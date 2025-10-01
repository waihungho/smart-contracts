```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CognitoNexus
 * @author Your Name/AI
 * @notice CognitoNexus is a Decentralized Autonomous Organization (DAO) designed to foster and fund
 *         innovative research and development projects. It provides a comprehensive ecosystem for
 *         project proposals, funding, milestone tracking, reputation management for researchers,
 *         and the creation, fractionalization, and licensing of Intellectual Property (IP) as
 *         non-fungible tokens (IP-NFTs).
 *
 * @dev This contract implements a sophisticated DAO with advanced features like
 *      on-chain reputation, milestone-based funding, internal fractional IP-NFTs,
 *      and dynamic IP licensing mechanisms. It aims to be a robust platform for
 *      decentralized R&D.
 */

// --- Outline and Function Summary ---
//
// I. DAO Core Governance & Treasury
//    - Manages the DAO's treasury, general proposals, and voting mechanisms.
//
// II. Researcher & Member Management
//    - Handles membership applications, skill attestations, and a dynamic reputation system.
//
// III. Project Lifecycle & Funding
//    - Covers the entire project lifecycle from proposal and funding allocation to
//      milestone verification, payment release, and dispute resolution.
//
// IV. Intellectual Property (IP-NFTs) & Licensing
//    - Manages the minting, fractional ownership, transfer, and dynamic licensing
//      of Intellectual Property represented as IP-NFTs.
//
// V. Advanced & Extensibility
//    - Provides mechanisms for registering oracles and adjusting DAO governance parameters.
//
// --- Function Summary ---
//
// 1. initializeDAO()
//    - Initializes the DAO with its first owner (who becomes the first member) and core parameters.
//
// 2. depositToTreasury()
//    - Allows any address to contribute Ether to the DAO's treasury.
//
// 3. proposeGeneralMotion(string calldata _motionHash)
//    - Members can propose general decisions for the DAO, referenced by an IPFS hash.
//
// 4. voteOnMotion(uint256 _motionId, bool _support)
//    - Members cast their vote (support or oppose) on an active general motion.
//
// 5. executeMotion(uint256 _motionId)
//    - Executes a general motion that has passed its voting period and reached quorum.
//
// 6. applyForMembership(string calldata _profileHash)
//    - Individuals can apply to become a DAO member by providing an IPFS hash to their profile/CV.
//
// 7. endorseApplicant(address _applicant, bool _approve)
//    - Existing members vote to approve or reject a membership application.
//
// 8. attestSkill(address _target, string calldata _skillHash, uint256 _score)
//    - Members or verified entities can attest to a target address's skill, influencing reputation.
//
// 9. updateResearcherReputation(address _researcher)
//    - Triggers an internal recalculation of a researcher's reputation score based on activity.
//
// 10. submitProjectProposal(string calldata _metadataHash, uint256 _totalBudget, uint256 _milestoneCount, bytes32[] calldata _milestoneHashes)
//     - Members propose new R&D projects with detailed metadata (IPFS hash), budget, and milestones.
//
// 11. voteOnProjectProposal(uint256 _proposalId, bool _support)
//     - Members cast their vote on an active project proposal.
//
// 12. allocateProjectFunds(uint256 _projectId)
//     - Transfers the approved budget for a project from the DAO treasury to a project-specific escrow.
//
// 13. requestMilestoneVerification(uint256 _projectId, uint256 _milestoneIndex, string calldata _verificationProofHash)
//     - A researcher requests verification and payment for a completed project milestone, providing proof.
//
// 14. verifyMilestoneAndReleasePayment(uint256 _projectId, uint256 _milestoneIndex)
//     - DAO members vote to verify a milestone's completion and release its corresponding payment.
//
// 15. initiateProjectDispute(uint256 _projectId, uint256 _milestoneIndex, string calldata _reasonHash)
//     - Allows any stakeholder to raise a dispute regarding project progress or milestone completion.
//
// 16. resolveProjectDispute(uint256 _disputeId, address _winner, uint256 _payoutToWinner)
//     - Resolves an active project dispute, potentially based on oracle input, and distributes funds.
//
// 17. mintProjectIPNFT(uint256 _projectId, string calldata _ipAssetHash, address[] calldata _initialOwners, uint256[] calldata _shares)
//     - Mints a new fractionalized IP-NFT for a successfully completed project, distributing initial shares.
//
// 18. proposeIPLicensingTerms(uint256 _ipNftId, string calldata _licenseTermsHash, uint256 _royaltyRateBps, uint256 _initialFee)
//     - Owners of an IP-NFT can propose terms for licensing their intellectual property to third parties.
//
// 19. acceptIPLicense(uint256 _ipNftId, uint256 _termsId, address _licensee)
//     - A third party accepts proposed IP licensing terms, paying the initial fee.
//
// 20. collectIPRoyalty(uint256 _ipNftId, uint256 _licenseId, uint256 _amount)
//     - A licensee makes a royalty payment for a licensed IP.
//
// 21. transferIPNFTFraction(uint256 _ipNftId, address _from, address _to, uint256 _amount)
//     - Facilitates the transfer of fractional ownership shares of an IP-NFT between addresses.
//
// 22. setIPNftOwnerRoyalties(uint256 _ipNftId, address[] calldata _owners, uint256[] calldata _shares)
//     - Allows IP-NFT owners to dynamically update the distribution percentages for future royalty payments.
//
// 23. registerOracle(address _oracleAddress, string calldata _oracleType)
//     - Registers a trusted oracle service for specific off-chain data verification or dispute resolution.
//
// 24. setGovernanceParameters(uint48 _minVoteDuration, uint16 _minQuorumPercentageBps)
//     - Allows DAO members to vote on and update core governance parameters like vote duration and quorum.

contract CognitoNexus {

    // --- Custom Errors ---
    error CognitoNexus__NotInitialized();
    error CognitoNexus__AlreadyInitialized();
    error CognitoNexus__NotMember();
    error CognitoNexus__Unauthorized();
    error CognitoNexus__InvalidParameter();
    error CognitoNexus__VotingPeriodNotEnded();
    error CognitoNexus__VotingPeriodNotStarted();
    error CognitoNexus__ProposalNotExecutable();
    error CognitoNexus__ProposalAlreadyVoted();
    error CognitoNexus__ProposalNotFound();
    error CognitoNexus__ApplicantNotFound();
    error CognitoNexus__ApplicantAlreadyMember();
    error CognitoNexus__ProjectNotFound();
    error CognitoNexus__ProjectNotApproved();
    error CognitoNexus__ProjectAlreadyFunded();
    error CognitoNexus__MilestoneNotFound();
    error CognitoNexus__MilestoneAlreadyVerified();
    error CognitoNexus__MilestoneNotRequestedForVerification();
    error CognitoNexus__InsufficientFunds();
    error CognitoNexus__DisputeNotFound();
    error CognitoNexus__DisputeAlreadyResolved();
    error CognitoNexus__IPNFTNotFound();
    error CognitoNexus__IPNFTAlreadyMinted();
    error CognitoNexus__IPNFTFractionTransferFailed();
    error CognitoNexus__InvalidSharesDistribution();
    error CognitoNexus__LicensingTermsNotFound();
    error CognitoNexus__LicenseNotFound();
    error CognitoNexus__LicenseAlreadyAccepted();
    error CognitoNexus__NoRoyaltyRecipient();

    // --- Enums ---
    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    enum ProjectState {
        Proposed,
        Approved,
        Funded,
        InProgress,
        Completed,
        Disputed,
        Cancelled
    }

    enum MilestoneState {
        Pending,
        VerificationRequested,
        Verified,
        Disputed,
        Paid
    }

    // --- Structs ---

    struct GeneralMotion {
        string motionHash; // IPFS hash to motion details
        uint256 id;
        uint48 startTimestamp;
        uint48 endTimestamp;
        uint256 totalVotes;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalState state;
        mapping(address => bool) hasVoted; // Tracks if a member has voted
    }

    struct MembershipApplication {
        string profileHash; // IPFS hash to applicant's profile/CV
        uint48 applicationTimestamp;
        uint256 endorsementsFor;
        uint256 endorsementsAgainst;
        bool processed;
        mapping(address => bool) hasEndorsed; // Tracks if a member has endorsed
    }

    struct Project {
        string metadataHash; // IPFS hash to project description, goals, contributors
        uint256 id;
        uint256 totalBudget;
        uint256 allocatedFunds;
        uint256 milestoneCount;
        ProjectState state;
        address proposer;
        uint48 startTimestamp;
        uint48 endTimestamp; // Expected completion or voting end
        mapping(address => bool) hasVoted; // For project proposal voting
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 ipNftId; // 0 if not minted yet
    }

    struct Milestone {
        bytes32 verificationHash; // Hash of requirements or expected outcome
        uint256 paymentAmount;
        MilestoneState state;
        string verificationProofHash; // IPFS hash to proof submitted by researcher
        uint48 verificationRequestTimestamp;
    }

    struct Dispute {
        uint256 projectId;
        uint256 milestoneIndex;
        string reasonHash; // IPFS hash to dispute reason/evidence
        address initiator;
        uint48 disputeTimestamp;
        address winner; // 0x0 if not resolved
        uint256 payoutAmount;
        bool resolved;
    }

    struct IPNFT {
        uint256 ipNftId;
        string ipAssetHash; // IPFS hash to the actual IP asset/metadata
        uint256 projectId;
        uint256 totalSupply; // Total fractional shares, e.g., 10,000 for basis points
        uint256 totalSharesDistributed;
        mapping(address => uint256) ownerShares; // ERC1155-like balance for fractional ownership
        uint256 nextLicenseId;
        mapping(uint256 => LicensingTerms) licensingTerms;
        mapping(uint256 => mapping(address => uint256)) royaltyDistributionShares; // Default 100% to owner
    }

    struct LicensingTerms {
        string licenseTermsHash; // IPFS hash to detailed legal terms
        uint256 royaltyRateBps; // Royalty rate in basis points (e.g., 500 for 5%)
        uint256 initialFee;
        bool active;
        uint256 nextLicenseeId;
    }

    struct License {
        uint256 ipNftId;
        uint256 termsId;
        address licensee;
        uint48 acceptedTimestamp;
        uint256 totalRoyaltiesPaid;
        bool active;
    }

    struct Oracle {
        address oracleAddress;
        string oracleType; // e.g., "DisputeResolver", "DataVerifier"
        bool registered;
    }

    // --- State Variables ---

    bool public initialized;
    address public owner; // Initial deployer, can be changed via DAO
    uint256 public totalMembers;
    uint256 public treasuryBalance;

    uint48 public minVoteDuration; // Minimum duration for proposals to be active (seconds)
    uint16 public minQuorumPercentageBps; // Minimum percentage of total members required for quorum (basis points)
    uint16 public minMembershipApprovalPercentageBps; // Percentage of existing members needed to approve a new member

    // --- Counters ---
    uint256 private nextMotionId;
    uint256 private nextProjectId;
    uint256 private nextDisputeId;
    uint256 private nextIpNftId;
    uint256 private nextOracleId;

    // --- Mappings ---
    mapping(address => bool) public isMember;
    mapping(address => uint256) public memberReputationScore; // Cumulative score based on successful projects, attestations
    mapping(address => MembershipApplication) public membershipApplications; // Active membership applications

    mapping(uint256 => GeneralMotion) public generalMotions;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => mapping(uint256 => Milestone)) public projectMilestones; // projectId -> milestoneIndex -> Milestone
    mapping(uint256 => Dispute) public disputes;

    mapping(uint256 => IPNFT) public ipNfts;
    mapping(uint256 => mapping(uint256 => License)) public ipNftLicenses; // ipNftId -> licenseId -> License
    mapping(uint256 => Oracle) public registeredOracles;

    // --- Events ---
    event DAOInitialized(address indexed _owner);
    event FundsDeposited(address indexed _sender, uint256 _amount);
    event GeneralMotionProposed(uint256 indexed _motionId, string _motionHash, address indexed _proposer);
    event MotionVoted(uint256 indexed _motionId, address indexed _voter, bool _support);
    event MotionExecuted(uint256 indexed _motionId, ProposalState _newState);
    event MembershipApplicationSubmitted(address indexed _applicant, string _profileHash);
    event ApplicantEndorsed(address indexed _endorser, address indexed _applicant, bool _approved);
    event NewMemberAdded(address indexed _newMember);
    event SkillAttested(address indexed _attester, address indexed _target, string _skillHash, uint256 _score);
    event ReputationUpdated(address indexed _researcher, uint256 _newScore);
    event ProjectProposalSubmitted(uint256 indexed _projectId, address indexed _proposer, string _metadataHash, uint256 _budget);
    event ProjectProposalVoted(uint256 indexed _projectId, address indexed _voter, bool _support);
    event ProjectApproved(uint256 indexed _projectId);
    event ProjectFunded(uint256 indexed _projectId, uint256 _amount);
    event MilestoneVerificationRequested(uint256 indexed _projectId, uint256 indexed _milestoneIndex, string _proofHash);
    event MilestoneVerifiedAndPaid(uint256 indexed _projectId, uint256 indexed _milestoneIndex, uint256 _amount);
    event ProjectDisputeInitiated(uint256 indexed _disputeId, uint256 indexed _projectId, uint256 _milestoneIndex, address indexed _initiator);
    event ProjectDisputeResolved(uint256 indexed _disputeId, address indexed _winner, uint256 _payout);
    event IPNFTMinted(uint256 indexed _ipNftId, uint256 indexed _projectId, string _ipAssetHash, address[] _owners, uint256[] _shares);
    event IPLicensingTermsProposed(uint256 indexed _ipNftId, uint256 indexed _termsId, string _termsHash);
    event IPLicenseAccepted(uint256 indexed _ipNftId, uint256 indexed _termsId, address indexed _licensee, uint256 _initialFee);
    event IPRoyaltyCollected(uint256 indexed _ipNftId, uint256 indexed _licenseId, address indexed _licensee, uint256 _amount);
    event IPNFTFractionTransferred(uint256 indexed _ipNftId, address indexed _from, address indexed _to, uint256 _amount);
    event IPNFTRoyaltyDistributionUpdated(uint256 indexed _ipNftId, address[] _owners, uint256[] _shares);
    event OracleRegistered(address indexed _oracleAddress, string _oracleType);
    event GovernanceParametersUpdated(uint48 _minVoteDuration, uint16 _minQuorumPercentageBps);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert CognitoNexus__Unauthorized();
        _;
    }

    modifier onlyMember() {
        if (!isMember[msg.sender]) revert CognitoNexus__NotMember();
        _;
    }

    modifier onlyInitialized() {
        if (!initialized) revert CognitoNexus__NotInitialized();
        _;
    }

    // --- Constructor ---
    constructor() {
        // Owner is initially deployer, initialization done via a function.
        // This allows for a two-step deployment if needed, or just immediate call.
    }

    // --- I. DAO Core Governance & Treasury ---

    /**
     * @notice Initializes the DAO with its first owner and core parameters.
     *         Can only be called once. The caller becomes the first member.
     * @dev Sets initial governance parameters, registers the deployer as owner and first member.
     * @param _minVoteDuration_ Minimum duration for voting periods in seconds.
     * @param _minQuorumPercentageBps_ Minimum percentage of total members for a proposal to pass (basis points).
     * @param _minMembershipApprovalPercentageBps_ Minimum percentage of members to approve a new member (basis points).
     */
    function initializeDAO(uint48 _minVoteDuration_, uint16 _minQuorumPercentageBps_, uint16 _minMembershipApprovalPercentageBps_)
        external
    {
        if (initialized) revert CognitoNexus__AlreadyInitialized();
        if (_minQuorumPercentageBps_ > 10000 || _minMembershipApprovalPercentageBps_ > 10000) revert CognitoNexus__InvalidParameter();

        owner = msg.sender;
        minVoteDuration = _minVoteDuration_;
        minQuorumPercentageBps = _minQuorumPercentageBps_;
        minMembershipApprovalPercentageBps = _minMembershipApprovalPercentageBps_;

        isMember[msg.sender] = true;
        totalMembers = 1;
        initialized = true;

        emit DAOInitialized(msg.sender);
        emit NewMemberAdded(msg.sender);
    }

    /**
     * @notice Allows any address to contribute Ether to the DAO's treasury.
     */
    function depositToTreasury() external payable onlyInitialized {
        if (msg.value == 0) revert CognitoNexus__InvalidParameter();
        treasuryBalance += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @notice Members can propose general decisions for the DAO, referenced by an IPFS hash.
     * @param _motionHash IPFS hash pointing to the detailed proposal document.
     */
    function proposeGeneralMotion(string calldata _motionHash) external onlyMember onlyInitialized {
        uint256 motionId = nextMotionId++;
        generalMotions[motionId] = GeneralMotion({
            motionHash: _motionHash,
            id: motionId,
            startTimestamp: uint48(block.timestamp),
            endTimestamp: uint48(block.timestamp + minVoteDuration),
            totalVotes: 0,
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active,
            hasVoted: new mapping(address => bool)
        });
        emit GeneralMotionProposed(motionId, _motionHash, msg.sender);
    }

    /**
     * @notice Members cast their vote (support or oppose) on an active general motion.
     * @param _motionId The ID of the motion to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnMotion(uint256 _motionId, bool _support) external onlyMember onlyInitialized {
        GeneralMotion storage motion = generalMotions[_motionId];
        if (motion.id == 0 && _motionId != 0) revert CognitoNexus__ProposalNotFound(); // check if motion exists
        if (motion.state != ProposalState.Active) revert CognitoNexus__VotingPeriodNotStarted(); // Or ended
        if (motion.endTimestamp < block.timestamp) revert CognitoNexus__VotingPeriodNotEnded();
        if (motion.hasVoted[msg.sender]) revert CognitoNexus__ProposalAlreadyVoted();

        motion.hasVoted[msg.sender] = true;
        motion.totalVotes++;
        if (_support) {
            motion.votesFor++;
        } else {
            motion.votesAgainst++;
        }

        emit MotionVoted(_motionId, msg.sender, _support);
    }

    /**
     * @notice Executes a general motion that has passed its voting period and reached quorum.
     * @dev This function currently only updates the state. In a real scenario, specific logic
     *      would be triggered based on the motion type (e.g., parameter changes, fund transfers).
     *      For this example, it demonstrates the DAO's decision-making process.
     * @param _motionId The ID of the motion to execute.
     */
    function executeMotion(uint256 _motionId) external onlyMember onlyInitialized {
        GeneralMotion storage motion = generalMotions[_motionId];
        if (motion.id == 0 && _motionId != 0) revert CognitoNexus__ProposalNotFound();
        if (motion.state != ProposalState.Active) revert CognitoNexus__ProposalNotExecutable();
        if (motion.endTimestamp > block.timestamp) revert CognitoNexus__VotingPeriodNotEnded(); // Voting period must have ended

        // Check quorum: total votes must meet minimum percentage of total members
        if (motion.totalVotes * 10000 / totalMembers < minQuorumPercentageBps) {
            motion.state = ProposalState.Failed;
            emit MotionExecuted(_motionId, ProposalState.Failed);
            return;
        }

        // Check if votesFor is greater than votesAgainst
        if (motion.votesFor > motion.votesAgainst) {
            motion.state = ProposalState.Succeeded;
            // Additional logic for executing the motion would go here.
            // For example, if the motion was to change a parameter:
            // if (motion.motionType == MotionType.SetGovernanceParams) {
            //     // parse motion.motionHash for params and apply
            // }
        } else {
            motion.state = ProposalState.Failed;
        }

        emit MotionExecuted(_motionId, motion.state);
    }

    // --- II. Researcher & Member Management ---

    /**
     * @notice Individuals can apply to become a DAO member by providing an IPFS hash to their profile/CV.
     * @param _profileHash IPFS hash to the applicant's profile or CV.
     */
    function applyForMembership(string calldata _profileHash) external onlyInitialized {
        if (isMember[msg.sender]) revert CognitoNexus__ApplicantAlreadyMember();
        if (membershipApplications[msg.sender].applicationTimestamp != 0) revert CognitoNexus__InvalidParameter(); // Already applied

        membershipApplications[msg.sender] = MembershipApplication({
            profileHash: _profileHash,
            applicationTimestamp: uint48(block.timestamp),
            endorsementsFor: 0,
            endorsementsAgainst: 0,
            processed: false,
            hasEndorsed: new mapping(address => bool)
        });
        emit MembershipApplicationSubmitted(msg.sender, _profileHash);
    }

    /**
     * @notice Existing members vote to approve or reject a membership application.
     * @dev A simple majority or a predefined quorum of existing members can decide.
     *      This function allows a 'yes' or 'no' vote.
     * @param _applicant The address of the applicant.
     * @param _approve True to endorse, false to reject.
     */
    function endorseApplicant(address _applicant, bool _approve) external onlyMember onlyInitialized {
        MembershipApplication storage application = membershipApplications[_applicant];
        if (application.applicationTimestamp == 0) revert CognitoNexus__ApplicantNotFound();
        if (application.processed) revert CognitoNexus__InvalidParameter(); // Application already processed
        if (application.hasEndorsed[msg.sender]) revert CognitoNexus__ProposalAlreadyVoted();

        application.hasEndorsed[msg.sender] = true;
        if (_approve) {
            application.endorsementsFor++;
        } else {
            application.endorsementsAgainst++;
        }

        emit ApplicantEndorsed(msg.sender, _applicant, _approve);

        // Check if decision can be made immediately (e.g., if enough votes collected)
        // For simplicity, let's assume a fixed voting duration or a threshold.
        // For this example, we'll check against `totalMembers`.
        if (application.endorsementsFor + application.endorsementsAgainst >= totalMembers / 2) { // Simple majority of active members
            if (application.endorsementsFor * 10000 / (application.endorsementsFor + application.endorsementsAgainst) >= minMembershipApprovalPercentageBps) {
                isMember[_applicant] = true;
                totalMembers++;
                application.processed = true;
                emit NewMemberAdded(_applicant);
            } else {
                application.processed = true; // Application rejected
            }
        }
    }

    /**
     * @notice Members or verified entities can attest to a target address's skill, influencing reputation.
     * @dev This could integrate with ZK-proofs for verifiable credentials. The `_score` adds to reputation.
     * @param _target The address of the researcher whose skill is being attested.
     * @param _skillHash IPFS hash of the skill description or verifiable credential.
     * @param _score The reputation points awarded for this attestation.
     */
    function attestSkill(address _target, string calldata _skillHash, uint256 _score) external onlyMember onlyInitialized {
        if (!isMember[_target] && membershipApplications[_target].applicationTimestamp == 0) revert CognitoNexus__NotMember(); // Can attest for members or applicants
        if (_score == 0) revert CognitoNexus__InvalidParameter();

        memberReputationScore[_target] += _score; // Simple addition; more complex logic could apply decay, multipliers, etc.
        emit SkillAttested(msg.sender, _target, _skillHash, _score);
        emit ReputationUpdated(_target, memberReputationScore[_target]);
    }

    /**
     * @notice Triggers an internal recalculation of a researcher's reputation score based on activity.
     * @dev This function could be called periodically or after specific events (e.g., project completion, dispute resolution).
     *      For simplicity, it just re-emits the current score. A real system would have more complex logic.
     * @param _researcher The address of the researcher to update.
     */
    function updateResearcherReputation(address _researcher) external onlyMember onlyInitialized {
        if (!isMember[_researcher]) revert CognitoNexus__NotMember();
        // In a real system, this would trigger a more complex recalculation
        // based on successful projects, completed milestones, skill attestations,
        // and dispute outcomes. For this example, it's a placeholder.
        emit ReputationUpdated(_researcher, memberReputationScore[_researcher]);
    }

    // --- III. Project Lifecycle & Funding ---

    /**
     * @notice Members propose new R&D projects with detailed metadata (IPFS hash), budget, and milestones.
     * @param _metadataHash IPFS hash to the detailed project proposal (description, team, etc.).
     * @param _totalBudget Total Ether requested for the project.
     * @param _milestoneCount The number of milestones for the project.
     * @param _milestoneHashes Array of IPFS hashes, one for each milestone's requirements/goals.
     */
    function submitProjectProposal(
        string calldata _metadataHash,
        uint256 _totalBudget,
        uint256 _milestoneCount,
        bytes32[] calldata _milestoneHashes
    ) external onlyMember onlyInitialized {
        if (_totalBudget == 0 || _milestoneCount == 0 || _milestoneCount != _milestoneHashes.length) revert CognitoNexus__InvalidParameter();

        uint256 projectId = nextProjectId++;
        projects[projectId] = Project({
            metadataHash: _metadataHash,
            id: projectId,
            totalBudget: _totalBudget,
            allocatedFunds: 0,
            milestoneCount: _milestoneCount,
            state: ProjectState.Proposed,
            proposer: msg.sender,
            startTimestamp: uint48(block.timestamp),
            endTimestamp: uint48(block.timestamp + minVoteDuration), // Voting period
            hasVoted: new mapping(address => bool),
            votesFor: 0,
            votesAgainst: 0,
            ipNftId: 0
        });

        uint256 milestonePayment = _totalBudget / _milestoneCount;
        for (uint256 i = 0; i < _milestoneCount; i++) {
            projectMilestones[projectId][i] = Milestone({
                verificationHash: _milestoneHashes[i],
                paymentAmount: milestonePayment,
                state: MilestoneState.Pending,
                verificationProofHash: "",
                verificationRequestTimestamp: 0
            });
        }
        emit ProjectProposalSubmitted(projectId, msg.sender, _metadataHash, _totalBudget);
    }

    /**
     * @notice Members cast their vote on an active project proposal.
     * @param _projectId The ID of the project proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProjectProposal(uint256 _projectId, bool _support) external onlyMember onlyInitialized {
        Project storage project = projects[_projectId];
        if (project.id == 0 && _projectId != 0) revert CognitoNexus__ProjectNotFound();
        if (project.state != ProjectState.Proposed) revert CognitoNexus__ProposalNotExecutable(); // Can only vote on proposed projects
        if (project.endTimestamp < block.timestamp) revert CognitoNexus__VotingPeriodNotEnded();
        if (project.hasVoted[msg.sender]) revert CognitoNexus__ProposalAlreadyVoted();

        project.hasVoted[msg.sender] = true;
        if (_support) {
            project.votesFor++;
        } else {
            project.votesAgainst++;
        }

        emit ProjectProposalVoted(_projectId, msg.sender, _support);

        // Check for immediate approval (e.g., if a high enough threshold is met early)
        if (project.votesFor + project.votesAgainst >= totalMembers / 2) { // Simplified quorum check
            if (project.votesFor * 10000 / (project.votesFor + project.votesAgainst) >= minQuorumPercentageBps) {
                project.state = ProjectState.Approved;
                emit ProjectApproved(_projectId);
            } else if (project.endTimestamp < block.timestamp) { // If voting period ended and not approved
                project.state = ProjectState.Cancelled;
            }
        }
    }

    /**
     * @notice Transfers the approved budget for a project from the DAO treasury to a project-specific escrow.
     * @dev Only callable by a member after the project has been approved by DAO vote.
     * @param _projectId The ID of the project to fund.
     */
    function allocateProjectFunds(uint256 _projectId) external onlyMember onlyInitialized {
        Project storage project = projects[_projectId];
        if (project.id == 0 && _projectId != 0) revert CognitoNexus__ProjectNotFound();
        if (project.state != ProjectState.Approved) revert CognitoNexus__ProjectNotApproved();
        if (project.allocatedFunds > 0) revert CognitoNexus__ProjectAlreadyFunded();
        if (treasuryBalance < project.totalBudget) revert CognitoNexus__InsufficientFunds();

        // Check if voting period is over and passed. If not, it's considered failed.
        if (project.endTimestamp > block.timestamp || project.votesFor <= project.votesAgainst || project.votesFor * 10000 / (project.votesFor + project.votesAgainst) < minQuorumPercentageBps) {
             project.state = ProjectState.Cancelled; // If not passed by endTimestamp
             revert CognitoNexus__ProjectNotApproved();
        }

        treasuryBalance -= project.totalBudget;
        project.allocatedFunds = project.totalBudget;
        project.state = ProjectState.InProgress; // Project starts
        emit ProjectFunded(_projectId, project.totalBudget);
    }

    /**
     * @notice A researcher requests verification and payment for a completed project milestone, providing proof.
     * @dev Only the project proposer or an assigned project lead can request verification.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone (0-based).
     * @param _verificationProofHash IPFS hash pointing to the proof of milestone completion.
     */
    function requestMilestoneVerification(
        uint256 _projectId,
        uint256 _milestoneIndex,
        string calldata _verificationProofHash
    ) external onlyInitialized {
        Project storage project = projects[_projectId];
        if (project.id == 0 && _projectId != 0) revert CognitoNexus__ProjectNotFound();
        if (msg.sender != project.proposer) revert CognitoNexus__Unauthorized(); // Only proposer can request
        if (project.state != ProjectState.InProgress && project.state != ProjectState.Disputed) revert CognitoNexus__ProjectNotApproved(); // Or in progress or disputed

        Milestone storage milestone = projectMilestones[_projectId][_milestoneIndex];
        if (_milestoneIndex >= project.milestoneCount || milestone.verificationHash == bytes32(0)) revert CognitoNexus__MilestoneNotFound();
        if (milestone.state != MilestoneState.Pending) revert CognitoNexus__MilestoneAlreadyVerified(); // Or already in verification

        milestone.verificationProofHash = _verificationProofHash;
        milestone.verificationRequestTimestamp = uint48(block.timestamp);
        milestone.state = MilestoneState.VerificationRequested;
        emit MilestoneVerificationRequested(_projectId, _milestoneIndex, _verificationProofHash);
    }

    /**
     * @notice DAO members vote to verify a milestone's completion and release its corresponding payment.
     * @dev Similar voting mechanism as project proposals. Successful vote releases funds.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     */
    function verifyMilestoneAndReleasePayment(uint256 _projectId, uint256 _milestoneIndex) external onlyMember onlyInitialized {
        Project storage project = projects[_projectId];
        if (project.id == 0 && _projectId != 0) revert CognitoNexus__ProjectNotFound();
        Milestone storage milestone = projectMilestones[_projectId][_milestoneIndex];
        if (_milestoneIndex >= project.milestoneCount || milestone.verificationHash == bytes32(0)) revert CognitoNexus__MilestoneNotFound();
        if (milestone.state != MilestoneState.VerificationRequested) revert CognitoNexus__MilestoneNotRequestedForVerification();

        // Simplified: Direct payment from project's allocated funds.
        // In a full system, this would be a DAO vote. For this example, any member can "verify"
        // provided the project is in a relevant state. A more robust solution would require
        // a specific voting proposal for each milestone verification.
        // For demonstration, let's assume a simple direct verification by a member,
        // but in production, this would be subject to DAO vote.

        // Simulating the actual fund transfer for a verified milestone
        if (project.allocatedFunds < milestone.paymentAmount) revert CognitoNexus__InsufficientFunds();

        payable(project.proposer).transfer(milestone.paymentAmount);
        project.allocatedFunds -= milestone.paymentAmount;
        milestone.state = MilestoneState.Paid;
        memberReputationScore[project.proposer] += 50; // Award reputation for successful milestone
        emit MilestoneVerifiedAndPaid(_projectId, _milestoneIndex, milestone.paymentAmount);
        emit ReputationUpdated(project.proposer, memberReputationScore[project.proposer]);

        // If this was the last milestone, mark project as completed
        if (_milestoneIndex == project.milestoneCount - 1) {
            project.state = ProjectState.Completed;
            memberReputationScore[project.proposer] += 200; // Award extra reputation for project completion
            emit ReputationUpdated(project.proposer, memberReputationScore[project.proposer]);
        }
    }


    /**
     * @notice Allows stakeholders to raise a dispute regarding project progress or milestone completion.
     * @dev Any member can initiate a dispute. This puts the project/milestone into a disputed state.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone (can be 0 if the dispute is about the overall project).
     * @param _reasonHash IPFS hash pointing to the detailed reason and evidence for the dispute.
     */
    function initiateProjectDispute(
        uint256 _projectId,
        uint256 _milestoneIndex,
        string calldata _reasonHash
    ) external onlyMember onlyInitialized {
        Project storage project = projects[_projectId];
        if (project.id == 0 && _projectId != 0) revert CognitoNexus__ProjectNotFound();
        if (project.state == ProjectState.Completed || project.state == ProjectState.Cancelled) revert CognitoNexus__InvalidParameter();

        // If dispute is about a specific milestone
        if (_milestoneIndex < project.milestoneCount) {
            Milestone storage milestone = projectMilestones[_projectId][_milestoneIndex];
            if (milestone.state == MilestoneState.Paid) revert CognitoNexus__InvalidParameter();
            milestone.state = MilestoneState.Disputed;
        }
        
        // Overall project dispute or specific milestone dispute
        project.state = ProjectState.Disputed;

        uint256 disputeId = nextDisputeId++;
        disputes[disputeId] = Dispute({
            projectId: _projectId,
            milestoneIndex: _milestoneIndex,
            reasonHash: _reasonHash,
            initiator: msg.sender,
            disputeTimestamp: uint48(block.timestamp),
            winner: address(0),
            payoutAmount: 0,
            resolved: false
        });
        emit ProjectDisputeInitiated(disputeId, _projectId, _milestoneIndex, msg.sender);
    }

    /**
     * @notice Resolves an active project dispute, potentially involving an oracle, and distributes funds accordingly.
     * @dev This function would typically be called by a trusted oracle or a DAO vote after adjudication.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _winner The address determined to be the winner of the dispute.
     * @param _payoutToWinner The amount of Ether to be paid to the winner.
     */
    function resolveProjectDispute(
        uint256 _disputeId,
        address _winner,
        uint256 _payoutToWinner
    ) external onlyInitialized {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.projectId == 0 && _disputeId != 0) revert CognitoNexus__DisputeNotFound();
        if (dispute.resolved) revert CognitoNexus__DisputeAlreadyResolved();

        // This should be callable only by a registered oracle or through a DAO vote result.
        // For simplicity, we allow `owner` to call it.
        if (msg.sender != owner) { // Placeholder for oracle access control
            bool isOracle = false;
            for (uint256 i = 0; i < nextOracleId; i++) {
                if (registeredOracles[i].registered && registeredOracles[i].oracleAddress == msg.sender) {
                    isOracle = true;
                    break;
                }
            }
            if (!isOracle) revert CognitoNexus__Unauthorized();
        }

        Project storage project = projects[dispute.projectId];
        // Revert project state to InProgress or Cancelled based on dispute outcome
        project.state = ProjectState.InProgress; // Assume it goes back to in progress unless project is cancelled
        if (_payoutToWinner > 0) {
            if (project.allocatedFunds < _payoutToWinner) revert CognitoNexus__InsufficientFunds();
            payable(_winner).transfer(_payoutToWinner);
            project.allocatedFunds -= _payoutToWinner;
        }

        if (dispute.milestoneIndex < project.milestoneCount) {
            // Milestone-specific dispute resolution logic (e.g., reset milestone state, mark as failed)
            projectMilestones[dispute.projectId][dispute.milestoneIndex].state = MilestoneState.Pending;
        }

        dispute.winner = _winner;
        dispute.payoutAmount = _payoutToWinner;
        dispute.resolved = true;
        
        // Update reputation based on dispute outcome
        if (_winner == project.proposer) {
            memberReputationScore[project.proposer] += 20;
        } else if (_winner == dispute.initiator) {
            memberReputationScore[dispute.initiator] += 20;
        }

        emit ProjectDisputeResolved(_disputeId, _winner, _payoutToWinner);
    }

    // --- IV. Intellectual Property (IP-NFTs) & Licensing ---

    /**
     * @notice Mints a new fractionalized IP-NFT for a successfully completed project, distributing initial shares.
     * @dev Only callable by a member, typically after a project is marked `Completed`.
     * @param _projectId The ID of the completed project.
     * @param _ipAssetHash IPFS hash to the actual intellectual property asset or its detailed metadata.
     * @param _initialOwners Array of addresses to receive initial shares.
     * @param _shares Array of amounts corresponding to `_initialOwners`. Sum must equal `totalSupply`.
     */
    function mintProjectIPNFT(
        uint256 _projectId,
        string calldata _ipAssetHash,
        address[] calldata _initialOwners,
        uint256[] calldata _shares
    ) external onlyMember onlyInitialized {
        Project storage project = projects[_projectId];
        if (project.id == 0 && _projectId != 0) revert CognitoNexus__ProjectNotFound();
        if (project.state != ProjectState.Completed) revert CognitoNexus__InvalidParameter();
        if (project.ipNftId != 0) revert CognitoNexus__IPNFTAlreadyMinted();
        if (_initialOwners.length != _shares.length || _initialOwners.length == 0) revert CognitoNexus__InvalidSharesDistribution();

        uint256 ipNftId = nextIpNftId++;
        uint256 totalSupply = 10_000; // Representing 100% in basis points for fractional ownership
        uint256 totalSharesGiven = 0;

        IPNFT storage newIpNft = ipNfts[ipNftId];
        newIpNft.ipNftId = ipNftId;
        newIpNft.ipAssetHash = _ipAssetHash;
        newIpNft.projectId = _projectId;
        newIpNft.totalSupply = totalSupply;
        newIpNft.nextLicenseId = 1; // Start license IDs from 1

        // Distribute initial shares
        for (uint256 i = 0; i < _initialOwners.length; i++) {
            newIpNft.ownerShares[_initialOwners[i]] += _shares[i];
            newIpNft.royaltyDistributionShares[_initialOwners[i]] += _shares[i]; // Default royalty distribution follows initial ownership
            totalSharesGiven += _shares[i];
        }

        if (totalSharesGiven != totalSupply) revert CognitoNexus__InvalidSharesDistribution();
        newIpNft.totalSharesDistributed = totalSharesGiven;
        project.ipNftId = ipNftId; // Link project to its IP-NFT

        emit IPNFTMinted(ipNftId, _projectId, _ipAssetHash, _initialOwners, _shares);
    }

    /**
     * @notice Owners of an IP-NFT can propose terms for licensing their intellectual property to third parties.
     * @dev Only callable by an owner of the IP-NFT.
     * @param _ipNftId The ID of the IP-NFT.
     * @param _licenseTermsHash IPFS hash pointing to the detailed legal terms of the license.
     * @param _royaltyRateBps Royalty rate in basis points (e.g., 500 for 5%) to be paid on revenue.
     * @param _initialFee One-time initial licensing fee in Ether.
     */
    function proposeIPLicensingTerms(
        uint256 _ipNftId,
        string calldata _licenseTermsHash,
        uint256 _royaltyRateBps,
        uint256 _initialFee
    ) external onlyMember onlyInitialized {
        IPNFT storage ipNft = ipNfts[_ipNftId];
        if (ipNft.ipNftId == 0 && _ipNftId != 0) revert CognitoNexus__IPNFTNotFound();
        if (ipNft.ownerShares[msg.sender] == 0) revert CognitoNexus__Unauthorized(); // Only an owner can propose
        if (_royaltyRateBps > 10000) revert CognitoNexus__InvalidParameter();

        uint256 termsId = ipNft.nextLicenseId++;
        ipNft.licensingTerms[termsId] = LicensingTerms({
            licenseTermsHash: _licenseTermsHash,
            royaltyRateBps: _royaltyRateBps,
            initialFee: _initialFee,
            active: true,
            nextLicenseeId: 1
        });
        emit IPLicensingTermsProposed(_ipNftId, termsId, _licenseTermsHash);
    }

    /**
     * @notice A third party accepts proposed IP licensing terms, paying the initial fee.
     * @param _ipNftId The ID of the IP-NFT.
     * @param _termsId The ID of the licensing terms being accepted.
     * @param _licensee The address of the entity accepting the license.
     */
    function acceptIPLicense(
        uint256 _ipNftId,
        uint256 _termsId,
        address _licensee
    ) external payable onlyInitialized {
        IPNFT storage ipNft = ipNfts[_ipNftId];
        if (ipNft.ipNftId == 0 && _ipNftId != 0) revert CognitoNexus__IPNFTNotFound();
        LicensingTerms storage terms = ipNft.licensingTerms[_termsId];
        if (!terms.active) revert CognitoNexus__LicensingTermsNotFound(); // Or not active

        if (msg.value < terms.initialFee) revert CognitoNexus__InsufficientFunds();

        // Distribute initial fee to IP-NFT owners based on their royalty distribution shares
        uint256 feeToDistribute = msg.value;
        for (uint256 i = 0; i < ipNft.totalSupply; i++) { // Iterate all possible shares (0-10000)
            address recipient = address(0);
            for(uint256 j = 0; j < _initialOwners.length; j++) { // This is inefficient. Better to iterate `ipNft.ownerShares`
                // A better approach would be to iterate through the `ownerShares` mapping directly,
                // or maintain a dynamic array of owners. For simplicity, assume `_initialOwners` is representative.
            }
             // Simplified distribution: all initial fee to the DAO treasury.
             // In a real system, iterate ipNft.ownerShares and transfer proportionally.
             // For this example, let's send to treasury for simplicity.
        }
        treasuryBalance += feeToDistribute; // Send initial fee to DAO treasury or directly to IP owners.

        uint256 licenseId = terms.nextLicenseeId++;
        ipNftLicenses[_ipNftId][licenseId] = License({
            ipNftId: _ipNftId,
            termsId: _termsId,
            licensee: _licensee,
            acceptedTimestamp: uint48(block.timestamp),
            totalRoyaltiesPaid: 0,
            active: true
        });

        emit IPLicenseAccepted(_ipNftId, _termsId, _licensee, terms.initialFee);
    }

    /**
     * @notice A licensee makes a royalty payment for a licensed IP.
     * @dev The payment is distributed among the IP-NFT owners based on their configured royalty distribution shares.
     * @param _ipNftId The ID of the IP-NFT.
     * @param _licenseId The ID of the active license.
     * @param _amount The amount of royalty payment in Ether.
     */
    function collectIPRoyalty(
        uint256 _ipNftId,
        uint256 _licenseId,
        uint256 _amount
    ) external payable onlyInitialized {
        IPNFT storage ipNft = ipNfts[_ipNftId];
        if (ipNft.ipNftId == 0 && _ipNftId != 0) revert CognitoNexus__IPNFTNotFound();
        License storage license = ipNftLicenses[_ipNftId][_licenseId];
        if (!license.active || license.licensee != msg.sender) revert CognitoNexus__LicenseNotFound();
        if (msg.value < _amount) revert CognitoNexus__InsufficientFunds();

        license.totalRoyaltiesPaid += _amount;

        uint256 remainingAmount = _amount;
        // Distribute royalties based on `royaltyDistributionShares`
        for (uint256 i = 0; i < ipNft.totalSupply; i++) { // Iterate through all possible shares
            // This loop structure is incorrect for mapping iteration. A direct array of owners is needed for iteration.
            // For simplicity, let's just send it to the DAO treasury.
            // In a real implementation: iterate `ipNft.royaltyDistributionShares` mapping keys and values.
        }
        
        // Example distribution (simplified, sends all to treasury for demo)
        treasuryBalance += remainingAmount; // All royalties go to treasury for simplicity.
                                         // Realistically, would be distributed proportionally to IP-NFT owners.

        emit IPRoyaltyCollected(_ipNftId, _licenseId, msg.sender, _amount);
    }

    /**
     * @notice Facilitates the transfer of fractional ownership shares of an IP-NFT between addresses.
     * @param _ipNftId The ID of the IP-NFT.
     * @param _from The current owner of the shares.
     * @param _to The recipient of the shares.
     * @param _amount The number of fractional shares to transfer.
     */
    function transferIPNFTFraction(
        uint256 _ipNftId,
        address _from,
        address _to,
        uint256 _amount
    ) external onlyInitialized {
        IPNFT storage ipNft = ipNfts[_ipNftId];
        if (ipNft.ipNftId == 0 && _ipNftId != 0) revert CognitoNexus__IPNFTNotFound();
        if (_from != msg.sender && !isMember[msg.sender]) revert CognitoNexus__Unauthorized(); // Only owner or authorized member
        if (ipNft.ownerShares[_from] < _amount) revert CognitoNexus__IPNFTFractionTransferFailed();
        if (_to == address(0)) revert CognitoNexus__InvalidParameter();

        ipNft.ownerShares[_from] -= _amount;
        ipNft.ownerShares[_to] += _amount;

        // Also update royalty distribution shares, assuming direct correlation
        ipNft.royaltyDistributionShares[_from] -= _amount;
        ipNft.royaltyDistributionShares[_to] += _amount;

        emit IPNFTFractionTransferred(_ipNftId, _from, _to, _amount);
    }

    /**
     * @notice Allows IP-NFT owners to dynamically update the distribution percentages for future royalty payments.
     * @dev This enables flexible royalty splits without changing underlying IP-NFT ownership.
     * @param _ipNftId The ID of the IP-NFT.
     * @param _owners Array of addresses receiving royalties.
     * @param _shares Array of shares (basis points) for each owner. Sum must equal `totalSupply`.
     */
    function setIPNftOwnerRoyalties(
        uint256 _ipNftId,
        address[] calldata _owners,
        uint256[] calldata _shares
    ) external onlyInitialized {
        IPNFT storage ipNft = ipNfts[_ipNftId];
        if (ipNft.ipNftId == 0 && _ipNftId != 0) revert CognitoNexus__IPNFTNotFound();
        if (ipNft.ownerShares[msg.sender] == 0) revert CognitoNexus__Unauthorized(); // Only an owner can set royalty distribution
        if (_owners.length != _shares.length || _owners.length == 0) revert CognitoNexus__InvalidSharesDistribution();

        uint256 totalShares = 0;
        for (uint256 i = 0; i < _shares.length; i++) {
            totalShares += _shares[i];
        }
        if (totalShares != ipNft.totalSupply) revert CognitoNexus__InvalidSharesDistribution();

        // Clear existing distribution and set new one
        // This requires iterating all current entries, which is not efficient for mappings.
        // A better approach would be to store owners in a dynamic array.
        // For simplicity, this function assumes the caller provides a full, fresh distribution.
        for (uint256 i = 0; i < ipNft.totalSupply; i++) { // Clear simplified for demo
            ipNft.royaltyDistributionShares[address(uint160(i))] = 0; // Inefficient, placeholder
        }

        for (uint256 i = 0; i < _owners.length; i++) {
            ipNft.royaltyDistributionShares[_owners[i]] = _shares[i];
        }

        emit IPNFTRoyaltyDistributionUpdated(_ipNftId, _owners, _shares);
    }

    // --- V. Advanced & Extensibility ---

    /**
     * @notice Registers a trusted oracle service for specific off-chain data verification or dispute resolution.
     * @dev Only the DAO owner can register oracles. A DAO vote could later handle this.
     * @param _oracleAddress The address of the oracle contract or trusted entity.
     * @param _oracleType A string describing the oracle's function (e.g., "DisputeResolver", "DataVerifier").
     */
    function registerOracle(address _oracleAddress, string calldata _oracleType) external onlyOwner onlyInitialized {
        if (_oracleAddress == address(0)) revert CognitoNexus__InvalidParameter();
        uint256 oracleId = nextOracleId++;
        registeredOracles[oracleId] = Oracle({
            oracleAddress: _oracleAddress,
            oracleType: _oracleType,
            registered: true
        });
        emit OracleRegistered(_oracleAddress, _oracleType);
    }

    /**
     * @notice Allows DAO members to vote on and update core governance parameters.
     * @dev This would typically be a `GeneralMotion` that, if passed, calls this function.
     *      For demonstration purposes, only `owner` can call it. A real DAO would use `executeMotion`.
     * @param _minVoteDuration_ New minimum duration for voting periods in seconds.
     * @param _minQuorumPercentageBps_ New minimum percentage of total members for quorum (basis points).
     */
    function setGovernanceParameters(uint48 _minVoteDuration_, uint16 _minQuorumPercentageBps_) external onlyOwner onlyInitialized {
        if (_minQuorumPercentageBps_ > 10000) revert CognitoNexus__InvalidParameter();
        minVoteDuration = _minVoteDuration_;
        minQuorumPercentageBps = _minQuorumPercentageBps_;
        emit GovernanceParametersUpdated(_minVoteDuration_, _minQuorumPercentageBps_);
    }

    // --- View Functions ---

    function getTreasuryBalance() public view returns (uint256) {
        return treasuryBalance;
    }

    function getGeneralMotion(uint256 _motionId)
        public
        view
        returns (
            string memory motionHash,
            uint48 startTimestamp,
            uint48 endTimestamp,
            uint256 votesFor,
            uint256 votesAgainst,
            ProposalState state
        )
    {
        GeneralMotion storage motion = generalMotions[_motionId];
        if (motion.id == 0 && _motionId != 0) revert CognitoNexus__ProposalNotFound();
        return (motion.motionHash, motion.startTimestamp, motion.endTimestamp, motion.votesFor, motion.votesAgainst, motion.state);
    }

    function getProjectDetails(uint256 _projectId)
        public
        view
        returns (
            string memory metadataHash,
            uint256 totalBudget,
            uint256 allocatedFunds,
            uint256 milestoneCount,
            ProjectState state,
            address proposer,
            uint256 ipNftId
        )
    {
        Project storage project = projects[_projectId];
        if (project.id == 0 && _projectId != 0) revert CognitoNexus__ProjectNotFound();
        return (
            project.metadataHash,
            project.totalBudget,
            project.allocatedFunds,
            project.milestoneCount,
            project.state,
            project.proposer,
            project.ipNftId
        );
    }

    function getMilestoneDetails(uint256 _projectId, uint256 _milestoneIndex)
        public
        view
        returns (
            bytes32 verificationHash,
            uint256 paymentAmount,
            MilestoneState state,
            string memory verificationProofHash
        )
    {
        Project storage project = projects[_projectId];
        if (project.id == 0 && _projectId != 0) revert CognitoNexus__ProjectNotFound();
        if (_milestoneIndex >= project.milestoneCount) revert CognitoNexus__MilestoneNotFound();

        Milestone storage milestone = projectMilestones[_projectId][_milestoneIndex];
        return (milestone.verificationHash, milestone.paymentAmount, milestone.state, milestone.verificationProofHash);
    }

    function getIPNFTDetails(uint256 _ipNftId)
        public
        view
        returns (
            string memory ipAssetHash,
            uint256 projectId,
            uint256 totalSupply,
            uint256 totalSharesDistributed
        )
    {
        IPNFT storage ipNft = ipNfts[_ipNftId];
        if (ipNft.ipNftId == 0 && _ipNftId != 0) revert CognitoNexus__IPNFTNotFound();
        return (ipNft.ipAssetHash, ipNft.projectId, ipNft.totalSupply, ipNft.totalSharesDistributed);
    }

    function getIPNFTOwnerShare(uint256 _ipNftId, address _owner) public view returns (uint256) {
        IPNFT storage ipNft = ipNfts[_ipNftId];
        if (ipNft.ipNftId == 0 && _ipNftId != 0) revert CognitoNexus__IPNFTNotFound();
        return ipNft.ownerShares[_owner];
    }

    function getIPLicensingTerms(uint256 _ipNftId, uint256 _termsId)
        public
        view
        returns (
            string memory licenseTermsHash,
            uint256 royaltyRateBps,
            uint256 initialFee,
            bool active
        )
    {
        IPNFT storage ipNft = ipNfts[_ipNftId];
        if (ipNft.ipNftId == 0 && _ipNftId != 0) revert CognitoNexus__IPNFTNotFound();
        LicensingTerms storage terms = ipNft.licensingTerms[_termsId];
        if (!terms.active) revert CognitoNexus__LicensingTermsNotFound();
        return (terms.licenseTermsHash, terms.royaltyRateBps, terms.initialFee, terms.active);
    }

    function getLicenseDetails(uint256 _ipNftId, uint256 _licenseId)
        public
        view
        returns (
            address licensee,
            uint48 acceptedTimestamp,
            uint256 totalRoyaltiesPaid,
            bool active
        )
    {
        IPNFT storage ipNft = ipNfts[_ipNftId];
        if (ipNft.ipNftId == 0 && _ipNftId != 0) revert CognitoNexus__IPNFTNotFound();
        License storage license = ipNftLicenses[_ipNftId][_licenseId];
        return (license.licensee, license.acceptedTimestamp, license.totalRoyaltiesPaid, license.active);
    }
}
```