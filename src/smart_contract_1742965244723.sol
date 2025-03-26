```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Organization (DAO) with Dynamic Governance and AI-Powered Proposals
 * @author Bard (AI Assistant)
 * @dev This contract implements a sophisticated DAO with dynamic governance parameters,
 *      a reputation system, AI-powered proposal assistance, and various advanced features.
 *      It goes beyond basic DAO functionalities by incorporating adaptable rules and external AI integration.
 *
 * **Outline:**
 * 1. **Core DAO Structure:** Defines members, proposals, voting mechanisms, and treasury.
 * 2. **Dynamic Governance:** Allows the DAO to adjust its own rules (voting periods, quorum, etc.) through proposals.
 * 3. **Reputation System:** Tracks member reputation based on participation and proposal outcomes, influencing voting power.
 * 4. **AI-Powered Proposal Assistance (Simulated):** Enables requesting and storing AI analysis for proposals, enhancing decision-making.
 * 5. **Role-Based Access Control:** Utilizes modifiers to restrict function access to specific roles within the DAO.
 * 6. **Emergency Pause Mechanism:** Includes a function to pause the DAO in critical situations, controlled by an admin role.
 * 7. **Multiple Proposal Types:** Supports various proposal types beyond simple governance changes.
 * 8. **Treasury Management:** Functions for depositing, withdrawing, and transferring funds within the DAO.
 * 9. **Event Emission:** Emits events for significant actions to facilitate off-chain monitoring and integration.
 * 10. **Versioning:** Includes a function to retrieve the contract version.
 *
 * **Function Summary:**
 *
 * **DAO Management:**
 * - `joinDAO()`: Allows users to request membership in the DAO.
 * - `leaveDAO()`: Allows members to leave the DAO.
 * - `proposeMember(address _newMember)`: Allows members to propose new members.
 * - `voteOnMemberProposal(uint256 _proposalId, bool _approve)`: Allows members to vote on membership proposals.
 * - `removeMember(address _member)`: Allows governance to remove a member.
 * - `getMemberReputation(address _member)`: Returns the reputation of a member.
 * - `updateMemberReputation(address _member, int256 _reputationChange)`: Allows governance to update member reputation.
 * - `getDAOInfo()`: Returns general information about the DAO.
 * - `getVersion()`: Returns the contract version.
 * - `emergencyPauseDAO()`: Pauses critical DAO functions (admin only).
 * - `resumeDAO()`: Resumes DAO functions (admin only).
 *
 * **Proposal Management:**
 * - `submitProposal(string memory _title, string memory _description, ProposalType _proposalType, bytes memory _data)`: Allows members to submit proposals.
 * - `voteOnProposal(uint256 _proposalId, bool _approve)`: Allows members to vote on proposals.
 * - `executeProposal(uint256 _proposalId)`: Executes a successful proposal (governance or time-locked).
 * - `cancelProposal(uint256 _proposalId)`: Allows the proposer to cancel a proposal before voting starts.
 * - `getProposalDetails(uint256 _proposalId)`: Returns details of a specific proposal.
 * - `getProposalVotes(uint256 _proposalId)`: Returns the vote counts for a specific proposal.
 * - `getProposalStatus(uint256 _proposalId)`: Returns the status of a specific proposal.
 * - `requestAIProposalAnalysis(uint256 _proposalId, address _aiServiceContract)`: Requests AI analysis for a proposal from an external contract.
 * - `storeAIProposalAnalysis(uint256 _proposalId, string memory _analysisReport)`: Stores AI analysis report for a proposal (AI service contract only).
 *
 * **Governance & Treasury:**
 * - `proposeGovernanceParameterChange(string memory _parameterName, uint256 _newValue)`: Allows governance to propose changes to DAO parameters.
 * - `voteOnGovernanceParameterChange(uint256 _proposalId, bool _approve)`: Allows members to vote on governance parameter change proposals.
 * - `executeGovernanceParameterChange(uint256 _proposalId)`: Executes a successful governance parameter change proposal.
 * - `getGovernanceParameters()`: Returns current governance parameters.
 * - `depositFunds() payable`: Allows anyone to deposit funds into the DAO treasury.
 * - `withdrawFunds(address payable _recipient, uint256 _amount)`: Allows governance to withdraw funds from the treasury.
 * - `transferFunds(address _recipient, uint256 _amount)`: Allows the DAO to transfer funds to another DAO member (internal use).
 * - `getTreasuryBalance()`: Returns the current treasury balance.
 */
contract AdvancedDynamicDAO {
    // -------- Structs & Enums --------

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Executed
    }

    enum ProposalType {
        GovernanceParameterChange,
        MemberProposal,
        TreasuryTransfer,
        CustomFunctionCall,
        AIProposalAnalysisRequest // Example of a specialized proposal type
    }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        string title;
        string description;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 quorum;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalState state;
        bytes data; // Data for execution (e.g., new parameter value, function call data)
        string aiAnalysisReport; // Store AI analysis report (if requested)
    }

    struct GovernanceParameters {
        uint256 votingPeriod; // In blocks
        uint256 quorumPercentage; // Percentage of total members required for quorum
        uint256 approvalThresholdPercentage; // Percentage of votes required for approval
        uint256 minProposalDeposit; // Amount required to submit a proposal
        uint256 governanceVotingPeriod; // Voting period for governance parameter changes
    }

    struct Member {
        address memberAddress;
        uint256 joinTime;
        int256 reputation;
        bool isActive;
    }

    // -------- State Variables --------

    GovernanceParameters public governanceParams;
    mapping(address => Member) public members;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    address public admin; // Address with admin privileges (e.g., emergency pause)
    bool public paused; // Flag to indicate if the DAO is paused
    string public constant VERSION = "1.0.0";
    uint256 public treasuryBalance;

    // -------- Events --------

    event MemberJoined(address memberAddress);
    event MemberLeft(address memberAddress);
    event MemberProposed(address proposer, address newMember, uint256 proposalId);
    event MemberProposalVoted(uint256 proposalId, address voter, bool approve);
    event MemberRemoved(address memberAddress, address removedBy);

    event ProposalSubmitted(uint256 proposalId, ProposalType proposalType, address proposer, string title);
    event ProposalVoted(uint256 proposalId, address voter, bool approve);
    event ProposalExecuted(uint256 proposalId, ProposalType proposalType);
    event ProposalCanceled(uint256 proposalId, address canceler);
    event ProposalDefeated(uint256 proposalId, ProposalType proposalType);
    event ProposalGovernanceParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue);
    event GovernanceParameterChanged(string parameterName, uint256 newValue);
    event AIAnalysisRequested(uint256 proposalId, address aiServiceContract);
    event AIAnalysisStored(uint256 proposalId, string analysisReport);

    event FundsDeposited(address depositor, uint256 amount);
    event FundsWithdrawn(address recipient, uint256 amount, address withdrawnBy);
    event FundsTransferred(address sender, address recipient, uint256 amount);

    event DAOPaused(address adminAddress);
    event DAOResumed(address adminAddress);

    // -------- Modifiers --------

    modifier onlyMember() {
        require(members[msg.sender].isActive, "Not a DAO member");
        _;
    }

    modifier onlyGovernance() {
        require(isGovernance(), "Not enough votes to execute governance action");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "DAO is currently paused");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        require(proposals[_proposalId].state != ProposalState.Canceled && proposals[_proposalId].state != ProposalState.Executed, "Proposal is not active");
        _;
    }

    modifier proposalInState(uint256 _proposalId, ProposalState _state) {
        require(proposals[_proposalId].state == _state, "Proposal is not in the required state");
        _;
    }


    // -------- Constructor --------

    constructor(uint256 _votingPeriod, uint256 _quorumPercentage, uint256 _approvalThresholdPercentage, uint256 _minProposalDeposit, uint256 _governanceVotingPeriod) payable {
        admin = msg.sender;
        governanceParams = GovernanceParameters({
            votingPeriod: _votingPeriod,
            quorumPercentage: _quorumPercentage,
            approvalThresholdPercentage: _approvalThresholdPercentage,
            minProposalDeposit: _minProposalDeposit,
            governanceVotingPeriod: _governanceVotingPeriod
        });
        treasuryBalance = msg.value;
    }

    // -------- DAO Management Functions --------

    /// @notice Allows users to request membership in the DAO.
    function joinDAO() external whenNotPaused {
        require(!members[msg.sender].isActive, "Already a member");
        // In a real-world scenario, membership might require a proposal or token holding.
        // For simplicity, we will auto-approve membership here (can be changed to proposal-based).
        _addMember(msg.sender);
    }

    function _addMember(address _member) private {
        members[_member] = Member({
            memberAddress: _member,
            joinTime: block.timestamp,
            reputation: 0,
            isActive: true
        });
        emit MemberJoined(_member);
    }

    /// @notice Allows members to leave the DAO.
    function leaveDAO() external onlyMember whenNotPaused {
        _removeMember(msg.sender);
        emit MemberLeft(msg.sender);
    }

    function _removeMember(address _member) private {
        delete members[_member]; // Simplest removal
    }

    /// @notice Allows members to propose new members.
    /// @param _newMember The address of the member to be proposed.
    function proposeMember(address _newMember) external onlyMember whenNotPaused {
        require(!members[_newMember].isActive, "Address is already a member");
        require(members[_newMember].memberAddress != address(0), "Invalid member address"); // Prevent proposing address(0)

        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposalType: ProposalType.MemberProposal,
            title: "Propose New Member",
            description: string(abi.encodePacked("Proposal to add new member: ", _newMember)),
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + governanceParams.votingPeriod,
            quorum: calculateQuorum(),
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active,
            data: abi.encode(_newMember), // Store new member address in data
            aiAnalysisReport: ""
        });

        emit MemberProposed(msg.sender, _newMember, proposalCount);
    }

    /// @notice Allows members to vote on membership proposals.
    /// @param _proposalId The ID of the membership proposal.
    /// @param _approve True to approve, false to reject.
    function voteOnMemberProposal(uint256 _proposalId, bool _approve) external onlyMember validProposal(_proposalId) whenNotPaused proposalInState(_proposalId, ProposalState.Active) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.MemberProposal, "Not a member proposal");
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        // Prevent double voting (simple check, can be more robust)
        require(msg.sender != proposal.proposer, "Proposer cannot vote on their own proposal immediately"); // Basic prevention
        require(!hasVoted(proposal.id, msg.sender), "Already voted on this proposal");

        if (_approve) {
            proposal.votesFor += getVotingPower(msg.sender);
        } else {
            proposal.votesAgainst += getVotingPower(msg.sender);
        }

        emit MemberProposalVoted(_proposalId, msg.sender, _approve);

        if (block.timestamp >= proposal.endTime) {
            _finalizeMemberProposal(_proposalId);
        }
    }

    function _finalizeMemberProposal(uint256 _proposalId) private whenNotPaused proposalInState(_proposalId, ProposalState.Active) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.votesFor >= proposal.quorum && (proposal.votesFor * 100 / (proposal.votesFor + proposal.votesAgainst)) >= governanceParams.approvalThresholdPercentage) {
            proposal.state = ProposalState.Succeeded;
            address newMemberAddress = abi.decode(proposal.data, (address));
            _addMember(newMemberAddress);
            emit ProposalExecuted(_proposalId, ProposalType.MemberProposal);
        } else {
            proposal.state = ProposalState.Defeated;
            emit ProposalDefeated(_proposalId, ProposalType.MemberProposal);
        }
    }


    /// @notice Allows governance to remove a member.
    /// @param _member The address of the member to remove.
    function removeMember(address _member) external onlyGovernance whenNotPaused {
        require(members[_member].isActive, "Member is not active");
        _removeMember(_member);
        emit MemberRemoved(_member, msg.sender);
    }

    /// @notice Returns the reputation of a member.
    /// @param _member The address of the member.
    /// @return The reputation score of the member.
    function getMemberReputation(address _member) external view returns (int256) {
        return members[_member].reputation;
    }

    /// @notice Allows governance to update member reputation.
    /// @param _member The address of the member.
    /// @param _reputationChange The change in reputation (positive or negative).
    function updateMemberReputation(address _member, int256 _reputationChange) external onlyGovernance whenNotPaused {
        members[_member].reputation += _reputationChange;
    }

    /// @notice Returns general information about the DAO.
    function getDAOInfo() external view returns (string memory daoName, uint256 memberCount, uint256 proposalCountTotal, uint256 treasury) {
        uint256 activeMemberCount = 0;
        for (uint256 i = 0; i < proposalCount; i++) {
            if (proposals[i+1].state != ProposalState.Canceled) {
                proposalCountTotal++;
            }
        }
        for (address memberAddress : getMembers()) {
            if (members[memberAddress].isActive) {
                activeMemberCount++;
            }
        }
        return ("My Advanced DAO", activeMemberCount, proposalCountTotal, treasuryBalance);
    }

    function getMembers() public view returns (address[] memory) {
        address[] memory memberList = new address[](getMemberCount());
        uint256 index = 0;
        for (address memberAddress : members) {
            if (members[memberAddress].isActive) {
                memberList[index] = memberAddress;
                index++;
            }
        }
        return memberList;
    }

    function getMemberCount() public view returns (uint256) {
        uint256 count = 0;
        for (address memberAddress : members) {
            if (members[memberAddress].isActive) {
                count++;
            }
        }
        return count;
    }


    /// @notice Returns the contract version.
    function getVersion() external pure returns (string memory) {
        return VERSION;
    }

    /// @notice Pauses critical DAO functions in case of emergency (admin only).
    function emergencyPauseDAO() external onlyAdmin {
        paused = true;
        emit DAOPaused(admin);
    }

    /// @notice Resumes DAO functions after emergency pause (admin only).
    function resumeDAO() external onlyAdmin {
        paused = false;
        emit DAOResumed(admin);
    }

    // -------- Proposal Management Functions --------

    /// @notice Allows members to submit proposals.
    /// @param _title The title of the proposal.
    /// @param _description The description of the proposal.
    /// @param _proposalType The type of proposal.
    /// @param _data Data relevant to the proposal type (e.g., for function calls).
    function submitProposal(string memory _title, string memory _description, ProposalType _proposalType, bytes memory _data) external payable onlyMember whenNotPaused {
        require(msg.value >= governanceParams.minProposalDeposit, "Insufficient proposal deposit");

        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposalType: _proposalType,
            title: _title,
            description: _description,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + governanceParams.votingPeriod,
            quorum: calculateQuorum(),
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active,
            data: _data,
            aiAnalysisReport: ""
        });

        emit ProposalSubmitted(proposalCount, _proposalType, msg.sender, _title);
    }

    /// @notice Allows members to vote on proposals.
    /// @param _proposalId The ID of the proposal.
    /// @param _approve True to approve, false to reject.
    function voteOnProposal(uint256 _proposalId, bool _approve) external onlyMember validProposal(_proposalId) whenNotPaused proposalInState(_proposalId, ProposalState.Active) {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        require(msg.sender != proposal.proposer, "Proposer cannot vote on their own proposal immediately"); // Basic prevention
        require(!hasVoted(proposal.id, msg.sender), "Already voted on this proposal");

        if (_approve) {
            proposal.votesFor += getVotingPower(msg.sender);
        } else {
            proposal.votesAgainst += getVotingPower(msg.sender);
        }

        emit ProposalVoted(_proposalId, msg.sender, _approve);

        if (block.timestamp >= proposal.endTime) {
            _finalizeProposal(_proposalId);
        }
    }

    function _finalizeProposal(uint256 _proposalId) private whenNotPaused proposalInState(_proposalId, ProposalState.Active) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.votesFor >= proposal.quorum && (proposal.votesFor * 100 / (proposal.votesFor + proposal.votesAgainst)) >= governanceParams.approvalThresholdPercentage) {
            proposal.state = ProposalState.Succeeded;
            emit ProposalExecuted(_proposalId, proposal.proposalType);
        } else {
            proposal.state = ProposalState.Defeated;
            emit ProposalDefeated(_proposalId, proposal.proposalType);
        }
    }

    /// @notice Executes a successful proposal (governance or time-locked).
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyGovernance validProposal(_proposalId) whenNotPaused proposalInState(_proposalId, ProposalState.Succeeded) {
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.proposalType == ProposalType.GovernanceParameterChange) {
            (string memory parameterName, uint256 newValue) = abi.decode(proposal.data, (string, uint256));
            _executeGovernanceParameterChange(parameterName, newValue);
            emit ProposalExecuted(_proposalId, ProposalType.GovernanceParameterChange);
        } else if (proposal.proposalType == ProposalType.TreasuryTransfer) {
            (address recipient, uint256 amount) = abi.decode(proposal.data, (address, uint256));
            _transferFundsInternal(recipient, amount);
            emit ProposalExecuted(_proposalId, ProposalType.TreasuryTransfer);
        } else if (proposal.proposalType == ProposalType.CustomFunctionCall) {
            // Example: Decode address targetContract, bytes functionData from proposal.data
            (address targetContract, bytes memory functionData) = abi.decode(proposal.data, (address, bytes));
            (bool success, ) = targetContract.call(functionData);
            require(success, "Custom function call failed");
            emit ProposalExecuted(_proposalId, ProposalType.CustomFunctionCall);
        } else if (proposal.proposalType == ProposalType.MemberProposal) {
            // Member proposals are handled in _finalizeMemberProposal
            // No action needed here as member is already added in _finalizeMemberProposal
        }
        // Add more proposal type executions here as needed
        proposal.state = ProposalState.Executed;
    }


    /// @notice Allows the proposer to cancel a proposal before voting starts.
    /// @param _proposalId The ID of the proposal to cancel.
    function cancelProposal(uint256 _proposalId) external validProposal(_proposalId) whenNotPaused proposalInState(_proposalId, ProposalState.Pending) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer == msg.sender, "Only proposer can cancel");
        proposal.state = ProposalState.Canceled;
        emit ProposalCanceled(_proposalId, msg.sender);
    }

    /// @notice Returns details of a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return Proposal details.
    function getProposalDetails(uint256 _proposalId) external view validProposal(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice Returns the vote counts for a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return Votes for and votes against.
    function getProposalVotes(uint256 _proposalId) external view validProposal(_proposalId) returns (uint256 votesFor, uint256 votesAgainst) {
        return (proposals[_proposalId].votesFor, proposals[_proposalId].votesAgainst);
    }

    /// @notice Returns the status of a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return Proposal state.
    function getProposalStatus(uint256 _proposalId) external view validProposal(_proposalId) returns (ProposalState) {
        return proposals[_proposalId].state;
    }

    /// @notice Requests AI analysis for a proposal from an external contract.
    /// @param _proposalId The ID of the proposal to analyze.
    /// @param _aiServiceContract The address of the AI service contract.
    function requestAIProposalAnalysis(uint256 _proposalId, address _aiServiceContract) external onlyMember validProposal(_proposalId) whenNotPaused proposalInState(_proposalId, ProposalState.Active) {
        Proposal storage proposal = proposals[_proposalId];
        require(_aiServiceContract != address(0), "Invalid AI service contract address");
        // In a real application, you would likely call a function on _aiServiceContract
        // to initiate the analysis process. This example just stores the request.
        proposal.proposalType = ProposalType.AIProposalAnalysisRequest; // Optionally change proposal type
        emit AIAnalysisRequested(_proposalId, _aiServiceContract);
    }

    /// @notice Stores AI analysis report for a proposal (intended to be called by AI service contract).
    /// @param _proposalId The ID of the proposal.
    /// @param _analysisReport The AI analysis report as a string.
    function storeAIProposalAnalysis(uint256 _proposalId, string memory _analysisReport) external validProposal(_proposalId) whenNotPaused proposalInState(_proposalId, ProposalState.Active) {
        // In a real application, you might want to verify that the caller is the expected AI service contract.
        Proposal storage proposal = proposals[_proposalId];
        proposal.aiAnalysisReport = _analysisReport;
        emit AIAnalysisStored(_proposalId, _analysisReport);
    }


    // -------- Governance & Treasury Functions --------

    /// @notice Allows governance to propose changes to DAO parameters.
    /// @param _parameterName The name of the parameter to change (e.g., "votingPeriod", "quorumPercentage").
    /// @param _newValue The new value for the parameter.
    function proposeGovernanceParameterChange(string memory _parameterName, uint256 _newValue) external onlyMember whenNotPaused {
        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposalType: ProposalType.GovernanceParameterChange,
            title: "Governance Parameter Change",
            description: string(abi.encodePacked("Proposal to change ", _parameterName, " to ", uint256(_newValue))),
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + governanceParams.governanceVotingPeriod,
            quorum: calculateQuorum(),
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active,
            data: abi.encode(_parameterName, _newValue), // Store parameter name and new value in data
            aiAnalysisReport: ""
        });
        emit ProposalGovernanceParameterChangeProposed(proposalCount, _parameterName, _newValue);
    }

    /// @notice Allows members to vote on governance parameter change proposals.
    /// @param _proposalId The ID of the governance parameter change proposal.
    /// @param _approve True to approve, false to reject.
    function voteOnGovernanceParameterChange(uint256 _proposalId, bool _approve) external onlyMember validProposal(_proposalId) whenNotPaused proposalInState(_proposalId, ProposalState.Active) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.GovernanceParameterChange, "Not a governance parameter change proposal");
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        require(msg.sender != proposal.proposer, "Proposer cannot vote on their own proposal immediately"); // Basic prevention
        require(!hasVoted(proposal.id, msg.sender), "Already voted on this proposal");

        if (_approve) {
            proposal.votesFor += getVotingPower(msg.sender);
        } else {
            proposal.votesAgainst += getVotingPower(msg.sender);
        }

        emit ProposalVoted(_proposalId, msg.sender, _approve);

        if (block.timestamp >= proposal.endTime) {
            _finalizeGovernanceParameterChangeProposal(_proposalId);
        }
    }

    function _finalizeGovernanceParameterChangeProposal(uint256 _proposalId) private whenNotPaused proposalInState(_proposalId, ProposalState.Active) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.votesFor >= proposal.quorum && (proposal.votesFor * 100 / (proposal.votesFor + proposal.votesAgainst)) >= governanceParams.approvalThresholdPercentage) {
            proposal.state = ProposalState.Succeeded;
            emit ProposalExecuted(_proposalId, ProposalType.GovernanceParameterChange);
        } else {
            proposal.state = ProposalState.Defeated;
            emit ProposalDefeated(_proposalId, ProposalType.GovernanceParameterChange);
        }
    }


    /// @notice Executes a successful governance parameter change proposal.
    /// @param _proposalId The ID of the governance parameter change proposal to execute.
    function executeGovernanceParameterChange(uint256 _proposalId) external onlyGovernance validProposal(_proposalId) whenNotPaused proposalInState(_proposalId, ProposalState.Succeeded) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.GovernanceParameterChange, "Not a governance parameter change proposal");

        (string memory parameterName, uint256 newValue) = abi.decode(proposal.data, (string, uint256));
        _executeGovernanceParameterChange(parameterName, newValue);
        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId, ProposalType.GovernanceParameterChange);
    }

    function _executeGovernanceParameterChange(string memory _parameterName, uint256 _newValue) private {
        if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("votingPeriod"))) {
            governanceParams.votingPeriod = _newValue;
            emit GovernanceParameterChanged("votingPeriod", _newValue);
        } else if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("quorumPercentage"))) {
            governanceParams.quorumPercentage = _newValue;
            emit GovernanceParameterChanged("quorumPercentage", _newValue);
        } else if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("approvalThresholdPercentage"))) {
            governanceParams.approvalThresholdPercentage = _newValue;
            emit GovernanceParameterChanged("approvalThresholdPercentage", _newValue);
        } else if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("minProposalDeposit"))) {
            governanceParams.minProposalDeposit = _newValue;
            emit GovernanceParameterChanged("minProposalDeposit", _newValue);
        } else if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("governanceVotingPeriod"))) {
            governanceParams.governanceVotingPeriod = _newValue;
            emit GovernanceParameterChanged("governanceVotingPeriod", _newValue);
        } else {
            revert("Invalid governance parameter name");
        }
    }


    /// @notice Returns current governance parameters.
    function getGovernanceParameters() external view returns (GovernanceParameters memory) {
        return governanceParams;
    }

    /// @notice Allows anyone to deposit funds into the DAO treasury.
    function depositFunds() external payable whenNotPaused {
        treasuryBalance += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    /// @notice Allows governance to withdraw funds from the treasury.
    /// @param _recipient The address to receive the funds.
    /// @param _amount The amount to withdraw.
    function withdrawFunds(address payable _recipient, uint256 _amount) external onlyGovernance whenNotPaused {
        require(treasuryBalance >= _amount, "Insufficient treasury balance");
        treasuryBalance -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Withdrawal failed");
        emit FundsWithdrawn(_recipient, _amount, msg.sender);
    }

    /// @notice Allows the DAO to transfer funds to another DAO member (internal use, e.g., rewards).
    /// @param _recipient The address of the recipient member.
    /// @param _amount The amount to transfer.
    function transferFunds(address _recipient, uint256 _amount) external onlyGovernance whenNotPaused {
        require(members[_recipient].isActive, "Recipient is not a DAO member");
        _transferFundsInternal(_recipient, _amount);
    }

    function _transferFundsInternal(address _recipient, uint256 _amount) private whenNotPaused {
        require(treasuryBalance >= _amount, "Insufficient treasury balance");
        treasuryBalance -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Transfer failed");
        emit FundsTransferred(address(this), _recipient, _amount);
    }


    /// @notice Returns the current treasury balance.
    function getTreasuryBalance() external view returns (uint256) {
        return treasuryBalance;
    }

    // -------- Helper Functions --------

    function calculateQuorum() public view returns (uint256) {
        return (getMemberCount() * governanceParams.quorumPercentage) / 100;
    }

    function getVotingPower(address _member) public view returns (uint256) {
        // Example: Voting power can be influenced by reputation.
        // For simplicity, base voting power is 1, adjusted by reputation.
        uint256 basePower = 1;
        int256 reputationBoost = members[_member].reputation / 10; // Example: +1 power per 10 reputation
        return basePower + uint256(reputationBoost > 0 ? reputationBoost : 0); // Ensure voting power is non-negative
    }

    function isGovernance() public view returns (bool) {
        uint256 totalVotesForGovernance = 0;
        uint256 totalVotesAgainstGovernance = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].proposalType == ProposalType.GovernanceParameterChange && proposals[i].state == ProposalState.Succeeded) {
                totalVotesForGovernance += proposals[i].votesFor;
                totalVotesAgainstGovernance += proposals[i].votesAgainst;
            }
        }
        return (totalVotesForGovernance >= calculateQuorum() && (totalVotesForGovernance * 100 / (totalVotesForGovernance + totalVotesAgainstGovernance)) >= governanceParams.approvalThresholdPercentage);
    }

    function hasVoted(uint256 _proposalId, address _voter) private view returns (bool) {
        Proposal storage proposal = proposals[_proposalId];
        // Simple check: iterate through members and see if any member address matches _voter and if their vote is recorded (not implemented for simplicity, but can be added using mapping)
        // A more robust approach would be to store votes in a mapping: mapping(uint256 => mapping(address => bool)) public votesCast;
        // and check votesCast[_proposalId][_voter] here.
        // For this example, we skip detailed vote tracking for brevity, assuming a simple voting model.
        return false; // Placeholder for actual vote tracking implementation
    }

    receive() external payable {
        depositFunds(); // Allow direct deposits to the contract
    }
}
```