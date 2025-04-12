```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Skill-Based Dynamic DAO with Reputation & Task Management
 * @author Bard (Example Smart Contract - Not for Production)
 * @dev This contract implements a Decentralized Autonomous Organization (DAO) with advanced features focusing on skill-based roles, dynamic governance, reputation system, and task management.
 * It's designed to be creative and trendy, incorporating concepts beyond basic DAO functionalities.
 *
 * **Outline and Function Summary:**
 *
 * **I. Core DAO Structure & Membership:**
 *    1. `requestMembership(string memory _profile)`: Allows an address to request membership with a profile description.
 *    2. `approveMembership(address _member)`:  Admin/Role-based function to approve a pending membership request.
 *    3. `rejectMembership(address _member)`: Admin/Role-based function to reject a pending membership request.
 *    4. `revokeMembership(address _member)`: Admin/Role-based function to revoke membership from an existing member.
 *    5. `getMemberProfile(address _member)`:  Retrieves the profile description of a member.
 *    6. `isMember(address _account)`: Checks if an address is a member of the DAO.
 *
 * **II. Skill-Based Roles & Permissions:**
 *    7. `defineRole(string memory _roleName, string memory _description)`: Defines a new skill-based role within the DAO (e.g., Developer, Designer, Marketer).
 *    8. `assignRole(address _member, uint256 _roleId)`: Assigns a defined role to a member, granting specific permissions.
 *    9. `removeRole(address _member, uint256 _roleId)`: Removes a role from a member.
 *    10. `getMemberRoles(address _member)`: Retrieves the list of roles assigned to a member.
 *    11. `getRoleDetails(uint256 _roleId)`: Retrieves details of a specific role.
 *    12. `hasRole(address _account, uint256 _roleId)`: Checks if an address has a specific role.
 *
 * **III. Dynamic Governance & Proposals:**
 *    13. `submitGovernanceProposal(string memory _title, string memory _description, bytes memory _calldata, address _target)`: Members can submit proposals to change governance parameters or execute contract functions.
 *    14. `voteOnProposal(uint256 _proposalId, bool _support)`: Members can vote on active governance proposals.
 *    15. `executeProposal(uint256 _proposalId)`: Executes a passed governance proposal (if conditions are met).
 *    16. `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific proposal.
 *    17. `getProposalVotingPower(address _voter)`: Retrieves the voting power of a member based on reputation and roles (dynamic weighting).
 *    18. `setVotingPeriod(uint256 _newVotingPeriod)`: Governance function to change the default voting period for proposals.
 *    19. `setQuorum(uint256 _newQuorum)`: Governance function to change the quorum required for proposal passing (percentage).
 *
 * **IV. Reputation System & Task Management:**
 *    20. `increaseReputation(address _member, uint256 _amount, string memory _reason)`: Admin/Role-based function to increase a member's reputation.
 *    21. `decreaseReputation(address _member, uint256 _amount, string memory _reason)`: Admin/Role-based function to decrease a member's reputation.
 *    22. `getMemberReputation(address _member)`: Retrieves the reputation score of a member.
 *    23. `createTask(string memory _title, string memory _description, uint256 _reward, uint256 _deadline)`: Members can create tasks for the DAO with a reward.
 *    24. `assignTask(uint256 _taskId, address _assignee)`: Admin/Role-based function to assign a task to a member.
 *    25. `submitTaskCompletion(uint256 _taskId)`: Members can submit their completed task for review.
 *    26. `approveTaskCompletion(uint256 _taskId)`: Admin/Role-based function to approve a task completion and reward the assignee.
 *    27. `rejectTaskCompletion(uint256 _taskId, string memory _reason)`: Admin/Role-based function to reject a task completion with a reason.
 *    28. `getTaskDetails(uint256 _taskId)`: Retrieves details of a specific task.
 *
 * **V.  Treasury (Basic Example - Can be expanded):**
 *    29. `deposit()`: Allows anyone to deposit ETH into the DAO treasury.
 *    30. `getTreasuryBalance()`: Retrieves the current ETH balance of the DAO treasury.
 *    // Treasury withdrawal would typically be governed by proposals.
 */
contract SkillBasedDynamicDAO {
    // ** I. Core DAO Structure & Membership **
    mapping(address => bool) public members; // Address to membership status
    mapping(address => string) public memberProfiles; // Member address to profile description
    mapping(address => bool) public pendingMembershipRequests; // Addresses requesting membership
    address public owner; // DAO Owner/Admin

    event MembershipRequested(address indexed member, string profile);
    event MembershipApproved(address indexed member);
    event MembershipRejected(address indexed member);
    event MembershipRevoked(address indexed member);

    // ** II. Skill-Based Roles & Permissions **
    struct Role {
        string name;
        string description;
    }
    mapping(uint256 => Role) public roles; // Role ID to Role details
    uint256 public roleCounter;
    mapping(address => mapping(uint256 => bool)) public memberRoles; // Member address to Role ID to hasRole status

    event RoleDefined(uint256 indexed roleId, string name, string description);
    event RoleAssigned(address indexed member, uint256 indexed roleId);
    event RoleRemoved(address indexed member, uint256 indexed roleId);

    // Define Admin Role ID (Role ID 1 for Admin - you can manage roles through governance later)
    uint256 public constant ADMIN_ROLE_ID = 1;

    // ** III. Dynamic Governance & Proposals **
    struct Proposal {
        uint256 id;
        string title;
        string description;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        bytes calldataData;
        address targetContract;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 quorum; // Quorum for this specific proposal (can be dynamic)
        bool executed;
        bool passed;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCounter;
    uint256 public votingPeriod = 7 days; // Default voting period
    uint256 public quorum = 50; // Default quorum percentage (50%)
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter => votedSupport

    event ProposalSubmitted(uint256 indexed proposalId, string title, address proposer);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalFailed(uint256 indexed proposalId);

    // ** IV. Reputation System & Task Management **
    mapping(address => uint256) public memberReputation; // Member address to reputation score
    struct Task {
        uint256 id;
        string title;
        string description;
        address creator;
        address assignee;
        uint256 reward;
        uint256 deadline;
        bool completed;
        bool approved;
        string rejectionReason;
    }
    mapping(uint256 => Task) public tasks;
    uint256 public taskCounter;

    event ReputationIncreased(address indexed member, uint256 amount, string reason);
    event ReputationDecreased(address indexed member, uint256 amount, string reason);
    event TaskCreated(uint256 indexed taskId, string title, address creator);
    event TaskAssigned(uint256 indexed taskId, address assignee);
    event TaskCompletionSubmitted(uint256 indexed taskId, address submitter);
    event TaskCompletionApproved(uint256 indexed taskId, address approver);
    event TaskCompletionRejected(uint256 indexed taskId, uint256 approver, string reason);

    // ** V. Treasury (Basic Example) **
    uint256 public treasuryBalance;

    constructor() {
        owner = msg.sender;
        // Define Admin Role on contract deployment
        defineRole("Admin", "Administrator role with full control over the DAO.");
        assignRole(owner, ADMIN_ROLE_ID); // Assign Admin role to the deployer
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyRole(uint256 _roleId) {
        require(hasRole(msg.sender, _roleId), "Caller does not have the required role.");
        _;
    }

    modifier onlyMember() {
        require(isMember(msg.sender), "Only members can call this function.");
        _;
    }

    // ** I. Core DAO Structure & Membership Functions **
    function requestMembership(string memory _profile) public {
        require(!isMember(msg.sender), "Already a member.");
        require(!pendingMembershipRequests[msg.sender], "Membership request already pending.");
        pendingMembershipRequests[msg.sender] = true;
        memberProfiles[msg.sender] = _profile;
        emit MembershipRequested(msg.sender, _profile);
    }

    function approveMembership(address _member) public onlyRole(ADMIN_ROLE_ID) {
        require(pendingMembershipRequests[_member], "No pending membership request.");
        members[_member] = true;
        pendingMembershipRequests[_member] = false;
        emit MembershipApproved(_member);
    }

    function rejectMembership(address _member) public onlyRole(ADMIN_ROLE_ID) {
        require(pendingMembershipRequests[_member], "No pending membership request.");
        pendingMembershipRequests[_member] = false;
        delete memberProfiles[_member]; // Optionally remove profile on rejection
        emit MembershipRejected(_member);
    }

    function revokeMembership(address _member) public onlyRole(ADMIN_ROLE_ID) {
        require(isMember(_member), "Not a member.");
        members[_member] = false;
        emit MembershipRevoked(_member);
    }

    function getMemberProfile(address _member) public view returns (string memory) {
        return memberProfiles[_member];
    }

    function isMember(address _account) public view returns (bool) {
        return members[_account];
    }

    // ** II. Skill-Based Roles & Permissions Functions **
    function defineRole(string memory _roleName, string memory _description) public onlyRole(ADMIN_ROLE_ID) {
        roleCounter++;
        roles[roleCounter] = Role({name: _roleName, description: _description});
        emit RoleDefined(roleCounter, _roleName, _description);
    }

    function assignRole(address _member, uint256 _roleId) public onlyRole(ADMIN_ROLE_ID) {
        require(isMember(_member), "Target address is not a member.");
        require(roles[_roleId].name.length > 0, "Role ID does not exist.");
        memberRoles[_member][_roleId] = true;
        emit RoleAssigned(_member, _roleId);
    }

    function removeRole(address _member, uint256 _roleId) public onlyRole(ADMIN_ROLE_ID) {
        require(isMember(_member), "Target address is not a member.");
        require(roles[_roleId].name.length > 0, "Role ID does not exist.");
        memberRoles[_member][_roleId] = false;
        emit RoleRemoved(_member, _roleId);
    }

    function getMemberRoles(address _member) public view returns (uint256[] memory) {
        require(isMember(_member), "Target address is not a member.");
        uint256[] memory assignedRoles = new uint256[](roleCounter); // Max possible roles
        uint256 count = 0;
        for (uint256 i = 1; i <= roleCounter; i++) {
            if (memberRoles[_member][i]) {
                assignedRoles[count] = i;
                count++;
            }
        }
        // Resize array to actual number of roles
        assembly {
            mstore(assignedRoles, count) // Set length at the beginning of the array
        }
        return assignedRoles;
    }

    function getRoleDetails(uint256 _roleId) public view returns (string memory name, string memory description) {
        require(roles[_roleId].name.length > 0, "Role ID does not exist.");
        return (roles[_roleId].name, roles[_roleId].description);
    }

    function hasRole(address _account, uint256 _roleId) public view returns (bool) {
        return memberRoles[_account][_roleId];
    }

    // ** III. Dynamic Governance & Proposals Functions **
    function submitGovernanceProposal(string memory _title, string memory _description, bytes memory _calldata, address _target) public onlyMember {
        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            id: proposalCounter,
            title: _title,
            description: _description,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            calldataData: _calldata,
            targetContract: _target,
            votesFor: 0,
            votesAgainst: 0,
            quorum: quorum, // Use default quorum initially, can be dynamic later
            executed: false,
            passed: false
        });
        emit ProposalSubmitted(proposalCounter, _title, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) public onlyMember {
        require(proposals[_proposalId].id == _proposalId, "Proposal does not exist.");
        require(block.timestamp < proposals[_proposalId].endTime, "Voting period has ended.");
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal.");

        proposalVotes[_proposalId][msg.sender] = true;
        uint256 votingPower = getProposalVotingPower(msg.sender); // Dynamic voting power calculation

        if (_support) {
            proposals[_proposalId].votesFor += votingPower;
        } else {
            proposals[_proposalId].votesAgainst += votingPower;
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) public onlyRole(ADMIN_ROLE_ID) { // Execution can be role-based or time-locked, etc.
        require(proposals[_proposalId].id == _proposalId, "Proposal does not exist.");
        require(!proposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp >= proposals[_proposalId].endTime, "Voting period not ended.");

        uint256 totalVotes = proposals[_proposalId].votesFor + proposals[_proposalId].votesAgainst;
        uint256 quorumThreshold = (totalVotes * proposals[_proposalId].quorum) / 100;

        if (proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst && proposals[_proposalId].votesFor >= quorumThreshold) {
            proposals[_proposalId].passed = true;
            (bool success, ) = proposals[_proposalId].targetContract.call(proposals[_proposalId].calldataData);
            if (success) {
                proposals[_proposalId].executed = true;
                emit ProposalExecuted(_proposalId);
            } else {
                proposals[_proposalId].executed = true; // Mark as executed even if call fails to prevent re-execution
                emit ProposalFailed(_proposalId); // Or a specific event for execution failure
                // revert("Proposal execution failed."); // Optionally revert if execution failure is critical
            }
        } else {
            proposals[_proposalId].executed = true; // Prevent further execution attempts
            emit ProposalFailed(_proposalId); // Or a specific event for proposal failure
            // revert("Proposal did not pass quorum or majority."); // Optionally revert if not passed
        }
    }

    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        require(proposals[_proposalId].id == _proposalId, "Proposal does not exist.");
        return proposals[_proposalId];
    }

    function getProposalVotingPower(address _voter) public view returns (uint256) {
        // Example: Voting power is 1 + (reputation / 100) + (number of roles * 2)
        uint256 reputationFactor = memberReputation[_voter] / 100;
        uint256 roleFactor = getMemberRoles(_voter).length * 2; // Bonus for having roles

        return 1 + reputationFactor + roleFactor; // Base voting power of 1
    }

    function setVotingPeriod(uint256 _newVotingPeriod) public onlyRole(ADMIN_ROLE_ID) {
        votingPeriod = _newVotingPeriod;
    }

    function setQuorum(uint256 _newQuorum) public onlyRole(ADMIN_ROLE_ID) {
        require(_newQuorum <= 100, "Quorum must be a percentage (<= 100).");
        quorum = _newQuorum;
    }


    // ** IV. Reputation System & Task Management Functions **
    function increaseReputation(address _member, uint256 _amount, string memory _reason) public onlyRole(ADMIN_ROLE_ID) {
        require(isMember(_member), "Target address is not a member.");
        memberReputation[_member] += _amount;
        emit ReputationIncreased(_member, _amount, _reason);
    }

    function decreaseReputation(address _member, uint256 _amount, string memory _reason) public onlyRole(ADMIN_ROLE_ID) {
        require(isMember(_member), "Target address is not a member.");
        // Prevent underflow - reputation can't be negative (or handle as needed)
        memberReputation[_member] = memberReputation[_member] > _amount ? memberReputation[_member] - _amount : 0;
        emit ReputationDecreased(_member, _amount, _reason);
    }

    function getMemberReputation(address _member) public view returns (uint256) {
        return memberReputation[_member];
    }

    function createTask(string memory _title, string memory _description, uint256 _reward, uint256 _deadline) public onlyMember {
        taskCounter++;
        tasks[taskCounter] = Task({
            id: taskCounter,
            title: _title,
            description: _description,
            creator: msg.sender,
            assignee: address(0), // Initially unassigned
            reward: _reward,
            deadline: _deadline,
            completed: false,
            approved: false,
            rejectionReason: ""
        });
        emit TaskCreated(taskCounter, _title, msg.sender);
    }

    function assignTask(uint256 _taskId, address _assignee) public onlyRole(ADMIN_ROLE_ID) {
        require(tasks[_taskId].id == _taskId, "Task does not exist.");
        require(!tasks[_taskId].completed, "Task already completed.");
        require(isMember(_assignee), "Assignee is not a member.");
        tasks[_taskId].assignee = _assignee;
        emit TaskAssigned(_taskId, _assignee);
    }

    function submitTaskCompletion(uint256 _taskId) public onlyMember {
        require(tasks[_taskId].id == _taskId, "Task does not exist.");
        require(tasks[_taskId].assignee == msg.sender, "Only assignee can submit completion.");
        require(!tasks[_taskId].completed, "Task already marked as completed.");
        require(block.timestamp <= tasks[_taskId].deadline, "Task deadline exceeded."); // Optional deadline check

        tasks[_taskId].completed = true;
        emit TaskCompletionSubmitted(_taskId, msg.sender);
    }

    function approveTaskCompletion(uint256 _taskId) public onlyRole(ADMIN_ROLE_ID) {
        require(tasks[_taskId].id == _taskId, "Task does not exist.");
        require(tasks[_taskId].completed, "Task is not marked as completed.");
        require(!tasks[_taskId].approved, "Task already approved.");

        tasks[_taskId].approved = true;
        // ** Transfer Reward Logic Here ** (Example: Assuming reward is in ETH)
        payable(tasks[_taskId].assignee).transfer(tasks[_taskId].reward);
        treasuryBalance -= tasks[_taskId].reward; // Deduct from treasury (basic example)
        emit TaskCompletionApproved(_taskId, msg.sender);
    }

    function rejectTaskCompletion(uint256 _taskId, string memory _reason) public onlyRole(ADMIN_ROLE_ID) {
        require(tasks[_taskId].id == _taskId, "Task does not exist.");
        require(tasks[_taskId].completed, "Task is not marked as completed.");
        require(!tasks[_taskId].approved, "Task already approved or rejected.");

        tasks[_taskId].completed = false; // Reset completion status
        tasks[_taskId].rejectionReason = _reason;
        emit TaskCompletionRejected(_taskId, msg.sender, _reason);
    }

    function getTaskDetails(uint256 _taskId) public view returns (Task memory) {
        require(tasks[_taskId].id == _taskId, "Task does not exist.");
        return tasks[_taskId];
    }


    // ** V. Treasury Functions **
    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        treasuryBalance += msg.value;
    }

    function getTreasuryBalance() public view returns (uint256) {
        return treasuryBalance;
    }

    //  Withdrawal function would typically be governed by proposals for security and decentralization.
    //  Example withdrawal proposal execution logic would be in the `executeProposal` function
    //  if the proposal's calldata was designed to call a withdrawal function (not included here for brevity,
    //  but crucial for a real-world DAO).
}
```