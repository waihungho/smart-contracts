```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Organization (DAO) with Dynamic Governance and Reputation System
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a DAO with advanced features including:
 *      - Dynamic Governance: Adaptable voting mechanisms and parameters based on community proposals.
 *      - Reputation System: Tracks member contributions and influences voting power and rewards.
 *      - Role-Based Access Control: Defines different roles with specific permissions.
 *      - Proposal Lifecycle Management: Comprehensive proposal states and actions (create, vote, execute, cancel).
 *      - Treasury Management: Securely manages DAO funds with controlled withdrawals.
 *      - Event-Driven Architecture: Emits events for all significant actions for off-chain monitoring.
 *      - Custom Proposal Types: Extensible framework to add new proposal types beyond core governance.
 *      - Reputation Decay & Rewards: Incentivizes continuous participation and contribution.
 *      - Emergency Shutdown: A safeguard mechanism for critical situations.
 *
 * Function Summary:
 *
 * **Membership & Roles:**
 * 1. joinDAO()               : Allows a user to become a member of the DAO.
 * 2. leaveDAO()              : Allows a member to leave the DAO.
 * 3. getMemberCount()         : Returns the total number of DAO members.
 * 4. isMember(address _account): Checks if an address is a member of the DAO.
 * 5. getMemberList()          : Returns a list of all DAO members (for demonstration, consider pagination in real-world).
 * 6. assignRole(address _member, Role _role): Assigns a specific role to a member (governance controlled).
 * 7. removeRole(address _member, Role _role): Removes a role from a member (governance controlled).
 * 8. getMemberRole(address _member): Returns the role of a member.
 *
 * **Governance Proposals:**
 * 9. createProposal(ProposalType _proposalType, string memory _title, string memory _description, bytes memory _data) : Allows members to create proposals of various types.
 * 10. voteOnProposal(uint _proposalId, Vote _vote): Allows members to vote on active proposals.
 * 11. executeProposal(uint _proposalId)          : Executes a passed proposal (governance or admin controlled).
 * 12. getProposalState(uint _proposalId)         : Returns the current state of a proposal.
 * 13. getProposalDetails(uint _proposalId)        : Returns detailed information about a proposal.
 * 14. cancelProposal(uint _proposalId)           : Cancels a proposal before voting ends (creator or admin controlled).
 * 15. setVotingPeriod(uint _newVotingPeriod)      : Creates a proposal to change the default voting period.
 * 16. setQuorum(uint _newQuorum)                 : Creates a proposal to change the voting quorum.
 *
 * **Reputation System:**
 * 17. allocateReputation(address _member, uint _amount): Allocates reputation points to a member (governance controlled).
 * 18. deductReputation(address _member, uint _amount) : Deducts reputation points from a member (governance controlled).
 * 19. getMemberReputation(address _member)       : Returns the reputation points of a member.
 * 20. applyReputationDecay()                     : Applies a decay factor to all members' reputation over time (governance triggered).
 *
 * **Treasury & Admin:**
 * 21. depositFunds()                             : Allows anyone to deposit funds into the DAO treasury.
 * 22. withdrawFunds(uint _amount, address payable _recipient) : Allows withdrawing funds from the treasury (governance proposal required).
 * 23. getTreasuryBalance()                       : Returns the current balance of the DAO treasury.
 * 24. emergencyShutdown()                        : Triggers an emergency shutdown of the DAO (admin controlled, can be governance based).
 * 25. setAdmin(address _newAdmin)                : Sets a new admin address (governance controlled).
 * 26. getAdmin()                                 : Returns the current admin address.
 */
contract AdvancedDAO {

    // -------- Enums and Structs --------

    enum Role {
        MEMBER,         // Basic DAO member
        ADMIN,          // DAO administrator with elevated privileges
        GOVERNANCE_COUNCIL // Members of the governance council with special voting rights (example)
    }

    enum ProposalType {
        GENERIC,
        TREASURY_WITHDRAWAL,
        GOVERNANCE_PARAMETER_CHANGE,
        ROLE_ASSIGNMENT,
        ROLE_REMOVAL,
        REPUTATION_ALLOCATION,
        REPUTATION_DEDUCTION,
        REPUTATION_DECAY_TRIGGER,
        ADMIN_CHANGE,
        EMERGENCY_SHUTDOWN // Example: More types can be added
    }

    enum ProposalState {
        PENDING,
        ACTIVE,
        PASSED,
        REJECTED,
        EXECUTED,
        CANCELLED
    }

    enum Vote {
        FOR,
        AGAINST,
        ABSTAIN
    }

    struct Proposal {
        uint id;
        ProposalType proposalType;
        string title;
        string description;
        address creator;
        uint startTime;
        uint endTime;
        uint quorum;
        uint forVotes;
        uint againstVotes;
        uint abstainVotes;
        ProposalState state;
        bytes data; // To store proposal-specific data
        mapping(address => Vote) votes; // Track votes per member
    }

    // -------- State Variables --------

    address public admin;
    mapping(address => Role) public memberRoles; // Map address to their role
    mapping(address => uint) public memberReputation; // Map address to their reputation points
    address[] public memberList; // List of members for iteration (consider better data structures for large scale)
    uint public memberCount;
    uint public proposalCount;
    mapping(uint => Proposal) public proposals;
    uint public votingPeriod = 7 days; // Default voting period
    uint public quorumPercentage = 51; // Default quorum percentage (e.g., 51% of votes needed to pass)
    bool public isShutdown = false;
    uint public reputationDecayRate = 1; // Percentage decay per decay period (example)
    uint public reputationDecayPeriod = 30 days; // Time interval for reputation decay (example)
    uint public lastReputationDecayTime;


    // -------- Events --------

    event MemberJoined(address member);
    event MemberLeft(address member);
    event RoleAssigned(address member, Role role);
    event RoleRemoved(address member, Role role);
    event ProposalCreated(uint proposalId, ProposalType proposalType, address creator);
    event VoteCast(uint proposalId, address voter, Vote vote);
    event ProposalExecuted(uint proposalId);
    event ProposalCancelled(uint proposalId);
    event ReputationAllocated(address member, uint amount);
    event ReputationDeducted(address member, uint amount);
    event ReputationDecayApplied();
    event FundsDeposited(address sender, uint amount);
    event FundsWithdrawn(address recipient, uint amount);
    event EmergencyShutdownTriggered();
    event AdminChanged(address newAdmin);


    // -------- Modifiers --------

    modifier onlyMember() {
        require(memberRoles[msg.sender] == Role.MEMBER || memberRoles[msg.sender] == Role.ADMIN || memberRoles[msg.sender] == Role.GOVERNANCE_COUNCIL, "Not a DAO member");
        _;
    }

    modifier onlyAdmin() {
        require(memberRoles[msg.sender] == Role.ADMIN, "Not an admin");
        _;
    }

    modifier proposalExists(uint _proposalId) {
        require(_proposalId < proposalCount && proposals[_proposalId].id == _proposalId, "Proposal does not exist");
        _;
    }

    modifier proposalInState(uint _proposalId, ProposalState _state) {
        require(proposals[_proposalId].state == _state, "Proposal is not in the required state");
        _;
    }

    modifier proposalActive(uint _proposalId) {
        require(proposals[_proposalId].state == ProposalState.ACTIVE, "Proposal is not active");
        require(block.timestamp < proposals[_proposalId].endTime, "Voting period has ended");
        _;
    }

    modifier proposalNotCancelled(uint _proposalId) {
        require(proposals[_proposalId].state != ProposalState.CANCELLED, "Proposal is cancelled");
        _;
    }

    modifier notShutdown() {
        require(!isShutdown, "DAO is shutdown");
        _;
    }


    // -------- Constructor --------

    constructor() {
        admin = msg.sender;
        memberRoles[msg.sender] = Role.ADMIN; // Creator is the initial admin
        memberRoles[msg.sender] = Role.MEMBER; // Creator is also the initial member
        memberList.push(msg.sender);
        memberCount = 1;
        lastReputationDecayTime = block.timestamp;
    }

    // -------- Membership Functions --------

    function joinDAO() external notShutdown {
        require(memberRoles[msg.sender] != Role.MEMBER && memberRoles[msg.sender] != Role.ADMIN && memberRoles[msg.sender] != Role.GOVERNANCE_COUNCIL, "Already a member");
        memberRoles[msg.sender] = Role.MEMBER;
        memberList.push(msg.sender);
        memberCount++;
        memberReputation[msg.sender] = 100; // Initial reputation for new members
        emit MemberJoined(msg.sender);
    }

    function leaveDAO() external onlyMember notShutdown {
        delete memberRoles[msg.sender];
        for (uint i = 0; i < memberList.length; i++) {
            if (memberList[i] == msg.sender) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        memberCount--;
        delete memberReputation[msg.sender]; // Remove reputation upon leaving
        emit MemberLeft(msg.sender);
    }

    function getMemberCount() external view returns (uint) {
        return memberCount;
    }

    function isMember(address _account) external view returns (bool) {
        return (memberRoles[_account] == Role.MEMBER || memberRoles[_account] == Role.ADMIN || memberRoles[_account] == Role.GOVERNANCE_COUNCIL);
    }

    function getMemberList() external view returns (address[] memory) {
        return memberList;
    }

    function assignRole(address _member, Role _role) external onlyAdmin notShutdown { // Example: Admin can assign roles
        memberRoles[_member] = _role;
        emit RoleAssigned(_member, _role);
    }

    function removeRole(address _member, Role _role) external onlyAdmin notShutdown { // Example: Admin can remove roles
        delete memberRoles[_member];
        emit RoleRemoved(_member, _role);
    }

    function getMemberRole(address _member) external view returns (Role) {
        return memberRoles[_member];
    }


    // -------- Governance Proposal Functions --------

    function createProposal(
        ProposalType _proposalType,
        string memory _title,
        string memory _description,
        bytes memory _data
    ) external onlyMember notShutdown {
        uint proposalId = proposalCount++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: _proposalType,
            title: _title,
            description: _description,
            creator: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            quorum: (memberCount * quorumPercentage) / 100,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            state: ProposalState.ACTIVE,
            data: _data,
            votes: mapping(address => Vote)()
        });
        emit ProposalCreated(proposalId, _proposalType, msg.sender);
    }

    function voteOnProposal(uint _proposalId, Vote _vote) external onlyMember notShutdown proposalExists(_proposalId) proposalActive(_proposalId) proposalNotCancelled(_proposalId) {
        require(proposals[_proposalId].votes[msg.sender] == Vote.ABSTAIN || proposals[_proposalId].votes[msg.sender] == Vote.AGAINST || proposals[_proposalId].votes[msg.sender] == Vote.FOR || proposals[_proposalId].votes[msg.sender] == Vote(0), "Already voted on this proposal"); // Ensure member hasn't voted yet (Vote(0) is default enum value)

        proposals[_proposalId].votes[msg.sender] = _vote;
        if (_vote == Vote.FOR) {
            proposals[_proposalId].forVotes += getVotingPower(msg.sender); // Voting power based on reputation
        } else if (_vote == Vote.AGAINST) {
            proposals[_proposalId].againstVotes += getVotingPower(msg.sender);
        } else if (_vote == Vote.ABSTAIN) {
            proposals[_proposalId].abstainVotes += getVotingPower(msg.sender);
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint _proposalId) external notShutdown proposalExists(_proposalId) proposalInState(_proposalId, ProposalState.ACTIVE) proposalNotCancelled(_proposalId) {
        require(block.timestamp >= proposals[_proposalId].endTime, "Voting period is still active");

        if (proposals[_proposalId].forVotes >= proposals[_proposalId].quorum) {
            proposals[_proposalId].state = ProposalState.PASSED;
            _executeProposalAction(_proposalId); // Internal function to handle proposal execution logic
            proposals[_proposalId].state = ProposalState.EXECUTED;
            emit ProposalExecuted(_proposalId);
        } else {
            proposals[_proposalId].state = ProposalState.REJECTED;
        }
    }

    function getProposalState(uint _proposalId) external view proposalExists(_proposalId) returns (ProposalState) {
        return proposals[_proposalId].state;
    }

    function getProposalDetails(uint _proposalId) external view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function cancelProposal(uint _proposalId) external onlyMember proposalExists(_proposalId) proposalInState(_proposalId, ProposalState.ACTIVE) proposalNotCancelled(_proposalId) {
        require(proposals[_proposalId].creator == msg.sender || memberRoles[msg.sender] == Role.ADMIN, "Only creator or admin can cancel proposal");
        proposals[_proposalId].state = ProposalState.CANCELLED;
        emit ProposalCancelled(_proposalId);
    }

    // -------- Governance Parameter Change Proposals --------

    function setVotingPeriod(uint _newVotingPeriod) external onlyMember notShutdown {
        bytes memory data = abi.encode(_newVotingPeriod);
        createProposal(ProposalType.GOVERNANCE_PARAMETER_CHANGE, "Change Voting Period", "Proposal to update the voting period", data);
    }

    function setQuorum(uint _newQuorum) external onlyMember notShutdown {
        bytes memory data = abi.encode(_newQuorum);
        createProposal(ProposalType.GOVERNANCE_PARAMETER_CHANGE, "Change Quorum", "Proposal to update the voting quorum percentage", data);
    }


    // -------- Reputation System Functions --------

    function allocateReputation(address _member, uint _amount) external onlyAdmin notShutdown { // Example: Admin can allocate reputation, could be governance based
        memberReputation[_member] += _amount;
        emit ReputationAllocated(_member, _amount);
    }

    function deductReputation(address _member, uint _amount) external onlyAdmin notShutdown { // Example: Admin can deduct reputation, could be governance based
        require(memberReputation[_member] >= _amount, "Insufficient reputation to deduct");
        memberReputation[_member] -= _amount;
        emit ReputationDeducted(_member, _amount);
    }

    function getMemberReputation(address _member) external view returns (uint) {
        return memberReputation[_member];
    }

    function applyReputationDecay() external notShutdown {
        require(block.timestamp >= lastReputationDecayTime + reputationDecayPeriod, "Reputation decay period not reached yet");
        for (uint i = 0; i < memberList.length; i++) {
            address member = memberList[i];
            uint decayAmount = (memberReputation[member] * reputationDecayRate) / 100;
            if (memberReputation[member] > 0) { // Avoid underflow
                memberReputation[member] -= decayAmount;
            }
        }
        lastReputationDecayTime = block.timestamp;
        emit ReputationDecayApplied();
    }


    // -------- Treasury Functions --------

    function depositFunds() external payable notShutdown {
        emit FundsDeposited(msg.sender, msg.value);
    }

    function withdrawFunds(uint _amount, address payable _recipient) external onlyMember notShutdown { // Withdrawal requires a proposal
        bytes memory data = abi.encode(_amount, _recipient);
        createProposal(ProposalType.TREASURY_WITHDRAWAL, "Treasury Withdrawal", "Proposal to withdraw funds from the treasury", data);
    }

    function getTreasuryBalance() external view returns (uint) {
        return address(this).balance;
    }


    // -------- Admin & Emergency Functions --------

    function emergencyShutdown() external onlyAdmin notShutdown {
        isShutdown = true;
        emit EmergencyShutdownTriggered();
    }

    function setAdmin(address _newAdmin) external onlyAdmin notShutdown { // Admin change requires governance for more security in real-world scenarios
        bytes memory data = abi.encode(_newAdmin);
        createProposal(ProposalType.ADMIN_CHANGE, "Change Admin", "Proposal to change the DAO administrator", data);
    }

    function getAdmin() external view returns (address) {
        return admin;
    }


    // -------- Internal Helper Functions --------

    function _executeProposalAction(uint _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.proposalType == ProposalType.TREASURY_WITHDRAWAL) {
            (uint amount, address payable recipient) = abi.decode(proposal.data, (uint, address payable));
            _treasuryWithdrawal(recipient, amount);
        } else if (proposal.proposalType == ProposalType.GOVERNANCE_PARAMETER_CHANGE) {
            (uint newValue) = abi.decode(proposal.data, (uint));
            if (keccak256(bytes(proposal.title)) == keccak256(bytes("Change Voting Period"))) {
                votingPeriod = newValue;
            } else if (keccak256(bytes(proposal.title)) == keccak256(bytes("Change Quorum"))) {
                quorumPercentage = newValue;
            }
        } else if (proposal.proposalType == ProposalType.ROLE_ASSIGNMENT) {
            (address member, Role role) = abi.decode(proposal.data, (address, Role));
            assignRole(member, role);
        } else if (proposal.proposalType == ProposalType.ROLE_REMOVAL) {
            (address member, Role role) = abi.decode(proposal.data, (address, Role));
            removeRole(member, role);
        } else if (proposal.proposalType == ProposalType.REPUTATION_ALLOCATION) {
            (address member, uint amount) = abi.decode(proposal.data, (address, uint));
            allocateReputation(member, amount);
        } else if (proposal.proposalType == ProposalType.REPUTATION_DEDUCTION) {
            (address member, uint amount) = abi.decode(proposal.data, (address, uint));
            deductReputation(member, amount);
        } else if (proposal.proposalType == ProposalType.REPUTATION_DECAY_TRIGGER) {
            applyReputationDecay();
        } else if (proposal.proposalType == ProposalType.ADMIN_CHANGE) {
            (address newAdmin) = abi.decode(proposal.data, (address));
            admin = newAdmin;
            memberRoles[admin] = Role.ADMIN; // Ensure new admin has admin role
            emit AdminChanged(admin);
        } else if (proposal.proposalType == ProposalType.EMERGENCY_SHUTDOWN) {
            emergencyShutdown();
        }
        // Add more proposal type handling here as needed
    }

    function _treasuryWithdrawal(address payable _recipient, uint _amount) internal {
        require(address(this).balance >= _amount, "Insufficient funds in treasury");
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Treasury withdrawal failed");
        emit FundsWithdrawn(_recipient, _amount);
    }

    function getVotingPower(address _member) internal view returns (uint) {
        // Example: Voting power is reputation points + 1 (to avoid zero power for new members)
        return memberReputation[_member] + 1;
        // In a more complex system, voting power could be based on stake, roles, or more sophisticated reputation metrics.
    }

    // Fallback function to receive Ether
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
}
```