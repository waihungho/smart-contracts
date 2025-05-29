Okay, here is a Solidity smart contract for a concept I'll call "Quantum Entangled NFTs". The idea is that some NFTs are minted in pairs and are linked ("entangled"). Actions on one NFT in an entangled pair can affect its partner, potentially changing its state or properties. The entanglement can be broken ("decohered") and potentially re-established. There are different states, properties, and interactions unique to this contract.

This design aims to be creative by introducing linked state/property dynamics between specific tokens, and avoids simply replicating standard ERC features or common patterns found in basic NFT projects (like just minting, transferring, burning, and static metadata). The transfer restrictions based on entanglement status are also a non-standard feature.

---

**Contract Name:** `QuantumEntangledNFT`

**Concept:** A non-fungible token contract where tokens can be minted as single, independent units, or as "entangled" pairs. Entangled tokens have linked states and properties, allowing actions on one to influence the other. Entanglement can be broken (Decohered) and potentially re-established.

**Core Mechanics:**
1.  **Minting:** Can mint single tokens or entangled pairs.
2.  **Entanglement:** A mapping links tokens in a pair. Only applies to pairs minted as such or explicitly re-entangled.
3.  **States:** Tokens have states (e.g., Quiescent, Activated, Decohered). State changes on one entangled token can affect its partner based on specific rules.
4.  **Properties:** Tokens have dynamic properties (e.g., Power, Resilience) that can be boosted or decay, potentially affecting their entangled partner.
5.  **Interaction Functions:** Functions to change state, boost properties, decay properties, decohere, and re-entangle.
6.  **Transfer Restrictions:** Entangled tokens (that are not Decohered) *cannot* be transferred individually. They must be transferred as a pair using a dedicated function. Decohered or single tokens can be transferred normally (via ERC721 standard).
7.  **Combining:** Decohered NFTs can be combined (burned) to create a new, single, non-entangled NFT with properties derived from the combined tokens.
8.  **Staking:** Entangled *Activated* pairs can be "staked" (a state change mechanism, no actual rewards implemented here).

**Function Summary:**

*   **ERC721 Standard Overrides (Modified for Entanglement Logic):**
    *   `balanceOf(address owner)`: Returns the count of tokens owned by an address.
    *   `ownerOf(uint256 tokenId)`: Returns the owner of a token.
    *   `approve(address to, uint256 tokenId)`: Approves an address to transfer a token.
    *   `getApproved(uint256 tokenId)`: Returns the approved address for a token.
    *   `setApprovalForAll(address operator, bool approved)`: Sets approval for an operator for all tokens.
    *   `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all tokens.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfers a token (restricted for entangled, non-decohered).
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer (restricted).
    *   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer with data (restricted).
    *   `supportsInterface(bytes4 interfaceId)`: Indicates supported interfaces (ERC165, ERC721).
    *   `tokenURI(uint256 tokenId)`: Returns metadata URI (can be dynamic based on state/properties).

*   **Custom Minting & Entanglement:**
    *   `mintEntangledPair(address to1, address to2)`: Mints two new tokens and links them as an entangled pair.
    *   `mintSingle(address to)`: Mints a single, non-entangled token.
    *   `transferPair(address from, address to, uint256 tokenId1, uint256 tokenId2)`: Transfers *both* tokens of an entangled pair (requires owning both).

*   **State Management:**
    *   `activate(uint256 tokenId)`: Attempts to activate a token; affects entangled partner based on rules.
    *   `deactivate(uint256 tokenId)`: Attempts to deactivate a token; affects entangled partner based on rules.
    *   `decohore(uint256 tokenId)`: Forces a token and its partner into the Decohered state, breaking entanglement until potentially re-established.
    *   `reEntangle(uint256 tokenId1, uint256 tokenId2)`: Re-establishes entanglement between two Decohered tokens owned by the same person.
    *   `stakePair(uint256 tokenId1, uint256 tokenId2)`: Marks an *Activated*, entangled pair as staked.
    *   `unstakePair(uint256 tokenId1, uint256 tokenId2)`: Unstakes a staked pair.

*   **Property Interaction:**
    *   `boostPower(uint256 tokenId)`: Increases a token's Power property; potentially affects partner.
    *   `reinforceResilience(uint256 tokenId)`: Increases a token's Resilience property; potentially affects partner.
    *   `decayProperties(uint256 tokenId)`: Decreases properties over time or based on conditions (example implementation).

*   **Query Functions:**
    *   `getEntangledPartner(uint256 tokenId)`: Returns the token ID of the entangled partner (0 if none).
    *   `getState(uint256 tokenId)`: Returns the current state of the token.
    *   `getPower(uint256 tokenId)`: Returns the Power property value.
    *   `getResilience(uint256 tokenId)`: Returns the Resilience property value.
    *   `isEntangled(uint256 tokenId)`: Checks if a token is currently linked in an entangled pair.
    *   `canTransfer(uint256 tokenId)`: Internal helper to check if a single token is allowed to be transferred.
    *   `isStaked(uint256 tokenId)`: Checks if a token is currently staked (part of a staked pair).

*   **Other Mechanics:**
    *   `combineDecohered(uint256 tokenId1, uint256 tokenId2)`: Burns two Decohered NFTs and mints a new, single, non-entangled NFT.
    *   `burn(uint256 tokenId)`: Burns a token; affects its partner if entangled.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ERC165.sol";

// Contract Name: QuantumEntangledNFT
// Concept: A non-fungible token contract where tokens can be minted as single,
// independent units, or as "entangled" pairs. Entangled tokens have linked
// states and properties, allowing actions on one to influence the other.
// Entanglement can be broken (Decohered) and potentially re-established.
// Aims for creativity through linked state/property dynamics and custom transfer logic.

// Core Mechanics:
// - Minting: Single or entangled pairs.
// - Entanglement: Linked pairs with reciprocal effects.
// - States: Quiescent, Activated, Decohered.
// - Properties: Dynamic values like Power, Resilience.
// - Interaction Functions: Activate, Deactivate, Decohere, ReEntangle, Boost, Reinforce, Decay.
// - Transfer Restrictions: Entangled, non-Decohered tokens cannot be transferred alone.
// - Combining: Decohered tokens can be burned to create a new, single token.
// - Staking: Activated entangled pairs can be staked (mechanism only, no rewards).

// Function Summary:
// - ERC721 Overrides: balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll,
//   transferFrom, safeTransferFrom (x2), supportsInterface, tokenURI (dynamic).
// - Custom Minting/Entanglement: mintEntangledPair, mintSingle, transferPair.
// - State Management: activate, deactivate, decohore, reEntangle, stakePair, unstakePair.
// - Property Interaction: boostPower, reinforceResilience, decayProperties.
// - Query Functions: getEntangledPartner, getState, getPower, getResilience, isEntangled, canTransfer (internal), isStaked.
// - Other Mechanics: combineDecohered, burn.

contract QuantumEntangledNFT is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    enum TokenState { Quiescent, Activated, Decohered }

    // --- State Variables ---

    // Link entangled tokens: token ID -> paired token ID (0 if not entangled)
    mapping(uint256 => uint256) private _pairedToken;

    // Current state of each token
    mapping(uint256 => TokenState) private _tokenState;

    // Dynamic properties
    mapping(uint256 => uint256) private _tokenPower;
    mapping(uint256 => uint256) private _tokenResilience;

    // Staking status (true if part of a staked pair)
    mapping(uint256 => bool) private _isStaked;

    // Base URI for metadata - actual metadata should reflect state/properties
    string private _baseTokenURI;

    // --- Constants ---
    uint256 public constant INITIAL_POWER = 10;
    uint256 public constant INITIAL_RESILIENCE = 5;
    uint256 public constant BOOST_AMOUNT = 5;
    uint256 public constant DECAY_AMOUNT = 1;

    // --- Events ---
    event MintedEntangledPair(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed owner1, address indexed owner2);
    event MintedSingle(uint256 indexed tokenId, address indexed owner);
    event StateChanged(uint256 indexed tokenId, TokenState newState, TokenState oldState);
    event PropertiesBoosted(uint256 indexed tokenId, uint256 newPower, uint256 newResilience);
    event PropertiesDecayed(uint256 indexed tokenId, uint256 newPower, uint256 newResilience);
    event Decohered(uint256 indexed tokenId1, uint256 indexed tokenId2); // Emitted for both when entanglement breaks
    event ReEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event PairStaked(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event PairUnstaked(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event CombinedDecohered(uint256 indexed burnedTokenId1, uint256 indexed burnedTokenId2, uint256 indexed newTokenId);

    // --- Constructor ---

    constructor(string memory name, string memory symbol, string memory baseTokenURI_)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _baseTokenURI = baseTokenURI_;
    }

    // --- Internal Helper Functions ---

    function _updateState(uint256 tokenId, TokenState newState) internal {
        TokenState oldState = _tokenState[tokenId];
        if (oldState != newState) {
            _tokenState[tokenId] = newState;
            emit StateChanged(tokenId, newState, oldState);
        }
    }

    function _updateProperties(uint256 tokenId, uint256 newPower, uint256 newResilience) internal {
         _tokenPower[tokenId] = newPower;
         _tokenResilience[tokenId] = newResilience;
         emit PropertiesBoosted(tokenId, newPower, newResilience); // Using Boosted event for any property change for simplicity
    }

    // Internal check if a single token is transferable via standard ERC721 methods
    function canTransfer(uint256 tokenId) internal view returns (bool) {
        uint256 pairedTokenId = _pairedToken[tokenId];
        if (pairedTokenId == 0) {
            // Not entangled, always transferable
            return true;
        } else {
            // Entangled, only transferable if Decohered
            return _tokenState[tokenId] == TokenState.Decohered && _tokenState[pairedTokenId] == TokenState.Decohered;
        }
    }

    // Custom _beforeTokenTransfer to enforce entanglement rules
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent single transfer of entangled, non-decohered tokens
        // This hook is called for each token in a potential batch (batchSize usually 1 for single transfers)
        if (batchSize == 1 && from != address(0) && to != address(0)) { // Not minting or burning
             require(canTransfer(tokenId), "QENFT: Entangled tokens must be transferred as a pair or be Decohered");
        }

        // If burning an entangled token, its partner becomes Decohered and link is broken
        if (to == address(0) && _pairedToken[tokenId] != 0) {
             uint256 pairedTokenId = _pairedToken[tokenId];
             // Only update if the partner still exists
             if (_exists(pairedTokenId)) {
                 _updateState(pairedTokenId, TokenState.Decohered);
                 _pairedToken[pairedTokenId] = 0; // Break partner's link
                 emit Decohered(tokenId, pairedTokenId); // Emitted on burn for the pair
             }
             _pairedToken[tokenId] = 0; // Break the burned token's link
        }

         // If transferring a staked token (should only happen via transferPair), unstake it
         if (_isStaked[tokenId]) {
              uint256 pairedTokenId = _pairedToken[tokenId];
               if (_exists(pairedTokenId) && _isStaked[pairedTokenId]) {
                    // Assume transferPair handles unstaking the pair
                    // If this is reached via standard transferFrom, it indicates an issue or bypass
                    // The canTransfer check should prevent this for entangled, non-decohered
                    // For decohered, unstaking might be desired anyway on transfer
                   _isStaked[tokenId] = false;
                   _isStaked[pairedTokenId] = false; // Unstake partner too if it still exists and was staked
               } else {
                   // Should not happen if isStaked implies being part of a staked pair
                   _isStaked[tokenId] = false;
               }
         }
    }


    // --- View Functions ---

    // 1. balanceOf (Override)
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return super.balanceOf(owner);
    }

    // 2. ownerOf (Override)
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return super.ownerOf(tokenId);
    }

    // 3. getApproved (Override)
    function getApproved(uint256 tokenId) public view override returns (address) {
        return super.getApproved(tokenId);
    }

    // 4. isApprovedForAll (Override)
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return super.isApprovedForAll(owner, operator);
    }

    // 5. supportsInterface (Override)
     function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC165).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    // 6. tokenURI (Override)
    // Note: A real implementation would use _baseTokenURI to point to a service
    // that generates dynamic JSON metadata based on the token's state and properties.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Placeholder: In reality, append token ID and have a service resolve it
        // e.g., string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId), "/", Strings.toString(uint8(_tokenState[tokenId]))));
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
    }

    // 7. getEntangledPartner
    function getEntangledPartner(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "QENFT: query for nonexistent token");
        return _pairedToken[tokenId];
    }

    // 8. getState
    function getState(uint256 tokenId) public view returns (TokenState) {
        require(_exists(tokenId), "QENFT: query for nonexistent token");
        return _tokenState[tokenId];
    }

    // 9. getPower
    function getPower(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "QENFT: query for nonexistent token");
         return _tokenPower[tokenId];
    }

    // 10. getResilience
    function getResilience(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "QENFT: query for nonexistent token");
        return _tokenResilience[tokenId];
    }

    // 11. isEntangled
    function isEntangled(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "QENFT: query for nonexistent token");
        return _pairedToken[tokenId] != 0;
    }

     // 12. isStaked
     function isStaked(uint256 tokenId) public view returns (bool) {
         require(_exists(tokenId), "QENFT: query for nonexistent token");
         return _isStaked[tokenId];
     }


    // --- Transaction Functions ---

    // 13. mintEntangledPair (Owner Only)
    function mintEntangledPair(address to1, address to2) public onlyOwner returns (uint256 tokenId1, uint256 tokenId2) {
        _tokenIdCounter.increment();
        tokenId1 = _tokenIdCounter.current();
        _safeMint(to1, tokenId1);
        _updateState(tokenId1, TokenState.Quiescent);
        _tokenPower[tokenId1] = INITIAL_POWER;
        _tokenResilience[tokenId1] = INITIAL_RESILIENCE;

        _tokenIdCounter.increment();
        tokenId2 = _tokenIdCounter.current();
        _safeMint(to2, tokenId2);
        _updateState(tokenId2, TokenState.Quiescent);
        _tokenPower[tokenId2] = INITIAL_POWER;
        _tokenResilience[tokenId2] = INITIAL_RESILIENCE;

        // Establish entanglement link
        _pairedToken[tokenId1] = tokenId2;
        _pairedToken[tokenId2] = tokenId1;

        emit MintedEntangledPair(tokenId1, tokenId2, to1, to2);
    }

    // 14. mintSingle (Owner Only)
    function mintSingle(address to) public onlyOwner returns (uint256 tokenId) {
        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _updateState(tokenId, TokenState.Quiescent); // Single tokens start Quiescent
        _tokenPower[tokenId] = INITIAL_POWER; // Singles also have properties
        _tokenResilience[tokenId] = INITIAL_RESILIENCE;
        // _pairedToken[tokenId] remains 0

        emit MintedSingle(tokenId, to);
    }

    // 15. transferFrom (Override - Restricted)
    // This function will rely on the _beforeTokenTransfer hook for the core transfer restriction logic.
    // Calling the standard super.transferFrom will trigger that hook.
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(canTransfer(tokenId), "QENFT: Entangled tokens must be transferred as a pair or be Decohered");
        super.transferFrom(from, to, tokenId);
    }

    // 16. safeTransferFrom (Override - Restricted)
     function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        require(canTransfer(tokenId), "QENFT: Entangled tokens must be transferred as a pair or be Decohered");
        super.safeTransferFrom(from, to, tokenId);
    }

    // 17. safeTransferFrom (Override - Restricted)
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(canTransfer(tokenId), "QENFT: Entangled tokens must be transferred as a pair or be Decohered");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // 18. transferPair
    // Custom function to transfer both NFTs in an entangled pair simultaneously.
    function transferPair(address from, address to, uint256 tokenId1, uint256 tokenId2) public {
        require(_exists(tokenId1), "QENFT: token 1 nonexistent");
        require(_exists(tokenId2), "QENFT: token 2 nonexistent");
        require(ownerOf(tokenId1) == from && ownerOf(tokenId2) == from, "QENFT: Sender must own both tokens");
        require(_pairedToken[tokenId1] == tokenId2 && _pairedToken[tokenId2] == tokenId1, "QENFT: Tokens are not a valid entangled pair");
        require(_tokenState[tokenId1] != TokenState.Decohered && _tokenState[tokenId2] != TokenState.Decohered, "QENFT: Cannot transfer pair if either token is Decohered");
        require(!_isStaked[tokenId1] && !_isStaked[tokenId2], "QENFT: Cannot transfer a staked pair");

        // ERC721 standard transfer logic handles approvals/operator checks if needed,
        // but since the sender == from, it implies owner initiated or approved operator is calling.
        // Let's just use the internal _transfer
        _transfer(from, to, tokenId1);
        _transfer(from, to, tokenId2);
        // _beforeTokenTransfer hook will not trigger the canTransfer check here
        // because 'from' and 'to' are not address(0) AND batchSize is 1 for each individual transfer.
        // The canTransfer check is specifically for preventing single transfers of *entangled* tokens.
        // Transferring a pair is explicitly allowed by this function.
    }

    // 19. activate
    function activate(uint256 tokenId) public {
        require(_exists(tokenId), "QENFT: activate on nonexistent token");
        require(ownerOf(tokenId) == msg.sender || isApprovedForAll(ownerOf(tokenId), msg.sender), "QENFT: Caller is not owner nor approved");
        require(_tokenState[tokenId] != TokenState.Activated, "QENFT: Token is already Activated");
        require(!_isStaked[tokenId], "QENFT: Cannot activate a staked token");

        uint256 pairedTokenId = _pairedToken[tokenId];

        if (pairedTokenId == 0) {
            // Single token: just activate
            _updateState(tokenId, TokenState.Activated);
        } else {
             // Entangled token: state change depends on partner
             require(_exists(pairedTokenId), "QENFT: Entangled partner nonexistent"); // Should not happen if entanglement is valid
             TokenState partnerState = _tokenState[pairedTokenId];

             if (partnerState == TokenState.Quiescent) {
                 // Both become Activated
                 _updateState(tokenId, TokenState.Activated);
                 _updateState(pairedTokenId, TokenState.Activated);
             } else if (partnerState == TokenState.Activated) {
                 // Both remain Activated (already are)
                 _updateState(tokenId, TokenState.Activated); // Explicitly update for event/consistency
             } else { // partnerState == TokenState.Decohered
                 // Caller activates their token, partner remains Decohered
                 _updateState(tokenId, TokenState.Activated);
             }
        }
    }

    // 20. deactivate
    function deactivate(uint256 tokenId) public {
        require(_exists(tokenId), "QENFT: deactivate on nonexistent token");
        require(ownerOf(tokenId) == msg.sender || isApprovedForAll(ownerOf(tokenId), msg.sender), "QENFT: Caller is not owner nor approved");
        require(_tokenState[tokenId] != TokenState.Quiescent && _tokenState[tokenId] != TokenState.Decohered, "QENFT: Token is already Quiescent or Decohered"); // Can only deactivate from Activated
        require(!_isStaked[tokenId], "QENFT: Cannot deactivate a staked token");


        uint256 pairedTokenId = _pairedToken[tokenId];

        if (pairedTokenId == 0) {
            // Single token: just deactivate
            _updateState(tokenId, TokenState.Quiescent);
        } else {
             // Entangled token: state change depends on partner
             require(_exists(pairedTokenId), "QENFT: Entangled partner nonexistent");
             TokenState partnerState = _tokenState[pairedTokenId];

             if (partnerState == TokenState.Activated) {
                 // Both become Quiescent
                 _updateState(tokenId, TokenState.Quiescent);
                 _updateState(pairedTokenId, TokenState.Quiescent);
             } else if (partnerState == TokenState.Quiescent) {
                 // Both remain Quiescent (already are, shouldn't happen if caller is Activated)
                 _updateState(tokenId, TokenState.Quiescent); // Explicitly update for event/consistency
             } else { // partnerState == TokenState.Decohered
                 // Caller deactivates their token, partner remains Decohered
                 _updateState(tokenId, TokenState.Quiescent);
             }
        }
    }

    // 21. decohore
    // Force breakdown of entanglement. Can be used strategically or as a consequence.
    function decohore(uint256 tokenId) public {
        require(_exists(tokenId), "QENFT: decohore on nonexistent token");
        require(ownerOf(tokenId) == msg.sender || isApprovedForAll(ownerOf(tokenId), msg.sender), "QENFT: Caller is not owner nor approved");
        require(_pairedToken[tokenId] != 0, "QENFT: Token is not entangled");
        require(_tokenState[tokenId] != TokenState.Decohered, "QENFT: Token is already Decohered");
        require(!_isStaked[tokenId], "QENFT: Cannot decohore a staked token");

        uint256 pairedTokenId = _pairedToken[tokenId];
        require(_exists(pairedTokenId), "QENFT: Entangled partner nonexistent"); // Should not happen

        // Both become Decohered
        _updateState(tokenId, TokenState.Decohered);
        _updateState(pairedTokenId, TokenState.Decohered);

        // Remove entanglement link
        _pairedToken[tokenId] = 0;
        _pairedToken[pairedTokenId] = 0;

        emit Decohered(tokenId, pairedTokenId);
    }

    // 22. reEntangle
    // Re-establish entanglement between two Decohered tokens owned by the same address.
    function reEntangle(uint256 tokenId1, uint256 tokenId2) public {
        require(_exists(tokenId1), "QENFT: token 1 nonexistent");
        require(_exists(tokenId2), "QENFT: token 2 nonexistent");
        require(tokenId1 != tokenId2, "QENFT: Cannot re-entangle token with itself");
        require(ownerOf(tokenId1) == msg.sender && ownerOf(tokenId2) == msg.sender, "QENFT: Caller must own both tokens");
        require(_tokenState[tokenId1] == TokenState.Decohered && _tokenState[tokenId2] == TokenState.Decohered, "QENFT: Both tokens must be Decohered");
        require(_pairedToken[tokenId1] == 0 && _pairedToken[tokenId2] == 0, "QENFT: Tokens must not be currently entangled");
         require(!_isStaked[tokenId1] && !_isStaked[tokenId2], "QENFT: Cannot re-entangle staked tokens");


        // Establish entanglement link
        _pairedToken[tokenId1] = tokenId2;
        _pairedToken[tokenId2] = tokenId1;

        // Reset state to Quiescent upon successful re-entanglement
        _updateState(tokenId1, TokenState.Quiescent);
        _updateState(tokenId2, TokenState.Quiescent);

        emit ReEntangled(tokenId1, tokenId2);
    }

    // 23. boostPower
    // Increases the Power property. Affects partner if entangled and in certain states.
    function boostPower(uint256 tokenId) public {
        require(_exists(tokenId), "QENFT: boost on nonexistent token");
        require(ownerOf(tokenId) == msg.sender || isApprovedForAll(ownerOf(tokenId), msg.sender), "QENFT: Caller is not owner nor approved");
        require(!_isStaked[tokenId], "QENFT: Cannot boost staked token");

        _tokenPower[tokenId] += BOOST_AMOUNT;
        emit PropertiesBoosted(tokenId, _tokenPower[tokenId], _tokenResilience[tokenId]);

        uint256 pairedTokenId = _pairedToken[tokenId];
        if (pairedTokenId != 0 && _exists(pairedTokenId)) {
             // Example entanglement effect: If both are Activated, partner also gets a smaller boost
             if (_tokenState[tokenId] == TokenState.Activated && _tokenState[pairedTokenId] == TokenState.Activated) {
                  _tokenPower[pairedTokenId] += BOOST_AMOUNT / 2;
                  emit PropertiesBoosted(pairedTokenId, _tokenPower[pairedTokenId], _tokenResilience[pairedTokenId]);
             }
        }
    }

    // 24. reinforceResilience
    // Increases the Resilience property. Affects partner if entangled and in certain states.
    function reinforceResilience(uint256 tokenId) public {
        require(_exists(tokenId), "QENFT: reinforce on nonexistent token");
        require(ownerOf(tokenId) == msg.sender || isApprovedForAll(ownerOf(tokenId), msg.sender), "QENFT: Caller is not owner nor approved");
        require(!_isStaked[tokenId], "QENFT: Cannot reinforce staked token");

        _tokenResilience[tokenId] += BOOST_AMOUNT;
        emit PropertiesBoosted(tokenId, _tokenPower[tokenId], _tokenResilience[tokenId]);

        uint256 pairedTokenId = _pairedToken[tokenId];
        if (pairedTokenId != 0 && _exists(pairedTokenId)) {
             // Example entanglement effect: If one is Activated and partner is Quiescent, transfer some resilience
              if (_tokenState[tokenId] == TokenState.Activated && _tokenState[pairedTokenId] == TokenState.Quiescent) {
                  uint256 transferAmount = BOOST_AMOUNT / 2;
                  if (_tokenResilience[tokenId] >= transferAmount) {
                       _tokenResilience[tokenId] -= transferAmount; // Cost to transfer
                       _tokenResilience[pairedTokenId] += transferAmount; // Partner gains
                       emit PropertiesDecayed(tokenId, _tokenPower[tokenId], _tokenResilience[tokenId]); // Decay on self
                       emit PropertiesBoosted(pairedTokenId, _tokenPower[pairedTokenId], _tokenResilience[pairedTokenId]); // Boost on partner
                  }
             }
        }
    }

     // 25. decayProperties
     // Simulates property decay. Could be called manually, or via other functions.
     function decayProperties(uint256 tokenId) public {
        require(_exists(tokenId), "QENFT: decay on nonexistent token");
        // Allow anyone to call this for simulation purposes, or add access control
        // require(ownerOf(tokenId) == msg.sender || isApprovedForAll(ownerOf(tokenId), msg.sender), "QENFT: Caller is not owner nor approved");

        uint256 currentPower = _tokenPower[tokenId];
        uint256 currentResilience = _tokenResilience[tokenId];

        if (currentPower >= DECAY_AMOUNT) _tokenPower[tokenId] -= DECAY_AMOUNT;
        else _tokenPower[tokenId] = 0;

        if (currentResilience >= DECAY_AMOUNT) _tokenResilience[tokenId] -= DECAY_AMOUNT;
        else _tokenResilience[tokenId] = 0;

         emit PropertiesDecayed(tokenId, _tokenPower[tokenId], _tokenResilience[tokenId]);

         // Example: If entangled and Decohered, partner decays faster
         uint256 pairedTokenId = _pairedToken[tokenId];
         if (pairedTokenId != 0 && _exists(pairedTokenId) && _tokenState[tokenId] == TokenState.Decohered && _tokenState[pairedTokenId] == TokenState.Decohered) {
             uint256 partnerPower = _tokenPower[pairedTokenId];
             uint256 partnerResilience = _tokenResilience[pairedTokenId];

             if (partnerPower >= DECAY_AMOUNT) _tokenPower[pairedTokenId] -= DECAY_AMOUNT; // Double decay
             else _tokenPower[pairedTokenId] = 0;

             if (partnerResilience >= DECAY_AMOUNT) _tokenResilience[pairedTokenId] -= DECAY_AMOUNT; // Double decay
             else _tokenResilience[pairedTokenId] = 0;

             emit PropertiesDecayed(pairedTokenId, _tokenPower[pairedTokenId], _tokenResilience[pairedTokenId]);
         }
     }


    // 26. combineDecohered
    // Burn two Decohered NFTs and mint a new, single one with combined properties.
    function combineDecohered(uint256 tokenId1, uint256 tokenId2) public returns (uint256 newTokenId) {
        require(_exists(tokenId1), "QENFT: token 1 nonexistent");
        require(_exists(tokenId2), "QENFT: token 2 nonexistent");
        require(tokenId1 != tokenId2, "QENFT: Cannot combine token with itself");
        require(ownerOf(tokenId1) == msg.sender && ownerOf(tokenId2) == msg.sender, "QENFT: Caller must own both tokens");
        require(_tokenState[tokenId1] == TokenState.Decohered && _tokenState[tokenId2] == TokenState.Decohered, "QENFT: Both tokens must be Decohered to combine");
        require(_pairedToken[tokenId1] == 0 && _pairedToken[tokenId2] == 0, "QENFT: Tokens must not be currently entangled"); // Should be true if Decohered

        // Calculate properties for the new token
        uint256 newPower = _tokenPower[tokenId1] + _tokenPower[tokenId2];
        uint256 newResilience = _tokenResilience[tokenId1] + _tokenResilience[tokenId2];

        // Burn the two source tokens
        _burn(tokenId1); // _beforeTokenTransfer handles partner de-linking if necessary (already Decohered here)
        _burn(tokenId2); // _beforeTokenTransfer handles partner de-linking

        // Mint a new single token to the sender
        _tokenIdCounter.increment();
        newTokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, newTokenId);
        _updateState(newTokenId, TokenState.Quiescent); // New token starts Quiescent
        _tokenPower[newTokenId] = newPower;
        _tokenResilience[newTokenId] = newResilience;
        // _pairedToken[newTokenId] remains 0

        emit CombinedDecohered(tokenId1, tokenId2, newTokenId);
    }


    // 27. stakePair
    // Mark an Entangled, Activated pair as staked. No reward mechanics here.
    function stakePair(uint256 tokenId1, uint256 tokenId2) public {
         require(_exists(tokenId1), "QENFT: token 1 nonexistent");
         require(_exists(tokenId2), "QENFT: token 2 nonexistent");
         require(tokenId1 != tokenId2, "QENFT: Cannot stake token alone or with itself");
         require(ownerOf(tokenId1) == msg.sender && ownerOf(tokenId2) == msg.sender, "QENFT: Caller must own both tokens");
         require(_pairedToken[tokenId1] == tokenId2 && _pairedToken[tokenId2] == tokenId1, "QENFT: Tokens are not a valid entangled pair");
         require(_tokenState[tokenId1] == TokenState.Activated && _tokenState[tokenId2] == TokenState.Activated, "QENFT: Both tokens must be Activated to stake");
         require(!_isStaked[tokenId1] && !_isStaked[tokenId2], "QENFT: Pair is already staked");

         _isStaked[tokenId1] = true;
         _isStaked[tokenId2] = true;

         emit PairStaked(tokenId1, tokenId2);
    }

     // 28. unstakePair
    function unstakePair(uint256 tokenId1, uint256 tokenId2) public {
         require(_exists(tokenId1), "QENFT: token 1 nonexistent");
         require(_exists(tokenId2), "QENFT: token 2 nonexistent");
         require(tokenId1 != tokenId2, "QENFT: Invalid token IDs");
         require(ownerOf(tokenId1) == msg.sender && ownerOf(tokenId2) == msg.sender, "QENFT: Caller must own both tokens");
         // Note: We don't require them to still be entangled or Activated to *unstake*,
         // allowing unstaking even if something happened to their state/link while staked.
         // However, a typical system would prevent state changes while staked.
         require(_isStaked[tokenId1] && _isStaked[tokenId2], "QENFT: Pair is not staked");


         _isStaked[tokenId1] = false;
         _isStaked[tokenId2] = false;

         emit PairUnstaked(tokenId1, tokenId2);
    }

     // 29. burn
     // Burn a token. If entangled, its partner becomes Decohered.
     // _beforeTokenTransfer handles the partner logic.
    function burn(uint256 tokenId) public {
        require(_exists(tokenId), "ERC721: burn of nonexistent token");
        require(ownerOf(tokenId) == msg.sender || isApprovedForAll(ownerOf(tokenId), msg.sender), "ERC721: caller is not token owner or approved");
        require(!_isStaked[tokenId], "QENFT: Cannot burn a staked token");

        _burn(tokenId);
        // _beforeTokenTransfer hook handles updating the partner's state and link if it existed.
    }


    // 30. setBaseTokenURI (Owner Only)
    function setBaseTokenURI(string memory baseTokenURI_) public onlyOwner {
        _baseTokenURI = baseTokenURI_;
    }
}
```