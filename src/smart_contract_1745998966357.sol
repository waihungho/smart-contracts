Okay, let's design a smart contract for a "Decentralized Soulbound Guild". This concept combines Soulbound Tokens (SBTs) for non-transferable membership and identity, a reputation system, role-based access control within the guild, a task/quest system for earning reputation, and a simple on-chain governance mechanism, all without relying on standard OpenZeppelin implementations directly for the core logic (though we might use some standard interfaces or basic patterns).

**Concept:**

A Decentralized Soulbound Guild is a community represented on-chain. Membership is an NFT (SBT) that is permanently tied to a wallet address. Within the guild, members earn reputation through contributions (like completing tasks or participating in governance). Reputation influences a member's role, and roles grant permissions within the guild (e.g., creating tasks, verifying submissions, proposing changes).

**Advanced/Creative/Trendy Aspects:**

1.  **Custom Soulbound Token Implementation:** A non-transferable ERC-721-like structure built directly into the contract.
2.  **On-Chain Reputation System:** Dynamic points tied to the SBT/member.
3.  **Role Progression tied to Reputation:** Members can automatically or semi-automatically level up roles based on their reputation score.
4.  **Dynamic Role Permissions:** Permissions can be granted/revoked from roles by governance or high-level members.
5.  **On-Chain Task System:** A simple framework for defining, assigning, submitting, and verifying tasks with reputation rewards.
6.  **Reputation-Weighted Governance:** Voting power in proposals is tied to reputation or role.
7.  **Vote Delegation:** Members can delegate their voting power.

**Outline:**

1.  **Contract Definition:** Basic contract structure, state variables, events, enums, structs.
2.  **Soulbound Token (SBT) Core:** Internal functions for minting and burning SBTs, tracking ownership (SBT ID <-> member address), and enforcing non-transferability.
3.  **Membership Management:** Functions for applying, inviting, approving, and revoking membership (minting/burning SBTs).
4.  **Reputation System:** Functions for awarding and penalizing reputation points.
5.  **Role Management:** Functions for creating roles, assigning roles to members, and defining/modifying role permissions.
6.  **Role Progression:** Logic to update a member's role based on their reputation threshold.
7.  **Task/Quest System:** Functions for creating tasks, assigning them, submitting completion, and verifying/awarding reputation.
8.  **Governance System:** Functions for creating proposals, voting on them (with delegation), and executing successful proposals.
9.  **Permissioning:** Internal helper function to check if a member (via their role) has a specific permission.
10. **View Functions:** Functions to query the state of members, roles, tasks, proposals, etc.
11. **Admin Functions:** Owner-specific operations like transferring ownership.

**Function Summary (29 Functions):**

1.  `constructor()`: Initializes the contract, creates a default "Guild Master" role and assigns it to the deployer (minting the first SBT).
2.  `applyForMembership()`: Allows anyone to submit an application to join.
3.  `inviteMember(address _applicant)`: Allows a permitted member to invite someone directly, bypassing application.
4.  `approveMembershipApplication(address _applicant)`: (Permission: `CAN_APPROVE_APPLICATION`) Approves a pending application, mints an SBT, and grants the initial member role.
5.  `revokeMembership(address _member)`: (Permission: `CAN_REVOKE_MEMBERSHIP`) Revokes membership, burns the SBT, clears member data.
6.  `isMember(address _address)`: (View) Checks if an address is currently a guild member.
7.  `getMemberSBTId(address _member)`: (View) Gets the SBT ID for a given member address.
8.  `getSBTBearer(uint256 _sbtId)`: (View) Gets the member address for a given SBT ID.
9.  `awardReputation(address _member, uint256 _amount)`: (Permission: `CAN_AWARD_REPUTATION`) Awards reputation points to a member.
10. `penalizeReputation(address _member, uint256 _amount)`: (Permission: `CAN_PENALIZE_REPUTATION`) Deducts reputation points from a member.
11. `getReputation(address _member)`: (View) Gets the current reputation of a member.
12. `createRole(bytes32 _roleId, string memory _name)`: (Permission: `CAN_CREATE_ROLE`) Creates a new role with a unique ID and name.
13. `assignRole(address _member, bytes32 _roleId)`: (Permission: `CAN_ASSIGN_ROLE`) Assigns an existing role to a member.
14. `getMemberRole(address _member)`: (View) Gets the ID of the role currently assigned to a member.
15. `getRoleDetails(bytes32 _roleId)`: (View) Gets the name of a role.
16. `grantRolePermission(bytes32 _roleId, bytes32 _permission)`: (Permission: `CAN_GRANT_PERMISSION`) Grants a specific permission to a role.
17. `revokeRolePermission(bytes32 _roleId, bytes32 _permission)`: (Permission: `CAN_REVOKE_PERMISSION`) Revokes a specific permission from a role.
18. `hasPermission(address _member, bytes32 _permission)`: (View) Checks if a member's current role has a specific permission.
19. `setRoleReputationThreshold(bytes32 _roleId, uint256 _threshold)`: (Permission: `CAN_SET_ROLE_THRESHOLD`) Sets the reputation threshold required to reach a specific role.
20. `attemptRoleProgression(address _member)`: (Permission: `CAN_TRIGGER_ROLE_PROGRESSION` or internal) Checks if a member's reputation qualifies them for a higher role and assigns it if so.
21. `createTask(bytes32 _taskId, string memory _description, uint256 _reputationReward, address _assignee)`: (Permission: `CAN_CREATE_TASK`) Creates a new task.
22. `submitTaskCompletion(bytes32 _taskId, string memory _proofDetails)`: Allows the assigned member to submit proof of task completion.
23. `verifyTaskCompletion(bytes32 _taskId)`: (Permission: `CAN_VERIFY_TASK`) Verifies a submitted task, awards reputation, and marks the task complete.
24. `cancelTask(bytes32 _taskId)`: (Permission: `CAN_CANCEL_TASK` - implicitly via CAN_CREATE_TASK or specific permission) Cancels an open or assigned task.
25. `getTaskDetails(bytes32 _taskId)`: (View) Retrieves details about a task.
26. `createProposal(bytes32 _proposalId, string memory _description, bytes32 _actionType, bytes memory _actionData, uint256 _votingPeriodBlocks)`: (Permission: `CAN_CREATE_PROPOSAL` or min reputation) Creates a new governance proposal.
27. `voteOnProposal(bytes32 _proposalId, bool _support)`: Allows a member (or their delegate) to vote on a proposal.
28. `delegateVote(address _delegate)`: Allows a member to delegate their voting power to another member.
29. `executeProposal(bytes32 _proposalId)`: (Permission: `CAN_EXECUTE_PROPOSAL`) Executes a proposal that has passed the voting period and met quorum/support requirements.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedSoulboundGuild
 * @dev A decentralized guild with soulbound membership, reputation, roles, tasks, and governance.
 *
 * Outline:
 * 1. Contract Definition: State variables, events, enums, structs.
 * 2. Soulbound Token (SBT) Core: Internal functions for minting/burning non-transferable tokens.
 * 3. Membership Management: Applying, inviting, approving, revoking membership.
 * 4. Reputation System: Awarding and penalizing reputation.
 * 5. Role Management: Creating, assigning roles, granting/revoking permissions.
 * 6. Role Progression: Updating roles based on reputation thresholds.
 * 7. Task System: Creating, submitting, verifying tasks for reputation.
 * 8. Governance System: Creating proposals, voting (with delegation), executing proposals.
 * 9. Permissioning: Internal helper to check permissions.
 * 10. View Functions: Querying state.
 * 11. Admin Functions: Ownership transfer.
 *
 * Function Summary:
 * 1.  constructor()
 * 2.  applyForMembership()
 * 3.  inviteMember(address _applicant)
 * 4.  approveMembershipApplication(address _applicant)
 * 5.  revokeMembership(address _member)
 * 6.  isMember(address _address)
 * 7.  getMemberSBTId(address _member)
 * 8.  getSBTBearer(uint256 _sbtId)
 * 9.  awardReputation(address _member, uint256 _amount)
 * 10. penalizeReputation(address _member, uint256 _amount)
 * 11. getReputation(address _member)
 * 12. createRole(bytes32 _roleId, string memory _name)
 * 13. assignRole(address _member, bytes32 _roleId)
 * 14. getMemberRole(address _member)
 * 15. getRoleDetails(bytes32 _roleId)
 * 16. grantRolePermission(bytes32 _roleId, bytes32 _permission)
 * 17. revokeRolePermission(bytes32 _roleId, bytes32 _permission)
 * 18. hasPermission(address _member, bytes32 _permission)
 * 19. setRoleReputationThreshold(bytes32 _roleId, uint256 _threshold)
 * 20. attemptRoleProgression(address _member)
 * 21. createTask(bytes32 _taskId, string memory _description, uint256 _reputationReward, address _assignee)
 * 22. submitTaskCompletion(bytes32 _taskId, string memory _proofDetails)
 * 23. verifyTaskCompletion(bytes32 _taskId)
 * 24. cancelTask(bytes32 _taskId)
 * 25. getTaskDetails(bytes32 _taskId)
 * 26. createProposal(bytes32 _proposalId, string memory _description, uint256 _votingPeriodBlocks)
 * 27. voteOnProposal(bytes32 _proposalId, bool _support)
 * 28. delegateVote(address _delegate)
 * 29. executeProposal(bytes32 _proposalId)
 * 30. getProposalState(bytes32 _proposalId)
 * 31. getProposalDetails(bytes32 _proposalId)
 * 32. getRolePermissions(bytes32 _roleId) (Added view helper)
 */
contract DecentralizedSoulboundGuild {

    // --- 1. Contract Definition ---

    address public owner; // Contract deployer / Admin

    // --- Events ---
    event MembershipApplied(address indexed applicant);
    event MembershipApproved(address indexed member, uint256 sbtId);
    event MembershipRevoked(address indexed member, uint256 sbtId);
    event ReputationAwarded(address indexed member, uint256 amount, uint256 newReputation);
    event ReputationPenalized(address indexed member, uint256 amount, uint256 newReputation);
    event RoleCreated(bytes32 indexed roleId, string name);
    event RoleAssigned(address indexed member, bytes32 indexed roleId);
    event PermissionGranted(bytes32 indexed roleId, bytes32 indexed permission);
    event PermissionRevoked(bytes32 indexed roleId, bytes32 indexed permission);
    event RoleReputationThresholdSet(bytes32 indexed roleId, uint256 threshold);
    event RoleProgressionAttempted(address indexed member, bytes32 indexed oldRoleId, bytes32 indexed newRoleId);
    event TaskCreated(bytes32 indexed taskId, address indexed creator, address indexed assignee, uint256 reputationReward);
    event TaskSubmitted(bytes32 indexed taskId, address indexed submitter);
    event TaskVerified(bytes32 indexed taskId, address indexed verifier);
    event TaskCancelled(bytes32 indexed taskId);
    event ProposalCreated(bytes32 indexed proposalId, address indexed creator);
    event Voted(bytes32 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event ProposalExecuted(bytes32 indexed proposalId);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // --- Structs & Enums ---

    struct Member {
        uint256 sbtId;
        uint256 reputation;
        bytes32 currentRoleId;
        bool exists; // Indicates if this address is a current member
        address voteDelegate; // Address this member delegates their vote to
    }

    struct Role {
        string name;
        mapping(bytes32 => bool) permissions; // Permission name => granted (true/false)
    }

    enum TaskStatus {
        Open, // Available for assignment
        Assigned, // Assigned to a member
        Submitted, // Assigned member submitted completion proof
        Verified, // Verified as complete, reputation awarded
        Cancelled // Task cancelled
    }

    struct Task {
        bytes32 taskId;
        address creator;
        string description;
        uint256 reputationReward;
        TaskStatus status;
        address assignee;
        address verifier; // Address who verified the task
        string proofDetails; // Details provided by the submitter
    }

    enum ProposalState {
        Pending,   // Created, waiting for voting period to start (not used in this simplified version, starts active)
        Active,    // Voting is open
        Succeeded, // Voting ended, passed
        Failed,    // Voting ended, failed
        Executed,  // Proposal logic has been executed
        Cancelled  // Proposal cancelled
    }

    struct Proposal {
        bytes32 proposalId;
        address creator;
        string description; // Description of the proposal
        uint256 submissionBlock; // Block number when proposal was created
        uint256 votingPeriodBlocks; // Duration of voting in blocks
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Voter address => voted (to prevent double voting)
        ProposalState state;
        // Note: This simplified proposal struct doesn't include execution data.
        // A real system would need to encode the actions to be taken.
        // Execution here will be symbolic or require off-chain action + on-chain record.
        // For more advanced execution, see comments in executeProposal.
    }

    // --- Mappings ---

    // Soulbound Token Mappings (Simplified ERC-721-like tracking)
    mapping(uint256 => address) private _sbtBearer; // SBT ID => Member Address
    mapping(address => uint256) private _memberSbtId; // Member Address => SBT ID
    uint256 private _sbtCounter; // Counter for unique SBT IDs

    // Membership & Reputation
    mapping(address => Member) public members;
    address[] private _memberAddresses; // To iterate/count members (careful with gas for large guilds)
    mapping(address => bool) public pendingApplications; // Applicant address => status

    // Roles & Permissions
    mapping(bytes32 => Role) public roles;
    bytes32 public guildMasterRoleId; // ID of the highest role, special privileges initially
    mapping(bytes32 => uint256) public roleReputationThresholds; // Role ID => reputation required to attain

    // Tasks
    mapping(bytes32 => Task) public tasks;
    // mapping(address => bytes32[]) public memberAssignedTasks; // Optional: track tasks assigned to a member

    // Governance
    mapping(bytes32 => Proposal) public proposals;
    // Voting power is calculated directly from member.reputation

    // --- Constants for Permissions (using keccak256 hash of strings for efficiency) ---
    bytes32 public constant CAN_INVITE_MEMBER = keccak256("CAN_INVITE_MEMBER");
    bytes32 public constant CAN_APPROVE_APPLICATION = keccak256("CAN_APPROVE_APPLICATION");
    bytes32 public constant CAN_REVOKE_MEMBERSHIP = keccak256("CAN_REVOKE_MEMBERSHIP");
    bytes32 public constant CAN_AWARD_REPUTATION = keccak256("CAN_AWARD_REPUTATION");
    bytes32 public constant CAN_PENALIZE_REPUTATION = keccak256("CAN_PENALIZE_REPUTATION");
    bytes32 public constant CAN_CREATE_ROLE = keccak256("CAN_CREATE_ROLE");
    bytes32 public constant CAN_ASSIGN_ROLE = keccak256("CAN_ASSIGN_ROLE");
    bytes32 public constant CAN_GRANT_PERMISSION = keccak256("CAN_GRANT_PERMISSION");
    bytes32 public constant CAN_REVOKE_PERMISSION = keccak256("CAN_REVOKE_PERMISSION");
    bytes32 public constant CAN_SET_ROLE_THRESHOLD = keccak256("CAN_SET_ROLE_THRESHOLD");
    bytes32 public constant CAN_TRIGGER_ROLE_PROGRESSION = keccak256("CAN_TRIGGER_ROLE_PROGRESSION"); // For `attemptRoleProgression`
    bytes32 public constant CAN_CREATE_TASK = keccak256("CAN_CREATE_TASK");
    bytes32 public constant CAN_VERIFY_TASK = keccak256("CAN_VERIFY_TASK");
    bytes32 public constant CAN_CANCEL_TASK = keccak256("CAN_CANCEL_TASK");
    bytes32 public constant CAN_CREATE_PROPOSAL = keccak256("CAN_CREATE_PROPOSAL");
    bytes32 public constant CAN_EXECUTE_PROPOSAL = keccak256("CAN_EXECUTE_PROPOSAL");

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlyMember(address _addr) {
        require(members[_addr].exists, "Not a guild member");
        _;
    }

    modifier onlyMemberCaller() {
        require(members[msg.sender].exists, "Caller is not a guild member");
        _;
    }

    // --- 2. Soulbound Token (SBT) Core (Internal) ---

    // Internal mint function - cannot be called externally or transferred
    function _mintSBT(address _to) internal returns (uint256) {
        require(_to != address(0), "Mint to the zero address");
        require(!members[_to].exists, "Address already has an SBT");

        _sbtCounter++;
        uint256 newTokenId = _sbtCounter;

        _sbtBearer[newTokenId] = _to;
        _memberSbtId[_to] = newTokenId;

        // Link SBT to the Member struct (created upon approval)
        members[_to].sbtId = newTokenId;
        members[_to].exists = true;

        // Standard ERC-721-like Mint event could be added if desired, but modified
        // emit Transfer(address(0), _to, newTokenId); // Use address(0) as sender for minting

        return newTokenId;
    }

    // Internal burn function - cannot be called externally
    function _burnSBT(uint256 _sbtId) internal {
        address bearer = _sbtBearer[_sbtId];
        require(bearer != address(0), "SBT does not exist");

        // Clear SBT mappings
        delete _sbtBearer[_sbtId];
        delete _memberSbtId[bearer];

        // Clear relevant Member data
        delete members[bearer]; // Or specifically members[bearer].exists = false and clear other fields

        // Remove from member address list (gas intensive, better to iterate and skip non-existent)
        // For simplicity, we won't remove from the array here to avoid complexities with shifting elements.
        // If iteration over members is needed, filter by members[address].exists.

        // Standard ERC-721-like Burn event could be added if desired, but modified
        // emit Transfer(bearer, address(0), _sbtId); // Use address(0) as receiver for burning
    }

    // Cannot implement transferFrom, safeTransferFrom, approve, getApproved, setApprovalForAll, isApprovedForAll
    // as these are Soulbound. The contract manages SBTs internally.

    // --- 3. Membership Management ---

    constructor() {
        owner = msg.sender;

        // Create initial Guild Master role
        bytes32 gmRoleId = keccak256("GUILD_MASTER");
        createRole(gmRoleId, "Guild Master");
        guildMasterRoleId = gmRoleId;

        // Grant all initial permissions to Guild Master
        roles[gmRoleId].permissions[CAN_INVITE_MEMBER] = true;
        roles[gmRoleId].permissions[CAN_APPROVE_APPLICATION] = true;
        roles[gmRoleId].permissions[CAN_REVOKE_MEMBERSHIP] = true;
        roles[gmRoleId].permissions[CAN_AWARD_REPUTATION] = true;
        roles[gmRoleId].permissions[CAN_PENALIZE_REPUTATION] = true;
        roles[gmRoleId].permissions[CAN_CREATE_ROLE] = true;
        roles[gmRoleId].permissions[CAN_ASSIGN_ROLE] = true;
        roles[gmRoleId].permissions[CAN_GRANT_PERMISSION] = true;
        roles[gmRoleId].permissions[CAN_REVOKE_PERMISSION] = true;
        roles[gmRoleId].permissions[CAN_SET_ROLE_THRESHOLD] = true;
        roles[gmRoleId].permissions[CAN_TRIGGER_ROLE_PROGRESSION] = true;
        roles[gmRoleId].permissions[CAN_CREATE_TASK] = true;
        roles[gmRoleId].permissions[CAN_VERIFY_TASK] = true;
        roles[gmRoleId].permissions[CAN_CANCEL_TASK] = true;
        roles[gmRoleId].permissions[CAN_CREATE_PROPOSAL] = true;
        roles[gmRoleId].permissions[CAN_EXECUTE_PROPOSAL] = true;

        // Mint first SBT and make deployer the Guild Master
        uint256 deployerSbtId = _mintSBT(msg.sender);
        members[msg.sender].currentRoleId = gmRoleId;
        members[msg.sender].reputation = 1000; // Start with some rep
        _memberAddresses.push(msg.sender); // Add to member list

        emit MembershipApproved(msg.sender, deployerSbtId); // Use Approved event for initial member
        emit RoleAssigned(msg.sender, gmRoleId);
    }

    /**
     * @dev Allows an address to apply for membership.
     */
    function applyForMembership() external {
        require(!members[msg.sender].exists, "Already a member");
        require(!pendingApplications[msg.sender], "Application already pending");

        pendingApplications[msg.sender] = true;
        emit MembershipApplied(msg.sender);
    }

    /**
     * @dev Allows a permitted member to invite someone directly.
     * @param _applicant The address to invite.
     */
    function inviteMember(address _applicant) external onlyMemberCaller {
        require(hasPermission(msg.sender, CAN_INVITE_MEMBER), "Caller does not have INVITE_MEMBER permission");
        require(!members[_applicant].exists, "Already a member");
        require(!pendingApplications[_applicant], "Application already pending");

        // An invitation is essentially an auto-approved application
        delete pendingApplications[_applicant]; // In case they applied manually
        _approveAndMintMember(_applicant); // Directly approve and mint
        // emit MembershipApplied(_applicant); // Can emit applied for consistency, or just approved
    }

    /**
     * @dev Approves a pending membership application and mints an SBT.
     * @param _applicant The address whose application to approve.
     */
    function approveMembershipApplication(address _applicant) external onlyMemberCaller {
        require(hasPermission(msg.sender, CAN_APPROVE_APPLICATION), "Caller does not have APPROVE_APPLICATION permission");
        require(pendingApplications[_applicant], "No pending application from this address");
        require(!members[_applicant].exists, "Address is already a member");

        delete pendingApplications[_applicant];
        _approveAndMintMember(_applicant);
    }

    /**
     * @dev Internal function to handle member approval and SBT minting.
     * @param _applicant The address to approve.
     */
    function _approveAndMintMember(address _applicant) internal {
        uint256 newSbtId = _mintSBT(_applicant);

        // Assign default member role and initial reputation (can be customized)
        bytes32 defaultRoleId = keccak256("MEMBER"); // Define a default role ID constant
        if (!roles[defaultRoleId].permissions[bytes32(0)]) { // Check if role exists using a dummy permission check
             createRole(defaultRoleId, "Member"); // Create if it doesn't exist
        }
        members[_applicant].currentRoleId = defaultRoleId;
        members[_applicant].reputation = 10; // Initial reputation

        _memberAddresses.push(_applicant); // Add to member list

        emit MembershipApproved(_applicant, newSbtId);
        emit RoleAssigned(_applicant, defaultRoleId);
    }

    /**
     * @dev Revokes membership for an address, burning their SBT.
     * @param _member The address of the member to revoke.
     */
    function revokeMembership(address _member) external onlyMemberCaller onlyMember(_member) {
        require(hasPermission(msg.sender, CAN_REVOKE_MEMBERSHIP), "Caller does not have REVOKE_MEMBERSHIP permission");
        require(_member != msg.sender, "Cannot revoke your own membership"); // Prevent self-locking

        uint256 sbtId = members[_member].sbtId;
        _burnSBT(sbtId);

        // Remove from _memberAddresses - highly gas inefficient for large lists
        // A different data structure (e.g., linked list or mapping of indices) would be better
        // For this example, we'll leave it as is, acknowledging the limitation.
        // Iterating _memberAddresses later needs to check members[address].exists.

        emit MembershipRevoked(_member, sbtId);
    }

    /**
     * @dev Checks if an address is a current guild member.
     * @param _address The address to check.
     * @return True if the address is a member, false otherwise.
     */
    function isMember(address _address) public view returns (bool) {
        return members[_address].exists;
    }

     /**
     * @dev Gets the SBT ID for a given member address.
     * @param _member The member address.
     * @return The SBT ID.
     */
    function getMemberSBTId(address _member) external view onlyMember(_member) returns (uint256) {
        return members[_member].sbtId;
    }

    /**
     * @dev Gets the member address for a given SBT ID.
     * @param _sbtId The SBT ID.
     * @return The member address.
     */
    function getSBTBearer(uint256 _sbtId) external view returns (address) {
        return _sbtBearer[_sbtId];
    }


    // --- 4. Reputation System ---

    /**
     * @dev Awards reputation points to a member.
     * @param _member The member to award reputation to.
     * @param _amount The amount of reputation to award.
     */
    function awardReputation(address _member, uint256 _amount) external onlyMemberCaller onlyMember(_member) {
        require(hasPermission(msg.sender, CAN_AWARD_REPUTATION), "Caller does not have AWARD_REPUTATION permission");

        uint256 oldRep = members[_member].reputation;
        members[_member].reputation += _amount;
        // Potential optimization: Check for role progression here or in attemptRoleProgression

        emit ReputationAwarded(_member, _amount, members[_member].reputation);
    }

    /**
     * @dev Deducts reputation points from a member.
     * @param _member The member to penalize.
     * @param _amount The amount of reputation to deduct.
     */
    function penalizeReputation(address _member, uint256 _amount) external onlyMemberCaller onlyMember(_member) {
        require(hasPermission(msg.sender, CAN_PENALIZE_REPUTATION), "Caller does not have PENALIZE_REPUTATION permission");

        uint256 oldRep = members[_member].reputation;
        if (members[_member].reputation < _amount) {
            members[_member].reputation = 0;
        } else {
            members[_member].reputation -= _amount;
        }
        // Potential logic: If reputation drops below a threshold, maybe demote role or revoke membership

        emit ReputationPenalized(_member, _amount, members[_member].reputation);
    }

    /**
     * @dev Gets the current reputation of a member.
     * @param _member The member's address.
     * @return The member's reputation points.
     */
    function getReputation(address _member) external view onlyMember(_member) returns (uint256) {
        return members[_member].reputation;
    }


    // --- 5. Role Management ---

    /**
     * @dev Creates a new role.
     * @param _roleId A unique identifier for the role (e.g., keccak256("ELDER")).
     * @param _name The human-readable name of the role.
     */
    function createRole(bytes32 _roleId, string memory _name) public onlyMemberCaller { // Public so constructor can call
        require(hasPermission(msg.sender, CAN_CREATE_ROLE), "Caller does not have CREATE_ROLE permission");
        // Check if roleId already exists (check permissions mapping state)
        bytes32 dummyPermissionCheck = bytes32(0); // Using a known default state value
        require(!roles[_roleId].permissions[dummyPermissionCheck], "Role ID already exists");
        require(_roleId != bytes32(0), "Role ID cannot be zero");

        roles[_roleId].name = _name;

        emit RoleCreated(_roleId, _name);
    }

    /**
     * @dev Assigns an existing role to a member.
     * @param _member The member to assign the role to.
     * @param _roleId The ID of the role to assign.
     */
    function assignRole(address _member, bytes32 _roleId) external onlyMemberCaller onlyMember(_member) {
        require(hasPermission(msg.sender, CAN_ASSIGN_ROLE), "Caller does not have ASSIGN_ROLE permission");
        // Check if roleId exists
        bytes32 dummyPermissionCheck = bytes32(0);
        require(roles[_roleId].permissions[dummyPermissionCheck], "Role ID does not exist");

        members[_member].currentRoleId = _roleId;

        emit RoleAssigned(_member, _roleId);
    }

    /**
     * @dev Gets the ID of the role currently assigned to a member.
     * @param _member The member's address.
     * @return The role ID.
     */
    function getMemberRole(address _member) external view onlyMember(_member) returns (bytes32) {
        return members[_member].currentRoleId;
    }

     /**
     * @dev Gets the name of a role.
     * @param _roleId The role ID.
     * @return The role name.
     */
    function getRoleDetails(bytes32 _roleId) external view returns (string memory) {
         bytes32 dummyPermissionCheck = bytes32(0);
         require(roles[_roleId].permissions[dummyPermissionCheck], "Role ID does not exist");
         return roles[_roleId].name;
    }

    /**
     * @dev Grants a specific permission to a role.
     * @param _roleId The ID of the role.
     * @param _permission The permission identifier (e.g., `CAN_CREATE_TASK`).
     */
    function grantRolePermission(bytes32 _roleId, bytes32 _permission) external onlyMemberCaller {
        require(hasPermission(msg.sender, CAN_GRANT_PERMISSION), "Caller does not have GRANT_PERMISSION permission");
         bytes32 dummyPermissionCheck = bytes32(0);
         require(roles[_roleId].permissions[dummyPermissionCheck], "Role ID does not exist");

        roles[_roleId].permissions[_permission] = true;

        emit PermissionGranted(_roleId, _permission);
    }

    /**
     * @dev Revokes a specific permission from a role.
     * @param _roleId The ID of the role.
     * @param _permission The permission identifier.
     */
    function revokeRolePermission(bytes32 _roleId, bytes32 _permission) external onlyMemberCaller {
        require(hasPermission(msg.sender, CAN_REVOKE_PERMISSION), "Caller does not have REVOKE_PERMISSION permission");
         bytes32 dummyPermissionCheck = bytes32(0);
         require(roles[_roleId].permissions[dummyPermissionCheck], "Role ID does not exist");

        roles[_roleId].permissions[_permission] = false;

        emit PermissionRevoked(_roleId, _permission);
    }

     /**
     * @dev Gets all permissions for a role. (Note: Iterating mapping keys isn't standard,
     * this is a simplified view - real implementation might store permissions in an array in Role struct).
     * This view can only check if a *specific* permission is granted.
     * @param _roleId The ID of the role.
     * @return True if a specific permission is granted, false otherwise.
     */
    // Example usage: call getRolePermissions(roleId, CAN_CREATE_TASK)
    function getRolePermissions(bytes32 _roleId, bytes32 _permission) external view returns (bool) {
        bytes32 dummyPermissionCheck = bytes32(0);
        require(roles[_roleId].permissions[dummyPermissionCheck], "Role ID does not exist");
        return roles[_roleId].permissions[_permission];
    }


    // --- 6. Role Progression ---

    /**
     * @dev Sets the reputation threshold required to attain a specific role.
     * This helps define the progression path.
     * @param _roleId The ID of the role.
     * @param _threshold The minimum reputation required for this role.
     */
    function setRoleReputationThreshold(bytes32 _roleId, uint256 _threshold) external onlyMemberCaller {
        require(hasPermission(msg.sender, CAN_SET_ROLE_THRESHOLD), "Caller does not have SET_ROLE_THRESHOLD permission");
         bytes32 dummyPermissionCheck = bytes32(0);
         require(roles[_roleId].permissions[dummyPermissionCheck], "Role ID does not exist");

        roleReputationThresholds[_roleId] = _threshold;

        emit RoleReputationThresholdSet(_roleId, _threshold);
    }

    /**
     * @dev Attempts to progress a member's role based on their reputation.
     * Can be called by a permitted member or potentially triggered internally
     * after reputation changes (though internal triggers add gas cost).
     * Finds the highest role the member qualifies for by reputation.
     * @param _member The member to check for progression.
     */
    function attemptRoleProgression(address _member) external onlyMemberCaller onlyMember(_member) {
        require(hasPermission(msg.sender, CAN_TRIGGER_ROLE_PROGRESSION), "Caller does not have TRIGGER_ROLE_PROGRESSION permission");

        uint256 currentRep = members[_member].reputation;
        bytes32 currentRoleId = members[_member].currentRoleId;
        bytes32 bestRoleId = currentRoleId;
        uint256 bestThreshold = roleReputationThresholds[currentRoleId];

        // This requires iterating through all *defined* roles to find the highest qualifying one.
        // Storing role IDs in an array would be better for iteration.
        // For simplicity, this example assumes you know role IDs or manage them off-chain for lookup.
        // A more complete system would need to store role IDs in an array upon creation.
        // **Simplified Logic:** Check against known higher-tier roles.
        // **Realistic Logic:** Need an array of role IDs to iterate `roleIds[]`.

        // --- Simplified Example Logic (Assumes specific known roles exist and have thresholds) ---
        bytes32 elderRoleId = keccak256("ELDER");
        bytes32 veteranRoleId = keccak256("VETERAN"); // Example intermediate role
        bytes32 memberRoleId = keccak256("MEMBER");

        // Check Elder role
        if (roleReputationThresholds[elderRoleId] > 0 && currentRep >= roleReputationThresholds[elderRoleId]) {
             // If current role isn't Elder and Elder has a higher threshold than current best
             if (currentRoleId != elderRoleId && roleReputationThresholds[elderRoleId] > bestThreshold) {
                 bestRoleId = elderRoleId;
                 bestThreshold = roleReputationThresholds[elderRoleId];
             }
        }
        // Check Veteran role (if applicable in hierarchy)
         if (roleReputationThresholds[veteranRoleId] > 0 && currentRep >= roleReputationThresholds[veteranRoleId]) {
             // If current role isn't Veteran and Veteran has a higher threshold than current best (but lower than Elder if applicable)
              if (currentRoleId != veteranRoleId && roleReputationThresholds[veteranRoleId] > bestThreshold) {
                 bestRoleId = veteranRoleId;
                 bestThreshold = roleReputationThresholds[veteranRoleId];
             }
        }
        // Ensure default Member role is assigned if no higher role is met and current isn't default
         if (roleReputationThresholds[memberRoleId] > 0 && currentRep >= roleReputationThresholds[memberRoleId]) {
              if (currentRoleId != memberRoleId && roleReputationThresholds[memberRoleId] > bestThreshold) {
                 // Only assign if member qualifies for base member role and current isn't already better
                 // This logic needs refinement based on the actual hierarchy.
                 // A proper system would sort roles by threshold and find the highest match.
             }
         }


        // --- End Simplified Example Logic ---

        // Assign the best qualifying role if it's different from the current one
        if (bestRoleId != currentRoleId) {
            members[_member].currentRoleId = bestRoleId;
            emit RoleProgressionAttempted(_member, currentRoleId, bestRoleId);
            emit RoleAssigned(_member, bestRoleId); // Also emit RoleAssigned for clarity
        } else {
             // Emit an event even if no progression occurred, could be useful for logging
             emit RoleProgressionAttempted(_member, currentRoleId, currentRoleId);
        }
    }


    // --- 7. Task/Quest System ---

    /**
     * @dev Creates a new task that can be assigned to a member for reputation.
     * @param _taskId A unique ID for the task.
     * @param _description A description of the task.
     * @param _reputationReward The reputation points awarded upon verification.
     * @param _assignee The member assigned to the task (address(0) if open).
     */
    function createTask(
        bytes32 _taskId,
        string memory _description,
        uint256 _reputationReward,
        address _assignee
    ) external onlyMemberCaller {
        require(hasPermission(msg.sender, CAN_CREATE_TASK), "Caller does not have CREATE_TASK permission");
        require(tasks[_taskId].creator == address(0), "Task ID already exists"); // Check if taskId is unused
        require(_taskId != bytes32(0), "Task ID cannot be zero");
        if (_assignee != address(0)) {
            require(members[_assignee].exists, "Assignee must be a member");
        }

        tasks[_taskId] = Task({
            taskId: _taskId,
            creator: msg.sender,
            description: _description,
            reputationReward: _reputationReward,
            status: _assignee == address(0) ? TaskStatus.Open : TaskStatus.Assigned,
            assignee: _assignee,
            verifier: address(0), // Verifier set upon verification
            proofDetails: "" // Proof details set upon submission
        });

        // If assigning to a member, track it (optional, see struct definition)
        // if (_assignee != address(0)) { memberAssignedTasks[_assignee].push(_taskId); }

        emit TaskCreated(_taskId, msg.sender, _assignee, _reputationReward);
    }

    /**
     * @dev Allows the assigned member to submit proof of task completion.
     * @param _taskId The ID of the task.
     * @param _proofDetails Details/link/hash of the proof.
     */
    function submitTaskCompletion(bytes32 _taskId, string memory _proofDetails) external onlyMemberCaller {
        Task storage task = tasks[_taskId];
        require(task.creator != address(0), "Task does not exist"); // Check if task exists
        require(task.status == TaskStatus.Assigned, "Task is not in Assigned status");
        require(task.assignee == msg.sender, "Only the assigned member can submit");

        task.status = TaskStatus.Submitted;
        task.proofDetails = _proofDetails;

        emit TaskSubmitted(_taskId, msg.sender);
    }

    /**
     * @dev Allows a permitted member (e.g., creator, verifier role) to verify a submitted task and award reputation.
     * @param _taskId The ID of the task to verify.
     */
    function verifyTaskCompletion(bytes32 _taskId) external onlyMemberCaller {
        require(hasPermission(msg.sender, CAN_VERIFY_TASK), "Caller does not have VERIFY_TASK permission");

        Task storage task = tasks[_taskId];
        require(task.creator != address(0), "Task does not exist");
        require(task.status == TaskStatus.Submitted, "Task is not in Submitted status");
        require(task.assignee != address(0), "Task must have an assignee"); // Should always be true if status is Submitted

        task.status = TaskStatus.Verified;
        task.verifier = msg.sender;

        // Award reputation to the assignee
        members[task.assignee].reputation += task.reputationReward;
        // Consider calling attemptRoleProgression here or in awardReputation

        emit TaskVerified(_taskId, msg.sender);
        emit ReputationAwarded(task.assignee, task.reputationReward, members[task.assignee].reputation);
    }

    /**
     * @dev Allows a permitted member (e.g., creator, admin) to cancel a task.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelTask(bytes32 _taskId) external onlyMemberCaller {
        // Permission check could be CAN_CREATE_TASK or a dedicated CAN_CANCEL_TASK
        require(hasPermission(msg.sender, CAN_CREATE_TASK) || hasPermission(msg.sender, CAN_CANCEL_TASK), "Caller does not have permission to cancel tasks");

        Task storage task = tasks[_taskId];
        require(task.creator != address(0), "Task does not exist");
        require(task.status != TaskStatus.Verified && task.status != TaskStatus.Cancelled, "Task is already completed or cancelled");

        task.status = TaskStatus.Cancelled;
        // No reputation awarded/deducted

        emit TaskCancelled(_taskId);
    }

     /**
     * @dev Retrieves details about a task.
     * @param _taskId The ID of the task.
     * @return Task details.
     */
    function getTaskDetails(bytes32 _taskId) external view returns (
        bytes32 taskId,
        address creator,
        string memory description,
        uint256 reputationReward,
        TaskStatus status,
        address assignee,
        address verifier,
        string memory proofDetails
    ) {
        Task storage task = tasks[_taskId];
        require(task.creator != address(0), "Task does not exist"); // Check if task exists

        return (
            task.taskId,
            task.creator,
            task.description,
            task.reputationReward,
            task.status,
            task.assignee,
            task.verifier,
            task.proofDetails
        );
    }


    // --- 8. Governance System ---

    /**
     * @dev Creates a new governance proposal.
     * @param _proposalId A unique ID for the proposal.
     * @param _description Description of the proposal (e.g., "Change voting period to 100 blocks").
     * @param _votingPeriodBlocks The duration of the voting period in blocks.
     */
    function createProposal(
        bytes32 _proposalId,
        string memory _description,
        uint256 _votingPeriodBlocks
        // In a real system, you'd pass parameters here detailing the action to be taken (e.g., target address, function signature, data)
    ) external onlyMemberCaller {
        require(hasPermission(msg.sender, CAN_CREATE_PROPOSAL), "Caller does not have CREATE_PROPOSAL permission");
        // Optional: Require minimum reputation to create proposal
        // require(members[msg.sender].reputation >= minReputationForProposal, "Not enough reputation to create proposal");
        require(proposals[_proposalId].creator == address(0), "Proposal ID already exists"); // Check if proposalId is unused
        require(_proposalId != bytes32(0), "Proposal ID cannot be zero");
        require(_votingPeriodBlocks > 0, "Voting period must be greater than 0");

        proposals[_proposalId] = Proposal({
            proposalId: _proposalId,
            creator: msg.sender,
            description: _description,
            submissionBlock: block.number,
            votingPeriodBlocks: _votingPeriodBlocks,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool),
            state: ProposalState.Active
            // actionType: _actionType, // Example of how action could be stored
            // actionData: _actionData // Example of how action data could be stored
        });

        emit ProposalCreated(_proposalId, msg.sender);
    }

    /**
     * @dev Allows a member or their delegate to vote on an active proposal.
     * Voting power is based on the member's reputation at the time of voting.
     * @param _proposalId The ID of the proposal.
     * @param _support True for a vote in support, false for against.
     */
    function voteOnProposal(bytes32 _proposalId, bool _support) external onlyMemberCaller {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.creator != address(0), "Proposal does not exist");
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.number <= proposal.submissionBlock + proposal.votingPeriodBlocks, "Voting period has ended");

        // Determine who is actually casting the vote (could be delegate)
        address voterAddress = msg.sender;
        // Find the root delegator if msg.sender is a delegatee
        // (A full system would trace the delegation chain)
        // For simplicity, we just check if msg.sender *is* a delegatee *for someone*.
        // The vote should be counted for the *delegator*, but recorded under the *voter* for tracking.
        // A better way is to find the *root* voter whose reputation counts.
        address rootVoter = voterAddress;
        // Simple delegation check: if sender delegates to someone, use sender's rep directly.
        // Correct delegation: Find the address whose reputation is being used.
        // Let's stick to the simpler model: voter's reputation counts, regardless of delegation state,
        // but they can delegate the *act* of calling voteOnProposal. This requires the delegate
        // to call *as* the delegator (e.g., using meta-transactions or simply trusting the delegate).
        // A more robust system involves tracking vote weight per address and allowing delegatees to cast that weight.

        // Let's implement vote delegation properly: the delegatee calls vote, but the vote is recorded for the delegator.
        address delegator = msg.sender;
        // Find the ultimate delegator in the chain if delegation is transitive (this adds complexity)
        // For simplicity, let's assume direct delegation only: A -> B means B can vote for A.
        // The voter is `msg.sender`. We check if `msg.sender` is a delegatee *for someone*.
        // This requires iterating `voteDelegates` mapping keys, which is inefficient.
        // Alternative: `voteDelegates[msg.sender]` stores the address *they* delegate TO.
        // We need a mapping `address => address[]` storing who delegates *to* an address. Or iterate.

        // Let's refine delegation: `members[address].voteDelegate` is who *this* address delegates TO.
        // When voting, we check if `msg.sender` is a delegate *for someone*.
        // This is hard to check efficiently on-chain.
        // Simpler approach: The caller (`msg.sender`) uses their own vote weight, *unless* they are
        // casting the vote *on behalf of* someone who designated them. This requires a different function signature,
        // like `voteOnProposalFor(address _delegator, bytes32 _proposalId, bool _support)`.
        // Let's update `voteOnProposal` to find the root voting address whose reputation counts.

        address currentAddress = msg.sender;
        address rootVotingAddress = currentAddress;
         // Follow the delegation chain *backwards* to find the address whose reputation counts.
         // This requires iterating ALL members' delegates, which is bad.
         // Alternative structure: `address => address` mapping for delegatees: `isDelegateeFor[delegatee] = delegator`
         // Or `address => address` mapping for who delegates *to* this address: `delegatedFrom[delegatee] = delegator` (doesn't handle multiple delegators)

        // Let's simplify delegation logic significantly for the example:
        // `delegateVote(address _delegate)` sets who *I* delegate *my* vote TO (`members[msg.sender].voteDelegate`).
        // `voteOnProposal` is called by *either* the member *or* their delegate.
        // The reputation that counts is the *member's* reputation, not the delegate's.
        // Need to prevent double voting by the member and their delegate.
        // We'll track `proposal.hasVoted[memberAddress]`.

        address memberAddress;
        // Check if msg.sender is a member
        if (members[msg.sender].exists) {
            memberAddress = msg.sender;
        } else {
             // Check if msg.sender is a delegate for someone (INEFFICIENT - needs a different lookup structure)
             // For simplicity, let's require the voter to be a member. Delegation means the delegate
             // is *trusted* to call `voteOnProposal` *as* the member (e.g., using a signed message validated off-chain).
             // Or the function needs to be `voteAsDelegate(address _member, bytes32 _proposalId, bool _support, bytes sig)`.

             // Let's revert to the simpler model where `voteOnProposal` can *only* be called by a member.
             // Delegation means the delegate calls the function *on behalf of* the delegator,
             // but this interaction happens outside the contract (e.g., signed message).
             // Or, the delegate calls with their *own* address, and we check if they are a registered delegatee.
             // This needs the inverse mapping: `mapping(address => address[]) delegateeToDelegators`. Still inefficient.

             // Okay, simplest model for this example: A member calls `voteOnProposal`.
             // The vote weight comes from their reputation.
             // The `delegateVote` function *only* updates who *they* delegate TO, which might be used off-chain or in a more complex future version.
             // For *this* example, delegateVote is mostly symbolic for on-chain representation of delegation.
             // The actual voting logic will use msg.sender's reputation.

             memberAddress = msg.sender; // Must be a member due to onlyMemberCaller
        }


        require(!proposal.hasVoted[memberAddress], "Member has already voted");
        uint256 votingPower = members[memberAddress].reputation;
        require(votingPower > 0, "Member must have reputation to vote"); // Prevent 0 rep members from voting

        proposal.hasVoted[memberAddress] = true;

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        emit Voted(_proposalId, memberAddress, _support, votingPower); // Emit voter's address (msg.sender)
    }

    /**
     * @dev Allows a member to delegate their voting power to another member.
     * Note: In this simplified model, delegation is recorded on-chain but
     * the actual `voteOnProposal` function uses the caller's reputation.
     * A true delegation system would need `voteOnProposalAsDelegate(address _delegator, ...)`
     * or track vote weight differently. This function primarily signals delegation intent.
     * @param _delegate The address of the member to delegate to. address(0) to clear delegation.
     */
    function delegateVote(address _delegate) external onlyMemberCaller {
         if (_delegate != address(0)) {
            require(members[_delegate].exists, "Delegatee must be a guild member");
            require(_delegate != msg.sender, "Cannot delegate vote to yourself");
         }
        // Prevent circular delegation is hard to check on-chain efficiently. Trust model applies.

        members[msg.sender].voteDelegate = _delegate;

        emit VoteDelegated(msg.sender, _delegate);
    }

    /**
     * @dev Executes a proposal that has passed its voting period and met requirements.
     * Note: The execution logic here is a placeholder. A real system needs
     * to safely parse and execute the intended action (e.g., call another contract,
     * change a state variable based on encoded `actionType` and `actionData`).
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(bytes32 _proposalId) external onlyMemberCaller {
         require(hasPermission(msg.sender, CAN_EXECUTE_PROPOSAL), "Caller does not have EXECUTE_PROPOSAL permission");

        Proposal storage proposal = proposals[_proposalId];
        require(proposal.creator != address(0), "Proposal does not exist");
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.number > proposal.submissionBlock + proposal.votingPeriodBlocks, "Voting period has not ended");

        // Determine if proposal passed (simple majority based on reputation)
        // Add quorum logic if needed (e.g., minimum total voting power required)
        bool passed = proposal.votesFor > proposal.votesAgainst;

        if (passed) {
            proposal.state = ProposalState.Succeeded;

            // --- EXECUTION LOGIC PLACEHOLDER ---
            // This is the complex part. How does the contract know *what* to do?
            // Option 1 (Simple): Proposals only affect internal guild state (e.g., changing parameters).
            //    e.g., If proposal was to change voting period: `if (proposal.actionType == keccak256("SET_VOTING_PERIOD")) { votingPeriod = abi.decode(proposal.actionData, (uint256)); }`
            // Option 2 (Complex): Proposals trigger external contract calls. Requires `address target; bytes callData;` in the Proposal struct and safe low-level calls. Dangerous if not secured.
            // For this example, let's assume proposals are for *internal* state changes or symbolic/off-chain actions.
            // We'll just mark it as executed.
            proposal.state = ProposalState.Executed; // Mark as executed after deciding outcome

            emit ProposalExecuted(_proposalId);
        } else {
            proposal.state = ProposalState.Failed;
        }
    }

    /**
     * @dev Gets the current state of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return The state of the proposal.
     */
    function getProposalState(bytes32 _proposalId) external view returns (ProposalState) {
        require(proposals[_proposalId].creator != address(0), "Proposal does not exist");
        return proposals[_proposalId].state;
    }

    /**
     * @dev Gets details about a proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal details.
     */
    function getProposalDetails(bytes32 _proposalId) external view returns (
        bytes32 proposalId,
        address creator,
        string memory description,
        uint256 submissionBlock,
        uint256 votingPeriodBlocks,
        uint256 votesFor,
        uint256 votesAgainst,
        ProposalState state
    ) {
         Proposal storage proposal = proposals[_proposalId];
         require(proposal.creator != address(0), "Proposal does not exist");

         return (
             proposal.proposalId,
             proposal.creator,
             proposal.description,
             proposal.submissionBlock,
             proposal.votingPeriodBlocks,
             proposal.votesFor,
             proposal.votesAgainst,
             proposal.state
         );
    }


    // --- 9. Permissioning (Internal) ---

    /**
     * @dev Internal helper to check if a member has a specific permission via their role.
     * @param _member The member's address.
     * @param _permission The permission identifier to check.
     * @return True if the member has the permission, false otherwise.
     */
    function _hasPermission(address _member, bytes32 _permission) internal view returns (bool) {
        if (!members[_member].exists) {
            return false; // Non-members have no permissions
        }
        bytes32 roleId = members[_member].currentRoleId;
        // Check if role exists and has the permission
        return roles[roleId].permissions[_permission];
    }

    // Public wrapper for _hasPermission for external queries
    function hasPermission(address _member, bytes32 _permission) public view onlyMember(_member) returns (bool) {
        return _hasPermission(_member, _permission);
    }

    // --- 10. View Functions (Additional useful views) ---

     /**
     * @dev Gets the total number of existing members.
     * Note: This iterates the memberAddresses array, which can be gas-intensive for large guilds.
     * A dedicated member counter updated on mint/burn would be more efficient.
     */
    function getTotalMembers() external view returns (uint256) {
        uint256 count = 0;
        for(uint i = 0; i < _memberAddresses.length; i++){
            if(members[_memberAddresses[i]].exists){
                count++;
            }
        }
        return count;
    }

     /**
     * @dev Gets a paginated list of member addresses. Highly gas-intensive for large guilds.
     * Use with caution or prefer off-chain indexing.
     */
    // function getMemberAddresses(uint256 _offset, uint256 _limit) external view returns (address[] memory) {
    //     uint256 total = _memberAddresses.length;
    //     require(_offset < total, "Offset out of bounds");
    //     uint256 endIndex = _offset + _limit;
    //     if (endIndex > total) {
    //         endIndex = total;
    //     }
    //     uint256 resultCount = 0;
    //     address[] memory result = new address[](_limit); // Allocate max possible

    //     for (uint i = _offset; i < endIndex; i++) {
    //          if(members[_memberAddresses[i]].exists) { // Only include existing members
    //             result[resultCount] = _memberAddresses[i];
    //             resultCount++;
    //          }
    //     }
    //     // Need to resize array if not all slots were filled (e.g., due to removed members)
    //     address[] memory finalResult = new address[](resultCount);
    //     for(uint i = 0; i < resultCount; i++) {
    //         finalResult[i] = result[i];
    //     }
    //     return finalResult;
    // }


    // --- 11. Admin Functions ---

    /**
     * @dev Transfers ownership of the contract.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be the zero address");
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }
}
```