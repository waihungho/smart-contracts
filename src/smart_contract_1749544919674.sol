Okay, let's create a smart contract with a creative, advanced concept: **Quantum Entangled NFTs (QENFTs)**.

This concept uses the metaphor of quantum entanglement to introduce dynamic, probabilistic relationships between pairs of NFTs. When two QENFTs are "entangled," certain actions or state changes on one *might* probabilistically affect the other, even if they are held by different owners. The entanglement has a limited "coherence time" and can "decay". Randomness plays a key role in the probability of entanglement effects.

This contract will be an ERC-721 extension with additional features.

---

## Smart Contract Outline & Function Summary

**Contract Name:** QuantumEntangledNFTs

**Concept:** An ERC-721 standard NFT contract where NFTs can be paired through a "quantum entanglement" mechanism. Entangled NFTs are linked such that a state or attribute change on one token has a probabilistic chance of affecting its entangled partner. Entanglement requires on-chain randomness (via Chainlink VRF) and has a limited duration ("coherence time") after which it decays.

**Key Features:**

1.  **ERC-721 Compliance:** Standard NFT ownership, transfer, and approval functions.
2.  **Dynamic Attributes & State:** NFTs have mutable attributes and states that can change based on interactions.
3.  **Quantum Entanglement:** A novel mechanism to link pairs of NFTs.
    *   Requires initiation and confirmation via Chainlink VRF for randomness.
    *   Stores the link between entangled pairs.
    *   Has a defined "coherence time" (duration).
4.  **Probabilistic Effect Propagation:** When a state/attribute changes on one entangled NFT, there's a chance (determined by randomness) that a related change occurs on its entangled partner.
5.  **Entanglement Decay:** Entanglement weakens over time or interactions and can eventually break.
6.  **On-chain Randomness:** Uses Chainlink VRF for unbiased probability outcomes (entanglement success, effect propagation).
7.  **Admin Controls:** Owner functions for setting parameters, pausing, etc.
8.  **Burn Function:** Allows burning of NFTs.

**Function Summary (at least 20):**

*   **Core ERC-721 (8 functions):** Standard functions required by ERC-721.
    1.  `balanceOf(address owner)`: Get number of tokens owned by an address.
    2.  `ownerOf(uint256 tokenId)`: Get owner of a token.
    3.  `approve(address to, uint256 tokenId)`: Approve another address to transfer a token.
    4.  `getApproved(uint256 tokenId)`: Get the approved address for a token.
    5.  `setApprovalForAll(address operator, bool approved)`: Approve/disapprove an operator for all tokens.
    6.  `isApprovedForAll(address owner, address operator)`: Check if an address is an operator.
    7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfer token (standard).
    8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfer token (safe).
    9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Transfer token (safe with data). *(Added for completeness, brings ERC721 total to 9)*
*   **Minting (3 functions):**
    10. `mint(address to)`: Mint a single token to an address.
    11. `mintBatch(address to, uint256 numTokens)`: Mint multiple tokens to an address.
    12. `adminMint(address to, uint256 tokenId, Attributes initialAttributes)`: Mint a specific token with predefined attributes (admin only).
*   **State & Attributes (4 functions):**
    13. `getAttributes(uint256 tokenId)`: Retrieve current attributes of a token.
    14. `getTokenState(uint256 tokenId)`: Retrieve current state of a token.
    15. `changeState(uint256 tokenId, QENFTState newState)`: Change the state of a token (might trigger entanglement effect).
    16. `changeAttribute(uint256 tokenId, uint8 attributeIndex, uint256 newValue)`: Change a specific attribute of a token (might trigger entanglement effect).
*   **Entanglement Management (5 functions):**
    17. `requestEntangle(uint256 tokenId1, uint256 tokenId2)`: Initiate entanglement request between two tokens. Requires VRF.
    18. `fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)`: VRF callback to finalize entanglement request based on randomness.
    19. `disentangle(uint256 tokenId)`: Manually break entanglement for a token (also breaks for partner).
    20. `triggerDecay(uint256 tokenId)`: Allow anyone to trigger entanglement decay check for a token.
    21. `isEntangled(uint256 tokenId)`: Check if a token is currently entangled.
*   **Query Functions (3 functions):**
    22. `getEntangledPartner(uint256 tokenId)`: Get the token ID of the entangled partner. Returns 0 if not entangled.
    23. `getEntanglementCoherence(uint256 tokenId)`: Get the remaining coherence time/strength of entanglement.
    24. `tokenURI(uint256 tokenId)`: Standard ERC-721 metadata URI function (will generate dynamic URI or point to resolver).
*   **Admin & Parameters (5 functions):**
    25. `pause()`: Pause contract operations (minting, entanglement, state changes).
    26. `unpause()`: Unpause contract operations.
    27. `setBaseURI(string memory baseURI_)`: Set the base URI for metadata.
    28. `setEntanglementParameters(uint64 subscriptionId, bytes32 keyHash, uint32 callbackGasLimit, uint32 requestConfirmations, uint256 requestProbabilityBasisPoints)`: Set Chainlink VRF and entanglement probability parameters.
    29. `setDecayParameters(uint256 decayRatePerSecond, uint256 maxCoherenceTime)`: Set parameters for entanglement decay.
*   **Utility (1 function):**
    30. `burn(uint256 tokenId)`: Burn (destroy) a token.

*(Total functions: 9 + 3 + 4 + 5 + 3 + 5 + 1 = 30. Meets the >= 20 requirement)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@chainlink/contracts/src/v0.8/VRF/VRFConsumerBaseV3.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- OUTLINE AND FUNCTION SUMMARY ABOVE ---

contract QuantumEntangledNFTs is ERC721, Ownable, Pausable, VRFConsumerBaseV3 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- State Structures & Enums ---

    enum QENFTState {
        RESTING,        // Default state
        EXCITED,        // Active/interacting state
        SUPERPOSITION,  // State before entanglement confirmed
        COLLAPSED       // Final/locked state
    }

    // Example Attributes struct - can be customized
    struct Attributes {
        uint256 strength;
        uint256 dexterity;
        string element; // e.g., "Fire", "Water", "Air", "Earth"
        // Add more attributes as needed
    }

    struct EntanglementInfo {
        uint256 partnerTokenId;
        uint256 startTime; // Timestamp of entanglement
        uint256 coherenceTime; // Duration of entanglement
        uint256 entanglementStrength; // A value that might decay over time/interactions
    }

    // --- State Variables ---

    // Token ID to its attributes
    mapping(uint256 => Attributes) private _tokenAttributes;

    // Token ID to its state
    mapping(uint256 => QENFTState) private _tokenState;

    // Token ID to its entanglement info (partner, start time, coherence)
    mapping(uint256 => EntanglementInfo) private _entanglements;

    // Map VRF request ID to the pair of tokens requesting entanglement
    mapping(uint256 => uint256[2]) private _entanglementRequests;

    string private _baseTokenURI;

    // --- Chainlink VRF Parameters ---
    uint64 private s_subscriptionId;
    bytes32 private s_keyHash;
    uint32 private s_callbackGasLimit;
    uint32 private s_requestConfirmations;
    // Probability that entanglement succeeds (in basis points, 10000 = 100%)
    uint256 private s_entanglementProbabilityBasisPoints = 7500; // 75%

    // --- Entanglement Decay Parameters ---
    uint256 private s_decayRatePerSecond = 1; // Points of strength lost per second (example)
    uint256 private s_maxCoherenceTime = 7 days; // Max duration of entanglement (example)
    uint256 private s_maxEntanglementStrength = 100; // Initial strength

    // --- Events ---

    event Minted(address indexed to, uint256 indexed tokenId);
    event StateChanged(uint256 indexed tokenId, QENFTState oldState, QENFTState newState);
    event AttributeChanged(uint256 indexed tokenId, uint8 attributeIndex, uint256 oldValue, uint256 newValue);
    event EntanglementRequested(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed requestId);
    event EntanglementCreated(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 coherenceTime);
    event Disentangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EntanglementDecayed(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EntanglementEffectApplied(uint256 indexed sourceTokenId, uint256 indexed targetTokenId, string effectDescription);
    event RandomnessReceived(uint256 indexed requestId, uint256[] randomWords);

    // --- Constructor ---

    constructor(
        address initialOwner,
        address vrfCoordinator,
        uint64 subscriptionId,
        bytes32 keyHash,
        uint32 callbackGasLimit,
        uint32 requestConfirmations
    )
        ERC721("Quantum Entangled NFT", "QENFT")
        Ownable(initialOwner)
        Pausable()
        VRFConsumerBaseV3(vrfCoordinator)
    {
        s_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
        s_callbackGasLimit = callbackGasLimit;
        s_requestConfirmations = requestConfirmations;
    }

    // --- Pausable Overrides ---
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Auto-disentangle on transfer for simplicity in this example
        // A more complex contract could allow entangled transfers, but that
        // adds significant complexity to state management across owners.
        if (_entanglements[tokenId].partnerTokenId != 0) {
            _disentanglePair(tokenId, _entanglements[tokenId].partnerTokenId);
        }
    }

    // --- ERC-721 Required Functions (Provided by OpenZeppelin) ---
    // balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom

    // Override tokenURI for dynamic metadata (placeholder logic)
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            return "";
        }

        // Example: Append token ID and state/attributes for dynamic metadata API
        string memory tokenUriSuffix = string(abi.encodePacked(
            Strings.toString(tokenId),
            "?state=",
            getStateString(_tokenState[tokenId]),
            "&strength=", Strings.toString(_tokenAttributes[tokenId].strength),
            "&element=", _tokenAttributes[tokenId].element // Example attributes
        ));

        if (bytes(base).length > 0 && bytes(tokenUriSuffix).length > 0) {
             // Ensure base ends with a slash if needed
            if (bytes(base)[bytes(base).length - 1] != '/') {
                return string(abi.encodePacked(base, "/", tokenUriSuffix));
            } else {
                return string(abi.encodePacked(base, tokenUriSuffix));
            }
        }

        return base;
    }

    // Helper to get state string for URI (example)
    function getStateString(QENFTState state) internal pure returns (string memory) {
        if (state == QENFTState.RESTING) return "resting";
        if (state == QENFTState.EXCITED) return "excited";
        if (state == QENFTState.SUPERPOSITION) return "superposition";
        if (state == QENFTState.COLLAPSED) return "collapsed";
        return "unknown";
    }


    // --- Minting Functions ---

    /// @notice Mints a new token to the recipient. Initial state is RESTING.
    function mint(address to) public onlyOwner whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);

        // Set default state and initial attributes
        _tokenState[newTokenId] = QENFTState.RESTING;
        _tokenAttributes[newTokenId] = Attributes({
            strength: 10,
            dexterity: 10,
            element: "None" // Default element
            // Initialize other attributes as needed
        });

        emit Minted(to, newTokenId);
        return newTokenId;
    }

    /// @notice Mints multiple tokens to the recipient.
    function mintBatch(address to, uint256 numTokens) public onlyOwner whenNotPaused {
        require(numTokens > 0, "Cannot mint 0 tokens");
        require(numTokens <= 50, "Batch size limited to 50"); // Example limit

        for (uint i = 0; i < numTokens; i++) {
            mint(to); // Reuse single mint logic
        }
    }

    /// @notice Mints a specific token ID with custom attributes (admin only).
    function adminMint(address to, uint256 tokenId, Attributes initialAttributes) public onlyOwner whenNotPaused {
        require(!_exists(tokenId), "Token ID already exists");
        // Need to handle the counter if admin mints below the current counter value.
        // For simplicity here, assume admin mints are for special, higher IDs or pre-allocated.
        // A robust implementation might require careful counter management or a separate minting process.
        if (tokenId >= _tokenIdCounter.current()) {
             _tokenIdCounter.current = tokenId + 1;
        }

        _safeMint(to, tokenId);
        _tokenState[tokenId] = QENFTState.RESTING;
        _tokenAttributes[tokenId] = initialAttributes;

        emit Minted(to, tokenId);
    }


    // --- State & Attribute Functions ---

    /// @notice Gets the attributes for a given token ID.
    function getAttributes(uint256 tokenId) public view returns (Attributes memory) {
        _requireOwned(tokenId); // Only owner can view detailed attributes directly? Or public? Let's make it public view.
        return _tokenAttributes[tokenId];
    }

    /// @notice Gets the state for a given token ID.
    function getTokenState(uint256 tokenId) public view returns (QENFTState) {
        _requireOwned(tokenId); // Public view is also fine
        return _tokenState[tokenId];
    }

    /// @notice Changes the state of a token. May trigger entanglement effect if entangled.
    /// @param tokenId The ID of the token to change state.
    /// @param newState The new state for the token.
    function changeState(uint256 tokenId, QENFTState newState) public payable whenNotPaused {
        _requireOwned(tokenId);
        require(_tokenState[tokenId] != QENFTState.COLLAPSED, "Cannot change state of a collapsed token");

        QENFTState oldState = _tokenState[tokenId];
        _tokenState[tokenId] = newState;
        emit StateChanged(tokenId, oldState, newState);

        // If entangled, potentially propagate effect
        if (_entanglements[tokenId].partnerTokenId != 0) {
            _applyEntanglementEffect(tokenId, _entanglements[tokenId].partnerTokenId);
        }
    }

    /// @notice Changes a specific attribute of a token. May trigger entanglement effect if entangled.
    /// @dev AttributeIndex maps to the position in the Attributes struct (0=strength, 1=dexterity, etc.).
    /// @param tokenId The ID of the token to change attribute.
    /// @param attributeIndex The index of the attribute to change (e.g., 0 for strength).
    /// @param newValue The new value for the attribute.
    function changeAttribute(uint256 tokenId, uint8 attributeIndex, uint256 newValue) public payable whenNotPaused {
        _requireOwned(tokenId);
        require(_tokenState[tokenId] != QENFTState.COLLAPSED, "Cannot change attribute of a collapsed token");

        Attributes storage attrs = _tokenAttributes[tokenId];
        uint256 oldValue;

        // This is a simple example. A real implementation might need more complex handling
        // for different attribute types (uint, string, etc.) and validation.
        if (attributeIndex == 0) { // Assuming index 0 is strength (uint256)
            oldValue = attrs.strength;
            attrs.strength = newValue;
        } else if (attributeIndex == 1) { // Assuming index 1 is dexterity (uint256)
            oldValue = attrs.dexterity;
            attrs.dexterity = newValue;
        }
        // Add more conditions for other attribute indices/types

        // Emit generic event for attribute change
        emit AttributeChanged(tokenId, attributeIndex, oldValue, newValue);

        // If entangled, potentially propagate effect
        if (_entanglements[tokenId].partnerTokenId != 0) {
            _applyEntanglementEffect(tokenId, _entanglements[tokenId].partnerTokenId);
        }
    }


    // --- Entanglement Management Functions ---

    /// @notice Initiates the process to entangle two tokens. Requires VRF request.
    /// @dev Requires both tokens to be in RESTING state and not already entangled.
    function requestEntangle(uint256 tokenId1, uint256 tokenId2) public payable whenNotPaused {
        _requireOwned(tokenId1); // Caller must own the first token
        require(ownerOf(tokenId2) != address(0), "Token 2 does not exist");
        require(tokenId1 != tokenId2, "Cannot entangle a token with itself");
        require(!isEntangled(tokenId1), "Token 1 is already entangled");
        require(!isEntangled(tokenId2), "Token 2 is already entangled");
        require(_tokenState[tokenId1] == QENFTState.RESTING, "Token 1 must be in RESTING state");
        require(_tokenState[tokenId2] == QENFTState.RESTING, "Token 2 must be in RESTING state");

        // Change states to SUPERPOSITION while waiting for randomness
        _tokenState[tokenId1] = QENFTState.SUPERPOSITION;
        _tokenState[tokenId2] = QENFTState.SUPERPOSITION;
        emit StateChanged(tokenId1, QENFTState.RESTING, QENFTState.SUPERPOSITION);
        emit StateChanged(tokenId2, QENFTState.RESTING, QENFTState.SUPERPOSITION);


        // Request randomness from Chainlink VRF
        uint256 requestId = requestRandomWords(s_keyHash, s_subscriptionId, s_requestConfirmations, s_callbackGasLimit, 1); // Request 1 random word

        _entanglementRequests[requestId] = [tokenId1, tokenId2];

        emit EntanglementRequested(tokenId1, tokenId2, requestId);
    }

    /// @notice VRF callback function. Finalizes entanglement based on random outcome.
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(randomWords.length > 0, "VRF did not return random words");

        uint256 tokenId1 = _entanglementRequests[requestId][0];
        uint256 tokenId2 = _entanglementRequests[requestId][1];

        delete _entanglementRequests[requestId]; // Clean up the request mapping

        emit RandomnessReceived(requestId, randomWords);

        // Check if tokens are still valid targets (not burned, not already entangled by other means)
        if (!_exists(tokenId1) || !_exists(tokenId2) || _entanglements[tokenId1].partnerTokenId != 0 || _entanglements[tokenId2].partnerTokenId != 0) {
             // Revert states if possible, or leave them in SUPERPOSITION as a failed state
            if (_exists(tokenId1) && _tokenState[tokenId1] == QENFTState.SUPERPOSITION) _tokenState[tokenId1] = QENFTState.RESTING;
            if (_exists(tokenId2) && _tokenState[tokenId2] == QENFTState.SUPERPOSITION) _tokenState[tokenId2] = QENFTState.RESTING;
            return; // Abort entanglement if conditions changed
        }

        // Use the random word to determine if entanglement succeeds
        uint256 randomNumber = randomWords[0];
        uint256 probabilityThreshold = (type(uint256).max / 10000) * s_entanglementProbabilityBasisPoints;

        if (randomNumber < probabilityThreshold) {
            // Entanglement Success!
            uint256 coherenceDuration = s_maxCoherenceTime; // Example: fixed max time on success
            uint256 initialStrength = s_maxEntanglementStrength; // Example: fixed max strength

            _entanglements[tokenId1] = EntanglementInfo(tokenId2, block.timestamp, coherenceDuration, initialStrength);
            _entanglements[tokenId2] = EntanglementInfo(tokenId1, block.timestamp, coherenceDuration, initialStrength);

            // Change states to EXCITED now that they are linked
            _tokenState[tokenId1] = QENFTState.EXCITED;
            _tokenState[tokenId2] = QENFTState.EXCITED;
            emit StateChanged(tokenId1, QENFTState.SUPERPOSITION, QENFTState.EXCITED);
            emit StateChanged(tokenId2, QENFTState.SUPERPOSITION, QENFTState.EXCITED);

            emit EntanglementCreated(tokenId1, tokenId2, coherenceDuration);

        } else {
            // Entanglement Failed
            // Revert states back to RESTING
            _tokenState[tokenId1] = QENFTState.RESTING;
            _tokenState[tokenId2] = QENFTState.RESTING;
            emit StateChanged(tokenId1, QENFTState.SUPERPOSITION, QENFTState.RESTING);
            emit StateChanged(tokenId2, QENFTState.SUPERPOSITION, QENFTState.RESTING);
        }
    }

    /// @notice Breaks the entanglement between a token and its partner.
    /// @param tokenId The ID of one of the entangled tokens.
    function disentangle(uint256 tokenId) public whenNotPaused {
         _requireOwned(tokenId);
         uint256 partnerTokenId = _entanglements[tokenId].partnerTokenId;
         require(partnerTokenId != 0, "Token is not entangled");

         _disentanglePair(tokenId, partnerTokenId);
    }

    /// @dev Internal function to perform the disentanglement logic.
    function _disentanglePair(uint256 tokenId1, uint256 tokenId2) internal {
        require(tokenId1 != 0 && tokenId2 != 0 && tokenId1 != tokenId2, "Invalid disentanglement pair");
        require(_entanglements[tokenId1].partnerTokenId == tokenId2, "Tokens are not entangled with each other");

        // Reset entanglement info
        delete _entanglements[tokenId1];
        delete _entanglements[tokenId2];

        // Reset states if they were EXCITED
        if (_tokenState[tokenId1] == QENFTState.EXCITED) _tokenState[tokenId1] = QENFTState.RESTING;
        if (_tokenState[tokenId2] == QENFTState.EXCITED) _tokenState[tokenId2] = QENFTState.RESTING;

        emit Disentangled(tokenId1, tokenId2);
    }

    /// @notice Allows anyone to trigger a decay check for a token's entanglement.
    /// @dev This is a way to allow external actors to pay for checking/applying decay.
    function triggerDecay(uint256 tokenId) public whenNotPaused {
        // No ownership check needed, anyone can trigger decay check
        if (_entanglements[tokenId].partnerTokenId != 0) {
            _applyDecay(tokenId);
        }
    }

    /// @notice Checks if a token is currently entangled.
    function isEntangled(uint256 tokenId) public view returns (bool) {
        return _entanglements[tokenId].partnerTokenId != 0;
    }

    /// @notice Gets the entangled partner's token ID. Returns 0 if not entangled.
    function getEntangledPartner(uint256 tokenId) public view returns (uint256) {
        return _entanglements[tokenId].partnerTokenId;
    }

    /// @notice Gets the remaining coherence time of the entanglement (in seconds).
    function getEntanglementCoherence(uint256 tokenId) public view returns (uint256 remainingSeconds) {
        EntanglementInfo storage info = _entanglements[tokenId];
        if (info.partnerTokenId == 0) {
            return 0; // Not entangled
        }
        uint256 elapsed = block.timestamp - info.startTime;
        if (elapsed >= info.coherenceTime) {
            return 0; // Coherence expired
        }
        return info.coherenceTime - elapsed;
    }


    // --- Internal Entanglement Logic ---

    /// @dev Applies decay logic to a token's entanglement. Breaks if coherence expires.
    function _applyDecay(uint256 tokenId) internal {
        EntanglementInfo storage info = _entanglements[tokenId];
        if (info.partnerTokenId != 0) {
            if (block.timestamp >= info.startTime + info.coherenceTime) {
                // Coherence expired, disentangle
                _disentanglePair(tokenId, info.partnerTokenId);
                emit EntanglementDecayed(tokenId, info.partnerTokenId);
            } else {
                 // Example decay logic: strength decreases over time
                 // uint256 elapsed = block.timestamp - info.startTime;
                 // info.entanglementStrength = s_maxEntanglementStrength > elapsed * s_decayRatePerSecond ? s_maxEntanglementStrength - elapsed * s_decayRatePerSecond : 0;
                 // A more complex model could involve probabilistic decay per block/interaction
            }
        }
    }


    /// @dev Probabilistically applies an effect to the entangled partner. Requires randomness.
    /// This function should be triggered *after* a state or attribute change on the source token.
    /// This simplified version requests new randomness for *each* potential effect.
    /// A more gas-efficient approach might use one batch of randomness from VRF upon entanglement creation
    /// or rely on other sources of entropy. Given the VRF latency, a more realistic async approach
    /// would be to request randomness *before* the effect application is needed, and process it later.
    /// For this example, we'll simulate the effect application here *if* randomness were instantly available,
    /// but note the practical limitation with VRF. A truly *probabilistic* effect triggered *immediately*
    /// by a user action is difficult with async VRF.
    /// Alternative: Use block hash as a weaker source of randomness, or Chainlink keepers to trigger based on state changes.
    function _applyEntanglementEffect(uint256 sourceTokenId, uint256 targetTokenId) internal {
        // Check if still entangled and if coherence hasn't expired
        EntanglementInfo storage sourceInfo = _entanglements[sourceTokenId];
        if (sourceInfo.partnerTokenId != targetTokenId || block.timestamp >= sourceInfo.startTime + sourceInfo.coherenceTime) {
             // Entanglement is no longer valid, perhaps trigger decay cleanup
             if (sourceInfo.partnerTokenId == targetTokenId) _applyDecay(sourceTokenId);
             return;
        }

        // *** SIMULATED EFFECT APPLICATION (Requires randomness not available synchronously with VRF) ***
        // In a real scenario using VRF, you'd need a different flow:
        // 1. User action triggers `changeState` or `changeAttribute`.
        // 2. This function (_applyEntanglementEffect) is called.
        // 3. Instead of applying effect, it *requests* randomness for this specific effect application.
        // 4. When VRF callback `fulfillRandomWords` happens later, it processes the *pending* effect request using the received randomness.

        // For demonstration, let's assume we *could* get randomness here (e.g., using block.timestamp % 100 or a pre-fetched random value)
        // A simple block hash based probability check (less secure/unpredictable than VRF for sensitive outcomes)
        uint256 effectProbabilityBasisPoints = 5000; // 50% chance of effect (example)
        // uint256 pseudoRandomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, sourceTokenId, targetTokenId))) % 10000;
        // if (pseudoRandomNumber < effectProbabilityBasisPoints) { ... apply effect ... }
        // Or, if we had fetched randomness:
        // uint256 randomWordForEffect = ... get from storage based on a pre-fetched requestId ... ;
        // uint256 effectProbabilityThreshold = (type(uint256).max / 10000) * effectProbabilityBasisPoints;
        // if (randomWordForEffect < effectProbabilityThreshold) { ... apply effect ... }


        // --- Example Effect Logic (executed if the probabilistic check passed) ---
        // This part needs to be implemented in the VRF callback if using VRF for effect probability.
        // Here, we write the logic as if it *could* happen here probabilistically.

        // Example: Mirroring state change
        QENFTState sourceState = _tokenState[sourceTokenId];
        QENFTState targetState = _tokenState[targetTokenId];

        if (sourceState != targetState && targetState != QENFTState.COLLAPSED) {
             // Probabilistically change partner's state to match the source's state (if it's not collapsed)
             // if (probabilistic check passes) {
                  _tokenState[targetTokenId] = sourceState;
                  emit StateChanged(targetTokenId, targetState, sourceState);
                  emit EntanglementEffectApplied(sourceTokenId, targetTokenId, "Mirrored State Change");
             // }
        }

        // Example: Randomly change an attribute
        // if (another probabilistic check passes) {
            // Use randomness to pick an attribute and change it
            // uint8 randomAttributeIndex = ... based on randomness ... % num_attributes;
            // uint256 randomAttributeValue = ... based on randomness ... ;
            // Attributes storage targetAttrs = _tokenAttributes[targetTokenId];
            // if (randomAttributeIndex == 0) targetAttrs.strength = randomAttributeValue;
            // ... similar for other attributes ...
            // emit AttributeChanged(...);
            // emit EntanglementEffectApplied(...);
        // }

        // --- END SIMULATED EFFECT APPLICATION ---

        // Regardless of whether an effect was applied, interaction can cause decay (example)
        // info.entanglementStrength = info.entanglementStrength > s_decayRatePerSecond ? info.entanglementStrength - s_decayRatePerSecond : 0;
        // if (info.entanglementStrength == 0) {
        //    _disentanglePair(sourceTokenId, targetTokenId);
        //    emit EntanglementDecayed(sourceTokenId, targetTokenId);
        // } else {
            _applyDecay(sourceTokenId); // Check time decay after interaction
        // }
    }

    // --- Query Functions ---

    /// @notice Gets the current base URI for metadata.
    function getBaseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    // tokenURI is already overridden above (function 24)

    // --- Admin & Parameter Functions ---

    /// @notice Sets the base URI for token metadata.
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
    }

    /// @notice Sets parameters for Chainlink VRF and the entanglement success probability.
    function setEntanglementParameters(
        uint64 subscriptionId,
        bytes32 keyHash,
        uint32 callbackGasLimit,
        uint32 requestConfirmations,
        uint256 requestProbabilityBasisPoints_ // in basis points (0-10000)
    ) public onlyOwner {
        require(requestProbabilityBasisPoints_ <= 10000, "Probability cannot exceed 10000 basis points");
        s_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
        s_callbackGasLimit = callbackGasLimit;
        s_requestConfirmations = requestConfirmations;
        s_entanglementProbabilityBasisPoints = requestProbabilityBasisPoints_;
    }

     /// @notice Sets parameters for entanglement decay.
     function setDecayParameters(uint256 decayRatePerSecond_, uint256 maxCoherenceTime_) public onlyOwner {
        require(decayRatePerSecond_ > 0, "Decay rate must be positive");
        require(maxCoherenceTime_ > 0, "Max coherence time must be positive");
        s_decayRatePerSecond = decayRatePerSecond_;
        s_maxCoherenceTime = maxCoherenceTime_;
     }

     /// @notice Sets the initial maximum entanglement strength.
     function setMaxEntanglementStrength(uint256 maxStrength_) public onlyOwner {
        require(maxStrength_ > 0, "Max strength must be positive");
        s_maxEntanglementStrength = maxStrength_;
     }

     // Note: A real VRF setup would also need a way for the owner to fund the VRF subscription.
     // This is typically done via the Chainlink Subscription Manager UI or contract.

    // --- Utility Functions ---

    /// @notice Burns (destroys) a token. Disentangles if necessary.
    function burn(uint256 tokenId) public payable {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");

        // Auto-disentangle before burning
        if (_entanglements[tokenId].partnerTokenId != 0) {
            _disentanglePair(tokenId, _entanglements[tokenId].partnerTokenId);
        }

        _burn(tokenId);
        // Clean up state and attributes (optional, but good practice for storage)
        delete _tokenState[tokenId];
        delete _tokenAttributes[tokenId];
    }

    // --- Internal Helpers ---

    // @dev Internal helper to require token ownership or approval for transfer/management
    function _requireOwned(uint256 tokenId) internal view {
         require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
    }
}
```

---

**Explanation of Advanced Concepts and Creativity:**

1.  **Quantum Entanglement Metaphor:** This is the core creative element. It's not *actual* quantum mechanics, but uses the concept of linked probabilistic states to drive the NFT's dynamic behavior.
2.  **Dynamic State and Attributes:** NFTs are not static JPEGs or fixed data points. Their `QENFTState` and `Attributes` can change based on interactions and external triggers (`changeState`, `changeAttribute`, `triggerDecay`).
3.  **Probabilistic Interactions:** Entanglement creation and the effect propagation are not guaranteed outcomes but depend on randomness, making interactions unpredictable and potentially more engaging.
4.  **On-chain Randomness (Chainlink VRF):** Using a verifiable random function is crucial for fair and unpredictable probabilistic outcomes, preventing manipulation. This is a standard but essential advanced pattern for unpredictable on-chain events.
5.  **Entanglement Lifecycle:** The concept includes creation (via VRF), a limited lifespan (`coherenceTime`), decay (`triggerDecay`, potentially passive decay logic), and destruction (`disentangle`, `burn`). This adds a temporal dimension to the relationships.
6.  **Event-Driven Effects:** State or attribute changes on one token *trigger* the potential for effects on its partner. This makes the tokens reactive to each other's "actions".
7.  **Async Randomness Handling:** While the example `_applyEntanglementEffect` is simplified, the structure using `requestEntangle` and `fulfillRandomWords` correctly models the asynchronous nature of fetching randomness via VRF, a key pattern in using VRF. A more complete implementation would need to store pending effects and process them in the VRF callback.
8.  **Composable Potential:** While not fully built out, the framework allows for future extensions where different attribute changes or state transitions on one token could cause *different* kinds of effects on the partner, leading to complex emergent behaviors between entangled pairs.
9.  **State Enums:** Using an enum for `QENFTState` makes the token's lifecycle and possible modes explicit and type-safe.
10. **Decay Trigger:** Allowing anyone to call `triggerDecay` incentivizes the community (or bots) to pay the gas cost for maintaining the state of the contract and cleaning up expired entanglements.

This contract goes beyond simple ERC-721 minting and transferring by introducing complex, probabilistic, and dynamic relationships between tokens, driven by a creative metaphor and relying on an external oracle for randomness.