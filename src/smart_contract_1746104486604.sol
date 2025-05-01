Okay, let's create a sophisticated smart contract concept that combines elements of dynamic NFTs, verifiable randomness, time-based mechanics, and intertwined state – inspired conceptually by quantum entanglement.

We'll call it `QuantumEntanglementNFT`. It will be an ERC721-like contract where tokens can be paired and "entangled". Actions on one token might affect its entangled partner, facilitated by on-chain state changes and randomness.

**Concepts Used:**

1.  **Dynamic NFTs:** Token metadata and properties change based on on-chain actions (`measureState`) and entanglement status.
2.  **Conceptual Quantum Entanglement:** Two tokens can be linked. Actions on one (like `measureState`) affect the pair. Transfers are restricted while entangled.
3.  **Chainlink VRF v2:** Used for verifiable randomness to drive the state changes during "measurement".
4.  **Access Control:** Fine-grained permissions for different actions (minting, configuration, admin).
5.  **Time-based Mechanics:** A time lock is required to detangle a pair.
6.  **Custom ERC721 Overrides:** Modifying transfer logic to enforce entanglement rules.
7.  **Request/Accept Flow:** Entanglement requires one party to request and the other to accept.

---

### **Smart Contract Outline: `QuantumEntanglementNFT`**

1.  **Contract Name:** `QuantumEntanglementNFT`
2.  **Inheritances:** `ERC721URIStorage` (for metadata), `AccessControl`, `VRFConsumerBaseV2`, `ReentrancyGuard`.
3.  **Key Concepts:** Dynamic NFT, Entanglement, Measurement (VRF-driven), Time-Locks, Roles.
4.  **Roles:**
    *   `DEFAULT_ADMIN_ROLE`: Full control, grants other roles.
    *   `MINTER_ROLE`: Can mint new tokens.
    *   `CONFIG_ROLE`: Can set configuration parameters (e.g., time locks, VRF details, base URI).
5.  **State Variables:**
    *   ERC721 state (token owner, approvals, etc.) - Handled by inherited contracts.
    *   Token counter.
    *   Entanglement state:
        *   `_isEntangled`: `mapping(uint256 => bool)`
        *   `_entangledPair`: `mapping(uint256 => uint256)` (tokenId1 => tokenId2)
    *   Entanglement Request state:
        *   `_pendingEntanglementRequests`: `mapping(uint256 => uint256)` (tokenId being requested => tokenId requesting)
    *   Detanglement state:
        *   `_detangleAvailableTime`: `mapping(uint256 => uint256)` (tokenId => timestamp when detangling is possible)
        *   `_detangleTimeLock`: `uint256` (Configurable time lock duration in seconds)
    *   Dynamic Properties:
        *   `_quantumCharge`: `mapping(uint256 => uint256)` (Example dynamic property)
        *   `_quantumState`: `mapping(uint256 => string)` (Example dynamic property)
        *   `_customProperties`: `mapping(uint256 => mapping(string => string))` (Admin-set properties)
    *   VRF State:
        *   `s_vrfCoordinator`: `address`
        *   `s_keyHash`: `bytes32`
        *   `s_subscriptionId`: `uint64`
        *   `s_callbackGasLimit`: `uint32`
        *   `s_requestConfirmations`: `uint16`
        *   `s_randomWords`: `uint32`
        *   `s_requests`: `mapping(uint256 => uint256)` (requestId => tokenId requesting measurement)
6.  **Events:** `Entangled`, `Detangled`, `MeasurementPerformed`, `PropertyChanged`, `EntanglementRequest`, `EntanglementRequestAccepted`, `EntanglementRequestCancelled`, `DetangleInitiated`.
7.  **Functions (Grouped by Category):**
    *   **Initialization & Base:** `constructor`, `supportsInterface`.
    *   **ERC721 Overrides/Extensions:** `_update`, `tokenURI`, `setBaseURI`.
    *   **Basic ERC721:** `mint`, `balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`.
    *   **Entanglement Management:** `requestEntanglement`, `acceptEntanglementRequest`, `cancelEntanglementRequest`, `isTokenEntangled`, `getEntangledToken`, `detanglePair`, `finalizeDetangle`.
    *   **Dynamic State & Measurement (VRF):** `measureState`, `fulfillRandomWords`, `_applyMeasurementEffect` (internal).
    *   **Property Getters/Setters:** `adminSetCustomProperty`, `getQuantumCharge`, `getQuantumState`, `getCustomProperty`.
    *   **Configuration:** `setDetangleTimeLock`, `getDetangleTimeLock`, `getDetangleAvailabilityTime`, `setVRFConfig`, `withdrawLink`.
    *   **Access Control:** `grantRole`, `revokeRole`, `renounceRole`, `hasRole`.

---

### **Function Summary**

1.  `constructor(address vrfCoordinator, bytes32 keyHash, uint64 subscriptionId, uint32 callbackGasLimit, uint16 requestConfirmations, uint32 numWords, string memory baseTokenURI)`: Initializes the contract, sets up Access Control roles, and configures Chainlink VRF parameters. Grants `DEFAULT_ADMIN_ROLE` to the deployer.
2.  `supportsInterface(bytes4 interfaceId) public view override returns (bool)`: Standard ERC165 function to declare supported interfaces (ERC721, AccessControl, VRFConsumerBaseV2).
3.  `_update(address to, uint256 tokenId, address auth) internal override returns (address)`: Internal override used by transfer functions. Modified to prevent transfers of entangled tokens.
4.  `mint(address to) public onlyRole(MINTER_ROLE) returns (uint256)`: Mints a new NFT and assigns it to the specified address. Assigns initial property values (e.g., quantumCharge=0, quantumState="Neutral").
5.  `tokenURI(uint256 tokenId) public view override returns (string memory)`: Returns the URI for the metadata of a given token. This function constructs a dynamic URI, potentially pointing to a metadata service that reads the on-chain properties (`_quantumCharge`, `_quantumState`, `_customProperties`) and generates the final JSON metadata.
6.  `setBaseURI(string memory newBaseURI) public onlyRole(CONFIG_ROLE)`: Allows the CONFIG_ROLE to update the base URI used by `tokenURI`.
7.  `balanceOf(address owner) public view override returns (uint256)`: Returns the number of tokens owned by an address.
8.  `ownerOf(uint256 tokenId) public view override returns (address)`: Returns the owner of a specific token.
9.  `approve(address to, uint256 tokenId) public override` : Approves an address to transfer a specific token.
10. `getApproved(uint256 tokenId) public view override returns (address)`: Gets the approved address for a specific token.
11. `setApprovalForAll(address operator, bool approved) public override`: Approves or revokes approval for an operator to manage all tokens owned by the caller.
12. `isApprovedForAll(address owner, address operator) public view override returns (bool)`: Checks if an operator is approved for all tokens of an owner.
13. `transferFrom(address from, address to, uint256 tokenId) public override`: Transfers a token from one address to another. Uses the overridden `_update` which prevents entangled transfers.
14. `safeTransferFrom(address from, address to, uint256 tokenId) public override`: Safely transfers a token, checking if the recipient can receive ERC721 tokens. Uses the overridden `_update`.
15. `requestEntanglement(uint256 tokenId1, uint256 tokenId2) public nonReentrant`: Initiates an entanglement request between `tokenId1` (caller's token) and `tokenId2`. Stores the request in `_pendingEntanglementRequests`. Requires caller owns `tokenId1`.
16. `acceptEntanglementRequest(uint256 tokenId1, uint256 tokenId2) public nonReentrant`: Accepts a pending entanglement request for `tokenId2` (caller's token) initiated by `tokenId1`. Requires caller owns `tokenId2`. Checks for valid pending request. If accepted, marks tokens as entangled, updates `_entangledPair`, clears the request, and emits `Entangled`.
17. `cancelEntanglementRequest(uint256 tokenId1, uint256 tokenId2) public nonReentrant`: Cancels a pending entanglement request for `tokenId2` (caller's token) initiated by `tokenId1`. Requires caller owns `tokenId2` or `tokenId1`. Clears the request.
18. `isTokenEntangled(uint256 tokenId) public view returns (bool)`: Checks if a token is currently entangled with another.
19. `getEntangledToken(uint256 tokenId) public view returns (uint256)`: Returns the tokenId of the token entangled with the given tokenId, or 0 if not entangled.
20. `detanglePair(uint256 tokenId) public nonReentrant`: Initiates the detanglement process for the pair that the given token belongs to. Requires caller owns the token. Sets the `_detangleAvailableTime` based on the current timestamp and `_detangleTimeLock`. Emits `DetangleInitiated`. Cannot be called if already initiating or not entangled.
21. `finalizeDetangle(uint256 tokenId) public nonReentrant`: Finalizes the detanglement process for the pair. Requires caller owns the token. Checks if the `_detangleAvailableTime` timestamp has passed. If so, clears entanglement state for both tokens in the pair and emits `Detangled`.
22. `measureState(uint256 tokenId) public nonReentrant`: Triggers a state "measurement" for an entangled pair. Requires caller owns the token and it must be entangled. Requests verifiable randomness from Chainlink VRF. Stores the VRF request ID linked to the token ID. Costs LINK for VRF request.
23. `fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override`: Chainlink VRF callback function. Automatically called by the VRF Coordinator once randomness is available. Uses the randomness to modify the properties (`_quantumCharge`, `_quantumState`) of the entangled pair associated with the `requestId`. Calls internal function `_applyMeasurementEffect`. Emits `MeasurementPerformed`.
24. `_applyMeasurementEffect(uint256 tokenId1, uint256 tokenId2, uint256 randomness) internal`: Internal function called by `fulfillRandomWords`. Uses the provided randomness to deterministically alter the state (`_quantumCharge`, `_quantumState`) of both `tokenId1` and `tokenId2` in the pair. Could involve incrementing/decrementing charge, changing state string, etc., based on randomness value. Emits `PropertyChanged` for affected tokens.
25. `adminSetCustomProperty(uint256 tokenId, string memory key, string memory value) public onlyRole(DEFAULT_ADMIN_ROLE)`: Allows the admin role to set arbitrary custom string properties for a token.
26. `getQuantumCharge(uint256 tokenId) public view returns (uint256)`: Returns the current quantum charge of a token.
27. `getQuantumState(uint256 tokenId) public view returns (string memory)`: Returns the current quantum state of a token.
28. `getCustomProperty(uint256 tokenId, string memory key) public view returns (string memory)`: Returns the value of a specific custom property for a token.
29. `grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE)`: Grants a role to an address.
30. `revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE)`: Revokes a role from an address.
31. `renounceRole(bytes32 role) public virtual override`: Allows an address to renounce its own role.
32. `hasRole(bytes32 role, address account) public view override returns (bool)`: Checks if an address has a specific role.
33. `setDetangleTimeLock(uint256 durationInSeconds) public onlyRole(CONFIG_ROLE)`: Allows the CONFIG_ROLE to set the duration of the detanglement time lock.
34. `getDetangleTimeLock() public view returns (uint256)`: Returns the current detanglement time lock duration.
35. `getDetangleAvailabilityTime(uint256 tokenId) public view returns (uint256)`: Returns the timestamp when a token (if initiating detanglement) becomes available to finalize detangling.
36. `withdrawLink() public onlyRole(DEFAULT_ADMIN_ROLE)`: Allows the admin to withdraw remaining LINK from the contract's VRF subscription balance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title QuantumEntanglementNFT
 * @dev A dynamic NFT contract where tokens can be conceptually "entangled".
 * Actions on one entangled token (measurement) affect its partner,
 * driven by verifiable randomness (Chainlink VRF).
 * Tokens cannot be transferred while entangled. Detangling requires a time lock.
 * Features Access Control for minting, configuration, and admin tasks.
 * Uses a request/accept flow for entanglement.
 */
contract QuantumEntanglementNFT is ERC721URIStorage, AccessControl, VRFConsumerBaseV2, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Roles ---
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant CONFIG_ROLE = keccak256("CONFIG_ROLE");

    // --- ERC721 State ---
    Counters.Counter private _tokenIdCounter;

    // --- Entanglement State ---
    mapping(uint256 => bool) private _isEntangled;
    mapping(uint256 => uint256) private _entangledPair; // tokenId1 => tokenId2

    // --- Entanglement Request State ---
    mapping(uint256 => uint256) private _pendingEntanglementRequests; // tokenId being requested => tokenId requesting

    // --- Detanglement State ---
    mapping(uint256 => uint256) private _detangleAvailableTime; // tokenId => timestamp when detangling is possible
    uint256 private _detangleTimeLock; // Configurable time lock duration in seconds

    // --- Dynamic Properties (Examples) ---
    mapping(uint256 => uint256) private _quantumCharge;
    mapping(uint256 => string) private _quantumState; // e.g., "Neutral", "Excited", "Calm"
    mapping(uint256 => mapping(string => string)) private _customProperties; // Admin-set arbitrary properties

    // --- VRF State ---
    VRFCoordinatorV2Interface private immutable s_vrfCoordinator;
    bytes32 private immutable s_keyHash;
    uint64 private immutable s_subscriptionId;
    uint32 private immutable s_callbackGasLimit;
    uint16 private immutable s_requestConfirmations;
    uint32 private immutable s_numWords;

    // Mapping from requestId to tokenId that requested the measurement
    mapping(uint256 => uint256) private s_requests;

    // --- Events ---
    event Entangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event Detangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event MeasurementPerformed(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 requestId);
    event PropertyChanged(uint256 indexed tokenId, string key, string value);
    event EntanglementRequest(uint256 indexed requesterTokenId, uint256 indexed requestedTokenId);
    event EntanglementRequestAccepted(uint256 indexed requesterTokenId, uint256 indexed requestedTokenId);
    event EntanglementRequestCancelled(uint256 indexed requesterTokenId, uint256 indexed requestedTokenId);
    event DetangleInitiated(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 availabilityTime);
    event DetangleTimeLockUpdated(uint256 oldLock, uint256 newLock);
    event VRFConfigUpdated(bytes32 keyHash, uint64 subscriptionId, uint32 callbackGasLimit, uint16 requestConfirmations, uint32 numWords);

    // --- Constructor ---
    constructor(
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint16 requestConfirmations,
        uint32 numWords,
        string memory baseTokenURI
    )
        ERC721("QuantumEntanglementNFT", "QE-NFT")
        ERC721URIStorage()
        AccessControl()
        VRFConsumerBaseV2(vrfCoordinator)
        ReentrancyGuard()
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Deployer is admin
        _grantRole(MINTER_ROLE, msg.sender); // Deployer is also minter by default
        _grantRole(CONFIG_ROLE, msg.sender); // Deployer is also config by default

        s_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
        s_callbackGasLimit = callbackGasLimit;
        s_requestConfirmations = requestConfirmations;
        s_numWords = numWords;

        _detangleTimeLock = 1 days; // Default time lock

        _setBaseURI(baseTokenURI);

        emit VRFConfigUpdated(keyHash, subscriptionId, callbackGasLimit, requestConfirmations, numWords);
        emit DetangleTimeLockUpdated(0, _detangleTimeLock);
    }

    // --- ERC165 Support ---
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // --- ERC721 Overrides ---

    /**
     * @dev Internal function used by transfers. Overridden to prevent entangled token transfers.
     * @param to The address to transfer the token to.
     * @param tokenId The token ID to transfer.
     * @param auth The address authorized to perform the transfer (owner or approved).
     */
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721URIStorage)
        returns (address)
    {
        require(!_isEntangled[tokenId], "QE: Cannot transfer entangled token");
        return super._update(to, tokenId, auth);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Returns a dynamic URI based on the base URI and token ID.
     * An off-chain service should listen to events/read state and serve metadata from this URI.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        _requireOwned(tokenId); // ERC721URIStorage requires this check
        string memory base = _baseURI();
        // Assume an off-chain service at baseURI/tokenId.json provides dynamic metadata
        // based on on-chain state like _quantumCharge, _quantumState, _isEntangled, _customProperties.
        return bytes(base).length > 0
            ? string(abi.concat(base, tokenId.toString(), ".json"))
            : "";
    }

    /**
     * @dev Sets the base URI for all token URIs. Only CONFIG_ROLE.
     */
    function setBaseURI(string memory newBaseURI)
        public
        onlyRole(CONFIG_ROLE)
    {
        _setBaseURI(newBaseURI);
    }

    // --- Basic ERC721 Functions (inherited) ---
    // balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll
    // transferFrom, safeTransferFrom (modified by _update override)

    /**
     * @dev Mints a new token. Only MINTER_ROLE.
     * Initializes default dynamic properties.
     */
    function mint(address to) public onlyRole(MINTER_ROLE) returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(to, newItemId);

        // Initialize dynamic properties
        _quantumCharge[newItemId] = 0;
        _quantumState[newItemId] = "Neutral";
        // No initial custom properties

        emit PropertyChanged(newItemId, "QuantumCharge", _quantumCharge[newItemId].toString());
        emit PropertyChanged(newItemId, "QuantumState", _quantumState[newItemId]);

        return newItemId;
    }

    // --- Entanglement Management ---

    /**
     * @dev Requests entanglement between caller's token and another token.
     * @param requesterTokenId The token ID owned by the caller (initiating).
     * @param requestedTokenId The token ID to request entanglement with.
     */
    function requestEntanglement(uint256 requesterTokenId, uint256 requestedTokenId) public nonReentrant {
        require(_exists(requesterTokenId), "QE: Requester token does not exist");
        require(_exists(requestedTokenId), "QE: Requested token does not exist");
        require(ownerOf(requesterTokenId) == msg.sender, "QE: Caller does not own requester token");
        require(requesterTokenId != requestedTokenId, "QE: Cannot request entanglement with self");
        require(!_isEntangled[requesterTokenId], "QE: Requester token is already entangled");
        require(!_isEntangled[requestedTokenId], "QE: Requested token is already entangled");
        require(_pendingEntanglementRequests[requestedTokenId] == 0, "QE: Requested token already has a pending request");
        require(_pendingEntanglementRequests[requesterTokenId] == 0, "QE: Requester token already has pending request as requested");

        // Store the request: tokenId being requested => tokenId requesting
        _pendingEntanglementRequests[requestedTokenId] = requesterTokenId;

        emit EntanglementRequest(requesterTokenId, requestedTokenId);
    }

    /**
     * @dev Accepts a pending entanglement request for caller's token.
     * @param requesterTokenId The token ID that initiated the request.
     * @param requestedTokenId The token ID owned by the caller (being requested).
     */
    function acceptEntanglementRequest(uint256 requesterTokenId, uint256 requestedTokenId) public nonReentrant {
         require(_exists(requesterTokenId), "QE: Requester token does not exist");
        require(_exists(requestedTokenId), "QE: Requested token does not exist");
        require(ownerOf(requestedTokenId) == msg.sender, "QE: Caller does not own requested token");
        require(!_isEntangled[requesterTokenId], "QE: Requester token is already entangled");
        require(!_isEntangled[requestedTokenId], "QE: Requested token is already entangled");
        require(_pendingEntanglementRequests[requestedTokenId] == requesterTokenId, "QE: No matching pending request found");

        // Clear the pending request
        delete _pendingEntanglementRequests[requestedTokenId];

        // Perform entanglement
        _isEntangled[requesterTokenId] = true;
        _isEntangled[requestedTokenId] = true;
        _entangledPair[requesterTokenId] = requestedTokenId;
        _entangledPair[requestedTokenId] = requesterTokenId;

        // Clear any pending detangle timers from previous entanglements
        delete _detangleAvailableTime[requesterTokenId];
        delete _detangleAvailableTime[requestedTokenId];


        emit EntanglementRequestAccepted(requesterTokenId, requestedTokenId);
        emit Entangled(requesterTokenId, requestedTokenId);
    }

    /**
     * @dev Cancels a pending entanglement request. Can be called by either token owner.
     * @param requesterTokenId The token ID that initiated the request.
     * @param requestedTokenId The token ID being requested.
     */
    function cancelEntanglementRequest(uint256 requesterTokenId, uint256 requestedTokenId) public nonReentrant {
        require(_exists(requesterTokenId), "QE: Requester token does not exist");
        require(_exists(requestedTokenId), "QE: Requested token does not exist");
        require(ownerOf(requesterTokenId) == msg.sender || ownerOf(requestedTokenId) == msg.sender, "QE: Caller is not owner of either token");

        // Check if a request exists in either direction (though accept flow implies only one direction matters)
        bool requestExists = _pendingEntanglementRequests[requestedTokenId] == requesterTokenId;
        require(requestExists, "QE: No pending request found to cancel");

        // Clear the pending request
        delete _pendingEntanglementRequests[requestedTokenId];

        emit EntanglementRequestCancelled(requesterTokenId, requestedTokenId);
    }

    /**
     * @dev Checks if a token is currently entangled.
     */
    function isTokenEntangled(uint256 tokenId) public view returns (bool) {
        return _isEntangled[tokenId];
    }

    /**
     * @dev Gets the token ID of the entangled partner. Returns 0 if not entangled.
     */
    function getEntangledToken(uint256 tokenId) public view returns (uint256) {
        return _entangledPair[tokenId];
    }

    /**
     * @dev Initiates the detanglement process for a pair.
     * Requires caller owns the token and it's entangled.
     * Starts the detangle time lock.
     */
    function detanglePair(uint256 tokenId) public nonReentrant {
        require(_exists(tokenId), "QE: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "QE: Caller does not own token");
        require(_isEntangled[tokenId], "QE: Token is not entangled");
        require(_detangleAvailableTime[tokenId] == 0, "QE: Detanglement already initiated"); // Cannot initiate if timer already set

        uint256 partnerTokenId = _entangledPair[tokenId];
        uint256 availabilityTime = block.timestamp + _detangleTimeLock;

        _detangleAvailableTime[tokenId] = availabilityTime;
        _detangleAvailableTime[partnerTokenId] = availabilityTime;

        emit DetangleInitiated(tokenId, partnerTokenId, availabilityTime);
    }

    /**
     * @dev Finalizes the detanglement process after the time lock.
     * Requires caller owns the token, it's entangled, and the time lock has passed.
     */
    function finalizeDetangle(uint256 tokenId) public nonReentrant {
        require(_exists(tokenId), "QE: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "QE: Caller does not own token");
        require(_isEntangled[tokenId], "QE: Token is not entangled");
        require(_detangleAvailableTime[tokenId] > 0, "QE: Detanglement not initiated");
        require(block.timestamp >= _detangleAvailableTime[tokenId], "QE: Detangle time lock has not expired");

        uint256 partnerTokenId = _entangledPair[tokenId];

        // Clear entanglement state
        _isEntangled[tokenId] = false;
        _isEntangled[partnerTokenId] = false;
        delete _entangledPair[tokenId];
        delete _entangledPair[partnerTokenId];
        delete _detangleAvailableTime[tokenId];
        delete _detangleAvailableTime[partnerTokenId];

        emit Detangled(tokenId, partnerTokenId);
    }

    // --- Dynamic State & Measurement (VRF) ---

    /**
     * @dev Triggers a state "measurement" for an entangled pair.
     * Requests verifiable randomness from Chainlink VRF.
     * Requires caller owns the token and it must be entangled.
     */
    function measureState(uint256 tokenId) public nonReentrant {
        require(_exists(tokenId), "QE: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "QE: Caller does not own token");
        require(_isEntangled[tokenId], "QE: Token is not entangled for measurement");
        require(_detangleAvailableTime[tokenId] == 0, "QE: Cannot measure during detanglement initiation");

        // Request randomness
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            s_numWords
        );

        // Store the mapping from request ID to the token that initiated it
        s_requests[requestId] = tokenId;

        // Event indicating measurement request (result comes later in fulfillRandomWords)
        emit MeasurementPerformed(tokenId, _entangledPair[tokenId], requestId);
    }

    /**
     * @dev Callback function used by VRF Coordinator.
     * Called when the random word is available.
     * Applies the "measurement effect" to the entangled pair.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 tokenId1 = s_requests[requestId];
        require(_exists(tokenId1), "QE: Invalid VRF request for non-existent token");
        uint256 tokenId2 = _entangledPair[tokenId1];
        // Check entanglement state again in case it changed between request and fulfillment
        require(_isEntangled[tokenId1] && _entangledPair[tokenId1] == tokenId2, "QE: Tokens detangled before measurement fulfillment");

        // Use the first random word to determine the effect
        uint256 randomness = randomWords[0];

        // Apply the effect to both tokens in the entangled pair
        _applyMeasurementEffect(tokenId1, tokenId2, randomness);

        // Clean up the request mapping
        delete s_requests[requestId];
    }

    /**
     * @dev Internal function to apply changes to properties based on randomness.
     * Example implementation: Randomly adjust QuantumCharge and change QuantumState.
     * This is where the core "dynamic" logic lives.
     */
    function _applyMeasurementEffect(uint256 tokenId1, uint256 tokenId2, uint256 randomness) internal {
        // Example effect: Randomly increase or decrease charge, change state

        // Simple charge adjustment based on odd/even randomness
        uint256 chargeChange = (randomness % 10) + 1; // Change between 1 and 10
        bool increase = randomness % 2 == 0;

        if (increase) {
            _quantumCharge[tokenId1] += chargeChange;
            _quantumCharge[tokenId2] += chargeChange; // Entangled effect
        } else {
            if (_quantumCharge[tokenId1] >= chargeChange) _quantumCharge[tokenId1] -= chargeChange; else _quantumCharge[tokenId1] = 0;
            if (_quantumCharge[tokenId2] >= chargeChange) _quantumCharge[tokenId2] -= chargeChange; else _quantumCharge[tokenId2] = 0; // Entangled effect
        }

        emit PropertyChanged(tokenId1, "QuantumCharge", _quantumCharge[tokenId1].toString());
        emit PropertyChanged(tokenId2, "QuantumCharge", _quantumCharge[tokenId2].toString());

        // Simple state change based on randomness distribution
        uint256 stateRoll = randomness % 100; // Roll 0-99
        string memory newState1;
        string memory newState2;

        if (stateRoll < 30) { // 30% chance
            newState1 = "Neutral";
            newState2 = "Neutral";
        } else if (stateRoll < 60) { // 30% chance
            newState1 = "Excited";
            newState2 = "Excited"; // Symmetric effect
        } else if (stateRoll < 80) { // 20% chance
            newState1 = "Calm";
            newState2 = "Calm"; // Symmetric effect
        } else { // 20% chance - Asymmetric entanglement effect!
             if (stateRoll % 2 == 0) {
                 newState1 = "Excited";
                 newState2 = "Calm";
             } else {
                 newState1 = "Calm";
                 newState2 = "Excited";
             }
        }

        if (bytes(_quantumState[tokenId1]).length == 0 || !keccak256(bytes(_quantumState[tokenId1])) == keccak256(bytes(newState1))) {
             _quantumState[tokenId1] = newState1;
             emit PropertyChanged(tokenId1, "QuantumState", newState1);
        }
         if (bytes(_quantumState[tokenId2]).length == 0 || !keccak256(bytes(_quantumState[tokenId2])) == keccak256(bytes(newState2))) {
            _quantumState[tokenId2] = newState2;
            emit PropertyChanged(tokenId2, "QuantumState", newState2);
         }
    }


    // --- Property Getters/Setters ---

    /**
     * @dev Allows admin to set arbitrary custom string properties for a token.
     * These are separate from the VRF-modified dynamic properties.
     */
    function adminSetCustomProperty(uint256 tokenId, string memory key, string memory value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_exists(tokenId), "QE: Token does not exist");
        _customProperties[tokenId][key] = value;
        emit PropertyChanged(tokenId, key, value);
    }

    /**
     * @dev Gets the current quantum charge of a token.
     */
    function getQuantumCharge(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "QE: Token does not exist");
        return _quantumCharge[tokenId];
    }

     /**
     * @dev Gets the current quantum state of a token.
     */
    function getQuantumState(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "QE: Token does not exist");
        return _quantumState[tokenId];
    }

    /**
     * @dev Gets the value of a specific custom property for a token.
     */
    function getCustomProperty(uint256 tokenId, string memory key) public view returns (string memory) {
         require(_exists(tokenId), "QE: Token does not exist");
         return _customProperties[tokenId][key];
    }

    // NOTE: getCustomPropertyKeys is omitted as it's very gas expensive due to Solidity mapping limitations.
    // An off-chain indexer is better suited for querying all custom keys.

    // --- Configuration ---

    /**
     * @dev Sets the detanglement time lock duration. Only CONFIG_ROLE.
     */
    function setDetangleTimeLock(uint256 durationInSeconds) public onlyRole(CONFIG_ROLE) {
        uint256 oldLock = _detangleTimeLock;
        _detangleTimeLock = durationInSeconds;
        emit DetangleTimeLockUpdated(oldLock, _detangleTimeLock);
    }

    /**
     * @dev Gets the current detanglement time lock duration.
     */
    function getDetangleTimeLock() public view returns (uint256) {
        return _detangleTimeLock;
    }

    /**
     * @dev Gets the timestamp when a token (if initiating detanglement) becomes available to finalize detangling.
     * Returns 0 if detanglement is not initiated.
     */
    function getDetangleAvailabilityTime(uint256 tokenId) public view returns (uint256) {
        return _detangleAvailableTime[tokenId];
    }

    /**
     * @dev Allows CONFIG_ROLE to update VRF settings (e.g., if subscription changes).
     * @param keyHash The new key hash.
     * @param subscriptionId The new subscription ID.
     * @param callbackGasLimit The new callback gas limit.
     * @param requestConfirmations The new request confirmations.
     * @param numWords The new number of random words requested.
     */
    function setVRFConfig(
        bytes32 keyHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint16 requestConfirmations,
        uint32 numWords
    ) public onlyRole(CONFIG_ROLE) {
        // Note: s_vrfCoordinator is immutable, requires contract redeploy if coordinator address changes.
        // For mutable coordinator, s_vrfCoordinator state var would not be immutable.
        // Also, changing subscription requires funding the new one off-chain.
        // This function assumes coordinator address is stable.

        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
        s_callbackGasLimit = callbackGasLimit;
        s_requestConfirmations = requestConfirmations;
        s_numWords = numWords;

         emit VRFConfigUpdated(keyHash, subscriptionId, callbackGasLimit, requestConfirmations, numWords);
    }

    /**
     * @dev Allows the admin to withdraw LINK tokens from the VRF subscription.
     * Requires the contract address to be an approved consumer of the subscription.
     */
    function withdrawLink() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(s_vrfCoordinator).balance > 0, "QE: No LINK balance to withdraw");
        // Chainlink VRF v2 coordinator has a withdraw function
        s_vrfCoordinator.withdraw(address(this).balance); // Withdraws all LINK
    }

    // --- Access Control Functions (inherited) ---
    // grantRole, revokeRole, renounceRole, hasRole

    // --- Internal Helpers (ERC721URIStorage specific) ---
    // _setBaseURI is internal to ERC721URIStorage
}
```