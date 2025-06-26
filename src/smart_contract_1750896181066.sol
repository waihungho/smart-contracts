Okay, let's create a smart contract concept around dynamic, time-sensitive, and interacting digital entities – let's call them "Quantum Flux Particles". These particles will exist purely within the contract's state, not as standard ERC-721 tokens, and their state and properties will evolve based on user actions, time, and internal "Flux Energy".

This concept avoids standard token interfaces (ERC-20, 721) and focuses on complex state management, time-based mechanics, internal resource pools (`fluxEnergy`), and probabilistic/conditional state transitions driven by internal factors and config.

---

**Smart Contract Name:** `QuantumFlux`

**Concept:** Manages digital "Flux Particles" that exist within the contract. Particles have complex states that evolve based on time, user interaction, and internal `fluxEnergy`. Users attempt to guide particles towards a 'Collapsed' state to claim yields, while avoiding 'Decaying' or 'Inert' states.

**Core Advanced Concepts:**
1.  **Complex State Machine:** Particles transition between multiple states (`Latent`, `Observing`, `Entangled`, `Decaying`, `Stable`, `Collapsed`, `Inert`).
2.  **Time-Based Mechanics:** State transitions can be triggered or influenced by elapsed time (`block.timestamp`).
3.  **Internal Mutable Property (`fluxEnergy`):** Particles have an internal value that can be boosted by user payments and influences state transition outcomes.
4.  **Conditional/Probabilistic Outcomes:** State transitions (especially to `Stable`, `Collapsed`, or `Inert`) can depend on a combination of elapsed time, `fluxEnergy`, and contract configuration parameters, introducing strategic risk/reward.
5.  **Interacting Entities:** Particles can be 'Entangled' in pairs, affecting each other's state transitions.
6.  **Non-Standard Assets:** Particles are not standard tokens; they are internal contract state entries managed via IDs and associated with owners.

**Outline & Function Summary:**

1.  **State Variables:**
    *   `particles`: Mapping from particle ID to `Particle` struct.
    *   `ownerParticles`: Mapping from owner address to array of particle IDs (simplification; iteration might be gas-heavy for many particles per owner).
    *   `nextParticleId`: Counter for unique particle IDs.
    *   `config`: Struct holding various time durations, fees, energy thresholds, yield amounts.
    *   `totalFeesCollected`: Total Ether collected from user actions.
    *   `totalParticlesMinted`: Global count.

2.  **Structs & Enums:**
    *   `Particle`: Struct containing owner, current state, `fluxEnergy`, timestamps (creation, last state change, state specific), entanglement partner ID, claimed status.
    *   `State`: Enum for particle states (`Latent`, `Observing`, `Entangled`, `Decaying`, `Stable`, `Collapsed`, `Inert`).
    *   `Config`: Struct for contract configuration parameters.

3.  **Events:**
    *   `ParticleMinted`: When a new particle is created.
    *   `StateChanged`: When a particle transitions state.
    *   `FluxEnergyBoosted`: When a particle's flux energy is increased.
    *   `Entangled`: When two particles become entangled.
    *   `EntanglementResolved`: When entangled particles resolve.
    *   `YieldClaimed`: When yield from a collapsed particle is claimed.
    *   `FeesWithdrawn`: When fees are withdrawn.

4.  **Modifiers:**
    *   `onlyOwner`: Restricts access to contract owner.
    *   `whenNotPaused`: Restricts access when contract is not paused.
    *   `whenPaused`: Restricts access when contract is paused.
    *   `isValidParticle`: Checks if a particle ID exists.
    *   `isOwnerOf`: Checks if msg.sender owns a particle.
    *   `canInteract`: Checks if particle is in a state allowing interaction (not Collapsed, Inert, or Claimed).

5.  **Functions (>= 20):**

    *   **Creation (3 functions):**
        *   `constructor`: Initializes contract, sets owner, initial config.
        *   `mintParticle() payable`: Allows users to mint a new particle by paying a fee. Particle starts in `Latent` state.
        *   `mintParticlesBatch(uint256 count) payable`: Mints multiple particles for the sender.

    *   **Querying & Reading (8 functions):**
        *   `getParticleCountByOwner(address owner) view`: Returns the number of particles owned by an address.
        *   `getParticleIdAtIndexForOwner(address owner, uint256 index) view`: Returns the ID of a particle at a specific index for an owner (requires knowing the count).
        *   `getParticleDetails(uint256 particleId) view isValidParticle`: Returns the full details of a particle struct.
        *   `getParticleState(uint256 particleId) view isValidParticle`: Returns only the current state of a particle.
        *   `getFluxEnergy(uint256 particleId) view isValidParticle`: Returns the flux energy of a particle.
        *   `getTotalParticles() view`: Returns the total number of particles ever minted.
        *   `getConfigParameters() view`: Returns the current contract configuration settings.
        *   `calculateCurrentState(uint256 particleId) view isValidParticle`: Calculates and returns what the particle's state *should* be based on elapsed time, without actually changing the state.

    *   **Particle Actions & State Transitions (7 functions):**
        *   `attemptObserve(uint256 particleId) whenNotPaused isValidParticle isOwnerOf canInteract`: Attempts to transition a particle from `Latent` to `Observing`. Fails if not `Latent`.
        *   `checkObservationStatus(uint256 particleId) whenNotPaused isValidParticle isOwnerOf canInteract`: Checks if observation duration has passed for an `Observing` particle. Transitions to `Stable` or `Decaying`/`Inert` based on time, flux energy, and config.
        *   `attemptEntangle(uint256 particle1Id, uint256 particle2Id) whenNotPaused isValidParticle(particle1Id) isValidParticle(particle2Id) isOwnerOf(particle1Id) isOwnerOf(particle2Id) canInteract(particle1Id) canInteract(particle2Id)`: Attempts to entangle two particles owned by the sender. Req: both `Latent` or `Stable`. Transitions both to `Entangled`.
        *   `checkEntanglementStatus(uint256 particleId) whenNotPaused isValidParticle isOwnerOf canInteract`: Checks if entanglement duration has passed for an `Entangled` particle. Resolves *both* entangled particles based on time, combined flux energy, and config, potentially to `Stable`, `Decaying`, `Inert`, or `Collapsed`.
        *   `attemptStabilize(uint256 particleId) payable whenNotPaused isValidParticle isOwnerOf canInteract`: Attempts to transition a `Decaying` or `Observing` particle to `Stable`. Requires a fee. Success chance depends on flux energy and config. Can fail to `Inert`.
        *   `attemptCollapse(uint256 particleId) payable whenNotPaused isValidParticle isOwnerOf canInteract`: Attempts to transition a `Stable` or `Entangled` particle to `Collapsed`. Requires a fee. Success chance depends on flux energy and config. Can fail to `Decaying`/`Inert`.
        *   `boostFluxEnergy(uint256 particleId) payable whenNotPaused isValidParticle isOwnerOf canInteract`: Allows the owner to increase a particle's `fluxEnergy` by paying Ether.

    *   **Outcome Claiming (2 functions):**
        *   `claimCollapsedYield(uint256 particleId) whenNotPaused isValidParticle isOwnerOf`: Allows claiming the yield from a `Collapsed` particle if not already claimed. Yield is transferred Ether based on config.
        *   `isParticleClaimed(uint256 particleId) view isValidParticle`: Checks if the yield for a collapsed particle has been claimed.

    *   **Admin & Configuration (4 functions):**
        *   `setConfigParameters(...) onlyOwner whenPaused`: Allows owner to update various configuration parameters (durations, fees, energy thresholds, yield amounts). Requires contract to be paused.
        *   `withdrawFees(address payable recipient) onlyOwner`: Allows owner to withdraw collected fees.
        *   `pause() onlyOwner whenNotPaused`: Pauses contract interactions.
        *   `unpause() onlyOwner whenPaused`: Unpauses contract interactions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Outline & Function Summary Above

contract QuantumFlux is Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- State Definitions ---
    enum State {
        Latent,      // Initial state, waiting for action
        Observing,   // Actively being observed, time-sensitive
        Entangled,   // Linked with another particle, time-sensitive
        Decaying,    // Losing energy, requires stabilization
        Stable,      // Good state, accumulating potential
        Collapsed,   // Final success state, yield claimable
        Inert        // Permanent decay state, cannot be revived
    }

    // --- Structs ---
    struct Particle {
        address owner;
        State state;
        uint64 creationTimestamp;
        uint64 lastStateChangeTimestamp;
        uint64 stateStartTime;       // Timestamp when current state was entered
        uint256 fluxEnergy;          // Internal energy/potential metric
        uint256 entanglementPartnerId; // ID of the entangled particle (if State is Entangled)
        bool yieldClaimed;           // True if yield from Collapsed state has been claimed
    }

    struct Config {
        uint64 observationDuration;     // Time required in Observing state
        uint64 entanglementDuration;    // Time required in Entangled state
        uint64 decayGracePeriod;        // Time before Latent/Decaying becomes Inert
        uint256 minFluxForStable;       // Minimum flux to transition to Stable (from Observe/Entangle)
        uint256 minFluxForCollapse;     // Minimum flux to transition to Collapsed (from Entangle/Collapse action)
        uint256 collapseSuccessEnergyDivisor; // Divisor for flux energy in collapse chance calculation
        uint256 particleMintFee;        // Fee to mint a new particle
        uint256 stabilizeFee;           // Fee for attemptStabilize action
        uint256 collapseFee;            // Fee for attemptCollapse action
        uint256 fluxBoostFeePerEnergy;  // Ether cost per point of flux energy boost
        uint256 collapsedYieldAmount;   // Ether amount transferred on yield claim
    }

    // --- State Variables ---
    mapping(uint256 => Particle) public particles;
    // Mapping owner to particle IDs. Using a simple array - gas warning for many particles per owner.
    mapping(address => uint256[]) private ownerParticles;
    Counters.Counter private _particleIds;
    Config public config;
    uint256 public totalFeesCollected;
    uint256 public totalParticlesMinted;

    // --- Events ---
    event ParticleMinted(uint256 indexed particleId, address indexed owner, uint64 timestamp);
    event StateChanged(uint256 indexed particleId, State oldState, State newState, uint64 timestamp);
    event FluxEnergyBoosted(uint256 indexed particleId, uint256 oldEnergy, uint256 newEnergy);
    event Entangled(uint256 indexed particle1Id, uint256 indexed particle2Id);
    event EntanglementResolved(uint256 indexed particleId, uint256 indexed partnerId);
    event YieldClaimed(uint256 indexed particleId, address indexed owner, uint256 amount);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event ConfigUpdated(Config newConfig);

    // --- Modifiers ---
    modifier isValidParticle(uint256 particleId) {
        require(particleId > 0 && particleId <= _particleIds.current(), "QF: Invalid particle ID");
        _;
    }

    modifier isOwnerOf(uint256 particleId) {
        require(particles[particleId].owner == msg.sender, "QF: Not your particle");
        _;
    }

    modifier canInteract(uint256 particleId) {
        State currentState = particles[particleId].state;
        require(currentState != State.Collapsed && currentState != State.Inert && !particles[particleId].yieldClaimed, "QF: Particle cannot be interacted with");
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) Pausable() {
        // Set initial configuration parameters
        config = Config({
            observationDuration: 1 days,
            entanglementDuration: 2 days,
            decayGracePeriod: 3 days,
            minFluxForStable: 100,
            minFluxForCollapse: 500,
            collapseSuccessEnergyDivisor: 20, // Higher divisor means harder to collapse
            particleMintFee: 0.01 ether,
            stabilizeFee: 0.005 ether,
            collapseFee: 0.01 ether,
            fluxBoostFeePerEnergy: 0.0001 ether, // 0.1 finney per energy point
            collapsedYieldAmount: 0.05 ether
        });
    }

    // --- Public Functions ---

    /// @notice Mints a new Quantum Flux Particle for the sender.
    /// @dev Requires paying the configured mint fee.
    function mintParticle() external payable whenNotPaused {
        require(msg.value >= config.particleMintFee, "QF: Insufficient mint fee");
        _safeMint(msg.sender);
        totalFeesCollected += msg.value;
    }

    /// @notice Mints multiple new Quantum Flux Particles for the sender.
    /// @dev Requires paying the configured mint fee per particle.
    /// @param count The number of particles to mint.
    function mintParticlesBatch(uint256 count) external payable whenNotPaused {
        require(count > 0, "QF: Count must be positive");
        require(msg.value >= config.particleMintFee * count, "QF: Insufficient total mint fee");
        for (uint i = 0; i < count; i++) {
            _safeMint(msg.sender);
        }
        totalFeesCollected += msg.value;
    }

    /// @notice Gets the number of particles owned by a specific address.
    /// @param owner The address to query.
    /// @return The count of particles owned by the address.
    function getParticleCountByOwner(address owner) external view returns (uint256) {
        return ownerParticles[owner].length;
    }

    /// @notice Gets the ID of a particle owned by an address at a specific index.
    /// @dev Use `getParticleCountByOwner` first to get the range of valid indices.
    /// @param owner The address to query.
    /// @param index The index of the particle in the owner's list.
    /// @return The ID of the particle.
    function getParticleIdAtIndexForOwner(address owner, uint256 index) external view returns (uint256) {
        require(index < ownerParticles[owner].length, "QF: Index out of bounds");
        return ownerParticles[owner][index];
    }

    /// @notice Gets all details for a specific particle.
    /// @param particleId The ID of the particle.
    /// @return A tuple containing all particle struct fields.
    function getParticleDetails(uint256 particleId) external view isValidParticle returns (Particle memory) {
        return particles[particleId];
    }

    /// @notice Gets the current state of a specific particle.
    /// @param particleId The ID of the particle.
    /// @return The state of the particle.
    function getParticleState(uint256 particleId) external view isValidParticle returns (State) {
        return particles[particleId].state;
    }

    /// @notice Gets the current flux energy of a specific particle.
    /// @param particleId The ID of the particle.
    /// @return The flux energy of the particle.
    function getFluxEnergy(uint256 particleId) external view isValidParticle returns (uint256) {
        return particles[particleId].fluxEnergy;
    }

    /// @notice Gets the total number of particles minted so far.
    /// @return The total count.
    function getTotalParticles() external view returns (uint256) {
        return totalParticlesMinted;
    }

    /// @notice Gets the current configuration parameters of the contract.
    /// @return A tuple containing all config struct fields.
    function getConfigParameters() external view returns (Config memory) {
        return config;
    }

    /// @notice Calculates the particle's state based on time and current state, without changing state.
    /// @dev Useful for off-chain checks or simulation. Does not trigger state transitions.
    /// @param particleId The ID of the particle.
    /// @return The calculated current state.
    function calculateCurrentState(uint256 particleId) external view isValidParticle returns (State) {
        Particle storage particle = particles[particleId];
        uint64 currentTime = uint64(block.timestamp);

        if (particle.state == State.Observing && currentTime >= particle.stateStartTime + config.observationDuration) {
            // Observation time elapsed - outcome based on flux/config (simulation)
            if (particle.fluxEnergy >= config.minFluxForStable) {
                 return State.Stable;
            } else {
                 return State.Decaying; // Or Inert based on grace period logic, needs refinement
            }
        }
        if (particle.state == State.Entangled && currentTime >= particle.stateStartTime + config.entanglementDuration) {
             // Entanglement time elapsed - outcome based on combined flux/config (simulation)
             // This view function is tricky for entangled pairs. It can only calculate *one* particle's potential outcome.
             // A real implementation might need a helper that takes *both* particles or make entanglement resolution require a call.
             // For simplicity here, we'll simulate a simplified check just for this particle's potential.
             // A better approach is to just check grace periods.
              if (particle.fluxEnergy < config.minFluxForStable) {
                   // Simulate decay possibility if flux is low after duration
                   return State.Decaying;
              } else {
                   return State.Stable; // Simulate stable possibility
              }
        }
        if (particle.state == State.Decaying && currentTime >= particle.stateStartTime + config.decayGracePeriod) {
            return State.Inert; // Decay time elapsed
        }
        if (particle.state == State.Latent && currentTime >= particle.stateStartTime + config.decayGracePeriod) {
            return State.Inert; // Latent left too long
        }

        // For other states or if time hasn't elapsed for the current state, return current state
        return particle.state;
    }


    /// @notice Attempts to initiate the observation process for a particle.
    /// @dev Particle must be in the `Latent` state. Transitions to `Observing`.
    /// @param particleId The ID of the particle to observe.
    function attemptObserve(uint256 particleId) external whenNotPaused isValidParticle isOwnerOf(particleId) canInteract(particleId) {
        Particle storage particle = particles[particleId];
        require(particle.state == State.Latent, "QF: Particle must be Latent to observe");

        _changeState(particleId, State.Observing);
    }

    /// @notice Checks if an `Observing` particle has completed its observation and resolves its state.
    /// @dev Transitions to `Stable` or `Decaying`/`Inert` based on time and `fluxEnergy`.
    /// @param particleId The ID of the particle to check.
    function checkObservationStatus(uint256 particleId) external whenNotPaused isValidParticle isOwnerOf(particleId) canInteract(particleId) {
        Particle storage particle = particles[particleId];
        require(particle.state == State.Observing, "QF: Particle must be Observing to check status");
        require(uint64(block.timestamp) >= particle.stateStartTime + config.observationDuration, "QF: Observation period not complete");

        State newState;
        if (particle.fluxEnergy >= config.minFluxForStable) {
            newState = State.Stable;
        } else {
            // If flux is low, it decays. Check if decay grace period is already over implicitly.
            if (uint64(block.timestamp) >= particle.lastStateChangeTimestamp + config.decayGracePeriod) {
                 newState = State.Inert; // Decay period from last state change exceeded
            } else {
                 newState = State.Decaying;
            }
        }
        _changeState(particleId, newState);
    }

    /// @notice Attempts to entangle two particles owned by the sender.
    /// @dev Both particles must be in `Latent` or `Stable` state. Transitions both to `Entangled`.
    /// @param particle1Id The ID of the first particle.
    /// @param particle2Id The ID of the second particle.
    function attemptEntangle(uint256 particle1Id, uint256 particle2Id) external whenNotPaused
        isValidParticle(particle1Id) isValidParticle(particle2Id)
        isOwnerOf(particle1Id) isOwnerOf(particle2Id)
        canInteract(particle1Id) canInteract(particle2Id)
    {
        require(particle1Id != particle2Id, "QF: Cannot entangle a particle with itself");

        Particle storage p1 = particles[particle1Id];
        Particle storage p2 = particles[particle2Id];

        require((p1.state == State.Latent || p1.state == State.Stable) && (p2.state == State.Latent || p2.state == State.Stable), "QF: Both particles must be Latent or Stable to entangle");

        _changeState(particle1Id, State.Entangled);
        _changeState(particle2Id, State.Entangled);
        p1.entanglementPartnerId = particle2Id;
        p2.entanglementPartnerId = particle1Id;

        emit Entangled(particle1Id, particle2Id);
    }

     /// @notice Checks if an `Entangled` pair of particles has completed entanglement and resolves their states.
     /// @dev Resolves *both* particles based on time, combined flux energy, and config. Can lead to `Stable`, `Decaying`, `Inert`, or `Collapsed`.
     /// @param particleId The ID of one particle in the entangled pair.
     function checkEntanglementStatus(uint256 particleId) external whenNotPaused isValidParticle isOwnerOf(particleId) canInteract(particleId) {
         Particle storage p1 = particles[particleId];
         require(p1.state == State.Entangled, "QF: Particle must be Entangled to check status");
         uint256 particle2Id = p1.entanglementPartnerId;
         require(particle2Id > 0 && particle2Id <= _particleIds.current(), "QF: Invalid entanglement partner");
         Particle storage p2 = particles[particle2Id];
         require(p2.state == State.Entangled && p2.entanglementPartnerId == particleId, "QF: Entanglement partner invalid or not entangled");
         require(uint64(block.timestamp) >= p1.stateStartTime + config.entanglementDuration, "QF: Entanglement period not complete");
         // Require partner also ready (should be, as they entered Entangled together, but good check)
         require(uint64(block.timestamp) >= p2.stateStartTime + config.entanglementDuration, "QF: Partner entanglement period not complete");

         // Resolution logic based on combined flux and config thresholds
         uint256 combinedFlux = p1.fluxEnergy + p2.fluxEnergy;
         State newState1;
         State newState2;

         // Deterministic "probabilistic" outcome based on flux energy and block hash/timestamp as weak entropy
         uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, particle1Id, particle2Id)));

         // Higher chance of Collapsed if flux is high and entropy aligns
         if (combinedFlux >= config.minFluxForCollapse && entropy % config.collapseSuccessEnergyDivisor == 0) {
             newState1 = State.Collapsed;
             newState2 = State.Collapsed;
         } else if (combinedFlux >= config.minFluxForStable * 2) { // Both stable if high flux
             newState1 = State.Stable;
             newState2 = State.Stable;
         } else if (combinedFlux >= config.minFluxForStable) { // One stable, one decays
             if (entropy % 2 == 0) {
                 newState1 = State.Stable;
                 newState2 = State.Decaying;
             } else {
                 newState1 = State.Decaying;
                 newState2 = State.Stable;
             }
         } else { // Both decay if flux is low
             newState1 = State.Decaying;
             newState2 = State.Decaying;
         }

         // Apply states and clear partner IDs
         _changeState(particle1Id, newState1);
         _changeState(particle2Id, newState2);
         p1.entanglementPartnerId = 0;
         p2.entanglementPartnerId = 0;

         emit EntanglementResolved(particle1Id, particle2Id);
     }


    /// @notice Attempts to stabilize a `Decaying` or `Observing` particle.
    /// @dev Requires a fee. Success chance depends on `fluxEnergy`. Can fail to `Inert`.
    /// @param particleId The ID of the particle.
    function attemptStabilize(uint256 particleId) external payable whenNotPaused isValidParticle isOwnerOf(particleId) canInteract(particleId) {
        Particle storage particle = particles[particleId];
        require(particle.state == State.Decaying || particle.state == State.Observing, "QF: Particle must be Decaying or Observing to stabilize");
        require(msg.value >= config.stabilizeFee, "QF: Insufficient stabilize fee");

        totalFeesCollected += msg.value;

        State newState;
        // Success chance increases with flux energy
        // Deterministic "randomness" based on flux/config/block data
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, particleId, particle.fluxEnergy)));

        // Simple check: If flux is high AND entropy favors success
        if (particle.fluxEnergy >= config.minFluxForStable && entropy % 10 < (particle.fluxEnergy / (config.minFluxForStable > 0 ? config.minFluxForStable : 1) )) {
             newState = State.Stable;
        } else {
             // Failure: Check if it turns Inert immediately based on elapsed time since last state change
             if (uint64(block.timestamp) >= particle.lastStateChangeTimestamp + config.decayGracePeriod) {
                  newState = State.Inert;
             } else {
                  newState = State.Decaying; // Remains Decaying or fails back to Decaying
             }
        }
        _changeState(particleId, newState);
    }

    /// @notice Attempts to collapse a `Stable` or `Entangled` particle.
    /// @dev Requires a fee. High risk, high reward. Success chance depends on `fluxEnergy`. Can fail to `Decaying`/`Inert`.
    /// @param particleId The ID of the particle.
    function attemptCollapse(uint256 particleId) external payable whenNotPaused isValidParticle isOwnerOf(particleId) canInteract(particleId) {
        Particle storage particle = particles[particleId];
        require(particle.state == State.Stable || particle.state == State.Entangled, "QF: Particle must be Stable or Entangled to attempt collapse");
        require(msg.value >= config.collapseFee, "QF: Insufficient collapse fee");

        totalFeesCollected += msg.value;

        State newState;
        uint256 currentFlux = particle.state == State.Entangled && particle.entanglementPartnerId > 0 ? particle.fluxEnergy + particles[particle.entanglementPartnerId].fluxEnergy : particle.fluxEnergy;

        // Success chance increases with flux energy. Higher chance to fail to Decaying/Inert.
        // Deterministic "randomness" based on flux/config/block data
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, particleId, currentFlux)));

        // Simple check: If flux is very high AND entropy favors success significantly
        if (currentFlux >= config.minFluxForCollapse && entropy % (config.collapseSuccessEnergyDivisor > 0 ? config.collapseSuccessEnergyDivisor : 1) == 0) {
             newState = State.Collapsed;
             // If entangled, try to collapse partner too? Or just this one?
             // Let's make attemptCollapse only collapse the target particle.
             // EntanglementResolution handles paired collapse.
             if (particle.state == State.Entangled && particle.entanglementPartnerId > 0) {
                  // If collapsing an entangled particle via attempt, the partner *might* also be affected,
                  // or the entanglement breaks. Let's break the entanglement here.
                  particles[particle.entanglementPartnerId].entanglementPartnerId = 0; // Break link for partner
                  // Partner state remains Entangled until its own checkEntanglementStatus call or action
             }

        } else {
             // Failure: Very likely to decay, potentially Inert immediately
             if (uint64(block.timestamp) >= particle.lastStateChangeTimestamp + config.decayGracePeriod) {
                  newState = State.Inert;
             } else {
                  newState = State.Decaying;
             }
        }

        _changeState(particleId, newState);
        if (newState == State.Entangled) { // If it somehow stayed entangled (shouldn't happen from Stable or Entangled unless logic changed)
             particle.entanglementPartnerId = 0; // Clear partner on failure if not collapsed
         }
    }

    /// @notice Allows the owner to claim the Ether yield from a `Collapsed` particle.
    /// @dev Particle must be in `Collapsed` state and yield must not have been claimed yet.
    /// @param particleId The ID of the particle.
    function claimCollapsedYield(uint256 particleId) external whenNotPaused isValidParticle isOwnerOf(particleId) {
        Particle storage particle = particles[particleId];
        require(particle.state == State.Collapsed, "QF: Particle must be Collapsed to claim yield");
        require(!particle.yieldClaimed, "QF: Yield already claimed");

        particle.yieldClaimed = true;

        // Transfer yield - use call.value for re-entrancy protection
        (bool success, ) = payable(msg.sender).call{value: config.collapsedYieldAmount}("");
        require(success, "QF: Yield transfer failed");

        emit YieldClaimed(particleId, msg.sender, config.collapsedYieldAmount);
    }

    /// @notice Allows the owner to increase a particle's `fluxEnergy` by paying Ether.
    /// @dev Higher flux energy improves chances of positive state transitions.
    /// @param particleId The ID of the particle.
    function boostFluxEnergy(uint256 particleId) external payable whenNotPaused isValidParticle isOwnerOf(particleId) canInteract(particleId) {
        Particle storage particle = particles[particleId];
        require(config.fluxBoostFeePerEnergy > 0, "QF: Flux boosting is disabled");
        uint256 energyGained = msg.value / config.fluxBoostFeePerEnergy;
        require(energyGained > 0, "QF: Insufficient payment for boost");

        uint256 oldEnergy = particle.fluxEnergy;
        particle.fluxEnergy += energyGained;
        totalFeesCollected += msg.value;

        emit FluxEnergyBoosted(particleId, oldEnergy, particle.fluxEnergy);
    }

    /// @notice Checks if the yield for a collapsed particle has been claimed.
    /// @param particleId The ID of the particle.
    /// @return True if claimed, false otherwise.
    function isParticleClaimed(uint256 particleId) external view isValidParticle returns (bool) {
        return particles[particleId].yieldClaimed;
    }

    // --- Admin Functions (onlyOwner, often Pausable) ---

    /// @notice Allows the owner to update contract configuration parameters.
    /// @dev Requires the contract to be paused.
    /// @param _config The new Config struct.
    function setConfigParameters(Config memory _config) external onlyOwner whenPaused {
        config = _config;
        emit ConfigUpdated(config);
    }

    /// @notice Allows the owner to withdraw collected fees.
    /// @param recipient The address to send the fees to.
    function withdrawFees(address payable recipient) external onlyOwner {
        uint256 balance = totalFeesCollected;
        totalFeesCollected = 0; // Reset balance before transfer to prevent re-entrancy
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "QF: Fee withdrawal failed");
        emit FeesWithdrawn(recipient, balance);
    }

    /// @notice Pauses the contract, preventing most user interactions.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract, allowing user interactions again.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // --- Internal Functions ---

    /// @dev Mints a new particle and assigns it to an owner.
    /// @param owner The address that will own the particle.
    function _safeMint(address owner) internal {
        _particleIds.increment();
        uint256 newParticleId = _particleIds.current();
        uint64 currentTime = uint64(block.timestamp);

        particles[newParticleId] = Particle({
            owner: owner,
            state: State.Latent,
            creationTimestamp: currentTime,
            lastStateChangeTimestamp: currentTime,
            stateStartTime: currentTime,
            fluxEnergy: 0,
            entanglementPartnerId: 0,
            yieldClaimed: false
        });
        ownerParticles[owner].push(newParticleId);
        totalParticlesMinted++;

        emit ParticleMinted(newParticleId, owner, currentTime);
    }

    /// @dev Internal helper to change a particle's state and update timestamps.
    /// @param particleId The ID of the particle.
    /// @param newState The new state for the particle.
    function _changeState(uint256 particleId, State newState) internal {
        Particle storage particle = particles[particleId];
        State oldState = particle.state;
        if (oldState != newState) {
            particle.state = newState;
            uint64 currentTime = uint64(block.timestamp);
            particle.lastStateChangeTimestamp = currentTime;
            particle.stateStartTime = currentTime; // Reset state start time for new state
            emit StateChanged(particleId, oldState, newState, currentTime);
        }
    }

    // Fallback function to accept Ether for potential future features (or error handling)
    // receive() external payable {
    //    // Optional: Handle incoming Ether not associated with specific calls
    // }
}
```