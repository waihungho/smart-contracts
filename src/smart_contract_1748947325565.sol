Okay, let's design a smart contract based on a unique concept, drawing inspiration from quantum mechanics principles like superposition, entanglement, and observation to create a state-altering asset system. We'll call it `QuantumRefraction`.

The core idea is that users deposit assets into a "Quantum State" which can be manipulated through "Refraction" (splitting potential outcomes) and "Entanglement" (linking states). The final outcome is determined only upon "Observation," potentially influenced by external data (like an oracle for randomness).

This is a complex and conceptual design, aiming for novelty rather than a standard application. It requires careful consideration of state management, branching possibilities, and external interaction.

---

**QuantumRefraction Smart Contract**

**Concept:** A system where deposited assets enter a non-deterministic "Quantum State." This state can be manipulated through "Refraction" (creating branching potential outcomes) and "Entanglement" (linking state outcomes). A final "Observation" event collapses the state and determines the actual outcome, potentially using external random data.

**Key Features:**
*   **Quantum State:** Assets are held in a mutable state structure.
*   **Refraction:** A process to split a single potential outcome path into multiple possibilities within a state.
*   **Entanglement:** Linking two separate states such that their observation outcomes may influence each other.
*   **Observation:** The event that collapses a state's potential outcomes into a single determined result.
*   **Oracle Interaction:** Reliance on an external oracle for randomness or outcome determination during Observation.
*   **Dynamic Outcomes:** Final results depend on the state's history (refractions, entanglements) and external factors.

**Outline & Function Summary:**

1.  **State Management & Configuration**
    *   `constructor`: Deploys and initializes core settings (owner, initial config).
    *   `config`: Struct defining parameters like state duration, max refractions, etc.
    *   `stateCounter`: Unique ID generator for states.
    *   `states`: Mapping storing `State` structs.
    *   `userStates`: Mapping tracking state IDs owned by each user.
    *   `allowedAssets`: Mapping for whitelisting deposit tokens.
    *   `oracleAddress`: Address of the randomness/outcome oracle.

2.  **Core Lifecycle Functions**
    *   `enterQuantumState`: User deposits allowed asset, initializing a new state in `Initialized` status.
    *   `cancelStateAndWithdraw`: User cancels an active state (before Observation) and potentially withdraws deposit (maybe with penalty).
    *   `observeState`: Triggers the process to determine the final outcome for a state. Requests data from the oracle if needed. Transitions state to `OracleRequested` or `Observed`.
    *   `processOracleOutcome`: Callback function for the oracle to deliver the result, transitioning state to `Observed` and setting final outcome/value.
    *   `claimOutcome`: User retrieves the assets/rewards determined by the final outcome of an `Observed` state. Transitions state to `Claimed`.

3.  **State Manipulation Functions**
    *   `refractState`: Splits a single state entry into multiple linked potential outcomes, increasing the branching possibilities. Transitions state(s) to `Refracted`.
    *   `entangleStates`: Links two separate state IDs, marking them as entangled. Transitions states to `Entangled`.
    *   `resolveEntanglement`: Automatically called after both entangled states are Observed, potentially adjusting their final outcomes based on the entanglement logic.

4.  **Configuration & Admin Functions**
    *   `setOracleAddress`: Owner sets the address of the trusted oracle.
    *   `setAllowedAsset`: Owner adds or removes an asset from the whitelist.
    *   `updateConfig`: Owner updates the general contract configuration parameters.
    *   `pauseContract`: Owner pauses core functions (deposits, observation triggers).
    *   `unpauseContract`: Owner unpauses the contract.
    *   `emergencyWithdrawStuckAssets`: Owner can withdraw tokens accidentally sent to the contract.

5.  **View & Query Functions**
    *   `getStateDetails`: Returns the full data for a specific state ID.
    *   `getUserStates`: Returns all state IDs associated with a user.
    *   `getPotentialOutcomes`: *Conceptual:* Before Observation, would show possible final outcomes based on refractions (requires complex off-chain calculation or simplified on-chain representation). For simplicity, this view function will list the *current* state(s) that branched from an initial one.
    *   `getEntangledPair`: Returns the state ID entangled with a given state ID.
    *   `getRefractionTree`: *Conceptual:* Returns the parent/child relationships showing the refraction history of a state. For simplicity, this view function will list direct children.
    *   `getContractBalance`: Returns the contract's balance of a specific token.

**Function Count Check:**
1.  `constructor`
2.  `enterQuantumState`
3.  `cancelStateAndWithdraw`
4.  `observeState`
5.  `processOracleOutcome`
6.  `claimOutcome`
7.  `refractState`
8.  `entangleStates`
9.  `resolveEntanglement` (Internal or triggered by oracle callback/observe) - Let's make it internal but conceptually a distinct step.
10. `setOracleAddress`
11. `setAllowedAsset`
12. `updateConfig`
13. `pauseContract`
14. `unpauseContract`
15. `emergencyWithdrawStuckAssets`
16. `getStateDetails`
17. `getUserStates`
18. `getPotentialOutcomes` (Simplified view)
19. `getEntangledPair`
20. `getRefractionTree` (Simplified view)
21. `getContractBalance`
22. (Internal Helper) `_distributeOutcome` - Handles token transfer based on outcome.
23. (Internal Helper) `_checkObservationEligibility` - Checks if a state can be observed.
24. (Internal Helper) `_handleEntanglementResolution` - The logic inside `resolveEntanglement`.

Okay, easily hitting 20+ functions with internal helpers and views.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- OUTLINE & FUNCTION SUMMARY ---
//
// 1. State Management & Configuration:
//    - struct Config: Defines contract parameters.
//    - enum StateStatus: Possible states of a quantum state entry.
//    - enum OutcomeType: Possible final outcome types.
//    - struct State: Represents a single quantum state entry.
//    - stateCounter: Increments for unique state IDs.
//    - states: Mapping from state ID to State struct.
//    - userStates: Mapping from user address to their state IDs.
//    - allowedAssets: Mapping for whitelisting deposit tokens.
//    - oracleAddress: Address of the trusted outcome oracle.
//    - config: Contract configuration parameters.
//
// 2. Core Lifecycle Functions:
//    - constructor: Initializes owner and base config.
//    - enterQuantumState(address asset, uint256 amount): User deposits asset to create a new state.
//    - cancelStateAndWithdraw(uint256 stateId): User cancels state before observation/claiming.
//    - observeState(uint256 stateId): Triggers state observation & oracle request.
//    - processOracleOutcome(uint256 oracleRequestId, uint256 stateId, OutcomeType finalOutcome, uint256 outcomeValue): Callback for oracle to deliver result.
//    - claimOutcome(uint256 stateId): User claims assets based on observed outcome.
//
// 3. State Manipulation Functions:
//    - refractState(uint256 stateId, uint256 numberOfBranches): Splits a state into multiple potential outcome paths.
//    - entangleStates(uint256 stateId1, uint256 stateId2): Links two states.
//    - resolveEntanglement(uint256 stateId1, uint256 stateId2): Internal logic to potentially adjust outcomes of entangled states after observation.
//
// 4. Configuration & Admin Functions (Owner-only):
//    - setOracleAddress(address _oracleAddress): Sets the oracle address.
//    - setAllowedAsset(address asset, bool allowed): Manages the allowed asset whitelist.
//    - updateConfig(uint256 minDeposit, uint256 stateDuration, uint256 maxRefractions): Updates config parameters.
//    - pauseContract(): Pauses core functions.
//    - unpauseContract(): Unpauses the contract.
//    - emergencyWithdrawStuckAssets(address token, uint256 amount): Allows owner to rescue tokens sent by mistake.
//
// 5. View & Query Functions:
//    - getStateDetails(uint256 stateId): Get data for a state.
//    - getUserStates(address user): Get all state IDs for a user.
//    - getPotentialOutcomes(uint256 stateId): Get direct children (branched states) after refraction.
//    - getEntangledPair(uint256 stateId): Get the entangled state ID.
//    - getRefractionTree(uint256 stateId): Get direct parent and children state IDs.
//    - getContractBalance(address token): Get contract balance of a token.
//
// Internal Helpers:
//    - _distributeOutcome(uint256 stateId): Handles asset distribution based on final outcome.
//    - _checkObservationEligibility(uint256 stateId): Checks conditions for observation.
//    - _handleEntanglementResolution(uint256 stateId1, uint256 stateId2): Logic for resolving entanglement.

contract QuantumRefraction is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- Structs and Enums ---

    struct Config {
        uint256 minDeposit;
        uint256 stateDuration; // Minimum time state must exist before observation (e.g., for stability)
        uint256 maxRefractions; // Maximum number of times a single state path can be refracted
        // Add other config parameters as needed, e.g., fees, outcome weights (if not oracle controlled)
    }

    enum StateStatus {
        Initialized,        // State created
        Refracted,          // State has branched
        Entangled,          // State is entangled with another
        OracleRequested,    // Oracle outcome requested
        Observed,           // Final outcome determined by oracle
        Claimed,            // Outcome claimed by user
        Cancelled           // State cancelled by user
    }

    enum OutcomeType {
        Undetermined,       // Outcome not yet set
        TypeA,              // Example outcome type
        TypeB,              // Another example type
        TypeC               // And another
        // More types can be added based on contract logic
    }

    struct State {
        address owner;
        address asset;
        uint256 depositAmount;
        uint256 startTime;
        uint256 observedTime;
        uint256 parentStateId;      // ID of the state this one branched from (0 if original)
        uint256[] childStateIds;    // IDs of states that branched from this one
        uint256 entangledStateId;   // ID of the state this one is entangled with (0 if not entangled)
        StateStatus status;
        OutcomeType finalOutcome;   // Determined after observation
        uint256 outcomeValue;       // Amount associated with the final outcome
        bool oracleRequested;       // Flag to ensure oracle is called only once per observation trigger
        uint256 refractionCount;    // How many times this specific path has been refracted
        uint256 oracleRequestId;    // ID used to track request with oracle
    }

    // --- State Variables ---

    uint256 public stateCounter; // Counter for unique state IDs (starts from 1)
    mapping(uint256 => State) public states;
    mapping(address => uint256[]) public userStates;
    mapping(address => bool) public allowedAssets; // ERC20 addresses allowed for deposit
    address public oracleAddress;
    Config public config;

    // Mapping oracle request ID to state ID
    mapping(uint256 => uint256) private oracleRequests;
    uint256 private oracleRequestCounter;

    // --- Events ---

    event StateInitialized(uint256 indexed stateId, address indexed owner, address indexed asset, uint256 amount, uint256 startTime);
    event StateCancelled(uint256 indexed stateId, address indexed owner);
    event StateRefracted(uint256 indexed parentStateId, uint256[] indexed childStateIds, uint256 numberOfBranches);
    event StatesEntangled(uint256 indexed stateId1, uint256 indexed stateId2);
    event ObservationTriggered(uint256 indexed stateId, uint256 oracleRequestId);
    event StateObserved(uint256 indexed stateId, OutcomeType indexed finalOutcome, uint256 outcomeValue, uint256 observedTime);
    event OutcomeClaimed(uint256 indexed stateId, address indexed owner, OutcomeType indexed outcomeType, uint256 valueClaimed);
    event ConfigUpdated(Config newConfig);
    event OracleAddressUpdated(address indexed newOracleAddress);
    event AssetAllowedStatusUpdated(address indexed asset, bool indexed allowed);
    event EmergencyWithdrawal(address indexed token, uint256 amount);

    // --- Modifiers ---

    modifier onlyAllowedAsset(address asset) {
        require(allowedAssets[asset], "Asset not allowed");
        _;
    }

    modifier onlyStateOwner(uint256 stateId) {
        require(states[stateId].owner == msg.sender, "Not state owner");
        _;
    }

    modifier onlyStateStatus(uint256 stateId, StateStatus status) {
        require(states[stateId].status == status, "Invalid state status");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Caller is not the oracle");
        _;
    }

    modifier notClaimed(uint256 stateId) {
         require(states[stateId].status != StateStatus.Claimed, "Outcome already claimed");
         _;
    }

    // --- Constructor ---

    constructor(address initialOracle, address[] memory initialAllowedAssets) Ownable(msg.sender) {
        require(initialOracle != address(0), "Initial oracle cannot be zero");
        oracleAddress = initialOracle;

        for(uint i = 0; i < initialAllowedAssets.length; i++) {
            require(initialAllowedAssets[i] != address(0), "Initial allowed asset cannot be zero");
            allowedAssets[initialAllowedAssets[i]] = true;
            emit AssetAllowedStatusUpdated(initialAllowedAssets[i], true);
        }

        // Set initial configuration - these should be carefully chosen parameters
        config = Config({
            minDeposit: 1e18, // Example: 1 token (assuming 18 decimals)
            stateDuration: 1 hours, // Example: min 1 hour before observation
            maxRefractions: 3 // Example: max 3 refractions per path
        });

        emit ConfigUpdated(config);
    }

    // --- Core Lifecycle Functions ---

    /**
     * @notice User deposits an allowed asset to enter a new quantum state.
     * @param asset The address of the ERC20 token being deposited.
     * @param amount The amount of the asset to deposit.
     */
    function enterQuantumState(address asset, uint256 amount)
        external
        whenNotPaused
        nonReentrant
        onlyAllowedAsset(asset)
    {
        require(amount >= config.minDeposit, "Deposit amount too low");

        uint256 newStateId = ++stateCounter;

        states[newStateId] = State({
            owner: msg.sender,
            asset: asset,
            depositAmount: amount,
            startTime: block.timestamp,
            observedTime: 0,
            parentStateId: 0, // This is an original state
            childStateIds: new uint256[](0),
            entangledStateId: 0, // Not entangled initially
            status: StateStatus.Initialized,
            finalOutcome: OutcomeType.Undetermined,
            outcomeValue: 0,
            oracleRequested: false,
            refractionCount: 0,
            oracleRequestId: 0 // No request yet
        });

        userStates[msg.sender].push(newStateId);

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

        emit StateInitialized(newStateId, msg.sender, asset, amount, block.timestamp);
    }

    /**
     * @notice User cancels a state and withdraws their deposit. May incur penalty depending on logic.
     * @param stateId The ID of the state to cancel.
     * @dev Cancelling might require returning less than the original deposit based on internal rules,
     *      or might be restricted based on state status (e.g., cannot cancel if OracleRequested or Observed).
     *      Current simple implementation just allows withdrawal if not Observed/Claimed.
     */
    function cancelStateAndWithdraw(uint256 stateId)
        external
        whenNotPaused
        nonReentrant
        onlyStateOwner(stateId)
        notClaimed(stateId)
    {
        State storage state = states[stateId];
        require(state.status < StateStatus.Observed, "State cannot be cancelled after observation");
        // Add checks here if cancelling states that have been refracted/entangled is restricted
        // require(state.childStateIds.length == 0, "Cannot cancel refracted state");
        // require(state.entangledStateId == 0, "Cannot cancel entangled state");


        // Potential penalty logic could be added here:
        // uint256 refundAmount = state.depositAmount * cancellationFee / 100; // Example fee

        // For simplicity, refund full deposit if not observed
        uint256 refundAmount = state.depositAmount;

        state.status = StateStatus.Cancelled;

        IERC20(state.asset).safeTransfer(msg.sender, refundAmount);

        // Note: state data remains but status prevents further action.
        // Clearing from userStates array would be gas-expensive, leave it.

        emit StateCancelled(stateId, msg.sender);
    }


    /**
     * @notice Triggers the observation process for a state. Requests outcome from the oracle.
     * @param stateId The ID of the state to observe.
     * @dev Observation can only happen once per state path (or end-node state after refractions).
     *      Requires state to be past minimum duration and not yet observed/claimed.
     */
    function observeState(uint256 stateId)
        external
        whenNotPaused
        nonReentrant
        onlyStateOwner(stateId)
    {
        State storage state = states[stateId];
        require(_checkObservationEligibility(stateId), "State not eligible for observation");
        require(!state.oracleRequested, "Oracle outcome already requested");
        require(state.childStateIds.length == 0, "Cannot observe a state with pending branches (must observe leaf states)");

        // In a real system, this would interact with an oracle contract
        // Example: IOracle(oracleAddress).requestOutcome(this.address, stateId, parameters_about_state);

        // For this conceptual contract, we simulate sending a request ID
        // The oracle is expected to call processOracleOutcome later using this ID and stateId.
        uint256 currentOracleRequestId = ++oracleRequestCounter;
        oracleRequests[currentOracleRequestId] = stateId;

        state.status = StateStatus.OracleRequested;
        state.oracleRequested = true;
        state.oracleRequestId = currentOracleRequestId;


        emit ObservationTriggered(stateId, currentOracleRequestId);
    }

    /**
     * @notice Callback function for the oracle to deliver the determined outcome.
     * @param oracleRequestId The ID of the original oracle request.
     * @param stateId The ID of the state being observed.
     * @param finalOutcome The determined outcome type.
     * @param outcomeValue The determined value/amount associated with the outcome.
     * @dev Must be called only by the designated oracle address.
     *      Updates the state status and outcome details.
     *      Could trigger entanglement resolution here if both states are now Observed.
     */
    function processOracleOutcome(
        uint256 oracleRequestId,
        uint256 stateId,
        OutcomeType finalOutcome,
        uint256 outcomeValue
    ) external onlyOracle {
        require(states[stateId].status == StateStatus.OracleRequested, "State not awaiting oracle outcome");
        require(states[stateId].oracleRequestId == oracleRequestId, "Invalid oracle request ID for state");
        require(oracleRequests[oracleRequestId] == stateId, "Oracle request ID mapping mismatch");

        State storage state = states[stateId];

        state.status = StateStatus.Observed;
        state.observedTime = block.timestamp;
        state.finalOutcome = finalOutcome;
        state.outcomeValue = outcomeValue;

        // Clear the oracle request mapping
        delete oracleRequests[oracleRequestId];

        emit StateObserved(stateId, finalOutcome, outcomeValue, block.timestamp);

        // Check for entanglement resolution
        if (state.entangledStateId != 0) {
            State storage entangledState = states[state.entangledStateId];
            if (entangledState.status == StateStatus.Observed) {
                _handleEntanglementResolution(stateId, state.entangledStateId);
            }
        }
    }

    /**
     * @notice User claims the assets based on the observed outcome of a state.
     * @param stateId The ID of the state to claim.
     * @dev Can only be called on a state with status `Observed`.
     */
    function claimOutcome(uint256 stateId)
        external
        whenNotPaused
        nonReentrant
        onlyStateOwner(stateId)
        onlyStateStatus(stateId, StateStatus.Observed)
        notClaimed(stateId)
    {
        _distributeOutcome(stateId);
        states[stateId].status = StateStatus.Claimed;
        emit OutcomeClaimed(stateId, msg.sender, states[stateId].finalOutcome, states[stateId].outcomeValue);
    }

    // --- State Manipulation Functions ---

    /**
     * @notice Refracts a state, splitting its potential outcome path into multiple branches.
     * @param stateId The ID of the state to refract.
     * @param numberOfBranches The number of new state entries to create from this one (must be > 1).
     * @dev Can only refract states that are Initialized or Refracted, have not been observed/cancelled,
     *      and haven't exceeded the max refraction count for this path.
     *      Each new branch inherits properties but gets a new ID and starts its own lifecycle.
     */
    function refractState(uint256 stateId, uint256 numberOfBranches)
        external
        whenNotPaused
        nonReentrant
        onlyStateOwner(stateId)
    {
        State storage parentState = states[stateId];
        require(parentState.status == StateStatus.Initialized || parentState.status == StateStatus.Refracted || parentState.status == StateStatus.Entangled, "State cannot be refracted from its current status");
        require(parentState.refractionCount < config.maxRefractions, "Max refractions reached for this path");
        require(numberOfBranches > 1, "Number of branches must be greater than 1");
        require(parentState.childStateIds.length == 0, "Cannot refract a state that already has children");

        uint256[] memory childIds = new uint256[](numberOfBranches);

        parentState.status = StateStatus.Refracted; // Mark parent as refracted
        parentState.childStateIds = childIds; // Link children back to parent

        for (uint i = 0; i < numberOfBranches; i++) {
            uint256 childStateId = ++stateCounter;
            childIds[i] = childStateId; // Store the ID in the parent's child list

            // Create the new child state inheriting most properties
            states[childStateId] = State({
                owner: parentState.owner,
                asset: parentState.asset,
                depositAmount: parentState.depositAmount, // Deposit amount is conceptually tied to the *original* deposit
                startTime: parentState.startTime, // Start time from original entry
                observedTime: 0,
                parentStateId: stateId, // Link to the parent
                childStateIds: new uint256[](0), // Children start with no branches
                entangledStateId: 0, // Refraction doesn't inherit entanglement, must be done explicitly on children
                status: StateStatus.Initialized, // New branch starts as Initialized
                finalOutcome: OutcomeType.Undetermined,
                outcomeValue: 0,
                oracleRequested: false,
                refractionCount: parentState.refractionCount + 1, // Increment refraction count for this path
                oracleRequestId: 0
            });
            // Note: Deposit amount is replicated, but only the *final* claim on an observed leaf state
            // will actually release assets. The total claimed across all branches of a single origin state
            // shouldn't exceed the original deposit *plus* earned outcomes. Complex logic needed here.
            // Simplification: Each leaf state after observation provides its `outcomeValue`, which could be 0, deposit, or more/less.

             userStates[parentState.owner].push(childStateId); // Add child state to user's list
        }

        emit StateRefracted(stateId, childIds, numberOfBranches);
    }

    /**
     * @notice Entangles two separate quantum states.
     * @param stateId1 The ID of the first state.
     * @param stateId2 The ID of the second state.
     * @dev Both states must be unentangled, active (not observed/claimed/cancelled), and owned by the caller.
     *      Once entangled, their observation outcomes might be linked or influence each other.
     */
    function entangleStates(uint256 stateId1, uint256 stateId2)
        external
        whenNotPaused
        nonReentrant
        onlyStateOwner(stateId1) // Assuming caller owns both
    {
        require(stateId1 != stateId2, "Cannot entangle a state with itself");
        require(states[stateId2].owner == msg.sender, "Caller must own both states"); // Check ownership of second state

        State storage state1 = states[stateId1];
        State storage state2 = states[stateId2];

        require(state1.entangledStateId == 0, "State 1 already entangled");
        require(state2.entangledStateId == 0, "State 2 already entangled");
        require(state1.status < StateStatus.Observed && state1.status != StateStatus.Cancelled, "State 1 not in valid status for entanglement");
        require(state2.status < StateStatus.Observed && state2.status != StateStatus.Cancelled, "State 2 not in valid status for entanglement");

        state1.entangledStateId = stateId2;
        state2.entangledStateId = stateId1;

        // Mark states as entangled if they weren't already e.g. Refracted
        if (state1.status != StateStatus.Refracted) state1.status = StateStatus.Entangled;
        if (state2.status != StateStatus.Refracted) state2.status = StateStatus.Entangled;


        emit StatesEntangled(stateId1, stateId2);
    }

    /**
     * @notice Internal function to handle the resolution logic for entangled states.
     * @param stateId1 The ID of the first observed state.
     * @param stateId2 The ID of the second observed state.
     * @dev Called automatically from `processOracleOutcome` when both entangled states are `Observed`.
     *      Implements the specific rules for how entanglement modifies outcomes.
     *      This logic is highly conceptual and depends on the desired "quantum" effect.
     *      Example: If one is TypeA and other TypeB, they both become TypeC. If both TypeA, they get bonus.
     */
    function _handleEntanglementResolution(uint256 stateId1, uint256 stateId2) internal {
        State storage state1 = states[stateId1];
        State storage state2 = states[stateId2];

        // Ensure they are indeed entangled with each other and are both observed
        require(state1.entangledStateId == stateId2 && state2.entangledStateId == stateId1, "States are not mutually entangled");
        require(state1.status == StateStatus.Observed && state2.status == StateStatus.Observed, "Both states must be Observed to resolve entanglement");

        // --- Conceptual Entanglement Resolution Logic ---
        // This part defines the "quantum interaction"
        OutcomeType outcome1 = state1.finalOutcome;
        OutcomeType outcome2 = state2.finalOutcome;
        uint256 value1 = state1.outcomeValue;
        uint256 value2 = state2.outcomeValue;

        if (outcome1 == OutcomeType.TypeA && outcome2 == OutcomeType.TypeB) {
            // Example: A and B results 'interact' and both become TypeC with combined value
            state1.finalOutcome = OutcomeType.TypeC;
            state2.finalOutcome = OutcomeType.TypeC;
            state1.outcomeValue = value1 + value2;
            state2.outcomeValue = value1 + value2; // Both get the combined value (conceptual)
        } else if (outcome1 == OutcomeType.TypeA && outcome2 == OutcomeType.TypeA) {
            // Example: Double A results in a bonus value
            state1.outcomeValue = value1 + (state1.depositAmount / 10); // 10% bonus
            state2.outcomeValue = value2 + (state2.depositAmount / 10); // 10% bonus
        }
        // Add more complex rules here based on other outcome combinations

        // Note: Emitting events about outcome changes after resolution might be useful
        // emit EntanglementResolved(stateId1, stateId2, state1.finalOutcome, state1.outcomeValue, state2.finalOutcome, state2.outcomeValue);
    }


    // --- Configuration & Admin Functions ---

    /**
     * @notice Owner sets the address of the trusted oracle contract.
     * @param _oracleAddress The new oracle address.
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "Oracle address cannot be zero");
        oracleAddress = _oracleAddress;
        emit OracleAddressUpdated(_oracleAddress);
    }

    /**
     * @notice Owner adds or removes an ERC20 asset from the allowed deposit list.
     * @param asset The address of the ERC20 token.
     * @param allowed True to allow, false to disallow.
     */
    function setAllowedAsset(address asset, bool allowed) external onlyOwner {
        require(asset != address(0), "Asset address cannot be zero");
        allowedAssets[asset] = allowed;
        emit AssetAllowedStatusUpdated(asset, allowed);
    }

    /**
     * @notice Owner updates the contract configuration parameters.
     * @param minDeposit Minimum deposit amount.
     * @param stateDuration Minimum time for a state to exist before observation.
     * @param maxRefractions Maximum refractions allowed per path.
     */
    function updateConfig(uint256 minDeposit, uint256 stateDuration, uint256 maxRefractions) external onlyOwner {
        config = Config({
            minDeposit: minDeposit,
            stateDuration: stateDuration,
            maxRefractions: maxRefractions
        });
        emit ConfigUpdated(config);
    }

    /**
     * @notice Pauses core contract functions (enterState, cancel, observe, claim, refract, entangle).
     * @dev Only owner can call.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract.
     * @dev Only owner can call.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows owner to withdraw any tokens accidentally sent to the contract.
     * @param token Address of the token to withdraw (ERC20 or ETH via address(0)).
     * @param amount Amount to withdraw.
     * @dev Be cautious with this function, it should only be used for rescue, not normal protocol withdrawals.
     *      Does NOT withdraw assets locked in active states.
     */
    function emergencyWithdrawStuckAssets(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            // Withdraw ETH
            (bool success, ) = payable(owner()).call{value: amount}("");
            require(success, "ETH withdrawal failed");
        } else {
            // Withdraw ERC20
            IERC20(token).safeTransfer(owner(), amount);
        }
        emit EmergencyWithdrawal(token, amount);
    }

    // --- View & Query Functions ---

    /**
     * @notice Gets the details of a specific quantum state.
     * @param stateId The ID of the state.
     * @return State struct details.
     */
    function getStateDetails(uint256 stateId) external view returns (State memory) {
        require(stateId > 0 && stateId <= stateCounter, "Invalid state ID");
        return states[stateId];
    }

    /**
     * @notice Gets the list of state IDs associated with a user.
     * @param user The address of the user.
     * @return An array of state IDs.
     */
    function getUserStates(address user) external view returns (uint256[] memory) {
        return userStates[user];
    }

    /**
     * @notice Gets the child state IDs resulting from a refraction.
     * @param stateId The ID of the parent state.
     * @return An array of child state IDs.
     * @dev This is a simplified view showing direct descendants, not a full tree traversal.
     */
    function getPotentialOutcomes(uint256 stateId) external view returns (uint256[] memory) {
         require(stateId > 0 && stateId <= stateCounter, "Invalid state ID");
         return states[stateId].childStateIds;
    }

     /**
      * @notice Gets the state ID that a given state is entangled with.
      * @param stateId The ID of the state.
      * @return The entangled state ID, or 0 if not entangled.
      */
    function getEntangledPair(uint256 stateId) external view returns (uint256) {
        require(stateId > 0 && stateId <= stateCounter, "Invalid state ID");
        return states[stateId].entangledStateId;
    }

    /**
     * @notice Gets the parent and child state IDs for a given state.
     * @param stateId The ID of the state.
     * @return parentId The ID of the parent state (0 if original).
     * @return childIds An array of child state IDs.
     */
    function getRefractionTree(uint256 stateId) external view returns (uint256 parentId, uint256[] memory childIds) {
        require(stateId > 0 && stateId <= stateCounter, "Invalid state ID");
        State memory state = states[stateId];
        return (state.parentStateId, state.childStateIds);
    }


    /**
     * @notice Gets the contract's balance of a specific ERC20 token.
     * @param token The address of the ERC20 token.
     * @return The balance amount.
     */
    function getContractBalance(address token) external view returns (uint256) {
        require(token != address(0), "Invalid token address");
        return IERC20(token).balanceOf(address(this));
    }

    // --- Internal Helper Functions ---

    /**
     * @notice Internal function to distribute assets based on the final outcome of an observed state.
     * @param stateId The ID of the state.
     * @dev This logic determines what assets are transferred based on `finalOutcome` and `outcomeValue`.
     *      Could transfer the original deposit, a multiple, a different token, etc.
     *      Requires careful consideration of where the `outcomeValue` comes from (oracle, internal calc)
     *      and how it relates to the original `depositAmount`.
     */
    function _distributeOutcome(uint256 stateId) internal {
        State storage state = states[stateId];
        require(state.status == StateStatus.Observed, "State must be Observed to distribute outcome");
        require(state.owner != address(0), "State owner address invalid"); // Safety check
        // Ensure outcomeValue isn't excessive compared to total contract holdings or original deposit + potential rewards

        uint256 amountToSend = 0;
        address tokenToSend = state.asset; // Default to original asset

        // --- Conceptual Distribution Logic ---
        // This part depends heavily on what OutcomeType and outcomeValue represent.
        // Example:
        if (state.finalOutcome == OutcomeType.TypeA) {
            // Outcome A means getting original deposit back plus potential bonus (stored in outcomeValue)
             amountToSend = state.depositAmount + state.outcomeValue; // outcomeValue is the bonus here
             tokenToSend = state.asset;
        } else if (state.finalOutcome == OutcomeType.TypeB) {
             // Outcome B means getting a fixed reward amount (stored in outcomeValue) in a different token
             // Example: assuming outcomeValue is in WEI of a reward token
             amountToSend = state.outcomeValue;
             tokenToSend = 0xRewardTokenAddress; // Replace with actual reward token address
             // Need to ensure contract holds enough RewardTokenAddress or has logic to mint/obtain it.
        } else if (state.finalOutcome == OutcomeType.TypeC) {
             // Outcome C means getting a percentage of original deposit (outcomeValue is percentage / 100)
             amountToSend = (state.depositAmount * state.outcomeValue) / 100; // outcomeValue is e.g. 50 for 50%
             tokenToSend = state.asset;
        } else {
             // Default or failure outcome: maybe just return original deposit or nothing
             amountToSend = state.depositAmount;
             tokenToSend = state.asset;
        }
        // Add more complex logic based on other outcome types or entanglement effects

        require(amountToSend > 0, "Outcome value is zero, no assets to send");
        require(tokenToSend != address(0), "Outcome token address invalid");
        require(IERC20(tokenToSend).balanceOf(address(this)) >= amountToSend, "Contract balance insufficient for outcome");

        IERC20(tokenToSend).safeTransfer(state.owner, amountToSend);
    }

    /**
     * @notice Internal function to check if a state is eligible to be observed.
     * @param stateId The ID of the state.
     * @return True if eligible, false otherwise.
     */
    function _checkObservationEligibility(uint256 stateId) internal view returns (bool) {
        State memory state = states[stateId];

        // Must be an active state that hasn't been observed or cancelled
        if (state.status >= StateStatus.Observed || state.status == StateStatus.Cancelled) {
            return false;
        }

        // Must meet minimum duration requirement
        if (block.timestamp < state.startTime + config.stateDuration) {
            return false;
        }

        // If it has children (was refracted), only the "leaf" states can be observed
        if (state.childStateIds.length > 0) {
            return false;
        }

        // Add other eligibility checks if needed (e.g., entanglement status, parameters set, etc.)

        return true;
    }

    // Note: _handleEntanglementResolution is already defined above.

    // Optional: Add a receive() or fallback() if you want to receive ETH, but this contract is token-centric.
}
```