Okay, let's design a smart contract based on the concept of managing dynamic, time-sensitive "Flux" across different states and user alignments within a controlled environment, influenced by internal mechanics and external factors. This avoids common DeFi/NFT/DAO patterns directly and focuses on a unique simulation-like state management.

We'll call it `QuantumFluxManager`.

---

**Smart Contract Outline and Function Summary: QuantumFluxManager**

This contract simulates a system managing different types of "Flux" (abstract energy units) for users. Users accrue Flux based on time, their "Alignment" state, and the current system "Phase". Flux can decay, be transformed between types, or committed to "Conduits" for different effects. The system itself transitions through phases, affecting global parameters. An external factor can also influence dynamics.

**Core Concepts:**

1.  **Flux Types:** Multiple distinct types of Flux (e.g., Stable, Volatile, Exotic).
2.  **User Alignment:** Each user has an Alignment state (e.g., Equilibrium, Deviation) affecting their interactions.
3.  **System Phases:** The contract operates in distinct Phases (e.g., Genesis, Equilibrium, Turbulence), altering global parameters.
4.  **Time Sensitivity:** Flux generation, decay, and phase shifts are time-based.
5.  **Conduits:** Locations where users can commit Flux for specific benefits or stability.
6.  **System Energy:** A small portion of transformation costs accrues to the contract, representing system overhead/energy.
7.  **External Factor:** A parameter influenced externally (simulated Oracle feed), affecting global dynamics.

**State Variables:**

*   User Flux balances (mapping user address to struct of flux types)
*   User Alignment (mapping user address to Alignment enum)
*   User last interaction/claim time (mapping user address to uint256)
*   User committed Flux in Conduits (mapping user address to mapping conduit ID to amount)
*   Global System Phase (enum)
*   Global total supply of each Flux type
*   Phase transition parameters (durations, conditions)
*   Flux parameters (generation rates, decay rates per phase/alignment/type)
*   Conduit parameters (yield rates, capacity, accepted flux types)
*   Current External Factor value
*   Time of last Phase shift
*   System Energy balance
*   Admin/Owner address

**Functions (>= 20):**

**I. User Interaction (Flux Management)**

1.  `claimGeneratedFlux()`: Calculate and distribute accrued Flux based on time, alignment, and phase.
2.  `transformFluxStableToVolatile(amount)`: Convert Stable Flux to Volatile Flux.
3.  `transformFluxVolatileToStable(amount)`: Convert Volatile Flux to Stable Flux.
4.  `transformFluxVolatileToExotic(amount)`: Convert Volatile Flux to Exotic Flux (higher cost/risk).
5.  `transformFluxExoticToVolatile(amount)`: Convert Exotic Flux back to Volatile Flux.
6.  `commitFluxToConduit(conduitId, amount)`: Deposit Flux into a specified Conduit.
7.  `withdrawCommittedFlux(conduitId, amount)`: Withdraw Flux from a Conduit (may incur penalty).
8.  `attemptAlignmentShift()`: Attempt to change user's Alignment (costly, potentially time-gated).

**II. User Information Queries**

9.  `getUserFluxBalances(user)`: Get current balances of all Flux types for a user.
10. `getUserAlignment(user)`: Get the current Alignment state for a user.
11. `getUserCommittedFlux(user, conduitId)`: Get amount of Flux committed by a user in a specific Conduit.
12. `getUserLastInteractionTime(user)`: Get the timestamp of the user's last significant interaction.
13. `getPotentialGeneratedFlux(user)`: Calculate potential Flux accrued since last claim *without* claiming.

**III. System Information Queries**

14. `getCurrentPhase()`: Get the current global System Phase.
15. `getTotalFluxSupply()`: Get the total supply of each Flux type in the system (including user balances and committed).
16. `getFluxParameters()`: Get the current generation and decay parameters for Flux types.
17. `getConduitParameters(conduitId)`: Get parameters for a specific Conduit.
18. `getPhaseParameters(phase)`: Get the parameters associated with a specific System Phase.
19. `getTimeUntilNextPhaseShift()`: Calculate the time remaining until the next scheduled Phase transition.
20. `getExternalFactor()`: Get the current value of the external influencing factor.
21. `getSystemEnergyBalance()`: Get the total amount of System Energy accumulated.
22. `getConduitCommittedTotal(conduitId)`: Get the total amount of Flux committed across all users in a specific Conduit.

**IV. System Management (Owner/Admin)**

23. `attemptPhaseShift()`: Trigger the system to check if Phase transition criteria are met and execute if so.
24. `setExternalFactor(newValue)`: Update the value of the external influencing factor (simulating oracle update).
25. `setFluxGenerationParams(params)`: Update global Flux generation parameters (within limits).
26. `setFluxDecayParams(params)`: Update global Flux decay parameters (within limits).
27. `addConduit(id, params)`: Introduce a new Conduit type with specified parameters.
28. `removeConduit(id)`: Remove an existing Conduit type (with migration/claiming rules).
29. `withdrawSystemEnergy(amount)`: Withdraw accumulated System Energy (owner only).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title QuantumFluxManager
/// @notice A smart contract managing dynamic, time-sensitive "Flux" units across user states and system phases.
/// It simulates a complex system with generation, decay, transformation, and commitment mechanics,
/// influenced by time, user alignment, system phase, and an external factor.

/// Outline:
/// I. Data Structures (Enums, Structs)
/// II. State Variables
/// III. Events
/// IV. Modifiers
/// V. Internal Helper Functions (Core Logic: Generation, Decay, Updates, Phase calculation)
/// VI. Constructor
/// VII. User Interaction Functions (Claim, Transform, Commit, Alignment Shift)
/// VIII. User Information Query Functions
/// IX. System Information Query Functions
/// X. System Management Functions (Owner/Admin)

contract QuantumFluxManager {

    // ========================================================================================================
    // I. Data Structures
    // ========================================================================================================

    /// @dev Enum representing different types of Flux.
    enum FluxType { Stable, Volatile, Exotic }

    /// @dev Enum representing user alignment state.
    enum UserAlignment { Equilibrium, Deviation }

    /// @dev Enum representing the current system phase.
    enum SystemPhase { Genesis, Equilibrium, Turbulence, Decay }

    /// @dev Struct holding balances of each Flux type for a user or globally.
    struct FluxBalances {
        uint256 stable;
        uint256 volatile;
        uint256 exotic;
    }

    /// @dev Struct defining parameters for a specific Flux type's behavior.
    struct FluxParams {
        uint256 baseGenerationRatePerSecond; // Per unit of time for default alignment/phase
        uint256 decayRatePerSecond;          // Percentage * 1e18 per second
        uint256 alignmentBonusMultiplier;    // Multiplier * 1e18 for specific alignment
        uint256 phaseMultiplier;             // Multiplier * 1e18 applied based on phase
    }

    /// @dev Struct defining parameters for a specific System Phase.
    struct PhaseParams {
        uint256 duration; // Duration of the phase in seconds (0 for indefinite)
        // Additional phase-specific effects can be added here, e.g., transformation cost multipliers
    }

    /// @dev Struct defining parameters for a Conduit.
    struct ConduitParams {
        FluxType acceptedFluxType;    // Type of flux accepted by this conduit
        uint256 yieldRatePerSecond;   // Yield percentage * 1e18 per second for committed flux
        uint256 capacity;             // Max total flux this conduit can hold (0 for unlimited)
        uint256 withdrawalPenalty;    // Percentage * 1e18 penalty on withdrawal
        bool isActive;                // Is this conduit currently active?
    }

    // ========================================================================================================
    // II. State Variables
    // ========================================================================================================

    /// @dev The owner of the contract, with admin privileges.
    address public owner;

    /// @dev Mapping from user address to their Flux balances.
    mapping(address => FluxBalances) private userFluxBalances;

    /// @dev Mapping from user address to their current Alignment.
    mapping(address => UserAlignment) private userAlignment;

    /// @dev Mapping from user address to the timestamp of their last interaction triggering Flux updates.
    mapping(address => uint256) private userLastInteractionTime;

    /// @dev Mapping from user address to mapping from conduit ID to committed Flux amount.
    mapping(address => mapping(uint256 => uint256)) private userCommittedFlux;

    /// @dev Mapping from conduit ID to total committed Flux amount.
    mapping(uint256 => uint256) private conduitTotalCommitted;

    /// @dev Global total supply of each Flux type.
    FluxBalances private totalFluxSupply;

    /// @dev Current System Phase.
    SystemPhase private currentPhase;

    /// @dev Timestamp when the current phase began.
    uint256 private currentPhaseStartTime;

    /// @dev Mapping from FluxType to its parameters.
    mapping(FluxType => FluxParams) private fluxParameters;

    /// @dev Mapping from SystemPhase to its parameters.
    mapping(SystemPhase => PhaseParams) private phaseParameters;

    /// @dev Mapping from conduit ID to its parameters.
    mapping(uint256 => ConduitParams) private conduitParameters;

    /// @dev Counter for assigning unique conduit IDs.
    uint256 private nextConduitId = 1;

    /// @dev A value representing an external factor influencing dynamics (e.g., temperature, market volatility).
    /// Simulated oracle feed, updated by owner. Value scaled by 1e18.
    uint256 public externalFactor = 1e18; // Default 1.0

    /// @dev Accumulated System Energy from transformation costs.
    uint256 private systemEnergyBalance;

    /// @dev Cooldown period in seconds for attempting an Alignment shift.
    uint256 public alignmentShiftCooldown = 7 days;

    /// @dev Mapping from user address to the timestamp of their last Alignment shift attempt.
    mapping(address => uint256) private userLastAlignmentShiftAttempt;

    // ========================================================================================================
    // III. Events
    // ========================================================================================================

    /// @dev Emitted when a user claims generated Flux.
    /// @param user The user who claimed.
    /// @param stableGained Amount of Stable Flux gained.
    /// @param volatileGained Amount of Volatile Flux gained.
    /// @param exoticGained Amount of Exotic Flux gained.
    event FluxClaimed(address indexed user, uint256 stableGained, uint256 volatileGained, uint256 exoticGained);

    /// @dev Emitted when a user transforms Flux.
    /// @param user The user who transformed.
    /// @param fromType The type of Flux consumed.
    /// @param toType The type of Flux produced.
    /// @param amountIn Amount of Flux consumed.
    /// @param amountOut Amount of Flux produced.
    event FluxTransformed(address indexed user, FluxType fromType, FluxType toType, uint256 amountIn, uint256 amountOut);

    /// @dev Emitted when a user commits Flux to a Conduit.
    /// @param user The user who committed.
    /// @param conduitId The ID of the Conduit.
    /// @param amount Amount of Flux committed.
    event FluxCommitted(address indexed user, uint256 indexed conduitId, uint256 amount);

    /// @dev Emitted when a user withdraws Flux from a Conduit.
    /// @param user The user who withdrew.
    /// @param conduitId The ID of the Conduit.
    /// @param amount Amount of Flux withdrawn.
    /// @param penalty Amount of Flux lost due to penalty.
    event FluxWithdrawn(address indexed user, uint256 indexed conduitId, uint256 amount, uint256 penalty);

    /// @dev Emitted when a user's Alignment shifts.
    /// @param user The user whose Alignment shifted.
    /// @param fromAlignment The previous Alignment.
    /// @param toAlignment The new Alignment.
    event AlignmentShifted(address indexed user, UserAlignment fromAlignment, UserAlignment toAlignment);

    /// @dev Emitted when the System Phase changes.
    /// @param fromPhase The previous Phase.
    /// @param toPhase The new Phase.
    /// @param startTime The timestamp when the new Phase began.
    event PhaseShifted(SystemPhase fromPhase, SystemPhase toPhase, uint256 startTime);

    /// @dev Emitted when the External Factor is updated.
    /// @param oldValue The previous value.
    /// @param newValue The new value.
    event ExternalFactorUpdated(uint256 oldValue, uint256 newValue);

    /// @dev Emitted when System Energy is withdrawn by the owner.
    /// @param recipient The address receiving the energy.
    /// @param amount Amount of System Energy withdrawn.
    event SystemEnergyWithdrawn(address indexed recipient, uint256 amount);

    // ========================================================================================================
    // IV. Modifiers
    // ========================================================================================================

    /// @dev Modifier to restrict function access to the contract owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "QFM: Only owner can call this function");
        _;
    }

    // ========================================================================================================
    // V. Internal Helper Functions
    // ========================================================================================================

    /// @dev Internal function to ensure user's Flux balances are updated based on time passed.
    /// Applies generation and decay effects.
    /// @param user The user address to update.
    function _updateUserFlux(address user) internal {
        uint256 currentTime = block.timestamp;
        uint256 lastTime = userLastInteractionTime[user];
        if (lastTime == 0) { // First interaction
            userLastInteractionTime[user] = currentTime;
            // No flux generated or decayed before first interaction
            return;
        }

        uint256 timeElapsed = currentTime - lastTime;
        if (timeElapsed == 0) {
            return; // No time has passed
        }

        FluxBalances storage balances = userFluxBalances[user];
        UserAlignment alignment = userAlignment[user];
        SystemPhase phase = _calculateCurrentPhase(); // Get potentially new phase

        // Apply Generation and Decay for each Flux type
        for (uint i = 0; i < uint(FluxType.Exotic) + 1; i++) {
            FluxType fluxType = FluxType(i);
            FluxParams storage params = fluxParameters[fluxType];

            // Generation
            uint256 generated = _generateFlux(timeElapsed, params, alignment, phase);
            if (generated > 0) {
                if (fluxType == FluxType.Stable) balances.stable += generated;
                else if (fluxType == FluxType.Volatile) balances.volatile += generated;
                else if (fluxType == FluxType.Exotic) balances.exotic += generated;
                totalFluxSupply = _addFluxBalances(totalFluxSupply, FluxBalances({
                    stable: fluxType == FluxType.Stable ? generated : 0,
                    volatile: fluxType == FluxType.Volatile ? generated : 0,
                    exotic: fluxType == FluxType.Exotic ? generated : 0
                }));
            }

            // Decay (Apply only to *uncommitted* flux)
            uint256 currentBalance;
             if (fluxType == FluxType.Stable) currentBalance = balances.stable;
             else if (fluxType == FluxType.Volatile) currentBalance = balances.volatile;
             else currentBalance = balances.exotic; // Exotic

            if (currentBalance > 0 && params.decayRatePerSecond > 0) {
                // Decay is proportional to current balance and decay rate, influenced by external factor
                // decay = balance * decayRate * timeElapsed * externalFactor / 1e18 / 1e18
                uint256 decayAmount = (currentBalance * params.decayRatePerSecond / 1e18) * timeElapsed / 1e18;
                decayAmount = decayAmount * externalFactor / 1e18; // Apply external factor

                if (decayAmount > currentBalance) decayAmount = currentBalance; // Cap decay at current balance

                if (decayAmount > 0) {
                     if (fluxType == FluxType.Stable) balances.stable -= decayAmount;
                     else if (fluxType == FluxType.Volatile) balances.volatile -= decayAmount;
                     else balances.exotic -= decayAmount; // Exotic

                    totalFluxSupply = _subtractFluxBalances(totalFluxSupply, FluxBalances({
                         stable: fluxType == FluxType.Stable ? decayAmount : 0,
                         volatile: fluxType == FluxType.Volatile ? decayAmount : 0,
                         exotic: fluxType == FluxType.Exotic ? decayAmount : 0
                     }));
                }
            }
        }

        // Update last interaction time *after* calculations
        userLastInteractionTime[user] = currentTime;
    }

    /// @dev Internal function to calculate generated Flux for a user based on parameters.
    /// @param timeElapsed Time passed since last update.
    /// @param params Flux parameters for the specific type.
    /// @param alignment User's current Alignment.
    /// @param phase Current System Phase.
    /// @return The amount of Flux generated.
    function _generateFlux(uint256 timeElapsed, FluxParams storage params, UserAlignment alignment, SystemPhase phase) internal view returns (uint256) {
        // Generation = timeElapsed * baseRate * alignmentMultiplier * phaseMultiplier * externalFactor / 1e18 / 1e18 / 1e18
        uint256 baseGeneration = timeElapsed * params.baseGenerationRatePerSecond;
        uint256 alignmentMultiplier = (alignment == UserAlignment.Equilibrium && params.alignmentBonusMultiplier > 0)
                                      ? params.alignmentBonusMultiplier : 1e18; // Assume bonus is for Equilibrium
        uint256 phaseMultiplier = params.phaseMultiplier > 0 ? params.phaseMultiplier : 1e18; // Assume 1.0 multiplier if not set

        uint256 generated = baseGeneration * alignmentMultiplier / 1e18;
        generated = generated * phaseMultiplier / 1e18;
        generated = generated * externalFactor / 1e18; // Apply external factor

        return generated;
    }

    /// @dev Internal function to calculate the current System Phase based on time.
    /// @return The current System Phase.
    function _calculateCurrentPhase() internal view returns (SystemPhase) {
        uint256 timeInCurrentCycle = block.timestamp - currentPhaseStartTime;
        SystemPhase current = currentPhase;

        // Simple sequential phase cycle for this example
        // Genesis -> Equilibrium -> Turbulence -> Decay -> Genesis -> ...
        // If current phase duration is set and has passed, advance phase
        if (phaseParameters[current].duration > 0 && timeInCurrentCycle >= phaseParameters[current].duration) {
             if (current == SystemPhase.Genesis) return SystemPhase.Equilibrium;
             else if (current == SystemPhase.Equilibrium) return SystemPhase.Turbulence;
             else if (current == SystemPhase.Turbulence) return SystemPhase.Decay;
             else return SystemPhase.Genesis; // Cycle back from Decay
        }
        return current;
    }

    /// @dev Internal function to execute a phase transition if criteria are met.
    function _performPhaseShift() internal {
        SystemPhase nextPhase = _calculateCurrentPhase();
        if (nextPhase != currentPhase) {
            SystemPhase oldPhase = currentPhase;
            currentPhase = nextPhase;
            currentPhaseStartTime = block.timestamp;
            emit PhaseShifted(oldPhase, currentPhase, currentPhaseStartTime);
        }
    }

    /// @dev Internal function to add FluxBalances structs.
    function _addFluxBalances(FluxBalances a, FluxBalances b) internal pure returns (FluxBalances) {
        return FluxBalances({
            stable: a.stable + b.stable,
            volatile: a.volatile + b.volatile,
            exotic: a.exotic + b.exotic
        });
    }

    /// @dev Internal function to subtract FluxBalances structs. Safe against underflow assumed by checks elsewhere.
    function _subtractFluxBalances(FluxBalances a, FluxBalances b) internal pure returns (FluxBalances) {
         // Use unchecked for subtraction where safety is guaranteed by prior checks
        unchecked {
             return FluxBalances({
                 stable: a.stable - b.stable,
                 volatile: a.volatile - b.volatile,
                 exotic: a.exotic - b.exotic
             });
        }
    }

    // ========================================================================================================
    // VI. Constructor
    // ========================================================================================================

    /// @notice Initializes the contract with initial parameters and sets the owner.
    /// @param initialFluxParams Array of initial parameters for each Flux type.
    /// @param initialPhaseParams Array of initial parameters for each System Phase.
    constructor(FluxParams[3] memory initialFluxParams, PhaseParams[4] memory initialPhaseParams) {
        owner = msg.sender;
        currentPhase = SystemPhase.Genesis;
        currentPhaseStartTime = block.timestamp;
        totalFluxSupply = FluxBalances({stable: 0, volatile: 0, exotic: 0});
        systemEnergyBalance = 0;

        // Set initial flux parameters
        fluxParameters[FluxType.Stable] = initialFluxParams[0];
        fluxParameters[FluxType.Volatile] = initialFluxParams[1];
        fluxParameters[FluxType.Exotic] = initialFluxParams[2];

        // Set initial phase parameters
        phaseParameters[SystemPhase.Genesis] = initialPhaseParams[0];
        phaseParameters[SystemPhase.Equilibrium] = initialPhaseParams[1];
        phaseParameters[SystemPhase.Turbulence] = initialPhaseParams[2];
        phaseParameters[SystemPhase.Decay] = initialPhaseParams[3];

        // Set default alignment for initial users (they start in Equilibrium)
        // This is implicitly handled: new users will have alignment mapping return default 0 (Equilibrium)
        // until they attempt a shift.
    }

    // ========================================================================================================
    // VII. User Interaction Functions
    // ========================================================================================================

    /// @notice Allows a user to claim accumulated Flux.
    /// Updates user's balances and applies generation/decay.
    function claimGeneratedFlux() external {
        _updateUserFlux(msg.sender); // This helper calculates and updates based on time
        FluxBalances memory claimed = userFluxBalances[msg.sender]; // Balances after update are the "claimed" state
        // Note: This current implementation of _updateUserFlux *directly* modifies balances.
        // A more granular approach could calculate *only* generation/decay since last claim,
        // add/subtract that, and emit events specifically for generated/decayed amounts.
        // For simplicity here, _updateUserFlux performs the full state update.
        emit FluxClaimed(msg.sender, claimed.stable, claimed.volatile, claimed.exotic); // Emitting post-update balance is simpler
    }

    /// @notice Transforms Stable Flux into Volatile Flux.
    /// @param amount Amount of Stable Flux to transform.
    function transformFluxStableToVolatile(uint256 amount) external {
        _updateUserFlux(msg.sender); // Update state before transformation
        require(userFluxBalances[msg.sender].stable >= amount, "QFM: Insufficient Stable Flux");

        // Example transformation rate and cost (can be made phase/alignment/externalFactor dependent)
        uint256 volatileProduced = amount * 80 / 100; // 80% efficiency
        uint256 systemEnergyCost = amount * 5 / 100; // 5% cost to system

        require(userFluxBalances[msg.sender].stable >= amount + systemEnergyCost, "QFM: Insufficient Stable Flux for amount and energy cost");

        userFluxBalances[msg.sender].stable -= (amount + systemEnergyCost);
        userFluxBalances[msg.sender].volatile += volatileProduced;
        systemEnergyBalance += systemEnergyCost;

        totalFluxSupply = _subtractFluxBalances(totalFluxSupply, FluxBalances({stable: amount + systemEnergyCost, volatile: 0, exotic: 0}));
        totalFluxSupply = _addFluxBalances(totalFluxSupply, FluxBalances({stable: 0, volatile: volatileProduced, exotic: 0}));
        // Note: systemEnergyBalance is tracked separately and doesn't count towards totalFluxSupply

        emit FluxTransformed(msg.sender, FluxType.Stable, FluxType.Volatile, amount, volatileProduced);
    }

    /// @notice Transforms Volatile Flux into Stable Flux.
    /// @param amount Amount of Volatile Flux to transform.
    function transformFluxVolatileToStable(uint256 amount) external {
         _updateUserFlux(msg.sender);
         require(userFluxBalances[msg.sender].volatile >= amount, "QFM: Insufficient Volatile Flux");

         // Example transformation rate and cost
         uint256 stableProduced = amount * 90 / 100; // 90% efficiency
         uint256 systemEnergyCost = amount * 3 / 100; // 3% cost to system

         require(userFluxBalances[msg.sender].volatile >= amount + systemEnergyCost, "QFM: Insufficient Volatile Flux for amount and energy cost");

         userFluxBalances[msg.sender].volatile -= (amount + systemEnergyCost);
         userFluxBalances[msg.sender].stable += stableProduced;
         systemEnergyBalance += systemEnergyCost;

         totalFluxSupply = _subtractFluxBalances(totalFluxSupply, FluxBalances({stable: 0, volatile: amount + systemEnergyCost, exotic: 0}));
         totalFluxSupply = _addFluxBalances(totalFluxSupply, FluxBalances({stable: stableProduced, volatile: 0, exotic: 0}));

         emit FluxTransformed(msg.sender, FluxType.Volatile, FluxType.Stable, amount, stableProduced);
    }

    /// @notice Transforms Volatile Flux into Exotic Flux.
    /// Requires specific conditions (e.g., high External Factor, specific Phase).
    /// @param amount Amount of Volatile Flux to transform.
    function transformFluxVolatileToExotic(uint256 amount) external {
         _updateUserFlux(msg.sender);
         require(userFluxBalances[msg.sender].volatile >= amount, "QFM: Insufficient Volatile Flux");

         // Example conditions: Requires Turbulence phase and high external factor (>1.5)
         require(currentPhase == SystemPhase.Turbulence, "QFM: Requires Turbulence Phase for Volatile to Exotic");
         require(externalFactor > 1.5 ether, "QFM: Requires high External Factor (>1.5)"); // 1.5 scaled by 1e18

         // Example transformation rate and cost (less efficient, higher energy cost)
         uint256 exoticProduced = amount * 60 / 100; // 60% efficiency
         uint256 systemEnergyCost = amount * 8 / 100; // 8% cost to system

         require(userFluxBalances[msg.sender].volatile >= amount + systemEnergyCost, "QFM: Insufficient Volatile Flux for amount and energy cost");

         userFluxBalances[msg.sender].volatile -= (amount + systemEnergyCost);
         userFluxBalances[msg.sender].exotic += exoticProduced;
         systemEnergyBalance += systemEnergyCost;

         totalFluxSupply = _subtractFluxBalances(totalFluxSupply, FluxBalances({stable: 0, volatile: amount + systemEnergyCost, exotic: 0}));
         totalFluxSupply = _addFluxBalances(totalFluxSupply, FluxBalances({stable: 0, volatile: 0, exotic: exoticProduced}));

         emit FluxTransformed(msg.sender, FluxType.Volatile, FluxType.Exotic, amount, exoticProduced);
    }

     /// @notice Transforms Exotic Flux into Volatile Flux.
     /// Less efficient than Volatile to Stable.
     /// @param amount Amount of Exotic Flux to transform.
     function transformFluxExoticToVolatile(uint256 amount) external {
          _updateUserFlux(msg.sender);
          require(userFluxBalances[msg.sender].exotic >= amount, "QFM: Insufficient Exotic Flux");

          // Example transformation rate and cost
          uint256 volatileProduced = amount * 70 / 100; // 70% efficiency
          uint256 systemEnergyCost = amount * 4 / 100; // 4% cost to system

          require(userFluxBalances[msg.sender].exotic >= amount + systemEnergyCost, "QFM: Insufficient Exotic Flux for amount and energy cost");

          userFluxBalances[msg.sender].exotic -= (amount + systemEnergyCost);
          userFluxBalances[msg.sender].volatile += volatileProduced;
          systemEnergyBalance += systemEnergyCost;

          totalFluxSupply = _subtractFluxBalances(totalFluxSupply, FluxBalances({stable: 0, volatile: 0, exotic: amount + systemEnergyCost}));
          totalFluxSupply = _addFluxBalances(totalFluxSupply, FluxBalances({stable: 0, volatile: volatileProduced, exotic: 0}));

          emit FluxTransformed(msg.sender, FluxType.Exotic, FluxType.Volatile, amount, volatileProduced);
     }


    /// @notice Commits a specific amount of Flux to a Conduit. Committed Flux does not decay but may yield.
    /// @param conduitId The ID of the Conduit.
    /// @param amount The amount of Flux to commit.
    function commitFluxToConduit(uint256 conduitId, uint256 amount) external {
        _updateUserFlux(msg.sender); // Update state before committing
        ConduitParams storage params = conduitParameters[conduitId];
        require(params.isActive, "QFM: Conduit is not active");
        require(amount > 0, "QFM: Amount must be greater than zero");

        FluxType acceptedType = params.acceptedFluxType;
        uint256 currentBalance;
        if (acceptedType == FluxType.Stable) currentBalance = userFluxBalances[msg.sender].stable;
        else if (acceptedType == FluxType.Volatile) currentBalance = userFluxBalances[msg.sender].volatile;
        else currentBalance = userFluxBalances[msg.sender].exotic;

        require(currentBalance >= amount, "QFM: Insufficient Flux of accepted type");

        uint256 currentConduitTotal = conduitTotalCommitted[conduitId];
        if (params.capacity > 0) {
             require(currentConduitTotal + amount <= params.capacity, "QFM: Conduit capacity reached");
        }

        // Deduct from user's main balance
        if (acceptedType == FluxType.Stable) userFluxBalances[msg.sender].stable -= amount;
        else if (acceptedType == FluxType.Volatile) userFluxBalances[msg.sender].volatile -= amount;
        else userFluxBalances[msg.sender].exotic -= amount;

        // Add to user's committed balance and total committed
        userCommittedFlux[msg.sender][conduitId] += amount;
        conduitTotalCommitted[conduitId] += amount;

        // Total supply remains the same, it just moves location internally

        emit FluxCommitted(msg.sender, conduitId, amount);
    }

    /// @notice Withdraws a specific amount of Flux from a Conduit. May incur a penalty.
    /// @param conduitId The ID of the Conduit.
    /// @param amount The amount of Flux to withdraw.
    function withdrawCommittedFlux(uint256 conduitId, uint256 amount) external {
        _updateUserFlux(msg.sender); // Update state before withdrawing (though committed flux doesn't decay, this updates main balances)
        ConduitParams storage params = conduitParameters[conduitId];
        require(params.isActive, "QFM: Conduit is not active");
        require(amount > 0, "QFM: Amount must be greater than zero");
        require(userCommittedFlux[msg.sender][conduitId] >= amount, "QFM: Insufficient committed Flux in this Conduit");

        // Calculate penalty
        uint256 penaltyAmount = (amount * params.withdrawalPenalty) / 1e18;
        uint256 receivedAmount = amount - penaltyAmount;

        // Deduct from user's committed balance and total committed
        userCommittedFlux[msg.sender][conduitId] -= amount;
        conduitTotalCommitted[conduitId] -= amount;

        // Add to user's main balance
        FluxType acceptedType = params.acceptedFluxType;
        if (acceptedType == FluxType.Stable) userFluxBalances[msg.sender].stable += receivedAmount;
        else if (acceptedType == FluxType.Volatile) userFluxBalances[msg.sender].volatile += receivedAmount;
        else userFluxBalances[msg.sender].exotic += receivedAmount;

        // Penalty is lost from total supply
        if (penaltyAmount > 0) {
            totalFluxSupply = _subtractFluxBalances(totalFluxSupply, FluxBalances({
                stable: acceptedType == FluxType.Stable ? penaltyAmount : 0,
                volatile: acceptedType == FluxType.Volatile ? penaltyAmount : 0,
                exotic: acceptedType == FluxType.Exotic ? penaltyAmount : 0
            }));
            // The penalty goes out of the system entirely, not to system energy or owner
        }

        emit FluxWithdrawn(msg.sender, conduitId, amount, penaltyAmount);
    }

    /// @notice Attempts to shift the user's Alignment. Has a cooldown and potentially conditions.
    /// @dev In this example, shifting costs some Volatile Flux and has a cooldown.
    function attemptAlignmentShift() external {
        _updateUserFlux(msg.sender); // Update state before checking costs
        uint256 currentTime = block.timestamp;
        uint256 lastAttemptTime = userLastAlignmentShiftAttempt[msg.sender];

        require(currentTime >= lastAttemptTime + alignmentShiftCooldown, "QFM: Alignment shift is on cooldown");

        // Example cost: 100 Volatile Flux
        uint256 cost = 100 * 1e18; // Assume 18 decimals for Flux units
        require(userFluxBalances[msg.sender].volatile >= cost, "QFM: Insufficient Volatile Flux to attempt shift");

        userFluxBalances[msg.sender].volatile -= cost;
        userLastAlignmentShiftAttempt[msg.sender] = currentTime;

        // Simple shift logic: Toggle between Equilibrium and Deviation
        UserAlignment oldAlignment = userAlignment[msg.sender];
        UserAlignment newAlignment = (oldAlignment == UserAlignment.Equilibrium)
                                       ? UserAlignment.Deviation : UserAlignment.Equilibrium;
        userAlignment[msg.sender] = newAlignment;

        // Penalty cost is removed from total supply
        totalFluxSupply = _subtractFluxBalances(totalFluxSupply, FluxBalances({stable: 0, volatile: cost, exotic: 0}));

        emit AlignmentShifted(msg.sender, oldAlignment, newAlignment);
    }

    // ========================================================================================================
    // VIII. User Information Query Functions
    // ========================================================================================================

    /// @notice Gets the current Flux balances for a specific user.
    /// @param user The user address.
    /// @return A FluxBalances struct containing the user's balances.
    function getUserFluxBalances(address user) external view returns (FluxBalances memory) {
        // Note: This view function doesn't trigger _updateUserFlux. Balances might be outdated
        // until the user or system triggers an update (e.g., via claimGeneratedFlux).
        return userFluxBalances[user];
    }

    /// @notice Gets the current Alignment state for a specific user.
    /// @param user The user address.
    /// @return The user's current UserAlignment.
    function getUserAlignment(address user) external view returns (UserAlignment) {
        return userAlignment[user];
    }

    /// @notice Gets the amount of Flux committed by a user in a specific Conduit.
    /// @param user The user address.
    /// @param conduitId The ID of the Conduit.
    /// @return The amount of Flux committed.
    function getUserCommittedFlux(address user, uint256 conduitId) external view returns (uint256) {
        return userCommittedFlux[user][conduitId];
    }

    /// @notice Gets the timestamp of a user's last interaction that updated their Flux state.
    /// @param user The user address.
    /// @return The timestamp of the last interaction.
    function getUserLastInteractionTime(address user) external view returns (uint256) {
        return userLastInteractionTime[user];
    }

     /// @notice Calculates the potential Flux a user would generate if they claimed now.
     /// Does NOT modify state.
     /// @param user The user address.
     /// @return A FluxBalances struct with potential generated amounts.
     function getPotentialGeneratedFlux(address user) external view returns (FluxBalances memory) {
         uint256 currentTime = block.timestamp;
         uint256 lastTime = userLastInteractionTime[user];
         if (lastTime == 0 || currentTime <= lastTime) {
             return FluxBalances({stable: 0, volatile: 0, exotic: 0});
         }

         uint256 timeElapsed = currentTime - lastTime;
         UserAlignment alignment = userAlignment[user];
         SystemPhase phase = _calculateCurrentPhase();

         FluxBalances memory potential;
         for (uint i = 0; i < uint(FluxType.Exotic) + 1; i++) {
             FluxType fluxType = FluxType(i);
             FluxParams storage params = fluxParameters[fluxType];
             uint256 generated = _generateFlux(timeElapsed, params, alignment, phase);

             if (fluxType == FluxType.Stable) potential.stable = generated;
             else if (fluxType == FluxType.Volatile) potential.volatile = generated;
             else potential.exotic = generated;
         }
         // Note: This does *not* account for decay on existing balance during this period.
         // It only shows the *generated* amount. A full "what if I updated now" would need to
         // simulate decay too, which is more complex in a pure view function.
         return potential;
     }


    // ========================================================================================================
    // IX. System Information Query Functions
    // ========================================================================================================

    /// @notice Gets the current global System Phase.
    /// @return The current SystemPhase.
    function getCurrentPhase() external view returns (SystemPhase) {
        return _calculateCurrentPhase(); // Always return the phase based on current time
    }

    /// @notice Gets the total supply of each Flux type across the system (user balances + committed).
    /// @return A FluxBalances struct with total supplies.
    function getTotalFluxSupply() external view returns (FluxBalances memory) {
        // Note: This total supply count doesn't include System Energy, which is separate.
        // It also doesn't actively update all user balances before summing. A truly real-time total
        // would be gas-prohibitive. This reflects the sum of balances at their last update times.
        return totalFluxSupply;
    }

    /// @notice Gets the current parameters for all Flux types.
    /// @return An array of FluxParams structs.
    function getFluxParameters() external view returns (FluxParams[3] memory) {
        FluxParams[3] memory params;
        params[0] = fluxParameters[FluxType.Stable];
        params[1] = fluxParameters[FluxType.Volatile];
        params[2] = fluxParameters[FluxType.Exotic];
        return params;
    }

    /// @notice Gets the parameters for a specific Conduit ID.
    /// @param conduitId The ID of the Conduit.
    /// @return A ConduitParams struct.
    function getConduitParameters(uint256 conduitId) external view returns (ConduitParams memory) {
        require(conduitParameters[conduitId].isActive || conduitTotalCommitted[conduitId] > 0, "QFM: Conduit does not exist or is inactive");
        return conduitParameters[conduitId];
    }

    /// @notice Gets the parameters for a specific System Phase.
    /// @param phase The SystemPhase enum value.
    /// @return A PhaseParams struct.
    function getPhaseParameters(SystemPhase phase) external view returns (PhaseParams memory) {
         return phaseParameters[phase];
    }

    /// @notice Calculates the time remaining until the next scheduled Phase transition based on duration.
    /// Returns 0 if the current phase duration is infinite (0) or has already passed.
    /// @return The time remaining in seconds.
    function getTimeUntilNextPhaseShift() external view returns (uint256) {
        uint256 timeInCurrent = block.timestamp - currentPhaseStartTime;
        uint256 duration = phaseParameters[currentPhase].duration;

        if (duration == 0 || timeInCurrent >= duration) {
            return 0; // Infinite duration or already passed
        }
        return duration - timeInCurrent;
    }

     /// @notice Checks if a specific Flux transformation is currently possible for a user.
     /// Does not check amount, only global/user conditions (Phase, Alignment, External Factor).
     /// @param user The user address.
     /// @param fromType The source Flux type.
     /// @param toType The target Flux type.
     /// @return True if the transformation is possible based on conditions, false otherwise.
     function canTransformFlux(address user, FluxType fromType, FluxType toType) external view returns (bool) {
         // Basic check: transformations require the specific functions to exist and have conditions
         // This view function provides a high-level capability check.
         if (fromType == FluxType.Stable && toType == FluxType.Volatile) return true; // Always possible (base transform)
         if (fromType == FluxType.Volatile && toType == FluxType.Stable) return true; // Always possible (base transform)
         if (fromType == FluxType.Volatile && toType == FluxType.Exotic) {
              // Check conditions from transformFluxVolatileToExotic
              return _calculateCurrentPhase() == SystemPhase.Turbulence && externalFactor > 1.5 ether;
         }
         if (fromType == FluxType.Exotic && toType == FluxType.Volatile) return true; // Always possible (base transform)

         // Add checks for other potential transformations if they were implemented
         return false;
     }

     /// @notice Gets the total amount of Flux committed across all users in a specific Conduit.
     /// @param conduitId The ID of the Conduit.
     /// @return The total committed amount.
     function getConduitCommittedTotal(uint256 conduitId) external view returns (uint256) {
         return conduitTotalCommitted[conduitId];
     }


    // ========================================================================================================
    // X. System Management Functions (Owner/Admin)
    // ========================================================================================================

    /// @notice Attempts to advance the System Phase if the duration for the current phase has passed.
    /// Can be called by anyone, but only results in a phase shift if timing criteria are met.
    function attemptPhaseShift() external {
        _performPhaseShift();
    }

    /// @notice Allows the owner to set the External Factor value.
    /// @param newValue The new value for the External Factor (scaled by 1e18).
    function setExternalFactor(uint256 newValue) external onlyOwner {
        uint256 oldValue = externalFactor;
        externalFactor = newValue;
        emit ExternalFactorUpdated(oldValue, newValue);
    }

    /// @notice Allows the owner to set global Flux generation parameters for a specific type.
    /// @param fluxType The FluxType to update.
    /// @param params The new FluxParams.
    function setFluxGenerationParams(FluxType fluxType, FluxParams memory params) external onlyOwner {
        // Basic validation: Ensure multipliers are reasonable (e.g., not excessively high)
        require(params.alignmentBonusMultiplier < 100e18, "QFM: Multiplier too high"); // Example limit 100x
        require(params.phaseMultiplier < 100e18, "QFM: Multiplier too high"); // Example limit 100x
        require(params.baseGenerationRatePerSecond > 0, "QFM: Generation rate must be positive");

        fluxParameters[fluxType].baseGenerationRatePerSecond = params.baseGenerationRatePerSecond;
        fluxParameters[fluxType].alignmentBonusMultiplier = params.alignmentBonusMultiplier;
        fluxParameters[fluxType].phaseMultiplier = params.phaseMultiplier;
        // Decay rate is set separately below
    }

     /// @notice Allows the owner to set global Flux decay parameters for a specific type.
     /// @param fluxType The FluxType to update.
     /// @param params The new FluxParams (specifically decayRatePerSecond).
     function setFluxDecayParams(FluxType fluxType, FluxParams memory params) external onlyOwner {
         // Basic validation: Ensure decay rate is not negative (uint) or excessively high (>100%)
         require(params.decayRatePerSecond <= 1e18, "QFM: Decay rate cannot be more than 100%"); // Max 100% per second is extreme

         fluxParameters[fluxType].decayRatePerSecond = params.decayRatePerSecond;
     }


    /// @notice Allows the owner to add a new Conduit type.
    /// @param conduitId The unique ID for the new Conduit.
    /// @param params The parameters for the new Conduit.
    function addConduit(uint256 conduitId, ConduitParams memory params) external onlyOwner {
        require(conduitId > 0, "QFM: Conduit ID must be greater than zero");
        require(!conduitParameters[conduitId].isActive, "QFM: Conduit ID already exists");
        require(params.yieldRatePerSecond <= 1e18, "QFM: Yield rate cannot be more than 100%"); // Max 100% per second is extreme
        require(params.withdrawalPenalty <= 1e18, "QFM: Penalty cannot be more than 100%");

        conduitParameters[conduitId] = params;
        conduitParameters[conduitId].isActive = true; // Ensure it's active upon adding
        if (conduitId >= nextConduitId) {
             nextConduitId = conduitId + 1; // Keep track of the next potential ID
        }
    }

    /// @notice Allows the owner to remove a Conduit type.
    /// Users must withdraw committed flux before removal is complete (or withdrawal becomes unavailable).
    /// Setting isActive to false disables further commits/withdrawals (or owner handles forced withdrawal).
    /// @param conduitId The ID of the Conduit to remove.
    function removeConduit(uint256 conduitId) external onlyOwner {
         require(conduitParameters[conduitId].isActive, "QFM: Conduit is not active");
         // In a real system, you might require conduitTotalCommitted[conduitId] == 0
         // Or implement a forced withdrawal mechanism. For this example, we just deactivate.
         conduitParameters[conduitId].isActive = false;
         // Note: Existing committed flux is now stuck unless a separate force-withdrawal function is added.
    }


    /// @notice Allows the owner to withdraw accumulated System Energy.
    /// @param amount The amount of System Energy to withdraw.
    function withdrawSystemEnergy(uint256 amount) external onlyOwner {
        require(amount > 0, "QFM: Amount must be greater than zero");
        require(systemEnergyBalance >= amount, "QFM: Insufficient System Energy");

        systemEnergyBalance -= amount;
        // In a real contract, you might want to send a specific token representing System Energy,
        // or ETH/WETH if the system somehow accumulated value there.
        // For this abstract example, it just reduces the internal balance.
        // If System Energy was meant to be a tradable token, you'd need ERC20 implementation.

        emit SystemEnergyWithdrawn(owner, amount); // Sending to owner as recipient in this example
    }

    // ========================================================================================================
    // XI. Advanced/Creative Concepts (Examples - Not all fully implemented with complex logic)
    // ========================================================================================================

    /// @notice Resolves a hypothetical 'System Event'. This is a placeholder for complex event logic.
    /// The actual effects of resolving an event would depend on its type and parameters,
    /// potentially involving global state changes, user challenges, or rewards/penalties.
    /// @dev In a full implementation, events would be triggered, have states, require user actions, etc.
    /// This function simulates the outcome based on a hypothetical current event ID.
    /// @param eventId The ID of the event being resolved.
    /// @param success Boolean indicating if the resolution was successful (example logic).
    function resolveCurrentEvent(uint256 eventId, bool success) external onlyOwner {
         // Example: A 'Turbulence Mitigation' event (ID 1).
         // If resolved successfully during Turbulence phase, it might reduce the phase duration or decay rates temporarily.
         // If resolved unsuccessfully, it might increase decay or transition to Decay phase faster.

         if (eventId == 1 && currentPhase == SystemPhase.Turbulence) {
             if (success) {
                 // Apply positive effects: e.g., temporarily reduce decay rates by 10%
                 // This would require tracking temporary modifiers, adding more state.
                 // For now, just a placeholder:
                 // decayRateModifier = 0.9e18;
                 emit SystemEnergyWithdrawn(msg.sender, 10 * 1e18); // Example: Reward caller for resolving
                 systemEnergyBalance -= 10 * 1e18; // Deduct from energy balance for reward
             } else {
                 // Apply negative effects: e.g., trigger immediate phase shift to Decay
                 currentPhase = SystemPhase.Decay;
                 currentPhaseStartTime = block.timestamp;
                 emit PhaseShifted(SystemPhase.Turbulence, SystemPhase.Decay, currentPhaseStartTime);
             }
         }
         // More event IDs and logic would go here...

         // This function acts as a hook for off-chain or admin logic to signal event outcomes.
    }

    // Total Public/External Functions: 29 (constructor not counted in the 20+ requested functions)
    // 1 (claim) + 4 (transform) + 2 (commit/withdraw) + 1 (align) = 8 User Tx
    // 5 (user queries) + 8 (system queries) = 13 Query
    // 7 (admin/system) = 7 Admin/System Tx
    // 1 (resolveEvent) = 1 Advanced Tx
    // Total = 8 + 13 + 7 + 1 = 29. This meets the >= 20 requirement.

    // Note on decimals: Assumes Flux amounts and System Energy are scaled by 1e18 like Ether for easier calculations with percentages/multipliers.
    // Parameters like rates and multipliers are also scaled by 1e18.
    // If different decimal points are desired, significant changes to calculation logic are needed.
}
```

**Explanation of Advanced Concepts & Creativity:**

1.  **Dynamic, Time-Sensitive State:** The core concept is not static balances but a constantly (theoretically) changing state influenced by elapsed time. `_updateUserFlux` is central, calculating generation and decay based on time since the last update. This creates a dynamic resource pool.
2.  **Multi-Type Flux with Inter-dependencies:** Having different Flux types (`Stable`, `Volatile`, `Exotic`) with different properties (generation, decay) and transformation rules creates strategic choices for users. Transformations aren't simple swaps but have costs, efficiencies, and potentially preconditions (`Volatile` -> `Exotic` requires `Turbulence` phase and high `externalFactor`).
3.  **User Alignment:** The `UserAlignment` enum introduces a personal state for each user that affects their interaction with the core mechanics (e.g., influencing generation rates). Shifting alignment is a user action with a cost and cooldown, adding a layer of personal strategy and risk.
4.  **System Phases:** The contract itself has a global state (`SystemPhase`) that changes over time (`_calculateCurrentPhase`, `_performPhaseShift`). Phases alter the global rules (parameters like generation/decay rates via `phaseMultiplier`). This adds global dynamics and periods of different market/system conditions.
5.  **Conduits:** `Conduits` represent a simple form of internal "staking" or resource allocation. Users commit Flux to remove it from standard decay and potentially earn yield (`yieldRatePerSecond` - although yield distribution logic isn't fully built out, the structure is there) or gain stability. Withdrawal penalties add friction.
6.  **External Factor:** The `externalFactor` variable, updated by the owner (simulating an oracle feed), introduces an external, unpredictable element that influences core dynamics like decay. This mimics how real-world factors or external data could impact a dApp's mechanics.
7.  **System Energy:** Accumulating a portion of transformation costs (`systemEnergyBalance`) provides an abstract sink and a resource that the system (or owner) can utilize, potentially for maintenance, rewards, or influencing future dynamics.
8.  **Event Simulation:** The `resolveCurrentEvent` function hints at a more complex event system where timed or triggered global events could occur, requiring specific user actions or resulting in significant state changes. This structure is a placeholder for integrating dynamic, non-standard game-like or simulation events.

This contract goes beyond typical token or simple interaction patterns by building a system with internal dynamics, time-based state changes, multiple interconnected variables (Flux types, Alignment, Phase, External Factor), and strategic user actions (transform, commit, shift). It serves as a more complex simulation or game-like contract rather than a standard financial primitive.