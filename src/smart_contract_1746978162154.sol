Okay, here is a smart contract concept based on a metaphorical "Quantum Fluctuations" system. It involves dynamic, interactive "Particles" whose states are influenced by various factors including energy input, observation (interaction), entropy of the overall system, and pseudo-random quantum effects.

This contract is complex, uses custom data structures, involves non-standard state transitions, and incorporates concepts like state entanglement and superposition (metaphorically implemented). It does not rely on existing ERC standards directly, although the `Particle` concept has similarities to dynamic NFTs.

**Disclaimer:** This is a *conceptual* contract designed to be interesting and meet the prompt's requirements. It is provided for educational purposes. Deploying complex, novel smart contracts like this requires rigorous auditing, testing, and careful consideration of economic incentives, gas costs, and potential attack vectors (especially around randomness). The on-chain "randomness" used is based on block data and is not truly secure or unpredictable in a public mempool.

---

## QuantumFluctuations Smart Contract

**Outline:**

1.  **Concept:** A system simulating quantum-like interactions between unique digital "Particles" within a fluctuating environment (the "FluctuationState").
2.  **Core Components:**
    *   `Particle` Struct: Represents a dynamic entity with properties like energy, purity, quantum state, and entanglement bonds.
    *   `FluctuationState`: A system-wide value representing entropy or complexity.
    *   Mappings: To track particles, owners, and entanglement.
    *   Parameters: Tunable values affecting particle behavior and system dynamics.
    *   Entropy Pool: Contract balance holding funds from interactions.
3.  **Key Features:**
    *   Particle Creation (standard and entangled pairs).
    *   Dynamic Particle State (energy injection/extraction, purity decay/mutation).
    *   Quantum-themed Interactions (observation effect, entanglement/disentanglement, superposition measurement, quantum jumps).
    *   Particle Lifecycle (splitting, merging, potential collapse).
    *   System Entropy Management.
    *   Owner/Admin Functions.
    *   Query Functions.
    *   Pseudo-randomness influencing state transitions.
4.  **Function Categories:**
    *   Setup & Admin
    *   Particle Creation
    *   Particle Management (Energy, Purity, Ownership)
    *   Quantum State Interactions
    *   System Entropy Management
    *   Particle Lifecycle (Complex)
    *   Query Functions

**Function Summary:**

1.  `constructor()`: Initializes the contract, setting the owner and initial parameters.
2.  `genesisFluctuation()`: (Admin) Triggers the initial state setup for the system.
3.  `setCreationCost()`: (Admin) Sets the cost in ETH to create a particle.
4.  `setDecayRate()`: (Admin) Sets the rate at which particle purity decays.
5.  `setObservationEffect()`: (Admin) Sets how much interaction affects particle state.
6.  `setEntropyThresholds()`: (Admin) Sets thresholds for overall system state transitions.
7.  `setQuantumJumpCost()`: (Admin) Sets the cost (in ETH or particle sacrifice) for triggering a quantum jump.
8.  `withdrawEntropyPool()`: (Admin) Allows the owner to withdraw funds from the contract's balance (the entropy pool).
9.  `createParticle()`: (Payable) Creates a new particle with initial energy and properties, influenced by the current system state.
10. `createEntangledPair()`: (Payable) Creates two new particles that are linked (entangled) from the start.
11. `injectEnergy()`: (Payable) Adds ETH (energy) to a specific particle.
12. `extractEnergy()`: Allows the owner of a particle to withdraw excess energy (ETH) from it.
13. `teleportParticle()`: Transfers ownership of a particle to another address.
14. `observeParticle()`: Interacts with a particle, potentially changing its purity or quantum state based on time since last observed and the system fluctuation state.
15. `mutateParticle()`: Forces a pseudo-random mutation on a particle's purity and potentially state, consuming some energy.
16. `entangleParticles()`: Attempts to entangle two existing particles owned by the caller. Requires specific conditions.
17. `disentangleParticles()`: Breaks the entanglement bond between two particles owned by the caller.
18. `measureSuperposition()`: For a particle in a `Superposed` state, this action forces it into a definite state (`Stable` or `Decaying`) based on pseudo-randomness and system state.
19. `splitParticle()`: If a particle has high energy and purity, this function allows splitting it into two smaller, potentially different particles, consuming energy and destroying the original.
20. `mergeParticles()`: If two particles owned by the caller meet certain criteria, they can be merged into a single, potentially more energetic or pure particle, destroying the originals.
21. `absorbEntropy()`: Allows a user to burn one of their particles to reduce the overall system `FluctuationState`.
22. `triggerQuantumJump()`: (Cost/Sacrifice) Initiates a significant, pseudo-random system-wide fluctuation affecting multiple particles or the `FluctuationState` dramatically.
23. `queryParticleState()`: (View) Retrieves the detailed state of a specific particle.
24. `queryOverallFluctuation()`: (View) Retrieves the current system `FluctuationState`.
25. `listOwnerParticles()`: (View) Returns an array of particle IDs owned by a specific address.
26. `getParticleCount()`: (View) Returns the total number of particles created.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ has overflow checks, SafeMath adds clarity and can be used for specific operations if needed.

// Note: For true randomness on-chain, consider using Chainlink VRF.
// The randomness here is based on block data and is NOT secure against miner manipulation.

/**
 * @title QuantumFluctuations
 * @dev A complex, conceptual smart contract simulating a system of dynamic,
 *      interactive "Particles" influenced by a system-wide "FluctuationState".
 *      Features include particle creation, energy management, quantum-themed
 *      interactions (observation, entanglement, superposition), particle lifecycle
 *      (splitting, merging), and system entropy management.
 *      This contract is for educational and conceptual exploration. It is NOT
 *      production-ready without significant security review and gas optimization.
 */
contract QuantumFluctuations is Ownable, ReentrancyGuard {
    using SafeMath for uint256; // Explicitly use SafeMath, though 0.8+ checks by default.

    // --- Errors ---
    error InvalidParticle(uint256 particleId);
    error NotParticleOwner(uint256 particleId, address caller);
    error InsufficientEnergy(uint256 particleId, uint256 required, uint256 current);
    error InsufficientPurity(uint256 particleId, uint256 required, uint256 current);
    error ParticlesAlreadyEntangled(uint256 particleId1, uint256 particleId2);
    error ParticlesNotEntangled(uint256 particleId1, uint256 particleId2);
    error CannotEntangleSelf();
    error CannotEntangleDifferentOwners(address owner1, address owner2);
    error ParticleNotInState(uint256 particleId, QuantumState requiredState);
    error CannotSplitParticle(uint256 particleId);
    error CannotMergeParticles(uint256 particleId1, uint256 particleId2);
    error EntropyPoolWithdrawalFailed();

    // --- Enums ---
    enum QuantumState {
        Unknown,        // Initial state
        Stable,         // Resistant to decay, less reactive
        Decaying,       // Purity decreases over time
        Entangled,      // Linked to another particle
        Superposed,     // State is uncertain, can collapse upon observation/measurement
        Collapsed       // Terminal state, inactive
    }

    // --- Structs ---
    struct Particle {
        uint256 id;
        address owner;
        uint256 energy;         // Represents value or potential, measured in wei
        uint256 purity;         // Represents stability or uniqueness, 0-10000
        QuantumState quantumState;
        uint256 creationBlock;
        uint256 lastObservedBlock;
        uint256 bondedPartnerId; // ID of the particle it's entangled with (0 if not entangled)
    }

    // --- State Variables ---
    uint256 private _nextParticleId;
    mapping(uint256 => Particle) private _particles;
    mapping(address => uint256[]) private _ownerParticles; // Simple array, potentially gas-intensive for many particles
    mapping(uint256 => address) private _particleOwners; // Redundant but efficient lookup

    uint256 public fluctuationState; // Represents system entropy or complexity, influences particle behavior

    // Tunable Parameters (Admin-set)
    uint256 public creationCost = 0.01 ether;
    uint256 public entangledPairPremium = 5000; // Basis points (100% = 10000)
    uint256 public decayRatePerBlock = 1; // Purity units lost per block if Decaying
    uint256 public observationEffectMagnitude = 100; // How much observation influences purity/state
    uint256 public minEnergyToExtract = 0.001 ether;
    uint256 public minEnergyToSplit = 0.02 ether;
    uint256 public minPurityToSplit = 7000;
    uint256 public minPurityToMerge = 5000; // Requires both particles to meet this
    uint256 public mergeEnergyCost = 0.005 ether;
    uint256 public absorbEntropyPurityFactor = 10; // How much purity affects entropy reduction
    uint256 public quantumJumpCost = 0.1 ether; // Cost in ETH or particle sacrifice

    uint256 public fluctuationThresholdHigh = 8000; // Thresholds for system state behavior
    uint256 public fluctuationThresholdLow = 2000;

    // --- Events ---
    event ParticleCreated(uint256 particleId, address owner, uint256 initialEnergy, QuantumState initialState);
    event EnergyInjected(uint256 particleId, uint256 amount, uint256 newEnergy);
    event EnergyExtracted(uint256 particleId, uint256 amount, uint256 newEnergy);
    event OwnershipTransferred(uint256 particleId, address from, address to);
    event ParticleObserved(uint256 particleId, uint256 newPurity, QuantumState newState);
    event ParticleMutated(uint256 particleId, uint256 newPurity, QuantumState newState);
    event ParticleDecayed(uint256 particleId, uint256 newPurity, uint256 newEnergy); // Note: Decay can happen internally via observe/mutate
    event ParticlesEntangled(uint256 particleId1, uint256 particleId2);
    event ParticlesDisentangled(uint256 particleId1, uint256 particleId2);
    event SuperpositionMeasured(uint256 particleId, QuantumState resultState);
    event ParticleSplit(uint256 originalId, uint256 newId1, uint256 newId2, uint256 remainingEnergy);
    event ParticlesMerged(uint256 particleId1, uint256 particleId2, uint256 newId, uint256 newEnergy, uint256 newPurity);
    event ParticleCollapsed(uint256 particleId); // Purity reached zero
    event EntropyAbsorbed(uint256 particleIdBurned, uint256 fluctuationChange);
    event QuantumJumpTriggered(address indexed trigger, uint256 fluctuationEffect);
    event FluctuationStateChanged(uint256 oldState, uint256 newState);
    event EntropyPoolFunded(address indexed funder, uint256 amount);

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        _nextParticleId = 1; // Start IDs from 1
        fluctuationState = 5000; // Initial neutral state
    }

    // --- Modifiers ---
    modifier particleExists(uint256 particleId) {
        if (_particleOwners[particleId] == address(0)) {
            revert InvalidParticle(particleId);
        }
        _;
    }

    modifier isParticleOwner(uint256 particleId) {
        if (_particleOwners[particleId] != msg.sender) {
            revert NotParticleOwner(particleId, msg.sender);
        }
        _;
    }

    // --- Internal Helpers ---

    /**
     * @dev Generates pseudo-randomness based on block data. NOT secure.
     * @param seed A value to incorporate into the random calculation.
     * @return A pseudo-random uint256.
     */
    function _pseudoRandom(uint256 seed) internal view returns (uint256) {
        uint256 combinedSeed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Or block.prevrandao in PoS
            block.number,
            msg.sender,
            seed
        )));
        return combinedSeed;
    }

    /**
     * @dev Gets the next available particle ID and increments the counter.
     */
    function _getAndIncrementNextParticleId() internal returns (uint256) {
        uint256 currentId = _nextParticleId;
        _nextParticleId = _nextParticleId.add(1);
        return currentId;
    }

    /**
     * @dev Adds a particle ID to the owner's list.
     * @param owner The owner's address.
     * @param particleId The ID to add.
     */
    function _addParticleToOwner(address owner, uint256 particleId) internal {
        _ownerParticles[owner].push(particleId);
        _particleOwners[particleId] = owner;
    }

    /**
     * @dev Removes a particle ID from the owner's list and mapping.
     *      Note: Removing from a dynamic array is O(n), can be gas-intensive.
     *      For large numbers of particles per owner, an iterable mapping pattern
     *      or off-chain tracking would be more gas-efficient.
     * @param owner The owner's address.
     * @param particleId The ID to remove.
     */
    function _removeParticleFromOwner(address owner, uint256 particleId) internal {
        uint256[] storage ownerParticles = _ownerParticles[owner];
        for (uint256 i = 0; i < ownerParticles.length; i++) {
            if (ownerParticles[i] == particleId) {
                // Replace with last element and pop
                ownerParticles[i] = ownerParticles[ownerParticles.length - 1];
                ownerParticles.pop();
                break; // Found and removed
            }
        }
        delete _particleOwners[particleId]; // Clear ownership mapping
    }

    /**
     * @dev Handles the decay logic for a particle based on elapsed blocks.
     *      This is called internally by other functions that interact with a particle.
     * @param particle The particle struct (passed by reference).
     */
    function _decayParticle(Particle storage particle) internal {
        if (particle.quantumState == QuantumState.Decaying) {
            uint256 blocksElapsed = block.number.sub(particle.lastObservedBlock);
            uint256 purityLoss = blocksElapsed.mul(decayRatePerBlock);
            if (particle.purity <= purityLoss) {
                particle.purity = 0;
                _collapseParticle(particle.id);
            } else {
                particle.purity = particle.purity.sub(purityLoss);
            }
            // Optional: Lose a small amount of energy when decaying
            // particle.energy = particle.energy.div(blocksElapsed > 0 ? blocksElapsed : 1); // Example, adjust logic
            emit ParticleDecayed(particle.id, particle.purity, particle.energy);
        }
    }

    /**
     * @dev Handles the collapse of a particle when its purity reaches zero.
     * @param particleId The ID of the particle to collapse.
     */
    function _collapseParticle(uint256 particleId) internal particleExists(particleId) {
        Particle storage particle = _particles[particleId];
        if (particle.quantumState != QuantumState.Collapsed) {
            particle.quantumState = QuantumState.Collapsed;
            // Optional: Distribute remaining energy to entropy pool or owner
            // payable(address(this)).transfer(particle.energy); // Example: Add to pool
            // particle.energy = 0; // Clear energy
            emit ParticleCollapsed(particleId);
            // Note: Particle data persists, just marked as Collapsed.
            // Full deletion is complex due to mapping structure and not necessary unless state bloat is an issue.
        }
    }

    /**
     * @dev Updates the overall system fluctuation state based on events.
     *      This is a simplified model. More complex interactions could affect this.
     * @param delta The amount to change the fluctuation state (can be positive or negative).
     */
    function _updateFluctuationState(int256 delta) internal {
        uint256 oldState = fluctuationState;
        if (delta > 0) {
             fluctuationState = fluctuationState.add(uint256(delta));
        } else {
            uint256 absDelta = uint256(-delta);
            if (fluctuationState <= absDelta) {
                fluctuationState = 0;
            } else {
                fluctuationState = fluctuationState.sub(absDelta);
            }
        }
        // Cap fluctuation state if needed (e.g., between 0 and 10000)
        fluctuationState = fluctuationState > 10000 ? 10000 : fluctuationState;
        fluctuationState = fluctuationState < 0 ? 0 : fluctuationState; // Should not happen with current math, but for safety
        if (fluctuationState != oldState) {
             emit FluctuationStateChanged(oldState, fluctuationState);
        }
    }


    // --- Admin Functions ---

    /**
     * @dev Initializes the overall system fluctuation state and parameters if needed.
     *      Can be called once by the owner after deployment.
     */
    function genesisFluctuation() external onlyOwner {
        // Can add more complex setup logic here if needed.
        // For now, constructor handles basic initialization.
        // This function serves as a placeholder for more elaborate genesis events.
        emit FluctuationStateChanged(0, fluctuationState); // Emit event for initial state
    }

    /**
     * @dev Sets the cost to create a single particle.
     * @param _creationCost The new cost in wei.
     */
    function setCreationCost(uint256 _creationCost) external onlyOwner {
        creationCost = _creationCost;
    }

    /**
     * @dev Sets the rate at which particle purity decays per block.
     * @param _decayRatePerBlock The new decay rate.
     */
    function setDecayRate(uint256 _decayRatePerBlock) external onlyOwner {
        decayRatePerBlock = _decayRatePerBlock;
    }

    /**
     * @dev Sets the magnitude of the effect when a particle is observed.
     * @param _observationEffectMagnitude The new effect magnitude.
     */
    function setObservationEffect(uint256 _observationEffectMagnitude) external onlyOwner {
        observationEffectMagnitude = _observationEffectMagnitude;
    }

    /**
     * @dev Sets the thresholds for overall system fluctuation state.
     * @param _high The new high threshold.
     * @param _low The new low threshold.
     */
    function setEntropyThresholds(uint256 _high, uint256 _low) external onlyOwner {
        require(_high > _low, "High threshold must be greater than low");
        fluctuationThresholdHigh = _high;
        fluctuationThresholdLow = _low;
    }

    /**
     * @dev Sets the cost or required sacrifice for triggering a quantum jump.
     * @param _cost The new cost in wei (or other unit if implementing sacrifice).
     */
    function setQuantumJumpCost(uint256 _cost) external onlyOwner {
        quantumJumpCost = _cost;
    }

     /**
     * @dev Allows the contract owner to withdraw funds from the entropy pool (contract balance).
     * @param amount The amount to withdraw in wei.
     */
    function withdrawEntropyPool(uint256 amount) external onlyOwner nonReentrant {
        require(address(this).balance >= amount, "Insufficient balance in entropy pool");
        (bool success, ) = payable(owner()).call{value: amount}("");
        if (!success) {
            revert EntropyPoolWithdrawalFailed();
        }
    }


    // --- Particle Creation ---

    /**
     * @dev Creates a new Quantum Particle.
     *      Initial energy is based on `msg.value`. Initial purity and state
     *      are pseudo-randomly determined, influenced by the system state.
     */
    function createParticle() external payable nonReentrant {
        require(msg.value >= creationCost, "Insufficient ETH to create particle");

        uint256 id = _getAndIncrementNextParticleId();
        uint256 initialEnergy = msg.value;
        uint256 randomSeed = _pseudoRandom(id);

        // Determine initial purity (e.g., influenced by fluctuationState)
        uint256 initialPurity = (randomSeed % 5000) + 2500; // Base purity
        if (fluctuationState < fluctuationThresholdLow) {
            initialPurity = initialPurity.add(randomSeed % 2000); // Higher purity in stable state
        } else if (fluctuationState > fluctuationThresholdHigh) {
            initialPurity = initialPurity.sub(randomSeed % 2000); // Lower purity in chaotic state
        }
        initialPurity = initialPurity > 10000 ? 10000 : (initialPurity < 0 ? 0 : initialPurity); // Clamp 0-10000

        // Determine initial state (e.g., chance of Superposed in high fluctuation)
        QuantumState initialState = QuantumState.Stable;
        if (fluctuationState > fluctuationThresholdHigh && randomSeed % 100 < 30) { // 30% chance in high state
            initialState = QuantumState.Superposed;
        } else if (fluctuationState < fluctuationThresholdLow && randomSeed % 100 < 10) { // 10% chance in low state
             initialState = QuantumState.Superposed; // Small chance even in stable state
        } else if (randomSeed % 100 < 20) { // Small chance of Decaying initially
             initialState = QuantumState.Decaying;
        }


        _particles[id] = Particle({
            id: id,
            owner: msg.sender,
            energy: initialEnergy,
            purity: initialPurity,
            quantumState: initialState,
            creationBlock: block.number,
            lastObservedBlock: block.number,
            bondedPartnerId: 0 // Not entangled initially
        });

        _addParticleToOwner(msg.sender, id);

        // System state update based on particle creation
        _updateFluctuationState(50); // Creation adds a small amount of entropy

        emit ParticleCreated(id, msg.sender, initialEnergy, initialState);
    }

    /**
     * @dev Creates a pair of new, entangled particles.
     *      Requires a higher cost than creating two individual particles.
     */
    function createEntangledPair() external payable nonReentrant {
        uint256 requiredCost = creationCost.mul(2).mul(10000 + entangledPairPremium).div(10000);
        require(msg.value >= requiredCost, "Insufficient ETH to create entangled pair");

        uint256 id1 = _getAndIncrementNextParticleId();
        uint256 id2 = _getAndIncrementNextParticleId();
        uint256 initialEnergy = msg.value.div(2); // Split energy between the pair
        uint256 randomSeed1 = _pseudoRandom(id1);
        uint256 randomSeed2 = _pseudoRandom(id2);

        // Initial properties can be correlated
        uint256 initialPurity1 = (randomSeed1 % 4000) + 3000;
        uint256 initialPurity2 = (randomSeed2 % 4000) + 3000;
        // Make them somewhat correlated purity = avg + diff * factor
        uint256 avgPurity = (initialPurity1.add(initialPurity2)).div(2);
        uint256 purityDiff = initialPurity1 > initialPurity2 ? initialPurity1.sub(initialPurity2) : initialPurity2.sub(initialPurity1);
        initialPurity1 = avgPurity.add(purityDiff.div(4)); // Make them slightly more similar
        initialPurity2 = avgPurity.sub(purityDiff.div(4));
        initialPurity1 = initialPurity1 > 10000 ? 10000 : initialPurity1;
        initialPurity2 = initialPurity2 > 10000 ? 10000 : initialPurity2;
        initialPurity1 = initialPurity1 < 0 ? 0 : initialPurity1; // Should not happen
        initialPurity2 = initialPurity2 < 0 ? 0 : initialPurity2; // Should not happen


        _particles[id1] = Particle({
            id: id1,
            owner: msg.sender,
            energy: initialEnergy,
            purity: initialPurity1,
            quantumState: QuantumState.Entangled, // Start as Entangled
            creationBlock: block.number,
            lastObservedBlock: block.number,
            bondedPartnerId: id2
        });

        _particles[id2] = Particle({
            id: id2,
            owner: msg.sender,
            energy: initialEnergy,
            purity: initialPurity2,
            quantumState: QuantumState.Entangled, // Start as Entangled
            creationBlock: block.number,
            lastObservedBlock: block.number,
            bondedPartnerId: id1
        });

        _addParticleToOwner(msg.sender, id1);
        _addParticleToOwner(msg.sender, id2);

        // System state update
        _updateFluctuationState(100); // Creating entanglement adds more complex entropy

        emit ParticleCreated(id1, msg.sender, initialEnergy, QuantumState.Entangled);
        emit ParticleCreated(id2, msg.sender, initialEnergy, QuantumState.Entangled);
        emit ParticlesEntangled(id1, id2);
    }


    // --- Particle Management (Energy, Purity, Ownership) ---

    /**
     * @dev Allows a particle owner to inject more energy (ETH) into their particle.
     * @param particleId The ID of the particle.
     */
    function injectEnergy(uint256 particleId) external payable nonReentrant particleExists(particleId) isParticleOwner(particleId) {
        Particle storage particle = _particles[particleId];
        require(particle.quantumState != QuantumState.Collapsed, "Cannot inject energy into a collapsed particle");

        particle.energy = particle.energy.add(msg.value);
        emit EnergyInjected(particleId, msg.value, particle.energy);

        // Optional: Energy injection could boost purity or affect state
        // particle.purity = particle.purity.add(msg.value.div(100000)); // Example effect
        // _updateFluctuationState(-10); // Injecting energy might reduce entropy
    }

    /**
     * @dev Allows a particle owner to extract energy (ETH) from their particle
     *      if its energy level is above a certain threshold.
     * @param particleId The ID of the particle.
     * @param amount The amount of energy (ETH) to extract.
     */
    function extractEnergy(uint256 particleId, uint256 amount) external nonReentrant particleExists(particleId) isParticleOwner(particleId) {
        Particle storage particle = _particles[particleId];
        require(particle.quantumState != QuantumState.Collapsed, "Cannot extract energy from a collapsed particle");
        require(amount > 0, "Extraction amount must be greater than zero");
        require(particle.energy.sub(amount) >= minEnergyToExtract, "Must leave minimum energy in particle"); // Ensure minimum left
        require(address(this).balance >= amount, "Contract lacks sufficient balance for extraction"); // Contract must hold the ETH

        particle.energy = particle.energy.sub(amount);

        (bool success, ) = payable(msg.sender).call{value: amount}("");
         // If transfer fails, revert and keep energy in particle
        if (!success) {
            particle.energy = particle.energy.add(amount); // Refund energy back to particle
            revert EntropyPoolWithdrawalFailed(); // Use a specific error for withdrawal
        }

        emit EnergyExtracted(particleId, amount, particle.energy);

        // Optional: Energy extraction might increase entropy or reduce purity
        // particle.purity = particle.purity.sub(amount.div(200000)); // Example effect
         _updateFluctuationState(20); // Extraction might increase entropy
    }

    /**
     * @dev Transfers ownership of a particle to another address.
     * @param particleId The ID of the particle to transfer.
     * @param to The recipient address.
     */
    function teleportParticle(uint256 particleId, address to) external particleExists(particleId) isParticleOwner(particleId) {
        require(to != address(0), "Cannot transfer to zero address");
        require(particleId != 0, "Cannot transfer ID 0"); // Should not happen with _nextParticleId starting at 1

        address from = msg.sender;
        Particle storage particle = _particles[particleId];

        // Handle entanglement: Teleporting one entangled particle requires teleporting the partner too?
        // Or does it break entanglement? Let's say it breaks entanglement for simplicity here.
        if (particle.quantumState == QuantumState.Entangled && particle.bondedPartnerId != 0) {
             _disentangleParticles(particle.id, particle.bondedPartnerId); // Internal call
        }

        _removeParticleFromOwner(from, particleId);
        _addParticleToOwner(to, particleId);

        // Update particle struct owner field
        particle.owner = to;
        particle.lastObservedBlock = block.number; // Observation effect on teleport?

        emit OwnershipTransferred(particleId, from, to);
    }

    // --- Quantum State Interactions ---

    /**
     * @dev "Observing" a particle simulates interaction affecting its state.
     *      Purity and state can change based on time elapsed since last observation
     *      and the overall system fluctuation state.
     * @param particleId The ID of the particle to observe.
     */
    function observeParticle(uint256 particleId) external particleExists(particleId) {
        // Anyone can observe a particle, not just the owner.
        Particle storage particle = _particles[particleId];
        require(particle.quantumState != QuantumState.Collapsed, "Cannot observe a collapsed particle");

        // Apply decay before observation effect
        _decayParticle(particle); // This might set purity to 0 and collapse

        if (particle.quantumState != QuantumState.Collapsed) {
            uint256 blocksElapsed = block.number.sub(particle.lastObservedBlock);
            uint256 randomSeed = _pseudoRandom(particleId.add(block.number));

            uint256 purityChange = (randomSeed % observationEffectMagnitude); // Base change

            // Fluctuation state influences the effect
            if (fluctuationState > fluctuationThresholdHigh) {
                // More chaotic, observation is less predictable, maybe more negative
                purityChange = purityChange.mul(2); // Magnify change
                if (randomSeed % 100 < 60) purityChange = purityChange.mul(uint256(-1)); // More likely negative
            } else if (fluctuationState < fluctuationThresholdLow) {
                // More stable, observation stabilizes
                purityChange = purityChange.div(2); // Less change
                // Purity change more likely positive
            } else {
                 // Neutral state, mix of effects
                 if (randomSeed % 2 == 0) purityChange = purityChange.mul(uint256(-1));
            }

            // Apply purity change, clamping between 0 and 10000
            if (purityChange > 0) {
                 particle.purity = particle.purity.add(purityChange);
                 particle.purity = particle.purity > 10000 ? 10000 : particle.purity;
            } else {
                 uint256 absPurityChange = uint256(-purityChange);
                 if (particle.purity <= absPurityChange) {
                     particle.purity = 0;
                     _collapseParticle(particleId); // Observation can cause collapse if purity is low
                 } else {
                      particle.purity = particle.purity.sub(absPurityChange);
                 }
            }

            // Observation might shift state, especially if Superposed
            if (particle.quantumState == QuantumState.Superposed) {
                 // Measurement logic is in measureSuperposition, but observation could trigger it
                 if (randomSeed % 100 < 50) { // 50% chance observation triggers collapse of superposition
                     measureSuperposition(particleId); // Internal call to resolve superposition
                 }
            } else {
                 // Maybe observation can induce superposition in some cases?
                 if (fluctuationState > fluctuationThresholdHigh && randomSeed % 100 < 15) {
                     particle.quantumState = QuantumState.Superposed;
                 }
            }


            particle.lastObservedBlock = block.number;

            emit ParticleObserved(particleId, particle.purity, particle.quantumState);
        }
    }

     /**
      * @dev Forces a pseudo-random mutation on a particle's purity and potentially state.
      *      Requires particle owner.
      * @param particleId The ID of the particle to mutate.
      * @param mutationSeed An external seed provided by the caller (adds slight user influence).
      */
    function mutateParticle(uint256 particleId, uint256 mutationSeed) external particleExists(particleId) isParticleOwner(particleId) {
        Particle storage particle = _particles[particleId];
        require(particle.quantumState != QuantumState.Collapsed, "Cannot mutate a collapsed particle");
        require(particle.energy >= creationCost.div(10), "Insufficient energy to withstand mutation"); // Mutation costs energy

        particle.energy = particle.energy.sub(creationCost.div(10)); // Energy cost

        // Apply decay first
        _decayParticle(particle);

        if (particle.quantumState != QuantumState.Collapsed) {
            uint256 randomFactor = _pseudoRandom(particleId.add(block.number).add(mutationSeed));

            // Purity mutation: Significant change based on randomness and fluctuation
            int256 purityChange = int256(randomFactor % 2000); // Base change range +/- 2000
            if (randomFactor % 2 == 0) purityChange = purityChange.mul(uint256(-1));

            // Fluctuation state magnifies or dampens mutation effect
            if (fluctuationState > fluctuationThresholdHigh) {
                 purityChange = purityChange.mul(2); // More extreme mutations
            } else if (fluctuationState < fluctuationThresholdLow) {
                 purityChange = purityChange.div(2); // Less extreme mutations
            }

             if (purityChange > 0) {
                 particle.purity = particle.purity.add(uint256(purityChange));
                 particle.purity = particle.purity > 10000 ? 10000 : particle.purity;
            } else {
                 uint256 absPurityChange = uint256(-purityChange);
                 if (particle.purity <= absPurityChange) {
                     particle.purity = 0;
                     _collapseParticle(particleId);
                 } else {
                      particle.purity = particle.purity.sub(absPurityChange);
                 }
            }

            // State mutation: Chance to shift state based on randomness and fluctuation
            QuantumState newState = particle.quantumState;
            uint256 stateRandom = _pseudoRandom(randomFactor);

            if (fluctuationState > fluctuationThresholdHigh && stateRandom % 100 < 40) { // High fluctuation -> more state changes
                 newState = QuantumState(stateRandom % 6); // Can jump to any state
            } else if (stateRandom % 100 < 10) { // Small chance of state change even in neutral/low
                 newState = QuantumState(stateRandom % 6);
            }

            // Ensure valid state transitions (e.g., cannot mutate to Entangled without a partner, cannot mutate out of Collapsed)
            if (newState == QuantumState.Entangled) newState = QuantumState.Superposed; // Cannot randomly become entangled
            if (particle.quantumState == QuantumState.Collapsed) newState = QuantumState.Collapsed; // Cannot un-collapse

            particle.quantumState = newState;
            particle.lastObservedBlock = block.number;

            emit ParticleMutated(particleId, particle.purity, particle.quantumState);

             _updateFluctuationState(30); // Mutation adds entropy
        }
    }

    /**
     * @dev Attempts to entangle two particles owned by the caller.
     *      Requires particles to be in a state that allows entanglement (e.g., not already entangled, not collapsed).
     * @param particleId1 The ID of the first particle.
     * @param particleId2 The ID of the second particle.
     */
    function entangleParticles(uint256 particleId1, uint256 particleId2) external nonReentrant particleExists(particleId1) isParticleOwner(particleId1) particleExists(particleId2) isParticleOwner(particleId2) {
        require(particleId1 != particleId2, "Cannot entangle a particle with itself");
        require(_particleOwners[particleId1] == _particleOwners[particleId2], "Cannot entangle particles owned by different addresses"); // Redundant check but good

        Particle storage particle1 = _particles[particleId1];
        Particle storage particle2 = _particles[particleId2];

        require(particle1.quantumState != QuantumState.Entangled && particle1.bondedPartnerId == 0, ParticlesAlreadyEntangled(particleId1, particle2.id));
        require(particle2.quantumState != QuantumState.Entangled && particle2.bondedPartnerId == 0, ParticlesAlreadyEntangled(particleId2, particle1.id));
        require(particle1.quantumState != QuantumState.Collapsed && particle2.quantumState != QuantumState.Collapsed, "Cannot entangle collapsed particles");

        // Apply decay before entanglement
        _decayParticle(particle1);
        _decayParticle(particle2);

        // Re-check after decay might cause collapse
        require(particle1.quantumState != QuantumState.Collapsed && particle2.quantumState != QuantumState.Collapsed, "One or both particles collapsed during decay check");

        particle1.bondedPartnerId = particleId2;
        particle2.bondedPartnerId = particleId1;
        particle1.quantumState = QuantumState.Entangled;
        particle2.quantumState = QuantumState.Entangled;

        // Optional: Entanglement might cost energy or reduce purity slightly
        // particle1.energy = particle1.energy.sub(creationCost.div(20));
        // particle2.energy = particle2.energy.sub(creationCost.div(20));

        particle1.lastObservedBlock = block.number;
        particle2.lastObservedBlock = block.number;

        emit ParticlesEntangled(particleId1, particleId2);
        emit ParticleObserved(particleId1, particle1.purity, particle1.quantumState); // State changed due to entanglement
        emit ParticleObserved(particleId2, particle2.purity, particle2.quantumState); // State changed due to entanglement

        _updateFluctuationState(80); // Entanglement adds complexity
    }

     /**
      * @dev Breaks the entanglement bond between two particles owned by the caller.
      * @param particleId1 The ID of the first particle.
      * @param particleId2 The ID of the second particle.
      */
    function disentangleParticles(uint256 particleId1, uint256 particleId2) public nonReentrant particleExists(particleId1) isParticleOwner(particleId1) particleExists(particleId2) isParticleOwner(particleId2) {
         require(particleId1 != particleId2, "Cannot disentangle self");
         require(_particleOwners[particleId1] == _particleOwners[particleId2], "Cannot disentangle particles owned by different addresses");

         Particle storage particle1 = _particles[particleId1];
         Particle storage particle2 = _particles[particleId2];

         require(particle1.quantumState == QuantumState.Entangled && particle1.bondedPartnerId == particleId2, ParticlesNotEntangled(particleId1, particleId2));
         require(particle2.quantumState == QuantumState.Entangled && particle2.bondedPartnerId == particleId1, ParticlesNotEntangled(particleId2, particleId1)); // Redundant check

         // Apply decay
         _decayParticle(particle1);
         _decayParticle(particle2);
          require(particle1.quantumState != QuantumState.Collapsed && particle2.quantumState != QuantumState.Collapsed, "One or both particles collapsed during decay check");


         particle1.bondedPartnerId = 0;
         particle2.bondedPartnerId = 0;

         // Disentanglement might result in a new state based on fluctuation state/randomness
         uint256 randomSeed1 = _pseudoRandom(particleId1.add(block.number).add(1));
         uint256 randomSeed2 = _pseudoRandom(particleId2.add(block.number).add(2));

         QuantumState newState1 = (fluctuationState > fluctuationThresholdHigh && randomSeed1 % 100 < 30) ? QuantumState.Superposed : QuantumState.Stable;
         QuantumState newState2 = (fluctuationState > fluctuationThresholdHigh && randomSeed2 % 100 < 30) ? QuantumState.Superposed : QuantumState.Stable;
         // Add a chance of Decaying state
         if (randomSeed1 % 100 < 10) newState1 = QuantumState.Decaying;
         if (randomSeed2 % 100 < 10) newState2 = QuantumState.Decaying;


         particle1.quantumState = newState1;
         particle2.quantumState = newState2;

         particle1.lastObservedBlock = block.number;
         particle2.lastObservedBlock = block.number;


         emit ParticlesDisentangled(particleId1, particleId2);
         emit ParticleObserved(particleId1, particle1.purity, particle1.quantumState); // State changed due to disentanglement
         emit ParticleObserved(particleId2, particle2.purity, particle2.quantumState); // State changed due to disentanglement

         _updateFluctuationState(-60); // Disentanglement might reduce entropy
    }

     /**
      * @dev Attempts to measure a particle in a Superposed state, collapsing it into a definite state.
      *      Requires particle owner.
      * @param particleId The ID of the particle to measure.
      */
    function measureSuperposition(uint256 particleId) public particleExists(particleId) isParticleOwner(particleId) {
        Particle storage particle = _particles[particleId];
        require(particle.quantumState == QuantumState.Superposed, ParticleNotInState(particleId, QuantumState.Superposed));

        // Apply decay
        _decayParticle(particle);
        if (particle.quantumState == QuantumState.Collapsed) {
            emit SuperpositionMeasured(particleId, QuantumState.Collapsed); // Collapsed during decay check
            return;
        }

        // Determine the resulting state based on pseudo-randomness and fluctuation state
        uint256 randomResult = _pseudoRandom(particleId.add(block.number).add(3));

        QuantumState resultState;
        // Probability influenced by fluctuation state
        uint256 stableChance = 60; // Base chance to become Stable
        if (fluctuationState > fluctuationThresholdHigh) {
            stableChance = 30; // Lower chance to stabilize in high fluctuation
        } else if (fluctuationState < fluctuationThresholdLow) {
            stableChance = 80; // Higher chance to stabilize in low fluctuation
        }

        if (randomResult % 100 < stableChance) {
            resultState = QuantumState.Stable;
        } else {
            resultState = QuantumState.Decaying;
        }

        particle.quantumState = resultState;
        particle.lastObservedBlock = block.number;

        emit SuperpositionMeasured(particleId, resultState);
        emit ParticleObserved(particleId, particle.purity, particle.quantumState); // State changed by measurement

         _updateFluctuationState(10); // Measurement adds a small amount of entropy
    }

    // --- System Entropy Management ---

    /**
     * @dev Allows a user to burn one of their particles to absorb entropy,
     *      reducing the overall system fluctuation state.
     * @param particleId The ID of the particle to sacrifice.
     */
    function absorbEntropy(uint256 particleId) external nonReentrant particleExists(particleId) isParticleOwner(particleId) {
        Particle storage particle = _particles[particleId];
        require(particle.quantumState != QuantumState.Collapsed, "Cannot sacrifice a collapsed particle");

        uint256 purityContribution = particle.purity.div(absorbEntropyPurityFactor);
        uint256 energyContribution = particle.energy.div(1 ether); // Value in ETH units
        int256 entropyReduction = int256(purityContribution.add(energyContribution).mul(5)); // Arbitrary calculation

        _removeParticleFromOwner(msg.sender, particleId);
        // Note: Particle data remains in _particles mapping but ownership is removed, effectively burning.
        // Alternatively, could move to an 'Address(0)' owner or special burned address.
        delete _particles[particleId]; // Actual deletion for this function

        _updateFluctuationState(-entropyReduction); // Sacrifice reduces entropy

        emit ParticleCollapsed(particleId); // Represents the "burning"
        emit EntropyAbsorbed(particleId, uint256(entropyReduction));
    }

    /**
     * @dev Allows users to fund the entropy pool (contract balance).
     *      This ETH can potentially be used for rewards, quantum jumps, etc.
     */
    function fundEntropyPool() external payable {
        require(msg.value > 0, "Must send ETH to fund entropy pool");
        // ETH is automatically added to contract balance.
        emit EntropyPoolFunded(msg.sender, msg.value);
    }

    // --- Particle Lifecycle (Complex Interactions) ---

    /**
     * @dev Allows splitting a particle into two if it meets high energy and purity thresholds.
     *      Consumes a significant amount of energy from the original particle.
     * @param particleId The ID of the particle to split.
     */
    function splitParticle(uint256 particleId) external nonReentrant particleExists(particleId) isParticleOwner(particleId) {
        Particle storage original = _particles[particleId];
        require(original.quantumState != QuantumState.Collapsed, "Cannot split a collapsed particle");
        require(original.energy >= minEnergyToSplit, InsufficientEnergy(particleId, minEnergyToSplit, original.energy));
        require(original.purity >= minPurityToSplit, InsufficientPurity(particleId, minPurityToSplit, original.purity));

        // Apply decay first
        _decayParticle(original);
        require(original.quantumState != QuantumState.Collapsed, "Particle collapsed during decay check before splitting");
        require(original.energy >= minEnergyToSplit, InsufficientEnergy(particleId, minEnergyToSplit, original.energy)); // Re-check after decay
        require(original.purity >= minPurityToSplit, InsufficientPurity(particleId, minPurityToSplit, original.purity)); // Re-check after decay


        uint256 id1 = _getAndIncrementNextParticleId();
        uint256 id2 = _getAndIncrementNextParticleId();

        uint256 energySplit = original.energy.div(2); // Split energy
        uint256 remainingEnergy = original.energy.sub(energySplit.mul(2)); // Any remainder
        original.energy = remainingEnergy; // Original particle retains a small amount? Or give it all to children? Let's give it all to children for simplicity.
        original.energy = 0; // Original loses most energy

        // Purity split with randomness
        uint256 randomSeed = _pseudoRandom(particleId.add(block.number).add(4));
        uint256 puritySplitBase = original.purity.div(2);
        uint256 purityVariation = randomSeed % (puritySplitBase.div(4) > 100 ? puritySplitBase.div(4) : 100); // +/- 25% variation up to a cap

        uint256 purity1 = puritySplitBase.add(purityVariation);
        uint256 purity2 = puritySplitBase.sub(purityVariation);

        purity1 = purity1 > 10000 ? 10000 : purity1;
        purity2 = purity2 < 0 ? 0 : purity2; // Can result in low purity child


        // Determine states of new particles (e.g., influenced by fluctuation/randomness)
        uint256 stateRandom1 = _pseudoRandom(id1.add(block.number));
        uint256 stateRandom2 = _pseudoRandom(id2.add(block.number));
        QuantumState state1 = (fluctuationState > fluctuationThresholdHigh && stateRandom1 % 100 < 20) ? QuantumState.Superposed : QuantumState.Stable;
        QuantumState state2 = (fluctuationState > fluctuationThresholdHigh && stateRandom2 % 100 < 20) ? QuantumState.Superposed : QuantumState.Stable;
         if (stateRandom1 % 100 < 15) state1 = QuantumState.Decaying;
         if (stateRandom2 % 100 < 15) state2 = QuantumState.Decaying;


        // Create the new particles
        _particles[id1] = Particle({
            id: id1,
            owner: msg.sender,
            energy: energySplit,
            purity: purity1,
            quantumState: state1,
            creationBlock: block.number,
            lastObservedBlock: block.number,
            bondedPartnerId: 0
        });
         _particles[id2] = Particle({
            id: id2,
            owner: msg.sender,
            energy: energySplit,
            purity: purity2,
            quantumState: state2,
            creationBlock: block.number,
            lastObservedBlock: block.number,
            bondedPartnerId: 0
        });

        _addParticleToOwner(msg.sender, id1);
        _addParticleToOwner(msg.sender, id2);

        // Original particle's state after splitting (e.g., collapsed or greatly reduced)
        // Let's say the original effectively "becomes" the new particles, so we mark the original as collapsed/inactive
         _collapseParticle(particleId); // The act of splitting collapses the parent

        emit ParticleSplit(particleId, id1, id2, original.energy); // original.energy is now 0 or remainder
        emit ParticleCreated(id1, msg.sender, energySplit, state1);
        emit ParticleCreated(id2, msg.sender, energySplit, state2);

        _updateFluctuationState(70); // Splitting adds complexity
    }

    /**
     * @dev Allows merging two particles into one if they meet certain purity thresholds.
     *      Combines energy and purity, consumes a small energy cost.
     * @param particleId1 The ID of the first particle.
     * @param particleId2 The ID of the second particle.
     */
    function mergeParticles(uint256 particleId1, uint256 particleId2) external payable nonReentrant particleExists(particleId1) isParticleOwner(particleId1) particleExists(particleId2) isParticleOwner(particleId2) {
        require(particleId1 != particleId2, "Cannot merge a particle with itself");
        require(_particleOwners[particleId1] == _particleOwners[particleId2], "Cannot merge particles owned by different addresses");
        require(msg.value >= mergeEnergyCost, "Insufficient ETH for merge cost"); // Pay a small merge cost

        Particle storage p1 = _particles[particleId1];
        Particle storage p2 = _particles[particleId2];

        require(p1.quantumState != QuantumState.Collapsed && p2.quantumState != QuantumState.Collapsed, "Cannot merge collapsed particles");
        require(p1.purity >= minPurityToMerge && p2.purity >= minPurityToMerge, "Particles must meet minimum purity to merge");

         // Apply decay
         _decayParticle(p1);
         _decayParticle(p2);
         require(p1.quantumState != QuantumState.Collapsed && p2.quantumState != QuantumState.Collapsed, "One or both particles collapsed during decay check");
         require(p1.purity >= minPurityToMerge && p2.purity >= minPurityToMerge, "Particles failed purity check after decay");


        // Break entanglement before merging if applicable
        if (p1.quantumState == QuantumState.Entangled) _disentangleParticles(particleId1, p1.bondedPartnerId); // This calls disentangleParticles internally
        if (p2.quantumState == QuantumState.Entangled) _disentangleParticles(particleId2, p2.bondedPartnerId); // This calls disentangleParticles internally

        uint256 newId = _getAndIncrementNextParticleId();
        uint256 newEnergy = p1.energy.add(p2.energy); // Combine energy

        // Combine purity (e.g., average + bonus, influenced by fluctuation)
        uint256 avgPurity = (p1.purity.add(p2.purity)).div(2);
        uint256 randomSeed = _pseudoRandom(particleId1.add(particleId2).add(block.number));
        uint256 purityBonus = randomSeed % 500; // Small random bonus
        if (fluctuationState < fluctuationThresholdLow) purityBonus = purityBonus.mul(2); // Higher bonus in stable state

        uint256 newPurity = avgPurity.add(purityBonus);
        newPurity = newPurity > 10000 ? 10000 : newPurity;


        // Determine state of new particle
        QuantumState newState = QuantumState.Stable; // Merging tends to create stability?
        if (fluctuationState > fluctuationThresholdHigh && randomSeed % 100 < 25) { // Chance of Superposed in high fluctuation
            newState = QuantumState.Superposed;
        } else if (randomSeed % 100 < 5) { // Small chance of Decaying
             newState = QuantumState.Decaying;
        }


         _particles[newId] = Particle({
            id: newId,
            owner: msg.sender,
            energy: newEnergy,
            purity: newPurity,
            quantumState: newState,
            creationBlock: block.number,
            lastObservedBlock: block.number,
            bondedPartnerId: 0
        });

        _addParticleToOwner(msg.sender, newId);

        // Mark original particles as collapsed/inactive
        _removeParticleFromOwner(msg.sender, particleId1);
        _removeParticleFromOwner(msg.sender, particleId2);
        _collapseParticle(particleId1); // Mark original as collapsed
        _collapseParticle(particleId2); // Mark original as collapsed
         delete _particles[particleId1]; // Actually delete for merge
         delete _particles[particleId2]; // Actually delete for merge


        emit ParticlesMerged(particleId1, particleId2, newId, newEnergy, newPurity);
        emit ParticleCollapsed(particleId1); // Represents the "consumption"
        emit ParticleCollapsed(particleId2); // Represents the "consumption"
        emit ParticleCreated(newId, msg.sender, newEnergy, newState);

        _updateFluctuationState(-50); // Merging reduces complexity
    }

     /**
      * @dev Triggers a significant, pseudo-random system-wide fluctuation event.
      *      Can dramatically change the overall state and potentially affect random particles.
      *      Requires payment of a cost or sacrifice of a particle (implemented with ETH cost here).
      */
     function triggerQuantumJump() external payable nonReentrant {
         require(msg.value >= quantumJumpCost, "Insufficient ETH to trigger Quantum Jump");

         uint256 randomSeed = _pseudoRandom(block.number.add(block.timestamp));
         int256 fluctuationEffect = int256((randomSeed % 2000) + 1000); // Large random change
         if (randomSeed % 2 == 0) fluctuationEffect = fluctuationEffect.mul(uint256(-1));

         _updateFluctuationState(fluctuationEffect);

         // Optional: Randomly affect a few particles' states
         uint256 totalParticles = _nextParticleId.sub(1);
         if (totalParticles > 0) {
             uint256 particlesToAffect = randomSeed % (totalParticles > 10 ? 10 : totalParticles.add(1)); // Affect up to 10 particles

             for (uint256 i = 0; i < particlesToAffect; i++) {
                 uint256 randomParticleId = (randomSeed.add(i).add(7)) % totalParticles.add(1); // Get a potential ID
                 if (randomParticleId == 0) continue; // Skip ID 0

                 Particle storage particle = _particles[randomParticleId];

                 // Check if particle exists and is not collapsed
                 if (_particleOwners[randomParticleId] != address(0) && particle.quantumState != QuantumState.Collapsed) {
                     // Apply a random state change or purity change
                     uint256 particleRandom = _pseudoRandom(particle.id.add(block.number).add(i));
                     particle.purity = (particle.purity.add(particleRandom % 1000)).mod(10001); // Random purity shift
                     particle.quantumState = QuantumState(particleRandom % 6); // Random state jump (might need validation)

                     // Ensure valid states after jump
                     if (particle.quantumState == QuantumState.Entangled) particle.quantumState = QuantumState.Superposed; // Cannot randomly become entangled
                     if (particle.quantumState == QuantumState.Unknown) particle.quantumState = QuantumState.Stable; // Unknown state unlikely

                     particle.lastObservedBlock = block.number;
                      emit ParticleObserved(particle.id, particle.purity, particle.quantumState); // Emit as an observation side-effect
                 }
             }
         }


         emit QuantumJumpTriggered(msg.sender, uint256(fluctuationEffect));
     }


    // --- Query Functions ---

    /**
     * @dev Gets the details of a specific particle.
     * @param particleId The ID of the particle.
     * @return The Particle struct.
     */
    function queryParticleState(uint256 particleId) external view particleExists(particleId) returns (Particle memory) {
        return _particles[particleId];
    }

    /**
     * @dev Gets the current overall system fluctuation state.
     * @return The fluctuation state value.
     */
    function queryOverallFluctuation() external view returns (uint256) {
        return fluctuationState;
    }

    /**
     * @dev Lists the IDs of all particles owned by a specific address.
     *      Note: Can be gas-intensive if an address owns many particles.
     * @param owner The address to query.
     * @return An array of particle IDs.
     */
    function listOwnerParticles(address owner) external view returns (uint256[] memory) {
        return _ownerParticles[owner];
    }

    /**
     * @dev Gets the total number of particles created in the system.
     * @return The total particle count.
     */
    function getParticleCount() external view returns (uint256) {
        return _nextParticleId.sub(1); // nextId is 1 + count
    }

     /**
      * @dev Predicts the potential outcome state(s) of a particle currently in Superposition.
      *      This is a simulation based on the current state and system fluctuation.
      *      Does NOT change the particle's state.
      * @param particleId The ID of the particle in Superposition.
      * @return predictedState The most likely state result.
      * @return stableProbability The estimated probability (0-10000) of collapsing to Stable.
      * @return decayingProbability The estimated probability (0-10000) of collapsing to Decaying.
      */
     function predictNextState(uint256 particleId) external view particleExists(particleId) returns (QuantumState predictedState, uint256 stableProbability, uint256 decayingProbability) {
        Particle memory particle = _particles[particleId]; // Read, not storage
        require(particle.quantumState == QuantumState.Superposed, "Particle is not in Superposed state");

        // Simulate the logic from measureSuperposition without state change
        // Probability influenced by fluctuation state
        uint256 baseStableChance = 6000; // Base chance to become Stable (60%)
        if (fluctuationState > fluctuationThresholdHigh) {
            stableProbability = baseStableChance.mul(5000).div(10000); // Lower chance to stabilize in high fluctuation (~30%)
        } else if (fluctuationState < fluctuationThresholdLow) {
            stableProbability = baseStableChance.mul(13333).div(10000); // Higher chance (~80%)
             stableProbability = stableProbability > 10000 ? 10000 : stableProbability; // Cap at 100%
        } else {
            stableProbability = baseStableChance; // Neutral state
        }

        decayingProbability = 10000 - stableProbability; // Remaining probability goes to Decaying

        // Determine the most likely predicted state
        predictedState = (stableProbability >= decayingProbability) ? QuantumState.Stable : QuantumState.Decaying;

        return (predictedState, stableProbability, decayingProbability);
     }
}
```