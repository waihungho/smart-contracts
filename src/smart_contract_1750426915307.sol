Okay, let's design a smart contract that represents a factory for creating **Dynamic, Generative, On-Chain Assets**. These assets won't just be static NFTs; their properties will be stored on-chain and can evolve over time or based on interactions, potentially using verifiable randomness. The "generation" refers to the initial parameters being set based on on-chain factors and randomness, and "dynamic" refers to these parameters changing later.

We will use Chainlink VRF for verifiable randomness, keep core asset parameters on-chain, and use a dynamic metadata approach where the `tokenURI` points to an external service that reads the *current* on-chain state to generate metadata.

This avoids duplicating standard NFT contracts and introduces complexity with on-chain state management, VRF integration for generation/evolution, and the dynamic metadata pattern.

---

### **Contract Outline and Function Summary**

**Contract Name:** `GenerativeAssetFactory`

**Concept:**
A factory contract that mints unique, generative, and dynamically evolving assets as ERC721 tokens. Each asset is created based on a predefined "Blueprint" and initial on-chain randomness/parameters. The asset's on-chain state (parameters) can change or "evolve" over time or via owner interaction, potentially requiring new randomness. Metadata is generated dynamically by an off-chain service reading the asset's current on-chain state.

**Key Features:**
1.  **Blueprint System:** Define different types of generative assets with unique rules, parameters, and evolution logic.
2.  **Generative Minting:** Mint assets based on a selected blueprint, using Chainlink VRF for verifiable randomness to influence initial parameters.
3.  **Dynamic On-Chain State:** Store core, evolving parameters for each asset directly on the blockchain.
4.  **Asset Evolution:** Allow asset owners to trigger a process that updates their asset's on-chain parameters, potentially using new randomness.
5.  **Dynamic Metadata:** `tokenURI` points to an external API that queries the contract for an asset's *current* state and generates metadata accordingly.
6.  **Admin/Governance:** Functions for creating blueprints, managing fees, and updating core contract configurations.
7.  **VRF Integration:** Securely obtain verifiable randomness for minting and evolution processes.

**Function Summary:**

**I. ERC721 Standard Functions (Inherited/Overridden):**
1.  `balanceOf(address owner) public view override`: Returns the number of tokens owned by `owner`.
2.  `ownerOf(uint256 tokenId) public view override`: Returns the owner of the `tokenId` token.
3.  `approve(address to, uint256 tokenId) public override`: Approves `to` to transfer the token.
4.  `getApproved(uint256 tokenId) public view override`: Returns the approved address for the token.
5.  `setApprovalForAll(address operator, bool approved) public override`: Enables or disables approval for a third party (`operator`) to manage all of `msg.sender`'s assets.
6.  `isApprovedForAll(address owner, address operator) public view override`: Tells whether an operator is approved by a token holder.
7.  `transferFrom(address from, address to, uint256 tokenId) public override`: Transfers token ownership.
8.  `safeTransferFrom(address from, address to, uint256 tokenId) public override`: Safer transfer variant (checks if destination is ERC721 receiver).
9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data) public override`: Safer transfer variant with data.
10. `supportsInterface(bytes4 interfaceId) public view override`: Standard ERC165 function.

**II. Blueprint Management:**
11. `createBlueprint(uint256 _mintFee, uint256 _evolutionFee, uint256 _maxSupply, bytes memory _initialParamsTemplate, bytes memory _evolutionLogicParams, string memory _baseMetadata)`: Creates a new type of generative asset blueprint.
12. `updateBlueprintParameters(uint256 _blueprintId, uint256 _newMintFee, uint256 _newEvolutionFee, uint256 _newMaxSupply, bytes memory _newInitialParamsTemplate, bytes memory _newEvolutionLogicParams, string memory _newBaseMetadata)`: Updates configuration parameters for an existing blueprint.
13. `getBlueprint(uint256 _blueprintId) public view returns (Blueprint memory)`: Retrieves the details of a specific blueprint.
14. `pauseBlueprintMinting(uint256 _blueprintId) public`: Pauses minting for a specific blueprint.
15. `unpauseBlueprintMinting(uint256 _blueprintId) public`: Unpauses minting for a specific blueprint.
16. `getAllBlueprintIds() public view returns (uint256[] memory)`: Returns a list of all created blueprint IDs.

**III. Asset Minting (Generative):**
17. `requestMint(uint256 _blueprintId)`: Initiates the minting process for a blueprint, pays the fee, and requests VRF randomness.
18. `getPendingMintRequest(bytes32 _requestId) public view returns (address minter, uint256 blueprintId)`: Views the details associated with a pending mint request.

**IV. Asset Evolution (Dynamic):**
19. `triggerAssetEvolution(uint256 _tokenId)`: Initiates the evolution process for an asset, pays the fee, and requests new VRF randomness if needed for that blueprint's evolution logic.
20. `getPendingEvolutionRequest(bytes32 _requestId) public view returns (uint256 tokenId)`: Views the details associated with a pending evolution request.
21. `getAssetData(uint256 _tokenId) public view returns (AssetData memory)`: Retrieves the current on-chain parameters/state of a specific asset.

**V. VRF Callbacks (Chainlink Automation):**
22. `fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override`: Callback function invoked by Chainlink VRF coordinator. Processes randomness to complete pending mint or evolution requests.

**VI. Dynamic Metadata:**
23. `tokenURI(uint256 tokenId) public view override returns (string memory)`: Generates the URI pointing to the dynamic metadata API endpoint for the token.
24. `setMetadataAPIBaseURI(string memory _newBaseURI)`: Sets the base URL for the dynamic metadata API.

**VII. Admin & Configuration:**
25. `withdrawFees(address _to)`: Allows the owner to withdraw accumulated contract fees.
26. `setVrfParameters(uint64 _subscriptionId, bytes32 _keyHash, address _vrfCoordinator)`: Sets Chainlink VRF configuration.
27. `setAllowedMetadataSigner(address _signer, bool _isAllowed)`: Allows/disallows specific addresses to be recognized as valid signers by the dynamic metadata API (optional, but good practice for API verification).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

// --- Contract Outline and Function Summary ---
// Contract Name: GenerativeAssetFactory
// Concept: A factory contract that mints unique, generative, and dynamically evolving assets as ERC721 tokens.
// Key Features: Blueprint System, Generative Minting (with VRF), Dynamic On-Chain State, Asset Evolution (with VRF), Dynamic Metadata, Admin/Governance.
//
// Function Summary:
// I. ERC721 Standard Functions (Inherited/Overridden):
//    1. balanceOf(address owner)
//    2. ownerOf(uint256 tokenId)
//    3. approve(address to, uint256 tokenId)
//    4. getApproved(uint256 tokenId)
//    5. setApprovalForAll(address operator, bool approved)
//    6. isApprovedForAll(address owner, address operator)
//    7. transferFrom(address from, address to, uint256 tokenId)
//    8. safeTransferFrom(address from, address to, uint256 tokenId)
//    9. safeTransferFrom(address from, address to, uint256 tokenId, bytes data)
//    10. supportsInterface(bytes4 interfaceId)
//
// II. Blueprint Management:
//    11. createBlueprint(...)
//    12. updateBlueprintParameters(...)
//    13. getBlueprint(uint256 _blueprintId)
//    14. pauseBlueprintMinting(uint256 _blueprintId)
//    15. unpauseBlueprintMinting(uint256 _blueprintId)
//    16. getAllBlueprintIds()
//
// III. Asset Minting (Generative):
//    17. requestMint(uint256 _blueprintId)
//    18. getPendingMintRequest(bytes32 _requestId)
//
// IV. Asset Evolution (Dynamic):
//    19. triggerAssetEvolution(uint256 _tokenId)
//    20. getPendingEvolutionRequest(bytes32 _requestId)
//    21. getAssetData(uint256 _tokenId)
//
// V. VRF Callbacks (Chainlink Automation):
//    22. fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
//
// VI. Dynamic Metadata:
//    23. tokenURI(uint256 tokenId)
//    24. setMetadataAPIBaseURI(string memory _newBaseURI)
//
// VII. Admin & Configuration:
//    25. withdrawFees(address _to)
//    26. setVrfParameters(uint64 _subscriptionId, bytes32 _keyHash, address _vrfCoordinator)
//    27. setAllowedMetadataSigner(address _signer, bool _isAllowed)
// --- End of Outline ---

contract GenerativeAssetFactory is ERC721, Ownable, VRFConsumerBaseV2, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _blueprintIds;

    // --- Structs ---

    // Defines a type of generative asset
    struct Blueprint {
        bool isActive; // Can assets of this type be minted?
        uint256 mintFee; // Fee to mint an asset of this type
        uint256 evolutionFee; // Fee to evolve an asset of this type
        uint256 maxSupply; // Maximum number of assets of this type
        uint256 currentSupply; // Number of assets of this type minted so far
        bytes initialParamsTemplate; // Template/seed data for initial parameters (interpreted off-chain)
        bytes evolutionLogicParams; // Parameters guiding the evolution process (interpreted off-chain)
        string baseMetadata; // Base string for metadata API endpoint for this blueprint (e.g., "/blueprint/X")
        bool paused; // Temporarily pause minting for this blueprint
    }

    // Stores the unique, dynamic state of an individual asset
    struct AssetData {
        uint256 blueprintId;
        uint256 mintTimestamp;
        uint256 lastEvolutionTimestamp;
        bytes currentParameters; // The actual evolving parameters stored on-chain
        uint256 evolutionCount; // How many times this asset has evolved
    }

    // Stores state for pending mint requests awaiting VRF randomness
    struct MintRequest {
        address minter;
        uint256 blueprintId;
    }

    // Stores state for pending evolution requests awaiting VRF randomness
    struct EvolutionRequest {
        uint256 tokenId;
    }

    // --- State Variables ---

    mapping(uint256 => Blueprint) public blueprints; // blueprintId -> Blueprint data
    mapping(uint256 => AssetData) public assetData; // tokenId -> Asset data

    // Chainlink VRF V2
    uint64 private s_subscriptionId;
    bytes32 private s_keyHash;
    uint32 private s_callbackGasLimit = 500_000; // Reasonable gas limit for fulfillRandomWords
    uint16 private s_requestConfirmations = 3;
    uint32 private s_numWords = 1; // We need at least one random word

    // Track VRF requests: requestId -> request type (mint/evolution) and context
    mapping(bytes32 => MintRequest) private s_pendingMintRequests;
    mapping(bytes32 => EvolutionRequest) private s_pendingEvolutionRequests;

    // Dynamic Metadata Configuration
    string private _metadataAPIBaseURI; // Base URI for the off-chain metadata API
    mapping(address => bool) private _allowedMetadataSigners; // Addresses allowed to sign metadata responses (optional check for off-chain API)

    // --- Events ---

    event BlueprintCreated(uint256 indexed blueprintId, address indexed creator);
    event BlueprintParametersUpdated(uint256 indexed blueprintId);
    event BlueprintMintingPaused(uint256 indexed blueprintId);
    event BlueprintMintingUnpaused(uint256 indexed blueprintId);
    event MintRequestInitiated(uint256 indexed blueprintId, address indexed minter, bytes32 indexed requestId);
    event AssetMinted(uint256 indexed tokenId, uint256 indexed blueprintId, address indexed owner);
    event EvolutionRequestInitiated(uint256 indexed tokenId, bytes32 indexed requestId);
    event AssetEvolved(uint256 indexed tokenId, uint256 newEvolutionCount);
    event FeesWithdrawn(address indexed to, uint256 amount);
    event MetadataAPIBaseURISet(string newBaseURI);

    // --- Constructor ---

    constructor(address vrfCoordinator, uint64 subscriptionId, bytes32 keyHash)
        ERC721("Generative Dynamic Asset", "GDA")
        Ownable(msg.sender)
        VRFConsumerBaseV2(vrfCoordinator)
    {
        s_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
    }

    // --- ERC721 Overrides (Explicit for clarity, functionality mostly handled by inherited) ---
    // (Functions 1-10 are standard ERC721 functions provided by OpenZeppelin)

    // --- Blueprint Management (Functions 11-16) ---

    /**
     * @notice Creates a new type of generative asset blueprint.
     * @param _mintFee The fee required to mint an asset using this blueprint.
     * @param _evolutionFee The fee required to trigger evolution for an asset using this blueprint.
     * @param _maxSupply The maximum number of tokens that can be minted for this blueprint (0 for unlimited).
     * @param _initialParamsTemplate Template data interpreted off-chain to set initial parameters.
     * @param _evolutionLogicParams Parameters guiding the off-chain evolution logic for this blueprint.
     * @param _baseMetadata Base path for the metadata API endpoint for this blueprint (e.g., "blueprint/1/").
     */
    function createBlueprint(
        uint256 _mintFee,
        uint256 _evolutionFee,
        uint256 _maxSupply,
        bytes memory _initialParamsTemplate,
        bytes memory _evolutionLogicParams,
        string memory _baseMetadata
    ) external onlyOwner nonReentrant {
        _blueprintIds.increment();
        uint256 newBlueprintId = _blueprintIds.current();

        blueprints[newBlueprintId] = Blueprint({
            isActive: true,
            mintFee: _mintFee,
            evolutionFee: _evolutionFee,
            maxSupply: _maxSupply,
            currentSupply: 0,
            initialParamsTemplate: _initialParamsTemplate,
            evolutionLogicParams: _evolutionLogicParams,
            baseMetadata: _baseMetadata,
            paused: false
        });

        emit BlueprintCreated(newBlueprintId, msg.sender);
    }

    /**
     * @notice Updates configuration parameters for an existing blueprint.
     * @param _blueprintId The ID of the blueprint to update.
     * @param _newMintFee The new fee for minting.
     * @param _newEvolutionFee The new fee for evolution.
     * @param _newMaxSupply The new maximum supply (0 for unlimited).
     * @param _newInitialParamsTemplate The new initial parameters template.
     * @param _newEvolutionLogicParams The new evolution logic parameters.
     * @param _newBaseMetadata The new base metadata path.
     */
    function updateBlueprintParameters(
        uint256 _blueprintId,
        uint256 _newMintFee,
        uint256 _newEvolutionFee,
        uint256 _newMaxSupply,
        bytes memory _newInitialParamsTemplate,
        bytes memory _newEvolutionLogicParams,
        string memory _newBaseMetadata
    ) external onlyOwner nonReentrant {
        Blueprint storage bp = blueprints[_blueprintId];
        require(bp.isActive, "Blueprint does not exist");

        bp.mintFee = _newMintFee;
        bp.evolutionFee = _newEvolutionFee;
        bp.maxSupply = _newMaxSupply;
        bp.initialParamsTemplate = _newInitialParamsTemplate;
        bp.evolutionLogicParams = _newEvolutionLogicParams;
        bp.baseMetadata = _newBaseMetadata;

        emit BlueprintParametersUpdated(_blueprintId);
    }

    /**
     * @notice Retrieves the details of a specific blueprint.
     * @param _blueprintId The ID of the blueprint.
     * @return A struct containing the blueprint's details.
     */
    function getBlueprint(uint256 _blueprintId) public view returns (Blueprint memory) {
        require(blueprints[_blueprintId].isActive, "Blueprint does not exist");
        return blueprints[_blueprintId];
    }

    /**
     * @notice Pauses minting for a specific blueprint. Existing tokens are unaffected.
     * @param _blueprintId The ID of the blueprint to pause.
     */
    function pauseBlueprintMinting(uint256 _blueprintId) external onlyOwner nonReentrant {
        Blueprint storage bp = blueprints[_blueprintId];
        require(bp.isActive, "Blueprint does not exist");
        bp.paused = true;
        emit BlueprintMintingPaused(_blueprintId);
    }

    /**
     * @notice Unpauses minting for a specific blueprint.
     * @param _blueprintId The ID of the blueprint to unpause.
     */
    function unpauseBlueprintMinting(uint256 _blueprintId) external onlyOwner nonReentrant {
        Blueprint storage bp = blueprints[_blueprintId];
        require(bp.isActive, "Blueprint does not exist");
        bp.paused = false;
        emit BlueprintMintingUnpaused(_blueprintId);
    }

    /**
     * @notice Returns a list of all created blueprint IDs.
     * @return An array of blueprint IDs.
     */
    function getAllBlueprintIds() public view returns (uint256[] memory) {
        uint256 totalBlueprints = _blueprintIds.current();
        uint256[] memory ids = new uint256[](totalBlueprints);
        for (uint256 i = 1; i <= totalBlueprints; i++) {
            ids[i - 1] = i;
        }
        return ids;
    }

    // --- Asset Minting (Generative) (Functions 17-18) ---

    /**
     * @notice Initiates the minting process for an asset based on a blueprint.
     * Requires payment of the blueprint's mint fee. Requests VRF randomness.
     * Minting is completed in the `fulfillRandomWords` callback.
     * @param _blueprintId The ID of the blueprint to use for minting.
     * @return requestId The VRF request ID.
     */
    function requestMint(uint256 _blueprintId) external payable nonReentrant returns (bytes32 requestId) {
        Blueprint storage bp = blueprints[_blueprintId];
        require(bp.isActive, "Blueprint does not exist");
        require(!bp.paused, "Blueprint minting is paused");
        require(msg.value >= bp.mintFee, "Insufficient mint fee");
        if (bp.maxSupply > 0) {
             require(bp.currentSupply < bp.maxSupply, "Blueprint supply limit reached");
        }

        // Request randomness from Chainlink VRF
        requestId = requestRandomWords(s_keyHash, s_subscriptionId, s_requestConfirmations, s_callbackGasLimit, s_numWords);

        // Store pending request details
        s_pendingMintRequests[requestId] = MintRequest({
            minter: msg.sender,
            blueprintId: _blueprintId
        });

        emit MintRequestInitiated(_blueprintId, msg.sender, requestId);

        // Transfer fee to contract
        // Fees are left in the contract and can be withdrawn by the owner
        // A simple `transfer` is sufficient here as no complex logic is needed on the receiving side.
        // If fees were intended for immediate use elsewhere, `call` would be more flexible.
    }

    /**
     * @notice Views the details associated with a pending mint request.
     * @param _requestId The VRF request ID.
     * @return minter The address that initiated the mint request.
     * @return blueprintId The blueprint ID requested.
     */
    function getPendingMintRequest(bytes32 _requestId) public view returns (address minter, uint256 blueprintId) {
        MintRequest memory req = s_pendingMintRequests[_requestId];
        return (req.minter, req.blueprintId);
    }

    // --- Asset Evolution (Dynamic) (Functions 19-21) ---

    /**
     * @notice Initiates the evolution process for a specific asset.
     * Requires payment of the blueprint's evolution fee. Requests VRF randomness if needed.
     * Evolution is completed in the `fulfillRandomWords` callback.
     * Only the token owner can trigger evolution.
     * @param _tokenId The ID of the asset to evolve.
     * @return requestId The VRF request ID (0 if no randomness was needed).
     */
    function triggerAssetEvolution(uint256 _tokenId) external payable nonReentrant returns (bytes32 requestId) {
        require(_exists(_tokenId), "Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Not token owner");

        AssetData storage data = assetData[_tokenId];
        Blueprint storage bp = blueprints[data.blueprintId];
        require(bp.isActive, "Blueprint inactive, cannot evolve"); // Optional: allow evolution even if blueprint is inactive? Decided against for simplicity.
        require(msg.value >= bp.evolutionFee, "Insufficient evolution fee");

        // Note: This example uses VRF for evolution always if numWords > 0.
        // A more advanced contract could have different evolution types:
        // 1) Randomness-based (requires VRF)
        // 2) Time-based (check block.timestamp)
        // 3) Interaction-based (params change based on specific calls)
        // 4) External Data-based (using Chainlink Keepers/Oracles)
        // For this example, we'll assume randomness is always needed for the 'standard' evolution.

        // Request randomness from Chainlink VRF for evolution
        requestId = requestRandomWords(s_keyHash, s_subscriptionId, s_requestConfirmations, s_callbackGasLimit, s_numWords);

        // Store pending request details
        s_pendingEvolutionRequests[requestId] = EvolutionRequest({
            tokenId: _tokenId
        });

        emit EvolutionRequestInitiated(_tokenId, requestId);

        // Transfer fee to contract
        // Fees are left in the contract and can be withdrawn by the owner
    }

    /**
     * @notice Views the details associated with a pending evolution request.
     * @param _requestId The VRF request ID.
     * @return tokenId The token ID requested to evolve.
     */
    function getPendingEvolutionRequest(bytes32 _requestId) public view returns (uint256 tokenId) {
        EvolutionRequest memory req = s_pendingEvolutionRequests[_requestId];
        return req.tokenId;
    }

    /**
     * @notice Retrieves the current on-chain parameters and state of a specific asset.
     * @param _tokenId The ID of the asset.
     * @return A struct containing the asset's state data.
     */
    function getAssetData(uint256 _tokenId) public view returns (AssetData memory) {
        require(_exists(_tokenId), "Token does not exist");
        return assetData[_tokenId];
    }

    // --- VRF Callbacks (Chainlink Automation) (Function 22) ---

    /**
     * @notice Callback function invoked by Chainlink VRF coordinator after randomness is fulfilled.
     * This function handles both minting and evolution completions based on the request ID.
     * @param requestId The VRF request ID.
     * @param randomWords The random words generated by VRF.
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        // Check if this request was for a mint
        MintRequest memory mintReq = s_pendingMintRequests[bytes32(requestId)];

        if (mintReq.minter != address(0)) {
            // This was a mint request
            delete s_pendingMintRequests[bytes32(requestId)]; // Clear the pending request

            Blueprint storage bp = blueprints[mintReq.blueprintId];

            // Basic check for supply limit (re-check in case state changed drastically, though unlikely with nonReentrant)
             if (bp.maxSupply > 0 && bp.currentSupply >= bp.maxSupply) {
                 // Handle case where supply limit was hit while request was pending
                 // Refund user? For now, just emit and don't mint.
                 // A more robust system might hold user's fee until fulfillment.
                 emit AssetMinted(0, mintReq.blueprintId, mintReq.minter); // Emit with tokenId 0 to signal failure
                 return; // Do not proceed with minting
             }

            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();

            // Use randomness and blueprint parameters to generate initial asset data
            // The actual parameter generation logic would be complex and likely happen off-chain,
            // but the *randomness* and *initialParamsTemplate* are provided here as input.
            // The `initialParamsTemplate` and `randomWords` would be passed to an off-chain
            // service via event listeners or direct lookup to determine the generated `currentParameters`.
            // For the contract's state, we'll store a simplified placeholder based on randomness.
            // In a real dapp, the off-chain service would calculate the parameters and potentially
            // send a transaction back (signed by an allowed signer) to update `currentParameters`,
            // or the client fetches data and interprets `randomWords` and template locally.
            // Storing *derived* parameters directly after VRF callback is cleaner if the derivation
            // is simple/deterministic or happens via a trusted oracle/keeper service.
            // For this example, let's simulate a simple derivation: `currentParameters` is a hash
            // of the template and randomness.

            bytes memory initialParams;
            if (randomWords.length > 0) {
                 // Simulate generating initial params based on template and randomness
                 initialParams = abi.encodePacked(bp.initialParamsTemplate, randomWords[0]);
            } else {
                 initialParams = bp.initialParamsTemplate; // Fallback if no randomness
            }


            assetData[newItemId] = AssetData({
                blueprintId: mintReq.blueprintId,
                mintTimestamp: block.timestamp,
                lastEvolutionTimestamp: block.timestamp,
                currentParameters: initialParams, // Placeholder: derived from randomness & template off-chain in a real system
                evolutionCount: 0
            });

            _safeMint(mintReq.minter, newItemId);
            bp.currentSupply++;

            emit AssetMinted(newItemId, mintReq.blueprintId, mintReq.minter);

        } else {
            // Check if this request was for an evolution
            EvolutionRequest memory evoReq = s_pendingEvolutionRequests[bytes32(requestId)];

            if (evoReq.tokenId != 0) {
                 // This was an evolution request
                delete s_pendingEvolutionRequests[bytes32(requestId)]; // Clear the pending request

                AssetData storage data = assetData[evoReq.tokenId];
                Blueprint storage bp = blueprints[data.blueprintId];

                // Use randomness and blueprint parameters to evolve asset data
                // Similar to minting, the complex evolution logic happens off-chain,
                // using `data.currentParameters`, `bp.evolutionLogicParams`, and `randomWords` as inputs.
                // The contract stores the resulting `newParameters`.
                // Simulate evolution: update parameters based on current and randomness.

                bytes memory evolvedParams;
                if (randomWords.length > 0) {
                    // Simulate evolving params based on current params, evolution logic, and randomness
                    evolvedParams = abi.encodePacked(data.currentParameters, bp.evolutionLogicParams, randomWords[0]);
                } else {
                    evolvedParams = abi.encodePacked(data.currentParameters, bp.evolutionLogicParams); // Fallback
                }

                data.currentParameters = evolvedParams; // Placeholder: derived off-chain
                data.lastEvolutionTimestamp = block.timestamp;
                data.evolutionCount++;

                emit AssetEvolved(evoReq.tokenId, data.evolutionCount);
            }
             // If neither a mint nor evolution request, the request ID was unknown or already processed.
             // This could indicate an issue or a duplicate callback.
        }
    }

    // --- Dynamic Metadata (Functions 23-24) ---

    /**
     * @notice Returns the URI for the token's metadata. This URI points to an off-chain API.
     * The API is expected to read the token's on-chain state (`assetData`) to generate dynamic JSON metadata.
     * Format: <_metadataAPIBaseURI>/<blueprint.baseMetadata>/<tokenId>
     * @param tokenId The ID of the token.
     * @return The metadata URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        AssetData storage data = assetData[tokenId];
        Blueprint storage bp = blueprints[data.blueprintId];

        string memory base = _metadataAPIBaseURI;
        string memory blueprintPath = bp.baseMetadata;
        string memory tokenIdStr = Strings.toString(tokenId);

        // Construct the full URI
        // Check if base ends with /, if not add it
        if (bytes(base).length > 0 && bytes(base)[bytes(base).length - 1] != '/') {
            base = string(abi.encodePacked(base, "/"));
        }
         // Check if blueprintPath ends with /, if not add it
         if (bytes(blueprintPath).length > 0 && bytes(blueprintPath)[bytes(blueprintPath).length - 1] != '/') {
             blueprintPath = string(abi.encodePacked(blueprintPath, "/"));
         }


        return string(abi.encodePacked(base, blueprintPath, tokenIdStr));
    }

    /**
     * @notice Sets the base URI for the off-chain dynamic metadata API.
     * @param _newBaseURI The new base URI.
     */
    function setMetadataAPIBaseURI(string memory _newBaseURI) external onlyOwner nonReentrant {
        _metadataAPIBaseURI = _newBaseURI;
        emit MetadataAPIBaseURISet(_newBaseURI);
    }

    // --- Admin & Configuration (Functions 25-27) ---

    /**
     * @notice Allows the contract owner to withdraw accumulated Ether fees.
     * @param _to The address to send the fees to.
     */
    function withdrawFees(address _to) external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        (bool success, ) = _to.call{value: balance}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(_to, balance);
    }

     /**
      * @notice Sets the Chainlink VRF parameters.
      * @param _subscriptionId The VRF subscription ID.
      * @param _keyHash The VRF key hash.
      * @param _vrfCoordinator The address of the VR VRF Coordinator.
      */
    function setVrfParameters(
        uint64 _subscriptionId,
        bytes32 _keyHash,
        address _vrfCoordinator
    ) external onlyOwner nonReentrant {
        s_subscriptionId = _subscriptionId;
        s_keyHash = _keyHash;
        // Note: Updating the coordinator address directly in the base contract might require
        // redeploying the base contract or using a proxy pattern if the base is immutable.
        // This simplified example just stores the values. A real implementation might
        // need to detach and re-attach the subscription.
    }


    /**
     * @notice Adds or removes an address from the list of allowed metadata signers.
     * This is intended for the off-chain API to verify requests coming from trusted sources,
     * not strictly enforced on-chain but useful for off-chain validation.
     * @param _signer The address to add or remove.
     * @param _isAllowed Whether the signer should be allowed (true) or not (false).
     */
    function setAllowedMetadataSigner(address _signer, bool _isAllowed) external onlyOwner nonReentrant {
        _allowedMetadataSigners[_signer] = _isAllowed;
        // No event added for this, could add one if needed for monitoring
    }

    /**
     * @notice Checks if an address is in the list of allowed metadata signers.
     * Public view function for the off-chain API to call.
     * @param _signer The address to check.
     * @return True if the signer is allowed, false otherwise.
     */
    function isAllowedMetadataSigner(address _signer) public view returns (bool) {
        return _allowedMetadataSigners[_signer];
    }

    // --- Internal/Helper Functions ---

    // The _beforeTokenTransfer and _afterTokenTransfer hooks could be used here
    // for custom logic around transfers, but are not strictly needed for this
    // contract's core dynamic/generative features.

    // --- Missing Functionality (Consider for a production system) ---
    // - More complex `fulfillRandomWords` logic to deterministically derive `currentParameters`
    //   based on `randomWords`, `initialParamsTemplate`, `evolutionLogicParams`, and prior state.
    //   This might require significant on-chain computation or rely on off-chain services
    //   (like Chainlink Keepers or a custom oracle submitting updates).
    // - Subscription management (creating, funding, adding consumers) would typically happen
    //   via a separate contract or manual interaction with the VRF Coordinator.
    // - More sophisticated error handling in `fulfillRandomWords` if `_safeMint` fails
    //   or other issues occur after getting randomness.
    // - Burning tokens.
    // - Royalty settings (ERC2981).
    // - Pausing evolution (separate from minting).
    // - Different evolution triggers (time, interaction, etc.).
    // - On-chain interpretation layer for `currentParameters` or `evolutionLogicParams`
    //   if certain parameter effects need to be enforced by the contract itself (e.g.,
    //   asset grants holder a specific right on-chain). Current design assumes
    //   parameters primarily influence off-chain rendering/utility via the metadata API.
    // - Access control for `triggerAssetEvolution` beyond just the owner (e.g., specific roles).
    // - Refund mechanism for failed mints/evolutions if VRF callback fails or hits supply limit.
    // - Upgradability pattern (e.g., UUPS proxy).
}
```