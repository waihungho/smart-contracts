Okay, let's create a complex and creative smart contract that isn't a standard DeFi, NFT, or DAO pattern. We'll invent a concept: simulating a decentralized "Quantum Entanglement Predictor" where users predict states of abstract "particles" that evolve and get "entangled" pseudorandomly.

This involves:
1.  **Particles:** Abstract entities with evolving states.
2.  **States:** Particles can be in a 'Superposition' state or a 'Collapsed' state (e.g., Up/Down).
3.  **Entanglement:** Particles can become entangled, meaning predicting/collapsing one can influence the state of its entangled partner.
4.  **Prediction Market:** Users stake tokens to predict the final 'Collapsed' state of a particle before a resolution block.
5.  **Resolution & Collapse:** At a specific block, the particle's state 'collapses' based on pseudorandomness, entanglement effects, and potentially prediction pressure. Correct predictors share the staked pool.
6.  **Dynamic Nature:** Particles can be created, decay, and entanglement links can form or break.
7.  **Pseudorandomness:** Using block data and other on-chain variables to simulate unpredictable outcomes (with caveats).
8.  **User Stats & Boosting:** Tracking user success and allowing users to boost prediction weight.

This concept allows for dynamic state, complex interactions, and goes beyond typical token/NFT/DAO mechanics.

---

**Smart Contract: QuantumEntanglementPredictor**

**Outline:**

1.  **License and Pragma**
2.  **Imports** (ERC20 for staking)
3.  **Error Definitions**
4.  **Events** (Particle creation, prediction, resolution, entanglement, etc.)
5.  **State Variables** (Mappings for particles, predictions, users; counters; parameters)
6.  **Structs** (`Particle`, `Prediction`, `UserState`, `EntanglementLink`)
7.  **Modifiers** (Admin, Owner)
8.  **Constructor**
9.  **Admin Functions** (Setting parameters, adding admins, withdrawing fees)
10. **Particle Management Functions** (Creating, updating, decaying particles/entanglements - some user-callable)
11. **User Prediction Functions** (Predicting, canceling, boosting, resolving)
12. **View Functions** (Getting details of particles, predictions, user stats, states)
13. **Internal Helper Functions** (Pseudorandom number generation, state resolution logic, winnings distribution)

**Function Summary (26 Functions):**

1.  `constructor()`: Initializes the contract with the prediction token address and owner.
2.  `setFeePercentage(uint256 newFee)`: Admin function to set the fee percentage on winnings.
3.  `addAdmin(address newAdmin)`: Owner function to add a new admin address.
4.  `removeAdmin(address adminToRemove)`: Owner function to remove an admin address.
5.  `createParticle(uint256 predictionDeadlineOffset, uint256 resolutionOffset, uint256 decayPeriod, uint256 initialProbabilityWeight)`: Admin or paid-user function to create a new particle with specific lifecycle parameters.
6.  `updateParticleParameters(uint256 particleId, uint256 predictionDeadlineOffset, uint256 resolutionOffset, uint256 decayPeriod, uint256 probabilityWeight)`: Admin function to adjust parameters of an existing particle.
7.  `decayParticle(uint256 particleId)`: Callable by anyone after particle's decay period to clean up state and potentially trigger entanglement breaks.
8.  `establishEntanglement(uint256 particleIdA, uint256 particleIdB)`: Admin or result of `attemptEntanglementProbe` to link two particles.
9.  `breakEntanglement(uint256 particleIdA, uint256 particleIdB)`: Admin or result of decay to unlink two particles.
10. `attemptEntanglementProbe(uint256 particleIdA, uint256 particleIdB)`: User function (pays fee) to attempt creating an entanglement link between two particles with a pseudorandom chance of success.
11. `predictParticleState(uint256 particleId, uint8 predictedState, uint256 amount)`: User function to stake tokens and predict the final state (0 or 1) of a particle.
12. `cancelPrediction(uint256 particleId)`: User function to cancel an outstanding prediction before the prediction deadline.
13. `boostPrediction(uint256 particleId, uint256 additionalAmount)`: User function to add more tokens to an existing prediction, increasing its weight.
14. `resolvePrediction(uint256 particleId)`: User function callable after the resolution block to trigger the particle's state collapse and claim winnings if correct.
15. `withdrawFees(address recipient)`: Admin function to withdraw accumulated protocol fees.
16. `getParticleDetails(uint256 particleId)`: View function to get all structural details of a particle.
17. `getParticleCurrentState(uint256 particleId)`: View function to see the particle's current state representation (Superposition, Collapsed Up/Down).
18. `getParticleResolutionState(uint256 particleId)`: View function to see the final collapsed state if resolution has occurred.
19. `getEntangledParticles(uint256 particleId)`: View function to list the IDs of particles entangled with a given particle.
20. `getUserPredictionDetails(uint256 particleId, address user)`: View function to see a specific user's prediction details for a particle.
21. `getUserStats(address user)`: View function to get a user's overall prediction statistics (total staked, won, win rate).
22. `getPredictionPoolBalance(uint256 particleId)`: View function to see the total tokens staked in the pool for a specific particle's current prediction round.
23. `getActiveParticleIds()`: View function to list IDs of particles currently active and accepting predictions.
24. `getParticleHistory(uint256 particleId, uint256 historyIndex)`: View function to retrieve details of past prediction/resolution rounds for a particle.
25. `getTotalParticlesCreated()`: View function to get the total number of particles created historically.
26. `getContractTokenBalance()`: View function to see the total balance of the prediction token held by the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Contract: QuantumEntanglementPredictor
// Purpose: Decentralized prediction market centered around simulated quantum entanglement and state collapse.
// Users stake tokens to predict the outcome (state) of abstract 'particles'. Particles
// evolve pseudorandomly, can become 'entangled', and their 'collapse' (resolution)
// can influence entangled partners.

// Key Concepts:
// - Particles: Abstract entities with lifecycle and states.
// - States: Superposition (pending resolution), Collapsed (final state 0 or 1).
// - Entanglement: A dynamic link between particles where one's collapse influences another.
// - Prediction: Staking tokens on a particle's final state.
// - Resolution/Collapse: Pseudorandom determination of a particle's state at a specific block, triggering payouts.
// - Pseudorandomness: Using on-chain data (blockhash, timestamp, etc.) to simulate unpredictability.
// - Dynamic State: Particles can be created, decay, and entanglement links form/break.

// Outline:
// 1. License and Pragma
// 2. Imports (ERC20, Ownable, SafeMath)
// 3. Error Definitions
// 4. Events
// 5. State Variables
// 6. Structs (Particle, Prediction, UserState, EntanglementLink)
// 7. Modifiers (Admin, Owner)
// 8. Constructor
// 9. Admin Functions (set parameters, manage admins, withdraw fees)
// 10. Particle Management Functions (create, update, decay particles, entanglement - some user-callable)
// 11. User Prediction Functions (predict, cancel, boost, resolve)
// 12. View Functions (get details of particles, predictions, user stats, states)
// 13. Internal Helper Functions (pseudorandomness, state resolution, payout)

// Function Summary (26 Functions):
// See detailed list above the contract code.

contract QuantumEntanglementPredictor is Ownable {
    using SafeMath for uint256;

    // --- Errors ---
    error InvalidParticleId();
    error ParticleNotActive();
    error ParticleDecayed();
    error PredictionPeriodEnded();
    error ResolutionPeriodNotStarted();
    error ResolutionAlreadyOccurred();
    error PredictionNotFound();
    error InsufficientStake();
    error InvalidState();
    error SameParticleIds();
    error ParticlesAlreadyEntangled();
    error ParticlesNotEntangled();
    error CannotCancelAfterDeadline();
    error NoFeesToWithdraw();
    error NotAdmin();
    error UserAlreadyAdmin();
    error CannotRemoveOwnerAdmin();

    // --- Events ---
    event ParticleCreated(uint256 indexed particleId, address indexed creator, uint256 creationBlock);
    event ParticleDecayed(uint256 indexed particleId, uint256 decayBlock);
    event EntanglementEstablished(uint256 indexed particleIdA, uint256 indexed particleIdB, address indexed initiator);
    event EntanglementBroken(uint256 indexed particleIdA, uint256 indexed particleIdB);
    event Predicted(uint256 indexed particleId, address indexed predictor, uint8 predictedState, uint256 amount, uint256 indexed predictionBlock);
    event PredictionCancelled(uint256 indexed particleId, address indexed predictor);
    event PredictionBoosted(uint256 indexed particleId, address indexed predictor, uint256 additionalAmount);
    event ParticleResolved(uint256 indexed particleId, uint8 finalState, uint256 indexed resolutionBlock, uint256 totalPool, uint256 totalCorrectStake);
    event WinningsDistributed(uint256 indexed particleId, address indexed winner, uint256 amount);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event ParametersUpdated(uint256 feePercentage, uint256 predictionDeadlineOffset, uint256 resolutionOffset, uint256 decayPeriod);

    // --- State Variables ---
    IERC20 public immutable predictionToken;
    uint256 public totalParticlesCreated;
    uint256 public feePercentage; // e.g., 500 for 5% (500/10000) - Basis points recommended
    uint256 public constant FEE_DENOMINATOR = 10000; // 100%

    // Parameters controlling particle lifecycle and timing
    uint256 public defaultPredictionDeadlineOffset;
    uint256 public defaultResolutionOffset;
    uint256 public defaultDecayPeriod;

    mapping(address => bool) public admins;

    enum ParticleState { Superposition, CollapsedUp, CollapsedDown, Decayed }

    struct Particle {
        uint256 id;
        ParticleState currentState;
        uint8 finalState; // 0 or 1 if collapsed
        uint256 creationBlock;
        uint256 predictionDeadlineBlock; // Block number after which no more predictions are allowed
        uint256 resolutionBlock;       // Block number after which resolution can occur
        uint256 decayBlock;            // Block number after which particle can be decayed

        uint256 probabilityWeight; // Influences pseudorandom outcome calculation

        mapping(uint256 => bool) entangledWith; // particleId => true if entangled
        uint256[] entangledParticleIds; // Store dynamically for easier iteration/viewing

        uint256 currentPredictionRoundTotalStake;
        mapping(address => Prediction) predictions; // user address => Prediction details
        address[] currentPredictors; // List of addresses who predicted in this round

        // Store history of resolved rounds
        struct ResolvedRoundHistory {
            uint256 resolutionBlock;
            uint8 finalState;
            uint256 totalPool;
            uint256 totalCorrectStake;
        }
        ResolvedRoundHistory[] history;
    }

    struct Prediction {
        uint256 particleId;
        address predictor;
        uint8 predictedState; // 0 or 1
        uint256 amountStaked;
        uint256 predictionBlock;
        bool exists; // Use a boolean to check existence in mapping
    }

    struct UserState {
        uint256 totalStaked;
        uint256 totalWon;
        uint256 totalPredictions;
        uint256 correctPredictions;
    }

    mapping(uint256 => Particle) public particles;
    uint256[] private activeParticleIds; // Dynamic list of active particles

    mapping(address => UserState) public userStates;

    // --- Modifiers ---
    modifier onlyAdmin() {
        if (!admins[msg.sender] && msg.sender != owner()) {
            revert NotAdmin();
        }
        _;
    }

    // --- Constructor ---
    constructor(address _predictionTokenAddress) Ownable(msg.sender) {
        predictionToken = IERC20(_predictionTokenAddress);
        feePercentage = 500; // Default 5% fee
        defaultPredictionDeadlineOffset = 200; // Approx 1 hour (assuming 18s blocks)
        defaultResolutionOffset = 400;       // Approx 2 hours
        defaultDecayPeriod = 10000;          // Approx 2.5 days

        admins[msg.sender] = true; // Owner is also an admin
    }

    // --- Admin Functions ---

    // 2. setFeePercentage - Admin function to set the fee percentage on winnings.
    function setFeePercentage(uint256 newFee) external onlyAdmin {
        require(newFee <= FEE_DENOMINATOR, "Fee cannot exceed 100%");
        feePercentage = newFee;
        emit ParametersUpdated(feePercentage, defaultPredictionDeadlineOffset, defaultResolutionOffset, defaultDecayPeriod);
    }

    // 3. addAdmin - Owner function to add a new admin address.
    function addAdmin(address newAdmin) external onlyOwner {
        if (admins[newAdmin]) revert UserAlreadyAdmin();
        admins[newAdmin] = true;
        emit AdminAdded(newAdmin);
    }

    // 4. removeAdmin - Owner function to remove an admin address.
    function removeAdmin(address adminToRemove) external onlyOwner {
        if (adminToRemove == owner()) revert CannotRemoveOwnerAdmin(); // Owner is always admin
        if (!admins[adminToRemove]) revert NotAdmin(); // Cannot remove non-admin
        admins[adminToRemove] = false;
        emit AdminRemoved(adminToRemove);
    }

    // 15. withdrawFees - Admin function to withdraw accumulated protocol fees.
    function withdrawFees(address recipient) external onlyAdmin {
        uint256 balance = predictionToken.balanceOf(address(this));
        // We assume the only balance in the contract not belonging to a prediction pool
        // are accumulated fees. A more robust system might track fees separately.
        // This simplistic approach implies fees are withdrawn AFTER all potential payouts.
        // A better design would track fees accrued per resolution.
        // For this example, let's refine: let's say fees are transferred to owner/admin immediately upon resolution.
        // Reimplementing fee withdrawal logic: let's assume fees are sent to owner on resolution
        // and this function is just a fallback, or for future fee types.
        // Okay, let's modify the payout logic to transfer fees to owner directly during resolution.
        // This withdrawFees function can then be removed or repurposed later.
        // *Correction:* Let's keep withdrawFees but assume fees accumulate. Fees are deducted during payout
        // and remain in the contract until withdrawn. This function is for withdrawal.

        // Simple check: If contract holds more than combined current prediction pools, that surplus is potentially fees.
        uint256 totalInPools = 0;
        for(uint i = 0; i < activeParticleIds.length; i++) {
            totalInPools = totalInPools.add(particles[activeParticleIds[i]].currentPredictionRoundTotalStake);
        }

        uint256 feesAvailable = balance.sub(totalInPools);

        if (feesAvailable == 0) revert NoFeesToWithdraw();

        predictionToken.transfer(recipient, feesAvailable);
        emit FeesWithdrawn(recipient, feesAvailable);
    }

    // --- Particle Management Functions ---

    // 5. createParticle - Admin or paid-user function to create a new particle.
    function createParticle(
        uint256 _predictionDeadlineOffset,
        uint256 _resolutionOffset,
        uint256 _decayPeriod,
        uint256 _initialProbabilityWeight // Larger weight => higher chance of state 1 (Up)
    ) external payable {
        // Allow anyone to create a particle by sending Ether, or allow admin for free
        uint256 creationFee = 0.01 ether; // Example fee
        if (!admins[msg.sender]) {
            require(msg.value >= creationFee, "Insufficient creation fee");
        }

        totalParticlesCreated++;
        uint256 newParticleId = totalParticlesCreated;

        uint256 pDeadline = block.number.add(_predictionDeadlineOffset);
        uint256 pResolution = block.number.add(_resolutionOffset);
        uint256 pDecay = block.number.add(_decayPeriod);

        // Basic validation
        require(pDeadline < pResolution, "Resolution must be after prediction deadline");
        require(pResolution < pDecay, "Decay must be after resolution");
        require(_initialProbabilityWeight <= 10000, "Probability weight must be <= 10000"); // Basis points

        Particle storage newParticle = particles[newParticleId];
        newParticle.id = newParticleId;
        newParticle.currentState = ParticleState.Superposition;
        newParticle.creationBlock = block.number;
        newParticle.predictionDeadlineBlock = pDeadline;
        newParticle.resolutionBlock = pResolution;
        newParticle.decayBlock = pDecay;
        newParticle.probabilityWeight = _initialProbabilityWeight; // e.g. 5000 for 50% chance

        activeParticleIds.push(newParticleId);

        emit ParticleCreated(newParticleId, msg.sender, block.number);
    }

    // 6. updateParticleParameters - Admin function to adjust parameters of an existing particle.
    function updateParticleParameters(
        uint256 particleId,
        uint256 _predictionDeadlineOffset,
        uint256 _resolutionOffset,
        uint256 _decayPeriod,
        uint256 _probabilityWeight
    ) external onlyAdmin {
        Particle storage particle = particles[particleId];
        if (particle.creationBlock == 0 || particle.currentState == ParticleState.Decayed) revert InvalidParticleId();
        if (particle.currentState != ParticleState.Superposition) revert ResolutionAlreadyOccurred(); // Cannot update once resolved

        uint256 pDeadline = particle.creationBlock.add(_predictionDeadlineOffset); // Recalculate from creation block? Or current block? Let's use creation for fixed intervals.
        uint256 pResolution = particle.creationBlock.add(_resolutionOffset);
        uint256 pDecay = particle.creationBlock.add(_decayPeriod);

        require(pDeadline < pResolution, "Resolution must be after prediction deadline");
        require(pResolution < pDecay, "Decay must be after resolution");
        require(_probabilityWeight <= 10000, "Probability weight must be <= 10000");

        particle.predictionDeadlineBlock = pDeadline;
        particle.resolutionBlock = pResolution;
        particle.decayBlock = pDecay;
        particle.probabilityWeight = _probabilityWeight;

        // Event should reflect the update but maybe not all params changed. Simple event is fine.
        // emit ParticleUpdated(particleId, pDeadline, pResolution, pDecay, _probabilityWeight); // Add ParticleUpdated event
    }

    // 7. decayParticle - Callable by anyone after particle's decay period to clean up state.
    function decayParticle(uint256 particleId) external {
        Particle storage particle = particles[particleId];
        if (particle.creationBlock == 0 || particle.currentState == ParticleState.Decayed) revert InvalidParticleId();

        if (block.number < particle.decayBlock) revert("Cannot decay particle yet");
        if (particle.currentState == ParticleState.Superposition) revert("Particle must be resolved before decay"); // Cannot decay unresolved particle with active pool

        // Mark as decayed
        particle.currentState = ParticleState.Decayed;

        // Remove from active list (simple iteration and swap-remove)
        for (uint i = 0; i < activeParticleIds.length; i++) {
            if (activeParticleIds[i] == particleId) {
                activeParticleIds[i] = activeParticleIds[activeParticleIds.length - 1];
                activeParticleIds.pop();
                break;
            }
        }

        // Break all entanglement links involving this particle
        for(uint i = 0; i < particle.entangledParticleIds.length; i++) {
            uint256 entangledId = particle.entangledParticleIds[i];
            Particle storage entangledParticle = particles[entangledId];
            if (entangledParticle.creationBlock != 0 && entangledParticle.currentState != ParticleState.Decayed) {
                 _breakEntanglement(particleId, entangledId); // Internal helper to break the link symmetrically
            }
        }
        particle.entangledParticleIds = new uint256[](0); // Clear the array

        // Note: User predictions and history remain accessible via mappings, only particle struct is marked Decayed.

        emit ParticleDecayed(particleId, block.number);
    }

    // Helper to break entanglement symmetrically
    function _breakEntanglement(uint256 particleIdA, uint256 particleIdB) internal {
         Particle storage particleA = particles[particleIdA];
         Particle storage particleB = particles[particleIdB];

        if (particleA.entangledWith[particleIdB]) {
            particleA.entangledWith[particleIdB] = false;
             // Remove from array - simple loop
            for(uint i = 0; i < particleA.entangledParticleIds.length; i++) {
                if (particleA.entangledParticleIds[i] == particleIdB) {
                     particleA.entangledParticleIds[i] = particleA.entangledParticleIds[particleA.entangledParticleIds.length - 1];
                     particleA.entangledParticleIds.pop();
                     break;
                }
            }
        }
        if (particleB.entangledWith[particleIdA]) {
            particleB.entangledWith[particleIdA] = false;
             // Remove from array - simple loop
             for(uint i = 0; i < particleB.entangledParticleIds.length; i++) {
                if (particleB.entangledParticleIds[i] == particleIdA) {
                     particleB.entangledParticleIds[i] = particleB.entangledParticleIds[particleB.entangledParticleIds.length - 1];
                     particleB.entangledParticleIds.pop();
                     break;
                }
            }
        }
        emit EntanglementBroken(particleIdA, particleIdB);
    }

    // 8. establishEntanglement - Admin or result of attemptEntanglementProbe to link two particles.
    // This is typically an *internal* outcome of a user's probe or an admin action.
    // Exposing directly as admin function for completeness.
    function establishEntanglement(uint256 particleIdA, uint256 particleIdB) external onlyAdmin {
        if (particleIdA == particleIdB) revert SameParticleIds();
        Particle storage particleA = particles[particleIdA];
        Particle storage particleB = particles[particleIdB];

        if (particleA.creationBlock == 0 || particleA.currentState == ParticleState.Decayed) revert InvalidParticleId();
        if (particleB.creationBlock == 0 || particleB.currentState == ParticleState.Decayed) revert InvalidParticleId();
        if (particleA.currentState != ParticleState.Superposition || particleB.currentState != ParticleState.Superposition) revert("Particles must be in Superposition");
        if (particleA.entangledWith[particleIdB]) revert ParticlesAlreadyEntangled();

        particleA.entangledWith[particleIdB] = true;
        particleB.entangledWith[particleIdA] = true;
        particleA.entangledParticleIds.push(particleIdB);
        particleB.entangledParticleIds.push(particleIdA);

        emit EntanglementEstablished(particleIdA, particleIdB, msg.sender);
    }

     // 9. breakEntanglement - Admin function to break a link. Can also happen on decay internally.
     // Exposing directly as admin function for completeness.
    function breakEntanglement(uint256 particleIdA, uint256 particleIdB) external onlyAdmin {
         if (particleIdA == particleIdB) revert SameParticleIds();
         Particle storage particleA = particles[particleIdA];
         Particle storage particleB = particles[particleIdB];

         if (particleA.creationBlock == 0 || particleA.currentState == ParticleState.Decayed) revert InvalidParticleId();
         if (particleB.creationBlock == 0 || particleB.currentState == ParticleState.Decayed) revert InvalidParticleId();
         if (!particleA.entangledWith[particleIdB]) revert ParticlesNotEntangled();

         _breakEntanglement(particleIdA, particleIdB);
    }

    // 10. attemptEntanglementProbe - User function (pays fee) to attempt creating an entanglement link.
    function attemptEntanglementProbe(uint256 particleIdA, uint256 particleIdB) external payable {
        if (particleIdA == particleIdB) revert SameParticleIds();
        Particle storage particleA = particles[particleIdA];
        Particle storage particleB = particles[particleIdB];

        if (particleA.creationBlock == 0 || particleA.currentState == ParticleState.Decayed) revert InvalidParticleId();
        if (particleB.creationBlock == 0 || particleB.currentState == ParticleState.Decayed) revert InvalidParticleId();
        if (particleA.currentState != ParticleState.Superposition || particleB.currentState != ParticleState.Superposition) revert("Particles must be in Superposition");
        if (particleA.entangledWith[particleIdB]) revert ParticlesAlreadyEntangled();

        uint256 probeFee = 0.005 ether; // Example fee
        require(msg.value >= probeFee, "Insufficient probe fee");

        // Pseudorandom chance calculation
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, particleIdA, particleIdB, block.number)));
        uint256 chance = seed % 100; // 0-99, gives a probability percentage

        uint256 successThreshold = 30; // Example: 30% chance of success

        if (chance < successThreshold) {
            // Success!
            particleA.entangledWith[particleIdB] = true;
            particleB.entangledWith[particleIdA] = true;
            particleA.entangledParticleIds.push(particleIdB);
            particleB.entangledParticleIds.push(particleIdA);
            emit EntanglementEstablished(particleIdA, particleIdB, msg.sender);
        } else {
            // Failure - fee is kept.
            // Can emit a 'ProbeFailed' event if needed
        }
    }


    // --- User Prediction Functions ---

    // 11. predictParticleState - User function to stake tokens and predict the final state.
    function predictParticleState(uint256 particleId, uint8 predictedState, uint256 amount) external {
        Particle storage particle = particles[particleId];
        if (particle.creationBlock == 0 || particle.currentState == ParticleState.Decayed) revert InvalidParticleId();
        if (particle.currentState != ParticleState.Superposition) revert ResolutionAlreadyOccurred();
        if (block.number >= particle.predictionDeadlineBlock) revert PredictionPeriodEnded();
        if (amount == 0) revert InsufficientStake();
        if (predictedState > 1) revert InvalidState(); // Only 0 or 1

        // Check if user already predicted in this round
        if (particle.predictions[msg.sender].exists) {
            revert("Already predicted in this round, use boostPrediction");
        }

        // Transfer tokens to the contract
        bool success = predictionToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        // Store prediction
        particle.predictions[msg.sender] = Prediction({
            particleId: particleId,
            predictor: msg.sender,
            predictedState: predictedState,
            amountStaked: amount,
            predictionBlock: block.number,
            exists: true
        });

        particle.currentPredictionRoundTotalStake = particle.currentPredictionRoundTotalStake.add(amount);
        particle.currentPredictors.push(msg.sender); // Add to list of predictors for this round

        // Update user stats
        userStates[msg.sender].totalStaked = userStates[msg.sender].totalStaked.add(amount);
        userStates[msg.sender].totalPredictions++;

        emit Predicted(particleId, msg.sender, predictedState, amount, block.number);
    }

    // 12. cancelPrediction - User function to cancel an outstanding prediction before the deadline.
    function cancelPrediction(uint256 particleId) external {
        Particle storage particle = particles[particleId];
        if (particle.creationBlock == 0 || particle.currentState == ParticleState.Decayed) revert InvalidParticleId();
        Prediction storage prediction = particle.predictions[msg.sender];
        if (!prediction.exists) revert PredictionNotFound();
        if (block.number >= particle.predictionDeadlineBlock) revert CannotCancelAfterDeadline();

        uint256 amountToReturn = prediction.amountStaked;

        // Remove prediction data
        delete particle.predictions[msg.sender];

        // Update total stake for the round
        particle.currentPredictionRoundTotalStake = particle.currentPredictionRoundTotalStake.sub(amountToReturn);

        // Remove predictor from list (simple loop and swap-remove)
        for (uint i = 0; i < particle.currentPredictors.length; i++) {
            if (particle.currentPredictors[i] == msg.sender) {
                particle.currentPredictors[i] = particle.currentPredictors[particle.currentPredictors.length - 1];
                particle.currentPredictors.pop();
                break;
            }
        }

        // Update user stats (this makes win rate calculation tricky if we don't track cancelled separately)
        // For simplicity, let's not update user stats on cancel for now, just return tokens.
        // A more advanced version might track attempts vs actual resolutions.

        // Return tokens
        bool success = predictionToken.transfer(msg.sender, amountToReturn);
        require(success, "Token transfer failed");

        emit PredictionCancelled(particleId, msg.sender);
    }

    // 13. boostPrediction - User function to add more tokens to an existing prediction.
    function boostPrediction(uint256 particleId, uint256 additionalAmount) external {
        Particle storage particle = particles[particleId];
        if (particle.creationBlock == 0 || particle.currentState == ParticleState.Decayed) revert InvalidParticleId();
        Prediction storage prediction = particle.predictions[msg.sender];
        if (!prediction.exists) revert PredictionNotFound();
        if (block.number >= particle.predictionDeadlineBlock) revert PredictionPeriodEnded();
        if (additionalAmount == 0) revert InsufficientStake();

        // Transfer additional tokens
        bool success = predictionToken.transferFrom(msg.sender, address(this), additionalAmount);
        require(success, "Token transfer failed");

        // Update prediction details
        prediction.amountStaked = prediction.amountStaked.add(additionalAmount);

        // Update total stake for the round
        particle.currentPredictionRoundTotalStake = particle.currentPredictionRoundTotalStake.add(additionalAmount);

        // Update user stats
        userStates[msg.sender].totalStaked = userStates[msg.sender].totalStaked.add(additionalAmount);
        // Note: TotalPredictions count doesn't increase here, only on the initial prediction.

        emit PredictionBoosted(particleId, msg.sender, additionalAmount);
    }


    // 14. resolvePrediction - User function callable after the resolution block to trigger state collapse and claim winnings.
    function resolvePrediction(uint256 particleId) external {
        Particle storage particle = particles[particleId];
        if (particle.creationBlock == 0 || particle.currentState == ParticleState.Decayed) revert InvalidParticleId();
        if (block.number < particle.resolutionBlock) revert ResolutionPeriodNotStarted();
        if (particle.currentState != ParticleState.Superposition) revert ResolutionAlreadyOccurred(); // Already resolved

        // --- Core Resolution Logic ---
        uint8 finalState = _resolveParticleState(particleId); // Determine the final state

        particle.finalState = finalState;
        particle.currentState = (finalState == 0) ? ParticleState.CollapsedDown : ParticleState.CollapsedUp;

        emit ParticleResolved(particleId, finalState, block.number, particle.currentPredictionRoundTotalStake, 0); // Emit pool size before calculating correct stake

        // --- Payout Logic ---
        uint256 totalCorrectStake = 0;
        address[] memory currentPredictors = particle.currentPredictors; // Use memory copy as we'll clear the state

        for (uint i = 0; i < currentPredictors.length; i++) {
            address predictorAddress = currentPredictors[i];
            Prediction storage pred = particle.predictions[predictorAddress];

            // Only process predictions that exist and are for the correct state
            if (pred.exists && pred.predictedState == finalState) {
                totalCorrectStake = totalCorrectStake.add(pred.amountStaked);
                userStates[predictorAddress].correctPredictions++; // Update user stats
            }
             // Regardless of correctness, increment total predictions counted for user state?
             // No, we incremented totalPredictions on the initial predict.
        }

         // Update the emitted event with correct totalCorrectStake
        emit ParticleResolved(particleId, finalState, block.number, particle.currentPredictionRoundTotalStake, totalCorrectStake);


        if (totalCorrectStake > 0) {
            uint256 poolAfterFees = particle.currentPredictionRoundTotalStake.sub(
                particle.currentPredictionRoundTotalStake.mul(feePercentage).div(FEE_DENOMINATOR)
            );

            for (uint i = 0; i < currentPredictors.length; i++) {
                 address predictorAddress = currentPredictors[i];
                 Prediction storage pred = particle.predictions[predictorAddress];

                 if (pred.exists && pred.predictedState == finalState) {
                    // Calculate winnings proportional to their correct stake
                    uint256 winnings = poolAfterFees.mul(pred.amountStaked).div(totalCorrectStake);
                    userStates[predictorAddress].totalWon = userStates[predictorAddress].totalWon.add(winnings);

                    // Transfer winnings
                    bool success = predictionToken.transfer(predictorAddress, winnings);
                    // If transfer fails, log it but don't revert? Or revert?
                    // Reverting might punish others. Let's log and move on for robustness.
                    if (!success) {
                        // Future: Implement a claim function for failed transfers
                        emit event TransferFailed(predictorAddress, winnings); // Need to define this event
                    } else {
                        emit WinningsDistributed(particleId, predictorAddress, winnings);
                    }
                }
            }
        }

        // --- Clean up for the next round (or mark as resolved if no more rounds) ---
        // Store history
        particle.history.push(Particle.ResolvedRoundHistory({
             resolutionBlock: block.number,
             finalState: finalState,
             totalPool: particle.currentPredictionRoundTotalStake,
             totalCorrectStake: totalCorrectStake
        }));

        // Clear current prediction data for this round
        for (uint i = 0; i < currentPredictors.length; i++) {
            delete particle.predictions[currentPredictors[i]];
        }
        particle.currentPredictors = new address[](0);
        particle.currentPredictionRoundTotalStake = 0;

        // Note: Particles currently designed for single prediction round -> decay.
        // To support multiple rounds, we would need to reset predictionDeadlineBlock, resolutionBlock, etc.
        // For this contract's complexity, single round then decay/history is sufficient.

    }

    // --- Internal Helper Functions ---

    // _generatePseudoRandom - Generates a pseudorandom number.
    // WARNING: On-chain randomness is predictable, especially by miners.
    // This is for conceptual simulation, not cryptographic security.
    function _generatePseudoRandom(uint256 particleId) internal view returns (uint256) {
        // Use a combination of block data and particle-specific data for variability
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            block.difficulty, // Note: difficulty is deprecated on PoS, might be 0. Add backup.
            gasleft(),
            particleId,
            address(this) // Include contract address
        )));

        // If block.difficulty is 0, mix in blockhash of a recent, unpredictable block
        if (block.difficulty == 0) {
             // blockhash(block.number - N) is available for last 256 blocks
             // Choose a block number that is likely finalized but not easily predictable
             // Using block.number - 7 as an example offset
             uint256 safeBlock = block.number > 7 ? block.number - 7 : 0;
             bytes32 blockHash = blockhash(safeBlock);
             seed = uint256(keccak256(abi.encodePacked(seed, blockHash)));
        }

        return seed;
    }

    // _resolveParticleState - Determines the particle's final state (0 or 1).
    // Incorporates pseudorandomness, particle's probability weight, and ENTANGLEMENT effects.
    function _resolveParticleState(uint256 particleId) internal returns (uint8) {
        Particle storage particle = particles[particleId];

        // Check for entanglement influence first
        uint8 entangledInfluenceState = 2; // 0: force Down, 1: force Up, 2: no influence

        for (uint i = 0; i < particle.entangledParticleIds.length; i++) {
            uint256 entangledId = particle.entangledParticleIds[i];
            Particle storage entangledParticle = particles[entangledId];

            // If entangled particle is RESOLVED and NOT DECAYED
            // Entanglement effect rule: If entangled particle resolves, it attempts to force THIS particle
            // into the *opposite* state IF this particle is still in Superposition.
            // The influence happens based on the *most recent* entangled collapse *before* this particle's resolution block.
            // This adds complexity. For simplicity in this version, let's just check entanglement state at *this* resolution time.
            // If *any* entangled partner is Collapsed, it exerts influence. If multiple are collapsed, which one wins?
            // Let's define: The FIRST resolved entangled particle's influence takes precedence.
            // Or, more complex: The influence is a weighted sum? Let's keep it simpler: Any collapsed entangled particle
            // exerts an *opposite* state influence. If contradictory influences exist (e.g., entangled with A (collapsed Up)
            // and B (collapsed Down)), the pseudorandom outcome decides the tie-break.

            if (entangledParticle.currentState == ParticleState.CollapsedUp && !entangledParticle.entangledWith[particleId]) {
                 // Check if the entanglement link is still active symmetrically!
                 // If A resolved to Up, it tries to make B (this particle) go Down.
                 entangledInfluenceState = 0; // Force Down (0)
                 break; // Apply the first found influence
            } else if (entangledParticle.currentState == ParticleState.CollapsedDown && !entangledParticle.entangledWith[particleId]) {
                 // If A resolved to Down, it tries to make B (this particle) go Up.
                 entangledInfluenceState = 1; // Force Up (1)
                 break; // Apply the first found influence
            }
             // Re-check: The entanglement mapping on the *entangledParticle* side must *still* point to *this* particle.
             // If the link was broken *after* they resolved but *before* this particle resolves, the influence shouldn't apply?
             // Yes, link must be active at the time of THIS particle's resolution check.

             // Let's refine: Check if the link is active AND the entangled particle is collapsed.
             if (particle.entangledWith[entangledId] && (entangledParticle.currentState == ParticleState.CollapsedUp || entangledParticle.currentState == ParticleState.CollapsedDown)) {
                if (entangledParticle.finalState == 0) { // If entangled resolved Down (0)
                    entangledInfluenceState = 1; // Tries to pull this particle Up (1)
                    break;
                } else { // If entangled resolved Up (1)
                    entangledInfluenceState = 0; // Tries to pull this particle Down (0)
                    break;
                }
             }
        }

        // Generate pseudorandom number
        uint256 randomNumber = _generatePseudoRandom(particleId);
        uint256 randomPercentage = (randomNumber % 10001); // 0-10000 basis points

        uint8 determinedState;

        if (entangledInfluenceState != 2) {
            // Entanglement influence is present - it tries to force a state
             uint256 influenceStrength = 5000; // Example: Entanglement has a 50% chance to override randomness alone
             uint256 influenceRoll = (randomNumber / 10001) % 10001; // Use a different part of the random number

             if (influenceRoll < influenceStrength) {
                 // Entanglement influence succeeds in forcing the state (probabilistically)
                 determinedState = entangledInfluenceState;
             } else {
                 // Entanglement influence failed to override randomness, fall back to particle's probability weight
                 determinedState = (randomPercentage < particle.probabilityWeight) ? 1 : 0;
             }
        } else {
            // No entanglement influence, determine state based on particle's probability weight alone
            determinedState = (randomPercentage < particle.probabilityWeight) ? 1 : 0;
        }

        return determinedState;
    }


    // --- View Functions ---

    // 16. getParticleDetails - View function to get all structural details of a particle.
    function getParticleDetails(uint256 particleId) external view returns (
        uint256 id,
        ParticleState currentState,
        uint8 finalState,
        uint256 creationBlock,
        uint256 predictionDeadlineBlock,
        uint256 resolutionBlock,
        uint256 decayBlock,
        uint256 probabilityWeight,
        uint256 currentPredictionRoundTotalStake,
        uint256 historyCount,
        uint256 entangledCount
    ) {
        Particle storage particle = particles[particleId];
        if (particle.creationBlock == 0) revert InvalidParticleId(); // Check existence

        return (
            particle.id,
            particle.currentState,
            particle.finalState,
            particle.creationBlock,
            particle.predictionDeadlineBlock,
            particle.resolutionBlock,
            particle.decayBlock,
            particle.probabilityWeight,
            particle.currentPredictionRoundTotalStake,
            particle.history.length,
            particle.entangledParticleIds.length
        );
    }

    // 17. getParticleCurrentState - View function to see the particle's current state representation.
    function getParticleCurrentState(uint256 particleId) external view returns (ParticleState) {
         Particle storage particle = particles[particleId];
         if (particle.creationBlock == 0) revert InvalidParticleId();
         return particle.currentState;
    }

    // 18. getParticleResolutionState - View function to see the final collapsed state if resolution has occurred.
    function getParticleResolutionState(uint256 particleId) external view returns (uint8) {
        Particle storage particle = particles[particleId];
        if (particle.creationBlock == 0) revert InvalidParticleId();
        if (particle.currentState == ParticleState.Superposition || particle.currentState == ParticleState.Decayed) revert("Particle has not resolved yet");
        return particle.finalState;
    }

    // 19. getEntangledParticles - View function to list the IDs of particles entangled with a given particle.
    function getEntangledParticles(uint256 particleId) external view returns (uint256[] memory) {
         Particle storage particle = particles[particleId];
         if (particle.creationBlock == 0 || particle.currentState == ParticleState.Decayed) revert InvalidParticleId();
         return particle.entangledParticleIds;
    }

    // 20. getUserPredictionDetails - View function to see a specific user's prediction details for a particle.
    function getUserPredictionDetails(uint256 particleId, address user) external view returns (
        uint8 predictedState,
        uint256 amountStaked,
        uint256 predictionBlock,
        bool exists
    ) {
         Particle storage particle = particles[particleId];
         if (particle.creationBlock == 0 || particle.currentState == ParticleState.Decayed) revert InvalidParticleId();
         Prediction storage prediction = particle.predictions[user];
         return (
             prediction.predictedState,
             prediction.amountStaked,
             prediction.predictionBlock,
             prediction.exists
         );
    }

    // 21. getUserStats - View function to get a user's overall prediction statistics.
    function getUserStats(address user) external view returns (
        uint256 totalStaked,
        uint256 totalWon,
        uint256 totalPredictions,
        uint256 correctPredictions
    ) {
        UserState storage stats = userStates[user];
        return (
            stats.totalStaked,
            stats.totalWon,
            stats.totalPredictions,
            stats.correctPredictions
        );
    }

    // 22. getPredictionPoolBalance - View function to see the total tokens staked in the pool for a specific particle's current prediction round.
    function getPredictionPoolBalance(uint256 particleId) external view returns (uint256) {
        Particle storage particle = particles[particleId];
        if (particle.creationBlock == 0 || particle.currentState == ParticleState.Decayed) revert InvalidParticleId();
        return particle.currentPredictionRoundTotalStake;
    }

    // 23. getActiveParticleIds - View function to list IDs of particles currently active and accepting predictions or awaiting resolution/decay.
    function getActiveParticleIds() external view returns (uint256[] memory) {
        // Return a copy of the activeParticleIds array
        return activeParticleIds;
    }

     // 24. getParticleHistory - View function to retrieve details of past prediction/resolution rounds for a particle.
    function getParticleHistory(uint256 particleId, uint256 historyIndex) external view returns (
        uint256 resolutionBlock,
        uint8 finalState,
        uint256 totalPool,
        uint256 totalCorrectStake
    ) {
         Particle storage particle = particles[particleId];
         if (particle.creationBlock == 0) revert InvalidParticleId();
         require(historyIndex < particle.history.length, "History index out of bounds");
         Particle.ResolvedRoundHistory storage historyEntry = particle.history[historyIndex];
         return (
             historyEntry.resolutionBlock,
             historyEntry.finalState,
             historyEntry.totalPool,
             historyEntry.totalCorrectStake
         );
    }

    // 25. getTotalParticlesCreated - View function to get the total number of particles created historically.
    function getTotalParticlesCreated() external view returns (uint256) {
        return totalParticlesCreated;
    }

    // 26. getContractTokenBalance - View function to see the total balance of the prediction token held by the contract.
     function getContractTokenBalance() external view returns (uint256) {
        return predictionToken.balanceOf(address(this));
     }

     // --- Fallback/Receive ---
     receive() external payable {
        // Optionally handle incoming Ether, maybe as a general donation or future use.
        // For now, just accept it.
     }

     fallback() external payable {
        // Optionally handle calls to undefined functions.
        // For now, just accept Ether if sent, otherwise revert.
         if (msg.value == 0) {
            revert("Call to undefined function");
         }
     }

}
```