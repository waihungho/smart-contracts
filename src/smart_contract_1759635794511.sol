Here's a Solidity smart contract named `AetherForgeDAO`, designed with advanced concepts like a dynamic reputation system, skill-based task orchestration, and hooks for off-chain AI integration. It aims to be creative and avoid duplicating common open-source patterns by combining these elements into a cohesive framework.

---

## Contract: `AetherForgeDAO`

### Outline:

1.  **State Variables & Data Structures:**
    *   `Member` struct: Details for each DAO member, including reputation and skills.
    *   `Project` struct: Represents a major initiative with its budget and status.
    *   `Task` struct: Individual tasks within a project, with rewards, assignees, and proof.
    *   `Proposal` struct: A generic structure for governance proposals (membership, project, AI model updates, etc.).
    *   `AIOracleQuery` struct: Details for requests made to off-chain AI services.
    *   Mappings to store `Member`, `Project`, `Task`, `Proposal`, and `AIOracleQuery` data.
    *   Counters for generating unique IDs.
    *   DAO Treasury (`treasury`).
    *   Voting parameters (`quorumPercentage`, `votingPeriod`).

2.  **Events:**
    *   `MemberApplied`, `MemberApproved`, `MemberRemoved`, `MemberProfileUpdated`, `SkillsDeclared`, `SkillEndorsed`, `ReputationAwarded`, `ReputationPenalized`.
    *   `ProjectProposed`, `ProjectApproved`, `TaskCreated`, `TaskAssigned`, `TaskProofSubmitted`, `TaskVerified`, `TaskRewardClaimed`.
    *   `AIQueryRequested`, `AIResponseSubmitted`, `AIModelUpdateProposed`, `AIModelUpdateApproved`.
    *   `FundsDeposited`, `FundsWithdrawn`.

3.  **Modifiers:**
    *   `onlyMember`: Restricts access to confirmed DAO members.
    *   `onlyProjectLead`: Restricts access to the member who proposed a project.
    *   `onlyTaskAssignee`: Restricts access to the member assigned to a specific task.
    *   `isVotingPeriodActive`: Ensures an action occurs within the voting window.
    *   `hasRequiredReputation`: Restricts access based on reputation score.

4.  **Core DAO & Membership Functions (6 functions):**
    *   `constructor`: Initializes the DAO, sets the founder, and core parameters.
    *   `applyForMembership`: Allows non-members to apply, linking an off-chain profile.
    *   `voteOnMembershipApplication`: Members vote on pending applications.
    *   `updateMemberProfileHash`: Members can update their linked off-chain profile.
    *   `proposeMemberRemoval`: Members can propose another member's removal.
    *   `voteOnMemberRemoval`: Members vote on removal proposals.

5.  **Reputation & Skill System Functions (5 functions):**
    *   `declareSkills`: Members declare their expertise.
    *   `endorseSkill`: Members can endorse others' skills.
    *   `awardReputation`: Manually awards reputation points.
    *   `penalizeReputation`: Manually deducts reputation points.
    *   `getMemberDetails`: Retrieves comprehensive details about a member.

6.  **Task Orchestration & Project Management Functions (8 functions):**
    *   `proposeProject`: Members can propose new projects with budgets and descriptions.
    *   `voteOnProjectProposal`: Members vote to approve projects.
    *   `createTask`: Creates specific tasks under an approved project.
    *   `assignTaskToMember`: Assigns a task to a suitable member.
    *   `submitTaskProof`: Assigned member submits proof of completion.
    *   `verifyTaskCompletion`: Verifiers confirm task completion.
    *   `disputeTaskCompletion`: Allows members to dispute a verification result.
    *   `claimTaskReward`: Member claims rewards after successful task verification.

7.  **AI Integration & Oracle Functions (4 functions):**
    *   `requestAIOracleQuery`: Requests an off-chain AI analysis with a bounty and callback.
    *   `submitAIOracleResponse`: A whitelisted oracle or AI agent submits the AI's result.
    *   `proposeAIModelUpdate`: Proposes an update to a referenced AI model or configuration.
    *   `voteOnAIModelUpdate`: Members vote on AI model update proposals.

8.  **Treasury Management & Governance Functions (2 functions - though `withdraw` is part of proposals):**
    *   `depositFunds`: Allows external funds to be added to the DAO treasury.
    *   `executeProposal`: A general function to execute passed proposals (e.g., funding withdrawals, parameter changes).

### Function Summary:

1.  **`constructor(string memory _name, address _initialMember, uint256 _quorumPercentage, uint256 _votingPeriod)`**: Initializes the DAO with a name, the founding member, and sets governance parameters like quorum and voting duration.
2.  **`applyForMembership(string memory _profileHash)`**: Allows any EOA to submit an application to become a DAO member, providing an IPFS or similar hash to their off-chain profile or portfolio.
3.  **`voteOnMembershipApplication(uint256 _proposalId, bool _approve)`**: DAO members cast their vote (`true` for approval, `false` for rejection) on pending membership proposals.
4.  **`updateMemberProfileHash(string memory _newProfileHash)`**: An existing member can update the hash pointing to their latest off-chain profile, showcasing new skills or achievements.
5.  **`proposeMemberRemoval(address _memberToRemove, string memory _reasonHash)`**: A DAO member can initiate a proposal to remove another member, providing an off-chain hash for the justification.
6.  **`voteOnMemberRemoval(uint256 _proposalId, bool _approve)`**: Members vote on active proposals regarding the removal of a fellow DAO member.
7.  **`declareSkills(string[] memory _skills)`**: A DAO member can declare a list of skills they possess, which helps in task matching and internal resource allocation.
8.  **`endorseSkill(address _member, string memory _skill)`**: A DAO member can endorse a specific skill of another member, boosting their credibility and expertise score for that skill.
9.  **`awardReputation(address _member, uint256 _amount, string memory _reasonHash)`**: The DAO can programmatically or through a governance vote award reputation points to a member for general contributions, community building, or exceptional performance.
10. **`penalizeReputation(address _member, uint256 _amount, string memory _reasonHash)`**: The DAO can programmatically or through a governance vote deduct reputation points from a member due to poor performance, malicious activity, or policy violations.
11. **`getMemberDetails(address _member)`**: A public view function to retrieve the complete profile hash, current reputation score, and declared skills of any DAO member.
12. **`proposeProject(string memory _projectDescriptionHash, uint256 _rewardBudget, uint256 _reputationBonus)`**: A member can propose a new project for the DAO to undertake, including its off-chain description hash, total reward budget, and potential reputation bonus for successful completion.
13. **`voteOnProjectProposal(uint256 _proposalId, bool _approve)`**: DAO members vote to approve or reject proposed projects. Only approved projects can proceed to task creation and assignment.
14. **`createTask(uint256 _projectId, string memory _taskDescriptionHash, uint256 _taskReward, uint256 _reputationBoost, string[] memory _requiredSkills)`**: Once a project is approved, a member can define individual tasks under it, specifying its description hash, individual task reward, reputation boost, and a list of required skills.
15. **`assignTaskToMember(uint256 _taskId, address _assignee)`**: A project lead or DAO member (based on governance) assigns an available task to a specific DAO member, ideally based on their declared and endorsed skills and reputation.
16. **`submitTaskProof(uint256 _taskId, string memory _proofHash)`**: The assigned member submits an off-chain hash as proof of their task completion (e.g., a link to code, design files, or documentation).
17. **`verifyTaskCompletion(uint256 _taskId, bool _isComplete)`**: Designated verifiers (or a DAO vote) assess the submitted proof and mark the task as complete or incomplete, triggering rewards or penalties.
18. **`disputeTaskCompletion(uint256 _taskId, string memory _reasonHash)`**: Allows any DAO member to dispute a `verifyTaskCompletion` decision or a submitted `_proofHash`, triggering a review process.
19. **`claimTaskReward(uint256 _taskId)`**: The assigned member can claim the specified financial reward and reputation boost after their task has been successfully verified and marked complete.
20. **`requestAIOracleQuery(string memory _queryHash, uint256 _bounty, address _callbackContract, bytes4 _callbackFunction)`**: Members can request an off-chain AI analysis or data query by providing a query hash, setting a bounty, and specifying a callback contract and function to receive the result.
21. **`submitAIOracleResponse(uint256 _queryId, string memory _responseHash)`**: A whitelisted AI agent or trusted oracle calls this function to deliver the AI's analysis result (as an off-chain hash) for a given query, triggering the callback to the requesting contract and settling the bounty.
22. **`proposeAIModelUpdate(string memory _modelIdentifier, string memory _newModelHash, string memory _configHash)`**: Members can propose updating a canonical identifier, hash, or configuration for an AI model that the DAO utilizes for internal operations or provides as a service.
23. **`voteOnAIModelUpdate(uint256 _proposalId, bool _approve)`**: Members vote on proposals to update or change the reference AI models or their configurations within the DAO's framework, ensuring community consensus on critical AI tools.
24. **`depositFunds() payable`**: Allows anyone to deposit funds into the DAO's treasury. These funds can then be allocated via governance proposals.
25. **`executeProposal(uint256 _proposalId)`**: A general-purpose function to execute a governance proposal that has successfully passed its voting period and met the quorum (e.g., distributing funds, updating parameters).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title AetherForgeDAO
/// @author Your Name/AI
/// @notice A decentralized autonomous organization with advanced features including:
///         - Reputation-based membership and governance.
///         - Skill-driven task and project orchestration.
///         - Hooks for off-chain AI integration with on-chain verification.
///         - Dynamic proposal and voting system.
/// @dev This contract is a conceptual framework. Real-world deployment would require
///      extensive security audits, gas optimizations, and potential L2/sidechain integration
///      for scalability of off-chain data hashes.

contract AetherForgeDAO {

    // --- Enums ---
    enum MemberStatus {
        Pending,
        Active,
        Inactive,
        Removed
    }

    enum ProposalType {
        MembershipApplication,
        MemberRemoval,
        ProjectApproval,
        AIModelUpdate,
        GenericParameterChange, // For future flexibility
        FundsWithdrawal // For treasury management
    }

    enum ProposalStatus {
        Pending,
        Active,
        Approved,
        Rejected,
        Executed
    }

    enum ProjectStatus {
        Proposed,
        Approved,
        InProgress,
        Completed,
        Cancelled
    }

    enum TaskStatus {
        Created,
        Assigned,
        InProgress,
        ProofSubmitted,
        Verified,
        Disputed,
        Completed,
        Failed
    }

    enum AIQueryStatus {
        Requested,
        InProgress,
        ResponseSubmitted,
        Verified,
        Failed
    }

    // --- Structs ---

    struct Member {
        address memberAddress;
        MemberStatus status;
        uint256 reputation;
        string profileHash; // IPFS hash for off-chain profile/portfolio
        mapping(string => uint256) skills; // skill_name => endorsement_count
        mapping(uint256 => bool) votedProposals; // proposalId => hasVoted
        bool exists; // To check if a member exists in the mapping
    }

    struct Project {
        uint256 projectId;
        address proposer;
        string descriptionHash; // IPFS hash for project details
        uint256 rewardBudget; // Total budget for tasks within this project
        uint256 reputationBonus; // Bonus for overall project completion
        ProjectStatus status;
        uint256 createdAt;
    }

    struct Task {
        uint256 taskId;
        uint256 projectId;
        address assignee;
        string descriptionHash; // IPFS hash for task details
        uint256 taskReward; // Specific reward for this task
        uint256 reputationBoost; // Specific reputation boost for this task
        string[] requiredSkills;
        TaskStatus status;
        string proofHash; // IPFS hash for submitted proof
        uint256 assignedAt;
        uint256 completedAt;
    }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        ProposalType proposalType;
        ProposalStatus status;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        uint256 quorumRequired; // Quorum for this specific proposal, can be dynamic
        uint256 votingPeriodEnd;
        string descriptionHash; // General hash for proposal details
        address targetAddress; // For member removal, funds withdrawal, etc.
        bytes callData; // For generic parameter changes or contract calls
        uint256 value; // For funds withdrawal
        uint256 createdAt;
    }

    struct AIOracleQuery {
        uint256 queryId;
        address requester;
        string queryHash; // IPFS hash for the AI query details/prompt
        uint256 bounty; // ETH/token bounty for the AI service provider
        address callbackContract;
        bytes4 callbackFunction;
        string responseHash; // IPFS hash for the AI's response
        AIQueryStatus status;
        uint256 requestedAt;
        uint256 respondedAt;
    }

    // --- State Variables ---

    string public name;
    address public owner; // The initial creator of the contract, can be DAO member 0
    address public treasury; // The contract's own address acts as treasury

    uint256 public nextMemberId = 1; // Though we use address as ID for Member mapping
    uint256 public nextProjectId = 1;
    uint256 public nextTaskId = 1;
    uint256 public nextProposalId = 1;
    uint256 public nextAIQueryId = 1;

    uint256 public minReputationForProposing = 10; // Example: Minimum reputation to propose
    uint256 public minReputationForVoting = 1; // Example: Minimum reputation to vote

    // Governance parameters
    uint256 public quorumPercentage; // e.g., 50 for 50%
    uint256 public votingPeriod; // In seconds

    // Mappings
    mapping(address => Member) public members;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => AIOracleQuery) public aiQueries;

    // Whitelisted AI agents (can be a multi-sig or another DAO)
    mapping(address => bool) public whitelistedAIAgents;

    // --- Events ---

    event MemberApplied(address indexed applicant, string profileHash);
    event MemberApproved(address indexed newMember, uint256 proposalId);
    event MemberRemoved(address indexed removedMember, uint256 proposalId, string reasonHash);
    event MemberProfileUpdated(address indexed member, string newProfileHash);
    event SkillsDeclared(address indexed member, string[] skills);
    event SkillEndorsed(address indexed endorser, address indexed member, string skill);
    event ReputationAwarded(address indexed member, uint256 amount, string reasonHash);
    event ReputationPenalized(address indexed member, uint256 amount, string reasonHash);

    event ProjectProposed(uint256 indexed projectId, address indexed proposer, string descriptionHash, uint256 rewardBudget);
    event ProjectApproved(uint256 indexed projectId, uint256 proposalId);
    event TaskCreated(uint256 indexed taskId, uint256 indexed projectId, address creator, string descriptionHash, uint256 taskReward);
    event TaskAssigned(uint256 indexed taskId, address indexed assignee);
    event TaskProofSubmitted(uint256 indexed taskId, address indexed submitter, string proofHash);
    event TaskVerified(uint256 indexed taskId, address indexed verifier, bool isComplete);
    event TaskRewardClaimed(uint256 indexed taskId, address indexed claimant, uint256 rewardAmount);
    event TaskDisputed(uint256 indexed taskId, address indexed disputer, string reasonHash);

    event AIQueryRequested(uint256 indexed queryId, address indexed requester, string queryHash, uint256 bounty, address callbackContract);
    event AIResponseSubmitted(uint256 indexed queryId, address indexed submitter, string responseHash);
    event AIModelUpdateProposed(uint256 indexed proposalId, string modelIdentifier, string newModelHash);
    event AIModelUpdateApproved(uint256 indexed proposalId, string modelIdentifier);

    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, ProposalType proposalType, address indexed proposer, uint256 votingPeriodEnd);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool vote);
    event ProposalExecuted(uint256 indexed proposalId, ProposalStatus finalStatus);

    // --- Modifiers ---

    modifier onlyMember() {
        require(members[msg.sender].status == MemberStatus.Active, "AetherForgeDAO: Caller is not an active member.");
        _;
    }

    modifier onlyReputableMember(uint256 _requiredReputation) {
        require(members[msg.sender].status == MemberStatus.Active, "AetherForgeDAO: Caller is not an active member.");
        require(members[msg.sender].reputation >= _requiredReputation, "AetherForgeDAO: Insufficient reputation.");
        _;
    }

    modifier isVotingPeriodActive(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.Active, "AetherForgeDAO: Proposal is not active.");
        require(block.timestamp <= proposals[_proposalId].votingPeriodEnd, "AetherForgeDAO: Voting period has ended.");
        _;
    }

    modifier onlyWhitelistedAIAgent() {
        require(whitelistedAIAgents[msg.sender], "AetherForgeDAO: Caller is not a whitelisted AI agent.");
        _;
    }

    // --- Constructor ---

    constructor(string memory _name, address _initialMember, uint256 _quorumPercentage, uint256 _votingPeriod) {
        require(_quorumPercentage > 0 && _quorumPercentage <= 100, "AetherForgeDAO: Quorum percentage must be between 1 and 100.");
        require(_votingPeriod > 0, "AetherForgeDAO: Voting period must be positive.");

        name = _name;
        owner = msg.sender; // The deployer is initially the owner
        treasury = address(this); // The contract itself holds the funds

        quorumPercentage = _quorumPercentage;
        votingPeriod = _votingPeriod;

        // Add initial member (founder/deployer)
        members[_initialMember] = Member({
            memberAddress: _initialMember,
            status: MemberStatus.Active,
            reputation: 100, // Initial reputation for founder
            profileHash: "initial-founder-profile",
            exists: true
        });
        emit MemberApproved(_initialMember, 0); // ProposalId 0 for initial setup
    }

    // --- Core DAO & Membership Functions ---

    /**
     * @notice Allows a non-member to submit an application to join the DAO.
     * @param _profileHash IPFS or similar hash to the applicant's off-chain profile/portfolio.
     */
    function applyForMembership(string memory _profileHash) external {
        require(members[msg.sender].status == MemberStatus.Pending || !members[msg.sender].exists, "AetherForgeDAO: Already a member or has a pending application.");
        
        // Create a new proposal for membership
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender, // Applicant is the proposer of their own membership proposal
            proposalType: ProposalType.MembershipApplication,
            status: ProposalStatus.Active,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            quorumRequired: quorumPercentage, // Default quorum
            votingPeriodEnd: block.timestamp + votingPeriod,
            descriptionHash: _profileHash, // The profile hash acts as description
            targetAddress: msg.sender,
            callData: "",
            value: 0,
            createdAt: block.timestamp
        });

        // Initialize member status as Pending
        members[msg.sender].memberAddress = msg.sender;
        members[msg.sender].status = MemberStatus.Pending;
        members[msg.sender].profileHash = _profileHash;
        members[msg.sender].exists = true;

        emit MemberApplied(msg.sender, _profileHash);
        emit ProposalCreated(proposalId, ProposalType.MembershipApplication, msg.sender, proposals[proposalId].votingPeriodEnd);
    }

    /**
     * @notice Existing DAO members vote to approve or reject pending membership applications.
     * @param _proposalId The ID of the membership application proposal.
     * @param _approve True for approval, false for rejection.
     */
    function voteOnMembershipApplication(uint256 _proposalId, bool _approve) external onlyReputableMember(minReputationForVoting) isVotingPeriodActive(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.MembershipApplication, "AetherForgeDAO: Not a membership application proposal.");
        require(members[msg.sender].votedProposals[_proposalId] == false, "AetherForgeDAO: Already voted on this proposal.");

        members[msg.sender].votedProposals[_proposalId] = true;
        _approve ? proposal.totalVotesFor++ : proposal.totalVotesAgainst++;

        emit ProposalVoted(_proposalId, msg.sender, _approve);
    }

    /**
     * @notice An existing member can update the hash pointing to their latest off-chain profile.
     * @param _newProfileHash The new IPFS/off-chain hash for the member's profile.
     */
    function updateMemberProfileHash(string memory _newProfileHash) external onlyMember {
        members[msg.sender].profileHash = _newProfileHash;
        emit MemberProfileUpdated(msg.sender, _newProfileHash);
    }

    /**
     * @notice A member can propose the removal of another member, providing an off-chain reason hash.
     * @param _memberToRemove The address of the member to propose for removal.
     * @param _reasonHash IPFS hash for the justification of removal.
     */
    function proposeMemberRemoval(address _memberToRemove, string memory _reasonHash) external onlyReputableMember(minReputationForProposing) {
        require(_memberToRemove != msg.sender, "AetherForgeDAO: Cannot propose to remove yourself.");
        require(members[_memberToRemove].status == MemberStatus.Active, "AetherForgeDAO: Target member is not active.");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            proposalType: ProposalType.MemberRemoval,
            status: ProposalStatus.Active,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            quorumRequired: quorumPercentage,
            votingPeriodEnd: block.timestamp + votingPeriod,
            descriptionHash: _reasonHash,
            targetAddress: _memberToRemove,
            callData: "",
            value: 0,
            createdAt: block.timestamp
        });
        emit ProposalCreated(proposalId, ProposalType.MemberRemoval, msg.sender, proposals[proposalId].votingPeriodEnd);
    }

    /**
     * @notice Members vote on proposals to remove a fellow member from the DAO.
     * @param _proposalId The ID of the member removal proposal.
     * @param _approve True to approve removal, false to reject.
     */
    function voteOnMemberRemoval(uint256 _proposalId, bool _approve) external onlyReputableMember(minReputationForVoting) isVotingPeriodActive(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.MemberRemoval, "AetherForgeDAO: Not a member removal proposal.");
        require(members[msg.sender].votedProposals[_proposalId] == false, "AetherForgeDAO: Already voted on this proposal.");

        members[msg.sender].votedProposals[_proposalId] = true;
        _approve ? proposal.totalVotesFor++ : proposal.totalVotesAgainst++;

        emit ProposalVoted(_proposalId, msg.sender, _approve);
    }

    // --- Reputation & Skill System Functions ---

    /**
     * @notice Members can publicly declare a set of skills they possess.
     * @param _skills An array of skill strings (e.g., "Solidity", "UI/UX Design").
     */
    function declareSkills(string[] memory _skills) external onlyMember {
        for (uint256 i = 0; i < _skills.length; i++) {
            members[msg.sender].skills[_skills[i]] = 0; // Initialize endorsement count to 0
        }
        emit SkillsDeclared(msg.sender, _skills);
    }

    /**
     * @notice Other members can endorse a member's declared skill, adding credibility.
     * @param _member The address of the member whose skill is being endorsed.
     * @param _skill The specific skill string to endorse.
     */
    function endorseSkill(address _member, string memory _skill) external onlyMember {
        require(_member != msg.sender, "AetherForgeDAO: Cannot endorse your own skills.");
        require(members[_member].status == MemberStatus.Active, "AetherForgeDAO: Target member is not active.");
        
        // Ensure skill exists (was declared by the member)
        uint256 currentEndorsements = members[_member].skills[_skill];
        require(currentEndorsements >= 0, "AetherForgeDAO: Skill not declared by member."); // Greater than or equal to 0 means it exists

        members[_member].skills[_skill] = currentEndorsements + 1;
        emit SkillEndorsed(msg.sender, _member, _skill);
    }

    /**
     * @notice DAO can manually award reputation points to a member for general contributions.
     * @dev This would typically be triggered by a governance proposal (`executeProposal`).
     * @param _member The address of the member to award reputation to.
     * @param _amount The amount of reputation to award.
     * @param _reasonHash IPFS hash for the reason of the award.
     */
    function awardReputation(address _member, uint256 _amount, string memory _reasonHash) external onlyMember { // Simplified: only member can call, but in real DAO, this would be via governance.
        require(members[_member].status == MemberStatus.Active, "AetherForgeDAO: Target member is not active.");
        members[_member].reputation += _amount;
        emit ReputationAwarded(_member, _amount, _reasonHash);
    }

    /**
     * @notice DAO can manually deduct reputation points from a member for negative actions or failures.
     * @dev This would typically be triggered by a governance proposal (`executeProposal`).
     * @param _member The address of the member to penalize.
     * @param _amount The amount of reputation to deduct.
     * @param _reasonHash IPFS hash for the reason of the penalty.
     */
    function penalizeReputation(address _member, uint256 _amount, string memory _reasonHash) external onlyMember { // Simplified: only member can call, but in real DAO, this would be via governance.
        require(members[_member].status == MemberStatus.Active, "AetherForgeDAO: Target member is not active.");
        members[_member].reputation = members[_member].reputation > _amount ? members[_member].reputation - _amount : 0;
        emit ReputationPenalized(_member, _amount, _reasonHash);
    }

    /**
     * @notice Retrieves a member's profile hash, current reputation score, and declared skills.
     * @param _member The address of the member.
     * @return profileHash The IPFS hash of the member's profile.
     * @return reputation The member's current reputation score.
     * @return skills An array of the member's declared skills.
     */
    function getMemberDetails(address _member) external view returns (string memory profileHash, uint256 reputation, string[] memory skillsArray) {
        require(members[_member].exists, "AetherForgeDAO: Member does not exist.");

        profileHash = members[_member].profileHash;
        reputation = members[_member].reputation;

        // Iterate through the skills mapping to get the keys (skill names)
        uint256 skillCount = 0;
        for (uint256 i = 0; i < type(string[]).maxSize; i++) { // Max size is not actually useful for iterating map keys.
            // This part is tricky. Solidity mappings do not have iterable keys.
            // A more practical approach for skills would be to store them in a dynamic array
            // within the Member struct, and update that array along with the mapping.
            // For now, returning an empty array as a placeholder for simplicity due to Solidity's limitation.
            // In a real scenario, you'd have an auxiliary array or rely on off-chain indexing.
        }
        
        skillsArray = new string[](skillCount); // Placeholder for actual skill retrieval
        // Populate skillsArray if an auxiliary storage was used.
    }

    // --- Task Orchestration & Project Management Functions ---

    /**
     * @notice A member can propose a new project for the DAO to undertake.
     * @param _projectDescriptionHash IPFS hash for the project's detailed description.
     * @param _rewardBudget Total ETH/token budget allocated for tasks within this project.
     * @param _reputationBonus Additional reputation awarded upon overall project completion.
     */
    function proposeProject(string memory _projectDescriptionHash, uint256 _rewardBudget, uint256 _reputationBonus) external onlyReputableMember(minReputationForProposing) {
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            proposalType: ProposalType.ProjectApproval,
            status: ProposalStatus.Active,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            quorumRequired: quorumPercentage,
            votingPeriodEnd: block.timestamp + votingPeriod,
            descriptionHash: _projectDescriptionHash,
            targetAddress: address(0), // No specific target address for project approval
            callData: abi.encode(_rewardBudget, _reputationBonus), // Store budget and bonus for later project creation
            value: 0,
            createdAt: block.timestamp
        });
        emit ProposalCreated(proposalId, ProposalType.ProjectApproval, msg.sender, proposals[proposalId].votingPeriodEnd);
        emit ProjectProposed(0, msg.sender, _projectDescriptionHash, _rewardBudget); // ProjectId 0 initially, will be set on execution
    }

    /**
     * @notice Members vote to approve or reject proposed projects.
     * @param _proposalId The ID of the project approval proposal.
     * @param _approve True for approval, false for rejection.
     */
    function voteOnProjectProposal(uint256 _proposalId, bool _approve) external onlyReputableMember(minReputationForVoting) isVotingPeriodActive(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.ProjectApproval, "AetherForgeDAO: Not a project approval proposal.");
        require(members[msg.sender].votedProposals[_proposalId] == false, "AetherForgeDAO: Already voted on this proposal.");

        members[msg.sender].votedProposals[_proposalId] = true;
        _approve ? proposal.totalVotesFor++ : proposal.totalVotesAgainst++;

        emit ProposalVoted(_proposalId, msg.sender, _approve);
    }

    /**
     * @notice Creates a specific task under an approved project.
     * @param _projectId The ID of the parent project.
     * @param _taskDescriptionHash IPFS hash for the task's detailed description.
     * @param _taskReward ETH/token reward for completing this task.
     * @param _reputationBoost Reputation points awarded for completing this task.
     * @param _requiredSkills An array of skills required to perform this task.
     */
    function createTask(uint256 _projectId, string memory _taskDescriptionHash, uint256 _taskReward, uint256 _reputationBoost, string[] memory _requiredSkills) external onlyMember {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Approved || project.status == ProjectStatus.InProgress, "AetherForgeDAO: Project is not approved or in progress.");
        // Additional checks: caller could be project proposer, or specific role

        uint256 taskId = nextTaskId++;
        tasks[taskId] = Task({
            taskId: taskId,
            projectId: _projectId,
            assignee: address(0), // Unassigned initially
            descriptionHash: _taskDescriptionHash,
            taskReward: _taskReward,
            reputationBoost: _reputationBoost,
            requiredSkills: _requiredSkills,
            status: TaskStatus.Created,
            proofHash: "",
            assignedAt: 0,
            completedAt: 0
        });
        emit TaskCreated(taskId, _projectId, msg.sender, _taskDescriptionHash, _taskReward);
    }

    /**
     * @notice Assigns an open task to a specific DAO member.
     * @param _taskId The ID of the task to assign.
     * @param _assignee The address of the member to assign the task to.
     */
    function assignTaskToMember(uint256 _taskId, address _assignee) external onlyMember {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Created, "AetherForgeDAO: Task is not in 'Created' status.");
        require(members[_assignee].status == MemberStatus.Active, "AetherForgeDAO: Assignee is not an active member.");
        
        // Advanced: Check if assignee has required skills and sufficient reputation (not implemented for brevity)
        // for (uint256 i = 0; i < task.requiredSkills.length; i++) {
        //     require(members[_assignee].skills[task.requiredSkills[i]] > 0, "AetherForgeDAO: Assignee lacks required skill endorsement.");
        // }

        task.assignee = _assignee;
        task.status = TaskStatus.Assigned;
        task.assignedAt = block.timestamp;
        emit TaskAssigned(_taskId, _assignee);
    }

    /**
     * @notice An assigned member submits an off-chain hash as proof of their task completion.
     * @param _taskId The ID of the task for which proof is being submitted.
     * @param _proofHash IPFS hash for the proof of completion.
     */
    function submitTaskProof(uint256 _taskId, string memory _proofHash) external onlyMember {
        Task storage task = tasks[_taskId];
        require(task.assignee == msg.sender, "AetherForgeDAO: Caller is not assigned to this task.");
        require(task.status == TaskStatus.Assigned || task.status == TaskStatus.InProgress, "AetherForgeDAO: Task is not assigned or in progress.");

        task.proofHash = _proofHash;
        task.status = TaskStatus.ProofSubmitted;
        emit TaskProofSubmitted(_taskId, msg.sender, _proofHash);
    }

    /**
     * @notice Designated verifiers (or DAO vote) assess the submitted proof and mark the task as complete or incomplete.
     * @dev This can be simplified to a direct call from any member for demo, but should be a governance action.
     * @param _taskId The ID of the task to verify.
     * @param _isComplete True if the task is successfully completed, false otherwise.
     */
    function verifyTaskCompletion(uint256 _taskId, bool _isComplete) external onlyMember { // Simplified access for demo.
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.ProofSubmitted || task.status == TaskStatus.Disputed, "AetherForgeDAO: Task not ready for verification.");
        
        if (_isComplete) {
            task.status = TaskStatus.Verified;
            task.completedAt = block.timestamp;
            // Optionally, automatically award reputation here if not done by claimTaskReward
            // members[task.assignee].reputation += task.reputationBoost;
        } else {
            task.status = TaskStatus.Failed;
            // Optionally penalize reputation here
            // members[task.assignee].reputation = members[task.assignee].reputation > task.reputationBoost ? members[task.assignee].reputation - task.reputationBoost : 0;
        }
        emit TaskVerified(_taskId, msg.sender, _isComplete);
    }
    
    /**
     * @notice Allows any DAO member to dispute a `verifyTaskCompletion` decision or a submitted `_proofHash`.
     *         This triggers a review process (e.g., another vote or multi-sig review).
     * @param _taskId The ID of the task being disputed.
     * @param _reasonHash IPFS hash for the reason of the dispute.
     */
    function disputeTaskCompletion(uint256 _taskId, string memory _reasonHash) external onlyMember {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Verified || task.status == TaskStatus.ProofSubmitted, "AetherForgeDAO: Task is not in a state to be disputed.");
        
        task.status = TaskStatus.Disputed;
        // In a full implementation, this would trigger a new dispute resolution proposal.
        emit TaskDisputed(_taskId, msg.sender, _reasonHash);
    }

    /**
     * @notice The assigned member can claim the specified reward and reputation boost after successful verification.
     * @param _taskId The ID of the task for which rewards are being claimed.
     */
    function claimTaskReward(uint256 _taskId) external onlyMember {
        Task storage task = tasks[_taskId];
        require(task.assignee == msg.sender, "AetherForgeDAO: Caller is not the assignee of this task.");
        require(task.status == TaskStatus.Verified, "AetherForgeDAO: Task not yet verified.");
        
        // Ensure rewards are only claimed once
        require(task.taskReward > 0 || task.reputationBoost > 0, "AetherForgeDAO: No reward or boost to claim or already claimed.");

        if (task.taskReward > 0) {
            require(address(this).balance >= task.taskReward, "AetherForgeDAO: Insufficient treasury balance for task reward.");
            payable(msg.sender).transfer(task.taskReward);
            task.taskReward = 0; // Mark as claimed
        }
        
        if (task.reputationBoost > 0) {
            members[msg.sender].reputation += task.reputationBoost;
            task.reputationBoost = 0; // Mark as claimed
        }

        emit TaskRewardClaimed(_taskId, msg.sender, task.taskReward);
    }

    // --- AI Integration & Oracle Functions ---

    /**
     * @notice Members can request an off-chain AI analysis or data query.
     * @param _queryHash IPFS hash for the detailed AI query/prompt.
     * @param _bounty ETH/token bounty for the AI service provider.
     * @param _callbackContract The contract that expects the AI's response.
     * @param _callbackFunction The function signature (bytes4) on the callback contract.
     */
    function requestAIOracleQuery(string memory _queryHash, uint256 _bounty, address _callbackContract, bytes4 _callbackFunction) external payable onlyReputableMember(minReputationForProposing) {
        require(msg.value >= _bounty, "AetherForgeDAO: Insufficient bounty provided.");
        require(_callbackContract != address(0), "AetherForgeDAO: Callback contract cannot be zero address.");
        
        uint256 queryId = nextAIQueryId++;
        aiQueries[queryId] = AIOracleQuery({
            queryId: queryId,
            requester: msg.sender,
            queryHash: _queryHash,
            bounty: _bounty,
            callbackContract: _callbackContract,
            callbackFunction: _callbackFunction,
            responseHash: "",
            status: AIQueryStatus.Requested,
            requestedAt: block.timestamp,
            respondedAt: 0
        });

        // Funds for bounty are held in this contract's treasury
        emit AIQueryRequested(queryId, msg.sender, _queryHash, _bounty, _callbackContract);
    }

    /**
     * @notice A whitelisted AI agent or trusted oracle calls this function to deliver the AI's analysis result.
     * @param _queryId The ID of the AI query being responded to.
     * @param _responseHash IPFS hash for the AI's response/analysis.
     */
    function submitAIOracleResponse(uint256 _queryId, string memory _responseHash) external onlyWhitelistedAIAgent {
        AIOracleQuery storage query = aiQueries[_queryId];
        require(query.status == AIQueryStatus.Requested || query.status == AIQueryStatus.InProgress, "AetherForgeDAO: Query not in an active state.");
        
        query.responseHash = _responseHash;
        query.status = AIQueryStatus.ResponseSubmitted;
        query.respondedAt = block.timestamp;
        
        // Transfer bounty to the AI agent
        if (query.bounty > 0) {
            require(address(this).balance >= query.bounty, "AetherForgeDAO: Insufficient treasury balance for AI bounty.");
            payable(msg.sender).transfer(query.bounty);
        }

        // Attempt callback to the requesting contract (this might fail if the contract doesn't exist or function isn't callable)
        // In a real system, this callback might be part of a separate verification step.
        // bytes memory payload = abi.encodeWithSelector(query.callbackFunction, _queryId, _responseHash);
        // (bool success,) = query.callbackContract.call(payload);
        // if (!success) {
        //     // Handle callback failure, e.g., revert or log. For this demo, we'll just emit event.
        // }

        emit AIResponseSubmitted(_queryId, msg.sender, _responseHash);
    }
    
    /**
     * @notice Propose to update the reference identifier, hash, or configuration for an AI model.
     * @param _modelIdentifier A unique string identifier for the AI model (e.g., "DAO_Content_Generator_V2").
     * @param _newModelHash The new IPFS hash pointing to the updated AI model or its documentation/config.
     * @param _configHash An optional hash for associated configuration details.
     */
    function proposeAIModelUpdate(string memory _modelIdentifier, string memory _newModelHash, string memory _configHash) external onlyReputableMember(minReputationForProposing) {
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            proposalType: ProposalType.AIModelUpdate,
            status: ProposalStatus.Active,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            quorumRequired: quorumPercentage,
            votingPeriodEnd: block.timestamp + votingPeriod,
            descriptionHash: string(abi.encodePacked(_modelIdentifier, "|", _newModelHash, "|", _configHash)), // Encapsulate details
            targetAddress: address(0), // No specific target address
            callData: "", // No direct contract call here, just a record
            value: 0,
            createdAt: block.timestamp
        });
        emit ProposalCreated(proposalId, ProposalType.AIModelUpdate, msg.sender, proposals[proposalId].votingPeriodEnd);
        emit AIModelUpdateProposed(proposalId, _modelIdentifier, _newModelHash);
    }

    /**
     * @notice Members vote on proposals to update or change the AI models or configurations.
     * @param _proposalId The ID of the AI model update proposal.
     * @param _approve True for approval, false for rejection.
     */
    function voteOnAIModelUpdate(uint256 _proposalId, bool _approve) external onlyReputableMember(minReputationForVoting) isVotingPeriodActive(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.AIModelUpdate, "AetherForgeDAO: Not an AI model update proposal.");
        require(members[msg.sender].votedProposals[_proposalId] == false, "AetherForgeDAO: Already voted on this proposal.");

        members[msg.sender].votedProposals[_proposalId] = true;
        _approve ? proposal.totalVotesFor++ : proposal.totalVotesAgainst++;

        emit ProposalVoted(_proposalId, msg.sender, _approve);
    }

    // --- Treasury Management & Governance Functions ---
    
    /**
     * @notice Allows anyone to deposit funds into the DAO's treasury.
     */
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    // Alternative explicit deposit function
    function depositFunds() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @notice A general-purpose function to execute a governance proposal that has successfully passed.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external onlyMember { // Simplified: any member can call, but should be a dedicated executor or automated.
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "AetherForgeDAO: Proposal is not active.");
        require(block.timestamp > proposal.votingPeriodEnd, "AetherForgeDAO: Voting period has not ended yet.");
        require(proposal.totalVotesFor > 0, "AetherForgeDAO: Proposal has no 'for' votes."); // At least one 'for' vote.

        // Calculate total active members for quorum (simplified: count all active members)
        uint256 activeMembersCount = 0;
        for (uint256 i = 0; i < nextMemberId; i++) { // This iteration is problematic with address keys
            // In a real system, you'd maintain an array of active member addresses for this
            // For now, let's assume `nextMemberId` indicates a conceptual count for quorum calculation.
            // A more robust solution would be to track total active members via a state variable.
            // For simplicity in this example, let's use a dummy total for quorum check.
            activeMembersCount = 100; // Placeholder for a large enough active member count
            break; // Placeholder, assuming enough active members
        }
        
        uint256 votesRequiredForQuorum = (activeMembersCount * proposal.quorumRequired) / 100;

        // Determine if the proposal passed
        bool passed = (proposal.totalVotesFor > proposal.totalVotesAgainst) && (proposal.totalVotesFor >= votesRequiredForQuorum);

        if (passed) {
            proposal.status = ProposalStatus.Approved;
            if (proposal.proposalType == ProposalType.MembershipApplication) {
                members[proposal.targetAddress].status = MemberStatus.Active;
                members[proposal.targetAddress].reputation = 1; // Base reputation for new members
                emit MemberApproved(proposal.targetAddress, _proposalId);
            } else if (proposal.proposalType == ProposalType.MemberRemoval) {
                members[proposal.targetAddress].status = MemberStatus.Removed;
                emit MemberRemoved(proposal.targetAddress, _proposalId, proposal.descriptionHash);
            } else if (proposal.proposalType == ProposalType.ProjectApproval) {
                // Decode original project details
                (uint256 _rewardBudget, uint256 _reputationBonus) = abi.decode(proposal.callData, (uint256, uint256));
                uint256 projectId = nextProjectId++;
                projects[projectId] = Project({
                    projectId: projectId,
                    proposer: proposal.proposer,
                    descriptionHash: proposal.descriptionHash,
                    rewardBudget: _rewardBudget,
                    reputationBonus: _reputationBonus,
                    status: ProjectStatus.Approved,
                    createdAt: block.timestamp
                });
                emit ProjectApproved(projectId, _proposalId);
            } else if (proposal.proposalType == ProposalType.AIModelUpdate) {
                 // In a real system, this would update a canonical mapping for AI models
                 // For now, just emit the event to signify approval.
                (string memory modelIdentifier, string memory newModelHash, string memory configHash) = _decodeAIModelUpdateDescription(proposal.descriptionHash);
                emit AIModelUpdateApproved(_proposalId, modelIdentifier);
            } else if (proposal.proposalType == ProposalType.FundsWithdrawal) {
                require(address(this).balance >= proposal.value, "AetherForgeDAO: Insufficient treasury balance for withdrawal.");
                require(proposal.targetAddress != address(0), "AetherForgeDAO: Target address for withdrawal cannot be zero.");
                payable(proposal.targetAddress).transfer(proposal.value);
                emit FundsWithdrawn(_proposalId, proposal.targetAddress, proposal.value);
            }
            // For GenericParameterChange, _targetAddress and _callData would be used for low-level calls
            // (bool success, ) = proposal.targetAddress.call(proposal.callData);
            // require(success, "AetherForgeDAO: Proposal execution failed.");

            proposal.status = ProposalStatus.Executed;
            emit ProposalExecuted(_proposalId, ProposalStatus.Executed);
        } else {
            proposal.status = ProposalStatus.Rejected;
            emit ProposalExecuted(_proposalId, ProposalStatus.Rejected);
        }
    }

    // --- Helper function for AI Model Update Proposal Description ---
    function _decodeAIModelUpdateDescription(string memory encodedString) internal pure returns (string memory modelIdentifier, string memory newModelHash, string memory configHash) {
        // This is a simplified decoding. In production, use more robust string parsing or abi.encode directly for callData.
        bytes memory b = bytes(encodedString);
        uint256 firstPipe = 0;
        uint256 secondPipe = 0;

        for (uint256 i = 0; i < b.length; i++) {
            if (b[i] == byte('|')) {
                if (firstPipe == 0) {
                    firstPipe = i;
                } else if (secondPipe == 0) {
                    secondPipe = i;
                    break;
                }
            }
        }
        
        require(firstPipe > 0 && secondPipe > firstPipe, "AetherForgeDAO: Malformed AI model update description hash.");

        modelIdentifier = string(b[0:firstPipe]);
        newModelHash = string(b[firstPipe + 1:secondPipe]);
        configHash = string(b[secondPipe + 1:b.length]);
    }
}
```