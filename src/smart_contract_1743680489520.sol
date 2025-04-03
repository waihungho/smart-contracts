```solidity
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation & Influence DAO
 * @author Bard (AI Assistant)
 * @dev A Decentralized Autonomous Organization (DAO) with a dynamic reputation and influence system.
 *      This DAO introduces a novel concept of member reputation and influence, which dynamically affects voting power
 *      and access to certain DAO functionalities. It goes beyond simple token-based voting and aims to create a
 *      more meritocratic and engaged community.
 *
 * **Outline and Function Summary:**
 *
 * **Core DAO Functions:**
 * 1. `joinDAO()`: Allows a user to request membership to the DAO.
 * 2. `approveMembership(address _member)`: Governance (or designated role) function to approve a pending membership request.
 * 3. `leaveDAO()`: Allows a member to voluntarily leave the DAO.
 * 4. `kickMember(address _member)`: Governance (or designated role) function to remove a member from the DAO.
 * 5. `deposit(uint256 _amount)`: Allows members to deposit funds into the DAO treasury.
 * 6. `withdraw(uint256 _amount)`: Allows members to propose and vote on withdrawing funds from the DAO treasury.
 * 7. `getTreasuryBalance()`: Returns the current balance of the DAO treasury.
 *
 * **Proposal & Voting Functions:**
 * 8. `createProposal(string memory _description, bytes memory _payload)`: Allows members to create proposals for DAO actions.
 * 9. `castVote(uint256 _proposalId, bool _support)`: Allows members to cast their vote on a proposal. Voting power is influenced by reputation.
 * 10. `executeProposal(uint256 _proposalId)`: Executes a proposal if it passes the voting threshold and quorum.
 * 11. `getProposalState(uint256 _proposalId)`: Returns the current state (active, pending, executed, rejected) of a proposal.
 * 12. `getProposalDetails(uint256 _proposalId)`: Returns detailed information about a proposal.
 *
 * **Reputation & Influence System Functions:**
 * 13. `awardReputation(address _member, uint256 _amount, string memory _reason)`: Governance (or designated role) function to award reputation points to a member.
 * 14. `deductReputation(address _member, uint256 _amount, string memory _reason)`: Governance (or designated role) function to deduct reputation points from a member.
 * 15. `getMemberReputation(address _member)`: Returns the current reputation points of a member.
 * 16. `setReputationThreshold(uint256 _threshold)`: Governance (or designated role) function to set the reputation threshold for increased influence.
 * 17. `getReputationThreshold()`: Returns the current reputation threshold.
 * 18. `getVotingWeight(address _member)`: Returns the voting weight of a member, dynamically calculated based on reputation.
 *
 * **Governance & Parameter Setting Functions:**
 * 19. `setVotingQuorum(uint256 _quorumPercentage)`: Governance (or designated role) function to set the quorum percentage for proposals.
 * 20. `getVotingQuorum()`: Returns the current voting quorum percentage.
 * 21. `setVotingDuration(uint256 _durationBlocks)`: Governance (or designated role) function to set the voting duration in blocks.
 * 22. `getVotingDuration()`: Returns the current voting duration in blocks.
 * 23. `setGovernanceRole(address _governanceAddress, bool _isGovernance)`: Allows to assign or remove governance role to an address.
 * 24. `isGovernance(address _address)`: Checks if an address has governance role.
 *
 * **Events:**
 * Emits events for important actions like membership changes, proposal creation, voting, reputation updates, and governance parameter changes.
 */
contract DynamicReputationDAO {

    // **** State Variables ****
    address public daoOwner; // Address of the DAO owner/initial governance
    mapping(address => bool) public members; // Mapping of DAO members
    mapping(address => bool) public pendingMemberships; // Track pending membership requests
    mapping(address => uint256) public memberReputation; // Reputation points for each member
    uint256 public reputationThreshold = 100; // Reputation threshold for increased influence
    uint256 public votingQuorumPercentage = 50; // Percentage of members needed to reach quorum
    uint256 public votingDurationBlocks = 100; // Voting duration in blocks
    uint256 public proposalCounter = 0; // Counter for proposal IDs
    mapping(uint256 => Proposal) public proposals; // Mapping of proposal IDs to Proposal structs
    uint256 public treasuryBalance = 0; // DAO Treasury Balance
    mapping(address => bool) public governanceRoles; // Addresses with governance privileges

    enum ProposalState {
        Pending,
        Active,
        Executed,
        Rejected,
        Cancelled
    }

    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        ProposalState state;
        uint256 votesFor;
        uint256 votesAgainst;
        bytes payload; // Data to be executed if proposal passes
    }

    // **** Events ****
    event MembershipRequested(address indexed member);
    event MembershipApproved(address indexed member);
    event MemberLeft(address indexed member);
    event MemberKicked(address indexed member, address indexed kickedBy);
    event DepositReceived(address indexed sender, uint256 amount);
    event WithdrawalProposed(uint256 proposalId, address indexed proposer, uint256 amount);
    event ProposalCreated(uint256 proposalId, address indexed proposer);
    event VoteCast(uint256 proposalId, address indexed voter, bool support, uint256 votingWeight);
    event ProposalExecuted(uint256 proposalId);
    event ProposalRejected(uint256 proposalId);
    event ProposalCancelled(uint256 proposalId);
    event ReputationAwarded(address indexed member, uint256 amount, string reason);
    event ReputationDeducted(address indexed member, uint256 amount, string reason);
    event ReputationThresholdUpdated(uint256 newThreshold);
    event VotingQuorumUpdated(uint256 newQuorum);
    event VotingDurationUpdated(uint256 newDuration);
    event GovernanceRoleSet(address indexed account, bool isGovernance);

    // **** Modifiers ****
    modifier onlyOwner() {
        require(msg.sender == daoOwner, "Only DAO owner can call this function.");
        _;
    }

    modifier onlyGovernance() {
        require(governanceRoles[msg.sender] || msg.sender == daoOwner, "Only governance roles can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only DAO members can call this function.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(proposals[_proposalId].id == _proposalId, "Invalid proposal ID.");
        _;
    }

    modifier proposalInState(uint256 _proposalId, ProposalState _state) {
        require(proposals[_proposalId].state == _state, "Proposal is not in the required state.");
        _;
    }

    // **** Constructor ****
    constructor() {
        daoOwner = msg.sender;
        governanceRoles[msg.sender] = true; // Initial owner is a governance role
    }

    // **** Core DAO Functions ****

    /// @notice Allows a user to request membership to the DAO.
    function joinDAO() external {
        require(!members[msg.sender], "Already a member.");
        require(!pendingMemberships[msg.sender], "Membership request already pending.");
        pendingMemberships[msg.sender] = true;
        emit MembershipRequested(msg.sender);
    }

    /// @notice Governance function to approve a pending membership request.
    /// @param _member The address of the member to approve.
    function approveMembership(address _member) external onlyGovernance {
        require(pendingMemberships[_member], "No pending membership request for this address.");
        members[_member] = true;
        pendingMemberships[_member] = false;
        memberReputation[_member] = 0; // Initialize reputation to 0 for new members
        emit MembershipApproved(_member);
    }

    /// @notice Allows a member to voluntarily leave the DAO.
    function leaveDAO() external onlyMember {
        delete members[msg.sender];
        delete memberReputation[msg.sender];
        emit MemberLeft(msg.sender);
    }

    /// @notice Governance function to remove a member from the DAO.
    /// @param _member The address of the member to kick.
    function kickMember(address _member) external onlyGovernance {
        require(members[_member], "Not a member.");
        delete members[_member];
        delete memberReputation[_member];
        emit MemberKicked(_member, msg.sender);
    }

    /// @notice Allows members to deposit funds into the DAO treasury.
    /// @param _amount The amount to deposit.
    function deposit(uint256 _amount) external onlyMember payable {
        require(msg.value == _amount, "Amount sent does not match deposit amount.");
        treasuryBalance += _amount;
        emit DepositReceived(msg.sender, _amount);
    }

    /// @notice Allows members to propose and vote on withdrawing funds from the DAO treasury.
    /// @param _amount The amount to withdraw.
    function withdraw(uint256 _amount) external onlyMember {
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        require(treasuryBalance >= _amount, "Insufficient funds in treasury.");

        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            id: proposalCounter,
            description: string(abi.encodePacked("Withdrawal of ", uint2str(_amount), " wei")),
            proposer: msg.sender,
            startTime: block.number,
            endTime: block.number + votingDurationBlocks,
            state: ProposalState.Active,
            votesFor: 0,
            votesAgainst: 0,
            payload: abi.encodeWithSignature("executeWithdrawal(uint256)", _amount) // Example payload
        });
        emit ProposalCreated(proposalCounter, msg.sender);
    }

    function executeWithdrawal(uint256 _amount) internal {
        payable(msg.sender).transfer(_amount); // Be extremely cautious with direct transfers
        treasuryBalance -= _amount;
    }


    /// @notice Returns the current balance of the DAO treasury.
    function getTreasuryBalance() external view returns (uint256) {
        return treasuryBalance;
    }

    // **** Proposal & Voting Functions ****

    /// @notice Allows members to create proposals for DAO actions.
    /// @param _description A description of the proposal.
    /// @param _payload Data to be executed if the proposal passes (e.g., function call data).
    function createProposal(string memory _description, bytes memory _payload) external onlyMember {
        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            id: proposalCounter,
            description: _description,
            proposer: msg.sender,
            startTime: block.number,
            endTime: block.number + votingDurationBlocks,
            state: ProposalState.Active,
            votesFor: 0,
            votesAgainst: 0,
            payload: _payload
        });
        emit ProposalCreated(proposalCounter, msg.sender);
    }

    /// @notice Allows members to cast their vote on a proposal. Voting power is influenced by reputation.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for' vote, false for 'against' vote.
    function castVote(uint256 _proposalId, bool _support) external onlyMember validProposal(_proposalId) proposalInState(_proposalId, ProposalState.Active) {
        Proposal storage proposal = proposals[_proposalId];
        require(block.number <= proposal.endTime, "Voting period has ended.");
        // In a real-world scenario, prevent double voting (e.g., using a mapping of voter to vote status)

        uint256 votingWeight = getVotingWeight(msg.sender);

        if (_support) {
            proposal.votesFor += votingWeight;
        } else {
            proposal.votesAgainst += votingWeight;
        }
        emit VoteCast(_proposalId, msg.sender, _support, votingWeight);
    }

    /// @notice Executes a proposal if it passes the voting threshold and quorum.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyGovernance validProposal(_proposalId) proposalInState(_proposalId, ProposalState.Active) {
        Proposal storage proposal = proposals[_proposalId];
        require(block.number > proposal.endTime, "Voting period is still active.");

        uint256 totalMembers = 0;
        for (address member : members) { // Inefficient for large DAOs, consider alternative counting methods in production
            if (members[member]) {
                totalMembers++;
            }
        }
        uint256 quorum = (totalMembers * votingQuorumPercentage) / 100;
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;

        require(totalVotes >= quorum, "Quorum not reached.");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal rejected: More votes against.");

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId);

        // Execute the payload (be extremely careful with executing arbitrary payloads in production)
        (bool success, bytes memory returnData) = address(this).call(proposal.payload);
        require(success, string(returnData)); // Revert if payload execution fails
    }

    /// @notice Returns the current state (active, pending, executed, rejected) of a proposal.
    /// @param _proposalId The ID of the proposal.
    function getProposalState(uint256 _proposalId) external view validProposal(_proposalId) returns (ProposalState) {
        return proposals[_proposalId].state;
    }

    /// @notice Returns detailed information about a proposal.
    /// @param _proposalId The ID of the proposal.
    function getProposalDetails(uint256 _proposalId) external view validProposal(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice Internal helper function to update proposal state to rejected if voting ends negatively.
    function _rejectProposalIfFailed(uint256 _proposalId) internal validProposal(_proposalId) proposalInState(_proposalId, ProposalState.Active) {
        Proposal storage proposal = proposals[_proposalId];
        if (block.number > proposal.endTime && proposal.state == ProposalState.Active) {
            if (proposal.votesFor <= proposal.votesAgainst) {
                proposal.state = ProposalState.Rejected;
                emit ProposalRejected(_proposalId);
            }
        }
    }

    /// @notice Allows members to check and update proposal state after voting period ends (can be called periodically).
    function checkAndUpdateProposalState(uint256 _proposalId) external validProposal(_proposalId) proposalInState(_proposalId, ProposalState.Active) {
        _rejectProposalIfFailed(_proposalId);
    }


    // **** Reputation & Influence System Functions ****

    /// @notice Governance function to award reputation points to a member.
    /// @param _member The address of the member to award reputation to.
    /// @param _amount The amount of reputation points to award.
    /// @param _reason A reason for awarding reputation.
    function awardReputation(address _member, uint256 _amount, string memory _reason) external onlyGovernance {
        require(members[_member], "Recipient is not a member.");
        memberReputation[_member] += _amount;
        emit ReputationAwarded(_member, _amount, _reason);
    }

    /// @notice Governance function to deduct reputation points from a member.
    /// @param _member The address of the member to deduct reputation from.
    /// @param _amount The amount of reputation points to deduct.
    /// @param _reason A reason for deducting reputation.
    function deductReputation(address _member, uint256 _amount, string memory _reason) external onlyGovernance {
        require(members[_member], "Recipient is not a member.");
        require(memberReputation[_member] >= _amount, "Insufficient reputation to deduct.");
        memberReputation[_member] -= _amount;
        emit ReputationDeducted(_member, _amount, _reason);
    }

    /// @notice Returns the current reputation points of a member.
    /// @param _member The address of the member.
    function getMemberReputation(address _member) external view returns (uint256) {
        return memberReputation[_member];
    }

    /// @notice Governance function to set the reputation threshold for increased influence.
    /// @param _threshold The new reputation threshold.
    function setReputationThreshold(uint256 _threshold) external onlyGovernance {
        reputationThreshold = _threshold;
        emit ReputationThresholdUpdated(_threshold);
    }

    /// @notice Returns the current reputation threshold.
    function getReputationThreshold() external view returns (uint256) {
        return reputationThreshold;
    }

    /// @notice Returns the voting weight of a member, dynamically calculated based on reputation.
    /// @param _member The address of the member.
    function getVotingWeight(address _member) public view returns (uint256) {
        if (memberReputation[_member] >= reputationThreshold) {
            // Example: Members with reputation above threshold have double voting weight
            return 2;
        } else {
            return 1;
        }
        // Can implement more sophisticated weighting logic based on reputation levels or tiers
    }

    // **** Governance & Parameter Setting Functions ****

    /// @notice Governance function to set the quorum percentage for proposals.
    /// @param _quorumPercentage The new quorum percentage (0-100).
    function setVotingQuorum(uint256 _quorumPercentage) external onlyGovernance {
        require(_quorumPercentage <= 100, "Quorum percentage must be between 0 and 100.");
        votingQuorumPercentage = _quorumPercentage;
        emit VotingQuorumUpdated(_quorumPercentage);
    }

    /// @notice Returns the current voting quorum percentage.
    function getVotingQuorum() external view returns (uint256) {
        return votingQuorumPercentage;
    }

    /// @notice Governance function to set the voting duration in blocks.
    /// @param _durationBlocks The new voting duration in blocks.
    function setVotingDuration(uint256 _durationBlocks) external onlyGovernance {
        votingDurationBlocks = _durationBlocks;
        emit VotingDurationUpdated(_durationBlocks);
    }

    /// @notice Returns the current voting duration in blocks.
    function getVotingDuration() external view returns (uint256) {
        return votingDurationBlocks;
    }

    /// @notice Allows to assign or remove governance role to an address.
    /// @param _governanceAddress The address to set governance role for.
    /// @param _isGovernance True to assign governance role, false to remove.
    function setGovernanceRole(address _governanceAddress, bool _isGovernance) external onlyGovernance {
        governanceRoles[_governanceAddress] = _isGovernance;
        emit GovernanceRoleSet(_governanceAddress, _isGovernance);
    }

    /// @notice Checks if an address has governance role.
    /// @param _address The address to check.
    function isGovernance(address _address) external view returns (bool) {
        return governanceRoles[_address];
    }

    // **** Utility Function (String conversion for events) ****
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
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}
```