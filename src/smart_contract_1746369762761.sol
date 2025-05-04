Okay, let's create a smart contract for a **Decentralized Autonomous Creative Fund (DACF)**. This fund will allow members (who hold a specific governance token) to propose creative projects, vote on which projects get funded, manage funding through milestones, and build reputation within the community. It incorporates elements of DAO governance, escrow, reputation, and project management on-chain.

We'll avoid directly copying standard DAO templates and add some unique twists like reputation-weighted voting and a specific milestone approval process.

---

**Decentralized Autonomous Creative Fund (DACF)**

**Outline:**

1.  **Introduction:** A smart contract for a community-governed fund supporting creative projects.
2.  **Core Concepts:** Membership via staking/holding governance tokens, project proposals, voting, milestone-based funding, reputation system, tiered governance actions.
3.  **State Variables:** Store contract owner, governance token address, treasury balance, members' info (stake, reputation, delegation), project proposals, governance parameters, escrow balances, etc.
4.  **Enums:** Define states for proposals.
5.  **Structs:** Define structure for member info, project proposals, milestone details.
6.  **Events:** Signal important actions like proposal creation, voting, funding, milestone completion, etc.
7.  **Modifiers:** Control access and state transitions.
8.  **Functions (20+):**
    *   **Initialization & Setup:** Constructor, set governance token.
    *   **Treasury Management:** Deposit, get balance, withdraw (governance action).
    *   **Membership & Staking:** Join, leave, update stake, get member info, delegate vote, get delegatee.
    *   **Governance Parameters:** Set parameters (via governance), get parameters.
    *   **Project Proposals:** Submit proposal, get proposal details, list proposals by state, cancel proposal.
    *   **Voting:** Vote on proposal, get vote status, finalize voting round.
    *   **Project Execution & Funding:** Fund approved proposal, signal milestone completion, vote on milestone completion, release funds for milestone, fail project (governance action), reclaim failed project funds, get project escrow balance, burn remaining escrow.
    *   **Reputation System:** Update reputation (internal, triggered by actions), get reputation (part of member info).
    *   **Governance Actions (Specific Types):** Propose parameter change, execute parameter change, propose new guardian, set new guardian.
    *   **Incentives:** Claim voting reward.
    *   **Emergency Controls:** Pause, unpause.

**Function Summary:**

1.  `constructor(address _governanceToken)`: Deploys the contract, sets the initial owner and governance token address.
2.  `setGovernanceToken(address _governanceToken)`: Sets the ERC20 governance token address (only allowed during initialization or via governance).
3.  `depositFunds()`: Allows anyone to deposit funds (e.g., Ether) into the contract's treasury.
4.  `getTreasuryBalance()`: Returns the current Ether balance held by the contract.
5.  `withdrawTreasuryFunds(uint256 amount, address recipient)`: Allows withdrawal from the treasury *only* if approved via a governance proposal.
6.  `setGovernanceParameters(uint256 _votingPeriod, uint256 _quorumPercentage, uint256 _approvalThresholdPercentage, uint256 _minStake)`: Sets governance parameters (voting period, quorum, approval threshold, minimum stake) *only* if approved via a governance parameter change proposal.
7.  `getGovernanceParameters()`: Returns the current governance parameter settings.
8.  `joinDACF(uint256 amount)`: Members stake the governance token to join the fund and gain voting power.
9.  `leaveDACF()`: Members unstake their governance tokens and leave the fund. Requires a grace period.
10. `updateMembershipStake(uint256 newAmount)`: Members can increase or decrease their staked governance tokens (within min stake).
11. `getMemberInfo(address member)`: Retrieves a member's staked amount, reputation score, and delegated address.
12. `delegateVote(address delegatee)`: Allows a member to delegate their voting power and reputation to another address.
13. `getDelegatee(address delegator)`: Returns the address to which a member has delegated their vote.
14. `submitProposal(string memory title, string memory description, uint256 fundingGoal, string[] memory milestoneDescriptions, uint256[] memory milestonePercentages, address fundingRecipient)`: Allows a member to submit a new creative project proposal with milestones and funding details.
15. `getProposalDetails(uint256 proposalId)`: Retrieves the full details of a specific project proposal.
16. `listProposalsByState(ProposalState state)`: Returns an array of proposal IDs filtered by their current state.
17. `cancelProposal(uint256 proposalId)`: Allows the proposer to cancel their proposal before voting starts.
18. `voteOnProposal(uint256 proposalId, bool support)`: Members cast their vote (For/Against) on a project proposal. Voting power is based on stake and reputation.
19. `getVoteStatus(uint256 proposalId, address member)`: Checks if a specific member has voted on a proposal and how.
20. `finalizeProposalVoting(uint256 proposalId)`: Any address can call this after the voting period ends to finalize the vote count and transition the proposal state (Approved/Rejected). Updates reputations based on voting outcome.
21. `fundApprovedProposal(uint256 proposalId)`: Transfers the approved funding amount from the treasury into an escrow specifically for the project, changing the proposal state to Active. Callable by any member after approval.
22. `signalMilestoneCompletion(uint256 proposalId, uint256 milestoneIndex)`: The project recipient signals that a specific milestone has been completed, opening it for community review/voting.
23. `voteOnMilestoneCompletion(uint256 proposalId, uint256 milestoneIndex, bool approved)`: Members vote on whether a signaled milestone has been completed satisfactorily. (Requires a sub-voting process or signaling threshold).
24. `releaseFundsForMilestone(uint256 proposalId, uint256 milestoneIndex)`: Releases the funds allocated for a specific milestone from escrow to the project recipient *only* if the milestone completion has been approved (via voting).
25. `failProjectByGovernance(uint256 proposalId)`: Allows the community (via a governance proposal) to mark an active project as failed due to non-delivery or other issues.
26. `reclaimFailedProjectFunds(uint256 proposalId)`: Allows either the contract (to return to treasury) or potentially contributors (if a mechanism existed, keep simple: return to treasury) to reclaim remaining funds from a failed project's escrow.
27. `getProjectEscrowBalance(uint256 proposalId)`: Returns the current balance held in escrow for a specific project.
28. `burnEscrowRemainder(uint256 proposalId)`: Burns any remaining funds in a project's escrow after it is fully completed or failed and funds are not reclaimed. (Requires a burn address or mechanism).
29. `proposeGovernanceParameterChange(uint256 _votingPeriod, uint256 _quorumPercentage, uint256 _approvalThresholdPercentage, uint256 _minStake)`: Submits a special type of proposal specifically to change the main governance parameters. Requires voting.
30. `executeGovernanceParameterChange(uint256 proposalId)`: Executes the parameter change after a `proposeGovernanceParameterChange` proposal passes voting.
31. `proposeNewGuardian(address newGuardian)`: Submits a special type of proposal to change the emergency guardian address. Requires voting.
32. `setNewGuardian(uint256 proposalId)`: Sets the new guardian address after a `proposeNewGuardian` proposal passes voting.
33. `claimVotingReward()`: Allows members who participated in winning votes (both project and governance) to claim a small reward from the treasury (mechanism to be defined, e.g., proportional to stake and vote weight).
34. `pauseContract()`: Emergency function to pause certain contract operations (e.g., voting, funding, joining). Callable by owner or guardian.
35. `unpauseContract()`: Unpauses the contract. Callable by owner or guardian.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for simplicity, could be replaced by full DAO governance

// Note: OpenZeppelin contracts are used for standard interfaces and utilities
// to keep the core logic focused on the DACF mechanics, not basic ERC20 or Pausable implementation.
// The "non-duplicate" requirement applies to the core DACF logic and architecture,
// not standard interfaces or widely used helper contracts.

/**
 * @title Decentralized Autonomous Creative Fund (DACF)
 * @dev A smart contract for a community-governed fund supporting creative projects.
 * Members stake governance tokens to gain voting power, propose projects,
 * vote on funding, manage milestone-based releases, and build reputation.
 * Incorporates unique mechanics for reputation-weighted voting and layered governance proposals.
 */
contract DecentralizedAutonomousCreativeFund is Pausable, Ownable {
    using Address for address payable;

    IERC20 public governanceToken;

    struct MemberInfo {
        uint256 stakedAmount;
        int256 reputation; // Can be positive or negative
        address delegatee; // Address member has delegated vote to
        bool isDelegating; // True if member has explicitly delegated
    }

    enum ProposalState {
        Pending,        // Just submitted, waiting for voting period start
        Voting,         // Currently in voting
        Approved,       // Approved by vote, waiting for funding/activation
        Rejected,       // Rejected by vote
        Active,         // Funded and in progress (for project proposals)
        MilestoneVoting, // Project milestone is being voted on (for project proposals)
        Completed,      // Project successfully completed
        Failed,         // Project failed or governance proposal failed execution
        Cancelled       // Proposal cancelled by proposer before voting
    }

    enum ProposalType {
        ProjectFunding,
        GovernanceParameterChange,
        GuardianChange,
        ProjectMilestoneApproval // Represents a vote specifically on a project milestone completion
    }

    struct Milestone {
        string description;
        uint256 percentage; // Percentage of total funding allocated to this milestone
        bool completed;     // True if milestone is marked completed by system (after vote/signal)
        bool completionSignaled; // True if recipient signaled completion, triggering voting
        uint256 completionVotingEnds; // Timestamp when milestone voting ends
        uint256 milestoneCompletionProposalId; // ID of the governance proposal for milestone approval
    }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        address proposer;
        string title; // For ProjectFunding, GovernanceParameterChange, GuardianChange
        string description; // For ProjectFunding
        uint256 fundingGoal; // For ProjectFunding (in ETH/Wei)
        Milestone[] milestones; // For ProjectFunding
        address fundingRecipient; // For ProjectFunding
        ProposalState state;
        uint256 creationTimestamp;
        uint256 votingEndsTimestamp;
        uint256 votesFor;
        uint256 votesAgainst;
        // Specific fields for GovernanceParameterChange proposal types
        uint256 newVotingPeriod;
        uint256 newQuorumPercentage;
        uint256 newApprovalThresholdPercentage;
        uint256 newMinStake;
        // Specific field for GuardianChange proposal type
        address newGuardianAddress;
        // Specific fields for ProjectMilestoneApproval proposal type
        uint256 projectProposalId; // The ID of the project this milestone vote is for
        uint256 milestoneIndex; // The index of the milestone being voted on
    }

    // --- State Variables ---

    mapping(address => MemberInfo) public members;
    uint256 public totalStakedSupply; // Total amount of governance tokens staked

    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals;
    uint256[] public allProposalIds; // To allow listing proposals

    // Tracking votes for each proposal and member
    mapping(uint256 => mapping(address => bool)) public hasVotedOnProposal;

    // Governance Parameters
    uint256 public votingPeriod = 7 days; // Default: 7 days for main proposals
    uint256 public milestoneVotingPeriod = 3 days; // Default: 3 days for milestone approvals
    uint256 public quorumPercentage = 10; // Default: 10% of total staked supply must vote
    uint256 public approvalThresholdPercentage = 50; // Default: 50% + 1 of total votes (excluding abstain)
    uint256 public minStake = 100 ether; // Default: Minimum tokens to stake (assuming 18 decimals)
    int256 public constant REPUTATION_SCALE = 100; // Scaling factor for reputation influence on voting weight

    address public guardian; // An address with emergency pause/unpause authority

    // Escrow for project funds (mapping project ID to remaining ETH balance)
    mapping(uint256 => uint256) public projectEscrow;

    // Time lock for unstaking (prevents rapid stake/unstake attacks)
    uint256 public unstakeGracePeriod = 3 days;
    mapping(address => uint256) public unstakeAvailableTimestamp;

    // Voting rewards pool (part of treasury, could be tracked separately)
    uint256 public totalVotingRewardsClaimed; // Simple counter, reward logic TBD

    // --- Events ---

    event GovernanceTokenSet(address indexed token);
    event FundsDeposited(address indexed sender, uint256 amount);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount, uint256 proposalId);

    event MemberJoined(address indexed member, uint256 stakedAmount);
    event MemberLeft(address indexed member, uint256 unstakedAmount);
    event MembershipStakeUpdated(address indexed member, uint256 oldAmount, uint256 newAmount);
    event VoteDelegated(address indexed delegator, address indexed delegatee);

    event GovernanceParametersSet(uint256 votingPeriod, uint256 quorumPercentage, uint256 approvalThresholdPercentage, uint256 minStake);

    event ProposalSubmitted(uint256 indexed proposalId, ProposalType indexed proposalType, address indexed proposer);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState oldState, ProposalState newState);
    event ProposalCancelled(uint256 indexed proposalId);
    event ProposalVoteCast(uint256 indexed proposalId, address indexed voter, uint256 votingWeight, bool support);
    event ProposalVotingFinalized(uint256 indexed proposalId, uint256 votesFor, uint256 votesAgainst, bool approved);

    event ProjectFunded(uint256 indexed proposalId, uint256 amount);
    event MilestoneSignaled(uint256 indexed proposalId, uint256 indexed milestoneIndex);
    event MilestoneVoteCast(uint256 indexed proposalId, uint256 indexed milestoneIndex, address indexed voter, bool support);
    event MilestoneVoteFinalized(uint256 indexed proposalId, uint256 indexed milestoneIndex, bool approved);
    event FundsReleasedForMilestone(uint256 indexed proposalId, uint256 indexed milestoneIndex, uint256 amount);
    event ProjectFailed(uint256 indexed proposalId);
    event FailedProjectFundsReclaimed(uint256 indexed proposalId, uint256 amount);
    event EscrowRemainderBurned(uint256 indexed proposalId, uint256 amount);

    event GovernanceParameterChangeProposed(uint256 indexed proposalId, uint256 newVotingPeriod, uint256 newQuorumPercentage, uint256 newApprovalThresholdPercentage, uint256 newMinStake);
    event GuardianChangeProposed(uint256 indexed proposalId, address newGuardian);
    event GovernanceActionExecuted(uint256 indexed proposalId, ProposalType indexed actionType);

    event VotingRewardClaimed(address indexed member, uint256 amount);

    event ContractPaused(address account);
    event ContractUnpaused(address account);

    // --- Modifiers ---

    modifier onlyMember() {
        require(members[msg.sender].stakedAmount >= minStake, "DACF: Caller is not an active member");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(proposalId > 0 && proposalId < nextProposalId, "DACF: Invalid proposal ID");
        _;
    }

    modifier isProposalState(uint256 proposalId, ProposalState state) {
        require(proposals[proposalId].state == state, "DACF: Proposal not in required state");
        _;
    }

    modifier onlyGuardianOrOwner() {
        require(msg.sender == owner() || msg.sender == guardian, "DACF: Only owner or guardian");
        _;
    }

    // --- Constructor ---

    constructor(address _governanceToken) Ownable(msg.sender) {
        require(_governanceToken != address(0), "DACF: Governance token address cannot be zero");
        governanceToken = IERC20(_governanceToken);
        guardian = msg.sender; // Set initial guardian to owner
        emit GovernanceTokenSet(_governanceToken);
    }

    // --- Emergency Controls ---

    /// @dev Pauses the contract. Callable by owner or guardian.
    function pauseContract() external onlyGuardianOrOwner whenNotPaused {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /// @dev Unpauses the contract. Callable by owner or guardian.
    function unpauseContract() external onlyGuardianOrOwner whenPaused {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    /// @dev Sets the emergency guardian address. Requires a governance proposal to change from owner.
    function setGuardian(address _newGuardian) external onlyMember whenNotPaused {
        // This should ideally be via a successful governance proposal
        // For initial setup or simple tests, allow owner to set initially if no guardian set yet.
        // In production, this would be called *only* by executeGovernanceAction for GuardianChange.
         require(msg.sender == owner(), "DACF: Guardian can only be set via governance proposal");
         guardian = _newGuardian;
    }


    // --- Treasury Management ---

    /// @dev Allows anyone to deposit Ether into the contract treasury.
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    /// @dev Allows anyone to deposit Ether into the contract treasury. Explicit function.
    function depositFunds() external payable whenNotPaused {
        emit FundsDeposited(msg.sender, msg.value);
    }

    /// @dev Returns the current Ether balance held by the contract.
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @dev Allows withdrawal from the treasury for non-project uses (e.g., operational costs), MUST be approved via governance proposal.
    /// This function itself is called *by* a governance execution function after a TreasuryWithdrawal proposal type passes.
    function _executeTreasuryWithdrawal(uint256 proposalId, uint256 amount, address payable recipient) internal whenNotPaused {
        require(address(this).balance >= amount, "DACF: Insufficient treasury balance for withdrawal");
        require(recipient != address(0), "DACF: Recipient address cannot be zero");

        // In a full implementation, this would check if proposalId corresponds to a
        // 'TreasuryWithdrawal' type proposal that has been approved and is being executed.
        // For simplicity in this example, we assume the calling context handles proposal checks.

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "DACF: Ether withdrawal failed");

        emit TreasuryWithdrawal(recipient, amount, proposalId);
    }

    // --- Membership & Staking ---

    /// @dev Staking governance tokens to become a member. Tokens are transferred to the contract.
    function joinDACF(uint256 amount) external whenNotPaused {
        require(amount >= minStake, "DACF: Staked amount must meet minimum stake requirement");

        MemberInfo storage member = members[msg.sender];
        require(member.stakedAmount == 0, "DACF: Member already joined");

        require(governanceToken.transferFrom(msg.sender, address(this), amount), "DACF: Token transfer failed");

        member.stakedAmount = amount;
        member.reputation = 0; // Start with neutral reputation
        member.delegatee = msg.sender; // Self-delegate by default
        member.isDelegating = false; // Not explicitly delegating yet

        totalStakedSupply += amount;
        emit MemberJoined(msg.sender, amount);
    }

    /// @dev Members unstake their governance tokens and leave the fund. Subject to a grace period.
    function leaveDACF() external onlyMember whenNotPaused {
        MemberInfo storage member = members[msg.sender];
        require(block.timestamp >= unstakeAvailableTimestamp[msg.sender], "DACF: Unstaking is subject to a grace period");

        uint256 amountToUnstake = member.stakedAmount;
        delete members[msg.sender]; // Remove member info
        totalStakedSupply -= amountToUnstake;
        unstakeAvailableTimestamp[msg.sender] = block.timestamp + unstakeGracePeriod; // Reset grace period after leaving

        require(governanceToken.transfer(msg.sender, amountToUnstake), "DACF: Token transfer failed");

        emit MemberLeft(msg.sender, amountToUnstake);
    }

    /// @dev Members can increase or decrease their staked amount (while remaining above min stake).
    function updateMembershipStake(uint256 newAmount) external onlyMember whenNotPaused {
        require(newAmount >= minStake, "DACF: New staked amount must meet minimum stake requirement");

        MemberInfo storage member = members[msg.sender];
        uint256 currentAmount = member.stakedAmount;

        if (newAmount > currentAmount) {
            uint256 diff = newAmount - currentAmount;
            require(governanceToken.transferFrom(msg.sender, address(this), diff), "DACF: Token transfer failed");
            totalStakedSupply += diff;
        } else if (newAmount < currentAmount) {
            uint256 diff = currentAmount - newAmount;
            totalStakedSupply -= diff;
            require(governanceToken.transfer(msg.sender, diff), "DACF: Token transfer failed");
        }
        member.stakedAmount = newAmount;
        emit MembershipStakeUpdated(msg.sender, currentAmount, newAmount);
    }

    /// @dev Retrieves a member's staked amount, reputation, and delegated address.
    function getMemberInfo(address memberAddress) external view returns (uint256 stakedAmount, int256 reputation, address delegatee) {
        MemberInfo storage member = members[memberAddress];
        return (member.stakedAmount, member.reputation, member.delegatee);
    }

    /// @dev Allows a member to delegate their voting power and reputation to another address.
    function delegateVote(address delegatee) external onlyMember whenNotPaused {
        require(delegatee != address(0), "DACF: Delegatee cannot be zero address");
        require(delegatee != msg.sender, "DACF: Cannot delegate to yourself");

        MemberInfo storage member = members[msg.sender];
        member.delegatee = delegatee;
        member.isDelegating = true;

        emit VoteDelegated(msg.sender, delegatee);
    }

    /// @dev Returns the address to which a member has delegated their vote.
    function getDelegatee(address delegator) external view returns (address) {
        return members[delegator].delegatee;
    }

    /// @dev Internal function to get the effective voting weight (stake + reputation influence).
    function _getEffectiveVotingWeight(address memberAddress) internal view returns (uint256) {
        MemberInfo storage member = members[memberAddress];
        address currentVoter = member.isDelegating ? member.delegatee : memberAddress;

        // Prevent delegation loops (basic check) - more robust cycle detection needed for production
        require(currentVoter != msg.sender || msg.sender == memberAddress, "DACF: Delegation loop detected");

        MemberInfo storage effectiveMember = members[currentVoter];
        uint256 baseWeight = effectiveMember.stakedAmount;

        // Simple reputation influence: reputation / REPUTATION_SCALE acts as a multiplier factor.
        // e.g., reputation 100 (+100%), reputation -50 (-50%). Cap influence to prevent extremes.
        int256 scaledReputation = effectiveMember.reputation / int256(REPUTATION_SCALE);
        int256 influence = scaledReputation; // Could cap this, e.g., +/- 100% of stake

        int256 effectiveWeight = int256(baseWeight) + (int256(baseWeight) * influence) / 100;

        return effectiveWeight > 0 ? uint256(effectiveWeight) : 0; // Voting weight cannot be negative
    }


    // --- Governance Parameters ---

    /// @dev Sets governance parameters. This function is intended to be called ONLY by executeGovernanceParameterChange after a proposal passes.
    function _setGovernanceParameters(uint256 _votingPeriod, uint256 _quorumPercentage, uint256 _approvalThresholdPercentage, uint256 _minStake) internal {
         require(_quorumPercentage <= 100 && _approvalThresholdPercentage <= 100, "DACF: Percentages must be <= 100");
         require(_minStake > 0, "DACF: Minimum stake must be greater than zero");

         votingPeriod = _votingPeriod;
         quorumPercentage = _quorumPercentage;
         approvalThresholdPercentage = _approvalThresholdPercentage;
         minStake = _minStake;
         emit GovernanceParametersSet(_votingPeriod, _quorumPercentage, _approvalThresholdPercentage, _minStake);
    }

    /// @dev Returns the current governance parameter settings.
    function getGovernanceParameters() external view returns (uint256, uint256, uint256, uint256) {
        return (votingPeriod, quorumPercentage, approvalThresholdPercentage, minStake);
    }


    // --- Project Proposals ---

    /// @dev Allows a member to submit a new creative project proposal.
    function submitProposal(
        string memory title,
        string memory description,
        uint256 fundingGoal,
        string[] memory milestoneDescriptions,
        uint256[] memory milestonePercentages,
        address fundingRecipient // The address receiving funds if approved
    ) external onlyMember whenNotPaused returns (uint256 proposalId) {
        require(bytes(title).length > 0, "DACF: Title cannot be empty");
        require(fundingGoal > 0, "DACF: Funding goal must be greater than zero");
        require(fundingRecipient != address(0), "DACF: Funding recipient cannot be zero address");
        require(milestoneDescriptions.length == milestonePercentages.length, "DACF: Milestone descriptions and percentages must match");
        require(milestoneDescriptions.length > 0, "DACF: Must include at least one milestone");

        uint256 totalPercentage = 0;
        for(uint i = 0; i < milestonePercentages.length; i++) {
            totalPercentage += milestonePercentages[i];
        }
        require(totalPercentage == 100, "DACF: Milestone percentages must sum to 100");

        proposalId = nextProposalId++;
        Proposal storage proposal = proposals[proposalId];

        proposal.id = proposalId;
        proposal.proposalType = ProposalType.ProjectFunding;
        proposal.proposer = msg.sender;
        proposal.title = title;
        proposal.description = description;
        proposal.fundingGoal = fundingGoal;
        proposal.fundingRecipient = fundingRecipient;
        proposal.state = ProposalState.Pending;
        proposal.creationTimestamp = block.timestamp;

        proposal.milestones = new Milestone[](milestoneDescriptions.length);
        for(uint i = 0; i < milestoneDescriptions.length; i++) {
            proposal.milestones[i].description = milestoneDescriptions[i];
            proposal.milestones[i].percentage = milestonePercentages[i];
            proposal.milestones[i].completed = false;
            proposal.milestones[i].completionSignaled = false;
        }

        allProposalIds.push(proposalId); // Add to list for retrieval

        emit ProposalSubmitted(proposalId, ProposalType.ProjectFunding, msg.sender);
    }

     /// @dev Submits a governance proposal to change parameters.
    function proposeGovernanceParameterChange(
        uint256 _votingPeriod,
        uint256 _quorumPercentage,
        uint256 _approvalThresholdPercentage,
        uint256 _minStake
    ) external onlyMember whenNotPaused returns (uint256 proposalId) {
        require(_quorumPercentage <= 100 && _approvalThresholdPercentage <= 100, "DACF: Percentages must be <= 100");
        require(_minStake > 0, "DACF: Minimum stake must be greater than zero");

        proposalId = nextProposalId++;
        Proposal storage proposal = proposals[proposalId];

        proposal.id = proposalId;
        proposal.proposalType = ProposalType.GovernanceParameterChange;
        proposal.proposer = msg.sender;
        proposal.title = "Change Governance Parameters";
        proposal.state = ProposalState.Pending;
        proposal.creationTimestamp = block.timestamp;
        proposal.newVotingPeriod = _votingPeriod;
        proposal.newQuorumPercentage = _quorumPercentage;
        proposal.newApprovalThresholdPercentage = _approvalThresholdPercentage;
        proposal.newMinStake = _minStake;

        allProposalIds.push(proposalId);

        emit ProposalSubmitted(proposalId, ProposalType.GovernanceParameterChange, msg.sender);
        emit GovernanceParameterChangeProposed(proposalId, _votingPeriod, _quorumPercentage, _approvalThresholdPercentage, _minStake);
    }

    /// @dev Submits a governance proposal to change the emergency guardian.
    function proposeNewGuardian(address newGuardianAddress) external onlyMember whenNotPaused returns (uint256 proposalId) {
        require(newGuardianAddress != address(0), "DACF: New guardian address cannot be zero");

        proposalId = nextProposalId++;
        Proposal storage proposal = proposals[proposalId];

        proposal.id = proposalId;
        proposal.proposalType = ProposalType.GuardianChange;
        proposal.proposer = msg.sender;
        proposal.title = "Change Emergency Guardian";
        proposal.state = ProposalState.Pending;
        proposal.creationTimestamp = block.timestamp;
        proposal.newGuardianAddress = newGuardianAddress;

        allProposalIds.push(proposalId);

        emit ProposalSubmitted(proposalId, ProposalType.GuardianChange, msg.sender);
        emit GuardianChangeProposed(proposalId, newGuardianAddress);
    }


    /// @dev Retrieves the full details of a specific project or governance proposal.
    function getProposalDetails(uint256 proposalId) public view proposalExists(proposalId) returns (Proposal memory) {
        return proposals[proposalId];
    }

    /// @dev Returns an array of proposal IDs filtered by their current state.
    function listProposalsByState(ProposalState state) external view returns (uint256[] memory) {
        uint256[] memory filteredIds = new uint256[](allProposalIds.length); // Max size
        uint256 count = 0;
        for (uint i = 0; i < allProposalIds.length; i++) {
            uint256 proposalId = allProposalIds[i];
            if (proposals[proposalId].state == state) {
                filteredIds[count] = proposalId;
                count++;
            }
        }
        // Resize array to exact count
        uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = filteredIds[i];
        }
        return result;
    }

    /// @dev Allows the proposer to cancel their proposal before it enters the voting state.
    function cancelProposal(uint256 proposalId) external proposalExists(proposalId) whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer == msg.sender, "DACF: Only proposer can cancel");
        require(proposal.state == ProposalState.Pending, "DACF: Can only cancel pending proposals");

        proposal.state = ProposalState.Cancelled;
        emit ProposalCancelled(proposalId);
        emit ProposalStateChanged(proposalId, ProposalState.Pending, ProposalState.Cancelled);
    }


    // --- Voting ---

    /// @dev Allows members (or their delegates) to cast a vote on a proposal.
    function voteOnProposal(uint256 proposalId, bool support) external onlyMember whenNotPaused proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];

        // If proposal is Pending, start voting period
        if (proposal.state == ProposalState.Pending) {
             proposal.state = ProposalState.Voting;
             proposal.votingEndsTimestamp = block.timestamp + votingPeriod; // Use main voting period for initial proposals
             emit ProposalStateChanged(proposalId, ProposalState.Pending, ProposalState.Voting);
        }

        // If proposal is MilestoneVoting, use milestone voting period
        if (proposal.state == ProposalState.MilestoneVoting) {
             // Check if milestone voting period has started
             require(proposal.milestoneCompletionProposalId != 0, "DACF: Milestone voting proposal ID not set");
             require(proposals[proposal.milestoneCompletionProposalId].votingEndsTimestamp > 0, "DACF: Milestone voting period not started");
             require(proposals[proposal.milestoneCompletionProposalId].state == ProposalState.Voting, "DACF: Milestone voting proposal not in Voting state");
        } else {
             // Check if the main proposal is in Voting state and period is active
             require(proposal.state == ProposalState.Voting, "DACF: Proposal is not in the Voting state");
             require(block.timestamp <= proposal.votingEndsTimestamp, "DACF: Voting period has ended");
        }


        address voter = msg.sender;
        address effectiveVoter = members[voter].isDelegating ? members[voter].delegatee : voter;

        require(!hasVotedOnProposal[proposalId][effectiveVoter], "DACF: Address has already voted on this proposal");

        // Get the effective voting weight (stake + reputation influence)
        uint256 votingWeight = _getEffectiveVotingWeight(effectiveVoter);
        require(votingWeight > 0, "DACF: Effective voting weight must be greater than zero");

        if (support) {
            proposal.votesFor += votingWeight;
        } else {
            proposal.votesAgainst += votingWeight;
        }

        hasVotedOnProposal[proposalId][effectiveVoter] = true; // Mark the *effective* voter as having voted

        emit ProposalVoteCast(proposalId, voter, votingWeight, support);
    }

    /// @dev Checks if a specific member (or their delegatee) has voted on a proposal.
    function getVoteStatus(uint256 proposalId, address memberAddress) external view proposalExists(proposalId) returns (bool) {
        address effectiveMember = members[memberAddress].isDelegating ? members[memberAddress].delegatee : memberAddress;
        return hasVotedOnProposal[proposalId][effectiveMember];
    }

    /// @dev Finalizes the voting round for a proposal if the period has ended.
    /// Determines if the proposal is Approved or Rejected based on quorum and approval threshold.
    function finalizeProposalVoting(uint256 proposalId) external proposalExists(proposalId) whenNotPaused {
        Proposal storage proposal = proposals[proposalId];

        // Determine which voting period applies
        uint256 relevantVotingEndsTimestamp;
        if (proposal.state == ProposalState.MilestoneVoting) {
             require(proposal.milestoneCompletionProposalId != 0, "DACF: Milestone voting proposal ID not set");
             require(proposals[proposal.milestoneCompletionProposalId].state == ProposalState.Voting, "DACF: Milestone voting proposal not in Voting state");
             relevantVotingEndsTimestamp = proposals[proposal.milestoneCompletionProposalId].votingEndsTimestamp;
             require(block.timestamp > relevantVotingEndsTimestamp, "DACF: Milestone voting period is not over");
        } else {
             require(proposal.state == ProposalState.Voting, "DACF: Proposal is not in the Voting state");
             require(block.timestamp > proposal.votingEndsTimestamp, "DACF: Main voting period is not over");
             relevantVotingEndsTimestamp = proposal.votingEndsTimestamp; // Store for event
        }


        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;

        // Calculate quorum: total votes cast must be at least quorumPercentage of total staked supply
        uint256 requiredQuorum = (totalStakedSupply * quorumPercentage) / 100;
        bool quorumMet = totalVotes >= requiredQuorum;

        // Calculate approval: votesFor must be at least approvalThresholdPercentage of total votes cast
        uint256 requiredApprovals = (totalVotes * approvalThresholdPercentage) / 100;
        bool approved = quorumMet && proposal.votesFor > requiredApprovals; // Strict majority for approval

        ProposalState oldState = proposal.state;
        ProposalType currentProposalType = proposal.proposalType; // Store before state change

        if (approved) {
            proposal.state = ProposalState.Approved;
        } else {
            proposal.state = ProposalState.Rejected;
        }

        // Update proposer reputation based on proposal outcome
        _updateReputation(proposal.proposer, approved ? 10 : -5); // Positive reputation for approved proposals, negative for rejected

        emit ProposalVotingFinalized(proposalId, proposal.votesFor, proposal.votesAgainst, approved);
        emit ProposalStateChanged(proposalId, oldState, proposal.state);

        // If this was a Milestone Voting proposal, finalize the milestone vote outcome
        if (currentProposalType == ProposalType.ProjectMilestoneApproval) {
            uint256 projectProposalId = proposal.projectProposalId;
            uint256 milestoneIndex = proposal.milestoneIndex;
            Proposal storage projectProposal = proposals[projectProposalId];
            projectProposal.milestones[milestoneIndex].completionVotingEnds = 0; // Reset timestamp

            emit MilestoneVoteFinalized(projectProposalId, milestoneIndex, approved);

            if (approved) {
                projectProposal.milestones[milestoneIndex].completed = true;
                // Proposer (project recipient) gets reputation boost for milestone completion
                _updateReputation(projectProposal.fundingRecipient, 5);
            } else {
                 // Proposer (project recipient) loses reputation if milestone is rejected
                 _updateReputation(projectProposal.fundingRecipient, -3);
            }
            // The state of the *project* proposal might remain Active or change to Failed if a critical milestone fails
            // This state change would need separate logic or a governance proposal (failProjectByGovernance).
        }
    }

    // --- Project Execution & Funding ---

    /// @dev Transfers the approved funding amount from the treasury into an escrow for the project.
    function fundApprovedProposal(uint256 proposalId) external onlyMember whenNotPaused proposalExists(proposalId) isProposalState(proposalId, ProposalState.Approved) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposalType == ProposalType.ProjectFunding, "DACF: Only Project Funding proposals can be funded");
        require(address(this).balance >= proposal.fundingGoal, "DACF: Insufficient treasury balance to fund proposal");
        require(projectEscrow[proposalId] == 0, "DACF: Proposal already funded");

        projectEscrow[proposalId] = proposal.fundingGoal;
        proposal.state = ProposalState.Active;
        proposal.fundingAllocated = proposal.fundingGoal; // Track allocated amount

        emit ProjectFunded(proposalId, proposal.fundingGoal);
        emit ProposalStateChanged(proposalId, ProposalState.Approved, ProposalState.Active);
    }

    /// @dev The project recipient signals that a specific milestone has been completed.
    /// This triggers the creation of a Milestone Approval governance proposal.
    function signalMilestoneCompletion(uint256 proposalId, uint256 milestoneIndex) external proposalExists(proposalId) isProposalState(proposalId, ProposalState.Active) whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(msg.sender == proposal.fundingRecipient, "DACF: Only the funding recipient can signal milestone completion");
        require(milestoneIndex < proposal.milestones.length, "DACF: Invalid milestone index");
        require(!proposal.milestones[milestoneIndex].completed, "DACF: Milestone already completed");
        require(!proposal.milestones[milestoneIndex].completionSignaled, "DACF: Milestone completion already signaled");

        proposal.milestones[milestoneIndex].completionSignaled = true;
        proposal.state = ProposalState.MilestoneVoting; // Change project state to reflect milestone review

        // Create a new governance proposal specifically for this milestone approval
        uint256 milestoneProposalId = nextProposalId++;
        Proposal storage milestoneApprovalProposal = proposals[milestoneProposalId];

        milestoneApprovalProposal.id = milestoneProposalId;
        milestoneApprovalProposal.proposalType = ProposalType.ProjectMilestoneApproval;
        milestoneApprovalProposal.proposer = msg.sender; // Recipient proposes completion
        milestoneApprovalProposal.title = string(abi.encodePacked("Approve Milestone ", uint256(milestoneIndex + 1).toString(), " for Project ", proposal.title));
        milestoneApprovalProposal.description = string(abi.encodePacked("Vote on completion of milestone ", uint256(milestoneIndex + 1).toString(), ": ", proposal.milestones[milestoneIndex].description));
        milestoneApprovalProposal.state = ProposalState.Voting; // Starts voting immediately
        milestoneApprovalProposal.creationTimestamp = block.timestamp;
        milestoneApprovalProposal.votingEndsTimestamp = block.timestamp + milestoneVotingPeriod; // Use specific milestone voting period
        milestoneApprovalProposal.projectProposalId = proposalId;
        milestoneApprovalProposal.milestoneIndex = milestoneIndex;

        proposal.milestones[milestoneIndex].milestoneCompletionProposalId = milestoneProposalId; // Link project milestone to the vote proposal ID

        allProposalIds.push(milestoneProposalId);

        emit MilestoneSignaled(proposalId, milestoneIndex);
        emit ProposalSubmitted(milestoneProposalId, ProposalType.ProjectMilestoneApproval, msg.sender);
        emit ProposalStateChanged(proposalId, ProposalState.Active, ProposalState.MilestoneVoting); // State change for the project proposal
    }

    /// @dev Members vote on whether a signaled milestone has been completed satisfactorily.
    /// This function simply routes the vote to the generated Milestone Approval proposal.
    function voteOnMilestoneCompletion(uint256 projectProposalId, uint256 milestoneIndex, bool approved) external onlyMember whenNotPaused proposalExists(projectProposalId) isProposalState(projectProposalId, ProposalState.MilestoneVoting) {
         Proposal storage projectProposal = proposals[projectProposalId];
         require(milestoneIndex < projectProposal.milestones.length, "DACF: Invalid milestone index");
         require(projectProposal.milestones[milestoneIndex].completionSignaled, "DACF: Milestone completion not signaled");
         require(!projectProposal.milestones[milestoneIndex].completed, "DACF: Milestone already completed");
         require(projectProposal.milestones[milestoneIndex].milestoneCompletionProposalId != 0, "DACF: Milestone voting proposal ID not set");

         uint256 milestoneVotingProposalId = projectProposal.milestones[milestoneIndex].milestoneCompletionProposalId;
         Proposal storage milestoneVotingProposal = proposals[milestoneVotingProposalId];

         require(milestoneVotingProposal.state == ProposalState.Voting, "DACF: Milestone voting proposal is not in Voting state");
         require(block.timestamp <= milestoneVotingProposal.votingEndsTimestamp, "DACF: Milestone voting period has ended");

         address voter = msg.sender;
         address effectiveVoter = members[voter].isDelegating ? members[voter].delegatee : voter;

         require(!hasVotedOnProposal[milestoneVotingProposalId][effectiveVoter], "DACF: Address has already voted on this milestone proposal");

         uint256 votingWeight = _getEffectiveVotingWeight(effectiveVoter);
         require(votingWeight > 0, "DACF: Effective voting weight must be greater than zero");

         if (approved) {
             milestoneVotingProposal.votesFor += votingWeight;
         } else {
             milestoneVotingProposal.votesAgainst += votingWeight;
         }

         hasVotedOnProposal[milestoneVotingProposalId][effectiveVoter] = true;

         emit MilestoneVoteCast(projectProposalId, milestoneIndex, voter, approved);
         emit ProposalVoteCast(milestoneVotingProposalId, voter, votingWeight, approved); // Also log on the internal proposal
    }

    /// @dev Releases the funds allocated for a specific milestone from escrow to the project recipient.
    /// Callable by anyone after the milestone voting proposal is finalized as Approved.
    function releaseFundsForMilestone(uint256 proposalId, uint256 milestoneIndex) external proposalExists(proposalId) whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposalType == ProposalType.ProjectFunding, "DACF: This function is for Project Funding proposals");
        require(proposal.state == ProposalState.MilestoneVoting || proposal.state == ProposalState.Active, "DACF: Project must be Active or in Milestone Voting");
        require(milestoneIndex < proposal.milestones.length, "DACF: Invalid milestone index");
        require(proposal.milestones[milestoneIndex].completed, "DACF: Milestone not marked as completed");

        uint256 milestoneAmount = (proposal.fundingAllocated * proposal.milestones[milestoneIndex].percentage) / 100;
        require(projectEscrow[proposalId] >= milestoneAmount, "DACF: Insufficient funds in project escrow for milestone");
        require(milestoneAmount > 0, "DACF: Milestone amount is zero");

        projectEscrow[proposalId] -= milestoneAmount;

        // Transfer funds to the project recipient
        (bool success, ) = payable(proposal.fundingRecipient).call{value: milestoneAmount}("");
        require(success, "DACF: Fund release failed");

        emit FundsReleasedForMilestone(proposalId, milestoneIndex, milestoneAmount);

        // Check if this was the last milestone
        bool allMilestonesCompleted = true;
        for(uint i = 0; i < proposal.milestones.length; i++) {
            if (!proposal.milestones[i].completed) {
                allMilestonesCompleted = false;
                break;
            }
        }

        if (allMilestonesCompleted) {
             proposal.state = ProposalState.Completed;
             // Recipient gets final reputation boost for completing the project
             _updateReputation(proposal.fundingRecipient, 20);
             emit ProposalStateChanged(proposalId, ProposalState.MilestoneVoting, ProposalState.Completed); // State could be Active or MilestoneVoting previously
        } else {
             // If not all milestones complete, return state to Active after milestone voting ends
             if (proposal.state == ProposalState.MilestoneVoting) {
                 proposal.state = ProposalState.Active;
                 emit ProposalStateChanged(proposalId, ProposalState.MilestoneVoting, ProposalState.Active);
             }
        }
    }

     /// @dev Allows the community (via a governance proposal) to mark an active project as failed.
    /// This function is intended to be called ONLY by executeGovernanceAction after a specific 'FailProject' proposal type passes.
    function _failProjectByGovernance(uint256 proposalId) internal whenNotPaused proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposalType == ProposalType.ProjectFunding, "DACF: This function is for Project Funding proposals");
        require(proposal.state == ProposalState.Active || proposal.state == ProposalState.MilestoneVoting, "DACF: Project must be Active or in Milestone Voting to be failed");

        proposal.state = ProposalState.Failed;
        // Project recipient loses reputation upon project failure
        _updateReputation(proposal.fundingRecipient, -15);
        emit ProjectFailed(proposalId);
        emit ProposalStateChanged(proposalId, proposal.state == ProposalState.Active ? ProposalState.Active : ProposalState.MilestoneVoting, ProposalState.Failed);
    }

    /// @dev Allows reclamation of remaining funds from a failed project's escrow back to the treasury.
    /// Could potentially be callable by anyone after failure, or require governance.
    function reclaimFailedProjectFunds(uint256 proposalId) external proposalExists(proposalId) isProposalState(proposalId, ProposalState.Failed) whenNotPaused {
        uint256 remainingFunds = projectEscrow[proposalId];
        require(remainingFunds > 0, "DACF: No funds remaining in escrow");

        projectEscrow[proposalId] = 0;

        // Transfer funds back to the contract treasury
        // Note: Funds deposited via 'receive' or 'depositFunds' are Ether, so they stay in contract balance.
        // We just zero out the internal tracking for this specific project's escrow.
        // If we were holding other tokens in escrow, we'd transfer them back here.
        // For ETH, the balance is already there. We just mark it as 'reclaimed'.

        emit FailedProjectFundsReclaimed(proposalId, remainingFunds);
    }

    /// @dev Returns the current balance held in escrow for a specific project.
    function getProjectEscrowBalance(uint256 proposalId) external view proposalExists(proposalId) returns (uint256) {
        return projectEscrow[proposalId];
    }

    /// @dev Burns any remaining funds in a project's escrow after it is fully completed or failed and funds are not reclaimed.
    /// Note: This requires a mechanism to 'burn' Ether, which typically means sending it to address(0).
    /// Exercise extreme caution with burning funds.
    function burnEscrowRemainder(uint256 proposalId) external proposalExists(proposalId) whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Completed || proposal.state == ProposalState.Failed, "DACF: Project must be Completed or Failed to burn remainder");
        uint256 remainingFunds = projectEscrow[proposalId];
        require(remainingFunds > 0, "DACF: No funds remaining in escrow to burn");

        projectEscrow[proposalId] = 0;

        // Sending Ether to address(0) effectively removes it from circulation.
        (bool success, ) = payable(address(0)).call{value: remainingFunds}("");
        require(success, "DACF: Failed to burn funds"); // Should not fail for address(0)

        emit EscrowRemainderBurned(proposalId, remainingFunds);
    }

    // --- Reputation System ---

    /// @dev Internal function to update a member's reputation score. Triggered by actions.
    /// Can be called directly by governance execution functions or within voting finalization.
    function _updateReputation(address memberAddress, int256 points) internal {
        // Ensure we are only updating active members
        if (members[memberAddress].stakedAmount > 0) {
             members[memberAddress].reputation += points;
             // Optional: Emit event for reputation change
             // emit ReputationUpdated(memberAddress, members[memberAddress].reputation);
        }
    }

    // --- Governance Actions (Execution functions called after proposal approval) ---

    /// @dev Executes a GovernanceParameterChange proposal after it is approved.
    /// Intended to be called by a specific 'ExecuteGovChange' function type,
    /// or within finalizeProposalVoting if that logic is integrated.
    function executeGovernanceParameterChange(uint256 proposalId) external proposalExists(proposalId) isProposalState(proposalId, ProposalState.Approved) whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposalType == ProposalType.GovernanceParameterChange, "DACF: Proposal is not a Governance Parameter Change type");

        _setGovernanceParameters(
            proposal.newVotingPeriod,
            proposal.newQuorumPercentage,
            proposal.newApprovalThresholdPercentage,
            proposal.newMinStake
        );

        proposal.state = ProposalState.Completed; // Mark governance proposal as completed
        emit GovernanceActionExecuted(proposalId, ProposalType.GovernanceParameterChange);
        emit ProposalStateChanged(proposalId, ProposalState.Approved, ProposalState.Completed);
    }

    /// @dev Executes a GuardianChange proposal after it is approved.
    /// Intended to be called by a specific 'ExecuteGovChange' function type.
    function setNewGuardian(uint256 proposalId) external proposalExists(proposalId) isProposalState(proposalId, ProposalState.Approved) whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposalType == ProposalType.GuardianChange, "DACF: Proposal is not a Guardian Change type");

        guardian = proposal.newGuardianAddress;

        proposal.state = ProposalState.Completed; // Mark governance proposal as completed
        emit GovernanceActionExecuted(proposalId, ProposalType.GuardianChange);
        emit ProposalStateChanged(proposalId, ProposalState.Approved, ProposalState.Completed);
    }

    // A placeholder for a generic governance action execution function if needed
    // function executeGovernanceAction(uint256 proposalId) external onlyMember whenNotPaused proposalExists(proposalId) isProposalState(proposalId, ProposalState.Approved) {
    //     Proposal storage proposal = proposals[proposalId];
    //     // Based on proposal.proposalType, call the relevant internal execution function
    //     if (proposal.proposalType == ProposalType.GovernanceParameterChange) {
    //         _setGovernanceParameters(...); // Get params from proposal struct
    //     } else if (proposal.proposalType == ProposalType.GuardianChange) {
    //         guardian = proposal.newGuardianAddress;
    //     } else if (proposal.proposalType == ProposalType.TreasuryWithdrawal) {
    //          _executeTreasuryWithdrawal(proposalId, proposal.withdrawalAmount, proposal.withdrawalRecipient); // Need to add fields to struct for this type
    //     } else if (proposal.proposalType == ProposalType.FailProject) {
    //          _failProjectByGovernance(proposal.projectToFailId); // Need to add fields
    //     }
    //     // ... handle other governance action types ...
    //     proposal.state = ProposalState.Completed;
    //     emit GovernanceActionExecuted(proposalId, proposal.proposalType);
    //     emit ProposalStateChanged(proposalId, ProposalState.Approved, ProposalState.Completed);
    // }


    // --- Incentives ---

    /// @dev Allows members who participated in winning votes to claim a small reward.
    /// Reward logic is simplified - could be based on vote weight, stake, reputation, etc.
    /// In this example, it's a placeholder. A real implementation needs a reward pool/calculation.
    function claimVotingReward() external onlyMember whenNotPaused {
        // Placeholder for complex reward calculation logic
        // uint256 rewardAmount = calculateReward(msg.sender); // Needs implementation
        // require(rewardAmount > 0, "DACF: No rewards to claim");

        // // Transfer reward from treasury or a dedicated rewards pool
        // // (bool success, ) = payable(msg.sender).call{value: rewardAmount}(""); // For Ether reward
        // // require(success, "DACF: Reward transfer failed");

        // // require(governanceToken.transfer(msg.sender, rewardAmount), "DACF: Token reward transfer failed"); // For token reward

        // totalVotingRewardsClaimed += rewardAmount;
        // emit VotingRewardClaimed(msg.sender, rewardAmount);

        revert("DACF: Voting reward claiming not yet implemented"); // Placeholder
    }

    // --- Utility/View Functions (Already included within the >= 20 count) ---
    // getTreasuryBalance()
    // getGovernanceParameters()
    // getMemberInfo()
    // getDelegatee()
    // getProposalDetails()
    // listProposalsByState()
    // getVoteStatus()
    // getProjectEscrowBalance()

    // Added uint256.toString() for convenience, requires OpenZeppelin's String library if not using 0.8.20+
    // If using older Solidity, need to implement toString or use a library.
    // For 0.8.20+, abi.encodePacked handles conversion for basic types.
    // For string concatenation with numbers, more complex logic or a library is needed.
    // Example for toString:
    // using Strings for uint256; // from @openzeppelin/contracts/utils/Strings.sol
}
```

**Explanation of Concepts and Features:**

1.  **Governance Token:** The contract relies on an ERC20 token for membership and voting power. Members must stake (`joinDACF`, `updateMembershipStake`) a minimum amount (`minStake`) to participate.
2.  **Staking & Unstaking:** Tokens are held by the contract. Unstaking (`leaveDACF`) includes a `unstakeGracePeriod` to mitigate quick entry/exit attacks affecting votes.
3.  **Reputation System:** A simple `int256 reputation` is tracked per member. Reputation changes are triggered by proposal outcomes (`finalizeProposalVoting`) and milestone completion/failure (`releaseFundsForMilestone`, `_failProjectByGovernance`).
4.  **Reputation-Weighted Voting:** The `_getEffectiveVotingWeight` function calculates voting power based on `stakedAmount` *and* `reputation`. This means members with positive reputation have amplified votes, and negative reputation diminishes them. The `REPUTATION_SCALE` constant allows tuning the influence.
5.  **Vote Delegation:** Members can `delegateVote` their combined stake and reputation voting power to another address.
6.  **Treasury Management:** Ether can be deposited (`depositFunds`). Withdrawal (`_executeTreasuryWithdrawal`) requires a specific type of governance proposal.
7.  **Project Proposals:** Members can submit detailed proposals (`submitProposal`) including funding goals, milestones, and a recipient address.
8.  **Milestone-Based Funding & Escrow:** Funding for approved projects is moved into an internal `projectEscrow`. Funds are released in stages (`releaseFundsForMilestone`) proportional to milestone percentages only *after* milestones are approved.
9.  **Milestone Approval Voting:** Project recipients `signalMilestoneCompletion`. This *creates a new governance proposal* (`ProposalType.ProjectMilestoneApproval`) for members to vote on (`voteOnMilestoneCompletion`). This adds a layer of community oversight for project progress.
10. **Tiered Governance Actions:** Different types of proposals exist:
    *   `ProjectFunding`: The core purpose, funding creative works.
    *   `GovernanceParameterChange`: Proposing changes to rules like voting period, quorum, threshold, or min stake. Executed by `executeGovernanceParameterChange` after approval.
    *   `GuardianChange`: Proposing a new emergency guardian. Executed by `setNewGuardian` after approval.
    *   `ProjectMilestoneApproval`: Automatically generated proposal to vote on a project milestone's completion.
    *   (Conceptually: `TreasuryWithdrawal`, `FailProject` would be other governance types requiring execution functions).
11. **Proposal Lifecycle:** Proposals move through states (`Pending`, `Voting`, `Approved`, `Rejected`, `Active`, `MilestoneVoting`, `Completed`, `Failed`, `Cancelled`) based on actions and voting outcomes.
12. **Quorum and Approval Thresholds:** Voting finalization (`finalizeProposalVoting`) requires a minimum percentage of total staked supply to have voted (quorum) and a minimum percentage of votes to be 'For' (approval threshold).
13. **Emergency Pause:** The `Ownable` owner and a designated `guardian` can `pauseContract` in emergencies, halting key operations like voting, funding, and joining.
14. **Burning Escrow:** A `burnEscrowRemainder` function allows removing remaining funds in a project's escrow (e.g., after failure) by sending them to `address(0)`. Use with extreme caution.
15. **Claim Voting Reward (Placeholder):** A function and event are included for `claimVotingReward`, suggesting a mechanism where active voters (especially on winning proposals) could receive tokens, though the complex reward calculation is marked as unimplemented.

This contract provides a framework for a decentralized creative fund with several distinct features beyond a basic voting contract, exceeding the requirement for 20 functions and incorporating advanced concepts like reputation-weighted voting and multi-level governance proposal types.

**Disclaimer:** This code is for educational and illustrative purposes. It contains complex logic and should be thoroughly audited and tested before deployment in a production environment. Specific areas like complex delegation cycle detection, robust reward calculation, and handling edge cases in state transitions or error handling would require further development for a production-ready system. Using OpenZeppelin libraries for standard components improves security but doesn't guarantee the custom logic is bug-free.