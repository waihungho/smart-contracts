Here's a Solidity smart contract for a **Decentralized Knowledge Nexus (DKN)**, incorporating advanced concepts like Soul-Bound Tokens (SBTs) for dynamic reputation, milestone-based project funding with peer and AI oracle review, tokenized knowledge assets (TKAs) with access control and royalties, and a decentralized task market with AI-assisted assignments.

It is designed to be innovative, creative, and avoids direct duplication of common open-source patterns by combining these features in a novel way within a single, cohesive system.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For converting uint to string for tokenURI

// Interface for a generic AI oracle (e.g., Chainlink's AnyAPI or a custom verifiable computation service)
interface IAIOracle {
    // A simplified request function. In a real Chainlink setup, this would be more complex
    // with `requestBytes` or `requestUint256` etc., and specific callback handling.
    // For this example, it represents sending a request payload to an off-chain AI service.
    function request(bytes memory _requestData) external returns (bytes32 requestId);
}

/**
 * @title DecentralizedKnowledgeNexus
 * @dev A cutting-edge smart contract for a decentralized autonomous research & development (DARD) platform.
 *      It facilitates collaborative, incentivized, and reputation-driven research, tokenizes knowledge assets,
 *      and integrates AI oracles for advanced functionalities like peer review and task assignment.
 *      This contract aims to create a self-sustaining ecosystem for scientific discovery and innovation,
 *      combining concepts like Soul-Bound Tokens (SBTs) for reputation, dynamic NFTs, milestone-based funding,
 *      tokenized knowledge assets (TKAs) with access control, and a decentralized task market.
 *      It implements its own ERC721 for Knowledge Graph NFTs and Tokenized Knowledge Assets.
 */
contract DecentralizedKnowledgeNexus is Ownable, Pausable, ERC721 {
    using EnumerableSet.AddressSet for EnumerableSet.AddressSet;
    using EnumerableSet.UintSet for EnumerableSet.UintSet; // For tracking projects by contributor
    using Counters for Counters.Counter;

    // --- Outline and Function Summary ---

    // I. Core Platform Management (Ownership, Pausability, Oracle & Token Integration)
    // 1. constructor(): Initializes owner, sets up initial AI oracle and token addresses.
    // 2. updateOracleAddress(address _newOracle): Updates the address for the AI/data oracle.
    // 3. updateTokenAddresses(address _govToken, address _nativeToken): Updates addresses for governance and the native funding token.
    // 4. pause(): Pauses contract operations, preventing most state-changing actions (owner only).
    // 5. unpause(): Unpauses contract operations (owner only).

    // II. Researcher Identity & Reputation (Soul-Bound Tokens & Dynamic Reputation)
    // 6. registerResearcher(string memory _profileCID): Registers a new researcher, linking an off-chain profile.
    // 7. updateResearcherProfile(string memory _newProfileCID): Updates a researcher's linked profile metadata.
    // 8. endorseResearcher(address _researcher): Allows registered researchers to endorse others, boosting their reputation score.
    // 9. mintKnowledgeGraphNFT(address _researcher): Mints a non-transferable Soul-Bound Token (SBT) representing a researcher's cumulative reputation and contributions. Its metadata is dynamic, reflecting score changes.

    // III. Research Project Lifecycle & Milestone-Based Funding
    // 10. proposeResearchProject(string memory _projectCID, uint256 _fundingGoal, uint256[] memory _milestoneAmounts, uint256[] memory _milestoneDurations): Submits a new project proposal with a funding goal and defined milestone allocations.
    // 11. fundProject(uint256 _projectId, uint256 _amount): Allows users to contribute funding to a project (uses nativeFundingToken).
    // 12. submitProjectMilestone(uint256 _projectId, uint256 _milestoneIndex, string memory _milestoneOutputCID): Project proposer submits work for a milestone.
    // 13. requestMilestoneReview(uint256 _projectId, uint256 _milestoneIndex): Triggers an AI oracle request for an initial assessment of a submitted milestone.
    // 14. submitPeerReviewScore(uint256 _projectId, uint256 _milestoneIndex, uint256 _score, string memory _reviewCID): Registered researchers submit peer review scores for a milestone.
    // 15. releaseMilestoneFunds(uint256 _projectId, uint256 _milestoneIndex): Releases funds to the project team after successful milestone review (based on a weighted average of peer and AI scores).

    // IV. Tokenized Knowledge Assets (TKA - ERC721 for Research Outputs)
    // 16. publishKnowledgeAsset(uint256 _projectId, uint256 _milestoneIndex, string memory _assetCID, bool _isPublic, uint256 _accessFee): Mints a new ERC721 TKA for research output, setting its access parameters and linking to IPFS.
    // 17. purchaseKnowledgeAssetAccess(uint256 _assetId): Allows users to pay the specified fee to gain access to private knowledge assets, with royalties distributed to the publisher and treasury.
    // 18. revokeKnowledgeAssetAccess(uint256 _assetId, address _user): Revokes a user's access to a licensed TKA (callable by the project proposer).
    // 19. updateKnowledgeAsset(uint256 _assetId, string memory _newAssetCID): Allows the original publisher to update the content of an existing TKA (e.g., a new version of a paper).

    // V. Decentralized Task Market (Bounties for Specific Research Tasks)
    // 20. createResearchTask(string memory _taskCID, uint256 _rewardAmount, uint256 _deadline): Posts a new task with a bounty, funding it from the creator's tokens.
    // 21. applyForTask(uint256 _taskId, string memory _applicationCID): Researchers apply for open tasks.
    // 22. requestAITaskAssignmentSuggestion(uint256 _taskId): Requests the AI oracle to suggest the best applicant for a task based on reputation and other metrics.
    // 23. assignTask(uint256 _taskId, address _applicant): Task creator assigns the task to an applicant, potentially using AI suggestions.
    // 24. submitTaskCompletion(uint256 _taskId, string memory _outputCID): Assigned researcher submits proof of task completion.
    // 25. verifyAndReleaseTaskPayment(uint256 _taskId): Task creator verifies completion and releases payment to the worker.

    // VI. AI Oracle Integration (Callback Functions)
    // 26. fulfillAIPeerReviewScore(bytes32 _requestId, uint256 _score, string memory _reasoningCID): Callback for the AI oracle to return a peer review score for a milestone.
    // 27. fulfillAITaskAssignmentSuggestion(bytes32 _requestId, address _suggestedApplicant, string memory _reasoningCID): Callback for the AI oracle to return a suggested applicant for a task.

    // VII. Treasury Management & Utilities
    // 28. getTreasuryFunds(): Returns the current balance of nativeFundingToken held by the contract treasury.
    // 29. withdrawTreasuryFunds(address _recipient, uint256 _amount): Allows the owner (or DAO) to withdraw funds from the treasury.

    // --- State Variables ---

    IAIOracle public aiOracle;
    IERC20 public governanceToken; // For future DAO governance, staking, or quadratic funding matching
    IERC20 public nativeFundingToken; // Token used for project funding and task rewards (e.g., stablecoin)

    Counters.Counter private _projectIdCounter;
    Counters.Counter private _assetIdCounter;
    Counters.Counter private _taskIdCounter;
    Counters.Counter private _knowledgeGraphNFTIdCounter;
    Counters.Counter private _oracleRequestIdCounter; // Unique ID for each oracle request

    // --- Structs ---

    struct Researcher {
        string profileCID; // IPFS CID for researcher's public profile metadata
        uint256 reputationScore; // A simple cumulative score
        uint256 knowledgeGraphNFTId; // 0 if KGNFT not minted yet, otherwise the tokenId
        EnumerableSet.AddressSet endorsedBy; // Set of addresses that have endorsed this researcher
    }

    struct Project {
        address proposer;
        string projectCID; // IPFS CID for project proposal details
        uint256 fundingGoal;
        uint256 raisedFunds; // Funds available for milestones
        uint256[] milestoneAmounts; // Amount allocated for each milestone
        uint256[] milestoneDurations; // Expected duration for each milestone in seconds
        uint256 currentMilestone; // Index of the current active milestone (0-indexed)
        mapping(uint256 => Milestone) milestones;
        EnumerableSet.AddressSet contributors; // Addresses who contributed to funding
        bool completed;
        bool cancelled;
        uint256 lastActivityTime; // For tracking project freshness
    }

    struct Milestone {
        string outputCID; // IPFS CID for milestone deliverables
        bool submitted;
        bool approved;
        bool fundsReleased;
        uint256 submissionTime;
        mapping(address => uint256) peerReviewScores; // Address => score (1-10)
        uint256 totalPeerReviewScore;
        uint256 peerReviewCount;
        bytes32 aiReviewRequestId; // Request ID for AI oracle review
        uint256 aiReviewScore; // Score from AI oracle (1-10)
        string aiReviewReasoningCID; // IPFS CID for AI's reasoning/report
    }

    struct KnowledgeAsset {
        address publisher;
        uint256 projectId;
        uint256 milestoneIndex;
        string assetCID; // IPFS CID for the knowledge asset content
        bool isPublic;
        uint256 accessFee; // In nativeFundingToken
        mapping(address => bool) hasAccess; // Users who have purchased/been granted access
        uint256 creationTime;
        uint256 lastUpdateTime;
    }

    struct ResearchTask {
        address creator;
        string taskCID; // IPFS CID for task description
        uint256 rewardAmount; // In nativeFundingToken
        uint256 deadline;
        address assignedTo;
        string completionOutputCID;
        bool completed;
        bool verified;
        bool paid;
        bytes32 aiAssignmentRequestId; // Request ID for AI oracle task assignment suggestion
        EnumerableSet.AddressSet applicants; // Set of addresses who applied for the task
    }

    // --- Mappings ---

    mapping(address => Researcher) public researchers;
    EnumerableSet.AddressSet private _registeredResearchers; // Keep track of registered researchers for O(1) existence check

    mapping(uint256 => Project) public projects;
    mapping(address => EnumerableSet.UintSet) public projectsByContributor; // Projects an address contributed to

    mapping(uint256 => KnowledgeAsset) public knowledgeAssets; // ERC721 TokenId for Knowledge Assets
    mapping(uint256 => uint256) public assetProjectId; // Maps assetId to projectId
    mapping(uint256 => uint256) public assetMilestoneIndex; // Maps assetId to milestone index

    mapping(uint256 => ResearchTask) public researchTasks;

    // Oracle request mappings to link a request ID back to its relevant entity
    mapping(bytes32 => uint256) public oracleRequestToProjectId;
    mapping(bytes32 => uint256) public oracleRequestToMilestoneIndex;
    mapping(bytes32 => uint256) public oracleRequestToTaskId;

    // --- Events ---

    event ResearcherRegistered(address indexed researcher, string profileCID);
    event ResearcherProfileUpdated(address indexed researcher, string newProfileCID);
    event ResearcherEndorsed(address indexed endorser, address indexed endorsed, uint256 newReputationScore);
    event KnowledgeGraphNFTMinted(address indexed owner, uint256 tokenId, uint256 reputationScore);

    event ProjectProposed(uint256 indexed projectId, address indexed proposer, string projectCID, uint256 fundingGoal);
    event ProjectFunded(uint256 indexed projectId, address indexed contributor, uint256 amount, uint256 totalRaised);
    event MilestoneSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, string outputCID);
    event MilestoneReviewRequested(uint256 indexed projectId, uint256 indexed milestoneIndex, bytes32 requestId);
    event PeerReviewSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed reviewer, uint256 score);
    event MilestoneFundsReleased(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amount);

    event KnowledgeAssetPublished(uint256 indexed assetId, uint256 indexed projectId, address indexed publisher, string assetCID, bool isPublic, uint256 accessFee);
    event KnowledgeAssetAccessPurchased(uint256 indexed assetId, address indexed purchaser, uint256 amountPaid);
    event KnowledgeAssetAccessRevoked(uint256 indexed assetId, address indexed user);
    event KnowledgeAssetUpdated(uint256 indexed assetId, string newAssetCID);

    event ResearchTaskCreated(uint256 indexed taskId, address indexed creator, string taskCID, uint256 rewardAmount, uint256 deadline);
    event TaskApplied(uint256 indexed taskId, address indexed applicant);
    event AITaskAssignmentSuggested(bytes32 indexed requestId, uint256 taskId, address suggestedApplicant, string reasoningCID);
    event TaskAssigned(uint256 indexed taskId, address indexed assignedTo);
    event TaskCompletionSubmitted(uint256 indexed taskId, address indexed worker, string outputCID);
    event TaskPaymentReleased(uint256 indexed taskId, address indexed worker, uint256 amount);

    event AIPeerReviewScoreReceived(bytes32 indexed requestId, uint256 projectId, uint256 milestoneIndex, uint256 score, string reasoningCID);
    event AITaskAssignmentSuggestionReceived(bytes32 indexed requestId, uint256 taskId, address suggestedApplicant, string reasoningCID);
    
    // --- Modifiers ---

    modifier onlyResearcher() {
        require(_registeredResearchers.contains(msg.sender), "DKN: Caller is not a registered researcher");
        _;
    }

    modifier onlyProjectProposer(uint256 _projectId) {
        require(projects[_projectId].proposer != address(0), "DKN: Project does not exist");
        require(projects[_projectId].proposer == msg.sender, "DKN: Caller is not the project proposer");
        _;
    }

    modifier onlyTaskCreator(uint256 _taskId) {
        require(researchTasks[_taskId].creator != address(0), "DKN: Task does not exist");
        require(researchTasks[_taskId].creator == msg.sender, "DKN: Caller is not the task creator");
        _;
    }

    modifier onlyAssignedTaskWorker(uint256 _taskId) {
        require(researchTasks[_taskId].creator != address(0), "DKN: Task does not exist");
        require(researchTasks[_taskId].assignedTo == msg.sender, "DKN: Caller is not assigned to this task");
        _;
    }

    modifier onlyAIOracle() {
        require(msg.sender == address(aiOracle), "DKN: Caller is not the AI oracle");
        _;
    }

    // --- Constructor ---

    constructor(address _aiOracleAddress, address _governanceTokenAddress, address _nativeFundingTokenAddress)
        ERC721("KnowledgeGraphNFT & KnowledgeAsset", "DKN") // Single ERC721 for both types of NFTs
        Ownable(msg.sender)
    {
        require(_aiOracleAddress != address(0), "DKN: AI Oracle address cannot be zero");
        require(_governanceTokenAddress != address(0), "DKN: Governance Token address cannot be zero");
        require(_nativeFundingTokenAddress != address(0), "DKN: Native Funding Token address cannot be zero");

        aiOracle = IAIOracle(_aiOracleAddress);
        governanceToken = IERC20(_governanceTokenAddress);
        nativeFundingToken = IERC20(_nativeFundingTokenAddress);
    }

    // --- I. Core Platform Management ---

    function updateOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "DKN: New AI Oracle address cannot be zero");
        aiOracle = IAIOracle(_newOracle);
    }

    function updateTokenAddresses(address _govToken, address _nativeToken) public onlyOwner {
        require(_govToken != address(0), "DKN: New Governance Token address cannot be zero");
        require(_nativeToken != address(0), "DKN: New Native Funding Token address cannot be zero");
        governanceToken = IERC20(_govToken);
        nativeFundingToken = IERC20(_nativeToken);
    }

    // --- II. Researcher Identity & Reputation ---

    function registerResearcher(string memory _profileCID) public whenNotPaused {
        require(!_registeredResearchers.contains(msg.sender), "DKN: Caller is already a registered researcher");
        researchers[msg.sender].profileCID = _profileCID;
        researchers[msg.sender].reputationScore = 1; // Starting reputation score
        _registeredResearchers.add(msg.sender);
        emit ResearcherRegistered(msg.sender, _profileCID);
    }

    function updateResearcherProfile(string memory _newProfileCID) public onlyResearcher whenNotPaused {
        researchers[msg.sender].profileCID = _newProfileCID;
        emit ResearcherProfileUpdated(msg.sender, _newProfileCID);
    }

    function endorseResearcher(address _researcher) public onlyResearcher whenNotPaused {
        require(_researcher != address(0), "DKN: Cannot endorse zero address");
        require(_researcher != msg.sender, "DKN: Cannot endorse self");
        require(_registeredResearchers.contains(_researcher), "DKN: Target is not a registered researcher");
        require(!researchers[_researcher].endorsedBy.contains(msg.sender), "DKN: Already endorsed this researcher");

        researchers[_researcher].reputationScore += 1; // Simple linear reputation boost
        researchers[_researcher].endorsedBy.add(msg.sender);
        emit ResearcherEndorsed(msg.sender, _researcher, researchers[_researcher].reputationScore);

        // KGNFT metadata (if minted) would dynamically update off-chain based on this score
    }

    // SBT: Knowledge Graph NFT (ERC721 non-transferable)
    function mintKnowledgeGraphNFT(address _researcher) public onlyResearcher whenNotPaused {
        require(researchers[_researcher].knowledgeGraphNFTId == 0, "DKN: Knowledge Graph NFT already minted for this researcher");
        require(_researcher == msg.sender, "DKN: Can only mint KGNFT for self");

        _knowledgeGraphNFTIdCounter.increment();
        uint256 tokenId = _knowledgeGraphNFTIdCounter.current();

        _mint(_researcher, tokenId); // Mint an ERC721 to the researcher

        researchers[_researcher].knowledgeGraphNFTId = tokenId;

        // The tokenURI for this NFT would point to a dynamic JSON that updates with reputationScore, contributions, etc.
        // For this contract, we'll just set a base URI for off-chain rendering.
        _setTokenURI(tokenId, string(abi.encodePacked("ipfs://knowledgegraph/", Strings.toString(tokenId), "/metadata.json")));

        emit KnowledgeGraphNFTMinted(_researcher, tokenId, researchers[_researcher].reputationScore);
    }

    // Override _beforeTokenTransfer to enforce non-transferability for KGNFTs
    // and to manage knowledge assets via explicit access control, not ERC721 transfers.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // This contract's ERC721 implementation is designed such that all tokens are non-transferable
        // between users, adhering to the "soul-bound" and "fixed-ownership" philosophy.
        // KGNFTs are inherently non-transferable. Knowledge Assets are owned by the publisher,
        // and access is managed by `purchaseKnowledgeAssetAccess`, not by transferring the underlying ERC721.
        if (from != address(0) && to != address(0)) {
            revert("DKN: NFTs minted by this contract are non-transferable between users.");
        }
    }

    // Override ERC721 approval functions to prevent transfers of _any_ NFT minted by this contract
    function approve(address to, uint256 tokenId) public virtual override {
        revert("DKN: Approvals for NFTs in this contract are restricted due to non-transferability.");
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        revert("DKN: Approvals for NFTs in this contract are restricted due to non-transferability.");
    }

    // --- III. Research Project Lifecycle & Funding ---

    function proposeResearchProject(
        string memory _projectCID,
        uint256 _fundingGoal,
        uint256[] memory _milestoneAmounts,
        uint256[] memory _milestoneDurations
    ) public onlyResearcher whenNotPaused returns (uint256 projectId) {
        require(_fundingGoal > 0, "DKN: Funding goal must be greater than zero");
        require(_milestoneAmounts.length > 0, "DKN: Must define at least one milestone");
        require(_milestoneAmounts.length == _milestoneDurations.length, "DKN: Milestone amounts and durations mismatch");

        uint256 totalMilestoneAmount;
        for (uint256 i = 0; i < _milestoneAmounts.length; i++) {
            require(_milestoneAmounts[i] > 0, "DKN: Milestone amount must be greater than zero");
            require(_milestoneDurations[i] > 0, "DKN: Milestone duration must be greater than zero");
            totalMilestoneAmount += _milestoneAmounts[i];
        }
        require(totalMilestoneAmount == _fundingGoal, "DKN: Sum of milestone amounts must equal funding goal");

        _projectIdCounter.increment();
        projectId = _projectIdCounter.current();

        Project storage newProject = projects[projectId];
        newProject.proposer = msg.sender;
        newProject.projectCID = _projectCID;
        newProject.fundingGoal = _fundingGoal;
        newProject.milestoneAmounts = _milestoneAmounts;
        newProject.milestoneDurations = _milestoneDurations;
        newProject.currentMilestone = 0; // First milestone is at index 0
        newProject.lastActivityTime = block.timestamp;

        emit ProjectProposed(projectId, msg.sender, _projectCID, _fundingGoal);
    }

    function fundProject(uint256 _projectId, uint256 _amount) public whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.proposer != address(0), "DKN: Project does not exist");
        require(!project.completed, "DKN: Project is already completed");
        require(!project.cancelled, "DKN: Project is cancelled");
        require(project.raisedFunds < project.fundingGoal, "DKN: Project is fully funded");
        require(_amount > 0, "DKN: Funding amount must be greater than zero");

        uint256 remainingFundsNeeded = project.fundingGoal - project.raisedFunds;
        uint256 amountToTransfer = _amount;
        if (amountToTransfer > remainingFundsNeeded) {
            amountToTransfer = remainingFundsNeeded; // Only accept up to the funding goal
        }

        require(nativeFundingToken.transferFrom(msg.sender, address(this), amountToTransfer), "DKN: Token transfer for funding failed");

        project.raisedFunds += amountToTransfer;
        project.contributors.add(msg.sender);
        projectsByContributor[msg.sender].add(_projectId); // Track contributions
        project.lastActivityTime = block.timestamp;

        // Simple reputation boost for funding. Could be more sophisticated (e.g., quadratic calculation or matching).
        if (_registeredResearchers.contains(msg.sender)) {
            researchers[msg.sender].reputationScore += (amountToTransfer / 100); // Small boost per 100 units funded
        }

        emit ProjectFunded(_projectId, msg.sender, amountToTransfer, project.raisedFunds);
    }

    function submitProjectMilestone(uint256 _projectId, uint256 _milestoneIndex, string memory _milestoneOutputCID)
        public
        onlyProjectProposer(_projectId)
        whenNotPaused
    {
        Project storage project = projects[_projectId];
        require(_milestoneIndex == project.currentMilestone, "DKN: Not the current active milestone");
        require(_milestoneIndex < project.milestoneAmounts.length, "DKN: Milestone index out of bounds");
        require(!project.milestones[_milestoneIndex].submitted, "DKN: Milestone already submitted");
        require(_milestoneOutputCID.length > 0, "DKN: Milestone output CID cannot be empty");

        Milestone storage milestone = project.milestones[_milestoneIndex];
        milestone.outputCID = _milestoneOutputCID;
        milestone.submitted = true;
        milestone.submissionTime = block.timestamp;
        project.lastActivityTime = block.timestamp;

        emit MilestoneSubmitted(_projectId, _milestoneIndex, _milestoneOutputCID);
    }

    function requestMilestoneReview(uint256 _projectId, uint256 _milestoneIndex)
        public
        onlyProjectProposer(_projectId)
        whenNotPaused
    {
        Project storage project = projects[_projectId];
        require(_milestoneIndex < project.milestoneAmounts.length, "DKN: Milestone index out of bounds");
        require(project.milestones[_milestoneIndex].submitted, "DKN: Milestone not yet submitted");
        require(project.milestones[_milestoneIndex].aiReviewRequestId == bytes32(0), "DKN: AI review already requested for this milestone");

        _oracleRequestIdCounter.increment();
        bytes32 requestId = keccak256(abi.encodePacked(_oracleRequestIdCounter.current(), block.timestamp, msg.sender, _projectId, _milestoneIndex)); // Unique request ID

        // Store mapping for callback
        oracleRequestToProjectId[requestId] = _projectId;
        oracleRequestToMilestoneIndex[requestId] = _milestoneIndex;

        // Make a request to the AI oracle (pass relevant data for review)
        // In a real Chainlink setup, this would use `ChainlinkClient.request`
        aiOracle.request(abi.encodePacked("peer_review", project.milestones[_milestoneIndex].outputCID, Strings.toString(_milestoneIndex)));
        project.milestones[_milestoneIndex].aiReviewRequestId = requestId;

        emit MilestoneReviewRequested(_projectId, _milestoneIndex, requestId);
    }

    function submitPeerReviewScore(uint256 _projectId, uint256 _milestoneIndex, uint256 _score, string memory _reviewCID)
        public
        onlyResearcher
        whenNotPaused
    {
        Project storage project = projects[_projectId];
        require(_milestoneIndex < project.milestoneAmounts.length, "DKN: Milestone index out of bounds");
        require(project.milestones[_milestoneIndex].submitted, "DKN: Milestone not yet submitted");
        require(_score >= 1 && _score <= 10, "DKN: Score must be between 1 and 10");
        require(project.proposer != msg.sender, "DKN: Proposer cannot peer review their own milestone");
        require(project.milestones[_milestoneIndex].peerReviewScores[msg.sender] == 0, "DKN: Already reviewed this milestone");
        require(_reviewCID.length > 0, "DKN: Review CID cannot be empty");

        Milestone storage milestone = project.milestones[_milestoneIndex];
        milestone.peerReviewScores[msg.sender] = _score;
        milestone.totalPeerReviewScore += _score;
        milestone.peerReviewCount += 1;
        project.lastActivityTime = block.timestamp;

        // Increase reviewer's reputation for active and helpful participation
        researchers[msg.sender].reputationScore += 1;

        emit PeerReviewSubmitted(_projectId, _milestoneIndex, msg.sender, _score);
    }

    function releaseMilestoneFunds(uint256 _projectId, uint256 _milestoneIndex)
        public
        onlyProjectProposer(_projectId)
        whenNotPaused
    {
        Project storage project = projects[_projectId];
        require(_milestoneIndex == project.currentMilestone, "DKN: Not the current active milestone");
        require(_milestoneIndex < project.milestoneAmounts.length, "DKN: Milestone index out of bounds");

        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.submitted, "DKN: Milestone not yet submitted");
        require(!milestone.fundsReleased, "DKN: Funds for this milestone already released");

        // Decision criteria: A combination of peer review (if available) and AI review (if available)
        uint256 avgPeerScore = milestone.peerReviewCount > 0 ? (milestone.totalPeerReviewScore / milestone.peerReviewCount) : 0;
        uint256 finalScore;
        
        if (milestone.aiReviewRequestId != bytes32(0) && milestone.aiReviewScore > 0) {
            // If both peer and AI reviews are present, take a weighted average
            if (milestone.peerReviewCount > 0) {
                 finalScore = (avgPeerScore * 7 + milestone.aiReviewScore * 3) / 10; // 70% peer, 30% AI
            } else {
                 finalScore = milestone.aiReviewScore; // Only AI score if no peer reviews
            }
        } else if (milestone.peerReviewCount > 0) {
            finalScore = avgPeerScore; // Only peer score if no AI review
        } else {
            revert("DKN: No sufficient review (peer or AI) to release funds.");
        }
        
        uint256 MIN_APPROVAL_SCORE = 6; // Example threshold for approval

        require(finalScore >= MIN_APPROVAL_SCORE, "DKN: Milestone review score too low for fund release");

        uint256 amountToRelease = project.milestoneAmounts[_milestoneIndex];
        require(project.raisedFunds >= amountToRelease, "DKN: Insufficient funds in project treasury for milestone");

        // Transfer funds to the project proposer (or a designated multi-sig for the team)
        require(nativeFundingToken.transfer(project.proposer, amountToRelease), "DKN: Milestone fund transfer failed");

        milestone.approved = true;
        milestone.fundsReleased = true;
        project.raisedFunds -= amountToRelease; // Deduct from the project's available funds
        project.currentMilestone += 1;
        project.lastActivityTime = block.timestamp;

        if (project.currentMilestone == project.milestoneAmounts.length) {
            project.completed = true;
            // Optionally, handle any remaining `project.raisedFunds` by returning to contributors or treasury
        }

        emit MilestoneFundsReleased(_projectId, _milestoneIndex, amountToRelease);
    }

    // --- IV. Tokenized Knowledge Assets (TKA - ERC721 for research outputs) ---

    function publishKnowledgeAsset(
        uint256 _projectId,
        uint256 _milestoneIndex,
        string memory _assetCID,
        bool _isPublic,
        uint256 _accessFee
    ) public onlyProjectProposer(_projectId) whenNotPaused returns (uint256 assetId) {
        Project storage project = projects[_projectId];
        require(_milestoneIndex < project.milestoneAmounts.length, "DKN: Milestone index out of bounds");
        require(project.milestones[_milestoneIndex].approved, "DKN: Milestone not yet approved to publish assets");
        require(!_isPublic || (_isPublic && _accessFee == 0), "DKN: Public assets cannot have an access fee");
        require(_assetCID.length > 0, "DKN: Asset CID cannot be empty");

        _assetIdCounter.increment();
        assetId = _assetIdCounter.current();

        knowledgeAssets[assetId].publisher = msg.sender;
        knowledgeAssets[assetId].projectId = _projectId;
        knowledgeAssets[assetId].milestoneIndex = _milestoneIndex;
        knowledgeAssets[assetId].assetCID = _assetCID;
        knowledgeAssets[assetId].isPublic = _isPublic;
        knowledgeAssets[assetId].accessFee = _accessFee;
        knowledgeAssets[assetId].creationTime = block.timestamp;
        knowledgeAssets[assetId].lastUpdateTime = block.timestamp;

        assetProjectId[assetId] = _projectId;
        assetMilestoneIndex[assetId] = _milestoneIndex;

        // Mint an ERC721 for the knowledge asset (this is *not* a KGNFT, but uses the same ERC721 contract)
        _mint(msg.sender, assetId);
        _setTokenURI(assetId, string(abi.encodePacked("ipfs://knowledgeasset/", Strings.toString(assetId), "/metadata.json")));

        emit KnowledgeAssetPublished(assetId, _projectId, msg.sender, _assetCID, _isPublic, _accessFee);
    }

    function purchaseKnowledgeAssetAccess(uint256 _assetId) public whenNotPaused {
        KnowledgeAsset storage asset = knowledgeAssets[_assetId];
        require(asset.publisher != address(0), "DKN: Knowledge Asset does not exist");
        require(!asset.isPublic, "DKN: Asset is public, no purchase necessary");
        require(asset.accessFee > 0, "DKN: Asset has no access fee");
        require(!asset.hasAccess[msg.sender], "DKN: Caller already has access to this asset");
        require(msg.sender != asset.publisher, "DKN: Publisher already has access");

        require(nativeFundingToken.transferFrom(msg.sender, address(this), asset.accessFee), "DKN: Token transfer for access failed");

        asset.hasAccess[msg.sender] = true;
        
        // Distribute royalties (e.g., 80% to publisher, 20% to DAO treasury)
        uint256 publisherShare = asset.accessFee * 80 / 100; // 80%
        uint256 treasuryShare = asset.accessFee - publisherShare; // 20%

        require(nativeFundingToken.transfer(asset.publisher, publisherShare), "DKN: Royalty transfer to publisher failed");
        // Treasury share remains in the contract, managed by governance

        emit KnowledgeAssetAccessPurchased(_assetId, msg.sender, asset.accessFee);
    }

    function revokeKnowledgeAssetAccess(uint256 _assetId, address _user) public onlyProjectProposer(knowledgeAssets[_assetId].projectId) whenNotPaused {
        KnowledgeAsset storage asset = knowledgeAssets[_assetId];
        require(asset.publisher != address(0), "DKN: Knowledge Asset does not exist");
        require(asset.hasAccess[_user], "DKN: User does not have access to this asset");
        require(_user != asset.publisher, "DKN: Cannot revoke access from publisher");

        asset.hasAccess[_user] = false;

        emit KnowledgeAssetAccessRevoked(_assetId, _user);
    }

    function updateKnowledgeAsset(uint256 _assetId, string memory _newAssetCID) public whenNotPaused {
        KnowledgeAsset storage asset = knowledgeAssets[_assetId];
        require(asset.publisher == msg.sender, "DKN: Only the publisher can update the asset");
        require(_newAssetCID.length > 0, "DKN: New asset CID cannot be empty");
        
        asset.assetCID = _newAssetCID;
        asset.lastUpdateTime = block.timestamp;

        // Optionally update the ERC721 tokenURI to reflect the new version
        // This might involve versioning the metadata itself.
        // For simplicity, we just update the internal CID.

        emit KnowledgeAssetUpdated(_assetId, _newAssetCID);
    }

    // --- V. Decentralized Task Market ---

    function createResearchTask(
        string memory _taskCID,
        uint256 _rewardAmount,
        uint256 _deadline
    ) public onlyResearcher whenNotPaused returns (uint256 taskId) {
        require(_rewardAmount > 0, "DKN: Reward amount must be greater than zero");
        require(_deadline > block.timestamp, "DKN: Deadline must be in the future");
        require(_taskCID.length > 0, "DKN: Task CID cannot be empty");
        require(nativeFundingToken.transferFrom(msg.sender, address(this), _rewardAmount), "DKN: Failed to transfer reward tokens to contract treasury");

        _taskIdCounter.increment();
        taskId = _taskIdCounter.current();

        ResearchTask storage newTask = researchTasks[taskId];
        newTask.creator = msg.sender;
        newTask.taskCID = _taskCID;
        newTask.rewardAmount = _rewardAmount;
        newTask.deadline = _deadline;

        emit ResearchTaskCreated(taskId, msg.sender, _taskCID, _rewardAmount, _deadline);
    }

    function applyForTask(uint256 _taskId, string memory _applicationCID) public onlyResearcher whenNotPaused {
        ResearchTask storage task = researchTasks[_taskId];
        require(task.creator != address(0), "DKN: Task does not exist");
        require(task.assignedTo == address(0), "DKN: Task is already assigned");
        require(block.timestamp < task.deadline, "DKN: Task application deadline passed");
        require(!task.applicants.contains(msg.sender), "DKN: Already applied for this task");
        require(_applicationCID.length > 0, "DKN: Application CID cannot be empty");


        task.applicants.add(msg.sender);
        // The _applicationCID would typically be stored off-chain or in a separate mapping if needed for detailed review.

        emit TaskApplied(_taskId, msg.sender);
    }

    function requestAITaskAssignmentSuggestion(uint256 _taskId) public onlyTaskCreator(_taskId) whenNotPaused {
        ResearchTask storage task = researchTasks[_taskId];
        require(task.assignedTo == address(0), "DKN: Task is already assigned");
        require(block.timestamp < task.deadline, "DKN: Task application deadline passed");
        require(task.applicants.length() > 0, "DKN: No applicants to suggest from");
        require(task.aiAssignmentRequestId == bytes32(0), "DKN: AI assignment suggestion already requested");

        _oracleRequestIdCounter.increment();
        bytes32 requestId = keccak256(abi.encodePacked(_oracleRequestIdCounter.current(), block.timestamp, msg.sender, _taskId));

        oracleRequestToTaskId[requestId] = _taskId;

        address[] memory applicantAddresses = new address[](task.applicants.length());
        for (uint256 i = 0; i < task.applicants.length(); i++) {
            applicantAddresses[i] = task.applicants.at(i);
        }
        
        // Pass task details and applicant list to AI oracle for analysis
        aiOracle.request(abi.encodePacked("task_assignment_suggest", task.taskCID, applicantAddresses));
        task.aiAssignmentRequestId = requestId;

        // Event for AI request is emitted upon fulfillment
    }

    function assignTask(uint256 _taskId, address _applicant) public onlyTaskCreator(_taskId) whenNotPaused {
        ResearchTask storage task = researchTasks[_taskId];
        require(task.assignedTo == address(0), "DKN: Task is already assigned");
        require(task.applicants.contains(_applicant), "DKN: Applicant has not applied for this task");
        require(block.timestamp < task.deadline, "DKN: Cannot assign task after deadline"); // Assignment deadline

        task.assignedTo = _applicant;

        emit TaskAssigned(_taskId, _applicant);
    }

    function submitTaskCompletion(uint256 _taskId, string memory _outputCID) public onlyAssignedTaskWorker(_taskId) whenNotPaused {
        ResearchTask storage task = researchTasks[_taskId];
        require(!task.completed, "DKN: Task already completed");
        require(_outputCID.length > 0, "DKN: Output CID cannot be empty");
        // Optional: require(block.timestamp <= task.deadline, "DKN: Task completion deadline passed");

        task.completionOutputCID = _outputCID;
        task.completed = true;

        emit TaskCompletionSubmitted(_taskId, msg.sender, _outputCID);
    }

    function verifyAndReleaseTaskPayment(uint256 _taskId) public onlyTaskCreator(_taskId) whenNotPaused {
        ResearchTask storage task = researchTasks[_taskId];
        require(task.completed, "DKN: Task not yet completed");
        require(!task.verified, "DKN: Task already verified");
        require(!task.paid, "DKN: Task already paid");
        require(task.assignedTo != address(0), "DKN: Task was never assigned");

        // Verification logic: For simplicity, the creator verifies.
        // In a more complex system, this could involve additional peer review or AI verification.
        task.verified = true;

        require(nativeFundingToken.transfer(task.assignedTo, task.rewardAmount), "DKN: Task payment transfer failed");
        task.paid = true;

        // Increase worker's reputation for successful task completion
        if (_registeredResearchers.contains(task.assignedTo)) {
            researchers[task.assignedTo].reputationScore += 5; // Higher boost for completing a task
        }

        emit TaskPaymentReleased(_taskId, task.assignedTo, task.rewardAmount);
    }

    // --- VI. AI Oracle Integration (Callback Functions) ---
    // These functions are designed to be called by the trusted AI oracle contract.

    function fulfillAIPeerReviewScore(bytes32 _requestId, uint256 _score, string memory _reasoningCID) public onlyAIOracle {
        uint256 projectId = oracleRequestToProjectId[_requestId];
        uint256 milestoneIndex = oracleRequestToMilestoneIndex[_requestId];

        require(projectId != 0, "DKN: Invalid AI review request ID");
        require(milestoneIndex < projects[projectId].milestoneAmounts.length, "DKN: Milestone index out of bounds for AI review");

        Milestone storage milestone = projects[projectId].milestones[milestoneIndex];
        require(milestone.aiReviewRequestId == _requestId, "DKN: Mismatched AI review request ID");
        require(milestone.aiReviewScore == 0, "DKN: AI review score already recorded");
        require(_score >= 1 && _score <= 10, "DKN: AI Score must be between 1 and 10");

        milestone.aiReviewScore = _score;
        milestone.aiReviewReasoningCID = _reasoningCID;

        delete oracleRequestToProjectId[_requestId]; // Clean up mapping after fulfillment
        delete oracleRequestToMilestoneIndex[_requestId];

        emit AIPeerReviewScoreReceived(_requestId, projectId, milestoneIndex, _score, _reasoningCID);
    }

    function fulfillAITaskAssignmentSuggestion(bytes32 _requestId, address _suggestedApplicant, string memory _reasoningCID) public onlyAIOracle {
        uint256 taskId = oracleRequestToTaskId[_requestId];

        require(taskId != 0, "DKN: Invalid AI task assignment request ID");
        
        ResearchTask storage task = researchTasks[taskId];
        require(task.aiAssignmentRequestId == _requestId, "DKN: Mismatched AI assignment request ID");
        // Allow re-suggestions if task is still unassigned
        // require(task.assignedTo == address(0), "DKN: Task already assigned before AI suggestion");

        // The AI provides a suggestion. The task creator still needs to call `assignTask`.
        // This makes the AI a powerful recommender, not a direct decision-maker, maintaining human oversight.
        // For more advanced autonomy, the contract could directly assign if a high confidence threshold is met.
        // For simplicity, we just emit the event, and the task creator can see the suggestion off-chain.

        delete oracleRequestToTaskId[_requestId]; // Clean up mapping after fulfillment

        emit AITaskAssignmentSuggestionReceived(_requestId, taskId, _suggestedApplicant, _reasoningCID);
    }

    // --- VII. Treasury Management & Utilities ---

    function getTreasuryFunds() public view returns (uint256) {
        // Returns the balance of nativeFundingToken held by the contract.
        // These funds accumulate from TKA access fees (20% share) and unspent project funds (if any are returned).
        return nativeFundingToken.balanceOf(address(this));
    }

    function withdrawTreasuryFunds(address _recipient, uint256 _amount) public onlyOwner {
        // In a full DAO implementation, this function would typically be called by a governance
        // proposal execution, rather than directly by `onlyOwner`. For this example, it's owner-controlled.
        require(_recipient != address(0), "DKN: Recipient cannot be zero address");
        require(_amount > 0, "DKN: Amount must be greater than zero");
        require(nativeFundingToken.balanceOf(address(this)) >= _amount, "DKN: Insufficient treasury funds");
        
        require(nativeFundingToken.transfer(_recipient, _amount), "DKN: Treasury withdrawal failed");
    }
}
```