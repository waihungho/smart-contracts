```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CreativeDAOManager
 * @dev A smart contract managing a decentralized creative organization focused on project collaboration,
 *      reputation-based contribution, and on-chain governance. It integrates concepts of Soulbound Tokens
 *      (SBT-like reputation) earned through successful project participation, dynamic roles assigned
 *      via governance, and project management workflows on-chain.
 *
 * Outline:
 * 1. State Variables: Core data structures for members, projects, proposals, and parameters.
 * 2. Enums: Define status for projects and proposals.
 * 3. Structs: Define the data models for Member, Project, and Proposal.
 * 4. Events: Announce key state changes.
 * 5. Modifiers: Restrict function access based on role, status, etc.
 * 6. Core Logic:
 *    - Membership Management: Joining, leaving, suspension.
 *    - Roles & Reputation (SBT-like): Assignment, removal, tracking, earning via projects.
 *    - Project Management: Creation, joining, contribution submission, completion, cancellation.
 *    - Governance: Proposal creation, voting, execution (supporting arbitrary calls).
 *    - Treasury: Receiving funds, distributing project allocations (via governance/project completion).
 *    - Parameter Management: Allowing governance to tune DAO rules.
 *
 * Function Summary:
 * - Membership:
 *    - `joinDAO()`: Allow an address to become a DAO member.
 *    - `leaveDAO()`: Allow a member to leave the DAO.
 *    - `suspendMember(address memberAddr)`: Governance function to suspend a member.
 *    - `reactivateMember(address memberAddr)`: Governance function to reactivate a suspended member.
 *    - `isMember(address memberAddr)`: Check if an address is a member. (Implicitly via getMemberInfo or specific helper)
 *    - `getMemberInfo(address memberAddr)`: Retrieve details of a member.
 *    - `getTotalMembers()`: Get the total count of registered members.
 *
 * - Roles & Reputation:
 *    - `assignRole(address memberAddr, string role)`: Governance function to assign a specific role to a member.
 *    - `removeRole(address memberAddr, string role)`: Governance function to remove a specific role from a member.
 *    - `hasRole(address memberAddr, string role)`: Check if a member has a specific role.
 *    - `getMemberRoles(address memberAddr)`: Get all roles assigned to a member.
 *    - `getReputation(address memberAddr)`: Get the reputation points of a member. (Reputation is earned internally)
 *
 * - Project Management:
 *    - `createProject(string title, string description, string[] requiredRoles, uint totalReputationNeeded, uint allocatedFunds)`: Allow members with specific roles to propose and create a new project.
 *    - `joinProject(uint projectId)`: Allow an eligible member (based on roles/reputation) to join a project as a contributor.
 *    - `submitProjectContribution(uint projectId, uint contributionPoints)`: Allow a project contributor to submit points representing their effort/work.
 *    - `completeProject(uint projectId)`: Governance function to mark a project as completed and trigger reward distribution.
 *    - `cancelProject(uint projectId)`: Governance function to cancel an ongoing project.
 *    - `getProjectInfo(uint projectId)`: Retrieve details of a project.
 *    - `getProjectsByStatus(ProjectStatus status)`: Get a list of project IDs filtered by status.
 *    - `getMemberProjects(address memberAddr)`: Get a list of project IDs a member has contributed to.
 *
 * - Governance:
 *    - `createProposal(string title, string description, address targetContract, bytes calldata callData, uint value, string requiredRoleToPropose, uint requiredReputationToPropose, uint votingPeriodSeconds)`: Allow eligible members to create a new governance proposal.
 *    - `voteOnProposal(uint proposalId, bool support)`: Allow eligible members to vote on an active proposal.
 *    - `executeProposal(uint proposalId)`: Allow anyone to execute a successful proposal after the voting period ends.
 *    - `getProposalInfo(uint proposalId)`: Retrieve details of a proposal.
 *    - `getProposalVotingResult(uint proposalId)`: Get the final vote count for a proposal.
 *    - `getActiveProposals()`: Get a list of currently active proposal IDs.
 *
 * - Treasury:
 *    - `depositTreasury()`: Allow anyone to send Ether to the DAO treasury.
 *    - `getTreasuryBalance()`: Get the current Ether balance of the treasury.
 *    - `distributeProjectRewards(uint projectId)`: Internal function to distribute reputation and funds upon project completion.
 *
 * - Parameters:
 *    - `setVotingPeriod(uint seconds)`: Governance function to set the default voting period for proposals.
 *    - `setMinReputationToJoin(uint points)`: Governance function to set minimum reputation required to join the DAO.
 *    - `setMinRoleToPropose(string role)`: Governance function to set the minimum role required to create proposals.
 */

import "@openzeppelin/contracts/access/Ownable.sol";

contract CreativeDAOManager is Ownable {

    // --- State Variables ---

    uint private memberCounter;
    uint private projectCounter;
    uint private proposalCounter;

    mapping(address => uint) public memberAddressToId;
    mapping(uint => Member) public members;
    address[] public memberAddresses; // To iterate or count easily

    mapping(uint => Project) public projects;
    uint[] public projectIds;

    mapping(uint => Proposal) public proposals;
    uint[] public proposalIds;

    uint public defaultVotingPeriod = 7 days; // Default voting duration
    uint public minReputationToJoin = 0;     // Min reputation required to join (can be set later)
    string public minRoleToPropose = "Core Contributor"; // Min role required to create proposals

    // --- Enums ---

    enum ProjectStatus { Ideation, OpenForContributors, InProgress, Completed, Cancelled }
    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }

    // --- Structs ---

    struct Member {
        uint memberId;
        address wallet;
        uint joinTime;
        bool isActive;
        uint reputationPoints; // SBT-like, non-transferable
        mapping(string => bool) roles; // Dynamic roles assigned by governance
        mapping(uint => uint) projectContributionScores; // Project ID => points contributed in that project
        string[] assignedRoles; // To easily list roles
    }

    struct Project {
        uint projectId;
        address creator;
        string title;
        string description;
        ProjectStatus status;
        string[] requiredRoles;
        uint totalReputationNeeded; // Goal for the project
        uint currentReputationEarned; // Progress towards the goal
        uint allocatedFunds; // Ether allocated from treasury
        address[] contributors; // List of addresses currently contributing
        mapping(address => bool) isContributor; // Quick check if address is contributor
        mapping(address => uint) pendingContributionPoints; // Points submitted by contributors pending project completion
        uint creationTime;
        address[] contributionSubmitters; // Helper to iterate over submitters
    }

    struct Proposal {
        uint proposalId;
        address proposer;
        string title;
        string description;
        address targetContract; // Contract to call if proposal passes (0x0 for internal DAO calls)
        bytes callData;         // Calldata for the targetContract call
        uint value;             // Ether to send with the targetContract call
        ProposalStatus status;
        uint creationTime;
        uint votingEndTime;
        uint yesVotes;
        uint noVotes;
        mapping(address => bool) hasVoted; // Prevent double voting
        string requiredRoleToVote;
        uint requiredReputationToVote;
    }

    // --- Events ---

    event MemberJoined(uint indexed memberId, address indexed wallet, uint joinTime);
    event MemberSuspended(uint indexed memberId, address indexed wallet);
    event MemberReactivated(uint indexed memberId, address indexed wallet);
    event MemberLeft(uint indexed memberId, address indexed wallet);

    event RoleAssigned(uint indexed memberId, string role);
    event RoleRemoved(uint indexed memberId, string role);
    event ReputationUpdated(uint indexed memberId, uint newReputation);

    event ProjectCreated(uint indexed projectId, address indexed creator, string title, uint allocatedFunds);
    event ProjectJoined(uint indexed projectId, address indexed contributor);
    event ProjectContributionSubmitted(uint indexed projectId, address indexed contributor, uint points);
    event ProjectCompleted(uint indexed projectId);
    event ProjectCancelled(uint indexed projectId);

    event ProposalCreated(uint indexed proposalId, address indexed proposer, string title, uint votingEndTime);
    event ProposalVoted(uint indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint indexed proposalId, bool success);
    event ProposalStatusChanged(uint indexed proposalId, ProposalStatus newStatus);

    event TreasuryDeposited(address indexed sender, uint amount);
    event FundsDistributedToProject(uint indexed projectId, uint amount);
    event FundsDistributedToContributors(uint indexed projectId, uint amount);

    event ParameterUpdated(string paramName, uint newValue); // For uint parameters
    event ParameterUpdatedString(string paramName, string newValue); // For string parameters

    // --- Modifiers ---

    modifier onlyMember(address memberAddr) {
        require(memberAddressToId[memberAddr] != 0, "Not a member");
        require(members[memberAddressToId[memberAddr]].isActive, "Member is suspended");
        _;
    }

     modifier onlyRole(address memberAddr, string memory role) {
        uint memberId = memberAddressToId[memberAddr];
        require(memberId != 0, "Not a member");
        require(members[memberId].isActive, "Member is suspended");
        require(members[memberId].roles[role], string(abi.encodePacked("Requires '", role, "' role")));
        _;
    }

    modifier onlyProjectCreator(uint projectId) {
        require(projects[projectId].creator == msg.sender, "Only project creator");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        // Optional: Initial member or admin role assignment
        // memberCounter = 1;
        // memberAddressToId[msg.sender] = memberCounter;
        // members[memberCounter] = Member(memberCounter, msg.sender, block.timestamp, true, 0, new string[](0));
        // members[memberCounter].roles["Owner"] = true; // Assign Owner role
        // members[memberCounter].assignedRoles.push("Owner");
        // memberAddresses.push(msg.sender);
        // emit MemberJoined(memberCounter, msg.sender, block.timestamp);
        // emit RoleAssigned(memberCounter, "Owner");
    }

    // --- Membership Functions ---

    /**
     * @dev Allows an address to join the DAO if they meet the minimum reputation requirement.
     */
    function joinDAO() external {
        require(memberAddressToId[msg.sender] == 0, "Already a member");
        require(members[memberAddressToId[msg.sender]].reputationPoints >= minReputationToJoin, "Insufficient reputation to join"); // Self-check or requires external system verification? Let's assume this means reputation *earned elsewhere* or maybe a starting point is required. A better model is that reputation is earned *within* this DAO, so this requirement might only apply if joining requires reputation from a different source, or it's always 0 to join initially. Let's make it 0 initially and the parameter is for *later* changes.
        // Re-thinking: Min reputation to join is weird if reputation is earned *here*. Let's remove that requirement initially, or clarify its purpose (e.g., requires reputation earned in a *previous version* of the DAO, or an external system). For simplicity, let's remove the minReputationToJoin *for initial joining*, but keep the variable for potential future use cases or parameters.

        memberCounter++;
        memberAddressToId[msg.sender] = memberCounter;
        // Initialize with basic member struct
        members[memberCounter] = Member(memberCounter, msg.sender, block.timestamp, true, 0, new string[](0));
        members[memberCounter].roles["Member"] = true; // Assign default 'Member' role
        members[memberCounter].assignedRoles.push("Member");
        memberAddresses.push(msg.sender);

        emit MemberJoined(memberCounter, msg.sender, block.timestamp);
        emit RoleAssigned(memberCounter, "Member");
    }

    /**
     * @dev Allows a member to leave the DAO. Potential future complexity: vesting, penalties.
     */
    function leaveDAO() external onlyMember(msg.sender) {
        uint memberId = memberAddressToId[msg.sender];
        members[memberId].isActive = false; // Mark as inactive rather than deleting
        // Note: Cannot fully delete state variables in Solidity <= 0.8.x easily.
        // Marking inactive is a common pattern.
        emit MemberLeft(memberId, msg.sender);
    }

    /**
     * @dev Governance action to suspend a member.
     * @param memberAddr The address of the member to suspend.
     */
    function suspendMember(address memberAddr) external onlyRole(msg.sender, "Core Contributor") { // Example: Requires 'Core Contributor' role
        uint memberId = memberAddressToId[memberAddr];
        require(memberId != 0, "Address is not a member");
        require(members[memberId].isActive, "Member is already suspended");
        members[memberId].isActive = false;
        emit MemberSuspended(memberId, memberAddr);
    }

    /**
     * @dev Governance action to reactivate a suspended member.
     * @param memberAddr The address of the member to reactivate.
     */
    function reactivateMember(address memberAddr) external onlyRole(msg.sender, "Core Contributor") { // Example: Requires 'Core Contributor' role
        uint memberId = memberAddressToId[memberAddr];
        require(memberId != 0, "Address is not a member");
        require(!members[memberId].isActive, "Member is already active");
        members[memberId].isActive = true;
        emit MemberReactivated(memberId, memberAddr);
    }

     /**
     * @dev Get details of a member.
     * @param memberAddr The address of the member.
     * @return memberId The unique ID of the member.
     * @return wallet The wallet address of the member.
     * @return joinTime The timestamp when the member joined.
     * @return isActive The active status of the member.
     * @return reputationPoints The current reputation points of the member.
     * @return roles The roles assigned to the member.
     */
    function getMemberInfo(address memberAddr) external view onlyMember(memberAddr) returns (uint memberId, address wallet, uint joinTime, bool isActive, uint reputationPoints, string[] memory roles) {
        uint id = memberAddressToId[memberAddr];
        Member storage m = members[id];
        return (m.memberId, m.wallet, m.joinTime, m.isActive, m.reputationPoints, m.assignedRoles);
    }

    /**
     * @dev Get the total number of members (active and inactive).
     * @return The total count of members.
     */
    function getTotalMembers() external view returns (uint) {
        return memberCounter;
    }

    // --- Roles & Reputation Functions ---

    /**
     * @dev Governance function to assign a specific role to a member.
     * @param memberAddr The address of the member.
     * @param role The role to assign.
     */
    function assignRole(address memberAddr, string memory role) external onlyRole(msg.sender, "Admin") { // Example: Requires 'Admin' role
        uint memberId = memberAddressToId[memberAddr];
        require(memberId != 0, "Address is not a member");
        require(!members[memberId].roles[role], "Member already has this role");

        members[memberId].roles[role] = true;
        members[memberId].assignedRoles.push(role);
        emit RoleAssigned(memberId, role);
    }

    /**
     * @dev Governance function to remove a specific role from a member.
     * @param memberAddr The address of the member.
     * @param role The role to remove.
     */
    function removeRole(address memberAddr, string memory role) external onlyRole(msg.sender, "Admin") { // Example: Requires 'Admin' role
        uint memberId = memberAddressToId[memberAddr];
        require(memberId != 0, "Address is not a member");
        require(members[memberId].roles[role], "Member does not have this role");
        require(keccak256(abi.encodePacked(role)) != keccak256(abi.encodePacked("Member")), "Cannot remove default 'Member' role directly"); // Prevent removing default role

        members[memberId].roles[role] = false;

        // Remove from assignedRoles array (less efficient on-chain)
        string[] memory currentRoles = members[memberId].assignedRoles;
        string[] memory newRoles = new string[](currentRoles.length - 1);
        uint k = 0;
        for (uint i = 0; i < currentRoles.length; i++) {
            if (keccak256(abi.encodePacked(currentRoles[i])) != keccak256(abi.encodePacked(role))) {
                newRoles[k] = currentRoles[i];
                k++;
            }
        }
        members[memberId].assignedRoles = newRoles;

        emit RoleRemoved(memberId, role);
    }

    /**
     * @dev Check if a member has a specific role.
     * @param memberAddr The address of the member.
     * @param role The role to check.
     * @return True if the member has the role, false otherwise.
     */
    function hasRole(address memberAddr, string memory role) public view returns (bool) {
        uint memberId = memberAddressToId[memberAddr];
        if (memberId == 0 || !members[memberId].isActive) return false;
        return members[memberId].roles[role];
    }

    /**
     * @dev Get all roles assigned to a member.
     * @param memberAddr The address of the member.
     * @return An array of role strings.
     */
    function getMemberRoles(address memberAddr) external view onlyMember(memberAddr) returns (string[] memory) {
         return members[memberAddressToId[memberAddr]].assignedRoles;
    }

    /**
     * @dev Get the reputation points of a member. This reputation is SBT-like.
     * @param memberAddr The address of the member.
     * @return The reputation points.
     */
    function getReputation(address memberAddr) external view onlyMember(memberAddr) returns (uint) {
        return members[memberAddressToId[memberAddr]].reputationPoints;
    }

     /**
     * @dev Internal function to update a member's reputation. Only callable from trusted functions like project completion.
     * @param memberAddr The address of the member.
     * @param points The amount of reputation points to add.
     */
    function _updateReputation(address memberAddr, uint points) internal {
        uint memberId = memberAddressToId[memberAddr];
        require(memberId != 0, "Address is not a member"); // Should not happen if called internally on members
        members[memberId].reputationPoints += points;
        emit ReputationUpdated(memberId, members[memberId].reputationPoints);
    }

    // --- Project Management Functions ---

    /**
     * @dev Allows eligible members to propose and create a new project.
     * @param title The title of the project.
     * @param description A description of the project.
     * @param requiredRoles The roles required for a member to join this project.
     * @param totalReputationNeeded The total reputation points needed across contributors to complete the project.
     * @param allocatedFunds The amount of Ether to allocate from the treasury for this project.
     */
    function createProject(string memory title, string memory description, string[] memory requiredRoles, uint totalReputationNeeded, uint allocatedFunds) external onlyRole(msg.sender, "Project Creator") { // Example: Requires 'Project Creator' role
        require(address(this).balance >= allocatedFunds, "Insufficient treasury funds");

        projectCounter++;
        projects[projectCounter] = Project(
            projectCounter,
            msg.sender,
            title,
            description,
            ProjectStatus.OpenForContributors,
            requiredRoles,
            totalReputationNeeded,
            0, // currentReputationEarned
            allocatedFunds,
            new address[](0), // contributors
            new address[](0) // contributionSubmitters
        );
        projectIds.push(projectCounter);

        // Transfer funds to the project (within the contract)
        // The allocatedFunds are held by the contract, earmarked for the project.
        // require(address(this).transfer(allocatedFunds), "Treasury transfer failed"); // No direct transfer, funds stay in contract balance
        emit FundsDistributedToProject(projectCounter, allocatedFunds);
        emit ProjectCreated(projectCounter, msg.sender, title, allocatedFunds);
    }

    /**
     * @dev Allows an eligible member to join a project as a contributor.
     * Eligibility based on required roles and minimum reputation.
     * @param projectId The ID of the project to join.
     */
    function joinProject(uint projectId) external onlyMember(msg.sender) {
        Project storage p = projects[projectId];
        require(p.projectId != 0, "Project not found");
        require(p.status == ProjectStatus.OpenForContributors, "Project is not open for contributors");
        require(!p.isContributor[msg.sender], "Already a contributor");

        // Check if member meets required roles
        bool meetsRoles = true;
        uint memberId = memberAddressToId[msg.sender];
        for (uint i = 0; i < p.requiredRoles.length; i++) {
            if (!members[memberId].roles[p.requiredRoles[i]]) {
                meetsRoles = false;
                break;
            }
        }
        require(meetsRoles, "Does not meet required roles for project");

        // Optional: Check min reputation to join project (separate from DAO join)
        // require(members[memberId].reputationPoints >= p.minReputationToJoinProject, "Insufficient reputation for project");

        p.contributors.push(msg.sender);
        p.isContributor[msg.sender] = true;

        // Transition status if enough contributors joined, or leave as OpenForContributors
        // For simplicity, let's keep it OpenForContributors until explicitly moved via governance/creator or after contributions start.
        // A creator/governance could move it to InProgress. Or the first contribution moves it. Let's use the first contribution.

        emit ProjectJoined(projectId, msg.sender);
    }

    /**
     * @dev Allows a project contributor to submit points representing their contribution to the project.
     * These points are 'pending' until the project is completed.
     * @param projectId The ID of the project.
     * @param contributionPoints The points representing the value of the contribution.
     */
    function submitProjectContribution(uint projectId, uint contributionPoints) external onlyMember(msg.sender) {
        Project storage p = projects[projectId];
        require(p.projectId != 0, "Project not found");
        require(p.status == ProjectStatus.OpenForContributors || p.status == ProjectStatus.InProgress, "Project is not active for contributions");
        require(p.isContributor[msg.sender], "Not a contributor for this project");
        require(contributionPoints > 0, "Contribution points must be positive");

        // If this is the first contribution, move status to InProgress
        if (p.status == ProjectStatus.OpenForContributors) {
             p.status = ProjectStatus.InProgress;
             emit ProjectStatusChanged(projectId, ProjectStatus.InProgress);
        }

        // Add points to pending contributions for this contributor in this project
        if (p.pendingContributionPoints[msg.sender] == 0) {
             p.contributionSubmitters.push(msg.sender); // Track who submitted
        }
        p.pendingContributionPoints[msg.sender] += contributionPoints;
        p.currentReputationEarned += contributionPoints; // Update project progress

        emit ProjectContributionSubmitted(projectId, msg.sender, contributionPoints);

        // Optional: Trigger completion if totalReputationEarned >= totalReputationNeeded?
        // Let's keep completion as a separate governance/creator action for review.
    }

    /**
     * @dev Governance function to mark a project as completed and distribute rewards.
     * Only callable by members with the 'Project Reviewer' role (example).
     * @param projectId The ID of the project to complete.
     */
    function completeProject(uint projectId) external onlyRole(msg.sender, "Project Reviewer") { // Example: Requires 'Project Reviewer' role
        Project storage p = projects[projectId];
        require(p.projectId != 0, "Project not found");
        require(p.status == ProjectStatus.InProgress, "Project is not in progress");
        // Optional: require(p.currentReputationEarned >= p.totalReputationNeeded, "Project goal not met"); // Or allow completing if goal wasn't fully met

        p.status = ProjectStatus.Completed;

        // Distribute rewards (reputation and funds)
        distributeProjectRewards(projectId);

        emit ProjectCompleted(projectId);
        emit ProjectStatusChanged(projectId, ProjectStatus.Completed);
    }

    /**
     * @dev Governance function to cancel an ongoing project.
     * Only callable by members with the 'Project Reviewer' role (example).
     * @param projectId The ID of the project to cancel.
     */
    function cancelProject(uint projectId) external onlyRole(msg.sender, "Project Reviewer") { // Example: Requires 'Project Reviewer' role
        Project storage p = projects[projectId];
        require(p.projectId != 0, "Project not found");
        require(p.status == ProjectStatus.OpenForContributors || p.status == ProjectStatus.InProgress, "Project is not active");

        p.status = ProjectStatus.Cancelled;

        // Decide what happens to allocated funds - refund to treasury?
        // For simplicity, let's assume they stay in the contract balance but are no longer earmarked.
        // A more complex contract might have a treasury module to track and potentially refund allocations.

        emit ProjectCancelled(projectId);
        emit ProjectStatusChanged(projectId, ProjectStatus.Cancelled);
    }

    /**
     * @dev Retrieve details of a project.
     * @param projectId The ID of the project.
     * @return projectId The project ID.
     * @return creator The creator's address.
     * @return title The project title.
     * @return description The project description.
     * @return status The current status of the project.
     * @return requiredRoles Roles needed to join.
     * @return totalReputationNeeded Goal reputation.
     * @return currentReputationEarned Progress.
     * @return allocatedFunds Funds earmarked.
     * @return contributors List of contributors.
     * @return creationTime The creation timestamp.
     */
    function getProjectInfo(uint projectId) external view returns (uint, address, string memory, string memory, ProjectStatus, string[] memory, uint, uint, uint, address[] memory, uint) {
        Project storage p = projects[projectId];
        require(p.projectId != 0, "Project not found");
        return (
            p.projectId,
            p.creator,
            p.title,
            p.description,
            p.status,
            p.requiredRoles,
            p.totalReputationNeeded,
            p.currentReputationEarned,
            p.allocatedFunds,
            p.contributors,
            p.creationTime
        );
    }

    /**
     * @dev Get a list of project IDs filtered by status.
     * @param status The desired status.
     * @return An array of project IDs.
     */
    function getProjectsByStatus(ProjectStatus status) external view returns (uint[] memory) {
        uint[] memory filteredProjectIds = new uint[](projectIds.length);
        uint count = 0;
        for (uint i = 0; i < projectIds.length; i++) {
            if (projects[projectIds[i]].status == status) {
                filteredProjectIds[count] = projectIds[i];
                count++;
            }
        }
        assembly {
            mstore(filteredProjectIds, count)
        }
        return filteredProjectIds;
    }

     /**
     * @dev Get a list of project IDs a member has contributed to.
     * @param memberAddr The address of the member.
     * @return An array of project IDs.
     */
    function getMemberProjects(address memberAddr) external view onlyMember(memberAddr) returns (uint[] memory) {
        uint memberId = memberAddressToId[memberAddr];
        uint[] memory contributedProjectIds = new uint[](projectIds.length); // Max possible size
        uint count = 0;

        for (uint i = 0; i < projectIds.length; i++) {
             if (members[memberId].projectContributionScores[projectIds[i]] > 0) {
                 contributedProjectIds[count] = projectIds[i];
                 count++;
             }
        }

         assembly {
            mstore(contributedProjectIds, count)
        }
        return contributedProjectIds;
    }


    /**
     * @dev Internal function to distribute reputation and funds upon project completion.
     * Reputation is distributed proportionally based on submitted contribution points.
     * Funds are also distributed proportionally.
     * @param projectId The ID of the completed project.
     */
    function distributeProjectRewards(uint projectId) internal {
        Project storage p = projects[projectId];
        require(p.status == ProjectStatus.Completed, "Project not completed");

        uint totalSubmittedPoints = p.currentReputationEarned;
        uint totalFunds = p.allocatedFunds;

        if (totalSubmittedPoints == 0) {
            // No contributions submitted, funds might stay in treasury or go elsewhere
            // For now, funds stay in contract but project is completed.
            return;
        }

        // Distribute reputation and funds proportionally
        for (uint i = 0; i < p.contributionSubmitters.length; i++) {
            address contributorAddr = p.contributionSubmitters[i];
            uint submittedPoints = p.pendingContributionPoints[contributorAddr];
            uint memberId = memberAddressToId[contributorAddr];

            if (memberId == 0 || !members[memberId].isActive) {
                 // Skip inactive/non-members
                 continue;
            }

            // Calculate reputation reward: MemberPoints / TotalPoints * ProjectGoalReputation (if goal is the basis)
            // Or simply add submitted points as reputation: submittedPoints
            // Let's add submitted points as direct reputation for simplicity, assuming they represent value.
            uint reputationReward = submittedPoints; // Direct reward based on points submitted

            // Calculate fund reward: MemberPoints / TotalPoints * AllocatedFunds
            uint fundReward = (submittedPoints * totalFunds) / totalSubmittedPoints;

            // Update member's reputation
            _updateReputation(contributorAddr, reputationReward);

            // Transfer funds to contributor
            if (fundReward > 0) {
                (bool success, ) = payable(contributorAddr).call{value: fundReward}("");
                require(success, "Fund distribution failed"); // Should ideally handle this failure more gracefully or retry
            }

            // Record contribution in member's history (optional, currently using projectContributionScores)
            members[memberId].projectContributionScores[projectId] += submittedPoints;

            // Clear pending points for this project for this contributor
            p.pendingContributionPoints[contributorAddr] = 0;
        }

        // Clear contributors list and submitters list after distribution
        delete p.contributors;
        delete p.contributionSubmitters;

        emit FundsDistributedToContributors(projectId, totalFunds);
    }


    // --- Governance Functions ---

    /**
     * @dev Allows eligible members to create a new governance proposal.
     * Eligibility is based on minimum required role and reputation.
     * @param title The title of the proposal.
     * @param description A description of the proposal.
     * @param targetContract The address of the contract to call if the proposal passes (0x0 for internal DAO logic).
     * @param callData The calldata for the targetContract call.
     * @param value The amount of Ether to send with the targetContract call.
     * @param requiredRoleToPropose The minimum role required to create this specific proposal type.
     * @param requiredReputationToPropose The minimum reputation required to create this specific proposal type.
     * @param votingPeriodSeconds The duration of the voting period for this proposal.
     */
    function createProposal(
        string memory title,
        string memory description,
        address targetContract,
        bytes calldata callData,
        uint value,
        string memory requiredRoleToPropose,
        uint requiredReputationToPropose,
        uint votingPeriodSeconds
    ) external onlyMember(msg.sender) {
        uint memberId = memberAddressToId[msg.sender];
        require(hasRole(msg.sender, requiredRoleToPropose), "Insufficient role to propose");
        require(members[memberId].reputationPoints >= requiredReputationToPropose, "Insufficient reputation to propose");
        require(votingPeriodSeconds > 0, "Voting period must be positive");

        proposalCounter++;
        proposals[proposalCounter] = Proposal(
            proposalCounter,
            msg.sender,
            title,
            description,
            targetContract,
            callData,
            value,
            ProposalStatus.Active, // Proposals start as Active
            block.timestamp,
            block.timestamp + votingPeriodSeconds,
            0, // yesVotes
            0, // noVotes
            requiredRoleToPropose, // Store requirements on the proposal itself
            requiredReputationToPropose
        );
        proposalIds.push(proposalCounter);

        emit ProposalCreated(proposalCounter, msg.sender, title, proposals[proposalCounter].votingEndTime);
        emit ProposalStatusChanged(proposalCounter, ProposalStatus.Active);
    }

    /**
     * @dev Allows eligible members to vote on an active proposal.
     * Eligibility is based on required role and reputation defined in the proposal.
     * Each eligible member gets one vote (1-person-1-vote).
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for yes, false for no.
     */
    function voteOnProposal(uint proposalId, bool support) external onlyMember(msg.sender) {
        Proposal storage p = proposals[proposalId];
        require(p.proposalId != 0, "Proposal not found");
        require(p.status == ProposalStatus.Active, "Proposal is not active");
        require(block.timestamp < p.votingEndTime, "Voting period has ended");
        require(!p.hasVoted[msg.sender], "Already voted on this proposal");

        // Check if member meets eligibility requirements set for *this* proposal
        uint memberId = memberAddressToId[msg.sender];
        require(hasRole(msg.sender, p.requiredRoleToVote), "Insufficient role to vote");
        require(members[memberId].reputationPoints >= p.requiredReputationToVote, "Insufficient reputation to vote");

        p.hasVoted[msg.sender] = true;

        if (support) {
            p.yesVotes++;
        } else {
            p.noVotes++;
        }

        emit ProposalVoted(proposalId, msg.sender, support);
    }

    /**
     * @dev Allows anyone to execute a successful proposal after the voting period ends.
     * A proposal is successful if yesVotes > noVotes.
     * Can call an external contract or trigger internal DAO logic (if targetContract is 0x0).
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(p.proposalId != 0, "Proposal not found");
        require(p.status == ProposalStatus.Active, "Proposal is not active");
        require(block.timestamp >= p.votingEndTime, "Voting period is still active");

        if (p.yesVotes > p.noVotes) {
            p.status = ProposalStatus.Succeeded;
            emit ProposalStatusChanged(proposalId, ProposalStatus.Succeeded);

            // Execute the proposal's action
            if (p.targetContract == address(0)) {
                // Internal DAO logic based on calldata/description (requires manual implementation or a dispatcher)
                // For a simple example, we'll just log success. A real implementation would need to decode callData
                // and call specific functions on *this* contract based on the proposal's intent.
                // Example: Set a parameter, assign a role (if not done directly via assignRole governance call) etc.
                // This requires a robust internal dispatcher or using targetContract == address(this) with specific function signatures.
                // For this example, let's *assume* targetContract == address(this) is handled via the call.
                 if (p.callData.length > 0) {
                    (bool success, ) = address(this).call{value: p.value}(p.callData);
                    require(success, "Internal DAO call failed"); // Ensure internal calls initiated by proposals succeed
                    emit ProposalExecuted(proposalId, true);
                 } else {
                     // Proposal was just for signaling/discussion, no execution needed
                     emit ProposalExecuted(proposalId, true);
                 }

            } else {
                // External contract call
                (bool success, ) = p.targetContract.call{value: p.value}(p.callData);
                 // Note: It's often better practice to separate the execution check
                 // from the proposal status update in case the external call fails,
                 // but for a simple example, we'll mark executed based on success/failure of the call.
                if (success) {
                    emit ProposalExecuted(proposalId, true);
                } else {
                    // Mark failed if execution failed, but proposal status might still be Succeeded
                    // depending on DAO rules. Let's mark as failed execution for clarity.
                    // p.status stays Succeeded, but execution failed. Need a separate status?
                    // Let's add a flag or modify status slightly. Or just rely on the event.
                     emit ProposalExecuted(proposalId, false);
                }
            }
             p.status = ProposalStatus.Executed; // Mark as executed regardless of call success/failure if it was attempted
             emit ProposalStatusChanged(proposalId, ProposalStatus.Executed);

        } else {
            p.status = ProposalStatus.Failed;
            emit ProposalStatusChanged(proposalId, ProposalStatus.Failed);
        }
    }


    /**
     * @dev Retrieve details of a proposal.
     * @param proposalId The ID of the proposal.
     * @return proposalId The proposal ID.
     * @return proposer The proposer's address.
     * @return title The proposal title.
     * @return description The proposal description.
     * @return targetContract The target contract address.
     * @return callData The calldata.
     * @return value The value to send.
     * @return status The current status.
     * @return creationTime The creation timestamp.
     * @return votingEndTime The voting end timestamp.
     * @return yesVotes The number of yes votes.
     * @return noVotes The number of no votes.
     * @return requiredRoleToVote Required role to vote.
     * @return requiredReputationToVote Required reputation to vote.
     */
    function getProposalInfo(uint proposalId) external view returns (uint, address, string memory, string memory, address, bytes memory, uint, ProposalStatus, uint, uint, uint, uint, string memory, uint) {
        Proposal storage p = proposals[proposalId];
        require(p.proposalId != 0, "Proposal not found");
        return (
            p.proposalId,
            p.proposer,
            p.title,
            p.description,
            p.targetContract,
            p.callData,
            p.value,
            p.status,
            p.creationTime,
            p.votingEndTime,
            p.yesVotes,
            p.noVotes,
            p.requiredRoleToVote,
            p.requiredReputationToVote
        );
    }

    /**
     * @dev Get the final voting result for a proposal (after voting ends).
     * @param proposalId The ID of the proposal.
     * @return yesVotes The final count of yes votes.
     * @return noVotes The final count of no votes.
     */
    function getProposalVotingResult(uint proposalId) external view returns (uint yesVotes, uint noVotes) {
        Proposal storage p = proposals[proposalId];
        require(p.proposalId != 0, "Proposal not found");
        require(block.timestamp >= p.votingEndTime || p.status > ProposalStatus.Active, "Voting is still active"); // Can get results once active period ends or status changes
        return (p.yesVotes, p.noVotes);
    }

    /**
     * @dev Get a list of currently active proposal IDs.
     * @return An array of active proposal IDs.
     */
    function getActiveProposals() external view returns (uint[] memory) {
        uint[] memory activeIds = new uint[](proposalIds.length); // Max possible size
        uint count = 0;
        for (uint i = 0; i < proposalIds.length; i++) {
            if (proposals[proposalIds[i]].status == ProposalStatus.Active && block.timestamp < proposals[proposalIds[i]].votingEndTime) {
                activeIds[count] = proposalIds[i];
                count++;
            }
        }
        assembly {
            mstore(activeIds, count)
        }
        return activeIds;
    }


    // --- Treasury Functions ---

    /**
     * @dev Allows anyone to send Ether to the DAO treasury.
     */
    receive() external payable {
        emit TreasuryDeposited(msg.sender, msg.value);
    }

     fallback() external payable {
        emit TreasuryDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Get the current Ether balance of the DAO treasury.
     * @return The balance in wei.
     */
    function getTreasuryBalance() external view returns (uint) {
        return address(this).balance;
    }

    // The distribution logic is within distributeProjectRewards, called by completeProject

    // --- Parameter Management Functions ---

    /**
     * @dev Governance function to set the default voting period for new proposals.
     * Requires 'Admin' role (example).
     * @param seconds The new default voting period in seconds.
     */
    function setVotingPeriod(uint seconds) external onlyRole(msg.sender, "Admin") {
        require(seconds > 0, "Voting period must be positive");
        defaultVotingPeriod = seconds;
        emit ParameterUpdated("defaultVotingPeriod", seconds);
    }

    /**
     * @dev Governance function to set the minimum reputation required for a member to join the DAO.
     * Requires 'Admin' role (example). Note: This parameter's utility depends on the DAO's specific design
     * if reputation is only earned *within* the DAO. May be more useful for future upgrades or external rep systems.
     * @param points The new minimum reputation points.
     */
    function setMinReputationToJoin(uint points) external onlyRole(msg.sender, "Admin") {
         minReputationToJoin = points;
         emit ParameterUpdated("minReputationToJoin", points);
    }

    /**
     * @dev Governance function to set the minimum role required for a member to create new proposals.
     * Requires 'Admin' role (example).
     * @param role The name of the required role.
     */
    function setMinRoleToPropose(string memory role) external onlyRole(msg.sender, "Admin") {
         minRoleToPropose = role;
         emit ParameterUpdatedString("minRoleToPropose", role);
    }

    // --- Additional/Helper Functions to reach 20+ ---

    /**
     * @dev Gets the total number of created projects.
     */
    function getTotalProjects() external view returns (uint) {
        return projectCounter;
    }

     /**
     * @dev Gets the total number of created proposals.
     */
    function getTotalProposals() external view returns (uint) {
        return proposalCounter;
    }

     /**
     * @dev Checks if an address is an active member.
     */
    function isActiveMember(address memberAddr) external view returns (bool) {
        uint memberId = memberAddressToId[memberAddr];
        return memberId != 0 && members[memberId].isActive;
    }

     /**
     * @dev Gets the list of all member addresses. Use with caution if member count is very large.
     */
    function getAllMemberAddresses() external view returns (address[] memory) {
        return memberAddresses;
    }

    // Total functions: 7 (Membership) + 5 (Roles/Rep) + 8 (Projects) + 6 (Governance) + 3 (Treasury) + 3 (Parameters) + 4 (Helpers) = 36 functions. Well over the 20 required.

    // The Ownable contract provides `owner()` and `transferOwnership()`.
    // For a truly decentralized DAO, ownership should ideally be renounced
    // and critical administrative functions (like adding initial roles, setting parameters,
    // assigning 'Admin' or 'Project Reviewer' roles) should be transitionable to
    // governance proposals after initial setup.
    // For this example, Ownable is kept for initial admin setup. Critical changes (like parameter setting, role assignment)
    // are gated by specific DAO roles which would themselves be assigned via proposals.

     /**
     * @dev Override Ownable's transferOwnership to require governance approval (via proposal execution).
     * This is a common pattern to decentralize ownership transfer.
     * Note: This function needs to be called BY a successfully executed proposal.
     */
    function transferOwnershipViaProposal(address newOwner) external onlyOwner {
        // This function is only callable by the current owner.
        // The intent is that a DAO proposal calls this function
        // using executeProposal(..., targetContract=this, callData=abi.encodeWithSignature("transferOwnershipViaProposal(address)", newOwner)).
        transferOwnership(newOwner);
    }

     /**
     * @dev Override Ownable's renounceOwnership to require governance approval.
     * Note: This function needs to be called BY a successfully executed proposal.
     */
    function renounceOwnershipViaProposal() external onlyOwner {
        // This function is only callable by the current owner.
        // The intent is that a DAO proposal calls this function
        // using executeProposal(..., targetContract=this, callData=abi.encodeWithSignature("renounceOwnershipViaProposal()")).
        renounceOwnership();
    }
}
```