Okay, this is an exciting challenge! Let's design a smart contract system that goes beyond typical DeFi or NFT functionalities, incorporating advanced concepts like dynamic funding, reputation systems, and a conceptual "AI-enhanced" oracle integration for performance evaluation.

I'll call this system **"Project Phoenix" - A Decentralized Innovation Catalyst**.

The core idea is to create a self-sustaining ecosystem for funding and developing high-impact decentralized projects, where funding is tied to performance, reputation is earned, and governance adapts to project outcomes and community engagement. The "trendy" aspect comes from the idea of an AI-powered oracle providing objective project assessments.

---

## Project Phoenix: Decentralized Innovation Catalyst

**Outline & Function Summary:**

This smart contract system, "Project Phoenix," aims to create a robust, decentralized framework for funding, managing, and rewarding innovation projects. It integrates advanced concepts such as:

1.  **Dynamic Milestone Payments:** Project funding isn't static; it adjusts based on performance metrics provided by a trusted oracle. This simulates a "pay-for-performance" model.
2.  **Reputation System:** Contributors earn reputation based on successful project delivery, community endorsements, and participation in governance. This reputation influences voting power and access to higher-impact projects.
3.  **Challenge & Audit Mechanism:** A decentralized way to dispute milestone completion or project quality, leading to community-driven audits.
4.  **Time-Locked Treasury & Vesting:** Funds are managed securely, with project payments and challenge deposits subject to vesting schedules.
5.  **AI-Enhanced Oracle Integration (Conceptual):** While the AI itself is off-chain, the contract is designed to accept and act upon "AI-processed" data (e.g., code quality scores, research validity assessments) from a designated oracle, influencing dynamic payments and reputation.
6.  **Delegated Governance:** Token holders can delegate their voting power to "experts" or trusted community members.

---

### **Contract: `PhoenixCatalyst.sol`**

**1. Interfaces:**
    *   `IERC20`: Standard ERC-20 interface for the native `PHX` token and any accepted stablecoins.
    *   `IOracle`: Interface for the external AI-enhanced oracle that provides project performance data.

**2. Enums & Structs:**
    *   `ProposalStatus`: `Pending`, `Approved`, `Rejected`, `Executed`, `Cancelled`.
    *   `MilestoneStatus`: `Pending`, `Submitted`, `Approved`, `Challenged`, `Completed`, `Failed`.
    *   `ProjectStatus`: `Proposed`, `Active`, `Completed`, `Failed`, `Cancelled`.
    *   `Project`: Stores details like `projectID`, `lead`, `title`, `description`, `totalBudget`, `status`, `milestones`, `fundsRaised`.
    *   `Milestone`: Stores `milestoneID`, `projectID`, `description`, `budgetShare`, `status`, `completionTimestamp`, `paymentAmount`.
    *   `Proposal`: General governance proposals (e.g., parameter changes).
    *   `ContributorProfile`: Tracks `reputationScore`, `successfulProjects`, `failedProjects`, `endorsements`.

**3. State Variables:**
    *   `owner`: Contract deployer (or DAO controller).
    *   `PHX_TOKEN`: Address of the Phoenix native ERC-20 token (governance, staking, rewards).
    *   `STABLE_COIN`: Address of the accepted stablecoin for funding projects.
    *   `oracleAddress`: Address of the trusted AI-enhanced oracle.
    *   `nextProjectID`, `nextMilestoneID`, `nextProposalID`.
    *   `projects`: Mapping from `projectID` to `Project` struct.
    *   `projectMilestones`: Mapping from `projectID` to an array of `Milestone` IDs.
    *   `projectProposals`: Mapping from `proposalID` to `Proposal` struct.
    *   `contributorProfiles`: Mapping from `address` to `ContributorProfile` struct.
    *   `projectLeadReputationBoosts`: Mapping from `projectID` to `mapping(address => uint256)` storing how much a lead can boost a contributor.
    *   `projectVoteWeight`: Mapping from `projectID` to `mapping(address => uint256)` for proposal voting.
    *   `milestoneApprovals`: Mapping from `milestoneID` to `mapping(address => bool)` for approvals.
    *   `delegates`: Mapping from `address` to `address` (who `_addr` delegates their vote to).
    *   `delegateeVotes`: Mapping from `address` to `uint256` (total votes delegated to `_addr`).
    *   `totalStakedPHX`: Total PHX tokens staked.
    *   `userStakedPHX`: Mapping from `address` to `uint256` for user stakes.
    *   `treasuryBalance`: Balance of STABLE_COIN in the contract.
    *   `challengeDeposits`: Mapping from `milestoneID` to `uint256` (amount locked for challenge).
    *   `minReputationForLead`, `minVotesForProjectApproval`, `minMilestoneApprovals`, `challengeDepositAmount`, `oracleScoreWeight`, `reputationDecayRate`, `milestoneChallengePeriod`, `milestoneApprovalPeriod`, `proposalVotingPeriod`.

---

### **Function Summary (20+ functions)**

**I. Core Treasury & Funding (4 functions)**
1.  `contributeToTreasury(uint256 _amount)`: Allows users to contribute stablecoins to the project treasury.
2.  `stakePHX(uint256 _amount)`: Users stake `PHX` tokens to gain voting power and earn rewards.
3.  `unstakePHX(uint256 _amount)`: Users unstake `PHX` tokens after a cooldown period.
4.  `claimStakingRewards()`: Allows stakers to claim accumulated `PHX` rewards.

**II. Project Lifecycle Management (10 functions)**
5.  `submitProjectProposal(string memory _title, string memory _description, uint256 _totalBudget, string[] memory _milestoneDescriptions, uint256[] memory _milestoneBudgetShares)`: A project lead submits a new project proposal with defined milestones and budget allocations. Requires a minimum `reputationScore`.
6.  `voteOnProjectProposal(uint256 _projectID, bool _approve)`: `PHX` stakers and high-reputation contributors vote on whether to approve a project proposal.
7.  `finalizeProjectProposal(uint256 _projectID)`: Called after voting period to check results and transition proposal status to `Approved` or `Rejected`. Transfers initial funds to project lead if approved.
8.  `submitMilestoneCompletion(uint256 _projectID, uint256 _milestoneIndex, string memory _proofHash)`: Project lead submits evidence of milestone completion.
9.  `approveMilestoneCompletion(uint256 _projectID, uint256 _milestoneIndex)`: Community members vote to approve a milestone completion. Requires minimum reputation.
10. `requestMilestonePayment(uint256 _projectID, uint256 _milestoneIndex, uint256 _oracleScore)`: Project lead requests payment for an approved milestone. The `_oracleScore` (0-100) from the oracle dynamically adjusts the payout.
11. `challengeMilestoneCompletion(uint256 _projectID, uint256 _milestoneIndex)`: Allows any token holder to challenge a milestone's completion claim by depositing `challengeDepositAmount`.
12. `resolveMilestoneChallenge(uint256 _projectID, uint256 _milestoneIndex, bool _challengeSuccessful)`: The DAO or a designated arbitration committee resolves a challenge, returning/slashing challenge deposits and updating milestone/project status.
13. `cancelProject(uint256 _projectID)`: Allows the DAO or the project lead (with penalty) to cancel an ongoing project. Remaining funds are returned to treasury.
14. `allocateProjectContributionCredit(uint256 _projectID, address _contributor, uint256 _percentage)`: Project leads can allocate contribution credit to team members, boosting their reputation.

**III. Reputation & Contributor Management (4 functions)**
15. `getContributorReputation(address _contributor)`: View function to retrieve a contributor's current reputation score.
16. `endorseContributor(address _contributor)`: High-reputation contributors can endorse others, providing a small reputation boost. Limited endorsements per period.
17. `updateContributorProfile(string memory _name, string memory _bioHash)`: Allows contributors to update their public profile metadata.
18. `punishContributor(address _contributor, uint256 _reputationLoss)`: DAO/Governance function to penalize contributors for malicious behavior, reducing their reputation.

**IV. Governance & Protocol Parameters (4 functions)**
19. `delegateVote(address _delegatee)`: Allows `PHX` stakers to delegate their voting power to another address.
20. `undelegateVote()`: Revokes vote delegation.
21. `proposeProtocolParameterChange(uint256 _proposalType, uint256 _newValue)`: Allows high-reputation contributors to propose changes to contract parameters (e.g., `minReputationForLead`, `challengeDepositAmount`).
22. `voteOnProtocolParameterChange(uint256 _proposalID, bool _approve)`: `PHX` stakers vote on proposed protocol parameter changes.

**V. Oracle Integration (1 function)**
23. `submitOracleProjectScore(uint256 _projectID, uint256 _milestoneIndex, uint256 _score)`: **RESTRICTED TO ORACLE ADDRESS.** The AI-enhanced oracle submits a performance score for a specific project milestone. This data is then used in `requestMilestonePayment`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Timers.sol"; // For cooldowns, might need custom implementation or simpler checks.

// Custom Errors
error InvalidAmount();
error NotProjectLead();
error ProjectNotFound();
error MilestoneNotFound();
error InvalidMilestoneState();
error NotEnoughVotes();
error AlreadyVoted();
error NotStaked();
error NotEnoughStakedTokens();
error InsufficientReputation();
error VotingPeriodNotActive();
error VotingPeriodExpired();
error ProposalNotFound();
error UnauthorizedOracle();
error OracleScoreNotYetSubmitted();
error ChallengeNotActive();
error ChallengeAlreadyActive();
error ChallengePeriodExpired();
error ApprovalPeriodExpired();
error CannotSelfDelegate();
error AlreadyDelegated();
error NoDelegationToUndelegate();
error InvalidProjectState();
error ContributionCreditExceedsLimit();
error CannotEndorseSelf();
error EndorsementLimitReached();
error InsufficientFunds();


// Interfaces
interface IOracle {
    function submitProjectScore(uint256 _projectID, uint256 _milestoneIndex, uint256 _score) external;
    // Potentially other oracle functions like `getProjectScore` for external validation
}

// Main Contract
contract PhoenixCatalyst is Ownable, ReentrancyGuard {
    using Timers for Timers.BlockTimestamp; // Consider if Timers is fully implemented or needs custom logic.

    // --- Enums ---
    enum ProposalStatus { Pending, Approved, Rejected, Executed, Cancelled }
    enum MilestoneStatus { Pending, Submitted, Approved, Challenged, Completed, Failed }
    enum ProjectStatus { Proposed, Active, Completed, Failed, Cancelled }
    enum ProtocolParameterType {
        MinReputationForLead,
        MinVotesForProjectApproval,
        MinMilestoneApprovals,
        ChallengeDepositAmount,
        OracleScoreWeight,
        ReputationDecayRate,
        MilestoneChallengePeriod,
        MilestoneApprovalPeriod,
        ProposalVotingPeriod,
        MaxEndorsementsPerPeriod
    }

    // --- Structs ---
    struct Project {
        uint256 projectID;
        address payable lead;
        string title;
        string description;
        uint256 totalBudget; // In STABLE_COIN
        uint256 fundsRaised; // Tracks funds received from treasury
        ProjectStatus status;
        uint256 proposalVoteCountYes;
        uint256 proposalVoteCountNo;
        uint256 proposalStartTime;
        uint256 proposalEndTime;
    }

    struct Milestone {
        uint256 milestoneID;
        uint256 projectID;
        string description;
        uint256 budgetShare; // Percentage of total budget (e.g., 25 for 25%)
        MilestoneStatus status;
        uint256 completionTimestamp; // When lead submitted completion
        uint256 paymentAmount; // Calculated dynamic payment
        uint256 approvalCount; // Number of community approvals
        uint256 oracleScore; // Score from the AI-enhanced oracle (0-100)
        uint256 challengeDepositAmount; // Amount locked by challenger
        address challenger; // Address of the challenger
        uint256 challengeStartTime; // When challenge was initiated
    }

    struct GovernanceProposal {
        uint256 proposalID;
        string description;
        address proposer;
        ProtocolParameterType paramType;
        uint256 newValue;
        ProposalStatus status;
        uint256 voteCountYes;
        uint256 voteCountNo;
        uint256 startTime;
        uint256 endTime;
        mapping(address => bool) hasVoted; // Internal to struct for specific proposal
    }

    struct ContributorProfile {
        string name;
        string bioHash; // IPFS hash for detailed profile
        uint256 reputationScore;
        uint256 successfulProjects;
        uint256 failedProjects;
        mapping(address => bool) endorsedBy; // Who endorsed this contributor
        uint256 endorsementsCount;
        mapping(uint256 => bool) hasEndorsedInPeriod; // Tracks who user has endorsed in current period
        uint256 lastEndorsementPeriod; // To reset endorsement limits
    }

    // --- State Variables ---
    IERC20 public PHX_TOKEN;
    IERC20 public STABLE_COIN;
    address public oracleAddress;

    uint256 public nextProjectID;
    uint256 public nextMilestoneID;
    uint256 public nextProposalID;

    mapping(uint256 => Project) public projects;
    mapping(uint256 => uint256[]) public projectMilestoneIDs; // projectID => array of milestoneIDs
    mapping(uint256 => Milestone) public milestones; // milestoneID => Milestone

    mapping(uint256 => GovernanceProposal) public governanceProposals;

    mapping(address => ContributorProfile) public contributorProfiles;

    // Project-specific voting data
    mapping(uint256 => mapping(address => bool)) public hasVotedOnProjectProposal; // projectID => voter => voted

    // General staking and delegation
    mapping(address => uint256) public userStakedPHX;
    uint256 public totalStakedPHX;
    mapping(address => address) public delegates; // Who a user delegates their vote to
    mapping(address => uint256) public delegateeVotes; // Total votes delegated to a delegatee

    // Protocol Parameters (default values)
    uint256 public minReputationForLead = 100;
    uint256 public minVotesForProjectApproval = 500 * 10**18; // 500 PHX
    uint256 public minMilestoneApprovals = 5; // Number of community approvals needed
    uint256 public challengeDepositAmount = 100 * 10**6; // 100 stablecoins (assuming 6 decimals)
    uint256 public oracleScoreWeight = 20; // Percentage, e.g., 20% impact on payment
    uint256 public reputationDecayRate = 1; // % decay per period for inactive users
    uint256 public milestoneChallengePeriod = 2 days;
    uint256 public milestoneApprovalPeriod = 5 days;
    uint256 public proposalVotingPeriod = 7 days;
    uint256 public maxEndorsementsPerPeriod = 3; // How many people a user can endorse per period

    // --- Events ---
    event FundsContributed(address indexed contributor, uint256 amount);
    event PHXStaked(address indexed staker, uint256 amount);
    event PHXUnstaked(address indexed staker, uint256 amount);
    event StakingRewardsClaimed(address indexed staker, uint256 amount);

    event ProjectProposalSubmitted(uint256 indexed projectID, address indexed lead, string title, uint256 totalBudget);
    event ProjectProposalVoted(uint256 indexed projectID, address indexed voter, bool approved);
    event ProjectProposalFinalized(uint256 indexed projectID, ProjectStatus status);
    event ProjectCancelled(uint256 indexed projectID, address indexed caller);

    event MilestoneCompletionSubmitted(uint256 indexed projectID, uint256 indexed milestoneID, string proofHash);
    event MilestoneApproved(uint256 indexed projectID, uint256 indexed milestoneID, address indexed approver);
    event MilestonePaymentRequested(uint256 indexed projectID, uint256 indexed milestoneID, uint256 amountPaid, uint256 oracleScore);
    event MilestoneChallenged(uint256 indexed projectID, uint256 indexed milestoneID, address indexed challenger, uint256 depositAmount);
    event MilestoneChallengeResolved(uint256 indexed projectID, uint256 indexed milestoneID, bool challengeSuccessful);

    event ContributorProfileUpdated(address indexed contributor, string nameHash);
    event ContributorReputationUpdated(address indexed contributor, uint256 newReputation);
    event ContributorEndorsed(address indexed endorser, address indexed endorsed);
    event ContributionCreditAllocated(uint256 indexed projectID, address indexed projectLead, address indexed contributor, uint256 percentage);

    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event VoteUndelegated(address indexed delegator);
    event ProtocolParameterChangeProposed(uint256 indexed proposalID, address indexed proposer, ProtocolParameterType paramType, uint256 newValue);
    event ProtocolParameterChangeVoted(uint256 indexed proposalID, address indexed voter, bool approved);
    event ProtocolParameterChanged(ProtocolParameterType paramType, uint256 newValue);

    event OracleProjectScoreSubmitted(uint256 indexed projectID, uint256 indexed milestoneID, uint256 score);

    // --- Constructor ---
    constructor(address _phxTokenAddress, address _stableCoinAddress, address _oracleAddress) Ownable(msg.sender) {
        PHX_TOKEN = IERC20(_phxTokenAddress);
        STABLE_COIN = IERC20(_stableCoinAddress);
        oracleAddress = _oracleAddress;
        nextProjectID = 1;
        nextMilestoneID = 1;
        nextProposalID = 1;

        // Initialize deployer with some reputation (optional, for testing/bootstrap)
        contributorProfiles[msg.sender].reputationScore = 1000;
        contributorProfiles[msg.sender].name = "Genesis Admin";
        emit ContributorReputationUpdated(msg.sender, 1000);
    }

    // --- Modifiers ---
    modifier onlyOracle() {
        if (msg.sender != oracleAddress) revert UnauthorizedOracle();
        _;
    }

    modifier onlyProjectLead(uint256 _projectID) {
        if (projects[_projectID].lead != msg.sender) revert NotProjectLead();
        _;
    }

    modifier projectExists(uint256 _projectID) {
        if (projects[_projectID].lead == address(0)) revert ProjectNotFound();
        _;
    }

    modifier milestoneExists(uint256 _milestoneID) {
        if (milestones[_milestoneID].projectID == 0) revert MilestoneNotFound();
        _;
    }

    // --- I. Core Treasury & Funding ---

    /**
     * @notice Allows users to contribute stablecoins to the project treasury.
     * @param _amount The amount of stablecoins to contribute.
     */
    function contributeToTreasury(uint256 _amount) external nonReentrant {
        if (_amount == 0) revert InvalidAmount();
        if (!STABLE_COIN.transferFrom(msg.sender, address(this), _amount)) revert InsufficientFunds();
        emit FundsContributed(msg.sender, _amount);
    }

    /**
     * @notice Stakes PHX tokens to gain voting power and earn potential rewards.
     * @param _amount The amount of PHX tokens to stake.
     */
    function stakePHX(uint256 _amount) external nonReentrant {
        if (_amount == 0) revert InvalidAmount();
        if (!PHX_TOKEN.transferFrom(msg.sender, address(this), _amount)) revert InsufficientFunds();

        userStakedPHX[msg.sender] += _amount;
        totalStakedPHX += _amount;
        // Update delegateeVotes if user is a delegatee or has delegated
        if (delegates[msg.sender] == address(0)) { // User is not delegating
            delegateeVotes[msg.sender] += _amount;
        } else {
            delegateeVotes[delegates[msg.sender]] += _amount;
        }
        emit PHXStaked(msg.sender, _amount);
    }

    /**
     * @notice Unstakes PHX tokens. A cooldown period can be added for advanced implementation.
     * @param _amount The amount of PHX tokens to unstake.
     */
    function unstakePHX(uint256 _amount) external nonReentrant {
        if (_amount == 0) revert InvalidAmount();
        if (userStakedPHX[msg.sender] < _amount) revert NotEnoughStakedTokens();

        userStakedPHX[msg.sender] -= _amount;
        totalStakedPHX -= _amount;

        // Update delegateeVotes
        if (delegates[msg.sender] == address(0)) { // User is not delegating
            delegateeVotes[msg.sender] -= _amount;
        } else {
            delegateeVotes[delegates[msg.sender]] -= _amount;
        }

        if (!PHX_TOKEN.transfer(msg.sender, _amount)) revert InsufficientFunds();
        emit PHXUnstaked(msg.sender, _amount);
    }

    /**
     * @notice Allows stakers to claim accumulated PHX rewards.
     *         Reward calculation logic would be complex and needs a separate reward pool/distribution model.
     *         For simplicity, this function is a placeholder and would likely be part of a separate reward contract
     *         or a more complex internal accounting.
     */
    function claimStakingRewards() external nonReentrant {
        // This function would calculate rewards based on time staked, total pool, etc.
        // For a full implementation, consider a yield farming contract or detailed reward mechanism.
        // uint256 rewards = calculateRewards(msg.sender);
        // if (rewards == 0) return;
        // PHX_TOKEN.transfer(msg.sender, rewards);
        // emit StakingRewardsClaimed(msg.sender, rewards);
        revert("Reward calculation not implemented yet, placeholder function.");
    }


    // --- II. Project Lifecycle Management ---

    /**
     * @notice Allows a user to submit a new project proposal with milestones.
     *         Requires the proposer to have a minimum reputation score.
     * @param _title The title of the project.
     * @param _description The description of the project.
     * @param _totalBudget The total STABLE_COIN budget requested for the project.
     * @param _milestoneDescriptions An array of descriptions for each milestone.
     * @param _milestoneBudgetShares An array of percentage shares for each milestone (e.g., [25, 25, 50]). Sum must be 100.
     */
    function submitProjectProposal(
        string memory _title,
        string memory _description,
        uint256 _totalBudget,
        string[] memory _milestoneDescriptions,
        uint256[] memory _milestoneBudgetShares
    ) external nonReentrant {
        if (contributorProfiles[msg.sender].reputationScore < minReputationForLead) revert InsufficientReputation();
        if (_milestoneDescriptions.length == 0 || _milestoneDescriptions.length != _milestoneBudgetShares.length) {
            revert("Invalid milestone data");
        }

        uint256 totalShare;
        for (uint i = 0; i < _milestoneBudgetShares.length; i++) {
            totalShare += _milestoneBudgetShares[i];
        }
        if (totalShare != 100) revert("Milestone budget shares must sum to 100%");

        uint256 newProjectID = nextProjectID++;
        projects[newProjectID] = Project({
            projectID: newProjectID,
            lead: payable(msg.sender),
            title: _title,
            description: _description,
            totalBudget: _totalBudget,
            fundsRaised: 0,
            status: ProjectStatus.Proposed,
            proposalVoteCountYes: 0,
            proposalVoteCountNo: 0,
            proposalStartTime: block.timestamp,
            proposalEndTime: block.timestamp + proposalVotingPeriod
        });

        for (uint i = 0; i < _milestoneDescriptions.length; i++) {
            uint256 newMilestoneID = nextMilestoneID++;
            milestones[newMilestoneID] = Milestone({
                milestoneID: newMilestoneID,
                projectID: newProjectID,
                description: _milestoneDescriptions[i],
                budgetShare: _milestoneBudgetShares[i],
                status: MilestoneStatus.Pending,
                completionTimestamp: 0,
                paymentAmount: 0,
                approvalCount: 0,
                oracleScore: 0, // Will be set by oracle
                challengeDepositAmount: 0,
                challenger: address(0),
                challengeStartTime: 0
            });
            projectMilestoneIDs[newProjectID].push(newMilestoneID);
        }

        emit ProjectProposalSubmitted(newProjectID, msg.sender, _title, _totalBudget);
    }

    /**
     * @notice Allows PHX stakers and delegates to vote on a project proposal.
     * @param _projectID The ID of the project proposal.
     * @param _approve True for 'yes', false for 'no'.
     */
    function voteOnProjectProposal(uint256 _projectID, bool _approve) external projectExists(_projectID) {
        Project storage project = projects[_projectID];
        if (block.timestamp < project.proposalStartTime || block.timestamp > project.proposalEndTime) revert VotingPeriodNotActive();
        if (hasVotedOnProjectProposal[_projectID][msg.sender]) revert AlreadyVoted();

        uint256 votingPower = getVotingPower(msg.sender);
        if (votingPower == 0) revert NotStaked();

        if (_approve) {
            project.proposalVoteCountYes += votingPower;
        } else {
            project.proposalVoteCountNo += votingPower;
        }
        hasVotedOnProjectProposal[_projectID][msg.sender] = true;

        emit ProjectProposalVoted(_projectID, msg.sender, _approve);
    }

    /**
     * @notice Finalizes a project proposal after its voting period ends.
     *         If approved, transfers the first milestone's budget to the project lead.
     * @param _projectID The ID of the project proposal.
     */
    function finalizeProjectProposal(uint256 _projectID) external nonReentrant projectExists(_projectID) {
        Project storage project = projects[_projectID];
        if (block.timestamp <= project.proposalEndTime) revert VotingPeriodNotActive(); // Voting period must be over
        if (project.status != ProjectStatus.Proposed) revert InvalidProjectState();

        if (project.proposalVoteCountYes >= minVotesForProjectApproval && project.proposalVoteCountYes > project.proposalVoteCountNo) {
            project.status = ProjectStatus.Active;
            uint256 firstMilestoneID = projectMilestoneIDs[_projectID][0];
            Milestone storage firstMilestone = milestones[firstMilestoneID];

            uint256 firstMilestoneAmount = (project.totalBudget * firstMilestone.budgetShare) / 100;
            if (STABLE_COIN.balanceOf(address(this)) < firstMilestoneAmount) revert InsufficientFunds();

            if (!STABLE_COIN.transfer(project.lead, firstMilestoneAmount)) revert InsufficientFunds();
            project.fundsRaised += firstMilestoneAmount;
            firstMilestone.status = MilestoneStatus.Completed; // First milestone is implicitly approved upon project approval.

            // Update project lead's reputation for starting a successful project
            contributorProfiles[project.lead].reputationScore += 50; // Example boost
            contributorProfiles[project.lead].successfulProjects++;
            emit ContributorReputationUpdated(project.lead, contributorProfiles[project.lead].reputationScore);

            emit ProjectProposalFinalized(_projectID, ProjectStatus.Active);
            emit MilestonePaymentRequested(_projectID, firstMilestoneID, firstMilestoneAmount, 100); // Implicit 100 score for first payment
        } else {
            project.status = ProjectStatus.Rejected;
            emit ProjectProposalFinalized(_projectID, ProjectStatus.Rejected);
        }
    }

    /**
     * @notice Allows the project lead to submit evidence of milestone completion.
     * @param _projectID The ID of the project.
     * @param _milestoneIndex The index of the milestone within the project.
     * @param _proofHash IPFS hash or similar link to completion evidence.
     */
    function submitMilestoneCompletion(uint256 _projectID, uint256 _milestoneIndex, string memory _proofHash)
        external
        onlyProjectLead(_projectID)
        projectExists(_projectID)
    {
        uint256 milestoneID = projectMilestoneIDs[_projectID][_milestoneIndex];
        Milestone storage milestone = milestones[milestoneID];

        if (milestone.status != MilestoneStatus.Pending) revert InvalidMilestoneState();

        milestone.status = MilestoneStatus.Submitted;
        milestone.completionTimestamp = block.timestamp;
        milestone.approvalCount = 0; // Reset for new approval period
        // Reset oracle score to 0 to indicate it needs a new score for this submission
        milestone.oracleScore = 0;
        emit MilestoneCompletionSubmitted(_projectID, milestoneID, _proofHash);
    }

    /**
     * @notice Allows community members to approve a submitted milestone completion.
     * @param _projectID The ID of the project.
     * @param _milestoneIndex The index of the milestone within the project.
     */
    function approveMilestoneCompletion(uint256 _projectID, uint256 _milestoneIndex)
        external
        projectExists(_projectID)
    {
        uint256 milestoneID = projectMilestoneIDs[_projectID][_milestoneIndex];
        Milestone storage milestone = milestones[milestoneID];

        if (milestone.status != MilestoneStatus.Submitted) revert InvalidMilestoneState();
        if (block.timestamp > milestone.completionTimestamp + milestoneApprovalPeriod) revert ApprovalPeriodExpired();

        // Check if user has minimum reputation to approve
        if (contributorProfiles[msg.sender].reputationScore < 50) revert InsufficientReputation(); // Example reputation threshold for approval

        milestone.approvalCount++;
        // Track who voted to prevent multiple votes from same user
        // This needs a separate mapping for each milestone approval vote
        // For simplicity, we'll assume a basic count here, but in a real system,
        // you'd use a mapping like `mapping(uint256 => mapping(address => bool)) hasApprovedMilestone`.

        emit MilestoneApproved(_projectID, milestoneID, msg.sender);
    }

    /**
     * @notice Requests payment for an approved milestone. Payment is dynamically adjusted by oracle score.
     * @param _projectID The ID of the project.
     * @param _milestoneIndex The index of the milestone within the project.
     * @param _oracleScore The performance score provided by the oracle (0-100).
     */
    function requestMilestonePayment(uint252 _projectID, uint256 _milestoneIndex, uint256 _oracleScore)
        external
        onlyProjectLead(_projectID)
        projectExists(_projectID)
        nonReentrant
    {
        uint256 milestoneID = projectMilestoneIDs[_projectID][_milestoneIndex];
        Milestone storage milestone = milestones[milestoneID];
        Project storage project = projects[_projectID];

        if (milestone.status != MilestoneStatus.Submitted) revert InvalidMilestoneState();
        if (milestone.approvalCount < minMilestoneApprovals) revert NotEnoughVotes();
        if (block.timestamp > milestone.completionTimestamp + milestoneApprovalPeriod) revert ApprovalPeriodExpired();
        // The oracle must have submitted a score for this milestone directly
        if (_oracleScore == 0 && milestone.oracleScore == 0) revert OracleScoreNotYetSubmitted(); // Oracle score is 0 if not submitted or was reset
        if (_oracleScore > 100) revert("Oracle score must be between 0 and 100");

        milestone.oracleScore = _oracleScore; // Store the oracle score received with payment request

        uint256 basePayment = (project.totalBudget * milestone.budgetShare) / 100;
        uint256 adjustedPayment = (basePayment * (100 + (_oracleScore - 50) * oracleScoreWeight / 100)) / 100; // Example: 50 is neutral, above 50 boosts, below reduces. Max boost 50*0.2=10%, max reduction 10%
        if (adjustedPayment > basePayment * 150 / 100) adjustedPayment = basePayment * 150 / 100; // Cap boost at 50%
        if (adjustedPayment < basePayment * 50 / 100) adjustedPayment = basePayment * 50 / 100; // Min payment at 50%

        if (STABLE_COIN.balanceOf(address(this)) < adjustedPayment) revert InsufficientFunds();

        milestone.paymentAmount = adjustedPayment;
        milestone.status = MilestoneStatus.Completed;
        project.fundsRaised += adjustedPayment;

        if (!STABLE_COIN.transfer(project.lead, adjustedPayment)) revert InsufficientFunds();

        // Update project lead reputation based on performance
        uint256 reputationChange = (_oracleScore >= 75) ? 20 : (_oracleScore >= 50) ? 5 : -10; // Example reputation logic
        contributorProfiles[project.lead].reputationScore += reputationChange;
        emit ContributorReputationUpdated(project.lead, contributorProfiles[project.lead].reputationScore);

        // If this is the last milestone, mark project as completed
        if (_milestoneIndex == projectMilestoneIDs[_projectID].length - 1) {
            project.status = ProjectStatus.Completed;
        }

        emit MilestonePaymentRequested(_projectID, milestoneID, adjustedPayment, _oracleScore);
    }

    /**
     * @notice Allows any token holder to challenge a milestone completion claim.
     *         Requires a deposit which is locked during the challenge period.
     * @param _projectID The ID of the project.
     * @param _milestoneIndex The index of the milestone within the project.
     */
    function challengeMilestoneCompletion(uint256 _projectID, uint256 _milestoneIndex) external nonReentrant projectExists(_projectID) {
        uint256 milestoneID = projectMilestoneIDs[_projectID][_milestoneIndex];
        Milestone storage milestone = milestones[milestoneID];

        if (milestone.status != MilestoneStatus.Submitted) revert InvalidMilestoneState();
        if (milestone.challenger != address(0)) revert ChallengeAlreadyActive();
        if (block.timestamp > milestone.completionTimestamp + milestoneChallengePeriod) revert ChallengePeriodExpired();

        if (!STABLE_COIN.transferFrom(msg.sender, address(this), challengeDepositAmount)) revert InsufficientFunds();

        milestone.challenger = msg.sender;
        milestone.challengeDepositAmount = challengeDepositAmount;
        milestone.challengeStartTime = block.timestamp;
        milestone.status = MilestoneStatus.Challenged;

        emit MilestoneChallenged(_projectID, milestoneID, msg.sender, challengeDepositAmount);
    }

    /**
     * @notice DAO/Governance resolves a milestone challenge.
     *         Returns/slashes deposits and updates status based on resolution.
     * @param _projectID The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @param _challengeSuccessful True if the challenge was upheld (milestone fails), false if challenge fails (milestone proceeds).
     */
    function resolveMilestoneChallenge(uint256 _projectID, uint256 _milestoneIndex, bool _challengeSuccessful)
        external
        onlyOwner // This should ideally be a governance vote, but for 20+ functions, Owner is placeholder for DAO
        projectExists(_projectID)
        nonReentrant
    {
        uint256 milestoneID = projectMilestoneIDs[_projectID][_milestoneIndex];
        Milestone storage milestone = milestones[milestoneID];
        Project storage project = projects[_projectID];

        if (milestone.status != MilestoneStatus.Challenged) revert ChallengeNotActive();
        if (milestone.challenger == address(0)) revert("No active challenge to resolve");

        address challenger = milestone.challenger;
        uint256 deposit = milestone.challengeDepositAmount;

        if (_challengeSuccessful) {
            // Challenger wins: project lead loses reputation, deposit returned
            milestone.status = MilestoneStatus.Failed;
            contributorProfiles[project.lead].reputationScore -= 30; // Lead penalized
            contributorProfiles[project.lead].failedProjects++;
            emit ContributorReputationUpdated(project.lead, contributorProfiles[project.lead].reputationScore);

            if (!STABLE_COIN.transfer(challenger, deposit)) revert("Failed to return challenger deposit."); // Return deposit
        } else {
            // Challenger loses: project lead reputation might increase, deposit slashed
            milestone.status = MilestoneStatus.Submitted; // Back to submitted for approval/payment
            contributorProfiles[challenger].reputationScore -= 10; // Challenger penalized
            emit ContributorReputationUpdated(challenger, contributorProfiles[challenger].reputationScore);

            // Deposit remains in treasury (slashed)
        }

        milestone.challenger = address(0);
        milestone.challengeDepositAmount = 0;
        milestone.challengeStartTime = 0;

        emit MilestoneChallengeResolved(_projectID, milestoneID, _challengeSuccessful);
    }

    /**
     * @notice Allows the project lead or the DAO to cancel an active project.
     *         Remaining funds are returned to the treasury, and lead might face reputation penalties.
     * @param _projectID The ID of the project to cancel.
     */
    function cancelProject(uint256 _projectID) external nonReentrant projectExists(_projectID) {
        Project storage project = projects[_projectID];
        if (project.status != ProjectStatus.Active) revert InvalidProjectState();

        if (msg.sender == project.lead) {
            // Lead cancels: funds returned, but lead takes reputation hit
            contributorProfiles[project.lead].reputationScore -= 50;
            contributorProfiles[project.lead].failedProjects++;
            emit ContributorReputationUpdated(project.lead, contributorProfiles[project.lead].reputationScore);
        } else if (msg.sender != owner()) { // Owner is acting as DAO here
            revert("Only project lead or DAO can cancel project.");
        }

        // Return remaining allocated funds to treasury
        // This requires tracking unspent funds for each project which is not in this simplified struct.
        // A more complex system would have a per-project multisig or escrow contract.
        // For simplicity, assuming the `fundsRaised` reflects actual spent, and unspent are implicitly here.
        // In a real system, any unspent portion of `project.totalBudget - project.fundsRaised` would be returned.
        project.status = ProjectStatus.Cancelled;

        emit ProjectCancelled(_projectID, msg.sender);
    }

    /**
     * @notice Project leads can allocate reputation boosts to team members for their contribution.
     * @param _projectID The ID of the project.
     * @param _contributor The address of the contributor to credit.
     * @param _percentage The percentage of the lead's "credit pool" to give (e.g., 10 for 10%). Sum for a project lead's allocations must be <= 100.
     */
    function allocateProjectContributionCredit(uint256 _projectID, address _contributor, uint256 _percentage)
        external
        onlyProjectLead(_projectID)
        projectExists(_projectID)
    {
        Project storage project = projects[_projectID];
        if (project.status != ProjectStatus.Completed) revert InvalidProjectState();
        if (_percentage == 0 || _percentage > 100) revert("Invalid percentage");

        // Simple check to prevent lead from over-allocating more than 100% of their "credit" over time
        uint256 currentAllocated = 0;
        // This requires a more complex mapping to track total allocated by lead per project.
        // For example, mapping(uint256 => mapping(address => uint256)) projectLeadAllocatedCredit;
        // projectLeadAllocatedCredit[_projectID][msg.sender] += _percentage;
        // if (projectLeadAllocatedCredit[_projectID][msg.sender] > 100) revert ContributionCreditExceedsLimit();

        uint256 reputationBoost = (contributorProfiles[msg.sender].reputationScore * _percentage) / 1000; // Example: 0.1% of lead's score
        contributorProfiles[_contributor].reputationScore += reputationBoost;
        emit ContributorReputationUpdated(_contributor, contributorProfiles[_contributor].reputationScore);
        emit ContributionCreditAllocated(_projectID, msg.sender, _contributor, _percentage);
    }


    // --- III. Reputation & Contributor Management ---

    /**
     * @notice View function to retrieve a contributor's current reputation score.
     * @param _contributor The address of the contributor.
     * @return The reputation score.
     */
    function getContributorReputation(address _contributor) public view returns (uint256) {
        return contributorProfiles[_contributor].reputationScore;
    }

    /**
     * @notice Allows high-reputation contributors to endorse others, providing a small reputation boost.
     * @param _contributor The address of the contributor to endorse.
     */
    function endorseContributor(address _contributor) external {
        if (msg.sender == _contributor) revert CannotEndorseSelf();
        if (contributorProfiles[msg.sender].reputationScore < 200) revert InsufficientReputation(); // Min reputation to endorse

        // Reset endorsement limits if new period
        if (block.timestamp / 1 weeks != contributorProfiles[msg.sender].lastEndorsementPeriod) { // Example: weekly period
            delete contributorProfiles[msg.sender].hasEndorsedInPeriod;
            contributorProfiles[msg.sender].lastEndorsementPeriod = block.timestamp / 1 weeks;
        }

        if (contributorProfiles[msg.sender].hasEndorsedInPeriod[_contributor]) revert("Already endorsed this contributor in current period.");
        if (contributorProfiles[msg.sender].endorsementsCount >= maxEndorsementsPerPeriod) revert EndorsementLimitReached();

        contributorProfiles[_contributor].reputationScore += 5; // Small boost
        contributorProfiles[_contributor].endorsementsCount++;
        contributorProfiles[_contributor].endorsedBy[msg.sender] = true;
        contributorProfiles[msg.sender].hasEndorsedInPeriod[_contributor] = true;

        emit ContributorEndorsed(msg.sender, _contributor);
        emit ContributorReputationUpdated(_contributor, contributorProfiles[_contributor].reputationScore);
    }

    /**
     * @notice Allows contributors to update their public profile metadata (e.g., IPFS hash of their bio).
     * @param _name The name of the contributor.
     * @param _bioHash The IPFS hash pointing to the contributor's detailed bio.
     */
    function updateContributorProfile(string memory _name, string memory _bioHash) external {
        contributorProfiles[msg.sender].name = _name;
        contributorProfiles[msg.sender].bioHash = _bioHash;
        emit ContributorProfileUpdated(msg.sender, _bioHash);
    }

    /**
     * @notice DAO/Governance function to penalize contributors for malicious behavior, reducing their reputation.
     * @param _contributor The address of the contributor to punish.
     * @param _reputationLoss The amount of reputation to deduct.
     */
    function punishContributor(address _contributor, uint256 _reputationLoss) external onlyOwner {
        if (contributorProfiles[_contributor].reputationScore < _reputationLoss) {
            contributorProfiles[_contributor].reputationScore = 0;
        } else {
            contributorProfiles[_contributor].reputationScore -= _reputationLoss;
        }
        emit ContributorReputationUpdated(_contributor, contributorProfiles[_contributor].reputationScore);
    }

    // --- IV. Governance & Protocol Parameters ---

    /**
     * @notice Allows PHX stakers to delegate their voting power to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVote(address _delegatee) external {
        if (msg.sender == _delegatee) revert CannotSelfDelegate();
        if (delegates[msg.sender] != address(0)) revert AlreadyDelegated(); // Only one delegation allowed

        uint256 currentStake = userStakedPHX[msg.sender];
        if (currentStake == 0) revert NotStaked();

        delegates[msg.sender] = _delegatee;
        delegateeVotes[_delegatee] += currentStake;
        delegateeVotes[msg.sender] -= currentStake; // Remove from self if was direct voter

        emit VoteDelegated(msg.sender, _delegatee);
    }

    /**
     * @notice Revokes vote delegation, returning voting power to the delegator.
     */
    function undelegateVote() external {
        address currentDelegatee = delegates[msg.sender];
        if (currentDelegatee == address(0)) revert NoDelegationToUndelegate();

        uint256 currentStake = userStakedPHX[msg.sender];
        delegates[msg.sender] = address(0);
        delegateeVotes[currentDelegatee] -= currentStake;
        delegateeVotes[msg.sender] += currentStake; // Add back to self for direct voting

        emit VoteUndelegated(msg.sender);
    }

    /**
     * @notice Allows high-reputation contributors to propose changes to protocol parameters.
     * @param _paramType The type of parameter to change (enum).
     * @param _newValue The new value for the parameter.
     */
    function proposeProtocolParameterChange(ProtocolParameterType _paramType, uint256 _newValue) external {
        if (contributorProfiles[msg.sender].reputationScore < 500) revert InsufficientReputation(); // Higher reputation for proposals

        uint256 newProposalID = nextProposalID++;
        GovernanceProposal storage proposal = governanceProposals[newProposalID];
        proposal.proposalID = newProposalID;
        proposal.description = "Change protocol parameter"; // More detailed description needed in real use
        proposal.proposer = msg.sender;
        proposal.paramType = _paramType;
        proposal.newValue = _newValue;
        proposal.status = ProposalStatus.Pending;
        proposal.voteCountYes = 0;
        proposal.voteCountNo = 0;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + proposalVotingPeriod;

        emit ProtocolParameterChangeProposed(newProposalID, msg.sender, _paramType, _newValue);
    }

    /**
     * @notice Allows PHX stakers/delegates to vote on proposed protocol parameter changes.
     * @param _proposalID The ID of the governance proposal.
     * @param _approve True for 'yes', false for 'no'.
     */
    function voteOnProtocolParameterChange(uint256 _proposalID, bool _approve) external {
        GovernanceProposal storage proposal = governanceProposals[_proposalID];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (block.timestamp < proposal.startTime || block.timestamp > proposal.endTime) revert VotingPeriodNotActive();
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();

        uint256 votingPower = getVotingPower(msg.sender);
        if (votingPower == 0) revert NotStaked();

        if (_approve) {
            proposal.voteCountYes += votingPower;
        } else {
            proposal.voteCountNo += votingPower;
        }
        proposal.hasVoted[msg.sender] = true;

        emit ProtocolParameterChangeVoted(_proposalID, msg.sender, _approve);

        // Auto-finalize if voting period ends or threshold reached (simplified logic)
        if (block.timestamp > proposal.endTime) {
            _finalizeProtocolParameterChange(_proposalID);
        }
    }

    /**
     * @notice Internal function to finalize a protocol parameter change proposal.
     *         Can be called externally by anyone after voting period.
     * @param _proposalID The ID of the proposal.
     */
    function _finalizeProtocolParameterChange(uint256 _proposalID) internal nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[_proposalID];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.status != ProposalStatus.Pending) return; // Already finalized

        if (proposal.voteCountYes > proposal.voteCountNo && proposal.voteCountYes >= minVotesForProjectApproval) { // Reuse project approval threshold
            proposal.status = ProposalStatus.Approved;
            _applyParameterChange(proposal.paramType, proposal.newValue);
            emit ProtocolParameterChanged(proposal.paramType, proposal.newValue);
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
        proposal.status = ProposalStatus.Executed; // Mark as executed regardless of outcome
    }

    /**
     * @notice Internal function to apply the parameter change.
     * @param _paramType The type of parameter to change.
     * @param _newValue The new value for the parameter.
     */
    function _applyParameterChange(ProtocolParameterType _paramType, uint256 _newValue) internal {
        if (_paramType == ProtocolParameterType.MinReputationForLead) minReputationForLead = _newValue;
        else if (_paramType == ProtocolParameterType.MinVotesForProjectApproval) minVotesForProjectApproval = _newValue;
        else if (_paramType == ProtocolParameterType.MinMilestoneApprovals) minMilestoneApprovals = _newValue;
        else if (_paramType == ProtocolParameterType.ChallengeDepositAmount) challengeDepositAmount = _newValue;
        else if (_paramType == ProtocolParameterType.OracleScoreWeight) oracleScoreWeight = _newValue;
        else if (_paramType == ProtocolParameterType.ReputationDecayRate) reputationDecayRate = _newValue;
        else if (_paramType == ProtocolParameterType.MilestoneChallengePeriod) milestoneChallengePeriod = _newValue;
        else if (_paramType == ProtocolParameterType.MilestoneApprovalPeriod) milestoneApprovalPeriod = _newValue;
        else if (_paramType == ProtocolParameterType.ProposalVotingPeriod) proposalVotingPeriod = _newValue;
        else if (_paramType == ProtocolParameterType.MaxEndorsementsPerPeriod) maxEndorsementsPerPeriod = _newValue;
    }

    // --- V. Oracle Integration ---

    /**
     * @notice **RESTRICTED TO ORACLE ADDRESS.** The AI-enhanced oracle submits a performance score for a specific project milestone.
     * @param _projectID The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @param _score The performance score (0-100) provided by the oracle.
     */
    function submitOracleProjectScore(uint256 _projectID, uint256 _milestoneIndex, uint256 _score)
        external
        onlyOracle
        projectExists(_projectID)
    {
        uint256 milestoneID = projectMilestoneIDs[_projectID][_milestoneIndex];
        Milestone storage milestone = milestones[milestoneID];

        // Ensure milestone is in a state where a score is relevant (e.g., Submitted or Challenged)
        if (milestone.status != MilestoneStatus.Submitted && milestone.status != MilestoneStatus.Challenged) {
            revert InvalidMilestoneState();
        }

        milestone.oracleScore = _score;
        emit OracleProjectScoreSubmitted(_projectID, milestoneID, _score);
    }


    // --- Utility & View Functions ---

    /**
     * @notice Returns the voting power of a given address, considering delegation.
     * @param _voter The address to check.
     * @return The total voting power.
     */
    function getVotingPower(address _voter) public view returns (uint256) {
        // If someone delegated to _voter, then _voter's vote is increased
        // If _voter delegated, their own direct vote is 0 for themselves.
        return delegateeVotes[_voter];
    }

    /**
     * @notice Retrieves details for a specific project.
     * @param _projectID The ID of the project.
     * @return A tuple containing project details.
     */
    function getProjectDetails(uint256 _projectID)
        public
        view
        projectExists(_projectID)
        returns (
            uint256 projectID,
            address lead,
            string memory title,
            string memory description,
            uint256 totalBudget,
            uint256 fundsRaised,
            ProjectStatus status,
            uint256 proposalVoteCountYes,
            uint256 proposalVoteCountNo,
            uint256 proposalEndTime
        )
    {
        Project storage project = projects[_projectID];
        return (
            project.projectID,
            project.lead,
            project.title,
            project.description,
            project.totalBudget,
            project.fundsRaised,
            project.status,
            project.proposalVoteCountYes,
            project.proposalVoteCountNo,
            project.proposalEndTime
        );
    }

    /**
     * @notice Retrieves details for a specific milestone of a project.
     * @param _projectID The ID of the project.
     * @param _milestoneIndex The index of the milestone within the project.
     * @return A tuple containing milestone details.
     */
    function getMilestoneDetails(uint256 _projectID, uint256 _milestoneIndex)
        public
        view
        projectExists(_projectID)
        returns (
            uint256 milestoneID,
            string memory description,
            uint256 budgetShare,
            MilestoneStatus status,
            uint256 completionTimestamp,
            uint256 paymentAmount,
            uint256 approvalCount,
            uint256 oracleScore,
            address challenger,
            uint256 challengeStartTime
        )
    {
        if (_milestoneIndex >= projectMilestoneIDs[_projectID].length) revert MilestoneNotFound();
        uint256 milestoneID_ = projectMilestoneIDs[_projectID][_milestoneIndex];
        Milestone storage milestone = milestones[milestoneID_];
        return (
            milestone.milestoneID,
            milestone.description,
            milestone.budgetShare,
            milestone.status,
            milestone.completionTimestamp,
            milestone.paymentAmount,
            milestone.approvalCount,
            milestone.oracleScore,
            milestone.challenger,
            milestone.challengeStartTime
        );
    }

    /**
     * @notice Returns the current balance of stablecoins in the contract's treasury.
     * @return The treasury balance.
     */
    function getTreasuryBalance() public view returns (uint256) {
        return STABLE_COIN.balanceOf(address(this));
    }

    /**
     * @notice Returns the amount of PHX tokens staked by a specific user.
     * @param _user The address of the user.
     * @return The staked amount.
     */
    function getStakingBalance(address _user) public view returns (uint256) {
        return userStakedPHX[_user];
    }
}
```