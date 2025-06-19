Okay, here is a Solidity smart contract implementing a concept I'm calling "Quantum Entangled ERC721 Tokens".

**Concept:** This contract extends ERC721 tokens with a unique "quantum entanglement" mechanism. Two tokens can become "entangled" through a mutual agreement process. When entangled, actions or state changes on one token can influence the other. They share a "correlation factor" and have individual "quantum states" that can be synced. This simulates (in a very abstract and metaphorical way) the linked nature of entangled quantum particles.

**Key Features & Advanced Concepts:**

1.  **Mutual Consent Entanglement:** Tokens can only be entangled after a proposal and acceptance process involving both token owners.
2.  **Mutual Consent Disentanglement:** Similarly, disentangling requires a proposal and acceptance, or owner intervention.
3.  **Linked State (Quantum State):** Each token has a numerical "quantum state". While entangled, these states can be explicitly synced, potentially averaging or combining their values.
4.  **Shared Correlation Factor:** Entangled tokens share a common "correlation factor" value. This factor can be influenced by state sync operations or manual updates by token owners.
5.  **Dynamic Traits:** A token's properties (like its URI or an abstract trait) can dynamically depend on its entanglement status, its quantum state, and the shared correlation factor.
6.  **Interaction Effects:** Certain actions (like transferring an entangled token) automatically break the entanglement, mimicking measurement collapse. Other actions (`mutateQuantumState`, `syncQuantumState`) specifically interact with the entanglement.
7.  **State-Dependent Actions:** Some functions might only be callable when a token is entangled or has a specific quantum state.
8.  **Non-Duplicative Logic:** While using standard ERC721 interfaces, the core logic for entanglement, state management, and correlation is custom and not directly replicated from common open-source libraries. (Note: Basic ERC721 state mappings and function signatures are standard by necessity to implement the interface, but the *interactions* defined here are unique).

**Outline:**

1.  **Pragma and Imports:** Specify Solidity version and necessary interface imports (ERC721, ERC165).
2.  **Errors:** Custom error definitions for clarity and gas efficiency.
3.  **Interfaces:** Define `IERC721` and `IERC165` interfaces (included directly for self-containment as requested).
4.  **Ownable Implementation:** Simple access control pattern (included directly).
5.  **Contract Definition:** `QuantumEntangledERC721` inherits from `Ownable`.
6.  **State Variables:**
    *   ERC721 core mappings (`_owners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`).
    *   Token counter.
    *   Entanglement mapping (`_entangledToken`).
    *   Quantum state mapping (`_quantumState`).
    *   Correlation factor mapping (`_correlationFactor`).
    *   Entanglement request state (`_entanglementRequests`).
    *   Disentanglement proposal state (`_disentanglementProposals`).
    *   Base URI.
7.  **Events:** Standard ERC721 events plus custom events for entanglement state changes.
8.  **Modifiers:** Custom modifiers (`isEntangled`, `notEntangled`, `areEntangledWithEachOther`, `isTokenOwner`, `isEntangledTokenOwner`).
9.  **Constructor:** Sets name, symbol, and initial owner.
10. **Internal Helper Functions:** Logic for core token operations (`_safeMint`, `_transfer`, `_approve`, `_burn`) and entanglement management (`_checkEntangledAndDisentangle`, `_entanglePair`, `_disentanglePair`).
11. **External/Public Functions:**
    *   Standard ERC721 interface functions.
    *   Owner-only administration functions (setting base URI).
    *   Token minting and burning.
    *   Entanglement proposal/acceptance/rejection/cancellation functions.
    *   Disentanglement proposal/acceptance/rejection/cancellation functions.
    *   Query functions for entanglement status and partner.
    *   Functions to interact with the quantum state and correlation factor.
    *   Function to trigger quantum state synchronization.
    *   Function to get dynamic trait based on state.
    *   Override `tokenURI`.
    *   Utility view functions (e.g., checking pending proposals).

**Function Summary (20+ functions):**

*   **Standard ERC721 (Overridden/Implemented):**
    1.  `balanceOf(address owner)`: Get token count for an owner.
    2.  `ownerOf(uint256 tokenId)`: Get owner of a token.
    3.  `approve(address to, uint256 tokenId)`: Approve another address to transfer a token.
    4.  `getApproved(uint256 tokenId)`: Get approved address for a token.
    5.  `setApprovalForAll(address operator, bool approved)`: Set approval for all tokens by an operator.
    6.  `isApprovedForAll(address owner, address operator)`: Check if an operator is approved for all tokens.
    7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfer token (internal, checks entanglement).
    8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer token (checks receiver).
    9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer token with data (checks receiver).
    10. `supportsInterface(bytes4 interfaceId)`: ERC165 compliance.
    11. `tokenURI(uint256 tokenId)`: Get token metadata URI (potentially dynamic).

*   **Basic Token Management:**
    12. `mint(address to)`: Mint a new token.
    13. `burn(uint256 tokenId)`: Burn a token (checks entanglement).
    14. `setTokenUriPrefix(string memory uriPrefix)`: Owner sets base URI.

*   **Entanglement Management:**
    15. `requestEntanglement(uint256 tokenId1, uint256 tokenId2)`: Owner of `tokenId1` requests entanglement with `tokenId2`.
    16. `acceptEntanglementRequest(uint256 tokenId)`: Owner of `tokenId` accepts an incoming request.
    17. `rejectEntanglementRequest(uint256 tokenId)`: Owner of `tokenId` rejects an incoming request.
    18. `cancelEntanglementRequest(uint256 tokenId)`: Owner of `tokenId` cancels their outgoing request.
    19. `proposeDisentanglement(uint256 tokenId)`: Owner of an entangled token proposes disentanglement.
    20. `acceptDisentanglementProposal(uint256 tokenId)`: Owner of the entangled partner token accepts disentanglement.
    21. `rejectDisentanglementProposal(uint256 tokenId)`: Owner of the entangled partner token rejects disentanglement.
    22. `cancelDisentanglementProposal(uint256 tokenId)`: Owner of an entangled token cancels their proposal.
    23. `forceDisentanglePair(uint256 tokenId1, uint256 tokenId2)`: Contract owner can force disentanglement.

*   **Quantum State & Correlation:**
    24. `isTokenEntangled(uint256 tokenId)`: Check if a token is entangled.
    25. `getEntangledToken(uint256 tokenId)`: Get the ID of the token entangled with this one (0 if none).
    26. `mutateQuantumState(uint256 tokenId, int256 newValue)`: Owner updates the quantum state of their token.
    27. `getQuantumState(uint256 tokenId)`: Get the current quantum state of a token.
    28. `syncQuantumState(uint256 tokenId)`: Trigger synchronization of quantum states between entangled tokens.
    29. `getCorrelationFactor(uint256 tokenId)`: Get the correlation factor of a token (shared if entangled).
    30. `updateCorrelationFactor(uint256 tokenId, uint256 newFactor)`: Owner of an entangled token updates the shared correlation factor.

*   **Dynamic & Query Functions:**
    31. `getDynamicTrait(uint256 tokenId)`: Get a hypothetical dynamic trait based on state.
    32. `checkPendingEntanglementRequest(uint256 tokenId)`: View details of an outgoing or incoming entanglement request.
    33. `checkPendingDisentanglementProposal(uint256 tokenId)`: View details of a pending disentanglement proposal.
    34. `getTokensByOwner(address owner)`: Get list of token IDs owned by an address (inefficient for many tokens).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline & Function Summary ---
// Concept: Quantum Entangled ERC721 Tokens
// Extends ERC721 with a metaphorical "quantum entanglement" mechanism.
// Two tokens can be linked, and state changes/actions on one can influence the other.

// Outline:
// 1. Pragma and Imports (Interfaces included for self-containment)
// 2. Errors
// 3. Interfaces (IERC721, IERC165)
// 4. Ownable Implementation (Basic access control)
// 5. Contract Definition (QuantumEntangledERC721)
// 6. State Variables (ERC721 state + entanglement state, quantum state, correlation factor)
// 7. Events (Standard ERC721 + custom entanglement events)
// 8. Modifiers (Custom checks for entanglement status, ownership)
// 9. Constructor
// 10. Internal Helper Functions (Core token ops, entanglement mechanics)
// 11. External/Public Functions (ERC721 interface, mint/burn, admin, entanglement flows, state/correlation ops, dynamic traits, queries)

// Function Summary (34+ functions):
// ERC721 Interface:
// 1.  balanceOf(address owner)
// 2.  ownerOf(uint256 tokenId)
// 3.  approve(address to, uint256 tokenId)
// 4.  getApproved(uint256 tokenId)
// 5.  setApprovalForAll(address operator, bool approved)
// 6.  isApprovedForAll(address owner, address operator)
// 7.  transferFrom(address from, address to, uint256 tokenId)
// 8.  safeTransferFrom(address from, address to, uint256 tokenId)
// 9.  safeTransferFrom(address from, address to, uint256 tokenId, bytes data)
// 10. supportsInterface(bytes4 interfaceId)
// 11. tokenURI(uint256 tokenId)

// Basic Token Management:
// 12. mint(address to)
// 13. burn(uint256 tokenId)
// 14. setTokenUriPrefix(string memory uriPrefix)

// Entanglement Management (Request/Accept Flow):
// 15. requestEntanglement(uint256 tokenId1, uint256 tokenId2)
// 16. acceptEntanglementRequest(uint256 tokenId)
// 17. rejectEntanglementRequest(uint256 tokenId)
// 18. cancelEntanglementRequest(uint256 tokenId)

// Disentanglement Management (Proposal/Accept Flow):
// 19. proposeDisentanglement(uint256 tokenId)
// 20. acceptDisentanglementProposal(uint256 tokenId)
// 21. rejectDisentanglementProposal(uint256 tokenId)
// 22. cancelDisentanglementProposal(uint256 tokenId)
// 23. forceDisentanglePair(uint256 tokenId1, uint256 tokenId2) (Owner only)

// Quantum State & Correlation:
// 24. isTokenEntangled(uint256 tokenId)
// 25. getEntangledToken(uint256 tokenId)
// 26. mutateQuantumState(uint256 tokenId, int256 newValue)
// 27. getQuantumState(uint256 tokenId)
// 28. syncQuantumState(uint256 tokenId)
// 29. getCorrelationFactor(uint256 tokenId)
// 30. updateCorrelationFactor(uint256 tokenId, uint256 newFactor)

// Dynamic & Query Functions:
// 31. getDynamicTrait(uint256 tokenId)
// 32. checkPendingEntanglementRequest(uint256 tokenId)
// 33. checkPendingDisentanglementProposal(uint256 tokenId)
// 34. getTokensByOwner(address owner) (Note: Potentially inefficient for many tokens)

// --- End Outline & Function Summary ---


// --- Interfaces ---
/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

/**
 * @dev Interface of the ERC165 standard, as defined in the https://eips.ethereum.org/EIPS/eip-165[EIP].
 * Implementers using this interface should register a selector for this interface, as well as all other interfaces
 * or interfaces of interfaces that they implement.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-to-detect-supported-interfaces[EIP section]
     * to learn more about how these ids are computed.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Interface of the ERC721 Receiver standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-721[EIP].
 * Used in `safeTransferFrom`.
 */
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// --- Basic Ownable Implementation ---
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an owner who can be granted exclusive access to specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the caller is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract for good. Removes the owner role from the end account.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access control.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// --- Contract Implementation ---
contract QuantumEntangledERC721 is IERC721, IERC165, Ownable {

    // --- Errors ---
    error TokenDoesNotExist();
    error NotOwnerOrApproved();
    error NotApprovedForAll();
    error TransferToZeroAddress();
    error NotImplemented(); // For safeTransferFrom with data check
    error CannotTransferToNonERC721Receiver();
    error CannotEntangleWithSelf();
    error TokensAlreadyEntangled();
    error TokensNotEntangled();
    error EntanglementRequestExists();
    error NoEntanglementRequestPending();
    error NotEntanglementRequester();
    error NotEntanglementRecipientOwner();
    error EntanglementRequestNotPending();
    error DisentanglementProposalExists();
    error NoDisentanglementProposalPending();
    error NotDisentanglementProposer();
    error NotEntangledPartnerOwner();
    error DisentanglementProposalNotPending();
    error MustBeEntangledForAction();
    error MustNotBeEntangledForAction();
    error OwnerRequiredForAction();
    error EntanglementStateMismatch();
    error ZeroAddressNotValidOwner();

    // --- State Variables ---
    string private _name;
    string private _symbol;
    string private _tokenUriPrefix;

    uint256 private _tokenCounter;

    // ERC721 core state
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Quantum entanglement state
    mapping(uint256 => uint256) private _entangledToken; // token ID => entangled token ID (0 if not entangled)

    // Quantum state and correlation
    mapping(uint256 => int256) private _quantumState; // token ID => its individual quantum state
    mapping(uint256 => uint256) private _correlationFactor; // token ID => shared correlation factor (only meaningful if entangled)

    // Entanglement Request State: tokenId1 => {tokenId2: owner2}
    mapping(uint256 => mapping(uint256 => address)) private _entanglementRequests; // tokenId1 (requester) => tokenId2 (recipient) => owner of tokenId2 at time of request

    // Disentanglement Proposal State: tokenId1 => {tokenId2: proposer}
    mapping(uint256 => mapping(uint256 => address)) private _disentanglementProposals; // tokenId1 (proposer) => tokenId2 (partner) => proposer address


    // --- Events ---
    event TokensEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed owner1, address indexed owner2);
    event TokensDisentangled(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed owner1, address indexed owner2);
    event QuantumStateMutated(uint256 indexed tokenId, int256 indexed oldState, int256 indexed newState);
    event QuantumStateSynced(uint256 indexed tokenId1, uint256 indexed tokenId2, int256 indexed state1, int256 indexed state2);
    event CorrelationFactorUpdated(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed newFactor);
    event EntanglementRequestSent(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed requester, address indexed recipientOwner);
    event EntanglementRequestAccepted(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed requester, address indexed recipientOwner);
    event EntanglementRequestRejected(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed requester, address indexed recipientOwner);
    event EntanglementRequestCancelled(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed requester, address indexed recipientOwner);
    event DisentanglementProposalSent(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed proposer);
    event DisentanglementProposalAccepted(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed proposer, address indexed partnerOwner);
    event DisentanglementProposalRejected(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed proposer, address indexed partnerOwner);
    event DisentanglementProposalCancelled(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed proposer);


    // --- Modifiers ---
    modifier isEntangled(uint256 tokenId) {
        require(_entangledToken[tokenId] != 0, MustBeEntangledForAction.selector);
        _;
    }

    modifier notEntangled(uint256 tokenId) {
        require(_entangledToken[tokenId] == 0, MustNotBeEntangledForAction.selector);
        _;
    }

    modifier areEntangledWithEachOther(uint256 tokenId1, uint256 tokenId2) {
        require(_entangledToken[tokenId1] == tokenId2 && _entangledToken[tokenId2] == tokenId1, EntanglementStateMismatch.selector);
        _;
    }

    modifier isTokenOwner(uint256 tokenId) {
        require(_owners[tokenId] == msg.sender, OwnerRequiredForAction.selector);
        _;
    }

    modifier isEntangledTokenOwner(uint256 tokenId) {
        uint256 entangledTokenId = _entangledToken[tokenId];
        require(entangledTokenId != 0, MustBeEntangledForAction.selector); // Ensure it's entangled first
        require(_owners[entangledTokenId] == msg.sender, OwnerRequiredForAction.selector);
        _;
    }


    // --- Constructor ---
    constructor(string memory name_, string memory symbol_, string memory uriPrefix_) Ownable() {
        _name = name_;
        _symbol = symbol_;
        _tokenUriPrefix = uriPrefix_;
        _tokenCounter = 0;
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Checks if a token exists.
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Throws if `tokenId` is not in the contract.
     */
    function _requireMinted(uint256 tokenId) internal view {
        require(_exists(tokenId), TokenDoesNotExist.selector);
    }

    /**
     * @dev Safely mints a new token to `to`.
     * Checks if `to` is a smart contract, and if so, calls `onERC721Received`.
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _mint(to, tokenId);
        // Basic check, a more robust check involves calling onERC721Received
        // Skipping full IERC721Receiver check for brevity in this example,
        // but in a real contract you would implement the standard check.
        // require(_checkOnERC721Received(address(0), to, tokenId, ""), CannotTransferToNonERC721Receiver.selector);
    }

    /**
     * @dev Mints a new token to `to`.
     * Unlike `_safeMint`, this doesn't check whether `to` is a smart contract.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), TransferToZeroAddress.selector);
        require(!_exists(tokenId), "ERC721: token already minted"); // Using string error here for variety
        _balances[to]++;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }


    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     * Internal function without access checks.
     * It handles auto-disentanglement on transfer.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(_owners[tokenId] == from, "ERC721: transfer from incorrect owner"); // Using string error here for variety
        require(to != address(0), TransferToZeroAddress.selector);

        _checkEntangledAndDisentangle(tokenId); // Auto-disentangle on transfer

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Auto-disentangles a token if it's entangled before a transfer or burn.
     */
    function _checkEntangledAndDisentangle(uint256 tokenId) internal {
        uint256 entangledTokenId = _entangledToken[tokenId];
        if (entangledTokenId != 0) {
            _disentanglePair(tokenId, entangledTokenId);
            // Optionally reset quantum state or correlation here on disentanglement
            // For simplicity, let's keep the state/correlation but the link is broken.
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(_owners[tokenId], to, tokenId);
    }

     /**
     * @dev Burns `tokenId`.
     * See {ERC721-_burn}.
     * It handles auto-disentanglement on burn.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner_ = _owners[tokenId];
        require(owner_ != address(0), TokenDoesNotExist.selector);

        _checkEntangledAndDisentangle(tokenId); // Auto-disentangle on burn

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner_]--;
        delete _owners[tokenId];
        delete _tokenApprovals[tokenId];
        delete _quantumState[tokenId];
        delete _correlationFactor[tokenId]; // Correlation is per-token but shared when entangled, reset on burn

        emit Transfer(owner_, address(0), tokenId);
    }

    /**
     * @dev Internally entangles two tokens. Clears any pending requests/proposals.
     */
    function _entanglePair(uint256 tokenId1, uint256 tokenId2) internal {
        _requireMinted(tokenId1);
        _requireMinted(tokenId2);
        require(_entangledToken[tokenId1] == 0 && _entangledToken[tokenId2] == 0, TokensAlreadyEntangled.selector);
        require(tokenId1 != tokenId2, CannotEntangleWithSelf.selector);

        address owner1 = _owners[tokenId1];
        address owner2 = _owners[tokenId2];
        require(owner1 != address(0) && owner2 != address(0), TokenDoesNotExist.selector); // Should be covered by _requireMinted

        _entangledToken[tokenId1] = tokenId2;
        _entangledToken[tokenId2] = tokenId1;

        // Initialize or sync correlation - let's just set a default or average existing ones
        uint256 initialCorrelation = (_correlationFactor[tokenId1] + _correlationFactor[tokenId2]) / 2;
        _correlationFactor[tokenId1] = initialCorrelation; // Correlation is shared, store it against one or both
        _correlationFactor[tokenId2] = initialCorrelation; // Redundant but ensures lookup works from either end

        // Clear any pending requests/proposals involving these tokens
        delete _entanglementRequests[tokenId1][tokenId2];
        delete _entanglementRequests[tokenId2][tokenId1];
        delete _disentanglementProposals[tokenId1][tokenId2];
        delete _disentanglementProposals[tokenId2][tokenId1];


        emit TokensEntangled(tokenId1, tokenId2, owner1, owner2);
        emit CorrelationFactorUpdated(tokenId1, tokenId2, initialCorrelation);
        // Optionally sync quantum states immediately or leave for separate action
        // _syncQuantumState(tokenId1, tokenId2); // Can call sync here if desired
    }

    /**
     * @dev Internally disentangles two tokens. Clears any pending proposals.
     */
    function _disentanglePair(uint256 tokenId1, uint256 tokenId2) internal {
         require(_entangledToken[tokenId1] == tokenId2 && _entangledToken[tokenId2] == tokenId1, TokensNotEntangled.selector);

        address owner1 = _owners[tokenId1];
        address owner2 = _owners[tokenId2];
        // Owners might be address(0) if one was burned, but the entangled link must exist

        delete _entangledToken[tokenId1];
        delete _entangledToken[tokenId2];

        // Optionally reset correlation factor on disentanglement or split it
        // For simplicity, let's reset it to 0 or a default. Or leave as is.
        // Let's leave as is for this example, allowing the factor to persist.

        // Clear any pending disentanglement proposals
        delete _disentanglementProposals[tokenId1][tokenId2];
        delete _disentanglementProposals[tokenId2][tokenId1];

        // Note: Entanglement requests should have been cleared upon successful entanglement

        emit TokensDisentangled(tokenId1, tokenId2, owner1, owner2);
    }


    // --- External/Public Functions (ERC721 Interface) ---

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        // ERC721 interface id
        bytes4 interfaceIdERC721 = 0x80ac58cd;
        // ERC721 Metadata Extension interface id (optional but common)
        bytes4 interfaceIdERC721Metadata = 0x5b5e139f;
        // ERC165 interface id itself
        bytes4 interfaceIdERC165 = 0x01ffc9a7;

        return interfaceId == interfaceIdERC721 ||
               interfaceId == interfaceIdERC721Metadata ||
               interfaceId == interfaceIdERC165;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner_) public view virtual returns (uint256) {
        require(owner_ != address(0), ZeroAddressNotValidOwner.selector);
        return _balances[owner_];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner_ = _owners[tokenId];
        require(owner_ != address(0), TokenDoesNotExist.selector);
        return owner_;
    }

     /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual {
        address owner_ = ownerOf(tokenId); // Checks existence
        require(to != owner_, "ERC721: approval to current owner"); // Using string error here for variety

        require(
            msg.sender == owner_ || isApprovedForAll(owner_, msg.sender),
            NotOwnerOrApproved.selector
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireMinted(tokenId);
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        require(operator != msg.sender, "ERC721: approve to caller"); // Using string error here for variety
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner_, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner_][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - *Custom:* Automatically disentangles the token before transfer.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            NotOwnerOrApproved.selector
        );

        _transfer(from, to, tokenId);
    }

     /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver}
     *   and return the acceptance magic value.
     * - *Custom:* Automatically disentangles the token before transfer.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-safeTransferFrom-address-address-uint256-}[`safeTransferFrom`], with data.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver}
     *   and return the acceptance magic value.
     * - *Custom:* Automatically disentangles the token before transfer.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            NotOwnerOrApproved.selector
        );
        _transfer(from, to, tokenId); // _transfer handles disentanglement
        // Skipping full IERC721Receiver check for brevity in this example,
        // but in a real contract you would implement the standard check.
        // require(_checkOnERC721Received(from, to, tokenId, data), CannotTransferToNonERC721Receiver.selector);
        if (to.code.length > 0) {
             // Basic check: just ensure it's not a zero address contract,
             // real implementation needs full IERC721Receiver check.
             // This is marked as NotImplented error as the full check is complex.
            revert NotImplemented();
        }
    }

    /**
     * @dev Check if `spender` is owner or approved to manage `tokenId`.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner_ = ownerOf(tokenId); // Checks existence
        return (spender == owner_ || getApproved(tokenId) == spender || isApprovedForAll(owner_, spender));
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * @dev Overridden to potentially make the URI dynamic based on entanglement state,
     * quantum state, and correlation factor.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory base = _tokenUriPrefix;
        if (bytes(base).length == 0) {
            return "";
        }

        string memory uri = string.concat(base, _toString(tokenId));

        // Example of dynamic URI based on state: Append query parameters
        if (isTokenEntangled(tokenId)) {
            uint256 entangledPartnerId = _entangledToken[tokenId];
            uint256 correlation = _correlationFactor[tokenId]; // Shared correlation
            int256 state = _quantumState[tokenId]; // Individual state

             uri = string.concat(uri, "?entangled=true", "&partner=", _toString(entangledPartnerId),
                                 "&state=", _toString(state), "&correlation=", _toString(correlation));
        } else {
             int256 state = _quantumState[tokenId]; // Individual state
             uri = string.concat(uri, "?entangled=false", "&state=", _toString(state));
        }

        // In a real dApp, an off-chain service would use this URI to fetch metadata,
        // read the query params, and generate dynamic JSON including traits based on the state.
        return uri;
    }

    // --- Basic Token Management ---

    /**
     * @dev Mints a new token and assigns it to `to`.
     * Initializes the token with a default quantum state and correlation factor.
     * The token starts in a non-entangled state.
     */
    function mint(address to) public onlyOwner returns (uint256) {
        uint256 newTokenId = _tokenCounter;
        _tokenCounter++;
        _safeMint(to, newTokenId);

        // Initialize quantum state and correlation
        _quantumState[newTokenId] = 0; // Default initial state
        _correlationFactor[newTokenId] = 100; // Default initial correlation

        return newTokenId;
    }

    /**
     * @dev Burns a token, removing it from existence.
     * Automatically disentangles the token if it is entangled.
     */
    function burn(uint256 tokenId) public virtual {
        address owner_ = ownerOf(tokenId); // Checks existence

        require(
            msg.sender == owner_ || isApprovedForAll(owner_, msg.sender),
            NotOwnerOrApproved.selector
        );

        _burn(tokenId); // _burn handles disentanglement
    }

    /**
     * @dev Owner sets the base URI for token metadata.
     * This prefix is used in `tokenURI`.
     */
    function setTokenUriPrefix(string memory uriPrefix_) public onlyOwner {
        _tokenUriPrefix = uriPrefix_;
    }

    /**
     * @dev Helper function to get the current token URI prefix.
     */
    function getTokenUriPrefix() public view returns (string memory) {
        return _tokenUriPrefix;
    }

    // --- Entanglement Management ---

    /**
     * @dev Owner of `tokenId1` requests entanglement with `tokenId2`.
     * Requires both tokens to exist and not already be entangled.
     * `tokenId2` must be owned by `to`.
     * Creates a pending request that the owner of `tokenId2` must accept.
     */
    function requestEntanglement(uint256 tokenId1, uint256 tokenId2) public virtual isTokenOwner(tokenId1) notEntangled(tokenId1) notEntangled(tokenId2) {
        _requireMinted(tokenId2);
        require(tokenId1 != tokenId2, CannotEntangleWithSelf.selector);

        address owner2 = ownerOf(tokenId2); // Checks existence
        require(owner2 != address(0), TokenDoesNotExist.selector); // Redundant check

        // Ensure no pending request already exists between this pair (in either direction)
        require(_entanglementRequests[tokenId1][tokenId2] == address(0) && _entanglementRequests[tokenId2][tokenId1] == address(0), EntanglementRequestExists.selector);

        _entanglementRequests[tokenId1][tokenId2] = owner2; // Store owner2's address at request time

        emit EntanglementRequestSent(tokenId1, tokenId2, msg.sender, owner2);
    }

     /**
     * @dev Owner of `tokenId` accepts an incoming entanglement request.
     * `tokenId` must be the recipient token in a pending request.
     * Requires `msg.sender` to be the owner of `tokenId`.
     * If successful, the two tokens become entangled.
     */
    function acceptEntanglementRequest(uint256 tokenId) public virtual isTokenOwner(tokenId) notEntangled(tokenId) {
        uint256 partnerTokenId = 0;
        address requesterOwner = address(0);

        // Find which token requested entanglement with this one
        for (uint256 i = 0; i < _tokenCounter; i++) { // Potentially inefficient loop
            if (_exists(i) && _entanglementRequests[i][tokenId] == msg.sender) {
                partnerTokenId = i;
                requesterOwner = ownerOf(i); // Get current owner of the partner token
                break;
            }
        }

        require(partnerTokenId != 0, NoEntanglementRequestPending.selector);
        require(_entanglementRequests[partnerTokenId][tokenId] != address(0), NoEntanglementRequestPending.selector); // Double check state
        // Crucially, check if the *current* owner of the requester token is still the same as when requested
        // This prevents requests being accepted after the requesting token has been transferred
        // Alternatively, you could allow it and just use the current owner. Sticking to original owner for stronger link.
        // require(ownerOf(partnerTokenId) == requesterOwner, "Entanglement: Requester token owner changed"); // Strict version
        // Let's use the simpler version that allows the current owner to accept on behalf of the token.
        // The request is associated with the *token*, not the owner at request time.

        // Ensure the partner token is also not entangled *now*
        require(_entangledToken[partnerTokenId] == 0, TokensAlreadyEntangled.selector);

        // Clear the specific request entry before entangling
        delete _entanglementRequests[partnerTokenId][tokenId];

        _entanglePair(partnerTokenId, tokenId);

        emit EntanglementRequestAccepted(partnerTokenId, tokenId, ownerOf(partnerTokenId), msg.sender);
    }

    /**
     * @dev Owner of `tokenId` rejects an incoming entanglement request.
     * `tokenId` must be the recipient token in a pending request.
     * Requires `msg.sender` to be the owner of `tokenId`.
     */
    function rejectEntanglementRequest(uint256 tokenId) public virtual isTokenOwner(tokenId) {
        uint256 partnerTokenId = 0;
        address requesterOwner = address(0);

         // Find which token requested entanglement with this one
        for (uint256 i = 0; i < _tokenCounter; i++) { // Potentially inefficient loop
            if (_exists(i) && _entanglementRequests[i][tokenId] == msg.sender) {
                partnerTokenId = i;
                requesterOwner = ownerOf(i); // Get current owner of the partner token
                break;
            }
        }

        require(partnerTokenId != 0, NoEntanglementRequestPending.selector);
        require(_entanglementRequests[partnerTokenId][tokenId] != address(0), NoEntanglementRequestPending.selector); // Double check state

        // Clear the request entry
        delete _entanglementRequests[partnerTokenId][tokenId];

        emit EntanglementRequestRejected(partnerTokenId, tokenId, ownerOf(partnerTokenId), msg.sender);
    }

    /**
     * @dev Owner of `tokenId` cancels their outgoing entanglement request.
     * `tokenId` must be the requester token in a pending request.
     * Requires `msg.sender` to be the owner of `tokenId`.
     */
    function cancelEntanglementRequest(uint256 tokenId) public virtual isTokenOwner(tokenId) {
         uint256 recipientTokenId = 0;
         address recipientOwner = address(0);

         // Find which token this token requested entanglement with
        for (uint256 i = 0; i < _tokenCounter; i++) { // Potentially inefficient loop
            if (_exists(i) && _entanglementRequests[tokenId][i] != address(0)) {
                 // Check if the stored owner matches the current owner of the recipient token
                 // Or decide if the request is tied to the token regardless of recipient owner change
                 // Let's tie it to the token, so any owner can accept/reject.
                recipientTokenId = i;
                recipientOwner = _entanglementRequests[tokenId][i]; // Stored owner
                break;
            }
        }

        require(recipientTokenId != 0, NoEntanglementRequestPending.selector);
        require(_entanglementRequests[tokenId][recipientTokenId] != address(0), NoEntanglementRequestPending.selector); // Double check state

        // Clear the request entry
        delete _entanglementRequests[tokenId][recipientTokenId];

        emit EntanglementRequestCancelled(tokenId, recipientTokenId, msg.sender, recipientOwner);
    }


    // --- Disentanglement Management ---

    /**
     * @dev Owner of `tokenId` proposes disentanglement from its entangled partner.
     * Requires the token to be entangled.
     * Creates a pending proposal that the owner of the entangled partner must accept.
     */
    function proposeDisentanglement(uint256 tokenId) public virtual isTokenOwner(tokenId) isEntangled(tokenId) {
        uint256 entangledPartnerId = _entangledToken[tokenId];
        require(_disentanglementProposals[tokenId][entangledPartnerId] == address(0) && _disentanglementProposals[entangledPartnerId][tokenId] == address(0), DisentanglementProposalExists.selector);

        _disentanglementProposals[tokenId][entangledPartnerId] = msg.sender; // Store proposer address

        emit DisentanglementProposalSent(tokenId, entangledPartnerId, msg.sender);
    }

     /**
     * @dev Owner of `tokenId` accepts a disentanglement proposal from its entangled partner.
     * `tokenId` must be the recipient of a pending disentanglement proposal.
     * Requires `msg.sender` to be the owner of `tokenId`.
     * If successful, the two tokens become disentangled.
     */
    function acceptDisentanglementProposal(uint256 tokenId) public virtual isTokenOwner(tokenId) isEntangled(tokenId) {
        uint256 entangledPartnerId = _entangledToken[tokenId];
        address proposer = _disentanglementProposals[entangledPartnerId][tokenId];

        require(proposer != address(0), NoDisentanglementProposalPending.selector);
        // Optionally check if the *current* owner of the proposer token is still the same
        // require(ownerOf(entangledPartnerId) == proposer, "Disentanglement: Proposer token owner changed"); // Strict version

        // Clear the specific proposal entry before disentangling
        delete _disentanglementProposals[entangledPartnerId][tokenId];

        _disentanglePair(entangledPartnerId, tokenId);

        emit DisentanglementProposalAccepted(entangledPartnerId, tokenId, proposer, msg.sender);
    }

    /**
     * @dev Owner of `tokenId` rejects a disentanglement proposal from its entangled partner.
     * `tokenId` must be the recipient of a pending disentanglement proposal.
     * Requires `msg.sender` to be the owner of `tokenId`.
     */
    function rejectDisentanglementProposal(uint256 tokenId) public virtual isTokenOwner(tokenId) isEntangled(tokenId) {
        uint256 entangledPartnerId = _entangledToken[tokenId];
        address proposer = _disentanglementProposals[entangledPartnerId][tokenId];

        require(proposer != address(0), NoDisentanglementProposalPending.selector);

        // Clear the proposal entry
        delete _disentanglementProposals[entangledPartnerId][tokenId];

        emit DisentanglementProposalRejected(entangledPartnerId, tokenId, proposer, msg.sender);
    }

    /**
     * @dev Owner of `tokenId` cancels their disentanglement proposal.
     * `tokenId` must be the token that initiated the proposal.
     * Requires `msg.sender` to be the owner of `tokenId`.
     */
    function cancelDisentanglementProposal(uint256 tokenId) public virtual isTokenOwner(tokenId) isEntangled(tokenId) {
         uint256 entangledPartnerId = _entangledToken[tokenId];
         address proposer = _disentanglementProposals[tokenId][entangledPartnerId];

         require(proposer != address(0), NoDisentanglementProposalPending.selector);
         require(proposer == msg.sender, NotDisentanglementProposer.selector); // Must be the original proposer

        // Clear the proposal entry
        delete _disentanglementProposals[tokenId][entangledPartnerId];

        emit DisentanglementProposalCancelled(tokenId, entangledPartnerId, msg.sender);
    }

    /**
     * @dev Allows the contract owner to force disentanglement of two tokens.
     * Can be used for emergency or administrative purposes.
     */
    function forceDisentanglePair(uint256 tokenId1, uint256 tokenId2) public onlyOwner {
        _requireMinted(tokenId1);
        _requireMinted(tokenId2);
        _disentanglePair(tokenId1, tokenId2);
    }

    // --- Quantum State & Correlation ---

    /**
     * @dev Checks if a token is currently entangled with another.
     */
    function isTokenEntangled(uint256 tokenId) public view virtual returns (bool) {
        return _entangledToken[tokenId] != 0;
    }

    /**
     * @dev Returns the ID of the token entangled with `tokenId`.
     * Returns 0 if the token is not entangled.
     */
    function getEntangledToken(uint256 tokenId) public view virtual returns (uint256) {
        return _entangledToken[tokenId];
    }

    /**
     * @dev Allows the owner of a token to change its individual quantum state.
     * This action can be performed regardless of entanglement status, but
     * the effect on the entangled partner is only through explicit syncing (`syncQuantumState`).
     */
    function mutateQuantumState(uint256 tokenId, int256 newValue) public virtual isTokenOwner(tokenId) {
        _requireMinted(tokenId); // Redundant due to isTokenOwner
        int256 oldState = _quantumState[tokenId];
        _quantumState[tokenId] = newValue;
        emit QuantumStateMutated(tokenId, oldState, newValue);

        // Optional: Automatically trigger a mild sync effect or correlation change here
    }

    /**
     * @dev Returns the current quantum state of a token.
     */
    function getQuantumState(uint256 tokenId) public view virtual returns (int256) {
        _requireMinted(tokenId);
        return _quantumState[tokenId];
    }

     /**
     * @dev Triggers a synchronization of quantum states between two entangled tokens.
     * Can be called by the owner of either entangled token.
     * The synchronization logic is a metaphorical representation. Here, it averages the states.
     * It also slightly adjusts the correlation factor based on the difference in states.
     */
    function syncQuantumState(uint256 tokenId) public virtual isEntangled(tokenId) isTokenOwner(tokenId) {
        uint256 partnerTokenId = _entangledToken[tokenId];
        require(ownerOf(partnerTokenId) != address(0), TokenDoesNotExist.selector); // Partner must exist

        int256 state1 = _quantumState[tokenId];
        int256 state2 = _quantumState[partnerTokenId];

        // Synchronization logic (example: average the states)
        int256 syncedState = (state1 + state2) / 2;

        _quantumState[tokenId] = syncedState;
        _quantumState[partnerTokenId] = syncedState;

        emit QuantumStateSynced(tokenId, partnerTokenId, syncedState, syncedState);
        emit QuantumStateMutated(tokenId, state1, syncedState);
        emit QuantumStateMutated(partnerTokenId, state2, syncedState);


        // Adjust correlation based on state difference (example: smaller diff -> higher correlation)
        // abs(state1 - state2)
        int256 stateDiff = state1 > state2 ? state1 - state2 : state2 - state1;
        uint256 currentCorrelation = _correlationFactor[tokenId]; // Should be same as partner

        // Max correlation is, say, 200. Min is 0. Default 100.
        // If stateDiff is large, correlation decreases. If small, increases.
        uint256 correlationChange = uint256(stateDiff > 100 ? 100 : stateDiff); // Scale difference
        uint256 newCorrelation;

        if (stateDiff < 50) { // States are relatively close
             newCorrelation = currentCorrelation + (50 - correlationChange); // Increase correlation
        } else { // States are far apart
             newCorrelation = currentCorrelation > correlationChange ? currentCorrelation - correlationChange : 0; // Decrease correlation
        }

        // Cap correlation
        newCorrelation = newCorrelation > 200 ? 200 : newCorrelation;

        _correlationFactor[tokenId] = newCorrelation;
        _correlationFactor[partnerTokenId] = newCorrelation;

        emit CorrelationFactorUpdated(tokenId, partnerTokenId, newCorrelation);
    }

     /**
     * @dev Returns the correlation factor for a token.
     * If entangled, this value is shared with the partner token.
     */
    function getCorrelationFactor(uint256 tokenId) public view virtual returns (uint256) {
        _requireMinted(tokenId);
        return _correlationFactor[tokenId];
    }

     /**
     * @dev Allows the owner of an entangled token to update the shared correlation factor.
     * This is an explicit way to influence the link between tokens.
     */
    function updateCorrelationFactor(uint256 tokenId, uint256 newFactor) public virtual isTokenOwner(tokenId) isEntangled(tokenId) {
        uint256 partnerTokenId = _entangledToken[tokenId];
        require(ownerOf(partnerTokenId) != address(0), TokenDoesNotExist.selector); // Partner must exist

        // Cap correlation (example max 200)
        uint256 cappedFactor = newFactor > 200 ? 200 : newFactor;

        _correlationFactor[tokenId] = cappedFactor;
        _correlationFactor[partnerTokenId] = cappedFactor;

        emit CorrelationFactorUpdated(tokenId, partnerTokenId, cappedFactor);
    }


    // --- Dynamic & Query Functions ---

    /**
     * @dev Example function to derive a dynamic trait based on the token's state.
     * This is a view function; the actual trait could influence off-chain metadata or game logic.
     * Example: A 'stability' trait based on correlation and state variance.
     */
    function getDynamicTrait(uint256 tokenId) public view virtual returns (string memory trait) {
        _requireMinted(tokenId);

        int256 state = _quantumState[tokenId];
        uint256 correlation = _correlationFactor[tokenId];
        bool isEntangled_ = isTokenEntangled(tokenId);

        string memory entanglementStatus = isEntangled_ ? "Entangled" : "Singular";
        string memory stateDescription;
        string memory correlationDescription;

        // Describe state
        if (state > 100) stateDescription = "High State";
        else if (state < -100) stateDescription = "Low State";
        else stateDescription = "Mid State";

        // Describe correlation (more relevant if entangled)
        if (correlation > 180) correlationDescription = "Highly Correlated";
        else if (correlation < 20 && isEntangled_) correlationDescription = "Weakly Correlated";
        else correlationDescription = "Normally Correlated";


        // Combine for a hypothetical "Quantum Aura" trait
        return string.concat("Quantum Aura: ", entanglementStatus, ", ", stateDescription, ", ", correlationDescription);
    }

    /**
     * @dev Checks the status of a pending entanglement request for `tokenId`.
     * Returns (requesterTokenId, recipientTokenId, requesterOwner, recipientOwner, isPending)
     * where requesterTokenId/recipientTokenId is 0 if no request involves `tokenId`.
     * Note: This searches in both directions (as requester and as recipient).
     */
    function checkPendingEntanglementRequest(uint256 tokenId) public view virtual returns (uint256 requesterTokenId, uint256 recipientTokenId, address requesterOwner, address recipientOwner, bool isPending) {
         _requireMinted(tokenId);

        // Check if tokenId is the requester
        for (uint256 i = 0; i < _tokenCounter; i++) { // Potentially inefficient loop
             if (_exists(i) && _entanglementRequests[tokenId][i] != address(0)) {
                return (tokenId, i, ownerOf(tokenId), _entanglementRequests[tokenId][i], true);
             }
        }

        // Check if tokenId is the recipient
         for (uint256 i = 0; i < _tokenCounter; i++) { // Potentially inefficient loop
             if (_exists(i) && _entanglementRequests[i][tokenId] != address(0)) {
                 return (i, tokenId, ownerOf(i), _entanglementRequests[i][tokenId], true);
             }
         }

        return (0, 0, address(0), address(0), false);
    }


    /**
     * @dev Checks the status of a pending disentanglement proposal for `tokenId`.
     * Returns (proposerTokenId, partnerTokenId, proposerAddress, isPending)
     * where proposerTokenId/partnerTokenId is 0 if no proposal involves `tokenId`.
     * Note: This searches in both directions (as proposer and as proposed-to).
     */
     function checkPendingDisentanglementProposal(uint256 tokenId) public view virtual returns (uint256 proposerTokenId, uint256 partnerTokenId, address proposerAddress, bool isPending) {
         _requireMinted(tokenId);
         uint256 entangledPartnerId = _entangledToken[tokenId]; // Need partner ID to check proposals

         if (entangledPartnerId == 0) {
             return (0, 0, address(0), false); // Not entangled, no proposal possible
         }

         // Check if tokenId is the proposer
         if (_disentanglementProposals[tokenId][entangledPartnerId] != address(0)) {
             return (tokenId, entangledPartnerId, _disentanglementProposals[tokenId][entangledPartnerId], true);
         }

         // Check if tokenId is the proposed-to partner
         if (_disentanglementProposals[entangledPartnerId][tokenId] != address(0)) {
              return (entangledPartnerId, tokenId, _disentanglementProposals[entangledPartnerId][tokenId], true);
         }

         return (0, 0, address(0), false);
     }


    /**
     * @dev Returns an array of token IDs owned by an address.
     * NOTE: This is inefficient for owners with many tokens as it iterates through all possible token IDs.
     * Use with caution in production, or implement a more efficient enumeration method.
     */
    function getTokensByOwner(address owner_) public view returns (uint256[] memory) {
        require(owner_ != address(0), ZeroAddressNotValidOwner.selector);
        uint256 tokenCount = _balances[owner_];
        if (tokenCount == 0) {
            return new uint256[](0);
        }

        uint256[] memory tokenIds = new uint256[](tokenCount);
        uint256 index = 0;
        // Iterate through all possible token IDs up to the current counter
        for (uint256 i = 0; i < _tokenCounter; i++) {
            if (_exists(i) && _owners[i] == owner_) {
                tokenIds[index] = i;
                index++;
                if (index == tokenCount) break; // Stop once we've found all tokens for this owner
            }
        }
        return tokenIds;
    }

    // --- Utility Functions ---

    /**
     * @dev Converts a `uint256` to its ASCII string representation.
     */
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

     /**
     * @dev Converts an `int256` to its ASCII string representation.
     */
    function _toString(int256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        bool negative = value < 0;
        if (negative) {
            value = -value;
        }
        uint26 temp = uint256(value);
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        if (negative) {
            digits++;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits;
        while (value != 0) {
            index -= 1;
            buffer[index] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        if (negative) {
            index -= 1;
            buffer[index] = '-';
        }
        return string(buffer);
    }


     // Note: Skipping the full IERC721Receiver check implementation for brevity
     // as it requires more complex introspection logic. A real contract would
     // include: `function _checkOnERC721Received(...) internal returns (bool)`
     // and use `to.isContract()` and `Address.functionCall()`.
}
```