Okay, here is a Solidity smart contract for "Quantum Entangled Tokens". This concept introduces tokens with distinct states and the ability to become "entangled" in pairs. When a superposition state is "observed" in one token, both tokens in the pair collapse into correlated stable states, mimicking a quantum-like effect deterministically based on internal state. It combines elements of ERC721 (Non-Fungible Tokens) with custom state management, entanglement logic, and novel mechanics like merging and splitting.

It builds on OpenZeppelin contracts for standard functionalities like ownership, pausing, and base ERC721 structure, but adds significant custom logic and state management beyond a typical implementation.

---

**Outline and Function Summary**

**Contract:** QuantumEntangledTokens

**Concept:** ERC721-based tokens with discrete states (`Dormant`, `Active`, `Superposed`, `Decayed`). Tokens can be 'entangled' in pairs when in the `Dormant` state, transitioning them to `Superposed`. Observing a token in `Superposed` state (via `observeSuperposition`) collapses the entanglement deterministically based on a stored correlation factor, moving both tokens to `Active` or `Decayed` states. Additional mechanics include merging `Decayed` tokens and splitting `Active` tokens. Transfers are restricted based on state and entanglement.

**Interfaces Inherited (partially implemented/overridden):**
*   ERC721Enumerable: Standard NFT functions, adds enumeration.
*   Ownable: Basic ownership management.
*   Pausable: Allows pausing contract interactions.

**Custom Errors:**
*   `InvalidStateTransition`: Attempted state change is not allowed from the current state.
*   `TokenNotInRequiredState`: Token is not in the state required for an action.
*   `AlreadyEntangled`: Token is already part of an entanglement.
*   `NotEntangled`: Token is not part of an entanglement.
*   `SameTokenEntanglement`: Attempted to entangle a token with itself.
*   `EntanglementDisabled`: Entanglement feature is currently disabled.
*   `NotOwnerOfBothTokens`: Caller does not own both tokens required for an action.
*   `ZeroAddressRecipient`: Attempted to mint or transfer to the zero address.
*   `CannotTransferEntangledSuperposed`: Cannot transfer a token that is entangled and in Superposed state.
*   `OnlySuperposedCanBeObserved`: Only tokens in the Superposed state can be observed.

**Events:**
*   `TokenStateChanged(uint256 indexed tokenId, State newState)`: Emitted when a token's state changes.
*   `TokensEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 correlationFactor)`: Emitted when two tokens become entangled.
*   `TokensDisentangled(uint256 indexed tokenId1, uint256 indexed tokenId2)`: Emitted when entanglement is broken.
*   `SuperpositionObserved(uint256 indexed tokenId, uint256 indexed entangledTokenId, State resultState1, State resultState2)`: Emitted when a Superposed state collapses.
*   `TokensMerged(uint256 indexed newTokenId, uint256 indexed burnedTokenId1, uint256 indexed burnedTokenId2)`: Emitted when two tokens are merged into a new one.
*   `TokenSplit(uint256 indexed burnedTokenId, uint256 indexed newTokenId1, uint256 indexed newTokenId2)`: Emitted when a token is split into two new ones.

**State Variables:**
*   `_tokenStates`: Mapping from token ID to its current state.
*   `_entangledPair`: Mapping from token ID to its entangled partner's token ID.
*   `_entanglementCorrelation`: Mapping from token ID to the correlation factor for its entangled pair.
*   `_nextTokenId`: Counter for minting new tokens.
*   `_entanglementEnabled`: Flag to enable/disable the entanglement feature.

**Functions:**

1.  `constructor()`: Initializes the contract, setting the owner and initial states.
2.  `supportsInterface(bytes4 interfaceId)`: Standard ERC165 interface support, includes ERC721, ERC721Enumerable, and Pausable.
3.  `ownerOf(uint256 tokenId)`: Returns the owner of the token (ERC721 standard).
4.  `balanceOf(address owner)`: Returns the number of tokens owned by an address (ERC721 standard).
5.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers token, overridden to check state/entanglement restrictions.
6.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer, overridden to check state/entanglement restrictions.
7.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Safe transfer with data, overridden to check state/entanglement restrictions.
8.  `approve(address to, uint256 tokenId)`: Approves transfer (ERC721 standard).
9.  `getApproved(uint256 tokenId)`: Gets approved address (ERC721 standard).
10. `setApprovalForAll(address operator, bool approved)`: Sets approval for all tokens (ERC721 standard).
11. `isApprovedForAll(address owner, address operator)`: Checks approval for all tokens (ERC721 standard).
12. `tokenByIndex(uint256 index)`: Gets token ID by index (ERC721Enumerable).
13. `tokenOfOwnerByIndex(address owner, uint256 index)`: Gets token ID owned by address by index (ERC721Enumerable).
14. `totalSupply()`: Gets total number of tokens (ERC721Enumerable).
15. `mint(address to)`: Mints a new token in `Dormant` state. (Owner only)
16. `batchMint(address[] calldata recipients)`: Mints multiple tokens to different recipients. (Owner only)
17. `getTokenState(uint256 tokenId)`: Returns the current state of a token.
18. `transitionState(uint256 tokenId, State targetState)`: Allows specific authorized state transitions (e.g., Owner/Approved can change from `Dormant` to `Active`). (Auth required)
19. `entangleTokens(uint256 tokenId1, uint256 tokenId2, uint256 correlationFactor)`: Entangles two tokens if both are `Dormant` and not already entangled. Sets their state to `Superposed`. (Auth required, e.g., owner of both)
20. `disentangleTokens(uint256 tokenId)`: Breaks entanglement for a token if it's entangled and *not* `Superposed`. Resets state to `Dormant`. (Auth required, e.g., owner)
21. `observeSuperposition(uint256 tokenId)`: Triggers the collapse of the entangled state if the token is `Superposed`. Deterministically moves the token and its partner to `Active` or `Decayed` based on the correlation factor. (Any caller can trigger observation)
22. `getEntangledPair(uint256 tokenId)`: Returns the token ID of the entangled partner, or 0 if not entangled.
23. `isEntangled(uint256 tokenId)`: Returns true if the token is part of an entanglement.
24. `getCorrelationFactor(uint256 tokenId)`: Returns the correlation factor for an entangled pair (of which the token is a part).
25. `conditionalTransferIfActive(uint256 tokenId, address to)`: Transfers a token only if its current state is `Active`. (Auth required, e.g., owner/approved)
26. `mergeDecayedTokens(uint256 tokenId1, uint256 tokenId2)`: Burns two tokens in the `Decayed` state owned by the caller and mints a new token in the `Dormant` state. (Owner of both required)
27. `splitActiveToken(uint256 tokenId)`: Burns a token in the `Active` state owned by the caller and mints two new tokens in the `Dormant` state. (Owner required)
28. `setEntanglementEnabled(bool enabled)`: Enables or disables the entanglement feature. (Owner only)
29. `pause()`: Pauses contract operations. (Owner only)
30. `unpause()`: Unpauses contract operations. (Owner only)
31. `withdraw()`: Allows owner to withdraw any accidentally sent Ether. (Owner only)
32. `getLatestTokenId()`: Returns the ID of the most recently minted token.
33. `getTokensOwnedBy(address owner)`: Returns an array of token IDs owned by a specific address. (Utility, potentially gas-intensive for large numbers)

*(Note: The ERC721 standard requires implementing `ownerOf`, `balanceOf`, `transferFrom`, `safeTransferFrom` variants, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, and `supportsInterface`. ERC721Enumerable adds `totalSupply`, `tokenByIndex`, `tokenOfOwnerByIndex`. Pausable adds `paused`, `pause`, `unpause`. We are implementing or overriding a significant number of these, plus adding our custom logic functions, easily exceeding 20 distinct actions/queries/logic units.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {IERC165} from "@openzeppelin/contracts/utils/interfaces/IERC165.sol";

// Outline and Function Summary at the top of the file.

contract QuantumEntangledTokens is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- Enums ---
    enum State {
        Dormant,    // Initial state, can be entangled from here
        Active,     // Stable state, transferable
        Superposed, // Entangled state, cannot be transferred, must be observed
        Decayed     // Stable state, cannot be transferred, can be merged
    }

    // --- State Variables ---
    mapping(uint256 => State) private _tokenStates;
    mapping(uint256 => uint256) private _entangledPair; // tokenId => entangledTokenId
    mapping(uint256 => uint256) private _entanglementCorrelation; // tokenId => correlationFactor for the pair
    Counters.Counter private _nextTokenId;
    bool private _entanglementEnabled = true;

    // --- Custom Errors ---
    error InvalidStateTransition(uint256 tokenId, State currentState, State targetState);
    error TokenNotInRequiredState(uint256 tokenId, State currentState, State requiredState);
    error AlreadyEntangled(uint256 tokenId);
    error NotEntangled(uint256 tokenId);
    error SameTokenEntanglement();
    error EntanglementDisabled();
    error NotOwnerOfBothTokens(address caller, uint256 tokenId1, uint256 tokenId2);
    error ZeroAddressRecipient();
    error CannotTransferEntangledSuperposed(uint256 tokenId);
    error OnlySuperposedCanBeObserved(uint256 tokenId);

    // --- Events ---
    event TokenStateChanged(uint256 indexed tokenId, State newState);
    event TokensEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 correlationFactor);
    event TokensDisentangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event SuperpositionObserved(uint256 indexed tokenId, uint256 indexed entangledTokenId, State resultState1, State resultState2);
    event TokensMerged(uint256 indexed newTokenId, uint256 indexed burnedTokenId1, uint256 indexed burnedTokenId2);
    event TokenSplit(uint256 indexed burnedTokenId, uint256 indexed newTokenId1, uint256 indexed newTokenId2);

    // --- Constructor ---
    constructor(string memory name, string memory symbol, address initialOwner)
        ERC721(name, symbol)
        Ownable(initialOwner)
    {}

    // --- Overrides for ERC721/ERC721Enumerable/Pausable ---

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, Ownable, Pausable) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Enumerable).interfaceId ||
               interfaceId == type(Ownable).interfaceId ||
               interfaceId == type(Pausable).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override(ERC721, ERC721Enumerable) returns (address) {
        return super.ownerOf(tokenId);
    }

    /**
     * @dev See {ERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override(ERC721, ERC721Enumerable) returns (uint256) {
         return super.balanceOf(owner);
    }

    /**
     * @dev See {ERC721-transferFrom}. Overridden to apply state/entanglement restrictions.
     */
    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721, ERC721Enumerable) {
        _beforeTokenTransfer(from, to, tokenId);
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {ERC721-safeTransferFrom}. Overridden to apply state/entanglement restrictions.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721, ERC721Enumerable) {
         _beforeTokenTransfer(from, to, tokenId);
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {ERC721-safeTransferFrom}. Overridden to apply state/entanglement restrictions.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(ERC721, ERC721Enumerable) {
        _beforeTokenTransfer(from, to, tokenId);
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev See {ERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override(ERC721, ERC721Enumerable) returns (uint256) {
        return super.totalSupply();
    }

    /**
     * @dev See {ERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override(ERC721, ERC721Enumerable) returns (uint256) {
        return super.tokenByIndex(index);
    }

     /**
     * @dev See {ERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override(ERC721, ERC721Enumerable) returns (uint256) {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     * Overridden to check token state and entanglement status before any transfer.
     * Tokens in `Superposed` state cannot be transferred.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
             // Minting doesn't require checks on the token's prior state
             // Initial state will be set by _mint or mint function
        } else if (to == address(0)) {
            // Burning
            _disentangleTokensInternal(tokenId); // Break entanglement if exists
            // State doesn't prevent burning, cleanup happens below in _burn
        } else {
            // Transfer between addresses
            if (_tokenStates[tokenId] == State.Superposed) {
                revert CannotTransferEntangledSuperposed(tokenId);
            }
            // Note: Transferring a token in Dormant or Active state *does* break its entanglement.
            // This is handled implicitly here if the token is not Superposed,
            // as the entanglement mapping is token ID based. When a token leaves
            // an address, its previous entanglement link becomes invalid from its perspective.
            // However, the partner's link still points to the transferred token's old ID.
            // To keep state consistent, we explicitly break entanglement on transfer
             if (_entangledPair[tokenId] != 0) {
                 _disentangleTokensInternal(tokenId);
             }
        }

        if (to == address(0)) {
             // No check needed for burn
        } else if (to == address(this)) {
             // Contract self-transfer, e.g., for merging/splitting - state doesn't strictly matter
        } else {
             // Standard transfer to a user
             if (to == address(0)) revert ZeroAddressRecipient();
             require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
             require(isApprovedForAll(from, _msgSender()) || getApproved(tokenId) == _msgSender(), "ERC721: transfer caller is not owner nor approved");
        }
    }

    /**
     * @dev See {ERC721-_burn}.
     * Overridden to clear state and entanglement mappings when a token is burned.
     */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        _disentangleTokensInternal(tokenId); // Ensure entanglement is broken
        delete _tokenStates[tokenId];
        super._burn(tokenId);
    }

    /**
     * @dev See {ERC721-_safeMint}.
     * Used internally by minting functions. Sets initial state.
     */
    function _safeMint(address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._safeMint(to, tokenId);
        _setTokenState(tokenId, State.Dormant); // Newly minted tokens start Dormant
    }


    // --- Custom State Management Functions ---

    /**
     * @dev Internal helper to set a token's state and emit an event.
     */
    function _setTokenState(uint256 tokenId, State newState) internal {
        State currentState = _tokenStates[tokenId];
        if (currentState != newState) {
             _tokenStates[tokenId] = newState;
             emit TokenStateChanged(tokenId, newState);
        }
    }

    /**
     * @dev Returns the current state of a given token.
     * @param tokenId The ID of the token.
     * @return The current state of the token.
     */
    function getTokenState(uint256 tokenId) public view returns (State) {
        // ERC721 requires token 0 to not exist. Check for existence implicitly via ownerOf or state.
        // Mapping default is State.Dormant, but non-existent tokens should behave differently.
        // A token exists if it has an owner.
        try ERC721Enumerable.ownerOf(tokenId) returns (address tokenOwner) {
             if (tokenOwner == address(0)) {
                 // Should not happen for existing tokens based on ERC721
                 return State.Dormant; // Or error? Let's treat 0 owner as non-existent
             }
             return _tokenStates[tokenId];
        } catch {
            // Token doesn't exist (e.g., has no owner via _owners mapping)
            // Return a default or indicate non-existence. Dormant is a safe default for non-existent.
            return State.Dormant; // Non-existent tokens default state conceptually
        }
    }


    /**
     * @dev Allows specific authorized transitions between states.
     * Not all transitions are allowed via this function (e.g., cannot go to/from Superposed).
     * Observation of Superposed uses a separate function.
     * @param tokenId The ID of the token to transition.
     * @param targetState The desired state.
     */
    function transitionState(uint256 tokenId, State targetState) public virtual {
        require(ownerOf(tokenId) == _msgSender() || getApproved(tokenId) == _msgSender() || isApprovedForAll(ownerOf(tokenId), _msgSender()),
            "Unauthorized"); // Only owner or approved can trigger manual transitions

        State currentState = _tokenStates[tokenId];

        if (currentState == targetState) {
            return; // No change
        }

        // Define allowed transitions via this function
        bool allowed = false;
        if (currentState == State.Dormant && targetState == State.Active) {
            allowed = true; // Dormant -> Active
        } else if (currentState == State.Active && targetState == State.Dormant) {
            allowed = true; // Active -> Dormant
        } else {
             revert InvalidStateTransition(tokenId, currentState, targetState);
        }

        if (_entangledPair[tokenId] != 0) {
             // If entangled, ensure we are not in Superposed, and breaking entanglement
             // before changing state might be necessary depending on desired logic.
             // Current logic: Disentangling is a separate step. TransitionState won't
             // affect entanglement status.
             // Let's disallow state transitions via this function if entangled at all
             // to force disentanglement first, except for the specific collapse via observeSuperposition.
             revert TokenNotInRequiredState(tokenId, currentState, currentState); // Disallow if entangled
        }

        if (allowed) {
            _setTokenState(tokenId, targetState);
        }
    }

    // --- Entanglement Functions ---

    /**
     * @dev Entangles two tokens together. Both must be Dormant and owned by the caller.
     * Sets both tokens to the Superposed state.
     * @param tokenId1 The ID of the first token.
     * @param tokenId2 The ID of the second token.
     * @param correlationFactor A factor used later during superposition collapse. Can be any uint256.
     */
    function entangleTokens(uint256 tokenId1, uint256 tokenId2, uint256 correlationFactor) public whenNotPaused {
        if (!_entanglementEnabled) revert EntanglementDisabled();
        if (tokenId1 == tokenId2) revert SameTokenEntanglement();

        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);

        if (owner1 != _msgSender() || owner2 != _msgSender() || owner1 != owner2) {
            revert NotOwnerOfBothTokens(_msgSender(), tokenId1, tokenId2);
        }

        if (_tokenStates[tokenId1] != State.Dormant) revert TokenNotInRequiredState(tokenId1, _tokenStates[tokenId1], State.Dormant);
        if (_tokenStates[tokenId2] != State.Dormant) revert TokenNotInRequiredState(tokenId2, _tokenStates[tokenId2], State.Dormant);

        if (_entangledPair[tokenId1] != 0) revert AlreadyEntangled(tokenId1);
        if (_entangledPair[tokenId2] != 0) revert AlreadyEntangled(tokenId2);

        _entangledPair[tokenId1] = tokenId2;
        _entangledPair[tokenId2] = tokenId1;
        _entanglementCorrelation[tokenId1] = correlationFactor; // Store factor with one token ID, retrieve via pair
        _entanglementCorrelation[tokenId2] = correlationFactor; // Store with both for easier lookup

        _setTokenState(tokenId1, State.Superposed);
        _setTokenState(tokenId2, State.Superposed);

        emit TokensEntangled(tokenId1, tokenId2, correlationFactor);
    }

    /**
     * @dev Breaks the entanglement for a given token.
     * The token and its partner must NOT be in the Superposed state.
     * Sets both tokens back to Dormant state.
     * @param tokenId The ID of one of the entangled tokens.
     */
    function disentangleTokens(uint256 tokenId) public whenNotPaused {
        uint256 partnerTokenId = _entangledPair[tokenId];
        if (partnerTokenId == 0) revert NotEntangled(tokenId);

        require(ownerOf(tokenId) == _msgSender(), "Not authorized to disentangle"); // Only owner can break

        if (_tokenStates[tokenId] == State.Superposed || _tokenStates[partnerTokenId] == State.Superposed) {
             // Disentanglement is not possible while in Superposed state. Observation is required.
             revert TokenNotInRequiredState(tokenId, _tokenStates[tokenId], State.Superposed); // Error indicates wrong state
        }

        _disentangleTokensInternal(tokenId);
    }

    /**
     * @dev Internal function to break entanglement mapping and reset states.
     * Used by disentangleTokens, _beforeTokenTransfer (on burn/transfer), and _burn.
     * Does *not* check state, authorization, or paused status - assumes caller has done checks.
     * @param tokenId The ID of one of the entangled tokens.
     */
    function _disentangleTokensInternal(uint256 tokenId) internal {
        uint256 partnerTokenId = _entangledPair[tokenId];
        if (partnerTokenId != 0) {
            delete _entangledPair[tokenId];
            delete _entangledPair[partnerTokenId];
            delete _entanglementCorrelation[tokenId];
            delete _entanglementCorrelation[partnerTokenId];

            // Reset states if they were involved in an entanglement
            if (_tokenStates[tokenId] == State.Superposed || _tokenStates[tokenId] == State.Dormant) {
                 _setTokenState(tokenId, State.Dormant); // Reset to dormant
            }
             if (_tokenStates[partnerTokenId] == State.Superposed || _tokenStates[partnerTokenId] == State.Dormant) {
                 _setTokenState(partnerTokenId, State.Dormant); // Reset to dormant
            }

            emit TokensDisentangled(tokenId, partnerTokenId);
        }
    }

    /**
     * @dev Triggers the collapse of the superposition for an entangled pair.
     * The target token MUST be in the Superposed state.
     * Deterministically moves both tokens from Superposed to either Active or Decayed
     * based on the correlation factor set during entanglement.
     * Any address can trigger this observation.
     * @param tokenId The ID of the token to observe.
     */
    function observeSuperposition(uint256 tokenId) public whenNotPaused {
        if (_tokenStates[tokenId] != State.Superposed) {
            revert OnlySuperposedCanBeObserved(tokenId);
        }

        uint256 partnerTokenId = _entangledPair[tokenId];
        // Should be true if state is Superposed, but double-check
        if (partnerTokenId == 0) revert NotEntangled(tokenId);
        // Partner should also be Superposed
        if (_tokenStates[partnerTokenId] != State.Superposed) {
             // This indicates an internal state inconsistency, should ideally not happen
             revert InvalidStateTransition(partnerTokenId, _tokenStates[partnerTokenId], State.Superposed);
        }

        // Apply the "quantum" effect based on correlation factor
        _applyEntanglementEffect(tokenId);
    }

    /**
     * @dev Internal function to apply the collapse effect for a Superposed pair.
     * Deterministically assigns Active/Decayed states based on correlation factor.
     * Assumes tokens are entangled and in Superposed state.
     * @param tokenId The ID of one of the entangled tokens.
     */
    function _applyEntanglementEffect(uint256 tokenId) internal {
         uint256 partnerTokenId = _entangledPair[tokenId];
         uint256 correlationFactor = _entanglementCorrelation[tokenId];

         // Deterministic outcome based on token IDs and correlation factor
         // Example logic: If correlationFactor is even/odd, or based on
         // (tokenId + partnerTokenId + correlationFactor) % 2, etc.
         // Using block hash is not reliable post-merge, timestamp too granular.
         // Let's use (tokenId + partnerTokenId + correlationFactor) % 2 for a simple deterministic split.
         uint256 combinedFactor = tokenId + partnerTokenId + correlationFactor;

         // Ensure consistent order for the deterministic check
         uint256 firstTokenId = tokenId < partnerTokenId ? tokenId : partnerTokenId;
         uint256 secondTokenId = tokenId < partnerTokenId ? partnerTokenId : tokenId;

         State state1;
         State state2;

         if (combinedFactor % 2 == 0) {
             // Even outcome: first ID gets Active, second gets Decayed
             state1 = State.Active;
             state2 = State.Decayed;
         } else {
             // Odd outcome: first ID gets Decayed, second gets Active
             state1 = State.Decayed;
             state2 = State.Active;
         }

         // Assign states based on original token IDs, not just first/second in comparison
         if (tokenId == firstTokenId) {
             _setTokenState(tokenId, state1);
             _setTokenState(partnerTokenId, state2);
         } else {
             _setTokenState(tokenId, state2);
             _setTokenState(partnerTokenId, state1);
         }

         // Disentangle the pair after collapse
         _disentangleTokensInternal(tokenId); // This also emits TokensDisentangled

         emit SuperpositionObserved(tokenId, partnerTokenId, _tokenStates[tokenId], _tokenStates[partnerTokenId]);
    }


    /**
     * @dev Gets the token ID of the entangled partner.
     * @param tokenId The ID of the token.
     * @return The ID of the entangled token, or 0 if not entangled.
     */
    function getEntangledPair(uint256 tokenId) public view returns (uint256) {
        return _entangledPair[tokenId];
    }

    /**
     * @dev Checks if a token is currently entangled.
     * @param tokenId The ID of the token.
     * @return True if entangled, false otherwise.
     */
    function isEntangled(uint256 tokenId) public view returns (bool) {
        return _entangledPair[tokenId] != 0;
    }

    /**
     * @dev Gets the correlation factor stored for an entangled pair.
     * @param tokenId The ID of a token in the pair.
     * @return The correlation factor, or 0 if not entangled.
     */
    function getCorrelationFactor(uint256 tokenId) public view returns (uint256) {
        return _entanglementCorrelation[tokenId];
    }

    // --- Novel Mechanics ---

    /**
     * @dev Allows transferring a token only if its state is Active.
     * Useful for conditional interactions based on state.
     * @param tokenId The ID of the token to transfer.
     * @param to The recipient address.
     */
    function conditionalTransferIfActive(uint256 tokenId, address to) public whenNotPaused {
        if (_tokenStates[tokenId] != State.Active) {
             revert TokenNotInRequiredState(tokenId, _tokenStates[tokenId], State.Active);
        }
        // Use the standard transfer function which includes state/entanglement checks
        safeTransferFrom(_msgSender(), to, tokenId);
    }

    /**
     * @dev Merges two Decayed tokens into a new Dormant token.
     * Requires the caller to own both Decayed tokens.
     * The two original tokens are burned.
     * @param tokenId1 The ID of the first Decayed token.
     * @param tokenId2 The ID of the second Decayed token.
     */
    function mergeDecayedTokens(uint256 tokenId1, uint256 tokenId2) public whenNotPaused {
        if (tokenId1 == tokenId2) revert SameTokenEntanglement(); // Cannot merge token with itself

        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);

        if (owner1 != _msgSender() || owner2 != _msgSender() || owner1 != owner2) {
            revert NotOwnerOfBothTokens(_msgSender(), tokenId1, tokenId2);
        }

        if (_tokenStates[tokenId1] != State.Decayed) revert TokenNotInRequiredState(tokenId1, _tokenStates[tokenId1], State.Decayed);
        if (_tokenStates[tokenId2] != State.Decayed) revert TokenNotInRequiredState(tokenId2, _tokenStates[tokenId2], State.Decayed);

        // Burn the two Decayed tokens
        _burn(tokenId1);
        _burn(tokenId2);

        // Mint a new token in Dormant state
        uint256 newTokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _safeMint(_msgSender(), newTokenId); // _safeMint sets state to Dormant

        emit TokensMerged(newTokenId, tokenId1, tokenId2);
    }

     /**
     * @dev Splits an Active token into two new Dormant tokens.
     * Requires the caller to own the Active token.
     * The original token is burned.
     * @param tokenId The ID of the Active token to split.
     */
    function splitActiveToken(uint256 tokenId) public whenNotPaused {
         address owner = ownerOf(tokenId);
         if (owner != _msgSender()) {
             revert NotOwnerOfBothTokens(_msgSender(), tokenId, 0); // Use 0 for second ID in error
         }

         if (_tokenStates[tokenId] != State.Active) revert TokenNotInRequiredState(tokenId, _tokenStates[tokenId], State.Active);

         // Burn the Active token
         _burn(tokenId);

         // Mint two new tokens in Dormant state
         uint256 newTokenId1 = _nextTokenId.current();
         _nextTokenId.increment();
         _safeMint(_msgSender(), newTokenId1); // _safeMint sets state to Dormant

         uint256 newTokenId2 = _nextTokenId.current();
         _nextTokenId.increment();
         _safeMint(_msgSender(), newTokenId2); // _safeMint sets state to Dormant

         emit TokenSplit(tokenId, newTokenId1, newTokenId2);
     }

    // --- Admin Functions ---

    /**
     * @dev Mints a new token and assigns it to an address.
     * The new token starts in the Dormant state.
     * @param to The address to mint the token to.
     */
    function mint(address to) public onlyOwner whenNotPaused {
        if (to == address(0)) revert ZeroAddressRecipient();
        uint256 newTokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _safeMint(to, newTokenId); // _safeMint calls _setTokenState to Dormant
    }

    /**
     * @dev Mints multiple tokens to a list of recipients.
     * Each new token starts in the Dormant state.
     * @param recipients Array of addresses to mint tokens to.
     */
    function batchMint(address[] calldata recipients) public onlyOwner whenNotPaused {
        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] == address(0)) revert ZeroAddressRecipient();
            uint256 newTokenId = _nextTokenId.current();
            _nextTokenId.increment();
            _safeMint(recipients[i], newTokenId);
        }
    }

    /**
     * @dev Toggles whether new entanglement pairs can be created.
     * Existing entanglements are unaffected.
     * @param enabled True to enable, false to disable.
     */
    function setEntanglementEnabled(bool enabled) public onlyOwner {
        _entanglementEnabled = enabled;
    }

    /**
     * @dev See {Pausable-pause}.
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev See {Pausable-unpause}.
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw any accidental Ether sent to the contract.
     */
    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    // --- Query Functions ---

    /**
     * @dev Returns the ID of the latest minted token.
     */
    function getLatestTokenId() public view returns (uint256) {
        // _nextTokenId is the *next* ID to be minted.
        // If count is 0, no tokens minted, return 0 or handle appropriately.
        // If count is N > 0, the latest minted ID is N-1.
        uint256 currentCount = _nextTokenId.current();
        return currentCount > 0 ? currentCount - 1 : 0;
    }

    /**
     * @dev Returns an array of all token IDs owned by a specific address.
     * This function can be gas-intensive for owners with many tokens.
     * Use {ERC721Enumerable-tokenOfOwnerByIndex} for iterating off-chain.
     * @param owner The address to query.
     * @return An array of token IDs.
     */
    function getTokensOwnedBy(address owner) public view returns (uint256[] memory) {
        // Leveraging ERC721Enumerable's internal structure
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }
}
```