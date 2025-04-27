Okay, let's create a smart contract concept for a "Decentralized Dynamic DAO with Skill-Based Membership and Phased Project Funding". This incorporates dynamic elements, non-standard membership criteria (skills/reputation), and a more complex project lifecycle than simple grant DAOs.

It won't use standard token voting directly, but rather a tiered reputation system. It will have phased funding linked to progress reporting. The configuration parameters of the DAO itself will be governable.

**Disclaimer:** This is a complex conceptual example. It is provided for educational purposes to demonstrate advanced concepts. It is *not* audited, production-ready code. Deploying complex smart contracts requires rigorous security audits and testing. Gas costs for many of these operations would be significant.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedDynamicDAO
 * @dev A dynamic DAO where membership is skill/reputation-based, governance uses tiered voting,
 *      and projects are funded in phases linked to progress reports. DAO parameters are governable.
 */

/*
Outline:
1.  State Variables & Structs: Definitions for Members, Proposals, Projects, and DAO Configuration.
2.  Events: Signals for key state changes.
3.  Modifiers: Access control based on membership or project roles.
4.  Core Configuration: Initial parameters, Tier thresholds.
5.  Membership Management: Proposing, voting on, onboarding, updating, and removing members.
6.  Reputation System: Awarding and penalizing reputation (via governance).
7.  Governance (Proposals): Submitting, voting on, and finalizing different proposal types (Membership, Project, Configuration). Tier-weighted voting.
8.  Project Lifecycle: Submitting, approving, funding phases, reporting, rating projects.
9.  Treasury Management: Depositing and withdrawing funds (governance controlled).
10. Dynamic Configuration Updates: Functions to change DAO parameters via approved config proposals.
11. Query Functions: Read-only functions to get DAO state.
*/

/*
Function Summary (Excluding internal/private helpers, >= 20 callable functions):

Membership Management:
1. proposeMember(address memberAddress, string memory skillTags) - Propose a new member with associated skills.
2. voteOnMembershipProposal(uint256 proposalId, bool approve) - Cast vote on a member proposal.
3. finalizeMembershipApproval(uint256 proposalId) - Finalize member onboarding if proposal passed.
4. resignMembership() - Allows a member to voluntarily leave the DAO.
5. kickMember(address memberAddress) - Submit proposal to remove a member.
6. updateSkillTags(string memory skillTags) - Member updates their listed skills.

Reputation System (Called internally by governance finalization or specific processes):
7. awardReputation(address memberAddress, uint256 amount, string memory reasonHash) - Increase member reputation.
8. penalizeReputation(address memberAddress, uint256 amount, string memory reasonHash) - Decrease member reputation.

Governance (Proposals):
9. submitProjectProposal(string memory title, string memory descriptionHash, string memory skillTagsRequired, uint256 totalBudget, uint256 durationBlocks) - Propose a new project for funding.
10. submitConfigProposal(string memory descriptionHash, bytes memory configData) - Propose a change to DAO configuration parameters.
11. voteOnProposal(uint256 proposalId, bool approve) - Cast vote on any active proposal (Project, Config, Kick Member).
12. delegateVote(address delegatee) - Delegate voting power to another member.
13. revokeDelegate() - Revoke vote delegation.
14. finalizeProposal(uint256 proposalId) - Finalize any proposal if voting period ended and passed.

Project Lifecycle:
15. submitProjectProgressReport(uint256 projectId, string memory reportHash) - Project team submits a progress report hash.
16. approveProjectReport(uint256 projectId) - Member votes to approve a project report.
17. requestProjectFunds(uint256 projectId, uint256 amount) - Project team requests a funding tranche after report approval.
18. rateProjectPerformance(uint256 projectId, uint256 rating) - Member rates a completed project (influences team reputation).

Treasury Management:
19. depositFunds() payable - Deposit Ether into the DAO treasury.
20. requestWithdrawal(address recipient, uint256 amount) - Submit proposal to withdraw funds from the treasury.

Dynamic Configuration Updates (Called internally by finalizeConfigApproval):
21. updateTierThresholds(uint256[] memory newThresholds) - Update reputation thresholds for tiers.
22. updateVotingPeriod(uint256 newPeriodBlocks) - Update the duration of voting periods.
// ... potentially more config update functions

Query Functions (Read-only):
23. getMemberDetails(address memberAddress) view - Get details of a member.
24. getProposalDetails(uint256 proposalId) view - Get details of a proposal.
25. getProjectDetails(uint256 projectId) view - Get details of a project.
26. getTreasuryBalance() view - Get the current treasury balance.
27. getMemberTier(address memberAddress) view - Get the current tier of a member.
// ... many more getters possible for specific state variables
*/

contract DecentralizedDynamicDAO {

    // --- Errors ---
    error NotMember();
    error AlreadyMember();
    error MemberNotFound();
    error ProposalNotFound();
    error ProposalAlreadyActive();
    error ProposalVotingEnded();
    error ProposalVotingNotEnded();
    error ProposalNotApproved();
    error ProposalTypeMismatch();
    error AlreadyVoted();
    error NoActiveDelegation();
    error SelfDelegationNotAllowed();
    error InsufficientVotes(); // For quorum/passing
    error InvalidConfigData();
    error ProjectNotFound();
    error NotProjectTeam();
    error ProjectNotApproved();
    error ProjectAlreadyCompleted();
    error InvalidRating();
    error InsufficientFunds();
    error ReportNotApproved();
    error FundingPhaseMismatch();
    error CannotWithdrawZero();
    error CannotProposeSelfKick();
    error OnlyCallableByGovernance(); // For functions like awardReputation, penalizeReputation, releaseFunds, etc. when not triggered by proposal finalization

    // --- Enums ---
    enum ProposalType {
        Membership,
        Project,
        Configuration,
        KickMember,
        Withdrawal
    }

    enum ProposalState {
        Pending,
        Active,
        Approved,
        Rejected,
        Finalized // For Membership, Config, Withdrawal
    }

    enum ProjectState {
        Proposed,
        Voting,
        Approved,
        InProgress,
        ReportPendingApproval,
        FundsRequested,
        Completed,
        Rejected
    }

    // --- Structs ---
    struct Member {
        bool isMember;
        uint256 reputation;
        string skillTags; // Comma-separated or JSON string? Keep simple for gas.
        address voteDelegate; // Who this member delegates their vote to
        bool hasDelegated;
    }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        address proposer;
        uint256 submissionBlock;
        uint256 votingEndBlock;
        ProposalState state;
        string descriptionHash; // IPFS hash or similar for detailed description
        // Specific data per type:
        address targetAddress; // For Membership, KickMember, Withdrawal
        uint256 targetAmount;  // For Withdrawal
        uint256 targetId;      // For Project (if config relates to project), or KickMember proposal ID
        bytes configData;      // For Configuration proposals

        // Voting State
        mapping(address => bool) hasVoted;
        uint256 totalWeightedVotesFor;
        uint256 totalWeightedVotesAgainst;
        uint256 totalWeightedVotingSupplyAtStart; // Snapshot of total voting weight when proposal starts
    }

    struct Project {
        uint256 id;
        address proposer; // Who proposed it
        string title;
        string descriptionHash;
        string skillTagsRequired;
        uint256 totalBudget;
        uint256 fundedAmount;
        uint256 durationBlocks; // Expected duration
        ProjectState state;
        uint256 proposalId; // The governance proposal that approved this project

        // Funding & Reporting
        uint256 currentFundingPhase; // Phase 0, 1, 2...
        uint256 lastReportBlock;
        string lastReportHash;
        bool reportApproved; // Approval status for the current phase report
        mapping(address => bool) hasApprovedReport; // Members who approved current report
        uint256 totalReportApprovalsWeighted; // Weighted sum of votes for the current report

        // Performance Rating (after completion)
        uint256 totalRatingSum;
        uint256 ratingCount;
    }

    // --- State Variables ---
    mapping(address => Member) public members;
    address[] public memberAddresses; // To iterate members (gas expensive!)

    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;

    mapping(uint256 => Project) public projects;
    uint256 public nextProjectId;

    uint256[] public tierThresholds; // Reputation required for each tier (tier 0 is base)
    uint256 public votingPeriodBlocks;
    uint256 public proposalQuorumThresholdWeighted; // Percentage of total weighted votes required for a proposal to be valid (e.g., 4000 for 40%)
    uint256 public reportApprovalThresholdWeighted; // Percentage of total weighted votes required for a project report to be approved

    // Governance-controlled functions that require an approved proposal execution
    // This mapping prevents direct calls and enforces the governance path.
    // bytes4 => bool (function signature => isGovernanceControlled)
    mapping(bytes4 => bool) public governanceControlledFunctions;

    // --- Events ---
    event MemberProposed(uint256 proposalId, address indexed memberAddress, string skillTags);
    event MemberOnboarded(address indexed memberAddress, uint256 reputation, string skillTags);
    event MemberResigned(address indexed memberAddress);
    event MemberSkillTagsUpdated(address indexed memberAddress, string skillTags);
    event MemberKicked(address indexed memberAddress); // Emitted after kick proposal finalization

    event ReputationAwarded(address indexed memberAddress, uint256 amount, string reasonHash);
    event ReputationPenalized(address indexed memberAddress, uint256 amount, string reasonHash);
    event MemberTierChanged(address indexed memberAddress, uint256 newTier);

    event ProposalSubmitted(uint256 indexed proposalId, ProposalType proposalType, address indexed proposer, string descriptionHash);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 weightedVote);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event VoteDelegationRevoked(address indexed delegator);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalFinalized(uint256 indexed proposalId, ProposalState finalState); // Approved or Rejected

    event ProjectSubmitted(uint256 indexed proposalId, address indexed proposer, string title);
    event ProjectStateChanged(uint256 indexed projectId, ProjectState newState);
    event ProjectReportSubmitted(uint256 indexed projectId, address indexed reporter, string reportHash);
    event ProjectReportApproved(uint256 indexed projectId);
    event ProjectFundsRequested(uint256 indexed projectId, uint256 amount);
    event ProjectFundsReleased(uint256 indexed projectId, uint256 amount);
    event ProjectCompleted(uint256 indexed projectId);
    event ProjectRated(uint256 indexed projectId, address indexed rater, uint256 rating);

    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsRequestedForWithdrawal(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    event ConfigUpdated(string description, bytes configData); // More specific events per config type better

    // --- Constructor ---
    constructor(uint256[] memory initialTierThresholds, uint256 initialVotingPeriodBlocks, uint256 initialQuorumThreshold, uint256 initialReportApprovalThreshold) {
        tierThresholds = initialTierThresholds;
        votingPeriodBlocks = initialVotingPeriodBlocks;
        proposalQuorumThresholdWeighted = initialQuorumThreshold; // e.g., 4000 for 40.00%
        reportApprovalThresholdWeighted = initialReportApprovalThreshold; // e.g., 5000 for 50.00%

        // Initialize the deployer as the first member with some base reputation
        // In a real DAO, a genesis or bootstrapping process would be more complex.
        address deployer = msg.sender;
        members[deployer] = Member({
            isMember: true,
            reputation: 1000, // Starting rep
            skillTags: "founder",
            voteDelegate: address(0),
            hasDelegated: false
        });
        memberAddresses.push(deployer); // Add to iterable list (gas warning applies)
        emit MemberOnboarded(deployer, 1000, "founder");
        emit MemberTierChanged(deployer, getMemberTier(deployer)); // Initial tier

        nextProposalId = 1;
        nextProjectId = 1;

        // Mark functions that should ONLY be callable via governance proposal finalization
        // Using function signatures: `functionName(paramType1, paramType2)`
        governanceControlledFunctions[this.awardReputation.selector] = true;
        governanceControlledFunctions[this.penalizeReputation.selector] = true;
        governanceControlledFunctions[this.updateTierThresholds.selector] = true;
        governanceControlledFunctions[this.updateVotingPeriod.selector] = true;
        governanceControlledFunctions[this.withdrawFunds.selector] = true; // The internal helper
        governanceControlledFunctions[this.releaseProjectFunds.selector] = true; // The internal helper
        governanceControlledFunctions[this.markProjectCompleted.selector] = true; // The internal helper
    }

    // --- Modifiers ---
    modifier onlyMember() {
        if (!members[msg.sender].isMember) {
            revert NotMember();
        }
        _;
    }

     modifier onlyProjectTeam(uint256 _projectId) {
        Project storage project = projects[_projectId];
        // Simple check: Only the proposer is the 'team' for this example.
        // Real DAO would have a separate team management system.
        if (project.proposer != msg.sender) {
             revert NotProjectTeam();
        }
        _;
    }

    // --- Internal Helpers ---

    /**
     * @dev Calculates the voting weight of a member based on their tier.
     *      Tier 0 = 1x weight, Tier 1 = 2x, Tier 2 = 4x, etc. (Exponential weighting)
     */
    function _calculateVotingWeight(address memberAddress) internal view returns (uint256) {
        if (!members[memberAddress].isMember) return 0;
        uint256 tier = getMemberTier(memberAddress);
        return 2**tier; // Example: 1, 2, 4, 8... based on tier
    }

    /**
     * @dev Calculates the tier of a member based on their reputation and current thresholds.
     */
    function getMemberTier(address memberAddress) public view returns (uint256) {
        uint256 rep = members[memberAddress].reputation;
        uint256 tier = 0;
        for (uint256 i = 0; i < tierThresholds.length; i++) {
            if (rep >= tierThresholds[i]) {
                tier = i + 1; // tierThresholds[0] is for Tier 1, [1] for Tier 2, etc.
            } else {
                break;
            }
        }
        return tier;
    }

    /**
     * @dev Gets the effective voter (self or delegatee).
     */
    function _getEffectiveVoter(address voter) internal view returns (address) {
        address delegatee = members[voter].voteDelegate;
        if (members[voter].hasDelegated && delegatee != address(0)) {
            // Prevent delegation loops (simplified: only one level)
            if (members[delegatee].hasDelegated && members[delegatee].voteDelegate == voter) {
                 // Simple loop detection, more complex needed for chains > 2
                 return voter; // Revert to self if delegatee delegates back
            }
            return delegatee;
        }
        return voter;
    }

    /**
     * @dev Calculate total weighted voting power currently available.
     *      NOTE: Iterating `memberAddresses` is GAS INTENSIVE.
     *      A real DAO might use a token supply snapshot or a more gas-efficient method.
     */
    function _getTotalWeightedVotingPower() internal view returns (uint256) {
        uint256 totalPower = 0;
        // WARNING: Gas cost scales with number of members. Use with caution.
        for (uint256 i = 0; i < memberAddresses.length; i++) {
            address memberAddr = memberAddresses[i];
            // Only count members who haven't delegated *from* them
            if (members[memberAddr].isMember && !members[memberAddr].hasDelegated) {
                 totalPower += _calculateVotingWeight(memberAddr);
            }
        }
        return totalPower;
    }

     /**
      * @dev Internal helper to check if a proposal has met the quorum and passed.
      */
    function _checkProposalPassed(uint256 proposalId) internal view returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        if (block.number <= proposal.votingEndBlock) return false; // Voting not ended

        uint256 totalWeightedSupply = proposal.totalWeightedVotingSupplyAtStart;
        if (totalWeightedSupply == 0) return false; // Avoid division by zero

        // Calculate quorum met: total votes cast (for + against) vs total supply
        uint256 totalVotesCastWeighted = proposal.totalWeightedVotesFor + proposal.totalWeightedVotesAgainst;
        bool quorumMet = (totalVotesCastWeighted * 10000) / totalWeightedSupply >= proposalQuorumThresholdWeighted;

        if (!quorumMet) return false;

        // Check majority: votes for > votes against
        return proposal.totalWeightedVotesFor > proposal.totalWeightedVotesAgainst;
    }

    /**
     * @dev Internal helper to check if a project report has met the approval threshold.
     */
     function _checkReportApproved(uint256 projectId) internal view returns (bool) {
         Project storage project = projects[projectId];
         if (project.state != ProjectState.ReportPendingApproval) return false;

         // Assuming report approval doesn't have a time limit, but requires a threshold of current voting power
         // Or maybe it should have a time limit? Let's assume it needs votes based on the *current* weighted supply.
         // WARNING: This uses the GAS INTENSIVE _getTotalWeightedVotingPower()
         uint256 currentWeightedSupply = _getTotalWeightedVotingPower();
         if (currentWeightedSupply == 0) return false;

         return (project.totalReportApprovalsWeighted * 10000) / currentWeightedSupply >= reportApprovalThresholdWeighted;
     }


    // --- Membership Management ---

    /**
     * @dev Proposes a new address for membership. Requires a member to propose.
     * @param memberAddress The address being proposed.
     * @param skillTags A string describing the proposed member's skills.
     */
    function proposeMember(address memberAddress, string memory skillTags) external onlyMember {
        if (members[memberAddress].isMember) revert AlreadyMember();

        uint256 proposalId = nextProposalId++;
        Proposal storage proposal = proposals[proposalId];

        proposal.id = proposalId;
        proposal.proposalType = ProposalType.Membership;
        proposal.proposer = msg.sender;
        proposal.submissionBlock = block.number;
        proposal.votingEndBlock = block.number + votingPeriodBlocks;
        proposal.state = ProposalState.Active;
        proposal.targetAddress = memberAddress;
        // descriptionHash could link to a profile/justification
        proposal.descriptionHash = string(abi.encodePacked("Membership proposal for ", memberAddress.toString())); // Simple description
        proposal.totalWeightedVotingSupplyAtStart = _getTotalWeightedVotingPower(); // Snapshot for quorum

        emit MemberProposed(proposalId, memberAddress, skillTags);
        emit ProposalSubmitted(proposalId, ProposalType.Membership, msg.sender, proposal.descriptionHash);
        emit ProposalStateChanged(proposalId, ProposalState.Active);
    }

    /**
     * @dev Allows a member to vote on an active proposal.
     * @param proposalId The ID of the proposal.
     * @param approve True to vote for, False to vote against.
     */
    function voteOnProposal(uint256 proposalId, bool approve) external onlyMember {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.state != ProposalState.Active) revert ProposalNotFound(); // Or specific ProposalNotActive error
        if (block.number > proposal.votingEndBlock) revert ProposalVotingEnded();

        address effectiveVoter = _getEffectiveVoter(msg.sender);
        if (proposal.hasVoted[effectiveVoter]) revert AlreadyVoted();

        uint256 weightedVote = _calculateVotingWeight(effectiveVoter);
        if (weightedVote == 0) revert NotMember(); // Should be caught by onlyMember, but double check

        proposal.hasVoted[effectiveVoter] = true;
        if (approve) {
            proposal.totalWeightedVotesFor += weightedVote;
        } else {
            proposal.totalWeightedVotesAgainst += weightedVote;
        }

        emit VoteCast(proposalId, effectiveVoter, approve, weightedVote);
    }

    /**
     * @dev Delegates voting power to another member.
     * @param delegatee The address to delegate to.
     */
    function delegateVote(address delegatee) external onlyMember {
        if (msg.sender == delegatee) revert SelfDelegationNotAllowed();
        if (!members[delegatee].isMember) revert MemberNotFound(); // Can only delegate to members

        Member storage delegatorMember = members[msg.sender];
        if (delegatorMember.hasDelegated) revert AlreadyVoted(); // Simple: cannot change delegation after setting

        delegatorMember.voteDelegate = delegatee;
        delegatorMember.hasDelegated = true; // Mark as having delegated

        emit VoteDelegated(msg.sender, delegatee);
    }

    /**
     * @dev Revokes vote delegation. This also effectively clears their ability to vote manually.
     */
    function revokeDelegate() external onlyMember {
        Member storage delegatorMember = members[msg.sender];
        if (!delegatorMember.hasDelegated) revert NoActiveDelegation();

        // Revoking delegation makes the member's own weight 0 effectively,
        // as they've chosen not to vote themselves and cleared their delegate.
        // They can delegate again if the logic allowed changing delegation.
        delegatorMember.voteDelegate = address(0);
        delegatorMember.hasDelegated = false; // Allow delegating again? Or just disable voting? Let's disable voting via this path.
        // To allow re-delegation, you'd need a state variable indicating if they CAN vote (self or delegated)

        emit VoteDelegationRevoked(msg.sender);
    }


    /**
     * @dev Finalizes a proposal after the voting period ends. Can be called by any member.
     * @param proposalId The ID of the proposal to finalize.
     */
    function finalizeProposal(uint256 proposalId) external onlyMember {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.state != ProposalState.Active) revert ProposalNotFound();
        if (block.number <= proposal.votingEndBlock) revert ProposalVotingNotEnded();

        bool passed = _checkProposalPassed(proposalId);

        if (passed) {
            proposal.state = ProposalState.Approved;
            emit ProposalStateChanged(proposalId, ProposalState.Approved);
            _executeProposal(proposalId); // Attempt to execute immediately if approved
        } else {
            proposal.state = ProposalState.Rejected;
             emit ProposalStateChanged(proposalId, ProposalState.Rejected);
        }
        emit ProposalFinalized(proposalId, proposal.state);
    }

     /**
      * @dev Internal function to execute a proposal based on its type.
      * @param proposalId The ID of the proposal to execute.
      */
    function _executeProposal(uint256 proposalId) internal {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.state != ProposalState.Approved) revert ProposalNotApproved(); // Should not happen if called from finalize

        // Prevent double execution
        if (proposal.proposalType == ProposalType.Membership ||
            proposal.proposalType == ProposalType.Configuration ||
            proposal.proposalType == ProposalType.Withdrawal) {
            if (proposal.state == ProposalState.Finalized) return; // Already executed
        }

        if (proposal.proposalType == ProposalType.Membership) {
            // Onboarding a new member
            address newMemberAddress = proposal.targetAddress;
            string memory skillTags = ""; // How to get skills submitted in proposeMember? Need to store it in the proposal struct or event. Let's add skillTags to the Proposal struct.
            // Need to find the original proposal data - requires modifying Proposal struct.
            // For now, simplified: skills are updated *after* onboarding.
            // Let's assume the proposeMember event *is* the record of skills for now, not stored in proposal.
            // Or, add a mapping `proposalId -> string skillTagsForMembership`. Less gas intensive.
            // For this example, let's add `string memory skillTagsForMembership` to the Proposal struct.
            // RETHINK: The `finalizeMembershipApproval` is a public wrapper, not internal. The execution happens *there*.
            // So this _executeProposal logic might be slightly different. The public function calls _checkProposalPassed then executes.
            // Let's adjust the structure. `finalizeProposal` just sets state to Approved/Rejected.
            // Separate public functions like `finalizeMembershipApproval`, `finalizeProjectApproval`, etc. check the state and execute.
        } else if (proposal.proposalType == ProposalType.Project) {
             // Project creation is finalized by finalizeProjectApproval
        } else if (proposal.proposalType == ProposalType.Configuration) {
             // Configuration change is finalized by finalizeConfigApproval
        } else if (proposal.proposalType == ProposalType.KickMember) {
             // Kick member is finalized by finalizeKickMember
        } else if (proposal.proposalType == ProposalType.Withdrawal) {
             // Withdrawal is finalized by finalizeWithdrawal
        }
         // If execution needs to happen *immediately* upon approval within finalizeProposal:
         // This requires complex bytes decoding and calling arbitrary functions, which is very risky.
         // The safer pattern is `finalizeProposal` -> set state to Approved -> `finalizeXProposal` (public, checks state) -> execute specific logic.
         // Let's stick to the safer pattern. `_executeProposal` can be removed or used for simple state transitions only.
    }


    // --- Specific Proposal Finalization Functions (Callable by any member IF proposal is Approved and not yet Finalized) ---
    // These replace the direct execution within `finalizeProposal` for safety and clarity.

    /**
     * @dev Finalizes a successful Membership proposal, onboarding the new member.
     * @param proposalId The ID of the Membership proposal.
     */
    function finalizeMembershipApproval(uint256 proposalId) external onlyMember {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposalType != ProposalType.Membership) revert ProposalTypeMismatch();
        if (proposal.state != ProposalState.Approved) revert ProposalNotApproved();
        if (proposal.targetAddress == address(0)) revert InvalidConfigData(); // Target address must be set

        address newMemberAddress = proposal.targetAddress;
        if (members[newMemberAddress].isMember) {
            proposal.state = ProposalState.Finalized; // Already a member, mark proposal done
            emit ProposalStateChanged(proposalId, ProposalState.Finalized);
            return; // Idempotent
        }

        // Assuming initial reputation is fixed for new members, or taken from proposal data
        uint256 initialRep = 500; // Example: Starting reputation for new members
        string memory initialSkills = "unspecified"; // Or retrieve from proposal if stored

        members[newMemberAddress] = Member({
            isMember: true,
            reputation: initialRep,
            skillTags: initialSkills,
            voteDelegate: address(0),
            hasDelegated: false
        });
        memberAddresses.push(newMemberAddress); // Add to iterable list (gas warning applies)

        proposal.state = ProposalState.Finalized;
        emit MemberOnboarded(newMemberAddress, initialRep, initialSkills);
        emit MemberTierChanged(newMemberAddress, getMemberTier(newMemberAddress));
        emit ProposalStateChanged(proposalId, ProposalState.Finalized);
    }

    /**
     * @dev Submits a proposal to kick a member.
     * @param memberAddress The member address to propose kicking.
     */
    function kickMember(address memberAddress) external onlyMember {
        if (!members[memberAddress].isMember) revert MemberNotFound();
        if (msg.sender == memberAddress) revert CannotProposeSelfKick(); // Prevent proposing to kick yourself

        uint256 proposalId = nextProposalId++;
        Proposal storage proposal = proposals[proposalId];

        proposal.id = proposalId;
        proposal.proposalType = ProposalType.KickMember;
        proposal.proposer = msg.sender;
        proposal.submissionBlock = block.number;
        proposal.votingEndBlock = block.number + votingPeriodBlocks;
        proposal.state = ProposalState.Active;
        proposal.targetAddress = memberAddress;
        proposal.descriptionHash = string(abi.encodePacked("Kick member proposal for ", memberAddress.toString()));
        proposal.totalWeightedVotingSupplyAtStart = _getTotalWeightedVotingPower();

        emit ProposalSubmitted(proposalId, ProposalType.KickMember, msg.sender, proposal.descriptionHash);
        emit ProposalStateChanged(proposalId, ProposalState.Active);
    }

     /**
      * @dev Finalizes a successful KickMember proposal, removing the member.
      * @param proposalId The ID of the KickMember proposal.
      */
    function finalizeKickMember(uint256 proposalId) external onlyMember {
         Proposal storage proposal = proposals[proposalId];
         if (proposal.proposalType != ProposalType.KickMember) revert ProposalTypeMismatch();
         if (proposal.state != ProposalState.Approved) revert ProposalNotApproved();
         if (proposal.targetAddress == address(0)) revert InvalidConfigData(); // Target address must be set

         address memberToKick = proposal.targetAddress;
         if (!members[memberToKick].isMember) {
              proposal.state = ProposalState.Finalized; // Already not a member, mark proposal done
              emit ProposalStateChanged(proposalId, ProposalState.Finalized);
             return; // Idempotent
         }

         delete members[memberToKick]; // Remove from mapping (does not remove from array)

         // Removing from memberAddresses array is GAS INTENSIVE and complex.
         // A better approach is to just use the mapping `members[address].isMember` as the source of truth
         // and accept that the `memberAddresses` array might contain non-members, or implement a separate,
         // gas-efficient way to manage iterable member lists off-chain or with helper contracts/events.
         // For this example, we'll leave the kicked member in the array but rely on `members[addr].isMember`.

         proposal.state = ProposalState.Finalized;
         emit MemberKicked(memberToKick);
         emit ProposalStateChanged(proposalId, ProposalState.Finalized);
    }


    /**
     * @dev Allows a member to voluntarily resign.
     */
    function resignMembership() external onlyMember {
        address memberAddress = msg.sender;
        delete members[memberAddress]; // Remove from mapping

        // Same note as kickMember regarding memberAddresses array.

        emit MemberResigned(memberAddress);
    }

    /**
     * @dev Allows a member to update their skill tags.
     * @param skillTags The new skill tags string.
     */
    function updateSkillTags(string memory skillTags) external onlyMember {
        members[msg.sender].skillTags = skillTags;
        emit MemberSkillTagsUpdated(msg.sender, skillTags);
    }

    // --- Reputation System ---
    // These functions are intended to be called by governance decisions (e.g., part of a finalized proposal).
    // Marked public but guarded by `onlyCallableByGovernance` modifier or check in a real system.
    // For simplicity here, they are public but assume an external process ensures governance approval.
    // A more robust system would have `finalizeReputationAwardProposal(uint256 proposalId)` etc.

    /**
     * @dev Awards reputation to a member.
     *      Requires governance approval (e.g., via a passed proposal execution).
     * @param memberAddress The member to award reputation to.
     * @param amount The amount of reputation to award.
     * @param reasonHash Hash linking to the reason (e.g., IPFS hash of a document).
     */
    function awardReputation(address memberAddress, uint256 amount, string memory reasonHash) public { // Should be internal or guarded
        // In a real DAO: require(governanceControlledFunctions[msg.sig], OnlyCallableByGovernance()); or similar
        if (!members[memberAddress].isMember) revert MemberNotFound();
        uint256 oldTier = getMemberTier(memberAddress);
        members[memberAddress].reputation += amount;
        emit ReputationAwarded(memberAddress, amount, reasonHash);
        uint256 newTier = getMemberTier(memberAddress);
        if (newTier != oldTier) emit MemberTierChanged(memberAddress, newTier);
    }

     /**
     * @dev Penalizes reputation of a member.
     *      Requires governance approval.
     * @param memberAddress The member to penalize.
     * @param amount The amount of reputation to penalize.
     * @param reasonHash Hash linking to the reason.
     */
    function penalizeReputation(address memberAddress, uint256 amount, string memory reasonHash) public { // Should be internal or guarded
        // In a real DAO: require(governanceControlledFunctions[msg.sig], OnlyCallableByGovernance()); or similar
        if (!members[memberAddress].isMember) revert MemberNotFound();
        uint256 oldTier = getMemberTier(memberAddress);
        if (members[memberAddress].reputation <= amount) {
            members[memberAddress].reputation = 0;
        } else {
            members[memberAddress].reputation -= amount;
        }
        emit ReputationPenalized(memberAddress, amount, reasonHash);
         uint256 newTier = getMemberTier(memberAddress);
        if (newTier != oldTier) emit MemberTierChanged(memberAddress, newTier);
    }


    // --- Project Lifecycle ---

    /**
     * @dev Submits a proposal for a new project. Requires a member.
     * @param title Project title.
     * @param descriptionHash IPFS hash for project description.
     * @param skillTagsRequired Skills needed for the project team.
     * @param totalBudget Total requested budget in Ether (WEI).
     * @param durationBlocks Expected project duration in blocks.
     */
    function submitProjectProposal(string memory title, string memory descriptionHash, string memory skillTagsRequired, uint256 totalBudget, uint256 durationBlocks) external onlyMember {
        uint256 proposalId = nextProposalId++;
        Proposal storage proposal = proposals[proposalId];

        proposal.id = proposalId;
        proposal.proposalType = ProposalType.Project;
        proposal.proposer = msg.sender;
        proposal.submissionBlock = block.number;
        proposal.votingEndBlock = block.number + votingPeriodBlocks;
        proposal.state = ProposalState.Active;
        proposal.descriptionHash = descriptionHash; // Use descriptionHash for project proposal details
        proposal.totalWeightedVotingSupplyAtStart = _getTotalWeightedVotingPower();

        // Store project-specific data in the proposal temporarily
        // This is a simplification. A real DAO might create a draft project object earlier.
        // Let's add more fields to the Proposal struct or a separate mapping for ProjectProposalDetails.
        // For this example, we'll create the Project struct with state Proposed immediately.

        uint256 projectId = nextProjectId++;
         projects[projectId] = Project({
            id: projectId,
            proposer: msg.sender,
            title: title,
            descriptionHash: descriptionHash,
            skillTagsRequired: skillTagsRequired,
            totalBudget: totalBudget,
            fundedAmount: 0,
            durationBlocks: durationBlocks,
            state: ProjectState.Proposed, // State changes to Voting when linked to proposal
            proposalId: proposalId,
            currentFundingPhase: 0,
            lastReportBlock: 0,
            lastReportHash: "",
            reportApproved: false,
            totalReportApprovalsWeighted: 0,
            totalRatingSum: 0,
            ratingCount: 0
        });

        proposal.targetId = projectId; // Link proposal to project

        projects[projectId].state = ProjectState.Voting; // Move project state to Voting

        emit ProjectSubmitted(proposalId, msg.sender, title);
        emit ProposalSubmitted(proposalId, ProposalType.Project, msg.sender, descriptionHash);
        emit ProposalStateChanged(proposalId, ProposalState.Active);
        emit ProjectStateChanged(projectId, ProjectState.Voting);
    }

    /**
     * @dev Finalizes a successful Project proposal, moving the project to Approved state.
     * @param proposalId The ID of the Project proposal.
     */
    function finalizeProjectApproval(uint256 proposalId) external onlyMember {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposalType != ProposalType.Project) revert ProposalTypeMismatch();
        if (proposal.state != ProposalState.Approved) revert ProposalNotApproved();
        if (proposal.targetId == 0) revert InvalidConfigData(); // Project ID must be set

        uint256 projectId = proposal.targetId;
        Project storage project = projects[projectId];
        if (project.state != ProjectState.Voting) {
            // Project already moved past voting or doesn't exist correctly
            proposal.state = ProposalState.Finalized; // Mark proposal done
             emit ProposalStateChanged(proposalId, ProposalState.Finalized);
            return; // Idempotent or error depending on desired strictness
        }

        project.state = ProjectState.Approved;
        proposal.state = ProposalState.Finalized;

        emit ProjectStateChanged(projectId, ProjectState.Approved);
        emit ProposalStateChanged(proposalId, ProposalState.Finalized);
    }

    /**
     * @dev Submits a progress report for a project. Only callable by the project proposer/team.
     *      Requires project to be in Approved or InProgress state. Moves state to ReportPendingApproval.
     * @param projectId The ID of the project.
     * @param reportHash IPFS hash for the report document.
     */
    function submitProjectProgressReport(uint256 projectId, string memory reportHash) external onlyProjectTeam(projectId) {
        Project storage project = projects[projectId];
        if (project.state != ProjectState.Approved && project.state != ProjectState.InProgress) {
            revert ProjectNotApproved(); // Not in a state where reports are relevant
        }

        project.state = ProjectState.ReportPendingApproval;
        project.lastReportBlock = block.number;
        project.lastReportHash = reportHash;
        project.reportApproved = false; // Reset approval status for the new report
        project.totalReportApprovalsWeighted = 0;

        // Clear previous report approvals (gas intensive if many members approved)
        // Better: Use a different mapping structure for per-report approvals
        // For this example, simple reset and re-collection of weighted votes.
        // This mapping `hasApprovedReport` is tied to the *current* report phase.

        emit ProjectReportSubmitted(projectId, msg.sender, reportHash);
        emit ProjectStateChanged(projectId, ProjectState.ReportPendingApproval);
    }

    /**
     * @dev Allows a member to approve a submitted project report.
     *      Only valid when the project is in ReportPendingApproval state.
     * @param projectId The ID of the project.
     */
    function approveProjectReport(uint256 projectId) external onlyMember {
        Project storage project = projects[projectId];
        if (project.state != ProjectState.ReportPendingApproval) revert ReportNotApproved(); // Not in the correct state

        address effectiveVoter = _getEffectiveVoter(msg.sender);

        if (project.hasApprovedReport[effectiveVoter]) revert AlreadyVoted();

        uint256 weightedVote = _calculateVotingWeight(effectiveVoter);
        if (weightedVote == 0) revert NotMember(); // Should be caught by onlyMember

        project.hasApprovedReport[effectiveVoter] = true;
        project.totalReportApprovalsWeighted += weightedVote;

        // Optional: Immediately check if threshold is met after vote
        if (_checkReportApproved(projectId)) {
             project.reportApproved = true;
             // Decide next state: InProgress if more funds/work, Completed if last report
             // This simple example doesn't track last phase explicitly.
             // A real DAO needs proposal/config for funding phases and final report marking.
             // Let's assume report approval just allows *requesting* funds, doesn't change state automatically.
             // The state change to InProgress or Completed happens upon fund release or explicit marking.
             emit ProjectReportApproved(projectId);
        }
    }


     /**
      * @dev Allows the project team to request a funding tranche.
      *      Requires the current report to be approved.
      * @param projectId The ID of the project.
      * @param amount The amount of Ether (WEI) requested for this tranche.
      */
     function requestProjectFunds(uint256 projectId, uint256 amount) external onlyProjectTeam(projectId) {
         Project storage project = projects[projectId];
         if (project.state != ProjectState.ReportPendingApproval && project.state != ProjectState.InProgress) {
             revert FundingPhaseMismatch();
         }
         if (!project.reportApproved) revert ReportNotApproved();

         // Check if requesting more than total budget (can refine with phase budgets)
         if (project.fundedAmount + amount > project.totalBudget) revert InvalidConfigData(); // Or specific error

         // State changes to FundsRequested, pending release.
         project.state = ProjectState.FundsRequested;
         project.currentFundingPhase++; // Increment phase counter

         emit ProjectFundsRequested(projectId, amount);
         emit ProjectStateChanged(projectId, ProjectState.FundsRequested);

         // Reset report approval state for the *next* report
         project.reportApproved = false;
         // WARNING: Resetting mapping values (hasApprovedReport) is GAS INTENSIVE.
         // Better: use a nested mapping or clear storage slot explicitly if needed.
         // For this example, we assume clearing is handled or state is managed differently.
         // A simpler approach: check approval *at the time of request*, not persist state.
         // Let's stick with the current model but note the gas cost of resetting `hasApprovedReport`.
         // A better approach might be `mapping(uint256 => mapping(address => bool)) reportApprovalVotes;` for per-phase tracking.
     }

     /**
      * @dev Releases requested funds to the project team.
      *      Requires governance approval (e.g., via a specific 'Release Funds' proposal, or automatically after report approval).
      *      For simplicity here, let's make it callable by an internal process assuming approval.
      * @param projectId The ID of the project.
      * @param amount The amount to release.
      */
     function releaseProjectFunds(uint256 projectId, uint256 amount) public { // Should be internal or guarded by governance
         // In a real DAO: require(governanceControlledFunctions[msg.sig], OnlyCallableByGovernance()); or similar
         Project storage project = projects[projectId];
         if (project.state != ProjectState.FundsRequested) revert FundingPhaseMismatch();
         if (amount > address(this).balance) revert InsufficientFunds(); // Check contract balance
         if (project.fundedAmount + amount > project.totalBudget) revert InvalidConfigData(); // Cannot exceed total budget

         project.fundedAmount += amount;

         // Send funds
         (bool success, ) = payable(project.proposer).call{value: amount}("");
         if (!success) {
            // Handle failure - potentially revert state or trigger a different process
            // Reverting state is safer for this example
            project.fundedAmount -= amount; // Revert funded amount state
            revert InsufficientFunds(); // Or specific transfer failed error
         }

         // Move state back to InProgress, ready for next report/phase, unless completed
         // How to know if it's the last phase? The DAO config needs to define phases or max phases.
         // Simple check: if fundedAmount == totalBudget, move to Completed state.
         if (project.fundedAmount == project.totalBudget) {
             project.state = ProjectState.Completed;
             emit ProjectCompleted(projectId);
         } else {
             project.state = ProjectState.InProgress;
         }

         emit ProjectFundsReleased(projectId, amount);
         emit ProjectStateChanged(projectId, project.state);
     }


     /**
      * @dev Allows members to rate a completed project.
      *      Contributes to the project team's reputation.
      * @param projectId The ID of the project.
      * @param rating The rating (e.g., 1-5).
      */
     function rateProjectPerformance(uint256 projectId, uint256 rating) external onlyMember {
         Project storage project = projects[projectId];
         if (project.state != ProjectState.Completed) revert ProjectNotApproved(); // Can only rate completed projects
         if (rating == 0 || rating > 5) revert InvalidRating(); // Example rating scale 1-5

         // Prevent rating your own project? Add check `require(project.proposer != msg.sender, ...);`

         // Simple average rating calculation
         project.totalRatingSum += rating;
         project.ratingCount++;

         // Optionally update team reputation immediately based on rating?
         // Better: A separate governance process periodically reviews ratings and adjusts reputation.
         // For simplicity here, we'll emit an event and note this is a trigger for off-chain/governance action.

         emit ProjectRated(projectId, msg.sender, rating);

         // Example: Trigger reputation update (conceptually)
         // uint256 averageRating = project.totalRatingSum / project.ratingCount;
         // if (averageRating > 3) { // If rating > 3, award reputation
         //     uint256 repAmount = (averageRating - 3) * 50; // Award more rep for higher rating
         //     // awardReputation(project.proposer, repAmount, "Project performance rating");
         // } else if (averageRating < 3 && project.ratingCount > 5) { // If rating < 3 after enough votes
         //     uint256 repAmount = (3 - averageRating) * 50; // Penalize rep for lower rating
         //     // penalizeReputation(project.proposer, repAmount, "Project performance rating");
         // }
         // ^ These award/penalize calls need to be properly integrated with governance control.
     }

    /**
     * @dev Explicitly mark a project as completed. May require governance or be automatic.
     *      Useful if totalBudget == fundedAmount doesn't signal completion, or for non-funded projects.
     *      Requires governance approval.
     * @param projectId The ID of the project.
     */
    function markProjectCompleted(uint256 projectId) public { // Should be internal or guarded by governance
         // In a real DAO: require(governanceControlledFunctions[msg.sig], OnlyCallableByGovernance()); or similar
         Project storage project = projects[projectId];
         if (project.state == ProjectState.Completed) return; // Idempotent
         if (project.state == ProjectState.Proposed || project.state == ProjectState.Voting || project.state == ProjectState.Rejected) revert ProjectNotApproved(); // Cannot mark unapproved/rejected as completed

         project.state = ProjectState.Completed;
         emit ProjectCompleted(projectId);
         emit ProjectStateChanged(projectId, ProjectState.Completed);
    }


    // --- Treasury Management ---

    /**
     * @dev Allows anyone to deposit Ether into the DAO treasury.
     */
    function depositFunds() external payable {
        if (msg.value == 0) revert CannotWithdrawZero(); // Should be CannotDepositZero(); using existing error for demo
        emit FundsDeposited(msg.sender, msg.value);
    }

     /**
      * @dev Submits a proposal to withdraw funds from the treasury.
      *      Requires a member.
      * @param recipient Address to send funds to.
      * @param amount Amount of Ether (WEI) to withdraw.
      */
     function requestWithdrawal(address recipient, uint256 amount) external onlyMember {
        if (amount == 0) revert CannotWithdrawZero();
        if (amount > address(this).balance) revert InsufficientFunds();

        uint256 proposalId = nextProposalId++;
        Proposal storage proposal = proposals[proposalId];

        proposal.id = proposalId;
        proposal.proposalType = ProposalType.Withdrawal;
        proposal.proposer = msg.sender;
        proposal.submissionBlock = block.number;
        proposal.votingEndBlock = block.number + votingPeriodBlocks;
        proposal.state = ProposalState.Active;
        proposal.targetAddress = recipient;
        proposal.targetAmount = amount;
        proposal.descriptionHash = string(abi.encodePacked("Withdrawal request for ", amount.toString(), " WEI to ", recipient.toString()));
        proposal.totalWeightedVotingSupplyAtStart = _getTotalWeightedVotingPower();

        emit FundsRequestedForWithdrawal(proposalId, recipient, amount);
        emit ProposalSubmitted(proposalId, ProposalType.Withdrawal, msg.sender, proposal.descriptionHash);
        emit ProposalStateChanged(proposalId, ProposalState.Active);
     }

    /**
     * @dev Executes a successful Withdrawal proposal, sending funds.
     *      Requires governance approval.
     * @param proposalId The ID of the Withdrawal proposal.
     */
    function finalizeWithdrawal(uint256 proposalId) external onlyMember { // Or restrict even more?
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposalType != ProposalType.Withdrawal) revert ProposalTypeMismatch();
        if (proposal.state != ProposalState.Approved) revert ProposalNotApproved();
        if (proposal.targetAddress == address(0) || proposal.targetAmount == 0) revert InvalidConfigData();

        // Prevent double execution
        if (proposal.state == ProposalState.Finalized) return;

        address recipient = proposal.targetAddress;
        uint256 amount = proposal.targetAmount;

        // Re-check balance just in case
        if (amount > address(this).balance) revert InsufficientFunds();

        // Use the internal controlled function to perform the actual transfer
        // This requires a mechanism to call internal/private functions from public ones,
        // or making `withdrawFunds` public and gating it via the governance flag.
        // Let's make `withdrawFunds` public and check the flag.

        // This needs a helper function structure like:
        // `executeGovernanceCall(address target, bytes memory callData)`
        // that *only* the governance system can call, which then calls target.call(callData).
        // Here, we'll simplify and call the public `withdrawFunds` function,
        // assuming `finalizeWithdrawal` is part of the trusted governance execution flow.

         _executeControlledWithdrawal(recipient, amount); // Call the guarded withdrawal helper

         proposal.state = ProposalState.Finalized;
         emit ProposalStateChanged(proposalId, ProposalState.Finalized);
    }

    /**
     * @dev Internal helper to perform a withdrawal, guarded by governance logic.
     * @param recipient Address to send funds to.
     * @param amount Amount of Ether (WEI) to withdraw.
     */
    function _executeControlledWithdrawal(address recipient, uint256 amount) internal { // Internal, not public
         // This internal function is called by trusted governance finalization.
         // No need for governanceControlledFunctions check here if only called internally.
         // If it were public, it *would* need that check.

         (bool success, ) = payable(recipient).call{value: amount}("");
         if (!success) {
             // Handle failure - potentially revert state or trigger a different process
             revert InsufficientFunds(); // Or specific transfer failed error
         }
         emit FundsWithdrawn(recipient, amount);
    }


    // --- Dynamic Configuration Updates ---

    /**
     * @dev Submits a proposal to change a DAO configuration parameter.
     *      Requires a member.
     * @param descriptionHash IPFS hash for the proposal details.
     * @param configData Data payload specifying the configuration change (structure depends on change type).
     *                   Example: abi.encode(functionSignature, param1, param2, ...) targeting a specific update function.
     *                   This is VERY complex and risky to implement generic execution.
     *                   Simpler approach: Each config type has its own proposal type or specific data structure.
     *                   Let's simplify: configData holds data for *known* update functions, and `finalizeConfigApproval` dispatches.
     */
    function submitConfigProposal(string memory descriptionHash, bytes memory configData) external onlyMember {
         // configData structure needs to be defined - e.g., first 4 bytes are function selector, rest are encoded params.
         // This still requires careful handling in finalizeConfigApproval.

        uint256 proposalId = nextProposalId++;
        Proposal storage proposal = proposals[proposalId];

        proposal.id = proposalId;
        proposal.proposalType = ProposalType.Configuration;
        proposal.proposer = msg.sender;
        proposal.submissionBlock = block.number;
        proposal.votingEndBlock = block.number + votingPeriodBlocks;
        proposal.state = ProposalState.Active;
        proposal.descriptionHash = descriptionHash;
        proposal.configData = configData; // Store the proposed config data
        proposal.totalWeightedVotingSupplyAtStart = _getTotalWeightedVotingPower();

        emit ProposalSubmitted(proposalId, ProposalType.Configuration, msg.sender, descriptionHash);
        emit ProposalStateChanged(proposalId, ProposalState.Active);
    }

     /**
      * @dev Finalizes a successful Configuration proposal, applying the changes.
      *      Requires governance approval. Uses the stored configData.
      *      This function is critical and requires careful implementation to avoid vulnerabilities.
      *      A robust version would use a timelock and separate executor contract.
      *      Simplified here for demonstration.
      * @param proposalId The ID of the Configuration proposal.
      */
    function finalizeConfigApproval(uint256 proposalId) external onlyMember { // Or restrict even more?
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposalType != ProposalType.Configuration) revert ProposalTypeMismatch();
        if (proposal.state != ProposalState.Approved) revert ProposalNotApproved();
        if (proposal.configData.length < 4) revert InvalidConfigData(); // Need at least function selector

        // Prevent double execution
        if (proposal.state == ProposalState.Finalized) return;

        bytes memory data = proposal.configData;
        bytes4 selector;
        assembly {
            selector := mload(add(data, 32)) // Read the first 4 bytes
        }

        // Check if the target function is actually one we *allow* to be called via config proposal
        // This prevents calling arbitrary functions in the contract.
        // We pre-marked trusted governance-controlled functions in the constructor/setup.
        if (!governanceControlledFunctions[selector]) {
             revert InvalidConfigData(); // Attempting to call an unauthorized function via config proposal
        }

        // Attempt to call the function specified in configData using low-level call
        // This is risky! Error handling is crucial.
        (bool success, ) = address(this).call(data);

        if (!success) {
             // Handle failure: configuration change failed. Revert or log? Reverting is safer.
             // The specific function called should ideally revert with a descriptive error.
             revert InvalidConfigData(); // Generic error indicating config execution failed
        }

        proposal.state = ProposalState.Finalized;
        emit ConfigUpdated("Configuration proposal executed", data); // Emit generic config update event
        emit ProposalStateChanged(proposalId, ProposalState.Finalized);

        // Emit specific event based on selector? Requires decoding selector -> function name mapping.
        // Example: if selector == this.updateTierThresholds.selector, emit UpdateTierThresholdsEvent(...)
    }


    /**
     * @dev Updates the reputation thresholds for different tiers.
     *      Requires governance approval (callable only via finalizeConfigApproval).
     * @param newThresholds Array of reputation thresholds.
     */
    function updateTierThresholds(uint256[] memory newThresholds) public { // Should be internal or guarded
         require(governanceControlledFunctions[msg.sig], OnlyCallableByGovernance());
         // Add validation: Check if thresholds are increasing order etc.
         tierThresholds = newThresholds;
         // Note: This changes tiers dynamically. Members' tiers will change implicitly.
         // No explicit event per member needed, the getMemberTier function reflects the change.
         // Could emit a general TierThresholdsUpdated event.
    }

    /**
     * @dev Updates the voting period duration in blocks.
     *      Requires governance approval (callable only via finalizeConfigApproval).
     * @param newPeriodBlocks The new voting period duration in blocks.
     */
    function updateVotingPeriod(uint256 newPeriodBlocks) public { // Should be internal or guarded
         require(governanceControlledFunctions[msg.sig], OnlyCallableByGovernance());
         // Add validation: minimum period?
         votingPeriodBlocks = newPeriodBlocks;
         // Could emit a VotingPeriodUpdated event.
    }

    // Add more update functions here for other parameters (quorum, report approval threshold, etc.)
    // Each would be public or internal and guarded by `governanceControlledFunctions`.


    // --- Query Functions (Read-only) ---

    /**
     * @dev Gets details for a specific member.
     * @param memberAddress The address of the member.
     * @return Member struct data.
     */
    function getMemberDetails(address memberAddress) external view returns (Member memory) {
        return members[memberAddress];
    }

    /**
     * @dev Gets details for a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return Proposal struct data (excluding mappings).
     */
    function getProposalDetails(uint256 proposalId) external view returns (
        uint256 id,
        ProposalType proposalType,
        address proposer,
        uint256 submissionBlock,
        uint256 votingEndBlock,
        ProposalState state,
        string memory descriptionHash,
        address targetAddress,
        uint256 targetAmount,
        uint256 targetId,
        uint256 totalWeightedVotesFor,
        uint256 totalWeightedVotesAgainst,
        uint256 totalWeightedVotingSupplyAtStart
    ) {
        Proposal storage proposal = proposals[proposalId];
         return (
            proposal.id,
            proposal.proposalType,
            proposal.proposer,
            proposal.submissionBlock,
            proposal.votingEndBlock,
            proposal.state,
            proposal.descriptionHash,
            proposal.targetAddress,
            proposal.targetAmount,
            proposal.targetId,
            proposal.totalWeightedVotesFor,
            proposal.totalWeightedVotesAgainst,
            proposal.totalWeightedVotingSupplyAtStart
         );
    }

     /**
      * @dev Gets details for a specific project.
      * @param projectId The ID of the project.
      * @return Project struct data (excluding mappings).
      */
     function getProjectDetails(uint256 projectId) external view returns (
         uint256 id,
         address proposer,
         string memory title,
         string memory descriptionHash,
         string memory skillTagsRequired,
         uint256 totalBudget,
         uint256 fundedAmount,
         uint256 durationBlocks,
         ProjectState state,
         uint256 proposalId,
         uint256 currentFundingPhase,
         uint256 lastReportBlock,
         string memory lastReportHash,
         bool reportApproved,
         uint256 totalReportApprovalsWeighted,
         uint256 totalRatingSum,
         uint256 ratingCount
     ) {
         Project storage project = projects[projectId];
         return (
             project.id,
             project.proposer,
             project.title,
             project.descriptionHash,
             project.skillTagsRequired,
             project.totalBudget,
             project.fundedAmount,
             project.durationBlocks,
             project.state,
             project.proposalId,
             project.currentFundingPhase,
             project.lastReportBlock,
             project.lastReportHash,
             project.reportApproved,
             project.totalReportApprovalsWeighted,
             project.totalRatingSum,
             project.ratingCount
         );
     }


    /**
     * @dev Gets the current Ether balance of the DAO treasury.
     * @return The treasury balance in WEI.
     */
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Gets the skill tags associated with a member.
     * @param memberAddress The address of the member.
     * @return The skill tags string.
     */
    function getMemberSkillTags(address memberAddress) external view returns (string memory) {
        return members[memberAddress].skillTags;
    }

    /**
     * @dev Gets the current block number when voting ends for a proposal.
     * @param proposalId The ID of the proposal.
     * @return The ending block number.
     */
    function getProposalVotingEndBlock(uint256 proposalId) external view returns (uint256) {
         return proposals[proposalId].votingEndBlock;
    }

    /**
     * @dev Gets the current voting period duration in blocks.
     * @return The voting period in blocks.
     */
    function getCurrentVotingPeriod() external view returns (uint256) {
         return votingPeriodBlocks;
    }

     /**
      * @dev Gets the total weighted votes for and against a proposal.
      * @param proposalId The ID of the proposal.
      * @return Tuple of (votesFor, votesAgainst).
      */
    function getProposalVoteCount(uint256 proposalId) external view returns (uint256 votesFor, uint256 votesAgainst) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.totalWeightedVotesFor, proposal.totalWeightedVotesAgainst);
    }

     /**
      * @dev Gets the current state of a proposal.
      * @param proposalId The ID of the proposal.
      * @return The proposal state enum.
      */
    function getProposalState(uint256 proposalId) external view returns (ProposalState) {
        return proposals[proposalId].state;
    }

     /**
      * @dev Gets the current state of a project.
      * @param projectId The ID of the project.
      * @return The project state enum.
      */
    function getProjectState(uint256 projectId) external view returns (ProjectState) {
        return projects[projectId].state;
    }

     /**
      * @dev Checks if a member has voted on a specific proposal.
      * @param proposalId The ID of the proposal.
      * @param memberAddress The address of the member.
      * @return True if the member (or their delegatee) has voted, false otherwise.
      */
    function hasVotedOnProposal(uint256 proposalId, address memberAddress) external view returns (bool) {
         address effectiveVoter = _getEffectiveVoter(memberAddress);
         return proposals[proposalId].hasVoted[effectiveVoter];
    }

     /**
      * @dev Gets the delegatee of a member.
      * @param memberAddress The address of the member.
      * @return The address of the delegatee, or address(0) if no delegation.
      */
    function getVoteDelegate(address memberAddress) external view returns (address) {
        if (!members[memberAddress].hasDelegated) return address(0);
        return members[memberAddress].voteDelegate;
    }

     /**
      * @dev Gets the current reputation tier thresholds.
      * @return An array of reputation thresholds.
      */
     function getTierThresholds() external view returns (uint256[] memory) {
         return tierThresholds;
     }

     /**
      * @dev Gets the IPFS hash for a specific project report.
      * @param projectId The ID of the project.
      * @return The report hash string.
      */
     function getProjectReportHash(uint256 projectId) external view returns (string memory) {
         return projects[projectId].lastReportHash;
     }

      /**
       * @dev Gets the total amount of funds allocated to a project.
       * @param projectId The ID of the project.
       * @return The total allocated budget in WEI.
       */
     function getProjectTotalBudget(uint256 projectId) external view returns (uint256) {
         return projects[projectId].totalBudget;
     }

     /**
      * @dev Gets the amount of funds already released to a project.
      * @param projectId The ID of the project.
      * @return The funded amount in WEI.
      */
     function getProjectFundedAmount(uint256 projectId) external view returns (uint256) {
         return projects[projectId].fundedAmount;
     }

     /**
      * @dev Gets the current rating and count for a completed project.
      * @param projectId The ID of the project.
      * @return Tuple of (totalRatingSum, ratingCount).
      */
     function getProjectRating(uint256 projectId) external view returns (uint256 totalRatingSum, uint256 ratingCount) {
         Project storage project = projects[projectId];
         return (project.totalRatingSum, project.ratingCount);
     }
}
```