Okay, let's design a smart contract around a concept of "Quantum Fluctuations" managing unique digital entities (like advanced, dynamic NFTs without using the ERC721 standard directly to fulfill the "don't duplicate open source" requirement, though the *pattern* will be similar for ownership). These entities will have properties that change based on various factors including on-chain pseudo-randomness, time, user actions, and potentially external data.

We'll create a contract that manages `FluctuatingEssence` tokens. Each essence will have properties that change dynamically.

**Concept:** **Quantum Fluctuation Manager**

*   Manages unique digital "Essences".
*   Essences have dynamic properties (Energy, Stability, Resonance) and a state.
*   Properties/State change via "fluctuations" triggered by users or external factors.
*   Fluctuations are influenced by on-chain pseudo-randomness, time, and interaction history.
*   Includes mechanics for interaction between essences, time-based decay, user "attunement", external oracle influence, and conditional actions based on properties.
*   Implements a basic role-based access control system.

---

**Outline:**

1.  **Pragma & Licenses:** Solidity version and license identifiers.
2.  **Imports:** SafeMath (optional, but good practice), ReentrancyGuard.
3.  **Error Handling:** Custom errors for clarity (Solidity 0.8+).
4.  **Enums:** Define possible states for an Essence.
5.  **Structs:** Define the `FluctuatingEssence` struct and related data structures.
6.  **Events:** Log key actions (creation, transfer, state change, property update, fluctuation, decay, etc.).
7.  **State Variables:** Mappings for storing essences, owners, role memberships, configuration, counters, etc.
8.  **Constants:** Role identifiers, property indices.
9.  **Modifiers:** For access control.
10. **Constructor:** Initializes the contract owner/manager role.
11. **Internal Functions:** Helper functions (e.g., pseudo-randomness generation, property update logic, state transition logic, decay calculation).
12. **Public/External Functions:** The 20+ functions as detailed in the summary.
    *   Essence Management (Create, Transfer, Burn, Get)
    *   Dynamic Property/State Management (Initiate Fluctuation, Apply Outcome, Attune, Harmonize, Decay, Amplify)
    *   Oracle Interaction (Request, Fulfill)
    *   Access Control (Grant, Revoke, Has Role, Renounce)
    *   Configuration (Set Fees, Rates, Oracle Address, State Transitions)
    *   Conditional Actions (Register Handlers, Trigger Action)
    *   View Functions (Get Properties, State, Fees, Rates, etc.)

---

**Function Summary:**

1.  `constructor()`: Deploys the contract and assigns the initial `MANAGER_ROLE`.
2.  `createEssence()`: Mints a new `FluctuatingEssence` token and assigns it to the caller. Initializes properties based on block data/entropy.
3.  `transferEssence(address to, uint256 essenceId)`: Transfers ownership of an essence.
4.  `burnEssence(uint256 essenceId)`: Destroys an essence, removing it from existence.
5.  `getEssence(uint256 essenceId)`: (View) Retrieves all details of a specific essence.
6.  `getEssenceProperties(uint256 essenceId)`: (View) Retrieves just the Energy, Stability, and Resonance properties.
7.  `getState(uint256 essenceId)`: (View) Retrieves the current state of an essence.
8.  `initiateFluctuation(uint256 essenceId)`: Triggers a process to calculate a *potential* next state and properties based on pseudo-randomness and current state. Stores the potential outcome internally. Requires a transition to `ESSENCE_STATE_FLUCTUATING`.
9.  `queryFluctuationResult(uint256 essenceId)`: (View) Returns the *potential* outcome (next state, properties) calculated by the last `initiateFluctuation` call for this essence, without applying it.
10. `applyFluctuationOutcome(uint256 essenceId)`: Applies the *potential* state and properties stored after `initiateFluctuation` to the essence. Requires the essence to be in `ESSENCE_STATE_FLUCTUATING` and transitions to a new state.
11. `attuneEssence(uint256 essenceId)`: Allows the owner to pay a fee to slightly influence the *tendency* of future fluctuations or boost a property. Transitions to `ESSENCE_STATE_ATTUNED`.
12. `harmonizeEssences(uint256 essenceId1, uint256 essenceId2)`: Allows owners (or a single owner if they own both) to interact two essences, potentially changing properties of both based on their initial states/properties. Transitions both to `ESSENCE_STATE_HARMONIZED`.
13. `decayEssence(uint256 essenceId)`: Applies a decay calculation to properties based on time elapsed since the last significant interaction. Transitions to `ESSENCE_STATE_DECAYING` if decay is significant.
14. `amplifyProperty(uint256 essenceId, uint8 propertyIndex, uint256 boostAmount)`: Allows boosting a specific property (Energy, Stability, or Resonance) by a fixed amount at a cost or based on internal factors.
15. `mutateState(uint256 essenceId, bytes32 externalEntropy)`: Allows incorporating external entropy (e.g., from an oracle or user-provided data) to influence a state change more drastically than normal fluctuation. Requires `ORACLE_ROLE` or specific permissions.
16. `requestOracleEntropy(uint256 essenceId)`: Simulates requesting entropy data for a specific essence from an external oracle system. Requires a callback function (`fulfillOracleEntropy`).
17. `fulfillOracleEntropy(uint256 essenceId, bytes32 entropyData)`: (Restricted) Callback function intended for the oracle to provide entropy data. Triggers a state/property change based on the provided data. Requires `ORACLE_ROLE`.
18. `grantRole(bytes32 role, address account)`: Grants a specific role to an address. Requires `MANAGER_ROLE`.
19. `revokeRole(bytes32 role, address account)`: Revokes a specific role from an address. Requires `MANAGER_ROLE`.
20. `hasRole(bytes32 role, address account)`: (View) Checks if an address has a specific role.
21. `renounceRole(bytes32 role)`: Allows an account to remove a role from itself.
22. `setAttunementFee(uint256 fee)`: (Restricted) Sets the fee required for the `attuneEssence` function. Requires `MANAGER_ROLE`.
23. `getAttunementFee()`: (View) Gets the current attunement fee.
24. `setDefaultDecayRate(uint256 rate)`: (Restricted) Sets the default decay rate applied by `decayEssence`. Requires `MANAGER_ROLE`.
25. `setSpecificDecayRate(uint256 essenceId, uint256 rate)`: (Restricted) Sets a custom decay rate for a specific essence, overriding the default. Requires `MANAGER_ROLE`.
26. `getDecayRate(uint256 essenceId)`: (View) Gets the effective decay rate for an essence (specific or default).
27. `setEssenceStateTransition(uint8 fromState, uint8 toState, bool allowed)`: (Restricted) Configures whether a transition from one state to another is permitted. Requires `MANAGER_ROLE`.
28. `isStateTransitionAllowed(uint8 fromState, uint8 toState)`: (View) Checks if a specific state transition is allowed.
29. `registerActionHandler(bytes4 functionSelector, address handlerAddress)`: (Restricted) Registers an address that can be called by `triggerConditionalAction` based on a function selector. Requires `MANAGER_ROLE`.
30. `unregisterActionHandler(bytes4 functionSelector)`: (Restricted) Unregisters an action handler. Requires `MANAGER_ROLE`.
31. `getRegisteredActionHandler(bytes4 functionSelector)`: (View) Gets the registered address for an action handler selector.
32. `triggerConditionalAction(uint256 essenceId, uint8 propertyIndex, uint256 threshold, bytes4 handlerSelector, bytes callData)`: Executes a call to a registered action handler *only if* the specified property of the essence meets or exceeds the given threshold. Uses `ReentrancyGuard`.

This provides a rich set of interactions including creation/destruction, transfer, dynamic state changes based on various inputs (internal, time, external), configured permissions, and conditional execution.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Basic implementation inspired by OpenZeppelin for reentrancy protection,
// but written here to avoid direct import and fulfill "don't duplicate" spirit
contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    // Function to allow calling into trusted contracts that use nonReentrant
    // Can be useful for complex interactions, use with extreme caution.
    modifier trustedCall() {
        uint256 originalStatus = _status;
        _status = _NOT_ENTERED; // Temporarily allow re-entering from a trusted call
        _;
        _status = originalStatus; // Restore previous status
    }
}


// Custom error codes for better debugging
error NotEssenceOwner(uint256 essenceId, address caller);
error EssenceDoesNotExist(uint256 essenceId);
error InvalidPropertyIndex(uint8 propertyIndex);
error InvalidEssenceState(uint8 state);
error InvalidStateTransition(uint8 fromState, uint8 toState);
error InsufficientAttunementFee(uint256 requiredFee, uint256 paidFee);
error ActionThresholdNotMet(uint256 essenceId, uint8 propertyIndex, uint256 threshold, uint256 actualValue);
error ActionHandlerNotRegistered(bytes4 selector);
error StateTransitionNotAllowed(uint8 fromState, uint8 toState);
error CannotTransferLockedEssence(uint256 essenceId);
error CannotFluctuateLockedEssence(uint256 essenceId);
error MustBeFluctuatingState(uint256 essenceId);
error MustBeNonFluctuatingState(uint256 essenceId);
error OnlyRole(bytes32 role, address account);
error OracleNotSet();
error OracleAddressInvalid(address oracleAddress);

contract QuantumFluctuationManager is ReentrancyGuard {

    // --- Enums ---
    enum EssenceState {
        IDLE,           // Default state, waiting for interaction
        FLUCTUATING,    // In the process of state change (initiated, waiting apply)
        ATTUNED,        // Recently attuned, properties slightly influenced
        DECAYING,       // Properties are actively decaying due to inactivity
        HARMONIZED,     // Recently harmonized with another essence
        LOCKED          // Temporarily locked during a complex operation (e.g., oracle call)
    }

    // --- Structs ---
    struct FluctuatingEssence {
        uint256 id;
        address owner;
        uint256 creationTime;
        EssenceState currentState;
        uint256 lastInteractionTime; // Timestamp of last significant interaction (attune, harmonize, apply fluctuation)
        uint256 energy;
        uint256 stability;
        uint256 resonance;
        bytes32 currentEntropySeed; // Seed used for the *last* fluctuation calculation
        bytes32 potentialNextSeed; // Seed for the *next* fluctuation calculation
        EssenceState potentialNextState;
        uint256 potentialNextEnergy;
        uint256 potentialNextStability;
        uint256 potentialNextResonance;
        uint256 specificDecayRate; // 0 means use default
    }

    // --- Events ---
    event EssenceCreated(uint256 indexed essenceId, address indexed owner, uint256 creationTime);
    event EssenceTransferred(uint256 indexed essenceId, address indexed from, address indexed to);
    event EssenceBurned(uint256 indexed essenceId);
    event EssenceStateChanged(uint256 indexed essenceId, EssenceState indexed oldState, EssenceState indexed newState);
    event EssencePropertiesUpdated(uint256 indexed essenceId, uint256 energy, uint256 stability, uint256 resonance);
    event FluctuationInitiated(uint256 indexed essenceId, bytes32 entropySeed);
    event FluctuationOutcomeApplied(uint256 indexed essenceId, EssenceState newState, uint256 energy, uint256 stability, uint256 resonance);
    event EssenceAttuned(uint256 indexed essenceId, uint256 paidFee, uint256 newResonanceInfluence); // Example influence
    event EssencesHarmonized(uint256 indexed essenceId1, uint256 indexed essenceId2, uint256 combinedInfluence); // Example influence
    event EssenceDecayed(uint256 indexed essenceId, uint256 timeElapsed, uint256 decayAmount);
    event PropertyAmplified(uint256 indexed essenceId, uint8 indexed propertyIndex, uint256 boostAmount);
    event StateMutatedByEntropy(uint256 indexed essenceId, bytes32 entropyData);
    event OracleEntropyRequested(uint256 indexed essenceId, address indexed caller);
    event OracleEntropyFulfilled(uint256 indexed essenceId, bytes32 entropyData);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed grantor);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed revoker);
    event AttunementFeeUpdated(uint256 oldFee, uint256 newFee);
    event DecayRateUpdated(uint256 indexed essenceId, uint256 newRate); // essenceId 0 for default
    event StateTransitionConfigured(uint8 indexed fromState, uint8 indexed toState, bool allowed);
    event ActionHandlerRegistered(bytes4 indexed selector, address indexed handler);
    event ActionHandlerUnregistered(bytes4 indexed selector);
    event ConditionalActionTriggered(uint256 indexed essenceId, bytes4 indexed handlerSelector, bool success, bytes result);
    event OracleAddressUpdated(address oldAddress, address newAddress);


    // --- State Variables ---
    mapping(uint256 => FluctuatingEssence) private _essences;
    mapping(uint256 => address) private _owners; // Redundant mapping for O(1) owner lookup like ERC721
    uint256 private _totalSupply;
    uint256 private _essenceNonce; // Used to ensure uniqueness of entropy seeds

    // Access Control
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    mapping(bytes32 => mapping(address => bool)) private _roles;

    // Configuration
    uint256 public attunementFee = 0.01 ether; // Example fee
    uint256 public defaultDecayRate = 1; // Example rate: 1 unit of decay per decay interval
    uint256 public decayInterval = 1 days; // Example interval
    address public oracleAddress;

    // State Transition Configuration: fromState => toState => allowed?
    mapping(uint8 => mapping(uint8 => bool)) private _stateTransitions;

    // Conditional Action Handlers: selector => handler address
    mapping(bytes4 => address) private _actionHandlers;

    // --- Modifiers ---
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function _checkRole(bytes32 role) internal view {
        if (!_roles[role][msg.sender]) {
            revert OnlyRole(role, msg.sender);
        }
    }

    modifier onlyEssenceOwner(uint256 essenceId) {
        if (_owners[essenceId] != msg.sender) {
            revert NotEssenceOwner(essenceId, msg.sender);
        }
        _;
    }

    modifier essenceExists(uint256 essenceId) {
        if (_owners[essenceId] == address(0)) {
             // Check _owners mapping as the source of truth for existence
            revert EssenceDoesNotExist(essenceId);
        }
        _;
    }

     modifier nonLocked(uint256 essenceId) {
        if (_essences[essenceId].currentState == EssenceState.LOCKED) {
            revert CannotTransferLockedEssence(essenceId);
        }
        _;
    }

     modifier notFluctuating(uint256 essenceId) {
        if (_essences[essenceId].currentState == EssenceState.FLUCTUATING) {
            revert CannotFluctuateLockedEssence(essenceId);
        }
        _;
    }

    modifier onlyFluctuating(uint256 essenceId) {
         if (_essences[essenceId].currentState != EssenceState.FLUCTUATING) {
            revert MustBeFluctuatingState(essenceId);
        }
        _;
    }

    modifier onlyNonFluctuating(uint256 essenceId) {
         if (_essences[essenceId].currentState == EssenceState.FLUCTUATING) {
            revert MustBeNonFluctuatingState(essenceId);
        }
    }


    // --- Constructor ---
    constructor() payable ReentrancyGuard() {
        _grantRole(MANAGER_ROLE, msg.sender);

        // Configure default allowed state transitions (example)
        _stateTransitions[uint8(EssenceState.IDLE)][uint8(EssenceState.FLUCTUATING)] = true;
        _stateTransitions[uint8(EssenceState.IDLE)][uint8(EssenceState.ATTUNED)] = true;
        _stateTransitions[uint8(EssenceState.IDLE)][uint8(EssenceState.DECAYING)] = true;
        _stateTransitions[uint8(EssenceState.IDLE)][uint8(EssenceState.HARMONIZED)] = true;
        _stateTransitions[uint8(EssenceState.IDLE)][uint8(EssenceState.LOCKED)] = true; // For oracle requests etc.

        _stateTransitions[uint8(EssenceState.FLUCTUATING)][uint8(EssenceState.IDLE)] = true; // After applying outcome
        _stateTransitions[uint8(EssenceState.FLUCTUATING)][uint8(EssenceState.LOCKED)] = true; // Can lock while fluctuating? Maybe not, design decision. Let's disallow for simplicity.

        _stateTransitions[uint8(EssenceState.ATTUNED)][uint8(EssenceState.IDLE)] = true;
        _stateTransitions[uint8(EssenceState.ATTUNED)][uint8(EssenceState.FLUCTUATING)] = true;
        _stateTransitions[uint8(EssenceState.ATTUNED)][uint8(EssenceState.HARMONIZED)] = true;
        _stateTransitions[uint8(EssenceState.ATTUNED)][uint8(EssenceState.LOCKED)] = true;

        _stateTransitions[uint8(EssenceState.DECAYING)][uint8(EssenceState.IDLE)] = true;
        _stateTransitions[uint8(EssenceState.DECAYING)][uint8(EssenceState.FLUCTUATING)] = true;
        _stateTransitions[uint8(EssenceState.DECAYING)][uint8(EssenceState.ATTUNED)] = true;
        _stateTransitions[uint8(EssenceState.DECAYING)][uint8(EssenceState.HARMONIZED)] = true;
        _stateTransitions[uint8(EssenceState.DECAYING)][uint8(EssenceState.LOCKED)] = true;

        _stateTransitions[uint8(EssenceState.HARMONIZED)][uint8(EssenceState.IDLE)] = true;
        _stateTransitions[uint8(EssenceState.HARMONIZED)][uint8(EssenceState.FLUCTUATING)] = true;
        _stateTransitions[uint8(EssenceState.HARMONIZED)][uint8(EssenceState.ATTUNED)] = true;
        _stateTransitions[uint8(EssenceState.HARMONIZED)][uint8(EssenceState.LOCKED)] = true;

        _stateTransitions[uint8(EssenceState.LOCKED)][uint8(EssenceState.IDLE)] = true; // Unlock
         _stateTransitions[uint8(EssenceState.LOCKED)][uint8(EssenceState.FLUCTUATING)] = true; // Unlock to Fluctuating after oracle
    }

    // --- Internal Helper Functions ---

    // Basic pseudo-randomness - DO NOT rely on this for security-sensitive applications.
    // Block data is public and can be influenced by miners.
    function _generatePseudoRandomSeed(uint256 essenceId) internal returns (bytes32) {
         _essenceNonce++; // Increment nonce to ensure unique seed per call
        return keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin, essenceId, _essenceNonce));
    }

    // Example property update logic based on seed and current properties
    function _calculateNextProperties(
        EssenceState currentState,
        uint256 currentEnergy,
        uint256 currentStability,
        uint256 currentResonance,
        bytes32 seed
    ) internal pure returns (
        EssenceState nextState,
        uint256 nextEnergy,
        uint256 nextStability,
        uint256 nextResonance
    ) {
        uint256 randomness = uint256(seed);

        // Simple deterministic logic based on state and randomness
        nextEnergy = (currentEnergy + (randomness % 100)) % 1000; // Example calculation
        nextStability = (currentStability + (randomness % 50)) % 500;
        nextResonance = (currentResonance + (randomness % 75)) % 750;

        // State transition logic based on randomness or current state
        uint256 stateChance = randomness % 100;
        if (currentState == EssenceState.IDLE) {
             if (stateChance < 20) nextState = EssenceState.ATTUNED;
             else if (stateChance < 30) nextState = EssenceState.DECAYING; // Unlikely from IDLE unless time passes
             else if (stateChance < 40) nextState = EssenceState.HARMONIZED; // Needs interaction
             else nextState = EssenceState.IDLE; // Stays IDLE
        } else if (currentState == EssenceState.FLUCTUATING) {
             // This function calculates the *potential* next state *after* applying
             // The actual application will transition to IDLE or a state dictated by the fluctuation outcome
            nextState = EssenceState.IDLE; // Typically returns to IDLE after fluctuation resolves
        } else {
            nextState = EssenceState.IDLE; // Default return state
        }
         // Note: The *actual* state transition on `applyFluctuationOutcome` should check `_stateTransitions`
         // This `_calculateNextProperties` just suggests a probabilistic outcome.

         // Clamp values to avoid overflow/underflow issues if calculations are more complex
         // Using modulo above implicitly clamps, but explicit clamping might be needed
         nextEnergy = nextEnergy > 1000 ? 1000 : nextEnergy;
         nextStability = nextStability > 500 ? 500 : nextStability;
         nextResonance = nextResonance > 750 ? 750 : nextResonance;
    }

     function _updateEssence(
        uint256 essenceId,
        address newOwner, // Can be address(0) for no change
        EssenceState newState, // Use current state if no change
        uint256 newEnergy,
        uint256 newStability,
        uint256 newResonance,
        bytes32 newEntropySeed, // Use current seed if no change
        uint256 newLastInteractionTime // 0 means no change
    ) internal essenceExists(essenceId) {
        FluctuatingEssence storage essence = _essences[essenceId];

        // State Transition Check
        if (newState != essence.currentState) {
            if (!_stateTransitions[uint8(essence.currentState)][uint8(newState)]) {
                revert StateTransitionNotAllowed(essence.currentState, newState);
            }
             emit EssenceStateChanged(essenceId, essence.currentState, newState);
             essence.currentState = newState;
        }


        // Owner Update
        if (newOwner != address(0) && newOwner != essence.owner) {
             address oldOwner = essence.owner;
            _owners[essenceId] = newOwner; // Update O(1) owner mapping
             essence.owner = newOwner; // Update struct owner
            // No need to update owner's list of essences here for gas efficiency; rely on events/indexers
            emit EssenceTransferred(essenceId, oldOwner, newOwner);
        }

        // Properties Update
        if (newEnergy != essence.energy || newStability != essence.stability || newResonance != essence.resonance) {
            essence.energy = newEnergy;
            essence.stability = newStability;
            essence.resonance = newResonance;
            emit EssencePropertiesUpdated(essenceId, newEnergy, newStability, newResonance);
        }

        // Entropy Seed Update
        if (newEntropySeed != bytes32(0)) { // Use bytes32(0) as flag for no change
            essence.currentEntropySeed = newEntropySeed;
        }

        // Last Interaction Time Update
        if (newLastInteractionTime != 0) {
            essence.lastInteractionTime = newLastInteractionTime;
        }
    }

    function _applyDecay(FluctuatingEssence storage essence) internal {
         uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - essence.lastInteractionTime;

        uint256 rate = essence.specificDecayRate > 0 ? essence.specificDecayRate : defaultDecayRate;

        if (timeElapsed > decayInterval && rate > 0) {
             // Calculate decay amount based on time elapsed and rate
             uint256 intervals = timeElapsed / decayInterval;
             uint256 decayAmount = intervals * rate; // Simple linear decay example

             uint256 oldEnergy = essence.energy;
             uint256 oldStability = essence.stability;
             uint256 oldResonance = essence.resonance;

             // Apply decay, ensuring values don't go below a minimum (e.g., 0 or 1)
             essence.energy = essence.energy > decayAmount ? essence.energy - decayAmount : 1;
             essence.stability = essence.stability > decayAmount ? essence.stability - decayAmount : 1;
             essence.resonance = essence.resonance > decayAmount ? essence.resonance - decayAmount : 1;

             // Update last interaction time to the current time
             essence.lastInteractionTime = currentTime;

             // Change state to DECAYING if it wasn't already, and decay was significant
             if (essence.currentState != EssenceState.DECAYING && (oldEnergy != essence.energy || oldStability != essence.stability || oldResonance != essence.resonance)) {
                 _updateEssence(essence.id, address(0), EssenceState.DECAYING, essence.energy, essence.stability, essence.resonance, bytes32(0), essence.lastInteractionTime);
             } else if (oldEnergy != essence.energy || oldStability != essence.stability || oldResonance != essence.resonance) {
                 // State was already DECAYING, just update properties and time
                 _updateEssence(essence.id, address(0), essence.currentState, essence.energy, essence.stability, essence.resonance, bytes32(0), essence.lastInteractionTime);
             }

             emit EssenceDecayed(essence.id, timeElapsed, decayAmount);
        }
         // If decay interval hasn't passed, no decay is applied.
    }

    function _grantRole(bytes32 role, address account) internal {
        if (!_roles[role][account]) {
            _roles[role][account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) internal {
        if (_roles[role][account]) {
            _roles[role][account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }


    // --- Public/External Functions (min 20 required) ---

    // 1. Constructor (already defined)

    // 2. createEssence
    function createEssence() external nonReentrant returns (uint256 newEssenceId) {
        _totalSupply++;
        newEssenceId = _totalSupply; // Simple sequential ID

        bytes32 initialSeed = _generatePseudoRandomSeed(newEssenceId);
        uint256 initialRandomness = uint256(initialSeed);

        // Initial properties influenced by the seed
        uint256 initialEnergy = (initialRandomness % 500) + 100; // Start between 100-599
        uint256 initialStability = (initialRandomness % 200) + 50; // Start between 50-249
        uint256 initialResonance = (initialRandomness % 300) + 75; // Start between 75-374

        _essences[newEssenceId] = FluctuatingEssence({
            id: newEssenceId,
            owner: msg.sender,
            creationTime: block.timestamp,
            currentState: EssenceState.IDLE,
            lastInteractionTime: block.timestamp,
            energy: initialEnergy,
            stability: initialStability,
            resonance: initialResonance,
            currentEntropySeed: initialSeed,
            potentialNextSeed: bytes32(0), // Not calculated yet
            potentialNextState: EssenceState.IDLE, // Default
            potentialNextEnergy: 0, // Default
            potentialNextStability: 0, // Default
            potentialNextResonance: 0, // Default
            specificDecayRate: 0 // Use default rate
        });
         _owners[newEssenceId] = msg.sender; // Keep owner mapping in sync

        emit EssenceCreated(newEssenceId, msg.sender, block.timestamp);
    }

    // 3. transferEssence
    function transferEssence(address to, uint256 essenceId) external nonReentrant essenceExists(essenceId) onlyEssenceOwner(essenceId) nonLocked(essenceId) {
        require(to != address(0), "Cannot transfer to zero address");
        _updateEssence(essenceId, to, _essences[essenceId].currentState, _essences[essenceId].energy, _essences[essenceId].stability, _essences[essenceId].resonance, bytes32(0), block.timestamp);
         // Decay might happen implicitly on interaction, but let's make transfers not update last interaction time for decay purposes unless it was the first interaction after decay interval.
         // Or, just apply decay *before* transfer is better logic. Let's add decay application where relevant.
         // _applyDecay(_essences[essenceId]); // Decide if transfer should trigger decay check. Let's skip for simplicity here.
    }

    // 4. burnEssence
    function burnEssence(uint256 essenceId) external nonReentrant essenceExists(essenceId) onlyEssenceOwner(essenceId) nonLocked(essenceId) {
        address owner = _essences[essenceId].owner;
        delete _essences[essenceId];
        delete _owners[essenceId];
        // Decrement total supply? Depends on desired tokenomics. Let's keep it total ever minted.
        // _totalSupply--; // Only if IDs were not sequential or we want to track burned
        emit EssenceBurned(essenceId);
    }

    // 5. getEssence (View)
    function getEssence(uint256 essenceId) external view essenceExists(essenceId) returns (FluctuatingEssence memory) {
        return _essences[essenceId];
    }

    // 6. getEssenceProperties (View)
     function getEssenceProperties(uint256 essenceId) external view essenceExists(essenceId) returns (uint256 energy, uint256 stability, uint256 resonance) {
        FluctuatingEssence storage essence = _essences[essenceId];
        return (essence.energy, essence.stability, essence.resonance);
    }

    // 7. getState (View)
     function getState(uint256 essenceId) external view essenceExists(essenceId) returns (EssenceState) {
        return _essences[essenceId].currentState;
    }

    // 8. initiateFluctuation
    function initiateFluctuation(uint256 essenceId) external nonReentrant essenceExists(essenceId) onlyEssenceOwner(essenceId) notFluctuating(essenceId) nonLocked(essenceId) {
        // Apply any potential decay before initiating fluctuation
        _applyDecay(_essences[essenceId]);

        bytes32 nextSeed = _generatePseudoRandomSeed(essenceId);

         // Calculate *potential* outcome based on current state/properties and the new seed
        (EssenceState potentialState, uint256 potentialEnergy, uint256 potentialStability, uint256 potentialResonance) = _calculateNextProperties(
            _essences[essenceId].currentState,
            _essences[essenceId].energy,
            _essences[essenceId].stability,
            _essences[essenceId].resonance,
            nextSeed
        );

        // Store the potential outcome and the seed used to calculate it
        FluctuatingEssence storage essence = _essences[essenceId];
        essence.potentialNextSeed = nextSeed;
        essence.potentialNextState = potentialState;
        essence.potentialNextEnergy = potentialEnergy;
        essence.potentialNextStability = potentialStability;
        essence.potentialNextResonance = potentialResonance;
        essence.lastInteractionTime = block.timestamp; // Interaction counts

        // Transition to FLUCTUATING state
        _updateEssence(essenceId, address(0), EssenceState.FLUCTUATING, essence.energy, essence.stability, essence.resonance, bytes32(0), essence.lastInteractionTime);

        emit FluctuationInitiated(essenceId, nextSeed);
    }

    // 9. queryFluctuationResult (View)
    function queryFluctuationResult(uint256 essenceId) external view essenceExists(essenceId) onlyFluctuating(essenceId) returns (EssenceState potentialState, uint256 potentialEnergy, uint256 potentialStability, uint256 potentialResonance) {
        FluctuatingEssence storage essence = _essences[essenceId];
        return (essence.potentialNextState, essence.potentialNextEnergy, essence.potentialNextStability, essence.potentialNextResonance);
    }

    // 10. applyFluctuationOutcome
    function applyFluctuationOutcome(uint256 essenceId) external nonReentrant essenceExists(essenceId) onlyEssenceOwner(essenceId) onlyFluctuating(essenceId) {
         FluctuatingEssence storage essence = _essences[essenceId];

         // Apply the stored potential outcome
         // Note: The target state *after* applying might be different from potentialNextState if transitions are configured.
         // Here, we assume applying fluctuation returns it to IDLE, unless the outcome *itself* dictates another allowed state.
         EssenceState targetState = essence.potentialNextState; // Use the calculated potential state as the target

         _updateEssence(
             essenceId,
             address(0), // No owner change
             targetState, // Apply the potential state
             essence.potentialNextEnergy,
             essence.potentialNextStability,
             essence.potentialNextResonance,
             essence.potentialNextSeed, // Update current seed
             block.timestamp // Update interaction time
         );

         // Clear potential outcome data after applying
         essence.potentialNextSeed = bytes32(0);
         essence.potentialNextState = EssenceState.IDLE; // Reset potential state storage
         essence.potentialNextEnergy = 0;
         essence.potentialNextStability = 0;
         essence.potentialNextResonance = 0;

         emit FluctuationOutcomeApplied(
             essenceId,
             _essences[essenceId].currentState, // Emit the actual state after update
             _essences[essenceId].energy,
             _essences[essenceId].stability,
             _essences[essenceId].resonance
         );
    }

    // 11. attuneEssence
    function attuneEssence(uint256 essenceId) external payable nonReentrant essenceExists(essenceId) onlyEssenceOwner(essenceId) nonLocked(essenceId) onlyNonFluctuating(essenceId) {
        if (msg.value < attunementFee) {
            revert InsufficientAttunementFee(attunementFee, msg.value);
        }

        // Refund excess ETH if any (optional, depends on desired fee model)
        if (msg.value > attunementFee) {
            payable(msg.sender).transfer(msg.value - attunementFee);
        }

        // Apply any potential decay before attuning
        _applyDecay(_essences[essenceId]);

        FluctuatingEssence storage essence = _essences[essenceId];
        // Example effect of attunement: slightly boost resonance or influence next fluctuation chance
        essence.resonance = essence.resonance + 10 > 750 ? 750 : essence.resonance + 10; // Small boost

        // Transition to ATTUNED state
        _updateEssence(essenceId, address(0), EssenceState.ATTUNED, essence.energy, essence.stability, essence.resonance, bytes32(0), block.timestamp);

        emit EssenceAttuned(essenceId, attunementFee, essence.resonance);
    }

    // 12. harmonizeEssences
    function harmonizeEssences(uint256 essenceId1, uint256 essenceId2) external nonReentrant essenceExists(essenceId1) essenceExists(essenceId2) nonLocked(essenceId1) nonLocked(essenceId2) onlyNonFluctuating(essenceId1) onlyNonFluctuating(essenceId2) {
        require(essenceId1 != essenceId2, "Cannot harmonize an essence with itself");
        require(_essences[essenceId1].owner == msg.sender || _essences[essenceId2].owner == msg.sender, "Must own at least one essence to initiate harmonization");
         // Add logic to require owning both or approval if harmonizing others' essences

         // Apply potential decay to both before harmonizing
        _applyDecay(_essences[essenceId1]);
        _applyDecay(_essences[essenceId2]);

        FluctuatingEssence storage essence1 = _essences[essenceId1];
        FluctuatingEssence storage essence2 = _essences[essenceId2];

        // Example harmonization logic: average stability, sum resonance, roll for energy boost
        uint256 avgStability = (essence1.stability + essence2.stability) / 2;
        uint256 sumResonance = essence1.resonance + essence2.resonance; // Could exceed max, handle overflow
        if (sumResonance > 1500) sumResonance = 1500; // Example cap

        bytes32 harmonizationSeed = _generatePseudoRandomSeed(essenceId1 + essenceId2); // Seed based on both IDs
        uint256 randomBoost = uint256(harmonizationSeed) % 50; // Up to 50 boost

        essence1.stability = avgStability;
        essence2.stability = avgStability;

        essence1.resonance = sumResonance / 2; // Divide sum equally or based on initial resonance?
        essence2.resonance = sumResonance / 2;

        essence1.energy = essence1.energy + randomBoost > 1000 ? 1000 : essence1.energy + randomBoost;
        essence2.energy = essence2.energy + (uint256(keccak256(abi.encodePacked(harmonizationSeed, 1))) % 50) > 1000 ? 1000 : essence2.energy + (uint256(keccak256(abi.encodePacked(harmonizationSeed, 1))) % 50); // Use related seed for second boost

        // Update both essences
         _updateEssence(essenceId1, address(0), EssenceState.HARMONIZED, essence1.energy, essence1.stability, essence1.resonance, bytes32(0), block.timestamp);
         _updateEssence(essenceId2, address(0), EssenceState.HARMONIZED, essence2.energy, essence2.stability, essence2.resonance, bytes32(0), block.timestamp);

        emit EssencesHarmonized(essenceId1, essenceId2, sumResonance);
    }

    // 13. decayEssence
    function decayEssence(uint256 essenceId) external nonReentrant essenceExists(essenceId) nonLocked(essenceId) {
        // This can be called by anyone to trigger decay,
        // incentivizing users/keepers to maintain essence state on chain.
        _applyDecay(_essences[essenceId]);
    }

    // 14. amplifyProperty
    function amplifyProperty(uint256 essenceId, uint8 propertyIndex, uint256 boostAmount) external nonReentrant essenceExists(essenceId) onlyEssenceOwner(essenceId) nonLocked(essenceId) onlyNonFluctuating(essenceId) {
        // This could require a fee, burning another token, or consuming "attunement points"
        // Let's make it consume some Resonance.

        require(propertyIndex < 3, "Invalid property index (0=Energy, 1=Stability, 2=Resonance)");
        require(boostAmount > 0, "Boost amount must be greater than 0");
        require(_essences[essenceId].resonance >= boostAmount, "Insufficient resonance to amplify property");

        _applyDecay(_essences[essenceId]); // Apply decay before using properties

        FluctuatingEssence storage essence = _essences[essenceId];
        essence.resonance -= boostAmount; // Consume resonance

        // Apply boost to the selected property
        if (propertyIndex == 0) { // Energy
            essence.energy = essence.energy + boostAmount > 1000 ? 1000 : essence.energy + boostAmount;
        } else if (propertyIndex == 1) { // Stability
            essence.stability = essence.stability + boostAmount > 500 ? 500 : essence.stability + boostAmount;
        } else if (propertyIndex == 2) { // Resonance (amplifying resonance consumes resonance, interesting mechanic)
             essence.resonance = essence.resonance + boostAmount > 750 ? 750 : essence.resonance + boostAmount;
        } else {
            revert InvalidPropertyIndex(propertyIndex);
        }

        _updateEssence(essenceId, address(0), EssenceState.IDLE, essence.energy, essence.stability, essence.resonance, bytes32(0), block.timestamp);

        emit PropertyAmplified(essenceId, propertyIndex, boostAmount);
    }

    // 15. mutateState (Allows admin/oracle to force a state change using external data)
    function mutateState(uint256 essenceId, bytes32 externalEntropy) external nonReentrant essenceExists(essenceId) onlyRole(ORACLE_ROLE) { // Only ORACLE_ROLE can call this
        // This bypasses normal fluctuation and uses external data for a state change
        _applyDecay(_essences[essenceId]);

        FluctuatingEssence storage essence = _essences[essenceId];

        // Example mutation logic based on external entropy
        uint256 randomness = uint256(externalEntropy);
        uint256 newEnergy = (essence.energy + (randomness % 200) - 100); // Add/subtract up to 100
        uint256 newStability = (essence.stability + (randomness % 100) - 50); // Add/subtract up to 50
        uint256 newResonance = (essence.resonance + (randomness % 150) - 75); // Add/subtract up to 75

        // Ensure properties stay within bounds (example bounds)
         newEnergy = newEnergy > 1000 ? 1000 : (newEnergy < 1 ? 1 : newEnergy);
         newStability = newStability > 500 ? 500 : (newStability < 1 ? 1 : newStability);
         newResonance = newResonance > 750 ? 750 : (newResonance < 1 ? 1 : newResonance);

         EssenceState newState = EssenceState.IDLE; // Default target state
         uint256 stateRoll = uint256(keccak256(abi.encodePacked(externalEntropy, essenceId))) % 100;
         if (stateRoll < 30) newState = EssenceState.ATTUNED;
         else if (stateRoll < 40) newState = EssenceState.DECAYING;


         _updateEssence(
             essenceId,
             address(0),
             newState,
             newEnergy,
             newStability,
             newResonance,
             externalEntropy, // Use external entropy as the new current seed
             block.timestamp
         );

         emit StateMutatedByEntropy(essenceId, externalEntropy);
    }

    // 16. requestOracleEntropy (Simulated request)
    function requestOracleEntropy(uint256 essenceId) external nonReentrant essenceExists(essenceId) onlyEssenceOwner(essenceId) nonLocked(essenceId) {
        require(oracleAddress != address(0), "Oracle address not set");
        // In a real system, this would likely emit an event the oracle listens for
        // or call an oracle contract's request function.
        // Here we just emit an event as a signal.
        _updateEssence(essenceId, address(0), EssenceState.LOCKED, _essences[essenceId].energy, _essences[essenceId].stability, _essences[essenceId].resonance, bytes32(0), block.timestamp); // Lock essence
        emit OracleEntropyRequested(essenceId, msg.sender);
    }

    // 17. fulfillOracleEntropy (Callback for the oracle)
    function fulfillOracleEntropy(uint256 essenceId, bytes32 entropyData) external nonReentrant essenceExists(essenceId) onlyRole(ORACLE_ROLE) {
         // Ensure the call comes from the registered oracle address, if oracleAddress is set
        if (oracleAddress != address(0)) {
            require(msg.sender == oracleAddress, "Caller is not the registered oracle");
        }

        FluctuatingEssence storage essence = _essences[essenceId];
        require(essence.currentState == EssenceState.LOCKED, "Essence not in LOCKED state awaiting oracle fulfillment");

        // Apply mutation logic based on the oracle provided entropy
         uint256 randomness = uint256(entropyData);
        uint256 newEnergy = (essence.energy + (randomness % 200) - 100);
        uint256 newStability = (essence.stability + (randomness % 100) - 50);
        uint256 newResonance = (essence.resonance + (randomness % 150) - 75);

         newEnergy = newEnergy > 1000 ? 1000 : (newEnergy < 1 ? 1 : newEnergy);
         newStability = newStability > 500 ? 500 : (newStability < 1 ? 1 : newStability);
         newResonance = newResonance > 750 ? 750 : (newResonance < 1 ? 1 : newResonance);

        // Transition state based on outcome/config, maybe unlock to IDLE or FLUCTUATING
        EssenceState nextStateAfterOracle = EssenceState.IDLE;
        uint256 stateRoll = uint256(keccak256(abi.encodePacked(entropyData, essenceId))) % 100;
         if (_stateTransitions[uint8(EssenceState.LOCKED)][uint8(EssenceState.FLUCTUATING)] && stateRoll < 50) { // Example condition
             nextStateAfterOracle = EssenceState.FLUCTUATING; // Unlock to fluctuating
             // Note: If transitioning to FLUCTUATING, need to set potential properties too
             // Or, just transition to IDLE and require the user to initiate fluctuation normally.
             // Let's transition to IDLE for simplicity after fulfillment.
             nextStateAfterOracle = EssenceState.IDLE; // Unlock to IDLE
         } else if (_stateTransitions[uint8(EssenceState.LOCKED)][uint8(EssenceState.IDLE)]) {
             nextStateAfterOracle = EssenceState.IDLE; // Unlock to IDLE
         } else {
             // Should not happen if transitions are configured correctly from LOCKED
             revert InvalidStateTransition(EssenceState.LOCKED, nextStateAfterOracle);
         }


         _updateEssence(
             essenceId,
             address(0),
             nextStateAfterOracle, // Unlock to IDLE or FLUCTUATING
             newEnergy,
             newStability,
             newResonance,
             entropyData, // Use external entropy as the new current seed
             block.timestamp
         );

        emit OracleEntropyFulfilled(essenceId, entropyData);
    }

    // 18. grantRole
    function grantRole(bytes32 role, address account) external nonReentrant onlyRole(MANAGER_ROLE) {
        _grantRole(role, account);
    }

    // 19. revokeRole
    function revokeRole(bytes32 role, address account) external nonReentrant onlyRole(MANAGER_ROLE) {
        _revokeRole(role, account);
    }

    // 20. hasRole (View)
    function hasRole(bytes32 role, address account) external view returns (bool) {
        return _roles[role][account];
    }

    // 21. renounceRole
    function renounceRole(bytes32 role) external nonReentrant {
        require(_roles[role][msg.sender], "Account does not have the role");
        _revokeRole(role, msg.sender); // Internal function checks if role exists
    }

    // 22. setAttunementFee
    function setAttunementFee(uint256 fee) external nonReentrant onlyRole(MANAGER_ROLE) {
        uint256 oldFee = attunementFee;
        attunementFee = fee;
        emit AttunementFeeUpdated(oldFee, fee);
    }

    // 23. getAttunementFee (View)
    // Already public state variable

    // 24. setDefaultDecayRate
    function setDefaultDecayRate(uint256 rate) external nonReentrant onlyRole(MANAGER_ROLE) {
        uint256 oldRate = defaultDecayRate;
        defaultDecayRate = rate;
        emit DecayRateUpdated(0, rate); // Use 0 as essenceId for default rate update
    }

    // 25. setSpecificDecayRate
    function setSpecificDecayRate(uint256 essenceId, uint256 rate) external nonReentrant essenceExists(essenceId) onlyRole(MANAGER_ROLE) {
        _essences[essenceId].specificDecayRate = rate;
        emit DecayRateUpdated(essenceId, rate);
    }

    // 26. getDecayRate (View)
    function getDecayRate(uint256 essenceId) external view essenceExists(essenceId) returns (uint256) {
        uint256 specificRate = _essences[essenceId].specificDecayRate;
        return specificRate > 0 ? specificRate : defaultDecayRate;
    }

    // 27. setEssenceStateTransition
    function setEssenceStateTransition(uint8 fromState, uint8 toState, bool allowed) external nonReentrant onlyRole(MANAGER_ROLE) {
        require(fromState < uint8(EssenceState.LOCKED) + 1 && toState < uint8(EssenceState.LOCKED) + 1, "Invalid state value");
        _stateTransitions[fromState][toState] = allowed;
        emit StateTransitionConfigured(fromState, toState, allowed);
    }

    // 28. isStateTransitionAllowed (View)
    function isStateTransitionAllowed(uint8 fromState, uint8 toState) external view returns (bool) {
         require(fromState < uint8(EssenceState.LOCKED) + 1 && toState < uint8(EssenceState.LOCKED) + 1, "Invalid state value");
        return _stateTransitions[fromState][toState];
    }

    // 29. registerActionHandler
    function registerActionHandler(bytes4 functionSelector, address handlerAddress) external nonReentrant onlyRole(MANAGER_ROLE) {
        require(handlerAddress != address(0), "Handler address cannot be zero");
        _actionHandlers[functionSelector] = handlerAddress;
        emit ActionHandlerRegistered(functionSelector, handlerAddress);
    }

    // 30. unregisterActionHandler
    function unregisterActionHandler(bytes4 functionSelector) external nonReentrant onlyRole(MANAGER_ROLE) {
        require(_actionHandlers[functionSelector] != address(0), "Action handler not registered");
        delete _actionHandlers[functionSelector];
        emit ActionHandlerUnregistered(functionSelector);
    }

    // 31. getRegisteredActionHandler (View)
    function getRegisteredActionHandler(bytes4 functionSelector) external view returns (address) {
        return _actionHandlers[functionSelector];
    }

    // 32. triggerConditionalAction
    // Allows calling into a pre-registered handler function on another contract
    // based on an essence's property meeting a threshold.
    function triggerConditionalAction(uint256 essenceId, uint8 propertyIndex, uint256 threshold, bytes4 handlerSelector, bytes calldata callData) external nonReentrant essenceExists(essenceId) nonLocked(essenceId) {
         require(propertyIndex < 3, "Invalid property index (0=Energy, 1=Stability, 2=Resonance)");

        // Apply any potential decay before checking properties
        _applyDecay(_essences[essenceId]);

        FluctuatingEssence storage essence = _essences[essenceId];
        uint256 currentValue;
        if (propertyIndex == 0) currentValue = essence.energy;
        else if (propertyIndex == 1) currentValue = essence.stability;
        else if (propertyIndex == 2) currentValue = essence.resonance;
        else revert InvalidPropertyIndex(propertyIndex); // Should be caught by initial require

        if (currentValue < threshold) {
            revert ActionThresholdNotMet(essenceId, propertyIndex, threshold, currentValue);
        }

        address handlerAddress = _actionHandlers[handlerSelector];
        if (handlerAddress == address(0)) {
            revert ActionHandlerNotRegistered(handlerSelector);
        }

        // Construct the payload for the call.
        // Assumes handler contracts have a function matching the selector that accepts callData.
        // For a specific interface pattern, use an interface call instead of low-level call.
        // Using low-level call with arbitrary data is powerful but risky.
        // A safer pattern would be require the handler contract implements a specific interface
        // like `interface IActionHandler { function handle(uint256 essenceId, bytes calldata data) external; }`
        // and register handlers based on *that* interface, then call `IActionHandler(handlerAddress).handle(essenceId, callData);`
        // Let's stick to the low-level call for maximum flexibility as requested by "advanced/creative",
        // but note the security implications. ReentrancyGuard helps, but external contract logic is key.

        bytes memory payload = abi.encodeWithSelector(handlerSelector, callData);

        // Execute the call using low-level call. Use `nonReentrant` modifier on this function.
        (bool success, bytes memory returndata) = handlerAddress.call(payload);

        // Optional: Handle success/failure and return data
        // require(success, string(abi.decode(returndata, (string)))); // Revert if call failed

        emit ConditionalActionTriggered(essenceId, handlerSelector, success, returndata);

        // Update last interaction time after triggering action (counts as interaction)
        essence.lastInteractionTime = block.timestamp;
    }

    // Additional Utility Functions (Getting to 20+ and useful features)

    // 33. getOwner (View) - ERC721 like
    function getOwner(uint256 essenceId) external view essenceExists(essenceId) returns (address) {
        return _owners[essenceId];
    }

    // 34. getTotalEssences (View) - ERC721 like total supply
    function getTotalEssences() external view returns (uint256) {
        return _totalSupply; // Tracks total ever minted
    }

    // 35. withdrawFees (Restricted) - Allows manager to withdraw collected fees
    function withdrawFees(address payable recipient) external nonReentrant onlyRole(MANAGER_ROLE) {
        require(recipient != address(0), "Recipient cannot be zero address");
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        recipient.transfer(balance);
    }

    // 36. setOracleAddress (Restricted)
    function setOracleAddress(address _oracle) external nonReentrant onlyRole(MANAGER_ROLE) {
        require(_oracle != address(0), "Oracle address cannot be zero");
        require(_oracle != oracleAddress, "New oracle address cannot be the same as the current one");
        address oldOracle = oracleAddress;
        oracleAddress = _oracle;
        emit OracleAddressUpdated(oldOracle, oracleAddress);
    }

    // 37. getOracleAddress (View)
    function getOracleAddress() external view returns (address) {
        return oracleAddress;
    }

    // 38. getLastInteractionTime (View)
    function getLastInteractionTime(uint256 essenceId) external view essenceExists(essenceId) returns (uint256) {
        return _essences[essenceId].lastInteractionTime;
    }

    // 39. calculatePotentialDecay (View) - Shows how much decay *would* be applied
    function calculatePotentialDecay(uint256 essenceId) external view essenceExists(essenceId) returns (uint256 decayAmount) {
         uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - _essences[essenceId].lastInteractionTime;

        uint256 rate = getDecayRate(essenceId); // Uses getDecayRate internally

        if (timeElapsed > decayInterval && rate > 0) {
             uint256 intervals = timeElapsed / decayInterval;
             decayAmount = intervals * rate;
        } else {
            decayAmount = 0;
        }
         // Note: This is a simple linear calculation. Actual decay might be more complex.
    }

    // 40. checkPropertyThreshold (View)
     function checkPropertyThreshold(uint256 essenceId, uint8 propertyIndex, uint256 threshold) external view essenceExists(essenceId) returns (bool) {
         require(propertyIndex < 3, "Invalid property index (0=Energy, 1=Stability, 2=Resonance)");

         FluctuatingEssence storage essence = _essences[essenceId];
        uint256 currentValue;
        if (propertyIndex == 0) currentValue = essence.energy;
        else if (propertyIndex == 1) currentValue = essence.stability;
        else if (propertyIndex == 2) currentValue = essence.resonance;
        else revert InvalidPropertyIndex(propertyIndex); // Should be caught by initial require

        return currentValue >= threshold;
     }

    // 41. getAvailableStates (View) - Utility to list states (enum values)
    function getAvailableStates() external pure returns (EssenceState[] memory) {
        // Hardcoded list of enum values
        EssenceState[] memory states = new EssenceState[](6);
        states[0] = EssenceState.IDLE;
        states[1] = EssenceState.FLUCTUATING;
        states[2] = EssenceState.ATTUNED;
        states[3] = EssenceState.DECAYING;
        states[4] = EssenceState.HARMONIZED;
        states[5] = EssenceState.LOCKED;
        return states;
    }

    // 42. setDecayInterval (Restricted)
     function setDecayInterval(uint256 interval) external nonReentrant onlyRole(MANAGER_ROLE) {
         require(interval > 0, "Decay interval must be greater than 0");
         decayInterval = interval;
     }

     // 43. getDecayInterval (View)
     function getDecayInterval() external view returns (uint256) {
         return decayInterval;
     }

}
```