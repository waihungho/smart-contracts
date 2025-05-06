Okay, let's design a smart contract based on a concept of "Quantum Fluctuating Assets" or "Entropic Particles". This concept incorporates ideas of randomness, time-decay, state changes, and interaction, aiming for something beyond standard token or DeFi mechanics.

Here's the proposed contract: `QuantumFluctuator`.

**Core Concept:** Users can mint "Particles". Each Particle has a dynamic "State" that can change randomly over time or upon certain interactions (Fluctuation). Users can spend "Quantum Energy" (an internal resource) to "Observe" a particle, potentially stabilizing its state temporarily or influencing its future fluctuation probability. Particles also lose "Stability" over time (Entropy) and can "Decay" if stability is too low. Particles can be "Entangled", linking their fates probabilistically.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- CONTRACT OUTLINE ---
// 1. State Variables & Mappings
// 2. Struct Definitions (Particle, StateProperties)
// 3. Event Definitions
// 4. Admin Parameters (Owner-settable configurations)
// 5. Constructor
// 6. Modifiers
// 7. Internal Helper Functions (Randomness, Stability Calculation, Decay)
// 8. Core Particle Management & Interaction Functions (Mint, Fluctuate, Observe, Entangle, Burn, Upgrade Stability)
// 9. Quantum Energy Management Functions (Generate Energy)
// 10. Admin Functions (Set costs, rates, state properties, withdraw fees)
// 11. View & Query Functions (Get particle data, user energy, contract params, simulations)
// 12. ERC721 Standard Functions (Inherited and overridden if necessary)

// --- FUNCTION SUMMARY ---
// Admin Functions:
// 1.  withdrawFees(): Withdraw collected ETH fees (Owner only).
// 2.  setDecayRate(uint256 _rate): Set the rate at which particle stability decays per block (Owner only).
// 3.  setObservationCost(uint256 _cost): Set the ETH cost to observe a particle (Owner only).
// 4.  setObservationEnergyCost(uint256 _cost): Set the Energy cost to observe a particle (Owner only).
// 5.  setEntanglementCost(uint256 _cost): Set the ETH cost to entangle two particles (Owner only).
// 6.  setEntanglementEnergyCost(uint256 _cost): Set the Energy cost to entangle two particles (Owner only).
// 7.  setEnergyGenerationCost(uint256 _cost): Set the ETH cost to generate Quantum Energy (Owner only).
// 8.  setStabilityUpgradeCost(uint256 _cost): Set the ETH cost to upgrade particle stability (Owner only).
// 9.  setStabilityUpgradeEnergyCost(uint256 _cost): Set the Energy cost to upgrade particle stability (Owner only).
// 10. setStateProperties(uint256 _state, uint256 _fluctuationWeight, uint256 _stabilityEffect): Set properties for a specific state (Owner only).
// 11. setFluctuationCooldown(uint256 _cooldown): Set the minimum blocks between manual fluctuations (Owner only).
// 12. setInitialStability(uint256 _stability): Set the initial stability particles receive upon minting (Owner only).

// User / Core Interaction Functions:
// 13. mintParticle(uint256 initialStabilityBoost): Mint a new particle (Payable).
// 14. fluctuateParticle(uint256 _tokenId): Manually trigger state fluctuation for owned particle.
// 15. observeParticle(uint256 _tokenId): Pay cost to observe particle, potentially affecting stability/fluctuation (Payable).
// 16. entangleParticles(uint256 _tokenId1, uint256 _tokenId2): Pay cost to entangle two owned particles (Payable).
// 17. generateEnergy(): Pay cost to generate Quantum Energy (Payable).
// 18. upgradeStability(uint256 _tokenId): Pay cost to increase particle stability.
// 19. burnParticle(uint256 _tokenId): Burn an owned particle.

// View & Query Functions:
// 20. getParticleData(uint256 _tokenId): Get all data for a specific particle.
// 21. getUserEnergy(address _user): Get Quantum Energy balance for a user.
// 22. getStateProperties(uint256 _state): Get defined properties for a specific state.
// 23. calculateCurrentStability(uint256 _tokenId): Calculate current stability considering decay since last update.
// 24. simulateFluctuation(uint256 _tokenId): Simulate the potential outcome of a fluctuation without changing state.
// 25. getParticlesByOwner(address _owner): Get list of particle tokenIds owned by an address (uses ERC721Enumerable).
// 26. getContractParameters(): Get current values of admin-settable parameters.
// 27. getFluctuationCooldown(uint256 _tokenId): Get the remaining blocks until a particle can be fluctuated again.

// Standard ERC721/Enumerable Functions (implicitly provided by inheritance):
// - balanceOf(address owner)
// - ownerOf(uint256 tokenId)
// - transferFrom(address from, address to, uint256 tokenId)
// - safeTransferFrom(address from, address to, uint256 tokenId)
// - approve(address to, uint256 tokenId)
// - getApproved(uint256 tokenId)
// - setApprovalForAll(address operator, bool approved)
// - isApprovedForAll(address owner, address operator)
// - supportsInterface(bytes4 interfaceId)
// - totalSupply()
// - tokenOfOwnerByIndex(address owner, uint256 index)
// - tokenByIndex(uint256 index)


contract QuantumFluctuator is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;
    uint256 public constant MAX_STATES = 10; // Example: States 0 to 9
    uint256 public constant DECAYED_STATE = 0; // State representing decay

    struct Particle {
        uint256 tokenId;
        uint256 currentState;
        uint256 birthBlock;
        uint256 lastInteractionBlock; // Block of last fluctuation, observation, or entanglement
        uint256 stabilityScore; // Represents resistance to decay and influences fluctuation
    }

    mapping(uint256 => Particle) public particles;
    mapping(address => uint256) public quantumEnergy; // Internal, non-transferable energy

    // --- Admin Parameters ---
    uint256 public decayRatePerBlock; // Rate at which stability decreases per block
    uint256 public observationCostETH; // ETH cost to observe
    uint256 public observationCostEnergy; // Energy cost to observe
    uint256 public entanglementCostETH; // ETH cost to entangle
    uint256 public entanglementCostEnergy; // Energy cost to entangle
    uint256 public energyGenerationCostETH; // ETH cost to generate energy
    uint256 public stabilityUpgradeCostETH; // ETH cost to upgrade stability
    uint256 public stabilityUpgradeCostEnergy; // Energy cost to upgrade stability
    uint256 public fluctuationCooldownBlocks; // Minimum blocks between manual fluctuations per particle
    uint256 public initialStability; // Stability given upon minting
    uint256 public stabilityThresholdDecay; // Below this stability, decay logic is severe

    struct StateProperties {
        uint256 fluctuationWeight; // Influences probability distribution in fluctuation
        uint256 stabilityEffect;   // How much observing/interacting in this state affects stability
        // Could add more properties like 'utility', 'color', 'rarity', etc.
    }
    mapping(uint256 => StateProperties) public stateProperties;

    // --- Events ---
    event ParticleMinted(uint256 indexed tokenId, address indexed owner, uint256 initialState, uint256 initialStability);
    event ParticleFluctuated(uint256 indexed tokenId, uint256 oldState, uint256 newState, uint256 finalStability);
    event ParticleObserved(uint256 indexed tokenId, address indexed observer, uint256 stabilityBoost, uint256 energyUsed, uint256 ethUsed);
    event ParticlesEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 energyUsed, uint256 ethUsed);
    event QuantumEnergyGenerated(address indexed user, uint256 amount, uint256 ethUsed);
    event StabilityUpgraded(uint256 indexed tokenId, uint256 stabilityAdded, uint256 energyUsed, uint256 ethUsed);
    event ParticleBurned(uint256 indexed tokenId, address indexed owner);
    event ParticleDecayed(uint256 indexed tokenId, uint256 finalStability);
    event StatePropertiesUpdated(uint256 indexed state, uint256 fluctuationWeight, uint256 stabilityEffect);
    event ContractParametersUpdated();


    // --- Constructor ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        // Set some initial default parameters (Owner should likely update these)
        decayRatePerBlock = 1;
        observationCostETH = 0.001 ether;
        observationCostEnergy = 10;
        entanglementCostETH = 0.002 ether;
        entanglementCostEnergy = 15;
        energyGenerationCostETH = 0.0005 ether;
        stabilityUpgradeCostETH = 0.0007 ether;
        stabilityUpgradeCostEnergy = 12;
        fluctuationCooldownBlocks = 10; // Cooldown period in blocks
        initialStability = 100;
        stabilityThresholdDecay = 20; // Particles below this stability are prone to severe decay

        // Set some initial state properties (example)
        stateProperties[0] = StateProperties({ fluctuationWeight: 5, stabilityEffect: 0 }); // Decayed state
        stateProperties[1] = StateProperties({ fluctuationWeight: 10, stabilityEffect: 5 });
        stateProperties[2] = StateProperties({ fluctuationWeight: 8, stabilityEffect: 8 });
        stateProperties[3] = StateProperties({ fluctuationWeight: 12, stabilityEffect: 6 });
        stateProperties[4] = StateProperties({ fluctuationWeight: 6, stabilityEffect: 10 });
        // ... define for other states up to MAX_STATES - 1
        for (uint256 i = 5; i < MAX_STATES; i++) {
             stateProperties[i] = StateProperties({ fluctuationWeight: 7 + i, stabilityEffect: 10 - (i % 5) }); // Example varying properties
        }

        emit ContractParametersUpdated();
    }

    // --- Modifiers ---
    modifier particleExists(uint256 _tokenId) {
        require(_exists(_tokenId), "Particle does not exist");
        _;
    }

    modifier isParticleOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not particle owner or approved");
        _;
    }

    modifier notDecayed(uint256 _tokenId) {
         Particle storage particle = particles[_tokenId];
         require(particle.currentState != DECAYED_STATE, "Particle has decayed and is inert");
         _;
    }

    // --- Internal Helper Functions ---

    // Simple pseudo-random number generation (NOT cryptographically secure)
    function _generateRandomSeed(uint256 _tokenId, uint256 _extraEntropy) internal view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Or block.basefee in post-EIP1559
            msg.sender,
            _tokenId,
            particles[_tokenId].lastInteractionBlock,
            _extraEntropy,
            tx.origin // Be cautious with tx.origin
        )));
         // Using block.number for extra entropy is common but predictable.
         // Using blockhash(block.number - 1) is an alternative if available.
         // For demonstration, combining multiple simple sources.
        seed = seed ^ uint256(keccak256(abi.encodePacked(block.number, _extraEntropy, msg.data)));
        return seed;
    }

    // Calculate stability loss based on time since last interaction
    function _calculateStabilityLoss(uint256 _lastInteractionBlock, uint256 _currentStability) internal view returns (uint256) {
        uint256 blocksPassed = block.number.sub(_lastInteractionBlock);
        uint256 potentialLoss = blocksPassed.mul(decayRatePerBlock);
        return _currentStability > potentialLoss ? potentialLoss : _currentStability;
    }

    // Apply decay effects if stability is too low
    function _applyDecayIfNecessary(uint256 _tokenId) internal {
        Particle storage particle = particles[_tokenId];
        uint256 currentCalculatedStability = particle.stabilityScore.sub(_calculateStabilityLoss(particle.lastInteractionBlock, particle.stabilityScore));

        if (currentCalculatedStability < stabilityThresholdDecay && particle.currentState != DECAYED_STATE) {
            // Severe decay effect: Reset state to 0 and drastically reduce stability
            particle.currentState = DECAYED_STATE;
            particle.stabilityScore = currentCalculatedStability.div(2); // Halve remaining stability
            particle.lastInteractionBlock = block.number; // Record decay happened
            emit ParticleDecayed(_tokenId, particle.stabilityScore);
        } else {
             // If not severe decay, just update stability based on calculated loss
             particle.stabilityScore = currentCalculatedStability;
        }
    }

    // Helper to retrieve mutable particle struct
    function _getParticle(uint256 _tokenId) internal particleExists(_tokenId) returns (Particle storage) {
         return particles[_tokenId];
    }

    // --- Core Particle Management & Interaction ---

    // 13. mintParticle
    function mintParticle(uint256 initialStabilityBoost) external payable {
        uint256 newItemId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // Simple pseudo-random initial state
        uint256 seed = _generateRandomSeed(newItemId, msg.value);
        uint256 initialState = seed % MAX_STATES;
        if (initialState == DECAYED_STATE) {
             initialState = (initialState + 1) % MAX_STATES; // Avoid minting in decayed state
        }

        uint256 stability = initialStability.add(initialStabilityBoost);

        particles[newItemId] = Particle({
            tokenId: newItemId,
            currentState: initialState,
            birthBlock: block.number,
            lastInteractionBlock: block.number,
            stabilityScore: stability
        });

        _safeMint(msg.sender, newItemId);

        emit ParticleMinted(newItemId, msg.sender, initialState, stability);
    }

    // 14. fluctuateParticle
    function fluctuateParticle(uint256 _tokenId) external isParticleOwner(_tokenId) particleExists(_tokenId) notDecayed(_tokenId) {
        Particle storage particle = _getParticle(_tokenId);

        require(block.number >= particle.lastInteractionBlock.add(fluctuationCooldownBlocks), "Fluctuation on cooldown");

        _applyDecayIfNecessary(_tokenId); // Apply decay before fluctuation

        uint256 seed = _generateRandomSeed(_tokenId, 0); // Use particle ID and block data
        uint256 oldState = particle.currentState;
        uint256 fluctuationInfluence = seed % 100; // 0-99

        uint256 newState;

        // More complex fluctuation logic could incorporate stability, state properties, etc.
        // Example: Higher stability makes state changes less drastic or less likely to decay
        if (particle.stabilityScore > 50 && fluctuationInfluence < 20) { // High stability resists random change
             newState = oldState; // State doesn't change
        } else if (particle.stabilityScore < stabilityThresholdDecay && fluctuationInfluence < 50) {
             newState = DECAYED_STATE; // High chance to decay if stability is low
        }
         else {
            // Default fluctuation: move to a neighboring state or a random state based on fluctuation weight
            uint256 changeDirection = seed % 2; // 0 or 1
            if (changeDirection == 0) {
                newState = (oldState + 1) % MAX_STATES;
            } else {
                 // Handle wrap-around for state 0
                newState = (oldState == 0) ? MAX_STATES - 1 : oldState - 1;
            }

            // Apply influence from current state's fluctuation weight
            uint256 weight = stateProperties[oldState].fluctuationWeight;
            uint256 weightedShift = (seed % weight) - (weight / 2); // Shift based on weight
            newState = (newState + uint256(int256(weightedShift))).mod(MAX_STATES); // Ensure it stays within bounds
         }

        // Ensure new state is not outside bounds or accidentally Decayed if not intended by logic
        if (newState >= MAX_STATES || (newState == DECAYED_STATE && particle.stabilityScore >= stabilityThresholdDecay)) {
             newState = (newState + 1) % MAX_STATES; // Simple correction
        }


        particle.currentState = newState;
        particle.lastInteractionBlock = block.number;

        // Stability changes slightly upon fluctuation (e.g., minor loss from energy dissipation)
        particle.stabilityScore = particle.stabilityScore > 1 ? particle.stabilityScore.sub(1) : 0;

        emit ParticleFluctuated(_tokenId, oldState, newState, particle.stabilityScore);
    }

    // 15. observeParticle
    function observeParticle(uint256 _tokenId) external payable isParticleOwner(_tokenId) particleExists(_tokenId) notDecayed(_tokenId) {
        Particle storage particle = _getParticle(_tokenId);

        uint256 requiredEnergy = observationCostEnergy;
        uint256 requiredETH = observationCostETH;

        require(quantumEnergy[msg.sender] >= requiredEnergy, "Not enough Quantum Energy");
        require(msg.value >= requiredETH, "Not enough ETH sent");

        // Apply decay before observation
        _applyDecayIfNecessary(_tokenId);

        // Observation effect: Boost stability and reset decay timer
        uint256 stabilityBoost = stateProperties[particle.currentState].stabilityEffect; // Boost depends on current state
        particle.stabilityScore = particle.stabilityScore.add(stabilityBoost);
        particle.lastInteractionBlock = block.number; // Observation resets decay timer

        // Consume resources
        quantumEnergy[msg.sender] = quantumEnergy[msg.sender].sub(requiredEnergy);
        // Refund excess ETH
        if (msg.value > requiredETH) {
            payable(msg.sender).transfer(msg.value.sub(requiredETH));
        }
        // Contract keeps required ETH (collected as fees)

        emit ParticleObserved(_tokenId, msg.sender, stabilityBoost, requiredEnergy, requiredETH);
    }

    // 16. entangleParticles
    function entangleParticles(uint256 _tokenId1, uint256 _tokenId2) external payable isParticleOwner(_tokenId1) isParticleOwner(_tokenId2) particleExists(_tokenId1) particleExists(_tokenId2) notDecayed(_tokenId1) notDecayed(_tokenId2) {
        require(_tokenId1 != _tokenId2, "Cannot entangle a particle with itself");

        Particle storage particle1 = _getParticle(_tokenId1);
        Particle storage particle2 = _getParticle(_tokenId2);

        uint256 requiredEnergy = entanglementCostEnergy;
        uint256 requiredETH = entanglementCostETH;

        require(quantumEnergy[msg.sender] >= requiredEnergy, "Not enough Quantum Energy");
        require(msg.value >= requiredETH, "Not enough ETH sent");

        // Apply decay before entanglement
        _applyDecayIfNecessary(_tokenId1);
        _applyDecayIfNecessary(_tokenId2);


        // Entanglement effect: Influence each other's state and potentially combine stability
        uint256 seed1 = _generateRandomSeed(_tokenId1, _tokenId2);
        uint256 seed2 = _generateRandomSeed(_tokenId2, _tokenId1);

        // Example: Combine states based on a probabilistic outcome influenced by stability
        uint256 combinedStability = particle1.stabilityScore.add(particle2.stabilityScore).div(2);
        uint256 avgFluctuationWeight = (stateProperties[particle1.currentState].fluctuationWeight + stateProperties[particle2.currentState].fluctuationWeight) / 2;

        uint256 outcome = (seed1 + seed2 + combinedStability + avgFluctuationWeight) % 100;

        uint256 newStabilityBoost = stateProperties[particle1.currentState].stabilityEffect + stateProperties[particle2.currentState].stabilityEffect;

        // Outcome logic (simplified example)
        if (outcome < 30) { // Low probability, both change randomly
            fluctuateParticle(_tokenId1); // Call internal fluctuation logic
            fluctuateParticle(_tokenId2);
            // Need to re-get storage pointers as fluctuateParticle might modify state
             particle1 = _getParticle(_tokenId1);
             particle2 = _getParticle(_tokenId2);
        } else if (outcome < 70) { // Medium probability, states average/combine
            uint256 avgState = (particle1.currentState + particle2.currentState) / 2;
            // Simple averaging - can make this more complex
            particle1.currentState = avgState;
            particle2.currentState = avgState;
             // Stability boost applied to both
             particle1.stabilityScore = particle1.stabilityScore.add(newStabilityBoost / 2);
             particle2.stabilityScore = particle2.stabilityScore.add(newStabilityBoost / 2);
        } else { // High probability, states become linked (e.g., one copies the other, stability boosted)
             // Let's say particle 2 copies particle 1's state, and both get stability boost
             particle2.currentState = particle1.currentState;
             particle1.stabilityScore = particle1.stabilityScore.add(newStabilityBoost);
             particle2.stabilityScore = particle2.stabilityScore.add(newStabilityBoost);
        }

         // Ensure states are within bounds after any combination logic
         particle1.currentState = particle1.currentState % MAX_STATES;
         particle2.currentState = particle2.currentState % MAX_STATES;

        particle1.lastInteractionBlock = block.number;
        particle2.lastInteractionBlock = block.number;

        // Consume resources
        quantumEnergy[msg.sender] = quantumEnergy[msg.sender].sub(requiredEnergy);
         if (msg.value > requiredETH) {
            payable(msg.sender).transfer(msg.value.sub(requiredETH));
        }

        emit ParticlesEntangled(_tokenId1, _tokenId2, requiredEnergy, requiredETH);
    }

    // 17. generateEnergy
    function generateEnergy() external payable {
        uint256 requiredETH = energyGenerationCostETH;
        require(msg.value >= requiredETH, "Not enough ETH sent");

        // Energy generation amount could be fixed, or scale with ETH sent, or time.
        // Fixed amount for simplicity.
        uint256 energyAmount = 50; // Example amount

        quantumEnergy[msg.sender] = quantumEnergy[msg.sender].add(energyAmount);

        if (msg.value > requiredETH) {
            payable(msg.sender).transfer(msg.value.sub(requiredETH));
        }

        emit QuantumEnergyGenerated(msg.sender, energyAmount, requiredETH);
    }

    // 18. upgradeStability
    function upgradeStability(uint256 _tokenId) external payable isParticleOwner(_tokenId) particleExists(_tokenId) notDecayed(_tokenId) {
        Particle storage particle = _getParticle(_tokenId);

        uint256 requiredEnergy = stabilityUpgradeCostEnergy;
        uint256 requiredETH = stabilityUpgradeCostETH;

        require(quantumEnergy[msg.sender] >= requiredEnergy, "Not enough Quantum Energy");
        require(msg.value >= requiredETH, "Not enough ETH sent");

        // Apply decay before upgrading
        _applyDecayIfNecessary(_tokenId);

        uint256 stabilityAdded = 30; // Example fixed boost
        particle.stabilityScore = particle.stabilityScore.add(stabilityAdded);
        particle.lastInteractionBlock = block.number; // Upgrading stability also counts as interaction

        // Consume resources
        quantumEnergy[msg.sender] = quantumEnergy[msg.sender].sub(requiredEnergy);
        if (msg.value > requiredETH) {
            payable(msg.sender).transfer(msg.value.sub(requiredETH));
        }

        emit StabilityUpgraded(_tokenId, stabilityAdded, requiredEnergy, requiredETH);
    }

    // 19. burnParticle
    function burnParticle(uint256 _tokenId) external isParticleOwner(_tokenId) particleExists(_tokenId) {
        // Optional: Add a cost to burn, or a benefit (e.g., regain some energy)
        _burn(_tokenId);
        // Optionally, delete particle data explicitly to save gas on future reads, though _burn handles state
        // delete particles[_tokenId]; // This is complex with ERC721Enumerable. ERC721 handles internal state.
        emit ParticleBurned(_tokenId, msg.sender);
    }


    // --- Admin Functions (Owner only) ---

    // 1. withdrawFees
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        payable(owner()).transfer(balance);
    }

    // 2. setDecayRate
    function setDecayRate(uint256 _rate) external onlyOwner {
        decayRatePerBlock = _rate;
        emit ContractParametersUpdated();
    }

    // 3. setObservationCost
    function setObservationCost(uint256 _cost) external onlyOwner {
        observationCostETH = _cost;
        emit ContractParametersUpdated();
    }

     // 4. setObservationEnergyCost
    function setObservationEnergyCost(uint256 _cost) external onlyOwner {
        observationCostEnergy = _cost;
        emit ContractParametersUpdated();
    }

    // 5. setEntanglementCost
    function setEntanglementCost(uint256 _cost) external onlyOwner {
        entanglementCostETH = _cost;
        emit ContractParametersUpdated();
    }

    // 6. setEntanglementEnergyCost
    function setEntanglementEnergyCost(uint256 _cost) external onlyOwner {
        entanglementCostEnergy = _cost;
        emit ContractParametersUpdated();
    }

    // 7. setEnergyGenerationCost
    function setEnergyGenerationCost(uint256 _cost) external onlyOwner {
        energyGenerationCostETH = _cost;
        emit ContractParametersUpdated();
    }

    // 8. setStabilityUpgradeCost
    function setStabilityUpgradeCost(uint256 _cost) external onlyOwner {
        stabilityUpgradeCostETH = _cost;
        emit ContractParametersUpdated();
    }

    // 9. setStabilityUpgradeEnergyCost
    function setStabilityUpgradeEnergyCost(uint256 _cost) external onlyOwner {
        stabilityUpgradeCostEnergy = _cost;
        emit ContractParametersUpdated();
    }

    // 10. setStateProperties
    function setStateProperties(uint256 _state, uint256 _fluctuationWeight, uint256 _stabilityEffect) external onlyOwner {
        require(_state < MAX_STATES, "Invalid state index");
        stateProperties[_state] = StateProperties({
            fluctuationWeight: _fluctuationWeight,
            stabilityEffect: _stabilityEffect
        });
        emit StatePropertiesUpdated(_state, _fluctuationWeight, _stabilityEffect);
    }

    // 11. setFluctuationCooldown
    function setFluctuationCooldown(uint256 _cooldown) external onlyOwner {
        fluctuationCooldownBlocks = _cooldown;
        emit ContractParametersUpdated();
    }

    // 12. setInitialStability
     function setInitialStability(uint256 _stability) external onlyOwner {
         initialStability = _stability;
         emit ContractParametersUpdated();
     }

    // --- View & Query Functions ---

    // 20. getParticleData
    function getParticleData(uint256 _tokenId) external view particleExists(_tokenId) returns (uint256, uint256, uint256, uint256, uint256)) {
        Particle storage particle = particles[_tokenId];
        return (
            particle.tokenId,
            particle.currentState,
            particle.birthBlock,
            particle.lastInteractionBlock,
            particle.stabilityScore // Note: This is the score *before* considering decay since last interaction
        );
    }

    // 21. getUserEnergy
    function getUserEnergy(address _user) external view returns (uint256) {
        return quantumEnergy[_user];
    }

    // 22. getStateProperties
    function getStateProperties(uint256 _state) external view returns (uint256 fluctuationWeight, uint256 stabilityEffect) {
        require(_state < MAX_STATES, "Invalid state index");
        StateProperties storage props = stateProperties[_state];
        return (props.fluctuationWeight, props.stabilityEffect);
    }

    // 23. calculateCurrentStability
    function calculateCurrentStability(uint256 _tokenId) external view particleExists(_tokenId) returns (uint256) {
        Particle storage particle = particles[_tokenId];
        return particle.stabilityScore.sub(_calculateStabilityLoss(particle.lastInteractionBlock, particle.stabilityScore));
    }

    // 24. simulateFluctuation
    function simulateFluctuation(uint256 _tokenId) external view particleExists(_tokenId) notDecayed(_tokenId) returns (uint256 potentialNextState) {
        Particle storage particle = particles[_tokenId];
         // Simulate seed based on current predictable factors + a small extra entropy
         uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            msg.sender, // The caller influences the simulation seed
            _tokenId,
            particle.lastInteractionBlock,
            block.number // Current block number
        )));

        uint256 oldState = particle.currentState;
        uint256 fluctuationInfluence = seed % 100;

        uint256 newState;

         // Use the same logic as fluctuateParticle, but without state changes
        if (particle.stabilityScore > 50 && fluctuationInfluence < 20) {
             newState = oldState;
        } else if (particle.stabilityScore < stabilityThresholdDecay && fluctuationInfluence < 50) {
             newState = DECAYED_STATE;
        }
         else {
            uint256 changeDirection = seed % 2;
            if (changeDirection == 0) {
                newState = (oldState + 1) % MAX_STATES;
            } else {
                newState = (oldState == 0) ? MAX_STATES - 1 : oldState - 1;
            }

            uint256 weight = stateProperties[oldState].fluctuationWeight;
            uint256 weightedShift = (seed % weight) - (weight / 2);
            newState = (newState + uint256(int256(weightedShift))).mod(MAX_STATES);
         }

         if (newState >= MAX_STATES || (newState == DECAYED_STATE && particle.stabilityScore >= stabilityThresholdDecay)) {
             newState = (newState + 1) % MAX_STATES;
        }


        return newState;
    }

    // 25. getParticlesByOwner
    function getParticlesByOwner(address _owner) external view returns (uint256[] memory) {
         uint256 tokenCount = balanceOf(_owner);
         uint256[] memory tokenIds = new uint256[](tokenCount);
         for (uint256 i = 0; i < tokenCount; i++) {
             tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
         }
         return tokenIds;
    }

    // 26. getContractParameters
     function getContractParameters() external view returns (
         uint256 currentDecayRatePerBlock,
         uint256 currentObservationCostETH,
         uint256 currentObservationCostEnergy,
         uint256 currentEntanglementCostETH,
         uint256 currentEntanglementCostEnergy,
         uint256 currentEnergyGenerationCostETH,
         uint256 currentStabilityUpgradeCostETH,
         uint256 currentStabilityUpgradeCostEnergy,
         uint256 currentFluctuationCooldownBlocks,
         uint256 currentInitialStability,
         uint256 currentStabilityThresholdDecay,
         uint256 maxStates,
         uint256 decayedState
     ) {
         return (
             decayRatePerBlock,
             observationCostETH,
             observationCostEnergy,
             entanglementCostETH,
             entanglementCostEnergy,
             energyGenerationCostETH,
             stabilityUpgradeCostETH,
             stabilityUpgradeCostEnergy,
             fluctuationCooldownBlocks,
             initialStability,
             stabilityThresholdDecay,
             MAX_STATES,
             DECAYED_STATE
         );
     }

     // 27. getFluctuationCooldown
     function getFluctuationCooldown(uint256 _tokenId) external view particleExists(_tokenId) returns (uint256 blocksRemaining) {
         Particle storage particle = particles[_tokenId];
         uint256 nextFluctuationBlock = particle.lastInteractionBlock.add(fluctuationCooldownBlocks);
         if (block.number >= nextFluctuationBlock) {
             return 0;
         } else {
             return nextFluctuationBlock.sub(block.number);
         }
     }


    // The following functions are overrides required by Solidity.
    // We are using ERC721Enumerable from OpenZeppelin, which handles the core logic
    // of tracking token supply, ownership, and token indices.
    // We only need to override the mint/burn hooks if we need custom logic
    // specific to *our* Particle struct deletion/creation, but in this design
    // the `particles` mapping complements ERC721's internal state, it doesn't replace it.
    // _safeMint is called in mintParticle.
    // _burn is called in burnParticle.

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address owner, uint256 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(owner, amount);
    }

     function tokenOfOwnerByIndex(address owner, uint256 index) public view override(ERC721Enumerable) returns (uint256) {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    function tokenByIndex(uint256 index) public view override(ERC721Enumerable) returns (uint256) {
        return super.tokenByIndex(index);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```