Okay, here is a Solidity smart contract for a "Decentralized Autonomous Guild (DAG)". This contract incorporates concepts like role-based permissions, on-chain reputation for task completion, structured project management with tasks, flexible governance for treasury spending and generic actions, and parameterized rules, aiming for over 20 functions and avoiding direct duplication of standard open-source patterns.

It's important to note that this is a complex system. A production-ready contract would require significant auditing, gas optimization, and potentially more robust data structures and error handling.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedAutonomousGuild
 * @dev A sophisticated smart contract representing a Decentralized Autonomous Guild (DAG).
 *      Members apply, are voted in, earn reputation by completing project tasks,
 *      manage a treasury, propose and vote on various actions including arbitrary
 *      contract calls, and operate under dynamically adjustable parameters.
 *      Features include role-based permissions, task-based reputation, and
 *      structured project workflows.
 */

/**
 * @title Outline & Function Summary
 *
 * I. Core Guild Management
 *    - constructor: Initializes the guild, sets initial parameters and roles.
 *    - pauseGuild: Pauses most guild operations (governance controlled).
 *    - unpauseGuild: Unpauses guild operations (governance controlled).
 *    - setGovernanceParameter: Updates core governance parameters via proposal.
 *    - emergencyShutdown: Allows a designated emergency role to shut down critical operations.
 *    - recoverERC20: Allows governance to recover accidentally sent ERC20 tokens.
 *    - recoverERC721: Allows governance to recover accidentally sent ERC721 tokens.
 *
 * II. Membership & Identity
 *    - applyForMembership: Allows anyone to submit a membership application.
 *    - voteOnMembershipApplication: Members vote on pending applications.
 *    - assignRole: Assigns a specific role to a member (permission controlled).
 *    - removeRole: Removes a role from a member (permission controlled).
 *    - updateMemberProfileHash: Members can update a hash pointing to off-chain profile data.
 *    - getMemberProfile: Retrieves a member's status, reputation, roles, and profile hash. (View)
 *    - isMember: Checks if an address is an active member. (View)
 *    - hasRole: Checks if a member has a specific role. (View)
 *
 * III. Treasury Management
 *    - depositTreasury: Allows anyone to deposit funds into the guild treasury.
 *    - proposeTreasurySpend: Proposes spending funds from the treasury.
 *    - voteOnTreasurySpend: Members vote on a treasury spend proposal.
 *    - executeTreasurySpend: Executes a passed treasury spend proposal.
 *    - getTreasuryBalance: Gets the current balance of the treasury. (View)
 *
 * IV. Project & Task Management
 *    - proposeProject: Members propose a new project, potentially with initial funding.
 *    - voteOnProjectProposal: Members vote on a project proposal (including funding approval).
 *    - assignMemberToTask: Assigns a guild member to a specific task within a project (permission controlled).
 *    - updateTaskStatus: Allows assigned member or authorized role to update task progress.
 *    - submitTaskDeliverablesHash: Allows assigned member to submit proof of task completion.
 *    - approveTaskCompletion: Allows authorized role to approve task completion.
 *    - awardReputationForTask: Awards reputation upon task completion approval.
 *    - getProjectDetails: Retrieves details of a specific project. (View)
 *    - getTaskDetails: Retrieves details of a specific task within a project. (View)
 *    - listProjectsByStatus: Lists project IDs filtered by status. (View)
 *
 * V. Governance & Proposals (beyond specific types)
 *    - proposeGenericAction: Proposes an arbitrary call to another contract (highly sensitive, governance controlled).
 *    - voteOnGenericAction: Members vote on a generic action proposal.
 *    - executeGenericAction: Executes a passed generic action proposal.
 *    - getProposalDetails: Retrieves details of any proposal. (View)
 *    - getProposalVoteCount: Gets current vote tally for a proposal. (View)
 *
 * VI. Reputation System
 *    - getReputationScore: Retrieves the reputation score for a member. (View)
 *
 * Total Functions: 30+
 */

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for initial setup/emergency role

contract DecentralizedAutonomousGuild is Ownable {
    using Address for address;

    // --- Enums ---
    enum MemberStatus { Applicant, Active, Inactive, Banned }
    enum ProposalStatus { Open, Passed, Failed, Executed, Cancelled }
    enum ProposalType { Membership, TreasurySpend, Project, GenericAction, ParameterChange }
    enum ProjectStatus { Proposed, Approved, InProgress, NeedsReview, Completed, Cancelled }
    enum TaskStatus { Open, Assigned, InProgress, NeedsReview, Completed, Cancelled }

    // --- Structs ---
    struct Member {
        address memberAddress;
        MemberStatus status;
        uint256 reputation;
        uint256 joinedTimestamp;
        bytes profileHash; // IPFS hash or similar for off-chain data
        // Mapping roleId => bool, indicates if member has this role
        mapping(uint256 => bool) roles;
    }

    struct Role {
        uint256 id;
        string name;
        // Mapping permissionName => bool
        mapping(string => bool) permissions;
        uint256 votingWeightMultiplier; // e.g., 100 = 1x, 200 = 2x
    }

    struct Task {
        uint256 id;
        uint256 projectId;
        address assignedMember;
        TaskStatus status;
        string description;
        bytes deliverablesHash; // IPFS hash or similar
        uint256 reputationAward; // Reputation points awarded upon completion
        uint256 deadline;
    }

    struct Project {
        uint256 id;
        address proposer;
        ProjectStatus status;
        string name;
        string descriptionHash; // IPFS hash or similar
        uint256 fundingAmount; // Amount requested/approved from treasury
        uint256 creationTime;
        uint256 deadline;
        uint256[] taskIds;
    }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        address proposer;
        ProposalStatus status;
        uint256 creationTime;
        uint256 votingDeadline;
        uint256 totalWeightedVotes; // Sum of weighted votes (yay + nay)
        uint256 totalYayVotes; // Sum of weighted yay votes
        uint256 totalNayVotes; // Sum of weighted nay votes
        mapping(address => bool) hasVoted; // Prevents double voting

        // Data specific to proposal type
        bytes proposalData; // abi.encodePacked or similar of relevant data
    }

    struct GovernanceParameters {
        uint256 minReputationToPropose; // Minimum reputation to create a proposal
        uint256 proposalVotingDuration; // Duration for voting in seconds
        uint256 proposalQuorumPercentage; // % of total active weighted votes required (e.g., 4000 for 40%)
        uint256 proposalThresholdPercentage; // % of weighted yay votes required to pass (e.g., 5100 for 51%)
        uint256 membershipVoteThresholdPercentage; // % of weighted yay votes for membership
        uint256 emergencyRole; // Role ID that can trigger emergency shutdown
        uint256 defaultRole; // Role ID assigned upon becoming active member
        uint256 minimumStakeToApply; // Future feature? Requires staking token logic. Not implemented here.
    }

    // --- State Variables ---
    address public treasuryAddress; // Address holding the guild funds (could be this contract or another)
    GovernanceParameters public params;

    uint256 private nextMemberId = 1; // Not strictly needed for mapping, but good for tracking count or potential future indexed access
    mapping(address => uint256) private memberAddressToId;
    mapping(uint256 => Member) public members;
    uint256 public totalActiveWeightedVotingPower; // Sum of votingWeightMultiplier for all active members

    uint256 private nextRoleId = 1;
    mapping(uint256 => Role) private roles;
    mapping(string => uint256) private roleNameToId; // For easier lookup

    uint256 private nextProjectId = 1;
    mapping(uint256 => Project) public projects;
    uint256[] public allProjectIds; // Simple list, filter by status in view function

    uint256 private nextTaskId = 1;
    mapping(uint256 => Task) public tasks;

    uint256 private nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals;
    uint256[] public allProposalIds; // Simple list, filter by status in view function

    bool public paused = false; // Governance controlled pause
    bool public emergencyShutdownActive = false; // Emergency controlled shutdown

    // --- Events ---
    event GuildPaused(address indexed account);
    event GuildUnpaused(address indexed account);
    event EmergencyShutdown(address indexed account);
    event GovernanceParameterUpdated(string parameterName, uint256 oldValue, uint256 newValue);

    event MemberApplicationSubmitted(address indexed applicant);
    event MemberApplicationVoted(uint256 indexed proposalId, address indexed voter, uint256 weightedVote, bool support);
    event MemberStatusChanged(address indexed member, MemberStatus oldStatus, MemberStatus newStatus);
    event RoleAssigned(address indexed member, uint256 indexed roleId);
    event RoleRemoved(address indexed member, uint256 indexed roleId);
    event MemberProfileUpdated(address indexed member, bytes profileHash);

    event TreasuryDeposited(address indexed sender, uint256 amount);
    event TreasurySpendProposed(uint256 indexed proposalId, address indexed proposer, address recipient, uint256 amount);
    event TreasurySpendExecuted(uint256 indexed proposalId);

    event ProjectProposed(uint256 indexed projectId, address indexed proposer, uint256 fundingAmount);
    event ProjectProposalVoted(uint256 indexed proposalId, address indexed voter, uint256 weightedVote, bool support);
    event ProjectStatusUpdated(uint256 indexed projectId, ProjectStatus oldStatus, ProjectStatus newStatus);
    event TaskAssigned(uint256 indexed taskId, uint256 indexed projectId, address indexed assignee);
    event TaskStatusUpdated(uint256 indexed taskId, TaskStatus oldStatus, TaskStatus newStatus);
    event TaskDeliverablesSubmitted(uint256 indexed taskId, bytes deliverablesHash);
    event TaskCompletionApproved(uint256 indexed taskId, address indexed approver);
    event ReputationAwarded(address indexed member, uint256 amount, uint256 indexed taskId);

    event GenericActionProposed(uint256 indexed proposalId, address indexed proposer, address target, bytes callData);
    event GenericActionExecuted(uint256 indexed proposalId);

    event ProposalCreated(uint256 indexed proposalId, ProposalType proposalType, address indexed proposer, uint256 votingDeadline);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, uint256 weightedVote, bool support);
    event ProposalStatusChanged(uint256 indexed proposalId, ProposalStatus oldStatus, ProposalStatus newStatus);

    // --- Modifiers ---
    modifier whenNotPausedOrShutdown() {
        require(!paused, "Guild: Paused");
        require(!emergencyShutdownActive, "Guild: Emergency Shutdown");
        _;
    }

    modifier onlyMember() {
        require(isMember(msg.sender), "Guild: Caller not an active member");
        _;
    }

    modifier hasRole(uint256 _roleId) {
        require(members[memberAddressToId[msg.sender]].roles[_roleId], "Guild: Caller does not have required role");
        _;
    }

    modifier proposalExistsAndOpen(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < nextProposalId, "Guild: Invalid proposal ID");
        require(proposals[_proposalId].status == ProposalStatus.Open, "Guild: Proposal not open");
        require(block.timestamp <= proposals[_proposalId].votingDeadline, "Guild: Voting period ended");
        _;
    }

    modifier onlyAssignedTaskMember(uint256 _taskId) {
        require(_taskId > 0 && _taskId < nextTaskId, "Guild: Invalid task ID");
        require(tasks[_taskId].assignedMember == msg.sender, "Guild: Not assigned to this task");
        _;
    }

    // --- Constructor ---
    constructor(address _treasuryAddress,
                uint256 _minReputationToPropose,
                uint256 _proposalVotingDuration, // in seconds
                uint256 _proposalQuorumPercentage, // e.g., 4000 for 40%
                uint256 _proposalThresholdPercentage, // e.g., 5100 for 51%
                uint256 _membershipVoteThresholdPercentage, // e.g., 6000 for 60%
                string memory _ownerRoleName,
                string memory _emergencyRoleName,
                string memory _defaultMemberRoleName,
                uint256 _ownerVotingWeight,
                uint256 _defaultVotingWeight) Ownable(msg.sender) {

        require(_treasuryAddress != address(0), "Guild: Invalid treasury address");
        require(_proposalVotingDuration > 0, "Guild: Invalid voting duration");
        require(_proposalQuorumPercentage <= 10000, "Guild: Quorum % invalid");
        require(_proposalThresholdPercentage <= 10000, "Guild: Threshold % invalid");
        require(_membershipVoteThresholdPercentage <= 10000, "Guild: Membership Threshold % invalid");

        treasuryAddress = _treasuryAddress;

        // Initialize governance parameters
        params.minReputationToPropose = _minReputationToPropose;
        params.proposalVotingDuration = _proposalVotingDuration;
        params.proposalQuorumPercentage = _proposalQuorumPercentage;
        params.proposalThresholdPercentage = _proposalThresholdPercentage;
        params.membershipVoteThresholdPercentage = _membershipVoteThresholdPercentage;

        // Initialize roles
        _createRole(_ownerRoleName, _ownerVotingWeight); // Role ID 1
        uint256 ownerRoleId = roleNameToId[_ownerRoleName];
        params.emergencyRole = _createRole(_emergencyRoleName, 0); // Role ID 2+
        params.defaultRole = _createRole(_defaultMemberRoleName, _defaultVotingWeight); // Role ID 3+

        // Assign owner role and default role to the initial owner
        memberAddressToId[msg.sender] = nextMemberId;
        members[nextMemberId] = Member({
            memberAddress: msg.sender,
            status: MemberStatus.Active,
            reputation: 0,
            joinedTimestamp: block.timestamp,
            profileHash: ""
        });
        members[nextMemberId].roles[ownerRoleId] = true;
        members[nextMemberId].roles[params.defaultRole] = true;
        totalActiveWeightedVotingPower += _ownerVotingWeight + _defaultVotingWeight; // Assume roles stack weight for simplicity
        nextMemberId++;

        // Set initial permissions for the owner role (role ID 1)
        Role storage ownerRole = roles[ownerRoleId];
        ownerRole.permissions["CAN_ASSIGN_ROLE"] = true;
        ownerRole.permissions["CAN_REMOVE_ROLE"] = true;
        ownerRole.permissions["CAN_APPROVE_TASK_COMPLETION"] = true;
        ownerRole.permissions["CAN_AWARD_REPUTATION_MANUAL"] = true; // Add a manual reputation award function if needed
        // Owner role often has superuser permissions, but governance should set more granularly

         // Initial permissions for the emergency role
        roles[params.emergencyRole].permissions["CAN_TRIGGER_EMERGENCY_SHUTDOWN"] = true;

        // Initial permissions for default member role
        roles[params.defaultRole].permissions["CAN_APPLY_FOR_MEMBERSHIP"] = true; // Should be redundant, anyone can apply
        roles[params.defaultRole].permissions["CAN_PROPOSE_PROJECT"] = true;
        roles[params.defaultRole].permissions["CAN_PROPOSE_TREASURY_SPEND"] = true;
        roles[params.defaultRole].permissions["CAN_PROPOSE_GENERIC_ACTION"] = true;
        roles[params.defaultRole].permissions["CAN_VOTE_PROPOSAL"] = true; // Can vote on all proposal types
        roles[params.defaultRole].permissions["CAN_UPDATE_OWN_PROFILE"] = true;
        roles[params.defaultRole].permissions["CAN_UPDATE_OWN_TASK_STATUS"] = true;
        roles[params.defaultRole].permissions["CAN_SUBMIT_OWN_TASK_DELIVERABLES"] = true;
    }

    // --- Internal Helpers ---

    // @dev Creates a new role. Only callable internally or via governance proposal.
    function _createRole(string memory _name, uint256 _votingWeight) internal returns (uint256) {
        require(roleNameToId[_name] == 0, "Guild: Role name already exists");
        uint256 roleId = nextRoleId++;
        roles[roleId] = Role({
            id: roleId,
            name: _name,
            votingWeightMultiplier: _votingWeight
        });
        roleNameToId[_name] = roleId;
        return roleId;
    }

    // @dev Destroys a role. Only callable internally or via governance proposal.
    function _destroyRole(uint256 _roleId) internal {
        require(_roleId > 0 && _roleId < nextRoleId, "Guild: Invalid role ID");
        require(_roleId != params.emergencyRole, "Guild: Cannot destroy emergency role");
        require(_roleId != params.defaultRole, "Guild: Cannot destroy default role");
        // Note: This doesn't remove roles from members. A migration or separate function is needed.
        // For simplicity here, we just remove the role definition and name mapping.
        delete roleNameToId[roles[_roleId].name];
        delete roles[_roleId];
    }

    // @dev Checks if a member has a specific permission granted by any of their roles.
    function _hasPermission(address _member, string memory _permission) internal view returns (bool) {
        uint256 memberId = memberAddressToId[_member];
        if (memberId == 0 || members[memberId].status != MemberStatus.Active) {
            return false; // Only active members have permissions
        }

        for (uint256 i = 1; i < nextRoleId; i++) {
             if (members[memberId].roles[i] && roles[i].permissions[_permission]) {
                return true;
            }
        }
        return false;
    }

     // @dev Calculates the effective weighted voting power of a member.
    function _getWeightedVotingPower(address _member) internal view returns (uint256) {
        uint256 memberId = memberAddressToId[_member];
        if (memberId == 0 || members[memberId].status != MemberStatus.Active) {
            return 0; // Only active members have voting power
        }

        uint256 totalWeight = 0;
         for (uint256 i = 1; i < nextRoleId; i++) {
             if (members[memberId].roles[i]) {
                 totalWeight += roles[i].votingWeightMultiplier;
             }
         }
         // Basic voting power is sum of role multipliers. Could add reputation factor here:
         // totalWeight += members[memberId].reputation / 100; // Example: 1 rep = 0.01 vote weight
        return totalWeight;
    }

    // @dev Handles voting logic for a proposal.
    function _vote(uint256 _proposalId, bool _support) internal {
        Proposal storage proposal = proposals[_proposalId];
        uint256 memberId = memberAddressToId[msg.sender];
        require(memberId > 0 && members[memberId].status == MemberStatus.Active, "Guild: Only active members can vote");
        require(!proposal.hasVoted[msg.sender], "Guild: Already voted on this proposal");

        uint256 weightedVote = _getWeightedVotingPower(msg.sender);
        require(weightedVote > 0, "Guild: Member has no voting power");

        proposal.hasVoted[msg.sender] = true;
        proposal.totalWeightedVotes += weightedVote;

        if (_support) {
            proposal.totalYayVotes += weightedVote;
        } else {
            proposal.totalNayVotes += weightedVote;
        }

        emit ProposalVoted(_proposalId, msg.sender, weightedVote, _support);

        // Check if voting period ended or quorum reached early (optional optimization)
        if (block.timestamp > proposal.votingDeadline || proposal.totalWeightedVotes >= (totalActiveWeightedVotingPower * params.proposalQuorumPercentage / 10000)) {
             _processProposal(_proposalId);
        }
    }

    // @dev Processes a proposal after voting ends or quorum is met.
    function _processProposal(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.status != ProposalStatus.Open) {
            return; // Already processed
        }

        // Check minimum required votes
        bool quorumReached = proposal.totalWeightedVotes >= (totalActiveWeightedVotingPower * params.proposalQuorumPercentage / 10000);

        // Check threshold for passing
        bool thresholdMet = proposal.totalYayVotes >= (proposal.totalWeightedVotes * (
            proposal.proposalType == ProposalType.Membership ? params.membershipVoteThresholdPercentage : params.proposalThresholdPercentage
        ) / 10000);

        ProposalStatus newStatus;
        if (block.timestamp > proposal.votingDeadline && (!quorumReached || !thresholdMet)) {
             // Voting period ended, check final results
             newStatus = ProposalStatus.Failed;
        } else if (quorumReached && thresholdMet) {
             // Quorum and threshold met (even before deadline possible)
             newStatus = ProposalStatus.Passed;
        } else {
             // Voting period not ended, and quorum/threshold not met yet
             return; // Don't process yet
        }

        ProposalStatus oldStatus = proposal.status;
        proposal.status = newStatus;
        emit ProposalStatusChanged(_proposalId, oldStatus, newStatus);
    }

    // --- Core Guild Management ---

    // 1. Constructor - Handled above

    // 2. Pauses most guild operations (controlled by governance via GenericAction)
    // Requires _hasPermission(msg.sender, "CAN_PAUSE_GUILD") - this permission should be set on a governance role
    function pauseGuild() external whenNotPausedOrShutdown {
        require(_hasPermission(msg.sender, "CAN_PAUSE_GUILD"), "Guild: No permission to pause");
        paused = true;
        emit GuildPaused(msg.sender);
    }

    // 3. Unpauses guild operations (controlled by governance via GenericAction)
    // Requires _hasPermission(msg.sender, "CAN_UNPAUSE_GUILD") - this permission should be set on a governance role
    function unpauseGuild() external { // Can unpause even if paused, but not if emergency shutdown
        require(!emergencyShutdownActive, "Guild: Cannot unpause during emergency shutdown");
        require(paused, "Guild: Not paused");
        require(_hasPermission(msg.sender, "CAN_UNPAUSE_GUILD"), "Guild: No permission to unpause");
        paused = false;
        emit GuildUnpaused(msg.sender);
    }

    // 4. Updates a core governance parameter (controlled by governance via ParameterChange proposal)
    // This function is executed *by the contract itself* after a proposal passes.
    function setGovernanceParameter(bytes32 _parameterName, uint256 _newValue) external whenNotPausedOrShutdown {
        // Check if called by a successfully executed ParameterChange proposal
        // This requires proposal execution logic to call this function specifically
        // For simplicity in this example, we'll allow a specific role to call it directly.
        // A real DAO would encode this call in a proposal and execute it.
        require(_hasPermission(msg.sender, "CAN_SET_GOVERNANCE_PARAMETER"), "Guild: No permission to set parameters");

        string memory name;
        uint256 oldValue;

        if (_parameterName == keccak256("minReputationToPropose")) {
            name = "minReputationToPropose";
            oldValue = params.minReputationToPropose;
            params.minReputationToPropose = _newValue;
        } else if (_parameterName == keccak256("proposalVotingDuration")) {
             name = "proposalVotingDuration";
             oldValue = params.proposalVotingDuration;
             require(_newValue > 0, "Guild: Invalid voting duration");
             params.proposalVotingDuration = _newValue;
        } else if (_parameterName == keccak256("proposalQuorumPercentage")) {
             name = "proposalQuorumPercentage";
             oldValue = params.proposalQuorumPercentage;
             require(_newValue <= 10000, "Guild: Quorum % invalid");
             params.proposalQuorumPercentage = _newValue;
        } else if (_parameterName == keccak256("proposalThresholdPercentage")) {
             name = "proposalThresholdPercentage";
             oldValue = params.proposalThresholdPercentage;
             require(_newValue <= 10000, "Guild: Threshold % invalid");
             params.proposalThresholdPercentage = _newValue;
        } else if (_parameterName == keccak256("membershipVoteThresholdPercentage")) {
             name = "membershipVoteThresholdPercentage";
             oldValue = params.membershipVoteThresholdPercentage;
             require(_newValue <= 10000, "Guild: Membership Threshold % invalid");
             params.membershipVoteThresholdPercentage = _newValue;
        }
        // Emergency role and default role should probably be set via dedicated proposal types or separate functions

        require(bytes(name).length > 0, "Guild: Invalid parameter name");
        emit GovernanceParameterUpdated(name, oldValue, _newValue);
    }

    // 5. Allows a designated emergency role to shut down critical operations immediately.
    function emergencyShutdown() external {
        require(_hasPermission(msg.sender, "CAN_TRIGGER_EMERGENCY_SHUTDOWN"), "Guild: No permission for emergency shutdown");
        emergencyShutdownActive = true;
        paused = true; // Also set paused
        emit EmergencyShutdown(msg.sender);
    }

     // 6. Allows governance to recover accidentally sent ERC20 tokens (controlled via GenericAction)
     // Needs a proposal mechanism to specify the token address and amount.
    function recoverERC20(address _token, uint256 _amount) external whenNotPausedOrShutdown {
        // This function should only be callable via a GenericAction proposal execution
        // For demonstration, adding a temporary owner check. In production, this would be removed.
        require(msg.sender == owner(), "Guild: Recover ERC20 only via governance"); // Replace with governance check

        IERC20 token = IERC20(_token);
        require(token.transfer(treasuryAddress, _amount), "Guild: ERC20 transfer failed");
    }

    // 7. Allows governance to recover accidentally sent ERC721 tokens (controlled via GenericAction)
     // Needs a proposal mechanism to specify the token address and token ID.
    function recoverERC721(address _token, uint256 _tokenId) external whenNotPausedOrShutdown {
        // This function should only be callable via a GenericAction proposal execution
        // For demonstration, adding a temporary owner check. In production, this would be removed.
        require(msg.sender == owner(), "Guild: Recover ERC721 only via governance"); // Replace with governance check

        IERC721 token = IERC721(_token);
        require(token.ownerOf(_tokenId) == address(this), "Guild: Contract does not own this NFT");
        token.safeTransferFrom(address(this), treasuryAddress, _tokenId);
    }

    // --- Membership & Identity ---

    // 8. Allows anyone to submit a membership application.
    function applyForMembership() external whenNotPausedOrShutdown {
        uint256 memberId = memberAddressToId[msg.sender];
        require(memberId == 0 || members[memberId].status == MemberStatus.Inactive, "Guild: Already an active or pending member");
        // Optional: require minimum stake token here

        if (memberId == 0) {
             memberAddressToId[msg.sender] = nextMemberId;
             members[nextMemberId] = Member({
                 memberAddress: msg.sender,
                 status: MemberStatus.Applicant,
                 reputation: 0,
                 joinedTimestamp: block.timestamp, // Timestamp of application
                 profileHash: ""
             });
             memberId = nextMemberId;
             nextMemberId++;
        } else {
             // Re-applying
             members[memberId].status = MemberStatus.Applicant;
             members[memberId].joinedTimestamp = block.timestamp;
        }

        // Create a Membership proposal
        bytes memory proposalData = abi.encodePacked(msg.sender); // Encode applicant address
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.Membership,
            proposer: msg.sender, // Applicant is the proposer
            status: ProposalStatus.Open,
            creationTime: block.timestamp,
            votingDeadline: block.timestamp + params.proposalVotingDuration,
            totalWeightedVotes: 0,
            totalYayVotes: 0,
            totalNayVotes: 0,
            hasVoted: new mapping(address => bool),
            proposalData: proposalData
        });
        allProposalIds.push(proposalId);

        emit MemberApplicationSubmitted(msg.sender);
        emit ProposalCreated(proposalId, ProposalType.Membership, msg.sender, proposals[proposalId].votingDeadline);
    }

    // 9. Members vote on pending membership applications.
    function voteOnMembershipApplication(uint256 _proposalId, bool _support) external onlyMember whenNotPausedOrShutdown proposalExistsAndOpen(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.Membership, "Guild: Not a membership proposal");
        _vote(_proposalId, _support);

        // Check if voting ended/quorum met to process the proposal state
        if (block.timestamp > proposals[_proposalId].votingDeadline || proposals[_proposalId].status == ProposalStatus.Passed) {
             _processMembershipProposal(_proposalId);
        }
    }

    // @dev Internal function to process membership proposal outcome.
    function _processMembershipProposal(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
         if (proposal.status != ProposalStatus.Passed && proposal.status != ProposalStatus.Failed) {
             _processProposal(_proposalId); // Ensure status is set to Passed/Failed
         }

        require(proposal.status != ProposalStatus.Open, "Guild: Voting not concluded yet");
        require(proposal.proposalType == ProposalType.Membership, "Guild: Not a membership proposal");
        require(proposal.proposalData.length >= 20, "Guild: Invalid proposal data"); // Ensure address is encoded

        address applicantAddress = abi.decode(proposal.proposalData, (address));
        uint256 memberId = memberAddressToId[applicantAddress];
        require(memberId > 0, "Guild: Applicant not found");

        MemberStatus oldStatus = members[memberId].status;

        if (proposal.status == ProposalStatus.Passed && oldStatus == MemberStatus.Applicant) {
            members[memberId].status = MemberStatus.Active;
            // Assign default role
            members[memberId].roles[params.defaultRole] = true;
            totalActiveWeightedVotingPower += roles[params.defaultRole].votingWeightMultiplier;
            emit MemberStatusChanged(applicantAddress, oldStatus, MemberStatus.Active);
             // Optionally mint NFT membership token here
        } else if (proposal.status == ProposalStatus.Failed && oldStatus == MemberStatus.Applicant) {
             members[memberId].status = MemberStatus.Inactive; // Or keep as Applicant? Inactive is clearer
             emit MemberStatusChanged(applicantAddress, oldStatus, MemberStatus.Inactive);
        }

        if (proposal.status == ProposalStatus.Passed || proposal.status == ProposalStatus.Failed) {
             // Ensure proposal is marked as Executed or Cancelled after processing
             proposal.status = ProposalStatus.Executed; // Mark as processed
             emit ProposalStatusChanged(_proposalId, proposal.status == ProposalStatus.Passed ? ProposalStatus.Passed : ProposalStatus.Failed, ProposalStatus.Executed);
        }
    }


    // 10. Assigns a specific role to a member.
    // Requires _hasPermission(msg.sender, "CAN_ASSIGN_ROLE")
    function assignRole(address _member, uint256 _roleId) external onlyMember whenNotPausedOrShutdown {
        require(_hasPermission(msg.sender, "CAN_ASSIGN_ROLE"), "Guild: No permission to assign roles");
        uint256 memberId = memberAddressToId[_member];
        require(memberId > 0 && members[memberId].status == MemberStatus.Active, "Guild: Member not found or not active");
        require(_roleId > 0 && _roleId < nextRoleId && roles[_roleId].id != 0, "Guild: Invalid role ID");
        require(!members[memberId].roles[_roleId], "Guild: Member already has this role");

        members[memberId].roles[_roleId] = true;
        totalActiveWeightedVotingPower += roles[_roleId].votingWeightMultiplier;
        emit RoleAssigned(_member, _roleId);
    }

    // 11. Removes a role from a member.
    // Requires _hasPermission(msg.sender, "CAN_REMOVE_ROLE")
     function removeRole(address _member, uint256 _roleId) external onlyMember whenNotPausedOrShutdown {
        require(_hasPermission(msg.sender, "CAN_REMOVE_ROLE"), "Guild: No permission to remove roles");
        uint256 memberId = memberAddressToId[_member];
        require(memberId > 0 && members[memberId].status == MemberStatus.Active, "Guild: Member not found or not active");
        require(_roleId > 0 && _roleId < nextRoleId && roles[_roleId].id != 0, "Guild: Invalid role ID");
        require(_roleId != params.emergencyRole, "Guild: Cannot remove emergency role");
        require(_roleId != params.defaultRole, "Guild: Cannot remove default role");
        require(members[memberId].roles[_roleId], "Guild: Member does not have this role");

        members[memberId].roles[_roleId] = false;
        totalActiveWeightedVotingPower -= roles[_roleId].votingWeightMultiplier;
        emit RoleRemoved(_member, _roleId);
     }

    // 12. Members can update a hash pointing to their off-chain profile data.
    // Requires _hasPermission(msg.sender, "CAN_UPDATE_OWN_PROFILE")
    function updateMemberProfileHash(bytes calldata _profileHash) external onlyMember whenNotPausedOrShutdown {
        require(_hasPermission(msg.sender, "CAN_UPDATE_OWN_PROFILE"), "Guild: No permission to update profile");
        uint256 memberId = memberAddressToId[msg.sender];
        members[memberId].profileHash = _profileHash;
        emit MemberProfileUpdated(msg.sender, _profileHash);
    }

    // 13. Retrieves a member's status, reputation, roles, and profile hash.
    function getMemberProfile(address _member) external view returns (address memberAddress, MemberStatus status, uint256 reputation, uint256 joinedTimestamp, bytes memory profileHash, uint256[] memory roleIds) {
        uint256 memberId = memberAddressToId[_member];
        require(memberId > 0, "Guild: Member not found");
        Member storage member = members[memberId];

        uint256[] memory currentRoleIds = new uint256[](nextRoleId);
        uint256 roleCount = 0;
        for (uint256 i = 1; i < nextRoleId; i++) {
            if (member.roles[i]) {
                currentRoleIds[roleCount] = i;
                roleCount++;
            }
        }

        assembly {
            mstore(currentRoleIds, roleCount) // Set dynamic array length
        }

        return (member.memberAddress, member.status, member.reputation, member.joinedTimestamp, member.profileHash, currentRoleIds);
    }

    // 14. Checks if an address is an active member.
    function isMember(address _addr) public view returns (bool) {
        uint256 memberId = memberAddressToId[_addr];
        return memberId > 0 && members[memberId].status == MemberStatus.Active;
    }

    // 15. Checks if a member has a specific role.
     function hasRole(address _member, uint256 _roleId) external view returns (bool) {
        uint256 memberId = memberAddressToId[_member];
        require(memberId > 0, "Guild: Member not found");
        require(_roleId > 0 && _roleId < nextRoleId && roles[_roleId].id != 0, "Guild: Invalid role ID");
        return members[memberId].roles[_roleId];
     }


    // --- Treasury Management ---

    // 16. Allows anyone to deposit funds into the guild treasury.
    receive() external payable {
        emit TreasuryDeposited(msg.sender, msg.value);
    }
    fallback() external payable {
         emit TreasuryDeposited(msg.sender, msg.value);
    }

    // 17. Proposes spending funds from the treasury.
    // Requires _hasPermission(msg.sender, "CAN_PROPOSE_TREASURY_SPEND") and min reputation
    function proposeTreasurySpend(address _recipient, uint256 _amount, bytes calldata _descriptionHash) external onlyMember whenNotPausedOrShutdown {
        require(_hasPermission(msg.sender, "CAN_PROPOSE_TREASURY_SPEND"), "Guild: No permission to propose treasury spend");
        require(members[memberAddressToId[msg.sender]].reputation >= params.minReputationToPropose, "Guild: Insufficient reputation to propose");
        require(_recipient != address(0), "Guild: Invalid recipient");
        require(_amount > 0, "Guild: Amount must be greater than 0");
        require(address(this).balance >= _amount, "Guild: Insufficient treasury balance"); // Check balance *before* proposing is good practice

        bytes memory proposalData = abi.encodePacked(_recipient, _amount, _descriptionHash);
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.TreasurySpend,
            proposer: msg.sender,
            status: ProposalStatus.Open,
            creationTime: block.timestamp,
            votingDeadline: block.timestamp + params.proposalVotingDuration,
            totalWeightedVotes: 0,
            totalYayVotes: 0,
            totalNayVotes: 0,
            hasVoted: new mapping(address => bool),
            proposalData: proposalData
        });
        allProposalIds.push(proposalId);

        emit TreasurySpendProposed(proposalId, msg.sender, _recipient, _amount);
        emit ProposalCreated(proposalId, ProposalType.TreasurySpend, msg.sender, proposals[proposalId].votingDeadline);
    }

    // 18. Members vote on a treasury spend proposal.
     function voteOnTreasurySpend(uint256 _proposalId, bool _support) external onlyMember whenNotPausedOrShutdown proposalExistsAndOpen(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.TreasurySpend, "Guild: Not a treasury spend proposal");
        _vote(_proposalId, _support);
        // Process happens via general _processProposal or explicit execute call
     }

    // 19. Executes a passed treasury spend proposal.
    // Can be called by any member after the voting period ends and it passed.
     function executeTreasurySpend(uint256 _proposalId) external onlyMember whenNotPausedOrShutdown {
        Proposal storage proposal = proposals[_proposalId];
        require(_proposalId > 0 && _proposalId < nextProposalId, "Guild: Invalid proposal ID");
        require(proposal.proposalType == ProposalType.TreasurySpend, "Guild: Not a treasury spend proposal");
        require(proposal.status != ProposalStatus.Executed, "Guild: Proposal already executed");
        require(proposal.status != ProposalStatus.Cancelled, "Guild: Proposal cancelled");

        // Ensure voting is concluded and check result if not already passed
        if (proposal.status == ProposalStatus.Open) {
             require(block.timestamp > proposal.votingDeadline, "Guild: Voting not concluded yet");
             _processProposal(_proposalId); // Finalize status
        }

        require(proposal.status == ProposalStatus.Passed, "Guild: Proposal did not pass");
        require(proposal.proposalData.length >= 52, "Guild: Invalid proposal data length"); // recipient (20) + amount (32)

        (address recipient, uint256 amount, ) = abi.decode(proposal.proposalData, (address, uint256, bytes)); // Decode recipient and amount
        require(address(this).balance >= amount, "Guild: Insufficient treasury balance for execution");

        proposal.status = ProposalStatus.Executed;
        emit ProposalStatusChanged(_proposalId, ProposalStatus.Passed, ProposalStatus.Executed);

        // Transfer funds
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Guild: Treasury transfer failed");
        emit TreasurySpendExecuted(_proposalId);
     }

    // 20. Gets the current balance of the treasury.
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // --- Project & Task Management ---

    // 21. Members propose a new project, potentially with initial funding.
    // Requires _hasPermission(msg.sender, "CAN_PROPOSE_PROJECT") and min reputation
    function proposeProject(string calldata _name, bytes calldata _descriptionHash, uint256 _fundingAmount, uint256 _deadline) external onlyMember whenNotPausedOrShutdown {
        require(_hasPermission(msg.sender, "CAN_PROPOSE_PROJECT"), "Guild: No permission to propose projects");
        require(members[memberAddressToId[msg.sender]].reputation >= params.minReputationToPropose, "Guild: Insufficient reputation to propose");
        require(bytes(_name).length > 0, "Guild: Project name required");
        require(_deadline > block.timestamp, "Guild: Project deadline must be in the future");
        if (_fundingAmount > 0) {
             require(address(this).balance >= _fundingAmount, "Guild: Insufficient treasury balance for requested funding");
        }

        uint256 projectId = nextProjectId++;
        projects[projectId] = Project({
            id: projectId,
            proposer: msg.sender,
            status: ProjectStatus.Proposed,
            name: _name,
            descriptionHash: _descriptionHash,
            fundingAmount: _fundingAmount,
            creationTime: block.timestamp,
            deadline: _deadline,
            taskIds: new uint256[](0) // Tasks are added later
        });
        allProjectIds.push(projectId);

        // Create a Project proposal for approval/funding
        bytes memory proposalData = abi.encodePacked(projectId, _fundingAmount); // Encode project ID and funding
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.Project,
            proposer: msg.sender,
            status: ProposalStatus.Open,
            creationTime: block.timestamp,
            votingDeadline: block.timestamp + params.proposalVotingDuration,
            totalWeightedVotes: 0,
            totalYayVotes: 0,
            totalNayVotes: 0,
            hasVoted: new mapping(address => bool),
            proposalData: proposalData
        });
         allProposalIds.push(proposalId);

        emit ProjectProposed(projectId, msg.sender, _fundingAmount);
        emit ProposalCreated(proposalId, ProposalType.Project, msg.sender, proposals[proposalId].votingDeadline);
    }

    // 22. Members vote on a project proposal (including funding approval).
    function voteOnProjectProposal(uint256 _proposalId, bool _support) external onlyMember whenNotPausedOrShutdown proposalExistsAndOpen(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.Project, "Guild: Not a project proposal");
        _vote(_proposalId, _support);

        // Check if voting ended/quorum met to process the proposal state
        if (block.timestamp > proposals[_proposalId].votingDeadline || proposals[_proposalId].status == ProposalStatus.Passed) {
             _processProjectProposal(_proposalId);
        }
    }

    // @dev Internal function to process project proposal outcome.
    function _processProjectProposal(uint256 _proposalId) internal {
         Proposal storage proposal = proposals[_proposalId];
         if (proposal.status != ProposalStatus.Passed && proposal.status != ProposalStatus.Failed) {
             _processProposal(_proposalId); // Ensure status is set to Passed/Failed
         }
         require(proposal.status != ProposalStatus.Open, "Guild: Voting not concluded yet");
         require(proposal.proposalType == ProposalType.Project, "Guild: Not a project proposal");
         require(proposal.proposalData.length >= 64, "Guild: Invalid proposal data"); // project ID (32) + funding (32)

         (uint256 projectId, uint256 fundingAmount) = abi.decode(proposal.proposalData, (uint256, uint256));
         require(projectId > 0 && projectId < nextProjectId, "Guild: Invalid project ID in proposal");
         Project storage project = projects[projectId];
         require(project.status == ProjectStatus.Proposed, "Guild: Project status not Proposed");

         ProjectStatus oldStatus = project.status;

         if (proposal.status == ProposalStatus.Passed) {
             project.status = ProjectStatus.Approved;
             // Transfer funding if requested
             if (fundingAmount > 0) {
                require(address(this).balance >= fundingAmount, "Guild: Insufficient treasury balance for project funding");
                 (bool success, ) = payable(treasuryAddress).call{value: fundingAmount}(""); // Send to treasury or project specific account
                 require(success, "Guild: Project funding transfer failed");
             }
         } else if (proposal.status == ProposalStatus.Failed) {
             project.status = ProjectStatus.Cancelled;
         }

         emit ProjectStatusUpdated(projectId, oldStatus, project.status);

         if (proposal.status == ProposalStatus.Passed || proposal.status == ProposalStatus.Failed) {
             // Ensure proposal is marked as Executed or Cancelled after processing
             proposal.status = ProposalStatus.Executed; // Mark as processed
             emit ProposalStatusChanged(_proposalId, proposal.status == ProposalStatus.Passed ? ProposalStatus.Passed : ProposalStatus.Failed, ProposalStatus.Executed);
        }
    }


    // 23. Assigns a guild member to a specific task within a project.
    // Requires _hasPermission(msg.sender, "CAN_ASSIGN_TASK")
    // Tasks are created implicitly or explicitly via project proposal details (simplified here)
    function assignMemberToTask(uint256 _projectId, uint256 _taskId, address _assignee) external onlyMember whenNotPausedOrShutdown {
        require(_hasPermission(msg.sender, "CAN_ASSIGN_TASK"), "Guild: No permission to assign tasks");
        require(_projectId > 0 && _projectId < nextProjectId, "Guild: Invalid project ID");
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Approved || project.status == ProjectStatus.InProgress, "Guild: Project not approved or in progress");
        require(_taskId > 0 && _taskId < nextTaskId, "Guild: Invalid task ID");
        Task storage task = tasks[_taskId];
        require(task.projectId == _projectId, "Guild: Task does not belong to this project");
        require(task.status == TaskStatus.Open || task.status == TaskStatus.Assigned || task.status == TaskStatus.InProgress, "Guild: Task not in assignable state");
        require(isMember(_assignee), "Guild: Assignee must be an active member");

        TaskStatus oldStatus = task.status;
        task.assignedMember = _assignee;
        if (task.status == TaskStatus.Open) {
             task.status = TaskStatus.Assigned;
        }
        emit TaskAssigned(_taskId, _projectId, _assignee);
        if (oldStatus != task.status) {
             emit TaskStatusUpdated(_taskId, oldStatus, task.status);
        }
    }

    // 24. Allows assigned member or authorized role to update task progress.
    // Requires _hasPermission(msg.sender, "CAN_UPDATE_ANY_TASK_STATUS") or onlyAssignedTaskMember
    function updateTaskStatus(uint256 _taskId, TaskStatus _newStatus) external onlyMember whenNotPausedOrShutdown {
        require(_taskId > 0 && _taskId < nextTaskId, "Guild: Invalid task ID");
        Task storage task = tasks[_taskId];
        require(task.status != TaskStatus.Completed && task.status != TaskStatus.Cancelled, "Guild: Task already completed or cancelled");

        bool isAuthorized = (msg.sender == task.assignedMember && _hasPermission(msg.sender, "CAN_UPDATE_OWN_TASK_STATUS")) ||
                            _hasPermission(msg.sender, "CAN_UPDATE_ANY_TASK_STATUS");
        require(isAuthorized, "Guild: No permission to update task status");

        require(_newStatus != TaskStatus.Open, "Guild: Cannot set status back to Open"); // Tasks become assigned from Open
        require(_newStatus != TaskStatus.Completed, "Guild: Use approveTaskCompletion to complete");
        require(_newStatus != TaskStatus.Cancelled, "Guild: Use a separate cancellation function if needed"); // Cancellation might need governance

        TaskStatus oldStatus = task.status;
        task.status = _newStatus;
        emit TaskStatusUpdated(_taskId, oldStatus, _newStatus);
    }

    // 25. Allows assigned member to submit proof of task completion (e.g., IPFS hash).
    // Requires onlyAssignedTaskMember
    function submitTaskDeliverablesHash(uint256 _taskId, bytes calldata _deliverablesHash) external onlyAssignedTaskMember whenNotPausedOrShutdown {
         require(_taskId > 0 && _taskId < nextTaskId, "Guild: Invalid task ID");
         Task storage task = tasks[_taskId];
         require(task.status == TaskStatus.InProgress || task.status == TaskStatus.NeedsReview, "Guild: Task not in progress or review state");
         require(bytes(_deliverablesHash).length > 0, "Guild: Deliverables hash required");

         TaskStatus oldStatus = task.status;
         task.deliverablesHash = _deliverablesHash;
         task.status = TaskStatus.NeedsReview; // Automatically moves to review
         emit TaskDeliverablesSubmitted(_taskId, _deliverablesHash);
         emit TaskStatusUpdated(_taskId, oldStatus, task.status);
    }

    // 26. Allows authorized role to approve task completion.
    // Requires _hasPermission(msg.sender, "CAN_APPROVE_TASK_COMPLETION")
     function approveTaskCompletion(uint256 _taskId) external onlyMember whenNotPausedOrShutdown {
         require(_hasPermission(msg.sender, "CAN_APPROVE_TASK_COMPLETION"), "Guild: No permission to approve tasks");
         require(_taskId > 0 && _taskId < nextTaskId, "Guild: Invalid task ID");
         Task storage task = tasks[_taskId];
         require(task.status == TaskStatus.NeedsReview, "Guild: Task not in NeedsReview status");
         require(bytes(task.deliverablesHash).length > 0, "Guild: Deliverables hash not submitted");

         TaskStatus oldStatus = task.status;
         task.status = TaskStatus.Completed;
         emit TaskCompletionApproved(_taskId, msg.sender);
         emit TaskStatusUpdated(_taskId, oldStatus, task.status);

         // Automatically award reputation upon approval
         awardReputationForTask(_taskId);
     }

    // 27. Awards reputation upon task completion approval (called internally).
    function awardReputationForTask(uint256 _taskId) internal {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Completed, "Guild: Task not completed");
        require(task.assignedMember != address(0), "Guild: Task has no assigned member");

        uint256 memberId = memberAddressToId[task.assignedMember];
        require(memberId > 0, "Guild: Assigned member not found"); // Should not happen if isMember check worked

        // Only award reputation once per task
        uint256 reputationToAward = task.reputationAward;
        task.reputationAward = 0; // Zero out to prevent double awards

        if (reputationToAward > 0) {
             members[memberId].reputation += reputationToAward;
             emit ReputationAwarded(task.assignedMember, reputationToAward, _taskId);
        }
    }

    // Add function to create tasks (likely part of project proposal data or a separate function for authorized roles)
    // For simplicity, let's add a function to create tasks for an *Approved* project.
    // Requires _hasPermission(msg.sender, "CAN_CREATE_TASK")
    function createTask(uint256 _projectId, string calldata _description, uint256 _reputationAward, uint256 _deadline) external onlyMember whenNotPausedOrShutdown {
        require(_hasPermission(msg.sender, "CAN_CREATE_TASK"), "Guild: No permission to create tasks");
        require(_projectId > 0 && _projectId < nextProjectId, "Guild: Invalid project ID");
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Approved || project.status == ProjectStatus.InProgress, "Guild: Project not approved or in progress");
        require(bytes(_description).length > 0, "Guild: Task description required");
        require(_deadline > block.timestamp, "Guild: Task deadline must be in the future");

        uint256 taskId = nextTaskId++;
        tasks[taskId] = Task({
            id: taskId,
            projectId: _projectId,
            assignedMember: address(0), // Not assigned yet
            status: TaskStatus.Open,
            description: _description,
            deliverablesHash: "",
            reputationAward: _reputationAward,
            deadline: _deadline
        });

        project.taskIds.push(taskId); // Add task ID to project's list
    }

     // 28. Retrieves details of a specific project.
    function getProjectDetails(uint256 _projectId) external view returns (Project memory) {
        require(_projectId > 0 && _projectId < nextProjectId, "Guild: Invalid project ID");
        return projects[_projectId];
    }

    // 29. Retrieves details of a specific task within a project.
    function getTaskDetails(uint256 _taskId) external view returns (Task memory) {
         require(_taskId > 0 && _taskId < nextTaskId, "Guild: Invalid task ID");
         return tasks[_taskId];
    }

    // 30. Lists project IDs filtered by status.
    function listProjectsByStatus(ProjectStatus _status) external view returns (uint256[] memory) {
        uint256[] memory filteredProjectIds = new uint256[](allProjectIds.length);
        uint256 count = 0;
        for (uint256 i = 0; i < allProjectIds.length; i++) {
            uint256 projectId = allProjectIds[i];
            if (projects[projectId].status == _status) {
                filteredProjectIds[count] = projectId;
                count++;
            }
        }
         assembly {
             mstore(filteredProjectIds, count) // Set dynamic array length
         }
        return filteredProjectIds;
    }


    // --- Governance & Proposals (Generic Actions) ---

    // 31. Proposes an arbitrary call to another contract (highly sensitive, governance controlled).
    // Requires _hasPermission(msg.sender, "CAN_PROPOSE_GENERIC_ACTION") and min reputation
    function proposeGenericAction(address _target, uint256 _value, bytes calldata _callData) external onlyMember whenNotPausedOrShutdown {
        require(_hasPermission(msg.sender, "CAN_PROPOSE_GENERIC_ACTION"), "Guild: No permission to propose generic action");
        require(members[memberAddressToId[msg.sender]].reputation >= params.minReputationToPropose, "Guild: Insufficient reputation to propose");
        require(_target != address(0), "Guild: Invalid target address");
        if (_value > 0) {
             require(address(this).balance >= _value, "Guild: Insufficient treasury balance for value transfer");
        }
        // _callData can be empty for value transfers

        bytes memory proposalData = abi.encodePacked(_target, _value, _callData);
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.GenericAction,
            proposer: msg.sender,
            status: ProposalStatus.Open,
            creationTime: block.timestamp,
            votingDeadline: block.timestamp + params.proposalVotingDuration,
            totalWeightedVotes: 0,
            totalYayVotes: 0,
            totalNayVotes: 0,
            hasVoted: new mapping(address => bool),
            proposalData: proposalData
        });
         allProposalIds.push(proposalId);

        emit GenericActionProposed(proposalId, msg.sender, _target, _callData);
        emit ProposalCreated(proposalId, ProposalType.GenericAction, msg.sender, proposals[proposalId].votingDeadline);
    }

    // 32. Members vote on a generic action proposal.
    function voteOnGenericAction(uint256 _proposalId, bool _support) external onlyMember whenNotPausedOrShutdown proposalExistsAndOpen(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.GenericAction, "Guild: Not a generic action proposal");
        _vote(_proposalId, _support);
         // Process happens via general _processProposal or explicit execute call
    }

    // 33. Executes a passed generic action proposal.
    // Can be called by any member after the voting period ends and it passed.
     function executeGenericAction(uint256 _proposalId) external onlyMember whenNotPausedOrShutdown {
        Proposal storage proposal = proposals[_proposalId];
        require(_proposalId > 0 && _proposalId < nextProposalId, "Guild: Invalid proposal ID");
        require(proposal.proposalType == ProposalType.GenericAction, "Guild: Not a generic action proposal");
        require(proposal.status != ProposalStatus.Executed, "Guild: Proposal already executed");
        require(proposal.status != ProposalStatus.Cancelled, "Guild: Proposal cancelled");

        // Ensure voting is concluded and check result if not already passed
        if (proposal.status == ProposalStatus.Open) {
             require(block.timestamp > proposal.votingDeadline, "Guild: Voting not concluded yet");
             _processProposal(_proposalId); // Finalize status
        }

        require(proposal.status == ProposalStatus.Passed, "Guild: Proposal did not pass");
        require(proposal.proposalData.length >= 52, "Guild: Invalid proposal data length"); // target (20) + value (32)

        (address target, uint256 value, bytes memory callData) = abi.decode(proposal.proposalData, (address, uint256, bytes));

        // --- WARNING: ARBITRARY CALL ---
        // This is the most powerful and dangerous part. It allows the DAO to interact
        // with any other contract. Security relies entirely on the governance process
        // to approve only safe and intended calls. Consider adding safeguards here,
        // e.g., a list of allowed function selectors or target addresses for high-risk calls.
        // For this example, we proceed with the raw call as proposed.
        // Ensure `target` is a contract if callData is not empty.
        if (callData.length > 0) {
             require(target.code.length > 0, "Guild: Target is not a contract");
        }


        proposal.status = ProposalStatus.Executed;
        emit ProposalStatusChanged(_proposalId, ProposalStatus.Passed, ProposalStatus.Executed);

        (bool success, ) = target.call{value: value}(callData);
        require(success, "Guild: Generic action execution failed"); // Revert if the called function reverts
        emit GenericActionExecuted(_proposalId);
     }

     // 34. Retrieves details of any proposal.
    function getProposalDetails(uint256 _proposalId) external view returns (Proposal memory) {
        require(_proposalId > 0 && _proposalId < nextProposalId, "Guild: Invalid proposal ID");
        Proposal storage p = proposals[_proposalId];
        return Proposal(
            p.id,
            p.proposalType,
            p.proposer,
            p.status,
            p.creationTime,
            p.votingDeadline,
            p.totalWeightedVotes,
            p.totalYayVotes,
            p.totalNayVotes,
            new mapping(address => bool), // Cannot return private mapping directly
            p.proposalData
        );
    }

    // 35. Gets current vote tally for a proposal.
     function getProposalVoteCount(uint256 _proposalId) external view returns (uint256 totalWeightedVotes, uint256 totalYayVotes, uint256 totalNayVotes) {
        require(_proposalId > 0 && _proposalId < nextProposalId, "Guild: Invalid proposal ID");
        Proposal storage p = proposals[_proposalId];
        return (p.totalWeightedVotes, p.totalYayVotes, p.totalNayVotes);
     }


    // --- Reputation System ---

    // 36. Retrieves the reputation score for a member.
     function getMemberReputation(address _member) external view returns (uint256) {
         uint256 memberId = memberAddressToId[_member];
         require(memberId > 0, "Guild: Member not found");
         return members[memberId].reputation;
     }

     // Add a function for manual reputation award (e.g., for exceptional contributions not tied to tasks)
     // Requires _hasPermission(msg.sender, "CAN_AWARD_REPUTATION_MANUAL")
     function awardReputationManually(address _member, uint256 _amount) external onlyMember whenNotPausedOrShutdown {
         require(_hasPermission(msg.sender, "CAN_AWARD_REPUTATION_MANUAL"), "Guild: No permission to award reputation manually");
         uint256 memberId = memberAddressToId[_member];
         require(memberId > 0 && members[memberId].status == MemberStatus.Active, "Guild: Member not found or not active");
         require(_amount > 0, "Guild: Amount must be greater than 0");

         members[memberId].reputation += _amount;
         // Note: Task ID is 0 for manual awards
         emit ReputationAwarded(_member, _amount, 0);
     }

    // Function to create roles via Governance (ParameterChange or dedicated type)
    // Function to assign/remove permissions to roles via Governance (ParameterChange or dedicated type)
    // These would involve proposing role ID/name, permission name, and boolean value in proposalData.
    // Example signature for a governance call to set permission:
    // function setRolePermission(uint256 _roleId, string memory _permissionName, bool _allowed) external ...

}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Role-Based Permissions:** Instead of just an "admin" or "member" flag, permissions are tied to specific roles (`mapping(string => bool) permissions`). Members can hold multiple roles, and permissions are additive. Functions check `_hasPermission(msg.sender, "PERMISSION_NAME")`. Role creation/management would ideally be governed by the DAO itself (e.g., via `GenericAction` or a dedicated proposal type calling internal functions).
2.  **Task-Based Reputation:** Reputation isn't just an arbitrary score; it's primarily earned by completing specific `Task`s within `Project`s. This ties on-chain activity directly to perceived value contribution. Tasks have statuses, deadlines, and assigned members.
3.  **Structured Project Workflow:** The contract includes basic states and functions for proposing, approving, assigning, updating, submitting deliverables for, and completing project tasks. This provides a framework for organizing work within the guild.
4.  **Parameterized Governance:** Core rules like voting duration, quorum, and threshold percentages are stored in a struct (`GovernanceParameters`) and can be updated via a governance process (`setGovernanceParameter`), making the DAO adaptable without contract upgrades (for these parameters).
5.  **Flexible Generic Governance (`proposeGenericAction`, `executeGenericAction`):** This allows the DAO to propose and execute *arbitrary calls* to other smart contracts or even calls to itself (like `pauseGuild`, `unpauseGuild`, `recoverERC20`/`ERC721`, `setGovernanceParameter`, `assignRole`, etc., if those functions were restricted to only being called by `executeGenericAction`). This is powerful but requires careful governance and high thresholds to prevent malicious calls.
6.  **Weighted Voting:** Voting power can be modified based on roles (`votingWeightMultiplier`). This allows for differentiated governance, e.g., core contributors (with specific roles) having more say.
7.  **Clear State Transitions:** Enums and specific functions (`_processProposal`, `_processMembershipProposal`, `_processProjectProposal`) manage the lifecycle of members, proposals, projects, and tasks.
8.  **Off-chain Data Integration:** `profileHash` and `descriptionHash`/`deliverablesHash` fields allow linking on-chain entities (members, projects, tasks) to richer off-chain data (profiles, project specs, reports) stored on IPFS or similar systems, keeping the chain lean while enabling detailed information access.
9.  **ERC20/ERC721 Recovery:** Includes functions to recover tokens accidentally sent to the contract address, but gated behind governance to prevent unauthorized access.
10. **Pause & Emergency Shutdown:** Separate mechanisms for temporarily pausing operations (governance controlled) and an immediate, potentially role-based, shutdown for emergencies.

This contract provides a framework for a community to self-govern, manage projects, reward contributions, and adapt its own rules in a decentralized manner, moving beyond simple token-weighted voting DAOs.