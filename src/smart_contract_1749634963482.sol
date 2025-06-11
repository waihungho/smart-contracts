Okay, here is a Solidity smart contract concept called `DigitalDreamWeaver`.

This contract creates unique, dynamic digital "dreams" represented as NFTs. These dreams aren't static images; they have internal states (mood, complexity, vibrancy, energy) and can influence each other through a defined graph structure. The core advanced concepts include:

1.  **Dynamic State NFTs:** Tokens with mutable attributes stored on-chain, not just a pointer to off-chain metadata.
2.  **Influence Graph:** Dreams can form directional links, where one dream's state can influence another's during simulation steps.
3.  **Simulated Evolution:** A mechanism (`simulateTimeStep`) where dream states evolve based on internal parameters, influence from others, and external factors (like block data).
4.  **Interactive Modification:** Functions allowing owners (or approved users) to attempt to steer a dream's state or combine aspects of multiple dreams.
5.  **Configurable Mechanics:** Owner can set parameters that affect global simulation or how individual dreams respond.
6.  **Procedural Seed:** Each dream has a seed that can be used off-chain for consistent visual generation based on its *current* on-chain state.

---

## DigitalDreamWeaver: Contract Outline & Function Summary

This contract manages a collection of dynamic, interactive digital 'Dreams' as ERC721 tokens.

**Concept:** Dreams are non-fungible tokens (NFTs) with mutable on-chain attributes (mood, complexity, energy, etc.) that can influence each other and evolve over time through simulation steps.

**Core Structure:**
*   `Dream` struct: Holds all on-chain attributes for a dream token.
*   Influence Mappings: Stores directional links between dreams.
*   Parameters: Stores global and per-dream configuration for evolution and interactions.

**Key Features:**
*   **Dream Weaving (Minting):** Create new dreams, potentially influenced by existing ones.
*   **State Interaction:** Modify dream attributes through various functions (attune mood, infuse energy, blend palettes, etc.).
*   **Influence Management:** Create and remove links between dreams.
*   **Evolution Simulation:** Trigger steps that evolve dream states based on defined rules and influence graphs.
*   **Configuration:** Owner can fine-tune aspects of the system and dream evolution.
*   **Metadata:** Dynamic `tokenURI` reflecting the current on-chain state of the dream.

**Function Summary (20+ Functions):**

**Core ERC721 (Inherited/Overridden):**
1.  `balanceOf(address owner) view`: Get number of dreams owned by an address. (Standard)
2.  `ownerOf(uint256 tokenId) view`: Get owner of a specific dream. (Standard)
3.  `approve(address to, uint256 tokenId)`: Approve another address to transfer a dream. (Standard)
4.  `getApproved(uint256 tokenId) view`: Get the approved address for a dream. (Standard)
5.  `setApprovalForAll(address operator, bool approved)`: Approve/disapprove operator for all dreams. (Standard)
6.  `isApprovedForAll(address owner, address operator) view`: Check if an operator is approved. (Standard)
7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfer dream (requires approval). (Standard)
8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer (checks receiver). (Standard, often overloaded)
9.  `tokenURI(uint256 tokenId) view`: Get the URI for the dream's metadata (Overridden to be dynamic).
10. `supportsInterface(bytes4 interfaceId) view`: ERC165 interface support check. (Standard)
11. `name() view`: Contract name. (Standard)
12. `symbol() view`: Contract symbol. (Standard)

**Dream Weaving (Minting):**
13. `weaveNewDream(string memory initialMoodHint) payable`: Creates a new dream with initial parameters influenced by a hint and contract state.
14. `weaveFromInfluence(uint256 influentialDreamId) payable`: Creates a new dream influenced by the state of an existing dream.
15. `dissipateDream(uint256 tokenId)`: Allows the owner to destroy (burn) a dream.

**State Interaction & Modification:**
16. `attuneMood(uint256 tokenId, uint8 targetMood) payable`: Attempts to shift a dream's mood towards a target, with probabilistic outcome.
17. `infuseEnergy(uint256 tokenId) payable`: Increases a dream's energy level.
18. `blendPalettes(uint256 tokenId1, uint256 tokenId2, uint256 targetTokenId) payable`: Blends the color palettes of two dreams into a third target dream (must own all three).
19. `increaseComplexity(uint256 tokenId) payable`: Attempts to increase a dream's complexity.
20. `scrambleParameters(uint256 tokenId) payable`: Introduces high randomness/chaos to a dream's attributes.
21. `anchorDream(uint256 tokenId) payable`: Marks a dream as 'anchored', making it resistant to certain state changes during simulation.
22. `releaseDream(uint256 tokenId)`: Removes the 'anchored' status.

**Influence Graph Management:**
23. `addInfluenceLink(uint256 sourceDreamId, uint256 targetDreamId)`: Creates a directional influence link (source -> target). Must own both.
24. `removeInfluenceLink(uint256 sourceDreamId, uint256 targetDreamId)`: Removes an existing influence link. Must own both.
25. `fortifyInfluence(uint256 sourceDreamId, uint256 targetDreamId) payable`: Attempts to make an existing influence link stronger (affects simulation).

**Evolution & Simulation:**
26. `simulateTimeStep(uint256 tokenId) payable`: Triggers a simulation step for a specific dream, evolving its state based on its parameters, influences, and block data.
27. `triggerEvolution(uint256 tokenId) payable`: Attempts to trigger a significant evolutionary jump for a dream based on its current state.
28. `triggerCascadeInfluence(uint256 startDreamId, uint8 maxDepth) payable`: Triggers simulation steps cascading through the influence graph starting from a dream, up to a max depth. (Potentially gas-intensive, needs limits).
29. `syncDreamWithBlock(uint256 tokenId) payable`: Integrates recent block data (hash, number, timestamp) into a dream's state, potentially causing minor fluctuations or parameter changes.

**Configuration & Utilities (Owner/Admin):**
30. `setEvolutionParameters(uint256 tokenId, uint16 mutationRate, uint16 sensitivityToInfluence, uint16 decayRate)`: Owner sets evolution parameters for a specific dream.
31. `setGlobalDreamParameter(uint8 paramType, uint256 value)`: Owner sets a global parameter affecting all dreams (e.g., base decay rate, influence weight).
32. `setInteractionCost(uint8 interactionType, uint256 cost)`: Owner sets the ETH cost required for certain interactions.
33. `pauseWeaving(bool paused)`: Owner can pause dream minting.
34. `pauseSimulations(bool paused)`: Owner can pause simulation functions.
35. `withdrawFees(address recipient)`: Owner can withdraw collected ETH fees.

**Read Functions (State Query):**
36. `getDreamDetails(uint256 tokenId) view`: Get all structured data for a dream.
37. `getInfluenceTargets(uint256 sourceDreamId) view`: Get the list of dreams influenced by a source dream.
38. `getDreamsInfluencing(uint256 targetDreamId) view`: Get the list of dreams influencing a target dream.
39. `getDreamBySeed(bytes32 seed) view`: Look up a dream ID by its unique seed (if known). (Requires mapping). *Correction: Storing reverse mapping is gas heavy. Better to just get the seed from `getDreamDetails`.*
40. `extractSeed(uint256 tokenId) view`: Get the unique procedural seed of a dream.

*(Self-Correction during summary writing: 39 was impractical without a reverse mapping. Replacing with something else or just ensuring the count is met by other functions. The list is already well over 20 without 39).*

Let's ensure the list of *distinct external/public* functions (excluding standard ERC721 getters like ownerOf, balanceOf, getApproved, isApprovedForAll, supportsInterface, name, symbol) is >= 20.

Creative/Advanced Functions:
1. `weaveNewDream`
2. `weaveFromInfluence`
3. `dissipateDream`
4. `attuneMood`
5. `infuseEnergy`
6. `blendPalettes`
7. `increaseComplexity`
8. `scrambleParameters`
9. `anchorDream`
10. `releaseDream`
11. `addInfluenceLink`
12. `removeInfluenceLink`
13. `fortifyInfluence`
14. `simulateTimeStep`
15. `triggerEvolution`
16. `triggerCascadeInfluence`
17. `syncDreamWithBlock`
18. `setEvolutionParameters`
19. `setGlobalDreamParameter`
20. `setInteractionCost`
21. `pauseWeaving`
22. `pauseSimulations`
23. `withdrawFees`
24. `getDreamDetails`
25. `getInfluenceTargets`
26. `getDreamsInfluencing`
27. `extractSeed`
28. `tokenURI` (Override is necessary for dynamic data)

Yes, that's 28 unique external/public functions beyond the most basic ERC721 interface requirements (like balanceOf, ownerOf, transfer, approve, etc., though we inherit and use them). The contract will inherit ERC721 from OpenZeppelin to handle standard ownership/transfer logic.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @title DigitalDreamWeaver
/// @notice A smart contract for creating and managing dynamic, evolving digital 'Dreams' as NFTs with influence mechanics.
/// @dev Dreams have mutable on-chain states that can be influenced by other dreams and external factors,
///      evolving over time through explicit simulation steps.

// --- Contract Outline ---
// 1. Imports (ERC721, Ownable, Counters, Math)
// 2. Errors
// 3. Events
// 4. Structs (Dream)
// 5. State Variables (Mappings for dreams, influence, parameters, costs, counters)
// 6. Constructor
// 7. Modifiers
// 8. Internal Helper Functions (Parameter generation, influence calculation, state evolution)
// 9. ERC721 Standard Overrides (tokenURI)
// 10. Core Functionality:
//     - Dream Weaving (Minting)
//     - State Interaction & Modification
//     - Influence Graph Management
//     - Evolution & Simulation Triggers
// 11. Configuration & Utility Functions (Owner-only)
// 12. Read Functions (State Query)

// --- Function Summary ---
// ERC721 Core (Inherited/Overridden): tokenURI, supportsInterface, name, symbol, balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom (various overloads)
//
// Dream Weaving:
// - weaveNewDream(string memory initialMoodHint) payable: Mints a new dream.
// - weaveFromInfluence(uint256 influentialDreamId) payable: Mints a dream inheriting traits from another.
// - dissipateDream(uint256 tokenId): Burns a dream.
//
// State Interaction:
// - attuneMood(uint256 tokenId, uint8 targetMood) payable: Attempts to change a dream's mood.
// - infuseEnergy(uint256 tokenId) payable: Increases a dream's energy.
// - blendPalettes(uint256 tokenId1, uint256 tokenId2, uint256 targetTokenId) payable: Blends colors of two dreams into a third.
// - increaseComplexity(uint256 tokenId) payable: Increases a dream's complexity.
// - scrambleParameters(uint256 tokenId) payable: Randomizes dream parameters.
// - anchorDream(uint256 tokenId) payable: Makes a dream resistant to certain changes.
// - releaseDream(uint256 tokenId): Removes anchor status.
//
// Influence Management:
// - addInfluenceLink(uint256 sourceDreamId, uint256 targetDreamId): Creates a directional link.
// - removeInfluenceLink(uint256 sourceDreamId, uint256 targetDreamId): Removes a link.
// - fortifyInfluence(uint256 sourceDreamId, uint256 targetDreamId) payable: Strengthens a link.
//
// Evolution & Simulation:
// - simulateTimeStep(uint256 tokenId) payable: Evolves a single dream based on rules and influence.
// - triggerEvolution(uint256 tokenId) payable: Attempts a significant evolution step.
// - triggerCascadeInfluence(uint256 startDreamId, uint8 maxDepth) payable: Simulates evolution cascading through influence graph.
// - syncDreamWithBlock(uint256 tokenId) payable: Incorporates block data into dream state.
//
// Configuration & Utilities:
// - setEvolutionParameters(uint256 tokenId, uint16 mutationRate, uint16 sensitivityToInfluence, uint16 decayRate): Sets individual dream evo params (Owner).
// - setGlobalDreamParameter(uint8 paramType, uint256 value): Sets system-wide parameters (Owner).
// - setInteractionCost(uint8 interactionType, uint256 cost): Sets costs for interactions (Owner).
// - pauseWeaving(bool paused): Pauses minting (Owner).
// - pauseSimulations(bool paused): Pauses simulation functions (Owner).
// - withdrawFees(address recipient): Withdraws contract balance (Owner).
//
// Read Functions:
// - getDreamDetails(uint256 tokenId) view: Retrieves a dream's state.
// - getInfluenceTargets(uint256 sourceDreamId) view: Gets dreams influenced by a source.
// - getDreamsInfluencing(uint256 targetDreamId) view: Gets dreams influencing a target.
// - extractSeed(uint256 tokenId) view: Gets a dream's procedural seed.

contract DigitalDreamWeaver is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Errors ---
    error DreamDoesNotExist(uint256 tokenId);
    error NotDreamOwnerOrApproved(uint256 tokenId);
    error InteractionPaused();
    error WeavingPaused();
    error SimulationPaused();
    error InsufficientPayment(uint256 required, uint256 provided);
    error CannotSelfInfluence();
    error InfluenceLinkAlreadyExists();
    error InfluenceLinkDoesNotExist();
    error MaxInfluenceLinksReached(uint256 tokenId);
    error InvalidParameterType();
    error InvalidInteractionType();
    error CannotBlendWithSelf();
    error MustOwnAllDreamsForBlend();
    error CascadeDepthTooHigh(uint8 maxDepth);
    error CannotAnchorAlreadyAnchored();
    error CannotReleaseIfNotAnchored();

    // --- Events ---
    event DreamWeaved(uint256 indexed tokenId, address indexed owner, bytes32 seed, uint256 blockNumber);
    event DreamDissipated(uint256 indexed tokenId, address indexed owner);
    event DreamStateChanged(uint256 indexed tokenId, string stateChangeType);
    event InfluenceLinkAdded(uint256 indexed sourceId, uint256 indexed targetId);
    event InfluenceLinkRemoved(uint256 indexed sourceId, uint256 indexed targetId);
    event SimulationStepTriggered(uint256 indexed tokenId, uint256 blockNumber);
    event EvolutionParametersSet(uint256 indexed tokenId, uint16 mutationRate, uint16 sensitivityToInfluence, uint16 decayRate);
    event GlobalParameterSet(uint8 indexed paramType, uint256 value);
    event InteractionCostSet(uint8 indexed interactionType, uint256 cost);
    event WeavingPausedToggled(bool paused);
    event SimulationsPausedToggled(bool paused);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Structs ---
    struct Dream {
        uint256 id;
        address owner; // Redundant with ERC721, but useful for struct passing
        uint8 mood; // 0-100 (e.g., 0=Chaotic, 50=Balanced, 100=Serene)
        bytes3 colorPalette; // RGB hex code packed
        uint16 complexity; // 0-1000
        uint16 vibrancy; // 0-1000
        uint256 energy; // Can be consumed or gained
        bytes32 seed; // Unique deterministic seed for procedural generation (off-chain)
        uint16 mutationRate; // 0-1000 (How prone to spontaneous change)
        uint16 sensitivityToInfluence; // 0-1000 (How much it's affected by others)
        uint16 decayRate; // 0-1000 (How quickly energy/vibrancy decays)
        uint64 lastSimulationTime; // Block timestamp of last simulation step
        bool isAnchored; // Resists certain random changes if true
    }

    // --- State Variables ---
    mapping(uint256 => Dream) private _dreams;
    mapping(uint256 => uint256[]) private _influenceTargets; // sourceId => list of targetIds
    mapping(uint256 => uint256[]) private _influenceSources; // targetId => list of sourceIds (for queries)

    uint256 public maxInfluenceLinksPerDream = 10; // Limit influence links to manage gas

    enum GlobalParameterType { BaseDecayRate, InfluenceWeight, ComplexityImpact, EnergyImpact }
    mapping(uint8 => uint256) public globalParameters;

    enum InteractionType { AttuneMood, InfuseEnergy, BlendPalettes, IncreaseComplexity, ScrambleParameters, AnchorDream, FortifyInfluence, SimulateTimeStep, TriggerEvolution, TriggerCascadeInfluence, SyncDreamWithBlock }
    mapping(uint8 => uint256) public interactionCosts; // Costs in WEI

    bool public weavingPaused = false;
    bool public simulationsPaused = false;

    // --- Constructor ---
    constructor() ERC721("DigitalDream", "DREAM") Ownable(msg.sender) {
        // Set some initial global parameters (example values)
        globalParameters[uint8(GlobalParameterType.BaseDecayRate)] = 1; // 1 per block maybe? Or per time unit? Let's simplify: used in _calculateEvolutionDelta
        globalParameters[uint8(GlobalParameterType.InfluenceWeight)] = 10; // How much influence matters
        globalParameters[uint8(GlobalParameterType.ComplexityImpact)] = 5; // How complexity affects other stats
        globalParameters[uint8(GlobalParameterType.EnergyImpact)] = 2; // How energy affects other stats

        // Set some initial interaction costs (example values)
        interactionCosts[uint8(InteractionType.AttuneMood)] = 0.01 ether;
        interactionCosts[uint8(InteractionType.InfuseEnergy)] = 0.005 ether;
        interactionCosts[uint8(InteractionType.BlendPalettes)] = 0.03 ether;
        interactionCosts[uint8(InteractionType.IncreaseComplexity)] = 0.02 ether;
        interactionCosts[uint8(InteractionType.ScrambleParameters)] = 0.04 ether;
        interactionCosts[uint8(InteractionType.AnchorDream)] = 0.05 ether;
        interactionCosts[uint8(InteractionType.FortifyInfluence)] = 0.01 ether;
        interactionCosts[uint8(InteractionType.SimulateTimeStep)] = 0.001 ether;
        interactionCosts[uint8(InteractionType.TriggerEvolution)] = 0.06 ether;
        interactionCosts[uint8(InteractionType.TriggerCascadeInfluence)] = 0.1 ether; // High cost for cascade
        interactionCosts[uint8(InteractionType.SyncDreamWithBlock)] = 0.0005 ether;
    }

    // --- Modifiers ---
    modifier whenNotWeavingPaused() {
        if (weavingPaused) revert WeavingPaused();
        _;
    }

    modifier whenNotSimulationPaused() {
        if (simulationsPaused) revert SimulationPaused();
        _;
    }

    modifier onlyDreamOwnerOrApproved(uint256 tokenId) {
        if (!_exists(tokenId)) revert DreamDoesNotExist(tokenId);
        if (_ownerOf(tokenId) != msg.sender && !isApprovedForAll(_ownerOf(tokenId), msg.sender) && getApproved(tokenId) != msg.sender) {
            revert NotDreamOwnerOrApproved(tokenId);
        }
        _;
    }

    modifier payForInteraction(uint8 interactionType) {
        uint256 requiredCost = interactionCosts[interactionType];
        if (msg.value < requiredCost) {
            revert InsufficientPayment(requiredCost, msg.value);
        }
        // Refund excess ETH immediately
        if (msg.value > requiredCost) {
            payable(msg.sender).transfer(msg.value - requiredCost);
        }
        _;
    }

    // --- Internal Helper Functions ---

    /// @dev Generates a pseudo-random seed based on block data, sender, and initial hint.
    function _generateSeed(address minter, string memory initialHint) internal view returns (bytes32) {
        // Simple combination of available entropy sources
        return keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Use block.difficulty or block.prevrandao in newer versions
            block.number,
            minter,
            initialHint,
            _tokenIdCounter.current(),
            msg.sender // Including msg.sender for more variation per call
        ));
    }

    /// @dev Creates initial dream parameters based on seed and optional influence/hint.
    function _createInitialParameters(
        bytes32 seed,
        string memory initialMoodHint,
        uint256 influentialDreamId // 0 if no influence
    ) internal view returns (uint8 mood, bytes3 colorPalette, uint16 complexity, uint16 vibrancy, uint256 energy, uint16 mutationRate, uint16 sensitivityToInfluence, uint16 decayRate) {
        // Use the seed to derive parameters deterministically but pseudo-randomly
        uint256 seedUint = uint256(seed);

        // Base randomness from seed
        mood = uint8(seedUint % 101); // 0-100
        colorPalette = bytes3(bytes32(seedUint >> 8)); // Take 3 bytes for RGB
        complexity = uint16(seedUint % 1001); // 0-1000
        vibrancy = uint16((seedUint >> 16) % 1001); // 0-1000
        energy = uint256((seedUint >> 32) % 10001); // 0-10000

        // Evolution parameters - some randomness, perhaps biased later
        mutationRate = uint16((seedUint >> 48) % 501); // 0-500 base
        sensitivityToInfluence = uint16((seedUint >> 64) % 501); // 0-500 base
        decayRate = uint16((seedUint >> 80) % 501); // 0-500 base

        // Apply hint influence (simple example)
        if (bytes(initialMoodHint).length > 0) {
            uint256 hintHash = uint256(keccak256(abi.encodePacked(initialMoodHint)));
            // Example: if hint hash ends in 0-4, bias mood down; 5-9, bias up.
            if (hintHash % 10 < 5) {
                 mood = Math.max(0, mood - uint8(hintHash % 20));
            } else {
                 mood = Math.min(100, mood + uint8(hintHash % 20));
            }
            complexity = uint16(Math.max(0, int256(complexity) + int256((hintHash >> 8) % 200) - 100)); // Shift complexity
        }

        // Apply influential dream influence (more significant example)
        if (influentialDreamId != 0 && _exists(influentialDreamId)) {
            Dream storage influencer = _dreams[influentialDreamId];
            mood = uint8((uint256(mood) + uint256(influencer.mood)) / 2); // Average mood
            // Simple blending of colorPalette bytes
            bytes3 blendedPalette;
            blendedPalette[0] = bytes1((bytes1(colorPalette, 0) + bytes1(influencer.colorPalette, 0)) / 2);
            blendedPalette[1] = bytes1((bytes1(colorPalette, 1) + bytes1(influencer.colorPalette, 1)) / 2);
            blendedPalette[2] = bytes1((bytes1(colorPalette, 2) + bytes1(influencer.colorPalette, 2)) / 2);
            colorPalette = blendedPalette;

            complexity = uint16((uint256(complexity) + uint224(influencer.complexity)) / 2);
            vibrancy = uint16((uint256(vibrancy) + uint224(influencer.vibrancy)) / 2);
            energy = (energy + influencer.energy) / 2;

            // Influence evolution parameters towards the influential dream's parameters
            mutationRate = uint16((uint256(mutationRate) + uint256(influencer.mutationRate)) / 2);
            sensitivityToInfluence = uint16((uint256(sensitivityToInfluence) + uint256(influencer.sensitivityToInfluence)) / 2);
            decayRate = uint16((uint256(decayRate) + uint256(influencer.decayRate)) / 2);
        }

        return (mood, colorPalette, complexity, vibrancy, energy, mutationRate, sensitivityToInfluence, decayRate);
    }

    /// @dev Calculates net influence on a dream from its sources.
    ///      This is a simplified example. Real implementation needs careful gas consideration.
    function _calculateNetInfluence(uint256 tokenId) internal view returns (int256 moodInfluence, int256 energyInfluence, int256 complexityInfluence, bytes3 paletteInfluence) {
        uint256[] storage sources = _influenceSources[tokenId];
        if (sources.length == 0) {
            return (0, 0, 0, bytes3(0));
        }

        int256 totalMood = 0;
        int256 totalEnergy = 0;
        int256 totalComplexity = 0;
        uint256 totalInfluences = 0;

        uint256 rSum = 0;
        uint256 gSum = 0;
        uint256 bSum = 0;

        // Iterate through sources (limited to avoid OOG)
        // In a real contract, complex influence might be pre-calculated, batched, or limited in scope.
        uint256 iterationLimit = Math.min(sources.length, 5); // Process max 5 sources per step

        for (uint256 i = 0; i < iterationLimit; ++i) {
            uint256 sourceId = sources[i];
            if (_exists(sourceId)) {
                Dream storage source = _dreams[sourceId];
                totalMood += int256(source.mood) - 50; // Center mood around 50
                totalEnergy += int224(source.energy);
                totalComplexity += int256(source.complexity);

                rSum += uint8(bytes1(source.colorPalette, 0));
                gSum += uint8(bytes1(source.colorPalette, 1));
                bSum += uint8(bytes1(source.colorPalette, 2));

                totalInfluences++;
            }
        }

        if (totalInfluences > 0) {
            // Average influence
            moodInfluence = (totalMood / int256(totalInfluences) * int256(globalParameters[uint8(GlobalParameterType.InfluenceWeight)])) / 1000; // Scale by weight
            energyInfluence = (totalEnergy / int256(totalInfluences) * int256(globalParameters[uint8(GlobalParameterType.InfluenceWeight)])) / 1000;
            complexityInfluence = (totalComplexity / int256(totalInfluences) * int256(globalParameters[uint8(GlobalParameterType.InfluenceWeight)])) / 1000;

            bytes3 avgPalette;
            avgPalette[0] = bytes1(uint8(rSum / totalInfluences));
            avgPalette[1] = bytes1(uint8(gSum / totalInfluences));
            avgPalette[2] = bytes1(uint8(bSum / totalInfluences));
            paletteInfluence = avgPalette;
        }

        return (moodInfluence, energyInfluence, complexityInfluence, paletteInfluence);
    }


    /// @dev Applies an evolution step to a dream based on its state and influence.
    ///      This is a simplified logic example.
    function _applyEvolutionStep(uint256 tokenId) internal {
        Dream storage dream = _dreams[tokenId];
        uint64 currentTime = uint64(block.timestamp);
        uint64 timeDelta = currentTime > dream.lastSimulationTime ? currentTime - dream.lastSimulationTime : 0;
        dream.lastSimulationTime = currentTime;

        // Calculate net influence
        (int256 moodInf, int256 energyInf, int256 compInf, bytes3 paletteInf) = _calculateNetInfluence(tokenId);

        // Apply decay (if not anchored)
        if (!dream.isAnchored) {
            uint256 decayAmount = (uint256(dream.decayRate) * globalParameters[uint8(GlobalParameterType.BaseDecayRate)] * timeDelta) / 10000; // Scaled decay
            dream.energy = dream.energy > decayAmount ? dream.energy - decayAmount : 0;
            dream.vibrancy = dream.vibrancy > decayAmount ? uint16(dream.vibrancy - decayAmount) : 0;
        }

        // Apply influence
        dream.mood = uint8(Math.max(0, Math.min(100, int256(dream.mood) + (moodInf * int256(dream.sensitivityToInfluence)) / 1000)));
        dream.energy = uint256(Math.max(0, int256(dream.energy) + (energyInf * int256(dream.sensitivityToInfluence)) / 1000));
        dream.complexity = uint16(Math.max(0, Math.min(1000, int256(dream.complexity) + (compInf * int256(dream.sensitivityToInfluence)) / 1000)));

        // Simple palette blending - weight towards influence palette based on sensitivity
        uint256 sens = dream.sensitivityToInfluence;
        bytes3 currentPalette = dream.colorPalette;
        bytes3 blendedPalette;
        blendedPalette[0] = bytes1(uint8((uint256(uint8(bytes1(currentPalette, 0))) * (1000 - sens) + uint256(uint8(bytes1(paletteInf, 0))) * sens) / 1000));
        blendedPalette[1] = bytes1(uint8((uint256(uint8(bytes1(currentPalette, 1))) * (1000 - sens) + uint256(uint8(bytes1(paletteInf, 1))) * sens) / 1000));
        blendedPalette[2] = bytes1(uint8((uint256(uint8(bytes1(currentPalette, 2))) * (1000 - sens) + uint256(uint8(bytes1(paletteInf, 2))) * sens) / 1000));
        dream.colorPalette = blendedPalette;


        // Apply spontaneous mutation (if not anchored)
        if (!dream.isAnchored && dream.mutationRate > 0) {
             // Use seed and block data for pseudo-randomness
            uint256 rand = uint256(keccak256(abi.encodePacked(dream.seed, block.timestamp, block.number)));
            if (rand % 1000 < dream.mutationRate) {
                // Apply a random mutation (example: shift mood slightly)
                int256 moodShift = int256((rand >> 8) % 21) - 10; // -10 to +10
                dream.mood = uint8(Math.max(0, Math.min(100, int256(dream.mood) + moodShift)));

                 // Apply a random shift to one color channel
                 uint8 channel = uint8((rand >> 16) % 3);
                 int256 colorShift = int256((rand >> 24) % 41) - 20; // -20 to +20
                 bytes3 mutatedPalette = dream.colorPalette;
                 int256 currentColorValue = int256(uint8(bytes1(mutatedPalette, channel)));
                 int256 newColorValue = Math.max(0, Math.min(255, currentColorValue + colorShift));
                 mutatedPalette[channel] = bytes1(uint8(newColorValue));
                 dream.colorPalette = mutatedPalette;

                 emit DreamStateChanged(tokenId, "Mutated");
            }
        }

         // Apply complexity impact (example: higher complexity increases vibrancy, lower complexity decreases it)
        int256 complexityEffect = (int256(dream.complexity) - 500) * int256(globalParameters[uint8(GlobalParameterType.ComplexityImpact)]) / 1000; // Center complexity around 500
        dream.vibrancy = uint16(Math.max(0, Math.min(1000, int256(dream.vibrancy) + complexityEffect));

        // Apply energy impact (example: higher energy increases vibrancy and potentially complexity)
        int256 energyEffectVibrancy = (int256(dream.energy) - 5000) * int256(globalParameters[uint8(GlobalParameterType.EnergyImpact)]) / 5000; // Center energy around 5000
        dream.vibrancy = uint16(Math.max(0, Math.min(1000, int256(dream.vibrancy) + energyEffectVibrancy)));
        // dream.complexity = uint16(Math.max(0, Math.min(1000, int256(dream.complexity) + (energyEffectVibrancy / 10)))); // Smaller complexity effect

        // Ensure parameters stay within bounds after all calculations
        dream.mood = Math.max(0, Math.min(100, dream.mood));
        dream.complexity = Math.max(0, Math.min(1000, dream.complexity));
        dream.vibrancy = Math.max(0, Math.min(1000, dream.vibrancy));
        // Energy can fluctuate more widely, but could cap it if needed
    }


    // --- ERC721 Standard Overrides ---

    /// @notice Returns the metadata URI for a given dream token.
    /// @dev This function is overridden to generate a URI that points to a service
    ///      which can interpret the dream's current on-chain state dynamically.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert DreamDoesNotExist(tokenId);
        }
        // Construct a URI pointing to an off-chain service that knows how to
        // generate metadata JSON and potentially imagery based on the on-chain state.
        // Example: "https://dreamweaver.xyz/api/metadata/{tokenId}"
        // Or a data URI for simple cases:
        // data:application/json;base64,... (base64 encoded JSON)
        // However, encoding complex JSON on-chain is expensive.
        // A common pattern is a gateway URI + token ID.
        // For this example, we'll return a placeholder or a minimal structure.

        // A more realistic approach points to an API that reads the state via web3
        string memory baseURI = "ipfs://QmbgA.../"; // Example placeholder base URI
        string memory jsonString = string(abi.encodePacked(
            '{"name":"Dream #',
            Strings.toString(tokenId),
            '", "description":"A digital dream.", "attributes": [',
            '{"trait_type": "Mood", "value": ', Strings.toString(_dreams[tokenId].mood), '}',
            ',{"trait_type": "Complexity", "value": ', Strings.toString(_dreams[tokenId].complexity), '}',
            ',{"trait_type": "Vibrancy", "value": ', Strings.toString(_dreams[tokenId].vibrancy), '}',
            ',{"trait_type": "Energy", "value": ', Strings.toString(_dreams[tokenId].energy), '}',
            ',{"trait_type": "Is Anchored", "value": ', _dreams[tokenId].isAnchored ? '"True"' : '"False"', '}',
            '], "dream_data": {', // Include raw data for off-chain interpretation
            '"mood":', Strings.toString(_dreams[tokenId].mood),
            ',"palette":"#', bytesToHex(_dreams[tokenId].colorPalette), '"',
            ',"complexity":', Strings.toString(_dreams[tokenId].complexity),
            ',"vibrancy":', Strings.toString(_dreams[tokenId].vibrancy),
            ',"energy":', Strings.toString(_dreams[tokenId].energy),
            ',"seed":"0x', bytesToHex(bytes(_dreams[tokenId].seed)), '"',
            ',"mutationRate":', Strings.toString(_dreams[tokenId].mutationRate),
            ',"sensitivityToInfluence":', Strings.toString(_dreams[tokenId].sensitivityToInfluence),
            ',"decayRate":', Strings.toString(_dreams[tokenId].decayRate),
            ',"lastSimTime":', Strings.toString(_dreams[tokenId].lastSimulationTime),
            ',"isAnchored":', _dreams[tokenId].isAnchored ? 'true' : 'false',
            '}}'
        ));

        // This is still quite large and expensive for on-chain.
        // A more practical way is to return a pointer like "ipfs://<hash>/{tokenId}.json"
        // and have a service generate the JSON off-chain by querying the contract state.
        // For the sake of showing dynamic data, we include the basic JSON structure.
        // In production, consider using a dedicated metadata service or IPFS with state query.

        // Placeholder example returning token ID in a simple URI structure:
        return string(abi.encodePacked("ipfs://<metadata_gateway_uri>/", Strings.toString(tokenId)));
    }

    // Helper to convert bytes to hex string (simplified, assumes bytes are valid hex chars or small)
    // Note: Full hex conversion is complex and gas-intensive. Use a library or off-chain for production.
    function bytesToHex(bytes memory b) internal pure returns (string memory) {
        bytes memory hexChars = "0123456789abcdef";
        bytes memory result = new bytes(b.length * 2);
        for (uint i = 0; i < b.length; i++) {
            result[i*2] = hexChars[uint8(b[i] >> 4)];
            result[i*2+1] = hexChars[uint8(b[i] & 0x0f)];
        }
        return string(result);
    }


    // --- Core Functionality ---

    /// @notice Weaves a new dream and mints it to the caller.
    /// @param initialMoodHint A string hint to slightly influence the dream's initial mood/complexity.
    /// @dev Requires payment according to `interactionCosts[InteractionType.WeaveNewDream]`.
    ///      Parameters are semi-randomly generated based on block data, sender, hint, and contract state.
    function weaveNewDream(string memory initialMoodHint)
        public
        payable
        whenNotWeavingPaused
        payForInteraction(uint8(InteractionType.WeaveNewDream)) // Assuming a cost set for minting
    {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        address minter = msg.sender;

        bytes32 seed = _generateSeed(minter, initialMoodHint);
        (uint8 mood, bytes3 colorPalette, uint16 complexity, uint16 vibrancy, uint256 energy, uint16 mutationRate, uint16 sensitivityToInfluence, uint16 decayRate) =
            _createInitialParameters(seed, initialMoodHint, 0); // No influential dream for base weave

        _dreams[newItemId] = Dream({
            id: newItemId,
            owner: minter, // Owner is set by ERC721 _safeMint later
            mood: mood,
            colorPalette: colorPalette,
            complexity: complexity,
            vibrancy: vibrancy,
            energy: energy,
            seed: seed,
            mutationRate: mutationRate,
            sensitivityToInfluence: sensitivityToInfluence,
            decayRate: decayRate,
            lastSimulationTime: uint64(block.timestamp),
            isAnchored: false
        });

        _safeMint(minter, newItemId);
        emit DreamWeaved(newItemId, minter, seed, block.number);
    }

    /// @notice Weaves a new dream influenced by an existing dream.
    /// @param influentialDreamId The ID of the dream whose traits will influence the new dream.
    /// @dev Requires payment. Caller must NOT own the influential dream, or must be approved.
    ///      Allows cross-collection influence if influentialDreamId refers to a dream they don't own.
    function weaveFromInfluence(uint256 influentialDreamId)
        public
        payable
        whenNotWeavingPaused
        payForInteraction(uint8(InteractionType.WeaveFromInfluence)) // Assuming a cost set for influenced minting
    {
        if (!_exists(influentialDreamId)) revert DreamDoesNotExist(influentialDreamId);
        // Allow anyone to weave FROM another dream, encourages interaction.
        // If owner wants to weave from their OWN, they just call this.

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        address minter = msg.sender;

        // Use influential dream's seed or state partially in new seed generation?
        // Let's keep new seed fully random for uniqueness but use its state for params.
        bytes32 seed = _generateSeed(minter, ""); // New random seed
        (uint8 mood, bytes3 colorPalette, uint16 complexity, uint16 vibrancy, uint256 energy, uint16 mutationRate, uint16 sensitivityToInfluence, uint16 decayRate) =
            _createInitialParameters(seed, "", influentialDreamId); // Use influential dream's state

        _dreams[newItemId] = Dream({
            id: newItemId,
             owner: minter, // Owner set by _safeMint
            mood: mood,
            colorPalette: colorPalette,
            complexity: complexity,
            vibrancy: vibrancy,
            energy: energy,
            seed: seed,
            mutationRate: mutationRate,
            sensitivityToInfluence: sensitivityToInfluence,
            decayRate: decayRate,
            lastSimulationTime: uint64(block.timestamp),
            isAnchored: false
        });

        _safeMint(minter, newItemId);
        emit DreamWeaved(newItemId, minter, seed, block.number);
    }

    /// @notice Allows the owner to destroy (burn) a dream they own.
    /// @param tokenId The ID of the dream to dissipate.
    /// @dev Clears associated state.
    function dissipateDream(uint256 tokenId) public onlyDreamOwnerOrApproved(tokenId) {
        if (!_exists(tokenId)) revert DreamDoesNotExist(tokenId);

        address owner = _ownerOf(tokenId);

        // Clean up influence links where this dream is a source or target
        uint256[] storage targets = _influenceTargets[tokenId];
        for (uint i = 0; i < targets.length; i++) {
             uint256 targetId = targets[i];
             // Remove this dream (tokenId) from targetId's sources list
             uint256[] storage sources = _influenceSources[targetId];
             for (uint j = 0; j < sources.length; j++) {
                if (sources[j] == tokenId) {
                    sources[j] = sources[sources.length - 1];
                    sources.pop();
                    break; // Assuming no duplicate source links
                }
             }
        }
         delete _influenceTargets[tokenId]; // Clear all target links from this dream

        uint256[] storage sources = _influenceSources[tokenId];
        for (uint i = 0; i < sources.length; i++) {
             uint256 sourceId = sources[i];
             // Remove this dream (tokenId) from sourceId's targets list
             uint256[] storage targetsOfSource = _influenceTargets[sourceId];
             for (uint j = 0; j < targetsOfSource.length; j++) {
                if (targetsOfSource[j] == tokenId) {
                    targetsOfSource[j] = targetsOfSource[targetsOfSource.length - 1];
                    targetsOfSource.pop();
                    break; // Assuming no duplicate target links
                }
             }
        }
        delete _influenceSources[tokenId]; // Clear all source links to this dream

        delete _dreams[tokenId]; // Remove the dream struct data
        _burn(tokenId); // Burn the ERC721 token
        emit DreamDissipated(tokenId, owner);
    }

    // --- State Interaction & Modification ---

    /// @notice Attempts to attune a dream's mood towards a target value.
    /// @param tokenId The dream ID.
    /// @param targetMood The desired mood (0-100).
    /// @dev Probabilistic outcome influenced by complexity and energy. Requires payment.
    function attuneMood(uint256 tokenId, uint8 targetMood)
        public
        payable
        onlyDreamOwnerOrApproved(tokenId)
        payForInteraction(uint8(InteractionType.AttuneMood))
    {
        Dream storage dream = _dreams[tokenId];
        uint256 rand = uint256(keccak256(abi.encodePacked(dream.seed, block.timestamp, msg.sender, block.number, targetMood)));

        // Probability of success/magnitude of change influenced by complexity, energy, etc.
        // Higher energy and lower complexity might make mood changes easier/more predictable.
        // Higher complexity might make it harder or more volatile.
        uint256 baseChance = 700; // 70% base chance for some change (0-1000 scale)
        int256 complexityModifier = int256(dream.complexity) - 500; // -500 to 500
        int256 energyModifier = int256(dream.energy) > 5000 ? int256(dream.energy - 5000) / 100 : int256(dream.energy) / 100 - 50; // Scale energy effect

        int256 actualChance = int256(baseChance) - complexityModifier / 5 + energyModifier; // Example formula
        actualChance = Math.max(0, Math.min(1000, actualChance)); // Cap chance between 0 and 1000

        if (rand % 1000 < uint256(actualChance)) {
            // Success or partial success: move mood closer to target
            int256 currentMood = int256(dream.mood);
            int256 moodDifference = int256(targetMood) - currentMood;
            int256 changeMagnitude = Math.abs(moodDifference);

            // Apply change based on chance and state (e.g., smaller change for higher complexity)
            uint256 appliedChange = Math.max(1, changeMagnitude * uint256(actualChance) / 1000); // Apply at least 1, scaled by chance

            if (moodDifference > 0) {
                dream.mood = uint8(Math.min(100, currentMood + appliedChange));
            } else if (moodDifference < 0) {
                 dream.mood = uint8(Math.max(0, currentMood - appliedChange));
            }
            emit DreamStateChanged(tokenId, "MoodAttuned");
        } else {
            // Failure: maybe small random shift or energy loss
             int256 moodShift = int256((rand >> 8) % 11) - 5; // -5 to +5 random shift on failure
             dream.mood = uint8(Math.max(0, Math.min(100, int256(dream.mood) + moodShift)));
             dream.energy = dream.energy > 100 ? dream.energy - 100 : 0; // Small energy penalty on failure
             emit DreamStateChanged(tokenId, "MoodAttuneAttemptFailed");
        }
    }

    /// @notice Increases a dream's energy level.
    /// @param tokenId The dream ID.
    /// @dev Requires payment.
    function infuseEnergy(uint256 tokenId)
        public
        payable
        onlyDreamOwnerOrApproved(tokenId)
        payForInteraction(uint8(InteractionType.InfuseEnergy))
    {
        Dream storage dream = _dreams[tokenId];
        uint256 energyGain = msg.value / (interactionCosts[uint8(InteractionType.InfuseEnergy)] / 1000); // Example: every 1/1000th of cost adds 1 energy
        dream.energy += energyGain;
        emit DreamStateChanged(tokenId, "EnergyInfused");
    }

     /// @notice Blends the color palettes of two source dreams into a target dream.
    /// @param tokenId1 The ID of the first source dream.
    /// @param tokenId2 The ID of the second source dream.
    /// @param targetTokenId The ID of the dream whose palette will be modified.
    /// @dev Requires owning or being approved for ALL three dreams. Requires payment.
    function blendPalettes(uint256 tokenId1, uint256 tokenId2, uint256 targetTokenId)
        public
        payable
        payForInteraction(uint8(InteractionType.BlendPalettes))
    {
        if (!_exists(tokenId1)) revert DreamDoesNotExist(tokenId1);
        if (!_exists(tokenId2)) revert DreamDoesNotExist(tokenId2);
        if (!_exists(targetTokenId)) revert DreamDoesNotExist(targetTokenId);

        if (tokenId1 == tokenId2 || tokenId1 == targetTokenId || tokenId2 == targetTokenId) revert CannotBlendWithSelf();

        // Must own/be approved for all three
        require(_ownerOf(tokenId1) == msg.sender || isApprovedForAll(_ownerOf(tokenId1), msg.sender) || getApproved(tokenId1) == msg.sender, "Not owner/approved for source 1");
        require(_ownerOf(tokenId2) == msg.sender || isApprovedForAll(_ownerOf(tokenId2), msg.sender) || getApproved(tokenId2) == msg.sender, "Not owner/approved for source 2");
        require(_ownerOf(targetTokenId) == msg.sender || isApprovedForAll(_ownerOf(targetTokenId), msg.sender) || getApproved(targetTokenId) == msg.sender, "Not owner/approved for target");

        Dream storage dream1 = _dreams[tokenId1];
        Dream storage dream2 = _dreams[tokenId2];
        Dream storage targetDream = _dreams[targetTokenId];

        // Simple average blend
        bytes3 palette1 = dream1.colorPalette;
        bytes3 palette2 = dream2.colorPalette;
        bytes3 newPalette;

        newPalette[0] = bytes1(uint8((uint256(uint8(bytes1(palette1, 0))) + uint256(uint8(bytes1(palette2, 0)))) / 2));
        newPalette[1] = bytes1(uint8((uint256(uint8(bytes1(palette1, 1))) + uint256(uint8(bytes1(palette2, 1)))) / 2));
        newPalette[2] = bytes1(uint8((uint256(uint8(bytes1(palette1, 2))) + uint256(uint8(bytes1(palette2, 2)))) / 2));

        targetDream.colorPalette = newPalette;
        emit DreamStateChanged(targetTokenId, "PaletteBlended");
    }

     /// @notice Attempts to increase a dream's complexity.
    /// @param tokenId The dream ID.
    /// @dev Probabilistic outcome. Requires payment. Higher complexity increases difficulty of further increases.
    function increaseComplexity(uint256 tokenId)
        public
        payable
        onlyDreamOwnerOrApproved(tokenId)
        payForInteraction(uint8(InteractionType.IncreaseComplexity))
    {
        Dream storage dream = _dreams[tokenId];
        if (dream.complexity >= 1000) return; // Already at max complexity

        uint256 rand = uint256(keccak256(abi.encodePacked(dream.seed, block.timestamp, msg.sender, block.number, dream.complexity)));

        // Chance decreases as complexity increases
        uint256 baseChance = 800; // 80% at 0 complexity
        uint256 complexityPenalty = (uint256(dream.complexity) * 800) / 1000; // 0 at 0, 800 at 1000
        uint256 actualChance = baseChance > complexityPenalty ? baseChance - complexityPenalty : 0; // 800 down to 0

        if (rand % 1000 < actualChance) {
            // Success: Increase complexity
            uint16 increaseAmount = uint16(Math.max(1, (1000 - dream.complexity) / 10 + 1)); // Larger increase when further from max
            dream.complexity = uint16(Math.min(1000, dream.complexity + increaseAmount));
            emit DreamStateChanged(tokenId, "ComplexityIncreased");
        } else {
            // Failure: maybe slight energy loss or small random shift
             dream.energy = dream.energy > 50 ? dream.energy - 50 : 0;
             emit DreamStateChanged(tokenId, "ComplexityIncreaseAttemptFailed");
        }
    }

     /// @notice Scrambles a dream's non-essential parameters, introducing chaos.
    /// @param tokenId The dream ID.
    /// @dev Highly random outcome. Affects mood, palette, vibrancy, possibly evolution params. Requires payment.
    function scrambleParameters(uint256 tokenId)
        public
        payable
        onlyDreamOwnerOrApproved(tokenId)
        payForInteraction(uint8(InteractionType.ScrambleParameters))
    {
        Dream storage dream = _dreams[tokenId];
        uint256 rand = uint256(keccak256(abi.encodePacked(dream.seed, block.timestamp, msg.sender, block.number, "scramble")));

        // Apply significant random shifts
        dream.mood = uint8(rand % 101);
        dream.colorPalette = bytes3(bytes32(rand >> 8));
        dream.vibrancy = uint16((rand >> 16) % 1001);

        // Potentially affect evolution parameters too, but less drastically
        dream.mutationRate = uint16(Math.max(0, Math.min(1000, int256(dream.mutationRate) + int256((rand >> 32) % 201) - 100))); // +/- 100
        dream.sensitivityToInfluence = uint16(Math.max(0, Math.min(1000, int256(dream.sensitivityToInfluence) + int256((rand >> 48) % 201) - 100)));
        dream.decayRate = uint16(Math.max(0, Math.min(1000, int256(dream.decayRate) + int256((rand >> 64) % 201) - 100)));

        emit DreamStateChanged(tokenId, "Scrambled");
    }

     /// @notice Marks a dream as 'anchored', making it resistant to certain simulation changes.
    /// @param tokenId The dream ID.
    /// @dev Requires payment. Anchored dreams decay slower and are less affected by random mutation and influence.
    function anchorDream(uint256 tokenId)
        public
        payable
        onlyDreamOwnerOrApproved(tokenId)
        payForInteraction(uint8(InteractionType.AnchorDream))
    {
        Dream storage dream = _dreams[tokenId];
        if (dream.isAnchored) revert CannotAnchorAlreadyAnchored();
        dream.isAnchored = true;
        emit DreamStateChanged(tokenId, "Anchored");
    }

    /// @notice Removes the 'anchored' status from a dream.
    /// @param tokenId The dream ID.
    /// @dev Makes the dream subject to full simulation effects again.
    function releaseDream(uint256 tokenId)
        public
        onlyDreamOwnerOrApproved(tokenId)
    {
        Dream storage dream = _dreams[tokenId];
        if (!dream.isAnchored) revert CannotReleaseIfNotAnchored();
        dream.isAnchored = false;
        emit DreamStateChanged(tokenId, "Released");
    }


    // --- Influence Graph Management ---

    /// @notice Creates a directional influence link from a source dream to a target dream.
    /// @param sourceDreamId The ID of the dream that will influence.
    /// @param targetDreamId The ID of the dream that will be influenced.
    /// @dev Requires owning or being approved for both dreams. Limited by `maxInfluenceLinksPerDream`.
    function addInfluenceLink(uint256 sourceDreamId, uint256 targetDreamId)
        public
        onlyDreamOwnerOrApproved(sourceDreamId)
        onlyDreamOwnerOrApproved(targetDreamId) // Ensure caller has permission on BOTH
    {
        if (sourceDreamId == targetDreamId) revert CannotSelfInfluence();
        if (!_exists(sourceDreamId)) revert DreamDoesNotExist(sourceDreamId);
        if (!_exists(targetDreamId)) revert DreamDoesNotExist(targetDreamId);

        uint256[] storage targets = _influenceTargets[sourceDreamId];
        uint256[] storage sources = _influenceSources[targetDreamId];

        // Check if link already exists
        for (uint i = 0; i < targets.length; i++) {
            if (targets[i] == targetDreamId) revert InfluenceLinkAlreadyExists();
        }

        // Check max links limit
        if (targets.length >= maxInfluenceLinksPerDream) revert MaxInfluenceLinksReached(sourceDreamId);
         if (sources.length >= maxInfluenceLinksPerDream) revert MaxInfluenceLinksReached(targetDreamId); // Also limit incoming links

        _influenceTargets[sourceDreamId].push(targetDreamId);
        _influenceSources[targetDreamId].push(sourceDreamId);

        emit InfluenceLinkAdded(sourceDreamId, targetDreamId);
    }

    /// @notice Removes a directional influence link.
    /// @param sourceDreamId The ID of the source dream.
    /// @param targetDreamId The ID of the target dream.
    /// @dev Requires owning or being approved for both dreams.
    function removeInfluenceLink(uint256 sourceDreamId, uint256 targetDreamId)
        public
        onlyDreamOwnerOrApproved(sourceDreamId)
        onlyDreamOwnerOrApproved(targetDreamId) // Ensure caller has permission on BOTH
    {
        if (!_exists(sourceDreamId)) revert DreamDoesNotExist(sourceDreamId);
        if (!_exists(targetDreamId)) revert DreamDoesNotExist(targetDreamId);

        uint256[] storage targets = _influenceTargets[sourceDreamId];
        uint256[] storage sources = _influenceSources[targetDreamId];

        bool targetFound = false;
        for (uint i = 0; i < targets.length; i++) {
            if (targets[i] == targetDreamId) {
                // Found target, remove it by swapping with last element and popping
                targets[i] = targets[targets.length - 1];
                targets.pop();
                targetFound = true;
                break;
            }
        }

        bool sourceFound = false;
         for (uint i = 0; i < sources.length; i++) {
            if (sources[i] == sourceDreamId) {
                sources[i] = sources[sources.length - 1];
                sources.pop();
                sourceFound = true;
                break;
            }
        }

        if (!targetFound || !sourceFound) revert InfluenceLinkDoesNotExist();

        emit InfluenceLinkRemoved(sourceDreamId, targetDreamId);
    }

     /// @notice Attempts to fortify an existing influence link.
    /// @param sourceDreamId The ID of the source dream.
    /// @param targetDreamId The ID of the target dream.
    /// @dev Requires owning or being approved for both. Requires payment. May slightly increase target's sensitivity to influence.
    function fortifyInfluence(uint256 sourceDreamId, uint256 targetDreamId)
        public
        payable
        onlyDreamOwnerOrApproved(sourceDreamId)
        onlyDreamOwnerOrApproved(targetDreamId)
        payForInteraction(uint8(InteractionType.FortifyInfluence))
    {
         if (!_exists(sourceDreamId)) revert DreamDoesNotExist(sourceDreamId);
        if (!_exists(targetDreamId)) revert DreamDoesNotExist(targetDreamId);

        // Check if link exists (simple check, could be more robust)
        bool linkExists = false;
        uint256[] storage targets = _influenceTargets[sourceDreamId];
        for (uint i = 0; i < targets.length; i++) {
            if (targets[i] == targetDreamId) {
                linkExists = true;
                break;
            }
        }
        if (!linkExists) revert InfluenceLinkDoesNotExist();

        // Apply effect: slightly increase target's sensitivity to influence
        Dream storage targetDream = _dreams[targetDreamId];
        targetDream.sensitivityToInfluence = uint16(Math.min(1000, targetDream.sensitivityToInfluence + 50)); // Increase sensitivity by 50 (cap at 1000)

        emit DreamStateChanged(targetDreamId, "InfluenceFortified");
    }


    // --- Evolution & Simulation Triggers ---

    /// @notice Triggers a simulation step for a specific dream.
    /// @param tokenId The dream ID.
    /// @dev Applies decay, influence, and potential mutation. Requires payment.
    function simulateTimeStep(uint256 tokenId)
        public
        payable
        whenNotSimulationPaused
        payForInteraction(uint8(InteractionType.SimulateTimeStep))
    {
        if (!_exists(tokenId)) revert DreamDoesNotExist(tokenId);

        _applyEvolutionStep(tokenId);
        emit SimulationStepTriggered(tokenId, block.number);
    }

     /// @notice Attempts to trigger a significant evolutionary jump for a dream.
    /// @param tokenId The dream ID.
    /// @dev Probabilistic, success depends on dream's state (e.g., high energy, balanced mood).
    ///      On success, applies larger state changes or random mutations. Requires payment.
    function triggerEvolution(uint256 tokenId)
        public
        payable
        whenNotSimulationPaused
        onlyDreamOwnerOrApproved(tokenId) // Only owner/approved can force major evolution
        payForInteraction(uint8(InteractionType.TriggerEvolution))
    {
        Dream storage dream = _dreams[tokenId];
        uint256 rand = uint256(keccak256(abi.encodePacked(dream.seed, block.timestamp, msg.sender, block.number, "evolution")));

        // Probability of major evolution based on state (example: more likely if energy is high, mood is centered)
        uint256 energyFactor = dream.energy > 5000 ? (dream.energy - 5000) / 100 : 0; // Bonus energy above 5000
        uint256 moodFactor = dream.mood > 25 && dream.mood < 75 ? uint256(50 - Math.abs(int256(dream.mood) - 50)) : 0; // Bonus for centered mood
        uint256 baseChance = 100; // 10% base chance (0-1000 scale)
        uint256 actualChance = baseChance + energyFactor + moodFactor;
        actualChance = Math.min(1000, actualChance); // Cap chance

        if (rand % 1000 < actualChance) {
            // Major Evolution Successful! Apply more significant changes.
            _applyEvolutionStep(tokenId); // Apply a normal step first
            _scrambleParametersInternal(tokenId, rand); // Apply a more intense scramble

            // Bonus effects: maybe increase max energy or complexity cap temporarily? (Advanced state management)
            // For simplicity, just apply a strong scramble and energy boost.
            dream.energy += 5000; // Significant energy boost after evolution
            emit DreamStateChanged(tokenId, "MajorEvolution");

        } else {
             // Evolution attempt failed
             dream.energy = dream.energy > 200 ? dream.energy - 200 : 0; // Energy penalty for failed attempt
             emit DreamStateChanged(tokenId, "EvolutionAttemptFailed");
        }
    }

    // Internal helper for scrambling logic used in triggerEvolution and scrambleParameters
     function _scrambleParametersInternal(uint256 tokenId, uint256 rand) internal {
        Dream storage dream = _dreams[tokenId];
        dream.mood = uint8(rand % 101);
        dream.colorPalette = bytes3(bytes32(rand >> 8));
        dream.vibrancy = uint16((rand >> 16) % 1001);

        // Stronger effect on evolution parameters
        dream.mutationRate = uint16(rand % 1001);
        dream.sensitivityToInfluence = uint16((rand >> 32) % 1001);
        dream.decayRate = uint16((rand >> 64) % 1001);
     }


    /// @notice Triggers simulation steps cascading through the influence graph.
    /// @param startDreamId The dream ID to start the cascade from.
    /// @param maxDepth The maximum depth to traverse the graph. Limited to prevent OOG.
    /// @dev Requires payment. Traverses influence links and applies `simulateTimeStep` to affected dreams. Gas-intensive.
    function triggerCascadeInfluence(uint256 startDreamId, uint8 maxDepth)
        public
        payable
        whenNotSimulationPaused
        payForInteraction(uint8(InteractionType.TriggerCascadeInfluence))
    {
        if (!_exists(startDreamId)) revert DreamDoesNotExist(startDreamId);
        if (maxDepth == 0 || maxDepth > 3) revert CascadeDepthTooHigh(maxDepth); // Limit depth to manage gas

        // Using a simple queue/breadth-first approach
        uint256[] memory queue = new uint256[](1 + maxInfluenceLinksPerDream * maxDepth); // Allocate max possible size (approx)
        mapping(uint256 => bool) visited; // Track visited dreams to avoid cycles and redundant work

        uint256 head = 0;
        uint256 tail = 0; // queue[head...tail-1]

        queue[tail++] = startDreamId;
        visited[startDreamId] = true;

        uint256 dreamsProcessed = 0; // Limit total processed dreams per call

        // Process queue layer by layer (simulating depth)
        uint256 currentLayerSize = 1;
        uint256 nextLayerSize = 0;

        for (uint8 depth = 0; depth < maxDepth && head < tail && dreamsProcessed < 20; ++depth) { // Limit total dreams processed
             nextLayerSize = 0;
             for (uint i = 0; i < currentLayerSize && head < tail && dreamsProcessed < 20; ++i) {
                 uint256 currentDreamId = queue[head++];

                 // Apply simulation step to the current dream in the cascade
                 _applyEvolutionStep(currentDreamId);
                 emit SimulationStepTriggered(currentDreamId, block.number);
                 dreamsProcessed++;

                 // Add its direct targets to the queue for the next layer
                 uint256[] storage targets = _influenceTargets[currentDreamId];
                 for (uint j = 0; j < targets.length && tail < queue.length && dreamsProcessed < 20; ++j) { // Limit targets added
                     uint256 targetId = targets[j];
                     if (_exists(targetId) && !visited[targetId]) {
                         queue[tail++] = targetId;
                         visited[targetId] = true;
                         nextLayerSize++;
                     }
                 }
             }
             currentLayerSize = nextLayerSize; // Move to processing the next layer
        }
        // Note: This BFS is simplified. A true depth-limited traversal needs more careful queue management.
        // The key here is to limit the loop iterations (depth and dreamsProcessed) to manage gas.
        emit DreamStateChanged(startDreamId, string(abi.encodePacked("CascadeTriggered_Depth", Strings.toString(maxDepth))));
    }


     /// @notice Integrates recent block data into a dream's state, causing minor fluctuations.
    /// @param tokenId The dream ID.
    /// @dev Uses block.number, block.timestamp, and block.prevrandao (difficulty) for entropy. Requires payment.
    function syncDreamWithBlock(uint256 tokenId)
        public
        payable
        whenNotSimulationPaused
        onlyDreamOwnerOrApproved(tokenId) // Only owner/approved can explicitly sync
        payForInteraction(uint8(InteractionType.SyncDreamWithBlock))
    {
        if (!_exists(tokenId)) revert DreamDoesNotExist(tokenId);
        Dream storage dream = _dreams[tokenId];

        // Use block data combined with seed for pseudo-randomness
        uint256 rand = uint256(keccak256(abi.encodePacked(
            dream.seed,
            block.timestamp,
            block.difficulty, // Or block.prevrandao
            block.number,
            msg.sender
        )));

        // Apply small, random fluctuations to key stats based on block data
        int256 moodShift = int256(rand % 11) - 5; // +/- 5
        dream.mood = uint8(Math.max(0, Math.min(100, int256(dream.mood) + moodShift)));

        int256 vibrancyShift = int256((rand >> 8) % 101) - 50; // +/- 50
        dream.vibrancy = uint16(Math.max(0, Math.min(1000, int256(dream.vibrancy) + vibrancyShift)));

        int256 energyShift = int256((rand >> 16) % 501) - 250; // +/- 250
        dream.energy = uint256(Math.max(0, int256(dream.energy) + energyShift));

        // Update last simulation time to reflect this state change
        dream.lastSimulationTime = uint64(block.timestamp);

        emit DreamStateChanged(tokenId, "SyncedWithBlock");
    }


    // --- Configuration & Utility Functions (Owner-only) ---

    /// @notice Owner sets evolution parameters for a specific dream.
    /// @param tokenId The dream ID.
    /// @param mutationRate How prone to spontaneous change (0-1000).
    /// @param sensitivityToInfluence How much it's affected by others (0-1000).
    /// @param decayRate How quickly energy/vibrancy decays (0-1000).
    function setEvolutionParameters(uint256 tokenId, uint16 mutationRate, uint16 sensitivityToInfluence, uint16 decayRate)
        public
        onlyOwner
    {
        if (!_exists(tokenId)) revert DreamDoesNotExist(tokenId);
        // Add validation if needed (e.g., ranges)
        _dreams[tokenId].mutationRate = mutationRate;
        _dreams[tokenId].sensitivityToInfluence = sensitivityToInfluence;
        _dreams[tokenId].decayRate = decayRate;
        emit EvolutionParametersSet(tokenId, mutationRate, sensitivityToInfluence, decayRate);
    }

    /// @notice Owner sets a global parameter affecting all dreams.
    /// @param paramType The type of parameter to set (enum GlobalParameterType).
    /// @param value The new value for the parameter.
    function setGlobalDreamParameter(uint8 paramType, uint256 value)
        public
        onlyOwner
    {
        if (paramType >= uint8(GlobalParameterType.EnergyImpact) + 1) revert InvalidParameterType();
        globalParameters[paramType] = value;
        emit GlobalParameterSet(paramType, value);
    }

    /// @notice Owner sets the ETH cost for a specific interaction type.
    /// @param interactionType The type of interaction (enum InteractionType).
    /// @param cost The new cost in WEI.
    function setInteractionCost(uint8 interactionType, uint256 cost)
        public
        onlyOwner
    {
         if (interactionType >= uint8(InteractionType.SyncDreamWithBlock) + 1) revert InvalidInteractionType();
         interactionCosts[interactionType] = cost;
         emit InteractionCostSet(interactionType, cost);
    }

    /// @notice Owner can pause or unpause dream weaving (minting).
    function pauseWeaving(bool paused) public onlyOwner {
        weavingPaused = paused;
        emit WeavingPausedToggled(paused);
    }

    /// @notice Owner can pause or unpause simulation/evolution functions.
    function pauseSimulations(bool paused) public onlyOwner {
        simulationsPaused = paused;
        emit SimulationsPausedToggled(paused);
    }

     /// @notice Owner can withdraw collected ETH fees from the contract balance.
    /// @param recipient The address to send the fees to.
    function withdrawFees(address recipient) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        payable(recipient).transfer(balance);
        emit FeesWithdrawn(recipient, balance);
    }

    // --- Read Functions (State Query) ---

    /// @notice Gets all the details for a specific dream.
    /// @param tokenId The dream ID.
    /// @return A struct containing the dream's current state.
    function getDreamDetails(uint256 tokenId) public view returns (Dream memory) {
        if (!_exists(tokenId)) revert DreamDoesNotExist(tokenId);
        return _dreams[tokenId];
    }

    /// @notice Gets the list of dream IDs that a specific dream influences.
    /// @param sourceDreamId The ID of the dream whose influence targets are queried.
    /// @return An array of dream IDs.
    function getInfluenceTargets(uint256 sourceDreamId) public view returns (uint256[] memory) {
        if (!_exists(sourceDreamId)) revert DreamDoesNotExist(sourceDreamId);
        return _influenceTargets[sourceDreamId];
    }

    /// @notice Gets the list of dream IDs that influence a specific dream.
    /// @param targetDreamId The ID of the dream whose influence sources are queried.
    /// @return An array of dream IDs.
    function getDreamsInfluencing(uint256 targetDreamId) public view returns (uint256[] memory) {
        if (!_exists(targetDreamId)) revert DreamDoesNotExist(targetDreamId);
        return _influenceSources[targetDreamId];
    }

     /// @notice Gets the unique procedural seed for a dream.
    /// @param tokenId The dream ID.
    /// @return The dream's seed as bytes32.
    function extractSeed(uint256 tokenId) public view returns (bytes32) {
         if (!_exists(tokenId)) revert DreamDoesNotExist(tokenId);
         return _dreams[tokenId].seed;
    }

    // The rest of the ERC721 functions like safeTransferFrom, transferFrom, etc. are inherited and work
    // on the token ownership handled by OpenZeppelin's implementation.

    // Fallback function to receive Ether for payable functions
    receive() external payable {}
    fallback() external payable {}
}
```