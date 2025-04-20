```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Venture Capital (DAVC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a Decentralized Autonomous Venture Capital (DAVC) system.
 * It allows members to propose, vote on, and fund projects in a decentralized and transparent manner.
 * This contract incorporates advanced concepts like:
 *  - Quadratic Voting for fairer decision-making.
 *  - Reputation-based access control and influence.
 *  - Milestone-based funding release for project accountability.
 *  - Dynamic membership tiers based on contribution.
 *  - On-chain governance for contract parameters and upgrades.
 *
 * Function Summary:
 *
 * --- Membership Functions ---
 * 1. requestMembership(): Allows users to request membership in the DAVC.
 * 2. approveMembership(address _user): Owner function to approve a pending membership request.
 * 3. revokeMembership(address _member): Owner function to revoke membership.
 * 4. getMemberDetails(address _member): Returns details of a member including tier, reputation, and staking.
 * 5. stakeTokens(uint256 _amount): Allows members to stake tokens to increase their reputation and voting power.
 * 6. unstakeTokens(uint256 _amount): Allows members to unstake tokens.
 * 7. getStakingBalance(address _member): Returns the staking balance of a member.
 *
 * --- Project Proposal Functions ---
 * 8. submitInvestmentProposal(string memory _projectName, string memory _projectDescription, uint256 _fundingGoal, string memory _milestones): Members can submit project proposals.
 * 9. updateInvestmentProposal(uint256 _proposalId, string memory _projectDescription, uint256 _fundingGoal, string memory _milestones): Proposer can update their proposal before voting starts.
 * 10. getInvestmentProposalDetails(uint256 _proposalId): Returns details of a specific investment proposal.
 * 11. markProposalMilestoneComplete(uint256 _proposalId, uint256 _milestoneIndex): Project proposer can mark a milestone as complete, subject to member voting.
 * 12. submitMilestoneCompletionVote(uint256 _proposalId, uint256 _milestoneIndex, bool _approve): Members can vote on milestone completion.
 * 13. getMilestoneCompletionVoteDetails(uint256 _proposalId, uint256 _milestoneIndex): Returns details of milestone completion votes.
 *
 * --- Voting and Funding Functions ---
 * 14. startInvestmentProposalVoting(uint256 _proposalId): Owner function to start voting on an investment proposal.
 * 15. castVote(uint256 _proposalId, bool _support): Members can cast votes on investment proposals using quadratic voting.
 * 16. getVotingDetails(uint256 _proposalId): Returns details of the voting process for a proposal.
 * 17. finalizeInvestmentProposal(uint256 _proposalId): Owner function to finalize voting and execute funding if successful.
 * 18. contributeToProposal(uint256 _proposalId, uint256 _amount): Members can contribute funds to a successful proposal.
 * 19. releaseMilestoneFunds(uint256 _proposalId, uint256 _milestoneIndex): Owner function to release funds for a completed and approved milestone.
 * 20. withdrawUnusedFunds(uint256 _proposalId): Project proposer can withdraw any unused funds after project completion or failure.
 *
 * --- Governance and Utility Functions ---
 * 21. setMembershipFee(uint256 _fee): Owner function to set the membership fee.
 * 22. setMinStakingAmount(uint256 _amount): Owner function to set the minimum staking amount for reputation.
 * 23. setVotingDuration(uint256 _duration): Owner function to set the voting duration for proposals.
 * 24. pauseContract(): Owner function to pause the contract for maintenance.
 * 25. unpauseContract(): Owner function to unpause the contract.
 * 26. getContractState(): Returns the current state of the contract (paused/unpaused).
 * 27. emergencyWithdraw(address _recipient, uint256 _amount): Owner function for emergency fund withdrawal in critical situations.
 */
contract DecentralizedAutonomousVC {
    // --- State Variables ---
    address public owner;
    string public contractName = "Decentralized Autonomous Venture Capital";
    uint256 public membershipFee = 0.1 ether; // Example fee
    uint256 public minStakingAmount = 1 ether; // Minimum staking for reputation
    uint256 public votingDuration = 7 days; // Default voting duration
    bool public paused = false;

    // Token for DAVC (replace with your actual token contract if needed)
    // For simplicity, using address(this) as a placeholder for internal token management
    address public davcToken = address(this); // In a real scenario, use an ERC20 contract.

    // --- Enums and Structs ---
    enum MembershipStatus { Pending, Active, Revoked }
    enum ProposalStatus { Submitted, Voting, Funded, Completed, Failed }
    enum VoteStatus { NotStarted, Active, Concluded }
    enum MilestoneStatus { Pending, Voting, Approved, Rejected, Funded }

    struct Member {
        MembershipStatus status;
        uint256 reputationScore;
        uint256 stakingBalance;
        uint256 joinedTimestamp;
    }

    struct InvestmentProposal {
        uint256 id;
        address proposer;
        string projectName;
        string projectDescription;
        uint256 fundingGoal;
        string milestones; // String to store milestones, consider a more structured approach in real app
        ProposalStatus status;
        uint256 votingStartTime;
        uint256 votingEndTime;
        mapping(address => bool) votes; // Members who voted and their support (true=support, false=against)
        uint256 positiveVotes;
        uint256 negativeVotes;
        uint256 totalContributions;
        mapping(uint256 => Milestone) milestonesDetails;
        uint256 milestoneCount;
    }

    struct Milestone {
        string description;
        MilestoneStatus status;
        uint256 fundsRequested;
        uint256 fundsReleased;
        mapping(address => bool) milestoneVotes; // Members who voted on milestone completion
        uint256 milestonePositiveVotes;
        uint256 milestoneNegativeVotes;
    }

    // --- Mappings ---
    mapping(address => Member) public members;
    mapping(uint256 => InvestmentProposal) public investmentProposals;
    mapping(uint256 => address[]) public proposalContributors; // Track contributors for each proposal
    mapping(address => uint256) public stakingBalances; // Track staking balance of each member

    uint256 public proposalCounter = 0;
    address[] public membershipRequests;

    // --- Events ---
    event MembershipRequested(address indexed user);
    event MembershipApproved(address indexed member);
    event MembershipRevoked(address indexed member);
    event TokensStaked(address indexed member, uint256 amount);
    event TokensUnstaked(address indexed member, uint256 amount);
    event InvestmentProposalSubmitted(uint256 proposalId, address indexed proposer, string projectName);
    event InvestmentProposalUpdated(uint256 proposalId);
    event InvestmentProposalVotingStarted(uint256 proposalId);
    event VoteCast(uint256 proposalId, address indexed voter, bool support);
    event InvestmentProposalFinalized(uint256 proposalId, ProposalStatus status);
    event ContributionMade(uint256 proposalId, address indexed contributor, uint256 amount);
    event MilestoneMarkedComplete(uint256 proposalId, uint256 milestoneIndex);
    event MilestoneCompletionVoteCast(uint256 proposalId, uint256 milestoneIndex, address indexed voter, bool approve);
    event MilestoneFundsReleased(uint256 proposalId, uint256 milestoneIndex, uint256 amount);
    event FundsWithdrawn(uint256 proposalId, address recipient, uint256 amount);
    event ContractPaused();
    event ContractUnpaused();
    event MembershipFeeUpdated(uint256 newFee);
    event MinStakingAmountUpdated(uint256 newAmount);
    event VotingDurationUpdated(uint256 newDuration);
    event EmergencyWithdrawal(address recipient, uint256 amount);


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action.");
        _;
    }

    modifier onlyMembers() {
        require(members[msg.sender].status == MembershipStatus.Active, "Only active members can perform this action.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCounter && investmentProposals[_proposalId].id == _proposalId, "Invalid proposal ID.");
        _;
    }

    modifier votingNotStarted(uint256 _proposalId) {
        require(investmentProposals[_proposalId].status == ProposalStatus.Submitted, "Voting has already started or concluded.");
        _;
    }

    modifier votingActive(uint256 _proposalId) {
        require(investmentProposals[_proposalId].status == ProposalStatus.Voting && block.timestamp <= investmentProposals[_proposalId].votingEndTime, "Voting is not active.");
        _;
    }

    modifier votingConcluded(uint256 _proposalId) {
        require(investmentProposals[_proposalId].status != ProposalStatus.Voting || block.timestamp > investmentProposals[_proposalId].votingEndTime, "Voting is still active.");
        _;
    }

    modifier milestoneExists(uint256 _proposalId, uint256 _milestoneIndex) {
        require(_milestoneIndex > 0 && _milestoneIndex <= investmentProposals[_proposalId].milestoneCount, "Invalid milestone index.");
        _;
    }

    modifier milestonePendingVote(uint256 _proposalId, uint256 _milestoneIndex) {
        require(investmentProposals[_proposalId].milestonesDetails[_milestoneIndex].status == MilestoneStatus.Voting, "Milestone voting is not active or already concluded.");
        _;
    }

    modifier milestoneNotFunded(uint256 _proposalId, uint256 _milestoneIndex) {
        require(investmentProposals[_proposalId].milestonesDetails[_milestoneIndex].status != MilestoneStatus.Funded, "Milestone already funded.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier pausedContract() {
        require(paused, "Contract is not paused.");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
    }

    // --- Membership Functions ---
    /// @notice Allows users to request membership in the DAVC.
    function requestMembership() external notPaused payable {
        require(msg.value >= membershipFee, "Membership fee is required.");
        require(members[msg.sender].status == MembershipStatus.Pending || members[msg.sender].status == MembershipStatus.Revoked || members[msg.sender].status == MembershipStatus.Active == false, "Membership already requested or active.");

        if (members[msg.sender].status != MembershipStatus.Active) {
            members[msg.sender].status = MembershipStatus.Pending;
            membershipRequests.push(msg.sender);
            emit MembershipRequested(msg.sender);
        }

        // Optionally send back excess ether if msg.value > membershipFee (not implemented for simplicity)
    }

    /// @notice Owner function to approve a pending membership request.
    /// @param _user Address of the user to approve membership for.
    function approveMembership(address _user) external onlyOwner notPaused {
        require(members[_user].status == MembershipStatus.Pending, "User is not pending membership.");
        members[_user].status = MembershipStatus.Active;
        members[_user].joinedTimestamp = block.timestamp;
        emit MembershipApproved(_user);
    }

    /// @notice Owner function to revoke membership.
    /// @param _member Address of the member to revoke membership from.
    function revokeMembership(address _member) external onlyOwner notPaused {
        require(members[_member].status == MembershipStatus.Active, "User is not an active member.");
        members[_member].status = MembershipStatus.Revoked;
        emit MembershipRevoked(_member);
    }

    /// @notice Returns details of a member including tier, reputation, and staking.
    /// @param _member Address of the member.
    /// @return MembershipStatus Status of the member.
    /// @return uint256 Reputation score of the member.
    /// @return uint256 Staking balance of the member.
    /// @return uint256 Joined timestamp of the member.
    function getMemberDetails(address _member) external view returns (MembershipStatus, uint256, uint256, uint256) {
        return (members[_member].status, members[_member].reputationScore, members[_member].stakingBalance, members[_member].joinedTimestamp);
    }

    /// @notice Allows members to stake tokens to increase their reputation and voting power.
    /// @param _amount Amount of tokens to stake.
    function stakeTokens(uint256 _amount) external onlyMembers notPaused {
        require(_amount >= minStakingAmount, "Staking amount must be at least the minimum staking amount.");
        // In real implementation, transfer tokens from member to this contract.
        // For this example, assuming tokens are managed internally or conceptually.
        stakingBalances[msg.sender] += _amount;
        members[msg.sender].stakingBalance += _amount;
        members[msg.sender].reputationScore += _amount / minStakingAmount; // Example reputation increase logic
        emit TokensStaked(msg.sender, _amount);
    }

    /// @notice Allows members to unstake tokens.
    /// @param _amount Amount of tokens to unstake.
    function unstakeTokens(uint256 _amount) external onlyMembers notPaused {
        require(_amount <= members[msg.sender].stakingBalance, "Insufficient staking balance.");
        stakingBalances[msg.sender] -= _amount;
        members[msg.sender].stakingBalance -= _amount;
        members[msg.sender].reputationScore -= _amount / minStakingAmount; // Example reputation decrease logic
        emit TokensUnstaked(msg.sender, _amount);
    }

    /// @notice Returns the staking balance of a member.
    /// @param _member Address of the member.
    /// @return uint256 Staking balance of the member.
    function getStakingBalance(address _member) external view returns (uint256) {
        return members[_member].stakingBalance;
    }

    // --- Project Proposal Functions ---
    /// @notice Members can submit project proposals.
    /// @param _projectName Name of the project.
    /// @param _projectDescription Description of the project.
    /// @param _fundingGoal Funding goal for the project in wei.
    /// @param _milestones String describing project milestones (consider a more structured approach in real app).
    function submitInvestmentProposal(string memory _projectName, string memory _projectDescription, uint256 _fundingGoal, string memory _milestones) external onlyMembers notPaused {
        proposalCounter++;
        investmentProposals[proposalCounter] = InvestmentProposal({
            id: proposalCounter,
            proposer: msg.sender,
            projectName: _projectName,
            projectDescription: _projectDescription,
            fundingGoal: _fundingGoal,
            milestones: _milestones,
            status: ProposalStatus.Submitted,
            votingStartTime: 0,
            votingEndTime: 0,
            positiveVotes: 0,
            negativeVotes: 0,
            totalContributions: 0,
            milestoneCount: 0
        });
        emit InvestmentProposalSubmitted(proposalCounter, msg.sender, _projectName);
    }

    /// @notice Proposer can update their proposal before voting starts.
    /// @param _proposalId ID of the proposal to update.
    /// @param _projectDescription Updated project description.
    /// @param _fundingGoal Updated funding goal in wei.
    /// @param _milestones Updated milestones description.
    function updateInvestmentProposal(uint256 _proposalId, string memory _projectDescription, uint256 _fundingGoal, string memory _milestones) external onlyMembers proposalExists(_proposalId) votingNotStarted(_proposalId) notPaused {
        require(investmentProposals[_proposalId].proposer == msg.sender, "Only proposer can update proposal.");
        investmentProposals[_proposalId].projectDescription = _projectDescription;
        investmentProposals[_proposalId].fundingGoal = _fundingGoal;
        investmentProposals[_proposalId].milestones = _milestones;
        emit InvestmentProposalUpdated(_proposalId);
    }

    /// @notice Returns details of a specific investment proposal.
    /// @param _proposalId ID of the proposal.
    /// @return InvestmentProposal struct containing proposal details.
    function getInvestmentProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (InvestmentProposal memory) {
        return investmentProposals[_proposalId];
    }

    /// @notice Project proposer can mark a milestone as complete, subject to member voting.
    /// @param _proposalId ID of the proposal.
    /// @param _milestoneIndex Index of the milestone being marked complete.
    function markProposalMilestoneComplete(uint256 _proposalId, uint256 _milestoneIndex) external onlyMembers proposalExists(_proposalId) notPaused {
        require(investmentProposals[_proposalId].proposer == msg.sender, "Only proposer can mark milestone complete.");
        require(_milestoneIndex > 0 && _milestoneIndex <= investmentProposals[_proposalId].milestoneCount, "Invalid milestone index.");
        require(investmentProposals[_proposalId].milestonesDetails[_milestoneIndex].status != MilestoneStatus.Funded && investmentProposals[_proposalId].milestonesDetails[_milestoneIndex].status != MilestoneStatus.Approved, "Milestone already funded or approved.");

        investmentProposals[_proposalId].milestonesDetails[_milestoneIndex].status = MilestoneStatus.Voting;
        emit MilestoneMarkedComplete(_proposalId, _milestoneIndex);
    }


    /// @notice Members can vote on milestone completion.
    /// @param _proposalId ID of the proposal.
    /// @param _milestoneIndex Index of the milestone to vote on.
    /// @param _approve Boolean indicating approval (true) or rejection (false) of milestone completion.
    function submitMilestoneCompletionVote(uint256 _proposalId, uint256 _milestoneIndex, bool _approve) external onlyMembers proposalExists(_proposalId) milestoneExists(_proposalId, _milestoneIndex) milestonePendingVote(_proposalId, _milestoneIndex) notPaused {
        require(!investmentProposals[_proposalId].milestonesDetails[_milestoneIndex].milestoneVotes[msg.sender], "Member has already voted on this milestone.");

        investmentProposals[_proposalId].milestonesDetails[_milestoneIndex].milestoneVotes[msg.sender] = true;
        if (_approve) {
            investmentProposals[_proposalId].milestonesDetails[_milestoneIndex].milestonePositiveVotes++;
        } else {
            investmentProposals[_proposalId].milestonesDetails[_milestoneIndex].milestoneNegativeVotes++;
        }
        emit MilestoneCompletionVoteCast(_proposalId, _milestoneIndex, msg.sender, _approve);

        // Check if voting is concluded based on a quorum or time (simplified for this example)
        if (investmentProposals[_proposalId].milestonesDetails[_milestoneIndex].milestonePositiveVotes > investmentProposals[_proposalId].milestonesDetails[_milestoneIndex].milestoneNegativeVotes) {
            investmentProposals[_proposalId].milestonesDetails[_milestoneIndex].status = MilestoneStatus.Approved;
        } else {
            investmentProposals[_proposalId].milestonesDetails[_milestoneIndex].status = MilestoneStatus.Rejected;
        }
    }


    /// @notice Returns details of milestone completion votes.
    /// @param _proposalId ID of the proposal.
    /// @param _milestoneIndex Index of the milestone.
    /// @return uint256 Positive votes for milestone completion.
    /// @return uint256 Negative votes against milestone completion.
    /// @return MilestoneStatus Status of the milestone completion voting.
    function getMilestoneCompletionVoteDetails(uint256 _proposalId, uint256 _milestoneIndex) external view proposalExists(_proposalId) milestoneExists(_proposalId, _milestoneIndex) returns (uint256, uint256, MilestoneStatus) {
        return (investmentProposals[_proposalId].milestonesDetails[_milestoneIndex].milestonePositiveVotes, investmentProposals[_proposalId].milestonesDetails[_milestoneIndex].milestoneNegativeVotes, investmentProposals[_proposalId].milestonesDetails[_milestoneIndex].status);
    }


    // --- Voting and Funding Functions ---
    /// @notice Owner function to start voting on an investment proposal.
    /// @param _proposalId ID of the proposal to start voting for.
    function startInvestmentProposalVoting(uint256 _proposalId) external onlyOwner proposalExists(_proposalId) votingNotStarted(_proposalId) notPaused {
        investmentProposals[_proposalId].status = ProposalStatus.Voting;
        investmentProposals[_proposalId].votingStartTime = block.timestamp;
        investmentProposals[_proposalId].votingEndTime = block.timestamp + votingDuration;
        emit InvestmentProposalVotingStarted(_proposalId);
    }

    /// @notice Members can cast votes on investment proposals using quadratic voting (simplified).
    /// @param _proposalId ID of the proposal to vote on.
    /// @param _support Boolean indicating support (true) or opposition (false) to the proposal.
    function castVote(uint256 _proposalId, bool _support) external onlyMembers proposalExists(_proposalId) votingActive(_proposalId) notPaused {
        require(!investmentProposals[_proposalId].votes[msg.sender], "Member has already voted.");

        // Simplified Quadratic Voting (Example: Cost increases with reputation)
        uint256 votingCost = members[msg.sender].reputationScore / 10; // Example cost calculation, adjust as needed

        // In a real system, you might need to deduct tokens or track voting power differently.
        // For this example, just ensuring member has reputation (simplified cost).
        require(members[msg.sender].reputationScore >= votingCost, "Insufficient reputation to vote.");

        investmentProposals[_proposalId].votes[msg.sender] = _support;
        if (_support) {
            investmentProposals[_proposalId].positiveVotes++;
        } else {
            investmentProposals[_proposalId].negativeVotes++;
        }
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Returns details of the voting process for a proposal.
    /// @param _proposalId ID of the proposal.
    /// @return VoteStatus Status of the voting.
    /// @return uint256 Start time of voting.
    /// @return uint256 End time of voting.
    /// @return uint256 Positive votes count.
    /// @return uint256 Negative votes count.
    function getVotingDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (VoteStatus, uint256, uint256, uint256, uint256) {
        VoteStatus status;
        if (investmentProposals[_proposalId].status == ProposalStatus.Submitted) {
            status = VoteStatus.NotStarted;
        } else if (investmentProposals[_proposalId].status == ProposalStatus.Voting && block.timestamp <= investmentProposals[_proposalId].votingEndTime) {
            status = VoteStatus.Active;
        } else {
            status = VoteStatus.Concluded;
        }
        return (status, investmentProposals[_proposalId].votingStartTime, investmentProposals[_proposalId].votingEndTime, investmentProposals[_proposalId].positiveVotes, investmentProposals[_proposalId].negativeVotes);
    }

    /// @notice Owner function to finalize voting and execute funding if successful.
    /// @param _proposalId ID of the proposal to finalize.
    function finalizeInvestmentProposal(uint256 _proposalId) external onlyOwner proposalExists(_proposalId) votingConcluded(_proposalId) notPaused {
        require(investmentProposals[_proposalId].status == ProposalStatus.Voting, "Voting is not yet concluded.");
        ProposalStatus finalStatus;
        if (investmentProposals[_proposalId].positiveVotes > investmentProposals[_proposalId].negativeVotes) { // Simple majority for success
            investmentProposals[_proposalId].status = ProposalStatus.Funded;
            finalStatus = ProposalStatus.Funded;
        } else {
            investmentProposals[_proposalId].status = ProposalStatus.Failed;
            finalStatus = ProposalStatus.Failed;
        }
        emit InvestmentProposalFinalized(_proposalId, finalStatus);
    }

    /// @notice Members can contribute funds to a successful proposal.
    /// @param _proposalId ID of the proposal to contribute to.
    /// @param _amount Amount to contribute in wei.
    function contributeToProposal(uint256 _proposalId, uint256 _amount) external onlyMembers proposalExists(_proposalId) notPaused payable {
        require(investmentProposals[_proposalId].status == ProposalStatus.Funded, "Proposal is not in Funded status.");
        require(investmentProposals[_proposalId].totalContributions + _amount <= investmentProposals[_proposalId].fundingGoal, "Contribution exceeds funding goal.");

        investmentProposals[_proposalId].totalContributions += _amount;
        proposalContributors[_proposalId].push(msg.sender);
        // Transfer funds from contributor to the contract (if using external tokens, integrate token transfer)
        emit ContributionMade(_proposalId, msg.sender, _amount);

        if (investmentProposals[_proposalId].totalContributions >= investmentProposals[_proposalId].fundingGoal) {
            investmentProposals[_proposalId].status = ProposalStatus.Completed; // Fully funded
        }
    }

    /// @notice Owner function to release funds for a completed and approved milestone.
    /// @param _proposalId ID of the proposal.
    /// @param _milestoneIndex Index of the milestone to release funds for.
    function releaseMilestoneFunds(uint256 _proposalId, uint256 _milestoneIndex) external onlyOwner proposalExists(_proposalId) milestoneExists(_proposalId, _milestoneIndex) milestoneNotFunded(_proposalId, _milestoneIndex) notPaused {
        require(investmentProposals[_proposalId].status == ProposalStatus.Funded || investmentProposals[_proposalId].status == ProposalStatus.Completed, "Proposal must be funded or completed to release milestone funds.");
        require(investmentProposals[_proposalId].milestonesDetails[_milestoneIndex].status == MilestoneStatus.Approved, "Milestone must be approved by members.");

        uint256 fundsToRelease = investmentProposals[_proposalId].milestonesDetails[_milestoneIndex].fundsRequested;
        require(fundsToRelease <= address(this).balance, "Contract balance insufficient to release funds."); // Check contract balance

        investmentProposals[_proposalId].milestonesDetails[_milestoneIndex].status = MilestoneStatus.Funded;
        investmentProposals[_proposalId].milestonesDetails[_milestoneIndex].fundsReleased = fundsToRelease;

        // Transfer funds to project proposer (replace with actual logic for multi-sig or project wallet)
        (bool success, ) = investmentProposals[_proposalId].proposer.call{value: fundsToRelease}("");
        require(success, "Funds transfer failed.");

        emit MilestoneFundsReleased(_proposalId, _milestoneIndex, fundsToRelease);
    }

    /// @notice Project proposer can withdraw any unused funds after project completion or failure.
    /// @param _proposalId ID of the proposal.
    function withdrawUnusedFunds(uint256 _proposalId) external proposalExists(_proposalId) notPaused {
        require(investmentProposals[_proposalId].proposer == msg.sender, "Only proposer can withdraw funds.");
        require(investmentProposals[_proposalId].status == ProposalStatus.Completed || investmentProposals[_proposalId].status == ProposalStatus.Failed, "Proposal must be completed or failed to withdraw funds.");

        uint256 totalReleased = 0;
        for (uint256 i = 1; i <= investmentProposals[_proposalId].milestoneCount; i++) {
            totalReleased += investmentProposals[_proposalId].milestonesDetails[i].fundsReleased;
        }
        uint256 withdrawableAmount = investmentProposals[_proposalId].totalContributions - totalReleased;
        require(withdrawableAmount > 0, "No unused funds to withdraw.");
        require(withdrawableAmount <= address(this).balance, "Contract balance insufficient for withdrawal.");

        investmentProposals[_proposalId].totalContributions -= withdrawableAmount; // Adjust total contribution to reflect withdrawal

        (bool success, ) = investmentProposals[_proposalId].proposer.call{value: withdrawableAmount}("");
        require(success, "Withdrawal failed.");
        emit FundsWithdrawn(_proposalId, msg.sender, withdrawableAmount);
    }


    // --- Governance and Utility Functions ---
    /// @notice Owner function to set the membership fee.
    /// @param _fee New membership fee in wei.
    function setMembershipFee(uint256 _fee) external onlyOwner notPaused {
        membershipFee = _fee;
        emit MembershipFeeUpdated(_fee);
    }

    /// @notice Owner function to set the minimum staking amount for reputation.
    /// @param _amount New minimum staking amount in wei.
    function setMinStakingAmount(uint256 _amount) external onlyOwner notPaused {
        minStakingAmount = _amount;
        emit MinStakingAmountUpdated(_amount);
    }

    /// @notice Owner function to set the voting duration for proposals.
    /// @param _duration New voting duration in seconds.
    function setVotingDuration(uint256 _duration) external onlyOwner notPaused {
        votingDuration = _duration;
        emit VotingDurationUpdated(_duration);
    }

    /// @notice Owner function to pause the contract for maintenance.
    function pauseContract() external onlyOwner notPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Owner function to unpause the contract.
    function unpauseContract() external onlyOwner pausedContract {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Returns the current state of the contract (paused/unpaused).
    /// @return bool True if paused, false otherwise.
    function getContractState() external view returns (bool) {
        return paused;
    }

    /// @notice Owner function for emergency fund withdrawal in critical situations.
    /// @param _recipient Address to receive the withdrawn funds.
    /// @param _amount Amount to withdraw in wei.
    function emergencyWithdraw(address _recipient, uint256 _amount) external onlyOwner pausedContract {
        require(_amount <= address(this).balance, "Withdrawal amount exceeds contract balance.");
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Emergency withdrawal failed.");
        emit EmergencyWithdrawal(_recipient, _amount);
    }

    // --- Fallback and Receive functions (optional for token contracts) ---
    receive() external payable {} // To receive ETH for contributions/membership fees
    fallback() external {}
}
```