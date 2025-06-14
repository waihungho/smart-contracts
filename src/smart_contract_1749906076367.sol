Okay, let's design a smart contract that simulates a concept based on "Quantum Entanglement" for digital assets or data points. This involves ideas like state superposition (represented by probabilities), entanglement between assets, and state collapse upon "observation," influencing entangled partners.

This concept is novel for smart contracts as it moves beyond standard token/NFT/DeFi mechanics into a more abstract, simulation-based protocol.

**Contract Name:** `QuantumEntanglementProtocol`

**Core Concept:** Manage digital 'Particles' that can exist in a superposition of predefined 'States'. Particles can be 'Entangled' in pairs. When a particle is 'Observed' (forcing it into a single state - collapse), its state influences the probability distribution of its entangled partner.

---

**Outline and Function Summary**

**Contract:** `QuantumEntanglementProtocol`

**Description:** A protocol for simulating quantum-like behavior on digital assets ("Particles"). Allows defining potential "States", creating Particles with initial state probabilities, entangling Particles, and "Observing" them to cause state collapse and influence entangled partners. Designed to explore complex conditional dependencies and emergent behavior in a simulated on-chain environment.

**Key Concepts Implemented:**
*   **Particles:** Unique digital assets managed by the contract.
*   **States:** Predefined potential conditions a Particle can be in (e.g., 'Spin Up', 'Spin Down', 'Alive', 'Dead', 'Red', 'Blue').
*   **Superposition:** Represented by a probability distribution over potential States for a Particle before observation.
*   **Entanglement:** Linking two Particles such that the Observation of one affects the probability distribution of the other.
*   **Observation:** The act of forcing a Particle into a single State, collapsing its superposition, and triggering influence on its entangled partner.
*   **Influence Factor:** A parameter determining the strength of correlation/influence between entangled partners upon observation.

**State Variables:**
*   `owner`: The contract owner (for administrative functions).
*   `paused`: Boolean indicating if the protocol is paused.
*   `particleCounter`: Counter for unique Particle IDs.
*   `entanglementCounter`: Counter for unique Entanglement IDs.
*   `stateTypes`: Mapping of State ID to `StateType` struct.
*   `particleData`: Mapping of Particle ID to `Particle` struct.
*   `entanglements`: Mapping of Entanglement ID to `Entanglement` struct.
*   `entangledPairs`: Mapping from Particle ID to its entangled partner's ID (simplified access).
*   `particleProbabilities`: Mapping `particleId => stateTypeId => probability` (probability in basis points, 0-10000).
*   `particleStateTypesList`: Mapping `particleId => list of state type IDs` relevant for this particle's probability distribution.
*   `observationCost`: Cost in wei to perform an observation.
*   `protocolFees`: Total fees collected.
*   `influenceFactor`: Parameter controlling state influence strength (0-10000).

**Structs:**
*   `StateType`: Represents a possible state (`id`, `name`).
*   `Particle`: Represents a particle (`id`, `owner`, `created`, `observedStateId` (0 if not observed), `entanglementId` (0 if not entangled), `metadataURI`, `observationDelegate`).
*   `Entanglement`: Represents an entanglement link (`id`, `particle1Id`, `particle2Id`, `active`, `created`).

**Enums:**
*   `ObservationStatus`: `Unobserved`, `Observed`.

**Modifiers:**
*   `onlyOwner`: Restricts access to the contract owner.
*   `whenNotPaused`: Allows execution only when the protocol is not paused.
*   `whenPaused`: Allows execution only when the protocol is paused.
*   `particleExists(uint256 _particleId)`: Checks if a particle ID is valid.
*   `onlyParticleOwnerOrDelegate(uint256 _particleId)`: Checks if caller is owner or delegate for a particle.
*   `onlyUnobserved(uint256 _particleId)`: Checks if a particle has not been observed yet.
*   `onlyEntangled(uint256 _particleId)`: Checks if a particle is entangled.

**Events:**
*   `ProtocolPaused(address indexed account)`
*   `ProtocolUnpaused(address indexed account)`
*   `StateTypeDefined(uint256 indexed stateTypeId, string name)`
*   `ParticleCreated(uint256 indexed particleId, address indexed owner, uint256 initialStateTypeId)`
*   `ProbabilitiesSet(uint256 indexed particleId, uint256[] stateTypeIds, uint256[] probabilities)`
*   `ParticlesEntangled(uint256 indexed entanglementId, uint256 indexed particle1Id, uint256 indexed particle2Id)`
*   `ParticlesUnentangled(uint256 indexed entanglementId, uint256 indexed particle1Id, uint256 indexed particle2Id)`
*   `ParticleObserved(uint256 indexed particleId, uint256 indexed observedStateId, address observer)`
*   `ParticleProbabilitiesUpdated(uint256 indexed particleId, uint256[] stateTypeIds, uint256[] newProbabilities)`
*   `ParticleTransfer(uint256 indexed particleId, address indexed from, address indexed to)`
*   `ObservationDelegateSet(uint256 indexed particleId, address indexed delegate)`
*   `ObservationDelegateRevoked(uint256 indexed particleId)`
*   `ObservationCostUpdated(uint256 newCost)`
*   `InfluenceFactorUpdated(uint256 newFactor)`
*   `FeesWithdrawn(address indexed to, uint256 amount)`
*   `ParticleReset(uint256 indexed particleId)`
*   `ParticleMetadataUpdated(uint256 indexed particleId, string uri)`

**Functions (Total: 28)**

1.  `constructor()`: Initializes the contract, sets owner and initial parameters.
2.  `defineStateType(uint256 _stateTypeId, string memory _name)`: Allows owner to define a new possible state type.
3.  `createParticle(uint256 _initialStateTypeId)`: Creates a new Particle owned by the caller. Requires the initial state type to be defined. Sets default initial probabilities (100% for initial state type, 0% for others).
4.  `setInitialProbabilities(uint256 _particleId, uint256[] memory _stateTypeIds, uint256[] memory _probabilities)`: Allows particle owner to set initial probability distribution *before* entanglement or observation. Probabilities must sum to 10000.
5.  `entangleParticles(uint256 _particleId1, uint256 _particleId2)`: Entangles two *unobserved, unentangled* particles owned by the caller. Creates a new entanglement.
6.  `unentangleParticles(uint256 _entanglementId)`: Allows owner of one of the entangled particles to break the entanglement.
7.  `observeParticle(uint256 _particleId, uint256 _observedStateTypeId)`: The core interaction. Allows owner or delegate to observe a particle, forcing it into `_observedStateTypeId`. Requires payment of `observationCost`. Triggers state collapse and influences the entangled partner's probabilities.
8.  `transferParticle(address _to, uint256 _particleId)`: Transfers ownership of a particle. Entanglements persist with the particle, but delegation is revoked.
9.  `delegateObservationRights(uint256 _particleId, address _delegate)`: Allows particle owner to delegate the right to `observeParticle` to another address.
10. `revokeObservationRights(uint256 _particleId)`: Allows particle owner to revoke observation delegation.
11. `setObservationCost(uint256 _cost)`: Owner function to update the cost of observation.
12. `withdrawFees(address _to)`: Owner function to withdraw accumulated protocol fees.
13. `pauseProtocol()`: Owner function to pause the contract (prevents state-changing interactions like create, entangle, observe, transfer).
14. `unpauseProtocol()`: Owner function to unpause the contract.
15. `resetParticleState(uint256 _particleId)`: Owner function to reset a particle's state (if observed) and probabilities back to its initial state configuration. Useful for simulations. Breaks entanglement.
16. `setInfluenceFactor(uint256 _factor)`: Owner function to set the `influenceFactor` (0-10000), controlling the strength of entanglement influence.
17. `setParticleMetadataURI(uint256 _particleId, string memory _uri)`: Allows particle owner to set a metadata URI (like an NFT tokenURI).
18. `getStateTypeName(uint256 _stateTypeId)`: Query function to get the name of a state type.
19. `getParticleOwner(uint256 _particleId)`: Query function to get the owner of a particle.
20. `getParticleState(uint256 _particleId)`: Query function to get the observed state ID of a particle (0 if unobserved).
21. `getParticleProbabilities(uint256 _particleId)`: Query function to get the current probability distribution for a particle.
22. `getEntangledPartner(uint256 _particleId)`: Query function to get the ID of a particle's entangled partner (0 if not entangled).
23. `isEntangled(uint256 _particleId)`: Query function to check if a particle is entangled.
24. `getObservationDelegate(uint256 _particleId)`: Query function to get the observation delegate for a particle.
25. `getParticleMetadataURI(uint256 _particleId)`: Query function to get the metadata URI for a particle.
26. `getEntanglementStatus(uint256 _particleId1, uint256 _particleId2)`: Query function to check if two specific particles are entangled.
27. `getObservationStatus(uint256 _particleId)`: Query function to check the observation status of a particle.
28. `getTotalParticles()`: Query function to get the total number of particles created.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline and Function Summary provided above the contract code.

/**
 * @title QuantumEntanglementProtocol
 * @dev A protocol for simulating quantum-like behavior on digital assets ("Particles").
 * Allows defining potential "States", creating Particles with initial state probabilities,
 * entangling Particles, and "Observing" them to cause state collapse and influence
 * entangled partners. Designed to explore complex conditional dependencies and emergent
 * behavior in a simulated on-chain environment.
 */
contract QuantumEntanglementProtocol {

    // --- Custom Errors ---
    error OnlyOwner();
    error Paused();
    error NotPaused();
    error ParticleDoesNotExist(uint256 particleId);
    error StateTypeDoesNotExist(uint256 stateTypeId);
    error NotParticleOwnerOrDelegate(uint256 particleId, address caller);
    error ParticleAlreadyObserved(uint256 particleId);
    error ParticlesAlreadyEntangled(uint256 particle1Id, uint256 particle2Id);
    error ParticleAlreadyEntangled(uint256 particleId);
    error ParticleNotEntangled(uint256 particleId);
    error CannotEntangleSelf();
    error InvalidProbabilitySum(uint256 totalProbability); // Probabilities must sum to 10000 (100%)
    error ProbabilityArrayMismatch();
    error InvalidObservedState(uint256 particleId, uint256 observedStateId); // State must be valid for particle
    error NotEnoughFunds(uint256 required, uint256 provided);
    error EntanglementDoesNotExist(uint256 entanglementId);
    error NotEntangledParty(uint256 entanglementId, uint256 particleId, address caller);
    error TargetIsNotEntangledPartner(uint256 particleId, uint256 targetParticleId);


    // --- Enums ---
    enum ObservationStatus { Unobserved, Observed }

    // --- Structs ---
    struct StateType {
        uint256 id;
        string name;
        // Could add compatibility scores, energy levels, etc. for more complex simulations
    }

    struct Particle {
        uint256 id;
        address owner;
        uint256 created;
        ObservationStatus observationStatus;
        uint256 observedStateId; // 0 if Unobserved
        uint256 entanglementId; // 0 if not entangled
        string metadataURI;
        address observationDelegate; // Address allowed to call observeParticle besides owner
        // Initial probability configuration, stored for reset capability
        uint256[] initialProbStateTypeIds;
        uint256[] initialProbabilities; // in basis points (0-10000)
    }

    struct Entanglement {
        uint256 id;
        uint256 particle1Id;
        uint256 particle2Id;
        bool active;
        uint256 created;
    }

    // --- State Variables ---
    address private immutable i_owner;
    bool private s_paused;

    uint256 private s_particleCounter;
    uint256 private s_entanglementCounter;

    // State Type Data: stateId => StateType
    mapping(uint256 => StateType) private s_stateTypes;
    // List of all defined state type IDs (for iteration)
    uint256[] private s_definedStateTypeIds;

    // Particle Data: particleId => Particle
    mapping(uint256 => Particle) private s_particleData;

    // Particle Probabilities: particleId => stateTypeId => probability (0-10000)
    mapping(uint256 => mapping(uint256 => uint256)) private s_particleProbabilities;

    // List of state type IDs relevant for a particle's probability distribution
    mapping(uint256 => uint256[]) private s_particleStateTypesList; // This helps iterate probabilities

    // Entanglement Data: entanglementId => Entanglement
    mapping(uint256 => Entanglement) private s_entanglements;
    // Simplified Entangled Pairs: particleId => entangledParticleId (0 if none)
    mapping(uint256 => uint256) private s_entangledPartners;

    uint256 private s_observationCost; // in wei
    uint256 private s_protocolFees;

    // Controls the strength of influence during observation (0-10000 basis points)
    uint256 private s_influenceFactor; // 10000 = 100% influence (strong correlation)

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert OnlyOwner();
        _;
    }

    modifier whenNotPaused() {
        if (s_paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!s_paused) revert NotPaused();
        _;
    }

    modifier particleExists(uint256 _particleId) {
        if (s_particleData[_particleId].id == 0 && _particleId != 0) revert ParticleDoesNotExist(_particleId);
        _;
    }

    modifier onlyParticleOwnerOrDelegate(uint256 _particleId) {
        address owner = s_particleData[_particleId].owner;
        address delegate = s_particleData[_particleId].observationDelegate;
        if (msg.sender != owner && msg.sender != delegate) revert NotParticleOwnerOrDelegate(_particleId, msg.sender);
        _;
    }

    modifier onlyUnobserved(uint256 _particleId) {
        if (s_particleData[_particleId].observationStatus == ObservationStatus.Observed) revert ParticleAlreadyObserved(_particleId);
        _;
    }

     modifier onlyEntangled(uint256 _particleId) {
        if (s_entangledPartners[_particleId] == 0) revert ParticleNotEntangled(_particleId);
        _;
    }

    // --- Events ---
    event ProtocolPaused(address indexed account);
    event ProtocolUnpaused(address indexed account);
    event StateTypeDefined(uint256 indexed stateTypeId, string name);
    event ParticleCreated(uint256 indexed particleId, address indexed owner, uint256 initialStateTypeId);
    event ProbabilitiesSet(uint256 indexed particleId, uint256[] stateTypeIds, uint200[] probabilities); // Using uint200 to fit in 8 feilds max for event data limit? Or split? Let's use uint256 for simplicity and handle potential large arrays off-chain.
    event ParticlesEntangled(uint256 indexed entanglementId, uint256 indexed particle1Id, uint256 indexed particle2Id);
    event ParticlesUnentangled(uint256 indexed entanglementId, uint256 indexed particle1Id, uint256 indexed particle2Id);
    event ParticleObserved(uint256 indexed particleId, uint256 indexed observedStateId, address observer);
    // Emitting the full probability map is too much, emit the particleId and maybe a hash or summary?
    // Let's emit the list of state types and corresponding probabilities. Could hit gas limits for large state lists.
    event ParticleProbabilitiesUpdated(uint256 indexed particleId, uint256[] stateTypeIds, uint256[] newProbabilities);
    event ParticleTransfer(uint256 indexed particleId, address indexed from, address indexed to);
    event ObservationDelegateSet(uint256 indexed particleId, address indexed delegate);
    event ObservationDelegateRevoked(uint256 indexed particleId);
    event ObservationCostUpdated(uint256 newCost);
    event InfluenceFactorUpdated(uint256 newFactor);
    event FeesWithdrawn(address indexed to, uint255 amount); // uint255 to avoid overflow with uint256 sum
    event ParticleReset(uint256 indexed particleId);
    event ParticleMetadataUpdated(uint256 indexed particleId, string uri);


    // --- Constructor ---
    constructor() {
        i_owner = msg.sender;
        s_paused = false;
        s_observationCost = 0.001 ether; // Example initial cost
        s_influenceFactor = 8000; // Example initial influence (80%)
        s_particleCounter = 0;
        s_entanglementCounter = 0;
        s_protocolFees = 0;

        // Define a couple of default state types (e.g., 1="DefaultA", 2="DefaultB")
        _defineStateType(1, "DefaultA");
        _defineStateType(2, "DefaultB");
    }

    // --- Admin Functions ---

    /**
     * @dev Pauses the protocol, preventing most state-changing functions.
     */
    function pauseProtocol() external onlyOwner whenNotPaused {
        s_paused = true;
        emit ProtocolPaused(msg.sender);
    }

    /**
     * @dev Unpauses the protocol, allowing state-changing functions.
     */
    function unpauseProtocol() external onlyOwner whenPaused {
        s_paused = false;
        emit ProtocolUnpaused(msg.sender);
    }

    /**
     * @dev Allows the owner to define a new possible state type.
     * @param _stateTypeId The unique ID for the new state type.
     * @param _name The name of the state type.
     */
    function defineStateType(uint256 _stateTypeId, string memory _name) external onlyOwner whenNotPaused {
        if (s_stateTypes[_stateTypeId].id != 0) revert("State type ID already exists");
        if (_stateTypeId == 0) revert("State type ID must be non-zero");
        s_stateTypes[_stateTypeId] = StateType({
            id: _stateTypeId,
            name: _name
        });
        s_definedStateTypeIds.push(_stateTypeId); // Add to the list of all defined types
        emit StateTypeDefined(_stateTypeId, _name);
    }

    /**
     * @dev Allows the owner to update the cost for observing a particle.
     * @param _cost The new observation cost in wei.
     */
    function setObservationCost(uint256 _cost) external onlyOwner {
        s_observationCost = _cost;
        emit ObservationCostUpdated(_cost);
    }

    /**
     * @dev Allows the owner to set the influence factor.
     * @param _factor The new influence factor (0-10000 basis points).
     */
    function setInfluenceFactor(uint256 _factor) external onlyOwner {
        if (_factor > 10000) revert("Influence factor cannot exceed 10000");
        s_influenceFactor = _factor;
        emit InfluenceFactorUpdated(_factor);
    }

    /**
     * @dev Allows the owner to withdraw accumulated protocol fees.
     * @param _to The address to send the fees to.
     */
    function withdrawFees(address _to) external onlyOwner {
        uint256 fees = s_protocolFees;
        s_protocolFees = 0;
        // Using call to prevent reentrancy issues compared to transfer/send
        (bool success, ) = payable(_to).call{value: fees}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(_to, uint255(fees)); // Cast to uint255 for event, fits in 8 fields
    }

    /**
     * @dev Resets a particle's state and probabilities back to its initial configuration.
     * Breaks any entanglement. Only callable by owner for simulation resets.
     * @param _particleId The ID of the particle to reset.
     */
    function resetParticleState(uint256 _particleId) external onlyOwner whenNotPaused particleExists(_particleId) {
        Particle storage particle = s_particleData[_particleId];

        // Break entanglement if any
        if (particle.entanglementId != 0) {
            _unentangleParticles(particle.entanglementId);
        }

        // Reset observation status and observed state
        particle.observationStatus = ObservationStatus.Unobserved;
        particle.observedStateId = 0;
        particle.observationDelegate = address(0); // Revoke any delegation

        // Reset probabilities to initial state
        // Clear current probabilities for this particle
        for (uint i = 0; i < s_particleStateTypesList[_particleId].length; i++) {
            s_particleProbabilities[_particleId][s_particleStateTypesList[_particleId][i]] = 0;
        }
        // Set probabilities from initial config
        s_particleStateTypesList[_particleId] = particle.initialProbStateTypeIds; // Restore list of relevant states
        for (uint i = 0; i < particle.initialProbStateTypeIds.length; i++) {
            s_particleProbabilities[_particleId][particle.initialProbStateTypeIds[i]] = particle.initialProbabilities[i];
        }

        emit ParticleReset(_particleId);
        emit ParticleProbabilitiesUpdated(_particleId, particle.initialProbStateTypeIds, particle.initialProbabilities);
    }


    // --- Particle Management Functions ---

    /**
     * @dev Creates a new Particle owned by the caller.
     * Sets initial probability to 100% for `_initialStateTypeId`.
     * @param _initialStateTypeId The state type ID to give the particle 100% probability initially.
     * Must be a defined state type.
     * @return The ID of the newly created particle.
     */
    function createParticle(uint256 _initialStateTypeId) external whenNotPaused {
        if (s_stateTypes[_initialStateTypeId].id == 0) revert StateTypeDoesNotExist(_initialStateTypeId);

        s_particleCounter++;
        uint256 newParticleId = s_particleCounter;

        // Prepare initial probabilities: 100% for the chosen state, 0% for others
        uint256[] memory initialProbStateTypeIds;
        uint256[] memory initialProbabilities;

        // Check if initial state type is one of the globally defined ones.
        bool foundInitialType = false;
        for(uint i=0; i < s_definedStateTypeIds.length; i++) {
            if (s_definedStateTypeIds[i] == _initialStateTypeId) {
                foundInitialType = true;
                break;
            }
        }
        if (!foundInitialType) revert StateTypeDoesNotExist(_initialStateTypeId);


        uint numDefinedStates = s_definedStateTypeIds.length;
        initialProbStateTypeIds = new uint256[](numDefinedStates);
        initialProbabilities = new uint256[](numDefinedStates);

        uint currentProbIndex = 0;
         for(uint i=0; i < numDefinedStates; i++) {
            uint256 stateTypeId = s_definedStateTypeIds[i];
            initialProbStateTypeIds[currentProbIndex] = stateTypeId;
            if (stateTypeId == _initialStateTypeId) {
                initialProbabilities[currentProbIndex] = 10000; // 100% in basis points
            } else {
                initialProbabilities[currentProbIndex] = 0;
            }
             s_particleProbabilities[newParticleId][stateTypeId] = initialProbabilities[currentProbIndex]; // Store in mapping directly
             currentProbIndex++;
        }

        // Store the list of state types relevant for this particle's probabilities
        s_particleStateTypesList[newParticleId] = initialProbStateTypeIds;


        s_particleData[newParticleId] = Particle({
            id: newParticleId,
            owner: msg.sender,
            created: block.timestamp,
            observationStatus: ObservationStatus.Unobserved,
            observedStateId: 0,
            entanglementId: 0,
            metadataURI: "",
            observationDelegate: address(0),
            initialProbStateTypeIds: initialProbStateTypeIds, // Store initial config
            initialProbabilities: initialProbabilities
        });


        emit ParticleCreated(newParticleId, msg.sender, _initialStateTypeId);
        emit ProbabilitiesSet(newParticleId, initialProbStateTypeIds, initialProbabilities);

        // Return the ID of the new particle
        // This return value won't be directly accessible from external transactions,
        // but helpful for simulation scripts or future cross-contract calls.
        // return newParticleId; // Functions emitting events usually return nothing externally
    }

     /**
     * @dev Allows the particle owner to set the initial probability distribution before observation/entanglement.
     * Sum of probabilities must be 10000 (100%). Only for unobserved, unentangled particles.
     * @param _particleId The ID of the particle.
     * @param _stateTypeIds The list of state type IDs for the distribution.
     * @param _probabilities The list of probabilities (0-10000 basis points) corresponding to _stateTypeIds.
     */
    function setInitialProbabilities(
        uint256 _particleId,
        uint256[] memory _stateTypeIds,
        uint256[] memory _probabilities
    ) external whenNotPaused particleExists(_particleId) onlyParticleOwnerOrDelegate(_particleId) onlyUnobserved(_particleId) { // Also needs to be unentangled? Yes.
         if (s_entangledPartners[_particleId] != 0) revert ParticleAlreadyEntangled(_particleId);
         if (_stateTypeIds.length != _probabilities.length) revert ProbabilityArrayMismatch();

        uint256 totalProbability = 0;
        // Validate state types and sum probabilities
        for (uint i = 0; i < _stateTypeIds.length; i++) {
            if (s_stateTypes[_stateTypeIds[i]].id == 0) revert StateTypeDoesNotExist(_stateTypeIds[i]);
            totalProbability += _probabilities[i];
        }

        if (totalProbability != 10000) revert InvalidProbabilitySum(totalProbability);

        // Clear current probabilities for this particle
         for (uint i = 0; i < s_particleStateTypesList[_particleId].length; i++) {
            s_particleProbabilities[_particleId][s_particleStateTypesList[_particleId][i]] = 0;
        }

        // Store the new probabilities
        s_particleStateTypesList[_particleId] = _stateTypeIds; // Update list of relevant states
        for (uint i = 0; i < _stateTypeIds.length; i++) {
            s_particleProbabilities[_particleId][_stateTypeIds[i]] = _probabilities[i];
        }

        // Update the particle's initial config backup (for reset)
        s_particleData[_particleId].initialProbStateTypeIds = _stateTypeIds;
        s_particleData[_particleId].initialProbabilities = _probabilities;


        emit ProbabilitiesSet(_particleId, _stateTypeIds, _probabilities);
    }


    /**
     * @dev Entangles two unobserved, unentangled particles owned by the caller.
     * @param _particleId1 The ID of the first particle.
     * @param _particleId2 The ID of the second particle.
     */
    function entangleParticles(uint256 _particleId1, uint256 _particleId2) external whenNotPaused
        particleExists(_particleId1)
        particleExists(_particleId2)
        onlyParticleOwnerOrDelegate(_particleId1) // Must own/delegate both? Or just one? Let's say caller must own/delegate *both*.
        onlyParticleOwnerOrDelegate(_particleId2)
        onlyUnobserved(_particleId1)
        onlyUnobserved(_particleId2)
    {
        if (_particleId1 == _particleId2) revert CannotEntangleSelf();
        if (s_entangledPartners[_particleId1] != 0 || s_entangledPartners[_particleId2] != 0) {
             if (s_entangledPartners[_particleId1] != 0) revert ParticleAlreadyEntangled(_particleId1);
             if (s_entangledPartners[_particleId2] != 0) revert ParticleAlreadyEntangled(_particleId2);
        }
         // Double check if they are somehow already entangled with each other
        if (s_entangledPartners[_particleId1] == _particleId2 || s_entangledPartners[_particleId2] == _particleId1) revert ParticlesAlreadyEntangled(_particleId1, _particleId2);


        s_entanglementCounter++;
        uint256 newEntanglementId = s_entanglementCounter;

        s_entanglements[newEntanglementId] = Entanglement({
            id: newEntanglementId,
            particle1Id: _particleId1,
            particle2Id: _particleId2,
            active: true,
            created: block.timestamp
        });

        s_entangledPartners[_particleId1] = _particleId2;
        s_entangledPartners[_particleId2] = _particleId1;

        s_particleData[_particleId1].entanglementId = newEntanglementId;
        s_particleData[_particleId2].entanglementId = newEntanglementId;

        emit ParticlesEntangled(newEntanglementId, _particleId1, _particleId2);
    }

     /**
     * @dev Breaks an entanglement. Callable by the owner/delegate of either particle involved.
     * Entangled particles must not have been observed yet to be unentangled this way.
     * Once one is observed, entanglement is effectively "broken" by collapse anyway,
     * but this function allows intentional disentanglement before observation.
     * @param _entanglementId The ID of the entanglement to break.
     */
    function unentangleParticles(uint256 _entanglementId) external whenNotPaused entanglementDoesNotExist(_entanglementId) {
        Entanglement storage entanglement = s_entanglements[_entanglementId];
        if (!entanglement.active) revert("Entanglement not active"); // Already broken

        uint256 p1Id = entanglement.particle1Id;
        uint256 p2Id = entanglement.particle2Id;

        // Caller must be owner/delegate of one of the particles
        if (msg.sender != s_particleData[p1Id].owner && msg.sender != s_particleData[p1Id].observationDelegate &&
            msg.sender != s_particleData[p2Id].owner && msg.sender != s_particleData[p2Id].observationDelegate) {
             revert NotEntangledParty(_entanglementId, 0, msg.sender); // Use 0 for particle ID as it could be either
        }

        // Entanglement breaks upon observation anyway, this is for pre-observation disentanglement
        if (s_particleData[p1Id].observationStatus == ObservationStatus.Observed ||
            s_particleData[p2Id].observationStatus == ObservationStatus.Observed) {
             revert("Cannot unentangle observed particles via this function");
        }

        _unentangleParticles(_entanglementId);
    }

    /**
     * @dev Internal function to perform the unentanglement logic.
     * @param _entanglementId The ID of the entanglement to break.
     */
    function _unentangleParticles(uint256 _entanglementId) internal {
        Entanglement storage entanglement = s_entanglements[_entanglementId];
        if (!entanglement.active) return; // Already inactive

        uint256 p1Id = entanglement.particle1Id;
        uint256 p2Id = entanglement.particle2Id;

        entanglement.active = false; // Mark entanglement as inactive

        // Update particles
        s_particleData[p1Id].entanglementId = 0;
        s_particleData[p2Id].entanglementId = 0;

        // Update simplified mapping
        delete s_entangledPartners[p1Id];
        delete s_entangledPartners[p2Id];

        emit ParticlesUnentangled(_entanglementId, p1Id, p2Id);
    }


    /**
     * @dev Observes a particle, forcing it into a single state and influencing its partner.
     * Callable by particle owner or delegate. Requires payment of observationCost.
     * Can only be called once per particle (unless reset by owner).
     * @param _particleId The ID of the particle to observe.
     * @param _observedStateTypeId The state type ID to force the particle into.
     */
    function observeParticle(uint256 _particleId, uint256 _observedStateTypeId) payable external whenNotPaused
        particleExists(_particleId)
        onlyParticleOwnerOrDelegate(_particleId)
        onlyUnobserved(_particleId)
    {
        if (msg.value < s_observationCost) revert NotEnoughFunds(s_observationCost, msg.value);

        // Transfer observation cost to protocol fees
        s_protocolFees += msg.value;

        Particle storage particle = s_particleData[_particleId];
        if (s_stateTypes[_observedStateTypeId].id == 0) revert StateTypeDoesNotExist(_observedStateTypeId);

        // Check if the observed state type is one the particle can be in
        bool isValidStateForParticle = false;
        uint256[] memory particleStates = s_particleStateTypesList[_particleId];
        for(uint i=0; i < particleStates.length; i++) {
            if (particleStates[i] == _observedStateTypeId) {
                isValidStateForParticle = true;
                break;
            }
        }
        if (!isValidStateForParticle) revert InvalidObservedState(_particleId, _observedStateTypeId);


        // 1. State Collapse: Set the particle's state and observation status
        particle.observationStatus = ObservationStatus.Observed;
        particle.observedStateId = _observedStateTypeId;

        // After collapse, probability is 100% for observed state, 0% for others
        for (uint i = 0; i < particleStates.length; i++) {
            s_particleProbabilities[_particleId][particleStates[i]] = (particleStates[i] == _observedStateTypeId) ? 10000 : 0;
        }
         // Emit updated probabilities for the observed particle
        emit ParticleProbabilitiesUpdated(_particleId, particleStates, _getProbabilitiesArray(_particleId));


        emit ParticleObserved(_particleId, _observedStateTypeId, msg.sender);


        // 2. Influence Entangled Partner (if any and unobserved)
        uint256 partnerId = s_entangledPartners[_particleId];
        if (partnerId != 0 && s_particleData[partnerId].observationStatus == ObservationStatus.Unobserved) {
            _influencePartner(_particleId, partnerId, _observedStateTypeId);

            // Entanglement effectively "breaks" after one particle is observed in this model
            // We could choose to keep the link but mark it as 'collapsed', or just break it.
            // Let's break the active link and set entanglementId to 0 for both.
            uint256 entanglementId = particle.entanglementId;
             if (entanglementId != 0) { // Should always be true if partnerId is not 0
                 s_entanglements[entanglementId].active = false;
                 s_particleData[_particleId].entanglementId = 0; // Update current particle's link
                 s_particleData[partnerId].entanglementId = 0; // Update partner's link
                 delete s_entangledPartners[_particleId]; // Remove simplified link
                 delete s_entangledPartners[partnerId]; // Remove simplified link
                 emit ParticlesUnentangled(entanglementId, _particleId, partnerId);
             }
        }
    }

    /**
     * @dev Internal function to calculate and apply influence on the entangled partner's probabilities.
     * This is a simplified simulation of quantum influence.
     * Rule: Observed state's probability is boosted on partner, others are reduced proportionally.
     * @param _influencingParticleId The ID of the particle that was just observed.
     * @param _influencedParticleId The ID of the entangled partner to influence.
     * @param _observedStateTypeId The state the influencing particle collapsed into.
     */
    function _influencePartner(uint256 _influencingParticleId, uint256 _influencedParticleId, uint256 _observedStateTypeId) internal {
         uint256[] memory partnerStateTypes = s_particleStateTypesList[_influencedParticleId];
         uint256 numStates = partnerStateTypes.length;
         if (numStates == 0) return; // Nothing to influence if partner has no states

         uint256 currentProbObservedState = s_particleProbabilities[_influencedParticleId][_observedStateTypeId]; // Partner's current probability for the observed state
         uint256 remainingProb = 10000 - currentProbObservedState; // Probability sum of all *other* states

         uint256 boostAmount = (10000 - currentProbObservedState) * s_influenceFactor / 10000; // Calculate boost based on remaining prob and influence factor

         uint256 newProbObservedState = currentProbObservedState + boostAmount;
         if (newProbObservedState > 10000) newProbObservedState = 10000; // Cap at 100%

         uint256 newRemainingProb = 10000 - newProbObservedState; // New sum for other states

         // Update probabilities
         s_particleProbabilities[_influencedParticleId][_observedStateTypeId] = newProbObservedState;
         // Scale other probabilities proportionally
         if (remainingProb > 0) { // Avoid division by zero
             for (uint i = 0; i < numStates; i++) {
                 uint256 stateTypeId = partnerStateTypes[i];
                 if (stateTypeId != _observedStateTypeId) {
                     uint256 currentOtherProb = s_particleProbabilities[_influencedParticleId][stateTypeId];
                     // newOtherProb = currentOtherProb * newRemainingProb / remainingProb
                     s_particleProbabilities[_influencedParticleId][stateTypeId] = currentOtherProb * newRemainingProb / remainingProb;
                 }
             }
         } else {
             // If remainingProb was 0, all probability was already on the observed state. No influence needed/possible on others.
             // Or, if influenceFactor was 100%, remainingProb goes to 0, all prob is on observed state.
             // Ensure others are 0 in this case.
             for (uint i = 0; i < numStates; i++) {
                  uint256 stateTypeId = partnerStateTypes[i];
                   if (stateTypeId != _observedStateTypeId) {
                        s_particleProbabilities[_influencedParticleId][stateTypeId] = 0;
                   }
             }
         }

         // Emit the updated probabilities for the partner
         emit ParticleProbabilitiesUpdated(_influencedParticleId, partnerStateTypes, _getProbabilitiesArray(_influencedParticleId));
    }

    /**
     * @dev Transfers ownership of a particle. Revokes any observation delegation.
     * Entanglements are not broken by transfer, but persist with the new owner.
     * @param _to The address to transfer the particle to.
     * @param _particleId The ID of the particle to transfer.
     */
    function transferParticle(address _to, uint256 _particleId) external whenNotPaused particleExists(_particleId) {
        Particle storage particle = s_particleData[_particleId];
        if (msg.sender != particle.owner) revert("Not particle owner");
        if (_to == address(0)) revert("Cannot transfer to zero address");

        address from = particle.owner;
        particle.owner = _to;
        // Revoke any active delegation on transfer
        particle.observationDelegate = address(0);

        emit ParticleTransfer(_particleId, from, _to);
         if (particle.observationDelegate != address(0)) {
             emit ObservationDelegateRevoked(_particleId);
         }
    }

     /**
     * @dev Allows the particle owner to delegate the right to observe the particle.
     * @param _particleId The ID of the particle.
     * @param _delegate The address to delegate observation rights to. Address(0) to revoke.
     */
    function delegateObservationRights(uint256 _particleId, address _delegate) external whenNotPaused particleExists(_particleId) {
        Particle storage particle = s_particleData[_particleId];
        if (msg.sender != particle.owner) revert("Not particle owner");

        particle.observationDelegate = _delegate;
        if (_delegate == address(0)) {
            emit ObservationDelegateRevoked(_particleId);
        } else {
            emit ObservationDelegateSet(_particleId, _delegate);
        }
    }

    /**
     * @dev Revokes any active observation delegation for a particle.
     * @param _particleId The ID of the particle.
     */
    function revokeObservationRights(uint256 _particleId) external whenNotPaused particleExists(_particleId) {
        Particle storage particle = s_particleData[_particleId];
        if (msg.sender != particle.owner) revert("Not particle owner");
        if (particle.observationDelegate == address(0)) revert("No active delegation");

        particle.observationDelegate = address(0);
        emit ObservationDelegateRevoked(_particleId);
    }

     /**
     * @dev Allows the particle owner to set a metadata URI for the particle.
     * Useful for linking to off-chain data like images or descriptions (similar to ERC721 tokenURI).
     * @param _particleId The ID of the particle.
     * @param _uri The URI string.
     */
    function setParticleMetadataURI(uint256 _particleId, string memory _uri) external whenNotPaused particleExists(_particleId) {
         Particle storage particle = s_particleData[_particleId];
         if (msg.sender != particle.owner) revert("Not particle owner");

         particle.metadataURI = _uri;
         emit ParticleMetadataUpdated(_particleId, _uri);
    }


    // --- Query Functions ---

    /**
     * @dev Returns the name of a state type.
     * @param _stateTypeId The ID of the state type.
     * @return The name of the state type.
     */
    function getStateTypeName(uint256 _stateTypeId) external view returns (string memory) {
        if (s_stateTypes[_stateTypeId].id == 0 && _stateTypeId != 0) revert StateTypeDoesNotExist(_stateTypeId);
        return s_stateTypes[_stateTypeId].name;
    }

    /**
     * @dev Returns the owner of a particle.
     * @param _particleId The ID of the particle.
     * @return The owner's address.
     */
    function getParticleOwner(uint256 _particleId) external view particleExists(_particleId) returns (address) {
        return s_particleData[_particleId].owner;
    }

    /**
     * @dev Returns the observed state ID of a particle.
     * @param _particleId The ID of the particle.
     * @return The observed state ID (0 if unobserved).
     */
    function getParticleState(uint256 _particleId) external view particleExists(_particleId) returns (uint256) {
        return s_particleData[_particleId].observedStateId;
    }

     /**
     * @dev Returns the current probability distribution for a particle.
     * Note: Iterates over all defined state types relevant to the particle, potentially gas-intensive for many states.
     * @param _particleId The ID of the particle.
     * @return A tuple of state type IDs and their corresponding probabilities (0-10000).
     */
    function getParticleProbabilities(uint256 _particleId) external view particleExists(_particleId) returns (uint256[] memory, uint256[] memory) {
        uint256[] memory stateTypes = s_particleStateTypesList[_particleId];
        uint256 numStates = stateTypes.length;
        uint256[] memory probabilities = new uint256[](numStates);

        for (uint i = 0; i < numStates; i++) {
            probabilities[i] = s_particleProbabilities[_particleId][stateTypes[i]];
        }

        return (stateTypes, probabilities);
    }

     /**
     * @dev Internal helper to get the probability array for emitting events.
     */
     function _getProbabilitiesArray(uint256 _particleId) internal view returns (uint256[] memory) {
        uint256[] memory stateTypes = s_particleStateTypesList[_particleId];
        uint256 numStates = stateTypes.length;
        uint256[] memory probabilities = new uint256[](numStates);

        for (uint i = 0; i < numStates; i++) {
            probabilities[i] = s_particleProbabilities[_particleId][stateTypes[i]];
        }
        return probabilities;
     }


    /**
     * @dev Returns the ID of a particle's entangled partner.
     * @param _particleId The ID of the particle.
     * @return The ID of the entangled partner (0 if not entangled).
     */
    function getEntangledPartner(uint256 _particleId) external view particleExists(_particleId) returns (uint256) {
        return s_entangledPartners[_particleId];
    }

     /**
     * @dev Checks if a particle is currently entangled.
     * @param _particleId The ID of the particle.
     * @return True if entangled, false otherwise.
     */
    function isEntangled(uint256 _particleId) external view particleExists(_particleId) returns (bool) {
        return s_entangledPartners[_particleId] != 0;
    }

    /**
     * @dev Returns the observation delegate for a particle.
     * @param _particleId The ID of the particle.
     * @return The delegate's address (address(0) if no delegate).
     */
    function getObservationDelegate(uint256 _particleId) external view particleExists(_particleId) returns (address) {
        return s_particleData[_particleId].observationDelegate;
    }

    /**
     * @dev Returns the metadata URI for a particle.
     * @param _particleId The ID of the particle.
     * @return The metadata URI string.
     */
    function getParticleMetadataURI(uint256 _particleId) external view particleExists(_particleId) returns (string memory) {
        return s_particleData[_particleId].metadataURI;
    }

     /**
     * @dev Checks if two specific particles are currently entangled *with each other*.
     * @param _particleId1 The ID of the first particle.
     * @param _particleId2 The ID of the second particle.
     * @return True if entangled with each other, false otherwise.
     */
    function getEntanglementStatus(uint256 _particleId1, uint256 _particleId2) external view particleExists(_particleId1) particleExists(_particleId2) returns (bool) {
        if (_particleId1 == _particleId2) return false;
        return s_entangledPartners[_particleId1] == _particleId2;
    }

    /**
     * @dev Returns the observation status of a particle.
     * @param _particleId The ID of the particle.
     * @return The observation status (Unobserved or Observed).
     */
    function getObservationStatus(uint256 _particleId) external view particleExists(_particleId) returns (ObservationStatus) {
        return s_particleData[_particleId].observationStatus;
    }

    /**
     * @dev Returns the total number of particles created.
     * @return The total particle count.
     */
    function getTotalParticles() external view returns (uint256) {
        return s_particleCounter;
    }

    /**
     * @dev Returns the current observation cost.
     * @return The observation cost in wei.
     */
    function getObservationCost() external view returns (uint256) {
        return s_observationCost;
    }

    /**
     * @dev Returns the current influence factor.
     * @return The influence factor (0-10000 basis points).
     */
    function getInfluenceFactor() external view returns (uint256) {
        return s_influenceFactor;
    }

    /**
     * @dev Returns the total protocol fees collected.
     * @return The total fees in wei.
     */
    function getProtocolFees() external view returns (uint256) {
        return s_protocolFees;
    }

     /**
     * @dev Returns the list of all defined state type IDs.
     * @return An array of defined state type IDs.
     */
    function getAllDefinedStateTypeIds() external view returns (uint256[] memory) {
        return s_definedStateTypeIds;
    }


     // --- Internal Helper for Constructor ---
     function _defineStateType(uint256 _stateTypeId, string memory _name) internal {
        s_stateTypes[_stateTypeId] = StateType({
            id: _stateTypeId,
            name: _name
        });
        s_definedStateTypeIds.push(_stateTypeId);
        emit StateTypeDefined(_stateTypeId, _name);
     }

    // Fallback function to receive Ether for observation costs
    receive() external payable {}
    fallback() external payable {}

}
```