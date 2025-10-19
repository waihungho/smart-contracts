Here's a smart contract for a "Decentralized Research Foundry" (DRF). This contract aims to be an advanced, creative, and trendy solution for funding and managing decentralized research and development projects. It incorporates elements of DAOs, milestone-based funding, a reputation system, and a dispute resolution mechanism.

The core idea is to allow researchers to submit proposals, have the community/governance review and approve them, fund projects in stages based on milestone completion, and resolve disputes that may arise during the research process.

---

## DecentralizedResearchFoundry (DRF)

### Outline and Function Summary

The `DecentralizedResearchFoundry` contract facilitates a community-driven platform for funding and managing research projects on the blockchain. It encompasses proposal submission, a multi-stage review and voting process, milestone-based funding release, a reputation system for participants, and an on-chain dispute resolution mechanism.

**I. Core Infrastructure & Fund Management**
1.  `constructor()`: Initializes the contract owner and initial governance parameters.
2.  `depositFoundryFund()`: Allows anyone to contribute ETH to the Foundry's common funding pool.
3.  `withdrawFoundryExcessFund()`: Enables the governance to withdraw surplus ETH from the Foundry fund if deemed necessary.
4.  `setGovernanceParameters()`: Allows governance to adjust critical parameters such as minimum votes for approval, review thresholds, and dispute periods.

**II. Proposal Submission & Lifecycle**
5.  `submitResearchProposal()`: Researchers submit a new proposal, including a title, description, total funding goal, and a detailed list of milestones.
6.  `updateProposalDraft()`: Allows the submitting researcher to modify their proposal details while it is still in the `Draft` status.
7.  `submitProposalForReview()`: Changes a proposal's status from `Draft` to `SubmittedForReview`, making it available for governance assignment of reviewers.
8.  `getProposalDetails()`: Read-only function to retrieve comprehensive information about a specific research proposal.

**III. Review & Approval Process (Proposals)**
9.  `assignProposalReviewers()`: Governance assigns a set of authorized addresses to review a specific research proposal.
10. `submitProposalReview()`: Assigned reviewers provide their assessment (rating and comment hash) for a proposal.
11. `voteOnProposalApproval()`: Holders of sufficient reputation (or delegated governance power) vote to approve or reject a proposal for funding.
12. `finalizeProposalDecision()`: After the voting period, this function tallies the votes and sets the proposal's final status (`ApprovedForFunding` or `Rejected`).

**IV. Milestone Management & Funding Release**
13. `submitMilestoneCompletion()`: Researchers mark a milestone as complete, providing evidence (via a hash), and request the next funding tranche.
14. `assignMilestoneReviewers()`: Governance assigns reviewers to assess a recently submitted milestone completion.
15. `submitMilestoneReview()`: Assigned reviewers provide their assessment of the completed milestone's evidence.
16. `voteOnMilestoneRelease()`: Reputation holders vote to approve or reject the release of funds for a completed milestone.
17. `finalizeMilestoneDecision()`: Tallies votes for a milestone. If approved, it triggers `releaseMilestoneFunding()` to the researcher, otherwise marks the milestone as `Rejected`.
18. `releaseMilestoneFunding()`: (Internal) Transfers the approved funding for a completed milestone to the researcher.

**V. Dispute Resolution & Arbitration**
19. `initiateMilestoneDispute()`: Allows a researcher or reviewer to formally dispute a milestone's review or completion status.
20. `submitDisputeEvidence()`: Parties involved in an `Open` dispute submit their cryptographic evidence hashes.
21. `voteOnDisputeOutcome()`: Reputation holders vote on the outcome of an ongoing dispute (e.g., siding with the researcher or the reviewer/governance).
22. `resolveDispute()`: Finalizes a dispute based on the voting outcome, potentially overriding previous decisions, penalizing parties, or re-evaluating.

**VI. Reputation & Administration**
23. `grantReputation()`: Owner/Governance can manually award reputation points (e.g., for exceptional off-chain contributions).
24. `revokeReputation()`: Owner/Governance can manually revoke reputation points (e.g., for malicious behavior).
25. `getReputationScore()`: Read-only function to check an address's current reputation score.
26. `emergencyPause()`: Allows the owner/governance to pause critical contract functions in an emergency.
27. `unpauseContract()`: Unpauses the contract functions.
28. `transferOwnership()`: Transfers contract ownership (and primary governance control) to a new address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title DecentralizedResearchFoundry (DRF)
 * @dev A smart contract for funding and managing decentralized research projects.
 *      It integrates proposal submission, milestone-based funding, a review system,
 *      a reputation mechanism, and on-chain dispute resolution.
 *
 * Outline and Function Summary:
 *
 * I. Core Infrastructure & Fund Management
 * 1. constructor(): Initializes the contract owner and initial governance parameters.
 * 2. depositFoundryFund(): Allows anyone to contribute ETH to the Foundry's common funding pool.
 * 3. withdrawFoundryExcessFund(): Enables the governance to withdraw surplus ETH from the Foundry fund if deemed necessary.
 * 4. setGovernanceParameters(): Allows governance to adjust critical parameters such as minimum votes for approval, review thresholds, and dispute periods.
 *
 * II. Proposal Submission & Lifecycle
 * 5. submitResearchProposal(): Researchers submit a new proposal, including a title, description, total funding goal, and a detailed list of milestones.
 * 6. updateProposalDraft(): Allows the submitting researcher to modify their proposal details while it is still in the `Draft` status.
 * 7. submitProposalForReview(): Changes a proposal's status from `Draft` to `SubmittedForReview`, making it available for governance assignment of reviewers.
 * 8. getProposalDetails(): Read-only function to retrieve comprehensive information about a specific research proposal.
 *
 * III. Review & Approval Process (Proposals)
 * 9. assignProposalReviewers(): Governance assigns a set of authorized addresses to review a specific research proposal.
 * 10. submitProposalReview(): Assigned reviewers provide their assessment (rating and comment hash) for a proposal.
 * 11. voteOnProposalApproval(): Holders of sufficient reputation (or delegated governance power) vote to approve or reject a proposal for funding.
 * 12. finalizeProposalDecision(): After the voting period, this function tallies the votes and sets the proposal's final status (`ApprovedForFunding` or `Rejected`).
 *
 * IV. Milestone Management & Funding Release
 * 13. submitMilestoneCompletion(): Researchers mark a milestone as complete, providing evidence (via a hash), and request the next funding tranche.
 * 14. assignMilestoneReviewers(): Governance assigns reviewers to assess a recently submitted milestone completion.
 * 15. submitMilestoneReview(): Assigned reviewers provide their assessment of the completed milestone's evidence.
 * 16. voteOnMilestoneRelease(): Reputation holders vote to approve or reject the release of funds for a completed milestone.
 * 17. finalizeMilestoneDecision(): Tallies votes for a milestone. If approved, it triggers releaseMilestoneFunding() to the researcher, otherwise marks the milestone as `Rejected`.
 * 18. releaseMilestoneFunding(): (Internal) Transfers the approved funding for a completed milestone to the researcher.
 *
 * V. Dispute Resolution & Arbitration
 * 19. initiateMilestoneDispute(): Allows a researcher or reviewer to formally dispute a milestone's review or completion status.
 * 20. submitDisputeEvidence(): Parties involved in an `Open` dispute submit their cryptographic evidence hashes.
 * 21. voteOnDisputeOutcome(): Reputation holders vote on the outcome of an ongoing dispute (e.g., siding with the researcher or the reviewer/governance).
 * 22. resolveDispute(): Finalizes a dispute based on the voting outcome, potentially overriding previous decisions, penalizing parties, or re-evaluating.
 *
 * VI. Reputation & Administration
 * 23. grantReputation(): Owner/Governance can manually award reputation points (e.g., for exceptional off-chain contributions).
 * 24. revokeReputation(): Owner/Governance can manually revoke reputation points (e.g., for malicious behavior).
 * 25. getReputationScore(): Read-only function to check an address's current reputation score.
 * 26. emergencyPause(): Allows the owner/governance to pause critical contract functions in an emergency.
 * 27. unpauseContract(): Unpauses the contract functions.
 * 28. transferOwnership(): Transfers contract ownership (and primary governance control) to a new address.
 */
contract DecentralizedResearchFoundry is Ownable, Pausable, ReentrancyGuard {

    // --- Enums ---
    enum ProposalStatus {
        Draft,                // Created by researcher, not yet submitted for review
        SubmittedForReview,   // Submitted for governance to assign reviewers
        UnderReview,          // Reviewers are actively assessing
        ApprovedForFunding,   // Approved by governance for funding (but no funds released yet)
        Rejected,             // Rejected by governance
        InProgress,           // Funding has started, milestones are being worked on
        Completed,            // All milestones completed and funded
        Cancelled             // Cancelled by governance or researcher (with conditions)
    }

    enum MilestoneStatus {
        Pending,              // Awaiting researcher to start/submit
        SubmittedForReview,   // Researcher submitted completion, awaiting review assignment
        UnderReview,          // Reviewers are assessing completion
        Approved,             // Approved for funding release
        Rejected,             // Rejected (requires re-submission or dispute)
        Disputed              // Milestone status is under dispute
    }

    enum ReviewType {
        Proposal,
        Milestone
    }

    enum DisputeStatus {
        Open,                 // Dispute initiated, awaiting evidence
        EvidenceSubmitted,    // All parties submitted evidence, awaiting vote
        UnderVote,            // Voting is active
        Resolved              // Dispute has been resolved
    }

    // --- Structs ---
    struct Milestone {
        uint256 id;                 // Unique milestone ID
        uint256 proposalId;         // Parent proposal ID
        string description;         // Description of the milestone
        uint256 fundingAmount;      // ETH amount for this milestone
        MilestoneStatus status;     // Current status of the milestone
        uint64 expectedCompletionDate; // Unix timestamp
        uint64 actualCompletionDate; // Unix timestamp of completion submission
        bytes32 evidenceHash;       // Hash of off-chain evidence (e.g., IPFS CID)
        uint256 reviewCount;        // Number of reviews received for this milestone
        uint256 approvalCount;      // Number of positive reviews/votes
        mapping(address => bool) hasReviewed; // Track who reviewed this milestone
        mapping(address => bool) hasVoted;    // Track who voted on this milestone's approval
    }

    struct Proposal {
        uint256 id;                   // Unique proposal ID
        address researcher;           // Address of the researcher/team lead
        string title;                 // Title of the research proposal
        string description;           // Detailed description (IPFS CID)
        uint256 fundingGoal;          // Total ETH requested for the proposal
        uint256 currentFundingReleased; // Total ETH released to date
        uint256[] milestoneIds;       // IDs of associated milestones
        ProposalStatus status;        // Current status of the proposal
        uint64 submittedAt;           // Unix timestamp of submission
        uint64 reviewPeriodEnd;       // Unix timestamp when proposal review period ends
        uint256 requiredReviews;      // Number of reviews needed before voting
        uint256 receivedReviews;      // Number of reviews received
        uint256 approvalVotes;        // Number of approval votes
        uint256 rejectionVotes;       // Number of rejection votes
        mapping(address => bool) hasReviewed; // Track who reviewed this proposal
        mapping(address => bool) hasVoted;    // Track who voted on this proposal's approval
    }

    struct Review {
        uint256 id;                  // Unique review ID
        address reviewer;            // Address of the reviewer
        ReviewType reviewType;       // Type: Proposal or Milestone
        uint256 entityId;            // ID of the proposal or milestone being reviewed
        uint8 rating;                // e.g., 1-5, or 0 (reject), 1 (approve)
        bytes32 commentHash;         // Hash of off-chain comments/feedback
        uint64 submittedAt;          // Unix timestamp
    }

    struct Dispute {
        uint256 id;                  // Unique dispute ID
        uint256 proposalId;          // Parent proposal ID
        uint256 milestoneId;         // Specific milestone ID being disputed
        address initiator;           // Address that initiated the dispute
        address defendant;           // Address being disputed against
        bytes32 reasonHash;          // Hash of the dispute reason
        bytes32[] evidenceHashes;    // Array of evidence hashes from both parties
        DisputeStatus status;        // Current status of the dispute
        uint64 initiatedAt;          // Unix timestamp
        uint64 evidencePeriodEnd;     // Unix timestamp for evidence submission deadline
        uint64 votingPeriodEnd;       // Unix timestamp for dispute voting deadline
        uint256 initiatorVotes;      // Votes for the initiator's side
        uint256 defendantVotes;      // Votes for the defendant's side
        mapping(address => bool) hasVoted; // Track who voted on this dispute
    }

    // --- State Variables ---
    uint256 public nextProposalId;
    uint256 public nextMilestoneId;
    uint256 public nextReviewId;
    uint256 public nextDisputeId;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => Milestone) public milestones;
    mapping(uint256 => Review) public reviews; // All reviews (proposal and milestone)
    mapping(uint256 => Dispute) public disputes;

    // Assigned reviewers: proposalId -> reviewerAddress -> isAssigned
    mapping(uint256 => mapping(address => bool)) public proposalReviewers;
    // Assigned reviewers: milestoneId -> reviewerAddress -> isAssigned
    mapping(uint256 => mapping(address => bool)) public milestoneReviewers;

    // Reputation system: address -> score
    mapping(address => uint256) public reputationScores;

    // Governance Parameters
    uint256 public minReputationForVote = 10; // Minimum reputation to cast a vote
    uint256 public minVotesForProposalApproval = 3; // Minimum positive votes for proposal approval
    uint256 public minReviewsForProposal = 2; // Minimum reviews needed before proposal voting
    uint256 public minReviewsForMilestone = 1; // Minimum reviews needed before milestone voting
    uint256 public reviewPeriodDuration = 3 days; // Duration for reviewers to submit their reviews
    uint256 public votingPeriodDuration = 7 days; // Duration for governance voting
    uint256 public disputeEvidencePeriod = 3 days; // Duration for parties to submit evidence in a dispute
    uint256 public disputeVotingPeriod = 5 days; // Duration for governance to vote on a dispute

    // --- Events ---
    event FoundryFundDeposited(address indexed sender, uint255 amount);
    event FoundryFundWithdrawn(address indexed recipient, uint255 amount);
    event GovernanceParametersUpdated(address indexed setter, uint256 newMinReputationForVote, uint256 newMinVotesForProposalApproval, uint256 newMinReviewsForProposal, uint256 newMinReviewsForMilestone, uint256 newReviewPeriodDuration, uint256 newVotingPeriodDuration, uint256 newDisputeEvidencePeriod, uint256 newDisputeVotingPeriod);

    event ProposalSubmitted(uint256 indexed proposalId, address indexed researcher, string title, uint256 fundingGoal, uint256 numMilestones);
    event ProposalUpdated(uint256 indexed proposalId, address indexed researcher);
    event ProposalSubmittedForReview(uint256 indexed proposalId);
    event ProposalReviewersAssigned(uint256 indexed proposalId, address[] reviewers);
    event ProposalReviewSubmitted(uint256 indexed proposalId, uint256 indexed reviewId, address indexed reviewer, uint8 rating);
    event ProposalVoteCast(uint256 indexed proposalId, address indexed voter, bool approved);
    event ProposalDecisionFinalized(uint256 indexed proposalId, ProposalStatus newStatus);

    event MilestoneCompletionSubmitted(uint256 indexed milestoneId, uint256 indexed proposalId, address indexed researcher, bytes32 evidenceHash);
    event MilestoneReviewersAssigned(uint256 indexed milestoneId, address[] reviewers);
    event MilestoneReviewSubmitted(uint256 indexed milestoneId, uint256 indexed reviewId, address indexed reviewer, uint8 rating);
    event MilestoneVoteCast(uint256 indexed milestoneId, uint256 indexed proposalId, address indexed voter, bool approved);
    event MilestoneDecisionFinalized(uint256 indexed milestoneId, MilestoneStatus newStatus);
    event MilestoneFundingReleased(uint256 indexed milestoneId, uint256 indexed proposalId, address indexed recipient, uint256 amount);

    event DisputeInitiated(uint256 indexed disputeId, uint256 indexed milestoneId, address indexed initiator, address defendant);
    event DisputeEvidenceSubmitted(uint256 indexed disputeId, address indexed submitter, bytes32 evidenceHash);
    event DisputeVoteCast(uint256 indexed disputeId, address indexed voter, bool initiatorSide);
    event DisputeResolved(uint256 indexed disputeId, DisputeStatus newStatus, bool winningSideInitiator);

    event ReputationGranted(address indexed user, uint256 amount, address indexed admin);
    event ReputationRevoked(address indexed user, uint256 amount, address indexed admin);


    // --- Modifiers ---
    modifier onlyResearcher(uint256 _proposalId) {
        require(proposals[_proposalId].researcher == _msgSender(), "DRF: Not the researcher of this proposal");
        _;
    }

    modifier onlyProposalReviewer(uint256 _proposalId) {
        require(proposalReviewers[_proposalId][_msgSender()], "DRF: Not an assigned reviewer for this proposal");
        _;
    }

    modifier onlyMilestoneReviewer(uint256 _milestoneId) {
        require(milestoneReviewers[_milestoneId][_msgSender()], "DRF: Not an assigned reviewer for this milestone");
        _;
    }

    modifier hasMinReputation() {
        require(reputationScores[_msgSender()] >= minReputationForVote, "DRF: Insufficient reputation to perform this action");
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        nextProposalId = 1;
        nextMilestoneId = 1;
        nextReviewId = 1;
        nextDisputeId = 1;
        // Grant initial owner some reputation to participate in governance
        reputationScores[msg.sender] = 100;
    }

    receive() external payable {
        emit FoundryFundDeposited(_msgSender(), msg.value);
    }

    fallback() external payable {
        emit FoundryFundDeposited(_msgSender(), msg.value);
    }

    // --- I. Core Infrastructure & Fund Management ---

    /**
     * @dev Allows anyone to contribute ETH to the Foundry's common funding pool.
     */
    function depositFoundryFund() external payable nonReentrant whenNotPaused {
        require(msg.value > 0, "DRF: Must deposit a positive amount");
        emit FoundryFundDeposited(_msgSender(), msg.value);
    }

    /**
     * @dev Enables the governance (owner) to withdraw surplus ETH from the Foundry fund.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawFoundryExcessFund(uint256 _amount) external onlyOwner nonReentrant whenNotPaused {
        require(_amount > 0, "DRF: Must withdraw a positive amount");
        require(address(this).balance >= _amount, "DRF: Insufficient balance in Foundry fund");
        
        (bool success,) = payable(owner()).call{value: _amount}("");
        require(success, "DRF: ETH transfer failed");

        emit FoundryFundWithdrawn(owner(), _amount);
    }

    /**
     * @dev Allows governance to adjust critical parameters of the Foundry.
     * @param _minReputationForVote_ New minimum reputation to cast a vote.
     * @param _minVotesForProposalApproval_ New minimum positive votes for proposal approval.
     * @param _minReviewsForProposal_ New minimum reviews needed before proposal voting.
     * @param _minReviewsForMilestone_ New minimum reviews needed before milestone voting.
     * @param _reviewPeriodDuration_ New duration for reviewers to submit their reviews.
     * @param _votingPeriodDuration_ New duration for governance voting.
     * @param _disputeEvidencePeriod_ New duration for parties to submit evidence in a dispute.
     * @param _disputeVotingPeriod_ New duration for governance to vote on a dispute.
     */
    function setGovernanceParameters(
        uint256 _minReputationForVote_,
        uint256 _minVotesForProposalApproval_,
        uint256 _minReviewsForProposal_,
        uint256 _minReviewsForMilestone_,
        uint256 _reviewPeriodDuration_,
        uint256 _votingPeriodDuration_,
        uint256 _disputeEvidencePeriod_,
        uint256 _disputeVotingPeriod_
    ) external onlyOwner whenNotPaused {
        require(_minReputationForVote_ > 0, "DRF: Min reputation must be > 0");
        require(_minVotesForProposalApproval_ > 0, "DRF: Min proposal votes must be > 0");
        require(_minReviewsForProposal_ > 0, "DRF: Min proposal reviews must be > 0");
        require(_minReviewsForMilestone_ > 0, "DRF: Min milestone reviews must be > 0");
        require(_reviewPeriodDuration_ > 0, "DRF: Review period must be > 0");
        require(_votingPeriodDuration_ > 0, "DRF: Voting period must be > 0");
        require(_disputeEvidencePeriod_ > 0, "DRF: Dispute evidence period must be > 0");
        require(_disputeVotingPeriod_ > 0, "DRF: Dispute voting period must be > 0");

        minReputationForVote = _minReputationForVote_;
        minVotesForProposalApproval = _minVotesForProposalApproval_;
        minReviewsForProposal = _minReviewsForProposal_;
        minReviewsForMilestone = _minReviewsForMilestone_;
        reviewPeriodDuration = _reviewPeriodDuration_;
        votingPeriodDuration = _votingPeriodDuration_;
        disputeEvidencePeriod = _disputeEvidencePeriod_;
        disputeVotingPeriod = _disputeVotingPeriod_;

        emit GovernanceParametersUpdated(
            _msgSender(),
            _minReputationForVote_,
            _minVotesForProposalApproval_,
            _minReviewsForProposal_,
            _minReviewsForMilestone_,
            _reviewPeriodDuration_,
            _votingPeriodDuration_,
            _disputeEvidencePeriod_,
            _disputeVotingPeriod_
        );
    }

    // --- II. Proposal Submission & Lifecycle ---

    /**
     * @dev Researchers submit a new proposal with details, funding goal, and milestones.
     * @param _title Title of the research proposal.
     * @param _descriptionHash IPFS hash of the detailed proposal description.
     * @param _fundingGoal Total ETH requested for the proposal.
     * @param _milestoneDescriptions Array of descriptions for each milestone.
     * @param _milestoneFundingAmounts Array of funding amounts for each milestone.
     * @param _milestoneExpectedCompletionDates Array of expected completion Unix timestamps for each milestone.
     */
    function submitResearchProposal(
        string memory _title,
        string memory _descriptionHash,
        uint256 _fundingGoal,
        string[] memory _milestoneDescriptions,
        uint256[] memory _milestoneFundingAmounts,
        uint64[] memory _milestoneExpectedCompletionDates
    ) external whenNotPaused nonReentrant {
        require(bytes(_title).length > 0, "DRF: Title cannot be empty");
        require(bytes(_descriptionHash).length > 0, "DRF: Description hash cannot be empty");
        require(_fundingGoal > 0, "DRF: Funding goal must be positive");
        require(_milestoneDescriptions.length > 0, "DRF: Must have at least one milestone");
        require(_milestoneDescriptions.length == _milestoneFundingAmounts.length, "DRF: Milestone data length mismatch");
        require(_milestoneDescriptions.length == _milestoneExpectedCompletionDates.length, "DRF: Milestone data length mismatch");

        uint256 totalMilestoneFunding;
        for (uint256 i = 0; i < _milestoneFundingAmounts.length; i++) {
            require(_milestoneFundingAmounts[i] > 0, "DRF: Milestone funding must be positive");
            require(_milestoneExpectedCompletionDates[i] > block.timestamp, "DRF: Milestone expected completion must be in the future");
            totalMilestoneFunding += _milestoneFundingAmounts[i];
        }
        require(totalMilestoneFunding == _fundingGoal, "DRF: Total milestone funding must equal funding goal");
        require(address(this).balance >= _fundingGoal, "DRF: Foundry fund too low for this proposal");


        uint256 currentProposalId = nextProposalId++;
        Proposal storage newProposal = proposals[currentProposalId];
        newProposal.id = currentProposalId;
        newProposal.researcher = _msgSender();
        newProposal.title = _title;
        newProposal.description = _descriptionHash;
        newProposal.fundingGoal = _fundingGoal;
        newProposal.status = ProposalStatus.Draft;
        newProposal.submittedAt = uint64(block.timestamp);
        newProposal.requiredReviews = minReviewsForProposal;

        for (uint256 i = 0; i < _milestoneDescriptions.length; i++) {
            uint256 currentMilestoneId = nextMilestoneId++;
            milestones[currentMilestoneId] = Milestone({
                id: currentMilestoneId,
                proposalId: currentProposalId,
                description: _milestoneDescriptions[i],
                fundingAmount: _milestoneFundingAmounts[i],
                status: MilestoneStatus.Pending,
                expectedCompletionDate: _milestoneExpectedCompletionDates[i],
                actualCompletionDate: 0,
                evidenceHash: bytes32(0),
                reviewCount: 0,
                approvalCount: 0
            });
            newProposal.milestoneIds.push(currentMilestoneId);
        }

        emit ProposalSubmitted(currentProposalId, _msgSender(), _title, _fundingGoal, _milestoneDescriptions.length);
    }

    /**
     * @dev Allows the researcher to update a proposal while it is in `Draft` status.
     *      Only non-critical details can be updated, and milestones cannot be modified after creation.
     * @param _proposalId The ID of the proposal to update.
     * @param _title New title.
     * @param _descriptionHash New description hash.
     */
    function updateProposalDraft(
        uint256 _proposalId,
        string memory _title,
        string memory _descriptionHash
    ) external onlyResearcher(_proposalId) whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Draft, "DRF: Proposal must be in Draft status to update");
        require(bytes(_title).length > 0, "DRF: Title cannot be empty");
        require(bytes(_descriptionHash).length > 0, "DRF: Description hash cannot be empty");

        proposal.title = _title;
        proposal.description = _descriptionHash;

        emit ProposalUpdated(_proposalId, _msgSender());
    }

    /**
     * @dev Moves a proposal from `Draft` to `SubmittedForReview` status.
     *      This makes it available for governance to assign reviewers.
     * @param _proposalId The ID of the proposal to submit for review.
     */
    function submitProposalForReview(uint256 _proposalId) external onlyResearcher(_proposalId) whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Draft, "DRF: Proposal must be in Draft status");

        proposal.status = ProposalStatus.SubmittedForReview;
        emit ProposalSubmittedForReview(_proposalId);
    }

    /**
     * @dev Retrieves details for a given proposal.
     * @param _proposalId The ID of the proposal.
     * @return Tuple containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            address researcher,
            string memory title,
            string memory description,
            uint256 fundingGoal,
            uint256 currentFundingReleased,
            uint256[] memory milestoneIds,
            ProposalStatus status,
            uint64 submittedAt,
            uint64 reviewPeriodEnd,
            uint256 requiredReviews,
            uint256 receivedReviews,
            uint256 approvalVotes,
            uint256 rejectionVotes
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "DRF: Proposal not found");

        return (
            proposal.id,
            proposal.researcher,
            proposal.title,
            proposal.description,
            proposal.fundingGoal,
            proposal.currentFundingReleased,
            proposal.milestoneIds,
            proposal.status,
            proposal.submittedAt,
            proposal.reviewPeriodEnd,
            proposal.requiredReviews,
            proposal.receivedReviews,
            proposal.approvalVotes,
            proposal.rejectionVotes
        );
    }

    // --- III. Review & Approval Process (Proposals) ---

    /**
     * @dev Governance assigns specific addresses as reviewers for a proposal.
     *      Moves proposal status to `UnderReview`.
     * @param _proposalId The ID of the proposal.
     * @param _reviewers Array of addresses to assign as reviewers.
     */
    function assignProposalReviewers(uint256 _proposalId, address[] memory _reviewers) external onlyOwner whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.SubmittedForReview, "DRF: Proposal not in 'SubmittedForReview' status");
        require(_reviewers.length > 0, "DRF: Must assign at least one reviewer");

        for (uint256 i = 0; i < _reviewers.length; i++) {
            require(reputationScores[_reviewers[i]] > 0, "DRF: Reviewer must have reputation");
            proposalReviewers[_proposalId][_reviewers[i]] = true;
        }

        proposal.status = ProposalStatus.UnderReview;
        proposal.reviewPeriodEnd = uint64(block.timestamp + reviewPeriodDuration);
        emit ProposalReviewersAssigned(_proposalId, _reviewers);
    }

    /**
     * @dev Assigned reviewers submit their assessment for a proposal.
     * @param _proposalId The ID of the proposal being reviewed.
     * @param _rating A numerical rating (e.g., 1-5, or 0=reject, 1=approve).
     * @param _commentHash Hash of off-chain comments.
     */
    function submitProposalReview(
        uint256 _proposalId,
        uint8 _rating,
        bytes32 _commentHash
    ) external onlyProposalReviewer(_proposalId) whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.UnderReview, "DRF: Proposal not in 'UnderReview' status");
        require(block.timestamp <= proposal.reviewPeriodEnd, "DRF: Proposal review period has ended");
        require(!proposal.hasReviewed[_msgSender()], "DRF: You have already reviewed this proposal");
        require(_rating >= 0 && _rating <= 5, "DRF: Rating must be between 0 and 5");

        uint256 currentReviewId = nextReviewId++;
        reviews[currentReviewId] = Review({
            id: currentReviewId,
            reviewer: _msgSender(),
            reviewType: ReviewType.Proposal,
            entityId: _proposalId,
            rating: _rating,
            commentHash: _commentHash,
            submittedAt: uint64(block.timestamp)
        });

        proposal.hasReviewed[_msgSender()] = true;
        proposal.receivedReviews++;
        // Award reputation for diligence
        reputationScores[_msgSender()] += 1;

        emit ProposalReviewSubmitted(_proposalId, currentReviewId, _msgSender(), _rating);
    }

    /**
     * @dev Reputation holders vote to approve or reject a proposal for funding.
     *      Can only vote after `minReviewsForProposal` have been submitted and `reviewPeriodEnd` has passed.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _approve True for approval, false for rejection.
     */
    function voteOnProposalApproval(uint256 _proposalId, bool _approve) external hasMinReputation whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "DRF: Proposal not found");
        require(proposal.status == ProposalStatus.UnderReview || proposal.status == ProposalStatus.SubmittedForReview, "DRF: Proposal not eligible for voting");
        require(block.timestamp > proposal.reviewPeriodEnd && proposal.receivedReviews >= proposal.requiredReviews, "DRF: Review period not ended or not enough reviews");
        require(!proposal.hasVoted[_msgSender()], "DRF: You have already voted on this proposal");

        if (_approve) {
            proposal.approvalVotes++;
        } else {
            proposal.rejectionVotes++;
        }
        proposal.hasVoted[_msgSender()] = true;
        reputationScores[_msgSender()] += 1; // Award reputation for active governance

        emit ProposalVoteCast(_proposalId, _msgSender(), _approve);
    }

    /**
     * @dev Finalizes the proposal decision based on votes. Can only be called after voting period.
     *      Sets the proposal's final status (`ApprovedForFunding` or `Rejected`).
     *      Researcher gets reputation for approved proposals.
     * @param _proposalId The ID of the proposal to finalize.
     */
    function finalizeProposalDecision(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "DRF: Proposal not found");
        require(proposal.status == ProposalStatus.UnderReview || proposal.status == ProposalStatus.SubmittedForReview, "DRF: Proposal not in voting stage");
        require(block.timestamp > (proposal.reviewPeriodEnd + votingPeriodDuration), "DRF: Voting period not ended");

        if (proposal.approvalVotes >= minVotesForProposalApproval && proposal.approvalVotes > proposal.rejectionVotes) {
            proposal.status = ProposalStatus.ApprovedForFunding;
            reputationScores[proposal.researcher] += 5; // Reward researcher for approved proposal
            // Milestone statuses remain Pending, funding is released per milestone completion
        } else {
            proposal.status = ProposalStatus.Rejected;
            // Optionally: refund any pre-staked funds by researcher if implemented
        }

        emit ProposalDecisionFinalized(_proposalId, proposal.status);
    }

    // --- IV. Milestone Management & Funding Release ---

    /**
     * @dev Researcher submits a milestone as complete, providing evidence.
     * @param _milestoneId The ID of the milestone to submit.
     * @param _evidenceHash Hash of the off-chain evidence for completion.
     */
    function submitMilestoneCompletion(uint256 _milestoneId, bytes32 _evidenceHash) external whenNotPaused {
        Milestone storage milestone = milestones[_milestoneId];
        require(milestone.id != 0, "DRF: Milestone not found");
        Proposal storage proposal = proposals[milestone.proposalId];
        require(proposal.researcher == _msgSender(), "DRF: Only researcher can submit milestone completion");
        require(proposal.status == ProposalStatus.ApprovedForFunding || proposal.status == ProposalStatus.InProgress, "DRF: Proposal not approved or in progress");
        require(milestone.status == MilestoneStatus.Pending || milestone.status == MilestoneStatus.Rejected, "DRF: Milestone not in Pending or Rejected status");
        require(_evidenceHash != bytes32(0), "DRF: Evidence hash cannot be empty");

        milestone.status = MilestoneStatus.SubmittedForReview;
        milestone.actualCompletionDate = uint64(block.timestamp);
        milestone.evidenceHash = _evidenceHash;
        milestone.reviewCount = 0; // Reset for new review cycle
        milestone.approvalCount = 0;
        // Clear previous votes/reviews
        delete milestone.hasReviewed;
        delete milestone.hasVoted;

        emit MilestoneCompletionSubmitted(_milestoneId, milestone.proposalId, _msgSender(), _evidenceHash);
    }

    /**
     * @dev Governance assigns reviewers for a submitted milestone completion.
     *      Moves milestone status to `UnderReview`.
     * @param _milestoneId The ID of the milestone.
     * @param _reviewers Array of addresses to assign as reviewers.
     */
    function assignMilestoneReviewers(uint256 _milestoneId, address[] memory _reviewers) external onlyOwner whenNotPaused {
        Milestone storage milestone = milestones[_milestoneId];
        require(milestone.status == MilestoneStatus.SubmittedForReview, "DRF: Milestone not in 'SubmittedForReview' status");
        require(_reviewers.length > 0, "DRF: Must assign at least one reviewer");

        for (uint256 i = 0; i < _reviewers.length; i++) {
            require(reputationScores[_reviewers[i]] > 0, "DRF: Reviewer must have reputation");
            milestoneReviewers[_milestoneId][_reviewers[i]] = true;
        }

        milestone.status = MilestoneStatus.UnderReview;
        // No explicit review period end for milestones; voting starts when enough reviews.
        emit MilestoneReviewersAssigned(_milestoneId, _reviewers);
    }

    /**
     * @dev Assigned reviewers submit their assessment for a completed milestone.
     * @param _milestoneId The ID of the milestone being reviewed.
     * @param _rating A numerical rating (e.g., 0=reject, 1=approve).
     * @param _commentHash Hash of off-chain comments.
     */
    function submitMilestoneReview(
        uint256 _milestoneId,
        uint8 _rating,
        bytes32 _commentHash
    ) external onlyMilestoneReviewer(_milestoneId) whenNotPaused {
        Milestone storage milestone = milestones[_milestoneId];
        require(milestone.status == MilestoneStatus.UnderReview, "DRF: Milestone not in 'UnderReview' status");
        require(!milestone.hasReviewed[_msgSender()], "DRF: You have already reviewed this milestone");
        require(_rating == 0 || _rating == 1, "DRF: Rating must be 0 (reject) or 1 (approve)");

        uint256 currentReviewId = nextReviewId++;
        reviews[currentReviewId] = Review({
            id: currentReviewId,
            reviewer: _msgSender(),
            reviewType: ReviewType.Milestone,
            entityId: _milestoneId,
            rating: _rating,
            commentHash: _commentHash,
            submittedAt: uint64(block.timestamp)
        });

        milestone.hasReviewed[_msgSender()] = true;
        milestone.reviewCount++;
        if (_rating == 1) {
            milestone.approvalCount++;
        }
        reputationScores[_msgSender()] += 1;

        emit MilestoneReviewSubmitted(_milestoneId, currentReviewId, _msgSender(), _rating);
    }

    /**
     * @dev Reputation holders vote to approve or reject a milestone completion.
     *      Can only vote after `minReviewsForMilestone` have been submitted.
     * @param _milestoneId The ID of the milestone to vote on.
     * @param _approve True for approval, false for rejection.
     */
    function voteOnMilestoneRelease(uint256 _milestoneId, bool _approve) external hasMinReputation whenNotPaused {
        Milestone storage milestone = milestones[_milestoneId];
        require(milestone.id != 0, "DRF: Milestone not found");
        require(milestone.status == MilestoneStatus.UnderReview || milestone.status == MilestoneStatus.SubmittedForReview, "DRF: Milestone not eligible for voting");
        require(milestone.reviewCount >= minReviewsForMilestone, "DRF: Not enough reviews submitted for this milestone");
        require(!milestone.hasVoted[_msgSender()], "DRF: You have already voted on this milestone");

        if (_approve) {
            milestone.approvalCount++; // Re-use approvalCount for votes, assuming 1 vote = 1 approval weight
        } else {
            // For rejection, we don't need a specific counter, just lack of approval is enough.
            // Could add a rejection counter if needed.
        }
        milestone.hasVoted[_msgSender()] = true;
        reputationScores[_msgSender()] += 1;

        emit MilestoneVoteCast(_milestoneId, milestone.proposalId, _msgSender(), _approve);
    }

    /**
     * @dev Finalizes the milestone decision based on votes. If approved, releases funding.
     *      If rejected, the researcher must resubmit or initiate a dispute.
     * @param _milestoneId The ID of the milestone to finalize.
     */
    function finalizeMilestoneDecision(uint256 _milestoneId) external whenNotPaused nonReentrant {
        Milestone storage milestone = milestones[_milestoneId];
        require(milestone.id != 0, "DRF: Milestone not found");
        require(milestone.status == MilestoneStatus.UnderReview || milestone.status == MilestoneStatus.SubmittedForReview, "DRF: Milestone not in voting stage");
        require(milestone.reviewCount >= minReviewsForMilestone, "DRF: Not enough reviews to finalize");
        // We assume voting period is implicit with calls. Or add a timestamp check.
        // For simplicity, any address can call this once enough votes are in.

        if (milestone.approvalCount >= minVotesForProposalApproval) { // Re-using proposal approval threshold for simplicity
            milestone.status = MilestoneStatus.Approved;
            _releaseMilestoneFunding(_milestoneId);
            reputationScores[proposals[milestone.proposalId].researcher] += 3; // Reward researcher for milestone
            // Check if all milestones are complete
            Proposal storage proposal = proposals[milestone.proposalId];
            bool allMilestonesCompleted = true;
            for(uint i=0; i < proposal.milestoneIds.length; i++) {
                if(milestones[proposal.milestoneIds[i]].status != MilestoneStatus.Approved) {
                    allMilestonesCompleted = false;
                    break;
                }
            }
            if (allMilestonesCompleted) {
                proposal.status = ProposalStatus.Completed;
                reputationScores[proposal.researcher] += 10; // Extra reward for full completion
            } else {
                proposal.status = ProposalStatus.InProgress;
            }

        } else {
            milestone.status = MilestoneStatus.Rejected;
        }

        emit MilestoneDecisionFinalized(_milestoneId, milestone.status);
    }

    /**
     * @dev Internal function to release funds for an approved milestone.
     * @param _milestoneId The ID of the milestone.
     */
    function _releaseMilestoneFunding(uint256 _milestoneId) internal {
        Milestone storage milestone = milestones[_milestoneId];
        Proposal storage proposal = proposals[milestone.proposalId];
        
        require(milestone.status == MilestoneStatus.Approved, "DRF: Milestone not approved for funding");
        require(address(this).balance >= milestone.fundingAmount, "DRF: Insufficient Foundry fund for milestone");

        (bool success,) = payable(proposal.researcher).call{value: milestone.fundingAmount}("");
        require(success, "DRF: Milestone funding transfer failed");

        proposal.currentFundingReleased += milestone.fundingAmount;
        emit MilestoneFundingReleased(_milestoneId, milestone.proposalId, proposal.researcher, milestone.fundingAmount);
    }

    // --- V. Dispute Resolution & Arbitration ---

    /**
     * @dev Allows a researcher or reviewer to initiate a dispute for a milestone.
     * @param _milestoneId The ID of the milestone being disputed.
     * @param _reasonHash Hash of the reason for dispute.
     * @param _defendant The address against whom the dispute is initiated.
     */
    function initiateMilestoneDispute(
        uint256 _milestoneId,
        bytes32 _reasonHash,
        address _defendant
    ) external whenNotPaused {
        Milestone storage milestone = milestones[_milestoneId];
        require(milestone.id != 0, "DRF: Milestone not found");
        require(milestone.status == MilestoneStatus.SubmittedForReview || milestone.status == MilestoneStatus.Rejected || milestone.status == MilestoneStatus.UnderReview, "DRF: Milestone not in a disputable state");
        require(_reasonHash != bytes32(0), "DRF: Reason hash cannot be empty");
        require(_defendant != address(0), "DRF: Defendant address cannot be zero");
        require(_msgSender() != _defendant, "DRF: Cannot dispute yourself");

        // Ensure only relevant parties can initiate
        bool isResearcher = (proposals[milestone.proposalId].researcher == _msgSender());
        bool isReviewer = milestoneReviewers[_milestoneId][_msgSender()];
        require(isResearcher || isReviewer, "DRF: Only researcher or assigned reviewer can initiate dispute");

        // Prevent duplicate disputes for the same milestone
        for (uint i = 1; i < nextDisputeId; i++) {
            if (disputes[i].milestoneId == _milestoneId && disputes[i].status != DisputeStatus.Resolved) {
                revert("DRF: A dispute is already active for this milestone");
            }
        }

        uint256 currentDisputeId = nextDisputeId++;
        disputes[currentDisputeId] = Dispute({
            id: currentDisputeId,
            proposalId: milestone.proposalId,
            milestoneId: _milestoneId,
            initiator: _msgSender(),
            defendant: _defendant,
            reasonHash: _reasonHash,
            evidenceHashes: new bytes32[](0),
            status: DisputeStatus.Open,
            initiatedAt: uint64(block.timestamp),
            evidencePeriodEnd: uint64(block.timestamp + disputeEvidencePeriod),
            votingPeriodEnd: 0, // Set after evidence submission
            initiatorVotes: 0,
            defendantVotes: 0
        });

        milestone.status = MilestoneStatus.Disputed; // Set milestone to disputed status
        emit DisputeInitiated(currentDisputeId, _milestoneId, _msgSender(), _defendant);
    }

    /**
     * @dev Parties involved in an open dispute submit their cryptographic evidence hashes.
     * @param _disputeId The ID of the dispute.
     * @param _evidenceHash Hash of the evidence.
     */
    function submitDisputeEvidence(uint256 _disputeId, bytes32 _evidenceHash) external whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "DRF: Dispute not found");
        require(dispute.status == DisputeStatus.Open, "DRF: Dispute not in Open status");
        require(_msgSender() == dispute.initiator || _msgSender() == dispute.defendant, "DRF: Only initiator or defendant can submit evidence");
        require(block.timestamp <= dispute.evidencePeriodEnd, "DRF: Evidence submission period has ended");
        require(_evidenceHash != bytes32(0), "DRF: Evidence hash cannot be empty");

        dispute.evidenceHashes.push(_evidenceHash);

        // If both parties have submitted or time is up, move to voting
        if (dispute.evidenceHashes.length >= 2 || block.timestamp > dispute.evidencePeriodEnd) {
             dispute.status = DisputeStatus.UnderVote;
             dispute.votingPeriodEnd = uint64(block.timestamp + disputeVotingPeriod);
        }
        
        emit DisputeEvidenceSubmitted(_disputeId, _msgSender(), _evidenceHash);
    }

    /**
     * @dev Reputation holders vote on the outcome of an ongoing dispute.
     * @param _disputeId The ID of the dispute.
     * @param _forInitiator True if voting for the initiator's side, false for the defendant's side.
     */
    function voteOnDisputeOutcome(uint256 _disputeId, bool _forInitiator) external hasMinReputation whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "DRF: Dispute not found");
        require(dispute.status == DisputeStatus.UnderVote || (dispute.status == DisputeStatus.EvidenceSubmitted && block.timestamp > dispute.evidencePeriodEnd), "DRF: Dispute not in voting stage");
        require(block.timestamp <= dispute.votingPeriodEnd, "DRF: Dispute voting period has ended");
        require(!dispute.hasVoted[_msgSender()], "DRF: You have already voted on this dispute");
        require(_msgSender() != dispute.initiator && _msgSender() != dispute.defendant, "DRF: Initiator or defendant cannot vote on their own dispute");

        if (_forInitiator) {
            dispute.initiatorVotes++;
        } else {
            dispute.defendantVotes++;
        }
        dispute.hasVoted[_msgSender()] = true;
        reputationScores[_msgSender()] += 1;

        emit DisputeVoteCast(_disputeId, _msgSender(), _forInitiator);
    }

    /**
     * @dev Finalizes a dispute based on the voting outcome.
     *      Can result in overriding previous milestone decisions, penalizing parties, etc.
     * @param _disputeId The ID of the dispute to resolve.
     */
    function resolveDispute(uint256 _disputeId) external whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "DRF: Dispute not found");
        require(dispute.status == DisputeStatus.UnderVote, "DRF: Dispute not in voting stage");
        require(block.timestamp > dispute.votingPeriodEnd, "DRF: Dispute voting period not ended");

        Milestone storage milestone = milestones[dispute.milestoneId];
        
        if (dispute.initiatorVotes > dispute.defendantVotes) {
            // Initiator wins: e.g., if researcher initiated dispute over rejected milestone
            // this could mean reversing the rejection or penalizing reviewer.
            // For simplicity, if initiator wins and milestone was rejected, mark it as Pending for resubmission or approved based on context.
            if (milestone.status == MilestoneStatus.Rejected) {
                milestone.status = MilestoneStatus.Pending; // Allows researcher to resubmit without new dispute
            } else if (milestone.status == MilestoneStatus.UnderReview || milestone.status == MilestoneStatus.SubmittedForReview) {
                // If dispute was initiated due to review process, and initiator wins, approve it.
                milestone.status = MilestoneStatus.Approved;
                _releaseMilestoneFunding(dispute.milestoneId);
            }
            // Optionally: Penalize defendant's reputation
            if (reputationScores[dispute.defendant] >= 2) reputationScores[dispute.defendant] -= 2;

            reputationScores[dispute.initiator] += 2; // Reward winning initiator
            emit DisputeResolved(_disputeId, DisputeStatus.Resolved, true);
        } else if (dispute.defendantVotes > dispute.initiatorVotes) {
            // Defendant wins: e.g., if reviewer initiated dispute over bad completion
            // For simplicity, if defendant wins, milestone remains Rejected (if it was) or is explicitly Rejected
            if (milestone.status != MilestoneStatus.Approved) {
                milestone.status = MilestoneStatus.Rejected;
            }
            // Optionally: Penalize initiator's reputation
            if (reputationScores[dispute.initiator] >= 2) reputationScores[dispute.initiator] -= 2;

            reputationScores[dispute.defendant] += 2; // Reward winning defendant
            emit DisputeResolved(_disputeId, DisputeStatus.Resolved, false);
        } else {
            // Tie or no votes - default to previous state or neutral outcome
            // Milestone remains in current status (e.g. Rejected or SubmittedForReview)
            emit DisputeResolved(_disputeId, DisputeStatus.Resolved, false); // No clear winner
        }

        dispute.status = DisputeStatus.Resolved;
    }

    // --- VI. Reputation & Administration ---

    /**
     * @dev Owner/Governance can manually award reputation points.
     * @param _user The address to award reputation to.
     * @param _amount The amount of reputation points.
     */
    function grantReputation(address _user, uint256 _amount) external onlyOwner whenNotPaused {
        require(_user != address(0), "DRF: Invalid user address");
        require(_amount > 0, "DRF: Amount must be positive");
        reputationScores[_user] += _amount;
        emit ReputationGranted(_user, _amount, _msgSender());
    }

    /**
     * @dev Owner/Governance can manually revoke reputation points.
     * @param _user The address to revoke reputation from.
     * @param _amount The amount of reputation points.
     */
    function revokeReputation(address _user, uint256 _amount) external onlyOwner whenNotPaused {
        require(_user != address(0), "DRF: Invalid user address");
        require(_amount > 0, "DRF: Amount must be positive");
        require(reputationScores[_user] >= _amount, "DRF: Insufficient reputation to revoke");
        reputationScores[_user] -= _amount;
        emit ReputationRevoked(_user, _amount, _msgSender());
    }

    /**
     * @dev Returns the reputation score of an address.
     * @param _user The address to check.
     * @return The reputation score.
     */
    function getReputationScore(address _user) external view returns (uint256) {
        return reputationScores[_user];
    }

    /**
     * @dev Pauses the contract, disabling most mutable functions.
     *      Can only be called by the owner.
     */
    function emergencyPause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract, enabling mutable functions again.
     *      Can only be called by the owner.
     */
    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Transfers ownership of the contract to a new address.
     *      Can only be called by the current owner.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "DRF: New owner cannot be the zero address");
        // Optionally, transfer owner's reputation to new owner, or reset to 0
        reputationScores[newOwner] += reputationScores[owner()];
        reputationScores[owner()] = 0;
        super.transferOwnership(newOwner);
    }
}
```