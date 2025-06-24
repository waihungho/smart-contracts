Okay, let's design a smart contract centered around the concept of *dynamic, evolving digital entities* with properties inspired by fractal structures. We'll call it `FractalGenesis`. These entities will be represented as NFTs (ERC-721), but their core feature is that their properties are stored *on-chain* and can change based on user interactions and contract logic.

This contract will include:

1.  **Generative Aspect:** Users can "generate" new fragments based on input or existing fragments.
2.  **Dynamic Properties:** Fragment parameters are stored and can be modified.
3.  **Evolution/Interaction:** Functions allow fragments to mutate, combine, evolve, or gain special states (like "anchored").
4.  **On-Chain State:** Key properties and interactions are recorded on the blockchain.
5.  **Complex Mechanics:** Features like calibrated property adjustments, attunement, linking, and multi-stage evolution add depth.

---

**Contract: FractalGenesis**

**Outline:**

1.  **License & Pragma**
2.  **Imports:** ERC721, Ownable, ReentrancyGuard, Counters
3.  **Error Definitions**
4.  **Constants & Immutables**
5.  **Enums:** Define types for Attunement and EvolutionState.
6.  **Structs:** Define the `Fragment` struct holding all on-chain properties.
7.  **State Variables:**
    *   Mapping `tokenId` to `Fragment`.
    *   Counter for total tokens minted.
    *   Cost of generating new fragments.
    *   Base URI for metadata.
    *   Pause state.
    *   Parameters related to calibration/evolution thresholds.
    *   Mapping for linked fragments.
8.  **Events:** Log key actions like minting, mutation, evolution, linking, etc.
9.  **Modifiers:** `whenNotPaused`, `whenPaused`, `onlyFragmentOwner`, `onlyValidFragment`.
10. **Constructor:** Initialize ERC721, Ownable, set initial parameters.
11. **Core ERC721 Overrides:** `tokenURI`, `_baseURI`.
12. **Owner Functions:**
    *   `setGenerationCost`: Set the cost to generate a new fragment.
    *   `withdrawFees`: Withdraw collected ETH.
    *   `pauseGeneration`: Pause fragment generation.
    *   `unpauseGeneration`: Unpause fragment generation.
    *   `setBaseURI`: Set the metadata base URI.
    *   `setCalibrationParameters`: Adjust parameters for calibration function.
    *   `setEvolutionParameters`: Adjust criteria/results for evolution.
    *   `mintInitialFragments`: Owner can mint a few initial fragments (e.g., Gen 0).
13. **User Interaction Functions:**
    *   `generateFragment`: Mint a new fragment, paying a fee. Uses block data for initial parameters.
    *   `getFragmentProperties`: Read properties of a specific fragment.
    *   `mutateFragment`: Randomly mutate some properties of a fragment.
    *   `combineFragments`: Burn two fragments to create a new one with combined/derived properties.
    *   `disperseFragment`: Burn a fragment.
    *   `attuneFragment`: Assign an attunement type to a fragment (if criteria met).
    *   `evolveFragment`: Evolve a fragment to the next stage (if criteria met).
    *   `anchorFragment`: Make a fragment's properties immutable.
    *   `refineProperty`: Spend resources (or time/other criteria) to improve one specific property.
    *   `calibrateFragment`: Adjust fragment properties based on the current block's state (timestamp, difficulty, hash).
    *   `linkFragments`: Establish a reciprocal link between two owned fragments.
    *   `unlinkFragments`: Remove a link between two fragments.
14. **Query/Helper Functions:**
    *   `isFragmentAnchored`: Check if a fragment is anchored.
    *   `getFragmentAttunement`: Get a fragment's attunement type.
    *   `canFragmentEvolve`: Check if a fragment currently meets evolution criteria.
    *   `getFragmentGenerationCount`: Get the total number of fragments generated *by users*.
    *   `getTotalFragmentsMinted`: Get the total count including owner mints.
    *   `getLinkedFragments`: Get the token ID of the fragment linked to a given fragment.
    *   `calculateEvolutionCriteria`: Internal helper to check evolution conditions.
    *   `_generateInitialProperties`: Internal helper for generating parameters.
    *   `_mutateProperties`: Internal helper for mutation logic.
    *   `_combinePropertyLogic`: Internal helper for combining properties.
    *   `_adjustPropertiesByCalibration`: Internal helper for calibration logic.

**Function Summary (Highlighting Advanced Concepts):**

*   `generateFragment()`: **Parametric Genesis & On-Chain Pseudorandomness.** Mints a new NFT (Fragment). Its initial properties are not fixed, but derived from the calling address, a counter, and potentially block data (`block.timestamp`, `block.difficulty`, `block.coinbase`) to introduce variation, acting as a form of on-chain pseudorandomness for initialization. Requires ETH payment.
*   `mutateFragment()`: **Dynamic On-Chain State Mutation.** Allows the owner of a Fragment to slightly alter its stored numerical properties (`c_real`, `scale`, etc.) based on defined mutation rules. This adds a progression/gamification layer where NFTs aren't static.
*   `combineFragments()`: **NFT Burning & Recombination.** Burns two source Fragment NFTs and mints a new one. The new Fragment's properties are derived algorithmically from the properties of the two burned parents (e.g., average, weighted average, random selection of parent traits). Introduces scarcity through burning and a mechanism for users to attempt to create Fragments with desired traits.
*   `disperseFragment()`: **Simple NFT Burning.** A basic burn function, but conceptually part of the lifecycle (destruction/dissipation).
*   `attuneFragment()`: **Conditional State Assignment.** Allows assigning a specific `AttunementType` (like 'Fire', 'Water', 'Void') to a Fragment *only if* its current properties meet certain thresholds or combinations defined within the contract. This adds discovery and goal-seeking.
*   `evolveFragment()`: **Multi-Stage Evolution.** Allows a Fragment to transition to a higher `evolvedLevel` (e.g., from 'Seed' to 'Bloom' to 'Nexus'). This is only possible if the Fragment meets complex, potentially multi-faceted criteria based on its properties, generation, attunement, or history (`mutation_count`). Adds a progression system and creates rarer, more powerful forms.
*   `anchorFragment()`: **State Immutability Mechanism.** Makes a specific Fragment's *on-chain properties* (`c_real`, `scale`, etc.) permanently immutable. This is useful for "locking in" desirable traits after mutation/refinement or as a prerequisite for higher evolution stages.
*   `refineProperty()`: **Granular Property Improvement.** Allows targeted improvement of *one specific* numerical property of a Fragment per call, potentially up to a cap. Could require a cooldown, payment, or burning another item (not implemented here for simplicity, but the concept is advanced). This differs from `mutate` which is more random/broad.
*   `calibrateFragment()`: **Block-Driven Property Adjustment.** Adjusts a Fragment's properties based on volatile block-specific data (`block.timestamp`, `block.difficulty`, `block.hash`). This introduces a dynamic element where simply calling the function at a different block height could yield a slightly different outcome, adding an element of chance or timing strategy. Uses bitwise operations on block hash for parameter influence.
*   `linkFragments()`: **On-Chain Relationships.** Creates a persistent, queryable link *between two owned Fragment NFTs*. This could be the basis for future mechanics like combined bonuses, pair evolution, or visual representation in a frontend. It's a non-transferable, state-based relationship stored on-chain.
*   `unlinkFragments()`: **Relationship Management.** Removes the on-chain link between two Fragments.
*   `getFragmentProperties()`: **Structured On-Chain Data Retrieval.** Provides a single call to get the full structured data of a Fragment, essential for off-chain rendering or analysis.
*   `canFragmentEvolve()`: **Complex Conditional Query.** A view function that calculates and returns whether a specific Fragment currently satisfies the criteria required to call `evolveFragment()`, allowing users to check eligibility before attempting the transaction.

This contract combines standard NFT ownership with dynamic, state-changing on-chain mechanics, introducing concepts like on-chain "genetics" (combination), "evolution" (conditional state change), "mutation" (random property change), "anchoring" (immutability), "calibration" (environmental influence), and "relationships" (linking), all driven by properties stored directly on the blockchain.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // Optional: for richer on-chain metadata generation potentially

// --- Contract: FractalGenesis ---
// An advanced, dynamic NFT contract where tokens (Fragments) have on-chain properties
// that can evolve, mutate, combine, anchor, and be influenced by block data.

// --- Outline ---
// 1. License & Pragma
// 2. Imports
// 3. Error Definitions
// 4. Constants & Immutables
// 5. Enums: AttunementType, EvolutionState
// 6. Structs: Fragment
// 7. State Variables: fragments, _tokenIdCounter, generationCost, _paused, baseURI,
//    calibrationParams, evolutionThresholds, fragmentLink
// 8. Events
// 9. Modifiers: whenNotPaused, whenPaused, onlyFragmentOwner, onlyValidFragment
// 10. Constructor
// 11. Core ERC721 Overrides: tokenURI, _baseURI
// 12. Owner Functions: setGenerationCost, withdrawFees, pauseGeneration, unpauseGeneration,
//     setBaseURI, setCalibrationParameters, setEvolutionParameters, mintInitialFragments
// 13. User Interaction Functions: generateFragment, getFragmentProperties, mutateFragment,
//     combineFragments, disperseFragment, attuneFragment, evolveFragment, anchorFragment,
//     refineProperty, calibrateFragment, linkFragments, unlinkFragments
// 14. Query/Helper Functions: isFragmentAnchored, getFragmentAttunement, canFragmentEvolve,
//     getFragmentGenerationCount, getTotalFragmentsMinted, getLinkedFragments,
//     calculateEvolutionCriteria (internal), _generateInitialProperties (internal),
//     _mutateProperties (internal), _combinePropertyLogic (internal),
//     _adjustPropertiesByCalibration (internal)

// --- Function Summary (Highlighting Advanced Concepts) ---
// - generateFragment(): Parametric Genesis & On-Chain Pseudorandomness. Mint a new Fragment NFT.
//   Initial properties are derived from input, block data, and address entropy. Requires payment.
// - mutateFragment(): Dynamic On-Chain State Mutation. Randomly alters some on-chain properties of a Fragment.
// - combineFragments(): NFT Burning & Recombination. Burns two Fragments to create a new one with combined traits.
// - disperseFragment(): Simple NFT Burning. Destroys a Fragment.
// - attuneFragment(): Conditional State Assignment. Assigns a type (AttunementType) if properties meet criteria.
// - evolveFragment(): Multi-Stage Evolution. Advances a Fragment to the next state (EvolutionState) if complex criteria are met.
// - anchorFragment(): State Immutability Mechanism. Makes a Fragment's on-chain properties immutable.
// - refineProperty(): Granular Property Improvement. Improves a specific numerical property (potentially limited).
// - calibrateFragment(): Block-Driven Property Adjustment. Adjusts properties based on current block data.
// - linkFragments(): On-Chain Relationships. Creates a reciprocal, persistent link between two owned Fragments.
// - unlinkFragments(): Relationship Management. Removes an existing link between two Fragments.
// - getFragmentProperties(): Structured On-Chain Data Retrieval. Reads all stored properties for a Fragment.
// - canFragmentEvolve(): Complex Conditional Query. Checks if a Fragment meets the criteria for evolution without attempting it.
// - isFragmentAnchored(): Query Anchored State.
// - getFragmentAttunement(): Query Attunement Type.
// - getLinkedFragments(): Query Linked Token ID.
// - getFragmentGenerationCount(): Stats for user-generated fragments.
// - getTotalFragmentsMinted(): Total fragments minted (including owner).
// - setGenerationCost(), withdrawFees(), pauseGeneration(), unpauseGeneration(), setBaseURI(),
//   setCalibrationParameters(), setEvolutionParameters(), mintInitialFragments(): Standard Owner controls.
// - tokenURI(): Overridden ERC721 metadata function (points to base URI, data handled off-chain based on on-chain properties).

contract FractalGenesis is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- Error Definitions ---
    error FragmentDoesNotExist(uint256 tokenId);
    error NotFragmentOwner(uint256 tokenId);
    error FragmentAnchored(uint256 tokenId);
    error CannotMutateAnchoredFragment(uint256 tokenId);
    error InvalidAttunement(uint8 attunementType);
    error AttunementCriteriaNotMet(uint256 tokenId);
    error EvolutionCriteriaNotMet(uint256 tokenId);
    error FragmentAlreadyEvolved(uint256 tokenId, uint8 currentLevel);
    error FragmentsAlreadyLinked(uint256 tokenId1, uint256 tokenId2);
    error FragmentsNotLinked(uint256 tokenId1, uint256 tokenId2);
    error FragmentsMustBeOwned(uint256 tokenId1, uint256 tokenId2);
    error FragmentsMustBeDifferent(uint256 tokenId1, uint256 tokenId2);
    error CannotDisperseAnchoredFragment(uint256 tokenId);
    error InvalidPropertyIndex(uint8 index);
    error RefinementCapReached(uint256 tokenId, uint8 propertyIndex);
    error CannotCalibrateAnchoredFragment(uint256 tokenId);
    error InvalidGenerationCost();
    error NotEnoughETHForGeneration(uint256 required, uint256 sent);
    error GenerationPaused();

    // --- Constants & Immutables ---
    uint128 public constant C_REAL_SCALE = 1e8; // Scaling factor for fixed-point `c_real`
    uint128 public constant C_IMAGINARY_SCALE = 1e8; // Scaling factor for fixed-point `c_imaginary`
    uint128 public constant SCALE_SCALE = 1e6; // Scaling factor for fixed-point `scale`
    uint16 public constant MAX_ITERATIONS = 1000; // Max allowed iterations
    uint8 public constant MAX_EVOLUTION_LEVEL = 3; // Max evolution level (0, 1, 2, 3)
    uint16 public constant MAX_MUTATION_COUNT = 255; // Cap mutation count

    // --- Enums ---
    enum AttunementType {
        None,
        Ignis,    // Fire
        Aqua,     // Water
        Terra,    // Earth
        Aether,   // Air/Spirit
        Chaos,    // Unpredictable
        Order     // Stable
    }

    enum EvolutionState {
        Seed,
        Bloom,
        Nexus,
        Transcendent // Corresponds to MAX_EVOLUTION_LEVEL
    }

    // --- Structs ---
    struct Fragment {
        uint256 generation; // Which generation this fragment belongs to (0 for initial, 1+ for generated)
        uint256 birthBlock; // Block number when this fragment was minted
        int128 c_real;     // Real part of the complex constant (scaled)
        int128 c_imaginary;// Imaginary part of the complex constant (scaled)
        uint128 scale;    // Scale factor (scaled)
        uint16 iterations; // Max iterations for fractal calculation
        uint32 color_offset; // Offset for color mapping (simple property)
        uint16 mutation_count; // How many times this fragment has been mutated
        AttunementType attunement; // Assigned attunement type
        bool isAnchored;   // If true, properties cannot be changed (except potentially evolution)
        uint8 evolvedLevel;// Current evolution level (0 to MAX_EVOLUTION_LEVEL)
    }

    // --- State Variables ---
    mapping(uint256 => Fragment) public fragments;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _generationCounter; // Counts user-generated fragments specifically

    uint256 public generationCost; // Cost in wei to generate a new fragment

    bool private _paused = false;

    string private _baseTokenURI;

    // Parameters influencing calibrateFragment (Owner settable for game balance)
    struct CalibrationParameters {
        uint8 cRealFactor; // Factor for c_real adjustment
        uint8 cImaginaryFactor; // Factor for c_imaginary adjustment
        uint8 scaleFactor; // Factor for scale adjustment
        uint8 iterationsFactor; // Factor for iterations adjustment
    }
    CalibrationParameters public calibrationParams;

    // Parameters/Thresholds for Evolution (Owner settable)
    struct EvolutionThresholds {
        uint16 minMutationCount;
        uint16 minIterations;
        uint128 minScale; // Scaled
        AttunementType requiredAttunement; // None if no specific attunement is required
        uint8 requiredEvolvedLevel; // Must be at this level to evolve to the next
    }
    EvolutionThresholds public evolutionThresholds;

    // Mapping for fragment linking (tokenId => linkedTokenId). 0 means not linked.
    mapping(uint256 => uint256) public fragmentLink;

    // --- Events ---
    event FragmentGenerated(uint256 indexed tokenId, address indexed owner, uint256 generation, uint256 generationCost);
    event FragmentMutated(uint256 indexed tokenId, address indexed mutator, uint16 newMutationCount);
    event FragmentsCombined(uint256 indexed parentTokenId1, uint256 indexed parentTokenId2, uint256 indexed newTokenId);
    event FragmentDispersed(uint256 indexed tokenId, address indexed disperser);
    event FragmentAttuned(uint256 indexed tokenId, AttunementType attunementType);
    event FragmentEvolved(uint256 indexed tokenId, uint8 newEvolutionLevel);
    event FragmentAnchored(uint256 indexed tokenId);
    event FragmentPropertyRefined(uint256 indexed tokenId, uint8 propertyIndex, int256 newValue); // int256 to cover scaled signed values
    event FragmentCalibrated(uint256 indexed tokenId);
    event FragmentsLinked(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event FragmentsUnlinked(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event GenerationCostUpdated(uint256 newCost);
    event GenerationPausedStateChanged(bool isPaused);

    // --- Modifiers ---
    modifier whenNotPaused() {
        if (_paused) revert GenerationPaused();
        _;
    }

    modifier whenPaused() {
        require(_paused, "Not paused");
        _;
    }

    modifier onlyFragmentOwner(uint256 tokenId) {
        if (_ownerOf(tokenId) != msg.sender) revert NotFragmentOwner(tokenId);
        _;
    }

    modifier onlyValidFragment(uint256 tokenId) {
        if (!fragments[tokenId].birthBlock > 0 || _exists(tokenId) == false) revert FragmentDoesNotExist(tokenId);
        _;
    }

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        uint256 _initialGenerationCost,
        string memory _initialBaseURI
    ) ERC721(name, symbol) Ownable(msg.sender) {
        if (_initialGenerationCost == 0) revert InvalidGenerationCost();
        generationCost = _initialGenerationCost;
        _baseTokenURI = _initialBaseURI;

        // Set initial calibration parameters (example values)
        calibrationParams = CalibrationParameters({
            cRealFactor: 1,
            cImaginaryFactor: 1,
            scaleFactor: 1,
            iterationsFactor: 1
        });

        // Set initial evolution thresholds (example values - can be adjusted by owner)
        evolutionThresholds = EvolutionThresholds({
            minMutationCount: 10,
            minIterations: 500,
            minScale: 500 * SCALE_SCALE, // Example: require scale 500+
            requiredAttunement: AttunementType.Terra, // Example: requires Earth attunement
            requiredEvolvedLevel: uint8(EvolutionState.Seed) // Must be Seed to evolve to Bloom
        });
    }

    // --- Core ERC721 Overrides ---

    /// @dev See {IERC721Metadata-tokenURI}.
    /// @dev Note: Metadata should typically be served from IPFS/centralized server
    /// based on the on-chain properties retrieved by `getFragmentProperties`.
    /// This function returns a base URI and token ID, allowing a metadata service
    /// to fetch the correct JSON based on the on-chain state.
    function tokenURI(uint256 tokenId) public view override onlyValidFragment(tokenId) returns (string memory) {
        // Construct metadata URI pointing to a service that reads on-chain state
        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            return ""; // No base URI set
        }
        // Append token ID
        return string(abi.encodePacked(base, Strings.toString(tokenId)));

        // Alternative (more complex/gas heavy): Generate Base64 encoded JSON on-chain
        // This is for demonstration of on-chain data, not practical for complex metadata.
        // Fragment memory frag = fragments[tokenId];
        // string memory json = string(abi.encodePacked(
        //     '{"name": "Fractal Fragment #', Strings.toString(tokenId),
        //     '", "description": "A dynamic fractal entity.",',
        //     '"attributes": [',
        //     '{"trait_type": "Generation", "value": ', Strings.toString(frag.generation), '},',
        //     '{"trait_type": "Birth Block", "value": ', Strings.toString(frag.birthBlock), '},',
        //     '{"trait_type": "C_Real", "value": ', Strings.toString(frag.c_real), '},', // Note: Need to handle fixed point display off-chain
        //     '{"trait_type": "C_Imaginary", "value": ', Strings.toString(frag.c_imaginary), '},', // Note: Need to handle fixed point display off-chain
        //     '{"trait_type": "Scale", "value": ', Strings.toString(frag.scale), '},', // Note: Need to handle fixed point display off-chain
        //     '{"trait_type": "Iterations", "value": ', Strings.toString(frag.iterations), '},',
        //     '{"trait_type": "Color Offset", "value": ', Strings.toString(frag.color_offset), '},',
        //     '{"trait_type": "Mutation Count", "value": ', Strings.toString(frag.mutation_count), '},',
        //     '{"trait_type": "Attunement", "value": "', _attunementTypeToString(frag.attunement), '"},',
        //     '{"trait_type": "Anchored", "value": ', frag.isAnchored ? "true" : "false", '},',
        //     '{"trait_type": "Evolution Level", "value": "', _evolutionStateToString(EvolutionState(frag.evolvedLevel)), '"}',
        //     // Add linked token ID if exists
        //     fragmentLink[tokenId] != 0 ? string(abi.encodePacked(',{"trait_type": "Linked Token ID", "value": ', Strings.toString(fragmentLink[tokenId]), '}')) : "",
        //     ']}'
        // ));
        // return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(json))));
    }

    /// @dev See {ERC721-_baseURI}.
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // --- Owner Functions ---

    /// @dev Sets the cost in wei to generate a new fragment.
    /// @param _newCost The new cost in wei.
    function setGenerationCost(uint256 _newCost) external onlyOwner {
        if (_newCost == 0) revert InvalidGenerationCost();
        generationCost = _newCost;
        emit GenerationCostUpdated(_newCost);
    }

    /// @dev Allows the owner to withdraw collected generation fees.
    function withdrawFees() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    /// @dev Pauses the fragment generation function.
    function pauseGeneration() external onlyOwner whenNotPaused {
        _paused = true;
        emit GenerationPausedStateChanged(true);
    }

    /// @dev Unpauses the fragment generation function.
    function unpauseGeneration() external onlyOwner whenPaused {
        _paused = false;
        emit GenerationPausedStateChanged(false);
    }

    /// @dev Sets the base URI for token metadata.
    function setBaseURI(string memory uri) external onlyOwner {
        _baseTokenURI = uri;
    }

    /// @dev Sets the parameters used for the calibrateFragment function.
    /// @param _cRealFactor Factor for c_real adjustment (0-255)
    /// @param _cImaginaryFactor Factor for c_imaginary adjustment (0-255)
    /// @param _scaleFactor Factor for scale adjustment (0-255)
    /// @param _iterationsFactor Factor for iterations adjustment (0-255)
    function setCalibrationParameters(
        uint8 _cRealFactor,
        uint8 _cImaginaryFactor,
        uint8 _scaleFactor,
        uint8 _iterationsFactor
    ) external onlyOwner {
        calibrationParams = CalibrationParameters({
            cRealFactor: _cRealFactor,
            cImaginaryFactor: _cImaginaryFactor,
            scaleFactor: _scaleFactor,
            iterationsFactor: _iterationsFactor
        });
    }

    /// @dev Sets the thresholds and requirements for evolving a fragment.
    /// @param _minMutationCount Minimum mutation count required.
    /// @param _minIterations Minimum iterations value required.
    /// @param _minScale Minimum scale value required (scaled).
    /// @param _requiredAttunement Required AttunementType (0 for None).
    /// @param _requiredEvolvedLevel Required current evolution level to advance from.
    function setEvolutionParameters(
        uint16 _minMutationCount,
        uint16 _minIterations,
        uint128 _minScale,
        AttunementType _requiredAttunement,
        uint8 _requiredEvolvedLevel
    ) external onlyOwner {
        if (_requiredEvolvedLevel > MAX_EVOLUTION_LEVEL - 1) {
            revert InvalidEvolutionCriteriaNotMet(); // Cannot set requirement beyond last level-1
        }
         if (_minIterations > MAX_ITERATIONS) {
            revert InvalidEvolutionCriteriaNotMet(); // Iterations cap
        }

        evolutionThresholds = EvolutionThresholds({
            minMutationCount: _minMutationCount,
            minIterations: _minIterations,
            minScale: _minScale,
            requiredAttunement: _requiredAttunement,
            requiredEvolvedLevel: _requiredEvolvedLevel
        });
    }

    /// @dev Allows the owner to mint initial generation 0 fragments.
    /// @param recipient Address to mint to.
    /// @param count Number of fragments to mint.
    function mintInitialFragments(address recipient, uint256 count) external onlyOwner {
        uint256 currentTokenId = _tokenIdCounter.current();
        for (uint256 i = 0; i < count; i++) {
            _tokenIdCounter.increment();
            uint256 newTokenId = _tokenIdCounter.current();

            Fragment memory newFrag;
            newFrag.generation = 0; // Initial generation
            newFrag.birthBlock = block.number;
            // Generate properties based on current state/entropy
            (newFrag.c_real, newFrag.c_imaginary, newFrag.scale, newFrag.iterations, newFrag.color_offset) =
                _generateInitialProperties(newTokenId, block.timestamp, uint256(block.difficulty), uint256(block.coinbase));

            newFrag.mutation_count = 0;
            newFrag.attunement = AttunementType.None;
            newFrag.isAnchored = false;
            newFrag.evolvedLevel = uint8(EvolutionState.Seed);

            fragments[newTokenId] = newFrag;
            _safeMint(recipient, newTokenId);

            emit FragmentGenerated(newTokenId, recipient, 0, 0); // Cost 0 for owner mints
        }
    }


    // --- User Interaction Functions ---

    /// @dev Allows a user to generate and mint a new fragment.
    /// @dev Initial properties are derived from transaction data and block data.
    function generateFragment() external payable nonReentrant whenNotPaused {
        if (msg.value < generationCost) revert NotEnoughETHForGeneration(generationCost, msg.value);
        if (generationCost > 0) {
             // Refund excess ETH if any, though require should prevent this if value == cost
             // If allowing > cost, uncomment this:
             // if (msg.value > generationCost) {
             //     (bool success, ) = payable(msg.sender).call{value: msg.value - generationCost}("");
             //     require(success, "Refund failed");
             // }
        }


        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _generationCounter.increment(); // Count user generations

        Fragment memory newFrag;
        newFrag.generation = _generationCounter.current(); // Generation based on user mints
        newFrag.birthBlock = block.number;

        // --- Parametric Genesis & On-Chain Pseudorandomness ---
        // Derive initial properties using a mix of transaction/block data for entropy
        (newFrag.c_real, newFrag.c_imaginary, newFrag.scale, newFrag.iterations, newFrag.color_offset) =
            _generateInitialProperties(newTokenId, block.timestamp, uint256(block.difficulty), uint256(block.coinbase));
        // Ensure iterations is within bounds
        if (newFrag.iterations == 0) newFrag.iterations = 1; // Prevent zero iterations
        if (newFrag.iterations > MAX_ITERATIONS) newFrag.iterations = MAX_ITERATIONS;
         if (newFrag.scale == 0) newFrag.scale = SCALE_SCALE; // Prevent zero scale

        newFrag.mutation_count = 0;
        newFrag.attunement = AttunementType.None;
        newFrag.isAnchored = false;
        newFrag.evolvedLevel = uint8(EvolutionState.Seed);

        fragments[newTokenId] = newFrag;
        _safeMint(msg.sender, newTokenId);

        emit FragmentGenerated(newTokenId, msg.sender, newFrag.generation, generationCost);
    }

    /// @dev Reads the detailed properties of a fragment.
    /// @param tokenId The ID of the fragment.
    /// @return A tuple containing all fragment properties.
    function getFragmentProperties(uint256 tokenId)
        public
        view
        onlyValidFragment(tokenId)
        returns (
            uint256 generation,
            uint256 birthBlock,
            int128 c_real,
            int128 c_imaginary,
            uint128 scale,
            uint16 iterations,
            uint32 color_offset,
            uint16 mutation_count,
            AttunementType attunement,
            bool isAnchored,
            uint8 evolvedLevel
        )
    {
        Fragment storage frag = fragments[tokenId];
        return (
            frag.generation,
            frag.birthBlock,
            frag.c_real,
            frag.c_imaginary,
            frag.scale,
            frag.iterations,
            frag.color_offset,
            frag.mutation_count,
            frag.attunement,
            frag.isAnchored,
            frag.evolvedLevel
        );
    }

    /// @dev Randomly mutates some properties of a fragment.
    /// @param tokenId The ID of the fragment to mutate.
    function mutateFragment(uint256 tokenId) external onlyFragmentOwner(tokenId) onlyValidFragment(tokenId) nonReentrant {
        if (fragments[tokenId].isAnchored) revert CannotMutateAnchoredFragment(tokenId);
        if (fragments[tokenId].mutation_count >= MAX_MUTATION_COUNT) revert RefinementCapReached(tokenId, 255); // Use 255 as a generic code

        Fragment storage frag = fragments[tokenId];

        // --- Dynamic On-Chain State Mutation ---
        // Use blockhash and other entropy sources for pseudorandom changes
        bytes32 entropy = keccak256(abi.encodePacked(
            tokenId,
            msg.sender,
            block.timestamp,
            block.number,
            blockhash(block.number - 1) // Use previous block hash for better randomness source
        ));

        _mutateProperties(frag, entropy);

        // Cap iterations and scale to prevent overflow/extreme values
        if (frag.iterations == 0) frag.iterations = 1;
        if (frag.iterations > MAX_ITERATIONS) frag.iterations = MAX_ITERATIONS;
        if (frag.scale == 0) frag.scale = SCALE_SCALE; // Prevent zero scale

        frag.mutation_count++;

        emit FragmentMutated(tokenId, msg.sender, frag.mutation_count);
    }

    /// @dev Burns two fragments and mints a new one with combined properties.
    /// @param tokenId1 The ID of the first parent fragment.
    /// @param tokenId2 The ID of the second parent fragment.
    function combineFragments(uint256 tokenId1, uint256 tokenId2) external onlyFragmentOwner(tokenId1) onlyValidFragment(tokenId1) nonReentrant {
        if (tokenId1 == tokenId2) revert FragmentsMustBeDifferent(tokenId1, tokenId2);
        if (_ownerOf(tokenId2) != msg.sender) revert FragmentsMustBeOwned(tokenId1, tokenId2); // Ensure owner also owns the second fragment
        if (!fragments[tokenId2].birthBlock > 0) revert FragmentDoesNotExist(tokenId2);

        // Cannot combine anchored fragments
        if (fragments[tokenId1].isAnchored) revert CannotMutateAnchoredFragment(tokenId1); // Re-use error
        if (fragments[tokenId2].isAnchored) revert CannotMutateAnchoredFragment(tokenId2); // Re-use error

        Fragment storage frag1 = fragments[tokenId1];
        Fragment storage frag2 = fragments[tokenId2];

        // --- NFT Burning & Recombination ---
        _burn(tokenId1);
        _burn(tokenId2);
        // Note: Fragment struct data for burned tokens remains in mapping but should be ignored if _exists is false

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _generationCounter.increment();

        Fragment memory newFrag;
        newFrag.generation = _generationCounter.current();
        newFrag.birthBlock = block.number;
        newFrag.mutation_count = 0; // Reset mutation count for new fragment
        newFrag.attunement = AttunementType.None; // Reset attunement
        newFrag.isAnchored = false; // Not anchored initially
        newFrag.evolvedLevel = uint8(EvolutionState.Seed); // Starts as Seed

        // Combine properties using a defined logic (example: average or mix)
        (newFrag.c_real, newFrag.c_imaginary, newFrag.scale, newFrag.iterations, newFrag.color_offset) =
            _combinePropertyLogic(frag1, frag2, blockhash(block.number - 1)); // Use prev block hash for entropy

        // Ensure iterations and scale are within bounds
        if (newFrag.iterations == 0) newFrag.iterations = 1;
        if (newFrag.iterations > MAX_ITERATIONS) newFrag.iterations = MAX_ITERATIONS;
         if (newFrag.scale == 0) newFrag.scale = SCALE_SCALE; // Prevent zero scale

        fragments[newTokenId] = newFrag;
        _safeMint(msg.sender, newTokenId);

        emit FragmentsCombined(tokenId1, tokenId2, newTokenId);
        emit FragmentGenerated(newTokenId, msg.sender, newFrag.generation, 0); // Combination doesn't cost ETH directly
    }

    /// @dev Burns a fragment, removing it from existence.
    /// @param tokenId The ID of the fragment to disperse.
    function disperseFragment(uint256 tokenId) external onlyFragmentOwner(tokenId) onlyValidFragment(tokenId) {
         if (fragments[tokenId].isAnchored) revert CannotDisperseAnchoredFragment(tokenId);

        // Check for existing link and unlink first
        if (fragmentLink[tokenId] != 0) {
            _unlinkFragmentsInternal(tokenId, fragmentLink[tokenId]);
        }

        _burn(tokenId);
        // Optional: Delete fragment data to save gas on future lookups, but mapping default is 0 anyway
        // delete fragments[tokenId]; // This isn't strictly necessary as _exists check handles burned tokens

        emit FragmentDispersed(tokenId, msg.sender);
    }

    /// @dev Attempts to assign an attunement type to a fragment based on its properties.
    /// @param tokenId The ID of the fragment to attune.
    /// @param attunementType The desired attunement type.
    function attuneFragment(uint256 tokenId, AttunementType attunementType)
        external
        onlyFragmentOwner(tokenId)
        onlyValidFragment(tokenId)
    {
        if (attunementType == AttunementType.None) revert InvalidAttunement(uint8(attunementType));
        if (fragments[tokenId].isAnchored) revert CannotMutateAnchoredFragment(tokenId); // Re-use error

        Fragment storage frag = fragments[tokenId];

        // --- Conditional State Assignment ---
        // Check if the fragment's properties meet the criteria for the requested attunement
        // Example Criteria (implement complex logic here based on attunementType):
        bool criteriaMet = false;
        if (attunementType == AttunementType.Ignis) {
            // Example: High iterations and positive c_real
            if (frag.iterations >= 800 && frag.c_real > 0) criteriaMet = true;
        } else if (attunementType == AttunementType.Aqua) {
            // Example: Low scale and negative c_imaginary
             if (frag.scale <= 200 * SCALE_SCALE && frag.c_imaginary < 0) criteriaMet = true;
        } else if (attunementType == AttunementType.Terra) {
            // Example: High scale and specific color offset range
             if (frag.scale >= 700 * SCALE_SCALE && frag.color_offset >= 1000000 && frag.color_offset <= 2000000) criteriaMet = true;
        } else if (attunementType == AttunementType.Aether) {
            // Example: Low mutation count and high iteration/scale ratio
            if (frag.mutation_count <= 5 && (frag.iterations * SCALE_SCALE / frag.scale) >= 2) criteriaMet = true; // Example ratio check
        } else if (attunementType == AttunementType.Chaos) {
            // Example: High mutation count and certain block data pattern (e.g., last byte of blockhash)
            bytes32 lastBlockHash = blockhash(block.number - 1);
            if (frag.mutation_count >= 100 && (uint8(lastBlockHash[31]) % 10) >= 7) criteriaMet = true;
        } else if (attunementType == AttunementType.Order) {
             // Example: Low mutation count and specific birth block range
             if (frag.mutation_count <= 5 && frag.birthBlock >= 10000000 && frag.birthBlock <= 12000000) criteriaMet = true; // Example: check for specific block range
        }
        // Add more complex criteria combining multiple properties and external factors (like block data)

        if (!criteriaMet) revert AttunementCriteriaNotMet(tokenId);

        frag.attunement = attunementType;
        emit FragmentAttuned(tokenId, attunementType);
    }

    /// @dev Attempts to evolve a fragment to the next stage based on evolution thresholds.
    /// @param tokenId The ID of the fragment to evolve.
    function evolveFragment(uint256 tokenId) external onlyFragmentOwner(tokenId) onlyValidFragment(tokenId) nonReentrant {
        Fragment storage frag = fragments[tokenId];

        if (frag.evolvedLevel >= MAX_EVOLUTION_LEVEL) revert FragmentAlreadyEvolved(tokenId, frag.evolvedLevel);

        // --- Multi-Stage Evolution & Complex Conditional Logic ---
        // Check if the fragment meets the criteria to evolve to the *next* level
        if (frag.evolvedLevel != evolutionThresholds.requiredEvolvedLevel) {
             revert EvolutionCriteriaNotMet(tokenId); // Must be at the specific required level to trigger *this* evolution path
        }

        if (!calculateEvolutionCriteria(tokenId)) {
            revert EvolutionCriteriaNotMet(tokenId);
        }

        // Evolution successful
        frag.evolvedLevel++;

        // Optional: Evolution could modify properties significantly, change attunement, or grant new abilities/traits (not fully implemented here)
        // Example: Reset mutation count or add a boost
        // frag.mutation_count = 0;
        // frag.attunement = AttunementType.None; // Maybe evolving changes attunement?

        emit FragmentEvolved(tokenId, frag.evolvedLevel);
    }

    /// @dev Makes a fragment's core properties immutable.
    /// @param tokenId The ID of the fragment to anchor.
    function anchorFragment(uint256 tokenId) external onlyFragmentOwner(tokenId) onlyValidFragment(tokenId) {
        if (fragments[tokenId].isAnchored) revert FragmentAnchored(tokenId);

        // Optional: Require criteria to be met before anchoring (e.g., minimum evolution level)
        // if (fragments[tokenId].evolvedLevel < uint8(EvolutionState.Bloom)) revert EvolutionCriteriaNotMet(tokenId); // Example

        fragments[tokenId].isAnchored = true;
        emit FragmentAnchored(tokenId);
    }

    /// @dev Attempts to refine a specific property of a fragment.
    /// @param tokenId The ID of the fragment to refine.
    /// @param propertyIndex Index indicating which property to refine (e.g., 0=c_real, 1=c_imaginary, 2=scale, 3=iterations, 4=color_offset).
    /// @param refinementAmount How much to refine the property (scaled for fixed-point).
    function refineProperty(uint256 tokenId, uint8 propertyIndex, int256 refinementAmount)
        external
        onlyFragmentOwner(tokenId)
        onlyValidFragment(tokenId)
        nonReentrant
    {
        if (fragments[tokenId].isAnchored) revert CannotMutateAnchoredFragment(tokenId);

        Fragment storage frag = fragments[tokenId];

        // --- Granular Property Improvement ---
        // Implement logic here, potentially costing gas, requiring item burns, or having cooldowns
        // For simplicity, this version just applies the refinement directly if not anchored.

        int256 oldValue;
        int256 newValue;

        if (propertyIndex == 0) { // c_real
             // Check against potential max/min caps if needed
            oldValue = frag.c_real;
            frag.c_real = frag.c_real + int128(refinementAmount);
            newValue = frag.c_real;
        } else if (propertyIndex == 1) { // c_imaginary
            oldValue = frag.c_imaginary;
            frag.c_imaginary = frag.c_imaginary + int128(refinementAmount);
             newValue = frag.c_imaginary;
        } else if (propertyIndex == 2) { // scale
             // Scale is uint128, need care with signed refinementAmount
            oldValue = int256(frag.scale);
            if (refinementAmount < 0) {
                 if (frag.scale < uint128(-refinementAmount)) frag.scale = 0;
                 else frag.scale -= uint128(-refinementAmount);
            } else {
                 frag.scale += uint128(refinementAmount);
            }
             if (frag.scale == 0) frag.scale = SCALE_SCALE; // Prevent zero scale
            newValue = int256(frag.scale);
        } else if (propertyIndex == 3) { // iterations
             // Iterations is uint16, need care
            oldValue = frag.iterations;
             if (refinementAmount < 0) {
                 if (frag.iterations < uint16(-refinementAmount)) frag.iterations = 0;
                 else frag.iterations -= uint16(-refinementAmount);
             } else {
                 frag.iterations += uint16(refinementAmount);
             }
             if (frag.iterations == 0) frag.iterations = 1; // Prevent zero iterations
             if (frag.iterations > MAX_ITERATIONS) frag.iterations = MAX_ITERATIONS;
            newValue = frag.iterations;
        } else if (propertyIndex == 4) { // color_offset
             // color_offset is uint32
            oldValue = frag.color_offset;
             if (refinementAmount < 0) {
                 if (frag.color_offset < uint32(-refinementAmount)) frag.color_offset = 0;
                 else frag.color_offset -= uint32(-refinementAmount);
             } else {
                 frag.color_offset += uint32(refinementAmount);
             }
             newValue = frag.color_offset;
        } else {
            revert InvalidPropertyIndex(propertyIndex);
        }

        // Increment mutation count even for targeted refinement (optional logic)
        if (frag.mutation_count < MAX_MUTATION_COUNT) {
            frag.mutation_count++;
        }

        emit FragmentPropertyRefined(tokenId, propertyIndex, newValue);
         emit FragmentMutated(tokenId, msg.sender, frag.mutation_count); // Also emit mutation event
    }

    /// @dev Adjusts fragment properties based on current block data (timestamp, difficulty, hash).
    /// @param tokenId The ID of the fragment to calibrate.
    function calibrateFragment(uint256 tokenId) external onlyFragmentOwner(tokenId) onlyValidFragment(tokenId) nonReentrant {
         if (fragments[tokenId].isAnchored) revert CannotCalibrateAnchoredFragment(tokenId);

        Fragment storage frag = fragments[tokenId];

        // --- Block-Driven Property Adjustment ---
        // Use block data to influence properties. This makes the outcome time/block dependent.
        bytes32 blockEntropy = blockhash(block.number - 1); // Using previous block hash
        if (blockEntropy == bytes32(0)) {
             // Handle case where blockhash is not available (very recent blocks)
             blockEntropy = keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender));
        }

        _adjustPropertiesByCalibration(frag, blockEntropy);

         // Ensure iterations and scale are within bounds
        if (frag.iterations == 0) frag.iterations = 1;
        if (frag.iterations > MAX_ITERATIONS) frag.iterations = MAX_ITERATIONS;
         if (frag.scale == 0) frag.scale = SCALE_SCALE; // Prevent zero scale

        // Calibration also counts as a form of mutation/change
         if (frag.mutation_count < MAX_MUTATION_COUNT) {
             frag.mutation_count++;
         }

        emit FragmentCalibrated(tokenId);
         emit FragmentMutated(tokenId, msg.sender, frag.mutation_count); // Also emit mutation event
    }

    /// @dev Creates a reciprocal on-chain link between two owned fragments.
    /// @param tokenId1 The ID of the first fragment.
    /// @param tokenId2 The ID of the second fragment.
    function linkFragments(uint256 tokenId1, uint256 tokenId2)
        external
        onlyFragmentOwner(tokenId1)
        onlyValidFragment(tokenId1)
        nonReentrant
    {
        if (tokenId1 == tokenId2) revert FragmentsMustBeDifferent(tokenId1, tokenId2);
        if (_ownerOf(tokenId2) != msg.sender) revert FragmentsMustBeOwned(tokenId1, tokenId2); // Ensure owner also owns the second fragment
        if (!fragments[tokenId2].birthBlock > 0) revert FragmentDoesNotExist(tokenId2);

        // Cannot link anchored fragments (optional rule)
        // if (fragments[tokenId1].isAnchored || fragments[tokenId2].isAnchored) revert CannotMutateAnchoredFragment(tokenId1); // Re-use error

        if (fragmentLink[tokenId1] != 0 || fragmentLink[tokenId2] != 0) revert FragmentsAlreadyLinked(tokenId1, tokenId2);

        // --- On-Chain Relationships ---
        fragmentLink[tokenId1] = tokenId2;
        fragmentLink[tokenId2] = tokenId1; // Reciprocal link

        emit FragmentsLinked(tokenId1, tokenId2);
    }

     /// @dev Removes the on-chain link between two fragments.
    /// @param tokenId1 The ID of one of the linked fragments.
    /// @param tokenId2 The ID of the other linked fragment.
    function unlinkFragments(uint256 tokenId1, uint256 tokenId2)
        external
        onlyFragmentOwner(tokenId1)
        onlyValidFragment(tokenId1)
        nonReentrant
    {
        if (tokenId1 == tokenId2) revert FragmentsMustBeDifferent(tokenId1, tokenId2);
         // Owner must own at least one fragment to initiate unlink. We already check tokenId1 ownership.
         // If tokenId2 owner is different, they would need to call from their side or we'd need approval/permission logic (more complex).
         // Let's require owner to own both for simplicity in this example.
        if (_ownerOf(tokenId2) != msg.sender) revert FragmentsMustBeOwned(tokenId1, tokenId2);
        if (!fragments[tokenId2].birthBlock > 0) revert FragmentDoesNotExist(tokenId2);

        if (fragmentLink[tokenId1] != tokenId2 || fragmentLink[tokenId2] != tokenId1) revert FragmentsNotLinked(tokenId1, tokenId2);

        // --- Relationship Management ---
        _unlinkFragmentsInternal(tokenId1, tokenId2);
        emit FragmentsUnlinked(tokenId1, tokenId2);
    }

    // Internal helper for unlinking
    function _unlinkFragmentsInternal(uint256 tokenId1, uint256 tokenId2) internal {
        delete fragmentLink[tokenId1];
        delete fragmentLink[tokenId2];
    }

    // --- Query/Helper Functions ---

    /// @dev Checks if a fragment is anchored.
    /// @param tokenId The ID of the fragment.
    /// @return True if anchored, false otherwise.
    function isFragmentAnchored(uint256 tokenId) public view onlyValidFragment(tokenId) returns (bool) {
        return fragments[tokenId].isAnchored;
    }

    /// @dev Gets the attunement type of a fragment.
    /// @param tokenId The ID of the fragment.
    /// @return The AttunementType enum value.
    function getFragmentAttunement(uint256 tokenId) public view onlyValidFragment(tokenId) returns (AttunementType) {
        return fragments[tokenId].attunement;
    }

    /// @dev Checks if a fragment meets the current evolution criteria for its level.
    /// @param tokenId The ID of the fragment.
    /// @return True if evolution criteria are met, false otherwise.
    function canFragmentEvolve(uint256 tokenId) public view onlyValidFragment(tokenId) returns (bool) {
         Fragment storage frag = fragments[tokenId];
         if (frag.evolvedLevel >= MAX_EVOLUTION_LEVEL) return false; // Already at max level
         if (frag.evolvedLevel != evolutionThresholds.requiredEvolvedLevel) return false; // Not at the correct starting level for this evolution path

         // --- Complex Conditional Query ---
         return calculateEvolutionCriteria(tokenId);
    }

    /// @dev Internal helper to check if evolution criteria are met based on current state and thresholds.
    function calculateEvolutionCriteria(uint256 tokenId) internal view returns (bool) {
         Fragment storage frag = fragments[tokenId];

         bool criteriaMet = true;
         if (frag.mutation_count < evolutionThresholds.minMutationCount) criteriaMet = false;
         if (frag.iterations < evolutionThresholds.minIterations) criteriaMet = false;
         if (frag.scale < evolutionThresholds.minScale) criteriaMet = false;
         if (evolutionThresholds.requiredAttunement != AttunementType.None && frag.attunement != evolutionThresholds.requiredAttunement) criteriaMet = false;

         // Add more complex criteria here if needed, e.g., based on birth block, generation, linked fragment state, etc.
         // Example: require a linked fragment
         // if (fragmentLink[tokenId] == 0) criteriaMet = false;

         return criteriaMet;
    }


    /// @dev Gets the total count of fragments generated by users (not including owner initial mints).
    function getFragmentGenerationCount() public view returns (uint256) {
        return _generationCounter.current();
    }

    /// @dev Gets the total number of fragments ever minted (including owner initial mints).
    function getTotalFragmentsMinted() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /// @dev Gets the token ID of the fragment linked to the given fragment.
    /// @param tokenId The ID of the fragment.
    /// @return The token ID of the linked fragment, or 0 if not linked.
    function getLinkedFragments(uint256 tokenId) public view onlyValidFragment(tokenId) returns (uint256) {
        return fragmentLink[tokenId];
    }

    // --- Internal Helpers for Property Logic ---

    /// @dev Internal helper to generate initial fragment properties.
    /// @param seed1 Used with keccak256 for entropy (e.g., tokenId)
    /// @param seed2 Used with keccak256 for entropy (e.g., block.timestamp)
    /// @param seed3 Used with keccak256 for entropy (e.g., block.difficulty)
    /// @param seed4 Used with keccak256 for entropy (e.g., block.coinbase or msg.sender)
    /// @return Initial c_real, c_imaginary, scale, iterations, color_offset.
    function _generateInitialProperties(
        uint256 seed1,
        uint256 seed2,
        uint256 seed3,
        uint256 seed4
    )
        internal
        pure
        returns (int128 c_real, int128 c_imaginary, uint128 scale, uint16 iterations, uint32 color_offset)
    {
        bytes32 hash = keccak256(abi.encodePacked(seed1, seed2, seed3, seed4));

        // Extract values using bit shifts and type casting
        // Example ranges based on common Mandelbrot/Julia set values:
        // c_real: -2.0 to 1.0 (scaled)
        // c_imaginary: -1.5 to 1.5 (scaled)
        // scale: 1.0 to 1000.0 (scaled)
        // iterations: 100 to 1000
        // color_offset: 0 to uint32 max

        // c_real: Extract 32 bytes, treat as uint256, map to range [-2 * C_REAL_SCALE, 1 * C_REAL_SCALE]
        uint256 raw_c_real = uint256(hash);
        c_real = int128(int256(raw_c_real % (3 * C_REAL_SCALE)) - int256(2 * C_REAL_SCALE)); // Maps to [-2.0, 1.0]

        // c_imaginary: Extract next 32 bytes
        uint256 raw_c_imaginary = uint256(keccak256(abi.encodePacked(hash, "c_imaginary")));
        c_imaginary = int128(int256(raw_c_imaginary % (3 * C_IMAGINARY_SCALE)) - int256(1.5 * C_IMAGINARY_SCALE)); // Maps to [-1.5, 1.5]

        // scale: Extract next 32 bytes, map to range [1 * SCALE_SCALE, 1000 * SCALE_SCALE]
        uint256 raw_scale = uint256(keccak256(abi.encodePacked(hash, "scale")));
        scale = uint128(raw_scale % (999 * SCALE_SCALE) + 1 * SCALE_SCALE); // Maps to [1.0, 1000.0]

        // iterations: Extract next 32 bytes, map to range [100, 1000]
        uint256 raw_iterations = uint256(keccak256(abi.encodePacked(hash, "iterations")));
        iterations = uint16(raw_iterations % 901 + 100); // Maps to [100, 1000]

        // color_offset: Extract next 32 bytes, map to uint32 range
        uint256 raw_color_offset = uint256(keccak256(abi.encodePacked(hash, "color_offset")));
        color_offset = uint32(raw_color_offset); // Use full range

        // Simple safeguard for iterations
        if (iterations == 0) iterations = 1;
         if (iterations > MAX_ITERATIONS) iterations = MAX_ITERATIONS;
        if (scale == 0) scale = SCALE_SCALE; // Safeguard for scale

        return (c_real, c_imaginary, scale, iterations, color_offset);
    }

    /// @dev Internal helper to apply mutation logic.
    /// @param frag The fragment struct to mutate (storage pointer).
    /// @param entropy Source of randomness for mutation.
    function _mutateProperties(Fragment storage frag, bytes32 entropy) internal pure {
        uint256 rand = uint256(entropy);

        // Apply small random changes
        // Mutate c_real based on first 16 bits of rand
        int256 delta_c_real = int16(uint16(rand % 65536)) - 32768; // Map 0-65535 to -32768 to 32767
        frag.c_real += int128(delta_c_real * int256(C_REAL_SCALE) / 500000); // Scale down change effect

        // Mutate c_imaginary based on next 16 bits
        int256 delta_c_imaginary = int16(uint16((rand >> 16) % 65536)) - 32768;
        frag.c_imaginary += int128(delta_c_imaginary * int256(C_IMAGINARY_SCALE) / 500000); // Scale down change effect

        // Mutate scale based on next 16 bits (treat as unsigned delta)
        uint256 delta_scale = uint16((rand >> 32) % 65536);
        if (delta_scale % 2 == 0) { // Randomly increase or decrease
            frag.scale += uint128(delta_scale * uint256(SCALE_SCALE) / 1000000); // Increase
        } else {
             if (frag.scale > uint128(delta_scale * uint256(SCALE_SCALE) / 1000000)) {
                frag.scale -= uint128(delta_scale * uint256(SCALE_SCALE) / 1000000); // Decrease
             } else {
                 frag.scale = SCALE_SCALE; // Minimum scale
             }
        }


        // Mutate iterations based on next 8 bits
        int256 delta_iterations = int8(uint8((rand >> 48) % 256)) - 128;
        if (delta_iterations < 0) {
            if (frag.iterations > uint16(-delta_iterations)) {
                frag.iterations -= uint16(-delta_iterations);
            } else {
                frag.iterations = 1; // Minimum iterations
            }
        } else {
            frag.iterations += uint16(delta_iterations);
        }

        // Mutate color_offset based on next 32 bits
        uint32 delta_color_offset = uint32((rand >> 56) % (2**32));
        // Simple XOR or addition for color offset change
        frag.color_offset = frag.color_offset ^ delta_color_offset; // XOR changes bits randomly
    }

    /// @dev Internal helper to combine properties from two fragments.
    /// @param frag1 The first parent fragment.
    /// @param frag2 The second parent fragment.
    /// @param entropy Source of randomness for combination bias.
    /// @return Combined c_real, c_imaginary, scale, iterations, color_offset.
    function _combinePropertyLogic(Fragment storage frag1, Fragment storage frag2, bytes32 entropy)
        internal
        pure
        returns (int128 c_real, int128 c_imaginary, uint128 scale, uint16 iterations, uint32 color_offset)
    {
        uint256 rand = uint256(entropy);

        // Example Combination Logic: Weighted average influenced by entropy
        // Bias towards frag1 or frag2 based on entropy
        uint256 bias = rand % 100; // 0-99

        // c_real: Weighted average
        c_real = int128((int256(frag1.c_real) * (100 - bias) + int256(frag2.c_real) * bias) / 100);

        // c_imaginary: Weighted average
        c_imaginary = int128((int256(frag1.c_imaginary) * (100 - bias) + int256(frag2.c_imaginary) * bias) / 100);

        // scale: Weighted average
        scale = uint128((uint256(frag1.scale) * (100 - bias) + uint256(frag2.scale) * bias) / 100);

        // iterations: Weighted average (integer arithmetic)
        iterations = uint16((uint256(frag1.iterations) * (100 - bias) + uint256(frag2.iterations) * bias) / 100);

        // color_offset: Mix using bitwise operation or simple average
        color_offset = (frag1.color_offset & frag2.color_offset) | ((frag1.color_offset ^ frag2.color_offset) & uint32(rand)); // Example mix

        return (c_real, c_imaginary, scale, iterations, color_offset);
    }

    /// @dev Internal helper to adjust properties based on block data.
    /// @param frag The fragment struct to adjust (storage pointer).
    /// @param blockEntropy Source of entropy from block data.
    function _adjustPropertiesByCalibration(Fragment storage frag, bytes32 blockEntropy) internal view {
         uint256 rand = uint256(blockEntropy);

        // Use calibration parameters to influence magnitude of adjustment
        // Adjust c_real based on first 32 bits of rand and calibrationParams.cRealFactor
        int256 cRealAdj = int32(uint32(rand)) - int32(2**31); // Map to signed range
        frag.c_real += int128(cRealAdj * calibrationParams.cRealFactor / 100); // Apply factor

        // Adjust c_imaginary based on next 32 bits
        int256 cImaginaryAdj = int32(uint32(rand >> 32)) - int32(2**31);
        frag.c_imaginary += int128(cImaginaryAdj * calibrationParams.cImaginaryFactor / 100);

        // Adjust scale based on next 32 bits (treat as unsigned delta)
        uint256 scaleAdj = uint32(rand >> 64);
        if (scaleAdj % 2 == 0) {
            frag.scale += uint128(scaleAdj * calibrationParams.scaleFactor / 1000); // Increase
        } else {
             if (frag.scale > uint128(scaleAdj * calibrationParams.scaleFactor / 1000)) {
                 frag.scale -= uint128(scaleAdj * calibrationParams.scaleFactor / 1000); // Decrease
             } else {
                 frag.scale = SCALE_SCALE; // Minimum scale
             }
        }


        // Adjust iterations based on next 16 bits
        int256 iterationsAdj = int16(uint16(rand >> 96)) - int16(2**15);
         if (iterationsAdj < 0) {
             if (frag.iterations > uint16(-iterationsAdj * calibrationParams.iterationsFactor / 50)) {
                 frag.iterations -= uint16(-iterationsAdj * calibrationParams.iterationsFactor / 50);
             } else {
                 frag.iterations = 1; // Minimum iterations
             }
         } else {
             frag.iterations += uint16(iterationsAdj * calibrationParams.iterationsFactor / 50);
         }

        // color_offset: Simple shift based on block data
        frag.color_offset += uint32(block.timestamp % 1000);
    }

    // Helper to convert AttunementType enum to string (useful for off-chain display/metadata)
    function _attunementTypeToString(AttunementType _type) internal pure returns (string memory) {
        if (_type == AttunementType.None) return "None";
        if (_type == AttunementType.Ignis) return "Ignis";
        if (_type == AttunementType.Aqua) return "Aqua";
        if (_type == AttunementType.Terra) return "Terra";
        if (_type == AttunementType.Aether) return "Aether";
        if (_type == AttunementType.Chaos) return "Chaos";
        if (_type == AttunementType.Order) return "Order";
        return "Unknown";
    }

     // Helper to convert EvolutionState enum to string (useful for off-chain display/metadata)
    function _evolutionStateToString(EvolutionState _state) internal pure returns (string memory) {
        if (_state == EvolutionState.Seed) return "Seed";
        if (_state == EvolutionState.Bloom) return "Bloom";
        if (_state == EvolutionState.Nexus) return "Nexus";
        if (_state == EvolutionState.Transcendent) return "Transcendent";
        return "Unknown";
    }

    // The `_ownerOf` internal function is used by `onlyFragmentOwner` and `FragmentsMustBeOwned`.
    // `_exists` internal function is used by `onlyValidFragment`.
    // `_safeMint` and `_burn` are from ERC721.
    // Counters._tokenIdCounter and Counters._generationCounter handle unique IDs and generation counts.
    // ReentrancyGuard prevents reentrancy on payable/state-changing calls.
    // Ownable provides basic ownership control.
}
```