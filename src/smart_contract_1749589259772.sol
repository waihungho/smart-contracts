Okay, this is an exciting challenge! Creating something advanced, creative, trendy, *non-duplicated*, and with 20+ functions requires weaving together several concepts.

Let's imagine a system where NFTs aren't just static images or items, but can be linked in a unique, dynamic way, influencing each other – like a conceptual "Quantum Entanglement" for digital assets.

**Concept: Quantum Entanglement NFTs**

This contract will create ERC-721 tokens that can become "entangled" in pairs. When two tokens are entangled, certain actions performed on one token will *inversely* affect the state of its entangled partner. Breaking the entanglement has consequences. This introduces strategic depth, potential gaming mechanics, or unique digital art interactions.

**Advanced Concepts Used:**

1.  **Dynamic NFT Metadata:** Token metadata (`tokenURI`) will change based on the token's state (entangled, resonance level, etc.).
2.  **Interdependent State:** Tokens have a shared or inversely related state variable ("Resonance") when entangled.
3.  **Configurable Mechanics:** Owner can adjust costs and parameters.
4.  **Batch Operations:** Transferring entangled pairs together.
5.  **Consequential Actions:** Burning one entangled token dramatically affects the other.
6.  **Pausable Features:** Ability to pause specific mechanics (entanglement, resonance changes) for maintenance or upgrades.
7.  **ERC-721 Enumerable:** Provides visibility into all tokens and tokens owned by an address.

---

**Contract Outline:**

1.  **License and Version**
2.  **Imports:** ERC721, Enumerable, Ownable, Pausable, Counters, Strings
3.  **Error Definitions**
4.  **State Variables:**
    *   Counters for token IDs
    *   Mappings for token states (struct)
    *   Mapping for entanglement pairs
    *   Constants (UNENTANGLED state)
    *   Configurable parameters (entanglement cost, max resonance, burn boost factor)
    *   Admin variables (base token URI, max supply)
5.  **Structs:** `TokenState` (resonance, generation, potentially more)
6.  **Events:** Minting, Entanglement, Break Entanglement, Resonance Change, Transfer Pair, Burn Entangled.
7.  **Modifiers:** (Implicit via OpenZeppelin)
8.  **Constructor:** Initializes base URI, admin, etc.
9.  **Internal Helpers:**
    *   `_updateResonanceInternal`: Handles inverse resonance change for a pair.
    *   `_breakEntanglementInternal`: Breaks entanglement without external checks/costs.
10. **Core ERC721 Functions (Inherited/Overridden):**
    *   `supportsInterface`
    *   `tokenURI` (Overridden for dynamic metadata)
    *   `totalSupply` (from Enumerable)
    *   `tokenByIndex` (from Enumerable)
    *   `tokenOfOwnerByIndex` (from Enumerable)
11. **Minting Functions:**
    *   `mintSingle`: Mints a single, unentangled token.
    *   `mintEntangledPair`: Mints two tokens, entangled from creation.
12. **Entanglement Functions:**
    *   `entangle`: Entangle two existing, unentangled tokens (requires payment).
    *   `breakEntanglement`: Break the entanglement of a pair (has consequences).
    *   `getEntangledToken`: Query the paired token ID.
    *   `isEntangled`: Query entanglement status.
13. **Resonance Interaction Functions:**
    *   `increaseResonance`: Increase resonance of a token (affects partner if entangled).
    *   `decreaseResonance`: Decrease resonance of a token (affects partner if entangled).
    *   `getResonance`: Query token's resonance.
14. **Pair Management Functions:**
    *   `transferEntangledPair`: Transfer both tokens of a pair atomically.
    *   `burnEntangledToken`: Burn one token in an entangled pair (significant effect on partner).
15. **Query Functions:**
    *   `getTokenState`: Get the full state of a token.
    *   `getGeneration`: Get the generation of a token.
16. **Admin/Configuration Functions (onlyOwner):**
    *   `setBaseURI`
    *   `setMaxSupply`
    *   `setEntanglementCost`
    *   `setBurnBoostFactor`
    *   `pauseEntanglementChanges`
    *   `unpauseEntanglementChanges`
    *   `pauseResonanceChanges`
    *   `unpauseResonanceChanges`
    *   `withdrawEther`

---

**Function Summary:**

*   `constructor(string memory name, string memory symbol, string memory baseTokenUri)`: Initializes the contract with name, symbol, and base URI.
*   `supportsInterface(bytes4 interfaceId)`: ERC-165 compliance for ERC-721 and ERC-721Enumerable. (Inherited/Overridden)
*   `tokenURI(uint256 tokenId)`: Returns the URI for a token's metadata, dynamically incorporating its state. (Overridden)
*   `totalSupply()`: Returns the total number of tokens minted. (Inherited from Enumerable)
*   `tokenByIndex(uint256 index)`: Returns the token ID at a specific index. (Inherited from Enumerable)
*   `tokenOfOwnerByIndex(address owner, uint256 index)`: Returns a token ID owned by `owner` at a specific index. (Inherited from Enumerable)
*   `mintSingle(address to, uint256 generation)`: Mints a new unentangled token of a specified generation to an address.
*   `mintEntangledPair(address toA, address toB, uint256 generation, uint256 initialResonance)`: Mints two new tokens, entangled with each other, to specified addresses, with initial resonance and generation.
*   `entangle(uint256 tokenId1, uint256 tokenId2)`: Allows the owner of two unentangled tokens to entangle them, requiring payment of the `entanglementCost`. Initializes their shared resonance.
*   `breakEntanglement(uint256 tokenId)`: Breaks the entanglement for the pair containing `tokenId`. Reduces resonance for both tokens as a consequence.
*   `getEntangledToken(uint256 tokenId)`: Returns the token ID that `tokenId` is entangled with, or 0 if unentangled.
*   `isEntangled(uint256 tokenId)`: Returns true if `tokenId` is entangled, false otherwise.
*   `increaseResonance(uint256 tokenId, uint256 amount)`: Increases the resonance of `tokenId`. If entangled, *decreases* the resonance of the paired token inversely. Requires ownership or approval.
*   `decreaseResonance(uint256 tokenId, uint256 amount)`: Decreases the resonance of `tokenId`. If entangled, *increases* the resonance of the paired token inversely. Requires ownership or approval.
*   `getResonance(uint256 tokenId)`: Returns the current resonance level of a token.
*   `transferEntangledPair(uint256 tokenId, address to)`: Transfers both tokens in an entangled pair to a new address atomically. Requires owner/approval for both.
*   `burnEntangledToken(uint256 tokenId)`: Burns `tokenId`. If entangled, the paired token's resonance is significantly boosted, and the entanglement is broken. Requires ownership or approval.
*   `getTokenState(uint256 tokenId)`: Returns the full `TokenState` struct for a token.
*   `getGeneration(uint256 tokenId)`: Returns the generation number of a token.
*   `setBaseURI(string memory baseTokenUri_)`: (Owner) Sets the base URI for token metadata.
*   `setMaxSupply(uint256 maxSupply_)`: (Owner) Sets the maximum total supply of tokens.
*   `setEntanglementCost(uint256 cost)`: (Owner) Sets the Ether cost to entangle two tokens.
*   `setBurnBoostFactor(uint256 factor)`: (Owner) Sets the multiplier for resonance boost when an entangled partner is burned.
*   `pauseEntanglementChanges()`: (Owner) Pauses the `entangle` and `breakEntanglement` functions.
*   `unpauseEntanglementChanges()`: (Owner) Unpauses the entanglement functions.
*   `pauseResonanceChanges()`: (Owner) Pauses `increaseResonance` and `decreaseResonance`.
*   `unpauseResonanceChanges()`: (Owner) Unpauses the resonance functions.
*   `withdrawEther()`: (Owner) Withdraws collected Ether from entanglement fees.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// --- Contract Outline ---
// 1. License and Version
// 2. Imports
// 3. Error Definitions
// 4. State Variables
// 5. Structs
// 6. Events
// 7. Modifiers (Inherited/Implicit)
// 8. Constructor
// 9. Internal Helpers (_updateResonanceInternal, _breakEntanglementInternal)
// 10. Core ERC721 Functions (Inherited/Overridden: supportsInterface, tokenURI, totalSupply, tokenByIndex, tokenOfOwnerByIndex)
// 11. Minting Functions (mintSingle, mintEntangledPair)
// 12. Entanglement Functions (entangle, breakEntanglement, getEntangledToken, isEntangled)
// 13. Resonance Interaction Functions (increaseResonance, decreaseResonance, getResonance)
// 14. Pair Management Functions (transferEntangledPair, burnEntangledToken)
// 15. Query Functions (getTokenState, getGeneration)
// 16. Admin/Configuration Functions (onlyOwner: setBaseURI, setMaxSupply, setEntanglementCost, setBurnBoostFactor, pause/unpause features, withdrawEther)

// --- Function Summary ---
// constructor: Initializes contract with name, symbol, base URI.
// supportsInterface: ERC-165 compliance. (Inherited)
// tokenURI: Returns dynamic metadata URI based on state. (Overridden)
// totalSupply: Total tokens minted. (Enumerable)
// tokenByIndex: Get token ID by index. (Enumerable)
// tokenOfOwnerByIndex: Get token ID by owner and index. (Enumerable)
// mintSingle: Mint a new unentangled token.
// mintEntangledPair: Mint two tokens, entangled from creation.
// entangle: Entangle two existing unentangled tokens (paid).
// breakEntanglement: Break entanglement (with resonance consequence).
// getEntangledToken: Get paired token ID.
// isEntangled: Check entanglement status.
// increaseResonance: Increase token resonance (inverse effect on partner if entangled).
// decreaseResonance: Decrease token resonance (inverse effect on partner if entangled).
// getResonance: Get token's resonance level.
// transferEntangledPair: Transfer both tokens in a pair atomically.
// burnEntangledToken: Burn one entangled token (boosts partner resonance, breaks entanglement).
// getTokenState: Get full token state struct.
// getGeneration: Get token generation.
// setBaseURI: (Owner) Set metadata base URI.
// setMaxSupply: (Owner) Set max token supply.
// setEntanglementCost: (Owner) Set cost to entangle.
// setBurnBoostFactor: (Owner) Set resonance boost factor on burn.
// pauseEntanglementChanges: (Owner) Pause entanglement changes.
// unpauseEntanglementChanges: (Owner) Unpause entanglement changes.
// pauseResonanceChanges: (Owner) Pause resonance changes.
// unpauseResonanceChanges: (Owner) Unpause resonance changes.
// withdrawEther: (Owner) Withdraw collected fees.

contract QuantumEntanglementNFT is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    struct TokenState {
        uint256 resonance; // A measure of some dynamic quality
        uint256 generation; // Batch or version the token was minted in
        // Add more state variables here as needed (e.g., traits, level, etc.)
    }

    mapping(uint256 => TokenState) private _tokenStates;
    mapping(uint256 => uint256) private _entangledPair; // Maps token ID to its entangled partner ID
    uint256 constant UNENTANGLED = 0; // Sentinel value for unentangled tokens

    string private _baseTokenURI;
    uint256 private _maxSupply;

    uint256 private _entanglementCost = 0.01 ether; // Cost to entangle two tokens
    uint256 private _maxResonance = 1000; // Max possible resonance level
    uint256 private _minResonance = 0; // Min possible resonance level

    // Factor by which partner resonance is boosted when one token in a pair is burned
    // e.g., factor 2 means resonance is doubled from its current level, capped at maxResonance
    uint256 private _burnBoostFactor = 2;
    // Resonance loss when entanglement is broken
    uint256 private _breakEntanglementResonanceLoss = 10;

    // --- Error Definitions ---
    error MaxSupplyReached();
    error NotOwnerOrApproved();
    error TokensAlreadyEntangled();
    error TokensNotEntangled();
    error CannotEntangleSelf();
    error CannotEntangleDifferentOwners();
    error InsufficientEntanglementCost();
    error Paused(string reason);
    error ResonanceCapReached();
    error ResonanceFloorReached();
    error OnlyEntangledTokens();
    error CannotTransferUnentangledPair();
    error InvalidTokenId();

    // --- Events ---
    event TokenMinted(uint256 indexed tokenId, address indexed owner, uint256 generation, bool isEntangled);
    event Entangled(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 initialResonance);
    event EntanglementBroken(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 finalResonance1, uint256 finalResonance2);
    event ResonanceChanged(uint256 indexed tokenId, uint256 oldResonance, uint256 newResonance);
    event EntangledPairTransferred(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed from, address indexed to);
    event BurnedEntangled(uint256 indexed burnedTokenId, uint256 indexed partnerTokenId, uint256 partnerBoostedResonance);
    event EntanglementCostUpdated(uint256 newCost);
    event BurnBoostFactorUpdated(uint256 newFactor);
    event BreakResonanceLossUpdated(uint256 newLoss);


    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory baseTokenUri_)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _baseTokenURI = baseTokenUri_;
        _maxSupply = type(uint256).max; // Default to max possible supply
    }

    // --- Internal Helpers ---

    // Safely gets the paired token ID, reverts if token doesn't exist or is unentangled
    function _getPairedToken(uint256 tokenId) internal view returns (uint256) {
        uint256 pairedTokenId = _entangledPair[tokenId];
        if (pairedTokenId == UNENTANGLED) {
             revert TokensNotEntangled();
        }
        // Basic check that the paired token also exists
        if (!_exists(pairedTokenId)) {
             // Should ideally not happen if state is consistent
             revert InvalidTokenId();
        }
        return pairedTokenId;
    }

    // Internal function to update resonance for a token and its entangled partner
    // If `isIncrease` is true, `amount` is added to `tokenId` and subtracted from partner (inverse)
    // If `isIncrease` is false, `amount` is subtracted from `tokenId` and added to partner (inverse)
    function _updateResonanceInternal(uint256 tokenId, uint256 amount, bool isIncrease) internal {
        TokenState storage state = _tokenStates[tokenId];
        uint256 oldResonance = state.resonance;
        uint256 newResonance;

        if (isIncrease) {
            newResonance = state.resonance + amount;
            if (newResonance > _maxResonance) {
                 newResonance = _maxResonance;
            }
        } else { // isDecrease
            newResonance = state.resonance - amount;
            if (newResonance < _minResonance) {
                 newResonance = _minResonance;
            }
        }

        // Prevent changes if the value wouldn't actually change due to caps/floors
        if (newResonance == oldResonance) {
             // No actual change, nothing more to do
             return;
        }

        state.resonance = newResonance;
        emit ResonanceChanged(tokenId, oldResonance, newResonance);

        // If entangled, apply inverse effect to partner
        uint256 pairedTokenId = _entangledPair[tokenId];
        if (pairedTokenId != UNENTANGLED && _exists(pairedTokenId)) {
            TokenState storage partnerState = _tokenStates[pairedTokenId];
            uint256 partnerOldResonance = partnerState.resonance;
            uint256 partnerNewResonance;

            // Inverse effect: If tokenId increased, partner decreases; If tokenId decreased, partner increases.
            if (isIncrease) {
                partnerNewResonance = partnerState.resonance - amount;
                 if (partnerNewResonance < _minResonance) {
                      partnerNewResonance = _minResonance;
                 }
            } else { // isDecrease
                partnerNewResonance = partnerState.resonance + amount;
                if (partnerNewResonance > _maxResonance) {
                    partnerNewResonance = _maxResonance;
                }
            }

             // Prevent changes if the value wouldn't actually change due to caps/floors
            if (partnerNewResonance != partnerOldResonance) {
                partnerState.resonance = partnerNewResonance;
                emit ResonanceChanged(pairedTokenId, partnerOldResonance, partnerNewResonance);
            }
        }
    }

    // Internal function to break entanglement for a pair
    // Assumes validity checks are done by the caller
    function _breakEntanglementInternal(uint256 tokenId1, uint256 tokenId2) internal {
         // Clear mapping from both sides
        _entangledPair[tokenId1] = UNENTANGLED;
        _entangledPair[tokenId2] = UNENTANGLED;

        // Apply resonance loss consequence
        _tokenStates[tokenId1].resonance = (_tokenStates[tokenId1].resonance < _breakEntanglementResonanceLoss) ? _minResonance : _tokenStates[tokenId1].resonance - _breakEntanglementResonanceLoss;
        _tokenStates[tokenId2].resonance = (_tokenStates[tokenId2].resonance < _breakEntanglementResonanceLoss) ? _minResonance : _tokenStates[tokenId2].resonance - _breakEntanglementResonanceLoss;

        emit EntanglementBroken(tokenId1, tokenId2, _tokenStates[tokenId1].resonance, _tokenStates[tokenId2].resonance);
    }

    // --- Core ERC721 Functions (Overridden) ---

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721Enumerable) // Specify overrides if necessary
        returns (string memory)
    {
        if (!_exists(tokenId)) revert ERC721Enumerable.URIQueryForNonexistentToken();

        // Construct dynamic metadata URL
        // This assumes the base URI serves a handler that can return JSON based on token ID
        // Example: https://your.metadata.api/token/123
        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            return "";
        }
        return string(abi.encodePacked(base, tokenId.toString()));

        // Optional: Include state directly in a data URI for simpler cases
        /*
        TokenState memory state = _tokenStates[tokenId];
        uint256 pairedTokenId = _entangledPair[tokenId];
        string memory entangledStatus = pairedTokenId == UNENTANGLED ? "false" : "true";
        string memory pairedIdString = pairedTokenId == UNENTANGLED ? "null" : pairedTokenId.toString();

        string memory json = string(abi.encodePacked(
            '{"name": "QE NFT #', tokenId.toString(), '",',
            '"description": "A Quantum Entanglement NFT.",',
            '"image": "ipfs://YOUR_DEFAULT_IMAGE_CID",', // Placeholder
            '"attributes": [',
            '{"trait_type": "Generation", "value": ', state.generation.toString(), '},',
            '{"trait_type": "Resonance", "value": ', state.resonance.toString(), '},',
            '{"trait_type": "Is Entangled", "value": ', entangledStatus, '}',
            (pairedTokenId != UNENTANGLED ? string(abi.encodePacked(',{"trait_type": "Entangled Partner", "value": ', pairedIdString, '}')) : ""),
            ']}'
        ));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
        // Note: Base64 library is needed for this approach
        // import "@openzeppelin/contracts/utils/Base64.sol";
        // using Base64 for bytes;
        */
    }

    // The following are inherited from ERC721Enumerable and count towards the 20+ function count:
    // - supportsInterface(bytes4 interfaceId)
    // - totalSupply()
    // - tokenByIndex(uint256 index)
    // - tokenOfOwnerByIndex(address owner, uint256 index)

    // Override `_beforeTokenTransfer` to prevent transferring entangled tokens individually
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0) && to != address(0) && _entangledPair[tokenId] != UNENTANGLED) {
            // If transfer is happening, check if it's part of a pair transfer
            // This is tricky to enforce purely in _beforeTokenTransfer without complex state
            // A simpler approach is to *only* allow entangled token transfers via the dedicated transferEntangledPair function
            // Revert if trying to transfer an entangled token using standard transfer methods (transferFrom, safeTransferFrom)
            revert OnlyEntangledTokens(); // Custom error indicates this specific restriction
        }
    }


    // --- Minting Functions ---

    function mintSingle(address to, uint256 generation) public onlyOwner {
        if (_tokenIdCounter.current() >= _maxSupply) revert MaxSupplyReached();

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(to, newItemId);
        _tokenStates[newItemId] = TokenState({
            resonance: 0, // Initial resonance
            generation: generation
        });
        _entangledPair[newItemId] = UNENTANGLED; // Ensure explicitly marked as unentangled

        emit TokenMinted(newItemId, to, generation, false);
    }

    function mintEntangledPair(address toA, address toB, uint256 generation, uint256 initialResonance) public onlyOwner {
        if (_tokenIdCounter.current() + 1 >= _maxSupply) revert MaxSupplyReached(); // Need 2 tokens

        _tokenIdCounter.increment();
        uint256 tokenA = _tokenIdCounter.current();

        _tokenIdCounter.increment();
        uint256 tokenB = _tokenIdCounter.current();

        _safeMint(toA, tokenA);
        _safeMint(toB, tokenB);

        // Ensure initial resonance doesn't exceed max
        uint256 limitedInitialResonance = initialResonance > _maxResonance ? _maxResonance : initialResonance;

        _tokenStates[tokenA] = TokenState({
            resonance: limitedInitialResonance,
            generation: generation
        });
        _tokenStates[tokenB] = TokenState({
            resonance: limitedInitialResonance, // Partners start with same resonance
            generation: generation
        });

        // Set entanglement mapping
        _entangledPair[tokenA] = tokenB;
        _entangledPair[tokenB] = tokenA;

        emit TokenMinted(tokenA, toA, generation, true);
        emit TokenMinted(tokenB, toB, generation, true);
        emit Entangled(tokenA, tokenB, limitedInitialResonance);
    }

    // --- Entanglement Functions ---

    function entangle(uint256 tokenId1, uint256 tokenId2) public payable whenNotPaused {
        if (tokenId1 == tokenId2) revert CannotEntangleSelf();
        if (!_exists(tokenId1) || !_exists(tokenId2)) revert InvalidTokenId();

        // Check if already entangled
        if (_entangledPair[tokenId1] != UNENTANGLED || _entangledPair[tokenId2] != UNENTANGLED) revert TokensAlreadyEntangled();

        // Check ownership: requires sender owns both tokens
        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);
        if (owner1 != msg.sender || owner2 != msg.sender) revert NotOwnerOrApproved(); // Simplified: requires sender owns both

        // Check payment
        if (msg.value < _entanglementCost) revert InsufficientEntanglementCost();

        // Set entanglement mapping
        _entangledPair[tokenId1] = tokenId2;
        _entangledPair[tokenId2] = tokenId1;

        // Determine initial resonance for the new pair
        // Let's average their current resonance
        uint256 initialResonance = (_tokenStates[tokenId1].resonance + _tokenStates[tokenId2].resonance) / 2;
         _tokenStates[tokenId1].resonance = initialResonance;
         _tokenStates[tokenId2].resonance = initialResonance;

        emit Entangled(tokenId1, tokenId2, initialResonance);

        // Refund any excess Ether
        if (msg.value > _entanglementCost) {
            payable(msg.sender).transfer(msg.value - _entanglementCost);
        }
    }

    function breakEntanglement(uint256 tokenId) public whenNotPaused {
        // Check ownership or approval
        if (ownerOf(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender) && getApproved(tokenId) != msg.sender) revert NotOwnerOrApproved();

        uint256 pairedTokenId = _getPairedToken(tokenId); // Reverts if not entangled

        _breakEntanglementInternal(tokenId, pairedTokenId);
    }

    function getEntangledToken(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) revert InvalidTokenId();
        return _entangledPair[tokenId];
    }

    function isEntangled(uint256 tokenId) public view returns (bool) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _entangledPair[tokenId] != UNENTANGLED;
    }

    // --- Resonance Interaction Functions ---

    function increaseResonance(uint256 tokenId, uint256 amount) public whenNotPaused {
        // Check ownership or approval
        if (ownerOf(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender) && getApproved(tokenId) != msg.sender) revert NotOwnerOrApproved();
         if (!_exists(tokenId)) revert InvalidTokenId();

        _updateResonanceInternal(tokenId, amount, true);
    }

    function decreaseResonance(uint256 tokenId, uint256 amount) public whenNotPaused {
         // Check ownership or approval
        if (ownerOf(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender) && getApproved(tokenId) != msg.sender) revert NotOwnerOrApproved();
         if (!_exists(tokenId)) revert InvalidTokenId();

        _updateResonanceInternal(tokenId, amount, false);
    }

    function getResonance(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) revert InvalidTokenId();
        return _tokenStates[tokenId].resonance;
    }

    // --- Pair Management Functions ---

    function transferEntangledPair(uint256 tokenId, address to) public {
        if (!_exists(tokenId)) revert InvalidTokenId();
        uint256 pairedTokenId = _getPairedToken(tokenId); // Reverts if not entangled

        address from = ownerOf(tokenId);
        if (ownerOf(pairedTokenId) != from) {
            // Should not happen if state is consistent and entanglement implies same owner or pair transfer
            revert InvalidTokenId();
        }

        // Check sender is owner or approved for ALL for the 'from' address
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) revert NotOwnerOrApproved();


        // Important: Use the internal _transfer function to bypass the _beforeTokenTransfer check
        // that prevents individual transfers of entangled tokens.
        _transfer(from, to, tokenId);
        _transfer(from, to, pairedTokenId); // Transfer the partner as well

        emit EntangledPairTransferred(tokenId, pairedTokenId, from, to);
    }

    function burnEntangledToken(uint256 tokenId) public {
         // Check ownership or approval
        if (ownerOf(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender) && getApproved(tokenId) != msg.sender) revert NotOwnerOrApproved();
         if (!_exists(tokenId)) revert InvalidTokenId();

        uint256 pairedTokenId = _getPairedToken(tokenId); // Reverts if not entangled

        // Significantly boost partner's resonance
        uint256 partnerOldResonance = _tokenStates[pairedTokenId].resonance;
        uint256 partnerNewResonance = partnerOldResonance * _burnBoostFactor;
        if (partnerNewResonance > _maxResonance) {
             partnerNewResonance = _maxResonance;
        }
        _tokenStates[pairedTokenId].resonance = partnerNewResonance;
        emit ResonanceChanged(pairedTokenId, partnerOldResonance, partnerNewResonance);
        emit BurnedEntangled(tokenId, pairedTokenId, partnerNewResonance);


        // Break the entanglement
        // Use internal helper to avoid re-checking ownership/entanglement and applying breaking costs
        _breakEntanglementInternal(tokenId, pairedTokenId);

        // Burn the token
        _burn(tokenId);

        // Note: The partner token remains, but is now unentangled with boosted resonance.
    }

    // --- Query Functions ---

    function getTokenState(uint256 tokenId) public view returns (TokenState memory) {
         if (!_exists(tokenId)) revert InvalidTokenId();
        return _tokenStates[tokenId];
    }

    function getGeneration(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) revert InvalidTokenId();
        return _tokenStates[tokenId].generation;
    }

    // --- Admin/Configuration Functions (onlyOwner) ---

    function setBaseURI(string memory baseTokenUri_) public onlyOwner {
        _baseTokenURI = baseTokenUri_;
    }

    function setMaxSupply(uint256 maxSupply_) public onlyOwner {
        _maxSupply = maxSupply_;
    }

    function setEntanglementCost(uint256 cost) public onlyOwner {
        _entanglementCost = cost;
        emit EntanglementCostUpdated(cost);
    }

     function setBurnBoostFactor(uint256 factor) public onlyOwner {
        _burnBoostFactor = factor;
        emit BurnBoostFactorUpdated(factor);
    }

     function setBreakEntanglementResonanceLoss(uint256 loss) public onlyOwner {
         _breakEntanglementResonanceLoss = loss;
         emit BreakResonanceLossUpdated(loss);
     }

    function pauseEntanglementChanges() public onlyOwner {
        _pause(); // Pauses all pausable functions (entangle, breakEntanglement, resonance changes)
        // Could have separate pause states if needed, but using OpenZeppelin's simplifies things
        // For this design, let's assume one pause state affects all these mechanics.
        // If we wanted to pause only entanglement, we'd need custom pausable logic per function group.
        // Sticking to standard Pausable.sol means all 'whenNotPaused' functions are affected.
    }

    function unpauseEntanglementChanges() public onlyOwner {
        _unpause(); // Unpauses all pausable functions
    }

     // Alias for pauseEntanglementChanges for clarity, but uses the same underlying pausable state
     function pauseResonanceChanges() public onlyOwner {
         pauseEntanglementChanges();
     }

     // Alias for unpauseEntanglementChanges
     function unpauseResonanceChanges() public onlyOwner {
         unpauseEntanglementChanges();
     }


    function withdrawEther() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // --- View Pausable Status ---
    // OpenZeppelin's Pausable adds `paused()` view function automatically.

    // --- Required overrides for ERC721Enumerable ---
    // These ensure the base ERC721 functions use the Enumerable storage
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

     function _burn(uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._burn(tokenId);
        // Clean up state after burning
        delete _tokenStates[tokenId];
        // Entanglement mapping should already be cleared if burned via burnEntangledToken
        // If burned by owner via base ERC721 burn, _beforeTokenTransfer might catch it,
        // but burnEntangledToken is the intended way to burn entangled tokens.
        // For safety, ensure mapping is cleared regardless of how _burn is called.
        uint256 paired = _entangledPair[tokenId];
        if (paired != UNENTANGLED) {
            _entangledPair[paired] = UNENTANGLED; // Clear partner's mapping
            // Note: This break does *not* apply the breakEntanglement consequences (resonance loss)
            // unless the token was burned via burnEntangledToken.
        }
        delete _entangledPair[tokenId]; // Clear this token's mapping
     }
}
```

**Explanation and Considerations:**

1.  **Uniqueness:** The core mechanism of dynamic, inversely-affected resonance between entangled NFT pairs, controllable entanglement/breakage, and the specific consequence of burning one partner are combined here in a way that differentiates it from standard NFT patterns (generative, fractional, simple staking).
2.  **ERC-721 Enumerable:** Inheriting from `ERC721Enumerable` automatically adds functions like `totalSupply`, `tokenByIndex`, and `tokenOfOwnerByIndex`, helping meet the function count and providing useful chain visibility.
3.  **Dynamic Metadata:** The `tokenURI` function points to a `_baseTokenURI`. A real-world implementation would require an off-chain server/service running at this base URI that dynamically generates JSON metadata for each token ID, including its current resonance, entanglement status, and partner ID.
4.  **State Management:** The `TokenState` struct holds dynamic properties. The `_entangledPair` mapping manages the paired relationship. `UNENTANGLED = 0` is a standard way to represent the absence of a pair in mappings.
5.  **Resonance Mechanics:** `_updateResonanceInternal` is the core logic for resonance changes. It ensures entangled partners are affected inversely and caps/floors are respected. The `increaseResonance` and `decreaseResonance` functions provide the external interface.
6.  **Entanglement Lifecycle:**
    *   Pairs can be minted entangled (`mintEntangledPair`).
    *   Unentangled tokens can become entangled (`entangle`) at a cost, if owned by the same address.
    *   Entanglement can be broken (`breakEntanglement`), resulting in a resonance loss.
7.  **Pair Transfer/Burn:**
    *   A custom `transferEntangledPair` function is needed because the overridden `_beforeTokenTransfer` blocks standard ERC721 transfer calls for entangled tokens. This enforces that entangled tokens must move together.
    *   `burnEntangledToken` provides a specific, dramatic consequence for sacrificing one token in a pair. It boosts the partner's resonance significantly and breaks the link.
8.  **Pausability:** Uses OpenZeppelin's `Pausable` to stop key mechanics (`entangle`, `breakEntanglement`, `increase/decreaseResonance`) via the `whenNotPaused` modifier. This allows the owner to freeze activity for upgrades or maintenance. Note: `pauseEntanglementChanges` and `pauseResonanceChanges` are aliases pointing to the same OpenZeppelin pause/unpause state for simplicity.
9.  **Admin Controls:** Several `onlyOwner` functions allow the contract deployer to configure parameters like costs, boost factors, max supply, and the metadata URI.
10. **Error Handling:** Uses Solidity 0.8+ `revert` with custom errors for clearer debugging and gas efficiency compared to older `require` strings.
11. **Function Count:** We have significantly more than 20 functions, including the inherited ones from ERC721Enumerable and Ownable/Pausable base contracts which are part of the contract's interface and functionality.

This contract provides a foundation for a unique NFT system with dynamic interactions, going beyond simple ownership and transfer. It would be suitable for a game, interactive art project, or experimental digital collection.