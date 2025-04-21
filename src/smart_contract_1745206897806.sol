```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation & Governance DAO
 * @author Gemini AI (Conceptual Contract - Not for Production)
 * @dev A smart contract implementing a dynamic reputation-based Decentralized Autonomous Organization (DAO)
 *      with advanced features for community engagement, skill-based roles, and decentralized learning.
 *
 * Outline and Function Summary:
 *
 * 1.  Membership & Reputation:
 *     - joinDAO(): Allows users to become members of the DAO.
 *     - leaveDAO(): Allows members to exit the DAO.
 *     - getMemberReputation(address member): Retrieves the reputation score of a member.
 *     - increaseReputation(address member, uint256 amount): Increases a member's reputation (admin/task completion).
 *     - decreaseReputation(address member, uint256 amount): Decreases a member's reputation (admin/penalties).
 *     - transferReputation(address recipient, uint256 amount): Allows members to transfer reputation to others (limited).
 *
 * 2.  Skill-Based Roles & Guilds:
 *     - createGuild(string memory guildName, string memory guildDescription): Creates a new skill-based guild within the DAO.
 *     - joinGuild(uint256 guildId): Allows members to join a specific guild.
 *     - leaveGuild(uint256 guildId): Allows members to leave a guild.
 *     - getGuildMembers(uint256 guildId): Retrieves the list of members in a guild.
 *     - assignRoleInGuild(uint256 guildId, address member, string memory roleName): Assigns a role to a member within a guild (guild admin).
 *     - removeRoleInGuild(uint256 guildId, address member, string memory roleName): Removes a role from a member within a guild (guild admin).
 *
 * 3.  Decentralized Learning & Knowledge Sharing:
 *     - proposeLearningModule(string memory moduleTitle, string memory moduleDescription, string memory moduleContentHash, uint256 reputationReward): Proposes a new learning module to the DAO.
 *     - voteOnLearningModule(uint256 moduleId, bool vote): Members vote on proposed learning modules.
 *     - approveLearningModule(uint256 moduleId): Approves a learning module if it passes voting (admin).
 *     - completeLearningModule(uint256 moduleId): Members mark a learning module as completed to earn reputation.
 *     - getLearningModuleDetails(uint256 moduleId): Retrieves details of a learning module.
 *
 * 4.  Dynamic Task & Project Management:
 *     - proposeTask(string memory taskTitle, string memory taskDescription, uint256 reputationReward, uint256 guildId): Proposes a task for a specific guild (or general DAO).
 *     - acceptTask(uint256 taskId): Members can accept open tasks.
 *     - submitTaskCompletion(uint256 taskId, string memory completionHash): Members submit proof of task completion.
 *     - approveTaskCompletion(uint256 taskId): Approves task completion and rewards reputation (task proposer/guild admin).
 *     - getTaskDetails(uint256 taskId): Retrieves details of a task.
 *
 * 5.  Advanced Governance & Proposals:
 *     - proposeGovernanceChange(string memory proposalTitle, string memory proposalDescription, bytes memory proposalData): Proposes changes to DAO parameters or contract logic.
 *     - voteOnGovernanceChange(uint256 proposalId, bool vote): Members vote on governance proposals.
 *     - executeGovernanceChange(uint256 proposalId): Executes approved governance proposals (admin/timelock).
 *     - delegateVote(address delegatee): Allows members to delegate their voting power to another member.
 *
 * 6.  Utility & Administration:
 *     - setReputationRewardForModuleCompletion(uint256 moduleId, uint256 reward): Admin sets reputation reward for completing a module.
 *     - setReputationRewardForTaskCompletion(uint256 taskId, uint256 reward): Admin sets reputation reward for completing a task.
 *     - getDAOInfo(): Returns general information about the DAO (member count, guild count etc.).
 *     - renounceMembership(): Allows members to permanently renounce their membership and reputation.
 */

contract DynamicReputationDAO {

    // --- Structs & Enums ---

    struct Member {
        uint256 reputation;
        bool isActive;
        // Add more member-specific data if needed (e.g., roles, guilds)
    }

    struct Guild {
        string name;
        string description;
        address guildAdmin; // Initially creator, could be changed via governance
        mapping(address => string[]) memberRoles; // Member address to list of roles within the guild
        uint256 memberCount;
    }

    struct LearningModule {
        string title;
        string description;
        string contentHash; // IPFS hash or similar
        uint256 reputationReward;
        bool isApproved;
        mapping(address => bool) completedBy; // Members who have completed the module
        uint256 completionCount;
    }

    struct Task {
        string title;
        string description;
        uint256 reputationReward;
        uint256 guildId; // 0 for general DAO tasks
        address proposer;
        address assignee;
        bool isCompleted;
        string completionHash;
        bool completionApproved;
    }

    struct GovernanceProposal {
        string title;
        string description;
        bytes proposalData; // Encoded function call data, or data to interpret for changes
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }


    // --- State Variables ---

    address public admin; // DAO Administrator
    uint256 public memberCount;
    mapping(address => Member) public members;
    mapping(uint256 => Guild) public guilds;
    uint256 public guildCount;
    mapping(uint256 => LearningModule) public learningModules;
    uint256 public learningModuleCount;
    mapping(uint256 => Task) public tasks;
    uint256 public taskCount;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public governanceProposalCount;
    mapping(address => address) public voteDelegations; // Member address to delegatee address
    uint256 public baseReputationRewardModule = 100; // Default reputation for module completion
    uint256 public baseReputationRewardTask = 50;   // Default reputation for task completion
    uint256 public governanceVotingDuration = 7 days; // Default voting duration for proposals


    // --- Events ---

    event MemberJoined(address memberAddress);
    event MemberLeft(address memberAddress);
    event ReputationIncreased(address memberAddress, uint256 amount);
    event ReputationDecreased(address memberAddress, uint256 amount);
    event ReputationTransferred(address from, address to, uint256 amount);
    event GuildCreated(uint256 guildId, string guildName, address admin);
    event GuildJoined(uint256 guildId, address member);
    event GuildLeft(uint256 guildId, address member);
    event RoleAssignedInGuild(uint256 guildId, address member, string roleName, address assignedBy);
    event RoleRemovedInGuild(uint256 guildId, address member, string roleName, address removedBy);
    event LearningModuleProposed(uint256 moduleId, string moduleTitle, address proposer);
    event LearningModuleVoted(uint256 moduleId, address voter, bool vote);
    event LearningModuleApproved(uint256 moduleId, address approver);
    event LearningModuleCompleted(uint256 moduleId, address completer);
    event TaskProposed(uint256 taskId, string taskTitle, address proposer, uint256 guildId);
    event TaskAccepted(uint256 taskId, address assignee);
    event TaskCompletionSubmitted(uint256 taskId, address submitter, string completionHash);
    event TaskCompletionApproved(uint256 taskId, address approver);
    event GovernanceProposalProposed(uint256 proposalId, string proposalTitle, address proposer);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);
    event VoteDelegated(address delegator, address delegatee);


    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only DAO admin can perform this action.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].isActive, "Only DAO members can perform this action.");
        _;
    }

    modifier validGuild(uint256 guildId) {
        require(guildId > 0 && guildId <= guildCount, "Invalid Guild ID.");
        _;
    }

    modifier guildAdmin(uint256 guildId) {
        require(guilds[guildId].guildAdmin == msg.sender, "Only Guild Admin can perform this action.");
        _;
    }

    modifier validLearningModule(uint256 moduleId) {
        require(moduleId > 0 && moduleId <= learningModuleCount, "Invalid Learning Module ID.");
        _;
    }

    modifier validTask(uint256 taskId) {
        require(taskId > 0 && taskId <= taskCount, "Invalid Task ID.");
        _;
    }

    modifier validGovernanceProposal(uint256 proposalId) {
        require(proposalId > 0 && proposalId <= governanceProposalCount, "Invalid Governance Proposal ID.");
        _;
    }

    modifier votingPeriodActive(uint256 proposalId) {
        require(block.timestamp >= governanceProposals[proposalId].votingStartTime && block.timestamp <= governanceProposals[proposalId].votingEndTime, "Voting period is not active.");
        _;
    }

    modifier proposalNotExecuted(uint256 proposalId) {
        require(!governanceProposals[proposalId].executed, "Proposal already executed.");
        _;
    }


    // --- Constructor ---

    constructor() {
        admin = msg.sender;
        memberCount = 0;
        guildCount = 0;
        learningModuleCount = 0;
        taskCount = 0;
        governanceProposalCount = 0;
    }


    // --- 1. Membership & Reputation ---

    function joinDAO() external {
        require(!members[msg.sender].isActive, "Already a member.");
        members[msg.sender] = Member({reputation: 0, isActive: true});
        memberCount++;
        emit MemberJoined(msg.sender);
    }

    function leaveDAO() external onlyMember {
        require(members[msg.sender].isActive, "Not a member.");
        members[msg.sender].isActive = false;
        memberCount--;
        emit MemberLeft(msg.sender);
    }

    function getMemberReputation(address member) external view returns (uint256) {
        return members[member].reputation;
    }

    function increaseReputation(address member, uint256 amount) external onlyAdmin {
        members[member].reputation += amount;
        emit ReputationIncreased(member, amount);
    }

    function decreaseReputation(address member, uint256 amount) external onlyAdmin {
        require(members[member].reputation >= amount, "Reputation cannot be negative.");
        members[member].reputation -= amount;
        emit ReputationDecreased(member, amount);
    }

    function transferReputation(address recipient, uint256 amount) external onlyMember {
        require(members[msg.sender].reputation >= amount, "Insufficient reputation.");
        require(recipient != address(0) && recipient != msg.sender, "Invalid recipient.");
        members[msg.sender].reputation -= amount;
        members[recipient].reputation += amount;
        emit ReputationTransferred(msg.sender, recipient, amount);
    }

    function renounceMembership() external onlyMember {
        delete members[msg.sender]; // Effectively removes member data
        memberCount--;
        emit MemberLeft(msg.sender);
    }


    // --- 2. Skill-Based Roles & Guilds ---

    function createGuild(string memory guildName, string memory guildDescription) external onlyMember {
        guildCount++;
        guilds[guildCount] = Guild({
            name: guildName,
            description: guildDescription,
            guildAdmin: msg.sender, // Creator is initial guild admin
            memberCount: 0
        });
        emit GuildCreated(guildCount, guildName, msg.sender);
    }

    function joinGuild(uint256 guildId) external onlyMember validGuild(guildId) {
        // Consider adding a check if member is already in guild if needed for more complex logic
        guilds[guildId].memberCount++;
        emit GuildJoined(guildId, msg.sender);
    }

    function leaveGuild(uint256 guildId) external onlyMember validGuild(guildId) {
        require(guilds[guildId].memberCount > 0, "Guild is already empty."); // Prevent underflow
        guilds[guildId].memberCount--;
        // Consider removing member from guild member list or roles mapping if implemented
        emit GuildLeft(guildId, msg.sender);
    }

    function getGuildMembers(uint256 guildId) external view validGuild(guildId) returns (address[] memory) {
        // This is a simplified version. For a real implementation, you would likely need to maintain a list of members per guild
        // Due to limitations of iterating mappings in Solidity, this is less efficient.
        // A better approach would be to maintain a separate array of guild members.
        address[] memory memberList = new address[](guilds[guildId].memberCount);
        uint256 index = 0;
        for (address memberAddress in members) {
            // In a real implementation, you'd check if 'memberAddress' is actually part of the guild.
            // For simplicity here, we're just assuming all members are potentially in any guild and counting guild members separately.
            // This needs to be improved for a production contract.
            if (members[memberAddress].isActive) { // Basic check if member is active in DAO
                // In a real guild implementation, you'd have a way to track guild membership explicitly.
                memberList[index] = memberAddress;
                index++;
                if (index >= guilds[guildId].memberCount) {
                    break; // Stop when we've collected enough members based on guild memberCount
                }
            }
        }
        return memberList;
    }


    function assignRoleInGuild(uint256 guildId, address member, string memory roleName) external onlyMember validGuild(guildId) guildAdmin(guildId) {
        guilds[guildId].memberRoles[member].push(roleName);
        emit RoleAssignedInGuild(guildId, member, roleName, msg.sender);
    }

    function removeRoleInGuild(uint256 guildId, address member, string memory roleName) external onlyMember validGuild(guildId) guildAdmin(guildId) {
        string[] storage roles = guilds[guildId].memberRoles[member];
        for (uint256 i = 0; i < roles.length; i++) {
            if (keccak256(bytes(roles[i])) == keccak256(bytes(roleName))) {
                delete roles[i]; // Delete role (leaves a gap, consider shifting for better array management if needed)
                // To truly remove and shift elements, you'd need more complex array manipulation logic.
                emit RoleRemovedInGuild(guildId, member, roleName, msg.sender);
                return;
            }
        }
        revert("Role not found for member in guild.");
    }


    // --- 3. Decentralized Learning & Knowledge Sharing ---

    function proposeLearningModule(string memory moduleTitle, string memory moduleDescription, string memory moduleContentHash, uint256 reputationReward) external onlyMember {
        learningModuleCount++;
        learningModules[learningModuleCount] = LearningModule({
            title: moduleTitle,
            description: moduleDescription,
            contentHash: moduleContentHash,
            reputationReward: reputationReward,
            isApproved: false,
            completionCount: 0
        });
        emit LearningModuleProposed(learningModuleCount, moduleTitle, msg.sender);
    }

    function voteOnLearningModule(uint256 moduleId, bool vote) external onlyMember validLearningModule(moduleId) {
        // Simple voting - could be weighted by reputation in a more advanced version
        // For now, first vote counts as approval/disapproval (simplified for example)
        LearningModule storage module = learningModules[moduleId];
        require(!module.isApproved, "Module already approved or rejected."); // Prevent revoting after approval/rejection

        if (vote) {
            approveLearningModule(moduleId); // If yes vote, immediately approve (simplified voting)
        } else {
            // In a real system, you might track votes against and have a rejection threshold.
            module.isApproved = false; // Simple rejection for no vote (again, simplified)
            emit LearningModuleApproved(moduleId, msg.sender); // Emit approval event even for rejection for simplicity in this example
        }
        emit LearningModuleVoted(moduleId, msg.sender, vote);
    }

    function approveLearningModule(uint256 moduleId) external onlyAdmin validLearningModule(moduleId) {
        require(!learningModules[moduleId].isApproved, "Module already approved.");
        learningModules[moduleId].isApproved = true;
        emit LearningModuleApproved(moduleId, msg.sender);
    }


    function completeLearningModule(uint256 moduleId) external onlyMember validLearningModule(moduleId) {
        LearningModule storage module = learningModules[moduleId];
        require(module.isApproved, "Learning module not yet approved.");
        require(!module.completedBy[msg.sender], "Module already completed.");

        module.completedBy[msg.sender] = true;
        module.completionCount++;
        increaseReputation(msg.sender, module.reputationReward > 0 ? module.reputationReward : baseReputationRewardModule); // Use module-specific reward or default
        emit LearningModuleCompleted(moduleId, msg.sender);
    }

    function getLearningModuleDetails(uint256 moduleId) external view validLearningModule(moduleId) returns (LearningModule memory) {
        return learningModules[moduleId];
    }


    // --- 4. Dynamic Task & Project Management ---

    function proposeTask(string memory taskTitle, string memory taskDescription, uint256 reputationReward, uint256 guildId) external onlyMember {
        taskCount++;
        tasks[taskCount] = Task({
            title: taskTitle,
            description: taskDescription,
            reputationReward: reputationReward,
            guildId: guildId,
            proposer: msg.sender,
            assignee: address(0),
            isCompleted: false,
            completionHash: "",
            completionApproved: false
        });
        emit TaskProposed(taskCount, taskTitle, msg.sender, guildId);
    }

    function acceptTask(uint256 taskId) external onlyMember validTask(taskId) {
        Task storage task = tasks[taskId];
        require(task.assignee == address(0), "Task already accepted.");
        task.assignee = msg.sender;
        emit TaskAccepted(taskId, msg.sender);
    }

    function submitTaskCompletion(uint256 taskId, string memory completionHash) external onlyMember validTask(taskId) {
        Task storage task = tasks[taskId];
        require(task.assignee == msg.sender, "Only assignee can submit completion.");
        require(!task.isCompleted, "Task already marked as completed.");
        task.completionHash = completionHash;
        task.isCompleted = true;
        emit TaskCompletionSubmitted(taskId, msg.sender, completionHash);
    }

    function approveTaskCompletion(uint256 taskId) external onlyMember validTask(taskId) {
        Task storage task = tasks[taskId];
        require(task.isCompleted, "Task completion not yet submitted.");
        require(!task.completionApproved, "Task completion already approved.");

        // Approval can be done by task proposer or guild admin (if guild task) or DAO admin.
        bool isApprover = (task.proposer == msg.sender) || (task.guildId > 0 && guilds[task.guildId].guildAdmin == msg.sender) || (admin == msg.sender);
        require(isApprover, "Only task proposer, guild admin, or DAO admin can approve completion.");

        task.completionApproved = true;
        increaseReputation(task.assignee, task.reputationReward > 0 ? task.reputationReward : baseReputationRewardTask); // Use task-specific reward or default
        emit TaskCompletionApproved(taskId, msg.sender);
    }

    function getTaskDetails(uint256 taskId) external view validTask(taskId) returns (Task memory) {
        return tasks[taskId];
    }


    // --- 5. Advanced Governance & Proposals ---

    function proposeGovernanceChange(string memory proposalTitle, string memory proposalDescription, bytes memory proposalData) external onlyMember {
        governanceProposalCount++;
        governanceProposals[governanceProposalCount] = GovernanceProposal({
            title: proposalTitle,
            description: proposalDescription,
            proposalData: proposalData,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + governanceVotingDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        emit GovernanceProposalProposed(governanceProposalCount, proposalTitle, msg.sender);
    }

    function voteOnGovernanceChange(uint256 proposalId, bool vote) external onlyMember validGovernanceProposal(proposalId) votingPeriodActive(proposalId) proposalNotExecuted(proposalId) {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        address voter = msg.sender;
        address delegatee = voteDelegations[voter];
        if (delegatee != address(0)) {
            voter = delegatee; // Use delegatee's address for voting if delegation is active
        }

        // In a real DAO, voting power would likely be reputation-weighted or token-weighted.
        if (vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit GovernanceProposalVoted(proposalId, voter, vote);
    }

    function executeGovernanceChange(uint256 proposalId) external onlyAdmin validGovernanceProposal(proposalId) proposalNotExecuted(proposalId) {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(block.timestamp > proposal.votingEndTime, "Voting period not yet ended.");

        // Simple majority for execution (can be changed via governance itself in a real DAO)
        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.executed = true;
            // In a real DAO, proposalData would be decoded and executed.
            // For simplicity, we just mark it as executed.
            // Example:  (bool success, bytes memory returnData) = address(this).delegatecall(proposal.proposalData);
            emit GovernanceProposalExecuted(proposalId);
        } else {
            revert("Governance proposal failed to pass."); // Proposal rejected
        }
    }

    function delegateVote(address delegatee) external onlyMember {
        require(delegatee != address(0) && delegatee != msg.sender, "Invalid delegatee address.");
        voteDelegations[msg.sender] = delegatee;
        emit VoteDelegated(msg.sender, delegatee);
    }


    // --- 6. Utility & Administration ---

    function setReputationRewardForModuleCompletion(uint256 moduleId, uint256 reward) external onlyAdmin validLearningModule(moduleId) {
        learningModules[moduleId].reputationReward = reward;
    }

    function setReputationRewardForTaskCompletion(uint256 taskId, uint256 reward) external onlyAdmin validTask(taskId) {
        tasks[taskId].reputationReward = reward;
    }

    function getDAOInfo() external view returns (uint256 currentMemberCount, uint256 currentGuildCount, uint256 currentLearningModuleCount, uint256 currentTaskCount, uint256 currentGovernanceProposalCount) {
        return (memberCount, guildCount, learningModuleCount, taskCount, governanceProposalCount);
    }

    function setGovernanceVotingDuration(uint256 durationInSeconds) external onlyAdmin {
        governanceVotingDuration = durationInSeconds;
    }

    function transferAdminRights(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid new admin address.");
        admin = newAdmin;
    }
}
```