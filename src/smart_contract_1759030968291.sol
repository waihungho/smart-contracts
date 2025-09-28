```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for simplicity of admin role, but custom roles could replace it.
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Custom error types for better user experience and gas efficiency
error SynergiaNet__NotEnoughFunds(uint256 required, uint256 provided);
error SynergiaNet__InvalidProjectState(uint256 projectId, string expectedState, string currentState);
error SynergiaNet__Unauthorized();
error SynergiaNet__VotingNotActive(uint256 id);
error SynergiaNet__AlreadyVoted(uint256 id);
error SynergiaNet__VotingPeriodEnded(uint256 id);
error SynergiaNet__ProjectNotFunded(uint256 projectId);
error SynergiaNet__DeliverableNotApproved(uint256 projectId, uint256 milestoneId);
error SynergiaNet__ZeroAddress();
error SynergiaNet__ProjectNotFound(uint256 projectId);
error SynergiaNet__MilestoneNotFound(uint256 projectId, uint256 milestoneId);
error SynergiaNet__ProjectLeadAlreadyAssigned(uint256 projectId);
error SynergiaNet__NotProjectLead(uint256 projectId);
error SynergiaNet__ProjectLeadElectionNotActive(uint256 projectId);
error SynergiaNet__LeadStakeTooLow(uint256 required, uint256 provided);
error SynergiaNet__DisputeAlreadyActive(uint256 projectId, uint256 milestoneId);
error SynergiaNet__DisputeNotFound(bytes32 disputeId);
error SynergiaNet__ProposalNotExecutable(uint256 proposalId);
error SynergiaNet__InsufficientSynergiaScore(uint256 required, uint256 provided);
error SynergiaNet__ProjectHasNoDpNFT(uint256 projectId);
error SynergiaNet__CannotFractionalizeMultipleTimes(uint256 projectId);

/**
 * @title SynergiaNet
 * @dev SynergiaNet is a decentralized autonomous organization (DAO) designed to facilitate collaborative creative projects.
 *      It enables users to propose, fund, execute, and collectively own the intellectual property (IP) generated from these projects.
 *      The platform features an adaptive governance model, dynamic project NFTs (dpNFTs) representing fractionalized IP,
 *      an on-chain reputation system (Synergia Score), and automated royalty distribution.
 *
 * Key Concepts:
 * - Adaptive Governance: Voting power combines staked tokens and a non-transferable "Synergia Score."
 * - Dynamic Project NFTs (dpNFTs): NFTs that evolve with project progress, representing collective IP.
 * - Fractionalized IP: dpNFTs can be fractionalized into ERC-20 tokens for broad ownership.
 * - Synergia Score (Reputation): A non-transferable score reflecting contribution quality and reliability.
 * - Milestone-Based Payments: Automated fund release based on project milestones and deliverable reviews.
 * - Oraclized Dispute Resolution: External oracle integration for dispute arbitration.
 * - Automated Royalty Distribution: On-chain distribution of revenues from IP.
 */
contract SynergiaNet is Ownable, ReentrancyGuard {

    /* ================================== */
    /* ======== Contract Interfaces ====== */
    /* ================================== */

    // Interface for an external Oracle service (e.g., Kleros-like) for dispute resolution.
    // In a real implementation, this would contain more specific functions for dispute creation, evidence submission, etc.
    interface IOracle {
        function createDispute(address _arbitrator, bytes memory _extraData, bytes memory _metaEvidence) external returns (bytes32 disputeId);
        function submitRuling(bytes32 _disputeId, uint256 _ruling) external; // Mock: 0 = Refused, 1 = Accept, 2 = Reject
        event DisputeCreated(bytes32 indexed disputeId, address indexed creator, bytes32 metaEvidenceHash);
        event RulingGiven(bytes32 indexed disputeId, uint256 ruling);
    }

    // Interface for a Dynamic Project NFT (dpNFT) contract.
    // This NFT evolves its metadata and potentially its underlying rights as the project progresses.
    // Assumes an ERC-721-like base with custom functions for dynamic metadata.
    interface IDpNFT {
        function mint(address to, uint256 projectId, string memory tokenURI) external returns (uint256);
        function updateTokenURI(uint256 tokenId, string memory newTokenURI) external;
        function transferOwnership(address newOwner) external; // For fractionalization scenario
        function getProjectID(uint256 tokenId) external view returns (uint256);
        function getCreator(uint256 tokenId) external view returns (address);
        event DpNFTMinted(uint256 indexed tokenId, uint256 indexed projectId, address indexed owner, string tokenURI);
        event DpNFTMetadataUpdated(uint256 indexed tokenId, string newTokenURI);
    }

    // Interface for a custom Fractionalizer contract.
    // This contract takes an ERC-721 and fractionalizes it into ERC-20 shares.
    interface IFractionalizer {
        function fractionalize(address nftContract, uint256 tokenId, string memory name, string memory symbol, uint256 totalShares) external returns (address fractionalToken);
    }

    /* ================================== */
    /* =========== Enums & Structs ====== */
    /* ================================== */

    enum ProjectState {
        Proposed,               // Project idea submitted
        AwaitingApproval,       // Waiting for guild members to vote on approval
        Approved,               // Project approved by guild
        Funding,                // Actively collecting funds
        LeadElection,           // Electing a Project Lead
        InProgress,             // Project is active, milestones being worked on
        AwaitingFinalization,   // All milestones complete, waiting for final review/dpNFT mint
        Finalized,              // Project complete, dpNFT minted, initial IP shares distributed
        Disputed,               // A milestone or project is under dispute resolution
        Rejected                // Project was rejected by guild or cancelled
    }

    enum ProposalState {
        Pending,
        Active,
        Passed,
        Failed,
        Executed
    }

    struct Project {
        uint256 projectId;
        address payable projectProposer;    // The original proposer of the project
        string projectURI;                  // IPFS hash for detailed project description
        uint256 fundingGoal;
        uint256 currentFunding;             // Current funds collected for the project
        ProjectState state;
        uint256 approvalVotingDeadline;
        uint256 approvalVotesFor;
        uint256 approvalVotesAgainst;
        uint256 dpNFTId;                    // ID of the minted dpNFT for this project
        address fractionalIpTokenAddress;   // Address of the ERC-20 token if IP is fractionalized
        address currentProjectLead;
        uint256 leadElectionDeadline;
        mapping(address => bool) contributors; // Accepted contributors
        uint256 nextMilestoneId;
        mapping(uint256 => Milestone) milestones;
        mapping(uint256 => bytes32) activeDisputes; // milestoneId => oracle_disputeId
        mapping(address => bool) projectApprovalVoters; // Records voters for project approval
        mapping(address => uint256) leadStakes; // Project Lead candidate stakes
        address[] leadCandidates;
    }

    struct Milestone {
        uint256 milestoneId;
        string description;
        uint256 paymentAmount;
        address contributor; // Assigned contributor
        bool submitted;
        bool reviewed;
        bool approved; // Approved by Project Lead
        bool paid;
        bytes32 deliverableHash; // IPFS hash of deliverable
        address reviewer; // Address who performed the review
    }

    struct GuildProposal {
        uint256 proposalId;
        address proposer;
        string description;
        address targetContract; // Address of contract to call (for upgrades/config)
        bytes callData;         // Encoded function call for execution
        uint256 votingDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalState state;
        mapping(address => bool) hasVoted; // Records voters for this specific guild proposal
        mapping(address => uint256) voterSynergiaScoreAtVote; // Snapshot of Synergia Score
        mapping(address => uint256) voterStakedTokensAtVote; // Snapshot of staked tokens
    }

    /* ================================== */
    /* =========== State Variables ====== */
    /* ================================== */

    // Core tokens for funding and staking
    IERC20 public immutable fundingToken;
    IERC20 public immutable stakingToken;

    // External contract addresses
    IOracle public immutable oracle;
    IDpNFT public immutable dpNFTContract;
    IFractionalizer public immutable fractionalizer;

    // System-wide configurations
    uint256 public constant MIN_PROJECT_FUNDING_GOAL = 1000 * 10 ** 18; // Example: 1000 tokens
    uint256 public constant PROJECT_APPROVAL_VOTING_PERIOD = 3 days;
    uint256 public constant GUILD_PROPOSAL_VOTING_PERIOD = 7 days;
    uint256 public constant PROJECT_LEAD_ELECTION_PERIOD = 2 days;
    uint256 public constant MIN_SYNERGIA_SCORE_FOR_PROPOSAL = 100; // Min score to propose guild changes or lead projects
    uint256 public constant MIN_STAKE_FOR_PROJECT_LEAD = 500 * 10 ** 18; // Example: 500 staking tokens
    uint256 public constant GUILD_QUORUM_PERCENTAGE = 20; // 20% of total voting power for a guild proposal to pass

    // Synergia Score (Reputation System)
    // Non-transferable, increases with positive contributions, decreases with negative actions.
    mapping(address => uint256) public synergiaScore;
    mapping(address => uint256) public stakedTokens; // Staked tokens by users for voting or lead roles

    // Project management
    uint256 public nextProjectId;
    mapping(uint252 projectId => Project) public projects;

    // Guild Proposals
    uint256 public nextProposalId;
    mapping(uint256 proposalId => GuildProposal) public guildProposals;

    // Total voting power for quorum calculations
    uint256 public totalSynergiaScore; // Sum of all synergia scores
    uint256 public totalStakedTokens;  // Sum of all staked tokens

    /* ================================== */
    /* ============= Events ============= */
    /* ================================== */

    event ProjectProposed(uint256 indexed projectId, address indexed proposer, string projectURI, uint256 fundingGoal);
    event ProjectApproved(uint256 indexed projectId);
    event ProjectRejected(uint256 indexed projectId, string reason);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount, uint256 currentFunding);
    event ProjectLeadElected(uint256 indexed projectId, address indexed projectLead);
    event ContributorAccepted(uint256 indexed projectId, address indexed contributor);
    event DeliverableSubmitted(uint256 indexed projectId, uint256 indexed milestoneId, address indexed contributor, bytes32 deliverableHash);
    event DeliverableReviewed(uint256 indexed projectId, uint256 indexed milestoneId, address indexed reviewer, bool approved);
    event MilestonePaymentReleased(uint256 indexed projectId, uint256 indexed milestoneId, address indexed contributor, uint256 amount);
    event ProjectFinalized(uint256 indexed projectId, uint256 dpNFTId);
    event ProjectdpNFTMetadataUpdated(uint256 indexed projectId, uint256 dpNFTId, string newURI);
    event ProjectIpFractionalized(uint256 indexed projectId, address indexed fractionalTokenAddress);
    event RoyaltiesDistributed(uint256 indexed projectId, uint256 amount);
    event SynergiaScoreUpdated(address indexed user, uint256 newScore);
    event GuildProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event GuildProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event GuildProposalExecuted(uint256 indexed proposalId);
    event DisputeInitiated(uint256 indexed projectId, uint256 indexed milestoneId, bytes32 indexed oracleDisputeId);
    event DisputeResolved(uint256 indexed projectId, uint256 indexed milestoneId, bytes32 indexed oracleDisputeId, uint256 ruling); // ruling: 0=Refused, 1=Accept, 2=Reject

    /* ================================== */
    /* ============ Modifiers =========== */
    /* ================================== */

    modifier onlyProjectLead(uint256 _projectId) {
        if (projects[_projectId].currentProjectLead != _msgSender()) {
            revert SynergiaNet__NotProjectLead(_projectId);
        }
        _;
    }

    modifier onlyContributor(uint256 _projectId, uint256 _milestoneId) {
        if (projects[_projectId].milestones[_milestoneId].contributor != _msgSender()) {
            revert SynergiaNet__Unauthorized();
        }
        _;
    }

    modifier onlyProjectProposer(uint256 _projectId) {
        if (projects[_projectId].projectProposer != _msgSender()) {
            revert SynergiaNet__Unauthorized();
        }
        _;
    }

    modifier hasMinSynergiaScore(uint256 _minScore) {
        if (synergiaScore[_msgSender()] < _minScore) {
            revert SynergiaNet__InsufficientSynergiaScore(_minScore, synergiaScore[_msgSender()]);
        }
        _;
    }

    /* ================================== */
    /* =========== Constructor ========== */
    /* ================================== */

    constructor(
        address _fundingToken,
        address _stakingToken,
        address _oracle,
        address _dpNFTContract,
        address _fractionalizer
    ) Ownable(_msgSender()) {
        if (_fundingToken == address(0) || _stakingToken == address(0) || _oracle == address(0) || _dpNFTContract == address(0) || _fractionalizer == address(0)) {
            revert SynergiaNet__ZeroAddress();
        }
        fundingToken = IERC20(_fundingToken);
        stakingToken = IERC20(_stakingToken);
        oracle = IOracle(_oracle);
        dpNFTContract = IDpNFT(_dpNFTContract);
        fractionalizer = IFractionalizer(_fractionalizer);
        nextProjectId = 1;
        nextProposalId = 1;
    }

    /* ================================== */
    /* === I. Core Governance & System Management == */
    /* ================================== */

    /**
     * @dev Updates system-wide configuration parameters.
     * @param _minProjectFundingGoal New minimum funding goal for projects.
     * @param _projectApprovalVotingPeriod New duration for project approval voting.
     * @param _guildProposalVotingPeriod New duration for guild proposal voting.
     * @param _projectLeadElectionPeriod New duration for project lead election.
     * @param _minSynergiaScoreForProposal New minimum Synergia Score to propose guild changes.
     * @param _minStakeForProjectLead New minimum stake for project lead role.
     * @param _guildQuorumPercentage New quorum percentage for guild proposals.
     */
    function updateCoreConfig(
        uint256 _minProjectFundingGoal,
        uint256 _projectApprovalVotingPeriod,
        uint256 _guildProposalVotingPeriod,
        uint256 _projectLeadElectionPeriod,
        uint256 _minSynergiaScoreForProposal,
        uint256 _minStakeForProjectLead,
        uint256 _guildQuorumPercentage
    ) external onlyOwner {
        // Validation for new values can be added here
        // MIN_PROJECT_FUNDING_GOAL = _minProjectFundingGoal; // Example, for actual update need mutable storage
        // PROJECT_APPROVAL_VOTING_PERIOD = _projectApprovalVotingPeriod;
        // GUILD_PROPOSAL_VOTING_PERIOD = _guildProposalVotingPeriod;
        // PROJECT_LEAD_ELECTION_PERIOD = _projectLeadElectionPeriod;
        // MIN_SYNERGIA_SCORE_FOR_PROPOSAL = _minSynergiaScoreForProposal;
        // MIN_STAKE_FOR_PROJECT_LEAD = _minStakeForProjectLead;
        // GUILD_QUORUM_PERCENTAGE = _guildQuorumPercentage;
        revert("Configuration update for simplicity, not actual mutable vars. This would be handled via governance proposals.");
    }

    /**
     * @dev Emergency pause for critical operations. Only owner can call.
     */
    function pauseSystem() external onlyOwner {
        // Implement OpenZeppelin Pausable or custom logic here
        revert("Pause functionality not implemented for brevity. Would use Pausable contract.");
    }

    /**
     * @dev Unpause the system. Only owner can call.
     */
    function unpauseSystem() external onlyOwner {
        // Implement OpenZeppelin Pausable or custom logic here
        revert("Unpause functionality not implemented for brevity. Would use Pausable contract.");
    }

    /**
     * @dev Submits a proposal for system-level changes (e.g., new contract logic, configuration updates).
     *      Requires minimum Synergia Score.
     * @param _description Description of the proposal.
     * @param _targetContract Address of the contract to call if the proposal passes.
     * @param _callData Encoded function call for the target contract.
     */
    function proposeGuildUpgrade(
        string memory _description,
        address _targetContract,
        bytes memory _callData
    ) external nonReentrant hasMinSynergiaScore(MIN_SYNERGIA_SCORE_FOR_PROPOSAL) {
        uint256 proposalId = nextProposalId++;
        GuildProposal storage proposal = guildProposals[proposalId];
        proposal.proposalId = proposalId;
        proposal.proposer = _msgSender();
        proposal.description = _description;
        proposal.targetContract = _targetContract;
        proposal.callData = _callData;
        proposal.votingDeadline = block.timestamp + GUILD_PROPOSAL_VOTING_PERIOD;
        proposal.state = ProposalState.Active;

        emit GuildProposalCreated(proposalId, _msgSender(), _description);
    }

    /**
     * @dev Casts a vote on an active guild upgrade proposal.
     *      Voting power is a sum of Synergia Score and staked tokens.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for "For", False for "Against".
     */
    function voteOnGuildProposal(uint256 _proposalId, bool _support) external nonReentrant {
        GuildProposal storage proposal = guildProposals[_proposalId];
        if (proposal.state != ProposalState.Active) {
            revert SynergiaNet__VotingNotActive(_proposalId);
        }
        if (proposal.votingDeadline < block.timestamp) {
            revert SynergiaNet__VotingPeriodEnded(_proposalId);
        }
        if (proposal.hasVoted[_msgSender()]) {
            revert SynergiaNet__AlreadyVoted(_proposalId);
        }

        uint256 voterSynergiaScore = synergiaScore[_msgSender()];
        uint256 voterStakedAmount = stakedTokens[_msgSender()];
        uint256 votingPower = voterSynergiaScore + (voterStakedAmount / 1 ether); // Convert staked tokens to a comparable scale

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[_msgSender()] = true;
        proposal.voterSynergiaScoreAtVote[_msgSender()] = voterSynergiaScore;
        proposal.voterStakedTokensAtVote[_msgSender()] = voterStakedAmount; // StakedTokens are not directly "voting power" but contribute to it.

        emit GuildProposalVoted(_proposalId, _msgSender(), _support, votingPower);
    }

    /**
     * @dev Executes a passed guild upgrade proposal.
     *      Requires the proposal to have passed the voting period and met quorum.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeGuildProposal(uint256 _proposalId) external nonReentrant {
        GuildProposal storage proposal = guildProposals[_proposalId];
        if (proposal.state != ProposalState.Active || proposal.votingDeadline > block.timestamp) {
            revert SynergiaNet__ProposalNotExecutable(_proposalId);
        }

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 requiredQuorum = (totalSynergiaScore + (totalStakedTokens / 1 ether)) * GUILD_QUORUM_PERCENTAGE / 100; // Total voting power snapshot

        if (totalVotes < requiredQuorum || proposal.votesFor <= proposal.votesAgainst) {
            proposal.state = ProposalState.Failed;
            revert SynergiaNet__ProposalNotExecutable(_proposalId); // Or a specific error like ProposalFailedQuorum
        }

        (bool success, ) = proposal.targetContract.call(proposal.callData);
        if (!success) {
            // Revert with error message if available, or just revert
            assembly {
                let returndata_size := returndatasize()
                returndatacopy(0, 0, returndata_size)
                revert(0, returndata_size)
            }
        }

        proposal.state = ProposalState.Executed;
        emit GuildProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows a user to delegate their Synergia Score for voting purposes to another address.
     *      This does not transfer the score, but assigns its voting weight to the delegate.
     *      Staked tokens are always counted from the staker's address.
     * @param _delegate The address to delegate Synergia Score to.
     */
    function delegateReputation(address _delegate) external {
        if (_delegate == address(0)) {
            revert SynergiaNet__ZeroAddress();
        }
        // This is a simplified delegation. A more robust system would involve a `delegates` mapping
        // and update the effective voting power for the delegate.
        // For brevity, we'll assume SynergiaScore is directly used by the address that holds it.
        // A real delegation system would require re-calculating `getVotingPower` for the delegate.
        revert("Reputation delegation not fully implemented for brevity. This would involve complex mapping and `getVotingPower` adjustments.");
    }

    /* ================================== */
    /* === II. Project Lifecycle & Funding == */
    /* ================================== */

    /**
     * @dev Initiates a new creative project with a detailed proposal and funding goal.
     *      Requires the proposer to have a minimum Synergia Score.
     * @param _projectURI IPFS hash or URL pointing to the detailed project description.
     * @param _fundingGoal The amount of fundingToken required for the project.
     * @param _milestones Array of milestone descriptions, payment amounts, and assigned contributors.
     */
    function proposeCreativeProject(
        string memory _projectURI,
        uint256 _fundingGoal,
        Milestone[] memory _milestones
    ) external nonReentrant hasMinSynergiaScore(MIN_SYNERGIA_SCORE_FOR_PROPOSAL) {
        if (_fundingGoal < MIN_PROJECT_FUNDING_GOAL) {
            revert SynergiaNet__NotEnoughFunds(MIN_PROJECT_FUNDING_GOAL, _fundingGoal);
        }
        if (bytes(_projectURI).length == 0) {
            revert SynergiaNet__InvalidProjectState(0, "Project URI cannot be empty", "Empty");
        }

        uint256 projectId = nextProjectId++;
        Project storage project = projects[projectId];
        project.projectId = projectId;
        project.projectProposer = payable(_msgSender());
        project.projectURI = _projectURI;
        project.fundingGoal = _fundingGoal;
        project.state = ProjectState.AwaitingApproval;
        project.approvalVotingDeadline = block.timestamp + PROJECT_APPROVAL_VOTING_PERIOD;
        project.nextMilestoneId = 1;

        for (uint256 i = 0; i < _milestones.length; i++) {
            Milestone storage m = project.milestones[project.nextMilestoneId];
            m.milestoneId = project.nextMilestoneId;
            m.description = _milestones[i].description;
            m.paymentAmount = _milestones[i].paymentAmount;
            m.contributor = _milestones[i].contributor; // Initial assignment, can be changed by lead
            project.nextMilestoneId++;
        }

        emit ProjectProposed(projectId, _msgSender(), _projectURI, _fundingGoal);
    }

    /**
     * @dev Guild members vote to approve or reject a proposed project.
     *      Voting power derived from Synergia Score and staked tokens.
     * @param _projectId The ID of the project to vote on.
     * @param _support True for "Approve", False for "Reject".
     */
    function voteOnProjectApproval(uint256 _projectId, bool _support) external nonReentrant {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) {
            revert SynergiaNet__ProjectNotFound(_projectId);
        }
        if (project.state != ProjectState.AwaitingApproval) {
            revert SynergiaNet__InvalidProjectState(_projectId, "AwaitingApproval", _toString(project.state));
        }
        if (project.approvalVotingDeadline < block.timestamp) {
            revert SynergiaNet__VotingPeriodEnded(_projectId);
        }
        if (project.projectApprovalVoters[_msgSender()]) {
            revert SynergiaNet__AlreadyVoted(_projectId);
        }

        // Simplified voting power for project approval (could be more complex like guild proposals)
        uint256 voterSynergiaScore = synergiaScore[_msgSender()];
        uint256 voterStakedAmount = stakedTokens[_msgSender()];
        uint256 votingPower = voterSynergiaScore + (voterStakedAmount / 1 ether); // Use a weighted sum

        if (_support) {
            project.approvalVotesFor += votingPower;
        } else {
            project.approvalVotesAgainst += votingPower;
        }
        project.projectApprovalVoters[_msgSender()] = true;

        // Auto-resolve if voting deadline passed (can also be triggered by a separate function)
        if (block.timestamp >= project.approvalVotingDeadline) {
            _resolveProjectApproval(_projectId);
        }
    }

    /**
     * @dev Internal function to resolve project approval based on votes.
     * @param _projectId The ID of the project.
     */
    function _resolveProjectApproval(uint256 _projectId) internal {
        Project storage project = projects[_projectId];
        if (project.state != ProjectState.AwaitingApproval || project.approvalVotingDeadline > block.timestamp) {
            revert SynergiaNet__InvalidProjectState(_projectId, "AwaitingApproval and Voting Period Ended", _toString(project.state));
        }

        if (project.approvalVotesFor > project.approvalVotesAgainst) {
            project.state = ProjectState.Funding;
            // Transfer funds from guild treasury if needed or start crowdfunding
            // For now, it just means it's ready for external funding
            emit ProjectApproved(_projectId);
        } else {
            project.state = ProjectState.Rejected;
            emit ProjectRejected(_projectId, "Failed project approval vote.");
        }
    }

    /**
     * @dev Contributes tokens to a project's funding goal.
     *      Tokens are held by the contract until the project is finalized or rejected.
     * @param _projectId The ID of the project to fund.
     * @param _amount The amount of fundingToken to contribute.
     */
    function fundProject(uint256 _projectId, uint256 _amount) external nonReentrant {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) {
            revert SynergiaNet__ProjectNotFound(_projectId);
        }
        if (project.state != ProjectState.Funding) {
            revert SynergiaNet__InvalidProjectState(_projectId, "Funding", _toString(project.state));
        }
        if (_amount == 0) {
            revert SynergiaNet__NotEnoughFunds(1, 0); // Amount must be > 0
        }

        if (!fundingToken.transferFrom(_msgSender(), address(this), _amount)) {
            revert SynergiaNet__NotEnoughFunds(_amount, fundingToken.balanceOf(_msgSender()));
        }

        project.currentFunding += _amount;
        emit ProjectFunded(_projectId, _msgSender(), _amount, project.currentFunding);

        if (project.currentFunding >= project.fundingGoal) {
            project.state = ProjectState.LeadElection;
            project.leadElectionDeadline = block.timestamp + PROJECT_LEAD_ELECTION_PERIOD;
            // Optionally, the proposer automatically becomes a lead candidate
            // Or only allow those with specific Synergia Score
        }
    }

    /**
     * @dev Users stake tokens to apply for the Project Lead role.
     *      Requires a minimum stake and Synergia Score.
     * @param _projectId The ID of the project to apply for.
     */
    function stakeForProjectLead(uint256 _projectId) external nonReentrant hasMinSynergiaScore(MIN_SYNERGIA_SCORE_FOR_PROPOSAL) {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) {
            revert SynergiaNet__ProjectNotFound(_projectId);
        }
        if (project.state != ProjectState.LeadElection) {
            revert SynergiaNet__ProjectLeadElectionNotActive(_projectId);
        }
        if (project.currentProjectLead != address(0)) {
            revert SynergiaNet__ProjectLeadAlreadyAssigned(_projectId);
        }

        if (!stakingToken.transferFrom(_msgSender(), address(this), MIN_STAKE_FOR_PROJECT_LEAD)) {
            revert SynergiaNet__LeadStakeTooLow(MIN_STAKE_FOR_PROJECT_LEAD, stakingToken.balanceOf(_msgSender()));
        }

        project.leadStakes[_msgSender()] += MIN_STAKE_FOR_PROJECT_LEAD;
        project.leadCandidates.push(_msgSender());

        totalStakedTokens += MIN_STAKE_FOR_PROJECT_LEAD; // Update global staked tokens
        stakedTokens[_msgSender()] += MIN_STAKE_FOR_PROJECT_LEAD; // User's total staked amount
    }

    /**
     * @dev Elects a Project Lead from stakers after the election period ends.
     *      The candidate with the highest Synergia Score among stakers is chosen.
     * @param _projectId The ID of the project.
     */
    function electProjectLead(uint256 _projectId) external nonReentrant {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) {
            revert SynergiaNet__ProjectNotFound(_projectId);
        }
        if (project.state != ProjectState.LeadElection || project.leadElectionDeadline > block.timestamp) {
            revert SynergiaNet__ProjectLeadElectionNotActive(_projectId);
        }
        if (project.currentProjectLead != address(0)) {
            revert SynergiaNet__ProjectLeadAlreadyAssigned(_projectId);
        }

        address electedLead = address(0);
        uint256 highestScore = 0;

        // Elect lead based on highest Synergia Score among candidates.
        // A more complex system could involve voting or random selection.
        for (uint256 i = 0; i < project.leadCandidates.length; i++) {
            address candidate = project.leadCandidates[i];
            if (project.leadStakes[candidate] >= MIN_STAKE_FOR_PROJECT_LEAD) { // Ensure they still have the minimum stake
                uint256 score = synergiaScore[candidate];
                if (score > highestScore) {
                    highestScore = score;
                    electedLead = candidate;
                }
            }
        }

        if (electedLead == address(0)) {
            project.state = ProjectState.Rejected; // No suitable lead found
            emit ProjectRejected(_projectId, "No Project Lead elected.");
            return;
        }

        project.currentProjectLead = electedLead;
        project.state = ProjectState.InProgress;

        // Refund stakes to non-elected candidates
        for (uint256 i = 0; i < project.leadCandidates.length; i++) {
            address candidate = project.leadCandidates[i];
            if (candidate != electedLead) {
                uint256 amount = project.leadStakes[candidate];
                project.leadStakes[candidate] = 0;
                stakedTokens[candidate] -= amount;
                totalStakedTokens -= amount;
                stakingToken.transfer(candidate, amount); // Return staked tokens
            }
        }

        emit ProjectLeadElected(_projectId, electedLead);
        _updateSynergiaScore(electedLead, 50); // Award score for being elected lead
    }

    /**
     * @dev Project Lead accepts a contributor to a specific role/milestone.
     * @param _projectId The ID of the project.
     * @param _contributor The address of the contributor.
     * @param _milestoneId The ID of the milestone they are assigned to.
     */
    function acceptContributorApplication(
        uint256 _projectId,
        address _contributor,
        uint256 _milestoneId
    ) external nonReentrant onlyProjectLead(_projectId) {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) {
            revert SynergiaNet__ProjectNotFound(_projectId);
        }
        if (project.state != ProjectState.InProgress) {
            revert SynergiaNet__InvalidProjectState(_projectId, "InProgress", _toString(project.state));
        }
        if (_contributor == address(0)) {
            revert SynergiaNet__ZeroAddress();
        }
        if (_milestoneId == 0 || _milestoneId >= project.nextMilestoneId) {
            revert SynergiaNet__MilestoneNotFound(_projectId, _milestoneId);
        }

        project.contributors[_contributor] = true;
        project.milestones[_milestoneId].contributor = _contributor; // Assign contributor to specific milestone

        emit ContributorAccepted(_projectId, _contributor);
    }

    /**
     * @dev A contributor submits work for a project milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneId The ID of the milestone.
     * @param _deliverableHash IPFS hash of the submitted work.
     */
    function submitDeliverable(
        uint256 _projectId,
        uint256 _milestoneId,
        bytes32 _deliverableHash
    ) external nonReentrant onlyContributor(_projectId, _milestoneId) {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) {
            revert SynergiaNet__ProjectNotFound(_projectId);
        }
        if (project.state != ProjectState.InProgress) {
            revert SynergiaNet__InvalidProjectState(_projectId, "InProgress", _toString(project.state));
        }
        Milestone storage milestone = project.milestones[_milestoneId];
        if (milestone.milestoneId == 0) {
            revert SynergiaNet__MilestoneNotFound(_projectId, _milestoneId);
        }
        if (milestone.submitted) {
            revert SynergiaNet__InvalidProjectState(_projectId, "Deliverable not yet submitted", "Already submitted");
        }

        milestone.submitted = true;
        milestone.deliverableHash = _deliverableHash;

        emit DeliverableSubmitted(_projectId, _milestoneId, _msgSender(), _deliverableHash);
    }

    /**
     * @dev Project Lead reviews a submitted deliverable.
     * @param _projectId The ID of the project.
     * @param _milestoneId The ID of the milestone.
     * @param _approved True if approved, False if rejected.
     */
    function reviewDeliverable(
        uint256 _projectId,
        uint256 _milestoneId,
        bool _approved
    ) external nonReentrant onlyProjectLead(_projectId) {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) {
            revert SynergiaNet__ProjectNotFound(_projectId);
        }
        if (project.state != ProjectState.InProgress) {
            revert SynergiaNet__InvalidProjectState(_projectId, "InProgress", _toString(project.state));
        }
        Milestone storage milestone = project.milestones[_milestoneId];
        if (milestone.milestoneId == 0) {
            revert SynergiaNet__MilestoneNotFound(_projectId, _milestoneId);
        }
        if (!milestone.submitted) {
            revert SynergiaNet__InvalidProjectState(_projectId, "Deliverable submitted", "Not submitted");
        }
        if (milestone.reviewed) {
            revert SynergiaNet__InvalidProjectState(_projectId, "Deliverable not yet reviewed", "Already reviewed");
        }

        milestone.reviewed = true;
        milestone.approved = _approved;
        milestone.reviewer = _msgSender();

        emit DeliverableReviewed(_projectId, _milestoneId, _msgSender(), _approved);

        if (_approved) {
            _updateSynergiaScore(milestone.contributor, 20); // Award score for successful deliverable
            _updateSynergiaScore(_msgSender(), 5); // Award score for reviewing
        } else {
            _updateSynergiaScore(milestone.contributor, -10); // Deduct score for rejected deliverable
        }
    }

    /**
     * @dev Releases funds to contributors upon successful milestone completion.
     * @param _projectId The ID of the project.
     * @param _milestoneId The ID of the milestone.
     */
    function releaseMilestonePayment(
        uint256 _projectId,
        uint256 _milestoneId
    ) external nonReentrant onlyProjectLead(_projectId) {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) {
            revert SynergiaNet__ProjectNotFound(_projectId);
        }
        if (project.state != ProjectState.InProgress) {
            revert SynergiaNet__InvalidProjectState(_projectId, "InProgress", _toString(project.state));
        }
        Milestone storage milestone = project.milestones[_milestoneId];
        if (milestone.milestoneId == 0) {
            revert SynergiaNet__MilestoneNotFound(_projectId, _milestoneId);
        }
        if (!milestone.approved) {
            revert SynergiaNet__DeliverableNotApproved(_projectId, _milestoneId);
        }
        if (milestone.paid) {
            revert SynergiaNet__InvalidProjectState(_projectId, "Milestone not yet paid", "Already paid");
        }
        if (project.currentFunding < milestone.paymentAmount) {
            revert SynergiaNet__NotEnoughFunds(milestone.paymentAmount, project.currentFunding);
        }

        project.currentFunding -= milestone.paymentAmount;
        milestone.paid = true;

        if (!fundingToken.transfer(milestone.contributor, milestone.paymentAmount)) {
            revert SynergiaNet__NotEnoughFunds(milestone.paymentAmount, fundingToken.balanceOf(address(this)));
        }

        emit MilestonePaymentReleased(_projectId, _milestoneId, milestone.contributor, milestone.paymentAmount);
    }

    /**
     * @dev Raises a dispute over a deliverable or payment, engaging the oracle.
     *      Can be called by contributor (if deliverable rejected/payment withheld) or lead (if deliverable bad).
     * @param _projectId The ID of the project.
     * @param _milestoneId The ID of the milestone under dispute.
     * @param _metaEvidenceHash IPFS hash for evidence related to the dispute.
     */
    function initiateDispute(
        uint256 _projectId,
        uint256 _milestoneId,
        bytes32 _metaEvidenceHash
    ) external nonReentrant {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) {
            revert SynergiaNet__ProjectNotFound(_projectId);
        }
        if (project.state != ProjectState.InProgress && project.state != ProjectState.AwaitingFinalization) {
            revert SynergiaNet__InvalidProjectState(_projectId, "InProgress or AwaitingFinalization", _toString(project.state));
        }
        if (project.activeDisputes[_milestoneId] != bytes32(0)) {
            revert SynergiaNet__DisputeAlreadyActive(_projectId, _milestoneId);
        }
        Milestone storage milestone = project.milestones[_milestoneId];
        if (milestone.milestoneId == 0) {
            revert SynergiaNet__MilestoneNotFound(_projectId, _milestoneId);
        }

        // Placeholder for oracle integration: assumes fixed arbitrator and extraData
        bytes32 oracleDisputeId = oracle.createDispute(address(0), "", abi.encodePacked(_metaEvidenceHash)); // Assume fixed params for mock
        project.activeDisputes[_milestoneId] = oracleDisputeId;
        project.state = ProjectState.Disputed; // Set project state to disputed

        emit DisputeInitiated(_projectId, _milestoneId, oracleDisputeId);
    }

    /**
     * @dev Callback function for the oracle to return dispute resolution.
     *      Only the oracle contract can call this.
     * @param _disputeId The ID of the dispute from the oracle.
     * @param _ruling The ruling from the oracle (e.g., 0=Refused, 1=Accept, 2=Reject).
     */
    function resolveDisputeCallback(bytes32 _disputeId, uint256 _ruling) external nonReentrant {
        // Only the oracle contract can call this function
        if (_msgSender() != address(oracle)) {
            revert SynergiaNet__Unauthorized();
        }

        // Find which project and milestone this dispute belongs to
        uint256 projectId = 0;
        uint256 milestoneId = 0;
        bool found = false;

        // Iterate through active projects to find the dispute (inefficient for many projects, better to map disputeId to projectId/milestoneId)
        for (uint256 i = 1; i < nextProjectId; i++) {
            Project storage project = projects[i];
            for (uint256 j = 1; j < project.nextMilestoneId; j++) {
                if (project.activeDisputes[j] == _disputeId) {
                    projectId = i;
                    milestoneId = j;
                    found = true;
                    break;
                }
            }
            if (found) break;
        }

        if (!found) {
            revert SynergiaNet__DisputeNotFound(_disputeId);
        }

        Project storage project = projects[projectId];
        Milestone storage milestone = project.milestones[milestoneId];

        delete project.activeDisputes[milestoneId]; // Remove from active disputes

        if (_ruling == 1) { // Oracle ruled "Accept" (e.g., contributor's work is good, or lead's rejection was invalid)
            milestone.approved = true;
            milestone.reviewed = true; // Mark as reviewed and approved by oracle
            _updateSynergiaScore(milestone.contributor, 30); // Award for successful dispute resolution
            _updateSynergiaScore(project.currentProjectLead, -15); // Deduct for faulty rejection
        } else if (_ruling == 2) { // Oracle ruled "Reject" (e.g., contributor's work is bad, or lead's rejection was valid)
            milestone.approved = false;
            milestone.reviewed = true; // Mark as reviewed by oracle
            _updateSynergiaScore(milestone.contributor, -20); // Deduct for failed dispute
            _updateSynergiaScore(project.currentProjectLead, 10); // Award for correct rejection
        } else { // Ruling refused or other outcome
            // Handle neutral ruling, potentially refund dispute fees or re-enter dispute state
        }
        
        // Return project to InProgress or AwaitingFinalization if no other disputes
        bool hasOtherDisputes = false;
        for (uint256 i = 1; i < project.nextMilestoneId; i++) {
            if (project.activeDisputes[i] != bytes32(0)) {
                hasOtherDisputes = true;
                break;
            }
        }
        if (!hasOtherDisputes) {
            // Determine if all milestones are complete
            bool allMilestonesComplete = true;
            for (uint256 i = 1; i < project.nextMilestoneId; i++) {
                if (!project.milestones[i].approved || !project.milestones[i].paid) {
                    allMilestonesComplete = false;
                    break;
                }
            }
            project.state = allMilestonesComplete ? ProjectState.AwaitingFinalization : ProjectState.InProgress;
        }

        emit DisputeResolved(projectId, milestoneId, _disputeId, _ruling);
    }

    /**
     * @dev Marks a project as complete, triggers dpNFT minting and initial IP distribution.
     *      Can only be called by the Project Lead after all milestones are completed and paid.
     * @param _projectId The ID of the project.
     * @param _finalProjectURI The final IPFS hash or URL for the completed project's IP.
     */
    function finalizeProject(uint256 _projectId, string memory _finalProjectURI) external nonReentrant onlyProjectLead(_projectId) {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) {
            revert SynergiaNet__ProjectNotFound(_projectId);
        }
        if (project.state != ProjectState.AwaitingFinalization) {
            revert SynergiaNet__InvalidProjectState(_projectId, "AwaitingFinalization", _toString(project.state));
        }

        // Verify all milestones are complete and paid
        for (uint256 i = 1; i < project.nextMilestoneId; i++) {
            if (!project.milestones[i].approved || !project.milestones[i].paid) {
                revert SynergiaNet__InvalidProjectState(_projectId, "All milestones completed and paid", "Milestones pending");
            }
        }

        project.state = ProjectState.Finalized;
        
        // Mint the dpNFT for the project
        project.dpNFTId = dpNFTContract.mint(address(this), _projectId, _finalProjectURI);
        
        // Project Lead gets some Synergia Score for finalization
        _updateSynergiaScore(_msgSender(), 100);

        // Remaining project funds can be distributed to project proposer, lead, or guild treasury
        // For simplicity, let's say it goes to the proposer and lead
        if (project.currentFunding > 0) {
            uint256 remainingFunds = project.currentFunding;
            uint256 proposerShare = remainingFunds / 2; // Example split
            uint256 leadShare = remainingFunds - proposerShare;

            if (!fundingToken.transfer(project.projectProposer, proposerShare)) {
                // Log error or revert
            }
            if (!fundingToken.transfer(project.currentProjectLead, leadShare)) {
                // Log error or revert
            }
            project.currentFunding = 0;
        }

        // Unstake Project Lead's tokens
        uint256 leadStakeAmount = project.leadStakes[project.currentProjectLead];
        if (leadStakeAmount > 0) {
            project.leadStakes[project.currentProjectLead] = 0;
            stakedTokens[project.currentProjectLead] -= leadStakeAmount;
            totalStakedTokens -= leadStakeAmount;
            stakingToken.transfer(project.currentProjectLead, leadStakeAmount);
        }

        emit ProjectFinalized(_projectId, project.dpNFTId);
    }

    /* ================================== */
    /* === III. IP Management & Monetization (Dynamic Project NFTs - dpNFTs) == */
    /* ================================== */

    /**
     * @dev Mints the Dynamic Project NFT (dpNFT) upon project finalization.
     *      This function is called internally by `finalizeProject`.
     *      dpNFT represents the collective IP bundle of the project.
     * @param _projectId The ID of the project.
     * @param _owner The address to mint the dpNFT to (usually this contract initially for fractionalization).
     * @param _tokenURI The initial metadata URI for the dpNFT.
     */
    function mintProjectdpNFT(uint256 _projectId, address _owner, string memory _tokenURI) internal returns (uint256) {
        // This function is called internally by finalizeProject, not directly exposed.
        // It's listed here as a conceptual "function" of the dpNFT system.
        return dpNFTContract.mint(_owner, _projectId, _tokenURI);
    }

    /**
     * @dev Project Lead/Governance updates the dpNFT's metadata (e.g., new version, achievement).
     *      This shows the "dynamic" nature of the dpNFT.
     * @param _projectId The ID of the project.
     * @param _newURI The new IPFS hash or URL for the dpNFT's metadata.
     */
    function updateProjectdpNFTMetadata(uint256 _projectId, string memory _newURI) external nonReentrant onlyProjectLead(_projectId) {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) {
            revert SynergiaNet__ProjectNotFound(_projectId);
        }
        if (project.dpNFTId == 0) {
            revert SynergiaNet__ProjectHasNoDpNFT(_projectId);
        }

        dpNFTContract.updateTokenURI(project.dpNFTId, _newURI);

        emit ProjectdpNFTMetadataUpdated(_projectId, project.dpNFTId, _newURI);
    }

    /**
     * @dev Fractionalizes the dpNFT into ERC-20 tokens for broad ownership.
     *      Only callable once per project.
     * @param _projectId The ID of the project.
     * @param _name The name for the fractionalized ERC-20 token.
     * @param _symbol The symbol for the fractionalized ERC-20 token.
     * @param _totalShares The total number of ERC-20 shares to mint.
     */
    function fractionalizeProjectIP(
        uint256 _projectId,
        string memory _name,
        string memory _symbol,
        uint256 _totalShares
    ) external nonReentrant onlyProjectLead(_projectId) {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) {
            revert SynergiaNet__ProjectNotFound(_projectId);
        }
        if (project.state != ProjectState.Finalized) {
            revert SynergiaNet__InvalidProjectState(_projectId, "Finalized", _toString(project.state));
        }
        if (project.dpNFTId == 0) {
            revert SynergiaNet__ProjectHasNoDpNFT(_projectId);
        }
        if (project.fractionalIpTokenAddress != address(0)) {
            revert SynergiaNet__CannotFractionalizeMultipleTimes(_projectId);
        }

        // Transfer ownership of dpNFT to the Fractionalizer contract
        dpNFTContract.transferOwnership(address(fractionalizer));

        // Call the fractionalizer to create ERC-20 shares
        address fractionalTokenAddress = fractionalizer.fractionalize(address(dpNFTContract), project.dpNFTId, _name, _symbol, _totalShares);
        project.fractionalIpTokenAddress = fractionalTokenAddress;

        emit ProjectIpFractionalized(_projectId, fractionalTokenAddress);
    }

    /**
     * @dev Distributes collected royalties/revenues from the project's IP to
     *      fractional token holders and core contributors (proposer, lead, other key contributors).
     *      Assumes royalty collection happens off-chain or via a separate mechanism
     *      and funds are sent to this contract.
     * @param _projectId The ID of the project.
     * @param _amount The total amount of royalties to distribute.
     */
    function distributeProjectRoyalties(uint256 _projectId, uint256 _amount) external nonReentrant {
        // This function would typically be called by a trusted oracle or a dedicated revenue collector contract.
        // For demonstration, let's assume `_msgSender()` is authorized to trigger this.
        // In a real system, access would be restricted (e.g., onlyOwner, or specific role).

        Project storage project = projects[_projectId];
        if (project.projectId == 0) {
            revert SynergiaNet__ProjectNotFound(_projectId);
        }
        if (project.state != ProjectState.Finalized) {
            revert SynergiaNet__InvalidProjectState(_projectId, "Finalized", _toString(project.state));
        }
        if (_amount == 0) {
            return; // No royalties to distribute
        }
        if (!fundingToken.transferFrom(_msgSender(), address(this), _amount)) { // Assume funds are sent to contract first
            revert SynergiaNet__NotEnoughFunds(_amount, fundingToken.balanceOf(_msgSender()));
        }

        // Example distribution logic:
        // 1. A percentage to the core contributors (proposer, lead)
        // 2. The rest distributed proportionally to fractional IP token holders

        uint256 contributorShare = _amount / 10; // 10% for core contributors
        uint256 ipHolderShare = _amount - contributorShare;

        // Distribute to core contributors
        if (project.projectProposer != address(0)) {
            fundingToken.transfer(project.projectProposer, contributorShare / 2);
        }
        if (project.currentProjectLead != address(0)) {
            fundingToken.transfer(project.currentProjectLead, contributorShare / 2);
        }

        // Distribute to fractional IP token holders (if fractionalized)
        if (project.fractionalIpTokenAddress != address(0)) {
            // This is a simplified distribution. A real system would need to query
            // the fractional ERC-20 token contract for all holders and their balances,
            // which is highly gas-intensive on-chain.
            // Typically, this is done off-chain or using a push/pull pattern with merkel proofs.
            // For now, we'll send it to the fractional token contract, assuming it handles distribution.
            IERC20(project.fractionalIpTokenAddress).transfer(address(this), ipHolderShare); // Mock distribution to the fractional token contract itself for internal logic or to be claimed.
            revert("Royalty distribution to fractional holders not fully implemented on-chain due to gas constraints. Would require off-chain computation or pull mechanism.");
        } else {
            // If not fractionalized, remaining funds might go to original owner or guild treasury
            fundingToken.transfer(project.projectProposer, ipHolderShare); // Example: give to proposer
        }

        emit RoyaltiesDistributed(_projectId, _amount);
    }


    /* ================================== */
    /* === IV. Synergia Score (Reputation System) == */
    /* ================================== */

    /**
     * @dev Retrieves a user's current Synergia Score.
     * @param _user The address of the user.
     * @return The Synergia Score of the user.
     */
    function getSynergiaScore(address _user) external view returns (uint256) {
        return synergiaScore[_user];
    }

    /**
     * @dev Internal function to update Synergia Score based on actions.
     *      Score increases for successful deliverables, good reviews, dispute wins.
     *      Score decreases for rejected deliverables, failed disputes.
     * @param _user The address whose score is to be updated.
     * @param _delta The amount to add or subtract from the score.
     */
    function _updateSynergiaScore(address _user, int256 _delta) internal {
        uint256 currentScore = synergiaScore[_user];
        if (_delta > 0) {
            synergiaScore[_user] = currentScore + uint256(_delta);
            totalSynergiaScore += uint256(_delta);
        } else if (_delta < 0) {
            uint256 absDelta = uint256(-_delta);
            if (currentScore < absDelta) {
                synergiaScore[_user] = 0; // Score cannot go below zero
                totalSynergiaScore -= currentScore;
            } else {
                synergiaScore[_user] = currentScore - absDelta;
                totalSynergiaScore -= absDelta;
            }
        }
        emit SynergiaScoreUpdated(_user, synergiaScore[_user]);
    }

    /**
     * @dev Allows users to claim special achievement NFTs based on high Synergia Score and contributions.
     *      This would interact with a separate "Achievement NFT" contract.
     * @param _user The address claiming the achievement.
     * @param _achievementId The ID of the achievement to claim.
     */
    function claimSynergiaAchievements(address _user, uint256 _achievementId) external {
        // This function demonstrates an advanced concept but requires an external
        // Achievement NFT contract and specific logic to verify eligibility.
        // For instance:
        // require(synergiaScore[_user] >= MIN_SCORE_FOR_ACHIEVEMENT[_achievementId], "Not enough Synergia Score");
        // require(userHasCompletedProjects(_user, REQUIRED_PROJECTS[_achievementId]), "Not enough projects completed");
        // achievementNFTContract.mint(_user, _achievementId, "ipfs://...");
        revert("Achievement claiming not implemented for brevity. Requires external Achievement NFT contract and complex eligibility logic.");
    }
    
    // Function to update the `totalSynergiaScore` and `totalStakedTokens` in case of off-chain reputation decay or un-staking outside of project lead role.
    function _recalculateGlobalVotingPower() internal {
        // This function would be called periodically or by governance to keep global sums accurate.
        // It's computationally expensive to iterate all users on-chain.
        // For simplicity, we directly update totalSynergiaScore/totalStakedTokens during score updates and staking.
    }

    /* ================================== */
    /* ======== Utility Functions ======= */
    /* ================================== */

    /**
     * @dev Converts a ProjectState enum to its string representation.
     */
    function _toString(ProjectState _state) internal pure returns (string memory) {
        if (_state == ProjectState.Proposed) return "Proposed";
        if (_state == ProjectState.AwaitingApproval) return "AwaitingApproval";
        if (_state == ProjectState.Approved) return "Approved";
        if (_state == ProjectState.Funding) return "Funding";
        if (_state == ProjectState.LeadElection) return "LeadElection";
        if (_state == ProjectState.InProgress) return "InProgress";
        if (_state == ProjectState.AwaitingFinalization) return "AwaitingFinalization";
        if (_state == ProjectState.Finalized) return "Finalized";
        if (_state == ProjectState.Disputed) return "Disputed";
        if (_state == ProjectState.Rejected) return "Rejected";
        return "Unknown";
    }

    /**
     * @dev Get effective voting power for an address.
     *      Combines Synergia Score and staked tokens for a comprehensive voting weight.
     * @param _voter The address whose voting power is to be calculated.
     * @return The calculated voting power.
     */
    function getVotingPower(address _voter) public view returns (uint256) {
        uint256 score = synergiaScore[_voter];
        uint256 stakedAmount = stakedTokens[_voter];
        // Example weighting: 1 Synergia Score point = 1 voting unit
        // 1 staked token = 1 voting unit (assuming 18 decimal tokens and converting to whole units)
        return score + (stakedAmount / 10**18); 
    }
}
```