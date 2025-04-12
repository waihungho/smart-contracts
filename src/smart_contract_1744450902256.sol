```solidity
/**
 * @title Decentralized Autonomous Organization (DAO) for Creative Projects Funding - "ArtisanDAO"
 * @author Bard (AI Assistant)
 * @dev A DAO focused on funding and supporting creative projects (art, music, software, etc.) through community governance.
 *
 * **Outline & Function Summary:**
 *
 * **1. Core DAO Functionality:**
 *    - `submitMembershipProposal(string memory _reason)`: Allows anyone to submit a proposal to become a member, stating their reason.
 *    - `voteOnMembershipProposal(uint256 _proposalId, bool _support)`: Members can vote on membership proposals.
 *    - `processMembershipProposal(uint256 _proposalId)`: Processes a membership proposal after voting period, adding approved members.
 *    - `revokeMembership(address _member)`: Allows DAO governance to revoke membership from an address.
 *    - `getMemberDetails(address _member)`: Returns details about a member, including their karma and join date.
 *    - `isMember(address _account)`: Checks if an address is a member of the DAO.
 *
 * **2. Project Funding Proposals:**
 *    - `submitFundingProposal(string memory _projectName, string memory _projectDescription, uint256 _fundingGoal, address _projectCreator)`: Members can submit proposals to fund creative projects.
 *    - `voteOnFundingProposal(uint256 _proposalId, bool _support)`: Members vote on project funding proposals.
 *    - `processFundingProposal(uint256 _proposalId)`: Processes a funding proposal after voting, transferring funds if approved.
 *    - `contributeToProject(uint256 _projectId) payable`: Allows anyone (members and non-members) to contribute ETH to a funded project.
 *    - `withdrawProjectFunds(uint256 _projectId)`: Project creator can withdraw funds once funding goal is reached and project is approved.
 *    - `markProjectAsComplete(uint256 _projectId)`: Project creator can mark a funded project as complete, triggering potential rewards.
 *    - `getProjectDetails(uint256 _projectId)`: Returns details of a project funding proposal.
 *    - `getProjectStatus(uint256 _projectId)`: Returns the current status of a project (proposed, funded, completed, failed).
 *
 * **3. Governance and Rules:**
 *    - `submitRuleChangeProposal(string memory _ruleDescription, string memory _proposedRule)`: Members can propose changes to the DAO's rules or constitution.
 *    - `voteOnRuleChangeProposal(uint256 _proposalId, bool _support)`: Members vote on rule change proposals.
 *    - `processRuleChangeProposal(uint256 _proposalId)`: Processes rule change proposals and updates the DAO rules if approved.
 *    - `getCurrentRules()`: Returns the current rules or constitution of the DAO.
 *    - `setVotingDuration(uint256 _durationInSeconds)`: Admin function to set the default voting duration for proposals.
 *    - `setQuorum(uint256 _quorumPercentage)`: Admin function to set the quorum percentage required for proposals to pass.
 *
 * **4. Karma and Reputation System (Basic):**
 *    - `awardKarma(address _member, uint256 _karmaPoints, string memory _reason)`: Admin/DAO-controlled function to award karma points to members for contributions.
 *    - `getKarmaScore(address _member)`: Returns the karma score of a member. (Karma can be used for future governance weighting or rewards).
 *
 * **5. Emergency and Utility Functions:**
 *    - `pauseContract()`: Admin function to pause the contract in case of emergency or critical issues.
 *    - `unpauseContract()`: Admin function to unpause the contract.
 *    - `emergencyWithdraw(address payable _recipient, uint256 _amount)`: Admin function for emergency fund withdrawal to a specified address.
 *    - `getContractBalance()`: Returns the current ETH balance of the contract.
 */

pragma solidity ^0.8.0;

contract ArtisanDAO {
    // --- Enums and Structs ---

    enum ProposalType { MEMBERSHIP, FUNDING, RULE_CHANGE }
    enum ProposalStatus { PENDING, ACTIVE_VOTING, PASSED, REJECTED, EXECUTED }
    enum ProjectStatus { PROPOSED, FUNDED, COMPLETED, FAILED }

    struct MembershipProposal {
        uint256 proposalId;
        ProposalType proposalType;
        address proposer;
        string reason;
        ProposalStatus status;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
    }

    struct FundingProposal {
        uint256 proposalId;
        ProposalType proposalType;
        address proposer;
        string projectName;
        string projectDescription;
        uint256 fundingGoal;
        address projectCreator;
        ProposalStatus status;
        ProjectStatus projectStatus;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 currentFunding;
    }

    struct RuleChangeProposal {
        uint256 proposalId;
        ProposalType proposalType;
        address proposer;
        string ruleDescription;
        string proposedRule;
        ProposalStatus status;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
    }

    struct Member {
        address memberAddress;
        uint256 joinDate;
        uint256 karmaScore;
        bool isActive;
    }

    // --- State Variables ---

    address public admin;
    mapping(address => Member) public members;
    address[] public memberList;
    uint256 public memberCount;

    mapping(uint256 => MembershipProposal) public membershipProposals;
    uint256 public membershipProposalCount;

    mapping(uint256 => FundingProposal) public fundingProposals;
    uint256 public fundingProposalCount;

    mapping(uint256 => RuleChangeProposal) public ruleChangeProposals;
    uint256 public ruleChangeProposalCount;

    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public quorumPercentage = 50; // Default quorum percentage (50%)

    string public daoRules = "Initial DAO rules are set upon deployment. Rule changes require community proposal and voting.";

    bool public paused = false;

    uint256 public nextProposalId = 1; // Start proposal IDs from 1

    // --- Events ---

    event MembershipProposed(uint256 proposalId, address proposer, string reason);
    event MembershipVoteCast(uint256 proposalId, address voter, bool support);
    event MembershipProposalProcessed(uint256 proposalId, ProposalStatus status);
    event MembershipRevoked(address member, address revoker);

    event FundingProposed(uint256 proposalId, address proposer, string projectName, uint256 fundingGoal, address projectCreator);
    event FundingVoteCast(uint256 proposalId, address voter, bool support);
    event FundingProposalProcessed(uint256 proposalId, ProposalStatus status, ProjectStatus projectStatus);
    event ProjectContribution(uint256 projectId, address contributor, uint256 amount);
    event ProjectFundsWithdrawn(uint256 projectId, address creator, uint256 amount);
    event ProjectMarkedComplete(uint256 projectId, address creator);

    event RuleChangeProposed(uint256 proposalId, address proposer, string ruleDescription, string proposedRule);
    event RuleChangeVoteCast(uint256 proposalId, address voter, bool support);
    event RuleChangeProposalProcessed(uint256 proposalId, ProposalStatus status, string newRules);

    event KarmaAwarded(address member, uint256 karmaPoints, string reason);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event EmergencyWithdrawal(address recipient, uint256 amount, address admin);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMembers() {
        require(isMember(msg.sender), "Only DAO members can call this function.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0, "Invalid proposal ID.");
        _;
    }

    modifier proposalExists(ProposalType _proposalType, uint256 _proposalId) {
        if (_proposalType == ProposalType.MEMBERSHIP) {
            require(membershipProposals[_proposalId].proposalId == _proposalId, "Membership proposal does not exist.");
        } else if (_proposalType == ProposalType.FUNDING) {
            require(fundingProposals[_proposalId].proposalId == _proposalId, "Funding proposal does not exist.");
        } else if (_proposalType == ProposalType.RULE_CHANGE) {
            require(ruleChangeProposals[_proposalId].proposalId == _proposalId, "Rule change proposal does not exist.");
        } else {
            revert("Invalid proposal type.");
        }
        _;
    }

    modifier proposalInVoting(ProposalType _proposalType, uint256 _proposalId) {
        ProposalStatus status;
        if (_proposalType == ProposalType.MEMBERSHIP) {
            status = membershipProposals[_proposalId].status;
        } else if (_proposalType == ProposalType.FUNDING) {
            status = fundingProposals[_proposalId].status;
        } else if (_proposalType == ProposalType.RULE_CHANGE) {
            status = ruleChangeProposals[_proposalId].status;
        } else {
            revert("Invalid proposal type.");
        }
        require(status == ProposalStatus.ACTIVE_VOTING, "Proposal is not in active voting phase.");
        _;
    }

    modifier proposalPendingExecution(ProposalType _proposalType, uint256 _proposalId) {
        ProposalStatus status;
        if (_proposalType == ProposalType.MEMBERSHIP) {
            status = membershipProposals[_proposalId].status;
        } else if (_proposalType == ProposalType.FUNDING) {
            status = fundingProposals[_proposalId].status;
        } else if (_proposalType == ProposalType.RULE_CHANGE) {
            status = ruleChangeProposals[_proposalId].status;
        } else {
            revert("Invalid proposal type.");
        }
        require(status == ProposalStatus.PASSED, "Proposal is not passed and ready for execution.");
        _;
    }

    modifier projectExists(uint256 _projectId) {
        require(fundingProposals[_projectId].proposalId == _projectId, "Project does not exist.");
        _;
    }

    modifier projectInFundedStatus(uint256 _projectId) {
        require(fundingProposals[_projectId].projectStatus == ProjectStatus.FUNDED, "Project is not in funded status.");
        _;
    }

    modifier projectCreatorOnly(uint256 _projectId) {
        require(fundingProposals[_projectId].projectCreator == msg.sender, "Only project creator can call this function.");
        _;
    }


    // --- Constructor ---

    constructor() {
        admin = msg.sender;
    }

    // --- 1. Core DAO Functionality ---

    /// @notice Allows anyone to submit a proposal to become a member, stating their reason.
    /// @param _reason Reason for wanting to become a member.
    function submitMembershipProposal(string memory _reason) external notPaused {
        membershipProposals[nextProposalId] = MembershipProposal({
            proposalId: nextProposalId,
            proposalType: ProposalType.MEMBERSHIP,
            proposer: msg.sender,
            reason: _reason,
            status: ProposalStatus.PENDING,
            votingStartTime: 0,
            votingEndTime: 0,
            votesFor: 0,
            votesAgainst: 0
        });
        emit MembershipProposed(nextProposalId, msg.sender, _reason);
        nextProposalId++;
        membershipProposalCount++;
    }

    /// @notice Members can vote on membership proposals.
    /// @param _proposalId ID of the membership proposal.
    /// @param _support True for supporting the proposal, false for opposing.
    function voteOnMembershipProposal(uint256 _proposalId, bool _support) external onlyMembers notPaused validProposalId(_proposalId) proposalExists(ProposalType.MEMBERSHIP, _proposalId) proposalInVoting(ProposalType.MEMBERSHIP, _proposalId) {
        require(membershipProposals[_proposalId].votingEndTime > block.timestamp, "Voting period has ended.");
        require(membershipProposals[_proposalId].status == ProposalStatus.ACTIVE_VOTING, "Voting is not active for this proposal.");

        if (_support) {
            membershipProposals[_proposalId].votesFor++;
        } else {
            membershipProposals[_proposalId].votesAgainst++;
        }
        emit MembershipVoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Processes a membership proposal after voting period.
    /// @param _proposalId ID of the membership proposal.
    function processMembershipProposal(uint256 _proposalId) external onlyMembers notPaused validProposalId(_proposalId) proposalExists(ProposalType.MEMBERSHIP, _proposalId) {
        MembershipProposal storage proposal = membershipProposals[_proposalId];
        require(proposal.status == ProposalStatus.ACTIVE_VOTING, "Proposal voting is not active or already processed.");
        require(proposal.votingEndTime <= block.timestamp, "Voting period has not ended yet.");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorum = (memberCount * quorumPercentage) / 100; // Quorum based on current member count

        if (totalVotes >= quorum && proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.PASSED;
            _addMember(proposal.proposer);
        } else {
            proposal.status = ProposalStatus.REJECTED;
        }
        proposal.status = ProposalStatus.EXECUTED; // Mark as executed regardless of outcome
        emit MembershipProposalProcessed(_proposalId, proposal.status);
    }

    /// @notice Allows DAO governance to revoke membership from an address.
    /// @param _member Address of the member to revoke membership from.
    function revokeMembership(address _member) external onlyAdmin notPaused {
        require(isMember(_member), "Address is not a member.");
        members[_member].isActive = false;
        emit MembershipRevoked(_member, msg.sender);
    }

    /// @notice Returns details about a member, including their karma and join date.
    /// @param _member Address of the member.
    /// @return Member details (join date, karma score, isActive).
    function getMemberDetails(address _member) external view returns (uint256 joinDate, uint256 karmaScore, bool isActive) {
        require(isMember(_member), "Address is not a member.");
        return (members[_member].joinDate, members[_member].karmaScore, members[_member].isActive);
    }

    /// @notice Checks if an address is a member of the DAO.
    /// @param _account Address to check.
    /// @return True if the address is a member, false otherwise.
    function isMember(address _account) public view returns (bool) {
        return members[_account].isActive;
    }

    // --- 2. Project Funding Proposals ---

    /// @notice Members can submit proposals to fund creative projects.
    /// @param _projectName Name of the project.
    /// @param _projectDescription Description of the project.
    /// @param _fundingGoal Funding goal in Wei.
    /// @param _projectCreator Address of the project creator.
    function submitFundingProposal(string memory _projectName, string memory _projectDescription, uint256 _fundingGoal, address _projectCreator) external onlyMembers notPaused {
        require(_fundingGoal > 0, "Funding goal must be greater than zero.");
        fundingProposals[nextProposalId] = FundingProposal({
            proposalId: nextProposalId,
            proposalType: ProposalType.FUNDING,
            proposer: msg.sender,
            projectName: _projectName,
            projectDescription: _projectDescription,
            fundingGoal: _fundingGoal,
            projectCreator: _projectCreator,
            status: ProposalStatus.PENDING,
            projectStatus: ProjectStatus.PROPOSED,
            votingStartTime: 0,
            votingEndTime: 0,
            votesFor: 0,
            votesAgainst: 0,
            currentFunding: 0
        });
        emit FundingProposed(nextProposalId, msg.sender, _projectName, _fundingGoal, _projectCreator);
        nextProposalId++;
        fundingProposalCount++;
    }

    /// @notice Members vote on project funding proposals.
    /// @param _proposalId ID of the funding proposal.
    /// @param _support True for supporting the proposal, false for opposing.
    function voteOnFundingProposal(uint256 _proposalId, bool _support) external onlyMembers notPaused validProposalId(_proposalId) proposalExists(ProposalType.FUNDING, _proposalId) proposalInVoting(ProposalType.FUNDING, _proposalId) {
        require(fundingProposals[_proposalId].votingEndTime > block.timestamp, "Voting period has ended.");
        require(fundingProposals[_proposalId].status == ProposalStatus.ACTIVE_VOTING, "Voting is not active for this proposal.");

        if (_support) {
            fundingProposals[_proposalId].votesFor++;
        } else {
            fundingProposals[_proposalId].votesAgainst++;
        }
        emit FundingVoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Processes a funding proposal after voting period, transferring funds if approved.
    /// @param _proposalId ID of the funding proposal.
    function processFundingProposal(uint256 _proposalId) external onlyMembers notPaused validProposalId(_proposalId) proposalExists(ProposalType.FUNDING, _proposalId) {
        FundingProposal storage proposal = fundingProposals[_proposalId];
        require(proposal.status == ProposalStatus.ACTIVE_VOTING, "Proposal voting is not active or already processed.");
        require(proposal.votingEndTime <= block.timestamp, "Voting period has not ended yet.");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorum = (memberCount * quorumPercentage) / 100; // Quorum based on current member count

        if (totalVotes >= quorum && proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.PASSED;
            proposal.projectStatus = ProjectStatus.FUNDED;
        } else {
            proposal.status = ProposalStatus.REJECTED;
            proposal.projectStatus = ProjectStatus.FAILED;
        }
        proposal.status = ProposalStatus.EXECUTED; // Mark as executed regardless of outcome
        emit FundingProposalProcessed(_proposalId, proposal.status, proposal.projectStatus);
    }

    /// @notice Allows anyone (members and non-members) to contribute ETH to a funded project.
    /// @param _projectId ID of the project to contribute to.
    function contributeToProject(uint256 _projectId) external payable notPaused projectExists(_projectId) projectInFundedStatus(_projectId) {
        FundingProposal storage project = fundingProposals[_projectId];
        require(project.currentFunding < project.fundingGoal, "Project funding goal already reached.");

        uint256 contributionAmount = msg.value;
        project.currentFunding += contributionAmount;

        emit ProjectContribution(_projectId, msg.sender, contributionAmount);

        if (project.currentFunding >= project.fundingGoal) {
            project.projectStatus = ProjectStatus.FUNDED; // Mark as funded again if goal is reached through contribution
        }
    }

    /// @notice Project creator can withdraw funds once funding goal is reached and project is approved.
    /// @param _projectId ID of the project to withdraw funds from.
    function withdrawProjectFunds(uint256 _projectId) external notPaused projectExists(_projectId) projectInFundedStatus(_projectId) projectCreatorOnly(_projectId) {
        FundingProposal storage project = fundingProposals[_projectId];
        require(project.currentFunding >= project.fundingGoal, "Project funding goal not yet reached.");
        require(project.projectStatus == ProjectStatus.FUNDED, "Project is not in funded status.");

        uint256 amountToWithdraw = project.currentFunding;
        project.currentFunding = 0; // Reset project funding in contract after withdrawal

        payable(project.projectCreator).transfer(amountToWithdraw);
        emit ProjectFundsWithdrawn(_projectId, project.projectCreator, amountToWithdraw);
    }

    /// @notice Project creator can mark a funded project as complete, triggering potential rewards (future feature).
    /// @param _projectId ID of the project to mark as complete.
    function markProjectAsComplete(uint256 _projectId) external notPaused projectExists(_projectId) projectInFundedStatus(_projectId) projectCreatorOnly(_projectId) {
        FundingProposal storage project = fundingProposals[_projectId];
        require(project.projectStatus == ProjectStatus.FUNDED, "Project is not in funded status.");
        project.projectStatus = ProjectStatus.COMPLETED;
        emit ProjectMarkedComplete(_projectId, project.projectCreator);
        // Future: Implement reward mechanisms for completed projects (e.g., NFTs, karma boost).
    }

    /// @notice Returns details of a project funding proposal.
    /// @param _projectId ID of the project funding proposal.
    /// @return Project details (name, description, funding goal, creator, status, current funding).
    function getProjectDetails(uint256 _projectId) external view projectExists(_projectId) returns (string memory projectName, string memory projectDescription, uint256 fundingGoal, address projectCreator, ProjectStatus projectStatus, uint256 currentFunding) {
        FundingProposal storage project = fundingProposals[_projectId];
        return (project.projectName, project.projectDescription, project.fundingGoal, project.projectCreator, project.projectStatus, project.currentFunding);
    }

    /// @notice Returns the current status of a project (proposed, funded, completed, failed).
    /// @param _projectId ID of the project.
    /// @return Project status enum.
    function getProjectStatus(uint256 _projectId) external view projectExists(_projectId) returns (ProjectStatus) {
        return fundingProposals[_projectId].projectStatus;
    }


    // --- 3. Governance and Rules ---

    /// @notice Members can propose changes to the DAO's rules or constitution.
    /// @param _ruleDescription Description of the rule change.
    /// @param _proposedRule The proposed new rule text.
    function submitRuleChangeProposal(string memory _ruleDescription, string memory _proposedRule) external onlyMembers notPaused {
        ruleChangeProposals[nextProposalId] = RuleChangeProposal({
            proposalId: nextProposalId,
            proposalType: ProposalType.RULE_CHANGE,
            proposer: msg.sender,
            ruleDescription: _ruleDescription,
            proposedRule: _proposedRule,
            status: ProposalStatus.PENDING,
            votingStartTime: 0,
            votingEndTime: 0,
            votesFor: 0,
            votesAgainst: 0
        });
        emit RuleChangeProposed(nextProposalId, msg.sender, _ruleDescription, _proposedRule);
        nextProposalId++;
        ruleChangeProposalCount++;
    }

    /// @notice Members vote on rule change proposals.
    /// @param _proposalId ID of the rule change proposal.
    /// @param _support True for supporting the proposal, false for opposing.
    function voteOnRuleChangeProposal(uint256 _proposalId, bool _support) external onlyMembers notPaused validProposalId(_proposalId) proposalExists(ProposalType.RULE_CHANGE, _proposalId) proposalInVoting(ProposalType.RULE_CHANGE, _proposalId) {
        require(ruleChangeProposals[_proposalId].votingEndTime > block.timestamp, "Voting period has ended.");
        require(ruleChangeProposals[_proposalId].status == ProposalStatus.ACTIVE_VOTING, "Voting is not active for this proposal.");

        if (_support) {
            ruleChangeProposals[_proposalId].votesFor++;
        } else {
            ruleChangeProposals[_proposalId].votesAgainst++;
        }
        emit RuleChangeVoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Processes rule change proposals and updates the DAO rules if approved.
    /// @param _proposalId ID of the rule change proposal.
    function processRuleChangeProposal(uint256 _proposalId) external onlyMembers notPaused validProposalId(_proposalId) proposalExists(ProposalType.RULE_CHANGE, _proposalId) {
        RuleChangeProposal storage proposal = ruleChangeProposals[_proposalId];
        require(proposal.status == ProposalStatus.ACTIVE_VOTING, "Proposal voting is not active or already processed.");
        require(proposal.votingEndTime <= block.timestamp, "Voting period has not ended yet.");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorum = (memberCount * quorumPercentage) / 100; // Quorum based on current member count

        if (totalVotes >= quorum && proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.PASSED;
            daoRules = proposal.proposedRule; // Update DAO rules if proposal passes
            emit RuleChangeProposalProcessed(_proposalId, proposal.status, daoRules);
        } else {
            proposal.status = ProposalStatus.REJECTED;
            emit RuleChangeProposalProcessed(_proposalId, proposal.status, daoRules); // Rules remain unchanged
        }
        proposal.status = ProposalStatus.EXECUTED; // Mark as executed regardless of outcome
    }

    /// @notice Returns the current rules or constitution of the DAO.
    /// @return Current DAO rules string.
    function getCurrentRules() external view returns (string memory) {
        return daoRules;
    }

    /// @notice Admin function to set the default voting duration for proposals.
    /// @param _durationInSeconds Voting duration in seconds.
    function setVotingDuration(uint256 _durationInSeconds) external onlyAdmin notPaused {
        require(_durationInSeconds > 0, "Voting duration must be greater than zero.");
        votingDuration = _durationInSeconds;
    }

    /// @notice Admin function to set the quorum percentage required for proposals to pass.
    /// @param _quorumPercentage Quorum percentage (e.g., 50 for 50%).
    function setQuorum(uint256 _quorumPercentage) external onlyAdmin notPaused {
        require(_quorumPercentage <= 100 && _quorumPercentage > 0, "Quorum percentage must be between 1 and 100.");
        quorumPercentage = _quorumPercentage;
    }


    // --- 4. Karma and Reputation System (Basic) ---

    /// @notice Admin/DAO-controlled function to award karma points to members for contributions.
    /// @param _member Address of the member to award karma to.
    /// @param _karmaPoints Number of karma points to award.
    /// @param _reason Reason for awarding karma.
    function awardKarma(address _member, uint256 _karmaPoints, string memory _reason) external onlyAdmin notPaused {
        require(isMember(_member), "Address is not a member.");
        members[_member].karmaScore += _karmaPoints;
        emit KarmaAwarded(_member, _karmaPoints, _reason);
    }

    /// @notice Returns the karma score of a member.
    /// @param _member Address of the member.
    /// @return Karma score of the member.
    function getKarmaScore(address _member) external view returns (uint256) {
        require(isMember(_member), "Address is not a member.");
        return members[_member].karmaScore;
    }

    // --- 5. Emergency and Utility Functions ---

    /// @notice Admin function to pause the contract in case of emergency or critical issues.
    function pauseContract() external onlyAdmin {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Admin function to unpause the contract.
    function unpauseContract() external onlyAdmin {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Admin function for emergency fund withdrawal to a specified address.
    /// @param _recipient Address to receive the withdrawn funds.
    /// @param _amount Amount to withdraw in Wei.
    function emergencyWithdraw(address payable _recipient, uint256 _amount) external onlyAdmin {
        require(_amount <= address(this).balance, "Withdrawal amount exceeds contract balance.");
        payable(_recipient).transfer(_amount);
        emit EmergencyWithdrawal(_recipient, _amount, msg.sender);
    }

    /// @notice Returns the current ETH balance of the contract.
    /// @return Contract balance in Wei.
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // --- Internal Helper Functions ---

    function _addMember(address _newMember) internal {
        if (!isMember(_newMember)) {
            members[_newMember] = Member({
                memberAddress: _newMember,
                joinDate: block.timestamp,
                karmaScore: 0,
                isActive: true
            });
            memberList.push(_newMember);
            memberCount++;
        }
    }

    /// @dev Function to start voting for a proposal. Can be called by anyone (permissionless proposal activation).
    /// @param _proposalType Type of proposal (MEMBERSHIP, FUNDING, RULE_CHANGE).
    /// @param _proposalId ID of the proposal to activate voting for.
    function startVoting(ProposalType _proposalType, uint256 _proposalId) external notPaused validProposalId(_proposalId) proposalExists(_proposalType, _proposalId) {
        ProposalStatus currentStatus;
        if (_proposalType == ProposalType.MEMBERSHIP) {
            currentStatus = membershipProposals[_proposalId].status;
            require(currentStatus == ProposalStatus.PENDING, "Membership proposal voting already started or processed.");
            membershipProposals[_proposalId].status = ProposalStatus.ACTIVE_VOTING;
            membershipProposals[_proposalId].votingStartTime = block.timestamp;
            membershipProposals[_proposalId].votingEndTime = block.timestamp + votingDuration;
        } else if (_proposalType == ProposalType.FUNDING) {
            currentStatus = fundingProposals[_proposalId].status;
            require(currentStatus == ProposalStatus.PENDING, "Funding proposal voting already started or processed.");
            fundingProposals[_proposalId].status = ProposalStatus.ACTIVE_VOTING;
            fundingProposals[_proposalId].votingStartTime = block.timestamp;
            fundingProposals[_proposalId].votingEndTime = block.timestamp + votingDuration;
        } else if (_proposalType == ProposalType.RULE_CHANGE) {
            currentStatus = ruleChangeProposals[_proposalId].status;
            require(currentStatus == ProposalStatus.PENDING, "Rule change proposal voting already started or processed.");
            ruleChangeProposals[_proposalId].status = ProposalStatus.ACTIVE_VOTING;
            ruleChangeProposals[_proposalId].votingStartTime = block.timestamp;
            ruleChangeProposals[_proposalId].votingEndTime = block.timestamp + votingDuration;
        } else {
            revert("Invalid proposal type.");
        }
        // No specific event emitted for startVoting to keep events focused on core actions.
        // Consider adding events if needed for off-chain monitoring of voting activation.
    }
}
```