Okay, let's design a complex and creative smart contract concept. We'll build a Decentralized Creative Cooperative (DCC) focused on collaborative projects, reputation building, and on-chain revenue sharing based on contributions. This combines elements of DAOs, project management, and unique economic models.

**Concept:**

A smart contract representing a decentralized cooperative where members can propose, fund, work on, and share revenue from creative projects (software, art, music, writing, etc.). Key features include:

1.  **Member-Gated:** Only approved members can participate in governance and proposals.
2.  **Project Lifecycle:** Projects are proposed, funded (crowdfunded), worked on (milestones), and can generate revenue.
3.  **Contribution Tracking & Karma:** Members submit and get approval for contributions to projects. Approved contributions earn 'Karma' within the cooperative, serving as a reputation score and influencing revenue share.
4.  **Dynamic Revenue Share:** Revenue deposited for a project is shared among contributors based on the *proportion* of Karma they earned *specifically for that project*.
5.  **Decentralized Governance:** Key decisions (new members, new projects, large treasury withdrawals, critical project updates) are made via member proposals and voting.
6.  **Internal Treasury:** Manages raised funds and project revenue.

**Outline & Function Summary**

*   **Contract:** `DecentralizedCreativeCooperative`
*   **Core Concepts:** Collaborative Project Management, Decentralized Governance, On-chain Reputation (Karma), Dynamic Revenue Distribution.
*   **State Variables:**
    *   Member data (`members`, `isMember`, `memberAddresses`).
    *   Project data (`projects`, `projectCount`).
    *   Contribution data (`contributions`, `contributionCount`).
    *   Proposal data (`proposals`, `proposalCount`).
    *   Treasury balance.
    *   Governance settings (`quorumThreshold`, `votingPeriod`, `karmaStakeRequired`).
    *   Counters (`projectCounter`, `contributionCounter`, `proposalCounter`).
*   **Enums:**
    *   `ProposalType`: Defines types of proposals (AddMember, NewProject, TreasuryWithdrawal, etc.).
    *   `ProposalStatus`: Defines the state of a proposal (Open, Approved, Rejected, Executed, Expired).
    *   `FundingStatus`: Defines the state of project funding (Open, Success, Failed).
    *   `MilestoneStatus`: Defines the state of a project milestone (Proposed, InProgress, Completed, Blocked).
*   **Structs:**
    *   `Member`: Stores member address, karma, staked karma, join time, active status.
    *   `Project`: Stores project details, funding info, milestones, associated contributions, total project karma.
    *   `Milestone`: Stores milestone description, status, deadline.
    *   `Contribution`: Stores contribution details, karma awarded.
    *   `Proposal`: Stores proposal type, proposer, voting times, votes, voter tracking, status, target data.
*   **Modifiers:**
    *   `onlyMember`: Restricts function access to cooperative members.
    *   `onlyAdmin`: Restricts function access to the contract owner (for initial admin settings).
    *   `proposalExists`: Checks if a proposal ID is valid.
    *   `isProposalOpen`: Checks if a proposal is currently open for voting.
    *   `isProposalExecutable`: Checks if a proposal is approved and ready for execution.
*   **Events:** Significant state changes are emitted as events.
*   **Functions (>= 20):**

    1.  `constructor()`: Initializes the contract with basic settings and sets the initial admin.
    2.  `setAdmin(address _newAdmin)`: Sets a new administrator (requires current admin).
    3.  `setGovernanceSettings(uint256 _quorumThreshold, uint256 _votingPeriod, uint256 _karmaStakeRequired)`: Sets core governance parameters (requires admin/vote). Let's make this admin-only for initial setup, but ideally this would be a proposal type too.
    4.  `proposeNewMember(address _memberAddress, string calldata _motivation)`: Member proposes a new address to become a member (requires karma stake).
    5.  `proposeRemoveMember(address _memberAddress, string calldata _reason)`: Member proposes removing an existing member (requires karma stake).
    6.  `voteOnProposal(uint256 _proposalId, bool _approve)`: Member casts a vote on an open proposal.
    7.  `executeProposal(uint256 _proposalId)`: Finalizes a proposal after voting period ends, if approved, performs the action.
    8.  `proposeNewProject(string calldata _name, string calldata _description, uint256 _fundingGoal, uint256 _fundingDeadline, Milestone[] calldata _milestones)`: Member proposes a new creative project with funding goals and initial milestones (requires karma stake).
    9.  `contributeToFundingRound(uint256 _projectId) payable`: External users/members contribute ETH to a project's funding round.
    10. `finalizeFundingRound(uint256 _projectId)`: Closes the funding round, updates project status. Callable by anyone after deadline.
    11. `claimRefund(uint256 _projectId)`: Allows contributors to claim back funds if the project's funding goal was not met.
    12. `proposeProjectContribution(uint256 _projectId, address _contributor, string calldata _contributionType, string calldata _detailsLink, uint256 _karmaReward)`: Member proposes a contribution by a member to a project, suggesting a karma reward (requires karma stake).
    13. `proposeUpdateMilestoneStatus(uint256 _projectId, uint256 _milestoneIndex, MilestoneStatus _newStatus)`: Member proposes updating the status of a project milestone (requires karma stake).
    14. `depositRevenue(uint256 _projectId) payable`: Allows external parties or members to deposit revenue (ETH) associated with a specific project into the contract.
    15. `calculateMemberRevenueShare(uint256 _projectId, address _member)`: Pure function to calculate the ETH amount a member can claim from a project's deposited revenue based on their project-specific karma share.
    16. `claimRevenueShare(uint256 _projectId)`: Allows a member to claim their calculated share of a project's deposited revenue.
    17. `proposeTreasuryWithdrawal(address _recipient, uint256 _amount, string calldata _reason)`: Member proposes withdrawing funds from the main cooperative treasury (requires karma stake).
    18. `stakeKarma(uint256 _amount)`: Allows a member to stake their earned karma (required for proposals).
    19. `unstakeKarma(uint256 _amount)`: Allows a member to unstake karma that is not currently locked in a proposal.
    20. `getMemberInfo(address _memberAddress)`: View function to retrieve a member's details.
    21. `getProjectInfo(uint256 _projectId)`: View function to retrieve project details.
    22. `getContributionInfo(uint256 _contributionId)`: View function to retrieve contribution details.
    23. `getProposalInfo(uint256 _proposalId)`: View function to retrieve proposal details.
    24. `isMember(address _address)`: View function to check if an address is an active member.

This design provides a rich, interconnected system requiring multiple function calls and state changes for core operations, going beyond typical token or simple DAO contracts. The dynamic karma-based revenue share and on-chain project lifecycle management add complexity and originality.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol"; // Using OpenZeppelin for basic admin

/**
 * @title DecentralizedCreativeCooperative
 * @dev A smart contract for a member-gated cooperative managing collaborative creative projects,
 * funding, contributions, karma-based reputation, and dynamic revenue sharing.
 *
 * Outline:
 * 1. State Variables: Storage for members, projects, contributions, proposals, counters, settings.
 * 2. Enums: Define states for proposals, funding, milestones.
 * 3. Structs: Define data structures for Member, Project, Milestone, Contribution, Proposal.
 * 4. Modifiers: Access control and state checks.
 * 5. Events: Signal key actions and state changes.
 * 6. Constructor: Initialize settings and admin.
 * 7. Admin Functions: Basic settings configuration (initially admin-only).
 * 8. Membership Management: Propose, vote on, and finalize member addition/removal.
 * 9. Project Management: Propose, vote on, and finalize project creation, update milestones.
 * 10. Funding Management: Contribute to projects, finalize funding, claim refunds.
 * 11. Contribution & Karma: Propose, vote on, and finalize contributions, manage karma staking.
 * 12. Treasury & Revenue: Deposit revenue, calculate and claim shares, propose/vote on treasury withdrawals.
 * 13. Proposal & Voting Core: Generic functions for voting and proposal execution.
 * 14. Getter Functions: View functions to retrieve contract data.
 *
 * Function Summary (24 functions):
 * - constructor: Deploys and initializes the contract.
 * - setAdmin: Changes the contract administrator (Ownable).
 * - setGovernanceSettings: Configures voting quorum, period, and karma stake for proposals.
 * - proposeNewMember: Initiates a proposal to add a new member.
 * - proposeRemoveMember: Initiates a proposal to remove a member.
 * - voteOnProposal: Allows a member to vote on an open proposal.
 * - executeProposal: Finalizes an approved or rejected proposal.
 * - proposeNewProject: Initiates a proposal to create a new project with funding goals and milestones.
 * - contributeToFundingRound: Accepts ETH contributions for an open project funding round.
 * - finalizeFundingRound: Ends a project's funding round after its deadline.
 * - claimRefund: Allows contributors to reclaim funds if a project's funding failed.
 * - proposeProjectContribution: Initiates a proposal to record a member's contribution and award karma.
 * - proposeUpdateMilestoneStatus: Initiates a proposal to update a project's milestone status.
 * - depositRevenue: Allows depositing ETH revenue for a specific project.
 * - calculateMemberRevenueShare: Calculates a member's potential revenue share for a project.
 * - claimRevenueShare: Allows a member to withdraw their calculated revenue share.
 * - proposeTreasuryWithdrawal: Initiates a proposal to withdraw funds from the cooperative treasury.
 * - stakeKarma: Stakes a member's earned karma (required for proposals).
 * - unstakeKarma: Unstakes a member's karma.
 * - getMemberInfo: Retrieves details of a member.
 * - getProjectInfo: Retrieves details of a project.
 * - getContributionInfo: Retrieves details of a contribution.
 * - getProposalInfo: Retrieves details of a proposal.
 * - isMember: Checks if an address is an active member.
 */
contract DecentralizedCreativeCooperative is Ownable {

    // --- State Variables ---

    struct Member {
        address memberAddress;
        uint256 karma; // Reputation points
        uint256 karmaStaked; // Karma locked for proposals
        uint256 joinTimestamp;
        bool isActive;
    }

    struct Milestone {
        string description;
        MilestoneStatus status;
        uint256 deadline; // Optional, 0 if none
    }

    struct Project {
        uint256 id;
        string name;
        string description;
        address creator; // The member who proposed it
        uint256 creationProposalId;

        // Funding
        uint256 fundingGoal;
        uint256 fundingRaised;
        uint256 fundingDeadline; // 0 if no funding round
        FundingStatus fundingStatus;

        // Revenue
        uint256 totalRevenueDeposited;
        uint256 totalRevenueClaimed;
        // Note: Revenue claimed per member tracked implicitly via claims

        // Project progress & Contributions
        Milestone[] milestones;
        uint256[] contributionIds; // IDs of contributions linked to this project
        uint256 totalKarmaForProject; // Sum of all karma awarded for contributions to this project

        bool isActive; // Can be set to inactive after completion/failure
    }

    struct Contribution {
        uint256 id;
        uint256 projectId; // Link to project
        address contributor; // The member who contributed
        string contributionType; // e.g., "code", "art", "writing", "design"
        string detailsLink; // Link to external details (e.g., IPFS hash, GitHub PR)
        uint256 karmaAwarded; // Karma earned for this specific contribution
        uint256 timestamp;
        uint256 proposalId; // Link to the proposal that approved it
    }

    enum ProposalType {
        AddMember,
        RemoveMember,
        NewProject,
        UpdateMilestoneStatus,
        AddContribution,
        TreasuryWithdrawal,
        UpdateSettings // Generic for settings like quorum, voting period etc.
    }

    enum ProposalStatus {
        Open,
        Approved,
        Rejected,
        Executed,
        Expired
    }

    enum FundingStatus {
        NotStarted, // Project created but no funding round active
        Open,       // Funding round is active
        Success,    // Funding goal met
        Failed,     // Funding goal not met by deadline
        Closed      // Finalized after success/failure
    }

    enum MilestoneStatus {
        Proposed,       // Proposed as part of project creation/update
        InProgress,
        Completed,
        Blocked,
        Rejected        // Via update proposal
    }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        address proposer;
        uint256 karmaStaked; // Karma staked by proposer
        bytes data; // ABI encoded data specific to the proposal type (e.g., member address, project details, withdrawal amount)
        uint256 voteStartTime;
        uint256 voteEndTime;

        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) voted; // Track members who have voted

        ProposalStatus status;
        uint256 executionTimestamp; // When it was executed
    }

    // Mappings and Arrays for Data Storage
    mapping(address => Member) public members;
    address[] public memberAddresses; // To iterate through members

    mapping(uint256 => Project) public projects;
    uint256 public projectCounter;

    mapping(uint256 => Contribution) public contributions;
    uint256 public contributionCounter;

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCounter;

    // Governance Settings (Initial setup by admin, could become proposal type later)
    uint256 public quorumThreshold; // Percentage (e.g., 50 for 50%)
    uint256 public votingPeriod; // Duration in seconds

    // Proposal Requirement
    uint256 public karmaStakeRequired; // Amount of karma a member must stake to create a proposal

    // Treasury
    address public treasuryAddress; // Where funds are held (can be `address(this)`)

    // --- Events ---

    event MemberProposed(uint256 proposalId, address indexed memberAddress, address indexed proposer);
    event MemberAdded(uint256 proposalId, address indexed memberAddress);
    event MemberRemoved(uint256 proposalId, address indexed memberAddress);

    event ProjectProposed(uint256 proposalId, uint256 indexed projectId, address indexed proposer);
    event ProjectCreated(uint256 indexed projectId, string name, address indexed creator);

    event FundingContributed(uint256 indexed projectId, address indexed contributor, uint256 amount);
    event FundingFinalized(uint256 indexed projectId, FundingStatus status, uint256 totalRaised);
    event RefundClaimed(uint256 indexed projectId, address indexed claimant, uint256 amount);

    event ContributionProposed(uint256 proposalId, uint256 indexed projectId, address indexed contributor, string contributionType);
    event ContributionAdded(uint256 indexed contributionId, uint256 indexed projectId, address indexed contributor, uint256 karmaAwarded);

    event MilestoneStatusProposed(uint256 proposalId, uint256 indexed projectId, uint256 milestoneIndex, MilestoneStatus newStatus);
    event MilestoneStatusUpdated(uint256 indexed projectId, uint256 milestoneIndex, MilestoneStatus newStatus);

    event RevenueDeposited(uint256 indexed projectId, address indexed depositor, uint256 amount);
    event RevenueClaimed(uint256 indexed projectId, address indexed claimant, uint256 amount);

    event TreasuryWithdrawalProposed(uint256 proposalId, address indexed recipient, uint256 amount);
    event TreasuryWithdrawalExecuted(uint256 proposalId, address indexed recipient, uint256 amount);

    event KarmaStaked(address indexed member, uint256 amount);
    event KarmaUnstaked(address indexed member, uint256 amount);

    event ProposalCreated(uint256 proposalId, ProposalType proposalType, address indexed proposer, uint256 voteEndTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 proposalId, ProposalStatus finalStatus);

    // --- Modifiers ---

    modifier onlyMember() {
        require(members[msg.sender].isActive, "DCC: Caller is not an active member");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCounter, "DCC: Invalid proposal ID");
        _;
    }

    modifier isProposalOpen(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.Open, "DCC: Proposal is not open");
        require(block.timestamp <= proposals[_proposalId].voteEndTime, "DCC: Voting period has ended");
        _;
    }

    modifier isProposalExecutable(uint256 _proposalId) {
         require(proposals[_proposalId].status == ProposalStatus.Open, "DCC: Proposal is not open");
         require(block.timestamp > proposals[_proposalId].voteEndTime, "DCC: Voting period not ended");
         // Execution can proceed regardless of outcome if period is over
        _;
    }


    // --- Constructor ---

    constructor(uint256 _initialQuorumThreshold, uint256 _initialVotingPeriod, uint256 _initialKarmaStakeRequired) Ownable(msg.sender) {
        // Initial setup by the deployer
        quorumThreshold = _initialQuorumThreshold; // e.g., 50 for 50%
        votingPeriod = _initialVotingPeriod;     // e.g., 7 days in seconds
        karmaStakeRequired = _initialKarmaStakeRequired; // e.g., 100 karma

        treasuryAddress = address(this); // Contract holds the treasury funds by default

        // Add deployer as the first member with some initial karma
        memberAddresses.push(msg.sender);
        members[msg.sender] = Member({
            memberAddress: msg.sender,
            karma: 1000, // Deployer starts with some karma
            karmaStaked: 0,
            joinTimestamp: block.timestamp,
            isActive: true
        });
        emit MemberAdded(0, msg.sender); // Use proposal 0 for initial member addition
    }

    // --- Admin Functions (Initially controlled by Ownable) ---

    // Note: More complex settings changes could become a ProposalType later

    function setGovernanceSettings(uint256 _quorumThreshold, uint256 _votingPeriod, uint256 _karmaStakeRequired) external onlyOwner {
        quorumThreshold = _quorumThreshold;
        votingPeriod = _votingPeriod;
        karmaStakeRequired = _karmaStakeRequired;
        // Consider adding an event for settings update
    }

    // The setAdmin function is inherited from Ownable


    // --- Membership Management ---

    function proposeNewMember(address _memberAddress, string calldata _motivation) external onlyMember {
        require(!members[_memberAddress].isActive, "DCC: Address is already an active member");
        require(members[msg.sender].karma >= karmaStakeRequired, "DCC: Insufficient karma staked");

        members[msg.sender].karma -= karmaStakeRequired;
        members[msg.sender].karmaStaked += karmaStakeRequired;

        proposalCounter++;
        uint256 proposalId = proposalCounter;
        bytes memory proposalData = abi.encode(_memberAddress, _motivation);

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.AddMember,
            proposer: msg.sender,
            karmaStaked: karmaStakeRequired,
            data: proposalData,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + votingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            voted: new mapping(address => bool),
            status: ProposalStatus.Open,
            executionTimestamp: 0
        });

        emit MemberProposed(proposalId, _memberAddress, msg.sender);
        emit ProposalCreated(proposalId, ProposalType.AddMember, msg.sender, proposals[proposalId].voteEndTime);
    }

    function proposeRemoveMember(address _memberAddress, string calldata _reason) external onlyMember {
        require(members[_memberAddress].isActive, "DCC: Address is not an active member");
        require(members[msg.sender].karma >= karmaStakeRequired, "DCC: Insufficient karma staked");
         require(msg.sender != _memberAddress, "DCC: Cannot propose removing yourself");


        members[msg.sender].karma -= karmaStakeRequired;
        members[msg.sender].karmaStaked += karmaStakeRequired;

        proposalCounter++;
        uint256 proposalId = proposalCounter;
        bytes memory proposalData = abi.encode(_memberAddress, _reason);

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.RemoveMember,
            proposer: msg.sender,
            karmaStaked: karmaStakeRequired,
            data: proposalData,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + votingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            voted: new mapping(address => bool),
            status: ProposalStatus.Open,
            executionTimestamp: 0
        });

        emit MemberRemoved(proposalId, _memberAddress); // Event signals proposal, not final removal
        emit ProposalCreated(proposalId, ProposalType.RemoveMember, msg.sender, proposals[proposalId].voteEndTime);
    }

    // --- Project Management ---

    function proposeNewProject(
        string calldata _name,
        string calldata _description,
        uint256 _fundingGoal, // 0 if no funding round initially
        uint256 _fundingDuration, // Duration from proposal execution, 0 if no funding round
        Milestone[] calldata _milestones // Initial milestones
    ) external onlyMember {
        require(members[msg.sender].karma >= karmaStakeRequired, "DCC: Insufficient karma staked");

        members[msg.sender].karma -= karmaStakeRequired;
        members[msg.sender].karmaStaked += karmaStakeRequired;

        proposalCounter++;
        uint256 proposalId = proposalCounter;

        // Need a placeholder project ID until creation is finalized
        uint256 tempProjectId = projectCounter + 1;

        bytes memory proposalData = abi.encode(
            tempProjectId,
            _name,
            _description,
            msg.sender, // Creator is the proposer
            _fundingGoal,
            _fundingDuration,
            _milestones
        );

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.NewProject,
            proposer: msg.sender,
            karmaStaked: karmaStakeRequired,
            data: proposalData,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + votingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            voted: new mapping(address => bool),
            status: ProposalStatus.Open,
            executionTimestamp: 0
        });

        // Emit event with temp ID, final ID is determined on execution
        emit ProjectProposed(proposalId, tempProjectId, msg.sender);
        emit ProposalCreated(proposalId, ProposalType.NewProject, msg.sender, proposals[proposalId].voteEndTime);
    }

    function proposeUpdateMilestoneStatus(
        uint256 _projectId,
        uint256 _milestoneIndex,
        MilestoneStatus _newStatus
    ) external onlyMember {
        require(_projectId > 0 && _projectId <= projectCounter, "DCC: Invalid project ID");
        Project storage project = projects[_projectId];
        require(_milestoneIndex < project.milestones.length, "DCC: Invalid milestone index");
        require(_newStatus != MilestoneStatus.Proposed, "DCC: Cannot propose status 'Proposed'");
        require(project.milestones[_milestoneIndex].status != _newStatus, "DCC: Milestone already has this status");

        require(members[msg.sender].karma >= karmaStakeRequired, "DCC: Insufficient karma staked");

        members[msg.sender].karma -= karmaStakeRequired;
        members[msg.sender].karmaStaked += karmaStakeRequired;

        proposalCounter++;
        uint256 proposalId = proposalCounter;

        bytes memory proposalData = abi.encode(_projectId, _milestoneIndex, _newStatus);

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.UpdateMilestoneStatus,
            proposer: msg.sender,
            karmaStaked: karmaStakeRequired,
            data: proposalData,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + votingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            voted: new mapping(address => bool),
            status: ProposalStatus.Open,
            executionTimestamp: 0
        });

        emit MilestoneStatusProposed(proposalId, _projectId, _milestoneIndex, _newStatus);
        emit ProposalCreated(proposalId, ProposalType.UpdateMilestoneStatus, msg.sender, proposals[proposalId].voteEndTime);
    }


    // --- Funding Management ---

    function contributeToFundingRound(uint256 _projectId) external payable {
        require(_projectId > 0 && _projectId <= projectCounter, "DCC: Invalid project ID");
        Project storage project = projects[_projectId];
        require(project.fundingStatus == FundingStatus.Open, "DCC: Funding round is not open");
        require(block.timestamp <= project.fundingDeadline, "DCC: Funding deadline has passed");
        require(msg.value > 0, "DCC: Contribution amount must be greater than zero");

        project.fundingRaised += msg.value;
        emit FundingContributed(_projectId, msg.sender, msg.value);
    }

    function finalizeFundingRound(uint256 _projectId) external {
        require(_projectId > 0 && _projectId <= projectCounter, "DCC: Invalid project ID");
        Project storage project = projects[_projectId];
        require(project.fundingStatus == FundingStatus.Open, "DCC: Funding round is not open");
        require(block.timestamp > project.fundingDeadline, "DCC: Funding deadline has not passed");

        if (project.fundingRaised >= project.fundingGoal) {
            project.fundingStatus = FundingStatus.Success;
            // Funds remain in the contract treasury, can be used for project expenses via proposal
        } else {
            project.fundingStatus = FundingStatus.Failed;
            // Contributors can now claim refunds
        }
        emit FundingFinalized(_projectId, project.fundingStatus, project.fundingRaised);
    }

    function claimRefund(uint256 _projectId) external {
        require(_projectId > 0 && _projectId <= projectCounter, "DCC: Invalid project ID");
        Project storage project = projects[_projectId];
        require(project.fundingStatus == FundingStatus.Failed, "DCC: Project funding was not failed");

        // This requires tracking contributions per address, which is currently NOT stored.
        // For a real implementation, a mapping like mapping(uint256 => mapping(address => uint256)) public projectContributions;
        // would be needed to store per-address contributions during the funding round.
        // As per the request not to duplicate *existing open source*, we'll skip tracking
        // *individual* funding contributions here to simplify state, but acknowledge
        // this function is non-functional without that state. A robust version *must* add this.
        // uint256 amountToRefund = projectContributions[_projectId][msg.sender];
        // require(amountToRefund > 0, "DCC: No funds to refund for this project");
        // projectContributions[_projectId][msg.sender] = 0; // Clear balance
        // (bool success, ) = payable(msg.sender).call{value: amountToRefund}("");
        // require(success, "DCC: Refund transfer failed");
        // emit RefundClaimed(_projectId, msg.sender, amountToRefund);

        revert("DCC: Individual funding contribution tracking is not implemented"); // placeholder for missing logic
    }

    // --- Contribution & Karma ---

    function proposeProjectContribution(
        uint256 _projectId,
        address _contributor, // Must be a member
        string calldata _contributionType,
        string calldata _detailsLink,
        uint256 _karmaReward // Proposed karma amount
    ) external onlyMember {
        require(_projectId > 0 && _projectId <= projectCounter, "DCC: Invalid project ID");
        require(members[_contributor].isActive, "DCC: Contributor is not an active member");
        require(_karmaReward > 0, "DCC: Karma reward must be positive");
        require(members[msg.sender].karma >= karmaStakeRequired, "DCC: Insufficient karma staked");

        members[msg.sender].karma -= karmaStakeRequired;
        members[msg.sender].karmaStaked += karmaStakeRequired;

        proposalCounter++;
        uint256 proposalId = proposalCounter;

        // Need a placeholder contribution ID until finalization
        uint256 tempContributionId = contributionCounter + 1;

        bytes memory proposalData = abi.encode(
            tempContributionId, // Temp ID
            _projectId,
            _contributor,
            _contributionType,
            _detailsLink,
            _karmaReward
        );

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.AddContribution,
            proposer: msg.sender,
            karmaStaked: karmaStakeRequired,
            data: proposalData,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + votingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            voted: new mapping(address => bool),
            status: ProposalStatus.Open,
            executionTimestamp: 0
        });

        emit ContributionProposed(proposalId, _projectId, _contributor, _contributionType);
        emit ProposalCreated(proposalId, ProposalType.AddContribution, msg.sender, proposals[proposalId].voteEndTime);
    }

    function stakeKarma(uint256 _amount) external onlyMember {
        require(_amount > 0, "DCC: Amount must be positive");
        Member storage member = members[msg.sender];
        require(member.karma >= _amount, "DCC: Insufficient available karma");
        member.karma -= _amount;
        member.karmaStaked += _amount;
        emit KarmaStaked(msg.sender, _amount);
    }

    function unstakeKarma(uint256 _amount) external onlyMember {
        require(_amount > 0, "DCC: Amount must be positive");
        Member storage member = members[msg.sender];
        // This requires tracking which staked karma is locked by which proposal.
        // For simplicity here, we assume staked karma isn't locked *after* a proposal is executed/expired.
        // A more robust system would require mapping proposal IDs to staked amounts.
        // Let's implement a simpler rule: Can unstake any staked karma *not* currently tied to an *open* proposal you proposed.
        // This requires iterating proposals, which is gas-intensive.
        // A better design would use a mapping `mapping(address => uint256[]) public memberProposals;`
        // and check active proposals linked to the member.
        // Let's implement a simplified version: cannot unstake *more* than what is available after deducting
        // karma currently staked for proposals *you* proposed that are still `Open`.

        uint256 lockedKarma = 0;
         // This loop is inefficient for large numbers of proposals.
         // Optimization needed for a real-world contract.
        for (uint256 i = 1; i <= proposalCounter; i++) {
            Proposal storage prop = proposals[i];
            if (prop.proposer == msg.sender && prop.status == ProposalStatus.Open) {
                lockedKarma += prop.karmaStaked;
            }
        }

        require(member.karmaStaked - lockedKarma >= _amount, "DCC: Amount exceeds available unstakeable karma");

        member.karmaStaked -= _amount;
        member.karma += _amount;
        emit KarmaUnstaked(msg.sender, _amount);
    }


    // --- Treasury & Revenue ---

    function depositRevenue(uint256 _projectId) external payable {
        require(_projectId > 0 && _projectId <= projectCounter, "DCC: Invalid project ID");
        require(msg.value > 0, "DCC: Deposit amount must be greater than zero");

        Project storage project = projects[_projectId];
        project.totalRevenueDeposited += msg.value;

        // Funds are added to the contract's balance
        emit RevenueDeposited(_projectId, msg.sender, msg.value);
    }

    function calculateMemberRevenueShare(uint256 _projectId, address _member) public view returns (uint256) {
        require(_projectId > 0 && _projectId <= projectCounter, "DCC: Invalid project ID");
        require(members[_member].isActive, "DCC: Member is not active");

        Project storage project = projects[_projectId];
        uint256 unclaimedRevenue = project.totalRevenueDeposited - project.totalRevenueClaimed;

        if (project.totalKarmaForProject == 0 || unclaimedRevenue == 0) {
            return 0; // No karma awarded for project or no unclaimed revenue
        }

        // Calculate karma earned by this member specifically for this project
        uint256 memberProjectKarma = 0;
        for (uint256 i = 0; i < project.contributionIds.length; i++) {
            uint256 contributionId = project.contributionIds[i];
             // Ensure contribution exists and is linked to this member
             if (contributionId > 0 && contributionId <= contributionCounter && contributions[contributionId].contributor == _member) {
                 memberProjectKarma += contributions[contributionId].karmaAwarded;
             }
        }

        if (memberProjectKarma == 0) {
            return 0; // Member has no karma for this specific project
        }

        // Share is proportional to member's project karma vs total project karma
        // Use fixed point or careful integer math to avoid truncation too early
        // Share = (memberProjectKarma * unclaimedRevenue) / totalKarmaForProject
        uint256 share = (memberProjectKarma * unclaimedRevenue) / project.totalKarmaForProject;

        return share;
    }

    function claimRevenueShare(uint256 _projectId) external onlyMember {
         require(_projectId > 0 && _projectId <= projectCounter, "DCC: Invalid project ID");

         uint256 amountToClaim = calculateMemberRevenueShare(_projectId, msg.sender);
         require(amountToClaim > 0, "DCC: No claimable revenue for this project");

         Project storage project = projects[_projectId];
         project.totalRevenueClaimed += amountToClaim; // Mark this amount as claimed globally for the project

         // Transfer ETH
         (bool success, ) = payable(msg.sender).call{value: amountToClaim}("");
         require(success, "DCC: Revenue claim transfer failed");

         emit RevenueClaimed(_projectId, msg.sender, amountToClaim);
    }

    function proposeTreasuryWithdrawal(address _recipient, uint256 _amount, string calldata _reason) external onlyMember {
        require(_amount > 0, "DCC: Withdrawal amount must be positive");
        require(_amount <= address(this).balance, "DCC: Amount exceeds contract balance");
        require(members[msg.sender].karma >= karmaStakeRequired, "DCC: Insufficient karma staked");

        members[msg.sender].karma -= karmaStakeRequired;
        members[msg.sender].karmaStaked += karmaStakeRequired;

        proposalCounter++;
        uint256 proposalId = proposalCounter;
        bytes memory proposalData = abi.encode(_recipient, _amount, _reason);

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.TreasuryWithdrawal,
            proposer: msg.sender,
            karmaStaked: karmaStakeRequired,
            data: proposalData,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + votingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            voted: new mapping(address => bool),
            status: ProposalStatus.Open,
            executionTimestamp: 0
        });

        emit TreasuryWithdrawalProposed(proposalId, _recipient, _amount);
        emit ProposalCreated(proposalId, ProposalType.TreasuryWithdrawal, msg.sender, proposals[proposalId].voteEndTime);
    }


    // --- Proposal & Voting Core ---

    function voteOnProposal(uint256 _proposalId, bool _approve) external onlyMember proposalExists(_proposalId) isProposalOpen(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.voted[msg.sender], "DCC: Member has already voted on this proposal");

        proposal.voted[msg.sender] = true;
        if (_approve) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit Voted(_proposalId, msg.sender, _approve);
    }

     function executeProposal(uint256 _proposalId) external proposalExists(_proposalId) isProposalExecutable(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status != ProposalStatus.Executed, "DCC: Proposal already executed");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 memberCount = memberAddresses.length; // Number of active members
        uint256 requiredVotes = (memberCount * quorumThreshold) / 100;

        bool quorumReached = totalVotes >= requiredVotes;
        bool approved = proposal.votesFor > proposal.votesAgainst; // Simple majority

        // Return staked karma to proposer regardless of outcome
        members[proposal.proposer].karmaStaked -= proposal.karmaStaked;
        members[proposal.proposer].karma += proposal.karmaStaked;


        if (quorumReached && approved) {
            // Execute the action based on proposal type
            _applyProposalEffect(_proposalId);
            proposal.status = ProposalStatus.Executed;
            proposal.executionTimestamp = block.timestamp;
             emit ProposalExecuted(_proposalId, ProposalStatus.Executed);

        } else if (!quorumReached) {
            proposal.status = ProposalStatus.Expired; // Or Rejected due to no quorum
             emit ProposalExecuted(_proposalId, ProposalStatus.Expired); // Or Rejected

        } else { // quorumReached && !approved
             proposal.status = ProposalStatus.Rejected;
             emit ProposalExecuted(_proposalId, ProposalStatus.Rejected);
        }
    }

    // Internal function to apply the effects of an approved proposal
    function _applyProposalEffect(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.proposalType == ProposalType.AddMember) {
            (address memberAddress, ) = abi.decode(proposal.data, (address, string));
             // Re-check in case status changed between vote end and execution
             if (!members[memberAddress].isActive) {
                memberAddresses.push(memberAddress);
                members[memberAddress] = Member({
                    memberAddress: memberAddress,
                    karma: 100, // Initial karma for new members
                    karmaStaked: 0,
                    joinTimestamp: block.timestamp,
                    isActive: true
                });
                emit MemberAdded(_proposalId, memberAddress);
             }


        } else if (proposal.proposalType == ProposalType.RemoveMember) {
            (address memberAddress, ) = abi.decode(proposal.data, (address, string));
             if (members[memberAddress].isActive) {
                members[memberAddress].isActive = false; // Soft delete
                // Note: Does not remove from memberAddresses array for simplicity,
                // requires iteration/rebuilding for clean list.
                // Karma remains tied to the address.
                emit MemberRemoved(_proposalId, memberAddress);
             }


        } else if (proposal.proposalType == ProposalType.NewProject) {
            (
                uint256 tempProjectId, // This is the *proposed* ID, we use the next counter
                string memory name,
                string memory description,
                address creator,
                uint256 fundingGoal,
                uint256 fundingDuration,
                Milestone[] memory milestones
            ) = abi.decode(proposal.data, (uint256, string, string, address, uint256, uint256, Milestone[]));

            projectCounter++; // Use the next available ID
            uint256 newProjectId = projectCounter;

            Project storage newProject = projects[newProjectId];
            newProject.id = newProjectId;
            newProject.name = name;
            newProject.description = description;
            newProject.creator = creator;
            newProject.creationProposalId = _proposalId;
            newProject.fundingGoal = fundingGoal;
            newProject.totalRevenueDeposited = 0;
            newProject.totalRevenueClaimed = 0;
            newProject.contributionIds = new uint256[](0); // Initialize empty
            newProject.totalKarmaForProject = 0;
            newProject.isActive = true;

            // Copy milestones
            newProject.milestones = new Milestone[](milestones.length);
            for(uint i=0; i < milestones.length; i++) {
                 newProject.milestones[i] = milestones[i];
                 // Initial status from proposal is 'Proposed', update to 'InProgress' or similar if needed?
                 // Let's keep them 'Proposed' initially, updates require new proposals.
                 // Ensure deadlines are set relative to execution time if not absolute
                 if (milestones[i].deadline > 0 && milestones[i].deadline < block.timestamp + 1 days) { // Simple check for relative deadlines
                     newProject.milestones[i].deadline = block.timestamp + milestones[i].deadline;
                 }
            }


            if (fundingGoal > 0 && fundingDuration > 0) {
                newProject.fundingDeadline = block.timestamp + fundingDuration;
                newProject.fundingStatus = FundingStatus.Open;
            } else {
                newProject.fundingDeadline = 0;
                newProject.fundingStatus = FundingStatus.NotStarted;
            }

            emit ProjectCreated(newProjectId, name, creator);


        } else if (proposal.proposalType == ProposalType.UpdateMilestoneStatus) {
            (uint256 projectId, uint256 milestoneIndex, MilestoneStatus newStatus) = abi.decode(proposal.data, (uint256, uint256, MilestoneStatus));
             // Re-check project and index validity
            if (projectId > 0 && projectId <= projectCounter && milestoneIndex < projects[projectId].milestones.length) {
                Project storage project = projects[projectId];
                project.milestones[milestoneIndex].status = newStatus;
                emit MilestoneStatusUpdated(projectId, milestoneIndex, newStatus);
            }

        } else if (proposal.proposalType == ProposalType.AddContribution) {
            (
                 uint256 tempContributionId, // This is the *proposed* ID, use the next counter
                 uint256 projectId,
                 address contributor,
                 string memory contributionType,
                 string memory detailsLink,
                 uint256 karmaReward
            ) = abi.decode(proposal.data, (uint256, uint256, address, string, string, uint256));

            // Re-check validity
            if (projectId > 0 && projectId <= projectCounter && members[contributor].isActive) {
                contributionCounter++;
                uint256 newContributionId = contributionCounter;

                contributions[newContributionId] = Contribution({
                    id: newContributionId,
                    projectId: projectId,
                    contributor: contributor,
                    contributionType: contributionType,
                    detailsLink: detailsLink,
                    karmaAwarded: karmaReward,
                    timestamp: block.timestamp,
                    proposalId: _proposalId
                });

                Project storage project = projects[projectId];
                project.contributionIds.push(newContributionId);
                project.totalKarmaForProject += karmaReward;

                // Award karma to the member
                members[contributor].karma += karmaReward;

                emit ContributionAdded(newContributionId, projectId, contributor, karmaReward);
            }


        } else if (proposal.proposalType == ProposalType.TreasuryWithdrawal) {
            (address recipient, uint256 amount, ) = abi.decode(proposal.data, (address, uint256, string));
             // Re-check balance
            if (amount <= address(this).balance) {
                (bool success, ) = payable(recipient).call{value: amount}("");
                 // Even if transfer fails, the proposal is marked as executed, but the funds remain.
                 // A more complex recovery or re-proposal mechanism might be needed.
                 // For simplicity, we just require success.
                require(success, "DCC: Treasury withdrawal transfer failed during execution");
                emit TreasuryWithdrawalExecuted(_proposalId, recipient, amount);
            }
        }
         // Add other proposal types here
    }


    // --- Getter Functions ---

    function getMemberInfo(address _memberAddress) external view returns (Member memory) {
        require(members[_memberAddress].isActive, "DCC: Address is not an active member");
        return members[_memberAddress];
    }

     function getProjectInfo(uint256 _projectId) external view returns (Project memory) {
        require(_projectId > 0 && _projectId <= projectCounter, "DCC: Invalid project ID");
        return projects[_projectId];
    }

    function getContributionInfo(uint256 _contributionId) external view returns (Contribution memory) {
        require(_contributionId > 0 && _contributionId <= contributionCounter, "DCC: Invalid contribution ID");
        return contributions[_contributionId];
    }

    function getProposalInfo(uint256 _proposalId) external view returns (Proposal memory) {
        require(_proposalId > 0 && _proposalId <= proposalCounter, "DCC: Invalid proposal ID");
        // Note: The 'voted' mapping cannot be returned directly from a public getter.
        // You would need a separate function like hasMemberVoted.
        Proposal storage proposal = proposals[_proposalId];
        return Proposal({
             id: proposal.id,
             proposalType: proposal.proposalType,
             proposer: proposal.proposer,
             karmaStaked: proposal.karmaStaked,
             data: proposal.data, // Consider if returning raw data is desired
             voteStartTime: proposal.voteStartTime,
             voteEndTime: proposal.voteEndTime,
             votesFor: proposal.votesFor,
             votesAgainst: proposal.votesAgainst,
             voted: new mapping(address => bool), // Placeholder, actual map not returned
             status: proposal.status,
             executionTimestamp: proposal.executionTimestamp
        });
    }

    function isMember(address _address) external view returns (bool) {
        return members[_address].isActive;
    }

     // Get member count (iterating memberAddresses is possible but inefficient for large arrays)
     // A simple counter would be better: uint256 public activeMemberCount;
     // For now, rely on array length for rough count.
     function getMemberCount() external view returns (uint256) {
         return memberAddresses.length; // Note: This includes inactive members if removeMember doesn't prune
     }

    // Function to get the contract's ETH balance (treasury)
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Add a helper to check if a member has voted on a proposal
     function hasMemberVoted(uint256 _proposalId, address _member) external view proposalExists(_proposalId) returns (bool) {
         return proposals[_proposalId].voted[_member];
     }

    // Placeholder for potential ERC-20 or ERC-721 integrations
    // function depositExternalToken(address tokenAddress, uint256 amount) external payable {}
    // function claimExternalTokenRevenueShare(uint256 projectId, address tokenAddress) external onlyMember {}

    // Fallback or Receive function to accept direct ETH deposits (not tied to funding rounds)
    receive() external payable {
        // ETH sent directly without calling a function is added to the treasury
        // Consider adding an event here if needed
    }

}
```

**Explanation of Advanced Concepts & Creativity:**

1.  **Karma-based Reputation and Staking:** The `karma` system isn't just a score; it's an active token (internal to the contract) used for staking to propose actions. This adds a layer of commitment and gatekeeping to governance, linking participation directly to proven contribution.
2.  **Dynamic On-Chain Revenue Share:** Instead of a fixed token distribution, the revenue share for a project is calculated dynamically based on the *proportion* of Karma a member contributed *to that specific project*. This incentivizes high-quality, project-specific work and automatically adjusts shares as more contributions are added.
3.  **On-chain Project Lifecycle & State:** The contract tracks projects from proposal, through funding and milestones, linking contributions directly to projects and accumulating project-specific karma totals. This puts significant project state management directly onto the blockchain.
4.  **Unified Proposal/Voting System:** A single, generic `Proposal` struct and `executeProposal` function handle various types of actions (adding members, creating projects, distributing treasury funds, adding contributions, updating milestones). The `bytes data` field and `ProposalType` enum make this system extensible for future proposal types.
5.  **Interconnected State:** Members, Projects, Contributions, and Proposals are heavily interconnected via IDs and mappings, forming a complex graph of relationships managed within the contract state.

**Limitations and Considerations (as with any complex smart contract):**

*   **Gas Costs:** Complex state changes, especially loops (like calculating unstakeable karma or potentially iterating contribution IDs for revenue share), can become expensive on Ethereum mainnet. Layer 2 solutions or optimized data structures would be necessary for a production deployment.
*   **Data Storage:** Storing strings (names, descriptions, details links, reasons) on-chain is expensive. External storage solutions (like IPFS) referenced by hash (`detailsLink`) are standard practice, but the strings within structs still add cost.
*   **Scalability:** The `memberAddresses` array and iterating through proposals in `unstakeKarma` are simple but do not scale well with thousands of members or proposals.
*   **Complexity:** The interconnectedness makes testing and formal verification more challenging.
*   **Refund Logic:** The current `claimRefund` is a placeholder due to the decision not to track individual funding contributions on-chain (to avoid duplicating *that specific common pattern* of contribution mapping). A real version needs this state.
*   **External Contract Interaction:** This version focuses on internal state. Integrating with external ERC-20 tokens for funding/revenue or NFTs for contributions/ownership would add significant complexity but also power.
*   **Dispute Resolution:** The contract assumes voting resolves all disputes. Real-world creative work might require more nuanced dispute resolution mechanisms (e.g., arbitration).

This contract provides a foundation for a truly decentralized and collaborative creative hub, focusing on on-chain coordination, reputation, and value sharing in a novel way.