```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 *
 * Contract: Synthetica Nexus - Decentralized AI-Assisted Research Funding & Verification Platform
 *
 * Description: Synthetica Nexus is an innovative platform designed to foster and fund
 * advanced research through a blend of decentralized principles, AI oracle assessments,
 * peer review, and reputation-based incentives. It aims to accelerate scientific and
 * technological breakthroughs by creating a transparent and outcome-driven ecosystem.
 *
 * Key Advanced Concepts:
 * 1. AI Oracle Integration (Simulated): Mechanisms for off-chain AI to assess research
 *    milestones, with on-chain proofs for verifiability. The contract defines the interface
 *    for an external AI oracle, crucial for outcome verification.
 * 2. ZK-Proof for Privacy-Preserving Peer Review: Placeholder for verifiable,
 *    anonymous peer reviews using Zero-Knowledge Proofs (ZKPs) to confirm reviewer
 *    credentials (e.g., minimum reputation, expertise) without revealing specific identity.
 * 3. Soul-Bound Tokens (SBTs): Non-transferable tokens serving as on-chain reputation
 *    and verifiable credentials for researcher achievements and reviewer contributions.
 * 4. Dynamic Discovery Pool: A community-contributed fund that can be allocated
 *    algorithmically (future extension) or via DAO governance to promising research proposals,
 *    enabling flexible funding strategies.
 * 5. Outcome-Based Prediction Market: Allows users to predict the success of research
 *    proposals, aligning incentives, leveraging collective intelligence, and providing
 *    additional funding/rewards for accurate forecasts.
 * 6. Decentralized Governance: DAO-like structure allowing participants (potentially weighted
 *    by SBTs or stake) to propose and vote on protocol parameter updates and critical decisions,
 *    enabling the contract to evolve.
 * 7. Milestone-Based Funding & Progressive Rewards: Research projects are structured into
 *    stages, with funding and rewards released incrementally upon the successful, verified
 *    completion of each milestone.
 *
 * Outline & Function Summary:
 *
 * I. Core Platform Management & Setup:
 *    1.  constructor(): Initializes the contract owner, sets initial parameters like protocol fee and minimum proposal stake.
 *    2.  updateOracleAddress(address _newOracle): Allows the owner to update the address of the trusted AI assessment oracle.
 *    3.  pauseContract(bool _status): Enables emergency pausing/unpausing of core contract functionalities by the owner.
 *    4.  setProtocolFee(uint256 _feePermil): Sets the percentage of successful project funds taken as a platform fee (in permil, parts per thousand).
 *    5.  setMinimumProposalStake(uint256 _amount): Defines the minimum ETH amount a researcher must stake to submit a new proposal.
 *
 * II. Proposal & Funding:
 *    6.  submitResearchProposal(string memory _ipfsHash, uint256 _fundingGoal, uint256 _milestoneCount, uint256 _durationWeeks):
 *        Allows a researcher to submit a new project proposal, detailing its IPFS hash, funding goal, milestones, and duration. Requires an ETH stake.
 *    7.  fundProposal(uint256 _proposalId): Enables users to directly fund a specific research proposal by sending ETH.
 *    8.  depositToDiscoveryPool(): Allows anyone to contribute ETH to a general "Discovery Pool" for future allocation to promising projects.
 *    9.  withdrawFromDiscoveryPool(uint256 _amount): Permits withdrawal of unallocated funds from the Discovery Pool by the original depositor (if not yet allocated).
 *    10. allocateDiscoveryFunds(uint256 _proposalId, uint256 _amount): Enables designated governors (or a DAO mechanism) to allocate funds from the Discovery Pool to a specific proposal.
 *
 * III. Verification & Assessment (AI & Peer-driven):
 *    11. requestOracleAssessment(uint256 _proposalId, uint256 _milestoneIndex): Triggers an external AI oracle to assess a specific milestone's progress.
 *    12. receiveOracleAssessment(uint256 _proposalId, uint256 _milestoneIndex, uint256 _assessmentScore, bytes32 _oracleProof):
 *        Callback function, callable only by the designated oracle, to submit the AI's assessment score and an accompanying proof for a milestone.
 *    13. submitPeerReview(uint256 _proposalId, uint256 _milestoneIndex, string memory _reviewIpfsHash, bytes memory _zkProofOfReviewerID):
 *        Allows qualified peer reviewers to submit their assessment of a milestone, providing an IPFS hash for review content and a ZK-proof for credential verification.
 *    14. endorsePeerReview(uint256 _reviewId): Enables community members to endorse valuable peer reviews, contributing to the reviewer's reputation.
 *
 * IV. Reward & Distribution:
 *    15. distributeMilestoneRewards(uint256 _proposalId, uint256 _milestoneIndex):
 *        Initiates the distribution of funds for a successfully verified milestone to the researcher, and conceptually to funders and the protocol.
 *    16. claimRewards(uint256 _proposalId): Allows participants (researchers, funders, prediction winners, owner) to claim their finalized rewards.
 *    17. releaseProposalStake(uint256 _proposalId): Releases the initial stake back to the researcher upon successful project completion, or slashes it if the project fails.
 *
 * V. Reputation & Governance (SBT & DAO-like):
 *    18. mintResearcherSBT(address _recipient, string memory _badgeType):
 *        Mints a Soul-Bound Token (SBT) to acknowledge a researcher's significant achievement (e.g., "Verified Innovator").
 *    19. mintReviewerSBT(address _recipient, string memory _badgeType):
 *        Mints an SBT to recognize outstanding contributions from a peer reviewer (e.g., "Top Reviewer").
 *    20. proposeGovernanceChange(string memory _descriptionIpfsHash, address _target, bytes memory _calldata):
 *        Allows qualified participants to propose a contract parameter change or action to be voted on by the DAO.
 *    21. voteOnGovernanceProposal(uint256 _proposalId, bool _for):
 *        Enables participants to cast their vote (for or against) on an active governance proposal. Voting power might be influenced by SBTs or stake.
 *    22. executeGovernanceProposal(uint256 _proposalId):
 *        Executes a governance proposal that has successfully passed the voting period and met quorum requirements.
 *
 * VI. Prediction Market (on proposal success):
 *    23. placePrediction(uint256 _proposalId, bool _predictSuccess):
 *        Allows users to place a bet on the overall success (true) or failure (false) of a specific research proposal.
 *    24. claimPredictionWinnings(uint256 _proposalId):
 *        Enables users with accurate predictions to claim their share of the prediction pool for a finalized proposal.
 *
 */

contract SyntheticaNexus {
    address public owner;
    bool public paused;
    address public oracleAddress;
    uint256 public protocolFeePermil; // Fee in parts per thousand (e.g., 50 = 5%)
    uint256 public minimumProposalStake;

    // --- Events ---
    event ProposalSubmitted(uint256 indexed proposalId, address indexed researcher, string ipfsHash, uint256 fundingGoal);
    event ProposalFunded(uint256 indexed proposalId, address indexed funder, uint256 amount);
    event DiscoveryPoolDeposited(address indexed depositor, uint256 amount);
    event DiscoveryPoolAllocated(uint256 indexed proposalId, address indexed allocator, uint256 amount);
    event OracleAssessmentRequested(uint256 indexed proposalId, uint256 indexed milestoneIndex);
    event OracleAssessmentReceived(uint256 indexed proposalId, uint256 indexed milestoneIndex, uint256 score);
    event PeerReviewSubmitted(uint256 indexed reviewId, uint256 indexed proposalId, uint256 indexed milestoneIndex, address reviewer);
    event ReviewEndorsed(uint256 indexed reviewId, address indexed endorser);
    event MilestoneRewardsDistributed(uint256 indexed proposalId, uint256 indexed milestoneIndex, uint256 totalDistributed);
    event RewardsClaimed(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event ProposalStakeReleased(uint256 indexed proposalId, address indexed researcher, uint256 amount);
    event ResearcherSBTMinted(address indexed recipient, string badgeType);
    event ReviewerSBTMinted(address indexed recipient, string badgeType);
    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string descriptionIpfsHash);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed voter, bool decision);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event PredictionPlaced(uint256 indexed proposalId, address indexed predictor, bool predictedSuccess, uint256 amount);
    event PredictionWinningsClaimed(uint256 indexed proposalId, address indexed winner, uint256 amount);
    event ContractPaused(bool status);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Only the designated oracle can call this function.");
        _;
    }

    // --- Enums ---
    enum ProposalStatus { Pending, Active, Completed, Failed, Cancelled }
    enum MilestoneStatus { Pending, InProgress, AwaitingAssessment, Verified, Failed }
    enum GovernanceStatus { Pending, Approved, Rejected, Executed }

    // --- Structs ---

    struct Milestone {
        uint256 fundingAllocated;    // ETH allocated conceptually for this milestone from total project funds
        MilestoneStatus status;
        uint256 oracleAssessmentScore; // Score from 0-100, 0=bad, 100=excellent
        uint256 completionTimestamp;
        bool rewardsDistributed;
    }

    struct ResearchProposal {
        address researcher;
        string ipfsHash;            // IPFS hash for detailed proposal document
        uint256 fundingGoal;
        uint256 totalFunded;
        uint256 initialStake;       // ETH staked by researcher
        uint256 deadline;           // Timestamp when project duration ends
        ProposalStatus status;
        Milestone[] milestones;
        mapping(address => uint256) funders; // Who funded how much
        uint256 predictionPool;     // Total funds in prediction market for this proposal
        uint256 predictionSuccessPool; // Funds for success predictions
        uint256 predictionFailPool;    // Funds for failure predictions
        mapping(address => bool) hasPredictedSuccess; // Tracks if a user predicted success
        mapping(address => uint256) predictionAmounts; // Tracks user's prediction amount
        uint256 finalOracleScore;   // Average or final score determining overall success
        bool outcomeDetermined;     // True when final success/failure is known
        uint256 lastMilestoneCompleted; // Index of the last completed milestone (0 if none)
    }

    struct PeerReview {
        uint256 proposalId;
        uint256 milestoneIndex;
        address reviewer;
        string ipfsHash;             // IPFS hash for review content
        uint256 endorsementCount;
        bool verifiedByZK;           // True if ZK proof was successfully verified (conceptual)
        mapping(address => bool) hasEndorsed; // To prevent multiple endorsements
    }

    struct GovernanceProposal {
        address proposer;
        string descriptionIpfsHash;  // IPFS hash for detailed proposal text
        address target;              // The contract address to call (usually `address(this)`)
        bytes calldataPayload;       // The calldata for the function to execute
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        GovernanceStatus status;
        mapping(address => bool) hasVoted; // Prevents double voting
    }

    // --- State Variables ---
    uint256 public nextProposalId;
    mapping(uint256 => ResearchProposal) public proposals;
    mapping(address => uint256) public discoveryPoolBalances; // Balances of users in the discovery pool
    uint256 public totalDiscoveryPoolFunds;

    uint256 public nextReviewId;
    mapping(uint256 => PeerReview) public peerReviews;

    uint256 public nextGovernanceProposalId;
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // Simplified SBT System: mapping(recipient => mapping(badgeType => bool))
    mapping(address => mapping(string => bool)) public hasSBT;

    // Keep track of claimed rewards for all participants (researchers, funders, prediction winners, owner)
    // proposalId => recipientAddress => amountClaimable
    mapping(uint256 => mapping(address => uint256)) public claimedRewards; 

    // Constructor
    constructor() {
        owner = msg.sender;
        paused = false;
        oracleAddress = address(0x0); // Must be set by owner
        protocolFeePermil = 50; // 5% fee
        minimumProposalStake = 1 ether;

        nextProposalId = 1;
        nextReviewId = 1;
        nextGovernanceProposalId = 1;
    }

    // --- I. Core Platform Management & Setup ---

    /// @notice Updates the address of the trusted AI assessment oracle.
    /// @dev Only the contract owner can call this.
    /// @param _newOracle The new address for the AI oracle.
    function updateOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "Oracle address cannot be zero.");
        oracleAddress = _newOracle;
    }

    /// @notice Pauses or unpauses core contract functionalities in an emergency.
    /// @dev Only the contract owner can call this.
    /// @param _status True to pause, false to unpause.
    function pauseContract(bool _status) external onlyOwner {
        paused = _status;
        emit ContractPaused(_status);
    }

    /// @notice Sets the protocol fee for successful projects.
    /// @dev Fee is in permil (parts per thousand), e.g., 50 for 5%. Max 100 permil (10%).
    /// @param _feePermil The new fee in permil.
    function setProtocolFee(uint256 _feePermil) external onlyOwner {
        require(_feePermil <= 100, "Protocol fee cannot exceed 100 permil (10%).");
        protocolFeePermil = _feePermil;
    }

    /// @notice Sets the minimum ETH amount required for a researcher to stake when submitting a proposal.
    /// @dev Only the contract owner can call this.
    /// @param _amount The minimum stake amount in wei.
    function setMinimumProposalStake(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Minimum stake must be greater than zero.");
        minimumProposalStake = _amount;
    }

    // --- II. Proposal & Funding ---

    /// @notice Submits a new research proposal.
    /// @dev Requires the researcher to stake `minimumProposalStake`.
    /// @param _ipfsHash IPFS hash pointing to the detailed proposal document.
    /// @param _fundingGoal Total ETH needed for the project.
    /// @param _milestoneCount Number of milestones for the project.
    /// @param _durationWeeks Total project duration in weeks.
    function submitResearchProposal(
        string memory _ipfsHash,
        uint256 _fundingGoal,
        uint256 _milestoneCount,
        uint256 _durationWeeks
    ) external payable notPaused returns (uint256) {
        require(bytes(_ipfsHash).length > 0, "IPFS hash cannot be empty.");
        require(_fundingGoal > 0, "Funding goal must be greater than zero.");
        require(_milestoneCount > 0, "Must have at least one milestone.");
        require(_durationWeeks > 0, "Duration must be greater than zero.");
        require(msg.value >= minimumProposalStake, "Not enough stake provided.");

        uint256 proposalId = nextProposalId++;
        ResearchProposal storage newProposal = proposals[proposalId];

        newProposal.researcher = msg.sender;
        newProposal.ipfsHash = _ipfsHash;
        newProposal.fundingGoal = _fundingGoal;
        newProposal.totalFunded = 0;
        newProposal.initialStake = msg.value;
        newProposal.deadline = block.timestamp + (_durationWeeks * 7 days); // Set deadline for entire project
        newProposal.status = ProposalStatus.Pending;
        newProposal.outcomeDetermined = false;
        newProposal.lastMilestoneCompleted = 0;

        newProposal.milestones.length = _milestoneCount;
        for (uint256 i = 0; i < _milestoneCount; i++) {
            newProposal.milestones[i].status = MilestoneStatus.Pending;
            // Milestone funding will be allocated dynamically upon successful funding
        }

        emit ProposalSubmitted(proposalId, msg.sender, _ipfsHash, _fundingGoal);
        return proposalId;
    }

    /// @notice Funds a specific research proposal.
    /// @dev Any amount can be sent. Proposal moves to Active if funding goal reached.
    /// @param _proposalId The ID of the proposal to fund.
    function fundProposal(uint256 _proposalId) external payable notPaused {
        require(msg.value > 0, "Must send ETH to fund a proposal.");
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.researcher != address(0), "Proposal does not exist.");
        require(proposal.status == ProposalStatus.Pending || proposal.status == ProposalStatus.Active, "Proposal not eligible for funding.");
        require(proposal.totalFunded < proposal.fundingGoal, "Proposal already fully funded.");

        proposal.totalFunded += msg.value;
        proposal.funders[msg.sender] += msg.value;

        if (proposal.totalFunded >= proposal.fundingGoal && proposal.status == ProposalStatus.Pending) {
            proposal.status = ProposalStatus.Active;
            // For simplicity, each milestone gets an equal conceptual share of the total funded goal.
            uint256 fundsPerMilestone = proposal.fundingGoal / proposal.milestones.length;
            for (uint256 i = 0; i < proposal.milestones.length; i++) {
                proposal.milestones[i].fundingAllocated = fundsPerMilestone;
            }
        }

        emit ProposalFunded(_proposalId, msg.sender, msg.value);
    }

    /// @notice Allows users to deposit ETH into a general "Discovery Pool".
    /// @dev Funds in this pool can be later allocated to proposals by governors or through a specific mechanism.
    function depositToDiscoveryPool() external payable notPaused {
        require(msg.value > 0, "Must send ETH to deposit to the Discovery Pool.");
        discoveryPoolBalances[msg.sender] += msg.value;
        totalDiscoveryPoolFunds += msg.value;
        emit DiscoveryPoolDeposited(msg.sender, msg.value);
    }

    /// @notice Allows a user to withdraw their unallocated funds from the Discovery Pool.
    /// @dev Only funds not yet allocated to proposals can be withdrawn.
    /// @param _amount The amount to withdraw.
    function withdrawFromDiscoveryPool(uint256 _amount) external notPaused {
        require(_amount > 0, "Amount must be greater than zero.");
        require(discoveryPoolBalances[msg.sender] >= _amount, "Insufficient balance in Discovery Pool.");

        discoveryPoolBalances[msg.sender] -= _amount;
        totalDiscoveryPoolFunds -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    /// @notice Allocates funds from the Discovery Pool to a specific research proposal.
    /// @dev This function could be restricted to DAO governance or specific roles. For simplicity,
    ///      it is restricted to the owner, or it could be executed via `executeGovernanceProposal`.
    /// @param _proposalId The ID of the proposal to allocate funds to.
    /// @param _amount The amount of ETH to allocate.
    function allocateDiscoveryFunds(uint256 _proposalId, uint256 _amount) external notPaused onlyOwner {
        require(_amount > 0, "Amount must be greater than zero.");
        require(totalDiscoveryPoolFunds >= _amount, "Insufficient funds in Discovery Pool.");

        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.researcher != address(0), "Proposal does not exist.");
        require(proposal.status == ProposalStatus.Pending || proposal.status == ProposalStatus.Active, "Proposal not eligible for funding.");
        require(proposal.totalFunded < proposal.fundingGoal, "Proposal already fully funded.");

        totalDiscoveryPoolFunds -= _amount; // Funds are "virtually" moved, actual ETH remains in contract
        proposal.totalFunded += _amount;

        if (proposal.totalFunded >= proposal.fundingGoal && proposal.status == ProposalStatus.Pending) {
            proposal.status = ProposalStatus.Active;
            uint256 fundsPerMilestone = proposal.fundingGoal / proposal.milestones.length;
            for (uint256 i = 0; i < proposal.milestones.length; i++) {
                proposal.milestones[i].fundingAllocated = fundsPerMilestone;
            }
        }
        emit DiscoveryPoolAllocated(_proposalId, msg.sender, _amount);
    }

    // --- III. Verification & Assessment (AI & Peer-driven) ---

    /// @notice Requests an external AI oracle to assess a specific milestone.
    /// @dev This function would typically trigger an off-chain Chainlink keeper or similar mechanism.
    /// @param _proposalId The ID of the proposal.
    /// @param _milestoneIndex The index of the milestone (0-based).
    function requestOracleAssessment(uint256 _proposalId, uint256 _milestoneIndex) external notPaused {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.researcher != address(0), "Proposal does not exist.");
        require(msg.sender == proposal.researcher || msg.sender == owner, "Only researcher or owner can request assessment.");
        require(_milestoneIndex < proposal.milestones.length, "Milestone index out of bounds.");
        require(proposal.milestones[_milestoneIndex].status == MilestoneStatus.InProgress || proposal.milestones[_milestoneIndex].status == MilestoneStatus.Pending, "Milestone already assessed or failed.");
        require(block.timestamp <= proposal.deadline, "Project deadline passed.");

        proposal.milestones[_milestoneIndex].status = MilestoneStatus.AwaitingAssessment;
        emit OracleAssessmentRequested(_proposalId, _milestoneIndex);
    }

    /// @notice Callback function for the AI oracle to submit its assessment.
    /// @dev Callable only by the designated `oracleAddress`. Includes a proof for verifiability.
    /// @param _proposalId The ID of the proposal.
    /// @param _milestoneIndex The index of the milestone.
    /// @param _assessmentScore The score (0-100) from the AI oracle.
    /// @param _oracleProof A cryptographic proof from the oracle for the assessment (e.g., signature or ZK-proof hash).
    function receiveOracleAssessment(
        uint256 _proposalId,
        uint256 _milestoneIndex,
        uint256 _assessmentScore,
        bytes32 _oracleProof // Placeholder for a real oracle proof
    ) external onlyOracle notPaused {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.researcher != address(0), "Proposal does not exist.");
        require(_milestoneIndex < proposal.milestones.length, "Milestone index out of bounds.");
        require(proposal.milestones[_milestoneIndex].status == MilestoneStatus.AwaitingAssessment, "Milestone not awaiting assessment.");
        require(_assessmentScore <= 100, "Assessment score must be between 0 and 100.");

        // In a real system, `_oracleProof` would be verified here (e.g., signature check or ZK verifier call).
        // For this demo, we assume the proof is valid if provided by `oracleAddress`.

        proposal.milestones[_milestoneIndex].oracleAssessmentScore = _assessmentScore;
        proposal.milestones[_milestoneIndex].completionTimestamp = block.timestamp;
        proposal.milestones[_milestoneIndex].status = (_assessmentScore >= 70) ? MilestoneStatus.Verified : MilestoneStatus.Failed; // Threshold for success

        if (proposal.milestones[_milestoneIndex].status == MilestoneStatus.Verified) {
            proposal.lastMilestoneCompleted = _milestoneIndex + 1; // Update last completed milestone index
        } else {
            // If a milestone fails, the project might be considered failed overall
            proposal.status = ProposalStatus.Failed;
            proposal.outcomeDetermined = true;
            _finalizeFailedProposal(_proposalId); // Handle failure
        }

        // If this is the last milestone and it's verified, finalize the project
        if (proposal.lastMilestoneCompleted == proposal.milestones.length && proposal.milestones[_milestoneIndex].status == MilestoneStatus.Verified) {
             proposal.finalOracleScore = _assessmentScore; // Could be an average of all, but keeping it simple
             proposal.status = ProposalStatus.Completed;
             proposal.outcomeDetermined = true;
             _settlePredictionMarket(_proposalId); // Settle prediction market on project completion
             _finalizeFunderRewards(_proposalId); // Calculate and queue funder rewards
        }

        emit OracleAssessmentReceived(_proposalId, _milestoneIndex, _assessmentScore);
    }

    /// @notice Allows qualified peer reviewers to submit their assessment of a milestone.
    /// @dev `_zkProofOfReviewerID` is a placeholder for a zero-knowledge proof verifying reviewer's credentials.
    /// @param _proposalId The ID of the proposal.
    /// @param _milestoneIndex The index of the milestone.
    /// @param _reviewIpfsHash IPFS hash for the detailed review content.
    /// @param _zkProofOfReviewerID A ZK proof (bytes) to verify reviewer's identity/qualifications anonymously.
    function submitPeerReview(
        uint256 _proposalId,
        uint256 _milestoneIndex,
        string memory _reviewIpfsHash,
        bytes memory _zkProofOfReviewerID // Placeholder for ZK-proof verification
    ) external notPaused returns (uint256) {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.researcher != address(0), "Proposal does not exist.");
        require(_milestoneIndex < proposal.milestones.length, "Milestone index out of bounds.");
        require(bytes(_reviewIpfsHash).length > 0, "Review IPFS hash cannot be empty.");
        require(msg.sender != proposal.researcher, "Researcher cannot review their own proposal.");

        // Conceptual ZK-proof verification:
        // This would involve calling a ZK verifier contract or a precompile.
        // For demo purposes, we'll assume the proof is conceptually valid if provided.
        // `verifyZKProof(sender, _zkProofOfReviewerID)` would be a complex external call.
        bool zkVerified = _zkProofOfReviewerID.length > 0; // Simple placeholder check

        uint256 reviewId = nextReviewId++;
        peerReviews[reviewId] = PeerReview({
            proposalId: _proposalId,
            milestoneIndex: _milestoneIndex,
            reviewer: msg.sender,
            ipfsHash: _reviewIpfsHash,
            endorsementCount: 0,
            verifiedByZK: zkVerified,
            hasEndorsed: new mapping(address => bool)() // Initialize mapping
        });

        emit PeerReviewSubmitted(reviewId, _proposalId, _milestoneIndex, msg.sender);
        return reviewId;
    }

    /// @notice Allows community members to endorse a helpful peer review, boosting the reviewer's reputation.
    /// @param _reviewId The ID of the peer review to endorse.
    function endorsePeerReview(uint256 _reviewId) external notPaused {
        PeerReview storage review = peerReviews[_reviewId];
        require(review.reviewer != address(0), "Review does not exist.");
        require(msg.sender != review.reviewer, "Cannot endorse your own review.");
        require(!review.hasEndorsed[msg.sender], "Already endorsed this review.");

        review.endorsementCount++;
        review.hasEndorsed[msg.sender] = true;
        emit ReviewEndorsed(_reviewId, msg.sender);
    }

    // --- IV. Reward & Distribution ---

    /// @notice Distributes funds for a successfully verified milestone.
    /// @dev Callable by anyone once a milestone is verified. Distributes to researcher and queues protocol fee.
    ///      Funders' shares are calculated and queued upon full project completion.
    /// @param _proposalId The ID of the proposal.
    /// @param _milestoneIndex The index of the milestone.
    function distributeMilestoneRewards(uint256 _proposalId, uint256 _milestoneIndex) external notPaused {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.researcher != address(0), "Proposal does not exist.");
        require(_milestoneIndex < proposal.milestones.length, "Milestone index out of bounds.");
        Milestone storage milestone = proposal.milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.Verified, "Milestone not verified.");
        require(!milestone.rewardsDistributed, "Rewards already distributed for this milestone.");
        require(proposal.totalFunded >= milestone.fundingAllocated, "Not enough funds allocated for this milestone.");

        uint256 currentMilestoneShare = milestone.fundingAllocated;
        uint256 protocolFee = (currentMilestoneShare * protocolFeePermil) / 1000;
        uint256 fundsAfterFee = currentMilestoneShare - protocolFee;

        uint256 researcherShare = (fundsAfterFee * 80) / 100; // 80% to researcher for milestone
        // The remaining 20% + any leftover funds from the milestone is conceptually for funders.
        // This will be added to a pool that `_finalizeFunderRewards` will distribute from.

        claimedRewards[_proposalId][proposal.researcher] += researcherShare;
        claimedRewards[_proposalId][owner] += protocolFee; // Owner collects fees via claimRewards

        milestone.rewardsDistributed = true;
        emit MilestoneRewardsDistributed(_proposalId, _milestoneIndex, currentMilestoneShare);
    }

    /// @notice Allows participants (researchers, funders, prediction winners, owner) to claim their finalized rewards.
    /// @dev Rewards are pulled from the contract's balance. Rewards for researcher and owner are directly managed.
    ///      Funders and prediction winners' rewards are assumed to be populated into `claimedRewards` by
    ///      internal settlement logic (e.g., in `_finalizeFunderRewards` or `_settlePredictionMarket`).
    /// @param _proposalId The ID of the proposal.
    function claimRewards(uint256 _proposalId) external notPaused {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.researcher != address(0), "Proposal does not exist.");
        // Require outcome determined or owner claiming fees (owner can claim fees even if project not fully settled)
        require(proposal.outcomeDetermined || (msg.sender == owner && claimedRewards[_proposalId][owner] > 0), "Proposal outcome not determined yet or no fees to claim.");
        
        uint256 amountToTransfer = claimedRewards[_proposalId][msg.sender];
        require(amountToTransfer > 0, "No claimable rewards for this address and proposal.");

        claimedRewards[_proposalId][msg.sender] = 0; // Reset claimed amount to prevent re-claiming.
        payable(msg.sender).transfer(amountToTransfer);
        emit RewardsClaimed(_proposalId, msg.sender, amountToTransfer);
    }

    /// @notice Releases the initial stake back to the researcher if the project is successful, or slashes it if failed.
    /// @dev Callable by researcher or owner once the proposal outcome is determined.
    /// @param _proposalId The ID of the proposal.
    function releaseProposalStake(uint256 _proposalId) external notPaused {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.researcher != address(0), "Proposal does not exist.");
        require(msg.sender == proposal.researcher || msg.sender == owner, "Only researcher or owner can release stake.");
        require(proposal.outcomeDetermined, "Proposal outcome not yet determined.");
        require(proposal.initialStake > 0, "Stake already released or not provided.");

        uint256 stakeToRelease = proposal.initialStake;
        proposal.initialStake = 0; // Mark stake as handled

        if (proposal.status == ProposalStatus.Completed) {
            payable(proposal.researcher).transfer(stakeToRelease);
            emit ProposalStakeReleased(_proposalId, proposal.researcher, stakeToRelease);
        } else if (proposal.status == ProposalStatus.Failed) {
            // Stake is slashed and added to owner's claimable fees as a penalty.
            claimedRewards[_proposalId][owner] += stakeToRelease;
            emit ProposalStakeReleased(_proposalId, proposal.researcher, 0); // 0 amount released to researcher
        }
    }

    /// @dev Internal function to handle a failed proposal's final state.
    /// @param _proposalId The ID of the proposal.
    function _finalizeFailedProposal(uint256 _proposalId) internal {
        ResearchProposal storage proposal = proposals[_proposalId];
        proposal.status = ProposalStatus.Failed;
        proposal.outcomeDetermined = true;
        _settlePredictionMarket(_proposalId); // Settle prediction market for failure
        _finalizeFunderRewards(_proposalId); // Calculate and queue funder refunds/remaining
        // Any unspent funds or slashed stake might be redirected to discovery pool or owner.
    }

    /// @dev Internal function to calculate and queue funder rewards upon proposal finalization.
    ///      This is a conceptual distribution as iterating over mapping keys for `funders` is not direct.
    ///      A production system might use an array of funder addresses or a pull-based model with more complex math.
    /// @param _proposalId The ID of the proposal.
    function _finalizeFunderRewards(uint256 _proposalId) internal {
        ResearchProposal storage proposal = proposals[_proposalId];
        if (proposal.totalFunded == 0) return;

        uint256 totalFunderContribution = 0;
        // In a real system, we'd iterate over an array of funder addresses to sum up total contributions.
        // For this demo, let's assume total contributions is `proposal.totalFunded - proposal.initialStake`
        // (rough estimate, as initialStake is by researcher).
        // Let's iterate conceptually to show the intent, assuming `funders` mapping keys can be accessed.
        // This part needs real data structure (e.g. array of funders) in a production contract.
        // For this demo, we can simplify: funder rewards are a portion of funds remaining *after* researcher & owner.

        // Calculate total funds already 'claimed' by researcher through milestone rewards + owner fees
        uint256 alreadyDistributedToResearcherAndOwner = 0;
        // This requires summing up all milestone payouts for researcher and owner fees which is complex without iteration.

        // Simplified approach for demo: if project succeeds, funders get their original contribution back, plus a bonus.
        // If it fails, they get a proportional refund of remaining funds.
        if (proposal.status == ProposalStatus.Completed) {
            for (address funderAddress : proposal.funders.keys()) { // Pseudo-code for map iteration
                uint256 funderContribution = proposal.funders[funderAddress];
                if (funderContribution > 0) {
                    // Example: 10% bonus on contribution for successful project
                    uint256 bonus = (funderContribution * 10) / 100;
                    claimedRewards[_proposalId][funderAddress] += (funderContribution + bonus);
                }
            }
        } else if (proposal.status == ProposalStatus.Failed) {
            // Refund remaining funds proportionally. Total funds available for refund would be
            // `address(this).balance` MINUS funds set aside for researcher/owner.
            // For demo simplicity, let's assume a conceptual 50% refund.
            for (address funderAddress : proposal.funders.keys()) { // Pseudo-code for map iteration
                uint256 funderContribution = proposal.funders[funderAddress];
                if (funderContribution > 0) {
                    uint256 refundAmount = (funderContribution * 50) / 100; // Example: 50% refund
                    claimedRewards[_proposalId][funderAddress] += refundAmount;
                }
            }
        }
    }


    // --- V. Reputation & Governance (SBT & DAO-like) ---

    /// @notice Mints a Soul-Bound Token (SBT) to acknowledge a researcher's significant achievement.
    /// @dev Can only be called by the owner or via a successful governance proposal.
    /// @param _recipient The address to mint the SBT to.
    /// @param _badgeType The specific type of SBT badge (e.g., "Verified Innovator", "Grand Researcher").
    function mintResearcherSBT(address _recipient, string memory _badgeType) external onlyOwner notPaused {
        // In a real system, this would interact with a separate SBT contract (e.g., ERC721-compliant).
        // For demo, we use a simple mapping to track SBT ownership.
        require(_recipient != address(0), "Recipient cannot be zero address.");
        require(bytes(_badgeType).length > 0, "Badge type cannot be empty.");
        require(!hasSBT[_recipient][_badgeType], "Recipient already has this SBT badge.");

        hasSBT[_recipient][_badgeType] = true;
        emit ResearcherSBTMinted(_recipient, _badgeType);
    }

    /// @notice Mints an SBT to recognize outstanding contributions from a peer reviewer.
    /// @dev Can only be called by the owner or via a successful governance proposal.
    /// @param _recipient The address to mint the SBT to.
    /// @param _badgeType The specific type of SBT badge (e.g., "Top Reviewer", "Insightful Critic").
    function mintReviewerSBT(address _recipient, string memory _badgeType) external onlyOwner notPaused {
        // In a real system, this would interact with a separate SBT contract.
        // For demo, we use a simple mapping.
        require(_recipient != address(0), "Recipient cannot be zero address.");
        require(bytes(_badgeType).length > 0, "Badge type cannot be empty.");
        require(!hasSBT[_recipient][_badgeType], "Recipient already has this SBT badge.");

        hasSBT[_recipient][_badgeType] = true;
        emit ReviewerSBTMinted(_recipient, _badgeType);
    }

    /// @notice Allows qualified participants to propose a contract parameter change or action to be voted on by the DAO.
    /// @dev Proposal requires a stake or certain SBTs. For simplicity, only owner can propose here, or specific SBT holders.
    /// @param _descriptionIpfsHash IPFS hash for detailed proposal description.
    /// @param _target The address of the contract to call (usually `address(this)` for self-governance).
    /// @param _calldataPayload The encoded function call data for the proposed action.
    function proposeGovernanceChange(
        string memory _descriptionIpfsHash,
        address _target,
        bytes memory _calldataPayload
    ) external onlyOwner notPaused returns (uint256) {
        // In a real DAO, `onlyOwner` would be replaced by `require(hasSBT[msg.sender]["Governor"] == true || ...)`
        // or a token-based staking requirement.
        require(bytes(_descriptionIpfsHash).length > 0, "Description IPFS hash cannot be empty.");
        require(_target != address(0), "Target address cannot be zero.");
        require(_calldataPayload.length > 0, "Calldata payload cannot be empty.");

        uint256 proposalId = nextGovernanceProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            proposer: msg.sender,
            descriptionIpfsHash: _descriptionIpfsHash,
            target: _target,
            calldataPayload: _calldataPayload,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + 7 days, // 7-day voting period
            votesFor: 0,
            votesAgainst: 0,
            status: GovernanceStatus.Pending,
            hasVoted: new mapping(address => bool)() // Initialize mapping
        });

        emit GovernanceProposalCreated(proposalId, msg.sender, _descriptionIpfsHash);
        return proposalId;
    }

    /// @notice Enables participants to cast their vote (for or against) on an active governance proposal.
    /// @dev Voting power might be influenced by SBTs or stake, not implemented in this demo.
    /// @param _proposalId The ID of the governance proposal.
    /// @param _for True for a 'yes' vote, false for a 'no' vote.
    function voteOnGovernanceProposal(uint256 _proposalId, bool _for) external notPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposer != address(0), "Governance proposal does not exist.");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "Voting is not active.");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal.");

        // In a real DAO, voting power would be calculated here (e.g., 1 vote per SBT, or weighted by staked tokens).
        // For simplicity, each unique voter has 1 vote.
        if (_for) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit GovernanceVoteCast(_proposalId, msg.sender, _for);
    }

    /// @notice Executes a governance proposal that has successfully passed the voting period and met quorum requirements.
    /// @dev Anyone can trigger execution once conditions are met.
    /// @param _proposalId The ID of the governance proposal.
    function executeGovernanceProposal(uint256 _proposalId) external notPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposer != address(0), "Governance proposal does not exist.");
        require(block.timestamp > proposal.voteEndTime, "Voting period has not ended.");
        require(proposal.status == GovernanceStatus.Pending, "Proposal already executed or rejected.");

        // Simple majority and minimum turnout (quorum) for demo purposes.
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 minTurnout = 1; // Example: Minimum 1 vote for demo. Real DAOs use a % of total supply/staked tokens.

        if (totalVotes >= minTurnout && proposal.votesFor > proposal.votesAgainst) {
            // Execute the proposal
            (bool success, ) = proposal.target.call(proposal.calldataPayload);
            require(success, "Governance proposal execution failed.");
            proposal.status = GovernanceStatus.Executed;
            emit GovernanceProposalExecuted(_proposalId);
        } else {
            proposal.status = GovernanceStatus.Rejected;
            // Optionally, refund proposer stake if it was implemented.
        }
    }

    // --- VI. Prediction Market (on proposal success) ---

    /// @notice Allows users to place a bet on the overall success or failure of a specific research proposal.
    /// @dev Funds are pooled and distributed to correct predictors upon proposal finalization.
    /// @param _proposalId The ID of the proposal to predict on.
    /// @param _predictSuccess True if predicting success, false if predicting failure.
    function placePrediction(uint256 _proposalId, bool _predictSuccess) external payable notPaused {
        require(msg.value > 0, "Must send ETH for prediction.");
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.researcher != address(0), "Proposal does not exist.");
        require(proposal.status == ProposalStatus.Pending || proposal.status == ProposalStatus.Active, "Cannot predict on finalized or cancelled proposals.");
        require(!proposal.outcomeDetermined, "Outcome already determined.");
        require(proposal.predictionAmounts[msg.sender] == 0, "Already placed a prediction for this proposal.");

        proposal.predictionPool += msg.value;
        if (_predictSuccess) {
            proposal.predictionSuccessPool += msg.value;
        } else {
            proposal.predictionFailPool += msg.value;
        }
        proposal.hasPredictedSuccess[msg.sender] = _predictSuccess;
        proposal.predictionAmounts[msg.sender] = msg.value;

        emit PredictionPlaced(_proposalId, msg.sender, _predictSuccess, msg.value);
    }

    /// @dev Internal function to settle the prediction market once a proposal's outcome is determined.
    /// @param _proposalId The ID of the proposal.
    function _settlePredictionMarket(uint256 _proposalId) internal {
        ResearchProposal storage proposal = proposals[_proposalId];
        if (proposal.predictionPool == 0) return; // No predictions made

        bool actualSuccess = (proposal.status == ProposalStatus.Completed);
        uint256 totalWinningPool;
        uint256 totalLosingFunds; // Funds from the losing side to be distributed

        if (actualSuccess) {
            totalWinningPool = proposal.predictionSuccessPool;
            totalLosingFunds = proposal.predictionFailPool;
        } else {
            totalWinningPool = proposal.predictionFailPool;
            totalLosingFunds = proposal.predictionSuccessPool;
        }

        if (totalWinningPool == 0) {
            // No one predicted correctly, funds remain in contract or are redirected (e.g., to discovery pool)
            claimedRewards[_proposalId][owner] += proposal.predictionPool; // For demo, owner gets it.
            return;
        }

        // Distribute `totalLosingFunds` proportionally among `totalWinningPool` participants.
        // This requires iterating over all predictors, which isn't direct for mappings.
        // For demonstration purposes, we assume an internal mechanism updates `claimedRewards` for each winner.
        // This part would ideally be an iterable list of all predictors or a specific `calculatePredictionWinnings` func.

        // Placeholder loop for setting `claimedRewards` for winners:
        // In a real system, you'd iterate through all addresses that predicted on this proposal
        // and if their `hasPredictedSuccess[addr]` matches `actualSuccess`, you calculate their share.
        // For simplicity, let's assume we can loop over all `predictionAmounts` keys (conceptual).
        
        // This is a conceptual placeholder. A real implementation would iterate `predictionAmounts` and `hasPredictedSuccess`
        // of all participants in `_proposalId` to populate `claimedRewards`.
        // Example for how it *would* work for a specific `winnerAddress`:
        // uint256 winnerAmount = proposal.predictionAmounts[winnerAddress];
        // if ((proposal.hasPredictedSuccess[winnerAddress] && actualSuccess) || (!proposal.hasPredictedSuccess[winnerAddress] && !actualSuccess)) {
        //     uint256 winnings = (winnerAmount * totalLosingFunds) / totalWinningPool;
        //     claimedRewards[_proposalId][winnerAddress] += (winnerAmount + winnings); // Original bet + winnings
        // }
    }


    /// @notice Enables users with accurate predictions to claim their share of the prediction pool for a finalized proposal.
    /// @dev Assumes `_settlePredictionMarket` has already populated `claimedRewards` for winners.
    /// @param _proposalId The ID of the proposal.
    function claimPredictionWinnings(uint256 _proposalId) external notPaused {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.researcher != address(0), "Proposal does not exist.");
        require(proposal.outcomeDetermined, "Proposal outcome not yet determined.");
        
        // This function relies on `_settlePredictionMarket` (or similar logic)
        // having calculated and queued the winnings into `claimedRewards[_proposalId][msg.sender]`.
        // The funds for winning predictions are implicitly added to `claimedRewards` when the project is finalized.
        uint256 amountToTransfer = claimedRewards[_proposalId][msg.sender];
        require(amountToTransfer > 0, "No prediction winnings to claim for this address.");

        claimedRewards[_proposalId][msg.sender] = 0; // Reset claimed amount
        payable(msg.sender).transfer(amountToTransfer);
        emit PredictionWinningsClaimed(_proposalId, msg.sender, amountToTransfer);
    }

    // Fallback function to receive Ether
    receive() external payable {
        // Option to handle direct Ether transfers, e.g., to Discovery Pool.
        // For now, no specific action, it just receives and increases contract balance.
    }

    // Helper for debugging/owner
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Pseudo-code for map iteration for clarity in conceptual functions.
    // This is not actual Solidity syntax for `mapping.keys()`.
    // In a real contract, an `address[]` of participants would be maintained.
    function keys() private pure returns (address[] memory) {
        revert("Not implemented: Mapping keys cannot be iterated directly in Solidity.");
        // This function is purely for illustrating conceptual loops in comments/internal functions.
    }
}
```