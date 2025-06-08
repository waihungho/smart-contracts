Okay, here is a Solidity smart contract for a "Dynamic AI Oracle NFT" (DAIONFT). This contract combines several advanced concepts:

1.  **ERC721 Standard:** It's an NFT.
2.  **Dynamic NFTs (DNFTs):** The NFT's metadata and traits can change over time.
3.  **Oracle Integration:** Changes are driven by data received from an external oracle (simulating an AI service).
4.  **State Management:** The contract maintains complex on-chain state for each NFT, representing its "evolution" or current attributes.
5.  **Fee Mechanism:** Users pay a fee to request AI updates for their NFT.
6.  **Access Control:** Uses `Ownable` for administrative functions and checks the oracle's identity for updates.
7.  **DataURI Metadata:** `tokenURI` generates metadata on-the-fly using a data URI, allowing the on-chain state to directly influence off-chain representation without needing a separate metadata server (though it can be linked to one).
8.  **Evolution/Generation Logic:** Includes a concept of the NFT "evolving" or undergoing generations based on AI updates.

It's designed to be creative by having the NFT's characteristics potentially evolve based on simulated AI analysis delivered via an oracle.

---

### Smart Contract Outline:

*   **Contract Name:** `DynamicAIOracleNFT`
*   **Inherits:** `ERC721`, `Ownable`
*   **Dependencies:** `@openzeppelin/contracts/token/ERC721/ERC721.sol`, `@openzeppelin/contracts/access/Ownable.sol`, `@openzeppelin/contracts/utils/Base64.sol`
*   **Interfaces:** `IAIOracle` (defines the expected interface for the AI oracle contract)
*   **Data Structures:**
    *   `NFTState`: Struct to hold the mutable state of each token (description, image URL hint, evolution level, traits mapping).
*   **State Variables:**
    *   `_tokenStates`: Mapping from `tokenId` to `NFTState`.
    *   `_oracleAddress`: Address of the trusted AI Oracle contract.
    *   `_aiRequestFee`: Fee required to request an AI update.
    *   `_pendingUpdateRequests`: Mapping from oracle `requestId` to `tokenId` to track pending requests.
    *   `_paused`: Boolean to pause AI update requests.
    *   `_totalFeesCollected`: Total fees accumulated.
    *   `_maxEvolutionLevel`: Optional cap on evolution.
    *   `_baseMetadataURI`: Optional base URI if not using data URIs directly.
*   **Events:**
    *   `NFTStateUpdated`: Emitted when an NFT's state changes (via oracle).
    *   `AIUpdateRequestSent`: Emitted when a user requests an AI update for their token.
    *   `AIUpdateReceived`: Emitted when the oracle fulfills an update request.
    *   `OracleAddressUpdated`: Emitted when the oracle address is changed.
    *   `AIRequestFeeUpdated`: Emitted when the request fee is changed.
    *   `UpdatesPaused`: Emitted when updates are paused.
    *   `UpdatesResumed`: Emitted when updates are resumed.
    *   `MaxEvolutionLevelUpdated`: Emitted when the max evolution level is changed.
*   **Functions:** (Grouped by functionality)
    *   **ERC721 Overrides:**
        *   `tokenURI(uint256 tokenId)`: Generates dynamic metadata URI.
        *   `_baseURI()`: Internal helper for `tokenURI`.
        *   `_mint(address to, uint256 tokenId)`: Mints a new token and initializes its state.
    *   **NFT State & Queries:**
        *   `getNFTState(uint256 tokenId)`: View state of a token.
        *   `getEvolutionLevel(uint256 tokenId)`: View evolution level.
        *   `getTrait(uint256 tokenId, string memory traitKey)`: View a specific trait.
    *   **AI Oracle Interaction (User & Oracle):**
        *   `requestAIUpdate(uint256 tokenId)`: User function to request an update via oracle (payable).
        *   `fulfillAIUpdate(bytes32 requestId, tuple data)`: Oracle callback function to deliver AI results and update state. (Needs specific signature based on oracle) -> *Simplified to pass data directly for this example's `simulateOracleResponse`.* Let's define a clear data structure for the oracle response.
        *   `_processOracleResponse(uint256 tokenId, string memory description, string memory imageUrlHint, string[] memory traitKeys, string[] memory traitValues)`: Internal function to apply oracle results.
    *   **Admin Functions (OnlyOwner):**
        *   `setOracleAddress(address newOracle)`: Set the trusted oracle contract address.
        *   `setAIRequestFee(uint256 newFee)`: Set the fee for AI requests.
        *   `withdrawFees()`: Withdraw collected fees.
        *   `pauseAIUpdates()`: Pause user requests for AI updates.
        *   `resumeAIUpdates()`: Resume user requests.
        *   `setMaxEvolutionLevel(uint256 level)`: Set the maximum evolution cap.
        *   `setBaseMetadataURI(string memory uri)`: Set base URI if not using data URI for metadata.
        *   `simulateOracleResponse(uint256 tokenId, string memory description, string memory imageUrlHint, string[] memory traitKeys, string[] memory traitValues)`: *Simulate* an oracle response for a token (for testing/demo).
    *   **Helper/View Functions:**
        *   `isUpdatePaused()`: Check if updates are paused.
        *   `getAIRequestFee()`: Get current request fee.
        *   `getOracleAddress()`: Get oracle address.
        *   `getTotalFeesCollected()`: Get total collected fees.
        *   `getMaxEvolutionLevel()`: Get max evolution level.
        *   `getPendingRequestId(uint256 tokenId)`: Get the pending request ID for a token (if any).
        *   `hasPendingRequest(uint256 tokenId)`: Check if a token has a pending request.
        *   `getPendingTokenId(bytes32 requestId)`: Get the token ID for a given request ID.

*Total Functions:* 24 (including overrides and helper views).

---

### Function Summary:

*   `constructor(string memory name, string memory symbol, address initialOracle)`: Initializes the NFT contract with name, symbol, and an initial oracle address. Sets the owner to the deployer.
*   `tokenURI(uint256 tokenId)`: *Overrides ERC721.* Returns a data URI containing the JSON metadata for the token. The metadata (name, description, image, attributes) is dynamically generated based on the token's current `NFTState`.
*   `_baseURI()`: *Internal helper.* Returns the base part of the `tokenURI` (either an empty string for data URI generation or a user-set base URI).
*   `_mint(address to, uint256 tokenId)`: *Overrides ERC721 internal.* Mints a new token to `to` with `tokenId`. Initializes the `NFTState` for the new token with default values (e.g., evolution 0, basic description/image hint).
*   `getNFTState(uint256 tokenId)`: *View.* Returns the full `NFTState` struct for a given token ID.
*   `getEvolutionLevel(uint256 tokenId)`: *View.* Returns the current evolution level of a specific token.
*   `getTrait(uint256 tokenId, string memory traitKey)`: *View.* Returns the value of a specific trait key for a given token.
*   `requestAIUpdate(uint256 tokenId)`: Allows the *owner* of a token to request an AI analysis/update for their token. Requires sending `aiRequestFee` with the transaction. Calls the external `IAIOracle` contract to initiate the off-chain process. Stores the request ID returned by the oracle and associates it with the `tokenId`.
*   `fulfillAIUpdate(bytes32 requestId, string memory description, string memory imageUrlHint, string[] memory traitKeys, string[] memory traitValues)`: This function is intended to be called *only by the designated oracle contract*. It receives the `requestId` (originally from `requestAIUpdate`) and the AI-generated data. It uses the `requestId` to find the associated `tokenId`, updates the token's `NFTState` using `_processOracleResponse`, increments the evolution level (if within max cap), and emits `NFTStateUpdated` and `AIUpdateReceived` events.
*   `_processOracleResponse(uint256 tokenId, string memory description, string memory imageUrlHint, string[] memory traitKeys, string[] memory traitValues)`: *Internal.* Applies the received oracle data to the token's `NFTState`. Updates description, image hint, and the trait mapping.
*   `setOracleAddress(address newOracle)`: *OnlyOwner.* Sets the address of the trusted AI Oracle contract.
*   `setAIRequestFee(uint256 newFee)`: *OnlyOwner.* Sets the amount of Ether required to call `requestAIUpdate`.
*   `withdrawFees()`: *OnlyOwner.* Withdraws all accumulated fees (`totalFeesCollected`) to the owner's address.
*   `pauseAIUpdates()`: *OnlyOwner.* Pauses the ability for users to call `requestAIUpdate`.
*   `resumeAIUpdates()`: *OnlyOwner.* Resumes the ability for users to call `requestAIUpdate`.
*   `setMaxEvolutionLevel(uint256 level)`: *OnlyOwner.* Sets an optional maximum number of times a token can evolve via AI updates. Set to 0 for no cap.
*   `setBaseMetadataURI(string memory uri)`: *OnlyOwner.* Allows setting a base URI. If set, `tokenURI` will return `_baseMetadataURI + tokenId` instead of generating a data URI.
*   `simulateOracleResponse(uint256 tokenId, string memory description, string memory imageUrlHint, string[] memory traitKeys, string[] memory traitValues)`: *OnlyOwner.* A utility function for testing and demonstration. It bypasses the external oracle call and allows the owner to directly trigger the state update logic as if the oracle had responded. *Use with caution in production.*
*   `isUpdatePaused()`: *View.* Returns true if AI updates are currently paused.
*   `getAIRequestFee()`: *View.* Returns the current fee for requesting an AI update.
*   `getOracleAddress()`: *View.* Returns the address of the current trusted oracle contract.
*   `getTotalFeesCollected()`: *View.* Returns the total amount of Ether collected from AI request fees.
*   `getMaxEvolutionLevel()`: *View.* Returns the configured maximum evolution level.
*   `getPendingRequestId(uint256 tokenId)`: *View.* Returns the oracle `requestId` if a request is pending for the token, or a zero `bytes32` if not.
*   `hasPendingRequest(uint256 tokenId)`: *View.* Returns true if a request is currently pending for the token.
*   `getPendingTokenId(bytes32 requestId)`: *View.* Returns the `tokenId` associated with a given `requestId`, or 0 if no such request is pending.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Smart Contract Outline ---
// Contract Name: DynamicAIOracleNFT
// Inherits: ERC721, Ownable
// Dependencies: @openzeppelin/contracts/token/ERC721/ERC721.sol, @openzeppelin/contracts/access/Ownable.sol, @openzeppelin/contracts/utils/Base64.sol, @openzeppelin/contracts/utils/Strings.sol
// Interfaces: IAIOracle (defines expected interface for the oracle)
// Data Structures:
// - NFTState: Struct holding mutable token state (description, image URL hint, evolution level, traits).
// State Variables:
// - _tokenStates: Mapping from tokenId to NFTState.
// - _oracleAddress: Address of the trusted AI Oracle contract.
// - _aiRequestFee: Fee required to request an AI update.
// - _pendingUpdateRequests: Mapping from oracle requestId to tokenId to track pending requests.
// - _paused: Boolean to pause AI update requests.
// - _totalFeesCollected: Total fees accumulated.
// - _maxEvolutionLevel: Optional cap on evolution.
// - _baseMetadataURI: Optional base URI if not using data URIs directly.
// Events:
// - NFTStateUpdated: Emitted when an NFT's state changes.
// - AIUpdateRequestSent: Emitted when user requests update via oracle.
// - AIUpdateReceived: Emitted when oracle fulfills update request.
// - OracleAddressUpdated: Emitted when oracle address is changed.
// - AIRequestFeeUpdated: Emitted when fee is changed.
// - UpdatesPaused: Emitted when updates are paused.
// - UpdatesResumed: Emitted when updates are resumed.
// - MaxEvolutionLevelUpdated: Emitted when max evolution level is changed.
// Functions: (Grouped by functionality)
// - ERC721 Overrides: tokenURI, _baseURI, _mint
// - NFT State & Queries: getNFTState, getEvolutionLevel, getTrait
// - AI Oracle Interaction (User & Oracle): requestAIUpdate, fulfillAIUpdate (requires specific oracle signature), _processOracleResponse
// - Admin Functions (OnlyOwner): setOracleAddress, setAIRequestFee, withdrawFees, pauseAIUpdates, resumeAIUpdates, setMaxEvolutionLevel, setBaseMetadataURI, simulateOracleResponse (for demo)
// - Helper/View Functions: isUpdatePaused, getAIRequestFee, getOracleAddress, getTotalFeesCollected, getMaxEvolutionLevel, getPendingRequestId, hasPendingRequest, getPendingTokenId

// --- Function Summary ---
// constructor(string memory name, string memory symbol, address initialOracle): Initializes contract with name, symbol, and initial oracle.
// tokenURI(uint256 tokenId): Returns dynamic JSON metadata as a data URI based on NFTState.
// _baseURI(): Internal helper for tokenURI, handles optional baseMetadataURI.
// _mint(address to, uint256 tokenId): Mints token and initializes NFTState.
// getNFTState(uint256 tokenId): View function to get token's full state.
// getEvolutionLevel(uint256 tokenId): View function to get token's evolution level.
// getTrait(uint256 tokenId, string memory traitKey): View function to get a specific trait value.
// requestAIUpdate(uint256 tokenId): User requests AI update for owned token, pays fee, triggers oracle call.
// fulfillAIUpdate(bytes32 requestId, string memory description, string memory imageUrlHint, string[] memory traitKeys, string[] memory traitValues): Callback for oracle to deliver results and update token state. Requires specific signature matching oracle.
// _processOracleResponse(uint256 tokenId, string memory description, string memory imageUrlHint, string[] memory traitKeys, string[] memory traitValues): Internal logic to update NFTState based on oracle data.
// setOracleAddress(address newOracle): OnlyOwner sets the trusted oracle address.
// setAIRequestFee(uint256 newFee): OnlyOwner sets the fee for AI requests.
// withdrawFees(): OnlyOwner withdraws collected fees.
// pauseAIUpdates(): OnlyOwner pauses AI update requests.
// resumeAIUpdates(): OnlyOwner resumes AI update requests.
// setMaxEvolutionLevel(uint256 level): OnlyOwner sets max evolution level (0 for no cap).
// setBaseMetadataURI(string memory uri): OnlyOwner sets optional base URI for metadata.
// simulateOracleResponse(uint256 tokenId, string memory description, string memory imageUrlHint, string[] memory traitKeys, string[] memory traitValues): OnlyOwner simulates oracle response for testing/demo.
// isUpdatePaused(): View function for pause status.
// getAIRequestFee(): View function for current fee.
// getOracleAddress(): View function for oracle address.
// getTotalFeesCollected(): View function for collected fees.
// getMaxEvolutionLevel(): View function for max evolution level.
// getPendingRequestId(uint256 tokenId): View pending request ID for a token.
// hasPendingRequest(uint256 tokenId): View if a token has a pending request.
// getPendingTokenId(bytes32 requestId): View token ID for a pending request ID.

// Note: A real oracle integration (like Chainlink) would require specific libraries and slightly different fulfill signature.
// This contract uses a simplified fulfill signature and a simulation function for demonstration.

interface IAIOracle {
    // Example oracle function - actual signature depends on the oracle service
    // It should take necessary parameters (like tokenId), potentially callback function info,
    // and return a unique requestId.
    function requestData(uint256 tokenId, address callbackContract, bytes4 callbackFunctionSignature) external payable returns (bytes32 requestId);
}

contract DynamicAIOracleNFT is ERC721, Ownable {
    using Strings for uint256;

    struct NFTState {
        string description;
        string imageUrlHint; // A hint or fragment, not necessarily the full URL
        mapping(string => string) traits;
        uint256 evolutionLevel;
        bytes32 currentRequestId; // ID of the pending oracle request, if any
    }

    mapping(uint256 => NFTState) private _tokenStates;

    address private _oracleAddress;
    uint256 private _aiRequestFee;
    mapping(bytes32 => uint256) private _pendingUpdateRequests; // requestId => tokenId
    bool private _paused = false;
    uint256 private _totalFeesCollected = 0;
    uint256 private _maxEvolutionLevel = 0; // 0 means no cap
    string private _baseMetadataURI = ""; // If set, overrides data URI generation

    // Events
    event NFTStateUpdated(uint256 indexed tokenId, uint256 evolutionLevel, string description);
    event AIUpdateRequestSent(uint256 indexed tokenId, address indexed requester, bytes32 requestId);
    event AIUpdateReceived(uint256 indexed tokenId, bytes32 indexed requestId, bool success);
    event OracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event AIRequestFeeUpdated(uint256 oldFee, uint256 newFee);
    event UpdatesPaused();
    event UpdatesResumed();
    event MaxEvolutionLevelUpdated(uint256 oldLevel, uint256 newLevel);

    constructor(string memory name, string memory symbol, address initialOracle) ERC721(name, symbol) Ownable(msg.sender) {
        _oracleAddress = initialOracle;
        _aiRequestFee = 0.01 ether; // Example default fee
        emit OracleAddressUpdated(address(0), initialOracle);
        emit AIRequestFeeUpdated(0, _aiRequestFee);
    }

    // --- ERC721 Overrides ---

    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }

        if (bytes(_baseMetadataURI).length > 0) {
            return string(abi.encodePacked(_baseMetadataURI, tokenId.toString()));
        }

        // Generate Data URI Metadata On-The-Fly
        NFTState storage state = _tokenStates[tokenId];

        // Construct attributes array from traits mapping
        string memory attributesJson = "[";
        bool firstTrait = true;
        // Iterating mappings directly is not possible. A helper mapping or array of keys would be needed
        // in a real complex scenario. For this example, let's assume we have known keys
        // or simulate attributes construction. A more robust solution would store traits
        // in a dynamic array of structs {key, value} within NFTState.
        // Let's add some placeholder attributes derived from state for simplicity here.

        string memory description = state.description;
        string memory imageUrl = state.imageUrlHint; // Use hint as image field

        // Simple example attributes
        attributesJson = string(abi.encodePacked(attributesJson, '{ "trait_type": "Evolution Level", "value": "', state.evolutionLevel.toString(), '" }'));
        firstTrait = false;

        // If we had a way to iterate traits mapping, we'd add them here:
        // for (trait in state.traits) {
        //     if (!firstTrait) { attributesJson = string(abi.encodePacked(attributesJson, ",")); }
        //     attributesJson = string(abi.encodePacked(attributesJson, '{ "trait_type": "', trait.key, '", "value": "', trait.value, '" }'));
        //     firstTrait = false;
        // }
         // For demonstration, let's add a fixed trait or two if they exist.
         // This requires knowing trait keys beforehand or structuring `NFTState` differently.
         // Example: check for "Mood" trait if added via oracle simulation
         string memory moodTrait = state.traits["Mood"];
         if (bytes(moodTrait).length > 0) {
             if (!firstTrait) { attributesJson = string(abi.encodePacked(attributesJson, ",")); }
             attributesJson = string(abi.encodePacked(attributesJson, '{ "trait_type": "Mood", "value": "', moodTrait, '" }'));
             firstTrait = false;
         }


        attributesJson = string(abi.encodePacked(attributesJson, "]"));

        // Construct full JSON string
        string memory json = string(abi.encodePacked(
            '{',
            '"name": "', name(), " #", tokenId.toString(), '",',
            '"description": "', description, '",',
            '"image": "', imageUrl, '",',
            '"attributes": ', attributesJson,
            '}'
        ));

        string memory base64Json = Base64.encode(bytes(json));
        return string(abi.encodePacked("data:application/json;base64,", base64Json));
    }

    /// @dev See {ERC721-_baseURI}.
    function _baseURI() internal view override returns (string memory) {
        return _baseMetadataURI;
    }

    /// @dev Mints a new token and initializes its state.
    function _mint(address to, uint256 tokenId) internal override {
        super._mint(to, tokenId);
        NFTState storage state = _tokenStates[tokenId];
        // Initialize with default state
        state.description = "A newly born AI Entity NFT.";
        state.imageUrlHint = "ipfs://QmT.../initial.png"; // Placeholder image hint
        state.evolutionLevel = 0;
        // No pending request initially
    }

    // --- NFT State & Queries ---

    /// @dev Returns the full state struct for a given token.
    /// @param tokenId The ID of the token.
    /// @return The NFTState struct.
    function getNFTState(uint256 tokenId) public view returns (NFTState memory) {
         if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }
        // Note: Mapping within struct cannot be returned directly.
        // Need to manually copy or provide separate trait access.
        NFTState storage state = _tokenStates[tokenId];
        // Create a temporary struct for return, copying only non-mapping fields
        return NFTState({
            description: state.description,
            imageUrlHint: state.imageUrlHint,
            traits: state.traits, // This will likely be empty or error if returned directly in some contexts.
                                  // Best practice is separate trait accessors.
            evolutionLevel: state.evolutionLevel,
            currentRequestId: state.currentRequestId
        });
        // For practical return of traits, you'd need to store keys or return an array of pairs.
    }

    /// @dev Returns the evolution level of a token.
    /// @param tokenId The ID of the token.
    /// @return The evolution level.
    function getEvolutionLevel(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }
        return _tokenStates[tokenId].evolutionLevel;
    }

     /// @dev Returns the value of a specific trait for a token.
     /// @param tokenId The ID of the token.
     /// @param traitKey The key of the trait.
     /// @return The trait value.
    function getTrait(uint256 tokenId, string memory traitKey) public view returns (string memory) {
         if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }
        return _tokenStates[tokenId].traits[traitKey];
    }


    // --- AI Oracle Interaction ---

    /// @dev Allows the token owner to request an AI update via the oracle.
    /// @param tokenId The ID of the token to update.
    function requestAIUpdate(uint256 tokenId) public payable whenNotPaused {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "Not token owner");
        require(_oracleAddress != address(0), "Oracle address not set");
        require(msg.value >= _aiRequestFee, "Insufficient fee");
        require(_tokenStates[tokenId].currentRequestId == bytes32(0), "Pending update request exists");

        _totalFeesCollected += msg.value;

        // Check if max evolution level is reached (if cap is set)
        if (_maxEvolutionLevel > 0 && _tokenStates[tokenId].evolutionLevel >= _maxEvolutionLevel) {
            revert("Max evolution level reached");
        }

        // Interact with the oracle contract
        // The callback signature needs to match the fulfill function expected by the oracle system
        // For a simple example, let's assume the oracle takes tokenId and a function signature to call back
        bytes32 requestId = IAIOracle(_oracleAddress).requestData{value: msg.value}(
             tokenId,
             address(this),
             this.fulfillAIUpdate.selector // Or the selector of a specific fulfill function
         );

        _tokenStates[tokenId].currentRequestId = requestId;
        _pendingUpdateRequests[requestId] = tokenId;

        emit AIUpdateRequestSent(tokenId, msg.sender, requestId);
    }

    /// @dev Callback function intended to be called by the trusted oracle contract.
    /// This function processes the AI-generated data received from the oracle.
    /// NOTE: The signature `fulfillAIUpdate(bytes32 requestId, ...)` is illustrative.
    /// A real integration with a service like Chainlink would require a specific
    /// signature and potentially Chainlink client library usage.
    /// @param requestId The unique ID of the request being fulfilled.
    /// @param description The new description from the AI.
    /// @param imageUrlHint A hint or fragment for the image URL from the AI.
    /// @param traitKeys Array of trait keys from the AI.
    /// @param traitValues Array of trait values from the AI (must match traitKeys length).
    function fulfillAIUpdate(
        bytes32 requestId,
        string memory description,
        string memory imageUrlHint,
        string[] memory traitKeys,
        string[] memory traitValues // Simplified data structure for demo
    ) external {
        // This check is CRITICAL: ensure only the trusted oracle can call this
        require(msg.sender == _oracleAddress, "Caller is not the oracle");

        uint256 tokenId = _pendingUpdateRequests[requestId];
        require(tokenId != 0, "Unknown request ID");
        require(_tokenStates[tokenId].currentRequestId == requestId, "Request ID mismatch"); // Should match the pending request

        // Clear the pending request
        delete _pendingUpdateRequests[requestId];
        _tokenStates[tokenId].currentRequestId = bytes32(0); // Clear pending state on the token

        // Process and apply the received data
        _processOracleResponse(tokenId, description, imageUrlHint, traitKeys, traitValues);

        // Increment evolution level if not at max (and max > 0)
        if (_maxEvolutionLevel == 0 || _tokenStates[tokenId].evolutionLevel < _maxEvolutionLevel) {
            _tokenStates[tokenId].evolutionLevel++;
        }

        emit NFTStateUpdated(tokenId, _tokenStates[tokenId].evolutionLevel, _tokenStates[tokenId].description);
        emit AIUpdateReceived(tokenId, requestId, true); // Indicate success
    }

    /// @dev Internal function to apply oracle data to the NFTState.
    function _processOracleResponse(
        uint256 tokenId,
        string memory description,
        string memory imageUrlHint,
        string[] memory traitKeys,
        string[] memory traitValues
    ) internal {
        NFTState storage state = _tokenStates[tokenId];

        state.description = description;
        state.imageUrlHint = imageUrlHint;

        // Update traits mapping
        require(traitKeys.length == traitValues.length, "Trait key/value mismatch");
        for (uint i = 0; i < traitKeys.length; i++) {
            state.traits[traitKeys[i]] = traitValues[i];
        }
    }

    // --- Admin Functions (OnlyOwner) ---

    /// @dev Allows the owner to set the address of the trusted AI Oracle contract.
    /// @param newOracle The address of the new oracle contract.
    function setOracleAddress(address newOracle) public onlyOwner {
        require(newOracle != address(0), "Oracle address cannot be zero");
        emit OracleAddressUpdated(_oracleAddress, newOracle);
        _oracleAddress = newOracle;
    }

    /// @dev Allows the owner to set the fee required for requesting AI updates.
    /// @param newFee The new fee amount in wei.
    function setAIRequestFee(uint256 newFee) public onlyOwner {
        emit AIRequestFeeUpdated(_aiRequestFee, newFee);
        _aiRequestFee = newFee;
    }

    /// @dev Allows the owner to withdraw accumulated fees.
    function withdrawFees() public onlyOwner {
        uint256 fees = _totalFeesCollected;
        _totalFeesCollected = 0;
        (bool success, ) = payable(owner()).call{value: fees}("");
        require(success, "Fee withdrawal failed");
    }

    /// @dev Allows the owner to pause AI update requests.
    function pauseAIUpdates() public onlyOwner {
        require(!_paused, "Updates are already paused");
        _paused = true;
        emit UpdatesPaused();
    }

    /// @dev Allows the owner to resume AI update requests.
    function resumeAIUpdates() public onlyOwner {
        require(_paused, "Updates are not paused");
        _paused = false;
        emit UpdatesResumed();
    }

    /// @dev Sets an optional maximum evolution level for NFTs. 0 means no cap.
    /// @param level The new maximum evolution level.
    function setMaxEvolutionLevel(uint256 level) public onlyOwner {
        emit MaxEvolutionLevelUpdated(_maxEvolutionLevel, level);
        _maxEvolutionLevel = level;
    }

     /// @dev Sets an optional base URI for metadata. If set, tokenURI will use this + tokenId.
     /// If empty, tokenURI generates a data URI.
     /// @param uri The base URI string.
    function setBaseMetadataURI(string memory uri) public onlyOwner {
        _baseMetadataURI = uri;
    }


    /// @dev Allows the owner to simulate an oracle response for testing/demonstration.
    /// This bypasses the actual oracle call and directly triggers the state update logic.
    /// NOT FOR PRODUCTION USE IN A REAL ORACLE SCENARIO.
    /// @param tokenId The ID of the token to update.
    /// @param description Simulated new description.
    /// @param imageUrlHint Simulated new image hint.
    /// @param traitKeys Simulated trait keys.
    /// @param traitValues Simulated trait values.
    function simulateOracleResponse(
        uint256 tokenId,
        string memory description,
        string memory imageUrlHint,
        string[] memory traitKeys,
        string[] memory traitValues
    ) public onlyOwner {
         if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }
        // Clear any potentially pending request for this token for simulation purposes
        bytes32 pendingReqId = _tokenStates[tokenId].currentRequestId;
        if (pendingReqId != bytes32(0)) {
             delete _pendingUpdateRequests[pendingReqId];
             _tokenStates[tokenId].currentRequestId = bytes32(0);
        }


        // Use a dummy request ID for the event, not tied to any real oracle request
        bytes32 simulatedRequestId = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId));

        // Process and apply the simulated data
        _processOracleResponse(tokenId, description, imageUrlHint, traitKeys, traitValues);

        // Increment evolution level if not at max (and max > 0)
        if (_maxEvolutionLevel == 0 || _tokenStates[tokenId].evolutionLevel < _maxEvolutionLevel) {
            _tokenStates[tokenId].evolutionLevel++;
        }

        emit NFTStateUpdated(tokenId, _tokenStates[tokenId].evolutionLevel, _tokenStates[tokenId].description);
        emit AIUpdateReceived(tokenId, simulatedRequestId, true); // Indicate success with dummy ID
    }


    // --- Helper/View Functions ---

    /// @dev Checks if AI updates are currently paused.
    /// @return True if updates are paused, false otherwise.
    function isUpdatePaused() public view returns (bool) {
        return _paused;
    }

    /// @dev Returns the current fee for requesting an AI update.
    /// @return The fee amount in wei.
    function getAIRequestFee() public view returns (uint256) {
        return _aiRequestFee;
    }

    /// @dev Returns the address of the trusted AI Oracle contract.
    /// @return The oracle contract address.
    function getOracleAddress() public view returns (address) {
        return _oracleAddress;
    }

    /// @dev Returns the total amount of Ether collected from AI request fees.
    /// @return The total collected fees in wei.
    function getTotalFeesCollected() public view returns (uint256) {
        return _totalFeesCollected;
    }

    /// @dev Returns the configured maximum evolution level. 0 means no cap.
    /// @return The maximum evolution level.
    function getMaxEvolutionLevel() public view returns (uint256) {
        return _maxEvolutionLevel;
    }

     /// @dev Returns the pending oracle request ID for a token, if any.
     /// @param tokenId The ID of the token.
     /// @return The pending request ID, or bytes32(0) if no request is pending.
    function getPendingRequestId(uint256 tokenId) public view returns (bytes32) {
         if (!_exists(tokenId)) {
            return bytes32(0); // Or revert depending on desired behavior
        }
        return _tokenStates[tokenId].currentRequestId;
    }

    /// @dev Checks if a token currently has a pending oracle request.
    /// @param tokenId The ID of the token.
    /// @return True if a request is pending, false otherwise.
    function hasPendingRequest(uint256 tokenId) public view returns (bool) {
         if (!_exists(tokenId)) {
            return false;
        }
        return _tokenStates[tokenId].currentRequestId != bytes32(0);
    }

     /// @dev Returns the token ID associated with a pending request ID.
     /// @param requestId The request ID.
     /// @return The token ID, or 0 if the request ID is unknown or completed.
    function getPendingTokenId(bytes32 requestId) public view returns (uint256) {
        return _pendingUpdateRequests[requestId];
    }

    // Modifier to check if AI updates are paused
    modifier whenNotPaused() {
        require(!_paused, "AI updates are paused");
        _;
    }
}
```

---

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic Metadata (`tokenURI`):** Instead of pointing to a static JSON file off-chain, `tokenURI` constructs the metadata on-the-fly based on the current state (`NFTState`) stored directly in the contract. This state changes, making the metadata dynamic. Using a data URI means the metadata is served directly from the blockchain data, enhancing decentralization, although it's gas-intensive to generate complex JSON.
2.  **On-Chain State for Each Token (`_tokenStates` mapping):** Each NFT doesn't just have an owner and ID; it has its own rich data structure (`NFTState`) living on the blockchain. This allows the NFT to "remember" its evolution, traits, etc.
3.  **Oracle Integration:** The contract relies on an external oracle (`IAIOracle`) to receive information (simulating AI analysis results) that dictates how the NFT's state changes. This is a common pattern for bringing off-chain data/computation results on-chain. The `requestAIUpdate` and `fulfillAIUpdate` functions define this interaction flow.
4.  **State Updates Triggered by External Data:** The core mechanism is that an *external* event (the oracle delivering data) causes a *specific NFT's state* to change *on-chain*. This is a fundamental pattern for reactive/dynamic smart contracts.
5.  **Fee-Based Service (`requestAIUpdate`):** Users pay Ether to utilize the AI oracle service for their specific NFT, creating a simple economic model within the contract.
6.  **State Evolution (`evolutionLevel`):** The contract tracks how many times an NFT's state has been updated by the AI, giving it a clear history or "generation" count. A maximum level introduces scarcity or progression limits.
7.  **Trait Mapping (`traits`):** The `traits` mapping within `NFTState` allows for flexible, arbitrary key-value storage of attributes provided by the AI, making the type of data the AI can influence highly customizable.
8.  **Pending Request Tracking:** The `_pendingUpdateRequests` mapping is used to correctly route the oracle's response (`fulfillAIUpdate`) back to the specific token that requested the update, handling asynchronous oracle calls.
9.  **Admin Controls:** `Ownable` is used to provide administrative functions for setting critical parameters (`_oracleAddress`, `_aiRequestFee`, `_maxEvolutionLevel`) and managing the service (pause/resume).
10. **Simulation Function (`simulateOracleResponse`):** While not for production, this function is an advanced *development/demonstration* concept, allowing the owner to test the state update logic without a live oracle setup. It highlights the distinction between triggering a request and fulfilling it.

This contract structure is a simplified model, and a real-world implementation would need careful consideration of oracle security (e.g., using Chainlink's specific patterns), gas optimization, and potentially more complex data structures for traits or evolution logic. But it demonstrates the core principles of building dynamic, data-driven NFTs.