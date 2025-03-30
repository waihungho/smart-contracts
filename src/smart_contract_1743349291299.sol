```solidity
/**
 * @title Decentralized Autonomous Art Gallery (DAAG) - Advanced Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art gallery where artists can submit artworks,
 * curators can vote on exhibitions, and collectors can purchase and support art.
 * This contract incorporates advanced concepts like dynamic pricing, decentralized governance,
 * community curation, and artist revenue sharing, aiming to be creative and trendy.
 *
 * **Outline and Function Summary:**
 *
 * **1. Art Management Functions (Artist Role):**
 *    - `submitArtwork(string _artworkURI, uint256 _initialPrice)`: Allows artists to submit new artworks to the gallery with an initial price.
 *    - `setArtworkPrice(uint256 _artworkId, uint256 _newPrice)`: Allows artists to update the price of their artwork.
 *    - `removeArtwork(uint256 _artworkId)`: Allows artists to remove their artwork from the gallery (with potential restrictions).
 *    - `getArtistArtworks(address _artist)`: Retrieves a list of artwork IDs submitted by a specific artist.
 *
 * **2. Curation and Exhibition Functions (Curator/Community Role):**
 *    - `proposeArtworkForExhibition(uint256 _artworkId)`: Allows community members to propose artworks for exhibition.
 *    - `voteOnExhibitionProposal(uint256 _proposalId, bool _vote)`: Allows registered curators to vote on artwork exhibition proposals.
 *    - `enactExhibitionProposal(uint256 _proposalId)`: Executes an exhibition proposal if it passes (reaches quorum and majority).
 *    - `getCurrentExhibitions()`: Returns a list of artwork IDs currently on exhibition.
 *    - `getAllProposals()`: Returns a list of all exhibition proposal IDs.
 *    - `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific exhibition proposal.
 *
 * **3. Sales and Revenue Functions (Collector/Artist/Gallery Role):**
 *    - `purchaseArtwork(uint256 _artworkId)`: Allows collectors to purchase artworks from the gallery.
 *    - `donateToArtist(uint256 _artworkId)`: Allows collectors to donate to a specific artist whose artwork is in the gallery.
 *    - `withdrawArtistEarnings()`: Allows artists to withdraw their accumulated earnings from sales and donations.
 *    - `getArtworkSalesHistory(uint256 _artworkId)`: Retrieves the sales history for a specific artwork.
 *
 * **4. Governance and Parameter Setting Functions (DAO/Owner Role):**
 *    - `registerCurator(address _curator)`: Allows the contract owner (or DAO) to register new curators.
 *    - `removeCurator(address _curator)`: Allows the contract owner (or DAO) to remove curators.
 *    - `setGalleryFee(uint256 _newFeePercentage)`: Allows the contract owner (or DAO) to set the gallery fee percentage.
 *    - `setProposalQuorum(uint256 _newQuorum)`: Allows the contract owner (or DAO) to set the quorum for exhibition proposals.
 *    - `withdrawGalleryFees()`: Allows the contract owner (or DAO) to withdraw accumulated gallery fees for maintenance or development.
 *    - `getGalleryParameters()`: Retrieves current gallery parameters (fee, quorum, etc.).
 *
 * **5. Utility and Information Functions (Public):**
 *    - `getArtworkDetails(uint256 _artworkId)`: Retrieves detailed information about a specific artwork.
 *    - `getGalleryBalance()`: Returns the current balance of the gallery contract.
 *    - `isArtworkExhibited(uint256 _artworkId)`: Checks if an artwork is currently being exhibited.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DecentralizedAutonomousArtGallery is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    Counters.Counter private _artworkIds;
    Counters.Counter private _proposalIds;

    struct Artwork {
        uint256 id;
        string artworkURI;
        address artist;
        uint256 price;
        bool isExhibited;
        uint256 salesCount;
        uint256 donationAmount;
    }

    struct ExhibitionProposal {
        uint256 id;
        uint256 artworkId;
        address proposer;
        uint256 yesVotes;
        uint256 noVotes;
        bool isActive;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => Artwork) public artworks;
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;
    mapping(address => bool) public curators;
    mapping(address => uint256) public artistEarnings; // Track artist earnings

    uint256 public galleryFeePercentage = 5; // Default gallery fee percentage (5%)
    uint256 public proposalQuorum = 5;      // Default quorum for exhibition proposals (5 votes)
    address payable public galleryWallet;     // Wallet to receive gallery fees

    // List to track exhibited artworks and proposals for easy access
    uint256[] public exhibitedArtworkIds;
    uint256[] public proposalIdsList;

    // --- Events ---
    event ArtworkSubmitted(uint256 artworkId, address artist, string artworkURI, uint256 initialPrice);
    event ArtworkPriceUpdated(uint256 artworkId, uint256 newPrice);
    event ArtworkRemoved(uint256 artworkId, address artist);
    event ArtworkExhibitionProposed(uint256 proposalId, uint256 artworkId, address proposer);
    event ExhibitionVoteCasted(uint256 proposalId, address curator, bool vote);
    event ExhibitionProposalEnacted(uint256 proposalId, uint256 artworkId, bool isExhibited);
    event ArtworkPurchased(uint256 artworkId, address buyer, address artist, uint256 price, uint256 galleryFee);
    event DonationToArtist(uint256 artworkId, address donor, address artist, uint256 amount);
    event ArtistEarningsWithdrawn(address artist, uint256 amount);
    event CuratorRegistered(address curator);
    event CuratorRemoved(address curator);
    event GalleryFeeSet(uint256 newFeePercentage);
    event ProposalQuorumSet(uint256 newQuorum);
    event GalleryFeesWithdrawn(address wallet, uint256 amount);

    // --- Modifiers ---
    modifier onlyCurator() {
        require(curators[msg.sender], "Only curators can perform this action");
        _;
    }

    modifier artworkExists(uint256 _artworkId) {
        require(_artworkId > 0 && _artworkId <= _artworkIds.current() && artworks[_artworkId].id == _artworkId, "Artwork does not exist");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _proposalIds.current() && exhibitionProposals[_proposalId].id == _proposalId, "Proposal does not exist");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(exhibitionProposals[_proposalId].isActive, "Proposal is not active");
        _;
    }

    modifier notVotedYet(uint256 _proposalId) {
        require(!exhibitionProposals[_proposalId].hasVoted[msg.sender], "Curator has already voted on this proposal");
        _;
    }

    // --- Constructor ---
    constructor(address payable _galleryWallet) payable Ownable() {
        galleryWallet = _galleryWallet;
        // Optionally register the contract owner as the first curator
        curators[owner()] = true;
    }

    // --- 1. Art Management Functions ---

    function submitArtwork(string memory _artworkURI, uint256 _initialPrice) public {
        _artworkIds.increment();
        uint256 artworkId = _artworkIds.current();
        artworks[artworkId] = Artwork({
            id: artworkId,
            artworkURI: _artworkURI,
            artist: msg.sender,
            price: _initialPrice,
            isExhibited: false,
            salesCount: 0,
            donationAmount: 0
        });
        emit ArtworkSubmitted(artworkId, msg.sender, _artworkURI, _initialPrice);
    }

    function setArtworkPrice(uint256 _artworkId, uint256 _newPrice) public artworkExists(_artworkId) {
        require(artworks[_artworkId].artist == msg.sender, "Only artist can set artwork price");
        artworks[_artworkId].price = _newPrice;
        emit ArtworkPriceUpdated(_artworkId, _newPrice);
    }

    function removeArtwork(uint256 _artworkId) public artworkExists(_artworkId) {
        require(artworks[_artworkId].artist == msg.sender, "Only artist can remove artwork");
        // Consider adding restrictions: e.g., cannot remove if exhibited or recently sold.
        delete artworks[_artworkId]; // Remove artwork data. Consider marking as 'removed' instead of deleting in production.
        emit ArtworkRemoved(_artworkId, msg.sender);
    }

    function getArtistArtworks(address _artist) public view returns (uint256[] memory) {
        uint256[] memory artistArtworkIds = new uint256[](_artworkIds.current()); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= _artworkIds.current(); i++) {
            if (artworks[i].artist == _artist && artworks[i].id != 0) { // Check id != 0 to skip deleted slots (if not using delete)
                artistArtworkIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of artworks
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = artistArtworkIds[i];
        }
        return result;
    }


    // --- 2. Curation and Exhibition Functions ---

    function proposeArtworkForExhibition(uint256 _artworkId) public artworkExists(_artworkId) {
        require(!artworks[_artworkId].isExhibited, "Artwork is already exhibited");
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();
        exhibitionProposals[proposalId] = ExhibitionProposal({
            id: proposalId,
            artworkId: _artworkId,
            proposer: msg.sender,
            yesVotes: 0,
            noVotes: 0,
            isActive: true,
            hasVoted: mapping(address => bool)() // Initialize empty mapping
        });
        proposalIdsList.push(proposalId);
        emit ArtworkExhibitionProposed(proposalId, _artworkId, msg.sender);
    }

    function voteOnExhibitionProposal(uint256 _proposalId, bool _vote) public onlyCurator proposalExists(_proposalId) proposalActive(_proposalId) notVotedYet(_proposalId) {
        exhibitionProposals[_proposalId].hasVoted[msg.sender] = true;
        if (_vote) {
            exhibitionProposals[_proposalId].yesVotes++;
        } else {
            exhibitionProposals[_proposalId].noVotes++;
        }
        emit ExhibitionVoteCasted(_proposalId, msg.sender, _vote);
    }

    function enactExhibitionProposal(uint256 _proposalId) public proposalExists(_proposalId) proposalActive(_proposalId) {
        require(exhibitionProposals[_proposalId].yesVotes >= proposalQuorum, "Proposal does not meet quorum");
        require(exhibitionProposals[_proposalId].yesVotes > exhibitionProposals[_proposalId].noVotes, "Proposal does not have majority yes votes");

        uint256 artworkId = exhibitionProposals[_proposalId].artworkId;
        artworks[artworkId].isExhibited = true;
        exhibitedArtworkIds.push(artworkId);
        exhibitionProposals[_proposalId].isActive = false; // Mark proposal as enacted
        emit ExhibitionProposalEnacted(_proposalId, artworkId, true);
    }

    function getCurrentExhibitions() public view returns (uint256[] memory) {
        return exhibitedArtworkIds;
    }

    function getAllProposals() public view returns (uint256[] memory) {
        return proposalIdsList;
    }

    function getProposalDetails(uint256 _proposalId) public view proposalExists(_proposalId) returns (ExhibitionProposal memory) {
        return exhibitionProposals[_proposalId];
    }


    // --- 3. Sales and Revenue Functions ---

    function purchaseArtwork(uint256 _artworkId) public payable artworkExists(_artworkId) {
        require(artworks[_artworkId].isExhibited, "Artwork must be exhibited to be purchased");
        uint256 artworkPrice = artworks[_artworkId].price;
        require(msg.value >= artworkPrice, "Insufficient funds sent");

        uint256 galleryFee = artworkPrice.mul(galleryFeePercentage).div(100);
        uint256 artistPayment = artworkPrice.sub(galleryFee);

        // Transfer artist payment
        (bool successArtist, ) = payable(artworks[_artworkId].artist).call{value: artistPayment}("");
        require(successArtist, "Artist payment transfer failed");
        artistEarnings[artworks[_artworkId].artist] = artistEarnings[artworks[_artworkId].artist].add(artistPayment); // Track earnings

        // Transfer gallery fee
        (bool successGallery, ) = galleryWallet.call{value: galleryFee}("");
        require(successGallery, "Gallery fee transfer failed");

        artworks[_artworkId].salesCount++;

        // Refund any extra ETH sent
        if (msg.value > artworkPrice) {
            payable(msg.sender).transfer(msg.value - artworkPrice);
        }

        emit ArtworkPurchased(_artworkId, msg.sender, artworks[_artworkId].artist, artworkPrice, galleryFee);
    }

    function donateToArtist(uint256 _artworkId) public payable artworkExists(_artworkId) {
        require(artworks[_artworkId].isExhibited, "Donations only accepted for exhibited artworks");
        require(msg.value > 0, "Donation amount must be greater than zero");

        uint256 donationAmount = msg.value;

        // Transfer donation directly to artist
        (bool successArtist, ) = payable(artworks[_artworkId].artist).call{value: donationAmount}("");
        require(successArtist, "Artist donation transfer failed");
        artistEarnings[artworks[_artworkId].artist] = artistEarnings[artworks[_artworkId].artist].add(donationAmount); // Track earnings
        artworks[_artworkId].donationAmount = artworks[_artworkId].donationAmount.add(donationAmount);

        emit DonationToArtist(_artworkId, msg.sender, artworks[_artworkId].artist, donationAmount);
    }

    function withdrawArtistEarnings() public {
        uint256 earnings = artistEarnings[msg.sender];
        require(earnings > 0, "No earnings to withdraw");

        artistEarnings[msg.sender] = 0; // Reset artist earnings balance
        (bool success, ) = payable(msg.sender).call{value: earnings}("");
        require(success, "Artist earnings withdrawal failed");
        emit ArtistEarningsWithdrawn(msg.sender, earnings);
    }

    function getArtworkSalesHistory(uint256 _artworkId) public view artworkExists(_artworkId) returns (uint256, uint256) {
        return (artworks[_artworkId].salesCount, artworks[_artworkId].donationAmount);
    }


    // --- 4. Governance and Parameter Setting Functions ---

    function registerCurator(address _curator) public onlyOwner {
        curators[_curator] = true;
        emit CuratorRegistered(_curator);
    }

    function removeCurator(address _curator) public onlyOwner {
        curators[_curator] = false;
        emit CuratorRemoved(_curator);
    }

    function setGalleryFee(uint256 _newFeePercentage) public onlyOwner {
        require(_newFeePercentage <= 100, "Gallery fee percentage cannot exceed 100%");
        galleryFeePercentage = _newFeePercentage;
        emit GalleryFeeSet(_newFeePercentage);
    }

    function setProposalQuorum(uint256 _newQuorum) public onlyOwner {
        proposalQuorum = _newQuorum;
        emit ProposalQuorumSet(_newQuorum);
    }

    function withdrawGalleryFees() public onlyOwner {
        uint256 galleryBalance = address(this).balance;
        uint256 contractBalance = getGalleryBalance(); // Use function to exclude artist earnings
        uint256 withdrawableAmount = contractBalance.sub(artistEarningsTotal()); // Ensure we only withdraw gallery fees

        require(withdrawableAmount > 0, "No gallery fees to withdraw");
        require(address(galleryWallet) != address(0), "Gallery wallet address is not set");

        (bool success, ) = galleryWallet.call{value: withdrawableAmount}("");
        require(success, "Gallery fee withdrawal failed");
        emit GalleryFeesWithdrawn(galleryWallet, withdrawableAmount);
    }

    function getGalleryParameters() public view returns (uint256, uint256) {
        return (galleryFeePercentage, proposalQuorum);
    }

    // --- 5. Utility and Information Functions ---

    function getArtworkDetails(uint256 _artworkId) public view artworkExists(_artworkId) returns (Artwork memory) {
        return artworks[_artworkId];
    }

    function getGalleryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function isArtworkExhibited(uint256 _artworkId) public view artworkExists(_artworkId) returns (bool) {
        return artworks[_artworkId].isExhibited;
    }

    // --- Internal Helper Function ---
    function artistEarningsTotal() internal view returns (uint256) {
        uint256 totalEarnings = 0;
        for (uint256 i = 1; i <= _artworkIds.current(); i++) {
            if (artworks[i].artist != address(0)) { // Avoid summing earnings for deleted artworks (if not using delete, adjust logic)
                totalEarnings = totalEarnings.add(artistEarnings[artworks[i].artist]);
            }
        }
        return totalEarnings;
    }

    // --- Fallback function to receive ETH ---
    receive() external payable {}
}
```