```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Research Organization (DARO) Smart Contract
 * @author Bard (Example - Conceptual and for demonstration purposes only)
 *
 * @notice This contract implements a Decentralized Autonomous Research Organization (DARO)
 *         allowing for collaborative research funding, proposal submission, voting,
 *         knowledge sharing, reputation building, and decentralized governance.
 *         It incorporates advanced concepts like dynamic membership, quadratic voting,
 *         reputation-based rewards, and on-chain data storage for research artifacts.
 *
 * @dev **Function Summary:**
 *
 * **Member Management:**
 *   1.  `requestMembership()`: Allows users to request membership in the DARO.
 *   2.  `approveMembership(address _member)`:  Admin function to approve membership requests.
 *   3.  `revokeMembership(address _member)`: Admin function to revoke membership.
 *   4.  `getMembers()`: Returns a list of current DARO members.
 *   5.  `getMemberDetails(address _member)`:  Returns details about a specific member (reputation, join date).
 *
 * **Proposal Management:**
 *   6.  `submitResearchProposal(string memory _title, string memory _description, uint256 _fundingGoal, string memory _ipfsHashForDetails)`: Members can submit research proposals.
 *   7.  `voteOnProposal(uint256 _proposalId, bool _support)`: Members can vote on research proposals using quadratic voting (simplified).
 *   8.  `finalizeProposal(uint256 _proposalId)`:  Admin/governance function to finalize a proposal after voting period.
 *   9.  `getProposalDetails(uint256 _proposalId)`:  Retrieves details of a specific research proposal.
 *   10. `getProposalStatus(uint256 _proposalId)`:  Returns the current status of a proposal.
 *   11. `cancelProposal(uint256 _proposalId)`: Proposal submitter or admin can cancel a proposal before funding.
 *
 * **Funding & Treasury:**
 *   12. `fundProposal(uint256 _proposalId)`:  Allows anyone to contribute funds to a research proposal.
 *   13. `withdrawProposalFunds(uint256 _proposalId)`:  Proposal owner can withdraw funds after proposal approval and completion (with milestones ideally).
 *   14. `getTreasuryBalance()`: Returns the current balance of the DARO treasury.
 *   15. `getProposalFundingStatus(uint256 _proposalId)`: Returns the current funding status of a proposal.
 *
 * **Reputation & Rewards:**
 *   16. `contributeToResearch(uint256 _proposalId, string memory _ipfsHashForContribution)`: Members can submit research contributions to approved proposals.
 *   17. `reportResearchMilestone(uint256 _proposalId, string memory _milestoneDescription, string memory _ipfsHashForMilestone)`: Proposal owner can report a milestone completion.
 *   18. `approveResearchMilestone(uint256 _proposalId, uint256 _milestoneIndex)`: Members can vote to approve a reported milestone.
 *   19. `rewardContributors(uint256 _proposalId)`:  Admin/governance function to distribute rewards to contributors based on reputation and contribution quality (simplified).
 *   20. `penalizeMember(address _member, uint256 _penaltyPoints)`: Admin function to penalize members for misconduct, reducing reputation.
 *   21. `adjustReputation(address _member, int256 _reputationChange)`: Admin function to manually adjust member reputation.
 *   22. `getMemberReputation(address _member)`: Returns the reputation score of a member.
 *
 * **Governance & Settings:**
 *   23. `changeVotingDuration(uint256 _newDuration)`: Admin function to change the default voting duration for proposals.
 *   24. `changeProposalThreshold(uint256 _newThreshold)`: Admin function to change the required quorum for proposal approval.
 *   25. `pauseContract()`: Admin function to pause core functionalities in case of emergency.
 *   26. `unpauseContract()`: Admin function to resume contract functionalities.
 *   27. `setAdmin(address _newAdmin)`: Owner function to change the contract admin.
 *
 * **Utility Functions:**
 *   28. `getVersion()`: Returns the contract version.
 *
 * **Advanced Concepts Implemented:**
 *   - Decentralized Governance through voting and member approvals.
 *   - Dynamic Membership with request and approval process.
 *   - Quadratic Voting (simplified for demonstration).
 *   - On-chain Reputation System to track member contributions.
 *   - Decentralized Knowledge Sharing (using IPFS hash pointers).
 *   - Milestone-based research tracking.
 *   - Emergency Pause Functionality.
 */
contract DARO {

    // -------- State Variables --------

    address public owner; // Contract deployer
    address public admin; // Admin address for privileged functions
    uint256 public membershipFee = 0.1 ether; // Fee to request membership (can be zero)
    uint256 public votingDuration = 7 days; // Default voting duration for proposals
    uint256 public proposalThreshold = 50; // Percentage of votes needed for proposal approval
    bool public paused = false; // Contract pause state
    uint256 public contractVersion = 1;

    enum ProposalState { Pending, Voting, Approved, Funded, InProgress, Completed, Rejected, Cancelled }
    enum MilestoneState { PendingApproval, Approved, Rejected }

    struct Member {
        address memberAddress;
        uint256 reputation;
        uint256 joinTimestamp;
        bool isActive;
    }

    struct ResearchProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 fundingGoal;
        uint256 currentFunding;
        ProposalState state;
        uint256 votingEndTime;
        mapping(address => bool) votes; // Members who voted
        uint256 yesVotes;
        uint256 noVotes;
        string ipfsHashForDetails; // IPFS hash for detailed proposal document
        Milestone[] milestones;
        mapping(address => Contribution[]) contributions; // Contributions per member
    }

    struct Milestone {
        string description;
        string ipfsHashForMilestone;
        MilestoneState state;
        uint256 approvalVotes;
        uint256 rejectionVotes;
        uint256 deadline; // Optional deadline for milestone completion
    }

    struct Contribution {
        string ipfsHashForContribution;
        uint256 timestamp;
    }

    mapping(address => Member) public members;
    address[] public memberList;
    uint256 public memberCount = 0;
    uint256 public nextProposalId = 1;
    mapping(uint256 => ResearchProposal) public proposals;
    mapping(address => bool) public membershipRequests; // Track membership requests

    // -------- Events --------

    event MembershipRequested(address indexed memberAddress);
    event MembershipApproved(address indexed memberAddress);
    event MembershipRevoked(address indexed memberAddress);
    event ProposalSubmitted(uint256 proposalId, address indexed proposer, string title);
    event ProposalVoted(uint256 proposalId, address indexed voter, bool support);
    event ProposalFinalized(uint256 proposalId, ProposalState newState);
    event ProposalFunded(uint256 proposalId, uint256 amount);
    event FundsWithdrawn(uint256 proposalId, address indexed recipient, uint256 amount);
    event ContributionSubmitted(uint256 proposalId, address indexed contributor, string ipfsHash);
    event MilestoneReported(uint256 proposalId, uint256 milestoneIndex, string description);
    event MilestoneApproved(uint256 proposalId, uint256 milestoneIndex);
    event MilestoneRejected(uint256 proposalId, uint256 milestoneIndex);
    event ReputationAdjusted(address indexed member, int256 change);
    event ContractPaused();
    event ContractUnpaused();
    event AdminChanged(address indexed newAdmin);

    // -------- Modifiers --------

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMembers() {
        require(members[msg.sender].isActive, "Only members can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < nextProposalId, "Invalid proposal ID.");
        _;
    }

    modifier validMilestoneIndex(uint256 _proposalId, uint256 _milestoneIndex) {
        require(_milestoneIndex < proposals[_proposalId].milestones.length, "Invalid milestone index.");
        _;
    }


    // -------- Constructor --------

    constructor() {
        owner = msg.sender;
        admin = msg.sender; // Initially admin is also the contract deployer
    }

    // -------- Member Management Functions --------

    /// @notice Allows users to request membership in the DARO.
    function requestMembership() external payable whenNotPaused {
        require(!members[msg.sender].isActive, "Already a member.");
        require(!membershipRequests[msg.sender], "Membership already requested.");
        require(msg.value >= membershipFee, "Membership fee not met."); // Optional fee for spam prevention

        membershipRequests[msg.sender] = true;
        payable(address(this)).transfer(msg.value); // Transfer fee to contract treasury
        emit MembershipRequested(msg.sender);
    }

    /// @notice Admin function to approve membership requests.
    /// @param _member The address of the member to approve.
    function approveMembership(address _member) external onlyAdmin whenNotPaused {
        require(membershipRequests[_member], "Membership not requested.");
        require(!members[_member].isActive, "Already a member.");

        members[_member] = Member({
            memberAddress: _member,
            reputation: 100, // Initial reputation score
            joinTimestamp: block.timestamp,
            isActive: true
        });
        memberList.push(_member);
        memberCount++;
        membershipRequests[_member] = false;
        emit MembershipApproved(_member);
    }

    /// @notice Admin function to revoke membership.
    /// @param _member The address of the member to revoke.
    function revokeMembership(address _member) external onlyAdmin whenNotPaused {
        require(members[_member].isActive, "Not an active member.");

        members[_member].isActive = false;
        // Consider removing from memberList if needed for iteration efficiency in very large lists
        emit MembershipRevoked(_member);
    }

    /// @notice Returns a list of current DARO members.
    /// @return An array of member addresses.
    function getMembers() external view returns (address[] memory) {
        address[] memory activeMembers = new address[](memberCount);
        uint256 index = 0;
        for (uint256 i = 0; i < memberList.length; i++) {
            if (members[memberList[i]].isActive) {
                activeMembers[index] = memberList[i];
                index++;
            }
        }
        return activeMembers;
    }

    /// @notice Returns details about a specific member.
    /// @param _member The address of the member.
    /// @return Member details (address, reputation, joinTimestamp, isActive).
    function getMemberDetails(address _member) external view returns (Member memory) {
        return members[_member];
    }


    // -------- Proposal Management Functions --------

    /// @notice Members can submit research proposals.
    /// @param _title The title of the research proposal.
    /// @param _description A brief description of the proposal.
    /// @param _fundingGoal The funding goal in wei.
    /// @param _ipfsHashForDetails IPFS hash pointing to a detailed proposal document.
    function submitResearchProposal(
        string memory _title,
        string memory _description,
        uint256 _fundingGoal,
        string memory _ipfsHashForDetails
    ) external onlyMembers whenNotPaused {
        require(_fundingGoal > 0, "Funding goal must be greater than zero.");

        proposals[nextProposalId] = ResearchProposal({
            id: nextProposalId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            state: ProposalState.Pending, // Initial state is Pending
            votingEndTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            ipfsHashForDetails: _ipfsHashForDetails,
            milestones: new Milestone[](0), // Initialize empty milestone array
            contributions: mapping(address => Contribution[])() // Initialize empty contributions mapping
        });
        emit ProposalSubmitted(nextProposalId, msg.sender, _title);
        nextProposalId++;
    }

    /// @notice Members can vote on research proposals using quadratic voting (simplified).
    /// @dev In a real quadratic voting system, the cost of votes increases quadratically. Here, it's simplified to one vote per member per proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for yes, false for no.
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyMembers whenNotPaused validProposalId(_proposalId) {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Voting, "Proposal is not in voting state.");
        require(block.timestamp < proposal.votingEndTime, "Voting period has ended.");
        require(!proposal.votes[msg.sender], "Already voted on this proposal.");

        proposal.votes[msg.sender] = true;
        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /// @notice Admin/governance function to finalize a proposal after the voting period.
    /// @param _proposalId The ID of the proposal to finalize.
    function finalizeProposal(uint256 _proposalId) external onlyAdmin whenNotPaused validProposalId(_proposalId) {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Voting, "Proposal is not in voting state.");
        require(block.timestamp >= proposal.votingEndTime, "Voting period has not ended yet.");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        uint256 approvalPercentage = 0;
        if (totalVotes > 0) {
            approvalPercentage = (proposal.yesVotes * 100) / totalVotes;
        }

        if (approvalPercentage >= proposalThreshold) {
            proposal.state = ProposalState.Approved;
            emit ProposalFinalized(_proposalId, ProposalState.Approved);
        } else {
            proposal.state = ProposalState.Rejected;
            emit ProposalFinalized(_proposalId, ProposalState.Rejected);
        }
    }

    /// @notice Retrieves details of a specific research proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return Proposal details (id, proposer, title, description, fundingGoal, currentFunding, state, votingEndTime, yesVotes, noVotes, ipfsHashForDetails).
    function getProposalDetails(uint256 _proposalId) external view validProposalId(_proposalId) returns (ResearchProposal memory) {
        return proposals[_proposalId];
    }

    /// @notice Returns the current status of a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return ProposalState enum value.
    function getProposalStatus(uint256 _proposalId) external view validProposalId(_proposalId) returns (ProposalState) {
        return proposals[_proposalId].state;
    }

    /// @notice Proposal submitter or admin can cancel a proposal before funding.
    /// @param _proposalId The ID of the proposal to cancel.
    function cancelProposal(uint256 _proposalId) external whenNotPaused validProposalId(_proposalId) {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.state != ProposalState.Funded && proposal.state != ProposalState.InProgress && proposal.state != ProposalState.Completed, "Proposal cannot be cancelled in Funded, InProgress or Completed state.");
        require(msg.sender == proposal.proposer || msg.sender == admin, "Only proposer or admin can cancel.");

        proposal.state = ProposalState.Cancelled;
        emit ProposalFinalized(_proposalId, ProposalState.Cancelled);
    }


    // -------- Funding & Treasury Functions --------

    /// @notice Allows anyone to contribute funds to a research proposal.
    /// @param _proposalId The ID of the proposal to fund.
    function fundProposal(uint256 _proposalId) external payable whenNotPaused validProposalId(_proposalId) {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Approved, "Proposal must be in Approved state to be funded.");
        require(proposal.currentFunding < proposal.fundingGoal, "Proposal funding goal already reached.");

        uint256 amountToFund = msg.value;
        uint256 remainingFundingNeeded = proposal.fundingGoal - proposal.currentFunding;

        if (amountToFund > remainingFundingNeeded) {
            amountToFund = remainingFundingNeeded; // Don't overfund
        }

        proposal.currentFunding += amountToFund;
        payable(address(this)).transfer(amountToFund); // Transfer funds to contract treasury
        emit ProposalFunded(_proposalId, amountToFund);

        if (proposal.currentFunding >= proposal.fundingGoal) {
            proposal.state = ProposalState.Funded;
            emit ProposalFinalized(_proposalId, ProposalState.Funded);
        }
    }

    /// @notice Proposal owner can withdraw funds after proposal approval and completion (with milestones ideally).
    /// @dev In a real application, consider milestone-based withdrawal for better fund management and accountability.
    /// @param _proposalId The ID of the proposal to withdraw funds from.
    function withdrawProposalFunds(uint256 _proposalId) external onlyMembers whenNotPaused validProposalId(_proposalId) {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(msg.sender == proposal.proposer, "Only proposal owner can withdraw funds.");
        require(proposal.state == ProposalState.Funded || proposal.state == ProposalState.Completed, "Proposal must be Funded or Completed to withdraw funds.");
        require(proposal.currentFunding > 0, "No funds to withdraw.");

        uint256 amountToWithdraw = proposal.currentFunding;
        proposal.currentFunding = 0; // Reset funding after withdrawal
        proposal.state = ProposalState.InProgress; // Transition to In Progress state upon withdrawal (can be adjusted)

        (bool success, ) = payable(proposal.proposer).call{value: amountToWithdraw}("");
        require(success, "Funds withdrawal failed.");
        emit FundsWithdrawn(_proposalId, proposal.proposer, amountToWithdraw);
        emit ProposalFinalized(_proposalId, ProposalState.InProgress);
    }

    /// @notice Returns the current balance of the DARO treasury.
    /// @return The treasury balance in wei.
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Returns the current funding status of a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return Current funding amount and funding goal.
    function getProposalFundingStatus(uint256 _proposalId) external view validProposalId(_proposalId) returns (uint256 currentFunding, uint256 fundingGoal) {
        return (proposals[_proposalId].currentFunding, proposals[_proposalId].fundingGoal);
    }


    // -------- Reputation & Rewards Functions --------

    /// @notice Members can submit research contributions to approved proposals.
    /// @param _proposalId The ID of the proposal.
    /// @param _ipfsHashForContribution IPFS hash pointing to the research contribution.
    function contributeToResearch(uint256 _proposalId, string memory _ipfsHashForContribution) external onlyMembers whenNotPaused validProposalId(_proposalId) {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.InProgress || proposal.state == ProposalState.Completed, "Contributions only allowed for InProgress or Completed proposals.");

        proposal.contributions[msg.sender].push(Contribution({
            ipfsHashForContribution: _ipfsHashForContribution,
            timestamp: block.timestamp
        }));
        emit ContributionSubmitted(_proposalId, msg.sender, _ipfsHashForContribution);
    }

    /// @notice Proposal owner can report a milestone completion.
    /// @param _proposalId The ID of the proposal.
    /// @param _milestoneDescription Description of the milestone.
    /// @param _ipfsHashForMilestone IPFS hash pointing to the milestone artifact.
    function reportResearchMilestone(uint256 _proposalId, string memory _milestoneDescription, string memory _ipfsHashForMilestone) external onlyMembers whenNotPaused validProposalId(_proposalId) {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer == msg.sender, "Only proposal owner can report milestones.");
        require(proposal.state == ProposalState.InProgress, "Milestones can only be reported for InProgress proposals.");

        proposal.milestones.push(Milestone({
            description: _milestoneDescription,
            ipfsHashForMilestone: _ipfsHashForMilestone,
            state: MilestoneState.PendingApproval,
            approvalVotes: 0,
            rejectionVotes: 0,
            deadline: block.timestamp + 30 days // Example deadline
        }));
        emit MilestoneReported(_proposalId, proposal.milestones.length - 1, _milestoneDescription);
    }

    /// @notice Members can vote to approve a reported milestone.
    /// @param _proposalId The ID of the proposal.
    /// @param _milestoneIndex The index of the milestone to approve.
    function approveResearchMilestone(uint256 _proposalId, uint256 _milestoneIndex) external onlyMembers whenNotPaused validProposalId(_proposalId) validMilestoneIndex(_proposalId, _milestoneIndex) {
        ResearchProposal storage proposal = proposals[_proposalId];
        Milestone storage milestone = proposal.milestones[_milestoneIndex];
        require(milestone.state == MilestoneState.PendingApproval, "Milestone is not pending approval.");
        require(block.timestamp < milestone.deadline, "Milestone approval deadline passed."); // Example deadline enforcement

        milestone.approvalVotes++;
        if (milestone.approvalVotes > (memberCount / 2)) { // Simple majority for milestone approval
            milestone.state = MilestoneState.Approved;
            emit MilestoneApproved(_proposalId, _milestoneIndex);
        }
    }

    /// @notice Members can vote to reject a reported milestone.
    /// @param _proposalId The ID of the proposal.
    /// @param _milestoneIndex The index of the milestone to reject.
    function rejectResearchMilestone(uint256 _proposalId, uint256 _milestoneIndex) external onlyMembers whenNotPaused validProposalId(_proposalId) validMilestoneIndex(_proposalId, _milestoneIndex) {
        ResearchProposal storage proposal = proposals[_proposalId];
        Milestone storage milestone = proposal.milestones[_milestoneIndex];
        require(milestone.state == MilestoneState.PendingApproval, "Milestone is not pending approval.");
        require(block.timestamp < milestone.deadline, "Milestone approval deadline passed."); // Example deadline enforcement

        milestone.rejectionVotes++;
        if (milestone.rejectionVotes > (memberCount / 2)) { // Simple majority for milestone rejection
            milestone.state = MilestoneState.Rejected;
            emit MilestoneRejected(_proposalId, _milestoneIndex);
            // Consider actions upon milestone rejection, e.g., proposal review, penalty, etc.
        }
    }


    /// @notice Admin/governance function to distribute rewards to contributors based on reputation and contribution quality (simplified).
    /// @dev This is a highly simplified reward function. In a real system, reward mechanisms would be much more complex and potentially automated based on contribution evaluation.
    /// @param _proposalId The ID of the proposal to reward contributors for.
    function rewardContributors(uint256 _proposalId) external onlyAdmin whenNotPaused validProposalId(_proposalId) {
        ResearchProposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Completed, "Rewards can only be distributed for Completed proposals.");

        // Simplified reward logic: Increase reputation for all contributors.
        for (uint256 i = 0; i < memberList.length; i++) {
            address memberAddress = memberList[i];
            if (proposal.contributions[memberAddress].length > 0 && members[memberAddress].isActive) { // Check if member contributed and is active
                adjustReputation(memberAddress, 10); // Example: +10 reputation points per contribution (can be dynamic based on contribution quality)
            }
        }
        // In a real system, you might distribute tokens or other forms of value here.
    }

    /// @notice Admin function to penalize members for misconduct, reducing reputation.
    /// @param _member The address of the member to penalize.
    /// @param _penaltyPoints The number of reputation points to deduct.
    function penalizeMember(address _member, uint256 _penaltyPoints) external onlyAdmin whenNotPaused {
        require(members[_member].isActive, "Member is not active.");
        require(members[_member].reputation >= _penaltyPoints, "Penalty points exceed current reputation."); // Prevent negative reputation

        members[_member].reputation -= _penaltyPoints;
        emit ReputationAdjusted(_member, -int256(_penaltyPoints));
    }

    /// @notice Admin function to manually adjust member reputation.
    /// @param _member The address of the member.
    /// @param _reputationChange The amount to change reputation by (positive or negative).
    function adjustReputation(address _member, int256 _reputationChange) external onlyAdmin whenNotPaused {
        require(members[_member].isActive, "Member is not active.");
        members[_member].reputation = uint256(int256(members[_member].reputation) + _reputationChange); // Handle both positive and negative changes, ensure non-negative.
        emit ReputationAdjusted(_member, _reputationChange);
    }

    /// @notice Returns the reputation score of a member.
    /// @param _member The address of the member.
    /// @return The reputation score.
    function getMemberReputation(address _member) external view returns (uint256) {
        return members[_member].reputation;
    }


    // -------- Governance & Settings Functions --------

    /// @notice Admin function to change the default voting duration for proposals.
    /// @param _newDuration The new voting duration in seconds.
    function changeVotingDuration(uint256 _newDuration) external onlyAdmin whenNotPaused {
        votingDuration = _newDuration;
    }

    /// @notice Admin function to change the required quorum for proposal approval.
    /// @param _newThreshold The new proposal approval threshold percentage (0-100).
    function changeProposalThreshold(uint256 _newThreshold) external onlyAdmin whenNotPaused {
        require(_newThreshold <= 100, "Threshold must be between 0 and 100.");
        proposalThreshold = _newThreshold;
    }

    /// @notice Owner function to change the contract admin.
    /// @param _newAdmin The address of the new admin.
    function setAdmin(address _newAdmin) external onlyOwner whenNotPaused {
        require(_newAdmin != address(0), "Invalid admin address.");
        admin = _newAdmin;
        emit AdminChanged(_newAdmin);
    }

    /// @notice Admin function to pause core functionalities in case of emergency.
    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Admin function to resume contract functionalities.
    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused();
    }


    // -------- Utility Functions --------

    /// @notice Returns the contract version.
    /// @return The contract version number.
    function getVersion() external pure returns (uint256) {
        return contractVersion;
    }

    // Fallback function to receive ether
    receive() external payable {}
}
```