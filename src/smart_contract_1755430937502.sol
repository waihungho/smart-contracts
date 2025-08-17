This smart contract, "QuantumLeap DAO," is designed to be a decentralized autonomous organization focused on funding and coordinating ambitious, long-term, and potentially high-risk "Leaps" (projects) that aim for significant societal or scientific advancements. It moves beyond simple token-weighted voting by incorporating a unique, non-transferable reputation system and multi-stage project management.

---

## QuantumLeap DAO: Blueprint for Frontier Advancements

**Contract Name:** `QuantumLeapDAO`

**Purpose:** A decentralized autonomous organization (DAO) dedicated to funding, managing, and nurturing frontier research and development projects ("Leaps") that aim for transformative societal or scientific breakthroughs. It utilizes a hybrid governance model combining a utility token (`QLP`) with a non-transferable, earned reputation token (`QRL`) to foster meritocracy and long-term commitment.

---

### Outline

1.  **Core Components:**
    *   `QuantumLeapToken` (QLP): A standard ERC-20 utility token used for staking, incentives, and minor governance.
    *   `QuantumReputationLeap` (QRL): A *Soulbound Token (SBT)* equivalent, non-transferable, representing a member's earned reputation and primary voting power.
2.  **DAO Governance:**
    *   Proposal System: For funding Leaps, adjusting budgets, appointing Oracles, and DAO parameter changes.
    *   Reputation-Weighted Voting: Votes are primarily weighted by QRL.
    *   Quorum & Thresholds: Dynamic parameters for proposal success.
3.  **Project (Leap) Lifecycle Management:**
    *   Submission & Incubation: Formal proposal, initial DAO vote.
    *   Active Development: Milestone-based funding release.
    *   Review & Adjustment: Periodic reviews, budget adjustments via new proposals.
    *   Completion/Termination: Formal closure or early termination.
4.  **Reputation System (`QRL`):**
    *   Earning: Via successful project contributions, milestone approvals, oracle duties.
    *   Slashing: For malicious behavior or failed contributions.
    *   Delegation: QRL holders can delegate their reputation for specific votes.
    *   Dispute Resolution: Oracles play a key role.
5.  **Roles:**
    *   `Voyager`: General DAO member.
    *   `Pathfinder`: Lead of an approved Leap (project).
    *   `Oracle`: Elected members responsible for dispute resolution and milestone verification.
6.  **Treasury Management:**
    *   Receives funds (ETH/other tokens later).
    *   Disburses funds strictly based on approved milestones.

---

### Function Summary

**I. Core DAO Governance & Token Management**

1.  `constructor()`: Initializes the DAO, deploys QLP and QRL tokens, sets initial parameters.
2.  `updateDaoParameter(bytes32 _paramName, uint256 _newValue)`: Allows the DAO (via governance) to adjust core parameters (e.g., `proposalQuorum`, `votingPeriod`).
3.  `depositFunds(uint256 _amount)`: Allows any user to deposit QLP tokens into the DAO's treasury. Future expansion could include other ERC-20s.
4.  `withdrawDAOOperatingFunds(address _recipient, uint256 _amount)`: DAO-governed withdrawal of funds for operational expenses (e.g., auditing, legal fees), *not* project funding.

**II. Project (Leap) Lifecycle Management**

5.  `submitProjectProposal(string memory _detailsIPFSHash, uint256 _requestedQLPFunds, uint256 _incubationPeriod, Milestone[] memory _milestones)`: Allows any `Voyager` with minimum QRL to propose a new "Leap."
6.  `voteOnProposal(uint256 _proposalId, bool _support)`: Allows QRL holders to vote on active proposals, with their QRL balance determining vote weight.
7.  `finalizeProposal(uint256 _proposalId)`: Any member can call to finalize a proposal after its voting period ends, enacting the outcome.
8.  `submitMilestoneReport(uint256 _projectId, uint256 _milestoneIndex, string memory _reportIPFSHash)`: Called by a `Pathfinder` to submit a progress report for a milestone.
9.  `approveMilestone(uint256 _projectId, uint256 _milestoneIndex, bool _approved)`: Called by `Oracles` to vote on the approval of a submitted milestone. Multiple oracle approvals might be required.
10. `requestMilestonePayment(uint256 _projectId, uint256 _milestoneIndex)`: Called by a `Pathfinder` to request funds for an *approved* milestone. Funds are released from the DAO treasury.
11. `adjustProjectBudget(uint256 _projectId, uint256 _newBudget, string memory _reasonIPFSHash)`: Allows a `Pathfinder` to propose a budget adjustment for their active project (requires new DAO vote).
12. `initiateProjectReview(uint256 _projectId, string memory _reasonIPFSHash)`: Allows any `Voyager` to request a formal DAO review of a project's progress or conduct.

**III. Reputation (`QRL`) & Role Management**

13. `mintQRLForContribution(address _contributor, uint256 _amount, string memory _contributionHash)`: DAO-governed function to reward `QRL` (reputation) for significant contributions (e.g., successful project completion, valuable governance participation).
14. `burnQRLForMisconduct(address _offender, uint256 _amount, string memory _reasonHash)`: DAO-governed function to slash `QRL` for malicious behavior or severe project failures.
15. `delegateReputation(address _delegatee)`: Allows a `Voyager` to delegate their `QRL` voting power to another address.
16. `revokeReputationDelegation()`: Allows a `Voyager` to revoke their `QRL` delegation.
17. `registerOracle(address _oracleCandidate)`: Initiates a DAO proposal to appoint a new `Oracle`.
18. `removeOracle(address _oracleToRemove)`: Initiates a DAO proposal to remove an existing `Oracle`.
19. `challengeOracleDecision(uint256 _oracleDecisionId, string memory _challengeReasonIPFSHash)`: Allows `Voyagers` to formally challenge an Oracle's decision, triggering a DAO vote.

**IV. Advanced & Utility Functions**

20. `endorseProject(uint256 _projectId)`: Allows QRL holders to publicly "endorse" a project proposal, increasing its visibility and signaling pre-vote support. (No direct voting weight, but influences perception).
21. `submitStrategicInitiative(string memory _initiativeIPFSHash)`: Allows `Voyagers` to propose broad, non-project-specific strategic initiatives for the DAO (e.g., forming partnerships, new investment strategies).
22. `claimQLPForReputationStaking(uint256 _amount)`: Allows QRL holders to "stake" a portion of their *reputation* for a period, earning minor QLP rewards as an incentive for active participation. (This is a conceptual 'cognitive staking', not actual QRL token locking, but a commitment period tracked).
23. `viewProjectDetails(uint256 _projectId)`: Returns comprehensive details about a specific project.
24. `getUserReputation(address _user)`: Returns the QRL balance of a user.
25. `getProposalStatus(uint256 _proposalId)`: Returns the current status and voting results of a proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Custom ERC20 for QLP (QuantumLeap Points) ---
contract QuantumLeapToken is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("QuantumLeapPoints", "QLP") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

// --- QuantumReputationLeap (QRL) - Soulbound Token (SBT) equivalent ---
// This is an SBT-like system where QRL are non-transferable and represent reputation.
// For simplicity, we manage it as a mapping, simulating an ERC-721-like ID for each QRL point.
// In a full implementation, this could be a custom ERC721 that strictly disallows transfers.
contract QuantumReputationLeap is Context {
    mapping(address => uint256) private _reputations; // user => QRL balance
    mapping(address => address) private _delegates; // user => delegatee

    event ReputationMinted(address indexed to, uint256 amount);
    event ReputationBurned(address indexed from, uint256 amount);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ReputationDelegationRevoked(address indexed delegator);

    // This contract is meant to be managed by QuantumLeapDAO
    address public daoAddress;

    modifier onlyDAO() {
        require(msg.sender == daoAddress, "QRL: Only DAO can call this function");
        _;
    }

    constructor(address _daoAddress) {
        daoAddress = _daoAddress;
    }

    function setDaoAddress(address _newDaoAddress) public {
        require(daoAddress == address(0), "QRL: DAO address already set");
        daoAddress = _newDaoAddress;
    }

    function getReputation(address account) public view returns (uint256) {
        return _reputations[account];
    }

    function getDelegate(address account) public view returns (address) {
        return _delegates[account];
    }

    // --- DAO-controlled functions to manage reputation ---

    function mint(address to, uint256 amount) public onlyDAO {
        _reputations[to] += amount;
        emit ReputationMinted(to, amount);
    }

    function burn(address from, uint256 amount) public onlyDAO {
        require(_reputations[from] >= amount, "QRL: Insufficient reputation to burn");
        _reputations[from] -= amount;
        emit ReputationBurned(from, amount);
    }

    function delegate(address delegatee) public {
        require(delegatee != _msgSender(), "QRL: Cannot delegate to self");
        _delegates[_msgSender()] = delegatee;
        emit ReputationDelegated(_msgSender(), delegatee);
    }

    function revokeDelegation() public {
        require(_delegates[_msgSender()] != address(0), "QRL: No active delegation");
        delete _delegates[_msgSender()];
        emit ReputationDelegationRevoked(_msgSender());
    }

    // Returns effective reputation, considering delegation
    function getEffectiveReputation(address account) public view returns (uint256) {
        address delegatee = _delegates[account];
        if (delegatee != address(0)) {
            // If delegated, the delegatee's reputation is augmented by the delegator's
            // This simple model assumes the delegatee's *own* reputation is added to.
            // A more complex model might just pass the voting power directly.
            // For this advanced contract, we'll sum it up for the delegatee.
            return _reputations[account]; // The delegator loses direct voting power
        }
        return _reputations[account];
    }

    // A helper to get the total voting power including all delegated reputation *to* an address
    function getTotalVotingPower(address account) public view returns (uint256) {
        uint256 totalPower = _reputations[account];
        for (uint256 i = 0; i < 1000; i++) { // Max iterations to prevent gas issues in a real scenario
            // This is a simplified lookup. A real-world system would track delegations more efficiently.
            // For now, assume iteration over all users to find who delegated to `account`.
            // This is NOT scalable on-chain. Would need off-chain indexing or a different design.
            // For demonstration purposes, we'll just return the account's direct reputation.
            // The delegate function simply points the delegator's votes *to* the delegatee.
            // The actual voting function in DAO will check if `msg.sender` has delegated,
            // and if so, attribute the vote to the `delegatee`.
        }
        return totalPower;
    }
}

// --- Main QuantumLeap DAO Contract ---
contract QuantumLeapDAO is Ownable, ReentrancyGuard {
    QuantumLeapToken public qlpToken;
    QuantumReputationLeap public qrlToken;

    // --- DAO Parameters (governable) ---
    uint256 public proposalQuorumPercentage; // % of total QRL needed for a proposal to pass
    uint256 public proposalVoteThresholdPercentage; // % of 'yes' votes needed relative to total votes cast
    uint256 public votingPeriodDuration; // seconds
    uint256 public minQRLForProposal; // minimum QRL required to submit a proposal
    uint256 public minQRLToDelegate; // minimum QRL to be eligible as a delegatee
    uint256 public oracleApprovalThreshold; // number of oracles needed to approve a milestone

    // --- Enums ---
    enum ProposalType {
        ProjectFunding,
        BudgetAdjustment,
        OracleAppointment,
        ParameterChange,
        StrategicInitiative,
        ReputationChallenge,
        ProjectReview,
        ProjectTermination
    }

    enum ProposalStatus {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed,
        Canceled
    }

    enum ProjectStatus {
        Proposed,
        Incubating,
        Active,
        Paused,
        Completed,
        Terminated,
        Failed
    }

    // --- Structs ---
    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        address proposer;
        string detailsIPFSHash; // IPFS hash to detailed proposal description
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 yesVotes; // Total QRL for 'yes'
        uint256 noVotes; // Total QRL for 'no'
        mapping(address => bool) hasVoted; // User -> voted status
        ProposalStatus status;
        address targetAddress; // For OracleAppointment, ProjectTermination
        uint256 targetId; // For ProjectFunding, BudgetAdjustment, ReputationChallenge
        uint255 value; // For budget changes, funds to transfer
        bytes data; // For parameter changes (encoded function call)
        // Additional fields for specific proposal types can be packed or derived from detailsIPFSHash
    }

    struct Milestone {
        string descriptionIPFSHash;
        uint256 targetDate; // Unix timestamp
        uint256 budgetAllocation; // QLP amount
        bool isCompleted;
        bool isApproved;
        mapping(address => bool) oracleApproved; // Oracle -> approval status
        uint256 approvalsCount;
    }

    struct Project {
        uint256 id;
        address pathfinder; // Project lead
        ProjectStatus status;
        uint256 totalBudgetQLP;
        uint256 fundedAmountQLP;
        Milestone[] milestones;
        uint256 currentMilestoneIndex;
        string detailsIPFSHash; // IPFS hash to project plan
        uint256 reputationEarnedByPathfinder; // Total QRL earned by pathfinder for this project
    }

    // --- Mappings & State Variables ---
    uint256 public nextProposalId;
    uint256 public nextProjectId;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => Project) public projects;
    mapping(address => bool) public isOracle;
    address[] public oracles; // List of active oracles for easier iteration

    uint256 public totalQLPTreasury; // Total QLP held by the DAO

    // --- Events ---
    event ProposalSubmitted(uint256 indexed proposalId, ProposalType indexed pType, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint256 reputationWeight, bool support);
    event ProposalFinalized(uint256 indexed proposalId, ProposalStatus indexed status);
    event ProjectCreated(uint256 indexed projectId, address indexed pathfinder, uint256 requestedFunds);
    event MilestoneReported(uint256 indexed projectId, uint256 indexed milestoneIndex, string reportHash);
    event MilestoneApproved(uint256 indexed projectId, uint256 indexed milestoneIndex);
    event FundsDisbursed(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amount);
    event ReputationAwarded(address indexed recipient, uint256 amount, string reasonHash);
    event ReputationSlashed(address indexed offender, uint256 amount, string reasonHash);
    event OracleRegistered(address indexed oracle);
    event OracleRemoved(address indexed oracle);
    event DaoParameterUpdated(bytes32 indexed paramName, uint256 newValue);
    event ProjectStatusChanged(uint256 indexed projectId, ProjectStatus newStatus);
    event StrategicInitiativeSubmitted(uint256 indexed proposalId, string initiativeHash);
    event ProjectEndorsed(uint256 indexed projectId, address indexed endorser);

    // --- Modifiers ---
    modifier onlyPathfinder(uint256 _projectId) {
        require(projects[_projectId].pathfinder == msg.sender, "Caller is not the project pathfinder");
        _;
    }

    modifier onlyOracle() {
        require(isOracle[msg.sender], "Caller is not an Oracle");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        Proposal storage p = proposals[_proposalId];
        require(p.status == ProposalStatus.Active, "Proposal is not active");
        require(block.timestamp <= p.votingEndTime, "Voting period has ended");
        _;
    }

    modifier proposalPendingExecution(uint256 _proposalId) {
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp > p.votingEndTime, "Voting period has not ended");
        require(p.status == ProposalStatus.Active, "Proposal not in active status for finalization");
        _;
    }

    modifier hasMinReputation(uint256 _minQRL) {
        require(qrlToken.getEffectiveReputation(msg.sender) >= _minQRL, "Insufficient QRL reputation");
        _;
    }

    modifier projectActive(uint256 _projectId) {
        require(
            projects[_projectId].status == ProjectStatus.Active ||
                projects[_projectId].status == ProjectStatus.Incubating ||
                projects[_projectId].status == ProjectStatus.Paused,
            "Project is not in an active or incubatable state"
        );
        _;
    }

    constructor(uint256 _initialQLPSupply) Ownable(msg.sender) {
        qlpToken = new QuantumLeapToken(_initialQLPSupply);
        qrlToken = new QuantumReputationLeap(address(this)); // DAO itself manages QRL

        // Initialize governable parameters
        proposalQuorumPercentage = 5; // 5% of total QRL supply
        proposalVoteThresholdPercentage = 60; // 60% of cast votes
        votingPeriodDuration = 3 days; // 3 days for voting
        minQRLForProposal = 10; // 10 QRL to submit a proposal
        minQRLToDelegate = 1; // Any QRL holder can delegate
        oracleApprovalThreshold = 3; // 3 oracles needed for milestone approval

        // Mint initial QLP for the owner, then transfer to DAO treasury (conceptually)
        // In a real system, the owner would deposit it. Here for bootstrapping.
        qlpToken.transfer(address(this), qlpToken.balanceOf(msg.sender));
        totalQLPTreasury = qlpToken.balanceOf(address(this));
    }

    // --- I. Core DAO Governance & Token Management ---

    /**
     * @notice Allows the DAO (via governance) to adjust core parameters.
     * @param _paramName The name of the parameter to update (e.g., "proposalQuorumPercentage").
     * @param _newValue The new value for the parameter.
     */
    function updateDaoParameter(bytes32 _paramName, uint256 _newValue) external {
        // This function should only be callable via a successful governance proposal
        // A specific proposal type (ParameterChange) would target this function.
        // For simplicity in this demo, it's called internally by a proposal execution.
        if (_paramName == "proposalQuorumPercentage") {
            proposalQuorumPercentage = _newValue;
        } else if (_paramName == "proposalVoteThresholdPercentage") {
            proposalVoteThresholdPercentage = _newValue;
        } else if (_paramName == "votingPeriodDuration") {
            votingPeriodDuration = _newValue;
        } else if (_paramName == "minQRLForProposal") {
            minQRLForProposal = _newValue;
        } else if (_paramName == "minQRLToDelegate") {
            minQRLToDelegate = _newValue;
        } else if (_paramName == "oracleApprovalThreshold") {
            oracleApprovalThreshold = _newValue;
        } else {
            revert("Invalid parameter name");
        }
        emit DaoParameterUpdated(_paramName, _newValue);
    }

    /**
     * @notice Allows any user to deposit QLP tokens into the DAO's treasury.
     * @param _amount The amount of QLP to deposit.
     */
    function depositFunds(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Deposit amount must be greater than zero");
        qlpToken.transferFrom(msg.sender, address(this), _amount);
        totalQLPTreasury += _amount;
    }

    /**
     * @notice Allows the DAO to withdraw funds for operational expenses (not project funding).
     * This function should only be callable via a successful governance proposal.
     * @param _recipient The address to send funds to.
     * @param _amount The amount of QLP to withdraw.
     */
    function withdrawDAOOperatingFunds(address _recipient, uint256 _amount) external nonReentrant {
        // This function is executed by a successful DAO governance proposal.
        // For simplicity, directly callable by owner in this demo, but strictly DAO controlled in reality.
        require(msg.sender == owner(), "Only DAO owner can initiate this for demo"); // Replace with DAO logic
        require(_amount > 0, "Withdraw amount must be greater than zero");
        require(totalQLPTreasury >= _amount, "Insufficient QLP in DAO treasury");

        totalQLPTreasury -= _amount;
        qlpToken.transfer(_recipient, _amount);
    }

    // --- II. Project (Leap) Lifecycle Management ---

    /**
     * @notice Allows any Voyager with sufficient QRL to propose a new "Leap" project.
     * @param _detailsIPFSHash IPFS hash to detailed project description, goals, and team.
     * @param _requestedQLPFunds Total QLP requested for the project.
     * @param _incubationPeriod Time in seconds for the initial incubation phase.
     * @param _milestones Array of initial milestones with descriptions and budget allocations.
     */
    function submitProjectProposal(
        string memory _detailsIPFSHash,
        uint256 _requestedQLPFunds,
        uint256 _incubationPeriod,
        Milestone[] memory _milestones
    ) external hasMinReputation(minQRLForProposal) returns (uint256) {
        require(bytes(_detailsIPFSHash).length > 0, "Details IPFS hash cannot be empty");
        require(_requestedQLPFunds > 0, "Requested funds must be greater than zero");
        require(_milestones.length > 0, "At least one milestone required");
        require(totalQLPTreasury >= _requestedQLPFunds, "Insufficient funds in DAO treasury for this project");

        uint256 totalMilestoneAllocation = 0;
        for (uint256 i = 0; i < _milestones.length; i++) {
            totalMilestoneAllocation += _milestones[i].budgetAllocation;
        }
        require(totalMilestoneAllocation == _requestedQLPFunds, "Milestone allocations must sum to total requested funds");

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposalType = ProposalType.ProjectFunding;
        newProposal.proposer = msg.sender;
        newProposal.detailsIPFSHash = _detailsIPFSHash;
        newProposal.creationTime = block.timestamp;
        newProposal.votingEndTime = block.timestamp + votingPeriodDuration;
        newProposal.status = ProposalStatus.Active;
        // TargetId will be the projectId, set upon execution if successful
        // Value will be _requestedQLPFunds

        // Create a temporary project entry to link with the proposal
        uint256 tempProjectId = nextProjectId++;
        projects[tempProjectId].id = tempProjectId;
        projects[tempProjectId].pathfinder = msg.sender;
        projects[tempProjectId].status = ProjectStatus.Proposed;
        projects[tempProjectId].totalBudgetQLP = _requestedQLPFunds;
        projects[tempProjectId].detailsIPFSHash = _detailsIPFSHash;
        projects[tempProjectId].milestones = _milestones; // Copy milestones directly

        newProposal.targetId = tempProjectId; // Link proposal to the project

        emit ProposalSubmitted(proposalId, ProposalType.ProjectFunding, msg.sender);
        return proposalId;
    }

    /**
     * @notice Allows QRL holders to vote on active proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for a 'yes' vote, false for a 'no' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external proposalActive(_proposalId) {
        Proposal storage p = proposals[_proposalId];
        require(!p.hasVoted[msg.sender], "Already voted on this proposal");

        address voter = msg.sender;
        address delegatee = qrlToken.getDelegate(voter);

        uint256 voteWeight = qrlToken.getReputation(voter); // Direct reputation is primary vote power

        if (delegatee != address(0) && qrlToken.getReputation(voter) > 0) {
            // If the voter has delegated, their vote power is added to the delegatee's.
            // This requires the vote to be cast *by* the delegatee in a real system.
            // For simplicity, we assume `msg.sender` votes, but if they delegated, their QRL
            // would effectively count for the delegatee's total power, and they shouldn't vote directly.
            // In this implementation, the `delegateReputation` only *redirects* the vote
            // meaning the actual QRL of `msg.sender` is counted for `delegatee` if `delegatee` votes.
            // To simplify, let's say if you delegated, *you* cannot vote, only your delegatee can.
            revert("You have delegated your reputation. Your delegatee must vote.");
        }

        if (_support) {
            p.yesVotes += voteWeight;
        } else {
            p.noVotes += voteWeight;
        }
        p.hasVoted[voter] = true;

        emit VoteCast(_proposalId, voter, voteWeight, _support);
    }

    /**
     * @notice Any member can call to finalize a proposal after its voting period ends, enacting the outcome.
     * @param _proposalId The ID of the proposal to finalize.
     */
    function finalizeProposal(uint256 _proposalId) external nonReentrant proposalPendingExecution(_proposalId) {
        Proposal storage p = proposals[_proposalId];

        uint256 totalQRLSupply = qrlToken.totalSupply(); // Needs a total supply tracker in QRL contract
        // For simplicity, let's use sum of all reputations, assuming max QRL possible.
        // A real QRL contract would have `totalSupply()`
        uint256 totalReputationInDAO = 0; // sum of all _reputations values for active members

        // Placeholder for real total supply from QRL contract
        // uint256 totalReputationInDAO = qrlToken.getTotalSupply();

        uint256 totalVotesCast = p.yesVotes + p.noVotes;

        bool quorumMet = (totalVotesCast * 100) >= (totalReputationInDAO * proposalQuorumPercentage);
        bool thresholdMet = (p.yesVotes * 100) >= (totalVotesCast * proposalVoteThresholdPercentage);

        if (quorumMet && thresholdMet) {
            p.status = ProposalStatus.Succeeded;
            _executeProposal(p); // Execute the proposal's action
        } else {
            p.status = ProposalStatus.Failed;
            // If it was a ProjectFunding proposal, mark the project as Failed too.
            if (p.proposalType == ProposalType.ProjectFunding) {
                projects[p.targetId].status = ProjectStatus.Terminated; // Or Failed
                emit ProjectStatusChanged(p.targetId, ProjectStatus.Terminated);
            }
        }
        emit ProposalFinalized(_proposalId, p.status);
    }

    /**
     * @dev Internal function to execute a successful proposal.
     * @param _proposal The proposal struct to execute.
     */
    function _executeProposal(Proposal storage _proposal) internal {
        require(_proposal.status == ProposalStatus.Succeeded, "Proposal must be Succeeded to execute");

        if (_proposal.proposalType == ProposalType.ProjectFunding) {
            Project storage project = projects[_proposal.targetId];
            require(project.status == ProjectStatus.Proposed, "Project must be in Proposed status");

            project.status = ProjectStatus.Incubating; // Initial funding puts it in incubation
            project.fundedAmountQLP = _proposal.value; // Total budget assigned
            emit ProjectCreated(project.id, project.pathfinder, project.totalBudgetQLP);
            emit ProjectStatusChanged(project.id, ProjectStatus.Incubating);
        } else if (_proposal.proposalType == ProposalType.BudgetAdjustment) {
            Project storage project = projects[_proposal.targetId];
            require(project.status == ProjectStatus.Active, "Project must be active for budget adjustment");
            uint256 oldBudget = project.totalBudgetQLP;
            project.totalBudgetQLP = _proposal.value; // New total budget
            emit ProjectStatusChanged(project.id, ProjectStatus.Active); // No explicit budget event, status changed as it implies active management
            // Also need to track how much of the new budget is funded vs just approved.
        } else if (_proposal.proposalType == ProposalType.OracleAppointment) {
            require(!isOracle[_proposal.targetAddress], "Address is already an Oracle");
            isOracle[_proposal.targetAddress] = true;
            oracles.push(_proposal.targetAddress);
            emit OracleRegistered(_proposal.targetAddress);
        } else if (_proposal.proposalType == ProposalType.ParameterChange) {
            (bytes32 paramName, uint256 newValue) = abi.decode(_proposal.data, (bytes32, uint256));
            updateDaoParameter(paramName, newValue); // Call the internal update function
        } else if (_proposal.proposalType == ProposalType.StrategicInitiative) {
            // Strategic initiatives don't have direct on-chain execution beyond marking as executed.
            // Their impact is off-chain (new partnerships, new research directions, etc.)
            // The DAO has simply voted to support this direction.
            emit StrategicInitiativeSubmitted(_proposal.id, _proposal.detailsIPFSHash);
        } else if (_proposal.proposalType == ProposalType.ReputationChallenge) {
            // Handle reputation challenge outcome here.
            // Assuming _proposal.targetAddress is the challenged user.
            // And _proposal.value implies QRL to add/remove.
            // This is simplified, real challenge needs more data.
            // Example: if challenge succeeds, slash challenger, else award challenger etc.
            qrlToken.burn(_proposal.targetAddress, _proposal.value); // Example: slash if challenge was valid.
            emit ReputationSlashed(_proposal.targetAddress, _proposal.value, "Reputation challenge successful");
        } else if (_proposal.proposalType == ProposalType.ProjectTermination) {
            Project storage project = projects[_proposal.targetId];
            require(project.status != ProjectStatus.Terminated, "Project already terminated");
            project.status = ProjectStatus.Terminated;
            emit ProjectStatusChanged(project.id, ProjectStatus.Terminated);
        }

        _proposal.status = ProposalStatus.Executed;
    }

    /**
     * @notice Called by a Pathfinder to submit a progress report for a milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone being reported.
     * @param _reportIPFSHash IPFS hash to the detailed milestone report.
     */
    function submitMilestoneReport(
        uint256 _projectId,
        uint256 _milestoneIndex,
        string memory _reportIPFSHash
    ) external onlyPathfinder(_projectId) projectActive(_projectId) {
        Project storage project = projects[_projectId];
        require(_milestoneIndex == project.currentMilestoneIndex, "Not the current milestone");
        require(_milestoneIndex < project.milestones.length, "Milestone index out of bounds");
        require(!project.milestones[_milestoneIndex].isCompleted, "Milestone already completed");
        require(bytes(_reportIPFSHash).length > 0, "Report IPFS hash cannot be empty");

        project.milestones[_milestoneIndex].descriptionIPFSHash = _reportIPFSHash; // Re-use field for report link
        emit MilestoneReported(_projectId, _milestoneIndex, _reportIPFSHash);
    }

    /**
     * @notice Called by Oracles to vote on the approval of a submitted milestone.
     * Multiple oracle approvals (defined by `oracleApprovalThreshold`) are required.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone to approve.
     * @param _approved True if the Oracle approves, false to reject.
     */
    function approveMilestone(uint256 _projectId, uint256 _milestoneIndex, bool _approved) external onlyOracle {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active, "Project not active");
        require(_milestoneIndex == project.currentMilestoneIndex, "Not the current milestone");
        require(_milestoneIndex < project.milestones.length, "Milestone index out of bounds");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(!milestone.isCompleted, "Milestone already completed");
        require(!milestone.oracleApproved[msg.sender], "Oracle already voted on this milestone");

        if (_approved) {
            milestone.oracleApproved[msg.sender] = true;
            milestone.approvalsCount++;
            if (milestone.approvalsCount >= oracleApprovalThreshold) {
                milestone.isApproved = true;
                emit MilestoneApproved(_projectId, _milestoneIndex);
            }
        } else {
            // If an Oracle rejects, it might trigger a re-submission or a DAO review.
            // For now, it just doesn't count towards approval threshold.
            // A more complex system might trigger a reputation challenge or a DAO re-vote.
        }
    }

    /**
     * @notice Called by a Pathfinder to request funds for an *approved* milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone for which payment is requested.
     */
    function requestMilestonePayment(uint256 _projectId, uint256 _milestoneIndex) external onlyPathfinder(_projectId) nonReentrant {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active, "Project not active");
        require(_milestoneIndex == project.currentMilestoneIndex, "Not the current milestone for payment");
        require(_milestoneIndex < project.milestones.length, "Milestone index out of bounds");

        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.isApproved, "Milestone not yet approved by Oracles");
        require(!milestone.isCompleted, "Milestone payment already processed");
        require(totalQLPTreasury >= milestone.budgetAllocation, "Insufficient QLP in DAO treasury for milestone payment");

        totalQLPTreasury -= milestone.budgetAllocation;
        qlpToken.transfer(project.pathfinder, milestone.budgetAllocation);

        milestone.isCompleted = true;
        project.fundedAmountQLP += milestone.budgetAllocation;
        project.currentMilestoneIndex++;

        // If all milestones are completed, mark project as complete
        if (project.currentMilestoneIndex >= project.milestones.length) {
            project.status = ProjectStatus.Completed;
            emit ProjectStatusChanged(_projectId, ProjectStatus.Completed);
            // Award QRL to pathfinder upon project completion
            uint256 qrlReward = project.totalBudgetQLP / 1000; // Example: 0.1% of budget as QRL
            qrlToken.mint(project.pathfinder, qrlReward);
            project.reputationEarnedByPathfinder += qrlReward;
            emit ReputationAwarded(project.pathfinder, qrlReward, "Project completed");
        } else {
            // Move project to Active status after incubation or after first milestone payment
            if (project.status == ProjectStatus.Incubating) {
                project.status = ProjectStatus.Active;
                emit ProjectStatusChanged(_projectId, ProjectStatus.Active);
            }
        }

        emit FundsDisbursed(_projectId, _milestoneIndex, milestone.budgetAllocation);
    }

    /**
     * @notice Allows a Pathfinder to propose a budget adjustment for their active project.
     * This triggers a new DAO vote (BudgetAdjustment proposal).
     * @param _projectId The ID of the project.
     * @param _newBudget The new total budget for the project.
     * @param _reasonIPFSHash IPFS hash explaining the reason for adjustment.
     */
    function adjustProjectBudget(
        uint256 _projectId,
        uint256 _newBudget,
        string memory _reasonIPFSHash
    ) external onlyPathfinder(_projectId) projectActive(_projectId) returns (uint256) {
        Project storage project = projects[_projectId];
        require(_newBudget > project.fundedAmountQLP, "New budget must be greater than already funded amount");
        require(bytes(_reasonIPFSHash).length > 0, "Reason IPFS hash cannot be empty");

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposalType = ProposalType.BudgetAdjustment;
        newProposal.proposer = msg.sender;
        newProposal.detailsIPFSHash = _reasonIPFSHash;
        newProposal.creationTime = block.timestamp;
        newProposal.votingEndTime = block.timestamp + votingPeriodDuration;
        newProposal.status = ProposalStatus.Active;
        newProposal.targetId = _projectId;
        newProposal.value = _newBudget; // New budget amount

        emit ProposalSubmitted(proposalId, ProposalType.BudgetAdjustment, msg.sender);
        return proposalId;
    }

    /**
     * @notice Allows any Voyager to request a formal DAO review of a project's progress or conduct.
     * This triggers a new DAO vote (ProjectReview proposal).
     * @param _projectId The ID of the project.
     * @param _reasonIPFSHash IPFS hash explaining the reason for the review.
     */
    function initiateProjectReview(
        uint256 _projectId,
        string memory _reasonIPFSHash
    ) external hasMinReputation(minQRLForProposal) returns (uint256) {
        require(bytes(_reasonIPFSHash).length > 0, "Reason IPFS hash cannot be empty");
        require(projects[_projectId].status != ProjectStatus.Proposed, "Cannot review a proposed project");
        require(projects[_projectId].status != ProjectStatus.Terminated, "Cannot review a terminated project");

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposalType = ProposalType.ProjectReview;
        newProposal.proposer = msg.sender;
        newProposal.detailsIPFSHash = _reasonIPFSHash;
        newProposal.creationTime = block.timestamp;
        newProposal.votingEndTime = block.timestamp + votingPeriodDuration;
        newProposal.status = ProposalStatus.Active;
        newProposal.targetId = _projectId;

        emit ProposalSubmitted(proposalId, ProposalType.ProjectReview, msg.sender);
        return proposalId;
    }

    /**
     * @notice Allows a DAO proposal to pause an active project (e.g., pending review).
     * This function should only be callable via a successful governance proposal.
     * @param _projectId The ID of the project to pause.
     */
    function pauseProject(uint256 _projectId) external {
        // This function is executed by a successful DAO governance proposal (e.g., ProjectReview results in pause).
        require(msg.sender == owner(), "Only DAO owner can initiate this for demo"); // Replace with DAO logic
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active || project.status == ProjectStatus.Incubating, "Project not active or incubating");
        project.status = ProjectStatus.Paused;
        emit ProjectStatusChanged(_projectId, ProjectStatus.Paused);
    }

    /**
     * @notice Allows a DAO proposal to terminate a project (e.g., failure, fraud).
     * This function should only be callable via a successful governance proposal.
     * @param _projectId The ID of the project to terminate.
     */
    function terminateProject(uint256 _projectId) external {
        // This function is executed by a successful DAO governance proposal.
        require(msg.sender == owner(), "Only DAO owner can initiate this for demo"); // Replace with DAO logic
        Project storage project = projects[_projectId];
        require(project.status != ProjectStatus.Terminated && project.status != ProjectStatus.Completed, "Project already terminated or completed");
        project.status = ProjectStatus.Terminated;
        emit ProjectStatusChanged(_projectId, ProjectStatus.Terminated);
        // Funds remaining for milestones could be returned to DAO treasury or frozen.
    }

    // --- III. Reputation (QRL) & Role Management ---

    /**
     * @notice DAO-governed function to reward QRL (reputation) for significant contributions.
     * This function should only be callable via a successful governance proposal.
     * @param _contributor The address to mint QRL for.
     * @param _amount The amount of QRL to mint.
     * @param _contributionHash IPFS hash detailing the contribution.
     */
    function mintQRLForContribution(address _contributor, uint256 _amount, string memory _contributionHash) external {
        // This function is executed by a successful DAO governance proposal.
        require(msg.sender == owner(), "Only DAO owner can initiate this for demo"); // Replace with DAO logic
        qrlToken.mint(_contributor, _amount);
        emit ReputationAwarded(_contributor, _amount, _contributionHash);
    }

    /**
     * @notice DAO-governed function to slash QRL for malicious behavior or severe project failures.
     * This function should only be callable via a successful governance proposal.
     * @param _offender The address to burn QRL from.
     * @param _amount The amount of QRL to burn.
     * @param _reasonHash IPFS hash detailing the reason for slashing.
     */
    function burnQRLForMisconduct(address _offender, uint256 _amount, string memory _reasonHash) external {
        // This function is executed by a successful DAO governance proposal.
        require(msg.sender == owner(), "Only DAO owner can initiate this for demo"); // Replace with DAO logic
        qrlToken.burn(_offender, _amount);
        emit ReputationSlashed(_offender, _amount, _reasonHash);
    }

    /**
     * @notice Allows a Voyager to delegate their QRL voting power to another address.
     * The delegatee must have a minimum QRL to be eligible.
     * @param _delegatee The address to delegate reputation to.
     */
    function delegateReputation(address _delegatee) external {
        require(qrlToken.getReputation(_delegatee) >= minQRLToDelegate, "Delegatee must meet minimum QRL threshold");
        qrlToken.delegate(_delegatee);
    }

    /**
     * @notice Allows a Voyager to revoke their QRL delegation.
     */
    function revokeReputationDelegation() external {
        qrlToken.revokeDelegation();
    }

    /**
     * @notice Initiates a DAO proposal to appoint a new Oracle.
     * @param _oracleCandidate The address of the candidate for Oracle.
     */
    function registerOracle(address _oracleCandidate) external hasMinReputation(minQRLForProposal) returns (uint256) {
        require(!isOracle[_oracleCandidate], "Address is already an Oracle");

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposalType = ProposalType.OracleAppointment;
        newProposal.proposer = msg.sender;
        newProposal.detailsIPFSHash = "Proposal to appoint a new Oracle.";
        newProposal.creationTime = block.timestamp;
        newProposal.votingEndTime = block.timestamp + votingPeriodDuration;
        newProposal.status = ProposalStatus.Active;
        newProposal.targetAddress = _oracleCandidate;

        emit ProposalSubmitted(proposalId, ProposalType.OracleAppointment, msg.sender);
        return proposalId;
    }

    /**
     * @notice Initiates a DAO proposal to remove an existing Oracle.
     * @param _oracleToRemove The address of the Oracle to remove.
     */
    function removeOracle(address _oracleToRemove) external hasMinReputation(minQRLForProposal) returns (uint256) {
        require(isOracle[_oracleToRemove], "Address is not an Oracle");

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposalType = ProposalType.OracleAppointment; // Re-use type, or create new 'OracleRemoval'
        newProposal.proposer = msg.sender;
        newProposal.detailsIPFSHash = "Proposal to remove an Oracle.";
        newProposal.creationTime = block.timestamp;
        newProposal.votingEndTime = block.timestamp + votingPeriodDuration;
        newProposal.status = ProposalStatus.Active;
        newProposal.targetAddress = _oracleToRemove; // Target is the oracle to remove

        emit ProposalSubmitted(proposalId, ProposalType.OracleAppointment, msg.sender);
        return proposalId;
    }

    /**
     * @notice Allows Voyagers to formally challenge an Oracle's decision, triggering a DAO vote.
     * @param _oracleDecisionId A unique identifier for the specific Oracle decision being challenged.
     * @param _challengeReasonIPFSHash IPFS hash explaining the reason for the challenge.
     */
    function challengeOracleDecision(uint256 _oracleDecisionId, string memory _challengeReasonIPFSHash) external hasMinReputation(minQRLForProposal) returns (uint256) {
        require(bytes(_challengeReasonIPFSHash).length > 0, "Challenge reason cannot be empty");
        // In a real system, _oracleDecisionId would map to specific milestone approval, etc.
        // For simplicity, this initiates a generic reputation challenge proposal.
        // The DAO would then decide if the Oracle's reputation should be affected.

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposalType = ProposalType.ReputationChallenge;
        newProposal.proposer = msg.sender;
        newProposal.detailsIPFSHash = _challengeReasonIPFSHash;
        newProposal.creationTime = block.timestamp;
        newProposal.votingEndTime = block.timestamp + votingPeriodDuration;
        newProposal.status = ProposalStatus.Active;
        // targetId or targetAddress would refer to the Oracle whose decision is challenged
        // This requires more context passing for the actual oracle decision.

        emit ProposalSubmitted(proposalId, ProposalType.ReputationChallenge, msg.sender);
        return proposalId;
    }

    // --- IV. Advanced & Utility Functions ---

    /**
     * @notice Allows QRL holders to publicly "endorse" a project proposal, increasing its visibility.
     * This signals pre-vote support but does not directly count towards voting weight.
     * @param _projectId The ID of the project being endorsed.
     */
    function endorseProject(uint256 _projectId) external hasMinReputation(1) {
        require(projects[_projectId].status == ProjectStatus.Proposed, "Only proposed projects can be endorsed");
        // Could implement a mapping `mapping(uint256 => mapping(address => bool)) public projectEndorsements;`
        // to prevent duplicate endorsements and track counts.
        emit ProjectEndorsed(_projectId, msg.sender);
    }

    /**
     * @notice Allows Voyagers to propose broad, non-project-specific strategic initiatives for the DAO.
     * This triggers a new DAO vote (StrategicInitiative proposal).
     * @param _initiativeIPFSHash IPFS hash detailing the strategic initiative.
     */
    function submitStrategicInitiative(string memory _initiativeIPFSHash) external hasMinReputation(minQRLForProposal) returns (uint256) {
        require(bytes(_initiativeIPFSHash).length > 0, "Initiative IPFS hash cannot be empty");

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposalType = ProposalType.StrategicInitiative;
        newProposal.proposer = msg.sender;
        newProposal.detailsIPFSHash = _initiativeIPFSHash;
        newProposal.creationTime = block.timestamp;
        newProposal.votingEndTime = block.timestamp + votingPeriodDuration;
        newProposal.status = ProposalStatus.Active;

        emit ProposalSubmitted(proposalId, ProposalType.StrategicInitiative, msg.sender);
        return proposalId;
    }

    /**
     * @notice Allows QRL holders to "stake" a portion of their *reputation* for a period,
     * earning minor QLP rewards as an incentive for active participation.
     * This is a conceptual 'cognitive staking' where QRL isn't locked, but a commitment is tracked.
     * @param _amount The amount of QRL 'reputation' to commit to staking.
     * (This would conceptually map to a duration, and QLP emission based on total staked QRL).
     */
    function claimQLPForReputationStaking(uint256 _amount) external {
        // This function represents claiming rewards from a conceptual "reputation staking" pool.
        // The actual staking logic (duration, QLP emission rate) would be more complex,
        // likely managed off-chain with on-chain claims.
        // For this contract, it's a placeholder for an incentive mechanism.
        require(qrlToken.getEffectiveReputation(msg.sender) >= _amount, "Insufficient QRL reputation to claim staking rewards");

        // Simulate QLP reward based on _amount and some internal logic
        uint256 reward = _amount / 10; // Example: 10% of committed QRL amount (conceptually)
        require(totalQLPTreasury >= reward, "Insufficient QLP in DAO treasury for rewards");
        totalQLPTreasury -= reward;
        qlpToken.transfer(msg.sender, reward);
        // Need to track who claimed how much QLP to prevent double claims or manipulate rewards.
        // This is a simplified function.
    }

    /**
     * @notice Returns comprehensive details about a specific project.
     * @param _projectId The ID of the project.
     * @return Project struct containing all details.
     */
    function viewProjectDetails(uint256 _projectId) external view returns (Project memory) {
        return projects[_projectId];
    }

    /**
     * @notice Returns the QRL balance (reputation) of a user.
     * @param _user The address of the user.
     * @return The QRL balance of the user.
     */
    function getUserReputation(address _user) external view returns (uint256) {
        return qrlToken.getReputation(_user);
    }

    /**
     * @notice Returns the current status and voting results of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return id, type, proposer, detailsHash, creationTime, votingEndTime, yesVotes, noVotes, status.
     */
    function getProposalStatus(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            ProposalType proposalType,
            address proposer,
            string memory detailsIPFSHash,
            uint256 creationTime,
            uint256 votingEndTime,
            uint256 yesVotes,
            uint256 noVotes,
            ProposalStatus status
        )
    {
        Proposal storage p = proposals[_proposalId];
        return (
            p.id,
            p.proposalType,
            p.proposer,
            p.detailsIPFSHash,
            p.creationTime,
            p.votingEndTime,
            p.yesVotes,
            p.noVotes,
            p.status
        );
    }

    /**
     * @notice Returns the current balance of QLP in the DAO's treasury.
     * @return The total QLP balance.
     */
    function getTreasuryBalance() external view returns (uint256) {
        return totalQLPTreasury;
    }

    // Fallback function to prevent accidental ETH transfers (QLP is the treasury)
    receive() external payable {
        revert("ETH not accepted. Please deposit QLP tokens.");
    }
}
```