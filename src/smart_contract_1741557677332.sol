```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Task DAO with Reputation and Skill-Based Task Assignment
 * @author Bard (AI Assistant)
 * @dev A Decentralized Autonomous Organization (DAO) smart contract that focuses on dynamic task management,
 * reputation building, and skill-based task assignment. This contract aims to create a vibrant and efficient
 * community-driven organization where members can contribute, earn reputation, and participate in governance.
 *
 * ## Contract Outline:
 *
 * **1. Membership & Roles:**
 *    - `joinDAO()`: Allow users to request membership.
 *    - `approveMembership()`: Admin/Council approves membership requests.
 *    - `revokeMembership()`: Admin/Council revokes membership.
 *    - `isMember()`: Check if an address is a member.
 *    - `isAdmin()`: Check if an address is an admin.
 *    - `isCouncilMember()`: Check if an address is a council member.
 *    - `addCouncilMember()`: Admin adds a council member.
 *    - `removeCouncilMember()`: Admin removes a council member.
 *
 * **2. Skill Management:**
 *    - `addSkill()`: Admin/Council adds a new skill to the DAO's skill registry.
 *    - `updateSkill()`: Admin/Council updates an existing skill's information.
 *    - `getUserSkills()`: View skills associated with a member.
 *    - `addUserSkill()`: Members can claim skills they possess.
 *    - `removeUserSkill()`: Members can remove skills from their profile.
 *
 * **3. Task Management:**
 *    - `createTaskProposal()`: Members propose new tasks with details, reward, and required skills.
 *    - `voteOnTaskProposal()`: Members vote on task proposals.
 *    - `executeTaskProposal()`: Executes a passed task proposal, creating a task.
 *    - `assignTask()`: Council/Task proposer assigns a task to a member with matching skills.
 *    - `submitTask()`: Member submits their work for a task.
 *    - `reviewTaskSubmission()`: Council/Task proposer reviews submitted work.
 *    - `approveTaskCompletion()`: Council/Task proposer approves task completion and rewards the contributor.
 *    - `disputeTask()`: Member can dispute if task completion is unfairly rejected.
 *    - `resolveTaskDispute()`: Council/Admin resolves task disputes.
 *    - `getTaskDetails()`: View details of a specific task.
 *
 * **4. Reputation System:**
 *    - `getReputation()`: View a member's reputation score.
 *    - `increaseReputation()`: Council/Admin increases a member's reputation (e.g., for exceptional contributions).
 *    - `decreaseReputation()`: Council/Admin decreases a member's reputation (e.g., for misconduct).
 *
 * **5. Governance & Settings:**
 *    - `setProposalQuorum()`: Admin sets the quorum for task proposal voting.
 *    - `setVotingPeriod()`: Admin sets the voting period for task proposals.
 *    - `changeAdmin()`: Admin can transfer admin rights.
 *
 * ## Function Summary:
 *
 * - `joinDAO()`: Allows anyone to request membership in the DAO.
 * - `approveMembership(address _member)`: Admin or Council approves a pending membership request.
 * - `revokeMembership(address _member)`: Admin or Council revokes a member's membership.
 * - `isMember(address _account)`: Checks if an address is a member of the DAO.
 * - `isAdmin(address _account)`: Checks if an address is the admin of the DAO.
 * - `isCouncilMember(address _account)`: Checks if an address is a council member.
 * - `addCouncilMember(address _newCouncilMember)`: Admin adds a new address as a council member.
 * - `removeCouncilMember(address _councilMember)`: Admin removes an address from the council members.
 * - `addSkill(string memory _skillName, string memory _skillDescription)`: Admin or Council adds a new skill to the DAO's skill registry.
 * - `updateSkill(uint256 _skillId, string memory _newDescription)`: Admin or Council updates the description of an existing skill.
 * - `getUserSkills(address _member)`: Retrieves the list of skills associated with a DAO member.
 * - `addUserSkill(uint256 _skillId)`: Members can claim they possess a skill from the DAO's registry.
 * - `removeUserSkill(uint256 _skillId)`: Members can remove a skill from their claimed skills.
 * - `createTaskProposal(string memory _title, string memory _description, uint256 _reward, uint256[] memory _requiredSkillIds)`: Members propose a new task with title, description, reward, and required skills.
 * - `voteOnTaskProposal(uint256 _proposalId, bool _vote)`: Members vote for or against a task proposal.
 * - `executeTaskProposal(uint256 _proposalId)`: Executes a passed task proposal, creating a task.
 * - `assignTask(uint256 _taskId, address _assignee)`: Council or task proposer assigns a task to a member (ideally with matching skills).
 * - `submitTask(uint256 _taskId, string memory _submissionDetails)`: Assigned member submits their work for a task.
 * - `reviewTaskSubmission(uint256 _taskId, bool _isApproved, string memory _reviewComment)`: Council or task proposer reviews a task submission, approves or rejects it, and provides comments.
 * - `approveTaskCompletion(uint256 _taskId)`: Approves a task as completed and rewards the assigned member.
 * - `disputeTask(uint256 _taskId, string memory _disputeReason)`: Member disputes a rejected task submission.
 * - `resolveTaskDispute(uint256 _taskId, bool _resolveInFavorOfMember, string memory _resolutionComment)`: Council or Admin resolves a task dispute.
 * - `getTaskDetails(uint256 _taskId)`: Retrieves detailed information about a specific task.
 * - `getReputation(address _member)`: Retrieves the reputation score of a member.
 * - `increaseReputation(address _member, uint256 _amount, string memory _reason)`: Council or Admin increases a member's reputation with a reason.
 * - `decreaseReputation(address _member, uint256 _amount, string memory _reason)`: Council or Admin decreases a member's reputation with a reason.
 * - `setProposalQuorum(uint256 _newQuorum)`: Admin sets the required quorum percentage for task proposal voting.
 * - `setVotingPeriod(uint256 _newVotingPeriod)`: Admin sets the voting period for task proposals in blocks.
 * - `changeAdmin(address _newAdmin)`: Admin transfers the admin role to a new address.
 */

contract DynamicTaskDAO {
    // **** Enums and Structs ****

    enum ProposalStatus { Pending, Active, Passed, Rejected, Executed, Cancelled }
    enum TaskStatus { Open, Assigned, Submitted, UnderReview, Completed, Rejected, Disputed, DisputeResolved }

    struct Member {
        address memberAddress;
        uint256 reputation;
        bool isApproved;
        uint256 joinTimestamp;
    }

    struct Skill {
        uint256 skillId;
        string skillName;
        string skillDescription;
    }

    struct TaskProposal {
        uint256 proposalId;
        address proposer;
        string title;
        string description;
        uint256 reward;
        uint256[] requiredSkillIds;
        ProposalStatus status;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) votes; // Track who voted and their vote
    }

    struct Task {
        uint256 taskId;
        uint256 proposalId; // Link back to the proposal that created this task
        string title;
        string description;
        uint256 reward;
        uint256[] requiredSkillIds;
        TaskStatus status;
        address assignee;
        string submissionDetails;
        string reviewComment;
        string disputeReason;
        string resolutionComment;
    }

    // **** State Variables ****

    address public admin;
    mapping(address => bool) public councilMembers;
    mapping(address => Member) public members;
    address[] public memberList;
    uint256 public memberCount;

    Skill[] public skills;
    uint256 public skillIdCounter;
    mapping(address => uint256[]) public userSkills; // Member address to array of skillIds

    TaskProposal[] public proposals;
    uint256 public proposalIdCounter;
    uint256 public proposalQuorumPercentage = 50; // Default quorum: 50%
    uint256 public votingPeriodBlocks = 100; // Default voting period: 100 blocks

    Task[] public tasks;
    uint256 public taskIdCounter;

    // **** Events ****

    event MembershipRequested(address indexed memberAddress);
    event MembershipApproved(address indexed memberAddress);
    event MembershipRevoked(address indexed memberAddress);
    event CouncilMemberAdded(address indexed councilMember);
    event CouncilMemberRemoved(address indexed councilMember);
    event SkillAdded(uint256 skillId, string skillName);
    event SkillUpdated(uint256 skillId, string newDescription);
    event UserSkillAdded(address indexed memberAddress, uint256 skillId);
    event UserSkillRemoved(address indexed memberAddress, uint256 skillId);
    event TaskProposalCreated(uint256 proposalId, address proposer, string title);
    event TaskProposalVoted(uint256 proposalId, address voter, bool vote);
    event TaskProposalExecuted(uint256 proposalId, uint256 taskId);
    event TaskAssigned(uint256 taskId, address assignee);
    event TaskSubmitted(uint256 taskId, address submitter);
    event TaskSubmissionReviewed(uint256 taskId, bool isApproved, string reviewComment);
    event TaskCompleted(uint256 taskId, address completer, uint256 reward);
    event TaskDisputed(uint256 taskId, address disputer, string reason);
    event TaskDisputeResolved(uint256 taskId, bool inFavorOfMember, string resolutionComment);
    event ReputationIncreased(address indexed memberAddress, uint256 amount, string reason);
    event ReputationDecreased(address indexed memberAddress, uint256 amount, string reason);
    event ProposalQuorumSet(uint256 newQuorum);
    event VotingPeriodSet(uint256 newVotingPeriod);
    event AdminChanged(address indexed newAdmin);


    // **** Modifiers ****

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyCouncil() {
        require(councilMembers[msg.sender] || msg.sender == admin, "Only council or admin can perform this action");
        _;
    }

    modifier onlyMember() {
        require(isMember(msg.sender), "Only members can perform this action");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId < proposals.length, "Invalid proposal ID");
        _;
    }

    modifier validTask(uint256 _taskId) {
        require(_taskId < tasks.length, "Invalid task ID");
        _;
    }

    modifier validSkill(uint256 _skillId) {
        require(_skillId < skills.length, "Invalid skill ID");
        _;
    }

    modifier proposalInStatus(uint256 _proposalId, ProposalStatus _status) {
        require(proposals[_proposalId].status == _status, "Proposal is not in the required status");
        _;
    }

    modifier taskInStatus(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Task is not in the required status");
        _;
    }

    modifier onlyTaskAssignee(uint256 _taskId) {
        require(tasks[_taskId].assignee == msg.sender, "Only the assigned member can perform this action");
        _;
    }

    modifier onlyTaskProposerOrCouncil(uint256 _taskId) {
        uint256 proposalId = tasks[_taskId].proposalId;
        require(proposals[proposalId].proposer == msg.sender || councilMembers[msg.sender] || msg.sender == admin, "Only proposer, council, or admin can perform this action");
        _;
    }

    // **** Constructor ****

    constructor() {
        admin = msg.sender;
    }

    // **** 1. Membership & Roles ****

    function joinDAO() external {
        require(!isMember(msg.sender), "Already a member or membership pending");
        members[msg.sender] = Member({
            memberAddress: msg.sender,
            reputation: 0,
            isApproved: false,
            joinTimestamp: block.timestamp
        });
        memberList.push(msg.sender);
        memberCount++;
        emit MembershipRequested(msg.sender);
    }

    function approveMembership(address _member) external onlyCouncil {
        require(!members[_member].isApproved, "Member already approved");
        members[_member].isApproved = true;
        emit MembershipApproved(_member);
    }

    function revokeMembership(address _member) external onlyCouncil {
        require(members[_member].isApproved, "Member is not approved or not a member");
        members[_member].isApproved = false;
        emit MembershipRevoked(_member);
    }

    function isMember(address _account) public view returns (bool) {
        return members[_account].isApproved;
    }

    function isAdmin(address _account) public view returns (bool) {
        return _account == admin;
    }

    function isCouncilMember(address _account) public view returns (bool) {
        return councilMembers[_account];
    }

    function addCouncilMember(address _newCouncilMember) external onlyAdmin {
        require(!councilMembers[_newCouncilMember], "Address is already a council member");
        councilMembers[_newCouncilMember] = true;
        emit CouncilMemberAdded(_newCouncilMember);
    }

    function removeCouncilMember(address _councilMember) external onlyAdmin {
        require(councilMembers[_councilMember], "Address is not a council member");
        require(_councilMember != admin, "Cannot remove admin from council"); // Prevent accidentally removing admin if they are also in council
        delete councilMembers[_councilMember];
        emit CouncilMemberRemoved(_councilMember);
    }

    // **** 2. Skill Management ****

    function addSkill(string memory _skillName, string memory _skillDescription) external onlyCouncil {
        skills.push(Skill({
            skillId: skillIdCounter,
            skillName: _skillName,
            skillDescription: _skillDescription
        }));
        emit SkillAdded(skillIdCounter, _skillName);
        skillIdCounter++;
    }

    function updateSkill(uint256 _skillId, string memory _newDescription) external onlyCouncil validSkill(_skillId) {
        skills[_skillId].skillDescription = _newDescription;
        emit SkillUpdated(_skillId, _newDescription);
    }

    function getUserSkills(address _member) external view returns (uint256[] memory) {
        return userSkills[_member];
    }

    function addUserSkill(uint256 _skillId) external onlyMember validSkill(_skillId) {
        bool skillAlreadyAdded = false;
        for (uint256 i = 0; i < userSkills[msg.sender].length; i++) {
            if (userSkills[msg.sender][i] == _skillId) {
                skillAlreadyAdded = true;
                break;
            }
        }
        require(!skillAlreadyAdded, "Skill already added to user profile");
        userSkills[msg.sender].push(_skillId);
        emit UserSkillAdded(msg.sender, _skillId);
    }

    function removeUserSkill(uint256 _skillId) external onlyMember validSkill(_skillId) {
        for (uint256 i = 0; i < userSkills[msg.sender].length; i++) {
            if (userSkills[msg.sender][i] == _skillId) {
                // Remove skill by swapping with last element and popping
                userSkills[msg.sender][i] = userSkills[msg.sender][userSkills[msg.sender].length - 1];
                userSkills[msg.sender].pop();
                emit UserSkillRemoved(msg.sender, _skillId);
                return;
            }
        }
        revert("Skill not found in user profile");
    }

    // **** 3. Task Management ****

    function createTaskProposal(
        string memory _title,
        string memory _description,
        uint256 _reward,
        uint256[] memory _requiredSkillIds
    ) external onlyMember {
        require(_reward > 0, "Reward must be greater than 0");
        for (uint256 skillId of _requiredSkillIds) {
            require(skillId < skills.length, "Invalid skill ID in required skills");
        }

        proposals.push(TaskProposal({
            proposalId: proposalIdCounter,
            proposer: msg.sender,
            title: _title,
            description: _description,
            reward: _reward,
            requiredSkillIds: _requiredSkillIds,
            status: ProposalStatus.Pending,
            votingStartTime: 0,
            votingEndTime: 0,
            yesVotes: 0,
            noVotes: 0,
            votes: mapping(address => bool)()
        }));

        emit TaskProposalCreated(proposalIdCounter, msg.sender, _title);
        proposalIdCounter++;
    }

    function voteOnTaskProposal(uint256 _proposalId, bool _vote) external onlyMember validProposal(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Active) {
        require(!proposals[_proposalId].votes[msg.sender], "Already voted on this proposal");

        proposals[_proposalId].votes[msg.sender] = true;
        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit TaskProposalVoted(_proposalId, msg.sender, _vote);

        // Check if voting period ended and quorum reached (basic auto-execution example)
        if (block.number >= proposals[_proposalId].votingEndTime) {
            _finalizeProposal(_proposalId);
        }
    }

    function executeTaskProposal(uint256 _proposalId) external onlyCouncil validProposal(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Passed) {
        proposals[_proposalId].status = ProposalStatus.Executed;
        uint256 taskId = taskIdCounter;
        tasks.push(Task({
            taskId: taskId,
            proposalId: _proposalId,
            title: proposals[_proposalId].title,
            description: proposals[_proposalId].description,
            reward: proposals[_proposalId].reward,
            requiredSkillIds: proposals[_proposalId].requiredSkillIds,
            status: TaskStatus.Open,
            assignee: address(0),
            submissionDetails: "",
            reviewComment: "",
            disputeReason: "",
            resolutionComment: ""
        }));
        emit TaskProposalExecuted(_proposalId, taskId);
        taskIdCounter++;
    }

    function assignTask(uint256 _taskId, address _assignee) external onlyTaskProposerOrCouncil(_taskId) validTask(_taskId) taskInStatus(_taskId, TaskStatus.Open) {
        require(isMember(_assignee), "Assignee must be a DAO member");
        // Optional: Implement skill-based assignment logic here.
        // For simplicity, we are skipping explicit skill matching in this version.
        tasks[_taskId].assignee = _assignee;
        tasks[_taskId].status = TaskStatus.Assigned;
        emit TaskAssigned(_taskId, _assignee);
    }

    function submitTask(uint256 _taskId, string memory _submissionDetails) external onlyTaskAssignee(_taskId) validTask(_taskId) taskInStatus(_taskId, TaskStatus.Assigned) {
        tasks[_taskId].submissionDetails = _submissionDetails;
        tasks[_taskId].status = TaskStatus.Submitted;
        emit TaskSubmitted(_taskId, msg.sender);
    }

    function reviewTaskSubmission(uint256 _taskId, bool _isApproved, string memory _reviewComment) external onlyTaskProposerOrCouncil(_taskId) validTask(_taskId) taskInStatus(_taskId, TaskStatus.Submitted) {
        tasks[_taskId].reviewComment = _reviewComment;
        if (_isApproved) {
            tasks[_taskId].status = TaskStatus.UnderReview; // Change status to UnderReview for final approval function
        } else {
            tasks[_taskId].status = TaskStatus.Rejected;
        }
        emit TaskSubmissionReviewed(_taskId, _isApproved, _reviewComment);
    }

    function approveTaskCompletion(uint256 _taskId) external onlyTaskProposerOrCouncil(_taskId) validTask(_taskId) taskInStatus(_taskId, TaskStatus.UnderReview) {
        tasks[_taskId].status = TaskStatus.Completed;
        payable(tasks[_taskId].assignee).transfer(tasks[_taskId].reward); // Reward the assignee
        emit TaskCompleted(_taskId, tasks[_taskId].assignee, tasks[_taskId].reward);
    }

    function disputeTask(uint256 _taskId, string memory _disputeReason) external onlyTaskAssignee(_taskId) validTask(_taskId) taskInStatus(_taskId, TaskStatus.Rejected) {
        tasks[_taskId].status = TaskStatus.Disputed;
        tasks[_taskId].disputeReason = _disputeReason;
        emit TaskDisputed(_taskId, msg.sender, _disputeReason);
    }

    function resolveTaskDispute(uint256 _taskId, bool _resolveInFavorOfMember, string memory _resolutionComment) external onlyCouncil validTask(_taskId) taskInStatus(_taskId, TaskStatus.Disputed) {
        tasks[_taskId].status = TaskStatus.DisputeResolved;
        tasks[_taskId].resolutionComment = _resolutionComment;
        if (_resolveInFavorOfMember) {
            tasks[_taskId].status = TaskStatus.Completed; // Consider task completed if dispute resolved in member's favor
            payable(tasks[_taskId].assignee).transfer(tasks[_taskId].reward); // Reward the assignee
            emit TaskCompleted(_taskId, tasks[_taskId].assignee, tasks[_taskId].reward);
        } else {
            tasks[_taskId].status = TaskStatus.Rejected; // Task remains rejected if dispute not resolved in member's favor
        }
        emit TaskDisputeResolved(_taskId, _resolveInFavorOfMember, _resolutionComment);
    }

    function getTaskDetails(uint256 _taskId) external view validTask(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    // **** 4. Reputation System ****

    function getReputation(address _member) external view returns (uint256) {
        return members[_member].reputation;
    }

    function increaseReputation(address _member, uint256 _amount, string memory _reason) external onlyCouncil isMember(_member) {
        members[_member].reputation += _amount;
        emit ReputationIncreased(_member, _amount, _reason);
    }

    function decreaseReputation(address _member, uint256 _amount, string memory _reason) external onlyCouncil isMember(_member) {
        require(members[_member].reputation >= _amount, "Reputation cannot be negative");
        members[_member].reputation -= _amount;
        emit ReputationDecreased(_member, _amount, _reason);
    }

    // **** 5. Governance & Settings ****

    function setProposalQuorum(uint256 _newQuorum) external onlyAdmin {
        require(_newQuorum <= 100, "Quorum must be between 0 and 100");
        proposalQuorumPercentage = _newQuorum;
        emit ProposalQuorumSet(_newQuorum);
    }

    function setVotingPeriod(uint256 _newVotingPeriod) external onlyAdmin {
        votingPeriodBlocks = _newVotingPeriod;
        emit VotingPeriodSet(_newVotingPeriod);
    }

    function changeAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid admin address");
        admin = _newAdmin;
        councilMembers[admin] = true; // Ensure new admin is also a council member
        emit AdminChanged(_newAdmin);
    }

    // **** Internal Functions ****

    function _finalizeProposal(uint256 _proposalId) internal validProposal(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Active) {
        uint256 totalVotes = proposals[_proposalId].yesVotes + proposals[_proposalId].noVotes;
        uint256 quorumReached = (totalVotes * 100) / memberCount; // Calculate quorum percentage
        if (quorumReached >= proposalQuorumPercentage && proposals[_proposalId].yesVotes > proposals[_proposalId].noVotes) {
            proposals[_proposalId].status = ProposalStatus.Passed;
            executeTaskProposal(_proposalId); // Auto execute upon passing
        } else {
            proposals[_proposalId].status = ProposalStatus.Rejected;
        }
    }

    // Function to start voting on a proposal - Made public so anyone (or a bot) can start the voting process after proposal creation
    function startProposalVoting(uint256 _proposalId) external validProposal(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Pending) {
        proposals[_proposalId].status = ProposalStatus.Active;
        proposals[_proposalId].votingStartTime = block.number;
        proposals[_proposalId].votingEndTime = block.number + votingPeriodBlocks;
    }

    // Fallback function to receive Ether for task rewards (optional, for direct contract funding)
    receive() external payable {}
}
```