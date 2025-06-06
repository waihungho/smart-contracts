Okay, let's create a smart contract that embodies some interesting, advanced, and creative concepts, inspired by ideas like Quantum Mechanics and Dynamic NFTs, but without directly copying existing popular patterns.

This contract, tentatively named `QuantumEntangledNFTs`, will feature NFTs with "quantum states" that can be in "superposition" until observed, can become "entangled" with other NFTs, and have states that can "fluctuate" or "decay". It will also include a "fusion" mechanism.

Here's the outline and function summary, followed by the Solidity code.

---

**Outline and Function Summary:**

**Contract:** `QuantumEntangledNFTs`

This contract implements a non-fungible token (NFT) standard (ERC721) with added mechanics inspired by quantum physics analogies:
1.  **Quantum States:** Each NFT has internal state variables (`energyLevel`, `phase`, `lastStateChangeBlock`).
2.  **Superposition:** An NFT can be in a `superposed` state, meaning its `energyLevel` and `phase` are uncertain/undetermined until an "observation".
3.  **Observation:** A specific function call (`observeState`) collapses the superposition, fixing the `energyLevel` and `phase` based on pseudo-random factors derived from the transaction context.
4.  **Entanglement:** Two non-entangled NFTs can be "entangled", linking their fates. An action on one may affect the other.
5.  **Fluctuations & Decay:** Observed states (`energyLevel`, `phase`) can change slightly over time (`decay`) or through specific actions (`fluctuation`).
6.  **Fusion:** Two entangled and observed NFTs can be "fused" with a probability of success, potentially consuming them to create a new NFT with derived properties.

**Core State Variables:**
*   `_tokenStates`: Mapping from token ID to a `QuantumState` struct.
*   `_entangledPairs`: Mapping to track entangled partners.
*   `_entanglementFee`: Cost to entangle tokens.
*   `_fusionFee`: Cost to attempt fusion.
*   `_decayRate`: Rate at which energy decays per block.
*   `_fusionSuccessProbability`: Chance of fusion succeeding (scaled).
*   `_fluctuationsEnabled`: Admin toggle for state fluctuations.
*   `_tokenCounter`: Tracks the total number of tokens minted.
*   `_feePool`: Contract balance from fees.

**Structs:**
*   `QuantumState`: Stores `energyLevel`, `phase`, `isSuperposed`, `entangledPairId`, `lastStateChangeBlock`.

**Events:**
*   `StateObserved`: Emitted when a token's superposition collapses.
*   `Entangled`: Emitted when two tokens become entangled.
*   `Disentangled`: Emitted when entanglement is broken.
*   `FluctuationInduced`: Emitted when a state fluctuation occurs.
*   `DecayApplied`: Emitted when energy decay is applied.
*   `FusionAttempted`: Emitted when fusion is tried.
*   `FusionSuccessful`: Emitted when fusion succeeds, includes new token ID.
*   `FusionFailed`: Emitted when fusion fails.

**Function Summary (20+ functions):**

1.  `constructor(string memory name, string memory symbol)`: Initializes the contract, ERC721 name/symbol, and default settings.
2.  `supportsInterface(bytes4 interfaceId) public view override returns (bool)`: ERC165 standard.
3.  `balanceOf(address owner) public view override returns (uint256)`: ERC721 standard.
4.  `ownerOf(uint256 tokenId) public view override returns (address)`: ERC721 standard.
5.  `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC721 standard, includes internal hooks.
6.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: ERC721 standard, includes internal hooks.
7.  `transferFrom(address from, address to, uint256 tokenId)`: ERC721 standard, includes internal hooks.
8.  `approve(address to, uint256 tokenId) public override`: ERC721 standard.
9.  `setApprovalForAll(address operator, bool approved) public override`: ERC721 standard.
10. `getApproved(uint256 tokenId) public view override returns (address)`: ERC721 standard.
11. `isApprovedForAll(address owner, address operator) public view override returns (bool)`: ERC721 standard.
12. `tokenURI(uint256 tokenId) public view override returns (string memory)`: ERC721 standard. Returns a URI reflecting the token's current state (superposed/observed).
13. `mint(address recipient)`: Mints a new token, initializing its quantum state in superposition.
14. `observeState(uint256 tokenId)`: Public function to collapse the superposition of a token, fixing its state.
15. `getQuantumState(uint256 tokenId) public view returns (uint256 energy, uint256 phase, bool isSuperposed, uint256 entangledPairId, uint48 lastStateChangeBlock)`: Public view to retrieve a token's raw quantum state variables.
16. `isSuperposed(uint256 tokenId) public view returns (bool)`: Public view to check if a token is superposed.
17. `entangle(uint256 tokenId1, uint256 tokenId2) payable`: Public function to entangle two tokens, requiring ownership/approval and payment of the entanglement fee.
18. `disentangle(uint256 tokenId)`: Public function to break the entanglement of a token.
19. `getEntangledPair(uint256 tokenId) public view returns (uint256)`: Public view to find the entangled partner of a token.
20. `induceQuantumFluctuation(uint256 tokenId)`: Public function to introduce a random fluctuation in the state of an *observed* token (if enabled).
21. `checkAndApplyDecay(uint256 tokenId)`: Public function to calculate and apply energy decay to an *observed* token based on elapsed blocks.
22. `attemptQuantumFusion(uint256 tokenId1, uint256 tokenId2) payable`: Public function to attempt fusion of two *entangled* and *observed* tokens, requiring ownership/approval and payment of the fusion fee.
23. `canFuse(uint256 tokenId1, uint256 tokenId2) public view returns (bool)`: Public view to check if two tokens meet the conditions for fusion.
24. `setBaseURI(string memory baseURI) external onlyOwner`: Admin function to set the base URI for metadata.
25. `setMaxSupply(uint256 maxSupply) external onlyOwner`: Admin function to set the maximum number of tokens that can be minted.
26. `setEntanglementFee(uint256 fee) external onlyOwner`: Admin function to set the fee for entanglement.
27. `setFusionFee(uint256 fee) external onlyOwner`: Admin function to set the fee for fusion.
28. `setDecayRate(uint256 rate) external onlyOwner`: Admin function to set the energy decay rate per block.
29. `setFusionSuccessProbability(uint256 prob) external onlyOwner`: Admin function to set the probability of successful fusion (0-10000 for 0-100%).
30. `toggleFluctuationsEnabled(bool enabled) external onlyOwner`: Admin function to enable/disable state fluctuations.
31. `withdrawFees() external onlyOwner`: Admin function to withdraw collected fees.
32. `getTotalMinted() public view returns (uint256)`: Public view of total minted tokens.
33. `getDecayRate() public view returns (uint256)`: Public view of current decay rate.
34. `getEntanglementFee() public view returns (uint256)`: Public view of current entanglement fee.
35. `getFusionFee() public view returns (uint256)`: Public view of current fusion fee.
36. `getFusionSuccessProbability() public view returns (uint256)`: Public view of current fusion success probability.
37. `areFluctuationsEnabled() public view returns (bool)`: Public view of fluctuation status.
38. `getTokenLastStateChangeBlock(uint256 tokenId) public view returns (uint48)`: Public view of when a token's state last changed.
39. `getObservedState(uint256 tokenId) public view returns (uint256 energy, uint256 phase)`: Public view to get observed state, reverts if superposed.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/// @title QuantumEntangledNFTs
/// @dev An advanced ERC721 contract with quantum mechanics-inspired features: superposition,
/// entanglement, observation, fluctuation, decay, and fusion. NFTs possess quantum states
/// that behave dynamically based on these concepts.
///
/// **Outline:**
/// 1. Standard ERC721 Implementation (based on OpenZeppelin).
/// 2. Custom Data Structure for Quantum State (`QuantumState`).
/// 3. Mappings to store Token States and Entangled Pairs.
/// 4. State Variables for Fees, Rates, Supply, and Admin Settings.
/// 5. Error and Event Definitions.
/// 6. Core Quantum Mechanics Functions:
///    - Minting into Superposition
///    - Observing State (Collapsing Superposition)
///    - Entangling and Disentangling Tokens
///    - Inducing Fluctuations (on Observed States)
///    - Applying Decay (on Observed States)
///    - Attempting Fusion (of Entangled & Observed Tokens)
/// 7. Internal Helper Functions for State Management and Pseudo-Randomness.
/// 8. ERC721 Hooks (`_beforeTokenTransfer`, `_afterTokenTransfer`) for State Consistency.
/// 9. Admin Functions for managing parameters.
/// 10. View Functions for querying states and settings.
///
/// **Function Summary (>= 20 Functions):**
/// - `constructor`: Initializes contract with ERC721 details.
/// - `supportsInterface`: ERC165 standard check.
/// - `balanceOf`: ERC721 standard.
/// - `ownerOf`: ERC721 standard.
/// - `safeTransferFrom` (2 overloads): ERC721 standard with hooks.
/// - `transferFrom`: ERC721 standard with hooks.
/// - `approve`: ERC721 standard.
/// - `setApprovalForAll`: ERC721 standard.
/// - `getApproved`: ERC721 standard.
/// - `isApprovedForAll`: ERC721 standard.
/// - `tokenURI`: ERC721 standard, generates dynamic URI based on state.
/// - `mint`: Creates a new NFT in superposition.
/// - `observeState`: Forces a superposed token into a definite state.
/// - `getQuantumState`: Retrieves raw quantum state data.
/// - `isSuperposed`: Checks if a token is in superposition.
/// - `entangle`: Links two tokens quantum-mechanically.
/// - `disentangle`: Breaks the quantum link.
/// - `getEntangledPair`: Finds the entangled partner.
/// - `induceQuantumFluctuation`: Randomly alters an observed state.
/// - `checkAndApplyDecay`: Reduces energy based on time elapsed since last change.
/// - `attemptQuantumFusion`: Tries to merge two tokens into a new one.
/// - `canFuse`: Checks prerequisites for fusion.
/// - `setBaseURI`: Admin: sets metadata base path.
/// - `setMaxSupply`: Admin: sets token minting limit.
/// - `setEntanglementFee`: Admin: sets fee for entanglement.
/// - `setFusionFee`: Admin: sets fee for fusion attempts.
/// - `setDecayRate`: Admin: sets energy decay speed.
/// - `setFusionSuccessProbability`: Admin: sets fusion success rate.
/// - `toggleFluctuationsEnabled`: Admin: enables/disables state fluctuations.
/// - `withdrawFees`: Admin: collects contract balance.
/// - `getTotalMinted`: View: total tokens created.
/// - `getDecayRate`: View: current decay rate.
/// - `getEntanglementFee`: View: current entanglement fee.
/// - `getFusionFee`: View: current fusion fee.
/// - `getFusionSuccessProbability`: View: current fusion probability.
/// - `areFluctuationsEnabled`: View: fluctuation status.
/// - `getTokenLastStateChangeBlock`: View: last state change block.
/// - `getObservedState`: View: gets observed state, reverts if superposed.

contract QuantumEntangledNFTs is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenCounter;
    uint256 private _maxSupply = 1000; // Default max supply

    // --- Quantum State Structure ---
    struct QuantumState {
        uint256 energyLevel; // Represents some quantitative property
        uint256 phase;       // Represents some qualitative property (e.g., 0-3 for quadrants)
        bool isSuperposed;   // True if state is not yet observed/collapsed
        uint256 entangledPairId; // 0 if not entangled, otherwise ID of partner
        uint48 lastStateChangeBlock; // Block number when state was last fixed or changed
    }

    // --- State Variables ---
    mapping(uint256 => QuantumState) private _tokenStates;
    uint256 private _entanglementFee = 0.01 ether; // Default fee
    uint256 private _fusionFee = 0.05 ether;       // Default fee
    uint256 private _decayRate = 1; // Energy units decayed per block for observed tokens
    uint256 private _fusionSuccessProbability = 5000; // Probability scale: 0-10000 (50% default)
    bool private _fluctuationsEnabled = true; // Whether random fluctuations can occur
    uint256 private _feePool; // Collects fees

    // --- Constants ---
    uint256 internal constant ENTANGLED_PAIR_NONE = 0;
    uint256 internal constant FUSION_PROB_DENOMINATOR = 10000; // Scale for probability (0-10000 maps to 0-100%)
    uint256 internal constant MAX_ENERGY_LEVEL = 1000; // Example max energy level
    uint256 internal constant MAX_PHASE = 3; // Example max phase (0, 1, 2, 3)

    // --- Errors ---
    error MaxSupplyReached();
    error TokenDoesNotExist();
    error NotSuperposed(uint256 tokenId);
    error AlreadySuperposed(uint256 tokenId);
    error NotEntangled(uint256 tokenId);
    error AlreadyEntangled(uint256 tokenId);
    error CannotEntangleSelf();
    error NotOwnerOrApproved(uint256 tokenId);
    error NotOwnerOrApprovedBoth(uint256 tokenId1, uint256 tokenId2);
    error FusionConditionNotMet(string reason);
    error InsufficientFunds(uint256 required, uint256 provided);
    error FluctuationsDisabled();
    error TransferOfSuperposedForbidden(uint256 tokenId);
    error TransferBreaksEntanglement(uint256 tokenId); // This error is not used directly, but the logic prevents it

    // --- Events ---
    event StateObserved(uint256 indexed tokenId, uint256 energyLevel, uint256 phase, uint48 observationBlock);
    event Entangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event Disentangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event FluctuationInduced(uint256 indexed tokenId, uint256 newEnergyLevel, uint256 newPhase);
    event DecayApplied(uint256 indexed tokenId, uint256 energyDecayed, uint256 newEnergyLevel);
    event FusionAttempted(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event FusionSuccessful(uint256 indexed consumedToken1, uint256 indexed consumedToken2, uint256 indexed newTokenId);
    event FusionFailed(uint256 indexed tokenId1, uint256 indexed tokenId2);

    // --- Constructor ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    // --- Internal ERC721 Hooks ---

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent transfer of superposed tokens - must observe first
        if (_tokenStates[tokenId].isSuperposed) {
             revert TransferOfSuperposedForbidden(tokenId);
        }

        // Break entanglement on transfer
        if (_tokenStates[tokenId].entangledPairId != ENTANGLED_PAIR_NONE) {
            _disentangleTokens(tokenId, _tokenStates[tokenId].entangledPairId);
        }

        // Apply decay before transfer if state has changed
        if (!_tokenStates[tokenId].isSuperposed) {
             _applyDecay(tokenId);
        }
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
         super._afterTokenTransfer(from, to, tokenId, batchSize);
         // No specific state updates needed after transfer for this contract logic
         // Decay is handled before transfer, entanglement broken before transfer.
    }


    // --- ERC721 Standard Overrides ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist();
        }

        string memory baseURI = _baseURI();
        string memory stateParam;

        if (_tokenStates[tokenId].isSuperposed) {
            stateParam = "state=superposed";
        } else {
            // Encode observed state into URI parameters or path
            QuantumState storage state = _tokenStates[tokenId];
            // Example: ?state=observed&energy=123&phase=1
            stateParam = string.concat(
                 "state=observed",
                 "&energy=", state.energyLevel.toString(),
                 "&phase=", state.phase.toString(),
                 "&entangled=", state.entangledPairId == ENTANGLED_PAIR_NONE ? "none" : state.entangledPairId.toString()
            );
        }

        // Basic example combining base URI with state info
        // A real implementation would likely point to a metadata service
        // returning JSON based on these parameters.
        return string.concat(baseURI, tokenId.toString(), "?", stateParam);
    }

    // --- Minting ---

    /// @dev Mints a new token and initializes its state as superposed.
    /// @param recipient The address to mint the token to.
    function mint(address recipient) external onlyOwner {
        uint256 newTokenId = _tokenCounter.current();
        if (newTokenId >= _maxSupply) {
            revert MaxSupplyReached();
        }
        _tokenCounter.increment();

        _safeMint(recipient, newTokenId);

        // Initialize quantum state in superposition
        _tokenStates[newTokenId] = QuantumState({
            energyLevel: 0, // Undetermined in superposition
            phase: 0,       // Undetermined
            isSuperposed: true,
            entangledPairId: ENTANGLED_PAIR_NONE,
            lastStateChangeBlock: uint48(block.number) // Record block of creation
        });

        emit Minted(newTokenId, recipient); // Assuming ERC721 standard Mint event
        // Note: OpenZeppelin ERC721 emits Transfer event on mint, no need for custom Minted event unless desired.
        // Keeping the event definition for clarity, but using OZ Transfer implicitly.
    }

    // --- Quantum State Management ---

    /// @dev Forces a superposed token's state to collapse into definite energy and phase.
    /// State determination is pseudo-random based on block/transaction data.
    /// @param tokenId The ID of the token to observe.
    function observeState(uint256 tokenId) public {
        address tokenOwner = ownerOf(tokenId);
        if (msg.sender != tokenOwner && !isApprovedForAll(tokenOwner, msg.sender) && getApproved(tokenId) != msg.sender) {
             revert NotOwnerOrApproved(tokenId);
        }

        QuantumState storage state = _tokenStates[tokenId];
        if (!state.isSuperposed) {
            revert NotSuperposed(tokenId);
        }

        // Apply decay *before* observing if state wasn't superposed previously
        // This is redundant because `isSuperposed` implies lastStateChangeBlock was from creation,
        // and decay only applies to *observed* states. But including here for robustness
        // against potential future state transitions.
        // if (!state.isSuperposed) { _applyDecay(tokenId); } // This won't happen if !state.isSuperposed is true

        // Collapse superposition: Determine state based on pseudo-randomness
        uint256 randomValue = _generatePseudoRandomUint(tokenId);

        state.energyLevel = (randomValue % (MAX_ENERGY_LEVEL + 1));
        state.phase = (randomValue / (MAX_ENERGY_LEVEL + 1)) % (MAX_PHASE + 1);
        state.isSuperposed = false;
        state.lastStateChangeBlock = uint48(block.number);

        emit StateObserved(tokenId, state.energyLevel, state.phase, uint48(block.number));
    }

    /// @dev Gets the current raw quantum state variables for a token.
    /// @param tokenId The ID of the token.
    /// @return energyLevel, phase, isSuperposed, entangledPairId, lastStateChangeBlock
    function getQuantumState(uint256 tokenId) public view returns (uint256 energy, uint256 phase, bool superposed, uint256 pairId, uint48 lastBlock) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist();
        }
        QuantumState storage state = _tokenStates[tokenId];
        return (state.energyLevel, state.phase, state.isSuperposed, state.entangledPairId, state.lastStateChangeBlock);
    }

    /// @dev Checks if a token is currently in superposition.
    /// @param tokenId The ID of the token.
    /// @return True if the token is superposed, false otherwise.
    function isSuperposed(uint256 tokenId) public view returns (bool) {
         if (!_exists(tokenId)) {
            revert TokenDoesNotExist();
        }
        return _tokenStates[tokenId].isSuperposed;
    }

    /// @dev Gets the observed energy and phase of a token. Reverts if the token is superposed.
    /// @param tokenId The ID of the token.
    /// @return energy, phase
    function getObservedState(uint256 tokenId) public view returns (uint256 energy, uint256 phase) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist();
        }
        QuantumState storage state = _tokenStates[tokenId];
        if (state.isSuperposed) {
            revert NotSuperposed(tokenId);
        }
        return (state.energyLevel, state.phase);
    }


    // --- Entanglement ---

    /// @dev Entangles two tokens. Requires caller to own or be approved for both, and pay a fee.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function entangle(uint256 tokenId1, uint256 tokenId2) public payable {
        if (!_exists(tokenId1)) revert TokenDoesNotExist();
        if (!_exists(tokenId2)) revert TokenDoesNotExist();
        if (tokenId1 == tokenId2) revert CannotEntangleSelf();

        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);

        // Require caller to be authorized for both tokens
        bool callerIsOwner1 = msg.sender == owner1;
        bool callerIsOwner2 = msg.sender == owner2;
        bool callerIsApprovedAll1 = isApprovedForAll(owner1, msg.sender);
        bool callerIsApprovedAll2 = isApprovedForAll(owner2, msg.sender);
        bool callerIsApprovedToken1 = getApproved(tokenId1) == msg.sender;
        bool callerIsApprovedToken2 = getApproved(tokenId2) == msg.sender;

        bool authorized1 = callerIsOwner1 || callerIsApprovedAll1 || callerIsApprovedToken1;
        bool authorized2 = callerIsOwner2 || callerIsApprovedAll2 || callerIsApprovedToken2;

        if (!(authorized1 && authorized2)) {
            revert NotOwnerOrApprovedBoth(tokenId1, tokenId2);
        }

        QuantumState storage state1 = _tokenStates[tokenId1];
        QuantumState storage state2 = _tokenStates[tokenId2];

        if (state1.entangledPairId != ENTANGLED_PAIR_NONE || state2.entangledPairId != ENTANGLED_PAIR_NONE) {
            revert AlreadyEntangled(state1.entangledPairId != ENTANGLED_PAIR_NONE ? tokenId1 : tokenId2);
        }

        if (msg.value < _entanglementFee) {
            revert InsufficientFunds(_entanglementFee, msg.value);
        }

        _feePool += msg.value; // Collect fee

        state1.entangledPairId = tokenId2;
        state2.entangledPairId = tokenId1;

        emit Entangled(tokenId1, tokenId2);
    }

    /// @dev Breaks the entanglement of a token. Automatically breaks the partner's link.
    /// Requires caller to own or be approved for the token.
    /// @param tokenId The ID of the token.
    function disentangle(uint256 tokenId) public {
        address tokenOwner = ownerOf(tokenId);
         if (msg.sender != tokenOwner && !isApprovedForAll(tokenOwner, msg.sender) && getApproved(tokenId) != msg.sender) {
             revert NotOwnerOrApproved(tokenId);
        }

        QuantumState storage state = _tokenStates[tokenId];
        if (state.entangledPairId == ENTANGLED_PAIR_NONE) {
            revert NotEntangled(tokenId);
        }

        _disentangleTokens(tokenId, state.entangledPairId);
    }

    /// @dev Internal function to break entanglement between two specific tokens.
    /// Assumes existence and entanglement are checked by caller.
    function _disentangleTokens(uint256 tokenId1, uint256 tokenId2) internal {
        _tokenStates[tokenId1].entangledPairId = ENTANGLED_PAIR_NONE;
        _tokenStates[tokenId2].entangledPairId = ENTANGLED_PAIR_NONE;
        emit Disentangled(tokenId1, tokenId2);
    }

    /// @dev Gets the entangled partner's ID for a token. Returns 0 if not entangled.
    /// @param tokenId The ID of the token.
    /// @return The ID of the entangled partner, or 0.
    function getEntangledPair(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) {
            revert TokenDoesNotExist();
        }
        return _tokenStates[tokenId].entangledPairId;
    }


    // --- State Fluctuations and Decay ---

    /// @dev Induces a small, pseudo-random fluctuation in the state variables of an *observed* token.
    /// Can only occur if fluctuations are enabled by the owner.
    /// @param tokenId The ID of the token to fluctuate.
    function induceQuantumFluctuation(uint256 tokenId) public {
        address tokenOwner = ownerOf(tokenId);
         if (msg.sender != tokenOwner && !isApprovedForAll(tokenOwner, msg.sender) && getApproved(tokenId) != msg.sender) {
             revert NotOwnerOrApproved(tokenId);
        }

        QuantumState storage state = _tokenStates[tokenId];
        if (state.isSuperposed) {
            revert AlreadySuperposed(tokenId); // Can only fluctuate observed states
        }
        if (!_fluctuationsEnabled) {
            revert FluctuationsDisabled();
        }

        // Apply decay before potential fluctuation
        _applyDecay(tokenId);

        // Induce fluctuation based on pseudo-randomness
        uint256 randomValue = _generatePseudoRandomUint(tokenId);

        uint256 oldEnergy = state.energyLevel;
        uint256 oldPhase = state.phase;

        // Small random change - example logic
        if (randomValue % 2 == 0) {
            // Change energy slightly
            int256 energyChange = int256((randomValue / 2) % 11) - 5; // Change between -5 and +5
            state.energyLevel = uint256(int256(state.energyLevel) + energyChange);
             // Ensure energy stays within bounds
            if (state.energyLevel > MAX_ENERGY_LEVEL) state.energyLevel = MAX_ENERGY_LEVEL;
            if (state.energyLevel == 0 && energyChange < 0) state.energyLevel = 0; // Prevent underflow
        } else {
             // Change phase randomly to an adjacent phase (wrapping around)
            int256 phaseChange = (randomValue / 2) % 2 == 0 ? 1 : -1; // Change by +1 or -1
            state.phase = uint256(int256(state.phase) + phaseChange);
            state.phase = state.phase % (MAX_PHASE + 1); // Wrap phase around
        }

        state.lastStateChangeBlock = uint48(block.number);

        emit FluctuationInduced(tokenId, state.energyLevel, state.phase);

        // Potential Entanglement Effect:
        // If entangled, induce fluctuation on partner? Or a different effect?
        // Let's keep it simple for now and just emit event, advanced effects can be added.
        // For example, could call checkAndApplyDecay on partner, or induce a *smaller* fluctuation.
        // uint256 pairId = state.entangledPairId;
        // if (pairId != ENTANGLED_PAIR_NONE && !(_tokenStates[pairId].isSuperposed)) {
        //     // Example: Apply decay to partner
        //     _applyDecay(pairId);
        // }
    }

    /// @dev Checks for and applies energy decay to an *observed* token based on the number of blocks
    /// since its last state change.
    /// @param tokenId The ID of the token to check/decay.
    function checkAndApplyDecay(uint256 tokenId) public {
         address tokenOwner = ownerOf(tokenId);
         if (msg.sender != tokenOwner && !isApprovedForAll(tokenOwner, msg.sender) && getApproved(tokenId) != msg.sender) {
             revert NotOwnerOrApproved(tokenId);
        }

        QuantumState storage state = _tokenStates[tokenId];
        if (state.isSuperposed) {
            revert AlreadySuperposed(tokenId); // Decay only applies to observed states
        }

        _applyDecay(tokenId);
    }

    /// @dev Internal helper to calculate and apply decay.
    /// @param tokenId The ID of the token.
    function _applyDecay(uint256 tokenId) internal {
        QuantumState storage state = _tokenStates[tokenId];
        if (state.isSuperposed) return; // Only apply decay to observed states

        uint256 blocksSinceLastChange = block.number - state.lastStateChangeBlock;
        if (blocksSinceLastChange == 0) return; // No time elapsed

        uint256 decayAmount = blocksSinceLastChange * _decayRate;
        uint256 oldEnergy = state.energyLevel;

        if (state.energyLevel <= decayAmount) {
            state.energyLevel = 0;
            decayAmount = oldEnergy; // Decay amount is capped by current energy
        } else {
            state.energyLevel -= decayAmount;
        }

        state.lastStateChangeBlock = uint48(block.number);
        emit DecayApplied(tokenId, decayAmount, state.energyLevel);

        // Potential Entanglement Effect:
        // If entangled, apply decay to partner? Or a different effect?
        // uint256 pairId = state.entangledPairId;
        // if (pairId != ENTANGLED_PAIR_NONE && !(_tokenStates[pairId].isSuperposed)) {
        //     // Example: Apply decay to partner
        //     _applyDecay(pairId); // Recursive call - be cautious with complexity/gas
        // }
    }


    // --- Quantum Fusion ---

    /// @dev Attempts to fuse two entangled and observed tokens.
    /// Success probability is governed by the contract setting.
    /// On success, consumes the two input tokens and mints a new one with combined properties.
    /// On failure, may apply a penalty or break entanglement.
    /// Requires caller to own or be approved for both, and pay a fee.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function attemptQuantumFusion(uint256 tokenId1, uint256 tokenId2) public payable {
        if (!_exists(tokenId1)) revert TokenDoesNotExist();
        if (!_exists(tokenId2)) revert TokenDoesNotExist();
        if (tokenId1 == tokenId2) revert CannotEntangleSelf(); // Cannot fuse with self

        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);

        // Require caller to be authorized for both tokens
        bool callerIsOwner1 = msg.sender == owner1;
        bool callerIsOwner2 = msg.sender == owner2;
        bool callerIsApprovedAll1 = isApprovedForAll(owner1, msg.sender);
        bool callerIsApprovedAll2 = isApprovedForAll(owner2, msg.sender);
        bool callerIsApprovedToken1 = getApproved(tokenId1) == msg.sender;
        bool callerIsApprovedToken2 = getApproved(tokenId2) == msg.sender;

        bool authorized1 = callerIsOwner1 || callerIsApprovedAll1 || callerIsApprovedToken1;
        bool authorized2 = callerIsOwner2 || callerIsApprovedAll2 || callerIsApprovedToken2;

        if (!(authorized1 && authorized2)) {
            revert NotOwnerOrApprovedBoth(tokenId1, tokenId2);
        }

        QuantumState storage state1 = _tokenStates[tokenId1];
        QuantumState storage state2 = _tokenStates[tokenId2];

        if (state1.entangledPairId != tokenId2 || state2.entangledPairId != tokenId1) {
            revert FusionConditionNotMet("Tokens are not entangled.");
        }

        if (state1.isSuperposed || state2.isSuperposed) {
             revert FusionConditionNotMet("Both tokens must be observed.");
        }

        if (msg.value < _fusionFee) {
            revert InsufficientFunds(_fusionFee, msg.value);
        }

        _feePool += msg.value; // Collect fee

        // Apply decay to both tokens before fusion attempt
        _applyDecay(tokenId1);
        _applyDecay(tokenId2);

        emit FusionAttempted(tokenId1, tokenId2);

        // Determine fusion outcome pseudo-randomly
        uint256 randomValue = _generatePseudoRandomUint(tokenId1 + tokenId2); // Seed with both IDs
        bool success = (randomValue % FUSION_PROB_DENOMINATOR) < _fusionSuccessProbability;

        if (success) {
            // Perform fusion: Burn inputs, mint new token
            _disentangleTokens(tokenId1, tokenId2); // Break entanglement before burning

            _burn(tokenId1);
            _burn(tokenId2);

            uint256 newTokenId = _tokenCounter.current();
             if (newTokenId >= _maxSupply) {
                // Refund fee? Or keep as penalty? Let's keep as penalty if max supply reached during fusion
                revert MaxSupplyReached();
            }
            _tokenCounter.increment();

            _safeMint(msg.sender, newTokenId); // Mint new token to the caller

            // Initialize new token state based on inputs (example logic)
            _tokenStates[newTokenId] = QuantumState({
                energyLevel: (state1.energyLevel + state2.energyLevel) / 2, // Average energy
                phase: (state1.phase + state2.phase) % (MAX_PHASE + 1),     // Sum phases, wrap around
                isSuperposed: false, // Newly fused token is observed immediately
                entangledPairId: ENTANGLED_PAIR_NONE,
                lastStateChangeBlock: uint48(block.number)
            });

            emit FusionSuccessful(tokenId1, tokenId2, newTokenId);

        } else {
            // Fusion failed: Apply penalties or effects (example: break entanglement, reduce energy)
            _disentangleTokens(tokenId1, tokenId2); // Always break entanglement on failed fusion

            // Optional penalty: reduce energy significantly
            state1.energyLevel = state1.energyLevel / 2;
            state2.energyLevel = state2.energyLevel / 2;
            state1.lastStateChangeBlock = uint48(block.number);
            state2.lastStateChangeBlock = uint48(block.number);


            emit FusionFailed(tokenId1, tokenId2);
        }
    }

    /// @dev Checks if two tokens meet the basic conditions for a fusion attempt.
    /// Does not check ownership/approval or fee payment.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    /// @return True if fusion conditions are met, false otherwise.
    function canFuse(uint256 tokenId1, uint256 tokenId2) public view returns (bool) {
        if (!_exists(tokenId1) || !_exists(tokenId2) || tokenId1 == tokenId2) {
            return false;
        }

        QuantumState storage state1 = _tokenStates[tokenId1];
        QuantumState storage state2 = _tokenStates[tokenId2];

        // Check if entangled and both observed
        return (state1.entangledPairId == tokenId2 && state2.entangledPairId == tokenId1 && !state1.isSuperposed && !state2.isSuperposed);
    }


    // --- Internal Helper Functions ---

    /// @dev Generates a pseudo-random uint256.
    /// NOTE: This is NOT cryptographically secure and is susceptible to front-running.
    /// Suitable for game mechanics where strong randomness isn't critical.
    /// @param seed An additional seed for uniqueness.
    /// @return A pseudo-random uint256.
    function _generatePseudoRandomUint(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao, // Use block.prevrandao instead of block.difficulty in newer Solidity
            block.number,
            msg.sender,
            seed
        )));
    }

     /// @dev Internal helper to get the base URI.
     /// @return The base URI string.
    function _baseURI() internal view override returns (string memory) {
        // Implement your base URI logic here. Could be a state variable.
        // For this example, returning a placeholder.
        return "ipfs://your_metadata_base_uri/";
    }


    // --- Admin Functions (Ownable) ---

    /// @dev Sets the base URI for token metadata.
    /// @param baseURI The new base URI string.
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI); // ERC721 internal function
    }

    /// @dev Sets the maximum number of tokens that can be minted.
    /// @param maxSupply The new maximum supply.
    function setMaxSupply(uint256 maxSupply) external onlyOwner {
        _maxSupply = maxSupply;
    }

    /// @dev Sets the fee required to entangle two tokens.
    /// @param fee The new entanglement fee in wei.
    function setEntanglementFee(uint256 fee) external onlyOwner {
        _entanglementFee = fee;
    }

    /// @dev Sets the fee required to attempt fusing two tokens.
    /// @param fee The new fusion fee in wei.
    function setFusionFee(uint256 fee) external onlyOwner {
        _fusionFee = fee;
    }

    /// @dev Sets the energy decay rate per block for observed tokens.
    /// @param rate The new decay rate (energy units per block).
    function setDecayRate(uint256 rate) external onlyOwner {
        _decayRate = rate;
    }

    /// @dev Sets the probability of quantum fusion succeeding.
    /// @param prob The probability scaled by FUSION_PROB_DENOMINATOR (e.g., 5000 for 50%). Max 10000.
    function setFusionSuccessProbability(uint256 prob) external onlyOwner {
        require(prob <= FUSION_PROB_DENOMINATOR, "Prob must be <= 10000");
        _fusionSuccessProbability = prob;
    }

     /// @dev Toggles whether state fluctuations can be induced on observed tokens.
    /// @param enabled True to enable, false to disable.
    function toggleFluctuationsEnabled(bool enabled) external onlyOwner {
        _fluctuationsEnabled = enabled;
    }

    /// @dev Allows the owner to withdraw collected fees.
    function withdrawFees() external onlyOwner {
        uint256 balance = _feePool;
        _feePool = 0;
        payable(owner()).transfer(balance);
    }

    // --- View Functions ---

    /// @dev Returns the total number of tokens that have been minted.
    function getTotalMinted() public view returns (uint256) {
        return _tokenCounter.current();
    }

    /// @dev Returns the current energy decay rate per block.
    function getDecayRate() public view returns (uint256) {
        return _decayRate;
    }

    /// @dev Returns the current fee for entanglement.
    function getEntanglementFee() public view returns (uint256) {
        return _entanglementFee;
    }

    /// @dev Returns the current fee for fusion attempts.
    function getFusionFee() public view returns (uint256) {
        return _fusionFee;
    }

    /// @dev Returns the current fusion success probability (scaled by 10000).
    function getFusionSuccessProbability() public view returns (uint256) {
        return _fusionSuccessProbability;
    }

    /// @dev Returns whether state fluctuations are currently enabled.
    function areFluctuationsEnabled() public view returns (bool) {
        return _fluctuationsEnabled;
    }

    /// @dev Returns the block number when a token's state was last fixed or changed.
    /// @param tokenId The ID of the token.
    function getTokenLastStateChangeBlock(uint256 tokenId) public view returns (uint48) {
         if (!_exists(tokenId)) {
            revert TokenDoesNotExist();
        }
        return _tokenStates[tokenId].lastStateChangeBlock;
    }

    // Need 20+ functions. Let's count:
    // 1 constructor (not callable externally, but initialization)
    // 1 supportsInterface
    // 9 ERC721 standard overrides (balanceOf, ownerOf, 2x safeTransferFrom, transferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll, tokenURI)
    // 1 mint
    // 1 observeState
    // 1 getQuantumState
    // 1 isSuperposed
    // 1 entangle
    // 1 disentangle
    // 1 getEntangledPair
    // 1 induceQuantumFluctuation
    // 1 checkAndApplyDecay
    // 1 attemptQuantumFusion
    // 1 canFuse
    // --- Subtotal: 24 ---
    // 1 setBaseURI
    // 1 setMaxSupply
    // 1 setEntanglementFee
    // 1 setFusionFee
    // 1 setDecayRate
    // 1 setFusionSuccessProbability
    // 1 toggleFluctuationsEnabled
    // 1 withdrawFees
    // --- Subtotal: 8 Admin ---
    // 1 getTotalMinted
    // 1 getDecayRate (duplicate, but added explicitly for view)
    // 1 getEntanglementFee (duplicate)
    // 1 getFusionFee (duplicate)
    // 1 getFusionSuccessProbability (duplicate)
    // 1 areFluctuationsEnabled (duplicate)
    // 1 getTokenLastStateChangeBlock
    // 1 getObservedState
    // --- Subtotal: 8 View ---

    // Total external/public functions: 9 (ERC721) + 13 (Quantum actions + canFuse) + 8 (Admin) + 8 (View) = 38.
    // Plus constructor and internal helpers. Well over 20 public/external functions.
    // Let's make sure the view functions don't just repeat the admin setters.
    // getDecayRate, getEntanglementFee, getFusionFee, getFusionSuccessProbability, areFluctuationsEnabled are duplicates as views,
    // but explicitly listing them as `public view` adds them to the ABI as getter functions, which is standard practice.
    // So the count is correct based on unique entry points defined with `public` or `external`.

    // Add Minted event definition explicitly if using it (OpenZeppelin uses Transfer for minting)
    // event Minted(uint256 indexed tokenId, address indexed owner);

}
```