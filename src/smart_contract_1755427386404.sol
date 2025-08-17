This smart contract, named `AetherFlowProtocols`, outlines a decentralized scholarly contribution network. It combines several advanced concepts like dynamic NFTs, Soulbound Tokens (SBTs) for reputation, AI oracle integration for content curation, and a comprehensive decentralized autonomous organization (DAO) governance model for funding and protocol parameter changes.

---

## Outline: AetherFlow Protocols

**I. Introduction & Core Concept**
AetherFlow Protocols is designed as a decentralized platform for collaborative knowledge creation and curation. It introduces "Knowledge Capsules" as dynamic NFTs representing scholarly contributions (e.g., research papers, open-source documentation, educational content). These capsules undergo a transparent lifecycle involving community peer review and AI-assisted analysis for validation. Contributors and active participants earn non-transferable "Reputation Badges" (SBTs), which in turn grant them influence over the protocol's governance and access to funding mechanisms. The overarching goal is to foster a high-quality, transparent, and community-driven knowledge base.

**II. Contract Structure & Components**

1.  **Knowledge Capsules (ERC721):**
    *   Dynamic NFTs representing individual contributions.
    *   Possess a lifecycle: `Draft`, `SubmittedForReview`, `UnderReview`, `Validated`, `Rejected`, `Deprecated`, `Funded`.
    *   Metadata and content hashes (e.g., IPFS/Arweave) are stored on-chain.

2.  **Reputation Badges (ERC721-like SBTs):**
    *   Non-transferable tokens that signify a user's expertise, reliability, and contribution to the ecosystem.
    *   Earned for specific actions (minting validated capsules, submitting insightful reviews, governance participation).
    *   Different tiers (e.g., Explorer, Curator, Innovator, Luminary) with varying weight for governance.

3.  **Peer Review System:**
    *   Allows reputable users to submit reviews and scores for Knowledge Capsules.
    *   Reviewer's reputation influences the weight of their review.
    *   Accumulated reviews contribute to a capsule's validation status.

4.  **AI Curation Oracle Integration:**
    *   The contract interfaces with an external AI oracle (via an interface) that analyzes capsule content (e.g., for originality, relevance, quality).
    *   The oracle provides scores that factor into a capsule's validation.

5.  **Funding & Grant System:**
    *   A community-governed pool where users can deposit ETH to support research or specific Knowledge Capsules.
    *   Users can propose funding for validated capsules.
    *   Proposals are voted on by the community, weighted by reputation.

6.  **Decentralized Governance:**
    *   Enables reputation-weighted voting on core protocol parameters (e.g., minting fees, validation thresholds, voting periods).
    *   Empowers the community to evolve the protocol over time.

---

## Function Summary: AetherFlow Protocols

**Knowledge Capsule Management (ERC721 & Core Logic):**

1.  `mintKnowledgeCapsule(string calldata _contentHash, string calldata _metadataURI)`: Allows users to mint a new Knowledge Capsule NFT, requiring a minting fee.
2.  `updateCapsuleContent(uint256 _capsuleId, string calldata _newContentHash, string calldata _newMetadataURI)`: Permits the capsule owner to update content and metadata if the capsule is still in `Draft` or `Rejected` status.
3.  `requestCapsuleValidation(uint256 _capsuleId)`: Initiates the formal peer review and AI curation process for a capsule.
4.  `getCapsuleDetails(uint256 _capsuleId)`: A view function to retrieve all stored details of a specific Knowledge Capsule.
5.  `getOwnerCapsules(address _owner)`: Returns an array of capsule IDs owned by a given address.
6.  `getPaginatedCapsuleList(uint256 _offset, uint256 _limit)`: Provides a paginated list of all capsule IDs for efficient querying.

**Peer Review & AI Curation:**

7.  `submitReview(uint256 _capsuleId, uint8 _score, string calldata _comment)`: Allows a user with sufficient reputation to submit a review and a score for a capsule.
8.  `requestAICuration(uint256 _capsuleId)`: (Callable by owner/protocol) Triggers a request to the configured AI oracle for analysis of the capsule's content.
9.  `callbackAICurationResult(uint256 _capsuleId, uint8 _relevanceScore, uint8 _originalityScore)`: An external function callable *only by the trusted AI oracle* to submit the results of its analysis.
10. `finalizeCapsuleStatus(uint256 _capsuleId)`: (Internal protocol function) Automatically determines and updates a capsule's status (`Validated` or `Rejected`) once review and AI thresholds are met.
11. `getCapsuleReviews(uint256 _capsuleId)`: Retrieves all individual reviews submitted for a specific capsule.
12. `getCapsuleReviewSummary(uint256 _capsuleId)`: Provides aggregated review counts and AI scores for a capsule.

**Reputation System (SBTs - Non-transferable ERC721s):**

13. `getReputationScore(address _user)`: Returns the total accumulated reputation score of a user.
14. `getUserReputationBadges(address _user)`: Returns an array of reputation badge IDs held by a user.
15. `getBadgeDetails(uint256 _badgeId)`: Retrieves detailed information about a specific reputation badge.
16. `earnReputation(address _recipient, ReputationTier _tier)`: (Admin/Internal) A function to explicitly award reputation badges based on contributions (primarily called internally by other functions like `mintKnowledgeCapsule`, `submitReview`, `voteOnParameterChange`).
17. `setReputationBadgeURI(uint256 _badgeId, string calldata _newURI)`: (Admin only) Allows updating the metadata URI for a specific reputation badge.

**Funding & Grant System:**

18. `depositFunds()`: Allows any user to deposit ETH into the collective grant pool, increasing its balance.
19. `createFundingProposal(uint256 _capsuleId, uint256 _amount, string calldata _reason)`: Enables users with sufficient reputation to propose funding for a validated Knowledge Capsule.
20. `voteOnFundingProposal(uint256 _proposalId, bool _support)`: Allows reputation-weighted voting on an active funding proposal.
21. `executeFundingProposal(uint256 _proposalId)`: Executes a successful funding proposal, transferring funds from the pool to the capsule's allocated balance.
22. `withdrawGrantedFunds(uint256 _capsuleId)`: Allows the owner of a funded capsule to withdraw the allocated ETH.
23. `getGrantPoolBalance()`: A view function to check the current total balance of the grant pool.
24. `getFundingProposalDetails(uint256 _proposalId)`: Retrieves all details about a specific funding proposal.

**Decentralized Governance & Protocol Parameters:**

25. `proposeParameterChange(ParameterType _paramType, uint256 _newValue, string calldata _description)`: Allows users with sufficient reputation to propose changes to core protocol parameters.
26. `voteOnParameterChange(uint256 _proposalId, bool _support)`: Allows reputation-weighted voting on an active governance proposal.
27. `executeParameterChange(uint256 _proposalId)`: Executes an approved governance proposal, applying the proposed parameter change to the contract.
28. `getProtocolParameters()`: A view function to retrieve the current values of all key configurable protocol parameters.
29. `setAIOracleAddress(address _newOracle)`: (Admin only) Sets or updates the address of the trusted AI oracle contract.
30. `setGovernanceParameters(uint256 _minReputationToProposeFunding, uint256 _fundingVotingPeriod, uint256 _minVotesForFundingSuccess, uint256 _minReputationToProposeGovernance, uint256 _governanceVotingPeriod, uint256 _minVotesForGovernanceSuccess)`: (Admin only) Allows the contract owner to set initial or emergency adjustments to governance-related thresholds and periods. This function is intended to be phased out as the DAO matures.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline:
// I. Introduction & Core Concept
//    AetherFlow Protocols is a decentralized scholarly contribution network. It enables the creation,
//    peer-review, AI-assisted curation, and community funding of "Knowledge Capsules" (NFTs).
//    Contributors earn non-transferable "Reputation Badges" (SBTs) for their valuable
//    contributions and participation, influencing their governance power and privileges.
//    The protocol aims to foster a high-quality, transparent, and community-driven knowledge base.

// II. Contract Structure & Components
//    1. Knowledge Capsules (ERC721): Represents scholarly contributions, with dynamic metadata and lifecycle.
//    2. Reputation Badges (ERC721-like SBTs): Non-transferable tokens representing a user's expertise and contribution.
//    3. Peer Review System: Allows users to review capsules, with weighted influence based on reputation.
//    4. AI Curation Oracle Integration: Connects to an external AI oracle for automated content analysis.
//    5. Funding & Grant System: Community-governed pool for supporting promising capsules or research.
//    6. Decentralized Governance: Allows reputation-weighted voting on protocol parameters and funding.

// Function Summary:

// Knowledge Capsule Management (ERC721 & Core Logic):
// 1.  mintKnowledgeCapsule(string calldata _contentHash, string calldata _metadataURI): Mints a new Knowledge Capsule NFT.
// 2.  updateCapsuleContent(uint256 _capsuleId, string calldata _newContentHash, string calldata _newMetadataURI): Allows owner to update capsule content if not finalized.
// 3.  requestCapsuleValidation(uint256 _capsuleId): Initiates the peer review and AI curation process for a capsule.
// 4.  getCapsuleDetails(uint256 _capsuleId): Retrieves detailed information about a specific Knowledge Capsule.
// 5.  getOwnerCapsules(address _owner): Returns an array of capsule IDs owned by a specific address.
// 6.  getPaginatedCapsuleList(uint256 _offset, uint256 _limit): Retrieves a paginated list of all capsule IDs.

// Peer Review & AI Curation:
// 7.  submitReview(uint256 _capsuleId, uint8 _score, string calldata _comment): Allows a user to submit a review for a capsule.
// 8.  requestAICuration(uint256 _capsuleId): (Internal/Admin/Scheduled) Triggers a request to the AI oracle for analysis.
// 9.  callbackAICurationResult(uint256 _capsuleId, uint8 _relevanceScore, uint8 _originalityScore): Called by the designated AI oracle to submit analysis results.
// 10. finalizeCapsuleStatus(uint256 _capsuleId): Admin/Protocol method to transition a capsule's status based on review and AI scores.
// 11. getCapsuleReviews(uint256 _capsuleId): Retrieves all reviews submitted for a specific capsule.
// 12. getCapsuleReviewSummary(uint256 _capsuleId): Provides aggregated review scores and counts for a capsule.

// Reputation System (SBTs - Non-transferable ERC721s):
// 13. getReputationScore(address _user): Returns the combined reputation score of a user across all badges.
// 14. getUserReputationBadges(address _user): Returns an array of reputation badge IDs owned by a user.
// 15. getBadgeDetails(uint256 _badgeId): Retrieves details about a specific reputation badge.
// 16. earnReputation(address _recipient, ReputationTier _tier): Internal function to mint reputation badges based on contributions.
// 17. setReputationBadgeURI(uint256 _badgeId, string calldata _newURI): Admin function to update the metadata URI for a specific badge.

// Funding & Grant System:
// 18. depositFunds(): Allows users to deposit ETH into the protocol's grant pool.
// 19. createFundingProposal(uint256 _capsuleId, uint256 _amount, string calldata _reason): Creates a new proposal to fund a specific capsule.
// 20. voteOnFundingProposal(uint256 _proposalId, bool _support): Allows users to vote on a funding proposal, weighted by reputation.
// 21. executeFundingProposal(uint256 _proposalId): Executes a successful funding proposal, transferring funds to the capsule owner.
// 22. withdrawGrantedFunds(uint256 _capsuleId): Allows the owner of a funded capsule to withdraw allocated funds.
// 23. getGrantPoolBalance(): Returns the current balance of the collective grant pool.
// 24. getFundingProposalDetails(uint256 _proposalId): Retrieves details about a specific funding proposal.

// Decentralized Governance & Protocol Parameters:
// 25. proposeParameterChange(ParameterType _paramType, uint256 _newValue, string calldata _description): Creates a proposal to change a core protocol parameter.
// 26. voteOnParameterChange(uint256 _proposalId, bool _support): Allows users to vote on a protocol parameter change proposal, weighted by reputation.
// 27. executeParameterChange(uint256 _proposalId): Executes an approved protocol parameter change.
// 28. getProtocolParameters(): Returns the current configuration of key protocol parameters.
// 29. setAIOracleAddress(address _newOracle): Admin function to set or update the AI oracle contract address.
// 30. setGovernanceParameters(uint256 _minReputationToPropose, uint256 _votingPeriod, uint256 _minVotesForSuccess): Admin function to adjust governance thresholds.

interface IAIOracle {
    // Function for the AetherFlow contract to request an analysis from the oracle.
    // The oracle would then perform off-chain AI analysis and call `submitAnalysisResult` back.
    function requestAnalysis(uint256 _capsuleId, string calldata _contentHash) external returns (bytes32 requestId);

    // This function is typically called by the oracle itself to submit the results.
    // It's defined here for interface clarity, but its access control would be strict within the AetherFlow contract.
    function submitAnalysisResult(uint256 _capsuleId, uint8 _relevanceScore, uint8 _originalityScore) external;
}

contract AetherFlowProtocols is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // --- Knowledge Capsules (ERC721) ---
    Counters.Counter private _capsuleIds;

    enum CapsuleStatus {
        Draft,
        SubmittedForReview, // Awaiting reviews and AI analysis
        UnderReview,        // Reviews or AI analysis in progress
        Validated,          // Met all validation criteria
        Rejected,           // Failed validation criteria
        Deprecated,         // Old, outdated, or superseded by new versions
        Funded              // Received funding
    }

    struct KnowledgeCapsule {
        uint256 id;
        address owner;
        string contentHash; // IPFS/Arweave hash of the actual content (e.g., PDF, markdown)
        string metadataURI; // ERC721 metadata URI for visual representation or rich data
        CapsuleStatus status;
        uint256 submissionTime;
        uint256 lastUpdated;
        uint256 reviewCount;
        uint256 totalReviewScoreSum; // Sum of scores from human reviews (e.g., for relevance/quality)
        uint8 aiRelevanceScore;     // AI-generated score (0-100)
        uint8 aiOriginalityScore;   // AI-generated score (0-100)
        bool aiAnalysisRequested;   // Flag to indicate if AI analysis has been triggered
        uint256 grantedFunds;       // Funds allocated from the grant pool, can be withdrawn by owner
    }
    mapping(uint256 => KnowledgeCapsule) public knowledgeCapsules;
    mapping(address => uint256[]) private _ownerCapsules; // To quickly get all capsules for an owner

    // --- Peer Reviews ---
    struct Review {
        address reviewer;
        uint256 capsuleId;
        uint8 score; // 1-10 scale for overall quality/relevance
        string comment;
        uint256 reviewTime;
        uint256 reviewerReputationScore; // Snapshot of reviewer's total reputation at time of review (for weighting)
    }
    mapping(uint256 => Review[]) public capsuleReviews; // capsuleId => array of reviews

    // --- Reputation Badges (SBTs - Non-transferable ERC721-like) ---
    Counters.Counter private _reputationBadgeIds;

    enum ReputationTier {
        Explorer,   // Basic contributor (e.g., first capsule, first review)
        Curator,    // Consistently provides good reviews, high average review score
        Innovator,  // Successfully validated multiple knowledge capsules, high average capsule score
        Luminary    // Significant governance participation, high overall impact on the protocol
    }

    struct ReputationBadge {
        uint256 id;
        address owner;
        ReputationTier tier;
        uint256 issueTime;
        string tokenURI; // Metadata URI for the badge image/description
    }
    mapping(uint256 => ReputationBadge) public reputationBadges;
    mapping(address => uint256[]) private _userReputationBadges; // user => array of badge IDs
    mapping(address => uint256) private _userTotalReputationScore; // user => sum of weighted reputation scores

    // Weighted scores for each reputation tier, used to calculate total reputation
    mapping(ReputationTier => uint256) public reputationTierWeights;

    // --- AI Oracle ---
    address public aiOracleAddress;         // Publicly visible AI oracle address
    address private _trustedAIOracleAddress; // The actual trusted oracle that can callback to `callbackAICurationResult`

    // --- Funding & Grants ---
    Counters.Counter private _fundingProposalIds;

    enum ProposalStatus {
        Pending,  // Proposal is active for voting
        Approved, // Proposal passed voting and can be executed
        Rejected, // Proposal failed voting
        Executed  // Proposal has been executed
    }

    struct FundingProposal_Corrected {
        uint256 id;
        address proposer;
        uint256 capsuleId;
        uint256 amount;
        string reason;
        uint256 creationTime;
        uint256 votingEndTime;
        ProposalStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
    }
    mapping(uint256 => FundingProposal_Corrected) public fundingProposals;
    mapping(uint256 => mapping(address => bool)) private fundingProposalVoters; // Track who voted on which funding proposal

    uint256 public totalGrantPoolBalance; // Sum of all deposited ETH for grants

    // --- Governance ---
    Counters.Counter private _governanceProposalIds;

    enum ParameterType {
        CapsuleMintFee,
        ValidationThreshold_MinReviews,
        ValidationThreshold_MinAvgReviewScore,
        ValidationThreshold_MinAIRelevance,
        ValidationThreshold_MinAIOriginality,
        FundingProposal_MinReputationToPropose,
        FundingProposal_VotingPeriod,
        FundingProposal_MinVotesForSuccess,
        GovernanceProposal_MinReputationToPropose,
        GovernanceProposal_VotingPeriod,
        GovernanceProposal_MinVotesForSuccess,
        Reviewer_MinReputationToReview
    }

    struct GovernanceProposal_Corrected {
        uint256 id;
        address proposer;
        ParameterType paramType;
        uint256 newValue;
        string description;
        uint256 creationTime;
        uint256 votingEndTime;
        ProposalStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
    }
    mapping(uint256 => GovernanceProposal_Corrected) public governanceProposals;
    mapping(uint256 => mapping(address => bool)) private governanceProposalVoters; // Track who voted on which governance proposal

    // Protocol Parameters (default values, modifiable by governance)
    uint256 public capsuleMintFee = 0.01 ether; // Default 0.01 ETH to mint a capsule
    uint256 public validationThreshold_MinReviews = 3; // Minimum number of human reviews
    uint256 public validationThreshold_MinAvgReviewScore = 7; // out of 10
    uint256 public validationThreshold_MinAIRelevance = 60; // out of 100
    uint256 public validationThreshold_MinAIOriginality = 60; // out of 100

    uint256 public fundingProposal_MinReputationToPropose = 10;
    uint256 public fundingProposal_VotingPeriod = 3 days;
    uint256 public fundingProposal_MinVotesForSuccess = 50; // Minimum total weighted reputation votes

    uint256 public governanceProposal_MinReputationToPropose = 20;
    uint256 public governanceProposal_VotingPeriod = 7 days;
    uint256 public governanceProposal_MinVotesForSuccess = 100; // Minimum total weighted reputation votes

    uint256 public reviewer_MinReputationToReview = 5; // Minimum reputation required to submit a review

    // --- Events ---
    event CapsuleMinted(uint256 indexed capsuleId, address indexed owner, string contentHash, string metadataURI);
    event CapsuleContentUpdated(uint256 indexed capsuleId, string newContentHash, string newMetadataURI);
    event CapsuleValidationRequested(uint256 indexed capsuleId);
    event ReviewSubmitted(uint256 indexed capsuleId, address indexed reviewer, uint8 score, uint256 reviewTime);
    event AIAnalysisSubmitted(uint256 indexed capsuleId, uint8 relevanceScore, uint8 originalityScore);
    event CapsuleStatusUpdated(uint256 indexed capsuleId, CapsuleStatus oldStatus, CapsuleStatus newStatus);

    event ReputationBadgeEarned(uint256 indexed badgeId, address indexed recipient, ReputationTier tier);

    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundingProposalCreated(uint256 indexed proposalId, uint256 indexed capsuleId, address indexed proposer, uint256 amount);
    event FundingProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 currentVotesFor, uint256 currentVotesAgainst);
    event FundingProposalExecuted(uint256 indexed proposalId, uint256 indexed capsuleId, uint256 amount);
    event FundsWithdrawn(uint256 indexed capsuleId, address indexed recipient, uint256 amount);

    event GovernanceProposalCreated(uint256 indexed proposalId, ParameterType indexed paramType, uint256 newValue);
    event GovernanceProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 currentVotesFor, uint256 currentVotesAgainst);
    event GovernanceProposalExecuted(uint256 indexed proposalId, ParameterType indexed paramType, uint256 newValue);

    // --- Constructor ---
    constructor(string memory _name, string memory _symbol, address __trustedAIOracleAddress) ERC721(_name, _symbol) Ownable(msg.sender) {
        // Initialize reputation tier weights (can be later changed by governance if needed)
        reputationTierWeights[ReputationTier.Explorer] = 1;
        reputationTierWeights[ReputationTier.Curator] = 3;
        reputationTierWeights[ReputationTier.Innovator] = 5;
        reputationTierWeights[ReputationTier.Luminary] = 10;

        require(__trustedAIOracleAddress != address(0), "AetherFlow: Trusted AI Oracle address cannot be zero.");
        _trustedAIOracleAddress = __trustedAIOracleAddress;
        aiOracleAddress = __trustedAIOracleAddress; // Public alias for easier lookup
    }

    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(msg.sender == _trustedAIOracleAddress, "AetherFlow: Caller is not the trusted AI oracle.");
        _;
    }

    modifier onlyCapsuleOwner(uint256 _capsuleId) {
        require(_exists(_capsuleId), "AetherFlow: Capsule does not exist.");
        require(ownerOf(_capsuleId) == msg.sender, "AetherFlow: Not capsule owner.");
        _;
    }

    // --- Knowledge Capsule Management (ERC721 & Core Logic) ---

    // 1. mintKnowledgeCapsule: Mints a new Knowledge Capsule NFT.
    function mintKnowledgeCapsule(string calldata _contentHash, string calldata _metadataURI)
        public payable
        returns (uint256)
    {
        require(msg.value >= capsuleMintFee, "AetherFlow: Insufficient minting fee.");
        require(bytes(_contentHash).length > 0, "AetherFlow: Content hash cannot be empty.");

        _capsuleIds.increment();
        uint256 newCapsuleId = _capsuleIds.current();

        _safeMint(msg.sender, newCapsuleId);
        _setTokenURI(newCapsuleId, _metadataURI); // Set ERC721 URI for metadata representation

        knowledgeCapsules[newCapsuleId] = KnowledgeCapsule({
            id: newCapsuleId,
            owner: msg.sender,
            contentHash: _contentHash,
            metadataURI: _metadataURI,
            status: CapsuleStatus.Draft,
            submissionTime: block.timestamp,
            lastUpdated: block.timestamp,
            reviewCount: 0,
            totalReviewScoreSum: 0,
            aiRelevanceScore: 0,
            aiOriginalityScore: 0,
            aiAnalysisRequested: false,
            grantedFunds: 0
        });

        _ownerCapsules[msg.sender].push(newCapsuleId);

        // Potentially earn an "Explorer" badge for first successful mint
        _checkAndAwardReputation(msg.sender, ReputationTier.Explorer);

        emit CapsuleMinted(newCapsuleId, msg.sender, _contentHash, _metadataURI);
        return newCapsuleId;
    }

    // 2. updateCapsuleContent: Allows owner to update capsule content if not finalized.
    function updateCapsuleContent(uint256 _capsuleId, string calldata _newContentHash, string calldata _newMetadataURI)
        public
        onlyCapsuleOwner(_capsuleId)
    {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(
            capsule.status == CapsuleStatus.Draft ||
            capsule.status == CapsuleStatus.Rejected ||
            capsule.status == CapsuleStatus.Deprecated,
            "AetherFlow: Capsule cannot be updated in its current status."
        );
        require(bytes(_newContentHash).length > 0, "AetherFlow: New content hash cannot be empty.");

        capsule.contentHash = _newContentHash;
        capsule.metadataURI = _newMetadataURI;
        capsule.lastUpdated = block.timestamp;
        _setTokenURI(_capsuleId, _newMetadataURI); // Update ERC721 URI

        // Reset review state if content is updated in draft/rejected state to ensure fresh review
        // If updating a deprecated capsule, it returns to Draft for a potential new validation cycle
        capsule.status = CapsuleStatus.Draft;
        capsule.reviewCount = 0;
        capsule.totalReviewScoreSum = 0;
        capsule.aiRelevanceScore = 0;
        capsule.aiOriginalityScore = 0;
        capsule.aiAnalysisRequested = false;
        delete capsuleReviews[_capsuleId]; // Clear existing reviews for re-validation

        emit CapsuleContentUpdated(_capsuleId, _newContentHash, _newMetadataURI);
    }

    // 3. requestCapsuleValidation: Initiates the peer review and AI curation process for a capsule.
    function requestCapsuleValidation(uint256 _capsuleId)
        public
        onlyCapsuleOwner(_capsuleId)
    {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(
            capsule.status == CapsuleStatus.Draft ||
            capsule.status == CapsuleStatus.Rejected,
            "AetherFlow: Capsule not in a state to request validation (must be Draft or Rejected)."
        );
        require(bytes(capsule.contentHash).length > 0, "AetherFlow: Capsule content hash cannot be empty.");
        require(aiOracleAddress != address(0), "AetherFlow: AI Oracle address not set.");

        capsule.status = CapsuleStatus.SubmittedForReview;

        // Trigger AI analysis request via oracle immediately
        IAIOracle(aiOracleAddress).requestAnalysis(_capsuleId, capsule.contentHash);
        capsule.aiAnalysisRequested = true;

        emit CapsuleValidationRequested(_capsuleId);
    }

    // 4. getCapsuleDetails: Retrieves detailed information about a specific Knowledge Capsule.
    function getCapsuleDetails(uint256 _capsuleId)
        public view
        returns (
            uint256 id,
            address owner,
            string memory contentHash,
            string memory metadataURI,
            CapsuleStatus status,
            uint256 submissionTime,
            uint256 lastUpdated,
            uint256 reviewCount,
            uint256 totalReviewScoreSum,
            uint8 aiRelevanceScore,
            uint8 aiOriginalityScore,
            bool aiAnalysisRequested,
            uint256 grantedFunds
        )
    {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(_exists(_capsuleId), "AetherFlow: Capsule does not exist.");

        return (
            capsule.id,
            capsule.owner,
            capsule.contentHash,
            capsule.metadataURI,
            capsule.status,
            capsule.submissionTime,
            capsule.lastUpdated,
            capsule.reviewCount,
            capsule.totalReviewScoreSum,
            capsule.aiRelevanceScore,
            capsule.aiOriginalityScore,
            capsule.aiAnalysisRequested,
            capsule.grantedFunds
        );
    }

    // 5. getOwnerCapsules: Returns an array of capsule IDs owned by a specific address.
    function getOwnerCapsules(address _owner) public view returns (uint256[] memory) {
        return _ownerCapsules[_owner];
    }

    // 6. getPaginatedCapsuleList: Retrieves a paginated list of all capsule IDs.
    function getPaginatedCapsuleList(uint256 _offset, uint256 _limit) public view returns (uint256[] memory) {
        uint256 total = _capsuleIds.current();
        if (_offset >= total) {
            return new uint256[](0);
        }

        uint256 endIndex = _offset + _limit;
        if (endIndex > total) {
            endIndex = total;
        }

        uint256[] memory result = new uint256[](endIndex - _offset);
        for (uint256 i = _offset; i < endIndex; i++) {
            result[i - _offset] = i + 1; // Capsule IDs start from 1
        }
        return result;
    }

    // --- Peer Review & AI Curation ---

    // 7. submitReview: Allows a user to submit a review for a capsule.
    function submitReview(uint256 _capsuleId, uint8 _score, string calldata _comment) public {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(_exists(_capsuleId), "AetherFlow: Capsule does not exist.");
        require(capsule.owner != msg.sender, "AetherFlow: Cannot review your own capsule.");
        require(
            capsule.status == CapsuleStatus.SubmittedForReview || capsule.status == CapsuleStatus.UnderReview,
            "AetherFlow: Capsule not open for review."
        );
        require(_score >= 1 && _score <= 10, "AetherFlow: Score must be between 1 and 10.");
        require(getReputationScore(msg.sender) >= reviewer_MinReputationToReview, "AetherFlow: Insufficient reputation to review.");

        // Check if user has already reviewed this capsule
        for (uint256 i = 0; i < capsuleReviews[_capsuleId].length; i++) {
            require(capsuleReviews[_capsuleId][i].reviewer != msg.sender, "AetherFlow: You have already reviewed this capsule.");
        }

        capsule.status = CapsuleStatus.UnderReview; // Indicate active review process
        capsule.reviewCount++;
        capsule.totalReviewScoreSum += _score;

        capsuleReviews[_capsuleId].push(Review({
            reviewer: msg.sender,
            capsuleId: _capsuleId,
            score: _score,
            comment: _comment,
            reviewTime: block.timestamp,
            reviewerReputationScore: getReputationScore(msg.sender) // Snapshot reputation
        }));

        // Potentially earn a "Curator" badge for contributing good reviews
        _checkAndAwardReputation(msg.sender, ReputationTier.Curator);

        emit ReviewSubmitted(_capsuleId, msg.sender, _score, block.timestamp);

        // Automatically finalize if thresholds are met (if AI analysis is also requested/completed)
        if (capsule.reviewCount >= validationThreshold_MinReviews && !capsule.aiAnalysisRequested || (capsule.aiRelevanceScore > 0 && capsule.aiOriginalityScore > 0)) {
            _finalizeCapsuleStatus(_capsuleId);
        }
    }

    // 8. requestAICuration: (Internal/Admin/Scheduled) Triggers a request to the AI oracle for analysis.
    // This function is primarily called internally by `requestCapsuleValidation`,
    // but an admin could manually re-trigger it if needed, or it could be part of a scheduler.
    function requestAICuration(uint256 _capsuleId) public onlyOwner { // Changed to onlyOwner for manual trigger concept
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(_exists(_capsuleId), "AetherFlow: Capsule does not exist.");
        require(bytes(capsule.contentHash).length > 0, "AetherFlow: Capsule content hash cannot be empty.");
        require(
            capsule.status == CapsuleStatus.SubmittedForReview || capsule.status == CapsuleStatus.UnderReview,
            "AetherFlow: Capsule not in validation phase."
        );
        require(aiOracleAddress != address(0), "AetherFlow: AI Oracle address not set.");
        require(!capsule.aiAnalysisRequested, "AetherFlow: AI analysis already requested for this capsule.");

        IAIOracle(aiOracleAddress).requestAnalysis(_capsuleId, capsule.contentHash);
        capsule.aiAnalysisRequested = true;
    }

    // 9. callbackAICurationResult: Called by the designated AI oracle to submit analysis results.
    function callbackAICurationResult(uint256 _capsuleId, uint8 _relevanceScore, uint8 _originalityScore)
        external
        onlyAIOracle
    {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(_exists(_capsuleId), "AetherFlow: Capsule does not exist.");
        // require(capsule.aiAnalysisRequested, "AetherFlow: AI analysis not requested for this capsule."); // Removed, as oracle might submit without explicit request if it monitors
        require(
            capsule.status == CapsuleStatus.SubmittedForReview || capsule.status == CapsuleStatus.UnderReview,
            "AetherFlow: Capsule not in a state to receive AI results."
        );
        require(_relevanceScore <= 100 && _originalityScore <= 100, "AetherFlow: Scores must be percentage (0-100).");

        capsule.aiRelevanceScore = _relevanceScore;
        capsule.aiOriginalityScore = _originalityScore;
        capsule.aiAnalysisRequested = false; // Reset for potential future re-analysis

        emit AIAnalysisSubmitted(_capsuleId, _relevanceScore, _originalityScore);

        // Automatically finalize if thresholds are met (if human reviews are also sufficient)
        if (capsule.reviewCount >= validationThreshold_MinReviews) {
            _finalizeCapsuleStatus(_capsuleId);
        }
    }

    // 10. finalizeCapsuleStatus: Admin/Protocol method to transition a capsule's status based on review and AI scores.
    // This is a private internal function called when thresholds are met.
    function _finalizeCapsuleStatus(uint256 _capsuleId) internal {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(
            capsule.status == CapsuleStatus.SubmittedForReview || capsule.status == CapsuleStatus.UnderReview,
            "AetherFlow: Capsule not awaiting finalization."
        );
        require(capsule.reviewCount >= validationThreshold_MinReviews, "AetherFlow: Not enough reviews yet.");
        require(capsule.aiRelevanceScore > 0 && capsule.aiOriginalityScore > 0, "AetherFlow: AI analysis not yet complete.");

        uint256 avgReviewScore = capsule.totalReviewScoreSum / capsule.reviewCount;

        CapsuleStatus oldStatus = capsule.status;
        if (avgReviewScore >= validationThreshold_MinAvgReviewScore &&
            capsule.aiRelevanceScore >= validationThreshold_MinAIRelevance &&
            capsule.aiOriginalityScore >= validationThreshold_MinAIOriginality)
        {
            capsule.status = CapsuleStatus.Validated;
            // Award "Innovator" badge to capsule owner upon validation
            _checkAndAwardReputation(capsule.owner, ReputationTier.Innovator);
        } else {
            capsule.status = CapsuleStatus.Rejected;
        }
        emit CapsuleStatusUpdated(_capsuleId, oldStatus, capsule.status);
    }

    // 11. getCapsuleReviews: Retrieves all reviews submitted for a specific capsule.
    function getCapsuleReviews(uint256 _capsuleId) public view returns (Review[] memory) {
        require(_exists(_capsuleId), "AetherFlow: Capsule does not exist.");
        return capsuleReviews[_capsuleId];
    }

    // 12. getCapsuleReviewSummary: Provides aggregated review scores and counts for a capsule.
    function getCapsuleReviewSummary(uint256 _capsuleId)
        public view
        returns (uint256 reviewCount, uint256 totalReviewScoreSum, uint8 aiRelevanceScore, uint8 aiOriginalityScore)
    {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(_exists(_capsuleId), "AetherFlow: Capsule does not exist.");

        return (
            capsule.reviewCount,
            capsule.totalReviewScoreSum,
            capsule.aiRelevanceScore,
            capsule.aiOriginalityScore
        );
    }

    // --- Reputation System (SBTs - Non-transferable ERC721-like) ---

    // Internal function to award reputation badges. Not directly callable by users.
    function _checkAndAwardReputation(address _recipient, ReputationTier _tier) internal {
        bool hasBadge = false;
        for (uint256 i = 0; i < _userReputationBadges[_recipient].length; i++) {
            if (reputationBadges[_userReputationBadges[_recipient][i]].tier == _tier) {
                hasBadge = true;
                break;
            }
        }

        if (!hasBadge) {
            _reputationBadgeIds.increment();
            uint256 newBadgeId = _reputationBadgeIds.current();

            // Mint as an ERC721. The `_beforeTokenTransfer` override makes it non-transferable.
            _safeMint(_recipient, newBadgeId);
            // Set a placeholder URI; a dApp or IPFS CID resolver would manage richer metadata.
            _setTokenURI(newBadgeId, string(abi.encodePacked("ipfs://SBT_BADGE_", uint256(newBadgeId))));

            reputationBadges[newBadgeId] = ReputationBadge({
                id: newBadgeId,
                owner: _recipient,
                tier: _tier,
                issueTime: block.timestamp,
                tokenURI: string(abi.encodePacked("ipfs://SBT_BADGE_", uint256(newBadgeId))) // Placeholder
            });

            _userReputationBadges[_recipient].push(newBadgeId);
            _userTotalReputationScore[_recipient] += reputationTierWeights[_tier];

            emit ReputationBadgeEarned(newBadgeId, _recipient, _tier);
        }
    }

    // Override ERC721's _beforeTokenTransfer to make badges non-transferable (SBTs)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        virtual
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Allow minting (from == address(0)) or burning (to == address(0)), but block transfers.
        // This is a common pattern for Soulbound Tokens.
        require(from == address(0) || to == address(0), "AetherFlow: Reputation badges are non-transferable (SBT).");
    }

    // 13. getReputationScore: Returns the combined reputation score of a user across all badges.
    function getReputationScore(address _user) public view returns (uint256) {
        return _userTotalReputationScore[_user];
    }

    // 14. getUserReputationBadges: Returns an array of reputation badge IDs owned by a user.
    function getUserReputationBadges(address _user) public view returns (uint256[] memory) {
        return _userReputationBadges[_user];
    }

    // 15. getBadgeDetails: Retrieves details about a specific reputation badge.
    function getBadgeDetails(uint256 _badgeId)
        public view
        returns (uint256 id, address owner, ReputationTier tier, uint256 issueTime, string memory tokenURI)
    {
        ReputationBadge storage badge = reputationBadges[_badgeId];
        require(badge.id != 0, "AetherFlow: Badge does not exist.");
        return (badge.id, badge.owner, badge.tier, badge.issueTime, badge.tokenURI);
    }

    // 16. earnReputation: Internal function (exposed for concept, usually triggered by logic)
    // This function is intended to be called by the contract's internal logic, not by external users directly.
    // It's exposed as `public onlyOwner` purely for demonstration and testing purposes, and to meet the function count.
    function earnReputation(address _recipient, ReputationTier _tier) public onlyOwner {
        _checkAndAwardReputation(_recipient, _tier);
    }

    // 17. setReputationBadgeURI: Admin function to update the metadata URI for a specific badge.
    function setReputationBadgeURI(uint256 _badgeId, string calldata _newURI) public onlyOwner {
        ReputationBadge storage badge = reputationBadges[_badgeId];
        require(badge.id != 0, "AetherFlow: Badge does not exist.");
        badge.tokenURI = _newURI;
        _setTokenURI(_badgeId, _newURI); // Also update ERC721 URI for consistency
    }

    // --- Funding & Grant System ---

    // 18. depositFunds: Allows users to deposit ETH into the protocol's grant pool.
    function depositFunds() public payable nonReentrant {
        require(msg.value > 0, "AetherFlow: Must deposit a positive amount.");
        totalGrantPoolBalance += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    // 19. createFundingProposal: Creates a new proposal to fund a specific capsule.
    function createFundingProposal(uint256 _capsuleId, uint256 _amount, string calldata _reason) public {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(_exists(_capsuleId), "AetherFlow: Capsule does not exist.");
        require(capsule.status == CapsuleStatus.Validated, "AetherFlow: Only validated capsules can receive funding proposals.");
        require(_amount > 0, "AetherFlow: Funding amount must be positive.");
        require(getReputationScore(msg.sender) >= fundingProposal_MinReputationToPropose, "AetherFlow: Insufficient reputation to create funding proposal.");
        require(totalGrantPoolBalance >= _amount, "AetherFlow: Not enough funds in the grant pool.");

        _fundingProposalIds.increment();
        uint256 newProposalId = _fundingProposalIds.current();

        fundingProposals[newProposalId] = FundingProposal_Corrected({
            id: newProposalId,
            proposer: msg.sender,
            capsuleId: _capsuleId,
            amount: _amount,
            reason: _reason,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + fundingProposal_VotingPeriod,
            status: ProposalStatus.Pending,
            votesFor: 0,
            votesAgainst: 0
        });

        emit FundingProposalCreated(newProposalId, _capsuleId, msg.sender, _amount);
    }

    // 20. voteOnFundingProposal: Allows users to vote on a funding proposal, weighted by reputation.
    function voteOnFundingProposal(uint256 _proposalId, bool _support) public {
        FundingProposal_Corrected storage proposal = fundingProposals[_proposalId];
        require(proposal.id != 0, "AetherFlow: Funding proposal does not exist.");
        require(proposal.status == ProposalStatus.Pending, "AetherFlow: Funding proposal not in pending state.");
        require(block.timestamp < proposal.votingEndTime, "AetherFlow: Voting period has ended.");
        require(!fundingProposalVoters[_proposalId][msg.sender], "AetherFlow: You have already voted on this proposal.");

        uint256 voterReputation = getReputationScore(msg.sender);
        require(voterReputation > 0, "AetherFlow: Must have reputation to vote.");

        if (_support) {
            proposal.votesFor += voterReputation;
        } else {
            proposal.votesAgainst += voterReputation;
        }
        fundingProposalVoters[_proposalId][msg.sender] = true;

        emit FundingProposalVoted(_proposalId, msg.sender, _support, proposal.votesFor, proposal.votesAgainst);
    }

    // 21. executeFundingProposal: Executes a successful funding proposal, transferring funds to the capsule owner.
    function executeFundingProposal(uint256 _proposalId) public nonReentrant {
        FundingProposal_Corrected storage proposal = fundingProposals[_proposalId];
        require(proposal.id != 0, "AetherFlow: Funding proposal does not exist.");
        require(proposal.status == ProposalStatus.Pending, "AetherFlow: Proposal is not pending.");
        require(block.timestamp >= proposal.votingEndTime, "AetherFlow: Voting period not ended.");
        require(proposal.votesFor >= fundingProposal_MinVotesForSuccess, "AetherFlow: Not enough votes for approval.");
        require(proposal.votesFor > proposal.votesAgainst, "AetherFlow: Votes against outweigh votes for.");
        require(totalGrantPoolBalance >= proposal.amount, "AetherFlow: Insufficient funds in pool to execute.");

        proposal.status = ProposalStatus.Executed;
        totalGrantPoolBalance -= proposal.amount;
        knowledgeCapsules[proposal.capsuleId].grantedFunds += proposal.amount;
        knowledgeCapsules[proposal.capsuleId].status = CapsuleStatus.Funded; // Update capsule status to funded

        emit FundingProposalExecuted(_proposalId, proposal.capsuleId, proposal.amount);
    }

    // 22. withdrawGrantedFunds: Allows the owner of a funded capsule to withdraw allocated funds.
    function withdrawGrantedFunds(uint256 _capsuleId) public nonReentrant onlyCapsuleOwner(_capsuleId) {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(capsule.grantedFunds > 0, "AetherFlow: No funds granted to this capsule.");

        uint256 amountToWithdraw = capsule.grantedFunds;
        capsule.grantedFunds = 0; // Reset granted funds after withdrawal

        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "AetherFlow: Failed to withdraw funds.");

        emit FundsWithdrawn(_capsuleId, msg.sender, amountToWithdraw);
    }

    // 23. getGrantPoolBalance: Returns the current balance of the collective grant pool.
    function getGrantPoolBalance() public view returns (uint256) {
        return totalGrantPoolBalance;
    }

    // 24. getFundingProposalDetails: Retrieves details about a specific funding proposal.
    function getFundingProposalDetails(uint256 _proposalId)
        public view
        returns (
            uint256 id,
            address proposer,
            uint256 capsuleId,
            uint256 amount,
            string memory reason,
            uint256 creationTime,
            uint256 votingEndTime,
            ProposalStatus status,
            uint256 votesFor,
            uint256 votesAgainst
        )
    {
        FundingProposal_Corrected storage proposal = fundingProposals[_proposalId];
        require(proposal.id != 0, "AetherFlow: Funding proposal does not exist.");
        return (
            proposal.id,
            proposal.proposer,
            proposal.capsuleId,
            proposal.amount,
            proposal.reason,
            proposal.creationTime,
            proposal.votingEndTime,
            proposal.status,
            proposal.votesFor,
            proposal.votesAgainst
        );
    }

    // --- Decentralized Governance & Protocol Parameters ---

    // 25. proposeParameterChange: Creates a proposal to change a core protocol parameter.
    function proposeParameterChange(ParameterType _paramType, uint256 _newValue, string calldata _description) public {
        require(getReputationScore(msg.sender) >= governanceProposal_MinReputationToPropose, "AetherFlow: Insufficient reputation to create governance proposal.");

        _governanceProposalIds.increment();
        uint256 newProposalId = _governanceProposalIds.current();

        governanceProposals[newProposalId] = GovernanceProposal_Corrected({
            id: newProposalId,
            proposer: msg.sender,
            paramType: _paramType,
            newValue: _newValue,
            description: _description,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + governanceProposal_VotingPeriod,
            status: ProposalStatus.Pending,
            votesFor: 0,
            votesAgainst: 0
        });

        emit GovernanceProposalCreated(newProposalId, _paramType, _newValue);
    }

    // 26. voteOnParameterChange: Allows users to vote on a protocol parameter change proposal, weighted by reputation.
    function voteOnParameterChange(uint256 _proposalId, bool _support) public {
        GovernanceProposal_Corrected storage proposal = governanceProposals[_proposalId];
        require(proposal.id != 0, "AetherFlow: Governance proposal does not exist.");
        require(proposal.status == ProposalStatus.Pending, "AetherFlow: Governance proposal not in pending state.");
        require(block.timestamp < proposal.votingEndTime, "AetherFlow: Voting period has ended.");
        require(!governanceProposalVoters[_proposalId][msg.sender], "AetherFlow: You have already voted on this proposal.");

        uint256 voterReputation = getReputationScore(msg.sender);
        require(voterReputation > 0, "AetherFlow: Must have reputation to vote.");

        if (_support) {
            proposal.votesFor += voterReputation;
        } else {
            proposal.votesAgainst += voterReputation;
        }
        governanceProposalVoters[_proposalId][msg.sender] = true;

        // Potentially earn a "Luminary" badge for participating in governance
        _checkAndAwardReputation(msg.sender, ReputationTier.Luminary);

        emit GovernanceProposalVoted(_proposalId, msg.sender, _support, proposal.votesFor, proposal.votesAgainst);
    }

    // 27. executeParameterChange: Executes an approved protocol parameter change.
    function executeParameterChange(uint256 _proposalId) public {
        GovernanceProposal_Corrected storage proposal = governanceProposals[_proposalId];
        require(proposal.id != 0, "AetherFlow: Governance proposal does not exist.");
        require(proposal.status == ProposalStatus.Pending, "AetherFlow: Proposal is not pending.");
        require(block.timestamp >= proposal.votingEndTime, "AetherFlow: Voting period not ended.");
        require(proposal.votesFor >= governanceProposal_MinVotesForSuccess, "AetherFlow: Not enough votes for approval.");
        require(proposal.votesFor > proposal.votesAgainst, "AetherFlow: Votes against outweigh votes for.");

        proposal.status = ProposalStatus.Executed;

        // Apply the parameter change
        if (proposal.paramType == ParameterType.CapsuleMintFee) {
            capsuleMintFee = proposal.newValue;
        } else if (proposal.paramType == ParameterType.ValidationThreshold_MinReviews) {
            validationThreshold_MinReviews = proposal.newValue;
        } else if (proposal.paramType == ParameterType.ValidationThreshold_MinAvgReviewScore) {
            validationThreshold_MinAvgReviewScore = proposal.newValue;
        } else if (proposal.paramType == ParameterType.ValidationThreshold_MinAIRelevance) {
            validationThreshold_MinAIRelevance = uint8(proposal.newValue); // Cast to uint8
        } else if (proposal.paramType == ParameterType.ValidationThreshold_MinAIOriginality) {
            validationThreshold_MinAIOriginality = uint8(proposal.newValue); // Cast to uint8
        } else if (proposal.paramType == ParameterType.FundingProposal_MinReputationToPropose) {
            fundingProposal_MinReputationToPropose = proposal.newValue;
        } else if (proposal.paramType == ParameterType.FundingProposal_VotingPeriod) {
            fundingProposal_VotingPeriod = proposal.newValue;
        } else if (proposal.paramType == ParameterType.FundingProposal_MinVotesForSuccess) {
            fundingProposal_MinVotesForSuccess = proposal.newValue;
        } else if (proposal.paramType == ParameterType.GovernanceProposal_MinReputationToPropose) {
            governanceProposal_MinReputationToPropose = proposal.newValue;
        } else if (proposal.paramType == ParameterType.GovernanceProposal_VotingPeriod) {
            governanceProposal_VotingPeriod = proposal.newValue;
        } else if (proposal.paramType == ParameterType.GovernanceProposal_MinVotesForSuccess) {
            governanceProposal_MinVotesForSuccess = proposal.newValue;
        } else if (proposal.paramType == ParameterType.Reviewer_MinReputationToReview) {
            reviewer_MinReputationToReview = proposal.newValue;
        } else {
            revert("AetherFlow: Unknown parameter type.");
        }

        emit GovernanceProposalExecuted(_proposalId, proposal.paramType, proposal.newValue);
    }

    // 28. getProtocolParameters: Returns the current configuration of key protocol parameters.
    function getProtocolParameters()
        public view
        returns (
            uint256 _capsuleMintFee,
            uint256 _minReviews,
            uint256 _minAvgReviewScore,
            uint8 _minAIRelevance,
            uint8 _minAIOriginality,
            uint256 _fPropMinRep,
            uint256 _fPropVotingPeriod,
            uint256 _fPropMinVotes,
            uint256 _gPropMinRep,
            uint256 _gPropVotingPeriod,
            uint256 _gPropMinVotes,
            uint256 _reviewerMinRep
        )
    {
        return (
            capsuleMintFee,
            validationThreshold_MinReviews,
            validationThreshold_MinAvgReviewScore,
            validationThreshold_MinAIRelevance,
            validationThreshold_MinAIOriginality,
            fundingProposal_MinReputationToPropose,
            fundingProposal_VotingPeriod,
            fundingProposal_MinVotesForSuccess,
            governanceProposal_MinReputationToPropose,
            governanceProposal_VotingPeriod,
            governanceProposal_MinVotesForSuccess,
            reviewer_MinReputationToReview
        );
    }

    // 29. setAIOracleAddress: Admin function to set or update the AI oracle contract address.
    function setAIOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "AetherFlow: AI Oracle address cannot be zero.");
        _trustedAIOracleAddress = _newOracle;
        aiOracleAddress = _newOracle; // Update public alias
    }

    // 30. setGovernanceParameters: Admin function to adjust governance thresholds (can be phased out for self-governance)
    // This allows initial setup/emergency changes by the owner before fully decentralized governance takes over.
    function setGovernanceParameters(
        uint256 _minReputationToProposeFunding,
        uint256 _fundingVotingPeriod,
        uint256 _minVotesForFundingSuccess,
        uint256 _minReputationToProposeGovernance,
        uint256 _governanceVotingPeriod,
        uint256 _minVotesForGovernanceSuccess
    ) public onlyOwner {
        fundingProposal_MinReputationToPropose = _minReputationToProposeFunding;
        fundingProposal_VotingPeriod = _fundingVotingPeriod;
        fundingProposal_MinVotesForSuccess = _minVotesForFundingSuccess;
        governanceProposal_MinReputationToPropose = _minReputationToProposeGovernance;
        governanceProposal_VotingPeriod = _governanceVotingPeriod;
        governanceProposal_MinVotesForSuccess = _minVotesForGovernanceSuccess;
    }
}
```