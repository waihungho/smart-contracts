Here's a Solidity smart contract named `ArtifexForge` that implements several interesting, advanced, and trendy concepts without directly duplicating existing open-source functionalities. It focuses on AI-enhanced dynamic NFTs, collaborative creation, and a decentralized AI model marketplace.

The contract leverages OpenZeppelin libraries for standard functionalities like ERC721, Ownable, Pausable, ReentrancyGuard, and SafeMath, allowing the core logic to concentrate on the novel features.

---

## ArtifexForge: An AI-Enhanced Generative Art Protocol

**Concept Overview:**

`ArtifexForge` is an innovative, AI-enhanced decentralized protocol for creating, evolving, and trading dynamic generative art NFTs. It acts as a bridge between on-chain ownership/governance and off-chain AI computation, enabling unique functionalities like AI-driven NFT evolution, a marketplace for AI models, and collaborative creation with automated royalty distribution. The NFTs minted are not static images but "living" digital assets that can change and react based on AI outputs, oracle data, and community decisions.

---

**Outline:**

1.  **Libraries & Interfaces:**
    *   OpenZeppelin: `ERC721`, `Ownable`, `Pausable`, `ReentrancyGuard`, `SafeMath`, `Counters`.
    *   Custom Interface: `IAIOracle` for external AI Oracle/Executor services.
2.  **State Variables & Data Structures:**
    *   Defines structs for `ArtifexNFT`, `AIModel`, `InferenceRequest`, `EvolutionProposal`.
    *   Mappings and counters to manage NFTs, AI models, inference requests, and proposals.
    *   Protocol fee configurations and accumulated fees.
    *   Pausability state and AI model provider roles.
3.  **Events:** Comprehensive event logging for all critical actions, enhancing transparency and off-chain monitoring.
4.  **Modifiers:** Custom access control modifiers (`onlyAIModelProvider`, `onlyNFTCreatorOrCollaborator`, `onlyNFTOwner`, `notForSale`, `whenNotPaused`, `nonReentrant`).
5.  **Core NFT (`ArtifexToken` ERC721 Extension):**
    *   Manages the minting, metadata updates, and basic ownership of dynamic NFTs, including a `generationSeed` for AI-driven randomness.
6.  **AI Model Management:**
    *   Enables authorized providers to register, configure, and manage off-chain AI models within the protocol.
    *   Facilitates requests for AI inference by users and provides a mechanism for trusted oracles to submit and verify computation results.
7.  **Dynamic NFT Evolution:**
    *   Implements a decentralized proposal and voting mechanism for major NFT evolutions driven by AI models or external data.
    *   Allows linking NFTs to specific external data oracles for real-time, dynamic reactivity.
8.  **Collaborative Creation & Royalties:**
    *   Manages multiple creators/collaborators for a single NFT, allowing owners to define royalty shares.
    *   Automates royalty distribution from NFT sales, accumulating earnings for collaborators to claim.
9.  **Marketplace & Protocol Economics:**
    *   Functions for listing and purchasing NFTs on a simple marketplace.
    *   Mechanisms for collecting and distributing protocol fees from sales and AI model usage.
10. **Admin & Security:**
    *   Standard ownership transfer, contract pausing/unpausing for emergencies, and role management for AI model providers.

---

**Function Summary:**

**I. Core NFT (ArtifexToken - ERC721 Extension)**

1.  `mintArtifexNFT(string memory _initialMetadataURI)`:
    *   Mints a new Artifex NFT, assigning an initial metadata URI representing its starting generative art state. The `_initialMetadataURI` can point to an initial image or generative parameters. Sets the creator as the initial 100% royalty collaborator.
2.  `updateNFTGenerationSeed(uint256 _tokenId, bytes32 _newSeed)`:
    *   Allows the current owner of an NFT to update its internal cryptographic seed, which can influence future AI-driven generative processes tied to that NFT.
3.  `getNFTCurrentState(uint256 _tokenId)`:
    *   Retrieves the current AI-relevant parameters, oracle links, and state variables for a specific Artifex NFT, reflecting its dynamic nature.
4.  `getNFTEvolutionHistory(uint256 _tokenId)`:
    *   Provides a chronological (simplified) list of all successful AI-driven or manually approved evolution steps an NFT has undergone, including proposal details and outcomes. (A full history would typically be queried off-chain via event logs).
5.  `tokenURI(uint256 _tokenId)`:
    *   Overrides the standard ERC721 `tokenURI` function to return the current dynamic metadata URI of the NFT.

**II. AI Model & Inference Management**

6.  `registerAIModel(string memory _modelName, string memory _modelDescription, address _modelProvider, uint256 _inferenceCostWei, bytes32[] memory _supportedInputTypes, bytes32 _outputType)`:
    *   Allows authorized AI model providers to register their off-chain AI models with the protocol. Includes metadata, cost per inference, and supported/output data types (represented by hashes of schemas).
7.  `updateAIModel(uint256 _modelId, string memory _newDescription, uint256 _newCost, bool _isActive)`:
    *   Enables an AI model provider to modify the description, inference cost, or active status of their registered AI model.
8.  `requestAIInference(uint256 _tokenId, uint256 _modelId, bytes memory _inputData, address _callbackContract, bytes4 _callbackFunctionSelector)`:
    *   Initiates an off-chain AI inference request for a specified NFT using a registered AI model. `_inputData` contains parameters for the AI. A callback address and function are provided for when the AI computation is complete, enabling complex workflows.
9.  `submitAIInferenceProof(uint256 _inferenceRequestId, bytes memory _proof, bytes32 _outputHash, string memory _newMetadataURI)`:
    *   This function is called by a trusted AI oracle/executor. It submits cryptographic proof of an off-chain AI computation, the resulting output data hash, and updates the NFT's metadata URI to reflect the new generative state. (Proof verification is a placeholder due to complexity).
10. `getAIModelInfo(uint256 _modelId)`:
    *   Queries and returns detailed information about a registered AI model, including its provider, cost, and active status.
11. `getInferenceRequestStatus(uint256 _requestId)`:
    *   Allows users to check the current status (e.g., pending, completed, failed) of a previously submitted AI inference request.

**III. Dynamic NFT Evolution & Oracle Integration**

12. `proposeDynamicEvolution(uint256 _tokenId, uint256 _modelId, bytes memory _evolutionParameters, uint256 _duration)`:
    *   Allows an NFT owner or a designated collaborator to propose a major AI-driven evolution for an NFT, specifying an AI model and parameters. The proposal enters a community voting phase.
13. `voteOnEvolutionProposal(uint256 _proposalId, bool _for)`:
    *   Enables eligible users (e.g., token holders, NFT collaborators) to cast a vote for or against a pending NFT evolution proposal.
14. `executeApprovedEvolution(uint256 _proposalId)`:
    *   Executed once an evolution proposal passes its voting threshold. This function marks the proposal as executed, implying an off-chain AI system should then trigger the actual AI inference request to update the NFT based on the approved parameters.
15. `setNFTExternalDataSource(uint256 _tokenId, address _oracleAddress, bytes4 _dataFeedSelector, bytes32 _expectedDataType)`:
    *   Links a specific Artifex NFT to an external data oracle. This allows the NFT's state or appearance to dynamically react to real-world data feeds pushed by the oracle.
16. `receiveOracleData(uint256 _tokenId, bytes memory _data)`:
    *   A public callback function expected to be invoked by a whitelisted external oracle. When called, it updates the internal state of the specified NFT based on the received `_data`, potentially triggering automated metadata changes.

**IV. Collaborative Creation & Royalty Distribution**

17. `addCollaborator(uint256 _tokenId, address _collaborator, uint256 _shareBasisPoints)`:
    *   Allows the NFT owner to add another address as a collaborator, granting them a percentage share of future royalties from the NFT. Total shares cannot exceed 100% (10000 basis points).
18. `updateCollaboratorShare(uint256 _tokenId, address _collaborator, uint256 _newShareBasisPoints)`:
    *   Enables the NFT owner to adjust the royalty share of an existing collaborator, ensuring total shares remain valid.
19. `removeCollaborator(uint256 _tokenId, address _collaborator)`:
    *   Removes a collaborator from an NFT's royalty distribution list.
20. `claimCollaboratorRoyalties(uint256 _tokenId)`:
    *   Allows any registered collaborator of an NFT to claim their accumulated royalty share from sales or model usage fees generated by that NFT.

**V. Marketplace & Protocol Economics**

21. `listNFTForSale(uint256 _tokenId, uint256 _price)`:
    *   Places an Artifex NFT on the marketplace for a specified price in Wei.
22. `buyNFT(uint256 _tokenId)`:
    *   Allows a user to purchase a listed NFT, transferring ownership and distributing funds to the seller, collaborators (based on their shares), and the protocol fees.
23. `collectProtocolFees()`:
    *   Allows the contract owner to withdraw accumulated protocol fees from NFT sales and AI model usage.
24. `setProtocolFeeRate(uint256 _newRateBasisPoints)`:
    *   Sets the percentage of sale/usage value that goes to the protocol as a fee. (Basis points: 10000 = 100%).

**VI. Admin & Security**

25. `pause()`:
    *   An emergency function callable by the owner to pause critical functionalities of the contract, preventing further operations during incidents.
26. `unpause()`:
    *   Unpauses the contract, restoring normal operation.
27. `setAIModelProviderRole(address _provider, bool _isProvider)`:
    *   Grants or revokes the `AI_MODEL_PROVIDER_ROLE` for a given address, allowing them to register and manage AI models.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // SafeMath is redundant in 0.8+ but included for clarity on arithmetic safety.

/**
 * @title ArtifexForge
 * @dev An AI-enhanced decentralized protocol for creating, evolving, and trading dynamic generative art NFTs.
 *      It acts as a bridge between on-chain ownership/governance and off-chain AI computation, enabling unique
 *      functionalities like AI-driven NFT evolution, a marketplace for AI models, and collaborative creation
 *      with automated royalty distribution. NFTs minted are not static images but "living" digital assets
 *      that can change and react based on AI outputs, oracle data, and community decisions.
 */
contract ArtifexForge is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables & Data Structures ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _aiModelIdCounter;
    Counters.Counter private _inferenceRequestIdCounter;
    Counters.Counter private _evolutionProposalIdCounter;

    uint256 public protocolFeeRateBasisPoints; // e.g., 500 for 5% (500/10000)
    uint256 public accumulatedProtocolFees;

    // Struct for an Artifex NFT
    struct ArtifexNFT {
        string metadataURI; // Current metadata URI, evolves over time
        bytes32 generationSeed; // Seed for generative processes (e.g., used by off-chain AI)
        address[] collaborators; // List of addresses collaborating on this NFT
        mapping(address => uint256) collaboratorSharesBasisPoints; // Basis points share for each collaborator (sum cannot exceed 10000)
        address oracleAddress; // Address of the oracle providing dynamic data (0x0 if none)
        bytes4 dataFeedSelector; // Function selector for the oracle data feed (0x0 if none)
        bytes32 expectedDataType; // Hash of expected data schema from oracle (0x0 if none)
        mapping(address => uint256) earnedRoyalties; // Royalties accumulated for each collaborator
    }
    mapping(uint256 => ArtifexNFT) public artifexNFTs;
    mapping(uint256 => uint256) public nftPrices; // Token ID -> Price in Wei (0 if not for sale)

    // Struct for an AI Model registered in the protocol
    struct AIModel {
        string name;
        string description;
        address provider; // Address of the entity providing the off-chain AI service
        uint256 inferenceCostWei; // Cost to use this model per inference
        bytes32[] supportedInputTypes; // Hashes of supported input data schemas (e.g., keccak256("ImageStyleTransferParams"))
        bytes32 outputType; // Hash of output data schema (e.g., keccak256("ImageURI"))
        bool isActive;
    }
    mapping(uint256 => AIModel) public aiModels;
    mapping(address => bool) public isAIModelProvider; // Role for entities who can register AI models

    // Struct for an AI Inference Request
    enum InferenceStatus { Pending, Completed, Failed }
    struct InferenceRequest {
        uint256 tokenId;
        uint256 modelId;
        address requester;
        bytes inputData; // Data sent to off-chain AI for inference
        address callbackContract; // Contract to call back upon completion
        bytes4 callbackFunctionSelector; // Function to call back on the callbackContract
        InferenceStatus status;
        bytes32 outputHash; // Hash of the final output data (e.g., IPFS hash of new image)
    }
    mapping(uint256 => InferenceRequest) public inferenceRequests;

    // Struct for an NFT Evolution Proposal
    enum ProposalStatus { Pending, Approved, Rejected, Executed }
    struct EvolutionProposal {
        uint256 tokenId;
        uint256 modelId;
        bytes evolutionParameters; // Parameters for the AI model to evolve the NFT
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks who has voted
        ProposalStatus status;
    }
    mapping(uint256 => EvolutionProposal) public evolutionProposals;

    // --- Events ---
    event NFTMinted(uint256 indexed tokenId, address indexed owner, string initialMetadataURI);
    event NFTMetadataUpdated(uint256 indexed tokenId, string newMetadataURI);
    event NFTSeedUpdated(uint256 indexed tokenId, bytes32 newSeed);
    event NFTListedForSale(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTPurchased(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event RoyaltiesClaimed(uint256 indexed tokenId, address indexed collaborator, uint256 amount);

    event AIModelRegistered(uint256 indexed modelId, string name, address indexed provider, uint256 cost);
    event AIModelUpdated(uint256 indexed modelId, uint256 newCost, bool isActive);
    event AIInferenceRequested(uint256 indexed requestId, uint256 indexed tokenId, uint256 indexed modelId, address requester);
    event AIInferenceCompleted(uint256 indexed requestId, uint256 indexed tokenId, bytes32 outputHash, string newMetadataURI);

    event EvolutionProposed(uint256 indexed proposalId, uint256 indexed tokenId, uint256 indexed modelId, uint256 votingEndTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool decision);
    event EvolutionExecuted(uint256 indexed proposalId, uint256 indexed tokenId);

    event NFTDataSourceSet(uint256 indexed tokenId, address indexed oracleAddress, bytes4 dataFeedSelector);
    event OracleDataReceived(uint256 indexed tokenId, bytes data);

    event CollaboratorAdded(uint256 indexed tokenId, address indexed collaborator, uint256 shareBasisPoints);
    event CollaboratorShareUpdated(uint256 indexed tokenId, address indexed collaborator, uint256 newShareBasisPoints);
    event CollaboratorRemoved(uint256 indexed tokenId, address indexed collaborator);

    event ProtocolFeeRateUpdated(uint256 newRateBasisPoints);
    event ProtocolFeesCollected(uint256 amount);

    // --- Modifiers ---
    modifier onlyAIModelProvider() {
        require(isAIModelProvider[msg.sender], "ArtifexForge: Not an AI model provider");
        _;
    }

    modifier onlyNFTCreatorOrCollaborator(uint256 _tokenId) {
        require(
            _exists(_tokenId) && (ownerOf(_tokenId) == msg.sender || artifexNFTs[_tokenId].collaboratorSharesBasisPoints[msg.sender] > 0),
            "ArtifexForge: Not NFT owner or collaborator"
        );
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "ArtifexForge: Not NFT owner");
        _;
    }

    modifier notForSale(uint256 _tokenId) {
        require(nftPrices[_tokenId] == 0, "ArtifexForge: NFT is currently for sale");
        _;
    }

    constructor() ERC721("ArtifexForgeNFT", "ARTFX") Ownable(msg.sender) {
        protocolFeeRateBasisPoints = 500; // Default 5% protocol fee (500 / 10000)
    }

    // --- I. Core NFT (ArtifexToken - ERC721 Extension) ---

    /**
     * @dev Mints a new Artifex NFT, assigning an initial metadata URI. The creator is set as the initial 100% collaborator.
     * @param _initialMetadataURI The URI pointing to the initial metadata (e.g., IPFS hash of a JSON).
     */
    function mintArtifexNFT(string memory _initialMetadataURI) public payable whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _mint(msg.sender, newTokenId);
        artifexNFTs[newTokenId].metadataURI = _initialMetadataURI;
        // Generate a pseudo-random seed based on block data and sender address
        artifexNFTs[newTokenId].generationSeed = bytes32(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, newTokenId))));
        artifexNFTs[newTokenId].collaborators.push(msg.sender);
        artifexNFTs[newTokenId].collaboratorSharesBasisPoints[msg.sender] = 10000; // 100% initial share to creator

        emit NFTMinted(newTokenId, msg.sender, _initialMetadataURI);
        return newTokenId;
    }

    /**
     * @dev Allows the current owner of an NFT to update its internal cryptographic seed.
     *      This seed can influence future AI-driven generative processes tied to that NFT.
     * @param _tokenId The ID of the NFT to update.
     * @param _newSeed The new cryptographic seed.
     */
    function updateNFTGenerationSeed(uint256 _tokenId, bytes32 _newSeed) public virtual onlyNFTOwner(_tokenId) whenNotPaused {
        require(_exists(_tokenId), "ArtifexForge: NFT does not exist");
        artifexNFTs[_tokenId].generationSeed = _newSeed;
        emit NFTSeedUpdated(_tokenId, _newSeed);
    }

    /**
     * @dev Returns the current AI-relevant parameters, oracle links, and state variables for a specific Artifex NFT.
     * @param _tokenId The ID of the NFT.
     * @return metadataURI The current metadata URI.
     * @return generationSeed The current generation seed.
     * @return oracleAddress The address of the linked oracle.
     * @return dataFeedSelector The function selector for the oracle data feed.
     * @return expectedDataType The expected data type from the oracle.
     */
    function getNFTCurrentState(uint256 _tokenId) public view returns (string memory metadataURI, bytes32 generationSeed, address oracleAddress, bytes4 dataFeedSelector, bytes32 expectedDataType) {
        require(_exists(_tokenId), "ArtifexForge: NFT does not exist");
        ArtifexNFT storage nft = artifexNFTs[_tokenId];
        return (nft.metadataURI, nft.generationSeed, nft.oracleAddress, nft.dataFeedSelector, nft.expectedDataType);
    }

    /**
     * @dev Retrieves a list of past evolution steps for an NFT.
     *      (Note: This function iterates all proposals to find NFT-specific ones.
     *      For a high volume of proposals, off-chain indexing via events is recommended).
     * @param _tokenId The ID of the NFT.
     * @return proposalIds An array of evolution proposal IDs associated with the NFT.
     * @return statuses An array of corresponding proposal statuses.
     */
    function getNFTEvolutionHistory(uint256 _tokenId) public view returns (uint256[] memory proposalIds, ProposalStatus[] memory statuses) {
        require(_exists(_tokenId), "ArtifexForge: NFT does not exist");

        uint256 currentProposalCount = _evolutionProposalIdCounter.current();
        uint256[] memory tempProposalIds = new uint256[](currentProposalCount);
        ProposalStatus[] memory tempStatuses = new ProposalStatus[](currentProposalCount);
        uint256 count = 0;

        for (uint256 i = 1; i <= currentProposalCount; i++) {
            if (evolutionProposals[i].tokenId == _tokenId) {
                tempProposalIds[count] = i;
                tempStatuses[count] = evolutionProposals[i].status;
                count++;
            }
        }

        // Resize arrays to actual count
        assembly {
            mstore(tempProposalIds, count)
            mstore(tempStatuses, count)
        }
        return (tempProposalIds, tempStatuses);
    }

    /**
     * @dev Returns the token URI for a given tokenId. Overrides ERC721's tokenURI to be dynamic.
     * @param _tokenId The ID of the NFT.
     * @return The metadata URI of the NFT.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return artifexNFTs[_tokenId].metadataURI;
    }

    // --- II. AI Model & Inference Management ---

    /**
     * @dev Allows authorized AI model providers to register their off-chain AI models with the protocol.
     *      Includes metadata, cost per inference, and supported/output data types (represented by bytes32 hashes).
     * @param _modelName The human-readable name of the AI model.
     * @param _modelDescription A brief description of the model's capabilities.
     * @param _modelProvider The address of the entity providing the off-chain AI service.
     * @param _inferenceCostWei The cost in Wei to perform one inference with this model.
     * @param _supportedInputTypes An array of bytes32 hashes representing supported input data schemas.
     * @param _outputType A bytes32 hash representing the output data schema.
     */
    function registerAIModel(
        string memory _modelName,
        string memory _modelDescription,
        address _modelProvider,
        uint256 _inferenceCostWei,
        bytes32[] memory _supportedInputTypes,
        bytes32 _outputType
    ) public onlyAIModelProvider whenNotPaused {
        _aiModelIdCounter.increment();
        uint256 newModelId = _aiModelIdCounter.current();

        aiModels[newModelId] = AIModel({
            name: _modelName,
            description: _modelDescription,
            provider: _modelProvider,
            inferenceCostWei: _inferenceCostWei,
            supportedInputTypes: _supportedInputTypes,
            outputType: _outputType,
            isActive: true
        });

        emit AIModelRegistered(newModelId, _modelName, _modelProvider, _inferenceCostWei);
    }

    /**
     * @dev Enables an AI model provider to modify the description, inference cost, or active status of their registered AI model.
     * @param _modelId The ID of the AI model to update.
     * @param _newDescription The new description for the model.
     * @param _newCost The new inference cost in Wei.
     * @param _isActive The new active status of the model.
     */
    function updateAIModel(uint256 _modelId, string memory _newDescription, uint256 _newCost, bool _isActive) public onlyAIModelProvider whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        require(model.provider == msg.sender, "ArtifexForge: Only model provider can update");
        require(model.isActive || _isActive, "ArtifexForge: Cannot update an inactive model unless reactivating"); // Allow reactivating inactive models

        model.description = _newDescription;
        model.inferenceCostWei = _newCost;
        model.isActive = _isActive;

        emit AIModelUpdated(_modelId, _newCost, _isActive);
    }

    /**
     * @dev Initiates an off-chain AI inference request for a specified NFT using a registered AI model.
     *      `_inputData` contains parameters for the AI. A callback address and function are provided
     *      for when the AI computation is complete.
     * @param _tokenId The ID of the NFT to apply inference to.
     * @param _modelId The ID of the AI model to use.
     * @param _inputData The raw input data/parameters for the AI model.
     * @param _callbackContract The address of the contract expected to fulfill the inference (e.g., an AI oracle service).
     * @param _callbackFunctionSelector The function selector on the callback contract to call upon completion.
     */
    function requestAIInference(
        uint256 _tokenId,
        uint256 _modelId,
        bytes memory _inputData,
        address _callbackContract,
        bytes4 _callbackFunctionSelector
    ) public payable onlyNFTCreatorOrCollaborator(_tokenId) whenNotPaused nonReentrant {
        require(_exists(_tokenId), "ArtifexForge: NFT does not exist");
        AIModel storage model = aiModels[_modelId];
        require(model.provider != address(0), "ArtifexForge: AI model does not exist");
        require(model.isActive, "ArtifexForge: AI model is not active");
        require(msg.value >= model.inferenceCostWei, "ArtifexForge: Insufficient payment for inference");

        _inferenceRequestIdCounter.increment();
        uint256 newRequestId = _inferenceRequestIdCounter.current();

        inferenceRequests[newRequestId] = InferenceRequest({
            tokenId: _tokenId,
            modelId: _modelId,
            requester: msg.sender,
            inputData: _inputData,
            callbackContract: _callbackContract,
            callbackFunctionSelector: _callbackFunctionSelector,
            status: InferenceStatus.Pending,
            outputHash: bytes32(0) // Initial empty hash
        });

        // Transfer funds to the model provider
        (bool success, ) = payable(model.provider).call{value: model.inferenceCostWei}("");
        require(success, "ArtifexForge: Failed to transfer inference payment to model provider");

        // Calculate and accumulate protocol fee on model usage
        uint256 protocolFee = model.inferenceCostWei.mul(protocolFeeRateBasisPoints).div(10000);
        accumulatedProtocolFees = accumulatedProtocolFees.add(protocolFee);

        // Refund any excess payment
        if (msg.value > model.inferenceCostWei) {
            payable(msg.sender).transfer(msg.value.sub(model.inferenceCostWei));
        }

        // The AI oracle/executor would be notified off-chain (e.g., via event monitoring)
        // to process this request and call back using submitAIInferenceProof.
        emit AIInferenceRequested(newRequestId, _tokenId, _modelId, msg.sender);
    }

    /**
     * @dev This function is called by a trusted AI oracle/executor. It submits cryptographic proof
     *      of an off-chain AI computation, the resulting output data hash, and updates the NFT's
     *      metadata URI to reflect the new generative state.
     *      Note: In a real system, the `_proof` would be rigorously verified on-chain (e.g., ZK-SNARKs).
     *      For this example, we assume `msg.sender` is a trusted AI oracle or that proof verification happens off-chain.
     * @param _inferenceRequestId The ID of the inference request being fulfilled.
     * @param _proof The cryptographic proof of computation (placeholder; actual verification logic is complex).
     * @param _outputHash The hash of the AI's generated output data (e.g., content hash of the new art).
     * @param _newMetadataURI The new metadata URI for the NFT after inference, pointing to the evolved art.
     */
    function submitAIInferenceProof(
        uint256 _inferenceRequestId,
        bytes memory _proof, // Placeholder for verifiable computation proof
        bytes32 _outputHash,
        string memory _newMetadataURI
    ) public whenNotPaused {
        InferenceRequest storage req = inferenceRequests[_inferenceRequestId];
        require(req.requester != address(0), "ArtifexForge: Inference request does not exist"); // Check if request ID is valid
        require(req.status == InferenceStatus.Pending, "ArtifexForge: Inference request not pending");

        // --- IMPORTANT: Placeholder for Proof Verification ---
        // In a production system, this is where a robust cryptographic proof verification
        // would take place (e.g., calling a ZK-SNARK verifier contract, or verifying a Merkle proof).
        // For example: `require(VerifierContract.verify(_proof, req.inputData, _outputHash), "Invalid proof");`
        // Without this, the system relies on trusting the caller of this function.
        // --- End Placeholder ---

        req.status = InferenceStatus.Completed;
        req.outputHash = _outputHash;

        artifexNFTs[req.tokenId].metadataURI = _newMetadataURI; // Update NFT metadata

        emit AIInferenceCompleted(_inferenceRequestId, req.tokenId, _outputHash, _newMetadataURI);
        emit NFTMetadataUpdated(req.tokenId, _newMetadataURI);

        // If a custom callback was specified for the original request, execute it
        // This allows more complex workflows where an AI inference triggers another contract
        if (req.callbackContract != address(0) && req.callbackContract != address(this)) {
            (bool success, ) = req.callbackContract.call(abi.encodeWithSelector(req.callbackFunctionSelector, req.tokenId, _outputHash, _newMetadataURI));
            require(success, "ArtifexForge: Failed to execute custom callback");
        }
    }

    /**
     * @dev Queries and returns detailed information about a registered AI model.
     * @param _modelId The ID of the AI model.
     * @return name The model's name.
     * @return description The model's description.
     * @return provider The model provider's address.
     * @return inferenceCostWei The cost per inference.
     * @return isActive The model's active status.
     * @return supportedInputTypes The supported input data types.
     * @return outputType The output data type.
     */
    function getAIModelInfo(uint256 _modelId) public view returns (string memory name, string memory description, address provider, uint256 inferenceCostWei, bool isActive, bytes32[] memory supportedInputTypes, bytes32 outputType) {
        AIModel storage model = aiModels[_modelId];
        require(model.provider != address(0), "ArtifexForge: AI model does not exist");
        return (model.name, model.description, model.provider, model.inferenceCostWei, model.isActive, model.supportedInputTypes, model.outputType);
    }

    /**
     * @dev Allows users to check the current status (e.g., pending, completed, failed) of a previously submitted AI inference request.
     * @param _requestId The ID of the inference request.
     * @return status The current status of the request.
     * @return tokenId The associated NFT ID.
     * @return modelId The associated AI model ID.
     * @return outputHash The output hash if completed.
     */
    function getInferenceRequestStatus(uint256 _requestId) public view returns (InferenceStatus status, uint256 tokenId, uint256 modelId, bytes32 outputHash) {
        InferenceRequest storage req = inferenceRequests[_requestId];
        require(req.requester != address(0), "ArtifexForge: Inference request does not exist");
        return (req.status, req.tokenId, req.modelId, req.outputHash);
    }

    // --- III. Dynamic NFT Evolution & Oracle Integration ---

    /**
     * @dev Allows an NFT owner or a designated collaborator to propose a major evolution for an NFT,
     *      specifying an AI model and parameters. The proposal enters a community voting phase.
     * @param _tokenId The ID of the NFT to evolve.
     * @param _modelId The ID of the AI model to use for evolution.
     * @param _evolutionParameters Raw bytes parameters for the AI model.
     * @param _duration The duration in seconds for the voting period.
     */
    function proposeDynamicEvolution(uint256 _tokenId, uint256 _modelId, bytes memory _evolutionParameters, uint256 _duration) public onlyNFTCreatorOrCollaborator(_tokenId) whenNotPaused {
        require(_exists(_tokenId), "ArtifexForge: NFT does not exist");
        require(aiModels[_modelId].provider != address(0) && aiModels[_modelId].isActive, "ArtifexForge: AI model is not active or does not exist");
        require(_duration > 0, "ArtifexForge: Voting duration must be greater than zero");

        _evolutionProposalIdCounter.increment();
        uint256 newProposalId = _evolutionProposalIdCounter.current();

        evolutionProposals[newProposalId] = EvolutionProposal({
            tokenId: _tokenId,
            modelId: _modelId,
            evolutionParameters: _evolutionParameters,
            votingEndTime: block.timestamp.add(_duration),
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Pending
        });

        emit EvolutionProposed(newProposalId, _tokenId, _modelId, block.timestamp.add(_duration));
    }

    /**
     * @dev Enables eligible users (e.g., token holders, NFT collaborators) to cast a vote for or against a pending NFT evolution proposal.
     *      A more advanced system could implement weighted voting based on ARTFX token holdings or NFT ownership.
     * @param _proposalId The ID of the evolution proposal.
     * @param _for True for a 'for' vote, false for 'against'.
     */
    function voteOnEvolutionProposal(uint256 _proposalId, bool _for) public whenNotPaused {
        EvolutionProposal storage proposal = evolutionProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "ArtifexForge: Proposal not pending or already decided");
        require(block.timestamp < proposal.votingEndTime, "ArtifexForge: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "ArtifexForge: Already voted on this proposal");

        if (_for) {
            proposal.votesFor = proposal.votesFor.add(1);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(1);
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _for);
    }

    /**
     * @dev Executed once an evolution proposal passes its voting threshold.
     *      This function finalizes the proposal status. A separate off-chain process
     *      or automated bot would then monitor for "Approved" proposals and call
     *      `requestAIInference` (potentially with protocol funds) and subsequently
     *      `submitAIInferenceProof` to update the NFT metadata.
     * @param _proposalId The ID of the evolution proposal.
     */
    function executeApprovedEvolution(uint256 _proposalId) public whenNotPaused {
        EvolutionProposal storage proposal = evolutionProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "ArtifexForge: Proposal not pending");
        require(block.timestamp >= proposal.votingEndTime, "ArtifexForge: Voting period not ended");

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.Approved;
            // In a real system, a system like Chainlink Automation or a trusted bot
            // would monitor this event and call `requestAIInference` for the actual AI execution,
            // potentially funding it from a protocol treasury or by the original proposer.
            // For this example, we simply mark it as Approved, expecting off-chain action.
            emit EvolutionExecuted(_proposalId, proposal.tokenId);
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
    }

    /**
     * @dev Links a specific Artifex NFT to an external data oracle. This allows the NFT's state
     *      or appearance to dynamically react to real-world data feeds pushed by the oracle.
     * @param _tokenId The ID of the NFT to link.
     * @param _oracleAddress The address of the trusted oracle contract.
     * @param _dataFeedSelector The function selector on the oracle contract for the data feed.
     * @param _expectedDataType A bytes32 hash representing the expected data schema from the oracle.
     */
    function setNFTExternalDataSource(uint256 _tokenId, address _oracleAddress, bytes4 _dataFeedSelector, bytes32 _expectedDataType) public onlyNFTOwner(_tokenId) whenNotPaused {
        require(_exists(_tokenId), "ArtifexForge: NFT does not exist");
        artifexNFTs[_tokenId].oracleAddress = _oracleAddress;
        artifexNFTs[_tokenId].dataFeedSelector = _dataFeedSelector;
        artifexNFTs[_tokenId].expectedDataType = _expectedDataType;
        emit NFTDataSourceSet(_tokenId, _oracleAddress, _dataFeedSelector);
    }

    /**
     * @dev A public callback function expected to be invoked by a whitelisted external oracle.
     *      When called, it updates the internal state of the specified NFT based on the received `_data`,
     *      potentially triggering automated metadata changes or influencing future AI inferences.
     *      NOTE: In a production system, `msg.sender` should be verified against a whitelist of trusted oracles.
     * @param _tokenId The ID of the NFT to update.
     * @param _data The raw data received from the oracle.
     */
    function receiveOracleData(uint256 _tokenId, bytes memory _data) public whenNotPaused {
        require(_exists(_tokenId), "ArtifexForge: NFT does not exist");
        // Example validation (replace with actual trusted oracle check):
        // require(msg.sender == artifexNFTs[_tokenId].oracleAddress, "ArtifexForge: Not authorized oracle for this NFT");

        // Here, `_data` could be parsed and used to:
        // 1. Directly update `artifexNFTs[_tokenId].metadataURI` based on the data.
        // 2. Update internal NFT state variables that then feed into AI inference requests.
        // 3. Trigger a new `requestAIInference` call using this data as input.
        // For simplicity, we just log the event.
        emit OracleDataReceived(_tokenId, _data);
    }

    // --- IV. Collaborative Creation & Royalty Distribution ---

    /**
     * @dev Allows the NFT owner to add another address as a collaborator, granting them a percentage share of future royalties from the NFT.
     *      Total shares across all collaborators (including owner's initial share) cannot exceed 100% (10000 basis points).
     * @param _tokenId The ID of the NFT.
     * @param _collaborator The address of the new collaborator.
     * @param _shareBasisPoints The royalty share for the collaborator in basis points (e.g., 100 for 1%).
     */
    function addCollaborator(uint256 _tokenId, address _collaborator, uint256 _shareBasisPoints) public onlyNFTOwner(_tokenId) whenNotPaused {
        ArtifexNFT storage nft = artifexNFTs[_tokenId];
        require(nft.collaboratorSharesBasisPoints[_collaborator] == 0, "ArtifexForge: Collaborator already exists");
        require(_shareBasisPoints > 0, "ArtifexForge: Share must be greater than zero");

        uint256 currentTotalShares = 0;
        for (uint256 i = 0; i < nft.collaborators.length; i++) {
            currentTotalShares = currentTotalShares.add(nft.collaboratorSharesBasisPoints[nft.collaborators[i]]);
        }
        require(currentTotalShares.add(_shareBasisPoints) <= 10000, "ArtifexForge: Total shares exceed 100%");

        nft.collaborators.push(_collaborator);
        nft.collaboratorSharesBasisPoints[_collaborator] = _shareBasisPoints;

        emit CollaboratorAdded(_tokenId, _collaborator, _shareBasisPoints);
    }

    /**
     * @dev Enables the NFT owner to adjust the royalty share of an existing collaborator.
     *      Total shares across all collaborators cannot exceed 100% (10000 basis points).
     * @param _tokenId The ID of the NFT.
     * @param _collaborator The address of the collaborator.
     * @param _newShareBasisPoints The new royalty share in basis points.
     */
    function updateCollaboratorShare(uint256 _tokenId, address _collaborator, uint256 _newShareBasisPoints) public onlyNFTOwner(_tokenId) whenNotPaused {
        ArtifexNFT storage nft = artifexNFTs[_tokenId];
        require(nft.collaboratorSharesBasisPoints[_collaborator] > 0, "ArtifexForge: Collaborator does not exist");
        require(_newShareBasisPoints <= 10000, "ArtifexForge: Share cannot exceed 100%");

        uint256 currentCollaboratorShare = nft.collaboratorSharesBasisPoints[_collaborator];
        uint256 currentTotalShares = 0;
        for (uint256 i = 0; i < nft.collaborators.length; i++) {
            currentTotalShares = currentTotalShares.add(nft.collaboratorSharesBasisPoints[nft.collaborators[i]]);
        }

        require(currentTotalShares.sub(currentCollaboratorShare).add(_newShareBasisPoints) <= 10000, "ArtifexForge: Total shares exceed 100%");

        nft.collaboratorSharesBasisPoints[_collaborator] = _newShareBasisPoints;

        emit CollaboratorShareUpdated(_tokenId, _collaborator, _newShareBasisPoints);
    }

    /**
     * @dev Removes a collaborator from an NFT's royalty distribution list.
     * @param _tokenId The ID of the NFT.
     * @param _collaborator The address of the collaborator to remove.
     */
    function removeCollaborator(uint256 _tokenId, address _collaborator) public onlyNFTOwner(_tokenId) whenNotPaused {
        ArtifexNFT storage nft = artifexNFTs[_tokenId];
        require(nft.collaboratorSharesBasisPoints[_collaborator] > 0, "ArtifexForge: Collaborator does not exist");
        require(nft.collaborators.length > 1, "ArtifexForge: Cannot remove the last collaborator (owner)");

        // Find and remove collaborator from array (expensive for large arrays)
        bool found = false;
        for (uint256 i = 0; i < nft.collaborators.length; i++) {
            if (nft.collaborators[i] == _collaborator) {
                nft.collaborators[i] = nft.collaborators[nft.collaborators.length - 1]; // Swap with last element
                nft.collaborators.pop(); // Remove last element
                found = true;
                break;
            }
        }
        require(found, "ArtifexForge: Collaborator not found in list");
        delete nft.collaboratorSharesBasisPoints[_collaborator]; // Remove share from mapping

        emit CollaboratorRemoved(_tokenId, _collaborator);
    }

    /**
     * @dev Allows any registered collaborator of an NFT to claim their accumulated royalty share from sales or model usage fees generated by that NFT.
     * @param _tokenId The ID of the NFT.
     */
    function claimCollaboratorRoyalties(uint256 _tokenId) public nonReentrant {
        ArtifexNFT storage nft = artifexNFTs[_tokenId];
        uint256 amountToClaim = nft.earnedRoyalties[msg.sender];
        require(amountToClaim > 0, "ArtifexForge: No royalties to claim");

        nft.earnedRoyalties[msg.sender] = 0; // Reset balance before transfer to prevent re-claiming

        (bool success, ) = payable(msg.sender).call{value: amountToClaim}("");
        require(success, "ArtifexForge: Failed to transfer royalties");

        emit RoyaltiesClaimed(_tokenId, msg.sender, amountToClaim);
    }

    // --- V. Marketplace & Protocol Economics ---

    /**
     * @dev Places an Artifex NFT on the marketplace for a specified price in Wei.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The price in Wei for the NFT.
     */
    function listNFTForSale(uint256 _tokenId, uint256 _price) public onlyNFTOwner(_tokenId) notForSale(_tokenId) whenNotPaused {
        require(_price > 0, "ArtifexForge: Price must be greater than zero");
        nftPrices[_tokenId] = _price;
        emit NFTListedForSale(_tokenId, msg.sender, _price);
    }

    /**
     * @dev Allows a user to purchase a listed NFT, transferring ownership and distributing funds to the seller, collaborators, and protocol fees.
     * @param _tokenId The ID of the NFT to purchase.
     */
    function buyNFT(uint256 _tokenId) public payable whenNotPaused nonReentrant {
        require(_exists(_tokenId), "ArtifexForge: NFT does not exist");
        uint256 price = nftPrices[_tokenId];
        require(price > 0, "ArtifexForge: NFT is not for sale");
        require(msg.value >= price, "ArtifexForge: Insufficient ETH sent");
        require(ownerOf(_tokenId) != msg.sender, "ArtifexForge: Cannot buy your own NFT");

        address seller = ownerOf(_tokenId);
        nftPrices[_tokenId] = 0; // Mark as no longer for sale

        // Calculate protocol fee
        uint256 protocolFee = price.mul(protocolFeeRateBasisPoints).div(10000);
        accumulatedProtocolFees = accumulatedProtocolFees.add(protocolFee);

        // Distribute remaining amount to seller and collaborators
        uint256 remainingAmount = price.sub(protocolFee);
        ArtifexNFT storage nft = artifexNFTs[_tokenId];

        uint256 totalSharesBasisPoints = 0;
        // Calculate the effective total shares for active collaborators
        for (uint256 i = 0; i < nft.collaborators.length; i++) {
            totalSharesBasisPoints = totalSharesBasisPoints.add(nft.collaboratorSharesBasisPoints[nft.collaborators[i]]);
        }
        // This should always be <= 10000 due to add/update/remove checks
        require(totalSharesBasisPoints > 0, "ArtifexForge: No active collaborators to distribute to (internal error)");

        // Distribute to each collaborator based on their share
        for (uint256 i = 0; i < nft.collaborators.length; i++) {
            address collaborator = nft.collaborators[i];
            uint256 share = nft.collaboratorSharesBasisPoints[collaborator];
            uint256 collaboratorAmount = remainingAmount.mul(share).div(totalSharesBasisPoints);
            nft.earnedRoyalties[collaborator] = nft.earnedRoyalties[collaborator].add(collaboratorAmount);
        }

        // Transfer NFT ownership
        _transfer(seller, msg.sender, _tokenId);

        // Refund any excess payment to the buyer
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value.sub(price));
        }

        emit NFTPurchased(_tokenId, msg.sender, price);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated protocol fees from NFT sales and AI model usage.
     */
    function collectProtocolFees() public onlyOwner nonReentrant {
        uint256 amount = accumulatedProtocolFees;
        require(amount > 0, "ArtifexForge: No fees to collect");
        accumulatedProtocolFees = 0; // Reset balance before transfer

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ArtifexForge: Failed to transfer protocol fees");

        emit ProtocolFeesCollected(amount);
    }

    /**
     * @dev Sets the percentage of sale/usage value that goes to the protocol as a fee.
     * @param _newRateBasisPoints The new fee rate in basis points (e.g., 500 for 5%). Max 10000 (100%).
     */
    function setProtocolFeeRate(uint256 _newRateBasisPoints) public onlyOwner {
        require(_newRateBasisPoints <= 10000, "ArtifexForge: Fee rate cannot exceed 100%");
        protocolFeeRateBasisPoints = _newRateBasisPoints;
        emit ProtocolFeeRateUpdated(_newRateBasisPoints);
    }

    // --- VI. Admin & Security ---

    /**
     * @dev An emergency function callable by the owner to pause critical functionalities of the contract,
     *      preventing further operations during incidents.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, restoring normal operation.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Grants or revokes the `AI_MODEL_PROVIDER_ROLE` for a given address,
     *      allowing them to register and manage AI models.
     * @param _provider The address to grant/revoke the role.
     * @param _isProvider True to grant, false to revoke.
     */
    function setAIModelProviderRole(address _provider, bool _isProvider) public onlyOwner {
        isAIModelProvider[_provider] = _isProvider;
    }
}
```