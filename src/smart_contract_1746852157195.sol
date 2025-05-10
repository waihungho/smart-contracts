Okay, this is a fun challenge! Let's create a concept around "Quantum Entangled NFTs" (QENFTs). This uses quantum mechanics concepts like entanglement, superposition, and observation as metaphors for NFT state manipulation and interaction.

**Concept:**
QENFTs are NFTs that can exist in different "quantum states" (e.g., Ground, Excited, Superposition). Two QENFTs can become "entangled", meaning their states are linked. When an entangled NFT in "Superposition" is "observed", its state collapses to either Ground or Excited, and its entangled partner's state *instantaneously* collapses to a correlated state (anti-correlated in this example, like quantum spin). Other operations ("quantum gates") can affect the probabilities or properties while in superposition before observation.

This provides a rich set of interactions:
1.  **Minting:** Creating QENFTs.
2.  **Entanglement:** Linking pairs of QENFTs.
3.  **State Manipulation:** Putting NFTs into superposition, applying "gates" (metaphorical), and observing/collapsing states.
4.  **Decoherence:** Breaking entanglement.
5.  **Dynamic Properties:** Energy/phase can change based on state changes or observations.
6.  **Standard NFT Operations:** Transfer, approval, burning.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title QuantumEntangledNFTs
 * @dev An advanced ERC721 contract simulating Quantum Entanglement and Superposition
 *      using state transitions and correlated outcomes upon 'observation'.
 *      Note: This uses quantum mechanics as a *metaphor*. It does not involve
 *      actual quantum computation. The 'randomness' for state collapse uses
 *      block data, which is NOT cryptographically secure for high-value
 *      applications and can be manipulated by miners/validators.
 */
contract QuantumEntangledNFTs is ERC721, Ownable, Pausable, ReentrancyGuard {

    // --- Outline and Function Summary ---
    //
    // I. Core State & Data Structures:
    //    - QuantumState: Enum for state (Ground, Excited, Superposition)
    //    - Mappings to store state, entanglement, partner, energy, phase, etc.
    //    - Entanglement request tracking.
    //
    // II. ERC721 Standard Functions (8 functions + overrides):
    //     - constructor: Initializes contract.
    //     - supportsInterface: Standard ERC165.
    //     - balanceOf: Get owner's token count.
    //     - ownerOf: Get token owner.
    //     - getApproved: Get approved address for token.
    //     - isApprovedForAll: Check operator approval.
    //     - approve: Approve address for token.
    //     - setApprovalForAll: Set operator approval.
    //     - transferFrom: Transfer token (breaks entanglement).
    //     - safeTransferFrom (x2 overloads): Safe transfer token (breaks entanglement).
    //     - _beforeTokenTransfer: Internal hook to handle entanglement on transfer.
    //     - tokenURI: Get metadata URI (dynamic based on state).
    //
    // III. Quantum State Management (8 functions):
    //      - getQuantumState: Get the current state of a token.
    //      - applyHadamard: Put a token (and partner if entangled) into Superposition.
    //      - observeState: Collapse a token (and partner) from Superposition to Ground/Excited.
    //      - applyPauliX: Apply a NOT gate metaphorically in Superposition (flips outcome bias).
    //      - applyPauliZ: Apply a phase flip metaphorically in Superposition (changes phase).
    //      - applyCNOT: Apply a Controlled-NOT gate metaphorically based on an entangled partner's observed state.
    //      - getLastObservedBlock: Get the block number of the last state observation.
    //      - isInSuperposition: Check if a token is in Superposition.
    //
    // IV. Entanglement Management (6 functions):
    //     - isQuantumEntangled: Check if a token is entangled.
    //     - getEntangledPartner: Get the partner's ID if entangled.
    //     - requestEntanglement: Propose entanglement between two tokens.
    //     - acceptEntanglement: Accept a proposed entanglement.
    //     - rejectEntanglement: Reject a proposed entanglement.
    //     - breakEntanglement: Forcefully break an entanglement link (collapses state).
    //
    // V. Dynamic Property Management (5 functions):
    //    - getEnergy: Get a token's current energy level.
    //    - changeEnergy: Manually change a token's energy (owner only, or conditional).
    //    - getPhase: Get a token's current phase value.
    //    - changePhase: Manually change a token's phase (owner only, or conditional).
    //    - updatePropertiesOnObservation: Internal helper to update energy/phase after observation.
    //
    // VI. Token Lifecycle & Admin (5 functions):
    //     - mintQENFT: Mint a new Quantum Entangled NFT.
    //     - burnQENFT: Burn an NFT (breaks entanglement).
    //     - setBaseURI: Set the base URI for metadata.
    //     - pause: Pause transfers and certain operations.
    //     - unpause: Unpause contract.
    //
    // VII. Helper Functions:
    //      - _generatePseudoRandomness: Internal helper for pseudo-random number generation (CAUTION: not secure).
    //      - _setQuantumState: Internal helper to update state and emit event.
    //      - _processObservation: Internal core logic for state collapse.
    //      - _entanglePair: Internal helper to link two tokens.
    //      - _decoherePair: Internal helper to unlink two tokens and collapse state.
    //      - _validateEntangledPair: Internal helper to check if two tokens are valid entangled partners.
    //      - _getTokenOwner: Internal helper to get owner.

    // --- End Outline and Function Summary ---


    enum QuantumState { Ground, Excited, Superposition }

    // Core Quantum State
    mapping(uint256 => QuantumState) private _quantumState;
    // Whether the token is entangled
    mapping(uint256 => bool) private _isEntangled;
    // The ID of the entangled partner token (0 if not entangled)
    mapping(uint256 => uint256) private _entangledPartnerId;
    // Dynamic properties
    mapping(uint256 => uint256) private _energy;
    mapping(uint256 => bytes32) private _phase; // Represents phase, can be any bytes32 value
    // Keep track of the block number when observation last occurred
    mapping(uint256 => uint256) private _lastObservedBlock;

    // Metaphorical state biases/flags for Superposition operations
    mapping(uint256 => bool) private _superpositionPauliXFlip; // Tracks effect of PauliX gate metaphor
    mapping(uint256 => bool) private _superpositionPauliZFlip; // Tracks effect of PauliZ gate metaphor

    // Track pending entanglement requests: requesterId => targetId => exists
    mapping(uint256 => mapping[uint256 => bool]) private _entanglementRequests;

    // Counter for token IDs
    uint256 private _nextTokenId;

    // Base URI for metadata
    string private _baseTokenURI;

    // --- Events ---
    event QuantumStateChanged(uint256 indexed tokenId, QuantumState newState, uint256 indexed blockNumber);
    event TokensEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed blockNumber);
    event TokensDecohered(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed blockNumber);
    event StateObserved(uint256 indexed tokenId, QuantumState finalState, uint256 indexed blockNumber);
    event GateApplied(uint256 indexed tokenId, string gateType, uint256 indexed blockNumber);
    event EnergyChanged(uint256 indexed tokenId, uint256 newEnergy);
    event PhaseChanged(uint256 indexed tokenId, bytes32 newPhase);
    event EntanglementRequested(uint256 indexed requesterId, uint256 indexed targetId);
    event EntanglementAccepted(uint256 indexed requesterId, uint256 indexed targetId);
    event EntanglementRejected(uint256 indexed requesterId, uint256 indexed targetId);

    // --- Errors ---
    error InvalidTokenId(uint256 tokenId);
    error AlreadyExists(uint256 tokenId);
    error NotOwnerOrApproved(uint256 tokenId);
    error MustBeInState(uint256 tokenId, QuantumState requiredState);
    error CannotBeInState(uint256 tokenId, QuantumState forbiddenState);
    error AlreadyEntangled(uint256 tokenId);
    error NotEntangled(uint256 tokenId);
    error NotEntangledWithPartner(uint256 tokenId1, uint256 tokenId2);
    error EntanglementRequestNotFound(uint256 requesterId, uint256 targetId);
    error NotEntanglementRequester(uint256 requesterId);
    error NotEntanglementTarget(uint256 targetId);
    error DifferentOwners(); // For entanglement operations
    error SameTokenId(); // For entanglement operations
    error InvalidPartnerId(); // For operations requiring a specific partner

    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory baseURI)
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable()
    {
        _baseTokenURI = baseURI;
    }

    // --- ERC721 Standard Functions Overrides & Helpers ---

    // @dev Overrides the ERC721 _beforeTokenTransfer hook
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Decohering upon transfer is a simplified approach.
        // A more complex model might require transferring entangled pairs together.
        if (_isEntangled[tokenId]) {
             // Need to check if 'from' actually owns the token being transferred
            if (from != address(0)) { // Only break entanglement on actual transfer, not minting
                uint256 partnerId = _entangledPartnerId[tokenId];
                 // Ensure the partner hasn't been transferred or burned already in the same batch (less likely with batchSize 1 but good practice)
                if (_exists(partnerId) && _isEntangled[partnerId] && _entangledPartnerId[partnerId] == tokenId) {
                    _decoherePair(tokenId, partnerId);
                } else {
                     // This case might happen if the partner was burned or transferred first
                     // Just clear the state for the current token
                    _isEntangled[tokenId] = false;
                    _entangledPartnerId[tokenId] = 0;
                    emit TokensDecohered(tokenId, partnerId, block.number);
                     // Collapse state if in superposition upon forced decoherence
                    if (_quantumState[tokenId] == QuantumState.Superposition) {
                         _processObservation(tokenId);
                    }
                }
            }
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
        // In a real Dapp, this URI would point to a service returning dynamic metadata
        // based on the token's current state (_quantumState, _energy, _phase, _isEntangled, etc.)
        string memory base = _baseTokenURI;
        return string(abi.encodePacked(base, _toString(tokenId)));
    }

    // Override _burn to handle entanglement
    function _burn(uint256 tokenId) internal override {
        if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
        if (_isEntangled[tokenId]) {
            uint256 partnerId = _entangledPartnerId[tokenId];
             // Ensure partner exists and is still entangled with this token
            if (_exists(partnerId) && _isEntangled[partnerId] && _entangledPartnerId[partnerId] == tokenId) {
                _decoherePair(tokenId, partnerId);
            } else {
                 // Clear state for this token if partner already gone
                _isEntangled[tokenId] = false;
                _entangledPartnerId[tokenId] = 0;
                // No need to emit TokensDecohered with a non-existent partner
                 // Collapse state if in superposition upon forced decoherence
                if (_quantumState[tokenId] == QuantumState.Superposition) {
                     _processObservation(tokenId);
                }
            }
        }
        super._burn(tokenId);
        // Clear all state associated with the burned token
        delete _quantumState[tokenId];
        delete _energy[tokenId];
        delete _phase[tokenId];
        delete _lastObservedBlock[tokenId];
        delete _superpositionPauliXFlip[tokenId];
        delete _superpositionPauliZFlip[tokenId];
         // Clear any pending requests involving this token
        delete _entanglementRequests[tokenId];
        for (uint256 i = 1; i < _nextTokenId; i++) {
             if (_entanglementRequests[i][tokenId]) {
                 delete _entanglementRequests[i][tokenId];
             }
        }
    }

    // Expose burn functionality
    function burnQENFT(uint256 tokenId) public virtual nonReentrant whenNotPaused {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert NotOwnerOrApproved(tokenId);
        }
        _burn(tokenId);
    }

    // --- Quantum State Management (8 functions) ---

    function getQuantumState(uint256 tokenId) public view returns (QuantumState) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
        return _quantumState[tokenId];
    }

    // @dev Puts the token (and its entangled partner) into Superposition.
    // Requires state to be Ground or Excited.
    function applyHadamard(uint256 tokenId) public virtual nonReentrant whenNotPaused {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert NotOwnerOrApproved(tokenId);
        }
        QuantumState currentState = _quantumState[tokenId];
        if (currentState != QuantumState.Ground && currentState != QuantumState.Excited) {
            revert MustBeInState(tokenId, QuantumState.Ground); // Or Excited
        }

        _setQuantumState(tokenId, QuantumState.Superposition);
        _superpositionPauliXFlip[tokenId] = false; // Reset bias on entering superposition
        _superpositionPauliZFlip[tokenId] = false; // Reset phase bias on entering superposition
        emit GateApplied(tokenId, "Hadamard", block.number);

        if (_isEntangled[tokenId]) {
            uint256 partnerId = _entangledPartnerId[tokenId];
             // Apply Hadamard to partner if entangled and they are not already in superposition
             // Ensure partner exists and is entangled with this token
            if (_exists(partnerId) && _isEntangled[partnerId] && _entangledPartnerId[partnerId] == tokenId && _quantumState[partnerId] != QuantumState.Superposition) {
                 _setQuantumState(partnerId, QuantumState.Superposition);
                 _superpositionPauliXFlip[partnerId] = false;
                 _superpositionPauliZFlip[partnerId] = false;
                 emit GateApplied(partnerId, "Hadamard", block.number);
            }
        }
    }

     // @dev Collapses the token (and its entangled partner) from Superposition to Ground or Excited.
     // The outcome is pseudo-randomly determined, with bias potentially affected by gates.
    function observeState(uint256 tokenId) public virtual nonReentrant whenNotPaused {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert NotOwnerOrApproved(tokenId);
        }
        if (_quantumState[tokenId] != QuantumState.Superposition) {
            revert MustBeInState(tokenId, QuantumState.Superposition);
        }

        _processObservation(tokenId);
    }

    // @dev Applies a Pauli-X (NOT) gate metaphorically while in Superposition.
    // Flips the potential outcome bias upon subsequent observation.
    // Requires state to be Superposition.
    function applyPauliX(uint256 tokenId) public virtual nonReentrant whenNotPaused {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert NotOwnerOrApproved(tokenId);
        }
        if (_quantumState[tokenId] != QuantumState.Superposition) {
            revert MustBeInState(tokenId, QuantumState.Superposition);
        }
        _superpositionPauliXFlip[tokenId] = !_superpositionPauliXFlip[tokenId];
        emit GateApplied(tokenId, "Pauli-X", block.number);
    }

     // @dev Applies a Pauli-Z (Phase) gate metaphorically while in Superposition.
     // Affects the phase property upon subsequent observation/collapse.
     // Requires state to be Superposition.
    function applyPauliZ(uint256 tokenId) public virtual nonReentrant whenNotPaused {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert NotOwnerOrApproved(tokenId);
        }
        if (_quantumState[tokenId] != QuantumState.Superposition) {
            revert MustBeInState(tokenId, QuantumState.Superposition);
        }
        _superpositionPauliZFlip[tokenId] = !_superpositionPauliZFlip[tokenId];
        emit GateApplied(tokenId, "Pauli-Z", block.number);
    }

    // @dev Applies a Controlled-NOT gate metaphorically.
    // If controlId's *observed* state is Excited, applies Pauli-X effect to targetId *if* targetId is in Superposition and entangled.
    // Requires targetId to be entangled with controlId.
    function applyCNOT(uint256 controlId, uint256 targetId) public virtual nonReentrant whenNotPaused {
         // Require sender owns/is approved for BOTH tokens
        if (!_isApprovedOrOwner(msg.sender, controlId) && !_isApprovedOrOwner(msg.sender, targetId)) {
             revert NotOwnerOrApproved(controlId); // Or targetId, doesn't matter which for error
        }
         // If different owners, requires both owners to trigger? Or requires one owner to be approved for the other's token?
         // Let's require sender is approved or owner of *both* for simplicity in this example.
        if (!_isApprovedOrOwner(msg.sender, controlId) || !_isApprovedOrOwner(msg.sender, targetId)) {
             revert NotOwnerOrApproved(controlId);
        }
        if (controlId == targetId) {
            revert SameTokenId();
        }
        if (!_exists(controlId)) { revert InvalidTokenId(controlId); }
        if (!_exists(targetId)) { revert InvalidTokenId(targetId); }

        // Control must have an observed state (not Superposition)
        if (_quantumState[controlId] == QuantumState.Superposition) {
             revert CannotBeInState(controlId, QuantumState.Superposition);
        }
        // Target must be in Superposition and entangled with control
        if (_quantumState[targetId] != QuantumState.Superposition) {
            revert MustBeInState(targetId, QuantumState.Superposition);
        }
        if (!_isEntangled[targetId] || _entangledPartnerId[targetId] != controlId) {
            revert NotEntangledWithPartner(targetId, controlId);
        }

        // Check control state and apply Pauli-X effect to target if Excited
        if (_quantumState[controlId] == QuantumState.Excited) {
            _superpositionPauliXFlip[targetId] = !_superpositionPauliXFlip[targetId];
             // No need to flip control's bias as it's not in superposition
            emit GateApplied(targetId, "Controlled-NOT (Target)", block.number);
        }
         emit GateApplied(controlId, "Controlled-NOT (Control)", block.number); // Still emit for control
    }

    function getLastObservedBlock(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
        return _lastObservedBlock[tokenId];
    }

    function isInSuperposition(uint256 tokenId) public view returns (bool) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
        return _quantumState[tokenId] == QuantumState.Superposition;
    }


    // --- Entanglement Management (6 functions) ---

    function isQuantumEntangled(uint256 tokenId) public view returns (bool) {
         if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
        return _isEntangled[tokenId];
    }

     function getEntangledPartner(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
        return _entangledPartnerId[tokenId];
    }

     // @dev Owner of requesterId proposes entanglement with targetId.
     // Requires both tokens to exist and not be entangled.
    function requestEntanglement(uint256 requesterId, uint256 targetId) public virtual nonReentrant whenNotPaused {
        if (!_isApprovedOrOwner(msg.sender, requesterId)) {
            revert NotOwnerOrApproved(requesterId);
        }
        if (!_exists(targetId)) {
            revert InvalidTokenId(targetId);
        }
        if (requesterId == targetId) {
            revert SameTokenId();
        }
        if (_isEntangled[requesterId]) {
            revert AlreadyEntangled(requesterId);
        }
        if (_isEntangled[targetId]) {
            revert AlreadyEntangled(targetId);
        }
         // Ensure the target owner needs to accept
        if (_getTokenOwner(requesterId) == _getTokenOwner(targetId)) {
             // If same owner, they can just call acceptEntanglement directly or handle off-chain
             // For distinct owners, request/accept flow is needed.
             // Let's still allow request for consistency, but acceptance will be immediate if owner == owner.
        }

        _entanglementRequests[requesterId][targetId] = true;
        emit EntanglementRequested(requesterId, targetId);
    }

     // @dev Owner of targetId accepts the entanglement request from requesterId.
     // Requires a pending request and both tokens to be unentangled.
    function acceptEntanglement(uint256 requesterId, uint256 targetId) public virtual nonReentrant whenNotPaused {
        if (!_isApprovedOrOwner(msg.sender, targetId)) {
            revert NotOwnerOrApproved(targetId);
        }
         if (!_exists(requesterId)) {
             revert InvalidTokenId(requesterId);
         }
         if (requesterId == targetId) {
             revert SameTokenId();
         }
        if (!_entanglementRequests[requesterId][targetId]) {
            revert EntanglementRequestNotFound(requesterId, targetId);
        }
         if (_isEntangled[requesterId]) {
             revert AlreadyEntangled(requesterId);
         }
         if (_isEntangled[targetId]) {
             revert AlreadyEntangled(targetId);
         }
         // Owners must be distinct for the request/accept flow, otherwise accept directly?
         // Let's allow acceptance by *either* owner, but require the target owner's permission check above.
         // A simpler model is just `msg.sender` must be the owner/approved of `targetId`.

        delete _entanglementRequests[requesterId][targetId];
        _entanglePair(requesterId, targetId);
        emit EntanglementAccepted(requesterId, targetId);
    }

     // @dev Owner of targetId rejects the entanglement request from requesterId.
    function rejectEntanglement(uint256 requesterId, uint256 targetId) public virtual nonReentrant whenNotPaused {
        if (!_isApprovedOrOwner(msg.sender, targetId)) {
            revert NotOwnerOrApproved(targetId);
        }
        if (!_entanglementRequests[requesterId][targetId]) {
            revert EntanglementRequestNotFound(requesterId, targetId);
        }

        delete _entanglementRequests[requesterId][targetId];
        emit EntanglementRejected(requesterId, targetId);
    }

     // @dev Breaks the entanglement link between two tokens.
     // Can be called by the owner of either token or approved address.
     // Collapses the state of both tokens if they were in Superposition.
    function breakEntanglement(uint256 tokenId1, uint256 tokenId2) public virtual nonReentrant whenNotPaused {
        // Check ownership/approval for at least one token
         if (!_isApprovedOrOwner(msg.sender, tokenId1) && !_isApprovedOrOwner(msg.sender, tokenId2)) {
             revert NotOwnerOrApproved(tokenId1);
         }
         if (tokenId1 == tokenId2) {
             revert SameTokenId();
         }
        // Validate they are actually entangled with each other
        _validateEntangledPair(tokenId1, tokenId2);

        _decoherePair(tokenId1, tokenId2);
    }


    // --- Dynamic Property Management (5 functions) ---

    function getEnergy(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
        return _energy[tokenId];
    }

    // @dev Change the energy level of a token.
    // Could be based on gameplay, staking, state changes, etc.
    // Simple version: owner/approved can change it.
    function changeEnergy(uint256 tokenId, uint256 newEnergy) public virtual nonReentrant whenNotPaused {
         if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert NotOwnerOrApproved(tokenId);
        }
        _energy[tokenId] = newEnergy;
        emit EnergyChanged(tokenId, newEnergy);
    }

    function getPhase(uint256 tokenId) public view returns (bytes32) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
        return _phase[tokenId];
    }

     // @dev Change the phase value of a token.
     // Could be affected by Pauli-Z or observation outcomes.
     // Simple version: owner/approved can change it.
    function changePhase(uint256 tokenId, bytes32 newPhase) public virtual nonReentrant whenNotPaused {
         if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert NotOwnerOrApproved(tokenId);
        }
        _phase[tokenId] = newPhase;
        emit PhaseChanged(tokenId, newPhase);
    }

    // Internal helper to update properties after observation.
    // Can add more complex logic here (e.g., energy +/- based on state transition).
    function _updatePropertiesOnObservation(uint256 tokenId, QuantumState finalState) internal {
         // Example: Gain energy when entering Excited state, lose energy entering Ground.
         if (finalState == QuantumState.Excited) {
             _energy[tokenId] = _energy[tokenId] + 10; // Arbitrary amount
         } else { // Ground state
              if (_energy[tokenId] >= 5) {
                 _energy[tokenId] = _energy[tokenId] - 5; // Arbitrary amount
              } else {
                  _energy[tokenId] = 0;
              }
         }

         // Example: Phase flip if PauliZ was applied in superposition AND state collapsed to Excited
         if (_superpositionPauliZFlip[tokenId] && finalState == QuantumState.Excited) {
             _phase[tokenId] = bytes32(~uint256(_phase[tokenId])); // Bitwise NOT as a phase flip metaphor
         }
         // Clear the flip flag after observation regardless of outcome
         _superpositionPauliZFlip[tokenId] = false;


         emit EnergyChanged(tokenId, _energy[tokenId]);
         emit PhaseChanged(tokenId, _phase[tokenId]);
    }


    // --- Token Lifecycle & Admin (5 functions) ---

    function mintQENFT(address to, uint256 initialEnergy, bytes32 initialPhase) public virtual onlyOwner nonReentrant {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);

        // Initialize state as Ground upon minting
        _setQuantumState(tokenId, QuantumState.Ground);
        _isEntangled[tokenId] = false;
        _entangledPartnerId[tokenId] = 0; // 0 indicates no partner
        _energy[tokenId] = initialEnergy;
        _phase[tokenId] = initialPhase;
        _lastObservedBlock[tokenId] = block.number; // Assume initial state is "observed"
         _superpositionPauliXFlip[tokenId] = false;
         _superpositionPauliZFlip[tokenId] = false;
    }

    function setBaseURI(string memory baseURI) public virtual onlyOwner {
        _baseTokenURI = baseURI;
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }


    // --- Internal Helper Functions ---

    // @dev Sets the quantum state and emits the event.
    function _setQuantumState(uint256 tokenId, QuantumState newState) internal {
        _quantumState[tokenId] = newState;
        emit QuantumStateChanged(tokenId, newState, block.number);
    }

     // @dev Internal logic for state collapse upon observation or decoherence.
    function _processObservation(uint256 tokenId) internal {
        if (_quantumState[tokenId] != QuantumState.Superposition) {
             // Should ideally not happen if called correctly, but defensive check.
             return;
        }

        uint256 partnerId = _entangledPartnerId[tokenId];
        bool isEntangledPair = _isEntangled[tokenId] && _exists(partnerId) && _isEntangled[partnerId] && _entangledPartnerId[partnerId] == tokenId;

        // Use pseudo-randomness for state collapse outcome
        uint256 randomNumber = _generatePseudoRandomness(tokenId);

        QuantumState finalStateToken;
        QuantumState finalStatePartner = QuantumState.Ground; // Default for partner

        // Determine the state based on randomness and PauliX bias
        // If _superpositionPauliXFlip is true, it inverts the outcome probability (metaphorically)
        bool outcome = (randomNumber % 100 < 50); // Base 50/50 chance

        if (_superpositionPauliXFlip[tokenId]) {
             outcome = !outcome; // Flip the outcome
        }

        finalStateToken = outcome ? QuantumState.Excited : QuantumState.Ground;

        // If entangled, the partner's state is ANTI-CORRELATED
        if (isEntangledPair) {
             // Partner's outcome is the opposite of the current token's *unflipped* outcome (before applying PauliX bias to tokenId)
             // This simulates entanglement correlation independent of local gate applications
             bool partnerOutcome = (randomNumber % 100 < 50); // Same base random source
             partnerOutcome = !partnerOutcome; // Anti-correlated

             // Apply PauliX bias to partner IF it also had PauliX applied while in superposition
            if (_superpositionPauliXFlip[partnerId]) {
                 partnerOutcome = !partnerOutcome;
            }

            finalStatePartner = partnerOutcome ? QuantumState.Excited : QuantumState.Ground;

            // Ensure anti-correlation is enforced strictly by the source random number if needed for the metaphor
            // For this example, let's enforce the simple anti-correlation:
            finalStatePartner = (finalStateToken == QuantumState.Ground) ? QuantumState.Excited : QuantumState.Ground;

        }

        // Update states
        _setQuantumState(tokenId, finalStateToken);
        emit StateObserved(tokenId, finalStateToken, block.number);
        _lastObservedBlock[tokenId] = block.number;
         // Clear flip flags after observation
        _superpositionPauliXFlip[tokenId] = false;


        if (isEntangledPair) {
            _setQuantumState(partnerId, finalStatePartner);
            emit StateObserved(partnerId, finalStatePartner, block.number);
            _lastObservedBlock[partnerId] = block.number;
             // Clear partner's flip flags too after joint observation
            _superpositionPauliXFlip[partnerId] = false;
             _superpositionPauliZFlip[partnerId] = false; // Also clear Z flip
        } else {
             // If not entangled, clear the current token's Z flip flag
             _superpositionPauliZFlip[tokenId] = false;
        }


        // Update dynamic properties based on new state
        _updatePropertiesOnObservation(tokenId, finalStateToken);
         if (isEntangledPair) {
             _updatePropertiesOnObservation(partnerId, finalStatePartner);
         }
    }

    // @dev Links two tokens as entangled partners. Internal use.
    function _entanglePair(uint256 tokenId1, uint256 tokenId2) internal {
         if (!_exists(tokenId1)) { revert InvalidTokenId(tokenId1); }
         if (!_exists(tokenId2)) { revert InvalidTokenId(tokenId2); }
         if (tokenId1 == tokenId2) { revert SameTokenId(); }
         if (_isEntangled[tokenId1]) { revert AlreadyEntangled(tokenId1); }
         if (_isEntangled[tokenId2]) { revert AlreadyEntangled(tokenId2); }
         if (_getTokenOwner(tokenId1) != _getTokenOwner(tokenId2)) {
              // For simplicity, require same owner to entangle directly
              // The request/accept flow handles distinct owners
              revert DifferentOwners();
         }

        _isEntangled[tokenId1] = true;
        _entangledPartnerId[tokenId1] = tokenId2;
        _isEntangled[tokenId2] = true;
        _entangledPartnerId[tokenId2] = tokenId1;
        emit TokensEntangled(tokenId1, tokenId2, block.number);

         // Put both into superposition upon entanglement, ready for observation
        if (_quantumState[tokenId1] != QuantumState.Superposition) {
             _setQuantumState(tokenId1, QuantumState.Superposition);
             _superpositionPauliXFlip[tokenId1] = false;
             _superpositionPauliZFlip[tokenId1] = false;
        }
        if (_quantumState[tokenId2] != QuantumState.Superposition) {
            _setQuantumState(tokenId2, QuantumState.Superposition);
            _superpositionPauliXFlip[tokenId2] = false;
            _superpositionPauliZFlip[tokenId2] = false;
        }
    }

     // @dev Breaks the entanglement link between two tokens. Internal use.
     // Assumes tokens are valid and entangled with each other.
    function _decoherePair(uint256 tokenId1, uint256 tokenId2) internal {
        // Validate they are actually entangled with each other
        _validateEntangledPair(tokenId1, tokenId2); // Double check

        _isEntangled[tokenId1] = false;
        _entangledPartnerId[tokenId1] = 0;
        _isEntangled[tokenId2] = false;
        _entangledPartnerId[tokenId2] = 0;
        emit TokensDecohered(tokenId1, tokenId2, block.number);

        // Decoherence collapses superposition.
        if (_quantumState[tokenId1] == QuantumState.Superposition) {
            _processObservation(tokenId1); // Process observation/collapse for token1 (will also handle token2 if still entangled)
        } else if (_quantumState[tokenId2] == QuantumState.Superposition) {
             _processObservation(tokenId2); // Process observation/collapse for token2 (will also handle token1 if still entangled)
        }
         // If neither was in superposition, no state collapse needed by decoherence.
    }

     // @dev Internal helper to validate if two tokens are valid and entangled with each other.
    function _validateEntangledPair(uint256 tokenId1, uint256 tokenId2) internal view {
        if (!_exists(tokenId1)) { revert InvalidTokenId(tokenId1); }
        if (!_exists(tokenId2)) { revert InvalidTokenId(tokenId2); }
        if (tokenId1 == tokenId2) { revert SameTokenId(); }
        if (!_isEntangled[tokenId1] || !_isEntangled[tokenId2]) {
            revert NotEntangled(tokenId1); // Or tokenId2
        }
        if (_entangledPartnerId[tokenId1] != tokenId2 || _entangledPartnerId[tokenId2] != tokenId1) {
            revert NotEntangledWithPartner(tokenId1, tokenId2);
        }
    }


     // @dev Internal helper function for pseudo-randomness.
     // WARNING: This method is NOT cryptographically secure and is vulnerable
     // to miner/validator manipulation (front-running). Do not use this
     // for high-value outcomes in production systems. Use Chainlink VRF
     // or similar decentralized oracle for secure randomness.
    function _generatePseudoRandomness(uint256 input) internal view returns (uint256) {
         return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, input, block.number)));
    }

    // Helper to get owner, handling burned tokens (ownerOf would revert)
     function _getTokenOwner(uint256 tokenId) internal view returns (address) {
         // ERC721 `ownerOf` includes existence check, which is what we want.
         return ownerOf(tokenId);
     }

    // Helper function to check if sender is owner or approved
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
         if (!_exists(tokenId)) {
             return false; // Cannot be approved/owner of non-existent token
         }
        address tokenOwner = ownerOf(tokenId);
        return (spender == tokenOwner || getApproved(tokenId) == spender || isApprovedForAll(tokenOwner, spender));
    }
}
```