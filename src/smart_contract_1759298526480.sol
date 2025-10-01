The `ChronoGlyphGenesis` smart contract introduces a novel concept of "Dynamic NFTs" (dNFTs) that represent evolving digital organisms or art pieces. These ChronoGlyphs are not static images or data, but rather living entities whose traits and appearance can change based on various on-chain and off-chain interactions.

The core idea is to blend:
1.  **Immutable Genetic Code:** A foundational set of parameters for each ChronoGlyph, set at creation.
2.  **Dynamic State:** Traits that evolve based on:
    *   **Environmental Influence:** Data fed from trusted oracles (e.g., real-world weather, market sentiment, block data).
    *   **User Interaction:** Owners actively "nurture" their glyphs through on-chain actions and token deposits, influencing their growth and lifecycle.
    *   **AI Agent Insights:** Owners can commission external AI agents to analyze their glyph's state and propose "mutations" or "upgrades," which, if accepted, alter the glyph's dynamic metadata.
3.  **Lifecycle:** ChronoGlyphs progress through stages (Larva, Juvenile, Mature, Elder), unlocking new capabilities like spawning progeny.

This contract goes beyond typical NFT standards by providing mechanisms for profound on-chain and off-chain interaction, verifiable AI integration, and a dynamic lifecycle, creating a truly unique and evolving digital asset.

---

## Contract: `ChronoGlyphGenesis`

**Description:**
`ChronoGlyphGenesis` is a sophisticated, decentralized platform for minting and managing "ChronoGlyphs," which are dynamic NFTs (dNFTs) representing evolving digital organisms or art pieces. Each ChronoGlyph possesses a unique "genetic code" (immutable on-chain parameters) and a "dynamic state" influenced by environmental data (via oracles), user interactions, and insights from commissioned AI agents. Owners can nurture their ChronoGlyphs, commission AI coaches for "mutations" or "upgrades," and even facilitate the spawning of new "progeny," creating a rich, evolving digital ecosystem.

---

### Function Summary:

**I. Core ChronoGlyph Management (ERC721 & Base Functions):**

1.  `constructor()`
    *   **Description:** Initializes the contract with an admin (owner), base metadata URI, trusted oracle address, trusted verifier address, and initial prices for genesis minting, nurturing, and progeny spawning.
2.  `mintGenesisChronoGlyph()`
    *   **Description:** Allows users to mint a brand new, first-generation ChronoGlyph. The initial genetic hash is derived pseudo-randomly from block data and sender. Requires payment of `genesisPrice`.
    *   **Returns:** The ID of the newly minted ChronoGlyph.
3.  `tokenURI(uint256 tokenId)`
    *   **Description:** Returns the dynamic metadata URI for a given ChronoGlyph. This URI points to external data (e.g., IPFS gateway, API endpoint) that describes the ChronoGlyph's current visual representation and dynamic traits, composed from its genetic code and current dynamic state.
4.  `getChronoGlyphState(uint256 tokenId)`
    *   **Description:** Retrieves all detailed state information (genetic hash, genesis block, nurture count, life stage, dynamic metadata URI, etc.) for a specific ChronoGlyph.

**II. Evolution & Lifecycle Mechanics:**

5.  `nurtureChronoGlyph(uint256 tokenId)`
    *   **Description:** Allows the owner to "nurture" their ChronoGlyph by making a small ETH deposit (`nurturingFee`). This interaction updates the glyph's `lastNurturedBlock` and `nurturedCount`, influencing its internal "growth" and potentially advancing its `LifeStage`.
6.  `requestEnvironmentalUpdate(uint256 tokenId)`
    *   **Description:** Triggers a request for the registered oracle to update environmental data for a ChronoGlyph. This function sets up a call for off-chain oracle services to fetch relevant data, which would then call back `_updateGlyphEnvironmentalMetadata`.
7.  `_updateGlyphEnvironmentalMetadata(uint256 tokenId, string memory newEnvironmentalMetadataURI, bytes32 environmentalHash)` (Internal/Oracle-only)
    *   **Description:** An internal function, callable only by the `oracleAddress`, to update a ChronoGlyph's dynamic metadata URI based on new environmental data. This is the callback mechanism for oracle integrations.
8.  `spawnProgeny(uint256 parentTokenId, address newOwner, bytes32 progenyGeneticModifier)`
    *   **Description:** Allows a `Mature` or `Elder` ChronoGlyph to "spawn" a new ChronoGlyph. The progeny inherits traits from the parent and incorporates a `progenyGeneticModifier` for diversity. Requires a `proliferationFee` based on the parent's `nurturedCount` and `proliferationFeeBasis`.
    *   **Returns:** The ID of the newly spawned progeny ChronoGlyph.
9.  `proposeGeneticMutation(uint256 tokenId, bytes32 newGeneticParamHash)`
    *   **Description:** Initiates a proposal by the owner to permanently alter a ChronoGlyph's core `geneticHash`. This is a significant, high-impact action that requires a separate, trusted off-chain verification step before execution.
10. `executeGeneticMutation(uint256 tokenId, bytes32 newGeneticParamHash, bytes memory signature)`
    *   **Description:** Finalizes a proposed genetic mutation. This function is callable *only* by the designated `verifierAddress` and requires a valid ECDSA signature from this verifier, confirming the mutation's legitimacy, before the `geneticHash` is updated.

**III. AI Agent Interaction & Commissioning:**

11. `registerAIModule(address aiAgentContractAddress, string memory name, string memory description)`
    *   **Description:** An admin function to whitelist external AI Agent contracts. Only registered and active AI modules can submit suggestions.
12. `updateAIModuleInfo(address aiAgentContractAddress, string memory name, string memory description)`
    *   **Description:** Allows the contract owner to update the name and description of an already registered AI module.
13. `deactivateAIModule(address aiAgentContractAddress)`
    *   **Description:** An admin function to deactivate a registered AI module. Deactivated agents can no longer submit new suggestions (e.g., in case of malicious behavior or inactivity).
14. `commissionAICoach(uint256 tokenId, address aiAgentContract, uint256 feeAmount)`
    *   **Description:** Allows a ChronoGlyph owner to commission a registered AI agent to analyze their glyph and propose changes. The specified `feeAmount` is directly transferred to the AI agent contract.
15. `submitAICoachSuggestion(uint256 tokenId, string memory suggestedMetadataURI, bytes memory proof)`
    *   **Description:** Callable *only* by a registered and active AI Agent contract. The AI submits a proposed `suggestedMetadataURI` for a ChronoGlyph, along with a `proof` (placeholder for verifiable computation) of its analysis. The suggestion enters a `Pending` state.
16. `acceptAICoachSuggestion(uint256 tokenId, uint256 suggestionId)`
    *   **Description:** Allows the ChronoGlyph owner to accept a pending AI suggestion. Upon acceptance, the glyph's `dynamicMetadataURI` is updated to the AI's suggestion, and the suggestion's status changes to `Accepted`.
17. `rejectAICoachSuggestion(uint256 tokenId, uint256 suggestionId)`
    *   **Description:** Allows the ChronoGlyph owner to reject a pending AI suggestion, marking its status as `Rejected`.
18. `getAICoachSuggestions(uint256 tokenId)`
    *   **Description:** A view function that returns all past and pending `AISuggestion` structs for a specific ChronoGlyph.

**IV. Administration & Control:**

19. `setBaseURI(string memory _newBaseURI)`
    *   **Description:** An admin function to update the base URI component used in `tokenURI`.
20. `setOracleAddress(address _newOracleAddress)`
    *   **Description:** An admin function to update the address of the trusted oracle contract/service.
21. `setVerifierAddress(address _newVerifierAddress)`
    *   **Description:** An admin function to update the address of the trusted off-chain verifier responsible for approving genetic mutations.
22. `setGenesisPrice(uint256 _newPrice)`
    *   **Description:** An admin function to adjust the price (in wei) for minting new genesis ChronoGlyphs.
23. `setNurturingFee(uint256 _newFee)`
    *   **Description:** An admin function to adjust the fee (in wei) required for nurturing a ChronoGlyph.
24. `setProliferationFeeBasis(uint256 _newBasis)`
    *   **Description:** An admin function to set a multiplier for calculating the progeny spawning fee. This allows dynamic fee adjustments based on factors like parent glyph's nurtured count.
25. `withdrawFunds()`
    *   **Description:** Allows the contract owner to withdraw any accumulated ETH (from minting, nurturing, proliferation fees) from the contract balance.
26. `pause()`
    *   **Description:** An admin function to pause most state-changing functions in the contract, inherited from OpenZeppelin's `Pausable` module.
27. `unpause()`
    *   **Description:** An admin function to unpause the contract, re-enabling state-changing functions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For converting uint to string
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // For verifying signatures from verifier

/**
 * @title ChronoGlyphGenesis
 * @dev A sophisticated, decentralized platform for minting and managing "ChronoGlyphs,"
 *      which are dynamic NFTs (dNFTs) representing evolving digital organisms or art pieces.
 *      Each ChronoGlyph possesses a unique "genetic code" (immutable on-chain parameters)
 *      and a "dynamic state" influenced by environmental data (via oracles), user interactions,
 *      and insights from commissioned AI agents. Owners can nurture their ChronoGlyphs,
 *      commission AI coaches for "mutations" or "upgrades," and even facilitate the spawning
 *      of new "progeny," creating a rich, evolving digital ecosystem.
 */
contract ChronoGlyphGenesis is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Error Definitions ---
    error InvalidTokenId();
    error NotGlyphOwner();
    error NotRegisteredOracle();
    error NotRegisteredAIAgent();
    error AIAgentAlreadyRegistered();
    error AIAgentNotActive();
    error InsufficientPayment();
    error AlreadyProposedMutation();
    error MutationNotProposed();
    error NotAuthorizedVerifier();
    error InvalidSignature();
    error ProgenyNotMatureEnough();
    error SuggestionNotFoundOrInvalid();
    error SuggestionAlreadyProcessed();
    error CannotSelfCommissionAI();
    error MaxAICommissionFeeExceeded();
    error InvalidProliferationBasis();

    // --- Events ---
    event ChronoGlyphMinted(uint256 indexed tokenId, address indexed owner, bytes32 geneticHash, uint256 genesisBlock);
    event ChronoGlyphNurtured(uint256 indexed tokenId, address indexed nurturer, uint256 amount);
    event EnvironmentalDataUpdated(uint256 indexed tokenId, bytes32 environmentalHash, uint256 timestamp);
    event AIAgentRegistered(address indexed aiAgent, string name, string description);
    event AIAgentDeactivated(address indexed aiAgent);
    event AIAgentCommissioned(uint256 indexed tokenId, address indexed owner, address indexed aiAgent, uint256 fee);
    event AISuggestionSubmitted(uint256 indexed tokenId, uint256 indexed suggestionId, address indexed aiAgent, string suggestedMetadataURI);
    event AISuggestionAccepted(uint256 indexed tokenId, uint256 indexed suggestionId, address indexed accepter);
    event AISuggestionRejected(uint256 indexed tokenId, uint256 indexed suggestionId, address indexed rejecter);
    event ProgenySpawned(uint256 indexed parentTokenId, uint256 indexed progenyTokenId, address indexed newOwner, bytes32 progenyGeneticModifier);
    event GeneticMutationProposed(uint256 indexed tokenId, bytes32 newGeneticHash, address indexed proposer);
    event GeneticMutationExecuted(uint256 indexed tokenId, bytes32 newGeneticHash, address indexed executor);
    event BaseURIUpdated(string newURI);
    event GenesisPriceUpdated(uint256 newPrice);
    event NurturingFeeUpdated(uint256 newFee);
    event ProliferationFeeBasisUpdated(uint256 newBasis);

    // --- Structs & Enums ---

    enum LifeStage { Larva, Juvenile, Mature, Elder, Dormant }
    enum SuggestionStatus { Pending, Accepted, Rejected }

    struct ChronoGlyph {
        bytes32 geneticHash;           // Immutable core "DNA"
        uint256 genesisBlock;          // Block when it was minted
        uint256 lastNurturedBlock;     // Block when it was last nurtured by owner
        uint256 lastEnvironmentalUpdateBlock; // Block when env data was last updated
        LifeStage currentStage;        // Current life stage, evolves over time
        string dynamicMetadataURI;     // Evolving URI for dynamic traits (AI suggestions, env data)
        uint256 nurturedCount;         // How many times it has been nurtured
        uint256 progenyCount;          // How many progeny it has spawned
        bytes32 proposedMutationHash;  // Hash of genetic mutation proposed, 0 if none
    }

    struct AICoachModule {
        string name;
        string description;
        bool isActive;
    }

    struct AISuggestion {
        address aiAgent;
        string suggestedMetadataURI;
        uint256 timestamp;
        SuggestionStatus status;
    }

    // --- State Variables ---

    string private _baseURI;
    address public oracleAddress; // Address of the trusted oracle contract/service (can be a multisig)
    address public verifierAddress; // Address of the trusted off-chain verifier for genetic mutations (can be a multisig)

    uint256 public genesisPrice;     // Price to mint a new genesis ChronoGlyph (in wei)
    uint256 public nurturingFee;     // Fee for nurturing a ChronoGlyph (in wei)
    uint256 public proliferationFeeBasis; // Basis multiplier for progeny spawning fee (e.g., 1000 = 1 ETH per progeny if nurturedCount is 1000, or (nurturedCount * basis) / 1000)

    mapping(uint256 => ChronoGlyph) private _chronoGlyphs;
    mapping(address => AICoachModule) public registeredAIAgents;
    mapping(uint256 => AISuggestion[]) private _aiSuggestions; // tokenId -> array of suggestions

    // For tracking internal suggestion IDs (1-based)
    mapping(uint256 => Counters.Counter) private _aiSuggestionCounters;

    // --- Constructor ---

    constructor(
        address initialOwner,
        string memory name,
        string memory symbol,
        string memory initialBaseURI,
        address initialOracleAddress,
        address initialVerifierAddress,
        uint256 _genesisPrice,
        uint256 _nurturingFee,
        uint256 _proliferationFeeBasis
    )
        ERC721(name, symbol)
        Ownable(initialOwner)
        Pausable()
    {
        _baseURI = initialBaseURI;
        oracleAddress = initialOracleAddress;
        verifierAddress = initialVerifierAddress;
        genesisPrice = _genesisPrice;
        nurturingFee = _nurturingFee;
        proliferationFeeBasis = _proliferationFeeBasis;
    }

    // --- I. Core ChronoGlyph Management (ERC721 & Base Functions) ---

    /**
     * @dev Mints a new, first-generation ChronoGlyph.
     *      The initial genetic hash is derived from the minter's address and timestamp for pseudo-randomness.
     *      Requires payment of `genesisPrice`.
     * @return The ID of the newly minted ChronoGlyph.
     */
    function mintGenesisChronoGlyph() external payable whenNotPaused returns (uint256) {
        if (msg.value < genesisPrice) {
            revert InsufficientPayment();
        }

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Simple pseudo-random genetic hash for genesis glyphs
        bytes32 geneticHash = keccak256(abi.encodePacked(msg.sender, block.timestamp, newTokenId, block.difficulty, genesisPrice));
        string memory initialDynamicMetadataURI = string(abi.encodePacked(_baseURI, "initial/", Strings.toString(newTokenId), ".json"));

        _chronoGlyphs[newTokenId] = ChronoGlyph({
            geneticHash: geneticHash,
            genesisBlock: block.number,
            lastNurturedBlock: block.number,
            lastEnvironmentalUpdateBlock: block.number,
            currentStage: LifeStage.Larva,
            dynamicMetadataURI: initialDynamicMetadataURI,
            nurturedCount: 0,
            progenyCount: 0,
            proposedMutationHash: bytes32(0)
        });

        _mint(msg.sender, newTokenId);
        emit ChronoGlyphMinted(newTokenId, msg.sender, geneticHash, block.number);
        return newTokenId;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     *      Returns a composed URI for the token's metadata, combining the base URI
     *      with the ChronoGlyph's current dynamic state URI.
     *      This `dynamicMetadataURI` is expected to point to an external source (e.g., IPFS, API)
     *      that provides the most up-to-date metadata reflecting all changes.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        ChronoGlyph storage glyph = _chronoGlyphs[tokenId];
        // The dynamicMetadataURI stored in the struct is already the full dynamic part.
        // It could be an IPFS hash, a specific API endpoint, or just a path.
        // It's the responsibility of the oracle/AI agent to update this field correctly.
        return glyph.dynamicMetadataURI;
    }

    /**
     * @dev Retrieves all detailed state information for a ChronoGlyph.
     * @param tokenId The ID of the ChronoGlyph.
     * @return ChronoGlyph struct containing all its attributes.
     */
    function getChronoGlyphState(uint256 tokenId) public view returns (ChronoGlyph memory) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        return _chronoGlyphs[tokenId];
    }

    // --- II. Evolution & Lifecycle Mechanics ---

    /**
     * @dev Allows the owner to "nurture" their ChronoGlyph, influencing its growth.
     *      Updates `lastNurturedBlock` and `nurturedCount`.
     *      Requires payment of `nurturingFee`.
     * @param tokenId The ID of the ChronoGlyph to nurture.
     */
    function nurtureChronoGlyph(uint256 tokenId) external payable whenNotPaused {
        if (msg.sender != ownerOf(tokenId)) {
            revert NotGlyphOwner();
        }
        if (msg.value < nurturingFee) {
            revert InsufficientPayment();
        }

        ChronoGlyph storage glyph = _chronoGlyphs[tokenId];
        glyph.lastNurturedBlock = block.number;
        glyph.nurturedCount++;

        // Basic stage evolution logic: Can be made more complex with time elapsed, etc.
        if (glyph.currentStage == LifeStage.Larva && glyph.nurturedCount >= 5) {
            glyph.currentStage = LifeStage.Juvenile;
        } else if (glyph.currentStage == LifeStage.Juvenile && glyph.nurturedCount >= 15 && (block.number - glyph.genesisBlock) >= 100) {
            glyph.currentStage = LifeStage.Mature;
        } // More stages and conditions (e.g., requiring AI suggestions) can be added here.

        emit ChronoGlyphNurtured(tokenId, msg.sender, msg.value);
    }

    /**
     * @dev Triggers a request for the registered oracle to update environmental data for a ChronoGlyph.
     *      This function would typically involve making a call to an external oracle contract (e.g., Chainlink, Pyth)
     *      which would then provide the requested data back to `_updateGlyphEnvironmentalMetadata` via a callback.
     *      For simplicity, this function acts as a placeholder for initiating such a request.
     * @param tokenId The ID of the ChronoGlyph.
     */
    function requestEnvironmentalUpdate(uint256 tokenId) external whenNotPaused {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        // In a full implementation, this would involve a specific oracle interface call,
        // e.g., ChainlinkClient.requestData(jobId, url, path, callbackFunction).
        // This function just provides the entry point for such a mechanism.
        // The actual update is done by the oracle calling `_updateGlyphEnvironmentalMetadata`.
        // emit EnvironmentalUpdateRequest(tokenId, block.timestamp); // Could emit an event for an off-chain listener to pick up
    }

    /**
     * @dev Internal function called by the trusted oracle to update a glyph's dynamic metadata
     *      based on environmental data.
     *      Only callable by the designated `oracleAddress`.
     * @param tokenId The ID of the ChronoGlyph.
     * @param newEnvironmentalMetadataURI The new URI reflecting environmental changes.
     * @param environmentalHash A hash representing the environmental data for integrity verification.
     */
    function _updateGlyphEnvironmentalMetadata(uint256 tokenId, string memory newEnvironmentalMetadataURI, bytes32 environmentalHash) external {
        if (msg.sender != oracleAddress) {
            revert NotRegisteredOracle();
        }
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }

        ChronoGlyph storage glyph = _chronoGlyphs[tokenId];
        glyph.dynamicMetadataURI = newEnvironmentalMetadataURI;
        glyph.lastEnvironmentalUpdateBlock = block.number;

        emit EnvironmentalDataUpdated(tokenId, environmentalHash, block.timestamp);
    }

    /**
     * @dev Allows a mature ChronoGlyph to "spawn" a new one, inheriting and modifying traits.
     *      A fee is calculated based on `proliferationFeeBasis` and parent's `nurturedCount`.
     * @param parentTokenId The ID of the parent ChronoGlyph.
     * @param newOwner The address of the new owner for the progeny.
     * @param progenyGeneticModifier A hash or data to influence the progeny's genetic code, adding diversity.
     * @return The ID of the newly spawned progeny ChronoGlyph.
     */
    function spawnProgeny(
        uint256 parentTokenId,
        address newOwner,
        bytes32 progenyGeneticModifier
    ) external payable whenNotPaused returns (uint256) {
        if (msg.sender != ownerOf(parentTokenId)) {
            revert NotGlyphOwner();
        }
        if (!_exists(parentTokenId)) {
            revert InvalidTokenId();
        }
        ChronoGlyph storage parentGlyph = _chronoGlyphs[parentTokenId];
        if (parentGlyph.currentStage != LifeStage.Mature && parentGlyph.currentStage != LifeStage.Elder) {
            revert ProgenyNotMatureEnough();
        }

        uint256 proliferationFee = (parentGlyph.nurturedCount * proliferationFeeBasis) / 1000; // Example: 1000 means 1:1 ETH to nurturedCount ratio if basis is 1 ETH.
        if (msg.value < proliferationFee) {
            revert InsufficientPayment();
        }

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Genetic blend: Parent's geneticHash + progenyGeneticModifier for unique new genetics
        bytes32 newGeneticHash = keccak256(abi.encodePacked(parentGlyph.geneticHash, progenyGeneticModifier, block.timestamp, newTokenId));
        string memory initialDynamicMetadataURI = string(abi.encodePacked(_baseURI, "progeny/", Strings.toString(newTokenId), ".json"));

        _chronoGlyphs[newTokenId] = ChronoGlyph({
            geneticHash: newGeneticHash,
            genesisBlock: block.number,
            lastNurturedBlock: block.number,
            lastEnvironmentalUpdateBlock: block.number,
            currentStage: LifeStage.Larva, // Progeny always starts as Larva
            dynamicMetadataURI: initialDynamicMetadataURI,
            nurturedCount: 0,
            progenyCount: 0,
            proposedMutationHash: bytes32(0)
        });

        _mint(newOwner, newTokenId);
        parentGlyph.progenyCount++;
        emit ProgenySpawned(parentTokenId, newTokenId, newOwner, progenyGeneticModifier);
        return newTokenId;
    }

    /**
     * @dev Initiates a highly impactful, permanent change to a ChronoGlyph's core genetic code.
     *      This proposal needs to be verified off-chain by the `verifierAddress` before execution.
     * @param tokenId The ID of the ChronoGlyph to mutate.
     * @param newGeneticParamHash The proposed new genetic hash.
     */
    function proposeGeneticMutation(uint256 tokenId, bytes32 newGeneticParamHash) external whenNotPaused {
        if (msg.sender != ownerOf(tokenId)) {
            revert NotGlyphOwner();
        }
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        ChronoGlyph storage glyph = _chronoGlyphs[tokenId];
        if (glyph.proposedMutationHash != bytes32(0)) {
            revert AlreadyProposedMutation();
        }

        glyph.proposedMutationHash = newGeneticParamHash;
        emit GeneticMutationProposed(tokenId, newGeneticParamHash, msg.sender);
    }

    /**
     * @dev Finalizes a proposed genetic mutation after off-chain verification.
     *      Only callable by the designated `verifierAddress`. The `signature` is a proof
     *      from the verifier that the mutation parameters are valid and approved.
     * @param tokenId The ID of the ChronoGlyph.
     * @param newGeneticParamHash The new genetic hash that was proposed.
     * @param signature An ECDSA signature from the `verifierAddress` confirming the mutation.
     */
    function executeGeneticMutation(uint256 tokenId, bytes32 newGeneticParamHash, bytes memory signature) external whenNotPaused {
        if (msg.sender != verifierAddress) {
            revert NotAuthorizedVerifier();
        }
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        ChronoGlyph storage glyph = _chronoGlyphs[tokenId];
        if (glyph.proposedMutationHash != newGeneticParamHash || glyph.proposedMutationHash == bytes32(0)) {
            revert MutationNotProposed();
        }

        // Verify the signature. The verifier signs a hash of (tokenId, newGeneticParamHash)
        bytes32 messageHash = keccak256(abi.encodePacked(tokenId, newGeneticParamHash));
        bytes32 signedHash = ECDSA.toEthSignedMessageHash(messageHash); // Prefix with "\x19Ethereum Signed Message:\n32"
        if (ECDSA.recover(signedHash, signature) != verifierAddress) {
            revert InvalidSignature();
        }

        glyph.geneticHash = newGeneticParamHash;
        glyph.proposedMutationHash = bytes32(0); // Reset proposal after execution
        emit GeneticMutationExecuted(tokenId, newGeneticParamHash, msg.sender);
    }

    // --- III. AI Agent Interaction & Commissioning ---

    /**
     * @dev Admin function to whitelist external AI Agent contracts.
     *      Registered agents are allowed to submit suggestions via `submitAICoachSuggestion`.
     * @param aiAgentContractAddress The address of the AI agent contract.
     * @param name The name of the AI module.
     * @param description A brief description of its capabilities.
     */
    function registerAIModule(address aiAgentContractAddress, string memory name, string memory description) external onlyOwner {
        if (registeredAIAgents[aiAgentContractAddress].isActive) {
            revert AIAgentAlreadyRegistered();
        }
        registeredAIAgents[aiAgentContractAddress] = AICoachModule(name, description, true);
        emit AIAgentRegistered(aiAgentContractAddress, name, description);
    }

    /**
     * @dev Admin function to update details for a registered AI module.
     * @param aiAgentContractAddress The address of the AI agent contract.
     * @param name The new name of the AI module.
     * @param description A new description of its capabilities.
     */
    function updateAIModuleInfo(address aiAgentContractAddress, string memory name, string memory description) external onlyOwner {
        if (!registeredAIAgents[aiAgentContractAddress].isActive) {
            revert NotRegisteredAIAgent();
        }
        registeredAIAgents[aiAgentContractAddress].name = name;
        registeredAIAgents[aiAgentContractAddress].description = description;
        // No event for update as it's less critical than registration/deactivation
    }

    /**
     * @dev Deactivates a registered AI module (e.g., if it's malicious or inactive).
     *      Deactivated agents cannot submit new suggestions.
     * @param aiAgentContractAddress The address of the AI agent contract to deactivate.
     */
    function deactivateAIModule(address aiAgentContractAddress) external onlyOwner {
        if (!registeredAIAgents[aiAgentContractAddress].isActive) {
            revert AIAgentNotActive(); // Can only deactivate active agents
        }
        registeredAIAgents[aiAgentContractAddress].isActive = false;
        emit AIAgentDeactivated(aiAgentContractAddress);
    }

    /**
     * @dev Owner commissions a registered AI agent to analyze their ChronoGlyph and propose changes.
     *      The `feeAmount` specified is sent directly to the AI agent contract.
     * @param tokenId The ID of the ChronoGlyph.
     * @param aiAgentContract The address of the AI agent to commission.
     * @param feeAmount The amount of ETH to pay the AI agent.
     */
    function commissionAICoach(uint256 tokenId, address aiAgentContract, uint256 feeAmount) external payable whenNotPaused {
        if (msg.sender != ownerOf(tokenId)) {
            revert NotGlyphOwner();
        }
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        if (!registeredAIAgents[aiAgentContract].isActive) {
            revert NotRegisteredAIAgent();
        }
        if (msg.value < feeAmount) {
            revert InsufficientPayment();
        }
        if (aiAgentContract == address(0) || aiAgentContract == address(this)) {
            revert CannotSelfCommissionAI();
        }
        // Example sanity check for fee: limit commission fee to 1 ETH to prevent accidental overpayment
        if (feeAmount > 1 ether) {
             revert MaxAICommissionFeeExceeded();
        }

        // Transfer fee to the AI agent contract (assuming it's a payable contract)
        (bool success, ) = payable(aiAgentContract).call{value: feeAmount}("");
        require(success, "AI agent payment failed");

        emit AIAgentCommissioned(tokenId, msg.sender, aiAgentContract, feeAmount);
    }

    /**
     * @dev Callable by an *authorized* and *active* AI Agent contract to submit a verified suggestion
     *      for dynamic metadata update. `proof` is a placeholder for verifiable computation.
     * @param tokenId The ID of the ChronoGlyph.
     * @param suggestedMetadataURI The new dynamic metadata URI proposed by the AI.
     * @param proof Placeholder for a verification proof (e.g., ZKP, signed attestation from a trusted party).
     */
    function submitAICoachSuggestion(
        uint256 tokenId,
        string memory suggestedMetadataURI,
        bytes memory proof // Placeholder for verifiable proof
    ) external whenNotPaused {
        // msg.sender must be a registered AND active AI agent
        if (!registeredAIAgents[msg.sender].isActive) {
            revert NotRegisteredAIAgent();
        }
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        // In a real system, 'proof' would be validated here.
        // E.g., verifying a ZKP against a known verifier contract, or checking an ECDSA signature
        // from a trusted AI service provider. For this example, we assume `msg.sender`
        // being a registered and active AI agent is sufficient authorization to *submit* the suggestion
        // and the `proof` is conceptually part of their off-chain process.

        _aiSuggestionCounters[tokenId].increment();
        uint256 suggestionId = _aiSuggestionCounters[tokenId].current();

        _aiSuggestions[tokenId].push(
            AISuggestion({
                aiAgent: msg.sender,
                suggestedMetadataURI: suggestedMetadataURI,
                timestamp: block.timestamp,
                status: SuggestionStatus.Pending
            })
        );
        emit AISuggestionSubmitted(tokenId, suggestionId, msg.sender, suggestedMetadataURI);
    }

    /**
     * @dev Owner accepts an AI's suggestion, applying the changes to the ChronoGlyph's dynamic metadata.
     * @param tokenId The ID of the ChronoGlyph.
     * @param suggestionId The ID of the suggestion to accept (1-based from Counters).
     */
    function acceptAICoachSuggestion(uint256 tokenId, uint256 suggestionId) external whenNotPaused {
        if (msg.sender != ownerOf(tokenId)) {
            revert NotGlyphOwner();
        }
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        // Check bounds for suggestionId (1-based counter vs 0-based array index)
        if (suggestionId == 0 || suggestionId > _aiSuggestions[tokenId].length) {
            revert SuggestionNotFoundOrInvalid();
        }

        AISuggestion storage suggestion = _aiSuggestions[tokenId][suggestionId - 1]; // Adjust for 0-based array index
        if (suggestion.status != SuggestionStatus.Pending) {
            revert SuggestionAlreadyProcessed();
        }

        ChronoGlyph storage glyph = _chronoGlyphs[tokenId];
        glyph.dynamicMetadataURI = suggestion.suggestedMetadataURI; // Apply the AI's suggested metadata
        suggestion.status = SuggestionStatus.Accepted; // Mark as accepted
        emit AISuggestionAccepted(tokenId, suggestionId, msg.sender);
    }

    /**
     * @dev Owner rejects a suggestion, marking it as invalid.
     * @param tokenId The ID of the ChronoGlyph.
     * @param suggestionId The ID of the suggestion to reject (1-based from Counters).
     */
    function rejectAICoachSuggestion(uint256 tokenId, uint256 suggestionId) external whenNotPaused {
        if (msg.sender != ownerOf(tokenId)) {
            revert NotGlyphOwner();
        }
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        // Check bounds for suggestionId
        if (suggestionId == 0 || suggestionId > _aiSuggestions[tokenId].length) {
            revert SuggestionNotFoundOrInvalid();
        }

        AISuggestion storage suggestion = _aiSuggestions[tokenId][suggestionId - 1]; // Adjust for 0-based array index
        if (suggestion.status != SuggestionStatus.Pending) {
            revert SuggestionAlreadyProcessed();
        }

        suggestion.status = SuggestionStatus.Rejected; // Mark as rejected
        emit AISuggestionRejected(tokenId, suggestionId, msg.sender);
    }

    /**
     * @dev View function to retrieve all pending AI suggestions for a ChronoGlyph.
     * @param tokenId The ID of the ChronoGlyph.
     * @return An array of AISuggestion structs.
     */
    function getAICoachSuggestions(uint256 tokenId) external view returns (AISuggestion[] memory) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        return _aiSuggestions[tokenId];
    }

    // --- IV. Administration & Control ---

    /**
     * @dev Sets the base URI for ChronoGlyph metadata.
     *      This base URI is used as a prefix for constructing the full tokenURI.
     *      Only callable by the contract owner.
     * @param _newBaseURI The new base URI.
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        _baseURI = _newBaseURI;
        emit BaseURIUpdated(_newBaseURI);
    }

    /**
     * @dev Sets the address of the trusted oracle contract/service.
     *      Only this address can call `_updateGlyphEnvironmentalMetadata`.
     *      Only callable by the contract owner.
     * @param _newOracleAddress The new oracle address.
     */
    function setOracleAddress(address _newOracleAddress) external onlyOwner {
        oracleAddress = _newOracleAddress;
    }

    /**
     * @dev Sets the address of the trusted off-chain verifier for genetic mutations.
     *      Only this address can call `executeGeneticMutation`.
     *      Only callable by the contract owner.
     * @param _newVerifierAddress The new verifier address.
     */
    function setVerifierAddress(address _newVerifierAddress) external onlyOwner {
        verifierAddress = _newVerifierAddress;
    }

    /**
     * @dev Sets the price (in wei) for minting new genesis ChronoGlyphs.
     *      Only callable by the contract owner.
     * @param _newPrice The new genesis price in wei.
     */
    function setGenesisPrice(uint256 _newPrice) external onlyOwner {
        genesisPrice = _newPrice;
        emit GenesisPriceUpdated(_newPrice);
    }

    /**
     * @dev Sets the fee (in wei) for nurturing ChronoGlyphs.
     *      Only callable by the contract owner.
     * @param _newFee The new nurturing fee in wei.
     */
    function setNurturingFee(uint256 _newFee) external onlyOwner {
        nurturingFee = _newFee;
        emit NurturingFeeUpdated(_newFee);
    }

    /**
     * @dev Sets the basis multiplier for calculating progeny spawning fees.
     *      e.g., if set to 1000, and a parent has nurturedCount of 10, fee would be (10 * 1000) / 1000 = 10 wei.
     *      A value of 0 would mean free proliferation.
     *      Only callable by the contract owner.
     * @param _newBasis The new proliferation fee basis.
     */
    function setProliferationFeeBasis(uint256 _newBasis) external onlyOwner {
        if (_newBasis > 10_000_000_000_000_000_000) { // Example sanity check: Max 10 ETH equivalent per unit of nurturedCount
            revert InvalidProliferationBasis();
        }
        proliferationFeeBasis = _newBasis;
        emit ProliferationFeeBasisUpdated(_newBasis);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated ETH from fees (minting, nurturing, proliferation).
     *      Only callable by the contract owner.
     */
    function withdrawFunds() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    /**
     * @dev Pauses the contract, restricting most state-changing functions.
     *      Inherited from OpenZeppelin Pausable. Only callable by the contract owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     *      Inherited from OpenZeppelin Pausable. Only callable by the contract owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- Internal/Helper Functions (ERC721 overrides) ---

    function _baseURI() internal view override returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev Checks if a token ID exists.
     *      Overrides OpenZeppelin's _exists to reflect our internal token counter.
     */
    function _exists(uint256 tokenId) internal view override returns (bool) {
        // A token exists if its ID is within the range of minted tokens.
        return tokenId > 0 && tokenId <= _tokenIdCounter.current();
    }
}
```