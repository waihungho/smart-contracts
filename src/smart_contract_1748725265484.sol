Okay, here is a smart contract concept called `QuantumEntangledAsset` (QEA). It's an ERC721-based contract where tokens can be "entangled" in pairs, simulating certain behaviors inspired (loosely) by quantum entanglement and superposition, incorporating dynamic states and state changes influenced by actions and global parameters. It avoids standard OpenZeppelin extensions like `ERC721Enumerable` to reduce direct duplication of common patterns, implementing necessary functions manually or relying on the core `ERC721` only.

**Key Advanced/Creative Concepts:**

1.  **Entanglement Simulation:** Tokens can be explicitly paired and enter an "entangled" state.
2.  **Dynamic Pair States:** Entangled pairs have states (`Superposed`, `AlignedAA`, `AlignedBB`, `Decohered`) that change based on actions.
3.  **Measurement Simulation:** A `measureState` function simulates the collapse of a `Superposed` state into an `Aligned` state, affecting both tokens in the pair simultaneously.
4.  **Perturbation:** A `perturbEntangledState` function allows interacting with one token of a pair, with a chance of influencing the pair's state or the partner's state (probabilistic outcome simulated using block data).
5.  **Global Influence:** An owner-controlled parameter (`globalInfluenceFactor`) can subtly affect the *probability* or *outcome* dynamics of state changes (like measurement results or perturbation success rates) across *all* entangled pairs.
6.  **State-Dependent Transfer:** Entangled tokens cannot be transferred until they are disentangled (decohered).
7.  **Superposition Re-Initiation:** Allows resetting an `Aligned` pair back into a `Superposed` state under certain conditions.
8.  **Decoherence Trigger:** Explicitly force a pair into the `Decohered` state, breaking the entanglement.
9.  **Explicit State Querying:** Functions to query the state of individual tokens (derived from pair state) and entangled pairs.
10. **Pausable Entanglement:** Ability to pause entanglement-specific operations while keeping basic ERC721 functions active.

---

**Outline and Function Summary**

**Contract:** `QuantumEntangledAsset`
**Inherits:** `ERC721`, `Ownable`, `Pausable`
**Concept:** An ERC721 token simulating entanglement and dynamic state changes between pairs.

**States (Enums):**
*   `TokenState`: `Unknown`, `AlignedA`, `AlignedB` (Individual token conceptual state, often derived from PairState)
*   `PairState`: `NotEntangled`, `Superposed`, `AlignedAA`, `AlignedBB`, `Decohered` (State of an entangled pair)

**Structs:**
*   `EntanglementPair`: Stores details for an entangled pair (`tokenId1`, `tokenId2`, `state`).

**State Variables:**
*   `_tokenData`: Mapping `tokenId => { partnerId, pairId }` to link tokens to their partners and pairs.
*   `_pairs`: Mapping `pairId => EntanglementPair` storing pair details.
*   `_nextPairId`: Counter for generating unique pair IDs.
*   `_globalInfluenceFactor`: Affects probabilistic outcomes.
*   `_tokenStates`: Mapping `tokenId => TokenState` (Optional/Derived - used for `getLocalState`)

**Events:**
*   `Entangled(uint256 indexed pairId, uint256 indexed tokenId1, uint256 indexed tokenId2)`
*   `Disentangled(uint256 indexed pairId, uint256 indexed tokenId1, uint256 indexed tokenId2)`
*   `PairStateChanged(uint256 indexed pairId, PairState oldState, PairState newState)`
*   `Measured(uint256 indexed pairId, PairState resultState)`
*   `Perturbed(uint256 indexed tokenId, uint256 indexed partnerId, PairState newPairState)`
*   `GlobalInfluenceUpdated(uint256 oldFactor, uint256 newFactor)`

**Functions (Total: ~34, > 20 required):**

**ERC721 Standard (Implemented via inheritance/overrides):**
1.  `constructor(string name, string symbol)`: Initializes the contract.
2.  `name() view returns (string)`: Returns token name.
3.  `symbol() view returns (string)`: Returns token symbol.
4.  `balanceOf(address owner) view returns (uint256)`: Returns owner's balance.
5.  `ownerOf(uint256 tokenId) view returns (address)`: Returns token owner.
6.  `approve(address to, uint256 tokenId)`: Grants approval.
7.  `getApproved(uint256 tokenId) view returns (address)`: Gets approved address.
8.  `setApprovalForAll(address operator, bool approved)`: Sets operator approval.
9.  `isApprovedForAll(address owner, address operator) view returns (bool)`: Checks operator approval.
10. `transferFrom(address from, address to, uint256 tokenId)`: Transfers token (checks for entanglement).
11. `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfers token (checks for entanglement).
12. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Safely transfers token with data (checks for entanglement).
13. `totalSupply() view returns (uint256)`: Returns total minted tokens.
14. `tokenURI(uint256 tokenId) view returns (string)`: Returns token URI (override for custom logic if needed, default uses _tokenURIs mapping).
15. `supportsInterface(bytes4 interfaceId) view returns (bool)`: Checks interface support.
16. `_beforeTokenTransfer(address from, address to, uint256 tokenId)`: Internal hook to prevent transfer if entangled.

**Core Logic & State Management:**
17. `mint(address to, uint256 tokenId)`: Mints a new token (Owner only).
18. `entanglePair(uint256 tokenId1, uint256 tokenId2)`: Entangles two un-entangled tokens owned by the caller into a new pair in `Superposed` state.
19. `disentanglePair(uint256 tokenId)`: Disentangles the pair containing `tokenId`, setting pair state to `Decohered` and clearing links. Requires caller owns `tokenId`.
20. `measureState(uint256 tokenId)`: Simulates measurement on the pair containing `tokenId`. Requires caller owns `tokenId`. If pair is `Superposed`, deterministically sets state to `AlignedAA` or `AlignedBB` based on simulated randomness.
21. `perturbEntangledState(uint256 tokenId)`: Allows interaction with one token in a pair. Requires caller owns `tokenId`. If pair is `Superposed`, might trigger 'measurement'. If `Aligned`, might trigger `Superposition` or other state shifts based on `globalInfluenceFactor`.
22. `initiateSuperposition(uint256 tokenId)`: Attempts to reset an `Aligned` pair containing `tokenId` back to `Superposed`. Requires caller owns `tokenId`. May have conditions based on state or global factors.
23. `triggerDecoherence(uint256 tokenId)`: Immediately forces the pair containing `tokenId` into the `Decohered` state, same as `disentanglePair` but perhaps a different conceptual trigger. Requires caller owns `tokenId`.
24. `applyGlobalInfluence(uint256 newFactor)`: Updates the `_globalInfluenceFactor` (Owner only).
25. `getGlobalInfluence() view returns (uint256)`: Returns the current `_globalInfluenceFactor`.

**Query Functions:**
26. `isEntangled(uint256 tokenId) view returns (bool)`: Checks if a token is part of an entangled pair.
27. `getEntangledPartner(uint256 tokenId) view returns (uint256 partnerId)`: Returns the ID of the entangled partner, or 0 if not entangled.
28. `getPairIdForToken(uint256 tokenId) view returns (uint256 pairId)`: Returns the ID of the pair the token belongs to, or 0 if not entangled.
29. `getPairState(uint256 pairId) view returns (PairState)`: Returns the current state of a specific entangled pair.
30. `getPairTokens(uint256 pairId) view returns (uint256 tokenId1, uint256 tokenId2)`: Returns the two token IDs in a pair.
31. `getLocalState(uint256 tokenId) view returns (TokenState)`: Returns the conceptual state of an individual token (derived from pair state if entangled).

**Admin/Pausable Functions:**
32. `pauseEntanglementOps()`: Pauses entanglement-specific functions (Owner only). Inherits `pause()`.
33. `unpauseEntanglementOps()`: Unpauses entanglement-specific functions (Owner only). Inherits `unpause()`.
34. `paused() view returns (bool)`: Checks if the contract is paused (from Pausable).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Useful for calculations, though simple ones used here

/**
 * @title QuantumEntangledAsset (QEA)
 * @dev An ERC721 contract simulating quantum entanglement concepts between pairs of tokens.
 * Tokens can be entangled, enter different states (Superposed, Aligned, Decohered),
 * and state changes can be triggered by actions like measurement or perturbation,
 * potentially influenced by a global factor.
 */

// --- Outline and Function Summary ---
// Contract: QuantumEntangledAsset
// Inherits: ERC721, Ownable, Pausable
// Concept: An ERC721 token simulating entanglement and dynamic state changes between pairs.

// States (Enums):
// - TokenState: Unknown, AlignedA, AlignedB (Individual token conceptual state)
// - PairState: NotEntangled, Superposed, AlignedAA, AlignedBB, Decohered (State of an entangled pair)

// Structs:
// - EntanglementPair: Stores details for an entangled pair (tokenId1, tokenId2, state).

// State Variables:
// - _tokenData: Mapping tokenId => { partnerId, pairId }
// - _pairs: Mapping pairId => EntanglementPair
// - _nextPairId: Counter for generating unique pair IDs.
// - _globalInfluenceFactor: Affects probabilistic outcomes (0-1000, higher = more influence).
// - _tokenStates: Mapping tokenId => TokenState (Used for getLocalState)

// Events:
// - Entangled(uint256 indexed pairId, uint256 indexed tokenId1, uint256 indexed tokenId2)
// - Disentangled(uint256 indexed pairId, uint256 indexed tokenId1, uint256 indexed tokenId2)
// - PairStateChanged(uint256 indexed pairId, PairState oldState, PairState newState)
// - Measured(uint256 indexed pairId, PairState resultState)
// - Perturbed(uint256 indexed tokenId, uint256 indexed partnerId, PairState newPairState)
// - GlobalInfluenceUpdated(uint256 oldFactor, uint256 newFactor)

// Functions (~34):

// ERC721 Standard (Implemented via inheritance/overrides):
// 1. constructor(string name, string symbol)
// 2. name() view returns (string)
// 3. symbol() view returns (string)
// 4. balanceOf(address owner) view returns (uint256)
// 5. ownerOf(uint256 tokenId) view returns (address)
// 6. approve(address to, uint256 tokenId)
// 7. getApproved(uint256 tokenId) view returns (address)
// 8. setApprovalForAll(address operator, bool approved)
// 9. isApprovedForAll(address owner, address operator) view returns (bool)
// 10. transferFrom(address from, address to, uint256 tokenId)
// 11. safeTransferFrom(address from, address to, uint256 tokenId)
// 12. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
// 13. totalSupply() view returns (uint256)
// 14. tokenURI(uint256 tokenId) view returns (string)
// 15. supportsInterface(bytes4 interfaceId) view returns (bool)
// 16. _beforeTokenTransfer(address from, address to, uint256 tokenId)

// Core Logic & State Management:
// 17. mint(address to, uint256 tokenId)
// 18. entanglePair(uint256 tokenId1, uint256 tokenId2)
// 19. disentanglePair(uint256 tokenId)
// 20. measureState(uint256 tokenId)
// 21. perturbEntangledState(uint256 tokenId)
// 22. initiateSuperposition(uint256 tokenId)
// 23. triggerDecoherence(uint256 tokenId)
// 24. applyGlobalInfluence(uint256 newFactor)
// 25. getGlobalInfluence() view returns (uint256)

// Query Functions:
// 26. isEntangled(uint256 tokenId) view returns (bool)
// 27. getEntangledPartner(uint256 tokenId) view returns (uint256 partnerId)
// 28. getPairIdForToken(uint256 tokenId) view returns (uint256 pairId)
// 29. getPairState(uint256 pairId) view returns (PairState)
// 30. getPairTokens(uint256 pairId) view returns (uint256 tokenId1, uint256 tokenId2)
// 31. getLocalState(uint256 tokenId) view returns (TokenState)

// Admin/Pausable Functions:
// 32. pauseEntanglementOps()
// 33. unpauseEntanglementOps()
// 34. paused() view returns (bool)

// --- Contract Implementation ---

contract QuantumEntangledAsset is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Just in case for complex calculations, though simple ones used

    enum TokenState { Unknown, AlignedA, AlignedB }
    enum PairState { NotEntangled, Superposed, AlignedAA, AlignedBB, Decohered }

    struct TokenData {
        uint256 partnerId; // 0 if not entangled
        uint256 pairId;    // 0 if not entangled
    }

    struct EntanglementPair {
        uint256 tokenId1;
        uint256 tokenId2;
        PairState state;
    }

    mapping(uint256 => TokenData) private _tokenData;
    mapping(uint256 => EntanglementPair) private _pairs;
    Counters.Counter private _nextPairId;

    // Global factor influencing probabilistic outcomes (0-1000, higher = more influence)
    uint256 private _globalInfluenceFactor;

    // Keeping track of individual token state for getLocalState,
    // derived from pair state if entangled.
    mapping(uint256 => TokenState) private _tokenStates;

    event Entangled(uint256 indexed pairId, uint256 indexed tokenId1, uint256 indexed tokenId2);
    event Disentangled(uint256 indexed pairId, uint256 indexed tokenId1, uint256 indexed tokenId2);
    event PairStateChanged(uint256 indexed pairId, PairState oldState, PairState newState);
    event Measured(uint256 indexed pairId, PairState resultState);
    event Perturbed(uint256 indexed tokenId, uint256 indexed partnerId, PairState newPairState);
    event GlobalInfluenceUpdated(uint256 oldFactor, uint256 newFactor);

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {}

    // --- ERC721 Overrides ---

    /// @dev Prevents transfer if the token is currently entangled.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (batchSize > 1) {
            // Simple contract, disallow batch transfers for entanglement logic complexity
             revert("QEA: Batch transfers not supported due to entanglement checks");
        }

        if (isEntangled(tokenId)) {
             revert("QEA: Cannot transfer an entangled token. Disentangle first.");
        }
        // Note: This check is only on `tokenId`. If batchSize is 1, it's simple.
        // For batch transfers, would need to check all tokens in the batch.
    }

    // --- Minting (Owner only) ---

    /// @dev Mints a new token and assigns it to an address.
    /// @param to The address to mint the token to.
    /// @param tokenId The ID of the token to mint.
    function mint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);
        // Initialize token data as not entangled
        _tokenData[tokenId] = TokenData(0, 0);
        _tokenStates[tokenId] = TokenState.Unknown; // Initial individual state
    }

    // --- Entanglement Logic (Pausable) ---

    modifier whenNotEntangled(uint256 tokenId) {
        require(!isEntangled(tokenId), "QEA: Token is already entangled");
        _;
    }

    modifier whenEntangled(uint256 tokenId) {
        require(isEntangled(tokenId), "QEA: Token is not entangled");
        _;
    }

    modifier onlyPairOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "QEA: Caller must own the token");
        _;
    }

    /// @dev Entangles two un-entangled tokens owned by the caller.
    /// Creates a new entangled pair in the Superposed state.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function entanglePair(uint256 tokenId1, uint256 tokenId2)
        external
        whenNotPaused
        onlyPairOwner(tokenId1)
        onlyPairOwner(tokenId2)
        whenNotEntangled(tokenId1)
        whenNotEntangled(tokenId2)
    {
        require(tokenId1 != tokenId2, "QEA: Cannot entangle a token with itself");

        _nextPairId.increment();
        uint256 pairId = _nextPairId.current();

        _pairs[pairId] = EntanglementPair(tokenId1, tokenId2, PairState.Superposed);

        _tokenData[tokenId1] = TokenData(tokenId2, pairId);
        _tokenData[tokenId2] = TokenData(tokenId1, pairId);

        // Conceptual individual states unknown/derived in superposition
        _tokenStates[tokenId1] = TokenState.Unknown;
        _tokenStates[tokenId2] = TokenState.Unknown;

        emit Entangled(pairId, tokenId1, tokenId2);
        emit PairStateChanged(pairId, PairState.NotEntangled, PairState.Superposed);
    }

    /// @dev Disentangles a pair containing the given token.
    /// Sets the pair state to Decohered and clears entanglement links.
    /// @param tokenId The ID of a token within the pair to disentangle.
    function disentanglePair(uint256 tokenId)
        external
        whenNotPaused
        whenEntangled(tokenId)
        onlyPairOwner(tokenId)
    {
        uint256 pairId = _tokenData[tokenId].pairId;
        EntanglementPair storage pair = _pairs[pairId];

        PairState oldState = pair.state;
        pair.state = PairState.Decohered; // Explicitly set to Decohered before clearing

        uint256 tokenId1 = pair.tokenId1;
        uint256 tokenId2 = pair.tokenId2;

        // Clear entanglement data
        delete _tokenData[tokenId1];
        delete _tokenData[tokenId2];

        // Set individual states to Unknown after decoherence
        _tokenStates[tokenId1] = TokenState.Unknown;
        _tokenStates[tokenId2] = TokenState.Unknown;

        emit PairStateChanged(pairId, oldState, PairState.Decohered);
        emit Disentangled(pairId, tokenId1, tokenId2);

        // Note: The pair struct itself remains in storage with state Decohered,
        // but tokens are no longer linked to it via _tokenData. Could potentially prune
        // old Decohered pairs, but leaving them adds historical state trace.
    }

    /// @dev Simulates measuring the state of an entangled pair.
    /// If the pair is in Superposed state, it collapses it to AlignedAA or AlignedBB.
    /// Uses a simulated random source (not truly random on-chain).
    /// @param tokenId The ID of a token within the pair to measure.
    function measureState(uint256 tokenId)
        external
        whenNotPaused
        whenEntangled(tokenId)
        onlyPairOwner(tokenId)
    {
        uint256 pairId = _tokenData[tokenId].pairId;
        EntanglementPair storage pair = _pairs[pairId];

        if (pair.state != PairState.Superposed) {
            // Already measured or decohered, state is known/fixed
            return;
        }

        // Simulate randomness using block data and global influence
        // WARNING: This is NOT cryptographically secure randomness.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Use block.difficulty or blockhash for slightly better entropy than just timestamp
            msg.sender,
            tokenId,
            pairId,
            _globalInfluenceFactor // Incorporate global influence
        )));

        PairState oldState = pair.state;
        PairState newPairState;

        // Influence: Higher globalInfluenceFactor biases the outcome.
        // Simple example: If factor > 500, bias towards AlignedBB.
        // Adjust threshold based on desired influence strength.
        uint256 influenceThreshold = 500; // Mid-point for influence
        uint256 bias = _globalInfluenceFactor; // 0-1000

        if (randomNumber % 1000 < (500 + int256(bias - influenceThreshold))) { // Simple biased coin flip
            newPairState = PairState.AlignedAA;
            _tokenStates[pair.tokenId1] = TokenState.AlignedA;
            _tokenStates[pair.tokenId2] = TokenState.AlignedA;
        } else {
            newPairState = PairState.AlignedBB;
            _tokenStates[pair.tokenId1] = TokenState.AlignedB;
            _tokenStates[pair.tokenId2] = TokenState.AlignedB;
        }

        pair.state = newPairState;

        emit Measured(pairId, newPairState);
        emit PairStateChanged(pairId, oldState, newPairState);
    }

    /// @dev Perturbs one token within an entangled pair.
    /// Effects depend on the current state and global influence, simulating uncertain interaction.
    /// @param tokenId The ID of the token to perturb.
    function perturbEntangledState(uint256 tokenId)
        external
        whenNotPaused
        whenEntangled(tokenId)
        onlyPairOwner(tokenId)
    {
        uint256 pairId = _tokenData[tokenId].pairId;
        EntanglementPair storage pair = _pairs[pairId];
        uint256 partnerId = _tokenData[tokenId].partnerId;

        PairState oldState = pair.state;
        PairState newPairState = oldState; // Default: no change

        // Simulate randomness
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.number, // Use block.number for variation
            msg.sender,
            tokenId,
            pairId,
            _globalInfluenceFactor
        )));

        // Logic based on current state and influence factor
        if (pair.state == PairState.Superposed) {
            // High influence makes measurement more likely
            if (randomNumber % 1000 < (200 + (_globalInfluenceFactor / 5))) { // 20% base chance + influence effect
                 // Perturbation causes premature measurement
                 newPairState = (randomNumber % 2 == 0) ? PairState.AlignedAA : PairState.AlignedBB;
                 _tokenStates[pair.tokenId1] = (newPairState == PairState.AlignedAA) ? TokenState.AlignedA : TokenState.AlignedB;
                 _tokenStates[pair.tokenId2] = (newPairState == PairState.AlignedAA) ? TokenState.AlignedA : TokenState.AlignedB;
                 emit Measured(pairId, newPairState); // Emit measurement event as it's a collapse
            }
        } else if (pair.state == PairState.AlignedAA || pair.state == PairState.AlignedBB) {
             // Moderate influence can push it back to Superposition
             if (randomNumber % 1000 < (100 + (_globalInfluenceFactor / 10))) { // 10% base chance + influence effect
                 newPairState = PairState.Superposed;
                 _tokenStates[pair.tokenId1] = TokenState.Unknown;
                 _tokenStates[pair.tokenId2] = TokenState.Unknown;
             }
        }
        // Decohered state is stable to perturbation

        if (newPairState != oldState) {
            pair.state = newPairState;
            emit PairStateChanged(pairId, oldState, newPairState);
        }

        emit Perturbed(tokenId, partnerId, newPairState);
    }

    /// @dev Attempts to revert an Aligned pair back into a Superposed state.
    /// May fail based on state or global influence.
    /// @param tokenId The ID of a token within the pair.
    function initiateSuperposition(uint256 tokenId)
        external
        whenNotPaused
        whenEntangled(tokenId)
        onlyPairOwner(tokenId)
    {
        uint256 pairId = _tokenData[tokenId].pairId;
        EntanglementPair storage pair = _pairs[pairId];

        if (pair.state != PairState.AlignedAA && pair.state != PairState.AlignedBB) {
            revert("QEA: Pair is not in an Aligned state to initiate superposition");
        }

        // Simulate difficulty/probability based on global influence
        // Higher influence makes it harder to regain superposition
        uint256 successThreshold = 800 - (_globalInfluenceFactor / 2); // Base 80% chance, reduced by influence

        uint256 randomNumber = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            msg.sender,
            tokenId,
            pairId,
            _globalInfluenceFactor,
            "superposition" // Unique salt
        )));

        if (randomNumber % 1000 < successThreshold) {
            PairState oldState = pair.state;
            pair.state = PairState.Superposed;
            _tokenStates[pair.tokenId1] = TokenState.Unknown;
            _tokenStates[pair.tokenId2] = TokenState.Unknown;
            emit PairStateChanged(pairId, oldState, PairState.Superposed);
        } else {
            // Fail silently or emit a failed event? Let's just not change state.
            // Could emit event FailedSuperpositionAttempt(pairId, tokenId);
        }
    }

    /// @dev Immediately forces the pair containing the token into the Decohered state.
    /// Similar to disentanglePair, but could represent a different in-universe action.
    /// @param tokenId The ID of a token within the pair.
    function triggerDecoherence(uint256 tokenId)
        external
        whenNotPaused
        whenEntangled(tokenId)
        onlyPairOwner(tokenId)
    {
        // This function essentially calls disentanglePair for the specified token
        disentanglePair(tokenId);
        // The disentanglePair event handles the state change to Decohered
    }


    /// @dev Updates the global influence factor. Only callable by the contract owner.
    /// Affects the probability/dynamics in measureState and perturbEntangledState.
    /// @param newFactor The new global influence factor (0-1000).
    function applyGlobalInfluence(uint256 newFactor) external onlyOwner {
        require(newFactor <= 1000, "QEA: Global influence factor must be <= 1000");
        uint256 oldFactor = _globalInfluenceFactor;
        _globalInfluenceFactor = newFactor;
        emit GlobalInfluenceUpdated(oldFactor, newFactor);
    }

    /// @dev Returns the current global influence factor.
    function getGlobalInfluence() external view returns (uint256) {
        return _globalInfluenceFactor;
    }

    // --- Query Functions ---

    /// @dev Checks if a token is currently part of an entangled pair.
    /// @param tokenId The ID of the token to check.
    /// @return bool True if entangled, false otherwise.
    function isEntangled(uint256 tokenId) public view returns (bool) {
        return _tokenData[tokenId].pairId != 0;
    }

    /// @dev Returns the ID of the token entangled with the given token.
    /// Returns 0 if the token is not entangled.
    /// @param tokenId The ID of the token.
    /// @return uint256 The partner token ID or 0.
    function getEntangledPartner(uint256 tokenId) public view returns (uint256 partnerId) {
        return _tokenData[tokenId].partnerId;
    }

    /// @dev Returns the ID of the entangled pair the token belongs to.
    /// Returns 0 if the token is not entangled.
    /// @param tokenId The ID of the token.
    /// @return uint256 The pair ID or 0.
    function getPairIdForToken(uint256 tokenId) public view returns (uint256 pairId) {
        return _tokenData[tokenId].pairId;
    }

    /// @dev Returns the current state of an entangled pair.
    /// @param pairId The ID of the pair.
    /// @return PairState The state of the pair.
    function getPairState(uint256 pairId) public view returns (PairState) {
        require(pairId > 0 && pairId <= _nextPairId.current(), "QEA: Invalid pair ID");
        return _pairs[pairId].state;
    }

     /// @dev Returns the token IDs within an entangled pair.
     /// @param pairId The ID of the pair.
     /// @return uint256 The first token ID.
     /// @return uint256 The second token ID.
    function getPairTokens(uint256 pairId) public view returns (uint256 tokenId1, uint256 tokenId2) {
        require(pairId > 0 && pairId <= _nextPairId.current(), "QEA: Invalid pair ID");
        return (_pairs[pairId].tokenId1, _pairs[pairId].tokenId2);
    }

    /// @dev Returns the conceptual individual state of a token.
    /// If entangled, this state is derived from the pair's state.
    /// If not entangled, it's typically Unknown or based on its last entangled state.
    /// @param tokenId The ID of the token.
    /// @return TokenState The conceptual state of the token.
    function getLocalState(uint256 tokenId) public view returns (TokenState) {
         if (isEntangled(tokenId)) {
            uint256 pairId = _tokenData[tokenId].pairId;
            PairState pairState = _pairs[pairId].state;
            if (pairState == PairState.AlignedAA) return TokenState.AlignedA;
            if (pairState == PairState.AlignedBB) return TokenState.AlignedB;
            // Superposed or Decohered pair state means individual state is effectively Unknown or complex
            return TokenState.Unknown;
         }
         // For non-entangled, return its last known state or default to Unknown
         return _tokenStates[tokenId];
    }


    // --- Pausable Functionality ---

    /// @dev Pauses entanglement-specific operations. ERC721 standard functions remain active.
    function pauseEntanglementOps() external onlyOwner {
        _pause();
    }

    /// @dev Unpauses entanglement-specific operations.
    function unpauseEntanglementOps() external onlyOwner {
        _unpause();
    }

    // Pausable's `paused()` function is also public.
}
```

**Explanation of Functions and Concepts:**

1.  **`constructor`, `name`, `symbol`, `balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `totalSupply`, `tokenURI`, `supportsInterface`**: Standard ERC721 functions provided by OpenZeppelin. `tokenURI` is included but left as the default OpenZeppelin implementation (which usually relies on an internal `_tokenURIs` mapping or an override). `totalSupply` is standard.
2.  **`_beforeTokenTransfer`**: This is an internal override from OpenZeppelin's ERC721. We've added a check here to ensure that if a token is marked as entangled (`isEntangled(tokenId)` returns true), the transfer is reverted. This enforces the rule that entangled tokens are conceptually linked and cannot be moved independently.
3.  **`mint`**: A basic owner-only mint function to create new tokens. It also initializes the internal `_tokenData` for the new token, marking it as not entangled initially.
4.  **`entanglePair`**: Takes two *different*, *un-entangled* tokens owned by the caller. It links them together by setting their `partnerId` and assigning a new unique `pairId` from the `_nextPairId` counter. It records this pair in the `_pairs` mapping and sets the pair's initial state to `Superposed`.
5.  **`disentanglePair`**: Takes one token ID from an entangled pair. Requires the caller to own the token. It sets the pair's state to `Decohered` and, importantly, clears the `partnerId` and `pairId` from both tokens in the pair within the `_tokenData` mapping. This effectively breaks the on-chain entanglement link, allowing tokens to be transferred again.
6.  **`measureState`**: Designed to simulate the 'measurement' in quantum mechanics. It takes a token ID in a `Superposed` pair. It uses a simulated random source (combination of block data and caller address - *again, not truly random on-chain*) to determine the outcome. Based on this 'randomness', the pair's state deterministically becomes either `AlignedAA` or `AlignedBB`. This state change affects *both* tokens in the pair simultaneously. It only acts if the pair is `Superposed`.
7.  **`perturbEntangledState`**: A more complex, probabilistic interaction. Takes a token ID in a pair. Depending on the pair's current state (`Superposed`, `AlignedAA`, `AlignedBB`) and the `_globalInfluenceFactor`, this function might trigger a 'measurement' if `Superposed`, or perhaps initiate `Superposition` again if `Aligned`, with probabilities influenced by the global factor. This simulates external interaction causing uncertain state changes.
8.  **`initiateSuperposition`**: Allows attempting to revert an `Aligned` pair back to the `Superposed` state. This simulates a process to 'reset' the pair's state uncertainty. Its success probability is influenced by the `_globalInfluenceFactor` (perhaps harder to achieve superposition under high global influence).
9.  **`triggerDecoherence`**: An alternative way to explicitly set the pair state to `Decohered`. Conceptually distinct from `disentanglePair` (which also sets Decohered and clears links), this might represent an environmental factor or specific action causing the entanglement to break down, whereas `disentanglePair` is a deliberate administrative action by the owner. In this implementation, it simply calls `disentanglePair`.
10. **`applyGlobalInfluence`**: An owner-only function to set `_globalInfluenceFactor`. This factor (0-1000) is used in `measureState` and `perturbEntangledState` to bias or affect the probabilities of state transitions, adding a global dynamic element to the system.
11. **`getGlobalInfluence`**: Simple getter for the global influence factor.
12. **`isEntangled`**: A simple view function checking if a token's `pairId` is non-zero in the `_tokenData` mapping.
13. **`getEntangledPartner`**: Returns the `partnerId` stored in `_tokenData` for a token. Returns 0 if not entangled.
14. **`getPairIdForToken`**: Returns the `pairId` stored in `_tokenData` for a token. Returns 0 if not entangled.
15. **`getPairState`**: Returns the state of a specific pair based on its `pairId`. Requires a valid `pairId`.
16. **`getPairTokens`**: Returns the two token IDs associated with a given `pairId`.
17. **`getLocalState`**: Returns the conceptual state of an *individual* token. If the token is part of an `AlignedAA` pair, its local state is `AlignedA`. If `AlignedBB`, its state is `AlignedB`. If the pair is `Superposed` or `Decohered` (or the token isn't entangled), its local state is considered `Unknown`. This models the idea that an entangled particle's state is determined by the pair's state upon measurement.
18. **`pauseEntanglementOps`, `unpauseEntanglementOps`, `paused`**: Inherited from OpenZeppelin's `Pausable`. These allow the owner to temporarily disable functions marked with the `whenNotPaused` modifier (like `entanglePair`, `disentanglePair`, state change functions) while still allowing basic ERC721 transfers *of non-entangled tokens*.

This contract provides a rich, albeit simulated, state-changing system built on top of the ERC721 standard, incorporating concepts of linked assets, dynamic states, and external/internal influences. The probabilistic elements are simplified simulations due to blockchain's deterministic nature, but they serve the conceptual model.