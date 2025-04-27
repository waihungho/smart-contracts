Okay, let's design a creative, advanced concept smart contract based on a "Quantum Entanglement" analogy. This contract will manage non-fungible tokens (NFTs) that can be minted in entangled pairs. Actions on one token can potentially affect its entangled partner, and tokens can have a "superposition" state that collapses upon interaction.

We will build upon the ERC-721 standard but significantly modify and extend its behavior.

**Concept:** **Quantum Entangled Tokens (QET)**

*   NFTs minted in pairs.
*   Tokens within a pair are "entangled".
*   Entangled tokens have restrictions (e.g., transfer requires moving the pair).
*   Entanglement can be broken.
*   Tokens can have a "superposition" state with potential outcomes.
*   Interacting with a token ("measurement") collapses its superposition, determining a final state/value based on external factors (like block data for pseudo-randomness).
*   Entanglement can decay over time or with interactions, potentially weakening the link or auto-breaking.

---

**Outline and Function Summary:**

**Contract Name:** QuantumEntangledToken

**Core Functionality:**
1.  Manage ownership and metadata of unique tokens (ERC-721 base).
2.  Mint tokens in *entangled pairs*.
3.  Track and manage the entangled state between paired tokens.
4.  Implement a special transfer function for entangled pairs.
5.  Allow breaking entanglement.
6.  Manage a "superposition" state for each token, which has a potential value.
7.  Implement a "measurement" function that collapses the superposition and sets a final, determined value.
8.  Introduce a "decoherence" mechanism where entanglement can weaken or break over time/interactions.
9.  Provide query functions for entanglement status, pair information, superposition status, and values.
10. Include standard ERC-721 queries and basic access control (Ownable, Pausable).

**Function Summary (Total: 30+ functions)**

*   **ERC-721 Standard Functions (Modified):**
    1.  `balanceOf(address owner)`: Get the number of tokens owned by an address. (Standard)
    2.  `ownerOf(uint256 tokenId)`: Get the owner of a token. (Standard)
    3.  `approve(address to, uint256 tokenId)`: Approve an address to manage a token. (Modified: Restricted if entangled)
    4.  `getApproved(uint256 tokenId)`: Get the approved address for a token. (Standard)
    5.  `setApprovalForAll(address operator, bool approved)`: Set operator approval for all tokens. (Standard)
    6.  `isApprovedForAll(address owner, address operator)`: Check if an address is an operator. (Standard)
    7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfer token ownership. (Modified: Restricted if entangled)
    8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer token ownership. (Modified: Restricted if entangled)
    9.  `burn(uint256 tokenId)`: Destroy a token. (Modified: Restricted if entangled)
    10. `tokenURI(uint256 tokenId)`: Get metadata URI for a token. (Standard, could reflect state)
    11. `supportsInterface(bytes4 interfaceId)`: Check ERC-165 interface support. (Standard)

*   **Entanglement & Pairing Functions:**
    12. `mintEntangledPair(address owner)`: Mints two new tokens, establishes their entanglement, and assigns ownership to `owner`.
    13. `breakEntanglement(uint256 tokenId)`: Breaks the entanglement bond between a token and its partner. Requires specific conditions (e.g., owner, minimum duration passed).
    14. `transferEntangledPair(address from, address to, uint256 pairId)`: Transfers ownership of *both* tokens in an entangled pair simultaneously. This is the required method for moving entangled tokens.
    15. `getEntangledPartner(uint256 tokenId)`: Returns the token ID of the entangled partner. Returns 0 if not entangled.
    16. `getPairId(uint256 tokenId)`: Returns the unique ID of the pair the token belongs to.
    17. `isTokenEntangled(uint256 tokenId)`: Checks if a specific token is currently entangled.
    18. `getPairTokens(uint256 pairId)`: Returns the two token IDs associated with a given pair ID.
    19. `burnPair(uint256 pairId)`: Burns *both* tokens within a pair. Requires the pair to be entangled.

*   **Superposition & Measurement Functions:**
    20. `initializeSuperposition(uint256 tokenId, uint256 potentialValue)`: Sets the initial "potential value" for a token's superposition state. Can only be done before measurement.
    21. `measureSuperposition(uint256 tokenId, bytes32 externalEntropy)`: Collapses the token's superposition state. Determines and sets the final "measured value" based on the potential value and provided entropy (e.g., block hash). Affects partner if entangled? (Let's make it token-specific for simplicity).
    22. `getCurrentMeasuredValue(uint256 tokenId)`: Returns the final value if the token's superposition has been measured. Returns 0 or a sentinel value if not measured.
    23. `getPotentialSuperpositionValue(uint256 tokenId)`: Returns the initial potential value if the superposition has not been measured.
    24. `isSuperpositionMeasured(uint256 tokenId)`: Checks if a token's superposition has been measured.

*   **Decoherence & Time/Interaction Functions:**
    25. `applyDecoherence(uint256 tokenId)`: Triggers the decoherence logic for a token. Could potentially break entanglement or alter state based on time elapsed since minting/last interaction or total interactions.
    26. `getDecoherenceTimestamp(uint256 tokenId)`: Returns the timestamp associated with the token's decoherence state (e.g., when it was last checked or when decay started).
    27. `getInteractionCount(uint256 tokenId)`: Returns the number of significant interactions (e.g., `measureSuperposition`, `applyDecoherence`) a token has undergone.

*   **Configuration & Utility Functions:**
    28. `setMinEntanglementDuration(uint256 duration)`: Sets the minimum time (in seconds) before entanglement can be broken by `breakEntanglement`. (Owner only)
    29. `getMinEntanglementDuration()`: Gets the minimum entanglement duration.
    30. `setDecoherenceRate(uint256 rate)`: Sets parameters for the decoherence logic (e.g., how fast decay happens). (Owner only)
    31. `getDecoherenceRate()`: Gets the decoherence rate parameter.
    32. `getTotalPairs()`: Returns the total number of entangled pairs ever minted.
    33. `getPairOwner(uint256 pairId)`: Returns the owner of a pair (assuming both tokens in a pair must have the same owner).

*   **Access Control Functions (from OpenZeppelin):**
    34. `renounceOwnership()`: Relinquish ownership of the contract. (Owner only)
    35. `transferOwnership(address newOwner)`: Transfer ownership of the contract. (Owner only)
    36. `pause()`: Pause contract operations (transfers, minting, etc.). (Owner only)
    37. `unpause()`: Unpause contract operations. (Owner only)
    38. `paused()`: Check if the contract is paused.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For potential complex decoherence logic

// Outline and Function Summary:
// Contract Name: QuantumEntangledToken
// Core Functionality:
// 1. Manage ownership and metadata of unique tokens (ERC-721 base).
// 2. Mint tokens in entangled pairs.
// 3. Track and manage the entangled state between paired tokens.
// 4. Implement a special transfer function for entangled pairs.
// 5. Allow breaking entanglement.
// 6. Manage a "superposition" state for each token, which has a potential value.
// 7. Implement a "measurement" function that collapses the superposition and sets a final, determined value.
// 8. Introduce a "decoherence" mechanism where entanglement can weaken or break over time/interactions.
// 9. Provide query functions for entanglement status, pair information, superposition status, and values.
// 10. Include standard ERC-721 queries and basic access control (Ownable, Pausable).

// Function Summary (Total: 30+ functions)
// ERC-721 Standard Functions (Modified):
// 1.  balanceOf(address owner)
// 2.  ownerOf(uint256 tokenId)
// 3.  approve(address to, uint256 tokenId) (Modified)
// 4.  getApproved(uint256 tokenId)
// 5.  setApprovalForAll(address operator, bool approved)
// 6.  isApprovedForAll(address owner, address operator)
// 7.  transferFrom(address from, address to, uint256 tokenId) (Modified)
// 8.  safeTransferFrom(address from, address to, uint256 tokenId) (Modified)
// 9.  burn(uint256 tokenId) (Modified)
// 10. tokenURI(uint256 tokenId)
// 11. supportsInterface(bytes4 interfaceId)

// Entanglement & Pairing Functions:
// 12. mintEntangledPair(address owner)
// 13. breakEntanglement(uint256 tokenId)
// 14. transferEntangledPair(address from, address to, uint256 pairId)
// 15. getEntangledPartner(uint256 tokenId)
// 16. getPairId(uint256 tokenId)
// 17. isTokenEntangled(uint256 tokenId)
// 18. getPairTokens(uint256 pairId)
// 19. burnPair(uint256 pairId)

// Superposition & Measurement Functions:
// 20. initializeSuperposition(uint256 tokenId, uint256 potentialValue)
// 21. measureSuperposition(uint256 tokenId, bytes32 externalEntropy)
// 22. getCurrentMeasuredValue(uint256 tokenId)
// 23. getPotentialSuperpositionValue(uint256 tokenId)
// 24. isSuperpositionMeasured(uint256 tokenId)

// Decoherence & Time/Interaction Functions:
// 25. applyDecoherence(uint256 tokenId)
// 26. getDecoherenceTimestamp(uint256 tokenId)
// 27. getInteractionCount(uint256 tokenId)

// Configuration & Utility Functions:
// 28. setMinEntanglementDuration(uint256 duration)
// 29. getMinEntanglementDuration()
// 30. setDecoherenceRate(uint256 rate)
// 31. getDecoherenceRate()
// 32. getTotalPairs()
// 33. getPairOwner(uint256 pairId)

// Access Control Functions (from OpenZeppelin):
// 34. renounceOwnership()
// 35. transferOwnership(address newOwner)
// 36. pause()
// 37. unpause()
// 38. paused()


contract QuantumEntangledToken is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _tokenIds; // Counter for individual token IDs
    Counters.Counter private _pairIds;  // Counter for pair IDs

    // Mapping from tokenId to its entangled partner tokenId (0 if not entangled)
    mapping(uint256 => uint256) private _entangledPartner;

    // Mapping from tokenId to the unique pairId it belongs to
    mapping(uint256 => uint256) private _tokenPairId;

    // Mapping from pairId to the two tokenIds in that pair
    mapping(uint256 => uint256[2]) private _pairTokens;

    // --- Superposition State ---
    // Represents the potential state before 'measurement'
    mapping(uint256 => uint256) private _potentialSuperpositionValue;
    // Represents the actual state after 'measurement'
    mapping(uint256 => uint256) private _currentMeasuredValue;
    // Flag to check if superposition has been measured
    mapping(uint256 => bool) private _isSuperpositionMeasured;

    // --- Decoherence State ---
    // Timestamp when the token was minted (used for entanglement duration)
    mapping(uint256 => uint64) private _mintTimestamp;
    // Timestamp related to decoherence logic (e.g., last checked, decay started)
    mapping(uint256 => uint64) private _decoherenceTimestamp;
    // Count of significant interactions (measurement, applying decoherence)
    mapping(uint256 => uint256) private _interactionCount;

    // --- Configuration ---
    // Minimum time (in seconds) entanglement must exist before breaking
    uint256 private _minEntanglementDuration = 0; // Default: Can be broken immediately
    // Rate parameter for decoherence logic (interpretation flexible, e.g., blocks/interactions per decay step)
    uint256 private _decoherenceRate = 100; // Default value

    // --- Events ---
    event PairMinted(address indexed owner, uint256 pairId, uint256 tokenId1, uint256 tokenId2);
    event EntanglementBroken(uint256 pairId, uint256 tokenId1, uint256 tokenId2);
    event EntangledPairTransferred(address indexed from, address indexed to, uint256 pairId, uint256 tokenId1, uint256 tokenId2);
    event SuperpositionInitialized(uint256 indexed tokenId, uint256 potentialValue);
    event SuperpositionMeasured(uint256 indexed tokenId, uint256 measuredValue);
    event DecoherenceApplied(uint256 indexed tokenId, string effect); // effect could be "none", "weakened", "broken"

    // --- Constructor ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    // --- Modifiers ---
    modifier whenNotEntangled(uint256 tokenId) {
        require(!isTokenEntangled(tokenId), "QET: Token is entangled");
        _;
    }

    modifier whenEntangled(uint256 tokenId) {
        require(isTokenEntangled(tokenId), "QET: Token is not entangled");
        _;
    }

    modifier onlyEntangledPairOwner(uint256 pairId) {
        uint256[2] memory pairTokens = _pairTokens[pairId];
        require(pairTokens[0] != 0 && pairTokens[1] != 0, "QET: Invalid pair ID");
        require(ownerOf(pairTokens[0]) == msg.sender && ownerOf(pairTokens[1]) == msg.sender, "QET: Not owner of pair");
        _;
    }

    // --- Override ERC-721 Functions ---

    // 3. approve - Restricted if entangled
    function approve(address to, uint256 tokenId) public virtual override whenNotPaused whenNotEntangled(tokenId) {
        super.approve(to, tokenId);
    }

    // 7. transferFrom - Restricted if entangled
    function transferFrom(address from, address to, uint256 tokenId) public virtual override whenNotPaused whenNotEntangled(tokenId) {
        // Standard transferFrom is only allowed if the token is NOT entangled.
        // Entangled tokens must use transferEntangledPair.
        super.transferFrom(from, to, tokenId);
        _trackInteraction(tokenId); // Optional: track interactions on transfer
    }

    // 8. safeTransferFrom - Restricted if entangled
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override whenNotPaused whenNotEntangled(tokenId) {
        // Standard safeTransferFrom is only allowed if the token is NOT entangled.
        // Entangled tokens must use transferEntangledPair.
        super.safeTransferFrom(from, to, tokenId);
        _trackInteraction(tokenId); // Optional: track interactions on transfer
    }

    // 8. safeTransferFrom - Restricted if entangled
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override whenNotPaused whenNotEntangled(tokenId) {
        // Standard safeTransferFrom is only allowed if the token is NOT entangled.
        // Entangled tokens must use transferEntangledPair.
        super.safeTransferFrom(from, to, tokenId, data);
         _trackInteraction(tokenId); // Optional: track interactions on transfer
    }


    // 9. burn - Restricted if entangled. Must break entanglement or burn pair.
    function burn(uint256 tokenId) public virtual override whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "QET: Caller is not owner");
        require(!isTokenEntangled(tokenId), "QET: Cannot burn entangled token directly. Break entanglement first or burn the pair.");
        super.burn(tokenId);
         // No interaction tracking needed for burning
    }

    // 10. tokenURI - Can be overridden to reflect state/entanglement
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Example: Could include token ID, entanglement status, measured value in URI
        // string memory base = "ipfs://your_base_uri/";
        // string memory state = isTokenEntangled(tokenId) ? "entangled" : "free";
        // string memory value = _isSuperpositionMeasured[tokenId] ? Strings.toString(_currentMeasuredValue[tokenId]) : "unmeasured";
        // return string(abi.encodePacked(base, tokenId.toString(), "?state=", state, "&value=", value));
         return super.tokenURI(tokenId); // Default simple implementation
    }

    // 11. supportsInterface - Include ERC721
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ERC721).interfaceId || super.supportsInterface(interfaceId);
    }


    // --- Entanglement & Pairing Functions ---

    // 12. mintEntangledPair
    function mintEntangledPair(address owner) public onlyOwner whenNotPaused returns (uint256 pairId, uint256 tokenId1, uint256 tokenId2) {
        require(owner != address(0), "QET: Mint to zero address");

        _pairIds.increment();
        uint256 currentPairId = _pairIds.current();

        _tokenIds.increment();
        uint256 tokenAId = _tokenIds.current();

        _tokenIds.increment();
        uint256 tokenBId = _tokenIds.current();

        // Mint tokens
        _safeMint(owner, tokenAId);
        _safeMint(owner, tokenBId);

        // Establish entanglement
        _entangledPartner[tokenAId] = tokenBId;
        _entangledPartner[tokenBId] = tokenAId;

        // Link to pair ID
        _tokenPairId[tokenAId] = currentPairId;
        _tokenPairId[tokenBId] = currentPairId;
        _pairTokens[currentPairId] = [tokenAId, tokenBId];

        // Record mint timestamp for decoherence
        _mintTimestamp[tokenAId] = uint64(block.timestamp);
        _mintTimestamp[tokenBId] = uint64(block.timestamp);
        _decoherenceTimestamp[tokenAId] = uint64(block.timestamp); // Initialize decoherence timer
        _decoherenceTimestamp[tokenBId] = uint64(block.timestamp); // Initialize decoherence timer

        emit PairMinted(owner, currentPairId, tokenAId, tokenBId);

        return (currentPairId, tokenAId, tokenBId);
    }

    // 13. breakEntanglement
    function breakEntanglement(uint256 tokenId) public payable whenNotPaused whenEntangled(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "QET: Caller is not owner of token");

        uint256 partnerId = _entangledPartner[tokenId];
        uint256 pairId = _tokenPairId[tokenId];

        require(partnerId != 0, "QET: Token is not entangled"); // Should be caught by modifier
        require(ownerOf(partnerId) == msg.sender, "QET: Owner must also own the partner token to break entanglement");

        // Enforce minimum duration if set
        require(block.timestamp >= _mintTimestamp[tokenId] + _minEntanglementDuration, "QET: Minimum entanglement duration not passed");

        // Break the link
        _entangledPartner[tokenId] = 0;
        _entangledPartner[partnerId] = 0;

        // Note: Pair ID remains associated, but entanglement is broken.
        // The tokens are now 'free' and can be transferred individually.

        emit EntanglementBroken(pairId, tokenId, partnerId);
    }

    // 14. transferEntangledPair
    function transferEntangledPair(address from, address to, uint256 pairId) public payable whenNotPaused onlyEntangledPairOwner(pairId) {
        require(from == msg.sender || isApprovedForAll(from, msg.sender), "QET: Caller is not owner nor approved operator");
        require(to != address(0), "QET: Transfer to zero address");

        uint256[2] memory pairTokens = _pairTokens[pairId];
        uint256 tokenId1 = pairTokens[0];
        uint256 tokenId2 = pairTokens[1];

        require(ownerOf(tokenId1) == from && ownerOf(tokenId2) == from, "QET: From address must own both tokens in the pair");
        require(isTokenEntangled(tokenId1) && isTokenEntangled(tokenId2), "QET: Pair must be entangled to use this function");
        require(_entangledPartner[tokenId1] == tokenId2 && _entangledPartner[tokenId2] == tokenId1, "QET: Pair link is broken");

        // Perform transfers using internal helper (avoids re-checking entanglement within _transfer)
        _transfer(from, to, tokenId1);
        _transfer(from, to, tokenId2);

        // Note: Approvals for individual tokens are likely invalidated by _transfer.

        // Track interaction for both tokens
        _trackInteraction(tokenId1);
        _trackInteraction(tokenId2);


        emit EntangledPairTransferred(from, to, pairId, tokenId1, tokenId2);
    }

    // 15. getEntangledPartner
    function getEntangledPartner(uint256 tokenId) public view returns (uint256) {
        return _entangledPartner[tokenId];
    }

    // 16. getPairId
    function getPairId(uint256 tokenId) public view returns (uint256) {
        return _tokenPairId[tokenId];
    }

    // 17. isTokenEntangled
    function isTokenEntangled(uint256 tokenId) public view returns (bool) {
        return _entangledPartner[tokenId] != 0;
    }

    // 18. getPairTokens
    function getPairTokens(uint256 pairId) public view returns (uint256[2] memory) {
         require(pairId > 0 && pairId <= _pairIds.current(), "QET: Invalid pair ID");
        return _pairTokens[pairId];
    }

     // 19. burnPair
    function burnPair(uint256 pairId) public payable whenNotPaused onlyEntangledPairOwner(pairId) {
        uint256[2] memory pairTokens = _pairTokens[pairId];
        uint256 tokenId1 = pairTokens[0];
        uint256 tokenId2 = pairTokens[1];

         require(tokenId1 != 0 && tokenId2 != 0, "QET: Invalid pair tokens");
         require(isTokenEntangled(tokenId1) && isTokenEntangled(tokenId2), "QET: Pair must be entangled to be burned together");
         require(_entangledPartner[tokenId1] == tokenId2, "QET: Pair link mismatch");

        // Break entanglement explicitly before burning (or handle it internally)
        // Let's handle internally by resetting state before calling super.burn
        _entangledPartner[tokenId1] = 0;
        _entangledPartner[tokenId2] = 0;
        // Note: Pair ID and _pairTokens mapping might be kept for history, but token existence check confirms validity.
        // We don't decrement _pairIds.current() as this tracks total minted.

        super.burn(tokenId1);
        super.burn(tokenId2);

        // Clear other state mappings if necessary, though existence check is primary
        delete _tokenPairId[tokenId1];
        delete _tokenPairId[tokenId2];
        delete _mintTimestamp[tokenId1];
        delete _mintTimestamp[tokenId2];
        delete _decoherenceTimestamp[tokenId1];
        delete _decoherenceTimestamp[tokenId2];
        delete _interactionCount[tokenId1];
        delete _interactionCount[tokenId2];
        delete _potentialSuperpositionValue[tokenId1];
        delete _potentialSuperpositionValue[tokenId2];
        delete _currentMeasuredValue[tokenId1];
        delete _currentMeasuredValue[tokenId2];
        delete _isSuperpositionMeasured[tokenId1];
        delete _isSuperpositionMeasured[tokenId2];

        emit EntanglementBroken(pairId, tokenId1, tokenId2); // Emit that entanglement was broken as part of the burn
    }


    // --- Superposition & Measurement Functions ---

    // 20. initializeSuperposition
    function initializeSuperposition(uint256 tokenId, uint256 potentialValue) public payable whenNotPaused {
         require(_exists(tokenId), "QET: Token does not exist");
         require(ownerOf(tokenId) == msg.sender, "QET: Caller is not owner of token");
         require(!_isSuperpositionMeasured[tokenId], "QET: Superposition already measured");

         _potentialSuperpositionValue[tokenId] = potentialValue;

         emit SuperpositionInitialized(tokenId, potentialValue);
    }

    // 21. measureSuperposition
    // External entropy is needed as block.timestamp and block.hash are predictable
    // Consider Chainlink VRF or similar for production randomness
    function measureSuperposition(uint256 tokenId, bytes32 externalEntropy) public payable whenNotPaused {
        require(_exists(tokenId), "QET: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "QET: Caller is not owner of token");
        require(!_isSuperpositionMeasured[tokenId], "QET: Superposition already measured");
        require(_potentialSuperpositionValue[tokenId] > 0, "QET: Potential value not initialized"); // Ensure a potential value was set

        // Combine potential value, external entropy, and block data for pseudo-randomness
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(
            _potentialSuperpositionValue[tokenId],
            externalEntropy,
            block.timestamp,
            block.difficulty // block.difficulty is deprecated on PoS, consider other sources or remove
        )));

        // Simple pseudo-random determination based on the seed and potential value
        // In a real application, this logic could be much more complex
        uint256 measuredValue = (randomSeed % _potentialSuperpositionValue[tokenId]) + 1; // Value between 1 and potentialValue

        _currentMeasuredValue[tokenId] = measuredValue;
        _isSuperpositionMeasured[tokenId] = true;

        // Optional: Propagate some effect to partner if entangled
        // if (isTokenEntangled(tokenId)) {
        //     uint256 partnerId = _entangledPartner[tokenId];
        //     // Example: Partner's potential value is influenced, or state changes
        //     // _potentialSuperpositionValue[partnerId] = measuredValue * 2; // Just an example
        //     // emit SuperpositionInitialized(partnerId, _potentialSuperpositionValue[partnerId]);
        // }

        _trackInteraction(tokenId); // Track this interaction

        emit SuperpositionMeasured(tokenId, measuredValue);
    }

    // 22. getCurrentMeasuredValue
    function getCurrentMeasuredValue(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "QET: Token does not exist");
        return _currentMeasuredValue[tokenId]; // Returns 0 if not measured
    }

    // 23. getPotentialSuperpositionValue
    function getPotentialSuperpositionValue(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "QET: Token does not exist");
        return _potentialSuperpositionValue[tokenId];
    }

    // 24. isSuperpositionMeasured
    function isSuperpositionMeasured(uint256 tokenId) public view returns (bool) {
         require(_exists(tokenId), "QET: Token does not exist");
        return _isSuperpositionMeasured[tokenId];
    }

    // --- Decoherence & Time/Interaction Functions ---

    // 25. applyDecoherence
    // This function checks and applies potential decoherence effects
    // Could be called by anyone, perhaps incentivized, or periodically by an off-chain process
    function applyDecoherence(uint256 tokenId) public payable whenNotPaused {
        require(_exists(tokenId), "QET: Token does not exist");

        uint64 lastCheck = _decoherenceTimestamp[tokenId];
        uint64 currentTimestamp = uint64(block.timestamp);
        uint256 currentInteractions = _interactionCount[tokenId];
        bool currentlyEntangled = isTokenEntangled(tokenId);

        string memory effect = "none";

        if (currentlyEntangled) {
            // Example Decoherence Logic:
            // - If time since last check is significant AND interaction count is high...
            // - ...OR if total time since minting is very large...
            // - ...There's a chance entanglement breaks or weakens.

            uint256 timePassed = currentTimestamp - lastCheck;
            uint256 totalTime = currentTimestamp - _mintTimestamp[tokenId];

            // Pseudo-random chance based on time, interactions, and rate
            bytes32 entropy = keccak256(abi.encodePacked(tokenId, currentTimestamp, currentInteractions, timePassed, _decoherenceRate, block.difficulty)); // block.difficulty deprecated
            uint256 decayChance = uint256(entropy) % 1000; // 0-999

            uint256 threshold = (timePassed / 100) + (currentInteractions * 10) + (totalTime / 1000); // Example threshold logic
            threshold = threshold * (1000 / _decoherenceRate); // Apply rate influence

            if (decayChance < threshold) {
                 // Decoherence occurs!
                uint256 partnerId = _entangledPartner[tokenId];
                _entangledPartner[tokenId] = 0;
                _entangledPartner[partnerId] = 0;
                effect = "broken";
                emit EntanglementBroken(_tokenPairId[tokenId], tokenId, partnerId);
            } else {
                 // Entanglement didn't break this time, maybe just weakens (no state change in this simple example)
                 effect = "weakened (no break)";
            }
        } else {
             // Not entangled, maybe decoherence affects something else, or does nothing
             effect = "not entangled";
        }

        _decoherenceTimestamp[tokenId] = currentTimestamp; // Update timestamp
        _trackInteraction(tokenId); // Track this interaction

        emit DecoherenceApplied(tokenId, effect);
    }

    // 26. getDecoherenceTimestamp
    function getDecoherenceTimestamp(uint256 tokenId) public view returns (uint64) {
         require(_exists(tokenId), "QET: Token does not exist");
        return _decoherenceTimestamp[tokenId];
    }

    // 27. getInteractionCount
    function getInteractionCount(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "QET: Token does not exist");
        return _interactionCount[tokenId];
    }

    // Internal helper to track interactions that contribute to decoherence
    function _trackInteraction(uint256 tokenId) internal {
         if (_exists(tokenId)) { // Only track if token exists
            _interactionCount[tokenId]++;
         }
    }


    // --- Configuration & Utility Functions ---

    // 28. setMinEntanglementDuration
    function setMinEntanglementDuration(uint256 duration) public onlyOwner {
        _minEntanglementDuration = duration;
    }

    // 29. getMinEntanglementDuration
    function getMinEntanglementDuration() public view returns (uint256) {
        return _minEntanglementDuration;
    }

    // 30. setDecoherenceRate
    function setDecoherenceRate(uint256 rate) public onlyOwner {
        _decoherenceRate = rate;
    }

    // 31. getDecoherenceRate
    function getDecoherenceRate() public view returns (uint256) {
        return _decoherenceRate;
    }

    // 32. getTotalPairs
    function getTotalPairs() public view returns (uint256) {
        return _pairIds.current();
    }

    // 33. getPairOwner
    function getPairOwner(uint256 pairId) public view returns (address) {
        uint256[2] memory pairTokens = _pairTokens[pairId];
        require(pairTokens[0] != 0, "QET: Invalid pair ID");
        address owner1 = ownerOf(pairTokens[0]);
        address owner2 = ownerOf(pairTokens[1]);
        // Assuming both tokens in a pair must have the same owner for this query to be meaningful
        require(owner1 == owner2, "QET: Pair tokens have different owners");
        return owner1;
    }


    // --- Access Control Functions (from OpenZeppelin) ---
    // 34. renounceOwnership()
    // 35. transferOwnership(address newOwner)
    // 36. pause()
    // 37. unpause()
    // 38. paused()
    // These are inherited from Ownable and Pausable

    function pause() public onlyOwner virtual override {
        super.pause();
    }

    function unpause() public onlyOwner virtual override {
        super.unpause();
    }


    // --- Internal ERC-721 Overrides ---

    // Override _transfer to add custom logic/checks
    // This is called by standard transferFrom, safeTransferFrom, and our transferEntangledPair
    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        // Custom logic: If entangled, this internal transfer should ideally only happen
        // when called by `transferEntangledPair`. However, we allow it if *not* entangled
        // via the overridden external functions. The check in the external functions
        // is sufficient to prevent transferring only one entangled token via standard means.

        super._transfer(from, to, tokenId);

        // Note: approvals are cleared in super._transfer
    }

    // Override _update to potentially add logic on token lifecycle changes (mint/transfer/burn)
    // Not strictly necessary for this design, but good to know it's available
    // function _update(address to, uint256 tokenId, address auth) internal virtual override returns (address) {
    //     return super._update(to, tokenId, auth);
    // }

    // Override _safeMint to potentially add pre/post-mint logic
    function _safeMint(address to, uint256 tokenId) internal virtual override {
        super._safeMint(to, tokenId);
        // Could initialize state here if desired, but we do it in mintEntangledPair
    }

    // Override _burn to add pre/post-burn logic
    function _burn(uint256 tokenId) internal virtual override {
         // Ensure entanglement state is cleared before burning if burn is called directly
        if (_entangledPartner[tokenId] != 0) {
             uint256 partnerId = _entangledPartner[tokenId];
             // This should only happen if burnPair is called or logic is modified.
             // Standard burn is blocked by the override modifier.
             _entangledPartner[tokenId] = 0;
             _entangledPartner[partnerId] = 0;
             emit EntanglementBroken(_tokenPairId[tokenId], tokenId, partnerId);
        }
         super._burn(tokenId);
         // Clean up other state mappings after burning
         delete _tokenPairId[tokenId];
         delete _mintTimestamp[tokenId];
         delete _decoherenceTimestamp[tokenId];
         delete _interactionCount[tokenId];
         delete _potentialSuperpositionValue[tokenId];
         delete _currentMeasuredValue[tokenId];
         delete _isSuperpositionMeasured[tokenId];
    }

}
```