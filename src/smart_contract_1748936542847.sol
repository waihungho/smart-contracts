Okay, here is a Solidity smart contract concept called `QuantumFusion`. It's an ERC721 contract where tokens represent unique "Quantum Particles". These particles have dynamic states and attributes that can change through user interactions (like fusion, refinement, mutation) and simulated environmental factors (like decay).

This concept incorporates:
*   **Dynamic NFTs:** Particle attributes and states can change over time or based on interactions.
*   **Crafting/Alchemy:** Users can combine particles (`fuseParticles`) to create new ones.
*   **Simulated Systems:** Particles have properties like stability and a state (`QuantumState`) that evolves.
*   **Conditional Logic:** Actions like fusion or mutation might succeed or fail based on particle properties and randomness.
*   **State Management:** Tracking particle attributes, history, and entanglement.
*   **Owner-Configurable Parameters:** The contract owner can adjust certain system parameters (like fusion costs, decay rates, catalyst effects).
*   **Pseudo-Randomness:** Using on-chain data to introduce variability (with caveats about its security for high-value outcomes).

It avoids directly copying standard open-source examples by creating a unique, interconnected system of particle states and interactions beyond a simple ERC721 or basic staking/farming contract.

---

### `QuantumFusion` Smart Contract Outline and Function Summary

**Contract Name:** `QuantumFusion`
**Inherits:** ERC721, Ownable, Pausable
**Concept:** A system where users own unique "Quantum Particles" (ERC721 tokens) that can be fused, refined, mutated, and undergo state changes based on simulated quantum principles and user actions.

**Core Entities:**
*   `Particle`: A struct representing a unique ERC721 token with dynamic attributes (type, charge, stability, state, history).
*   `ParticleType`: Enum defining different categories of particles (e.g., Elementary, Composite, Exotic).
*   `QuantumState`: Enum defining the current state of a particle (e.g., Superposed, Stable, Entangled, Decayed, Mutating).

**Key State Variables:**
*   `particles`: Mapping from token ID to `Particle` struct.
*   `_tokenIdCounter`: Counter for minting new particles.
*   `fusionParameters`: Struct or mapping defining costs, success rates, and outcomes of fusion.
*   `decayRate`: Parameter influencing how quickly particles decay.
*   `catalystEffects`: Mapping defining how different "catalysts" affect particles.
*   `entangledPairs`: Mapping or structure to track entangled particles.

**Function Summary (>= 20 functions):**

1.  **ERC721 Standard Functions (9 functions):**
    *   `balanceOf(address owner)`: Get number of tokens owned by an address.
    *   `ownerOf(uint256 tokenId)`: Get owner of a specific token.
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe token transfer.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Token transfer (less safe).
    *   `approve(address to, uint256 tokenId)`: Approve an address to spend a token.
    *   `setApprovalForAll(address operator, bool approved)`: Approve an operator for all tokens.
    *   `getApproved(uint256 tokenId)`: Get the approved address for a token.
    *   `isApprovedForAll(address owner, address operator)`: Check if an operator is approved.
    *   `supportsInterface(bytes4 interfaceId)`: ERC165 standard interface check.

2.  **Particle Creation & Minting (2 functions):**
    *   `mintInitialParticles(address owner, ParticleType initialType, uint256 count)`: Mint a batch of initial, non-fused particles to an address.
    *   `mintFusedParticle(address owner, uint256 parent1Id, uint256 parent2Id, Particle calldata newParticleData)` (Internal/Helper): Creates a new particle resulting from fusion.

3.  **Particle Actions & Interactions (6 functions):**
    *   `fuseParticles(uint256 tokenId1, uint256 tokenId2)`: Attempts to fuse two particles owned by the caller. May succeed (burns parents, mints new particle) or fail (state change or loss for parents).
    *   `refineParticle(uint256 tokenId)`: Attempts to refine a particle, potentially increasing stability or altering attributes based on random chance and state.
    *   `triggerMutation(uint256 tokenId)`: Attempts to force a mutation in a particle's type or attributes.
    *   `stabilizeParticle(uint256 tokenId)`: Attempts to move a particle to a `Stable` state, consuming resources or meeting conditions.
    *   `applyCatalyst(uint256 tokenId, uint256 catalystId)`: Applies a simulated "catalyst" to a particle, triggering an effect defined by `catalystId`.
    *   `entangleParticles(uint256 tokenId1, uint256 tokenId2)`: Attempts to create an entangled link between two particles (caller must own both).

4.  **Particle Information & State Query (5 functions):**
    *   `getParticleSnapshot(uint256 tokenId)`: View function returning a snapshot of a particle's current details (struct).
    *   `getParticleState(uint256 tokenId)`: View function returning only the `QuantumState` of a particle.
    *   `getParticleHistory(uint256 tokenId)`: View function returning parent IDs and generation.
    *   `queryEntanglementStatus(uint256 tokenId1, uint256 tokenId2)`: View function checking if two particles are currently entangled.
    *   `simulateInteraction(uint256 tokenId1, uint256 tokenId2, bytes32 interactionType)`: View function simulating the outcome of a potential action (e.g., fusion) without executing it, based on current states.

5.  **System Configuration & Control (7 functions):**
    *   `setFusionParams(uint256 successRateNumerator, uint256 successRateDenominator, uint256 failureStateChangeLikelihood)`: Owner function to set fusion outcome parameters.
    *   `setDecayRate(uint64 newDecayRate)`: Owner function to set the decay rate (e.g., time units per state degradation).
    *   `setCatalystEffect(uint256 catalystId, int256 stabilityModifier, int256 chargeModifier, uint256 mutationChance)`: Owner function to define effects of catalysts.
    *   `getCatalystEffect(uint256 catalystId)`: View function to get catalyst effect parameters.
    *   `pauseContract()`: Owner function to pause contract functionality.
    *   `unpauseContract()`: Owner function to unpause contract functionality.
    *   `withdrawAnyBalance(address recipient)`: Owner function to withdraw any accumulated ETH (or other tokens) from the contract.

6.  **Utility (1 function):**
    *   `contractVersion()`: View function returning the contract version string.

**Total Function Count:** 9 (ERC721) + 2 (Minting) + 6 (Actions) + 5 (Info) + 7 (Config) + 1 (Utility) = **30 Functions**.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max/random-like scaling
import "@openzeppelin/contracts/utils/Context.sol"; // For _msgSender()

/// @title QuantumFusion
/// @dev An ERC721 contract representing dynamic "Quantum Particles" that can be fused,
/// refined, mutated, and change state based on simulated quantum principles.
contract QuantumFusion is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Error Definitions ---
    error InvalidParticleId();
    error NotParticleOwner();
    error FusionFailed(string reason);
    error InvalidParticleState(QuantumState currentState, string actionRequired);
    error AlreadyEntangled();
    error NotEnoughStability();
    error InvalidCatalyst();
    error CannotEntangleSelf();
    error AlreadyStable();
    error NotInSuperposedState();

    // --- Enums ---
    enum ParticleType {
        Undefined,
        Elementary, // Basic building blocks
        Composite,  // Fused from Elementary
        Exotic,     // Rare, high stability/charge
        Decayed     // Unstable, low utility
    }

    enum QuantumState {
        Undefined,
        Superposed, // Initial or uncertain state, can collapse
        Stable,     // Resistant to change, high stability
        Entangled,  // Linked to another particle
        Mutating,   // Undergoing transformation
        Decaying,   // Losing stability over time
        Fusing      // Currently involved in a fusion process
    }

    // --- Structs ---
    struct Particle {
        uint64 creationTime;
        uint64 lastUpdateTime;
        ParticleType particleType;
        int256 charge;      // Can be positive, negative, or zero
        uint256 stability;  // Higher stability resists decay/mutation, aids fusion
        QuantumState quantumState;
        uint256 generation; // 0 for initial, increases with fusion
        uint256 parent1Id;  // 0 for initial particles
        uint256 parent2Id;  // 0 for initial particles
        // Could add more attributes like color, frequency, spin, etc.
    }

    struct FusionParameters {
        uint256 successRateNumerator;   // N / D chance of success
        uint256 successRateDenominator;
        uint256 failureStateChangeLikelihood; // N / D chance of state change on failure
        uint256 minStabilityForFusion;
        uint256 maxGenerationDifference; // Max diff allowed between parents
    }

    struct CatalystEffect {
        int256 stabilityModifier; // Amount added/subtracted
        int256 chargeModifier;    // Amount added/subtracted
        uint256 mutationChance;   // N / 10000 chance of mutation
        uint64 stateChangeDuration; // How long a state change might last
    }

    // --- State Variables ---
    mapping(uint256 => Particle) public particles;
    mapping(uint256 => uint256) private _entangledPairs; // tokenId1 => tokenId2, and tokenId2 => tokenId1
    mapping(uint256 => CatalystEffect) private _catalystEffects;

    FusionParameters public fusionParameters;
    uint64 public decayRate = 86400; // Default decay rate: 1 stability per day (adjust units)

    // --- Events ---
    event ParticleMinted(uint256 indexed tokenId, address indexed owner, ParticleType particleType, uint256 generation);
    event ParticlesFused(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed newParticleId, address indexed owner, bool success);
    event ParticleRefined(uint256 indexed tokenId, address indexed owner, bool success, string message);
    event ParticleMutated(uint256 indexed tokenId, address indexed owner, ParticleType oldType, ParticleType newType);
    event ParticleStateChanged(uint256 indexed tokenId, QuantumState oldState, QuantumState newState);
    event ParticlesEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EntanglementBroken(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event CatalystApplied(uint256 indexed tokenId, uint256 indexed catalystId, address indexed owner);
    event ParticleDecayed(uint256 indexed tokenId, uint256 newStability, QuantumState newState);

    // --- Constructor ---
    constructor() ERC721("QuantumFusionParticle", "QFP") Ownable(msg.sender) Pausable(false) {
        // Set initial default fusion parameters
        fusionParameters = FusionParameters({
            successRateNumerator: 60,
            successRateDenominator: 100, // 60% base success rate
            failureStateChangeLikelihood: 30, // 30% chance of state change on failure
            minStabilityForFusion: 10,
            maxGenerationDifference: 2
        });
    }

    // --- Modifiers ---
    modifier whenNotPaused() override {
        super.whenNotPaused();
    }

    modifier whenPaused() override {
        super.whenPaused();
    }

    // --- Internal/Helper Functions ---

    /// @dev Generates a pseudo-random seed using block data and transaction details.
    /// WARNING: This is NOT cryptographically secure and should not be used for
    /// high-value outcomes where manipulation is possible (e.g., front-running).
    /// It is suitable for demonstrating variable outcomes in a conceptual model.
    function _generatePseudoRandomSeed() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            block.number,
            gasleft(),
            _msgSender(),
            _tokenIdCounter.current(), // Include a counter for more entropy per mint/action
            particles[(_tokenIdCounter.current() > 0 ? _tokenIdCounter.current() - 1 : 0)].stability // Mix in some state
        )));
    }

    /// @dev Internal function to update a particle's state based on time and rules.
    /// This might be called before any action involving the particle.
    function _updateParticleState(uint256 tokenId) internal {
        Particle storage particle = particles[tokenId];
        uint64 currentTime = uint64(block.timestamp);

        // Decay simulation
        if (particle.quantumState != QuantumState.Stable && particle.quantumState != QuantumState.Decayed) {
            uint64 timeElapsed = currentTime - particle.lastUpdateTime;
            if (timeElapsed > 0 && decayRate > 0) {
                uint256 stabilityLoss = timeElapsed / decayRate;
                if (stabilityLoss > 0) {
                     // Ensure stability doesn't go below zero in uint
                    particle.stability = particle.stability > stabilityLoss ? particle.stability - stabilityLoss : 0;
                    particle.lastUpdateTime = currentTime;

                    if (particle.stability == 0 && particle.quantumState != QuantumState.Decaying) {
                        emit ParticleStateChanged(tokenId, particle.quantumState, QuantumState.Decaying);
                        particle.quantumState = QuantumState.Decaying;
                    } else if (particle.stability > 0 && particle.quantumState == QuantumState.Decaying) {
                         // Could potentially recover from Decaying if stability is added back
                         // For now, Decaying is often a terminal state unless stabilized
                    }
                    emit ParticleDecayed(tokenId, particle.stability, particle.quantumState);
                }
            }
        }

        // Handle state transitions based on time or conditions (e.g., mutation duration ends)
        // This is a simplified example; complex state machines would require more logic
        if (particle.quantumState == QuantumState.Mutating && currentTime >= particle.lastUpdateTime + 7 days) { // Example: Mutation takes 7 days
             particle.quantumState = QuantumState.Superposed; // Return to uncertain state after mutation period
             emit ParticleStateChanged(tokenId, QuantumState.Mutating, QuantumState.Superposed);
        }
         if (particle.quantumState == QuantumState.Fusing && currentTime >= particle.lastUpdateTime + 1 hours) { // Example: Fusion state timeout
             // This state implies it was *involved* in fusion. If the fusion transaction failed or timed out,
             // the state might revert or become Decaying depending on rules. Let's just revert to Superposed for simplicity here.
             particle.quantumState = QuantumState.Superposed;
             emit ParticleStateChanged(tokenId, QuantumState.Fusing, QuantumState.Superposed);
         }


        // Update last update time if any state change or decay occurred (handled above)
        particle.lastUpdateTime = currentTime; // Ensure this is updated even if no decay happens but time elapsed
    }

    /// @dev Internal helper to check and potentially update particle states before interaction.
    function _prepareParticlesForInteraction(uint256 tokenId1, uint256 tokenId2) internal {
        _updateParticleState(tokenId1);
        _updateParticleState(tokenId2);

        Particle storage p1 = particles[tokenId1];
        Particle storage p2 = particles[tokenId2];

         // Break entanglement if either particle is involved in a new action
        if (p1.quantumState == QuantumState.Entangled || p2.quantumState == QuantumState.Entangled) {
            uint256 entangledWith1 = _entangledPairs[tokenId1];
            uint256 entangledWith2 = _entangledPairs[tokenId2];

            if (entangledWith1 != 0 && entangledWith1 != tokenId2) _breakEntanglement(tokenId1, entangledWith1);
            if (entangledWith2 != 0 && entangledWith2 != tokenId1) _breakEntanglement(tokenId2, entangledWith2);
        }
    }


    /// @dev Internal function to handle the outcome logic of fusion.
    function _performFusionLogic(uint256 parent1Id, uint256 parent2Id) internal returns (bool success) {
        Particle storage p1 = particles[parent1Id];
        Particle storage p2 = particles[parent2Id];

        // Basic checks (already done in fuseParticles, but good practice for internal logic)
        if (p1.stability < fusionParameters.minStabilityForFusion || p2.stability < fusionParameters.minStabilityForFusion) {
             revert FusionFailed("Insufficient stability");
        }
         if (Math.absolute(int256(p1.generation) - int256(p2.generation)) > int256(fusionParameters.maxGenerationDifference)) {
             revert FusionFailed("Generation difference too large");
         }

        // Pseudo-randomness for outcome
        uint256 seed = _generatePseudoRandomSeed();
        uint256 outcomeRoll = seed % fusionParameters.successRateDenominator;

        success = outcomeRoll < fusionParameters.successRateNumerator;

        if (success) {
            // --- Successful Fusion ---
            // Determine new particle properties (simplified logic)
            ParticleType newType;
            if (p1.particleType == ParticleType.Elementary && p2.particleType == ParticleType.Elementary) {
                newType = ParticleType.Composite;
            } else if (p1.particleType == ParticleType.Composite && p2.particleType == ParticleType.Composite) {
                 newType = ParticleType.Exotic; // Simplified chance of Exotic
            } else if (p1.particleType == ParticleType.Exotic || p2.particleType == ParticleType.Exotic) {
                 newType = ParticleType.Exotic;
            }
             else {
                newType = ParticleType.Composite; // Default composite
            }

            int256 newCharge = p1.charge + p2.charge;
            uint256 newStability = (p1.stability + p2.stability) / 2 + 10; // Average + bonus
             newStability = Math.min(newStability, type(uint256).max - 1000); // Cap stability to avoid overflow issues in potential future calcs


            uint256 newGeneration = Math.max(p1.generation, p2.generation) + 1;

            // Burn parents
            _burn(parent1Id);
            _burn(parent2Id);

            // Mint new particle
            _tokenIdCounter.increment();
            uint256 newTokenId = _tokenIdCounter.current();
            address owner = ownerOf(parent1Id); // Owner of parent1 is the owner of the result

            particles[newTokenId] = Particle({
                creationTime: uint64(block.timestamp),
                lastUpdateTime: uint64(block.timestamp),
                particleType: newType,
                charge: newCharge,
                stability: newStability,
                quantumState: QuantumState.Superposed, // New particles start Superposed
                generation: newGeneration,
                parent1Id: parent1Id,
                parent2Id: parent2Id
            });

            _safeMint(owner, newTokenId);
            emit ParticleMinted(newTokenId, owner, newType, newGeneration);
            emit ParticlesFused(parent1Id, parent2Id, newTokenId, owner, true);

        } else {
            // --- Fusion Failure ---
            // Apply consequences: Reduce stability, change state
            p1.stability = p1.stability > 10 ? p1.stability - 10 : 0;
            p2.stability = p2.stability > 10 ? p2.stability - 10 : 0;

            uint256 stateChangeRoll = seed % fusionParameters.failureStateChangeLikelihood; // Simplified check
            if (stateChangeRoll == 0) { // Small chance of state change on failure
                 emit ParticleStateChanged(parent1Id, p1.quantumState, QuantumState.Decaying);
                 p1.quantumState = QuantumState.Decaying;
                 emit ParticleStateChanged(parent2Id, p2.quantumState, QuantumState.Decaying);
                 p2.quantumState = QuantumState.Decaying;
            }

            emit ParticlesFused(parent1Id, parent2Id, 0, ownerOf(parent1Id), false); // New ID 0 signals failure
            revert FusionFailed("Fusion attempt failed, particles may have lost stability or changed state.");
        }

        return success;
    }

    /// @dev Internal function to break an entanglement bond.
    function _breakEntanglement(uint256 tokenId1, uint256 tokenId2) internal {
        delete _entangledPairs[tokenId1];
        delete _entangledPairs[tokenId2];
        emit EntanglementBroken(tokenId1, tokenId2);

        // State change for entangled particles when link is broken
        Particle storage p1 = particles[tokenId1];
        Particle storage p2 = particles[tokenId2];
        if (p1.quantumState == QuantumState.Entangled) {
             p1.quantumState = QuantumState.Superposed; // Revert to uncertain state
             emit ParticleStateChanged(tokenId1, QuantumState.Entangled, QuantumState.Superposed);
        }
         if (p2.quantumState == QuantumState.Entangled) {
             p2.quantumState = QuantumState.Superposed; // Revert to uncertain state
             emit ParticleStateChanged(tokenId2, QuantumState.Entangled, QuantumState.Superposed);
         }
    }


    /// @dev Override to handle state updates before transfers and clear entanglement.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // If transferring, it potentially breaks entanglement
        uint256 entangledWith = _entangledPairs[tokenId];
        if (entangledWith != 0) {
            _breakEntanglement(tokenId, entangledWith);
        }

        // Optional: Update state on transfer if needed, though calling before every action is often sufficient
        // _updateParticleState(tokenId);
    }


    // --- ERC721 Standard Implementations ---
    // Standard functions are provided by inheriting ERC721 from OpenZeppelin
    // We only need to override if we add custom logic, like _beforeTokenTransfer above
    // For completeness, listing them here as per the requirement count:
    // 1. balanceOf(address owner) inherited
    // 2. ownerOf(uint256 tokenId) inherited
    // 3. safeTransferFrom(address from, address to, uint256 tokenId) inherited
    // 4. transferFrom(address from, address to, uint256 tokenId) inherited
    // 5. approve(address to, uint256 tokenId) inherited
    // 6. setApprovalForAll(address operator, bool approved) inherited
    // 7. getApproved(uint256 tokenId) inherited
    // 8. isApprovedForAll(address owner, address operator) inherited
    // 9. supportsInterface(bytes4 interfaceId) inherited (requires overriding only if custom interfaces are added)
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    // --- Particle Creation & Minting ---

    /// @dev Mints initial particles of a specific type. Only callable by owner.
    /// These represent particles that were not created by fusion.
    /// @param owner The address to mint tokens to.
    /// @param initialType The type of particle to mint (e.g., Elementary).
    /// @param count The number of particles to mint.
    function mintInitialParticles(address owner, ParticleType initialType, uint256 count) external onlyOwner whenNotPaused {
        require(initialType != ParticleType.Undefined && initialType != ParticleType.Composite && initialType != ParticleType.Exotic && initialType != ParticleType.Decayed, "Invalid initial type");

        uint64 currentTime = uint64(block.timestamp);
        for (uint i = 0; i < count; i++) {
            _tokenIdCounter.increment();
            uint256 newItemId = _tokenIdCounter.current();

            particles[newItemId] = Particle({
                creationTime: currentTime,
                lastUpdateTime: currentTime,
                particleType: initialType,
                charge: 0, // Initial particles start neutral
                stability: 50, // Base stability
                quantumState: QuantumState.Superposed, // Initial particles start Superposed
                generation: 0,
                parent1Id: 0,
                parent2Id: 0
            });

            _safeMint(owner, newItemId);
            emit ParticleMinted(newItemId, owner, initialType, 0);
        }
    }

    // --- Particle Actions & Interactions ---

    /// @dev Attempts to fuse two Quantum Particles. The caller must own both.
    /// Success leads to burning parents and minting a new particle. Failure leads to penalties.
    /// Requires particles to be in a suitable state.
    /// @param tokenId1 The ID of the first particle.
    /// @param tokenId2 The ID of the second particle.
    function fuseParticles(uint256 tokenId1, uint256 tokenId2) external whenNotPaused {
        require(_exists(tokenId1), InvalidParticleId());
        require(_exists(tokenId2), InvalidParticleId());
        require(tokenId1 != tokenId2, "Cannot fuse a particle with itself");
        require(ownerOf(tokenId1) == _msgSender(), NotParticleOwner());
        require(ownerOf(tokenId2) == _msgSender(), "Caller does not own particle 2");

        _prepareParticlesForInteraction(tokenId1, tokenId2);

        Particle storage p1 = particles[tokenId1];
        Particle storage p2 = particles[tokenId2];

        // Basic state checks for fusion eligibility
        require(p1.quantumState != QuantumState.Decayed && p1.quantumState != QuantumState.Decaying && p1.quantumState != QuantumState.Fusing,
            InvalidParticleState(p1.quantumState, "Cannot fuse a particle that is Decayed, Decaying, or already Fusing"));
        require(p2.quantumState != QuantumState.Decayed && p2.quantumState != QuantumState.Decaying && p2.quantumState != QuantumState.Fusing,
            InvalidParticleState(p2.quantumState, "Cannot fuse a particle that is Decayed, Decaying, or already Fusing"));

        // Set state to Fusing temporarily (helps prevent double-spend/re-entrancy issues in complex systems)
        emit ParticleStateChanged(tokenId1, p1.quantumState, QuantumState.Fusing);
        p1.quantumState = QuantumState.Fusing;
        emit ParticleStateChanged(tokenId2, p2.quantumState, QuantumState.Fusing);
        p2.quantumState = QuantumState.Fusing;

        // Perform the core fusion logic
        bool success = _performFusionLogic(tokenId1, tokenId2);

        // States are handled by _performFusionLogic (burns on success, state change on failure)
        // If execution reaches here without reverting, fusion must have succeeded and parents were burned.
    }

    /// @dev Attempts to refine a single particle, increasing its stability. Chance-based.
    /// Requires particle to be in a suitable state.
    /// @param tokenId The ID of the particle to refine.
    function refineParticle(uint256 tokenId) external whenNotPaused {
        require(_exists(tokenId), InvalidParticleId());
        require(ownerOf(tokenId) == _msgSender(), NotParticleOwner());

         _updateParticleState(tokenId);
         Particle storage particle = particles[tokenId];

         require(particle.quantumState != QuantumState.Decayed && particle.quantumState != QuantumState.Decaying && particle.quantumState != QuantumState.Fusing,
            InvalidParticleState(particle.quantumState, "Cannot refine a particle that is Decayed, Decaying, or Fusing"));
        require(particle.stability < 100, "Particle is already highly stable"); // Cap refinement

        uint256 seed = _generatePseudoRandomSeed();
        uint256 successRoll = seed % 100; // 1 in 100 chance base success

        bool success = successRoll < (particle.stability / 2 + 10); // Stability improves success chance

        if (success) {
            particle.stability = Math.min(particle.stability + 5 + (seed % 5), 100); // Increase stability, max 100
            emit ParticleRefined(tokenId, _msgSender(), true, "Refinement successful, stability increased.");
        } else {
            // Small chance of penalty on failure
            uint256 penaltyRoll = seed % 10;
            if (penaltyRoll == 0) {
                 particle.stability = particle.stability > 1 ? particle.stability - 1 : 0;
                 if (particle.stability == 0 && particle.quantumState != QuantumState.Decaying) {
                      emit ParticleStateChanged(tokenId, particle.quantumState, QuantumState.Decaying);
                      particle.quantumState = QuantumState.Decaying;
                 }
                 emit ParticleRefined(tokenId, _msgSender(), false, "Refinement failed, particle lost a small amount of stability.");
            } else {
                 emit ParticleRefined(tokenId, _msgSender(), false, "Refinement failed.");
            }
        }
         particle.lastUpdateTime = uint64(block.timestamp); // Update timestamp after action
    }

    /// @dev Attempts to trigger a mutation in a particle's type. Chance-based.
    /// Requires particle to be in a suitable state (e.g., Superposed or Mutating).
    /// @param tokenId The ID of the particle to mutate.
    function triggerMutation(uint256 tokenId) external whenNotPaused {
        require(_exists(tokenId), InvalidParticleId());
        require(ownerOf(tokenId) == _msgSender(), NotParticleOwner());

        _updateParticleState(tokenId);
        Particle storage particle = particles[tokenId];

        require(particle.quantumState == QuantumState.Superposed || particle.quantumState == QuantumState.Mutating,
             InvalidParticleState(particle.quantumState, "Particle must be Superposed or already Mutating to trigger mutation"));
        require(particle.quantumState != QuantumState.Decayed && particle.quantumState != QuantumState.Decaying && particle.quantumState != QuantumState.Stable,
            InvalidParticleState(particle.quantumState, "Cannot mutate a particle that is Decayed, Decaying, or Stable"));


        uint256 seed = _generatePseudoRandomSeed();
        uint256 mutationRoll = seed % 100; // Base 1% chance

        // Stability *reduces* mutation chance
        bool success = mutationRoll < (100 - particle.stability);

        if (success) {
            ParticleType oldType = particle.particleType;
            // Simplified mutation logic: Cycle through types or jump randomly
            if (particle.particleType == ParticleType.Elementary) particle.particleType = ParticleType.Composite;
            else if (particle.particleType == ParticleType.Composite) particle.particleType = ParticleType.Exotic;
            else if (particle.particleType == ParticleType.Exotic) particle.particleType = ParticleType.Decayed; // Exotic can decay unexpectedly
            else particle.particleType = ParticleType.Superposed; // Unlikely states might revert

            emit ParticleMutated(tokenId, _msgSender(), oldType, particle.particleType);
            emit ParticleStateChanged(tokenId, particle.quantumState, QuantumState.Mutating);
            particle.quantumState = QuantumState.Mutating; // Enters mutation state for a duration
            particle.lastUpdateTime = uint64(block.timestamp); // Reset timer for mutation state duration

        } else {
             // Failed mutation attempt might increase stability slightly or change state
             particle.stability = Math.min(particle.stability + 1, 100);
             if (mutationRoll < 5) { // Small chance of state change on failure
                emit ParticleStateChanged(tokenId, particle.quantumState, QuantumState.Decaying);
                 particle.quantumState = QuantumState.Decaying;
             }
            particle.lastUpdateTime = uint64(block.timestamp);
        }
    }

    /// @dev Attempts to change a particle's state to Stable. Requires sufficient stability.
    /// Consumes stability in the process.
    /// @param tokenId The ID of the particle to stabilize.
    function stabilizeParticle(uint256 tokenId) external whenNotPaused {
        require(_exists(tokenId), InvalidParticleId());
        require(ownerOf(tokenId) == _msgSender(), NotParticleOwner());

        _updateParticleState(tokenId);
        Particle storage particle = particles[tokenId];

        require(particle.quantumState != QuantumState.Decayed && particle.quantumState != QuantumState.Stable,
            InvalidParticleState(particle.quantumState, "Particle must not be Decayed or already Stable"));
        require(particle.stability >= 75, NotEnoughStability()); // Requires high stability to enter Stable state

        uint256 stabilityCost = particle.stability / 3; // Cost is relative to current stability
        particle.stability -= stabilityCost; // Consume stability

        QuantumState oldState = particle.quantumState;
        particle.quantumState = QuantumState.Stable;
        particle.lastUpdateTime = uint64(block.timestamp);

        emit ParticleStateChanged(tokenId, oldState, QuantumState.Stable);
    }

    /// @dev Applies a simulated "catalyst" to a particle, altering its attributes based on the catalyst type.
    /// Requires particle to be in a suitable state.
    /// @param tokenId The ID of the particle.
    /// @param catalystId The ID of the catalyst being applied.
    function applyCatalyst(uint256 tokenId, uint256 catalystId) external whenNotPaused {
        require(_exists(tokenId), InvalidParticleId());
        require(ownerOf(tokenId) == _msgSender(), NotParticleOwner());

        _updateParticleState(tokenId);
        Particle storage particle = particles[tokenId];

        require(particle.quantumState != QuantumState.Decayed && particle.quantumState != QuantumState.Fusing,
             InvalidParticleState(particle.quantumState, "Cannot apply catalyst to a particle that is Decayed or Fusing"));

        CatalystEffect memory effect = _catalystEffects[catalystId];
        require(effect.stabilityModifier != 0 || effect.chargeModifier != 0 || effect.mutationChance != 0, InvalidCatalyst());

        // Apply effects
        particle.stability = effect.stabilityModifier >= 0 ?
                             Math.min(particle.stability + uint256(effect.stabilityModifier), 100) : // Cap stability at 100
                             (particle.stability > uint256(-effect.stabilityModifier) ? particle.stability - uint256(-effect.stabilityModifier) : 0);

        particle.charge += effect.chargeModifier;

        // Apply mutation chance if applicable
        if (effect.mutationChance > 0 && particle.quantumState != QuantumState.Stable && particle.quantumState != QuantumState.Decayed) {
             uint256 seed = _generatePseudoRandomSeed();
             if (seed % 10000 < effect.mutationChance) {
                 ParticleType oldType = particle.particleType;
                 // Simplified mutation based on effect (e.g., positive charge catalyst might push towards Exotic)
                 if (effect.chargeModifier > 0 && particle.particleType != ParticleType.Exotic) particle.particleType = ParticleType.Exotic;
                 else if (effect.chargeModifier < 0 && particle.particleType != ParticleType.Decayed) particle.particleType = ParticleType.Decayed;
                 else if (particle.particleType == ParticleType.Elementary) particle.particleType = ParticleType.Composite; // Default shift
                 else particle.particleType = ParticleType.Superposed; // Catch-all

                 emit ParticleMutated(tokenId, _msgSender(), oldType, particle.particleType);
                 emit ParticleStateChanged(tokenId, particle.quantumState, QuantumState.Mutating);
                 particle.quantumState = QuantumState.Mutating; // Enters mutation state
                 particle.lastUpdateTime = uint64(block.timestamp); // Reset timer
             }
        }

        // Handle potential state changes based on catalyst effect duration or type
        if (effect.stateChangeDuration > 0 && particle.quantumState != QuantumState.Stable && particle.quantumState != QuantumState.Decayed) {
             emit ParticleStateChanged(tokenId, particle.quantumState, QuantumState.Mutating); // Or another catalyst-specific state
             particle.quantumState = QuantumState.Mutating; // Example: Catalyst forces a temporary state
             particle.lastUpdateTime = uint64(block.timestamp); // Start timer for state duration
        }

        particle.lastUpdateTime = uint64(block.timestamp); // Ensure timestamp is updated
        emit CatalystApplied(tokenId, catalystId, _msgSender());
    }

    /// @dev Attempts to entangle two particles. Requires caller to own both.
    /// Particles must be in a suitable state (e.g., Superposed).
    /// @param tokenId1 The ID of the first particle.
    /// @param tokenId2 The ID of the second particle.
    function entangleParticles(uint256 tokenId1, uint256 tokenId2) external whenNotPaused {
        require(_exists(tokenId1), InvalidParticleId());
        require(_exists(tokenId2), InvalidParticleId());
        require(tokenId1 != tokenId2, CannotEntangleSelf());
        require(ownerOf(tokenId1) == _msgSender(), NotParticleOwner());
        require(ownerOf(tokenId2) == _msgSender(), "Caller does not own particle 2");

        _prepareParticlesForInteraction(tokenId1, tokenId2); // Updates states and breaks existing entanglement

        Particle storage p1 = particles[tokenId1];
        Particle storage p2 = particles[tokenId2];

        require(p1.quantumState == QuantumState.Superposed, InvalidParticleState(p1.quantumState, "Particle 1 must be Superposed to entangle"));
        require(p2.quantumState == QuantumState.Superposed, InvalidParticleState(p2.quantumState, "Particle 2 must be Superposed to entangle"));
        require(_entangledPairs[tokenId1] == 0 && _entangledPairs[tokenId2] == 0, AlreadyEntangled());


        // Success is automatic if conditions met (simplified)
        _entangledPairs[tokenId1] = tokenId2;
        _entangledPairs[tokenId2] = tokenId1;

        emit ParticleStateChanged(tokenId1, p1.quantumState, QuantumState.Entangled);
        p1.quantumState = QuantumState.Entangled;
         emit ParticleStateChanged(tokenId2, p2.quantumState, QuantumState.Entangled);
        p2.quantumState = QuantumState.Entangled;

        p1.lastUpdateTime = uint64(block.timestamp);
        p2.lastUpdateTime = uint64(block.timestamp);

        emit ParticlesEntangled(tokenId1, tokenId2);
    }

    /// @dev Forces a Superposed particle to collapse into a definite state (Stable or Decaying) based on randomness.
    /// Breaks entanglement if applicable.
    /// @param tokenId The ID of the particle.
    function collapseSuperposition(uint256 tokenId) external whenNotPaused {
        require(_exists(tokenId), InvalidParticleId());
        require(ownerOf(tokenId) == _msgSender(), NotParticleOwner());

        _updateParticleState(tokenId);
        Particle storage particle = particles[tokenId];

        require(particle.quantumState == QuantumState.Superposed, NotInSuperposedState());

        // Break entanglement if it somehow got into superposition while entangled (shouldn't happen with current logic, but safety)
         uint256 entangledWith = _entangledPairs[tokenId];
         if (entangledWith != 0) {
             _breakEntanglement(tokenId, entangledWith);
         }

        uint256 seed = _generatePseudoRandomSeed();
        uint256 collapseRoll = seed % 100;

        QuantumState oldState = particle.quantumState;

        // Collapse outcome depends on stability
        if (collapseRoll < particle.stability) {
            particle.quantumState = QuantumState.Stable; // Collapse to Stable
            particle.stability = Math.min(particle.stability + 10, 100); // Bonus stability for collapsing Stable
        } else {
            particle.quantumState = QuantumState.Decaying; // Collapse to Decaying
             particle.stability = particle.stability > 20 ? particle.stability - 20 : 0; // Penalty for collapsing Decaying
        }

        particle.lastUpdateTime = uint64(block.timestamp);
        emit ParticleStateChanged(tokenId, oldState, particle.quantumState);
    }

     /// @dev Extracts "energy" from a particle, reducing its stability significantly.
     /// If stability drops to zero, the particle becomes Decayed.
     /// @param tokenId The ID of the particle.
     /// @param amount The amount of stability to attempt to extract (clamped).
     function extractEnergy(uint256 tokenId, uint256 amount) external whenNotPaused {
         require(_exists(tokenId), InvalidParticleId());
         require(ownerOf(tokenId) == _msgSender(), NotParticleOwner());
         require(amount > 0, "Extraction amount must be positive");

         _updateParticleState(tokenId);
         Particle storage particle = particles[tokenId];

         require(particle.quantumState != QuantumState.Decayed, InvalidParticleState(particle.quantumState, "Cannot extract energy from a Decayed particle"));
         require(particle.stability > 0, NotEnoughStability());

         uint256 actualAmount = Math.min(amount, particle.stability);
         particle.stability -= actualAmount;

         QuantumState oldState = particle.quantumState;
         if (particle.stability == 0) {
             emit ParticleStateChanged(tokenId, oldState, QuantumState.Decayed);
             particle.quantumState = QuantumState.Decayed; // Terminal state
             // Could potentially burn the token here depending on game design
         } else if (oldState == QuantumState.Stable && particle.stability < 75) {
              // If was Stable and now below threshold, revert to Superposed or Decaying
              if (particle.stability > 10) { // If still some stability left
                 emit ParticleStateChanged(tokenId, oldState, QuantumState.Superposed);
                 particle.quantumState = QuantumState.Superposed;
              } else { // Very low stability
                 emit ParticleStateChanged(tokenId, oldState, QuantumState.Decaying);
                 particle.quantumState = QuantumState.Decaying;
              }
         }


         particle.lastUpdateTime = uint64(block.timestamp);
         // Could emit an event for energy extraction
     }


    // --- Particle Information & State Query ---

    /// @dev Gets a snapshot of a particle's current details.
    /// Triggers state update based on time before returning.
    /// @param tokenId The ID of the particle.
    /// @return The Particle struct data.
    function getParticleSnapshot(uint256 tokenId) public view returns (Particle memory) {
        require(_exists(tokenId), InvalidParticleId());
         // Note: View functions cannot modify state, so _updateParticleState cannot be called here.
         // The data returned reflects the last recorded state, not the state *right now* including decay.
         // A getter that allows state changes would need to be non-view.
         // For a more accurate view of decay, client-side calculation based on lastUpdateTime and decayRate is needed.
        return particles[tokenId];
    }

    /// @dev Gets the current quantum state of a particle.
    /// @param tokenId The ID of the particle.
    /// @return The QuantumState enum value.
    function getParticleState(uint256 tokenId) public view returns (QuantumState) {
        require(_exists(tokenId), InvalidParticleId());
         // Similar limitation to getParticleSnapshot regarding decay calculation in view function.
        return particles[tokenId].quantumState;
    }

    /// @dev Gets the history of a particle's creation (parents and generation).
    /// @param tokenId The ID of the particle.
    /// @return parent1Id The ID of the first parent (0 if initial).
    /// @return parent2Id The ID of the second parent (0 if initial).
    /// @return generation The generation number (0 if initial).
    function getParticleHistory(uint256 tokenId) public view returns (uint256 parent1Id, uint256 parent2Id, uint256 generation) {
        require(_exists(tokenId), InvalidParticleId());
        Particle storage particle = particles[tokenId];
        return (particle.parent1Id, particle.parent2Id, particle.generation);
    }

    /// @dev Checks if two specific particles are currently entangled.
    /// @param tokenId1 The ID of the first particle.
    /// @param tokenId2 The ID of the second particle.
    /// @return True if the particles are entangled with each other, false otherwise.
    function queryEntanglementStatus(uint256 tokenId1, uint256 tokenId2) public view returns (bool) {
        require(_exists(tokenId1), InvalidParticleId());
        require(_exists(tokenId2), InvalidParticleId());
        if (tokenId1 == tokenId2) return false; // A particle cannot be entangled with itself
        return _entangledPairs[tokenId1] == tokenId2 && _entangledPairs[tokenId2] == tokenId1;
    }

    /// @dev Simulates the outcome of a potential interaction (e.g., fusion) without executing it.
    /// This is a view function and does not change contract state.
    /// The simulation logic is simplified for demonstration.
    /// @param tokenId1 The ID of the first particle for simulation.
    /// @param tokenId2 The ID of the second particle for simulation.
    /// @param interactionType A bytes32 identifier for the type of interaction (e.g., "FUSION").
    /// @return A string describing the simulated outcome.
    function simulateInteraction(uint256 tokenId1, uint256 tokenId2, bytes32 interactionType) public view returns (string memory) {
        require(_exists(tokenId1), InvalidParticleId());
        require(_exists(tokenId2), InvalidParticleId());

        if (interactionType == "FUSION") {
            Particle storage p1 = particles[tokenId1];
            Particle storage p2 = particles[tokenId2];

            if (p1.stability < fusionParameters.minStabilityForFusion || p2.stability < fusionParameters.minStabilityForFusion) {
                return "Simulation: Fusion would likely fail due to low stability.";
            }
            if (Math.absolute(int256(p1.generation) - int256(p2.generation)) > int256(fusionParameters.maxGenerationDifference)) {
                 return "Simulation: Fusion would likely fail due to generation difference.";
            }

            // Simulate randomness based on properties (cannot use block.timestamp/difficulty reliably in view)
            // Use particle properties as a pseudo-deterministic seed for simulation
            uint256 simulationSeed = uint256(keccak256(abi.encodePacked(
                p1.stability, p2.stability, p1.charge, p2.charge, p1.generation, p2.generation, tokenId1, tokenId2
            )));

            uint256 outcomeRoll = simulationSeed % fusionParameters.successRateDenominator;

            if (outcomeRoll < fusionParameters.successRateNumerator) {
                 // Simulate new particle properties
                ParticleType newType;
                if (p1.particleType == ParticleType.Elementary && p2.particleType == ParticleType.Elementary) newType = ParticleType.Composite;
                else if (p1.particleType == ParticleType.Composite && p2.particleType == ParticleType.Composite) newType = ParticleType.Exotic;
                else newType = ParticleType.Composite;

                int256 newCharge = p1.charge + p2.charge;
                uint256 newStability = (p1.stability + p2.stability) / 2 + 10;
                uint256 newGeneration = Math.max(p1.generation, p2.generation) + 1;

                string memory outcome = string(abi.encodePacked(
                    "Simulation: Fusion likely succeeds. Resulting particle: Type ",
                    _particleTypeToString(newType),
                    ", Charge ",
                    _int256ToString(newCharge),
                    ", Stability ",
                    _uint256ToString(newStability),
                    ", Generation ",
                    _uint256ToString(newGeneration),
                    "."
                ));
                 return outcome;

            } else {
                 return "Simulation: Fusion likely fails. Parents may lose stability or change state.";
            }
        }
        // Add more interaction types here (e.g., "REFINEMENT", "MUTATION")
        else {
            return "Simulation: Unknown interaction type.";
        }
    }

    // --- System Configuration & Control ---

    /// @dev Owner sets the fusion parameters.
    /// @param successRateNumerator Numerator for success chance (N/D).
    /// @param successRateDenominator Denominator for success chance (N/D).
    /// @param failureStateChangeLikelihood Numerator for state change chance on failure (N/D).
    /// @param minStabilityForFusion Minimum stability required for each parent.
    /// @param maxGenerationDifference Maximum allowed generation difference between parents.
    function setFusionParams(
        uint256 successRateNumerator,
        uint256 successRateDenominator,
        uint256 failureStateChangeLikelihood,
        uint256 minStabilityForFusion,
        uint256 maxGenerationDifference
    ) external onlyOwner {
        require(successRateDenominator > 0, "Denominator cannot be zero");
        require(successRateNumerator <= successRateDenominator, "Numerator cannot exceed denominator");
        require(failureStateChangeLikelihood <= successRateDenominator, "Failure state likelihood cannot exceed denominator"); // Use same denominator for simplicity

        fusionParameters = FusionParameters({
            successRateNumerator: successRateNumerator,
            successRateDenominator: successRateDenominator,
            failureStateChangeLikelihood: failureStateChangeLikelihood,
            minStabilityForFusion: minStabilityForFusion,
            maxGenerationDifference: maxGenerationDifference
        });
    }

    /// @dev Owner sets the decay rate. Higher rate means slower decay.
    /// @param newDecayRate The time unit interval for 1 stability loss (e.g., seconds per stability).
    function setDecayRate(uint64 newDecayRate) external onlyOwner {
         require(newDecayRate > 0, "Decay rate must be positive");
        decayRate = newDecayRate;
    }

    /// @dev Owner sets the effects for a specific catalyst ID.
    /// @param catalystId The ID of the catalyst.
    /// @param stabilityModifier The amount to add/subtract from stability.
    /// @param chargeModifier The amount to add/subtract from charge.
    /// @param mutationChance N/10000 chance of mutation (e.g., 500 = 5% chance).
    /// @param stateChangeDuration Duration in seconds for a temporary state change effect (0 if none).
    function setCatalystEffect(
        uint256 catalystId,
        int256 stabilityModifier,
        int256 chargeModifier,
        uint256 mutationChance,
        uint64 stateChangeDuration
    ) external onlyOwner {
        _catalystEffects[catalystId] = CatalystEffect({
            stabilityModifier: stabilityModifier,
            chargeModifier: chargeModifier,
            mutationChance: mutationChance,
            stateChangeDuration: stateChangeDuration
        });
    }

    /// @dev Gets the effects defined for a specific catalyst ID.
    /// @param catalystId The ID of the catalyst.
    /// @return The CatalystEffect struct data.
    function getCatalystEffect(uint256 catalystId) public view returns (CatalystEffect memory) {
        return _catalystEffects[catalystId];
    }

    /// @dev Pauses the contract. Prevents actions like fusion, refinement, mutation, etc.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @dev Unpauses the contract.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @dev Allows the owner to withdraw any ETH or other tokens sent to the contract.
    /// Implement specific token withdrawal functions if needed.
    /// @param recipient Address to send funds to.
    function withdrawAnyBalance(address recipient) external onlyOwner {
        require(recipient != address(0), "Invalid recipient address");

        // Withdraw ETH
        (bool successETH, ) = recipient.call{value: address(this).balance}("");
        require(successETH, "ETH withdrawal failed");

        // Add logic here for withdrawing other tokens if the contract is designed to receive them
        // e.g., IERC20(tokenAddress).transfer(recipient, IERC20(tokenAddress).balanceOf(address(this)));
    }


    // --- Utility ---

    /// @dev Returns the contract version string.
    function contractVersion() external pure returns (string memory) {
        return "QuantumFusion_1.0";
    }

    // --- Internal View Helpers (for simulateInteraction) ---

    function _particleTypeToString(ParticleType pType) internal pure returns (string memory) {
        if (pType == ParticleType.Elementary) return "Elementary";
        if (pType == ParticleType.Composite) return "Composite";
        if (pType == ParticleType.Exotic) return "Exotic";
        if (pType == ParticleType.Decayed) return "Decayed";
        return "Undefined";
    }

    function _uint256ToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint265 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }

     function _int256ToString(int256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        bool negative = value < 0;
        if (negative) {
            value = -value;
        }
        uint256 absValue = uint256(value);
        string memory absString = _uint256ToString(absValue);

        if (negative) {
            bytes memory buffer = new bytes(absString.length + 1);
            buffer[0] = '-';
            bytes(absString).transfer(0, buffer, 1, absString.length); // copy absString bytes into buffer after '-'
            return string(buffer);
        } else {
            return absString;
        }
    }

}
```