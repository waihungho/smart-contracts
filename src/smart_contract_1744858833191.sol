```solidity
/**
 * @title Dynamic Governance & Asset Management DAO
 * @author Bard (AI Assistant)
 * @dev A Decentralized Autonomous Organization (DAO) contract with dynamic governance,
 *      reputation system, and advanced asset management capabilities.
 *
 * **Outline and Function Summary:**
 *
 * **1.  Membership Management:**
 *     - `joinDAO()`: Allows users to request membership, potentially requiring a deposit or approval.
 *     - `approveMembership(address _member)`: Admin/Council function to approve pending membership requests.
 *     - `revokeMembership(address _member)`: Admin/Council function to revoke membership, potentially with asset transfer or penalty.
 *     - `isMember(address _user)`: Public view function to check if an address is a member.
 *     - `getMemberCount()`: Public view function to retrieve the current number of members.
 *
 * **2.  Governance & Voting:**
 *     - `submitProposal(string memory _description, ProposalType _proposalType, bytes memory _data)`: Members propose actions with descriptions and data.
 *     - `voteOnProposal(uint256 _proposalId, VoteOption _vote)`: Members cast votes on active proposals.
 *     - `executeProposal(uint256 _proposalId)`: Executes a proposal if it passes the voting threshold.
 *     - `cancelProposal(uint256 _proposalId)`: Allows the proposer or admin to cancel a proposal before voting ends.
 *     - `getProposalDetails(uint256 _proposalId)`: Public view function to retrieve details of a specific proposal.
 *     - `getProposalVotingStats(uint256 _proposalId)`: Public view function to get voting statistics for a proposal.
 *
 * **3.  Dynamic Governance Parameters:**
 *     - `updateVotingQuorum(uint256 _newQuorum)`: Admin/Council function to change the required quorum for proposals to pass.
 *     - `updateVotingDuration(uint256 _newDuration)`: Admin/Council function to adjust the voting duration for proposals.
 *     - `updateProposalDeposit(uint256 _newDeposit)`: Admin/Council function to modify the deposit required to submit a proposal.
 *
 * **4.  Reputation System:**
 *     - `increaseReputation(address _member, uint256 _amount)`: Admin/Council function to increase a member's reputation score.
 *     - `decreaseReputation(address _member, uint256 _amount)`: Admin/Council function to decrease a member's reputation score.
 *     - `getMemberReputation(address _member)`: Public view function to retrieve a member's reputation score.
 *     - `setMinReputationForProposal(ProposalType _proposalType, uint256 _minReputation)`: Admin/Council function to set minimum reputation required to submit certain proposal types.
 *
 * **5.  Treasury & Asset Management:**
 *     - `depositFunds()`: Allows anyone to deposit ETH into the DAO treasury.
 *     - `proposeAssetTransfer(address _recipient, address _tokenAddress, uint256 _amount)`: Members propose transferring assets (ETH or ERC20) from the treasury.
 *     - `getTreasuryBalance()`: Public view function to get the ETH balance of the DAO treasury.
 *     - `getTokenBalance(address _tokenAddress)`: Public view function to get the balance of a specific ERC20 token in the DAO treasury.
 *     - `emergencyPause()`: Admin/Council function to pause critical contract functions in case of emergency.
 *     - `emergencyUnpause()`: Admin/Council function to resume paused contract functions.
 */
pragma solidity ^0.8.0;

contract DynamicGovernanceDAO {
    // -------- State Variables --------

    address public admin; // Address of the DAO administrator
    address[] public councilMembers; // Addresses of council members with elevated permissions
    mapping(address => bool) public members; // Mapping of member addresses to boolean (true if member)
    address[] public pendingMembers; // Array of addresses requesting membership
    uint256 public memberCount; // Total number of members

    uint256 public votingQuorum = 50; // Percentage quorum required for proposals to pass (e.g., 50 means 50%)
    uint256 public votingDuration = 7 days; // Default voting duration in seconds
    uint256 public proposalDepositAmount = 1 ether; // Amount of ETH required to submit a proposal

    enum ProposalType {
        GENERIC,
        GOVERNANCE_CHANGE,
        ASSET_TRANSFER,
        CUSTOM_FUNCTION_CALL
    }

    enum VoteOption {
        AGAINST,
        FOR,
        ABSTAIN
    }

    struct Proposal {
        uint256 id;
        address proposer;
        ProposalType proposalType;
        string description;
        bytes data; // Data for execution (e.g., function call data)
        uint256 startTime;
        uint256 endTime;
        mapping(address => VoteOption) votes;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votesAbstain;
        bool executed;
        bool cancelled;
    }

    Proposal[] public proposals;
    uint256 public proposalCounter;

    mapping(address => uint256) public reputation; // Reputation score for each member
    mapping(ProposalType => uint256) public minReputationForProposalType; // Minimum reputation required for specific proposal types

    bool public paused = false; // Emergency pause state

    // -------- Events --------

    event MembershipRequested(address indexed member);
    event MembershipApproved(address indexed member);
    event MembershipRevoked(address indexed member);
    event ProposalSubmitted(uint256 proposalId, address proposer, ProposalType proposalType, string description);
    event VoteCast(uint256 proposalId, address voter, VoteOption vote);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCancelled(uint256 proposalId);
    event VotingQuorumUpdated(uint256 newQuorum);
    event VotingDurationUpdated(uint256 newDuration);
    event ProposalDepositUpdated(uint256 newDeposit);
    event ReputationIncreased(address indexed member, uint256 amount);
    event ReputationDecreased(address indexed member, uint256 amount);
    event ContractPaused();
    event ContractUnpaused();

    // -------- Modifiers --------

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier onlyCouncil() {
        bool isCouncil = false;
        for (uint256 i = 0; i < councilMembers.length; i++) {
            if (councilMembers[i] == msg.sender) {
                isCouncil = true;
                break;
            }
        }
        require(isCouncil || msg.sender == admin, "Only council members or admin can perform this action.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can perform this action.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is currently paused.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId < proposals.length, "Proposal does not exist.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(!proposals[_proposalId].executed && !proposals[_proposalId].cancelled && block.timestamp <= proposals[_proposalId].endTime, "Proposal is not active.");
        _;
    }

    modifier proposalNotCancelled(uint256 _proposalId) {
        require(!proposals[_proposalId].cancelled, "Proposal is cancelled.");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!proposals[_proposalId].executed, "Proposal is already executed.");
        _;
    }

    modifier canSubmitProposal(ProposalType _proposalType) {
        require(reputation[msg.sender] >= minReputationForProposalType[_proposalType], "Insufficient reputation to submit this proposal type.");
        _;
    }


    // -------- Constructor --------

    constructor(address[] memory _initialCouncilMembers) {
        admin = msg.sender;
        councilMembers = _initialCouncilMembers;
    }

    // -------- 1. Membership Management Functions --------

    /// @notice Allows users to request membership in the DAO.
    function joinDAO() external notPaused {
        require(!members[msg.sender], "You are already a member.");
        require(!isPendingMember(msg.sender), "Membership request already pending.");
        pendingMembers.push(msg.sender);
        emit MembershipRequested(msg.sender);
    }

    /// @notice Allows admin/council to approve a pending membership request.
    /// @param _member Address of the member to approve.
    function approveMembership(address _member) external onlyCouncil notPaused {
        require(isPendingMember(_member), "Address is not a pending member.");
        require(!members(_member), "Address is already a member.");

        for (uint256 i = 0; i < pendingMembers.length; i++) {
            if (pendingMembers[i] == _member) {
                pendingMembers[i] = pendingMembers[pendingMembers.length - 1];
                pendingMembers.pop();
                break;
            }
        }

        members[_member] = true;
        memberCount++;
        emit MembershipApproved(_member);
    }

    /// @notice Allows admin/council to revoke membership from a member.
    /// @param _member Address of the member to revoke membership from.
    function revokeMembership(address _member) external onlyCouncil notPaused {
        require(members[_member], "Address is not a member.");
        delete members[_member];
        memberCount--;
        emit MembershipRevoked(_member);
        // Consider adding logic to handle member's assets or reputation if needed.
    }

    /// @notice Checks if an address is a member of the DAO.
    /// @param _user Address to check.
    /// @return bool True if the address is a member, false otherwise.
    function isMember(address _user) public view returns (bool) {
        return members[_user];
    }

    /// @notice Gets the current number of members in the DAO.
    /// @return uint256 The number of members.
    function getMemberCount() public view returns (uint256) {
        return memberCount;
    }

    /// @notice Checks if an address is in the pending membership list.
    /// @param _user Address to check.
    /// @return bool True if the address is a pending member, false otherwise.
    function isPendingMember(address _user) public view returns (bool) {
        for (uint256 i = 0; i < pendingMembers.length; i++) {
            if (pendingMembers[i] == _user) {
                return true;
            }
        }
        return false;
    }


    // -------- 2. Governance & Voting Functions --------

    /// @notice Allows members to submit a proposal for DAO action.
    /// @param _description A brief description of the proposal.
    /// @param _proposalType Type of the proposal (e.g., GENERIC, GOVERNANCE_CHANGE).
    /// @param _data Data associated with the proposal (e.g., function call data).
    function submitProposal(
        string memory _description,
        ProposalType _proposalType,
        bytes memory _data
    ) external payable onlyMember notPaused canSubmitProposal(_proposalType) {
        require(msg.value >= proposalDepositAmount, "Insufficient proposal deposit.");

        Proposal storage newProposal = proposals.push();
        newProposal.id = proposalCounter++;
        newProposal.proposer = msg.sender;
        newProposal.proposalType = _proposalType;
        newProposal.description = _description;
        newProposal.data = _data;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + votingDuration;

        payable(address(this)).transfer(msg.value); // Transfer proposal deposit to contract

        emit ProposalSubmitted(newProposal.id, msg.sender, _proposalType, _description);
    }

    /// @notice Allows members to vote on an active proposal.
    /// @param _proposalId ID of the proposal to vote on.
    /// @param _vote Vote option (FOR, AGAINST, ABSTAIN).
    function voteOnProposal(uint256 _proposalId, VoteOption _vote) external onlyMember notPaused proposalExists(_proposalId) proposalActive(_proposalId) proposalNotCancelled(_proposalId) proposalNotExecuted(_proposalId) {
        require(proposals[_proposalId].votes[msg.sender] == VoteOption.ABSTAIN, "You have already voted on this proposal."); // Assuming ABSTAIN is default initial value

        proposals[_proposalId].votes[msg.sender] = _vote;
        if (_vote == VoteOption.FOR) {
            proposals[_proposalId].votesFor++;
        } else if (_vote == VoteOption.AGAINST) {
            proposals[_proposalId].votesAgainst++;
        } else if (_vote == VoteOption.ABSTAIN) {
            proposals[_proposalId].votesAbstain++;
        }

        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    /// @notice Executes a proposal if it has passed the voting threshold.
    /// @param _proposalId ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external notPaused proposalExists(_proposalId) proposalActive(_proposalId) proposalNotCancelled(_proposalId) proposalNotExecuted(_proposalId) {
        require(block.timestamp > proposals[_proposalId].endTime, "Voting is still active.");

        uint256 totalVotes = proposals[_proposalId].votesFor + proposals[_proposalId].votesAgainst + proposals[_proposalId].votesAbstain;
        uint256 quorumReached = (totalVotes * 100) / memberCount; // Calculate quorum percentage
        require(quorumReached >= votingQuorum, "Quorum not reached for proposal execution.");
        require(proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst, "Proposal failed to pass majority vote.");


        proposals[_proposalId].executed = true;

        if (proposals[_proposalId].proposalType == ProposalType.ASSET_TRANSFER) {
            // Example: Assuming data is encoded for asset transfer (address recipient, address tokenAddress, uint256 amount)
            (address recipient, address tokenAddress, uint256 amount) = abi.decode(proposals[_proposalId].data, (address, address, uint256));
            if (tokenAddress == address(0)) { // ETH transfer
                payable(recipient).transfer(amount);
            } else { // ERC20 transfer (requires interface)
                IERC20(tokenAddress).transfer(recipient, amount);
            }
        } else if (proposals[_proposalId].proposalType == ProposalType.CUSTOM_FUNCTION_CALL) {
            // Example: Generic function call - be VERY careful with security implications!
            (address targetAddress, bytes memory callData) = abi.decode(proposals[_proposalId].data, (address, bytes));
            (bool success, ) = targetAddress.call(callData);
            require(success, "Custom function call failed.");
        } // Add more proposal type execution logic here as needed.

        emit ProposalExecuted(_proposalId);
    }

    /// @notice Allows the proposer or admin to cancel a proposal before voting ends.
    /// @param _proposalId ID of the proposal to cancel.
    function cancelProposal(uint256 _proposalId) external proposalExists(_proposalId) proposalActive(_proposalId) proposalNotCancelled(_proposalId) proposalNotExecuted(_proposalId) {
        require(msg.sender == proposals[_proposalId].proposer || msg.sender == admin || isCouncilMember(msg.sender), "Only proposer, admin or council can cancel proposal.");
        proposals[_proposalId].cancelled = true;
        emit ProposalCancelled(_proposalId);
        payable(proposals[_proposalId].proposer).transfer(proposalDepositAmount); // Return proposal deposit
    }

    /// @notice Gets details of a specific proposal.
    /// @param _proposalId ID of the proposal.
    /// @return Proposal struct containing proposal details.
    function getProposalDetails(uint256 _proposalId) public view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice Gets voting statistics for a specific proposal.
    /// @param _proposalId ID of the proposal.
    /// @return uint256 votesFor, uint256 votesAgainst, uint256 votesAbstain.
    function getProposalVotingStats(uint256 _proposalId) public view proposalExists(_proposalId) returns (uint256 votesFor, uint256 votesAgainst, uint256 votesAbstain) {
        return (proposals[_proposalId].votesFor, proposals[_proposalId].votesAgainst, proposals[_proposalId].votesAbstain);
    }

    // -------- 3. Dynamic Governance Parameter Functions --------

    /// @notice Allows admin/council to update the voting quorum percentage.
    /// @param _newQuorum New quorum percentage (0-100).
    function updateVotingQuorum(uint256 _newQuorum) external onlyCouncil notPaused {
        require(_newQuorum <= 100, "Quorum percentage must be between 0 and 100.");
        votingQuorum = _newQuorum;
        emit VotingQuorumUpdated(_newQuorum);
    }

    /// @notice Allows admin/council to update the voting duration.
    /// @param _newDuration New voting duration in seconds.
    function updateVotingDuration(uint256 _newDuration) external onlyCouncil notPaused {
        votingDuration = _newDuration;
        emit VotingDurationUpdated(_newDuration);
    }

    /// @notice Allows admin/council to update the proposal deposit amount.
    /// @param _newDeposit New proposal deposit amount in wei.
    function updateProposalDeposit(uint256 _newDeposit) external onlyCouncil notPaused {
        proposalDepositAmount = _newDeposit;
        emit ProposalDepositUpdated(_newDeposit);
    }

    // -------- 4. Reputation System Functions --------

    /// @notice Allows admin/council to increase a member's reputation score.
    /// @param _member Address of the member to increase reputation for.
    /// @param _amount Amount to increase reputation by.
    function increaseReputation(address _member, uint256 _amount) external onlyCouncil notPaused {
        reputation[_member] += _amount;
        emit ReputationIncreased(_member, _amount);
    }

    /// @notice Allows admin/council to decrease a member's reputation score.
    /// @param _member Address of the member to decrease reputation for.
    /// @param _amount Amount to decrease reputation by.
    function decreaseReputation(address _member, uint256 _amount) external onlyCouncil notPaused {
        reputation[_member] -= _amount;
        emit ReputationDecreased(_member, _amount);
    }

    /// @notice Gets a member's reputation score.
    /// @param _member Address of the member.
    /// @return uint256 Reputation score.
    function getMemberReputation(address _member) public view returns (uint256) {
        return reputation[_member];
    }

    /// @notice Allows admin/council to set the minimum reputation required to submit a specific proposal type.
    /// @param _proposalType Proposal type to set the minimum reputation for.
    /// @param _minReputation Minimum reputation score required.
    function setMinReputationForProposal(ProposalType _proposalType, uint256 _minReputation) external onlyCouncil notPaused {
        minReputationForProposalType[_proposalType] = _minReputation;
    }

    // -------- 5. Treasury & Asset Management Functions --------

    /// @notice Allows anyone to deposit ETH into the DAO treasury.
    function depositFunds() external payable notPaused {
        // Funds are automatically received by the contract when msg.value > 0 in any payable function call.
        // No explicit code needed here, but you could add logic or events if desired.
    }

    /// @notice Allows members to propose transferring assets (ETH or ERC20) from the treasury.
    /// @param _recipient Address to receive the assets.
    /// @param _tokenAddress Address of the ERC20 token to transfer (address(0) for ETH).
    /// @param _amount Amount of assets to transfer.
    function proposeAssetTransfer(address _recipient, address _tokenAddress, uint256 _amount) external onlyMember notPaused canSubmitProposal(ProposalType.ASSET_TRANSFER) {
        // Encode data for proposal execution - recipient, token address, amount
        bytes memory data = abi.encode(_recipient, _tokenAddress, _amount);
        submitProposal("Asset Transfer Proposal", ProposalType.ASSET_TRANSFER, data);
    }

    /// @notice Gets the ETH balance of the DAO treasury.
    /// @return uint256 ETH balance in wei.
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Gets the balance of a specific ERC20 token in the DAO treasury.
    /// @param _tokenAddress Address of the ERC20 token.
    /// @return uint256 Token balance.
    function getTokenBalance(address _tokenAddress) public view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    // -------- 6. Emergency & System Functions --------

    /// @notice Allows admin/council to pause critical contract functions in case of emergency.
    function emergencyPause() external onlyCouncil notPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Allows admin/council to resume paused contract functions.
    function emergencyUnpause() external onlyCouncil {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Check if address is council member
    function isCouncilMember(address _address) public view returns (bool) {
        for (uint256 i = 0; i < councilMembers.length; i++) {
            if (councilMembers[i] == _address) {
                return true;
            }
        }
        return false;
    }

    // -------- Interfaces --------
    interface IERC20 {
        function transfer(address recipient, uint256 amount) external returns (bool);
        function balanceOf(address account) external view returns (uint256);
    }
}
```