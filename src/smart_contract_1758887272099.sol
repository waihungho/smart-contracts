```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SyntheticaNexus - A Decentralized AI/ZK-Powered Research & Development Lab
 * @author [Your Name/Alias]
 * @notice This contract orchestrates a decentralized platform for research and development.
 *         It enables the submission, funding, and execution of research proposals,
 *         integrating advanced concepts like ZK-proofs for privacy-preserving submissions,
 *         AI-driven oracles for peer review, and a dynamic reputation system.
 *         It aims to foster innovation in a trustless and censorship-resistant manner.
 *
 * @dev This is a conceptual contract designed to showcase advanced features.
 *      Actual integration with external ZK verifier contracts, AI oracles, and
 *      complex cross-chain mechanisms would require further specialized implementations.
 *      Error handling, comprehensive access control, and edge cases are simplified
 *      for readability and focus on the core concepts.
 *      It uses mock interfaces for IZKVerifier and IAIOracle.
 */

// --- OUTLINE ---
// 1.  Interfaces (Conceptual for ZK Verifier, AI Oracle, ERC20)
// 2.  Errors
// 3.  Events
// 4.  Enums & Structs
// 5.  Core Contract State Variables
// 6.  Constructor
// 7.  External Contract Integration & Admin Functions
// 8.  Research Proposal Lifecycle Functions
// 9.  Review & Dispute Resolution Functions
// 10. Reputation & Role Management Functions
// 11. Governance & Parameter Adjustment Functions
// 12. Utility & Information Functions
// 13. Emergency Pause Functionality

// --- FUNCTION SUMMARY ---

// I. External Contract Integration & Admin Functions (5 functions)
// 1.  constructor(address _token, address _zkVerifier, address _aiOracle, address _initialFeeRecipient): Initializes the contract with token, verifier, oracle addresses, and fee recipient.
// 2.  updateOracleAddress(address _newOracle): Admin function to update the AI Oracle contract address.
// 3.  updateZKVerifierAddress(address _newVerifier): Admin function to update the ZK Verifier contract address.
// 4.  setProtocolFeeRecipient(address _newRecipient): Admin function to change the recipient of protocol fees.
// 5.  setProtocolFeeRate(uint256 _newRatePermil): Admin function to set the protocol fee rate (in per mille, e.g., 100 for 10%).

// II. Research Proposal Lifecycle Functions (10 functions)
// 6.  submitResearchProposal(string memory _title, string memory _description, uint256 _fundingGoal, uint256 _rewardAmount, bytes32 _zkProofSchemaHash, uint256 _deadline): Allows users to submit a new research proposal.
// 7.  fundProposal(uint256 _proposalId, uint256 _amount): Allows users to contribute funds to a specific proposal.
// 8.  approveProposal(uint256 _proposalId): Allows governance stakers to vote for approving a proposal to move to 'InProgress'.
// 9.  submitInterimResultProof(uint256 _proposalId, bytes memory _proof): Researchers submit a ZK proof of interim progress. (Requires _proof to be verifiable by IZKVerifier)
// 10. requestAIReview(uint256 _proposalId, bytes32 _submissionHash): Triggers an AI Oracle review for a submission (interim or final).
// 11. submitFinalSolutionProof(uint256 _proposalId, bytes memory _proof, bytes32 _solutionHash): Researcher submits final solution via ZK proof, associating a unique hash. (Requires _proof to be verifiable by IZKVerifier)
// 12. markProjectCompletion(uint256 _proposalId, address[] memory _reviewers): Marks a project as completed and triggers fund distribution. Requires prior successful AI/ZK review.
// 13. claimReward(uint256 _proposalId): Allows the researcher to claim their reward once the project is marked complete.
// 14. refundUnusedProposalFunds(uint256 _proposalId): Allows proposers or funders to reclaim funds if a proposal fails to get approved or funded within its deadline.
// 15. extendProposalDeadline(uint256 _proposalId, uint256 _newDeadline): Governance-approved extension of a proposal's deadline.

// III. Review & Dispute Resolution Functions (5 functions)
// 16. stakeForReviewerRole(uint256 _amount): Allows users to stake tokens to become an eligible reviewer.
// 17. unstakeFromReviewerRole(): Allows reviewers to unstake their tokens if not actively reviewing or in dispute.
// 18. challengeReviewDecision(uint256 _proposalId, uint256 _reviewIndex, string memory _reason): Initiates a dispute over an AI review decision.
// 19. voteOnDispute(uint256 _disputeId, bool _supportClaimant): Governance stakers vote on an ongoing dispute.
// 20. resolveDispute(uint256 _disputeId): Admin/governance function to finalize a dispute resolution after voting.

// IV. Reputation & Role Management Functions (2 functions)
// 21. getResearcherReputation(address _researcher): Returns the reputation score of a given researcher.
// 22. updateResearcherProfile(string memory _ipfsHash): Allows researchers to link an IPFS hash to their profile for public information.

// V. Governance & Parameter Adjustment Functions (5 functions)
// 23. stakeForGovernance(uint256 _amount): Allows users to stake tokens to participate in governance (voting).
// 24. unstakeFromGovernance(): Allows governance stakers to unstake their tokens.
// 25. proposeParameterChange(bytes32 _paramKey, uint256 _newValue): Allows governance stakers to propose a change to a system parameter. (e.g., "proposalVotingThreshold", 100)
// 26. voteOnParameterChange(bytes32 _paramHash, bool _approve): Allows governance stakers to vote on a proposed parameter change.
// 27. executeParameterChange(bytes32 _paramHash): Admin/governance function to execute a successful parameter change proposal.

// VI. Utility & Information Functions (3 functions)
// 28. getRequiredProofSchemaHash(uint256 _proposalId): Returns the ZK proof schema hash required for a specific proposal.
// 29. markSolutionAsKnowledgeBaseEntry(bytes32 _solutionHash): (Internal/Admin) Marks a successfully verified solution hash as an entry in the knowledge base.
// 30. registerCrossChainKnowledgeLink(bytes32 _solutionHash, string memory _chainIdentifier, string memory _externalLink): Conceptually registers a link to cross-chain knowledge related to a solution.

// VII. Emergency Pause Functionality (2 functions)
// 31. emergencyPause(): Allows the designated owner to pause critical functions in case of emergency.
// 32. unpause(): Allows the designated owner to unpause the contract.

// --- INTERFACES ---

interface IZKVerifier {
    function verifyProof(bytes memory _proof, bytes32 _publicInputsHash) external view returns (bool);
}

interface IAIOracle {
    // A simplified interface. In reality, this would likely be an Oracle-managed
    // request/response pattern with callback or push.
    function requestReview(uint256 _proposalId, bytes32 _submissionHash) external returns (uint256 reviewRequestId);
    function getReviewScore(uint256 _reviewRequestId) external view returns (int256 score); // e.g. -100 to 100
}

// --- ERRORS ---

error SyntheticaNexus__ZeroAddress();
error SyntheticaNexus__InvalidAmount();
error SyntheticaNexus__InvalidDeadline();
error SyntheticaNexus__ProposalNotFound();
error SyntheticaNexus__ProposalNotInStatus(uint256 proposalId, string expectedStatus, string currentStatus);
error SyntheticaNexus__FundingNotMet();
error SyntheticaNexus__DeadlinePassed();
error SyntheticaNexus__AlreadyVoted();
error SyntheticaNexus__InsufficientStake();
error SyntheticaNexus__NotAReviewer();
error SyntheticaNexus__ReviewNotFound();
error SyntheticaNexus__NotProposer();
error SyntheticaNexus__NotApprovedForFunding();
error SyntheticaNexus__NotEnoughVotes();
error SyntheticaNexus__DisputeNotFound();
error SyntheticaNexus__DisputeNotOpen();
error SyntheticaNexus__SolutionAlreadyRegistered();
error SyntheticaNexus__InvalidProof();
error SyntheticaNexus__AIReviewPending();
error SyntheticaNexus__AIReviewScoreInvalid();
error SyntheticaNexus__ParamKeyNotRecognized();
error SyntheticaNexus__ParamChangeProposalNotFound();
error SyntheticaNexus__ProposalAlreadyApproved();
error SyntheticaNexus__NotEnoughGovernanceStake();
error SyntheticaNexus__ReviewerHasActiveDispute();
error SyntheticaNexus__AlreadyCompleted();
error SyntheticaNexus__NotEnoughFundsToClaim();
error SyntheticaNexus__CannotRefundApprovedProposal();
error SyntheticaNexus__ProposalNotReadyForCompletion();


// --- EVENTS ---

event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, uint256 fundingGoal, uint256 deadline);
event ProposalFunded(uint256 indexed proposalId, address indexed funder, uint256 amount, uint256 totalFunds);
event ProposalApproved(uint256 indexed proposalId, address indexed approver);
event ProposalStatusChanged(uint256 indexed proposalId, string oldStatus, string newStatus);
event InterimResultProofSubmitted(uint256 indexed proposalId, address indexed researcher, bytes32 publicInputsHash);
event AIReviewRequested(uint256 indexed proposalId, uint256 indexed reviewRequestId, bytes32 submissionHash);
event AIReviewCompleted(uint256 indexed proposalId, uint256 indexed reviewRequestId, int256 score);
event FinalSolutionProofSubmitted(uint256 indexed proposalId, address indexed researcher, bytes32 solutionHash);
event ProjectCompleted(uint256 indexed proposalId, address indexed researcher, uint256 rewardAmount);
event RewardClaimed(uint256 indexed proposalId, address indexed claimant, uint256 amount);
event FundsRefunded(uint256 indexed proposalId, address indexed recipient, uint256 amount);
event ReviewerStaked(address indexed reviewer, uint256 amount);
event ReviewerUnstaked(address indexed reviewer, uint256 amount);
event ReviewDecisionChallenged(uint256 indexed disputeId, uint256 indexed proposalId, address indexed claimant, uint256 reviewIndex);
event DisputeVoted(uint256 indexed disputeId, address indexed voter, bool supportClaimant);
event DisputeResolved(uint256 indexed disputeId, bool resolvedForClaimant);
event ReputationUpdated(address indexed user, int256 newReputation);
event ProfileUpdated(address indexed user, string ipfsHash);
event GovernanceStaked(address indexed staker, uint256 amount);
event GovernanceUnstaked(address indexed staker, uint256 amount);
event ParameterChangeProposed(bytes32 indexed paramHash, bytes32 paramKey, uint256 newValue, address indexed proposer);
event ParameterChangeVoted(bytes32 indexed paramHash, address indexed voter, bool approved);
event ParameterChangeExecuted(bytes32 indexed paramHash, bytes32 paramKey, uint256 newValue);
event ProposalDeadlineExtended(uint256 indexed proposalId, uint256 oldDeadline, uint256 newDeadline);
event KnowledgeBaseEntryAdded(bytes32 indexed solutionHash, uint256 indexed proposalId);
event CrossChainKnowledgeLinkRegistered(bytes32 indexed solutionHash, string chainIdentifier, string externalLink);
event Paused(address account);
event Unpaused(address account);

contract SyntheticaNexus is Ownable, ReentrancyGuard {

    // --- ENUMS & STRUCTS ---

    enum ProposalStatus {
        Proposed,       // Just submitted
        Funding,        // Open for funding, waiting for governance approval
        Approved,       // Funded & approved, work can begin
        InProgress,     // Researcher is actively working, might submit interim proofs
        Reviewing,      // Waiting for AI review of a submission (interim or final)
        Completed,      // Final solution accepted, rewards can be claimed
        Rejected,       // Proposal rejected by governance or failed to fund
        Disputed        // A review decision is under dispute
    }

    enum DisputeStatus {
        Open,
        ResolvedForClaimant,
        ResolvedAgainstClaimant
    }

    struct Review {
        address reviewer;        // The actual entity/account who requested the review (could be anyone, or specifically assigned)
        uint256 reviewRequestId; // ID from the AI Oracle for this specific review
        bytes32 submissionHash;  // Hash of the data submitted for review (e.g., IPFS hash of ZK public inputs)
        int256 aiScore;          // Score provided by the AI Oracle (-100 to 100, for example)
        uint256 timestamp;
        bool disputeInitiated;   // True if a dispute has been opened for this review
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description; // IPFS hash or short description
        uint256 fundingGoal; // Total funds required
        uint256 currentFunds; // Funds collected so far
        uint256 rewardAmount; // Amount specifically for the researcher upon completion
        uint256 protocolFee; // Protocol fee collected if proposal completes
        ProposalStatus status;
        uint256 deadline; // Deadline for funding/approval
        bytes32 zkProofSchemaHash; // Expected schema hash for ZK proofs for this project
        uint256 completionTimestamp; // When the project was marked complete
        address[] funders; // List of addresses who funded
        mapping(address => uint256) funderAmounts; // Amount contributed by each funder
        mapping(address => bool) governanceVotesForApproval; // Track governance votes for approval
        uint256 votesForApproval;
        Review[] reviews; // List of all interim/final reviews
        bytes32 finalSolutionHash; // The hash of the final solution, once accepted
        address[] assignedReviewers; // Reviewers assigned (or who claimed review bounties) for this project
        uint256 totalReviewerReward; // Total allocated for reviewers for this proposal
    }

    struct Dispute {
        uint256 disputeId;
        uint256 proposalId;
        address claimant; // Who initiated the dispute
        uint256 reviewIndex; // The specific review being challenged
        string reason; // IPFS hash or short reason
        uint256 votesForClaimant;
        uint256 votesAgainstClaimant;
        mapping(address => bool) hasVoted; // Track who voted
        uint256 deadline;
        DisputeStatus status;
    }

    struct ParameterChangeProposal {
        bytes32 paramKey;
        uint256 newValue;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        uint256 deadline;
        bool executed;
    }

    // --- CORE CONTRACT STATE VARIABLES ---

    IERC20 public immutable token;
    IZKVerifier public zkVerifier;
    IAIOracle public aiOracle;

    address public protocolFeeRecipient;
    uint256 public protocolFeeRatePermil; // e.g., 100 for 10%, 50 for 5%

    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;

    uint256 public nextDisputeId;
    mapping(uint256 => Dispute) public disputes;

    uint256 public proposalVotingThreshold; // Minimum governance votes (or total staked value) needed for proposal approval
    uint256 public disputeVotingThreshold;  // Minimum governance votes (or total staked value) needed to resolve a dispute

    // Reputation system: Higher for good contributions, lower for bad
    mapping(address => int256) public reputations;

    // Reviewer role management
    uint256 public minReviewerStake;
    mapping(address => uint256) public reviewerStakes; // Amount staked by a reviewer
    mapping(address => bool) public hasActiveDisputeAsReviewer; // If a reviewer has a dispute, they can't unstake

    // Governance role management
    mapping(address => uint256) public governanceStakes; // Amount staked for governance voting
    mapping(address => string) public researcherProfiles; // IPFS hash for public profiles

    // Knowledge Base to prevent direct duplication (conceptual)
    mapping(bytes32 => bool) public knowledgeBaseEntries;
    mapping(bytes32 => address) public knowledgeBaseEntryAuthor; // Author of the solution hash

    // Parameter Change Governance
    mapping(bytes32 => ParameterChangeProposal) public pendingParameterChanges;

    // Emergency Pause
    bool public paused;

    // --- MODIFIERS ---

    modifier onlyIfGovernanceStaker() {
        if (governanceStakes[msg.sender] == 0) revert SyntheticaNexus__NotEnoughGovernanceStake();
        _;
    }

    modifier onlyIfReviewer() {
        if (reviewerStakes[msg.sender] == 0) revert SyntheticaNexus__NotAReviewer();
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    // --- CONSTRUCTOR ---

    constructor(address _token, address _zkVerifier, address _aiOracle, address _initialFeeRecipient)
        Ownable(msg.sender) { // Initialize Ownable with deployer as owner
        if (_token == address(0) || _zkVerifier == address(0) || _aiOracle == address(0) || _initialFeeRecipient == address(0)) {
            revert SyntheticaNexus__ZeroAddress();
        }
        token = IERC20(_token);
        zkVerifier = IZKVerifier(_zkVerifier);
        aiOracle = IAIOracle(_aiOracle);
        protocolFeeRecipient = _initialFeeRecipient;

        // Initialize default parameters
        protocolFeeRatePermil = 50; // 5% fee
        proposalVotingThreshold = 100 ether; // Example: 100 tokens staked needed to influence vote significantly
        disputeVotingThreshold = 50 ether;
        minReviewerStake = 10 ether; // Example: 10 tokens to become a reviewer
        paused = false;

        nextProposalId = 1;
        nextDisputeId = 1;
    }

    // --- I. External Contract Integration & Admin Functions ---

    /**
     * @notice Admin function to update the AI Oracle contract address.
     * @param _newOracle The new address of the AI Oracle contract.
     */
    function updateOracleAddress(address _newOracle) external onlyOwner notPaused {
        if (_newOracle == address(0)) revert SyntheticaNexus__ZeroAddress();
        aiOracle = IAIOracle(_newOracle);
    }

    /**
     * @notice Admin function to update the ZK Verifier contract address.
     * @param _newVerifier The new address of the ZK Verifier contract.
     */
    function updateZKVerifierAddress(address _newVerifier) external onlyOwner notPaused {
        if (_newVerifier == address(0)) revert SyntheticaNexus__ZeroAddress();
        zkVerifier = IZKVerifier(_newVerifier);
    }

    /**
     * @notice Admin function to change the recipient of protocol fees.
     * @param _newRecipient The new address for protocol fees.
     */
    function setProtocolFeeRecipient(address _newRecipient) external onlyOwner notPaused {
        if (_newRecipient == address(0)) revert SyntheticaNexus__ZeroAddress();
        protocolFeeRecipient = _newRecipient;
    }

    /**
     * @notice Admin function to set the protocol fee rate.
     * @param _newRatePermil The new fee rate in per mille (e.g., 100 for 10%). Max 1000.
     */
    function setProtocolFeeRate(uint256 _newRatePermil) external onlyOwner notPaused {
        if (_newRatePermil > 1000) revert SyntheticaNexus__InvalidAmount(); // Max 100%
        protocolFeeRatePermil = _newRatePermil;
    }

    // --- II. Research Proposal Lifecycle Functions ---

    /**
     * @notice Allows users to submit a new research proposal.
     * @param _title The title of the proposal.
     * @param _description A short description or IPFS hash of a detailed description.
     * @param _fundingGoal The total amount of tokens required for the project.
     * @param _rewardAmount The specific amount of tokens allocated as reward for the researcher.
     * @param _zkProofSchemaHash A hash representing the expected ZK proof schema for submissions.
     * @param _deadline The timestamp by which the proposal needs to be funded and approved.
     */
    function submitResearchProposal(
        string memory _title,
        string memory _description,
        uint256 _fundingGoal,
        uint256 _rewardAmount,
        bytes32 _zkProofSchemaHash,
        uint256 _deadline
    ) external notPaused {
        if (bytes(_title).length == 0 || bytes(_description).length == 0) revert SyntheticaNexus__InvalidAmount();
        if (_fundingGoal == 0 || _rewardAmount == 0) revert SyntheticaNexus__InvalidAmount();
        if (_deadline <= block.timestamp) revert SyntheticaNexus__InvalidDeadline();
        if (_rewardAmount >= _fundingGoal) revert SyntheticaNexus__InvalidAmount(); // Reward must be less than total goal

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];

        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.fundingGoal = _fundingGoal;
        newProposal.rewardAmount = _rewardAmount;
        newProposal.status = ProposalStatus.Proposed;
        newProposal.deadline = _deadline;
        newProposal.zkProofSchemaHash = _zkProofSchemaHash;
        newProposal.protocolFee = (_fundingGoal - _rewardAmount) * protocolFeeRatePermil / 1000;
        newProposal.totalReviewerReward = (_fundingGoal - _rewardAmount) - newProposal.protocolFee;

        emit ProposalSubmitted(proposalId, msg.sender, _fundingGoal, _deadline);
    }

    /**
     * @notice Allows users to contribute funds to a specific proposal.
     * @param _proposalId The ID of the proposal to fund.
     * @param _amount The amount of tokens to contribute.
     */
    function fundProposal(uint256 _proposalId, uint256 _amount) external nonReentrant notPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert SyntheticaNexus__ProposalNotFound();
        if (_amount == 0) revert SyntheticaNexus__InvalidAmount();
        if (proposal.status != ProposalStatus.Proposed && proposal.status != ProposalStatus.Funding) {
            revert SyntheticaNexus__ProposalNotInStatus(_proposalId, "Proposed or Funding", _statusToString(proposal.status));
        }
        if (block.timestamp >= proposal.deadline) revert SyntheticaNexus__DeadlinePassed();

        token.transferFrom(msg.sender, address(this), _amount);

        if (proposal.status == ProposalStatus.Proposed) {
            proposal.status = ProposalStatus.Funding;
            emit ProposalStatusChanged(_proposalId, "Proposed", "Funding");
        }

        if (proposal.funderAmounts[msg.sender] == 0) {
            proposal.funders.push(msg.sender);
        }
        proposal.funderAmounts[msg.sender] += _amount;
        proposal.currentFunds += _amount;

        emit ProposalFunded(_proposalId, msg.sender, _amount, proposal.currentFunds);
    }

    /**
     * @notice Allows governance stakers to vote for approving a proposal to move to 'InProgress'.
     *         A proposal needs to meet its funding goal AND reach the approval voting threshold.
     * @param _proposalId The ID of the proposal to approve.
     */
    function approveProposal(uint256 _proposalId) external onlyIfGovernanceStaker notPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert SyntheticaNexus__ProposalNotFound();
        if (proposal.status != ProposalStatus.Funding) {
            revert SyntheticaNexus__ProposalNotInStatus(_proposalId, "Funding", _statusToString(proposal.status));
        }
        if (block.timestamp >= proposal.deadline) revert SyntheticaNexus__DeadlinePassed();
        if (proposal.governanceVotesForApproval[msg.sender]) revert SyntheticaNexus__AlreadyVoted();
        if (proposal.currentFunds < proposal.fundingGoal) revert SyntheticaNexus__FundingNotMet();

        proposal.governanceVotesForApproval[msg.sender] = true;
        proposal.votesForApproval += governanceStakes[msg.sender]; // Sum of staked tokens for voting power

        if (proposal.votesForApproval >= proposalVotingThreshold) {
            proposal.status = ProposalStatus.Approved;
            emit ProposalStatusChanged(_proposalId, "Funding", "Approved");
            emit ProposalApproved(_proposalId, msg.sender);
        }
    }

    /**
     * @notice Researchers submit a ZK proof of interim progress.
     *         The actual proof data (e.g., JSON) is off-chain, only the verifiable hash is on-chain.
     * @param _proposalId The ID of the proposal.
     * @param _proof The raw ZK proof data.
     */
    function submitInterimResultProof(uint256 _proposalId, bytes memory _proof) external notPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert SyntheticaNexus__ProposalNotFound();
        if (proposal.proposer != msg.sender) revert SyntheticaNexus__NotProposer();
        if (proposal.status != ProposalStatus.Approved && proposal.status != ProposalStatus.InProgress) {
            revert SyntheticaNexus__ProposalNotInStatus(_proposalId, "Approved or InProgress", _statusToString(proposal.status));
        }

        // Mock public inputs hash derivation for ZK proof. In reality, this would be part of the ZK circuit.
        bytes32 publicInputsHash = keccak256(abi.encodePacked(_proof, proposal.zkProofSchemaHash));

        if (!zkVerifier.verifyProof(_proof, publicInputsHash)) revert SyntheticaNexus__InvalidProof();

        if (proposal.status == ProposalStatus.Approved) { // First submission
            proposal.status = ProposalStatus.InProgress;
            emit ProposalStatusChanged(_proposalId, "Approved", "InProgress");
        }
        // No explicit review for interim, but can add it later if needed.
        // For now, it's just a verification of progress.
        emit InterimResultProofSubmitted(_proposalId, msg.sender, publicInputsHash);
    }

    /**
     * @notice Triggers an AI Oracle review for a submission (interim or final).
     * @param _proposalId The ID of the proposal.
     * @param _submissionHash A hash representing the data to be reviewed (e.g., IPFS hash of research output).
     */
    function requestAIReview(uint256 _proposalId, bytes32 _submissionHash) external onlyIfReviewer notPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert SyntheticaNexus__ProposalNotFound();
        if (proposal.status == ProposalStatus.Completed || proposal.status == ProposalStatus.Rejected) {
             revert SyntheticaNexus__ProposalNotInStatus(_proposalId, "Not Completed/Rejected", _statusToString(proposal.status));
        }

        // Check if current user is already an assigned reviewer, or allow open review
        bool isAssigned = false;
        for (uint i = 0; i < proposal.assignedReviewers.length; i++) {
            if (proposal.assignedReviewers[i] == msg.sender) {
                isAssigned = true;
                break;
            }
        }
        if (!isAssigned) {
            proposal.assignedReviewers.push(msg.sender); // Dynamically assign reviewer upon request
        }

        // Call the AI oracle
        uint256 reviewRequestId = aiOracle.requestReview(_proposalId, _submissionHash);

        proposal.reviews.push(Review({
            reviewer: msg.sender,
            reviewRequestId: reviewRequestId,
            submissionHash: _submissionHash,
            aiScore: 0, // Will be updated later
            timestamp: block.timestamp,
            disputeInitiated: false
        }));

        proposal.status = ProposalStatus.Reviewing;
        emit ProposalStatusChanged(_proposalId, _statusToString(proposal.status), "Reviewing");
        emit AIReviewRequested(_proposalId, reviewRequestId, _submissionHash);
    }

    /**
     * @notice Callback from AI Oracle (or a trusted relay) to submit the AI review score.
     *         Only the trusted AI Oracle address can call this.
     * @param _proposalId The ID of the proposal.
     * @param _reviewRequestId The ID of the review request.
     * @param _score The AI-generated score (-100 to 100).
     */
    function receiveAIReviewScore(uint256 _proposalId, uint256 _reviewRequestId, int256 _score) external notPaused {
        if (msg.sender != address(aiOracle)) revert("SyntheticaNexus: Not AI Oracle");
        if (_score < -100 || _score > 100) revert SyntheticaNexus__AIReviewScoreInvalid();

        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert SyntheticaNexus__ProposalNotFound();

        bool found = false;
        for (uint i = 0; i < proposal.reviews.length; i++) {
            if (proposal.reviews[i].reviewRequestId == _reviewRequestId) {
                proposal.reviews[i].aiScore = _score;
                found = true;
                break;
            }
        }
        if (!found) revert SyntheticaNexus__ReviewNotFound();

        emit AIReviewCompleted(_proposalId, _reviewRequestId, _score);
    }

    /**
     * @notice Researcher submits final solution via ZK proof, associating a unique hash.
     * @param _proposalId The ID of the proposal.
     * @param _proof The raw ZK proof data for the final solution.
     * @param _solutionHash A unique hash representing the final solution (e.g., IPFS hash).
     */
    function submitFinalSolutionProof(
        uint256 _proposalId,
        bytes memory _proof,
        bytes32 _solutionHash
    ) external notPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert SyntheticaNexus__ProposalNotFound();
        if (proposal.proposer != msg.sender) revert SyntheticaNexus__NotProposer();
        if (proposal.status != ProposalStatus.InProgress && proposal.status != ProposalStatus.Reviewing) {
            revert SyntheticaNexus__ProposalNotInStatus(_proposalId, "InProgress or Reviewing", _statusToString(proposal.status));
        }

        // Verify ZK proof for the final solution
        bytes32 publicInputsHash = keccak256(abi.encodePacked(_proof, proposal.zkProofSchemaHash));
        if (!zkVerifier.verifyProof(_proof, publicInputsHash)) revert SyntheticaNexus__InvalidProof();

        proposal.finalSolutionHash = _solutionHash;
        emit FinalSolutionProofSubmitted(_proposalId, msg.sender, _solutionHash);

        // Optionally, could automatically request an AI review for the final solution here.
        // For now, we assume `markProjectCompletion` will check for a successful review.
    }

    /**
     * @notice Marks a project as completed and triggers fund distribution.
     *         Requires prior successful AI/ZK review and submission of final solution.
     *         Can be called by any governance staker or the owner.
     * @param _proposalId The ID of the proposal to mark complete.
     * @param _reviewers The list of addresses who contributed to reviews for this project.
     */
    function markProjectCompletion(uint256 _proposalId, address[] memory _reviewers) external onlyIfGovernanceStaker notPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert SyntheticaNexus__ProposalNotFound();
        if (proposal.status == ProposalStatus.Completed) revert SyntheticaNexus__AlreadyCompleted();
        if (proposal.finalSolutionHash == bytes32(0)) revert SyntheticaNexus__ProposalNotReadyForCompletion();

        // Check for at least one positive AI review among the latest ones
        bool hasPositiveReview = false;
        for(uint i = proposal.reviews.length; i > 0; i--) {
            if (proposal.reviews[i-1].aiScore >= 50) { // Example: score >= 50 is considered positive
                hasPositiveReview = true;
                break;
            }
        }
        if (!hasPositiveReview) revert SyntheticaNexus__AIReviewPending(); // Or "SyntheticaNexus__NoPositiveAIReview()"

        // Distribute reviewer rewards (simplified - equally for now, could be weighted by score/reputation)
        uint256 totalReviewers = _reviewers.length;
        if (totalReviewers > 0 && proposal.totalReviewerReward > 0) {
            uint256 rewardPerReviewer = proposal.totalReviewerReward / totalReviewers;
            for (uint i = 0; i < totalReviewers; i++) {
                // Transfer tokens directly to reviewers, or store for later claim
                token.transfer(_reviewers[i], rewardPerReviewer);
                reputations[_reviewers[i]] += 10; // Positive reputation boost
            }
        }

        proposal.status = ProposalStatus.Completed;
        proposal.completionTimestamp = block.timestamp;

        // Mark solution in knowledge base
        _markSolutionAsKnowledgeBaseEntry(_proposalId, proposal.finalSolutionHash);

        emit ProposalStatusChanged(_proposalId, _statusToString(proposal.status), "Completed");
        emit ProjectCompleted(_proposalId, proposal.proposer, proposal.rewardAmount);

        reputations[proposal.proposer] += 50; // Major reputation boost for completion
    }

    /**
     * @notice Allows the researcher to claim their reward once the project is marked complete.
     * @param _proposalId The ID of the completed proposal.
     */
    function claimReward(uint256 _proposalId) external nonReentrant notPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert SyntheticaNexus__ProposalNotFound();
        if (proposal.proposer != msg.sender) revert SyntheticaNexus__NotProposer();
        if (proposal.status != ProposalStatus.Completed) {
            revert SyntheticaNexus__ProposalNotInStatus(_proposalId, "Completed", _statusToString(proposal.status));
        }
        if (proposal.rewardAmount == 0) revert SyntheticaNexus__NotEnoughFundsToClaim();

        uint256 amountToClaim = proposal.rewardAmount;
        proposal.rewardAmount = 0; // Prevent double claim

        token.transfer(msg.sender, amountToClaim);
        token.transfer(protocolFeeRecipient, proposal.protocolFee); // Transfer protocol fee

        emit RewardClaimed(_proposalId, msg.sender, amountToClaim);
    }

    /**
     * @notice Allows proposers or funders to reclaim funds if a proposal fails to get approved or funded within its deadline.
     * @param _proposalId The ID of the proposal.
     */
    function refundUnusedProposalFunds(uint256 _proposalId) external nonReentrant notPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert SyntheticaNexus__ProposalNotFound();
        if (proposal.status == ProposalStatus.Approved || proposal.status == ProposalStatus.InProgress || proposal.status == ProposalStatus.Reviewing || proposal.status == ProposalStatus.Completed) {
             revert SyntheticaNexus__CannotRefundApprovedProposal();
        }
        if (block.timestamp < proposal.deadline && proposal.currentFunds < proposal.fundingGoal) {
            revert SyntheticaNexus__DeadlinePassed(); // Not passed deadline and not fully funded yet
        }

        uint256 refundAmount = proposal.funderAmounts[msg.sender];
        if (refundAmount == 0) revert SyntheticaNexus__NotEnoughFundsToClaim();

        proposal.funderAmounts[msg.sender] = 0;
        proposal.currentFunds -= refundAmount;

        token.transfer(msg.sender, refundAmount);
        emit FundsRefunded(_proposalId, msg.sender, refundAmount);

        // If no more funds, set status to rejected
        if (proposal.currentFunds == 0) {
            proposal.status = ProposalStatus.Rejected;
            emit ProposalStatusChanged(_proposalId, _statusToString(proposal.status), "Rejected");
        }
    }

    /**
     * @notice Governance-approved extension of a proposal's deadline.
     *         Only callable by governance stakers.
     * @param _proposalId The ID of the proposal.
     * @param _newDeadline The new timestamp for the deadline.
     */
    function extendProposalDeadline(uint256 _proposalId, uint256 _newDeadline) external onlyIfGovernanceStaker notPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert SyntheticaNexus__ProposalNotFound();
        if (_newDeadline <= proposal.deadline) revert SyntheticaNexus__InvalidDeadline();
        if (proposal.status != ProposalStatus.Proposed && proposal.status != ProposalStatus.Funding) {
            revert SyntheticaNexus__ProposalNotInStatus(_proposalId, "Proposed or Funding", _statusToString(proposal.status));
        }

        uint256 oldDeadline = proposal.deadline;
        proposal.deadline = _newDeadline;
        emit ProposalDeadlineExtended(_proposalId, oldDeadline, _newDeadline);
    }


    // --- III. Review & Dispute Resolution Functions ---

    /**
     * @notice Allows users to stake tokens to become an eligible reviewer.
     * @param _amount The amount of tokens to stake. Must be >= minReviewerStake.
     */
    function stakeForReviewerRole(uint256 _amount) external nonReentrant notPaused {
        if (_amount < minReviewerStake) revert SyntheticaNexus__InsufficientStake();

        token.transferFrom(msg.sender, address(this), _amount);
        reviewerStakes[msg.sender] += _amount;
        emit ReviewerStaked(msg.sender, _amount);
    }

    /**
     * @notice Allows reviewers to unstake their tokens if not actively reviewing or in dispute.
     */
    function unstakeFromReviewerRole() external nonReentrant notPaused {
        uint256 stakedAmount = reviewerStakes[msg.sender];
        if (stakedAmount == 0) revert SyntheticaNexus__InsufficientStake();
        if (hasActiveDisputeAsReviewer[msg.sender]) revert SyntheticaNexus__ReviewerHasActiveDispute();

        reviewerStakes[msg.sender] = 0;
        token.transfer(msg.sender, stakedAmount);
        emit ReviewerUnstaked(msg.sender, stakedAmount);
    }

    /**
     * @notice Initiates a dispute over an AI review decision.
     * @param _proposalId The ID of the proposal.
     * @param _reviewIndex The index of the specific review in the proposal's review array.
     * @param _reason A string or IPFS hash explaining the reason for the challenge.
     */
    function challengeReviewDecision(
        uint256 _proposalId,
        uint256 _reviewIndex,
        string memory _reason
    ) external notPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert SyntheticaNexus__ProposalNotFound();
        if (_reviewIndex >= proposal.reviews.length) revert SyntheticaNexus__ReviewNotFound();
        if (proposal.reviews[_reviewIndex].disputeInitiated) revert("SyntheticaNexus: Dispute already initiated for this review.");

        proposal.status = ProposalStatus.Disputed;
        proposal.reviews[_reviewIndex].disputeInitiated = true;
        hasActiveDisputeAsReviewer[proposal.reviews[_reviewIndex].reviewer] = true;

        uint256 disputeId = nextDisputeId++;
        disputes[disputeId] = Dispute({
            disputeId: disputeId,
            proposalId: _proposalId,
            claimant: msg.sender,
            reviewIndex: _reviewIndex,
            reason: _reason,
            votesForClaimant: 0,
            votesAgainstClaimant: 0,
            deadline: block.timestamp + 7 days, // Example: 7 days for dispute voting
            status: DisputeStatus.Open,
            hasVoted: new mapping(address => bool) // Initialize empty mapping
        });

        emit DisputeDecisionChallenged(disputeId, _proposalId, msg.sender, _reviewIndex);
        emit ProposalStatusChanged(_proposalId, _statusToString(proposal.status), "Disputed");
    }

    /**
     * @notice Governance stakers vote on an ongoing dispute.
     * @param _disputeId The ID of the dispute.
     * @param _supportClaimant True if voting to support the claimant, false otherwise.
     */
    function voteOnDispute(uint256 _disputeId, bool _supportClaimant) external onlyIfGovernanceStaker notPaused {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.disputeId == 0) revert SyntheticaNexus__DisputeNotFound();
        if (dispute.status != DisputeStatus.Open) revert SyntheticaNexus__DisputeNotOpen();
        if (dispute.hasVoted[msg.sender]) revert SyntheticaNexus__AlreadyVoted();
        if (block.timestamp >= dispute.deadline) revert SyntheticaNexus__DeadlinePassed();

        dispute.hasVoted[msg.sender] = true;
        uint256 voterStake = governanceStakes[msg.sender];

        if (_supportClaimant) {
            dispute.votesForClaimant += voterStake;
        } else {
            dispute.votesAgainstClaimant += voterStake;
        }

        emit DisputeVoted(_disputeId, msg.sender, _supportClaimant);
    }

    /**
     * @notice Admin/governance function to finalize a dispute resolution after voting.
     *         Requires significant governance stake.
     * @param _disputeId The ID of the dispute to resolve.
     */
    function resolveDispute(uint256 _disputeId) external onlyIfGovernanceStaker notPaused {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.disputeId == 0) revert SyntheticaNexus__DisputeNotFound();
        if (dispute.status != DisputeStatus.Open) revert SyntheticaNexus__DisputeNotOpen();
        if (block.timestamp < dispute.deadline && (dispute.votesForClaimant + dispute.votesAgainstClaimant < disputeVotingThreshold)) {
            revert SyntheticaNexus__NotEnoughVotes();
        }

        bool resolvedForClaimant = dispute.votesForClaimant > dispute.votesAgainstClaimant;
        dispute.status = resolvedForClaimant ? DisputeStatus.ResolvedForClaimant : DisputeStatus.ResolvedAgainstClaimant;

        Proposal storage proposal = proposals[dispute.proposalId];
        address reviewer = proposal.reviews[dispute.reviewIndex].reviewer;

        if (resolvedForClaimant) {
            // Claimant wins: review is overturned, reviewer reputation lowered, potential stake slash
            reputations[dispute.claimant] += 20; // Reputation boost for successfully challenging
            reputations[reviewer] -= 30; // Reputation hit for bad review
            // Slash reviewer's stake (example: 10% of minReviewerStake)
            uint256 slashAmount = minReviewerStake / 10;
            if (reviewerStakes[reviewer] >= slashAmount) {
                reviewerStakes[reviewer] -= slashAmount;
                // transfer to protocolFeeRecipient or burn
                token.transfer(protocolFeeRecipient, slashAmount);
            }
        } else {
            // Claimant loses: reviewer reputation boosted, claimant reputation lowered
            reputations[dispute.claimant] -= 10;
            reputations[reviewer] += 10;
        }

        hasActiveDisputeAsReviewer[reviewer] = false;
        proposal.status = ProposalStatus.InProgress; // Move proposal back to in progress after dispute
        emit ProposalStatusChanged(dispute.proposalId, "Disputed", "InProgress");
        emit DisputeResolved(_disputeId, resolvedForClaimant);
    }

    // --- IV. Reputation & Role Management Functions ---

    /**
     * @notice Returns the reputation score of a given researcher.
     * @param _researcher The address of the researcher.
     * @return The reputation score.
     */
    function getResearcherReputation(address _researcher) external view returns (int256) {
        return reputations[_researcher];
    }

    /**
     * @notice Allows researchers to link an IPFS hash to their profile for public information.
     * @param _ipfsHash The IPFS hash pointing to the researcher's public profile data.
     */
    function updateResearcherProfile(string memory _ipfsHash) external notPaused {
        researcherProfiles[msg.sender] = _ipfsHash;
        emit ProfileUpdated(msg.sender, _ipfsHash);
    }

    // --- V. Governance & Parameter Adjustment Functions ---

    /**
     * @notice Allows users to stake tokens to participate in governance (voting).
     * @param _amount The amount of tokens to stake.
     */
    function stakeForGovernance(uint256 _amount) external nonReentrant notPaused {
        if (_amount == 0) revert SyntheticaNexus__InvalidAmount();
        token.transferFrom(msg.sender, address(this), _amount);
        governanceStakes[msg.sender] += _amount;
        emit GovernanceStaked(msg.sender, _amount);
    }

    /**
     * @notice Allows governance stakers to unstake their tokens.
     */
    function unstakeFromGovernance() external nonReentrant notPaused {
        uint256 stakedAmount = governanceStakes[msg.sender];
        if (stakedAmount == 0) revert SyntheticaNexus__InsufficientStake();

        // Check if user has any active votes that could be impacted by unstaking
        // (Simplified: assuming no ongoing votes need to be considered for this prompt)

        governanceStakes[msg.sender] = 0;
        token.transfer(msg.sender, stakedAmount);
        emit GovernanceUnstaked(msg.sender, stakedAmount);
    }

    /**
     * @notice Allows governance stakers to propose a change to a system parameter.
     * @param _paramKey A bytes32 identifier for the parameter (e.g., "proposalVotingThreshold").
     * @param _newValue The new value for the parameter.
     */
    function proposeParameterChange(bytes32 _paramKey, uint256 _newValue) external onlyIfGovernanceStaker notPaused {
        bytes32 paramHash = keccak256(abi.encodePacked(_paramKey, _newValue));
        if (pendingParameterChanges[paramHash].deadline != 0) revert("SyntheticaNexus: Parameter change already proposed.");

        pendingParameterChanges[paramHash] = ParameterChangeProposal({
            paramKey: _paramKey,
            newValue: _newValue,
            votesFor: governanceStakes[msg.sender],
            votesAgainst: 0,
            hasVoted: new mapping(address => bool),
            deadline: block.timestamp + 3 days, // Example: 3 days for voting
            executed: false
        });
        pendingParameterChanges[paramHash].hasVoted[msg.sender] = true;

        emit ParameterChangeProposed(paramHash, _paramKey, _newValue, msg.sender);
    }

    /**
     * @notice Allows governance stakers to vote on a proposed parameter change.
     * @param _paramHash The hash identifying the parameter change proposal.
     * @param _approve True to vote for the change, false to vote against.
     */
    function voteOnParameterChange(bytes32 _paramHash, bool _approve) external onlyIfGovernanceStaker notPaused {
        ParameterChangeProposal storage proposal = pendingParameterChanges[_paramHash];
        if (proposal.deadline == 0 || proposal.executed) revert SyntheticaNexus__ParamChangeProposalNotFound();
        if (proposal.hasVoted[msg.sender]) revert SyntheticaNexus__AlreadyVoted();
        if (block.timestamp >= proposal.deadline) revert SyntheticaNexus__DeadlinePassed();

        proposal.hasVoted[msg.sender] = true;
        if (_approve) {
            proposal.votesFor += governanceStakes[msg.sender];
        } else {
            proposal.votesAgainst += governanceStakes[msg.sender];
        }

        emit ParameterChangeVoted(_paramHash, msg.sender, _approve);
    }

    /**
     * @notice Admin/governance function to execute a successful parameter change proposal.
     * @param _paramHash The hash identifying the parameter change proposal.
     */
    function executeParameterChange(bytes32 _paramHash) external onlyOwner notPaused {
        ParameterChangeProposal storage proposal = pendingParameterChanges[_paramHash];
        if (proposal.deadline == 0 || proposal.executed) revert SyntheticaNexus__ParamChangeProposalNotFound();
        if (block.timestamp < proposal.deadline) revert("SyntheticaNexus: Voting period not over.");
        if (proposal.votesFor <= proposal.votesAgainst || proposal.votesFor < proposalVotingThreshold) {
            revert SyntheticaNexus__NotEnoughVotes();
        }

        // Execute the parameter change based on _paramKey
        if (proposal.paramKey == "proposalVotingThreshold") {
            proposalVotingThreshold = proposal.newValue;
        } else if (proposal.paramKey == "disputeVotingThreshold") {
            disputeVotingThreshold = proposal.newValue;
        } else if (proposal.paramKey == "minReviewerStake") {
            minReviewerStake = proposal.newValue;
        } else if (proposal.paramKey == "protocolFeeRatePermil") {
            protocolFeeRatePermil = proposal.newValue;
        } else {
            revert SyntheticaNexus__ParamKeyNotRecognized();
        }

        proposal.executed = true;
        emit ParameterChangeExecuted(_paramHash, proposal.paramKey, proposal.newValue);
    }

    // --- VI. Utility & Information Functions ---

    /**
     * @notice Returns the ZK proof schema hash required for a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return The bytes32 hash of the required ZK proof schema.
     */
    function getRequiredProofSchemaHash(uint256 _proposalId) external view returns (bytes32) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert SyntheticaNexus__ProposalNotFound();
        return proposal.zkProofSchemaHash;
    }

    /**
     * @notice Internal/Admin function to mark a successfully verified solution hash as an entry in the knowledge base.
     *         This helps prevent duplication of research effort.
     * @param _proposalId The ID of the proposal.
     * @param _solutionHash The unique hash of the final solution.
     */
    function _markSolutionAsKnowledgeBaseEntry(uint256 _proposalId, bytes32 _solutionHash) internal {
        if (knowledgeBaseEntries[_solutionHash]) revert SyntheticaNexus__SolutionAlreadyRegistered();
        Proposal storage proposal = proposals[_proposalId];
        knowledgeBaseEntries[_solutionHash] = true;
        knowledgeBaseEntryAuthor[_solutionHash] = proposal.proposer;
        emit KnowledgeBaseEntryAdded(_solutionHash, _proposalId);
    }

    /**
     * @notice Conceptually registers a link to cross-chain knowledge related to a solution.
     *         This function mainly emits an event for off-chain indexing.
     * @param _solutionHash The unique hash of the final solution.
     * @param _chainIdentifier A string identifying the external blockchain/system (e.g., "Polygon", "Arweave").
     * @param _externalLink A URL or identifier pointing to the cross-chain resource.
     */
    function registerCrossChainKnowledgeLink(
        bytes32 _solutionHash,
        string memory _chainIdentifier,
        string memory _externalLink
    ) external notPaused {
        if (!knowledgeBaseEntries[_solutionHash]) revert("SyntheticaNexus: Solution not in knowledge base.");
        // This function itself does not store the link on-chain to save gas,
        // but emits an event for off-chain indexing and integration.
        emit CrossChainKnowledgeLinkRegistered(_solutionHash, _chainIdentifier, _externalLink);
    }

    // --- VII. Emergency Pause Functionality ---

    /**
     * @notice Allows the designated owner to pause critical functions in case of emergency.
     *         This prevents new proposals, funding, and major state changes.
     */
    function emergencyPause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Allows the designated owner to unpause the contract after an emergency.
     */
    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // --- INTERNAL/PRIVATE HELPERS ---

    function _statusToString(ProposalStatus _status) internal pure returns (string memory) {
        if (_status == ProposalStatus.Proposed) return "Proposed";
        if (_status == ProposalStatus.Funding) return "Funding";
        if (_status == ProposalStatus.Approved) return "Approved";
        if (_status == ProposalStatus.InProgress) return "InProgress";
        if (_status == ProposalStatus.Reviewing) return "Reviewing";
        if (_status == ProposalStatus.Completed) return "Completed";
        if (_status == ProposalStatus.Rejected) return "Rejected";
        if (_status == ProposalStatus.Disputed) return "Disputed";
        return "Unknown";
    }
}
```