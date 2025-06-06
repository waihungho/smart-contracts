Okay, let's create a smart contract with a unique theme and advanced mechanics. We'll call it the **QuantumFluxCatalyst**.

The core idea is a system involving:
1.  **Flux:** A fungible, time-generating resource specific to each user.
2.  **Resonance:** A global, time-decaying state influenced by user actions and catalysts.
3.  **Catalysts:** Non-fungible tokens (NFTs) with dynamic attributes, which consume Flux, influence Resonance, and can be used to synthesize new Catalysts or mutate existing ones.
4.  **Epochs:** Time periods affecting resource generation and decay rates.

This involves concepts like time-based state changes, resource management, dynamic NFTs (attributes changing based on interaction), crafting/synthesis mechanics, and a global state variable influenced by individual actions.

**Disclaimer:** This is a complex example focusing on demonstrating creative logic. Implementing it in a production environment would require rigorous testing, gas optimization, security audits, and potentially external services (like Chainlink VRF for better randomness, or keeper networks for automating time-based processes). The "randomness" implemented here is pseudo-random and unsuitable for high-value applications where predictability is a vulnerability.

---

## QuantumFluxCatalyst Smart Contract: Outline and Function Summary

**Contract Name:** `QuantumFluxCatalyst`

**Core Concepts:** Time-based resource generation (Flux), Global state interaction (Resonance), Dynamic NFTs (Catalysts with changing attributes), Multi-stage processes (Synthesis, Mutation), Epoch system.

**Key State Variables:**
*   `userFlux`: Mapping of user addresses to their Flux balance.
*   `catalysts`: Mapping of token IDs to Catalyst structs (containing attributes, state, timestamps).
*   `ownerOf`: Mapping of token IDs to owner addresses (basic NFT ownership).
*   `userCatalystTokens`: Mapping of user addresses to an array of their catalyst token IDs.
*   `currentGlobalResonance`: The global Resonance value.
*   `fluxGenerationRate`: Rate at which users passively generate Flux (per unit time).
*   `resonanceDecayRate`: Rate at which global Resonance decays (per unit time).
*   `epochDuration`: Duration of each epoch.
*   `currentEpoch`: Current epoch number.
*   `lastEpochUpdateTime`: Timestamp of the last epoch update.
*   `tokenIdCounter`: Counter for minting new catalysts.
*   `userLastProcessedTimestamp`: Timestamp when a user's passive flux was last claimed or processed.

**Structs:**
*   `Catalyst`: Represents a single NFT with attributes (`fluxAbsorptionRate`, `resonanceInfluence`, `synthesisPotential`, `mutationPotential`), state (`Inert`, `Active`, `Synthesizing`, `Mutating`), and process timestamps (`lastProcessedTimestamp`, `processCompletionTime`).

**Enums:**
*   `CatalystState`: Defines the possible states of a Catalyst.

**Events:**
*   `FluxClaimed`: When a user claims passive Flux.
*   `CatalystMinted`: When a new Catalyst is created.
*   `CatalystTransferred`: When a Catalyst is transferred.
*   `CatalystStateChanged`: When a Catalyst's state changes.
*   `CatalystAttributesMutated`: When a Catalyst's attributes change.
*   `ResonanceUpdated`: When the global Resonance changes.
*   `EpochAdvanced`: When the epoch changes.
*   `ParametersAdjusted`: When global parameters are changed (admin).

**Function Summary (Minimum 20 functions):**

**I. Getters and Basic State Queries:**
1.  `getUserFlux(address user)`: Get a user's current Flux balance, including passive generation since last claim.
2.  `getCurrentGlobalResonance()`: Get the current global Resonance value, accounting for time decay.
3.  `getCatalyst(uint256 tokenId)`: Get the full details (struct) of a specific Catalyst.
4.  `ownerOf(uint256 tokenId)`: Get the owner of a specific Catalyst token (standard NFT getter).
5.  `getUserCatalystTokens(address user)`: Get the list of token IDs owned by a user.
6.  `getTotalCatalystSupply()`: Get the total number of Catalysts minted.
7.  `getFluxGenerationRate()`: Get the current global Flux generation rate.
8.  `getResonanceDecayRate()`: Get the current global Resonance decay rate.
9.  `getEpochDuration()`: Get the duration of an epoch.
10. `getCurrentEpoch()`: Get the current epoch number.
11. `getCatalystState(uint256 tokenId)`: Get the current state of a specific Catalyst.

**II. User Actions (Flux & Resonance Interaction):**
12. `claimPassiveFlux()`: Allows a user to claim Flux generated based on time elapsed since their last claim or processing. Updates user's Flux balance and processing timestamp.
13. `processCatalystEffects(uint256 tokenId)`: Processes the effects of a single Catalyst. Consumes Flux from the owner, influences global Resonance, and updates the Catalyst's internal timestamp. Requires the Catalyst to be `Active`.
14. `processAllUserCatalysts(address user)`: A helper or user-callable function to process effects for all `Active` catalysts owned by a user. (Could be gas-intensive).
15. `activateCatalyst(uint256 tokenId)`: Changes a Catalyst's state from `Inert` to `Active`. May require a small Flux cost. Calls `processCatalystEffects` to settle state before activating.
16. `deactivateCatalyst(uint256 tokenId)`: Changes a Catalyst's state from `Active` to `Inert`. Calls `processCatalystEffects` to settle state before deactivating.
17. `synthesizeCatalyst(uint256 sourceCatalystId)`: Initiates a synthesis process using an `Active` Catalyst. Requires Flux cost and sufficient `synthesisPotential`. Changes state to `Synthesizing`. The outcome (success/failure, new attributes) is determined internally and finalized later.
18. `mutateCatalyst(uint256 catalystId)`: Initiates a mutation process on an `Active` Catalyst. Requires Flux cost and sufficient `mutationPotential`. Changes state to `Mutating`. The outcome (success/failure, new attributes) is determined internally and finalized later.
19. `claimSynthesisOutput(uint256 sourceCatalystId)`: Finalizes a completed synthesis process. If successful, mints a new Catalyst and transfers it to the user. Changes source Catalyst state back to `Active` or `Inert`.
20. `claimMutationOutput(uint256 catalystId)`: Finalizes a completed mutation process. If successful, updates the Catalyst's attributes. Changes state back to `Active` or `Inert`.
21. `attuneCatalyst(uint256 tokenId, uint256 fluxBoost, uint256 resonanceBoost, uint256 duration)`: Allows a user to spend Flux to temporarily boost a Catalyst's `fluxAbsorptionRate` and `resonanceInfluence` for a specified duration.
22. `transferCatalyst(address recipient, uint256 tokenId)`: Transfers ownership of a Catalyst token. Deactivates the catalyst before transfer.

**III. Admin/System Functions:**
23. `mintCatalyst(address recipient, uint256 initialFluxRate, uint256 initialResInfluence, uint256 initialSynthPotential, uint256 initialMutPotential)`: Allows the contract owner to mint a new Catalyst with specified base attributes and assign it to a user.
24. `distributeFlux(address[] users, uint256[] amounts)`: Allows the contract owner to distribute Flux to multiple users.
25. `adjustGlobalParameters(uint256 newFluxGenerationRate, uint256 newResonanceDecayRate, uint256 newEpochDuration)`: Allows the contract owner to adjust global rates and epoch duration.
26. `triggerResonanceCascade(uint256 boostAmount)`: Allows the owner to manually add a large boost to global Resonance (e.g., for events).
27. `burnCatalyst(uint256 tokenId)`: Allows the owner to burn a Catalyst token.

*(Self-correction: We have well over 20 functions now, including internal helpers which are also functions though not directly callable externally. The summary lists the key external ones).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Note: This contract is a complex example demonstrating concepts.
// It is NOT audited and not suitable for production use without significant review,
// testing, and potential refactoring (e.g., externalizing processing for gas efficiency,
// using Chainlink VRF for true randomness).

/*
 * QuantumFluxCatalyst Smart Contract
 *
 * This contract simulates a system involving time-based resource generation (Flux),
 * a global dynamic state (Resonance), and dynamic non-fungible tokens (Catalysts).
 * Catalysts consume Flux, influence Resonance, and can be used in synthesis or
 * mutation processes to create new Catalysts or alter existing ones. An Epoch
 * system governs global rates.
 *
 * Features:
 * - Passive Flux generation for users over time.
 * - Global Resonance state that decays over time and is influenced by Active Catalysts.
 * - Dynamic Catalyst NFTs with attributes influencing Flux consumption, Resonance
 *   contribution, synthesis potential, and mutation potential.
 * - Catalyst states: Inert, Active, Synthesizing, Mutating.
 * - Time-based processing of Catalyst effects.
 * - Multi-stage Synthesis and Mutation processes.
 * - Temporary Catalyst attribute boosts (Attunement).
 * - Epoch system affecting global rates.
 * - Basic NFT ownership tracking (without full ERC721 interface for brevity,
 *   but ownership transfer is included).
 * - Admin functions for initialization and parameter adjustment.
 *
 * Outline:
 * - Imports
 * - Structs and Enums
 * - Events
 * - State Variables
 * - Constructor
 * - Internal Helper Functions (Epoch, Resonance, Processing, Minting/Burning)
 * - Public Getter Functions (>= 10)
 * - User Action Functions (Claiming, Activating, Processing, Synthesis, Mutation, Attunement, Transfer >= 10)
 * - Admin Functions (Minting, Distribution, Parameter Adjustment, Cascade)
 *
 * Function Summary: (See detailed list above code block)
 * Includes getters for user flux, resonance, catalyst details, supply, rates, epochs, state.
 * Includes user actions for claiming flux, processing catalyst effects, activating/deactivating,
 * initiating and claiming synthesis/mutation, attuning, and transferring catalysts.
 * Includes admin actions for minting, distributing flux, adjusting parameters, and triggering
 * resonance cascades.
 */

contract QuantumFluxCatalyst is Ownable {
    using Counters for Counters.Counter;

    // --- Structs and Enums ---

    enum CatalystState {
        Inert,
        Active,
        Synthesizing,
        Mutating
    }

    struct Catalyst {
        uint256 tokenId;
        // Base attributes (can be affected by Attunement or Mutation)
        uint256 baseFluxAbsorptionRate; // Flux consumed per unit time while Active
        uint256 baseResonanceInfluence; // Resonance contribution per unit time while Active
        uint256 synthesisPotential; // Chance/ability to synthesize new catalysts
        uint256 mutationPotential; // Chance/ability to mutate attributes

        // Attunement Boost (temporary overrides base attributes)
        uint256 fluxBoost;
        uint256 resonanceBoost;
        uint256 boostExpirationTime;

        CatalystState state;
        uint256 lastProcessedTimestamp; // When its effects were last applied
        uint256 processCompletionTime; // For Synthesizing/Mutating states

        // Pointer back to owner for faster user lookup (redundant with ownerOf but useful)
        address currentOwner;
    }

    // --- State Variables ---

    mapping(address => uint256) private userFlux; // User's Flux balance
    mapping(address => uint256) private userLastProcessedTimestamp; // When user's passive flux was last claimed/processed
    mapping(uint256 => Catalyst) public catalysts; // All catalyst data
    mapping(uint256 => address) private _ownerOf; // Standard NFT owner mapping
    mapping(address => uint256[]) private userCatalystTokens; // Quick lookup for user's token IDs

    Counters.Counter private _tokenIdCounter; // Counter for unique Catalyst IDs

    uint256 public currentGlobalResonance; // The current global Resonance value

    uint256 public fluxGenerationRate; // Passive Flux generation rate per user per second
    uint256 public resonanceDecayRate; // Global Resonance decay rate per second

    uint256 public epochDuration; // Duration of each epoch in seconds
    uint256 public currentEpoch; // Current epoch number
    uint256 public lastEpochUpdateTime; // Timestamp of the last epoch update

    // Costs for synthesis and mutation processes (in Flux)
    uint256 public synthesisFluxCost;
    uint256 public mutationFluxCost;
    uint256 public constant PROCESS_DURATION = 1 days; // Duration for synthesis/mutation processes

    // --- Events ---

    event FluxClaimed(address indexed user, uint256 amount);
    event CatalystMinted(address indexed owner, uint256 indexed tokenId, uint256 initialFluxRate, uint256 initialResInfluence);
    event CatalystTransferred(address indexed from, address indexed to, uint256 indexed tokenId);
    event CatalystStateChanged(uint256 indexed tokenId, CatalystState newState);
    event CatalystAttributesMutated(uint256 indexed tokenId, uint256 newFluxRate, uint256 newResInfluence, uint256 newSynthPotential, uint256 newMutPotential);
    event ResonanceUpdated(uint256 newResonanceValue);
    event EpochAdvanced(uint224 indexed epoch, uint256 timestamp);
    event ParametersAdjusted(uint256 newFluxGenerationRate, uint256 newResonanceDecayRate, uint256 newEpochDuration);
    event CatalystProcessed(uint256 indexed tokenId, uint256 fluxConsumed, uint256 resonanceAdded, uint256 timeElapsed);
    event AttunementApplied(uint256 indexed tokenId, uint256 fluxBoost, uint256 resonanceBoost, uint256 expirationTime);
    event SynthesisInitiated(uint256 indexed sourceCatalystId, uint256 completionTime);
    event MutationInitiated(uint256 indexed catalystId, uint256 completionTime);
    event SynthesisCompleted(uint256 indexed sourceCatalystId, uint256 indexed newCatalystId);
    event MutationCompleted(uint256 indexed catalystId, uint256 success, uint256 newFluxRate, uint256 newResInfluence, uint256 newSynthPotential, uint256 newMutPotential);
    event CatalystBurned(uint256 indexed tokenId);

    // --- Constructor ---

    constructor(
        uint256 _initialFluxGenerationRate,
        uint256 _initialResonanceDecayRate,
        uint256 _initialEpochDuration,
        uint256 _initialSynthesisFluxCost,
        uint256 _initialMutationFluxCost
    ) Ownable(msg.sender) {
        fluxGenerationRate = _initialFluxGenerationRate;
        resonanceDecayRate = _initialResonanceDecayRate;
        epochDuration = _initialEpochDuration;
        lastEpochUpdateTime = block.timestamp;
        currentEpoch = 0;

        synthesisFluxCost = _initialSynthesisFluxCost;
        mutationFluxCost = _initialMutationFluxCost;

        currentGlobalResonance = 0; // Start from zero or initial value? Let's start at 0.
    }

    // --- Internal Helper Functions ---

    // @notice Updates the current epoch based on time elapsed
    function _updateEpoch() internal {
        uint256 timeElapsed = block.timestamp - lastEpochUpdateTime;
        if (timeElapsed >= epochDuration) {
            uint256 epochsPassed = timeElapsed / epochDuration;
            currentEpoch += epochsPassed;
            lastEpochUpdateTime += epochsPassed * epochDuration; // Advance timestamp accurately
            emit EpochAdvanced(uint224(currentEpoch), block.timestamp);
            // Potential: Rates could change based on epoch number here
        }
    }

    // @notice Updates global Resonance based on time decay. Should be called before reading resonance.
    function _updateGlobalResonance() internal {
        _updateEpoch(); // Ensure epoch is updated first

        uint256 timeSinceLastUpdate = block.timestamp - lastEpochUpdateTime; // Decay happens relative to epoch start? Or constantly? Let's do constantly.
        // Using `block.timestamp` directly since the last time *Resonance* was updated would be better,
        // but tracking that globally adds complexity. Let's assume this is called frequently enough
        // or incorporate decay into catalyst processing.
        // Alternative: Decay happens *only* during `_processCatalystEffects` or specific calls.
        // Let's simplify and decay based on time since *lastEpochUpdateTime* (as a proxy for system activity).
        // If resonance is very low, decay should slow down. Add a floor.
        uint256 decayAmount = (block.timestamp - lastEpochUpdateTime) * resonanceDecayRate;
        if (currentGlobalResonance > decayAmount) {
             currentGlobalResonance -= decayAmount;
        } else {
             currentGlobalResonance = 0; // Cannot go below zero
        }
        // Maybe set lastEpochUpdateTime = block.timestamp after decay calculation? No, that would stop decay until next epoch.
        // Let's refine: Calculate decay based on time since `lastGlobalResonanceUpdateTimestamp`.
        // Adding `uint256 private lastGlobalResonanceUpdateTimestamp;` state variable.
        // Constructor sets `lastGlobalResonanceUpdateTimestamp = block.timestamp;`
        uint256 timeSinceResonanceUpdate = block.timestamp - lastGlobalResonanceUpdateTimestamp;
         uint256 decayThisPeriod = timeSinceResonanceUpdate * resonanceDecayRate;
         if (currentGlobalResonance > decayThisPeriod) {
             currentGlobalResonance -= decayThisPeriod;
         } else {
             currentGlobalResonance = 0;
         }
        lastGlobalResonanceUpdateTimestamp = block.timestamp; // Update timestamp after decay calculation

        emit ResonanceUpdated(currentGlobalResonance);
    }
     uint256 private lastGlobalResonanceUpdateTimestamp; // Added state variable

    // @notice Calculates passive Flux generation and updates user's timestamp
    // @param user The address of the user to process
    // @return The amount of Flux generated
    function _processUserPassiveFlux(address user) internal returns (uint256 generatedFlux) {
        uint256 timeElapsed = block.timestamp - userLastProcessedTimestamp[user];
        generatedFlux = timeElapsed * fluxGenerationRate;
        userFlux[user] += generatedFlux;
        userLastProcessedTimestamp[user] = block.timestamp;
        return generatedFlux;
    }

    // @notice Mints a new Catalyst token
    function _mintCatalyst(address recipient, uint256 fluxRate, uint256 resInfluence, uint256 synthPotential, uint256 mutPotential) internal returns (uint256 tokenId) {
        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();

        catalysts[tokenId] = Catalyst({
            tokenId: tokenId,
            baseFluxAbsorptionRate: fluxRate,
            baseResonanceInfluence: resInfluence,
            synthesisPotential: synthPotential,
            mutationPotential: mutPotential,
            fluxBoost: 0,
            resonanceBoost: 0,
            boostExpirationTime: 0,
            state: CatalystState.Inert, // Minted as Inert
            lastProcessedTimestamp: block.timestamp,
            processCompletionTime: 0,
            currentOwner: recipient // Set owner in struct
        });

        // Update ownership mappings
        _ownerOf[tokenId] = recipient;
        userCatalystTokens[recipient].push(tokenId);

        emit CatalystMinted(recipient, tokenId, fluxRate, resInfluence);
    }

    // @notice Burns a Catalyst token
    function _burnCatalyst(uint256 tokenId) internal {
        require(_ownerOf[tokenId] != address(0), "Catalyst does not exist");
        address owner = _ownerOf[tokenId];

        // Remove from owner's array
        uint256[] storage tokens = userCatalystTokens[owner];
        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] == tokenId) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }

        // Clear mappings and delete struct
        delete _ownerOf[tokenId];
        delete catalysts[tokenId]; // This resets the struct to default values

        emit CatalystBurned(tokenId);
    }

    // @notice Transfers ownership of a Catalyst token
    function _transferCatalyst(address from, address to, uint256 tokenId) internal {
        require(_ownerOf[tokenId] == from, "Not owner");
        require(to != address(0), "Transfer to zero address");

        // Ensure catalyst is inert before transfer
        if (catalysts[tokenId].state == CatalystState.Active) {
             _processCatalystEffects(tokenId); // Settle effects
             catalysts[tokenId].state = CatalystState.Inert; // Force Inert state on transfer
             emit CatalystStateChanged(tokenId, CatalystState.Inert);
        } else if (catalysts[tokenId].state != CatalystState.Inert) {
            // Cannot transfer while Synthesizing or Mutating
            revert("Cannot transfer while catalyst is processing");
        }


        // Update owner's array (remove from 'from')
        uint256[] storage fromTokens = userCatalystTokens[from];
         bool found = false;
        for (uint i = 0; i < fromTokens.length; i++) {
            if (fromTokens[i] == tokenId) {
                fromTokens[i] = fromTokens[fromTokens.length - 1];
                fromTokens.pop();
                 found = true; // Should always be found if ownerOf is correct
                break;
            }
        }
        require(found, "Internal error: token not found in owner array");


        // Update mappings
        _ownerOf[tokenId] = to;
        catalysts[tokenId].currentOwner = to; // Update owner in struct
        userCatalystTokens[to].push(tokenId); // Add to 'to's array

        emit CatalystTransferred(from, to, tokenId);
    }

    // @notice Pseudo-randomly generates attributes for a new or mutated catalyst
    // @dev This randomness is predictable and should NOT be used in security-sensitive contexts.
    //      A production system would use Chainlink VRF or similar.
    // @param entropySeed An extra seed for randomness, e.g., from source catalyst attributes
    // @return Generated attributes: fluxRate, resInfluence, synthPotential, mutPotential
    function _generateCatalystAttributes(uint256 entropySeed) internal view returns (uint256, uint256, uint256, uint256) {
        // Combine various low-entropy sources
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            block.number,
            msg.sender, // User initiating action
            entropySeed,
            currentGlobalResonance // Influence results based on global state
        )));

        // Use the seed to derive attributes (example simple ranges)
        // These ranges/logic would need careful tuning in a real system
        uint256 fluxRate = (seed % 100) + 10; // 10 to 109
        uint256 resInfluence = ((seed / 100) % 50) + 5; // 5 to 54
        uint256 synthPotential = ((seed / 5000) % 20) + 1; // 1 to 20
        uint256 mutPotential = ((seed / 100000) % 15) + 1; // 1 to 15

        // Further influence by global resonance? Higher resonance -> better stats?
        // Let's add a simple multiplier based on scaled resonance (e.g., 1 + resonance/10000)
        uint256 resonanceMultiplier = 1e18 + (currentGlobalResonance > 1e16 ? currentGlobalResonance / 100 : 0); // Avoid overflow, scale down resonance effect
         fluxRate = (fluxRate * resonanceMultiplier) / 1e18;
         resInfluence = (resInfluence * resonanceMultiplier) / 1e18;
         synthPotential = (synthPotential * resonanceMultiplier) / 1e18;
         mutPotential = (mutPotential * resonanceMultiplier) / 1e18;

        return (fluxRate, resInfluence, synthPotential, mutPotential);
    }

    // @notice Processes the effects of a single Catalyst based on time elapsed
    function _processCatalystEffects(uint256 tokenId) internal {
        Catalyst storage cat = catalysts[tokenId];
        require(cat.state != CatalystState.Synthesizing && cat.state != CatalystState.Mutating, "Catalyst is processing, effects are paused");

        uint256 timeElapsed = block.timestamp - cat.lastProcessedTimestamp;

        if (timeElapsed == 0) {
            return; // Nothing to process
        }

        uint256 currentFluxAbsorptionRate = cat.baseFluxAbsorptionRate;
        uint256 currentResonanceInfluence = cat.baseResonanceInfluence;

        // Apply attunement boost if active
        if (block.timestamp < cat.boostExpirationTime) {
            currentFluxAbsorptionRate += cat.fluxBoost;
            currentResonanceInfluence += cat.resonanceBoost;
        } else if (cat.boostExpirationTime > 0) {
            // Boost expired, reset it
            cat.fluxBoost = 0;
            cat.resonanceBoost = 0;
            cat.boostExpirationTime = 0;
        }

        uint256 fluxCost = timeElapsed * currentFluxAbsorptionRate;
        uint256 resonanceAdded = timeElapsed * currentResonanceInfluence;

        // Check user's flux balance - cannot process if insufficient flux
        address owner = cat.currentOwner; // Use currentOwner from struct
        if (userFlux[owner] < fluxCost) {
            // Not enough flux. Process only for the time flux was available.
            // This is complex: (timeElapsed / fluxCost) * userFlux[owner]. Need to handle division by zero.
            // Simpler: Deactivate the catalyst if flux runs out.
            if (cat.state == CatalystState.Active) {
                 cat.state = CatalystState.Inert; // Deactivate due to insufficient flux
                 emit CatalystStateChanged(tokenId, CatalystState.Inert);
                 // Log this scenario?
                 emit CatalystProcessed(tokenId, userFlux[owner], 0, timeElapsed); // Report consumed flux
                 userFlux[owner] = 0; // Consume all remaining flux
                 cat.lastProcessedTimestamp = block.timestamp; // Update timestamp fully
                 return; // Stop processing effects for this cycle
            } else {
                 // If not active (e.g., Inert), no flux cost anyway, just update timestamp
                 cat.lastProcessedTimestamp = block.timestamp;
                 return;
            }
        }

        // Consume Flux
        userFlux[owner] -= fluxCost;

        // Add Resonance (only if Active)
        if (cat.state == CatalystState.Active) {
             currentGlobalResonance += resonanceAdded;
             // Ensure resonance update timestamp is updated when resonance is added
             lastGlobalResonanceUpdateTimestamp = block.timestamp;
        }


        // Update catalyst timestamp
        cat.lastProcessedTimestamp = block.timestamp;

        emit CatalystProcessed(tokenId, fluxCost, resonanceAdded, timeElapsed);
    }

    // @notice Resolves a synthesis attempt (internal logic)
    function _resolveSynthesisAttempt(uint256 sourceCatalystId) internal {
        Catalyst storage cat = catalysts[sourceCatalystId];
        require(cat.state == CatalystState.Synthesizing, "Synthesis not initiated");
        require(block.timestamp >= cat.processCompletionTime, "Synthesis not completed yet");

        // Determine success based on synthesis potential and global resonance (example logic)
        // Pseudo-random outcome based on combined factors
        uint256 successChance = cat.synthesisPotential + (currentGlobalResonance / 10000); // Scale resonance effect
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, sourceCatalystId, cat.synthesisPotential, currentGlobalResonance)));
        uint255 randomNumber = uint255(seed); // Max value of uint255 is large enough for percentages

        bool success = (randomNumber % 100) < successChance; // Simple chance check (capped at 100)

        if (success) {
            // Generate attributes for the new catalyst influenced by the source and global state
            (uint256 fluxRate, uint256 resInfluence, uint256 synthPotential, uint256 mutPotential) = _generateCatalystAttributes(cat.baseFluxAbsorptionRate + cat.baseResonanceInfluence + cat.synthesisPotential);

            // Mint the new catalyst
            uint256 newCatalystId = _mintCatalyst(cat.currentOwner, fluxRate, resInfluence, synthPotential, mutPotential);

            emit SynthesisCompleted(sourceCatalystId, newCatalystId);
        } else {
            // Synthesis failed, perhaps refund some flux or add a penalty?
             // For simplicity, no refund/penalty here. Just no new token.
             emit SynthesisCompleted(sourceCatalystId, 0); // Signal failure with tokenid 0
        }

        // Reset source catalyst state and completion time
        cat.state = CatalystState.Active; // Return to active after synthesis
        cat.processCompletionTime = 0;
        emit CatalystStateChanged(sourceCatalystId, CatalystState.Active); // Assume returns to Active
    }

    // @notice Resolves a mutation attempt (internal logic)
    function _resolveMutationAttempt(uint256 catalystId) internal {
        Catalyst storage cat = catalysts[catalystId];
        require(cat.state == CatalystState.Mutating, "Mutation not initiated");
        require(block.timestamp >= cat.processCompletionTime, "Mutation not completed yet");

        // Determine success and outcome based on mutation potential and global resonance
        uint256 successChance = cat.mutationPotential + (currentGlobalResonance / 10000); // Scale resonance effect
         uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, catalystId, cat.mutationPotential, currentGlobalResonance)));
        uint255 randomNumber = uint255(seed);

        bool success = (randomNumber % 100) < successChance;

        uint256 newFluxRate = cat.baseFluxAbsorptionRate;
        uint256 newResInfluence = cat.baseResonanceInfluence;
        uint256 newSynthPotential = cat.synthesisPotential;
        uint256 newMutPotential = cat.mutationPotential;

        if (success) {
             // Generate NEW attributes (could be better or worse)
            (newFluxRate, newResInfluence, newSynthPotential, newMutPotential) = _generateCatalystAttributes(cat.baseFluxAbsorptionRate + cat.baseResonanceInfluence + cat.mutationPotential);

            // Apply the new attributes
            cat.baseFluxAbsorptionRate = newFluxRate;
            cat.baseResonanceInfluence = newResInfluence;
            cat.synthesisPotential = newSynthPotential;
            cat.mutationPotential = newMutPotential;

            emit CatalystAttributesMutated(catalystId, newFluxRate, newResInfluence, newSynthPotential, newMutPotential);
        }
        // If failed, attributes remain unchanged.

        emit MutationCompleted(catalystId, success ? 1 : 0, newFluxRate, newResInfluence, newSynthPotential, newMutPotential);

        // Reset catalyst state and completion time
        cat.state = CatalystState.Active; // Return to active after mutation
        cat.processCompletionTime = 0;
         emit CatalystStateChanged(catalystId, CatalystState.Active); // Assume returns to Active
    }

    // --- Public Getter Functions ---

    // 1. Get a user's current Flux balance, including passive generation since last claim.
    function getUserFlux(address user) external view returns (uint256) {
         // Need to process passive flux generation in a view function without changing state.
         // This requires recalculating time elapsed.
         uint256 timeElapsed = block.timestamp - userLastProcessedTimestamp[user];
         uint256 generatedFlux = timeElapsed * fluxGenerationRate;
        return userFlux[user] + generatedFlux;
    }

    // 2. Get the current global Resonance value, accounting for time decay.
    function getCurrentGlobalResonance() external view returns (uint256) {
        // Need to calculate decay without changing state
        uint256 timeSinceResonanceUpdate = block.timestamp - lastGlobalResonanceUpdateTimestamp;
        uint256 decayThisPeriod = timeSinceResonanceUpdate * resonanceDecayRate;
        if (currentGlobalResonance > decayThisPeriod) {
             return currentGlobalResonance - decayThisPeriod;
        } else {
             return 0;
        }
    }

    // 3. Get the full details (struct) of a specific Catalyst.
    function getCatalyst(uint256 tokenId) external view returns (Catalyst memory) {
        require(_ownerOf[tokenId] != address(0), "Catalyst does not exist");
        return catalysts[tokenId];
    }

    // 4. Get the owner of a specific Catalyst token.
    function ownerOf(uint256 tokenId) public view returns (address) {
        return _ownerOf[tokenId];
    }

    // 5. Get the list of token IDs owned by a user.
    function getUserCatalystTokens(address user) external view returns (uint256[] memory) {
        return userCatalystTokens[user];
    }

    // 6. Get the total number of Catalysts minted.
    function getTotalCatalystSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // 7. Get the current global Flux generation rate.
    function getFluxGenerationRate() external view returns (uint256) {
        return fluxGenerationRate;
    }

    // 8. Get the current global Resonance decay rate.
    function getResonanceDecayRate() external view returns (uint256) {
        return resonanceDecayRate;
    }

    // 9. Get the duration of an epoch.
    function getEpochDuration() external view returns (uint256) {
        return epochDuration;
    }

    // 10. Get the current epoch number.
    function getCurrentEpoch() external view returns (uint256) {
        // Recalculate epoch in view function
        uint256 timeElapsed = block.timestamp - lastEpochUpdateTime;
        uint256 epochsPassed = timeElapsed / epochDuration;
        return currentEpoch + epochsPassed;
    }

    // 11. Get the current state of a specific Catalyst.
    function getCatalystState(uint256 tokenId) external view returns (CatalystState) {
        require(_ownerOf[tokenId] != address(0), "Catalyst does not exist");
        return catalysts[tokenId].state;
    }

    // --- User Action Functions ---

    // 12. Allows a user to claim Flux generated based on time elapsed.
    function claimPassiveFlux() external {
        _updateEpoch();
        _updateGlobalResonance(); // Update resonance as well

        uint256 generated = _processUserPassiveFlux(msg.sender);
        emit FluxClaimed(msg.sender, generated);
    }

     // 13. Processes the effects of a single Catalyst owned by the caller.
    function processCatalystEffects(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
         _updateEpoch();
         _updateGlobalResonance(); // Update resonance

        _processCatalystEffects(tokenId);
    }

    // 14. Helper or user-callable function to process effects for all active catalysts owned by a user.
    // Caution: This can be gas-intensive if a user has many active catalysts.
    function processAllUserCatalysts(address user) external {
        require(user == msg.sender || owner() == msg.sender, "Not authorized"); // Allow owner to trigger for any user
         _updateEpoch();
         _updateGlobalResonance(); // Update resonance

        uint256[] storage tokens = userCatalystTokens[user];
        for (uint i = 0; i < tokens.length; i++) {
            if (catalysts[tokens[i]].state == CatalystState.Active) {
                _processCatalystEffects(tokens[i]);
            }
        }
         // Process passive flux too while we're here
        _processUserPassiveFlux(user);
    }

    // 15. Changes a Catalyst's state from Inert to Active.
    function activateCatalyst(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require(catalysts[tokenId].state == CatalystState.Inert, "Catalyst is not Inert");

         _updateEpoch();
         _updateGlobalResonance(); // Update resonance

        // Optional: Require a small activation flux cost?
        // uint256 activationCost = 100; // Example cost
        // require(userFlux[msg.sender] >= activationCost, "Insufficient Flux for activation");
        // userFlux[msg.sender] -= activationCost;

        // Process pending effects in Inert state (time elapsed doesn't consume flux/add resonance, just updates timestamp)
        _processCatalystEffects(tokenId); // This ensures `lastProcessedTimestamp` is current before activating

        catalysts[tokenId].state = CatalystState.Active;
        emit CatalystStateChanged(tokenId, CatalystState.Active);
    }

    // 16. Changes a Catalyst's state from Active to Inert.
    function deactivateCatalyst(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require(catalysts[tokenId].state == CatalystState.Active, "Catalyst is not Active");

         _updateEpoch();
         _updateGlobalResonance(); // Update resonance

        // Process pending effects in Active state before deactivating
        _processCatalystEffects(tokenId);

        catalysts[tokenId].state = CatalystState.Inert;
        emit CatalystStateChanged(tokenId, CatalystState.Inert);
    }

    // 17. Initiates a synthesis process using an Active Catalyst.
    function synthesizeCatalyst(uint256 sourceCatalystId) external {
        require(ownerOf(sourceCatalystId) == msg.sender, "Not owner");
        require(catalysts[sourceCatalystId].state == CatalystState.Active, "Source Catalyst must be Active");
        require(userFlux[msg.sender] >= synthesisFluxCost, "Insufficient Flux for synthesis");
        require(catalysts[sourceCatalystId].synthesisPotential > 0, "Source Catalyst has no synthesis potential");

         _updateEpoch();
         _updateGlobalResonance(); // Update resonance

        // Process pending effects before changing state
        _processCatalystEffects(sourceCatalystId);

        // Consume Flux cost
        userFlux[msg.sender] -= synthesisFluxCost;

        // Change state and set completion time
        catalysts[sourceCatalystId].state = CatalystState.Synthesizing;
        catalysts[sourceCatalystId].processCompletionTime = block.timestamp + PROCESS_DURATION; // Process takes fixed duration
        emit CatalystStateChanged(sourceCatalystId, CatalystState.Synthesizing);
        emit SynthesisInitiated(sourceCatalystId, catalysts[sourceCatalystId].processCompletionTime);
    }

    // 18. Initiates a mutation process on an Active Catalyst.
    function mutateCatalyst(uint256 catalystId) external {
        require(ownerOf(catalystId) == msg.sender, "Not owner");
        require(catalysts[catalystId].state == CatalystState.Active, "Catalyst must be Active");
        require(userFlux[msg.sender] >= mutationFluxCost, "Insufficient Flux for mutation");
        require(catalysts[catalystId].mutationPotential > 0, "Catalyst has no mutation potential");

         _updateEpoch();
         _updateGlobalResonance(); // Update resonance

        // Process pending effects before changing state
        _processCatalystEffects(catalystId);

        // Consume Flux cost
        userFlux[msg.sender] -= mutationFluxCost;

        // Change state and set completion time
        catalysts[catalystId].state = CatalystState.Mutating;
        catalysts[catalystId].processCompletionTime = block.timestamp + PROCESS_DURATION; // Process takes fixed duration
        emit CatalystStateChanged(catalystId, CatalystState.Mutating);
        emit MutationInitiated(catalystId, catalysts[catalystId].processCompletionTime);
    }

    // 19. Finalizes a completed synthesis process.
    function claimSynthesisOutput(uint256 sourceCatalystId) external {
        require(ownerOf(sourceCatalystId) == msg.sender, "Not owner");
        require(catalysts[sourceCatalystId].state == CatalystState.Synthesizing, "Catalyst is not Synthesizing");
        require(block.timestamp >= catalysts[sourceCatalystId].processCompletionTime, "Synthesis process not completed yet");

         _updateEpoch();
         _updateGlobalResonance(); // Update resonance

        _resolveSynthesisAttempt(sourceCatalystId);
        // State and completion time are reset inside _resolveSynthesisAttempt
    }

    // 20. Finalizes a completed mutation process.
    function claimMutationOutput(uint256 catalystId) external {
        require(ownerOf(catalystId) == msg.sender, "Not owner");
        require(catalysts[catalystId].state == CatalystState.Mutating, "Catalyst is not Mutating");
        require(block.timestamp >= catalysts[catalystId].processCompletionTime, "Mutation process not completed yet");

         _updateEpoch();
         _updateGlobalResonance(); // Update resonance

        _resolveMutationAttempt(catalystId);
        // State and completion time are reset inside _resolveMutationAttempt
    }

     // 21. Allows a user to spend Flux to temporarily boost a Catalyst's stats.
     function attuneCatalyst(uint256 tokenId, uint256 fluxBoost, uint256 resonanceBoost, uint256 duration) external {
         require(ownerOf(tokenId) == msg.sender, "Not owner");
         require(duration > 0, "Duration must be greater than 0");

         // Calculate Flux cost for attunement (example: 100 Flux per duration unit per 100 boost points)
         uint256 attunementCost = (duration * (fluxBoost + resonanceBoost) * 100) / 1e18; // Scale appropriately
         require(userFlux[msg.sender] >= attunementCost, "Insufficient Flux for attunement");

         _updateEpoch();
         _updateGlobalResonance(); // Update resonance

         // Process pending effects before applying boost (important for accurate timestamps)
         _processCatalystEffects(tokenId);

         // Consume Flux
         userFlux[msg.sender] -= attunementCost;

         // Apply the boost and set expiration time
         Catalyst storage cat = catalysts[tokenId];
         cat.fluxBoost = fluxBoost;
         cat.resonanceBoost = resonanceBoost;
         cat.boostExpirationTime = block.timestamp + duration;

         emit AttunementApplied(tokenId, fluxBoost, resonanceBoost, cat.boostExpirationTime);
     }


    // 22. Transfers ownership of a Catalyst token.
    function transferCatalyst(address recipient, uint256 tokenId) external {
        require(msg.sender != address(0), "Transfer from zero address"); // Standard check
        _transferCatalyst(msg.sender, recipient, tokenId);
    }


    // --- Admin Functions (onlyOwner) ---

    // 23. Allows the contract owner to mint a new Catalyst.
    function mintCatalyst(address recipient, uint256 initialFluxRate, uint256 initialResInfluence, uint256 initialSynthPotential, uint256 initialMutPotential) external onlyOwner {
        require(recipient != address(0), "Mint to zero address");
        _mintCatalyst(recipient, initialFluxRate, initialResInfluence, initialSynthPotential, initialMutPotential);
    }

    // 24. Allows the contract owner to distribute Flux to multiple users.
    function distributeFlux(address[] calldata users, uint256[] calldata amounts) external onlyOwner {
        require(users.length == amounts.length, "Arrays must have same length");
         _updateEpoch(); // Ensure epoch is updated
         _updateGlobalResonance(); // Ensure resonance is updated

        for (uint i = 0; i < users.length; i++) {
            require(users[i] != address(0), "Distribution to zero address");
            // Ensure passive flux is processed before adding more
             _processUserPassiveFlux(users[i]);
            userFlux[users[i]] += amounts[i];
             // No event emitted for each, can add one if needed
        }
    }

    // 25. Allows the contract owner to adjust global rates and epoch duration.
    function adjustGlobalParameters(uint256 newFluxGenerationRate, uint256 newResonanceDecayRate, uint256 newEpochDuration) external onlyOwner {
        require(newEpochDuration > 0, "Epoch duration must be positive");

        fluxGenerationRate = newFluxGenerationRate;
        resonanceDecayRate = newResonanceDecayRate;

        // If epoch duration changes, update epoch based on old duration before setting new
        _updateEpoch(); // This updates epoch based on current `epochDuration`

        epochDuration = newEpochDuration;

        emit ParametersAdjusted(fluxGenerationRate, resonanceDecayRate, epochDuration);
    }

    // 26. Allows the owner to manually add a large boost to global Resonance.
    function triggerResonanceCascade(uint256 boostAmount) external onlyOwner {
        require(boostAmount > 0, "Boost amount must be positive");

         _updateEpoch();
         _updateGlobalResonance(); // Update resonance before adding more

        currentGlobalResonance += boostAmount;
         lastGlobalResonanceUpdateTimestamp = block.timestamp; // Update timestamp after boost
        emit ResonanceUpdated(currentGlobalResonance);
    }

    // 27. Allows the owner to burn a Catalyst token.
    function burnCatalyst(uint256 tokenId) external onlyOwner {
        _burnCatalyst(tokenId);
    }

    // Example Admin function to set specific catalyst attributes (e.g., for initial setup or corrections)
    function setCatalystAttributes(uint256 tokenId, uint256 fluxRate, uint256 resInfluence, uint256 synthPotential, uint256 mutPotential) external onlyOwner {
        require(_ownerOf[tokenId] != address(0), "Catalyst does not exist");
        Catalyst storage cat = catalysts[tokenId];
        require(cat.state != CatalystState.Synthesizing && cat.state != CatalystState.Mutating, "Cannot set attributes while catalyst is processing");

        cat.baseFluxAbsorptionRate = fluxRate;
        cat.baseResonanceInfluence = resInfluence;
        cat.synthesisPotential = synthPotential;
        cat.mutationPotential = mutPotential;

        emit CatalystAttributesMutated(tokenId, fluxRate, resInfluence, synthPotential, mutPotential);
    }
}
```