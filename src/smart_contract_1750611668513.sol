Okay, let's create a smart contract concept centered around dynamic, evolving digital artifacts with interconnected parameters and timed processes. We'll call it `QuantumRealmForge`. The core idea is that users can mint unique NFTs (Artifacts) which have internal properties (Complexity, Stability, Chronon Energy, Rarity Potential) that can change over time or through user interaction, leading to potential "evolution" or "decay."

This contract will blend concepts of:
1.  **Dynamic NFTs:** Artifact parameters change on-chain.
2.  **Time-Based Mechanics:** Parameters decay over time (simulated by calculating elapsed time since last interaction).
3.  **State-Dependent Behavior:** Actions or outcomes depend on the current state of the artifact's parameters.
4.  **Resource Management (Simulated):** Chronon Energy acts as a resource.
5.  **Parametric Systems:** Artifacts are defined by numerical parameters that interact.
6.  **User Interaction as Input:** User actions drive changes in artifact state.
7.  **Simulated Complexity/Evolution:** Functions mimic processes of growth, decay, and transformation.
8.  **Artifact Interaction:** Allowing two NFTs to interact and influence each other.

---

**Outline and Function Summary: QuantumRealmForge**

This contract allows users to forge unique digital artifacts (ERC721 NFTs) with dynamic, interconnected parameters. These parameters (Complexity, Stability, Chronon Energy, Rarity Potential) evolve based on time elapsed and specific user-triggered functions.

**Core Concepts:**

*   **Artifacts:** ERC721 tokens with unique IDs.
*   **Parameters:** `complexity`, `stability`, `chrononEnergy`, `rarityPotential` - numerical values influencing artifact state and behavior.
*   **Chronon Decay:** `chrononEnergy` decreases over real-world time if the artifact is not interacted with.
*   **Quantum Flux:** A function introducing random-like changes to parameters.
*   **Evolution:** A potential transformation unlocked when parameters meet certain thresholds.
*   **Resonance:** Interaction between two artifacts affecting their parameters.

**Functions Summary:**

1.  `constructor()`: Initializes the contract, sets owner.
2.  `forgeArtifact()`: Mints a new ERC721 artifact. Requires ETH payment. Initializes parameters based on block data/simple entropy.
3.  `forgeArtifactWithBias(uint16 complexityBias, uint16 stabilityBias)`: Mints a new artifact, allowing the user to slightly bias initial complexity/stability within limits. Higher cost.
4.  `batchForgeArtifacts(uint256 count)`: Mints multiple artifacts in a single transaction.
5.  `getArtifactParameters(uint256 tokenId)`: Reads the current core parameters of an artifact.
6.  `getArtifactGenesisAttributes(uint256 tokenId)`: Reads the initial parameters when the artifact was minted.
7.  `getDynamicTraits(uint256 tokenId)`: Calculates and returns descriptive "traits" (strings) based on the artifact's *current* parameter values (e.g., "Unstable", "Radiant"). Pure function.
8.  `infuseChrononEnergy(uint256 tokenId)`: Increases the `chrononEnergy` parameter. Requires payment or specific conditions. Updates last interaction time.
9.  `stabilizeArtifact(uint256 tokenId)`: Increases the `stability` parameter. May slightly decrease `complexity`. Requires payment. Updates last interaction time.
10. `introduceComplexity(uint256 tokenId)`: Increases the `complexity` parameter. May slightly decrease `stability`. Requires payment and potentially high chronon energy. Updates last interaction time.
11. `attuneRarityPotential(uint256 tokenId)`: Increases the `rarityPotential` parameter. More expensive/rare action. Updates last interaction time.
12. `triggerQuantumFlux(uint256 tokenId)`: Applies a significant, pseudo-random change to all parameters based on their current state and chronon energy. Consumes chronon energy. Updates last interaction time.
13. `decayChrononEnergy(uint256 tokenId)`: Calculates elapsed time since last interaction and reduces `chrononEnergy` based on the global decay rate. Can be called by anyone (a keeper function, though no explicit reward mechanism is built in this version).
14. `attemptEvolution(uint256 tokenId)`: Checks if parameters meet specific thresholds for evolution. If so, triggers a major parameter shift or state change (e.g., unlocks new ranges, changes trait calculation logic). Consumes energy/stability. Updates last interaction time.
15. `crystallizeState(uint256 tokenId)`: Locks the `complexity` and `stability` parameters, preventing further changes from decay or flux (but possibly limiting evolution). Requires high cost/energy. Updates last interaction time.
16. `initiateResonance(uint256 tokenId1, uint256 tokenId2)`: Allows two artifacts to interact. Their parameters are modified based on a defined resonance logic (e.g., averaging, transferring, or conflicting). Requires ownership/approval for both. Updates last interaction time for both.
17. `queryPotentialFluxResult(uint256 tokenId)`: Pure/view function showing a potential outcome if `triggerQuantumFlux` were called now (for simulation/preview). Uses parameters but no state change.
18. `setForgingCost(uint256 newCost)`: Owner function to update the cost of forging.
19. `setChrononDecayRate(uint256 rate)`: Owner function to update the decay rate for chronon energy (per hour equivalent).
20. `getForgingCost()`: Returns the current cost to forge.
21. `getChrononDecayRate()`: Returns the current decay rate.
22. `getTotalArtifactSupply()`: Returns the total number of artifacts minted.
23. `getArtifactLastInteractionTime(uint256 tokenId)`: Returns the timestamp of the last interaction with the artifact.
24. `withdrawFunds()`: Owner function to withdraw ETH collected from forging/interactions.
25. `renounceOwnership()`: Owner can renounce ownership (standard OpenZeppelin).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Outline and Function Summary ---
// See above section for detailed Outline and Function Summary.
// --- End Outline and Function Summary ---

contract QuantumRealmForge is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

    // Struct to hold artifact parameters
    struct ArtifactParameters {
        // Parameters are uint16 to save gas and represent values typically 0-1000 range
        uint16 complexity; // How complex the artifact is (higher = more potential for unique traits, but unstable)
        uint16 stability; // How stable the artifact is (higher = resists flux and decay, lower = prone to wild changes)
        uint16 chrononEnergy; // A dynamic energy source (decays over time, fuels advanced actions)
        uint16 rarityPotential; // Influences the likelihood of hitting beneficial outcomes during flux/evolution
    }

    // Mappings to store artifact data
    mapping(uint256 => ArtifactParameters) private _artifactParameters;
    mapping(uint256 => ArtifactParameters) private _artifactGenesisAttributes; // Store initial state
    mapping(uint256 => uint64) private _lastInteractionTime; // Timestamp of last interaction
    mapping(uint256 => bool) private _isCrystallized; // State if parameters are locked

    // Constants and adjustable parameters
    uint256 private _forgingCost = 0.01 ether; // Cost to mint an artifact
    uint256 private _chrononDecayRatePerSecond = 1; // Rate of chronon decay (e.g., 1 unit per hour, adjusted to per second for simplicity)
    // Note: 1 unit per hour -> 1 / 3600 per second. Using 1 is illustrative, a real rate would be much smaller.
    // Let's use a more realistic representation: decay per 15 minutes
    uint256 private constant DECAY_PERIOD_SECONDS = 15 * 60; // Decay occurs every 15 minutes
    uint256 private _chrononDecayAmountPerPeriod = 10; // Amount of chronon energy lost per decay period

    // Parameter limits (example values)
    uint16 private constant MAX_PARAMETER_VALUE = 1000;

    // Events
    event ArtifactForged(uint256 indexed tokenId, address indexed owner, ArtifactParameters initialParameters);
    event ParametersChanged(uint256 indexed tokenId, string changeType, ArtifactParameters newParameters);
    event ChrononDecayed(uint256 indexed tokenId, uint16 newChrononEnergy, uint256 decayAmount);
    event EvolutionAttempted(uint256 indexed tokenId, bool successful, string outcome);
    event ResonanceInitiated(uint256 indexed tokenId1, uint256 indexed tokenId2, ArtifactParameters newParams1, ArtifactParameters newParams2);
    event StateCrystallized(uint256 indexed tokenId);
    event ForgingCostUpdated(uint256 newCost);
    event ChrononDecayRateUpdated(uint256 newRate);

    // Errors
    error ArtifactNotFound(uint256 tokenId);
    error NotArtifactOwnerOrApproved(uint256 tokenId);
    error InsufficientPayment(uint256 required, uint256 sent);
    error ArtifactCrystallized(uint256 tokenId);
    error InvalidBias(uint16 complexityBias, uint16 stabilityBias);
    error InsufficientChrononEnergy(uint256 tokenId, uint16 required, uint16 current);
    error ArtifactsAlreadyInResonance(uint256 tokenId1, uint256 tokenId2); // Placeholder if we had state for resonance

    constructor() ERC721("Quantum Realm Artifact", "QRA") Ownable(msg.sender) {}

    // --- Internal Helpers ---

    // Get mutable reference to parameters - use with care!
    function _getArtifactParameters(uint256 tokenId) internal view returns (ArtifactParameters storage) {
         ArtifactParameters storage params = _artifactParameters[tokenId];
         if (params.complexity == 0 && params.stability == 0 && params.chrononEnergy == 0 && params.rarityPotential == 0 && _exists(tokenId)) {
             // This check handles the case where an artifact exists but parameters mapping wasn't correctly initialized
             // (shouldn't happen with current minting logic, but good defensive check)
             revert ArtifactNotFound(tokenId);
         } else if (!_exists(tokenId)) {
             revert ArtifactNotFound(tokenId);
         }
         return params;
    }


    // Helper to generate pseudo-randomness for initial parameters and flux
    // NOTE: This is *not* cryptographically secure and can be manipulated by miners.
    // For production systems requiring secure randomness, use Chainlink VRF or similar.
    function _generateEntropy(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, seed)));
    }

    // Apply chronon decay based on elapsed time
    function _applyChrononDecay(uint256 tokenId) internal {
        if (_isCrystallized[tokenId]) {
            return; // Crystallized artifacts don't decay chronon energy this way
        }

        uint64 lastInteraction = _lastInteractionTime[tokenId];
        if (lastInteraction == 0) {
            lastInteraction = uint64(block.timestamp); // Initialize if first interaction
        }

        uint256 elapsedSeconds = block.timestamp - lastInteraction;

        // Calculate number of decay periods passed
        uint256 decayPeriods = elapsedSeconds.div(DECAY_PERIOD_SECONDS);

        if (decayPeriods > 0) {
            ArtifactParameters storage params = _getArtifactParameters(tokenId);
            uint256 decayAmount = decayPeriods.mul(_chrononDecayAmountPerPeriod);

            uint16 oldChrononEnergy = params.chrononEnergy;
            params.chrononEnergy = uint16(uint256(params.chrononEnergy).sub(decayAmount > params.chrononEnergy ? params.chrononEnergy : decayAmount));

            if (oldChrononEnergy != params.chrononEnergy) {
                emit ChrononDecayed(tokenId, params.chrononEnergy, decayAmount);
                _lastInteractionTime[tokenId] = uint64(block.timestamp); // Update interaction time after decay
            }
            // If decayAmount was less than params.chrononEnergy, interaction time is updated below in the calling function
        }
    }

    // Update last interaction time for an artifact
    function _updateLastInteractionTime(uint256 tokenId) internal {
        _lastInteractionTime[tokenId] = uint64(block.timestamp);
    }

    // Check if sender is owner or approved for the token
    modifier isArtifactOwnerOrApproved(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender && getApproved(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender)) {
            revert NotArtifactOwnerOrApproved(tokenId);
        }
        _;
    }

    // Check if artifact exists
    modifier artifactExists(uint256 tokenId) {
        if (!_exists(tokenId)) {
            revert ArtifactNotFound(tokenId);
        }
        _;
    }

    // Ensure artifact is not crystallized for certain operations
    modifier notCrystallized(uint256 tokenId) {
        if (_isCrystallized[tokenId]) {
            revert ArtifactCrystallized(tokenId);
        }
        _;
    }

    // --- ERC721 Overrides ---

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        // In a real contract, this would return a URI pointing to metadata (e.g., JSON file)
        // which could include dynamic traits fetched from getDynamicTraits.
        // For this example, we'll just return a placeholder.
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked("ipfs://YOUR_METADATA_CID/", Strings.toString(tokenId), ".json"));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return interfaceId == type(ERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function _update(address to, uint256 tokenId, address auth) internal virtual override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint256 value) internal virtual override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    // --- Core Forging Functions (1, 2, 3) ---

    /// @notice Mints a new Quantum Realm Artifact.
    /// @dev Initializes parameters based on pseudo-randomness.
    function forgeArtifact() public payable {
        if (msg.value < _forgingCost) {
            revert InsufficientPayment(_forgingCost, msg.value);
        }

        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(msg.sender, newTokenId);

        uint256 entropy = _generateEntropy(newTokenId);

        ArtifactParameters memory initialParams;
        initialParams.complexity = uint16((entropy % 200) + 100); // Base complexity
        initialParams.stability = uint16(((entropy >> 16) % 200) + 100); // Base stability
        initialParams.chrononEnergy = uint16(((entropy >> 32) % 300) + 200); // Initial energy
        initialParams.rarityPotential = uint16(((entropy >> 48) % 100) + 50); // Initial rarity pot

        _artifactParameters[newTokenId] = initialParams;
        _artifactGenesisAttributes[newTokenId] = initialParams; // Store genesis state
        _updateLastInteractionTime(newTokenId);

        emit ArtifactForged(newTokenId, msg.sender, initialParams);
    }

    /// @notice Mints a new artifact allowing bias in initial complexity/stability.
    /// @param complexityBias A value (e.g., 0-100) to bias initial complexity.
    /// @param stabilityBias A value (e.g., 0-100) to bias initial stability.
    /// @dev Requires higher cost and biases initial parameters based on provided inputs.
    function forgeArtifactWithBias(uint16 complexityBias, uint16 stabilityBias) public payable {
        uint256 biasedCost = _forgingCost.mul(120).div(100); // 20% higher cost for bias
        if (msg.value < biasedCost) {
            revert InsufficientPayment(biasedCost, msg.value);
        }
        if (complexityBias > 100 || stabilityBias > 100) {
             revert InvalidBias(complexityBias, stabilityBias);
        }


        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(msg.sender, newTokenId);

        uint256 entropy = _generateEntropy(newTokenId + 1); // Use different seed

        ArtifactParameters memory initialParams;
        // Apply bias: shift base range based on bias input
        initialParams.complexity = uint16((entropy % 150) + 100 + complexityBias);
        initialParams.stability = uint16(((entropy >> 16) % 150) + 100 + stabilityBias);
        initialParams.chrononEnergy = uint16(((entropy >> 32) % 300) + 150);
        initialParams.rarityPotential = uint16(((entropy >> 48) % 80) + 40);

        // Ensure parameters don't exceed max (simple cap)
        initialParams.complexity = initialParams.complexity > MAX_PARAMETER_VALUE ? MAX_PARAMETER_VALUE : initialParams.complexity;
        initialParams.stability = initialParams.stability > MAX_PARAMETER_VALUE ? MAX_PARAMETER_VALUE : initialParams.stability;
        initialParams.chrononEnergy = initialParams.chrononEnergy > MAX_PARAMETER_VALUE ? MAX_PARAMETER_VALUE : initialParams.chrononEnergy;
        initialParams.rarityPotential = initialParams.rarityPotential > MAX_PARAMETER_VALUE ? MAX_PARAMETER_VALUE : initialParams.rarityPotential;


        _artifactParameters[newTokenId] = initialParams;
        _artifactGenesisAttributes[newTokenId] = initialParams;
        _updateLastInteractionTime(newTokenId);

        emit ArtifactForged(newTokenId, msg.sender, initialParams);
    }

    /// @notice Mints multiple artifacts in a single transaction.
    /// @param count The number of artifacts to mint.
    /// @dev Max count can be limited to prevent gas issues. Requires `count * _forgingCost` payment.
    function batchForgeArtifacts(uint256 count) public payable {
        require(count > 0 && count <= 10, "Max 10 artifacts per batch"); // Limit batch size
        uint256 totalCost = _forgingCost.mul(count);
         if (msg.value < totalCost) {
            revert InsufficientPayment(totalCost, msg.value);
        }

        for (uint256 i = 0; i < count; i++) {
            uint256 newTokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();

            _safeMint(msg.sender, newTokenId);

            uint256 entropy = _generateEntropy(newTokenId);

            ArtifactParameters memory initialParams;
            initialParams.complexity = uint16((entropy % 200) + 100);
            initialParams.stability = uint16(((entropy >> 16) % 200) + 100);
            initialParams.chrononEnergy = uint16(((entropy >> 32) % 300) + 200);
            initialParams.rarityPotential = uint16(((entropy >> 48) % 100) + 50);

            _artifactParameters[newTokenId] = initialParams;
            _artifactGenesisAttributes[newTokenId] = initialParams;
            _updateLastInteractionTime(newTokenId);

            emit ArtifactForged(newTokenId, msg.sender, initialParams);
        }
    }

    // --- Query Functions (5, 6, 7, 20, 22, 23) ---

    /// @notice Gets the current parameters of an artifact.
    /// @param tokenId The ID of the artifact.
    /// @return A struct containing the artifact's current parameters.
    function getArtifactParameters(uint256 tokenId) public view artifactExists(tokenId) returns (ArtifactParameters memory) {
        // Apply decay state before returning, but don't save state in a view function
        ArtifactParameters memory currentParams = _artifactParameters[tokenId];
        if (!_isCrystallized[tokenId]) {
             uint64 lastInteraction = _lastInteractionTime[tokenId];
             if (lastInteraction == 0) { lastInteraction = uint64(block.timestamp); } // Handle uninitialized

             uint256 elapsedSeconds = block.timestamp - lastInteraction;
             uint256 decayPeriods = elapsedSeconds.div(DECAY_PERIOD_SECONDS);
             uint256 decayAmount = decayPeriods.mul(_chrononDecayAmountPerPeriod);

            currentParams.chrononEnergy = uint16(uint256(currentParams.chrononEnergy).sub(decayAmount > currentParams.chrononEnergy ? currentParams.chrononEnergy : decayAmount));
        }
        return currentParams;
    }

    /// @notice Gets the initial parameters of an artifact when it was forged.
    /// @param tokenId The ID of the artifact.
    /// @return A struct containing the artifact's genesis attributes.
    function getArtifactGenesisAttributes(uint256 tokenId) public view artifactExists(tokenId) returns (ArtifactParameters memory) {
        return _artifactGenesisAttributes[tokenId];
    }

    /// @notice Calculates dynamic traits based on current artifact parameters.
    /// @param tokenId The ID of the artifact.
    /// @return An array of strings representing the artifact's current traits.
    function getDynamicTraits(uint256 tokenId) public view artifactExists(tokenId) returns (string[] memory) {
        ArtifactParameters memory params = getArtifactParameters(tokenId); // Get potentially decayed parameters

        string[] memory traits = new string[](4); // Max 4 simple traits for demo

        // Example trait logic
        if (params.complexity > 700 && params.stability < 300) {
            traits[0] = "Volatile";
        } else if (params.complexity > 700) {
            traits[0] = "Intricate";
        } else if (params.complexity < 300) {
            traits[0] = "Simple";
        } else {
            traits[0] = "Balanced Complexity";
        }

        if (params.stability > 700 && params.chrononEnergy > 500) {
            traits[1] = "Resilient";
        } else if (params.stability > 700) {
            traits[1] = "Stable";
        } else if (params.stability < 300) {
            traits[1] = "Unstable";
        } else {
            traits[1] = "Normal Stability";
        }

        if (params.chrononEnergy > 700) {
            traits[2] = "Radiant";
        } else if (params.chrononEnergy > 400) {
             traits[2] = "Charged";
        } else if (params.chrononEnergy < 100) {
            traits[2] = "Depleted";
        } else {
             traits[2] = "Energetic";
        }

         if (params.rarityPotential > 700) {
            traits[3] = "Mythic Potential";
        } else if (params.rarityPotential > 500) {
             traits[3] = "Rare Potential";
        } else {
             traits[3] = "Standard Potential";
        }

        // Filter out empty strings if not all slots are used
        uint256 traitCount = 0;
        for(uint i = 0; i < traits.length; i++) {
            if(bytes(traits[i]).length > 0) {
                traitCount++;
            }
        }

        string[] memory filteredTraits = new string[](traitCount);
        uint256 currentIdx = 0;
         for(uint i = 0; i < traits.length; i++) {
            if(bytes(traits[i]).length > 0) {
                filteredTraits[currentIdx] = traits[i];
                currentIdx++;
            }
        }

        return filteredTraits;
    }

    /// @notice Returns the timestamp of the last interaction with the artifact.
    /// @param tokenId The ID of the artifact.
    function getArtifactLastInteractionTime(uint256 tokenId) public view artifactExists(tokenId) returns (uint64) {
        return _lastInteractionTime[tokenId];
    }

     /// @notice Returns the current cost to forge an artifact.
    function getForgingCost() public view returns (uint256) {
        return _forgingCost;
    }

    /// @notice Returns the current chronon energy decay rate (amount per period).
    function getChrononDecayRate() public view returns (uint256) {
        return _chrononDecayAmountPerPeriod;
    }

    /// @notice Returns the total number of artifacts minted.
    function getTotalArtifactSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }


    // --- Interaction & Evolution Functions (8-16) ---

    /// @notice Infuses chronon energy into an artifact.
    /// @param tokenId The ID of the artifact.
    /// @dev Requires payment.
    function infuseChrononEnergy(uint256 tokenId) public payable artifactExists(tokenId) isArtifactOwnerOrApproved(tokenId) notCrystallized(tokenId) {
        // Example cost to infuse energy
        uint256 infusionCost = _forgingCost.div(5); // 20% of forging cost
         if (msg.value < infusionCost) {
            revert InsufficientPayment(infusionCost, msg.value);
        }

        // Apply decay before infusing
        _applyChrononDecay(tokenId);

        ArtifactParameters storage params = _getArtifactParameters(tokenId);

        // Increase energy, cap at MAX_PARAMETER_VALUE
        params.chrononEnergy = uint16(uint256(params.chrononEnergy).add(150).min(MAX_PARAMETER_VALUE));

        _updateLastInteractionTime(tokenId);
        emit ParametersChanged(tokenId, "Chronon Infusion", params);
    }

     /// @notice Stabilizes an artifact, increasing stability and slightly decreasing complexity.
    /// @param tokenId The ID of the artifact.
    /// @dev Requires payment.
    function stabilizeArtifact(uint256 tokenId) public payable artifactExists(tokenId) isArtifactOwnerOrApproved(tokenId) notCrystallized(tokenId) {
        uint256 stabilityCost = _forgingCost.div(4); // 25% of forging cost
         if (msg.value < stabilityCost) {
            revert InsufficientPayment(stabilityCost, msg.value);
        }

         // Apply decay first
        _applyChrononDecay(tokenId);

        ArtifactParameters storage params = _getArtifactParameters(tokenId);

        // Increase stability, cap at MAX_PARAMETER_VALUE
        params.stability = uint16(uint256(params.stability).add(100).min(MAX_PARAMETER_VALUE));

        // Slight complexity reduction as a trade-off, minimum 0
        params.complexity = uint16(uint256(params.complexity).sub(uint256(params.complexity).mul(5).div(100))); // Reduce complexity by 5%


        _updateLastInteractionTime(tokenId);
        emit ParametersChanged(tokenId, "Stabilization", params);
    }

    /// @notice Introduces complexity to an artifact, increasing complexity and slightly decreasing stability.
    /// @param tokenId The ID of the artifact.
    /// @dev Requires payment and sufficient chronon energy.
    function introduceComplexity(uint256 tokenId) public payable artifactExists(tokenId) isArtifactOwnerOrApproved(tokenId) notCrystallized(tokenId) {
        uint256 complexityCost = _forgingCost.div(3); // 33% of forging cost
         if (msg.value < complexityCost) {
            revert InsufficientPayment(complexityCost, msg.value);
        }

         // Apply decay first
        _applyChrononDecay(tokenId);

        ArtifactParameters storage params = _getArtifactParameters(tokenId);

        uint16 requiredEnergy = 200; // Example energy cost
        if (params.chrononEnergy < requiredEnergy) {
            revert InsufficientChrononEnergy(tokenId, requiredEnergy, params.chrononEnergy);
        }
        params.chrononEnergy = uint16(uint256(params.chrononEnergy).sub(requiredEnergy));

        // Increase complexity, cap at MAX_PARAMETER_VALUE
        params.complexity = uint16(uint256(params.complexity).add(120).min(MAX_PARAMETER_VALUE));

        // Slight stability reduction as a trade-off, minimum 0
         params.stability = uint16(uint256(params.stability).sub(uint256(params.stability).mul(7).div(100))); // Reduce stability by 7%


        _updateLastInteractionTime(tokenId);
        emit ParametersChanged(tokenId, "Complexity Introduction", params);
    }

    /// @notice Attempts to attune the rarity potential of an artifact.
    /// @param tokenId The ID of the artifact.
    /// @dev More expensive/rare action.
    function attuneRarityPotential(uint256 tokenId) public payable artifactExists(tokenId) isArtifactOwnerOrApproved(tokenId) {
        // This action might not be tied to crystallization state, as it's about future potential
        uint256 rarityCost = _forgingCost.mul(2); // 200% of forging cost
         if (msg.value < rarityCost) {
            revert InsufficientPayment(rarityCost, msg.value);
        }

        // Apply decay first (rarity attunement needs energy)
        _applyChrononDecay(tokenId);

        ArtifactParameters storage params = _getArtifactParameters(tokenId);

        uint16 requiredEnergy = 300; // Example energy cost
        if (params.chrononEnergy < requiredEnergy) {
            revert InsufficientChrononEnergy(tokenId, requiredEnergy, params.chrononEnergy);
        }
        params.chrononEnergy = uint16(uint256(params.chrononEnergy).sub(requiredEnergy));


        // Increase rarity potential based on current state and some entropy
        uint256 entropy = _generateEntropy(tokenId + block.timestamp);
        uint16 rarityBoost = uint16((entropy % 50) + (params.chrononEnergy / 20) + (params.stability / 30)); // Boost affected by energy and stability

        params.rarityPotential = uint16(uint256(params.rarityPotential).add(rarityBoost).min(MAX_PARAMETER_VALUE));

        _updateLastInteractionTime(tokenId);
        emit ParametersChanged(tokenId, "Rarity Attunement", params);
    }


    /// @notice Triggers a quantum flux event, causing significant, pseudo-random parameter changes.
    /// @param tokenId The ID of the artifact.
    /// @dev Consumes chronon energy and is influenced by stability/complexity/rarityPotential.
    function triggerQuantumFlux(uint256 tokenId) public artifactExists(tokenId) isArtifactOwnerOrApproved(tokenId) notCrystallized(tokenId) {
         // Apply decay first
        _applyChrononDecay(tokenId);

        ArtifactParameters storage params = _getArtifactParameters(tokenId);

        uint16 requiredEnergy = 250; // Example energy cost
        if (params.chrononEnergy < requiredEnergy) {
            revert InsufficientChrononEnergy(tokenId, requiredEnergy, params.chrononEnergy);
        }
        params.chrononEnergy = uint16(uint256(params.chrononEnergy).sub(requiredEnergy));

        // --- Quantum Flux Logic (Simulated) ---
        // This is the core dynamic mechanism. Parameters shift based on current state, rarity, and entropy.
        uint256 entropy = _generateEntropy(tokenId + block.timestamp + params.complexity + params.stability);

        int256 complexityChange = int256((entropy % 200) - 100); // Random change -100 to +100
        int256 stabilityChange = int256(((entropy >> 16) % 200) - 100);
        int256 chrononChange = int256(((entropy >> 32) % 100) - 50); // Smaller random change
        int256 rarityChange = int256(((entropy >> 48) % 50) - 25); // Smaller random change

        // Influence changes based on parameters
        // Low stability -> wider swings
        if (params.stability < 400) {
             complexityChange = complexityChange * 150 / 100; // 50% larger swings
             stabilityChange = stabilityChange * 150 / 100;
        } else if (params.stability > 700) {
            // High stability -> smaller swings, bias towards stability gain
             complexityChange = complexityChange * 50 / 100; // 50% smaller swings
             stabilityChange = (stabilityChange * 50 / 100) + 30; // Bias towards positive stability
        }

        // High complexity -> wider swings, bias towards complexity gain
         if (params.complexity > 700) {
             complexityChange = (complexityChange * 150 / 100) + 30; // Bias towards positive complexity
             stabilityChange = stabilityChange * 150 / 100;
        }

        // Rarity potential influences the *chance* of a highly beneficial outcome
        uint256 rarityRoll = (entropy >> 64) % 1000;
        if (rarityRoll < params.rarityPotential) { // Higher chance with higher rarityPotential
             // Apply a positive bias to changes if rarity roll succeeds
             if (complexityChange < 50) complexityChange = 50 + int256(entropy % 50);
             if (stabilityChange < 50) stabilityChange = 50 + int256((entropy >> 8) % 50);
             if (chrononChange < 30) chrononChange = 30 + int256((entropy >> 16) % 30);
             if (rarityChange < 20) rarityChange = 20 + int256((entropy >> 24) % 20);
         }


        // Apply changes, ensuring results stay within [0, MAX_PARAMETER_VALUE]
        params.complexity = uint16(int256(params.complexity).add(complexityChange).max(0).min(MAX_PARAMETER_VALUE));
        params.stability = uint16(int256(params.stability).add(stabilityChange).max(0).min(MAX_PARAMETER_VALUE));
        params.chrononEnergy = uint16(int256(params.chrononEnergy).add(chrononChange).max(0).min(MAX_PARAMETER_VALUE));
        params.rarityPotential = uint16(int256(params.rarityPotential).add(rarityChange).max(0).min(MAX_PARAMETER_VALUE));

        // --- End Quantum Flux Logic ---

        _updateLastInteractionTime(tokenId);
        emit ParametersChanged(tokenId, "Quantum Flux", params);
    }

     /// @notice Calculates a *potential* outcome of triggerQuantumFlux without state change.
    /// @param tokenId The ID of the artifact.
    /// @dev Pure/view function for simulation purposes. Uses pseudo-randomness so multiple calls will differ.
    /// NOTE: This is *not* guaranteed to be the *actual* result if called later, due to block variations.
    function queryPotentialFluxResult(uint256 tokenId) public view artifactExists(tokenId) returns (ArtifactParameters memory potentialParams) {
        ArtifactParameters memory params = getArtifactParameters(tokenId); // Get potentially decayed parameters

        // Simulate flux logic as in triggerQuantumFlux
        uint256 entropy = _generateEntropy(tokenId + block.timestamp + params.complexity + params.stability + 999); // Different seed for preview

        int256 complexityChange = int256((entropy % 200) - 100);
        int256 stabilityChange = int256(((entropy >> 16) % 200) - 100);
        int256 chrononChange = int256(((entropy >> 32) % 100) - 50);
        int256 rarityChange = int256(((entropy >> 48) % 50) - 25);

        // Influence changes based on parameters (same logic as flux)
        if (params.stability < 400) {
             complexityChange = complexityChange * 150 / 100;
             stabilityChange = stabilityChange * 150 / 100;
        } else if (params.stability > 700) {
             complexityChange = complexityChange * 50 / 100;
             stabilityChange = (stabilityChange * 50 / 100) + 30;
        }
         if (params.complexity > 700) {
             complexityChange = (complexityChange * 150 / 100) + 30;
             stabilityChange = stabilityChange * 150 / 100;
        }

        uint256 rarityRoll = (entropy >> 64) % 1000;
        if (rarityRoll < params.rarityPotential) {
             if (complexityChange < 50) complexityChange = 50 + int256(entropy % 50);
             if (stabilityChange < 50) stabilityChange = 50 + int256((entropy >> 8) % 50);
             if (chrononChange < 30) chrononChange = 30 + int256((entropy >> 16) % 30);
             if (rarityChange < 20) rarityChange = 20 + int256((entropy >> 24) % 20);
         }

        // Calculate potential parameters (excluding energy cost for preview)
        potentialParams.complexity = uint16(int256(params.complexity).add(complexityChange).max(0).min(MAX_PARAMETER_VALUE));
        potentialParams.stability = uint16(int256(params.stability).add(stabilityChange).max(0).min(MAX_PARAMETER_VALUE));
        potentialParams.chrononEnergy = uint16(int256(params.chrononEnergy).add(chrononChange).max(0).min(MAX_PARAMETER_VALUE)); // Show potential energy change
        potentialParams.rarityPotential = uint16(int256(params.rarityPotential).add(rarityChange).max(0).min(MAX_PARAMETER_VALUE));

        return potentialParams;
    }


    /// @notice Allows anyone to trigger chronon decay for an artifact.
    /// @param tokenId The ID of the artifact.
    /// @dev This is designed to be callable by anyone to incentivize keeping decay up-to-date off-chain,
    ///      though no explicit ETH reward is included in this basic version.
    function decayChrononEnergy(uint256 tokenId) public artifactExists(tokenId) {
         // Anyone can call this to keep the state updated
         _applyChrononDecay(tokenId);
         // Note: _applyChrononDecay updates the last interaction time if decay occurred.
    }


    /// @notice Attempts to trigger an evolutionary event for an artifact.
    /// @param tokenId The ID of the artifact.
    /// @dev Requires specific parameter thresholds and consumes resources. Outcome can vary.
    function attemptEvolution(uint256 tokenId) public artifactExists(tokenId) isArtifactOwnerOrApproved(tokenId) notCrystallized(tokenId) {
         // Apply decay first
        _applyChrononDecay(tokenId);

        ArtifactParameters storage params = _getArtifactParameters(tokenId);

        uint16 requiredEnergy = 400;
        uint16 requiredStability = 500;
        uint16 requiredComplexity = 500;

        bool conditionsMet = params.chrononEnergy >= requiredEnergy &&
                             params.stability >= requiredStability &&
                             params.complexity >= requiredComplexity;

        string memory outcome;
        bool successful = false;

        if (conditionsMet) {
            // Consume resources
            params.chrononEnergy = uint16(uint256(params.chrononEnergy).sub(requiredEnergy));
            params.stability = uint16(uint256(params.stability).sub(requiredStability/2)); // Half stability cost

            // Apply a large parameter shift based on rarityPotential and entropy
            uint256 entropy = _generateEntropy(tokenId + block.timestamp + 777);
            uint256 rarityInfluence = uint256(params.rarityPotential);

            int256 complexityBoost = int256((entropy % 300) + rarityInfluence / 3); // Boost influenced by rarity
            int256 stabilityBoost = int256(((entropy >> 16) % 300) + rarityInfluence / 3);
            int256 energyBoost = int256(((entropy >> 32) % 200) + rarityInfluence / 2);
            int256 rarityBoost = int256(((entropy >> 48) % 100) + rarityInfluence / 4);

             // Apply changes, ensuring results stay within [0, MAX_PARAMETER_VALUE]
            params.complexity = uint16(int256(params.complexity).add(complexityBoost).max(0).min(MAX_PARAMETER_VALUE));
            params.stability = uint16(int256(params.stability).add(stabilityBoost).max(0).min(MAX_PARAMETER_VALUE));
            params.chrononEnergy = uint16(int256(params.chrononEnergy).add(energyBoost).max(0).min(MAX_PARAMETER_VALUE));
            params.rarityPotential = uint16(int256(params.rarityPotential).add(rarityBoost).max(0).min(MAX_PARAMETER_VALUE));

            successful = true;
            outcome = "Success";

             // Potentially unlock new features or ranges for this artifact?
             // Example: Could set a flag _isEvolved[tokenId] = true; and change trait logic in getDynamicTraits

        } else {
            // Evolution failed - minor parameter penalty
             uint256 entropy = _generateEntropy(tokenId + block.timestamp + 888);
             params.chrononEnergy = uint16(uint256(params.chrononEnergy).sub(uint256(params.chrononEnergy).mul(10).div(100)).max(0)); // Lose 10% energy
             params.stability = uint16(uint256(params.stability).sub(uint16((entropy % 50) + 20)).max(0)); // Lose some stability

            successful = false;
            outcome = "Failure";
        }

        _updateLastInteractionTime(tokenId);
        emit EvolutionAttempted(tokenId, successful, outcome);
        emit ParametersChanged(tokenId, "Evolution Attempt", params);
    }

    /// @notice Crystallizes an artifact's state, locking complexity and stability.
    /// @param tokenId The ID of the artifact.
    /// @dev Requires high cost/energy. Prevents future decay/flux on complexity/stability. Chronon still decays.
    function crystallizeState(uint256 tokenId) public payable artifactExists(tokenId) isArtifactOwnerOrApproved(tokenId) notCrystallized(tokenId) {
         uint256 crystallizeCost = _forgingCost.mul(3); // 300% of forging cost
         if (msg.value < crystallizeCost) {
            revert InsufficientPayment(crystallizeCost, msg.value);
        }

         // Apply decay first
        _applyChrononDecay(tokenId);

        ArtifactParameters storage params = _getArtifactParameters(tokenId);

        uint16 requiredEnergy = 600; // Example energy cost
        if (params.chrononEnergy < requiredEnergy) {
            revert InsufficientChrononEnergy(tokenId, requiredEnergy, params.chrononEnergy);
        }
         params.chrononEnergy = uint16(uint256(params.chrononEnergy).sub(requiredEnergy));


        _isCrystallized[tokenId] = true; // Set crystallization flag

        _updateLastInteractionTime(tokenId);
        emit StateCrystallized(tokenId);
         emit ParametersChanged(tokenId, "Crystallization", params); // Parameters are now locked
    }

    /// @notice Initiates a resonance between two artifacts, modifying their parameters.
    /// @param tokenId1 The ID of the first artifact.
    /// @param tokenId2 The ID of the second artifact.
    /// @dev Requires ownership/approval for both tokens. Parameters change based on a defined logic.
    function initiateResonance(uint256 tokenId1, uint256 tokenId2) public artifactExists(tokenId1) artifactExists(tokenId2) {
        require(tokenId1 != tokenId2, "Cannot resonate an artifact with itself");

        // Check ownership/approval for BOTH tokens
        bool senderIsOwner1 = ownerOf(tokenId1) == msg.sender;
        bool senderIsApproved1 = getApproved(tokenId1) == msg.sender || isApprovedForAll(ownerOf(tokenId1), msg.sender);

        bool senderIsOwner2 = ownerOf(tokenId2) == msg.sender;
        bool senderIsApproved2 = getApproved(tokenId2) == msg.sender || isApprovedForAll(ownerOf(tokenId2), msg.sender);

        require((senderIsOwner1 || senderIsApproved1) && (senderIsOwner2 || senderIsApproved2), "Sender must be owner or approved for both artifacts");

         // Apply decay first to both
        _applyChrononDecay(tokenId1);
        _applyChrononDecay(tokenId2);

        ArtifactParameters storage params1 = _getArtifactParameters(tokenId1);
        ArtifactParameters storage params2 = _getArtifactParameters(tokenId2);

         // Example Resonance Logic: Parameters tend towards the average, but with influence from Rarity Potential
         // Consume some energy from both
         uint16 energyCostPer = 100;
         if (params1.chrononEnergy < energyCostPer || params2.chrononEnergy < energyCostPer) {
             revert InsufficientChrononEnergy(params1.chrononEnergy < energyCostPer ? tokenId1 : tokenId2, energyCostPer, params1.chrononEnergy < energyCostPer ? params1.chrononEnergy : params2.chrononEnergy);
         }
         params1.chrononEnergy = uint16(uint256(params1.chrononEnergy).sub(energyCostPer));
         params2.chrononEnergy = uint16(uint256(params2.chrononEnergy).sub(energyCostPer));


        uint16 avgComplexity = uint16((uint256(params1.complexity) + params2.complexity) / 2);
        uint16 avgStability = uint16((uint256(params1.stability) + params2.stability) / 2);
        uint16 avgRarity = uint16((uint256(params1.rarityPotential) + params2.rarityPotential) / 2);

        // Influence of rarity: higher combined rarity potential pulls parameters towards higher values slightly
        uint16 rarityInfluenceAmount = (params1.rarityPotential + params2.rarityPotential) / 20; // Example influence

        // Apply changes, capping at MAX_PARAMETER_VALUE
        params1.complexity = uint16(uint256(params1.complexity).add(avgComplexity).add(rarityInfluenceAmount).div(2).min(MAX_PARAMETER_VALUE));
        params2.complexity = uint16(uint256(params2.complexity).add(avgComplexity).add(rarityInfluenceAmount).div(2).min(MAX_PARAMETER_VALUE));

        params1.stability = uint16(uint256(params1.stability).add(avgStability).add(rarityInfluenceAmount).div(2).min(MAX_PARAMETER_VALUE));
        params2.stability = uint16(uint256(params2.stability).add(avgStability).add(rarityInfluenceAmount).div(2).min(MAX_PARAMETER_VALUE));

         params1.rarityPotential = uint16(uint256(params1.rarityPotential).add(avgRarity).add(rarityInfluenceAmount).div(2).min(MAX_PARAMETER_VALUE));
        params2.rarityPotential = uint16(uint256(params2.rarityPotential).add(avgRarity).add(rarityInfluenceAmount).div(2).min(MAX_PARAMETER_VALUE));


        _updateLastInteractionTime(tokenId1);
        _updateLastInteractionTime(tokenId2);

        emit ResonanceInitiated(tokenId1, tokenId2, params1, params2);
         emit ParametersChanged(tokenId1, "Resonance", params1);
         emit ParametersChanged(tokenId2, "Resonance", params2);
    }

    // --- Owner Functions (18, 19, 24) ---

    /// @notice Sets the cost to forge a new artifact.
    /// @param newCost The new cost in Wei.
    function setForgingCost(uint256 newCost) public onlyOwner {
        _forgingCost = newCost;
        emit ForgingCostUpdated(newCost);
    }

    /// @notice Sets the amount of chronon energy decayed per decay period.
    /// @param amountPerPeriod The new decay amount per period.
    function setChrononDecayRate(uint256 amountPerPeriod) public onlyOwner {
        _chrononDecayAmountPerPeriod = amountPerPeriod;
        emit ChrononDecayRateUpdated(amountPerPeriod);
    }

    /// @notice Allows the contract owner to withdraw accumulated ETH.
    function withdrawFunds() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    // --- Standard ERC721 Functions (inherited/overridden) ---
    // 25. renounceOwnership() is inherited from Ownable.

    // The following functions are standard ERC721 and overridden from OpenZeppelin:
    // balanceOf(address owner)
    // ownerOf(uint256 tokenId)
    // approve(address to, uint256 tokenId)
    // getApproved(uint256 tokenId)
    // setApprovalForAll(address operator, bool approved)
    // isApprovedForAll(address owner, address operator)
    // transferFrom(address from, address to, uint256 tokenId)
    // safeTransferFrom(address from, address to, uint256 tokenId)
    // safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)

    // ERC721Enumerable overrides:
    // totalSupply()
    // tokenOfOwnerByIndex(address owner, uint256 index)
    // tokenByIndex(uint256 index)

}
```