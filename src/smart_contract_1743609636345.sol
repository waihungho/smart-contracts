```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAAG)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art gallery, enabling artists to submit,
 *      curators to manage, and users to interact with digital art pieces (represented as NFTs).
 *
 * **Outline and Function Summary:**
 *
 * **Core Functionality:**
 * 1. `submitArt(string memory _artCID, string memory _metadataCID)`: Artists submit their art (identified by content CID and metadata CID) for gallery consideration.
 * 2. `mintGalleryPass(address _to)`: Platform owner can mint a "Gallery Pass" NFT to a user, granting them curator/voting rights.
 * 3. `transferGalleryPass(uint256 _tokenId, address _to)`: Allow transfer of Gallery Pass NFTs.
 * 4. `burnGalleryPass(uint256 _tokenId)`: Platform owner can burn a Gallery Pass NFT.
 * 5. `getArtDetails(uint256 _artId)`: Retrieve details of a submitted art piece.
 * 6. `isArtApproved(uint256 _artId)`: Check if an art piece is approved for the gallery.
 *
 * **Curation and Governance:**
 * 7. `proposeArtForGallery(uint256 _artId)`: Gallery Pass holders can propose submitted art to be featured in the gallery.
 * 8. `voteOnArtProposal(uint256 _proposalId, bool _vote)`: Gallery Pass holders can vote on art proposals.
 * 9. `executeArtProposal(uint256 _proposalId)`: Execute a successful art proposal, adding the art to the gallery.
 * 10. `createCuratorProposal(string memory _proposalDescription, bytes memory _calldata)`: Gallery Pass holders can propose changes to gallery parameters or actions.
 * 11. `voteOnCuratorProposal(uint256 _proposalId, bool _vote)`: Gallery Pass holders vote on curator proposals.
 * 12. `executeCuratorProposal(uint256 _proposalId)`: Execute a successful curator proposal.
 *
 * **Gallery Interaction and Features:**
 * 13. `purchaseArt(uint256 _artId)`: Users can purchase approved art directly from the gallery (concept for revenue sharing).
 * 14. `donateToArtist(uint256 _artId)`: Users can donate to the artist of a specific artwork.
 * 15. `sponsorArtwork(uint256 _artId, uint256 _durationInDays)`: Users can sponsor an artwork to boost its visibility for a certain duration.
 * 16. `reportArtwork(uint256 _artId, string memory _reportReason)`: Users can report artwork for inappropriate content.
 * 17. `withdrawArtistEarnings(uint256 _artId)`: Artists can withdraw their earnings from art sales or donations.
 * 18. `setGalleryFee(uint256 _feePercentage)`: Platform owner can set a fee percentage for art sales.
 * 19. `withdrawGalleryFees()`: Platform owner can withdraw accumulated gallery fees.
 * 20. `setCuratorThreshold(uint256 _threshold)`: Platform owner can adjust the curator pass threshold.
 * 21. `setGalleryPassPrice(uint256 _price)`: Platform owner can set the price of a Gallery Pass (if monetized).
 * 22. `setPlatformOwner(address _newOwner)`: Platform owner can transfer ownership of the contract.
 * 23. `pauseContract()`: Platform owner can pause the contract in case of emergency.
 * 24. `unpauseContract()`: Platform owner can unpause the contract.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DecentralizedAutonomousArtGallery is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _artIdCounter;
    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _galleryPassIdCounter;

    // --- Structs and Enums ---

    struct ArtPiece {
        uint256 artId;
        address artist;
        string artCID; // Content Identifier for the art itself (e.g., IPFS CID)
        string metadataCID; // Content Identifier for art metadata (e.g., IPFS CID)
        bool submitted;
        bool approved;
        uint256 purchasePrice;
        uint256 earnings;
        uint256 sponsorshipExpiry; // Timestamp of sponsorship expiry
        uint256 reportCount;
    }

    struct ArtProposal {
        uint256 proposalId;
        uint256 artId;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        mapping(address => bool) voters; // Track voters to prevent double voting
    }

    struct CuratorProposal {
        uint256 proposalId;
        string description;
        bytes calldata; // Calldata to execute if proposal passes
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        mapping(address => bool) voters; // Track voters to prevent double voting
    }

    // --- State Variables ---

    mapping(uint256 => ArtPiece) public artPieces;
    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => CuratorProposal) public curatorProposals;
    mapping(address => bool) public galleryPassHolders; // Addresses with Gallery Pass
    uint256 public galleryPassPrice; // Price to mint a Gallery Pass (optional, can be 0 for free passes)
    uint256 public curatorThreshold = 50; // Percentage of votes needed for proposal to pass (e.g., 50 = 50%)
    uint256 public galleryFeePercentage = 5; // Percentage fee on art sales
    uint256 public galleryFeesCollected;

    // --- Events ---

    event ArtSubmitted(uint256 artId, address artist, string artCID, string metadataCID);
    event ArtProposedForGallery(uint256 proposalId, uint256 artId, address proposer);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalExecuted(uint256 proposalId, uint256 artId);
    event CuratorProposalCreated(uint256 proposalId, string description, address proposer);
    event CuratorProposalVoted(uint256 proposalId, address voter, bool vote);
    event CuratorProposalExecuted(uint256 proposalId);
    event ArtPurchased(uint256 artId, address buyer, uint256 price);
    event DonationMade(uint256 artId, address donator, uint256 amount);
    event ArtworkSponsored(uint256 artId, address sponsor, uint256 durationDays, uint256 expiryTimestamp);
    event ArtworkReported(uint256 artId, address reporter, string reason);
    event ArtistEarningsWithdrawn(uint256 artId, address artist, uint256 amount);
    event GalleryFeeSet(uint256 feePercentage);
    event GalleryFeesWithdrawn(uint256 amount);
    event CuratorThresholdSet(uint256 threshold);
    event GalleryPassPriceSet(uint256 price);
    event PlatformOwnerChanged(address newOwner);
    event ContractPaused();
    event ContractUnpaused();
    event GalleryPassMinted(uint256 tokenId, address to);
    event GalleryPassTransferred(uint256 tokenId, address from, address to);
    event GalleryPassBurned(uint256 tokenId, address burner);


    // --- Modifiers ---

    modifier onlyGalleryPassHolder() {
        require(galleryPassHolders[msg.sender], "Not a Gallery Pass holder");
        _;
    }

    modifier onlyApprovedArt(uint256 _artId) {
        require(artPieces[_artId].approved, "Art is not approved for gallery");
        _;
    }

    modifier validArtId(uint256 _artId) {
        require(artPieces[_artId].submitted, "Invalid Art ID");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _proposalIdCounter.current, "Invalid Proposal ID");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!_getProposalExecuted(_proposalId), "Proposal already executed");
        _;
    }

    modifier notVotedYet(uint256 _proposalId) {
        require(!_hasVoted(msg.sender, _proposalId), "Already voted on this proposal");
        _;
    }

    // --- Constructor ---

    constructor() ERC721("GalleryPass", "GPASS") {
        galleryPassPrice = 0; // Default to free passes initially
    }

    // --- Core Functionality ---

    /// @dev Artists submit their art for gallery consideration.
    /// @param _artCID Content Identifier (CID) for the art itself.
    /// @param _metadataCID Content Identifier (CID) for art metadata.
    function submitArt(string memory _artCID, string memory _metadataCID) public whenNotPaused {
        _artIdCounter.increment();
        uint256 artId = _artIdCounter.current;
        artPieces[artId] = ArtPiece({
            artId: artId,
            artist: msg.sender,
            artCID: _artCID,
            metadataCID: _metadataCID,
            submitted: true,
            approved: false,
            purchasePrice: 0,
            earnings: 0,
            sponsorshipExpiry: 0,
            reportCount: 0
        });
        emit ArtSubmitted(artId, msg.sender, _artCID, _metadataCID);
    }

    /// @dev Platform owner can mint a "Gallery Pass" NFT to a user.
    /// @param _to Address to receive the Gallery Pass.
    function mintGalleryPass(address _to) public onlyOwner whenNotPaused {
        _galleryPassIdCounter.increment();
        uint256 tokenId = _galleryPassIdCounter.current;
        _mint(_to, tokenId);
        galleryPassHolders[_to] = true;
        emit GalleryPassMinted(tokenId, _to);
    }

    /// @dev Allow transfer of Gallery Pass NFTs.
    /// @param _tokenId Token ID of the Gallery Pass to transfer.
    /// @param _to Address to transfer the Gallery Pass to.
    function transferGalleryPass(uint256 _tokenId, address _to) public whenNotPaused {
        address from = ERC721.ownerOf(_tokenId);
        require(from == msg.sender, "Sender is not owner of Gallery Pass");
        _transfer(from, _to, _tokenId);
        galleryPassHolders[from] = false; // Revoke holder status from sender
        galleryPassHolders[_to] = true;    // Grant holder status to receiver
        emit GalleryPassTransferred(_tokenId, from, _to);
    }

    /// @dev Platform owner can burn a Gallery Pass NFT, revoking curator rights.
    /// @param _tokenId Token ID of the Gallery Pass to burn.
    function burnGalleryPass(uint256 _tokenId) public onlyOwner whenNotPaused {
        address ownerOfPass = ERC721.ownerOf(_tokenId);
        galleryPassHolders[ownerOfPass] = false;
        _burn(_tokenId);
        emit GalleryPassBurned(_tokenId, ownerOfPass);
    }

    /// @dev Retrieve details of a submitted art piece.
    /// @param _artId ID of the art piece.
    /// @return ArtPiece struct containing art details.
    function getArtDetails(uint256 _artId) public view validArtId(_artId) returns (ArtPiece memory) {
        return artPieces[_artId];
    }

    /// @dev Check if an art piece is approved for the gallery.
    /// @param _artId ID of the art piece.
    /// @return True if approved, false otherwise.
    function isArtApproved(uint256 _artId) public view validArtId(_artId) returns (bool) {
        return artPieces[_artId].approved;
    }

    // --- Curation and Governance ---

    /// @dev Gallery Pass holders can propose submitted art to be featured in the gallery.
    /// @param _artId ID of the art piece to propose.
    function proposeArtForGallery(uint256 _artId) public onlyGalleryPassHolder whenNotPaused validArtId(_artId) {
        require(!artPieces[_artId].approved, "Art is already approved");
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current;
        artProposals[proposalId] = ArtProposal({
            proposalId: proposalId,
            artId: _artId,
            proposer: msg.sender,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            voters: mapping(address => bool)()
        });
        emit ArtProposedForGallery(proposalId, _artId, msg.sender);
    }

    /// @dev Gallery Pass holders can vote on art proposals.
    /// @param _proposalId ID of the art proposal.
    /// @param _vote True for vote in favor, false for vote against.
    function voteOnArtProposal(uint256 _proposalId, bool _vote)
        public
        onlyGalleryPassHolder
        whenNotPaused
        validProposalId(_proposalId)
        proposalNotExecuted(_proposalId)
        notVotedYet(_proposalId)
    {
        ArtProposal storage proposal = artProposals[_proposalId];
        proposal.voters[msg.sender] = true; // Mark voter as voted

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @dev Execute a successful art proposal, adding the art to the gallery if enough votes are cast.
    /// @param _proposalId ID of the art proposal to execute.
    function executeArtProposal(uint256 _proposalId)
        public
        onlyGalleryPassHolder
        whenNotPaused
        validProposalId(_proposalId)
        proposalNotExecuted(_proposalId)
    {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal not initialized"); // Sanity check

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 curatorCount = _balanceOf(address(this)); // Approximate curator count, might need adjustment
        require(curatorCount > 0, "No curators available to vote."); // Prevent division by zero if no curators
        uint256 requiredVotes = curatorCount.mul(curatorThreshold).div(100);

        require(proposal.votesFor >= requiredVotes, "Proposal does not meet approval threshold");

        artPieces[proposal.artId].approved = true;
        proposal.executed = true;
        emit ArtProposalExecuted(_proposalId, proposal.artId);
    }

    /// @dev Gallery Pass holders can create proposals to change gallery parameters or actions.
    /// @param _proposalDescription Description of the curator proposal.
    /// @param _calldata Encoded function call data to be executed if the proposal passes.
    function createCuratorProposal(string memory _proposalDescription, bytes memory _calldata)
        public
        onlyGalleryPassHolder
        whenNotPaused
    {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current;
        curatorProposals[proposalId] = CuratorProposal({
            proposalId: proposalId,
            description: _proposalDescription,
            calldata: _calldata,
            proposer: msg.sender,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            voters: mapping(address => bool)()
        });
        emit CuratorProposalCreated(proposalId, _proposalDescription, msg.sender);
    }

    /// @dev Gallery Pass holders vote on curator proposals.
    /// @param _proposalId ID of the curator proposal.
    /// @param _vote True for vote in favor, false for vote against.
    function voteOnCuratorProposal(uint256 _proposalId, bool _vote)
        public
        onlyGalleryPassHolder
        whenNotPaused
        validProposalId(_proposalId)
        proposalNotExecuted(_proposalId)
        notVotedYet(_proposalId)
    {
        CuratorProposal storage proposal = curatorProposals[_proposalId];
        proposal.voters[msg.sender] = true; // Mark voter as voted

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit CuratorProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @dev Execute a successful curator proposal, enacting the proposed changes.
    /// @param _proposalId ID of the curator proposal to execute.
    function executeCuratorProposal(uint256 _proposalId)
        public
        onlyGalleryPassHolder
        whenNotPaused
        validProposalId(_proposalId)
        proposalNotExecuted(_proposalId)
    {
        CuratorProposal storage proposal = curatorProposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal not initialized"); // Sanity check

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 curatorCount = _balanceOf(address(this)); // Approximate curator count
        require(curatorCount > 0, "No curators available to vote."); // Prevent division by zero if no curators
        uint256 requiredVotes = curatorCount.mul(curatorThreshold).div(100);

        require(proposal.votesFor >= requiredVotes, "Proposal does not meet approval threshold");

        (bool success, ) = address(this).call(proposal.calldata);
        require(success, "Curator proposal execution failed");

        proposal.executed = true;
        emit CuratorProposalExecuted(_proposalId);
    }

    // --- Gallery Interaction and Features ---

    /// @dev Users can purchase approved art directly from the gallery.
    /// @param _artId ID of the art piece to purchase.
    function purchaseArt(uint256 _artId) public payable whenNotPaused validArtId(_artId) onlyApprovedArt(_artId) {
        require(artPieces[_artId].purchasePrice > 0, "Art is not for sale");
        require(msg.value >= artPieces[_artId].purchasePrice, "Insufficient payment");

        uint256 artistShare = artPieces[_artId].purchasePrice.mul(100 - galleryFeePercentage).div(100);
        uint256 galleryFee = artPieces[_artId].purchasePrice.mul(galleryFeePercentage).div(100);

        artPieces[_artId].earnings = artPieces[_artId].earnings.add(artistShare);
        galleryFeesCollected = galleryFeesCollected.add(galleryFee);

        payable(artPieces[_artId].artist).transfer(artistShare);
        // Gallery fees are accumulated and withdrawn by the owner later.

        emit ArtPurchased(_artId, msg.sender, artPieces[_artId].purchasePrice);
    }

    /// @dev Users can donate to the artist of a specific artwork.
    /// @param _artId ID of the art piece to donate to.
    function donateToArtist(uint256 _artId) public payable whenNotPaused validArtId(_artId) onlyApprovedArt(_artId) {
        require(msg.value > 0, "Donation amount must be greater than zero");
        artPieces[_artId].earnings = artPieces[_artId].earnings.add(msg.value);
        payable(artPieces[_artId].artist).transfer(msg.value); // Directly transfer donation
        emit DonationMade(_artId, msg.sender, msg.value);
    }

    /// @dev Users can sponsor an artwork to boost its visibility for a certain duration.
    /// @param _artId ID of the art piece to sponsor.
    /// @param _durationInDays Duration of sponsorship in days.
    function sponsorArtwork(uint256 _artId, uint256 _durationInDays) public payable whenNotPaused validArtId(_artId) onlyApprovedArt(_artId) {
        // Example sponsorship cost (can be configurable or based on duration)
        uint256 sponsorshipCost = _durationInDays.mul(1 ether); // Example: 1 ether per day

        require(msg.value >= sponsorshipCost, "Insufficient sponsorship funds");

        artPieces[_artId].sponsorshipExpiry = block.timestamp + (_durationInDays * 1 days); // Set expiry timestamp
        payable(owner()).transfer(msg.value); // Sponsorship funds go to platform owner for gallery maintenance/rewards.

        emit ArtworkSponsored(_artId, msg.sender, _durationInDays, artPieces[_artId].sponsorshipExpiry);
    }

    /// @dev Users can report artwork for inappropriate content.
    /// @param _artId ID of the art piece to report.
    /// @param _reportReason Reason for reporting the artwork.
    function reportArtwork(uint256 _artId, string memory _reportReason) public whenNotPaused validArtId(_artId) {
        artPieces[_artId].reportCount++;
        emit ArtworkReported(_artId, msg.sender, _reportReason);
        // In a real application, you would implement a moderation process based on report counts.
    }

    /// @dev Artists can withdraw their earnings from art sales or donations.
    /// @param _artId ID of the art piece for which to withdraw earnings.
    function withdrawArtistEarnings(uint256 _artId) public whenNotPaused validArtId(_artId) {
        require(artPieces[_artId].artist == msg.sender, "Not the artist of this artwork");
        uint256 amountToWithdraw = artPieces[_artId].earnings;
        require(amountToWithdraw > 0, "No earnings to withdraw");

        artPieces[_artId].earnings = 0; // Reset earnings after withdrawal
        payable(msg.sender).transfer(amountToWithdraw);
        emit ArtistEarningsWithdrawn(_artId, msg.sender, amountToWithdraw);
    }

    // --- Platform Owner Functions ---

    /// @dev Platform owner can set the gallery fee percentage for art sales.
    /// @param _feePercentage New gallery fee percentage (0-100).
    function setGalleryFee(uint256 _feePercentage) public onlyOwner whenNotPaused {
        require(_feePercentage <= 100, "Fee percentage must be between 0 and 100");
        galleryFeePercentage = _feePercentage;
        emit GalleryFeeSet(_feePercentage);
    }

    /// @dev Platform owner can withdraw accumulated gallery fees.
    function withdrawGalleryFees() public onlyOwner whenNotPaused {
        require(galleryFeesCollected > 0, "No gallery fees collected");
        uint256 amountToWithdraw = galleryFeesCollected;
        galleryFeesCollected = 0;
        payable(owner()).transfer(amountToWithdraw);
        emit GalleryFeesWithdrawn(amountToWithdraw);
    }

    /// @dev Platform owner can adjust the curator pass vote threshold percentage.
    /// @param _threshold New threshold percentage (0-100).
    function setCuratorThreshold(uint256 _threshold) public onlyOwner whenNotPaused {
        require(_threshold <= 100, "Threshold percentage must be between 0 and 100");
        curatorThreshold = _threshold;
        emit CuratorThresholdSet(_threshold);
    }

    /// @dev Platform owner can set the price of a Gallery Pass (if monetization is desired).
    /// @param _price Price for a Gallery Pass in wei.
    function setGalleryPassPrice(uint256 _price) public onlyOwner whenNotPaused {
        galleryPassPrice = _price;
        emit GalleryPassPriceSet(_price);
    }

    /// @dev Platform owner can transfer ownership of the contract.
    /// @param _newOwner Address of the new platform owner.
    function setPlatformOwner(address _newOwner) public onlyOwner whenNotPaused {
        transferOwnership(_newOwner);
        emit PlatformOwnerChanged(_newOwner);
    }

    /// @dev Platform owner can pause the contract in case of emergency.
    function pauseContract() public onlyOwner whenNotPaused {
        _pause();
        emit ContractPaused();
    }

    /// @dev Platform owner can unpause the contract to resume normal operation.
    function unpauseContract() public onlyOwner whenPaused {
        _unpause();
        emit ContractUnpaused();
    }

    // --- Internal Helper Functions ---

    function _hasVoted(address _voter, uint256 _proposalId) internal view returns (bool) {
        if (_proposalId <= _proposalIdCounter.current) {
            if (artProposals[_proposalId].proposalId == _proposalId) {
                return artProposals[_proposalId].voters[_voter];
            } else if (curatorProposals[_proposalId].proposalId == _proposalId) {
                return curatorProposals[_proposalId].voters[_voter];
            }
        }
        return false; // Proposal ID might be invalid or of a different type.
    }

    function _getProposalExecuted(uint256 _proposalId) internal view returns (bool) {
         if (_proposalId <= _proposalIdCounter.current) {
            if (artProposals[_proposalId].proposalId == _proposalId) {
                return artProposals[_proposalId].executed;
            } else if (curatorProposals[_proposalId].proposalId == _proposalId) {
                return curatorProposals[_proposalId].executed;
            }
        }
        return false; // Proposal ID might be invalid or of a different type.
    }

    // --- Fallback and Receive (Optional, for direct ETH receiving if needed) ---

    receive() external payable {}
    fallback() external payable {}
}
```