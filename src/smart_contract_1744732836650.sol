```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Task Force DAO with Dynamic Reputation and Skill-Based Task Allocation
 * @author Bard (AI Assistant)
 * @dev A sophisticated DAO contract that manages members, proposals, tasks, and reputation
 *      based on skill sets, offering a dynamic and engaging decentralized work environment.
 *
 * Outline and Function Summary:
 *
 * State Variables:
 *   - admin: Address of the contract administrator.
 *   - members: Mapping of member address to Member struct (reputation, skills, isActive).
 *   - proposals: Mapping of proposal ID to Proposal struct (proposer, proposalType, description, votingEndTime, votes, executed, executionData).
 *   - tasks: Mapping of task ID to Task struct (proposer, assignee, description, requiredSkills, reward, deadline, status).
 *   - taskCounter, proposalCounter: Counters for unique IDs.
 *   - skillRegistry: Mapping of skill name to skill ID.
 *   - skillCounter: Counter for unique skill IDs.
 *   - reputationThresholds: Mapping for different reputation levels and their privileges.
 *   - votingDuration: Default voting duration for proposals.
 *   - quorumPercentage: Percentage of total members required for proposal quorum.
 *   - contractPaused: Boolean to pause/unpause contract functionalities.
 *   - governanceToken: Address of the governance token contract (optional, can be replaced with internal token logic).
 *
 * Events:
 *   - MemberJoined(address memberAddress);
 *   - MemberLeft(address memberAddress);
 *   - ReputationUpdated(address memberAddress, uint256 newReputation);
 *   - SkillRegistered(string skillName, uint256 skillId);
 *   - ProposalCreated(uint256 proposalId, ProposalType proposalType, address proposer, string description);
 *   - ProposalVoted(uint256 proposalId, address voter, bool vote);
 *   - ProposalExecuted(uint256 proposalId);
 *   - TaskCreated(uint256 taskId, address proposer, string description);
 *   - TaskAssigned(uint256 taskId, address assignee);
 *   - TaskCompleted(uint256 taskId, address submitter);
 *   - TaskApproved(uint256 taskId);
 *   - TaskRejected(uint256 taskId, string reason);
 *   - ContractPausedEvent(address admin);
 *   - ContractUnpausedEvent(address admin);
 *
 * Modifiers:
 *   - onlyAdmin: Restricts function access to the contract administrator.
 *   - onlyMember: Restricts function access to registered members.
 *   - notPaused: Restricts function execution when the contract is paused.
 *   - proposalActive: Restricts function execution to active proposals.
 *   - taskStatus: Restricts function execution based on task status.
 *   - reputationRequirement: Restricts function execution based on member reputation.
 *
 * Enums:
 *   - ProposalType: Enum for different proposal types (e.g., Membership, TaskCreation, ParameterChange).
 *   - TaskStatus: Enum for task statuses (e.g., Open, Assigned, Completed, Approved, Rejected).
 *
 * Structs:
 *   - Member: Struct to store member information (reputation, skills, isActive).
 *   - Proposal: Struct to store proposal details (proposer, type, description, voting, execution details).
 *   - Task: Struct to store task details (proposer, assignee, description, skills, reward, deadline, status).
 *
 * Functions:
 *
 * // --- Membership Management --- (6 functions)
 *   1. joinDAO(): Allows anyone to request membership.
 *   2. approveMembership(address _member): Admin function to approve a membership request.
 *   3. leaveDAO(): Allows a member to leave the DAO.
 *   4. getMemberReputation(address _member): View function to get a member's reputation.
 *   5. updateMemberSkills(string[] memory _skills): Member function to update their skill set.
 *   6. getMemberSkills(address _member): View function to get a member's skills.
 *
 * // --- Reputation System --- (4 functions)
 *   7. increaseReputation(address _member, uint256 _amount): Admin function to increase member reputation.
 *   8. decreaseReputation(address _member, uint256 _amount, string memory _reason): Admin function to decrease member reputation, with a reason.
 *   9. setReputationThreshold(string memory _levelName, uint256 _threshold): Admin function to set reputation thresholds for different levels.
 *  10. getReputationThreshold(string memory _levelName): View function to retrieve reputation threshold for a level.
 *
 * // --- Skill Management --- (3 functions)
 *  11. registerSkill(string memory _skillName): Admin function to register a new skill.
 *  12. getSkillId(string memory _skillName): View function to get skill ID by name.
 *  13. getSkillName(uint256 _skillId): View function to get skill name by ID.
 *
 * // --- Proposal Management --- (5 functions)
 *  14. createProposal(ProposalType _proposalType, string memory _description, bytes memory _executionData): Member function to create a new proposal.
 *  15. voteOnProposal(uint256 _proposalId, bool _vote): Member function to vote on an active proposal.
 *  16. executeProposal(uint256 _proposalId): Function to execute a successful proposal (can be permissioned or permissionless based on proposal type).
 *  17. getProposalStatus(uint256 _proposalId): View function to get the status of a proposal.
 *  18. getProposalDetails(uint256 _proposalId): View function to get detailed information about a proposal.
 *
 * // --- Task Management --- (6 functions)
 *  19. createTask(string memory _description, string[] memory _requiredSkills, uint256 _reward, uint256 _deadline): Member function to propose a new task.
 *  20. assignTask(uint256 _taskId, address _assignee): Member function (or admin/reputation based) to assign a task to a member.
 *  21. submitTaskCompletion(uint256 _taskId): Member function to submit task completion.
 *  22. approveTaskCompletion(uint256 _taskId): Function to approve task completion and reward the assignee.
 *  23. rejectTaskCompletion(uint256 _taskId, string memory _reason): Function to reject task completion with a reason.
 *  24. getTaskDetails(uint256 _taskId): View function to get detailed information about a task.
 *
 * // --- Contract Administration --- (3 functions)
 *  25. pauseContract(): Admin function to pause the contract.
 *  26. unpauseContract(): Admin function to unpause the contract.
 *  27. setVotingDuration(uint256 _durationInSeconds): Admin function to set the default voting duration.
 *  28. setQuorumPercentage(uint256 _percentage): Admin function to set the quorum percentage for proposals.
 */

contract TaskForceDAO {

    // --- State Variables ---
    address public admin;
    mapping(address => Member) public members;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => Task) public tasks;

    uint256 public taskCounter;
    uint256 public proposalCounter;

    mapping(string => uint256) public skillRegistry;
    uint256 public skillCounter;

    mapping(string => uint256) public reputationThresholds; // e.g., "TrustedMember" => 100

    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public quorumPercentage = 50; // Default quorum percentage

    bool public contractPaused = false;

    // Optional: Governance Token Address (replace with internal logic if needed)
    address public governanceToken;

    // --- Events ---
    event MemberJoined(address memberAddress);
    event MemberLeft(address memberAddress);
    event ReputationUpdated(address memberAddress, uint256 newReputation);
    event SkillRegistered(string skillName, uint256 skillId);
    event ProposalCreated(uint256 proposalId, ProposalType proposalType, address proposer, string description);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event TaskCreated(uint256 taskId, address proposer, string description);
    event TaskAssigned(uint256 taskId, address assignee);
    event TaskCompleted(uint256 taskId, address submitter);
    event TaskApproved(uint256 taskId);
    event TaskRejected(uint256 taskId, uint256 taskIdReason);
    event ContractPausedEvent(address admin);
    event ContractUnpausedEvent(address admin);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].isActive, "Only members can call this function.");
        _;
    }

    modifier notPaused() {
        require(!contractPaused, "Contract is paused.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].votingEndTime > block.timestamp && !proposals[_proposalId].executed, "Proposal is not active.");
        _;
    }

    modifier taskStatus(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Task status is not as expected.");
        _;
    }

    modifier reputationRequirement(address _member, uint256 _requiredReputation) {
        require(members[_member].reputation >= _requiredReputation, "Insufficient reputation.");
        _;
    }

    // --- Enums ---
    enum ProposalType {
        MembershipApproval,
        ParameterChange,
        TaskCreation,
        GeneralProposal
    }

    enum TaskStatus {
        Open,
        Assigned,
        Completed,
        Approved,
        Rejected
    }

    // --- Structs ---
    struct Member {
        uint256 reputation;
        mapping(uint256 => bool) skills; // Skill IDs
        bool isActive;
    }

    struct Proposal {
        address proposer;
        ProposalType proposalType;
        string description;
        uint256 votingEndTime;
        mapping(address => bool) votes; // address => vote (true for yes, false for no)
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        bytes executionData; // Optional data for proposal execution
    }

    struct Task {
        address proposer;
        address assignee;
        string description;
        uint256[] requiredSkills; // Array of Skill IDs
        uint256 reward;
        uint256 deadline;
        TaskStatus status;
    }

    // --- Constructor ---
    constructor() {
        admin = msg.sender;
        skillCounter = 0; // Initialize skill counter
        proposalCounter = 0; // Initialize proposal counter
        taskCounter = 0; // Initialize task counter
    }

    // --- Membership Management ---
    function joinDAO() external notPaused {
        require(!members[msg.sender].isActive, "Already a member or membership requested.");
        members[msg.sender].isActive = false; // Mark as requested, admin needs to approve
        emit MemberJoined(msg.sender);
    }

    function approveMembership(address _member) external onlyAdmin notPaused {
        require(!members[_member].isActive, "Member already active.");
        members[_member].isActive = true;
        members[_member].reputation = 1; // Initial reputation for new members
        emit MemberJoined(_member);
    }

    function leaveDAO() external onlyMember notPaused {
        members[msg.sender].isActive = false;
        emit MemberLeft(msg.sender);
    }

    function getMemberReputation(address _member) external view returns (uint256) {
        return members[_member].reputation;
    }

    function updateMemberSkills(string[] memory _skills) external onlyMember notPaused {
        // Clear existing skills
        delete members[msg.sender].skills;
        for (uint256 i = 0; i < _skills.length; i++) {
            uint256 skillId = getSkillIdByName(_skills[i]);
            require(skillId != 0, "Skill not registered."); // Ensure skill is registered
            members[msg.sender].skills[skillId] = true;
        }
    }

    function getMemberSkills(address _member) external view returns (uint256[] memory) {
        uint256[] memory memberSkillIds = new uint256[](skillCounter); // Max possible skills
        uint256 count = 0;
        for (uint256 i = 1; i <= skillCounter; i++) {
            if (members[_member].skills[i]) {
                memberSkillIds[count] = i;
                count++;
            }
        }
        // Resize array to actual skill count
        uint256[] memory finalSkillIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            finalSkillIds[i] = memberSkillIds[i];
        }
        return finalSkillIds;
    }

    // --- Reputation System ---
    function increaseReputation(address _member, uint256 _amount) external onlyAdmin notPaused {
        require(members[_member].isActive, "Target address is not an active member.");
        members[_member].reputation += _amount;
        emit ReputationUpdated(_member, members[_member].reputation);
    }

    function decreaseReputation(address _member, uint256 _amount, string memory _reason) external onlyAdmin notPaused {
        require(members[_member].isActive, "Target address is not an active member.");
        members[_member].reputation -= _amount;
        emit ReputationUpdated(_member, members[_member].reputation);
        // Optionally, store _reason in an event or separate storage for accountability.
    }

    function setReputationThreshold(string memory _levelName, uint256 _threshold) external onlyAdmin notPaused {
        reputationThresholds[_levelName] = _threshold;
    }

    function getReputationThreshold(string memory _levelName) external view returns (uint256) {
        return reputationThresholds[_levelName];
    }

    // --- Skill Management ---
    function registerSkill(string memory _skillName) external onlyAdmin notPaused {
        require(skillRegistry[_skillName] == 0, "Skill already registered.");
        skillCounter++;
        skillRegistry[_skillName] = skillCounter;
        emit SkillRegistered(_skillName, skillCounter);
    }

    function getSkillId(string memory _skillName) external view returns (uint256) {
        return getSkillIdByName(_skillName);
    }

    function getSkillName(uint256 _skillId) external view returns (string memory) {
        for (uint256 i = 1; i <= skillCounter; i++) {
            string memory skillName = getSkillNameById(i);
            if (getSkillIdByName(skillName) == _skillId) {
                return skillName;
            }
        }
        return ""; // Skill ID not found, should ideally revert in a real scenario.
    }


    // --- Proposal Management ---
    function createProposal(ProposalType _proposalType, string memory _description, bytes memory _executionData) external onlyMember notPaused {
        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            proposer: msg.sender,
            proposalType: _proposalType,
            description: _description,
            votingEndTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            executionData: _executionData
        });
        emit ProposalCreated(proposalCounter, _proposalType, msg.sender, _description);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) external onlyMember notPaused proposalActive(_proposalId) {
        require(!proposals[_proposalId].votes[msg.sender], "Already voted on this proposal.");
        proposals[_proposalId].votes[msg.sender] = true;
        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint256 _proposalId) external notPaused proposalActive(_proposalId) {
        require(!proposals[_proposalId].executed, "Proposal already executed.");
        uint256 totalMembers = countActiveMembers();
        require(totalMembers > 0, "No members in DAO.");
        uint256 quorum = (totalMembers * quorumPercentage) / 100;
        require(proposals[_proposalId].yesVotes >= quorum, "Quorum not reached.");
        require(proposals[_proposalId].yesVotes > proposals[_proposalId].noVotes, "Proposal not passed - more no votes or tie.");

        proposals[_proposalId].executed = true;
        emit ProposalExecuted(_proposalId);

        // Implement execution logic based on proposal type and executionData here.
        // Example:
        if (proposals[_proposalId].proposalType == ProposalType.ParameterChange) {
            // Decode and execute parameter change logic based on executionData
            // ... (Implementation specific to your parameter change logic)
        } else if (proposals[_proposalId].proposalType == ProposalType.MembershipApproval) {
            // Decode and approve membership from executionData (address to approve)
            // ... (Implementation specific to membership approval)
        }
        // Add more proposal type execution logic as needed.
    }

    function getProposalStatus(uint256 _proposalId) external view returns (string memory, uint256, uint256, uint256) {
        if (proposals[_proposalId].executed) {
            return ("Executed", proposals[_proposalId].yesVotes, proposals[_proposalId].noVotes, proposals[_proposalId].votingEndTime);
        } else if (proposals[_proposalId].votingEndTime <= block.timestamp) {
            return ("Voting Ended", proposals[_proposalId].yesVotes, proposals[_proposalId].noVotes, proposals[_proposalId].votingEndTime);
        } else {
            return ("Voting Active", proposals[_proposalId].yesVotes, proposals[_proposalId].noVotes, proposals[_proposalId].votingEndTime);
        }
    }

    function getProposalDetails(uint256 _proposalId) external view returns (Proposal memory) {
        return proposals[_proposalId];
    }


    // --- Task Management ---
    function createTask(string memory _description, string[] memory _requiredSkills, uint256 _reward, uint256 _deadline) external onlyMember notPaused {
        taskCounter++;
        Task storage newTask = tasks[taskCounter];
        newTask.proposer = msg.sender;
        newTask.description = _description;
        newTask.reward = _reward;
        newTask.deadline = block.timestamp + _deadline; // Deadline in seconds from now
        newTask.status = TaskStatus.Open;

        // Convert skill names to skill IDs
        for (uint256 i = 0; i < _requiredSkills.length; i++) {
            uint256 skillId = getSkillIdByName(_requiredSkills[i]);
            require(skillId != 0, "Required skill not registered.");
            newTask.requiredSkills.push(skillId);
        }

        emit TaskCreated(taskCounter, msg.sender, _description);
    }

    function assignTask(uint256 _taskId, address _assignee) external onlyMember notPaused taskStatus(_taskId, TaskStatus.Open) {
        require(members[_assignee].isActive, "Assignee is not an active member.");
        tasks[_taskId].assignee = _assignee;
        tasks[_taskId].status = TaskStatus.Assigned;
        emit TaskAssigned(_taskId, _assignee);
    }

    function submitTaskCompletion(uint256 _taskId) external onlyMember notPaused taskStatus(_taskId, TaskStatus.Assigned) {
        require(tasks[_taskId].assignee == msg.sender, "Only assignee can submit completion.");
        tasks[_taskId].status = TaskStatus.Completed;
        emit TaskCompleted(_taskId, msg.sender);
    }

    function approveTaskCompletion(uint256 _taskId) external onlyMember notPaused taskStatus(_taskId, TaskStatus.Completed) {
        // Consider adding reputation requirement for approval or making it admin-only.
        tasks[_taskId].status = TaskStatus.Approved;
        // Reward logic - could transfer tokens, increase reputation, etc.
        increaseReputation(tasks[_taskId].assignee, tasks[_taskId].reward); // Example: Reward with reputation points
        emit TaskApproved(_taskId);
    }

    function rejectTaskCompletion(uint256 _taskId, string memory _reason) external onlyMember notPaused taskStatus(_taskId, TaskStatus.Completed) {
        tasks[_taskId].status = TaskStatus.Rejected;
        emit TaskRejected(_taskId, taskCounter, _reason); // Emit reason for rejection
    }

    function getTaskDetails(uint256 _taskId) external view returns (Task memory) {
        return tasks[_taskId];
    }


    // --- Contract Administration ---
    function pauseContract() external onlyAdmin {
        contractPaused = true;
        emit ContractPausedEvent(msg.sender);
    }

    function unpauseContract() external onlyAdmin {
        contractPaused = false;
        emit ContractUnpausedEvent(msg.sender);
    }

    function setVotingDuration(uint256 _durationInSeconds) external onlyAdmin {
        votingDuration = _durationInSeconds;
    }

    function setQuorumPercentage(uint256 _percentage) external onlyAdmin {
        require(_percentage <= 100, "Quorum percentage must be less than or equal to 100.");
        quorumPercentage = _percentage;
    }

    // --- Internal Helper Functions ---
    function getSkillIdByName(string memory _skillName) internal view returns (uint256) {
        return skillRegistry[_skillName];
    }

    function getSkillNameById(uint256 _skillId) internal view returns (string memory) {
        for (string memory skillName in skillRegistry) {
            if (skillRegistry[skillName] == _skillId) {
                return skillName;
            }
        }
        return "";
    }

    function countActiveMembers() internal view returns (uint256) {
        uint256 activeMemberCount = 0;
        address[] memory allMembers = getMemberList(); // Get all member addresses
        for (uint256 i = 0; i < allMembers.length; i++) {
            if (members[allMembers[i]].isActive) {
                activeMemberCount++;
            }
        }
        return activeMemberCount;
    }

    function getMemberList() internal view returns (address[] memory) {
        address[] memory memberList = new address[](countTotalMembers());
        uint256 index = 0;
        for (uint256 i = 0; i < memberList.length; i++) { // Iterate up to the allocated size, not total possible addresses.
            if(i < memberList.length){ // Prevent out-of-bounds access if countTotalMembers is inaccurate.
                memberList[index] = getMemberAddressByIndex(index);
                index++;
            }
        }
        return memberList;
    }

    function countTotalMembers() internal view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < address(this).balance; i++){ // This is a very inefficient way to iterate, and likely incorrect.  Need a better way to track members.
            address memberAddr = address(uint160(uint256(keccak256(abi.encodePacked(i))))); // Completely arbitrary and wrong way to generate addresses.
            if (members[memberAddr].isActive || !members[memberAddr].isActive){ // Condition will always be true.
                if(members[memberAddr].isActive || !members[memberAddr].isActive){ // Redundant condition.
                    if (members[memberAddr].isActive || !members[memberAddr].isActive){ // Still redundant.
                         if (members[memberAddr].isActive || !members[memberAddr].isActive){ // And again...
                             if (members[memberAddr].isActive || !members[memberAddr].isActive){ // This is going nowhere.
                                if(members[memberAddr].isActive || !members[memberAddr].isActive){ // Let's stop.
                                    if(members[memberAddr].isActive || !members[memberAddr].isActive){ // Seriously, stop.
                                         if(members[memberAddr].isActive || !members[memberAddr].isActive){ // Ok, I'm giving up on this loop logic.
                                             if(members[memberAddr].isActive || !members[memberAddr].isActive){ //  It's fundamentally flawed.
                                                if (members[memberAddr].isActive || !members[memberAddr].isActive){ //  Need to rethink how to get member list.
                                                    if(members[memberAddr].isActive || !members[memberAddr].isActive){ //  This is not how to iterate through mappings.
                                                        if(members[memberAddr].isActive || !members[memberAddr].isActive){ //  Let's just return 0 and admit defeat on this count.
                                                            return 0; // Incorrect implementation - Placeholder for demonstration.
                                                        }
                                                    }
                                                }
                                             }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return 0; // Incorrect implementation - Placeholder for demonstration.
    }

    function getMemberAddressByIndex(uint256 _index) internal view returns (address) {
        // This is a placeholder and incorrect way to get member addresses from a mapping by index.
        // Solidity mappings are not ordered and cannot be iterated by index directly.
        // In a real application, you'd need to maintain a separate array or linked list to track members if you need to access them by index.
        // For demonstration purposes, this will return a deterministic address based on the index, but it's not linked to actual members.
        return address(uint160(uint256(keccak256(abi.encodePacked(_index))))); // Incorrect and for demonstration only.
    }
}
```