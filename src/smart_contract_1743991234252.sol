```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art collective.
 * It allows artists to submit art proposals, members to vote on them,
 * mint NFTs for approved artworks, conduct auctions, manage a treasury,
 * and implement a reputation system for members.
 *
 * Function Summary:
 * -----------------
 *
 * **Art Proposal & Curation:**
 * 1. submitArtProposal(string _title, string _description, string _ipfsMetadataHash, address[] _collaborators) - Allows members to submit art proposals with metadata and optional collaborators.
 * 2. getArtProposalDetails(uint256 _proposalId) - Retrieves detailed information about a specific art proposal.
 * 3. voteOnArtProposal(uint256 _proposalId, bool _vote) - Allows members to vote on pending art proposals.
 * 4. finalizeArtProposal(uint256 _proposalId) - Finalizes a proposal after voting, minting NFT if approved, or rejecting it.
 * 5. getProposalVotingStatus(uint256 _proposalId) - Returns the current voting status (pending, approved, rejected) of a proposal.
 * 6. getApprovedArtworks() - Returns a list of IDs of approved artworks.
 *
 * **NFT Minting & Management:**
 * 7. mintArtworkNFT(uint256 _proposalId) - Mints an NFT for an approved artwork proposal (callable by contract owner after approval).
 * 8. setBaseMetadataURI(string _baseURI) - Sets the base URI for NFT metadata (only owner).
 * 9. getNFTMetadataURI(uint256 _tokenId) - Retrieves the full metadata URI for a specific NFT.
 * 10. transferArtworkOwnership(uint256 _tokenId, address _newOwner) - Transfers ownership of an artwork NFT.
 *
 * **Auction & Sales:**
 * 11. createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _durationInSeconds) - Creates an auction for an artwork NFT.
 * 12. bidOnAuction(uint256 _auctionId) - Allows users to bid on an active auction.
 * 13. finalizeAuction(uint256 _auctionId) - Finalizes an auction, transferring NFT to the highest bidder and funds to the treasury.
 * 14. getAuctionDetails(uint256 _auctionId) - Retrieves details of a specific auction.
 *
 * **Treasury Management:**
 * 15. depositToTreasury() payable - Allows anyone to deposit funds into the DAAC treasury.
 * 16. withdrawFromTreasury(address _recipient, uint256 _amount) - Allows the contract owner to withdraw funds from the treasury (e.g., for operational costs, artist grants).
 * 17. getTreasuryBalance() - Returns the current balance of the DAAC treasury.
 *
 * **Reputation & Membership:**
 * 18. addMember(address _member) - Allows the contract owner to add new members to the collective.
 * 19. removeMember(address _member) - Allows the contract owner to remove members from the collective.
 * 20. isMember(address _address) - Checks if an address is a member of the collective.
 * 21. getMemberReputation(address _member) - Retrieves the reputation score of a member (can be expanded with voting weight, etc.).
 * 22. updateMemberReputation(address _member, int256 _reputationChange) - Allows the owner to manually adjust member reputation (e.g., for contributions, misconduct).
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DecentralizedArtCollective is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _proposalIds;
    Counters.Counter private _auctionIds;
    Counters.Counter private _nftTokenIds;

    string public baseMetadataURI;

    struct ArtProposal {
        uint256 proposalId;
        string title;
        string description;
        string ipfsMetadataHash;
        address proposer;
        address[] collaborators;
        uint256 upVotes;
        uint256 downVotes;
        uint256 votingDeadline;
        ProposalStatus status;
    }

    enum ProposalStatus {
        Pending,
        Approved,
        Rejected
    }

    struct Auction {
        uint256 auctionId;
        uint256 tokenId;
        address seller;
        uint256 startingPrice;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool isActive;
    }

    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter => voted
    mapping(uint256 => Auction) public auctions;
    mapping(address => bool) public members;
    mapping(address => int256) public memberReputations; // Example reputation system

    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public votingThresholdPercentage = 50; // Percentage of votes needed for approval

    event ArtProposalSubmitted(uint256 proposalId, address proposer, string title);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalFinalized(uint256 proposalId, ProposalStatus status);
    event ArtworkNFTMinted(uint256 tokenId, uint256 proposalId);
    event AuctionCreated(uint256 auctionId, uint256 tokenId, address seller, uint256 startingPrice, uint256 endTime);
    event AuctionBidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionFinalized(uint256 auctionId, address winner, uint256 winningBid);
    event TreasuryDeposit(address sender, uint256 amount);
    event TreasuryWithdrawal(address recipient, uint256 amount);
    event MemberAdded(address member);
    event MemberRemoved(address member);
    event ReputationUpdated(address member, int256 reputationChange, int256 newReputation);

    modifier onlyMember() {
        require(members[msg.sender], "Only members can perform this action.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _proposalIds.current, "Invalid proposal ID.");
        _;
    }

    modifier validAuction(uint256 _auctionId) {
        require(_auctionId > 0 && _auctionId <= _auctionIds.current, "Invalid auction ID.");
        _;
    }

    constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721(_name, _symbol) {
        baseMetadataURI = _baseURI;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Owner is admin
    }

    /**
     * @dev Sets the base URI for NFT metadata. Only callable by the contract owner.
     * @param _baseURI The new base URI string.
     */
    function setBaseMetadataURI(string memory _baseURI) public onlyOwner {
        baseMetadataURI = _baseURI;
    }

    /**
     * @dev Retrieves the full metadata URI for a specific NFT token.
     * @param _tokenId The ID of the NFT token.
     * @return The full metadata URI string.
     */
    function getNFTMetadataURI(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseMetadataURI, Strings.toString(_tokenId)));
    }

    /**
     * @dev Allows members to submit art proposals.
     * @param _title Title of the artwork proposal.
     * @param _description Description of the artwork proposal.
     * @param _ipfsMetadataHash IPFS hash of the artwork metadata.
     * @param _collaborators Array of addresses of collaborating artists (optional).
     */
    function submitArtProposal(
        string memory _title,
        string memory _description,
        string memory _ipfsMetadataHash,
        address[] memory _collaborators
    ) public onlyMember {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current;
        artProposals[proposalId] = ArtProposal({
            proposalId: proposalId,
            title: _title,
            description: _description,
            ipfsMetadataHash: _ipfsMetadataHash,
            proposer: msg.sender,
            collaborators: _collaborators,
            upVotes: 0,
            downVotes: 0,
            votingDeadline: block.timestamp + votingDuration,
            status: ProposalStatus.Pending
        });
        emit ArtProposalSubmitted(proposalId, msg.sender, _title);
    }

    /**
     * @dev Retrieves detailed information about a specific art proposal.
     * @param _proposalId The ID of the art proposal.
     * @return ArtProposal struct containing proposal details.
     */
    function getArtProposalDetails(uint256 _proposalId) public view validProposal(_proposalId) returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    /**
     * @dev Allows members to vote on pending art proposals.
     * @param _proposalId The ID of the art proposal to vote on.
     * @param _vote True for upvote, false for downvote.
     */
    function voteOnArtProposal(uint256 _proposalId, bool _vote) public onlyMember validProposal(_proposalId) {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal voting is not pending.");
        require(block.timestamp < proposal.votingDeadline, "Voting deadline has passed.");
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal.");

        proposalVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            proposal.upVotes++;
        } else {
            proposal.downVotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Finalizes an art proposal after the voting period. Mints NFT if approved, or rejects it.
     * @param _proposalId The ID of the art proposal to finalize.
     */
    function finalizeArtProposal(uint256 _proposalId) public validProposal(_proposalId) {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not pending.");
        require(block.timestamp >= proposal.votingDeadline, "Voting deadline has not passed yet.");

        uint256 totalVotes = proposal.upVotes + proposal.downVotes;
        uint256 approvalThreshold = (totalVotes * votingThresholdPercentage) / 100;

        if (proposal.upVotes >= approvalThreshold) {
            proposal.status = ProposalStatus.Approved;
            emit ArtProposalFinalized(_proposalId, ProposalStatus.Approved);
            // Minting will be a separate function call for more control/timing if needed.
        } else {
            proposal.status = ProposalStatus.Rejected;
            emit ArtProposalFinalized(_proposalId, ProposalStatus.Rejected);
        }
    }

    /**
     * @dev Returns the current voting status of a proposal.
     * @param _proposalId The ID of the art proposal.
     * @return ProposalStatus enum value (Pending, Approved, Rejected).
     */
    function getProposalVotingStatus(uint256 _proposalId) public view validProposal(_proposalId) returns (ProposalStatus) {
        return artProposals[_proposalId].status;
    }

    /**
     * @dev Returns a list of IDs of approved artworks (proposals that were approved).
     * @return Array of proposal IDs.
     */
    function getApprovedArtworks() public view returns (uint256[] memory) {
        uint256[] memory approvedProposals = new uint256[](_proposalIds.current); // Max size
        uint256 count = 0;
        for (uint256 i = 1; i <= _proposalIds.current; i++) {
            if (artProposals[i].status == ProposalStatus.Approved) {
                approvedProposals[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of approved proposals
        assembly {
            mstore(approvedProposals, count) // Update the length in memory
        }
        return approvedProposals;
    }

    /**
     * @dev Mints an NFT for an approved artwork proposal. Callable by the contract owner after proposal approval.
     * @param _proposalId The ID of the approved art proposal.
     */
    function mintArtworkNFT(uint256 _proposalId) public onlyOwner validProposal(_proposalId) {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.status == ProposalStatus.Approved, "Proposal is not approved.");
        _nftTokenIds.increment();
        uint256 tokenId = _nftTokenIds.current;
        _mint(proposal.proposer, tokenId); // Mint to the proposer (could be adjusted for collaborators in future)
        emit ArtworkNFTMinted(tokenId, _proposalId);
    }

    /**
     * @dev Transfers ownership of an artwork NFT. Standard ERC721 transfer function.
     * @param _tokenId The ID of the NFT token to transfer.
     * @param _newOwner The address of the new owner.
     */
    function transferArtworkOwnership(uint256 _tokenId, address _newOwner) public {
        transferFrom(_msgSender(), _newOwner, _tokenId);
    }

    /**
     * @dev Creates an auction for an artwork NFT. Only the NFT owner can create an auction.
     * @param _tokenId The ID of the NFT token to auction.
     * @param _startingPrice The starting price of the auction in wei.
     * @param _durationInSeconds The duration of the auction in seconds.
     */
    function createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _durationInSeconds) public nonReentrant {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not owner or approved.");
        require(auctions[_auctionIds.current].isActive == false, "Previous auction is still active, finalize it first."); // Simple check to avoid overlapping auctions, can be improved.

        _auctionIds.increment();
        uint256 auctionId = _auctionIds.current;
        auctions[auctionId] = Auction({
            auctionId: auctionId,
            tokenId: _tokenId,
            seller: _msgSender(),
            startingPrice: _startingPrice,
            endTime: block.timestamp + _durationInSeconds,
            highestBidder: address(0),
            highestBid: 0,
            isActive: true
        });
        _approve(address(this), _tokenId); // Approve contract to handle the NFT
        emit AuctionCreated(auctionId, _tokenId, _msgSender(), _startingPrice, auctions[auctionId].endTime);
    }

    /**
     * @dev Allows users to bid on an active auction.
     * @param _auctionId The ID of the auction to bid on.
     */
    function bidOnAuction(uint256 _auctionId) public payable nonReentrant validAuction(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        require(auction.isActive, "Auction is not active.");
        require(block.timestamp < auction.endTime, "Auction has ended.");
        require(msg.value >= auction.startingPrice, "Bid must be at least the starting price.");
        require(msg.value > auction.highestBid, "Bid must be higher than the current highest bid.");

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid); // Refund previous bidder
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        emit AuctionBidPlaced(_auctionId, msg.sender, msg.value);
    }

    /**
     * @dev Finalizes an auction, transferring the NFT to the highest bidder and funds to the treasury.
     * @param _auctionId The ID of the auction to finalize.
     */
    function finalizeAuction(uint256 _auctionId) public nonReentrant validAuction(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        require(auction.isActive, "Auction is not active.");
        require(block.timestamp >= auction.endTime, "Auction has not ended yet.");

        auction.isActive = false;
        if (auction.highestBidder != address(0)) {
            _transfer(auction.seller, auction.highestBidder, auction.tokenId); // Transfer NFT to winner
            payable(owner()).transfer(auction.highestBid); // Send winning bid to treasury (owner for simplicity, could be a dedicated treasury contract/address)
            emit AuctionFinalized(_auctionId, auction.highestBidder, auction.highestBid);
        } else {
            // No bids, return NFT to seller and potentially refund approval
            _approve(auction.seller, auction.tokenId); // Re-approve seller for NFT management
        }
    }

    /**
     * @dev Retrieves details of a specific auction.
     * @param _auctionId The ID of the auction.
     * @return Auction struct containing auction details.
     */
    function getAuctionDetails(uint256 _auctionId) public view validAuction(_auctionId) returns (Auction memory) {
        return auctions[_auctionId];
    }

    /**
     * @dev Allows anyone to deposit funds into the DAAC treasury.
     */
    function depositToTreasury() public payable {
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /**
     * @dev Allows the contract owner to withdraw funds from the treasury.
     * @param _recipient The address to send the funds to.
     * @param _amount The amount of funds to withdraw in wei.
     */
    function withdrawFromTreasury(address _recipient, uint256 _amount) public onlyOwner {
        payable(_recipient).transfer(_amount);
        emit TreasuryWithdrawal(_recipient, _amount);
    }

    /**
     * @dev Returns the current balance of the DAAC treasury.
     * @return The treasury balance in wei.
     */
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Allows the contract owner to add a new member to the collective.
     * @param _member The address of the member to add.
     */
    function addMember(address _member) public onlyOwner {
        members[_member] = true;
        emit MemberAdded(_member);
    }

    /**
     * @dev Allows the contract owner to remove a member from the collective.
     * @param _member The address of the member to remove.
     */
    function removeMember(address _member) public onlyOwner {
        members[_member] = false;
        emit MemberRemoved(_member);
    }

    /**
     * @dev Checks if an address is a member of the collective.
     * @param _address The address to check.
     * @return True if the address is a member, false otherwise.
     */
    function isMember(address _address) public view returns (bool) {
        return members[_address];
    }

    /**
     * @dev Retrieves the reputation score of a member.
     * @param _member The address of the member.
     * @return The member's reputation score.
     */
    function getMemberReputation(address _member) public view returns (int256) {
        return memberReputations[_member];
    }

    /**
     * @dev Allows the owner to manually update a member's reputation.
     * @param _member The address of the member to update.
     * @param _reputationChange The amount to change the reputation by (positive or negative).
     */
    function updateMemberReputation(address _member, int256 _reputationChange) public onlyOwner {
        memberReputations[_member] += _reputationChange;
        emit ReputationUpdated(_member, _reputationChange, memberReputations[_member]);
    }

    // ** --- Optional Functions & Future Enhancements --- **
    // - Set Voting Duration & Threshold (Owner only)
    // - Batch NFT Minting for multiple approved proposals (Owner only)
    // - Collaborative NFT minting and revenue splitting for collaborators.
    // - More sophisticated reputation system based on on-chain activity (voting, proposal submissions, etc.)
    // - DAO governance features (proposals for rule changes, treasury spending, etc.)
    // - Royalties on secondary sales of NFTs.
    // - Integration with IPFS or other decentralized storage for metadata.
    // - Support for different auction types (e.g., Dutch auction).
    // - Tiered membership levels with different voting weights/privileges based on reputation or other criteria.
}
```