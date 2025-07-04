Okay, let's design a smart contract around an interesting, advanced, and creative concept: **Quantum Entangled Tokens**. This contract will implement ERC-721 (Non-Fungible Tokens) but with a core mechanic where tokens can be explicitly linked into "entangled pairs". Actions performed on one token in an entangled pair can affect its partner, sharing state, or even requiring paired actions like transfer or burning.

This goes beyond standard ERC-721 by adding:
1.  Explicit, contract-managed token entanglement.
2.  Shared, dynamic state between entangled tokens (e.g., 'charge level', 'quantum state').
3.  Special actions only possible on entangled pairs (`attune`, `quantumJump`).
4.  Time-based decay of shared state.
5.  Delegation of control over entangled pairs.
6.  Forced paired actions for transfer and burning when entangled.
7.  Snapshotting of pair states.

We will use OpenZeppelin libraries for standard parts (ERC721, Ownable) but build the core entanglement logic from scratch to ensure uniqueness of the *specific implementation and combination* of these features.

---

**Contract Name:** `QuantumEntangledToken`

**Concept:** An ERC-721 contract where individual tokens can be linked together into "entangled pairs". Entangled tokens share state, require paired actions for transfer/burn, and can undergo specific "quantum" operations.

**Outline:**

1.  **State Variables:** Manage token IDs, pair IDs, entanglement mapping, pair states, delegation, decay rate, action costs/gains, pausing, and snapshots.
2.  **Structs & Enums:** Define `PairState` struct and `QuantumState` enum.
3.  **Events:** Announce key actions (Minting Pairs, Entangling, Unentangling, Attuning, Jumping, Delegation, Transferring Pairs, Burning Pairs, State Changes, Snapshots).
4.  **Errors:** Custom errors for specific failure conditions.
5.  **Modifiers:** Check entanglement, ownership, delegation, pausing.
6.  **ERC-721 Overrides:** Modify standard `transferFrom` and `safeTransferFrom` to prevent single-token transfers for entangled tokens.
7.  **Core Entanglement Functions:** Minting entangled pairs, entangling existing tokens, unentangling pairs.
8.  **Pair State Management:** Attuning (increasing charge), applying decay (decreasing charge), performing Quantum Jump (consuming charge, changing state).
9.  **Delegation:** Allowing an address to control actions on a specific pair.
10. **Paired Actions:** Functions to transfer or burn an entire entangled pair.
11. **Admin Functions:** Set parameters like decay rate, action costs/gains, pause contract.
12. **Snapshotting:** Record the state of all pairs at a point in time.
13. **View Functions:** Query token/pair status, state, delegation, snapshot data.

**Function Summary:**

1.  `constructor(string name, string symbol)`: Initializes the contract with a name and symbol.
2.  `supportsInterface(bytes4 interfaceId)`: Standard ERC721 support.
3.  `name()`: Returns the token name.
4.  `symbol()`: Returns the token symbol.
5.  `balanceOf(address owner)`: Standard ERC721.
6.  `ownerOf(uint256 tokenId)`: Standard ERC721.
7.  `approve(address to, uint256 tokenId)`: Standard ERC721.
8.  `getApproved(uint256 tokenId)`: Standard ERC721.
9.  `setApprovalForAll(address operator, bool approved)`: Standard ERC721.
10. `isApprovedForAll(address owner, address operator)`: Standard ERC721.
11. `transferFrom(address from, address to, uint256 tokenId)`: **Override**. Prevents transfer if token is entangled.
12. `safeTransferFrom(address from, address to, uint256 tokenId)`: **Override**. Prevents transfer if token is entangled.
13. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: **Override**. Prevents transfer if token is entangled.
14. `mintPair(address ownerA, address ownerB, uint8 entanglementType)`: Mints two new tokens, immediately entangles them, and assigns initial state.
15. `entangle(uint256 tokenIdA, uint256 tokenIdB, uint8 entanglementType)`: Entangles two *existing*, unentangled tokens. Requires approval from both owners.
16. `unentangle(uint256 pairId)`: Separates an entangled pair. Requires owner/delegate of both tokens.
17. `transferEntangledPair(uint256 pairId, address toA, address toB)`: Transfers both tokens in a pair. Requires owner/delegate of the pair. Allows transferring to different addresses.
18. `burnEntangledPair(uint256 pairId)`: Burns both tokens in a pair. Requires owner/delegate of the pair.
19. `attunePair(uint256 pairId)`: Increases the `chargeLevel` of an entangled pair. Requires owner/delegate. Consumes internal "energy" (e.g., caller pays gas).
20. `performQuantumJump(uint256 pairId)`: Performs a state transition (`QuantumState`). Requires sufficient `chargeLevel`. Consumes `chargeLevel`. Requires owner/delegate.
21. `delegatePairControl(uint256 pairId, address delegate)`: Allows the owner of the pair's tokens to set a delegate who can perform pair actions.
22. `revokePairControl(uint256 pairId)`: Removes the delegate for a pair.
23. `getPairId(uint256 tokenId)`: Returns the pair ID for a token, or 0 if not entangled. (View)
24. `getTokensInPair(uint256 pairId)`: Returns the two token IDs in a pair. (View)
25. `isPairEntangled(uint256 pairId)`: Checks if a pair ID is currently active/entangled. (View)
26. `getPairCharge(uint256 pairId)`: Returns the current `chargeLevel` of a pair, adjusted for decay. (View)
27. `getPairStateEnum(uint256 pairId)`: Returns the current `QuantumState` enum of a pair. (View)
28. `getPairEntanglementType(uint256 pairId)`: Returns the entanglement type of a pair. (View)
29. `getPairDelegate(uint256 pairId)`: Returns the current delegate for a pair. (View)
30. `calculateDecayedCharge(uint256 pairId)`: Helper view to see how much charge decay has occurred since last update. (View)
31. `applyChargeDecay(uint256 pairId)`: Applies the calculated decay to the pair's stored charge level. Requires owner/delegate. Can be called by anyone if decay is triggered (e.g., by a keeper), but we'll keep it owner/delegate for simplicity unless external keepers are in scope. Let's make it callable by anyone but the owner/delegate pays gas. Or maybe make it a view helper and decay is *calculated* on the fly in `getPairCharge` and `performQuantumJump`. Yes, calculating decay on the fly is better to avoid forcing external calls. Let's remove `applyChargeDecay` as a separate state-changing function and bake it into relevant functions.
32. `setDecayRate(uint256 rate)`: Admin function to set the decay rate (charge units per second).
33. `setJumpChargeCost(uint256 cost)`: Admin function to set the charge consumed by `performQuantumJump`.
34. `setAttuneChargeGain(uint256 gain)`: Admin function to set the charge gained by `attunePair`.
35. `pauseEntanglementActions(bool paused)`: Admin function to pause entanglement-specific actions.
36. `isEntanglementActionsPaused()`: Returns the paused status. (View)
37. `snapshotPairStates()`: Creates a historical snapshot of all active pair states. Requires owner.
38. `getLatestSnapshotId()`: Returns the ID of the most recent snapshot. (View)
39. `getPairStateAtSnapshot(uint256 snapshotId, uint256 pairId)`: Returns the `PairState` of a pair at a specific snapshot. (View)

This gives us 39 functions, well over the requested 20, with a complex and intertwined logic centered around the unique entanglement mechanic.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721ConsecutiveEnumerable.sol"; // Allows enumerating token IDs

/**
 * @title QuantumEntangledToken
 * @dev An ERC-721 contract implementing a unique concept of token entanglement.
 * Tokens can be linked into entangled pairs, sharing state and requiring paired actions.
 */

// Outline:
// 1. State Variables: Manage token IDs, pair IDs, entanglement mapping, pair states, delegation, decay rate, action costs/gains, pausing, and snapshots.
// 2. Structs & Enums: Define PairState struct and QuantumState enum.
// 3. Events: Announce key actions (Minting Pairs, Entangling, Unentangling, Attuning, Jumping, Delegation, Transferring Pairs, Burning Pairs, State Changes, Snapshots).
// 4. Errors: Custom errors for specific failure conditions.
// 5. Modifiers: Check entanglement, ownership, delegation, pausing.
// 6. ERC-721 Overrides: Modify standard transferFrom and safeTransferFrom.
// 7. Core Entanglement Functions: Minting entangled pairs, entangling existing tokens, unentangling pairs.
// 8. Pair State Management: Attuning (increasing charge), performing Quantum Jump (consuming charge, changing state), decay calculation.
// 9. Delegation: Allowing an address to control actions on a specific pair.
// 10. Paired Actions: Functions to transfer or burn an entire entangled pair.
// 11. Admin Functions: Set parameters like decay rate, action costs/gains, pause contract.
// 12. Snapshotting: Record the state of all pairs at a point in time.
// 13. View Functions: Query token/pair status, state, delegation, snapshot data.

// Function Summary:
// 1.  constructor(string name, string symbol): Initializes the contract.
// 2.  supportsInterface(bytes4 interfaceId): Standard ERC721.
// 3.  name(): Returns token name.
// 4.  symbol(): Returns token symbol.
// 5.  balanceOf(address owner): Standard ERC721.
// 6.  ownerOf(uint256 tokenId): Standard ERC721.
// 7.  approve(address to, uint256 tokenId): Standard ERC721.
// 8.  getApproved(uint256 tokenId): Standard ERC721.
// 9.  setApprovalForAll(address operator, bool approved): Standard ERC721.
// 10. isApprovedForAll(address owner, address operator): Standard ERC721.
// 11. transferFrom(address from, address to, uint256 tokenId): Override - Prevents single transfer if entangled.
// 12. safeTransferFrom(address from, address to, uint256 tokenId): Override - Prevents single transfer if entangled.
// 13. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data): Override - Prevents single transfer if entangled.
// 14. mintPair(address ownerA, address ownerB, uint8 entanglementType): Mints & entangles two new tokens.
// 15. entangle(uint256 tokenIdA, uint256 tokenIdB, uint8 entanglementType): Entangles existing tokens. Requires owner/approval.
// 16. unentangle(uint256 pairId): Separates an entangled pair. Requires owner/delegate.
// 17. transferEntangledPair(uint256 pairId, address toA, address toB): Transfers both tokens in a pair. Requires owner/delegate.
// 18. burnEntangledPair(uint256 pairId): Burns both tokens in a pair. Requires owner/delegate.
// 19. attunePair(uint256 pairId): Increases pair's charge level. Requires owner/delegate.
// 20. performQuantumJump(uint256 pairId): Changes pair's state, consumes charge. Requires owner/delegate & sufficient charge.
// 21. delegatePairControl(uint256 pairId, address delegate): Set delegate for a pair. Requires owner.
// 22. revokePairControl(uint256 pairId): Remove delegate. Requires owner.
// 23. getPairId(uint256 tokenId): Get pair ID for a token. (View)
// 24. getTokensInPair(uint256 pairId): Get token IDs in a pair. (View)
// 25. isPairEntangled(uint256 pairId): Check if pair ID is active. (View)
// 26. getPairCharge(uint256 pairId): Get pair's current charge (decayed). (View)
// 27. getPairStateEnum(uint256 pairId): Get pair's current QuantumState. (View)
// 28. getPairEntanglementType(uint256 pairId): Get pair's entanglement type. (View)
// 29. getPairDelegate(uint256 pairId): Get pair's delegate. (View)
// 30. calculateDecayedCharge(uint256 pairId): Calculate decay amount for a pair. (View)
// 31. setDecayRate(uint256 rate): Admin: Set charge decay rate.
// 32. setJumpChargeCost(uint256 cost): Admin: Set charge cost for Quantum Jump.
// 33. setAttuneChargeGain(uint256 gain): Admin: Set charge gained by Attune.
// 34. pauseEntanglementActions(bool paused): Admin: Pause core entanglement functions.
// 35. isEntanglementActionsPaused(): Get paused status. (View)
// 36. snapshotPairStates(): Create a snapshot of all pair states. Admin only.
// 37. getLatestSnapshotId(): Get ID of latest snapshot. (View)
// 38. getPairStateAtSnapshot(uint256 snapshotId, uint256 pairId): Get pair state at a snapshot. (View)

contract QuantumEntangledToken is ERC721ConsecutiveEnumerable, Ownable {
    using Counters for Counters.Counter;

    // --- State Variables ---
    Counters.Counter private _nextTokenId;
    Counters.Counter private _nextPairId;
    Counters.Counter private _nextSnapshotId;

    // Mapping from tokenId to the pairId it belongs to (0 if not entangled)
    mapping(uint256 => uint256) private _tokenIdToPairId;

    // Mapping from pairId to the two tokenIds in the pair
    mapping(uint256 => uint256[2]) private _pairTokens;

    // Struct to hold the shared state of an entangled pair
    enum QuantumState { GroundState, ExcitedState, SuperpositionState, CollapsedState }

    struct PairState {
        uint256 chargeLevel;
        uint8 entanglementType; // e.g., 0 for Alpha, 1 for Beta, etc.
        QuantumState currentState;
        uint64 lastAttuneTime; // Timestamp of last charge gain or decay application
    }

    // Mapping from pairId to its current shared state
    mapping(uint256 => PairState) private _pairStates;

    // Mapping from pairId to an address delegated to control actions on the pair
    mapping(uint256 => address) private _pairDelegates;

    // Admin configurable parameters
    uint256 public decayRate = 1; // Charge units decayed per second
    uint256 public jumpChargeCost = 100; // Charge required/consumed for Quantum Jump
    uint256 public attuneChargeGain = 50; // Charge gained from Attune

    bool public entanglementActionsPaused = false;

    // Snapshotting state
    mapping(uint256 => mapping(uint256 => PairState)) private _pairStateSnapshots;
    mapping(uint256 => uint256[] or bytes) private _snapshotPairIds; // Store which pairIds existed at snapshot (more complex storage needed for full list, maybe just store pairIds)

    // --- Events ---
    event PairMinted(uint256 indexed pairId, uint256 indexed tokenIdA, uint256 indexed tokenIdB, address indexed ownerA, address ownerB, uint8 entanglementType);
    event TokensEntangled(uint256 indexed pairId, uint256 indexed tokenIdA, uint256 indexed tokenIdB, uint8 entanglementType);
    event PairUnentangled(uint256 indexed pairId, uint256 indexed tokenIdA, uint256 indexed tokenIdB);
    event PairTransferred(uint256 indexed pairId, address indexed from, address indexed toA, address indexed toB);
    event PairBurned(uint256 indexed pairId, address indexed from, uint256 indexed tokenIdA, uint256 indexed tokenIdB);
    event PairAttuned(uint256 indexed pairId, uint256 newCharge);
    event QuantumJumpPerformed(uint256 indexed pairId, QuantumState indexed newState, uint256 remainingCharge);
    event PairDelegateSet(uint256 indexed pairId, address indexed delegator, address indexed delegate);
    event PairDelegateRevoked(uint256 indexed pairId, address indexed delegator, address indexed delegate);
    event SnapshotCreated(uint256 indexed snapshotId, uint256 timestamp);
    event DecayRateSet(uint256 indexed newRate);
    event JumpChargeCostSet(uint256 indexed newCost);
    event AttuneChargeGainSet(uint256 indexed newGain);
    event EntanglementActionsPaused(bool indexed paused);


    // --- Errors ---
    error QET_TokenNotEntangled(uint256 tokenId);
    error QET_PairNotFound(uint256 pairId);
    error QET_AlreadyEntangled(uint256 tokenId);
    error QET_CannotEntangleSelf();
    error QET_TokensNotOwnedBySameAddress(); // For simplicity, entangling requires same owner or approvals
    error QET_EntangleApprovalRequired(uint256 tokenId, address owner);
    error QET_UnentangleApprovalRequired(uint256 pairId, address ownerA, address ownerB);
    error QET_TransferPairApprovalRequired(uint256 pairId, address ownerA, address ownerB);
    error QET_BurnPairApprovalRequired(uint256 pairId, address ownerA, address ownerB);
    error QET_InsufficientCharge(uint256 pairId, uint256 requiredCharge, uint256 currentCharge);
    error QET_NotPairOwnerOrDelegate(uint256 pairId, address caller);
    error QET_EntanglementActionsPaused();
    error QET_InvalidSnapshotId(uint256 snapshotId);


    // --- Constructor ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    // --- Modifiers ---
    modifier whenEntanglementActionsNotPaused() {
        if (entanglementActionsPaused) {
            revert QET_EntanglementActionsPaused();
        }
        _;
    }

    modifier onlyPairOwnerOrDelegate(uint256 pairId) {
        uint256[2] memory tokens = _pairTokens[pairId];
        if (tokens[0] == 0) revert QET_PairNotFound(pairId); // Check pair exists

        address ownerA = ownerOf(tokens[0]);
        address ownerB = ownerOf(tokens[1]);
        address delegate = _pairDelegates[pairId];

        // Check if caller is owner of both tokens OR the appointed delegate
        if (msg.sender != ownerA || msg.sender != ownerB) { // If not owner of both (handles single owner case too)
             if (msg.sender != delegate) {
                 revert QET_NotPairOwnerOrDelegate(pairId, msg.sender);
             }
        }
        _;
    }


    // --- Internal Helpers ---

    function _isEntangled(uint256 tokenId) internal view returns (bool) {
        return _tokenIdToPairId[tokenId] != 0;
    }

    function _getPairId(uint256 tokenId) internal view returns (uint256) {
        return _tokenIdToPairId[tokenId];
    }

    function _getPairState(uint256 pairId) internal view returns (PairState storage) {
        // This assumes pairId exists. Should be called after checking _pairTokens[pairId][0] != 0
        return _pairStates[pairId];
    }

    function _getTokensInPair(uint256 pairId) internal view returns (uint256[2] memory) {
        uint256[2] memory tokens = _pairTokens[pairId];
        if (tokens[0] == 0) revert QET_PairNotFound(pairId);
        return tokens;
    }

     // Internal function to calculate current charge considering decay
    function _calculateCurrentCharge(uint256 pairId) internal view returns (uint256) {
        PairState storage pair = _getPairState(pairId);
        uint256 timeElapsed = block.timestamp - pair.lastAttuneTime;
        uint256 decayedAmount = timeElapsed * decayRate;
        return pair.chargeLevel >= decayedAmount ? pair.chargeLevel - decayedAmount : 0;
    }

     // Internal function to apply decay and update lastAttuneTime
     function _applyChargeDecay(uint256 pairId) internal {
        PairState storage pair = _getPairState(pairId);
        uint256 timeElapsed = block.timestamp - pair.lastAttuneTime;
        uint256 decayedAmount = timeElapsed * decayRate;
        pair.chargeLevel = pair.chargeLevel >= decayedAmount ? pair.chargeLevel - decayedAmount : 0;
        pair.lastAttuneTime = uint64(block.timestamp);
     }


    // --- ERC-721 Overrides ---
    // We override transferFrom and safeTransferFrom to prevent transferring
    // single tokens if they are entangled. They must be transferred as a pair.

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        if (_isEntangled(tokenId)) {
            revert QET_AlreadyEntangled(tokenId); // Cannot transfer single entangled token
        }
        // Call the original ERC721 transferFrom for non-entangled tokens
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        if (_isEntangled(tokenId)) {
            revert QET_AlreadyEntangled(tokenId); // Cannot transfer single entangled token
        }
        // Call the original ERC721 safeTransferFrom for non-entangled tokens
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        if (_isEntangled(tokenId)) {
            revert QET_AlreadyEntangled(tokenId); // Cannot transfer single entangled token
        }
        // Call the original ERC721 safeTransferFrom for non-entangled tokens
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // --- Core Entanglement Functions ---

    /**
     * @dev Mints a new pair of entangled tokens and assigns them to owners.
     * @param ownerA Address to receive the first token.
     * @param ownerB Address to receive the second token.
     * @param entanglementType Type of entanglement for the pair.
     */
    function mintPair(address ownerA, address ownerB, uint8 entanglementType) external onlyOwner whenEntanglementActionsNotPaused {
        uint256 tokenIdA = _nextTokenId.current();
        _nextTokenId.increment();
        uint256 tokenIdB = _nextTokenId.current();
        _nextTokenId.increment();
        uint256 pairId = _nextPairId.current();
        _nextPairId.increment();

        // Mint tokens
        _safeMint(ownerA, tokenIdA);
        _safeMint(ownerB, tokenIdB);

        // Entangle them
        _tokenIdToPairId[tokenIdA] = pairId;
        _tokenIdToPairId[tokenIdB] = pairId;
        _pairTokens[pairId][0] = tokenIdA;
        _pairTokens[pairId][1] = tokenIdB;

        // Initialize pair state
        _pairStates[pairId] = PairState({
            chargeLevel: 0,
            entanglementType: entanglementType,
            currentState: QuantumState.GroundState,
            lastAttuneTime: uint64(block.timestamp)
        });

        emit PairMinted(pairId, tokenIdA, tokenIdB, ownerA, ownerB, entanglementType);
    }

    /**
     * @dev Entangles two existing, unentangled tokens. Requires approval from both owners.
     * @param tokenIdA ID of the first token.
     * @param tokenIdB ID of the second token.
     * @param entanglementType Type of entanglement for the pair.
     */
    function entangle(uint256 tokenIdA, uint256 tokenIdB, uint8 entanglementType) external whenEntanglementActionsNotPaused {
        if (tokenIdA == tokenIdB) revert QET_CannotEntangleSelf();
        if (_isEntangled(tokenIdA)) revert QET_AlreadyEntangled(tokenIdA);
        if (_isEntangled(tokenIdB)) revert QET_AlreadyEntangled(tokenIdB);

        address ownerA = ownerOf(tokenIdA);
        address ownerB = ownerOf(tokenIdB);

        // For entangling, we require explicit approval from both owners
        // Or they are the same owner and calling from that address
        bool callerIsOwnerA = msg.sender == ownerA;
        bool callerIsOwnerB = msg.sender == ownerB;
        bool callerApprovedA = getApproved(tokenIdA) == msg.sender || isApprovedForAll(ownerA, msg.sender);
        bool callerApprovedB = getApproved(tokenIdB) == msg.sender || isApprovedForAll(ownerB, msg.sender);

        if (!((callerIsOwnerA || callerApprovedA) && (callerIsOwnerB || callerApprovedB))) {
            // Refined error to indicate which approval might be missing if owners are different
            if(ownerA != ownerB) {
                 if (!(callerIsOwnerA || callerApprovedA)) revert QET_EntangleApprovalRequired(tokenIdA, ownerA);
                 if (!(callerIsOwnerB || callerApprovedB)) revert QET_EntangleApprovalRequired(tokenIdB, ownerB);
            } else { // Same owner case
                 if (!(callerIsOwnerA || callerApprovedA)) revert QET_EntangleApprovalRequired(tokenIdA, ownerA); // Check applies to both
            }
        }

        uint256 pairId = _nextPairId.current();
        _nextPairId.increment();

        _tokenIdToPairId[tokenIdA] = pairId;
        _tokenIdToPairId[tokenIdB] = pairId;
        _pairTokens[pairId][0] = tokenIdA;
        _pairTokens[pairId][1] = tokenIdB;

        _pairStates[pairId] = PairState({
            chargeLevel: 0,
            entanglementType: entanglementType,
            currentState: QuantumState.GroundState,
            lastAttuneTime: uint64(block.timestamp)
        });

        // Clear individual approvals upon entanglement
        _approve(address(0), tokenIdA);
        _approve(address(0), tokenIdB);


        emit TokensEntangled(pairId, tokenIdA, tokenIdB, entanglementType);
    }

    /**
     * @dev Unentangles a pair of tokens. Requires owner or delegate of the pair.
     * @param pairId ID of the pair to unentangle.
     */
    function unentangle(uint256 pairId) external onlyPairOwnerOrDelegate(pairId) whenEntanglementActionsNotPaused {
        uint256[2] memory tokens = _getTokensInPair(pairId); // Checks if pair exists
        uint256 tokenIdA = tokens[0];
        uint256 tokenIdB = tokens[1];

        // Clear entanglement mappings
        delete _tokenIdToPairId[tokenIdA];
        delete _tokenIdToPairId[tokenIdB];
        delete _pairTokens[pairId]; // This effectively marks the pairId as inactive

        // Clear pair state and delegate (optional, but good cleanup)
        delete _pairStates[pairId];
        delete _pairDelegates[pairId];

        emit PairUnentangled(pairId, tokenIdA, tokenIdB);
    }

    // --- Paired Actions (Transfer & Burn) ---

    /**
     * @dev Transfers both tokens in an entangled pair. Requires owner or delegate of the pair.
     * Allows transferring to potentially different addresses.
     * @param pairId ID of the pair to transfer.
     * @param toA Address to receive the first token.
     * @param toB Address to receive the second token.
     */
    function transferEntangledPair(uint256 pairId, address toA, address toB) external onlyPairOwnerOrDelegate(pairId) whenEntanglementActionsNotPaused {
        uint256[2] memory tokens = _getTokensInPair(pairId); // Checks if pair exists
        uint256 tokenIdA = tokens[0];
        uint256 tokenIdB = tokens[1];

        address ownerA = ownerOf(tokenIdA);
        address ownerB = ownerOf(tokenIdB);

        // Standard ERC721 _transfer will handle ownership update
        _transfer(ownerA, toA, tokenIdA);
        _transfer(ownerB, toB, tokenIdB);

        // Important: Need to clear approvals before transferring
        // Note: OpenZeppelin's _transfer clears approvals, so this is handled.

        emit PairTransferred(pairId, msg.sender, toA, toB);
    }

    /**
     * @dev Burns both tokens in an entangled pair. Requires owner or delegate of the pair.
     * @param pairId ID of the pair to burn.
     */
    function burnEntangledPair(uint256 pairId) external onlyPairOwnerOrDelegate(pairId) whenEntanglementActionsNotPaused {
        uint256[2] memory tokens = _getTokensInPair(pairId); // Checks if pair exists
        uint256 tokenIdA = tokens[0];
        uint256 tokenIdB = tokens[1];

        address ownerA = ownerOf(tokenIdA);
        address ownerB = ownerOf(tokenIdB);

        // Burn tokens using OpenZeppelin's _burn
        _burn(tokenIdA);
        _burn(tokenIdB);

        // Also unentangle them completely
        delete _tokenIdToPairId[tokenIdA];
        delete _tokenIdToPairId[tokenIdB];
        delete _pairTokens[pairId];
        delete _pairStates[pairId];
        delete _pairDelegates[pairId];

        emit PairBurned(pairId, msg.sender, tokenIdA, tokenIdB);
    }


    // --- Pair State Management & Actions ---

    /**
     * @dev Increases the charge level of an entangled pair. Requires owner or delegate.
     * Charge gain is subject to `attuneChargeGain`. Applies decay before gaining.
     * @param pairId ID of the pair to attune.
     */
    function attunePair(uint256 pairId) external onlyPairOwnerOrDelegate(pairId) whenEntanglementActionsNotPaused {
        PairState storage pair = _getPairState(pairId); // Checks if pair exists indirectly via onlyPairOwnerOrDelegate

        // Apply decay before gaining charge
        _applyChargeDecay(pairId);

        pair.chargeLevel += attuneChargeGain;
        pair.lastAttuneTime = uint64(block.timestamp); // Update timestamp

        emit PairAttuned(pairId, pair.chargeLevel);
    }

     /**
     * @dev Calculates the current charge level for a pair, accounting for decay.
     * @param pairId ID of the pair.
     * @return The calculated current charge level.
     */
    function calculateDecayedCharge(uint256 pairId) public view returns (uint256) {
         // Checks if pair exists implicitly via _getTokensInPair or similar check in calling context
         // Or add an explicit check here if this is public view
         if (_pairTokens[pairId][0] == 0) revert QET_PairNotFound(pairId);
         return _calculateCurrentCharge(pairId);
    }


    /**
     * @dev Performs a Quantum Jump for an entangled pair. Requires owner or delegate and sufficient charge.
     * Consumes charge and transitions the pair's QuantumState.
     * @param pairId ID of the pair to jump.
     */
    function performQuantumJump(uint256 pairId) external onlyPairOwnerOrDelegate(pairId) whenEntanglementActionsNotPaused {
        PairState storage pair = _getPairState(pairId); // Checks if pair exists indirectly

        // Apply decay and get current charge
        _applyChargeDecay(pairId);
        uint256 currentCharge = pair.chargeLevel;

        if (currentCharge < jumpChargeCost) {
            revert QET_InsufficientCharge(pairId, jumpChargeCost, currentCharge);
        }

        // Consume charge
        pair.chargeLevel -= jumpChargeCost;

        // Transition state (example logic, can be more complex)
        if (pair.currentState == QuantumState.GroundState) {
            pair.currentState = QuantumState.ExcitedState;
        } else if (pair.currentState == QuantumState.ExcitedState) {
            pair.currentState = QuantumState.SuperpositionState;
        } else if (pair.currentState == QuantumState.SuperpositionState) {
            pair.currentState = QuantumState.CollapsedState;
        } else if (pair.currentState == QuantumState.CollapsedState) {
            pair.currentState = QuantumState.GroundState; // Reset or special effect
        }
        // Update last attune time as state changed (optional, but fits decay model)
        pair.lastAttuneTime = uint64(block.timestamp);


        emit QuantumJumpPerformed(pairId, pair.currentState, pair.chargeLevel);
    }


    // --- Delegation ---

    /**
     * @dev Allows the owner of a pair's tokens to delegate control of pair actions to another address.
     * @param pairId ID of the pair.
     * @param delegate Address to set as delegate (address(0) to clear).
     */
    function delegatePairControl(uint256 pairId, address delegate) external {
        uint256[2] memory tokens = _getTokensInPair(pairId);
        address ownerA = ownerOf(tokens[0]);
        address ownerB = ownerOf(tokens[1]);

        // Only owner of *both* tokens can set a delegate for the pair
        if (msg.sender != ownerA || msg.sender != ownerB) {
             // Check if caller is owner of both (handles single owner implicitly)
            revert QET_NotPairOwnerOrDelegate(pairId, msg.sender);
        }

        address currentDelegate = _pairDelegates[pairId];
        _pairDelegates[pairId] = delegate;

        if (delegate != currentDelegate) {
             emit PairDelegateSet(pairId, msg.sender, delegate);
        }
    }

    /**
     * @dev Removes the delegate for a pair. Only callable by the current owner.
     * @param pairId ID of the pair.
     */
    function revokePairControl(uint256 pairId) external {
        uint256[2] memory tokens = _getTokensInPair(pairId);
        address ownerA = ownerOf(tokens[0]);
        address ownerB = ownerOf(tokens[1]);

        // Only owner of *both* tokens can revoke a delegate
        if (msg.sender != ownerA || msg.sender != ownerB) {
            revert QET_NotPairOwnerOrDelegate(pairId, msg.sender);
        }

        address currentDelegate = _pairDelegates[pairId];
         if (currentDelegate != address(0)) {
            delete _pairDelegates[pairId];
             emit PairDelegateRevoked(pairId, msg.sender, currentDelegate);
         }
    }


    // --- Admin Functions ---

    /**
     * @dev Sets the rate at which charge decays per second. Only callable by owner.
     * @param rate New decay rate.
     */
    function setDecayRate(uint256 rate) external onlyOwner {
        decayRate = rate;
        emit DecayRateSet(rate);
    }

     /**
     * @dev Sets the charge cost for the Quantum Jump action. Only callable by owner.
     * @param cost New jump cost.
     */
    function setJumpChargeCost(uint256 cost) external onlyOwner {
        jumpChargeCost = cost;
        emit JumpChargeCostSet(cost);
    }

     /**
     * @dev Sets the charge gained from the Attune action. Only callable by owner.
     * @param gain New attune gain.
     */
    function setAttuneChargeGain(uint256 gain) external onlyOwner {
        attuneChargeGain = gain;
        emit AttuneChargeGainSet(gain);
    }

     /**
     * @dev Pauses or unpauses core entanglement-specific actions (mintPair, entangle, unentangle, attunePair, performQuantumJump, transferEntangledPair, burnEntangledPair).
     * Standard ERC721 functions are unaffected. Only callable by owner.
     * @param paused True to pause, false to unpause.
     */
    function pauseEntanglementActions(bool paused) external onlyOwner {
        entanglementActionsPaused = paused;
        emit EntanglementActionsPaused(paused);
    }


    // --- Snapshotting ---
    // Note: Storing ALL pair states for ALL snapshots can be very gas/storage intensive over time.
    // A more robust solution might involve external storage or ZK proofs for verification.
    // This implementation is a basic on-chain snapshot.

    /**
     * @dev Creates a snapshot of the current state of all active entangled pairs. Only callable by owner.
     */
    function snapshotPairStates() external onlyOwner {
        uint256 snapshotId = _nextSnapshotId.current() + 1; // Increment before using
        _nextSnapshotId.increment();

        // Store the list of pairIds active at this snapshot (simplified)
        // A more scalable approach might iterate pairIds up to _nextPairId.current()
        // and check if _pairTokens[pairId][0] != 0.
        // For simplicity here, we'll just iterate and store states for *all* pairIds ever created that are currently active.
        // This might capture some briefly active pairs. A more precise method would track active pairIds separately.
        // Let's iterate through token IDs instead, it's easier with ERC721Enumerable
        uint256 numTokens = totalSupply();
        uint256[] memory activePairIds = new uint256[](_nextPairId.current()); // Max possible pair IDs

        uint256 activeCount = 0;
        for (uint256 i = 0; i < numTokens; i++) {
            uint256 tokenId = tokenByIndex(i); // From ERC721Enumerable
            uint256 pairId = _tokenIdToPairId[tokenId];
            if (pairId != 0) {
                bool found = false;
                for(uint j = 0; j < activeCount; j++) {
                    if (activePairIds[j] == pairId) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    activePairIds[activeCount] = pairId;
                    activeCount++;
                }
            }
        }

        // Resize array to actual active count
        assembly {
            mstore(activePairIds, activeCount)
        }


        // Store the state for each active pair
        // Note: This copies state to storage, which is expensive.
        for (uint i = 0; i < activeCount; i++) {
            uint256 currentPairId = activePairIds[i];
             // Recalculate charge with decay before snapshotting
             _applyChargeDecay(currentPairId); // Apply decay to storage state before copying
            _pairStateSnapshots[snapshotId][currentPairId] = _pairStates[currentPairId];
        }

         // Store the list of active pair IDs for this snapshot
         // Simplified storage: just store the current count of pair IDs and iterate up to it.
         // This assumes pair IDs are contiguous and we can check validity later.
         // Alternative: Store the array of activePairIds, but dynamic arrays in storage are costly.
         // Let's store the count and rely on the _pairTokens check for validity in the getter.
         // Store a flag or marker to indicate the snapshot exists.
         _snapshotPairStates[snapshotId][0].chargeLevel = _nextPairId.current(); // Use chargeLevel of pairId 0 as a marker/counter
         _snapshotPairStates[snapshotId][0].lastAttuneTime = uint64(block.timestamp); // Store timestamp here


        emit SnapshotCreated(snapshotId, block.timestamp);
    }

    /**
     * @dev Returns the ID of the most recently created snapshot.
     * @return The latest snapshot ID.
     */
    function getLatestSnapshotId() external view returns (uint256) {
        return _nextSnapshotId.current();
    }

    /**
     * @dev Returns the state of a specific pair at a given snapshot.
     * @param snapshotId The ID of the snapshot.
     * @param pairId The ID of the pair.
     * @return The PairState struct at that snapshot.
     */
    function getPairStateAtSnapshot(uint256 snapshotId, uint256 pairId) external view returns (PairState memory) {
         if (snapshotId == 0 || snapshotId > _nextSnapshotId.current()) {
            revert QET_InvalidSnapshotId(snapshotId);
         }
         // Check if the pair existed at or before this snapshot (using the marker/counter)
         if (pairId == 0 || pairId >= _snapshotPairStates[snapshotId][0].chargeLevel) {
            revert QET_PairNotFound(pairId);
         }

         PairState memory snapshotState = _pairStateSnapshots[snapshotId][pairId];

         // Note: Charge decay is captured at the moment of snapshotting.
         // If you need charge at a later time *relative to the snapshot*,
         // you'd need to recalculate decay based on snapshot time and query time.
         // For simplicity, we return the state exactly as recorded.

         return snapshotState;
    }


    // --- View Functions ---

     /**
     * @dev Returns the pair ID for a given token ID.
     * @param tokenId The token ID.
     * @return The pair ID, or 0 if not entangled.
     */
    function getPairId(uint256 tokenId) external view returns (uint256) {
        return _tokenIdToPairId[tokenId];
    }

    /**
     * @dev Returns the two token IDs belonging to a given pair ID.
     * @param pairId The pair ID.
     * @return A two-element array containing the token IDs.
     */
    function getTokensInPair(uint256 pairId) external view returns (uint256[2] memory) {
         return _getTokensInPair(pairId); // Uses internal helper with check
    }

     /**
     * @dev Checks if a given pair ID is currently active (entangled).
     * @param pairId The pair ID.
     * @return True if entangled, false otherwise.
     */
    function isPairEntangled(uint256 pairId) external view returns (bool) {
         // Check if the first token ID mapping exists for this pair ID
         return _pairTokens[pairId][0] != 0;
     }

    /**
     * @dev Returns the current charge level of an entangled pair, accounting for decay.
     * @param pairId The pair ID.
     * @return The current charge level.
     */
    function getPairCharge(uint256 pairId) external view returns (uint256) {
        if (_pairTokens[pairId][0] == 0) revert QET_PairNotFound(pairId);
        return _calculateCurrentCharge(pairId);
    }

    /**
     * @dev Returns the current Quantum State of an entangled pair.
     * @param pairId The pair ID.
     * @return The current QuantumState enum value.
     */
    function getPairStateEnum(uint256 pairId) external view returns (QuantumState) {
        if (_pairTokens[pairId][0] == 0) revert QET_PairNotFound(pairId);
        return _pairStates[pairId].currentState;
    }

    /**
     * @dev Returns the entanglement type of an entangled pair.
     * @param pairId The pair ID.
     * @return The entanglement type byte.
     */
    function getPairEntanglementType(uint256 pairId) external view returns (uint8) {
        if (_pairTokens[pairId][0] == 0) revert QET_PairNotFound(pairId);
        return _pairStates[pairId].entanglementType;
    }

    /**
     * @dev Returns the address currently delegated to control a specific pair.
     * @param pairId The pair ID.
     * @return The delegate address, or address(0) if no delegate is set.
     */
    function getPairDelegate(uint256 pairId) external view returns (address) {
         if (_pairTokens[pairId][0] == 0) return address(0); // Return 0 if pair doesn't exist
         return _pairDelegates[pairId];
    }

    /**
     * @dev Helper view to check if an address is the owner (of both tokens) or the delegate for a pair.
     * @param pairId The pair ID.
     * @param addr The address to check.
     * @return True if the address is the owner or delegate, false otherwise.
     */
    function isPairController(uint256 pairId, address addr) external view returns (bool) {
        uint256[2] memory tokens = _pairTokens[pairId];
        if (tokens[0] == 0) return false; // Pair doesn't exist

        address ownerA = ownerOf(tokens[0]);
        address ownerB = ownerOf(tokens[1]);
        address delegate = _pairDelegates[pairId];

        return (addr == ownerA && addr == ownerB) || (addr == delegate && delegate != address(0));
    }

    /**
     * @dev Returns the current paused status for entanglement-specific actions.
     * @return True if paused, false otherwise.
     */
    function isEntanglementActionsPaused() external view returns (bool) {
        return entanglementActionsPaused;
    }

    // Note: functions inherited from ERC721Enumerable (totalSupply, tokenByIndex, tokenOfOwnerByIndex)
    // are also available views, adding to the total function count.

}
```