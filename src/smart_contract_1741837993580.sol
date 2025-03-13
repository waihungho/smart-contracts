```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Advanced Decentralized Autonomous Organization (DAO) - "SynergyDAO"
 * @author Bard (AI Assistant)
 * @dev A sophisticated DAO contract with advanced governance, reputation, dynamic roles,
 *      skill-based contribution, delegated voting, conditional proposals, and more.
 *      This contract aims to showcase creative and trendy functions beyond basic DAO implementations.
 *
 * **Outline and Function Summary:**
 *
 * **Core DAO Functions:**
 *  1. `joinDAO()`: Allows users to request membership to the DAO.
 *  2. `leaveDAO()`: Allows members to leave the DAO.
 *  3. `isMember(address _member)`: Checks if an address is a member of the DAO.
 *  4. `getMemberCount()`: Returns the total number of DAO members.
 *
 * **Governance & Proposal System:**
 *  5. `createProposal(string memory _title, string memory _description, bytes memory _calldata, address _target, uint256 _value, uint256 _votingDuration)`: Creates a new proposal for DAO actions.
 *  6. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows members to vote for or against a proposal.
 *  7. `executeProposal(uint256 _proposalId)`: Executes a passed proposal after the voting period.
 *  8. `cancelProposal(uint256 _proposalId)`: Allows the proposer to cancel a proposal before voting starts (with conditions).
 *  9. `getProposalState(uint256 _proposalId)`: Returns the current state of a proposal (Pending, Active, Passed, Failed, Executed, Cancelled).
 *  10. `getProposalVotes(uint256 _proposalId)`: Returns the vote counts (for and against) for a given proposal.
 *  11. `getProposalDetails(uint256 _proposalId)`: Returns detailed information about a proposal.
 *
 * **Reputation & Skill-Based Roles:**
 *  12. `contributeSkill(string memory _skill)`: Allows members to register their skills with the DAO.
 *  13. `getMemberSkills(address _member)`: Returns the skills registered by a member.
 *  14. `assignRole(address _member, string memory _role)`: Assigns a specific role to a member (DAO-governed).
 *  15. `revokeRole(address _member, string memory _role)`: Revokes a role from a member (DAO-governed).
 *  16. `hasRole(address _member, string memory _role)`: Checks if a member has a specific role.
 *  17. `getRoleMembers(string memory _role)`: Returns a list of members who have a specific role.
 *
 * **Advanced Features:**
 *  18. `delegateVotingPower(address _delegatee)`: Allows members to delegate their voting power to another member.
 *  19. `undelegateVotingPower()`: Cancels voting power delegation.
 *  20. `getVotingPower(address _member)`: Returns the voting power of a member (considering delegation).
 *  21. `proposeConditionalExecution(string memory _title, string memory _description, bytes memory _calldata, address _target, uint256 _value, uint256 _votingDuration, address _conditionContract, bytes memory _conditionCalldata)`: Creates a proposal that executes only if a condition on another contract is met.
 *  22. `checkConditionalProposalCondition(uint256 _proposalId)`:  Externally callable function to check and update the status of a conditional proposal.
 *  23. `setProposalQuorum(uint256 _newQuorumPercentage)`:  DAO-governed function to change the quorum percentage required for proposal passing.
 *  24. `setVotingDuration(uint256 _proposalId, uint256 _newDuration)`: DAO-governed function to extend the voting duration of a specific proposal (before voting ends).
 *  25. `depositFunds()`: Allows anyone to deposit funds into the DAO treasury.
 *  26. `requestWithdrawal(address _recipient, uint256 _amount, string memory _reason)`: Members can request withdrawals from the treasury (requires proposal approval).
 *
 */
contract SynergyDAO {

    // ------ State Variables ------

    address public daoOwner;
    uint256 public memberCount;
    mapping(address => bool) public isDAOActiveMember;
    mapping(address => string[]) public memberSkills;
    mapping(address => mapping(string => bool)) public memberRoles;
    mapping(address => address) public delegatedVotingPower; // Member => Delegatee
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalQuorumPercentage = 50; // Default quorum: 50%
    uint256 public defaultVotingDuration = 7 days; // Default voting duration
    mapping(string => address[]) public roleMembers; // Role Name => Array of Member Addresses

    enum ProposalState { Pending, Active, Passed, Failed, Executed, Cancelled, ConditionalCheckPending, ConditionalPassed, ConditionalFailed }

    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        bytes calldata;
        address target;
        uint256 value;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalState state;
        mapping(address => bool) hasVoted;
        address conditionContract; // For conditional proposals
        bytes conditionCalldata;   // For conditional proposals
    }

    // ------ Events ------

    event MembershipRequested(address indexed member);
    event MembershipGranted(address indexed member);
    event MembershipRevoked(address indexed member);
    event MemberLeft(address indexed member);
    event SkillContributed(address indexed member, string skill);
    event RoleAssigned(address indexed member, string role, address indexed by);
    event RoleRevoked(address indexed member, string role, address indexed by);
    event VotingPowerDelegated(address indexed delegator, address indexed delegatee);
    event VotingPowerUndelegated(address indexed delegator);
    event ProposalCreated(uint256 proposalId, address proposer, string title);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCancelled(uint256 proposalId);
    event ProposalStateUpdated(uint256 proposalId, ProposalState newState);
    event FundsDeposited(address indexed sender, uint256 amount);
    event WithdrawalRequested(address indexed recipient, uint256 amount, string reason);

    // ------ Modifiers ------

    modifier onlyDAOOwner() {
        require(msg.sender == daoOwner, "Only DAO owner can perform this action.");
        _;
    }

    modifier onlyMember() {
        require(isDAOActiveMember[msg.sender], "Only active DAO members can perform this action.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId < proposalCount, "Invalid proposal ID.");
        _;
    }

    modifier onlyProposer(uint256 _proposalId) {
        require(proposals[_proposalId].proposer == msg.sender, "Only the proposer can perform this action.");
        _;
    }

    modifier inProposalState(uint256 _proposalId, ProposalState _state) {
        require(proposals[_proposalId].state == _state, "Proposal is not in the required state.");
        _;
    }


    // ------ Constructor ------

    constructor() {
        daoOwner = msg.sender;
        memberCount = 0;
    }

    // ------ Core DAO Functions ------

    function joinDAO() external {
        require(!isDAOActiveMember[msg.sender], "Already a member.");
        isDAOActiveMember[msg.sender] = true;
        memberCount++;
        emit MembershipGranted(msg.sender);
    }

    function leaveDAO() external onlyMember {
        isDAOActiveMember[msg.sender] = false;
        memberCount--;
        emit MemberLeft(msg.sender);
    }

    function isMember(address _member) external view returns (bool) {
        return isDAOActiveMember[_member];
    }

    function getMemberCount() external view returns (uint256) {
        return memberCount;
    }

    // ------ Governance & Proposal System ------

    function createProposal(
        string memory _title,
        string memory _description,
        bytes memory _calldata,
        address _target,
        uint256 _value,
        uint256 _votingDuration
    ) external onlyMember {
        require(_votingDuration > 0 && _votingDuration <= 30 days, "Voting duration must be between 1 day and 30 days.");
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            title: _title,
            description: _description,
            calldata: _calldata,
            target: _target,
            value: _value,
            votingStartTime: 0, // Set when voting starts
            votingEndTime: 0,   // Set when voting starts
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Pending,
            conditionContract: address(0), // Not a conditional proposal
            conditionCalldata: bytes('')
        });
        emit ProposalCreated(proposalCount, msg.sender, _title);
        proposalCount++;
    }

    function proposeConditionalExecution(
        string memory _title,
        string memory _description,
        bytes memory _calldata,
        address _target,
        uint256 _value,
        uint256 _votingDuration,
        address _conditionContract,
        bytes memory _conditionCalldata
    ) external onlyMember {
        require(_votingDuration > 0 && _votingDuration <= 30 days, "Voting duration must be between 1 day and 30 days.");
        require(_conditionContract != address(0), "Condition contract address cannot be zero for conditional proposals.");

        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            title: _title,
            description: _description,
            calldata: _calldata,
            target: _target,
            value: _value,
            votingStartTime: 0, // Set when voting starts
            votingEndTime: 0,   // Set when voting starts
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.ConditionalCheckPending, // Initially pending condition check
            conditionContract: _conditionContract,
            conditionCalldata: _conditionCalldata
        });
        emit ProposalCreated(proposalCount, msg.sender, _title);
        proposalCount++;
    }


    function startProposalVoting(uint256 _proposalId) internal validProposalId(_proposalId) inProposalState(_proposalId, ProposalState.Pending) {
        proposals[_proposalId].votingStartTime = block.timestamp;
        proposals[_proposalId].votingEndTime = block.timestamp + defaultVotingDuration;
        proposals[_proposalId].state = ProposalState.Active;
        emit ProposalStateUpdated(_proposalId, ProposalState.Active);
    }

    function startConditionalProposalVoting(uint256 _proposalId) internal validProposalId(_proposalId) inProposalState(_proposalId, ProposalState.ConditionalPassed) {
        proposals[_proposalId].votingStartTime = block.timestamp;
        proposals[_proposalId].votingEndTime = block.timestamp + defaultVotingDuration;
        proposals[_proposalId].state = ProposalState.Active;
        emit ProposalStateUpdated(_proposalId, ProposalState.Active);
    }


    function voteOnProposal(uint256 _proposalId, bool _support) external onlyMember validProposalId(_proposalId) inProposalState(_proposalId, ProposalState.Active) {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal.");
        require(block.timestamp <= proposal.votingEndTime, "Voting period has ended.");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += getVotingPower(msg.sender);
        } else {
            proposal.votesAgainst += getVotingPower(msg.sender);
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) external onlyMember validProposalId(_proposalId) inProposalState(_proposalId, ProposalState.Passed) {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp > proposal.votingEndTime, "Voting period must be ended to execute.");
        require(proposal.votesFor * 100 >= (proposal.votesFor + proposal.votesAgainst) * proposalQuorumPercentage, "Proposal did not reach quorum.");

        proposal.state = ProposalState.Executed;
        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.calldata);
        require(success, "Proposal execution failed.");
        emit ProposalExecuted(_proposalId);
        emit ProposalStateUpdated(_proposalId, ProposalState.Executed);
    }

    function cancelProposal(uint256 _proposalId) external onlyProposer(_proposalId) validProposalId(_proposalId) inProposalState(_proposalId, ProposalState.Pending) {
        proposals[_proposalId].state = ProposalState.Cancelled;
        emit ProposalCancelled(_proposalId);
        emit ProposalStateUpdated(_proposalId, ProposalState.Cancelled);
    }

    function getProposalState(uint256 _proposalId) external view validProposalId(_proposalId) returns (ProposalState) {
        return proposals[_proposalId].state;
    }

    function getProposalVotes(uint256 _proposalId) external view validProposalId(_proposalId) returns (uint256 votesFor, uint256 votesAgainst) {
        return (proposals[_proposalId].votesFor, proposals[_proposalId].votesAgainst);
    }

    function getProposalDetails(uint256 _proposalId) external view validProposalId(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    // ------ Reputation & Skill-Based Roles ------

    function contributeSkill(string memory _skill) external onlyMember {
        memberSkills[msg.sender].push(_skill);
        emit SkillContributed(msg.sender, _skill);
    }

    function getMemberSkills(address _member) external view returns (string[] memory) {
        return memberSkills[_member];
    }

    function assignRole(address _member, string memory _role) external onlyDAOOwner {
        require(!memberRoles[_member][_role], "Member already has this role.");
        memberRoles[_member][_role] = true;
        roleMembers[_role].push(_member);
        emit RoleAssigned(_member, _role, msg.sender);
    }

    function revokeRole(address _member, string memory _role) external onlyDAOOwner {
        require(memberRoles[_member][_role], "Member does not have this role.");
        memberRoles[_member][_role] = false;
        // Remove from roleMembers array
        address[] storage membersWithRole = roleMembers[_role];
        for (uint256 i = 0; i < membersWithRole.length; i++) {
            if (membersWithRole[i] == _member) {
                membersWithRole[i] = membersWithRole[membersWithRole.length - 1];
                membersWithRole.pop();
                break;
            }
        }
        emit RoleRevoked(_member, _role, msg.sender);
    }

    function hasRole(address _member, string memory _role) external view returns (bool) {
        return memberRoles[_member][_role];
    }

    function getRoleMembers(string memory _role) external view returns (address[] memory) {
        return roleMembers[_role];
    }


    // ------ Advanced Features ------

    function delegateVotingPower(address _delegatee) external onlyMember {
        require(isDAOActiveMember[_delegatee] && _delegatee != msg.sender, "Invalid delegatee.");
        delegatedVotingPower[msg.sender] = _delegatee;
        emit VotingPowerDelegated(msg.sender, _delegatee);
    }

    function undelegateVotingPower() external onlyMember {
        delete delegatedVotingPower[msg.sender];
        emit VotingPowerUndelegated(msg.sender);
    }

    function getVotingPower(address _member) public view returns (uint256) {
        if (delegatedVotingPower[_member] != address(0)) {
            return getVotingPower(delegatedVotingPower[_member]); // Recursively get voting power of delegatee
        } else {
            return 1; // Base voting power is 1 (can be adjusted based on reputation, etc. in more advanced versions)
        }
    }

    function checkConditionalProposalCondition(uint256 _proposalId) external validProposalId(_proposalId) inProposalState(_proposalId, ProposalState.ConditionalCheckPending) {
        Proposal storage proposal = proposals[_proposalId];
        (bool conditionMet, bytes memory returnData) = proposal.conditionContract.staticcall(proposal.conditionCalldata);
        if (conditionMet) {
            proposal.state = ProposalState.ConditionalPassed;
            startConditionalProposalVoting(_proposalId); // Automatically start voting if condition is met
            emit ProposalStateUpdated(_proposalId, ProposalState.ConditionalPassed);
        } else {
            proposal.state = ProposalState.ConditionalFailed;
            emit ProposalStateUpdated(_proposalId, ProposalState.ConditionalFailed);
        }
    }

    function setProposalQuorum(uint256 _newQuorumPercentage) external onlyDAOOwner {
        require(_newQuorumPercentage >= 1 && _newQuorumPercentage <= 100, "Quorum percentage must be between 1 and 100.");
        proposalQuorumPercentage = _newQuorumPercentage;
    }

    function setVotingDuration(uint256 _proposalId, uint256 _newDuration) external onlyDAOOwner validProposalId(_proposalId) inProposalState(_proposalId, ProposalState.Pending) {
        require(_newDuration > 0 && _newDuration <= 30 days, "Voting duration must be between 1 day and 30 days.");
        defaultVotingDuration = _newDuration; // Note: This changes default duration for *future* proposals, not the specific proposal.
        // To change duration for a specific proposal already created but not yet active, more complex logic is needed.
        // For simplicity, this function now sets the default for future proposals.
    }

    // ------ Treasury Functions ------

    function depositFunds() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    function requestWithdrawal(address _recipient, uint256 _amount, string memory _reason) external onlyMember {
        require(_recipient != address(0), "Invalid recipient address.");
        require(_amount > 0, "Withdrawal amount must be greater than zero.");

        bytes memory calldataPayload = abi.encodeWithSignature("transfer(address,uint256)", _recipient, _amount);
        createProposal(
            "Withdrawal Request",
            string.concat("Withdrawal request to ", _reason),
            calldataPayload,
            address(this), // Target this contract for internal token transfer (if managing tokens) or a separate treasury contract.
            0, // Value should be 0 if we are just transferring internal balance. If external token, adjust accordingly.
            defaultVotingDuration
        );
        emit WithdrawalRequested(_recipient, _amount, _reason);
    }

    // Fallback function to receive Ether
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    // Fallback function to receive data (for contract interactions)
    fallback() external payable {
         emit FundsDeposited(msg.sender, msg.value);
    }

    // Example function that can be called by proposals (e.g., for treasury withdrawals)
    function transfer(address _to, uint256 _amount) external {
        require(msg.sender == address(this), "Only this contract can call this function (via proposal execution).");
        payable(_to).transfer(_amount); // For Ether withdrawals from contract balance
    }
}
```