Okay, let's design a smart contract that incorporates several advanced and creative concepts beyond standard tokenomics or simple dApps. We'll create a system themed around "Quantum Fluctuations," featuring dynamic token properties, evolving NFTs, internal state-based randomness, and a prediction market on contract parameters.

This contract will not be based on standard interfaces like ERC20 or ERC721 directly, although it will have similar concepts for fungible and non-fungible units. The core logic will be custom.

Here is the proposed structure and function summary:

---

## QuantumFluctuations Smart Contract

This contract simulates a system where digital "Fluctuation Units" (FUs, a fungible token) and "Quantum States" (Q-States, non-fungible tokens) exist and interact within a dynamic environment influenced by an internal "Fluctuation Intensity" parameter. Users can trigger "Observations" which probabilistically alter the system's state, mutate their Q-States, entangle states, and even predict future intensity levels.

**Core Concepts:**

1.  **Fluctuation Units (FUs):** A fungible token representing energy or potential within the system. Its behavior and value are tied to the system's intensity.
2.  **Quantum States (Q-States):** Non-fungible tokens (NFTs) with mutable properties that can decay, mutate based on system intensity, and be 'synthesized' back into FUs.
3.  **Fluctuation Intensity:** A key contract parameter that changes probabilistically over time (or block intervals) when triggered by user "Observations". It influences mutation outcomes, decay rates, and synthesis yields.
4.  **Observation:** A user action that triggers a potential change in the global Fluctuation Intensity and might yield a small bonus for the observer.
5.  **Mutation & Decay:** Q-States can have their properties actively mutated (influenced by intensity) or passively decay over time towards equilibrium.
6.  **Entanglement:** Q-States can be linked, and interactions with one might influence its entangled partner.
7.  **Internal Prediction Market:** Users can bond FUs to predict the future value of the Fluctuation Intensity. Correct predictions are rewarded.

---

**Outline:**

1.  **SPDX-License-Identifier & Pragma**
2.  **Imports:** Ownable, Pausable (for basic security/control, standard pattern but applied to custom logic).
3.  **Error Definitions**
4.  **Events:** To signal key state changes.
5.  **Structs:**
    *   `QuantumStateProperties`: Defines the mutable traits of a Q-State.
    *   `IntensityPrediction`: Holds details about an active prediction.
6.  **State Variables:** Store contract data like balances, state properties, intensity, prediction data, configuration.
7.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `whenPaused`.
8.  **Constructor:** Initializes contract owner and basic parameters.
9.  **Core Quantum/Dynamic Logic Functions:** Drive the system's state changes.
10. **Fluctuation Unit (FU) Management Functions:** Handle the fungible tokens.
11. **Quantum State (Q-State) Management Functions:** Handle the non-fungible tokens (NFTs).
12. **Entanglement Functions:** Manage links between Q-States.
13. **Internal Prediction Market Functions:** Handle predictions on intensity.
14. **Configuration Functions:** Allow owner to adjust parameters.
15. **Utility & View Functions:** Retrieve information about the contract state.
16. **Emergency/Owner Functions:** Pause, transfer ownership.

---

**Function Summary:**

1.  `constructor()`: Initializes the contract, setting the owner and some initial parameters.
2.  `emergencyPause()`: Owner-only. Pauses core interactions.
3.  `emergencyUnpause()`: Owner-only. Unpauses core interactions.
4.  `transferOwnership(address newOwner)`: Owner-only. Transfers contract ownership.
5.  `mintInitialFluctuationUnits(address recipient, uint256 amount)`: Owner-only. Mints initial FUs into the system (e.g., for distribution).
6.  `transferFluctuationUnits(address recipient, uint256 amount)`: Transfers FUs from caller to recipient.
7.  `burnFluctuationUnits(uint256 amount)`: Burns caller's FUs.
8.  `balanceOfFluctuationUnits(address account)`: View function. Returns FU balance of an account.
9.  `mintQuantumState()`: Creates a new Q-State (NFT) and assigns it to the caller. Gives it initial, somewhat random properties. Requires FU payment.
10. `transferQuantumState(address from, address to, uint256 stateId)`: Transfers ownership of a Q-State. Requires approval or being the owner/approved sender.
11. `getQuantumStateOwner(uint256 stateId)`: View function. Returns owner of a Q-State.
12. `getQuantumStateProperties(uint256 stateId)`: View function. Returns the mutable properties of a Q-State.
13. `observeFluctuations()`: Triggers a system observation. Probabilistically updates `fluctuationIntensity`. May distribute a small FU bonus to the caller. Requires FU payment.
14. `mutateQuantumState(uint256 stateId)`: Attempts to mutate a Q-State's properties. Outcome influenced by current `fluctuationIntensity` and internal randomness. Requires owning the state and FU payment.
15. `decayQuantumState(uint256 stateId)`: Applies decay to a Q-State's properties based on time since last interaction/decay and `equilibriumDecayRate`. Can be called by anyone, but only affects the state properties.
16. `synthesizeStateEnergy(uint256 stateId)`: Burns a Q-State (NFT) and mints FUs to the caller. The amount of FUs depends on the state's current properties and the `fluctuationIntensity`. Requires owning the state.
17. `setQuantumStateEntanglement(uint256 stateId, uint256 entangledWithStateId)`: Entangles `stateId` with `entangledWithStateId`. Requires owning `stateId` and potentially `entangledWithStateId`, plus FU payment. Creates a one-way link.
18. `breakQuantumStateEntanglement(uint256 stateId)`: Breaks the entanglement link from `stateId`. Requires owning `stateId`.
19. `triggerEntangledReaction(uint256 stateId)`: If `stateId` is entangled, this function attempts to trigger a mutation or decay on its entangled partner. Requires owning `stateId` and FU payment.
20. `proposeIntensityPrediction(uint256 intensityValue, uint256 resolutionBlock)`: Proposes a prediction for `fluctuationIntensity` at a specific future block. Requires bonding FUs. Only one active prediction allowed at a time.
21. `resolveIntensityPrediction()`: Resolves the active prediction if the `resolutionBlock` is reached. Rewards predictor if correct (within tolerance) or burns/retains bond if incorrect.
22. `getCurrentPredictionDetails()`: View function. Returns details of the currently active prediction.
23. `updateEquilibriumDecayRate(uint256 newRate)`: Owner-only. Sets the rate at which Q-States decay.
24. `updateFluctuationParameters(uint256 intensityChangeFactor, uint256 observationBonusAmount, uint256 observationCost, uint256 mutationCost, uint256 synthesisBaseYield, uint256 entanglementCost, uint256 reactionCost, uint256 mintStateCost, uint256 predictionTolerance)`: Owner-only. Updates various parameters influencing the core logic and costs/rewards.
25. `setPredictionBondAmount(uint256 amount)`: Owner-only. Sets the amount of FUs required to propose a prediction.
26. `getFluctuationIntensity()`: View function. Returns the current global Fluctuation Intensity.
27. `getTimeSinceLastObservation()`: View function. Returns blocks since the last observation.
28. `simulateFutureMutation(uint256 stateId, uint256 blocksInFuture)`: View function. Estimates the possible range of a Q-State's properties after mutation *if* it were to happen in the future, considering potential intensity changes. (This function is complex to make truly predictive/simulative on-chain and would likely provide a probabilistic range or expected value based on current state). Let's simplify: it estimates expected state after decay *and* potential mutation effects based on current intensity, not simulating future intensity changes.
29. `calculateDecayAmount(uint256 stateId)`: View function. Calculates the amount of decay that would be applied to a Q-State *right now* if `decayQuantumState` were called.
30. `predictStateDecay(uint256 stateId, uint256 blocksInFuture)`: View function. Estimates the properties of a Q-State after applying decay logic for a certain number of blocks in the future.

*(Self-correction: We need at least 20. The current list is 30+ functions including views and owner functions. This is sufficient and covers the outlined concepts)*

---

Now, let's write the Solidity code for this contract.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; // Not strictly needed as we're not interacting with external ERC20s, but good pattern knowledge. Let's just use mappings for simplicity as it's an internal token.

// Custom error definitions
error QuantumFluctuations__InsufficientFunds();
error QuantumFluctuations__InvalidAmount();
error QuantumFluctuations__StateNotFound(uint256 stateId);
error QuantumFluctuations__NotStateOwner();
error QuantumFluctuations__TransferFailed();
error QuantumFluctuations__AlreadyPredicting();
error QuantumFluctuations__PredictionNotResolvedYet();
error QuantumFluctuations__NoActivePrediction();
error QuantumFluctuations__InvalidStateOperation(string reason); // More generic for state issues
error QuantumFluctuations__EntanglementFailed(string reason);
error QuantumFluctuations__ReactionFailed(string reason);
error QuantumFluctuations__ZeroAddress();


contract QuantumFluctuations is Ownable, Pausable {

    // --- State Variables ---

    // Fungible Fluctuating Units (FUs)
    mapping(address => uint256) private s_fluctuationUnits;
    uint256 private s_totalFluctuationUnits;

    // Non-Fungible Quantum States (Q-States)
    struct QuantumStateProperties {
        uint256 id;
        address owner;
        uint256 creationBlock;
        uint256 lastInteractionBlock; // Block of last mutation, decay, or entanglement change
        uint256 stability; // How resistant to decay (0-1000)
        uint256 resonance; // How much it interacts with intensity (0-1000)
        uint256 vitality;  // General health/value attribute (0-1000)
        uint256 entangledWithStateId; // 0 if not entangled, otherwise ID of entangled state
    }
    mapping(uint256 => QuantumStateProperties) private s_quantumStates;
    uint256 private s_nextQuantumStateId = 1; // Start state IDs from 1

    // System Parameters
    uint256 private s_fluctuationIntensity; // Main dynamic parameter (0-10000)
    uint256 private s_lastObservationBlock; // Block number when observeFluctuations was last called

    // Configuration Parameters (Owner-adjustable)
    struct ConfigParameters {
        uint256 equilibriumDecayRate; // Rate of decay per block difference (e.g., 1 per 100 blocks)
        uint256 intensityChangeFactor; // How much intensity changes per observation
        uint256 observationBonusAmount; // FU bonus for observer
        uint256 observationCost; // FU cost to observe
        uint256 mutationCost; // FU cost to mutate a state
        uint256 synthesisBaseYield; // Base FUs received from synthesizing a state
        uint256 entanglementCost; // FU cost to entangle states
        uint256 reactionCost; // FU cost to trigger entangled reaction
        uint256 mintStateCost; // FU cost to mint a new state
        uint256 predictionBondAmount; // FU cost to make a prediction
        uint256 predictionTolerance; // % tolerance for prediction accuracy (e.g., 50 = +/- 5%)
        uint256 maxPropertyRange; // Max value for state properties (e.g., 1000)
    }
    ConfigParameters private s_config;

    // Internal Prediction Market
    struct IntensityPrediction {
        address predictor;
        uint256 intensityValue;
        uint256 resolutionBlock;
        uint256 bondAmount;
        bool active;
    }
    IntensityPrediction private s_activePrediction;

    // --- Events ---

    event FluctuationsObserved(uint256 newIntensity, uint256 observationBonusGiven);
    event StateMinted(uint256 stateId, address owner, uint256 creationBlock);
    event StateTransfer(address indexed from, address indexed to, uint256 indexed stateId);
    event StateMutated(uint256 indexed stateId, uint256 newStability, uint256 newResonance, uint256 newVitality, uint256 intensityAtMutation);
    event StateDecayed(uint256 indexed stateId, uint256 newStability, uint256 newResonance, uint256 newVitality, uint256 decayAmountApplied);
    event StateSynthesized(uint256 indexed stateId, address owner, uint256 unitsMinted);
    event StateEntangled(uint256 indexed stateId1, uint256 indexed stateId2);
    event StateDisentangled(uint256 indexed stateId);
    event EntangledReactionTriggered(uint256 indexed stateId, uint256 indexed targetStateId);
    event IntensityPredictionProposed(address indexed predictor, uint256 intensityValue, uint256 resolutionBlock, uint256 bondAmount);
    event IntensityPredictionResolved(address indexed predictor, bool accurate, uint256 bondReturned, uint256 rewardGiven);
    event FluctuationUnitsMinted(address indexed recipient, uint256 amount);
    event FluctuationUnitsBurned(address indexed account, uint256 amount);
    event ConfigUpdated();

    // --- Constructor ---

    constructor(
        uint256 initialFluctuationIntensity,
        uint256 initialEquilibriumDecayRate,
        uint256 initialIntensityChangeFactor,
        uint256 initialObservationBonusAmount,
        uint256 initialObservationCost,
        uint256 initialMutationCost,
        uint256 initialSynthesisBaseYield,
        uint256 initialEntanglementCost,
        uint256 initialReactionCost,
        uint256 initialMintStateCost,
        uint256 initialPredictionBondAmount,
        uint256 initialPredictionTolerance,
        uint256 initialMaxPropertyRange
    ) Ownable(msg.sender) Pausable(false) {
        // Basic validation (can add more robust checks)
        if (initialMaxPropertyRange == 0) revert QuantumFluctuations__InvalidAmount();

        s_fluctuationIntensity = initialFluctuationIntensity;
        s_lastObservationBlock = block.number;

        s_config = ConfigParameters({
            equilibriumDecayRate: initialEquilibriumDecayRate,
            intensityChangeFactor: initialIntensityChangeFactor,
            observationBonusAmount: initialObservationBonusAmount,
            observationCost: initialObservationCost,
            mutationCost: initialMutationCost,
            synthesisBaseYield: initialSynthesisBaseYield,
            entanglementCost: initialEntanglementCost,
            reactionCost: initialReactionCost,
            mintStateCost: initialMintStateCost,
            predictionBondAmount: initialPredictionBondAmount,
            predictionTolerance: initialPredictionTolerance, // e.g., 50 for 5%
            maxPropertyRange: initialMaxPropertyRange // e.g., 1000
        });

        // Initialize prediction state
        s_activePrediction.active = false;
    }

    // --- Modifiers ---
    // Inherited from Ownable and Pausable

    // --- Core Quantum/Dynamic Logic Functions ---

    /**
     * @notice Triggers a system observation, potentially changing global intensity.
     * @dev Pays observation cost, updates intensity based on block number and other factors.
     *      May award a small FU bonus.
     */
    function observeFluctuations() external whenNotPaused {
        if (s_fluctuationUnits[msg.sender] < s_config.observationCost) revert QuantumFluctuations__InsufficientFunds();

        _burnFluctuationUnits(msg.sender, s_config.observationCost);

        // --- Simulate Fluctuation Intensity Change (Pseudo-Randomness) ---
        // WARNING: This pseudo-randomness is based on block data and contract state.
        // It is NOT cryptographically secure and can be influenced by miners.
        // For high-value applications, integrate Chainlink VRF or similar external randomness.

        uint256 timeSinceLast = block.number - s_lastObservationBlock;
        uint256 entropy = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao, // Use prevrandao instead of difficulty for newer Solidity
            s_fluctuationIntensity,
            timeSinceLast,
            msg.sender,
            s_totalFluctuationUnits // Include contract state
        )));

        // Intensity change is influenced by entropy and config parameters
        // Example logic: Intensity tends towards a mid-range but fluctuates based on entropy
        uint256 intensityChange = (entropy % s_config.intensityChangeFactor);

        if (entropy % 2 == 0) {
            // Increase intensity, capped at max
            s_fluctuationIntensity = s_fluctuationIntensity + intensityChange;
            if (s_fluctuationIntensity > 10000) s_fluctuationIntensity = 10000; // Example cap
        } else {
            // Decrease intensity, floored at min
            if (intensityChange > s_fluctuationIntensity) {
                 s_fluctuationIntensity = 0;
            } else {
                 s_fluctuationIntensity = s_fluctuationIntensity - intensityChange;
            }
             if (s_fluctuationIntensity < 0) s_fluctuationIntensity = 0; // Should be >= 0 due to uint
        }

        s_lastObservationBlock = block.number;

        // Award potential bonus
        uint256 bonusGiven = 0;
        if (s_config.observationBonusAmount > 0) {
             // Simple probabilistic bonus chance based on entropy
             if (entropy % 100 < s_fluctuationIntensity / 100) { // Higher intensity, higher chance (example logic)
                 _mintFluctuationUnits(msg.sender, s_config.observationBonusAmount);
                 bonusGiven = s_config.observationBonusAmount;
             }
        }

        emit FluctuationsObserved(s_fluctuationIntensity, bonusGiven);
    }

     /**
     * @notice Attempts to mutate the properties of a Quantum State.
     * @dev Outcome depends on current intensity and internal randomness. Applies decay first.
     * @param stateId The ID of the state to mutate.
     */
    function mutateQuantumState(uint256 stateId) external whenNotPaused {
        QuantumStateProperties storage state = _getQuantumState(stateId);
        if (state.owner != msg.sender) revert QuantumFluctuations__NotStateOwner();
        if (s_fluctuationUnits[msg.sender] < s_config.mutationCost) revert QuantumFluctuations__InsufficientFunds();

        _burnFluctuationUnits(msg.sender, s_config.mutationCost);

        // Apply decay before mutation
        _applyDecay(stateId);

        // --- Simulate Mutation (Pseudo-Randomness) ---
        // Influenced by current state properties, intensity, and block data
         uint256 entropy = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            s_fluctuationIntensity,
            state.stability,
            state.resonance,
            state.vitality,
            stateId,
            msg.sender
        )));

        uint256 intensityFactor = s_fluctuationIntensity / 100; // Scale intensity for calculation
        uint256 maxProp = s_config.maxPropertyRange;

        // Example Mutation Logic: Properties change based on entropy and intensity.
        // Higher resonance might mean more drastic changes influenced by intensity.
        // Higher stability might resist change.
        // Vitality might shift based on the outcome.

        int256 stabilityChange = int256((entropy % (intensityFactor + state.resonance / 10)) - (intensityFactor / 2 + state.stability / 10));
        int256 resonanceChange = int256((entropy % (intensityFactor + state.stability / 10)) - (intensityFactor / 2 + state.resonance / 10));
        int256 vitalityChange = int256((entropy % (intensityFactor / 2 + (state.stability + state.resonance) / 20)) - intensityFactor / 4);

        // Apply changes, clamping within [0, maxProp]
        state.stability = uint256(int256(state.stability) + stabilityChange).clamp(0, maxProp);
        state.resonance = uint256(int256(state.resonance) + resonanceChange).clamp(0, maxProp);
        state.vitality = uint256(int256(state.vitality) + vitalityChange).clamp(0, maxProp);

        state.lastInteractionBlock = block.number; // Update interaction block after mutation

        emit StateMutated(stateId, state.stability, state.resonance, state.vitality, s_fluctuationIntensity);
    }

     /**
     * @notice Applies time-based decay to a Quantum State's properties towards an equilibrium.
     * @dev Can be called by anyone to update a state's properties based on elapsed blocks.
     * @param stateId The ID of the state to decay.
     */
    function decayQuantumState(uint256 stateId) external whenNotPaused {
         QuantumStateProperties storage state = _getQuantumState(stateId);

         // Applying decay is public function, doesn't require ownership, just updates state
        _applyDecay(stateId);

        // Event emitted within _applyDecay
    }

    /**
     * @notice Burns a Quantum State and synthesizes Fluctuating Units based on its properties.
     * @dev The amount of FUs minted depends on the state's vitality, resonance, and current intensity.
     * @param stateId The ID of the state to synthesize.
     */
    function synthesizeStateEnergy(uint256 stateId) external whenNotPaused {
        QuantumStateProperties storage state = _getQuantumState(stateId);
        if (state.owner != msg.sender) revert QuantumFluctuations__NotStateOwner();

        // Apply decay before calculating synthesis yield
        _applyDecay(stateId);

        // Example Synthesis Yield Logic:
        // Base yield + bonus based on vitality, resonance, and intensity.
        uint256 yield = s_config.synthesisBaseYield +
                       (state.vitality * s_fluctuationIntensity / 10000) +
                       (state.resonance * s_fluctuationIntensity / 10000);

        address owner = state.owner; // Capture owner before deleting

        // Remove the state
        delete s_quantumStates[stateId];

        // Mint FUs to the owner
        if (yield > 0) {
            _mintFluctuationUnits(owner, yield);
        }

        emit StateSynthesized(stateId, owner, yield);
    }


    // --- Fluctuation Unit (FU) Management Functions ---

    // Note: mintInitialFluctuationUnits is above with Owner functions

    /**
     * @notice Transfers Fluctuating Units from the caller to a recipient.
     * @param recipient The address to transfer FUs to.
     * @param amount The amount of FUs to transfer.
     */
    function transferFluctuationUnits(address recipient, uint256 amount) public whenNotPaused {
        if (recipient == address(0)) revert QuantumFluctuations__ZeroAddress();
        if (amount == 0) revert QuantumFluctuations__InvalidAmount();
        if (s_fluctuationUnits[msg.sender] < amount) revert QuantumFluctuations__InsufficientFunds();

        s_fluctuationUnits[msg.sender] -= amount;
        s_fluctuationUnits[recipient] += amount;

        // No ERC20 Transfer event as this is not a standard ERC20
        // Can add a custom event if needed, but keeping it minimal here
    }

    /**
     * @notice Burns Fluctuating Units from the caller's balance.
     * @param amount The amount of FUs to burn.
     */
    function burnFluctuationUnits(uint256 amount) public whenNotPaused {
         if (amount == 0) revert QuantumFluctuations__InvalidAmount();
         if (s_fluctuationUnits[msg.sender] < amount) revert QuantumFluctuations__InsufficientFunds();

         _burnFluctuationUnits(msg.sender, amount);
         emit FluctuationUnitsBurned(msg.sender, amount);
    }

    /**
     * @notice Gets the balance of Fluctuating Units for an account.
     * @param account The address to query.
     * @return The FU balance of the account.
     */
    function balanceOfFluctuationUnits(address account) public view returns (uint256) {
        return s_fluctuationUnits[account];
    }

    // --- Quantum State (Q-State) Management Functions ---

     /**
     * @notice Creates a new Quantum State (NFT) and assigns it to the caller.
     * @dev Requires FU payment. Initial properties are pseudo-randomly assigned.
     * @return The ID of the newly minted state.
     */
    function mintQuantumState() external whenNotPaused returns (uint256) {
        if (s_fluctuationUnits[msg.sender] < s_config.mintStateCost) revert QuantumFluctuations__InsufficientFunds();

        _burnFluctuationUnits(msg.sender, s_config.mintStateCost);

        uint256 newStateId = s_nextQuantumStateId++;

        // --- Simulate Initial Properties (Pseudo-Randomness) ---
        uint256 entropy = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender,
            newStateId,
            s_totalFluctuationUnits
        )));

        uint256 maxProp = s_config.maxPropertyRange;

        s_quantumStates[newStateId] = QuantumStateProperties({
            id: newStateId,
            owner: msg.sender,
            creationBlock: block.number,
            lastInteractionBlock: block.number, // Set interaction block on creation
            stability: (entropy % maxProp), // Initial stability
            resonance: ((entropy / 10) % maxProp), // Initial resonance
            vitality: ((entropy / 100) % maxProp), // Initial vitality
            entangledWithStateId: 0 // Not entangled initially
        });

        emit StateMinted(newStateId, msg.sender, block.number);
        return newStateId;
    }

    /**
     * @notice Transfers ownership of a Quantum State.
     * @dev Similar to ERC721 transferFrom, requires sender to be owner or approved.
     * @param from The address currently owning the state.
     * @param to The address to transfer the state to.
     * @param stateId The ID of the state to transfer.
     */
    function transferQuantumState(address from, address to, uint256 stateId) public whenNotPaused {
        if (from != msg.sender) revert QuantumFluctuations__TransferFailed("Sender not 'from' address"); // Simplified: owner must initiate or approve is needed
        if (to == address(0)) revert QuantumFluctuations__ZeroAddress();

        QuantumStateProperties storage state = _getQuantumState(stateId);
        if (state.owner != from) revert QuantumFluctuations__NotStateOwner();

        // Apply decay before transfer
        _applyDecay(stateId);

        // Perform transfer
        state.owner = to;

        emit StateTransfer(from, to, stateId);
    }

     /**
     * @notice Gets the owner of a Quantum State.
     * @param stateId The ID of the state to query.
     * @return The owner's address.
     */
    function getQuantumStateOwner(uint256 stateId) public view returns (address) {
        _getQuantumState(stateId); // Check existence
        return s_quantumStates[stateId].owner;
    }

     /**
     * @notice Gets the current properties of a Quantum State.
     * @param stateId The ID of the state to query.
     * @return The properties struct.
     */
    function getQuantumStateProperties(uint256 stateId) public view returns (QuantumStateProperties memory) {
         _getQuantumState(stateId); // Check existence
         // Note: This view function does NOT apply decay automatically.
         // Use calculateDecayAmount or predictStateDecay for future values.
         return s_quantumStates[stateId];
    }

    // --- Entanglement Functions ---

    /**
     * @notice Entangles one Quantum State with another. Creates a one-way link.
     * @dev Requires owning the source state and paying an FU cost.
     * @param stateId The ID of the state to entangle.
     * @param entangledWithStateId The ID of the state to entangle with.
     */
    function setQuantumStateEntanglement(uint256 stateId, uint256 entangledWithStateId) external whenNotPaused {
         QuantumStateProperties storage state1 = _getQuantumState(stateId);
         QuantumStateProperties storage state2 = _getQuantumState(entangledWithStateId); // Ensure target exists

         if (state1.owner != msg.sender) revert QuantumFluctuations__NotStateOwner();
         if (stateId == entangledWithStateId) revert QuantumFluctuations__EntanglementFailed("Cannot entangle state with itself");
         if (state1.entangledWithStateId != 0) revert QuantumFluctuations__EntanglementFailed("State already entangled");

         if (s_fluctuationUnits[msg.sender] < s_config.entanglementCost) revert QuantumFluctuations__InsufficientFunds();
         _burnFluctuationUnits(msg.sender, s_config.entanglementCost);

         state1.entangledWithStateId = entangledWithStateId;
         state1.lastInteractionBlock = block.number; // Update interaction block

         emit StateEntangled(stateId, entangledWithStateId);
    }

    /**
     * @notice Breaks the entanglement link from a Quantum State.
     * @dev Requires owning the state.
     * @param stateId The ID of the state to disentangle.
     */
    function breakQuantumStateEntanglement(uint256 stateId) external whenNotPaused {
        QuantumStateProperties storage state = _getQuantumState(stateId);
        if (state.owner != msg.sender) revert QuantumFluctuations__NotStateOwner();
        if (state.entangledWithStateId == 0) revert QuantumFluctuations__InvalidStateOperation("State not entangled");

        state.entangledWithStateId = 0;
         state.lastInteractionBlock = block.number; // Update interaction block

        emit StateDisentangled(stateId);
    }

    /**
     * @notice Triggers a potential reaction on a state's entangled partner.
     * @dev If the state is entangled, this might cause a mutation or decay on the linked state,
     *      influenced by intensity and randomness. Requires owning the source state and FU cost.
     * @param stateId The ID of the state from which to trigger the reaction.
     */
    function triggerEntangledReaction(uint256 stateId) external whenNotPaused {
         QuantumStateProperties storage state1 = _getQuantumState(stateId);
         if (state1.owner != msg.sender) revert QuantumFluctuations__NotStateOwner();
         if (state1.entangledWithStateId == 0) revert QuantumFluctuations__ReactionFailed("State not entangled");

         if (s_fluctuationUnits[msg.sender] < s_config.reactionCost) revert QuantumFluctuations__InsufficientFunds();
         _burnFluctuationUnits(msg.sender, s_config.reactionCost);

         uint256 targetStateId = state1.entangledWithStateId;
         // Check if the target state still exists
         if (s_quantumStates[targetStateId].id != targetStateId) {
              // Target state no longer exists, break entanglement? Or just fail?
              // Let's break the entanglement from the source state.
             state1.entangledWithStateId = 0;
             state1.lastInteractionBlock = block.number;
              emit StateDisentangled(stateId);
             revert QuantumFluctuations__ReactionFailed("Entangled target state no longer exists");
         }

         QuantumStateProperties storage state2 = s_quantumStates[targetStateId]; // Get mutable reference to target

        // --- Simulate Reaction (Pseudo-Randomness) ---
        // Reaction outcome influenced by intensity, both states' properties, and block data
         uint256 entropy = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            s_fluctuationIntensity,
            state1.stability, state1.resonance, state1.vitality,
            state2.stability, state2.resonance, state2.vitality,
            stateId, targetStateId, msg.sender
        )));

        // Example Reaction Logic: 50/50 chance of mutation or decay on target,
        // potentially stronger effect based on resonance/intensity.
        if (entropy % 2 == 0) {
             // Trigger mutation-like effect on target
             uint256 intensityFactor = s_fluctuationIntensity / 100;
             uint256 maxProp = s_config.maxPropertyRange;

             int256 stabilityChange = int256((entropy % (intensityFactor + state1.resonance / 20 + state2.resonance / 20)) - (intensityFactor / 4 + state2.stability / 20));
             int256 resonanceChange = int256((entropy % (intensityFactor + state1.stability / 20 + state2.stability / 20)) - (intensityFactor / 4 + state2.resonance / 20));
             int256 vitalityChange = int256((entropy % (intensityFactor / 4 + (state1.vitality + state2.vitality) / 40)) - intensityFactor / 8);

             // Apply changes, clamping within [0, maxProp]
             state2.stability = uint256(int256(state2.stability) + stabilityChange).clamp(0, maxProp);
             state2.resonance = uint256(int256(state2.resonance) + resonanceChange).clamp(0, maxProp);
             state2.vitality = uint256(int256(state2.vitality) + vitalityChange).clamp(0, maxProp);

             state2.lastInteractionBlock = block.number;
             emit StateMutated(targetStateId, state2.stability, state2.resonance, state2.vitality, s_fluctuationIntensity); // Re-use mutation event
        } else {
             // Trigger decay-like effect on target (potentially stronger)
             _applyDecay(targetStateId); // Use existing decay logic, maybe adjust rate based on entropy/intensity if desired
             // Event emitted within _applyDecay
        }

        state1.lastInteractionBlock = block.number; // Update source state interaction block too

        emit EntangledReactionTriggered(stateId, targetStateId);
    }

    // --- Internal Prediction Market Functions ---

     /**
     * @notice Proposes a prediction for the future Fluctuation Intensity.
     * @dev Requires bonding FUs. Only one prediction can be active at a time.
     * @param intensityValue The predicted intensity value.
     * @param resolutionBlock The block number at which the prediction resolves. Must be in the future.
     */
    function proposeIntensityPrediction(uint256 intensityValue, uint256 resolutionBlock) external whenNotPaused {
        if (s_activePrediction.active) revert QuantumFluctuations__AlreadyPredicting();
        if (resolutionBlock <= block.number) revert QuantumFluctuations__InvalidStateOperation("Resolution block must be in the future");
        if (intensityValue > 10000) intensityValue = 10000; // Cap prediction value
        if (s_fluctuationUnits[msg.sender] < s_config.predictionBondAmount) revert QuantumFluctuations__InsufficientFunds();

        _burnFluctuationUnits(msg.sender, s_config.predictionBondAmount); // Bond the FUs

        s_activePrediction = IntensityPrediction({
            predictor: msg.sender,
            intensityValue: intensityValue,
            resolutionBlock: resolutionBlock,
            bondAmount: s_config.predictionBondAmount,
            active: true
        });

        emit IntensityPredictionProposed(msg.sender, intensityValue, resolutionBlock, s_config.predictionBondAmount);
    }

     /**
     * @notice Resolves the active prediction if the resolution block is reached.
     * @dev Checks if the actual intensity is within tolerance and rewards the predictor if correct.
     */
    function resolveIntensityPrediction() external whenNotPaused {
        if (!s_activePrediction.active) revert QuantumFluctuations__NoActivePrediction();
        if (block.number < s_activePrediction.resolutionBlock) revert QuantumFluctuations__PredictionNotResolvedYet();

        address predictor = s_activePrediction.predictor;
        uint256 predictedValue = s_activePrediction.intensityValue;
        uint256 bond = s_activePrediction.bondAmount;

        // Capture current intensity at resolution
        uint256 actualValue = s_fluctuationIntensity;

        // Calculate tolerance range
        uint256 tolerance = (predictedValue * s_config.predictionTolerance) / 1000; // tolerance is in permille now for 0.1% precision
        uint256 lowerBound = (predictedValue >= tolerance) ? predictedValue - tolerance : 0;
        uint256 upperBound = predictedValue + tolerance;
        // Cap upper bound at max intensity value (10000 example cap)
        if (upperBound > 10000) upperBound = 10000;


        bool accurate = (actualValue >= lowerBound && actualValue <= upperBound);
        uint256 reward = 0;

        if (accurate) {
            // Return bond and give a reward (e.g., proportional to bond or fixed)
            _mintFluctuationUnits(predictor, bond); // Return bond
            reward = bond / 2; // Example reward: 50% of bond
             _mintFluctuationUnits(predictor, reward);
        } else {
            // Bond is lost (stays in contract or could be burned)
            // For this example, let's say it just stays in the contract's "unallocated" balance.
            // Could implement a treasury or burn mechanism if needed.
        }

        // Deactivate the prediction
        s_activePrediction.active = false;

        emit IntensityPredictionResolved(predictor, accurate, accurate ? bond : 0, reward);
    }

     /**
     * @notice Gets the details of the currently active prediction.
     * @return The prediction struct.
     */
    function getCurrentPredictionDetails() public view returns (IntensityPrediction memory) {
        return s_activePrediction;
    }

    // --- Configuration Functions (Owner Only) ---

     /**
     * @notice Owner-only. Sets the rate at which Quantum States decay.
     * @param newRate The new decay rate.
     */
    function updateEquilibriumDecayRate(uint256 newRate) external onlyOwner whenNotPaused {
        s_config.equilibriumDecayRate = newRate;
        emit ConfigUpdated();
    }

    /**
     * @notice Owner-only. Updates various parameters affecting the core logic, costs, and rewards.
     * @dev Allows tuning the system's economy and dynamics.
     * @param intensityChangeFactor How much intensity changes per observation.
     * @param observationBonusAmount FU bonus for observer.
     * @param observationCost FU cost to observe.
     * @param mutationCost FU cost to mutate a state.
     * @param synthesisBaseYield Base FUs received from synthesizing a state.
     * @param entanglementCost FU cost to entangle states.
     * @param reactionCost FU cost to trigger entangled reaction.
     * @param mintStateCost FU cost to mint a new state.
     * @param predictionTolerance % tolerance for prediction accuracy (e.g., 50 = +/- 5%).
     * @param maxPropertyRange Max value for state properties (e.g., 1000).
     */
    function updateFluctuationParameters(
        uint256 intensityChangeFactor,
        uint256 observationBonusAmount,
        uint256 observationCost,
        uint256 mutationCost,
        uint256 synthesisBaseYield,
        uint256 entanglementCost,
        uint256 reactionCost,
        uint256 mintStateCost,
        uint256 predictionTolerance, // e.g., 50 for 5%
        uint256 maxPropertyRange // e.g., 1000
    ) external onlyOwner whenNotPaused {
         if (maxPropertyRange == 0) revert QuantumFluctuations__InvalidAmount();

        s_config.intensityChangeFactor = intensityChangeFactor;
        s_config.observationBonusAmount = observationBonusAmount;
        s_config.observationCost = observationCost;
        s_config.mutationCost = mutationCost;
        s_config.synthesisBaseYield = synthesisBaseYield;
        s_config.entanglementCost = entanglementCost;
        s_config.reactionCost = reactionCost;
        s_config.mintStateCost = mintStateCost;
        s_config.predictionTolerance = predictionTolerance; // Store in permille (0.1%) if needed for higher precision, or keep simple %
        s_config.maxPropertyRange = maxPropertyRange;

        // Ensure intensity doesn't exceed new max if updated downwards (optional)
        // if (s_fluctuationIntensity > 10000) s_fluctuationIntensity = 10000; // Using example cap of 10000

        emit ConfigUpdated();
    }

     /**
     * @notice Owner-only. Sets the amount of FUs required to propose a prediction.
     * @param amount The new bond amount.
     */
    function setPredictionBondAmount(uint256 amount) external onlyOwner whenNotPaused {
        s_config.predictionBondAmount = amount;
         emit ConfigUpdated();
    }

     /**
     * @notice Owner-only. Mints initial Fluctuating Units into the system for a recipient.
     * @dev Used for initial token distribution or funding certain pools.
     * @param recipient The address to receive the FUs.
     * @param amount The amount of FUs to mint.
     */
    function mintInitialFluctuationUnits(address recipient, uint256 amount) external onlyOwner {
        if (recipient == address(0)) revert QuantumFluctuations__ZeroAddress();
        if (amount == 0) revert QuantumFluctuations__InvalidAmount();

        _mintFluctuationUnits(recipient, amount);
        emit FluctuationUnitsMinted(recipient, amount);
    }

    // --- Utility & View Functions ---

     /**
     * @notice Gets the current global Fluctuation Intensity.
     * @return The current intensity value.
     */
    function getFluctuationIntensity() public view returns (uint256) {
        return s_fluctuationIntensity;
    }

     /**
     * @notice Gets the number of blocks elapsed since the last observation.
     * @return The number of blocks.
     */
    function getTimeSinceLastObservation() public view returns (uint256) {
        return block.number - s_lastObservationBlock;
    }

     /**
     * @notice Estimates the possible range of a Q-State's properties after mutation *if* it were to happen now.
     * @dev This is a probabilistic estimate based on current state and intensity, not a future prediction.
     *      Does not change state or apply decay.
     * @param stateId The ID of the state to simulate mutation for.
     * @return Estimated min/max values for stability, resonance, and vitality after one mutation.
     */
    function simulateFutureMutation(uint256 stateId) public view returns (
        uint256 estimatedMinStability, uint256 estimatedMaxStability,
        uint256 estimatedMinResonance, uint256 estimatedMaxResonance,
        uint256 estimatedMinVitality, uint256 estimatedMaxVitality
    ) {
         _getQuantumState(stateId); // Check existence
         QuantumStateProperties memory state = s_quantumStates[stateId]; // Use memory to avoid side effects

        // This is a simplified view based on the *current* state and intensity.
        // True simulation of future state including future intensity changes is not feasible/deterministic in a view function.
        // The actual change in mutateQuantumState is int256((entropy % X) - Y).
        // Max change is roughly X, min change is roughly -Y.
        // Max X for stability change: intensityFactor + state.resonance / 10
        // Min Y for stability change: intensityFactor / 2 + state.stability / 10
        // Max positive change: X
        // Max negative change: -Y

        uint256 intensityFactor = s_fluctuationIntensity / 100;
        uint256 maxProp = s_config.maxPropertyRange;

        // Estimate ranges based on the mutation formula's bounds (simplified)
        // Consider the 'entropy % MaxEntropyTerm' part. Max value is roughly MaxEntropyTerm - 1, min is 0.
        // The change is (random value) - ConstantTerm.
        // Max Change ~ (MaxEntropyTerm - 1) - ConstantTerm
        // Min Change ~ 0 - ConstantTerm = -ConstantTerm

        // Stability Change: (entropy % (intensityFactor + state.resonance / 10)) - (intensityFactor / 2 + state.stability / 10)
        uint256 stabilityMaxEntropyTerm = intensityFactor + state.resonance / 10 + 1; // +1 because modulo N gives 0..N-1
        uint256 stabilityConstantTerm = intensityFactor / 2 + state.stability / 10;
        int256 estimatedMaxStabilityChange = int256(stabilityMaxEntropyTerm - 1) - int256(stabilityConstantTerm);
        int256 estimatedMinStabilityChange = 0 - int256(stabilityConstantTerm);

        estimatedMinStability = uint256(int256(state.stability) + estimatedMinStabilityChange).clamp(0, maxProp);
        estimatedMaxStability = uint256(int256(state.stability) + estimatedMaxStabilityChange).clamp(0, maxProp);


        // Resonance Change: (entropy % (intensityFactor + state.stability / 10)) - (intensityFactor / 2 + state.resonance / 10)
        uint256 resonanceMaxEntropyTerm = intensityFactor + state.stability / 10 + 1;
        uint256 resonanceConstantTerm = intensityFactor / 2 + state.resonance / 10;
        int256 estimatedMaxResonanceChange = int256(resonanceMaxEntropyTerm - 1) - int256(resonanceConstantTerm);
        int256 estimatedMinResonanceChange = 0 - int256(resonanceConstantTerm);

        estimatedMinResonance = uint256(int256(state.resonance) + estimatedMinResonanceChange).clamp(0, maxProp);
        estimatedMaxResonance = uint256(int256(state.resonance) + estimatedMaxResonanceChange).clamp(0, maxProp);


        // Vitality Change: (entropy % (intensityFactor / 2 + (state.stability + state.resonance) / 20)) - intensityFactor / 4
         uint256 vitalityMaxEntropyTerm = intensityFactor / 2 + (state.stability + state.resonance) / 20 + 1;
         uint256 vitalityConstantTerm = intensityFactor / 4;
         int256 estimatedMaxVitalityChange = int256(vitalityMaxEntropyTerm - 1) - int256(vitalityConstantTerm);
         int256 estimatedMinVitalityChange = 0 - int256(vitalityConstantTerm);

        estimatedMinVitality = uint256(int256(state.vitality) + estimatedMinVitalityChange).clamp(0, maxProp);
        estimatedMaxVitality = uint256(int256(state.vitality) + estimatedMaxVitalityChange).clamp(0, maxProp);

        return (
            estimatedMinStability, estimatedMaxStability,
            estimatedMinResonance, estimatedMaxResonance,
            estimatedMinVitality, estimatedMaxVitality
        );
    }


     /**
     * @notice Calculates the amount of decay that would be applied to a Q-State *right now*.
     * @param stateId The ID of the state.
     * @return The amount of decay to apply to each property.
     */
    function calculateDecayAmount(uint256 stateId) public view returns (uint256 decayAmount) {
        _getQuantumState(stateId); // Check existence
        QuantumStateProperties memory state = s_quantumStates[stateId]; // Use memory

        uint256 blocksSinceInteraction = block.number - state.lastInteractionBlock;
        uint256 rate = s_config.equilibriumDecayRate;

        // Simple linear decay: decayAmount = blocksSinceInteraction / rate
        // Cap decay to prevent overflow or excessive decay
        decayAmount = (blocksSinceInteraction > 0 && rate > 0) ? blocksSinceInteraction / rate : 0;

        // Cap decay so it doesn't exceed current property values (though decay is subtracted, calculation is simpler this way)
        uint256 maxPossibleDecay = state.stability; // Decay is applied equally to all properties in _applyDecay example
        if (decayAmount > maxPossibleDecay) decayAmount = maxPossibleDecay; // Prevent decaying below zero (though uint will wrap)
        if (decayAmount > s_config.maxPropertyRange) decayAmount = s_config.maxPropertyRange; // Arbitrary cap on decay amount per call

        return decayAmount;
    }

    /**
     * @notice Estimates the properties of a Q-State after applying decay logic for a certain number of blocks.
     * @dev Does not change state. Uses current properties and decay rate.
     * @param stateId The ID of the state.
     * @param blocksInFuture The number of blocks to simulate decay over.
     * @return Estimated stability, resonance, vitality after decay.
     */
    function predictStateDecay(uint256 stateId, uint256 blocksInFuture) public view returns (
        uint256 estimatedStability, uint256 estimatedResonance, uint256 estimatedVitality
    ) {
         _getQuantumState(stateId); // Check existence
         QuantumStateProperties memory state = s_quantumStates[stateId]; // Use memory

        uint256 rate = s_config.equilibriumDecayRate;
        uint256 decayAmountTotal = (blocksInFuture > 0 && rate > 0) ? blocksInFuture / rate : 0;

        // Apply decay to each property, clamping at 0
        estimatedStability = (state.stability > decayAmountTotal) ? state.stability - decayAmountTotal : 0;
        estimatedResonance = (state.resonance > decayAmountTotal) ? state.resonance - decayAmountTotal : 0;
        estimatedVitality = (state.vitality > decayAmountTotal) ? state.vitality - decayAmountTotal : 0;

        return (estimatedStability, estimatedResonance, estimatedVitality);
    }

    // --- Internal Helper Functions ---

     /**
     * @dev Internal function to mint Fluctuating Units.
     */
    function _mintFluctuationUnits(address account, uint256 amount) internal {
        // No overflow check needed for addition if amount is uint256 (max supply is effectively 2^256)
        // Could add a cap if a specific max supply is desired.
        s_fluctuationUnits[account] += amount;
        s_totalFluctuationUnits += amount;
    }

     /**
     * @dev Internal function to burn Fluctuating Units.
     */
    function _burnFluctuationUnits(address account, uint256 amount) internal {
        s_fluctuationUnits[account] -= amount; // Safe due to check in public/external burn function
        s_totalFluctuationUnits -= amount; // Safe due to check in public/external burn function
    }

     /**
     * @dev Internal helper to retrieve QuantumStateProperties and check existence.
     */
    function _getQuantumState(uint256 stateId) internal view returns (QuantumStateProperties storage) {
        // State ID 0 is reserved (unentangled state)
        if (stateId == 0) revert QuantumFluctuations__StateNotFound(stateId);
        // Check if the state mapping entry corresponds to the ID
        if (s_quantumStates[stateId].id != stateId) {
            revert QuantumFluctuations__StateNotFound(stateId);
        }
        return s_quantumStates[stateId];
    }

     /**
     * @dev Internal function to apply decay logic to a state.
     *      Updates properties and lastInteractionBlock. Emits event.
     */
    function _applyDecay(uint256 stateId) internal {
        QuantumStateProperties storage state = _getQuantumState(stateId);

        uint256 blocksSinceInteraction = block.number - state.lastInteractionBlock;
        uint256 rate = s_config.equilibriumDecayRate;

        if (blocksSinceInteraction == 0 || rate == 0) return; // No decay needed or possible

        uint256 decayAmount = blocksSinceInteraction / rate;

        // Apply decay, clamping at 0
        uint256 oldStability = state.stability;
        uint256 oldResonance = state.resonance;
        uint256 oldVitality = state.vitality;

        state.stability = (state.stability > decayAmount) ? state.stability - decayAmount : 0;
        state.resonance = (state.resonance > decayAmount) ? state.resonance - decayAmount : 0;
        state.vitality = (state.vitality > decayAmount) ? state.vitality - decayAmount : 0;

        state.lastInteractionBlock = block.number; // Update interaction block

        emit StateDecayed(stateId, state.stability, state.resonance, state.vitality, decayAmount);
    }
}

// Helper library for clamping (could be internal or external)
library Clamp {
    function clamp(uint256 self, uint256 min, uint256 max) internal pure returns (uint256) {
        return self < min ? min : (self > max ? max : self);
    }
     function clamp(int256 self, int256 min, int256 max) internal pure returns (int256) {
        return self < min ? min : (self > max ? max : self);
    }
}

// Add Clamp library to the contract's scope if needed (optional, can be standalone)
// using Clamp for uint256;
// using Clamp for int256;
// Or just make the internal helper functions within the contract directly. Let's add them inside.
// Re-integrating clamp into the contract to avoid extra import/using directive.

// Final contract with clamp integrated:
// Remove the external library and using directive.
// Add the clamp helper functions internally.

// (Integrating clamp... see final code structure)

// --- Final Code Structure Refinement ---
// Move internal helpers to the end.
// Integrate clamp functions directly.
// Double check function count.
// Add necessary imports.
// Ensure all outlined functions are present.

```

**Final Contract Code (Integrating Clamp):**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";


// Custom error definitions
error QuantumFluctuations__InsufficientFunds();
error QuantumFluctuations__InvalidAmount();
error QuantumFluctuations__StateNotFound(uint256 stateId);
error QuantumFluctuations__NotStateOwner();
error QuantumFluctuations__TransferFailed();
error QuantumFluctuations__AlreadyPredicting();
error QuantumFluctuations__PredictionNotResolvedYet();
error QuantumFluctuations__NoActivePrediction();
error QuantumFluctuations__InvalidStateOperation(string reason); // More generic for state issues
error QuantumFluctuations__EntanglementFailed(string reason);
error QuantumFluctuations__ReactionFailed(string reason);
error QuantumFluctuations__ZeroAddress();


contract QuantumFluctuations is Ownable, Pausable {

    // --- State Variables ---

    // Fungible Fluctuating Units (FUs)
    mapping(address => uint256) private s_fluctuationUnits;
    uint256 private s_totalFluctuationUnits;

    // Non-Fungible Quantum States (Q-States)
    struct QuantumStateProperties {
        uint256 id;
        address owner;
        uint256 creationBlock;
        uint256 lastInteractionBlock; // Block of last mutation, decay, or entanglement change
        uint256 stability; // How resistant to decay (0-1000)
        uint256 resonance; // How much it interacts with intensity (0-1000)
        uint256 vitality;  // General health/value attribute (0-1000)
        uint256 entangledWithStateId; // 0 if not entangled, otherwise ID of entangled state
    }
    mapping(uint256 => QuantumStateProperties) private s_quantumStates;
    uint256 private s_nextQuantumStateId = 1; // Start state IDs from 1

    // System Parameters
    uint256 private s_fluctuationIntensity; // Main dynamic parameter (0-10000)
    uint256 private s_lastObservationBlock; // Block number when observeFluctuations was last called

    // Configuration Parameters (Owner-adjustable)
    struct ConfigParameters {
        uint256 equilibriumDecayRate; // Rate of decay per block difference (e.g., 1 per 100 blocks)
        uint256 intensityChangeFactor; // How much intensity changes per observation (e.g., 100 for +/- 100 range)
        uint256 observationBonusAmount; // FU bonus for observer
        uint256 observationCost; // FU cost to observe
        uint256 mutationCost; // FU cost to mutate a state
        uint256 synthesisBaseYield; // Base FUs received from synthesizing a state
        uint256 entanglementCost; // FU cost to entangle states
        uint256 reactionCost; // FU cost to trigger entangled reaction
        uint256 mintStateCost; // FU cost to mint a new state
        uint256 predictionBondAmount; // FU cost to make a prediction
        uint256 predictionTolerance; // Tolerance for prediction accuracy (e.g., 50 for +/- 0.5%) (Value / 1000)
        uint256 maxPropertyRange; // Max value for state properties (e.g., 1000)
        uint256 maxIntensity; // Max value for fluctuation intensity
    }
    ConfigParameters private s_config;

    // Internal Prediction Market
    struct IntensityPrediction {
        address predictor;
        uint256 intensityValue;
        uint256 resolutionBlock;
        uint256 bondAmount;
        bool active;
    }
    IntensityPrediction private s_activePrediction;

    // --- Events ---

    event FluctuationsObserved(uint256 newIntensity, uint256 observationBonusGiven);
    event StateMinted(uint256 stateId, address owner, uint256 creationBlock);
    event StateTransfer(address indexed from, address indexed to, uint256 indexed stateId);
    event StateMutated(uint256 indexed stateId, uint256 newStability, uint256 newResonance, uint256 newVitality, uint256 intensityAtMutation);
    event StateDecayed(uint256 indexed stateId, uint256 newStability, uint256 newResonance, uint256 newVitality, uint256 decayAmountApplied);
    event StateSynthesized(uint256 indexed stateId, address owner, uint256 unitsMinted);
    event StateEntangled(uint256 indexed stateId1, uint256 indexed stateId2);
    event StateDisentangled(uint256 indexed stateId);
    event EntangledReactionTriggered(uint256 indexed stateId, uint256 indexed targetStateId);
    event IntensityPredictionProposed(address indexed predictor, uint256 intensityValue, uint256 resolutionBlock, uint256 bondAmount);
    event IntensityPredictionResolved(address indexed predictor, bool accurate, uint256 bondReturned, uint256 rewardGiven);
    event FluctuationUnitsMinted(address indexed recipient, uint256 amount);
    event FluctuationUnitsBurned(address indexed account, uint256 amount);
    event ConfigUpdated();

    // --- Constructor ---

    constructor(
        uint256 initialFluctuationIntensity,
        uint256 initialEquilibriumDecayRate,
        uint256 initialIntensityChangeFactor,
        uint256 initialObservationBonusAmount,
        uint256 initialObservationCost,
        uint256 initialMutationCost,
        uint256 initialSynthesisBaseYield,
        uint256 initialEntanglementCost,
        uint256 initialReactionCost,
        uint256 initialMintStateCost,
        uint256 initialPredictionBondAmount,
        uint256 initialPredictionTolerance, // e.g., 50 for +/- 0.5% (Value / 1000)
        uint256 initialMaxPropertyRange, // e.g., 1000
        uint256 initialMaxIntensity // e.g., 10000
    ) Ownable(msg.sender) Pausable(false) {
        // Basic validation
        if (initialMaxPropertyRange == 0 || initialMaxIntensity == 0) revert QuantumFluctuations__InvalidAmount();
        if (initialFluctuationIntensity > initialMaxIntensity) initialFluctuationIntensity = initialMaxIntensity;

        s_fluctuationIntensity = initialFluctuationIntensity;
        s_lastObservationBlock = block.number;

        s_config = ConfigParameters({
            equilibriumDecayRate: initialEquilibriumDecayRate,
            intensityChangeFactor: initialIntensityChangeFactor,
            observationBonusAmount: initialObservationBonusAmount,
            observationCost: initialObservationCost,
            mutationCost: initialMutationCost,
            synthesisBaseYield: initialSynthesisBaseYield,
            entanglementCost: initialEntanglementCost,
            reactionCost: initialReactionCost,
            mintStateCost: initialMintStateCost,
            predictionBondAmount: initialPredictionBondAmount,
            predictionTolerance: initialPredictionTolerance, // stored as is, used as value/1000
            maxPropertyRange: initialMaxPropertyRange,
            maxIntensity: initialMaxIntensity
        });

        // Initialize prediction state
        s_activePrediction.active = false;
    }

    // --- Modifiers ---
    // Inherited from Ownable and Pausable

    // --- Core Quantum/Dynamic Logic Functions ---

    /**
     * @notice Triggers a system observation, potentially changing global intensity.
     * @dev Pays observation cost, updates intensity based on block number and other factors.
     *      May award a small FU bonus.
     */
    function observeFluctuations() external whenNotPaused {
        if (s_fluctuationUnits[msg.sender] < s_config.observationCost) revert QuantumFluctuations__InsufficientFunds();

        _burnFluctuationUnits(msg.sender, s_config.observationCost);

        // --- Simulate Fluctuation Intensity Change (Pseudo-Randomness) ---
        // WARNING: This pseudo-randomness is based on block data and contract state.
        // It is NOT cryptographically secure and can be influenced by miners.
        // For high-value applications, integrate Chainlink VRF or similar external randomness.

        uint256 timeSinceLast = block.number - s_lastObservationBlock;
        uint256 entropy = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao, // Use prevrandao instead of difficulty for newer Solidity
            s_fluctuationIntensity,
            timeSinceLast,
            msg.sender,
            s_totalFluctuationUnits // Include contract state
        )));

        // Intensity change is influenced by entropy and config parameters
        // Example logic: Intensity tends towards a mid-range but fluctuates based on entropy
        uint256 intensityChange = (entropy % (s_config.intensityChangeFactor + 1)); // Add 1 to avoid modulo 0 if config is 0

        if (entropy % 2 == 0) {
            // Increase intensity, capped at max
            s_fluctuationIntensity = _clamp(s_fluctuationIntensity + intensityChange, 0, s_config.maxIntensity);
        } else {
            // Decrease intensity, floored at min
             s_fluctuationIntensity = _clamp(s_fluctuationIntensity - intensityChange, 0, s_config.maxIntensity);
        }

        s_lastObservationBlock = block.number;

        // Award potential bonus
        uint256 bonusGiven = 0;
        if (s_config.observationBonusAmount > 0) {
             // Simple probabilistic bonus chance based on entropy and intensity
             // e.g., higher intensity slightly increases bonus chance
             uint256 bonusChanceFactor = s_config.maxIntensity > 0 ? s_fluctuationIntensity * 100 / s_config.maxIntensity : 0; // Scale intensity to 0-100
             if (entropy % 100 < bonusChanceFactor + 10) { // Add a base chance + intensity scaled chance
                 _mintFluctuationUnits(msg.sender, s_config.observationBonusAmount);
                 bonusGiven = s_config.observationBonusAmount;
             }
        }

        emit FluctuationsObserved(s_fluctuationIntensity, bonusGiven);
    }

     /**
     * @notice Attempts to mutate the properties of a Quantum State.
     * @dev Outcome depends on current intensity and internal randomness. Applies decay first.
     * @param stateId The ID of the state to mutate.
     */
    function mutateQuantumState(uint256 stateId) external whenNotPaused {
        QuantumStateProperties storage state = _getQuantumState(stateId);
        if (state.owner != msg.sender) revert QuantumFluctuations__NotStateOwner();
        if (s_fluctuationUnits[msg.sender] < s_config.mutationCost) revert QuantumFluctuations__InsufficientFunds();

        _burnFluctuationUnits(msg.sender, s_config.mutationCost);

        // Apply decay before mutation
        _applyDecay(stateId);

        // --- Simulate Mutation (Pseudo-Randomness) ---
        // Influenced by current state properties, intensity, and block data
         uint256 entropy = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            s_fluctuationIntensity,
            state.stability,
            state.resonance,
            state.vitality,
            stateId,
            msg.sender
        )));

        uint256 intensityFactor = s_config.maxIntensity > 0 ? s_fluctuationIntensity * 100 / s_config.maxIntensity : 0; // Scale intensity to 0-100
        uint256 maxProp = s_config.maxPropertyRange;

        // Example Mutation Logic: Properties change based on entropy and intensity.
        // Higher resonance might mean more drastic changes influenced by intensity.
        // Higher stability might resist change.
        // Vitality might shift based on the outcome.

        int256 stabilityChange = int256((entropy % (intensityFactor + state.resonance / 10 + 1)) - (intensityFactor / 2 + state.stability / 10));
        int256 resonanceChange = int256((entropy % (intensityFactor + state.stability / 10 + 1)) - (intensityFactor / 2 + state.resonance / 10));
        int256 vitalityChange = int256((entropy % (intensityFactor / 2 + (state.stability + state.resonance) / 20 + 1)) - intensityFactor / 4);

        // Apply changes, clamping within [0, maxProp]
        state.stability = _clampIntToUint(int256(state.stability) + stabilityChange, 0, maxProp);
        state.resonance = _clampIntToUint(int256(state.resonance) + resonanceChange, 0, maxProp);
        state.vitality = _clampIntToUint(int256(state.vitality) + vitalityChange, 0, maxProp);

        state.lastInteractionBlock = block.number; // Update interaction block after mutation

        emit StateMutated(stateId, state.stability, state.resonance, state.vitality, s_fluctuationIntensity);
    }

     /**
     * @notice Applies time-based decay to a Quantum State's properties towards an equilibrium.
     * @dev Can be called by anyone to update a state's properties based on elapsed blocks.
     * @param stateId The ID of the state to decay.
     */
    function decayQuantumState(uint256 stateId) external whenNotPaused {
         _getQuantumState(stateId); // Check existence

         // Applying decay is public function, doesn't require ownership, just updates state
        _applyDecay(stateId);

        // Event emitted within _applyDecay
    }

    /**
     * @notice Burns a Quantum State and synthesizes Fluctuating Units based on its properties.
     * @dev The amount of FUs minted depends on the state's vitality, resonance, and current intensity.
     * @param stateId The ID of the state to synthesize.
     */
    function synthesizeStateEnergy(uint256 stateId) external whenNotPaused {
        QuantumStateProperties storage state = _getQuantumState(stateId);
        if (state.owner != msg.sender) revert QuantumFluctuations__NotStateOwner();

        // Apply decay before calculating synthesis yield
        _applyDecay(stateId);

        // Example Synthesis Yield Logic:
        // Base yield + bonus based on vitality, resonance, and intensity.
        uint256 intensityFactor = s_config.maxIntensity > 0 ? s_fluctuationIntensity * 100 / s_config.maxIntensity : 0; // Scale intensity 0-100
        uint256 yield = s_config.synthesisBaseYield +
                       (state.vitality * intensityFactor / 100) + // Vitality contributes more at higher intensity
                       (state.resonance * (100 - intensityFactor) / 100); // Resonance contributes more at lower intensity (example)

        address owner = state.owner; // Capture owner before deleting

        // Remove the state
        delete s_quantumStates[stateId];

        // Mint FUs to the owner
        if (yield > 0) {
            _mintFluctuationUnits(owner, yield);
        }

        emit StateSynthesized(stateId, owner, yield);
    }


    // --- Fluctuation Unit (FU) Management Functions ---

    // Note: mintInitialFluctuationUnits is below with Owner functions

    /**
     * @notice Transfers Fluctuating Units from the caller to a recipient.
     * @param recipient The address to transfer FUs to.
     * @param amount The amount of FUs to transfer.
     */
    function transferFluctuationUnits(address recipient, uint256 amount) public whenNotPaused {
        if (recipient == address(0)) revert QuantumFluctuations__ZeroAddress();
        if (amount == 0) revert QuantumFluctuations__InvalidAmount();
        if (s_fluctuationUnits[msg.sender] < amount) revert QuantumFluctuations__InsufficientFunds();

        s_fluctuationUnits[msg.sender] -= amount;
        s_fluctuationUnits[recipient] += amount;

        // No ERC20 Transfer event as this is not a standard ERC20
        // Can add a custom event if needed, but keeping it minimal here
    }

    /**
     * @notice Burns Fluctuating Units from the caller's balance.
     * @param amount The amount of FUs to burn.
     */
    function burnFluctuationUnits(uint256 amount) public whenNotPaused {
         if (amount == 0) revert QuantumFluctuations__InvalidAmount();
         if (s_fluctuationUnits[msg.sender] < amount) revert QuantumFluctuations__InsufficientFunds();

         _burnFluctuationUnits(msg.sender, amount);
         emit FluctuationUnitsBurned(msg.sender, amount);
    }

    /**
     * @notice Gets the balance of Fluctuating Units for an account.
     * @param account The address to query.
     * @return The FU balance of the account.
     */
    function balanceOfFluctuationUnits(address account) public view returns (uint256) {
        return s_fluctuationUnits[account];
    }

    // --- Quantum State (Q-State) Management Functions ---

     /**
     * @notice Creates a new Quantum State (NFT) and assigns it to the caller.
     * @dev Requires FU payment. Initial properties are pseudo-randomly assigned.
     * @return The ID of the newly minted state.
     */
    function mintQuantumState() external whenNotPaused returns (uint256) {
        if (s_fluctuationUnits[msg.sender] < s_config.mintStateCost) revert QuantumFluctuations__InsufficientFunds();

        _burnFluctuationUnits(msg.sender, s_config.mintStateCost);

        uint256 newStateId = s_nextQuantumStateId++;

        // --- Simulate Initial Properties (Pseudo-Randomness) ---
        uint256 entropy = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender,
            newStateId,
            s_totalFluctuationUnits
        )));

        uint256 maxProp = s_config.maxPropertyRange;

        s_quantumStates[newStateId] = QuantumStateProperties({
            id: newStateId,
            owner: msg.sender,
            creationBlock: block.number,
            lastInteractionBlock: block.number, // Set interaction block on creation
            stability: (entropy % maxProp), // Initial stability
            resonance: ((entropy / 10) % maxProp), // Initial resonance
            vitality: ((entropy / 100) % maxProp), // Initial vitality
            entangledWithStateId: 0 // Not entangled initially
        });

        emit StateMinted(newStateId, msg.sender, block.number);
        return newStateId;
    }

    /**
     * @notice Transfers ownership of a Quantum State.
     * @dev Similar to ERC721 transferFrom, requires sender to be owner or approved.
     * @param from The address currently owning the state.
     * @param to The address to transfer the state to.
     * @param stateId The ID of the state to transfer.
     */
    function transferQuantumState(address from, address to, uint256 stateId) public whenNotPaused {
        // Simplified: owner must initiate. For full ERC721 like, would need approval system.
        if (from != msg.sender) revert QuantumFluctuations__TransferFailed("Sender must be 'from' address");
        if (to == address(0)) revert QuantumFluctuations__ZeroAddress();

        QuantumStateProperties storage state = _getQuantumState(stateId);
        if (state.owner != from) revert QuantumFluctuations__NotStateOwner();

        // Apply decay before transfer (optional but consistent)
        _applyDecay(stateId);

        // Perform transfer
        state.owner = to;

        emit StateTransfer(from, to, stateId);
    }

     /**
     * @notice Gets the owner of a Quantum State.
     * @param stateId The ID of the state to query.
     * @return The owner's address.
     */
    function getQuantumStateOwner(uint256 stateId) public view returns (address) {
        _getQuantumState(stateId); // Check existence
        return s_quantumStates[stateId].owner;
    }

     /**
     * @notice Gets the current properties of a Quantum State.
     * @param stateId The ID of the state to query.
     * @return The properties struct.
     */
    function getQuantumStateProperties(uint256 stateId) public view returns (QuantumStateProperties memory) {
         _getQuantumState(stateId); // Check existence
         // Note: This view function does NOT apply decay automatically.
         // Use calculateDecayAmount or predictStateDecay for future values.
         return s_quantumStates[stateId];
    }

    // --- Entanglement Functions ---

    /**
     * @notice Entangles one Quantum State with another. Creates a one-way link.
     * @dev Requires owning the source state and paying an FU cost.
     * @param stateId The ID of the state to entangle.
     * @param entangledWithStateId The ID of the state to entangle with.
     */
    function setQuantumStateEntanglement(uint256 stateId, uint256 entangledWithStateId) external whenNotPaused {
         QuantumStateProperties storage state1 = _getQuantumState(stateId);
         _getQuantumState(entangledWithStateId); // Ensure target exists

         if (state1.owner != msg.sender) revert QuantumFluctuations__NotStateOwner();
         if (stateId == entangledWithStateId) revert QuantumFluctuations__EntanglementFailed("Cannot entangle state with itself");
         if (state1.entangledWithStateId != 0) revert QuantumFluctuations__EntanglementFailed("State already entangled");

         if (s_fluctuationUnits[msg.sender] < s_config.entanglementCost) revert QuantumFluctuations__InsufficientFunds();
         _burnFluctuationUnits(msg.sender, s_config.entanglementCost);

         state1.entangledWithStateId = entangledWithStateId;
         state1.lastInteractionBlock = block.number; // Update interaction block

         emit StateEntangled(stateId, entangledWithStateId);
    }

    /**
     * @notice Breaks the entanglement link from a Quantum State.
     * @dev Requires owning the state.
     * @param stateId The ID of the state to disentangle.
     */
    function breakQuantumStateEntanglement(uint256 stateId) external whenNotPaused {
        QuantumStateProperties storage state = _getQuantumState(stateId);
        if (state.owner != msg.sender) revert QuantumFluctuations__NotStateOwner();
        if (state.entangledWithStateId == 0) revert QuantumFluctuations__InvalidStateOperation("State not entangled");

        state.entangledWithStateId = 0;
         state.lastInteractionBlock = block.number; // Update interaction block

        emit StateDisentangled(stateId);
    }

    /**
     * @notice Triggers a potential reaction on a state's entangled partner.
     * @dev If the state is entangled, this might cause a mutation or decay on the linked state,
     *      influenced by intensity and randomness. Requires owning the source state and FU cost.
     * @param stateId The ID of the state from which to trigger the reaction.
     */
    function triggerEntangledReaction(uint256 stateId) external whenNotPaused {
         QuantumStateProperties storage state1 = _getQuantumState(stateId);
         if (state1.owner != msg.sender) revert QuantumFluctuations__NotStateOwner();
         if (state1.entangledWithStateId == 0) revert QuantumFluctuations__ReactionFailed("State not entangled");

         if (s_fluctuationUnits[msg.sender] < s_config.reactionCost) revert QuantumFluctuations__InsufficientFunds();
         _burnFluctuationUnits(msg.sender, s_config.reactionCost);

         uint256 targetStateId = state1.entangledWithStateId;
         // Check if the target state still exists
         if (s_quantumStates[targetStateId].id != targetStateId) {
              // Target state no longer exists, break entanglement from source and fail reaction
             state1.entangledWithStateId = 0;
             state1.lastInteractionBlock = block.number;
              emit StateDisentangled(stateId);
             revert QuantumFluctuations__ReactionFailed("Entangled target state no longer exists");
         }

         QuantumStateProperties storage state2 = s_quantumStates[targetStateId]; // Get mutable reference to target

        // --- Simulate Reaction (Pseudo-Randomness) ---
        // Reaction outcome influenced by intensity, both states' properties, and block data
         uint256 entropy = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            s_fluctuationIntensity,
            state1.stability, state1.resonance, state1.vitality,
            state2.stability, state2.resonance, state2.vitality,
            stateId, targetStateId, msg.sender
        )));

        // Example Reaction Logic: 50/50 chance of mutation or decay on target,
        // potentially stronger effect based on resonance/intensity.
        if (entropy % 2 == 0) {
             // Trigger mutation-like effect on target
             uint256 intensityFactor = s_config.maxIntensity > 0 ? s_fluctuationIntensity * 100 / s_config.maxIntensity : 0;
             uint256 maxProp = s_config.maxPropertyRange;

             int256 stabilityChange = int256((entropy % (intensityFactor + state1.resonance / 20 + state2.resonance / 20 + 1)) - (intensityFactor / 4 + state2.stability / 20));
             int256 resonanceChange = int256((entropy % (intensityFactor + state1.stability / 20 + state2.stability / 20 + 1)) - (intensityFactor / 4 + state2.resonance / 20));
             int256 vitalityChange = int256((entropy % (intensityFactor / 4 + (state1.vitality + state2.vitality) / 40 + 1)) - intensityFactor / 8);

             // Apply changes, clamping within [0, maxProp]
             state2.stability = _clampIntToUint(int256(state2.stability) + stabilityChange, 0, maxProp);
             state2.resonance = _clampIntToUint(int256(state2.resonance) + resonanceChange, 0, maxProp);
             state2.vitality = _clampIntToUint(int256(state2.vitality) + vitalityChange, 0, maxProp);

             state2.lastInteractionBlock = block.number;
             emit StateMutated(targetStateId, state2.stability, state2.resonance, state2.vitality, s_fluctuationIntensity); // Re-use mutation event
        } else {
             // Trigger decay-like effect on target (potentially stronger)
             // Decay amount could be scaled up here based on entropy/intensity if desired
             _applyDecay(targetStateId); // Use existing decay logic
             // Event emitted within _applyDecay
        }

        state1.lastInteractionBlock = block.number; // Update source state interaction block too

        emit EntangledReactionTriggered(stateId, targetStateId);
    }

    // --- Internal Prediction Market Functions ---

     /**
     * @notice Proposes a prediction for the future Fluctuation Intensity.
     * @dev Requires bonding FUs. Only one prediction can be active at a time.
     * @param intensityValue The predicted intensity value.
     * @param resolutionBlock The block number at which the prediction resolves. Must be in the future.
     */
    function proposeIntensityPrediction(uint256 intensityValue, uint256 resolutionBlock) external whenNotPaused {
        if (s_activePrediction.active) revert QuantumFluctuations__AlreadyPredicting();
        if (resolutionBlock <= block.number) revert QuantumFluctuations__InvalidStateOperation("Resolution block must be in the future");
        if (intensityValue > s_config.maxIntensity) intensityValue = s_config.maxIntensity; // Cap prediction value
        if (s_fluctuationUnits[msg.sender] < s_config.predictionBondAmount) revert QuantumFluctuations__InsufficientFunds();

        _burnFluctuationUnits(msg.sender, s_config.predictionBondAmount); // Bond the FUs

        s_activePrediction = IntensityPrediction({
            predictor: msg.sender,
            intensityValue: intensityValue,
            resolutionBlock: resolutionBlock,
            bondAmount: s_config.predictionBondAmount,
            active: true
        });

        emit IntensityPredictionProposed(msg.sender, intensityValue, resolutionBlock, s_config.predictionBondAmount);
    }

     /**
     * @notice Resolves the active prediction if the resolution block is reached.
     * @dev Checks if the actual intensity is within tolerance and rewards the predictor if correct.
     */
    function resolveIntensityPrediction() external whenNotPaused {
        if (!s_activePrediction.active) revert QuantumFluctuations__NoActivePrediction();
        if (block.number < s_activePrediction.resolutionBlock) revert QuantumFluctuations__PredictionNotResolvedYet();

        address predictor = s_activePrediction.predictor;
        uint256 predictedValue = s_activePrediction.intensityValue;
        uint256 bond = s_activePrediction.bondAmount;

        // Capture current intensity at resolution
        uint256 actualValue = s_fluctuationIntensity;

        // Calculate tolerance range based on stored config tolerance (value / 1000 = 0.1%)
        uint256 toleranceAmount = (predictedValue * s_config.predictionTolerance) / 1000; // tolerance is in permille

        uint256 lowerBound = (predictedValue >= toleranceAmount) ? predictedValue - toleranceAmount : 0;
        uint256 upperBound = predictedValue + toleranceAmount;
        // Cap upper bound at max intensity value
        if (upperBound > s_config.maxIntensity) upperBound = s_config.maxIntensity;


        bool accurate = (actualValue >= lowerBound && actualValue <= upperBound);
        uint256 reward = 0;

        if (accurate) {
            // Return bond and give a reward (e.g., proportional to bond or fixed)
            _mintFluctuationUnits(predictor, bond); // Return bond
            reward = bond / 2; // Example reward: 50% of bond
             _mintFluctuationUnits(predictor, reward);
        } else {
            // Bond is lost (stays in contract's total supply or could be burned)
             emit FluctuationUnitsBurned(address(this), bond); // Simulate burning the bond
        }

        // Deactivate the prediction
        s_activePrediction.active = false;

        emit IntensityPredictionResolved(predictor, accurate, accurate ? bond : 0, reward);
    }

     /**
     * @notice Gets the details of the currently active prediction.
     * @return The prediction struct.
     */
    function getCurrentPredictionDetails() public view returns (IntensityPrediction memory) {
        return s_activePrediction;
    }

    // --- Configuration Functions (Owner Only) ---

     /**
     * @notice Owner-only. Sets the rate at which Quantum States decay.
     * @param newRate The new decay rate.
     */
    function updateEquilibriumDecayRate(uint256 newRate) external onlyOwner whenNotPaused {
        s_config.equilibriumDecayRate = newRate;
        emit ConfigUpdated();
    }

    /**
     * @notice Owner-only. Updates various parameters affecting the core logic, costs, and rewards.
     * @dev Allows tuning the system's economy and dynamics.
     * @param intensityChangeFactor How much intensity changes per observation (e.g., 100).
     * @param observationBonusAmount FU bonus for observer.
     * @param observationCost FU cost to observe.
     * @param mutationCost FU cost to mutate a state.
     * @param synthesisBaseYield Base FUs received from synthesizing a state.
     * @param entanglementCost FU cost to entangle states.
     * @param reactionCost FU cost to trigger entangled reaction.
     * @param mintStateCost FU cost to mint a new state.
     * @param predictionTolerance Tolerance for prediction accuracy (e.g., 50 for +/- 0.5% = 50/1000).
     * @param maxPropertyRange Max value for state properties (e.g., 1000).
     * @param maxIntensity Max value for fluctuation intensity (e.g., 10000).
     */
    function updateFluctuationParameters(
        uint256 intensityChangeFactor,
        uint256 observationBonusAmount,
        uint256 observationCost,
        uint256 mutationCost,
        uint256 synthesisBaseYield,
        uint256 entanglementCost,
        uint256 reactionCost,
        uint256 mintStateCost,
        uint256 predictionTolerance, // stored as is, used as value/1000
        uint256 maxPropertyRange,
        uint256 maxIntensity
    ) external onlyOwner whenNotPaused {
         if (maxPropertyRange == 0 || maxIntensity == 0) revert QuantumFluctuations__InvalidAmount();

        s_config.intensityChangeFactor = intensityChangeFactor;
        s_config.observationBonusAmount = observationBonusAmount;
        s_config.observationCost = observationCost;
        s_config.mutationCost = mutationCost;
        s_config.synthesisBaseYield = synthesisBaseYield;
        s_config.entanglementCost = entanglementCost;
        s_config.reactionCost = reactionCost;
        s_config.mintStateCost = mintStateCost;
        s_config.predictionTolerance = predictionTolerance;
        s_config.maxPropertyRange = maxPropertyRange;
        s_config.maxIntensity = maxIntensity;

        // Clamp current intensity if new max is lower
        s_fluctuationIntensity = _clamp(s_fluctuationIntensity, 0, s_config.maxIntensity);

        emit ConfigUpdated();
    }

     /**
     * @notice Owner-only. Sets the amount of FUs required to propose a prediction.
     * @param amount The new bond amount.
     */
    function setPredictionBondAmount(uint256 amount) external onlyOwner whenNotPaused {
        s_config.predictionBondAmount = amount;
         emit ConfigUpdated();
    }

     /**
     * @notice Owner-only. Mints initial Fluctuating Units into the system for a recipient.
     * @dev Used for initial token distribution or funding certain pools.
     * @param recipient The address to receive the FUs.
     * @param amount The amount of FUs to mint.
     */
    function mintInitialFluctuationUnits(address recipient, uint256 amount) external onlyOwner {
        if (recipient == address(0)) revert QuantumFluctuations__ZeroAddress();
        if (amount == 0) revert QuantumFluctuations__InvalidAmount();

        _mintFluctuationUnits(recipient, amount);
        emit FluctuationUnitsMinted(recipient, amount);
    }

    // --- Utility & View Functions ---

     /**
     * @notice Gets the current global Fluctuation Intensity.
     * @return The current intensity value.
     */
    function getFluctuationIntensity() public view returns (uint256) {
        return s_fluctuationIntensity;
    }

     /**
     * @notice Gets the number of blocks elapsed since the last observation.
     * @return The number of blocks.
     */
    function getTimeSinceLastObservation() public view returns (uint256) {
        return block.number - s_lastObservationBlock;
    }

     /**
     * @notice Estimates the possible range of a Q-State's properties after mutation *if* it were to happen now.
     * @dev This is a probabilistic estimate based on current state and intensity, not a future prediction.
     *      Does not change state or apply decay.
     * @param stateId The ID of the state to simulate mutation for.
     * @return Estimated min/max values for stability, resonance, and vitality after one mutation.
     */
    function simulateFutureMutation(uint256 stateId) public view returns (
        uint256 estimatedMinStability, uint256 estimatedMaxStability,
        uint256 estimatedMinResonance, uint256 estimatedMaxResonance,
        uint256 estimatedMinVitality, uint256 estimatedMaxVitality
    ) {
         _getQuantumState(stateId); // Check existence
         QuantumStateProperties memory state = s_quantumStates[stateId]; // Use memory to avoid side effects

        // This is a simplified view based on the *current* state and intensity.
        // True simulation of future state including future intensity changes is not feasible/deterministic in a view function.
        // The actual change in mutateQuantumState is int256((entropy % MaxEntropyTerm) - ConstantTerm).
        // Max positive change ~ MaxEntropyTerm - 1 - ConstantTerm
        // Max negative change ~ 0 - ConstantTerm = -ConstantTerm

        uint256 intensityFactor = s_config.maxIntensity > 0 ? s_fluctuationIntensity * 100 / s_config.maxIntensity : 0; // Scale intensity 0-100
        uint256 maxProp = s_config.maxPropertyRange;

        // Estimate ranges based on the mutation formula's bounds
        uint256 stabilityMaxEntropyTerm = intensityFactor + state.resonance / 10 + 1;
        uint256 stabilityConstantTerm = intensityFactor / 2 + state.stability / 10;
        int256 estimatedMaxStabilityChange = int256(stabilityMaxEntropyTerm) - 1 - int256(stabilityConstantTerm);
        int256 estimatedMinStabilityChange = 0 - int256(stabilityConstantTerm);

        estimatedMinStability = _clampIntToUint(int256(state.stability) + estimatedMinStabilityChange, 0, maxProp);
        estimatedMaxStability = _clampIntToUint(int256(state.stability) + estimatedMaxStabilityChange, 0, maxProp);


        uint256 resonanceMaxEntropyTerm = intensityFactor + state.stability / 10 + 1;
        uint256 resonanceConstantTerm = intensityFactor / 2 + state.resonance / 10;
        int256 estimatedMaxResonanceChange = int256(resonanceMaxEntropyTerm) - 1 - int256(resonanceConstantTerm);
        int256 estimatedMinResonanceChange = 0 - int256(resonanceConstantTerm);

        estimatedMinResonance = _clampIntToUint(int256(state.resonance) + estimatedMinResonanceChange, 0, maxProp);
        estimatedMaxResonance = _clampIntToUint(int256(state.resonance) + estimatedMaxResonanceChange, 0, maxProp);


         uint256 vitalityMaxEntropyTerm = intensityFactor / 2 + (state.stability + state.resonance) / 20 + 1;
         uint256 vitalityConstantTerm = intensityFactor / 4;
         int256 estimatedMaxVitalityChange = int256(vitalityMaxEntropyTerm) - 1 - int256(vitalityConstantTerm);
         int256 estimatedMinVitalityChange = 0 - int256(vitalityConstantTerm);

        estimatedMinVitality = _clampIntToUint(int256(state.vitality) + estimatedMinVitalityChange, 0, maxProp);
        estimatedMaxVitality = _clampIntToUint(int256(state.vitality) + estimatedMaxVitalityChange, 0, maxProp);

        return (
            estimatedMinStability, estimatedMaxStability,
            estimatedMinResonance, estimatedMaxResonance,
            estimatedMinVitality, estimatedMaxVitality
        );
    }


     /**
     * @notice Calculates the amount of decay that would be applied to a Q-State *right now*.
     * @param stateId The ID of the state.
     * @return The amount of decay to apply to each property.
     */
    function calculateDecayAmount(uint256 stateId) public view returns (uint256 decayAmount) {
        _getQuantumState(stateId); // Check existence
        QuantumStateProperties memory state = s_quantumStates[stateId]; // Use memory

        uint256 blocksSinceInteraction = block.number - state.lastInteractionBlock;
        uint256 rate = s_config.equilibriumDecayRate;

        // Simple linear decay: decayAmount = blocksSinceInteraction / rate
        // Cap decay to prevent overflow or excessive decay per call
        decayAmount = (blocksSinceInteraction > 0 && rate > 0) ? blocksSinceInteraction / rate : 0;

        // Decay is applied equally to all properties in _applyDecay example, capped by the lowest property
        uint256 minProp = state.stability;
        if (state.resonance < minProp) minProp = state.resonance;
        if (state.vitality < minProp) minProp = state.vitality;

        if (decayAmount > minProp) decayAmount = minProp; // Cannot decay below 0 for any property
        if (decayAmount > s_config.maxPropertyRange) decayAmount = s_config.maxPropertyRange; // Arbitrary cap on decay amount calculation

        return decayAmount;
    }

    /**
     * @notice Estimates the properties of a Q-State after applying decay logic for a certain number of blocks.
     * @dev Does not change state. Uses current properties and decay rate.
     * @param stateId The ID of the state.
     * @param blocksInFuture The number of blocks to simulate decay over.
     * @return Estimated stability, resonance, vitality after decay.
     */
    function predictStateDecay(uint256 stateId, uint256 blocksInFuture) public view returns (
        uint256 estimatedStability, uint256 estimatedResonance, uint256 estimatedVitality
    ) {
         _getQuantumState(stateId); // Check existence
         QuantumStateProperties memory state = s_quantumStates[stateId]; // Use memory

        uint256 rate = s_config.equilibriumDecayRate;
        uint256 decayAmountTotal = (blocksInFuture > 0 && rate > 0) ? blocksInFuture * (1 ether) / rate : 0; // Use 1 ether for potential fixed point decay logic later? Or keep simple? Simple is better for example.

        // Simple linear decay: decayAmountTotal = blocksInFuture / rate
         decayAmountTotal = (blocksInFuture > 0 && rate > 0) ? blocksInFuture / rate : 0;


        // Apply decay to each property, clamping at 0
        estimatedStability = (state.stability > decayAmountTotal) ? state.stability - decayAmountTotal : 0;
        estimatedResonance = (state.resonance > decayAmountTotal) ? state.resonance - decayAmountTotal : 0;
        estimatedVitality = (state.vitality > decayAmountTotal) ? state.vitality - decayAmountTotal : 0;

        // Ensure values are within max property range
        uint256 maxProp = s_config.maxPropertyRange;
         estimatedStability = _clamp(estimatedStability, 0, maxProp);
         estimatedResonance = _clamp(estimatedResonance, 0, maxProp);
         estimatedVitality = _clamp(estimatedVitality, 0, maxProp);


        return (estimatedStability, estimatedResonance, estimatedVitality);
    }


     /**
     * @notice Gets the current configuration parameters.
     * @return The ConfigParameters struct.
     */
    function getConfig() public view returns (ConfigParameters memory) {
        return s_config;
    }


    // --- Internal Helper Functions ---

     /**
     * @dev Internal function to mint Fluctuating Units.
     */
    function _mintFluctuationUnits(address account, uint256 amount) internal {
        // No overflow check needed for addition if amount is uint256 (max supply is effectively 2^256)
        // Could add a cap if a specific max supply is desired.
        s_fluctuationUnits[account] += amount;
        s_totalFluctuationUnits += amount;
    }

     /**
     * @dev Internal function to burn Fluctuating Units.
     */
    function _burnFluctuationUnits(address account, uint256 amount) internal {
        // Ensure burn amount doesn't exceed balance (should be handled by caller checks too)
        if (s_fluctuationUnits[account] < amount) revert QuantumFluctuations__InsufficientFunds();
        s_fluctuationUnits[account] -= amount;

         // Ensure total supply doesn't underflow (should be safe if individual burn is safe)
        if (s_totalFluctuationUnits < amount) s_totalFluctuationUnits = 0; // Should not happen with proper checks
        else s_totalFluctuationUnits -= amount;
    }

     /**
     * @dev Internal helper to retrieve QuantumStateProperties and check existence.
     */
    function _getQuantumState(uint256 stateId) internal view returns (QuantumStateProperties storage) {
        // State ID 0 is reserved (unentangled state)
        if (stateId == 0) revert QuantumFluctuations__StateNotFound(stateId);
        // Check if the state mapping entry corresponds to the ID
        if (s_quantumStates[stateId].id != stateId) {
            revert QuantumFluctuations__StateNotFound(stateId);
        }
        return s_quantumStates[stateId];
    }

     /**
     * @dev Internal function to apply decay logic to a state.
     *      Updates properties and lastInteractionBlock. Emits event.
     */
    function _applyDecay(uint256 stateId) internal {
        QuantumStateProperties storage state = _getQuantumState(stateId);

        uint256 blocksSinceInteraction = block.number - state.lastInteractionBlock;
        uint256 rate = s_config.equilibriumDecayRate;

        if (blocksSinceInteraction == 0 || rate == 0) return; // No decay needed or possible

        uint256 decayAmount = blocksSinceInteraction / rate;

        // Apply decay, clamping at 0 and capping by max property range
        uint256 maxProp = s_config.maxPropertyRange;
        uint256 oldStability = state.stability;
        uint256 oldResonance = state.resonance;
        uint256 oldVitality = state.vitality;

        state.stability = _clamp(state.stability - decayAmount, 0, maxProp);
        state.resonance = _clamp(state.resonance - decayAmount, 0, maxProp);
        state.vitality = _clamp(state.vitality - decayAmount, 0, maxProp);

        // Ensure we actually decayed something before updating block and emitting event
        if (state.stability != oldStability || state.resonance != oldResonance || state.vitality != oldVitality) {
             state.lastInteractionBlock = block.number; // Update interaction block
             emit StateDecayed(stateId, state.stability, state.resonance, state.vitality, decayAmount);
        }
    }

     /**
     * @dev Internal helper to clamp a uint256 value between min and max.
     */
    function _clamp(uint256 self, uint256 min, uint256 max) internal pure returns (uint256) {
        return self < min ? min : (self > max ? max : self);
    }

     /**
     * @dev Internal helper to clamp an int256 value between min and max and return as uint256.
     *      Handles potential negative results by returning the uint256 min (0).
     */
    function _clampIntToUint(int256 self, uint256 min, uint256 max) internal pure returns (uint256) {
        if (self < int256(min)) return min; // Handle results below 0 correctly for uint
        if (self > int256(max)) return max;
        return uint256(self);
    }
}
```

This contract provides a unique system with intertwined dynamics between fungible units, evolving non-fungible states, and a contract-internal prediction market, all driven by a pseudo-randomly fluctuating intensity parameter. It avoids duplicating standard open-source patterns by building a custom economic/state model.

**Disclaimer:**
*   **Randomness:** The internal pseudo-randomness is for demonstration purposes only. It is predictable and should *not* be used in high-value, adversarial scenarios on-chain. True randomness requires external or more sophisticated on-chain mechanisms (like VRF).
*   **Complexity:** The interaction logic (mutation, decay, entanglement, synthesis) is simplified for illustration. Real-world complex systems would require more detailed mathematical modeling.
*   **Gas:** Complex state updates and multiple interactions can consume significant gas. Optimization might be needed for a production environment.
*   **Security:** While basic Ownable/Pausable are used, this is a complex contract. A full security audit would be necessary for any production deployment.
*   **Scalability:** Storing all Q-State properties and potentially iterating over entangled links could hit gas limits with a very large number of states or complex entanglement chains. The current entanglement uses a simple one-way link which is safer.
*   **Economic Model:** The specific formulas for mutation, decay, synthesis, and intensity change are examples. Designing a balanced and sustainable in-game economy requires careful consideration and iteration.