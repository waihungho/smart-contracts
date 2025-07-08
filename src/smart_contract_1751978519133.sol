Okay, let's design a smart contract that incorporates several advanced, creative, and trendy concepts without being a direct copy of standard open-source contracts. We'll create a *Quantum Ephemeral NFT (QE-NFT)*, which combines ideas of time-limited ownership, dynamic metadata based on interaction ("observation"), and a unique "entanglement" feature linking two tokens.

Here's the outline and function summary, followed by the Solidity code.

---

## Quantum Ephemeral NFT (QE-NFT) Smart Contract

**Concept:** A non-fungible token that is time-limited (ephemeral), whose visual/metadata state can change based on observation and internal logic (quantum metaphor), and which can be 'entangled' with another QE-NFT, affecting both.

**Inherits:** ERC721Enumerable (for token tracking), Ownable (for administrative functions), Pausable (for safety).

**Key Features:**
*   **Ephemerality:** Each NFT has an expiry timestamp. Transfers and certain interactions are restricted after expiry. NFTs can be recharged.
*   **Dynamic State (Quantum Metaphor):** Each NFT can have multiple potential metadata states. Which state is revealed via `tokenURI` depends on the current internal state index, the last time it was 'observed', and potentially its entanglement status.
*   **Observation Effect:** A `recordObservation` function updates a timestamp. The `tokenURI` function uses this timestamp (and a cooldown) to potentially lock the state to the one seen during observation, simulating an 'observer effect'.
*   **Entanglement:** Two QE-NFTs can be linked. Actions on one (like recharging) can have effects on the entangled pair, subject to cooldowns.
*   **State Variants:** Admins or potentially owners can add different metadata URIs representing possible "quantum states" for an NFT.
*   **Controlled Minting:** Only authorized minters can create new NFTs.

**Outline & Function Summary:**

**I. Core ERC721 Functions (Overridden/Extended)**
1.  `constructor`: Initializes the contract, sets name/symbol, sets initial admin config.
2.  `mint`: Creates a new QE-NFT with initial state, expiry, and assigns to an address. Requires minter authorization.
3.  `transferFrom`: Overridden to prevent transfers after expiry.
4.  `safeTransferFrom` (ERC721): Overridden to prevent transfers after expiry.
5.  `approve`: Overridden to prevent approval setting after expiry.
6.  `setApprovalForAll`: Overridden to prevent setting operator after expiry.
7.  `tokenURI`: Overridden. Dynamically determines the metadata URI based on the NFT's state index, last observation time, entanglement status, and expiry. This is the core "quantum" logic.

**II. Ephemeral Logic**
8.  `getExpiryTimestamp(uint256 tokenId)`: Returns the expiry timestamp for a token.
9.  `isExpired(uint256 tokenId)`: Checks if a token has expired.
10. `rechargeNFT(uint256 tokenId, uint64 durationInSeconds)`: Extends the expiry time of an NFT. Can be called by owner or approved address before/shortly after expiry.
11. `burnExpiredNFT(uint256 tokenId)`: Allows the owner to burn an NFT that has expired (and is no longer in a grace period for recharging).

**III. Dynamic State (Quantum Metaphor) Logic**
12. `addStateVariant(uint256 tokenId, string memory stateURI)`: Adds a new potential metadata URI variant for a specific token. Owner/Admin only.
13. `removeStateVariant(uint256 tokenId, uint256 stateIndex)`: Removes a state variant by index for a token. Owner/Admin only.
14. `getStateVariantURI(uint256 tokenId, uint256 stateIndex)`: Returns a specific state variant URI by index.
15. `getCurrentStateIndex(uint256 tokenId)`: Returns the currently active state index for an NFT.
16. `forceStateTransition(uint256 tokenId, uint256 newStateIndex)`: Allows the owner/admin to manually set the current state index.

**IV. Observation Effect Logic**
17. `recordObservation(uint256 tokenId)`: Updates the last observed timestamp for the token. Anyone can call this (subject to cooldown), simulating interaction.
18. `getLastObservationTime(uint256 tokenId)`: Returns the timestamp of the last observation.
19. `setObservationCooldown(uint64 cooldownInSeconds)`: Admin function to set the minimum time between recording observations for an NFT.

**V. Entanglement Logic**
20. `entangleNFTs(uint256 tokenId1, uint256 tokenId2)`: Links two un-entangled NFTs together. Owner of both must initiate.
21. `unentangleNFTs(uint256 tokenId)`: Removes the entanglement link for a specific NFT (automatically unlinks the other). Owner only.
22. `getEntangledWith(uint256 tokenId)`: Returns the token ID that the specified token is entangled with (0 if not entangled).
23. `rechargeEntangled(uint256 tokenId, uint64 durationInSeconds)`: Recharges *both* NFTs in an entangled pair. Callable by owner of either entangled token. Subject to entanglement cooldown.
24. `setEntanglementCooldown(uint64 cooldownInSeconds)`: Admin function to set the minimum time between entanglement effects being applied (e.g., recharging the pair).

**VI. Administrative Functions**
25. `setDefaultExpiryDuration(uint64 durationInSeconds)`: Sets the default lifespan for newly minted NFTs. Admin only.
26. `setRechargeGracePeriod(uint64 durationInSeconds)`: Sets how long after expiry an NFT can still be recharged. Admin only.
27. `addAuthorizedMinter(address minter)`: Grants an address permission to mint NFTs. Admin only.
28. `removeAuthorizedMinter(address minter)`: Revokes minting permission. Admin only.
29. `pause()`: Pauses certain contract functions (minting, transfers, state transitions, entanglement, recharging). Admin only.
30. `unpause()`: Unpauses the contract. Admin only.
31. `setBaseURI(string memory baseURI)`: Sets a base URI for metadata, used as a fallback or prefix in `tokenURI`. Admin only.

**VII. Query Functions**
32. `isAuthorizedMinter(address minter)`: Checks if an address is authorized to mint.
33. `getStateVariantsCount(uint256 tokenId)`: Returns the number of state variants for a token.
34. `getNFTData(uint256 tokenId)`: Returns the comprehensive data struct for an NFT (expiry, state index, last observation, entangled token).
35. `getTotalMinted()`: Returns the total number of NFTs ever minted.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/// @title Quantum Ephemeral NFT (QE-NFT)
/// @dev A dynamic, time-limited NFT with observation-dependent state and entanglement features.
contract QuantumEphemeralNFT is ERC721Enumerable, Ownable, Pausable {
    using Strings for uint256;

    // --- State Variables ---

    struct EphemeralNFTData {
        uint64 expiryTimestamp;
        uint256 currentStateIndex; // Index in the stateVariants array
        uint64 lastObservationTime;
        uint64 lastEntanglementEffectTime; // Cooldown for entanglement effects
        uint256 entangledWith; // Token ID this token is entangled with (0 if none)
    }

    // Maps tokenId to its specific dynamic data
    mapping(uint256 => EphemeralNFTData) private _tokenData;

    // Maps tokenId to an array of its potential state variant URIs
    mapping(uint256 => string[]) private _stateVariants;

    // Admin configurable parameters
    uint64 private _defaultExpiryDuration;
    uint64 private _rechargeGracePeriod; // Time after expiry during which recharge is allowed
    uint64 private _observationCooldown; // Time required between observations to potentially affect tokenURI
    uint64 private _entanglementCooldown; // Time required between applying entanglement effects

    // Authorized minters
    mapping(address => bool) private _authorizedMinters;

    // Base URI for metadata (can be combined with dynamic parts in tokenURI)
    string private _baseURI;

    // Counter for total minted tokens (used for token IDs)
    uint256 private _nextTokenId;

    // --- Events ---

    event NFTMinted(uint256 indexed tokenId, address indexed owner, uint64 expiryTimestamp);
    event NFTRecharged(uint256 indexed tokenId, uint64 newExpiryTimestamp, address indexed caller);
    event NFTBurnedExpired(uint256 indexed tokenId, address indexed owner);
    event StateVariantAdded(uint256 indexed tokenId, uint256 indexed index, string stateURI);
    event StateVariantRemoved(uint256 indexed tokenId, uint256 indexed index);
    event StateTransitioned(uint256 indexed tokenId, uint256 indexed oldStateIndex, uint256 indexed newStateIndex, address indexed caller);
    event ObservationRecorded(uint256 indexed tokenId, uint64 timestamp);
    event NFTsEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed caller);
    event NFTUnentangled(uint256 indexed tokenId, address indexed caller);
    event EntanglementEffectApplied(uint256 indexed tokenId1, uint256 indexed tokenId2, uint64 lastEffectTime);

    // --- Modifiers ---

    modifier onlyAuthorizedMinter() {
        require(_authorizedMinters[msg.sender], "QE-NFT: Caller is not an authorized minter");
        _;
    }

    modifier whenNotExpired(uint256 tokenId) {
        require(block.timestamp < _tokenData[tokenId].expiryTimestamp, "QE-NFT: Token has expired");
        _;
    }

    modifier whenExpired(uint256 tokenId) {
        require(block.timestamp >= _tokenData[tokenId].expiryTimestamp, "QE-NFT: Token has not expired");
        _;
    }

    modifier canRecharge(uint256 tokenId) {
        require(
            block.timestamp < _tokenData[tokenId].expiryTimestamp || // Not expired
            block.timestamp < _tokenData[tokenId].expiryTimestamp + _rechargeGracePeriod, // Within grace period
            "QE-NFT: Token cannot be recharged at this time"
        );
        _;
    }

    modifier onlyTokenOwnerOrApproved(uint256 tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "QE-NFT: Caller is not owner nor approved"
        );
        _;
    }

    // --- Constructor ---

    constructor(
        string memory name,
        string memory symbol,
        uint64 defaultExpiryDurationInSeconds,
        uint64 rechargeGracePeriodInSeconds,
        uint64 observationCooldownInSeconds,
        uint64 entanglementCooldownInSeconds
    ) ERC721(name, symbol) Ownable(msg.sender) Pausable() {
        _defaultExpiryDuration = defaultExpiryDurationInSeconds;
        _rechargeGracePeriod = rechargeGracePeriodInSeconds;
        _observationCooldown = observationCooldownInSeconds;
        _entanglementCooldown = entanglementCooldownInSeconds;
        // Add deployer as the initial authorized minter
        _authorizedMinters[msg.sender] = true;
    }

    // --- Core ERC721 Functions (Overridden/Extended) ---

    /// @notice Mints a new Quantum Ephemeral NFT.
    /// @dev Only authorized minters can call this. Sets initial state and expiry.
    /// @param to The address to mint the token to.
    /// @param initialStateURI The initial metadata URI for state variant 0.
    function mint(address to, string memory initialStateURI)
        public
        onlyAuthorizedMinter
        whenNotPaused
        returns (uint256)
    {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);

        _tokenData[tokenId].expiryTimestamp = uint64(block.timestamp + _defaultExpiryDuration);
        _tokenData[tokenId].currentStateIndex = 0;
        _tokenData[tokenId].lastObservationTime = 0;
        _tokenData[tokenId].lastEntanglementEffectTime = 0;
        _tokenData[tokenId].entangledWith = 0;

        _stateVariants[tokenId].push(initialStateURI); // Add state variant 0

        emit NFTMinted(tokenId, to, _tokenData[tokenId].expiryTimestamp);

        return tokenId;
    }

    /// @inheritdoc ERC721
    /// @dev Prevents transfers if the token has expired (and is past the grace period).
    function transferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
         require(
            block.timestamp < _tokenData[tokenId].expiryTimestamp + _rechargeGracePeriod,
            "QE-NFT: Cannot transfer expired token after grace period"
        );
        super.transferFrom(from, to, tokenId);
    }

    /// @inheritdoc ERC721
    /// @dev Prevents transfers if the token has expired (and is past the grace period).
    function safeTransferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
         require(
            block.timestamp < _tokenData[tokenId].expiryTimestamp + _rechargeGracePeriod,
            "QE-NFT: Cannot transfer expired token after grace period"
        );
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @inheritdoc ERC721
    /// @dev Prevents transfers if the token has expired (and is past the grace period).
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override whenNotPaused {
         require(
            block.timestamp < _tokenData[tokenId].expiryTimestamp + _rechargeGracePeriod,
            "QE-NFT: Cannot transfer expired token after grace period"
        );
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// @inheritdoc ERC721
    /// @dev Prevents approval setting if the token has expired (and is past the grace period).
    function approve(address to, uint256 tokenId) public override whenNotPaused {
         require(
            block.timestamp < _tokenData[tokenId].expiryTimestamp + _rechargeGracePeriod,
            "QE-NFT: Cannot approve expired token after grace period"
        );
        super.approve(to, tokenId);
    }

     /// @inheritdoc ERC721
    /// @dev Prevents operator setting if the token has expired (and is past the grace period).
    function setApprovalForAll(address operator, bool approved) public override whenNotPaused {
        // Setting approval for all isn't directly tied to a single token's expiry,
        // but we apply the pause check for consistency with other interaction functions.
        super.setApprovalForAll(operator, approved);
    }


    /// @inheritdoc ERC721Enumerable
    /// @dev Overrides tokenURI to implement the dynamic state logic.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists

        EphemeralNFTData storage data = _tokenData[tokenId];
        string[] storage variants = _stateVariants[tokenId];

        if (variants.length == 0) {
            // Fallback if no state variants are defined
            return string(abi.encodePacked(_baseURI, tokenId.toString()));
        }

        uint256 stateIndex = data.currentStateIndex;

        // --- Dynamic State Logic based on Observation and Entanglement ---

        // 1. Check for Expired State
        if (block.timestamp >= data.expiryTimestamp) {
            // Return a special URI for expired tokens
            // Example: Combine baseURI with "/expired/" and token ID
             if (bytes(_baseURI).length > 0) {
                return string(abi.encodePacked(_baseURI, "/expired/", tokenId.toString()));
            } else {
                 // Or return a default static expired URI or JSON
                 // Example: Return base64 encoded JSON
                 bytes memory json = abi.encodePacked(
                     '{"name": "Expired QE-NFT #', tokenId.toString(), '", ',
                     '"description": "This Quantum Ephemeral NFT has expired.", ',
                     '"image": "data:image/svg+xml;base64,...[expired image data]..."}' // Replace with actual SVG/image data URI
                 );
                 return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
            }
        }

        // 2. Check for Observation Effect
        // If recently observed (within observationCooldown), potentially lock to the state observed then.
        // For simplicity here, let's say observation *temporarily* fixes the state to the current one.
        // A more advanced version could store the state index *at the time of observation*.
        // Current simpler logic: if observed recently, use the *current* state index.
        // The *real* power is how the state index itself might change based on observation *history*.
        // Let's implement a simple dynamic logic: State index cycles based on time + entanglement + observation history.
        // This is where the "quantum" non-determinism is simulated.

        uint256 dynamicStateLogicInput = block.timestamp + tokenId;
        if (data.entangledWith != 0) {
             dynamicStateLogicInput += data.entangledWith; // Entanglement influences state
        }
         if (data.lastObservationTime > 0 && block.timestamp - data.lastObservationTime < _observationCooldown) {
             // Recent observation makes the state index calculation "less random" or fixed
             dynamicStateLogicInput += data.lastObservationTime * 2; // Observation influences state differently
         }

        // Simple deterministic logic based on input:
        uint256 calculatedStateIndex = (dynamicStateLogicInput % variants.length);

        // Now decide which index to use:
        // - If recently observed, use the *calculated* index (simulate collapsing to a state based on recent look)
        // - Otherwise, use the stored `currentStateIndex` (simulating a more "fixed" or less observed state)
        // - OR, the stored `currentStateIndex` could be the *default* and the calculated one is the *observed* one.
        // Let's go with: Calculated index is the 'observed' state, stored is the 'default' state.
        // If recently observed, return the URI for the 'observed' state.
        // Otherwise, return the URI for the 'default' state.

        if (data.lastObservationTime > 0 && block.timestamp - data.lastObservationTime < _observationCooldown) {
            // Return the state calculated based on recent observation/dynamic factors
             stateIndex = calculatedStateIndex;
        } else {
            // Return the state stored in the contract (the 'default' or last force-set state)
            stateIndex = data.currentStateIndex;
        }


        // Ensure the chosen index is valid
        if (stateIndex >= variants.length) {
            // Should not happen if logic is sound, but fallback to state 0 if index is out of bounds
            stateIndex = 0;
        }

        string memory selectedURI = variants[stateIndex];

        // 3. Combine Base URI (if set)
        if (bytes(_baseURI).length > 0) {
            // If _baseURI ends with /, use it directly, otherwise add /
             if (bytes(_baseURI)[bytes(_baseURI).length - 1] == "/") {
                 return string(abi.encodePacked(_baseURI, selectedURI));
             } else {
                 return string(abi.encodePacked(_baseURI, "/", selectedURI));
             }
        } else {
            return selectedURI; // Return just the state variant URI
        }
    }

    // --- Ephemeral Logic ---

    /// @notice Gets the expiry timestamp for a token.
    function getExpiryTimestamp(uint256 tokenId) public view returns (uint64) {
        _requireOwned(tokenId); // Or _exists(tokenId); based on desired visibility for non-owners
        return _tokenData[tokenId].expiryTimestamp;
    }

    /// @notice Checks if a token has expired.
    function isExpired(uint256 tokenId) public view returns (bool) {
         _requireOwned(tokenId); // Or _exists(tokenId)
        return block.timestamp >= _tokenData[tokenId].expiryTimestamp;
    }

    /// @notice Recharges the NFT, extending its expiry timestamp.
    /// @dev Can be called by owner or approved address if the token is not expired or is within the grace period.
    /// @param tokenId The token ID to recharge.
    /// @param durationInSeconds The duration to add to the current timestamp for the new expiry.
    function rechargeNFT(uint256 tokenId, uint64 durationInSeconds)
        public
        onlyTokenOwnerOrApproved(tokenId)
        canRecharge(tokenId)
        whenNotPaused
    {
        // Ensure duration is positive
        require(durationInSeconds > 0, "QE-NFT: Duration must be positive");

        // Calculate new expiry: it's either (current expiry + duration) OR (now + duration),
        // whichever is later. This prevents reducing expiry if called while not expired.
        uint64 currentExpiry = _tokenData[tokenId].expiryTimestamp;
        uint64 newExpiry = uint64(block.timestamp + durationInSeconds);

        if (newExpiry < currentExpiry) {
             newExpiry = currentExpiry + durationInSeconds; // Prevent reducing expiry
        }

        _tokenData[tokenId].expiryTimestamp = newExpiry;

        emit NFTRecharged(tokenId, newExpiry, _msgSender());
    }

    /// @notice Allows the owner to burn an expired NFT (past the grace period).
    /// @param tokenId The token ID to burn.
    function burnExpiredNFT(uint256 tokenId) public whenExpired(tokenId) whenNotPaused {
        require(ownerOf(tokenId) == _msgSender(), "QE-NFT: Caller must be owner to burn");
        require(block.timestamp >= _tokenData[tokenId].expiryTimestamp + _rechargeGracePeriod, "QE-NFT: Token is still in recharge grace period");

        _burn(tokenId);
        // Clean up associated data (optional, but good practice)
        delete _tokenData[tokenId];
        delete _stateVariants[tokenId];

        emit NFTBurnedExpired(tokenId, _msgSender());
    }

    // --- Dynamic State (Quantum Metaphor) Logic ---

    /// @notice Adds a new state variant URI for a specific token.
    /// @dev Only callable by the token owner or contract owner.
    /// @param tokenId The token ID.
    /// @param stateURI The metadata URI for the new state.
    function addStateVariant(uint256 tokenId, string memory stateURI)
        public
        onlyTokenOwnerOrApproved(tokenId) // Can be changed to onlyOwner if only admin should add states
        whenNotPaused
    {
         _stateVariants[tokenId].push(stateURI);
         emit StateVariantAdded(tokenId, _stateVariants[tokenId].length - 1, stateURI);
    }

    /// @notice Removes a state variant by index for a token.
    /// @dev Only callable by the token owner or contract owner. State index 0 cannot be removed.
    /// @param tokenId The token ID.
    /// @param stateIndex The index of the state variant to remove.
    function removeStateVariant(uint256 tokenId, uint256 stateIndex)
        public
        onlyTokenOwnerOrApproved(tokenId) // Can be changed to onlyOwner
        whenNotPaused
    {
        require(stateIndex > 0, "QE-NFT: Cannot remove state variant 0");
        string[] storage variants = _stateVariants[tokenId];
        require(stateIndex < variants.length, "QE-NFT: State index out of bounds");

        // Simple remove-by-swap-and-pop (order is not guaranteed for state variants)
        variants[stateIndex] = variants[variants.length - 1];
        variants.pop();

        // If the current state index was the removed one, reset it to 0 or another valid state
        if (_tokenData[tokenId].currentStateIndex == stateIndex) {
            _tokenData[tokenId].currentStateIndex = 0;
        } else if (_tokenData[tokenId].currentStateIndex == variants.length) {
             // If current state was the last one swapped, update index
             _tokenData[tokenId].currentStateIndex = stateIndex;
        }


        emit StateVariantRemoved(tokenId, stateIndex);
    }

    /// @notice Gets a specific state variant URI by index for a token.
    function getStateVariantURI(uint256 tokenId, uint256 stateIndex) public view returns (string memory) {
         _requireOwned(tokenId);
         string[] storage variants = _stateVariants[tokenId];
         require(stateIndex < variants.length, "QE-NFT: State index out of bounds");
         return variants[stateIndex];
    }

     /// @notice Gets the currently stored state index for a token.
     /// @dev This is the index used by default in tokenURI when not overridden by observation.
    function getCurrentStateIndex(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId);
        return _tokenData[tokenId].currentStateIndex;
    }

    /// @notice Forces a token to transition to a specific stored state index.
    /// @dev Only callable by the token owner or contract owner. Does not affect dynamic tokenURI logic based on observation.
    /// @param tokenId The token ID.
    /// @param newStateIndex The index of the state variant to transition to.
    function forceStateTransition(uint256 tokenId, uint256 newStateIndex)
        public
        onlyTokenOwnerOrApproved(tokenId) // Can be changed to onlyOwner
        whenNotPaused
    {
         string[] storage variants = _stateVariants[tokenId];
         require(newStateIndex < variants.length, "QE-NFT: New state index out of bounds");
         uint256 oldStateIndex = _tokenData[tokenId].currentStateIndex;
        _tokenData[tokenId].currentStateIndex = newStateIndex;
         emit StateTransitioned(tokenId, oldStateIndex, newStateIndex, _msgSender());
    }


    // --- Observation Effect Logic ---

    /// @notice Records an observation event for the NFT.
    /// @dev Updates the last observed timestamp, which can influence the tokenURI output temporarily.
    /// Subject to observation cooldown.
    /// @param tokenId The token ID.
    function recordObservation(uint256 tokenId) public whenNotExpired(tokenId) whenNotPaused {
         // Allow anyone to record observation, but enforce cooldown per token
         EphemeralNFTData storage data = _tokenData[tokenId];
         require(block.timestamp >= data.lastObservationTime + _observationCooldown, "QE-NFT: Observation cooldown active");

        data.lastObservationTime = uint64(block.timestamp);
        emit ObservationRecorded(tokenId, data.lastObservationTime);
    }

    /// @notice Gets the timestamp of the last recorded observation for a token.
    function getLastObservationTime(uint256 tokenId) public view returns (uint64) {
        _requireOwned(tokenId);
        return _tokenData[tokenId].lastObservationTime;
    }

    // --- Entanglement Logic ---

    /// @notice Entangles two NFTs together.
    /// @dev Requires caller to own both tokens. Tokens must not already be entangled.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function entangleNFTs(uint256 tokenId1, uint256 tokenId2) public whenNotPaused {
        require(tokenId1 != tokenId2, "QE-NFT: Cannot entangle a token with itself");
        require(ownerOf(tokenId1) == _msgSender(), "QE-NFT: Caller must own token1");
        require(ownerOf(tokenId2) == _msgSender(), "QE-NFT: Caller must own token2");
        require(_tokenData[tokenId1].entangledWith == 0, "QE-NFT: Token1 is already entangled");
        require(_tokenData[tokenId2].entangledWith == 0, "QE-NFT: Token2 is already entangled");

        _tokenData[tokenId1].entangledWith = tokenId2;
        _tokenData[tokenId2].entangledWith = tokenId1;

        emit NFTsEntangled(tokenId1, tokenId2, _msgSender());
    }

    /// @notice Unentangles an NFT from its paired token.
    /// @dev Requires caller to be the owner of the token.
    /// @param tokenId The token ID to unentangle.
    function unentangleNFTs(uint256 tokenId) public whenNotPaused {
        require(ownerOf(tokenId) == _msgSender(), "QE-NFT: Caller must be owner to unentangle");
        uint256 entangledWithId = _tokenData[tokenId].entangledWith;
        require(entangledWithId != 0, "QE-NFT: Token is not entangled");

        // Clear entanglement for both tokens
        _tokenData[tokenId].entangledWith = 0;
        _tokenData[entangledWithId].entangledWith = 0;

        emit NFTUnentangled(tokenId, _msgSender());
    }

    /// @notice Gets the token ID that a specified token is entangled with.
    /// @return The entangled token ID, or 0 if not entangled.
    function getEntangledWith(uint256 tokenId) public view returns (uint256) {
         _requireOwned(tokenId); // Or _exists(tokenId)
        return _tokenData[tokenId].entangledWith;
    }

    /// @notice Applies an entanglement effect: recharges both NFTs in the pair.
    /// @dev Callable by the owner of either entangled token. Subject to entanglement cooldown.
    /// @param tokenId The ID of one of the tokens in the entangled pair.
    /// @param durationInSeconds The duration to add to the expiry of both NFTs.
    function rechargeEntangled(uint256 tokenId, uint64 durationInSeconds) public whenNotPaused {
         uint256 entangledWithId = _tokenData[tokenId].entangledWith;
         require(entangledWithId != 0, "QE-NFT: Token is not entangled");
         require(ownerOf(tokenId) == _msgSender() || ownerOf(entangledWithId) == _msgSender(), "QE-NFT: Caller must own one of the entangled tokens");

         // Check entanglement effect cooldown on *both* tokens
         require(block.timestamp >= _tokenData[tokenId].lastEntanglementEffectTime + _entanglementCooldown, "QE-NFT: Entanglement effect cooldown active on token1");
         require(block.timestamp >= _tokenData[entangledWithId].lastEntanglementEffectTime + _entanglementCooldown, "QE-NFT: Entanglement effect cooldown active on token2");

         // Ensure both tokens are in a state where they *can* be recharged
         require(
             block.timestamp < _tokenData[tokenId].expiryTimestamp + _rechargeGracePeriod,
             "QE-NFT: Token1 is past its recharge grace period"
         );
          require(
             block.timestamp < _tokenData[entangledWithId].expiryTimestamp + _rechargeGracePeriod,
             "QE-NFT: Token2 is past its recharge grace period"
         );

         // Recharge both tokens
         uint64 newExpiry1 = uint64(block.timestamp + durationInSeconds);
         if (newExpiry1 < _tokenData[tokenId].expiryTimestamp) newExpiry1 = _tokenData[tokenId].expiryTimestamp + durationInSeconds;
         _tokenData[tokenId].expiryTimestamp = newExpiry1;

         uint64 newExpiry2 = uint64(block.timestamp + durationInSeconds);
          if (newExpiry2 < _tokenData[entangledWithId].expiryTimestamp) newExpiry2 = _tokenData[entangledWithId].expiryTimestamp + durationInSeconds;
         _tokenData[entangledWithId].expiryTimestamp = newExpiry2;


         // Update cooldown for both tokens
         _tokenData[tokenId].lastEntanglementEffectTime = uint64(block.timestamp);
         _tokenData[entangledWithId].lastEntanglementEffectTime = uint64(block.timestamp);

         emit EntanglementEffectApplied(tokenId, entangledWithId, uint64(block.timestamp));
         // Also emit recharge events for clarity
         emit NFTRecharged(tokenId, newExpiry1, _msgSender());
         emit NFTRecharged(entangledWithId, newExpiry2, _msgSender());
    }


    // --- Administrative Functions ---

    /// @notice Sets the default duration for newly minted NFTs.
    function setDefaultExpiryDuration(uint64 durationInSeconds) public onlyOwner {
        _defaultExpiryDuration = durationInSeconds;
    }

    /// @notice Sets the grace period after expiry during which recharge is allowed.
    function setRechargeGracePeriod(uint64 durationInSeconds) public onlyOwner {
        _rechargeGracePeriod = durationInSeconds;
    }

    /// @notice Sets the minimum time between recording observations for an NFT.
    function setObservationCooldown(uint64 cooldownInSeconds) public onlyOwner {
         _observationCooldown = cooldownInSeconds;
    }

    /// @notice Sets the minimum time between applying entanglement effects to a pair.
    function setEntanglementCooldown(uint64 cooldownInSeconds) public onlyOwner {
        _entanglementCooldown = cooldownInSeconds;
    }

    /// @notice Adds an address to the list of authorized minters.
    function addAuthorizedMinter(address minter) public onlyOwner {
        require(minter != address(0), "QE-NFT: Cannot add zero address as minter");
        _authorizedMinters[minter] = true;
    }

    /// @notice Removes an address from the list of authorized minters.
    function removeAuthorizedMinter(address minter) public onlyOwner {
        require(minter != _msgSender(), "QE-NFT: Cannot remove yourself as minter"); // Prevent accidental lockout
        _authorizedMinters[minter] = false;
    }

    /// @inheritdoc Pausable
    function pause() public onlyOwner {
        _pause();
    }

    /// @inheritdoc Pausable
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Sets the base URI for token metadata.
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseURI = baseURI;
    }

    // --- Query Functions ---

    /// @notice Checks if an address is authorized to mint.
    function isAuthorizedMinter(address minter) public view returns (bool) {
        return _authorizedMinters[minter];
    }

    /// @notice Gets the number of state variants available for a token.
    function getStateVariantsCount(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId); // Or _exists(tokenId)
        return _stateVariants[tokenId].length;
    }

    /// @notice Gets the comprehensive data struct for an NFT.
    /// @dev Returns expiry, state index, last observation time, last entanglement effect time, and entangled token ID.
    function getNFTData(uint256 tokenId)
        public
        view
        returns (
            uint64 expiryTimestamp,
            uint256 currentStateIndex,
            uint64 lastObservationTime,
            uint64 lastEntanglementEffectTime,
            uint256 entangledWith
        )
    {
        _requireOwned(tokenId); // Or _exists(tokenId)
        EphemeralNFTData storage data = _tokenData[tokenId];
        return (
            data.expiryTimestamp,
            data.currentStateIndex,
            data.lastObservationTime,
            data.lastEntanglementEffectTime,
            data.entangledWith
        );
    }

     /// @notice Gets the total number of NFTs ever minted by this contract.
    function getTotalMinted() public view returns (uint256) {
        return _nextTokenId;
    }

    // --- Internal/Helper Functions ---

     // We override _requireOwned to check existence. This is called by standard ERC721 functions like ownerOf.
     function _requireOwned(uint256 tokenId) internal view override {
         require(_exists(tokenId), "ERC721: owner query for nonexistent token");
     }

    // The rest of ERC721Enumerable, Ownable, Pausable functions are available publicly.
    // e.g., owner(), paused(), name(), symbol(), totalSupply(), tokenByIndex(), tokenOfOwnerByIndex()
}
```

---

**Explanation of Creative/Advanced Concepts:**

1.  **Ephemerality & Recharge:** Standard NFTs are permanent. Making them time-limited (`expiryTimestamp`) adds a novel dimension. The `rechargeNFT` function provides a mechanism to extend lifespan, creating potential gameplay loops or dynamic value propositions. The `rechargeGracePeriod` adds flexibility.
2.  **Dynamic Metadata (`tokenURI` Override):** This is where the "Quantum" metaphor comes into play.
    *   Instead of a single static URI, the contract stores multiple `_stateVariants`.
    *   The `tokenURI` function doesn't just return a fixed string; it calculates which string to return based on contract state:
        *   **Expiry:** Returns a special "expired" URI.
        *   **Observation Effect:** If `recordObservation` was called recently (within `_observationCooldown`), the URI is determined by a calculation (`calculatedStateIndex`) involving time, token ID, and entanglement status. This simulates the state being influenced by being "looked at".
        *   **Default/Stored State:** If not recently observed, it returns the URI corresponding to the `currentStateIndex`, which can be force-set by the owner (`forceStateTransition`) or potentially changed by other logic (not explicitly implemented beyond force-setting and dynamic calculation in `tokenURI`, but could be extended).
    *   This means the *same token ID* could return different URIs depending on *when* and potentially *how recently* it was interacted with via `recordObservation`, simulating a state that isn't fixed until observed.
3.  **Entanglement:** The `entangleNFTs` and `unentangleNFTs` functions create a explicit link between two tokens (`entangledWith`). The `rechargeEntangled` function demonstrates one possible effect: recharging one token recharges the other, subject to a shared cooldown (`_entanglementCooldown`). More complex effects could be added, like state transitions triggered by entanglement, or properties of one token influencing the other.
4.  **Controlled Minting & Pausability:** Basic but important advanced patterns for managing token supply and reacting to potential issues.
5.  **Structs and Mappings for Complex State:** Using structs (`EphemeralNFTData`) and nested mappings (`_stateVariants[tokenId]`) allows each token to store significant, individual dynamic data beyond just ownership.

This contract provides a framework where NFTs are not static images on a blockchain, but dynamic entities with lifespans, reactive properties, and interdependencies, pushing beyond typical ERC721 use cases.