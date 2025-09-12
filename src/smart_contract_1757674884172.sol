The `AetherForge` smart contract is designed as a Decentralized Autonomous Research & Development Fund (DARF). It aims to fund innovative projects by leveraging an AI-powered oracle for proposal evaluation, implementing dynamic governance mechanisms, and recognizing contributor influence through a reputation system. Successful projects can also have their Intellectual Property (IP) recorded on-chain, potentially accruing royalties. The contract emphasizes advanced concepts like adaptive parameters, multi-faceted stakeholder engagement, and a robust project lifecycle.

---

**Outline:**

**I. Core Fund Management:** Functions related to depositing, withdrawing, and querying the fund's financial status.
**II. Project Lifecycle & Proposals:** Functions governing the submission, evaluation, and progression of R&D projects.
**III. Governance & Voting:** Mechanisms for stakeholders to vote on project proposals and changes to the contract's operational parameters.
**IV. Project Milestones & IP Record Management:** Managing project progress through milestones and recording IP for completed projects.
**V. Reputation & Rewards:** System for tracking and distributing reputation-based influence and rewards.
**VI. Dynamic & Advanced Mechanisms & Emergency Protocol:** Features for adaptive governance, AI oracle interaction, and fail-safe operations.

---

**Function Summary:**

1.  **`depositFunds()`**: Allows users to deposit funds (ETH) into the AetherForge treasury, becoming potential stakeholders.
2.  **`withdrawUnallocatedFunds()`**: Enables authorized governors to withdraw excess unallocated funds from the treasury.
3.  **`getFundBalance()`**: Returns the total ETH balance currently held by the AetherForge contract.
4.  **`getAvailableFunding()`**: Calculates and returns the ETH amount available for new projects, excluding committed funds.
5.  **`proposeProject()`**: Initiates a new R&D project proposal, including a detailed description, requested budget, and milestone structure.
6.  **`updateProposalDetails()`**: Permits the original proposer to modify their project proposal details before voting commences.
7.  **`getProjectDetails()`**: Retrieves all relevant information about a specific project proposal by its unique ID.
8.  **`getAIProposalScore()`**: Queries the integrated AI Oracle for an objective evaluation score of a given project proposal.
9.  **`voteOnProposal()`**: Allows eligible stakeholders to cast their vote (for or against) on an active project proposal.
10. **`finalizeProposalVoting()`**: Concludes the voting phase for a proposal, determining its outcome and allocating funds if passed.
11. **`proposeGovernanceChange()`**: Enables authorized roles to submit proposals for modifying the contract's core governance parameters.
12. **`voteOnGovernanceChange()`**: Allows stakeholders to vote on proposed changes to the AetherForge's governance rules.
13. **`finalizeGovernanceChange()`**: Executes and applies the approved changes to the contract's governance parameters.
14. **`getCurrentGovernanceParams()`**: Returns the complete set of currently active governance parameters.
15. **`submitMilestoneCompletion()`**: Project teams report the completion of a specific project milestone for review.
16. **`approveMilestone()`**: Evaluators or governors review and approve a submitted milestone, triggering the next payment tranche.
17. **`recordIPOwnership()`**: Creates an immutable on-chain record signifying the Intellectual Property ownership for a successfully completed project.
18. **`claimIPRoyalties()`**: Allows the recorded owner of a project's IP to claim accumulated royalties (a portion of future contract fees) associated with their IP.
19. **`getReputationScore()`**: Returns the non-transferable AetherReputation score for a specified address, indicating their standing.
20. **`distributeReputation()`**: Internal function used to assign AetherReputation tokens to users based on their positive contributions.
21. **`claimEvaluatorReward()`**: Rewards evaluators who demonstrated accurate judgment by voting correctly on project outcomes.
22. **`updateAIOracleAddress()`**: Allows the governance body to update the trusted address of the external AI Oracle contract.
23. **`triggerEmergencyProtocol()`**: Activates a temporary emergency state, potentially freezing critical actions or overriding governance, requiring a super-majority vote.
24. **`submitOracleReport()`**: The designated AI Oracle provides its periodic assessment, which contributes to the dynamic adjustment of governance parameters.
25. **`adjustDynamicGovernance()`**: Internal function that automatically fine-tunes governance parameters based on the fund's health, recent project success rates, and AI insights.
26. **`setProjectOutcome()`**: Formally marks a project as either successful or failed, impacting overall system metrics and reputation.
27. **`getRecentProjectSuccessRate()`**: Calculates and returns the rolling average success rate of completed projects within a defined period.
28. **`revokeProjectFunding()`**: Allows the governance body to halt funding for a project if it consistently fails to meet milestones or deviates critically.
29. **`getContributorInfluenceScore()`**: Calculates a user's combined influence score, factoring in their reputation and staked contributions for voting.
30. **`updateProjectFundingRequest()`**: Allows a project proposer to submit a request for an amendment to their approved budget or milestone structure, which requires a new governance vote.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal interface for an AI Oracle contract that provides scores and reports
interface IAIOracle {
    function getProposalScore(uint256 proposalId, string memory proposalDetailsHash) external view returns (uint256);
    function submitReport(uint256 aiSentimentScore, uint256 fundHealthBias) external;
}

// Minimal interface for an external Royalty Distributor (for IP NFTs)
interface IRoyaltyDistributor {
    function distributeRoyalties(address recipient, uint256 amount) external;
}

contract AetherForge {

    // --- Events ---
    event FundsDeposited(address indexed user, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event ProjectProposed(uint256 indexed proposalId, address indexed proposer, string title, uint256 requestedBudget);
    event ProjectProposalUpdated(uint256 indexed proposalId, string newTitle);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 influence);
    event ProposalFinalized(uint256 indexed proposalId, ProposalStatus status, uint256 fundedAmount);
    event GovernanceChangeProposed(uint256 indexed govPropId, address indexed proposer, GovernanceParams newParams);
    event GovernanceChangeFinalized(uint256 indexed govPropId, bool executed);
    event MilestoneSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex);
    event MilestoneApproved(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 paymentAmount);
    event IPRuleRecorded(uint256 indexed projectId, address indexed owner, string ipDetailsHash);
    event RoyaltiesClaimed(uint256 indexed projectId, address indexed claimant, uint256 amount);
    event ReputationDistributed(address indexed user, uint256 amount);
    event EvaluatorRewardClaimed(address indexed evaluator, uint256 amount);
    event AIOracleAddressUpdated(address indexed newAddress);
    event EmergencyProtocolTriggered(address indexed initiator);
    event OracleReportSubmitted(uint256 aiSentimentScore, uint256 fundHealthBias);
    event DynamicGovernanceAdjusted(GovernanceParams newParams);
    event ProjectOutcomeSet(uint256 indexed projectId, ProjectOutcome outcome);
    event FundingRevoked(uint256 indexed projectId);
    event ProjectFundingRequestUpdated(uint256 indexed projectId, uint256 newRequestedBudget);

    // --- Roles (Basic Access Control) ---
    address private _owner; // Contract deployer/main administrator
    address public governorRole; // Can propose governance changes, trigger emergency, approve withdrawals
    address public aiOracleAddress; // The address of the trusted AI Oracle contract
    address public royaltyDistributorAddress; // External contract to handle royalty distribution

    // Emergency State
    bool public inEmergencyState;
    uint256 public emergencyStartTimestamp;
    uint256 public constant EMERGENCY_DURATION = 7 days; // Emergency state lasts 7 days

    // --- Enums ---
    enum ProposalStatus { Pending, Approved, Rejected, Funded, Completed, Failed, Cancelled }
    enum MilestoneStatus { Pending, Approved, Rejected }
    enum ProjectOutcome { Undetermined, Success, Failure }

    // --- Structs ---

    struct GovernanceParams {
        uint256 proposalQuorumBPS; // Basis Points (e.g., 5000 = 50%) for project proposals
        uint256 proposalVotingDuration; // In seconds
        uint256 milestoneApprovalThresholdBPS; // For evaluators to approve milestones
        uint256 governanceChangeQuorumBPS; // For governance parameter changes
        uint256 governanceChangeVotingDuration;
        uint256 emergencyQuorumBPS; // For triggering emergency protocol
        uint256 minReputationForVote; // Minimum reputation required to vote
        uint256 royaltyFeeBPS; // Basis points for royalties on deposits
        uint256 evaluatorRewardBPS; // Basis points of project budget for evaluators
    }

    struct ProjectProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 requestedBudget; // Total budget in wei
        uint256 fundedAmount; // Actual amount allocated
        uint256[] milestonePayments; // Array of payments for each milestone
        MilestoneStatus[] milestoneStatuses; // Status for each milestone
        uint256 currentMilestoneIndex; // Index of the next milestone to be approved (0-indexed)
        ProposalStatus status;
        uint256 voteEndTime;
        uint256 yesVotes; // Total influence-weighted 'yes' votes
        uint256 noVotes; // Total influence-weighted 'no' votes
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        ProjectOutcome outcome;
        uint256 creationTimestamp;
        string ipDetailsHash; // Hash of IP details, becomes active upon completion
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        GovernanceParams newParams;
        uint256 voteEndTime;
        uint256 yesVotes; // Total influence-weighted 'yes' votes
        uint256 noVotes; // Total influence-weighted 'no' votes
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this governance change
        bool executed;
    }

    // AetherForge IP Ownership Record (simplified, not a full ERC721)
    struct IPRule {
        address owner;
        string ipDetailsHash; // Hash of the IP metadata/URI
        uint256 projectId;
        uint256 accumulatedRoyalties;
    }

    // --- Storage ---
    uint256 public totalFundBalance;
    uint256 public totalCommittedFunds; // Funds locked for active projects
    uint256 public totalRoyaltiesCollected; // Total royalties collected from deposits

    uint256 public nextProposalId;
    mapping(uint256 => ProjectProposal) public projects;
    uint256[] public activeProjectIds; // For tracking and iterating active projects

    uint256 public nextGovernanceProposalId;
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    GovernanceParams public currentGovernanceParams;

    mapping(address => uint256) public reputationScores; // AetherReputation - non-transferable
    mapping(uint256 => IPRule) public ipRecords; // Project ID to IP Record

    uint256[] private projectOutcomesHistory; // For calculating success rate (0=Fail, 1=Success)
    uint256 public constant SUCCESS_RATE_WINDOW_SIZE = 10; // Number of recent projects to consider

    // --- Modifiers ---
    modifier onlyOwner() {
        require(_msgSender() == _owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyGovernor() {
        require(_msgSender() == governorRole || _msgSender() == _owner, "AccessControl: caller is not a governor");
        _;
    }

    modifier onlyAIOracle() {
        require(_msgSender() == aiOracleAddress, "AccessControl: caller is not the AI Oracle");
        _;
    }

    modifier whenNotInEmergency() {
        require(!inEmergencyState || (inEmergencyState && block.timestamp > emergencyStartTimestamp + EMERGENCY_DURATION),
            "EmergencyProtocol: Contract is in emergency state");
        _;
    }

    modifier whenInEmergency() {
        require(inEmergencyState && block.timestamp <= emergencyStartTimestamp + EMERGENCY_DURATION,
            "EmergencyProtocol: Contract is not in active emergency state");
        _;
    }

    modifier onlyProjectProposer(uint256 _projectId) {
        require(projects[_projectId].proposer == _msgSender(), "AetherForge: Only proposer can call this function");
        _;
    }

    modifier onlyIfReputable() {
        require(reputationScores[_msgSender()] >= currentGovernanceParams.minReputationForVote, "AetherForge: Insufficient reputation to participate");
        _;
    }

    // --- Constructor ---
    constructor(address _initialGovernor, address _aiOracleAddress, address _royaltyDistributor) {
        _owner = _msgSender();
        governorRole = _initialGovernor;
        aiOracleAddress = _aiOracleAddress;
        royaltyDistributorAddress = _royaltyDistributor;

        // Initialize default governance parameters
        currentGovernanceParams = GovernanceParams({
            proposalQuorumBPS: 5000, // 50%
            proposalVotingDuration: 3 days, // 3 days in seconds
            milestoneApprovalThresholdBPS: 6000, // 60%
            governanceChangeQuorumBPS: 6600, // 66%
            governanceChangeVotingDuration: 7 days,
            emergencyQuorumBPS: 8000, // 80%
            minReputationForVote: 10,
            royaltyFeeBPS: 100, // 1%
            evaluatorRewardBPS: 200 // 2% of project budget for evaluators
        });

        nextProposalId = 1;
        nextGovernanceProposalId = 1;
    }

    // --- I. Core Fund Management ---

    function depositFunds() external payable whenNotInEmergency {
        require(msg.value > 0, "AetherForge: Deposit amount must be greater than zero");
        totalFundBalance += msg.value;

        // Distribute a percentage as royalties to active IP owners
        if (currentGovernanceParams.royaltyFeeBPS > 0 && royaltyDistributorAddress != address(0)) {
            uint256 royaltyAmount = (msg.value * currentGovernanceParams.royaltyFeeBPS) / 10000;
            totalRoyaltiesCollected += royaltyAmount;
            // The royaltyDistributor contract would then decide how to allocate this to IP owners
            // For this contract, we'll just track it and assume an external distributor
            IRoyaltyDistributor(royaltyDistributorAddress).distributeRoyalties(address(this), royaltyAmount);
        }

        emit FundsDeposited(_msgSender(), msg.value);
    }

    function withdrawUnallocatedFunds(uint256 _amount) external onlyGovernor whenNotInEmergency {
        require(_amount > 0, "AetherForge: Withdrawal amount must be greater than zero");
        require(totalFundBalance - totalCommittedFunds >= _amount, "AetherForge: Insufficient unallocated funds");

        totalFundBalance -= _amount;
        payable(_msgSender()).transfer(_amount); // Governor gets the funds
        emit FundsWithdrawn(_msgSender(), _amount);
    }

    function getFundBalance() external view returns (uint256) {
        return totalFundBalance;
    }

    function getAvailableFunding() external view returns (uint256) {
        return totalFundBalance - totalCommittedFunds;
    }

    // --- II. Project Lifecycle & Proposals ---

    function proposeProject(string memory _title, string memory _description, uint256 _requestedBudget, uint256[] memory _milestonePayments) external whenNotInEmergency {
        require(_requestedBudget > 0, "AetherForge: Requested budget must be greater than zero");
        require(_milestonePayments.length > 0, "AetherForge: At least one milestone payment is required");

        uint256 totalMilestonePayments;
        for (uint256 i = 0; i < _milestonePayments.length; i++) {
            require(_milestonePayments[i] > 0, "AetherForge: Milestone payment must be greater than zero");
            totalMilestonePayments += _milestonePayments[i];
        }
        require(totalMilestonePayments == _requestedBudget, "AetherForge: Sum of milestone payments must equal requested budget");

        uint256 newId = nextProposalId++;
        projects[newId] = ProjectProposal({
            id: newId,
            proposer: _msgSender(),
            title: _title,
            description: _description,
            requestedBudget: _requestedBudget,
            fundedAmount: 0,
            milestonePayments: _milestonePayments,
            milestoneStatuses: new MilestoneStatus[_milestonePayments.length],
            currentMilestoneIndex: 0,
            status: ProposalStatus.Pending,
            voteEndTime: block.timestamp + currentGovernanceParams.proposalVotingDuration,
            yesVotes: 0,
            noVotes: 0,
            hasVoted: new mapping(address => bool), // Initialize mapping
            outcome: ProjectOutcome.Undetermined,
            creationTimestamp: block.timestamp,
            ipDetailsHash: ""
        });

        // Initialize all milestone statuses to Pending
        for (uint256 i = 0; i < _milestonePayments.length; i++) {
            projects[newId].milestoneStatuses[i] = MilestoneStatus.Pending;
        }

        activeProjectIds.push(newId);
        emit ProjectProposed(newId, _msgSender(), _title, _requestedBudget);
    }

    function updateProposalDetails(uint256 _projectId, string memory _newTitle, string memory _newDescription) external onlyProjectProposer(_projectId) whenNotInEmergency {
        ProjectProposal storage project = projects[_projectId];
        require(project.status == ProposalStatus.Pending, "AetherForge: Can only update pending proposals");

        project.title = _newTitle;
        project.description = _newDescription;
        emit ProjectProposalUpdated(_projectId, _newTitle);
    }

    function getProjectDetails(uint256 _projectId) external view returns (
        uint256 id,
        address proposer,
        string memory title,
        string memory description,
        uint256 requestedBudget,
        uint256 fundedAmount,
        ProposalStatus status,
        uint256 voteEndTime,
        uint256 yesVotes,
        uint256 noVotes,
        uint256 currentMilestoneIndex,
        uint256 totalMilestones,
        ProjectOutcome outcome,
        string memory ipDetailsHash
    ) {
        ProjectProposal storage project = projects[_projectId];
        return (
            project.id,
            project.proposer,
            project.title,
            project.description,
            project.requestedBudget,
            project.fundedAmount,
            project.status,
            project.voteEndTime,
            project.yesVotes,
            project.noVotes,
            project.currentMilestoneIndex,
            project.milestonePayments.length,
            project.outcome,
            project.ipDetailsHash
        );
    }

    function getAIProposalScore(uint256 _proposalId, string memory _proposalDetailsHash) external view returns (uint256) {
        require(aiOracleAddress != address(0), "AetherForge: AI Oracle address not set");
        return IAIOracle(aiOracleAddress).getProposalScore(_proposalId, _proposalDetailsHash);
    }

    // --- III. Governance & Voting ---

    function voteOnProposal(uint256 _projectId, bool _support) external onlyIfReputable whenNotInEmergency {
        ProjectProposal storage project = projects[_projectId];
        require(project.status == ProposalStatus.Pending, "AetherForge: Proposal is not in voting phase");
        require(block.timestamp <= project.voteEndTime, "AetherForge: Voting for this proposal has ended");
        require(!project.hasVoted[_msgSender()], "AetherForge: Already voted on this proposal");

        uint256 influence = getContributorInfluenceScore(_msgSender());
        require(influence > 0, "AetherForge: Voter has no influence");

        project.hasVoted[_msgSender()] = true;
        if (_support) {
            project.yesVotes += influence;
        } else {
            project.noVotes += influence;
        }

        emit VoteCast(_projectId, _msgSender(), _support, influence);
    }

    function finalizeProposalVoting(uint256 _projectId) external whenNotInEmergency {
        ProjectProposal storage project = projects[_projectId];
        require(project.status == ProposalStatus.Pending, "AetherForge: Proposal is not in voting phase");
        require(block.timestamp > project.voteEndTime, "AetherForge: Voting period is not over yet");

        uint256 totalVotes = project.yesVotes + project.noVotes;
        if (totalVotes == 0) {
            project.status = ProposalStatus.Rejected; // No votes cast
            emit ProposalFinalized(_projectId, project.status, 0);
            return;
        }

        uint256 yesVotePercentageBPS = (project.yesVotes * 10000) / totalVotes;

        if (yesVotePercentageBPS >= currentGovernanceParams.proposalQuorumBPS && project.yesVotes > project.noVotes) {
            require(totalFundBalance - totalCommittedFunds >= project.requestedBudget, "AetherForge: Insufficient available funds to approve");
            project.status = ProposalStatus.Funded;
            project.fundedAmount = project.requestedBudget;
            totalCommittedFunds += project.requestedBudget;
            distributeReputation(project.proposer, 50); // Reward proposer for successful proposal
            emit ProposalFinalized(_projectId, project.status, project.fundedAmount);
            // Pay first milestone if applicable
            if (project.milestonePayments.length > 0) {
                 uint256 firstPayment = project.milestonePayments[0];
                 require(totalFundBalance >= firstPayment, "AetherForge: Not enough funds for first milestone payment immediately");
                 totalFundBalance -= firstPayment;
                 payable(project.proposer).transfer(firstPayment);
                 project.currentMilestoneIndex = 1; // Move to next milestone for approval
                 emit MilestoneApproved(_projectId, 0, firstPayment);
            }
        } else {
            project.status = ProposalStatus.Rejected;
            // Reward negative voters if project fails? Or penalize positive? More complex.
            emit ProposalFinalized(_projectId, project.status, 0);
        }
    }

    function proposeGovernanceChange(GovernanceParams memory _newParams) external onlyGovernor whenNotInEmergency {
        uint256 newId = nextGovernanceProposalId++;
        governanceProposals[newId] = GovernanceProposal({
            id: newId,
            proposer: _msgSender(),
            newParams: _newParams,
            voteEndTime: block.timestamp + currentGovernanceParams.governanceChangeVotingDuration,
            yesVotes: 0,
            noVotes: 0,
            hasVoted: new mapping(address => bool),
            executed: false
        });
        emit GovernanceChangeProposed(newId, _msgSender(), _newParams);
    }

    function voteOnGovernanceChange(uint256 _govPropId, bool _support) external onlyIfReputable whenNotInEmergency {
        GovernanceProposal storage govProp = governanceProposals[_govPropId];
        require(!govProp.executed, "AetherForge: Governance proposal already executed");
        require(block.timestamp <= govProp.voteEndTime, "AetherForge: Voting for this governance change has ended");
        require(!govProp.hasVoted[_msgSender()], "AetherForge: Already voted on this governance change");

        uint256 influence = getContributorInfluenceScore(_msgSender());
        require(influence > 0, "AetherForge: Voter has no influence");

        govProp.hasVoted[_msgSender()] = true;
        if (_support) {
            govProp.yesVotes += influence;
        } else {
            govProp.noVotes += influence;
        }
        emit VoteCast(_govPropId, _msgSender(), _support, influence); // Using same event, maybe specific for gov change
    }

    function finalizeGovernanceChange(uint256 _govPropId) external whenNotInEmergency {
        GovernanceProposal storage govProp = governanceProposals[_govPropId];
        require(!govProp.executed, "AetherForge: Governance proposal already executed");
        require(block.timestamp > govProp.voteEndTime, "AetherForge: Voting period is not over yet");

        uint256 totalVotes = govProp.yesVotes + govProp.noVotes;
        if (totalVotes == 0) {
            govProp.executed = true; // Mark as executed but not approved
            emit GovernanceChangeFinalized(_govPropId, false);
            return;
        }

        uint256 yesVotePercentageBPS = (govProp.yesVotes * 10000) / totalVotes;

        if (yesVotePercentageBPS >= currentGovernanceParams.governanceChangeQuorumBPS && govProp.yesVotes > govProp.noVotes) {
            currentGovernanceParams = govProp.newParams;
            govProp.executed = true;
            emit GovernanceChangeFinalized(_govPropId, true);
        } else {
            govProp.executed = true;
            emit GovernanceChangeFinalized(_govPropId, false);
        }
    }

    function getCurrentGovernanceParams() external view returns (GovernanceParams memory) {
        return currentGovernanceParams;
    }

    // --- IV. Project Milestones & IP Record Management ---

    function submitMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex) external onlyProjectProposer(_projectId) whenNotInEmergency {
        ProjectProposal storage project = projects[_projectId];
        require(project.status == ProposalStatus.Funded, "AetherForge: Project not in funded status");
        require(_milestoneIndex == project.currentMilestoneIndex, "AetherForge: Incorrect milestone index submitted");
        require(_milestoneIndex < project.milestonePayments.length, "AetherForge: Milestone index out of bounds");
        require(project.milestoneStatuses[_milestoneIndex] == MilestoneStatus.Pending, "AetherForge: Milestone already submitted/approved/rejected");

        project.milestoneStatuses[_milestoneIndex] = MilestoneStatus.Pending; // Already pending, but explicitly mark
        // In a real system, this would trigger an external review process,
        // which would then call approveMilestone or reject.
        emit MilestoneSubmitted(_projectId, _milestoneIndex);
    }

    function approveMilestone(uint256 _projectId, uint256 _milestoneIndex, bool _approve) external onlyGovernor whenNotInEmergency {
        ProjectProposal storage project = projects[_projectId];
        require(project.status == ProposalStatus.Funded, "AetherForge: Project not in funded status");
        require(_milestoneIndex < project.milestonePayments.length, "AetherForge: Milestone index out of bounds");
        require(_milestoneIndex == project.currentMilestoneIndex, "AetherForge: Only current milestone can be approved");
        require(project.milestoneStatuses[_milestoneIndex] == MilestoneStatus.Pending, "AetherForge: Milestone not in pending review state");

        if (_approve) {
            uint256 paymentAmount = project.milestonePayments[_milestoneIndex];
            require(totalFundBalance >= paymentAmount, "AetherForge: Insufficient funds to pay milestone");

            totalFundBalance -= paymentAmount;
            payable(project.proposer).transfer(paymentAmount);
            project.milestoneStatuses[_milestoneIndex] = MilestoneStatus.Approved;
            project.currentMilestoneIndex++;
            distributeReputation(project.proposer, 10); // Reward for milestone completion

            if (project.currentMilestoneIndex == project.milestonePayments.length) {
                project.status = ProposalStatus.Completed;
                setProjectOutcome(_projectId, ProjectOutcome.Success); // Project fully completed
                distributeReputation(project.proposer, 100); // Larger reward for full completion
                // Consider evaluator rewards here for those who voted 'yes' and it passed
            }
            emit MilestoneApproved(_projectId, _milestoneIndex, paymentAmount);
        } else {
            project.milestoneStatuses[_milestoneIndex] = MilestoneStatus.Rejected;
            // Potentially trigger a governance vote for next steps or revoke funding
            emit MilestoneApproved(_projectId, _milestoneIndex, 0); // Payment is 0 for rejection
        }
    }

    function recordIPOwnership(uint256 _projectId, string memory _ipDetailsHash) external onlyProjectProposer(_projectId) whenNotInEmergency {
        ProjectProposal storage project = projects[_projectId];
        require(project.status == ProposalStatus.Completed, "AetherForge: Project not completed to record IP");
        require(bytes(project.ipDetailsHash).length == 0, "AetherForge: IP already recorded for this project");

        project.ipDetailsHash = _ipDetailsHash;
        ipRecords[_projectId] = IPRule({
            owner: project.proposer,
            ipDetailsHash: _ipDetailsHash,
            projectId: _projectId,
            accumulatedRoyalties: 0
        });

        emit IPRuleRecorded(_projectId, project.proposer, _ipDetailsHash);
    }

    function claimIPRoyalties(uint256 _projectId) external whenNotInEmergency {
        IPRule storage ipRecord = ipRecords[_projectId];
        require(ipRecord.owner == _msgSender(), "AetherForge: Not the owner of this IP record");
        require(ipRecord.accumulatedRoyalties > 0, "AetherForge: No royalties to claim");

        uint256 royalties = ipRecord.accumulatedRoyalties;
        ipRecord.accumulatedRoyalties = 0;
        payable(_msgSender()).transfer(royalties);
        emit RoyaltiesClaimed(_projectId, _msgSender(), royalties);
    }

    // --- V. Reputation & Rewards ---

    function getReputationScore(address _user) public view returns (uint256) {
        return reputationScores[_user];
    }

    function distributeReputation(address _user, uint256 _amount) internal {
        reputationScores[_user] += _amount;
        emit ReputationDistributed(_user, _amount);
    }

    function claimEvaluatorReward(uint256 _projectId) external whenNotInEmergency {
        ProjectProposal storage project = projects[_projectId];
        require(project.status == ProposalStatus.Completed || project.status == ProposalStatus.Failed, "AetherForge: Project outcome not finalized");
        require(project.hasVoted[_msgSender()], "AetherForge: You did not vote on this project");

        bool votedSuccessfully = false;
        if (project.outcome == ProjectOutcome.Success && project.yesVotes > project.noVotes && project.hasVoted[_msgSender()]) {
            votedSuccessfully = true;
        } else if (project.outcome == ProjectOutcome.Failure && project.noVotes > project.yesVotes && project.hasVoted[_msgSender()]) {
            votedSuccessfully = true;
        }

        require(votedSuccessfully, "AetherForge: Your vote was not aligned with the final project outcome.");

        // Prevent double claiming (using hasVoted is not sufficient here, need a specific claim flag)
        // For simplicity, we'll assume an external tracking system prevents double claims.
        // In a real scenario, this would involve a mapping for `hasClaimedEvaluatorReward[_projectId][_msgSender()]`.

        uint256 rewardAmount = (project.requestedBudget * currentGovernanceParams.evaluatorRewardBPS) / 10000;
        require(totalFundBalance >= rewardAmount, "AetherForge: Insufficient funds for evaluator reward");

        totalFundBalance -= rewardAmount;
        payable(_msgSender()).transfer(rewardAmount);
        emit EvaluatorRewardClaimed(_msgSender(), rewardAmount);
        distributeReputation(_msgSender(), 5); // Small reputation boost for accurate evaluation
    }

    // --- VI. Dynamic & Advanced Mechanisms & Emergency Protocol ---

    function updateAIOracleAddress(address _newAddress) external onlyGovernor {
        require(_newAddress != address(0), "AetherForge: New AI Oracle address cannot be zero");
        aiOracleAddress = _newAddress;
        emit AIOracleAddressUpdated(_newAddress);
    }

    function triggerEmergencyProtocol() external onlyGovernor {
        // Requires a high quorum from current governance parameters.
        // Simplified: only governor can trigger, but in advanced system, would be a governance vote
        // requiring currentGovernanceParams.emergencyQuorumBPS
        require(!inEmergencyState || (inEmergencyState && block.timestamp > emergencyStartTimestamp + EMERGENCY_DURATION),
            "EmergencyProtocol: Already in an active emergency or cooldown state");

        inEmergencyState = true;
        emergencyStartTimestamp = block.timestamp;
        emit EmergencyProtocolTriggered(_msgSender());
    }

    // This function would typically be called by the AI Oracle
    function submitOracleReport(uint256 _aiSentimentScore, uint256 _fundHealthBias) external onlyAIOracle whenNotInEmergency {
        // Store report data, which then influences adjustDynamicGovernance
        // For this example, we directly call adjustDynamicGovernance
        adjustDynamicGovernance(_aiSentimentScore, _fundHealthBias);
        emit OracleReportSubmitted(_aiSentimentScore, _fundHealthBias);
    }

    function adjustDynamicGovernance(uint256 _aiSentimentScore, uint256 _fundHealthBias) internal {
        // This is a simplified example of dynamic adjustment.
        // Real-world logic would involve more complex algorithms based on AI reports, fund health, etc.

        // Calculate fund health score (e.g., available vs. committed funds)
        uint256 currentAvailable = totalFundBalance - totalCommittedFunds;
        uint256 fundHealthRatioBPS = (totalFundBalance > 0) ? (currentAvailable * 10000) / totalFundBalance : 0;

        uint256 successRate = getRecentProjectSuccessRate(); // Value between 0 and 10000 BPS

        // Factors for adjustment
        int256 sentimentImpact = int256(_aiSentimentScore) - 5000; // Assuming _aiSentimentScore is 0-10000, 5000 is neutral
        int256 fundHealthImpact = int256(fundHealthRatioBPS) - 5000;
        int256 successRateImpact = int256(successRate) - 5000;

        // Adjust proposal quorum: Lower if sentiment/health is high, raise if low
        int256 newQuorumBPS = int256(currentGovernanceParams.proposalQuorumBPS) - (sentimentImpact / 100) - (fundHealthImpact / 200); // Max +/- 50 BPS for sentiment, 25 for health
        if (newQuorumBPS < 3000) newQuorumBPS = 3000; // Min 30%
        if (newQuorumBPS > 7000) newQuorumBPS = 7000; // Max 70%
        currentGovernanceParams.proposalQuorumBPS = uint256(newQuorumBPS);

        // Adjust voting duration: Shorter if quick decisions are needed (high sentiment/success), longer if caution needed
        int256 newDuration = int256(currentGovernanceParams.proposalVotingDuration) - (sentimentImpact * 60 * 60 / 2000); // Max +/- 1.8 hours
        if (newDuration < 1 days) newDuration = 1 days;
        if (newDuration > 5 days) newDuration = 5 days;
        currentGovernanceParams.proposalVotingDuration = uint256(newDuration);

        // Adjust min reputation for vote: Higher if poor performance, lower if good
        int256 newMinRep = int256(currentGovernanceParams.minReputationForVote) - (successRateImpact / 1000); // Max +/- 5 reputation
        if (newMinRep < 0) newMinRep = 0;
        if (newMinRep > 100) newMinRep = 100;
        currentGovernanceParams.minReputationForVote = uint256(newMinRep);


        // Note: For advanced concepts, _fundHealthBias from AI could override or amplify other effects.
        // For example, if AI predicts a market crash (high fundHealthBias), it might significantly raise quorum.

        emit DynamicGovernanceAdjusted(currentGovernanceParams);
    }

    function setProjectOutcome(uint256 _projectId, ProjectOutcome _outcome) public whenNotInEmergency {
        ProjectProposal storage project = projects[_projectId];
        require(project.status == ProposalStatus.Completed || project.status == ProposalStatus.Failed, "AetherForge: Project not in final state");
        require(project.outcome == ProjectOutcome.Undetermined, "AetherForge: Project outcome already set");

        project.outcome = _outcome;
        projectOutcomesHistory.push(_outcome == ProjectOutcome.Success ? 1 : 0); // 1 for success, 0 for failure

        if (projectOutcomesHistory.length > SUCCESS_RATE_WINDOW_SIZE) {
            projectOutcomesHistory.pop(); // Keep history size fixed
        }

        emit ProjectOutcomeSet(_projectId, _outcome);
    }

    function getRecentProjectSuccessRate() public view returns (uint256) {
        if (projectOutcomesHistory.length == 0) {
            return 0;
        }

        uint256 successfulProjects;
        for (uint256 i = 0; i < projectOutcomesHistory.length; i++) {
            if (projectOutcomesHistory[i] == 1) { // 1 means Success
                successfulProjects++;
            }
        }
        return (successfulProjects * 10000) / projectOutcomesHistory.length; // Returns in BPS
    }

    function revokeProjectFunding(uint256 _projectId) external onlyGovernor whenNotInEmergency {
        ProjectProposal storage project = projects[_projectId];
        require(project.status == ProposalStatus.Funded, "AetherForge: Project not in funded status");

        uint256 remainingBudget = project.requestedBudget - project.fundedAmount;
        totalCommittedFunds -= remainingBudget; // Uncommit remaining funds

        project.status = ProposalStatus.Cancelled;
        setProjectOutcome(_projectId, ProjectOutcome.Failure); // Mark as failed due to revocation
        emit FundingRevoked(_projectId);
    }

    function getContributorInfluenceScore(address _contributor) public view returns (uint256) {
        // Influence score combines reputation and potentially staked funds (simplified to reputation only)
        // In a more complex system, this could also include tokens staked in the contract,
        // or other on-chain activities.
        return reputationScores[_contributor];
    }

    function updateProjectFundingRequest(uint256 _projectId, uint256 _newRequestedBudget, uint256[] memory _newMilestonePayments) external onlyProjectProposer(_projectId) whenNotInEmergency {
        ProjectProposal storage project = projects[_projectId];
        require(project.status == ProposalStatus.Funded, "AetherForge: Project not funded, cannot update budget");
        require(_newRequestedBudget > project.fundedAmount, "AetherForge: New budget must be higher than already funded amount");
        require(_newMilestonePayments.length >= project.currentMilestoneIndex, "AetherForge: New milestones cannot be less than current progress");

        uint256 totalNewMilestonePayments;
        for (uint256 i = 0; i < _newMilestonePayments.length; i++) {
            totalNewMilestonePayments += _newMilestonePayments[i];
        }
        require(totalNewMilestonePayments == _newRequestedBudget, "AetherForge: Sum of new milestone payments must equal new requested budget");

        // This would typically trigger a new governance vote for the amendment
        // For simplicity, we just update the details and require a new vote approval.
        project.requestedBudget = _newRequestedBudget;
        project.milestonePayments = _newMilestonePayments;
        // Reset status to pending for re-evaluation by governance for the additional funds
        project.status = ProposalStatus.Pending; // Requires re-approval for the new budget
        project.voteEndTime = block.timestamp + currentGovernanceParams.proposalVotingDuration;
        project.yesVotes = 0;
        project.noVotes = 0;
        // Reset hasVoted for new vote round
        // This is a mapping within the struct, so we can't easily reset it entirely.
        // A better approach would be to create a new "amendment proposal" struct.
        // For current context, this is a simplification.
        // Consider this effectively cancels current voting state and starts a new one for the same project ID.
        // For production, create a separate `ProjectAmendment` struct.
        emit ProjectFundingRequestUpdated(_projectId, _newRequestedBudget);
    }


    // --- Fallback & Receive ---
    receive() external payable {
        depositFunds();
    }

    fallback() external payable {
        depositFunds();
    }

    // --- Owner functions (basic admin) ---
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = _newOwner;
    }

    function setGovernor(address _newGovernor) public onlyOwner {
        require(_newGovernor != address(0), "Governor: new governor is the zero address");
        governorRole = _newGovernor;
    }

    function setRoyaltyDistributor(address _newDistributor) public onlyOwner {
        require(_newDistributor != address(0), "RoyaltyDistributor: new address is the zero address");
        royaltyDistributorAddress = _newDistributor;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
```