```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Gemini AI Assistant
 * @dev This contract implements a Decentralized Autonomous Art Collective (DAAC) where artists can submit their artwork (represented as NFTs),
 * members can vote on submissions, and successful artists get their work featured and potentially rewarded.
 * It incorporates advanced concepts like tiered membership, quadratic voting, decentralized curation, and dynamic commission structures.
 *
 * Function Summary:
 *
 * **Membership & Governance:**
 * 1.  `requestMembership(string memory _artistStatement) payable`: Allows artists to request membership by paying a fee and providing an artist statement.
 * 2.  `approveMembership(address _artistAddress)`: Governor-only function to approve a pending membership request.
 * 3.  `revokeMembership(address _memberAddress)`: Governor-only function to revoke membership.
 * 4.  `upgradeMembershipTier(uint8 _newTier) payable`: Allows members to upgrade their membership tier by paying a fee.
 * 5.  `setGovernor(address _newGovernor)`: Governor-only function to change the contract governor.
 * 6.  `pauseContract()`: Governor-only function to pause most contract functionalities.
 * 7.  `unpauseContract()`: Governor-only function to unpause the contract.
 *
 * **Art Submission & Curation:**
 * 8.  `submitArtwork(string memory _artworkCID, string memory _metadataCID)`: Members can submit their artwork (NFT) proposal with content and metadata CIDs.
 * 9.  `voteOnArtwork(uint256 _proposalId, bool _approve, uint256 _voteWeight)`: Members can vote on artwork proposals using quadratic voting.
 * 10. `finalizeArtworkProposal(uint256 _proposalId)`: Governor-only function to finalize a proposal after voting period ends, either accepting or rejecting it.
 * 11. `setVotingDuration(uint256 _durationInBlocks)`: Governor-only function to set the voting duration for artwork proposals.
 * 12. `reportInappropriateContent(uint256 _proposalId)`: Members can report artwork proposals deemed inappropriate.
 * 13. `resolveContentReport(uint256 _proposalId, bool _removeArtwork)`: Governor-only function to resolve content reports and potentially remove artwork.
 *
 * **Treasury & Rewards:**
 * 14. `depositToTreasury() payable`: Allows anyone to deposit ETH into the DAAC treasury.
 * 15. `withdrawFromTreasury(address _recipient, uint256 _amount)`: Governor-only function to withdraw ETH from the treasury.
 * 16. `setMembershipFee(uint256 _fee)`: Governor-only function to set the base membership fee.
 * 17. `setTierUpgradeFee(uint8 _tier, uint256 _fee)`: Governor-only function to set the upgrade fee for a specific membership tier.
 * 18. `setCommissionRate(uint256 _ratePercentage)`: Governor-only function to set the commission rate charged on artwork sales (if implemented externally).
 * 19. `distributeVotingRewards(uint256 _proposalId)`: Governor-only function to distribute rewards to voters on a finalized proposal (if reward mechanism is implemented).
 *
 * **Utility & Information:**
 * 20. `getProposalDetails(uint256 _proposalId) view returns (Proposal memory)`:  Allows anyone to retrieve details of a specific artwork proposal.
 * 21. `getMemberDetails(address _memberAddress) view returns (Member memory)`: Allows anyone to retrieve details of a specific member.
 * 22. `getTreasuryBalance() view returns (uint256)`: Allows anyone to view the current treasury balance.
 * 23. `isMember(address _address) view returns (bool)`:  Checks if an address is a member.
 * 24. `getMembershipTier(address _address) view returns (uint8)`: Returns the membership tier of an address.
 */
pragma solidity ^0.8.0;

contract DecentralizedAutonomousArtCollective {

    // -------- Outline & Function Summary (Already provided above) --------

    // -------- State Variables --------

    address public governor;
    bool public paused;

    uint256 public membershipFee;
    mapping(uint8 => uint256) public tierUpgradeFees; // Tier level => Upgrade Fee
    uint256 public commissionRatePercentage; // Percentage commission on sales (if applicable)

    uint256 public proposalCounter;
    uint256 public votingDurationBlocks = 100; // Default voting duration in blocks

    enum MembershipStatus { Pending, Active, Revoked }
    enum ProposalStatus { Submitted, Voting, Accepted, Rejected, ContentReported }
    enum VoteType { Approve, Reject }

    struct Member {
        MembershipStatus status;
        uint8 tier; // Membership tiers (e.g., Tier 1, Tier 2, Tier 3)
        string artistStatement;
        uint256 joinTimestamp;
    }
    mapping(address => Member) public members;

    struct Proposal {
        uint256 id;
        address proposer;
        string artworkCID; // CID for the artwork content (e.g., IPFS)
        string metadataCID; // CID for artwork metadata (e.g., IPFS - name, description, etc.)
        ProposalStatus status;
        uint256 submissionTimestamp;
        uint256 votingEndTime;
        uint256 approveVotes;
        uint256 rejectVotes;
        mapping(address => uint256) public votes; // Voter address => vote weight (for quadratic voting)
        uint256 contentReports;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256[] public activeProposals; // Array to track proposals currently in voting

    // -------- Events --------

    event MembershipRequested(address indexed artistAddress);
    event MembershipApproved(address indexed memberAddress, uint8 tier);
    event MembershipRevoked(address indexed memberAddress);
    event MembershipTierUpgraded(address indexed memberAddress, uint8 newTier);
    event GovernorChanged(address indexed oldGovernor, address indexed newGovernor);
    event ContractPaused();
    event ContractUnpaused();

    event ArtworkSubmitted(uint256 indexed proposalId, address indexed proposer, string artworkCID, string metadataCID);
    event VoteCast(uint256 indexed proposalId, address indexed voter, VoteType voteType, uint256 voteWeight);
    event ArtworkProposalFinalized(uint256 indexed proposalId, ProposalStatus status);
    event VotingDurationSet(uint256 durationInBlocks);
    event ContentReported(uint256 indexed proposalId, address reporter);
    event ContentReportResolved(uint256 indexed proposalId, bool removedArtwork);

    event TreasuryDeposit(address indexed depositor, uint256 amount);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);
    event MembershipFeeSet(uint256 newFee);
    event TierUpgradeFeeSet(uint8 tier, uint256 newFee);
    event CommissionRateSet(uint256 newRatePercentage);
    event VotingRewardsDistributed(uint256 indexed proposalId, uint256 totalRewards);


    // -------- Modifiers --------

    modifier onlyGovernor() {
        require(msg.sender == governor, "Only governor can call this function.");
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

    modifier onlyMember() {
        require(members[msg.sender].status == MembershipStatus.Active, "Only members can call this function.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(proposals[_proposalId].id == _proposalId, "Invalid proposal ID.");
        _;
    }

    modifier proposalInStatus(uint256 _proposalId, ProposalStatus _status) {
        require(proposals[_proposalId].status == _status, "Proposal is not in the required status.");
        _;
    }


    // -------- Constructor --------

    constructor() {
        governor = msg.sender;
        membershipFee = 0.1 ether; // Initial membership fee
        tierUpgradeFees[2] = 0.2 ether; // Example Tier 2 upgrade fee
        tierUpgradeFees[3] = 0.5 ether; // Example Tier 3 upgrade fee
        commissionRatePercentage = 5; // Example 5% commission
    }


    // -------- Membership & Governance Functions --------

    /// @notice Allows artists to request membership by paying a fee and providing an artist statement.
    /// @param _artistStatement A statement from the artist about their work and motivation to join.
    function requestMembership(string memory _artistStatement) external payable whenNotPaused {
        require(members[msg.sender].status == MembershipStatus.Pending || members[msg.sender].status == MembershipStatus.Revoked || members[msg.sender].status == MembershipStatus.Active == false, "Membership already requested or active.");
        require(msg.value >= membershipFee, "Membership fee is required.");

        members[msg.sender] = Member({
            status: MembershipStatus.Pending,
            tier: 1, // Default to Tier 1 upon joining
            artistStatement: _artistStatement,
            joinTimestamp: block.timestamp
        });
        emit MembershipRequested(msg.sender);
    }

    /// @notice Governor-only function to approve a pending membership request.
    /// @param _artistAddress The address of the artist to approve.
    function approveMembership(address _artistAddress) external onlyGovernor whenNotPaused {
        require(members[_artistAddress].status == MembershipStatus.Pending, "Address is not pending membership.");
        members[_artistAddress].status = MembershipStatus.Active;
        emit MembershipApproved(_artistAddress, members[_artistAddress].tier);
    }

    /// @notice Governor-only function to revoke membership.
    /// @param _memberAddress The address of the member to revoke membership from.
    function revokeMembership(address _memberAddress) external onlyGovernor whenNotPaused {
        require(members[_memberAddress].status == MembershipStatus.Active, "Address is not an active member.");
        members[_memberAddress].status = MembershipStatus.Revoked;
        emit MembershipRevoked(_memberAddress);
    }

    /// @notice Allows members to upgrade their membership tier by paying a fee.
    /// @param _newTier The desired new membership tier.
    function upgradeMembershipTier(uint8 _newTier) external payable onlyMember whenNotPaused {
        require(_newTier > members[msg.sender].tier && _newTier <= 3, "Invalid tier upgrade requested."); // Example: Up to Tier 3
        require(tierUpgradeFees[_newTier] > 0, "Tier upgrade fee not set.");
        require(msg.value >= tierUpgradeFees[_newTier], "Tier upgrade fee is required.");

        members[msg.sender].tier = _newTier;
        emit MembershipTierUpgraded(msg.sender, _newTier);
    }

    /// @notice Governor-only function to change the contract governor.
    /// @param _newGovernor The address of the new governor.
    function setGovernor(address _newGovernor) external onlyGovernor whenNotPaused {
        require(_newGovernor != address(0), "Invalid governor address.");
        emit GovernorChanged(governor, _newGovernor);
        governor = _newGovernor;
    }

    /// @notice Governor-only function to pause most contract functionalities.
    function pauseContract() external onlyGovernor whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Governor-only function to unpause the contract.
    function unpauseContract() external onlyGovernor whenPaused {
        paused = false;
        emit ContractUnpaused();
    }


    // -------- Art Submission & Curation Functions --------

    /// @notice Members can submit their artwork (NFT) proposal with content and metadata CIDs.
    /// @param _artworkCID The CID of the artwork content (e.g., IPFS).
    /// @param _metadataCID The CID of the artwork metadata (e.g., IPFS).
    function submitArtwork(string memory _artworkCID, string memory _metadataCID) external onlyMember whenNotPaused {
        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            id: proposalCounter,
            proposer: msg.sender,
            artworkCID: _artworkCID,
            metadataCID: _metadataCID,
            status: ProposalStatus.Submitted,
            submissionTimestamp: block.timestamp,
            votingEndTime: block.number + votingDurationBlocks,
            approveVotes: 0,
            rejectVotes: 0,
            contentReports: 0
        });
        activeProposals.push(proposalCounter);
        emit ArtworkSubmitted(proposalCounter, msg.sender, _artworkCID, _metadataCID);
    }

    /// @notice Members can vote on artwork proposals using quadratic voting.
    /// @param _proposalId The ID of the artwork proposal to vote on.
    /// @param _approve Boolean indicating whether to approve (true) or reject (false) the proposal.
    /// @param _voteWeight The amount of voting power the member wants to use (capped by their tier).
    function voteOnArtwork(uint256 _proposalId, bool _approve, uint256 _voteWeight) external onlyMember whenNotPaused validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Submitted) {
        require(block.number <= proposals[_proposalId].votingEndTime, "Voting period has ended.");
        require(proposals[_proposalId].votes[msg.sender] == 0, "Already voted on this proposal."); // Prevent double voting

        uint256 maxVoteWeight = members[msg.sender].tier * 10; // Example: Tier 1 = 10 votes, Tier 2 = 20 votes, Tier 3 = 30 votes

        require(_voteWeight > 0 && _voteWeight <= maxVoteWeight, "Invalid vote weight.");

        uint256 quadraticVoteCost = _voteWeight * _voteWeight; // Quadratic voting - cost increases quadratically with vote weight
        // In a real implementation, you might deduct this "cost" (e.g., using a virtual currency or reputation)
        // For simplicity, this example just tracks the weighted vote.

        proposals[_proposalId].votes[msg.sender] = _voteWeight; // Store the vote weight
        if (_approve) {
            proposals[_proposalId].approveVotes += _voteWeight;
            emit VoteCast(_proposalId, msg.sender, VoteType.Approve, _voteWeight);
        } else {
            proposals[_proposalId].rejectVotes += _voteWeight;
            emit VoteCast(_proposalId, msg.sender, VoteType.Reject, _voteWeight);
        }

        // Update proposal status to voting once first vote is cast
        if (proposals[_proposalId].status == ProposalStatus.Submitted) {
            proposals[_proposalId].status = ProposalStatus.Voting;
        }
    }

    /// @notice Governor-only function to finalize a proposal after voting period ends, either accepting or rejecting it.
    /// @param _proposalId The ID of the artwork proposal to finalize.
    function finalizeArtworkProposal(uint256 _proposalId) external onlyGovernor whenNotPaused validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Voting) {
        require(block.number > proposals[_proposalId].votingEndTime, "Voting period has not ended yet.");

        ProposalStatus finalStatus;
        if (proposals[_proposalId].approveVotes > proposals[_proposalId].rejectVotes) {
            finalStatus = ProposalStatus.Accepted;
            // TODO: Implement actions for accepted proposals (e.g., feature artwork, mint NFT, etc.)
        } else {
            finalStatus = ProposalStatus.Rejected;
            // TODO: Implement actions for rejected proposals (e.g., inform proposer, etc.)
        }
        proposals[_proposalId].status = finalStatus;
        emit ArtworkProposalFinalized(_proposalId, finalStatus);

        // Remove proposal from active proposals array
        for (uint256 i = 0; i < activeProposals.length; i++) {
            if (activeProposals[i] == _proposalId) {
                activeProposals[i] = activeProposals[activeProposals.length - 1];
                activeProposals.pop();
                break;
            }
        }

        // TODO: Implement reward distribution for voters on accepted proposals (optional)
        // distributeVotingRewards(_proposalId);
    }

    /// @notice Governor-only function to set the voting duration for artwork proposals.
    /// @param _durationInBlocks The new voting duration in blocks.
    function setVotingDuration(uint256 _durationInBlocks) external onlyGovernor whenNotPaused {
        require(_durationInBlocks > 0, "Voting duration must be positive.");
        votingDurationBlocks = _durationInBlocks;
        emit VotingDurationSet(_durationInBlocks);
    }

    /// @notice Members can report artwork proposals deemed inappropriate.
    /// @param _proposalId The ID of the artwork proposal to report.
    function reportInappropriateContent(uint256 _proposalId) external onlyMember whenNotPaused validProposalId(_proposalId) {
        require(proposals[_proposalId].status != ProposalStatus.ContentReported, "Proposal already reported.");
        proposals[_proposalId].status = ProposalStatus.ContentReported;
        proposals[_proposalId].contentReports++;
        emit ContentReported(_proposalId, msg.sender);
    }

    /// @notice Governor-only function to resolve content reports and potentially remove artwork.
    /// @param _proposalId The ID of the artwork proposal to resolve the report for.
    /// @param _removeArtwork Boolean indicating whether to remove the artwork (true) or keep it (false).
    function resolveContentReport(uint256 _proposalId, bool _removeArtwork) external onlyGovernor whenNotPaused validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.ContentReported) {
        ProposalStatus finalStatus = ProposalStatus.Rejected; // Default to rejected if content is problematic
        if (!_removeArtwork) {
            finalStatus = ProposalStatus.Submitted; // Revert to submitted for voting if report is dismissed
        } else {
            // TODO: Implement logic to handle removed artwork (e.g., remove from featured list, etc.)
        }

        proposals[_proposalId].status = finalStatus;
        emit ContentReportResolved(_proposalId, _removeArtwork);
        emit ArtworkProposalFinalized(_proposalId, finalStatus); // Also emit proposal finalized event to reflect status change
    }


    // -------- Treasury & Rewards Functions --------

    /// @notice Allows anyone to deposit ETH into the DAAC treasury.
    function depositToTreasury() external payable whenNotPaused {
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /// @notice Governor-only function to withdraw ETH from the treasury.
    /// @param _recipient The address to receive the withdrawn ETH.
    /// @param _amount The amount of ETH to withdraw.
    function withdrawFromTreasury(address _recipient, uint256 _amount) external onlyGovernor whenNotPaused {
        require(_recipient != address(0), "Invalid recipient address.");
        require(address(this).balance >= _amount, "Insufficient treasury balance.");
        payable(_recipient).transfer(_amount);
        emit TreasuryWithdrawal(_recipient, _amount);
    }

    /// @notice Governor-only function to set the base membership fee.
    /// @param _fee The new membership fee in wei.
    function setMembershipFee(uint256 _fee) external onlyGovernor whenNotPaused {
        membershipFee = _fee;
        emit MembershipFeeSet(_fee);
    }

    /// @notice Governor-only function to set the upgrade fee for a specific membership tier.
    /// @param _tier The membership tier to set the upgrade fee for.
    /// @param _fee The new upgrade fee in wei.
    function setTierUpgradeFee(uint8 _tier, uint256 _fee) external onlyGovernor whenNotPaused {
        require(_tier > 1 && _tier <= 3, "Invalid tier for upgrade fee setting."); // Example: Tiers 2 and 3 upgrades
        tierUpgradeFees[_tier] = _fee;
        emit TierUpgradeFeeSet(_tier, _fee);
    }

    /// @notice Governor-only function to set the commission rate charged on artwork sales (if implemented externally).
    /// @param _ratePercentage The new commission rate percentage (e.g., 5 for 5%).
    function setCommissionRate(uint256 _ratePercentage) external onlyGovernor whenNotPaused {
        require(_ratePercentage <= 100, "Commission rate cannot exceed 100%.");
        commissionRatePercentage = _ratePercentage;
        emit CommissionRateSet(_ratePercentage);
    }

    /// @notice Governor-only function to distribute rewards to voters on a finalized proposal (if reward mechanism is implemented).
    /// @param _proposalId The ID of the finalized artwork proposal.
    function distributeVotingRewards(uint256 _proposalId) external onlyGovernor whenNotPaused validProposalId(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Accepted) {
        // TODO: Implement a reward distribution mechanism for voters on accepted proposals.
        // Example: Distribute a portion of treasury or collected fees to voters proportionally to their vote weight.
        // This is a complex feature and requires careful design of the reward system.

        uint256 totalRewards = 0; // Calculate rewards based on treasury, fees, etc.
        emit VotingRewardsDistributed(_proposalId, totalRewards);
    }


    // -------- Utility & Information Functions --------

    /// @notice Allows anyone to retrieve details of a specific artwork proposal.
    /// @param _proposalId The ID of the artwork proposal.
    /// @return Proposal struct containing proposal details.
    function getProposalDetails(uint256 _proposalId) external view validProposalId(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice Allows anyone to retrieve details of a specific member.
    /// @param _memberAddress The address of the member.
    /// @return Member struct containing member details.
    function getMemberDetails(address _memberAddress) external view returns (Member memory) {
        return members[_memberAddress];
    }

    /// @notice Allows anyone to view the current treasury balance.
    /// @return The current treasury balance in wei.
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Checks if an address is a member.
    /// @param _address The address to check.
    /// @return True if the address is an active member, false otherwise.
    function isMember(address _address) external view returns (bool) {
        return members[_address].status == MembershipStatus.Active;
    }

    /// @notice Returns the membership tier of an address.
    /// @param _address The address to check.
    /// @return The membership tier (1, 2, or 3, or 0 if not a member).
    function getMembershipTier(address _address) external view returns (uint8) {
        if (members[_address].status == MembershipStatus.Active) {
            return members[_address].tier;
        } else {
            return 0;
        }
    }
}
```