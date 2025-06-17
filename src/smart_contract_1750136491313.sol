Okay, this sounds like a fun challenge! Let's create a concept around "Quantum Forging" – where users synthesize particles, forge them into complex artifacts that have dynamic states, decay over time, can become entangled, and whose properties are influenced by interaction.

This contract will feature:
1.  **Essences:** Base types of "energy/matter" with unique properties.
2.  **Flux:** A transient energy resource needed for operations.
3.  **Particles:** Tokenized (though simply represented by balance) instances of Essences.
4.  **Artifacts:** Unique, complex items forged from Particles and Flux, with state, stability, complexity, and time-sensitive properties.
5.  **Dynamic State:** Artifacts change state (Stable, Volatile, Entangled, Decayed) based on interactions and time.
6.  **Decay:** Artifacts lose stability if not interacted with.
7.  **Entanglement:** Two artifacts can be linked, potentially influencing each other (conceptually represented).
8.  **Mutation:** Artifacts can be mutated, introducing randomness and changing properties.
9.  **Dismantling:** Artifacts can be broken down, recovering some resources based on their state.

We will *not* use standard interfaces like ERC20 or ERC721 directly to ensure it's not a direct copy of open-source token standards, although the concepts of balance tracking and unique ownership are similar. Access control will be a simple owner pattern.

---

**Outline and Function Summary: QuantumForge**

**Theme:** A system for synthesizing abstract quantum "Essences" into "Particles," which are then forged into complex, dynamic "Artifacts" that live and decay on the blockchain.

**Core Components:**
*   `EssenceProperties`: Defines properties of different essence types (stability influence, complexity influence, decay resistance).
*   `Particle Balances`: Users hold quantities of specific essence types as particles.
*   `Flux Balances`: Users hold a consumable energy resource.
*   `Artifact`: Represents a unique forged item with composition, state, stability, complexity, creation/interaction timestamps, and entanglement links.

**Key Mechanics:**
*   **Essence Management (Admin):** Defining and updating the fundamental essence types available in the system.
*   **Flux Generation:** Users can periodically generate Flux.
*   **Particle Synthesis:** Users consume Flux to create random particles based on available essence types.
*   **Artifact Forging:** Users consume Particles and Flux to create new Artifacts with properties derived from their components.
*   **Artifact Interaction:** Users interact with their Artifacts to boost stability and update timestamps, influencing decay.
*   **Artifact Decay:** Artifacts lose stability over time if not interacted with. This is calculated and applied upon specific actions.
*   **Artifact State Transitions:** Artifacts change state (Stable, Volatile, Entangled, Decayed, Dormant) based on stability, interactions, and specific actions.
*   **Artifact Mutation:** Users can attempt to mutate an Artifact, introducing randomness to its composition and state.
*   **Artifact Entanglement:** Users can link two of their Artifacts, creating an 'Entangled' state.
*   **Artifact Dismantling:** Users can break down Artifacts to recover partial resources, the amount depending on the Artifact's state.
*   **Transfers:** Users can transfer Flux, Particles, and Artifacts to others.

**Function List (Total: 30+ Functions):**

**Admin Functions (Require Owner):**
1.  `constructor()`: Initializes contract, sets owner.
2.  `setOwner(address newOwner)`: Transfers ownership.
3.  `pauseContract()`: Pauses state-changing user operations.
4.  `unpauseContract()`: Unpauses contract.
5.  `createEssenceType(string name, uint256 baseStabilityInfluence, uint256 complexityInfluence, uint256 decayResistance)`: Defines a new essence type.
6.  `updateEssenceProperties(uint256 essenceId, uint256 baseStabilityInfluence, uint256 complexityInfluence, uint256 decayResistance)`: Updates properties of an existing essence type.

**Resource Management Functions:**
7.  `harvestFlux()`: Allows a user to generate Flux based on time since last harvest.
8.  `transferFlux(address recipient, uint256 amount)`: Transfers Flux to another user.
9.  `synthesizeParticles(uint256 fluxAmount)`: Consumes Flux to create a random distribution of particles for the user.
10. `transferParticles(address recipient, uint256 essenceId, uint256 amount)`: Transfers a specific type and amount of particles to another user.

**Artifact Management Functions:**
11. `forgeArtifact(uint256[] essenceComposition, uint256[] essenceAmounts, uint256 fluxCost)`: Creates a new Artifact from specified particles and Flux.
12. `interactWithArtifact(uint256 artifactId, uint256 fluxCost)`: User interacts with an Artifact, applying decay, boosting stability, and potentially changing state.
13. `calculateAndApplyDecay(uint256 artifactId)`: Calculates and applies time-based stability decay to an Artifact. Callable by anyone, but only updates if needed.
14. `mutateArtifact(uint256 artifactId, uint252 fluxCost)`: Attempts to randomly mutate an Artifact's properties or composition.
15. `dismantleArtifact(uint256 artifactId)`: Breaks down an Artifact, returning some resources based on its state.
16. `entangleArtifacts(uint256 artifactId1, uint256 artifactId2, uint256 fluxCost)`: Links two Artifacts, changing their state to Entangled.
17. `dissipateEntanglement(uint256 artifactId1, uint256 artifactId2, uint256 fluxCost)`: Breaks the link between two Entangled Artifacts.
18. `transferArtifact(address recipient, uint256 artifactId)`: Transfers ownership of an Artifact.

**Query/View Functions (Read-Only):**
19. `getEssenceCount()`: Returns the total number of defined essence types.
20. `getEssenceProperties(uint256 essenceId)`: Returns properties of a specific essence type.
21. `getUserFluxBalance(address user)`: Returns the Flux balance for a user.
22. `getUserParticleBalance(address user, uint256 essenceId)`: Returns the particle count of a specific essence type for a user.
23. `getLastFluxHarvestTime(address user)`: Returns the timestamp of the user's last Flux harvest.
24. `getTotalArtifactsForged()`: Returns the total number of Artifacts ever forged.
25. `getArtifactOwner(uint256 artifactId)`: Returns the owner of an Artifact.
26. `getArtifactComposition(uint256 artifactId)`: Returns the essence composition (IDs and amounts) of an Artifact.
27. `getArtifactDetails(uint256 artifactId)`: Returns comprehensive details of an Artifact (calculates potential decay for stability).
28. `getArtifactState(uint256 artifactId)`: Returns the current state of an Artifact.
29. `getArtifactStability(uint256 artifactId)`: Returns the current stability of an Artifact (calculates potential decay).
30. `getArtifactComplexity(uint256 artifactId)`: Returns the complexity of an Artifact.
31. `getEntangledArtifacts(uint256 artifactId)`: Returns the list of Artifacts entangled with a given one.
32. `calculatePotentialDecay(uint256 artifactId)`: (Internal/Pure helper) Calculates the potential stability loss since last interaction based on time and properties. Exposed via `getArtifactStability` etc. *Correction*: Will implement as an internal helper called by view functions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumForge
 * @dev A conceptual smart contract exploring dynamic states, resource management,
 *      and time-sensitive properties in forged digital artifacts.
 *      Features include Essence and Particle systems, Flux energy, Artifact forging,
 *      interaction, time-based decay, mutation, entanglement, and dismantling.
 *      Designed to be complex and non-standard, avoiding direct interfaces
 *      like ERC20/ERC721 for creative exploration.
 */

// Outline and Function Summary provided above the contract code block.

contract QuantumForge {

    // --- Custom Errors ---
    error Unauthorized();
    error Paused();
    error NotPaused();
    error InvalidEssenceId();
    error InsufficientFlux();
    error InsufficientParticles(uint256 essenceId);
    error ArtifactNotFound();
    error NotArtifactOwner();
    error InvalidArtifactComposition();
    error ArtifactNotEntangled(uint256 artifactId1, uint256 artifactId2);
    error ArtifactAlreadyEntangled(uint256 artifactId);
    error CannotEntangleSelf();
    error InsufficientArtifactsForEntanglement();
    error EntanglementPairMismatch();
    error DecayCheckTooFrequent(uint256 artifactId);
    error ArtifactInDecayedState();
    error ArtifactInEntangledState();
    error ArtifactRequiresInteraction();
    error CannotMutateDecayedArtifact();
    error CannotDismantleEntangledArtifact();

    // --- Events ---
    event EssenceTypeCreated(uint256 indexed essenceId, string name, uint256 baseStabilityInfluence, uint256 complexityInfluence, uint256 decayResistance);
    event EssencePropertiesUpdated(uint256 indexed essenceId, uint256 baseStabilityInfluence, uint256 complexityInfluence, uint256 decayResistance);
    event FluxHarvested(address indexed user, uint256 amount);
    event FluxTransferred(address indexed from, address indexed to, uint256 amount);
    event ParticlesSynthesized(address indexed user, uint256 totalFluxConsumed, uint256 totalParticlesCreated);
    event ParticlesTransferred(address indexed from, address indexed to, uint256 indexed essenceId, uint256 amount);
    event ArtifactForged(address indexed owner, uint256 indexed artifactId, uint256 initialStability, uint256 initialComplexity);
    event ArtifactInteracted(address indexed user, uint256 indexed artifactId, uint256 stabilityChange, uint8 newArtifactState);
    event ArtifactDecayed(uint256 indexed artifactId, uint256 stabilityLoss, uint8 newArtifactState);
    event ArtifactMutated(uint256 indexed artifactId, uint8 newArtifactState, string description); // Description could hint at change
    event ArtifactDismantled(address indexed user, uint256 indexed artifactId, uint256 fluxReturned, uint256 particlesReturnedCount); // Count of different particle types
    event ArtifactEntangled(uint256 indexed artifactId1, uint256 indexed artifactId2);
    event ArtifactDissipatedEntanglement(uint256 indexed artifactId1, uint256 indexed artifactId2);
    event ArtifactTransferred(address indexed from, address indexed to, uint256 indexed artifactId);
    event ArtifactStateChanged(uint256 indexed artifactId, uint8 oldState, uint8 newState);
    event ContractPaused(address indexed user);
    event ContractUnpaused(address indexed user);

    // --- State Variables ---

    address private _owner;
    bool private _paused;

    // Essence Definitions
    struct EssenceProperties {
        string name;
        uint256 baseStabilityInfluence; // How much this essence contributes to initial stability
        uint256 complexityInfluence;    // How much this essence contributes to complexity
        uint256 decayResistance;      // How much this essence resists decay (higher is better)
    }
    mapping(uint256 => EssenceProperties) public essenceTypes;
    uint256 private _nextEssenceId = 1; // Start IDs from 1

    // Resource Balances
    mapping(address => uint256) private _fluxBalances;
    mapping(address => mapping(uint256 => uint256)) private _particleBalances; // user => essenceId => count

    // Flux Generation Cooldown
    uint256 public fluxHarvestCooldown = 1 days; // Users can harvest flux once per day
    uint256 public baseFluxPerHarvest = 100;
    mapping(address => uint64) private _lastFluxHarvestTime;

    // Artifacts
    enum ArtifactState {
        Stable,
        Volatile,
        Entangled,
        Decayed,
        Dormant // A state an artifact might enter after decay or entanglement dissipation
    }

    struct Artifact {
        address owner;
        uint256[] essenceComposition; // List of essence IDs
        uint256[] essenceAmounts;     // Corresponding amounts of essences
        uint64 creationTime;
        uint64 lastInteractionTime;
        uint256 stability;          // Current stability level (0-1000 scale, example)
        uint256 complexity;         // Derived complexity (higher is generally better, resists mutation?)
        ArtifactState state;
        uint256[] entangledWith;      // List of artifact IDs it's entangled with
        uint64 lastDecayCheckTime; // To prevent spamming calculateAndApplyDecay
    }
    mapping(uint256 => Artifact) private _artifacts;
    uint256 private _nextArtifactId = 1; // Start IDs from 1
    mapping(uint256 => bool) private _artifactExists; // Helper to check existence cheaply

    // Artifact Decay Parameters (example values)
    uint256 public constant STABILITY_SCALE = 1000; // Max stability
    uint256 public constant BASE_DECAY_RATE_PER_SECOND = 1; // Base decay points per second (adjust scale)
    uint256 public constant MIN_DECAY_INTERVAL = 1 minutes; // Minimum time between decay applications per artifact

    // Artifact Interaction Parameters (example values)
    uint256 public constant INTERACTION_STABILITY_BOOST = 100; // Stability gained per interaction

    // Artifact Mutation Parameters (example values)
    uint256 public mutationSuccessChance = 50; // Percentage chance of success
    uint256 public mutationVolatilityIncrease = 50; // Stability loss on failed mutation


    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != _owner) revert Unauthorized();
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!_paused) revert NotPaused();
        _;
    }

    modifier artifactExists(uint256 artifactId) {
        if (!_artifactExists[artifactId]) revert ArtifactNotFound();
        _;
    }

    modifier isArtifactOwner(uint256 artifactId) {
        if (_artifacts[artifactId].owner != msg.sender) revert NotArtifactOwner();
        _;
    }

    // --- Constructor ---

    constructor() {
        _owner = msg.sender;
        _paused = false;
        // Optionally create some initial essence types here
        _createEssenceType("Quantum Dust", 10, 5, 5); // ID 1
        _createEssenceType("Flux Crystal", 5, 10, 10); // ID 2
        _createEssenceType("Void Shard", 15, 15, 2);  // ID 3
    }

    // --- Admin Functions ---

    function setOwner(address newOwner) external onlyOwner {
        _owner = newOwner;
    }

    function pauseContract() external onlyOwner whenNotPaused {
        _paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external onlyOwner whenPaused {
        _paused = false;
        emit ContractUnpaused(msg.sender);
    }

    function createEssenceType(string memory name, uint256 baseStabilityInfluence_, uint256 complexityInfluence_, uint256 decayResistance_) external onlyOwner {
        uint256 essenceId = _nextEssenceId++;
        essenceTypes[essenceId] = EssenceProperties(name, baseStabilityInfluence_, complexityInfluence_, decayResistance_);
        emit EssenceTypeCreated(essenceId, name, baseStabilityInfluence_, complexityInfluence_, decayResistance_);
    }

    function updateEssenceProperties(uint256 essenceId, uint256 baseStabilityInfluence_, uint256 complexityInfluence_, uint256 decayResistance_) external onlyOwner artifactExists(essenceId) {
         if (essenceId >= _nextEssenceId || essenceId == 0) revert InvalidEssenceId(); // Check it's a valid *existing* ID

        EssenceProperties storage essence = essenceTypes[essenceId];
        essence.baseStabilityInfluence = baseStabilityInfluence_;
        essence.complexityInfluence = complexityInfluence_;
        essence.decayResistance = decayResistance_;
        emit EssencePropertiesUpdated(essenceId, baseStabilityInfluence_, complexityInfluence_, decayResistance_);
    }

    // --- Resource Management Functions ---

    function harvestFlux() external whenNotPaused {
        uint64 lastHarvest = _lastFluxHarvestTime[msg.sender];
        uint66 currentTime = uint66(block.timestamp); // Use larger type for safety in multiplication if needed

        if (currentTime < lastHarvest + fluxHarvestCooldown) {
             // Not enough time has passed
             revert ArtifactRequiresInteraction(); // Reusing error for conceptual cooldown
        }

        uint256 timeSinceLastHarvest = currentTime - lastHarvest;
        // Simple example: linear growth based on time elapsed / cooldown period
        uint256 harvestedAmount = (baseFluxPerHarvest * timeSinceLastHarvest) / fluxHarvestCooldown;

        if (harvestedAmount == 0) {
             // Not enough time for at least 1 unit of flux
             revert ArtifactRequiresInteraction(); // Reusing error
        }

        _fluxBalances[msg.sender] += harvestedAmount;
        _lastFluxHarvestTime[msg.sender] = uint64(currentTime); // Update last harvest time

        emit FluxHarvested(msg.sender, harvestedAmount);
    }

    function transferFlux(address recipient, uint256 amount) external whenNotPaused {
        if (recipient == address(0)) revert Unauthorized(); // Basic check
        if (_fluxBalances[msg.sender] < amount) revert InsufficientFlux();

        _fluxBalances[msg.sender] -= amount;
        _fluxBalances[recipient] += amount;

        emit FluxTransferred(msg.sender, recipient, amount);
    }

    function synthesizeParticles(uint256 fluxAmount) external whenNotPaused {
        if (_fluxBalances[msg.sender] < fluxAmount) revert InsufficientFlux();
        if (fluxAmount == 0) return; // Do nothing if no flux is spent

        _fluxBalances[msg.sender] -= fluxAmount;

        // Simulate particle creation based on flux spent and available essence types
        uint256 totalParticlesCreated = 0;
        uint256 availableEssenceTypes = _nextEssenceId - 1;

        if (availableEssenceTypes == 0) {
             emit ParticlesSynthesized(msg.sender, fluxAmount, 0);
             return; // No essences defined
        }

        // Basic pseudo-random distribution based on flux amount
        // WARNING: This is NOT cryptographically secure and is predictable.
        // For a real DApp, use a verifiably random function (VRF) like Chainlink VRF.
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, fluxAmount, _nextArtifactId)));

        uint256 particlesPerFluxUnit = 1; // Example conversion rate
        uint256 particlesToDistribute = fluxAmount * particlesPerFluxUnit;

        if (particlesToDistribute == 0) {
             emit ParticlesSynthesized(msg.sender, fluxAmount, 0);
             return;
        }

        // Distribute particles among essence types
        for (uint256 i = 0; i < particlesToDistribute; ) {
             // Pick a random essence ID (modulo number of types)
             uint256 chosenEssenceId = (entropy % availableEssenceTypes) + 1; // IDs are 1-based

             // Check if essence type exists (should always if ID is valid)
             if (essenceTypes[chosenEssenceId].baseStabilityInfluence > 0 || chosenEssenceId == 1) { // Simple existence check
                _particleBalances[msg.sender][chosenEssenceId]++;
                totalParticlesCreated++;
                i++; // Increment only if a particle was successfully assigned
             }
             // Update entropy for next iteration (simple shift/mix)
             entropy = uint256(keccak256(abi.encodePacked(entropy, i, chosenEssenceId)));
        }

        emit ParticlesSynthesized(msg.sender, fluxAmount, totalParticlesCreated);
    }

    function transferParticles(address recipient, uint256 essenceId, uint256 amount) external whenNotPaused {
        if (recipient == address(0)) revert Unauthorized();
        if (essenceId == 0 || essenceId >= _nextEssenceId) revert InvalidEssenceId();
        if (_particleBalances[msg.sender][essenceId] < amount) revert InsufficientParticles(essenceId);

        _particleBalances[msg.sender][essenceId] -= amount;
        _particleBalances[recipient][essenceId] += amount;

        emit ParticlesTransferred(msg.sender, recipient, essenceId, amount);
    }

    // --- Artifact Management Functions ---

    function forgeArtifact(uint256[] memory essenceComposition, uint256[] memory essenceAmounts, uint256 fluxCost) external whenNotPaused {
        if (essenceComposition.length == 0 || essenceComposition.length != essenceAmounts.length) revert InvalidArtifactComposition();
        if (_fluxBalances[msg.sender] < fluxCost) revert InsufficientFlux();

        // Check if caller has required particles and calculate initial properties
        uint256 initialStability = 0;
        uint256 initialComplexity = 0;
        uint256 totalDecayResistanceInfluence = 0; // Sum of resistance values

        for (uint256 i = 0; i < essenceComposition.length; i++) {
            uint256 essenceId = essenceComposition[i];
            uint256 amount = essenceAmounts[i];

            if (essenceId == 0 || essenceId >= _nextEssenceId) revert InvalidEssenceId();
            if (_particleBalances[msg.sender][essenceId] < amount) revert InsufficientParticles(essenceId);
            if (amount == 0) continue; // Skip if amount is 0

            EssenceProperties storage props = essenceTypes[essenceId];
            initialStability += props.baseStabilityInfluence * amount;
            initialComplexity += props.complexityInfluence * amount;
            totalDecayResistanceInfluence += props.decayResistance * amount;
        }

        // Consume particles and flux
        _fluxBalances[msg.sender] -= fluxCost;
        for (uint256 i = 0; i < essenceComposition.length; i++) {
            uint256 essenceId = essenceComposition[i];
            uint256 amount = essenceAmounts[i];
            if (amount > 0) {
                 _particleBalances[msg.sender][essenceId] -= amount;
            }
        }

        // Determine final initial stability (normalize? Cap?)
        // Example: scale initial stability based on total influence, cap at STABILITY_SCALE
        uint256 totalEssenceAmount = 0;
        for(uint256 i=0; i<essenceAmounts.length; i++) totalEssenceAmount += essenceAmounts[i];
        if (totalEssenceAmount > 0) {
             initialStability = (initialStability * STABILITY_SCALE) / (totalEssenceAmount * 20); // Example scaling, adjust factor (20) as needed
             initialComplexity = initialComplexity; // Complexity can be raw sum or scaled
        } else {
            initialStability = 1; // Minimum stability even if forged with no essences (e.g., just flux?) - design choice
            initialComplexity = 1;
        }
        if (initialStability > STABILITY_SCALE) initialStability = STABILITY_SCALE;
        if (initialStability == 0) initialStability = 1; // Ensure minimum stability
        if (initialComplexity == 0) initialComplexity = 1; // Ensure minimum complexity


        // Create the artifact
        uint256 artifactId = _nextArtifactId++;
        Artifact storage newArtifact = _artifacts[artifactId];
        newArtifact.owner = msg.sender;
        newArtifact.essenceComposition = essenceComposition;
        newArtifact.essenceAmounts = essenceAmounts;
        newArtifact.creationTime = uint64(block.timestamp);
        newArtifact.lastInteractionTime = uint64(block.timestamp);
        newArtifact.stability = initialStability;
        newArtifact.complexity = initialComplexity;
        newArtifact.state = ArtifactState.Stable; // Start as stable
        newArtifact.lastDecayCheckTime = uint64(block.timestamp);
        // entangledWith starts empty

        _artifactExists[artifactId] = true;

        emit ArtifactForged(msg.sender, artifactId, newArtifact.stability, newArtifact.complexity);
    }

    function interactWithArtifact(uint256 artifactId, uint256 fluxCost) external whenNotPaused artifactExists(artifactId) isArtifactOwner(artifactId) {
        Artifact storage artifact = _artifacts[artifactId];

        if (artifact.state == ArtifactState.Decayed) revert ArtifactInDecayedState();
        // Interaction might be different for Entangled or Dormant states - add specific checks/logic if needed
        // For now, allow interaction with Volatile/Stable/Dormant/Entangled

        if (_fluxBalances[msg.sender] < fluxCost) revert InsufficientFlux();
        _fluxBalances[msg.sender] -= fluxCost;

        // Apply decay first based on time since last check/interaction
        _applyDecay(artifactId, artifact);

        // Boost stability (capped)
        uint256 oldStability = artifact.stability;
        uint256 stabilityBoost = INTERACTION_STABILITY_BOOST;
        artifact.stability = artifact.stability + stabilityBoost > STABILITY_SCALE ? STABILITY_SCALE : artifact.stability + stabilityBoost;

        // Update last interaction time
        artifact.lastInteractionTime = uint64(block.timestamp);

        // Potential state change on interaction (example: Volatile artifacts might stabilize)
        ArtifactState oldState = artifact.state;
        ArtifactState newState = artifact.state;
        if (artifact.state == ArtifactState.Volatile && artifact.stability > STABILITY_SCALE / 2) {
             newState = ArtifactState.Stable;
        } else if (artifact.state == ArtifactState.Stable && artifact.stability < STABILITY_SCALE / 4) {
             newState = ArtifactState.Volatile;
        }
        // Interactions do not change Entangled or Decayed states directly here

        if (oldState != newState) {
             artifact.state = newState;
             emit ArtifactStateChanged(artifactId, uint8(oldState), uint8(newState));
        }


        emit ArtifactInteracted(msg.sender, artifactId, artifact.stability - oldStability, uint8(newState));
    }

    /**
     * @dev Calculates and applies time-based stability decay to an artifact.
     *      Callable by anyone, but has a minimum interval check per artifact
     *      to prevent spamming state changes unnecessarily off-chain.
     */
    function calculateAndApplyDecay(uint256 artifactId) external whenNotPaused artifactExists(artifactId) {
        Artifact storage artifact = _artifacts[artifactId];
        _applyDecay(artifactId, artifact);
    }

    /**
     * @dev Internal helper to apply decay logic. Called by interacting functions and calculateAndApplyDecay.
     */
    function _applyDecay(uint256 artifactId, Artifact storage artifact) internal {
        // Ensure minimum interval since last check/interaction for decay calculation
        uint64 currentTime = uint64(block.timestamp);
        uint64 lastRelevantTime = artifact.lastDecayCheckTime > artifact.lastInteractionTime ? artifact.lastDecayCheckTime : artifact.lastInteractionTime;

        if (currentTime < lastRelevantTime + MIN_DECAY_INTERVAL && artifact.lastDecayCheckTime > 0) {
             // Decay check done too recently, or first interaction time not set yet
             // Allow it through if lastDecayCheckTime is 0 (artifact just created)
             if (artifact.lastDecayCheckTime > 0) {
                // Decide if we revert or just do nothing. Reverting on public call is safer.
                // But internal calls should just proceed if no decay is due.
                // Let's proceed internally but check publicly.
                if (msg.sender != address(this)) { // Assuming public call wrapper exists or this is callable externally
                    // This check is primarily for the public calculateAndApplyDecay
                    if (currentTime < artifact.lastDecayCheckTime + MIN_DECAY_INTERVAL) {
                         revert DecayCheckTooFrequent(artifactId);
                    }
                }
             }
        }

        uint256 timeElapsed = currentTime - lastRelevantTime;
        if (timeElapsed == 0) {
             artifact.lastDecayCheckTime = currentTime;
             return; // No time has passed
        }

        // Calculate decay amount
        // Decay is influenced by time elapsed and the artifact's decay resistance (derived from composition)
        uint256 totalDecayResistanceInfluence = 0;
         for (uint256 i = 0; i < artifact.essenceComposition.length; i++) {
            uint256 essenceId = artifact.essenceComposition[i];
            uint256 amount = artifact.essenceAmounts[i];
            if (essenceTypes[essenceId].decayResistance > 0) {
                totalDecayResistanceInfluence += essenceTypes[essenceId].decayResistance * amount;
            }
        }
        // Example decay calculation: higher resistance means slower decay
        // Inverse relationship with resistance sum. Add a base minimum resistance to avoid division by zero.
        uint256 adjustedResistance = totalDecayResistanceInfluence + 10; // Add base resistance
        uint256 potentialDecay = (BASE_DECAY_RATE_PER_SECOND * timeElapsed * STABILITY_SCALE) / adjustedResistance;

        uint256 stabilityLoss = potentialDecay;
        if (stabilityLoss > artifact.stability) {
            stabilityLoss = artifact.stability; // Cannot lose more stability than it has
        }

        uint256 oldStability = artifact.stability;
        artifact.stability -= stabilityLoss;

        ArtifactState oldState = artifact.state;
        ArtifactState newState = artifact.state;

        // State transitions based on decay
        if (artifact.stability == 0) {
            if (artifact.state != ArtifactState.Decayed && artifact.state != ArtifactState.Entangled) { // Can't decay if Entangled? Design choice.
                 newState = ArtifactState.Decayed;
            }
        } else if (artifact.stability < STABILITY_SCALE / 4 && artifact.state == ArtifactState.Stable) {
            newState = ArtifactState.Volatile;
        } else if (artifact.stability >= STABILITY_SCALE / 2 && artifact.state == ArtifactState.Volatile) {
            newState = ArtifactState.Stable; // Can revert to Stable if stability recovers?
        }

        artifact.lastDecayCheckTime = currentTime; // Update decay check time

        if (oldState != newState) {
             artifact.state = newState;
             emit ArtifactStateChanged(artifactId, uint8(oldState), uint8(newState));
        }

        if (stabilityLoss > 0) {
             emit ArtifactDecayed(artifactId, stabilityLoss, uint8(newState));
        }
    }

    function mutateArtifact(uint256 artifactId, uint256 fluxCost) external whenNotPaused artifactExists(artifactId) isArtifactOwner(artifactId) {
         Artifact storage artifact = _artifacts[artifactId];

         if (artifact.state == ArtifactState.Decayed) revert CannotMutateDecayedArtifact();
         if (_fluxBalances[msg.sender] < fluxCost) revert InsufficientFlux();

         _fluxBalances[msg.sender] -= fluxCost;

         // Apply decay before attempting mutation
         _applyDecay(artifactId, artifact);

         // Check if mutation is possible/desirable based on state/stability
         if (artifact.state == ArtifactState.Entangled) revert ArtifactInEntangledState(); // Entangled artifacts resist mutation?

         // Pseudo-random chance of success
         uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, artifactId, fluxCost, artifact.stability)));
         bool success = (seed % 100) < mutationSuccessChance;

         ArtifactState oldState = artifact.state;
         ArtifactState newState = artifact.state;
         string memory mutationDescription = "Mutation Attempt";

         if (success) {
             // Successful Mutation: Slightly alter composition, potentially boost/change state
             mutationDescription = "Mutation Successful";
             uint256 totalEssenceAmount = 0;
             for(uint256 i=0; i<artifact.essenceAmounts.length; i++) totalEssenceAmount += artifact.essenceAmounts[i];

             if (totalEssenceAmount > 0) {
                  // Example: randomly swap small amounts between essence types present or add/remove a small amount
                  uint256 indexToModify = seed % artifact.essenceComposition.length;
                  uint256 modificationAmount = (seed % 5) + 1; // Add/remove 1-5 particles

                  uint256 oldAmount = artifact.essenceAmounts[indexToModify];
                  uint256 essenceId = artifact.essenceComposition[indexToModify];

                  if ((seed % 2) == 0 && oldAmount > modificationAmount) { // 50% chance to remove
                       artifact.essenceAmounts[indexToModify] -= modificationAmount;
                       _particleBalances[msg.sender][essenceId] += modificationAmount; // Return particles
                       mutationDescription = string(abi.encodePacked(mutationDescription, " (Composition Reduced)"));
                  } else { // 50% chance to add (requires player has particles)
                       if (_particleBalances[msg.sender][essenceId] >= modificationAmount) {
                           artifact.essenceAmounts[indexToModify] += modificationAmount;
                           _particleBalances[msg.sender][essenceId] -= modificationAmount;
                           mutationDescription = string(abi.encodePacked(mutationDescription, " (Composition Increased)"));
                       } else if (_nextEssenceId > 1) { // Try adding a different random particle if possible
                           uint256 randomEssenceId = (seed % (_nextEssenceId - 1)) + 1;
                           if (_particleBalances[msg.sender][randomEssenceId] >= modificationAmount) {
                               // Add the new essence ID/amount if it wasn't there, or increase amount
                               bool found = false;
                               for(uint256 i=0; i<artifact.essenceComposition.length; i++){
                                   if(artifact.essenceComposition[i] == randomEssenceId){
                                       artifact.essenceAmounts[i] += modificationAmount;
                                       found = true;
                                       break;
                                   }
                               }
                               if(!found){
                                   // Add new composition entry - more complex, requires resizing arrays.
                                   // For simplicity here, let's only modify existing types or fail to add if new type needed.
                                   // Real implementation needs dynamic array resizing or different composition storage.
                                   // Simplification: just boost stability slightly instead of composition change if add fails
                                   artifact.stability += modificationAmount * 5; // Small stability boost
                                   mutationDescription = string(abi.encodePacked(mutationDescription, " (Stability Boost)"));
                               } else {
                                   _particleBalances[msg.sender][randomEssenceId] -= modificationAmount;
                                   mutationDescription = string(abi.encodePacked(mutationDescription, " (Composition Varied)"));
                               }
                           } else {
                                // Failed to add any particles, maybe just a state change?
                                mutationDescription = string(abi.encodePacked(mutationDescription, " (No Resource Change)"));
                           }
                       } else {
                           mutationDescription = string(abi.encodePacked(mutationDescription, " (No Resource Change)"));
                       }
                  }
                   // Recalculate complexity and possibly adjust stability based on new composition
                   // Skipping recalculation for simplicity in this example, but a real contract would do this.
                   // artifact.complexity = _calculateComplexity(artifact.essenceComposition, artifact.essenceAmounts);
                   // artifact.stability = _recalculateStabilityBasedOnComposition(artifact.essenceComposition, artifact.essenceAmounts, artifact.stability); // Blend old and new based on change
             } else {
                  // No essences, just flux used? Minimal change.
                  mutationDescription = string(abi.encodePacked(mutationDescription, " (Minimal Effect)"));
             }


             // State changes on success (e.g., Volatile becomes Stable, Dormant becomes Volatile)
             if (newState == ArtifactState.Volatile) newState = ArtifactState.Stable;
             else if (newState == ArtifactState.Dormant) newState = ArtifactState.Volatile;
             // Successful mutation on Stable could make it more complex but Volatile?
             else if (newState == ArtifactState.Stable && artifact.complexity > 100) newState = ArtifactState.Volatile; // Example complexity threshold

         } else {
             // Failed Mutation: Stability loss, potentially change state to Volatile or Decayed
             mutationDescription = "Mutation Failed";
             uint256 stabilityLoss = mutationVolatilityIncrease;
             if (stabilityLoss > artifact.stability) stabilityLoss = artifact.stability;
             artifact.stability -= stabilityLoss;
             mutationDescription = string(abi.encodePacked(mutationDescription, string(abi.encodePacked(" (Stability Loss: ", Strings.toString(stabilityLoss), ")"))));

             // State changes on failure
             if (artifact.stability == 0 && newState != ArtifactState.Entangled) newState = ArtifactState.Decayed;
             else if (newState == ArtifactState.Stable) newState = ArtifactState.Volatile;
         }

         if (oldState != newState) {
              artifact.state = newState;
              emit ArtifactStateChanged(artifactId, uint8(oldState), uint8(newState));
         }

         emit ArtifactMutated(artifactId, uint8(newState), mutationDescription);
    }


    function dismantleArtifact(uint256 artifactId) external whenNotPaused artifactExists(artifactId) isArtifactOwner(artifactId) {
        Artifact storage artifact = _artifacts[artifactId];

        if (artifact.state == ArtifactState.Entangled) revert CannotDismantleEntangledArtifact();

        // Apply decay before dismantling to ensure resources returned are based on current state
        _applyDecay(artifactId, artifact);

        // Calculate resources returned based on state and stability
        uint224 fluxReturned = 0; // Use uint224 for safety if total flux could exceed uint128
        mapping(uint256 => uint256) storage particlesReturned;
        uint256 particlesReturnedCount = 0; // Count of distinct particle types returned

        // Example logic:
        // - Decayed artifacts return minimal resources.
        // - Stable artifacts return more.
        // - Volatile/Dormant are in between.
        // - Amount also scaled by remaining stability.
        uint256 stabilityFactor = artifact.stability; // Max STABILITY_SCALE

        if (artifact.state == ArtifactState.Stable) {
             fluxReturned = uint224(artifact.complexity * stabilityFactor / STABILITY_SCALE / 10); // Scale by complexity & stability
             // Return a percentage of original particles based on stability
             for (uint256 i = 0; i < artifact.essenceComposition.length; i++) {
                  uint256 essenceId = artifact.essenceComposition[i];
                  uint256 originalAmount = artifact.essenceAmounts[i];
                  uint256 returnedAmount = (originalAmount * stabilityFactor) / STABILITY_SCALE; // Return up to 100%
                  if (returnedAmount > 0) {
                       particlesReturned[essenceId] += returnedAmount;
                       particlesReturnedCount++;
                  }
             }
        } else if (artifact.state == ArtifactState.Volatile || artifact.state == ArtifactState.Dormant) {
             fluxReturned = uint224(artifact.complexity * stabilityFactor / STABILITY_SCALE / 20); // Less flux than Stable
             // Return a smaller percentage of original particles
             for (uint256 i = 0; i < artifact.essenceComposition.length; i++) {
                  uint256 essenceId = artifact.essenceComposition[i];
                  uint256 originalAmount = artifact.essenceAmounts[i];
                  uint256 returnedAmount = (originalAmount * stabilityFactor) / (STABILITY_SCALE * 2); // Return up to 50%
                  if (returnedAmount > 0) {
                       particlesReturned[essenceId] += returnedAmount;
                       particlesReturnedCount++;
                  }
             }
        } else if (artifact.state == ArtifactState.Decayed) {
             // Minimal return
             fluxReturned = uint224(artifact.complexity * stabilityFactor / STABILITY_SCALE / 50); // Very little flux
             for (uint256 i = 0; i < artifact.essenceComposition.length; i++) {
                  uint256 essenceId = artifact.essenceComposition[i];
                  uint256 originalAmount = artifact.essenceAmounts[i];
                  uint256 returnedAmount = (originalAmount * stabilityFactor) / (STABILITY_SCALE * 10); // Very few particles (max 10%)
                  if (returnedAmount > 0) {
                       particlesReturned[essenceId] += returnedAmount;
                       particlesReturnedCount++;
                  }
             }
        }
        // No return for Entangled state as it's blocked by the check

        // Transfer returned resources
        if (fluxReturned > 0) {
            _fluxBalances[msg.sender] += fluxReturned;
        }
        for(uint256 essenceId = 1; essenceId < _nextEssenceId; essenceId++){
            if(particlesReturned[essenceId] > 0){
                _particleBalances[msg.sender][essenceId] += particlesReturned[essenceId];
            }
        }

        // Emit event before deleting artifact data
        emit ArtifactDismantled(msg.sender, artifactId, fluxReturned, particlesReturnedCount);

        // Delete the artifact data
        delete _artifacts[artifactId];
        _artifactExists[artifactId] = false;
    }

    function entangleArtifacts(uint256 artifactId1, uint256 artifactId2, uint256 fluxCost) external whenNotPaused artifactExists(artifactId1) artifactExists(artifactId2) {
        if (artifactId1 == artifactId2) revert CannotEntangleSelf();

        Artifact storage artifact1 = _artifacts[artifactId1];
        Artifact storage artifact2 = _artifacts[artifactId2];

        if (artifact1.owner != msg.sender || artifact2.owner != msg.sender) revert NotArtifactOwner(); // Both must be owned by caller
        if (_fluxBalances[msg.sender] < fluxCost) revert InsufficientFlux();

        // Apply decay before entanglement
        _applyDecay(artifactId1, artifact1);
        _applyDecay(artifactId2, artifact2);

        // Entanglement requires specific states? Example: only Stable or Volatile
        if (artifact1.state == ArtifactState.Decayed || artifact2.state == ArtifactState.Decayed) revert ArtifactInDecayedState();
        if (artifact1.state == ArtifactState.Entangled) revert ArtifactAlreadyEntangled(artifactId1);
        if (artifact2.state == ArtifactState.Entangled) revert ArtifactAlreadyEntangled(artifactId2);


        _fluxBalances[msg.sender] -= fluxCost;

        // Update states and entanglement lists
        ArtifactState oldState1 = artifact1.state;
        ArtifactState oldState2 = artifact2.state;

        artifact1.state = ArtifactState.Entangled;
        artifact2.state = ArtifactState.Entangled;

        artifact1.entangledWith.push(artifactId2);
        artifact2.entangledWith.push(artifactId1);

        emit ArtifactStateChanged(artifactId1, uint8(oldState1), uint8(ArtifactState.Entangled));
        emit ArtifactStateChanged(artifactId2, uint8(oldState2), uint8(ArtifactState.Entangled));
        emit ArtifactEntangled(artifactId1, artifactId2);
    }

    function dissipateEntanglement(uint256 artifactId1, uint256 artifactId2, uint256 fluxCost) external whenNotPaused artifactExists(artifactId1) artifactExists(artifactId2) {
         if (artifactId1 == artifactId2) revert CannotEntangleSelf(); // Still relevant check
         // Ensure consistent order for checks/storage if needed, but here order doesn't strictly matter for finding the link

         Artifact storage artifact1 = _artifacts[artifactId1];
         Artifact storage artifact2 = _artifacts[artifactId2];

         if (artifact1.owner != msg.sender || artifact2.owner != msg.sender) revert NotArtifactOwner();
         if (_fluxBalances[msg.sender] < fluxCost) revert InsufficientFlux();

         // Check if they are actually entangled with each other
         bool isEntangled1 = false;
         for(uint256 i=0; i < artifact1.entangledWith.length; i++){
             if(artifact1.entangledWith[i] == artifactId2){
                 isEntangled1 = true;
                 break;
             }
         }
         bool isEntangled2 = false;
          for(uint256 i=0; i < artifact2.entangledWith.length; i++){
             if(artifact2.entangledWith[i] == artifactId1){
                 isEntangled2 = true;
                 break;
             }
         }

         if (!isEntangled1 || !isEntangled2) revert ArtifactNotEntangled(artifactId1, artifactId2);


         _fluxBalances[msg.sender] -= fluxCost;

         // Apply decay before dissipating
         _applyDecay(artifactId1, artifact1);
         _applyDecay(artifactId2, artifact2);

         // Remove entanglement link (involves finding index and shifting/removing from dynamic array)
         // Solidity <0.6 doesn't have array.pop(index). Need to manual shift.
         // In 0.8+, swap-and-pop is common.
         uint256 index1 = artifact1.entangledWith.length; // Find index of artifact2 in artifact1's list
         for(uint256 i=0; i < artifact1.entangledWith.length; i++){
             if(artifact1.entangledWith[i] == artifactId2){
                 index1 = i;
                 break;
             }
         }
         artifact1.entangledWith[index1] = artifact1.entangledWith[artifact1.entangledWith.length - 1];
         artifact1.entangledWith.pop();

         uint256 index2 = artifact2.entangledWith.length; // Find index of artifact1 in artifact2's list
         for(uint256 i=0; i < artifact2.entangledWith.length; i++){
             if(artifact2.entangledWith[i] == artifactId1){
                 index2 = i;
                 break;
             }
         }
         artifact2.entangledWith[index2] = artifact2.entangledWith[artifact2.entangledWith.length - 1];
         artifact2.entangledWith.pop();

         // Change states (e.g., back to Dormant or Volatile depending on stability)
         ArtifactState oldState1 = artifact1.state;
         ArtifactState oldState2 = artifact2.state;

         // Determine new state based on post-decay stability
         artifact1.state = (artifact1.stability == 0) ? ArtifactState.Decayed : (artifact1.stability < STABILITY_SCALE / 4 ? ArtifactState.Volatile : ArtifactState.Dormant);
         artifact2.state = (artifact2.stability == 0) ? ArtifactState.Decayed : (artifact2.stability < STABILITY_SCALE / 4 ? ArtifactState.Volatile : ArtifactState.Dormant);


         if (oldState1 != artifact1.state) emit ArtifactStateChanged(artifactId1, uint8(oldState1), uint8(artifact1.state));
         if (oldState2 != artifact2.state) emit ArtifactStateChanged(artifactId2, uint8(oldState2), uint8(artifact2.state));

         emit ArtifactDissipatedEntanglement(artifactId1, artifactId2);
    }

    function transferArtifact(address recipient, uint256 artifactId) external whenNotPaused artifactExists(artifactId) isArtifactOwner(artifactId) {
        if (recipient == address(0)) revert Unauthorized();
        Artifact storage artifact = _artifacts[artifactId];

        // Apply decay before transferring to ensure receiving owner sees current state
        _applyDecay(artifactId, artifact);

        address oldOwner = artifact.owner;
        artifact.owner = recipient;

        // If artifact is entangled, this transfer might break entanglement or transfer the entangled *pair*?
        // Design Choice: Transferring an entangled artifact BREAKS entanglement with its partners.
        // A more complex design could transfer the whole entangled 'cluster'.
        // Let's break entanglement for simplicity.
        if(artifact.state == ArtifactState.Entangled){
             // Need to carefully iterate and remove self from partners' lists
             uint256[] memory partners = artifact.entangledWith; // Copy the list as we modify the original
             delete artifact.entangledWith; // Clear the list first

             for(uint256 i = 0; i < partners.length; i++){
                 uint256 partnerId = partners[i];
                 if(_artifactExists[partnerId]){ // Check if partner still exists
                     Artifact storage partner = _artifacts[partnerId];
                     // Find this artifactId in the partner's entangledWith list and remove it
                     uint256 selfIndex = partner.entangledWith.length;
                      for(uint256 j=0; j < partner.entangledWith.length; j++){
                         if(partner.entangledWith[j] == artifactId){
                             selfIndex = j;
                             break;
                         }
                     }
                     if(selfIndex < partner.entangledWith.length){ // Found it
                         partner.entangledWith[selfIndex] = partner.entangledWith[partner.entangledWith.length - 1];
                         partner.entangledWith.pop();
                     }
                     // Change partner state - e.g., back to Dormant or Volatile
                     ArtifactState oldPartnerState = partner.state;
                     partner.state = (partner.stability == 0) ? ArtifactState.Decayed : (partner.stability < STABILITY_SCALE / 4 ? ArtifactState.Volatile : ArtifactState.Dormant);
                     if (oldPartnerState != partner.state) emit ArtifactStateChanged(partnerId, uint8(oldPartnerState), uint8(partner.state));

                     emit ArtifactDissipatedEntanglement(artifactId, partnerId); // Emit for each broken link
                 }
             }
            // Change this artifact's state
            ArtifactState oldState = artifact.state;
            artifact.state = (artifact.stability == 0) ? ArtifactState.Decayed : (artifact.stability < STABILITY_SCALE / 4 ? ArtifactState.Volatile : ArtifactState.Dormant);
            if (oldState != artifact.state) emit ArtifactStateChanged(artifactId, uint8(oldState), uint8(artifact.state));
        }


        emit ArtifactTransferred(oldOwner, recipient, artifactId);
    }


    // --- Query/View Functions ---

    function getEssenceCount() external view returns (uint256) {
        return _nextEssenceId - 1;
    }

    function getEssenceProperties(uint256 essenceId) external view returns (EssenceProperties memory) {
        if (essenceId == 0 || essenceId >= _nextEssenceId) revert InvalidEssenceId();
        return essenceTypes[essenceId];
    }

    function getUserFluxBalance(address user) external view returns (uint256) {
        return _fluxBalances[user];
    }

    function getUserParticleBalance(address user, uint256 essenceId) external view returns (uint256) {
        if (essenceId == 0 || essenceId >= _nextEssenceId) revert InvalidEssenceId();
        return _particleBalances[user][essenceId];
    }

    function getLastFluxHarvestTime(address user) external view returns (uint64) {
         return _lastFluxHarvestTime[user];
    }

    function getTotalArtifactsForged() external view returns (uint256) {
        return _nextArtifactId - 1;
    }

    function getArtifactOwner(uint256 artifactId) external view artifactExists(artifactId) returns (address) {
        return _artifacts[artifactId].owner;
    }

    function getArtifactComposition(uint256 artifactId) external view artifactExists(artifactId) returns (uint256[] memory essenceIds, uint256[] memory amounts) {
        Artifact storage artifact = _artifacts[artifactId];
        return (artifact.essenceComposition, artifact.essenceAmounts);
    }

    // Helper view function to calculate potential decay without changing state
    function _calculatePotentialDecayAmount(uint256 artifactId, Artifact storage artifact) internal view returns (uint256 potentialLoss) {
        uint64 currentTime = uint64(block.timestamp);
        uint64 lastRelevantTime = artifact.lastDecayCheckTime > artifact.lastInteractionTime ? artifact.lastDecayCheckTime : artifact.lastInteractionTime;
        uint256 timeElapsed = currentTime - lastRelevantTime;

        if (timeElapsed == 0) return 0;

        uint256 totalDecayResistanceInfluence = 0;
         for (uint256 i = 0; i < artifact.essenceComposition.length; i++) {
            uint256 essenceId = artifact.essenceComposition[i];
            uint256 amount = artifact.essenceAmounts[i];
            // Check for valid essenceId before accessing properties
            if (essenceId > 0 && essenceId < _nextEssenceId && essenceTypes[essenceId].decayResistance > 0) {
                totalDecayResistanceInfluence += essenceTypes[essenceId].decayResistance * amount;
            }
        }
        uint256 adjustedResistance = totalDecayResistanceInfluence + 10; // Base resistance

        return (BASE_DECAY_RATE_PER_SECOND * timeElapsed * STABILITY_SCALE) / adjustedResistance;
    }


    function getArtifactDetails(uint256 artifactId) external view artifactExists(artifactId) returns (
        address owner,
        uint256[] memory essenceComposition,
        uint256[] memory essenceAmounts,
        uint64 creationTime,
        uint64 lastInteractionTime,
        uint256 stability, // Reflects potential decay
        uint256 complexity,
        ArtifactState state,
        uint224 potentialDecaySinceLastCheck // How much stability could be lost if decay is applied now
    ) {
        Artifact storage artifact = _artifacts[artifactId];
        uint256 currentStability = artifact.stability;
        uint256 decayAmount = 0;

        // Only calculate potential decay if state is not Decayed (decayed state stability is always 0)
        if (artifact.state != ArtifactState.Decayed) {
             decayAmount = _calculatePotentialDecayAmount(artifactId, artifact);
             if (decayAmount > currentStability) decayAmount = currentStability;
             currentStability = currentStability - decayAmount;
        }


        return (
            artifact.owner,
            artifact.essenceComposition,
            artifact.essenceAmounts,
            artifact.creationTime,
            artifact.lastInteractionTime,
            currentStability, // Return stability after potential decay
            artifact.complexity,
            artifact.state,
            uint224(decayAmount) // Return calculated potential decay
        );
    }

    function getArtifactState(uint256 artifactId) external view artifactExists(artifactId) returns (ArtifactState) {
         return _artifacts[artifactId].state;
    }

    function getArtifactStability(uint256 artifactId) external view artifactExists(artifactId) returns (uint256) {
        Artifact storage artifact = _artifacts[artifactId];
        if (artifact.state == ArtifactState.Decayed) return 0; // Decayed artifacts have 0 stability
        uint256 potentialDecay = _calculatePotentialDecayAmount(artifactId, artifact);
        uint256 currentStability = artifact.stability;
        if (potentialDecay > currentStability) return 0;
        return currentStability - potentialDecay; // Return stability after potential decay
    }

    function getArtifactComplexity(uint256 artifactId) external view artifactExists(artifactId) returns (uint256) {
        return _artifacts[artifactId].complexity;
    }

    function getEntangledArtifacts(uint256 artifactId) external view artifactExists(artifactId) returns (uint256[] memory) {
        return _artifacts[artifactId].entangledWith;
    }

     // Internal helper (not exposed as view function directly, but called by getArtifactDetails/Stability)
    // function calculatePotentialDecay(uint256 artifactId) internal view returns (uint256 potentialLoss) {
    //    Artifact storage artifact = _artifacts[artifactId];
    //    return _calculatePotentialDecayAmount(artifactId, artifact);
    // }


    // --- Utility/Helper for Development (Optional) ---
    // Function to allow owner to distribute initial resources for testing
    function ownerMintInitialResources(address user, uint256 fluxAmount, uint256 essenceId, uint256 particleAmount) external onlyOwner {
        if (user == address(0)) revert Unauthorized();
         if (essenceId == 0 || essenceId >= _nextEssenceId) revert InvalidEssenceId();

        _fluxBalances[user] += fluxAmount;
        _particleBalances[user][essenceId] += particleAmount;
        // No events for this as it's dev/testing
    }

    // Simple helper to convert uint256 to string (like OpenZeppelin's Strings.sol)
    // Not strictly required by the prompt if using OpenZeppelin but required if avoiding all open source.
    // Including a basic version here.
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
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }

}
```