Okay, here is a smart contract concept I've developed called "Quantum Flux Protocol". It's designed to be unique by incorporating concepts of dynamic particle states, time-based decay, probabilistic interactions, global environmental factors, and a staking mechanism, all within a single non-standard framework. It's not a simple token, NFT, or standard DeFi primitive.

**Disclaimer:** This code is for educational and conceptual demonstration purposes. It uses `block.timestamp` and `blockhash` for pseudo-randomness, which is **not secure** for high-value outcomes as miners can influence these values. For production, a secure oracle like Chainlink VRF is required. Gas costs for functions iterating over arrays (like `getUserParticles` or `getParticlesByStateList`) can become very high with many particles; consider off-chain indexing or alternative data structures for scalability.

---

# Quantum Flux Protocol

## Outline:

1.  **Concept:** A protocol governing dynamic digital entities called "Flux Particles" that exist in different states (`Stable`, `Volatile`, `Decaying`, `Mutated`). Particles have energy levels and decay over time if not interacted with. Users can create, stabilize, charge, merge, split, mutate, and stake particles. A global "Instability Factor" influences particle behavior, which users can influence.
2.  **State Variables:**
    *   `owner`: Contract deployer/admin.
    *   `nextParticleId`: Counter for unique particle IDs.
    *   `particles`: Mapping from ID to `Particle` struct.
    *   `userParticles`: Mapping from user address to list of their particle IDs.
    *   `globalInstabilityFactor`: A parameter affecting particle decay and interactions.
    *   `decayRatePerMinute`: Base rate at which particle energy decays per minute.
    *   `stabilizationCost`: Cost in Ether to stabilize a particle.
    *   `chargeCost`: Cost in Ether to charge a particle.
    *   `mergeProbabilityNumerator/Denominator`: Base probability for successful merge.
    *   `splitProbabilityNumerator/Denominator`: Base probability for successful split.
    *   `mutationProbabilityNumerator/Denominator`: Base probability for successful mutation.
    *   `particleStaking`: Mapping from particle ID to stake start timestamp (0 if not staked).
3.  **Structs & Enums:**
    *   `Particle`: Struct defining a particle's properties (owner, state, energy, timestamps, mutation factor).
    *   `State`: Enum defining the possible states of a particle.
4.  **Events:** To log key actions and state changes.
5.  **Modifiers:** `onlyOwner` for administrative functions.
6.  **Functions:**
    *   **Admin/Setup (Owner Only):** Set global parameters, withdraw funds.
    *   **Particle Creation & Management:** Create new particles, get details, list user particles, transfer ownership.
    *   **Particle State & Energy Management:** Stabilize, charge, update state based on time, initiate decay.
    *   **Probabilistic Interactions:** Attempt merge, attempt split, mutate particle.
    *   **Staking:** Stake/unstake particles, check staking status.
    *   **Global Influence:** Contribute Ether to reduce global instability, trigger temporary flux events (owner only).
    *   **Querying:** Get contract state, total particles, counts/lists by state, global instability.

## Function Summary:

1.  `constructor()`: Initializes the contract with the owner.
2.  `receive() external payable`: Allows the contract to receive Ether for costs and contributions.
3.  `onlyOwner()`: Modifier to restrict access to owner-only functions.
4.  `_updateParticleStateBasedOnTime(uint256 _particleId)`: Internal helper to update a particle's state and energy based on elapsed time since last interaction, considering decay rate, staking status, and global instability.
5.  `_calculateCurrentState(uint256 _particleId)`: Internal helper to determine a particle's state based on its energy and last interaction time after decay is applied.
6.  `_generatePseudoRandomNumber(uint256 _seed)`: Internal helper for simple, *insecure* pseudo-random number generation using block data.
7.  `setGlobalInstabilityFactor(uint256 _factor)`: Owner sets the global instability parameter.
8.  `setDecayRatePerMinute(uint256 _rate)`: Owner sets the base energy decay rate.
9.  `setStabilizationCost(uint256 _cost)`: Owner sets the cost to stabilize a particle.
10. `setChargeCost(uint256 _cost)`: Owner sets the cost to charge a particle.
11. `setMergeProbability(uint256 _numerator, uint256 _denominator)`: Owner sets the base probability for merging.
12. `setSplitProbability(uint256 _numerator, uint256 _denominator)`: Owner sets the base probability for splitting.
13. `setMutationProbability(uint256 _numerator, uint256 _denominator)`: Owner sets the base probability for mutation.
14. `createParticle() payable`: Creates a new `Stable` particle for the caller, potentially requiring a fee.
15. `getParticleDetails(uint256 _particleId) view`: Retrieves all details of a specific particle after updating its potential state based on time.
16. `getUserParticles(address _user) view`: Lists all particle IDs owned by a specific user. *Gas Warning: Inefficient for many particles.*
17. `updateParticleState(uint256 _particleId)`: Allows anyone to trigger a time-based state update for a particle (e.g., before interacting).
18. `stabilizeParticle(uint256 _particleId) payable`: Pays the `stabilizationCost` to reset a particle's `lastInteractionTime` and potentially move it back to `Stable`.
19. `chargeParticle(uint256 _particleId) payable`: Pays the `chargeCost` to increase a particle's energy.
20. `initiateDecay(uint256 _particleId)`: Forces a particle to transition towards a `Decaying` state immediately, potentially triggering an event or outcome (e.g., releasing resources - not fully implemented here, but a concept).
21. `attemptMerge(uint256 _particleId1, uint256 _particleId2)`: Attempts to merge two particles owned by the caller. Outcome is probabilistic and depends on particle states/energy, potentially consuming the merged particles and creating a new, stronger one.
22. `attemptSplit(uint256 _particleId)`: Attempts to split a high-energy particle owned by the caller into two smaller ones. Probabilistic outcome.
23. `mutateParticle(uint256 _particleId)`: Attempts to mutate a particle owned by the caller. Probabilistic outcome, potentially changing state, energy, or mutation factor unpredictably.
24. `transferParticle(address _to, uint256 _particleId)`: Transfers ownership of a particle.
25. `stakeParticle(uint256 _particleId)`: Stakes a particle, pausing its time-based decay and potentially affecting interactions.
26. `unstakeParticle(uint256 _particleId)`: Unstakes a particle, resuming its time-based decay calculation.
27. `getStakeStatus(uint256 _particleId) view`: Checks if a particle is staked and when it was staked.
28. `contributeToStability() payable`: Users can send Ether to reduce the `globalInstabilityFactor` temporarily or permanently (implementation detail could vary - here, a simple reduction).
29. `triggerFluxEvent(int256 _instabilityChange)`: Owner can simulate a global event that changes instability (positive for stability boost, negative for instability spike).
30. `getTotalParticles() view`: Returns the total number of particles created.
31. `countParticlesByState(State _state) view`: Returns the number of particles currently in a specific state. *Gas Warning: Iterates through all particles.*
32. `getParticlesByStateList(State _state) view`: Returns a list of IDs for particles in a specific state. *Gas Warning: Iterates through all particles, potentially returning a large array.*
33. `getGlobalInstability() view`: Returns the current global instability factor.
34. `withdrawFunds(address payable _to, uint256 _amount)`: Owner withdraws collected Ether from the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Note: This contract uses block.timestamp and blockhash for pseudo-randomness,
// which is NOT secure for high-value outcomes due to miner manipulability.
// For a production system, use a secure VRF oracle like Chainlink VRF.
// Also, functions iterating over many particles can hit gas limits.

/**
 * @title Quantum Flux Protocol
 * @dev A protocol governing dynamic digital entities ("Flux Particles") with state, energy,
 *      time-based decay, probabilistic interactions, and global environmental influence.
 */
contract QuantumFluxProtocol {

    // --- Outline ---
    // 1. Concept: Dynamic particles, time-based decay, probabilistic interactions, global influence.
    // 2. State Variables: owner, nextParticleId, particles mapping, userParticles mapping, global factors, staking info.
    // 3. Structs & Enums: Particle struct, State enum.
    // 4. Events: Logging key actions.
    // 5. Modifiers: onlyOwner.
    // 6. Functions: Admin, Creation/Management, State/Energy, Interactions, Staking, Global Influence, Querying, Withdrawal.

    // --- Function Summary ---
    // 1. constructor(): Initializes owner.
    // 2. receive() external payable: Allows contract to receive Ether.
    // 3. onlyOwner(): Modifier for admin functions.
    // 4. _updateParticleStateBasedOnTime(uint256): Internal helper for time-based decay/state update.
    // 5. _calculateCurrentState(uint256): Internal helper to determine state after decay.
    // 6. _generatePseudoRandomNumber(uint256): INTERNAL, INSECURE pseudo-random number generator.
    // 7. setGlobalInstabilityFactor(uint256): Admin - Sets global instability.
    // 8. setDecayRatePerMinute(uint256): Admin - Sets energy decay rate.
    // 9. setStabilizationCost(uint256): Admin - Sets stabilization cost.
    // 10. setChargeCost(uint256): Admin - Sets charging cost.
    // 11. setMergeProbability(uint256, uint256): Admin - Sets merge probability base.
    // 12. setSplitProbability(uint256, uint256): Admin - Sets split probability base.
    // 13. setMutationProbability(uint256, uint256): Admin - Sets mutation probability base.
    // 14. createParticle() payable: Creates a new particle for caller.
    // 15. getParticleDetails(uint256) view: Gets particle details (after time update).
    // 16. getUserParticles(address) view: Gets list of particle IDs for a user.
    // 17. updateParticleState(uint256): Anyone can trigger state update for a particle.
    // 18. stabilizeParticle(uint256) payable: Stabilizes a particle (resets decay time).
    // 19. chargeParticle(uint256) payable: Increases particle energy.
    // 20. initiateDecay(uint256): Forces decay (conceptional).
    // 21. attemptMerge(uint256, uint256): Attempts merging two particles.
    // 22. attemptSplit(uint256): Attempts splitting a particle.
    // 23. mutateParticle(uint256): Attempts mutating a particle.
    // 24. transferParticle(address, uint256): Transfers particle ownership.
    // 25. stakeParticle(uint256): Stakes a particle.
    // 26. unstakeParticle(uint256): Unstakes a particle.
    // 27. getStakeStatus(uint256) view: Checks staking status.
    // 28. contributeToStability() payable: Reduces global instability.
    // 29. triggerFluxEvent(int256): Admin - Modifies global instability.
    // 30. getTotalParticles() view: Total particle count.
    // 31. countParticlesByState(State) view: Count particles by state.
    // 32. getParticlesByStateList(State) view: List particles by state.
    // 33. getGlobalInstability() view: Get current global instability.
    // 34. withdrawFunds(address payable, uint256): Admin - Withdraws Ether.

    // --- Enums ---
    enum State {
        Stable,
        Volatile,
        Decaying,
        Mutated,
        Null // Represents a non-existent particle or placeholder
    }

    // --- Structs ---
    struct Particle {
        uint256 id;
        address owner;
        State state;
        uint256 energy; // Represents health/vitality
        uint256 creationTime;
        uint256 lastInteractionTime; // Used for decay calculation
        uint256 mutationFactor; // Influences mutation chance/outcome
        // Future possible fields: type, properties affecting interactions, etc.
    }

    // --- State Variables ---
    address public owner;
    uint256 public nextParticleId = 1; // Start IDs from 1

    mapping(uint256 => Particle) public particles;
    mapping(address => uint256[]) private userParticles; // Store user's particle IDs

    // Global Parameters (Influence particle behavior)
    uint256 public globalInstabilityFactor = 100; // Base instability, higher = more decay/volatility
    uint256 public decayRatePerMinute = 5; // Energy points lost per minute in non-staked/stable states

    // Costs in wei
    uint256 public stabilizationCost = 0.01 ether;
    uint256 public chargeCost = 0.005 ether;
    uint256 public createParticleCost = 0.02 ether;

    // Probabilities (numerator/denominator)
    uint256 public mergeProbabilityNumerator = 60; // 60/100 = 60% base chance
    uint256 public mergeProbabilityDenominator = 100;
    uint256 public splitProbabilityNumerator = 30; // 30/100 = 30% base chance
    uint256 public splitProbabilityDenominator = 100;
    uint256 public mutationProbabilityNumerator = 20; // 20/100 = 20% base chance
    uint256 public mutationProbabilityDenominator = 100;

    // Staking
    mapping(uint256 => uint256) public particleStaking; // particleId => stakeStartTime (0 if not staked)

    // --- Events ---
    event ParticleCreated(uint256 indexed id, address indexed owner, uint256 initialEnergy);
    event StateChanged(uint256 indexed id, State indexed newState, State oldState);
    event EnergyChanged(uint256 indexed id, uint256 newEnergy, uint256 oldEnergy);
    event ParticleTransferred(uint256 indexed id, address indexed from, address indexed to);
    event ParticlesMerged(uint256 indexed id1, uint256 indexed id2, uint256 indexed newParticleId);
    event ParticleSplit(uint256 indexed id, uint256 indexed newParticleId1, uint256 indexed newParticleId2);
    event ParticleMutated(uint256 indexed id, uint256 newMutationFactor);
    event ParticleStaked(uint256 indexed id, uint256 timestamp);
    event ParticleUnstaked(uint256 indexed id, uint256 timestamp);
    event GlobalInstabilityChanged(uint256 newFactor, uint256 oldFactor);
    event StabilityContributed(address indexed user, uint256 amount);
    event FluxEventTriggered(int256 instabilityChange);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier particleExists(uint256 _particleId) {
        require(_particleId > 0 && _particleId < nextParticleId, "Invalid particle ID");
        require(particles[_particleId].owner != address(0), "Particle does not exist or was consumed");
        _;
    }

    modifier isParticleOwner(uint256 _particleId) {
        require(particles[_particleId].owner == msg.sender, "Not the owner of this particle");
        _;
    }

    // --- Internal / Helper Functions ---

    /**
     * @dev Internal function to update a particle's state and energy based on time elapsed.
     * Applies decay unless staked.
     * @param _particleId The ID of the particle to update.
     */
    function _updateParticleStateBasedOnTime(uint256 _particleId) internal {
        Particle storage particle = particles[_particleId];
        require(particle.owner != address(0), "Particle does not exist"); // Should be covered by particleExists if external

        uint256 lastTime = particle.lastInteractionTime;
        if (particleStaking[_particleId] > 0) {
            // If staked, last interaction time is effectively now for decay calculation purposes
            lastTime = block.timestamp;
        }

        uint256 timeElapsed = block.timestamp - lastTime;
        uint256 decayAmount = 0;

        if (timeElapsed > 0 && particleStaking[_particleId] == 0) {
            // Calculate decay based on time and global instability
            // Decay is faster when instability is higher
            decayAmount = (timeElapsed / 60) * decayRatePerMinute * (globalInstabilityFactor + 100) / 100; // Base + instability %

            if (decayAmount > particle.energy) {
                particle.energy = 0;
            } else {
                particle.energy -= decayAmount;
            }
            emit EnergyChanged(_particleId, particle.energy, particle.energy + decayAmount);
        }

        // Update state based on new energy/time
        State oldState = particle.state;
        particle.state = _calculateCurrentState(_particleId);
        particle.lastInteractionTime = block.timestamp; // Update last interaction time after state check

        if (particle.state != oldState) {
            emit StateChanged(_particleId, particle.state, oldState);
        }
    }

    /**
     * @dev Internal function to determine a particle's state based on its current energy level.
     * Assumes decay has just been applied.
     * @param _particleId The ID of the particle.
     * @return The calculated state.
     */
    function _calculateCurrentState(uint256 _particleId) internal view returns (State) {
        uint256 energy = particles[_particleId].energy;
        // State transitions based on energy thresholds (example thresholds)
        if (energy > 800) return State.Stable;
        if (energy > 400) return State.Volatile;
        if (energy > 0) return State.Decaying;
        return State.Null; // Represents fully decayed/inert (could transition to a 'Spent' or 'Dust' state)
    }

    /**
     * @dev INTERNAL AND INSECURE PSEUDO-RANDOM NUMBER GENERATION.
     * DO NOT use for high-value outcomes in production.
     * Miner can manipulate blockhash.
     * @param _seed Additional seed for randomness.
     * @return A pseudo-random uint256.
     */
    function _generatePseudoRandomNumber(uint256 _seed) internal view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, block.number, blockhash(block.number - 1), _seed)));
        return seed;
    }

    /**
     * @dev Internal helper to add a particle ID to a user's list.
     * @param _user The user's address.
     * @param _particleId The particle ID.
     */
    function _addUserParticle(address _user, uint256 _particleId) internal {
        userParticles[_user].push(_particleId);
    }

    /**
     * @dev Internal helper to remove a particle ID from a user's list.
     * @param _user The user's address.
     * @param _particleId The particle ID.
     */
    function _removeUserParticle(address _user, uint256 _particleId) internal {
        uint256[] storage pList = userParticles[_user];
        for (uint i = 0; i < pList.length; i++) {
            if (pList[i] == _particleId) {
                // Replace with last element and pop (efficient removal)
                pList[i] = pList[pList.length - 1];
                pList.pop();
                break; // Found and removed
            }
        }
    }


    // --- Admin / Setup Functions (onlyOwner) ---

    /**
     * @dev Sets the global instability factor. Affects decay rate.
     * @param _factor The new global instability factor.
     */
    function setGlobalInstabilityFactor(uint256 _factor) external onlyOwner {
        require(_factor <= 1000, "Instability factor too high"); // Example sanity check
        uint256 oldFactor = globalInstabilityFactor;
        globalInstabilityFactor = _factor;
        emit GlobalInstabilityChanged(globalInstabilityFactor, oldFactor);
    }

    /**
     * @dev Sets the base energy decay rate per minute.
     * @param _rate The new decay rate.
     */
    function setDecayRatePerMinute(uint256 _rate) external onlyOwner {
        decayRatePerMinute = _rate;
    }

    /**
     * @dev Sets the cost to stabilize a particle.
     * @param _cost The new stabilization cost in wei.
     */
    function setStabilizationCost(uint256 _cost) external onlyOwner {
        stabilizationCost = _cost;
    }

    /**
     * @dev Sets the cost to charge a particle.
     * @param _cost The new charge cost in wei.
     */
    function setChargeCost(uint256 _cost) external onlyOwner {
        chargeCost = _cost;
    }

    /**
     * @dev Sets the base probability for successful merge attempts.
     * @param _numerator Numerator of the probability fraction.
     * @param _denominator Denominator of the probability fraction.
     */
    function setMergeProbability(uint256 _numerator, uint256 _denominator) external onlyOwner {
        require(_denominator > 0, "Denominator cannot be zero");
        mergeProbabilityNumerator = _numerator;
        mergeProbabilityDenominator = _denominator;
    }

    /**
     * @dev Sets the base probability for successful split attempts.
     * @param _numerator Numerator of the probability fraction.
     * @param _denominator Denominator of the probability fraction.
     */
    function setSplitProbability(uint256 _numerator, uint256 _denominator) external onlyOwner {
        require(_denominator > 0, "Denominator cannot be zero");
        splitProbabilityNumerator = _numerator;
        splitProbabilityDenominator = _denominator;
    }

    /**
     * @dev Sets the base probability for successful mutation attempts.
     * @param _numerator Numerator of the probability fraction.
     * @param _denominator Denominator of the probability fraction.
     */
    function setMutationProbability(uint256 _numerator, uint256 _denominator) external onlyOwner {
        require(_denominator > 0, "Denominator cannot be zero");
        mutationProbabilityNumerator = _numerator;
        mutationProbabilityDenominator = _denominator;
    }

    // --- Particle Creation & Management ---

    /**
     * @dev Creates a new Flux Particle for the caller. Requires payment.
     * @dev Initial energy is random for variability.
     */
    function createParticle() external payable {
        require(msg.value >= createParticleCost, "Insufficient Ether to create particle");

        uint256 newId = nextParticleId;
        // Initial energy could be random, e.g., 500 + random(0, 500)
        uint256 initialEnergy = 500 + (_generatePseudoRandomNumber(newId) % 501); // Energy between 500 and 1000

        particles[newId] = Particle({
            id: newId,
            owner: msg.sender,
            state: State.Stable, // Starts stable
            energy: initialEnergy,
            creationTime: block.timestamp,
            lastInteractionTime: block.timestamp,
            mutationFactor: _generatePseudoRandomNumber(newId * 2) % 100 // Random initial mutation factor
        });

        _addUserParticle(msg.sender, newId);

        emit ParticleCreated(newId, msg.sender, initialEnergy);
        nextParticleId++;
    }

    /**
     * @dev Retrieves details of a specific particle. Updates state based on time before returning.
     * @param _particleId The ID of the particle.
     * @return Particle struct details.
     */
    function getParticleDetails(uint256 _particleId) external particleExists(_particleId) view returns (Particle memory) {
        // Create a temporary struct to return current values *after* potential decay calculation
        // Note: This view function cannot modify state, so it simulates the update.
        // An external call to updateParticleState might be needed before viewing for accuracy in state.
        Particle memory particle = particles[_particleId];
        uint256 lastTime = particle.lastInteractionTime;
        if (particleStaking[_particleId] > 0) {
             lastTime = block.timestamp; // Simulate staked state preventing decay
        }

        uint256 timeElapsed = block.timestamp - lastTime;
        uint256 decayAmount = 0;

         if (timeElapsed > 0 && particleStaking[_particleId] == 0) {
            decayAmount = (timeElapsed / 60) * decayRatePerMinute * (globalInstabilityFactor + 100) / 100;
            if (decayAmount > particle.energy) {
                particle.energy = 0;
            } else {
                particle.energy -= decayAmount;
            }
        }
        particle.state = _calculateCurrentState(_particleId); // Calculate state based on simulated energy

        return particle;
    }


    /**
     * @dev Lists all particle IDs owned by a specific user.
     * @param _user The address of the user.
     * @return An array of particle IDs.
     * @notice Gas Warning: This function can be very expensive for users with many particles.
     */
    function getUserParticles(address _user) external view returns (uint256[] memory) {
        return userParticles[_user];
    }

    /**
     * @dev Transfers ownership of a particle to another address.
     * @param _to The recipient address.
     * @param _particleId The ID of the particle to transfer.
     */
    function transferParticle(address _to, uint256 _particleId) external particleExists(_particleId) isParticleOwner(_particleId) {
        require(_to != address(0), "Transfer to zero address");
        require(particleStaking[_particleId] == 0, "Cannot transfer staked particle");

        address from = msg.sender;
        Particle storage particle = particles[_particleId];

        _updateParticleStateBasedOnTime(_particleId); // Update state before transfer

        particle.owner = _to;
        _removeUserParticle(from, _particleId);
        _addUserParticle(_to, _particleId);

        emit ParticleTransferred(_particleId, from, _to);
    }


    // --- Particle State & Energy Management ---

    /**
     * @dev Allows anyone to trigger a time-based state update for a specific particle.
     * Useful before performing other actions to ensure state is current.
     * @param _particleId The ID of the particle to update.
     */
    function updateParticleState(uint256 _particleId) external particleExists(_particleId) {
         _updateParticleStateBasedOnTime(_particleId);
         // StateChanged and EnergyChanged events are emitted inside _updateParticleStateBasedOnTime
    }

    /**
     * @dev Stabilizes a particle, resetting its last interaction time to now. Requires payment.
     * Can potentially move the particle back to a more stable state if energy allows.
     * @param _particleId The ID of the particle to stabilize.
     */
    function stabilizeParticle(uint256 _particleId) external payable particleExists(_particleId) isParticleOwner(_particleId) {
        require(msg.value >= stabilizationCost, "Insufficient Ether to stabilize");
        require(particleStaking[_particleId] == 0, "Cannot stabilize a staked particle"); // Staked is already "stable" from decay perspective

        _updateParticleStateBasedOnTime(_particleId); // Update state before action

        Particle storage particle = particles[_particleId];
        // Stabilization effect: Sets last interaction time to now, pausing decay.
        // Also might boost energy slightly or adjust state threshold for stability.
        // Example: If Decaying, maybe give a small energy boost
        if (particle.state == State.Decaying && particle.energy > 0) {
             uint256 energyBoost = particle.energy / 10; // Small boost
             particle.energy += energyBoost;
             emit EnergyChanged(_particleId, particle.energy, particle.energy - energyBoost);
        }
        particle.lastInteractionTime = block.timestamp; // This is the main stabilization effect

        State oldState = particle.state;
        particle.state = _calculateCurrentState(_particleId); // Recalculate state after action

        if (particle.state != oldState) {
            emit StateChanged(_particleId, particle.state, oldState);
        }
        // Ether is collected by the contract
    }

    /**
     * @dev Charges a particle, increasing its energy level. Requires payment.
     * Effectiveness might depend on current state.
     * @param _particleId The ID of the particle to charge.
     */
    function chargeParticle(uint256 _particleId) external payable particleExists(_particleId) isParticleOwner(_particleId) {
        require(msg.value >= chargeCost, "Insufficient Ether to charge");
        require(particleStaking[_particleId] == 0, "Cannot charge a staked particle"); // Staked particles might not need charging

        _updateParticleStateBasedOnTime(_particleId); // Update state before action

        Particle storage particle = particles[_particleId];
        require(particle.energy < 1000, "Particle is already fully charged"); // Max energy example

        uint256 chargeAmount = 100 + (_generatePseudoRandomNumber(particle.id + block.number) % 101); // Example: Add 100-200 energy

        // Effectiveness could depend on state: Decaying gets more, Stable gets less
        if (particle.state == State.Decaying) chargeAmount = chargeAmount * 2;
        if (particle.state == State.Stable) chargeAmount = chargeAmount / 2;

        uint256 oldEnergy = particle.energy;
        particle.energy += chargeAmount;
        if (particle.energy > 1000) particle.energy = 1000; // Cap energy

        emit EnergyChanged(_particleId, particle.energy, oldEnergy);

        State oldState = particle.state;
        particle.state = _calculateCurrentState(_particleId); // Recalculate state after action

        if (particle.state != oldState) {
            emit StateChanged(_particleId, particle.state, oldState);
        }
        particle.lastInteractionTime = block.timestamp; // Charging also counts as interaction
        // Ether is collected by the contract
    }

    /**
     * @dev Initiates a deliberate decay process for a particle.
     * This could have specific outcomes not tied to the passive time-based decay,
     * e.g., yielding temporary resources, changing properties faster. (Conceptual - requires specific outcome logic)
     * @param _particleId The ID of the particle.
     */
    function initiateDecay(uint256 _particleId) external particleExists(_particleId) isParticleOwner(_particleId) {
        require(particleStaking[_particleId] == 0, "Cannot initiate decay on a staked particle");

        _updateParticleStateBasedOnTime(_particleId); // Update state before action

        Particle storage particle = particles[_particleId];
        require(particle.state != State.Null, "Particle is already inert");

        State oldState = particle.state;
        particle.state = State.Decaying; // Force Decaying state
        particle.lastInteractionTime = block.timestamp; // Update interaction time

        // *** Implement specific outcome logic for initiated decay here ***
        // Example: Maybe a small amount of energy is released immediately?
        // Or it unlocks a special interaction only possible in the Decaying state?
        // For this example, we just force the state change.

        if (particle.state != oldState) {
            emit StateChanged(_particleId, particle.state, oldState);
        }
    }


    // --- Probabilistic Interaction Functions ---

    /**
     * @dev Attempts to merge two particles owned by the caller.
     * Probabilistic outcome based on states, energy, and global instability.
     * Success consumes the two particles and potentially creates a new one.
     * @param _particleId1 ID of the first particle.
     * @param _particleId2 ID of the second particle.
     */
    function attemptMerge(uint256 _particleId1, uint256 _particleId2) external particleExists(_particleId1) particleExists(_particleId2) {
        require(_particleId1 != _particleId2, "Cannot merge a particle with itself");
        require(particles[_particleId1].owner == msg.sender && particles[_particleId2].owner == msg.sender, "Must own both particles to attempt merge");
        require(particleStaking[_particleId1] == 0 && particleStaking[_particleId2] == 0, "Cannot merge staked particles");

        _updateParticleStateBasedOnTime(_particleId1); // Update state before action
        _updateParticleStateBasedOnTime(_particleId2);

        Particle storage p1 = particles[_particleId1];
        Particle storage p2 = particles[_particleId2];

        // Particles must be in compatible states (example: not Null, maybe Volatile or Mutated are best?)
        require(p1.state != State.Null && p2.state != State.Null, "Cannot merge inert particles");
        // require(p1.state == State.Volatile || p2.state == State.Volatile, "Merge requires at least one volatile particle"); // Example rule

        uint256 baseProbability = (mergeProbabilityNumerator * 100) / mergeProbabilityDenominator; // Convert to base 100
        // Adjust probability based on states, energy, instability, etc.
        // Example: Higher energy = higher chance, Decaying state = lower chance, Instability = higher chance?
        uint256 effectiveProbability = baseProbability;
        effectiveProbability += (p1.energy + p2.energy) / 50; // +1% chance per 50 combined energy
        if (p1.state == State.Decaying || p2.state == State.Decaying) effectiveProbability -= 20; // -20% chance if decaying
        if (globalInstabilityFactor > 150) effectiveProbability += (globalInstabilityFactor - 150) / 5; // +1% per 5 instability over 150

        if (effectiveProbability > 100) effectiveProbability = 100;
        if (effectiveProbability < 0) effectiveProbability = 0;


        uint256 randomNum = _generatePseudoRandomNumber(_particleId1 + _particleId2 + block.timestamp) % 100; // 0-99

        if (randomNum < effectiveProbability) {
            // --- Merge Successful ---
            uint256 newId = nextParticleId;
            uint256 combinedEnergy = (p1.energy + p2.energy) * 8 / 10; // 80% energy retention
            uint256 newMutationFactor = (p1.mutationFactor + p2.mutationFactor) / 2; // Average mutation factor

            particles[newId] = Particle({
                id: newId,
                owner: msg.sender,
                state: _calculateCurrentState(newId), // Calculate initial state
                energy: combinedEnergy,
                creationTime: block.timestamp,
                lastInteractionTime: block.timestamp,
                mutationFactor: newMutationFactor
            });
            _addUserParticle(msg.sender, newId);
            nextParticleId++;

            // Consume original particles
            _removeUserParticle(msg.sender, _particleId1);
            _removeUserParticle(msg.sender, _particleId2);
            delete particles[_particleId1];
            delete particles[_particleId2]; // Mark as consumed

            emit ParticlesMerged(_particleId1, _particleId2, newId);
            // Note: StateChanged/EnergyChanged for the *new* particle will be calculated on first fetch/interaction
        } else {
            // --- Merge Failed ---
            // Particles might lose energy or change state unpredictably on failure
            uint256 energyLoss = (p1.energy + p2.energy) / 10; // 10% energy loss
            p1.energy = p1.energy > energyLoss/2 ? p1.energy - energyLoss/2 : 0;
            p2.energy = p2.energy > energyLoss/2 ? p2.energy - energyLoss/2 : 0;

            emit EnergyChanged(_particleId1, p1.energy, p1.energy + energyLoss/2);
            emit EnergyChanged(_particleId2, p2.energy, p2.energy + energyLoss/2);

            State oldState1 = p1.state;
            State oldState2 = p2.state;
            p1.state = _calculateCurrentState(_particleId1);
            p2.state = _calculateCurrentState(_particleId2);

             if (p1.state != oldState1) emit StateChanged(_particleId1, p1.state, oldState1);
             if (p2.state != oldState2) emit StateChanged(_particleId2, p2.state, oldState2);

            // No event for failed merge explicitly, implicit via state/energy changes
        }
         // Update last interaction time for remaining/new particles if applicable
        p1.lastInteractionTime = block.timestamp;
        p2.lastInteractionTime = block.timestamp;
    }

    /**
     * @dev Attempts to split a high-energy particle into two.
     * Probabilistic outcome based on energy, state, and global instability.
     * Success consumes the original particle and creates two new ones.
     * @param _particleId ID of the particle to attempt splitting.
     */
    function attemptSplit(uint256 _particleId) external particleExists(_particleId) isParticleOwner(_particleId) {
        require(particleStaking[_particleId] == 0, "Cannot split a staked particle");

        _updateParticleStateBasedOnTime(_particleId); // Update state before action

        Particle storage p = particles[_particleId];
        require(p.energy > 500, "Particle energy too low to attempt split"); // Example energy requirement
        require(p.state != State.Null, "Cannot split inert particle");

        uint256 baseProbability = (splitProbabilityNumerator * 100) / splitProbabilityDenominator; // Convert to base 100
        // Adjust probability based on energy, state, instability
        uint256 effectiveProbability = baseProbability;
        effectiveProbability += (p.energy - 500) / 10; // +1% chance per 10 energy over 500
        if (p.state == State.Stable) effectiveProbability -= 15; // Less likely if too stable
         if (globalInstabilityFactor > 120) effectiveProbability += (globalInstabilityFactor - 120) / 8; // +1% per 8 instability over 120

        if (effectiveProbability > 100) effectiveProbability = 100;
        if (effectiveProbability < 0) effectiveProbability = 0;


        uint256 randomNum = _generatePseudoRandomNumber(_particleId + block.number + 1) % 100; // 0-99

        if (randomNum < effectiveProbability) {
            // --- Split Successful ---
            uint256 newId1 = nextParticleId;
            uint256 newId2 = nextParticleId + 1;
            uint256 splitEnergy = p.energy / 2; // Split energy between the two new particles

            particles[newId1] = Particle({
                id: newId1,
                owner: msg.sender,
                state: _calculateCurrentState(newId1),
                energy: splitEnergy,
                creationTime: block.timestamp,
                lastInteractionTime: block.timestamp,
                mutationFactor: p.mutationFactor + (_generatePseudoRandomNumber(newId1 * 3) % 20) // Slight mutation factor change
            });

             particles[newId2] = Particle({
                id: newId2,
                owner: msg.sender,
                state: _calculateCurrentState(newId2),
                energy: splitEnergy,
                creationTime: block.timestamp,
                lastInteractionTime: block.timestamp,
                mutationFactor: p.mutationFactor - (_generatePseudoRandomNumber(newId2 * 4) % 20) // Slight mutation factor change (can go negative conceptually?)
            });
             // Ensure mutationFactor stays non-negative (example)
             if(particles[newId2].mutationFactor > p.mutationFactor) particles[newId2].mutationFactor = 0;


            _addUserParticle(msg.sender, newId1);
            _addUserParticle(msg.sender, newId2);
            nextParticleId += 2;

            // Consume original particle
            _removeUserParticle(msg.sender, _particleId);
            delete particles[_particleId]; // Mark as consumed

            emit ParticleSplit(_particleId, newId1, newId2);
        } else {
             // --- Split Failed ---
             // Particle loses significant energy and becomes volatile/decaying
            uint256 energyLoss = p.energy / 3; // 33% energy loss
            p.energy = p.energy > energyLoss ? p.energy - energyLoss : 0;

            emit EnergyChanged(_particleId, p.energy, p.energy + energyLoss);

            State oldState = p.state;
            p.state = _calculateCurrentState(_particleId); // Recalculate state
            if (p.state != oldState) emit StateChanged(_particleId, p.state, oldState);

            // No event for failed split
        }
         // Update last interaction time for remaining particle if applicable
        p.lastInteractionTime = block.timestamp;
    }

    /**
     * @dev Attempts to mutate a particle.
     * Probabilistic outcome based on mutation factor, state, and global instability.
     * Success can change energy, mutation factor, or even state unpredictably.
     * @param _particleId ID of the particle to attempt mutating.
     */
    function mutateParticle(uint256 _particleId) external particleExists(_particleId) isParticleOwner(_particleId) {
        require(particleStaking[_particleId] == 0, "Cannot mutate a staked particle");

        _updateParticleStateBasedOnTime(_particleId); // Update state before action

        Particle storage p = particles[_particleId];
        require(p.state != State.Null, "Cannot mutate inert particle");

        uint256 baseProbability = (mutationProbabilityNumerator * 100) / mutationProbabilityDenominator; // Convert to base 100
        // Adjust probability based on mutation factor, state, instability
        uint256 effectiveProbability = baseProbability;
        effectiveProbability += p.mutationFactor / 2; // +1% chance per 2 mutation factor
        if (p.state == State.Decaying) effectiveProbability += 10; // More likely if decaying
        if (globalInstabilityFactor > 100) effectiveProbability += (globalInstabilityFactor - 100) / 10; // +1% per 10 instability over 100


        if (effectiveProbability > 100) effectiveProbability = 100;
        if (effectiveProbability < 0) effectiveProbability = 0;

        uint256 randomNum = _generatePseudoRandomNumber(_particleId + block.number + 2) % 100; // 0-99

        if (randomNum < effectiveProbability) {
            // --- Mutation Successful ---
            uint256 mutationOutcome = _generatePseudoRandomNumber(_particleId + block.timestamp) % 100; // Different seed for outcome type

            uint256 oldEnergy = p.energy;
            uint256 oldMutationFactor = p.mutationFactor;
            State oldState = p.state;

            // Example outcomes based on mutationOutcome random number
            if (mutationOutcome < 30) { // 30% chance: Energy fluctuation
                int256 energyChange = int256(_generatePseudoRandomNumber(mutationOutcome) % 401) - 200; // Change between -200 and +200
                if (energyChange < 0) {
                    uint256 loss = uint256(-energyChange);
                    p.energy = p.energy > loss ? p.energy - loss : 0;
                     emit EnergyChanged(_particleId, p.energy, oldEnergy);
                } else {
                     p.energy += uint256(energyChange);
                     if (p.energy > 1000) p.energy = 1000; // Cap energy
                     emit EnergyChanged(_particleId, p.energy, oldEnergy);
                }
            } else if (mutationOutcome < 60) { // 30% chance: Mutation factor change
                int256 factorChange = int256(_generatePseudoRandomNumber(mutationOutcome) % 51) - 25; // Change between -25 and +25
                 if (factorChange < 0) {
                    uint256 loss = uint256(-factorChange);
                    p.mutationFactor = p.mutationFactor > loss ? p.mutationFactor - loss : 0;
                 } else {
                     p.mutationFactor += uint256(factorChange);
                 }
                emit ParticleMutated(_particleId, p.mutationFactor);
            } else if (mutationOutcome < 80) { // 20% chance: State shift (unpredictable)
                 uint256 stateShift = _generatePseudoRandomNumber(mutationOutcome) % 4;
                 if (stateShift == 0) p.state = State.Stable;
                 else if (stateShift == 1) p.state = State.Volatile;
                 else if (stateShift == 2) p.state = State.Decaying;
                 else p.state = State.Mutated; // Can it become Mutated state directly? Yes, in a mutation!
                 if (p.state != oldState) emit StateChanged(_particleId, p.state, oldState);
            } else { // 20% chance: Minor combined effects or unusual outcome
                 // E.g., Small energy boost + small mutation factor boost
                 p.energy += 50;
                 if (p.energy > 1000) p.energy = 1000;
                 p.mutationFactor += 10;
                 emit EnergyChanged(_particleId, p.energy, oldEnergy);
                 emit ParticleMutated(_particleId, p.mutationFactor);
            }

             // Re-calculate state based on potentially new energy/properties (unless state was directly set)
             if(mutationOutcome >= 30 && mutationOutcome < 80) { // If state wasn't directly set
                 p.state = _calculateCurrentState(_particleId);
                 if (p.state != oldState) emit StateChanged(_particleId, p.state, oldState);
             } else if (mutationOutcome < 30) { // If energy changed
                 p.state = _calculateCurrentState(_particleId);
                 if (p.state != oldState) emit StateChanged(_particleId, p.state, oldState);
             }
             // Mutation also counts as interaction
             p.lastInteractionTime = block.timestamp;

        } else {
             // --- Mutation Failed ---
             // Particle loses energy and instability might increase locally or globally
            uint256 energyLoss = p.energy / 5; // 20% energy loss
            p.energy = p.energy > energyLoss ? p.energy - energyLoss : 0;

            emit EnergyChanged(_particleId, p.energy, p.energy + energyLoss);

            State oldState = p.state;
            p.state = _calculateCurrentState(_particleId); // Recalculate state
            if (p.state != oldState) emit StateChanged(_particleId, p.state, oldState);

             // Failed mutation increases local instability/volatility (represented by energy loss/state change)
             // Could also slightly increase global instability? (Conceptual)
        }
         // Update last interaction time
         p.lastInteractionTime = block.timestamp;
    }


    // --- Staking Functions ---

    /**
     * @dev Stakes a particle. Pauses time-based decay.
     * @param _particleId The ID of the particle to stake.
     */
    function stakeParticle(uint256 _particleId) external particleExists(_particleId) isParticleOwner(_particleId) {
        require(particleStaking[_particleId] == 0, "Particle is already staked");

        _updateParticleStateBasedOnTime(_particleId); // Update state before staking

        particleStaking[_particleId] = block.timestamp;
        particles[_particleId].lastInteractionTime = block.timestamp; // Reset interaction time on stake

        emit ParticleStaked(_particleId, block.timestamp);
    }

    /**
     * @dev Unstakes a particle. Resumes time-based decay calculation from now.
     * @param _particleId The ID of the particle to unstake.
     */
    function unstakeParticle(uint256 _particleId) external particleExists(_particleId) isParticleOwner(_particleId) {
        require(particleStaking[_particleId] > 0, "Particle is not staked");

        // Note: Decay is calculated from the moment it's unstaked, not from stake time.
        // _updateParticleStateBasedOnTime will use the *current* block.timestamp vs lastInteractionTime (which was reset on stake).
        particleStaking[_particleId] = 0;
        particles[_particleId].lastInteractionTime = block.timestamp; // Reset interaction time on unstake too

        emit ParticleUnstaked(_particleId, block.timestamp);
    }

    /**
     * @dev Checks the staking status of a particle.
     * @param _particleId The ID of the particle.
     * @return timestamp The timestamp when the particle was staked (0 if not staked).
     */
    function getStakeStatus(uint256 _particleId) external view particleExists(_particleId) returns (uint256 timestamp) {
        return particleStaking[_particleId];
    }

    // --- Global Influence Functions ---

    /**
     * @dev Allows users to contribute Ether to reduce the global instability factor.
     * The amount of instability reduced depends on the Ether sent.
     */
    function contributeToStability() external payable {
        require(msg.value > 0, "Must send Ether to contribute");

        // Example: Every 0.1 Ether reduces instability by 1 point (capped at a floor)
        uint256 instabilityReduction = (msg.value / 0.1 ether); // Integer division
        uint256 oldFactor = globalInstabilityFactor;

        if (globalInstabilityFactor > instabilityReduction) {
            globalInstabilityFactor -= instabilityReduction;
        } else {
            globalInstabilityFactor = 0; // Cannot go below 0 (or some floor)
        }

        emit StabilityContributed(msg.sender, msg.value);
        if (globalInstabilityFactor != oldFactor) {
             emit GlobalInstabilityChanged(globalInstabilityFactor, oldFactor);
        }
        // Ether is collected by the contract
    }

    /**
     * @dev Owner can trigger a "Flux Event" that temporarily or permanently changes
     * the global instability factor.
     * @param _instabilityChange The amount to add or subtract from the global instability.
     */
    function triggerFluxEvent(int256 _instabilityChange) external onlyOwner {
        uint256 oldFactor = globalInstabilityFactor;

        if (_instabilityChange > 0) {
            globalInstabilityFactor += uint256(_instabilityChange);
             if (globalInstabilityFactor > 1000) globalInstabilityFactor = 1000; // Cap example
        } else if (_instabilityChange < 0) {
            uint256 reduction = uint256(-_instabilityChange);
             if (globalInstabilityFactor > reduction) {
                globalInstabilityFactor -= reduction;
             } else {
                globalInstabilityFactor = 0; // Cannot go below 0 (or some floor)
             }
        }

        emit FluxEventTriggered(_instabilityChange);
        if (globalInstabilityFactor != oldFactor) {
             emit GlobalInstabilityChanged(globalInstabilityFactor, oldFactor);
        }
    }

    // --- Querying Functions ---

    /**
     * @dev Returns the total number of particles that have ever been created.
     * @return The total count.
     */
    function getTotalParticles() external view returns (uint256) {
        return nextParticleId - 1;
    }

    /**
     * @dev Counts the number of particles currently in a specific state.
     * Note: This requires iterating through all potentially existing particles.
     * @param _state The state to count.
     * @return The count of particles in that state.
     * @notice Gas Warning: This function can be very expensive with many particles.
     */
    function countParticlesByState(State _state) external view returns (uint256) {
        uint256 count = 0;
        // Iterate through all possible particle IDs
        for (uint256 i = 1; i < nextParticleId; i++) {
             // We need to update state based on time to get the *current* state for the count
             // This requires simulating the decay logic here in the view function.
             Particle memory particle = particles[i];
             if (particle.owner != address(0)) { // Check if particle still exists
                uint256 lastTime = particle.lastInteractionTime;
                if (particleStaking[i] > 0) {
                    lastTime = block.timestamp; // Simulate staked state
                }
                uint256 timeElapsed = block.timestamp - lastTime;
                uint256 decayAmount = 0;
                 if (timeElapsed > 0 && particleStaking[i] == 0) {
                    decayAmount = (timeElapsed / 60) * decayRatePerMinute * (globalInstabilityFactor + 100) / 100;
                    if (decayAmount > particle.energy) {
                        particle.energy = 0;
                    } else {
                        particle.energy -= decayAmount;
                    }
                }
                State currentState = _calculateCurrentState(i); // Calculate state based on simulated energy

                if (currentState == _state) {
                    count++;
                }
            }
        }
        return count;
    }


    /**
     * @dev Lists the IDs of particles currently in a specific state.
     * Note: This requires iterating through all potentially existing particles.
     * @param _state The state to list.
     * @return An array of particle IDs.
     * @notice Gas Warning: This function can be very expensive with many particles.
     */
    function getParticlesByStateList(State _state) external view returns (uint256[] memory) {
        uint256[] memory particleIds = new uint256[](countParticlesByState(_state)); // Create array of exact size (requires recounting)
        uint256 currentIndex = 0;
         for (uint256 i = 1; i < nextParticleId; i++) {
             Particle memory particle = particles[i];
             if (particle.owner != address(0)) { // Check if particle still exists
                 // Simulate decay for current state check
                 uint256 lastTime = particle.lastInteractionTime;
                if (particleStaking[i] > 0) {
                    lastTime = block.timestamp; // Simulate staked state
                }
                uint256 timeElapsed = block.timestamp - lastTime;
                uint256 decayAmount = 0;
                 if (timeElapsed > 0 && particleStaking[i] == 0) {
                    decayAmount = (timeElapsed / 60) * decayRatePerMinute * (globalInstabilityFactor + 100) / 100;
                    if (decayAmount > particle.energy) {
                        particle.energy = 0;
                    } else {
                        particle.energy -= decayAmount;
                    }
                }
                State currentState = _calculateCurrentState(i); // Calculate state based on simulated energy

                if (currentState == _state) {
                    particleIds[currentIndex] = i;
                    currentIndex++;
                }
            }
        }
        return particleIds;
    }


    /**
     * @dev Returns the current global instability factor.
     * @return The current global instability factor.
     */
    function getGlobalInstability() external view returns (uint256) {
        return globalInstabilityFactor;
    }


     // --- Withdrawal Function ---

    /**
     * @dev Allows the owner to withdraw accumulated Ether.
     * @param _to The address to send the Ether to.
     * @param _amount The amount of Ether to withdraw in wei.
     */
    function withdrawFunds(address payable _to, uint256 _amount) external onlyOwner {
        require(_amount > 0, "Withdrawal amount must be positive");
        require(address(this).balance >= _amount, "Insufficient contract balance");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Ether withdrawal failed");
    }
}
```