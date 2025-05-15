Okay, let's design a smart contract for a Decentralized Autonomous Creative Fund (DACF). This contract will allow participants to contribute funds, propose creative projects, vote on which projects get funded, manage project execution via milestones, track participant reputation, and govern the fund's parameters – all on-chain.

It incorporates concepts like:
1.  **DAO Governance:** Voting on projects and fund configuration.
2.  **Reputation System:** Non-transferable score influencing voting power and privileges.
3.  **Milestone-Based Funding:** Releasing project funds only upon verifiable progress.
4.  **Funding Cycles:** Structured periods for different activities (submission, voting, execution).
5.  **Configurable Parameters:** Allowing the community to tune fund behavior over time.
6.  **Slashing/Penalties:** Discouraging malicious behavior or project failure.

It aims to be creative by combining these elements specifically for funding and managing creative endeavors, going beyond standard token or NFT structures.

---

**Contract Outline & Function Summary**

**Contract Name:** `DecentralizedAutonomousCreativeFund`

**Purpose:** A decentralized fund governed by its participants to support creative projects through a proposal, voting, and milestone-based funding process, incorporating a reputation system.

**Core Concepts:**
*   **Funding Cycles:** The fund operates in distinct phases (Submission, Voting, Execution, Cooldown).
*   **Proposals:** Participants submit project proposals requesting funding and outlining milestones.
*   **Voting:** Participants with reputation vote on project proposals and configuration changes. Voting power is based on reputation.
*   **Milestones:** Approved projects receive funds in stages tied to milestone completion, verified by the community.
*   **Reputation:** Earned by participating constructively (e.g., voting on successful proposals, completing project milestones). Lost for detrimental actions. Reputation determines voting power and access.
*   **Configuration Governance:** Key fund parameters can be changed through a separate proposal and voting process.

**State Variables:**
*   `fundBalance`: Total ETH held by the contract.
*   `totalReputation`: Sum of all reputation points in the system.
*   `funders`: Mapping of addresses to contributed ETH amount.
*   `reputation`: Mapping of addresses to reputation points.
*   `projectProposals`: Mapping of proposal ID to `ProjectProposal` struct.
*   `configProposals`: Mapping of proposal ID to `ConfigProposal` struct.
*   `projectProposalCounter`: Counter for project proposal IDs.
*   `configProposalCounter`: Counter for config proposal IDs.
*   `currentFundingCycle`: The current cycle number.
*   `currentCyclePhase`: Enum indicating the current phase (Submission, Voting, Execution, Cooldown).
*   `cyclePhaseEndTime`: Timestamp when the current phase ends.
*   `config`: `FundConfig` struct holding governance parameters.
*   `projectVotes`: Nested mapping (proposalId => voterAddress => bool) for project votes.
*   `configVotes`: Nested mapping (proposalId => voterAddress => bool) for config votes.
*   `milestoneVerificationVotes`: Nested mapping (proposalId => milestoneIndex => voterAddress => bool) for milestone verification votes.
*   `allocatedProjectFunds`: Mapping of project proposal ID to the amount of ETH allocated but not yet released.

**Enums:**
*   `CyclePhase`: Represents the distinct stages of a funding cycle.
*   `ProposalStatus`: Indicates the state of a project or config proposal.
*   `MilestoneStatus`: Indicates the state of a project milestone.

**Structs:**
*   `FundConfig`: Holds configurable parameters of the fund (durations, thresholds, reputation gain/loss amounts).
*   `ProjectProposal`: Details of a proposed creative project.
*   `ConfigProposal`: Details of a proposed change to the `FundConfig`.
*   `Milestone`: Details of a project milestone (description, funding percentage).

**Events:**
*   `ContributionReceived`: Logs when someone contributes ETH.
*   `ContributionWithdrawn`: Logs when someone withdraws ETH.
*   `ProjectProposalSubmitted`: Logs a new project proposal.
*   `ConfigProposalSubmitted`: Logs a new config proposal.
*   `ProjectVoted`: Logs a vote on a project proposal.
*   `ConfigVoted`: Logs a vote on a config proposal.
*   `ProjectProposalOutcome`: Logs the result of a project vote (Approved/Rejected).
*   `ConfigProposalOutcome`: Logs the result of a config vote (Approved/Rejected).
*   `MilestoneCompletionSubmitted`: Logs when a project lead submits a milestone completion.
*   `MilestoneVerificationVoted`: Logs a vote on milestone verification.
*   `MilestoneVerified`: Logs when a milestone is successfully verified.
*   `MilestonePaymentDistributed`: Logs when a milestone payment is sent.
*   `ProjectFailedReported`: Logs when a project failure is reported.
*   `ProjectTerminated`: Logs when a project is terminated (e.g., failure or completion).
*   `ReputationAwarded`: Logs reputation gain.
*   `ReputationPenalized`: Logs reputation loss.
*   `ConfigUpdated`: Logs when the fund configuration is changed.
*   `CyclePhaseAdvanced`: Logs the transition to the next cycle phase.

**Function Summary (>= 20 distinct public/external functions):**

1.  `constructor`: Initializes the contract with basic parameters and the first funding cycle.
2.  `contribute()`: Allows participants to send ETH to the fund, potentially gaining initial reputation. (payable)
3.  `withdrawContribution()`: Allows participants to withdraw their *unallocated* contribution under specific conditions (e.g., after a cycle ends, if projects they voted for weren't funded).
4.  `submitProjectProposal()`: Allows eligible participants to propose a project during the Submission phase. Requires reputation.
5.  `voteOnProjectProposal(uint256 proposalId, bool support)`: Allows participants with reputation to vote Yes/No on a project proposal during the Voting phase. Voting power based on reputation.
6.  `submitMilestoneCompletionProof(uint256 proposalId, uint256 milestoneIndex, string calldata proofDetails)`: Allows the project proposer to submit proof of milestone completion during the Execution phase.
7.  `requestMilestonePayment(uint256 proposalId, uint256 milestoneIndex)`: Allows the project proposer to request payment for a completed and verified milestone.
8.  `voteToVerifyMilestone(uint256 proposalId, uint256 milestoneIndex, bool verified)`: Allows participants with reputation to vote Yes/No on whether a submitted milestone proof is sufficient during the Execution phase.
9.  `distributeMilestonePayment(uint256 proposalId, uint256 milestoneIndex)`: Internal/Triggered function to send funds for a verified milestone. Called after successful verification vote.
10. `reportProjectFailure(uint256 proposalId, string calldata reason)`: Allows participants to report a project failing to meet expectations during the Execution phase. Potential reputation impact.
11. `proposeConfigChange(FundConfig memory newConfig)`: Allows participants with sufficient reputation to propose changing the fund's configuration during the Submission phase.
12. `voteOnConfigChange(uint256 proposalId, bool support)`: Allows participants with reputation to vote Yes/No on a config change proposal during the Voting phase. Voting power based on reputation.
13. `enactConfigChange(uint256 proposalId)`: Internal/Triggered function to apply an approved configuration change. Called after successful config vote.
14. `startNextFundingCyclePhase()`: Allows anyone to trigger the transition to the next phase if the current phase duration has passed. This function handles phase-specific logic (tallying votes, distributing initial project funds, checking milestones).
15. `getFundBalance()`: View function returning the total ETH held by the contract.
16. `getReputation(address participant)`: View function returning the reputation points of an address.
17. `getProjectProposalDetails(uint256 proposalId)`: View function returning details of a specific project proposal.
18. `getProjectProposalStatus(uint256 proposalId)`: View function returning the status of a project proposal.
19. `getVotingPower(address participant)`: View function returning the current voting power of an address (based on reputation).
20. `getCurrentCyclePhase()`: View function returning the current funding cycle phase.
21. `getMilestoneStatus(uint256 proposalId, uint256 milestoneIndex)`: View function returning the status of a specific project milestone.
22. `getConfig()`: View function returning the current fund configuration parameters.
23. `getProjectProposalVoteCount(uint256 proposalId)`: View function returning the current vote counts for a project proposal.
24. `getMilestoneVerificationVoteCount(uint256 proposalId, uint256 milestoneIndex)`: View function returning the current vote counts for a milestone verification.
25. `hasVotedOnProjectProposal(uint256 proposalId, address voter)`: View function checking if an address has voted on a project proposal.
26. `hasVotedOnConfigProposal(uint256 proposalId, address voter)`: View function checking if an address has voted on a config proposal.
27. `hasVotedOnMilestoneVerification(uint256 proposalId, uint256 milestoneIndex, address voter)`: View function checking if an address has voted on a milestone verification.
28. `getAllocatedProjectFunds(uint256 proposalId)`: View function returning the amount of funds allocated to a project but not yet released for milestones.

This structure provides over 20 functions covering funding, proposal, complex multi-stage voting (project, config, milestone), project execution management, reputation, configuration, and cycle management.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedAutonomousCreativeFund
 * @dev A community-governed fund to support creative projects using ETH contributions.
 * Participants contribute ETH, propose projects, vote on funding, manage execution
 * via milestones, earn/lose reputation based on participation, and govern fund parameters.
 *
 * Core Concepts:
 * - Funding Cycles: Structured phases (Submission, Voting, Execution, Cooldown).
 * - Proposals: Project and Config proposals subject to voting.
 * - Voting: Reputation-based voting power. Separate votes for project funding, config changes, and milestone verification.
 * - Milestones: Project funds released based on verified milestone completion.
 * - Reputation: Non-transferable score for voting power and eligibility, earned/lost through actions.
 * - Configuration Governance: Fund parameters can be updated via successful config proposals.
 *
 * Outline:
 * 1. Enums, Structs, Events
 * 2. State Variables
 * 3. Modifiers
 * 4. Constructor
 * 5. Core Fund Mechanics (Contribution, Withdrawal)
 * 6. Funding Cycle Management
 * 7. Project Proposal & Voting
 * 8. Config Proposal & Voting
 * 9. Project Execution & Milestone Management
 * 10. Reputation System (Internal Helpers)
 * 11. View Functions (> 20 total public/external functions)
 */
contract DecentralizedAutonomousCreativeFund {

    // --- 1. Enums, Structs, Events ---

    /**
     * @dev Represents the current phase of a funding cycle.
     */
    enum CyclePhase { Submission, Voting, Execution, Cooldown }

    /**
     * @dev Represents the status of a project or configuration proposal.
     */
    enum ProposalStatus { Pending, Approved, Rejected, Terminated, Executed }

    /**
     * @dev Represents the status of a project milestone.
     */
    enum MilestoneStatus { Pending, ProofSubmitted, VerificationVoting, Verified, Failed }

    /**
     * @dev Struct to hold configurable parameters of the fund.
     * All durations are in seconds.
     */
    struct FundConfig {
        uint256 submissionPeriodDuration;
        uint256 votingPeriodDuration;
        uint256 executionPeriodDuration;
        uint256 cooldownPeriodDuration;
        uint256 minReputationToProposeProject;
        uint256 minReputationToProposeConfig;
        uint256 minReputationToVote;
        uint256 minReputationToVerifyMilestone;
        uint256 projectVotingQuorumNumerator; // Numerator for percentage (denominator is 100)
        uint256 projectApprovalThresholdNumerator; // Numerator for percentage (denominator is 100)
        uint256 milestoneVerificationQuorumNumerator;
        uint256 milestoneVerificationApprovalThresholdNumerator;
        uint256 reputationGainOnSuccessfulProjectVote;
        uint256 reputationGainOnSuccessfulConfigVote;
        uint256 reputationGainOnMilestoneVerificationVote;
        uint256 reputationGainOnMilestoneCompletion;
        uint256 reputationPenaltyOnProjectFailure;
        uint256 reputationPenaltyOnFailureReport; // Optional, penalize false reports
        uint256 configVotingQuorumNumerator;
        uint256 configApprovalThresholdNumerator;
    }

    /**
     * @dev Struct to define a project milestone.
     */
    struct Milestone {
        string description;
        uint256 fundingPercentage; // Percentage of total requested funding for this milestone
        MilestoneStatus status;
        uint256 yesVotes; // Votes for verification
        uint256 noVotes; // Votes against verification
    }

    /**
     * @dev Struct to hold details of a proposed creative project.
     */
    struct ProjectProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 requestedAmount; // Total ETH requested for the project
        Milestone[] milestones; // List of milestones
        ProposalStatus status;
        uint256 submittedCycle; // The cycle in which the proposal was submitted
        uint256 yesVotes; // Votes for funding
        uint256 noVotes; // Votes against funding
        uint256 fundsDistributed; // Total ETH distributed for completed milestones
        uint256 lastMilestoneVoteEndTime; // Timestamp when the last milestone verification vote ends
        uint256 projectCompletionTime; // Timestamp when project is marked as completed or terminated
    }

    /**
     * @dev Struct to hold details of a proposed configuration change.
     */
    struct ConfigProposal {
        uint256 id;
        address proposer;
        FundConfig newConfig; // The proposed new configuration
        ProposalStatus status;
        uint256 submittedCycle; // The cycle in which the proposal was submitted
        uint256 yesVotes;
        uint256 noVotes;
    }

    // Events
    event ContributionReceived(address indexed participant, uint256 amount, uint256 reputationAwarded);
    event ContributionWithdrawn(address indexed participant, uint256 amount);
    event ProjectProposalSubmitted(uint256 indexed proposalId, address indexed proposer, uint256 requestedAmount, uint256 cycle);
    event ConfigProposalSubmitted(uint256 indexed proposalId, address indexed proposer, uint256 cycle);
    event ProjectVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ConfigVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProjectProposalOutcome(uint256 indexed proposalId, ProposalStatus status, uint256 yesVotes, uint256 noVotes, uint256 totalVotingPower);
    event ConfigProposalOutcome(uint256 indexed proposalId, ProposalStatus status, uint256 yesVotes, uint256 noVotes, uint256 totalVotingPower);
    event MilestoneCompletionSubmitted(uint256 indexed proposalId, uint256 indexed milestoneIndex, address indexed proposer);
    event MilestoneVerificationVoted(uint256 indexed proposalId, uint256 indexed milestoneIndex, address indexed voter, bool verified, uint256 votingPower);
    event MilestoneVerified(uint256 indexed proposalId, uint256 indexed milestoneIndex);
    event MilestonePaymentDistributed(uint256 indexed proposalId, uint256 indexed milestoneIndex, uint256 amount);
    event ProjectFailedReported(uint256 indexed proposalId, address indexed reporter, string reason);
    event ProjectTerminated(uint256 indexed proposalId, ProposalStatus status); // Status indicates why (Terminated/Executed)
    event ReputationAwarded(address indexed participant, uint256 amount, string reason);
    event ReputationPenalized(address indexed participant, uint256 amount, string reason);
    event ConfigUpdated(address indexed proposer, uint256 indexed proposalId, FundConfig newConfig);
    event CyclePhaseAdvanced(uint256 indexed cycle, CyclePhase oldPhase, CyclePhase newPhase, uint256 endTime);

    // --- 2. State Variables ---

    uint256 public fundBalance;
    uint256 public totalReputation; // Sum of all reputation points in the system

    mapping(address => uint256) public funders; // ETH contributed by each address
    mapping(address => uint256) public reputation; // Reputation points for each address

    mapping(uint256 => ProjectProposal) public projectProposals;
    mapping(uint256 => ConfigProposal) public configProposals;

    uint256 public projectProposalCounter; // Starts at 1
    uint256 public configProposalCounter; // Starts at 1

    uint256 public currentFundingCycle;
    CyclePhase public currentCyclePhase;
    uint256 public cyclePhaseEndTime;

    FundConfig public config;

    // Vote tracking: proposalId => voterAddress => votedForYes
    mapping(uint256 => mapping(address => bool)) private projectVotes;
    mapping(uint256 => mapping(address => bool)) private configVotes;

    // Milestone vote tracking: proposalId => milestoneIndex => voterAddress => votedForYes
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) private milestoneVerificationVotes;

    // Funds allocated to approved projects, but not yet released
    mapping(uint256 => uint256) public allocatedProjectFunds;

    // --- 3. Modifiers ---

    modifier onlyPhase(CyclePhase _phase) {
        require(currentCyclePhase == _phase, "DACF: Not in the correct cycle phase");
        _;
    }

    modifier updateCyclePhase() {
        if (block.timestamp >= cyclePhaseEndTime) {
            _advanceFundingCyclePhase();
        }
        _;
    }

    // --- 4. Constructor ---

    constructor(FundConfig memory initialConfig) {
        require(initialConfig.submissionPeriodDuration > 0, "DACF: Invalid config");
        require(initialConfig.votingPeriodDuration > 0, "DACF: Invalid config");
        require(initialConfig.executionPeriodDuration > 0, "DACF: Invalid config");
        require(initialConfig.cooldownPeriodDuration > 0, "DACF: Invalid config");
        require(initialConfig.projectVotingQuorumNumerator <= 100, "DACF: Invalid quorum");
        require(initialConfig.projectApprovalThresholdNumerator <= 100, "DACF: Invalid approval threshold");
        require(initialConfig.milestoneVerificationQuorumNumerator <= 100, "DACF: Invalid quorum");
        require(initialConfig.milestoneVerificationApprovalThresholdNumerator <= 100, "DACF: Invalid approval threshold");
        require(initialConfig.configVotingQuorumNumerator <= 100, "DACF: Invalid quorum");
        require(initialConfig.configApprovalThresholdNumerator <= 100, "DACF: Invalid approval threshold");


        config = initialConfig;
        currentFundingCycle = 1;
        currentCyclePhase = CyclePhase.Submission;
        cyclePhaseEndTime = block.timestamp + config.submissionPeriodDuration;

        projectProposalCounter = 1;
        configProposalCounter = 1;
    }

    // --- 5. Core Fund Mechanics ---

    /**
     * @dev Allows participants to contribute ETH to the fund.
     * Initial reputation may be awarded upon first contribution.
     */
    receive() external payable {
        contribute();
    }

    /**
     * @dev Allows participants to contribute ETH to the fund.
     * Initial reputation may be awarded upon first contribution.
     * @param amount The amount of ETH to contribute (sent via msg.value).
     */
    function contribute() public payable updateCyclePhase {
        require(msg.value > 0, "DACF: Contribution must be greater than zero");

        fundBalance += msg.value;
        funders[msg.sender] += msg.value;

        // Example: Award initial reputation on first contribution
        if (reputation[msg.sender] == 0) {
             uint256 initialRep = 100; // Example initial reputation amount
             reputation[msg.sender] += initialRep;
             totalReputation += initialRep;
             emit ReputationAwarded(msg.sender, initialRep, "Initial contribution");
        }

        emit ContributionReceived(msg.sender, msg.value, reputation[msg.sender]);
    }

    /**
     * @dev Allows a participant to withdraw their *unallocated* contribution.
     * Withdrawal is only possible during Cooldown phase or if funds weren't allocated
     * in the latest cycle they participated in.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawContribution(uint256 amount) public updateCyclePhase {
        require(funders[msg.sender] >= amount, "DACF: Insufficient contribution balance");
        require(amount > 0, "DACF: Withdrawal amount must be greater than zero");

        // --- Advanced withdrawal logic ---
        // This requires tracking how much of a funder's contribution is 'locked'
        // by proposals they voted FOR that were approved. This is complex
        // state to manage.
        // For simplicity in this example, we'll allow withdrawal only if the
        // fund balance *exceeds* total allocated funds OR during Cooldown phase.
        // A more robust system would track per-funder allocation lock.

        uint256 totalAllocated = 0;
        // Note: Iterating through all projectProposals might be too gas-intensive
        // for large numbers. A real-world system might use a different pattern
        // or restrict withdrawals further.
        // For this example, we'll sum allocated funds simply.
        // A better approach might be to track *unallocated* funds directly for each funder.
        // As a proxy, let's check if total contract balance minus allocated funds is sufficient.
        // This implicitly means contributors can only withdraw from the 'excess' pool
        // unless it's during Cooldown.

        for(uint256 i = 1; i < projectProposalCounter; i++) {
             ProjectProposal storage proposal = projectProposals[i];
             if (proposal.status == ProposalStatus.Approved || proposal.status == ProposalStatus.Executed) {
                  totalAllocated += (proposal.requestedAmount - proposal.fundsDistributed);
             }
        }

        bool isCooldown = (currentCyclePhase == CyclePhase.Cooldown);
        bool isFundSufficientForWithdrawal = (fundBalance - totalAllocated) >= amount;

        require(isCooldown || isFundSufficientForWithdrawal, "DACF: Funds currently allocated or not in cooldown phase");

        funders[msg.sender] -= amount;
        fundBalance -= amount;
        payable(msg.sender).transfer(amount);

        emit ContributionWithdrawn(msg.sender, amount);
    }

    // --- 6. Funding Cycle Management ---

    /**
     * @dev Allows anyone to advance the funding cycle phase if the current phase has ended.
     * Triggers phase-specific logic (e.g., tallying votes, distributing initial funds).
     */
    function startNextFundingCyclePhase() public updateCyclePhase {
        // updateCyclePhase modifier handles the core logic if time is up.
        // If this function is called before cyclePhaseEndTime, it does nothing until the time is met.
        // The modifier ensures that if called *at* or *after* the end time,
        // the phase transition logic `_advanceFundingCyclePhase` is executed *before* the function body,
        // and if called again *within* the new phase, it does nothing.
    }

    /**
     * @dev Internal function to handle the logic of advancing the funding cycle phase.
     * This function is triggered by the `updateCyclePhase` modifier.
     */
    function _advanceFundingCyclePhase() internal {
        // Check if time is actually up to prevent re-triggering in the same block/call
        if (block.timestamp < cyclePhaseEndTime) {
            return; // Not time to advance yet
        }

        CyclePhase oldPhase = currentCyclePhase;
        uint256 nextPhaseStartTime = block.timestamp; // Next phase starts immediately

        if (currentCyclePhase == CyclePhase.Submission) {
            // --- Transition from Submission to Voting ---
            // No specific actions needed for proposals themselves, they are now static.
            currentCyclePhase = CyclePhase.Voting;
            cyclePhaseEndTime = nextPhaseStartTime + config.votingPeriodDuration;
        } else if (currentCyclePhase == CyclePhase.Voting) {
            // --- Transition from Voting to Execution ---
            // Tally project and config votes. Distribute initial funds for approved projects.
            _tallyProjectVotes();
            _tallyConfigVotes();
            _distributeInitialProjectFunds();

            currentCyclePhase = CyclePhase.Execution;
            cyclePhaseEndTime = nextPhaseStartTime + config.executionPeriodDuration;
        } else if (currentCyclePhase == CyclePhase.Execution) {
            // --- Transition from Execution to Cooldown ---
            // Projects that did not complete milestones or were reported failed
            // might be terminated here. Remaining allocated funds returned to main pool.
            _finalizeExecutingProjects();

            currentCyclePhase = CyclePhase.Cooldown;
            cyclePhaseEndTime = nextPhaseStartTime + config.cooldownPeriodDuration;
        } else if (currentCyclePhase == CyclePhase.Cooldown) {
            // --- Transition from Cooldown back to Submission ---
            // Reset for the next cycle.
            currentFundingCycle++;
            currentCyclePhase = CyclePhase.Submission;
            cyclePhaseEndTime = nextPhaseStartTime + config.submissionPeriodDuration;
        }

        emit CyclePhaseAdvanced(currentFundingCycle, oldPhase, currentCyclePhase, cyclePhaseEndTime);
    }

    // --- 7. Project Proposal & Voting ---

    /**
     * @dev Allows a participant to submit a new project proposal.
     * Must be in the Submission phase and meet min reputation requirement.
     * @param _title Project title.
     * @param _description Project description.
     * @param _requestedAmount Total ETH requested.
     * @param _milestones Array of milestone details.
     */
    function submitProjectProposal(
        string calldata _title,
        string calldata _description,
        uint256 _requestedAmount,
        Milestone[] calldata _milestones
    ) external onlyPhase(CyclePhase.Submission) updateCyclePhase {
        require(reputation[msg.sender] >= config.minReputationToProposeProject, "DACF: Insufficient reputation to propose");
        require(_requestedAmount > 0, "DACF: Requested amount must be > 0");
        require(_milestones.length > 0, "DACF: Project must have at least one milestone");

        uint256 totalPercentage = 0;
        for (uint i = 0; i < _milestones.length; i++) {
            totalPercentage += _milestones[i].fundingPercentage;
             // Initialize milestone status and votes
             _milestones[i].status = MilestoneStatus.Pending;
             _milestones[i].yesVotes = 0;
             _milestones[i].noVotes = 0;
        }
        require(totalPercentage == 100, "DACF: Milestone percentages must sum to 100");
        require(_requestedAmount <= fundBalance, "DACF: Requested amount exceeds current fund balance"); // Cannot request more than available

        uint256 proposalId = projectProposalCounter++;
        projectProposals[proposalId] = ProjectProposal({
            id: proposalId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            requestedAmount: _requestedAmount,
            milestones: _milestones,
            status: ProposalStatus.Pending,
            submittedCycle: currentFundingCycle,
            yesVotes: 0,
            noVotes: 0,
            fundsDistributed: 0,
            lastMilestoneVoteEndTime: 0,
            projectCompletionTime: 0
        });

        emit ProjectProposalSubmitted(proposalId, msg.sender, _requestedAmount, currentFundingCycle);
    }

    /**
     * @dev Allows a participant to vote on a project proposal.
     * Must be in the Voting phase and meet min reputation requirement.
     * Can only vote once per proposal per cycle.
     * @param proposalId The ID of the project proposal.
     * @param support True for a 'Yes' vote, False for a 'No' vote.
     */
    function voteOnProjectProposal(uint256 proposalId, bool support) public onlyPhase(CyclePhase.Voting) updateCyclePhase {
        ProjectProposal storage proposal = projectProposals[proposalId];
        require(proposal.id != 0, "DACF: Project proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "DACF: Project proposal is not in a votable state");
        require(proposal.submittedCycle == currentFundingCycle, "DACF: Project proposal not from current cycle");
        require(!projectVotes[proposalId][msg.sender], "DACF: Already voted on this project proposal");
        require(reputation[msg.sender] >= config.minReputationToVote, "DACF: Insufficient reputation to vote");

        uint256 votingPower = reputation[msg.sender]; // Voting power is 1:1 with reputation

        if (support) {
            proposal.yesVotes += votingPower;
        } else {
            proposal.noVotes += votingPower;
        }
        projectVotes[proposalId][msg.sender] = true;

        emit ProjectVoted(proposalId, msg.sender, support, votingPower);
    }

    /**
     * @dev Internal function to tally project votes at the end of the Voting phase.
     */
    function _tallyProjectVotes() internal {
        uint256 totalRepAtStartOfVoting = totalReputation; // Use reputation from the start of the phase

        // Iterate only through proposals submitted in the current cycle
        for(uint256 i = projectProposalCounter - _getProposalsSubmittedInCycleCount(currentFundingCycle, true); i < projectProposalCounter; i++) {
            ProjectProposal storage proposal = projectProposals[i];
            // Only tally pending proposals from the current cycle
            if (proposal.status == ProposalStatus.Pending && proposal.submittedCycle == currentFundingCycle) {
                uint256 totalVotes = proposal.yesVotes + proposal.noVotes;

                // Check quorum: total votes must be at least quorum percentage of total reputation
                bool quorumMet = (totalVotes * 100) >= (totalRepAtStartOfVoting * config.projectVotingQuorumNumerator);

                // Check approval: Yes votes must be at least approval threshold percentage of total votes
                bool approved = (proposal.yesVotes * 100) >= (totalVotes * config.projectApprovalThresholdNumerator);

                if (quorumMet && approved) {
                    proposal.status = ProposalStatus.Approved;
                    // Allocate funds for approved projects (will be distributed via milestones)
                    allocatedProjectFunds[proposal.id] = proposal.requestedAmount;
                    fundBalance -= proposal.requestedAmount; // Funds are considered allocated
                    // Award reputation to YES voters on approved proposal (simplified)
                    // More complex: iterate voters, check if they voted Yes
                    // For simplicity here, award based on proposal outcome
                    // A real system needs detailed vote tracking storage for this.
                    // As a simplification: voters on *any* proposal from this cycle get rep if their side won the proposal they voted on.
                    // This would require tracking voter support explicitly, not just the boolean flag.
                    // Skipping explicit voter reputation award here to keep complexity manageable for the example function count.
                    // Awarding will happen on Milestone Verification or Project Completion.
                } else {
                    proposal.status = ProposalStatus.Rejected;
                    // Award reputation to NO voters on rejected proposal (simplified)
                    // Skipping explicit voter reputation award here.
                }
                emit ProjectProposalOutcome(proposal.id, proposal.status, proposal.yesVotes, proposal.noVotes, totalVotes);
            }
        }
    }

     /**
     * @dev Internal helper to count proposals submitted in a specific cycle.
     * Note: This can be gas intensive for large numbers of proposals if called frequently.
     * In a real system, store this count.
     * @param cycle The cycle number.
     * @param isProject True for project proposals, False for config proposals.
     */
    function _getProposalsSubmittedInCycleCount(uint256 cycle, bool isProject) internal view returns (uint256) {
        uint256 count = 0;
        uint256 counter = isProject ? projectProposalCounter : configProposalCounter;
        // Assuming proposal IDs are sequential and start from 1, this checks recent ones.
        // A more robust way would be to store proposal IDs per cycle or use an iterable mapping.
        uint256 startId = isProject ? 1 : 1; // Simplistic: start from 1
        if (counter > 100) { // Limit iteration for safety in this example
             startId = counter - 100;
        }

        for(uint256 i = startId; i < counter; i++) {
            if (isProject) {
                if (projectProposals[i].id != 0 && projectProposals[i].submittedCycle == cycle) {
                    count++;
                }
            } else {
                 if (configProposals[i].id != 0 && configProposals[i].submittedCycle == cycle) {
                    count++;
                }
            }
        }
         // Fallback if counter is small (e.g., first cycle)
         if (count == 0 && counter > 1) {
            for (uint i = 1; i < counter; i++) {
                 if (isProject) {
                    if (projectProposals[i].id != 0 && projectProposals[i].submittedCycle == cycle) {
                       count++;
                    }
                } else {
                     if (configProposals[i].id != 0 && configProposals[i].submittedCycle == cycle) {
                       count++;
                    }
                }
            }
         }
        return count;
    }


     /**
     * @dev Internal function to distribute the initial allocated funds for approved projects.
     * Called at the transition from Voting to Execution.
     * Note: Funds are *allocated* during tallying, but transferred here.
     * Funds remain within the contract, tracked in `allocatedProjectFunds`.
     */
    function _distributeInitialProjectFunds() internal {
        // Iterate only through proposals from the current cycle that were approved
        for(uint256 i = projectProposalCounter - _getProposalsSubmittedInCycleCount(currentFundingCycle, true); i < projectProposalCounter; i++) {
             ProjectProposal storage proposal = projectProposals[i];
            if (proposal.status == ProposalStatus.Approved && proposal.submittedCycle == currentFundingCycle) {
                // Initial distribution is 0. Funds are distributed per milestone.
                // The allocation in `allocatedProjectFunds` represents the total budget.
                // No funds leave the contract at this step.
                // The project's budget is now available to be paid out via milestones.
            }
        }
    }


    // --- 8. Config Proposal & Voting ---

    /**
     * @dev Allows a participant to propose a change to the fund's configuration.
     * Must be in the Submission phase and meet min reputation requirement.
     * @param _newConfig The proposed new configuration struct.
     */
    function proposeConfigChange(FundConfig memory _newConfig) public onlyPhase(CyclePhase.Submission) updateCyclePhase {
        require(reputation[msg.sender] >= config.minReputationToProposeConfig, "DACF: Insufficient reputation to propose config changes");
         require(_newConfig.submissionPeriodDuration > 0, "DACF: Invalid config");
         require(_newConfig.votingPeriodDuration > 0, "DACF: Invalid config");
         require(_newConfig.executionPeriodDuration > 0, "DACF: Invalid config");
         require(_newConfig.cooldownPeriodDuration > 0, "DACF: Invalid config");
         require(_newConfig.projectVotingQuorumNumerator <= 100, "DACF: Invalid quorum");
         require(_newConfig.projectApprovalThresholdNumerator <= 100, "DACF: Invalid approval threshold");
         require(_newConfig.milestoneVerificationQuorumNumerator <= 100, "DACF: Invalid quorum");
         require(_newConfig.milestoneVerificationApprovalThresholdNumerator <= 100, "DACF: Invalid approval threshold");
         require(_newConfig.configVotingQuorumNumerator <= 100, "DACF: Invalid quorum");
         require(_newConfig.configApprovalThresholdNumerator <= 100, "DACF: Invalid approval threshold");


        uint256 proposalId = configProposalCounter++;
        configProposals[proposalId] = ConfigProposal({
            id: proposalId,
            proposer: msg.sender,
            newConfig: _newConfig,
            status: ProposalStatus.Pending,
            submittedCycle: currentFundingCycle,
            yesVotes: 0,
            noVotes: 0
        });

        emit ConfigProposalSubmitted(proposalId, msg.sender, currentFundingCycle);
    }

    /**
     * @dev Allows a participant to vote on a configuration change proposal.
     * Must be in the Voting phase and meet min reputation requirement.
     * Can only vote once per proposal per cycle.
     * @param proposalId The ID of the config proposal.
     * @param support True for a 'Yes' vote, False for a 'No' vote.
     */
    function voteOnConfigChange(uint256 proposalId, bool support) public onlyPhase(CyclePhase.Voting) updateCyclePhase {
        ConfigProposal storage proposal = configProposals[proposalId];
        require(proposal.id != 0, "DACF: Config proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "DACF: Config proposal is not in a votable state");
        require(proposal.submittedCycle == currentFundingCycle, "DACF: Config proposal not from current cycle");
        require(!configVotes[proposalId][msg.sender], "DACF: Already voted on this config proposal");
        require(reputation[msg.sender] >= config.minReputationToVote, "DACF: Insufficient reputation to vote");

        uint256 votingPower = reputation[msg.sender];

        if (support) {
            proposal.yesVotes += votingPower;
        } else {
            proposal.noVotes += votingPower;
        }
        configVotes[proposalId][msg.sender] = true;

        emit ConfigVoted(proposalId, msg.sender, support, votingPower);
    }

    /**
     * @dev Internal function to tally config votes at the end of the Voting phase.
     */
    function _tallyConfigVotes() internal {
        uint256 totalRepAtStartOfVoting = totalReputation;

        // Iterate only through proposals submitted in the current cycle
        for(uint256 i = configProposalCounter - _getProposalsSubmittedInCycleCount(currentFundingCycle, false); i < configProposalCounter; i++) {
            ConfigProposal storage proposal = configProposals[i];
            // Only tally pending proposals from the current cycle
            if (proposal.status == ProposalStatus.Pending && proposal.submittedCycle == currentFundingCycle) {
                uint256 totalVotes = proposal.yesVotes + proposal.noVotes;

                // Check quorum and approval
                bool quorumMet = (totalVotes * 100) >= (totalRepAtStartOfVoting * config.configVotingQuorumNumerator);
                bool approved = (proposal.yesVotes * 100) >= (totalVotes * config.configApprovalThresholdNumerator);

                if (quorumMet && approved) {
                    proposal.status = ProposalStatus.Approved;
                    // Enact the config change immediately
                    _enactConfigChange(proposal.id);
                     // Award reputation to YES voters (simplified)
                     // Skipping explicit voter reputation award here.
                } else {
                    proposal.status = ProposalStatus.Rejected;
                    // Award reputation to NO voters (simplified)
                    // Skipping explicit voter reputation award here.
                }
                 emit ConfigProposalOutcome(proposal.id, proposal.status, proposal.yesVotes, proposal.noVotes, totalVotes);
            }
        }
    }

    /**
     * @dev Internal function to apply an approved configuration change.
     * @param proposalId The ID of the approved config proposal.
     */
    function _enactConfigChange(uint256 proposalId) internal {
        ConfigProposal storage proposal = configProposals[proposalId];
        require(proposal.status == ProposalStatus.Approved, "DACF: Config proposal not approved");

        config = proposal.newConfig;
        proposal.status = ProposalStatus.Executed; // Mark as executed

        emit ConfigUpdated(proposal.proposer, proposal.id, config);
    }


    // --- 9. Project Execution & Milestone Management ---

    /**
     * @dev Allows the project proposer to submit proof of completion for a milestone.
     * Must be in the Execution phase and the project must be Approved/Executing.
     * Starts the verification voting period for this milestone.
     * @param proposalId The ID of the project proposal.
     * @param milestoneIndex The index of the milestone (0-based).
     * @param proofDetails A string containing links or details of the proof.
     */
    function submitMilestoneCompletionProof(
        uint256 proposalId,
        uint256 milestoneIndex,
        string calldata proofDetails
    ) public onlyPhase(CyclePhase.Execution) updateCyclePhase {
        ProjectProposal storage proposal = projectProposals[proposalId];
        require(proposal.proposer == msg.sender, "DACF: Only project proposer can submit proof");
        require(proposal.status == ProposalStatus.Approved || proposal.status == ProposalStatus.Executed, "DACF: Project is not active"); // Approved means initial funding allocated
        require(milestoneIndex < proposal.milestones.length, "DACF: Invalid milestone index");
        require(proposal.milestones[milestoneIndex].status == MilestoneStatus.Pending, "DACF: Milestone is not pending");

        // Update milestone status
        proposal.milestones[milestoneIndex].status = MilestoneStatus.ProofSubmitted;
        // Reset votes for this milestone verification
        proposal.milestones[milestoneIndex].yesVotes = 0;
        proposal.milestones[milestoneIndex].noVotes = 0;
         // Note: Voting period for milestone verification is implicit within the Execution phase.
         // A more advanced system might have a separate shorter voting window per milestone.
         // For this example, verification voting happens anytime while status is ProofSubmitted during Execution.
        proposal.lastMilestoneVoteEndTime = block.timestamp + 7 days; // Example: Give 7 days for voting per milestone after proof submitted


        emit MilestoneCompletionSubmitted(proposalId, milestoneIndex, msg.sender);
        // proofDetails is not stored on-chain to save gas, assume it's off-chain (e.g., IPFS hash)
    }

    /**
     * @dev Allows participants with reputation to vote on whether a milestone proof is valid.
     * Must be in the Execution phase and during the verification voting window for the milestone.
     * Requires min reputation to verify.
     * @param proposalId The ID of the project proposal.
     * @param milestoneIndex The index of the milestone.
     * @param verified True to verify, False to reject verification.
     */
    function voteToVerifyMilestone(uint256 proposalId, uint256 milestoneIndex, bool verified) public onlyPhase(CyclePhase.Execution) updateCyclePhase {
        ProjectProposal storage proposal = projectProposals[proposalId];
        require(proposal.id != 0, "DACF: Project proposal does not exist");
        require(proposal.status == ProposalStatus.Approved || proposal.status == ProposalStatus.Executed, "DACF: Project is not active");
        require(milestoneIndex < proposal.milestones.length, "DACF: Invalid milestone index");
        require(proposal.milestones[milestoneIndex].status == MilestoneStatus.ProofSubmitted, "DACF: Milestone is not awaiting verification");
        require(block.timestamp < proposal.lastMilestoneVoteEndTime, "DACF: Milestone verification voting period has ended");
        require(reputation[msg.sender] >= config.minReputationToVerifyMilestone, "DACF: Insufficient reputation to verify milestones");
        require(!milestoneVerificationVotes[proposalId][milestoneIndex][msg.sender], "DACF: Already voted on this milestone verification");

        uint256 votingPower = reputation[msg.sender]; // Voting power based on reputation

        Milestone storage milestone = proposal.milestones[milestoneIndex];
        if (verified) {
            milestone.yesVotes += votingPower;
        } else {
            milestone.noVotes += votingPower;
        }
        milestoneVerificationVotes[proposalId][milestoneIndex][msg.sender] = true;

        // Check if verification vote threshold is met immediately (can be configured)
        _checkMilestoneVerificationOutcome(proposalId, milestoneIndex);

        emit MilestoneVerificationVoted(proposalId, milestoneIndex, msg.sender, verified, votingPower);
    }

    /**
     * @dev Internal function to check if milestone verification voting thresholds are met
     * and update milestone status/distribute funds if verified.
     * Can be triggered by a vote or by advancing the cycle phase during execution.
     * @param proposalId The ID of the project proposal.
     * @param milestoneIndex The index of the milestone.
     */
    function _checkMilestoneVerificationOutcome(uint256 proposalId, uint256 milestoneIndex) internal {
        ProjectProposal storage proposal = projectProposals[proposalId];
        Milestone storage milestone = proposal.milestones[milestoneIndex];

        // Only process milestones that are in the ProofSubmitted state and within their voting window OR the Execution phase ended
        if (milestone.status != MilestoneStatus.ProofSubmitted || (block.timestamp < proposal.lastMilestoneVoteEndTime && currentCyclePhase == CyclePhase.Execution)) {
             // If Execution phase ended, process even if voting window wasn't met, maybe with different logic?
             // For now, only process if voting window ended OR cycle ended while in ProofSubmitted
             if (block.timestamp < proposal.lastMilestoneVoteEndTime && currentCyclePhase != CyclePhase.Execution) return; // Not time to check yet
             if (block.timestamp >= proposal.lastMilestoneVoteEndTime && currentCyclePhase == CyclePhase.Execution) { /* proceed check */ } else if (currentCyclePhase != CyclePhase.Execution && milestone.status == MilestoneStatus.ProofSubmitted) { /* proceed check at phase end */ } else return; // Not in correct state/phase to check
        }


        uint256 totalMilestoneVotes = milestone.yesVotes + milestone.noVotes;
        uint256 totalReputationAtVoteTime = totalReputation; // Use current total reputation

        // Check quorum and approval for milestone verification
        bool quorumMet = (totalMilestoneVotes * 100) >= (totalReputationAtVoteTime * config.milestoneVerificationQuorumNumerator);
        bool approved = (milestone.yesVotes * 100) >= (totalMilestoneVotes * config.milestoneVerificationApprovalThresholdNumerator);

        if (quorumMet && approved) {
            milestone.status = MilestoneStatus.Verified;
            _awardReputation(proposal.proposer, config.reputationGainOnMilestoneCompletion, "Milestone completed");
             // Award reputation to YES voters (simplified)
             // Skipping explicit voter reputation award here.
            emit MilestoneVerified(proposal.id, milestoneIndex);
            // Funds are distributed when proposer requests payment via requestMilestonePayment
        } else if (milestone.status == MilestoneStatus.ProofSubmitted && (block.timestamp >= proposal.lastMilestoneVoteEndTime || currentCyclePhase != CyclePhase.Execution)) {
             // Mark as Failed if verification failed or vote window/phase ended without meeting thresholds
            milestone.status = MilestoneStatus.Failed;
             // Award reputation to NO voters (simplified)
             // Skipping explicit voter reputation award here.
             // Maybe penalize proposer? Depends on rules.
        }
    }

     /**
     * @dev Allows the project proposer to request payment for a completed and verified milestone.
     * Must be in the Execution phase and the milestone must be Verified.
     * @param proposalId The ID of the project proposal.
     * @param milestoneIndex The index of the milestone.
     */
    function requestMilestonePayment(uint256 proposalId, uint256 milestoneIndex) public onlyPhase(CyclePhase.Execution) updateCyclePhase {
        ProjectProposal storage proposal = projectProposals[proposalId];
        require(proposal.proposer == msg.sender, "DACF: Only project proposer can request payment");
        require(milestoneIndex < proposal.milestones.length, "DACF: Invalid milestone index");
        require(proposal.milestones[milestoneIndex].status == MilestoneStatus.Verified, "DACF: Milestone is not verified");

        _distributeMilestonePayment(proposalId, milestoneIndex);
    }


    /**
     * @dev Internal function to send funds for a verified milestone.
     * Triggered by requestMilestonePayment or potentially at phase end if auto-release is desired.
     * @param proposalId The ID of the project proposal.
     * @param milestoneIndex The index of the milestone.
     */
    function _distributeMilestonePayment(uint256 proposalId, uint256 milestoneIndex) internal {
        ProjectProposal storage proposal = projectProposals[proposalId];
        Milestone storage milestone = proposal.milestones[milestoneIndex];

        require(milestone.status == MilestoneStatus.Verified, "DACF: Milestone is not verified for payment");
        require(allocatedProjectFunds[proposal.id] > 0, "DACF: No allocated funds for this project");

        uint256 paymentAmount = (proposal.requestedAmount * milestone.fundingPercentage) / 100;
        require(allocatedProjectFunds[proposal.id] >= paymentAmount, "DACF: Insufficient allocated funds for this milestone");

        // Mark milestone as paid (or a new status like 'Completed')
        milestone.status = MilestoneStatus.Completed; // Using Completed to signify paid

        allocatedProjectFunds[proposal.id] -= paymentAmount;
        proposal.fundsDistributed += paymentAmount;

        // Transfer funds to the proposer
        // Use a check-effects-interactions pattern
        payable(proposal.proposer).transfer(paymentAmount);

        emit MilestonePaymentDistributed(proposal.id, milestoneIndex, paymentAmount);

        // Check if all milestones are completed
        bool allCompleted = true;
        for (uint i = 0; i < proposal.milestones.length; i++) {
            if (proposal.milestones[i].status != MilestoneStatus.Completed) {
                allCompleted = false;
                break;
            }
        }

        if (allCompleted) {
            proposal.status = ProposalStatus.Executed; // Project successfully completed
            proposal.projectCompletionTime = block.timestamp;
            emit ProjectTerminated(proposal.id, ProposalStatus.Executed);
            // Any remaining allocated funds for this project are returned to the main pool
            if (allocatedProjectFunds[proposal.id] > 0) {
                 fundBalance += allocatedProjectFunds[proposal.id];
                 allocatedProjectFunds[proposal.id] = 0; // Should be 0 if sum of percentages was 100
            }
        }
    }

     /**
     * @dev Allows participants to report that an executing project is failing.
     * Must be in the Execution phase. May require reputation.
     * This can trigger review or penalties based on fund rules.
     * @param proposalId The ID of the project proposal.
     * @param reason Details about why the project is failing.
     */
    function reportProjectFailure(uint256 proposalId, string calldata reason) public onlyPhase(CyclePhase.Execution) updateCyclePhase {
        ProjectProposal storage proposal = projectProposals[proposalId];
        require(proposal.id != 0, "DACF: Project proposal does not exist");
        require(proposal.status == ProposalStatus.Approved || proposal.status == ProposalStatus.Executed, "DACF: Project is not active");
        // require(reputation[msg.sender] >= config.minReputationToReportFailure, "DACF: Insufficient reputation to report failure"); // Optional: add config parameter for this

        // This report itself doesn't necessarily stop the project immediately.
        // It serves as a signal for community review.
        // A more advanced system might trigger a formal review process or a vote to terminate.
        // For this example, logging the event and potentially having a phase end check is sufficient.

        emit ProjectFailedReported(proposalId, msg.sender, reason);

        // Advanced: Penalize reporter if report is later found to be false (requires complex state)
        // _penalizeReputation(msg.sender, config.reputationPenaltyOnFailureReport, "False project failure report");
    }

     /**
     * @dev Internal function to finalize projects at the end of the Execution phase.
     * Checks for projects that failed to complete milestones and terminates them.
     */
     function _finalizeExecutingProjects() internal {
         // Iterate through all projects that were approved in the current or previous cycles
         // and are still in Approved state (meaning they started execution)
          for(uint256 i = 1; i < projectProposalCounter; i++) {
             ProjectProposal storage proposal = projectProposals[i];
             // Check projects approved in *any* previous cycle that are still active (Approved/Executed)
              if (proposal.status == ProposalStatus.Approved || proposal.status == ProposalStatus.Executed) { // Executed means completed all milestones
                   // Check if project is still active but failed to complete milestones on time
                   bool allMilestonesCompleted = true;
                   bool hasPendingOrProofSubmitted = false;
                   for(uint j=0; j < proposal.milestones.length; j++) {
                       if (proposal.milestones[j].status != MilestoneStatus.Completed) {
                           allMilestonesCompleted = false;
                           if (proposal.milestones[j].status == MilestoneStatus.Pending || proposal.milestones[j].status == MilestoneStatus.ProofSubmitted) {
                               hasPendingOrProofSubmitted = true;
                           }
                       }
                   }

                   if (!allMilestonesCompleted) {
                       // If there are still pending/proof submitted milestones when Execution phase ends, the project might be considered failed.
                       // This rule needs to be clear (e.g., finish all milestones within the *cycle* they are approved for?).
                       // Assuming projects must finish all milestones within the Execution phase they were approved OR subsequent Execution phases.
                       // A simple rule: If Execution phase ends and not all milestones are completed, project is terminated.
                       if (hasPendingOrProofSubmitted) {
                            proposal.status = ProposalStatus.Terminated;
                            proposal.projectCompletionTime = block.timestamp;

                             // Penalize the proposer for project failure
                             _penalizeReputation(proposal.proposer, config.reputationPenaltyOnProjectFailure, "Project failed to complete milestones");

                            // Return remaining allocated funds to the main pool
                            if (allocatedProjectFunds[proposal.id] > 0) {
                                fundBalance += allocatedProjectFunds[proposal.id];
                                allocatedProjectFunds[proposal.id] = 0;
                            }
                            emit ProjectTerminated(proposal.id, ProposalStatus.Terminated);
                       }
                   } else {
                       // If all milestones completed and status is still Approved (should be Executed), fix status
                       if (proposal.status == ProposalStatus.Approved) {
                            proposal.status = ProposalStatus.Executed;
                            proposal.projectCompletionTime = block.timestamp;
                            emit ProjectTerminated(proposal.id, ProposalStatus.Executed); // Log completion
                       }
                        // If project finished, any leftovers in allocatedProjectFunds should return (should be 0 if percentages sum to 100)
                        if (allocatedProjectFunds[proposal.id] > 0) {
                             fundBalance += allocatedProjectFunds[proposal.id];
                             allocatedProjectFunds[proposal.id] = 0;
                        }
                   }
              }
          }
     }


    // --- 10. Reputation System (Internal Helpers) ---

    /**
     * @dev Internal function to award reputation points.
     * @param participant The address to award reputation to.
     * @param amount The amount of reputation points to award.
     * @param reason A string describing the reason for the award.
     */
    function _awardReputation(address participant, uint256 amount, string memory reason) internal {
        if (amount > 0) {
            reputation[participant] += amount;
            totalReputation += amount;
            emit ReputationAwarded(participant, amount, reason);
        }
    }

    /**
     * @dev Internal function to penalize (remove) reputation points.
     * Reputation cannot go below zero.
     * @param participant The address to penalize.
     * @param amount The amount of reputation points to remove.
     * @param reason A string describing the reason for the penalty.
     */
    function _penalizeReputation(address participant, uint256 amount, string memory reason) internal {
        if (amount > 0) {
            uint256 loss = amount;
            if (reputation[participant] < loss) {
                loss = reputation[participant]; // Can't go below zero
            }
            reputation[participant] -= loss;
            totalReputation -= loss;
            emit ReputationPenalized(participant, loss, reason);
        }
    }


    // --- 11. View Functions (> 20 total) ---

    /**
     * @dev Returns the total ETH balance held by the contract.
     */
    function getFundBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the reputation points of a participant.
     * @param participant The address to check.
     */
    function getReputation(address participant) public view returns (uint256) {
        return reputation[participant];
    }

     /**
     * @dev Returns the total sum of all reputation points in the system.
     */
    function getTotalReputation() public view returns (uint256) {
        return totalReputation;
    }


    /**
     * @dev Returns the current voting power of a participant.
     * Currently 1:1 with reputation. Can be extended based on stake or time.
     * @param participant The address to check.
     */
    function getVotingPower(address participant) public view returns (uint256) {
        return reputation[participant];
    }

    /**
     * @dev Returns the current funding cycle number.
     */
    function getCurrentFundingCycle() public view returns (uint256) {
        return currentFundingCycle;
    }

    /**
     * @dev Returns the current funding cycle phase.
     */
    function getCurrentCyclePhase() public view returns (CyclePhase) {
        // Update phase automatically if time is up before returning
         if (block.timestamp >= cyclePhaseEndTime) {
             // Cannot call internal from view. Replicate check or require caller to call startNextFundingCyclePhase first.
             // For a view function, just return the *current* state, don't modify.
         }
        return currentCyclePhase;
    }

     /**
     * @dev Returns the timestamp when the current cycle phase ends.
     */
    function getCyclePhaseEndTime() public view returns (uint256) {
        return cyclePhaseEndTime;
    }


    /**
     * @dev Returns details of a specific project proposal.
     * @param proposalId The ID of the project proposal.
     */
    function getProjectProposalDetails(uint256 proposalId) public view returns (
        uint256 id,
        address proposer,
        string memory title,
        string memory description,
        uint256 requestedAmount,
        Milestone[] memory milestones,
        ProposalStatus status,
        uint256 submittedCycle,
        uint256 yesVotes,
        uint256 noVotes,
        uint256 fundsDistributed,
        uint256 projectCompletionTime
    ) {
        ProjectProposal storage proposal = projectProposals[proposalId];
        require(proposal.id != 0, "DACF: Project proposal does not exist");

        // Need to copy milestones array from storage to memory for view function return
        Milestone[] memory milestonesMemory = new Milestone[](proposal.milestones.length);
        for (uint i = 0; i < proposal.milestones.length; i++) {
            milestonesMemory[i] = proposal.milestones[i];
        }

        return (
            proposal.id,
            proposal.proposer,
            proposal.title,
            proposal.description,
            proposal.requestedAmount,
            milestonesMemory,
            proposal.status,
            proposal.submittedCycle,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.fundsDistributed,
            proposal.projectCompletionTime
        );
    }

    /**
     * @dev Returns the status of a specific project proposal.
     * @param proposalId The ID of the project proposal.
     */
    function getProjectProposalStatus(uint256 proposalId) public view returns (ProposalStatus) {
        require(projectProposals[proposalId].id != 0, "DACF: Project proposal does not exist");
        return projectProposals[proposalId].status;
    }

     /**
     * @dev Returns the current vote counts for a project proposal.
     * @param proposalId The ID of the project proposal.
     */
    function getProjectProposalVoteCount(uint256 proposalId) public view returns (uint256 yesVotes, uint256 noVotes) {
        require(projectProposals[proposalId].id != 0, "DACF: Project proposal does not exist");
        return (projectProposals[proposalId].yesVotes, projectProposals[proposalId].noVotes);
    }


    /**
     * @dev Returns details of a specific config proposal.
     * @param proposalId The ID of the config proposal.
     */
    function getConfigProposalDetails(uint256 proposalId) public view returns (
        uint256 id,
        address proposer,
        FundConfig memory newConfig,
        ProposalStatus status,
        uint256 submittedCycle,
        uint256 yesVotes,
        uint256 noVotes
    ) {
        ConfigProposal storage proposal = configProposals[proposalId];
        require(proposal.id != 0, "DACF: Config proposal does not exist");

        return (
            proposal.id,
            proposal.proposer,
            proposal.newConfig,
            proposal.status,
            proposal.submittedCycle,
            proposal.yesVotes,
            proposal.noVotes
        );
    }

    /**
     * @dev Returns the status of a specific config proposal.
     * @param proposalId The ID of the config proposal.
     */
    function getConfigProposalStatus(uint256 proposalId) public view returns (ProposalStatus) {
        require(configProposals[proposalId].id != 0, "DACF: Config proposal does not exist");
        return configProposals[proposalId].status;
    }

    /**
     * @dev Returns the current vote counts for a config proposal.
     * @param proposalId The ID of the config proposal.
     */
    function getConfigProposalVoteCount(uint256 proposalId) public view returns (uint256 yesVotes, uint256 noVotes) {
        require(configProposals[proposalId].id != 0, "DACF: Config proposal does not exist");
        return (configProposals[proposalId].yesVotes, configProposals[proposalId].noVotes);
    }


    /**
     * @dev Returns the status of a specific project milestone.
     * @param proposalId The ID of the project proposal.
     * @param milestoneIndex The index of the milestone.
     */
    function getMilestoneStatus(uint256 proposalId, uint256 milestoneIndex) public view returns (MilestoneStatus) {
        ProjectProposal storage proposal = projectProposals[proposalId];
        require(proposal.id != 0, "DACF: Project proposal does not exist");
        require(milestoneIndex < proposal.milestones.length, "DACF: Invalid milestone index");
        return proposal.milestones[milestoneIndex].status;
    }

    /**
     * @dev Returns the current vote counts for a milestone verification.
     * @param proposalId The ID of the project proposal.
     * @param milestoneIndex The index of the milestone.
     */
    function getMilestoneVerificationVoteCount(uint256 proposalId, uint256 milestoneIndex) public view returns (uint256 yesVotes, uint256 noVotes) {
        ProjectProposal storage proposal = projectProposals[proposalId];
        require(proposal.id != 0, "DACF: Project proposal does not exist");
        require(milestoneIndex < proposal.milestones.length, "DACF: Invalid milestone index");
         Milestone storage milestone = proposal.milestones[milestoneIndex];
        return (milestone.yesVotes, milestone.noVotes);
    }


    /**
     * @dev Returns the current fund configuration parameters.
     */
    function getConfig() public view returns (FundConfig memory) {
        return config;
    }

     /**
     * @dev Checks if a participant has voted on a specific project proposal in the current cycle.
     * @param proposalId The ID of the project proposal.
     * @param voter The address to check.
     */
    function hasVotedOnProjectProposal(uint256 proposalId, address voter) public view returns (bool) {
        return projectVotes[proposalId][voter];
    }

     /**
     * @dev Checks if a participant has voted on a specific config proposal in the current cycle.
     * @param proposalId The ID of the config proposal.
     * @param voter The address to check.
     */
    function hasVotedOnConfigProposal(uint256 proposalId, address voter) public view returns (bool) {
        return configVotes[proposalId][voter];
    }

     /**
     * @dev Checks if a participant has voted on a specific milestone verification.
     * @param proposalId The ID of the project proposal.
     * @param milestoneIndex The index of the milestone.
     * @param voter The address to check.
     */
    function hasVotedOnMilestoneVerification(uint256 proposalId, uint256 milestoneIndex, address voter) public view returns (bool) {
        return milestoneVerificationVotes[proposalId][milestoneIndex][voter];
    }

    /**
     * @dev Returns the amount of ETH allocated to a project but not yet released.
     * @param proposalId The ID of the project proposal.
     */
    function getAllocatedProjectFunds(uint256 proposalId) public view returns (uint256) {
        return allocatedProjectFunds[proposalId];
    }

    /**
     * @dev Returns the amount of ETH contributed by a specific funder.
     * @param funder The address of the funder.
     */
    function getFunderContribution(address funder) public view returns (uint256) {
        return funders[funder];
    }

    /**
     * @dev Returns the number of project proposals submitted so far.
     */
    function getProjectProposalCount() public view returns (uint256) {
        return projectProposalCounter - 1; // Counter starts at 1
    }

     /**
     * @dev Returns the number of config proposals submitted so far.
     */
    function getConfigProposalCount() public view returns (uint256) {
        return configProposalCounter - 1; // Counter starts at 1
    }

    /**
     * @dev Returns the end time for milestone verification voting for a specific milestone.
     * @param proposalId The ID of the project proposal.
     * @param milestoneIndex The index of the milestone.
     */
    function getMilestoneVerificationEndTime(uint256 proposalId, uint256 milestoneIndex) public view returns (uint256) {
        ProjectProposal storage proposal = projectProposals[proposalId];
        require(proposal.id != 0, "DACF: Project proposal does not exist");
        require(milestoneIndex < proposal.milestones.length, "DACF: Invalid milestone index");
         // The contract only tracks the last vote end time set.
         // A more complex system would need a mapping per milestone.
        return proposal.lastMilestoneVoteEndTime; // Simplified: returns the last set end time on the proposal
    }

    /**
     * @dev Returns the total funds distributed to a project so far.
     * @param proposalId The ID of the project proposal.
     */
    function getProjectFundsDistributed(uint256 proposalId) public view returns (uint256) {
         require(projectProposals[proposalId].id != 0, "DACF: Project proposal does not exist");
         return projectProposals[proposalId].fundsDistributed;
    }


    // Adding check for 20+ public/external functions:
    // 1. constructor (1)
    // 2. contribute (2)
    // 3. withdrawContribution (3)
    // 4. submitProjectProposal (4)
    // 5. voteOnProjectProposal (5)
    // 6. submitMilestoneCompletionProof (6)
    // 7. requestMilestonePayment (7)
    // 8. voteToVerifyMilestone (8)
    // 9. reportProjectFailure (9)
    // 10. proposeConfigChange (10)
    // 11. voteOnConfigChange (11)
    // 12. startNextFundingCyclePhase (12)

    // View Functions:
    // 13. getFundBalance (13)
    // 14. getReputation (14)
    // 15. getTotalReputation (15)
    // 16. getVotingPower (16)
    // 17. getCurrentFundingCycle (17)
    // 18. getCurrentCyclePhase (18)
    // 19. getCyclePhaseEndTime (19)
    // 20. getProjectProposalDetails (20)
    // 21. getProjectProposalStatus (21)
    // 22. getProjectProposalVoteCount (22)
    // 23. getConfigProposalDetails (23)
    // 24. getConfigProposalStatus (24)
    // 25. getConfigProposalVoteCount (25)
    // 26. getMilestoneStatus (26)
    // 27. getMilestoneVerificationVoteCount (27)
    // 28. getConfig (28)
    // 29. hasVotedOnProjectProposal (29)
    // 30. hasVotedOnConfigProposal (30)
    // 31. hasVotedOnMilestoneVerification (31)
    // 32. getAllocatedProjectFunds (32)
    // 33. getFunderContribution (33)
    // 34. getProjectProposalCount (34)
    // 35. getConfigProposalCount (35)
    // 36. getMilestoneVerificationEndTime (36)
    // 37. getProjectFundsDistributed (37)

    // Total public/external functions: 37. Requirement of >= 20 is met.

}
```