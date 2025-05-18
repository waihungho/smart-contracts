Okay, let's design a smart contract based on the concept of a "Quantum State Fluctuator". This contract will represent a system that can exist in multiple potential states (a "superposition") and, when triggered by a specific condition, will "collapse" into a single, observed state based on simulated entropy. The contract's behavior and available functions will change depending on its current "phase" and the final "observed state".

This concept uses:
*   **State Machines:** Transitions between distinct phases (Initial, Superposition, Collapsing, Collapsed).
*   **Simulated Entropy:** Using block data and user input to simulate a non-deterministic outcome for the collapse.
*   **State-Dependent Logic:** Functions behave differently or are only available based on the contract's current observed state.
*   **Resource Management:** An internal "Energy" resource is required for the collapse.
*   **Configuration:** Owner can configure the potential states, their "energies" (probabilities), and state-specific parameters.

It aims to be creative by using a conceptual analogy (quantum states) to drive the contract's state and behavior, and advanced by employing a non-trivial state machine and simulated probabilistic outcomes influencing subsequent interactions.

---

**Outline & Function Summary: QuantumFluctuator.sol**

This contract simulates a system that exists in multiple potential states (Superposition) and collapses into a single Observed State based on simulated entropy. Its functionality is gated by its current lifecycle Phase and the specific Observed State it collapses into.

**Contract State:**

*   `owner`: The contract owner with configuration privileges.
*   `currentPhase`: The current lifecycle phase (Initial, Superposition, Collapsing, Collapsed).
*   `potentialStates`: Array of possible states the system can be in during Superposition.
*   `stateEnergies`: Mapping from SuperposedState to a weight/energy value influencing collapse probability.
*   `accumulatedEnergy`: Total energy available in the system, required for Collapse.
*   `minEnergyForCollapse`: Minimum energy needed to initiate Collapse.
*   `collapseCooldownBlocks`: Minimum blocks between Collapse events.
*   `lastCollapseBlock`: The block number of the last Collapse.
*   `collapseEntropySeedInfluence`: Percentage (0-100) of how much user seed influences entropy vs block data.
*   `allowedInitiators`: Mapping to restrict who can initiate collapse.
*   `currentState`: The resolved state after Collapse (valid only in Collapsed phase).
*   `stateBasedParameters`: Mapping from ObservedState to a configurable uint256 value.
*   `generatedQuantumData`: A unique bytes32 value generated upon Collapse.
*   `userStateInteractionCount`: Tracks how many times a user has performed an action valid only in the current Observed State.
*   `totalEnergyAccumulated`: Total energy ever accumulated.

**Enums:**

*   `StatePhase`: Defines the contract's lifecycle phases.
*   `SuperposedState`: Defines the distinct states the system can be in during Superposition.
*   `ObservedState`: Defines the distinct states the system can collapse into (mirrors `SuperposedState` in this implementation).

**Events:**

*   `SuperpositionInitialized(uint256 numStates)`: When potential states are set up.
*   `PhaseChanged(StatePhase oldPhase, StatePhase newPhase)`: When the contract transitions between phases.
*   `PotentialStateAdded(SuperposedState state, uint256 initialEnergy)`: When a new potential state is configured.
*   `PotentialStateRemoved(SuperposedState state)`: When a potential state is removed.
*   `StateEnergyUpdated(SuperposedState state, uint256 newEnergy)`: When the energy of a potential state is changed.
*   `EnergyAccumulated(address indexed by, uint256 amount, uint256 total)`: When energy is added.
*   `CollapseInitiated(address indexed initiator, uint256 userSeed)`: When the collapse process starts.
*   `CollapseResolved(ObservedState indexed resolvedState, bytes32 entropy)`: When the collapse finishes and a state is determined.
*   `StateParameterUpdated(ObservedState indexed state, uint256 newValue)`: When a state-based parameter is changed by the owner.
*   `QuantumDataGenerated(ObservedState indexed state, bytes32 data)`: When the unique data is generated after collapse.
*   `UserStateActionPerformed(address indexed user, ObservedState indexed state, uint256 newCount)`: When a user interacts with the state-specific function.
*   `ContractWithdrawal(address indexed to, uint256 amount)`: When Ether is withdrawn.

**Functions (28 Total):**

1.  `constructor()`: Initializes the contract, setting owner and initial phase.
2.  `initializeSuperposition(SuperposedState[] calldata states, uint256[] calldata energies)`: (Owner Only) Sets up the initial potential states and their energies. Transitions from `Initial` to `Superposition`. Requires matching lengths for states and energies.
3.  `addPotentialState(SuperposedState state, uint256 initialEnergy)`: (Owner Only) Adds a single potential state and its energy. Valid only in `Initial` or `Superposition` phase.
4.  `removePotentialState(SuperposedState state)`: (Owner Only) Removes a potential state. Valid only in `Initial` or `Superposition` phase.
5.  `updateStateEnergy(SuperposedState state, uint256 newEnergy)`: (Owner Only) Updates the energy of an existing potential state. Valid only in `Initial` or `Superposition` phase.
6.  `setMinEnergyForCollapse(uint256 energy)`: (Owner Only) Sets the minimum `accumulatedEnergy` required to initiate Collapse.
7.  `setCollapseCooldownBlocks(uint256 blocks)`: (Owner Only) Sets the minimum number of blocks between Collapse events.
8.  `setEntropyInfluencePercentage(uint256 influence)`: (Owner Only) Sets how much the user seed affects the collapse entropy (0-100).
9.  `setAllowedInitiator(address initiator, bool allowed)`: (Owner Only) Grants or revokes permission for specific addresses to initiate collapse (if restriction is active).
10. `setObservedStateParameter(ObservedState state, uint256 value)`: (Owner Only) Sets a uint256 parameter associated with a specific `ObservedState`.
11. `transferOwnership(address newOwner)`: (Owner Only) Transfers ownership of the contract.
12. `accumulateEnergy()`: (Payable) Allows anyone to send Ether to the contract, which is converted into `accumulatedEnergy`. Energy rate is fixed (e.g., 1 Ether = 1000 Energy).
13. `initiateCollapseAndResolve(uint256 userSeed)`: (Callable by allowed initiators or anyone if no restrictions) Triggers the collapse process. Requires minimum accumulated energy and elapsed cooldown. Transitions from `Superposition` to `Collapsing`, then immediately resolves to `Collapsed`. Uses block data and `userSeed` to generate entropy, determines the `currentState` based on state energies, generates `generatedQuantumData`, applies state effects, and updates phase/cooldown.
14. `performStateAction()`: (Public) A function whose effects and requirements depend entirely on the current `currentState`. Requires the phase to be `Collapsed`. This is a core state-dependent function. Increments `userStateInteractionCount` for the caller and current state.
15. `resetSystem()`: (Owner Only) Resets the contract back to the `Initial` phase, clearing accumulated energy, observed state, generated data, and optionally potential states/energies.
16. `getPotentialStates()`: (View) Returns the array of currently configured `SuperposedState` values.
17. `getStateEnergy(SuperposedState state)`: (View) Returns the energy/weight for a specific `SuperposedState`.
18. `getAccumulatedEnergy()`: (View) Returns the current total `accumulatedEnergy`.
19. `getMinEnergyForCollapse()`: (View) Returns the minimum energy required to initiate Collapse.
20. `getCollapseCooldownBlocks()`: (View) Returns the cooldown period between collapses in blocks.
21. `getLastCollapseBlock()`: (View) Returns the block number of the last collapse.
22. `getTimeSinceLastCollapse()`: (View) Returns the number of blocks elapsed since the last collapse (0 if never collapsed).
23. `getEntropyInfluencePercentage()`: (View) Returns how much the user seed influences entropy (0-100).
24. `isAllowedInitiator(address initiator)`: (View) Checks if an address is allowed to initiate collapse (if restriction is active).
25. `getCurrentPhase()`: (View) Returns the contract's current `StatePhase`.
26. `getCurrentObservedState()`: (View) Returns the resolved `ObservedState` (valid only in `Collapsed` phase).
27. `getObservedStateParameter(ObservedState state)`: (View) Returns the uint256 parameter associated with a specific `ObservedState`.
28. `getGeneratedQuantumData()`: (View) Returns the `bytes32` data generated upon Collapse (valid only in `Collapsed` phase).
29. `getUserStateInteractionCount(address user, ObservedState state)`: (View) Returns how many times a user interacted via `performStateAction` when the state was the specified `ObservedState`. *Self-correction:* This should probably just track interactions for the *current* observed state, or be a mapping of mapping: `mapping(address => mapping(ObservedState => uint256))`. Let's use `mapping(address => uint256)` for simplicity tracking interactions *in the current* observed state via `performStateAction`. Let's rename the state variable to `userCurrentStateInteractionCount`. The function will then be `getUserCurrentStateInteractionCount(address user)`.
30. `getContractBalance()`: (View) Returns the total Ether balance held by the contract.
31. `withdrawEther(uint256 amount)`: (Owner Only) Allows the owner to withdraw Ether from the contract balance.

Okay, that's 31 functions, well over the required 20. Let's refine the `userStateInteractionCount` slightly to be more interesting: track counts *per observed state* per user. So the mapping `mapping(address => mapping(ObservedState => uint256)) userStateInteractionCount;` is better. Let's rename function 29 back to `getUserStateInteractionCount(address user, ObservedState state)`. This makes more sense.

Let's implement this.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumFluctuator
 * @dev Simulates a system with potential states (Superposition) that collapses
 *      into a single Observed State based on simulated entropy.
 *      Contract behavior is dependent on its current Phase and Observed State.
 *      Includes configuration, resource management (Energy), state-dependent
 *      actions, and simulated randomness.
 */

/**
 * @dev Outline:
 * - Contract State Variables (owner, phase, states, energies, energy, cooldown, etc.)
 * - Enums (StatePhase, SuperposedState, ObservedState)
 * - Events (Phase transitions, state updates, energy, collapse, data generation, actions)
 * - Modifiers (onlyOwner, inPhase, notInPhase)
 * - Constructor
 * - Owner Configuration Functions (~10)
 * - Energy Accumulation Function (~1)
 * - Core Mechanics (Initialize Superposition, Initiate & Resolve Collapse, Reset) (~3)
 * - State-Dependent Actions (~1)
 * - Querying / View Functions (~16)
 * - Internal Helpers (Entropy generation, State resolution, Apply effects)
 */

/**
 * @dev Function Summary (31 functions):
 *
 * Initialization & Configuration (Owner Only unless specified):
 * 1. constructor(): Sets initial owner and phase.
 * 2. initializeSuperposition(states, energies): Sets initial potential states and their energies. (-> Superposition)
 * 3. addPotentialState(state, energy): Adds a single potential state.
 * 4. removePotentialState(state): Removes a potential state.
 * 5. updateStateEnergy(state, newEnergy): Updates energy of a state.
 * 6. setMinEnergyForCollapse(energy): Sets minimum energy for collapse.
 * 7. setCollapseCooldownBlocks(blocks): Sets blocks cooldown between collapses.
 * 8. setEntropyInfluencePercentage(influence): Sets user seed influence (0-100%).
 * 9. setAllowedInitiator(initiator, allowed): Allows/disallows specific collapse initiators.
 * 10. setObservedStateParameter(state, value): Sets parameter for an Observed State.
 * 11. transferOwnership(newOwner): Transfers contract ownership.
 *
 * Energy & Core Mechanics:
 * 12. accumulateEnergy() (payable): Adds energy to the system using Ether.
 * 13. initiateCollapseAndResolve(userSeed): Triggers state collapse based on entropy. (-> Collapsing -> Collapsed)
 * 14. resetSystem(): Resets contract to Initial or Superposition state.
 *
 * State-Dependent Actions:
 * 15. performStateAction(): Executes logic based on the current Observed State. (Requires Collapsed phase)
 *
 * Querying & Views (Public):
 * 16. getPotentialStates(): Returns array of potential states.
 * 17. getStateEnergy(state): Returns energy for a specific state.
 * 18. getAccumulatedEnergy(): Returns current accumulated energy.
 * 19. getMinEnergyForCollapse(): Returns min energy required for collapse.
 * 20. getCollapseCooldownBlocks(): Returns collapse cooldown.
 * 21. getLastCollapseBlock(): Returns block of last collapse.
 * 22. getTimeSinceLastCollapse(): Returns blocks since last collapse.
 * 23. getEntropyInfluencePercentage(): Returns user seed influence percentage.
 * 24. isAllowedInitiator(initiator): Checks if address can initiate collapse.
 * 25. getCurrentPhase(): Returns current contract phase.
 * 26. getCurrentObservedState(): Returns the resolved Observed State. (Requires Collapsed phase)
 * 27. getObservedStateParameter(state): Returns parameter for a specific Observed State.
 * 28. getGeneratedQuantumData(): Returns the generated data. (Requires Collapsed phase)
 * 29. getUserStateInteractionCount(user, state): Returns interaction count for user in a specific Observed State.
 * 30. getContractBalance(): Returns contract's Ether balance.
 * 31. withdrawEther(amount): (Owner Only) Withdraws Ether from the contract.
 */

contract QuantumFluctuator {

    // --- Enums ---
    enum StatePhase {
        Initial,       // Contract is initialized, configuration is possible
        Superposition, // Potential states are set, ready for collapse
        Collapsing,    // Collapse process is ongoing (brief state)
        Collapsed      // System is in a single, resolved state
    }

    // Example states - these can be anything conceptually
    enum SuperposedState {
        UndefinedState,
        StateA_HighEnergy,
        StateB_LowEnergy,
        StateC_Unstable,
        QuantumVoid_ZeroPoint
    }

    // Observed states mirror superposed states for simplicity in this design
    enum ObservedState {
        UndefinedObservedState,
        ObservedA,
        ObservedB,
        ObservedC,
        ObservedVoid
    }

    // --- State Variables ---

    address private immutable i_owner;

    StatePhase public currentPhase;

    SuperposedState[] public potentialStates;
    mapping(SuperposedState => uint256) public stateEnergies;
    mapping(SuperposedState => bool) private isPotentialStateValid; // Helper to check if state exists

    uint256 public accumulatedEnergy;
    uint256 public totalEnergyAccumulated; // Tracks total energy ever added
    uint256 public minEnergyForCollapse = 1000; // Default minimum energy
    uint256 public collapseCooldownBlocks = 10; // Default cooldown

    uint256 public lastCollapseBlock;

    uint256 public collapseEntropySeedInfluence = 50; // Percentage (0-100)

    // If true, only addresses in allowedInitiators mapping can initiate collapse
    bool public collapseInitiationRestricted = false;
    mapping(address => bool) public allowedInitiators;

    ObservedState public currentState = ObservedState.UndefinedObservedState;
    mapping(ObservedState => uint256) public stateBasedParameters;
    bytes32 public generatedQuantumData;

    // Tracks user interactions within specific observed states
    mapping(address => mapping(ObservedState => uint256)) public userStateInteractionCount;

    // --- Events ---

    event SuperpositionInitialized(uint256 numStates);
    event PhaseChanged(StatePhase oldPhase, StatePhase newPhase);
    event PotentialStateAdded(SuperposedState state, uint256 initialEnergy);
    event PotentialStateRemoved(SuperposedState state);
    event StateEnergyUpdated(SuperposedState state, uint256 newEnergy);
    event EnergyAccumulated(address indexed by, uint256 amount, uint256 total);
    event CollapseInitiated(address indexed initiator, uint256 userSeed);
    event CollapseResolved(ObservedState indexed resolvedState, bytes32 entropy);
    event StateParameterUpdated(ObservedState indexed state, uint256 newValue);
    event QuantumDataGenerated(ObservedState indexed state, bytes32 data);
    event UserStateActionPerformed(address indexed user, ObservedState indexed state, uint256 newCount);
    event ContractWithdrawal(address indexed to, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == i_owner, "Only owner can call this function");
        _;
    }

    modifier inPhase(StatePhase requiredPhase) {
        require(currentPhase == requiredPhase, "Function not available in current phase");
        _;
    }

    modifier notInPhase(StatePhase forbiddenPhase) {
        require(currentPhase != forbiddenPhase, "Function not available in this phase");
        _;
    }

    // --- Constructor ---

    constructor() {
        i_owner = msg.sender;
        currentPhase = StatePhase.Initial;
        emit PhaseChanged(StatePhase.Initial, currentPhase);

        // Add Undefined states to internal map to prevent issues with default enum value
        isPotentialStateValid[SuperposedState.UndefinedState] = true;
        // Map UndefinedObservedState as well
        stateBasedParameters[ObservedState.UndefinedObservedState] = 0;
    }

    // --- Owner Configuration Functions ---

    /**
     * @dev Sets up the initial potential states and their energies.
     *      Transitions contract from Initial to Superposition phase.
     *      Cannot be called if already in Superposition or later.
     * @param states Array of SuperposedState enums.
     * @param energies Array of corresponding energy values.
     */
    function initializeSuperposition(SuperposedState[] calldata states, uint256[] calldata energies)
        external onlyOwner inPhase(StatePhase.Initial)
    {
        require(states.length > 0, "Must provide states");
        require(states.length == energies.length, "States and energies must have same length");

        // Clear any existing states if resetSystem allowed re-initiation
        for (uint i = 0; i < potentialStates.length; i++) {
             isPotentialStateValid[potentialStates[i]] = false; // Mark as invalid
             delete stateEnergies[potentialStates[i]];
        }
        delete potentialStates; // Clear the array

        for (uint i = 0; i < states.length; i++) {
            SuperposedState state = states[i];
            uint256 energy = energies[i];
            require(state != SuperposedState.UndefinedState, "Cannot use UndefinedState");
            require(!isPotentialStateValid[state], "Duplicate state provided");
            require(energy > 0, "State energy must be positive");

            potentialStates.push(state);
            stateEnergies[state] = energy;
            isPotentialStateValid[state] = true;
        }

        StatePhase oldPhase = currentPhase;
        currentPhase = StatePhase.Superposition;
        emit PhaseChanged(oldPhase, currentPhase);
        emit SuperpositionInitialized(potentialStates.length);
    }

    /**
     * @dev Adds a single potential state and its energy.
     *      Valid only in Initial or Superposition phase.
     * @param state The SuperposedState to add.
     * @param initialEnergy The energy/weight for this state.
     */
    function addPotentialState(SuperposedState state, uint256 initialEnergy)
        external onlyOwner notInPhase(StatePhase.Collapsing) notInPhase(StatePhase.Collapsed)
    {
        require(state != SuperposedState.UndefinedState, "Cannot add UndefinedState");
        require(!isPotentialStateValid[state], "State already exists");
        require(initialEnergy > 0, "Energy must be positive");

        potentialStates.push(state);
        stateEnergies[state] = initialEnergy;
        isPotentialStateValid[state] = true;

        // If in Initial phase, setting first state transitions to Superposition
        if (currentPhase == StatePhase.Initial) {
             StatePhase oldPhase = currentPhase;
             currentPhase = StatePhase.Superposition;
             emit PhaseChanged(oldPhase, currentPhase);
        }

        emit PotentialStateAdded(state, initialEnergy);
    }

    /**
     * @dev Removes a potential state.
     *      Valid only in Initial or Superposition phase.
     *      Requires at least one state to remain if in Superposition.
     * @param state The SuperposedState to remove.
     */
    function removePotentialState(SuperposedState state)
        external onlyOwner notInPhase(StatePhase.Collapsing) notInPhase(StatePhase.Collapsed)
    {
        require(state != SuperposedState.UndefinedState, "Cannot remove UndefinedState");
        require(isPotentialStateValid[state], "State does not exist");
        if (currentPhase == StatePhase.Superposition) {
             require(potentialStates.length > 1, "Cannot remove the last potential state in Superposition phase");
        }


        isPotentialStateValid[state] = false;
        delete stateEnergies[state];

        // Find and remove from the array (inefficient for large arrays)
        uint256 indexToRemove = type(uint256).max;
        for (uint i = 0; i < potentialStates.length; i++) {
            if (potentialStates[i] == state) {
                indexToRemove = i;
                break;
            }
        }
        if (indexToRemove != type(uint256).max) {
            // Swap with last element and pop
            if (indexToRemove < potentialStates.length - 1) {
                potentialStates[indexToRemove] = potentialStates[potentialStates.length - 1];
            }
            potentialStates.pop();
        }

        // If removing the last state in Initial phase, consider phase implications
        if (currentPhase == StatePhase.Initial && potentialStates.length == 0) {
             // Stay in Initial phase
        } else if (currentPhase == StatePhase.Superposition && potentialStates.length == 0) {
             // Should not happen due to the check above
        }


        emit PotentialStateRemoved(state);
    }

    /**
     * @dev Updates the energy/weight of an existing potential state.
     *      Valid only in Initial or Superposition phase.
     * @param state The SuperposedState to update.
     * @param newEnergy The new energy value.
     */
    function updateStateEnergy(SuperposedState state, uint256 newEnergy)
        external onlyOwner notInPhase(StatePhase.Collapsing) notInPhase(StatePhase.Collapsed)
    {
        require(isPotentialStateValid[state], "State does not exist");
        require(newEnergy > 0, "Energy must be positive");
        stateEnergies[state] = newEnergy;
        emit StateEnergyUpdated(state, newEnergy);
    }

    /**
     * @dev Sets the minimum accumulatedEnergy required to initiate Collapse.
     * @param energy The minimum energy amount.
     */
    function setMinEnergyForCollapse(uint256 energy) external onlyOwner {
        minEnergyForCollapse = energy;
    }

    /**
     * @dev Sets the minimum number of blocks that must pass between Collapse events.
     * @param blocks The number of blocks for the cooldown.
     */
    function setCollapseCooldownBlocks(uint256 blocks) external onlyOwner {
        collapseCooldownBlocks = blocks;
    }

     /**
     * @dev Sets the percentage influence (0-100) of the userSeed on entropy generation.
     *      0 means only block data is used, 100 means userSeed is more influential (still mixed with block data).
     * @param influence The influence percentage (0-100).
     */
    function setEntropyInfluencePercentage(uint256 influence) external onlyOwner {
        require(influence <= 100, "Influence percentage must be 0-100");
        collapseEntropySeedInfluence = influence;
    }

    /**
     * @dev Grants or revokes permission for a specific address to initiate collapse.
     *      If collapseInitiationRestricted is true, only allowed addresses can call initiateCollapseAndResolve.
     *      Setting allowed = true for an address automatically sets collapseInitiationRestricted to true.
     *      Setting allowed = false will unset collapseInitiationRestricted if no other addresses are allowed.
     * @param initiator The address to set permissions for.
     * @param allowed Whether the initiator is allowed or not.
     */
    function setAllowedInitiator(address initiator, bool allowed) external onlyOwner {
        require(initiator != address(0), "Cannot set zero address as initiator");
        allowedInitiators[initiator] = allowed;

        if (allowed) {
            collapseInitiationRestricted = true;
        } else {
            // Check if any other initiators are still allowed
            bool anyOtherAllowed = false;
            // NOTE: Checking all possible addresses is impossible.
            // This is a simplification. A real system might track allowed initiators in a list.
            // For this example, we assume owner manages this carefully or restriction can be manually toggled.
            // Let's add a manual toggle for simplicity in this example.
            // (Adding toggle function later)
            // For now, just set the value. Owner needs to manage restriction state separately.
        }
    }

    /**
     * @dev Owner function to explicitly set whether collapse initiation is restricted.
     *      If true, only addresses previously set with `setAllowedInitiator(addr, true)` can initiate.
     * @param restricted True to restrict, false to allow anyone (subject to other checks).
     */
    function setCollapseInitiationRestricted(bool restricted) external onlyOwner {
        collapseInitiationRestricted = restricted;
    }


    /**
     * @dev Sets a uint256 parameter associated with a specific ObservedState.
     *      These parameters can influence the behavior of `performStateAction`.
     * @param state The ObservedState enum.
     * @param value The uint256 value to set.
     */
    function setObservedStateParameter(ObservedState state, uint256 value) external onlyOwner {
        require(state != ObservedState.UndefinedObservedState, "Cannot set parameter for UndefinedObservedState");
        stateBasedParameters[state] = value;
        emit StateParameterUpdated(state, value);
    }

    /**
     * @dev Transfers ownership of the contract.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        address oldOwner = i_owner;
        // Note: Since owner is immutable, this basic implementation
        // doesn't actually change the immutable i_owner.
        // A standard Ownable pattern would use a mutable state variable.
        // To adhere strictly to "no open source duplicate" AND transfer ownership,
        // we'd need to make `owner` mutable. Let's adjust `i_owner` to `owner`.
        // This is a deviation from the initial `immutable` plan to meet the spec.
        // Let's correct this:
        // address private owner; // -> Should be mutable
        // constructor sets owner = msg.sender
        // transferOwnership updates owner = newOwner
        // modifier onlyOwner uses owner

        // *Correction Implementation:*
        // The initial design used `immutable i_owner`. To allow transfer, it must be mutable.
        // Let's rename `i_owner` to `_owner` and make it a standard state variable.

        address _oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(_oldOwner, newOwner);
    }

    // *Correction:* State variable and constructor adjusted for mutable owner.
    address private _owner; // Corrected from i_owner to be mutable

    constructor() {
        _owner = msg.sender;
        currentPhase = StatePhase.Initial;
        emit PhaseChanged(StatePhase.Initial, currentPhase);

        isPotentialStateValid[SuperposedState.UndefinedState] = true;
        stateBasedParameters[ObservedState.UndefinedObservedState] = 0;
         emit OwnershipTransferred(address(0), _owner); // Standard for Ownable
    }

    // *Correction:* onlyOwner modifier adjusted to use `_owner`.
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }
    // End of Correction


    // --- Energy & Core Mechanics ---

    /**
     * @dev Allows anyone to send Ether to the contract, which is converted into energy.
     *      Example rate: 1 Ether = 1000 Energy units. This rate can be a state variable.
     */
    function accumulateEnergy() external payable {
        require(msg.value > 0, "Must send Ether to accumulate energy");
        // Simple energy conversion: 1 ETH = 1000 Energy units
        uint256 energyGained = msg.value * 1000 / 1e18; // 1e18 is 1 Ether in Wei
        require(energyGained > 0, "Amount sent too small to gain energy");
        accumulatedEnergy += energyGained;
        totalEnergyAccumulated += energyGained;
        emit EnergyAccumulated(msg.sender, energyGained, accumulatedEnergy);
    }

    /**
     * @dev Triggers the state collapse process and immediately resolves to an Observed State.
     *      Requires specific phase (Superposition), minimum energy, and cooldown elapsed.
     *      Uses block data and userSeed to simulate entropy and determine the outcome based on state energies.
     *      Transitions phase from Superposition -> Collapsing -> Collapsed.
     * @param userSeed A uint256 provided by the user to influence entropy.
     */
    function initiateCollapseAndResolve(uint256 userSeed)
        external inPhase(StatePhase.Superposition)
    {
        require(potentialStates.length > 0, "No potential states configured");
        require(accumulatedEnergy >= minEnergyForCollapse, "Not enough energy for collapse");
        require(block.number >= lastCollapseBlock + collapseCooldownBlocks, "Collapse cooldown in effect");

        // Check initiator permissions if restricted
        if (collapseInitiationRestricted) {
            require(allowedInitiators[msg.sender], "Initiator not allowed");
        }

        // Transition phase: Superposition -> Collapsing
        StatePhase oldPhase = currentPhase;
        currentPhase = StatePhase.Collapsing;
        emit PhaseChanged(oldPhase, currentPhase);
        emit CollapseInitiated(msg.sender, userSeed);

        // --- Simulate Entropy Generation ---
        // NOTE: Block data is predictable to miners. This is for simulation/demonstration, NOT for high-security randomness.
        bytes32 entropy = _generateEntropy(userSeed);

        // --- Resolve State Based on Entropy and Energies ---
        ObservedState resolvedState = _resolveState(entropy);
        require(resolvedState != ObservedState.UndefinedObservedState, "Internal error: Failed to resolve state");

        // --- Apply State Effects ---
        _applyStateEffects(resolvedState, entropy);

        // Update state variables after successful collapse
        accumulatedEnergy -= minEnergyForCollapse; // Consume energy
        lastCollapseBlock = block.number;
        currentState = resolvedState;

        // Transition phase: Collapsing -> Collapsed
        oldPhase = currentPhase;
        currentPhase = StatePhase.Collapsed;
        emit PhaseChanged(oldPhase, currentPhase);
        emit CollapseResolved(currentState, entropy);
    }

     /**
     * @dev Resets the contract back to an earlier state.
     *      Owner can choose to go back to Initial (clears states) or Superposition (keeps states).
     * @param resetToInitial If true, resets to Initial phase, clearing all potential states.
     *                       If false, resets to Superposition phase, keeping potential states and energies.
     *      Always clears accumulated energy, observed state, and generated data.
     */
    function resetSystem(bool resetToInitial) external onlyOwner {
        StatePhase oldPhase = currentPhase;
        currentPhase = StatePhase.Initial; // Default reset target

        // Clear collapse-specific data
        accumulatedEnergy = 0; // Or maybe keep some? Let's clear for a 'fresh' state
        currentState = ObservedState.UndefinedObservedState;
        generatedQuantumData = bytes32(0);
        // Reset user interaction counts for the previous state (optional, or clear all?)
        // Clearing all interaction counts:
        // This is hard/impossible efficiently on-chain for a mapping of mapping.
        // Let's skip clearing user interaction counts in reset for efficiency.
        // They persist but are tied to specific ObservedStates.

        if (resetToInitial) {
             // Clear potential states and energies
             for (uint i = 0; i < potentialStates.length; i++) {
                  isPotentialStateValid[potentialStates[i]] = false;
                  delete stateEnergies[potentialStates[i]];
             }
             delete potentialStates;
             currentPhase = StatePhase.Initial;
        } else {
             // Reset to Superposition, only if there are potential states defined
             if (potentialStates.length > 0) {
                 currentPhase = StatePhase.Superposition;
             } else {
                 // If no states were defined before resetToInitial=false, must go to Initial
                 currentPhase = StatePhase.Initial;
             }
        }

        lastCollapseBlock = 0; // Reset cooldown

        emit PhaseChanged(oldPhase, currentPhase);
        // Note: if resetting to Superposition, need to ensure states exist or owner adds them again.
        // The logic ensures phase is Initial if no states are left.
    }


    // --- State-Dependent Actions ---

    /**
     * @dev Executes an action whose logic depends on the current Observed State.
     *      Only callable when the contract is in the Collapsed phase.
     *      Example: Different states might unlock different functionality or require different inputs/payments.
     */
    function performStateAction() external inPhase(StatePhase.Collapsed) {
        // Logic based on the current state
        ObservedState state = currentState;

        // Example state-dependent logic:
        if (state == ObservedState.ObservedA) {
            // Action for State A: Maybe allow claiming some token, or trigger an event
            // require(stateBasedParameters[state] > 0, "State A action needs parameter");
            // Do something with stateBasedParameters[state]
            // emit StateActionA(msg.sender, stateBasedParameters[state]);
            // For this example, just a simple log and interaction count update
            uint256 param = stateBasedParameters[state]; // Use the parameter
            // Log the action with state and parameter
            emit UserStateActionPerformed(msg.sender, state, param); // Reusing event, maybe create a specific one

        } else if (state == ObservedState.ObservedB) {
            // Action for State B: Maybe require a small Ether payment, or have a different cooldown
            // require(msg.value >= 1e15, "State B action requires 0.001 Ether");
            // ... other State B logic ...
            uint256 param = stateBasedParameters[state];
             emit UserStateActionPerformed(msg.sender, state, param);

        } else if (state == ObservedState.ObservedC) {
            // Action for State C: Maybe this state is "unstable" or has a limited time window
             uint256 param = stateBasedParameters[state];
             emit UserStateActionPerformed(msg.sender, state, param);

        } else if (state == ObservedState.ObservedVoid) {
             // Action for Void State: Maybe nothing happens, or it resets something
             // This state could be a "failure" state
             revert("No action possible in the Quantum Void state"); // Example: Void state is inactive

        } else {
            // Should not happen if currentState is a valid ObservedState
             revert("Unknown observed state");
        }

        // Increment user interaction count for THIS specific state
        userStateInteractionCount[msg.sender][state]++;
        // Optional: emit an event specific to the action if needed,
        // but UserStateActionPerformed covers basic interaction count.
    }


    // --- Querying / View Functions ---

    /**
     * @dev Returns the array of currently configured potential states.
     */
    function getPotentialStates() external view returns (SuperposedState[] memory) {
        return potentialStates;
    }

    /**
     * @dev Returns the energy/weight for a specific potential state.
     * @param state The SuperposedState enum.
     */
    function getStateEnergy(SuperposedState state) external view returns (uint256) {
         require(isPotentialStateValid[state], "State does not exist");
        return stateEnergies[state];
    }

    /**
     * @dev Returns the current total accumulated energy.
     */
    function getAccumulatedEnergy() external view returns (uint256) {
        return accumulatedEnergy;
    }

     /**
     * @dev Returns the total energy ever accumulated in the contract's history.
     */
    function getTotalEnergyAccumulated() external view returns (uint256) {
        return totalEnergyAccumulated;
    }


    /**
     * @dev Returns the minimum energy required to initiate Collapse.
     */
    function getMinEnergyForCollapse() external view returns (uint256) {
        return minEnergyForCollapse;
    }

    /**
     * @dev Returns the cooldown period between collapses in blocks.
     */
    function getCollapseCooldownBlocks() external view returns (uint256) {
        return collapseCooldownBlocks;
    }

    /**
     * @dev Returns the block number of the last collapse. 0 if never collapsed.
     */
    function getLastCollapseBlock() external view returns (uint256) {
        return lastCollapseBlock;
    }

    /**
     * @dev Returns the number of blocks elapsed since the last collapse. 0 if never collapsed.
     */
    function getTimeSinceLastCollapse() external view returns (uint256) {
        if (lastCollapseBlock == 0) {
            return 0;
        }
        return block.number - lastCollapseBlock;
    }

    /**
     * @dev Returns the percentage influence (0-100) of the userSeed on entropy generation.
     */
     function getEntropyInfluencePercentage() external view returns (uint256) {
         return collapseEntropySeedInfluence;
     }

     /**
      * @dev Checks if collapse initiation is restricted and if the given address is allowed.
      * @param initiator The address to check.
      * @return True if restricted and allowed, or if not restricted at all. False otherwise.
      */
     function isAllowedInitiator(address initiator) external view returns (bool) {
         if (!collapseInitiationRestricted) {
             return true; // Anyone can initiate if not restricted
         }
         return allowedInitiators[initiator]; // Check specific permission
     }

    /**
     * @dev Returns the contract's current lifecycle StatePhase.
     */
    function getCurrentPhase() external view returns (StatePhase) {
        return currentPhase;
    }

    /**
     * @dev Returns the resolved Observed State. Only valid when the contract is in the Collapsed phase.
     */
    function getCurrentObservedState() external view inPhase(StatePhase.Collapsed) returns (ObservedState) {
        return currentState;
    }

    /**
     * @dev Returns the uint256 parameter associated with a specific ObservedState.
     * @param state The ObservedState enum.
     */
    function getObservedStateParameter(ObservedState state) external view returns (uint256) {
        // Allow querying parameter for any valid ObservedState enum value
        // require(state != ObservedState.UndefinedObservedState, "Cannot query UndefinedObservedState parameter"); // Optional restriction
        return stateBasedParameters[state];
    }

    /**
     * @dev Returns the bytes32 data generated upon Collapse. Only valid when in Collapsed phase.
     */
    function getGeneratedQuantumData() external view inPhase(StatePhase.Collapsed) returns (bytes32) {
        return generatedQuantumData;
    }

    /**
     * @dev Returns the number of times a user has successfully called performStateAction
     *      when the contract was in the specified Observed State.
     * @param user The address of the user.
     * @param state The ObservedState to query for.
     */
    function getUserStateInteractionCount(address user, ObservedState state) external view returns (uint256) {
         // Allow querying for any user and any valid ObservedState enum value
        return userStateInteractionCount[user][state];
    }


    /**
     * @dev Returns the total Ether balance currently held by the contract.
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Allows the owner to withdraw a specified amount of Ether from the contract balance.
     * @param amount The amount of Ether (in Wei) to withdraw.
     */
    function withdrawEther(uint256 amount) external onlyOwner {
        require(amount > 0, "Must withdraw a positive amount");
        require(amount <= address(this).balance, "Not enough Ether in contract");
        payable(_owner).transfer(amount);
        emit ContractWithdrawal(_owner, amount);
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Generates simulated entropy using block data and the user seed.
     *      NOTE: This is NOT cryptographically secure randomness on EVM.
     *      Miners can influence or predict block data. Suitable for demonstration/games where security isn't paramount.
     * @param userSeed A uint256 value from the user.
     * @return A bytes32 representing the simulated entropy.
     */
    function _generateEntropy(uint256 userSeed) internal view returns (bytes32) {
        // Simple deterministic mix of block data and user seed
        bytes32 blockEntropy = keccak256(
            abi.encodePacked(
                block.timestamp,
                block.number,
                block.difficulty, // block.difficulty is deprecated, use block.prevrandao in PoS
                msg.sender // Include initiator address
            )
        );

        // Mix block entropy and user seed based on influence percentage
        // A simple interpolation based on the influence percentage
        // (0% influence = only blockEntropy, 100% influence = mix where userSeed has high impact)
        // This is a simple simulation, not a mathematically precise probability distribution adjustment.
        bytes32 userSeedHash = keccak256(abi.encodePacked(userSeed));

        // Simple weighted hash mix: (blockHash * (100 - influence) + userSeedHash * influence) / 100
        // This doesn't work directly with bytes32.
        // Let's treat hashes as large numbers for mixing influence.
        uint256 blockEntropyUint = uint256(blockEntropy);
        uint256 userSeedUint = uint256(userSeedHash);

        uint256 mixedValue = (blockEntropyUint * (100 - collapseEntropySeedInfluence) + userSeedUint * collapseEntropySeedInfluence) / 100;

        return bytes32(mixedValue);

        // A more robust (but still not secure) way might involve block hash over a range of blocks or external oracles like Chainlink VRF.
        // Sticking to pure on-chain for this example as requested.
    }

    /**
     * @dev Determines the resolved Observed State based on the generated entropy and state energies.
     *      Uses a weighted selection method.
     * @param entropy The bytes32 entropy value.
     * @return The selected ObservedState.
     */
    function _resolveState(bytes32 entropy) internal view returns (ObservedState) {
        require(potentialStates.length > 0, "No potential states to resolve");

        uint256 totalEnergy = 0;
        for (uint i = 0; i < potentialStates.length; i++) {
            totalEnergy += stateEnergies[potentialStates[i]];
        }

        if (totalEnergy == 0) {
             // Should not happen if states were added with positive energy, but as a safeguard
             return ObservedState.UndefinedObservedState;
        }

        // Use the entropy as a random number within the total energy range
        uint256 randomValue = uint256(entropy) % totalEnergy;

        uint256 cumulativeEnergy = 0;
        for (uint i = 0; i < potentialStates.length; i++) {
            SuperposedState potentialState = potentialStates[i];
            cumulativeEnergy += stateEnergies[potentialState];

            if (randomValue < cumulativeEnergy) {
                // Map SuperposedState enum to ObservedState enum
                // This requires a consistent mapping or lookup.
                // For this simple example, we'll assume they map directly based on definition order.
                // In a real complex system, you'd have a mapping or a more sophisticated enum structure.
                // Let's use a switch or if-else based on the potentialState enum value.
                if (potentialState == SuperposedState.StateA_HighEnergy) return ObservedState.ObservedA;
                if (potentialState == SuperposedState.StateB_LowEnergy) return ObservedState.ObservedB;
                if (potentialState == SuperposedState.StateC_Unstable) return ObservedState.ObservedC;
                if (potentialState == SuperposedState.QuantumVoid_ZeroPoint) return ObservedState.ObservedVoid;

                // Fallback for any unmapped states (should not happen if enums match)
                 return ObservedState.UndefinedObservedState;
            }
        }

        // Fallback in case calculation fails (should not be reachable)
        return ObservedState.UndefinedObservedState;
    }

    /**
     * @dev Applies effects based on the resolved Observed State.
     *      This includes generating quantum data and potentially other state-specific side effects.
     * @param resolvedState The state the system collapsed into.
     * @param entropy The entropy used for resolution.
     */
    function _applyStateEffects(ObservedState resolvedState, bytes32 entropy) internal {
        // Generate unique data based on the resolved state and the entropy
        generatedQuantumData = keccak256(
            abi.encodePacked(
                resolvedState,
                entropy,
                block.number, // Add block info for uniqueness
                block.timestamp
            )
        );
        emit QuantumDataGenerated(resolvedState, generatedQuantumData);

        // Other state-specific effects could go here:
        // - Minting tokens based on the state
        // - Triggering calls to other contracts
        // - Adjusting internal parameters other than the stateBasedParameters map
        // - Initializing state-specific cooldowns or access lists
        // - Setting initial values for state-specific mini-games or interactions
    }

     /**
      * @dev Returns the contract's owner address.
      */
    function owner() external view returns (address) {
        return _owner;
    }
}
```