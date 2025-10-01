Here's a smart contract named `ArcanumCodex` that embodies several advanced, creative, and trendy concepts, while striving to be unique from common open-source implementations. It serves as a decentralized platform for funding and managing research, creative works, or problem-solving initiatives, integrating dynamic reputation, AI-assisted curation (simulated), milestone-based funding, peer review, and dynamic Soulbound NFTs for achievements.

---

**Arcanum Codex Smart Contract**

**Purpose:** A decentralized platform for funding and curating novel research, creative works, and problem-solving initiatives. It integrates dynamic soulbound reputation (SBTs), AI-assisted project evaluation (simulated), milestone-based funding, peer review, and dynamic "Knowledge Shards" (NFTs) representing significant achievements.

---

**Outline:**

1.  **Libraries & Interfaces:**
    *   `Ownable`: For administrative access control (OpenZeppelin).
    *   `Pausable`: For emergency pausing functionality (OpenZeppelin).
    *   `ReentrancyGuard`: For reentrancy attack prevention (OpenZeppelin).
    *   `ERC721`: Base for the Soulbound Knowledge Shards, extended to be non-transferable (OpenZeppelin).
    *   `Counters`: For generating unique IDs (OpenZeppelin).
    *   `Strings`: For utility in dynamic metadata generation (OpenZeppelin).
    *   `Base64`: A utility library for encoding dynamic metadata (custom, derived from OpenZeppelin examples).
    *   `ILookupAIOracle`: A custom interface for the simulated AI Oracle contract.

2.  **State Variables:**
    *   Platform configuration: `aiOracleAddress`, `platformFeePercent`, `accumulatedFees`.
    *   Reputation system: `contributorReputation` (mapping), `INITIAL_REPUTATION`, `MIN_REPUTATION_FOR_REVIEW`, `REPUTATION_DECAY_RATE`, `REPUTATION_DECAY_INTERVAL`, `lastReputationDecay`.
    *   Project management: `_projectIds` (counter), `projects` (mapping of `projectId` to `Project` struct).
    *   Peer review & disputes: `_reviewIds` (counter), `reviews` (mapping), `projectReviewers` (mapping), `_repProposalIds` (counter), `reputationProposals` (mapping), `MIN_REPUTATION_FOR_PROPOSAL`, `REPUTATION_PROPOSAL_VOTE_PERIOD`.
    *   Knowledge Shards (SBT-NFTs): `_tokenIds` (counter for NFTs), `_shardToProject` (mapping for linked project), `_shardAchievementType` (mapping for achievement description), `_baseTokenURI` (for NFT image).

3.  **Events:** To signal important state changes on-chain (e.g., `ProjectProposalSubmitted`, `KnowledgeShardMinted`, `ContributorReputationUpdated`).

4.  **Enums & Structs:**
    *   `ProjectStatus`: Defines the lifecycle stages of a project.
    *   `MilestoneStatus`: Defines the states of project milestones.
    *   `Project`: Stores comprehensive details for each initiative.
    *   `Milestone`: Details for each stage of a project.
    *   `Review`: Captures peer review information.
    *   `ReputationProposal`: Stores details for proposed reputation adjustments.

5.  **Functions Categories:**
    *   **I. Core Platform Management & Configuration:** Setup, fees, pausing.
    *   **II. Contributor Reputation Management (SBT-like):** Querying, proposing, voting on, updating, and decaying reputation.
    *   **III. Project Lifecycle Management:** Submission, funding, milestone completion, and approval.
    *   **IV. AI Oracle Integration (Simulated):** Setting AI scores, retrieving scores, requesting AI suggestions.
    *   **V. Peer Review & Dispute Resolution:** Assigning reviewers, submitting reviews, disputing, and resolving disputes.
    *   **VI. Knowledge Shards (Dynamic SBT-NFTs):** Minting, dynamic metadata generation, and revocation.

---

**Function Summary:**

**I. Core Platform Management & Configuration**
1.  `constructor(address _aiOracleAddress, uint256 _initialFeePercent, string memory _baseUri)`: Initializes the contract, setting the AI Oracle address, initial platform fee, and base URI for Knowledge Shard metadata.
2.  `setAIOracleAddress(address _newOracle)`: Owner-only function to update the address of the trusted AI Oracle contract.
3.  `setPlatformFee(uint256 _newFeePercent)`: Owner-only function to adjust the platform's percentage fee on successful project funding.
4.  `withdrawPlatformFees()`: Owner-only function to withdraw accumulated platform fees to the owner's address.
5.  `togglePauseContract()`: Owner-only function to pause or unpause the contract, stopping most critical operations during emergencies or maintenance.

**II. Contributor Reputation Management (SBT-like)**
6.  `getContributorReputation(address _contributor)`: Returns the current reputation score for a specific contributor address.
7.  `proposeReputationAdjustment(address _target, int256 _adjustment, string memory _reason)`: Allows contributors with sufficient reputation to propose changes to another contributor's reputation, initiating a voting process.
8.  `voteOnReputationAdjustment(uint256 _proposalId, bool _approve)`: Contributors can vote on an active reputation adjustment proposal.
9.  `_updateReputation(address _target, int256 _delta)`: An internal utility function used to adjust a contributor's reputation score, called by various other functions based on actions.
10. `decayReputation(address _contributor)`: Allows anyone (or an automated keeper) to trigger a periodic decay of a contributor's reputation, encouraging continuous engagement.

**III. Project Lifecycle Management**
11. `submitProjectProposal(string memory _title, string memory _description, uint256 _initialFundingRequest, uint256[] memory _milestoneAmounts, string[] memory _milestoneDescriptions)`: Enables a contributor to submit a new project proposal, detailing its purpose, funding needs, and specific milestones.
12. `getProjectDetails(uint256 _projectId)`: Retrieves comprehensive data for a given project, including its status, funding, and milestones.
13. `fundProject(uint256 _projectId)`: Allows any user to contribute Ether to a project, either for initial funding or subsequent milestones.
14. `submitMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, string memory _proofHash)`: The project owner submits evidence (e.g., an IPFS hash) that a project milestone has been completed.
15. `approveMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex)`: Designated reviewers, the AI Oracle, or the contract owner can approve a completed milestone, releasing the associated funds (minus platform fees) to the project owner.

**IV. AI Oracle Integration (Simulated)**
16. `setProjectAIScore(uint256 _projectId, uint256 _score, string memory _feedbackHash)`: Callable only by the designated AI Oracle, this function sets an AI-generated score and feedback for a project, influencing its approval or rejection.
17. `getProjectAIScore(uint256 _projectId)`: Retrieves the AI score and feedback hash previously set for a specific project.
18. `requestAISuggestion(uint256 _projectId)`: Allows a project owner to request a simulated AI suggestion for their project, potentially incurring a small fee forwarded to the AI Oracle.

**V. Peer Review & Dispute Resolution**
19. `assignReviewerToProject(uint256 _projectId, address _reviewer)`: (Owner-only for this example, could be reputation-gated in a DAO) Assigns a contributor as a peer reviewer for a specific project.
20. `submitProjectReview(uint256 _projectId, bool _isPositive, string memory _feedbackHash)`: An assigned reviewer submits their evaluation of a project, impacting both their and the project owner's reputation.
21. `disputeProjectReview(uint256 _projectId, uint256 _reviewId, string memory _reasonHash)`: The project owner can formally dispute a submitted peer review, setting the project's status to disputed.
22. `resolveDispute(uint256 _reviewId, bool _upholdReview)`: (Owner-only for this example, could be high-reputation governance) Resolves a disputed review, either upholding the original review or overturning it, with reputation implications for all parties.

**VI. Knowledge Shards (Dynamic SBT-NFTs)**
23. `mintKnowledgeShard(address _recipient, uint256 _projectId, string memory _achievementType)`: Mints a new, non-transferable Knowledge Shard NFT to a recipient for significant achievements, such as successful project completion or outstanding contributions.
24. `_updateShardMetadata(uint256 _shardId)`: An internal conceptual function (the dynamism is primarily in `tokenURI`) that signifies how the metadata of a Knowledge Shard can reflect its linked project's progress or the owner's reputation.
25. `tokenURI(uint256 _shardId)`: Overrides the standard ERC721 function to return a dynamically generated Base64-encoded JSON metadata URI for a Knowledge Shard, reflecting current project status and recipient's reputation.
26. `revokeKnowledgeShard(uint256 _shardId)`: Owner-only function to burn a Knowledge Shard, typically used if the underlying achievement is discredited or proven fraudulent, resulting in a reputation penalty for the shard owner.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For `toString()` potentially in metadata

// --- Outline: Arcanum Codex Smart Contract ---
//
// Purpose: A decentralized platform for funding and curating novel research, creative works,
// and problem-solving initiatives. It integrates dynamic soulbound reputation (SBTs),
// AI-assisted project evaluation (simulated), milestone-based funding, and dynamic
// "Knowledge Shards" (NFTs) representing significant achievements.
//
// I. Libraries & Interfaces:
//    - Ownable (OpenZeppelin for access control)
//    - Pausable (OpenZeppelin for contract pause functionality)
//    - ReentrancyGuard (OpenZeppelin for security)
//    - ERC721 (OpenZeppelin for Knowledge Shards, customized for SBT nature)
//    - Counters (OpenZeppelin for ID generation)
//    - Strings (OpenZeppelin for utility in metadata generation)
//    - ILookupAIOracle (Custom interface for the simulated AI Oracle)
//
// II. State Variables:
//    - Platform settings (fee, AI oracle address).
//    - Mappings for projects (details, funding, milestones).
//    - Mappings for contributors (reputation, roles).
//    - Mappings for reviews, disputes.
//    - KnowledgeShard (ERC721) specific variables (token IDs, metadata base URI).
//
// III. Events: For important actions like project submission, funding, reputation changes,
//      shard minting, milestone updates.
//
// IV. Enums & Structs:
//    - ProjectStatus (Pending, Approved, Funding, InProgress, Completed, Rejected, Disputed).
//    - MilestoneStatus (Pending, Submitted, Approved, Released, Rejected).
//    - Project struct: Stores project details, owner, funding, milestones.
//    - Milestone struct: Details for each project milestone.
//    - Review struct: Details for project reviews.
//    - ReputationProposal struct: Details for proposed reputation adjustments.
//
// V. Functions Categories:
//    - I. Core Platform Management & Configuration
//    - II. Contributor Reputation Management (SBT-like)
//    - III. Project Lifecycle Management
//    - IV. AI Oracle Integration (Simulated)
//    - V. Peer Review & Dispute Resolution
//    - VI. Knowledge Shards (Dynamic SBT-NFTs)
//
// --- Function Summary: ---
//
// I. Core Platform Management & Configuration
// 1.  constructor(address _aiOracleAddress, uint256 _initialFeePercent, string memory _baseUri): Initializes the contract, sets the AI Oracle address, and initial platform fee.
// 2.  setAIOracleAddress(address _newOracle): Owner function to update the trusted AI Oracle contract address.
// 3.  setPlatformFee(uint256 _newFeePercent): Owner function to update the platform's percentage fee on successful project funding.
// 4.  withdrawPlatformFees(): Owner function to withdraw accumulated platform fees.
// 5.  togglePauseContract(): Owner function to pause or unpause the contract in emergencies or for upgrades.
//
// II. Contributor Reputation Management (SBT-like)
// 6.  getContributorReputation(address _contributor): Returns the current reputation score of a given contributor.
// 7.  proposeReputationAdjustment(address _target, int256 _adjustment, string memory _reason): Allows high-reputation contributors to propose reputation changes for others, requiring a vote.
// 8.  voteOnReputationAdjustment(uint256 _proposalId, bool _approve): Contributors vote on proposed reputation adjustments.
// 9.  _updateReputation(address _target, int256 _delta): Internal function to adjust a contributor's reputation score (e.g., for successful projects, good reviews, or penalties).
// 10. decayReputation(address _contributor): A function that can be called (e.g., by a keeper) to gradually reduce a contributor's reputation over time if inactive or scores are old, encouraging continuous engagement.
//
// III. Project Lifecycle Management
// 11. submitProjectProposal(string memory _title, string memory _description, uint256 _initialFundingRequest, uint256[] memory _milestoneAmounts, string[] memory _milestoneDescriptions): Allows a contributor to submit a new project proposal with funding requirements and detailed milestones.
// 12. getProjectDetails(uint256 _projectId): Retrieves comprehensive details about a specific project.
// 13. fundProject(uint256 _projectId): Contributors can send Ether to fund a project, either for initial funding or a specific milestone.
// 14. submitMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, string memory _proofHash): Project owner submits proof that a milestone has been completed.
// 15. approveMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex): High-reputation reviewers or the AI Oracle can approve a submitted milestone, releasing the associated funds.
//
// IV. AI Oracle Integration (Simulated)
// 16. setProjectAIScore(uint256 _projectId, uint256 _score, string memory _feedbackHash): Callable only by the designated `aiOracleAddress`, sets an AI-generated score and feedback hash for a project.
// 17. getProjectAIScore(uint256 _projectId): Retrieves the AI score and feedback hash for a specific project.
// 18. requestAISuggestion(uint256 _projectId): A project owner can request a simulated AI suggestion for their project, potentially incurring a small fee. (This function simulates an interaction with an external AI service).
//
// V. Peer Review & Dispute Resolution
// 19. assignReviewerToProject(uint256 _projectId, address _reviewer): (Admin/HighRep) Assigns a contributor as a peer reviewer for a project.
// 20. submitProjectReview(uint256 _projectId, bool _isPositive, string memory _feedbackHash): An assigned reviewer submits their evaluation of a project.
// 21. disputeProjectReview(uint256 _projectId, uint256 _reviewId, string memory _reasonHash): A project owner can dispute a submitted review.
// 22. resolveDispute(uint256 _reviewId, bool _upholdReview): High-reputation members or the contract owner can resolve a review dispute.
//
// VI. Knowledge Shards (Dynamic SBT-NFTs)
// 23. mintKnowledgeShard(address _recipient, uint256 _projectId, string memory _achievementType): Mints a new Knowledge Shard (SBT-NFT) to a recipient for achieving a significant milestone or contribution.
// 24. _updateShardMetadata(uint256 _shardId): Internal function called to dynamically update the metadata URI of a Knowledge Shard based on linked project progress or contributor reputation. (Conceptual, handled by tokenURI)
// 25. tokenURI(uint256 _shardId): Returns the dynamic metadata URI for a given Knowledge Shard, compliant with ERC721 metadata standard.
// 26. revokeKnowledgeShard(uint256 _shardId): Callable by the owner or highly-reputed governance, to burn a Knowledge Shard if the underlying achievement is discredited or proven fraudulent.
//
// ---------------------------------------------

// Interface for the simulated AI Oracle
interface ILookupAIOracle {
    // This function would be called by the ArcanumCodex contract to request a suggestion.
    // The AI Oracle would then process it and might call back ArcanumCodex with setProjectAIScore.
    function requestSuggestion(uint256 _projectId) external payable;
}

contract ArcanumCodex is Ownable, Pausable, ReentrancyGuard, ERC721 {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Platform Configuration
    address public aiOracleAddress;
    uint256 public platformFeePercent; // Percentage fee (e.g., 500 for 5% -> 500/10000)
    uint256 public constant MAX_PLATFORM_FEE = 1000; // 10% max fee
    uint256 public accumulatedFees; // Ether accumulated from fees

    // Reputation
    mapping(address => int256) public contributorReputation; // SBT-like score
    uint256 public constant INITIAL_REPUTATION = 1000;
    uint256 public constant MIN_REPUTATION_FOR_REVIEW = 500;
    uint256 public constant REPUTATION_DECAY_RATE = 100; // 10% decay per interval (100/1000)
    uint256 public constant REPUTATION_DECAY_INTERVAL = 30 days; // How often decay can be applied
    mapping(address => uint256) public lastReputationDecay;

    // Project Management
    Counters.Counter private _projectIds;
    enum ProjectStatus { PendingApproval, Approved, Funding, InProgress, Completed, Rejected, Disputed }
    enum MilestoneStatus { Pending, Submitted, Approved, Released, Rejected }

    struct Milestone {
        uint256 amount;
        string description;
        MilestoneStatus status;
        string proofHash; // Hash of external proof (e.g., IPFS CID)
        uint256 fundsReleasedAt;
    }

    struct Project {
        address owner;
        string title;
        string description;
        uint256 initialFundingRequest;
        uint256 currentFunding; // Total funded so far
        uint256 fundsWithdrawn; // Total withdrawn by owner for milestones
        ProjectStatus status;
        Milestone[] milestones;
        uint256 submittedAt;
        uint256 aiScore; // AI generated score
        string aiFeedbackHash;
        mapping(address => bool) hasReviewed; // To track if a reviewer has submitted a review
        mapping(address => bool) isReviewer; // To track assigned reviewers
    }
    mapping(uint256 => Project) public projects;

    // Peer Review & Disputes
    Counters.Counter private _reviewIds;
    struct Review {
        uint256 projectId;
        address reviewer;
        bool isPositive;
        string feedbackHash;
        uint256 submittedAt;
        bool disputed;
        bool upheld; // If dispute resolution upheld the review
    }
    mapping(uint256 => Review) public reviews; // Maps reviewId to Review struct
    mapping(uint256 => mapping(address => uint256)) public projectReviewers; // project ID => reviewer => review ID

    // Reputation Adjustment Proposals
    Counters.Counter private _repProposalIds;
    struct ReputationProposal {
        address proposer;
        address target;
        int256 adjustment;
        string reason;
        uint256 submittedAt;
        mapping(address => bool) hasVoted;
        uint256 votesFor;
        uint256 votesAgainst;
        bool resolved;
        bool approved;
    }
    mapping(uint256 => ReputationProposal) public reputationProposals;
    uint256 public constant MIN_REPUTATION_FOR_PROPOSAL = 1500;
    uint256 public constant REPUTATION_PROPOSAL_VOTE_PERIOD = 7 days; // Voting period

    // Knowledge Shards (Dynamic SBT-NFTs)
    Counters.Counter private _tokenIds; // For ERC721 token IDs
    mapping(uint256 => uint256) private _shardToProject; // Shard ID to Project ID
    mapping(uint256 => string) private _shardAchievementType; // Shard ID to achievement description
    string private _baseTokenURI; // Base URI for metadata images

    // --- Events ---
    event AIOracleAddressUpdated(address indexed newOracle);
    event PlatformFeeUpdated(uint256 newFeePercent);
    event PlatformFeesWithdrawn(address indexed to, uint256 amount);
    event ContributorReputationUpdated(address indexed contributor, int256 newReputation);
    event ReputationAdjustmentProposed(uint256 indexed proposalId, address indexed target, int256 adjustment, string reason);
    event ReputationAdjustmentVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event ReputationAdjustmentResolved(uint256 indexed proposalId, bool approved);
    event ProjectProposalSubmitted(uint256 indexed projectId, address indexed owner, string title);
    event ProjectStatusUpdated(uint256 indexed projectId, ProjectStatus newStatus);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event MilestoneSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, string proofHash);
    event MilestoneApproved(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed approver);
    event ProjectAIScoreUpdated(uint256 indexed projectId, uint256 score, string feedbackHash);
    event AISuggestionRequested(uint256 indexed projectId, address indexed requester);
    event ReviewerAssigned(uint256 indexed projectId, address indexed reviewer);
    event ProjectReviewed(uint256 indexed projectId, uint256 indexed reviewId, address indexed reviewer, bool isPositive);
    event ReviewDisputed(uint256 indexed projectId, uint256 indexed reviewId, address indexed disputer);
    event DisputeResolved(uint256 indexed reviewId, bool upheldReview);
    event KnowledgeShardMinted(uint256 indexed shardId, address indexed recipient, uint256 indexed projectId, string achievementType);
    event KnowledgeShardRevoked(uint256 indexed shardId, address indexed revoker);

    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "ArcanumCodex: Caller is not the AI Oracle");
        _;
    }

    modifier onlyProjectOwner(uint256 _projectId) {
        require(projects[_projectId].owner == msg.sender, "ArcanumCodex: Only project owner can call this");
        _;
    }

    modifier onlyHighReputation() {
        require(contributorReputation[msg.sender] >= int256(MIN_REPUTATION_FOR_REVIEW), "ArcanumCodex: Insufficient reputation");
        _;
    }

    modifier onlySuperHighReputation() {
        require(contributorReputation[msg.sender] >= int256(MIN_REPUTATION_FOR_PROPOSAL), "ArcanumCodex: Insufficient reputation for this action");
        _;
    }

    // --- Constructor ---
    constructor(address _aiOracleAddress, uint256 _initialFeePercent, string memory _baseUri)
        ERC721("KnowledgeShard", "KSHARD")
        Ownable(msg.sender)
    {
        require(_initialFeePercent <= MAX_PLATFORM_FEE, "ArcanumCodex: Initial fee too high");
        require(_aiOracleAddress != address(0), "ArcanumCodex: AI Oracle address cannot be zero");

        aiOracleAddress = _aiOracleAddress;
        platformFeePercent = _initialFeePercent;
        _baseTokenURI = _baseUri;
    }

    // Override `_beforeTokenTransfer` to enforce Soulbound nature
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Allow minting (from address(0)) and burning (to address(0))
        // Disallow all other transfers
        if (from != address(0) && to != address(0)) {
            revert("KnowledgeShard: This token is soulbound and cannot be transferred");
        }
    }

    // --- I. Core Platform Management & Configuration ---

    function setAIOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "ArcanumCodex: AI Oracle cannot be zero address");
        aiOracleAddress = _newOracle;
        emit AIOracleAddressUpdated(_newOracle);
    }

    function setPlatformFee(uint256 _newFeePercent) public onlyOwner {
        require(_newFeePercent <= MAX_PLATFORM_FEE, "ArcanumCodex: Fee percentage exceeds max allowed");
        platformFeePercent = _newFeePercent;
        emit PlatformFeeUpdated(_newFeePercent);
    }

    function withdrawPlatformFees() public onlyOwner nonReentrant {
        uint256 amount = accumulatedFees;
        accumulatedFees = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ArcanumCodex: Fee withdrawal failed");
        emit PlatformFeesWithdrawn(msg.sender, amount);
    }

    function togglePauseContract() public onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    // --- II. Contributor Reputation Management (SBT-like) ---

    function getContributorReputation(address _contributor) public view returns (int256) {
        return contributorReputation[_contributor];
    }

    function proposeReputationAdjustment(address _target, int256 _adjustment, string memory _reason)
        public
        whenNotPaused
        onlySuperHighReputation
        returns (uint256 proposalId)
    {
        require(_target != address(0), "ArcanumCodex: Target cannot be zero address");
        require(contributorReputation[_target] != 0, "ArcanumCodex: Target must be an active contributor");
        require(_adjustment != 0, "ArcanumCodex: Adjustment cannot be zero");
        require(_target != msg.sender, "ArcanumCodex: Cannot propose adjustment for self");


        proposalId = _repProposalIds.increment();
        reputationProposals[proposalId] = ReputationProposal({
            proposer: msg.sender,
            target: _target,
            adjustment: _adjustment,
            reason: _reason,
            submittedAt: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
            resolved: false,
            approved: false
        });
        emit ReputationAdjustmentProposed(proposalId, _target, _adjustment, _reason);
        return proposalId;
    }

    function voteOnReputationAdjustment(uint256 _proposalId, bool _approve)
        public
        whenNotPaused
        onlyHighReputation
    {
        ReputationProposal storage proposal = reputationProposals[_proposalId];
        require(proposal.proposer != address(0), "ArcanumCodex: Invalid proposal ID"); // Check if proposal exists
        require(!proposal.resolved, "ArcanumCodex: Proposal already resolved");
        require(block.timestamp < proposal.submittedAt + REPUTATION_PROPOSAL_VOTE_PERIOD, "ArcanumCodex: Voting period ended");
        require(!proposal.hasVoted[msg.sender], "ArcanumCodex: Already voted on this proposal");
        require(msg.sender != proposal.proposer, "ArcanumCodex: Proposer cannot vote on their own proposal");
        require(msg.sender != proposal.target, "ArcanumCodex: Target cannot vote on their own proposal");

        proposal.hasVoted[msg.sender] = true;
        if (_approve) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit ReputationAdjustmentVoted(_proposalId, msg.sender, _approve);

        // Simple resolution logic: If minimum 3 total votes and a majority, resolve.
        // This can be made more complex with dynamic quorum based on total active voters or stake.
        if (proposal.votesFor + proposal.votesAgainst >= 3) { // Minimum 3 votes to consider resolving
            proposal.resolved = true;
            if (proposal.votesFor > proposal.votesAgainst) {
                proposal.approved = true;
                _updateReputation(proposal.target, proposal.adjustment);
            } else {
                proposal.approved = false; // Explicitly mark as not approved
            }
            emit ReputationAdjustmentResolved(_proposalId, proposal.approved);
        }
    }

    function _updateReputation(address _target, int256 _delta) internal {
        // Initialize reputation if it's the first activity
        if (contributorReputation[_target] == 0 && _delta > 0) {
            contributorReputation[_target] = int256(INITIAL_REPUTATION);
        }

        int256 newRep = contributorReputation[_target] + _delta;
        if (newRep < 0) newRep = 0; // Reputation cannot go below zero.
        contributorReputation[_target] = newRep;

        emit ContributorReputationUpdated(_target, newRep);
    }

    function decayReputation(address _contributor) public whenNotPaused {
        require(contributorReputation[_contributor] > int256(INITIAL_REPUTATION), "ArcanumCodex: Reputation too low to decay below initial");
        require(block.timestamp >= lastReputationDecay[_contributor] + REPUTATION_DECAY_INTERVAL, "ArcanumCodex: Too soon to decay reputation");

        int256 currentRep = contributorReputation[_contributor];
        int256 decayAmount = (currentRep * int256(REPUTATION_DECAY_RATE)) / 1000; // e.g., 100/1000 = 10%
        if (decayAmount == 0) decayAmount = 1; // At least 1 point decay

        // Don't decay below initial reputation
        if (currentRep - decayAmount < int256(INITIAL_REPUTATION)) {
            decayAmount = currentRep - int256(INITIAL_REPUTATION);
        }
        _updateReputation(_contributor, -decayAmount);
        lastReputationDecay[_contributor] = block.timestamp;
    }

    // --- III. Project Lifecycle Management ---

    function submitProjectProposal(
        string memory _title,
        string memory _description,
        uint256 _initialFundingRequest,
        uint256[] memory _milestoneAmounts,
        string[] memory _milestoneDescriptions
    ) public whenNotPaused nonReentrant returns (uint256 projectId) {
        require(bytes(_title).length > 0, "ArcanumCodex: Title cannot be empty");
        require(bytes(_description).length > 0, "ArcanumCodex: Description cannot be empty");
        require(_initialFundingRequest > 0, "ArcanumCodex: Initial funding request must be positive");
        require(_milestoneAmounts.length == _milestoneDescriptions.length, "ArcanumCodex: Milestone arrays must match in length");
        require(_milestoneAmounts.length > 0, "ArcanumCodex: At least one milestone is required");

        projectId = _projectIds.increment();
        Project storage newProject = projects[projectId];
        newProject.owner = msg.sender;
        newProject.title = _title;
        newProject.description = _description;
        newProject.initialFundingRequest = _initialFundingRequest;
        newProject.status = ProjectStatus.PendingApproval;
        newProject.submittedAt = block.timestamp;

        for (uint256 i = 0; i < _milestoneAmounts.length; i++) {
            require(_milestoneAmounts[i] > 0, "ArcanumCodex: Milestone amount must be positive");
            require(bytes(_milestoneDescriptions[i]).length > 0, "ArcanumCodex: Milestone description cannot be empty");
            newProject.milestones.push(Milestone({
                amount: _milestoneAmounts[i],
                description: _milestoneDescriptions[i],
                status: MilestoneStatus.Pending,
                proofHash: "",
                fundsReleasedAt: 0
            }));
        }

        _updateReputation(msg.sender, 50); // Small rep boost for submitting
        emit ProjectProposalSubmitted(projectId, msg.sender, _title);
        return projectId;
    }

    function getProjectDetails(uint256 _projectId)
        public
        view
        returns (
            address owner,
            string memory title,
            string memory description,
            uint256 initialFundingRequest,
            uint256 currentFunding,
            uint256 fundsWithdrawn,
            ProjectStatus status,
            Milestone[] memory milestones,
            uint256 submittedAt,
            uint256 aiScore,
            string memory aiFeedbackHash
        )
    {
        Project storage p = projects[_projectId];
        require(p.owner != address(0), "ArcanumCodex: Project does not exist");
        return (
            p.owner,
            p.title,
            p.description,
            p.initialFundingRequest,
            p.currentFunding,
            p.fundsWithdrawn,
            p.status,
            p.milestones,
            p.submittedAt,
            p.aiScore,
            p.aiFeedbackHash
        );
    }

    function fundProject(uint256 _projectId) public payable whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        require(project.owner != address(0), "ArcanumCodex: Project does not exist");
        require(project.status == ProjectStatus.Approved || project.status == ProjectStatus.Funding || project.status == ProjectStatus.InProgress, "ArcanumCodex: Project not open for funding");
        require(msg.value > 0, "ArcanumCodex: Must send Ether to fund project");

        project.currentFunding += msg.value;

        // Transition status if enough initial funding is received
        if (project.status == ProjectStatus.Approved && project.currentFunding >= project.initialFundingRequest) {
            project.status = ProjectStatus.InProgress;
            emit ProjectStatusUpdated(_projectId, ProjectStatus.InProgress);
            _updateReputation(project.owner, 100); // Rep boost for project owner on reaching initial funding
        } else if (project.status == ProjectStatus.Approved) {
            project.status = ProjectStatus.Funding;
            emit ProjectStatusUpdated(_projectId, ProjectStatus.Funding);
        }

        _updateReputation(msg.sender, 25); // Rep boost for funder
        emit ProjectFunded(_projectId, msg.sender, msg.value);
    }

    function submitMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, string memory _proofHash)
        public
        whenNotPaused
        onlyProjectOwner(_projectId)
    {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.InProgress, "ArcanumCodex: Project not in progress");
        require(_milestoneIndex < project.milestones.length, "ArcanumCodex: Invalid milestone index");
        require(project.milestones[_milestoneIndex].status == MilestoneStatus.Pending, "ArcanumCodex: Milestone not pending");
        require(bytes(_proofHash).length > 0, "ArcanumCodex: Proof hash cannot be empty");

        project.milestones[_milestoneIndex].status = MilestoneStatus.Submitted;
        project.milestones[_milestoneIndex].proofHash = _proofHash;
        emit MilestoneSubmitted(_projectId, _milestoneIndex, _proofHash);
    }

    function approveMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex) public whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        require(project.owner != address(0), "ArcanumCodex: Project does not exist");
        require(msg.sender == owner() || msg.sender == aiOracleAddress || project.isReviewer[msg.sender],
            "ArcanumCodex: Only owner, AI Oracle, or assigned reviewer can approve milestone");
        require(_milestoneIndex < project.milestones.length, "ArcanumCodex: Invalid milestone index");
        require(project.milestones[_milestoneIndex].status == MilestoneStatus.Submitted, "ArcanumCodex: Milestone not in submitted state");
        require(project.currentFunding >= (project.milestones[_milestoneIndex].amount + project.fundsWithdrawn), "ArcanumCodex: Insufficient project funds for milestone payout");

        project.milestones[_milestoneIndex].status = MilestoneStatus.Approved;
        project.milestones[_milestoneIndex].fundsReleasedAt = block.timestamp;
        
        uint256 payoutAmount = project.milestones[_milestoneIndex].amount;
        uint256 fee = (payoutAmount * platformFeePercent) / 10000; // Apply fee, 10000 = 100%
        uint256 netPayout = payoutAmount - fee;
        accumulatedFees += fee;

        project.fundsWithdrawn += payoutAmount; // Track total payout including fee

        (bool success, ) = payable(project.owner).call{value: netPayout}("");
        require(success, "ArcanumCodex: Milestone payout failed");

        emit MilestoneApproved(_projectId, _milestoneIndex, msg.sender);
        _updateReputation(project.owner, 75); // Rep boost for owner
        _updateReputation(msg.sender, 30); // Rep boost for approver

        // Check if all milestones completed
        bool allMilestonesCompleted = true;
        for (uint256 i = 0; i < project.milestones.length; i++) {
            if (project.milestones[i].status != MilestoneStatus.Approved && project.milestones[i].status != MilestoneStatus.Released) {
                allMilestonesCompleted = false;
                break;
            }
        }
        if (allMilestonesCompleted) {
            project.status = ProjectStatus.Completed;
            emit ProjectStatusUpdated(_projectId, ProjectStatus.Completed);
            _updateReputation(project.owner, 200); // Big rep boost for completing project
            mintKnowledgeShard(project.owner, _projectId, "ProjectCompletion");
        }
    }


    // --- IV. AI Oracle Integration (Simulated) ---

    function setProjectAIScore(uint256 _projectId, uint256 _score, string memory _feedbackHash)
        public
        whenNotPaused
        onlyAIOracle
    {
        Project storage project = projects[_projectId];
        require(project.owner != address(0), "ArcanumCodex: Project does not exist");
        require(project.status == ProjectStatus.PendingApproval, "ArcanumCodex: AI score can only be set for pending projects");

        project.aiScore = _score;
        project.aiFeedbackHash = _feedbackHash;

        // Auto-approve projects with high AI score (Example threshold)
        if (_score >= 70) {
            project.status = ProjectStatus.Approved;
            emit ProjectStatusUpdated(_projectId, ProjectStatus.Approved);
            _updateReputation(project.owner, 100); // Rep boost for project owner on AI approval
        } else if (_score < 30) { // Example rejection threshold
            project.status = ProjectStatus.Rejected;
            emit ProjectStatusUpdated(_projectId, ProjectStatus.Rejected);
            _updateReputation(project.owner, -50); // Rep penalty for poor AI score
        }

        emit ProjectAIScoreUpdated(_projectId, _score, _feedbackHash);
    }

    function getProjectAIScore(uint256 _projectId) public view returns (uint256 score, string memory feedbackHash) {
        Project storage project = projects[_projectId];
        require(project.owner != address(0), "ArcanumCodex: Project does not exist");
        return (project.aiScore, project.aiFeedbackHash);
    }

    function requestAISuggestion(uint256 _projectId) public payable whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.owner != address(0), "ArcanumCodex: Project does not exist");
        // Simulate a small fee for AI interaction
        require(msg.value >= 0.001 ether, "ArcanumCodex: Insufficient ETH for AI suggestion request fee");

        // Forward the payment to the AI Oracle for processing
        // The AI Oracle contract is expected to implement ILookupAIOracle.
        ILookupAIOracle(aiOracleAddress).requestSuggestion{value: msg.value}(_projectId);

        emit AISuggestionRequested(_projectId, msg.sender);
    }


    // --- V. Peer Review & Dispute Resolution ---

    function assignReviewerToProject(uint256 _projectId, address _reviewer) public onlyOwner whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.owner != address(0), "ArcanumCodex: Project does not exist");
        require(contributorReputation[_reviewer] >= int256(MIN_REPUTATION_FOR_REVIEW), "ArcanumCodex: Reviewer has insufficient reputation");
        require(!project.isReviewer[_reviewer], "ArcanumCodex: Reviewer already assigned");

        project.isReviewer[_reviewer] = true;
        emit ReviewerAssigned(_projectId, _reviewer);
    }

    function submitProjectReview(uint256 _projectId, bool _isPositive, string memory _feedbackHash)
        public
        whenNotPaused
        onlyHighReputation
    {
        Project storage project = projects[_projectId];
        require(project.owner != address(0), "ArcanumCodex: Project does not exist");
        require(project.isReviewer[msg.sender], "ArcanumCodex: Caller is not an assigned reviewer for this project");
        require(!project.hasReviewed[msg.sender], "ArcanumCodex: Reviewer has already submitted a review for this project");
        require(project.status == ProjectStatus.Approved || project.status == ProjectStatus.Funding || project.status == ProjectStatus.InProgress, "ArcanumCodex: Project not in reviewable status");

        uint256 reviewId = _reviewIds.increment();
        reviews[reviewId] = Review({
            projectId: _projectId,
            reviewer: msg.sender,
            isPositive: _isPositive,
            feedbackHash: _feedbackHash,
            submittedAt: block.timestamp,
            disputed: false,
            upheld: false
        });
        projectReviewers[_projectId][msg.sender] = reviewId;
        project.hasReviewed[msg.sender] = true;

        if (_isPositive) {
            _updateReputation(msg.sender, 20); // Rep boost for positive review
            _updateReputation(project.owner, 10); // Small boost for project owner
        } else {
            _updateReputation(msg.sender, 5); // Smaller boost for negative (constructive) review
            _updateReputation(project.owner, -10); // Small penalty for project owner
        }
        emit ProjectReviewed(_projectId, reviewId, msg.sender, _isPositive);
    }

    function disputeProjectReview(uint256 _projectId, uint256 _reviewId, string memory _reasonHash)
        public
        whenNotPaused
        onlyProjectOwner(_projectId)
    {
        Review storage review = reviews[_reviewId];
        require(review.projectId == _projectId, "ArcanumCodex: Review ID does not match project");
        require(!review.disputed, "ArcanumCodex: Review already disputed");
        require(bytes(_reasonHash).length > 0, "ArcanumCodex: Reason hash cannot be empty");

        review.disputed = true;
        projects[_projectId].status = ProjectStatus.Disputed; // Project enters disputed state
        emit ReviewDisputed(_projectId, _reviewId, msg.sender);
    }

    function resolveDispute(uint256 _reviewId, bool _upholdReview) public onlyOwner whenNotPaused {
        Review storage review = reviews[_reviewId];
        require(review.reviewer != address(0), "ArcanumCodex: Invalid review ID");
        require(review.disputed, "ArcanumCodex: Review is not currently disputed");

        review.disputed = false;
        review.upheld = _upholdReview;

        Project storage project = projects[review.projectId];
        // Return to in-progress only if it was previously InProgress or similar.
        // If it was Approved or Funding, it should revert to that.
        // For simplicity, let's assume it returns to Approved or InProgress.
        if (project.status == ProjectStatus.Disputed) {
            project.status = ProjectStatus.InProgress;
            emit ProjectStatusUpdated(review.projectId, ProjectStatus.InProgress);
        }

        if (_upholdReview) { // If the original review stands
            _updateReputation(review.reviewer, 50); // Reward reviewer for good review
            _updateReputation(project.owner, -20); // Small penalty for frivolous dispute
        } else { // If the original review is overturned
            _updateReputation(review.reviewer, -50); // Penalty for poor review
            _updateReputation(project.owner, 20); // Reward owner for successful dispute
        }
        emit DisputeResolved(_reviewId, _upholdReview);
    }

    // --- VI. Knowledge Shards (Dynamic SBT-NFTs) ---
    // Inheriting ERC721, so using its functions directly.

    function mintKnowledgeShard(address _recipient, uint256 _projectId, string memory _achievementType)
        public
        whenNotPaused
        onlyOwner // Only owner or contract logic (which calls onlyOwner) can mint
        returns (uint256 shardId)
    {
        require(_recipient != address(0), "ArcanumCodex: Cannot mint to zero address");
        
        shardId = _tokenIds.increment();
        _safeMint(_recipient, shardId);
        _updateShardMetadata(shardId); // Initialize metadata conceptually

        // Link shard to project for dynamic metadata
        _shardToProject[shardId] = _projectId;
        _shardAchievementType[shardId] = _achievementType;
        
        emit KnowledgeShardMinted(shardId, _recipient, _projectId, _achievementType);
        _updateReputation(_recipient, 150); // Significant rep boost for receiving a shard
        return shardId;
    }

    // This function is internal and view as the dynamic metadata is generated on the fly by tokenURI.
    // It's a conceptual placeholder.
    function _updateShardMetadata(uint256 _shardId) internal view {
        // This function would conceptually trigger an update if metadata were stored externally (e.g., IPFS).
        // For on-chain dynamic metadata (as implemented in tokenURI), no direct state update is needed here.
    }

    function tokenURI(uint256 _shardId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(_shardId), "ERC721Metadata: URI query for nonexistent token");

        uint256 projectId = _shardToProject[_shardId];
        string memory achievementType = _shardAchievementType[_shardId];
        address owner = ownerOf(_shardId);
        int256 ownerReputation = contributorReputation[owner];

        string memory projectTitle = "";
        ProjectStatus projectStatus = ProjectStatus.PendingApproval; // Default
        if (projectId != 0 && projects[projectId].owner != address(0)) {
            projectTitle = projects[projectId].title;
            projectStatus = projects[projectId].status;
        }

        // Generate dynamic JSON metadata string
        string memory json = string(abi.encodePacked(
            '{"name": "Knowledge Shard #', Strings.toString(_shardId),
            '", "description": "A soulbound token representing an achievement in the Arcanum Codex.",',
            '"image": "', _baseTokenURI, Strings.toString(_shardId), '.png",', // Placeholder image, could be dynamic based on achievement type
            '"attributes": [',
                '{"trait_type": "Achievement Type", "value": "', achievementType, '"},',
                '{"trait_type": "Recipient Reputation", "value": ', Strings.toString(uint256(ownerReputation)), '}'
        ));

        if (projectId != 0 && bytes(projectTitle).length > 0) {
            json = string(abi.encodePacked(json, ',',
                '{"trait_type": "Linked Project ID", "value": ', Strings.toString(projectId), '},',
                '{"trait_type": "Linked Project Title", "value": "', projectTitle, '"},',
                '{"trait_type": "Linked Project Status", "value": "', _projectStatusToString(projectStatus), '"}'
            ));
        }
        
        json = string(abi.encodePacked(json, ']}'));

        // Encode to base64
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // Helper for enum to string conversion for metadata
    function _projectStatusToString(ProjectStatus _status) internal pure returns (string memory) {
        if (_status == ProjectStatus.PendingApproval) return "Pending Approval";
        if (_status == ProjectStatus.Approved) return "Approved";
        if (_status == ProjectStatus.Funding) return "Funding";
        if (_status == ProjectStatus.InProgress) return "In Progress";
        if (_status == ProjectStatus.Completed) return "Completed";
        if (_status == ProjectStatus.Rejected) return "Rejected";
        if (_status == ProjectStatus.Disputed) return "Disputed";
        return "Unknown";
    }

    function revokeKnowledgeShard(uint256 _shardId) public onlyOwner whenNotPaused {
        require(_exists(_shardId), "ArcanumCodex: Shard does not exist");
        address shardOwner = ownerOf(_shardId);
        _burn(_shardId); // ERC721 burn function

        // Clear mappings associated with the burned shard
        delete _shardToProject[_shardId];
        delete _shardAchievementType[_shardId];

        _updateReputation(shardOwner, -200); // Significant rep penalty for having shard revoked
        emit KnowledgeShardRevoked(_shardId, msg.sender);
    }

    // Fallback and Receive functions to accept Ether
    receive() external payable whenNotPaused {}
    fallback() external payable whenNotPaused {}
}


// --- Helper Library for Base64 Encoding ---
// Adapted from OpenZeppelin's ERC721URIStorage Base64 implementation.
library Base64 {
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load not more than 3x bytes at time.
        // The cast to uint256 is not necessary, but prevents the
        // compiler from warning about the use of `data.length` in a non-storage context.
        uint256 encodedLen = (data.length + 2) / 3 * 4;
        bytes memory result = new bytes(encodedLen);

        unchecked {
            for (uint256 i = 0; i < data.length; i += 3) {
                uint256 chunk;
                if (i + 2 < data.length) {
                    chunk = (uint256(data[i]) << 16) | (uint256(data[i + 1]) << 8) | uint256(data[i + 2]);
                } else if (i + 1 < data.length) {
                    chunk = (uint256(data[i]) << 16) | (uint256(data[i + 1]) << 8);
                } else {
                    chunk = (uint256(data[i]) << 16);
                }

                if (i + 2 < data.length) {
                    result[i / 3 * 4] = bytes1(_TABLE[(chunk >> 18) & 0x3F]);
                    result[i / 3 * 4 + 1] = bytes1(_TABLE[(chunk >> 12) & 0x3F]);
                    result[i / 3 * 4 + 2] = bytes1(_TABLE[(chunk >> 6) & 0x3F]);
                    result[i / 3 * 4 + 3] = bytes1(_TABLE[chunk & 0x3F]);
                } else if (i + 1 < data.length) {
                    result[i / 3 * 4] = bytes1(_TABLE[(chunk >> 18) & 0x3F]);
                    result[i / 3 * 4 + 1] = bytes1(_TABLE[(chunk >> 12) & 0x3F]);
                    result[i / 3 * 4 + 2] = bytes1(_TABLE[(chunk >> 6) & 0x3F]);
                    result[i / 3 * 4 + 3] = '='; // Padding
                } else {
                    result[i / 3 * 4] = bytes1(_TABLE[(chunk >> 18) & 0x3F]);
                    result[i / 3 * 4 + 1] = bytes1(_TABLE[(chunk >> 12) & 0x3F]);
                    result[i / 3 * 4 + 2] = '='; // Padding
                    result[i / 3 * 4 + 3] = '='; // Padding
                }
            }
        }
        return string(result);
    }
}
```