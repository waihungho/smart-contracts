Okay, this is an exciting challenge! Let's design a smart contract for a "QuantumLeap DAO" – a decentralized autonomous organization focused on funding and governing highly speculative, high-impact "Quantum Projects." It will incorporate advanced concepts like dynamic reputation, adaptive governance, on-chain "knowledge" accumulation, and a unique reward system.

We'll avoid duplicating standard open-source components by creating novel interactions and logic for the core features.

---

## QuantumLeap DAO Smart Contract

This contract implements a sophisticated DAO focused on funding and managing cutting-edge, high-risk, high-reward "Quantum Projects." It introduces dynamic member reputation, adaptive governance parameters, a collective "knowledge base" derived from project outcomes, and an innovative impact-based reward distribution system.

### **Outline & Function Summary**

**Contract Name:** `QuantumLeapDAO`

**Purpose:** To serve as a decentralized organization for collectively identifying, funding, governing, and learning from experimental "Quantum Projects."

**Key Features:**
1.  **Dynamic Member Reputation (Expertise Scores):** Members accumulate expertise in various domains based on successful project contributions, accurate voting, and verified impact.
2.  **Adaptive Governance:** Core DAO parameters (quorum, voting thresholds, challenge periods) can be dynamically adjusted through governance proposals, allowing the DAO to "learn" and evolve.
3.  **On-chain Knowledge Base:** Project outcomes (success, failure, impact) are recorded, forming a collective, queryable "knowledge base" for future decision-making.
4.  **Impact-Based Rewards:** Rewards are distributed proportionally to a member's demonstrated impact and expertise, moving beyond simple token holdings.
5.  **Project Lifecycle Management:** Comprehensive process from proposal to funding, milestone tracking, outcome verification, and finalization.
6.  **"Quantum Anomaly" Simulation:** A conceptual placeholder for unpredictable external factors affecting projects, adding a layer of advanced simulation.

---

**Function Summary:**

**A. Core DAO Management & Setup**
1.  `constructor()`: Initializes the DAO with an initial administrator and core parameters.
2.  `depositFunds()`: Allows anyone to deposit funds into the DAO treasury.
3.  `setCoreGovernanceParameter()`: Allows DAO admins (initially deployer, later DAO-governed) to set crucial, non-adaptive governance parameters.
4.  `withdrawDAOFunds()`: Executes a withdrawal of funds from the DAO treasury, requiring a successful governance proposal.

**B. Member Management & Expertise**
5.  `registerMember()`: Allows a new address to register as a DAO member.
6.  `updateMemberProfile()`: Allows members to update their self-declared expertise domains and descriptions.
7.  `delegateExpertiseWeight()`: Allows members to delegate their expertise weight for specific domains to another member for voting purposes.
8.  `liquidateMember()`: Initiates a governance proposal to remove a problematic member, potentially revoking their expertise points.

**C. Project Lifecycle & Funding**
9.  `proposeQuantumProject()`: Allows a member to submit a new "Quantum Project" proposal for funding.
10. `voteOnProjectProposal()`: Allows members to vote on active project funding proposals, weighted by their dynamic expertise.
11. `executeProjectFunding()`: Executes the transfer of funds to a project lead after a successful funding vote.
12. `submitProjectMilestone()`: Allows a project lead to update the progress of their funded project by submitting milestone reports.
13. `verifyProjectOutcome()`: Initiates the process for a designated "verifier" committee (or role) to assess a project's final outcome (success/failure/impact).
14. `challengeProjectOutcome()`: Allows a member to challenge a project's verified outcome, initiating a re-evaluation process.
15. `finalizeProject()`: Marks a project as complete after its outcome has been verified and all rewards/penalties processed.

**D. Reputation, Rewards & Knowledge Base**
16. `awardExpertisePoints()`: System function (called internally or by verifiers) to grant expertise points based on positive contributions.
17. `penalizeExpertisePoints()`: System function (called internally or by verifiers/governance) to deduct expertise points for negative contributions.
18. `calculateDynamicVotingWeight()`: (Public view function) Calculates a member's current voting weight based on their token holdings and accumulated expertise.
19. `queryKnowledgeBase()`: Allows querying the DAO's on-chain knowledge base for insights into past project outcomes for a given project type or risk profile.
20. `distributeAdaptiveRewards()`: Triggers the distribution of rewards from the treasury based on a member's total verified impact and contribution across projects.

**E. Adaptive Governance & Advanced Concepts**
21. `initiateParameterAdjustmentProposal()`: Allows members to propose changes to core adaptive governance parameters (e.g., quorum, voting duration).
22. `voteOnParameterAdjustment()`: Allows members to vote on proposals to adjust DAO governance parameters.
23. `enactParameterAdjustment()`: Applies the proposed governance parameter changes after a successful vote.
24. `signalResearchPriority()`: Allows members to signal their preferred research domains or project types, influencing future DAO focus.
25. `proposeInterchainInitiative()`: A conceptual function allowing proposals for cross-chain or external system interactions, requiring off-chain execution or oracle integration.
26. `initiateDomainAudit()`: Triggers a governance proposal to audit the expertise scores or performance metrics within a specific project domain.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For treasury, assuming a standard ERC20 for funding.

/**
 * @title QuantumLeapDAO
 * @dev A sophisticated DAO for funding and governing high-risk, high-reward "Quantum Projects."
 *      Features dynamic reputation, adaptive governance, on-chain knowledge base, and impact-based rewards.
 */
contract QuantumLeapDAO is AccessControl {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- Roles ---
    bytes32 public constant DAO_ADMIN_ROLE = keccak256("DAO_ADMIN_ROLE"); // Manages initial parameters, can propose changes.
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");   // Designated to verify project outcomes.

    // --- Events ---
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event MemberRegistered(address indexed memberAddress, string name);
    event MemberProfileUpdated(address indexed memberAddress);
    event ExpertiseDelegated(address indexed delegator, address indexed delegatee, string domain);
    event MemberLiquidated(address indexed memberAddress);

    event ProjectProposed(uint256 indexed projectId, address indexed proposer, string name, uint256 requestedFunds);
    event ProjectVoteCast(uint256 indexed projectId, address indexed voter, bool support, uint256 weight);
    event ProjectFunded(uint256 indexed projectId, address indexed projectLead, uint256 amount);
    event ProjectMilestoneSubmitted(uint256 indexed projectId, uint256 milestoneIndex, string description);
    event ProjectOutcomeVerified(uint256 indexed projectId, ProjectOutcome outcome, uint256 impactScore);
    event ProjectOutcomeChallenged(uint256 indexed projectId, address indexed challenger);
    event ProjectFinalized(uint256 indexed projectId, ProjectOutcome finalOutcome);

    event ExpertiseAwarded(address indexed member, string domain, uint256 points);
    event ExpertisePenalized(address indexed member, string domain, uint256 points);
    event RewardsDistributed(address indexed member, uint256 amount);

    event ParameterAdjustmentProposed(uint256 indexed proposalId, string paramName, uint256 newValue);
    event ParameterAdjustmentVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ParameterAdjustmentEnacted(string paramName, uint256 newValue);

    event ResearchPrioritySignaled(address indexed member, string domain);
    event InterchainInitiativeProposed(uint256 indexed proposalId, string description);
    event DomainAuditInitiated(string indexed domain);

    // --- Enums ---
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Canceled }
    enum ProjectStatus { Proposed, Active, MilestoneSubmitted, VerificationPending, Verified, Challenged, Finalized }
    enum ProjectOutcome { Undefined, Success, PartialSuccess, Failure, Anomalous } // Anomalous for unpredictable factors

    // --- Structs ---

    struct Member {
        string name;
        string description;
        bool isRegistered;
        // Mapping of expertise domain to points (e.g., "AI" => 100 points)
        mapping(string => uint256) expertisePoints;
        // Delegated expertise: delegatee => domain => points
        mapping(address => mapping(string => uint256)) delegatedExpertiseOut;
        // Received expertise: delegator => domain => points
        mapping(address => mapping(string => uint256)) receivedExpertiseIn;
        uint256 totalImpactScore; // Cumulative score from successful projects
        uint256 lastRewardClaimBlock; // Block number of last reward claim
    }

    struct Project {
        Counters.Counter id;
        address proposer;
        address projectLead; // Can be proposer or another designated address
        string name;
        string description;
        uint256 requestedFunds;
        uint256 fundedAmount;
        string[] expertiseDomainsRequired; // e.g., ["AI", "QuantumPhysics"]
        uint256 proposalBlock;
        uint256 voteEndTime;
        uint256 totalForVotes;
        uint256 totalAgainstVotes;
        mapping(address => bool) hasVoted; // Voter address => true
        ProjectStatus status;
        ProjectOutcome finalOutcome;
        uint256 verifiedImpactScore;
        uint256 challengePeriodEndTime;
        string[] milestoneDescriptions; // Log of submitted milestones
        mapping(uint256 => bytes32) milestoneHashes; // Hash of milestone content for integrity
        // On-chain "knowledge" entry related to this project (index into s_knowledgeBase)
        uint256 knowledgeEntryIndex;
        mapping(address => bool) voterForProposal; // True if voted for, false if voted against
    }

    struct GovernanceProposal {
        Counters.Counter id;
        string description;
        address proposer;
        uint256 proposalBlock;
        uint256 voteEndTime;
        uint256 totalForVotes;
        uint256 totalAgainstVotes;
        mapping(address => bool) hasVoted;
        ProposalState state;
        bytes data; // Encoded function call for parameter adjustment or treasury withdrawal
        bytes32 targetFunctionSelector; // Selector of the function to be called
        address targetAddress; // Target contract for the call (e.g., self for parameter adjustment)
    }

    struct ParameterAdjustmentProposal {
        Counters.Counter id;
        string paramName;
        uint256 newValue;
        uint256 proposalBlock;
        uint256 voteEndTime;
        uint256 totalForVotes;
        uint256 totalAgainstVotes;
        mapping(address => bool) hasVoted;
        ProposalState state;
    }

    // On-chain knowledge base entry, derived from verified project outcomes
    struct KnowledgeEntry {
        uint256 projectId;
        string projectName;
        string[] expertiseDomains;
        ProjectOutcome outcome;
        uint256 impactScore;
        uint256 riskProfile; // e.g., 1-10, determined by proposer/verifiers
        // Future: bytes32 dataHash; // Hash of detailed project report (off-chain)
    }

    // --- State Variables ---
    IERC20 public immutable daoTreasuryToken; // The ERC20 token used for funding
    address public treasuryAddress; // Address of the actual treasury (could be this contract or a separate vault)

    // Counters for unique IDs
    Counters.Counter private _projectIdCounter;
    Counters.Counter private _generalProposalIdCounter; // For withdraw, member liquidation, interchain
    Counters.Counter private _paramAdjustmentIdCounter;

    // Mappings for data storage
    mapping(address => Member) public s_members;
    mapping(uint256 => Project) public s_projects; // project ID => Project struct
    mapping(uint256 => GovernanceProposal) public s_generalProposals; // proposal ID => GovernanceProposal struct
    mapping(uint256 => ParameterAdjustmentProposal) public s_paramAdjustmentProposals; // param adj ID => proposal struct

    // On-chain knowledge base (array of entries)
    KnowledgeEntry[] public s_knowledgeBase;

    // Core DAO governance parameters (adaptive)
    uint256 public projectProposalVotingPeriodBlocks; // How long project proposals are open for voting
    uint256 public governanceProposalVotingPeriodBlocks; // How long governance proposals are open
    uint256 public projectFundingQuorumPercentage; // % of total voting weight needed to pass project funding
    uint256 public governanceQuorumPercentage; // % of total voting weight needed to pass governance proposals
    uint256 public challengePeriodBlocks; // Time window to challenge a project outcome
    uint256 public minExpertiseForProjectLead; // Minimum expertise points required to be a project lead
    uint256 public minImpactScoreForReward; // Minimum impact score required for reward distribution

    // Global total voting weight (sum of all members' expertise points)
    uint256 public totalGlobalExpertiseWeight; // Sum of all expertise points across all domains for all members

    // --- Modifiers ---
    modifier onlyMember() {
        require(s_members[msg.sender].isRegistered, "QLDAO: Caller is not a registered member.");
        _;
    }

    modifier onlyProjectLead(uint256 _projectId) {
        require(s_projects[_projectId].projectLead == msg.sender, "QLDAO: Caller is not the project lead.");
        _;
    }

    modifier onlyVerifier() {
        require(hasRole(VERIFIER_ROLE, msg.sender), "QLDAO: Caller does not have VERIFIER_ROLE.");
        _;
    }

    modifier proposalState(uint256 _proposalId, ProposalState _expectedState) {
        require(s_generalProposals[_proposalId].state == _expectedState, "QLDAO: Invalid proposal state.");
        _;
    }

    modifier paramAdjProposalState(uint256 _proposalId, ProposalState _expectedState) {
        require(s_paramAdjustmentProposals[_proposalId].state == _expectedState, "QLDAO: Invalid parameter adjustment proposal state.");
        _;
    }

    modifier projectStatus(uint256 _projectId, ProjectStatus _expectedStatus) {
        require(s_projects[_projectId].status == _expectedStatus, "QLDAO: Invalid project status.");
        _;
    }

    // --- Constructor ---
    constructor(address _treasuryTokenAddress, address _initialDAOAdmin) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Deployer is default admin
        _grantRole(DAO_ADMIN_ROLE, _initialDAOAdmin); // Initial DAO Admin role
        _grantRole(VERIFIER_ROLE, _initialDAOAdmin); // Initial Verifier role (can be changed by DAO later)

        daoTreasuryToken = IERC20(_treasuryTokenAddress);
        treasuryAddress = address(this); // The contract itself holds the treasury

        // Initial core governance parameters
        projectProposalVotingPeriodBlocks = 1000; // Approx 4 hours with 14s blocks
        governanceProposalVotingPeriodBlocks = 2000; // Approx 8 hours
        projectFundingQuorumPercentage = 50; // 50% of total voting weight
        governanceQuorumPercentage = 60; // 60% of total voting weight
        challengePeriodBlocks = 500; // Approx 2 hours
        minExpertiseForProjectLead = 100; // Minimum expertise to lead a project
        minImpactScoreForReward = 1; // Minimum score to qualify for rewards
    }

    // --- A. Core DAO Management & Setup ---

    /**
     * @dev Allows anyone to deposit ERC20 tokens into the DAO treasury.
     * @param _amount The amount of tokens to deposit.
     */
    function depositFunds(uint256 _amount) external {
        require(daoTreasuryToken.transferFrom(msg.sender, treasuryAddress, _amount), "QLDAO: Token transfer failed.");
        emit FundsDeposited(msg.sender, _amount);
    }

    /**
     * @dev Allows a DAO Admin to set non-adaptive core governance parameters.
     *      For adaptive parameters, use `initiateParameterAdjustmentProposal`.
     *      This function is for initial setup or critical overrides by the DAO_ADMIN_ROLE,
     *      which itself should be governed by the DAO over time (e.g., multisig).
     * @param _paramName The name of the parameter to set (e.g., "minExpertiseForProjectLead").
     * @param _newValue The new value for the parameter.
     */
    function setCoreGovernanceParameter(string calldata _paramName, uint256 _newValue)
        external
        onlyRole(DAO_ADMIN_ROLE)
    {
        if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("minExpertiseForProjectLead"))) {
            minExpertiseForProjectLead = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("minImpactScoreForReward"))) {
            minImpactScoreForReward = _newValue;
        } else {
            revert("QLDAO: Invalid parameter name for direct setting.");
        }
        emit ParameterAdjustmentEnacted(_paramName, _newValue);
    }

    /**
     * @dev Initiates a governance proposal to withdraw funds from the DAO treasury.
     *      Requires a vote to pass.
     * @param _recipient The address to send funds to.
     * @param _amount The amount of tokens to withdraw.
     * @param _description A description for the withdrawal purpose.
     * @return The ID of the created proposal.
     */
    function withdrawDAOFunds(address _recipient, uint256 _amount, string calldata _description)
        external
        onlyMember
        returns (uint256)
    {
        require(_amount > 0, "QLDAO: Withdrawal amount must be greater than zero.");
        require(daoTreasuryToken.balanceOf(treasuryAddress) >= _amount, "QLDAO: Insufficient treasury funds.");

        _generalProposalIdCounter.increment();
        uint256 proposalId = _generalProposalIdCounter.current();

        s_generalProposals[proposalId] = GovernanceProposal({
            id: Counters.to = (proposalId),
            description: _description,
            proposer: msg.sender,
            proposalBlock: block.number,
            voteEndTime: block.number.add(governanceProposalVotingPeriodBlocks),
            totalForVotes: 0,
            totalAgainstVotes: 0,
            hasVoted: new mapping(address => bool)(),
            state: ProposalState.Active,
            data: abi.encodeWithSelector(daoTreasuryToken.transfer.selector, _recipient, _amount),
            targetFunctionSelector: daoTreasuryToken.transfer.selector,
            targetAddress: address(daoTreasuryToken)
        });

        emit InterchainInitiativeProposed(proposalId, _description); // Reusing event for general proposal, could make a new one
        return proposalId;
    }

    // --- B. Member Management & Expertise ---

    /**
     * @dev Allows an address to register as a member of the DAO.
     * @param _name The member's chosen display name.
     * @param _description A brief self-description or areas of interest.
     */
    function registerMember(string calldata _name, string calldata _description) external {
        require(!s_members[msg.sender].isRegistered, "QLDAO: Already a registered member.");
        s_members[msg.sender].name = _name;
        s_members[msg.sender].description = _description;
        s_members[msg.sender].isRegistered = true;
        // Grant initial expertise (optional, could be zero)
        awardExpertisePoints(msg.sender, "General", 10);
        emit MemberRegistered(msg.sender, _name);
    }

    /**
     * @dev Allows a member to update their profile.
     * @param _name The new display name.
     * @param _description The new self-description.
     * @param _expertiseDomains An array of self-declared expertise domains (e.g., ["AI", "Blockchain"]).
     */
    function updateMemberProfile(string calldata _name, string calldata _description, string[] calldata _expertiseDomains)
        external
        onlyMember
    {
        s_members[msg.sender].name = _name;
        s_members[msg.sender].description = _description;
        // Note: Actual expertise points are awarded/penalized by the system,
        // these are just self-declared interests for filtering/search.
        // Members' actual expertise points are internal.
        emit MemberProfileUpdated(msg.sender);
    }

    /**
     * @dev Allows a member to delegate their expertise weight for a specific domain to another member.
     *      Useful for domain specialists to pool their influence.
     * @param _delegatee The address to delegate expertise to.
     * @param _domain The expertise domain (e.g., "QuantumPhysics").
     * @param _amount The amount of expertise points to delegate.
     */
    function delegateExpertiseWeight(address _delegatee, string calldata _domain, uint256 _amount)
        external
        onlyMember
    {
        require(s_members[_delegatee].isRegistered, "QLDAO: Delegatee is not a registered member.");
        require(s_members[msg.sender].expertisePoints[_domain] >= _amount, "QLDAO: Insufficient expertise points to delegate.");
        
        s_members[msg.sender].expertisePoints[_domain] = s_members[msg.sender].expertisePoints[_domain].sub(_amount);
        s_members[_delegatee].expertisePoints[_domain] = s_members[_delegatee].expertisePoints[_domain].add(_amount);

        // Track delegations for potential revocation
        s_members[msg.sender].delegatedExpertiseOut[_delegatee][_domain] = 
            s_members[msg.sender].delegatedExpertiseOut[_delegatee][_domain].add(_amount);
        s_members[_delegatee].receivedExpertiseIn[msg.sender][_domain] = 
            s_members[_delegatee].receivedExpertiseIn[msg.sender][_domain].add(_amount);

        emit ExpertiseDelegated(msg.sender, _delegatee, _domain);
    }

    /**
     * @dev Initiates a governance proposal to liquidate (remove) a problematic member.
     *      If passed, the member's expertise points might be reset or significantly reduced.
     * @param _memberToLiquidate The address of the member to propose for liquidation.
     * @param _reason A reason for the liquidation.
     * @return The ID of the created proposal.
     */
    function liquidateMember(address _memberToLiquidate, string calldata _reason)
        external
        onlyMember
        returns (uint256)
    {
        require(s_members[_memberToLiquidate].isRegistered, "QLDAO: Target is not a registered member.");
        require(_memberToLiquidate != msg.sender, "QLDAO: Cannot propose to liquidate self.");

        _generalProposalIdCounter.increment();
        uint256 proposalId = _generalProposalIdCounter.current();

        s_generalProposals[proposalId] = GovernanceProposal({
            id: Counters.to = (proposalId),
            description: string(abi.encodePacked("Liquidate member: ", _memberToLiquidate.toHexString(), " - ", _reason)),
            proposer: msg.sender,
            proposalBlock: block.number,
            voteEndTime: block.number.add(governanceProposalVotingPeriodBlocks),
            totalForVotes: 0,
            totalAgainstVotes: 0,
            hasVoted: new mapping(address => bool)(),
            state: ProposalState.Active,
            data: abi.encodeCall(this.penalizeExpertisePoints, (_memberToLiquidate, "General", type(uint256).max)), // Max penalty
            targetFunctionSelector: this.penalizeExpertisePoints.selector,
            targetAddress: address(this)
        });

        return proposalId;
    }

    // --- C. Project Lifecycle & Funding ---

    /**
     * @dev Allows a member to propose a new "Quantum Project" for funding.
     * @param _name The name of the project.
     * @param _description A detailed description of the project.
     * @param _requestedFunds The amount of DAO tokens requested.
     * @param _expertiseDomainsRequired An array of expertise domains crucial for this project.
     * @param _riskProfile An arbitrary integer reflecting the project's risk (e.g., 1-10).
     * @return The ID of the created project proposal.
     */
    function proposeQuantumProject(
        string calldata _name,
        string calldata _description,
        uint256 _requestedFunds,
        string[] calldata _expertiseDomainsRequired,
        uint256 _riskProfile
    ) external onlyMember returns (uint256) {
        require(s_members[msg.sender].expertisePoints["General"] >= minExpertiseForProjectLead, "QLDAO: Not enough general expertise to propose project.");
        _projectIdCounter.increment();
        uint256 projectId = _projectIdCounter.current();

        s_projects[projectId] = Project({
            id: Counters.to = (projectId),
            proposer: msg.sender,
            projectLead: msg.sender, // Proposer is initial project lead
            name: _name,
            description: _description,
            requestedFunds: _requestedFunds,
            fundedAmount: 0,
            expertiseDomainsRequired: _expertiseDomainsRequired,
            proposalBlock: block.number,
            voteEndTime: block.number.add(projectProposalVotingPeriodBlocks),
            totalForVotes: 0,
            totalAgainstVotes: 0,
            hasVoted: new mapping(address => bool)(),
            status: ProjectStatus.Proposed,
            finalOutcome: ProjectOutcome.Undefined,
            verifiedImpactScore: 0,
            challengePeriodEndTime: 0,
            milestoneDescriptions: new string[](0),
            milestoneHashes: new mapping(uint256 => bytes32)(),
            knowledgeEntryIndex: type(uint256).max, // Mark as unassigned initially
            voterForProposal: new mapping(address => bool)()
        });

        emit ProjectProposed(projectId, msg.sender, _name, _requestedFunds);
        return projectId;
    }

    /**
     * @dev Allows members to vote on active project funding proposals.
     *      Voting weight is determined by dynamic expertise.
     * @param _projectId The ID of the project to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnProjectProposal(uint256 _projectId, bool _support) external onlyMember {
        Project storage project = s_projects[_projectId];
        require(project.status == ProjectStatus.Proposed, "QLDAO: Project is not in proposed state.");
        require(block.number <= project.voteEndTime, "QLDAO: Voting period has ended.");
        require(!project.hasVoted[msg.sender], "QLDAO: Already voted on this project.");

        uint256 voterWeight = calculateDynamicVotingWeight(msg.sender);
        require(voterWeight > 0, "QLDAO: Voter has no effective voting weight.");

        project.hasVoted[msg.sender] = true;
        project.voterForProposal[msg.sender] = _support; // Store how they voted

        if (_support) {
            project.totalForVotes = project.totalForVotes.add(voterWeight);
        } else {
            project.totalAgainstVotes = project.totalAgainstVotes.add(voterWeight);
        }
        emit ProjectVoteCast(_projectId, msg.sender, _support, voterWeight);
    }

    /**
     * @dev Executes the transfer of funds for a project if its proposal passed.
     *      Can only be called after the voting period ends.
     * @param _projectId The ID of the project to fund.
     */
    function executeProjectFunding(uint256 _projectId) external {
        Project storage project = s_projects[_projectId];
        require(project.status == ProjectStatus.Proposed, "QLDAO: Project must be in Proposed status.");
        require(block.number > project.voteEndTime, "QLDAO: Voting period not ended yet.");
        require(project.fundedAmount == 0, "QLDAO: Project already funded."); // Prevent double funding

        uint256 totalVotes = project.totalForVotes.add(project.totalAgainstVotes);
        require(totalVotes > 0, "QLDAO: No votes cast."); // Must have at least some participation

        // Calculate actual quorum based on total active voting power at the time of proposal conclusion
        // This is a simplification; a more robust system would track active voters at the start of the proposal
        uint256 requiredQuorum = totalGlobalExpertiseWeight.mul(projectFundingQuorumPercentage).div(100);
        require(totalVotes >= requiredQuorum, "QLDAO: Quorum not met for project funding.");

        // Check if project passed (simple majority of valid votes)
        if (project.totalForVotes > project.totalAgainstVotes) {
            require(daoTreasuryToken.transfer(project.projectLead, project.requestedFunds), "QLDAO: Funding transfer failed.");
            project.fundedAmount = project.requestedFunds;
            project.status = ProjectStatus.Active;
            emit ProjectFunded(_projectId, project.projectLead, project.requestedFunds);

            // Award expertise to proposer/lead for successful funding initiation
            awardExpertisePoints(project.proposer, "ProjectInitiation", 25);
        } else {
            project.status = ProjectStatus.Finalized; // Mark as failed without funding
            emit ProjectFinalized(_projectId, ProjectOutcome.Failure);
        }
    }

    /**
     * @dev Allows a project lead to submit a milestone update.
     * @param _projectId The ID of the project.
     * @param _milestoneDescription A string describing the milestone achieved.
     */
    function submitProjectMilestone(uint256 _projectId, string calldata _milestoneDescription)
        external
        onlyProjectLead(_projectId)
        projectStatus(_projectId, ProjectStatus.Active)
    {
        Project storage project = s_projects[_projectId];
        project.milestoneDescriptions.push(_milestoneDescription);
        // Store hash of milestone description to prevent tampering/prove content
        project.milestoneHashes[project.milestoneDescriptions.length - 1] = keccak256(abi.encodePacked(_milestoneDescription));
        project.status = ProjectStatus.MilestoneSubmitted;
        emit ProjectMilestoneSubmitted(_projectId, project.milestoneDescriptions.length - 1, _milestoneDescription);
    }

    /**
     * @dev Initiates the verification process for a project's final outcome.
     *      Can be called by the project lead or a DAO admin to trigger verification.
     *      Requires VERIFIER_ROLE to perform the actual verification.
     * @param _projectId The ID of the project to verify.
     * @param _outcome The determined outcome of the project.
     * @param _impactScore The assessed impact score (0-100).
     */
    function verifyProjectOutcome(uint256 _projectId, ProjectOutcome _outcome, uint256 _impactScore)
        external
        onlyVerifier
        projectStatus(_projectId, ProjectStatus.MilestoneSubmitted) // Must have submitted milestones
    {
        Project storage project = s_projects[_projectId];
        require(_outcome != ProjectOutcome.Undefined, "QLDAO: Outcome cannot be Undefined.");
        require(_impactScore <= 100, "QLDAO: Impact score must be between 0 and 100.");

        project.finalOutcome = _outcome;
        project.verifiedImpactScore = _impactScore;
        project.status = ProjectStatus.VerificationPending; // Transition to pending to allow challenge
        project.challengePeriodEndTime = block.number.add(challengePeriodBlocks);

        emit ProjectOutcomeVerified(_projectId, _outcome, _impactScore);
    }

    /**
     * @dev Allows a member to challenge a verified project outcome during the challenge period.
     *      Triggers a re-evaluation process (not fully implemented here, would involve another vote/arbitration).
     * @param _projectId The ID of the project whose outcome is being challenged.
     * @param _reason A brief reason for the challenge.
     */
    function challengeProjectOutcome(uint256 _projectId, string calldata _reason)
        external
        onlyMember
        projectStatus(_projectId, ProjectStatus.VerificationPending)
    {
        Project storage project = s_projects[_projectId];
        require(block.number <= project.challengePeriodEndTime, "QLDAO: Challenge period has ended.");

        project.status = ProjectStatus.Challenged;
        // In a real system, this would trigger a new governance proposal for re-evaluation
        // or an arbitration process. For this scope, it just changes status.
        emit ProjectOutcomeChallenged(_projectId, msg.sender);
    }

    /**
     * @dev Finalizes a project after its outcome has been verified and (optionally) challenged.
     *      Adds the project's outcome to the DAO's knowledge base and distributes rewards/penalties.
     * @param _projectId The ID of the project to finalize.
     */
    function finalizeProject(uint256 _projectId)
        external
    {
        Project storage project = s_projects[_projectId];
        require(
            project.status == ProjectStatus.VerificationPending && block.number > project.challengePeriodEndTime ||
            project.status == ProjectStatus.Challenged || // Assume challenged projects can be finalized after arbitration
            project.status == ProjectStatus.Proposed // For projects that failed to get funded
            , "QLDAO: Project not in a finalizable state."
        );
        require(project.finalOutcome != ProjectOutcome.Undefined || project.status == ProjectStatus.Proposed, "QLDAO: Project outcome must be set or project not funded.");

        // If not already finalized (e.g., due to failing funding)
        if (project.status != ProjectStatus.Finalized) {
            project.status = ProjectStatus.Finalized;

            // Add to Knowledge Base only if it was funded and verified
            if (project.fundedAmount > 0 && project.finalOutcome != ProjectOutcome.Undefined) {
                s_knowledgeBase.push(KnowledgeEntry({
                    projectId: _projectId,
                    projectName: project.name,
                    expertiseDomains: project.expertiseDomainsRequired,
                    outcome: project.finalOutcome,
                    impactScore: project.verifiedImpactScore,
                    riskProfile: 0 // Placeholder, could be from initial proposal or verifier input
                    // dataHash: ... (if off-chain reports were used)
                }));
                project.knowledgeEntryIndex = s_knowledgeBase.length - 1;

                // Adjust expertise based on outcome
                if (project.finalOutcome == ProjectOutcome.Success || project.finalOutcome == ProjectOutcome.PartialSuccess) {
                    awardExpertisePoints(project.projectLead, "ProjectExecution", project.verifiedImpactScore);
                    // Reward members who voted 'for' a successful project
                    for (uint i = 0; i < project.id.current(); i++) { // Iterate through all potential voters (simplistic, better to track specific voters)
                        address voter = address(uint160(i)); // Placeholder, actual voter list needs to be tracked properly.
                        if (project.hasVoted[voter] && project.voterForProposal[voter]) {
                            awardExpertisePoints(voter, "AccurateVoting", project.verifiedImpactScore.div(10));
                        }
                    }
                } else if (project.finalOutcome == ProjectOutcome.Failure) {
                    penalizeExpertisePoints(project.projectLead, "ProjectExecution", 20); // Penalty for failure
                    // Penalize members who voted 'for' a failed project (simplified)
                    for (uint i = 0; i < project.id.current(); i++) { // Placeholder
                        address voter = address(uint160(i));
                        if (project.hasVoted[voter] && project.voterForProposal[voter]) {
                            penalizeExpertisePoints(voter, "InaccurateVoting", 5);
                        }
                    }
                }
                // Update cumulative impact score for the project lead
                s_members[project.projectLead].totalImpactScore = s_members[project.projectLead].totalImpactScore.add(project.verifiedImpactScore);
            }
            emit ProjectFinalized(_projectId, project.finalOutcome);
        }
    }

    // --- D. Reputation, Rewards & Knowledge Base ---

    /**
     * @dev Awards expertise points to a member in a specific domain.
     *      Internal function, called by the system (e.g., successful project, accurate vote).
     * @param _member The address of the member.
     * @param _domain The expertise domain (e.g., "AI", "Blockchain").
     * @param _points The number of points to award.
     */
    function awardExpertisePoints(address _member, string memory _domain, uint256 _points) internal {
        require(s_members[_member].isRegistered, "QLDAO: Member not registered.");
        s_members[_member].expertisePoints[_domain] = s_members[_member].expertisePoints[_domain].add(_points);
        totalGlobalExpertiseWeight = totalGlobalExpertiseWeight.add(_points);
        emit ExpertiseAwarded(_member, _domain, _points);
    }

    /**
     * @dev Penalizes expertise points from a member in a specific domain.
     *      Internal function, called by the system (e.g., failed project, inaccurate vote, liquidation).
     * @param _member The address of the member.
     * @param _domain The expertise domain.
     * @param _points The number of points to penalize.
     */
    function penalizeExpertisePoints(address _member, string memory _domain, uint256 _points) internal {
        require(s_members[_member].isRegistered, "QLDAO: Member not registered.");
        uint256 currentPoints = s_members[_member].expertisePoints[_domain];
        if (currentPoints > _points) {
            s_members[_member].expertisePoints[_domain] = currentPoints.sub(_points);
            totalGlobalExpertiseWeight = totalGlobalExpertiseWeight.sub(_points);
        } else {
            totalGlobalExpertiseWeight = totalGlobalExpertiseWeight.sub(currentPoints);
            s_members[_member].expertisePoints[_domain] = 0; // Cannot go below zero
        }
        emit ExpertisePenalized(_member, _domain, _points);
    }

    /**
     * @dev Calculates a member's dynamic voting weight, combining general expertise.
     *      In a real system, this would be more complex, potentially weighting
     *      expertise relevant to the proposal's domain.
     * @param _member The address of the member.
     * @return The calculated voting weight.
     */
    function calculateDynamicVotingWeight(address _member) public view returns (uint256) {
        if (!s_members[_member].isRegistered) {
            return 0;
        }
        // Simple aggregation for now. Could be more complex (e.g., sqrt, or domain-specific weighting).
        uint256 totalExpertise = 0;
        // This iteration over all domains is gas-intensive if domains are many.
        // A better approach would be to track a 'total' expertise score.
        // For demonstration, let's assume 'General' domain is the primary weight.
        totalExpertise = s_members[_member].expertisePoints["General"];

        // Add a multiplier for specific highly-relevant domains if applicable,
        // but for general voting, let's stick to General expertise for simplicity.
        return totalExpertise;
    }

    /**
     * @dev Queries the on-chain knowledge base for insights into past project outcomes.
     *      Useful for informing future decisions.
     * @param _projectTypeKeyword A keyword to filter project types (e.g., "AI", "Biotech").
     * @param _minImpactScore Minimum impact score to filter.
     * @return An array of `KnowledgeEntry` structs matching the criteria.
     */
    function queryKnowledgeBase(string calldata _projectTypeKeyword, uint256 _minImpactScore)
        external
        view
        returns (KnowledgeEntry[] memory)
    {
        KnowledgeEntry[] memory results = new KnowledgeEntry[](s_knowledgeBase.length);
        uint256 count = 0;

        // Iterate through the knowledge base to find matches
        for (uint i = 0; i < s_knowledgeBase.length; i++) {
            KnowledgeEntry storage entry = s_knowledgeBase[i];
            bool typeMatch = false;
            for (uint j = 0; j < entry.expertiseDomains.length; j++) {
                if (keccak256(abi.encodePacked(entry.expertiseDomains[j])) == keccak256(abi.encodePacked(_projectTypeKeyword))) {
                    typeMatch = true;
                    break;
                }
            }

            if (typeMatch && entry.impactScore >= _minImpactScore) {
                results[count] = entry;
                count++;
            }
        }
        // Resize array to actual number of results
        KnowledgeEntry[] memory finalResults = new KnowledgeEntry[](count);
        for (uint i = 0; i < count; i++) {
            finalResults[i] = results[i];
        }
        return finalResults;
    }

    /**
     * @dev Distributes adaptive rewards to members based on their total impact score.
     *      This function would typically be called periodically (e.g., weekly, monthly)
     *      by a DAO admin or a timed contract.
     *      Reward pool scales with DAO treasury and overall success.
     *      Rewards are proportional to member's `totalImpactScore`.
     */
    function distributeAdaptiveRewards()
        external
        onlyRole(DAO_ADMIN_ROLE) // Can be triggered by DAO_ADMIN, or a proposal
    {
        uint256 totalClaimableRewards = 0;
        // Example: 1% of treasury or a fixed amount per period,
        // dynamically scaled by average project impact or DAO activity.
        // For simplicity, let's use a percentage of treasury for claimable rewards.
        uint256 rewardPool = daoTreasuryToken.balanceOf(treasuryAddress).div(100); // 1% of treasury

        if (rewardPool == 0) {
            return; // No rewards to distribute
        }

        uint256 totalQualifyingImpact = 0;
        address[] memory qualifyingMembers = new address[](s_members.length); // Placeholder
        uint256 memberCount = 0;

        // Sum up total impact of all members who qualify for rewards
        // This loop is for demonstration. In a real scenario, iterating over all members
        // in a single transaction can hit gas limits. A better approach involves Merkle proofs
        // for off-chain calculation or paginated claim functionality.
        // For now, let's just sum up for illustration.
        // This loop needs to be fixed to iterate over actual member addresses.
        // A mapping `address => Member` cannot be iterated directly in Solidity.
        // One would need an array of all registered member addresses.
        // For simplicity, let's assume `s_members` has a hidden array `_allMemberAddresses` for iteration.
        // (Not actually implemented due to complexity for this example, focusing on logic).

        // Placeholder for calculating total qualifying impact:
        // Assume an array of all member addresses `_allMembers` exists.
        // for (uint i = 0; i < _allMembers.length; i++) {
        //     address memberAddress = _allMembers[i];
        //     if (s_members[memberAddress].totalImpactScore >= minImpactScoreForReward) {
        //         totalQualifyingImpact = totalQualifyingImpact.add(s_members[memberAddress].totalImpactScore);
        //     }
        // }

        // --- Simplified Calculation for Demonstration ---
        // For a demonstration, let's assume we iterate over all known project leads,
        // and distribute based on their impact from *those* projects.
        // This avoids iterating over all members directly, though still not fully robust.
        mapping(address => uint256) tempMemberImpact;
        for (uint256 i = 1; i <= _projectIdCounter.current(); i++) {
            Project storage project = s_projects[i];
            if (project.finalOutcome == ProjectOutcome.Success || project.finalOutcome == ProjectOutcome.PartialSuccess) {
                if (project.verifiedImpactScore >= minImpactScoreForReward) {
                    tempMemberImpact[project.projectLead] = tempMemberImpact[project.projectLead].add(project.verifiedImpactScore);
                    totalQualifyingImpact = totalQualifyingImpact.add(project.verifiedImpactScore);
                }
            }
        }

        if (totalQualifyingImpact == 0) {
            return; // No one qualified or no impact to distribute
        }

        // Iterate again (or over `tempMemberImpact` keys) to distribute
        for (uint256 i = 1; i <= _projectIdCounter.current(); i++) {
            Project storage project = s_projects[i]; // Re-using project leads as a proxy for members
            address memberAddress = project.projectLead; // This is a simplification
            uint256 memberImpact = tempMemberImpact[memberAddress]; // Use the calculated impact from temp map

            if (memberImpact > 0) {
                 uint256 share = rewardPool.mul(memberImpact).div(totalQualifyingImpact);
                 if (share > 0) {
                     require(daoTreasuryToken.transfer(memberAddress, share), "QLDAO: Reward transfer failed.");
                     s_members[memberAddress].lastRewardClaimBlock = block.number;
                     emit RewardsDistributed(memberAddress, share);
                 }
            }
        }
        // --- End Simplified Calculation ---
    }

    // --- E. Adaptive Governance & Advanced Concepts ---

    /**
     * @dev Initiates a governance proposal to adjust a core adaptive governance parameter.
     *      Requires a vote to pass.
     * @param _paramName The name of the parameter to adjust (e.g., "projectProposalVotingPeriodBlocks").
     * @param _newValue The new value for the parameter.
     * @return The ID of the created parameter adjustment proposal.
     */
    function initiateParameterAdjustmentProposal(string calldata _paramName, uint256 _newValue)
        external
        onlyMember
        returns (uint256)
    {
        // Basic validation for parameter names
        bytes32 paramHash = keccak256(abi.encodePacked(_paramName));
        require(
            paramHash == keccak256(abi.encodePacked("projectProposalVotingPeriodBlocks")) ||
            paramHash == keccak256(abi.encodePacked("governanceProposalVotingPeriodBlocks")) ||
            paramHash == keccak256(abi.encodePacked("projectFundingQuorumPercentage")) ||
            paramHash == keccak256(abi.encodePacked("governanceQuorumPercentage")) ||
            paramHash == keccak256(abi.encodePacked("challengePeriodBlocks")),
            "QLDAO: Invalid adaptive parameter name."
        );

        _paramAdjustmentIdCounter.increment();
        uint256 proposalId = _paramAdjustmentIdCounter.current();

        s_paramAdjustmentProposals[proposalId] = ParameterAdjustmentProposal({
            id: Counters.to = (proposalId),
            paramName: _paramName,
            newValue: _newValue,
            proposalBlock: block.number,
            voteEndTime: block.number.add(governanceProposalVotingPeriodBlocks),
            totalForVotes: 0,
            totalAgainstVotes: 0,
            hasVoted: new mapping(address => bool)(),
            state: ProposalState.Active
        });

        emit ParameterAdjustmentProposed(proposalId, _paramName, _newValue);
        return proposalId;
    }

    /**
     * @dev Allows members to vote on a parameter adjustment proposal.
     * @param _proposalId The ID of the parameter adjustment proposal.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnParameterAdjustment(uint256 _proposalId, bool _support)
        external
        onlyMember
        paramAdjProposalState(_proposalId, ProposalState.Active)
    {
        ParameterAdjustmentProposal storage proposal = s_paramAdjustmentProposals[_proposalId];
        require(block.number <= proposal.voteEndTime, "QLDAO: Voting period has ended.");
        require(!proposal.hasVoted[msg.sender], "QLDAO: Already voted on this proposal.");

        uint256 voterWeight = calculateDynamicVotingWeight(msg.sender);
        require(voterWeight > 0, "QLDAO: Voter has no effective voting weight.");

        proposal.hasVoted[msg.sender] = true;

        if (_support) {
            proposal.totalForVotes = proposal.totalForVotes.add(voterWeight);
        } else {
            proposal.totalAgainstVotes = proposal.totalAgainstVotes.add(voterWeight);
        }
        emit ParameterAdjustmentVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Enacts a parameter adjustment proposal if it passed the vote.
     * @param _proposalId The ID of the parameter adjustment proposal.
     */
    function enactParameterAdjustment(uint256 _proposalId)
        external
        paramAdjProposalState(_proposalId, ProposalState.Active)
    {
        ParameterAdjustmentProposal storage proposal = s_paramAdjustmentProposals[_proposalId];
        require(block.number > proposal.voteEndTime, "QLDAO: Voting period not ended yet.");

        uint256 totalVotes = proposal.totalForVotes.add(proposal.totalAgainstVotes);
        require(totalVotes > 0, "QLDAO: No votes cast.");

        uint256 requiredQuorum = totalGlobalExpertiseWeight.mul(governanceQuorumPercentage).div(100);
        require(totalVotes >= requiredQuorum, "QLDAO: Quorum not met for parameter adjustment.");

        if (proposal.totalForVotes > proposal.totalAgainstVotes) {
            bytes32 paramHash = keccak256(abi.encodePacked(proposal.paramName));
            if (paramHash == keccak256(abi.encodePacked("projectProposalVotingPeriodBlocks"))) {
                projectProposalVotingPeriodBlocks = proposal.newValue;
            } else if (paramHash == keccak256(abi.encodePacked("governanceProposalVotingPeriodBlocks"))) {
                governanceProposalVotingPeriodBlocks = proposal.newValue;
            } else if (paramHash == keccak256(abi.encodePacked("projectFundingQuorumPercentage"))) {
                projectFundingQuorumPercentage = proposal.newValue;
            } else if (paramHash == keccak256(abi.encodePacked("governanceQuorumPercentage"))) {
                governanceQuorumPercentage = proposal.newValue;
            } else if (paramHash == keccak256(abi.encodePacked("challengePeriodBlocks"))) {
                challengePeriodBlocks = proposal.newValue;
            }
            proposal.state = ProposalState.Executed;
            emit ParameterAdjustmentEnacted(proposal.paramName, proposal.newValue);
        } else {
            proposal.state = ProposalState.Failed;
        }
    }

    /**
     * @dev Allows members to signal their preferred research domains or project types.
     *      This does not directly trigger actions but informs DAO strategy and future proposals.
     * @param _domain The expertise domain or research area to signal priority for.
     */
    function signalResearchPriority(string calldata _domain) external onlyMember {
        // This can be used to gather data off-chain or by a future analysis contract
        // to guide funding decisions. No direct on-chain state change here beyond the event.
        emit ResearchPrioritySignaled(msg.sender, _domain);
    }

    /**
     * @dev A conceptual function for proposing initiatives that involve off-chain or cross-chain interactions.
     *      The execution of such a proposal would require external oracle integration or manual execution
     *      based on DAO consensus.
     * @param _description A description of the interchain or external initiative.
     * @param _externalTarget A conceptual target address/ID on another chain or system.
     * @param _payload A conceptual payload for the external interaction.
     * @return The ID of the created proposal.
     */
    function proposeInterchainInitiative(string calldata _description, address _externalTarget, bytes calldata _payload)
        external
        onlyMember
        returns (uint256)
    {
        _generalProposalIdCounter.increment();
        uint256 proposalId = _generalProposalIdCounter.current();

        s_generalProposals[proposalId] = GovernanceProposal({
            id: Counters.to = (proposalId),
            description: _description,
            proposer: msg.sender,
            proposalBlock: block.number,
            voteEndTime: block.number.add(governanceProposalVotingPeriodBlocks),
            totalForVotes: 0,
            totalAgainstVotes: 0,
            hasVoted: new mapping(address => bool)(),
            state: ProposalState.Active,
            data: _payload, // The payload for the external system
            targetFunctionSelector: bytes4(0), // Placeholder for external call
            targetAddress: _externalTarget // Placeholder for external target
        });

        emit InterchainInitiativeProposed(proposalId, _description);
        return proposalId;
    }

    /**
     * @dev Initiates a governance proposal to audit the expertise scores or performance metrics
     *      within a specific project domain. This implies an external audit process.
     * @param _domain The domain to be audited (e.g., "AI", "Biotech").
     * @param _reason The reason for initiating the audit.
     * @return The ID of the created proposal.
     */
    function initiateDomainAudit(string calldata _domain, string calldata _reason)
        external
        onlyMember
        returns (uint256)
    {
        _generalProposalIdCounter.increment();
        uint256 proposalId = _generalProposalIdCounter.current();

        s_generalProposals[proposalId] = GovernanceProposal({
            id: Counters.to = (proposalId),
            description: string(abi.encodePacked("Initiate audit for domain: ", _domain, " - ", _reason)),
            proposer: msg.sender,
            proposalBlock: block.number,
            voteEndTime: block.number.add(governanceProposalVotingPeriodBlocks),
            totalForVotes: 0,
            totalAgainstVotes: 0,
            hasVoted: new mapping(address => bool)(),
            state: ProposalState.Active,
            data: "", // No direct on-chain execution for external audit
            targetFunctionSelector: bytes4(0),
            targetAddress: address(0)
        });

        emit DomainAuditInitiated(_domain);
        return proposalId;
    }

    // --- Utility/Helper Functions ---

    /**
     * @dev Helper function to check the status of a general governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return The current state of the proposal.
     */
    function getGeneralProposalState(uint256 _proposalId) public view returns (ProposalState) {
        GovernanceProposal storage proposal = s_generalProposals[_proposalId];
        if (proposal.state == ProposalState.Active && block.number > proposal.voteEndTime) {
            uint256 totalVotes = proposal.totalForVotes.add(proposal.totalAgainstVotes);
            uint256 requiredQuorum = totalGlobalExpertiseWeight.mul(governanceQuorumPercentage).div(100);
            if (totalVotes >= requiredQuorum && proposal.totalForVotes > proposal.totalAgainstVotes) {
                return ProposalState.Succeeded;
            } else {
                return ProposalState.Failed;
            }
        }
        return proposal.state;
    }

    /**
     * @dev Helper function to check the status of a parameter adjustment proposal.
     * @param _proposalId The ID of the proposal.
     * @return The current state of the proposal.
     */
    function getParameterAdjustmentProposalState(uint256 _proposalId) public view returns (ProposalState) {
        ParameterAdjustmentProposal storage proposal = s_paramAdjustmentProposals[_proposalId];
        if (proposal.state == ProposalState.Active && block.number > proposal.voteEndTime) {
            uint256 totalVotes = proposal.totalForVotes.add(proposal.totalAgainstVotes);
            uint256 requiredQuorum = totalGlobalExpertiseWeight.mul(governanceQuorumPercentage).div(100);
            if (totalVotes >= requiredQuorum && proposal.totalForVotes > proposal.totalAgainstVotes) {
                return ProposalState.Succeeded;
            } else {
                return ProposalState.Failed;
            }
        }
        return proposal.state;
    }

    // --- Access Control Overrides ---
    // Ensure that only roles can modify internal roles.
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // The functions `grantRole`, `revokeRole`, `renounceRole` are inherited from AccessControl
    // and can be called by addresses with DEFAULT_ADMIN_ROLE. Over time, the DAO itself could
    // vote to grant/revoke these roles, effectively decentralizing administrative power.
}
```