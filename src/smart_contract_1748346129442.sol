Okay, here is a Solidity smart contract implementing a "Quantum Entanglement NFT" (QENFT). This contract features several states for NFTs, unique entanglement mechanics, a collapse function to reveal hidden properties based on external "entropy," cascading effects on entangled pairs, custom transfer/burn logic, and administrative controls.

It's designed to be complex and illustrative, not a simple extension of standard ERC-721. It implements the *logic* of ownership and transfers but uses custom function names and state management to avoid direct duplication of common open-source interfaces like OpenZeppelin's base implementations.

**Concept:**

*   **QENFTs:** NFTs with unique properties and states.
*   **States:**
    *   `Uncollapsed`: Initial state. Properties are visible. Can be entangled or initiated for collapse.
    *   `Entangled`: Paired with another QENFT. Specific transfer/burn rules apply. Can trigger effects on the partner. Can be disentangled (before collapse) or initiated for collapse.
    *   `Collapsing`: Intermediate state after `initiateCollapse`, waiting for external entropy. Frozen.
    *   `Collapsed`: Final state. Hidden properties are revealed/determined using entropy. State is fixed. Cannot be entangled/disentangled. Some actions may be restricted.
    *   `Frozen`: An independent state overlay that prevents transfers and most state-changing operations. Can be applied/removed independently of Uncollapsed/Entangled/Collapsed states.
*   **Entanglement:** Two `Uncollapsed` tokens can be paired. They become `Entangled`.
*   **Collapse:** A process to finalize a token's state and reveal its hidden properties. Requires external entropy input.
*   **Hidden Properties:** Determined semi-randomly based on external entropy provided during collapse, only visible after the token is `Collapsed`.
*   **Entangled Effects:** Calling a specific function on an `Entangled` token can trigger a one-time effect flag on its partner *before* the partner is collapsed.
*   **Custom Transfer/Burn:** Entangled pairs must be transferred together. Burning an Entangled token burns its partner.
*   **Entropy Oracle:** A trusted external address or contract that provides the required entropy data for collapse.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntanglementNFT
 * @dev An advanced, creative NFT contract with unique states, entanglement mechanics,
 *      collapsing properties, and custom transfer/burn logic.
 *      This contract does NOT inherit from standard interfaces like ERC721 directly
 *      to demonstrate custom implementation logic and avoid duplicating common open source patterns.
 */

/**
 * @dev Outline:
 * 1. State Variables & Constants
 * 2. Enums for NFT State
 * 3. Struct for Token Data
 * 4. Mappings for Token State, Ownership, Balances
 * 5. Events
 * 6. Modifiers
 * 7. Constructor
 * 8. Core NFT Logic (Mint, Transfer, Burn - Custom Implementations)
 * 9. State Management (Entangle, Disentangle, Collapse Process)
 * 10. Property Management (Visible, Hidden, Updates, Getters)
 * 11. Entanglement Effects
 * 12. Freezing Mechanism
 * 13. Access Control (Owner, Admin, Entropy Oracle)
 * 14. Utility & Query Functions
 */

/**
 * @dev Function Summary:
 * - mintQENFT(): Mints a new QENFT in the Uncollapsed state.
 * - entangleTokens(tokenId1, tokenId2): Pairs two Uncollapsed tokens into the Entangled state.
 * - disentangleTokens(tokenId1, tokenId2): Breaks the entanglement of two Entangled tokens (only if not Collapsed).
 * - initiateCollapse(tokenId): Marks an Uncollapsed or Entangled token for collapse, transitioning to Collapsing state. Requires later entropy.
 * - provideEntropy(tokenId, entropyData): Restricted function (EntropyOracle) to provide randomness for a token in Collapsing state.
 * - finalizeCollapse(tokenId): Uses received entropy to determine hidden properties and transitions from Collapsing to Collapsed state.
 * - getQENFTState(tokenId): Returns the current state of a token.
 * - getEntanglementPair(tokenId): Returns the partner ID if the token is Entangled.
 * - getVisibleProperties(tokenId, index): Returns a specific visible property value.
 * - getHiddenProperties(tokenId, index): Returns a specific hidden property value (only accessible if Collapsed).
 * - transferSingleQENFT(to, tokenId): Custom transfer for a single token (fails if Entangled or Frozen).
 * - transferEntangledPair(to, tokenId1, tokenId2): Custom transfer specifically for an Entangled pair, sending both to the same address.
 * - burnQENFT(tokenId): Burns a token. If Entangled, automatically burns its partner.
 * - triggerEntangledEffect(tokenId): If Entangled, sets the 'effectApplied' flag on the partner (if partner not Collapsed).
 * - checkPartnerEffectStatus(tokenId): Checks the 'effectApplied' flag on this token.
 * - freezeQENFT(tokenId): Marks a token as Frozen, preventing transfers and state changes.
 * - unfreezeQENFT(tokenId): Unmarks a token as Frozen.
 * - isFrozen(tokenId): Checks if a token is Frozen.
 * - updateVisibleProperty(tokenId, index, value): Allows owner to update a visible property (only if not Collapsed or Frozen).
 * - setEntropyOracle(oracleAddress): Owner function to set the trusted address for providing entropy.
 * - getEntropyOracle(): Returns the current entropy oracle address.
 * - getReceivedEntropy(tokenId): Returns the raw entropy data received for a token in Collapsing/Collapsed state.
 * - setMetadataURI(tokenId, uri): Sets the metadata URI for a token.
 * - getMetadataURI(tokenId): Gets the metadata URI for a token.
 * - getTotalMinted(): Returns the total number of tokens minted.
 * - getOwnerOf(tokenId): Returns the owner of a token.
 * - getBalanceOf(owner): Returns the number of tokens owned by an address.
 * - getAdmin(): Returns the current admin address.
 * - setAdmin(adminAddress): Owner function to set the admin address.
 * - adminSetState(tokenId, newState): Admin override to set a token's state (use with caution).
 * - adminSetVisibleProperties(tokenId, properties): Admin override to set all visible properties.
 * - adminSetHiddenProperties(tokenId, properties): Admin override to set all hidden properties (use after collapse or with adminSetState).
 * - adminClearEntanglement(tokenId): Admin override to break entanglement without requiring the partner.
 */


contract QuantumEntanglementNFT {

    // --- 1. State Variables & Constants ---
    address private _owner;
    address private _admin; // Secondary administrative role
    address private _entropyOracle; // Address allowed to call provideEntropy

    uint256 private _totalSupply; // Total number of tokens minted
    uint256 private constant VISIBLE_PROPERTIES_COUNT = 5; // Example: 5 slots for visible properties
    uint256 private constant HIDDEN_PROPERTIES_COUNT = 3; // Example: 3 slots for hidden properties

    // --- 2. Enums for NFT State ---
    enum QENFTState {
        NonExistent,  // Represents a non-minted token ID
        Uncollapsed,
        Entangled,
        Collapsing,   // Intermediate state waiting for entropy
        Collapsed     // Final state, properties revealed
    }

    // --- 3. Struct for Token Data ---
    struct TokenData {
        QENFTState state;
        address owner;
        uint256 entanglementPartnerId; // 0 if not entangled
        bool isFrozen;
        uint256[VISIBLE_PROPERTIES_COUNT] visibleProperties;
        uint256[HIDDEN_PROPERTIES_COUNT] hiddenProperties; // Determined upon collapse
        bytes entropyData; // Data received from oracle for collapse
        bool partnerEffectApplied; // Flag set by partner if triggerEntangledEffect is called
        string metadataURI;
    }

    // --- 4. Mappings for Token State, Ownership, Balances ---
    mapping(uint256 => TokenData) private _tokenData;
    mapping(address => uint256) private _balances; // Simple balance counter

    // --- 5. Events ---
    event QENFTMinted(uint256 indexed tokenId, address indexed owner);
    event TokensEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event TokensDisentangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event CollapseInitiated(uint256 indexed tokenId);
    event EntropyProvided(uint256 indexed tokenId, bytes entropyHash);
    event CollapseFinalized(uint256 indexed tokenId);
    event QENFTTransfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event QENFTBurned(uint256 indexed tokenId, address indexed owner);
    event VisiblePropertyChanged(uint256 indexed tokenId, uint256 indexed index, uint256 newValue);
    event HiddenPropertyChanged(uint256 indexed tokenId, uint256 indexed index, uint256 newValue);
    event EntangledEffectTriggered(uint256 indexed tokenId, uint256 indexed partnerTokenId);
    event QENFTFrozen(uint256 indexed tokenId);
    event QENFTUnfrozen(uint256 indexed tokenId);
    event AdminSetState(uint256 indexed tokenId, QENFTState newState);
    event EntropyOracleSet(address indexed oldOracle, address indexed newOracle);
    event AdminSet(address indexed oldAdmin, address indexed newAdmin);

    // --- 6. Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == _owner, "QENFT: Not contract owner");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin || msg.sender == _owner, "QENFT: Not admin or owner");
        _;
    }

    modifier onlyEntropyOracle() {
        require(msg.sender == _entropyOracle, "QENFT: Not entropy oracle");
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        require(_tokenData[tokenId].state != QENFTState.NonExistent, "QENFT: Token does not exist");
        _;
    }

    modifier notFrozen(uint256 tokenId) {
        require(!_tokenData[tokenId].isFrozen, "QENFT: Token is frozen");
        _;
    }

    modifier isOwner(uint256 tokenId) {
        require(_tokenData[tokenId].owner == msg.sender, "QENFT: Not token owner");
        _;
    }

    // --- 7. Constructor ---
    constructor() {
        _owner = msg.sender;
        // Admin and EntropyOracle are initially unset (address(0))
    }

    // --- 8. Core NFT Logic (Mint, Transfer, Burn - Custom Implementations) ---

    /**
     * @dev Mints a new Quantum Entanglement NFT.
     * Sets initial state to Uncollapsed and assigns ownership to the caller.
     */
    function mintQENFT() external {
        _totalSupply++;
        uint256 newTokenId = _totalSupply; // Simple incremental ID

        _tokenData[newTokenId].state = QENFTState.Uncollapsed;
        _tokenData[newTokenId].owner = msg.sender;
        _tokenData[newTokenId].isFrozen = false;
        _tokenData[newTokenId].entanglementPartnerId = 0; // Not entangled initially
        _tokenData[newTokenId].partnerEffectApplied = false; // No effect applied initially

        // Initialize properties to default values (e.g., 0)
        for (uint256 i = 0; i < VISIBLE_PROPERTIES_COUNT; i++) {
             _tokenData[newTokenId].visibleProperties[i] = 0;
        }
         for (uint256 i = 0; i < HIDDEN_PROPERTIES_COUNT; i++) {
             _tokenData[newTokenId].hiddenProperties[i] = 0; // Will be set on collapse
        }

        _balances[msg.sender]++;

        emit QENFTMinted(newTokenId, msg.sender);
    }

    /**
     * @dev Transfers ownership of a single QENFT.
     * Only allowed if the token is not Entangled and not Frozen.
     * @param to The recipient address.
     * @param tokenId The ID of the token to transfer.
     */
    function transferSingleQENFT(address to, uint256 tokenId)
        external
        tokenExists(tokenId)
        isOwner(tokenId)
        notFrozen(tokenId)
    {
        require(to != address(0), "QENFT: transfer to zero address");
        require(_tokenData[tokenId].state != QENFTState.Entangled, "QENFT: Cannot transfer single entangled token. Use transferEntangledPair.");
        require(_tokenData[tokenId].state != QENFTState.Collapsing, "QENFT: Cannot transfer token during collapse process.");

        _transfer(msg.sender, to, tokenId);
    }

    /**
     * @dev Transfers ownership of an Entangled pair of QENFTs.
     * Both tokens must be owned by the caller and sent to the same recipient.
     * @param to The recipient address for both tokens.
     * @param tokenId1 The ID of the first token in the pair.
     * @param tokenId2 The ID of the second token in the pair.
     */
    function transferEntangledPair(address to, uint256 tokenId1, uint256 tokenId2)
        external
        tokenExists(tokenId1)
        tokenExists(tokenId2)
        isOwner(tokenId1)
        isOwner(tokenId2) // Both must be owned by caller
        notFrozen(tokenId1)
        notFrozen(tokenId2) // Both must not be frozen
    {
        require(to != address(0), "QENFT: transfer to zero address");
        require(tokenId1 != tokenId2, "QENFT: Cannot transfer same token as a pair");

        // Verify entanglement and partner IDs match
        require(_tokenData[tokenId1].state == QENFTState.Entangled, "QENFT: Token 1 is not entangled");
        require(_tokenData[tokenId2].state == QENFTState.Entangled, "QENFT: Token 2 is not entangled");
        require(_tokenData[tokenId1].entanglementPartnerId == tokenId2, "QENFT: Token 1 partner mismatch");
        require(_tokenData[tokenId2].entanglementPartnerId == tokenId1, "QENFT: Token 2 partner mismatch");

        // Both must be in Entangled state, implies not Collapsing or Collapsed
        require(_tokenData[tokenId1].state != QENFTState.Collapsing && _tokenData[tokenId1].state != QENFTState.Collapsed, "QENFT: Cannot transfer entangled pair if either is Collapsing or Collapsed.");

        _transfer(msg.sender, to, tokenId1);
        _transfer(msg.sender, to, tokenId2);
    }

    /**
     * @dev Internal transfer logic. Updates owner and balances.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        _balances[from]--;
        _balances[to]++;
        _tokenData[tokenId].owner = to;

        emit QENFTTransfer(from, to, tokenId);
    }


    /**
     * @dev Burns a QENFT.
     * If the token is Entangled, its partner is also automatically burned (cascading burn).
     * Not allowed if the token is Frozen.
     * @param tokenId The ID of the token to burn.
     */
    function burnQENFT(uint256 tokenId)
        external
        tokenExists(tokenId)
        isOwner(tokenId)
        notFrozen(tokenId)
    {
        QENFTState currentState = _tokenData[tokenId].state;
        uint256 partnerId = _tokenData[tokenId].entanglementPartnerId;

        _burn(tokenId); // Burn the requested token

        // If Entangled, burn the partner too
        if (currentState == QENFTState.Entangled && partnerId != 0) {
             // Check if partner still exists and is indeed the partner
            if (_tokenData[partnerId].state != QENFTState.NonExistent && _tokenData[partnerId].entanglementPartnerId == tokenId) {
                 // Important: The partner must NOT be frozen to be cascade burned.
                 // This prevents infinite loops if someone tries to burn one token
                 // while the other is frozen. The cascade fails if the partner is frozen.
                 require(!_tokenData[partnerId].isFrozen, "QENFT: Entangled partner is frozen, cannot cascade burn.");

                 // Note: partner might be owned by someone else if transferEntangledPair wasn't used correctly,
                 // but the requirement for burning is that msg.sender owns the token THEY INITIATED THE BURN ON.
                 // The cascade burn doesn't require msg.sender to own the partner,
                 // but it's implied by the Entangled state rules (pairs should stay together).
                 // If pairs get separated (e.g. via admin override), cascade burn might burn a token someone else owns!
                 // Add owner check for cascade burn for safety in weird states.
                 require(_tokenData[partnerId].owner == address(this) || _tokenData[partnerId].owner == msg.sender, "QENFT: Entangled partner not owned by caller or contract, cannot cascade burn.");


                 _burn(partnerId); // Burn the partner
            }
        }
    }

     /**
     * @dev Internal burn logic. Cleans up state.
     */
    function _burn(uint256 tokenId) internal {
        address owner = _tokenData[tokenId].owner;

        _balances[owner]--;
        delete _tokenData[tokenId]; // Removes all data associated with the tokenId

        emit QENFTBurned(tokenId, owner);
        // Total supply is not decreased, as token IDs are incremental and not reused.
    }

    // --- 9. State Management (Entangle, Disentangle, Collapse Process) ---

    /**
     * @dev Attempts to entangle two Uncollapsed QENFTs.
     * Both tokens must be owned by the caller and be in the Uncollapsed state.
     * @param tokenId1 The ID of the first token.
     * @param tokenId2 The ID of the second token.
     */
    function entangleTokens(uint256 tokenId1, uint256 tokenId2)
        external
        tokenExists(tokenId1)
        tokenExists(tokenId2)
        isOwner(tokenId1)
        isOwner(tokenId2)
        notFrozen(tokenId1)
        notFrozen(tokenId2)
    {
        require(tokenId1 != tokenId2, "QENFT: Cannot entangle a token with itself");
        require(_tokenData[tokenId1].state == QENFTState.Uncollapsed, "QENFT: Token 1 must be Uncollapsed");
        require(_tokenData[tokenId2].state == QENFTState.Uncollapsed, "QENFT: Token 2 must be Uncollapsed");

        _tokenData[tokenId1].state = QENFTState.Entangled;
        _tokenData[tokenId1].entanglementPartnerId = tokenId2;
        _tokenData[tokenId2].state = QENFTState.Entangled;
        _tokenData[tokenId2].entanglementPartnerId = tokenId1;

        emit TokensEntangled(tokenId1, tokenId2);
    }

    /**
     * @dev Attempts to disentangle two Entangled QENFTs.
     * Both tokens must be owned by the caller and be in the Entangled state.
     * Only possible if neither token has initiated the collapse process (Collapsing or Collapsed).
     * @param tokenId1 The ID of the first token.
     * @param tokenId2 The ID of the second token.
     */
    function disentangleTokens(uint256 tokenId1, uint256 tokenId2)
        external
        tokenExists(tokenId1)
        tokenExists(tokenId2)
        isOwner(tokenId1)
        isOwner(tokenId2)
        notFrozen(tokenId1)
        notFrozen(tokenId2)
    {
        require(tokenId1 != tokenId2, "QENFT: Cannot disentangle the same token");

        require(_tokenData[tokenId1].state == QENFTState.Entangled, "QENFT: Token 1 must be Entangled");
        require(_tokenData[tokenId2].state == QENFTState.Entangled, "QENFT: Token 2 must be Entangled");
        require(_tokenData[tokenId1].entanglementPartnerId == tokenId2, "QENFT: Token 1 partner mismatch");
        require(_tokenData[tokenId2].entanglementPartnerId == tokenId1, "QENFT: Token 2 partner mismatch");

        // Cannot disentangle if collapse process has started
        require(_tokenData[tokenId1].state != QENFTState.Collapsing && _tokenData[tokenId1].state != QENFTState.Collapsed, "QENFT: Token 1 collapse process has started");
        require(_tokenData[tokenId2].state != QENFTState.Collapsing && _tokenData[tokenId2].state != QENFTState.Collapsed, "QENFT: Token 2 collapse process has started");


        _tokenData[tokenId1].state = QENFTState.Uncollapsed;
        _tokenData[tokenId1].entanglementPartnerId = 0;
        _tokenData[tokenId2].state = QENFTState.Uncollapsed;
        _tokenData[tokenId2].entanglementPartnerId = 0;

        emit TokensDisentangled(tokenId1, tokenId2);
    }

    /**
     * @dev Initiates the collapse process for a token.
     * Marks the token as Collapsing and makes it frozen until finalized.
     * Requires the token to be Uncollapsed or Entangled.
     * If Entangled, this *only* initiates collapse for the called token, not its partner automatically.
     * The partner can still be disentangled or initiated for its own collapse separately.
     * @param tokenId The ID of the token to initiate collapse for.
     */
    function initiateCollapse(uint256 tokenId)
        external
        tokenExists(tokenId)
        isOwner(tokenId)
        notFrozen(tokenId) // Must not be frozen when initiating
    {
        QENFTState currentState = _tokenData[tokenId].state;
        require(currentState == QENFTState.Uncollapsed || currentState == QENFTState.Entangled, "QENFT: Token must be Uncollapsed or Entangled to initiate collapse");

        _tokenData[tokenId].state = QENFTState.Collapsing;
        _tokenData[tokenId].isFrozen = true; // Automatically freeze during collapse process

        emit CollapseInitiated(tokenId);
    }

    /**
     * @dev Provides entropy data for a token in the Collapsing state.
     * Callable only by the designated EntropyOracle address.
     * @param tokenId The ID of the token receiving entropy.
     * @param entropyData The bytes of entropy data.
     */
    function provideEntropy(uint256 tokenId, bytes memory entropyData)
        external
        onlyEntropyOracle()
        tokenExists(tokenId)
    {
        require(_tokenData[tokenId].state == QENFTState.Collapsing, "QENFT: Token is not in Collapsing state");
        require(_tokenData[tokenId].entropyData.length == 0, "QENFT: Entropy already provided for this token");
        require(entropyData.length > 0, "QENFT: Entropy data cannot be empty");

        _tokenData[tokenId].entropyData = entropyData;

        emit EntropyProvided(tokenId, keccak256(entropyData));
    }

    /**
     * @dev Finalizes the collapse process for a token.
     * Requires the token to be in the Collapsing state and have received entropy data.
     * Uses the entropy data to determine the hidden properties.
     * Transitions the token state to Collapsed and unfreezes it.
     * @param tokenId The ID of the token to finalize collapse for.
     */
    function finalizeCollapse(uint256 tokenId)
        external
        tokenExists(tokenId)
    {
        require(_tokenData[tokenId].state == QENFTState.Collapsing, "QENFT: Token is not in Collapsing state");
        require(_tokenData[tokenId].entropyData.length > 0, "QENFT: Entropy data not yet provided");

        // Determine hidden properties based on entropy
        _determineHiddenProperties(tokenId, _tokenData[tokenId].entropyData);

        _tokenData[tokenId].state = QENFTState.Collapsed;
        _tokenData[tokenId].isFrozen = false; // Unfreeze after collapse

        emit CollapseFinalized(tokenId);
    }

    /**
     * @dev Internal function to determine and set hidden properties based on entropy.
     * This is a simplified deterministic process using hashing.
     * NOTE: This is not cryptographically secure randomness like VRF.
     * @param tokenId The ID of the token.
     * @param entropyData The entropy data provided by the oracle.
     */
    function _determineHiddenProperties(uint256 tokenId, bytes memory entropyData) internal {
        // Combine entropy with token-specific data for determination
        bytes32 seed = keccak256(abi.encodePacked(
            entropyData,
            tokenId,
            block.timestamp,
            block.chainid,
            block.difficulty // block.difficulty might be 0 or deprecated in PoS, use block.basefee or other state vars if needed
        ));

        for (uint256 i = 0; i < HIDDEN_PROPERTIES_COUNT; i++) {
            // Use a slice of the hash for each property
            // Shift the seed for each property to ensure variety
            bytes32 propertySeed = keccak256(abi.encodePacked(seed, i));
            // Convert bytes32 to uint256 and take modulo for a range
            _tokenData[tokenId].hiddenProperties[i] = uint256(propertySeed) % 1000; // Example: properties are 0-999
            emit HiddenPropertyChanged(tokenId, i, _tokenData[tokenId].hiddenProperties[i]);
        }
    }

    // --- 10. Property Management (Visible, Hidden, Updates, Getters) ---

    /**
     * @dev Gets a specific visible property for a token.
     * Visible properties are accessible regardless of state.
     * @param tokenId The ID of the token.
     * @param index The index of the visible property (0 to VISIBLE_PROPERTIES_COUNT - 1).
     * @return The value of the visible property.
     */
    function getVisibleProperties(uint256 tokenId, uint256 index)
        external
        view
        tokenExists(tokenId)
        returns (uint256)
    {
        require(index < VISIBLE_PROPERTIES_COUNT, "QENFT: Invalid visible property index");
        return _tokenData[tokenId].visibleProperties[index];
    }

    /**
     * @dev Gets a specific hidden property for a token.
     * Hidden properties are only accessible after the token is Collapsed.
     * @param tokenId The ID of the token.
     * @param index The index of the hidden property (0 to HIDDEN_PROPERTIES_COUNT - 1).
     * @return The value of the hidden property.
     */
    function getHiddenProperties(uint256 tokenId, uint256 index)
        external
        view
        tokenExists(tokenId)
        returns (uint256)
    {
        require(index < HIDDEN_PROPERTIES_COUNT, "QENFT: Invalid hidden property index");
        require(_tokenData[tokenId].state == QENFTState.Collapsed, "QENFT: Hidden properties not revealed yet");
        return _tokenData[tokenId].hiddenProperties[index];
    }

     /**
     * @dev Allows the owner to update a visible property of their token.
     * Only allowed if the token is not Collapsed and not Frozen.
     * @param tokenId The ID of the token.
     * @param index The index of the visible property to update.
     * @param value The new value for the property.
     */
    function updateVisibleProperty(uint256 tokenId, uint256 index, uint256 value)
        external
        tokenExists(tokenId)
        isOwner(tokenId)
        notFrozen(tokenId)
    {
        require(index < VISIBLE_PROPERTIES_COUNT, "QENFT: Invalid visible property index");
        require(_tokenData[tokenId].state != QENFTState.Collapsing && _tokenData[tokenId].state != QENFTState.Collapsed, "QENFT: Cannot update visible properties after collapse initiated/finalized");

        _tokenData[tokenId].visibleProperties[index] = value;
        emit VisiblePropertyChanged(tokenId, index, value);
    }


    // --- 11. Entanglement Effects ---

    /**
     * @dev If the token is Entangled and its partner is not Collapsed,
     * triggers a one-time effect by setting the 'partnerEffectApplied' flag on the partner.
     * Can only be called once per token/partner pair pre-collapse.
     * @param tokenId The ID of the token triggering the effect.
     */
    function triggerEntangledEffect(uint256 tokenId)
        external
        tokenExists(tokenId)
        isOwner(tokenId)
        notFrozen(tokenId)
    {
        require(_tokenData[tokenId].state == QENFTState.Entangled, "QENFT: Token is not Entangled");
        uint256 partnerId = _tokenData[tokenId].entanglementPartnerId;
        require(partnerId != 0, "QENFT: Token is not entangled with a partner");
        require(_tokenData[partnerId].state != QENFTState.Collapsing && _tokenData[partnerId].state != QENFTState.Collapsed, "QENFT: Partner collapse process has started or finalized");

        TokenData storage partnerData = _tokenData[partnerId];
        require(!partnerData.partnerEffectApplied, "QENFT: Entangled effect already applied by partner");

        partnerData.partnerEffectApplied = true;
        emit EntangledEffectTriggered(tokenId, partnerId);

        // Note: The effect itself (what it means) is not implemented here.
        // It's just a state flag, indicating external logic might react to it,
        // or the hidden property determination could potentially use this flag.
    }

    /**
     * @dev Checks if the 'partnerEffectApplied' flag is set on this token.
     * @param tokenId The ID of the token.
     * @return True if the partner has triggered the effect on this token, false otherwise.
     */
    function checkPartnerEffectStatus(uint256 tokenId)
        external
        view
        tokenExists(tokenId)
        returns (bool)
    {
        return _tokenData[tokenId].partnerEffectApplied;
    }

    // --- 12. Freezing Mechanism ---

     /**
     * @dev Freezes a QENFT.
     * A frozen token cannot be transferred or have its state changed by the owner.
     * Admin/Owner overrides are still possible.
     * @param tokenId The ID of the token to freeze.
     */
    function freezeQENFT(uint256 tokenId)
        external
        tokenExists(tokenId)
        isOwner(tokenId)
    {
        require(!_tokenData[tokenId].isFrozen, "QENFT: Token is already frozen");
        _tokenData[tokenId].isFrozen = true;
        emit QENFTFrozen(tokenId);
    }

     /**
     * @dev Unfreezes a QENFT.
     * @param tokenId The ID of the token to unfreeze.
     */
    function unfreezeQENFT(uint256 tokenId)
        external
        tokenExists(tokenId)
        isOwner(tokenId)
    {
        require(_tokenData[tokenId].isFrozen, "QENFT: Token is not frozen");
        _tokenData[tokenId].isFrozen = false;
        emit QENFTUnfrozen(tokenId);
    }

    /**
     * @dev Checks if a QENFT is frozen.
     * @param tokenId The ID of the token.
     * @return True if the token is frozen, false otherwise.
     */
    function isFrozen(uint256 tokenId)
        external
        view
        tokenExists(tokenId)
        returns (bool)
    {
        return _tokenData[tokenId].isFrozen;
    }


    // --- 13. Access Control (Owner, Admin, Entropy Oracle) ---

    /**
     * @dev Sets the trusted address for providing entropy data.
     * Only callable by the contract owner.
     * @param oracleAddress The address of the entropy oracle.
     */
    function setEntropyOracle(address oracleAddress) external onlyOwner {
        address oldOracle = _entropyOracle;
        _entropyOracle = oracleAddress;
        emit EntropyOracleSet(oldOracle, oracleAddress);
    }

    /**
     * @dev Gets the current entropy oracle address.
     */
    function getEntropyOracle() external view returns (address) {
        return _entropyOracle;
    }

    /**
     * @dev Sets the admin address.
     * Only callable by the contract owner.
     * @param adminAddress The address to set as admin.
     */
    function setAdmin(address adminAddress) external onlyOwner {
        address oldAdmin = _admin;
        _admin = adminAddress;
        emit AdminSet(oldAdmin, adminAddress);
    }

    /**
     * @dev Gets the current admin address.
     */
    function getAdmin() external view returns (address) {
        return _admin;
    }

    /**
     * @dev Allows admin or owner to force set the state of a token.
     * Use with extreme caution, as this bypasses normal state transitions.
     * @param tokenId The ID of the token.
     * @param newState The state to set.
     */
    function adminSetState(uint256 tokenId, QENFTState newState)
        external
        onlyAdmin()
        tokenExists(tokenId)
    {
        require(newState != QENFTState.NonExistent, "QENFT: Admin cannot set state to NonExistent (use burn)");
         _tokenData[tokenId].state = newState;
         emit AdminSetState(tokenId, newState);
    }

     /**
     * @dev Allows admin or owner to set all visible properties of a token.
     * Bypasses normal update restrictions.
     * @param tokenId The ID of the token.
     * @param properties An array of new visible property values.
     */
    function adminSetVisibleProperties(uint256 tokenId, uint256[VISIBLE_PROPERTIES_COUNT] memory properties)
        external
        onlyAdmin()
        tokenExists(tokenId)
    {
         _tokenData[tokenId].visibleProperties = properties;
         // No specific event for admin bulk set, relies on function call log
    }

     /**
     * @dev Allows admin or owner to set all hidden properties of a token.
     * Bypasses the entropy-based determination. Use with caution.
     * @param tokenId The ID of the token.
     * @param properties An array of new hidden property values.
     */
    function adminSetHiddenProperties(uint256 tokenId, uint256[HIDDEN_PROPERTIES_COUNT] memory properties)
        external
        onlyAdmin()
        tokenExists(tokenId)
    {
         _tokenData[tokenId].hiddenProperties = properties;
         // No specific event for admin bulk set, relies on function call log
    }

     /**
     * @dev Allows admin or owner to break the entanglement of a token unilaterally.
     * Use with caution, as this bypasses the disentangleTokens requirements.
     * Updates both the token and its partner.
     * @param tokenId The ID of the token to clear entanglement for.
     */
    function adminClearEntanglement(uint256 tokenId)
        external
        onlyAdmin()
        tokenExists(tokenId)
    {
         if (_tokenData[tokenId].state == QENFTState.Entangled) {
             uint256 partnerId = _tokenData[tokenId].entanglementPartnerId;
             _tokenData[tokenId].state = QENFTState.Uncollapsed;
             _tokenData[tokenId].entanglementPartnerId = 0;

             // Clear partner's entanglement if it exists and points back
             if (_tokenData[partnerId].state != QENFTState.NonExistent && _tokenData[partnerId].entanglementPartnerId == tokenId) {
                 _tokenData[partnerId].state = QENFTState.Uncollapsed; // Partner also goes back to Uncollapsed
                 _tokenData[partnerId].entanglementPartnerId = 0;
                 emit TokensDisentangled(tokenId, partnerId); // Emit event for clarity
             } else {
                 // Partner might be in a weird state, just note this token is no longer entangled
                 emit TokensDisentangled(tokenId, 0); // Indicate disentangled unilaterally
             }
         }
    }


    // --- 14. Utility & Query Functions ---

    /**
     * @dev Gets the current state of a QENFT.
     * @param tokenId The ID of the token.
     * @return The QENFTState enum value.
     */
    function getQENFTState(uint256 tokenId)
        external
        view
        tokenExists(tokenId)
        returns (QENFTState)
    {
        return _tokenData[tokenId].state;
    }

    /**
     * @dev Gets the entanglement partner ID for a QENFT.
     * Returns 0 if the token is not Entangled.
     * @param tokenId The ID of the token.
     * @return The partner token ID or 0.
     */
    function getEntanglementPair(uint256 tokenId)
        external
        view
        tokenExists(tokenId)
        returns (uint256)
    {
        return _tokenData[tokenId].entanglementPartnerId;
    }

     /**
     * @dev Gets the raw entropy data received for a token.
     * Only relevant for tokens that have been through initiateCollapse and provideEntropy.
     * @param tokenId The ID of the token.
     * @return The entropy data bytes.
     */
    function getReceivedEntropy(uint256 tokenId)
        external
        view
        tokenExists(tokenId)
        returns (bytes memory)
    {
        // Consider restricting this view based on state or role if entropy is sensitive
        // For this example, allowing view for anyone with a valid token ID
        return _tokenData[tokenId].entropyData;
    }


    /**
     * @dev Sets the metadata URI for a token.
     * @param tokenId The ID of the token.
     * @param uri The URI string.
     */
    function setMetadataURI(uint256 tokenId, string memory uri)
        external
        tokenExists(tokenId)
        isOwner(tokenId)
        notFrozen(tokenId) // Cannot change URI if frozen
    {
        _tokenData[tokenId].metadataURI = uri;
        // Note: Standard ERC721 might emit Transfer event with data=uri,
        // but we're not strictly following ERC721 interface.
    }

    /**
     * @dev Gets the metadata URI for a token.
     * @param tokenId The ID of the token.
     * @return The URI string.
     */
    function getMetadataURI(uint256 tokenId)
        external
        view
        tokenExists(tokenId)
        returns (string memory)
    {
        return _tokenData[tokenId].metadataURI;
    }

    /**
     * @dev Gets the total number of QENFTs ever minted.
     * Token IDs range from 1 to _totalSupply.
     */
    function getTotalMinted() external view returns (uint256) {
        return _totalSupply;
    }

     /**
     * @dev Gets the owner of a specific token.
     * Returns address(0) if the token does not exist.
     * @param tokenId The ID of the token.
     * @return The owner address.
     */
    function getOwnerOf(uint256 tokenId)
        external
        view
        returns (address)
    {
         // Return address(0) if it doesn't exist, consistent with ERC721 ownerOf
         if (_tokenData[tokenId].state == QENFTState.NonExistent) {
             return address(0);
         }
        return _tokenData[tokenId].owner;
    }

    /**
     * @dev Gets the number of tokens owned by an address.
     * @param owner The address to query.
     * @return The balance of tokens.
     */
    function getBalanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "QENFT: balance query for zero address");
        return _balances[owner];
    }

    // ERC165 compatibility (optional but good practice if interacting with marketplaces)
    // function supportsInterface(bytes4 interfaceId) external view returns (bool) {
    //     // Replace with actual ERC721 interfaceId if implementing full interface,
    //     // otherwise this contract has a custom interface.
    //     // Example: return interfaceId == 0x80ac58cd; // ERC721 standard interface ID
    //     return false; // Explicitly state we don't support ERC721 interface directly
    // }

}
```