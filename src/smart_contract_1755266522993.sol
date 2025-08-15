This smart contract, **AetherFlow Labs**, presents a decentralized autonomous research and development platform. It's designed to bring a new level of transparency, decentralization, and innovation to scientific and technological advancements by integrating AI evaluation, dynamic intellectual property NFTs, and a robust reputation system, all governed by a DAO.

---

## AetherFlow Labs: Decentralized Autonomous Research & Development Platform (DARL)

### Outline:

1.  **Overview**: A decentralized platform for funding, managing, and monetizing research and development projects. It leverages AI Oracles for initial proposal evaluation, a robust reputation system for participants, dynamic IP NFTs for intellectual property, and DAO governance for decision-making.
2.  **Core Components**:
    *   **Project Lifecycle Management**: From proposal submission to project closure, with staged funding releases linked to milestones.
    *   **AI Oracle Integration**: For automated, data-driven preliminary analysis and scoring of research proposals.
    *   **Dynamic Intellectual Property (IP) NFTs**: ERC-721 tokens representing projects, with metadata that evolves and updates automatically as project milestones are met.
    *   **Reputation System**: Tracks and assigns scores (RScore) to researchers, reviewers, and contributors based on their platform activities, success rates, and impactful contributions.
    *   **DAO Governance**: A central mechanism for funding decisions, dispute resolution, platform parameter adjustments, and role delegations.
    *   **Milestone & Grant System**: Ensures funds are released progressively, tied to verifiable project progress.
    *   **Royalty Distribution**: A framework for distributing future earnings derived from the intellectual property to defined contributors.
3.  **Key Innovations**:
    *   **AI-Enhanced Curation**: Using an AI oracle to pre-screen proposals, offering an objective initial assessment that can reduce human bias and streamline the review process.
    *   **Adaptive IP NFTs**: NFTs that are not static but change and accrue value (via metadata updates) as projects mature, reflecting the ongoing development and achievements of the underlying IP.
    *   **Verifiable Milestone Proofs (ZK-Proof Compatibility)**: Designed to accept hash commitments to off-chain Zero-Knowledge Proofs, allowing for privacy-preserving verification of complex milestones without revealing sensitive underlying data.
    *   **Dynamic Reputation-Weighted Incentives**: Encouraging quality contributions and responsible participation through a transparent and evolving reputation score that influences roles and privileges within the platform.
    *   **On-chain Dispute Resolution**: A mechanism for resolving conflicts related to projects or milestones, adjudicated by the DAO.

---

### Function Summary:

**I. Core Platform Management & Configuration:**
*   `constructor()`: Initializes the platform, sets up the initial admin, and deploys the `ProjectIPNFT` contract, granting it necessary roles.
*   `setAIDecisionOracle(address _oracle)`: Sets the address of the AI oracle contract responsible for proposal evaluation. Callable only by DAO.
*   `setGovernanceToken(address _token)`: Sets the address of the ERC-20 governance token used for DAO voting. Callable only by DAO.
*   `updatePlatformFeeRate(uint256 _newRatePermil)`: DAO-controlled function to update the platform's royalty fee percentage (in per-mille).
*   `pausePlatform()`: Emergency or DAO-approved function to pause core platform operations.
*   `unpausePlatform()`: Emergency or DAO-approved function to unpause core platform operations.

**II. Research Project Lifecycle:**
*   `submitResearchProposal(string memory _ipfsHash, uint256 _requestedFunding, Milestone[] memory _milestones, bytes32 _zkProofHashForPrivacy)`: Allows a researcher to submit a new project proposal, including IPFS hash of details, funding, milestones, and an optional hash of an off-chain ZK proof for private elements.
*   `requestAIDecision(uint256 _projectId)`: Initiates a request to the AI Oracle for an evaluation of a specific project proposal. Callable only by DAO.
*   `receiveAIDecision(uint256 _projectId, int256 _aiScore)`: Callback function for the AI Oracle to deliver its evaluation score for a project. Only callable by the designated AI Oracle.
*   `voteOnProposal(uint256 _projectId, bool _approve)`: DAO members cast their vote on whether to approve a project for funding. Requires holding governance tokens.
*   `finalizeProposalFunding(uint256 _projectId)`: Finalizes the funding for an approved project, mints the initial IP NFT, and conceptually releases the first milestone tranche. Callable only by DAO.
*   `submitMilestoneProof(uint256 _projectId, uint256 _milestoneIndex, string memory _ipfsProofHash, bytes32 _zkProofHashForPrivacy)`: Researcher submits proof of completion for a specific milestone.
*   `reviewMilestone(uint256 _projectId, uint256 _milestoneIndex, bool _approved)`: Appointed reviewers (or DAO) evaluate and approve/reject a submitted milestone proof.
*   `approveMilestone(uint256 _projectId, uint256 _milestoneIndex)`: Releases the funding for an approved milestone and triggers an update to the project's IP NFT metadata. Callable only by DAO.
*   `requestProjectClosure(uint256 _projectId)`: Researcher requests the formal closure of a completed project.
*   `finalizeProjectClosure(uint256 _projectId)`: DAO/admin formalizes the closure of a project, marking it as complete and potentially updating final IP NFT metadata. Callable only by DAO.

**III. Intellectual Property (IP) NFT & Royalties:**
*   `getProjectIPNFTAddress()`: Returns the address of the `ProjectIPNFT` ERC-721 contract deployed by the platform.
*   `distributeRoyalties(uint256 _projectId, uint256 _amount)`: Allows an external entity (e.g., royalty collector) to deposit royalties for a project, which are then distributed to the IP NFT holder(s) according to the registered split.
*   `registerIPRoyaltySplit(uint256 _projectId, address[] memory _contributors, uint256[] memory _shares)`: Allows the project owner to define how future royalties will be split among various contributors, recorded on the IP NFT.

**IV. Reputation System (RScore):**
*   `getResearcherRScore(address _researcher)`: Retrieves the current reputation score (RScore) of a given address.
*   `delegateReviewerRole(address _candidate)`: DAO can delegate specialized `REVIEWER_ROLE` based on a candidate's RScore.

**V. Dispute Resolution (Simplified):**
*   `raiseDispute(uint256 _projectId, uint256 _milestoneIndex, string memory _disputeReasonIPFSHash)`: Allows any participant to raise a dispute related to a project or a specific milestone.
*   `voteOnDispute(uint256 _disputeId, bool _resolution)`: DAO members cast their vote on the resolution of an active dispute. Requires holding governance tokens.
*   `finalizeDisputeResolution(uint256 _disputeId)`: DAO-controlled function to finalize the outcome of a dispute based on voting results, potentially affecting project status or RScore.

**VI. Data & Utility Functions:**
*   `getProjectDetails(uint256 _projectId)`: Returns comprehensive structured data about a specific project.
*   `getMilestoneCount(uint256 _projectId)`: Returns the total number of milestones defined for a project.
*   `getMilestoneStatus(uint256 _projectId, uint256 _milestoneIndex)`: Returns the current status and details of a specific milestone.
*   `getDisputeDetails(uint256 _disputeId)`: Returns the details of a specific dispute.

---

### Smart Contract Code:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // Using ERC721 directly for ProjectIPNFT
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Interfaces ---
// Mock AI Oracle Interface
interface IAIOracle {
    // _callbackSelector: the function selector of the callback function in _callbackContract
    function requestEvaluation(uint256 _projectId, string memory _ipfsHash, address _callbackContract, bytes4 _callbackSelector) external;
}

// --- ProjectIPNFT Contract (ERC-721 for dynamic IP) ---
contract ProjectIPNFT is ERC721, AccessControl {
    // Roles for controlling NFT minting and metadata updates
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant METADATA_UPDATER_ROLE = keccak256("METADATA_UPDATER_ROLE");

    // Private mapping to store token URIs, allowing for dynamic updates
    mapping(uint256 => string) private _tokenUris;

    constructor(address defaultAdmin) ERC721("AetherFlow Project IP", "AFL-IP") {
        // Grant DEFAULT_ADMIN_ROLE to the deploying address (AetherFlowLabs contract)
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
    }

    // Custom internal function to set the token URI, overriding default ERC721 behavior
    function _setTokenURI(uint256 tokenId, string memory uri) internal override {
        _tokenUris[tokenId] = uri;
    }

    // Public function to get token URI (standard ERC721)
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenUris[tokenId];
    }

    /**
     * @notice Mints a new Project IP NFT.
     * @param to The address to mint the NFT to.
     * @param tokenId The unique ID for the new NFT.
     * @param uri The initial metadata URI for the NFT.
     */
    function mint(address to, uint256 tokenId, string memory uri) external onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    /**
     * @notice Updates the metadata URI for an existing Project IP NFT.
     * This allows the NFT's representation to evolve with project progress.
     * @param tokenId The ID of the NFT to update.
     * @param newUri The new metadata URI.
     */
    function updateMetadata(uint256 tokenId, string memory newUri) external onlyRole(METADATA_UPDATER_ROLE) {
        require(_exists(tokenId), "ProjectIPNFT: Token does not exist.");
        _setTokenURI(tokenId, newUri);
        emit MetadataUpdate(tokenId);
    }

    // Event for metadata update, follows ERC721 Metadata Extensions
    event MetadataUpdate(uint256 _tokenId);
}


// --- Main AetherFlowLabs Contract ---
contract AetherFlowLabs is AccessControl, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- Roles ---
    // Role for addresses authorized to execute DAO-approved actions
    bytes32 public constant DAO_EXECUTOR_ROLE = keccak256("DAO_EXECUTOR_ROLE");
    // Role for designated reviewers who assess project milestones
    bytes32 public constant REVIEWER_ROLE = keccak256("REVIEWER_ROLE");
    // Role for the AI Oracle to call back `receiveAIDecision`
    bytes32 public constant AI_ORACLE_CALLBACK_ROLE = keccak256("AI_ORACLE_CALLBACK_ROLE");

    // --- State Variables ---
    Counters.Counter private _projectIdCounter;
    Counters.Counter private _disputeIdCounter;

    // Configuration
    address public aiOracleAddress; // Address of the external AI Oracle contract
    IERC20 public governanceToken; // Address of the DAO's ERC-20 governance token
    uint256 public platformFeePermil; // Platform fee rate in per-mille (e.g., 50 for 5%)
    ProjectIPNFT public projectIPNFT; // Instance of the deployed ProjectIPNFT contract

    // --- Data Structures ---
    enum ProjectStatus { Proposed, AI_Evaluating, Voting, FundingApproved, InProgress, Completed, Closed, Rejected, Disputed }
    enum MilestoneStatus { Pending, ProofSubmitted, ReviewInProgress, Approved, Rejected }
    enum DisputeStatus { Open, ResolvedApproved, ResolvedRejected }

    struct RoyaltySplit {
        address contributor;
        uint256 sharePermil; // Share in per-mille (e.g., 1000 for 100%)
    }

    struct Milestone {
        string descriptionIPFSHash;     // IPFS hash of milestone details/deliverables
        uint256 fundingAmount;          // Funding tranche released upon milestone approval
        MilestoneStatus status;
        string proofIPFSHash;           // IPFS hash of proof submitted by researcher
        bytes32 zkProofHashForPrivacy;  // Optional hash of an off-chain ZK proof for verification
        mapping(address => bool) reviewedBy; // Tracks which reviewers have submitted
        uint256 reviewApprovals;        // Number of positive reviews
        uint256 reviewRejections;       // Number of negative reviews
        bool isReviewApproved;          // Final decision for review, set by DAO_EXECUTOR_ROLE
    }

    struct Project {
        uint256 id;
        address researcher;
        string proposalIPFSHash;                // IPFS hash of the detailed research proposal
        uint256 requestedFunding;
        uint256 totalFundedAmount;              // Sum of all milestone funding released
        Milestone[] milestones;
        uint256 currentMilestoneIndex;          // Index of the milestone currently being worked on/funded
        ProjectStatus status;
        int256 aiScore;                         // AI evaluation score for the proposal
        uint256 ipNFTId;                        // Token ID of the associated Project IP NFT
        RoyaltySplit[] royaltySplit;            // Defines how future royalties are split
        mapping(address => bool) proposalVoted; // Tracks DAO members who voted on proposal
        uint256 proposalVotesFor;
        uint256 proposalVotesAgainst;
        uint256 disputeId;                      // ID of current active dispute, 0 if none
        uint256 projectBalance;                 // Conceptual balance for this project within the contract (not actual ETH)
        bytes32 zkProofHashForPrivacy;          // Optional hash for private elements in the initial proposal
    }

    struct Dispute {
        uint256 id;
        uint256 projectId;
        uint256 milestoneIndex;         // If dispute is milestone-specific (0 if project-level)
        address raisedBy;
        string reasonIPFSHash;          // IPFS hash of the detailed reason for the dispute
        DisputeStatus status;
        mapping(address => bool) voteCasted; // Tracks DAO members who voted on dispute
        uint256 resolutionVotesFor;
        uint256 resolutionVotesAgainst;
    }

    mapping(uint256 => Project) public projects;
    mapping(address => uint256) public researcherRScores; // Reputation score for participants
    mapping(uint256 => Dispute) public disputes;

    // --- Events ---
    event ProjectProposed(uint256 indexed projectId, address indexed researcher, string ipfsHash);
    event AIDecisionRequested(uint256 indexed projectId, address indexed aiOracle);
    event AIDecisionReceived(uint256 indexed projectId, int256 aiScore);
    event ProjectVoted(uint256 indexed projectId, address indexed voter, bool approved);
    event ProjectFundingApproved(uint256 indexed projectId, uint256 amount);
    event MilestoneProofSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, string proofHash, bytes32 zkProofHash);
    event MilestoneReviewed(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed reviewer, bool approved);
    event MilestoneApproved(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 fundedAmount);
    event ProjectClosed(uint256 indexed projectId);
    event RoyaltiesDistributed(uint256 indexed projectId, uint256 amount);
    event RoyaltySplitRegistered(uint256 indexed projectId, address indexed owner);
    event RScoreUpdated(address indexed user, int256 newScore);
    event DisputeRaised(uint256 indexed disputeId, uint256 indexed projectId, address indexed raisedBy);
    event DisputeResolved(uint256 indexed disputeId, bool resolutionApproved);
    event PlatformFeeUpdated(uint252 newRatePermil);

    // --- Constructor ---
    constructor() Pausable(false) {
        // Grant DEFAULT_ADMIN_ROLE to the deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Initially grant DAO_EXECUTOR_ROLE to the deployer for setup.
        // In a full DAO, this role would be managed by a DAO governance contract.
        _grantRole(DAO_EXECUTOR_ROLE, msg.sender);

        // Deploy the ProjectIPNFT contract and grant it necessary roles
        projectIPNFT = new ProjectIPNFT(address(this));
        projectIPNFT.grantRole(projectIPNFT.MINTER_ROLE(), address(this));
        projectIPNFT.grantRole(projectIPNFT.METADATA_UPDATER_ROLE(), address(this));

        platformFeePermil = 50; // Default 5% platform fee (50 per-mille)
    }

    // --- Modifiers ---
    modifier onlyDAO() {
        require(hasRole(DAO_EXECUTOR_ROLE, msg.sender), "AFL: Must have DAO_EXECUTOR_ROLE");
        _;
    }

    modifier onlyAICallback() {
        require(msg.sender == aiOracleAddress, "AFL: Only AI Oracle can call this function");
        require(hasRole(AI_ORACLE_CALLBACK_ROLE, msg.sender), "AFL: AI Oracle needs callback role");
        _;
    }

    // --- I. Core Platform Management & Configuration ---

    /**
     * @notice Sets the address of the AI Oracle contract.
     * Callable only by addresses with the DAO_EXECUTOR_ROLE.
     * @param _oracle The address of the AI Oracle.
     */
    function setAIDecisionOracle(address _oracle) external onlyDAO {
        require(_oracle != address(0), "AFL: Invalid AI Oracle address");
        aiOracleAddress = _oracle;
        // Grant the AI Oracle the role to call back `receiveAIDecision`
        _grantRole(AI_ORACLE_CALLBACK_ROLE, _oracle);
    }

    /**
     * @notice Sets the address of the ERC-20 governance token used for DAO voting.
     * Callable only by addresses with the DAO_EXECUTOR_ROLE.
     * @param _token The address of the governance token.
     */
    function setGovernanceToken(address _token) external onlyDAO {
        require(_token != address(0), "AFL: Invalid governance token address");
        governanceToken = IERC20(_token);
    }

    /**
     * @notice Updates the platform's royalty fee rate.
     * Callable only by addresses with the DAO_EXECUTOR_ROLE.
     * @param _newRatePermil The new fee rate in per-mille (e.g., 50 for 5%).
     */
    function updatePlatformFeeRate(uint256 _newRatePermil) external onlyDAO {
        require(_newRatePermil <= 1000, "AFL: Fee rate cannot exceed 100%"); // 1000 permil = 100%
        platformFeePermil = _newRatePermil;
        emit PlatformFeeUpdated(_newRatePermil);
    }

    /**
     * @notice Pauses core platform operations in case of emergency or DAO decision.
     * Callable by DAO_EXECUTOR_ROLE.
     */
    function pausePlatform() public onlyDAO {
        _pause();
    }

    /**
     * @notice Unpauses core platform operations.
     * Callable by DAO_EXECUTOR_ROLE.
     */
    function unpausePlatform() public onlyDAO {
        _unpause();
    }

    // --- II. Research Project Lifecycle ---

    /**
     * @notice Allows a researcher to submit a new project proposal.
     * @param _ipfsHash IPFS hash pointing to detailed proposal information.
     * @param _requestedFunding Total funding requested for the project.
     * @param _milestones An array defining the project's milestones and their respective funding tranches.
     * @param _zkProofHashForPrivacy Optional hash of an off-chain ZK proof for private elements of the proposal.
     */
    function submitResearchProposal(
        string memory _ipfsHash,
        uint256 _requestedFunding,
        Milestone[] memory _milestones, // Milestones passed as a memory array
        bytes32 _zkProofHashForPrivacy
    ) external whenNotPaused nonReentrant {
        require(_requestedFunding > 0, "AFL: Funding must be greater than zero");
        require(_milestones.length > 0, "AFL: Must define at least one milestone");
        require(bytes(_ipfsHash).length > 0, "AFL: Proposal IPFS hash is required");

        uint256 totalMilestoneFunding;
        for (uint256 i = 0; i < _milestones.length; i++) {
            totalMilestoneFunding += _milestones[i].fundingAmount;
            require(_milestones[i].fundingAmount > 0, "AFL: Milestone funding must be positive");
            require(bytes(_milestones[i].descriptionIPFSHash).length > 0, "AFL: Milestone description required");
        }
        require(totalMilestoneFunding == _requestedFunding, "AFL: Sum of milestone funding must equal total requested funding");

        _projectIdCounter.increment();
        uint256 newProjectId = _projectIdCounter.current();

        Project storage newProject = projects[newProjectId];
        newProject.id = newProjectId;
        newProject.researcher = msg.sender;
        newProject.proposalIPFSHash = _ipfsHash;
        newProject.requestedFunding = _requestedFunding;
        // Copy milestone data. Mappings inside structs in storage arrays work as expected.
        newProject.milestones = new Milestone[](_milestones.length); // Initialize the storage array
        for(uint i=0; i<_milestones.length; i++) {
            newProject.milestones[i].descriptionIPFSHash = _milestones[i].descriptionIPFSHash;
            newProject.milestones[i].fundingAmount = _milestones[i].fundingAmount;
            newProject.milestones[i].status = MilestoneStatus.Pending; // Initial status for all milestones
            // Other fields like proofIPFSHash, zkProofHashForPrivacy, reviewApprovals, reviewRejections, isReviewApproved will be default initialized
        }
        newProject.currentMilestoneIndex = 0;
        newProject.status = ProjectStatus.Proposed;
        newProject.zkProofHashForPrivacy = _zkProofHashForPrivacy;

        emit ProjectProposed(newProjectId, msg.sender, _ipfsHash);
    }

    /**
     * @notice Requests an AI evaluation for a specific project proposal.
     * Callable only by addresses with the DAO_EXECUTOR_ROLE.
     * @param _projectId The ID of the project to be evaluated.
     */
    function requestAIDecision(uint256 _projectId) external onlyDAO {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Proposed, "AFL: Project not in Proposed status");
        require(aiOracleAddress != address(0), "AFL: AI Oracle not set");

        project.status = ProjectStatus.AI_Evaluating;

        // Callback selector for receiveAIDecision
        bytes4 callbackSelector = this.receiveAIDecision.selector;

        // Call the AI Oracle to request evaluation
        IAIOracle(aiOracleAddress).requestEvaluation(_projectId, project.proposalIPFSHash, address(this), callbackSelector);

        emit AIDecisionRequested(_projectId, aiOracleAddress);
    }

    /**
     * @notice Callback function for the AI Oracle to deliver its evaluation score.
     * Only callable by the designated AI Oracle.
     * @param _projectId The ID of the project evaluated.
     * @param _aiScore The evaluation score from the AI Oracle.
     */
    function receiveAIDecision(uint256 _projectId, int256 _aiScore) external onlyAICallback {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.AI_Evaluating, "AFL: Project not in AI_Evaluating status");

        project.aiScore = _aiScore;
        // A configurable threshold could be implemented here (e.g., if _aiScore < min_score, set to Rejected)
        project.status = ProjectStatus.Voting; // Transition to voting stage

        emit AIDecisionReceived(_projectId, _aiScore);
    }

    /**
     * @notice Allows DAO members to vote on funding a project proposal.
     * Requires holding governance tokens.
     * @param _projectId The ID of the project being voted on.
     * @param _approve True for approval vote, false for rejection vote.
     */
    function voteOnProposal(uint256 _projectId, bool _approve) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Voting, "AFL: Project not in Voting status");
        require(address(governanceToken) != address(0), "AFL: Governance token not set");
        require(!project.proposalVoted[msg.sender], "AFL: Already voted on this proposal");
        require(governanceToken.balanceOf(msg.sender) > 0, "AFL: Must hold governance tokens to vote");

        project.proposalVoted[msg.sender] = true;
        if (_approve) {
            project.proposalVotesFor++;
        } else {
            project.proposalVotesAgainst++;
        }

        emit ProjectVoted(_projectId, msg.sender, _approve);
        // In a full DAO, voting periods, quorum, and execution would be handled by a separate governance module.
    }

    /**
     * @notice Finalizes the funding for an approved project, mints its IP NFT, and releases initial funds.
     * Callable only by addresses with the DAO_EXECUTOR_ROLE.
     * @param _projectId The ID of the project to finalize funding for.
     */
    function finalizeProposalFunding(uint256 _projectId) external onlyDAO nonReentrant {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Voting, "AFL: Project not in Voting status");
        require(project.proposalVotesFor > project.proposalVotesAgainst, "AFL: Proposal not approved by majority");
        // Additional DAO logic for quorum, minimum voters, voting period completion should be here.

        project.status = ProjectStatus.FundingApproved;
        project.currentMilestoneIndex = 0; // Start with the first milestone

        // Mint the IP NFT for the project
        uint256 ipNFTId = _projectId; // Using project ID as NFT ID for simplicity
        projectIPNFT.mint(project.researcher, ipNFTId, project.proposalIPFSHash); // Initial metadata is the proposal hash
        project.ipNFTId = ipNFTId;

        // Transfer initial funding for the first milestone (if any)
        if (project.milestones.length > 0) {
            uint256 firstMilestoneFunding = project.milestones[0].fundingAmount;
            // IMPORTANT: In a real system, actual funds (ETH/tokens) would be transferred here
            // from a DAO treasury or external deposit.
            // For this example, `project.projectBalance` is an internal conceptual balance.
            project.projectBalance += firstMilestoneFunding;
            project.totalFundedAmount += firstMilestoneFunding;
            project.status = ProjectStatus.InProgress;
            project.milestones[0].status = MilestoneStatus.ReviewInProgress; // First milestone is implicitly in progress
            project.milestones[0].isReviewApproved = false; // Ensure it starts as not approved
        }

        // Update researcher RScore for successful proposal approval
        _updateRScore(project.researcher, 10);

        emit ProjectFundingApproved(_projectId, project.projectBalance);
    }

    /**
     * @notice Allows a researcher to submit proof of completion for a milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone being completed.
     * @param _ipfsProofHash IPFS hash of the proof (e.g., reports, code links, images).
     * @param _zkProofHashForPrivacy Optional hash of an off-chain ZK proof for private verification.
     */
    function submitMilestoneProof(
        uint256 _projectId,
        uint256 _milestoneIndex,
        string memory _ipfsProofHash,
        bytes32 _zkProofHashForPrivacy
    ) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.researcher == msg.sender, "AFL: Only project researcher can submit milestone proof");
        require(project.status == ProjectStatus.InProgress, "AFL: Project not in InProgress status");
        require(_milestoneIndex == project.currentMilestoneIndex, "AFL: Not the current milestone to be submitted");
        require(_milestoneIndex < project.milestones.length, "AFL: Invalid milestone index");
        require(bytes(_ipfsProofHash).length > 0, "AFL: Milestone proof hash is required");

        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.status != MilestoneStatus.Approved, "AFL: Milestone already approved");

        milestone.proofIPFSHash = _ipfsProofHash;
        milestone.zkProofHashForPrivacy = _zkProofHashForPrivacy;
        milestone.status = MilestoneStatus.ProofSubmitted;
        milestone.reviewApprovals = 0; // Reset reviews for new submission
        milestone.reviewRejections = 0;
        milestone.isReviewApproved = false; // Reset approval status

        emit MilestoneProofSubmitted(_projectId, _milestoneIndex, _ipfsProofHash, _zkProofHashForPrivacy);
    }

    /**
     * @notice Allows designated reviewers or DAO to review a submitted milestone proof.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone being reviewed.
     * @param _approved True if the review is positive, false otherwise.
     */
    function reviewMilestone(uint256 _projectId, uint256 _milestoneIndex, bool _approved) external whenNotPaused {
        require(hasRole(REVIEWER_ROLE, msg.sender) || hasRole(DAO_EXECUTOR_ROLE, msg.sender), "AFL: Only reviewers or DAO can review milestones");
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.InProgress, "AFL: Project not in InProgress status");
        require(_milestoneIndex < project.milestones.length, "AFL: Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.ProofSubmitted, "AFL: Milestone proof not submitted or already finalized");
        require(!milestone.reviewedBy[msg.sender], "AFL: Already reviewed this milestone");

        milestone.reviewedBy[msg.sender] = true;
        if (_approved) {
            milestone.reviewApprovals++;
        } else {
            milestone.reviewRejections++;
        }

        emit MilestoneReviewed(_projectId, _milestoneIndex, msg.sender, _approved);

        // Update reviewer's RScore based on contribution
        _updateRScore(msg.sender, _approved ? 1 : -1);
    }

    /**
     * @notice Approves a milestone, releases its funding tranche, and updates the IP NFT metadata.
     * Callable only by addresses with the DAO_EXECUTOR_ROLE, typically after a review period.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone to approve.
     */
    function approveMilestone(uint256 _projectId, uint256 _milestoneIndex) external onlyDAO nonReentrant {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.InProgress, "AFL: Project not in InProgress status");
        require(_milestoneIndex < project.milestones.length, "AFL: Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.ProofSubmitted, "AFL: Milestone proof not submitted");
        require(!milestone.isReviewApproved, "AFL: Milestone already finalized");

        // Example: Simple majority approval (can be more complex with review thresholds or specific DAO votes)
        require(milestone.reviewApprovals >= milestone.reviewRejections, "AFL: Milestone did not receive enough positive reviews");

        milestone.isReviewApproved = true;
        milestone.status = MilestoneStatus.Approved;
        _updateRScore(project.researcher, 5); // Researcher gets score for milestone completion

        // Update IP NFT metadata to reflect milestone completion (e.g., adding link to proof)
        string memory newIPFSMeta = string(abi.encodePacked(
            project.proposalIPFSHash, // Keep original proposal hash
            "_milestone_", Strings.toString(_milestoneIndex), "_proof_", milestone.proofIPFSHash
        ));
        projectIPNFT.updateMetadata(project.ipNFTId, newIPFSMeta);

        // Fund the next milestone or mark project as complete
        if (_milestoneIndex + 1 < project.milestones.length) {
            project.currentMilestoneIndex++;
            Milestone storage nextMilestone = project.milestones[project.currentMilestoneIndex];
            project.projectBalance += nextMilestone.fundingAmount; // Simulate transfer for next milestone
            project.totalFundedAmount += nextMilestone.fundingAmount;
            nextMilestone.status = MilestoneStatus.ReviewInProgress; // Next milestone implicitly in progress
            nextMilestone.isReviewApproved = false;
        } else {
            project.status = ProjectStatus.Completed; // All milestones done
        }

        emit MilestoneApproved(_projectId, _milestoneIndex, milestone.fundingAmount);
    }

    /**
     * @notice Allows the researcher to request formal closure of a completed project.
     * @param _projectId The ID of the project to close.
     */
    function requestProjectClosure(uint256 _projectId) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.researcher == msg.sender, "AFL: Only project researcher can request closure");
        require(project.status == ProjectStatus.Completed, "AFL: Project must be in Completed status");
        // No explicit status change, awaits `finalizeProjectClosure` by DAO
    }

    /**
     * @notice Formalizes the closure of a project, marking it as complete.
     * Callable only by addresses with the DAO_EXECUTOR_ROLE.
     * @param _projectId The ID of the project to finalize closure for.
     */
    function finalizeProjectClosure(uint256 _projectId) external onlyDAO nonReentrant {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Completed, "AFL: Project must be in Completed status");

        project.status = ProjectStatus.Closed;

        // Finalize IP NFT metadata (e.g., pointing to final report, patents)
        string memory finalIPFSMeta = string(abi.encodePacked("ipfs://final_report_hash_for_project_", Strings.toString(_projectId)));
        projectIPNFT.updateMetadata(project.ipNFTId, finalIPFSMeta);

        // Any remaining `projectBalance` could be transferred to the researcher here
        // (e.g., `payable(project.researcher).transfer(project.projectBalance);`)
        project.projectBalance = 0; // Clear internal balance after assumed transfer

        // Researcher gets a final boost to RScore for successful project completion
        _updateRScore(project.researcher, 20);

        emit ProjectClosed(_projectId);
    }

    // --- III. Intellectual Property (IP) NFT & Royalties ---

    /**
     * @notice Returns the address of the deployed ProjectIPNFT contract.
     */
    function getProjectIPNFTAddress() external view returns (address) {
        return address(projectIPNFT);
    }

    /**
     * @notice Distributes collected royalties for a project to its defined contributors.
     * This function assumes an external entity deposits funds into the contract for distribution.
     * @param _projectId The ID of the project for which royalties are being distributed.
     * @param _amount The total amount of royalties to distribute (in native token or an ERC20, current implementation assumes native token distribution from a previously deposited amount or mock).
     */
    function distributeRoyalties(uint256 _projectId, uint256 _amount) external nonReentrant {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Closed, "AFL: Project must be closed to distribute royalties");
        require(_amount > 0, "AFL: Amount must be positive");
        // In a real system, `msg.value` would be checked if sending native token, or `IERC20(royaltyToken).transferFrom` if ERC20.

        uint256 platformFee = (_amount * platformFeePermil) / 1000;
        uint256 amountToDistribute = _amount - platformFee;

        // Collect platform fee (e.g., transfer to a DAO treasury address)
        // (new CallReceiver(DAO_TREASURY_ADDRESS)).call{value: platformFee}(""); // Placeholder

        if (project.royaltySplit.length > 0) {
            uint256 totalShares;
            for (uint256 i = 0; i < project.royaltySplit.length; i++) {
                totalShares += project.royaltySplit[i].sharePermil;
            }
            require(totalShares == 1000, "AFL: Royalty shares must sum to 1000 permil (100%)");

            for (uint256 i = 0; i < project.royaltySplit.length; i++) {
                address contributor = project.royaltySplit[i].contributor;
                uint256 shareAmount = (amountToDistribute * project.royaltySplit[i].sharePermil) / 1000;
                // Actual transfer of funds would happen here (e.g., `payable(contributor).transfer(shareAmount);`)
                // This is a placeholder for actual payment logic.
            }
        } else {
            // Default: Send all to the IP NFT holder (project researcher by default unless NFT transferred)
            address ipNFTOwner = projectIPNFT.ownerOf(project.ipNFTId);
            // payable(ipNFTOwner).transfer(amountToDistribute); // Placeholder for actual payment
        }

        emit RoyaltiesDistributed(_projectId, _amount);
    }

    /**
     * @notice Allows the project owner to define how future royalties will be split among contributors.
     * @param _projectId The ID of the project.
     * @param _contributors An array of addresses of contributors.
     * @param _shares An array of corresponding shares (in per-mille) for each contributor.
     */
    function registerIPRoyaltySplit(uint256 _projectId, address[] memory _contributors, uint256[] memory _shares) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.researcher == msg.sender || projectIPNFT.ownerOf(project.ipNFTId) == msg.sender, "AFL: Only project owner or IP NFT holder can define royalty split");
        require(project.status == ProjectStatus.FundingApproved || project.status == ProjectStatus.InProgress || project.status == ProjectStatus.Completed || project.status == ProjectStatus.Closed, "AFL: Project must be active or completed");
        require(_contributors.length == _shares.length, "AFL: Mismatch in contributors and shares array lengths");
        require(_contributors.length > 0, "AFL: Must specify at least one contributor");

        uint256 totalShares;
        for (uint256 i = 0; i < _shares.length; i++) {
            totalShares += _shares[i];
            require(_shares[i] > 0, "AFL: Shares must be positive");
            require(_contributors[i] != address(0), "AFL: Invalid contributor address");
        }
        require(totalShares == 1000, "AFL: Total shares must sum to 1000 (100%)");

        delete project.royaltySplit; // Clear existing split
        project.royaltySplit = new RoyaltySplit[](_contributors.length);
        for (uint256 i = 0; i < _contributors.length; i++) {
            project.royaltySplit[i] = RoyaltySplit({
                contributor: _contributors[i],
                sharePermil: _shares[i]
            });
        }

        emit RoyaltySplitRegistered(_projectId, msg.sender);
    }

    // --- IV. Reputation System (RScore) ---

    /**
     * @notice Internal function to update a user's Reputation Score (RScore).
     * @param _user The address of the user whose RScore is being updated.
     * @param _change The amount to change the RScore by (can be positive or negative).
     */
    function _updateRScore(address _user, int256 _change) internal {
        if (_change > 0) {
            researcherRScores[_user] += uint256(_change);
        } else if (_change < 0) {
            if (researcherRScores[_user] >= uint256(-_change)) {
                researcherRScores[_user] -= uint256(-_change);
            } else {
                researcherRScores[_user] = 0; // Prevent underflow
            }
        }
        // Emitting the new total score, not just the change
        emit RScoreUpdated(_user, int256(researcherRScores[_user]));
    }

    /**
     * @notice Retrieves the current Reputation Score (RScore) of a given address.
     * @param _researcher The address of the researcher/user.
     * @return The current RScore.
     */
    function getResearcherRScore(address _researcher) public view returns (uint256) {
        return researcherRScores[_researcher];
    }

    /**
     * @notice Allows the DAO to delegate the REVIEWER_ROLE to a candidate based on their RScore.
     * Callable only by addresses with the DAO_EXECUTOR_ROLE.
     * @param _candidate The address of the candidate to grant the reviewer role to.
     */
    function delegateReviewerRole(address _candidate) external onlyDAO {
        require(researcherRScores[_candidate] >= 50, "AFL: Candidate RScore too low for reviewer role"); // Example threshold
        _grantRole(REVIEWER_ROLE, _candidate);
    }

    // --- V. Dispute Resolution (Simplified) ---

    /**
     * @notice Allows any participant to raise a dispute related to a project or milestone.
     * @param _projectId The ID of the project the dispute is related to.
     * @param _milestoneIndex The index of the specific milestone, or 0 for a project-level dispute.
     * @param _disputeReasonIPFSHash IPFS hash of the detailed reason for the dispute.
     */
    function raiseDispute(
        uint256 _projectId,
        uint256 _milestoneIndex,
        string memory _disputeReasonIPFSHash
    ) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "AFL: Project does not exist");
        require(project.disputeId == 0, "AFL: Project already has an active dispute");
        require(bytes(_disputeReasonIPFSHash).length > 0, "AFL: Dispute reason required");

        _disputeIdCounter.increment();
        uint256 newDisputeId = _disputeIdCounter.current();

        Dispute storage newDispute = disputes[newDisputeId];
        newDispute.id = newDisputeId;
        newDispute.projectId = _projectId;
        newDispute.milestoneIndex = _milestoneIndex;
        newDispute.raisedBy = msg.sender;
        newDispute.reasonIPFSHash = _disputeReasonIPFSHash;
        newDispute.status = DisputeStatus.Open;

        project.disputeId = newDisputeId; // Link dispute to project
        if (project.status != ProjectStatus.Disputed) {
             project.status = ProjectStatus.Disputed; // Pause project progression during dispute
        }

        emit DisputeRaised(newDisputeId, _projectId, msg.sender);
    }

    /**
     * @notice Allows DAO members to vote on the resolution of an active dispute.
     * @param _disputeId The ID of the dispute being voted on.
     * @param _resolution True for approving the dispute's resolution, false for rejecting it.
     */
    function voteOnDispute(uint256 _disputeId, bool _resolution) external whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Open, "AFL: Dispute not open for voting");
        require(address(governanceToken) != address(0), "AFL: Governance token not set");
        require(!dispute.voteCasted[msg.sender], "AFL: Already voted on this dispute");
        require(governanceToken.balanceOf(msg.sender) > 0, "AFL: Must hold governance tokens to vote");

        dispute.voteCasted[msg.sender] = true;
        if (_resolution) {
            dispute.resolutionVotesFor++;
        } else {
            dispute.resolutionVotesAgainst++;
        }

        // In a full DAO, execution after voting period would be handled by a separate governance module.
    }

    /**
     * @notice Finalizes the resolution of a dispute based on voting results.
     * Callable only by addresses with the DAO_EXECUTOR_ROLE.
     * @param _disputeId The ID of the dispute to finalize.
     */
    function finalizeDisputeResolution(uint256 _disputeId) external onlyDAO {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Open, "AFL: Dispute not open for finalization");

        bool resolutionApproved = (dispute.resolutionVotesFor > dispute.resolutionVotesAgainst);
        if (resolutionApproved) {
            dispute.status = DisputeStatus.ResolvedApproved;
            // Example of dispute resolution impact:
            // If the dispute successfully invalidated a milestone proof, you might revert milestone status
            // or penalize the researcher by reducing their RScore.
            // _updateRScore(dispute.raisedBy, 5); // Example: reward for raising a valid dispute
            // _updateRScore(projects[dispute.projectId].researcher, -10); // Example: penalize researcher
        } else {
            dispute.status = DisputeStatus.ResolvedRejected;
            // Example: penalize dispute raiser for invalid dispute
            // _updateRScore(dispute.raisedBy, -5);
        }

        Project storage project = projects[dispute.projectId];
        project.disputeId = 0; // Clear dispute link
        if (project.status == ProjectStatus.Disputed) {
            // Restore previous status or set to a sensible default if dispute resolved
            project.status = ProjectStatus.InProgress;
        }

        emit DisputeResolved(_disputeId, resolutionApproved);
    }

    // --- VI. Data & Utility Functions ---

    /**
     * @notice Returns comprehensive structured data about a specific project.
     * @param _projectId The ID of the project.
     */
    function getProjectDetails(uint256 _projectId)
        public view
        returns (
            uint256 id,
            address researcher,
            string memory proposalIPFSHash,
            uint256 requestedFunding,
            uint256 totalFundedAmount,
            ProjectStatus status,
            int256 aiScore,
            uint256 ipNFTId,
            uint256 currentMilestoneIndex,
            uint256 projectBalance,
            uint256 disputeId
        )
    {
        Project storage project = projects[_projectId];
        require(project.id != 0, "AFL: Project does not exist");
        return (
            project.id,
            project.researcher,
            project.proposalIPFSHash,
            project.requestedFunding,
            project.totalFundedAmount,
            project.status,
            project.aiScore,
            project.ipNFTId,
            project.currentMilestoneIndex,
            project.projectBalance,
            project.disputeId
        );
    }

    /**
     * @notice Returns the total number of milestones defined for a project.
     * @param _projectId The ID of the project.
     */
    function getMilestoneCount(uint256 _projectId) public view returns (uint256) {
        return projects[_projectId].milestones.length;
    }

    /**
     * @notice Returns the current status and detailed information of a specific milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     */
    function getMilestoneStatus(uint256 _projectId, uint256 _milestoneIndex)
        public view
        returns (
            string memory descriptionIPFSHash,
            uint256 fundingAmount,
            MilestoneStatus status,
            string memory proofIPFSHash,
            bytes32 zkProofHashForPrivacy,
            uint256 reviewApprovals,
            uint256 reviewRejections,
            bool isReviewApproved
        )
    {
        Project storage project = projects[_projectId];
        require(project.id != 0, "AFL: Project does not exist");
        require(_milestoneIndex < project.milestones.length, "AFL: Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        return (
            milestone.descriptionIPFSHash,
            milestone.fundingAmount,
            milestone.status,
            milestone.proofIPFSHash,
            milestone.zkProofHashForPrivacy,
            milestone.reviewApprovals,
            milestone.reviewRejections,
            milestone.isReviewApproved
        );
    }

    /**
     * @notice Returns the details of a specific dispute.
     * @param _disputeId The ID of the dispute.
     */
    function getDisputeDetails(uint256 _disputeId)
        public view
        returns (
            uint256 id,
            uint256 projectId,
            uint256 milestoneIndex,
            address raisedBy,
            string memory reasonIPFSHash,
            DisputeStatus status,
            uint256 resolutionVotesFor,
            uint256 resolutionVotesAgainst
        )
    {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "AFL: Dispute does not exist");
        return (
            dispute.id,
            dispute.projectId,
            dispute.milestoneIndex,
            dispute.raisedBy,
            dispute.reasonIPFSHash,
            dispute.status,
            dispute.resolutionVotesFor,
            dispute.resolutionVotesAgainst
        );
    }
}
```