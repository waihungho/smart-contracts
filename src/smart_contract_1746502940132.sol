Okay, let's design a smart contract that incorporates several advanced and creative concepts, simulating aspects of quantum mechanics (entanglement, collapse) and complex state dependencies, while also including inter-contract communication and dynamic outcomes.

We'll call it the **QuantumEntanglementFund**. Users will deposit funds, which become "particles". These particles can enter an "entangled" state influenced by time and simulated entropy. While entangled, they are linked to other particles (potentially even in *other* instances of the same contract). A "collapse" event, triggered manually or automatically, resolves the particle's state, determining a final outcome (yield or penalty) based on simulated probabilistic factors and potentially the state of its "entangled" partner.

This contract is *not* a realistic simulation of quantum mechanics, but uses the concepts metaphorically to create a unique, state-dependent, and somewhat unpredictable investment model.

---

**Contract Name:** `QuantumEntanglementFund`

**Concept:** A fund simulating quantum entanglement and collapse for deposited funds ("particles"). Deposits move through distinct states (`Unentangled`, `Entangling`, `Entangled`, `Collapsed`). Entanglement is a time and entropy-dependent process. Entangled particles can be linked to others, creating dependencies. A "collapse" event resolves the particle's outcome probabilistically, influenced by simulated quantum factors and potentially the state of linked particles.

**Unique Features:**
1.  **State Machine per Deposit:** Each deposit (Particle) has its own lifecycle and state.
2.  **Simulated Entanglement:** State transition to `Entangled` is time-locked and influenced by simulated entropy.
3.  **Simulated Collapse:** State transition to `Collapsed` resolves the particle's value probabilistically, influenced by entropy and linked particles.
4.  **Inter-Contract Linking:** Particles in one instance of the contract can be explicitly linked to particles in *another* deployed instance, with operations on one potentially affecting the other (simulated "spooky action at a distance").
5.  **Dynamic Outcomes:** Final withdrawal amounts are not fixed but determined by the collapse process.
6.  **External Entropy Influence:** Allows provision of external seeds to influence the entropy calculation, decentralizing part of the randomness source (though relying on block hash for core entropy).
7.  **Watcher Role:** Functions (`autoCollapse`, `checkAndFinalizeEntanglement`) designed to be callable by anyone to push state transitions forward, incentivizing participation.

**Limitations:**
*   The "quantum" aspects are entirely simulated using standard blockchain entropy sources (like block hash) and predefined parameters. It does not involve actual quantum computing.
*   Entropy on a blockchain is pseudorandom and potentially exploitable (e.g., miner manipulation). The `provideEntropySeed` function attempts to mitigate this slightly by allowing external input, but it's still not true randomness.

**Outline:**

1.  **State Variables:**
    *   Owner and Pausability state.
    *   Enum for Particle States.
    *   Struct for Particle data (owner, amount, deposit time, state, timers, linked particle ID, etc.).
    *   Mappings: particle ID -> Particle, user address -> list of particle IDs, particle ID -> linked particle ID.
    *   Counters for particle IDs.
    *   Parameters: entanglement duration, collapse outcome range (min/max yield/penalty), entropy seed.
    *   Address of a linked `QuantumEntanglementFund` contract instance.

2.  **Events:**
    *   ParticleDeposit, EntanglementInitiated, EntanglementFinalized, CollapseTriggered, ParticleWithdrawn, ParametersUpdated, LinkEstablished, EntropySeedProvided, Paused, Unpaused.

3.  **Modifiers:**
    *   `onlyOwner`, `whenNotPaused`, `onlyParticleOwner`, `onlyState`.

4.  **Internal Helper Functions:**
    *   `_generateEntropy`: Combines block hash, timestamp, particle ID, and potentially a provided seed to generate pseudorandomness.
    *   `_calculateCollapseOutcome`: Uses entropy to determine the final amount for a collapsed particle within the defined range.
    *   `_updateParticleState`: Internal function to handle state transitions and emit events.
    *   `_getParticle`: Internal getter with safety checks.

5.  **Public/External Functions (at least 20):**
    *   **Core Fund Operations:**
        *   `deposit()`: Receive Ether, create `Unentangled` particle.
        *   `withdraw()`: Withdraw funds from a `Collapsed` particle based on its determined outcome.
        *   `getParticleDetails()`: Retrieve all data for a specific particle ID.
        *   `getUserParticleIds()`: Get all particle IDs owned by a user.
        *   `getParticleState()`: Get the state of a specific particle.
        *   `getTotalParticles()`: Get the total number of particles created.
        *   `getContractBalance()`: Get the total Ether held in the contract.
    *   **Entanglement Lifecycle:**
        *   `initiateEntanglement(uint256 _particleId)`: Start the timer for an `Unentangled` particle.
        *   `checkAndFinalizeEntanglement(uint256 _particleId)`: Callable by anyone, checks if entanglement timer is up and uses entropy to potentially move particle to `Entangled`.
        *   `triggerCollapse(uint256 _particleId)`: Trigger collapse for an `Entangled` particle.
        *   `autoCollapse(uint256 _particleId)`: Callable by anyone, triggers collapse if particle meets automatic collapse criteria (e.g., entangled for too long).
        *   `isEligibleForEntanglement(uint256 _particleId)`: Check if a particle can have entanglement initiated.
        *   `isEligibleForFinalization(uint256 _particleId)`: Check if entanglement can be finalized.
        *   `isEligibleForCollapse(uint256 _particleId)`: Check if a particle can be collapsed.
        *   `simulateQuantumFluctuation()`: Callable by anyone, uses entropy to potentially trigger a random state change (collapse or entanglement finalization) for a *small* number of random active particles. (Adds a bit of unpredictability).
    *   **Inter-Contract Linking:**
        *   `setEntanglementLink(address _linkedContract)`: Owner sets the address of another `QuantumEntanglementFund`.
        *   `getEntanglementLink()`: Get the linked contract address.
        *   `establishParticleLink(uint256 _particleId, address _linkedContract, uint256 _linkedParticleId)`: Owner/privileged role links a particle here to one on the linked contract. Requires verification on the linked contract.
        *   `getLinkedParticleId(uint256 _particleId)`: Get the ID of the particle linked to this one.
        *   `checkLinkedStateConsistency(uint256 _particleId)`: Check if the state of the linked particle on the other contract is consistent with expectations (e.g., still Entangled if this one is). Returns state/info from linked contract.
        *   `triggerLinkedCollapse(uint256 _particleId)`: Trigger collapse on a particle *and* call the linked contract to trigger collapse on its linked particle. This simulates the "spooky action".
    *   **Parameters & Admin:**
        *   `updateEntanglementParameters(uint256 _entanglementDuration)`: Owner updates parameters.
        *   `updateCollapseParameters(int256 _minYieldBasisPoints, int256 _maxYieldBasisPoints)`: Owner updates outcome range (e.g., -1000 to +2000 for -10% to +20%).
        *   `provideEntropySeed(bytes32 _seed)`: Anyone can provide a seed *if* allowed by contract state (e.g., before a certain phase, or only once). This seed influences future entropy.
        *   `getEntropySeed()`: Get the currently active entropy seed.
        *   `pause()`: Owner pauses the contract.
        *   `unpause()`: Owner unpauses.
        *   `setOwner(address _newOwner)`: Transfer ownership.
        *   `emergencyWithdraw()`: Owner can withdraw all funds in case of emergency (bypasses particle states).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline:
// 1. State Variables (Owner, Pausability, Enums, Structs, Mappings, Counters, Parameters, Linked Contract Address)
// 2. Events
// 3. Modifiers
// 4. Internal Helper Functions (_generateEntropy, _calculateCollapseOutcome, _updateParticleState, _getParticle)
// 5. Public/External Functions (Core, Entanglement, Linking, Parameters/Admin, Entropy)

// Function Summary:
// Core Fund Operations:
// 1.  deposit(): Allows users to deposit Ether and create a new 'Unentangled' particle.
// 2.  withdraw(uint256 _particleId): Allows a user to withdraw funds for a 'Collapsed' particle based on its outcome.
// 3.  getParticleDetails(uint256 _particleId): Retrieves all stored data for a specific particle ID.
// 4.  getUserParticleIds(address _user): Returns a list of particle IDs owned by a specific user.
// 5.  getParticleState(uint256 _particleId): Returns the current state (enum) of a particle.
// 6.  getTotalParticles(): Returns the total count of particles created.
// 7.  getContractBalance(): Returns the total Ether currently held in the contract.

// Entanglement Lifecycle:
// 8.  initiateEntanglement(uint256 _particleId): Starts the entanglement timer for an 'Unentangled' particle. Callable by particle owner.
// 9.  checkAndFinalizeEntanglement(uint256 _particleId): Callable by anyone. Checks if entanglement duration is met and uses entropy to transition particle to 'Entangled'.
// 10. triggerCollapse(uint256 _particleId): Callable by particle owner. Forces an 'Entangled' particle into the 'Collapsed' state.
// 11. autoCollapse(uint256 _particleId): Callable by anyone. Automatically collapses an 'Entangled' particle if it exceeds a certain entanglement duration (e.g., double the required time).
// 12. isEligibleForEntanglement(uint256 _particleId): Checks if a particle is in the correct state and meets conditions to initiate entanglement.
// 13. isEligibleForFinalization(uint256 _particleId): Checks if a particle is 'Entangling' and its timer is up.
// 14. isEligibleForCollapse(uint256 _particleId): Checks if a particle is in a state that allows collapse (Entangled or Auto-Collapse eligible).
// 15. simulateQuantumFluctuation(): Callable by anyone. Uses entropy to potentially trigger state changes (Entanglement finalization or Collapse) for a limited random sample of active particles. (Introduces external unpredictability).

// Inter-Contract Linking:
// 16. setEntanglementLink(address _linkedContract): Owner sets the address of another QuantumEntanglementFund contract instance to enable inter-contract linking.
// 17. getEntanglementLink(): Returns the address of the linked QuantumEntanglementFund contract.
// 18. establishParticleLink(uint256 _particleId, address _linkedContractAddress, uint256 _linkedParticleId): Owner links a particle in THIS contract to a specific particle in another QuantumEntanglementFund contract. Requires linked particle to be active (Entangling/Entangled).
// 19. getLinkedParticleId(uint256 _particleId): Returns the ID of the particle linked to _particleId in the linked contract.
// 20. checkLinkedStateConsistency(uint256 _particleId): Queries the linked contract to check the state of the linked particle. Returns its state.
// 21. triggerLinkedCollapse(uint256 _particleId): Triggers collapse for _particleId and simultaneously calls the linked contract to trigger collapse for its linked particle (if linked).

// Parameters & Admin:
// 22. updateEntanglementParameters(uint256 _entanglementDuration): Owner updates the required time for a particle to become entangled after initiation.
// 23. updateCollapseParameters(int256 _minYieldBasisPoints, int256 _maxYieldBasisPoints): Owner updates the minimum and maximum possible yield/penalty during collapse (in basis points).
// 24. provideEntropySeed(bytes32 _seed): Anyone can provide an additional seed to be mixed into entropy calculation. Can only be provided once per 'entropy cycle' (simulated here by allowing one seed per contract lifetime for simplicity, could be time-based).
// 25. getEntropySeed(): Returns the currently active external entropy seed.
// 26. pause(): Owner pauses contract operations.
// 27. unpause(): Owner unpauses contract operations.
// 28. setOwner(address _newOwner): Transfers ownership of the contract.
// 29. emergencyWithdraw(): Owner can withdraw all funds from the contract in an emergency.

// Helper/Query Functions:
// 30. getRequiredEntanglementTime(): Returns the configured entanglement duration.
// 31. getCollapseYieldRange(): Returns the configured min/max yield/penalty range in basis points.


contract QuantumEntanglementFund is Ownable, Pausable {
    using SafeMath for uint256;

    // --- 1. State Variables ---

    enum ParticleState {
        Unentangled, // Initial state after deposit
        Entangling,  // Entanglement initiated, timer running
        Entangled,   // Entanglement finalized, linked state active
        Collapsed    // Final state, outcome determined, ready for withdrawal
    }

    struct Particle {
        address owner;
        uint256 amount; // Amount deposited (in wei)
        uint256 depositTime;
        ParticleState state;
        uint256 entanglementInitiationTime; // Timestamp when Entangling started
        uint256 entanglementFinalizationTime; // Timestamp when Entangled state was achieved (optional tracking)
        uint256 collapseTime; // Timestamp when Collapsed state was achieved
        int256 finalOutcomeBasisPoints; // Yield/penalty in basis points after collapse (-10000 to +N)
        uint256 linkedParticleId; // ID of particle in linked contract (if linked)
        address linkedContractAddress; // Address of the linked contract (redundant but helpful)
    }

    uint256 private _particleCounter;
    mapping(uint256 => Particle) private _particles;
    mapping(address => uint256[]) private _userParticles; // Tracks particles owned by each user
    mapping(uint256 => uint256) private _linkedParticleMapping; // particleId => linkedParticleId (simple mapping for quick lookup)

    // Parameters
    uint256 public entanglementDuration = 7 days; // Time required in Entangling state
    int256 public minYieldBasisPoints = -1000; // Minimum outcome: -10%
    int256 public maxYieldBasisPoints = 2000;  // Maximum outcome: +20% (in basis points, 100bp = 1%)

    // Entropy
    bytes32 private _entropySeed; // External seed provided by user
    bool private _entropySeedProvided = false; // Track if seed has been provided

    // Inter-contract link
    QuantumEntanglementFund public linkedEntanglementContract;

    // --- 2. Events ---

    event ParticleDeposit(address indexed user, uint256 particleId, uint256 amount);
    event EntanglementInitiated(uint256 particleId, uint256 initiationTime);
    event EntanglementFinalized(uint256 particleId, uint256 finalizationTime);
    event CollapseTriggered(uint256 particleId, uint256 collapseTime, int256 finalOutcomeBasisPoints);
    event ParticleWithdrawn(uint256 particleId, address indexed user, uint256 originalAmount, uint256 finalAmount);
    event ParametersUpdated(uint256 newEntanglementDuration, int256 newMinYieldBP, int256 newMaxYieldBP);
    event LinkEstablished(uint256 particleId, address indexed linkedContract, uint256 linkedParticleId);
    event EntropySeedProvided(bytes32 indexed seed, address indexed provider);

    // Inherited events: Paused, Unpaused, OwnershipTransferred

    // --- 3. Modifiers ---

    modifier onlyParticleOwner(uint256 _particleId) {
        require(_particles[_particleId].owner == msg.sender, "Not your particle");
        _;
    }

    modifier onlyState(uint256 _particleId, ParticleState _requiredState) {
        require(_particles[_particleId].state == _requiredState, "Particle not in required state");
        _;
    }

    // --- Constructor ---

    constructor(uint256 _initialEntanglementDuration, int256 _initialMinYieldBP, int256 _initialMaxYieldBP) Ownable(msg.sender) {
        entanglementDuration = _initialEntanglementDuration;
        minYieldBasisPoints = _initialMinYieldBP;
        maxYieldBasisPoints = _initialMaxYieldBP;
        _particleCounter = 0;
    }

    receive() external payable {
        // Allow receiving direct Ether deposits if deposit() isn't called,
        // though these won't create particles. EmergencyWithdraw can access.
    }

    // --- 4. Internal Helper Functions ---

    /**
     * @dev Generates pseudorandom entropy. Combines block data, timestamp, particle ID,
     * and an optional user-provided seed.
     * @param _particleId The ID of the particle this entropy is for.
     * @return bytes32 Pseudorandom hash.
     */
    function _generateEntropy(uint256 _particleId) internal view returns (bytes32) {
        // Combine various factors for a more "random" seed
        bytes32 combinedSeed = keccak256(
            abi.encodePacked(
                blockhash(block.number - 1), // Use a recent block hash (not current to avoid miner manipulation in simple cases)
                block.timestamp,
                _particleId,
                msg.sender, // Include the caller, though this might make it deterministic for a single caller
                tx.origin,
                tx.gasprice,
                _entropySeed // Include the user-provided seed if available
            )
        );
        return combinedSeed;
    }

    /**
     * @dev Calculates the final outcome amount based on the original amount and collapse parameters,
     * using entropy for probabilistic determination.
     * @param _originalAmount The initial deposited amount.
     * @param _entropy The entropy seed for this calculation.
     * @return uint256 The final amount after applying yield or penalty.
     * @return int256 The yield/penalty in basis points.
     */
    function _calculateCollapseOutcome(uint256 _originalAmount, bytes32 _entropy) internal view returns (uint256, int256) {
        // Use entropy to get a value between 0 and 10000 (inclusive)
        uint256 randomFactor = uint256(_entropy) % 10001; // 0 to 10000

        // Map the random factor to the basis point range (minYieldBasisPoints to maxYieldBasisPoints)
        // Range span = max - min
        // Position in span = randomFactor / 10000 * span
        // Outcome BP = min + Position in span
        int256 rangeSpan = maxYieldBasisPoints - minYieldBasisPoints;
        int256 outcomeBasisPoints = minYieldBasisPoints + (int256((randomFactor * uint256(rangeSpan)) / 10000));

        // Calculate final amount: original + (original * outcomeBP / 10000)
        // Need to be careful with negative outcomes (penalties)
        uint256 finalAmount;
        if (outcomeBasisPoints >= 0) {
            uint256 yield = _originalAmount.mul(uint256(outcomeBasisPoints)).div(10000);
            finalAmount = _originalAmount.add(yield);
        } else {
            // Penalty is absolute value
            uint256 penalty = _originalAmount.mul(uint256(outcomeBasisPoints * -1)).div(10000);
            // Ensure final amount is not less than 0 (though with Ether, it shouldn't be possible unless original is 0)
            finalAmount = _originalAmount > penalty ? _originalAmount.sub(penalty) : 0;
        }

        // Cap the final amount at the contract's current balance to prevent draining
        // In a real system, managing funds for yields requires external sources or pooled mechanics.
        // Here, yield comes from the pool. If the pool can't cover it, the yield is capped.
        uint256 contractBalance = address(this).balance;
        if (finalAmount > contractBalance) {
            finalAmount = contractBalance;
             // Re-calculate outcomeBasisPoints based on capped amount for accuracy in event
             if (_originalAmount > 0) {
                  outcomeBasisPoints = int256(finalAmount.sub(_originalAmount).mul(10000).div(_originalAmount));
             } else {
                 outcomeBasisPoints = 0; // Cannot calculate basis points if original amount is 0
             }
        }


        return (finalAmount, outcomeBasisPoints);
    }

    /**
     * @dev Internal helper to update a particle's state and emit the corresponding event.
     * @param _particleId The ID of the particle to update.
     * @param _newState The new state for the particle.
     */
    function _updateParticleState(uint256 _particleId, ParticleState _newState) internal {
        Particle storage particle = _particles[_particleId];
        require(particle.owner != address(0), "Particle does not exist"); // Basic check

        ParticleState oldState = particle.state;
        particle.state = _newState;

        if (_newState == ParticleState.Entangling && oldState == ParticleState.Unentangled) {
            particle.entanglementInitiationTime = block.timestamp;
            emit EntanglementInitiated(_particleId, block.timestamp);
        } else if (_newState == ParticleState.Entangled && oldState == ParticleState.Entangling) {
             particle.entanglementFinalizationTime = block.timestamp;
             emit EntanglementFinalized(_particleId, block.timestamp);
        } else if (_newState == ParticleState.Collapsed && oldState != ParticleState.Collapsed) {
            particle.collapseTime = block.timestamp;
            // Outcome calculated during collapse trigger, not just state update
            // emit CollapseTriggered event is done in triggerCollapse functions
        }
        // Note: Transition validation (e.g., can't go from Collapsed back to Unentangled)
        // is handled in the public functions calling this helper.
    }

    /**
     * @dev Internal helper to get a particle struct with existence check.
     * @param _particleId The ID of the particle.
     * @return Particle storage reference.
     */
    function _getParticle(uint256 _particleId) internal view returns (Particle storage) {
        Particle storage particle = _particles[_particleId];
        require(particle.owner != address(0), "Particle does not exist");
        return particle;
    }


    // --- 5. Public/External Functions ---

    // --- Core Fund Operations ---

    /**
     * @dev Allows users to deposit Ether and create a new 'Unentangled' particle.
     */
    function deposit() external payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be greater than 0");

        _particleCounter = _particleCounter.add(1);
        uint256 newParticleId = _particleCounter;

        _particles[newParticleId] = Particle({
            owner: msg.sender,
            amount: msg.value,
            depositTime: block.timestamp,
            state: ParticleState.Unentangled,
            entanglementInitiationTime: 0,
            entanglementFinalizationTime: 0,
            collapseTime: 0,
            finalOutcomeBasisPoints: 0, // Set on collapse
            linkedParticleId: 0, // Set if linked
            linkedContractAddress: address(0) // Set if linked
        });

        _userParticles[msg.sender].push(newParticleId);

        emit ParticleDeposit(msg.sender, newParticleId, msg.value);
    }

    /**
     * @dev Allows a user to withdraw funds for a 'Collapsed' particle based on its determined outcome.
     * @param _particleId The ID of the particle to withdraw.
     */
    function withdraw(uint256 _particleId) external onlyParticleOwner(_particleId) onlyState(_particleId, ParticleState.Collapsed) whenNotPaused {
        Particle storage particle = _getParticle(_particleId);

        uint256 finalAmount;
        // Final amount is stored in the struct after collapse
        if (particle.finalOutcomeBasisPoints >= 0) {
             // Calculate exact amount from original + BP to avoid potential floating point issues
             uint256 yield = particle.amount.mul(uint256(particle.finalOutcomeBasisPoints)).div(10000);
             finalAmount = particle.amount.add(yield);
        } else {
             uint256 penalty = particle.amount.mul(uint256(particle.finalOutcomeBasisPoints * -1)).div(10000);
             finalAmount = particle.amount > penalty ? particle.amount.sub(penalty) : 0;
        }

        // Double-check against contract balance (should be handled in collapse, but safety)
        if (finalAmount > address(this).balance) {
             finalAmount = address(this).balance;
        }

        // Clear particle data (optional, but prevents re-withdrawal)
        // Note: Clearing complex structs like this can be tricky with storage pointers
        // Simple solution: mark as withdrawn or move to a terminal state.
        // Here, we rely on the state being Collapsed and transfer happening once.
        // A mapping `isWithdrawn[particleId]` could be safer.
        // For this example, we'll transfer and rely on state.
        // If a particle is withdrawn, it stays in Collapsed state but balance is zeroed.
        // To prevent double-spend on the balance, let's set amount to 0 after calculating finalAmount.
        uint256 originalAmount = particle.amount;
        particle.amount = 0; // Mark as withdrawn implicitly

        (bool success, ) = payable(particle.owner).call{value: finalAmount}("");
        require(success, "Withdrawal failed");

        emit ParticleWithdrawn(_particleId, particle.owner, originalAmount, finalAmount);
    }

    /**
     * @dev Retrieves all stored data for a specific particle ID.
     * @param _particleId The ID of the particle.
     * @return struct Particle
     */
    function getParticleDetails(uint256 _particleId) external view returns (Particle memory) {
         // Need to copy storage to memory for return
        Particle storage particle = _getParticle(_particleId);
        return particle;
    }

    /**
     * @dev Returns a list of particle IDs owned by a specific user.
     * @param _user The address of the user.
     * @return uint256[] Array of particle IDs.
     */
    function getUserParticleIds(address _user) external view returns (uint256[] memory) {
        return _userParticles[_user];
    }

    /**
     * @dev Returns the current state (enum) of a particle.
     * @param _particleId The ID of the particle.
     * @return ParticleState The state of the particle.
     */
    function getParticleState(uint256 _particleId) external view returns (ParticleState) {
         require(_particles[_particleId].owner != address(0), "Particle does not exist");
        return _particles[_particleId].state;
    }

     /**
     * @dev Returns the total count of particles created.
     * @return uint256 Total particle count.
     */
    function getTotalParticles() external view returns (uint256) {
        return _particleCounter;
    }

    /**
     * @dev Returns the total Ether currently held in the contract.
     * @return uint256 Contract balance in wei.
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // --- Entanglement Lifecycle ---

    /**
     * @dev Starts the entanglement timer for an 'Unentangled' particle. Callable by particle owner.
     * Moves particle state from Unentangled to Entangling.
     * @param _particleId The ID of the particle.
     */
    function initiateEntanglement(uint256 _particleId) external onlyParticleOwner(_particleId) onlyState(_particleId, ParticleState.Unentangled) whenNotPaused {
        _updateParticleState(_particleId, ParticleState.Entangling);
        // entanglementInitiationTime is set in _updateParticleState
    }

    /**
     * @dev Checks if entanglement duration is met for an 'Entangling' particle
     * and uses entropy to transition particle to 'Entangled'. Callable by anyone.
     * Incentivizes pushing states forward.
     * @param _particleId The ID of the particle.
     */
    function checkAndFinalizeEntanglement(uint256 _particleId) external whenNotPaused {
        Particle storage particle = _getParticle(_particleId);
        require(particle.state == ParticleState.Entangling, "Particle not in Entangling state");
        require(particle.entanglementInitiationTime > 0, "Entanglement not initiated");
        require(block.timestamp >= particle.entanglementInitiationTime + entanglementDuration, "Entanglement duration not met");

        // Simple check: Use entropy. If it's even, finalize. If odd, wait for autoCollapse or manual trigger.
        // More complex logic could involve probability based on time, etc.
        bytes32 entropy = _generateEntropy(_particleId);
        uint256 randomFactor = uint256(entropy) % 100; // 0-99

        // Let's make it probabilistic - e.g., 80% chance to finalize if time is met
        if (randomFactor < 80) { // 80% chance of success
             _updateParticleState(_particleId, ParticleState.Entangled);
        }
        // If randomFactor >= 80, it stays Entangling until autoCollapse or triggerCollapse
        // (This adds a small probabilistic delay/uncertainty even after timer)
    }


    /**
     * @dev Forces an 'Entangled' particle into the 'Collapsed' state. Callable by particle owner.
     * Calculates and stores the final outcome amount.
     * @param _particleId The ID of the particle.
     */
    function triggerCollapse(uint256 _particleId) external onlyParticleOwner(_particleId) onlyState(_particleId, ParticleState.Entangled) whenNotPaused {
        Particle storage particle = _getParticle(_particleId);

        // Calculate outcome based on entropy
        bytes32 entropy = _generateEntropy(_particleId);
        (uint256 finalAmount, int256 outcomeBasisPoints) = _calculateCollapseOutcome(particle.amount, entropy);

        particle.finalOutcomeBasisPoints = outcomeBasisPoints;
        // Note: particle.amount remains the original amount until withdrawal.
        // finalAmount is just the calculated value for the event/struct field.

        _updateParticleState(_particleId, ParticleState.Collapsed); // State update happens last

        emit CollapseTriggered(_particleId, block.timestamp, outcomeBasisPoints);

        // Check for linked particle and trigger collapse if necessary (manual trigger doesn't auto-trigger linked unless using triggerLinkedCollapse)
        // The triggerLinkedCollapse function handles the paired collapse.
    }

     /**
     * @dev Callable by anyone. Automatically collapses an 'Entangled' particle if it exceeds
     * a certain entanglement duration (e.g., double the required time). Incentivizes pushing states forward.
     * Calculates and stores the final outcome amount.
     * @param _particleId The ID of the particle.
     */
    function autoCollapse(uint256 _particleId) external whenNotPaused {
        Particle storage particle = _getParticle(_particleId);
        require(particle.state == ParticleState.Entangled || particle.state == ParticleState.Entangling, "Particle not in Entangled or Entangling state"); // Can auto-collapse long-standing Entangling too

        uint256 requiredTime;
        if (particle.state == ParticleState.Entangled) {
             requiredTime = particle.entanglementFinalizationTime; // Use time it became Entangled
        } else { // Entangling
             requiredTime = particle.entanglementInitiationTime; // Use time it became Entangling
        }

        require(requiredTime > 0, "Timestamps not set for state"); // Should not happen if in these states
        require(block.timestamp >= requiredTime + entanglementDuration.mul(2), "Auto-collapse duration not met"); // Auto-collapse after double duration

        // Calculate outcome based on entropy
        bytes32 entropy = _generateEntropy(_particleId);
        (uint256 finalAmount, int256 outcomeBasisPoints) = _calculateCollapseOutcome(particle.amount, entropy);

        particle.finalOutcomeBasisPoints = outcomeBasisPoints;

        _updateParticleState(_particleId, ParticleState.Collapsed); // State update happens last

        emit CollapseTriggered(_particleId, block.timestamp, outcomeBasisPoints);

        // Auto-collapse does NOT automatically trigger linked collapse.
        // triggerLinkedCollapse must be used for paired collapse.
    }

    /**
     * @dev Checks if a particle is in the correct state and meets conditions to initiate entanglement.
     * @param _particleId The ID of the particle.
     * @return bool True if eligible, false otherwise.
     */
    function isEligibleForEntanglement(uint256 _particleId) external view returns (bool) {
        Particle memory particle = _getParticle(_particleId);
        return particle.state == ParticleState.Unentangled;
    }

    /**
     * @dev Checks if a particle is 'Entangling' and its timer is up.
     * @param _particleId The ID of the particle.
     * @return bool True if eligible, false otherwise.
     */
    function isEligibleForFinalization(uint256 _particleId) external view returns (bool) {
        Particle memory particle = _getParticle(_particleId);
        return particle.state == ParticleState.Entangling &&
               particle.entanglementInitiationTime > 0 && // Should be set if Entangling
               block.timestamp >= particle.entanglementInitiationTime + entanglementDuration;
    }

    /**
     * @dev Checks if a particle is in a state that allows collapse (Entangled or Auto-Collapse eligible from Entangling/Entangled).
     * @param _particleId The ID of the particle.
     * @return bool True if eligible, false otherwise.
     */
    function isEligibleForCollapse(uint256 _particleId) external view returns (bool) {
        Particle memory particle = _getParticle(_particleId);
        if (particle.state == ParticleState.Collapsed) return false; // Already collapsed

        if (particle.state == ParticleState.Entangled) return true; // Can always manually collapse Entangled

        // Check for auto-collapse eligibility if Entangling or Entangled
         uint256 requiredTime;
        if (particle.state == ParticleState.Entangled) {
             requiredTime = particle.entanglementFinalizationTime;
        } else if (particle.state == ParticleState.Entangling) {
             requiredTime = particle.entanglementInitiationTime;
        } else {
            return false; // Not in a collapse-eligible state
        }

        return requiredTime > 0 && block.timestamp >= requiredTime + entanglementDuration.mul(2); // Auto-collapse check
    }

    /**
     * @dev Callable by anyone. Uses entropy to potentially trigger state changes (Entanglement finalization or Collapse)
     * for a limited random sample of active particles. Introduces external unpredictability.
     * Note: This function is simplified. A real system might iterate or use a different mechanism.
     * This version affects a single particle determined somewhat randomly.
     */
    function simulateQuantumFluctuation() external whenNotPaused {
        if (_particleCounter == 0) return; // No particles to affect

        // Use entropy to pick a particle ID
        bytes32 entropy = keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender, _entropySeed, _particleCounter));
        uint256 randomParticleId = (uint256(entropy) % _particleCounter) + 1; // Get a valid ID

        Particle storage particle = _particles[randomParticleId];

        // Check if the particle exists and is in a relevant state
        if (particle.owner == address(0) || particle.state == ParticleState.Unentangled || particle.state == ParticleState.Collapsed) {
             return; // Skip if not in a state that can be affected by this
        }

        bytes32 particleEntropy = _generateEntropy(randomParticleId);
        uint256 actionFactor = uint256(particleEntropy) % 100; // 0-99

        // Apply a small probability of action
        if (actionFactor < 5) { // 5% chance of a state change
             if (particle.state == ParticleState.Entangling && isEligibleForFinalization(randomParticleId)) {
                  // Attempt to finalize entanglement
                   bytes32 finalizationEntropy = _generateEntropy(randomParticleId);
                   uint256 finalizeFactor = uint256(finalizationEntropy) % 100;
                   if (finalizeFactor < 80) { // 80% chance to finalize
                        _updateParticleState(randomParticleId, ParticleState.Entangled);
                   }
             } else if (particle.state == ParticleState.Entangled || particle.state == ParticleState.Entangling) { // Can auto-collapse if eligible
                   if (isEligibleForCollapse(randomParticleId)) {
                        // Attempt to auto-collapse
                        bytes32 collapseEntropy = _generateEntropy(randomParticleId);
                        (uint256 finalAmount, int256 outcomeBasisPoints) = _calculateCollapseOutcome(particle.amount, collapseEntropy);
                        particle.finalOutcomeBasisPoints = outcomeBasisPoints;
                        _updateParticleState(randomParticleId, ParticleState.Collapsed);
                        emit CollapseTriggered(randomParticleId, block.timestamp, outcomeBasisPoints);
                   }
             }
        }
    }


    // --- Inter-Contract Linking ---

    /**
     * @dev Owner sets the address of another QuantumEntanglementFund contract instance.
     * This enables inter-contract linking.
     * @param _linkedContract The address of the linked contract.
     */
    function setEntanglementLink(address _linkedContract) external onlyOwner whenNotPaused {
        require(_linkedContract != address(0), "Linked contract address cannot be zero");
        // Basic check that it's a contract
        uint256 size;
        assembly { size := extcodesize(_linkedContract) }
        require(size > 0, "Linked address is not a contract");

        linkedEntanglementContract = QuantumEntanglementFund(_linkedContract);
        emit LinkEstablished(0, _linkedContract, 0); // Use particleId 0 to signify contract link
    }

     /**
     * @dev Returns the address of the linked QuantumEntanglementFund contract.
     * @return address Linked contract address.
     */
    function getEntanglementLink() external view returns (address) {
        return address(linkedEntanglementContract);
    }


    /**
     * @dev Owner links a particle in THIS contract to a specific particle in another
     * QuantumEntanglementFund contract (set via setEntanglementLink).
     * Requires both particles to exist and be in an 'active' state (Entangling or Entangled)
     * and not already linked.
     * @param _particleId The ID of the particle in this contract.
     * @param _linkedContractAddress The address of the linked contract (must match linkedEntanglementContract).
     * @param _linkedParticleId The ID of the particle in the linked contract.
     */
    function establishParticleLink(uint256 _particleId, address _linkedContractAddress, uint256 _linkedParticleId) external onlyOwner whenNotPaused {
        require(_linkedContractAddress == address(linkedEntanglementContract), "Provided linked contract address does not match configured link");
        require(address(linkedEntanglementContract) != address(0), "Entanglement link contract not set");
        require(_linkedParticleId > 0, "Linked particle ID must be valid");

        Particle storage particle = _getParticle(_particleId);
        require(particle.state == ParticleState.Entangling || particle.state == ParticleState.Entangled, "Particle in this contract must be Entangling or Entangled");
        require(particle.linkedParticleId == 0, "Particle in this contract is already linked");

        // Verify the linked particle exists and is in an active state on the linked contract
        try linkedEntanglementContract.getParticleDetails(_linkedParticleId) returns (Particle memory linkedDetails) {
             require(linkedDetails.owner != address(0), "Linked particle does not exist");
             require(linkedDetails.state == ParticleState.Entangling || linkedDetails.state == ParticleState.Entangled, "Linked particle must be Entangling or Entangled");
             // Optional: Could check if linked particle is already linked from its side
             // require(linkedDetails.linkedParticleId == 0, "Linked particle is already linked from its side");
             // Note: Implementing a reciprocal link requires a call back to the linked contract,
             // which adds complexity and potential reentrancy risks.
             // For simplicity, we'll store the link only FROM this particle.
        } catch {
            revert("Could not get linked particle details or linked contract call failed");
        }

        // Store the link
        particle.linkedParticleId = _linkedParticleId;
        particle.linkedContractAddress = _linkedContractAddress; // Store address for easy lookup
        _linkedParticleMapping[_particleId] = _linkedParticleId; // Also store in simple mapping


        emit LinkEstablished(_particleId, _linkedContractAddress, _linkedParticleId);
    }

     /**
     * @dev Returns the ID of the particle linked to _particleId in the linked contract.
     * Returns 0 if no link exists.
     * @param _particleId The ID of the particle in this contract.
     * @return uint256 The linked particle ID, or 0.
     */
    function getLinkedParticleId(uint256 _particleId) external view returns (uint256) {
         require(_particles[_particleId].owner != address(0), "Particle does not exist");
        return _particles[_particleId].linkedParticleId; // Or use _linkedParticleMapping[_particleId]
    }

    /**
     * @dev Queries the linked contract to check the state of the linked particle.
     * Useful for checking "entanglement state consistency".
     * @param _particleId The ID of the particle in this contract.
     * @return ParticleState The state of the linked particle, or Collapsed if contract call fails/particle invalid.
     */
    function checkLinkedStateConsistency(uint256 _particleId) external view returns (ParticleState) {
        Particle memory particle = _getParticle(_particleId);
        require(particle.linkedParticleId > 0 && particle.linkedContractAddress != address(0), "Particle is not linked");

        // Perform a static call (view) to the linked contract
        try QuantumEntanglementFund(particle.linkedContractAddress).getParticleState(particle.linkedParticleId) returns (ParticleState linkedState) {
            return linkedState;
        } catch {
            // If call fails (e.g., linked contract gone, particle not found), assume 'collapsed' state conceptually
            return ParticleState.Collapsed;
        }
    }

    /**
     * @dev Triggers collapse for _particleId and simultaneously calls the linked contract
     * to trigger collapse for its linked particle (if linked and in a state that allows collapse).
     * This simulates "spooky action at a distance". Callable by particle owner.
     * @param _particleId The ID of the particle in this contract.
     */
    function triggerLinkedCollapse(uint256 _particleId) external onlyParticleOwner(_particleId) onlyState(_particleId, ParticleState.Entangled) whenNotPaused {
        Particle storage particle = _getParticle(_particleId);

        // First, collapse the particle in THIS contract
        bytes32 entropy = _generateEntropy(_particleId);
        (uint256 finalAmount, int256 outcomeBasisPoints) = _calculateCollapseOutcome(particle.amount, entropy);
        particle.finalOutcomeBasisPoints = outcomeBasisPoints;
        _updateParticleState(_particleId, ParticleState.Collapsed);
        emit CollapseTriggered(_particleId, block.timestamp, outcomeBasisPoints);


        // Second, attempt to trigger collapse on the linked particle
        if (particle.linkedParticleId > 0 && particle.linkedContractAddress != address(0)) {
            // Use a low-level call to handle potential failures gracefully without reverting this contract's state change
            bytes memory payload = abi.encodeWithSignature("triggerCollapse(uint256)", particle.linkedParticleId);
            (bool success, ) = payable(particle.linkedContractAddress).call(payload);

            // Log the outcome of the linked call, but don't revert this transaction if it fails
            // Consider adding an event here for linked collapse attempt/failure
             if (!success) {
                 // Log failure
                 // emit LinkedCollapseFailed(_particleId, particle.linkedContractAddress, particle.linkedParticleId);
             }
        }
    }


    // --- Parameters & Admin ---

    /**
     * @dev Owner updates the required time for a particle to become entangled after initiation.
     * @param _entanglementDuration The new duration in seconds.
     */
    function updateEntanglementParameters(uint256 _entanglementDuration) external onlyOwner whenNotPaused {
        require(_entanglementDuration > 0, "Duration must be positive");
        entanglementDuration = _entanglementDuration;
        emit ParametersUpdated(entanglementDuration, minYieldBasisPoints, maxYieldBasisPoints);
    }

    /**
     * @dev Owner updates the minimum and maximum possible yield/penalty during collapse (in basis points).
     * e.g., -1000 for -10%, 2000 for +20%.
     * @param _minYieldBasisPoints Minimum outcome in basis points.
     * @param _maxYieldBasisPoints Maximum outcome in basis points.
     */
    function updateCollapseParameters(int256 _minYieldBasisPoints, int256 _maxYieldBasisPoints) external onlyOwner whenNotPaused {
         require(_minYieldBasisPoints <= _maxYieldBasisPoints, "Min yield cannot be greater than max yield");
         // Add reasonable bounds if necessary, e.g., require(_maxYieldBasisPoints <= 10000, "Max yield capped");
        minYieldBasisPoints = _minYieldBasisPoints;
        maxYieldBasisPoints = _maxYieldBasisPoints;
        emit ParametersUpdated(entanglementDuration, minYieldBasisPoints, maxYieldBasisPoints);
    }

    /**
     * @dev Anyone can provide an additional seed to be mixed into entropy calculation.
     * This attempts to make the entropy slightly less predictable by miners if called close to a state change.
     * Can only be provided once per 'entropy cycle' (simulated simply by allowing it once ever).
     * @param _seed The bytes32 seed value.
     */
    function provideEntropySeed(bytes32 _seed) external whenNotPaused {
        require(!_entropySeedProvided, "Entropy seed already provided for this cycle");
        _entropySeed = _seed;
        _entropySeedProvided = true; // For this simple example, seed is permanent once set.
                                    // A real system might reset this periodically.
        emit EntropySeedProvided(_seed, msg.sender);
    }

     /**
     * @dev Returns the currently active external entropy seed.
     * @return bytes32 The entropy seed.
     */
    function getEntropySeed() external view returns (bytes32) {
        return _entropySeed;
    }

    /**
     * @dev Owner pauses the contract. Certain state-changing operations become unavailable.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Owner unpauses the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Transfers ownership of the contract.
     */
    // Overrides the Ownable transferOwnership to include Pausable check if desired,
    // but standard Ownable transferOwnership doesn't check pausable state, which is fine.
    // function setOwner(address newOwner) external onlyOwner { // ERC173 standard function name is transferOwnership
    //     transferOwnership(newOwner);
    // }

    /**
     * @dev Owner can withdraw all funds from the contract in case of emergency.
     * Bypasses particle states. Use with extreme caution.
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Emergency withdrawal failed");
    }

    // --- Helper/Query Functions ---

    /**
     * @dev Returns the configured entanglement duration.
     * @return uint256 Duration in seconds.
     */
    function getRequiredEntanglementTime() external view returns (uint256) {
        return entanglementDuration;
    }

    /**
     * @dev Returns the configured min/max yield/penalty range in basis points.
     * @return int256 Minimum basis points.
     * @return int256 Maximum basis points.
     */
    function getCollapseYieldRange() external view returns (int256, int256) {
        return (minYieldBasisPoints, maxYieldBasisPoints);
    }

    // Add more query functions if needed, e.g., getActiveEntangledParticles(), getCollapsibleParticles() etc.
    // These would likely involve iterating through particles or maintaining separate lists, which can be gas-intensive.
    // For 20+ functions, the above should suffice, covering core logic, state transitions, linking, and admin.

}
```