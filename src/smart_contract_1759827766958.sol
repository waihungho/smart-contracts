```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // For potentially storing dynamic metadata URIs

// Mock Chainlink Client interface for demonstration purposes.
// In a real Chainlink integration, this would import
// '@chainlink/contracts/src/v0.8/ChainlinkClient.sol'
// and the contract would inherit from it.
interface IChainlinkOracleClient {
    // This is a simplified representation. A real Chainlink request would involve
    // LINK token payment and a specific `request` function.
    // The `fulfill` function would then be called back by the Chainlink node.
    function requestBytes(
        address _oracle,
        bytes32 _jobId,
        uint256 _fee, // Typically LINK token amount
        bytes memory _data // Encoded parameters for the Chainlink external adapter
    ) external returns (bytes32 requestId);
}

/**
 * @title ChronoGenesisEngine
 * @dev A decentralized platform for an AI-assisted, evolving narrative and world, driven by user prompts and governed by a DAO.
 *
 * @outline
 * This contract orchestrates the creation and evolution of a persistent, generative, and interactive digital world.
 * Users contribute 'Prompts' which are processed by AI Oracles (e.g., Chainlink External Adapters for LLMs/Diffusion Models)
 * to generate 'Narrative Fragments'. These fragments collectively build the 'World' and can be claimed as unique
 * 'World Segments' (ERC721 NFTs). The entire ecosystem is governed by a DAO with liquid democracy, overseeing
 * AI model integration, world parameters, and dispute resolution. A reputation system encourages quality contributions.
 *
 * @function_summary
 *
 * I. Core Engine Initialization & Parameters (3 functions)
 * 1. constructor(): Initializes the ERC721 token, sets initial admin, and calls internal engine setup.
 * 2. _initializeEngine(): (Internal) Sets up initial engine parameters like fees, reputation thresholds, and voting rules.
 * 3. updateEngineParameter(): (DAO-only via proposal) Allows the DAO to modify core engine parameters after a successful governance proposal.
 *
 * II. AI Oracle & Narrative Fragment Management (4 functions)
 * 4. registerAIOracle(): (DAO-only via proposal) Registers a new external AI oracle, defining its address and job ID for generation tasks.
 * 5. requestNarrativeFragmentGeneration(): Allows a user to submit a prompt for AI-driven narrative generation, paying a fee.
 * 6. fulfillNarrativeFragmentGeneration(): (Oracle Callback) Processes the AI's response, creates a new Narrative Fragment, and updates the prompt engineer's reputation.
 * 7. getNarrativeFragmentDetails(): Retrieves the full details of a specific Narrative Fragment.
 *
 * III. World Segment Management (ERC721 Extension) (5 functions)
 * 8. claimWorldSegment(): Allows a user to mint an ERC721 NFT for an unclaimed World Segment, associating it with a Narrative Fragment.
 * 9. proposeWorldSegmentMerge(): (Segment Owner-only) Initiates a DAO proposal to merge two World Segments into a new one.
 * 10. executeWorldSegmentMerge(): (DAO-only via proposal) Finalizes the merge of segments after a successful governance vote, burning originals and minting new.
 * 11. updateWorldSegmentAttributes(): (Segment Owner-only) Allows owners to update mutable metadata (e.g., custom name, external link) for their World Segment.
 * 12. generateWorldSegmentConcept(): (Paid function) Requests AI to generate a *concept* for a new World Segment, returning a Narrative Fragment ID without minting an NFT.
 *
 * IV. Prompt Engineering & Reputation (3 functions)
 * 13. submitPromptForReview(): Allows users to submit prompts for community or curator review before direct AI generation, potentially offering a cheaper path.
 * 14. rateNarrativeFragment(): Allows users (with potential reputation weighting) to rate a Narrative Fragment, impacting the reputation of its creator.
 * 15. getPromptEngineerReputation(): Retrieves the current reputation score for a specific prompt engineer.
 *
 * V. Governance & Proposals (7 functions)
 * 16. createProposal(): Initiates a new DAO proposal for various changes (parameters, AI models, world events).
 * 17. voteOnProposal(): Allows eligible voters to cast a vote on an active proposal, respecting delegated voting power.
 * 18. delegateVote(): Allows a voter to delegate their voting power to another address (liquid democracy).
 * 19. undelegateVote(): Revokes a previously set vote delegation.
 * 20. executeProposal(): Finalizes and enacts a successful DAO proposal after its voting period.
 * 21. proposeAIModelForEngine(): (Reputation-gated) Proposes a new AI model for integration, triggering a DAO vote for approval.
 * 22. resolveContentDispute(): (DAO-only via proposal) Allows the DAO to flag or remove Narrative Fragments deemed problematic (e.g., offensive, off-topic).
 *
 * VI. Utility & Information (3 functions)
 * 23. getProposalDetails(): Retrieves comprehensive information about a specific DAO proposal.
 * 24. getVoteCount(): Returns the current vote tally (yes/no/abstain) for an active proposal.
 * 25. getMinReputationForPromptReview(): Returns the minimum reputation required for submitting prompts for community review.
 */
contract ChronoGenesisEngine is ERC721URIStorage, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- Structs ---

    struct EngineParameters {
        uint256 aiRequestFee;             // Fee in wei for requesting AI generation
        uint256 minReputationForReview;   // Min reputation to submit prompts for review
        uint256 proposalThreshold;        // Min reputation to create a proposal
        uint256 quorumPercentage;         // Percentage of total voting power required for a proposal to pass
        uint256 votingPeriod;             // Duration of voting in seconds
        uint256 minReputationForAIModelProposal; // Min reputation to propose new AI models
        uint256 worldSegmentClaimFee;     // Fee to claim a World Segment
    }

    struct AIOracle {
        address oracleAddress; // The address of the Chainlink oracle or similar
        bytes32 jobId;         // The job ID for Chainlink requests
        bool isActive;         // Is this oracle currently active?
    }

    struct NarrativeFragment {
        uint256 id;
        uint256 timestamp;
        address creator;               // Address of the prompt engineer
        uint256 parentNarrativeId;     // Optional: ID of the fragment this one builds upon
        bytes32 promptHash;            // Hash of the original prompt string or the AI request
        string contentURI;             // URI (e.g., IPFS hash) to the AI-generated content
        bytes32 aiModelId;             // Identifier for the AI model used
        bool isFlagged;                // Flagged by DAO for inappropriate content
    }

    struct WorldSegment {
        uint256 id;
        uint256 genesisNarrativeId;    // The initial NF that defines this segment's origin
        string name;                   // Custom name set by owner
        string descriptionURI;         // URI for richer metadata (e.g., image, detailed lore)
        bool claimed;                  // True if this segment has been minted as an NFT
        uint256 lastEvolutionTimestamp; // Timestamp of the last significant update/evolution
        uint256[] childNarrativeIds;    // IDs of NFs that further describe this segment
    }

    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;            // A short description of the proposal
        uint256 creationTimestamp;
        uint256 votingPeriodEnd;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 abstainVotes;
        ProposalState state;
        bytes callData;                // Data for the function to be called on execution
        address targetContract;        // Target contract for execution
        // Specific fields for certain proposal types to easily retrieve context
        bytes32 aiModelId;             // For AI model proposals
        uint256 paramValue;            // For parameter changes
        string paramName;              // For parameter changes
        uint256[] segmentIdsToMerge;   // For world segment merge proposals
    }

    // --- State Variables ---

    Counters.Counter private _narrativeFragmentIds;
    Counters.Counter private _worldSegmentIds;
    Counters.Counter private _proposalIds;

    mapping(uint256 => NarrativeFragment) public narrativeFragments;
    mapping(uint256 => WorldSegment) public worldSegments;
    mapping(uint256 => uint256[]) public narrativeFragmentChildren; // Maps parent NF ID to child NF IDs

    // Reputation system: maps prompt engineer address to their score
    mapping(address => uint256) public promptEngineerReputation;

    // AI Oracles: maps unique oracle ID (bytes32) to AIOracle struct
    mapping(bytes32 => AIOracle) public aiOracles;
    mapping(bytes32 => address) public requestIdToCreator; // Maps Chainlink request ID to creator address

    // Governance
    mapping(uint256 => Proposal) public proposals;
    mapping(address => address) public delegates;             // For liquid democracy (voter => delegatee)
    mapping(uint256 => mapping(address => bool)) public hasVoted; // Proposal ID => Voter => Voted

    EngineParameters public engineParameters;

    // --- Events ---
    event NarrativeFragmentRequested(uint256 indexed requestId, address indexed creator, bytes32 promptHash, uint256 parentId);
    event NarrativeFragmentGenerated(uint256 indexed fragmentId, address indexed creator, bytes32 aiModelId, string contentURI, uint256 parentId);
    event WorldSegmentClaimed(uint256 indexed segmentId, address indexed owner, uint256 genesisNarrativeId);
    event WorldSegmentMerged(uint256 indexed newSegmentId, address indexed owner, uint256[] mergedFromSegmentIds);
    event ReputationUpdated(address indexed engineer, uint256 newReputation);
    event PromptSubmittedForReview(address indexed submitter, bytes32 promptHash);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event EngineParameterUpdated(string indexed paramName, uint256 newValue);
    event AIOracleRegistered(bytes32 indexed oracleId, address oracleAddress, bytes32 jobId);
    event ContentFlagged(uint256 indexed narrativeFragmentId, address indexed moderator);

    // --- Constructor ---
    constructor(address initialOwner) ERC721("ChronoGenesis World Segment", "CGWS") Ownable(initialOwner) {
        _initializeEngine();
    }

    // --- Modifiers ---
    // In a full DAO, functions intended to be called by the DAO would have a modifier
    // like `onlyDAOExecutor` which verifies `msg.sender` is the DAO's timelock or
    // execution contract. For this example, `onlyOwner` is used as a placeholder
    // for initial setup and demonstrating the *intent* that these functions
    // are for administrative/governance control, typically executed via a DAO proposal.
    modifier onlyDAOExecutor() {
        // Placeholder: In a real DAO, `msg.sender` would be the DAO's executor contract.
        // For this example, we use onlyOwner to simplify, assuming the owner
        // will transfer ownership to a DAO multisig/timelock after deployment.
        require(msg.sender == owner(), "Caller is not the DAO executor or contract owner.");
        _;
    }

    // --- I. Core Engine Initialization & Parameters ---

    /**
     * @dev Internal function to initialize engine parameters. Called by the constructor.
     */
    function _initializeEngine() internal {
        engineParameters.aiRequestFee = 0.001 ether; // Example: 0.001 ETH per AI request
        engineParameters.minReputationForReview = 10;
        engineParameters.proposalThreshold = 100; // Example: 100 reputation
        engineParameters.quorumPercentage = 4;    // Example: 4% of total voting power
        engineParameters.votingPeriod = 5 days;   // Example: 5 days for voting
        engineParameters.minReputationForAIModelProposal = 50;
        engineParameters.worldSegmentClaimFee = 0.01 ether; // Example: 0.01 ETH to claim a segment
    }

    /**
     * @dev Allows the DAO to modify core engine parameters.
     *      This function is intended to be called by the `executeProposal` function
     *      after a successful DAO vote.
     * @param _paramName The name of the parameter to update.
     * @param _newValue The new value for the parameter.
     */
    function updateEngineParameter(string calldata _paramName, uint256 _newValue) external onlyDAOExecutor {
        bytes32 paramNameHash = keccak256(abi.encodePacked(_paramName));
        if (paramNameHash == keccak256(abi.encodePacked("aiRequestFee"))) {
            engineParameters.aiRequestFee = _newValue;
        } else if (paramNameHash == keccak256(abi.encodePacked("minReputationForReview"))) {
            engineParameters.minReputationForReview = _newValue;
        } else if (paramNameHash == keccak256(abi.encodePacked("proposalThreshold"))) {
            engineParameters.proposalThreshold = _newValue;
        } else if (paramNameHash == keccak256(abi.encodePacked("quorumPercentage"))) {
            require(_newValue <= 100, "Quorum percentage cannot exceed 100");
            engineParameters.quorumPercentage = _newValue;
        } else if (paramNameHash == keccak256(abi.encodePacked("votingPeriod"))) {
            engineParameters.votingPeriod = _newValue;
        } else if (paramNameHash == keccak256(abi.encodePacked("minReputationForAIModelProposal"))) {
            engineParameters.minReputationForAIModelProposal = _newValue;
        } else if (paramNameHash == keccak256(abi.encodePacked("worldSegmentClaimFee"))) {
            engineParameters.worldSegmentClaimFee = _newValue;
        } else {
            revert("Unknown parameter name");
        }
        emit EngineParameterUpdated(_paramName, _newValue);
    }

    // --- II. AI Oracle & Narrative Fragment Management ---

    /**
     * @dev Registers a new external AI oracle that the engine can use for generation.
     *      This function is intended to be called by the `executeProposal` function
     *      after a successful DAO vote approving the new oracle.
     * @param _oracleId A unique identifier for this oracle.
     * @param _oracleAddress The on-chain address of the oracle smart contract (e.g., Chainlink external adapter).
     * @param _jobId The Chainlink Job ID or similar identifier for the specific AI task.
     */
    function registerAIOracle(bytes32 _oracleId, address _oracleAddress, bytes32 _jobId) external onlyDAOExecutor {
        require(_oracleAddress != address(0), "Invalid oracle address");
        require(aiOracles[_oracleId].oracleAddress == address(0), "Oracle ID already registered");

        aiOracles[_oracleId] = AIOracle({
            oracleAddress: _oracleAddress,
            jobId: _jobId,
            isActive: true
        });
        emit AIOracleRegistered(_oracleId, _oracleAddress, _jobId);
    }

    /**
     * @dev Allows a user to submit a prompt for AI-driven narrative generation.
     *      Requires payment of the `aiRequestFee`.
     * @param _oracleId The ID of the AI oracle to use.
     * @param _prompt The natural language prompt for the AI.
     * @param _parentNarrativeId Optional: The ID of a Narrative Fragment this new one builds upon. Set to 0 if none.
     * @return requestId The ID of the Chainlink request (or similar).
     */
    function requestNarrativeFragmentGeneration(bytes32 _oracleId, string calldata _prompt, uint256 _parentNarrativeId)
        external
        payable
        nonReentrant
        returns (bytes32 requestId)
    {
        require(msg.value >= engineParameters.aiRequestFee, "Insufficient fee for AI request");
        require(aiOracles[_oracleId].isActive, "Oracle is not active");
        if (_parentNarrativeId != 0) {
            require(narrativeFragments[_parentNarrativeId].id == _parentNarrativeId, "Parent narrative fragment does not exist");
        }

        // Refund any excess payment
        if (msg.value > engineParameters.aiRequestFee) {
            payable(msg.sender).transfer(msg.value.sub(engineParameters.aiRequestFee));
        }

        // Simulating the Chainlink request. In a real scenario, this would be an actual external call.
        // For example:
        // IChainlinkOracleClient(aiOracles[_oracleId].oracleAddress).requestBytes(
        //     aiOracles[_oracleId].oracleAddress,
        //     aiOracles[_oracleId].jobId,
        //     LINK_TOKEN.balanceOf(address(this)), // Assuming LINK for fees
        //     abi.encodeCall(this.fulfillNarrativeFragmentGeneration, (requestId, _prompt, _parentNarrativeId, _oracleId))
        // );
        // For simplicity and to avoid LINK token integration, we'll mock the `requestId`.
        bytes32 mockRequestId = keccak256(abi.encodePacked(msg.sender, block.timestamp, _prompt, _parentNarrativeId));
        requestIdToCreator[mockRequestId] = msg.sender; // Store creator for later callback verification
        // Storing prompt hash and parent ID for retrieval in fulfill function
        _narrativeFragmentIds.increment(); // Pre-allocate an ID for the fragment
        uint256 preAllocatedFragmentId = _narrativeFragmentIds.current();
        requestIdToCreator[keccak256(abi.encodePacked("promptHash", mockRequestId))] = address(uint160(uint256(keccak256(abi.encodePacked(_prompt)))));
        requestIdToCreator[keccak256(abi.encodePacked("parentId", mockRequestId))] = address(uint160(_parentNarrativeId));
        requestIdToCreator[keccak256(abi.encodePacked("fragmentId", mockRequestId))] = address(uint160(preAllocatedFragmentId));

        emit NarrativeFragmentRequested(uint256(mockRequestId), msg.sender, keccak256(abi.encodePacked(_prompt)), _parentNarrativeId);
        return mockRequestId;
    }

    /**
     * @dev Callback function from the AI Oracle (e.g., Chainlink) after generating content.
     *      This function creates a new Narrative Fragment and updates the creator's reputation.
     *      This function must be called by the registered oracle address.
     * @param _requestId The ID of the original request.
     * @param _generatedContentURI URI (e.g., IPFS hash) to the AI-generated content.
     * @param _aiModelId The identifier of the specific AI model that produced the content.
     */
    function fulfillNarrativeFragmentGeneration(
        bytes32 _requestId,
        string calldata _generatedContentURI,
        bytes32 _aiModelId
    ) external nonReentrant {
        address creator = requestIdToCreator[_requestId];
        require(creator != address(0), "Request ID not found or already fulfilled.");
        // In production, `msg.sender` should be verified against registered `aiOracles[_aiModelId].oracleAddress`.
        // For this example, we trust the `requestIdToCreator` mapping to be indicative.

        // Retrieve stored data for the request
        uint256 preAllocatedFragmentId = uint256(uint160(requestIdToCreator[keccak256(abi.encodePacked("fragmentId", _requestId))]));
        bytes32 originalPromptHash = bytes32(uint256(uint160(requestIdToCreator[keccak256(abi.encodePacked("promptHash", _requestId))])));
        uint256 parentNarrativeId = uint256(uint160(requestIdToCreator[keccak256(abi.encodePacked("parentId", _requestId))]));

        // Clear request-related data to prevent replay attacks and save gas
        delete requestIdToCreator[_requestId];
        delete requestIdToCreator[keccak256(abi.encodePacked("promptHash", _requestId))];
        delete requestIdToCreator[keccak256(abi.encodePacked("parentId", _requestId))];
        delete requestIdToCreator[keccak256(abi.encodePacked("fragmentId", _requestId))];

        NarrativeFragment storage newNF = narrativeFragments[preAllocatedFragmentId];
        newNF.id = preAllocatedFragmentId;
        newNF.timestamp = block.timestamp;
        newNF.creator = creator;
        newNF.promptHash = originalPromptHash;
        newNF.parentNarrativeId = parentNarrativeId;
        newNF.contentURI = _generatedContentURI;
        newNF.aiModelId = _aiModelId;
        newNF.isFlagged = false;

        // Optionally, update parent-child relationship
        if (newNF.parentNarrativeId != 0) {
            narrativeFragmentChildren[newNF.parentNarrativeId].push(preAllocatedFragmentId);
        }

        // Award reputation to the prompt engineer (initial boost)
        promptEngineerReputation[creator] = promptEngineerReputation[creator].add(5); // Example: 5 points
        emit ReputationUpdated(creator, promptEngineerReputation[creator]);
        emit NarrativeFragmentGenerated(preAllocatedFragmentId, creator, _aiModelId, _generatedContentURI, newNF.parentNarrativeId);
    }

    /**
     * @dev Retrieves the details of a specific Narrative Fragment.
     * @param _fragmentId The ID of the Narrative Fragment.
     * @return A tuple containing all details of the Narrative Fragment.
     */
    function getNarrativeFragmentDetails(uint256 _fragmentId)
        external
        view
        returns (uint256 id, uint256 timestamp, address creator, uint256 parentNarrativeId, bytes32 promptHash, string memory contentURI, bytes32 aiModelId, bool isFlagged)
    {
        NarrativeFragment storage nf = narrativeFragments[_fragmentId];
        require(nf.id == _fragmentId, "Narrative Fragment does not exist");
        return (nf.id, nf.timestamp, nf.creator, nf.parentNarrativeId, nf.promptHash, nf.contentURI, nf.aiModelId, nf.isFlagged);
    }

    // --- III. World Segment Management (ERC721 Extension) ---

    /**
     * @dev Allows a user to claim an "unclaimed" World Segment by minting an NFT.
     *      This makes the World Segment owned and provides a unique ERC721 token.
     *      The segment is associated with a specific Narrative Fragment.
     * @param _genesisNarrativeId The ID of the Narrative Fragment that defines this segment.
     * @param _name The initial name for this World Segment.
     * @param _descriptionURI Optional URI for richer segment metadata (e.g., image, detailed lore).
     */
    function claimWorldSegment(uint256 _genesisNarrativeId, string calldata _name, string calldata _descriptionURI)
        external
        payable
        nonReentrant
    {
        require(narrativeFragments[_genesisNarrativeId].id == _genesisNarrativeId, "Genesis Narrative Fragment does not exist");
        require(msg.value >= engineParameters.worldSegmentClaimFee, "Insufficient fee to claim World Segment");

        _worldSegmentIds.increment();
        uint256 newSegmentId = _worldSegmentIds.current();

        WorldSegment storage newWS = worldSegments[newSegmentId];
        newWS.id = newSegmentId;
        newWS.genesisNarrativeId = _genesisNarrativeId;
        newWS.name = _name;
        newWS.descriptionURI = _descriptionURI;
        newWS.claimed = true;
        newWS.lastEvolutionTimestamp = block.timestamp;
        newWS.childNarrativeIds.push(_genesisNarrativeId); // The genesis narrative is the first child

        _safeMint(msg.sender, newSegmentId);
        _setTokenURI(newSegmentId, _descriptionURI); // Set ERC721 URI

        // Refund any excess payment
        if (msg.value > engineParameters.worldSegmentClaimFee) {
            payable(msg.sender).transfer(msg.value.sub(engineParameters.worldSegmentClaimFee));
        }

        emit WorldSegmentClaimed(newSegmentId, msg.sender, _genesisNarrativeId);
    }

    /**
     * @dev Proposes to merge two or more existing World Segments into a new one.
     *      Requires ownership of all segments to be merged by the proposer. Triggers a DAO proposal.
     * @param _segmentIdsToMerge An array of World Segment IDs to be merged.
     * @param _newName The name for the new merged segment.
     * @param _newDescriptionURI URI for the metadata of the new merged segment.
     * @param _proposalDescription A description for the DAO proposal.
     */
    function proposeWorldSegmentMerge(
        uint256[] calldata _segmentIdsToMerge,
        string calldata _newName,
        string calldata _newDescriptionURI,
        string calldata _proposalDescription
    ) external {
        require(_segmentIdsToMerge.length >= 2, "Must propose merging at least two segments.");
        for (uint256 i = 0; i < _segmentIdsToMerge.length; i++) {
            require(ownerOf(_segmentIdsToMerge[i]) == msg.sender, "Must own all segments to be merged.");
            require(worldSegments[_segmentIdsToMerge[i]].id == _segmentIdsToMerge[i], "Segment does not exist.");
        }

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: _proposalDescription,
            creationTimestamp: block.timestamp,
            votingPeriodEnd: block.timestamp.add(engineParameters.votingPeriod),
            yesVotes: 0,
            noVotes: 0,
            abstainVotes: 0,
            state: ProposalState.Pending,
            callData: abi.encodeWithSelector(this.executeWorldSegmentMerge.selector, _segmentIdsToMerge, _newName, _newDescriptionURI),
            targetContract: address(this),
            aiModelId: bytes32(0),
            paramValue: 0,
            paramName: "",
            segmentIdsToMerge: _segmentIdsToMerge // Store for easy retrieval in proposal details
        });

        emit ProposalCreated(proposalId, msg.sender, _proposalDescription);
    }

    /**
     * @dev Executes the merge of World Segments after a successful DAO vote.
     *      This function is intended to be called by the `executeProposal` function.
     *      Burns the original segments and mints a new one.
     * @param _segmentIdsToMerge The IDs of the segments to merge.
     * @param _newName The name of the new merged segment.
     * @param _newDescriptionURI URI for the new segment's metadata.
     */
    function executeWorldSegmentMerge(
        uint256[] calldata _segmentIdsToMerge,
        string calldata _newName,
        string calldata _newDescriptionURI
    ) external onlyDAOExecutor {
        require(_segmentIdsToMerge.length >= 2, "Must merge at least two segments.");
        address newOwner = ownerOf(_segmentIdsToMerge[0]); // Assumes all merged segments have the same owner or proposal specifies new owner

        // Burn original segments
        for (uint256 i = 0; i < _segmentIdsToMerge.length; i++) {
            require(ownerOf(_segmentIdsToMerge[i]) == newOwner, "All segments must have the same owner to merge directly.");
            _burn(_segmentIdsToMerge[i]);
            delete worldSegments[_segmentIdsToMerge[i]]; // Remove from our custom mapping
        }

        _worldSegmentIds.increment();
        uint256 newSegmentId = _worldSegmentIds.current();

        WorldSegment storage newWS = worldSegments[newSegmentId];
        newWS.id = newSegmentId;
        newWS.genesisNarrativeId = worldSegments[_segmentIdsToMerge[0]].genesisNarrativeId; // Take genesis from first
        newWS.name = _newName;
        newWS.descriptionURI = _newDescriptionURI;
        newWS.claimed = true;
        newWS.lastEvolutionTimestamp = block.timestamp;
        // Combine child narrative IDs from all merged segments
        for (uint256 i = 0; i < _segmentIdsToMerge.length; i++) {
            for (uint256 j = 0; j < worldSegments[_segmentIdsToMerge[i]].childNarrativeIds.length; j++) {
                newWS.childNarrativeIds.push(worldSegments[_segmentIdsToMerge[i]].childNarrativeIds[j]);
            }
        }

        _safeMint(newOwner, newSegmentId);
        _setTokenURI(newSegmentId, _newDescriptionURI);

        emit WorldSegmentMerged(newSegmentId, newOwner, _segmentIdsToMerge);
    }

    /**
     * @dev Allows the owner of a World Segment to update its mutable attributes.
     * @param _segmentId The ID of the World Segment.
     * @param _newName The new custom name for the segment.
     * @param _newDescriptionURI The new URI for richer metadata.
     */
    function updateWorldSegmentAttributes(uint256 _segmentId, string calldata _newName, string calldata _newDescriptionURI)
        external
        nonReentrant
    {
        require(ownerOf(_segmentId) == msg.sender, "Only the owner can update segment attributes.");
        WorldSegment storage ws = worldSegments[_segmentId];
        require(ws.id == _segmentId, "World Segment does not exist.");

        ws.name = _newName;
        ws.descriptionURI = _newDescriptionURI;
        _setTokenURI(_segmentId, _newDescriptionURI); // Update ERC721 URI as well
    }

    /**
     * @dev Requests AI to generate a *concept* for a new World Segment.
     *      This does not mint an NFT but returns a Narrative Fragment ID for the concept.
     *      Similar to `requestNarrativeFragmentGeneration` but specifically for world segment concepts.
     * @param _oracleId The ID of the AI oracle to use.
     * @param _conceptPrompt A detailed prompt for the AI to generate a segment concept.
     * @return newFragmentId The ID of the Narrative Fragment representing the generated concept.
     */
    function generateWorldSegmentConcept(bytes32 _oracleId, string calldata _conceptPrompt)
        external
        payable
        nonReentrant
        returns (uint256 newFragmentId)
    {
        require(msg.value >= engineParameters.aiRequestFee, "Insufficient fee for AI concept generation");
        require(aiOracles[_oracleId].isActive, "Oracle is not active");

        if (msg.value > engineParameters.aiRequestFee) {
            payable(msg.sender).transfer(msg.value.sub(engineParameters.aiRequestFee));
        }

        // Simulating AI request and fulfillment for concept.
        // In a real scenario, this would be a two-step process similar to `requestNarrativeFragmentGeneration`.
        // For simplicity, we'll directly generate a mock fragment ID here for the concept.
        _narrativeFragmentIds.increment();
        newFragmentId = _narrativeFragmentIds.current();

        NarrativeFragment storage newNF = narrativeFragments[newFragmentId];
        newNF.id = newFragmentId;
        newNF.timestamp = block.timestamp;
        newNF.creator = msg.sender;
        newNF.promptHash = keccak256(abi.encodePacked(_conceptPrompt));
        newNF.contentURI = "ipfs://mock_concept_uri_" + _conceptPrompt; // Mock URI
        newNF.aiModelId = _oracleId; // Using oracle ID as model ID for mock
        newNF.isFlagged = false;

        // Award reputation for concept submission
        promptEngineerReputation[msg.sender] = promptEngineerReputation[msg.sender].add(3); // Example: 3 points
        emit ReputationUpdated(msg.sender, promptEngineerReputation[msg.sender]);
        emit NarrativeFragmentGenerated(newFragmentId, msg.sender, _oracleId, newNF.contentURI, 0);

        return newFragmentId;
    }

    // --- IV. Prompt Engineering & Reputation ---

    /**
     * @dev Allows users to submit prompts for community or curator review before direct AI generation.
     *      Requires a minimum reputation score.
     * @param _prompt The prompt string to be reviewed.
     * @param _category Optional category for the prompt (e.g., "lore", "creature", "landscape").
     */
    function submitPromptForReview(string calldata _prompt, string calldata _category) external {
        require(promptEngineerReputation[msg.sender] >= engineParameters.minReputationForReview, "Insufficient reputation for prompt review submission.");
        // In a full system, this would store the prompt in a queue for review by curators
        // or for voting by other high-reputation members.
        // For this example, we just emit an event.
        emit PromptSubmittedForReview(msg.sender, keccak256(abi.encodePacked(_prompt, _category)));
    }

    /**
     * @dev Allows users to rate a specific Narrative Fragment, impacting the reputation of its creator.
     *      Voting power could be weighted by reputation or token holdings.
     * @param _fragmentId The ID of the Narrative Fragment to rate.
     * @param _score The rating (e.g., 1 for bad, 5 for excellent).
     */
    function rateNarrativeFragment(uint256 _fragmentId, uint8 _score) external {
        require(narrativeFragments[_fragmentId].id == _fragmentId, "Narrative Fragment does not exist.");
        require(narrativeFragments[_fragmentId].creator != msg.sender, "Cannot rate your own fragment.");
        require(_score >= 1 && _score <= 5, "Score must be between 1 and 5.");

        address creator = narrativeFragments[_fragmentId].creator;
        uint256 currentReputation = promptEngineerReputation[creator];
        uint256 voterReputation = promptEngineerReputation[msg.sender]; // Using voter's reputation as influence weight

        // Simple reputation adjustment logic based on score:
        int256 reputationChange;
        if (_score == 1) reputationChange = -5;
        else if (_score == 2) reputationChange = -2;
        else if (_score == 3) reputationChange = 0;
        else if (_score == 4) reputationChange = 2;
        else if (_score == 5) reputationChange = 5;
        else reputationChange = 0; // Should not happen due to require statement

        // Adjust reputation based on voter's reputation (simple multiplier)
        uint256 multiplier = voterReputation.div(10).add(1); // Min multiplier 1, increases by 1 for every 10 rep
        
        uint256 finalRepChange = uint256(reputationChange).mul(multiplier);

        if (reputationChange > 0) {
            promptEngineerReputation[creator] = currentReputation.add(finalRepChange);
        } else if (reputationChange < 0) {
            promptEngineerReputation[creator] = currentReputation.sub(finalRepChange);
        }

        emit ReputationUpdated(creator, promptEngineerReputation[creator]);
    }

    /**
     * @dev Retrieves the current reputation score for a given address.
     * @param _engineer The address of the prompt engineer.
     * @return The current reputation score.
     */
    function getPromptEngineerReputation(address _engineer) external view returns (uint256) {
        return promptEngineerReputation[_engineer];
    }

    // --- V. Governance & Proposals ---

    /**
     * @dev Creates a new DAO proposal. Requires a minimum reputation score.
     * @param _description A detailed description of the proposal.
     * @param _targetContract The address of the contract the proposal will interact with (e.g., this contract).
     * @param _callData The encoded function call (selector + arguments) for execution.
     */
    function createProposal(string calldata _description, address _targetContract, bytes calldata _callData)
        external
    {
        require(promptEngineerReputation[msg.sender] >= engineParameters.proposalThreshold, "Insufficient reputation to create a proposal.");
        require(_targetContract != address(0), "Target contract cannot be zero address.");
        require(_callData.length > 0, "Call data cannot be empty.");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            creationTimestamp: block.timestamp,
            votingPeriodEnd: block.timestamp.add(engineParameters.votingPeriod),
            yesVotes: 0,
            noVotes: 0,
            abstainVotes: 0,
            state: ProposalState.Pending,
            callData: _callData,
            targetContract: _targetContract,
            aiModelId: bytes32(0),
            paramValue: 0,
            paramName: "",
            segmentIdsToMerge: new uint256[](0) // Initialize empty array
        });

        emit ProposalCreated(proposalId, msg.sender, _description);
    }

    /**
     * @dev Allows an eligible voter to cast a vote on an active proposal.
     *      Implements liquid democracy where voting power can be delegated.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support 0 for 'No', 1 for 'Yes', 2 for 'Abstain'.
     */
    function voteOnProposal(uint256 _proposalId, uint8 _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "Proposal does not exist.");
        require(proposal.creationTimestamp > 0, "Proposal not yet active."); // Ensure initialized
        require(block.timestamp <= proposal.votingPeriodEnd, "Voting period has ended.");
        require(!hasVoted[_proposalId][msg.sender], "Already voted on this proposal.");

        // Get effective voter (after delegation)
        address voter = delegates[msg.sender] == address(0) ? msg.sender : delegates[msg.sender];
        uint256 voterReputation = promptEngineerReputation[voter]; // Using reputation as voting power for this example
        require(voterReputation > 0, "Voter has no voting power.");

        // Set proposal state to Active if it was Pending
        if (proposal.state == ProposalState.Pending) {
            proposal.state = ProposalState.Active;
        }

        if (_support == 0) { // No
            proposal.noVotes = proposal.noVotes.add(voterReputation);
        } else if (_support == 1) { // Yes
            proposal.yesVotes = proposal.yesVotes.add(voterReputation);
        } else if (_support == 2) { // Abstain
            proposal.abstainVotes = proposal.abstainVotes.add(voterReputation);
        } else {
            revert("Invalid support option (0=No, 1=Yes, 2=Abstain).");
        }

        hasVoted[_proposalId][msg.sender] = true;
        emit VoteCast(_proposalId, msg.sender, _support == 1, voterReputation);
    }

    /**
     * @dev Delegates voting power to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVote(address _delegatee) external {
        require(_delegatee != address(0), "Delegatee cannot be zero address.");
        require(_delegatee != msg.sender, "Cannot delegate to yourself.");
        delegates[msg.sender] = _delegatee;
    }

    /**
     * @dev Revokes a previously set vote delegation.
     */
    function undelegateVote() external {
        delete delegates[msg.sender];
    }

    /**
     * @dev Executes a successful DAO proposal after its voting period has ended.
     *      Anyone can call this, but it will only succeed if the proposal passed.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "Proposal does not exist.");
        require(proposal.state != ProposalState.Executed, "Proposal already executed.");
        require(block.timestamp > proposal.votingPeriodEnd, "Voting period has not ended.");
        require(proposal.state == ProposalState.Active || proposal.state == ProposalState.Pending, "Proposal is not active or pending.");

        uint256 totalActiveVotes = proposal.yesVotes.add(proposal.noVotes);
        require(totalActiveVotes > 0, "No active votes cast for this proposal.");

        // Calculate total possible voting power for quorum check.
        // In a real DAO, this would be a snapshot taken at proposal creation or sum of all reputation.
        // For this example, we use a placeholder total to illustrate the concept.
        uint256 totalVotingPowerSnapshot = 1_000_000; // Placeholder: Assume 1M reputation points as total supply

        bool passedQuorum = totalActiveVotes >= totalVotingPowerSnapshot.mul(engineParameters.quorumPercentage).div(100);
        bool passedThreshold = proposal.yesVotes > proposal.noVotes;

        if (passedQuorum && passedThreshold) {
            proposal.state = ProposalState.Succeeded;

            // Execute the proposal's intended action
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            require(success, "Proposal execution failed.");

            proposal.state = ProposalState.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.state = ProposalState.Defeated;
            revert("Proposal did not meet quorum or voting threshold.");
        }
    }

    /**
     * @dev Allows a high-reputation engineer to propose a new AI model for integration.
     *      This triggers a DAO proposal for approval.
     * @param _modelId A unique identifier for the proposed AI model.
     * @param _description A description of the model, its capabilities, and how it can be used.
     * @param _oracleAddress The address of the oracle that can interface with this model.
     * @param _jobId The Chainlink Job ID or similar for this model.
     */
    function proposeAIModelForEngine(bytes32 _modelId, string calldata _description, address _oracleAddress, bytes32 _jobId)
        external
    {
        require(promptEngineerReputation[msg.sender] >= engineParameters.minReputationForAIModelProposal, "Insufficient reputation to propose an AI model.");
        require(aiOracles[_modelId].oracleAddress == address(0), "AI Model ID already exists or is reserved.");
        require(_oracleAddress != address(0), "Oracle address cannot be zero.");

        // Create a proposal to register this AI oracle
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        // Encode the call to `registerAIOracle` for execution
        bytes memory callData = abi.encodeWithSelector(this.registerAIOracle.selector, _modelId, _oracleAddress, _jobId);

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: string(abi.encodePacked("Propose new AI Model (", _description, ")")),
            creationTimestamp: block.timestamp,
            votingPeriodEnd: block.timestamp.add(engineParameters.votingPeriod),
            yesVotes: 0,
            noVotes: 0,
            abstainVotes: 0,
            state: ProposalState.Pending,
            callData: callData,
            targetContract: address(this),
            aiModelId: _modelId, // Store the model ID in the proposal struct
            paramValue: 0,
            paramName: "",
            segmentIdsToMerge: new uint256[](0)
        });

        emit ProposalCreated(proposalId, msg.sender, "AI Model Proposal: ".concat(_description));
    }

    /**
     * @dev Allows the DAO to flag or resolve disputes about Narrative Fragments (e.g., offensive, off-topic).
     *      This function is intended to be called by the `executeProposal` function
     *      after a successful DAO vote.
     * @param _fragmentId The ID of the Narrative Fragment to flag.
     * @param _flaggedStatus True to flag, false to unflag/resolve.
     */
    function resolveContentDispute(uint256 _fragmentId, bool _flaggedStatus) external onlyDAOExecutor {
        require(narrativeFragments[_fragmentId].id == _fragmentId, "Narrative Fragment does not exist.");
        narrativeFragments[_fragmentId].isFlagged = _flaggedStatus;
        emit ContentFlagged(_fragmentId, msg.sender);
    }

    // --- VI. Utility & Information ---

    /**
     * @dev Retrieves comprehensive information about a specific DAO proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing all details of the proposal.
     */
    function getProposalDetails(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory description,
            uint256 creationTimestamp,
            uint256 votingPeriodEnd,
            uint256 yesVotes,
            uint256 noVotes,
            uint256 abstainVotes,
            ProposalState state,
            bytes memory callData,
            address targetContract,
            bytes32 aiModelId,
            uint256 paramValue,
            string memory paramName,
            uint256[] memory segmentIdsToMerge
        )
    {
        Proposal storage p = proposals[_proposalId];
        require(p.id == _proposalId, "Proposal does not exist.");
        return (
            p.id,
            p.proposer,
            p.description,
            p.creationTimestamp,
            p.votingPeriodEnd,
            p.yesVotes,
            p.noVotes,
            p.abstainVotes,
            p.state,
            p.callData,
            p.targetContract,
            p.aiModelId,
            p.paramValue,
            p.paramName,
            p.segmentIdsToMerge
        );
    }

    /**
     * @dev Returns the current vote tally for a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return yes The total 'Yes' votes.
     * @return no The total 'No' votes.
     * @return abstain The total 'Abstain' votes.
     */
    function getVoteCount(uint256 _proposalId) external view returns (uint256 yes, uint256 no, uint256 abstain) {
        Proposal storage p = proposals[_proposalId];
        require(p.id == _proposalId, "Proposal does not exist.");
        return (p.yesVotes, p.noVotes, p.abstainVotes);
    }

    /**
     * @dev Returns the minimum reputation required for submitting prompts for community review.
     * @return The minimum reputation score.
     */
    function getMinReputationForPromptReview() external view returns (uint256) {
        return engineParameters.minReputationForReview;
    }

    // --- ERC721 Overrides (for tokenURI) ---
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return worldSegments[tokenId].descriptionURI;
    }
}
```