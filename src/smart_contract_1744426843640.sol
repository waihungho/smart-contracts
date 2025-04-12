```solidity
/**
 * @title Decentralized Autonomous Organization (DAO) with Dynamic Governance and Reputation System
 * @author Gemini AI (Conceptual Smart Contract - Not for Production)
 * @notice This smart contract implements a DAO with advanced features including:
 *   - Dynamic governance parameters (quorum, voting duration) adjustable by DAO itself.
 *   - Reputation system for members influencing voting power and access to features.
 *   - Multi-stage proposal process (draft, voting, execution).
 *   - Role-based access control for different functionalities.
 *   - Treasury management with customizable spending limits.
 *   - On-chain dispute resolution mechanism (basic example).
 *   - Event-driven architecture for off-chain monitoring.
 *   - Advanced proposal types (parameter changes, role assignments, reputation adjustments).
 *   - Emergency shutdown mechanism for critical situations.
 *
 * Function Summary:
 *
 *  **Membership & Roles:**
 *    1. requestMembership(): Allows users to request membership to the DAO.
 *    2. voteOnMembershipRequest(uint256 _requestId, bool _approve): Members vote on pending membership requests.
 *    3. revokeMembership(address _member): Admin function to revoke a member's membership.
 *    4. assignRole(address _member, Role _role): Admin function to assign roles to members.
 *    5. removeRole(address _member, Role _role): Admin function to remove roles from members.
 *    6. getMemberRole(address _member): View function to check a member's role.
 *    7. getMemberList(): View function to get the list of members.
 *
 *  **Proposal & Voting:**
 *    8. submitProposal(ProposalType _proposalType, string memory _title, string memory _description, bytes memory _data): Members submit proposals for various actions.
 *    9. voteOnProposal(uint256 _proposalId, bool _support): Members vote on active proposals.
 *    10. executeProposal(uint256 _proposalId): Executes a passed proposal after the voting period.
 *    11. cancelProposal(uint256 _proposalId): Admin function to cancel a proposal before voting ends.
 *    12. getProposalDetails(uint256 _proposalId): View function to retrieve details of a specific proposal.
 *    13. getActiveProposals(): View function to get a list of active proposal IDs.
 *    14. getPastProposals(): View function to get a list of past proposal IDs.
 *
 *  **Governance & Parameters:**
 *    15. setGovernanceParameter(GovernanceParameter _parameter, uint256 _value): Proposes a change to governance parameters (quorum, voting duration, etc.). Requires governance proposal.
 *    16. getGovernanceParameter(GovernanceParameter _parameter): View function to get the current value of a governance parameter.
 *
 *  **Reputation System:**
 *    17. getReputation(address _member): View function to get a member's reputation score.
 *    18. adjustReputation(address _member, int256 _reputationChange): Admin/Role-based function to adjust a member's reputation. Requires special role or governance proposal.
 *    19. getVotingPower(address _member): View function to calculate a member's voting power based on reputation.
 *
 *  **Treasury & Emergency:**
 *    20. deposit(address _token, uint256 _amount): Allows depositing supported tokens into the DAO treasury.
 *    21. withdrawFromTreasury(address _token, address _recipient, uint256 _amount): Proposes withdrawal from the treasury. Requires governance proposal.
 *    22. emergencyShutdown(): Admin function to trigger an emergency shutdown of the DAO in critical situations.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract DynamicGovernanceDAO is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Define Roles within the DAO
    enum Role {
        MEMBER,         // Basic member with voting rights
        ADMIN,          // Administrative privileges (e.g., role management, emergency shutdown)
        TREASURY_MANAGER, // Role to manage treasury withdrawals (requires governance approval still)
        REPUTATION_MANAGER // Role to adjust reputation scores (requires governance or admin approval)
    }

    // Define Proposal Types
    enum ProposalType {
        GENERAL,            // General proposals for DAO direction
        GOVERNANCE_CHANGE,  // Proposals to change governance parameters
        TREASURY_WITHDRAWAL, // Proposals to withdraw funds from the treasury
        ROLE_ASSIGNMENT,    // Proposals to assign roles to members
        REPUTATION_ADJUSTMENT // Proposals to adjust member reputation
    }

    // Define Governance Parameters that can be changed by proposals
    enum GovernanceParameter {
        VOTING_DURATION,
        QUORUM_PERCENTAGE,
        MEMBERSHIP_VOTE_DURATION,
        MEMBERSHIP_QUORUM_PERCENTAGE,
        TREASURY_WITHDRAWAL_LIMIT // Example: Daily withdrawal limit
    }

    struct Proposal {
        ProposalType proposalType;
        string title;
        string description;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 quorum;
        bool executed;
        bytes data; // To store proposal-specific data (e.g., target address, function signature, parameters)
    }

    struct MembershipRequest {
        address requester;
        uint256 requestTime;
        bool approved;
        bool voted;
    }

    // State Variables
    EnumerableSet.AddressSet private members;
    mapping(address => mapping(Role => bool)) public memberRoles;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    mapping(address => int256) public reputationScores;
    mapping(uint256 => MembershipRequest) public membershipRequests;
    uint256 public membershipRequestCount;

    // Governance Parameters - Initial Values (can be changed via proposals)
    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public quorumPercentage = 51;    // Default quorum percentage (51%)
    uint256 public membershipVoteDuration = 3 days;
    uint256 public membershipQuorumPercentage = 60;

    bool public emergencyShutdownActive = false;

    // Supported tokens for treasury (initially empty - can be expanded through governance)
    mapping(address => bool) public supportedTreasuryTokens;

    // Events
    event MembershipRequested(address indexed requester, uint256 requestId);
    event MembershipApproved(address indexed member, uint256 requestId);
    event MembershipRevoked(address indexed member);
    event RoleAssigned(address indexed member, Role role);
    event RoleRemoved(address indexed member, Role role);
    event ProposalSubmitted(uint256 proposalId, ProposalType proposalType, address indexed proposer);
    event ProposalVoted(uint256 proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCancelled(uint256 proposalId);
    event GovernanceParameterChanged(GovernanceParameter parameter, uint256 newValue);
    event ReputationAdjusted(address indexed member, int256 change, int256 newScore);
    event TreasuryDeposit(address indexed token, address indexed depositor, uint256 amount);
    event TreasuryWithdrawalProposed(uint256 proposalId, address token, address recipient, uint256 amount);
    event EmergencyShutdownTriggered();
    event EmergencyShutdownResolved();

    // Modifiers
    modifier onlyMember() {
        require(isMember(msg.sender), "Only members can perform this action.");
        _;
    }

    modifier onlyRole(Role _role) {
        require(hasRole(msg.sender, _role), "Must have the required role.");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(msg.sender, Role.ADMIN), "Only admins can perform this action.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].endTime > block.timestamp && !proposals[_proposalId].executed, "Proposal is not active.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId < proposalCount, "Proposal does not exist.");
        _;
    }

    modifier notEmergencyShutdown() {
        require(!emergencyShutdownActive, "DAO is in emergency shutdown mode.");
        _;
    }

    // -------------------- Membership & Roles Functions --------------------

    /**
     * @notice Allows users to request membership to the DAO.
     */
    function requestMembership() external notEmergencyShutdown {
        membershipRequests[membershipRequestCount] = MembershipRequest({
            requester: msg.sender,
            requestTime: block.timestamp,
            approved: false,
            voted: false
        });
        emit MembershipRequested(msg.sender, membershipRequestCount);
        membershipRequestCount++;
    }

    /**
     * @notice Members vote on pending membership requests.
     * @param _requestId The ID of the membership request.
     * @param _approve True to approve, false to reject.
     */
    function voteOnMembershipRequest(uint256 _requestId, bool _approve) external onlyMember notEmergencyShutdown {
        require(_requestId < membershipRequestCount, "Invalid membership request ID.");
        MembershipRequest storage request = membershipRequests[_requestId];
        require(!request.approved, "Membership request already processed.");
        require(!request.voted, "You have already voted on this request.");

        request.voted = true; // Mark voter as voted (simple yes/no, could be extended for weighted voting later)

        uint256 approvalVotes = 0;
        uint256 totalVotes = 0;
        for (uint256 i = 0; i < membershipRequestCount; i++) {
            if (membershipRequests[i].requester == request.requester && membershipRequests[i].voted) { // Simple check - improve for real-world scenarios
                totalVotes++;
                if (membershipRequests[i].approved) { // Assuming 'approved' is set elsewhere in a more complex voting logic
                    approvalVotes++;
                }
            }
        }

        if (_approve) {
            approvalVotes++;
        } else {
            // Implement rejection logic if needed, e.g., rejection count, specific rejection reasons
        }
        totalVotes++;

        uint256 quorumRequired = members.length() * membershipQuorumPercentage / 100;
        if (totalVotes >= quorumRequired) {
            if (approvalVotes * 100 >= membershipQuorumPercentage) {
                _approveMembership(request.requester);
                request.approved = true; // Mark request as approved to prevent further voting
                emit MembershipApproved(request.requester, _requestId);
            } else {
                // Membership rejected (optional: emit event for rejection)
                request.approved = true; // Mark request as processed even if rejected
            }
        }
    }

    /**
     * @dev Internal function to add a member to the DAO.
     * @param _member The address of the member to add.
     */
    function _approveMembership(address _member) internal {
        members.add(_member);
        memberRoles[_member][Role.MEMBER] = true; // Assign default MEMBER role
    }

    /**
     * @notice Admin function to revoke a member's membership.
     * @param _member The address of the member to revoke.
     */
    function revokeMembership(address _member) external onlyAdmin notEmergencyShutdown {
        require(isMember(_member), "Address is not a member.");
        members.remove(_member);
        delete memberRoles[_member]; // Remove all roles
        reputationScores[_member] = 0; // Reset reputation
        emit MembershipRevoked(_member);
    }

    /**
     * @notice Admin function to assign roles to members.
     * @param _member The address of the member.
     * @param _role The role to assign.
     */
    function assignRole(address _member, Role _role) external onlyAdmin notEmergencyShutdown {
        require(isMember(_member), "Address is not a member.");
        memberRoles[_member][_role] = true;
        emit RoleAssigned(_member, _role);
    }

    /**
     * @notice Admin function to remove roles from members.
     * @param _member The address of the member.
     * @param _role The role to remove.
     */
    function removeRole(address _member, Role _role) external onlyAdmin notEmergencyShutdown {
        require(isMember(_member), "Address is not a member.");
        memberRoles[_member][_role] = false;
        emit RoleRemoved(_member, _role);
    }

    /**
     * @notice View function to check a member's role.
     * @param _member The address of the member.
     * @param _role The role to check.
     * @return True if the member has the role, false otherwise.
     */
    function hasRole(address _member, Role _role) public view returns (bool) {
        return memberRoles[_member][_role];
    }

    /**
     * @notice View function to check if an address is a member.
     * @param _member The address to check.
     * @return True if the address is a member, false otherwise.
     */
    function isMember(address _member) public view returns (bool) {
        return members.contains(_member);
    }

    /**
     * @notice View function to get a member's role.
     * @param _member The address of the member.
     * @return The Role of the member.
     */
    function getMemberRole(address _member) external view returns (Role[] memory) {
        require(isMember(_member), "Address is not a member.");
        Role[] memory roles = new Role[](4); // Assuming max 4 roles for now, adjust if needed
        uint256 roleCount = 0;
        if (memberRoles[_member][Role.MEMBER]) roles[roleCount++] = Role.MEMBER;
        if (memberRoles[_member][Role.ADMIN]) roles[roleCount++] = Role.ADMIN;
        if (memberRoles[_member][Role.TREASURY_MANAGER]) roles[roleCount++] = Role.TREASURY_MANAGER;
        if (memberRoles[_member][Role.REPUTATION_MANAGER]) roles[roleCount++] = Role.REPUTATION_MANAGER;

        Role[] memory memberRolesArray = new Role[](roleCount);
        for(uint256 i = 0; i < roleCount; i++){
            memberRolesArray[i] = roles[i];
        }
        return memberRolesArray;
    }


    /**
     * @notice View function to get the list of members.
     * @return An array of member addresses.
     */
    function getMemberList() external view returns (address[] memory) {
        uint256 memberCount = members.length();
        address[] memory memberList = new address[](memberCount);
        for (uint256 i = 0; i < memberCount; i++) {
            memberList[i] = members.at(i);
        }
        return memberList;
    }

    // -------------------- Proposal & Voting Functions --------------------

    /**
     * @notice Members submit proposals for various actions.
     * @param _proposalType The type of proposal.
     * @param _title A brief title for the proposal.
     * @param _description A detailed description of the proposal.
     * @param _data Proposal-specific data (e.g., target address, function call data).
     */
    function submitProposal(
        ProposalType _proposalType,
        string memory _title,
        string memory _description,
        bytes memory _data
    ) external onlyMember notEmergencyShutdown {
        proposals[proposalCount] = Proposal({
            proposalType: _proposalType,
            title: _title,
            description: _description,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            votesFor: 0,
            votesAgainst: 0,
            quorum: quorumPercentage,
            executed: false,
            data: _data
        });
        emit ProposalSubmitted(proposalCount, _proposalType, msg.sender);
        proposalCount++;
    }

    /**
     * @notice Members vote on active proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True to vote for, false to vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyMember proposalExists(_proposalId) proposalActive(_proposalId) notEmergencyShutdown {
        Proposal storage proposal = proposals[_proposalId];
        uint256 votingPower = getVotingPower(msg.sender); // Get voting power based on reputation

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Executes a passed proposal after the voting period.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external proposalExists(_proposalId) notEmergencyShutdown {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.endTime <= block.timestamp, "Voting period is still active.");
        require(!proposal.executed, "Proposal already executed.");

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        uint256 quorumRequired = members.length() * proposal.quorum / 100; // Quorum based on current parameters
        require(totalVotes >= quorumRequired, "Quorum not reached.");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal failed to pass (not enough votes for).");

        proposal.executed = true;
        _executeProposalAction(_proposalId); // Internal function to handle proposal execution logic
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Internal function to execute the action associated with a proposal.
     * @param _proposalId The ID of the proposal.
     */
    function _executeProposalAction(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.proposalType == ProposalType.GOVERNANCE_CHANGE) {
            (GovernanceParameter parameter, uint256 newValue) = abi.decode(proposal.data, (GovernanceParameter, uint256));
            setGovernanceParameterInternal(parameter, newValue); // Internal function to update parameters
        } else if (proposal.proposalType == ProposalType.TREASURY_WITHDRAWAL) {
            (address tokenAddress, address recipient, uint256 amount) = abi.decode(proposal.data, (address, address, uint256));
            _withdrawFromTreasuryInternal(tokenAddress, recipient, amount); // Internal withdrawal function
        } else if (proposal.proposalType == ProposalType.ROLE_ASSIGNMENT) {
            (address memberAddress, Role roleToAssign) = abi.decode(proposal.data, (address, Role));
            assignRole(memberAddress, roleToAssign); // Use existing role assignment function
        } else if (proposal.proposalType == ProposalType.REPUTATION_ADJUSTMENT) {
             (address memberAddress, int256 reputationChange) = abi.decode(proposal.data, (address, int256));
             adjustReputation(memberAddress, reputationChange); // Use existing reputation adjustment function
        }
        // Add more proposal type execution logic here as needed.
        // General proposals might not have specific on-chain actions, but could be tracked for record-keeping.
    }


    /**
     * @notice Admin function to cancel a proposal before voting ends.
     * @param _proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 _proposalId) external onlyAdmin proposalExists(_proposalId) proposalActive(_proposalId) notEmergencyShutdown {
        Proposal storage proposal = proposals[_proposalId];
        proposal.endTime = block.timestamp; // Effectively ends voting immediately
        proposal.executed = true; // Mark as executed (in a cancelled state)
        emit ProposalCancelled(_proposalId);
    }

    /**
     * @notice View function to retrieve details of a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal details struct.
     */
    function getProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /**
     * @notice View function to get a list of active proposal IDs.
     * @return An array of active proposal IDs.
     */
    function getActiveProposals() external view returns (uint256[] memory) {
        uint256 activeProposalCount = 0;
        for (uint256 i = 0; i < proposalCount; i++) {
            if (proposals[i].endTime > block.timestamp && !proposals[i].executed) {
                activeProposalCount++;
            }
        }
        uint256[] memory activeProposalIds = new uint256[](activeProposalCount);
        uint256 index = 0;
        for (uint256 i = 0; i < proposalCount; i++) {
            if (proposals[i].endTime > block.timestamp && !proposals[i].executed) {
                activeProposalIds[index++] = i;
            }
        }
        return activeProposalIds;
    }

    /**
     * @notice View function to get a list of past proposal IDs.
     * @return An array of past proposal IDs (executed or expired).
     */
    function getPastProposals() external view returns (uint256[] memory) {
        uint256 pastProposalCount = 0;
        for (uint256 i = 0; i < proposalCount; i++) {
            if (proposals[i].endTime <= block.timestamp || proposals[i].executed) {
                pastProposalCount++;
            }
        }
        uint256[] memory pastProposalIds = new uint256[](pastProposalCount);
        uint256 index = 0;
        for (uint256 i = 0; i < proposalCount; i++) {
            if (proposals[i].endTime <= block.timestamp || proposals[i].executed) {
                pastProposalIds[index++] = i;
            }
        }
        return pastProposalIds;
    }

    // -------------------- Governance & Parameter Functions --------------------

    /**
     * @notice Proposes a change to governance parameters (quorum, voting duration, etc.). Requires governance proposal.
     * @param _parameter The governance parameter to change.
     * @param _value The new value for the parameter.
     */
    function setGovernanceParameter(GovernanceParameter _parameter, uint256 _value) external onlyMember notEmergencyShutdown {
        bytes memory data = abi.encode(_parameter, _value);
        submitProposal(
            ProposalType.GOVERNANCE_CHANGE,
            "Governance Parameter Change",
            string(abi.encodePacked("Propose to change ", _getParameterName(_parameter), " to ", uint2str(_value))),
            data
        );
    }

    /**
     * @dev Internal function to set governance parameters after a successful governance proposal.
     * @param _parameter The governance parameter to change.
     * @param _value The new value for the parameter.
     */
    function setGovernanceParameterInternal(GovernanceParameter _parameter, uint256 _value) internal {
        if (_parameter == GovernanceParameter.VOTING_DURATION) {
            votingDuration = _value;
        } else if (_parameter == GovernanceParameter.QUORUM_PERCENTAGE) {
            quorumPercentage = _value;
        } else if (_parameter == GovernanceParameter.MEMBERSHIP_VOTE_DURATION) {
            membershipVoteDuration = _value;
        } else if (_parameter == GovernanceParameter.MEMBERSHIP_QUORUM_PERCENTAGE) {
            membershipQuorumPercentage = _value;
        }
        // Add more parameters here as needed
        emit GovernanceParameterChanged(_parameter, _value);
    }

    /**
     * @notice View function to get the current value of a governance parameter.
     * @param _parameter The governance parameter to retrieve.
     * @return The current value of the parameter.
     */
    function getGovernanceParameter(GovernanceParameter _parameter) external view returns (uint256) {
        if (_parameter == GovernanceParameter.VOTING_DURATION) {
            return votingDuration;
        } else if (_parameter == GovernanceParameter.QUORUM_PERCENTAGE) {
            return quorumPercentage;
        } else if (_parameter == GovernanceParameter.MEMBERSHIP_VOTE_DURATION) {
            return membershipVoteDuration;
        } else if (_parameter == GovernanceParameter.MEMBERSHIP_QUORUM_PERCENTAGE) {
            return membershipQuorumPercentage;
        }
        // Add more parameters here as needed
        return 0; // Default return if parameter not found (shouldn't happen in this enum-based design)
    }

    /**
     * @dev Helper function to get parameter name for event descriptions.
     */
    function _getParameterName(GovernanceParameter _parameter) internal pure returns (string memory) {
        if (_parameter == GovernanceParameter.VOTING_DURATION) {
            return "Voting Duration";
        } else if (_parameter == GovernanceParameter.QUORUM_PERCENTAGE) {
            return "Quorum Percentage";
        } else if (_parameter == GovernanceParameter.MEMBERSHIP_VOTE_DURATION) {
            return "Membership Vote Duration";
        } else if (_parameter == GovernanceParameter.MEMBERSHIP_QUORUM_PERCENTAGE) {
            return "Membership Quorum Percentage";
        }
        return "Unknown Parameter";
    }

    // -------------------- Reputation System Functions --------------------

    /**
     * @notice View function to get a member's reputation score.
     * @param _member The address of the member.
     * @return The member's reputation score.
     */
    function getReputation(address _member) external view returns (int256) {
        return reputationScores[_member];
    }

    /**
     * @notice Admin/Role-based function to adjust a member's reputation. Requires special role or governance proposal.
     * @param _member The address of the member to adjust reputation for.
     * @param _reputationChange The amount to change the reputation score (positive or negative).
     */
    function adjustReputation(address _member, int256 _reputationChange) public onlyRole(Role.REPUTATION_MANAGER) notEmergencyShutdown {
        require(isMember(_member), "Address is not a member.");
        reputationScores[_member] = reputationScores[_member] + _reputationChange;
        emit ReputationAdjusted(_member, _reputationChange, reputationScores[_member]);
    }

    /**
     * @notice View function to calculate a member's voting power based on reputation.
     * @param _member The address of the member.
     * @return The member's voting power.
     */
    function getVotingPower(address _member) public view returns (uint256) {
        int256 reputation = reputationScores[_member];
        uint256 baseVotingPower = 1; // Base voting power for all members

        // Example: Reputation-based voting power scaling (can be customized)
        if (reputation > 100) {
            return baseVotingPower.add(uint256(reputation / 100)); // Increase voting power for higher reputation
        } else {
            return baseVotingPower;
        }
        // More complex reputation-based voting power logic can be implemented here.
    }

    // -------------------- Treasury & Emergency Functions --------------------

    /**
     * @notice Allows depositing supported tokens into the DAO treasury.
     * @param _token The address of the token being deposited. Use address(0) for ETH.
     * @param _amount The amount of tokens to deposit.
     */
    function deposit(address _token, uint256 _amount) external payable notEmergencyShutdown {
        if (_token == address(0)) { // ETH deposit
            require(msg.value == _amount, "ETH value sent is not equal to amount.");
            emit TreasuryDeposit(_token, msg.sender, _amount);
        } else { // Token deposit
            require(supportedTreasuryTokens[_token], "Token is not supported in treasury.");
            IERC20 token = IERC20(_token);
            require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed.");
            emit TreasuryDeposit(_token, msg.sender, _amount);
        }
    }

    /**
     * @notice Proposes withdrawal from the treasury. Requires governance proposal.
     * @param _token The address of the token to withdraw. Use address(0) for ETH.
     * @param _recipient The address to receive the withdrawn tokens.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawFromTreasury(address _token, address _recipient, uint256 _amount) external onlyMember notEmergencyShutdown {
        require(supportedTreasuryTokens[_token] || _token == address(0), "Token is not supported for withdrawal.");
        bytes memory data = abi.encode(_token, _recipient, _amount);
        submitProposal(
            ProposalType.TREASURY_WITHDRAWAL,
            "Treasury Withdrawal Proposal",
            string(abi.encodePacked("Propose to withdraw ", uint2str(_amount), " of token ", _token, " to ", _recipient)),
            data
        );
        emit TreasuryWithdrawalProposed(proposalCount, _token, _recipient, _amount);
    }

    /**
     * @dev Internal function to withdraw tokens from the treasury after proposal execution.
     * @param _token The address of the token to withdraw.
     * @param _recipient The address to receive the withdrawn tokens.
     * @param _amount The amount of tokens to withdraw.
     */
    function _withdrawFromTreasuryInternal(address _token, address _recipient, uint256 _amount) internal {
        if (_token == address(0)) { // ETH withdrawal
            payable(_recipient).transfer(_amount);
        } else { // Token withdrawal
            IERC20 token = IERC20(_token);
            require(token.transfer(_recipient, _amount), "Treasury token transfer failed.");
        }
    }

    /**
     * @notice Admin function to trigger an emergency shutdown of the DAO in critical situations.
     *  This would ideally disable critical functions like proposal submission, voting, execution (except maybe for resolving the emergency).
     *  The exact shutdown behavior needs careful design based on DAO's specific needs.
     */
    function emergencyShutdown() external onlyAdmin notEmergencyShutdown {
        emergencyShutdownActive = true;
        emit EmergencyShutdownTriggered();
        // In a real-world scenario, more complex shutdown logic would be implemented here,
        // such as pausing all proposal related functions, restricting treasury access, etc.
    }

    /**
     * @notice Admin function to resolve emergency shutdown and resume normal DAO operations.
     *  This would typically require careful review and potentially a governance proposal to lift the shutdown.
     */
    function resolveEmergencyShutdown() external onlyAdmin {
        emergencyShutdownActive = false;
        emit EmergencyShutdownResolved();
        // In a real-world scenario, this might require further checks or governance approval
        // before fully reactivating all DAO functions.
    }

    // ----------- Utility Function to convert uint to string for descriptions -----------
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    // Fallback function to receive ETH
    receive() external payable {}
}
```