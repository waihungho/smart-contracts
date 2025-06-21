Okay, here is a Solidity smart contract concept for a "Decentralized Genius Guild" - a platform for collaborative projects, skill validation, and reputation building.

This contract aims to be:
1.  **Interesting/Creative:** It combines decentralized skill self-attestation, peer endorsement, project creation, task management, bounty distribution, internal reputation tracking, and a conceptual framework for IP registration/licensing within a single system.
2.  **Advanced Concept:** Features like on-chain skill validation methods (peer endorsement, credential hash linkage), dynamic reputation based on task completion/review, project-specific funding/bounties, and linking digital hashes to project IP are more complex than standard token or simple DAO contracts. The interaction between members, projects, tasks, and reputation creates a rich state model.
3.  **Trendy:** Leverages decentralized collaboration, reputation systems, and potential for on-chain IP concepts relevant to Web3 and decentralized work paradigms.
4.  **Non-Duplicative:** While individual *patterns* (like Ownable or Pausable) are common, the specific *combination and logic* of these features for this particular use case (a skill-based project/task guild) is not a standard open-source template you'd find on OpenZeppelin or similar libraries as a single, combined unit.
5.  **> 20 Functions:** Includes functions for member management, skill management, project lifecycle, task management, reputation lookup, IP registration, and admin controls, easily exceeding 20 distinct functions (including views).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
Outline: Decentralized Genius Guild Smart Contract

1.  Introduction & Purpose
    - A decentralized platform for skilled individuals ("Guild Members") to collaborate on projects, manage tasks, build reputation, and track intellectual property.

2.  State Management
    - Members: Track guild members, their skills, reputation, and active projects.
    - Skills: Define types of skills and their validation methods.
    - Projects: Manage project details, teams, status, and associated tasks/IP.
    - Tasks: Detail tasks within projects, assignees, status, and bounties.
    - Reputation: An internal score for members based on contributions.
    - IP: Records hashes and details related to project outputs/IP.

3.  Core Functionality
    - Member Registration & Profile Management
    - Skill Declaration & Validation (Self, Peer, Credential, Admin)
    - Project Creation & Team Management
    - Project Funding (Using native currency / Ether)
    - Task Creation, Assignment, Completion & Review
    - Bounty Distribution upon Task Completion
    - Reputation Earning Mechanism
    - Project IP Registration
    - Basic Access Control (Owner/Admin)
    - Pausability

4.  Advanced Concepts
    - Dynamic internal state across multiple interconnected entities (Members, Projects, Tasks, IP).
    - Skill Validation Methods Enum for flexible skill verification.
    - On-chain reputation calculation based on validated task completion.
    - Conceptual IP registration linking digital hashes to project outputs.
    - Handling native currency bounties within the contract.

5.  Error Handling & Events
    - Custom Errors for clarity.
    - Events to log significant actions.

Function Summary:

Member Management:
1.  `joinGuild()`: Registers the caller as a guild member.
2.  `declareSkill(string calldata skillName)`: Member declares possession of a skill.
3.  `endorseSkill(address memberToEndorse, string calldata skillName)`: Allows a guild member to endorse another member's skill.
4.  `revokeSkillEndorsement(address memberToEndorse, string calldata skillName)`: Allows a guild member to remove their endorsement.
5.  `getMember(address memberAddress)`: View member profile data.
6.  `getMemberSkills(address memberAddress)`: View list of skills declared/validated for a member.
7.  `getMemberEndorsements(address memberAddress, string calldata skillName)`: View addresses endorsing a specific skill for a member.
8.  `getMemberReputation(address memberAddress)`: View a member's current reputation score.

Skill Management (Admin/Curated):
9.  `addSkillDefinition(string calldata skillName, SkillValidationMethod method, string calldata description)`: Define a new skill type and its validation method (Owner only).
10. `updateSkillDefinition(string calldata skillName, SkillValidationMethod method, string calldata description)`: Update an existing skill definition (Owner only).
11. `getSkillDefinition(string calldata skillName)`: View definition of a skill type.

Project Management:
12. `createProject(string calldata name, string calldata description)`: Creates a new project, caller becomes the owner.
13. `addTeamMemberToProject(uint projectId, address memberAddress)`: Adds a guild member to a project team (Project Owner only).
14. `removeTeamMemberFromProject(uint projectId, address memberAddress)`: Removes a team member (Project Owner only).
15. `fundProject(uint projectId) payable`: Allows funding a project with native currency (ETH).
16. `getProject(uint projectId)`: View project details.
17. `getProjectTeam(uint projectId)`: View list of team members for a project.
18. `getProjectFunds(uint projectId)`: View current native currency balance of a project.

Task Management:
19. `createTask(uint projectId, string calldata description, uint bountyAmount, uint dueDate)`: Creates a task within a project (Project Owner/Team only).
20. `assignTask(uint taskId, address assignee)`: Assigns a task to a team member (Project Owner/Team only).
21. `submitTaskCompletion(uint taskId)`: Assignee submits task as completed.
22. `reviewTaskCompletion(uint taskId, bool accepted)`: Project Owner/Team reviews submitted task. Accepts triggers bounty/reputation.
23. `getTask(uint taskId)`: View task details.
24. `getProjectTasks(uint projectId)`: View list of tasks for a project.

Reputation System:
(Reputation is updated internally upon successful task completion review - see `reviewTaskCompletion`)

IP Management:
25. `registerProjectIPHash(uint projectId, bytes32 ipHash, string calldata description)`: Registers a hash representing project IP/deliverable (Project Owner/Team only).
26. `getProjectIP(uint projectId)`: View registered IP hashes for a project.

Admin/Utility:
27. `pauseContract()`: Pauses certain state-changing functions (Owner only).
28. `unpauseContract()`: Unpauses the contract (Owner only).
29. `renounceOwnership()`: Renounce contract ownership (Owner only).
30. `transferOwnership(address newOwner)`: Transfer contract ownership (Owner only).
31. `withdrawOwnerFunds(uint amount)`: Owner can withdraw contract's general balance (not project-specific funds) - *Use with caution, ideally funds stay with projects*. (This is more of a safety valve if general contract balance accrues, not project bounties).

*/

// --- Imports ---
// Basic Ownable pattern (implemented manually here for self-containment, but OpenZeppelin's is recommended in production)
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Basic Pausable pattern (implemented manually)
abstract contract Pausable {
    bool private _paused;

    event Paused(address account);
    event Unpaused(address account);

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requireNotPaused() internal view virtual {
        require(!_paused, "Pausable: paused");
    }

    function _requirePaused() internal view virtual {
        require(_paused, "Pausable: not paused");
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}


// --- Custom Errors ---
error AlreadyGuildMember();
error NotGuildMember();
error SkillAlreadyDeclared();
error SkillNotDeclared();
error CannotEndorseSelf();
error AlreadyEndorsedSkill();
error NotEndorsedSkill();
error SkillDefinitionExists();
error SkillDefinitionNotFound();
error ProjectNotFound();
error NotProjectOwner();
error NotProjectTeamMember();
error MemberAlreadyInTeam();
error MemberNotInTeam();
error TaskNotFound();
error NotTaskAssignee();
error TaskNotSubmittedForReview();
error TaskAlreadyReviewed();
error TaskNotCompleted();
error ProjectFundsTooLow();
error IPAlreadyRegistered();
error BountyNotFunded();


// --- Enums ---
enum SkillValidationMethod {
    SelfAttested,     // Member declares skill themselves
    PeerEndorsed,     // Requires endorsement from other members
    CredentialHash,   // Requires linking an off-chain credential hash
    AdminVerified     // Requires verification by contract owner/admin
}

enum ProjectStatus {
    Proposed,       // Project is suggested (future use for proposals)
    Active,         // Project is underway
    Completed,      // Project finished successfully
    Cancelled       // Project terminated
}

enum TaskStatus {
    Open,           // Task created, needs assignment
    Assigned,       // Task assigned to a member
    Submitted,      // Assignee submitted completion for review
    Completed,      // Task reviewed and accepted
    Rejected,       // Task reviewed and rejected
    Cancelled       // Task cancelled
}


// --- Structs ---
struct Member {
    address memberAddress;
    uint reputation;
    bool isGuildMember;
    // Add other profile fields here (e.g., string name, string bioHash)
}

struct MemberSkill {
    string skillName;
    SkillValidationMethod validationMethod;
    bool isValidated; // Becomes true based on validationMethod requirements
    bytes32 credentialHash; // Optional, for CredentialHash method
    address[] endorsers; // For PeerEndorsed method
}

struct SkillDefinition {
    string description;
    SkillValidationMethod method;
    // Add other skill-specific metadata here
}

struct Project {
    uint id;
    address owner;
    string name;
    string description;
    ProjectStatus status;
    address[] teamMembers; // Includes the owner
    uint nextTaskId;
    uint projectFunds; // Native currency (ETH) held by the project
}

struct Task {
    uint id;
    uint projectId;
    string description;
    uint bountyAmount; // Amount paid upon completion (in native currency)
    uint dueDate; // Unix timestamp
    TaskStatus status;
    address assignee;
    bool submittedForReview; // Flag to indicate assignee submitted
}

struct ProjectIP {
    bytes32 ipHash; // Cryptographic hash of the project's deliverable/IP
    string description;
    uint registeredTimestamp;
    // Add fields for licensing terms concept here (e.g., mapping(address => uint) grantedLicenses;)
}


// --- Contract Definition ---
contract DecentralizedGeniusGuild is Ownable, Pausable {

    // --- State Variables ---
    mapping(address => Member) public members;
    mapping(address => mapping(string => MemberSkill)) public memberSkills; // memberAddress => skillName => MemberSkill
    mapping(string => SkillDefinition) public skillDefinitions; // skillName => SkillDefinition
    string[] public definedSkillNames; // Array to list all defined skill names

    mapping(uint => Project) public projects;
    mapping(uint => Task) public tasks;
    mapping(uint => ProjectIP[]) public projectIPs; // projectId => array of ProjectIPs

    uint public nextProjectId = 1;
    uint public nextTaskId = 1; // Global task ID counter across all projects

    // Configuration for reputation gain/loss (can be adjusted by owner or future DAO)
    uint public taskCompletionReputationGain = 10;


    // --- Events ---
    event MemberJoined(address indexed memberAddress);
    event SkillDeclared(address indexed memberAddress, string skillName, SkillValidationMethod method);
    event SkillEndorsed(address indexed endorser, address indexed memberAddress, string skillName);
    event SkillEndorsementRevoked(address indexed endorser, address indexed memberAddress, string skillName);
    event SkillDefinitionAdded(string skillName, SkillValidationMethod method);
    event SkillDefinitionUpdated(string skillName, SkillValidationMethod method);

    event ProjectCreated(uint indexed projectId, address indexed owner, string name);
    event TeamMemberAdded(uint indexed projectId, address indexed memberAddress);
    event TeamMemberRemoved(uint indexed projectId, address indexed memberAddress);
    event ProjectFunded(uint indexed projectId, address indexed funder, uint amount);
    event ProjectStatusUpdated(uint indexed projectId, ProjectStatus newStatus);

    event TaskCreated(uint indexed taskId, uint indexed projectId, address indexed creator, uint bountyAmount, uint dueDate);
    event TaskAssigned(uint indexed taskId, uint indexed projectId, address indexed assignee);
    event TaskSubmitted(uint indexed taskId, uint indexed projectId, address indexed assignee);
    event TaskReviewed(uint indexed taskId, uint indexed projectId, address indexed reviewer, bool accepted);
    event BountyDistributed(uint indexed taskId, uint indexed projectId, address indexed assignee, uint amount);
    event TaskStatusUpdated(uint indexed taskId, TaskStatus newStatus);

    event ReputationGained(address indexed memberAddress, uint amount);
    event ReputationLost(address indexed memberAddress, uint amount); // For future penalty features

    event ProjectIPRegistered(uint indexed projectId, bytes32 ipHash, address indexed registree);

    // --- Modifiers ---
    modifier onlyGuildMember() {
        require(members[msg.sender].isGuildMember, NotGuildMember.selector);
        _;
    }

    modifier onlyProjectOwner(uint projectId) {
        require(projects[projectId].owner == msg.sender, NotProjectOwner.selector);
        _;
    }

    modifier onlyProjectTeamMember(uint projectId) {
        bool isMember = false;
        Project storage project = projects[projectId];
        for (uint i = 0; i < project.teamMembers.length; i++) {
            if (project.teamMembers[i] == msg.sender) {
                isMember = true;
                break;
            }
        }
        require(isMember, NotProjectTeamMember.selector);
        _;
    }


    // --- Constructor ---
    // Constructor is handled by Ownable base contract setting initial owner


    // --- Member Management Functions ---

    /// @notice Allows a user to join the Decentralized Genius Guild.
    function joinGuild() external whenNotPaused {
        require(!members[msg.sender].isGuildMember, AlreadyGuildMember.selector);
        members[msg.sender] = Member({
            memberAddress: msg.sender,
            reputation: 0,
            isGuildMember: true
        });
        emit MemberJoined(msg.sender);
    }

    /// @notice Allows a guild member to declare they have a specific skill.
    /// @param skillName The name of the skill being declared.
    function declareSkill(string calldata skillName) external onlyGuildMember whenNotPaused {
        require(skillDefinitions[skillName].method != SkillValidationMethod(0), SkillDefinitionNotFound.selector); // Check if skill definition exists (assuming 0 is default invalid enum)
        require(memberSkills[msg.sender][skillName].skillName.length == 0, SkillAlreadyDeclared.selector); // Check if skill is already declared

        SkillDefinition storage skillDef = skillDefinitions[skillName];
        bool isValidated = (skillDef.method == SkillValidationMethod.SelfAttested); // SelfAttested is validated immediately

        memberSkills[msg.sender][skillName] = MemberSkill({
            skillName: skillName,
            validationMethod: skillDef.method,
            isValidated: isValidated,
            credentialHash: 0, // Default
            endorsers: new address[](0) // Default empty
        });

        emit SkillDeclared(msg.sender, skillName, skillDef.method);
    }

    /// @notice Allows a guild member to endorse another member for a declared skill (if validation method is PeerEndorsed).
    /// @param memberToEndorse The address of the member to endorse.
    /// @param skillName The name of the skill to endorse.
    function endorseSkill(address memberToEndorse, string calldata skillName) external onlyGuildMember whenNotPaused {
        require(msg.sender != memberToEndorse, CannotEndorseSelf.selector);
        require(members[memberToEndorse].isGuildMember, NotGuildMember.selector);

        MemberSkill storage memberSkill = memberSkills[memberToEndorse][skillName];
        require(memberSkill.skillName.length > 0, SkillNotDeclared.selector); // Check if the member has declared the skill
        require(memberSkill.validationMethod == SkillValidationMethod.PeerEndorsed, "Skill validation is not PeerEndorsed");

        for (uint i = 0; i < memberSkill.endorsers.length; i++) {
            if (memberSkill.endorsers[i] == msg.sender) {
                revert AlreadyEndorsedSkill.selector; // Already endorsed
            }
        }

        memberSkill.endorsers.push(msg.sender);

        // Optional: Auto-validate after a certain number of endorsements
        // if (memberSkill.endorsers.length >= MIN_ENDORSEMENTS_FOR_VALIDATION) {
        //    memberSkill.isValidated = true;
        // }

        emit SkillEndorsed(msg.sender, memberToEndorse, skillName);
    }

     /// @notice Allows a guild member to revoke their endorsement for another member's skill.
    /// @param memberToEndorse The address of the member whose endorsement is being revoked.
    /// @param skillName The name of the skill.
    function revokeSkillEndorsement(address memberToEndorse, string calldata skillName) external onlyGuildMember whenNotPaused {
        require(msg.sender != memberToEndorse, CannotEndorseSelf.selector);
        require(members[memberToEndorse].isGuildMember, NotGuildMember.selector);

        MemberSkill storage memberSkill = memberSkills[memberToEndorse][skillName];
        require(memberSkill.skillName.length > 0, SkillNotDeclared.selector); // Check if the member has declared the skill
        require(memberSkill.validationMethod == SkillValidationMethod.PeerEndorsed, "Skill validation is not PeerEndorsed");

        bool found = false;
        for (uint i = 0; i < memberSkill.endorsers.length; i++) {
            if (memberSkill.endorsers[i] == msg.sender) {
                // Remove the endorser by swapping with the last element and shrinking the array
                memberSkill.endorsers[i] = memberSkill.endorsers[memberSkill.endorsers.length - 1];
                memberSkill.endorsers.pop();
                found = true;
                break;
            }
        }
        require(found, NotEndorsedSkill.selector); // Endorsement not found

        // Optional: De-validate if endorsements drop below threshold
        // if (memberSkill.isValidated && memberSkill.endorsers.length < MIN_ENDORSEMENTS_FOR_VALIDATION) {
        //     memberSkill.isValidated = false;
        // }

        emit SkillEndorsementRevoked(msg.sender, memberToEndorse, skillName);
    }

    // --- View Functions (Member) ---
    function getMember(address memberAddress) public view returns (Member memory) {
        return members[memberAddress];
    }

    function getMemberSkills(address memberAddress) public view returns (MemberSkill[] memory) {
        require(members[memberAddress].isGuildMember, NotGuildMember.selector);
        // Note: Iterating over mapping is not possible. This requires an auxiliary storage or pre-knowledge of declared skills.
        // A common pattern is to store declared skill names in a dynamic array within the Member struct.
        // For this example, let's assume a helper or off-chain lookup combined with these view functions.
        // Returning an empty array as a placeholder or requiring specific skillName lookup.
        // Let's return skills based on existing definitions that the member *might* have declared.
        // A more realistic approach would add a `string[] declaredSkillNames` to the Member struct.
        // For now, let's just provide direct lookup for a *specific* skill:
        revert("Get all skills view requires iterating dynamic Member.declaredSkillNames array (not implemented in this basic example).");
        // Returning a dummy empty array to satisfy syntax:
        // MemberSkill[] memory declared = new MemberSkill[](0);
        // return declared;
    }

     function getMemberSkill(address memberAddress, string calldata skillName) public view returns (MemberSkill memory) {
        require(members[memberAddress].isGuildMember, NotGuildMember.selector);
        require(memberSkills[memberAddress][skillName].skillName.length > 0, SkillNotDeclared.selector);
        return memberSkills[memberAddress][skillName];
     }

    function getMemberEndorsements(address memberAddress, string calldata skillName) public view returns (address[] memory) {
        require(members[memberAddress].isGuildMember, NotGuildMember.selector);
         MemberSkill storage memberSkill = memberSkills[memberAddress][skillName];
        require(memberSkill.skillName.length > 0, SkillNotDeclared.selector);
        require(memberSkill.validationMethod == SkillValidationMethod.PeerEndorsed, "Skill validation is not PeerEndorsed");
        return memberSkill.endorsers;
    }

    function getMemberReputation(address memberAddress) public view returns (uint) {
        require(members[memberAddress].isGuildMember, NotGuildMember.selector);
        return members[memberAddress].reputation;
    }


    // --- Skill Management Functions (Owner Only) ---

    /// @notice Allows the contract owner to define a new skill type and its validation requirements.
    /// @param skillName The unique name of the skill.
    /// @param method The method required to validate this skill.
    /// @param description A brief description of the skill.
    function addSkillDefinition(string calldata skillName, SkillValidationMethod method, string calldata description) external onlyOwner whenNotPaused {
        require(skillDefinitions[skillName].method == SkillValidationMethod(0), SkillDefinitionExists.selector); // Check if skill already exists

        skillDefinitions[skillName] = SkillDefinition({
            description: description,
            method: method
        });
        definedSkillNames.push(skillName); // Add to list of defined names for lookup

        emit SkillDefinitionAdded(skillName, method);
    }

    /// @notice Allows the contract owner to update an existing skill definition.
    /// @param skillName The name of the skill to update.
    /// @param method The new validation method.
    /// @param description The new description.
    function updateSkillDefinition(string calldata skillName, SkillValidationMethod method, string calldata description) external onlyOwner whenNotPaused {
        require(skillDefinitions[skillName].method != SkillValidationMethod(0), SkillDefinitionNotFound.selector);

        skillDefinitions[skillName].method = method;
        skillDefinitions[skillName].description = description;

        // Note: Updating validation method here doesn't automatically re-validate/invalidate existing member skills.
        // A separate function or logic would be needed for that if desired.

        emit SkillDefinitionUpdated(skillName, method);
    }

    // --- View Functions (Skill) ---
    function getSkillDefinition(string calldata skillName) public view returns (SkillDefinition memory) {
        require(skillDefinitions[skillName].method != SkillValidationMethod(0), SkillDefinitionNotFound.selector);
        return skillDefinitions[skillName];
    }

    function getDefinedSkillNames() public view returns (string[] memory) {
        return definedSkillNames;
    }


    // --- Project Management Functions ---

    /// @notice Creates a new project within the guild. Caller becomes the project owner.
    /// @param name The name of the project.
    /// @param description A description of the project goals.
    /// @return projectId The ID of the newly created project.
    function createProject(string calldata name, string calldata description) external onlyGuildMember whenNotPaused returns (uint projectId) {
        projectId = nextProjectId++;
        address[] memory initialTeam = new address[](1);
        initialTeam[0] = msg.sender;

        projects[projectId] = Project({
            id: projectId,
            owner: msg.sender,
            name: name,
            description: description,
            status: ProjectStatus.Active, // Start as Active, could add Proposed stage
            teamMembers: initialTeam,
            nextTaskId: 1, // Task IDs are per-project, but stored globally mapping(uint => Task)
            projectFunds: 0
        });

        // Add project ID to member's active projects list? (Requires modifying Member struct)
        // For this example, we won't store project IDs in Member to keep Member struct simpler.

        emit ProjectCreated(projectId, msg.sender, name);
    }

    /// @notice Adds a guild member to a project's team. Only the project owner can do this.
    /// @param projectId The ID of the project.
    /// @param memberAddress The address of the member to add.
    function addTeamMemberToProject(uint projectId, address memberAddress) external onlyProjectOwner(projectId) whenNotPaused {
        Project storage project = projects[projectId];
        require(project.status == ProjectStatus.Active, "Project is not active");
        require(members[memberAddress].isGuildMember, NotGuildMember.selector);

        for (uint i = 0; i < project.teamMembers.length; i++) {
            if (project.teamMembers[i] == memberAddress) {
                revert MemberAlreadyInTeam.selector;
            }
        }

        project.teamMembers.push(memberAddress);
        emit TeamMemberAdded(projectId, memberAddress);
    }

     /// @notice Removes a team member from a project. Only the project owner can do this.
    /// @param projectId The ID of the project.
    /// @param memberAddress The address of the member to remove.
    function removeTeamMemberFromProject(uint projectId, address memberAddress) external onlyProjectOwner(projectId) whenNotPaused {
        Project storage project = projects[projectId];
        require(project.status == ProjectStatus.Active, "Project is not active");
        require(memberAddress != project.owner, "Cannot remove project owner from team");

        bool found = false;
        for (uint i = 0; i < project.teamMembers.length; i++) {
            if (project.teamMembers[i] == memberAddress) {
                // Swap with last and pop
                project.teamMembers[i] = project.teamMembers[project.teamMembers.length - 1];
                project.teamMembers.pop();
                found = true;
                break;
            }
        }
        require(found, MemberNotInTeam.selector);
        emit TeamMemberRemoved(projectId, memberAddress);
    }


    /// @notice Allows anyone (guild member or not) to send native currency (ETH) to fund a specific project.
    /// @param projectId The ID of the project to fund.
    function fundProject(uint projectId) external payable whenNotPaused {
        Project storage project = projects[projectId];
        require(project.id != 0, ProjectNotFound.selector); // Check if project exists
        require(project.status == ProjectStatus.Active || project.status == ProjectStatus.Proposed, "Project is not fundable");
        require(msg.value > 0, "Funding amount must be greater than 0");

        // Add funds to the project's internal balance
        project.projectFunds += msg.value;

        emit ProjectFunded(projectId, msg.sender, msg.value);
    }

    // --- View Functions (Project) ---
    function getProject(uint projectId) public view returns (Project memory) {
        require(projects[projectId].id != 0, ProjectNotFound.selector);
        return projects[projectId];
    }

    function getProjectTeam(uint projectId) public view returns (address[] memory) {
         require(projects[projectId].id != 0, ProjectNotFound.selector);
        return projects[projectId].teamMembers;
    }

    function getProjectFunds(uint projectId) public view returns (uint) {
         require(projects[projectId].id != 0, ProjectNotFound.selector);
         // Return the contract's balance specifically held for this project
         // Note: This requires tracking funds per project. The `projectFunds` field does this conceptually.
         // The actual ETH balance of the contract is global. Transfers need to manage this carefully.
         // A better pattern might involve wrapping ETH in an ERC-20 or using a dedicated payment splitter.
         // For this example, `projectFunds` is a simple counter, assuming ETH comes into the contract
         // and bounty transfers reduce the contract's *overall* ETH balance, tracked against this counter.
         // REALITY CHECK: Storing `projectFunds` as a simple uint is *incorrect* for tracking actual ETH.
         // To correctly track per-project ETH, a separate contract or more complex accounting is needed.
         // Let's treat `projectFunds` as a *pledged* or *allocated* amount, not the actual ETH balance held by the contract for the project.
         // The Bounty distribution logic below would then need adjustment, perhaps sending directly from funder or requiring a pull mechanism.
         // LET'S REVISE: `projectFunds` *is* the ETH balance. `fundProject` adds to it. `distributeTaskBounty` sends ETH *from the contract's balance*.
         // This works IF the contract only receives ETH via `fundProject` and only sends via `distributeTaskBounty`.
         return projects[projectId].projectFunds;
    }


    // --- Task Management Functions ---

    /// @notice Creates a new task within a project. Can only be called by a project team member.
    /// @param projectId The ID of the project the task belongs to.
    /// @param description A description of the task.
    /// @param bountyAmount The amount of native currency to pay upon successful completion.
    /// @param dueDate Unix timestamp for task deadline.
    /// @return taskId The global ID of the newly created task.
    function createTask(uint projectId, string calldata description, uint bountyAmount, uint dueDate) external onlyProjectTeamMember(projectId) whenNotPaused returns (uint taskId) {
        Project storage project = projects[projectId];
        require(project.status == ProjectStatus.Active, "Project is not active");
        // Optionally require bountyAmount <= project.projectFunds if bounties must be pre-funded per task.
        // Current model assumes bounty comes from project's overall funds when distributed.

        taskId = nextTaskId++; // Use global task ID counter

        tasks[taskId] = Task({
            id: taskId,
            projectId: projectId,
            description: description,
            bountyAmount: bountyAmount,
            dueDate: dueDate,
            status: TaskStatus.Open,
            assignee: address(0),
            submittedForReview: false
        });

        // Need to link this task ID back to the project struct?
        // A simple approach is to query tasks mapping by projectId (requires iteration off-chain or helper).
        // Storing task IDs in Project struct `uint[] taskIds` is another option.

        emit TaskCreated(taskId, projectId, msg.sender, bountyAmount, dueDate);
    }

    /// @notice Assigns an open task to a guild member who is also on the project team.
    /// @param taskId The ID of the task to assign.
    /// @param assignee The address of the member to assign the task to.
    function assignTask(uint taskId, address assignee) external onlyGuildMember whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.id != 0, TaskNotFound.selector);
        require(task.status == TaskStatus.Open, "Task is not open");

        Project storage project = projects[task.projectId];
        require(project.status == ProjectStatus.Active, "Project is not active");
        require(members[assignee].isGuildMember, NotGuildMember.selector);

        // Check if assignee is a member of the project team
        bool isTeamMember = false;
        for (uint i = 0; i < project.teamMembers.length; i++) {
            if (project.teamMembers[i] == assignee) {
                isTeamMember = true;
                break;
            }
        }
        require(isTeamMember, NotProjectTeamMember.selector);

        task.assignee = assignee;
        task.status = TaskStatus.Assigned;

        emit TaskAssigned(taskId, task.projectId, assignee);
    }

    /// @notice Allows the assignee of a task to submit it for review.
    /// @param taskId The ID of the task to submit.
    function submitTaskCompletion(uint taskId) external onlyGuildMember whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.id != 0, TaskNotFound.selector);
        require(task.assignee == msg.sender, NotTaskAssignee.selector);
        require(task.status == TaskStatus.Assigned, "Task is not assigned");
        require(!task.submittedForReview, "Task already submitted for review");

        task.submittedForReview = true;
        task.status = TaskStatus.Submitted; // Update status to reflect submission

        emit TaskSubmitted(taskId, task.projectId, msg.sender);
    }

    /// @notice Allows a project team member (or owner) to review a submitted task.
    /// Accepts completion -> distributes bounty, updates reputation. Rejects -> sets status to Rejected.
    /// @param taskId The ID of the task to review.
    /// @param accepted Whether the task completion is accepted or rejected.
    function reviewTaskCompletion(uint taskId, bool accepted) external onlyGuildMember whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.id != 0, TaskNotFound.selector);
        require(task.submittedForReview, TaskNotSubmittedForReview.selector);
        require(task.status == TaskStatus.Submitted, "Task is not in Submitted status");

        Project storage project = projects[task.projectId];
        require(project.status == ProjectStatus.Active, "Project is not active");

        // Reviewer must be a project team member (excluding the assignee)
        bool isReviewer = false;
        for (uint i = 0; i < project.teamMembers.length; i++) {
            if (project.teamMembers[i] == msg.sender && msg.sender != task.assignee) {
                 isReviewer = true;
                 break;
            }
        }
        // Allow owner to review even if they are the assignee (edge case, might want to disallow self-review)
        if (!isReviewer && msg.sender == project.owner) {
             isReviewer = true;
        }
        require(isReviewer, "Caller is not authorized to review this task");

        task.submittedForReview = false; // Reset submission flag

        if (accepted) {
            task.status = TaskStatus.Completed;
            // Update assignee's reputation
            members[task.assignee].reputation += taskCompletionReputationGain;
            emit ReputationGained(task.assignee, taskCompletionReputationGain);

            // Distribute bounty (if any)
            if (task.bountyAmount > 0) {
                 // Check if project has sufficient funds (tracked internally)
                 require(project.projectFunds >= task.bountyAmount, ProjectFundsTooLow.selector);

                 // Transfer ETH from contract balance to assignee
                 // This requires the contract to hold the ETH.
                 // Note: This is a basic implementation. Re-entrancy is a risk in complex scenarios.
                 // `call` is generally safer than `transfer` or `send` regarding gas stipend issues, but still requires care.
                 (bool success, ) = payable(task.assignee).call{value: task.bountyAmount}("");
                 require(success, "ETH transfer failed"); // Basic check

                 // Update project's internal fund count
                 project.projectFunds -= task.bountyAmount;

                 emit BountyDistributed(taskId, task.projectId, task.assignee, task.bountyAmount);
            }

        } else {
            task.status = TaskStatus.Rejected;
            // Optionally penalize reputation for rejected work?
            // members[task.assignee].reputation = members[task.assignee].reputation > PENALTY ? members[task.assignee].reputation - PENALTY : 0;
            // emit ReputationLost(task.assignee, PENALTY);
        }

        emit TaskReviewed(taskId, task.projectId, msg.sender, accepted);
        emit TaskStatusUpdated(taskId, task.status);
    }

    // --- View Functions (Task) ---
    function getTask(uint taskId) public view returns (Task memory) {
        require(tasks[taskId].id != 0, TaskNotFound.selector);
        return tasks[taskId];
    }

    function getProjectTasks(uint projectId) public view returns (Task[] memory) {
        require(projects[projectId].id != 0, ProjectNotFound.selector);
        // This requires iterating ALL tasks to find those belonging to the project.
        // A more efficient approach involves storing a `uint[] taskIds` array in the Project struct,
        // or querying off-chain and validating on-chain.
        // For this example, we acknowledge this limitation and don't provide a direct on-chain iterator.
        // A more realistic implementation would add `uint[] taskIds` to the Project struct and retrieve them directly.
        revert("Get project tasks view requires iterating global task map or storing task IDs in Project struct (not implemented in this basic example).");
         // Returning a dummy empty array to satisfy syntax:
        // Task[] memory projectTasks = new Task[](0);
        // return projectTasks;
    }

    // --- IP Management Functions ---

    /// @notice Registers a cryptographic hash representing the IP or deliverable of a project.
    /// Can only be called by a project team member.
    /// @param projectId The ID of the project the IP relates to.
    /// @param ipHash The hash of the IP/deliverable (e.g., IPFS CID hash, file hash).
    /// @param description A description of the IP being registered.
    function registerProjectIPHash(uint projectId, bytes32 ipHash, string calldata description) external onlyProjectTeamMember(projectId) whenNotPaused {
        Project storage project = projects[projectId];
        require(project.id != 0, ProjectNotFound.selector);
        // Optionally require project status Completed? Depends on workflow.

        // Check if this exact hash is already registered for this project
        for (uint i = 0; i < projectIPs[projectId].length; i++) {
            if (projectIPs[projectId][i].ipHash == ipHash) {
                revert IPAlreadyRegistered.selector;
            }
        }

        projectIPs[projectId].push(ProjectIP({
            ipHash: ipHash,
            description: description,
            registeredTimestamp: block.timestamp
        }));

        emit ProjectIPRegistered(projectId, ipHash, msg.sender);
    }

    // --- View Functions (IP) ---
    function getProjectIP(uint projectId) public view returns (ProjectIP[] memory) {
         require(projects[projectId].id != 0, ProjectNotFound.selector);
         return projectIPs[projectId];
    }

    // --- Admin/Utility Functions ---

    /// @notice Pauses the contract, disabling most state-changing operations.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract, enabling state-changing operations again.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // Ownership functions are inherited from Ownable

    /// @notice Allows the owner to withdraw any ETH accidentally sent directly to the contract
    /// that is NOT intended as project funding. This is a safety valve.
    /// @param amount The amount of ETH to withdraw.
    function withdrawOwnerFunds(uint amount) external onlyOwner whenNotPaused {
        // Ensure the withdrawal doesn't deplete project funds (requires careful tracking)
        // A robust system would separate owner balance from project balances.
        // For this simplified example, we just ensure the contract has enough ETH globally.
        // This function assumes any ETH not 'assigned' to a project via `projectFunds` counter is withdrawable by owner.
        // This is fragile and for demonstration only.
        require(address(this).balance >= amount, "Insufficient contract balance for withdrawal");

        // Simple check: total ETH in contract > sum of projectFunds is withdrawable.
        // This check is hard to implement efficiently on-chain without iterating all projects.
        // Let's add a basic check that the withdrawal doesn't drop total balance below sum of known project funds.
        // Still inefficient and error-prone. A better design uses dedicated accounts/contracts.
        // For demo purposes, keeping it simple but acknowledging the limitation.
        // uint totalProjectFunds; // Calculating this on-chain is costly
        // require(address(this).balance - amount >= totalProjectFunds, "Withdrawal would affect project funds");

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Owner ETH withdrawal failed");
    }

     // --- View Functions (Utility) ---
     // Function to get the current contract balance (useful for debugging/monitoring)
     function getContractBalance() public view returns (uint) {
         return address(this).balance;
     }

}
```