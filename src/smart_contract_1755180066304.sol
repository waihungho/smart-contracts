Here is a Solidity smart contract named "NexusLore" that implements several advanced, creative, and trendy concepts without directly duplicating existing open-source projects in its specific combination and business logic.

It features:
1.  **Dynamic Soulbound Tokens (SBTs):** For reputation, where the token's metadata URI dynamically updates based on a user's on-chain contributions and achievements.
2.  **AI-Assisted Content Scoring (via Oracle):** Integrates an off-chain AI model for quality assessment, plagiarism checks, or relevance scoring of submitted projects, with scores delivered via an oracle.
3.  **Multi-Dimensional Reputation System:** Different roles (Contributor, Reviewer, Curator) accumulate distinct reputation scores influencing their privileges and SBT metadata.
4.  **Decentralized Knowledge NFTs:** Successful and validated projects are minted as unique, verifiable Knowledge NFTs.
5.  **Milestone-based Funding & Rewards:** Facilitates funding for research streams and projects, with contributors and reviewers earning rewards upon validation.
6.  **On-chain Dispute Resolution:** A mechanism for disputing project outcomes, involving a voting process.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title IKnowledgeNFTs
 * @dev Interface for the external Knowledge NFT contract.
 */
interface IKnowledgeNFTs {
    function mint(address to, uint256 tokenId, string calldata uri) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function updateTokenURI(uint256 tokenId, string calldata newUri) external;
}

/**
 * @title IReputationSBTs
 * @dev Interface for the external Reputation Soulbound Token (SBT) contract.
 *      These SBTs represent a user's on-chain reputation and roles.
 */
interface IReputationSBTs {
    function mint(address to, uint256 tokenId, string calldata uri) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function updateTokenURI(uint256 tokenId, string calldata newUri) external;
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

/**
 * @title INexusLoreOracle
 * @dev Interface for the external AI Oracle contract responsible for content scoring.
 */
interface INexusLoreOracle {
    // requestAIScore triggers an off-chain AI process, returning a unique requestId.
    function requestAIScore(uint256 projectId, string memory contentHash) external returns (bytes32 requestId);
    // getAIScore retrieves the fulfilled score for a given request.
    function getAIScore(bytes32 requestId) external view returns (uint256 score);
    // Callback function the oracle calls to deliver the score on-chain.
    function fulfillAIScore(bytes32 requestId, uint256 score) external;
}

/**
 * @title NexusLore: Decentralized Knowledge & Innovation Nexus
 * @dev This contract facilitates a decentralized network for collaborative knowledge creation,
 *      peer review, and dynamic reputation building. It incorporates advanced concepts
 *      like dynamic Soulbound Tokens (SBTs) for reputation, AI-assisted content scoring
 *      via oracles, and milestone-based funding for projects.
 *
 * Outline:
 * 1.  Core Infrastructure & Global Settings
 * 2.  Stream (Topic) Management
 * 3.  Project Submission & Lifecycle
 * 4.  Reputation & Soulbound Tokens (SBTs) Management
 * 5.  Funding & Rewards
 * 6.  Dispute Resolution
 * 7.  Oracle & External Integration Callbacks
 *
 * Function Summary:
 * - constructor(): Initializes the contract with addresses for external NFT/SBT and Oracle contracts.
 * - setOracleAddress(): Sets the address of the AI oracle.
 * - setKnowledgeNFTsAddress(): Sets the address of the Knowledge NFT contract.
 * - setReputationSBTsAddress(): Sets the address of the Reputation SBT contract.
 * - setProtocolFeePercentage(): Sets the percentage of rewards taken as protocol fee.
 * - proposeStream(): Allows any user to propose a new research stream or topic.
 * - approveStream(): An admin (Owner) approves a proposed stream, making it active.
 * - setStreamCurator(): Assigns a Stream Shaper (curator) to an active stream.
 * - updateStreamMetadata(): Allows a stream's curator to update its description or other metadata.
 * - submitProject(): Users submit a project (e.g., research, dataset) to an active stream.
 * - requestAIScore(): Initiates an off-chain AI evaluation request for a submitted project.
 * - receiveAIScore(): Callback function used by the oracle to deliver the AI score on-chain.
 * - assignReviewers(): A stream's curator assigns Veritas Validators (reviewers) to a project.
 * - submitReview(): Assigned reviewers submit their evaluation for a project.
 * - finalizeProjectReview(): The stream curator finalizes the project's review process, determining its success.
 * - mintKnowledgeNFT(): Mints a unique Knowledge NFT for successfully finalized projects.
 * - updateLoreWeaverReputation(): Internal: Adjusts a contributor's reputation score.
 * - updateVeritasValidatorReputation(): Internal: Adjusts a reviewer's reputation score.
 * - updateStreamShaperReputation(): Internal: Adjusts a curator's reputation score.
 * - updateReputationSBTMetadata(): Internal: Updates the URI of a user's Reputation SBT reflecting their new scores.
 * - getReputationScore(): Retrieves a user's combined reputation score.
 * - getSBTTokenId(): Retrieves the Soulbound Token ID associated with a user's address.
 * - getProjectStatus(): Retrieves the current status of a project.
 * - depositFunds(): Allows users to deposit funds (e.g., Ether, DAI) as bounties for projects or streams.
 * - claimProjectReward(): Allows contributors of a successful project to claim their share of deposited funds.
 * - claimReviewReward(): Allows reviewers of a project to claim rewards for their validated reviews.
 * - withdrawProtocolFunds(): Allows the contract owner to withdraw accumulated protocol fees.
 * - initiateDispute(): Allows a project submitter or reviewer to dispute a project's finalization or a review.
 * - submitDisputeVote(): Allows designated dispute arbiters (e.g., Owner/Admins) to vote on an active dispute.
 * - resolveDispute(): Resolves a dispute based on the majority vote, potentially altering project status or reputation.
 * - pause(): Pauses contract functionality in emergencies (admin only).
 * - unpause(): Unpauses contract functionality (admin only).
 */
contract NexusLore is Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // External Contract Interfaces
    IKnowledgeNFTs public knowledgeNFTs;
    IReputationSBTs public reputationSBTs;
    INexusLoreOracle public nexusLoreOracle;

    // --- Configuration & Fees ---
    uint256 public protocolFeePercentage; // e.g., 500 for 5% (500 / 10000)

    // --- Counters ---
    Counters.Counter private _nextStreamId;
    Counters.Counter private _nextProjectId;
    Counters.Counter private _nextKnowledgeNFTId;
    Counters.Counter private _nextDisputeId;

    // --- Structs ---

    enum StreamStatus { Proposed, Active, Inactive }
    struct Stream {
        uint256 id;
        string name;
        string metadataURI; // IPFS hash for detailed description, rules, etc.
        address curator; // address of the StreamShaper
        StreamStatus status;
        uint256 depositedFunds;
        uint256 proposedBlock; // Block number when stream was proposed
    }

    enum ProjectStatus { Pending, AwaitingAIScore, AwaitingReview, InReview, Reviewed, FinalizedSuccess, FinalizedFailure, Disputed }
    struct Project {
        uint256 id;
        uint224 streamId; // Using uint224 to save space
        address contributor; // LoreWeaver
        string metadataURI; // IPFS hash for project details, content hash etc.
        uint256 depositedFunds;
        ProjectStatus status;
        uint256 aiScore; // AI's assessment score (0-100)
        bytes32 oracleRequestId; // ID for the oracle request
        uint256 aiScoreReceivedBlock; // Block when AI score was received
        uint256 creationBlock;
    }

    struct Review {
        uint256 projectId;
        address reviewer; // VeritasValidator
        string reviewURI; // IPFS hash for review content
        uint256 score; // Reviewer's score for the project (0-100)
        bool finalized; // True if review has been accepted/counted
    }

    // Reputation Scores (separate for different roles)
    // LoreWeaver: Contributor reputation
    mapping(address => uint256) public loreWeaverReputation;
    // VeritasValidator: Reviewer reputation
    mapping(address => uint256) public veritasValidatorReputation;
    // StreamShaper: Curator reputation
    mapping(address => uint256) public streamShaperReputation;

    // Mapping for user's SBT Token ID (assuming 1 SBT per user for their profile)
    mapping(address => uint256) public userSBTTokenId;

    enum DisputeStatus { Open, Voting, ResolvedSuccess, ResolvedFailure }
    struct Dispute {
        uint256 id;
        uint256 subjectId; // Could be projectId or reviewId
        address initiator;
        string reason;
        DisputeStatus status;
        mapping(address => bool) voted;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 resolutionBlock; // Block when dispute was resolved
    }

    // --- Mappings ---
    mapping(uint256 => Stream) public streams;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => Review[]) public projectReviews; // projectId => array of reviews
    mapping(uint256 => mapping(address => bool)) public projectReviewers; // projectId => reviewer address => is assigned
    mapping(uint256 => mapping(address => bool)) public projectReviewSubmitted; // projectId => reviewer address => has submitted review
    mapping(address => uint256) public pendingRewards; // accumulated rewards for users

    mapping(uint256 => Dispute) public disputes;
    mapping(bytes32 => uint256) public oracleRequestIdToProjectId; // For oracle callbacks

    // --- Events ---
    event OracleAddressSet(address indexed newAddress);
    event KnowledgeNFTsAddressSet(address indexed newAddress);
    event ReputationSBTsAddressSet(address indexed newAddress);
    event ProtocolFeePercentageSet(uint256 newPercentage);

    event StreamProposed(uint256 indexed streamId, string name, address indexed proposer);
    event StreamApproved(uint256 indexed streamId);
    event StreamCuratorSet(uint256 indexed streamId, address indexed newCurator);
    event StreamMetadataUpdated(uint256 indexed streamId, string newURI);

    event ProjectSubmitted(uint256 indexed projectId, uint256 indexed streamId, address indexed contributor);
    event AIScoreRequested(uint256 indexed projectId, bytes32 indexed requestId, string contentHash);
    event AIScoreReceived(uint256 indexed projectId, bytes32 indexed requestId, uint256 score);
    event ReviewersAssigned(uint256 indexed projectId, address[] reviewers);
    event ReviewSubmitted(uint256 indexed projectId, address indexed reviewer, uint256 score);
    event ProjectFinalized(uint256 indexed projectId, ProjectStatus status, uint256 finalAIScore, uint256 reviewCount);
    event KnowledgeNFTMinted(uint256 indexed projectId, uint256 indexed tokenId, address recipient, string tokenURI);

    event ReputationUpdated(address indexed user, string role, uint256 newScore);
    event SBTMetadataUpdated(address indexed user, uint256 indexed tokenId, string newURI);

    event FundsDeposited(address indexed depositor, uint256 indexed subjectId, uint256 amount);
    event ProjectRewardClaimed(uint256 indexed projectId, address indexed claimant, uint256 amount);
    event ReviewRewardClaimed(uint256 indexed projectId, address indexed claimant, uint256 amount);
    event ProtocolFundsWithdrawn(address indexed owner, uint256 amount);

    event DisputeInitiated(uint256 indexed disputeId, uint256 indexed subjectId, address indexed initiator);
    event DisputeVoteCast(uint256 indexed disputeId, address indexed voter, bool voteFor);
    event DisputeResolved(uint256 indexed disputeId, DisputeStatus status);

    // --- Constructor ---
    constructor(address _knowledgeNFTsAddr, address _reputationSBTsAddr, address _oracleAddr) Ownable(msg.sender) {
        require(_knowledgeNFTsAddr != address(0), "Invalid KnowledgeNFTs address");
        require(_reputationSBTsAddr != address(0), "Invalid ReputationSBTs address");
        require(_oracleAddr != address(0), "Invalid Oracle address");

        knowledgeNFTs = IKnowledgeNFTs(_knowledgeNFTsAddr);
        reputationSBTs = IReputationSBTs(_reputationSBTsAddr);
        nexusLoreOracle = INexusLoreOracle(_oracleAddr);

        protocolFeePercentage = 500; // Default to 5% (500/10000)
    }

    // --- Core Infrastructure & Global Settings ---

    function setOracleAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Invalid address");
        nexusLoreOracle = INexusLoreOracle(_newAddress);
        emit OracleAddressSet(_newAddress);
    }

    function setKnowledgeNFTsAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Invalid address");
        knowledgeNFTs = IKnowledgeNFTs(_newAddress);
        emit KnowledgeNFTsAddressSet(_newAddress);
    }

    function setReputationSBTsAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Invalid address");
        reputationSBTs = IReputationSBTs(_newAddress);
        emit ReputationSBTsAddressSet(_newAddress);
    }

    function setProtocolFeePercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage <= 10000, "Percentage cannot exceed 100%"); // 10000 = 100%
        protocolFeePercentage = _newPercentage;
        emit ProtocolFeePercentageSet(_newPercentage);
    }

    // --- Stream (Topic) Management ---

    function proposeStream(string calldata _name, string calldata _metadataURI) external whenNotPaused {
        _nextStreamId.increment();
        uint256 newStreamId = _nextStreamId.current();
        streams[newStreamId] = Stream({
            id: newStreamId,
            name: _name,
            metadataURI: _metadataURI,
            curator: address(0), // No curator initially
            status: StreamStatus.Proposed,
            depositedFunds: 0,
            proposedBlock: block.number
        });
        emit StreamProposed(newStreamId, _name, msg.sender);
    }

    function approveStream(uint256 _streamId) external onlyOwner whenNotPaused {
        Stream storage stream = streams[_streamId];
        require(stream.id != 0, "Stream does not exist");
        require(stream.status == StreamStatus.Proposed, "Stream is not in proposed state");

        stream.status = StreamStatus.Active;
        emit StreamApproved(_streamId);
    }

    function setStreamCurator(uint256 _streamId, address _curator) external onlyOwner whenNotPaused {
        Stream storage stream = streams[_streamId];
        require(stream.id != 0, "Stream does not exist");
        require(stream.status == StreamStatus.Active, "Stream not active");
        require(_curator != address(0), "Invalid curator address");

        stream.curator = _curator;
        _ensureReputationSBT(msg.sender); // Ensure curator has an SBT
        _updateStreamShaperReputation(_curator, 10); // Initial reputation for setting curator
        emit StreamCuratorSet(_streamId, _curator);
    }

    function updateStreamMetadata(uint256 _streamId, string calldata _newMetadataURI) external whenNotPaused {
        Stream storage stream = streams[_streamId];
        require(stream.id != 0, "Stream does not exist");
        require(stream.status == StreamStatus.Active, "Stream not active");
        require(stream.curator == msg.sender, "Only stream curator can update metadata");

        stream.metadataURI = _newMetadataURI;
        emit StreamMetadataUpdated(_streamId, _newMetadataURI);
    }

    // --- Project Submission & Lifecycle ---

    function submitProject(uint256 _streamId, string calldata _metadataURI) external whenNotPaused {
        Stream storage stream = streams[_streamId];
        require(stream.id != 0, "Stream does not exist");
        require(stream.status == StreamStatus.Active, "Stream not active for submissions");

        _nextProjectId.increment();
        uint256 newProjectId = _nextProjectId.current();
        projects[newProjectId] = Project({
            id: newProjectId,
            streamId: uint224(_streamId),
            contributor: msg.sender,
            metadataURI: _metadataURI,
            depositedFunds: 0,
            status: ProjectStatus.Pending,
            aiScore: 0,
            oracleRequestId: bytes32(0),
            aiScoreReceivedBlock: 0,
            creationBlock: block.number
        });

        _ensureReputationSBT(msg.sender); // Ensure contributor has an SBT
        emit ProjectSubmitted(newProjectId, _streamId, msg.sender);
    }

    function requestAIScore(uint256 _projectId, string calldata _contentHash) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project does not exist");
        require(project.contributor == msg.sender || streams[project.streamId].curator == msg.sender, "Only contributor or curator can request AI score");
        require(project.status == ProjectStatus.Pending || project.status == ProjectStatus.AwaitingAIScore, "Project not in valid state for AI scoring");
        require(bytes(_contentHash).length > 0, "Content hash cannot be empty");
        require(address(nexusLoreOracle) != address(0), "Oracle address not set");

        bytes32 requestId = nexusLoreOracle.requestAIScore(_projectId, _contentHash);
        project.oracleRequestId = requestId;
        project.status = ProjectStatus.AwaitingAIScore;
        oracleRequestIdToProjectId[requestId] = _projectId;
        emit AIScoreRequested(_projectId, requestId, _contentHash);
    }

    // Callback from the Oracle to deliver the AI score
    function fulfillAIScore(bytes32 _requestId, uint256 _score) external nonReentrant {
        require(msg.sender == address(nexusLoreOracle), "Only Oracle can call this function");
        uint256 projectId = oracleRequestIdToProjectId[_requestId];
        require(projectId != 0, "Unknown request ID");

        Project storage project = projects[projectId];
        require(project.status == ProjectStatus.AwaitingAIScore, "Project not awaiting AI score");
        require(project.oracleRequestId == _requestId, "Request ID mismatch");

        project.aiScore = _score;
        project.aiScoreReceivedBlock = block.number;
        project.status = ProjectStatus.AwaitingReview; // Ready for peer review
        delete oracleRequestIdToProjectId[_requestId]; // Clean up mapping

        emit AIScoreReceived(projectId, _requestId, _score);
    }

    function assignReviewers(uint256 _projectId, address[] calldata _reviewers) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project does not exist");
        require(streams[project.streamId].curator == msg.sender, "Only stream curator can assign reviewers");
        require(project.status == ProjectStatus.AwaitingReview, "Project not awaiting reviewers");
        require(_reviewers.length > 0, "Must assign at least one reviewer");

        project.status = ProjectStatus.InReview;
        for (uint i = 0; i < _reviewers.length; i++) {
            require(_reviewers[i] != address(0), "Invalid reviewer address");
            require(!projectReviewers[_projectId][_reviewers[i]], "Reviewer already assigned");
            projectReviewers[_projectId][_reviewers[i]] = true;
            _ensureReputationSBT(_reviewers[i]); // Ensure reviewer has an SBT
        }
        emit ReviewersAssigned(_projectId, _reviewers);
    }

    function submitReview(uint256 _projectId, string calldata _reviewURI, uint256 _score) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project does not exist");
        require(project.status == ProjectStatus.InReview, "Project not in review phase");
        require(projectReviewers[_projectId][msg.sender], "You are not an assigned reviewer for this project");
        require(!projectReviewSubmitted[_projectId][msg.sender], "You have already submitted a review for this project");
        require(_score <= 100, "Review score cannot exceed 100");

        projectReviews[_projectId].push(Review({
            projectId: _projectId,
            reviewer: msg.sender,
            reviewURI: _reviewURI,
            score: _score,
            finalized: false
        }));
        projectReviewSubmitted[_projectId][msg.sender] = true;

        emit ReviewSubmitted(_projectId, msg.sender, _score);
    }

    function finalizeProjectReview(uint256 _projectId) external whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project does not exist");
        require(streams[project.streamId].curator == msg.sender, "Only stream curator can finalize project");
        require(project.status == ProjectStatus.InReview, "Project not in review state");

        Review[] storage reviews = projectReviews[_projectId];
        require(reviews.length > 0, "No reviews submitted yet");

        uint256 totalReviewScore = 0;
        uint256 acceptedReviewCount = 0;

        for (uint i = 0; i < reviews.length; i++) {
            if (!reviews[i].finalized) { // Only consider non-finalized reviews
                totalReviewScore += reviews[i].score;
                acceptedReviewCount++;
                reviews[i].finalized = true; // Mark as finalized
                _updateVeritasValidatorReputation(reviews[i].reviewer, 10); // Reward reviewer reputation
            }
        }

        require(acceptedReviewCount > 0, "No new reviews to finalize.");

        uint256 avgReviewScore = totalReviewScore / acceptedReviewCount;
        uint256 combinedScore = (project.aiScore + avgReviewScore) / 2; // Simple average of AI and human reviews

        if (combinedScore >= 70) { // Example threshold for success
            project.status = ProjectStatus.FinalizedSuccess;
            _updateLoreWeaverReputation(project.contributor, 20); // Reward contributor reputation
            _updateStreamShaperReputation(streams[project.streamId].curator, 5); // Reward curator for successful project
        } else {
            project.status = ProjectStatus.FinalizedFailure;
            // Optionally, penalize contributor reputation for failure.
        }

        emit ProjectFinalized(_projectId, project.status, combinedScore, acceptedReviewCount);
    }

    function mintKnowledgeNFT(uint256 _projectId) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project does not exist");
        require(project.status == ProjectStatus.FinalizedSuccess, "Project not successfully finalized");
        require(address(knowledgeNFTs) != address(0), "KnowledgeNFTs contract address not set");

        // Ensure only contributor or curator can mint
        require(msg.sender == project.contributor || msg.sender == streams[project.streamId].curator, "Only contributor or curator can mint Knowledge NFT");

        _nextKnowledgeNFTId.increment();
        uint256 newKnowledgeNFTId = _nextKnowledgeNFTId.current();
        
        knowledgeNFTs.mint(project.contributor, newKnowledgeNFTId, project.metadataURI);
        emit KnowledgeNFTMinted(_projectId, newKnowledgeNFTId, project.contributor, project.metadataURI);
    }

    // --- Reputation & Soulbound Tokens (SBTs) Management ---

    function _ensureReputationSBT(address _user) internal {
        if (userSBTTokenId[_user] == 0) {
            _nextKnowledgeNFTId.increment(); // Use same counter or separate for SBTs, this is just a dummy id.
            uint256 newSBTId = _nextKnowledgeNFTId.current(); // This is just a unique ID for the SBT
            userSBTTokenId[_user] = newSBTId;
            reputationSBTs.mint(_user, newSBTId, ""); // Mint with empty URI, will be updated.
            _updateReputationSBTMetadata(_user); // Update immediately after mint
        }
    }

    function _updateLoreWeaverReputation(address _user, uint256 _points) internal {
        loreWeaverReputation[_user] += _points;
        emit ReputationUpdated(_user, "LoreWeaver", loreWeaverReputation[_user]);
        _updateReputationSBTMetadata(_user);
    }

    function _updateVeritasValidatorReputation(address _user, uint256 _points) internal {
        veritasValidatorReputation[_user] += _points;
        emit ReputationUpdated(_user, "VeritasValidator", veritasValidatorReputation[_user]);
        _updateReputationSBTMetadata(_user);
    }

    function _updateStreamShaperReputation(address _user, uint256 _points) internal {
        streamShaperReputation[_user] += _points;
        emit ReputationUpdated(_user, "StreamShaper", streamShaperReputation[_user]);
        _updateReputationSBTMetadata(_user);
    }

    // Internal function to update the SBT metadata URI based on current reputation
    function _updateReputationSBTMetadata(address _user) internal {
        require(userSBTTokenId[_user] != 0, "User does not have an SBT minted yet.");

        uint256 totalRep = getReputationScore(_user);
        string memory uri = string(abi.encodePacked(
            "ipfs://{BASE_URI}/", // Placeholder for actual IPFS gateway/base path
            Strings.toString(totalRep),
            "_",
            Strings.toString(loreWeaverReputation[_user]),
            "_",
            Strings.toString(veritasValidatorReputation[_user]),
            "_",
            Strings.toString(streamShaperReputation[_user]),
            ".json" // File format, containing more details
        ));
        reputationSBTs.updateTokenURI(userSBTTokenId[_user], uri);
        emit SBTMetadataUpdated(_user, userSBTTokenId[_user], uri);
    }

    function getReputationScore(address _user) public view returns (uint256) {
        return loreWeaverReputation[_user] + veritasValidatorReputation[_user] + streamShaperReputation[_user];
    }

    function getSBTTokenId(address _user) public view returns (uint256) {
        return userSBTTokenId[_user];
    }

    function getProjectStatus(uint256 _projectId) public view returns (ProjectStatus) {
        return projects[_projectId].status;
    }

    // --- Funding & Rewards ---

    function depositFunds(uint256 _subjectId) external payable whenNotPaused nonReentrant {
        require(msg.value > 0, "Must send Ether");
        // SubjectId can be StreamId or ProjectId. For simplicity, assume project funding.
        // Can extend to specify type (0 for stream, 1 for project)
        Project storage project = projects[_subjectId];
        require(project.id != 0, "Subject (project) does not exist");
        project.depositedFunds += msg.value;
        emit FundsDeposited(msg.sender, _subjectId, msg.value);
    }

    function claimProjectReward(uint256 _projectId) external nonReentrant {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project does not exist");
        require(project.contributor == msg.sender, "Only project contributor can claim");
        require(project.status == ProjectStatus.FinalizedSuccess, "Project not successfully finalized");

        uint256 totalReward = project.depositedFunds;
        require(totalReward > 0, "No funds to claim");

        uint256 protocolFee = (totalReward * protocolFeePercentage) / 10000;
        uint256 contributorShare = totalReward - protocolFee;

        project.depositedFunds = 0; // Mark as claimed

        pendingRewards[msg.sender] += contributorShare; // Accumulate for later withdrawal
        pendingRewards[owner()] += protocolFee;

        emit ProjectRewardClaimed(_projectId, msg.sender, contributorShare);
    }

    function claimReviewReward(uint256 _projectId) external nonReentrant {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project does not exist");
        require(project.status == ProjectStatus.FinalizedSuccess, "Project not successfully finalized to claim review rewards");

        bool hasReviewed = false;
        for (uint i = 0; i < projectReviews[_projectId].length; i++) {
            if (projectReviews[_projectId][i].reviewer == msg.sender && projectReviews[_projectId][i].finalized) {
                hasReviewed = true;
                break;
            }
        }
        require(hasReviewed, "You have not submitted a finalized review for this project.");

        // Simple fixed reward per review for now, can be more complex (e.g., % of project funds)
        uint256 reviewRewardAmount = 0.001 ether; // Example: 0.001 ETH per valid review

        require(address(this).balance >= reviewRewardAmount, "Insufficient contract balance for review reward");

        uint256 protocolFee = (reviewRewardAmount * protocolFeePercentage) / 10000;
        uint256 reviewerShare = reviewRewardAmount - protocolFee;

        pendingRewards[msg.sender] += reviewerShare;
        pendingRewards[owner()] += protocolFee;

        emit ReviewRewardClaimed(_projectId, msg.sender, reviewerShare);
    }

    function withdrawPendingRewards() external nonReentrant {
        uint256 amount = pendingRewards[msg.sender];
        require(amount > 0, "No pending rewards to withdraw");

        pendingRewards[msg.sender] = 0;
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function withdrawProtocolFunds() external onlyOwner nonReentrant {
        uint256 amount = pendingRewards[owner()];
        require(amount > 0, "No protocol funds to withdraw");

        pendingRewards[owner()] = 0;
        (bool success,) = owner().call{value: amount}("");
        require(success, "Failed to send Ether");
        emit ProtocolFundsWithdrawn(owner(), amount);
    }

    // --- Dispute Resolution ---

    function initiateDispute(uint256 _subjectId, string calldata _reason) external whenNotPaused {
        Project storage project = projects[_subjectId];
        require(project.id != 0, "Subject (project) does not exist");
        require(project.status != ProjectStatus.Disputed, "Project already under dispute");
        require(project.contributor == msg.sender || projectReviewers[_subjectId][msg.sender], "Only contributor or reviewer can dispute");
        
        _nextDisputeId.increment();
        uint256 newDisputeId = _nextDisputeId.current();

        disputes[newDisputeId] = Dispute({
            id: newDisputeId,
            subjectId: _subjectId,
            initiator: msg.sender,
            reason: _reason,
            status: DisputeStatus.Open,
            votesFor: 0,
            votesAgainst: 0,
            resolutionBlock: 0
        });
        project.status = ProjectStatus.Disputed; // Temporarily mark as disputed

        emit DisputeInitiated(newDisputeId, _subjectId, msg.sender);
    }

    // For simplicity, only Owner can vote on disputes in this example.
    // In a real system, this would be a DAO or a set of arbiters.
    function submitDisputeVote(uint256 _disputeId, bool _voteFor) external onlyOwner whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "Dispute does not exist");
        require(dispute.status == DisputeStatus.Open || dispute.status == DisputeStatus.Voting, "Dispute not open for voting");
        require(!dispute.voted[msg.sender], "You have already voted on this dispute");

        dispute.status = DisputeStatus.Voting; // Ensure it transitions to voting
        if (_voteFor) {
            dispute.votesFor++;
        } else {
            dispute.votesAgainst++;
        }
        dispute.voted[msg.sender] = true;

        emit DisputeVoteCast(_disputeId, msg.sender, _voteFor);
    }

    function resolveDispute(uint256 _disputeId) external onlyOwner nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "Dispute does not exist");
        require(dispute.status == DisputeStatus.Voting, "Dispute not in voting state");

        // Simple majority rule
        if (dispute.votesFor > dispute.votesAgainst) {
            dispute.status = DisputeStatus.ResolvedSuccess;
            // Example: If dispute was about project failure, revert to AwaitingReview
            // Or if about unfair review, re-enable review for that person.
            Project storage project = projects[dispute.subjectId];
            if (project.status == ProjectStatus.Disputed) {
                project.status = ProjectStatus.AwaitingReview; // Reopen for review/re-evaluation
            }
        } else {
            dispute.status = DisputeStatus.ResolvedFailure;
            // Revert project status to its previous state or confirm failure.
            Project storage project = projects[dispute.subjectId];
            if (project.status == ProjectStatus.Disputed) {
                // If dispute fails, revert to previous state or confirm original finalization
                // For simplicity, let's assume it confirms original state or failure
                if (project.aiScore >= 70) { // If AI score was good, maybe it goes back to awaiting review
                   project.status = ProjectStatus.FinalizedFailure; // Or previous status before dispute
                } else {
                    project.status = ProjectStatus.FinalizedFailure;
                }
            }
        }
        dispute.resolutionBlock = block.number;
        emit DisputeResolved(_disputeId, dispute.status);
    }
}
```