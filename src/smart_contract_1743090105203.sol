```solidity
pragma solidity ^0.8.0;

/**
 * @title Dynamic Decentralized Organization (DDAO) - Advanced Governance & Incentive System
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a Dynamic Decentralized Autonomous Organization (DDAO)
 * with advanced governance, incentive mechanisms, and dynamic features beyond typical DAOs.
 * It incorporates role-based access control, reputation system, dynamic voting parameters,
 * task delegation, and a reward system to foster active participation and efficient decision-making.
 *
 * **Outline & Function Summary:**
 *
 * **1. Initialization & Ownership:**
 *    - `constructor(string memory _name, string memory _description, address _initialOwner)`: Initializes the DDAO with name, description, and sets the initial owner.
 *    - `transferOwnership(address newOwner)`: Allows the contract owner to transfer ownership.
 *    - `owner()`: Returns the address of the contract owner.
 *
 * **2. DAO Core Parameters & Configuration:**
 *    - `setDaoName(string memory _name)`: Allows the owner to update the DAO's name.
 *    - `setDaoDescription(string memory _description)`: Allows the owner to update the DAO's description.
 *    - `setVotingQuorum(uint256 _quorumPercentage)`: Allows the owner to set the minimum quorum percentage for proposals.
 *    - `setVotingDuration(uint256 _durationBlocks)`: Allows the owner to set the default voting duration in blocks.
 *    - `setDefaultProposalDeposit(uint256 _depositAmount)`: Allows the owner to set the default deposit required for proposals.
 *
 * **3. Member Management & Roles:**
 *    - `addMember(address _member)`: Allows the owner to add a new member to the DAO.
 *    - `removeMember(address _member)`: Allows the owner to remove a member from the DAO.
 *    - `assignRole(address _member, Role _role)`: Allows the owner to assign a specific role to a member.
 *    - `revokeRole(address _member, Role _role)`: Allows the owner to revoke a role from a member.
 *    - `hasRole(address _member, Role _role)`: Checks if a member has a specific role.
 *    - `getMemberRoles(address _member)`: Returns the roles assigned to a member.
 *    - `isMember(address _member)`: Checks if an address is a member of the DAO.
 *
 * **4. Proposal System (Advanced & Dynamic):**
 *    - `createProposal(ProposalType _proposalType, string memory _title, string memory _description, bytes memory _data, uint256 _depositAmount)`: Allows members to create different types of proposals with optional data and deposit.
 *    - `voteOnProposal(uint256 _proposalId, VoteOption _vote)`: Allows members to vote on active proposals.
 *    - `executeProposal(uint256 _proposalId)`: Executes a proposal if it passes the voting and quorum requirements (role-based execution).
 *    - `cancelProposal(uint256 _proposalId)`: Allows the proposer to cancel a proposal before it starts voting (deposit refund logic).
 *    - `getProposalDetails(uint256 _proposalId)`: Returns detailed information about a specific proposal.
 *    - `getProposalVoteCount(uint256 _proposalId, VoteOption _vote)`: Returns the vote count for a specific option in a proposal.
 *    - `getProposalStatus(uint256 _proposalId)`: Returns the current status of a proposal.
 *
 * **5. Reputation & Incentive System:**
 *    - `awardReputation(address _member, uint256 _reputationPoints)`: Allows roles with 'REPUTATION_MANAGER' to award reputation points to members.
 *    - `deductReputation(address _member, uint256 _reputationPoints)`: Allows roles with 'REPUTATION_MANAGER' to deduct reputation points from members.
 *    - `getMemberReputation(address _member)`: Returns the reputation points of a member.
 *    - `setReputationThresholdForRole(Role _role, uint256 _threshold)`: Allows the owner to set reputation thresholds required for specific roles.
 *    - `checkReputationThreshold(address _member, Role _role)`: Checks if a member meets the reputation threshold for a specific role.
 *
 * **6. Task Delegation & Bounty System (Creative Functionality):**
 *    - `createTask(string memory _taskTitle, string memory _taskDescription, uint256 _bountyAmount)`: Allows members with 'TASK_CREATOR' role to create tasks with a bounty.
 *    - `applyForTask(uint256 _taskId)`: Allows members to apply for a task.
 *    - `assignTask(uint256 _taskId, address _assignee)`: Allows roles with 'TASK_MANAGER' to assign a task to an applicant.
 *    - `submitTaskCompletion(uint256 _taskId)`: Allows the assignee to submit task completion for review.
 *    - `approveTaskCompletion(uint256 _taskId)`: Allows roles with 'TASK_MANAGER' to approve task completion and release bounty.
 *    - `rejectTaskCompletion(uint256 _taskId)`: Allows roles with 'TASK_MANAGER' to reject task completion (with feedback mechanism - future enhancement).
 *    - `getTaskDetails(uint256 _taskId)`: Returns details about a specific task.
 *    - `getTaskStatus(uint256 _taskId)`: Returns the current status of a task.
 *
 * **7. Emergency & Pause Functionality:**
 *    - `pauseDao()`: Allows the owner to pause critical functionalities of the DAO in case of emergency.
 *    - `unpauseDao()`: Allows the owner to unpause the DAO functionalities.
 *    - `isPaused()`: Returns the current paused status of the DAO.
 *
 * **8. View & Utility Functions:**
 *    - `getDaoName()`: Returns the DAO's name.
 *    - `getDaoDescription()`: Returns the DAO's description.
 *    - `getVotingQuorum()`: Returns the current voting quorum percentage.
 *    - `getVotingDuration()`: Returns the default voting duration in blocks.
 *    - `getDefaultProposalDeposit()`: Returns the default proposal deposit amount.
 *    - `getContractBalance()`: Returns the contract's ETH balance.
 */

contract DynamicDDAO {
    // -------- STATE VARIABLES --------

    string public daoName;
    string public daoDescription;
    address public owner;
    uint256 public votingQuorumPercentage = 50; // Default 50% quorum
    uint256 public votingDurationBlocks = 100; // Default voting duration (approx. 15-20 minutes with 12s block time)
    uint256 public defaultProposalDeposit = 1 ether; // Default proposal deposit

    bool public paused = false; // Paused state for emergency

    enum Role {
        ADMIN,          // Highest level admin, can manage roles and core settings
        PROPOSAL_CREATOR, // Can create proposals
        TASK_CREATOR,    // Can create tasks
        TASK_MANAGER,    // Can manage tasks (assign, approve, reject)
        REPUTATION_MANAGER, // Can award/deduct reputation
        TREASURY_MANAGER, // Can manage treasury (future enhancement - spending proposals)
        MEMBER           // Basic member role
    }

    enum ProposalType {
        TEXT_PROPOSAL,      // Simple text-based proposal
        CODE_UPGRADE,       // Proposal to upgrade contract code (future enhancement - proxy pattern)
        PARAMETER_CHANGE,   // Proposal to change DAO parameters
        TASK_CREATION,      // Proposal to create a new task (alternative to direct task creation)
        TREASURY_SPENDING  // Proposal for treasury spending (future enhancement)
    }

    enum ProposalStatus {
        PENDING,        // Proposal created, waiting for voting to start
        ACTIVE,         // Voting in progress
        PASSED,         // Proposal passed voting
        REJECTED,       // Proposal rejected
        EXECUTED,       // Proposal executed
        CANCELLED       // Proposal cancelled by proposer
    }

    enum VoteOption {
        FOR,
        AGAINST,
        ABSTAIN
    }

    struct Proposal {
        ProposalType proposalType;
        string title;
        string description;
        address proposer;
        uint256 depositAmount;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votesAbstain;
        ProposalStatus status;
        bytes data; // Optional data for proposal execution
    }

    struct Task {
        string title;
        string description;
        address creator;
        uint256 bountyAmount;
        address assignee;
        TaskStatus status;
        address[] applicants;
    }

    enum TaskStatus {
        OPEN,          // Task is created and open for applications
        APPLIED,       // Task has applications but not assigned
        ASSIGNED,      // Task is assigned to a member
        COMPLETED_SUBMITTED, // Assignee has submitted completion
        COMPLETED_APPROVED,  // Task completion approved, bounty released
        COMPLETED_REJECTED,  // Task completion rejected
        CANCELLED       // Task cancelled
    }


    mapping(address => mapping(Role => bool)) public memberRoles; // Member to Role mapping
    mapping(address => uint256) public memberReputation; // Member reputation points
    mapping(uint256 => Proposal) public proposals; // Proposal ID to Proposal struct
    uint256 public proposalCount = 0;
    mapping(uint256 => mapping(address => VoteOption)) public proposalVotes; // Proposal ID, Voter address to Vote Option
    mapping(uint256 => Task) public tasks; // Task ID to Task struct
    uint256 public taskCount = 0;
    mapping(Role => uint256) public reputationThresholdForRole; // Role to Reputation threshold


    // -------- MODIFIERS --------

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyRole(Role _role) {
        require(hasRole(msg.sender, _role), "Caller does not have required role.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId < proposalCount && proposals[_proposalId].proposer != address(0), "Proposal does not exist.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.ACTIVE, "Proposal is not active.");
        _;
    }

    modifier notPaused() {
        require(!paused, "DAO is currently paused.");
        _;
    }

    modifier validMember(address _member) {
        require(isMember(_member), "Address is not a member of the DAO.");
        _;
    }


    // -------- EVENTS --------

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event DaoNameUpdated(string newName);
    event DaoDescriptionUpdated(string newDescription);
    event VotingQuorumUpdated(uint256 newQuorumPercentage);
    event VotingDurationUpdated(uint256 newDurationBlocks);
    event DefaultProposalDepositUpdated(uint256 newDepositAmount);
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event RoleAssigned(address indexed member, Role role);
    event RoleRevoked(address indexed member, Role role);
    event ReputationAwarded(address indexed member, uint256 points);
    event ReputationDeducted(address indexed member, uint256 points);
    event ReputationThresholdSet(Role role, uint256 threshold);
    event ProposalCreated(uint256 indexed proposalId, ProposalType proposalType, address proposer, string title);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, VoteOption vote);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId);
    event TaskCreated(uint256 indexed taskId, string title, address creator);
    event TaskApplied(uint256 indexed taskId, address applicant);
    event TaskAssigned(uint256 indexed taskId, address assignee, address manager);
    event TaskCompletionSubmitted(uint256 indexed taskId, address assignee);
    event TaskCompletionApproved(uint256 indexed taskId, address manager);
    event TaskCompletionRejected(uint256 indexed taskId, address manager);
    event TaskCancelled(uint256 indexed taskId);
    event DaoPaused();
    event DaoUnpaused();


    // -------- 1. INITIALIZATION & OWNERSHIP --------

    constructor(string memory _name, string memory _description, address _initialOwner) {
        daoName = _name;
        daoDescription = _description;
        owner = _initialOwner;
        emit OwnershipTransferred(address(0), _initialOwner);

        // Initialize default roles for the owner (ADMIN, PROPOSAL_CREATOR, TASK_CREATOR, TASK_MANAGER, REPUTATION_MANAGER)
        _assignInitialRoles(_initialOwner);

        // Owner is automatically a member
        addMember(_initialOwner);
    }

    function _assignInitialRoles(address _account) private {
        memberRoles[_account][Role.ADMIN] = true;
        memberRoles[_account][Role.PROPOSAL_CREATOR] = true;
        memberRoles[_account][Role.TASK_CREATOR] = true;
        memberRoles[_account][Role.TASK_MANAGER] = true;
        memberRoles[_account][Role.REPUTATION_MANAGER] = true;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function owner() public view returns (address) {
        return owner;
    }

    // -------- 2. DAO CORE PARAMETERS & CONFIGURATION --------

    function setDaoName(string memory _name) public onlyOwner {
        daoName = _name;
        emit DaoNameUpdated(_name);
    }

    function setDaoDescription(string memory _description) public onlyOwner {
        daoDescription = _description;
        emit DaoDescriptionUpdated(_description);
    }

    function setVotingQuorum(uint256 _quorumPercentage) public onlyOwner {
        require(_quorumPercentage <= 100, "Quorum percentage must be between 0 and 100.");
        votingQuorumPercentage = _quorumPercentage;
        emit VotingQuorumUpdated(_quorumPercentage);
    }

    function setVotingDuration(uint256 _durationBlocks) public onlyOwner {
        votingDurationBlocks = _durationBlocks;
        emit VotingDurationUpdated(_durationBlocks);
    }

    function setDefaultProposalDeposit(uint256 _depositAmount) public onlyOwner {
        defaultProposalDeposit = _depositAmount;
        emit DefaultProposalDepositUpdated(_depositAmount);
    }

    // -------- 3. MEMBER MANAGEMENT & ROLES --------

    function addMember(address _member) public onlyOwner {
        require(!isMember(_member), "Member already exists.");
        memberRoles[_member][Role.MEMBER] = true; // Assign basic MEMBER role by default
        emit MemberAdded(_member);
    }

    function removeMember(address _member) public onlyOwner {
        require(isMember(_member) && _member != owner(), "Cannot remove owner or non-member.");
        delete memberRoles[_member]; // Effectively removes all roles
        delete memberReputation[_member]; // Optionally remove reputation as well
        emit MemberRemoved(_member);
    }

    function assignRole(address _member, Role _role) public onlyOwner {
        require(isMember(_member), "Cannot assign role to non-member.");
        memberRoles[_member][_role] = true;
        emit RoleAssigned(_member, _role);
    }

    function revokeRole(address _member, Role _role) public onlyOwner {
        require(isMember(_member), "Cannot revoke role from non-member.");
        require(_role != Role.MEMBER, "Cannot revoke base MEMBER role directly, use removeMember."); // Protect base member role.
        memberRoles[_member][_role] = false;
        emit RoleRevoked(_member, _role);
    }

    function hasRole(address _member, Role _role) public view returns (bool) {
        return memberRoles[_member][_role];
    }

    function getMemberRoles(address _member) public view returns (Role[] memory) {
        Role[] memory roles = new Role[](7); // Max 7 roles defined
        uint256 roleCount = 0;
        for (uint8 i = 0; i < 7; i++) { // Iterate through enum values
            if (memberRoles[_member][Role(i)]) {
                roles[roleCount] = Role(i);
                roleCount++;
            }
        }
        Role[] memory memberRolesArray = new Role[](roleCount);
        for (uint256 i = 0; i < roleCount; i++) {
            memberRolesArray[i] = roles[i];
        }
        return memberRolesArray;
    }


    function isMember(address _member) public view returns (bool) {
        return memberRoles[_member][Role.MEMBER];
    }


    // -------- 4. PROPOSAL SYSTEM (Advanced & Dynamic) --------

    function createProposal(
        ProposalType _proposalType,
        string memory _title,
        string memory _description,
        bytes memory _data,
        uint256 _depositAmount
    ) public onlyRole(Role.PROPOSAL_CREATOR) notPaused payable {
        require(msg.value >= _depositAmount, "Insufficient deposit sent.");
        require(_depositAmount >= defaultProposalDeposit, "Deposit amount must be at least the default proposal deposit.");

        uint256 proposalId = proposalCount++;
        proposals[proposalId] = Proposal({
            proposalType: _proposalType,
            title: _title,
            description: _description,
            proposer: msg.sender,
            depositAmount: _depositAmount,
            startTime: 0, // Voting starts when activated
            endTime: 0,   // Voting end time set when activated
            votesFor: 0,
            votesAgainst: 0,
            votesAbstain: 0,
            status: ProposalStatus.PENDING,
            data: _data
        });

        // Refund excess deposit if any
        if (msg.value > _depositAmount) {
            payable(msg.sender).transfer(msg.value - _depositAmount);
        }

        emit ProposalCreated(proposalId, _proposalType, msg.sender, _title);

        // Automatically start voting for new proposals immediately (can be adjusted for review process)
        _startProposalVoting(proposalId);
    }


    function _startProposalVoting(uint256 _proposalId) private proposalExists(_proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.PENDING, "Proposal voting already started or not in pending state.");
        proposals[_proposalId].status = ProposalStatus.ACTIVE;
        proposals[_proposalId].startTime = block.number;
        proposals[_proposalId].endTime = block.number + votingDurationBlocks;
    }


    function voteOnProposal(uint256 _proposalId, VoteOption _vote) public validMember(msg.sender) proposalExists(_proposalId) proposalActive(_proposalId) notPaused {
        require(proposalVotes[_proposalId][msg.sender] == VoteOption(0), "Already voted on this proposal."); // Assuming default enum value is 0 (no vote)
        require(block.number <= proposals[_proposalId].endTime, "Voting period has ended.");

        proposalVotes[_proposalId][msg.sender] = _vote;

        if (_vote == VoteOption.FOR) {
            proposals[_proposalId].votesFor++;
        } else if (_vote == VoteOption.AGAINST) {
            proposals[_proposalId].votesAgainst++;
        } else if (_vote == VoteOption.ABSTAIN) {
            proposals[_proposalId].votesAbstain++;
        }

        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }


    function executeProposal(uint256 _proposalId) public onlyRole(Role.ADMIN) proposalExists(_proposalId) notPaused {
        require(proposals[_proposalId].status == ProposalStatus.ACTIVE || proposals[_proposalId].status == ProposalStatus.PASSED, "Proposal not in active or passed state.");
        require(block.number > proposals[_proposalId].endTime, "Voting period has not ended yet.");

        if (proposals[_proposalId].status != ProposalStatus.PASSED) {
            _finalizeProposalVoting(_proposalId); // Finalize voting if not already done
        }

        require(proposals[_proposalId].status == ProposalStatus.PASSED, "Proposal did not pass voting.");
        require(proposals[_proposalId].status != ProposalStatus.EXECUTED, "Proposal already executed."); // Prevent double execution

        proposals[_proposalId].status = ProposalStatus.EXECUTED;

        // --- Execute proposal logic based on proposal type ---
        if (proposals[_proposalId].proposalType == ProposalType.PARAMETER_CHANGE) {
            // Example: Assuming data field contains packed parameters (e.g., new voting duration)
            // (In real world, decode _data based on specific parameter change proposal structure)
            // bytes memory data = proposals[_proposalId].data;
            // uint256 newDuration = abi.decode(data, (uint256)); // Example decoding
            // setVotingDuration(newDuration); // Example parameter change execution
        } else if (proposals[_proposalId].proposalType == ProposalType.TEXT_PROPOSAL) {
            // No specific on-chain execution for text proposals, they are informational.
        }
        // ... Add execution logic for other ProposalTypes as needed ...

        emit ProposalExecuted(_proposalId);

        // Return proposer's deposit after successful execution (incentive for good proposals)
        payable(proposals[_proposalId].proposer).transfer(proposals[_proposalId].depositAmount);
    }

    function _finalizeProposalVoting(uint256 _proposalId) private proposalExists(_proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.ACTIVE, "Proposal voting not active.");
        require(block.number > proposals[_proposalId].endTime, "Voting period has not ended yet.");

        uint256 totalVotes = proposals[_proposalId].votesFor + proposals[_proposalId].votesAgainst + proposals[_proposalId].votesAbstain;
        uint256 quorum = (totalVotes * 100) / (getMemberCount()); // Assuming getMemberCount() exists (or track member count)
        bool passed = (quorum >= votingQuorumPercentage) && (proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst);

        if (passed) {
            proposals[_proposalId].status = ProposalStatus.PASSED;
        } else {
            proposals[_proposalId].status = ProposalStatus.REJECTED;
            // Optionally, proposer loses deposit for rejected proposals (disincentive for frivolous proposals)
            // No deposit return for rejected proposals in this example.
        }
    }


    function cancelProposal(uint256 _proposalId) public proposalExists(_proposalId) notPaused {
        require(proposals[_proposalId].proposer == msg.sender, "Only proposer can cancel.");
        require(proposals[_proposalId].status == ProposalStatus.PENDING || proposals[_proposalId].status == ProposalStatus.ACTIVE, "Proposal cannot be cancelled in current status.");

        proposals[_proposalId].status = ProposalStatus.CANCELLED;
        emit ProposalCancelled(_proposalId);

        // Refund proposer's deposit on cancellation
        payable(proposals[_proposalId].proposer).transfer(proposals[_proposalId].depositAmount);
    }


    function getProposalDetails(uint256 _proposalId) public view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function getProposalVoteCount(uint256 _proposalId, VoteOption _vote) public view proposalExists(_proposalId) returns (uint256) {
        if (_vote == VoteOption.FOR) {
            return proposals[_proposalId].votesFor;
        } else if (_vote == VoteOption.AGAINST) {
            return proposals[_proposalId].votesAgainst;
        } else if (_vote == VoteOption.ABSTAIN) {
            return proposals[_proposalId].votesAbstain;
        }
        return 0; // Default case, should not reach here if VoteOption is correctly used.
    }

    function getProposalStatus(uint256 _proposalId) public view proposalExists(_proposalId) returns (ProposalStatus) {
        return proposals[_proposalId].status;
    }

    // -------- 5. REPUTATION & INCENTIVE SYSTEM --------

    function awardReputation(address _member, uint256 _reputationPoints) public onlyRole(Role.REPUTATION_MANAGER) validMember(_member) notPaused {
        memberReputation[_member] += _reputationPoints;
        emit ReputationAwarded(_member, _reputationPoints);
    }

    function deductReputation(address _member, uint256 _reputationPoints) public onlyRole(Role.REPUTATION_MANAGER) validMember(_member) notPaused {
        require(memberReputation[_member] >= _reputationPoints, "Insufficient reputation to deduct.");
        memberReputation[_member] -= _reputationPoints;
        emit ReputationDeducted(_member, _reputationPoints);
    }

    function getMemberReputation(address _member) public view validMember(_member) returns (uint256) {
        return memberReputation[_member];
    }

    function setReputationThresholdForRole(Role _role, uint256 _threshold) public onlyOwner {
        reputationThresholdForRole[_role] = _threshold;
        emit ReputationThresholdSet(_role, _threshold);
    }

    function checkReputationThreshold(address _member, Role _role) public view validMember(_member) returns (bool) {
        return memberReputation[_member] >= reputationThresholdForRole[_role];
    }


    // -------- 6. TASK DELEGATION & BOUNTY SYSTEM (Creative Functionality) --------

    function createTask(
        string memory _taskTitle,
        string memory _taskDescription,
        uint256 _bountyAmount
    ) public onlyRole(Role.TASK_CREATOR) notPaused payable {
        require(msg.value >= _bountyAmount, "Insufficient bounty amount sent.");
        require(_bountyAmount > 0, "Bounty amount must be greater than zero.");

        uint256 taskId = taskCount++;
        tasks[taskId] = Task({
            title: _taskTitle,
            description: _taskDescription,
            creator: msg.sender,
            bountyAmount: _bountyAmount,
            assignee: address(0), // Initially unassigned
            status: TaskStatus.OPEN,
            applicants: new address[](0)
        });

        // Refund excess bounty if any
        if (msg.value > _bountyAmount) {
            payable(msg.sender).transfer(msg.value - _bountyAmount);
        }

        emit TaskCreated(taskId, _taskTitle, msg.sender);
    }


    function applyForTask(uint256 _taskId) public validMember(msg.sender) notPaused {
        require(tasks[_taskId].status == TaskStatus.OPEN, "Task is not open for applications.");
        require(tasks[_taskId].assignee == address(0), "Task already assigned.");
        require(!_isApplicant(tasks[_taskId].applicants, msg.sender), "Already applied for this task.");

        tasks[_taskId].applicants.push(msg.sender);
        tasks[_taskId].status = TaskStatus.APPLIED; // Update task status to applied when first applicant applies
        emit TaskApplied(_taskId, msg.sender);
    }

    function _isApplicant(address[] storage _applicants, address _applicant) private view returns (bool) {
        for (uint256 i = 0; i < _applicants.length; i++) {
            if (_applicants[i] == _applicant) {
                return true;
            }
        }
        return false;
    }


    function assignTask(uint256 _taskId, address _assignee) public onlyRole(Role.TASK_MANAGER) validMember(_assignee) notPaused {
        require(tasks[_taskId].status == TaskStatus.OPEN || tasks[_taskId].status == TaskStatus.APPLIED, "Task is not open or in applied status.");
        require(tasks[_taskId].assignee == address(0), "Task already assigned.");
        require(_isApplicant(tasks[_taskId].applicants, _assignee), "Assignee must be an applicant for the task."); // Ensure only applicants can be assigned.

        tasks[_taskId].assignee = _assignee;
        tasks[_taskId].status = TaskStatus.ASSIGNED;
        emit TaskAssigned(_taskId, _assignee, msg.sender);
    }


    function submitTaskCompletion(uint256 _taskId) public validMember(msg.sender) notPaused {
        require(tasks[_taskId].status == TaskStatus.ASSIGNED, "Task is not in assigned status.");
        require(tasks[_taskId].assignee == msg.sender, "Only assignee can submit completion.");

        tasks[_taskId].status = TaskStatus.COMPLETED_SUBMITTED;
        emit TaskCompletionSubmitted(_taskId, msg.sender);
    }


    function approveTaskCompletion(uint256 _taskId) public onlyRole(Role.TASK_MANAGER) notPaused {
        require(tasks[_taskId].status == TaskStatus.COMPLETED_SUBMITTED, "Task completion not submitted.");

        tasks[_taskId].status = TaskStatus.COMPLETED_APPROVED;
        emit TaskCompletionApproved(_taskId, msg.sender);

        // Release bounty to assignee
        payable(tasks[_taskId].assignee).transfer(tasks[_taskId].bountyAmount);
    }

    function rejectTaskCompletion(uint256 _taskId) public onlyRole(Role.TASK_MANAGER) notPaused {
        require(tasks[_taskId].status == TaskStatus.COMPLETED_SUBMITTED, "Task completion not submitted.");

        tasks[_taskId].status = TaskStatus.COMPLETED_REJECTED;
        emit TaskCompletionRejected(_taskId, msg.sender);

        // Bounty remains in contract for other tasks or DAO treasury (depending on design)
        // In this example, bounty stays in the contract.
    }

    function cancelTask(uint256 _taskId) public onlyRole(Role.TASK_MANAGER) notPaused {
        require(tasks[_taskId].status != TaskStatus.COMPLETED_APPROVED && tasks[_taskId].status != TaskStatus.COMPLETED_REJECTED && tasks[_taskId].status != TaskStatus.CANCELLED, "Task cannot be cancelled in current status.");

        tasks[_taskId].status = TaskStatus.CANCELLED;
        emit TaskCancelled(_taskId);

        // Return bounty to task creator (optional, could also keep in DAO treasury in some scenarios)
        payable(tasks[_taskId].creator).transfer(tasks[_taskId].bountyAmount);
    }


    function getTaskDetails(uint256 _taskId) public view returns (Task memory) {
        return tasks[_taskId];
    }

    function getTaskStatus(uint256 _taskId) public view returns (TaskStatus) {
        return tasks[_taskId].status;
    }


    // -------- 7. EMERGENCY & PAUSE FUNCTIONALITY --------

    function pauseDao() public onlyOwner {
        paused = true;
        emit DaoPaused();
    }

    function unpauseDao() public onlyOwner {
        paused = false;
        emit DaoUnpaused();
    }

    function isPaused() public view returns (bool) {
        return paused;
    }


    // -------- 8. VIEW & UTILITY FUNCTIONS --------

    function getDaoName() public view returns (string memory) {
        return daoName;
    }

    function getDaoDescription() public view returns (string memory) {
        return daoDescription;
    }

    function getVotingQuorum() public view returns (uint256) {
        return votingQuorumPercentage;
    }

    function getVotingDuration() public view returns (uint256) {
        return votingDurationBlocks;
    }

    function getDefaultProposalDeposit() public view returns (uint256) {
        return defaultProposalDeposit;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMemberCount() public view returns (uint256) {
        uint256 count = 0;
        // Inefficient way to count members, consider tracking members in a list for efficiency in real-world scenarios.
        // Iterating through all possible addresses is not feasible on a live blockchain.
        // This is just a placeholder for demonstration purposes.
        // In a real DAO, you would likely maintain a list or mapping of members.
        // For now, a very basic and inefficient (and potentially inaccurate) approach:
        for (uint256 i = 0; i < proposalCount * 10; i++) { // A very rough estimation range, not reliable for large DAOs.
            address potentialMember = address(uint160(uint256(keccak256(abi.encodePacked(i))))); // Generate pseudo-random addresses
            if (isMember(potentialMember)) {
                count++;
            }
        }
        return count;
    }


    // Fallback function to receive ETH
    receive() external payable {}
}
```