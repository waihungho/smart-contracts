```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Organization (DAO) with Dynamic Governance & Skill-Based Roles
 * @author Bard (AI Assistant)
 * @dev A sophisticated DAO smart contract demonstrating advanced concepts like dynamic governance,
 * skill-based role assignments, multi-type proposals, and on-chain reputation management.
 * This contract is designed to be unique and not directly replicate existing open-source DAOs.
 *
 * **Outline and Function Summary:**
 *
 * **DAO Core Functions:**
 * 1. `joinDAO()`: Allows users to request membership in the DAO.
 * 2. `approveMembership(address _member)`: Admin-only function to approve pending membership requests.
 * 3. `revokeMembership(address _member)`: Admin-only function to remove a member from the DAO.
 * 4. `leaveDAO()`: Allows a member to voluntarily leave the DAO.
 * 5. `getMembers()`: Returns a list of current DAO members.
 * 6. `isMember(address _user)`: Checks if an address is a member of the DAO.
 * 7. `pauseDAO()`: Admin-only function to pause all DAO activities (except crucial admin functions).
 * 8. `unpauseDAO()`: Admin-only function to unpause DAO activities.
 * 9. `getDAOInfo()`: Returns general information about the DAO (name, admin, paused status, etc.).
 *
 * **Role & Skill Management:**
 * 10. `defineRole(string memory _roleName, string memory _roleDescription, string[] memory _requiredSkills)`: Admin-only function to define a new role with required skills.
 * 11. `assignRole(address _member, uint256 _roleId)`: Admin-only function to assign a role to a DAO member.
 * 12. `removeRole(address _member, uint256 _roleId)`: Admin-only function to remove a role from a DAO member.
 * 13. `getRoleDetails(uint256 _roleId)`: Returns details of a specific role.
 * 14. `getMemberRoles(address _member)`: Returns a list of roles assigned to a member.
 * 15. `addSkill(string memory _skillName, string memory _skillDescription)`: Admin-only function to add a new skill to the skill registry.
 * 16. `getSkillDetails(uint256 _skillId)`: Returns details of a specific skill.
 * 17. `declareSkill(uint256 _skillId)`: Allows a member to declare possession of a skill. (Could be linked to reputation or role eligibility)
 * 18. `getMemberSkills(address _member)`: Returns a list of skills declared by a member.
 *
 * **Proposal & Voting System:**
 * 19. `createProposal(ProposalType _proposalType, string memory _title, string memory _description, bytes memory _data)`: Allows members to create proposals of different types.
 * 20. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows members to vote on active proposals.
 * 21. `executeProposal(uint256 _proposalId)`: Admin-only function to execute a passed proposal.
 * 22. `getProposalDetails(uint256 _proposalId)`: Returns details of a specific proposal.
 * 23. `getProposalsByType(ProposalType _proposalType)`: Returns a list of proposals of a specific type.
 * 24. `getProposalVotingStats(uint256 _proposalId)`: Returns voting statistics for a proposal.
 * 25. `cancelProposal(uint256 _proposalId)`: Admin-only function to cancel a proposal before voting ends.
 *
 * **Dynamic Governance Parameters (Example - could be expanded):**
 * 26. `setQuorum(uint256 _newQuorumPercentage)`: Admin-only function to dynamically adjust the quorum percentage required for proposals to pass.
 * 27. `getQuorum()`: Returns the current quorum percentage.
 *
 * **Reputation (Conceptual - could be expanded with more complex logic):**
 * 28. `contributeToDAO(string memory _contributionDescription)`: Allows members to record contributions (conceptually for reputation).
 * 29. `getMemberContributions(address _member)`: Returns a list of contributions recorded by a member.
 *
 * **Events:**
 *  - Numerous events are emitted throughout the contract to track key actions.
 */
contract SkillBasedDAO {
    /* -------------------- STATE VARIABLES -------------------- */
    string public daoName;
    address public admin;
    bool public paused;
    uint256 public quorumPercentage; // Percentage of votes needed to pass a proposal

    mapping(address => bool) public members;
    address[] public memberList;
    mapping(address => bool) public pendingMembershipRequests;

    uint256 public nextRoleId;
    mapping(uint256 => Role) public roles;
    mapping(address => uint256[]) public memberRoles;

    uint256 public nextSkillId;
    mapping(uint256 => Skill) public skills;
    mapping(address => uint256[]) public memberSkills;

    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => member => hasVoted
    mapping(uint256 => uint256) public proposalVoteCounts; // proposalId => voteCount (For support votes - simplified for example)

    mapping(address => Contribution[]) public memberContributions;

    /* -------------------- STRUCTS & ENUMS -------------------- */
    enum ProposalType {
        TEXT_PROPOSAL,
        CODE_CHANGE,
        TREASURY_TRANSFER,
        ROLE_MANAGEMENT,
        PARAMETER_CHANGE
    }

    struct Role {
        uint256 id;
        string name;
        string description;
        uint256[] requiredSkillIds;
    }

    struct Skill {
        uint256 id;
        string name;
        string description;
    }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        string title;
        string description;
        address proposer;
        uint256 creationTimestamp;
        bytes data; // Generic data field for proposal-specific information
        bool executed;
        bool passed;
        bool active;
    }

    struct Contribution {
        uint256 timestamp;
        string description;
    }

    /* -------------------- EVENTS -------------------- */
    event DAOCreated(string daoName, address admin);
    event MembershipRequested(address member);
    event MembershipApproved(address member);
    event MembershipRevoked(address member);
    event MemberLeft(address member);
    event DAOPaused(address admin);
    event DAOUnpaused(address admin);

    event RoleDefined(uint256 roleId, string roleName);
    event RoleAssigned(address member, uint256 roleId);
    event RoleRemoved(address member, uint256 roleId);
    event SkillAdded(uint256 skillId, string skillName);
    event SkillDeclared(address member, uint256 skillId);

    event ProposalCreated(uint256 proposalId, ProposalType proposalType, string title, address proposer);
    event ProposalVoted(uint256 proposalId, address member, bool support);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCancelled(uint256 proposalId);
    event QuorumSet(uint256 newQuorumPercentage);
    event ContributionRecorded(address member, string description);

    /* -------------------- MODIFIERS -------------------- */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only DAO members can call this function.");
        _;
    }

    modifier notPaused() {
        require(!paused, "DAO is currently paused.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].id == _proposalId, "Proposal does not exist.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].active, "Proposal is not active.");
        _;
    }


    /* -------------------- CONSTRUCTOR -------------------- */
    constructor(string memory _daoName, uint256 _initialQuorumPercentage) {
        daoName = _daoName;
        admin = msg.sender;
        paused = false;
        quorumPercentage = _initialQuorumPercentage;
        emit DAOCreated(_daoName, admin);
    }

    /* -------------------- DAO CORE FUNCTIONS -------------------- */
    function joinDAO() external notPaused {
        require(!members[msg.sender] && !pendingMembershipRequests[msg.sender], "Already a member or membership request pending.");
        pendingMembershipRequests[msg.sender] = true;
        emit MembershipRequested(msg.sender);
    }

    function approveMembership(address _member) external onlyAdmin notPaused {
        require(pendingMembershipRequests[_member], "No pending membership request for this address.");
        require(!members[_member], "Address is already a member.");
        members[_member] = true;
        memberList.push(_member);
        delete pendingMembershipRequests[_member];
        emit MembershipApproved(_member);
    }

    function revokeMembership(address _member) external onlyAdmin notPaused {
        require(members[_member], "Address is not a member.");
        members[_member] = false;
        // Remove from memberList (inefficient for large lists, optimize if needed in real application)
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == _member) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        emit MembershipRevoked(_member);
    }

    function leaveDAO() external onlyMember notPaused {
        revokeMembership(msg.sender); // Reuse revoke logic, but initiated by member
        emit MemberLeft(msg.sender);
    }

    function getMembers() external view returns (address[] memory) {
        return memberList;
    }

    function isMember(address _user) external view returns (bool) {
        return members[_user];
    }

    function pauseDAO() external onlyAdmin {
        paused = true;
        emit DAOPaused(admin);
    }

    function unpauseDAO() external onlyAdmin {
        paused = false;
        emit DAOUnpaused(admin);
    }

    function getDAOInfo() external view returns (string memory, address, bool, uint256) {
        return (daoName, admin, paused, quorumPercentage);
    }

    /* -------------------- ROLE & SKILL MANAGEMENT -------------------- */
    function defineRole(string memory _roleName, string memory _roleDescription, string[] memory _requiredSkills) external onlyAdmin notPaused {
        uint256[] memory requiredSkillIds = new uint256[](_requiredSkills.length);
        for (uint256 i = 0; i < _requiredSkills.length; i++) {
            uint256 skillId = getSkillIdByName(_requiredSkills[i]);
            require(skillId != 0, "Required skill not found."); // Assuming skillId 0 means not found
            requiredSkillIds[i] = skillId;
        }

        roles[nextRoleId] = Role({
            id: nextRoleId,
            name: _roleName,
            description: _roleDescription,
            requiredSkillIds: requiredSkillIds
        });
        emit RoleDefined(nextRoleId, _roleName);
        nextRoleId++;
    }

    function assignRole(address _member, uint256 _roleId) external onlyAdmin notPaused {
        require(members[_member], "Target address is not a member.");
        require(roles[_roleId].id == _roleId, "Role does not exist."); // Check if role exists

        memberRoles[_member].push(_roleId);
        emit RoleAssigned(_member, _roleId);
    }

    function removeRole(address _member, uint256 _roleId) external onlyAdmin notPaused {
        require(members[_member], "Target address is not a member.");
        require(roles[_roleId].id == _roleId, "Role does not exist.");

        uint256[] storage rolesOfMember = memberRoles[_member];
        for (uint256 i = 0; i < rolesOfMember.length; i++) {
            if (rolesOfMember[i] == _roleId) {
                rolesOfMember[i] = rolesOfMember[rolesOfMember.length - 1];
                rolesOfMember.pop();
                emit RoleRemoved(_member, _roleId);
                return;
            }
        }
        revert("Role not assigned to member.");
    }

    function getRoleDetails(uint256 _roleId) external view returns (Role memory) {
        require(roles[_roleId].id == _roleId, "Role does not exist.");
        return roles[_roleId];
    }

    function getMemberRoles(address _member) external view returns (uint256[] memory) {
        return memberRoles[_member];
    }

    function addSkill(string memory _skillName, string memory _skillDescription) external onlyAdmin notPaused {
        require(getSkillIdByName(_skillName) == 0, "Skill name already exists."); // Prevent duplicate skill names

        skills[nextSkillId] = Skill({
            id: nextSkillId,
            name: _skillName,
            description: _skillDescription
        });
        emit SkillAdded(nextSkillId, _skillName);
        nextSkillId++;
    }

    function getSkillDetails(uint256 _skillId) external view returns (Skill memory) {
        require(skills[_skillId].id == _skillId, "Skill does not exist.");
        return skills[_skillId];
    }

    function declareSkill(uint256 _skillId) external onlyMember notPaused {
        require(skills[_skillId].id == _skillId, "Skill does not exist.");
        require(!hasDeclaredSkill(msg.sender, _skillId), "Skill already declared.");
        memberSkills[msg.sender].push(_skillId);
        emit SkillDeclared(msg.sender, _skillId);
    }

    function getMemberSkills(address _member) external view returns (uint256[] memory) {
        return memberSkills[_member];
    }

    /* -------------------- PROPOSAL & VOTING SYSTEM -------------------- */
    function createProposal(
        ProposalType _proposalType,
        string memory _title,
        string memory _description,
        bytes memory _data
    ) external onlyMember notPaused {
        proposals[nextProposalId] = Proposal({
            id: nextProposalId,
            proposalType: _proposalType,
            title: _title,
            description: _description,
            proposer: msg.sender,
            creationTimestamp: block.timestamp,
            data: _data,
            executed: false,
            passed: false,
            active: true
        });
        emit ProposalCreated(nextProposalId, _proposalType, _title, msg.sender);
        nextProposalId++;
    }

    function voteOnProposal(uint256 _proposalId, bool _support) external onlyMember notPaused proposalExists(_proposalId) proposalActive(_proposalId) {
        require(!proposalVotes[_proposalId][msg.sender], "Member has already voted on this proposal.");
        proposalVotes[_proposalId][msg.sender] = true;
        if (_support) {
            proposalVoteCounts[_proposalId]++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) external onlyAdmin notPaused proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.active, "Proposal is not active.");
        require(!proposal.executed, "Proposal already executed.");

        uint256 totalMembers = memberList.length;
        uint256 votesFor = proposalVoteCounts[_proposalId];
        uint256 requiredVotes = (totalMembers * quorumPercentage) / 100;

        if (votesFor >= requiredVotes) {
            proposal.passed = true;
            proposal.executed = true;
            proposal.active = false;
            // ** IMPORTANT: Implement proposal execution logic based on proposal.proposalType and proposal.data **
            // Example (very basic and illustrative - needs to be adapted for real use cases):
            if (proposal.proposalType == ProposalType.TEXT_PROPOSAL) {
                // Example: Log the text proposal data
                emit ProposalExecuted(_proposalId); // Consider more specific events
            } else if (proposal.proposalType == ProposalType.CODE_CHANGE) {
                // Example:  In a more complex system, this could trigger code updates (carefully designed and secured)
                emit ProposalExecuted(_proposalId);
            } else if (proposal.proposalType == ProposalType.TREASURY_TRANSFER) {
                // Example:  Transfer funds based on data (ensure data is properly structured and validated)
                emit ProposalExecuted(_proposalId);
            }
            // ... Implement execution logic for other proposal types ...
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.passed = false;
            proposal.executed = false;
            proposal.active = false; // Proposal fails if quorum not reached
            emit ProposalCancelled(_proposalId); // Could use a different event like ProposalFailed
        }
    }

    function getProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function getProposalsByType(ProposalType _proposalType) external view returns (uint256[] memory) {
        uint256[] memory proposalIds = new uint256[](nextProposalId); // Max size, could be optimized
        uint256 count = 0;
        for (uint256 i = 0; i < nextProposalId; i++) {
            if (proposals[i].proposalType == _proposalType && proposals[i].id == i) { // Check id to avoid gaps from cancellations if implemented
                proposalIds[count] = i;
                count++;
            }
        }
        assembly { // Assembly to efficiently resize the array
            mstore(proposalIds, count) // Store the actual length at the beginning of the array
        }
        return proposalIds;
    }

    function getProposalVotingStats(uint256 _proposalId) external view proposalExists(_proposalId) returns (uint256, uint256) {
        uint256 totalMembers = memberList.length;
        return (proposalVoteCounts[_proposalId], totalMembers);
    }

    function cancelProposal(uint256 _proposalId) external onlyAdmin notPaused proposalExists(_proposalId) proposalActive(_proposalId){
        Proposal storage proposal = proposals[_proposalId];
        proposal.active = false;
        proposal.executed = false;
        proposal.passed = false;
        emit ProposalCancelled(_proposalId);
    }

    /* -------------------- DYNAMIC GOVERNANCE PARAMETERS -------------------- */
    function setQuorum(uint256 _newQuorumPercentage) external onlyAdmin notPaused {
        require(_newQuorumPercentage <= 100, "Quorum percentage cannot exceed 100.");
        quorumPercentage = _newQuorumPercentage;
        emit QuorumSet(_newQuorumPercentage);
    }

    function getQuorum() external view returns (uint256) {
        return quorumPercentage;
    }

    /* -------------------- REPUTATION (Conceptual) -------------------- */
    function contributeToDAO(string memory _contributionDescription) external onlyMember notPaused {
        memberContributions[msg.sender].push(Contribution({
            timestamp: block.timestamp,
            description: _contributionDescription
        }));
        emit ContributionRecorded(msg.sender, _contributionDescription);
    }

    function getMemberContributions(address _member) external view returns (Contribution[] memory) {
        return memberContributions[_member];
    }

    /* -------------------- HELPER/INTERNAL FUNCTIONS -------------------- */
    function getSkillIdByName(string memory _skillName) internal view returns (uint256) {
        for (uint256 i = 0; i < nextSkillId; i++) {
            if (skills[i].id == i && keccak256(bytes(skills[i].name)) == keccak256(bytes(_skillName))) {
                return i;
            }
        }
        return 0; // 0 indicates skill not found (assuming skillIds start from 1 or if 0 is never used)
    }

    function hasDeclaredSkill(address _member, uint256 _skillId) internal view returns (bool) {
        for (uint256 i = 0; i < memberSkills[_member].length; i++) {
            if (memberSkills[_member][i] == _skillId) {
                return true;
            }
        }
        return false;
    }
}
```