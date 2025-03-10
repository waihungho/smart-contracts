```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Task & Reputation DAO
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Organization (DAO) focused on dynamic task management and a robust reputation system.
 *      This DAO allows members to propose, vote on, and execute tasks. It incorporates a skill-based task assignment,
 *      a reputation system based on task completion and contributions, and dynamic governance parameters.
 *      This contract aims to be a creative and advanced example, distinct from common open-source DAO implementations.
 *
 * Function Outline and Summary:
 *
 * 1.  initializeDAO(string _daoName, uint256 _initialVotingDuration, uint256 _initialQuorumPercentage):
 *     - Initializes the DAO with a name, default voting duration, and quorum percentage. Only callable once by the contract deployer.
 *
 * 2.  proposeTask(string _taskDescription, string[] memory _requiredSkills, uint256 _reward, uint256 _deadline):
 *     - Allows any DAO member to propose a new task with a description, required skills, reward, and deadline.
 *
 * 3.  voteOnTaskProposal(uint256 _proposalId, bool _support):
 *     - Allows DAO members to vote on a task proposal. Voting power is 1 member = 1 vote.
 *
 * 4.  executeTaskProposal(uint256 _proposalId):
 *     - Executes a task proposal if it has passed (reached quorum and majority support) and the deadline has not passed.
 *
 * 5.  assignTask(uint256 _taskId, address _memberAddress):
 *     - Allows the DAO owner (or designated role) to assign a task to a specific member. (Can be extended to auto-assignment based on skills)
 *
 * 6.  submitTask(uint256 _taskId):
 *     - Allows the assigned member to submit their completed task for review.
 *
 * 7.  approveTaskCompletion(uint256 _taskId):
 *     - Allows the DAO owner (or designated role/voters) to approve a submitted task as completed. Rewards the member and increases reputation.
 *
 * 8.  rejectTaskCompletion(uint256 _taskId, string _reason):
 *     - Allows the DAO owner (or designated role/voters) to reject a submitted task with a reason. Potentially decreases reputation.
 *
 * 9.  addMember(address _memberAddress):
 *     - Allows the DAO owner to add a new member to the DAO.
 *
 * 10. removeMember(address _memberAddress):
 *     - Allows the DAO owner to remove a member from the DAO. Requires a proposal and voting in a more advanced version.
 *
 * 11. getMemberReputation(address _memberAddress):
 *     - Returns the reputation score of a given DAO member.
 *
 * 12. increaseMemberReputation(address _memberAddress, uint256 _amount):
 *     - Allows the DAO owner (or designated role) to manually increase a member's reputation (e.g., for exceptional contributions).
 *
 * 13. decreaseMemberReputation(address _memberAddress, uint256 _amount):
 *     - Allows the DAO owner (or designated role) to manually decrease a member's reputation (e.g., for misconduct).
 *
 * 14. setVotingDuration(uint256 _newDuration):
 *     - Allows the DAO owner to change the default voting duration for proposals.
 *
 * 15. setQuorumPercentage(uint256 _newPercentage):
 *     - Allows the DAO owner to change the quorum percentage required for proposals to pass.
 *
 * 16. proposeGovernanceChange(string _description, bytes memory _calldata):
 *     - Allows members to propose changes to DAO governance parameters or contract functions via calldata execution on this contract itself.
 *
 * 17. voteOnGovernanceChange(uint256 _proposalId, bool _support):
 *     - Allows DAO members to vote on governance change proposals.
 *
 * 18. executeGovernanceChange(uint256 _proposalId):
 *     - Executes a passed governance change proposal by calling the target function with the provided calldata.
 *
 * 19. recordContribution(address _memberAddress, string _contributionDescription, uint256 _reputationReward):
 *     - Allows the DAO owner (or designated role) to manually reward reputation for general contributions outside of tasks.
 *
 * 20. getTaskDetails(uint256 _taskId):
 *     - Returns detailed information about a specific task, including status, description, assigned member, etc.
 *
 * 21. getProposalDetails(uint256 _proposalId):
 *     - Returns detailed information about a specific proposal (task or governance change).
 *
 * 22. getDAOInfo():
 *     - Returns general information about the DAO, such as name, voting duration, quorum, and member count.
 */
contract DynamicTaskReputationDAO {
    string public daoName;
    address public owner;
    uint256 public votingDuration; // Default voting duration in blocks
    uint256 public quorumPercentage; // Percentage of members required for quorum
    uint256 public nextProposalId;
    uint256 public nextTaskId;

    mapping(address => bool) public members;
    mapping(address => uint256) public memberReputation;

    struct Task {
        uint256 id;
        string description;
        string[] requiredSkills;
        uint256 reward;
        uint256 deadline; // Block number deadline
        TaskStatus status;
        address assignedMember;
        address proposer;
        uint256 proposalId; // Proposal ID for the task proposal that created this task
    }

    enum TaskStatus { Proposed, Open, Assigned, Submitted, Approved, Rejected, Completed }
    mapping(uint256 => Task) public tasks;

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        string description;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bytes calldataPayload; // For governance proposals
        uint256 taskId; // For task proposals, if applicable, link to task ID (though task itself is the outcome)
    }

    enum ProposalType { TaskProposal, GovernanceChange }
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => memberAddress => voted

    event DAOInitialized(string daoName, address owner);
    event MemberAdded(address memberAddress);
    event MemberRemoved(address memberAddress);
    event TaskProposed(uint256 taskId, uint256 proposalId, string description, address proposer);
    event TaskProposalVoted(uint256 proposalId, address voter, bool support);
    event TaskProposalExecuted(uint256 proposalId, uint256 taskId);
    event TaskAssigned(uint256 taskId, address assignedMember, address assigner);
    event TaskSubmitted(uint256 taskId, address submitter);
    event TaskApproved(uint256 taskId, address approver);
    event TaskRejected(uint256 taskId, uint256 proposalId, string reason, address rejecter);
    event ReputationIncreased(address memberAddress, uint256 amount, string reason);
    event ReputationDecreased(address memberAddress, uint256 amount, string reason);
    event VotingDurationChanged(uint256 newDuration, address changer);
    event QuorumPercentageChanged(uint256 newPercentage, address changer);
    event GovernanceChangeProposed(uint256 proposalId, string description, address proposer);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool support);
    event GovernanceProposalExecuted(uint256 proposalId);
    event ContributionRecorded(address memberAddress, string description, uint256 reputationReward, address recorder);


    modifier onlyOwner() {
        require(msg.sender == owner, "Only DAO owner can perform this action");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only DAO members can perform this action");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(proposals[_proposalId].id == _proposalId, "Invalid proposal ID");
        _;
    }

    modifier validTask(uint256 _taskId) {
        require(tasks[_taskId].id == _taskId, "Invalid task ID");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!proposals[_proposalId].executed, "Proposal already executed");
        _;
    }

    modifier votingPeriodActive(uint256 _proposalId) {
        require(block.number >= proposals[_proposalId].startTime && block.number <= proposals[_proposalId].endTime, "Voting period is not active");
        _;
    }

    modifier taskStatus(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Task status is not as expected");
        _;
    }


    constructor() {
        owner = msg.sender;
        nextProposalId = 1;
        nextTaskId = 1;
    }

    function initializeDAO(string memory _daoName, uint256 _initialVotingDuration, uint256 _initialQuorumPercentage) public onlyOwner {
        require(bytes(daoName).length == 0, "DAO already initialized"); // Prevent re-initialization
        daoName = _daoName;
        votingDuration = _initialVotingDuration;
        quorumPercentage = _initialQuorumPercentage;
        emit DAOInitialized(_daoName, owner);
    }

    function proposeTask(string memory _taskDescription, string[] memory _requiredSkills, uint256 _reward, uint256 _deadline) public onlyMember {
        require(bytes(_taskDescription).length > 0, "Task description cannot be empty");
        require(_reward > 0, "Task reward must be positive");
        require(_deadline > block.number, "Task deadline must be in the future");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.TaskProposal,
            description: _taskDescription,
            proposer: msg.sender,
            startTime: block.number,
            endTime: block.number + votingDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            calldataPayload: "", // Not used for task proposals
            taskId: 0 // Not yet a task, proposal first
        });

        emit GovernanceChangeProposed(proposalId, _taskDescription, msg.sender); // Reusing event for proposal creation, can make specific event if needed

        uint256 taskId = nextTaskId++;
        tasks[taskId] = Task({
            id: taskId,
            description: _taskDescription,
            requiredSkills: _requiredSkills,
            reward: _reward,
            deadline: _deadline,
            status: TaskStatus.Proposed,
            assignedMember: address(0),
            proposer: msg.sender,
            proposalId: proposalId
        });

        emit TaskProposed(taskId, proposalId, _taskDescription, msg.sender);
    }

    function voteOnTaskProposal(uint256 _proposalId, bool _support) public onlyMember validProposal(_proposalId) proposalNotExecuted(_proposalId) votingPeriodActive(_proposalId) {
        require(!proposalVotes[_proposalId][msg.sender], "Member has already voted on this proposal");
        proposalVotes[_proposalId][msg.sender] = true;

        if (_support) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit TaskProposalVoted(_proposalId, msg.sender, _support);
    }

    function executeTaskProposal(uint256 _proposalId) public validProposal(_proposalId) proposalNotExecuted(_proposalId) {
        require(block.number > proposals[_proposalId].endTime, "Voting period is still active");

        uint256 totalMembers = 0;
        for (uint i = 0; i < membersArray.length; i++) { // Assuming membersArray is maintained for efficient member count
            if (members[membersArray[i]]) {
                totalMembers++;
            }
        }
        require(totalMembers > 0, "No members in DAO to calculate quorum"); // Avoid division by zero

        uint256 quorumThreshold = (totalMembers * quorumPercentage) / 100;
        require((proposals[_proposalId].votesFor + proposals[_proposalId].votesAgainst) >= quorumThreshold, "Proposal does not meet quorum");
        require(proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst, "Proposal not passed - not enough votes in favor");

        uint256 taskId = tasks[proposals[_proposalId].taskId].id; // Get taskId from proposal association
        require(tasks[taskId].proposalId == _proposalId, "Task and Proposal ID mismatch"); // Sanity check
        require(tasks[taskId].status == TaskStatus.Proposed, "Task status is not Proposed");
        require(tasks[taskId].deadline > block.number, "Task deadline has passed");

        tasks[taskId].status = TaskStatus.Open; // Task is now open for assignment
        proposals[_proposalId].executed = true;
        emit TaskProposalExecuted(_proposalId, taskId);
    }

    function assignTask(uint256 _taskId, address _memberAddress) public onlyOwner validTask(_taskId) taskStatus(_taskId, TaskStatus.Open) {
        require(members[_memberAddress], "Address is not a DAO member");
        require(tasks[_taskId].assignedMember == address(0), "Task already assigned");

        tasks[_taskId].status = TaskStatus.Assigned;
        tasks[_taskId].assignedMember = _memberAddress;
        emit TaskAssigned(_taskId, _memberAddress, msg.sender);
    }

    function submitTask(uint256 _taskId) public onlyMember validTask(_taskId) taskStatus(_taskId, TaskStatus.Assigned) {
        require(tasks[_taskId].assignedMember == msg.sender, "Only assigned member can submit the task");
        tasks[_taskId].status = TaskStatus.Submitted;
        emit TaskSubmitted(_taskId, msg.sender);
    }

    function approveTaskCompletion(uint256 _taskId) public onlyOwner validTask(_taskId) taskStatus(_taskId, TaskStatus.Submitted) {
        address assignedMember = tasks[_taskId].assignedMember;
        uint256 reward = tasks[_taskId].reward;

        tasks[_taskId].status = TaskStatus.Approved;
        memberReputation[assignedMember] += reward; // Reputation increase is directly tied to reward for simplicity
        emit TaskApproved(_taskId, msg.sender);
        emit ReputationIncreased(assignedMember, reward, "Task completion reward");

        // In a real-world scenario, you would transfer the reward tokens/ETH here.
        // For simplicity, this example only focuses on reputation and status changes.
        tasks[_taskId].status = TaskStatus.Completed; // Mark as completed after approval and reward
    }

    function rejectTaskCompletion(uint256 _taskId, string memory _reason) public onlyOwner validTask(_taskId) taskStatus(_taskId, TaskStatus.Submitted) {
        tasks[_taskId].status = TaskStatus.Rejected;
        emit TaskRejected(_taskId, tasks[_taskId].proposalId, _reason, msg.sender);
        // Potentially decrease reputation for rejected tasks (optional and can be implemented with more nuanced logic)
        // memberReputation[tasks[_taskId].assignedMember] -= 10; // Example reputation decrease
        // emit ReputationDecreased(tasks[_taskId].assignedMember, 10, "Task rejected - quality issue");
    }


    // --- Member Management ---
    address[] public membersArray; // Maintain an array for easier iteration and member count

    function addMember(address _memberAddress) public onlyOwner {
        require(!members[_memberAddress], "Address is already a member");
        members[_memberAddress] = true;
        memberReputation[_memberAddress] = 0; // Initialize reputation
        membersArray.push(_memberAddress);
        emit MemberAdded(_memberAddress);
    }

    function removeMember(address _memberAddress) public onlyOwner {
        require(members[_memberAddress], "Address is not a member");
        delete members[_memberAddress];
        // Remove from membersArray (more complex, can be optimized if needed in a real app)
        for (uint i = 0; i < membersArray.length; i++) {
            if (membersArray[i] == _memberAddress) {
                membersArray[i] = membersArray[membersArray.length - 1];
                membersArray.pop();
                break;
            }
        }
        emit MemberRemoved(_memberAddress);
    }

    function getMemberReputation(address _memberAddress) public view returns (uint256) {
        return memberReputation[_memberAddress];
    }

    function increaseMemberReputation(address _memberAddress, uint256 _amount) public onlyOwner {
        memberReputation[_memberAddress] += _amount;
        emit ReputationIncreased(_memberAddress, _amount, "Manual reputation increase by owner");
    }

    function decreaseMemberReputation(address _memberAddress, uint256 _amount) public onlyOwner {
        memberReputation[_memberAddress] -= _amount;
        emit ReputationDecreased(_memberAddress, _amount, "Manual reputation decrease by owner");
    }


    // --- Governance Parameter Changes ---
    function setVotingDuration(uint256 _newDuration) public onlyOwner {
        votingDuration = _newDuration;
        emit VotingDurationChanged(_newDuration, msg.sender);
    }

    function setQuorumPercentage(uint256 _newPercentage) public onlyOwner {
        require(_newPercentage <= 100, "Quorum percentage cannot exceed 100");
        quorumPercentage = _newPercentage;
        emit QuorumPercentageChanged(_newPercentage, msg.sender);
    }


    // --- Governance Change Proposals ---
    function proposeGovernanceChange(string memory _description, bytes memory _calldata) public onlyMember {
        require(bytes(_description).length > 0, "Governance change description cannot be empty");
        require(_calldata.length > 0, "Governance change calldata cannot be empty");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.GovernanceChange,
            description: _description,
            proposer: msg.sender,
            startTime: block.number,
            endTime: block.number + votingDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            calldataPayload: _calldata,
            taskId: 0 // Not a task proposal
        });
        emit GovernanceChangeProposed(proposalId, _description, msg.sender);
    }

    function voteOnGovernanceChange(uint256 _proposalId, bool _support) public onlyMember validProposal(_proposalId) proposalNotExecuted(_proposalId) votingPeriodActive(_proposalId) {
        require(!proposalVotes[_proposalId][msg.sender], "Member has already voted on this proposal");
        proposalVotes[_proposalId][msg.sender] = true;

        if (_support) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _support);
    }

    function executeGovernanceChange(uint256 _proposalId) public validProposal(_proposalId) proposalNotExecuted(_proposalId) {
        require(block.number > proposals[_proposalId].endTime, "Voting period is still active");

        uint256 totalMembers = 0;
        for (uint i = 0; i < membersArray.length; i++) {
            if (members[membersArray[i]]) {
                totalMembers++;
            }
        }
        require(totalMembers > 0, "No members in DAO to calculate quorum"); // Avoid division by zero

        uint256 quorumThreshold = (totalMembers * quorumPercentage) / 100;
        require((proposals[_proposalId].votesFor + proposals[_proposalId].votesAgainst) >= quorumThreshold, "Proposal does not meet quorum");
        require(proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst, "Proposal not passed - not enough votes in favor");

        (bool success, ) = address(this).delegatecall(proposals[_proposalId].calldataPayload); // Execute governance change on this contract
        require(success, "Governance change execution failed");

        proposals[_proposalId].executed = true;
        emit GovernanceProposalExecuted(_proposalId);
    }


    // --- Reputation for General Contributions ---
    function recordContribution(address _memberAddress, string memory _contributionDescription, uint256 _reputationReward) public onlyOwner {
        require(members[_memberAddress], "Address is not a DAO member");
        require(_reputationReward > 0, "Reputation reward must be positive");
        memberReputation[_memberAddress] += _reputationReward;
        emit ContributionRecorded(_memberAddress, _contributionDescription, _reputationReward, msg.sender);
    }


    // --- Getter Functions ---
    function getTaskDetails(uint256 _taskId) public view validTask(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    function getProposalDetails(uint256 _proposalId) public view validProposal(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function getDAOInfo() public view returns (string memory, uint256, uint256, uint256) {
        return (daoName, votingDuration, quorumPercentage, membersArray.length);
    }
}
```