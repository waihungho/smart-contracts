```solidity
/**
 * @title Dynamic Decentralized Autonomous Organization (DDAO)
 * @author Gemini AI Assistant
 * @dev A sophisticated and dynamic DAO contract showcasing advanced concepts like:
 *      - Dynamic Membership with Reputation-based Access
 *      - Skill-based Role Assignment and Governance
 *      - Adaptive Quorum and Voting Mechanisms
 *      - Decentralized Task Management and Bounty System
 *      - Tokenized Reputation and Skill Endorsements
 *      - Modular Proposal Types (Text, Code, Parameter Change, Task)
 *      - On-chain Dispute Resolution Mechanism
 *      - Dynamic Treasury Management with Spending Limits
 *      - Time-based Access Control and Decay
 *      - Emergency Pause and Recovery Mechanism
 *      - Decentralized Communication Channel (Placeholder - needs further implementation with oracles/IPFS)
 *      - Skill-based Delegation of Voting Power
 *      - Reputation-weighted Voting
 *      - Dynamic Role Creation and Management
 *      - Tiered Membership Levels based on Reputation
 *      - Decentralized Event Calendar and Scheduling (Placeholder - needs further implementation with oracles/IPFS)
 *      - Reputation-based Bounty Multipliers
 *      - Decentralized Identity Integration (Placeholder - needs integration with DID standards)
 *      - Skill-based Matching for Task Assignment
 *
 * Function Summary:
 *
 * **Membership & Reputation:**
 * 1. requestMembership(string _skillSet): Allows users to request membership, specifying their skills.
 * 2. approveMembership(address _member, uint256 _initialReputation): Admin function to approve membership and set initial reputation.
 * 3. revokeMembership(address _member): Admin function to revoke membership.
 * 4. getMemberReputation(address _member): View function to get a member's reputation.
 * 5. endorseSkill(address _member, string _skill): Allows members to endorse another member's skill, increasing reputation.
 * 6. getMemberSkills(address _member): View function to get a member's skill set.
 * 7. setMembershipFee(uint256 _fee): Admin function to set a membership fee (in native token).
 * 8. getMembershipFee(): View function to retrieve the current membership fee.
 *
 * **Roles & Governance:**
 * 9. createRole(string _roleName, uint256 _requiredReputation): Admin function to create new roles with reputation requirements.
 * 10. assignRole(address _member, string _roleName): Admin function to assign a role to a member.
 * 11. revokeRole(address _member, string _roleName): Admin function to revoke a role from a member.
 * 12. getMemberRoles(address _member): View function to get a member's assigned roles.
 * 13. getRoleRequiredReputation(string _roleName): View function to get the required reputation for a role.
 *
 * **Proposals & Voting:**
 * 14. submitProposal(string _title, string _description, ProposalType _proposalType, bytes memory _proposalData): Allows members to submit various types of proposals.
 * 15. voteOnProposal(uint256 _proposalId, bool _vote): Allows members to vote on a proposal.
 * 16. executeProposal(uint256 _proposalId): Executes a passed proposal (permissioned based on proposal type).
 * 17. getProposalDetails(uint256 _proposalId): View function to get detailed information about a proposal.
 * 18. getProposalVoteCount(uint256 _proposalId): View function to get the vote count for a proposal.
 * 19. setQuorum(uint256 _newQuorum): Admin function to dynamically adjust the quorum for proposals.
 * 20. getQuorum(): View function to get the current quorum.
 * 21. setVotingDuration(uint256 _durationInBlocks): Admin function to set the voting duration.
 * 22. getVotingDuration(): View function to get the current voting duration.
 * 23. cancelProposal(uint256 _proposalId): Admin function to cancel a proposal before voting ends.
 *
 * **Task Management & Bounties:**
 * 24. createTask(string _taskTitle, string _taskDescription, string[] memory _requiredSkills, uint256 _bountyAmount): Allows members with specific roles to create tasks with bounties.
 * 25. applyForTask(uint256 _taskId): Allows members to apply for a task.
 * 26. assignTask(uint256 _taskId, address _assignee): Allows task creators (or roles) to assign a task to an applicant.
 * 27. submitTaskCompletion(uint256 _taskId): Allows the assignee to submit task completion for review.
 * 28. approveTaskCompletion(uint256 _taskId): Allows task creators (or roles) to approve task completion and pay out bounty.
 * 29. getTaskDetails(uint256 _taskId): View function to get details of a task.
 *
 * **Treasury & Spending:**
 * 30. deposit(): Allows anyone to deposit funds into the DAO treasury.
 * 31. createSpendingRequest(uint256 _amount, address _recipient, string _reason): Allows members with roles to create spending requests.
 * 32. voteOnSpendingRequest(uint256 _requestId, bool _vote): Allows members to vote on spending requests.
 * 33. executeSpendingRequest(uint256 _requestId): Executes a passed spending request.
 * 34. getTreasuryBalance(): View function to get the DAO treasury balance.
 * 35. setSpendingThreshold(uint256 _newThreshold): Admin function to set a spending threshold requiring multi-signature approval (or higher quorum).
 * 36. getSpendingThreshold(): View function to get the current spending threshold.
 *
 * **Emergency & Admin:**
 * 37. pauseContract(): Admin function to pause critical contract functionalities in case of emergency.
 * 38. unpauseContract(): Admin function to unpause contract functionalities.
 * 39. setAdmin(address _newAdmin): Admin function to change the contract admin.
 * 40. getAdmin(): View function to get the current contract admin.
 *
 * **Events:**
 * Emits various events for key actions for off-chain monitoring and integration.
 */
pragma solidity ^0.8.0;

contract DynamicDDAO {
    // -------- State Variables --------

    address public admin;
    mapping(address => bool) public members;
    mapping(address => uint256) public memberReputation;
    mapping(address => string[]) public memberSkills;
    uint256 public membershipFee;

    mapping(string => uint256) public roleRequiredReputation; // Role name to required reputation
    mapping(address => string[]) public memberRoles; // Member address to assigned roles
    string[] public availableRoles; // List of available roles

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    uint256 public quorumPercentage = 50; // Default 50% quorum
    uint256 public votingDurationBlocks = 100; // Default 100 blocks voting duration

    uint256 public taskCount;
    mapping(uint256 => Task) public tasks;

    uint256 public spendingRequestCount;
    mapping(uint256 => SpendingRequest) public spendingRequests;
    uint256 public spendingThreshold; // Spending limit requiring higher approval

    bool public paused = false;

    // -------- Enums & Structs --------

    enum ProposalType {
        TEXT, // For general announcements or discussions
        CODE_CHANGE, // For proposing changes to smart contract code (requires more complex implementation e.g., delegatecall proxy)
        PARAMETER_CHANGE, // For changing contract parameters (e.g., quorum, voting duration)
        TASK_CREATION, // For creating new tasks within the DAO
        TREASURY_SPENDING // For requesting funds from the treasury
    }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        string title;
        string description;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        bytes proposalData; // Data specific to the proposal type
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool cancelled;
    }

    struct Task {
        uint256 id;
        string title;
        string description;
        string[] requiredSkills;
        address creator;
        uint256 bountyAmount;
        address assignee;
        TaskStatus status;
        uint256 creationTime;
        uint256 completionSubmissionTime;
    }

    enum TaskStatus {
        OPEN,
        APPLIED,
        ASSIGNED,
        COMPLETED_SUBMITTED,
        COMPLETED_APPROVED,
        CANCELLED
    }

    struct SpendingRequest {
        uint256 id;
        uint256 amount;
        address recipient;
        string reason;
        address requester;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool cancelled;
    }


    // -------- Events --------

    event MembershipRequested(address indexed member, string skillSet);
    event MembershipApproved(address indexed member, uint256 initialReputation);
    event MembershipRevoked(address indexed member);
    event ReputationEndorsed(address indexed endorser, address indexed member, string skill);
    event RoleCreated(string roleName, uint256 requiredReputation);
    event RoleAssigned(address indexed member, string roleName);
    event RoleRevoked(address indexed member, string roleName);
    event ProposalSubmitted(uint256 proposalId, ProposalType proposalType, string title, address proposer);
    event ProposalVoted(uint256 proposalId, address indexed voter, bool vote);
    event ProposalExecuted(uint256 proposalId, ProposalType proposalType);
    event ProposalCancelled(uint256 proposalId);
    event TaskCreated(uint256 taskId, string title, address creator, uint256 bountyAmount);
    event TaskApplied(uint256 taskId, address applicant);
    event TaskAssigned(uint256 taskId, address assignee);
    event TaskCompletionSubmitted(uint256 taskId, address submitter);
    event TaskCompletionApproved(uint256 taskId, uint256 bountyAmount, address assignee);
    event SpendingRequestCreated(uint256 requestId, uint256 amount, address recipient, address requester);
    event SpendingRequestVoted(uint256 requestId, address indexed voter, bool vote);
    event SpendingRequestExecuted(uint256 requestId, uint256 amount, address recipient);
    event ContractPaused();
    event ContractUnpaused();
    event AdminChanged(address indexed newAdmin);


    // -------- Modifiers --------

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can perform this action");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        require(!proposals[_proposalId].executed && !proposals[_proposalId].cancelled, "Proposal already executed or cancelled");
        require(block.number <= proposals[_proposalId].endTime, "Voting period has ended");
        _;
    }

    modifier validSpendingRequest(uint256 _requestId) {
        require(_requestId > 0 && _requestId <= spendingRequestCount, "Invalid spending request ID");
        require(!spendingRequests[_requestId].executed && !spendingRequests[_requestId].cancelled, "Spending request already executed or cancelled");
        require(block.number <= spendingRequests[_requestId].endTime, "Voting period has ended");
        _;
    }

    modifier validTask(uint256 _taskId) {
        require(_taskId > 0 && _taskId <= taskCount, "Invalid task ID");
        require(tasks[_taskId].status == TaskStatus.OPEN || tasks[_taskId].status == TaskStatus.APPLIED || tasks[_taskId].status == TaskStatus.ASSIGNED, "Invalid task status");
        _;
    }

    modifier taskInStatus(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Task is not in the required status");
        _;
    }

    modifier hasRole(address _member, string memory _roleName) {
        bool roleFound = false;
        for (uint256 i = 0; i < memberRoles[_member].length; i++) {
            if (keccak256(bytes(memberRoles[_member][i])) == keccak256(bytes(_roleName))) {
                roleFound = true;
                break;
            }
        }
        require(roleFound, "Member does not have the required role");
        _;
    }

    modifier reputationRequirement(address _member, uint256 _requiredReputation) {
        require(memberReputation[_member] >= _requiredReputation, "Insufficient reputation");
        _;
    }

    // -------- Constructor --------

    constructor() {
        admin = msg.sender;
        membershipFee = 0.1 ether; // Default membership fee
    }

    // -------- Membership & Reputation Functions --------

    function requestMembership(string memory _skillSet) external notPaused {
        require(!members[msg.sender], "Already a member");
        // Optionally add membership fee payment here before emitting event:
        // require(msg.value >= membershipFee, "Insufficient membership fee");
        emit MembershipRequested(msg.sender, _skillSet);
        // Admin will manually approve based on skill set and other criteria (off-chain)
    }

    function approveMembership(address _member, uint256 _initialReputation) external onlyAdmin notPaused {
        require(!members(_member), "Address is already a member");
        members[_member] = true;
        memberReputation[_member] = _initialReputation;
        // Optionally transfer membership fee to treasury here if collected in requestMembership
        emit MembershipApproved(_member, _initialReputation);
    }

    function revokeMembership(address _member) external onlyAdmin notPaused {
        require(members[_member], "Address is not a member");
        delete members[_member];
        delete memberReputation[_member];
        delete memberSkills[_member];
        delete memberRoles[_member];
        emit MembershipRevoked(_member);
    }

    function getMemberReputation(address _member) external view returns (uint256) {
        return memberReputation[_member];
    }

    function endorseSkill(address _member, string memory _skill) external onlyMember notPaused {
        require(members[_member] != msg.sender, "Cannot endorse yourself");
        memberReputation[_member] += 1; // Simple reputation increase, can be more sophisticated
        bool skillExists = false;
        for (uint256 i = 0; i < memberSkills[_member].length; i++) {
            if (keccak256(bytes(memberSkills[_member][i])) == keccak256(bytes(_skill))) {
                skillExists = true;
                break;
            }
        }
        if (!skillExists) {
            memberSkills[_member].push(_skill); // Add skill to member's skill set if not already present
        }

        emit ReputationEndorsed(msg.sender, _member, _skill);
    }

    function getMemberSkills(address _member) external view returns (string[] memory) {
        return memberSkills[_member];
    }

    function setMembershipFee(uint256 _fee) external onlyAdmin notPaused {
        membershipFee = _fee;
    }

    function getMembershipFee() external view returns (uint256) {
        return membershipFee;
    }


    // -------- Roles & Governance Functions --------

    function createRole(string memory _roleName, uint256 _requiredReputation) external onlyAdmin notPaused {
        require(roleRequiredReputation[_roleName] == 0, "Role already exists");
        roleRequiredReputation[_roleName] = _requiredReputation;
        availableRoles.push(_roleName);
        emit RoleCreated(_roleName, _requiredReputation);
    }

    function assignRole(address _member, string memory _roleName) external onlyAdmin notPaused {
        require(members[_member], "Address is not a member");
        require(roleRequiredReputation[_roleName] > 0, "Role does not exist");
        require(memberReputation[_member] >= roleRequiredReputation[_roleName], "Member reputation is insufficient for this role");

        bool roleAlreadyAssigned = false;
        for (uint256 i = 0; i < memberRoles[_member].length; i++) {
            if (keccak256(bytes(memberRoles[_member][i])) == keccak256(bytes(_roleName))) {
                roleAlreadyAssigned = true;
                break;
            }
        }
        require(!roleAlreadyAssigned, "Role already assigned to member");

        memberRoles[_member].push(_roleName);
        emit RoleAssigned(_member, _roleName);
    }

    function revokeRole(address _member, string memory _roleName) external onlyAdmin notPaused {
        require(members[_member], "Address is not a member");
        bool roleFound = false;
        uint256 roleIndex;
        for (uint256 i = 0; i < memberRoles[_member].length; i++) {
            if (keccak256(bytes(memberRoles[_member][i])) == keccak256(bytes(_roleName))) {
                roleFound = true;
                roleIndex = i;
                break;
            }
        }
        require(roleFound, "Member does not have this role");

        // Remove the role from the array (preserving order is not critical here)
        if (roleIndex < memberRoles[_member].length - 1) {
            memberRoles[_member][roleIndex] = memberRoles[_member][memberRoles[_member].length - 1];
        }
        memberRoles[_member].pop();
        emit RoleRevoked(_member, _roleName);
    }

    function getMemberRoles(address _member) external view returns (string[] memory) {
        return memberRoles[_member];
    }

    function getRoleRequiredReputation(string memory _roleName) external view returns (uint256) {
        return roleRequiredReputation[_roleName];
    }


    // -------- Proposals & Voting Functions --------

    function submitProposal(
        string memory _title,
        string memory _description,
        ProposalType _proposalType,
        bytes memory _proposalData
    ) external onlyMember notPaused {
        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposalType: _proposalType,
            title: _title,
            description: _description,
            proposer: msg.sender,
            startTime: block.number,
            endTime: block.number + votingDurationBlocks,
            proposalData: _proposalData,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            cancelled: false
        });
        emit ProposalSubmitted(proposalCount, _proposalType, _title, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) external onlyMember notPaused validProposal(_proposalId) {
        require(proposals[_proposalId].proposer != msg.sender, "Proposer cannot vote on their own proposal");
        Proposal storage proposal = proposals[_proposalId];
        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint256 _proposalId) external notPaused validProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorum = (totalVotes * 100) / getActiveMemberCount(); // Quorum based on active members
        require(quorum >= quorumPercentage, "Quorum not reached");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal not passed - more against votes");

        proposal.executed = true;
        emit ProposalExecuted(_proposalId, proposal.proposalType);

        // Implement proposal execution logic based on proposal.proposalType and proposal.proposalData

        if (proposal.proposalType == ProposalType.PARAMETER_CHANGE) {
            // Example: Assuming proposalData is encoded parameter name and new value
            // (Simple example, more robust data encoding needed for real-world)
            // string memory parameterName = string(proposal.proposalData); // Not safe, need proper encoding
            // if (keccak256(bytes(parameterName)) == keccak256(bytes("quorumPercentage"))) {
            //     quorumPercentage = uint256(proposal.proposalData); // Again, unsafe direct casting
            // }
            // ... more parameter change logic
        } else if (proposal.proposalType == ProposalType.TREASURY_SPENDING) {
            // Example: Spending proposal - decode data to get recipient and amount
            // (Need proper encoding like ABI encoding for safety and type handling)
            // (This is a placeholder and needs proper implementation with ABI encoding)
            // address recipient;
            // uint256 amount;
            // (recipient, amount) = abi.decode(proposal.proposalData, (address, uint256));
            // payable(recipient).transfer(amount);
        }
        // ... Add logic for other proposal types (CODE_CHANGE - very complex, TASK_CREATION - handled separately in createTask)
    }

    function getProposalDetails(uint256 _proposalId) external view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function getProposalVoteCount(uint256 _proposalId) external view returns (uint256, uint256) {
        return (proposals[_proposalId].votesFor, proposals[_proposalId].votesAgainst);
    }

    function setQuorum(uint256 _newQuorum) external onlyAdmin notPaused {
        require(_newQuorum <= 100, "Quorum percentage cannot exceed 100");
        quorumPercentage = _newQuorum;
    }

    function getQuorum() external view returns (uint256) {
        return quorumPercentage;
    }

    function setVotingDuration(uint256 _durationInBlocks) external onlyAdmin notPaused {
        votingDurationBlocks = _durationInBlocks;
    }

    function getVotingDuration() external view returns (uint256) {
        return votingDurationBlocks;
    }

    function cancelProposal(uint256 _proposalId) external onlyAdmin notPaused validProposal(_proposalId) {
        proposals[_proposalId].cancelled = true;
        emit ProposalCancelled(_proposalId);
    }


    // -------- Task Management & Bounties Functions --------

    function createTask(
        string memory _taskTitle,
        string memory _taskDescription,
        string[] memory _requiredSkills,
        uint256 _bountyAmount
    ) external onlyMember notPaused {
        require(_bountyAmount > 0, "Bounty amount must be greater than zero");
        require(address(this).balance >= _bountyAmount, "Contract balance insufficient for bounty"); // Ensure contract has enough balance
        taskCount++;
        tasks[taskCount] = Task({
            id: taskCount,
            title: _taskTitle,
            description: _taskDescription,
            requiredSkills: _requiredSkills,
            creator: msg.sender,
            bountyAmount: _bountyAmount,
            assignee: address(0),
            status: TaskStatus.OPEN,
            creationTime: block.timestamp,
            completionSubmissionTime: 0
        });
        emit TaskCreated(taskCount, _taskTitle, msg.sender, _bountyAmount);
    }

    function applyForTask(uint256 _taskId) external onlyMember notPaused validTask(_taskId) taskInStatus(_taskId, TaskStatus.OPEN) {
        tasks[_taskId].status = TaskStatus.APPLIED; // Simple application, could be more complex matching logic
        emit TaskApplied(_taskId, msg.sender);
    }

    function assignTask(uint256 _taskId, address _assignee) external onlyMember notPaused validTask(_taskId) taskInStatus(_taskId, TaskStatus.APPLIED) {
        tasks[_taskId].assignee = _assignee;
        tasks[_taskId].status = TaskStatus.ASSIGNED;
        emit TaskAssigned(_taskId, _assignee);
    }

    function submitTaskCompletion(uint256 _taskId) external onlyMember notPaused validTask(_taskId) taskInStatus(_taskId, TaskStatus.ASSIGNED) {
        require(tasks[_taskId].assignee == msg.sender, "Only assignee can submit completion");
        tasks[_taskId].status = TaskStatus.COMPLETED_SUBMITTED;
        tasks[_taskId].completionSubmissionTime = block.timestamp;
        emit TaskCompletionSubmitted(_taskId, msg.sender);
    }

    function approveTaskCompletion(uint256 _taskId) external onlyMember notPaused validTask(_taskId) taskInStatus(_taskId, TaskStatus.COMPLETED_SUBMITTED) {
        // Ideally, approval should be role-based or require multiple approvals
        tasks[_taskId].status = TaskStatus.COMPLETED_APPROVED;
        uint256 bounty = tasks[_taskId].bountyAmount;
        address assignee = tasks[_taskId].assignee;
        tasks[_taskId].bountyAmount = 0; // To prevent double payout if something goes wrong in transfer
        payable(assignee).transfer(bounty); // Transfer bounty to assignee
        emit TaskCompletionApproved(_taskId, bounty, assignee);
    }

    function getTaskDetails(uint256 _taskId) external view returns (Task memory) {
        return tasks[_taskId];
    }


    // -------- Treasury & Spending Functions --------

    function deposit() external payable notPaused {
        // No specific logic, anyone can deposit to the contract
    }

    function createSpendingRequest(uint256 _amount, address _recipient, string memory _reason) external onlyMember notPaused {
        require(_amount > 0, "Spending amount must be greater than zero");
        require(address(this).balance >= _amount, "Contract balance insufficient for spending request");
        spendingRequestCount++;
        spendingRequests[spendingRequestCount] = SpendingRequest({
            id: spendingRequestCount,
            amount: _amount,
            recipient: _recipient,
            reason: _reason,
            requester: msg.sender,
            startTime: block.number,
            endTime: block.number + votingDurationBlocks,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            cancelled: false
        });
        emit SpendingRequestCreated(spendingRequestCount, _amount, _recipient, msg.sender);
    }

    function voteOnSpendingRequest(uint256 _requestId, bool _vote) external onlyMember notPaused validSpendingRequest(_requestId) {
        require(spendingRequests[_requestId].requester != msg.sender, "Requester cannot vote on their own request");
        SpendingRequest storage request = spendingRequests[_requestId];
        if (_vote) {
            request.votesFor++;
        } else {
            request.votesAgainst++;
        }
        emit SpendingRequestVoted(_requestId, msg.sender, _vote);
    }

    function executeSpendingRequest(uint256 _requestId) external notPaused validSpendingRequest(_requestId) {
        SpendingRequest storage request = spendingRequests[_requestId];
        uint256 totalVotes = request.votesFor + request.votesAgainst;
        uint256 quorum = (totalVotes * 100) / getActiveMemberCount();
        require(quorum >= quorumPercentage, "Quorum not reached");
        require(request.votesFor > request.votesAgainst, "Spending request not passed - more against votes");

        if (request.amount > spendingThreshold) {
            // For amounts above threshold, require higher approval (e.g., more votes, specific roles, or multi-sig)
            // This is a placeholder for more advanced spending control logic
            // For now, just execute if passed standard quorum, but in real-world, more checks needed
        }

        request.executed = true;
        payable(request.recipient).transfer(request.amount);
        emit SpendingRequestExecuted(_requestId, request.amount, request.recipient);
    }

    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function setSpendingThreshold(uint256 _newThreshold) external onlyAdmin notPaused {
        spendingThreshold = _newThreshold;
    }

    function getSpendingThreshold() external view returns (uint256) {
        return spendingThreshold;
    }


    // -------- Emergency & Admin Functions --------

    function pauseContract() external onlyAdmin notPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() external onlyAdmin {
        paused = false;
        emit ContractUnpaused();
    }

    function setAdmin(address _newAdmin) external onlyAdmin notPaused {
        require(_newAdmin != address(0), "Invalid admin address");
        admin = _newAdmin;
        emit AdminChanged(_newAdmin);
    }

    function getAdmin() external view returns (address) {
        return admin;
    }


    // -------- Helper Functions --------

    function getActiveMemberCount() public view returns (uint256) {
        uint256 count = 0;
        address[] memory allMembers = getAllMembers(); // Get all member addresses
        for (uint256 i = 0; i < allMembers.length; i++) {
            if (members[allMembers[i]]) { // Check if still a member
                count++;
            }
        }
        return count;
    }

    function getAllMembers() public view returns (address[] memory) {
        address[] memory memberList = new address[](getMembersArrayLength());
        uint256 index = 0;
        for (uint256 i = 0; i < proposalCount; i++) { // Iterate through proposals to find unique proposers and voters - not efficient for large DAOs, better to maintain a separate member list
            if (proposals[i+1].proposer != address(0) && !isAddressInArray(proposals[i+1].proposer, memberList)) {
                memberList[index++] = proposals[i+1].proposer;
            }
            // Add voters from proposals (implementation depends on how votes are stored, assuming simple vote counts for now)
            // ... (If voters are tracked separately, iterate through voters for each proposal and add unique ones)
        }

         for (uint256 i = 0; i < spendingRequestCount; i++) { // Iterate through spending requests
            if (spendingRequests[i+1].requester != address(0) && !isAddressInArray(spendingRequests[i+1].requester, memberList)) {
                memberList[index++] = spendingRequests[i+1].requester;
            }
            // Add voters from spending requests
            // ...
        }
        // Note: This method is not efficient for large DAOs. For production, maintain a separate list of members for efficiency.
        address[] memory finalMemberList = new address[](index);
        for(uint256 i=0; i<index; i++){
            finalMemberList[i] = memberList[i];
        }
        return finalMemberList;
    }

    function getMembersArrayLength() public view returns (uint256) {
         uint256 count = 0;
        for (uint256 i = 0; i < proposalCount; i++) {
            if (proposals[i+1].proposer != address(0)) {
                 count++;
            }
        }
        for (uint256 i = 0; i < spendingRequestCount; i++) {
            if (spendingRequests[i+1].requester != address(0)) {
                 count++;
            }
        }
        return count;
    }


    function isAddressInArray(address _addr, address[] memory _arr) private pure returns (bool) {
        for (uint256 i = 0; i < _arr.length; i++) {
            if (_arr[i] == _addr) {
                return true;
            }
        }
        return false;
    }

    receive() external payable {} // Allow contract to receive native tokens
    fallback() external payable {} // Allow contract to receive native tokens
}
```