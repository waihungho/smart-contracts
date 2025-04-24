Okay, let's create a smart contract concept called "QuantumEntangledNFTs". This contract will issue NFTs that possess dynamic properties inspired by quantum mechanics:

1.  **Superposition:** NFTs start in a "Superposition" state, having multiple potential outcomes for their final form.
2.  **Observation:** A specific action ("Observation Event") collapses the superposition, fixing the NFT into one of several "Collapsed" phases based on on-chain randomness.
3.  **Entanglement:** Two NFTs can be "entangled," meaning actions on one can conditionally affect the state of the other.
4.  **Fluctuation:** While in superposition, NFTs can undergo "Fluctuation," a process that modifies factors used in predicting the outcome of observation (though the final outcome is still random upon observation).

This contract will be an ERC721 standard implementation with custom extensions for these unique mechanics.

---

**Contract: QuantumEntangledNFTs**

**Outline:**

1.  **Contract Overview:**
    *   ERC721 standard compliance.
    *   Pausable and Ownable features for administrative control.
    *   Core Concepts: Superposition (Phase 0), Observation (collapsing to Phase 1+), Entanglement (linking token states), Fluctuation (modifying prediction factors).
    *   Dynamic `tokenURI` based on the token's current phase.
    *   Minting, transfer, burning with entanglement effects.
    *   Fees for specific actions (Observation, Fluctuation, Entanglement Effect).

2.  **State Variables:**
    *   NFT state mappings (`_phases`, `_entangledWith`).
    *   Metadata storage for phases (`_phaseAttributes`).
    *   Admin settings (`_maxSupply`, `_observationFee`, `_fluctuationFee`, `_entanglementEffectFee`, `_entanglementEffectCooldown`).
    *   Counters (`_nextTokenId`, `_totalSupply`).
    *   Cooldowns (`_entanglementEffectCooldowns`, `_fluctuationCooldowns`).
    *   Prediction modifiers (`_superpositionFluctuationModifiers`).

3.  **Events:**
    *   Standard ERC721 events.
    *   `Observed` (tokenId, newPhase).
    *   `Entangled` (tokenId1, tokenId2).
    *   `Disentangled` (tokenId1, tokenId2).
    *   `EntanglementEffectTriggered` (triggerTokenId, affectedTokenId, outcomeMessage).
    *   `SuperpositionFluctuated` (tokenId, modifierValue).
    *   `PhaseAttributesSet` (phase, uri).
    *   Fee/Setting updates.

4.  **Modifiers:**
    *   Standard `onlyOwner`, `whenNotPaused`.
    *   `whenPaused`.
    *   Custom checks (e.g., `onlySuperposition`, `onlyObserved`, `notEntangled`).

5.  **Functions (20+ required):**

    *   **Standard ERC721 (Inherited/Overridden - ~12 functions):**
        1.  `constructor`
        2.  `balanceOf(address owner)` (view)
        3.  `ownerOf(uint256 tokenId)` (view)
        4.  `approve(address to, uint256 tokenId)`
        5.  `getApproved(uint256 tokenId)` (view)
        6.  `setApprovalForAll(address operator, bool approved)`
        7.  `isApprovedForAll(address owner, address operator)` (view)
        8.  `transferFrom(address from, address to, uint256 tokenId)`
        9.  `safeTransferFrom(address from, address to, uint256 tokenId)` (overload 1)
        10. `safeTransferFrom(address from, address to, uint256 tokenId)` (overload 2)
        11. `tokenURI(uint256 tokenId)` (view, overridden) - Returns URI based on phase.
        12. `_burn(uint256 tokenId)` (internal, overridden) - Handles burning, including entangled twin.
        13. `_beforeTokenTransfer(...)` (internal, overridden) - Handles entanglement breaking on transfer.

    *   **Custom Core Mechanics (~6 functions):**
        14. `mint()` - Mints a new token in Superposition (Phase 0). Payable to mint.
        15. `observe(uint256 tokenId)` - Collapses superposition based on randomness. Payable for observation fee.
        16. `entangle(uint256 tokenId1, uint256 tokenId2)` - Links two NFTs. Requires both owned by caller, observed, and not entangled.
        17. `disentangle(uint256 tokenId)` - Breaks the entanglement link for a token and its pair.
        18. `triggerEntanglementEffect(uint256 tokenId)` - Executes a conditional state change on the entangled pair. Payable for fee, respects cooldown.
        19. `superpositionFluctuate(uint256 tokenId)` - Adds a modifier for predicting observation outcome. Only for Phase 0 tokens, payable for fee, respects cooldown.

    *   **View Functions (~4 functions):**
        20. `getPhase(uint256 tokenId)` (view) - Gets the current phase of a token.
        21. `isEntangled(uint256 tokenId)` (view) - Checks if a token is entangled.
        22. `getEntangledToken(uint256 tokenId)` (view) - Gets the ID of the token an NFT is entangled with.
        23. `predictObservationOutcome(uint256 tokenId)` (view) - Predicts the potential outcome of observation using current block data and fluctuation modifiers (non-binding).
        24. `getPhaseAttributes(uint8 phase)` (view) - Gets the URI/metadata for a specific phase.

    *   **Admin/Owner Functions (~8 functions):**
        25. `pause()`
        26. `unpause()`
        27. `withdrawEther()`
        28. `setMaxSupply(uint256 supply)`
        29. `setObservationFee(uint256 fee)`
        30. `setFluctuationFee(uint256 fee)`
        31. `setEntanglementEffectFee(uint256 fee)`
        32. `setEntanglementEffectCooldown(uint48 cooldown)`
        33. `setFluctuationCooldown(uint48 cooldown)`
        34. `setPhaseAttributes(uint8 phase, string memory uri)`

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Contract: QuantumEntangledNFTs ---
//
// Outline:
// 1. Contract Overview: ERC721 with dynamic "Quantum" mechanics: Superposition (Phase 0), Observation (collapse), Entanglement (linking), Fluctuation (prediction modifiers).
// 2. State Variables: Track phases, entanglement links, admin settings, cooldowns, prediction modifiers.
// 3. Events: Standard ERC721, plus custom events for state changes (Observed, Entangled, etc.).
// 4. Modifiers: Standard access control (Ownable, Pausable) plus custom state checks (onlySuperposition, etc.).
// 5. Functions:
//    - Standard ERC721 (Inherited/Overridden) for core NFT functionality.
//    - Custom Core Mechanics: mint, observe (collapse superposition), entangle (link tokens), disentangle (break link), triggerEntanglementEffect (conditional state change), superpositionFluctuate (modify prediction factors).
//    - View Functions: getPhase, isEntangled, getEntangledToken, predictObservationOutcome, getPhaseAttributes.
//    - Admin Functions: pause, unpause, withdraw, set fees, set cooldowns, set max supply, set phase metadata.
//
// Function Summary:
// - Standard ERC721 (13 functions): Basic NFT operations (mint, transfer, balance, ownership, approvals, URI override, internal burn/transfer hooks).
// - mint(): Mints a new NFT in Phase 0 (Superposition).
// - observe(uint256 tokenId): Collapses a Superposition token to a random Observed phase (1-based). Charges fee.
// - entangle(uint256 tokenId1, uint256 tokenId2): Links two distinct, observed, and non-entangled tokens owned by the caller.
// - disentangle(uint256 tokenId): Breaks the entanglement link for the specified token and its pair.
// - triggerEntanglementEffect(uint256 tokenId): Attempts to apply a conditional phase change effect to the entangled pair based on current states. Charges fee, respects cooldown.
// - superpositionFluctuate(uint256 tokenId): Adds a modifier to a Phase 0 token for future prediction calculations. Charges fee, respects cooldown.
// - getPhase(uint256 tokenId): Returns the current phase of a token.
// - isEntangled(uint256 tokenId): Returns true if a token is entangled.
// - getEntangledToken(uint256 tokenId): Returns the ID of the token's entangled pair (0 if not entangled).
// - predictObservationOutcome(uint256 tokenId): Provides a non-binding prediction of the outcome if observe() were called now, considering fluctuation modifiers.
// - getPhaseAttributes(uint8 phase): Returns the base URI for a specific phase.
// - pause(): Pauses most contract interactions (Owner only).
// - unpause(): Unpauses contract interactions (Owner only).
// - withdrawEther(): Withdraws collected fees (Owner only).
// - setMaxSupply(uint256 supply): Sets the maximum number of tokens that can be minted (Owner only).
// - setObservationFee(uint256 fee): Sets the fee for the observe() function (Owner only).
// - setFluctuationFee(uint256 fee): Sets the fee for the superpositionFluctuate() function (Owner only).
// - setEntanglementEffectFee(uint256 fee): Sets the fee for the triggerEntanglementEffect() function (Owner only).
// - setEntanglementEffectCooldown(uint48 cooldown): Sets the cooldown duration for entanglement effect triggers (Owner only).
// - setFluctuationCooldown(uint48 cooldown): Sets the cooldown duration for fluctuation (Owner only).
// - setPhaseAttributes(uint8 phase, string memory uri): Sets the base metadata/URI string for a given phase (Owner only).
// --- End Function Summary ---

contract QuantumEntangledNFTs is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    Counters.Counter private _nextTokenId;

    // State: 0 = Superposition (default), 1+ = Observed/Collapsed Phase
    mapping(uint256 => uint8) private _phases; // tokenId => phase (0 for superposition)
    mapping(uint8 => string) private _phaseAttributes; // phase => base tokenURI string

    // Entanglement: tokenId => entangled tokenId (0 if not entangled)
    mapping(uint256 => uint256) private _entangledWith;

    // Fees and Limits
    uint256 private _maxSupply;
    uint256 private _observationFee;
    uint256 private _fluctuationFee;
    uint256 private _entanglementEffectFee;

    // Cooldowns (using uint48 for packing, max ~9 trillion seconds)
    uint48 private _entanglementEffectCooldown;
    uint48 private _fluctuationCooldown;
    mapping(uint256 => uint48) private _entanglementEffectCooldowns; // tokenId => next trigger timestamp
    mapping(uint256 => uint48) private _fluctuationCooldowns; // tokenId => next fluctuation timestamp

    // Superposition Fluctuation Modifiers (used for prediction visualization, not final randomness)
    // Maps tokenId to a list of unique modifiers added during fluctuation
    mapping(uint256 => bytes32[]) private _superpositionFluctuationModifiers;

    // Max phase value (e.g., 3 for Phase 1, 2, 3 after observation)
    uint8 public constant MAX_OBSERVABLE_PHASE = 3; // Example: Phases 1, 2, 3
    uint8 public constant SUPERPOSITION_PHASE = 0;

    // --- Events ---
    event Observed(uint256 indexed tokenId, uint8 newPhase);
    event Entangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event Disentangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EntanglementEffectTriggered(uint256 indexed triggerTokenId, uint256 indexed affectedTokenId, string outcomeMessage);
    event SuperpositionFluctuated(uint256 indexed tokenId, bytes32 modifierValue);
    event PhaseAttributesSet(uint8 indexed phase, string uri);
    event MaxSupplySet(uint256 supply);
    event FeesSet(uint256 observationFee, uint256 fluctuationFee, uint256 entanglementEffectFee);
    event CooldownsSet(uint48 entanglementEffectCooldown, uint48 fluctuationCooldown);


    // --- Modifiers ---
    modifier onlySuperposition(uint256 tokenId) {
        require(_exists(tokenId), "Token does not exist");
        require(_phases[tokenId] == SUPERPOSITION_PHASE, "Token is not in Superposition");
        _;
    }

    modifier onlyObserved(uint256 tokenId) {
        require(_exists(tokenId), "Token does not exist");
        require(_phases[tokenId] > SUPERPOSITION_PHASE, "Token is not Observed");
        _;
    }

    modifier notEntangled(uint256 tokenId) {
        require(_entangledWith[tokenId] == 0, "Token is already entangled");
        _;
    }

    modifier onlyEntangled(uint256 tokenId) {
        require(_entangledWith[tokenId] != 0, "Token is not entangled");
        _;
    }

    modifier notSelf(uint256 tokenId1, uint256 tokenId2) {
        require(tokenId1 != tokenId2, "Cannot use the same token");
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, uint256 maxSupply)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _maxSupply = maxSupply;
    }

    // --- Standard ERC721 Overrides ---

    function _baseURI() internal view override returns (string memory) {
        // We use tokenURI directly for phase-specific metadata
        return "";
    }

    /// @dev See {ERC721-tokenURI}. Returns metadata URI based on the token's phase.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint8 currentPhase = _phases[tokenId];
        string memory baseURI = _phaseAttributes[currentPhase];
        // Optional: Append token ID or other data if baseURI is just a directory
        // return string(abi.encodePacked(baseURI, tokenId.toString()));
        return baseURI;
    }

    /// @dev See {ERC721Enumerable-totalSupply}.
    function totalSupply() public view override(ERC721, ERC721Enumerable) returns (uint256) {
        return _nextTokenId.current();
    }

    /// @dev See {ERC721Enumerable-tokenOfOwnerByIndex}.
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (uint256)
    {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    /// @dev See {ERC721Enumerable-tokenByIndex}.
    function tokenByIndex(uint256 index)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (uint256)
    {
        return super.tokenByIndex(index);
    }

    /// @dev See {ERC721-_beforeTokenTransfer}. Handles entanglement breaking on transfer.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId);

        // Break entanglement if transferred, unless it's a mint or burn
        if (from != address(0) && to != address(0)) {
             // Note: Transferring both entangled tokens simultaneously in a single transaction
             // is not automatically handled here and would require more complex
             // batch transfer logic or external wrapper. Standard ERC721 transfer
             // handles one token at a time, breaking entanglement if the pair isn't also moving.
            uint256 entangledTokenId = _entangledWith[tokenId];
            if (entangledTokenId != 0) {
                // Only break if the pair isn't also being transferred BY THE SAME CALL
                // This is hard to check reliably in a single-token hook.
                // Simpler approach: Transferring *any* entangled token breaks the link.
                // A user wanting to keep them entangled must disentangle first, then transfer both.
                 _disentangle(tokenId, entangledTokenId); // Use internal helper
                 emit Disentangled(tokenId, entangledTokenId);
            }
        }
    }

    /// @dev See {ERC721-_burn}. Handles burning, including the entangled twin.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        // First, handle entanglement: if burning an entangled token, burn its twin
        uint256 entangledTokenId = _entangledWith[tokenId];
        if (entangledTokenId != 0) {
             // To avoid reentrancy/infinite loop via the burn hook itself,
             // we break the entanglement *before* burning the second token.
            _disentangle(tokenId, entangledTokenId); // Use internal helper
             emit Disentangled(tokenId, entangledTokenId);
            // Check existence before burning the twin, just in case (should exist)
            if (_exists(entangledTokenId)) {
                 super._burn(entangledTokenId);
            }
        }
        // Then, perform the actual burn of the requested token
        super._burn(tokenId);
         // Clean up phase and fluctuation data
        delete _phases[tokenId];
        delete _superpositionFluctuationModifiers[tokenId];
        delete _fluctuationCooldowns[tokenId];
        delete _entanglementEffectCooldowns[tokenId];
    }


    // --- Custom Core Mechanics ---

    /// @notice Mints a new QuantumEntangledNFT in the Superposition phase (Phase 0).
    /// @dev Payable function. Checks against max supply.
    /// @return The ID of the newly minted token.
    function mint() public payable whenNotPaused returns (uint256) {
        uint256 newTokenId = _nextTokenId.current();
        require(newTokenId < _maxSupply, "Max supply reached");

        // Mint the token
        _safeMint(msg.sender, newTokenId);

        // Set initial phase to Superposition (Phase 0)
        _phases[newTokenId] = SUPERPOSITION_PHASE;
        _nextTokenId.increment();

        return newTokenId;
    }

    /// @notice Collapses the superposition of a token, fixing its phase based on on-chain randomness.
    /// @dev Requires the token to be in Superposition (Phase 0) and owned by the caller.
    /// @param tokenId The ID of the token to observe.
    function observe(uint256 tokenId) public payable onlySuperposition(tokenId) whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "Caller must own the token");
        require(msg.value >= _observationFee, "Insufficient fee");

        // Pay the fee
        (bool success, ) = payable(owner()).call{value: msg.value}("");
        require(success, "Fee payment failed");

        // Determine the outcome phase based on unpredictable block data
        // Using a combination of timestamp, prevrandao (if available), sender, and tokenId
        // prevrandao is preferred if block.timestamp has low entropy.
        // For chains without prevrandao like older ones or some L2s, block.timestamp is the fallback.
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId)));
        // Use block.prevrandao if available (post-Merge Ethereum)
        if (block.chainid == 1 || block.chainid == 5 || block.chainid == 11155111) { // Mainnet, Goerli, Sepolia - generally support prevrandao
             randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, tokenId)));
        }


        // The outcome is modulo MAX_OBSERVABLE_PHASE, +1 because phases start from 1
        uint8 newPhase = uint8((randomSeed % MAX_OBSERVABLE_PHASE) + 1);

        // Set the new phase
        _phases[tokenId] = newPhase;

        // Clean up fluctuation modifiers as they are no longer relevant for prediction post-observation
        delete _superpositionFluctuationModifiers[tokenId];
        delete _fluctuationCooldowns[tokenId]; // Reset fluctuation cooldown

        emit Observed(tokenId, newPhase);
    }

    /// @notice Links two distinct, observed, and non-entangled NFTs owned by the caller.
    /// @dev Requires caller owns both tokens, both are observed, and neither is currently entangled.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function entangle(uint256 tokenId1, uint256 tokenId2) public notSelf(tokenId1, tokenId2) onlyObserved(tokenId1) onlyObserved(tokenId2) notEntangled(tokenId1) notEntangled(tokenId2) whenNotPaused {
        require(ownerOf(tokenId1) == msg.sender, "Caller must own token 1");
        require(ownerOf(tokenId2) == msg.sender, "Caller must own token 2");

        _entangledWith[tokenId1] = tokenId2;
        _entangledWith[tokenId2] = tokenId1;

        // Reset entanglement effect cooldown for both upon entanglement
        _entanglementEffectCooldowns[tokenId1] = 0;
        _entanglementEffectCooldowns[tokenId2] = 0;

        emit Entangled(tokenId1, tokenId2);
    }

    /// @notice Breaks the entanglement link for a specified token and its pair.
    /// @dev Requires the token to be owned by the caller and currently entangled.
    /// @param tokenId The ID of one of the entangled tokens.
    function disentangle(uint256 tokenId) public onlyEntangled(tokenId) whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "Caller must own the token");

        uint256 entangledTokenId = _entangledWith[tokenId];
        _disentangle(tokenId, entangledTokenId); // Use internal helper

        emit Disentangled(tokenId, entangledTokenId);
    }

    /// @notice Triggers a conditional effect on an entangled pair based on their current phases.
    /// @dev Requires the token to be owned by the caller, entangled, and respects the cooldown.
    /// @param tokenId The ID of the token triggering the effect.
    function triggerEntanglementEffect(uint256 tokenId) public payable onlyEntangled(tokenId) onlyObserved(tokenId) whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "Caller must own the token");
        require(msg.value >= _entanglementEffectFee, "Insufficient fee");
        require(uint48(block.timestamp) >= _entanglementEffectCooldowns[tokenId], "Entanglement effect is on cooldown");

         // Pay the fee
        (bool success, ) = payable(owner()).call{value: msg.value}("");
        require(success, "Fee payment failed");

        uint256 entangledTokenId = _entangledWith[tokenId];
        uint8 triggerPhase = _phases[tokenId];
        uint8 entangledPhase = _phases[entangledTokenId];
        string memory outcomeMessage = "No effect";

        // Example Effect Logic: Cycles phases based on modulo arithmetic
        // If TriggerPhase is P and EntangledPhase is Q, try to change Entangled to (Q + P) % MAX_OBSERVABLE_PHASE + 1
        // Make it conditional: only if entangledPhase is different from triggerPhase
        if (triggerPhase != entangledPhase) {
            uint8 newEntangledPhase = uint8(((entangledPhase - 1 + triggerPhase - 1) % MAX_OBSERVABLE_PHASE) + 1); // -1 for 0-based calculation, +1 for 1-based phase
            _phases[entangledTokenId] = newEntangledPhase;
            outcomeMessage = string(abi.encodePacked("Affected token phase changed from ", entangledPhase.toString(), " to ", newEntangledPhase.toString()));
        } else {
             outcomeMessage = "Phases are the same, no conditional change occurred";
        }

        // Set cooldown for both entangled tokens
        uint48 nextCooldownTime = uint48(block.timestamp + _entanglementEffectCooldown);
        _entanglementEffectCooldowns[tokenId] = nextCooldownTime;
        _entanglementEffectCooldowns[entangledTokenId] = nextCooldownTime;


        emit EntanglementEffectTriggered(tokenId, entangledTokenId, outcomeMessage);
    }

    /// @notice Adds a modifier to a Superposition token, potentially influencing the prediction of its observation outcome.
    /// @dev Only for tokens in Superposition (Phase 0). Requires fee and respects cooldown.
    /// @param tokenId The ID of the token to fluctuate.
    function superpositionFluctuate(uint256 tokenId) public payable onlySuperposition(tokenId) whenNotPaused {
         require(ownerOf(tokenId) == msg.sender, "Caller must own the token");
         require(msg.value >= _fluctuationFee, "Insufficient fee");
         require(uint48(block.timestamp) >= _fluctuationCooldowns[tokenId], "Fluctuation is on cooldown");

        // Pay the fee
        (bool success, ) = payable(owner()).call{value: msg.value}("");
        require(success, "Fee payment failed");

        // Generate a unique modifier based on sender, block, etc.
        bytes32 modifierValue = keccak256(abi.encodePacked(msg.sender, block.timestamp, block.number, _superpositionFluctuationModifiers[tokenId].length));
        _superpositionFluctuationModifiers[tokenId].push(modifierValue);

         // Set cooldown
        _fluctuationCooldowns[tokenId] = uint48(block.timestamp + _fluctuationCooldown);

        emit SuperpositionFluctuated(tokenId, modifierValue);
    }


    // --- View Functions ---

    /// @notice Gets the current phase of a token.
    /// @param tokenId The ID of the token.
    /// @return The phase (0 for Superposition, 1+ for Observed). Returns 0 if token doesn't exist.
    function getPhase(uint256 tokenId) public view returns (uint8) {
        if (!_exists(tokenId)) {
            return 0; // Or handle as error
        }
        return _phases[tokenId];
    }

    /// @notice Checks if a token is currently entangled with another.
    /// @param tokenId The ID of the token.
    /// @return True if entangled, false otherwise or if token doesn't exist.
    function isEntangled(uint256 tokenId) public view returns (bool) {
         if (!_exists(tokenId)) {
            return false;
        }
        return _entangledWith[tokenId] != 0;
    }

    /// @notice Gets the ID of the token's entangled pair.
    /// @param tokenId The ID of the token.
    /// @return The ID of the entangled token, or 0 if not entangled or token doesn't exist.
    function getEntangledToken(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) {
            return 0;
        }
        return _entangledWith[tokenId];
    }

    /// @notice Provides a non-binding prediction of the observation outcome for a Superposition token.
    /// @dev Uses current block data and accumulated fluctuation modifiers. Not guaranteed to be the actual outcome.
    /// @param tokenId The ID of the Superposition token.
    /// @return The predicted phase outcome (1+). Returns 0 if token is not in Superposition.
    function predictObservationOutcome(uint256 tokenId) public view returns (uint8) {
        if (_phases[tokenId] != SUPERPOSITION_PHASE) {
            return 0; // Only predict for superposition tokens
        }

        // Base seed from current block data (same logic as observe, but static)
         uint256 predictionSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId)));
         if (block.chainid == 1 || block.chainid == 5 || block.chainid == 11155111) {
             predictionSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, tokenId)));
         }


        // Incorporate fluctuation modifiers into the prediction seed
        bytes32[] memory modifiers = _superpositionFluctuationModifiers[tokenId];
        for (uint i = 0; i < modifiers.length; i++) {
            predictionSeed = uint256(keccak256(abi.encodePacked(predictionSeed, modifiers[i])));
        }

        // Predict the outcome phase (1-based)
        uint8 predictedPhase = uint8((predictionSeed % MAX_OBSERVABLE_PHASE) + 1);

        return predictedPhase;
    }

    /// @notice Gets the base metadata/URI string associated with a specific phase.
    /// @param phase The phase number (0 for Superposition, 1+ for Observed phases).
    /// @return The base URI string for the phase.
    function getPhaseAttributes(uint8 phase) public view returns (string memory) {
        return _phaseAttributes[phase];
    }

    // --- Admin/Owner Functions ---

    /// @notice Pauses contract functions.
    /// @dev Only owner can call.
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses contract functions.
    /// @dev Only owner can call.
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Allows the owner to withdraw collected Ether fees.
    /// @dev Only owner can call.
    function withdrawEther() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Ether withdrawal failed");
    }

    /// @notice Sets the maximum number of tokens that can be minted.
    /// @dev Only owner can call. Must be greater than or equal to the current total supply.
    /// @param supply The new maximum supply.
    function setMaxSupply(uint256 supply) public onlyOwner {
        require(supply >= _nextTokenId.current(), "New supply must be >= current supply");
        _maxSupply = supply;
        emit MaxSupplySet(supply);
    }

    /// @notice Sets the fees for core interactions.
    /// @dev Only owner can call.
    /// @param observationFee_ Fee for observe().
    /// @param fluctuationFee_ Fee for superpositionFluctuate().
    /// @param entanglementEffectFee_ Fee for triggerEntanglementEffect().
    function setFees(uint256 observationFee_, uint256 fluctuationFee_, uint256 entanglementEffectFee_) public onlyOwner {
        _observationFee = observationFee_;
        _fluctuationFee = fluctuationFee_;
        _entanglementEffectFee = entanglementEffectFee_;
        emit FeesSet(_observationFee, _fluctuationFee, _entanglementEffectFee);
    }

     /// @notice Sets the cooldown durations for specific actions.
    /// @dev Only owner can call.
    /// @param entanglementEffectCooldown_ Cooldown for triggerEntanglementEffect() in seconds.
    /// @param fluctuationCooldown_ Cooldown for superpositionFluctuate() in seconds.
    function setCooldowns(uint48 entanglementEffectCooldown_, uint48 fluctuationCooldown_) public onlyOwner {
        _entanglementEffectCooldown = entanglementEffectCooldown_;
        _fluctuationCooldown = fluctuationCooldown_;
        emit CooldownsSet(_entanglementEffectCooldown, _fluctuationCooldown);
    }


    /// @notice Sets the base metadata/URI string for a specific phase.
    /// @dev Only owner can call. Allows defining the visual/data representation of each phase.
    /// @param phase The phase number (0 for Superposition, 1+ for Observed).
    /// @param uri The base URI string (e.g., IPFS hash or URL prefix).
    function setPhaseAttributes(uint8 phase, string memory uri) public onlyOwner {
        require(phase <= MAX_OBSERVABLE_PHASE, "Invalid phase number");
        _phaseAttributes[phase] = uri;
        emit PhaseAttributesSet(phase, uri);
    }

     // --- Internal Helpers ---

    /// @dev Internal helper to break entanglement between two tokens.
    function _disentangle(uint256 tokenId1, uint256 tokenId2) internal {
        if (_entangledWith[tokenId1] == tokenId2 && _entangledWith[tokenId2] == tokenId1) {
            delete _entangledWith[tokenId1];
            delete _entangledWith[tokenId2];
        }
    }
}
```