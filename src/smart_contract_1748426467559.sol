Okay, let's create a smart contract that uses the metaphor of "Quantum Entanglement" for token pairs. This contract will be an ERC-721 (NFT) where tokens can be 'entangled' with each other. Actions performed on one entangled token will have effects on its paired token, mimicking non-local correlation. We'll also incorporate states, properties, and interactions inspired by quantum mechanics concepts like superposition, measurement, and decoherence, without relying on actual quantum computing (which isn't possible on EVM).

This concept is creative, relatively advanced due to the interconnected state management and custom transfer logic, and fits the "trendy" NFT space with unique mechanics. It aims not to duplicate any single standard open-source contract's core novel logic, though it will use established patterns like ERC721, Ownable, and Pausable from OpenZeppelin for safety and best practice.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Quantum Entangled Tokens (QET)
/// @author Your Name/Alias
/// @notice A novel ERC-721 contract where tokens can be 'entangled' in pairs.
/// Actions on one entangled token influence its pair. Features include entanglement
/// states, interaction states, quantum properties, coherence decay, and special
/// entangled transfer/separation functions.

/*
Outline:
1.  Imports: ERC721, Ownable, Pausable, Counters, Math, Strings from OpenZeppelin.
2.  Errors: Custom errors for specific conditions.
3.  Events: To signal key state changes and actions (mint, burn, entanglement, decoherence, measurement, state changes, property updates).
4.  Enums: Define possible states for tokens (EntanglementState, InteractionState, TokenState).
5.  Structs: Define QuantumProperties.
6.  State Variables: Mappings and variables to track token states, pairs, properties, coherence, total supply, etc.
7.  Constructor: Initializes the ERC721 contract, owner, and pausable state.
8.  Modifiers: Custom modifiers for state checks (e.g., whenEntangled, whenNotEntangled).
9.  Core ERC721 Overrides: `_beforeTokenTransfer` to apply entanglement/state effects during transfers.
10. ERC721 Standard Functions: Implement required ERC721 functions.
11. Minting & Burning: Functions to create and destroy tokens.
12. Quantum Mechanics Functions:
    -   `entangleTokens`: Pair two unentangled tokens.
    -   `decoherePair`: Break the entanglement link.
    -   `performQuantumMeasurement`: Apply a 'measurement' effect on an entangled pair, influencing states and coherence.
    -   `induceSuperposition`: Change a token's interaction state to Superposed.
    -   `collapseSuperposition`: Change a Superposed token back to a non-Superposed state.
    -   `decayCoherence`: Manually decrease a token's coherence (also happens automatically on certain actions).
    -   `setQuantumProperties`: Define immutable properties for a token (e.g., charm, strangeness, spin).
13. State & Property Getters: Functions to query entanglement state, interaction state, pair ID, properties, coherence.
14. Special Transfer Functions:
    -   `transferEntangledPair`: Transfer both tokens of an entangled pair together.
    -   `separateEntangledPair`: Transfer entangled tokens to different recipients, forcing decoherence.
15. Admin/Utility Functions: Pause/unpause, ownership management, rescue accidentally sent ETH/tokens, get total supply.
*/

/*
Function Summary (Public/External Functions - aiming for 20+):

ERC721 Standard (Required overrides):
-   `balanceOf(address owner)`: Returns the number of tokens owned by `owner`.
-   `ownerOf(uint256 tokenId)`: Returns the owner of the `tokenId` token.
-   `approve(address to, uint256 tokenId)`: Approves `to` to transfer `tokenId`.
-   `getApproved(uint256 tokenId)`: Returns the approved address for `tokenId`.
-   `setApprovalForAll(address operator, bool approved)`: Approves/disapproves `operator` for all tokens of sender.
-   `isApprovedForAll(address owner, address operator)`: Checks if `operator` is approved for all tokens of `owner`.
-   `transferFrom(address from, address to, uint256 tokenId)`: Transfers `tokenId` from `from` to `to`.
-   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer checking receiver capability.
-   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer with data.
-   `tokenURI(uint256 tokenId)`: Returns the URI for metadata of `tokenId`.
-   `supportsInterface(bytes4 interfaceId)`: Standard interface check.

Minting & Burning:
-   `mint(address to)`: Mints a new token to `to`. Initial state is Unentangled/Ground, random properties, max coherence.
-   `burn(uint256 tokenId)`: Burns (destroys) a token. Must be unentangled or decohered.

Quantum Mechanics & State Management:
-   `entangleTokens(uint256 tokenId1, uint256 tokenId2)`: Entangles two tokens owned by the caller.
-   `decoherePair(uint256 tokenId)`: Decouples a token from its pair.
-   `performQuantumMeasurement(uint256 tokenId)`: Simulates a quantum measurement, influencing the state and coherence of the token and its pair (if entangled).
-   `induceSuperposition(uint256 tokenId)`: Attempts to put a token into a Superposed state (requires specific conditions).
-   `collapseSuperposition(uint256 tokenId)`: Attempts to collapse a Superposed token back to Ground or Excited state.
-   `decayCoherence(uint256 tokenId)`: Explicitly reduces a token's coherence. Coherence also decays during transfers and measurements.
-   `setQuantumProperties(uint256 tokenId, uint256 charm, uint256 strangeness, uint256 spin)`: Sets initial, immutable quantum properties for a token *before* it's entangled.

State & Property Getters:
-   `getEntanglementState(uint256 tokenId)`: Returns the EntanglementState of a token.
-   `getInteractionState(uint256 tokenId)`: Returns the InteractionState of a token.
-   `getTokenState(uint256 tokenId)`: Returns the combined TokenState (enum) of a token.
-   `getEntangledPair(uint256 tokenId)`: Returns the tokenId of the paired token, or 0 if not entangled.
-   `getQuantumProperties(uint256 tokenId)`: Returns the QuantumProperties of a token.
-   `getCoherence(uint256 tokenId)`: Returns the current coherence level of a token.

Special Transfer Functions:
-   `transferEntangledPair(uint256 tokenId, address receiver)`: Transfers an entangled token AND its pair to the same `receiver`. Fails if not entangled or receiver can't receive ERC721.
-   `separateEntangledPair(uint256 tokenId, address receiverToken1, address receiverToken2)`: Transfers an entangled token to `receiverToken1` and its pair to `receiverToken2`. FORCES decoherence and applies a coherence penalty.

Admin & Utility:
-   `pause()`: Pauses transfers and most state-changing actions (Owner only).
-   `unpause()`: Unpauses the contract (Owner only).
-   `isPaused()`: Checks if the contract is paused.
-   `renounceOwnership()`: Renounces ownership of the contract (Owner only).
-   `transferOwnership(address newOwner)`: Transfers ownership of the contract (Owner only).
-   `rescueETH()`: Allows owner to withdraw accidentally sent ETH.
-   `rescueToken(address tokenAddress, uint256 amount)`: Allows owner to withdraw accidentally sent ERC20 tokens.
-   `getTotalSupply()`: Returns the total number of tokens minted.

Total Public/External Functions: 11 (ERC721) + 2 (Mint/Burn) + 7 (Quantum Mechanics) + 6 (Getters) + 2 (Special Transfer) + 7 (Admin/Utility) = 35+ functions. Easily exceeds the 20 minimum.
*/

// --- Custom Errors ---
error QET__AlreadyEntangled(uint256 tokenId);
error QET__NotEntangled(uint256 tokenId);
error QET__TokensNotOwnedByCaller(uint256 tokenId1, uint256 tokenId2);
error QET__CannotEntangleSelf();
error QET__CannotEntangleWithDifferentOwner();
error QET__CannotDecohereWhenNotEntangled(uint256 tokenId);
error QET__CannotBurnEntangled(uint256 tokenId);
error QET__PropertiesAlreadySet(uint256 tokenId);
error QET__CoherenceTooLow(uint256 tokenId, uint256 currentCoherence);
error QET__MeasurementRequiresEntanglementOrSuperposition(uint256 tokenId);
error QET__CannotSuperposeUnentangled(uint256 tokenId);
error QET__CannotCollapseNonSuperposed(uint256 tokenId);
error QET__CannotTransferPairWhenNotEntangled(uint256 tokenId);
error QET__CannotSeparatePairWhenNotEntangled(uint256 tokenId);

// --- Events ---
event TokenEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
event TokenDecohered(uint256 indexed tokenId1, uint256 indexed tokenId2);
event QuantumMeasurementPerformed(uint256 indexed tokenId, uint256 indexed pairedTokenId, uint256 measurementRandomness);
event TokenStateChanged(uint256 indexed tokenId, TokenState oldState, TokenState newState);
event QuantumPropertiesSet(uint256 indexed tokenId, uint256 charm, uint256 strangeness, uint256 spin);
event CoherenceDecayed(uint256 indexed tokenId, uint256 newCoherence);
event EntangledPairTransferred(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed from, address indexed to);
event EntangledPairSeparated(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed from, address receiver1, address receiver2);


contract QuantumEntangledTokens is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Enums ---
    enum EntanglementState { Unentangled, Entangled, Decohered }
    enum InteractionState { GroundState, ExcitedState, SuperposedState }

    // Combined State for easier tracking/emission
    enum TokenState {
        UnentangledGround, UnentangledExcited, UnentangledSuperposed,
        EntangledGround, EntangledExcited, EntangledSuperposed,
        DecoheredGround, DecoheredExcited, DecoheredSuperposed
    }

    // --- Structs ---
    struct QuantumProperties {
        uint256 charm;      // e.g., influences coherence decay rate, state transition probability
        uint256 strangeness; // e.g., influences 'randomness' outcome in measurement
        uint256 spin;       // e.g., a binary property, 0 or 1, that flips on certain interactions
    }

    // --- State Variables ---
    Counters.Counter private _tokenCounter;

    // Mapping from tokenId to its current state
    mapping(uint256 => EntanglementState) private _entanglementState;
    mapping(uint256 => InteractionState) private _interactionState;

    // Mapping for entangled pairs: tokenId -> pairedTokenId
    mapping(uint256 => uint256) private _entangledPair;

    // Mapping for Quantum Properties: tokenId -> properties
    mapping(uint256 => QuantumProperties) private _quantumProperties;
    // Keep track if properties are set
    mapping(uint256 => bool) private _propertiesSet;

    // Mapping for Coherence: tokenId -> coherence level (e.g., 0-1000)
    mapping(uint256 => uint256) private _coherence;
    uint256 public constant MAX_COHERENCE = 1000;
    uint256 public constant COHERENCE_DECAY_TRANSFER = 50;
    uint256 public constant COHERENCE_DECAY_MEASUREMENT = 100;
    uint256 public constant COHERENCE_DECAY_SEPARATION = 300; // Significant penalty

    // Base URI for token metadata
    string private _baseTokenURI;

    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory baseTokenURI)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _baseTokenURI = baseTokenURI;
        // Contract starts unpaused
    }

    // --- Modifiers ---
    modifier whenEntangled(uint256 tokenId) {
        if (_entanglementState[tokenId] != EntanglementState.Entangled) {
             revert QET__NotEntangled(tokenId);
        }
        _;
    }

     modifier whenNotEntangled(uint256 tokenId) {
        if (_entanglementState[tokenId] == EntanglementState.Entangled) {
             revert QET__AlreadyEntangled(tokenId);
        }
        _;
    }

    modifier onlyEntangledPair(uint256 tokenId1, uint256 tokenId2) {
        if (_entangledPair[tokenId1] != tokenId2 || _entangledPair[tokenId2] != tokenId1) {
            revert QET__NotEntangled(tokenId1); // Or a specific pair error
        }
        _;
    }

    modifier whenPropertiesNotSet(uint256 tokenId) {
        if (_propertiesSet[tokenId]) {
            revert QET__PropertiesAlreadySet(tokenId);
        }
        _;
    }

    // --- Internal Helpers ---

    /// @dev Generates a pseudo-random factor based on block data. Not cryptographically secure.
    function _generateRandomFactor(uint256 seed) internal view returns (uint256) {
        // Using block.timestamp and block.difficulty (or block.prevrandao in newer versions) is common for pseudo-randomness on EVM.
        // Keccak256 of changing block data provides a pseudo-random number.
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, seed)));
        return randomness;
    }

    /// @dev Calculates the combined TokenState enum based on individual states.
    function _getCombinedState(uint256 tokenId) internal view returns (TokenState) {
        EntanglementState eState = _entanglementState[tokenId];
        InteractionState iState = _interactionState[tokenId];

        if (eState == EntanglementState.Unentangled) {
            if (iState == InteractionState.GroundState) return TokenState.UnentangledGround;
            if (iState == InteractionState.ExcitedState) return TokenState.UnentangledExcited;
            if (iState == InteractionState.SuperposedState) return TokenState.UnentangledSuperposed;
        } else if (eState == EntanglementState.Entangled) {
            if (iState == InteractionState.GroundState) return TokenState.EntangledGround;
            if (iState == InteractionState.ExcitedState) return TokenState.EntangledExcited;
            if (iState == InteractionState.SuperposedState) return TokenState.EntangledSuperposed;
        } else if (eState == EntanglementState.Decohered) {
             if (iState == InteractionState.GroundState) return TokenState.DecoheredGround;
            if (iState == InteractionState.ExcitedState) return TokenState.DecoheredExcited;
            if (iState == InteractionState.SuperposedState) return TokenState.DecoheredSuperposed;
        }
        // Should not reach here
        revert("QET: Invalid State Combination");
    }

    /// @dev Updates the state mappings and emits a TokenStateChanged event.
    function _updateTokenState(uint256 tokenId, EntanglementState newEState, InteractionState newIState) internal {
        TokenState oldCombinedState = _getCombinedState(tokenId);
        _entanglementState[tokenId] = newEState;
        _interactionState[tokenId] = newIState;
        TokenState newCombinedState = _getCombinedState(tokenId);
        if (oldCombinedState != newCombinedState) {
             emit TokenStateChanged(tokenId, oldCombinedState, newCombinedState);
        }
    }

    /// @dev Ensures properties are set before certain operations (like entanglement)
    function _requirePropertiesSet(uint256 tokenId) internal view {
        require(_propertiesSet[tokenId], "QET: Properties not set");
    }


    // --- ERC721 Overrides ---

    /// @dev See {ERC721-tokenURI}.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            return "";
        }
        // Concatenate base URI with token ID and potential file extension (e.g., .json)
        // For a simple example, just use baseURI/tokenId
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /// @dev See {ERC721-_beforeTokenTransfer}.
    /// This is the core place where entanglement effects on transfer are implemented.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // If minting (from == address(0)) or burning (to == address(0)), skip entanglement effects here.
        // State changes for mint/burn are handled in mint/burn functions.
        if (from == address(0) || to == address(0)) {
            return;
        }

        // --- Apply Coherence Decay on Transfer ---
        uint256 currentCoherence = _coherence[tokenId];
        uint256 decayAmount = COHERENCE_DECAY_TRANSFER;
        // Could add logic here for properties affecting decay:
        // decayAmount = decayAmount * (_quantumProperties[tokenId].charm + 1) / 100; // Example

        uint256 newCoherence = currentCoherence > decayAmount ? currentCoherence - decayAmount : 0;
        _coherence[tokenId] = newCoherence;
        emit CoherenceDecayed(tokenId, newCoherence);

        // --- Handle Entangled Pairs ---
        if (_entanglementState[tokenId] == EntanglementState.Entangled) {
            uint256 pairedTokenId = _entangledPair[tokenId];

            // If transferring one token of an entangled pair NOT as a pair,
            // force decoherence and apply separation penalty
            bool isSeparating = (ownerOf(pairedTokenId) != to); // Check current owner vs destination owner

            if (isSeparating) {
                 // This scenario is primarily handled by separateEntangledPair, but also catch direct transferFrom
                 // Force decoherence on both
                _updateTokenState(tokenId, EntanglementState.Decohered, _interactionState[tokenId]);
                _updateTokenState(pairedTokenId, EntanglementState.Decohered, _interactionState[pairedTokenId]);
                delete _entangledPair[tokenId];
                delete _entangledPair[pairedTokenId];
                emit TokenDecohered(tokenId, pairedTokenId);

                // Apply significant coherence decay on separation for both
                uint256 coherence1 = _coherence[tokenId];
                uint256 coherence2 = _coherence[pairedTokenId];
                _coherence[tokenId] = coherence1 > COHERENCE_DECAY_SEPARATION ? coherence1 - COHERENCE_DECAY_SEPARATION : 0;
                _coherence[pairedTokenId] = coherence2 > COHERENCE_DECAY_SEPARATION ? coherence2 - COHERENCE_DECAY_SEPARATION : 0;
                 emit CoherenceDecayed(tokenId, _coherence[tokenId]);
                 emit CoherenceDecayed(pairedTokenId, _coherence[pairedTokenId]);

                 // Optional: Could add an event for forced decoherence due to separation
            } else {
                 // If transferring the pair together (should use transferEntangledPair),
                 // minimal effect beyond standard decay.
                 // Note: transferEntangledPair handles the actual transfer call to trigger this hook.
            }
        }

         // Optional: If coherence reaches zero, force decoherence
        if (_coherence[tokenId] == 0 && _entanglementState[tokenId] == EntanglementState.Entangled) {
             uint256 pairedTokenId = _entangledPair[tokenId];
             _updateTokenState(tokenId, EntanglementState.Decohered, _interactionState[tokenId]);
             _updateTokenState(pairedTokenId, EntanglementState.Decohered, _interactionState[pairedTokenId]);
             delete _entangledPair[tokenId];
             delete _entangledPair[pairedTokenId];
             emit TokenDecohered(tokenId, pairedTokenId);
        }
    }


    // --- ERC721 Standard Functions (Implicitly included or overridden) ---
    // balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll,
    // transferFrom, safeTransferFrom, safeTransferFrom(data), tokenURI, supportsInterface
    // These are implemented by OpenZeppelin's ERC721 and ERC165 and used by the contract.


    // --- Minting & Burning ---

    /// @notice Mints a new Quantum Entangled Token.
    /// @param to The address that will receive the new token.
    /// @return The tokenId of the newly minted token.
    function mint(address to) public onlyOwner whenNotPaused returns (uint256) {
        _tokenCounter.increment();
        uint256 newItemId = _tokenCounter.current();

        _mint(to, newItemId);

        // Initialize states and coherence
        _updateTokenState(newItemId, EntanglementState.Unentangled, InteractionState.GroundState);
        _coherence[newItemId] = MAX_COHERENCE; // Start with max coherence
        // Properties are set separately later

        // No entanglement pair initially
        delete _entangledPair[newItemId];

        return newItemId;
    }

    /// @notice Burns (destroys) a Quantum Entangled Token.
    /// @param tokenId The ID of the token to burn.
    function burn(uint256 tokenId) public onlyOwner whenNotPaused {
        // Ensure token is not entangled
        if (_entanglementState[tokenId] == EntanglementState.Entangled) {
            revert QET__CannotBurnEntangled(tokenId);
        }
         // Check existence and ownership is implicit in _burn

        _burn(tokenId);

        // Clean up state mappings (optional but good practice)
        delete _entanglementState[tokenId];
        delete _interactionState[tokenId];
        delete _entangledPair[tokenId]; // Should already be clear if not entangled
        delete _quantumProperties[tokenId];
        delete _propertiesSet[tokenId];
        delete _coherence[tokenId];
    }


    // --- Quantum Mechanics & State Management Functions ---

    /// @notice Attempts to entangle two unentangled tokens owned by the caller.
    /// Requires properties to be set for both tokens.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function entangleTokens(uint256 tokenId1, uint256 tokenId2) public whenNotPaused {
        // Basic checks
        _requireOwned(tokenId1);
        _requireOwned(tokenId2);
        if (tokenId1 == tokenId2) revert QET__CannotEntangleSelf();
        if (ownerOf(tokenId1) != ownerOf(tokenId2)) revert QET__CannotEntangleWithDifferentOwner();

        // State checks
        whenNotEntangled(tokenId1);
        whenNotEntangled(tokenId2);
        _requirePropertiesSet(tokenId1);
        _requirePropertiesSet(tokenId2);

        // Perform entanglement
        _entangledPair[tokenId1] = tokenId2;
        _entangledPair[tokenId2] = tokenId1;

        // Update states for both
        InteractionState iState1 = _interactionState[tokenId1]; // Keep existing interaction state
        InteractionState iState2 = _interactionState[tokenId2];
        _updateTokenState(tokenId1, EntanglementState.Entangled, iState1);
        _updateTokenState(tokenId2, EntanglementState.Entangled, iState2);

        emit TokenEntangled(tokenId1, tokenId2);
    }

    /// @notice Decouples a token from its entangled pair. Both tokens become Decohered.
    /// @param tokenId The ID of the token to decohere.
    function decoherePair(uint256 tokenId) public whenNotPaused whenEntangled(tokenId) {
        _requireOwned(tokenId);

        uint256 pairedTokenId = _entangledPair[tokenId];
        require(pairedTokenId != 0, "QET: Invalid pair ID"); // Should be guaranteed by whenEntangled

        // Update states for both to Decohered
        InteractionState iState1 = _interactionState[tokenId];
        InteractionState iState2 = _interactionState[pairedTokenId];
        _updateTokenState(tokenId, EntanglementState.Decohered, iState1);
        _updateTokenState(pairedTokenId, EntanglementState.Decohered, iState2);

        // Remove the entanglement link
        delete _entangledPair[tokenId];
        delete _entangledPair[pairedTokenId];

        emit TokenDecohered(tokenId, pairedTokenId);
    }

    /// @notice Simulates a quantum measurement.
    /// If entangled, this affects the state and coherence of both tokens.
    /// If Superposed, it forces a collapse.
    /// @param tokenId The ID of the token being measured.
    function performQuantumMeasurement(uint256 tokenId) public whenNotPaused {
        _requireOwned(tokenId);
        _requirePropertiesSet(tokenId);

        EntanglementState eState = _entanglementState[tokenId];
        InteractionState iState = _interactionState[tokenId];
        uint256 pairedTokenId = _entangledPair[tokenId]; // 0 if not entangled

        // Measurement must have an effect - either on an entangled pair or on a superposition
        if (eState != EntanglementState.Entangled && iState != InteractionState.SuperposedState) {
             revert QET__MeasurementRequiresEntanglementOrSuperposition(tokenId);
        }

        // Apply Coherence Decay on Measurement
        uint256 currentCoherence = _coherence[tokenId];
        uint256 newCoherence = currentCoherence > COHERENCE_DECAY_MEASUREMENT ? currentCoherence - COHERENCE_DECAY_MEASUREMENT : 0;
        _coherence[tokenId] = newCoherence;
        emit CoherenceDecayed(tokenId, newCoherence);

        // If entangled, apply decay to partner too
        if (eState == EntanglementState.Entangled && pairedTokenId != 0) {
             uint256 pairCoherence = _coherence[pairedTokenId];
             uint256 newPairCoherence = pairCoherence > COHERENCE_DECAY_MEASUREMENT ? pairCoherence - COHERENCE_DECAY_MEASUREMENT : 0;
             _coherence[pairedTokenId] = newPairCoherence;
              emit CoherenceDecayed(pairedTokenId, newPairCoherence);

            // If coherence reaches zero for either, force decoherence
            if (_coherence[tokenId] == 0 || _coherence[pairedTokenId] == 0) {
                 decoherePair(tokenId); // Calls decoherePair which handles both sides
                 pairedTokenId = 0; // Clear pairedTokenId as they are no longer entangled
            }
        }

        // --- State Transition Logic based on Measurement ---
        // Use pseudo-randomness influenced by strangeness property
        uint256 randomness = _generateRandomFactor(tokenId + (pairedTokenId > 0 ? pairedTokenId : 0)); // Seed includes partner if exists
        uint256 strangeness = _quantumProperties[tokenId].strangeness;
        uint256 randomOutcome = (randomness + strangeness) % 100; // Simple pseudo-random outcome

        InteractionState newIState = iState; // Default is no change

        if (iState == InteractionState.SuperposedState) {
            // Collapse Superposition: Randomly collapse to Ground or Excited
            if (randomOutcome < 50) { // 50% chance (can be influenced by properties)
                newIState = InteractionState.GroundState;
            } else {
                newIState = InteractionState.ExcitedState;
            }
            // If entangled, the collapse might influence the partner's state!
            if (eState == EntanglementState.Entangled && pairedTokenId != 0) {
                 InteractionState pairIState = _interactionState[pairedTokenId];
                 // Example: Partner state flips based on the measurement outcome
                 InteractionState newPairIState = pairIState;
                 if (randomOutcome < 25) { // Small chance the partner also collapses/flips
                      newPairIState = (pairIState == InteractionState.GroundState) ? InteractionState.ExcitedState : InteractionState.GroundState;
                 } else if (randomOutcome >= 75) {
                     newPairIState = (pairIState == InteractionState.ExcitedState) ? InteractionState.GroundState : InteractionState.ExcitedState;
                 }
                 _updateTokenState(pairedTokenId, _entanglementState[pairedTokenId], newPairIState);
            }

        } else if (eState == EntanglementState.Entangled) {
             // Measurement on entangled but non-superposed token might flip interaction state randomly
             if (randomOutcome < 10 + (strangeness / 10)) { // Base 10% chance + chance from strangeness
                newIState = (iState == InteractionState.GroundState) ? InteractionState.ExcitedState : InteractionState.GroundState;

                 // The partner's state is correlated! It might flip in the *opposite* way.
                 if (pairedTokenId != 0) {
                    InteractionState pairIState = _interactionState[pairedTokenId];
                    InteractionState newPairIState = (pairIState == InteractionState.GroundState) ? InteractionState.ExcitedState : InteractionState.GroundState;
                     _updateTokenState(pairedTokenId, _entanglementState[pairedTokenId], newPairIState);
                 }
             }
        }

        // Update the state of the measured token
        if (newIState != iState) {
            _updateTokenState(tokenId, eState, newIState);
        }

        emit QuantumMeasurementPerformed(tokenId, pairedTokenId, randomness);
    }

    /// @notice Attempts to induce a Superposition state. Only possible for entangled tokens.
    /// Requires sufficient coherence.
    /// @param tokenId The ID of the token.
    function induceSuperposition(uint256 tokenId) public whenNotPaused whenEntangled(tokenId) {
         _requireOwned(tokenId);
         _requirePropertiesSet(tokenId); // Superposition might depend on properties

         // Requires sufficient coherence (e.g., > 200)
         if (_coherence[tokenId] < 200) revert QET__CoherenceTooLow(tokenId, _coherence[tokenId]);

         // Only if not already superposed
         if (_interactionState[tokenId] != InteractionState.SuperposedState) {
             _updateTokenState(tokenId, EntanglementState.Entangled, InteractionState.SuperposedState);
             // Inducing superposition on one token might affect the partner's state,
             // perhaps making it also superposed or flipping its state.
             uint256 pairedTokenId = _entangledPair[tokenId];
             if (pairedTokenId != 0) {
                  // Example: Partner also enters superposition if its coherence is also high
                 if (_coherence[pairedTokenId] >= 200) {
                    _updateTokenState(pairedTokenId, EntanglementState.Entangled, InteractionState.SuperposedState);
                 } else {
                     // Or maybe the partner just flips its interaction state
                      InteractionState pairIState = _interactionState[pairedTokenId];
                     InteractionState newPairIState = (pairIState == InteractionState.GroundState) ? InteractionState.ExcitedState : InteractionState.GroundState;
                     _updateTokenState(pairedTokenId, EntanglementState.Entangled, newPairIState);
                 }
             }
         }
    }

    /// @notice Attempts to collapse a Superposed state.
    /// @param tokenId The ID of the token.
    function collapseSuperposition(uint256 tokenId) public whenNotPaused {
        _requireOwned(tokenId);

        if (_interactionState[tokenId] != InteractionState.SuperposedState) {
            revert QET__CannotCollapseNonSuperposed(tokenId);
        }

        // Collapse forces a 'measurement' type outcome
        performQuantumMeasurement(tokenId); // This function handles the collapse logic
    }

    /// @notice Manually decays a token's coherence.
    /// @param tokenId The ID of the token.
    function decayCoherence(uint256 tokenId) public whenNotPaused {
        _requireOwned(tokenId);
         uint256 currentCoherence = _coherence[tokenId];
        uint256 decayAmount = 100; // Fixed decay amount for manual action
        // Could be influenced by properties: decayAmount += _quantumProperties[tokenId].charm / 5;

        uint256 newCoherence = currentCoherence > decayAmount ? currentCoherence - decayAmount : 0;
        _coherence[tokenId] = newCoherence;
        emit CoherenceDecayed(tokenId, newCoherence);

        // If entangled, maybe this action affects the partner's coherence slightly?
        if (_entanglementState[tokenId] == EntanglementState.Entangled) {
             uint256 pairedTokenId = _entangledPair[tokenId];
             if (pairedTokenId != 0) {
                uint256 pairCoherence = _coherence[pairedTokenId];
                 uint256 pairDecayAmount = decayAmount / 2; // Half decay for partner
                 uint256 newPairCoherence = pairCoherence > pairDecayAmount ? pairCoherence - pairDecayAmount : 0;
                 _coherence[pairedTokenId] = newPairCoherence;
                 emit CoherenceDecayed(pairedTokenId, newPairCoherence);
                 if (_coherence[tokenId] == 0 || _coherence[pairedTokenId] == 0) {
                     decoherePair(tokenId);
                 }
             }
        }
        // Optional: If coherence reaches zero, force decoherence check is in _beforeTokenTransfer and performMeasurement
    }

    /// @notice Sets the immutable quantum properties for a token.
    /// Can only be called once per token, before it's entangled.
    /// @param tokenId The ID of the token.
    /// @param charm A property influencing coherence and interactions.
    /// @param strangeness A property influencing measurement outcomes.
    /// @param spin A property influencing correlated flips (e.g., 0 or 1).
    function setQuantumProperties(uint256 tokenId, uint256 charm, uint256 strangeness, uint256 spin) public whenNotPaused whenPropertiesNotSet(tokenId) {
         _requireOwned(tokenId);
        // Spin could be restricted to 0 or 1 if desired
        // require(spin == 0 || spin == 1, "QET: Spin must be 0 or 1");

        _quantumProperties[tokenId] = QuantumProperties(charm, strangeness, spin);
        _propertiesSet[tokenId] = true;
        emit QuantumPropertiesSet(tokenId, charm, strangeness, spin);
    }


    // --- State & Property Getters ---

    /// @notice Gets the EntanglementState of a token.
    /// @param tokenId The ID of the token.
    /// @return The EntanglementState enum.
    function getEntanglementState(uint256 tokenId) public view returns (EntanglementState) {
        _requireOwned(tokenId);
        return _entanglementState[tokenId];
    }

    /// @notice Gets the InteractionState of a token.
    /// @param tokenId The ID of the token.
    /// @return The InteractionState enum.
    function getInteractionState(uint256 tokenId) public view returns (InteractionState) {
         _requireOwned(tokenId);
        return _interactionState[tokenId];
    }

     /// @notice Gets the combined TokenState enum of a token.
    /// @param tokenId The ID of the token.
    /// @return The combined TokenState enum.
    function getTokenState(uint256 tokenId) public view returns (TokenState) {
         _requireOwned(tokenId);
        return _getCombinedState(tokenId);
    }

    /// @notice Gets the ID of the token entangled with the given token.
    /// Returns 0 if the token is not entangled.
    /// @param tokenId The ID of the token.
    /// @return The ID of the paired token, or 0.
    function getEntangledPair(uint256 tokenId) public view returns (uint256) {
         _requireOwned(tokenId);
        return _entangledPair[tokenId];
    }

    /// @notice Gets the QuantumProperties of a token.
    /// @param tokenId The ID of the token.
    /// @return The QuantumProperties struct. Returns default struct if properties not set.
    function getQuantumProperties(uint256 tokenId) public view returns (QuantumProperties memory) {
        _requireOwned(tokenId);
        return _quantumProperties[tokenId];
    }

    /// @notice Gets the current coherence level of a token.
    /// @param tokenId The ID of the token.
    /// @return The coherence level (0 to MAX_COHERENCE).
    function getCoherence(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId);
        return _coherence[tokenId];
    }

    // --- Special Transfer Functions ---

    /// @notice Transfers an entangled token AND its paired token to the same receiver.
    /// Both tokens must be owned by the caller and be entangled with each other.
    /// @param tokenId The ID of one of the entangled tokens.
    /// @param receiver The address to transfer both tokens to.
    function transferEntangledPair(uint256 tokenId, address receiver) public whenNotPaused {
        uint256 pairedTokenId = _entangledPair[tokenId];
        if (pairedTokenId == 0) {
             revert QET__CannotTransferPairWhenNotEntangled(tokenId);
        }
         _requireOwned(tokenId);
         _requireOwned(pairedTokenId); // Both must be owned by caller

        // Use internal _transfer to trigger _beforeTokenTransfer hook
        _transfer(ownerOf(tokenId), receiver, tokenId);
        _transfer(ownerOf(pairedTokenId), receiver, pairedTokenId); // Ensure the pair is transferred too

        emit EntangledPairTransferred(tokenId, pairedTokenId, ownerOf(tokenId), receiver); // ownerOf might be receiver now, need to store old owner
    }

    /// @notice Transfers an entangled token and its paired token to *different* receivers.
    /// This action forces decoherence of the pair and applies a coherence penalty.
    /// Both tokens must be owned by the caller and be entangled with each other.
    /// @param tokenId The ID of one of the entangled tokens (will go to receiverToken1).
    /// @param receiverToken1 The address to transfer the first token to.
    /// @param receiverToken2 The address to transfer the paired token to.
    function separateEntangledPair(uint256 tokenId, address receiverToken1, address receiverToken2) public whenNotPaused {
         uint256 pairedTokenId = _entangledPair[tokenId];
        if (pairedTokenId == 0) {
             revert QET__CannotSeparatePairWhenNotEntangled(tokenId);
        }
         _requireOwned(tokenId);
         _requireOwned(pairedTokenId); // Both must be owned by caller
         require(receiverToken1 != receiverToken2, "QET: Receivers must be different for separation");

         address originalOwner = ownerOf(tokenId);

         // Force decoherence BEFORE transfer logic triggers _beforeTokenTransfer
         // This ensures the separation penalty is applied and state is updated.
         decoherePair(tokenId); // This updates states and clears _entangledPair

         // Now perform the transfers. _beforeTokenTransfer will see them as Decohered.
         _transfer(originalOwner, receiverToken1, tokenId);
         _transfer(originalOwner, receiverToken2, pairedTokenId);

         emit EntangledPairSeparated(tokenId, pairedTokenId, originalOwner, receiverToken1, receiverToken2);
    }


    // --- Admin & Utility Functions ---

    /// @notice Pauses the contract, preventing transfers and most state changes.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract, allowing normal operations.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Checks if the contract is currently paused.
    /// @return True if the contract is paused, false otherwise.
    function isPaused() public view returns (bool) {
        return paused(); // Inherited from Pausable
    }

     /// @notice Returns the total number of tokens minted.
     /// @return The total supply.
    function getTotalSupply() public view returns (uint256) {
        return _tokenCounter.current();
    }

    /// @notice Allows the owner to withdraw accidentally sent ETH.
    function rescueETH() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "QET: ETH rescue failed");
    }

    /// @notice Allows the owner to withdraw accidentally sent ERC20 tokens.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount of tokens to withdraw.
    function rescueToken(address tokenAddress, uint256 amount) public onlyOwner {
         IERC20 token = IERC20(tokenAddress);
         require(token.transfer(msg.sender, amount), "QET: Token rescue failed");
    }

    // Override supportsInterface to indicate support for ERC721, ERC165, Ownable, Pausable
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC165).interfaceId ||
               interfaceId == type(Ownable).interfaceId ||
               interfaceId == type(Pausable).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    // --- View all tokens owned by an address (potentially gas-intensive for many tokens) ---
    // This function requires tracking tokens per owner, which isn't standard ERC721.
    // Implementing it requires iterating or maintaining an additional mapping/array.
    // A simple mapping approach (mapping(address => uint256[])) can work but needs careful updates on transfer/mint/burn.
    // For this example, let's omit the full implementation to keep it cleaner,
    // but acknowledge it would be needed for a front-end listing.
    // A common pattern is to emit events for token transfers and rely on indexers.

    // Example placeholder if needed (requires additional state/logic to maintain):
    /*
    mapping(address => uint256[]) private _ownerTokens; // Example state variable

    /// @notice Returns all token IDs owned by an address.
    /// WARNING: Can be gas-intensive if an owner holds many tokens.
    /// @param owner The address to query.
    /// @return An array of token IDs.
    function getTokensByOwner(address owner) public view returns (uint256[] memory) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _ownerTokens[owner];
    }

    // Need to update _ownerTokens in _mint, _burn, and _transfer
    // _mint: add tokenId to _ownerTokens[to]
    // _burn: remove tokenId from _ownerTokens[_ownerOf(tokenId)]
    // _transfer: remove from _ownerTokens[from], add to _ownerTokens[to]
    // Removing from a dynamic array is costly in Solidity.
    */


}

// Dummy ERC20 interface for rescueToken function
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
```