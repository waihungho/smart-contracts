```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline: SyntellectNexus - A Decentralized Cognitive Funding & Reputation Protocol
// This contract aims to create a novel decentralized funding and reputation system.
// It leverages non-transferable Soulbound Reputation (SBR) tokens, an AI-oracle-driven
// Cognitive Index (CI) for projects, adaptive funding gates, and gamified staking
// to foster innovation and ensure accountability.
//
// Core Concepts:
// - Soulbound Reputation (SBR) Tokens: Non-transferable tokens representing individual
//   expertise across various domains. SBRs are crucial for governance weight and
//   specialized voting.
// - Project Cognitive Index (CI): A dynamic, AI-oracle-influenced score for projects.
//   The CI reflects external sentiment, progress, or market fit, and directly affects
//   funding release schedules and Syntellect Stake rewards.
// - Adaptive Funding Gates (AFG): Incremental funding release for projects, dynamically
//   adjusted based on the project's CI and reputation-weighted milestone approvals.
// - Syntellect Stakes (SS): A gamified staking mechanism where users can stake funds
//   on a project's success. Rewards and refunds are tied to the project's CI and
//   overall outcome.
// - Reputation-Weighted Quadratic Governance (RWQG): Decentralized decision-making
//   using a form of quadratic voting, where voting power is amplified by the voter's
//   SBR tokens and their delegations.
// - Dynamic System Parameters (DSP): Key protocol parameters (e.g., funding percentages,
//   dispute fees, vote thresholds) can adapt over time based on overall ecosystem
//   performance and governance decisions, fostering a self-evolving system.

// Function Summary:
// I. Core System Management & Setup
// 1. constructor(address _aiOracleAddress, address _fundingTokenAddress): Initializes contract, sets AI Oracle, and the ERC20 token used for funding/staking.
// 2. updateSystemParameter(bytes32 _paramName, uint256 _newValue): Allows governance (owner/DAO) to update critical protocol constants (e.g., minProjectDeposit, milestoneVoteThreshold).
// 3. setOracleAddress(address _newOracleAddress): Updates the address of the trusted AI Oracle.
// 4. pauseContract(bool _pause): Enables emergency pausing/unpausing of critical operations.

// II. Soulbound Reputation (SBR) Management
// 5. registerExpertiseDomain(string memory _domainName): Creates a new category for reputation (e.g., "Smart Contract Dev", "Marketing").
// 6. mintReputationToken(address _to, uint256 _domainId, uint256 _amount): Mints SBR tokens to an address for a specific domain. (Typically invoked by an approved "Reputation Council" or through a separate verification process).
// 7. burnReputationToken(address _from, uint256 _domainId, uint256 _amount): Burns SBR tokens from an address.
// 8. delegateReputation(address _delegatee, uint256 _domainId): Allows an SBR holder to delegate their domain-specific reputation weight to another address for voting.
// 9. undelegateReputation(uint256 _domainId): Revokes a reputation delegation for a specific domain.
// 10. getReputationScore(address _account, uint256 _domainId): Retrieves the effective reputation score (including delegation) for an account in a specific domain.

// III. Project Lifecycle & Funding
// 11. submitProjectProposal(string memory _projectCID, uint256 _totalFundingRequested, uint256 _initialDeposit, bytes32[] memory _milestoneCIDs, uint256[] memory _milestoneAmounts, uint256[][] memory _milestoneRelevantDomains): Submits a new project proposal with details, funding, milestones, and relevant domains for each milestone.
// 12. voteOnProjectProposal(uint256 _projectId, bool _approve, uint256 _voteIntensity): SBR holders vote on project approval using quadratic voting weighted by their total reputation.
// 13. fundApprovedProject(uint256 _projectId): Transfers the initial project deposit (from the project creator) to the project's escrow after successful proposal approval.
// 14. submitMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, string memory _proofCID): Project team submits proof of milestone completion.
// 15. voteOnMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, bool _completed, uint256 _voteIntensity, uint256 _relevantDomainId): SBR holders vote on whether a milestone has been completed, weighted by reputation in a specified relevant domain.
// 16. releaseMilestoneFunds(uint256 _projectId, uint256 _milestoneIndex): Releases funds for a completed milestone, dynamically adjusted by the project's Cognitive Index.
// 17. disputeMilestone(uint256 _projectId, uint256 _milestoneIndex, uint256 _disputeStakeAmount): Allows a user to formally dispute a claimed milestone completion, requiring a stake.
// 18. resolveDispute(uint256 _projectId, uint256 _milestoneIndex, bool _isProjectSideRight): Governance or a dispute council resolves a milestone dispute, distributing stakes accordingly.

// IV. Cognitive Index (CI) & AI Oracle Interaction
// 19. requestCognitiveIndexUpdate(uint256 _projectId): Initiates a request to the AI Oracle for an updated Cognitive Index for a specific project.
// 20. receiveCognitiveIndexUpdate(uint256 _projectId, uint256 _newCI, uint256 _requestId): Callback function for the AI Oracle to deliver the updated CI. (Only callable by the registered oracle).

// V. Syntellect Stakes (SS) & Incentives
// 21. stakeOnProject(uint256 _projectId, uint256 _amount): Users stake funds on a project, believing it will succeed and meet its goals.
// 22. withdrawStake(uint256 _projectId): Allows users to withdraw their *active* stake under specific conditions (e.g., project failure, before any milestone completion is finalized).
// 23. claimStakeRewards(uint256 _projectId): Allows successful stakers to claim rewards, calculated based on the project's Cognitive Index and overall success.
// 24. claimFailedStakeRefund(uint256 _projectId): Allows stakers to claim a partial refund if a project fails or is abandoned.

// Interfaces for external contracts
interface IAIOracle {
    function requestCIUpdate(address _callbackContract, uint256 _projectId) external returns (uint256 requestId);
    // There could be more functions for the oracle, but this is sufficient for the example.
}

contract SyntellectNexus is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- State Variables ---
    IERC20 public immutable fundingToken;
    IAIOracle public aiOracle;
    bool public paused;

    uint256 public nextProjectId;
    uint256 public nextDomainId;
    uint256 public nextOracleRequestId;

    // System Parameters (Dynamic) - can be updated by governance
    mapping(bytes32 => uint256) public systemParameters;

    // Reputation (SBR)
    struct ReputationDomain {
        string name;
        address owner; // The entity/DAO responsible for minting in this domain
    }
    mapping(uint256 => ReputationDomain) public reputationDomains; // domainId => ReputationDomain
    mapping(address => mapping(uint256 => uint256)) private _reputationBalances; // account => domainId => amount
    mapping(address => mapping(uint256 => address)) private _reputationDelegates; // delegator => domainId => delegatee
    mapping(address => mapping(uint256 => uint256)) private _reputationVoteWeights; // delegatee => domainId => accumulated_weight

    // Projects
    enum ProjectStatus { PendingApproval, Approved, Active, Completed, Failed, Disputed }
    enum MilestoneStatus { Pending, Approved, Disputed, Completed }

    struct Milestone {
        bytes32 contentCID; // IPFS CID for milestone details
        uint256 amount;     // Funding amount for this milestone
        MilestoneStatus status;
        uint256 approvalVotes; // Total weighted votes for completion
        uint256 disapprovalVotes; // Total weighted votes against completion
        mapping(address => bool) hasVoted; // Voter address => if they voted on this milestone
        string proofCID;    // Proof of completion submitted by project team
        uint256[] relevantDomains; // SBR domains most relevant for voting on this milestone
        address currentDisputer; // Address of the current disputer
        uint256 disputeStake; // Amount staked by the disputer
    }

    struct Project {
        address payable creator;
        bytes32 projectCID;     // IPFS CID for project details
        uint256 totalFundingRequested;
        uint256 initialDeposit; // Creator's initial stake/deposit
        ProjectStatus status;
        uint256 currentCognitiveIndex; // AI Oracle driven, 0-10000 range
        uint256 projectApprovalVotes; // Total weighted votes for project approval
        uint256 projectDisapprovalVotes; // Total weighted votes against project approval
        mapping(address => bool) hasVotedForProposal; // Voter address => if they voted on this proposal
        uint256 fundsInEscrow; // Funds held for the project
        Milestone[] milestones;
        uint256 lastCIUpdateRequestId; // Last request ID sent to oracle
    }
    mapping(uint256 => Project) public projects;

    // Syntellect Stakes (SS)
    mapping(uint256 => mapping(address => uint256)) public projectStakes; // projectId => staker => amount
    mapping(uint256 => uint256) public totalProjectStakes; // projectId => total staked
    mapping(uint256 => mapping(address => bool)) public stakeClaimed; // projectId => staker => bool

    // Events
    event SystemParameterUpdated(bytes32 indexed paramName, uint256 newValue);
    event OracleAddressUpdated(address indexed newAddress);
    event ContractPaused(bool indexed isPaused);

    event ExpertiseDomainRegistered(uint256 indexed domainId, string name, address indexed owner);
    event ReputationMinted(address indexed to, uint256 indexed domainId, uint256 amount);
    event ReputationBurned(address indexed from, uint256 indexed domainId, uint256 amount);
    event ReputationDelegated(address indexed delegator, address indexed delegatee, uint256 indexed domainId);
    event ReputationUndelegated(address indexed delegator, uint256 indexed domainId);

    event ProjectProposed(uint256 indexed projectId, address indexed creator, uint256 totalFundingRequested);
    event ProjectProposalVoted(uint256 indexed projectId, address indexed voter, bool approved, uint256 effectiveWeight);
    event ProjectApproved(uint256 indexed projectId);
    event ProjectFunded(uint256 indexed projectId, uint256 amount);
    event MilestoneSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, string proofCID);
    event MilestoneVoted(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed voter, bool completed, uint256 effectiveWeight);
    event MilestoneFundsReleased(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amountReleased);
    event MilestoneDisputed(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed disputer, uint256 disputeStake);
    event MilestoneDisputeResolved(uint256 indexed projectId, uint256 indexed milestoneIndex, bool isProjectSideRight);

    event CIUpdateRequestSent(uint256 indexed projectId, uint256 indexed requestId);
    event CIUpdateReceived(uint256 indexed projectId, uint256 newCI, uint256 indexed requestId);

    event ProjectStaked(uint256 indexed projectId, address indexed staker, uint256 amount);
    event StakeWithdrawn(uint256 indexed projectId, address indexed staker, uint256 amount);
    event StakeRewardsClaimed(uint256 indexed projectId, address indexed staker, uint256 rewards);
    event FailedStakeRefunded(uint256 indexed projectId, address indexed staker, uint256 refundAmount);

    // Modifiers
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == address(aiOracle), "Only AI Oracle can call this function");
        _;
    }

    // --- Constructor ---
    constructor(address _aiOracleAddress, address _fundingTokenAddress) {
        require(_aiOracleAddress != address(0), "Oracle address cannot be zero");
        require(_fundingTokenAddress != address(0), "Funding token address cannot be zero");

        aiOracle = IAIOracle(_aiOracleAddress);
        fundingToken = IERC20(_fundingTokenAddress);
        paused = false;

        // Initialize default system parameters (these can be updated by governance)
        systemParameters[bytes32("MIN_PROJECT_DEPOSIT_PERCENT")] = 10; // 10% of total funding requested
        systemParameters[bytes32("PROJECT_APPROVAL_THRESHOLD")] = 60; // 60% approval for projects
        systemParameters[bytes32("MILESTONE_APPROVAL_THRESHOLD")] = 50; // 50% approval for milestones
        systemParameters[bytes32("DISPUTE_FEE_PERCENT")] = 2; // 2% of milestone amount
        systemParameters[bytes32("CI_IMPACT_FACTOR")] = 50; // How much CI affects funding (e.g., 50 means 50/10000 = 0.5% per CI point)
        systemParameters[bytes32("STAKE_REWARD_PERCENT_BASE")] = 10; // Base 10% reward for successful stakers
        systemParameters[bytes32("FAILED_STAKE_REFUND_PERCENT")] = 50; // 50% refund for failed projects
        systemParameters[bytes32("SBR_COUNCIL_ROLE_ID")] = 1; // Example role ID for SBR minting authority.
        // For simplicity, SBR minting/burning is done by owner in this example.
        // In a real DAO, this would be a specific "Reputation Council" role.
    }

    // --- I. Core System Management & Setup ---

    /**
     * @dev Allows governance (owner) to update critical protocol constants.
     * @param _paramName The name of the parameter (e.g., "MIN_PROJECT_DEPOSIT_PERCENT").
     * @param _newValue The new value for the parameter.
     */
    function updateSystemParameter(bytes32 _paramName, uint256 _newValue) external onlyOwner {
        systemParameters[_paramName] = _newValue;
        emit SystemParameterUpdated(_paramName, _newValue);
    }

    /**
     * @dev Updates the address of the trusted AI Oracle.
     * @param _newOracleAddress The new address for the AI Oracle contract.
     */
    function setOracleAddress(address _newOracleAddress) external onlyOwner {
        require(_newOracleAddress != address(0), "New oracle address cannot be zero");
        aiOracle = IAIOracle(_newOracleAddress);
        emit OracleAddressUpdated(_newOracleAddress);
    }

    /**
     * @dev Pauses or unpauses the contract in emergencies.
     * Only the owner can call this. Critical operations are affected.
     * @param _pause True to pause, false to unpause.
     */
    function pauseContract(bool _pause) external onlyOwner {
        paused = _pause;
        emit ContractPaused(_pause);
    }

    // --- II. Soulbound Reputation (SBR) Management ---

    /**
     * @dev Creates a new category for reputation (e.g., "Smart Contract Dev", "Marketing").
     * Only the owner (representing the DAO/governance) can register new domains.
     * @param _domainName The descriptive name for the new expertise domain.
     * @return The ID of the newly registered domain.
     */
    function registerExpertiseDomain(string memory _domainName) external onlyOwner returns (uint256) {
        uint256 domainId = nextDomainId++;
        reputationDomains[domainId] = ReputationDomain(_domainName, msg.sender); // For now, owner of Nexus is domain owner. Could be dynamic.
        emit ExpertiseDomainRegistered(domainId, _domainName, msg.sender);
        return domainId;
    }

    /**
     * @dev Mints SBR tokens to an address for a specific domain.
     * In a real system, this would be restricted to an authorized "Reputation Council" or based on
     * verifiable off-chain credentials/contributions, rather than just `onlyOwner`.
     * For this example, `onlyOwner` acts as the council.
     * @param _to The address to receive the SBR tokens.
     * @param _domainId The ID of the expertise domain.
     * @param _amount The amount of SBR tokens to mint.
     */
    function mintReputationToken(address _to, uint256 _domainId, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Cannot mint to zero address");
        require(reputationDomains[_domainId].owner != address(0), "Domain does not exist");
        // For simplicity, `onlyOwner` is the minter. Could be `require(msg.sender == reputationDomains[_domainId].owner)`
        _reputationBalances[_to][_domainId] = _reputationBalances[_to][_domainId].add(_amount);
        // If delegated, update delegatee's vote weight
        if (_reputationDelegates[_to][_domainId] != address(0)) {
            _reputationVoteWeights[_reputationDelegates[_to][_domainId]][_domainId] = _reputationVoteWeights[_reputationDelegates[_to][_domainId]][_domainId].add(_amount);
        } else {
            _reputationVoteWeights[_to][_domainId] = _reputationVoteWeights[_to][_domainId].add(_amount);
        }
        emit ReputationMinted(_to, _domainId, _amount);
    }

    /**
     * @dev Burns SBR tokens from an address for a specific domain.
     * Again, for this example, `onlyOwner` acts as the council for penalization or correction.
     * @param _from The address from which to burn the SBR tokens.
     * @param _domainId The ID of the expertise domain.
     * @param _amount The amount of SBR tokens to burn.
     */
    function burnReputationToken(address _from, uint256 _domainId, uint256 _amount) external onlyOwner {
        require(_from != address(0), "Cannot burn from zero address");
        require(_reputationBalances[_from][_domainId] >= _amount, "Insufficient reputation balance");

        _reputationBalances[_from][_domainId] = _reputationBalances[_from][_domainId].sub(_amount);
        // If delegated, update delegatee's vote weight
        if (_reputationDelegates[_from][_domainId] != address(0)) {
            _reputationVoteWeights[_reputationDelegates[_from][_domainId]][_domainId] = _reputationVoteWeights[_reputationDelegates[_from][_domainId]][_domainId].sub(_amount);
        } else {
            _reputationVoteWeights[_from][_domainId] = _reputationVoteWeights[_from][_domainId].sub(_amount);
        }
        emit ReputationBurned(_from, _domainId, _amount);
    }

    /**
     * @dev Allows an SBR holder to delegate their domain-specific reputation weight to another address for voting.
     * This implements a form of liquid democracy for reputation.
     * @param _delegatee The address to which reputation weight will be delegated.
     * @param _domainId The ID of the expertise domain.
     */
    function delegateReputation(address _delegatee, uint256 _domainId) external {
        require(_delegatee != address(0), "Delegatee cannot be zero address");
        require(_delegatee != msg.sender, "Cannot delegate to self");
        require(reputationDomains[_domainId].owner != address(0), "Domain does not exist");

        address currentDelegatee = _reputationDelegates[msg.sender][_domainId];
        uint256 reputationAmount = _reputationBalances[msg.sender][_domainId];

        // If already delegated, remove old delegation weight
        if (currentDelegatee != address(0)) {
            _reputationVoteWeights[currentDelegatee][_domainId] = _reputationVoteWeights[currentDelegatee][_domainId].sub(reputationAmount);
        } else {
            // If not delegated, remove original owner's weight
            _reputationVoteWeights[msg.sender][_domainId] = _reputationVoteWeights[msg.sender][_domainId].sub(reputationAmount);
        }

        // Set new delegatee and add weight
        _reputationDelegates[msg.sender][_domainId] = _delegatee;
        _reputationVoteWeights[_delegatee][_domainId] = _reputationVoteWeights[_delegatee][_domainId].add(reputationAmount);

        emit ReputationDelegated(msg.sender, _delegatee, _domainId);
    }

    /**
     * @dev Revokes a reputation delegation for a specific domain, returning voting power to the original holder.
     * @param _domainId The ID of the expertise domain.
     */
    function undelegateReputation(uint256 _domainId) external {
        address currentDelegatee = _reputationDelegates[msg.sender][_domainId];
        require(currentDelegatee != address(0), "No active delegation to undelegate");
        require(reputationDomains[_domainId].owner != address(0), "Domain does not exist");

        uint256 reputationAmount = _reputationBalances[msg.sender][_domainId];

        _reputationVoteWeights[currentDelegatee][_domainId] = _reputationVoteWeights[currentDelegatee][_domainId].sub(reputationAmount);
        _reputationDelegates[msg.sender][_domainId] = address(0);
        _reputationVoteWeights[msg.sender][_domainId] = _reputationVoteWeights[msg.sender][_domainId].add(reputationAmount); // Return weight to sender

        emit ReputationUndelegated(msg.sender, _domainId);
    }

    /**
     * @dev Retrieves the effective reputation score for an account in a specific domain.
     * This score includes any delegated reputation.
     * @param _account The address of the account.
     * @param _domainId The ID of the expertise domain.
     * @return The effective reputation score.
     */
    function getReputationScore(address _account, uint256 _domainId) public view returns (uint256) {
        // If _account has delegated its reputation, their effective score for voting is 0 for that domain.
        // We need to return the *active* voting power of an account in a domain.
        // This is stored in _reputationVoteWeights for the delegatee, or the original holder if not delegated.
        return _reputationVoteWeights[_account][_domainId];
    }

    /**
     * @dev Calculates total effective reputation score for an account across all domains.
     * @param _account The address of the account.
     * @return The total effective reputation score.
     */
    function getTotalReputationScore(address _account) public view returns (uint256) {
        uint256 totalScore = 0;
        for (uint256 i = 0; i < nextDomainId; i++) {
            totalScore = totalScore.add(getReputationScore(_account, i));
        }
        return totalScore;
    }

    // --- III. Project Lifecycle & Funding ---

    /**
     * @dev Submits a new project proposal with details, funding, milestones, and relevant domains for each milestone.
     * @param _projectCID IPFS CID for detailed project description.
     * @param _totalFundingRequested The total amount of funding requested for the project.
     * @param _initialDeposit Creator's initial stake/deposit, required to signal commitment.
     * @param _milestoneCIDs Array of IPFS CIDs for each milestone.
     * @param _milestoneAmounts Array of funding amounts for each milestone.
     * @param _milestoneRelevantDomains 2D array, where each inner array lists relevant domain IDs for a milestone.
     */
    function submitProjectProposal(
        string memory _projectCID,
        uint256 _totalFundingRequested,
        uint256 _initialDeposit,
        bytes32[] memory _milestoneCIDs,
        uint256[] memory _milestoneAmounts,
        uint256[][] memory _milestoneRelevantDomains
    ) external whenNotPaused nonReentrant {
        require(bytes(_projectCID).length > 0, "Project CID cannot be empty");
        require(_totalFundingRequested > 0, "Total funding requested must be greater than zero");
        require(_initialDeposit >= _totalFundingRequested.mul(systemParameters[bytes32("MIN_PROJECT_DEPOSIT_PERCENT")]).div(100), "Insufficient initial deposit");
        require(_milestoneCIDs.length > 0, "Must have at least one milestone");
        require(_milestoneCIDs.length == _milestoneAmounts.length, "Milestone CIDs and amounts mismatch");
        require(_milestoneCIDs.length == _milestoneRelevantDomains.length, "Milestone CIDs and relevant domains mismatch");

        // Ensure total milestone amounts do not exceed requested funding
        uint256 totalMilestoneAmount = 0;
        for (uint256 i = 0; i < _milestoneAmounts.length; i++) {
            totalMilestoneAmount = totalMilestoneAmount.add(_milestoneAmounts[i]);
        }
        require(totalMilestoneAmount <= _totalFundingRequested, "Milestone amounts exceed total requested funding");

        // Transfer initial deposit from creator to contract
        require(fundingToken.transferFrom(msg.sender, address(this), _initialDeposit), "Initial deposit transfer failed");

        Milestone[] memory newMilestones = new Milestone[](_milestoneCIDs.length);
        for (uint256 i = 0; i < _milestoneCIDs.length; i++) {
            newMilestones[i].contentCID = _milestoneCIDs[i];
            newMilestones[i].amount = _milestoneAmounts[i];
            newMilestones[i].status = MilestoneStatus.Pending;
            newMilestones[i].relevantDomains = _milestoneRelevantDomains[i];
        }

        uint256 projectId = nextProjectId++;
        projects[projectId] = Project({
            creator: payable(msg.sender),
            projectCID: _projectCID,
            totalFundingRequested: _totalFundingRequested,
            initialDeposit: _initialDeposit,
            status: ProjectStatus.PendingApproval,
            currentCognitiveIndex: 5000, // Default CI (50%) initially
            projectApprovalVotes: 0,
            projectDisapprovalVotes: 0,
            fundsInEscrow: _initialDeposit, // Initial deposit now in escrow
            milestones: newMilestones,
            lastCIUpdateRequestId: 0
        });

        emit ProjectProposed(projectId, msg.sender, _totalFundingRequested);
    }

    /**
     * @dev SBR holders vote on project approval using quadratic voting weighted by their total reputation.
     * @param _projectId The ID of the project to vote on.
     * @param _approve True for approval, false for disapproval.
     * @param _voteIntensity A numerical value representing the voter's intensity (e.g., 1-100).
     */
    function voteOnProjectProposal(uint256 _projectId, bool _approve, uint256 _voteIntensity) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist");
        require(project.status == ProjectStatus.PendingApproval, "Project is not in pending approval status");
        require(!project.hasVoted[msg.sender], "Already voted on this proposal");
        require(getTotalReputationScore(msg.sender) > 0, "Requires reputation to vote");
        require(_voteIntensity > 0, "Vote intensity must be positive");

        uint256 totalReputation = getTotalReputationScore(msg.sender);
        uint256 effectiveWeight = SafeMath.sqrt(_voteIntensity).mul(totalReputation); // Quadratic weighting by intensity, linearly by reputation

        if (_approve) {
            project.projectApprovalVotes = project.projectApprovalVotes.add(effectiveWeight);
        } else {
            project.projectDisapprovalVotes = project.projectDisapprovalVotes.add(effectiveWeight);
        }
        project.hasVoted[msg.sender] = true;

        emit ProjectProposalVoted(_projectId, msg.sender, _approve, effectiveWeight);

        // Check if approval threshold is met. This logic can be more complex (e.g., voting period).
        // For simplicity, it checks immediately after a vote.
        uint256 totalVotes = project.projectApprovalVotes.add(project.projectDisapprovalVotes);
        if (totalVotes > 0 && project.projectApprovalVotes.mul(100).div(totalVotes) >= systemParameters[bytes32("PROJECT_APPROVAL_THRESHOLD")]) {
             project.status = ProjectStatus.Approved;
             emit ProjectApproved(_projectId);
        } else if (totalVotes > 0 && project.projectDisapprovalVotes.mul(100).div(totalVotes) > (100 - systemParameters[bytes32("PROJECT_APPROVAL_THRESHOLD")])) {
            project.status = ProjectStatus.Failed; // Project failed if enough disapproval
            // Funds from initial deposit might be partially refunded or kept as penalty
        }
    }

    /**
     * @dev Transfers the initial project funding (ERC20 tokens) from a sponsor or general fund
     * to the project's escrow after successful proposal approval.
     * This function assumes an external actor or DAO contributes the funding.
     * @param _projectId The ID of the approved project.
     */
    function fundApprovedProject(uint256 _projectId) external whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist");
        require(project.status == ProjectStatus.Approved, "Project is not in approved status");
        require(project.fundsInEscrow < project.totalFundingRequested, "Project is already fully funded");

        uint256 amountToFund = project.totalFundingRequested.sub(project.fundsInEscrow);
        require(amountToFund > 0, "No additional funds needed for this project");

        // Assumes msg.sender (e.g., DAO treasury or a specific funder) is providing the funds.
        require(fundingToken.transferFrom(msg.sender, address(this), amountToFund), "Funding transfer failed");

        project.fundsInEscrow = project.fundsInEscrow.add(amountToFund);
        project.status = ProjectStatus.Active; // Project moves to active once fully funded
        emit ProjectFunded(_projectId, amountToFund);
    }

    /**
     * @dev Project team submits proof of milestone completion.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone being completed.
     * @param _proofCID IPFS CID for proof of completion.
     */
    function submitMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, string memory _proofCID) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.creator == msg.sender, "Only project creator can submit milestone completion");
        require(project.status == ProjectStatus.Active, "Project is not active");
        require(_milestoneIndex < project.milestones.length, "Invalid milestone index");
        require(project.milestones[_milestoneIndex].status == MilestoneStatus.Pending, "Milestone is not in pending status");
        require(bytes(_proofCID).length > 0, "Proof CID cannot be empty");

        project.milestones[_milestoneIndex].status = MilestoneStatus.Approved; // Temporarily "Approved" meaning ready for community vote
        project.milestones[_milestoneIndex].proofCID = _proofCID;

        emit MilestoneSubmitted(_projectId, _milestoneIndex, _proofCID);
    }

    /**
     * @dev SBR holders vote on whether a milestone has been completed, weighted by reputation in a specified relevant domain.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @param _completed True if the voter believes the milestone is completed, false otherwise.
     * @param _voteIntensity A numerical value representing the voter's intensity (e.g., 1-100).
     * @param _relevantDomainId The specific SBR domain ID that the voter is applying their expertise from.
     */
    function voteOnMilestoneCompletion(
        uint256 _projectId,
        uint256 _milestoneIndex,
        bool _completed,
        uint256 _voteIntensity,
        uint256 _relevantDomainId
    ) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist");
        require(_milestoneIndex < project.milestones.length, "Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.Approved || milestone.status == MilestoneStatus.Disputed, "Milestone not ready for voting or already completed");
        require(!milestone.hasVoted[msg.sender], "Already voted on this milestone");
        require(getReputationScore(msg.sender, _relevantDomainId) > 0, "Requires reputation in the specified domain to vote");
        require(_voteIntensity > 0, "Vote intensity must be positive");

        bool domainIsRelevant = false;
        for (uint256 i = 0; i < milestone.relevantDomains.length; i++) {
            if (milestone.relevantDomains[i] == _relevantDomainId) {
                domainIsRelevant = true;
                break;
            }
        }
        require(domainIsRelevant, "Specified domain is not relevant for this milestone");

        uint256 reputationInDomain = getReputationScore(msg.sender, _relevantDomainId);
        uint256 effectiveWeight = SafeMath.sqrt(_voteIntensity).mul(reputationInDomain);

        if (_completed) {
            milestone.approvalVotes = milestone.approvalVotes.add(effectiveWeight);
        } else {
            milestone.disapprovalVotes = milestone.disapprovalVotes.add(effectiveWeight);
        }
        milestone.hasVoted[msg.sender] = true;

        emit MilestoneVoted(_projectId, _milestoneIndex, msg.sender, _completed, effectiveWeight);
    }

    /**
     * @dev Releases funds for a completed milestone, dynamically adjusted by the project's Cognitive Index.
     * This function can be called by anyone once voting period ends or certain conditions are met.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone to release funds for.
     */
    function releaseMilestoneFunds(uint256 _projectId, uint256 _milestoneIndex) external whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist");
        require(project.status == ProjectStatus.Active, "Project is not active");
        require(_milestoneIndex < project.milestones.length, "Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.Approved, "Milestone is not in approved status for release (check voting)");

        uint256 totalVotes = milestone.approvalVotes.add(milestone.disapprovalVotes);
        require(totalVotes > 0, "No votes recorded for this milestone yet"); // Ensure minimum participation

        uint256 approvalPercentage = milestone.approvalVotes.mul(100).div(totalVotes);
        require(approvalPercentage >= systemParameters[bytes32("MILESTONE_APPROVAL_THRESHOLD")], "Milestone did not meet approval threshold");

        // Calculate dynamic release amount based on CI
        uint256 baseAmount = milestone.amount;
        // CI is 0-10000. 5000 is neutral. Higher CI boosts, lower CI reduces.
        // E.g., CI 6000 means +1000 from neutral. Factor 50 means 1000 * 0.005 = 5% boost.
        int256 ciAdjustment = int256(project.currentCognitiveIndex).sub(5000); // Signed adjustment
        uint256 ciImpactFactor = systemParameters[bytes32("CI_IMPACT_FACTOR")]; // e.g., 50 (0.5% per 100 CI points from neutral)

        uint256 adjustedAmount;
        if (ciAdjustment > 0) {
            uint256 boost = baseAmount.mul(uint256(ciAdjustment)).mul(ciImpactFactor).div(1000000); // 10000 for CI scale, 100 for percentage
            adjustedAmount = baseAmount.add(boost);
        } else {
            uint256 reduction = baseAmount.mul(uint256(ciAdjustment * -1)).mul(ciImpactFactor).div(1000000);
            adjustedAmount = baseAmount.sub(reduction);
        }
        
        // Ensure adjusted amount does not exceed total funding requested or available escrow
        adjustedAmount = SafeMath.min(adjustedAmount, project.totalFundingRequested.sub(project.initialDeposit)); // Exclude initial deposit from funding pool
        // Cap adjusted amount at what's in escrow remaining for milestones
        adjustedAmount = SafeMath.min(adjustedAmount, project.fundsInEscrow.sub(project.initialDeposit)); // Only funds beyond initial deposit are for milestones

        require(project.fundsInEscrow >= adjustedAmount, "Insufficient funds in escrow for milestone release");

        // Update project funds
        project.fundsInEscrow = project.fundsInEscrow.sub(adjustedAmount);
        milestone.status = MilestoneStatus.Completed;

        // Transfer funds to project creator
        require(fundingToken.transfer(project.creator, adjustedAmount), "Milestone fund transfer failed");

        emit MilestoneFundsReleased(_projectId, _milestoneIndex, adjustedAmount);

        // Check if all milestones are completed to finalize project
        bool allCompleted = true;
        for (uint256 i = 0; i < project.milestones.length; i++) {
            if (project.milestones[i].status != MilestoneStatus.Completed) {
                allCompleted = false;
                break;
            }
        }
        if (allCompleted) {
            project.status = ProjectStatus.Completed;
            // Any remaining initial deposit could be refunded to creator or released as bonus/penalty
        }
    }

    /**
     * @dev Allows a user to formally dispute a claimed milestone completion, requiring a stake.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @param _disputeStakeAmount The amount of fundingToken to stake for the dispute.
     */
    function disputeMilestone(uint256 _projectId, uint256 _milestoneIndex, uint256 _disputeStakeAmount) external whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist");
        require(_milestoneIndex < project.milestones.length, "Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.Approved, "Milestone is not in an approved state to dispute");
        require(milestone.currentDisputer == address(0), "Milestone is already under dispute");
        require(_disputeStakeAmount > 0, "Dispute stake must be positive");
        require(fundingToken.transferFrom(msg.sender, address(this), _disputeStakeAmount), "Dispute stake transfer failed");

        milestone.currentDisputer = msg.sender;
        milestone.disputeStake = _disputeStakeAmount;
        milestone.status = MilestoneStatus.Disputed;

        emit MilestoneDisputed(_projectId, _milestoneIndex, msg.sender, _disputeStakeAmount);
    }

    /**
     * @dev Governance or a dispute council resolves a milestone dispute, distributing stakes accordingly.
     * This function is expected to be called by the `owner` (representing the DAO/governance).
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @param _isProjectSideRight True if the project's claim of completion is upheld, false if the disputer is correct.
     */
    function resolveDispute(uint256 _projectId, uint256 _milestoneIndex, bool _isProjectSideRight) external onlyOwner whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist");
        require(_milestoneIndex < project.milestones.length, "Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.Disputed, "Milestone is not currently under dispute");
        require(milestone.currentDisputer != address(0), "No active disputer for this milestone");

        uint256 disputeStake = milestone.disputeStake;
        address disputer = milestone.currentDisputer;

        if (_isProjectSideRight) {
            // Project was right, disputer loses stake (or a portion)
            // Stake can be burned, sent to treasury, or used for rewards.
            // For simplicity, it's sent to the project creator as compensation for the dispute.
            require(fundingToken.transfer(project.creator, disputeStake), "Transfer dispute stake to creator failed");
        } else {
            // Disputer was right, milestone completion is invalid. Disputer gets stake back.
            require(fundingToken.transfer(disputer, disputeStake), "Refund dispute stake to disputer failed");
            // Set status back to Pending, requiring re-submission or project failure.
            milestone.status = MilestoneStatus.Pending;
        }

        milestone.currentDisputer = address(0);
        milestone.disputeStake = 0;

        emit MilestoneDisputeResolved(_projectId, _milestoneIndex, _isProjectSideRight);
    }


    // --- IV. Cognitive Index (CI) & AI Oracle Interaction ---

    /**
     * @dev Initiates a request to the AI Oracle for an updated Cognitive Index for a specific project.
     * Callable by anyone, but oracle will charge a fee.
     * @param _projectId The ID of the project to request CI update for.
     * @return The request ID generated by the oracle.
     */
    function requestCognitiveIndexUpdate(uint256 _projectId) external whenNotPaused returns (uint256) {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist");
        require(project.status == ProjectStatus.Active, "Project is not active for CI updates");

        uint256 requestId = aiOracle.requestCIUpdate(address(this), _projectId);
        project.lastCIUpdateRequestId = requestId; // Store the request ID for tracking
        nextOracleRequestId = requestId.add(1); // Increment local counter (if oracle uses sequential IDs)

        emit CIUpdateRequestSent(_projectId, requestId);
        return requestId;
    }

    /**
     * @dev Callback function for the AI Oracle to deliver the updated CI.
     * Only callable by the registered oracle.
     * @param _projectId The ID of the project.
     * @param _newCI The new Cognitive Index value (e.g., 0-10000 scale).
     * @param _requestId The ID of the original request.
     */
    function receiveCognitiveIndexUpdate(uint256 _projectId, uint256 _newCI, uint256 _requestId) external onlyOracle {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist");
        require(project.lastCIUpdateRequestId == _requestId, "Invalid or outdated request ID for CI update");
        require(_newCI <= 10000, "Cognitive Index out of bounds (0-10000)");

        project.currentCognitiveIndex = _newCI;
        project.lastCIUpdateRequestId = 0; // Reset after fulfillment

        emit CIUpdateReceived(_projectId, _newCI, _requestId);
    }

    // --- V. Syntellect Stakes (SS) & Incentives ---

    /**
     * @dev Users stake funds on a project, believing it will succeed and meet its goals.
     * @param _projectId The ID of the project to stake on.
     * @param _amount The amount of fundingToken to stake.
     */
    function stakeOnProject(uint256 _projectId, uint256 _amount) external whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist");
        require(project.status == ProjectStatus.Active, "Can only stake on active projects");
        require(_amount > 0, "Stake amount must be positive");
        require(fundingToken.transferFrom(msg.sender, address(this), _amount), "Stake transfer failed");

        projectStakes[_projectId][msg.sender] = projectStakes[_projectId][msg.sender].add(_amount);
        totalProjectStakes[_projectId] = totalProjectStakes[_projectId].add(_amount);

        emit ProjectStaked(_projectId, msg.sender, _amount);
    }

    /**
     * @dev Allows users to withdraw their *active* stake under specific conditions
     * (e.g., project failure, before any milestone completion is finalized).
     * @param _projectId The ID of the project.
     */
    function withdrawStake(uint256 _projectId) external whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist");
        require(projectStakes[_projectId][msg.sender] > 0, "No active stake found for this project");
        require(project.status != ProjectStatus.Completed, "Cannot withdraw stake from completed project");

        // Allow withdrawal if project is failed or still pending, or if no milestones completed yet
        bool anyMilestoneCompleted = false;
        for (uint256 i = 0; i < project.milestones.length; i++) {
            if (project.milestones[i].status == MilestoneStatus.Completed) {
                anyMilestoneCompleted = true;
                break;
            }
        }
        require(!anyMilestoneCompleted || project.status == ProjectStatus.Failed, "Withdrawal not allowed after milestone completion or if project is active");

        uint256 amountToWithdraw = projectStakes[_projectId][msg.sender];
        projectStakes[_projectId][msg.sender] = 0;
        totalProjectStakes[_projectId] = totalProjectStakes[_projectId].sub(amountToWithdraw);

        require(fundingToken.transfer(msg.sender, amountToWithdraw), "Stake withdrawal failed");
        emit StakeWithdrawn(_projectId, msg.sender, amountToWithdraw);
    }

    /**
     * @dev Allows successful stakers to claim rewards, calculated based on the project's Cognitive Index and overall success.
     * @param _projectId The ID of the project.
     */
    function claimStakeRewards(uint256 _projectId) external whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist");
        require(project.status == ProjectStatus.Completed, "Project is not completed yet");
        require(projectStakes[_projectId][msg.sender] > 0, "No stake found for this project");
        require(!stakeClaimed[_projectId][msg.sender], "Rewards already claimed");

        uint256 stakedAmount = projectStakes[_projectId][msg.sender];
        uint256 ciBonus = project.currentCognitiveIndex.sub(5000); // Higher CI = better rewards
        uint256 rewardPercentage = systemParameters[bytes32("STAKE_REWARD_PERCENT_BASE")]; // Base e.g. 10%

        // Adjust reward percentage based on CI (e.g., for every 1000 CI points above 5000, add 1% reward)
        if (ciBonus > 0) {
            rewardPercentage = rewardPercentage.add(ciBonus.div(1000)); // Simple linear bonus for every 1000 CI points
        }
        
        uint256 rewards = stakedAmount.mul(rewardPercentage).div(100);
        uint256 totalPayout = stakedAmount.add(rewards);

        // Ensure contract has enough funds (e.g., from penalties, initial deposit surplus, or a treasury)
        // For simplicity, assuming the contract has these funds or they come from initial project over-funding.
        // In a real system, this would need a treasury or a clear source of reward funds.
        require(fundingToken.transfer(msg.sender, totalPayout), "Claim rewards failed, contract balance insufficient");

        projectStakes[_projectId][msg.sender] = 0; // Clear stake after claiming
        totalProjectStakes[_projectId] = totalProjectStakes[_projectId].sub(stakedAmount);
        stakeClaimed[_projectId][msg.sender] = true;

        emit StakeRewardsClaimed(_projectId, msg.sender, rewards);
    }

    /**
     * @dev Allows stakers to claim a partial refund if a project fails or is abandoned.
     * @param _projectId The ID of the project.
     */
    function claimFailedStakeRefund(uint256 _projectId) external whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist");
        require(project.status == ProjectStatus.Failed, "Project is not in failed status");
        require(projectStakes[_projectId][msg.sender] > 0, "No stake found for this project");
        require(!stakeClaimed[_projectId][msg.sender], "Refund already claimed");

        uint256 stakedAmount = projectStakes[_projectId][msg.sender];
        uint256 refundPercentage = systemParameters[bytes32("FAILED_STAKE_REFUND_PERCENT")]; // e.g., 50%
        uint256 refundAmount = stakedAmount.mul(refundPercentage).div(100);

        // Refund from available funds in contract
        require(fundingToken.transfer(msg.sender, refundAmount), "Refund failed, contract balance insufficient");

        projectStakes[_projectId][msg.sender] = 0;
        totalProjectStakes[_projectId] = totalProjectStakes[_projectId].sub(stakedAmount);
        stakeClaimed[_projectId][msg.sender] = true;

        emit FailedStakeRefunded(_projectId, msg.sender, refundAmount);
    }

    // --- Utility Functions ---

    /**
     * @dev Internal helper for calculating square root for quadratic voting.
     * @param x The number to find the integer square root of.
     * @return The integer square root.
     */
    function SafeMath_sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x;
        y = 1;
        if (x == 0) return 0;
        while (z > y) {
            y = (y + z) / 2;
            z = x / y;
        }
    }
}
```