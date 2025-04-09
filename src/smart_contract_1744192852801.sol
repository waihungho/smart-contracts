```solidity
/**
 * @title Decentralized Autonomous Organization (DAO) with Dynamic Governance and Reputation System
 * @author Bard (AI Model)
 * @dev This smart contract implements a DAO with advanced features including:
 *      - Dynamic Governance: Voting power and quorum based on reputation.
 *      - Reputation System:  Members earn reputation through participation and positive actions.
 *      - Role-Based Access Control:  Granular permissions for different DAO actions.
 *      - Proposal Types:  Support for various types of proposals (parameter changes, treasury spending, role assignments, custom functions).
 *      - Challenge and Dispute Resolution: Mechanism to challenge proposals and initiate dispute resolution.
 *      - Delegated Voting:  Members can delegate their voting power.
 *      - Timed Actions:  Actions that can be scheduled for execution after a certain time.
 *      - Emergency Pause:  Mechanism to pause critical DAO functions in case of emergencies.
 *      - On-Chain Data Analytics:  Basic functions to query DAO statistics.
 *      - NFT-Based Membership (Optional - can be extended):  Potential to integrate NFT-based membership in the future.
 *
 * Function Summary:
 *
 * **Membership Management:**
 *   - joinDAO(): Allows users to request membership in the DAO.
 *   - approveMembership(address _member):  Admin function to approve pending membership requests.
 *   - removeMember(address _member): Admin function to remove a member from the DAO.
 *   - getMemberList(): Returns a list of current DAO members.
 *   - isMember(address _user): Checks if an address is a member of the DAO.
 *
 * **Reputation System:**
 *   - awardReputation(address _member, uint256 _amount): Admin/Governance function to award reputation points to a member.
 *   - penalizeReputation(address _member, uint256 _amount): Admin/Governance function to penalize reputation points from a member.
 *   - getMemberReputation(address _member):  Returns the reputation points of a member.
 *
 * **Governance and Proposals:**
 *   - createProposal(string memory _title, string memory _description, ProposalType _proposalType, bytes memory _proposalData): Allows members to create proposals.
 *   - voteOnProposal(uint256 _proposalId, VoteOption _vote): Allows members to vote on active proposals.
 *   - executeProposal(uint256 _proposalId): Executes a proposal if it passes and the voting period is over.
 *   - cancelProposal(uint256 _proposalId): Admin/Proposer function to cancel a proposal before voting ends.
 *   - challengeProposal(uint256 _proposalId): Allows members to challenge a proposal and trigger dispute resolution.
 *   - resolveDispute(uint256 _proposalId, DisputeResolution _resolution): Admin/Governance function to resolve disputes for challenged proposals.
 *   - getProposalDetails(uint256 _proposalId): Returns details of a specific proposal.
 *   - getActiveProposals(): Returns a list of currently active proposal IDs.
 *   - getPastProposals(): Returns a list of past proposal IDs.
 *   - setVotingPeriod(uint256 _newPeriod): Admin function to change the default voting period.
 *   - setQuorumThreshold(uint256 _newThreshold): Admin function to change the quorum threshold percentage.
 *   - delegateVote(address _delegatee): Allows members to delegate their voting power to another member.
 *   - revokeDelegation(): Allows members to revoke their vote delegation.
 *
 * **Treasury Management (Example - can be expanded):**
 *   - depositToTreasury(): Allows anyone to deposit funds into the DAO treasury.
 *   - createTreasuryWithdrawalProposal(address _recipient, uint256 _amount, string memory _reason): Allows members to propose treasury withdrawals.
 *   - getTreasuryBalance(): Returns the current balance of the DAO treasury.
 *
 * **Role-Based Access Control:**
 *   - assignRole(address _member, Role _role): Admin function to assign a role to a member.
 *   - revokeRole(address _member, Role _role): Admin function to revoke a role from a member.
 *   - hasRole(address _member, Role _role): Checks if a member has a specific role.
 *
 * **Timed Actions (Example - can be expanded):**
 *   - scheduleAction(uint256 _timestamp, ActionType _actionType, bytes memory _actionData): Allows governance to schedule actions to be executed at a future timestamp.
 *   - executeScheduledAction(uint256 _actionId): Internal function to execute scheduled actions when the timestamp is reached.
 *
 * **Emergency and Utility Functions:**
 *   - pauseDAO(): Admin function to pause critical DAO functionalities.
 *   - unpauseDAO(): Admin function to unpause DAO functionalities.
 *   - getDAOStatus(): Returns the current status of the DAO (paused/active).
 *   - getDAOMetrics(): Returns basic metrics about the DAO (member count, proposal count, etc.).
 */
pragma solidity ^0.8.0;

contract DynamicGovernanceDAO {
    // -------- Enums and Structs --------

    enum ProposalType {
        PARAMETER_CHANGE,
        TREASURY_SPENDING,
        ROLE_ASSIGNMENT,
        CUSTOM_FUNCTION // Example: Could be used to execute contract calls, etc.
    }

    enum VoteOption {
        ABSTAIN,
        FOR,
        AGAINST
    }

    enum ProposalStatus {
        PENDING,
        ACTIVE,
        PASSED,
        REJECTED,
        CANCELLED,
        CHALLENGED,
        DISPUTE_RESOLVED
    }

    enum DisputeResolution {
        UPHOLD_PROPOSAL,
        REJECT_PROPOSAL,
        AMEND_PROPOSAL // Could be expanded for more complex resolutions
    }

    enum Role {
        ADMIN,
        TREASURY_MANAGER,
        REPUTATION_MANAGER // Example roles - can be extended
    }

    enum ActionType {
        PARAMETER_UPDATE,
        TREASURY_TRANSFER,
        ROLE_CHANGE,
        CUSTOM_ACTION // For more complex scheduled operations
    }

    struct Proposal {
        uint256 id;
        string title;
        string description;
        ProposalType proposalType;
        bytes proposalData; // Encoded data specific to the proposal type
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        ProposalStatus status;
        address[] voters; // List of addresses that have voted to prevent double voting
        address challenger; // Address that challenged the proposal (if challenged)
        DisputeResolution disputeResolution; // Resolution of the dispute (if challenged)
    }

    struct ScheduledAction {
        uint256 id;
        uint256 timestamp;
        ActionType actionType;
        bytes actionData;
        bool executed;
    }

    struct Member {
        address memberAddress;
        uint256 reputation;
        Role[] roles;
        address delegate; // Address of the delegate for voting
    }

    // -------- State Variables --------

    address public owner;
    mapping(address => Member) public members;
    address[] public memberList;
    uint256 public nextMemberId = 1; // Simple sequential member ID (can be replaced with address if needed)
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId = 1;
    uint256 public votingPeriod = 7 days; // Default voting period
    uint256 public quorumThresholdPercentage = 50; // Default quorum percentage (e.g., 50% of members must vote)
    mapping(uint256 => ScheduledAction) public scheduledActions;
    uint256 public nextActionId = 1;
    bool public paused = false;
    uint256 public totalReputation = 0; // Track total reputation in the system

    // -------- Events --------

    event MembershipRequested(address indexed memberAddress);
    event MembershipApproved(address indexed memberAddress);
    event MemberRemoved(address indexed memberAddress);
    event ReputationAwarded(address indexed memberAddress, uint256 amount);
    event ReputationPenalized(address indexed memberAddress, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, ProposalType proposalType, address proposer);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, VoteOption vote);
    event ProposalExecuted(uint256 indexed proposalId, ProposalStatus status);
    event ProposalCancelled(uint256 indexed proposalId);
    event ProposalChallenged(uint256 indexed proposalId, address challenger);
    event DisputeResolved(uint256 indexed proposalId, DisputeResolution resolution);
    event VotingPeriodUpdated(uint256 newPeriod);
    event QuorumThresholdUpdated(uint256 newThreshold);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event VoteDelegationRevoked(address indexed delegator);
    event ActionScheduled(uint256 indexed actionId, ActionType actionType, uint256 timestamp);
    event ActionExecuted(uint256 indexed actionId, ActionType actionType);
    event DAOPaused();
    event DAOUnpaused();

    // -------- Modifiers --------

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isMember(msg.sender), "Only members can call this function.");
        _;
    }

    modifier onlyRole(Role _role) {
        require(hasRole(msg.sender, _role), "Member does not have the required role.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.ACTIVE, "Proposal is not active.");
        _;
    }

    modifier proposalPending(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.PENDING, "Proposal is not pending.");
        _;
    }

    modifier notPaused() {
        require(!paused, "DAO is currently paused.");
        _;
    }

    // -------- Constructor --------

    constructor() {
        owner = msg.sender;
    }

    // -------- Membership Management --------

    function joinDAO() external notPaused {
        require(!isMember(msg.sender), "Already a member.");
        // In a real DAO, you might have a more complex membership request process (e.g., proposal, voting).
        // For this example, we'll keep it simple with admin approval.
        emit MembershipRequested(msg.sender);
    }

    function approveMembership(address _member) external onlyOwner notPaused {
        require(!isMember(_member), "Address is already a member.");
        members[_member] = Member({
            memberAddress: _member,
            reputation: 0, // Start with zero reputation
            roles: new Role[](0),
            delegate: address(0) // No delegation initially
        });
        memberList.push(_member);
        emit MembershipApproved(_member);
    }

    function removeMember(address _member) external onlyOwner notPaused {
        require(isMember(_member), "Address is not a member.");
        delete members[_member];
        // Remove from memberList (more efficient way might be to track indices if order matters less)
        for (uint i = 0; i < memberList.length; i++) {
            if (memberList[i] == _member) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        emit MemberRemoved(_member);
    }

    function getMemberList() external view returns (address[] memory) {
        return memberList;
    }

    function isMember(address _user) public view returns (bool) {
        return members[_user].memberAddress != address(0);
    }

    // -------- Reputation System --------

    function awardReputation(address _member, uint256 _amount) external onlyOwner notPaused {
        require(isMember(_member), "Address is not a member.");
        members[_member].reputation += _amount;
        totalReputation += _amount;
        emit ReputationAwarded(_member, _amount);
    }

    function penalizeReputation(address _member, uint256 _amount) external onlyOwner notPaused {
        require(isMember(_member), "Address is not a member.");
        require(members[_member].reputation >= _amount, "Cannot penalize more reputation than member has.");
        members[_member].reputation -= _amount;
        totalReputation -= _amount;
        emit ReputationPenalized(_member, _amount);
    }

    function getMemberReputation(address _member) external view returns (uint256) {
        require(isMember(_member), "Address is not a member.");
        return members[_member].reputation;
    }

    // -------- Governance and Proposals --------

    function createProposal(
        string memory _title,
        string memory _description,
        ProposalType _proposalType,
        bytes memory _proposalData
    ) external onlyMember notPaused {
        Proposal storage newProposal = proposals[nextProposalId];
        newProposal.id = nextProposalId;
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.proposalType = _proposalType;
        newProposal.proposalData = _proposalData;
        newProposal.proposer = msg.sender;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + votingPeriod;
        newProposal.status = ProposalStatus.ACTIVE;

        emit ProposalCreated(nextProposalId, _proposalType, msg.sender);
        nextProposalId++;
    }

    function voteOnProposal(uint256 _proposalId, VoteOption _vote) external onlyMember proposalActive(_proposalId) notPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(!hasVoted(proposal, msg.sender), "Member has already voted on this proposal.");

        proposal.voters.push(msg.sender); // Record that voter has voted

        if (_vote == VoteOption.FOR) {
            proposal.forVotes += getVotingPower(msg.sender);
        } else if (_vote == VoteOption.AGAINST) {
            proposal.againstVotes += getVotingPower(msg.sender);
        } else if (_vote == VoteOption.ABSTAIN) {
            proposal.abstainVotes += getVotingPower(msg.sender);
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint256 _proposalId) external notPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.ACTIVE, "Proposal is not active.");
        require(block.timestamp >= proposal.endTime, "Voting period is not over.");

        uint256 totalVotes = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
        uint256 quorumThreshold = (memberList.length * quorumThresholdPercentage) / 100; // Calculate quorum based on percentage of members

        require(totalVotes >= quorumThreshold, "Quorum not reached."); // Quorum requirement

        if (proposal.forVotes > proposal.againstVotes) {
            proposal.status = ProposalStatus.PASSED;
            _executeAction(proposal); // Internal function to execute the proposal action
            emit ProposalExecuted(_proposalId, ProposalStatus.PASSED);
        } else {
            proposal.status = ProposalStatus.REJECTED;
            emit ProposalExecuted(_proposalId, ProposalStatus.REJECTED);
        }
    }

    function cancelProposal(uint256 _proposalId) external notPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer == msg.sender || msg.sender == owner, "Only proposer or owner can cancel proposal.");
        require(proposal.status == ProposalStatus.ACTIVE, "Proposal is not active.");
        require(block.timestamp < proposal.endTime, "Voting period is already over."); // Can only cancel before voting ends

        proposal.status = ProposalStatus.CANCELLED;
        emit ProposalCancelled(_proposalId);
    }

    function challengeProposal(uint256 _proposalId) external onlyMember proposalActive(_proposalId) notPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.challenger == address(0), "Proposal already challenged."); // Only challenge once

        proposal.status = ProposalStatus.CHALLENGED;
        proposal.challenger = msg.sender;
        emit ProposalChallenged(_proposalId, msg.sender);
    }

    function resolveDispute(uint256 _proposalId, DisputeResolution _resolution) external onlyOwner notPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.CHALLENGED, "Proposal is not challenged.");

        proposal.disputeResolution = _resolution;
        proposal.status = ProposalStatus.DISPUTE_RESOLVED;

        if (_resolution == DisputeResolution.UPHOLD_PROPOSAL) {
            _executeAction(proposal); // Execute if dispute uphelds the proposal
            emit ProposalExecuted(_proposalId, ProposalStatus.PASSED); // Consider status as passed after dispute upheld
        } else if (_resolution == DisputeResolution.REJECT_PROPOSAL) {
            proposal.status = ProposalStatus.REJECTED;
            emit ProposalExecuted(_proposalId, ProposalStatus.REJECTED); // Consider status as rejected after dispute rejected
        } else if (_resolution == DisputeResolution.AMEND_PROPOSAL) {
            // Logic for amending proposal - could involve resetting votes, re-activating proposal, etc.
            // This is a more complex feature and can be expanded.
            proposal.status = ProposalStatus.PENDING; // Example - set to pending for further action
            emit DisputeResolved(_proposalId, _resolution);
            // Further actions for amendment would be needed
        } else {
            emit DisputeResolved(_proposalId, _resolution);
        }
    }

    function getProposalDetails(uint256 _proposalId) external view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function getActiveProposals() external view returns (uint256[] memory) {
        uint256[] memory activeProposalIds = new uint256[](nextProposalId - 1);
        uint256 count = 0;
        for (uint256 i = 1; i < nextProposalId; i++) {
            if (proposals[i].status == ProposalStatus.ACTIVE) {
                activeProposalIds[count] = i;
                count++;
            }
        }
        // Resize array to actual count of active proposals
        assembly { // Assembly for efficient array resizing
            mstore(activeProposalIds, count)
        }
        return activeProposalIds;
    }

    function getPastProposals() external view returns (uint256[] memory) {
        uint256[] memory pastProposalIds = new uint256[](nextProposalId - 1);
        uint256 count = 0;
        for (uint256 i = 1; i < nextProposalId; i++) {
            if (proposals[i].status != ProposalStatus.ACTIVE && proposals[i].status != ProposalStatus.PENDING) { // Get all non-active/pending proposals
                pastProposalIds[count] = i;
                count++;
            }
        }
        // Resize array to actual count of past proposals
        assembly { // Assembly for efficient array resizing
            mstore(pastProposalIds, count)
        }
        return pastProposalIds;
    }

    function setVotingPeriod(uint256 _newPeriod) external onlyOwner notPaused {
        votingPeriod = _newPeriod;
        emit VotingPeriodUpdated(_newPeriod);
    }

    function setQuorumThreshold(uint256 _newThreshold) external onlyOwner notPaused {
        require(_newThreshold <= 100, "Quorum threshold cannot be more than 100%.");
        quorumThresholdPercentage = _newThreshold;
        emit QuorumThresholdUpdated(_newThreshold);
    }

    function delegateVote(address _delegatee) external onlyMember notPaused {
        require(isMember(_delegatee), "Delegatee must be a member.");
        require(_delegatee != msg.sender, "Cannot delegate vote to yourself.");
        members[msg.sender].delegate = _delegatee;
        emit VoteDelegated(msg.sender, _delegatee);
    }

    function revokeDelegation() external onlyMember notPaused {
        members[msg.sender].delegate = address(0);
        emit VoteDelegationRevoked(msg.sender);
    }

    // -------- Treasury Management (Example) --------

    function depositToTreasury() external payable notPaused {
        // Funds are directly sent to the contract address.
        // In a more complex DAO, you might have a separate treasury contract.
    }

    function createTreasuryWithdrawalProposal(address _recipient, uint256 _amount, string memory _reason) external onlyMember notPaused {
        // Encode proposal data for treasury withdrawal
        bytes memory proposalData = abi.encode(_recipient, _amount, _reason);
        createProposal("Treasury Withdrawal", _reason, ProposalType.TREASURY_SPENDING, proposalData);
    }

    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // -------- Role-Based Access Control --------

    function assignRole(address _member, Role _role) external onlyOwner notPaused {
        require(isMember(_member), "Address is not a member.");
        bool roleExists = false;
        for (uint i = 0; i < members[_member].roles.length; i++) {
            if (members[_member].roles[i] == _role) {
                roleExists = true;
                break;
            }
        }
        require(!roleExists, "Member already has this role.");
        members[_member].roles.push(_role);
        emit RoleAssigned(_member, _role); // Assuming you add RoleAssigned event
    }

    event RoleAssigned(address indexed memberAddress, Role role);
    event RoleRevoked(address indexed memberAddress, Role role);

    function revokeRole(address _member, Role _role) external onlyOwner notPaused {
        require(isMember(_member), "Address is not a member.");
        bool roleFound = false;
        for (uint i = 0; i < members[_member].roles.length; i++) {
            if (members[_member].roles[i] == _role) {
                members[_member].roles[i] = members[_member].roles[members[_member].roles.length - 1];
                members[_member].roles.pop();
                roleFound = true;
                break;
            }
        }
        require(roleFound, "Role not found for member.");
        emit RoleRevoked(_member, _role);
    }

    function hasRole(address _member, Role _role) public view returns (bool) {
        if (!isMember(_member)) return false; // Non-members have no roles
        for (uint i = 0; i < members[_member].roles.length; i++) {
            if (members[_member].roles[i] == _role) {
                return true;
            }
        }
        return false;
    }

    // -------- Timed Actions (Example) --------

    function scheduleAction(uint256 _timestamp, ActionType _actionType, bytes memory _actionData) external onlyRole(Role.ADMIN) notPaused {
        require(_timestamp > block.timestamp, "Timestamp must be in the future.");
        scheduledActions[nextActionId] = ScheduledAction({
            id: nextActionId,
            timestamp: _timestamp,
            actionType: _actionType,
            actionData: _actionData,
            executed: false
        });
        emit ActionScheduled(nextActionId, _actionType, _timestamp);
        nextActionId++;
    }

    function executeScheduledActions() external notPaused {
        for (uint256 i = 1; i < nextActionId; i++) {
            if (!scheduledActions[i].executed && block.timestamp >= scheduledActions[i].timestamp) {
                _executeScheduledAction(scheduledActions[i]);
                scheduledActions[i].executed = true;
                emit ActionExecuted(i, scheduledActions[i].actionType);
            }
        }
    }

    // -------- Emergency and Utility Functions --------

    function pauseDAO() external onlyOwner {
        paused = true;
        emit DAOPaused();
    }

    function unpauseDAO() external onlyOwner {
        paused = false;
        emit DAOUnpaused();
    }

    function getDAOStatus() external view returns (bool) {
        return paused;
    }

    function getDAOMetrics() external view returns (uint256 memberCount, uint256 proposalCount, uint256 treasuryBalance, uint256 totalSystemReputation) {
        return (memberList.length, nextProposalId - 1, address(this).balance, totalReputation);
    }

    // -------- Internal Helper Functions --------

    function _executeAction(Proposal storage proposal) internal {
        if (proposal.proposalType == ProposalType.PARAMETER_CHANGE) {
            // Example: Assuming proposalData is encoded for parameter change (e.g., new voting period)
            (uint256 newVotingPeriod) = abi.decode(proposal.proposalData, (uint256));
            setVotingPeriod(newVotingPeriod); // Call function to update parameter
        } else if (proposal.proposalType == ProposalType.TREASURY_SPENDING) {
            (address recipient, uint256 amount, ) = abi.decode(proposal.proposalData, (address, uint256, string)); // Decode recipient and amount
            payable(recipient).transfer(amount); // Transfer funds - be careful with security in real implementations
        } else if (proposal.proposalType == ProposalType.ROLE_ASSIGNMENT) {
            (address memberToAssign, Role roleToAssign) = abi.decode(proposal.proposalData, (address, Role));
            assignRole(memberToAssign, roleToAssign); // Assign role based on proposal
        } else if (proposal.proposalType == ProposalType.CUSTOM_FUNCTION) {
            // Example:  Proposal data could be function signature and arguments to call another contract
            // This requires careful security considerations and input validation.
            // In a real-world scenario, you'd need a more robust and secure way to handle custom function calls.
            // For simplicity, we'll leave this as a placeholder.
            // (bytes memory functionSignature, bytes memory functionArgs) = abi.decode(proposal.proposalData, (bytes, bytes));
            // // ... Logic to call another contract or perform custom action based on functionSignature and functionArgs
        }
        // Add more proposal type execution logic here as needed.
    }

    function _executeScheduledAction(ScheduledAction storage action) internal {
        if (action.actionType == ActionType.PARAMETER_UPDATE) {
            (uint256 newVotingPeriod) = abi.decode(action.actionData, (uint256));
            setVotingPeriod(newVotingPeriod); // Example: Update voting period
        } else if (action.actionType == ActionType.TREASURY_TRANSFER) {
            (address recipient, uint256 amount) = abi.decode(action.actionData, (address, uint256));
            payable(recipient).transfer(amount); // Example: Transfer funds
        } else if (action.actionType == ActionType.ROLE_CHANGE) {
            (address memberAddress, Role roleToAssign, bool assign) = abi.decode(action.actionData, (address, Role, bool));
            if (assign) {
                assignRole(memberAddress, roleToAssign);
            } else {
                revokeRole(memberAddress, roleToAssign);
            }
        } else if (action.actionType == ActionType.CUSTOM_ACTION) {
            // Placeholder for custom scheduled actions - needs more robust implementation in real world
            // Could involve calling other contracts, complex state updates, etc.
            // (bytes memory customActionData) = abi.decode(action.actionData, (bytes));
            // // ... Logic to perform custom action based on customActionData
        }
        // Add more scheduled action type execution logic here.
    }

    function getVotingPower(address _voter) internal view returns (uint256) {
        if (members[_voter].delegate != address(0)) {
            return getVotingPower(members[_voter].delegate); // Recursive delegation
        } else {
            return members[_voter].reputation + 1; // Voting power is reputation + base power of 1
        }
    }

    function hasVoted(Proposal storage _proposal, address _voter) internal view returns (bool) {
        for (uint i = 0; i < _proposal.voters.length; i++) {
            if (_proposal.voters[i] == _voter) {
                return true;
            }
        }
        return false;
    }
}
```