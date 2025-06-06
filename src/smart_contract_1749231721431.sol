Okay, let's design a smart contract around the concept of "Quantum State NFTs". These NFTs will represent theoretical quantum particles or systems. Their properties (metadata) will be dynamic and influenced by external "oracle" input (simulated here by a privileged address calling a function) and internal "entropy" that accrues over time or with interactions. The core idea is a dynamic state that can eventually "collapse" into a final, immutable state, determining the NFT's ultimate form and rarity.

We will use OpenZeppelin contracts as a base (ERC721, Ownable, ERC721URIStorage, ERC721Enumerable) but add significant custom logic for the state, entropy, oracle interaction, and dynamic metadata. The custom logic will be the core "interesting, advanced, creative" part.

**Concept:** Quantum Oracle NFTs
**Theme:** Each NFT represents a theoretical quantum entity. Its state changes dynamically based on time (entropy) and external "quantum fluctuation" data provided by an oracle. Owners can make "predictions" about the final state before it collapses. The state eventually "collapses" into a final, immutable form.
**Advanced Concepts:**
1.  **Dynamic State:** NFT properties are not fixed at mint.
2.  **Time-Based Entropy:** A property (entropy) increases over time.
3.  **Oracle Interaction:** External data influences internal state/entropy.
4.  **State Transition Logic:** Rules for how entropy and oracle data cause state changes or collapse.
5.  **Prediction Mechanism:** Owners can record a prediction about the future state.
6.  **State Collapse:** A mechanism to finalize the NFT's state.
7.  **Dynamic Metadata:** The `tokenURI` reflects the current dynamic state before collapse and the final state after.
8.  **Entanglement (Simplified):** Pairs of tokens could potentially be linked, where an action on one might influence the other (though this makes the function count and complexity explode, let's keep it to individual tokens for now, but the *theme* allows for future expansion). We can add a placeholder for entanglement data.

---

**Outline and Function Summary**

**Contract Name:** `QuantumOracleNFT`

**Inherits:**
*   `ERC721URIStorage`: Standard NFT with support for per-token URI.
*   `ERC721Enumerable`: Allows iterating token IDs for a user or globally.
*   `Ownable`: Provides a contract owner role for administrative functions.
*   `Base64` (Helper Library): Used for encoding dynamic JSON metadata in `tokenURI`.

**State Variables:**
*   `_nextTokenId`: Counter for minted tokens.
*   `_oracleAddress`: Address allowed to provide oracle data.
*   `_baseEntropyRatePerSecond`: Rate at which entropy increases per second.
*   `_collapseEntropyThreshold`: Entropy level required for potential state collapse.
*   `_entropyOracleInfluenceFactor`: How much oracle data impacts entropy.
*   `_metadataBaseURI`: Base URI for external metadata service (optional, for non-dynamic parts).
*   `_collapsedMetadataURI`: URI prefix for metadata after collapse.
*   `_tokenData`: Mapping from `tokenId` to `TokenData` struct.

**Structs:**
*   `TokenData`: Stores specific data for each token:
    *   `state`: Current `QuantumState` enum value.
    *   `entropy`: Accumulated entropy level.
    *   `lastEntropyUpdateTime`: Timestamp when entropy was last explicitly updated/calculated.
    *   `collapseTimestamp`: Timestamp when state was collapsed (0 if not collapsed).
    *   `entangledTokenId`: Placeholder for potential future entanglement feature.
    *   `predictionValue`: Stored prediction made by the owner.
    *   `hasPredicted`: Flag indicating if a prediction is active.

**Enums:**
*   `QuantumState`: Defines possible states (e.g., `Superposition`, `FluctuatingA`, `FluctuatingB`, `Collapsed`).

**Events:**
*   `Minted(uint256 tokenId, address recipient)`
*   `OracleDataUpdated(uint256 tokenId, uint256 oracleValue, uint256 newEntropy)`
*   `StateChanged(uint256 tokenId, QuantumState oldState, QuantumState newState)`
*   `StateCollapsed(uint256 tokenId, QuantumState finalState, uint64 collapseTimestamp)`
*   `PredictionMade(uint256 tokenId, uint256 predictionValue)`
*   `PredictionCleared(uint256 tokenId)`

**Functions (20+ minimum):**

**Standard ERC721 / Overrides:**
1.  `constructor()`: Initializes the contract, sets base URI, oracle address.
2.  `name()`: Returns contract name (inherited).
3.  `symbol()`: Returns contract symbol (inherited).
4.  `totalSupply()`: Returns total number of tokens minted (inherited).
5.  `balanceOf(address owner)`: Returns owner's token count (inherited).
6.  `ownerOf(uint256 tokenId)`: Returns owner of token (inherited).
7.  `getApproved(uint256 tokenId)`: Returns approved address (inherited).
8.  `isApprovedForAll(address owner, address operator)`: Checks operator approval (inherited).
9.  `approve(address to, uint256 tokenId)`: Approves address for token (inherited).
10. `setApprovalForAll(address operator, bool approved)`: Sets operator approval (inherited).
11. `transferFrom(address from, address to, uint256 tokenId)`: Transfers token (inherited - overridden to add checks).
12. `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer (inherited - overridden to add checks).
13. `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer with data (inherited - overridden to add checks).
14. `tokenOfOwnerByIndex(address owner, uint256 index)`: Returns token by owner index (inherited from Enumerable).
15. `tokenByIndex(uint256 index)`: Returns token by global index (inherited from Enumerable).
16. `tokenURI(uint256 tokenId)`: **Override.** Returns dynamic or static metadata URI based on token state.

**Core Logic / Custom Functions:**
17. `mint(address to)`: Mints a new token with initial state and parameters. `onlyOwner`.
18. `getQuantumState(uint256 tokenId)`: Returns the current `QuantumState` of a token.
19. `getCurrentEntropy(uint256 tokenId)`: Calculates and returns the *current* entropy, including time-based accrual.
20. `getLastEntropyUpdateTime(uint256 tokenId)`: Returns the timestamp of the last explicit entropy calculation/update.
21. `getEntangledTokenId(uint256 tokenId)`: Returns the stored entangled token ID (placeholder).
22. `updateOracleData(uint256 tokenId, uint256 oracleValue)`: Called by `_oracleAddress`. Uses `oracleValue` to influence the token's entropy and potentially trigger state transitions.
23. `predictState(uint256 tokenId, uint256 predictionValue)`: Allows token owner to record a prediction value. Can only be called if the token is in a non-collapsed state and hasn't predicted yet.
24. `clearPrediction(uint256 tokenId)`: Allows token owner to clear their active prediction. Can only be called if the token is in a non-collapsed state and has a prediction.
25. `checkPredictionOutcome(uint256 tokenId)`: **View.** Checks if the stored prediction value matches a criteria based on the *collapsed* state or final entropy. (Needs logic tied to collapse).
26. `triggerCollapse(uint256 tokenId)`: Allows token owner or anyone (if entropy threshold met) to attempt to collapse the state. Finalizes state and entropy.
27. `getStateDescription(QuantumState state)`: **Pure.** Helper to get a human-readable string for a state. Used in metadata.
28. `setOracleAddress(address newOracleAddress)`: Sets the address authorized to call `updateOracleData`. `onlyOwner`.
29. `setEntropyParameters(uint256 _baseRatePerSecond, uint256 _collapseThreshold, uint256 _oracleInfluenceFactor)`: Sets the parameters governing entropy accrual and oracle impact. `onlyOwner`.
30. `setMetadataURIs(string memory _base, string memory _collapsed)`: Sets the base URIs for dynamic and collapsed metadata. `onlyOwner`.
31. `isCollapsed(uint256 tokenId)`: **View.** Checks if a token's state is `Collapsed`.
32. `getCollapseTimestamp(uint256 tokenId)`: Returns the timestamp when the token collapsed.
33. `getTokenData(uint256 tokenId)`: **View.** Returns the full `TokenData` struct for a token.
34. `calculateDynamicEntropy(uint256 tokenId)`: **Internal View.** Calculates the entropy including accrual since the last update.
35. `_applyOracleInfluence(uint256 tokenId, uint256 oracleValue)`: **Internal.** Applies oracle influence to entropy and handles potential state changes based on rules.
36. `_triggerCollapseLogic(uint256 tokenId)`: **Internal.** Handles the logic for state collapse, setting the final state, and updating the struct.
37. `canTriggerCollapse(uint256 tokenId)`: **View.** Checks if a token currently meets the conditions (e.g., entropy threshold) for manual collapse.
38. `_generateDynamicMetadata(uint256 tokenId)`: **Internal View.** Generates the Base64 encoded JSON metadata for a non-collapsed token.
39. `_generateCollapsedMetadata(uint256 tokenId)`: **Internal View.** Generates the Base64 encoded JSON metadata for a collapsed token.
40. `getPrediction(uint256 tokenId)`: **View.** Returns the stored prediction value.
41. `hasPredicted(uint256 tokenId)`: **View.** Checks if a prediction is active for the token.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Outline and Function Summary:

// Contract Name: QuantumOracleNFT

// Concept: Each NFT represents a theoretical quantum entity. Its state changes dynamically based on time (entropy) and external "quantum fluctuation" data provided by an oracle.
// Owners can make "predictions" about the final state before it collapses. The state eventually "collapses" into a final, immutable form.

// Inherits:
// - ERC721URIStorage: Standard NFT with support for per-token URI.
// - ERC721Enumerable: Allows iterating token IDs for a user or globally.
// - Ownable: Provides a contract owner role for administrative functions.
// - Base64 (Helper Library): Used for encoding dynamic JSON metadata in tokenURI.

// State Variables:
// - _nextTokenId: Counter for minted tokens.
// - _oracleAddress: Address allowed to provide oracle data.
// - _baseEntropyRatePerSecond: Rate at which entropy increases per second.
// - _collapseEntropyThreshold: Entropy level required for potential state collapse.
// - _entropyOracleInfluenceFactor: How much oracle data impacts entropy.
// - _metadataBaseURI: Base URI for external metadata service (optional, for non-dynamic parts).
// - _collapsedMetadataURI: URI prefix for metadata after collapse.
// - _tokenData: Mapping from tokenId to TokenData struct.

// Structs:
// - TokenData: Stores specific data for each token:
//     - state: Current QuantumState enum value.
//     - entropy: Accumulated entropy level.
//     - lastEntropyUpdateTime: Timestamp when entropy was last explicitly updated/calculated.
//     - collapseTimestamp: Timestamp when state was collapsed (0 if not collapsed).
//     - entangledTokenId: Placeholder for potential future entanglement feature (set to 0 if none).
//     - predictionValue: Stored prediction made by the owner (0 if none).
//     - hasPredicted: Flag indicating if a prediction is active.

// Enums:
// - QuantumState: Defines possible states (e.g., Superposition, FluctuatingA, FluctuatingB, Collapsed).

// Events:
// - Minted(uint256 tokenId, address recipient)
// - OracleDataUpdated(uint256 tokenId, uint256 oracleValue, uint256 newEntropy)
// - StateChanged(uint256 tokenId, QuantumState oldState, QuantumState newState)
// - StateCollapsed(uint256 tokenId, QuantumState finalState, uint64 collapseTimestamp)
// - PredictionMade(uint256 tokenId, uint256 predictionValue)
// - PredictionCleared(uint256 tokenId)

// Functions (20+):

// Standard ERC721 / Overrides:
// 1. constructor()
// 2. name() (inherited)
// 3. symbol() (inherited)
// 4. totalSupply() (inherited)
// 5. balanceOf(address owner) (inherited)
// 6. ownerOf(uint256 tokenId) (inherited)
// 7. getApproved(uint256 tokenId) (inherited)
// 8. isApprovedForAll(address owner, address operator) (inherited)
// 9. approve(address to, uint256 tokenId) (inherited)
// 10. setApprovalForAll(address operator, bool approved) (inherited)
// 11. transferFrom(address from, address to, uint256 tokenId) (overridden)
// 12. safeTransferFrom(address from, address to, uint256 tokenId) (overridden)
// 13. safeTransferFrom(address from, address to, uint256 tokenId, bytes data) (overridden)
// 14. tokenOfOwnerByIndex(address owner, uint256 index) (inherited)
// 15. tokenByIndex(uint256 index) (inherited)
// 16. tokenURI(uint256 tokenId) (override - dynamic/static metadata)

// Core Logic / Custom Functions:
// 17. mint(address to)
// 18. getQuantumState(uint256 tokenId)
// 19. getCurrentEntropy(uint256 tokenId)
// 20. getLastEntropyUpdateTime(uint256 tokenId)
// 21. getEntangledTokenId(uint256 tokenId)
// 22. updateOracleData(uint256 tokenId, uint256 oracleValue)
// 23. predictState(uint256 tokenId, uint256 predictionValue)
// 24. clearPrediction(uint256 tokenId)
// 25. checkPredictionOutcome(uint256 tokenId) (view)
// 26. triggerCollapse(uint256 tokenId)
// 27. getStateDescription(QuantumState state) (pure)
// 28. setOracleAddress(address newOracleAddress)
// 29. setEntropyParameters(uint256 _baseRatePerSecond, uint256 _collapseThreshold, uint256 _oracleInfluenceFactor)
// 30. setMetadataURIs(string memory _base, string memory _collapsed)
// 31. isCollapsed(uint256 tokenId) (view)
// 32. getCollapseTimestamp(uint256 tokenId) (view)
// 33. getTokenData(uint256 tokenId) (view)
// 34. calculateDynamicEntropy(uint256 tokenId) (internal view)
// 35. _applyOracleInfluence(uint256 tokenId, uint256 oracleValue) (internal)
// 36. _triggerCollapseLogic(uint256 tokenId) (internal)
// 37. canTriggerCollapse(uint256 tokenId) (view)
// 38. _generateDynamicMetadata(uint256 tokenId) (internal view)
// 39. _generateCollapsedMetadata(uint256 tokenId) (internal view)
// 40. getPrediction(uint256 tokenId) (view)
// 41. hasPredicted(uint256 tokenId) (view)

contract QuantumOracleNFT is ERC721URIStorage, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _nextTokenId;

    address private _oracleAddress;

    uint256 private _baseEntropyRatePerSecond; // Entropy increase per second
    uint256 private _collapseEntropyThreshold; // Entropy required to potentially trigger collapse
    uint256 private _entropyOracleInfluenceFactor; // Factor for oracle value influencing entropy

    string private _metadataBaseURI; // Base URI for external metadata (can be gateway like IPFS)
    string private _collapsedMetadataURI; // Base URI for collapsed state metadata

    enum QuantumState {
        Superposition, // Initial dynamic state
        FluctuatingA, // Dynamic state A, influenced by oracle/entropy
        FluctuatingB, // Dynamic state B, influenced by oracle/entropy
        Collapsed // Final, immutable state
    }

    struct TokenData {
        QuantumState state;
        uint256 entropy; // Accumulated entropy value
        uint64 lastEntropyUpdateTime; // Timestamp of the last entropy calculation/update
        uint64 collapseTimestamp; // Timestamp when state was collapsed (0 if not collapsed)
        uint256 entangledTokenId; // Placeholder for potential entanglement (0 if none)
        uint256 predictionValue; // Value predicted by owner (0 if none)
        bool hasPredicted; // True if owner has made a prediction
    }

    mapping(uint256 => TokenData) private _tokenData;

    event Minted(uint256 tokenId, address recipient);
    event OracleDataUpdated(uint256 tokenId, uint256 oracleValue, uint256 newEntropy);
    event StateChanged(uint256 tokenId, QuantumState oldState, QuantumState newState);
    event StateCollapsed(uint256 tokenId, QuantumState finalState, uint64 collapseTimestamp);
    event PredictionMade(uint256 tokenId, uint256 predictionValue);
    event PredictionCleared(uint256 tokenId);

    constructor(
        string memory name_,
        string memory symbol_,
        address oracleAddress_,
        uint256 baseEntropyRatePerSecond_,
        uint256 collapseEntropyThreshold_,
        uint256 entropyOracleInfluenceFactor_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        require(oracleAddress_ != address(0), "Invalid oracle address");
        _oracleAddress = oracleAddress_;
        _baseEntropyRatePerSecond = baseEntropyRatePerSecond_;
        _collapseEntropyThreshold = collapseEntropyThreshold_;
        _entropyOracleInfluenceFactor = entropyOracleInfluenceFactor_;
        // Default URIs can be set later via setMetadataURIs
    }

    // --- ERC721 Overrides ---

    // 11. transferFrom(address from, address to, uint256 tokenId)
    // 12. safeTransferFrom(address from, address to, uint256 tokenId)
    // 13. safeTransferFrom(address from, address to, uint256 tokenId, bytes data)
    // Override transfer functions to prevent transfers if a prediction is active
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (from != address(0) && _tokenData[tokenId].hasPredicted) {
             revert("Cannot transfer token while prediction is active");
        }
    }

    // The following functions are inherited from ERC721Enumerable and ERC721URIStorage:
    // name(), symbol(), totalSupply(), balanceOf(), ownerOf(), getApproved(), isApprovedForAll(),
    // approve(), setApprovalForAll(), tokenOfOwnerByIndex(), tokenByIndex()
    // No need to list them explicitly here unless overridden.

    // 16. tokenURI(uint256 tokenId) - Override to handle dynamic metadata
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists

        if (_tokenData[tokenId].state == QuantumState.Collapsed) {
            // Use collapsed URI if state is collapsed
             if (bytes(_collapsedMetadataURI).length == 0) {
                return ""; // Or return a default error/placeholder URI
            }
            return string(abi.encodePacked(_collapsedMetadataURI, Strings.toString(tokenId)));
        } else {
            // Generate dynamic metadata if not collapsed
            return string(abi.encodePacked("data:application/json;base64,", Base64.encode(_generateDynamicMetadata(tokenId))));
        }
    }

    // --- Core Logic / Custom Functions ---

    // 17. mint(address to)
    function mint(address to) public onlyOwner returns (uint256) {
        _nextTokenId.increment();
        uint256 newTokenId = _nextTokenId.current();

        _safeMint(to, newTokenId);

        // Initialize token data
        _tokenData[newTokenId] = TokenData({
            state: QuantumState.Superposition,
            entropy: 0,
            lastEntropyUpdateTime: uint64(block.timestamp),
            collapseTimestamp: 0,
            entangledTokenId: 0, // Default: no entanglement
            predictionValue: 0, // Default: no prediction
            hasPredicted: false // Default: no prediction
        });

        emit Minted(newTokenId, to);

        return newTokenId;
    }

    // 18. getQuantumState(uint256 tokenId)
    function getQuantumState(uint256 tokenId) public view returns (QuantumState) {
         _requireOwned(tokenId);
        return _tokenData[tokenId].state;
    }

    // 19. getCurrentEntropy(uint256 tokenId)
    // Calculates entropy including accrual since last update
    function getCurrentEntropy(uint256 tokenId) public view returns (uint256) {
         _requireOwned(tokenId);
        return calculateDynamicEntropy(tokenId);
    }

    // 20. getLastEntropyUpdateTime(uint256 tokenId)
    function getLastEntropyUpdateTime(uint256 tokenId) public view returns (uint64) {
         _requireOwned(tokenId);
        return _tokenData[tokenId].lastEntropyUpdateTime;
    }

    // 21. getEntangledTokenId(uint256 tokenId)
    function getEntangledTokenId(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId);
        return _tokenData[tokenId].entangledTokenId;
    }

    // 22. updateOracleData(uint256 tokenId, uint256 oracleValue)
    // Called by the designated oracle address
    function updateOracleData(uint256 tokenId, uint256 oracleValue) public {
        require(msg.sender == _oracleAddress, "Only oracle can update data");
        _requireOwned(tokenId);
        TokenData storage token = _tokenData[tokenId];
        require(token.state != QuantumState.Collapsed, "Token state is already collapsed");

        // Apply time-based entropy accrual before applying oracle influence
        token.entropy = calculateDynamicEntropy(tokenId);
        token.lastEntropyUpdateTime = uint64(block.timestamp);

        // Apply oracle influence and trigger state changes
        _applyOracleInfluence(tokenId, oracleValue);

        emit OracleDataUpdated(tokenId, oracleValue, token.entropy);
    }

    // 23. predictState(uint256 tokenId, uint256 predictionValue)
    function predictState(uint256 tokenId, uint256 predictionValue) public {
        require(msg.sender == ownerOf(tokenId), "Only token owner can predict");
        TokenData storage token = _tokenData[tokenId];
        require(token.state != QuantumState.Collapsed, "Cannot predict on a collapsed token");
        require(!token.hasPredicted, "Prediction already made for this token");

        token.predictionValue = predictionValue;
        token.hasPredicted = true;

        emit PredictionMade(tokenId, predictionValue);
    }

    // 24. clearPrediction(uint256 tokenId)
    function clearPrediction(uint256 tokenId) public {
        require(msg.sender == ownerOf(tokenId), "Only token owner can clear prediction");
        TokenData storage token = _tokenData[tokenId];
        require(token.hasPredicted, "No active prediction to clear");

        token.predictionValue = 0;
        token.hasPredicted = false;

        emit PredictionCleared(tokenId);
    }

    // 25. checkPredictionOutcome(uint256 tokenId)
    // Example prediction logic: Predict if final entropy will be odd/even based on predictionValue 0/1
    function checkPredictionOutcome(uint256 tokenId) public view returns (bool) {
         _requireOwned(tokenId);
        TokenData storage token = _tokenData[tokenId];
        require(token.state == QuantumState.Collapsed, "Prediction outcome only available after collapse");
        require(token.hasPredicted, "No prediction was made for this token");

        // Example logic: PredictionValue 0 = predict final entropy is even, 1 = predict final entropy is odd
        // Add more complex prediction outcomes here if needed
        if (token.predictionValue == 0) {
            return token.entropy % 2 == 0;
        } else if (token.predictionValue == 1) {
            return token.entropy % 2 != 0;
        }
        // Add more cases if predictionValue has other meanings
        return false; // Default false for unknown prediction values
    }

    // 26. triggerCollapse(uint256 tokenId)
    function triggerCollapse(uint256 tokenId) public {
        _requireOwned(tokenId); // Only owner or approved can trigger, but check ownership first
        TokenData storage token = _tokenData[tokenId];
        require(token.state != QuantumState.Collapsed, "Token state is already collapsed");
        require(canTriggerCollapse(tokenId) || msg.sender == ownerOf(tokenId), "Conditions for collapse not met or not owner");
        // Allow owner to force collapse if conditions met, or if specifically allowed regardless of threshold?
        // Current logic allows owner if conditions met, or anyone if entropy very high? Let's require owner approval if not past a *very* high threshold.
        // Let's simplify: Only owner can trigger collapse, provided minimum entropy threshold is met.
        require(msg.sender == ownerOf(tokenId), "Only token owner can trigger collapse");
        require(calculateDynamicEntropy(tokenId) >= _collapseEntropyThreshold, "Entropy threshold not met for collapse");


        _triggerCollapseLogic(tokenId);
    }

    // 27. getStateDescription(QuantumState state)
    function getStateDescription(QuantumState state) public pure returns (string memory) {
        if (state == QuantumState.Superposition) return "Superposition";
        if (state == QuantumState.FluctuatingA) return "Fluctuating A";
        if (state == QuantumState.FluctuatingB) return "Fluctuating B";
        if (state == QuantumState.Collapsed) return "Collapsed";
        return "Unknown";
    }

    // 28. setOracleAddress(address newOracleAddress)
    function setOracleAddress(address newOracleAddress) public onlyOwner {
        require(newOracleAddress != address(0), "Invalid oracle address");
        _oracleAddress = newOracleAddress;
    }

    // 29. setEntropyParameters(uint256 _baseRatePerSecond, uint256 _collapseThreshold, uint256 _oracleInfluenceFactor)
    function setEntropyParameters(
        uint256 baseRatePerSecond_,
        uint256 collapseThreshold_,
        uint256 oracleInfluenceFactor_
    ) public onlyOwner {
        _baseEntropyRatePerSecond = baseRatePerSecond_;
        _collapseEntropyThreshold = collapseThreshold_;
        _entropyOracleInfluenceFactor = oracleInfluenceFactor_;
    }

    // 30. setMetadataURIs(string memory _base, string memory _collapsed)
    function setMetadataURIs(string memory baseURI_, string memory collapsedURI_) public onlyOwner {
        _metadataBaseURI = baseURI_;
        _collapsedMetadataURI = collapsedURI_;
    }

    // 31. isCollapsed(uint256 tokenId)
    function isCollapsed(uint256 tokenId) public view returns (bool) {
         _requireOwned(tokenId);
        return _tokenData[tokenId].state == QuantumState.Collapsed;
    }

    // 32. getCollapseTimestamp(uint256 tokenId)
    function getCollapseTimestamp(uint256 tokenId) public view returns (uint64) {
         _requireOwned(tokenId);
        return _tokenData[tokenId].collapseTimestamp;
    }

    // 33. getTokenData(uint256 tokenId)
    function getTokenData(uint256 tokenId) public view returns (TokenData memory) {
         _requireOwned(tokenId);
        // Return a copy to avoid state modification via view function
        TokenData storage token = _tokenData[tokenId];
         return TokenData({
            state: token.state,
            entropy: calculateDynamicEntropy(tokenId), // Return dynamic entropy
            lastEntropyUpdateTime: token.lastEntropyUpdateTime,
            collapseTimestamp: token.collapseTimestamp,
            entangledTokenId: token.entangledTokenId,
            predictionValue: token.predictionValue,
            hasPredicted: token.hasPredicted
        });
    }


    // --- Internal Helper Functions ---

    // 34. calculateDynamicEntropy(uint256 tokenId)
    // Calculates the current entropy including time-based accrual.
    // Used in view functions or before state-changing operations that depend on current entropy.
    function calculateDynamicEntropy(uint256 tokenId) internal view returns (uint256) {
        TokenData storage token = _tokenData[tokenId];
        if (token.state == QuantumState.Collapsed) {
            // Entropy is fixed after collapse
            return token.entropy;
        } else {
            // Accrue entropy based on time since last update
            uint256 timeElapsed = block.timestamp - token.lastEntropyUpdateTime;
            return token.entropy + (timeElapsed * _baseEntropyRatePerSecond);
        }
    }

     // 35. _applyOracleInfluence(uint256 tokenId, uint256 oracleValue)
     // Internal function to apply oracle influence and trigger state changes.
     // Simplified logic:
     // - Oracle value directly adds to entropy.
     // - High entropy + certain oracle value distribution might cause state transition.
     // - Very high entropy might cause collapse regardless of threshold.
    function _applyOracleInfluence(uint256 tokenId, uint256 oracleValue) internal {
        TokenData storage token = _tokenData[tokenId];
        QuantumState oldState = token.state;

        // Apply influence to entropy
        token.entropy = token.entropy + (oracleValue * _entropyOracleInfluenceFactor) / 100; // Simple scaling

        // Example State Transition Logic (can be complex based on oracleValue, entropy, current state)
        // This is a simplified, creative example. More complex rules could involve modulo, randomness from oracle, etc.
        if (token.state == QuantumState.Superposition) {
            if (oracleValue > 1000 && token.entropy > 500) {
                token.state = QuantumState.FluctuatingA;
            } else if (oracleValue < 500 && token.entropy > 500) {
                 token.state = QuantumState.FluctuatingB;
            } else if (token.entropy > _collapseEntropyThreshold * 2 && oracleValue % 3 == 0) {
                 // Very high entropy + specific oracle pattern can force collapse
                 _triggerCollapseLogic(tokenId);
            }
        } else if (token.state == QuantumState.FluctuatingA) {
            if (oracleValue % 5 == 0 && token.entropy > 700) {
                token.state = QuantumState.FluctuatingB;
            } else if (token.entropy > _collapseEntropyThreshold && oracleValue > 1500) {
                 _triggerCollapseLogic(tokenId);
            }
        } else if (token.state == QuantumState.FluctuatingB) {
             if (oracleValue % 7 == 0 && token.entropy > 700) {
                token.state = QuantumState.FluctuatingA;
            } else if (token.entropy > _collapseEntropyThreshold && oracleValue < 300) {
                 _triggerCollapseLogic(tokenId);
            }
        }

        if (oldState != token.state && token.state != QuantumState.Collapsed) {
             emit StateChanged(tokenId, oldState, token.state);
        }
    }

    // 36. _triggerCollapseLogic(uint256 tokenId)
    // Internal function to finalize the state collapse.
    function _triggerCollapseLogic(uint256 tokenId) internal {
        TokenData storage token = _tokenData[tokenId];
        // Ensure entropy is calculated one last time before collapse
        token.entropy = calculateDynamicEntropy(tokenId);
        token.lastEntropyUpdateTime = uint64(block.timestamp);

        QuantumState finalState;
        // Determine final state based on entropy and perhaps current state/prediction
        // Example Logic:
        if (token.entropy % 2 == 0) {
            finalState = QuantumState.FluctuatingA; // Collapse to A if entropy is even
        } else {
            finalState = QuantumState.FluctuatingB; // Collapse to B if entropy is odd
        }
        // More complex logic could incorporate the prediction value, oracle value history, etc.
        // For simplicity, the Collapsed state itself is just a flag. The final "form" is implied by properties like entropy or which Fluctuating state it was closest to.
        // Let's make the collapsed state one of the Fluctuating states or a new "Stabilized" concept?
        // Let's keep Collapsed as the final state flag, and the "properties" like final entropy determine rarity/visuals.

        token.state = QuantumState.Collapsed;
        token.collapseTimestamp = uint64(block.timestamp);

        emit StateCollapsed(tokenId, token.state, token.collapseTimestamp);

        // Prediction outcome can now be checked
        // (No need to emit here, owner calls checkPredictionOutcome)
    }

    // 37. canTriggerCollapse(uint256 tokenId)
    // Checks if the entropy threshold for manual collapse is met.
    function canTriggerCollapse(uint256 tokenId) public view returns (bool) {
         _requireOwned(tokenId);
        TokenData storage token = _tokenData[tokenId];
        return token.state != QuantumState.Collapsed && calculateDynamicEntropy(tokenId) >= _collapseEntropyThreshold;
    }


    // 38. _generateDynamicMetadata(uint256 tokenId)
    // Generates Base64 encoded JSON for the token's dynamic state metadata.
    function _generateDynamicMetadata(uint256 tokenId) internal view returns (bytes memory) {
        TokenData storage token = _tokenData[tokenId];
        uint256 currentEntropy = calculateDynamicEntropy(tokenId); // Get up-to-date entropy

        // Construct JSON string
        string memory json = string(abi.encodePacked(
            '{"name": "Quantum Particle #', Strings.toString(tokenId),
            '", "description": "A quantum particle in a dynamic state.",',
            '"attributes": [',
            '{"trait_type": "State", "value": "', getStateDescription(token.state), '"},',
            '{"trait_type": "Entropy", "value": ', Strings.toString(currentEntropy), '},',
            '{"trait_type": "Last Entropy Update", "value": ', Strings.toString(token.lastEntropyUpdateTime), '}',
            // Add other dynamic properties here
            ']}'
        ));

        return abi.encodePacked(json);
    }

    // 39. _generateCollapsedMetadata(uint256 tokenId)
    // Generates Base64 encoded JSON for the token's final, collapsed state metadata.
    function _generateCollapsedMetadata(uint256 tokenId) internal view returns (bytes memory) {
        TokenData storage token = _tokenData[tokenId];
        // Use the final entropy stored at collapse
        uint256 finalEntropy = token.entropy;

        // Example: Calculate rarity score based on final entropy (simplified)
        uint256 rarityScore = finalEntropy / 10; // Arbitrary calculation

        string memory json = string(abi.encodePacked(
            '{"name": "Quantum Particle #', Strings.toString(tokenId), ' (Collapsed)',
            '", "description": "A quantum particle whose state has collapsed.",',
            ' "image": "', _collapsedMetadataURI, Strings.toString(tokenId), '/image.png",', // Example image path based on collapsed URI and token ID
            '"attributes": [',
            '{"trait_type": "State", "value": "Collapsed"},', // Redundant but clear
            '{"trait_type": "Final Entropy", "value": ', Strings.toString(finalEntropy), '},',
            '{"trait_type": "Collapse Timestamp", "value": ', Strings.toString(token.collapseTimestamp), '},',
            '{"trait_type": "Rarity Score", "value": ', Strings.toString(rarityScore), '}'
            // Add other final properties here
            ']}'
        ));

        return abi.encodePacked(json);
    }

    // 40. getPrediction(uint256 tokenId)
    function getPrediction(uint256 tokenId) public view returns (uint256) {
         _requireOwned(tokenId);
        return _tokenData[tokenId].predictionValue;
    }

    // 41. hasPredicted(uint256 tokenId)
    function hasPredicted(uint256 tokenId) public view returns (bool) {
         _requireOwned(tokenId);
        return _tokenData[tokenId].hasPredicted;
    }

    // Helper to ensure token exists before fetching data (inherited from ERC721)
    // function _requireOwned(uint256 tokenId) internal view {
    //    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    // }


    // The following functions are overrides required by Solidity.
    function _update(address to, uint256 tokenId, uint256 auth)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._update(to, tokenId, auth);
    }

    function _increaseBalance(address owner, uint256 amount)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(owner, amount);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```