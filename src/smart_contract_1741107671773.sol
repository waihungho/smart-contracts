```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC).
 * This contract enables artists to submit artworks, community members to curate and vote on them,
 * and manage a collective treasury for funding art projects and rewarding contributors.
 *
 * **Outline and Function Summary:**
 *
 * **1. Core Art Management:**
 *    - `submitArtwork(string memory _title, string memory _description, string memory _ipfsHash)`: Allows artists to submit their artwork proposals.
 *    - `getArtworkDetails(uint256 _artworkId)`: Retrieves details of a specific artwork proposal.
 *    - `approveArtwork(uint256 _artworkId)`: Allows curators to approve an artwork proposal after successful voting.
 *    - `rejectArtwork(uint256 _artworkId)`: Allows curators to reject an artwork proposal after unsuccessful voting.
 *    - `mintArtworkNFT(uint256 _artworkId)`: Mints an NFT representing an approved artwork, owned by the DAAC Treasury.
 *    - `burnArtworkNFT(uint256 _artworkId)`: Burns the NFT associated with an artwork (e.g., if deemed inappropriate later by governance).
 *    - `listApprovedArtworks()`: Returns a list of IDs of all approved artworks.
 *    - `listPendingArtworks()`: Returns a list of IDs of all pending artwork proposals.
 *    - `getTotalArtworksSubmitted()`: Returns the total number of artworks submitted.
 *    - `getTotalArtworksApproved()`: Returns the total number of artworks approved.
 *
 * **2. Governance & Voting:**
 *    - `createProposal(string memory _title, string memory _description, ProposalType _proposalType, uint256 _artworkId, address _recipient, uint256 _amount)`: Allows members to create various types of proposals (Artwork Approval, Treasury Spending, Rule Change).
 *    - `voteOnProposal(uint256 _proposalId, VoteOption _vote)`: Allows members to vote on active proposals.
 *    - `executeProposal(uint256 _proposalId)`: Executes a proposal if it passes the voting threshold.
 *    - `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific proposal.
 *    - `getProposalVoteCount(uint256 _proposalId)`: Returns the vote counts for a specific proposal.
 *    - `listActiveProposals()`: Returns a list of IDs of all active proposals.
 *    - `listExecutedProposals()`: Returns a list of IDs of all executed proposals.
 *
 * **3. Membership & Reputation:**
 *    - `requestMembership()`: Allows users to request membership to the DAAC.
 *    - `approveMembership(address _member)`: Allows existing members to approve a membership request.
 *    - `revokeMembership(address _member)`: Allows governance to revoke membership from a user.
 *    - `getMemberCount()`: Returns the total number of DAAC members.
 *    - `isMember(address _account)`: Checks if an address is a member of the DAAC.
 *    - `getMemberReputation(address _member)`: (Future Enhancement) - Could track reputation based on contribution.
 *
 * **4. Treasury & Revenue:**
 *    - `depositFunds()` payable`: Allows anyone to deposit funds into the DAAC treasury.
 *    - `withdrawFunds(address _recipient, uint256 _amount)`: Allows governance to withdraw funds from the treasury (through proposals).
 *    - `getTreasuryBalance()`: Returns the current balance of the DAAC treasury.
 *    - `setArtworkSalePrice(uint256 _artworkId, uint256 _price)`: Sets the sale price for an artwork NFT (governed by proposals).
 *    - `purchaseArtworkNFT(uint256 _artworkId) payable`: Allows anyone to purchase an artwork NFT, sending funds to the treasury.
 *
 * **5. Community & Engagement:**
 *    - `submitCommunityIdea(string memory _idea)`: Allows members to submit general community ideas or suggestions.
 *    - `listCommunityIdeas()`: Returns a list of submitted community ideas.
 *    - `addCommentToArtwork(uint256 _artworkId, string memory _comment)`: Allows members to add comments to specific artworks.
 *    - `getArtworkComments(uint256 _artworkId)`: Retrieves comments associated with a specific artwork.
 *
 * **6. Utility & Admin:**
 *    - `pauseContract()`: Allows the contract owner to pause certain functionalities in case of emergency.
 *    - `unpauseContract()`: Allows the contract owner to unpause the contract.
 *    - `setVotingDuration(uint256 _durationInBlocks)`: Allows the contract owner to set the default voting duration.
 *    - `setQuorumPercentage(uint256 _percentage)`: Allows the contract owner to set the quorum percentage for proposals.
 *    - `transferOwnership(address newOwner)`: Allows the current owner to transfer contract ownership.
 *    - `getVersion()`: Returns the contract version.
 */

contract DecentralizedAutonomousArtCollective {
    // -------- State Variables --------

    address public owner;
    bool public paused;
    uint256 public votingDurationBlocks = 100; // Default voting duration: 100 blocks
    uint256 public quorumPercentage = 50; // Default quorum: 50%

    uint256 public artworkCounter;
    mapping(uint256 => Artwork) public artworks;
    enum ArtworkStatus { Pending, Approved, Rejected }
    struct Artwork {
        uint256 id;
        string title;
        string description;
        string ipfsHash;
        address artist;
        ArtworkStatus status;
        uint256 salePrice;
        address nftOwner; // Address that currently owns the NFT (Treasury initially)
        bool nftMinted;
        bool nftBurned;
        string[] comments; // Array to store comments for each artwork
    }

    uint256 public proposalCounter;
    mapping(uint256 => Proposal) public proposals;
    enum ProposalType { ArtworkApproval, TreasurySpending, RuleChange, MembershipAction }
    enum ProposalStatus { Active, Passed, Rejected, Executed }
    enum VoteOption { For, Against, Abstain }
    struct Proposal {
        uint256 id;
        string title;
        string description;
        ProposalType proposalType;
        ProposalStatus status;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => VoteOption) public votes; // Track votes per member
        uint256 artworkId; // Relevant for ArtworkApproval proposals
        address recipient; // Relevant for TreasurySpending proposals
        uint256 amount; // Relevant for TreasurySpending proposals
    }

    mapping(address => bool) public members;
    address[] public memberList;
    mapping(address => bool) public membershipRequests;

    string[] public communityIdeas;
    string public constant VERSION = "1.0.0";

    // -------- Events --------

    event ArtworkSubmitted(uint256 artworkId, string title, address artist);
    event ArtworkApproved(uint256 artworkId);
    event ArtworkRejected(uint256 artworkId);
    event ArtworkNFTMinted(uint256 artworkId, address nftOwner);
    event ArtworkNFTBurned(uint256 artworkId);

    event ProposalCreated(uint256 proposalId, ProposalType proposalType, string title, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, VoteOption vote);
    event ProposalExecuted(uint256 proposalId, ProposalStatus status);

    event MembershipRequested(address member);
    event MembershipApproved(address member);
    event MembershipRevoked(address member);

    event FundsDeposited(address sender, uint256 amount);
    event FundsWithdrawn(address recipient, uint256 amount);
    event ArtworkPurchased(uint256 artworkId, address buyer, uint256 price);

    event CommunityIdeaSubmitted(uint256 ideaId, string idea, address submitter);
    event CommentAddedToArtwork(uint256 artworkId, address commenter, string comment);

    event ContractPaused(address owner);
    event ContractUnpaused(address owner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // -------- Modifiers --------

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
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
        require(members[msg.sender], "Only members can call this function.");
        _;
    }

    modifier validArtworkId(uint256 _artworkId) {
        require(_artworkId > 0 && _artworkId <= artworkCounter, "Invalid artwork ID.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCounter, "Invalid proposal ID.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.Active, "Proposal is not active.");
        _;
    }

    modifier proposalPassed(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.Passed, "Proposal has not passed.");
        _;
    }


    // -------- Constructor --------

    constructor() {
        owner = msg.sender;
        paused = false;
        members[owner] = true; // Owner is automatically a member
        memberList.push(owner);
    }

    // -------- 1. Core Art Management Functions --------

    /// @notice Allows artists to submit their artwork proposals.
    /// @param _title Title of the artwork.
    /// @param _description Description of the artwork.
    /// @param _ipfsHash IPFS hash of the artwork data.
    function submitArtwork(string memory _title, string memory _description, string memory _ipfsHash) external whenNotPaused {
        artworkCounter++;
        artworks[artworkCounter] = Artwork({
            id: artworkCounter,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            artist: msg.sender,
            status: ArtworkStatus.Pending,
            salePrice: 0, // Default sale price is 0, to be set later
            nftOwner: address(0), // NFT not minted yet
            nftMinted: false,
            nftBurned: false,
            comments: new string[](0)
        });
        emit ArtworkSubmitted(artworkCounter, _title, msg.sender);
    }

    /// @notice Retrieves details of a specific artwork proposal.
    /// @param _artworkId ID of the artwork.
    /// @return Artwork struct containing artwork details.
    function getArtworkDetails(uint256 _artworkId) external view validArtworkId(_artworkId) returns (Artwork memory) {
        return artworks[_artworkId];
    }

    /// @notice Allows curators to approve an artwork proposal after successful voting.
    /// @param _artworkId ID of the artwork to approve.
    function approveArtwork(uint256 _artworkId) external onlyMember validArtworkId(_artworkId) whenNotPaused {
        require(artworks[_artworkId].status == ArtworkStatus.Pending, "Artwork is not pending approval.");

        // Check if there is a passed proposal for this artwork approval
        bool proposalFoundAndPassed = false;
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (proposals[i].proposalType == ProposalType.ArtworkApproval &&
                proposals[i].artworkId == _artworkId &&
                proposals[i].status == ProposalStatus.Passed) {
                proposalFoundAndPassed = true;
                break;
            }
        }
        require(proposalFoundAndPassed, "Artwork approval requires a passed proposal.");

        artworks[_artworkId].status = ArtworkStatus.Approved;
        emit ArtworkApproved(_artworkId);
    }

    /// @notice Allows curators to reject an artwork proposal after unsuccessful voting.
    /// @param _artworkId ID of the artwork to reject.
    function rejectArtwork(uint256 _artworkId) external onlyMember validArtworkId(_artworkId) whenNotPaused {
        require(artworks[_artworkId].status == ArtworkStatus.Pending, "Artwork is not pending rejection.");

        // Check if there is a passed proposal for this artwork rejection (or failed approval) - logic can be adjusted as needed
        bool proposalFoundAndRejected = false;
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (proposals[i].proposalType == ProposalType.ArtworkApproval &&
                proposals[i].artworkId == _artworkId &&
                proposals[i].status == ProposalStatus.Rejected) { // Or check for failed approval proposal if needed
                proposalFoundAndRejected = true;
                break;
            }
        }
        require(proposalFoundAndRejected, "Artwork rejection requires a passed rejection proposal (or failed approval proposal).");


        artworks[_artworkId].status = ArtworkStatus.Rejected;
        emit ArtworkRejected(_artworkId);
    }

    /// @notice Mints an NFT representing an approved artwork, owned by the DAAC Treasury.
    /// @param _artworkId ID of the approved artwork.
    function mintArtworkNFT(uint256 _artworkId) external onlyMember validArtworkId(_artworkId) whenNotPaused {
        require(artworks[_artworkId].status == ArtworkStatus.Approved, "Artwork is not approved.");
        require(!artworks[_artworkId].nftMinted, "NFT already minted for this artwork.");
        require(!artworks[_artworkId].nftBurned, "NFT is burned for this artwork.");

        // In a real implementation, this would involve minting an actual NFT (e.g., ERC721/ERC1155)
        // For simplicity, we'll just mark it as minted and set the owner to the contract address itself (treasury).
        artworks[_artworkId].nftMinted = true;
        artworks[_artworkId].nftOwner = address(this); // DAAC Treasury owns the NFT
        emit ArtworkNFTMinted(_artworkId, address(this));
    }

    /// @notice Burns the NFT associated with an artwork (e.g., if deemed inappropriate later by governance).
    /// @param _artworkId ID of the artwork whose NFT should be burned.
    function burnArtworkNFT(uint256 _artworkId) external onlyMember validArtworkId(_artworkId) whenNotPaused {
        require(artworks[_artworkId].nftMinted, "NFT not minted for this artwork yet.");
        require(!artworks[_artworkId].nftBurned, "NFT already burned for this artwork.");

        // In a real implementation, this would involve burning the actual NFT.
        // For simplicity, we'll just mark it as burned.
        artworks[_artworkId].nftBurned = true;
        artworks[_artworkId].nftOwner = address(0); // No owner after burning
        emit ArtworkNFTBurned(_artworkId);
    }

    /// @notice Returns a list of IDs of all approved artworks.
    /// @return Array of artwork IDs.
    function listApprovedArtworks() external view returns (uint256[] memory) {
        uint256[] memory approvedArtworkIds = new uint256[](artworkCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= artworkCounter; i++) {
            if (artworks[i].status == ArtworkStatus.Approved) {
                approvedArtworkIds[count] = artworks[i].id;
                count++;
            }
        }
        // Resize the array to the actual number of approved artworks
        assembly {
            mstore(approvedArtworkIds, count) // Update the length of the array
        }
        return approvedArtworkIds;
    }

    /// @notice Returns a list of IDs of all pending artwork proposals.
    /// @return Array of artwork IDs.
    function listPendingArtworks() external view returns (uint256[] memory) {
        uint256[] memory pendingArtworkIds = new uint256[](artworkCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= artworkCounter; i++) {
            if (artworks[i].status == ArtworkStatus.Pending) {
                pendingArtworkIds[count] = artworks[i].id;
                count++;
            }
        }
        assembly {
            mstore(pendingArtworkIds, count)
        }
        return pendingArtworkIds;
    }

    /// @notice Returns the total number of artworks submitted.
    /// @return Total artwork count.
    function getTotalArtworksSubmitted() external view returns (uint256) {
        return artworkCounter;
    }

    /// @notice Returns the total number of artworks approved.
    /// @return Total approved artwork count.
    function getTotalArtworksApproved() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i <= artworkCounter; i++) {
            if (artworks[i].status == ArtworkStatus.Approved) {
                count++;
            }
        }
        return count;
    }


    // -------- 2. Governance & Voting Functions --------

    /// @notice Allows members to create various types of proposals.
    /// @param _title Title of the proposal.
    /// @param _description Description of the proposal.
    /// @param _proposalType Type of the proposal (ArtworkApproval, TreasurySpending, RuleChange).
    /// @param _artworkId (Optional) Artwork ID for ArtworkApproval proposals.
    /// @param _recipient (Optional) Recipient address for TreasurySpending proposals.
    /// @param _amount (Optional) Amount for TreasurySpending proposals.
    function createProposal(
        string memory _title,
        string memory _description,
        ProposalType _proposalType,
        uint256 _artworkId,
        address _recipient,
        uint256 _amount
    ) external onlyMember whenNotPaused {
        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            id: proposalCounter,
            title: _title,
            description: _description,
            proposalType: _proposalType,
            status: ProposalStatus.Active,
            startTime: block.number,
            endTime: block.number + votingDurationBlocks,
            votesFor: 0,
            votesAgainst: 0,
            votes: mapping(address => VoteOption)(),
            artworkId: _artworkId,
            recipient: _recipient,
            amount: _amount
        });
        emit ProposalCreated(proposalCounter, _proposalType, _title, msg.sender);
    }

    /// @notice Allows members to vote on active proposals.
    /// @param _proposalId ID of the proposal to vote on.
    /// @param _vote Vote option (For, Against, Abstain).
    function voteOnProposal(uint256 _proposalId, VoteOption _vote) external onlyMember validProposalId(_proposalId) proposalActive(_proposalId) whenNotPaused {
        require(proposals[_proposalId].votes[msg.sender] == VoteOption.Abstain || proposals[_proposalId].votes[msg.sender] == VoteOption.For || proposals[_proposalId].votes[msg.sender] == VoteOption.Against , "Already voted on this proposal."); // Ensure member hasn't voted yet (default is Abstain, so it will not be initial value)
        require(block.number <= proposals[_proposalId].endTime, "Voting period has ended.");

        proposals[_proposalId].votes[msg.sender] = _vote; // Record the vote

        if (_vote == VoteOption.For) {
            proposals[_proposalId].votesFor++;
        } else if (_vote == VoteOption.Against) {
            proposals[_proposalId].votesAgainst++;
        }

        emit ProposalVoted(_proposalId, msg.sender, _vote);

        // Check if voting period ended and potentially execute automatically if threshold reached
        if (block.number >= proposals[_proposalId].endTime) {
            _finalizeProposal(_proposalId);
        }
    }

    /// @notice Executes a proposal if it passes the voting threshold.
    /// @param _proposalId ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyMember validProposalId(_proposalId) proposalPassed(_proposalId) whenNotPaused {
        require(proposals[_proposalId].status != ProposalStatus.Executed, "Proposal already executed.");

        Proposal storage proposal = proposals[_proposalId];

        if (proposal.proposalType == ProposalType.ArtworkApproval) {
            approveArtwork(proposal.artworkId); // Execute artwork approval
        } else if (proposal.proposalType == ProposalType.TreasurySpending) {
            _withdrawTreasuryFunds(proposal.recipient, proposal.amount); // Execute treasury withdrawal
        } else if (proposal.proposalType == ProposalType.RuleChange) {
            // Example: Implement logic for rule changes here (e.g., change voting duration, quorum, etc.)
            // This is a placeholder and needs specific implementation based on rules to be changed.
            // For example, if a proposal is to change quorum percentage, you would update `quorumPercentage` here.
            //  if (proposal.title == "Change Quorum Percentage") {
            //      setQuorumPercentage(proposal.amount); // Assuming proposal.amount contains the new quorum percentage
            //  }
        } else if (proposal.proposalType == ProposalType.MembershipAction) {
            // Example:  Membership approval/revocation could be handled here
            // Logic depends on proposal details - could pass target address in proposal description or parameters
        }

        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalId, ProposalStatus.Executed);
    }

    /// @dev Internal function to finalize a proposal after voting period ends.
    /// @param _proposalId ID of the proposal to finalize.
    function _finalizeProposal(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.status != ProposalStatus.Active || block.number < proposal.endTime) {
            return; // Already finalized or voting not ended yet
        }

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorumNeeded = (memberList.length * quorumPercentage) / 100; // Quorum based on member count
        uint256 votesInFavorPercentage = 0;
        if (totalVotes > 0) {
            votesInFavorPercentage = (proposal.votesFor * 100) / totalVotes;
        }

        if (totalVotes >= quorumNeeded && votesInFavorPercentage > 50) { // Simple majority with quorum
            proposal.status = ProposalStatus.Passed;
            emit ProposalExecuted(_proposalId, ProposalStatus.Passed); // Indicate proposal passed, execution might be separate
        } else {
            proposal.status = ProposalStatus.Rejected;
            emit ProposalExecuted(_proposalId, ProposalStatus.Rejected); // Indicate proposal rejected
        }
    }


    /// @notice Retrieves details of a specific proposal.
    /// @param _proposalId ID of the proposal.
    /// @return Proposal struct containing proposal details.
    function getProposalDetails(uint256 _proposalId) external view validProposalId(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice Returns the vote counts for a specific proposal.
    /// @param _proposalId ID of the proposal.
    /// @return Votes for and votes against.
    function getProposalVoteCount(uint256 _proposalId) external view validProposalId(_proposalId) returns (uint256 votesFor, uint256 votesAgainst) {
        return (proposals[_proposalId].votesFor, proposals[_proposalId].votesAgainst);
    }

    /// @notice Returns a list of IDs of all active proposals.
    /// @return Array of proposal IDs.
    function listActiveProposals() external view returns (uint256[] memory) {
        uint256[] memory activeProposalIds = new uint256[](proposalCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (proposals[i].status == ProposalStatus.Active) {
                activeProposalIds[count] = proposals[i].id;
                count++;
            }
        }
        assembly {
            mstore(activeProposalIds, count)
        }
        return activeProposalIds;
    }

    /// @notice Returns a list of IDs of all executed proposals (passed or rejected).
    /// @return Array of proposal IDs.
    function listExecutedProposals() external view returns (uint256[] memory) {
        uint256[] memory executedProposalIds = new uint256[](proposalCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (proposals[i].status == ProposalStatus.Passed || proposals[i].status == ProposalStatus.Rejected || proposals[i].status == ProposalStatus.Executed) { // Include Executed status too
                executedProposalIds[count] = proposals[i].id;
                count++;
            }
        }
        assembly {
            mstore(executedProposalIds, count)
        }
        return executedProposalIds;
    }


    // -------- 3. Membership & Reputation Functions --------

    /// @notice Allows users to request membership to the DAAC.
    function requestMembership() external whenNotPaused {
        require(!members[msg.sender], "Already a member.");
        require(!membershipRequests[msg.sender], "Membership already requested.");
        membershipRequests[msg.sender] = true;
        emit MembershipRequested(msg.sender);
    }

    /// @notice Allows existing members to approve a membership request.
    /// @param _member Address of the member to approve.
    function approveMembership(address _member) external onlyMember whenNotPaused {
        require(membershipRequests[_member], "No membership request pending for this address.");
        require(!members[_member], "Address is already a member.");

        members[_member] = true;
        memberList.push(_member);
        membershipRequests[_member] = false; // Clear request
        emit MembershipApproved(_member);
    }

    /// @notice Allows governance to revoke membership from a user (needs governance proposal in real scenario).
    /// @param _member Address of the member to revoke.
    function revokeMembership(address _member) external onlyMember whenNotPaused { // In real DAO, revocation should be proposal-based
        require(members[_member], "Address is not a member.");
        require(_member != owner, "Cannot revoke ownership membership."); // Prevent owner from being removed for simplicity

        members[_member] = false;

        // Remove from memberList - inefficient, consider better way if member list is frequently updated
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == _member) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }

        emit MembershipRevoked(_member);
    }

    /// @notice Returns the total number of DAAC members.
    /// @return Member count.
    function getMemberCount() external view returns (uint256) {
        return memberList.length;
    }

    /// @notice Checks if an address is a member of the DAAC.
    /// @param _account Address to check.
    /// @return True if member, false otherwise.
    function isMember(address _account) external view returns (bool) {
        return members[_account];
    }

    /// @notice (Future Enhancement) - Could track reputation based on contribution.
    /// @param _member Address of the member.
    /// @return Member reputation score.
    function getMemberReputation(address _member) external view onlyMember returns (uint256) {
        // Placeholder for reputation system - could be based on voting participation, proposal creation, artwork submission, etc.
        // For now, just return a constant or implement actual reputation logic here.
        return 100; // Example: Default reputation score
    }


    // -------- 4. Treasury & Revenue Functions --------

    /// @notice Allows anyone to deposit funds into the DAAC treasury.
    function depositFunds() external payable whenNotPaused {
        emit FundsDeposited(msg.sender, msg.value);
    }

    /// @notice Allows governance to withdraw funds from the treasury (through proposals).
    /// @param _recipient Address to receive the funds.
    /// @param _amount Amount to withdraw.
    function withdrawFunds(address _recipient, uint256 _amount) external onlyMember whenNotPaused {
        // Check for passed treasury spending proposal
        bool proposalFoundAndPassed = false;
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (proposals[i].proposalType == ProposalType.TreasurySpending &&
                proposals[i].recipient == _recipient &&
                proposals[i].amount == _amount &&
                proposals[i].status == ProposalStatus.Passed) {
                proposalFoundAndPassed = true;
                break;
            }
        }
        require(proposalFoundAndPassed, "Treasury withdrawal requires a passed TreasurySpending proposal.");

        _withdrawTreasuryFunds(_recipient, _amount);
    }

    /// @dev Internal function to withdraw funds from treasury after proposal approval
    function _withdrawTreasuryFunds(address _recipient, uint256 _amount) internal {
        require(address(this).balance >= _amount, "Insufficient treasury balance.");
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Transfer failed.");
        emit FundsWithdrawn(_recipient, _amount);
    }


    /// @notice Returns the current balance of the DAAC treasury.
    /// @return Treasury balance.
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Sets the sale price for an artwork NFT (governed by proposals).
    /// @param _artworkId ID of the artwork.
    /// @param _price Sale price in wei.
    function setArtworkSalePrice(uint256 _artworkId, uint256 _price) external onlyMember validArtworkId(_artworkId) whenNotPaused {
        require(artworks[_artworkId].nftMinted, "NFT must be minted before setting sale price.");

         // Check for passed proposal to set artwork sale price - logic can be expanded
        bool proposalFoundAndPassed = false;
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (proposals[i].proposalType == ProposalType.RuleChange && // Using RuleChange for price setting, could be more specific ProposalType
                proposals[i].artworkId == _artworkId &&
                proposals[i].amount == _price && // Assuming proposal.amount stores the new price
                proposals[i].status == ProposalStatus.Passed) {
                proposalFoundAndPassed = true;
                break;
            }
        }
        require(proposalFoundAndPassed, "Setting artwork sale price requires a passed proposal.");

        artworks[_artworkId].salePrice = _price;
    }

    /// @notice Allows anyone to purchase an artwork NFT, sending funds to the treasury.
    /// @param _artworkId ID of the artwork to purchase.
    function purchaseArtworkNFT(uint256 _artworkId) external payable validArtworkId(_artworkId) whenNotPaused {
        require(artworks[_artworkId].nftMinted, "NFT is not minted yet.");
        require(artworks[_artworkId].salePrice > 0, "Artwork is not for sale or price not set.");
        require(msg.value >= artworks[_artworkId].salePrice, "Insufficient payment.");

        address previousOwner = artworks[_artworkId].nftOwner;
        artworks[_artworkId].nftOwner = msg.sender; // Buyer becomes the NFT owner

        // Transfer funds to treasury
        payable(address(this)).transfer(artworks[_artworkId].salePrice); // Direct transfer to contract address (treasury)

        // Refund any excess payment
        if (msg.value > artworks[_artworkId].salePrice) {
            payable(msg.sender).transfer(msg.value - artworks[_artworkId].salePrice);
        }

        emit ArtworkPurchased(_artworkId, msg.sender, artworks[_artworkId].salePrice);
        emit FundsDeposited(msg.sender, artworks[_artworkId].salePrice); // Also emit deposit event for treasury tracking (optional)
    }


    // -------- 5. Community & Engagement Functions --------

    /// @notice Allows members to submit general community ideas or suggestions.
    /// @param _idea Community idea text.
    function submitCommunityIdea(string memory _idea) external onlyMember whenNotPaused {
        communityIdeas.push(_idea);
        emit CommunityIdeaSubmitted(communityIdeas.length - 1, _idea, msg.sender);
    }

    /// @notice Returns a list of submitted community ideas.
    /// @return Array of community idea strings.
    function listCommunityIdeas() external view returns (string[] memory) {
        return communityIdeas;
    }

    /// @notice Allows members to add comments to specific artworks.
    /// @param _artworkId ID of the artwork to comment on.
    /// @param _comment Comment text.
    function addCommentToArtwork(uint256 _artworkId, string memory _comment) external onlyMember validArtworkId(_artworkId) whenNotPaused {
        artworks[_artworkId].comments.push(_comment);
        emit CommentAddedToArtwork(_artworkId, msg.sender, _comment);
    }

    /// @notice Retrieves comments associated with a specific artwork.
    /// @param _artworkId ID of the artwork.
    /// @return Array of comment strings.
    function getArtworkComments(uint256 _artworkId) external view validArtworkId(_artworkId) returns (string[] memory) {
        return artworks[_artworkId].comments;
    }


    // -------- 6. Utility & Admin Functions --------

    /// @notice Allows the contract owner to pause certain functionalities in case of emergency.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(owner);
    }

    /// @notice Allows the contract owner to unpause the contract.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(owner);
    }

    /// @notice Allows the contract owner to set the default voting duration.
    /// @param _durationInBlocks New voting duration in blocks.
    function setVotingDuration(uint256 _durationInBlocks) external onlyOwner whenNotPaused {
        votingDurationBlocks = _durationInBlocks;
    }

    /// @notice Allows the contract owner to set the quorum percentage for proposals.
    /// @param _percentage New quorum percentage (e.g., 50 for 50%).
    function setQuorumPercentage(uint256 _percentage) external onlyOwner whenNotPaused {
        require(_percentage <= 100, "Quorum percentage must be less than or equal to 100.");
        quorumPercentage = _percentage;
    }

    /// @notice Allows the current owner to transfer contract ownership.
    /// @param newOwner Address of the new owner.
    function transferOwnership(address newOwner) external onlyOwner whenNotPaused {
        require(newOwner != address(0), "New owner address cannot be zero.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        members[newOwner] = true; // New owner becomes a member as well
        memberList.push(newOwner); // Add new owner to member list (if not already there - could check for duplicates in real impl)
    }

    /// @notice Returns the contract version.
    /// @return Contract version string.
    function getVersion() external pure returns (string memory) {
        return VERSION;
    }

    receive() external payable {
        depositFunds(); // Allow direct deposits to the contract address (treasury)
    }

    fallback() external {}
}
```