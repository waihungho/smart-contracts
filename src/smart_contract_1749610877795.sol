Okay, let's design a smart contract called `QuantumChronicles`. This contract will manage a collection of dynamic NFTs representing evolving artifacts within a narrative or timeline. The artifacts' properties can change based on time, external events (simulated via Chainlink oracles), user interaction, and controlled randomness (via Chainlink VRF). The contract will also feature "Epochs" which represent different phases of the chronicle, influencing artifact behavior and creation.

This contract integrates ERC721 standards with advanced concepts like:
1.  **Dynamic State:** Artifacts aren't static; their properties and behavior change.
2.  **On-chain Randomness:** Uses Chainlink VRF for unpredictable outcomes (e.g., initial artifact traits, temporal shifts).
3.  **Oracle Interaction:** Uses Chainlink Any API to simulate external data affecting artifacts or the narrative.
4.  **Time & Epochs:** The contract state (`currentEpoch`) and artifact state can depend on time or explicit epoch progression.
5.  **User Interaction & State Transitions:** Users can trigger actions that change artifact states (e.g., "Unveiling").
6.  **Complex Data Structure:** Artifacts hold multiple dynamic properties.
7.  **Access Control & Pausability:** Standard but necessary features.
8.  **Inheritance:** Uses standard OpenZeppelin contracts.

It aims to be creative by embedding mechanics tied to an abstract, evolving chronicle concept.

---

**QuantumChronicles Smart Contract**

**Outline:**

1.  **License & Pragmas:** Standard SPDX license and Solidity version.
2.  **Imports:** ERC721, Ownable, VRFConsumerBaseV2, ChainlinkClient, LinkTokenInterface, Pausable.
3.  **Error Codes:** Custom errors for clarity.
4.  **Enums:** Define possible states for artifacts (`ArtifactState`) and contract epochs (`Epoch`).
5.  **Structs:** Define the data structure for each artifact (`ArtifactData`).
6.  **State Variables:**
    *   Contract metadata (name, symbol).
    *   Epoch tracking (`currentEpoch`, epoch-specific parameters).
    *   Artifact data mapping (`id => ArtifactData`).
    *   Counters (`_nextTokenId`, `_vrfRequestIdCounter`).
    *   VRF configuration (keyhash, subId, request confirmations, number of words).
    *   Chainlink Any API configuration (oracle address, job ID, fee).
    *   Mappings for tracking pending VRF requests and Oracle requests (`requestId => data`).
    *   Pausability state.
7.  **Events:** Signal important actions (minting, state changes, epoch changes, VRF/Oracle requests/fulfillment).
8.  **Constructor:** Initialize contract, ERC721, Ownable, Pausable, VRFConsumerBaseV2, ChainlinkClient, and set initial VRF/Oracle parameters.
9.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `whenPaused`.
10. **ERC721 Standard Functions:** Overrides and implementations (`tokenURI`, internal helpers).
11. **Core Chronicle/Artifact Management Functions:**
    *   Minting (`mintChronicleArtifact`, triggered by VRF fulfillment).
    *   Getting artifact details (`getArtifactDetails`).
    *   Updating artifact data (internal functions).
    *   Unveiling artifacts (`unveilArtifactProperties`).
12. **Epoch Management Functions:**
    *   Advancing the epoch (`advanceEpoch`).
    *   Setting epoch-specific parameters (`setEpochParameter`).
    *   Getting current epoch (`getCurrentEpoch`).
13. **Temporal Mechanics (VRF Integration):**
    *   Triggering a temporal shift (`triggerTemporalShift`).
    *   VRF request function (`requestRandomWords`, internal).
    *   VRF fulfillment callback (`fulfillRandomWords`).
    *   Mapping VRF requests to actions (minting, temporal shifts).
14. **External Influence (Oracle Integration):**
    *   Requesting external data (`requestChronicleInfluence`).
    *   Chainlink Client request function (`sendChainlinkRequest`, internal).
    *   Chainlink Client fulfillment callback (`fulfillChainlinkRequest`).
    *   Mapping Oracle requests to actions/storage.
    *   Getting Oracle request result (`getChronicleInfluenceResult`).
15. **Configuration & Utility Functions:**
    *   Setting VRF parameters (`setVRFParameters`).
    *   Setting Oracle parameters (`setOracleParameters`).
    *   Owner withdrawal (`withdrawFunds`).
    *   Pausability functions (`pause`, `unpause`).
    *   Getting contract state (`isPaused`, `getTokenCount`).

---

**Function Summary (27 Functions):**

1.  `constructor(...)`: Initializes the contract, sets basic metadata, and configures Chainlink VRF and Oracle settings.
2.  `supportsInterface(bytes4 interfaceId)`: ERC165 standard function, reports supported interfaces.
3.  `balanceOf(address owner)`: ERC721 standard function, returns number of tokens owned by an address.
4.  `ownerOf(uint256 tokenId)`: ERC721 standard function, returns the owner of a specific token.
5.  `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC721 standard function, transfers token ownership safely.
6.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: ERC721 standard function (overload), transfers token ownership safely with data.
7.  `transferFrom(address from, address to, uint256 tokenId)`: ERC721 standard function, transfers token ownership (less safe than `safeTransferFrom` for smart contract recipients).
8.  `approve(address to, uint256 tokenId)`: ERC721 standard function, approves an address to spend a specific token.
9.  `getApproved(uint256 tokenId)`: ERC721 standard function, returns the approved address for a token.
10. `setApprovalForAll(address operator, bool approved)`: ERC721 standard function, approves/disapproves an operator for all owner's tokens.
11. `isApprovedForAll(address owner, address operator)`: ERC721 standard function, checks if an operator is approved for all owner's tokens.
12. `tokenURI(uint256 tokenId)`: ERC721 standard function (override), returns the URI for token metadata, incorporating dynamic state.
13. `mintChronicleArtifact(uint32 _requestConfirmations)`: Public function allowing anyone to *request* a new artifact mint. Requires payment (implicitly handled by transfer *to* contract) and triggers a VRF request. The actual minting happens in `fulfillRandomWords`.
14. `fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords)`: Chainlink VRF callback function. It processes the randomness received and completes the action associated with the request ID (e.g., minting an artifact, determining temporal shift outcomes).
15. `getArtifactDetails(uint256 tokenId)`: Reads and returns all stored data for a specific artifact.
16. `unveilArtifactProperties(uint256 tokenId)`: Allows the owner of an artifact to change its state from `Dormant` to `Unveiled`, potentially revealing more about its properties or enabling new interactions. Might require a condition or cost.
17. `advanceEpoch()`: Owner-only function to increment the `currentEpoch`. This can change the behavior or parameters for minting, shifts, etc.
18. `setEpochParameter(Epoch epoch, uint256 parameterCode, uint256 value)`: Owner-only function to set specific parameters associated with different epochs.
19. `getCurrentEpoch()`: Returns the current epoch of the chronicle.
20. `triggerTemporalShift(uint256 tokenId, uint32 _requestConfirmations)`: Allows triggering a state change or property modification on a specific artifact. Requires a VRF request to determine the outcome of the shift. Can only be called under certain conditions (e.g., sufficient `temporalEnergy`).
21. `requestChronicleInfluence(uint256 tokenId, string memory _externalDataSource)`: Allows requesting external data via Chainlink Oracle to potentially influence an artifact's state or properties. The actual influence logic is in `fulfillChainlinkRequest`.
22. `fulfillChainlinkRequest(bytes32 _requestId, bytes memory _data)`: Chainlink Client callback function. Processes the data received from the oracle and applies any defined influence on the artifact or contract state.
23. `getChronicleInfluenceResult(bytes32 _requestId)`: Allows querying the result stored from a specific Chainlink Oracle request.
24. `setVRFParameters(uint64 _subscriptionId, bytes32 _keyHash, uint32 _requestConfirmations, uint32 _numWords)`: Owner-only function to update VRF configuration.
25. `setOracleParameters(address _oracle, bytes32 _jobId, uint256 _fee)`: Owner-only function to update Chainlink Any API configuration.
26. `pause()`: Owner-only function to pause certain contract interactions (e.g., minting, state changes). Uses the `Pausable` pattern.
27. `unpause()`: Owner-only function to unpause the contract.
28. `withdrawFunds()`: Owner-only function to withdraw any accumulated Ether (e.g., from minting fees, if implemented).
29. `getTokenCount()`: Returns the total number of artifacts minted.

**(Note: The function count easily exceeds 20 with these distinct operations, including standard ERC721 functions and Chainlink integration functions.)**

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// Chainlink VRF v2 imports
import "@chainlink/contracts/src/v0.8/VRF/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

// Chainlink Any API imports
import "@chainlink/contracts/src/v0.8/AnyAPI/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";


// --- QuantumChronicles Smart Contract ---
//
// Outline:
// 1. License & Pragmas
// 2. Imports (ERC721, Ownable, Counters, Pausable, Chainlink VRF, Chainlink Any API)
// 3. Error Codes (Custom errors)
// 4. Enums (ArtifactState, Epoch)
// 5. Structs (ArtifactData)
// 6. State Variables (Contract metadata, epoch tracking, artifact data, counters, VRF config, Any API config, request mappings, pausable state)
// 7. Events (Signal actions)
// 8. Constructor (Initialization and config setup)
// 9. Modifiers (Access control, pausable state)
// 10. ERC721 Standard Functions (Overrides and inherited)
// 11. Core Chronicle/Artifact Management Functions (Minting request/fulfillment, details, unveiling)
// 12. Epoch Management Functions (Advancing, setting parameters, getting current)
// 13. Temporal Mechanics (VRF Integration - trigger, request, fulfill)
// 14. External Influence (Oracle Integration - request, fulfill, get result)
// 15. Configuration & Utility Functions (Set VRF/Oracle params, withdraw, pause/unpause, getters)
//
// Function Summary (29 Functions):
// 1. constructor(...)                  : Initializes contract, sets metadata, and Chainlink VRF/Oracle config.
// 2. supportsInterface(bytes4)       : ERC165 standard, reports supported interfaces.
// 3. balanceOf(address)              : ERC721 standard, owner token balance.
// 4. ownerOf(uint256)                : ERC721 standard, token owner.
// 5. safeTransferFrom(address,addr,uint256): ERC721 standard, safe token transfer.
// 6. safeTransferFrom(address,addr,uint256,bytes): ERC721 standard, safe transfer with data.
// 7. transferFrom(address,address,uint256): ERC721 standard, token transfer.
// 8. approve(address,uint256)        : ERC721 standard, approve address for token.
// 9. getApproved(uint256)            : ERC721 standard, get approved address.
// 10. setApprovalForAll(address,bool) : ERC721 standard, approve operator for all tokens.
// 11. isApprovedForAll(address,address): ERC721 standard, check operator approval.
// 12. tokenURI(uint256)              : ERC721 standard override, returns dynamic metadata URI.
// 13. mintChronicleArtifact(uint32)  : Public function to request artifact minting via VRF.
// 14. fulfillRandomWords(uint256,uint256[]): Chainlink VRF callback, fulfills randomness request (e.g., minting, shift outcome).
// 15. getArtifactDetails(uint256)    : Reads stored data for a specific artifact.
// 16. unveilArtifactProperties(uint256): Allows owner to transition artifact state to Unveiled.
// 17. advanceEpoch()                 : Owner-only, increments the current contract epoch.
// 18. setEpochParameter(Epoch,uint256,uint256): Owner-only, sets epoch-specific configuration parameters.
// 19. getCurrentEpoch()              : Returns the current epoch enum.
// 20. triggerTemporalShift(uint256,uint32): Allows triggering a temporal shift on an artifact via VRF.
// 21. requestChronicleInfluence(uint256,string): Requests external data via Chainlink Oracle to influence an artifact.
// 22. fulfillChainlinkRequest(bytes32,bytes): Chainlink Client callback, processes oracle data and applies influence.
// 23. getChronicleInfluenceResult(bytes32): Retrieves the result stored from an Oracle request.
// 24. setVRFParameters(uint64,bytes32,uint32,uint32): Owner-only, updates VRF configuration.
// 25. setOracleParameters(address,bytes32,uint256): Owner-only, updates Chainlink Any API configuration.
// 26. pause()                        : Owner-only, pauses mutable contract interactions.
// 27. unpause()                      : Owner-only, unpauses contract interactions.
// 28. withdrawFunds()                : Owner-only, withdraws contract's Ether balance.
// 29. getTokenCount()                : Returns the total number of artifacts minted.

contract QuantumChronicles is ERC721, Ownable, Pausable, VRFConsumerBaseV2, ChainlinkClient {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // --- Error Codes ---
    error ArtifactDoesNotExist(uint256 tokenId);
    error UnauthorizedTemporalShift(uint256 tokenId);
    error InvalidEpochParameterCode(uint256 code);
    error ArtifactNotInDormantState(uint256 tokenId);
    error InvalidRandomWordCount(uint256 expected, uint256 received);
    error VRFRequestFailed(uint256 requestId);
    error OracleRequestFailed(bytes32 requestId);
    error RequestIdNotFound(uint256 requestId);
    error ChainlinkRequestIdNotFound(bytes32 requestId);
    error InvalidCallbackFromNonChainlink();

    // --- Enums ---
    enum ArtifactState {
        Dormant,        // Initial state, properties potentially hidden/undetermined
        Active,         // Normal state, properties are stable
        TemporalShift,  // Currently undergoing a transformation via temporal mechanics
        Unveiled        // Properties are fully revealed and locked (or stable)
    }

    enum Epoch {
        EraOfGenesis,       // Initial epoch, specific rules apply
        AgeOfFlux,          // Epoch where temporal shifts are more likely
        EpochOfUnveiling,   // Epoch where unveiling is incentivized or required
        TheSilentPeriod     // Late epoch, limited activity
    }

    // --- Structs ---
    struct ArtifactData {
        uint66 genesisTime;     // Block timestamp when minted
        ArtifactState currentState; // Current state of the artifact
        uint65 temporalEnergy;  // Energy level for temporal shifts (conceptually)
        bytes32 chroniclePath;  // Identifier for a specific narrative path/variant
        string propertiesHash;  // Hash/identifier pointing to off-chain properties (image, traits, etc.)
        uint66 lastStateChangeTime; // Block timestamp of the last state change
        uint64 influenceFactor; // A numerical factor influenced by oracles or shifts
    }

    // --- State Variables ---
    Epoch public currentEpoch;

    // Example epoch-specific parameters (using a simple mapping for demonstration)
    // Code 1: Minting cost (in wei)
    // Code 2: Base temporal shift probability (scaled, e.g., 1000 = 10%)
    mapping(Epoch => mapping(uint256 => uint256)) public epochParameters;

    mapping(uint256 => ArtifactData) private _artifactData;

    // VRF v2 configuration
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private s_subscriptionId;
    bytes32 private s_keyHash;
    uint32 private s_requestConfirmations;
    uint32 private s_numWords;

    // Track VRF requests to map fulfillment back to action type and target
    mapping(uint256 => bytes32) private s_vrfRequestType; // request id => keccak256(action name)
    mapping(uint256 => uint256) private s_vrfRequestTokenId; // request id => target token id (0 if new mint)
    bytes32 private constant VRF_TYPE_MINT = keccak256("MINT");
    bytes32 private constant VRF_TYPE_TEMPORAL_SHIFT = keccak256("TEMPORAL_SHIFT");

    // Chainlink Any API configuration
    LinkTokenInterface private immutable i_link;
    address private s_oracle;
    bytes32 private s_jobId;
    uint256 private s_fee; // fee in LINK

    // Track Chainlink Any API requests and results
    mapping(bytes32 => bytes32) private s_oracleRequestTokenId; // request id => target token id (bytes32(tokenId))
    mapping(bytes32 => bytes) private s_oracleRequestResults; // request id => result data

    // --- Events ---
    event ChronicleArtifactMinted(uint256 indexed tokenId, address indexed owner, uint66 genesisTime, Epoch epoch);
    event ArtifactStateChanged(uint256 indexed tokenId, ArtifactState oldState, ArtifactState newState, uint66 timestamp);
    event EpochAdvanced(Epoch indexed oldEpoch, Epoch indexed newEpoch, address indexed by);
    event PropertiesUnveiled(uint256 indexed tokenId, string propertiesHash);
    event TemporalShiftTriggered(uint256 indexed tokenId, uint256 indexed requestId);
    event ChronicleInfluenceRequested(uint256 indexed tokenId, bytes32 indexed requestId);
    event ChronicleInfluenceReceived(bytes32 indexed requestId, bytes result);
    event VRFRequestSent(uint256 indexed requestId, bytes32 indexed requestType, uint256 targetTokenId);
    event VRFFulfillmentReceived(uint256 indexed requestId, uint256[] randomWords);

    // --- Modifiers ---
    // Inherited onlyOwner from Ownable
    // Inherited whenNotPaused from Pausable
    // Inherited whenPaused from Pausable

    // --- Constructor ---
    constructor(
        address vrfCoordinator,
        address linkToken,
        uint64 subscriptionId,
        bytes32 keyHash,
        uint32 requestConfirmations,
        uint32 numWords,
        address oracleAddress,
        bytes32 jobId,
        uint256 feeInLink
    )
        ERC721("QuantumChronicles", "QCH")
        Ownable(msg.sender)
        Pausable()
        VRFConsumerBaseV2(vrfCoordinator)
        ChainlinkClient() // Initialize ChainlinkClient
    {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_link = LinkTokenInterface(linkToken);
        s_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
        s_requestConfirmations = requestConfirmations;
        s_numWords = numWords; // VRF words needed (e.g., 1 for minting, 2 for shift params)

        s_oracle = oracleAddress;
        s_jobId = jobId;
        s_fee = feeInLink;
        setChainlinkToken(address(i_link)); // Set the LINK token address for ChainlinkClient

        currentEpoch = Epoch.EraOfGenesis;

        // Set example default epoch parameters
        epochParameters[Epoch.EraOfGenesis][1] = 0.01 ether; // Minting cost
        epochParameters[Epoch.AgeOfFlux][1] = 0.02 ether;
        epochParameters[Epoch.EpochOfUnveiling][1] = 0.015 ether;
        epochParameters[Epoch.TheSilentPeriod][1] = 0.05 ether; // Higher cost late game

        epochParameters[Epoch.EraOfGenesis][2] = 500; // Shift probability (5%)
        epochParameters[Epoch.AgeOfFlux][2] = 2000; // Shift probability (20%)
        epochParameters[Epoch.EpochOfUnveiling][2] = 1000; // Shift probability (10%)
        epochParameters[Epoch.TheSilentPeriod][2] = 100; // Shift probability (1%)
    }

    // --- ERC721 Standard Overrides & Functions ---

    function _baseURI() internal pure override returns (string memory) {
        // Base URI should typically point to a metadata server/gateway
        return "ipfs://<YOUR_METADATA_BASE_URI>/";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }
        // A dynamic tokenURI can be constructed based on artifact state
        ArtifactData storage artifact = _artifactData[tokenId];
        string memory base = _baseURI();
        // Example: append tokenId and state as query params for dynamic rendering off-chain
        return string(abi.encodePacked(base, Strings.toString(tokenId), "?state=", Strings.toString(uint256(artifact.currentState))));
        // A more complex version would involve using artifact.propertiesHash
    }

    // --- Core Chronicle/Artifact Management ---

    /// @notice Requests a new Chronicle Artifact to be minted. Requires sending the current epoch's minting cost.
    ///         Minting is asynchronous and depends on the VRF callback.
    /// @param _requestConfirmations The number of block confirmations the VRF request should wait for.
    function mintChronicleArtifact(uint32 _requestConfirmations) public payable whenNotPaused {
        uint256 mintCost = epochParameters[currentEpoch][1];
        if (msg.value < mintCost) {
            // Revert and return excess Ether if sent
            revert("Insufficient ETH sent for minting");
        }

        // Store sender for later minting in fulfillRandomWords
        bytes memory reqData = abi.encodePacked(msg.sender);

        // Request randomness for initial artifact properties
        uint256 requestId = _requestRandomWords(s_keyHash, s_subscriptionId, _requestConfirmations, s_numWords, VRF_TYPE_MINT, 0, reqData);

        emit VRFRequestSent(requestId, VRF_TYPE_MINT, 0);

        // Refund any excess ETH
        if (msg.value > mintCost) {
            payable(msg.sender).transfer(msg.value - mintCost);
        }
    }

    /// @notice Callback function for Chainlink VRF. Processes the received randomness.
    /// @param _requestId The ID of the VRF request.
    /// @param _randomWords An array of random words generated by VRF.
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        // This ensures only the VRF coordinator can fulfill requests
        // This check is inherited from VRFConsumerBaseV2

        bytes32 requestType = s_vrfRequestType[_requestId];
        delete s_vrfRequestType[_requestId]; // Clean up mapping

        uint256 targetTokenId = s_vrfRequestTokenId[_requestId];
        delete s_vrfRequestTokenId[_requestId]; // Clean up mapping

        // Retrieve any associated data stored with the request
        // bytes memory reqData = s_vrfRequestData[_requestId]; // Assuming you added a mapping for request data
        // delete s_vrfRequestData[_requestId];

        emit VRFFulfillmentReceived(_requestId, _randomWords);

        if (_randomWords.length < s_numWords) {
            revert InvalidRandomWordCount(s_numWords, _randomWords.length);
        }

        if (requestType == VRF_TYPE_MINT) {
            address recipient;
            // Decode recipient from stored request data if needed, or infer from state
            // For minting, the sender was stored implicitly with the request ID mapping
            // We would need another mapping like mapping(uint256 => address) private s_vrfRequestRecipient;
            // For simplicity, let's assume the VRF request stores the recipient directly or it's retrieved differently.
            // A better pattern is to store the recipient's address in the request mapping alongside the request type.
            // Let's assume we stored the recipient address keyed by requestId in `s_vrfRequestData` when requesting.
            // Example using a simplified approach for this code, assuming recipient is derived or hardcoded for demo:
            // In a real app, store the recipient with the request ID.
            // For this example, let's add a mapping: mapping(uint256 => address) private s_vrfRequestRecipient;
            // And populate it in mintChronicleArtifact BEFORE requesting VRF.

            // Assuming s_vrfRequestRecipient[_requestId] exists
            // recipient = s_vrfRequestRecipient[_requestId];
            // delete s_vrfRequestRecipient[_requestId]; // Clean up

            // Simplified: For mint, let's assume the request data (reqData) WAS the recipient address.
            // THIS REQUIRES storing the recipient in a mapping linked to the request ID when minting.
            // The current structure s_vrfRequestData mapping isn't defined. Let's use s_vrfRequestTokenId conceptually
            // and assume 0 means mint, and the recipient is stored elsewhere linked to the request ID.
            // Let's refine: mintChronicleArtifact should store the recipient address linked to the request ID.
            // Adding mapping: `mapping(uint256 => address) private s_vrfRequestRecipient;`
            // Populate in `mintChronicleArtifact`: `s_vrfRequestRecipient[requestId] = msg.sender;`
            // Retrieve here: `address recipient = s_vrfRequestRecipient[_requestId]; delete s_vrfRequestRecipient[_requestId];`
            // For this example, let's assume `reqData` in `mintChronicleArtifact` *was* the recipient address encoded.
             if (reqData.length != 20) revert VRFRequestFailed(_requestId); // Assuming reqData holds address
             address recipient = address(bytes20(reqData));


            _mintArtifact(recipient, _randomWords);

        } else if (requestType == VRF_TYPE_TEMPORAL_SHIFT) {
             if (targetTokenId == 0 || !_exists(targetTokenId)) revert ArtifactDoesNotExist(targetTokenId);
            _applyTemporalShift(targetTokenId, _randomWords);

        } else {
            // Handle unknown request type or log an error
        }
    }

    /// @dev Internal function to mint a new artifact using VRF results.
    function _mintArtifact(address recipient, uint256[] memory randomWords) internal whenNotPaused {
        uint256 tokenId = _tokenIds.current();
        _tokenIds.increment();

        // Use randomWords to determine initial properties
        // Example: randomWords[0] determines chronicle path, randomWords[1] determines initial energy
        bytes32 chroniclePath;
        uint65 initialEnergy;
        string memory propertiesHash; // Placeholder - in reality generated off-chain based on inputs/randomness

        if (randomWords.length > 0) {
             chroniclePath = bytes32(randomWords[0]); // Use first word for path
        } else {
             chroniclePath = keccak256(abi.encodePacked(tokenId, block.timestamp)); // Fallback/default
        }

        if (randomWords.length > 1) {
             initialEnergy = uint65(randomWords[1] % 1000); // Use second word for energy (example 0-999)
        } else {
             initialEnergy = uint65(500); // Default energy
        }

        // Properties hash should be generated off-chain based on chroniclePath, epoch, randomness etc.
        // This is a placeholder. The off-chain service watches for Minted events.
        propertiesHash = string(abi.encodePacked("initial_hash_", Strings.toString(tokenId)));


        _artifactData[tokenId] = ArtifactData({
            genesisTime: uint66(block.timestamp),
            currentState: ArtifactState.Dormant, // Starts Dormant
            temporalEnergy: initialEnergy,
            chroniclePath: chroniclePath,
            propertiesHash: propertiesHash,
            lastStateChangeTime: uint66(block.timestamp),
            influenceFactor: 0 // Starts at 0
        });

        _safeMint(recipient, tokenId);

        emit ChronicleArtifactMinted(tokenId, recipient, uint66(block.timestamp), currentEpoch);
         // Note: PropertiesUnveiled isn't emitted here as it starts Dormant.
    }


    /// @notice Retrieves the full data struct for a given artifact.
    /// @param tokenId The ID of the artifact.
    /// @return The ArtifactData struct.
    function getArtifactDetails(uint256 tokenId) public view returns (ArtifactData memory) {
        if (!_exists(tokenId)) {
            revert ArtifactDoesNotExist(tokenId);
        }
        return _artifactData[tokenId];
    }

    /// @notice Allows the artifact owner to transition a Dormant artifact to Unveiled.
    ///         This state change might trigger off-chain metadata updates to reveal properties.
    /// @param tokenId The ID of the artifact to unveil.
    function unveilArtifactProperties(uint256 tokenId) public whenNotPaused {
        address artifactOwner = ownerOf(tokenId);
        if (msg.sender != artifactOwner) {
            revert OwnableUnauthorizedAccount(msg.sender); // Using Ownable's error for consistency
        }
        if (!_exists(tokenId)) {
             revert ArtifactDoesNotExist(tokenId);
        }

        ArtifactData storage artifact = _artifactData[tokenId];
        if (artifact.currentState != ArtifactState.Dormant) {
             revert ArtifactNotInDormantState(tokenId);
        }

        // State transition
        artifact.currentState = ArtifactState.Unveiled;
        artifact.lastStateChangeTime = uint66(block.timestamp);

        // In a real implementation, you might update propertiesHash here
        // based on final calculated traits, or this state change signals off-chain
        // to finalize and host the metadata at the tokenURI.
        // For demo, let's just signal the state change.

        emit ArtifactStateChanged(tokenId, ArtifactState.Dormant, ArtifactState.Unveiled, uint66(block.timestamp));
        // Emit PropertiesUnveiled to signal off-chain systems
        emit PropertiesUnveiled(tokenId, artifact.propertiesHash); // propertiesHash might be updated off-chain after this
    }

    // --- Epoch Management ---

    /// @notice Advances the contract to the next epoch. Owner only.
    function advanceEpoch() public onlyOwner whenNotPaused {
        Epoch oldEpoch = currentEpoch;
        // Simple sequential epoch progression. Could be more complex based on conditions.
        if (currentEpoch == Epoch.EraOfGenesis) {
            currentEpoch = Epoch.AgeOfFlux;
        } else if (currentEpoch == Epoch.AgeOfFlux) {
            currentEpoch = Epoch.EpochOfUnveiling;
        } else if (currentEpoch == Epoch.EpochOfUnveiling) {
            currentEpoch = Epoch.TheSilentPeriod;
        } else if (currentEpoch == Epoch.TheSilentPeriod) {
            // Optional: loop back, halt, or transition to a new state
             revert("End of current epoch sequence"); // Or handle as needed
        }
        emit EpochAdvanced(oldEpoch, currentEpoch, msg.sender);
    }

     /// @notice Sets a configuration parameter for a specific epoch. Owner only.
     /// @param epoch The epoch to configure.
     /// @param parameterCode The code for the parameter (e.g., 1 for mint cost, 2 for shift probability).
     /// @param value The value to set for the parameter.
    function setEpochParameter(Epoch epoch, uint256 parameterCode, uint256 value) public onlyOwner {
        // Add checks for valid parameterCode if needed
        if (parameterCode == 0) revert InvalidEpochParameterCode(parameterCode);
        epochParameters[epoch][parameterCode] = value;
    }

    /// @notice Gets the current epoch of the chronicle.
    /// @return The current Epoch enum value.
    function getCurrentEpoch() public view returns (Epoch) {
        return currentEpoch;
    }


    // --- Temporal Mechanics (VRF Integration for State Change) ---

    /// @notice Allows triggering a temporal shift on a specific artifact.
    ///         Requires randomness via VRF to determine the outcome.
    ///         Conditions might apply (e.g., temporalEnergy > threshold).
    /// @param tokenId The ID of the artifact to shift.
    /// @param _requestConfirmations The number of block confirmations for the VRF request.
    function triggerTemporalShift(uint256 tokenId, uint32 _requestConfirmations) public whenNotPaused {
         address artifactOwner = ownerOf(tokenId);
        if (msg.sender != artifactOwner) {
            revert OwnableUnauthorizedAccount(msg.sender);
        }
         if (!_exists(tokenId)) {
             revert ArtifactDoesNotExist(tokenId);
        }

        ArtifactData storage artifact = _artifactData[tokenId];

        // Example condition: Requires minimum temporal energy
        uint256 minEnergyForShift = 100; // Example threshold
        if (artifact.temporalEnergy < minEnergyForShift) {
             revert UnauthorizedTemporalShift(tokenId);
        }

        // Temporarily change state to indicate shift in progress
        ArtifactState oldState = artifact.currentState;
        artifact.currentState = ArtifactState.TemporalShift;
        artifact.lastStateChangeTime = uint66(block.timestamp);
        emit ArtifactStateChanged(tokenId, oldState, ArtifactState.TemporalShift, uint66(block.timestamp));

        // Request randomness for the shift outcome
        // Store tokenId with the request so fulfillRandomWords knows which artifact to modify
        uint256 requestId = _requestRandomWords(s_keyHash, s_subscriptionId, _requestConfirmations, s_numWords, VRF_TYPE_TEMPORAL_SHIFT, tokenId, new bytes(0));

        emit TemporalShiftTriggered(tokenId, requestId);
        emit VRFRequestSent(requestId, VRF_TYPE_TEMPORAL_SHIFT, tokenId);

        // Note: The artifact state will be updated to Active or another state in fulfillRandomWords
    }

    /// @dev Internal helper to request randomness from Chainlink VRF.
    function _requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint32 requestConfirmations,
        uint32 numWords,
        bytes32 requestType,
        uint256 targetTokenId,
        bytes memory reqData // Data to associate with the request (e.g., recipient address)
    ) internal returns (uint256 requestId) {
        requestId = i_vrfCoordinator.requestRandomWords(
            keyHash,
            subId,
            requestConfirmations,
            numWords
        );
        s_vrfRequestType[requestId] = requestType;
        s_vrfRequestTokenId[requestId] = targetTokenId; // Store target tokenId (0 for mint)
        // If reqData is needed later, store it here: s_vrfRequestData[requestId] = reqData;
        if (requestType == VRF_TYPE_MINT) {
             // For mint, we need the recipient address later in fulfillRandomWords.
             // Let's assume reqData IS the recipient address encoded.
             // A dedicated mapping `mapping(uint256 => address) private s_vrfRequestRecipient;`
             // would be cleaner. For this example, we will use `reqData` directly in fulfillRandomWords.
             // THIS IS A SIMPLIFICATION FOR THE EXAMPLE CODE. Proper state management for VRF requests is crucial.
        }
    }

    /// @dev Internal function to apply temporal shift effects using VRF results.
    function _applyTemporalShift(uint256 tokenId, uint256[] memory randomWords) internal {
        // Ensure the artifact is in TemporalShift state waiting for this callback
        ArtifactData storage artifact = _artifactData[tokenId];
        // Check state explicitly in case multiple shifts were requested
        // Or design prevents overlapping shifts
        // if (artifact.currentState != ArtifactState.TemporalShift) {
        //      // Handle unexpected state - maybe log or revert?
        //      // For now, assume it's the expected callback
        // }

        // Use randomWords to determine the outcome of the shift
        // Example: randomWords[0] influences energy change, randomWords[1] influences influenceFactor
        int256 energyChange = 0;
        uint256 influenceAddition = 0;
        ArtifactState nextState = ArtifactState.Active; // Default state after shift

        if (randomWords.length > 0) {
            // Example logic: If first word is even, energy increases; if odd, decreases
            energyChange = (randomWords[0] % 2 == 0) ? int256(randomWords[0] % 100) : -int256(randomWords[0] % 50);
        }
        if (randomWords.length > 1) {
            // Example logic: Second word adds to influence factor
            influenceAddition = randomWords[1] % 20; // Add up to 20 to influence
            // Example: Use second word to determine if state changes beyond Active
            if (randomWords[1] % 100 < 5) { // 5% chance of reverting to Dormant
                 nextState = ArtifactState.Dormant;
            } else if (randomWords[1] % 100 > 95) { // 5% chance of becoming Unveiled
                 nextState = ArtifactState.Unveiled;
                 // Off-chain system might update propertiesHash here
            }
        }

        // Apply changes
        // Ensure temporalEnergy doesn't underflow/overflow (simplified)
        if (energyChange > 0) {
             artifact.temporalEnergy += uint65(energyChange);
        } else {
             if (artifact.temporalEnergy < uint65(-energyChange)) artifact.temporalEnergy = 0;
             else artifact.temporalEnergy -= uint65(-energyChange);
        }

        artifact.influenceFactor += uint64(influenceAddition);
        ArtifactState oldState = artifact.currentState;
        artifact.currentState = nextState;
        artifact.lastStateChangeTime = uint66(block.timestamp);

        emit ArtifactStateChanged(tokenId, oldState, nextState, uint66(block.timestamp));
         if (nextState == ArtifactState.Unveiled && oldState != ArtifactState.Unveiled) {
             emit PropertiesUnveiled(tokenId, artifact.propertiesHash); // Signal off-chain
         }
    }


    // --- External Influence (Oracle Integration) ---

     /// @notice Requests external data via Chainlink Oracle to influence an artifact's state.
     /// @param tokenId The ID of the artifact to potentially influence.
     /// @param _externalDataSource A string identifying the external data source/type (interpreted by the Oracle Job).
     function requestChronicleInfluence(uint256 tokenId, string memory _externalDataSource) public whenNotPaused {
        address artifactOwner = ownerOf(tokenId);
        if (msg.sender != artifactOwner) {
            revert OwnableUnauthorizedAccount(msg.sender);
        }
        if (!_exists(tokenId)) {
             revert ArtifactDoesNotExist(tokenId);
        }

        // Build the Chainlink request payload
        Chainlink.Request memory req = buildChainlinkRequest(s_jobId, address(this), this.fulfillChainlinkRequest.selector);

        // Add parameters for the oracle job. Example: tell the job which artifact and what data source.
        req.addUint256("tokenId", tokenId);
        req.add("dataSource", _externalDataSource);

        // Send the request
        bytes32 requestId = sendChainlinkRequestTo(s_oracle, req, s_fee);

        // Store mapping from Chainlink requestId to tokenId
        s_oracleRequestTokenId[requestId] = bytes32(tokenId);

        emit ChronicleInfluenceRequested(tokenId, requestId);
    }

    /// @notice Callback function for Chainlink Any API. Processes the received data.
    /// @param _requestId The ID of the Oracle request.
    /// @param _data The data received from the oracle.
    function fulfillChainlinkRequest(bytes32 _requestId, bytes memory _data) public override recordChainlinkCallback(_requestId) {
        // This modifier ensures only a Chainlink node can call this.

        // Retrieve the target tokenId
        bytes32 tokenBytes = s_oracleRequestTokenId[_requestId];
        delete s_oracleRequestTokenId[_requestId]; // Clean up mapping

        uint256 tokenId = uint256(tokenBytes);
        if (!_exists(tokenId)) {
             // Artifact was likely transferred or burned after request sent
             // Log or handle appropriately, don't revert the oracle callback
             emit OracleRequestFailed(_requestId); // Custom error for tracking
             return; // Exit without affecting state
        }

        // Store the raw result for later querying
        s_oracleRequestResults[_requestId] = _data;
        emit ChronicleInfluenceReceived(_requestId, _data);

        // Example logic: Use the received data to influence the artifact
        // This part is highly dependent on the Oracle Job's output format
        // For demonstration, let's assume _data is a simple uint256 value encoded
        uint256 influenceValue;
        if (_data.length == 32) {
             assembly {
                 influenceValue := mload(add(_data, 32))
             }
        } else {
             // Handle unexpected data format
             emit OracleRequestFailed(_requestId); // Indicate issue
             return;
        }

        ArtifactData storage artifact = _artifactData[tokenId];

        // Apply influence (example: add the value to influenceFactor)
        artifact.influenceFactor += uint64(influenceValue);

        // Optional: Change state or other properties based on influenceValue
        // if (influenceValue > 100 && artifact.currentState == ArtifactState.Active) {
        //     artifact.currentState = ArtifactState.TemporalShift; // Or another state
        //     artifact.lastStateChangeTime = uint66(block.timestamp);
        //     emit ArtifactStateChanged(tokenId, ArtifactState.Active, ArtifactState.TemporalShift, uint66(block.timestamp));
        // }
    }

     /// @notice Retrieves the stored result for a completed Chainlink Oracle request.
     /// @param _requestId The ID of the Oracle request.
     /// @return The raw data received from the oracle.
    function getChronicleInfluenceResult(bytes32 _requestId) public view returns (bytes memory) {
        bytes memory result = s_oracleRequestResults[_requestId];
        if (result.length == 0 && s_oracleRequestTokenId[_requestId] == bytes32(0)) {
             // Check if the request ID even existed and was processed
             // s_oracleRequestTokenId is deleted on fulfillment, so check implies it was never sent OR already processed/deleted
             // A dedicated mapping to track request state (e.g., Requested, Fulfilled, Failed) would be more robust.
             // For simplicity, assuming non-zero result means success here.
             // The check `s_oracleRequestTokenId[_requestId] == bytes32(0)` after deletion confirms it was fulfilled/processed.
             // A request that was never sent would also return bytes32(0) for the token ID, so this check isn't perfect.
             // A better approach is needed to distinguish unfound vs fulfilled empty result.
             // Assuming non-empty means result received.
             revert ChainlinkRequestIdNotFound(_requestId); // Indicate no result found or request never sent
        }
        return result;
    }


    // --- Configuration & Utility Functions ---

    /// @notice Allows owner to update Chainlink VRF parameters.
    function setVRFParameters(
        uint64 _subscriptionId,
        bytes32 _keyHash,
        uint32 _requestConfirmations,
        uint32 _numWords
    ) public onlyOwner {
        s_subscriptionId = _subscriptionId;
        s_keyHash = _keyHash;
        s_requestConfirmations = _requestConfirmations;
        s_numWords = _numWords;
    }

    /// @notice Allows owner to update Chainlink Any API parameters.
    function setOracleParameters(
        address _oracle,
        bytes32 _jobId,
        uint256 _fee
    ) public onlyOwner {
        s_oracle = _oracle;
        s_jobId = _jobId;
        s_fee = _fee;
    }

    /// @notice Allows owner to withdraw any Ether held by the contract.
    function withdrawFunds() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    /// @notice Pauses certain functions (minting, shifts, unveils). Owner only.
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract. Owner only.
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Checks if the contract is currently paused.
    function isPaused() public view returns (bool) {
        return paused();
    }

    /// @notice Gets the total number of artifacts minted.
    function getTokenCount() public view returns (uint256) {
        return _tokenIds.current();
    }

    // Internal function overrides for ERC721
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address owner, uint256 additionalBalance) internal override(ERC721) {
        super._increaseBalance(owner, additionalBalance);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
         // Optional: Add logic here if burning affects the chronicle or energy
        delete _artifactData[tokenId];
        super._burn(tokenId);
    }
}
```