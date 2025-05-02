Okay, let's design a smart contract concept that involves dynamic states, time-based mechanics, external influence, and various interaction patterns. We'll call it the "Temporal Relic Forge".

It will manage unique digital "Relics" that evolve or degrade based on internal energy, time passing, user interaction, and simulated external "cosmic events".

**Concept Outline:**

1.  **Core Asset:** A non-fungible concept (managed internally, not necessarily ERC721 to avoid direct duplication, but conceptually similar to unique items). Each Relic has a unique ID, an owner, a `state` (enum), `temporalEnergy`, `lastInteractionTimestamp`, and potentially other dynamic `attributes`.
2.  **States:** Relics exist in different states (e.g., Dormant, Active, Flux, Degraded, Transcendent). States grant different abilities or have different properties.
3.  **Temporal Energy:** A core resource. Gained through certain actions or "cosmic events", lost passively over time (decay), or consumed by powerful actions.
4.  **Time Mechanics:** State transitions and energy decay/gain are influenced by the time elapsed since the last interaction or state update.
5.  **Interactions:** Users can interact with their relics or public relics, consuming energy, potentially changing attributes, or triggering effects.
6.  **External Influence (Simulated Oracle):** An admin or designated oracle can inject data simulating external events that universally or specifically affect relics (e.g., a "Cosmic Surge" adding energy, a "Temporal Glitch" altering states).
7.  **Advanced Functions:** State-dependent abilities, merging/splitting mechanics, timed actions, prediction of state changes, querying complex conditions.
8.  **Access Control:** Owner/Admin roles for critical contract parameters and some powerful relic modifications.

**Function Summary:**

1.  `constructor()`: Initializes the contract with owner/admin.
2.  `createRelic()`: Admin-only function to mint a new relic, assigning an ID, initial state/energy, and owner.
3.  `getRelicDetails(uint256 _relicId)`: View function to get comprehensive details of a relic.
4.  `getRelicState(uint256 _relicId)`: View function to get the current state of a relic.
5.  `getRelicEnergy(uint256 _relicId)`: View function to get the current temporal energy of a relic.
6.  `getRelicOwner(uint256 _relicId)`: View function to get the owner of a relic.
7.  `getRelicAttribute(uint256 _relicId, uint256 _attributeIndex)`: View function to get a specific dynamic attribute of a relic.
8.  `interactWithRelic(uint256 _relicId)`: User function to interact, consumes energy, updates interaction timestamp, potentially affects state calculation.
9.  `updateRelicState(uint256 _relicId)`: Core function to recalculate and transition the relic's state based on time, energy, and attributes. Callable by anyone to push updates on-chain (caller pays gas).
10. `attuneRelic(uint256 _relicId)`: A state-dependent action requiring a specific state and energy level, consumes significant energy for a positive effect (e.g., boost attribute).
11. `stabilizeRelic(uint256 _relicId)`: Consumes energy to temporarily halt time-based decay or state changes. Only available in certain volatile states.
12. `injectCosmicEvent(uint256 _eventType, bytes _eventData)`: Admin/Oracle function to simulate external data affecting relics (e.g., boost energy for all relics in a certain state, or specific relics).
13. `transferRelic(uint256 _relicId, address _to)`: Basic transfer function.
14. `sacrificeRelic(uint256 _relicId)`: Burns the relic in exchange for a benefit (e.g., returning some locked ETH, or boosting another relic). Only available in specific states.
15. `predictNextState(uint256 _relicId)`: View function to predict the state the relic would transition to if `updateRelicState` were called immediately.
16. `queryStateCondition(uint256 _relicId, uint256 _conditionType)`: View function to check if a relic meets complex criteria based on state, energy, attributes, and time.
17. `setTimeLock(uint256 _actionType, uint256 _seconds)`: Admin function to set timelock duration for sensitive actions.
18. `proposeCriticalParameterChange(uint256 _paramType, int256 _newValue)`: Admin function to propose a change to core contract parameters (like decay rates, state thresholds), starts a timelock.
19. `executeCriticalParameterChange(uint256 _paramType, int256 _newValue)`: Admin function to finalize the proposed parameter change after the timelock expires.
20. `pauseInteractions()`: Admin function to pause user interactions (e.g., during upgrades or maintenance).
21. `unpauseInteractions()`: Admin function to resume user interactions.
22. `getRelicCount()`: View function for total number of relics.
23. `getCurrentStateDuration(uint256 _relicId)`: View function showing how long a relic has been in its current state.
24. `setRelicAttributeBase(uint256 _attributeIndex, uint256 _baseValue)`: Admin function to set base values for attributes affecting new relics.
25. `setRelicAttributeModifier(uint256 _attributeIndex, int256 _modifier)`: Admin function to set global modifiers that affect how attributes influence state transitions or energy changes.
26. `estimateEnergyDecay(uint256 _relicId, uint256 _timeElapsed)`: Pure function to estimate energy decay over a given time.
27. `checkRelicEligibilityForAction(uint256 _relicId, uint256 _actionType)`: View function to check if a relic meets the requirements for a specific state-dependent action.
28. `getAdmin()`: View function to get the current admin address.
29. `setAdmin(address _newAdmin)`: Owner-only function to change the admin address.
30. `withdrawFees(address _to)`: Admin function to withdraw accumulated fees (e.g., from relic creation or interactions).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// --- ChronoRelicForge: Outline and Function Summary ---
//
// Concept: Manages unique digital "Relics" with dynamic states, temporal energy, and attributes.
// Relics evolve or degrade based on time, interactions, and simulated external events.
// Includes advanced features like state-dependent actions, time-locked parameters, and external influence simulation.
//
// Functions:
// 1.  constructor(): Initializes owner and admin.
// 2.  createRelic(address _owner): Admin creates a new relic.
// 3.  getRelicDetails(uint256 _relicId): View detailed relic data.
// 4.  getRelicState(uint256 _relicId): View relic's current state.
// 5.  getRelicEnergy(uint256 _relicId): View relic's temporal energy.
// 6.  getRelicOwner(uint256 _relicId): View relic's owner.
// 7.  getRelicAttribute(uint256 _relicId, uint256 _attributeIndex): View a specific attribute.
// 8.  interactWithRelic(uint256 _relicId): User interaction, consumes energy.
// 9.  updateRelicState(uint256 _relicId): Recalculates state based on time/energy/attributes.
// 10. attuneRelic(uint256 _relicId): State/energy dependent positive action.
// 11. stabilizeRelic(uint256 _relicId): Consumes energy to prevent decay in certain states.
// 12. injectCosmicEvent(uint256 _eventType, bytes _eventData): Admin injects external data affecting relics.
// 13. transferRelic(uint256 _relicId, address _to): Transfer relic ownership.
// 14. sacrificeRelic(uint256 _relicId): Burn relic for a benefit (state-dependent).
// 15. predictNextState(uint256 _relicId): Predicts future state based on current data.
// 16. queryStateCondition(uint256 _relicId, uint256 _conditionType): Checks if relic meets complex criteria.
// 17. setTimeLock(uint256 _actionType, uint256 _seconds): Admin sets timelock durations.
// 18. proposeCriticalParameterChange(uint256 _paramType, int256 _newValue): Admin proposes parameter change with timelock.
// 19. executeCriticalParameterChange(uint256 _paramType, int256 _newValue): Admin executes parameter change after timelock.
// 20. pauseInteractions(): Admin pauses user interactions.
// 21. unpauseInteractions(): Admin unpauses user interactions.
// 22. getRelicCount(): View total number of relics.
// 23. getCurrentStateDuration(uint256 _relicId): View how long a relic has been in its current state.
// 24. setRelicAttributeBase(uint256 _attributeIndex, uint256 _baseValue): Admin sets base attribute values for new relics.
// 25. setRelicAttributeModifier(uint256 _attributeIndex, int256 _modifier): Admin sets global attribute influence modifiers.
// 26. estimateEnergyDecay(uint256 _relicId, uint256 _timeElapsed): Pure estimate of energy decay.
// 27. checkRelicEligibilityForAction(uint256 _relicId, uint256 _actionType): Checks if relic can perform a specific action.
// 28. getAdmin(): View admin address.
// 29. setAdmin(address _newAdmin): Owner sets new admin address.
// 30. withdrawFees(address _to): Admin withdraws accumulated fees.

contract ChronoRelicForge is ReentrancyGuard, Context {

    // --- Errors ---
    error NotOwnerOrAdmin();
    error NotAdmin();
    error NotRelicOwner(uint256 relicId, address caller);
    error RelicNotFound(uint256 relicId);
    error InvalidState(uint256 relicId, RelicState currentState, string requiredState);
    error InsufficientEnergy(uint256 relicId, uint256 currentEnergy, uint256 requiredEnergy);
    error InteractionPaused();
    error InvalidParameterType(uint256 paramType);
    error NoParameterChangeProposed();
    error TimelockNotExpired(uint256 timeLeft);
    error ParameterChangeAlreadyProposed(uint256 paramType);
    error InvalidAttributeIndex(uint256 index);
    error SacrificeNotAllowed(uint256 relicId, RelicState currentState);
    error InvalidActionType(uint256 actionType);
    error NotPaused();
    error AlreadyPaused();

    // --- Events ---
    event RelicCreated(uint256 indexed relicId, address indexed owner, RelicState initialState, uint256 initialEnergy);
    event RelicStateUpdated(uint256 indexed relicId, RelicState oldState, RelicState newState, uint256 timestamp);
    event RelicEnergyChanged(uint256 indexed relicId, uint256 oldEnergy, uint256 newEnergy, string reason);
    event RelicInteracted(uint256 indexed relicId, address indexed user, uint256 newEnergy);
    event RelicTransferred(uint256 indexed relicId, address indexed from, address indexed to);
    event CosmicEventInjected(uint256 eventType, bytes eventData);
    event RelicSacrificed(uint256 indexed relicId, address indexed owner, RelicState finalState, uint256 finalEnergy);
    event CriticalParameterChangeProposed(uint256 indexed paramType, int256 newValue, uint256 timelockExpiry);
    event CriticalParameterChangeExecuted(uint256 indexed paramType, int256 executedValue);
    event InteractionsPaused();
    event InteractionsUnpaused();
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    event FeesWithdrawn(address indexed to, uint256 amount);
    event RelicAttributeChanged(uint256 indexed relicId, uint256 indexed attributeIndex, uint256 newValue);
    event RelicAttributeModifierChanged(uint256 indexed attributeIndex, int256 newModifier);

    // --- State Variables ---

    enum RelicState {
        Dormant,     // Low energy, inactive, slow decay/gain
        Active,      // Stable state, moderate energy, standard decay/gain
        Flux,        // High energy, unstable, potential for transcendence or rapid decay
        Degraded,    // Low energy, decaying, prone to dormancy or sacrifice
        Transcendent // Very high energy, stable (requires upkeep), grants special abilities
    }

    struct Relic {
        uint256 id;
        address owner;
        RelicState state;
        uint256 temporalEnergy;
        uint256 lastInteractionTimestamp;
        uint256 stateEntryTimestamp; // Timestamp when the relic entered its current state
        uint256[] attributes; // Dynamic attributes affecting state transitions/abilities
    }

    mapping(uint256 => Relic) private _relics;
    uint256 private _relicCounter;
    address private _owner; // Contract owner
    address private _admin; // Role for daily operations/parameter changes

    bool private _paused; // Pause mechanism for interactions

    // Core parameters influencing relic dynamics
    mapping(uint256 => int256) private _coreParameters; // paramType => value (int256 for flexibility)

    enum ParameterType {
        EnergyDecayRatePerSecond,
        InteractionEnergyCost,
        InteractionEnergyGain,
        DormantToActiveEnergyThreshold,
        ActiveToFluxEnergyThreshold,
        ActiveToDegradedEnergyThreshold,
        FluxToTranscendentEnergyThreshold,
        DegradedToDormantEnergyThreshold,
        BaseAttributeEnergyInfluence, // Example: how much attribute[0] affects energy change
        StateTransitionCheckInterval // How often updateRelicState logic considers full transitions
    }

    mapping(uint256 => uint256) private _timelockDurations; // actionType => seconds

    enum TimelockActionType {
        CriticalParameterChange
        // Add other sensitive actions here
    }

    struct ProposedParameterChange {
        uint256 paramType;
        int256 newValue;
        uint256 timelockExpiry;
        bool exists;
    }

    ProposedParameterChange private _proposedParameterChange;

    uint256 private constant ATTRIBUTE_COUNT = 3; // Example: Number of dynamic attributes per relic
    mapping(uint256 => uint256) private _baseAttributes; // Default attributes for new relics
    mapping(uint256 => int256) private _attributeModifiers; // Global modifiers for attribute influence

    uint256 public creationFee = 0.01 ether; // Example fee for creating relics
    uint256 public interactionFee = 0.0001 ether; // Example fee for user interactions

    // --- Modifiers ---

    modifier onlyOwner() {
        if (_msgSender() != _owner) revert NotOwnerOrAdmin();
        _;
    }

    modifier onlyAdmin() {
        if (_msgSender() != _admin && _msgSender() != _owner) revert NotAdmin();
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert InteractionPaused();
        _;
    }

    modifier whenPaused() {
        if (!_paused) revert NotPaused();
        _;
    }

    modifier validRelicId(uint256 _relicId) {
        if (_relicId == 0 || _relicId > _relicCounter) revert RelicNotFound(_relicId);
        _;
    }

    modifier isRelicOwner(uint256 _relicId) {
        if (_relics[_relicId].owner != _msgSender()) revert NotRelicOwner(_relicId, _msgSender());
        _;
    }

    // --- Constructor ---

    constructor(address initialAdmin) {
        _owner = _msgSender();
        _admin = initialAdmin;

        // Initialize default core parameters
        _coreParameters[uint256(ParameterType.EnergyDecayRatePerSecond)] = 1; // Lose 1 energy per second
        _coreParameters[uint256(ParameterType.InteractionEnergyCost)] = 10;
        _coreParameters[uint256(ParameterType.InteractionEnergyGain)] = 5;
        _coreParameters[uint256(ParameterType.DormantToActiveEnergyThreshold)] = 50;
        _coreParameters[uint256(ParameterType.ActiveToFluxEnergyThreshold)] = 200;
        _coreParameters[uint256(ParameterType.ActiveToDegradedEnergyThreshold)] = 20;
        _coreParameters[uint256(ParameterType.FluxToTranscendentEnergyThreshold)] = 500;
        _coreParameters[uint256(ParameterType.DegradedToDormantEnergyThreshold)] = 10;
        _coreParameters[uint256(ParameterType.BaseAttributeEnergyInfluence)] = 1; // Attribute[0] adds energy gain per second
        _coreParameters[uint256(ParameterType.StateTransitionCheckInterval)] = 300; // Check for major state transitions every 5 minutes of inactivity/update calls

        // Initialize default timelock durations
        _timelockDurations[uint256(TimelockActionType.CriticalParameterChange)] = 7 days; // 7 days timelock for parameter changes

        // Initialize base attributes for new relics
        for (uint256 i = 0; i < ATTRIBUTE_COUNT; i++) {
            _baseAttributes[i] = 10; // Default base value
            _attributeModifiers[i] = 0; // Default modifier
        }

        _paused = false; // Start unpaused
    }

    // --- Core Relic Management Functions ---

    /**
     * @notice Admin function to create a new relic.
     * @param _owner The address that will initially own the new relic.
     */
    function createRelic(address _owner) public payable onlyAdmin {
        if (msg.value < creationFee) revert InsufficientEnergy(0, msg.value, creationFee); // Using InsufficientEnergy error for fee check
        _relicCounter++;
        uint256 relicId = _relicCounter;

        uint256[] memory initialAttributes = new uint256[](ATTRIBUTE_COUNT);
        for (uint256 i = 0; i < ATTRIBUTE_COUNT; i++) {
            initialAttributes[i] = _baseAttributes[i];
        }

        _relics[relicId] = Relic({
            id: relicId,
            owner: _owner,
            state: RelicState.Dormant, // Start in Dormant state
            temporalEnergy: 0, // Start with no energy
            lastInteractionTimestamp: block.timestamp,
            stateEntryTimestamp: block.timestamp,
            attributes: initialAttributes
        });

        emit RelicCreated(relicId, _owner, RelicState.Dormant, 0);
    }

    /**
     * @notice Transfers ownership of a relic.
     * @param _relicId The ID of the relic to transfer.
     * @param _to The address to transfer the relic to.
     */
    function transferRelic(uint256 _relicId, address _to) public validRelicId(_relicId) isRelicOwner(_relicId) nonReentrant {
        address from = _relics[_relicId].owner;
        _relics[_relicId].owner = _to;
        emit RelicTransferred(_relicId, from, _to);
    }

    /**
     * @notice User interaction with a relic. Consumes energy and updates timestamp.
     * @param _relicId The ID of the relic to interact with.
     */
    function interactWithRelic(uint256 _relicId) public payable validRelicId(_relicId) whenNotPaused {
         if (msg.value < interactionFee) revert InsufficientEnergy(0, msg.value, interactionFee); // Using InsufficientEnergy error for fee check

        Relic storage relic = _relics[_relicId];

        // Optional: Require minimum energy or certain state to interact
        // if (relic.temporalEnergy < _coreParameters[uint256(ParameterType.InteractionEnergyCost)]) {
        //     revert InsufficientEnergy(_relicId, relic.temporalEnergy, uint256(_coreParameters[uint256(ParameterType.InteractionEnergyCost)]));
        // }

        uint256 oldEnergy = relic.temporalEnergy;
        // Apply time decay BEFORE interaction
        _applyTemporalDecay(_relicId);

        uint256 interactionCost = uint256(_coreParameters[uint256(ParameterType.InteractionEnergyCost)]);
        uint256 interactionGain = uint256(_coreParameters[uint256(ParameterType.InteractionEnergyGain)]);

        // Ensure energy doesn't go below zero conceptually, though uint handles this
        if (relic.temporalEnergy < interactionCost) {
             relic.temporalEnergy = 0;
        } else {
             relic.temporalEnergy -= interactionCost;
        }

        relic.temporalEnergy += interactionGain; // Interaction provides some energy back

        relic.lastInteractionTimestamp = block.timestamp;

        emit RelicInteracted(_relicId, _msgSender(), relic.temporalEnergy);
        emit RelicEnergyChanged(_relicId, oldEnergy, relic.temporalEnergy, "Interaction");

        // Consider immediate state update check after interaction if it's a major trigger
        _checkStateTransition(_relicId);
    }


    /**
     * @notice Recalculates and updates the relic's state based on time, energy, and attributes.
     * Anyone can call this, paying gas to update the state.
     * @param _relicId The ID of the relic to update.
     */
    function updateRelicState(uint256 _relicId) public validRelicId(_relicId) whenNotPaused nonReentrant {
        Relic storage relic = _relics[_relicId];
        uint256 oldEnergy = relic.temporalEnergy;
        RelicState oldState = relic.state;

        // Apply decay based on time elapsed since last state check/interaction
        _applyTemporalDecay(_relicId);

        // Complex state transition logic based on energy levels, time, and attributes
        // This is where the core dynamic behavior happens.
        // Check for major state transitions only if enough time has passed or significant energy change?
        // For simplicity, let's check thresholds every time this is called.

        RelicState potentialNewState = oldState;

        // Define transition rules based on current state and energy/attributes
        uint256 currentEnergy = relic.temporalEnergy;
        uint256 timeSinceLastUpdate = block.timestamp - relic.stateEntryTimestamp;
        // Example attribute influence: attribute[0] makes it easier to reach 'Flux'
        int256 attributeInfluence = 0;
        if (relic.attributes.length > 0) {
             attributeInfluence = int256(relic.attributes[0]) * _attributeModifiers[0] + _coreParameters[uint256(ParameterType.BaseAttributeEnergyInfluence)];
        }


        if (oldState == RelicState.Dormant) {
            if (currentEnergy >= uint256(_coreParameters[uint256(ParameterType.DormantToActiveEnergyThreshold)])) {
                potentialNewState = RelicState.Active;
            }
        } else if (oldState == RelicState.Active) {
            if (currentEnergy >= uint256(_coreParameters[uint256(ParameterType.ActiveToFluxEnergyThreshold)])) {
                 // Maybe attributes also influence this transition?
                if (currentEnergy + uint256(attributeInfluence > 0 ? attributeInfluence : 0) >= uint256(_coreParameters[uint256(ParameterType.ActiveToFluxEnergyThreshold)])) {
                     potentialNewState = RelicState.Flux;
                }
            } else if (currentEnergy < uint256(_coreParameters[uint256(ParameterType.ActiveToDegradedEnergyThreshold)])) {
                potentialNewState = RelicState.Degraded;
            }
        } else if (oldState == RelicState.Flux) {
             // Flux state is volatile - can go up to Transcendent or down to Active/Degraded
             if (currentEnergy >= uint256(_coreParameters[uint256(ParameterType.FluxToTranscendentEnergyThreshold)])) {
                 potentialNewState = RelicState.Transcendent; // High threshold for Transcendent
             } else if (currentEnergy < uint256(_coreParameters[uint256(ParameterType.ActiveToDegradedEnergyThreshold)])) {
                 potentialNewState = RelicState.Degraded; // Can drop back to Degraded quickly
             } else if (currentEnergy < uint256(_coreParameters[uint256(ParameterType.ActiveToFluxEnergyThreshold)])) {
                 potentialNewState = RelicState.Active; // Can stabilize back to Active
             }
        } else if (oldState == RelicState.Degraded) {
            if (currentEnergy >= uint256(_coreParameters[uint256(ParameterType.ActiveToDegradedEnergyThreshold)])) {
                potentialNewState = RelicState.Active; // Can recover to Active
            } else if (currentEnergy < uint256(_coreParameters[uint256(ParameterType.DegradedToDormantEnergyThreshold)])) {
                potentialNewState = RelicState.Dormant; // Can fully degrade to Dormant
            }
        } else if (oldState == RelicState.Transcendent) {
            // Transcendent might require minimum energy upkeep or time in state
            // If energy drops too low, it might revert
            if (currentEnergy < uint256(_coreParameters[uint256(ParameterType.ActiveToFluxEnergyThreshold)])) { // Example: Falls below Flux threshold
                 potentialNewState = RelicState.Flux; // Revert to Flux if upkeep fails
            }
        }

        if (potentialNewState != oldState) {
            relic.state = potentialNewState;
            relic.stateEntryTimestamp = block.timestamp;
            emit RelicStateUpdated(_relicId, oldState, potentialNewState, block.timestamp);
        }

        // Emit energy change if decay happened
        if (relic.temporalEnergy != oldEnergy) {
             emit RelicEnergyChanged(_relicId, oldEnergy, relic.temporalEnergy, "Temporal Decay/Update");
        }
    }

    /**
     * @notice Perform a state-dependent action requiring a specific state and energy level.
     * Example: Boosts an attribute.
     * @param _relicId The ID of the relic.
     */
    function attuneRelic(uint256 _relicId) public validRelicId(_relicId) isRelicOwner(_relicId) whenNotPaused {
        Relic storage relic = _relics[_relicId];

        // Example: Only possible in Flux or Transcendent state
        if (relic.state != RelicState.Flux && relic.state != RelicState.Transcendent) {
            revert InvalidState(_relicId, relic.state, "Flux or Transcendent");
        }

        uint256 requiredEnergy = 100; // Example cost
        if (relic.temporalEnergy < requiredEnergy) {
            revert InsufficientEnergy(_relicId, relic.temporalEnergy, requiredEnergy);
        }

        uint256 oldEnergy = relic.temporalEnergy;
        relic.temporalEnergy -= requiredEnergy;

        // Example effect: Boost a random attribute or attribute 0
        if (relic.attributes.length > 0) {
             relic.attributes[0] += 5; // Boost attribute 0
             emit RelicAttributeChanged(_relicId, 0, relic.attributes[0]);
        }
        relic.lastInteractionTimestamp = block.timestamp; // Counts as interaction
        emit RelicEnergyChanged(_relicId, oldEnergy, relic.temporalEnergy, "Attunement");
        emit RelicInteracted(_relicId, _msgSender(), relic.temporalEnergy);

        // Check for state changes after attunement
        _checkStateTransition(_relicId);
    }

     /**
      * @notice Consumes energy to temporarily prevent time-based decay or state changes.
      * Useful in volatile states like Flux or Degraded.
      * @param _relicId The ID of the relic.
      */
    function stabilizeRelic(uint256 _relicId) public validRelicId(_relicId) isRelicOwner(_relicId) whenNotPaused {
         Relic storage relic = _relics[_relicId];

         // Example: Only possible in Flux or Degraded states
         if (relic.state != RelicState.Flux && relic.state != RelicState.Degraded) {
             revert InvalidState(_relicId, relic.state, "Flux or Degraded");
         }

         uint256 requiredEnergy = 50; // Example cost
         if (relic.temporalEnergy < requiredEnergy) {
             revert InsufficientEnergy(_relicId, relic.temporalEnergy, requiredEnergy);
         }

         uint256 oldEnergy = relic.temporalEnergy;
         relic.temporalEnergy -= requiredEnergy;

         // Effect: Reset the last interaction/state entry timestamp to effectively "pause" time influence
         relic.lastInteractionTimestamp = block.timestamp;
         relic.stateEntryTimestamp = block.timestamp; // Resets duration in current state

         emit RelicEnergyChanged(_relicId, oldEnergy, relic.temporalEnergy, "Stabilization");
         emit RelicInteracted(_relicId, _msgSender(), relic.temporalEnergy); // Counts as interaction

         // Stabilization might prevent immediate state changes, but still run the check
         _checkStateTransition(_relicId);
     }

    /**
     * @notice Admin/Oracle function to inject a simulated cosmic event that affects relics.
     * @param _eventType Type of event (defines effect logic).
     * @param _eventData Arbitrary data related to the event.
     */
    function injectCosmicEvent(uint256 _eventType, bytes _eventData) public onlyAdmin {
        // Example logic:
        // eventType 1: Cosmic Surge - adds energy to all relics in Flux state
        // eventType 2: Temporal Glitch - randomly shifts state for a percentage of relics

        if (_eventType == 1) {
            // Cosmic Surge logic
            uint256 energyBoost = 20; // Example boost
            for (uint256 i = 1; i <= _relicCounter; i++) {
                 Relic storage relic = _relics[i];
                 if (relic.state == RelicState.Flux) {
                      uint256 oldEnergy = relic.temporalEnergy;
                      relic.temporalEnergy += energyBoost;
                      emit RelicEnergyChanged(i, oldEnergy, relic.temporalEnergy, "Cosmic Surge");
                 }
            }
        } else if (_eventType == 2) {
             // Temporal Glitch logic (more complex, potentially involves randomness or criteria)
             // For simplicity, let's say it boosts energy significantly for a specific relic ID provided in _eventData
             require(_eventData.length >= 32, "Invalid event data length");
             uint256 relicIdToBoost = uint256(bytes32(_eventData));
             if (relicIdToBoost > 0 && relicIdToBoost <= _relicCounter) {
                 Relic storage relic = _relics[relicIdToBoost];
                 uint256 oldEnergy = relic.temporalEnergy;
                 relic.temporalEnergy += 100; // Significant boost
                 emit RelicEnergyChanged(relicIdToBoost, oldEnergy, relic.temporalEnergy, "Temporal Glitch Boost");
                 // Glitch might also force a state check
                 _checkStateTransition(relicIdToBoost);
             } else {
                  revert RelicNotFound(relicIdToBoost);
             }

        } else {
            // Handle other event types or revert
            // For this example, we'll just emit the event for unhandled types
            emit CosmicEventInjected(_eventType, _eventData);
            return;
        }

        emit CosmicEventInjected(_eventType, _eventData);
    }

    /**
     * @notice Burns a relic for a specific benefit. Only possible in certain states.
     * Example: Reclaiming some value or triggering an event.
     * @param _relicId The ID of the relic to sacrifice.
     */
    function sacrificeRelic(uint256 _relicId) public validRelicId(_relicId) isRelicOwner(_relicId) nonReentrant {
        Relic storage relic = _relics[_relicId];

        // Example: Only allowed in Degraded or Dormant states
        if (relic.state != RelicState.Degraded && relic.state != RelicState.Dormant) {
             revert SacrificeNotAllowed(_relicId, relic.state);
        }

        // Example benefit: Send back a small amount of ETH (simulate reclaiming value)
        uint256 returnAmount = address(this).balance / 1000; // Example: 0.1% of contract balance
        if (returnAmount > 0) {
             (bool success, ) = payable(_msgSender()).call{value: returnAmount}("");
             require(success, "ETH transfer failed");
        }


        // Record final state and energy before deletion
        RelicState finalState = relic.state;
        uint256 finalEnergy = relic.temporalEnergy;

        // Delete the relic data
        delete _relics[_relicId];

        emit RelicSacrificed(_relicId, _msgSender(), finalState, finalEnergy);
    }

    // --- View Functions ---

    /**
     * @notice Gets detailed information about a relic.
     * @param _relicId The ID of the relic.
     * @return struct Relic The relic details.
     */
    function getRelicDetails(uint256 _relicId) public view validRelicId(_relicId) returns (Relic memory) {
        Relic storage relic = _relics[_relicId];
        uint256[] memory currentAttributes = new uint256[](relic.attributes.length);
        for(uint256 i=0; i<relic.attributes.length; i++) {
            currentAttributes[i] = relic.attributes[i];
        }
        // Need to return a memory struct for view functions with mappings/arrays
        return Relic({
            id: relic.id,
            owner: relic.owner,
            state: relic.state,
            temporalEnergy: relic.temporalEnergy, // Note: Does not apply decay in view
            lastInteractionTimestamp: relic.lastInteractionTimestamp,
            stateEntryTimestamp: relic.stateEntryTimestamp,
            attributes: currentAttributes
        });
    }

     /**
     * @notice Gets the current state of a relic.
     * @param _relicId The ID of the relic.
     * @return RelicState The current state.
     */
    function getRelicState(uint256 _relicId) public view validRelicId(_relicId) returns (RelicState) {
         return _relics[_relicId].state;
    }

     /**
     * @notice Gets the current temporal energy of a relic.
     * Note: This view function does NOT apply time-based decay. Use updateRelicState for on-chain decay.
     * @param _relicId The ID of the relic.
     * @return uint256 The temporal energy.
     */
    function getRelicEnergy(uint256 _relicId) public view validRelicId(_relicId) returns (uint256) {
         return _relics[_relicId].temporalEnergy;
    }

     /**
     * @notice Gets the owner of a relic.
     * @param _relicId The ID of the relic.
     * @return address The owner address.
     */
    function getRelicOwner(uint256 _relicId) public view validRelicId(_relicId) returns (address) {
         return _relics[_relicId].owner;
    }

     /**
     * @notice Gets a specific dynamic attribute of a relic.
     * @param _relicId The ID of the relic.
     * @param _attributeIndex The index of the attribute (0 to ATTRIBUTE_COUNT-1).
     * @return uint256 The attribute value.
     */
    function getRelicAttribute(uint256 _relicId, uint256 _attributeIndex) public view validRelicId(_relicId) returns (uint256) {
         Relic storage relic = _relics[_relicId];
         if (_attributeIndex >= relic.attributes.length) revert InvalidAttributeIndex(_attributeIndex);
         return relic.attributes[_attributeIndex];
     }

    /**
     * @notice Predicts the state the relic would transition to if updateRelicState were called now.
     * Does not change state on-chain.
     * @param _relicId The ID of the relic.
     * @return RelicState The predicted state.
     */
    function predictNextState(uint256 _relicId) public view validRelicId(_relicId) returns (RelicState) {
        Relic storage relic = _relics[_relicId];
        RelicState currentState = relic.state;
        uint256 currentEnergy = relic.temporalEnergy; // Use current energy for prediction
        // For a true prediction incorporating *potential* decay, one would need to
        // simulate decay based on elapsed time since last interaction, but that's
        // complex in a view function without state changes.
        // This prediction is based on *current* values.

        // Example attribute influence prediction: attribute[0] makes it easier to reach 'Flux'
        int256 attributeInfluence = 0;
        if (relic.attributes.length > 0) {
             attributeInfluence = int256(relic.attributes[0]) * _attributeModifiers[0] + _coreParameters[uint256(ParameterType.BaseAttributeEnergyInfluence)];
        }


        if (currentState == RelicState.Dormant) {
            if (currentEnergy >= uint256(_coreParameters[uint256(ParameterType.DormantToActiveEnergyThreshold)])) {
                return RelicState.Active;
            }
        } else if (currentState == RelicState.Active) {
            if (currentEnergy >= uint256(_coreParameters[uint256(ParameterType.ActiveToFluxEnergyThreshold)])) {
                 if (currentEnergy + uint256(attributeInfluence > 0 ? attributeInfluence : 0) >= uint256(_coreParameters[uint256(ParameterType.ActiveToFluxEnergyThreshold)])) {
                      return RelicState.Flux;
                 }
            } else if (currentEnergy < uint256(_coreParameters[uint256(ParameterType.ActiveToDegradedEnergyThreshold)])) {
                return RelicState.Degraded;
            }
        } else if (currentState == RelicState.Flux) {
             if (currentEnergy >= uint256(_coreParameters[uint256(ParameterType.FluxToTranscendentEnergyThreshold)])) {
                 return RelicState.Transcendent;
             } else if (currentEnergy < uint256(_coreParameters[uint256(ParameterType.ActiveToDegradedEnergyThreshold)])) {
                 return RelicState.Degraded;
             } else if (currentEnergy < uint256(_coreParameters[uint256(ParameterType.ActiveToFluxEnergyThreshold)])) {
                 return RelicState.Active;
             }
        } else if (currentState == RelicState.Degraded) {
            if (currentEnergy >= uint256(_coreParameters[uint256(ParameterType.ActiveToDegradedEnergyThreshold)])) {
                return RelicState.Active;
            } else if (currentEnergy < uint256(_coreParameters[uint256(ParameterType.DegradedToDormantEnergyThreshold)])) {
                return RelicState.Dormant;
            }
        } else if (currentState == RelicState.Transcendent) {
            if (currentEnergy < uint256(_coreParameters[uint256(ParameterType.ActiveToFluxEnergyThreshold)])) {
                 return RelicState.Flux;
            }
        }

        // If no transition condition is met, stay in the current state
        return currentState;
    }

    /**
     * @notice Checks if a relic meets complex criteria based on state, energy, attributes, and time.
     * Example: Is it ready for 'fusion'? Does it meet requirements for a public bounty?
     * @param _relicId The ID of the relic.
     * @param _conditionType The type of condition to check.
     * @return bool True if the condition is met, false otherwise.
     */
    function queryStateCondition(uint256 _relicId, uint256 _conditionType) public view validRelicId(_relicId) returns (bool) {
        Relic storage relic = _relics[_relicId];
        uint256 currentEnergy = relic.temporalEnergy;
        uint256 timeInState = block.timestamp - relic.stateEntryTimestamp;
        // Need to retrieve attributes safely
        uint256 attribute0 = relic.attributes.length > 0 ? relic.attributes[0] : 0;
        uint256 attribute1 = relic.attributes.length > 1 ? relic.attributes[1] : 0;


        // Example Conditions:
        if (_conditionType == 1) { // Is it "Fusion Ready"? (Example: Active state + High Energy + Specific Attribute)
             return relic.state == RelicState.Active && currentEnergy >= 150 && attribute0 >= 20;
        } else if (_conditionType == 2) { // Is it "Temporal Anomaly"? (Example: Flux state + High Time in State)
             return relic.state == RelicState.Flux && timeInState >= 1 day;
        } else if (_conditionType == 3) { // Is it "Decay Critical"? (Example: Degraded state + Very Low Energy)
             return relic.state == RelicState.Degraded && currentEnergy < 15;
        }
        // Add more complex conditions based on game/app logic

        // If condition type is not recognized
        return false;
    }

    /**
     * @notice Returns the total number of relics created.
     * @return uint256 The total count.
     */
    function getRelicCount() public view returns (uint256) {
         return _relicCounter;
    }

    /**
     * @notice Returns the duration (in seconds) the relic has been in its current state.
     * @param _relicId The ID of the relic.
     * @return uint256 The duration in seconds.
     */
    function getCurrentStateDuration(uint256 _relicId) public view validRelicId(_relicId) returns (uint256) {
         return block.timestamp - _relics[_relicId].stateEntryTimestamp;
    }

     /**
      * @notice Estimates the potential energy decay over a given time period based on current parameters.
      * This is a pure function, it does not read relic-specific data.
      * @param _timeElapsed The time period in seconds.
      * @return uint256 The estimated energy loss.
      */
    function estimateEnergyDecay(uint256 _timeElapsed) public view returns (uint256) {
        // Note: This doesn't account for relic-specific attributes that might influence decay.
        // A more complex pure function could take attributes as input.
         int256 decayRate = _coreParameters[uint256(ParameterType.EnergyDecayRatePerSecond)];
         // Ensure decayRate is positive for decay
         if (decayRate < 0) return 0;
         return _timeElapsed * uint256(decayRate);
    }

    /**
     * @notice Checks if a relic is eligible to perform a specific state-dependent action.
     * @param _relicId The ID of the relic.
     * @param _actionType The type of action to check eligibility for (e.g., 1 for Attune).
     * @return bool True if eligible, false otherwise.
     */
    function checkRelicEligibilityForAction(uint256 _relicId, uint256 _actionType) public view validRelicId(_relicId) returns (bool) {
        Relic storage relic = _relics[_relicId];
        uint256 currentEnergy = relic.temporalEnergy;

        // Example Action Types:
        if (_actionType == 1) { // Check eligibility for attuneRelic
             uint256 requiredEnergy = 100; // Matches attuneRelic cost
             return (relic.state == RelicState.Flux || relic.state == RelicState.Transcendent) && currentEnergy >= requiredEnergy;
        } else if (_actionType == 2) { // Check eligibility for stabilizeRelic
             uint256 requiredEnergy = 50; // Matches stabilizeRelic cost
             return (relic.state == RelicState.Flux || relic.state == RelicState.Degraded) && currentEnergy >= requiredEnergy;
        } else if (_actionType == 3) { // Check eligibility for sacrificeRelic
             return (relic.state == RelicState.Degraded || relic.state == RelicState.Dormant);
        }

        // Default: Not eligible if action type is unknown
        return false;
    }

    /**
     * @notice Gets the current admin address.
     */
    function getAdmin() public view returns (address) {
        return _admin;
    }

    // --- Admin & Owner Functions ---

    /**
     * @notice Owner can change the admin address.
     * @param _newAdmin The address of the new admin.
     */
    function setAdmin(address _newAdmin) public onlyOwner {
        address oldAdmin = _admin;
        _admin = _newAdmin;
        emit AdminChanged(oldAdmin, _newAdmin);
    }

    /**
     * @notice Admin can modify a specific dynamic attribute of a relic.
     * Useful for balancing or responding to off-chain events/decisions.
     * @param _relicId The ID of the relic.
     * @param _attributeIndex The index of the attribute (0 to ATTRIBUTE_COUNT-1).
     * @param _newValue The new value for the attribute.
     */
    function modifyRelicAttribute(uint256 _relicId, uint256 _attributeIndex, uint256 _newValue) public validRelicId(_relicId) onlyAdmin {
         Relic storage relic = _relics[_relicId];
         if (_attributeIndex >= relic.attributes.length) revert InvalidAttributeIndex(_attributeIndex);
         relic.attributes[_attributeIndex] = _newValue;
         emit RelicAttributeChanged(_relicId, _attributeIndex, _newValue);
         // Consider forcing a state update check here if attribute changes significantly affect state
         _checkStateTransition(_relicId);
     }

     /**
      * @notice Admin sets the base value for an attribute for all *new* relics.
      * @param _attributeIndex The index of the attribute.
      * @param _baseValue The new base value.
      */
    function setRelicAttributeBase(uint256 _attributeIndex, uint256 _baseValue) public onlyAdmin {
         if (_attributeIndex >= ATTRIBUTE_COUNT) revert InvalidAttributeIndex(_attributeIndex);
         _baseAttributes[_attributeIndex] = _baseValue;
     }

    /**
     * @notice Admin sets a global modifier for how an attribute influences relic dynamics (e.g., energy changes).
     * @param _attributeIndex The index of the attribute.
     * @param _modifier The new modifier value (can be positive or negative).
     */
    function setRelicAttributeModifier(uint256 _attributeIndex, int256 _modifier) public onlyAdmin {
         if (_attributeIndex >= ATTRIBUTE_COUNT) revert InvalidAttributeIndex(_attributeIndex);
         _attributeModifiers[_attributeIndex] = _modifier;
         emit RelicAttributeModifierChanged(_attributeIndex, _modifier);
     }


    /**
     * @notice Admin proposes a change to a core contract parameter, starting a timelock.
     * Only one parameter change can be proposed at a time.
     * @param _paramType The type of parameter to change (enum ParameterType).
     * @param _newValue The new value for the parameter (int256 to allow negative values if needed).
     */
    function proposeCriticalParameterChange(uint256 _paramType, int256 _newValue) public onlyAdmin {
        if (_paramType >= uint256(ParameterType.StateTransitionCheckInterval) + 1) revert InvalidParameterType(_paramType); // Basic type validation
        if (_proposedParameterChange.exists) revert ParameterChangeAlreadyProposed(_proposedParameterChange.paramType);

        uint256 timelock = _timelockDurations[uint256(TimelockActionType.CriticalParameterChange)];
        uint256 expiry = block.timestamp + timelock;

        _proposedParameterChange = ProposedParameterChange({
            paramType: _paramType,
            newValue: _newValue,
            timelockExpiry: expiry,
            exists: true
        });

        emit CriticalParameterChangeProposed(_paramType, _newValue, expiry);
    }

    /**
     * @notice Admin executes a proposed parameter change after the timelock has expired.
     */
    function executeCriticalParameterChange() public onlyAdmin {
        if (!_proposedParameterChange.exists) revert NoParameterChangeProposed();
        if (block.timestamp < _proposedParameterChange.timelockExpiry) {
            revert TimelockNotExpired(_proposedParameterChange.timelockExpiry - block.timestamp);
        }

        _coreParameters[_proposedParameterChange.paramType] = _proposedParameterChange.newValue;
        emit CriticalParameterChangeExecuted(_proposedParameterChange.paramType, _proposedParameterChange.newValue);

        // Clear the proposal
        delete _proposedParameterChange;
    }

    /**
     * @notice Admin can pause certain user interactions (like `interactWithRelic`).
     */
    function pauseInteractions() public onlyAdmin whenNotPaused {
        _paused = true;
        emit InteractionsPaused();
    }

    /**
     * @notice Admin can unpause user interactions.
     */
    function unpauseInteractions() public onlyAdmin whenPaused {
        _paused = false;
        emit InteractionsUnpaused();
    }

    /**
     * @notice Admin can withdraw accumulated fees (e.g., creationFee, interactionFee).
     * @param _to The address to send the fees to.
     */
    function withdrawFees(address _to) public onlyAdmin nonReentrant {
        uint256 balance = address(this).balance;
        if (balance == 0) return;

        (bool success, ) = payable(_to).call{value: balance}("");
        require(success, "Fee withdrawal failed");

        emit FeesWithdrawn(_to, balance);
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Applies temporal decay to a relic's energy based on time elapsed since last interaction/update.
     * @param _relicId The ID of the relic.
     */
    function _applyTemporalDecay(uint256 _relicId) internal {
        Relic storage relic = _relics[_relicId];
        uint256 timeElapsed = block.timestamp - relic.lastInteractionTimestamp; // Time since *any* timestamp update

        // Only apply decay if significant time has passed
        if (timeElapsed == 0) return;

        int256 decayRate = _coreParameters[uint256(ParameterType.EnergyDecayRatePerSecond)];
        uint256 energyDecay = 0;

        // Calculate decay, ensuring positive decay rate
        if (decayRate > 0) {
             energyDecay = timeElapsed * uint256(decayRate);
        }

        // Example: Attribute[1] reduces decay
        if (relic.attributes.length > 1) {
             int256 decayReduction = int256(relic.attributes[1]) * _attributeModifiers[1];
             // Prevent reduction from exceeding decay
             energyDecay = (energyDecay > 0 && decayReduction > 0) ? (energyDecay > uint256(decayReduction) ? energyDecay - uint256(decayReduction) : 0) : energyDecay;
        }


        uint256 oldEnergy = relic.temporalEnergy;
        if (relic.temporalEnergy >= energyDecay) {
            relic.temporalEnergy -= energyDecay;
        } else {
            relic.temporalEnergy = 0;
        }

        // Update timestamp *after* calculating decay
        relic.lastInteractionTimestamp = block.timestamp; // Or set to block.timestamp if decay was applied
        // Note: This timestamp is used for *decay* calculation. State entry timestamp is separate.

        // Emit energy change if it occurred
        if (relic.temporalEnergy != oldEnergy) {
             emit RelicEnergyChanged(_relicId, oldEnergy, relic.temporalEnergy, "Temporal Decay Applied");
        }
    }

     /**
      * @dev Internal function to check for potential state transitions after energy/time updates.
      * Called by functions that modify energy or time.
      * @param _relicId The ID of the relic.
      */
     function _checkStateTransition(uint256 _relicId) internal {
         Relic storage relic = _relics[_relicId];
         uint256 timeSinceStateUpdate = block.timestamp - relic.stateEntryTimestamp;

         // Only check for major state transitions if a certain interval has passed since the last *actual* state change
         // or if this check is triggered by a major event (like interaction or cosmic event)
         // For simplicity, let's make this check always attempt the state update logic.
         // A more advanced version might only call updateRelicState here if timeSinceStateUpdate > StateTransitionCheckInterval

         // Call the main state update logic
         updateRelicState(_relicId);
     }


    // --- Fallback/Receive to accept ETH fees ---
    receive() external payable {}
    fallback() external payable {}
}
```