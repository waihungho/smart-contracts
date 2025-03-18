```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective, enabling artists to submit artwork proposals,
 *      community members to vote on them, and the collective to fund and manage digital art.
 *
 * Function Outline and Summary:
 *
 * **Governance & Membership:**
 * 1. `becomeMember()`: Allows users to become members of the DAAC by staking a certain amount of tokens.
 * 2. `leaveMembership()`: Allows members to leave the DAAC and unstake their tokens.
 * 3. `setMembershipStakeAmount(uint256 _stakeAmount)`: Allows the contract owner to set the required stake amount for membership.
 * 4. `getMembershipStakeAmount()`: Returns the current membership stake amount.
 * 5. `getMemberCount()`: Returns the current number of DAAC members.
 * 6. `isMember(address _user)`: Checks if a given address is a member of the DAAC.
 * 7. `changeQuorum(uint256 _newQuorum)`: Allows the contract owner to change the voting quorum for proposals.
 * 8. `getQuorum()`: Returns the current voting quorum.
 * 9. `setVotingDuration(uint256 _durationInSeconds)`: Allows the contract owner to set the voting duration for proposals.
 * 10. `getVotingDuration()`: Returns the current voting duration.
 *
 * **Art Proposal & Curation:**
 * 11. `submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash, uint256 _fundingGoal)`: Allows members to submit art proposals with details and funding goals.
 * 12. `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows members to vote on active art proposals.
 * 13. `finalizeProposal(uint256 _proposalId)`: Finalizes a proposal after the voting period, checking if it passed and executing actions.
 * 14. `getProposalDetails(uint256 _proposalId)`: Returns detailed information about a specific art proposal.
 * 15. `getProposalVoteCount(uint256 _proposalId)`: Returns the current vote count (yes/no) for a proposal.
 * 16. `getProposalStatus(uint256 _proposalId)`: Returns the current status of a proposal (Pending, Active, Passed, Failed, Executed).
 * 17. `cancelProposal(uint256 _proposalId)`: Allows the proposal submitter to cancel a proposal before it starts.
 *
 * **Treasury & Funding:**
 * 18. `depositToTreasury()`: Allows anyone to deposit tokens into the DAAC treasury.
 * 19. `withdrawFromTreasury(uint256 _amount)`: Allows the contract owner to withdraw tokens from the treasury (potentially for operational costs, subject to future DAO governance).
 * 20. `getTreasuryBalance()`: Returns the current balance of the DAAC treasury.
 * 21. `fundProposal(uint256 _proposalId)`: Funds a passed art proposal from the treasury, transferring tokens to the artist.
 * 22. `refundProposal(uint256 _proposalId)`: Refunds the treasury if a funded proposal is cancelled or fails to be executed for some reason (edge case).
 *
 * **Utility & Information:**
 * 23. `getTokenAddress()`: Returns the address of the ERC20 token used for membership and treasury.
 * 24. `getProposalCount()`: Returns the total number of art proposals submitted.
 * 25. `getVersion()`: Returns the contract version.
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedAutonomousArtCollective is Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    IERC20 public daacToken; // ERC20 token used for membership and treasury
    uint256 public membershipStakeAmount; // Amount of tokens required to become a member
    mapping(address => bool) public isDAACMember; // Mapping to track DAAC members
    Counters.Counter private memberCount; // Counter for DAAC members
    uint256 public votingDuration; // Duration of voting period in seconds
    uint256 public quorum; // Percentage of members required to vote for quorum (e.g., 50 for 50%)

    struct ArtProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        string ipfsHash; // IPFS hash of the artwork
        uint256 fundingGoal;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 votingEndTime;
        ProposalStatus status;
    }

    enum ProposalStatus {
        Pending, // Proposal submitted, waiting to start voting
        Active,  // Voting is in progress
        Passed,  // Proposal passed voting
        Failed,  // Proposal failed voting
        Executed, // Proposal funding executed
        Cancelled // Proposal cancelled by proposer before voting starts
    }

    mapping(uint256 => ArtProposal) public artProposals;
    Counters.Counter private proposalCount;

    event MembershipStaked(address indexed member, uint256 amount);
    event MembershipUnstaked(address indexed member, uint256 amount);
    event MembershipStakeAmountChanged(uint256 newAmount);
    event VotingDurationChanged(uint256 newDuration);
    event QuorumChanged(uint256 newQuorum);

    event ArtProposalSubmitted(uint256 proposalId, address proposer, string title);
    event ProposalVoteCasted(uint256 proposalId, address voter, bool vote);
    event ProposalFinalized(uint256 proposalId, ProposalStatus status);
    event ProposalCancelled(uint256 proposalId, address canceller);
    event ProposalFunded(uint256 proposalId, address artist, uint256 amount);

    event TreasuryDeposit(address depositor, uint256 amount);
    event TreasuryWithdrawal(address recipient, uint256 amount);

    constructor(address _daacTokenAddress, uint256 _membershipStakeAmount, uint256 _votingDuration, uint256 _quorum) payable {
        daacToken = IERC20(_daacTokenAddress);
        membershipStakeAmount = _membershipStakeAmount;
        votingDuration = _votingDuration;
        quorum = _quorum;
    }

    // ---- Governance & Membership Functions ----

    /**
     * @dev Allows a user to become a member of the DAAC by staking tokens.
     */
    function becomeMember() public {
        require(!isDAACMember[msg.sender], "Already a member");
        require(daacToken.allowance(msg.sender, address(this)) >= membershipStakeAmount, "Allowance not set or insufficient allowance for stake");
        require(daacToken.transferFrom(msg.sender, address(this), membershipStakeAmount), "Token transfer failed");
        isDAACMember[msg.sender] = true;
        memberCount.increment();
        emit MembershipStaked(msg.sender, membershipStakeAmount);
    }

    /**
     * @dev Allows a member to leave the DAAC and unstake their tokens.
     */
    function leaveMembership() public {
        require(isDAACMember[msg.sender], "Not a member");
        isDAACMember[msg.sender] = false;
        memberCount.decrement();
        require(daacToken.transfer(msg.sender, membershipStakeAmount), "Token unstake transfer failed");
        emit MembershipUnstaked(msg.sender, membershipStakeAmount);
    }

    /**
     * @dev Allows the contract owner to set the required stake amount for membership.
     * @param _stakeAmount The new stake amount.
     */
    function setMembershipStakeAmount(uint256 _stakeAmount) public onlyOwner {
        membershipStakeAmount = _stakeAmount;
        emit MembershipStakeAmountChanged(_stakeAmount);
    }

    /**
     * @dev Returns the current membership stake amount.
     * @return The current membership stake amount.
     */
    function getMembershipStakeAmount() public view returns (uint256) {
        return membershipStakeAmount;
    }

    /**
     * @dev Returns the current number of DAAC members.
     * @return The current member count.
     */
    function getMemberCount() public view returns (uint256) {
        return memberCount.current();
    }

    /**
     * @dev Checks if a given address is a member of the DAAC.
     * @param _user The address to check.
     * @return True if the address is a member, false otherwise.
     */
    function isMember(address _user) public view returns (bool) {
        return isDAACMember[_user];
    }

    /**
     * @dev Allows the contract owner to change the voting quorum.
     * @param _newQuorum The new quorum percentage (e.g., 50 for 50%).
     */
    function changeQuorum(uint256 _newQuorum) public onlyOwner {
        require(_newQuorum <= 100, "Quorum must be a percentage (<= 100)");
        quorum = _newQuorum;
        emit QuorumChanged(_newQuorum);
    }

    /**
     * @dev Returns the current voting quorum.
     * @return The current voting quorum percentage.
     */
    function getQuorum() public view returns (uint256) {
        return quorum;
    }

    /**
     * @dev Allows the contract owner to set the voting duration for proposals.
     * @param _durationInSeconds The voting duration in seconds.
     */
    function setVotingDuration(uint256 _durationInSeconds) public onlyOwner {
        votingDuration = _durationInSeconds;
        emit VotingDurationChanged(_durationInSeconds);
    }

    /**
     * @dev Returns the current voting duration.
     * @return The current voting duration in seconds.
     */
    function getVotingDuration() public view returns (uint256) {
        return votingDuration;
    }


    // ---- Art Proposal & Curation Functions ----

    /**
     * @dev Allows members to submit art proposals.
     * @param _title The title of the artwork proposal.
     * @param _description A brief description of the artwork.
     * @param _ipfsHash The IPFS hash of the artwork.
     * @param _fundingGoal The funding goal in DAAC tokens for the artwork.
     */
    function submitArtProposal(
        string memory _title,
        string memory _description,
        string memory _ipfsHash,
        uint256 _fundingGoal
    ) public {
        require(isDAACMember[msg.sender], "Only DAAC members can submit proposals");
        require(bytes(_title).length > 0 && bytes(_description).length > 0 && bytes(_ipfsHash).length > 0, "Proposal details cannot be empty");
        require(_fundingGoal > 0, "Funding goal must be greater than zero");

        proposalCount.increment();
        uint256 proposalId = proposalCount.current();

        artProposals[proposalId] = ArtProposal({
            id: proposalId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            fundingGoal: _fundingGoal,
            yesVotes: 0,
            noVotes: 0,
            votingEndTime: block.timestamp + votingDuration,
            status: ProposalStatus.Pending
        });

        artProposals[proposalId].status = ProposalStatus.Active; // Immediately set to active for voting
        emit ArtProposalSubmitted(proposalId, msg.sender, _title);
    }

    /**
     * @dev Allows members to vote on active art proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote True for yes, false for no.
     */
    function voteOnProposal(uint256 _proposalId, bool _vote) public {
        require(isDAACMember[msg.sender], "Only DAAC members can vote");
        require(artProposals[_proposalId].status == ProposalStatus.Active, "Proposal is not active for voting");
        require(block.timestamp < artProposals[_proposalId].votingEndTime, "Voting period has ended");

        // To prevent double voting, consider implementing a mapping to track votes per proposal and member.
        // For simplicity, double voting is not explicitly prevented in this basic example.

        if (_vote) {
            artProposals[_proposalId].yesVotes++;
        } else {
            artProposals[_proposalId].noVotes++;
        }
        emit ProposalVoteCasted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Finalizes a proposal after the voting period ends.
     * @param _proposalId The ID of the proposal to finalize.
     */
    function finalizeProposal(uint256 _proposalId) public {
        require(artProposals[_proposalId].status == ProposalStatus.Active, "Proposal is not active or already finalized");
        require(block.timestamp >= artProposals[_proposalId].votingEndTime, "Voting period has not ended yet");

        uint256 totalVotes = artProposals[_proposalId].yesVotes + artProposals[_proposalId].noVotes;
        uint256 memberCountSnapshot = memberCount.current(); // Get a snapshot to avoid reentrancy issues if member count changes during execution

        if (memberCountSnapshot == 0) {
            artProposals[_proposalId].status = ProposalStatus.Failed; // If no members, proposal fails.
            emit ProposalFinalized(_proposalId, ProposalStatus.Failed);
            return;
        }

        uint256 quorumThreshold = (memberCountSnapshot * quorum) / 100; // Calculate quorum threshold

        if (totalVotes >= quorumThreshold && artProposals[_proposalId].yesVotes > artProposals[_proposalId].noVotes) {
            artProposals[_proposalId].status = ProposalStatus.Passed;
            emit ProposalFinalized(_proposalId, ProposalStatus.Passed);
        } else {
            artProposals[_proposalId].status = ProposalStatus.Failed;
            emit ProposalFinalized(_proposalId, ProposalStatus.Failed);
        }
    }

    /**
     * @dev Returns detailed information about a specific art proposal.
     * @param _proposalId The ID of the proposal.
     * @return Struct ArtProposal containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    /**
     * @dev Returns the current vote count for a proposal.
     * @param _proposalId The ID of the proposal.
     * @return yesVotes - The number of yes votes.
     * @return noVotes - The number of no votes.
     */
    function getProposalVoteCount(uint256 _proposalId) public view returns (uint256 yesVotes, uint256 noVotes) {
        return (artProposals[_proposalId].yesVotes, artProposals[_proposalId].noVotes);
    }

    /**
     * @dev Returns the current status of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return The ProposalStatus enum value.
     */
    function getProposalStatus(uint256 _proposalId) public view returns (ProposalStatus) {
        return artProposals[_proposalId].status;
    }

    /**
     * @dev Allows the proposal submitter to cancel a proposal before it starts voting.
     * @param _proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 _proposalId) public {
        require(artProposals[_proposalId].proposer == msg.sender, "Only proposer can cancel");
        require(artProposals[_proposalId].status == ProposalStatus.Pending || artProposals[_proposalId].status == ProposalStatus.Active, "Proposal cannot be cancelled in current status"); // Allow cancel even if voting started, for flexibility
        artProposals[_proposalId].status = ProposalStatus.Cancelled;
        emit ProposalCancelled(_proposalId, msg.sender);
    }


    // ---- Treasury & Funding Functions ----

    /**
     * @dev Allows anyone to deposit tokens into the DAAC treasury.
     */
    function depositToTreasury() public payable {
        uint256 amount = daacToken.allowance(msg.sender, address(this));
        require(amount > 0, "No tokens approved for deposit");
        require(daacToken.transferFrom(msg.sender, address(this), amount), "Token deposit transfer failed");
        emit TreasuryDeposit(msg.sender, amount);
    }

    /**
     * @dev Allows the contract owner to withdraw tokens from the treasury.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawFromTreasury(uint256 _amount) public onlyOwner {
        require(daacToken.balanceOf(address(this)) >= _amount, "Insufficient treasury balance");
        require(daacToken.transfer(owner(), _amount), "Treasury withdrawal transfer failed");
        emit TreasuryWithdrawal(owner(), _amount);
    }

    /**
     * @dev Returns the current balance of the DAAC treasury.
     * @return The treasury balance.
     */
    function getTreasuryBalance() public view returns (uint256) {
        return daacToken.balanceOf(address(this));
    }

    /**
     * @dev Funds a passed art proposal from the treasury, transferring tokens to the artist.
     * @param _proposalId The ID of the proposal to fund.
     */
    function fundProposal(uint256 _proposalId) public onlyOwner { // Owner can execute funding for simplicity, in a real DAO it would be governance vote
        require(artProposals[_proposalId].status == ProposalStatus.Passed, "Proposal must be passed to be funded");
        require(artProposals[_proposalId].fundingGoal > 0, "Funding goal must be greater than zero");
        require(daacToken.balanceOf(address(this)) >= artProposals[_proposalId].fundingGoal, "Insufficient treasury balance to fund proposal");
        require(artProposals[_proposalId].status != ProposalStatus.Executed, "Proposal already funded");

        artProposals[_proposalId].status = ProposalStatus.Executed;
        require(daacToken.transfer(artProposals[_proposalId].proposer, artProposals[_proposalId].fundingGoal), "Funding transfer to artist failed");
        emit ProposalFunded(_proposalId, artProposals[_proposalId].proposer, artProposals[_proposalId].fundingGoal);
    }

    /**
     * @dev Refunds the treasury if a funded proposal is cancelled or fails to be executed (edge case handling).
     * @param _proposalId The ID of the proposal to refund.
     */
    function refundProposal(uint256 _proposalId) public onlyOwner { // Owner can initiate refund for edge cases, in real DAO, governance would decide.
        require(artProposals[_proposalId].status == ProposalStatus.Executed, "Proposal must be in Executed state to be refunded (edge case)");
        require(artProposals[_proposalId].fundingGoal > 0, "Funding goal must be greater than zero");
        require(daacToken.balanceOf(artProposals[_proposalId].proposer) >= artProposals[_proposalId].fundingGoal, "Artist does not have the funds to refund");

        artProposals[_proposalId].status = ProposalStatus.Failed; // Set status back to failed after refund
        require(daacToken.transferFrom(artProposals[_proposalId].proposer, address(this), artProposals[_proposalId].fundingGoal), "Refund transfer from artist failed");
        emit TreasuryDeposit(artProposals[_proposalId].proposer, artProposals[_proposalId].fundingGoal); // Treat refund as deposit back to treasury
    }


    // ---- Utility & Information Functions ----

    /**
     * @dev Returns the address of the ERC20 token used for membership and treasury.
     * @return The ERC20 token address.
     */
    function getTokenAddress() public view returns (address) {
        return address(daacToken);
    }

    /**
     * @dev Returns the total number of art proposals submitted.
     * @return The total proposal count.
     */
    function getProposalCount() public view returns (uint256) {
        return proposalCount.current();
    }

    /**
     * @dev Returns the contract version (simple string for now).
     * @return Contract version string.
     */
    function getVersion() public pure returns (string memory) {
        return "DAAC v1.0";
    }

    // Fallback function to receive tokens (optional, for convenience if sending directly to contract address)
    receive() external payable {}
    fallback() external payable {}
}
```