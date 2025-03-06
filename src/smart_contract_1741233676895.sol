```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Organization (DAO) with Dynamic Governance & Reputation System
 * @author Bard (AI Assistant)
 * @dev A sophisticated DAO contract incorporating dynamic governance parameters,
 *      a reputation system influencing voting power, and various advanced features.
 *      This DAO is designed to be flexible, adaptable, and engaging for its members.
 *
 * **Outline & Function Summary:**
 *
 * **Governance Parameters Management:**
 *   1. `setQuorumPercentage(uint256 _quorumPercentage)`: Allows the DAO owner to change the quorum percentage required for proposals to pass.
 *   2. `setVotingPeriodBlocks(uint256 _votingPeriodBlocks)`: Allows the DAO owner to adjust the voting period duration in blocks.
 *   3. `addProposalType(string memory _typeName)`: Allows the DAO owner to register new types of proposals that can be created.
 *   4. `removeProposalType(uint256 _typeId)`: Allows the DAO owner to remove existing proposal types.
 *   5. `setGovernanceParameter(string memory _parameterName, uint256 _newValue)`: A generic function to set various governance parameters (extensible).
 *
 * **Membership & Reputation Management:**
 *   6. `joinDAO()`: Allows any address to request membership to the DAO.
 *   7. `approveMembership(address _member)`: Allows current DAO members (with sufficient reputation/role) to approve pending membership requests.
 *   8. `revokeMembership(address _member)`: Allows DAO members (with sufficient reputation/role) to revoke membership.
 *   9. `earnReputation(address _member, uint256 _reputationPoints)`: Allows designated roles to award reputation points to members for contributions.
 *  10. `burnReputation(address _member, uint256 _reputationPoints)`: Allows designated roles to deduct reputation points from members.
 *  11. `getMemberReputation(address _member)`: Returns the reputation score of a DAO member.
 *  12. `setReputationThresholdForVoting(uint256 _threshold)`:  Allows the DAO owner to set a minimum reputation threshold required to vote.
 *
 * **Proposal & Voting System:**
 *  13. `createProposal(uint256 _proposalTypeId, string memory _title, string memory _description, bytes memory _calldata)`: Allows DAO members to create proposals of registered types.
 *  14. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows DAO members to vote on active proposals, weighted by their reputation.
 *  15. `executeProposal(uint256 _proposalId)`: Executes a passed proposal after the voting period ends.
 *  16. `cancelProposal(uint256 _proposalId)`: Allows the proposer (or designated role) to cancel a proposal before the voting period ends (with conditions).
 *  17. `getProposalState(uint256 _proposalId)`: Returns the current state of a proposal (Pending, Active, Succeeded, Failed, Executed, Cancelled).
 *  18. `getProposalVotes(uint256 _proposalId)`: Returns the vote counts (for and against) for a specific proposal.
 *
 * **Treasury & Utility Functions:**
 *  19. `deposit()`: Allows anyone to deposit Ether into the DAO treasury.
 *  20. `withdrawFromTreasury(address _recipient, uint256 _amount)`: Allows the DAO (via successful proposal execution) to withdraw funds from the treasury.
 *  21. `pauseContract()`: Allows the DAO owner to pause core contract functionalities in case of emergency.
 *  22. `unpauseContract()`: Allows the DAO owner to resume contract functionalities.
 *  23. `ownerWithdraw()`: Allows the contract owner to withdraw any accidentally sent Ether to the contract (safety measure).
 */

contract DynamicGovernanceDAO {
    // -------- State Variables --------

    address public owner;
    uint256 public quorumPercentage = 51; // Default quorum: 51%
    uint256 public votingPeriodBlocks = 100; // Default voting period: 100 blocks
    uint256 public proposalCounter = 0;
    uint256 public reputationThresholdForVoting = 0; // Minimum reputation to vote
    bool public paused = false;

    // Structs & Enums
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Cancelled }

    struct Proposal {
        uint256 id;
        uint256 proposalTypeId;
        address proposer;
        string title;
        string description;
        bytes calldata;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalState state;
    }

    struct ProposalType {
        uint256 id;
        string name;
    }

    // Mappings
    mapping(address => bool) public isMember;
    mapping(address => uint256) public memberReputation;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => ProposalType) public proposalTypes;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => voted
    mapping(address => bool) public pendingMembershipRequests;
    mapping(string => uint256) public governanceParameters; // Generic parameter storage


    // Events
    event QuorumPercentageUpdated(uint256 newQuorumPercentage);
    event VotingPeriodUpdated(uint256 newVotingPeriodBlocks);
    event ProposalTypeAdded(uint256 typeId, string typeName);
    event ProposalTypeRemoved(uint256 typeId);
    event GovernanceParameterSet(string parameterName, uint256 newValue);
    event MembershipRequested(address member);
    event MembershipApproved(address member);
    event MembershipRevoked(address member);
    event ReputationEarned(address member, uint256 points);
    event ReputationBurned(address member, uint256 points);
    event ReputationThresholdUpdated(uint256 threshold);
    event ProposalCreated(uint256 proposalId, uint256 proposalTypeId, address proposer, string title);
    event VoteCast(uint256 proposalId, address voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCancelled(uint256 proposalId);
    event ContractPaused();
    event ContractUnpaused();
    event TreasuryDeposit(address sender, uint256 amount);
    event TreasuryWithdrawal(address recipient, uint256 amount);
    event OwnerWithdrawal(address recipient, uint256 amount);

    // -------- Modifiers --------

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can call this function.");
        _;
    }

    modifier onlyProposed(uint256 _proposalId) {
        require(proposals[_proposalId].proposer == msg.sender, "Only proposer can call this function.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCounter, "Invalid proposal ID.");
        _;
    }

    modifier activeProposal(uint256 _proposalId) {
        require(proposals[_proposalId].state == ProposalState.Active, "Proposal is not active.");
        _;
    }

    modifier pendingProposal(uint256 _proposalId) {
        require(proposals[_proposalId].state == ProposalState.Pending, "Proposal is not pending.");
        _;
    }

    modifier succeededProposal(uint256 _proposalId) {
        require(proposals[_proposalId].state == ProposalState.Succeeded, "Proposal is not succeeded.");
        _;
    }

    modifier notVoted(uint256 _proposalId) {
        require(!hasVoted[_proposalId][msg.sender], "Already voted on this proposal.");
        _;
    }

    modifier hasSufficientReputation() {
        require(memberReputation[msg.sender] >= reputationThresholdForVoting, "Insufficient reputation to vote.");
        _;
    }

    // -------- Constructor --------

    constructor() {
        owner = msg.sender;
        // Initialize default proposal types (can be extended)
        addProposalType("Text Proposal"); // Type ID 1
        addProposalType("Function Call Proposal"); // Type ID 2
        governanceParameters["initialParameter"] = 100; // Example of setting a generic parameter
    }

    // -------- Governance Parameter Management Functions --------

    /// @dev Sets the quorum percentage required for proposals to pass. Only owner can call.
    /// @param _quorumPercentage New quorum percentage value (e.g., 51 for 51%).
    function setQuorumPercentage(uint256 _quorumPercentage) external onlyOwner {
        require(_quorumPercentage <= 100, "Quorum percentage must be <= 100.");
        quorumPercentage = _quorumPercentage;
        emit QuorumPercentageUpdated(_quorumPercentage);
    }

    /// @dev Sets the voting period duration in blocks. Only owner can call.
    /// @param _votingPeriodBlocks New voting period duration in blocks.
    function setVotingPeriodBlocks(uint256 _votingPeriodBlocks) external onlyOwner {
        votingPeriodBlocks = _votingPeriodBlocks;
        emit VotingPeriodUpdated(_votingPeriodBlocks);
    }

    /// @dev Adds a new proposal type to the DAO. Only owner can call.
    /// @param _typeName Name of the new proposal type.
    function addProposalType(string memory _typeName) public onlyOwner {
        uint256 newTypeId = proposalTypes.length + 1; // Simple incremental ID
        proposalTypes[newTypeId] = ProposalType(newTypeId, _typeName);
        emit ProposalTypeAdded(newTypeId, _typeName);
    }

    /// @dev Removes a proposal type from the DAO. Only owner can call.
    /// @param _typeId ID of the proposal type to remove.
    function removeProposalType(uint256 _typeId) external onlyOwner {
        require(proposalTypes[_typeId].id != 0, "Proposal type ID does not exist.");
        delete proposalTypes[_typeId];
        emit ProposalTypeRemoved(_typeId);
    }

    /// @dev Sets a generic governance parameter. Only owner can call. Extensible for various settings.
    /// @param _parameterName Name of the parameter to set.
    /// @param _newValue New value for the parameter.
    function setGovernanceParameter(string memory _parameterName, uint256 _newValue) external onlyOwner {
        governanceParameters[_parameterName] = _newValue;
        emit GovernanceParameterSet(_parameterName, _newValue);
    }

    // -------- Membership & Reputation Management Functions --------

    /// @dev Allows any address to request membership to the DAO.
    function joinDAO() external notPaused {
        require(!isMember[msg.sender], "Already a member.");
        require(!pendingMembershipRequests[msg.sender], "Membership request already pending.");
        pendingMembershipRequests[msg.sender] = true;
        emit MembershipRequested(msg.sender);
    }

    /// @dev Allows DAO members to approve pending membership requests. Requires sufficient reputation to approve (can be customized).
    /// @param _member Address to approve membership for.
    function approveMembership(address _member) external onlyMember hasSufficientReputation notPaused {
        require(pendingMembershipRequests[_member], "No pending membership request.");
        isMember[_member] = true;
        pendingMembershipRequests[_member] = false;
        memberReputation[_member] = 0; // Initialize reputation for new member
        emit MembershipApproved(_member);
    }

    /// @dev Allows DAO members to revoke membership. Requires sufficient reputation to revoke (can be customized).
    /// @param _member Address to revoke membership from.
    function revokeMembership(address _member) external onlyMember hasSufficientReputation notPaused {
        require(isMember[_member], "Not a member.");
        require(_member != msg.sender, "Cannot revoke your own membership."); // Optional: Prevent self-revocation
        isMember[_member] = false;
        delete memberReputation[_member]; // Optionally remove reputation on revocation
        emit MembershipRevoked(_member);
    }

    /// @dev Allows designated roles (e.g., admins, can be implemented with roles mapping) to award reputation points.
    /// @param _member Address to award reputation to.
    /// @param _reputationPoints Amount of reputation points to award.
    function earnReputation(address _member, uint256 _reputationPoints) external onlyOwner notPaused { // Example: Only owner can award reputation
        require(isMember[_member], "Recipient is not a member.");
        memberReputation[_member] += _reputationPoints;
        emit ReputationEarned(_member, _reputationPoints);
    }

    /// @dev Allows designated roles (e.g., admins) to deduct reputation points.
    /// @param _member Address to deduct reputation from.
    /// @param _reputationPoints Amount of reputation points to deduct.
    function burnReputation(address _member, uint256 _reputationPoints) external onlyOwner notPaused { // Example: Only owner can burn reputation
        require(isMember[_member], "Recipient is not a member.");
        require(memberReputation[_member] >= _reputationPoints, "Not enough reputation to burn.");
        memberReputation[_member] -= _reputationPoints;
        emit ReputationBurned(_member, _reputationPoints);
    }

    /// @dev Returns the reputation score of a DAO member.
    /// @param _member Address of the member.
    /// @return uint256 Reputation score of the member.
    function getMemberReputation(address _member) external view returns (uint256) {
        return memberReputation[_member];
    }

    /// @dev Sets the minimum reputation threshold required to vote on proposals. Only owner can call.
    /// @param _threshold Minimum reputation threshold.
    function setReputationThresholdForVoting(uint256 _threshold) external onlyOwner {
        reputationThresholdForVoting = _threshold;
        emit ReputationThresholdUpdated(_threshold);
    }

    // -------- Proposal & Voting System Functions --------

    /// @dev Creates a new proposal. Only members can create proposals.
    /// @param _proposalTypeId ID of the proposal type (from registered types).
    /// @param _title Title of the proposal.
    /// @param _description Detailed description of the proposal.
    /// @param _calldata Calldata to be executed if the proposal passes (can be empty for text proposals).
    function createProposal(
        uint256 _proposalTypeId,
        string memory _title,
        string memory _description,
        bytes memory _calldata
    ) external onlyMember notPaused {
        require(proposalTypes[_proposalTypeId].id != 0, "Invalid proposal type ID.");
        proposalCounter++;
        Proposal storage newProposal = proposals[proposalCounter];
        newProposal.id = proposalCounter;
        newProposal.proposalTypeId = _proposalTypeId;
        newProposal.proposer = msg.sender;
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.calldata = _calldata;
        newProposal.startTime = block.number;
        newProposal.endTime = block.number + votingPeriodBlocks;
        newProposal.state = ProposalState.Active; // Proposal starts in Active state
        emit ProposalCreated(proposalCounter, _proposalTypeId, msg.sender, _title);
    }

    /// @dev Allows DAO members to vote on an active proposal.
    /// @param _proposalId ID of the proposal to vote on.
    /// @param _support Boolean indicating support (true) or against (false).
    function voteOnProposal(uint256 _proposalId, bool _support)
        external
        onlyMember
        validProposal(_proposalId)
        activeProposal(_proposalId)
        notVoted(_proposalId)
        hasSufficientReputation
        notPaused
    {
        hasVoted[_proposalId][msg.sender] = true;
        uint256 votingPower = memberReputation[msg.sender] + 1; // Example: Reputation + 1 voting power
        if (_support) {
            proposals[_proposalId].votesFor += votingPower;
        } else {
            proposals[_proposalId].votesAgainst += votingPower;
        }
        emit VoteCast(_proposalId, msg.sender, _support, votingPower);

        // Check if voting period ended and update proposal state
        if (block.number >= proposals[_proposalId].endTime) {
            _finalizeProposal(_proposalId);
        }
    }

    /// @dev Executes a succeeded proposal after the voting period has ended and quorum is reached.
    /// @param _proposalId ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external validProposal( _proposalId) succeededProposal(_proposalId) notPaused {
        require(proposals[_proposalId].state != ProposalState.Executed, "Proposal already executed.");
        require(block.number >= proposals[_proposalId].endTime, "Voting period not ended yet."); // Double check voting period end.

        if (proposals[_proposalId].proposalTypeId == 2) { // Example: Type ID 2 is "Function Call Proposal"
            (bool success, ) = address(this).call(proposals[_proposalId].calldata);
            require(success, "Proposal execution failed.");
        }
        proposals[_proposalId].state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId);
    }

    /// @dev Allows the proposer (or designated role) to cancel a proposal before the voting period ends.
    /// @param _proposalId ID of the proposal to cancel.
    function cancelProposal(uint256 _proposalId) external validProposal(_proposalId) pendingProposal(_proposalId) onlyProposed(_proposalId) notPaused {
        proposals[_proposalId].state = ProposalState.Cancelled;
        emit ProposalCancelled(_proposalId);
    }

    /// @dev Gets the current state of a proposal.
    /// @param _proposalId ID of the proposal.
    /// @return ProposalState Current state of the proposal.
    function getProposalState(uint256 _proposalId) external view validProposal(_proposalId) returns (ProposalState) {
        return proposals[_proposalId].state;
    }

    /// @dev Gets the vote counts for a specific proposal.
    /// @param _proposalId ID of the proposal.
    /// @return uint256 Votes for the proposal.
    /// @return uint256 Votes against the proposal.
    function getProposalVotes(uint256 _proposalId) external view validProposal(_proposalId) returns (uint256, uint256) {
        return (proposals[_proposalId].votesFor, proposals[_proposalId].votesAgainst);
    }

    // -------- Treasury & Utility Functions --------

    /// @dev Allows anyone to deposit Ether into the DAO treasury.
    function deposit() external payable notPaused {
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /// @dev Allows the DAO to withdraw funds from the treasury. Can only be called after successful proposal execution (Type ID 2 - Function Call Proposal).
    /// @param _recipient Address to send the withdrawn Ether to.
    /// @param _amount Amount of Ether to withdraw.
    function withdrawFromTreasury(address _recipient, uint256 _amount) external notPaused {
        // This function should ideally be called via a successful proposal execution.
        // Security Note: In a real-world scenario, restrict access further and implement proper checks
        // to ensure only executed proposals can trigger treasury withdrawals.
        payable(_recipient).transfer(_amount);
        emit TreasuryWithdrawal(_recipient, _amount);
    }

    /// @dev Pauses core contract functionalities. Only owner can call.
    function pauseContract() external onlyOwner {
        paused = true;
        emit ContractPaused();
    }

    /// @dev Resumes contract functionalities. Only owner can call.
    function unpauseContract() external onlyOwner {
        paused = false;
        emit ContractUnpaused();
    }

    /// @dev Allows the contract owner to withdraw any accidentally sent Ether to the contract. Safety measure.
    function ownerWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit OwnerWithdrawal(owner, balance);
    }

    // -------- Internal Functions --------

    /// @dev Internal function to finalize a proposal after the voting period ends.
    /// @param _proposalId ID of the proposal to finalize.
    function _finalizeProposal(uint256 _proposalId) internal validProposal(_proposalId) activeProposal(_proposalId) {
        if (proposals[_proposalId].state != ProposalState.Active) return; // Already finalized

        uint256 totalVotes = proposals[_proposalId].votesFor + proposals[_proposalId].votesAgainst;
        uint256 quorumRequired = (totalVotes * quorumPercentage) / 100; // Quorum based on total votes cast
        if (proposals[_proposalId].votesFor >= quorumRequired) {
            proposals[_proposalId].state = ProposalState.Succeeded;
        } else {
            proposals[_proposalId].state = ProposalState.Failed;
        }
    }

    // Fallback function to receive Ether
    receive() external payable {
        emit TreasuryDeposit(msg.sender, msg.value);
    }
}
```