```solidity
/**
 * @title Decentralized Autonomous Organization (DAO) with Dynamic Governance & Reputation System
 * @author Bard (AI Assistant)
 * @dev This contract implements a DAO with advanced features including:
 *      - Dynamic Governance Parameters (Voting Threshold, Quorum, Voting Duration)
 *      - Reputation-Based Voting Power
 *      - Role-Based Access Control with Customizable Permissions
 *      - Proposal Types: General, Parameter Change, Role Management, Treasury Action
 *      - Proposal Lifecycle Management (Queuing, Execution, Cancellation)
 *      - Emergency Pause Mechanism
 *      - On-Chain Treasury Management
 *      - Delegation of Voting Power
 *      - Dispute Resolution Mechanism (Simplified)
 *      - Versioning for future upgrades
 *
 * Function Summary:
 * 1. initializeDAO(string _daoName, address[] _initialMembers) - Initializes the DAO with a name and initial members.
 * 2. joinDAO() - Allows anyone to request membership to the DAO.
 * 3. approveMembership(address _member) - Allows DAO members with 'APPROVE_MEMBERSHIP' role to approve pending membership requests.
 * 4. leaveDAO() - Allows members to voluntarily leave the DAO.
 * 5. createProposal(string _title, string _description, ProposalType _proposalType, bytes _data) - Allows members to create proposals of various types.
 * 6. voteOnProposal(uint256 _proposalId, VoteOption _vote) - Allows members to vote on active proposals, weighted by reputation.
 * 7. executeProposal(uint256 _proposalId) - Allows anyone to execute a passed proposal after the voting period.
 * 8. cancelProposal(uint256 _proposalId) - Allows proposal creators to cancel their proposals before the voting period ends.
 * 9. updateVotingThreshold(uint256 _newThreshold) - Allows DAO members with 'MANAGE_GOVERNANCE' role to update the voting threshold.
 * 10. updateQuorum(uint256 _newQuorum) - Allows DAO members with 'MANAGE_GOVERNANCE' role to update the quorum requirement.
 * 11. updateVotingDuration(uint256 _newDuration) - Allows DAO members with 'MANAGE_GOVERNANCE' role to update the voting duration.
 * 12. depositToTreasury() payable - Allows anyone to deposit ETH into the DAO's treasury.
 * 13. withdrawFromTreasury(address _recipient, uint256 _amount) - Allows DAO members with 'MANAGE_TREASURY' role to withdraw ETH from the treasury to a recipient.
 * 14. delegateVote(address _delegatee) - Allows members to delegate their voting power to another member.
 * 15. revokeDelegation() - Allows members to revoke their vote delegation.
 * 16. raiseDispute(uint256 _proposalId, string _disputeReason) - Allows members to raise a dispute on a passed proposal before execution.
 * 17. resolveDispute(uint256 _proposalId, DisputeResolution _resolution) - Allows DAO members with 'RESOLVE_DISPUTES' role to resolve disputes on proposals.
 * 18. pauseDAO() - Allows DAO members with 'EMERGENCY_ACTIONS' role to pause the DAO in case of emergency.
 * 19. unpauseDAO() - Allows DAO members with 'EMERGENCY_ACTIONS' role to unpause the DAO.
 * 20. getDAOVersion() - Returns the version of the DAO contract.
 * 21. getProposalDetails(uint256 _proposalId) - Returns detailed information about a specific proposal.
 * 22. getMemberReputation(address _member) - Returns the reputation score of a DAO member.
 * 23. getRolePermissions(Role _role) - Returns the permissions associated with a specific role.
 * 24. isMember(address _account) - Checks if an address is a member of the DAO.
 * 25. hasRole(address _account, Role _role) - Checks if a member has a specific role.
 * 26. getTreasuryBalance() - Returns the current balance of the DAO treasury.
 */

pragma solidity ^0.8.0;

contract DynamicGovernanceDAO {
    string public daoName;
    address public daoOwner; // Optional, for initial setup/admin, could be removed for full decentralization
    uint256 public daoVersion = 1;

    // Dynamic Governance Parameters
    uint256 public votingThreshold = 50; // Percentage of votes required to pass a proposal (e.g., 50%)
    uint256 public quorum = 30; // Percentage of total members required to participate in a vote (e.g., 30%)
    uint256 public votingDuration = 7 days; // Default voting duration

    // Reputation System
    mapping(address => uint256) public memberReputation;

    // Roles and Permissions (Simplified, can be expanded)
    enum Role {
        MEMBER,                // Basic DAO member
        APPROVE_MEMBERSHIP,    // Can approve membership requests
        MANAGE_GOVERNANCE,     // Can change governance parameters
        MANAGE_TREASURY,       // Can manage treasury withdrawals
        RESOLVE_DISPUTES,      // Can resolve proposal disputes
        EMERGENCY_ACTIONS      // Can pause/unpause the DAO
    }

    mapping(Role => string[]) public rolePermissions; // Map roles to permission descriptions (for UI/info)
    mapping(address => Role[]) public memberRoles;

    // Membership Management
    mapping(address => bool) public isDAOActiveMember;
    address[] public activeMembers;
    mapping(address => bool) public pendingMembershipRequests;

    // Proposals
    enum ProposalState {
        PENDING,    // Proposal created, waiting for voting to start
        ACTIVE,     // Voting in progress
        PASSED,     // Proposal passed voting
        REJECTED,   // Proposal rejected
        EXECUTED,   // Proposal successfully executed
        CANCELLED,  // Proposal cancelled by creator
        DISPUTED,   // Proposal is under dispute
        RESOLVED    // Dispute has been resolved
    }

    enum ProposalType {
        GENERAL,             // General decision making
        PARAMETER_CHANGE,    // Change governance parameters
        ROLE_MANAGEMENT,     // Assign/revoke roles
        TREASURY_ACTION      // Treasury related actions (e.g., funding a project)
    }

    enum VoteOption {
        YEA,
        NAY,
        ABSTAIN
    }

    enum DisputeResolution {
        REJECT_EXECUTION,
        ALLOW_EXECUTION
    }

    struct Proposal {
        uint256 id;
        address proposer;
        ProposalType proposalType;
        ProposalState state;
        string title;
        string description;
        uint256 creationTimestamp;
        uint256 votingEndTime;
        bytes data; // Data related to the proposal (e.g., new parameter value, role to assign, etc.)
        mapping(address => VoteOption) votes;
        uint256 yeaVotes;
        uint256 nayVotes;
        uint256 abstainVotes;
        uint256 disputeResolutionDeadline;
        DisputeResolution disputeResolution;
        string disputeReason;
    }

    Proposal[] public proposals;
    uint256 public proposalCounter;

    // Treasury
    uint256 public treasuryBalance; // In Wei

    // Delegation
    mapping(address => address) public voteDelegations; // Delegator -> Delegatee

    // Emergency Pause
    bool public paused;

    // Events
    event DAOOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event DAOMemberJoined(address indexed member);
    event DAOMemberLeft(address indexed member);
    event MembershipRequestSubmitted(address indexed member);
    event MembershipRequestApproved(address indexed member);
    event ProposalCreated(uint256 indexed proposalId, address proposer, ProposalType proposalType, string title);
    event VoteCast(uint256 indexed proposalId, address voter, VoteOption vote);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId);
    event GovernanceParameterUpdated(string parameter, uint256 newValue);
    event TreasuryDeposit(address indexed sender, uint256 amount);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount, address indexed manager);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event VoteDelegationRevoked(address indexed delegator);
    event DisputeRaised(uint256 indexed proposalId, address disputer, string reason);
    event DisputeResolved(uint256 indexed proposalId, DisputeResolution resolution, address resolver);
    event DAOPaused(address pauser);
    event DAOUnpaused(address unpauser);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == daoOwner, "Only DAO owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isDAOActiveMember[msg.sender], "Only active DAO members can call this function.");
        _;
    }

    modifier onlyRole(Role _role) {
        bool hasRequiredRole = false;
        for (uint256 i = 0; i < memberRoles[msg.sender].length; i++) {
            if (memberRoles[msg.sender][i] == _role) {
                hasRequiredRole = true;
                break;
            }
        }
        require(hasRequiredRole, "Caller does not have the required role.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId < proposals.length, "Proposal does not exist.");
        _;
    }

    modifier proposalInState(uint256 _proposalId, ProposalState _state) {
        require(proposals[_proposalId].state == _state, "Proposal is not in the required state.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].state == ProposalState.ACTIVE, "Proposal is not active.");
        _;
    }

    modifier notPaused() {
        require(!paused, "DAO is currently paused.");
        _;
    }


    constructor() {
        daoOwner = msg.sender; // Optional owner for initial setup
        // Initialize default role permissions (Example - Customize as needed)
        rolePermissions[Role.APPROVE_MEMBERSHIP] = ["Approve new membership requests"];
        rolePermissions[Role.MANAGE_GOVERNANCE] = ["Update voting threshold", "Update quorum", "Update voting duration"];
        rolePermissions[Role.MANAGE_TREASURY] = ["Withdraw funds from treasury"];
        rolePermissions[Role.RESOLVE_DISPUTES] = ["Resolve disputes on proposals"];
        rolePermissions[Role.EMERGENCY_ACTIONS] = ["Pause DAO", "Unpause DAO"];
    }

    /// @notice Initializes the DAO with a name and initial members. Can only be called once by the owner.
    /// @param _daoName The name of the DAO.
    /// @param _initialMembers An array of initial member addresses.
    function initializeDAO(string memory _daoName, address[] memory _initialMembers) external onlyOwner {
        require(bytes(daoName).length == 0, "DAO already initialized."); // Prevent re-initialization
        daoName = _daoName;
        for (uint256 i = 0; i < _initialMembers.length; i++) {
            _addMember(_initialMembers[i]);
        }
        emit DAOOwnershipTransferred(daoOwner, address(this)); // Example event, owner could be contract itself after setup
        daoOwner = address(this); // Transfer ownership to the contract itself for full decentralization (optional)
    }

    /// @notice Allows anyone to request membership to the DAO.
    function joinDAO() external notPaused {
        require(!isDAOActiveMember[msg.sender], "Already a member.");
        require(!pendingMembershipRequests[msg.sender], "Membership request already pending.");
        pendingMembershipRequests[msg.sender] = true;
        emit MembershipRequestSubmitted(msg.sender);
    }

    /// @notice Allows DAO members with 'APPROVE_MEMBERSHIP' role to approve pending membership requests.
    /// @param _member The address of the member to approve.
    function approveMembership(address _member) external onlyRole(Role.APPROVE_MEMBERSHIP) notPaused {
        require(pendingMembershipRequests[_member], "No pending membership request.");
        require(!isDAOActiveMember[_member], "Address is already a member.");
        _addMember(_member);
        pendingMembershipRequests[_member] = false;
        emit MembershipRequestApproved(_member);
    }

    function _addMember(address _member) internal {
        isDAOActiveMember[_member] = true;
        activeMembers.push(_member);
        memberReputation[_member] = 100; // Initial reputation score
        _assignRole(_member, Role.MEMBER); // Assign basic MEMBER role
        emit DAOMemberJoined(_member);
    }


    /// @notice Allows members to voluntarily leave the DAO.
    function leaveDAO() external onlyMember notPaused {
        require(isDAOActiveMember[msg.sender], "Not a member.");
        _removeMember(msg.sender);
        emit DAOMemberLeft(msg.sender);
    }

    function _removeMember(address _member) internal {
        isDAOActiveMember[_member] = false;
        // Remove from activeMembers array (inefficient for large arrays, consider alternative data structure if needed)
        for (uint256 i = 0; i < activeMembers.length; i++) {
            if (activeMembers[i] == _member) {
                delete activeMembers[i];
                break; // Assuming members are unique, can break after finding first match
            }
        }
        delete memberRoles[_member]; // Remove roles
        delete memberReputation[_member]; // Remove reputation
        delete voteDelegations[_member]; // Remove delegation if any
    }


    /// @notice Allows members to create proposals of various types.
    /// @param _title The title of the proposal.
    /// @param _description A detailed description of the proposal.
    /// @param _proposalType The type of proposal (General, Parameter Change, etc.).
    /// @param _data Additional data related to the proposal (e.g., encoded parameters for parameter changes).
    function createProposal(
        string memory _title,
        string memory _description,
        ProposalType _proposalType,
        bytes memory _data
    ) external onlyMember notPaused {
        require(bytes(_title).length > 0 && bytes(_description).length > 0, "Title and description cannot be empty.");

        proposals.push(Proposal({
            id: proposalCounter,
            proposer: msg.sender,
            proposalType: _proposalType,
            state: ProposalState.PENDING,
            title: _title,
            description: _description,
            creationTimestamp: block.timestamp,
            votingEndTime: block.timestamp + votingDuration,
            data: _data,
            votes: mapping(address => VoteOption)(),
            yeaVotes: 0,
            nayVotes: 0,
            abstainVotes: 0,
            disputeResolutionDeadline: 0,
            disputeResolution: DisputeResolution.ALLOW_EXECUTION, // Default resolution is allow execution
            disputeReason: ""
        }));
        emit ProposalCreated(proposalCounter, msg.sender, _proposalType, _title);
        proposalCounter++;
    }

    /// @notice Allows members to vote on active proposals, weighted by reputation.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote The vote option (YEA, NAY, ABSTAIN).
    function voteOnProposal(uint256 _proposalId, VoteOption _vote)
        external
        onlyMember
        notPaused
        proposalExists(_proposalId)
        proposalInState(_proposalId, ProposalState.PENDING)
    {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp <= proposal.votingEndTime, "Voting period has ended.");
        require(proposal.votes[msg.sender] == VoteOption.ABSTAIN, "Already voted."); // Default enum value is 0, assuming abstain is 0 or handle appropriately

        proposal.votes[msg.sender] = _vote;
        if (_vote == VoteOption.YEA) {
            proposal.yeaVotes += getVotingPower(msg.sender); // Voting power based on reputation
        } else if (_vote == VoteOption.NAY) {
            proposal.nayVotes += getVotingPower(msg.sender);
        } else if (_vote == VoteOption.ABSTAIN) {
            proposal.abstainVotes += getVotingPower(msg.sender);
        }

        emit VoteCast(_proposalId, msg.sender, _vote);

        // Check if voting is completed based on time (or could be based on quorum/votes if needed)
        if (block.timestamp >= proposal.votingEndTime) {
            _finalizeProposal(_proposalId);
        } else {
            proposal.state = ProposalState.ACTIVE; // Transition to active state once first vote is cast
        }
    }

    /// @dev Calculates voting power based on reputation (example: linear scaling, can be more complex)
    function getVotingPower(address _member) internal view returns (uint256) {
        return 1 + (memberReputation[_member] / 100); // Base power of 1 + reputation factor
    }

    /// @dev Finalizes a proposal after the voting period.
    /// @param _proposalId The ID of the proposal to finalize.
    function _finalizeProposal(uint256 _proposalId) internal proposalExists(_proposalId) proposalInState(_proposalId, ProposalState.ACTIVE) {
        Proposal storage proposal = proposals[_proposalId];
        uint256 totalVotesCast = proposal.yeaVotes + proposal.nayVotes + proposal.abstainVotes;
        uint256 totalActiveMembers = activeMembers.length;
        uint256 quorumReached = (totalActiveMembers > 0) ? (totalVotesCast * 100) / totalActiveMembers : 0; // Prevent division by zero

        if (quorumReached >= quorum && proposal.yeaVotes * 100 >= (proposal.yeaVotes + proposal.nayVotes) * votingThreshold) {
            proposal.state = ProposalState.PASSED;
        } else {
            proposal.state = ProposalState.REJECTED;
        }
    }


    /// @notice Allows anyone to execute a passed proposal after the voting period.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external notPaused proposalExists(_proposalId) proposalInState(_proposalId, ProposalState.PASSED) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.disputeResolution == DisputeResolution.ALLOW_EXECUTION, "Proposal execution is disputed.");
        proposal.state = ProposalState.EXECUTED;
        // Implement proposal execution logic based on proposal.proposalType and proposal.data
        if (proposal.proposalType == ProposalType.PARAMETER_CHANGE) {
            _executeParameterChange(proposal.data);
        } else if (proposal.proposalType == ProposalType.ROLE_MANAGEMENT) {
            _executeRoleManagement(proposal.data);
        } else if (proposal.proposalType == ProposalType.TREASURY_ACTION) {
            _executeTreasuryAction(proposal.data);
        } else if (proposal.proposalType == ProposalType.GENERAL) {
            // General proposal execution logic (can be expanded based on data structure)
        }
        emit ProposalExecuted(_proposalId);
    }

    function _executeParameterChange(bytes memory _data) internal {
        // Decode data based on expected parameter change format (example: uint256 newVotingThreshold)
        (uint256 newVotingThreshold, uint256 newQuorum, uint256 newVotingDuration) = abi.decode(_data, (uint256, uint256, uint256));
        if (newVotingThreshold > 0) updateVotingThreshold(newVotingThreshold);
        if (newQuorum > 0) updateQuorum(newQuorum);
        if (newVotingDuration > 0) updateVotingDuration(newVotingDuration);
    }

    function _executeRoleManagement(bytes memory _data) internal {
        // Decode data based on expected role management format (example: address targetMember, Role role, bool assign)
        (address targetMember, Role role, bool assign) = abi.decode(_data, (address, Role, bool));
        if (assign) {
            _assignRole(targetMember, role);
        } else {
            _revokeRole(targetMember, role);
        }
    }

    function _executeTreasuryAction(bytes memory _data) internal {
        // Decode data based on expected treasury action format (example: address recipient, uint256 amount)
        (address recipient, uint256 amount) = abi.decode(_data, (address, uint256));
        withdrawFromTreasury(recipient, amount); // Assuming withdrawFromTreasury handles authorization
    }


    /// @notice Allows proposal creators to cancel their proposals before the voting period ends.
    /// @param _proposalId The ID of the proposal to cancel.
    function cancelProposal(uint256 _proposalId)
        external
        onlyMember
        notPaused
        proposalExists(_proposalId)
        proposalInState(_proposalId, ProposalState.PENDING) // Can only cancel pending proposals
    {
        require(proposals[_proposalId].proposer == msg.sender, "Only proposer can cancel.");
        proposals[_proposalId].state = ProposalState.CANCELLED;
        emit ProposalCancelled(_proposalId);
    }

    /// @notice Allows DAO members with 'MANAGE_GOVERNANCE' role to update the voting threshold.
    /// @param _newThreshold The new voting threshold percentage (e.g., 50 for 50%).
    function updateVotingThreshold(uint256 _newThreshold) external onlyRole(Role.MANAGE_GOVERNANCE) notPaused {
        require(_newThreshold <= 100 && _newThreshold > 0, "Voting threshold must be between 1 and 100.");
        votingThreshold = _newThreshold;
        emit GovernanceParameterUpdated("votingThreshold", _newThreshold);
    }

    /// @notice Allows DAO members with 'MANAGE_GOVERNANCE' role to update the quorum requirement.
    /// @param _newQuorum The new quorum percentage (e.g., 30 for 30%).
    function updateQuorum(uint256 _newQuorum) external onlyRole(Role.MANAGE_GOVERNANCE) notPaused {
        require(_newQuorum <= 100 && _newQuorum >= 0, "Quorum must be between 0 and 100.");
        quorum = _newQuorum;
        emit GovernanceParameterUpdated("quorum", _newQuorum);
    }

    /// @notice Allows DAO members with 'MANAGE_GOVERNANCE' role to update the voting duration.
    /// @param _newDuration The new voting duration in seconds.
    function updateVotingDuration(uint256 _newDuration) external onlyRole(Role.MANAGE_GOVERNANCE) notPaused {
        require(_newDuration > 0, "Voting duration must be greater than 0.");
        votingDuration = _newDuration;
        emit GovernanceParameterUpdated("votingDuration", _newDuration);
    }

    /// @notice Allows anyone to deposit ETH into the DAO's treasury.
    depositToTreasury() external payable notPaused {
        treasuryBalance += msg.value;
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /// @notice Allows DAO members with 'MANAGE_TREASURY' role to withdraw ETH from the treasury to a recipient.
    /// @param _recipient The address to receive the withdrawn ETH.
    /// @param _amount The amount of ETH to withdraw in Wei.
    function withdrawFromTreasury(address _recipient, uint256 _amount) public onlyRole(Role.MANAGE_TREASURY) notPaused {
        require(_recipient != address(0), "Invalid recipient address.");
        require(_amount > 0, "Withdrawal amount must be greater than 0.");
        require(treasuryBalance >= _amount, "Insufficient treasury balance.");

        treasuryBalance -= _amount;
        payable(_recipient).transfer(_amount);
        emit TreasuryWithdrawal(_recipient, _amount, msg.sender);
    }

    /// @notice Allows members to delegate their voting power to another member.
    /// @param _delegatee The address of the member to delegate voting power to.
    function delegateVote(address _delegatee) external onlyMember notPaused {
        require(isDAOActiveMember[_delegatee], "Delegatee must be a DAO member.");
        require(_delegatee != msg.sender, "Cannot delegate to self.");
        voteDelegations[msg.sender] = _delegatee;
        emit VoteDelegated(msg.sender, _delegatee);
    }

    /// @notice Allows members to revoke their vote delegation.
    function revokeDelegation() external onlyMember notPaused {
        require(voteDelegations[msg.sender] != address(0), "No delegation to revoke.");
        delete voteDelegations[msg.sender];
        emit VoteDelegationRevoked(msg.sender);
    }

    /// @notice Allows members to raise a dispute on a passed proposal before execution.
    /// @param _proposalId The ID of the passed proposal.
    /// @param _disputeReason Reason for raising the dispute.
    function raiseDispute(uint256 _proposalId, string memory _disputeReason)
        external
        onlyMember
        notPaused
        proposalExists(_proposalId)
        proposalInState(_proposalId, ProposalState.PASSED)
    {
        require(proposals[_proposalId].disputeResolutionDeadline == 0, "Dispute already raised."); // Only one dispute per proposal
        proposals[_proposalId].state = ProposalState.DISPUTED;
        proposals[_proposalId].disputeResolutionDeadline = block.timestamp + 3 days; // Example dispute resolution deadline
        proposals[_proposalId].disputeReason = _disputeReason;
        emit DisputeRaised(_proposalId, msg.sender, _disputeReason);
    }

    /// @notice Allows DAO members with 'RESOLVE_DISPUTES' role to resolve disputes on proposals.
    /// @param _proposalId The ID of the disputed proposal.
    /// @param _resolution The resolution of the dispute (REJECT_EXECUTION or ALLOW_EXECUTION).
    function resolveDispute(uint256 _proposalId, DisputeResolution _resolution)
        external
        onlyRole(Role.RESOLVE_DISPUTES)
        notPaused
        proposalExists(_proposalId)
        proposalInState(_proposalId, ProposalState.DISPUTED)
    {
        require(block.timestamp <= proposals[_proposalId].disputeResolutionDeadline, "Dispute resolution deadline passed.");
        proposals[_proposalId].disputeResolution = _resolution;
        proposals[_proposalId].state = ProposalState.RESOLVED;
        emit DisputeResolved(_proposalId, _resolution, msg.sender);
    }

    /// @notice Allows DAO members with 'EMERGENCY_ACTIONS' role to pause the DAO in case of emergency.
    function pauseDAO() external onlyRole(Role.EMERGENCY_ACTIONS) notPaused {
        require(!paused, "DAO is already paused.");
        paused = true;
        emit DAOPaused(msg.sender);
    }

    /// @notice Allows DAO members with 'EMERGENCY_ACTIONS' role to unpause the DAO.
    function unpauseDAO() external onlyRole(Role.EMERGENCY_ACTIONS) {
        require(paused, "DAO is not paused.");
        paused = false;
        emit DAOUnpaused(msg.sender);
    }

    /// @notice Returns the version of the DAO contract.
    function getDAOVersion() external view returns (uint256) {
        return daoVersion;
    }

    /// @notice Returns detailed information about a specific proposal.
    /// @param _proposalId The ID of the proposal.
    function getProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice Returns the reputation score of a DAO member.
    /// @param _member The address of the DAO member.
    function getMemberReputation(address _member) external view returns (uint256) {
        return memberReputation[_member];
    }

    /// @notice Returns the permissions associated with a specific role.
    /// @param _role The Role enum value.
    function getRolePermissions(Role _role) external view returns (string[] memory) {
        return rolePermissions[_role];
    }

    /// @notice Checks if an address is a member of the DAO.
    /// @param _account The address to check.
    function isMember(address _account) external view returns (bool) {
        return isDAOActiveMember[_account];
    }

    /// @notice Checks if a member has a specific role.
    /// @param _account The address of the member.
    /// @param _role The Role enum value to check for.
    function hasRole(address _account, Role _role) external view returns (bool) {
        for (uint256 i = 0; i < memberRoles[_account].length; i++) {
            if (memberRoles[_account][i] == _role) {
                return true;
            }
        }
        return false;
    }

    /// @notice Returns the current balance of the DAO treasury.
    function getTreasuryBalance() external view returns (uint256) {
        return treasuryBalance;
    }

    // Internal Role Management functions (could be exposed through proposals for decentralized role changes)
    function _assignRole(address _member, Role _role) internal {
        bool roleExists = false;
        for (uint256 i = 0; i < memberRoles[_member].length; i++) {
            if (memberRoles[_member][i] == _role) {
                roleExists = true;
                break;
            }
        }
        if (!roleExists) {
            memberRoles[_member].push(_role);
        }
    }

    function _revokeRole(address _member, Role _role) internal {
        for (uint256 i = 0; i < memberRoles[_member].length; i++) {
            if (memberRoles[_member][i] == _role) {
                delete memberRoles[_member][i]; // Effectively removes the role, order might not be preserved, but roles are checked by iteration anyway
                break; // Assuming each role is assigned only once, can break after finding first match
            }
        }
    }

    // Fallback function to receive ETH deposits
    receive() external payable {
        depositToTreasury();
    }
}
```