Here's a Solidity smart contract, "NeuralCanvasProtocol," designed with advanced, creative, and trendy concepts related to decentralized AI, NFTs, and community governance. It avoids direct duplication of common open-source projects by combining these elements in a unique operational flow, especially concerning AI agent evolution, reputation, and dynamic content royalties.

This contract serves as a platform where:
1.  **AI Agents are NFTs**: Users can register and own generative AI models (represented as NFTs), which can be specialized for various content types (art, text, music, etc.).
2.  **Decentralized Training Data**: Users contribute training datasets (referenced by IPFS hashes) and are rewarded based on community curation.
3.  **Content Generation & Curation**: Users request content from AI Agents, which then submit the generated output (IPFS hashes). Community members provide feedback, influencing agent reputation.
4.  **Dynamic NFTs & Royalties**: Generated content can be minted as NFTs, with royalties distributed upon sale to the agent owner, data contributors, and the protocol treasury based on configurable percentages.
5.  **Agent Evolution & Reputation**: AI Agents have a dynamic reputation score, influenced by content quality, feedback, and successful data utilization. Agents can undergo "evolution" (model updates) approved by community governance.
6.  **Simplified DAO Governance**: The contract includes basic governance mechanisms for parameter tuning and agent evolution, representing a future decentralized autonomous organization.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath for older versions, for 0.8.x it's mostly implicit but good for clarity on some ops
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

// Outline and Function Summary:
// This contract, "NeuralCanvasProtocol," establishes a decentralized platform for
// AI-powered content generation and curation. It allows users to register AI Agents
// (as NFTs), contribute training data, request content generation, provide feedback,
// and mint generated content as NFTs with a sophisticated royalty distribution system.
// The protocol incorporates a dynamic reputation system for AI Agents and data contributors,
// and a community-driven evolution mechanism for agents.

// --- I. Core Infrastructure & Ownership (AI Agent NFT Management) ---
// 1. constructor(): Initializes the contract, sets the initial owner, treasury address, and initial fees.
// 2. registerAI_Agent(string memory _agentMetadataURI): Mints a new AI Agent NFT, linking it to its off-chain model parameters/metadata via IPFS.
// 3. updateAgentMetadata(uint256 _agentId, string memory _newMetadataURI): Allows the agent owner to update the IPFS hash for their agent's model/parameters.
// 4. setAgentGenerationFee(uint256 _agentId, uint256 _fee): Sets the fee required to request content generation from a specific AI Agent.
// 5. withdrawProtocolFunds(address _to, uint256 _amount): Allows the owner (acting as DAO) to withdraw accumulated fees from the protocol treasury.
// 6. pauseContract(): Pauses core contract functionality in emergencies.
// 7. unpauseContract(): Unpauses the contract after an emergency.

// --- II. AI Agent Management & Evolution ---
// 8. submitTrainingData(string memory _dataURI): Users submit a hash of training data (via IPFS URI), staking tokens as a commitment.
// 9. curateTrainingData(uint256 _submissionId, bool _isApproved): Owner (acting as DAO) approves/rejects submitted training data. Rewards approved, penalizes rejected.
// 10. penalizeDataContributor(uint256 _submissionId, uint256 _penaltyAmount): Allows the DAO to explicitly penalize a data contributor for malicious submissions.
// 11. requestAgentEvolution(uint256 _agentId, string memory _newModelURI, string memory _evolutionProposalURI): Proposes an evolution for an AI Agent, linking to new model parameters and a proposal description. Requires community/DAO approval.
// 12. finalizeAgentEvolution(uint256 _evolutionProposalId): Executes an approved evolution proposal, updating the agent's model hash and potentially reputation.
// 13. updateAgentReputationBoost(uint256 _agentId, int256 _boostValue): Allows the DAO to adjust an agent's reputation score (e.g., for exceptional performance or infractions).

// --- III. Content Generation & Curation (Generated Content NFT Management) ---
// 14. requestContentGeneration(uint256 _agentId, string memory _promptHash): Users request content generation from an AI Agent, paying the agent's fee. Records the request.
// 15. submitGeneratedContent(uint256 _generationRequestId, string memory _contentURI): The AI Agent owner submits the hash of the generated content (after off-chain generation).
// 16. submitContentFeedback(uint256 _generationRequestId, int8 _score, string memory _category): Users provide feedback (e.g., score -5 to 5, category tag) on generated content, influencing the agent's reputation. Requires a small stake to deter spam.
// 17. mintGeneratedContentNFT(uint252 _generationRequestId, string memory _nftMetadataURI): Mints a new NFT (different from AI Agent NFT) for selected generated content.
// 18. getContentNFTOwner(uint256 _contentNFTId): Returns the current owner of a specific Generated Content NFT.
// 19. getContentNFTURI(uint256 _contentNFTId): Returns the URI for a specific Generated Content NFT.
// 20. transferContentNFT(address _from, address _to, uint256 _contentNFTId): Facilitates direct transfer of a Generated Content NFT (simplified for P2P, without sales logic).
// 21. buyGeneratedContentNFT(uint256 _contentNFTId, uint256 _price): Allows buying minted content NFTs, distributing royalties to agent owner, data contributors (via agent owner), and protocol.
// 22. setRoyaltySplitPercentages(uint256 _protocolShare, uint256 _agentShare, uint256 _dataContributorShare): DAO sets the royalty distribution percentages for minted NFTs.
// 23. getAgentReputation(uint256 _agentId): Retrieves an agent's current calculated reputation score.
// 24. getAgentGenerationHistory(uint256 _agentId, uint256 _offset, uint256 _limit): Retrieves a paginated list of a specific agent's generation requests and submitted content.

// --- IV. Governance & Parameter Tuning ---
// 25. proposeParameterChange(bytes32 _parameterKey, uint256 _newValue, string memory _proposalURI): Allows DAO members (owner for now) to propose changes to core contract parameters.
// 26. voteOnProposal(uint256 _proposalId, bool _support): Users vote on active Agent Evolution or Governance proposals.
// 27. executeProposal(uint256 _proposalId): Executes an approved governance proposal, applying the parameter change.
// 28. setMinimumFeedbackStake(uint256 _newStake): DAO can set minimum stake required for giving feedback to prevent spam/sybil attacks.


contract NeuralCanvasProtocol is ERC721URIStorage, Pausable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    // AI Agents (ERC721 NFTs - "NeuralCanvas AI Agent" token type)
    Counters.Counter private _agentTokenIds;
    struct AI_Agent {
        address owner;
        string metadataURI; // IPFS hash to model parameters, code, etc.
        uint256 generationFee; // Fee to request content generation from this agent
        uint256 reputation; // Accumulated reputation based on feedback, data quality, etc.
        uint256 lastEvolutionBlock; // Block number of last evolution
    }
    mapping(uint256 => AI_Agent) public aiAgents; // agentId => AI_Agent struct

    // Training Data Submissions
    Counters.Counter private _dataSubmissionIds;
    struct TrainingDataSubmission {
        address contributor;
        string dataURI; // IPFS hash to the dataset
        uint256 stakeAmount;
        bool isApproved; // True if curated and approved
        bool isProcessed; // True if rewarded/penalized
        uint256 submissionBlock;
    }
    mapping(uint256 => TrainingDataSubmission) public dataSubmissions; // submissionId => TrainingDataSubmission

    // Content Generation Requests
    Counters.Counter private _generationRequestIds;
    struct GenerationRequest {
        uint256 agentId;
        address requester;
        string promptHash; // Hash of the user's prompt (for privacy/verification)
        uint256 feePaid;
        uint256 requestBlock;
        string contentURI; // IPFS hash of the generated content, set post-generation
        bool contentSubmitted;
        int256 totalFeedbackScore; // Sum of feedback scores for this content
        uint256 feedbackCount; // Number of feedbacks received
        uint256 contentNFTId; // Link to the minted NFT if applicable
    }
    mapping(uint256 => GenerationRequest) public generationRequests;

    // Generated Content NFTs (Internal ERC721-like management - "NeuralCanvas Generated Content" token type)
    Counters.Counter private _contentNFTIds;
    mapping(uint256 => address) public contentNFTOwners; // contentNFTId => owner
    mapping(uint256 => string) private _contentTokenURIs; // contentNFTId => URI
    struct GeneratedContentNFT {
        uint256 generationRequestId;
        address originalRequester; // Original requestor of content, might not be current NFT owner
        address agentOwnerAtMint; // Agent owner at the time of NFT minting
        address[] dataContributorsAtMint; // List of data contributors whose data was used (conceptual, simplified for now)
        uint256 mintTimestamp;
        // uint256 currentPrice; // Price for immediate sale (if listed) - not directly in contract for sale
        address lastSeller; // To track royalties
        address lastBuyer; // To track royalties
    }
    mapping(uint256 => GeneratedContentNFT) public generatedContentNFTs;


    // Agent Evolution Proposals
    Counters.Counter private _evolutionProposalIds;
    struct AgentEvolutionProposal {
        uint256 agentId;
        string newModelURI;
        string proposalURI; // Link to detailed proposal description
        uint256 totalVotes;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted;
        bool executed;
        uint256 creationBlock;
    }
    mapping(uint256 => AgentEvolutionProposal) public agentEvolutionProposals;

    // General Governance Proposals (for contract parameters)
    Counters.Counter private _governanceProposalIds;
    struct GovernanceProposal {
        bytes32 parameterKey; // Key representing the parameter to change (e.g., keccak256("protocolFeeBasisPoints"))
        uint256 newValue;
        string proposalURI; // Link to detailed proposal description
        uint256 totalVotes;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted;
        bool executed;
        uint256 creationBlock;
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // Protocol Parameters & Fees
    address public immutable protocolTreasury;
    uint256 public protocolFeeBasisPoints; // e.g., 500 for 5% (out of 10000)
    uint256 public agentRoyaltyBasisPoints;
    uint256 public dataContributorRoyaltyBasisPoints; // Implicitly goes to agent owner as proxy for now
    uint256 public minTrainingDataStake;
    uint256 public minFeedbackStake; // Minimum stake required to provide feedback to prevent spam

    // --- Events ---
    event AI_AgentRegistered(uint256 indexed agentId, address indexed owner, string metadataURI);
    event AgentMetadataUpdated(uint256 indexed agentId, string newMetadataURI);
    event AgentGenerationFeeSet(uint256 indexed agentId, uint256 fee);
    event TrainingDataSubmitted(uint256 indexed submissionId, address indexed contributor, string dataURI, uint256 stakeAmount);
    event TrainingDataCurated(uint256 indexed submissionId, bool isApproved);
    event DataContributorRewarded(uint256 indexed submissionId, address indexed contributor, uint256 rewardAmount);
    event DataContributorPenalized(uint256 indexed submissionId, address indexed contributor, uint256 penaltyAmount);
    event ContentGenerationRequested(uint256 indexed requestId, uint256 indexed agentId, address indexed requester, uint256 feePaid);
    event GeneratedContentSubmitted(uint256 indexed requestId, uint256 indexed agentId, string contentURI);
    event ContentFeedbackSubmitted(uint256 indexed requestId, address indexed referrer, int8 score);
    event GeneratedContentNFTMinted(uint256 indexed contentNFTId, uint256 indexed requestId, address indexed minter, string nftMetadataURI);
    event GeneratedContentNFTSold(uint256 indexed contentNFTId, address indexed seller, address indexed buyer, uint256 price);
    event AgentEvolutionProposed(uint256 indexed proposalId, uint256 indexed agentId, string newModelURI);
    event AgentEvolutionFinalized(uint256 indexed proposalId, uint256 indexed agentId, string newModelURI);
    event GovernanceProposalCreated(uint252 indexed proposalId, bytes32 indexed parameterKey, uint256 newValue, string proposalURI);
    event GovernanceProposalVoted(uint252 indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint252 indexed proposalId, bytes32 indexed parameterKey, uint256 oldValue, uint256 newValue);
    event RoyaltySplitPercentagesSet(uint256 protocolShare, uint256 agentShare, uint256 dataContributorShare);
    event MinFeedbackStakeSet(uint256 newStake);

    constructor(
        address _protocolTreasury,
        uint256 _initialProtocolFeeBP,
        uint256 _initialAgentRoyaltyBP,
        uint256 _initialDataContributorRoyaltyBP,
        uint256 _minTrainingDataStake,
        uint256 _minFeedbackStake
    ) ERC721("NeuralCanvas AI Agent", "NCAA") Ownable(msg.sender) {
        require(_protocolTreasury != address(0), "Invalid treasury address");
        protocolTreasury = _protocolTreasury;
        protocolFeeBasisPoints = _initialProtocolFeeBP;
        agentRoyaltyBasisPoints = _initialAgentRoyaltyBP;
        dataContributorRoyaltyBasisPoints = _initialDataContributorRoyaltyBP;
        minTrainingDataStake = _minTrainingDataStake;
        minFeedbackStake = _minFeedbackStake;

        // Ensure royalty splits don't exceed 100% (10000 basis points)
        require(_initialProtocolFeeBP.add(_initialAgentRoyaltyBP).add(_initialDataContributorRoyaltyBP) <= 10000, "Royalty splits exceed 100%");
    }

    // --- I. Core Infrastructure & Ownership (AI Agent NFT Management) ---

    // 1. constructor: (Implemented above)

    // 2. registerAI_Agent: Mints a new AI Agent NFT.
    function registerAI_Agent(string memory _agentMetadataURI) external whenNotPaused returns (uint256) {
        _agentTokenIds.increment();
        uint256 newAgentId = _agentTokenIds.current();

        _safeMint(msg.sender, newAgentId); // Mints the ERC721 AI Agent NFT
        _setTokenURI(newAgentId, _agentMetadataURI); // Sets URI for the AI Agent NFT

        aiAgents[newAgentId] = AI_Agent({
            owner: msg.sender,
            metadataURI: _agentMetadataURI,
            generationFee: 0, // Agent owner must set this
            reputation: 0,
            lastEvolutionBlock: block.number
        });

        emit AI_AgentRegistered(newAgentId, msg.sender, _agentMetadataURI);
        return newAgentId;
    }

    // 3. updateAgentMetadata: Allows the agent owner to update the IPFS hash for their agent's model/parameters.
    function updateAgentMetadata(uint256 _agentId, string memory _newMetadataURI) external whenNotPaused {
        require(ownerOf(_agentId) == msg.sender, "Caller is not agent owner"); // Uses ERC721 ownerOf
        aiAgents[_agentId].metadataURI = _newMetadataURI;
        _setTokenURI(_agentId, _newMetadataURI); // Update ERC721 URI as well
        emit AgentMetadataUpdated(_agentId, _newMetadataURI);
    }

    // 4. setAgentGenerationFee: Sets the fee required to request content generation from a specific AI Agent.
    function setAgentGenerationFee(uint256 _agentId, uint256 _fee) external whenNotPaused {
        require(ownerOf(_agentId) == msg.sender, "Caller is not agent owner"); // Uses ERC721 ownerOf
        aiAgents[_agentId].generationFee = _fee;
        emit AgentGenerationFeeSet(_agentId, _fee);
    }

    // 5. withdrawProtocolFunds: Allows the owner (acting as DAO) to withdraw accumulated fees from the protocol treasury.
    function withdrawProtocolFunds(address _to, uint256 _amount) external onlyOwner whenNotPaused {
        require(address(this).balance >= _amount, "Insufficient balance");
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Failed to withdraw funds");
    }

    // 6. pauseContract(): Pauses core contract functionality in emergencies.
    function pauseContract() external onlyOwner {
        _pause();
    }

    // 7. unpauseContract(): Unpauses the contract after an emergency.
    function unpauseContract() external onlyOwner {
        _unpause();
    }


    // --- II. AI Agent Management & Evolution ---

    // 8. submitTrainingData: Users submit a hash of training data (via IPFS URI), staking tokens.
    function submitTrainingData(string memory _dataURI) external payable whenNotPaused returns (uint256) {
        require(msg.value >= minTrainingDataStake, "Insufficient stake for data submission");

        _dataSubmissionIds.increment();
        uint256 submissionId = _dataSubmissionIds.current();

        dataSubmissions[submissionId] = TrainingDataSubmission({
            contributor: msg.sender,
            dataURI: _dataURI,
            stakeAmount: msg.value,
            isApproved: false,
            isProcessed: false,
            submissionBlock: block.number
        });

        emit TrainingDataSubmitted(submissionId, msg.sender, _dataURI, msg.value);
        return submissionId;
    }

    // 9. curateTrainingData: Owner (acting as DAO) approves/rejects submitted training data.
    function curateTrainingData(uint256 _submissionId, bool _isApproved) external onlyOwner whenNotPaused {
        TrainingDataSubmission storage submission = dataSubmissions[_submissionId];
        require(submission.contributor != address(0), "Submission does not exist");
        require(!submission.isProcessed, "Submission already processed");

        submission.isApproved = _isApproved;
        submission.isProcessed = true;

        if (_isApproved) {
            uint256 rewardAmount = submission.stakeAmount.add(submission.stakeAmount.div(4)); // 25% bonus example
            (bool success, ) = payable(submission.contributor).call{value: rewardAmount}("");
            require(success, "Failed to reward contributor");
            emit DataContributorRewarded(_submissionId, submission.contributor, rewardAmount);
        } else {
            // Penalize: send stake to treasury (or burn).
            (bool success, ) = payable(protocolTreasury).call{value: submission.stakeAmount}("");
            require(success, "Failed to send penalty to treasury");
            emit DataContributorPenalized(_submissionId, submission.contributor, submission.stakeAmount);
        }
        emit TrainingDataCurated(_submissionId, _isApproved);
    }

    // 10. penalizeDataContributor: Allows the DAO to explicitly penalize.
    function penalizeDataContributor(uint256 _submissionId, uint256 _penaltyAmount) external onlyOwner whenNotPaused {
        TrainingDataSubmission storage submission = dataSubmissions[_submissionId];
        require(submission.contributor != address(0), "Submission does not exist");
        require(submission.isProcessed, "Submission not yet processed for curation");
        require(_penaltyAmount <= submission.stakeAmount, "Penalty exceeds original stake");

        if (submission.stakeAmount > 0) {
            uint256 effectivePenalty = _penaltyAmount;
            if (effectivePenalty > submission.stakeAmount) effectivePenalty = submission.stakeAmount;

            (bool success, ) = payable(protocolTreasury).call{value: effectivePenalty}("");
            require(success, "Failed to send penalty to treasury");
            submission.stakeAmount = submission.stakeAmount.sub(effectivePenalty);
        }
        emit DataContributorPenalized(_submissionId, submission.contributor, _penaltyAmount);
    }

    // 11. requestAgentEvolution: Propose an evolution for an AI Agent.
    function requestAgentEvolution(uint256 _agentId, string memory _newModelURI, string memory _evolutionProposalURI) external whenNotPaused returns (uint256) {
        require(ownerOf(_agentId) == msg.sender, "Caller is not agent owner");

        _evolutionProposalIds.increment();
        uint252 proposalId = _evolutionProposalIds.current();

        agentEvolutionProposals[proposalId] = AgentEvolutionProposal({
            agentId: _agentId,
            newModelURI: _newModelURI,
            proposalURI: _evolutionProposalURI,
            totalVotes: 0,
            yesVotes: 0,
            noVotes: 0,
            hasVoted: new mapping(address => bool),
            executed: false,
            creationBlock: block.number
        });

        emit AgentEvolutionProposed(proposalId, _agentId, _newModelURI);
        return proposalId;
    }

    // 12. finalizeAgentEvolution: Executes an approved evolution proposal.
    function finalizeAgentEvolution(uint252 _evolutionProposalId) external onlyOwner whenNotPaused {
        AgentEvolutionProposal storage proposal = agentEvolutionProposals[_evolutionProposalId];
        require(proposal.agentId != 0, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.yesVotes > proposal.noVotes, "Evolution proposal not approved"); // Simplified approval

        aiAgents[proposal.agentId].metadataURI = proposal.newModelURI;
        _setTokenURI(proposal.agentId, proposal.newModelURI); // Update ERC721 URI for the agent
        aiAgents[proposal.agentId].lastEvolutionBlock = block.number;
        // Optionally reset or boost agent reputation here based on successful evolution

        proposal.executed = true;
        emit AgentEvolutionFinalized(_evolutionProposalId, proposal.agentId, proposal.newModelURI);
    }

    // 13. updateAgentReputationBoost: DAO can adjust an agent's reputation score.
    function updateAgentReputationBoost(uint256 _agentId, int256 _boostValue) external onlyOwner whenNotPaused {
        require(ownerOf(_agentId) != address(0), "Agent does not exist");
        if (_boostValue > 0) {
            aiAgents[_agentId].reputation = aiAgents[_agentId].reputation.add(uint256(_boostValue));
        } else {
            uint256 absBoost = uint256(-_boostValue);
            aiAgents[_agentId].reputation = aiAgents[_agentId].reputation > absBoost ? aiAgents[_agentId].reputation.sub(absBoost) : 0;
        }
        // No specific event for reputation change for brevity, can be added if needed.
    }


    // --- III. Content Generation & Curation (Generated Content NFT Management) ---

    // 14. requestContentGeneration: User requests content from an AI Agent, paying a fee.
    function requestContentGeneration(uint256 _agentId, string memory _promptHash) external payable whenNotPaused returns (uint256) {
        require(ownerOf(_agentId) != address(0), "Agent does not exist");
        require(aiAgents[_agentId].generationFee > 0, "Agent generation fee not set");
        require(msg.value >= aiAgents[_agentId].generationFee, "Insufficient payment for generation request");

        uint256 fee = aiAgents[_agentId].generationFee;
        (bool success, ) = payable(ownerOf(_agentId)).call{value: fee}(""); // Transfer fee to agent owner
        require(success, "Failed to transfer fee to agent owner");

        _generationRequestIds.increment();
        uint256 requestId = _generationRequestIds.current();

        generationRequests[requestId] = GenerationRequest({
            agentId: _agentId,
            requester: msg.sender,
            promptHash: _promptHash,
            feePaid: fee,
            requestBlock: block.number,
            contentURI: "",
            contentSubmitted: false,
            totalFeedbackScore: 0,
            feedbackCount: 0,
            contentNFTId: 0
        });

        emit ContentGenerationRequested(requestId, _agentId, msg.sender, fee);
        return requestId;
    }

    // 15. submitGeneratedContent: Agent owner submits the hash of the generated content.
    function submitGeneratedContent(uint256 _generationRequestId, string memory _contentURI) external whenNotPaused {
        GenerationRequest storage request = generationRequests[_generationRequestId];
        require(request.agentId != 0, "Request does not exist");
        require(ownerOf(request.agentId) == msg.sender, "Caller is not the owner of the generating agent");
        require(!request.contentSubmitted, "Content already submitted for this request");

        request.contentURI = _contentURI;
        request.contentSubmitted = true;
        aiAgents[request.agentId].reputation = aiAgents[request.agentId].reputation.add(1); // Small boost for completion

        emit GeneratedContentSubmitted(_generationRequestId, request.agentId, _contentURI);
    }

    // 16. submitContentFeedback: Users provide feedback on generated content.
    function submitContentFeedback(uint256 _generationRequestId, int8 _score, string memory _category) external payable whenNotPaused {
        require(msg.value >= minFeedbackStake, "Insufficient stake for feedback");
        GenerationRequest storage request = generationRequests[_generationRequestId];
        require(request.agentId != 0, "Request does not exist");
        require(request.contentSubmitted, "Content not yet submitted for this request");
        require(_score >= -5 && _score <= 5, "Feedback score must be between -5 and 5");

        (bool success, ) = payable(protocolTreasury).call{value: msg.value}(""); // Send stake to treasury to deter spam
        require(success, "Failed to send feedback stake to treasury");

        request.totalFeedbackScore = request.totalFeedbackScore.add(_score);
        request.feedbackCount++;

        if (_score > 0) {
            aiAgents[request.agentId].reputation = aiAgents[request.agentId].reputation.add(uint256(_score));
        } else if (_score < 0) {
            uint256 absScore = uint256(-_score);
            aiAgents[request.agentId].reputation = aiAgents[request.agentId].reputation > absScore ? aiAgents[request.agentId].reputation.sub(absScore) : 0;
        }

        emit ContentFeedbackSubmitted(_generationRequestId, msg.sender, _score);
    }

    // 17. mintGeneratedContentNFT: Mints a new NFT for selected generated content.
    function mintGeneratedContentNFT(uint256 _generationRequestId, string memory _nftMetadataURI) external whenNotPaused returns (uint256) {
        GenerationRequest storage request = generationRequests[_generationRequestId];
        require(request.agentId != 0, "Request does not exist");
        require(request.contentSubmitted, "Content not yet submitted");
        require(request.contentNFTId == 0, "NFT already minted for this content");
        require(request.requester == msg.sender || ownerOf(request.agentId) == msg.sender, "Caller is neither requester nor agent owner");

        _contentNFTIds.increment();
        uint256 newContentNFTId = _contentNFTIds.current();

        contentNFTOwners[newContentNFTId] = msg.sender;
        _contentTokenURIs[newContentNFTId] = _nftMetadataURI;

        generatedContentNFTs[newContentNFTId] = GeneratedContentNFT({
            generationRequestId: _generationRequestId,
            originalRequester: request.requester,
            agentOwnerAtMint: ownerOf(request.agentId),
            dataContributorsAtMint: new address[](0), // Placeholder: complex tracking needed for real system
            mintTimestamp: block.timestamp,
            lastSeller: address(0),
            lastBuyer: address(0)
        });
        request.contentNFTId = newContentNFTId;

        emit GeneratedContentNFTMinted(newContentNFTId, _generationRequestId, msg.sender, _nftMetadataURI);
        return newContentNFTId;
    }

    // 18. getContentNFTOwner: Returns the current owner of a specific Generated Content NFT.
    function getContentNFTOwner(uint256 _contentNFTId) external view returns (address) {
        return contentNFTOwners[_contentNFTId];
    }

    // 19. getContentNFTURI: Returns the URI for a specific Generated Content NFT.
    function getContentNFTURI(uint252 _contentNFTId) external view returns (string memory) {
        return _contentTokenURIs[_contentNFTId];
    }

    // 20. transferContentNFT: Facilitates direct transfer of a Generated Content NFT (simplified).
    function transferContentNFT(address _from, address _to, uint256 _contentNFTId) external whenNotPaused {
        require(contentNFTOwners[_contentNFTId] == _from, "NFT not owned by from address");
        require(msg.sender == _from || msg.sender == owner(), "Only NFT owner or contract owner can initiate direct transfer");
        contentNFTOwners[_contentNFTId] = _to;
        generatedContentNFTs[_contentNFTId].lastSeller = _from;
        generatedContentNFTs[_contentNFTId].lastBuyer = _to;
    }

    // 21. buyGeneratedContentNFT: Allows buying minted content NFTs.
    function buyGeneratedContentNFT(uint256 _contentNFTId, uint256 _price) external payable whenNotPaused {
        GeneratedContentNFT storage contentNFT = generatedContentNFTs[_contentNFTId];
        require(contentNFT.generationRequestId != 0, "Content NFT does not exist");
        require(contentNFTOwners[_contentNFTId] != address(0), "Content NFT not minted or invalid");
        require(contentNFTOwners[_contentNFTId] != msg.sender, "Cannot buy your own NFT");
        require(msg.value == _price, "Incorrect payment amount");

        address currentSeller = contentNFTOwners[_contentNFTId];
        require(currentSeller != address(0), "Current owner invalid");

        uint256 totalAmount = msg.value;
        uint256 protocolShare = totalAmount.mul(protocolFeeBasisPoints).div(10000);
        uint256 agentShare = totalAmount.mul(agentRoyaltyBasisPoints).div(10000);
        uint256 dataContributorShare = totalAmount.mul(dataContributorRoyaltyBasisPoints).div(10000); // Sent to agent owner as proxy

        uint256 sellerProceeds = totalAmount.sub(protocolShare).sub(agentShare).sub(dataContributorShare);

        (bool successProto, ) = payable(protocolTreasury).call{value: protocolShare}("");
        require(successProto, "Failed to send protocol share");

        // Data contributor share is currently routed to the agent owner at mint time.
        (bool successAgent, ) = payable(contentNFT.agentOwnerAtMint).call{value: agentShare.add(dataContributorShare)}("");
        require(successAgent, "Failed to send agent and data contributor share");

        (bool successSeller, ) = payable(currentSeller).call{value: sellerProceeds}("");
        require(successSeller, "Failed to send seller proceeds");

        contentNFTOwners[_contentNFTId] = msg.sender;
        contentNFT.lastSeller = currentSeller;
        contentNFT.lastBuyer = msg.sender;

        emit GeneratedContentNFTSold(_contentNFTId, currentSeller, msg.sender, _price);
    }

    // 22. setRoyaltySplitPercentages: DAO sets the royalty distribution percentages.
    function setRoyaltySplitPercentages(uint256 _protocolShare, uint256 _agentShare, uint256 _dataContributorShare) external onlyOwner whenNotPaused {
        require(_protocolShare.add(_agentShare).add(_dataContributorShare) <= 10000, "Royalty splits exceed 100%");
        protocolFeeBasisPoints = _protocolShare;
        agentRoyaltyBasisPoints = _agentShare;
        dataContributorRoyaltyBasisPoints = _dataContributorShare;
        emit RoyaltySplitPercentagesSet(_protocolShare, _agentShare, _dataContributorShare);
    }

    // 23. getAgentReputation: Retrieves an agent's current calculated reputation score.
    function getAgentReputation(uint256 _agentId) external view returns (uint256) {
        require(ownerOf(_agentId) != address(0), "Agent does not exist");
        return aiAgents[_agentId].reputation;
    }

    // 24. getAgentGenerationHistory: Retrieves a paginated list of a specific agent's generation requests.
    // NOTE: This implementation is inefficient for a very large number of requests.
    // A production system would store agent-specific request IDs in a separate mapping for efficient lookup.
    function getAgentGenerationHistory(uint256 _agentId, uint256 _offset, uint256 _limit) external view returns (uint256[] memory, string[] memory) {
        require(ownerOf(_agentId) != address(0), "Agent does not exist");

        uint256[] memory tempRequestIds = new uint256[](_generationRequestIds.current());
        string[] memory tempContentURIs = new string[](_generationRequestIds.current());
        uint256 count = 0;

        for (uint256 i = 1; i <= _generationRequestIds.current(); i++) {
            if (generationRequests[i].agentId == _agentId) {
                tempRequestIds[count] = i;
                tempContentURIs[count] = generationRequests[i].contentURI;
                count++;
            }
        }

        uint256 start = _offset;
        uint256 end = _offset.add(_limit);
        if (end > count) end = count;
        if (start > count) start = count;

        uint256 actualReturnSize = end.sub(start);
        uint256[] memory resultIds = new uint256[](actualReturnSize);
        string[] memory resultURIs = new string[](actualReturnSize);

        for (uint256 i = 0; i < actualReturnSize; i++) {
            resultIds[i] = tempRequestIds[start.add(i)];
            resultURIs[i] = tempContentURIs[start.add(i)];
        }
        return (resultIds, resultURIs);
    }


    // --- IV. Governance & Parameter Tuning ---

    // 25. proposeParameterChange: Allows DAO members (owner for now) to propose changes.
    function proposeParameterChange(bytes32 _parameterKey, uint256 _newValue, string memory _proposalURI) external onlyOwner whenNotPaused returns (uint256) {
        _governanceProposalIds.increment();
        uint252 proposalId = _governanceProposalIds.current();

        governanceProposals[proposalId] = GovernanceProposal({
            parameterKey: _parameterKey,
            newValue: _newValue,
            proposalURI: _proposalURI,
            totalVotes: 0,
            yesVotes: 0,
            noVotes: 0,
            hasVoted: new mapping(address => bool),
            executed: false,
            creationBlock: block.number
        });

        emit GovernanceProposalCreated(proposalId, _parameterKey, _newValue, _proposalURI);
        return proposalId;
    }

    // 26. voteOnProposal: Users vote on active Agent Evolution or Governance proposals.
    // This is a simplified voting mechanism (1 address = 1 vote). For DAO, token-weighted voting would be used.
    function voteOnProposal(uint252 _proposalId, bool _support) external whenNotPaused {
        // Check if it's an Agent Evolution Proposal
        if (agentEvolutionProposals[_proposalId].agentId != 0) {
            AgentEvolutionProposal storage proposal = agentEvolutionProposals[_proposalId];
            require(!proposal.executed, "Agent evolution proposal already executed");
            require(!proposal.hasVoted[msg.sender], "Already voted on this agent evolution proposal");

            proposal.hasVoted[msg.sender] = true;
            proposal.totalVotes++;
            if (_support) {
                proposal.yesVotes++;
            } else {
                proposal.noVotes++;
            }
            emit GovernanceProposalVoted(_proposalId, msg.sender, _support);
            return;
        }

        // Check if it's a General Governance Proposal
        if (governanceProposals[_proposalId].parameterKey != bytes32(0)) {
            GovernanceProposal storage proposal = governanceProposals[_proposalId];
            require(!proposal.executed, "Governance proposal already executed");
            require(!proposal.hasVoted[msg.sender], "Already voted on this governance proposal");

            proposal.hasVoted[msg.sender] = true;
            proposal.totalVotes++;
            if (_support) {
                proposal.yesVotes++;
            } else {
                proposal.noVotes++;
            }
            emit GovernanceProposalVoted(_proposalId, msg.sender, _support);
            return;
        }

        revert("Proposal does not exist");
    }

    // 27. executeProposal: Executes approved governance proposals.
    function executeProposal(uint252 _proposalId) external onlyOwner whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.parameterKey != bytes32(0), "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.yesVotes > proposal.noVotes, "Governance proposal not approved"); // Simplified approval

        uint256 oldValue;
        if (proposal.parameterKey == keccak256("protocolFeeBasisPoints")) {
            oldValue = protocolFeeBasisPoints;
            protocolFeeBasisPoints = proposal.newValue;
        } else if (proposal.parameterKey == keccak256("agentRoyaltyBasisPoints")) {
            oldValue = agentRoyaltyBasisPoints;
            agentRoyaltyBasisPoints = proposal.newValue;
        } else if (proposal.parameterKey == keccak256("dataContributorRoyaltyBasisPoints")) {
            oldValue = dataContributorRoyaltyBasisPoints;
            dataContributorRoyaltyBasisPoints = proposal.newValue;
        } else if (proposal.parameterKey == keccak256("minTrainingDataStake")) {
            oldValue = minTrainingDataStake;
            minTrainingDataStake = proposal.newValue;
        } else if (proposal.parameterKey == keccak256("minFeedbackStake")) {
            oldValue = minFeedbackStake;
            minFeedbackStake = proposal.newValue;
        } else {
            revert("Unknown parameter key for governance");
        }

        // Re-check royalty sum to prevent invalid configurations
        require(protocolFeeBasisPoints.add(agentRoyaltyBasisPoints).add(dataContributorRoyaltyBasisPoints) <= 10000, "Royalty splits exceed 100% after execution");

        proposal.executed = true;
        emit GovernanceProposalExecuted(_proposalId, proposal.parameterKey, oldValue, proposal.newValue);
    }

    // 28. setMinimumFeedbackStake: DAO can set minimum stake required for giving feedback.
    function setMinimumFeedbackStake(uint256 _newStake) external onlyOwner whenNotPaused {
        minFeedbackStake = _newStake;
        emit MinFeedbackStakeSet(_newStake);
    }

    // --- Utility/Helper Functions ---

    // For ERC721 compatibility for the AI Agents
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```