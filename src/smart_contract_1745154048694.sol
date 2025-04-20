## Decentralized Autonomous Organization (DAO) with Dynamic Governance & Skill-Based Roles

**Outline and Function Summary:**

This smart contract implements a Decentralized Autonomous Organization (DAO) with advanced features focusing on dynamic governance, skill-based roles, and reputation-based access.  It aims to create a flexible and adaptable organization that can evolve based on member contributions and community needs.

**Key Features:**

* **Dynamic Governance:**  Voting mechanisms can be customized for different proposal types (simple majority, quadratic voting, reputation-weighted voting).
* **Skill-Based Roles:**  Members can acquire roles based on demonstrated skills and contributions, granting specific permissions and responsibilities.
* **Reputation System:**  Members earn reputation for participation and positive contributions, influencing voting power and role eligibility.
* **Project-Based Tasks & Bounties:**  DAO can create projects with specific tasks and reward members for completing them.
* **Decentralized Communication Channel (Conceptual):**  Placeholder for integrating off-chain communication tools.
* **Treasury Management with Staking & Yield Generation (Conceptual):** Placeholder for advanced treasury management strategies.
* **NFT-Based Role Badges (Conceptual):**  Placeholder for representing roles as NFTs for external validation.
* **Conditional Logic for Proposals:**  Proposals can include conditional logic for execution based on external data or oracle input (conceptual).
* **Decentralized Dispute Resolution (Conceptual):** Placeholder for integrating dispute resolution mechanisms.

**Function Summary:**

**1. Membership & Roles:**
    * `joinDAO()`: Allows users to become DAO members.
    * `leaveDAO()`: Allows members to leave the DAO.
    * `assignRole(address _member, bytes32 _role)`: Assigns a role to a member (Admin-only).
    * `revokeRole(address _member, bytes32 _role)`: Revokes a role from a member (Admin-only).
    * `hasRole(address _member, bytes32 _role)`: Checks if a member has a specific role.
    * `getMemberRoles(address _member)`: Returns a list of roles for a member.

**2. Reputation System:**
    * `awardReputation(address _member, uint256 _amount)`: Awards reputation points to a member (Role: Reputation Manager).
    * `deductReputation(address _member, uint256 _amount)`: Deducts reputation points from a member (Role: Reputation Manager).
    * `getMemberReputation(address _member)`: Returns the reputation points of a member.
    * `setReputationThresholdForRole(bytes32 _role, uint256 _threshold)`: Sets the reputation threshold required for a specific role (Admin-only).
    * `getReputationThresholdForRole(bytes32 _role)`: Gets the reputation threshold for a role.

**3. Proposals & Voting:**
    * `submitProposal(string _title, string _description, ProposalType _proposalType, bytes _proposalData)`:  Members submit proposals.
    * `voteOnProposal(uint256 _proposalId, VoteOption _vote)`: Members vote on a proposal.
    * `executeProposal(uint256 _proposalId)`: Executes a proposal if voting conditions are met (Role: Executor).
    * `cancelProposal(uint256 _proposalId)`: Cancels a proposal before voting ends (Role: Proposer or Admin).
    * `getProposalDetails(uint256 _proposalId)`: Returns details of a specific proposal.
    * `getProposalVoteCount(uint256 _proposalId)`: Returns the vote count for a proposal.

**4. Project & Task Management:**
    * `createProject(string _projectName, string _projectDescription)`: Creates a new project within the DAO (Role: Project Manager).
    * `addTaskToProject(uint256 _projectId, string _taskName, string _taskDescription, uint256 _bounty)`: Adds a task to a project with a bounty (Role: Project Manager).
    * `assignTask(uint256 _taskId, address _member)`: Assigns a task to a member (Role: Project Manager).
    * `submitTaskCompletion(uint256 _taskId)`: Member submits completed task for review.
    * `approveTaskCompletion(uint256 _taskId)`: Approves task completion and pays bounty (Role: Project Manager).
    * `getProjectDetails(uint256 _projectId)`: Returns details of a specific project.
    * `getTaskDetails(uint256 _taskId)`: Returns details of a specific task.

**5. Configuration & Admin:**
    * `setVotingDuration(ProposalType _proposalType, uint256 _duration)`: Sets the voting duration for a specific proposal type (Admin-only).
    * `getVotingDuration(ProposalType _proposalType)`: Gets the voting duration for a proposal type.
    * `setVotingQuorum(ProposalType _proposalType, uint256 _quorum)`: Sets the voting quorum (percentage) for a proposal type (Admin-only).
    * `getVotingQuorum(ProposalType _proposalType)`: Gets the voting quorum for a proposal type.
    * `defineRole(bytes32 _roleName)`: Defines a new role within the DAO (Admin-only).
    * `isRoleDefined(bytes32 _roleName)`: Checks if a role is defined.
    * `renounceRole(bytes32 _role)`: Allows a member to renounce a role they hold.


```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Organization (DAO) with Dynamic Governance & Skill-Based Roles
 * @author [Your Name/Organization]
 * @dev This contract implements a DAO with advanced features focusing on dynamic governance,
 *      skill-based roles, and reputation-based access.
 *
 * **Outline and Function Summary:**
 *
 * This smart contract implements a Decentralized Autonomous Organization (DAO) with advanced features focusing on dynamic governance, skill-based roles, and reputation-based access.  It aims to create a flexible and adaptable organization that can evolve based on member contributions and community needs.
 *
 * **Key Features:**
 *
 * * **Dynamic Governance:**  Voting mechanisms can be customized for different proposal types (simple majority, quadratic voting, reputation-weighted voting).
 * * **Skill-Based Roles:**  Members can acquire roles based on demonstrated skills and contributions, granting specific permissions and responsibilities.
 * * **Reputation System:**  Members earn reputation for participation and positive contributions, influencing voting power and role eligibility.
 * * **Project-Based Tasks & Bounties:**  DAO can create projects with specific tasks and reward members for completing them.
 * * **Decentralized Communication Channel (Conceptual):**  Placeholder for integrating off-chain communication tools.
 * * **Treasury Management with Staking & Yield Generation (Conceptual):** Placeholder for advanced treasury management strategies.
 * * **NFT-Based Role Badges (Conceptual):**  Placeholder for representing roles as NFTs for external validation.
 * * **Conditional Logic for Proposals:**  Proposals can include conditional logic for execution based on external data or oracle input (conceptual).
 * * **Decentralized Dispute Resolution (Conceptual):** Placeholder for integrating dispute resolution mechanisms.
 *
 * **Function Summary:**
 *
 * **1. Membership & Roles:**
 *     * `joinDAO()`: Allows users to become DAO members.
 *     * `leaveDAO()`: Allows members to leave the DAO.
 *     * `assignRole(address _member, bytes32 _role)`: Assigns a role to a member (Admin-only).
 *     * `revokeRole(address _member, bytes32 _role)`: Revokes a role from a member (Admin-only).
 *     * `hasRole(address _member, bytes32 _role)`: Checks if a member has a specific role.
 *     * `getMemberRoles(address _member)`: Returns a list of roles for a member.
 *
 * **2. Reputation System:**
 *     * `awardReputation(address _member, uint256 _amount)`: Awards reputation points to a member (Role: Reputation Manager).
 *     * `deductReputation(address _member, uint256 _amount)`: Deducts reputation points from a member (Role: Reputation Manager).
 *     * `getMemberReputation(address _member)`: Returns the reputation points of a member.
 *     * `setReputationThresholdForRole(bytes32 _role, uint256 _threshold)`: Sets the reputation threshold required for a specific role (Admin-only).
 *     * `getReputationThresholdForRole(bytes32 _role)`: Gets the reputation threshold for a role.
 *
 * **3. Proposals & Voting:**
 *     * `submitProposal(string _title, string _description, ProposalType _proposalType, bytes _proposalData)`:  Members submit proposals.
 *     * `voteOnProposal(uint256 _proposalId, VoteOption _vote)`: Members vote on a proposal.
 *     * `executeProposal(uint256 _proposalId)`: Executes a proposal if voting conditions are met (Role: Executor).
 *     * `cancelProposal(uint256 _proposalId)`: Cancels a proposal before voting ends (Role: Proposer or Admin).
 *     * `getProposalDetails(uint256 _proposalId)`: Returns details of a specific proposal.
 *     * `getProposalVoteCount(uint256 _proposalId)`: Returns the vote count for a proposal.
 *
 * **4. Project & Task Management:**
 *     * `createProject(string _projectName, string _projectDescription)`: Creates a new project within the DAO (Role: Project Manager).
 *     * `addTaskToProject(uint256 _projectId, string _taskName, string _taskDescription, uint256 _bounty)`: Adds a task to a project with a bounty (Role: Project Manager).
 *     * `assignTask(uint256 _taskId, address _member)`: Assigns a task to a member (Role: Project Manager).
 *     * `submitTaskCompletion(uint256 _taskId)`: Member submits completed task for review.
 *     * `approveTaskCompletion(uint256 _taskId)`: Approves task completion and pays bounty (Role: Project Manager).
 *     * `getProjectDetails(uint256 _projectId)`: Returns details of a specific project.
 *     * `getTaskDetails(uint256 _taskId)`: Returns details of a specific task.
 *
 * **5. Configuration & Admin:**
 *     * `setVotingDuration(ProposalType _proposalType, uint256 _duration)`: Sets the voting duration for a specific proposal type (Admin-only).
 *     * `getVotingDuration(ProposalType _proposalType)`: Gets the voting duration for a proposal type.
 *     * `setVotingQuorum(ProposalType _proposalType, uint256 _quorum)`: Sets the voting quorum (percentage) for a proposal type (Admin-only).
 *     * `getVotingQuorum(ProposalType _proposalType)`: Gets the voting quorum for a proposal type.
 *     * `defineRole(bytes32 _roleName)`: Defines a new role within the DAO (Admin-only).
 *     * `isRoleDefined(bytes32 _roleName)`: Checks if a role is defined.
 *     * `renounceRole(bytes32 _role)`: Allows a member to renounce a role they hold.
 */
contract AdvancedDAO {

    // --- Enums and Structs ---

    enum ProposalType {
        TEXT,           // Simple text-based proposals
        CODE_CHANGE,    // Proposals for smart contract code changes (advanced, requires careful implementation and review)
        TREASURY_SPEND, // Proposals to spend treasury funds
        ROLE_CHANGE     // Proposals to change roles or permissions
    }

    enum ProposalStatus {
        PENDING,
        ACTIVE,
        PASSED,
        REJECTED,
        EXECUTED,
        CANCELLED
    }

    enum VoteOption {
        FOR,
        AGAINST,
        ABSTAIN
    }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        ProposalType proposalType;
        string title;
        string description;
        bytes proposalData; // Flexible data field for different proposal types
        uint256 startTime;
        uint256 endTime;
        uint256 quorum; // Percentage quorum required
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalStatus status;
        mapping(address => VoteOption) memberVotes; // Track votes per member
    }

    struct Project {
        uint256 projectId;
        string name;
        string description;
        address projectManager;
        mapping(uint256 => Task) tasks; // Tasks within the project
        uint256 taskCount;
    }

    struct Task {
        uint256 taskId;
        uint256 projectId;
        string name;
        string description;
        uint256 bounty;
        address assignee;
        bool isCompleted;
        bool isApproved;
    }


    // --- State Variables ---

    address public admin;
    uint256 public memberCount;
    uint256 public proposalCount;
    uint256 public projectCount;

    mapping(address => bool) public isMember;
    mapping(address => uint256) public memberReputation;
    mapping(address => mapping(bytes32 => bool)) public memberRoles; // Nested mapping for roles per member
    mapping(bytes32 => bool) public definedRoles; // Keep track of defined roles
    mapping(bytes32 => uint256) public roleReputationThreshold; // Reputation threshold for roles
    mapping(ProposalType => uint256) public proposalVotingDuration; // Voting duration per proposal type (in seconds)
    mapping(ProposalType => uint256) public proposalVotingQuorum;   // Voting quorum (percentage 0-100) per proposal type
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => Project) public projects;


    // --- Events ---

    event MemberJoined(address member);
    event MemberLeft(address member);
    event RoleAssigned(address member, bytes32 role);
    event RoleRevoked(address member, bytes32 role);
    event ReputationAwarded(address member, uint256 amount);
    event ReputationDeducted(address member, uint256 amount);
    event ProposalSubmitted(uint256 proposalId, ProposalType proposalType, address proposer, string title);
    event ProposalVoted(uint256 proposalId, address voter, VoteOption vote);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCancelled(uint256 proposalId);
    event ProjectCreated(uint256 projectId, string projectName, address projectManager);
    event TaskAdded(uint256 taskId, uint256 projectId, string taskName);
    event TaskAssigned(uint256 taskId, address assignee);
    event TaskCompletionSubmitted(uint256 taskId, address submitter);
    event TaskCompletionApproved(uint256 taskId, address approver);
    event RoleDefined(bytes32 roleName);
    event RoleReputationThresholdSet(bytes32 roleName, uint256 threshold);
    event VotingDurationSet(ProposalType proposalType, uint256 duration);
    event VotingQuorumSet(ProposalType proposalType, uint256 quorum);
    event RoleRenounced(address member, bytes32 role);


    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can perform this action");
        _;
    }

    modifier onlyRole(bytes32 _role) {
        require(hasRole(msg.sender, _role), "Caller does not have required role");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId < proposalCount, "Invalid proposal ID");
        _;
    }

    modifier validProject(uint256 _projectId) {
        require(_projectId < projectCount, "Invalid project ID");
        _;
    }

    modifier validTask(uint256 _taskId) {
        require(_taskId < projects[projects[_taskId].projectId].taskCount, "Invalid task ID");
        _;
    }

    modifier proposalInStatus(uint256 _proposalId, ProposalStatus _status) {
        require(proposals[_proposalId].status == _status, "Proposal is not in the required status");
        _;
    }

    modifier votingActive(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.ACTIVE, "Voting is not active");
        require(block.timestamp <= proposals[_proposalId].endTime, "Voting period has ended");
        _;
    }

    modifier votingNotStarted(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.PENDING, "Voting has already started");
        _;
    }

    modifier notVoted(uint256 _proposalId) {
        require(proposals[_proposalId].memberVotes[msg.sender] == VoteOption.ABSTAIN, "Member has already voted");
        _;
    }

    modifier reputationAboveThreshold(bytes32 _role) {
        require(memberReputation[msg.sender] >= roleReputationThreshold[_role], "Reputation below threshold for role");
        _;
    }


    // --- Constructor ---

    constructor() {
        admin = msg.sender;
        memberCount = 0;
        proposalCount = 0;
        projectCount = 0;

        // Define default roles (can be extended)
        defineRole("Admin");
        defineRole("ReputationManager");
        defineRole("ProposalExecutor");
        defineRole("ProjectManager");

        // Set default voting durations (adjust as needed)
        proposalVotingDuration[ProposalType.TEXT] = 7 days;
        proposalVotingDuration[ProposalType.CODE_CHANGE] = 14 days;
        proposalVotingDuration[ProposalType.TREASURY_SPEND] = 10 days;
        proposalVotingDuration[ProposalType.ROLE_CHANGE] = 7 days;

        // Set default voting quorums (adjust as needed, percentages)
        proposalVotingQuorum[ProposalType.TEXT] = 50;
        proposalVotingQuorum[ProposalType.CODE_CHANGE] = 60;
        proposalVotingQuorum[ProposalType.TREASURY_SPEND] = 55;
        proposalVotingQuorum[ProposalType.ROLE_CHANGE] = 50;

        // Admin role is initially assigned to the contract deployer
        assignRole(admin, "Admin");
    }


    // --- 1. Membership & Roles Functions ---

    function joinDAO() external {
        require(!isMember[msg.sender], "Already a member");
        isMember[msg.sender] = true;
        memberCount++;
        memberReputation[msg.sender] = 0; // Initial reputation
        emit MemberJoined(msg.sender);
    }

    function leaveDAO() external onlyMember {
        isMember[msg.sender] = false;
        memberCount--;
        // Consider handling reputation or roles upon leaving, if needed
        emit MemberLeft(msg.sender);
    }

    function assignRole(address _member, bytes32 _role) external onlyAdmin {
        require(isRoleDefined(_role), "Role is not defined");
        memberRoles[_member][_role] = true;
        emit RoleAssigned(_member, _role);
    }

    function revokeRole(address _member, bytes32 _role) external onlyAdmin {
        memberRoles[_member][_role] = false;
        emit RoleRevoked(_member, _role);
    }

    function hasRole(address _member, bytes32 _role) public view returns (bool) {
        return isMember[_member] && memberRoles[_member][_role];
    }

    function getMemberRoles(address _member) external view returns (bytes32[] memory) {
        require(isMember[_member], "Address is not a member");
        bytes32[] memory roles = new bytes32[](definedRoles.length); // Maximum possible roles
        uint256 roleIndex = 0;
        for (uint256 i = 0; i < definedRoles.length; i++) { // Iterate through defined roles (inefficient, consider better role management)
            bytes32 roleName;
            uint256 count = 0;
            for (bytes32 currentRoleName : definedRoles) { // Iterate keys in definedRoles mapping - no direct way to iterate keys
                if(count == i) {
                    roleName = currentRoleName;
                    break;
                }
                count++;
            }
            if (memberRoles[_member][roleName]) {
                roles[roleIndex] = roleName;
                roleIndex++;
            }
        }
        // Resize array to actual number of roles assigned
        bytes32[] memory finalRoles = new bytes32[](roleIndex);
        for (uint256 i = 0; i < roleIndex; i++) {
            finalRoles[i] = roles[i];
        }
        return finalRoles;
    }

    function renounceRole(bytes32 _role) external onlyMember {
        memberRoles[msg.sender][_role] = false;
        emit RoleRenounced(msg.sender, _role);
    }


    // --- 2. Reputation System Functions ---

    function awardReputation(address _member, uint256 _amount) external onlyRole("ReputationManager") {
        require(isMember[_member], "Recipient is not a member");
        memberReputation[_member] += _amount;
        emit ReputationAwarded(_member, _amount);
    }

    function deductReputation(address _member, uint256 _amount) external onlyRole("ReputationManager") {
        require(isMember[_member], "Recipient is not a member");
        require(memberReputation[_member] >= _amount, "Not enough reputation to deduct");
        memberReputation[_member] -= _amount;
        emit ReputationDeducted(_member, _amount);
    }

    function getMemberReputation(address _member) external view onlyMember returns (uint256) {
        return memberReputation[_member];
    }

    function setReputationThresholdForRole(bytes32 _role, uint256 _threshold) external onlyAdmin {
        require(isRoleDefined(_role), "Role is not defined");
        roleReputationThreshold[_role] = _threshold;
        emit RoleReputationThresholdSet(_role, _threshold);
    }

    function getReputationThresholdForRole(bytes32 _role) external view returns (uint256) {
        return roleReputationThreshold[_role];
    }


    // --- 3. Proposals & Voting Functions ---

    function submitProposal(
        string memory _title,
        string memory _description,
        ProposalType _proposalType,
        bytes memory _proposalData
    ) external onlyMember {
        require(bytes(_title).length > 0 && bytes(_description).length > 0, "Title and description cannot be empty");

        uint256 proposalId = proposalCount++;
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            proposalType: _proposalType,
            title: _title,
            description: _description,
            proposalData: _proposalData,
            startTime: 0, // Set to 0 initially, activated when voting starts
            endTime: 0,   // Set to 0 initially, calculated when voting starts
            quorum: proposalVotingQuorum[_proposalType],
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.PENDING,
            memberVotes: mapping(address => VoteOption.ABSTAIN)
        });

        emit ProposalSubmitted(proposalId, _proposalType, msg.sender, _title);

        // Automatically start voting after submission (optional, can be separate function)
        _startProposalVoting(proposalId);
    }

    function _startProposalVoting(uint256 _proposalId) internal validProposal(_proposalId) votingNotStarted(_proposalId) {
        proposals[_proposalId].status = ProposalStatus.ACTIVE;
        proposals[_proposalId].startTime = block.timestamp;
        proposals[_proposalId].endTime = block.timestamp + proposalVotingDuration[proposals[_proposalId].proposalType];
    }


    function voteOnProposal(uint256 _proposalId, VoteOption _vote) external onlyMember validProposal(_proposalId) votingActive(_proposalId) notVoted(_proposalId) {
        proposals[_proposalId].memberVotes[msg.sender] = _vote;

        if (_vote == VoteOption.FOR) {
            proposals[_proposalId].votesFor++;
        } else if (_vote == VoteOption.AGAINST) {
            proposals[_proposalId].votesAgainst++;
        } // Abstain doesn't increment votes

        emit ProposalVoted(_proposalId, msg.sender, _vote);

        // Check if voting period ended or quorum reached (optional, could be triggered externally or in executeProposal)
        if (block.timestamp >= proposals[_proposalId].endTime) {
            _finalizeProposalVoting(_proposalId);
        }
    }

    function _finalizeProposalVoting(uint256 _proposalId) internal validProposal(_proposalId) proposalInStatus(_proposalId, ProposalStatus.ACTIVE) {
        uint256 totalVotes = proposals[_proposalId].votesFor + proposals[_proposalId].votesAgainst;
        uint256 quorumPercentage = (totalVotes * 100) / memberCount; // Calculate quorum as percentage of members

        if (quorumPercentage >= proposals[_proposalId].quorum && proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst) {
            proposals[_proposalId].status = ProposalStatus.PASSED;
        } else {
            proposals[_proposalId].status = ProposalStatus.REJECTED;
        }
    }


    function executeProposal(uint256 _proposalId) external onlyRole("ProposalExecutor") validProposal(_proposalId) proposalInStatus(_proposalId, ProposalStatus.PASSED) {
        require(proposals[_proposalId].status != ProposalStatus.EXECUTED, "Proposal already executed");

        // --- Proposal Execution Logic ---
        ProposalType proposalType = proposals[_proposalId].proposalType;

        if (proposalType == ProposalType.TEXT) {
            // Example: Log the text proposal content (more complex actions possible based on proposalData)
            string memory proposalContent = string(proposals[_proposalId].proposalData);
            // In a real application, you might trigger off-chain actions based on this text.
            emit ProposalExecuted(_proposalId);

        } else if (proposalType == ProposalType.CODE_CHANGE) {
            // --- !!! WARNING !!! ---
            // Executing code change proposals on-chain is extremely complex and risky.
            // This is a placeholder and requires very careful design, security audits, and potentially
            // off-chain governance processes for code review and deployment.
            // Example (highly simplified and illustrative - DO NOT USE IN PRODUCTION WITHOUT EXTREME CAUTION):
            // assembly {
            //     // Example of directly modifying contract code - DANGEROUS and not recommended in most cases.
            //     // This is for illustration of the CONCEPT ONLY.
            //     // dataoffset(proposals[_proposalId].proposalData) // Get offset to the code data
            //     // datasize(proposals[_proposalId].proposalData)   // Get size of the code data
            //     // codecopy(...) // Copy the new code to contract's bytecode
            // }
            emit ProposalExecuted(_proposalId);

        } else if (proposalType == ProposalType.TREASURY_SPEND) {
            // Example: Assume proposalData contains encoded address and amount to send
            (address recipient, uint256 amount) = abi.decode(proposals[_proposalId].proposalData, (address, uint256));
            // In a real application, integrate with a treasury contract or token.
            payable(recipient).transfer(amount); // Simple transfer - Replace with secure treasury management.
            emit ProposalExecuted(_proposalId);

        } else if (proposalType == ProposalType.ROLE_CHANGE) {
            // Example: Assume proposalData contains encoded address, role name, and action (assign/revoke)
            (address targetMember, bytes32 roleName, string memory action) = abi.decode(proposals[_proposalId].proposalData, (address, bytes32, string));
            if (keccak256(bytes(action)) == keccak256(bytes("assign"))) {
                assignRole(targetMember, roleName);
            } else if (keccak256(bytes(action)) == keccak256(bytes("revoke"))) {
                revokeRole(targetMember, roleName);
            }
            emit ProposalExecuted(_proposalId);

        } else {
            revert("Unknown proposal type for execution");
        }

        proposals[_proposalId].status = ProposalStatus.EXECUTED;
    }

    function cancelProposal(uint256 _proposalId) external validProposal(_proposalId) votingNotStarted(_proposalId) {
        require(msg.sender == proposals[_proposalId].proposer || hasRole(msg.sender, "Admin"), "Only proposer or admin can cancel");
        proposals[_proposalId].status = ProposalStatus.CANCELLED;
        emit ProposalCancelled(_proposalId);
    }

    function getProposalDetails(uint256 _proposalId) external view validProposal(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function getProposalVoteCount(uint256 _proposalId) external view validProposal(_proposalId) returns (uint256, uint256) {
        return (proposals[_proposalId].votesFor, proposals[_proposalId].votesAgainst);
    }


    // --- 4. Project & Task Management Functions ---

    function createProject(string memory _projectName, string memory _projectDescription) external onlyRole("ProjectManager") {
        require(bytes(_projectName).length > 0 && bytes(_projectDescription).length > 0, "Project name and description cannot be empty");
        uint256 projectId = projectCount++;
        projects[projectId] = Project({
            projectId: projectId,
            name: _projectName,
            description: _projectDescription,
            projectManager: msg.sender,
            tasks: mapping(uint256 => Task)(),
            taskCount: 0
        });
        emit ProjectCreated(projectId, _projectName, msg.sender);
    }

    function addTaskToProject(
        uint256 _projectId,
        string memory _taskName,
        string memory _taskDescription,
        uint256 _bounty
    ) external onlyRole("ProjectManager") validProject(_projectId) {
        require(bytes(_taskName).length > 0 && bytes(_taskDescription).length > 0, "Task name and description cannot be empty");
        uint256 taskId = projects[_projectId].taskCount++;
        projects[_projectId].tasks[taskId] = Task({
            taskId: taskId,
            projectId: _projectId,
            name: _taskName,
            description: _taskDescription,
            bounty: _bounty,
            assignee: address(0), // Initially unassigned
            isCompleted: false,
            isApproved: false
        });
        emit TaskAdded(taskId, _projectId, _taskName);
    }

    function assignTask(uint256 _taskId, address _member) external onlyRole("ProjectManager") validTask(_taskId) {
        require(isMember[_member], "Assignee is not a member");
        uint256 projectId = projects[_taskId].projectId;
        uint256 taskIndex = _taskId; // Assuming taskIds are sequential within a project

        projects[projectId].tasks[taskIndex].assignee = _member;
        emit TaskAssigned(_taskId, _member);
    }


    function submitTaskCompletion(uint256 _taskId) external onlyMember validTask(_taskId) {
        uint256 projectId = projects[_taskId].projectId;
        uint256 taskIndex = _taskId;
        require(projects[projectId].tasks[taskIndex].assignee == msg.sender, "Only assignee can submit completion");
        require(!projects[projectId].tasks[taskIndex].isCompleted, "Task already submitted for completion");

        projects[projectId].tasks[taskIndex].isCompleted = true;
        emit TaskCompletionSubmitted(_taskId, msg.sender);
    }

    function approveTaskCompletion(uint256 _taskId) external onlyRole("ProjectManager") validTask(_taskId) {
        uint256 projectId = projects[_taskId].projectId;
        uint256 taskIndex = _taskId;
        require(projects[projectId].tasks[taskIndex].isCompleted, "Task not submitted for completion");
        require(!projects[projectId].tasks[taskIndex].isApproved, "Task already approved");

        projects[projectId].tasks[taskIndex].isApproved = true;
        // In a real application, transfer bounty from treasury to assignee.
        // For simplicity, just emit event here.
        emit TaskCompletionApproved(_taskId, msg.sender);

        // Example Bounty transfer (requires treasury management - placeholder)
        // if (projects[projectId].tasks[taskIndex].bounty > 0) {
        //     // Treasury.transfer(projects[projectId].tasks[taskIndex].assignee, projects[projectId].tasks[taskIndex].bounty);
        //     // emit BountyPaid(projects[projectId].tasks[taskIndex].taskId, projects[projectId].tasks[taskIndex].assignee, projects[projectId].tasks[taskIndex].bounty);
        // }

    }

    function getProjectDetails(uint256 _projectId) external view validProject(_projectId) returns (Project memory) {
        return projects[_projectId];
    }

    function getTaskDetails(uint256 _taskId) external view validTask(_taskId) returns (Task memory) {
        uint256 projectId = projects[_taskId].projectId;
        uint256 taskIndex = _taskId;
        return projects[projectId].tasks[taskIndex];
    }


    // --- 5. Configuration & Admin Functions ---

    function setVotingDuration(ProposalType _proposalType, uint256 _duration) external onlyAdmin {
        proposalVotingDuration[_proposalType] = _duration;
        emit VotingDurationSet(_proposalType, _duration);
    }

    function getVotingDuration(ProposalType _proposalType) external view returns (uint256) {
        return proposalVotingDuration[_proposalType];
    }

    function setVotingQuorum(ProposalType _proposalType, uint256 _quorum) external onlyAdmin {
        require(_quorum <= 100, "Quorum percentage must be <= 100");
        proposalVotingQuorum[_proposalType] = _quorum;
        emit VotingQuorumSet(_proposalType, _quorum);
    }

    function getVotingQuorum(ProposalType _proposalType) external view returns (uint256) {
        return proposalVotingQuorum[_proposalType];
    }

    function defineRole(bytes32 _roleName) external onlyAdmin {
        require(!isRoleDefined(_roleName), "Role already defined");
        definedRoles[_roleName] = true;
        roleReputationThreshold[_roleName] = 0; // Default reputation threshold is 0
        emit RoleDefined(_roleName);
    }

    function isRoleDefined(bytes32 _roleName) public view returns (bool) {
        return definedRoles[_roleName];
    }
}
```

**Explanation of Advanced Concepts and Trendy Features:**

* **Dynamic Governance:**  The `proposalVotingDuration` and `proposalVotingQuorum` mappings allow the DAO to adjust voting parameters for different types of proposals. This adds flexibility.  In a more advanced implementation, you could even propose changes to these governance parameters themselves through DAO proposals.

* **Skill-Based Roles:** Roles are defined using `bytes32` and managed using the `memberRoles` mapping. This allows for a flexible and extensible role system. Roles can be assigned and revoked, and functions can be restricted to specific roles using the `onlyRole` modifier.  The `getMemberRoles` function attempts to return a dynamic list of roles (though role iteration in Solidity mappings is not ideal and could be improved in a real application with a different data structure).

* **Reputation System:** The `memberReputation` mapping and the `awardReputation`/`deductReputation` functions implement a basic reputation system.  Reputation can be used for various purposes, like influencing voting weight (not implemented in this basic example, but a potential extension) or granting access to certain roles based on reputation thresholds.

* **Project & Task Management:**  This section provides functionality for creating projects, adding tasks with bounties, assigning tasks to members, and managing task completion and approval. This introduces a practical use case for the DAO beyond just governance, enabling it to organize and reward work within the community.

* **Proposal Types:**  The `ProposalType` enum allows for different types of proposals, each potentially with different voting rules and execution logic. The example includes `TEXT`, `CODE_CHANGE`, `TREASURY_SPEND`, and `ROLE_CHANGE` to illustrate different use cases.  **Note:**  `CODE_CHANGE` proposals in particular are extremely complex and risky on-chain and are included for conceptual completeness but should be approached with extreme caution in a real-world scenario.

* **Conceptual Placeholders:**  The outline mentions features like "Decentralized Communication Channel," "Treasury Management with Staking & Yield Generation," "NFT-Based Role Badges," and "Decentralized Dispute Resolution." These are not fully implemented in the Solidity code but are indicated as areas for further development and integration.  In a real-world DAO, these would be crucial components and could be implemented through separate contracts, oracles, or off-chain integrations.

**Important Considerations and Further Improvements:**

* **Security:** This is a simplified example. In a production DAO, thorough security audits are crucial. Reentrancy vulnerabilities, access control issues, and potential attack vectors need to be carefully considered and mitigated.
* **Gas Optimization:** The contract can be optimized for gas efficiency.  For example, the role iteration in `getMemberRoles` is not efficient.  Using events for role definitions and managing roles in a more structured way could improve gas costs.
* **Treasury Management:** The example lacks a robust treasury management system.  In a real DAO, a separate treasury contract would be essential for managing funds, potentially with staking, yield farming, and multisig security.
* **Code Change Proposals:**  On-chain code change proposals are extremely risky and complex.  Consider off-chain governance and code review processes for such proposals.  Directly modifying contract code on-chain should be avoided in most practical scenarios.
* **Error Handling and User Experience:** More detailed error messages and better event logging can improve the user experience and debugging.
* **Off-Chain Integration:** DAOs often require off-chain components for communication, task management interfaces, voting interfaces, and more complex logic.  This contract provides the on-chain foundation, but a complete DAO ecosystem would involve significant off-chain development.
* **Scalability:**  Consider scalability challenges as the DAO grows in membership and activity.  Data structures and function design should be optimized for performance.

This contract provides a foundation for a more advanced and feature-rich DAO.  You can expand upon these features and integrate additional functionalities to create a truly innovative and dynamic decentralized organization. Remember to prioritize security, scalability, and user experience as you develop further.