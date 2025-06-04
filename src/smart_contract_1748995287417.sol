Okay, here is a Solidity smart contract concept called `QuantumFluctuations`. It aims to incorporate several interesting, advanced, and creative ideas beyond standard tokens or simple logic. It simulates a system of dynamic, interacting "Quantum Particles" with unpredictable states and complex rules.

It includes concepts like:
*   Dynamic State (particles whose state changes based on interactions, time, external data)
*   Conditional Ownership/Burning
*   Entanglements (relationships between particles that affect their behavior)
*   Observation Effect (user interaction changing particle state)
*   Resource Management (Energy and Noise)
*   Configurable System Dynamics (Dimensions, Fluctuation Rules)
*   Conditional Execution & Predictive Triggers (based on state or oracle data)
*   Cascading Effects
*   User Profiles and Permissions (Observers)
*   State Aggregation and Hashing

**Disclaimer:** This is a complex conceptual contract designed to fulfill the prompt's requirements. It contains simulated randomness and oracle interactions, which would require robust external implementations (like Chainlink VRF or Oracles) for production use. It is not audited and should not be used in a production environment without significant security review and testing. Implementing true, secure randomness and reliable oracle interaction on-chain is a major challenge.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumFluctuations
 * @dev A creative and complex smart contract simulating dynamic "Quantum Particles"
 *      with fluctuating states, entanglements, conditional ownership, and
 *      interactions influenced by internal rules, time, and simulated external data.
 *      It explores advanced concepts like dynamic state, conditional logic,
 *      resource management, and configurable system dynamics.
 */

// --- OUTLINE ---
// 1. Custom Errors
// 2. Events
// 3. Structs for data representation (Particle, FluctuationRule, ObserverProfile, PredictedEvent)
// 4. State Variables to store core data and configurations
// 5. Modifiers for access control and state checks
// 6. Constructor
// 7. Core Particle Management Functions (Create, Get, Update State)
// 8. Ownership & Transfer Functions (Conditional)
// 9. Interaction Functions (Observe, Entangle, Tunnel)
// 10. System Dynamics & Configuration Functions (Dimensions, Rules)
// 11. Resource Management Functions (Energy, Noise)
// 12. Conditional Execution & Scheduling Functions
// 13. Data Aggregation & Analysis Functions
// 14. Observer Profile & Permissions
// 15. Admin & Utility Functions
// 16. Internal Helper Functions

// --- FUNCTION SUMMARY ---
// (Total: 25 functions)

// Core Particle Management:
// 1. createQuantumParticle(uint256 initialEntropy) external: Creates a new particle with initial properties.
// 2. batchCreateParticles(uint256[] calldata initialEntropies) external: Creates multiple particles efficiently.
// 3. getParticleState(uint256 particleId) public view: Retrieves the current state parameters of a particle.
// 4. triggerRandomFluctuation(uint256 particleId) external: Triggers an internal, pseudo-random state change based on entropy and rules.
// 5. applyExternalFluctuation(uint256 particleId, bytes32 externalData) external: Applies a state change influenced by simulated external data (oracle).

// Ownership & Transfer:
// 6. getParticleOwner(uint256 particleId) public view: Gets the owner of a particle.
// 7. transferParticleConditional(uint256 particleId, address newOwner, uint256 requiredStateValue) external: Transfers ownership only if a state condition is met.
// 8. burnParticleConditional(uint256 particleId, uint256 requiredNoiseLevel) external: Burns a particle only if a noise level condition is met.

// Interaction Functions:
// 9. createEntanglement(uint256 particleId1, uint256 particleId2) external: Creates a link between two particles, affecting their intertwined state.
// 10. resolveEntanglement(uint256 entanglementId) external: Breaks an entanglement, potentially causing state collapse or release of energy.
// 11. observeParticle(uint256 particleId) external payable: Allows an observer to interact, potentially collapsing state randomness and costing energy/ether.
// 12. simulateQuantumTunneling(uint256 particleId, address targetOwner, uint256 energyCost) external payable: Simulates 'tunneling' a particle to a new owner under specific conditions and energy cost.

// System Dynamics & Configuration:
// 13. addDimension(bytes32 dimensionName, int256 initialInfluence) external onlyOwner: Adds a new influencing dimension to the system.
// 14. setDimensionInfluence(bytes32 dimensionName, int256 influence) external onlyOwner: Sets the impact level of a specific dimension on fluctuations.
// 15. setFluctuationRule(bytes32 ruleId, FluctuationRule calldata rule) external onlyOwner: Defines or updates a rule governing state fluctuations.
// 16. getDimensionInfluence(bytes32 dimensionName) public view: Gets the influence of a dimension.
// 17. getFluctuationRule(bytes32 ruleId) public view: Gets details of a fluctuation rule.

// Resource Management:
// 18. depositEnergy() external payable: Allows users to deposit Ether as 'Energy' for interactions.
// 19. generateQuantumNoise(uint256 particleId) external: Generates 'Noise' resource based on a particle's state or interactions.

// Conditional Execution & Scheduling:
// 20. executeConditionalAction(uint256 particleId, bytes4 actionSelector, bytes calldata actionData) external: Executes a generic action on a particle based on predefined conditions within the action logic. (Conceptual placeholder)
// 21. scheduleEventOnPredictedState(uint256 particleId, bytes32 oraclePredictionHash, uint64 executionTimestamp, bytes4 actionSelector, bytes calldata actionData) external: Schedules an action to be executed if the particle's state matches an oracle prediction hash at a future time. (Highly conceptual, requires oracle integration)

// Data Aggregation & Analysis:
// 22. aggregateParticleStates(uint256[] calldata particleIds) public view: Calculates an aggregate value or summary of states for a set of particles.
// 23. getContractStateHash() public view: Generates a hash representing the current significant state of the entire contract (e.g., parameters, number of particles).

// Observer Profile & Permissions:
// 24. createObserverProfile() external: Allows a user to create an 'Observer' profile to gain interaction permissions.
// 25. grantObserverPermission(address observer, uint256 particleId) external onlyOwner: Grants explicit observation permission for a specific particle. (Alternative/supplementary to profile)

contract QuantumFluctuations {

    // --- 1. Custom Errors ---
    error NotContractOwner();
    error ContractIsPaused();
    error ContractNotPaused();
    error ParticleDoesNotExist(uint256 particleId);
    error ParticleAlreadyExists(uint256 particleId);
    error NotParticleOwner(uint256 particleId, address caller);
    error ConditionNotMet(string conditionDescription);
    error InsufficientEnergy(uint256 required, uint256 available);
    error EntanglementDoesNotExist(uint256 entanglementId);
    error ParticlesAlreadyEntangled(uint256 particleId1, uint256 particleId2);
    error InvalidActionSelector(bytes4 selector);
    error OraclePredictionMismatch(bytes32 expectedHash, bytes32 actualHash);
    error ScheduledEventNotReady(uint64 executionTimestamp);
    error NoObserverProfile(address observer);
    error NotAuthorizedObserver(address observer, uint256 particleId);

    // --- 2. Events ---
    event ParticleCreated(uint256 particleId, address owner, uint256 initialEntropy);
    event ParticleStateFluctuated(uint256 particleId, uint256 newEntropy, int256 newEnergyLevel, bytes32 fluctuationType);
    event ParticleTransferred(uint256 particleId, address indexed oldOwner, address indexed newOwner);
    event ParticleBurned(uint256 particleId, address indexed owner);
    event EntanglementCreated(uint256 entanglementId, uint256 indexed particleId1, uint256 indexed particleId2);
    event EntanglementResolved(uint256 entanglementId);
    event ParticleObserved(uint256 particleId, address indexed observer, uint256 observationCost);
    event ParticleTunneled(uint256 particleId, address indexed oldOwner, address indexed newOwner);
    event DimensionAdded(bytes32 dimensionName, int256 initialInfluence);
    event DimensionInfluenceSet(bytes32 dimensionName, int256 influence);
    event FluctuationRuleSet(bytes32 ruleId);
    event EnergyDeposited(address indexed user, uint256 amount);
    event NoiseGenerated(uint256 indexed particleId, uint256 amount);
    event ConditionalActionExecuted(uint256 indexed particleId, bytes4 actionSelector);
    event PredictiveEventScheduled(uint256 indexed particleId, uint64 executionTimestamp);
    event PredictiveEventExecuted(uint256 indexed particleId, uint64 executionTimestamp);
    event ObserverProfileCreated(address indexed observer);
    event ObserverPermissionGranted(address indexed observer, uint256 indexed particleId);

    // --- 3. Structs ---
    struct Particle {
        uint256 entropy;       // A measure of internal state variability (e.g., 0-1000)
        int256 energyLevel;     // Represents internal energy (can be positive or negative)
        uint64 lastFluctuationTime; // Timestamp of the last state change
        bytes32[] activeDimensions; // List of dimensions currently influencing this particle
        uint256[] entangledWith; // List of entanglement IDs this particle is part of
        address owner;
        string metadataURI; // For potential off-chain metadata
    }

    struct FluctuationRule {
        int256 entropyChangeFactor;
        int256 energyChangeFactor;
        uint256 noiseGenerationFactor; // How much noise is generated by this fluctuation type
        mapping(bytes32 => int256) dimensionModifiers; // Influence of dimensions on this rule
    }

    struct Entanglement {
        uint256 particle1Id;
        uint256 particle2Id;
        uint256 creationTime;
        // Could add shared state parameters or influence factors here
    }

    struct ObserverProfile {
        bool exists;
        uint256 totalObservations;
        mapping(uint256 => bool) grantedPermissions; // Specific particle permissions
    }

    // Simplified struct for a scheduled event
    struct PredictedEvent {
        uint256 particleId;
        bytes32 oraclePredictionHash; // Hash of the state predicted by an oracle
        uint64 executionTimestamp;
        bytes4 actionSelector; // Selector of the function to call (conceptual)
        bytes calldata actionData; // Calldata for the function (conceptual)
        bool executed;
    }

    // --- 4. State Variables ---
    address private immutable i_owner;
    bool private s_paused;
    uint256 private s_totalSupply;
    uint256 private s_entanglementCounter; // To generate unique entanglement IDs
    uint256 private s_totalContractEnergy; // Total Ether held by the contract

    // Mappings for core data
    mapping(uint255 => Particle) private s_particles; // Particle ID -> Particle data (Using uint255 to avoid potential collision with type(uint256).max if used elsewhere)
    mapping(uint256 => Entanglement) private s_entanglements; // Entanglement ID -> Entanglement data

    // Configuration mappings
    mapping(bytes32 => int256) private s_dimensionInfluence; // Dimension Name -> Influence factor
    mapping(bytes32 => FluctuationRule) private s_fluctuationRules; // Rule ID -> Rule data

    // Resource mappings
    mapping(address => uint256) private s_observerEnergyBalances; // Observer Address -> Energy balance (Ether deposited)
    mapping(address => uint256) private s_observerNoiseLevels; // Observer Address -> Noise level

    // Observer mappings
    mapping(address => ObserverProfile) private s_observerProfiles;

    // Scheduled Events
    PredictedEvent[] private s_scheduledEvents; // Array of scheduled events

    // --- 5. Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NotContractOwner();
        _;
    }

    modifier whenNotPaused() {
        if (s_paused) revert ContractIsPaused();
        _;
    }

    modifier whenPaused() {
        if (!s_paused) revert ContractNotPaused();
        _;
    }

    modifier particleExists(uint256 particleId) {
        if (s_particles[uint255(particleId)].owner == address(0) && particleId != 0) revert ParticleDoesNotExist(particleId); // Check against zero address and non-zero ID
        _;
    }

    modifier isParticleOwner(uint256 particleId) {
        if (s_particles[uint255(particleId)].owner != msg.sender) revert NotParticleOwner(particleId, msg.sender);
        _;
    }

    modifier isObserver(address observer) {
        if (!s_observerProfiles[observer].exists) revert NoObserverProfile(observer);
        _;
    }

    modifier canObserveParticle(address observer, uint256 particleId) {
        if (!s_observerProfiles[observer].exists || !s_observerProfiles[observer].grantedPermissions[particleId]) {
             revert NotAuthorizedObserver(observer, particleId);
        }
        _;
    }


    // --- 6. Constructor ---
    constructor() {
        i_owner = msg.sender;
        s_paused = false;
        s_totalSupply = 0;
        s_entanglementCounter = 0;
        s_totalContractEnergy = 0;

        // Initialize some default dimensions and rules (example)
        s_dimensionInfluence["TimeFlow"] = 10;
        s_dimensionInfluence["CosmicRadiation"] = -5;

        s_fluctuationRules["StandardRandom"] = FluctuationRule({
            entropyChangeFactor: 50,
            energyChangeFactor: -10,
            noiseGenerationFactor: 5,
            dimensionModifiers: new mapping(bytes32 => int256)()
        });
        s_fluctuationRules["HighEnergyPulse"] = FluctuationRule({
            entropyChangeFactor: -100,
            energyChangeFactor: 200,
            noiseGenerationFactor: 50,
             dimensionModifiers: new mapping(bytes32 => int256)()
        });
        // Add dimension modifiers to rules after rule creation if needed
        s_fluctuationRules["StandardRandom"].dimensionModifiers["TimeFlow"] = 2;
        s_fluctuationRules["HighEnergyPulse"].dimensionModifiers["CosmicRadiation"] = -1;

    }

    receive() external payable {
        s_totalContractEnergy += msg.value;
        emit EnergyDeposited(msg.sender, msg.value);
    }

    fallback() external payable {
        s_totalContractEnergy += msg.value;
        emit EnergyDeposited(msg.sender, msg.value);
    }

    // --- 7. Core Particle Management ---

    /**
     * @dev Creates a new Quantum Particle.
     * @param initialEntropy The initial entropy value for the particle.
     */
    function createQuantumParticle(uint256 initialEntropy) external whenNotPaused {
        s_totalSupply++;
        uint256 particleId = s_totalSupply; // Simple ID based on total supply

        // Ensure the calculated ID is not already in use (belt and suspenders for this simple ID generation)
         if (s_particles[uint255(particleId)].owner != address(0)) revert ParticleAlreadyExists(particleId);

        s_particles[uint255(particleId)] = Particle({
            entropy: initialEntropy,
            energyLevel: 0,
            lastFluctuationTime: uint64(block.timestamp),
            activeDimensions: new bytes32[](0), // Start with no specific dimensions
            entangledWith: new uint256[](0),
            owner: msg.sender,
            metadataURI: ""
        });

        // Activate some initial dimensions based on entropy (example logic)
        if (initialEntropy > 500) {
            s_particles[uint255(particleId)].activeDimensions.push("TimeFlow");
        }

        emit ParticleCreated(particleId, msg.sender, initialEntropy);
    }

    /**
     * @dev Creates multiple particles efficiently.
     * @param initialEntropies An array of initial entropy values for the new particles.
     */
    function batchCreateParticles(uint256[] calldata initialEntropies) external whenNotPaused {
        for (uint256 i = 0; i < initialEntropies.length; i++) {
            s_totalSupply++;
            uint256 particleId = s_totalSupply;
             if (s_particles[uint255(particleId)].owner != address(0)) revert ParticleAlreadyExists(particleId); // Should not happen with sequential ID

            s_particles[uint255(particleId)] = Particle({
                entropy: initialEntropies[i],
                energyLevel: 0,
                lastFluctuationTime: uint64(block.timestamp),
                 activeDimensions: new bytes32[](0),
                 entangledWith: new uint256[](0),
                owner: msg.sender,
                metadataURI: ""
            });

             if (initialEntropies[i] > 500) {
                s_particles[uint255(particleId)].activeDimensions.push("TimeFlow");
            }
            emit ParticleCreated(particleId, msg.sender, initialEntropies[i]);
        }
    }

    /**
     * @dev Retrieves the current state parameters of a particle.
     * @param particleId The ID of the particle.
     * @return The particle's entropy, energy level, last fluctuation time, and metadata URI.
     */
    function getParticleState(uint256 particleId) public view particleExists(particleId) returns (uint256 entropy, int256 energyLevel, uint64 lastFluctuationTime, string memory metadataURI) {
        Particle storage particle = s_particles[uint255(particleId)];
        return (particle.entropy, particle.energyLevel, particle.lastFluctuationTime, particle.metadataURI);
    }

    /**
     * @dev Triggers an internal, pseudo-random state change based on entropy and rules.
     *      Uses a simple pseudo-random factor for demonstration. Not suitable for production.
     * @param particleId The ID of the particle to fluctuate.
     */
    function triggerRandomFluctuation(uint256 particleId) external whenNotPaused particleExists(particleId) {
        Particle storage particle = s_particles[uint255(particleId)];

        // --- Simulated Randomness (DO NOT USE IN PRODUCTION) ---
        // A real contract needs Chainlink VRF or similar.
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, particleId))) % 100; // Factor 0-99
        // --- End Simulated Randomness ---

        // Apply a default rule (e.g., "StandardRandom") modified by random factor
        bytes32 ruleId = "StandardRandom"; // Could be dynamic based on particle state
        FluctuationRule storage rule = s_fluctuationRules[ruleId];

        _applyFluctuationEffect(particle, rule, randomFactor);

        emit ParticleStateFluctuated(particleId, particle.entropy, particle.energyLevel, ruleId);
    }

    /**
     * @dev Applies a state change influenced by simulated external data.
     *      A real implementation would involve an oracle pattern (e.g., Chainlink).
     * @param particleId The ID of the particle to fluctuate.
     * @param externalData A simulated hash or data point from an external source.
     */
    function applyExternalFluctuation(uint256 particleId, bytes32 externalData) external whenNotPaused particleExists(particleId) {
        Particle storage particle = s_particles[uint255(particleId)];

        // --- Simulated Oracle Interaction ---
        // A real contract would verify a Chainlink oracle response or similar.
        // For this example, we just use the externalData to derive a factor.
        uint256 externalFactor = uint256(externalData) % 200; // Factor 0-199
        // --- End Simulated Oracle Interaction ---

        // Apply a different rule (e.g., "HighEnergyPulse") modified by external factor
        bytes32 ruleId = "HighEnergyPulse"; // Could be dynamic
         if (s_fluctuationRules[ruleId].entropyChangeFactor == 0 && s_fluctuationRules[ruleId].energyChangeFactor == 0) {
             // Rule doesn't exist or is empty, use a default
             ruleId = "StandardRandom";
         }
        FluctuationRule storage rule = s_fluctuationRules[ruleId];


        _applyFluctuationEffect(particle, rule, externalFactor);

        emit ParticleStateFluctuated(particleId, particle.entropy, particle.energyLevel, ruleId);
    }

     /**
     * @dev Sets the metadata URI for a particle. (Like ERC721 tokenURI)
     * @param particleId The ID of the particle.
     * @param uri The new metadata URI.
     */
    function setParticleMetadataURI(uint256 particleId, string calldata uri) external isParticleOwner(particleId) particleExists(particleId) {
        s_particles[uint255(particleId)].metadataURI = uri;
    }

    /**
     * @dev Gets the metadata URI for a particle.
     * @param particleId The ID of the particle.
     * @return The metadata URI.
     */
    function getParticleMetadataURI(uint256 particleId) public view particleExists(particleId) returns (string memory) {
        return s_particles[uint255(particleId)].metadataURI;
    }


    // --- 8. Ownership & Transfer ---

    /**
     * @dev Gets the current owner of a particle.
     * @param particleId The ID of the particle.
     * @return The owner's address.
     */
    function getParticleOwner(uint256 particleId) public view particleExists(particleId) returns (address) {
        return s_particles[uint255(particleId)].owner;
    }

    /**
     * @dev Transfers ownership of a particle to a new owner, but only if a specific state condition is met.
     * @param particleId The ID of the particle to transfer.
     * @param newOwner The address to transfer ownership to.
     * @param requiredStateValue A threshold value for the particle's entropy state.
     */
    function transferParticleConditional(uint256 particleId, address newOwner, uint256 requiredStateValue) external whenNotPaused isParticleOwner(particleId) particleExists(particleId) {
        Particle storage particle = s_particles[uint255(particleId)];

        // Example condition: Particle entropy must be above a threshold
        if (particle.entropy < requiredStateValue) {
            revert ConditionNotMet("Entropy below required value");
        }

        address oldOwner = particle.owner;
        particle.owner = newOwner;

        emit ParticleTransferred(particleId, oldOwner, newOwner);
    }

    /**
     * @dev Burns (destroys) a particle, but only if the owner's noise level meets a specific condition.
     * @param particleId The ID of the particle to burn.
     * @param requiredNoiseLevel A threshold value for the owner's noise level.
     */
    function burnParticleConditional(uint256 particleId, uint256 requiredNoiseLevel) external whenNotPaused isParticleOwner(particleId) particleExists(particleId) {
        // Example condition: Owner's noise level must be above a threshold
        if (s_observerNoiseLevels[msg.sender] < requiredNoiseLevel) {
            revert ConditionNotMet("Insufficient owner noise level");
        }

        address ownerToBurn = s_particles[uint255(particleId)].owner;

        // Note: Deleting from a mapping doesn't reduce storage cost unless it was previously set to a non-zero value
        delete s_particles[uint255(particleId)];
        // s_totalSupply is not decreased to keep IDs sequential, this creates 'gaps'.
        // A more complex system might manage a list of active IDs.

        // Decrease owner's noise as a potential effect of burning
        s_observerNoiseLevels[ownerToBurn] = s_observerNoiseLevels[ownerToBurn] < requiredNoiseLevel ? 0 : s_observerNoiseLevels[ownerToBurn] - requiredNoiseLevel;


        emit ParticleBurned(particleId, ownerToBurn);
    }


    // --- 9. Interaction Functions ---

    /**
     * @dev Creates an entanglement link between two particles.
     *      Entangled particles' states might influence each other.
     * @param particleId1 The ID of the first particle.
     * @param particleId2 The ID of the second particle.
     */
    function createEntanglement(uint256 particleId1, uint256 particleId2) external whenNotPaused particleExists(particleId1) particleExists(particleId2) {
        // Prevent self-entanglement
        if (particleId1 == particleId2) revert ConditionNotMet("Cannot entangle a particle with itself");

        // Check if they are already entangled (simple check against known entanglements)
        // A more robust check would iterate through particle.entangledWith lists
        for (uint256 i = 0; i < s_particles[uint255(particleId1)].entangledWith.length; i++) {
            uint256 existingEntanglementId = s_particles[uint255(particleId1)].entangledWith[i];
            if ((s_entanglements[existingEntanglementId].particle1Id == particleId2) || (s_entanglements[existingEntanglementId].particle2Id == particleId2)) {
                 revert ParticlesAlreadyEntangled(particleId1, particleId2);
            }
        }


        s_entanglementCounter++;
        uint256 entanglementId = s_entanglementCounter;

        s_entanglements[entanglementId] = Entanglement({
            particle1Id: particleId1,
            particle2Id: particleId2,
            creationTime: block.timestamp
        });

        // Update particle structs to reference the entanglement
        s_particles[uint255(particleId1)].entangledWith.push(entanglementId);
        s_particles[uint255(particleId2)].entangledWith.push(entanglementId);

        // Maybe trigger an initial fluctuation upon entanglement
        _applyEntanglementInfluence(particleId1, particleId2);

        emit EntanglementCreated(entanglementId, particleId1, particleId2);
    }

    /**
     * @dev Resolves (breaks) an entanglement link between two particles.
     *      Might cause state collapse or energy release.
     * @param entanglementId The ID of the entanglement to resolve.
     */
    function resolveEntanglement(uint256 entanglementId) external whenNotPaused {
        Entanglement storage entanglement = s_entanglements[entanglementId];

        if (entanglement.particle1Id == 0 && entanglement.particle2Id == 0) revert EntanglementDoesNotExist(entanglementId); // Check if entanglement exists

        uint256 p1Id = entanglement.particle1Id;
        uint256 p2Id = entanglement.particle2Id;

        // Remove entanglement reference from particles (basic example, requires careful array manipulation)
        // In reality, managing dynamic arrays like this in Solidity is gas-intensive and complex.
        // A common pattern is to mark as inactive rather than deleting.
        // For demonstration, we simulate removal:
        _removeEntanglementFromParticle(p1Id, entanglementId);
        _removeEntanglementFromParticle(p2Id, entanglementId);


        // Apply effects of resolution (e.g., state collapse, energy release)
        s_particles[uint255(p1Id)].entropy = s_particles[uint255(p1Id)].entropy / 2; // Example effect
        s_particles[uint255(p2Id)].energyLevel += 50; // Example effect

        delete s_entanglements[entanglementId]; // Remove the entanglement data

        emit EntanglementResolved(entanglementId);
        // Could also emit ParticleStateFluctuated events for p1 and p2
    }

    /**
     * @dev Allows an observer to interact with a particle, potentially collapsing state randomness,
     *      costing energy (Ether), and increasing owner's noise. Requires observer profile and permission.
     * @param particleId The ID of the particle to observe.
     */
    function observeParticle(uint256 particleId) external payable whenNotPaused particleExists(particleId) isObserver(msg.sender) canObserveParticle(msg.sender, particleId) {
        Particle storage particle = s_particles[uint255(particleId)];
        uint256 observationCost = 0.01 ether; // Example cost

        if (msg.value < observationCost) revert InsufficientEnergy(observationCost, msg.value);

        // Simulate state collapse or specific state change upon observation
        // Example: entropy is pushed towards an average or a fixed value
        particle.entropy = particle.entropy / 2 + 250; // Example: move towards 250
        particle.lastFluctuationTime = uint64(block.timestamp);

        // Increase the observer's noise level slightly (simulated effect)
        s_observerNoiseLevels[msg.sender] += 1;

        // Potentially send observation cost to the particle owner or burn it
        // payable(particle.owner).transfer(observationCost); // Simple transfer (might fail on reentrancy)
        // Or add to contract energy: s_totalContractEnergy += msg.value; (handled by receive/fallback)

        s_observerProfiles[msg.sender].totalObservations++;

        emit ParticleObserved(particleId, msg.sender, observationCost);
        emit ParticleStateFluctuated(particleId, particle.entropy, particle.energyLevel, "Observation");
    }

    /**
     * @dev Simulates 'tunneling' a particle to a new owner instantly,
     *      requiring specific particle state and energy cost.
     * @param particleId The ID of the particle to tunnel.
     * @param targetOwner The address the particle will tunnel to.
     * @param energyCost The amount of contract energy (Ether) required.
     */
    function simulateQuantumTunneling(uint256 particleId, address targetOwner, uint256 energyCost) external whenNotPaused particleExists(particleId) {
        Particle storage particle = s_particles[uint255(particleId)];

        // Example condition: Particle entropy must be in a 'tunnelable' range
        if (particle.entropy < 100 || particle.entropy > 800) {
             revert ConditionNotMet("Particle entropy not in tunnelable range");
        }

        // Check if sufficient contract energy is available (if energyCost > 0)
        if (energyCost > 0 && s_totalContractEnergy < energyCost) {
            revert InsufficientEnergy(energyCost, s_totalContractEnergy);
        }

        // Deduct energy from the contract
        if (energyCost > 0) {
             s_totalContractEnergy -= energyCost;
             // Note: This Ether is not sent anywhere in this example, just deducted conceptually.
             // It could be burned or sent to a treasury.
        }


        address oldOwner = particle.owner;
        particle.owner = targetOwner; // Instantaneous transfer

        // State change due to tunneling
        particle.entropy = particle.entropy % 50; // Example: randomizes/resets entropy

        emit ParticleTunneled(particleId, oldOwner, targetOwner);
        emit ParticleStateFluctuated(particleId, particle.entropy, particle.energyLevel, "Tunneling");
    }

     /**
     * @dev Calculates a conceptual 'strength' for an entanglement based on particle states and creation time.
     *      A view function demonstrating derived state.
     * @param entanglementId The ID of the entanglement.
     * @return A calculated strength value.
     */
    function calculateEntanglementStrength(uint256 entanglementId) public view returns (uint256) {
        Entanglement storage entanglement = s_entanglements[entanglementId];
        if (entanglement.particle1Id == 0 && entanglement.particle2Id == 0) return 0; // Non-existent

        // Example calculation: based on average entropy and entanglement duration
        Particle storage p1 = s_particles[uint255(entanglement.particle1Id)];
        Particle storage p2 = s_particles[uint255(entanglement.particle2Id)];

        uint256 averageEntropy = (p1.entropy + p2.entropy) / 2;
        uint256 duration = block.timestamp - entanglement.creationTime;

        // Avoid division by zero if duration is 0
        uint256 strength = averageEntropy * (duration == 0 ? 1 : duration);

        // Add influence from dimensions (example)
        for (uint256 i = 0; i < p1.activeDimensions.length; i++) {
            strength += uint256(s_dimensionInfluence[p1.activeDimensions[i]]);
        }
        for (uint256 i = 0; i < p2.activeDimensions.length; i++) {
             strength += uint256(s_dimensionInfluence[p2.activeDimensions[i]]);
        }


        return strength;
    }


    // --- 10. System Dynamics & Configuration ---

    /**
     * @dev Adds a new influencing dimension to the system dynamics. Only owner can call.
     * @param dimensionName The unique name of the dimension (e.g., "GravityWave").
     * @param initialInfluence The initial influence factor of this dimension.
     */
    function addDimension(bytes32 dimensionName, int256 initialInfluence) external onlyOwner {
        // Could add a check to ensure dimensionName doesn't exist
        s_dimensionInfluence[dimensionName] = initialInfluence;
        emit DimensionAdded(dimensionName, initialInfluence);
    }

    /**
     * @dev Sets the influence factor of an existing dimension. Only owner can call.
     * @param dimensionName The name of the dimension.
     * @param influence The new influence factor.
     */
    function setDimensionInfluence(bytes32 dimensionName, int256 influence) external onlyOwner {
        // Could add a check to ensure dimensionName exists
        s_dimensionInfluence[dimensionName] = influence;
        emit DimensionInfluenceSet(dimensionName, influence);
    }

    /**
     * @dev Defines or updates a rule governing state fluctuations. Only owner can call.
     * @param ruleId The unique ID of the rule (e.g., "MagneticStorm").
     * @param rule The FluctuationRule struct containing parameters.
     */
    function setFluctuationRule(bytes32 ruleId, FluctuationRule calldata rule) external onlyOwner {
        // Copy the rule data, including mapping elements (dimensionsModifiers)
        s_fluctuationRules[ruleId].entropyChangeFactor = rule.entropyChangeFactor;
        s_fluctuationRules[ruleId].energyChangeFactor = rule.energyChangeFactor;
        s_fluctuationRules[ruleId].noiseGenerationFactor = rule.noiseGenerationFactor;

        // Copy dimension modifiers - requires iterating through calldata keys/values, which is complex in Solidity
        // For simplicity in this example, we'll assume dimensionModifiers are set separately or via admin calls
        // s_fluctuationRules[ruleId].dimensionModifiers = rule.dimensionModifiers; // This won't work directly for mappings

        // Let's add a placeholder for setting a *specific* dimension modifier for a rule
        // Example: setFluctuationRuleDimensionModifier("StandardRandom", "TimeFlow", 3);
        // Adding a separate function for this is cleaner than trying to copy mapping from calldata.
        emit FluctuationRuleSet(ruleId);
    }

     /**
     * @dev Sets a specific dimension modifier within a fluctuation rule.
     * @param ruleId The ID of the fluctuation rule.
     * @param dimensionName The name of the dimension.
     * @param modifierValue The influence value of this dimension on this rule.
     */
    function setFluctuationRuleDimensionModifier(bytes32 ruleId, bytes32 dimensionName, int256 modifierValue) external onlyOwner {
        // Could add checks if ruleId and dimensionName exist
        s_fluctuationRules[ruleId].dimensionModifiers[dimensionName] = modifierValue;
    }


    /**
     * @dev Gets the influence factor of a dimension.
     * @param dimensionName The name of the dimension.
     * @return The influence factor.
     */
    function getDimensionInfluence(bytes32 dimensionName) public view returns (int256) {
        return s_dimensionInfluence[dimensionName];
    }

    /**
     * @dev Gets details of a fluctuation rule.
     * @param ruleId The ID of the rule.
     * @return The rule's parameters. Note: Mappings within structs cannot be returned directly.
     *         This example returns the base parameters only. Retrieving dimension modifiers would require a separate function.
     */
    function getFluctuationRule(bytes32 ruleId) public view returns (int256 entropyChangeFactor, int256 energyChangeFactor, uint256 noiseGenerationFactor) {
        FluctuationRule storage rule = s_fluctuationRules[ruleId];
        return (rule.entropyChangeFactor, rule.energyChangeFactor, rule.noiseGenerationFactor);
    }

    // --- 11. Resource Management ---

    /**
     * @dev Allows users to deposit Ether into the contract, representing 'Energy'.
     *      This Energy can be consumed by interactions like observation or tunneling.
     */
    // Already handled by receive/fallback, but adding an explicit function for clarity.
    // function depositEnergy() external payable {
    //     s_totalContractEnergy += msg.value;
    //     emit EnergyDeposited(msg.sender, msg.value);
    // }

    /**
     * @dev Allows the owner to withdraw accumulated contract energy.
     * @param amount The amount of Ether to withdraw.
     */
    function withdrawEnergy(uint256 amount) external onlyOwner {
        if (s_totalContractEnergy < amount) revert InsufficientEnergy(amount, s_totalContractEnergy);
        s_totalContractEnergy -= amount;
        payable(i_owner).transfer(amount); // Careful with transfer in complex contracts
    }

    /**
     * @dev Generates 'Noise' resource for a user based on a particle's state or interactions.
     *      Noise could represent accumulated uncertainty or side effects.
     * @param particleId The ID of the particle involved in noise generation.
     */
    function generateQuantumNoise(uint256 particleId) external whenNotPaused particleExists(particleId) {
        // Example logic: Generate noise based on particle entropy and energy level
        Particle storage particle = s_particles[uint255(particleId)];
        uint256 noiseAmount = particle.entropy / 100 + uint256(particle.energyLevel > 0 ? particle.energyLevel : 0) / 50;

        s_observerNoiseLevels[msg.sender] += noiseAmount;

        emit NoiseGenerated(particleId, noiseAmount);
    }

    /**
     * @dev Gets the energy balance of an observer (Ether deposited).
     * @param observer The observer's address.
     * @return The energy balance in Wei.
     */
    function getObserverEnergyBalance(address observer) public view returns (uint256) {
        return s_observerEnergyBalances[observer]; // Note: This mapping is not directly used in this code, `s_totalContractEnergy` holds combined energy. This function exists to show the *concept* of tracking user energy. A real implementation might use a separate token or per-user Ether tracking.
    }

    /**
     * @dev Gets the noise level of an observer.
     * @param observer The observer's address.
     * @return The noise level.
     */
    function getObserverNoiseLevel(address observer) public view returns (uint256) {
        return s_observerNoiseLevels[observer];
    }

    // --- 12. Conditional Execution & Scheduling ---

    /**
     * @dev Executes a generic action on a particle if specific, pre-defined conditions are met.
     *      This is a highly conceptual placeholder. Real implementation would need an action registry
     *      and a way to define and check complex conditions securely on-chain or via trusted off-chain logic.
     * @param particleId The ID of the particle.
     * @param actionSelector The function selector of the action to attempt (conceptual).
     * @param actionData Calldata for the action (conceptual).
     */
    function executeConditionalAction(uint256 particleId, bytes4 actionSelector, bytes calldata actionData) external whenNotPaused particleExists(particleId) {
        Particle storage particle = s_particles[uint255(particleId)];

        // --- Conceptual Condition Check ---
        bool conditionMet = false;
        // Example: Check if particle energy is high AND entropy is low
        if (particle.energyLevel > 100 && particle.entropy < 200) {
            conditionMet = true;
        }
        // --- End Conceptual Condition Check ---

        if (!conditionMet) {
             revert ConditionNotMet("Generic condition for action execution not met");
        }

        // --- Conceptual Action Execution ---
        // In a real system, this would involve a mapping from selector to function pointer or an internal dispatch.
        // This example does nothing but emit an event.
        // bytes memory callData = abi.encodePacked(actionSelector, actionData);
        // (bool success, bytes memory returndata) = address(this).delegatecall(callData);
        // require(success, string(returndata));
        // --- End Conceptual Action Execution ---

        // Simulate a state change caused by the action
        particle.energyLevel -= 50;
        particle.entropy += 10;

        emit ConditionalActionExecuted(particleId, actionSelector);
        emit ParticleStateFluctuated(particleId, particle.entropy, particle.energyLevel, "ConditionalAction");
    }


    /**
     * @dev Schedules an action to be executed if the particle's state hash matches a
     *      predicted hash from an oracle at a future timestamp.
     *      HIGHLY CONCEPTUAL - Requires sophisticated oracle and scheduling implementation.
     *      Calling this just adds an entry to an array. A separate function (e.g., `executeScheduledEvent`)
     *      would need to be called later (potentially by anyone, incentivized) to check and trigger execution.
     * @param particleId The ID of the particle.
     * @param oraclePredictionHash Hash representing the state predicted by the oracle at the execution time.
     * @param executionTimestamp The future timestamp when the state should be checked and action executed.
     * @param actionSelector The function selector of the action to execute (conceptual).
     * @param actionData Calldata for the action (conceptual).
     */
    function scheduleEventOnPredictedState(
        uint256 particleId,
        bytes32 oraclePredictionHash,
        uint64 executionTimestamp,
        bytes4 actionSelector,
        bytes calldata actionData // Note: storing calldata directly can be complex/expensive
    ) external whenNotPaused particleExists(particleId) {
        // Basic validation (timestamp in the future)
        if (executionTimestamp <= block.timestamp) {
            revert ConditionNotMet("Execution timestamp must be in the future");
        }

        // Store the scheduled event (simplified, actual calldata storage needs care)
        s_scheduledEvents.push(PredictedEvent({
            particleId: particleId,
            oraclePredictionHash: oraclePredictionHash,
            executionTimestamp: executionTimestamp,
            actionSelector: actionSelector,
            actionData: actionData, // Store as is for example; deep copy might be needed for complex data
            executed: false
        }));

        emit PredictiveEventScheduled(particleId, executionTimestamp);
    }

     /**
     * @dev Attempts to execute a scheduled event if the current time is past the execution timestamp
     *      and the particle's state hash matches the oracle's prediction.
     *      Anyone can call this, possibly incentivized (not implemented).
     *      HIGHLY CONCEPTUAL - Oracle interaction and state hashing are simplified.
     * @param eventIndex The index of the event in the scheduledEvents array.
     */
    function executeScheduledEvent(uint256 eventIndex) external whenNotPaused {
        // Basic check
        if (eventIndex >= s_scheduledEvents.length) revert ConditionNotMet("Invalid event index");

        PredictedEvent storage scheduledEvent = s_scheduledEvents[eventIndex];

        // Check if already executed
        if (scheduledEvent.executed) revert ConditionNotMet("Event already executed");

        // Check if current time is past execution time
        if (block.timestamp < scheduledEvent.executionTimestamp) revert ScheduledEventNotReady(scheduledEvent.executionTimestamp);

        // Check if particle exists and get its current state hash (SIMULATED)
        if (s_particles[uint255(scheduledEvent.particleId)].owner == address(0)) revert ParticleDoesNotExist(scheduledEvent.particleId); // Simplified check
        bytes32 currentParticleStateHash = _getParticleStateHash(scheduledEvent.particleId); // Simulated state hash

        // Check if current state hash matches the predicted hash
        if (currentParticleStateHash != scheduledEvent.oraclePredictionHash) {
            revert OraclePredictionMismatch(scheduledEvent.oraclePredictionHash, currentParticleStateHash);
        }

        // --- Execute the Action (Conceptual) ---
        // This is the part where `actionSelector` and `actionData` would be used
        // to call another function or trigger internal logic.
        // For this example, we just simulate a state change.
        Particle storage particle = s_particles[uint255(scheduledEvent.particleId)];
        particle.energyLevel += 100; // Example effect
        particle.lastFluctuationTime = uint64(block.timestamp);
        // --- End Conceptual Execution ---

        scheduledEvent.executed = true; // Mark as executed

        emit PredictiveEventExecuted(scheduledEvent.particleId, scheduledEvent.executionTimestamp);
         emit ParticleStateFluctuated(scheduledEvent.particleId, particle.entropy, particle.energyLevel, "PredictiveExecution");
    }

     /**
     * @dev Triggers a cascading fluctuation effect where changing one particle's state
     *      influences other particles it's entangled with or nearby (conceptually).
     * @param particleId The ID of the particle initiating the cascade.
     * @param cascadeIntensity A factor determining the strength of the cascade.
     */
    function triggerCascadingFluctuation(uint256 particleId, uint256 cascadeIntensity) external whenNotPaused particleExists(particleId) {
        // Get the initiating particle
        Particle storage initiatingParticle = s_particles[uint255(particleId)];

        // Apply direct fluctuation to the initiating particle first
        bytes32 ruleId = "HighEnergyPulse"; // Example rule for cascade source
         if (s_fluctuationRules[ruleId].entropyChangeFactor == 0) ruleId = "StandardRandom";
        _applyFluctuationEffect(initiatingParticle, s_fluctuationRules[ruleId], cascadeIntensity / 10);

         emit ParticleStateFluctuated(particleId, initiatingParticle.entropy, initiatingParticle.energyLevel, "CascadingSource");


        // Propagate effect to entangled particles
        for (uint256 i = 0; i < initiatingParticle.entangledWith.length; i++) {
            uint256 entanglementId = initiatingParticle.entangledWith[i];
            Entanglement storage entanglement = s_entanglements[entanglementId];

            uint256 otherParticleId;
            if (entanglement.particle1Id == particleId) {
                otherParticleId = entanglement.particle2Id;
            } else if (entanglement.particle2Id == particleId) {
                otherParticleId = entanglement.particle1Id;
            } else {
                // Should not happen if entangledWith list is correct
                continue;
            }

            // Apply a diluted fluctuation to the entangled particle
             if (s_particles[uint255(otherParticleId)].owner != address(0)) { // Ensure particle still exists
                Particle storage entangledParticle = s_particles[uint255(otherParticleId)];
                 bytes32 cascadeRuleId = "StandardRandom"; // Example rule for cascade effect
                 _applyFluctuationEffect(entangledParticle, s_fluctuationRules[cascadeRuleId], cascadeIntensity / 20); // Less intense effect

                 emit ParticleStateFluctuated(otherParticleId, entangledParticle.entropy, entangledParticle.energyLevel, "CascadingEffect");
             }
        }

        // Could also simulate effects on 'nearby' particles (conceptually, needs a spatial model)
        // This would likely require iterating through a subset of all particles, which is gas-intensive.
        // Skipping for this example.
    }


     /**
     * @dev Applies a time-dependent decay effect to a particle's state (e.g., entropy decreases over time).
     *      Can be called externally or triggered internally.
     * @param particleId The ID of the particle.
     */
    function applyTimeDecayToParticle(uint256 particleId) external whenNotPaused particleExists(particleId) {
        Particle storage particle = s_particles[uint255(particleId)];
        uint64 timePassed = uint64(block.timestamp) - particle.lastFluctuationTime;

        // Example decay logic: Entropy decays linearly with time passed, capped at minimum
        uint256 decayAmount = timePassed / 100; // 1 unit decay per 100 seconds
        if (particle.entropy > decayAmount) {
            particle.entropy -= decayAmount;
        } else {
            particle.entropy = 0; // Decay stops at 0
        }

        particle.lastFluctuationTime = uint64(block.timestamp); // Update last fluctuation time

        emit ParticleStateFluctuated(particleId, particle.entropy, particle.energyLevel, "TimeDecay");
    }


    // --- 13. Data Aggregation & Analysis ---

    /**
     * @dev Calculates an aggregate value (e.g., average entropy) for a set of particles.
     *      Demonstrates on-chain data aggregation.
     * @param particleIds An array of particle IDs.
     * @return The calculated aggregate entropy value.
     */
    function aggregateParticleStates(uint256[] calldata particleIds) public view returns (uint256 averageEntropy) {
        if (particleIds.length == 0) return 0;

        uint256 totalEntropy = 0;
        uint256 validParticleCount = 0;

        for (uint256 i = 0; i < particleIds.length; i++) {
             // Only include particles that exist
            if (s_particles[uint255(particleIds[i])].owner != address(0)) {
                totalEntropy += s_particles[uint255(particleIds[i])].entropy;
                validParticleCount++;
            }
        }

        if (validParticleCount == 0) return 0;
        return totalEntropy / validParticleCount;
    }

    /**
     * @dev Generates a hash representing the current significant state of the contract.
     *      Can be used for auditing, checkpoints, or triggering events based on global state.
     *      Note: Hashing complex state like mappings is tricky and often involves iterating
     *      over known keys or relying on Merkle proofs off-chain. This is a simplified hash.
     * @return A bytes32 hash representing the contract's state.
     */
    function getContractStateHash() public view returns (bytes32) {
        // Hash a few key parameters. This is NOT a secure representation of the FULL state.
        // A truly secure state hash would require iterating through ALL particles, entanglements, etc.
        // or using off-chain techniques with proofs.
        return keccak256(abi.encodePacked(
            s_totalSupply,
            s_entanglementCounter,
            s_totalContractEnergy,
            block.timestamp
            // Could include hashes of aggregate states of dimensions, rules, etc.
        ));
    }

     /**
     * @dev Gets the total number of particles created.
     * @return The total supply count.
     */
    function getTotalParticles() public view returns (uint256) {
        return s_totalSupply;
    }


    // --- 14. Observer Profile & Permissions ---

    /**
     * @dev Allows a user to create an 'Observer' profile.
     *      Having a profile grants access to certain interaction functions (like `observeParticle`).
     */
    function createObserverProfile() external whenNotPaused {
        if (s_observerProfiles[msg.sender].exists) {
            revert ConditionNotMet("Observer profile already exists");
        }
        s_observerProfiles[msg.sender].exists = true;
        s_observerProfiles[msg.sender].totalObservations = 0;
        // grantedPermissions mapping is initialized empty

        emit ObserverProfileCreated(msg.sender);
    }

    /**
     * @dev Grants explicit observation permission for a specific particle to an observer.
     *      This overrides/supplements the general requirement of having a profile.
     * @param observer The address of the observer.
     * @param particleId The ID of the particle.
     */
    function grantObserverPermission(address observer, uint256 particleId) external onlyOwner particleExists(particleId) isObserver(observer) {
        s_observerProfiles[observer].grantedPermissions[particleId] = true;
        emit ObserverPermissionGranted(observer, particleId);
    }

     /**
     * @dev Revokes explicit observation permission for a specific particle from an observer.
     * @param observer The address of the observer.
     * @param particleId The ID of the particle.
     */
    function revokeObserverPermission(address observer, uint256 particleId) external onlyOwner particleExists(particleId) isObserver(observer) {
        s_observerProfiles[observer].grantedPermissions[particleId] = false;
    }

    /**
     * @dev Checks if an address has an observer profile.
     * @param observer The address to check.
     * @return True if the address has a profile, false otherwise.
     */
    function hasObserverProfile(address observer) public view returns (bool) {
        return s_observerProfiles[observer].exists;
    }

    /**
     * @dev Checks if an observer has explicit permission to observe a particle.
     * @param observer The observer's address.
     * @param particleId The particle ID.
     * @return True if permission is granted, false otherwise.
     */
    function hasObserverPermission(address observer, uint256 particleId) public view returns (bool) {
        return s_observerProfiles[observer].grantedPermissions[particleId];
    }


    // --- 15. Admin & Utility Functions ---

    /**
     * @dev Pauses the contract, preventing most state-changing operations. Only owner can call.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        s_paused = true;
    }

    /**
     * @dev Unpauses the contract, allowing operations again. Only owner can call.
     */
    function unpauseContract() external onlyOwner whenPaused {
        s_paused = false;
    }

     /**
     * @dev Gets the current pause status of the contract.
     * @return True if paused, false otherwise.
     */
    function isPaused() public view returns (bool) {
        return s_paused;
    }

    /**
     * @dev Gets the owner of the contract.
     * @return The owner's address.
     */
    function owner() public view returns (address) {
        return i_owner;
    }

    // Note on Upgradeability: True contract upgradeability requires patterns like Proxy contracts (e.g., UUPS, Transparent).
    // This contract does not implement such a pattern. Mentioning "upgradeContract" conceptually
    // would imply deploying a new contract and migrating state, which is complex and beyond this scope.
    // A placeholder function is not helpful without the underlying proxy logic.

    // --- 16. Internal Helper Functions ---

    /**
     * @dev Internal function to apply fluctuation effects to a particle.
     * @param particle The particle struct storage pointer.
     * @param rule The fluctuation rule storage pointer.
     * @param intensityFactor A factor modifying the rule's intensity.
     */
    function _applyFluctuationEffect(Particle storage particle, FluctuationRule storage rule, uint256 intensityFactor) internal {
        // Apply entropy change based on rule factors and dimensions
        int256 totalEntropyChange = rule.entropyChangeFactor;
         for (uint256 i = 0; i < particle.activeDimensions.length; i++) {
             bytes32 dimName = particle.activeDimensions[i];
             totalEntropyChange += s_dimensionInfluence[dimName] * rule.dimensionModifiers[dimName];
         }
         // Adjust by intensity factor (example: scale change)
         totalEntropyChange = (totalEntropyChange * int256(intensityFactor)) / 100; // Scale by 0-100 factor

        // Update entropy (ensure it stays non-negative, or handle negative entropy conceptually)
        if (totalEntropyChange > 0) {
            particle.entropy += uint256(totalEntropyChange);
        } else if (uint256(-totalEntropyChange) <= particle.entropy) {
            particle.entropy -= uint256(-totalEntropyChange);
        } else {
            particle.entropy = 0; // Prevents underflow
        }


        // Apply energy change similarly
        int256 totalEnergyChange = rule.energyChangeFactor;
         for (uint256 i = 0; i < particle.activeDimensions.length; i++) {
             bytes32 dimName = particle.activeDimensions[i];
              totalEnergyChange += s_dimensionInfluence[dimName] * rule.dimensionModifiers[dimName];
         }
        totalEnergyChange = (totalEnergyChange * int256(intensityFactor)) / 100;

        particle.energyLevel += totalEnergyChange; // Energy can be negative

        // Generate noise based on rule and intensity
        uint256 noiseGenerated = (rule.noiseGenerationFactor * intensityFactor) / 100;
        // Add noise to particle's owner (if exists) or the contract's 'environmental' noise
        if (particle.owner != address(0)) {
             s_observerNoiseLevels[particle.owner] += noiseGenerated;
        } else {
            // Handle noise for unowned particles if applicable
        }


        particle.lastFluctuationTime = uint64(block.timestamp);

        // Note: Entanglement effects could be applied here too
         _applyEntanglementInfluenceOnFluctuation(particle);
    }

     /**
     * @dev Internal helper to apply influence from entangled particles during fluctuation.
     * @param particle The particle currently fluctuating.
     */
    function _applyEntanglementInfluenceOnFluctuation(Particle storage particle) internal {
        // Example: Entangled particles influence each other's energy levels during fluctuation
        for (uint256 i = 0; i < particle.entangledWith.length; i++) {
            uint256 entanglementId = particle.entangledWith[i];
            Entanglement storage entanglement = s_entanglements[entanglementId];

            uint256 otherParticleId;
            if (entanglement.particle1Id == particle.particleId) { // Needs particle.particleId - tricky without struct ID
                 // In a real implementation, structs might need to store their own ID or be indexed differently
                 // For this example, we'll skip direct entanglement influence during *this* fluctuation
                 // as mapping particle struct storage pointer back to its ID is non-trivial.
                 // Entanglement influence is better applied *when* entangled or resolved, or via a separate function.
            } else if (entanglement.particle2Id == particle.particleId) {
                 // Same issue
            }
        }
         // Revisit this: Applying entanglement influence here is complex due to struct storage vs ID.
         // Better to have a separate function that takes two particle IDs and applies mutual influence.
         // _applyEntanglementInfluence(particle.particleId, otherParticleId); // Conceptually
    }

     /**
     * @dev Internal helper to apply mutual influence when creating entanglement.
     * @param particleId1 ID of the first particle.
     * @param particleId2 ID of the second particle.
     */
    function _applyEntanglementInfluence(uint256 particleId1, uint256 particleId2) internal particleExists(particleId1) particleExists(particleId2) {
        Particle storage p1 = s_particles[uint255(particleId1)];
        Particle storage p2 = s_particles[uint255(particleId2)];

        // Example: Entanglement averages energy levels
        int256 averageEnergy = (p1.energyLevel + p2.energyLevel) / 2;
        p1.energyLevel = averageEnergy;
        p2.energyLevel = averageEnergy;

        // Example: Entanglement adds a conceptual "Entanglement" dimension influence
        bytes32 entanglementDimension = "Entanglement";
        if (s_dimensionInfluence[entanglementDimension] == 0) { // Add if not exists
            s_dimensionInfluence[entanglementDimension] = 1;
        }
        // Check if dimensions are already active before adding
        bool p1HasDim = false;
        for(uint i=0; i<p1.activeDimensions.length; i++) if(p1.activeDimensions[i] == entanglementDimension) p1HasDim = true;
        if(!p1HasDim) p1.activeDimensions.push(entanglementDimension);

        bool p2HasDim = false;
        for(uint i=0; i<p2.activeDimensions.length; i++) if(p2.activeDimensions[i] == entanglementDimension) p2HasDim = true;
        if(!p2HasDim) p2.activeDimensions.push(entanglementDimension);

        // Could also emit state fluctuation events here
    }


    /**
     * @dev Internal helper to remove an entanglement ID reference from a particle's list.
     *      Simplistic array manipulation, gas inefficient for large arrays.
     * @param particleId The ID of the particle.
     * @param entanglementIdToRemove The ID of the entanglement to remove.
     */
    function _removeEntanglementFromParticle(uint256 particleId, uint256 entanglementIdToRemove) internal particleExists(particleId) {
        Particle storage particle = s_particles[uint255(particleId)];
        uint256 len = particle.entangledWith.length;
        for (uint i = 0; i < len; i++) {
            if (particle.entangledWith[i] == entanglementIdToRemove) {
                // Swap with last element and pop (order doesn't matter here)
                if (i < len - 1) {
                    particle.entangledWith[i] = particle.entangledWith[len - 1];
                }
                particle.entangledWith.pop();
                break; // Assuming entanglement ID is unique in the list
            }
        }
    }

     /**
     * @dev Internal helper to generate a simplified hash of a particle's state.
     *      Used for conceptual oracle predictions. NOT cryptographically secure for proofs.
     * @param particleId The ID of the particle.
     * @return A hash of the particle's state.
     */
    function _getParticleStateHash(uint256 particleId) internal view particleExists(particleId) returns (bytes32) {
        Particle storage particle = s_particles[uint255(particleId)];
        // Hash key state parameters
        return keccak256(abi.encodePacked(
            particle.entropy,
            particle.energyLevel,
            particle.lastFluctuationTime
            // Exclude dynamic arrays like activeDimensions or entangledWith for simplicity
        ));
    }

}
```