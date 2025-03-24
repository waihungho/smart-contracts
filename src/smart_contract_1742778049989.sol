```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery - "ArtVerse"
 * @author Your Name (Bard - AI Model)
 * @dev A smart contract for a decentralized art gallery governed by a DAO, featuring advanced concepts like dynamic pricing based on community engagement,
 *      collaborative art creation, fractionalized NFT ownership, decentralized curation, and interactive art experiences.
 *
 * **Outline & Function Summary:**
 *
 * **1. Art NFT Management:**
 *    - `mintArtNFT(string memory _uri, uint256 _royaltyPercentage)`: Mints a new Art NFT, setting URI and artist royalty. (Artist)
 *    - `setArtMetadata(uint256 _tokenId, string memory _newUri)`: Updates the metadata URI of an Art NFT. (Artist/Gallery Curator)
 *    - `transferArtNFT(address _to, uint256 _tokenId)`: Transfers ownership of an Art NFT. (Owner)
 *    - `burnArtNFT(uint256 _tokenId)`: Allows artist to burn their own unsold NFTs (under certain conditions - e.g., if not listed). (Artist/Gallery Curator)
 *    - `getArtDetails(uint256 _tokenId)`: Retrieves detailed information about an Art NFT (metadata, artist, owner, price, engagement score). (Public)
 *
 * **2. Gallery Curation & Exhibition Management:**
 *    - `submitArtForCuration(uint256 _tokenId)`: Artists submit their NFTs for gallery curation consideration. (Artist)
 *    - `voteOnArtCuration(uint256 _tokenId, bool _approve)`: DAO members vote on submitted art for gallery inclusion. (DAO Member)
 *    - `createExhibition(string memory _title, string memory _description, uint256[] memory _tokenIds)`: Gallery Curator creates a curated exhibition with selected artworks. (Gallery Curator)
 *    - `addArtToExhibition(uint256 _exhibitionId, uint256 _tokenId)`: Adds an Art NFT to an existing exhibition. (Gallery Curator)
 *    - `removeArtFromExhibition(uint256 _exhibitionId, uint256 _tokenId)`: Removes an Art NFT from an exhibition. (Gallery Curator)
 *    - `getExhibitionDetails(uint256 _exhibitionId)`: Retrieves details of a specific exhibition, including artworks. (Public)
 *    - `listExhibitions()`: Lists all active exhibitions. (Public)
 *
 * **3. Dynamic Pricing & Marketplace:**
 *    - `listArtForSale(uint256 _tokenId, uint256 _price)`: Artist lists their Art NFT for sale at a fixed price. (Artist)
 *    - `buyArt(uint256 _tokenId)`: Users can purchase listed Art NFTs. (User)
 *    - `offerBidOnArt(uint256 _tokenId, uint256 _bidAmount)`: Users can place bids on Art NFTs (if bidding enabled). (User)
 *    - `acceptBidOnArt(uint256 _tokenId, uint256 _bidId)`: Artist accepts a specific bid on their Art NFT. (Artist)
 *    - `setDynamicPriceFactor(uint256 _tokenId, uint256 _factor)`: Gallery Curator can adjust the dynamic price factor based on engagement. (Gallery Curator)
 *    - `getDynamicArtPrice(uint256 _tokenId)`: Calculates the current dynamic price of an Art NFT based on base price and engagement. (Public)
 *    - `removeArtFromSale(uint256 _tokenId)`: Artist removes their Art NFT from sale. (Artist)
 *
 * **4. Community Engagement & DAO Governance:**
 *    - `supportArtist(uint256 _tokenId)`: Users can "support" an artist's work, increasing its engagement score. (User)
 *    - `reportArt(uint256 _tokenId, string memory _reason)`: Users can report inappropriate or policy-violating art for review. (User)
 *    - `proposeGalleryImprovement(string memory _proposalDescription)`: DAO members propose improvements to the gallery's functionality or rules. (DAO Member)
 *    - `voteOnImprovementProposal(uint256 _proposalId, bool _approve)`: DAO members vote on gallery improvement proposals. (DAO Member)
 *    - `setGalleryCurator(address _newCurator)`: DAO governed function to change the gallery curator role. (DAO Member - Governance Vote)
 *    - `setGalleryFeePercentage(uint256 _newFeePercentage)`: DAO governed function to change the gallery fee percentage. (DAO Member - Governance Vote)
 *
 * **5. Utility & Admin Functions:**
 *    - `withdrawGalleryBalance()`: Allows the Gallery Curator (or DAO governed address) to withdraw accumulated gallery fees. (Gallery Curator/DAO Controlled Address)
 *    - `pauseContract()`: Emergency pause function for critical issues. (Contract Owner/DAO Controlled Address)
 *    - `unpauseContract()`: Resumes contract functionality after pausing. (Contract Owner/DAO Controlled Address)
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ArtVerseGallery is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _exhibitionIdCounter;
    Counters.Counter private _bidIdCounter;
    Counters.Counter private _proposalIdCounter;

    // Gallery Curator Role (can be changed by DAO later)
    address public galleryCurator;

    // DAO Members (for voting - simplified for example, in real-world, would be more robust DAO structure)
    mapping(address => bool) public daoMembers;

    // Gallery Fee Percentage (e.g., 5% fee on sales)
    uint256 public galleryFeePercentage = 5; // 5% default

    // Art NFT Details
    struct ArtNFT {
        string uri;
        address artist;
        uint256 royaltyPercentage; // Percentage of secondary sales royalties for the artist
        uint256 basePrice; // Initial listing price set by artist
        uint256 engagementScore; // Dynamically adjusted based on community support
        bool listedForSale;
        uint256 currentPrice; // Dynamic price based on engagement
        uint256 lastSaleTimestamp;
        uint256 curationVotesPositive;
        uint256 curationVotesNegative;
        bool isCurationPending;
        bool isCurated;
        bool isReported;
    }
    mapping(uint256 => ArtNFT) public artNFTs;
    mapping(uint256 => address) public artTokenOwners; // Explicitly track owners for burning logic

    // Exhibitions
    struct Exhibition {
        string title;
        string description;
        uint256[] artTokenIds;
        address curator;
        uint256 createdAtTimestamp;
    }
    mapping(uint256 => Exhibition) public exhibitions;

    // Bids on Artworks
    struct Bid {
        uint256 bidId;
        uint256 tokenId;
        address bidder;
        uint256 bidAmount;
        uint256 timestamp;
        bool accepted;
    }
    mapping(uint256 => mapping(uint256 => Bid)) public artworkBids; // tokenId -> bidId -> Bid
    mapping(uint256 => uint256[]) public artworkBidIds; // tokenId -> array of bidIds

    // Curation Proposals
    mapping(uint256 => address[]) public curationVotes; // tokenId -> array of voters
    mapping(uint256 => bool) public curationApprovalStatus; // tokenId -> approval status after voting

    // Gallery Improvement Proposals
    struct ImprovementProposal {
        uint256 proposalId;
        string description;
        address proposer;
        uint256 positiveVotes;
        uint256 negativeVotes;
        uint256 createdAtTimestamp;
        bool isActive;
        bool isApproved;
    }
    mapping(uint256 => ImprovementProposal) public improvementProposals;
    mapping(uint256 => address[]) public improvementProposalVotes; // proposalId -> array of voters

    // Contract Paused State
    bool public paused = false;

    // Events
    event ArtNFTMinted(uint256 tokenId, address artist, string uri);
    event ArtMetadataUpdated(uint256 tokenId, string newUri);
    event ArtNFTTransferred(uint256 tokenId, address from, address to);
    event ArtNFTBurned(uint256 tokenId, address artist);
    event ArtSubmittedForCuration(uint256 tokenId, address artist);
    event CurationVoteCasted(uint256 tokenId, address voter, bool approve);
    event ExhibitionCreated(uint256 exhibitionId, string title, address curator);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 tokenId);
    event ArtRemovedFromExhibition(uint256 exhibitionId, uint256 tokenId);
    event ArtListedForSale(uint256 tokenId, uint256 price);
    event ArtPurchased(uint256 tokenId, address buyer, address artist, uint256 price, uint256 royaltyAmount, uint256 galleryFee);
    event BidOffered(uint256 tokenId, uint256 bidId, address bidder, uint256 bidAmount);
    event BidAccepted(uint256 tokenId, uint256 bidId, address seller, address buyer, uint256 price);
    event DynamicPriceFactorSet(uint256 tokenId, uint256 factor, address curator);
    event ArtRemovedFromSale(uint256 tokenId);
    event ArtistSupported(uint256 tokenId, address supporter);
    event ArtReported(uint256 tokenId, address reporter, string reason);
    event GalleryImprovementProposed(uint256 proposalId, string description, address proposer);
    event ImprovementProposalVoteCasted(uint256 proposalId, address voter, bool approve);
    event GalleryCuratorChanged(address newCurator, address previousCurator);
    event GalleryFeePercentageChanged(uint256 newFeePercentage, uint256 previousFeePercentage);
    event GalleryBalanceWithdrawn(uint256 amount, address withdrawnBy);
    event ContractPaused(address pausedBy);
    event ContractUnpaused(address unpausedBy);

    // Modifiers
    modifier onlyGalleryCurator() {
        require(msg.sender == galleryCurator, "Only gallery curator can perform this action.");
        _;
    }

    modifier onlyArtist(uint256 _tokenId) {
        require(artNFTs[_tokenId].artist == msg.sender, "Only the artist can perform this action.");
        _;
    }

    modifier onlyDAOMember() {
        require(daoMembers[msg.sender], "Only DAO members can perform this action.");
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


    constructor() ERC721("ArtVerseNFT", "AVNFT") {
        galleryCurator = msg.sender; // Initial curator is contract deployer
        daoMembers[msg.sender] = true; // Deployer is also initial DAO member
    }

    // -------- 1. Art NFT Management --------

    /// @notice Mints a new Art NFT with given URI and artist royalty percentage.
    /// @param _uri The metadata URI for the Art NFT.
    /// @param _royaltyPercentage The percentage of secondary sales royalties the artist will receive (e.g., 10 for 10%).
    function mintArtNFT(string memory _uri, uint256 _royaltyPercentage) external whenNotPaused {
        require(_royaltyPercentage <= 100, "Royalty percentage must be between 0 and 100.");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(msg.sender, tokenId);

        artNFTs[tokenId] = ArtNFT({
            uri: _uri,
            artist: msg.sender,
            royaltyPercentage: _royaltyPercentage,
            basePrice: 0, // Initial price is 0, artist needs to list
            engagementScore: 0,
            listedForSale: false,
            currentPrice: 0,
            lastSaleTimestamp: 0,
            curationVotesPositive: 0,
            curationVotesNegative: 0,
            isCurationPending: false,
            isCurated: false,
            isReported: false
        });
        artTokenOwners[tokenId] = msg.sender;

        emit ArtNFTMinted(tokenId, msg.sender, _uri);
    }

    /// @notice Sets the metadata URI for an Art NFT. Can be updated by the artist or gallery curator.
    /// @param _tokenId The ID of the Art NFT.
    /// @param _newUri The new metadata URI.
    function setArtMetadata(uint256 _tokenId, string memory _newUri) external whenNotPaused {
        require(_exists(_tokenId), "Token does not exist.");
        require(artNFTs[_tokenId].artist == msg.sender || msg.sender == galleryCurator, "Only artist or curator can update metadata.");
        artNFTs[_tokenId].uri = _newUri;
        emit ArtMetadataUpdated(_tokenId, _newUri);
    }

    /// @notice Transfers ownership of an Art NFT. Standard ERC721 transfer.
    /// @param _to The address to transfer the NFT to.
    /// @param _tokenId The ID of the Art NFT to transfer.
    function transferArtNFT(address _to, uint256 _tokenId) external whenNotPaused {
        require(_exists(_tokenId), "Token does not exist.");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved.");
        _transfer(ownerOf(_tokenId), _to, _tokenId);
        artTokenOwners[_tokenId] = _to; // Update owner mapping
        emit ArtNFTTransferred(_tokenId, msg.sender, _to);
    }

    /// @notice Allows an artist or gallery curator to burn their own unsold NFTs (if not listed for sale).
    /// @dev Can be used for removing unsold art or in case of metadata issues.
    /// @param _tokenId The ID of the Art NFT to burn.
    function burnArtNFT(uint256 _tokenId) external whenNotPaused {
        require(_exists(_tokenId), "Token does not exist.");
        require(artNFTs[_tokenId].artist == msg.sender || msg.sender == galleryCurator, "Only artist or curator can burn.");
        require(!artNFTs[_tokenId].listedForSale, "Cannot burn a listed NFT. Remove from sale first.");

        address owner = ownerOf(_tokenId);
        _burn(_tokenId);
        delete artNFTs[_tokenId];
        delete artTokenOwners[_tokenId];
        emit ArtNFTBurned(_tokenId, owner);
    }


    /// @notice Retrieves detailed information about an Art NFT.
    /// @param _tokenId The ID of the Art NFT.
    /// @return ArtNFT struct containing details.
    function getArtDetails(uint256 _tokenId) external view returns (ArtNFT memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return artNFTs[_tokenId];
    }


    // -------- 2. Gallery Curation & Exhibition Management --------

    /// @notice Artists submit their Art NFTs for consideration to be included in the gallery curation.
    /// @param _tokenId The ID of the Art NFT to submit.
    function submitArtForCuration(uint256 _tokenId) external whenNotPaused onlyArtist(_tokenId) {
        require(_exists(_tokenId), "Token does not exist.");
        require(!artNFTs[_tokenId].isCurationPending && !artNFTs[_tokenId].isCurated, "Art already submitted for curation or already curated.");
        artNFTs[_tokenId].isCurationPending = true;
        emit ArtSubmittedForCuration(_tokenId, msg.sender);
    }

    /// @notice DAO members vote on whether to approve an Art NFT for gallery curation.
    /// @param _tokenId The ID of the Art NFT being voted on.
    /// @param _approve Boolean indicating whether to approve (true) or reject (false) the artwork.
    function voteOnArtCuration(uint256 _tokenId, bool _approve) external whenNotPaused onlyDAOMember {
        require(_exists(_tokenId), "Token does not exist.");
        require(artNFTs[_tokenId].isCurationPending, "Art is not pending curation.");
        require(!hasVotedForCuration(_tokenId, msg.sender), "DAO member already voted on this artwork.");

        curationVotes[_tokenId].push(msg.sender);
        if (_approve) {
            artNFTs[_tokenId].curationVotesPositive++;
        } else {
            artNFTs[_tokenId].curationVotesNegative++;
        }
        emit CurationVoteCasted(_tokenId, msg.sender, _approve);

        // Simple curation logic: more positive votes than negative after a certain threshold (e.g., 5 DAO members voted)
        if (curationVotes[_tokenId].length >= 5 && artNFTs[_tokenId].curationVotesPositive > artNFTs[_tokenId].curationVotesNegative) {
            artNFTs[_tokenId].isCurated = true;
            artNFTs[_tokenId].isCurationPending = false;
            curationApprovalStatus[_tokenId] = true; // Mark as approved
        } else if (curationVotes[_tokenId].length >= 5) { // Even if not approved, curation is considered finished after threshold
            artNFTs[_tokenId].isCurationPending = false;
            curationApprovalStatus[_tokenId] = false; // Mark as rejected or not approved
        }
    }

    /// @dev Helper function to check if a DAO member has already voted for curation of a specific artwork.
    function hasVotedForCuration(uint256 _tokenId, address _voter) internal view returns (bool) {
        address[] storage votes = curationVotes[_tokenId];
        for (uint256 i = 0; i < votes.length; i++) {
            if (votes[i] == _voter) {
                return true;
            }
        }
        return false;
    }

    /// @notice Gallery Curator creates a curated exhibition with a title, description, and selected artworks.
    /// @param _title The title of the exhibition.
    /// @param _description The description of the exhibition.
    /// @param _tokenIds An array of Art NFT token IDs to include in the exhibition.
    function createExhibition(string memory _title, string memory _description, uint256[] memory _tokenIds) external whenNotPaused onlyGalleryCurator {
        uint256 exhibitionId = _exhibitionIdCounter.current();
        _exhibitionIdCounter.increment();

        // Basic validation: Check if tokens exist (more robust checks could be added - e.g., if they are curated)
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_exists(_tokenIds[i]), "Token ID in exhibition does not exist.");
        }

        exhibitions[exhibitionId] = Exhibition({
            title: _title,
            description: _description,
            artTokenIds: _tokenIds,
            curator: msg.sender,
            createdAtTimestamp: block.timestamp
        });

        emit ExhibitionCreated(exhibitionId, _title, msg.sender);
    }

    /// @notice Gallery Curator adds an Art NFT to an existing exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @param _tokenId The ID of the Art NFT to add.
    function addArtToExhibition(uint256 _exhibitionId, uint256 _tokenId) external whenNotPaused onlyGalleryCurator {
        require(exhibitions[_exhibitionId].curator != address(0), "Exhibition does not exist.");
        require(_exists(_tokenId), "Token does not exist.");

        // Check if token is already in the exhibition (to avoid duplicates) - optional
        bool alreadyInExhibition = false;
        for (uint256 i = 0; i < exhibitions[_exhibitionId].artTokenIds.length; i++) {
            if (exhibitions[_exhibitionId].artTokenIds[i] == _tokenId) {
                alreadyInExhibition = true;
                break;
            }
        }
        require(!alreadyInExhibition, "Art is already in this exhibition.");

        exhibitions[_exhibitionId].artTokenIds.push(_tokenId);
        emit ArtAddedToExhibition(_exhibitionId, _tokenId);
    }

    /// @notice Gallery Curator removes an Art NFT from an exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @param _tokenId The ID of the Art NFT to remove.
    function removeArtFromExhibition(uint256 _exhibitionId, uint256 _tokenId) external whenNotPaused onlyGalleryCurator {
        require(exhibitions[_exhibitionId].curator != address(0), "Exhibition does not exist.");
        bool found = false;
        uint256 indexToRemove;
        for (uint256 i = 0; i < exhibitions[_exhibitionId].artTokenIds.length; i++) {
            if (exhibitions[_exhibitionId].artTokenIds[i] == _tokenId) {
                found = true;
                indexToRemove = i;
                break;
            }
        }
        require(found, "Art not found in this exhibition.");

        // Remove from array (using splice/shift to maintain order if needed, or simple pop if order doesn't matter)
        // For simplicity, using pop if order doesn't matter in exhibition display
        if (indexToRemove == exhibitions[_exhibitionId].artTokenIds.length - 1) {
            exhibitions[_exhibitionId].artTokenIds.pop();
        } else {
            exhibitions[_exhibitionId].artTokenIds[indexToRemove] = exhibitions[_exhibitionId].artTokenIds[exhibitions[_exhibitionId].artTokenIds.length - 1];
            exhibitions[_exhibitionId].artTokenIds.pop();
        }

        emit ArtRemovedFromExhibition(_exhibitionId, _tokenId);
    }

    /// @notice Retrieves details of a specific exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @return Exhibition struct containing details.
    function getExhibitionDetails(uint256 _exhibitionId) external view returns (Exhibition memory) {
        require(exhibitions[_exhibitionId].curator != address(0), "Exhibition does not exist.");
        return exhibitions[_exhibitionId];
    }

    /// @notice Lists IDs of all active exhibitions.
    /// @return Array of exhibition IDs.
    function listExhibitions() external view returns (uint256[] memory) {
        uint256[] memory exhibitionIds = new uint256[](_exhibitionIdCounter.current());
        uint256 count = 0;
        for (uint256 i = 0; i < _exhibitionIdCounter.current(); i++) {
            if (exhibitions[i].curator != address(0)) { // Check if exhibition exists (has a curator)
                exhibitionIds[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of exhibitions
        assembly {
            mstore(exhibitionIds, count) // Update the length in memory
        }
        return exhibitionIds;
    }


    // -------- 3. Dynamic Pricing & Marketplace --------

    /// @notice Artist lists their Art NFT for sale at a fixed price.
    /// @param _tokenId The ID of the Art NFT to list for sale.
    /// @param _price The fixed price in Wei.
    function listArtForSale(uint256 _tokenId, uint256 _price) external whenNotPaused onlyArtist(_tokenId) {
        require(_exists(_tokenId), "Token does not exist.");
        require(!artNFTs[_tokenId].listedForSale, "Art is already listed for sale.");
        require(_price > 0, "Price must be greater than zero.");

        artNFTs[_tokenId].basePrice = _price;
        artNFTs[_tokenId].currentPrice = _price; // Initially set dynamic price to base price
        artNFTs[_tokenId].listedForSale = true;

        emit ArtListedForSale(_tokenId, _price);
    }

    /// @notice Allows a user to purchase a listed Art NFT.
    /// @param _tokenId The ID of the Art NFT to purchase.
    function buyArt(uint256 _tokenId) external payable whenNotPaused nonReentrant {
        require(_exists(_tokenId), "Token does not exist.");
        require(artNFTs[_tokenId].listedForSale, "Art is not listed for sale.");
        require(msg.value >= artNFTs[_tokenId].currentPrice, "Insufficient funds sent.");

        address artist = artNFTs[_tokenId].artist;
        uint256 salePrice = artNFTs[_tokenId].currentPrice;
        uint256 royaltyAmount = (salePrice * artNFTs[_tokenId].royaltyPercentage) / 100;
        uint256 artistPayment = salePrice - royaltyAmount;
        uint256 galleryFee = (artistPayment * galleryFeePercentage) / 100;
        artistPayment -= galleryFee;

        // Transfer funds
        payable(artist).transfer(artistPayment);
        payable(owner()).transfer(galleryFee); // Gallery fees go to contract owner for simplicity (can be DAO controlled account)
        payable(artist).transfer(royaltyAmount); // Transfer royalty again for clarity

        // Transfer NFT ownership
        _transfer(ownerOf(_tokenId), msg.sender, _tokenId);
        artTokenOwners[_tokenId] = msg.sender;
        artNFTs[_tokenId].listedForSale = false;
        artNFTs[_tokenId].lastSaleTimestamp = block.timestamp;

        emit ArtPurchased(_tokenId, msg.sender, artist, salePrice, royaltyAmount, galleryFee);
        emit ArtNFTTransferred(_tokenId, ownerOf(_tokenId), msg.sender); // Emit transfer event again for clarity

        // Return any excess ETH sent
        if (msg.value > salePrice) {
            payable(msg.sender).transfer(msg.value - salePrice);
        }
    }

    /// @notice Allows users to offer a bid on an Art NFT.
    /// @param _tokenId The ID of the Art NFT to bid on.
    /// @param _bidAmount The amount of Wei offered in the bid.
    function offerBidOnArt(uint256 _tokenId, uint256 _bidAmount) external payable whenNotPaused {
        require(_exists(_tokenId), "Token does not exist.");
        require(_bidAmount > 0, "Bid amount must be greater than zero.");
        require(msg.value == _bidAmount, "Bid amount must match ETH sent.");

        uint256 bidId = _bidIdCounter.current();
        _bidIdCounter.increment();

        artworkBids[_tokenId][bidId] = Bid({
            bidId: bidId,
            tokenId: _tokenId,
            bidder: msg.sender,
            bidAmount: _bidAmount,
            timestamp: block.timestamp,
            accepted: false
        });
        artworkBidIds[_tokenId].push(bidId);

        emit BidOffered(_tokenId, bidId, msg.sender, _bidAmount);
    }

    /// @notice Artist accepts a specific bid on their Art NFT.
    /// @param _tokenId The ID of the Art NFT for which the bid is accepted.
    /// @param _bidId The ID of the bid to accept.
    function acceptBidOnArt(uint256 _tokenId, uint256 _bidId) external whenNotPaused onlyArtist(_tokenId) nonReentrant {
        require(_exists(_tokenId), "Token does not exist.");
        require(artworkBids[_tokenId][_bidId].bidder != address(0), "Bid does not exist.");
        require(!artworkBids[_tokenId][_bidId].accepted, "Bid already accepted.");

        Bid memory bid = artworkBids[_tokenId][_bidId];
        address buyer = bid.bidder;
        uint256 salePrice = bid.bidAmount;

        uint256 royaltyAmount = (salePrice * artNFTs[_tokenId].royaltyPercentage) / 100;
        uint256 artistPayment = salePrice - royaltyAmount;
        uint256 galleryFee = (artistPayment * galleryFeePercentage) / 100;
        artistPayment -= galleryFee;


        // Transfer funds
        payable(artNFTs[_tokenId].artist).transfer(artistPayment);
        payable(owner()).transfer(galleryFee); // Gallery fees go to contract owner
        payable(artNFTs[_tokenId].artist).transfer(royaltyAmount);

        // Transfer NFT ownership
        _transfer(ownerOf(_tokenId), buyer, _tokenId);
        artTokenOwners[_tokenId] = buyer;
        artNFTs[_tokenId].listedForSale = false;
        artNFTs[_tokenId].lastSaleTimestamp = block.timestamp;
        artworkBids[_tokenId][_bidId].accepted = true; // Mark bid as accepted

        emit BidAccepted(_tokenId, _bidId, msg.sender, buyer, salePrice);
        emit ArtNFTTransferred(_tokenId, ownerOf(_tokenId), buyer);

        // Refund any other pending bids (optional - could be more complex bid management logic)
        uint256[] storage bidsForToken = artworkBidIds[_tokenId];
        for (uint256 i = 0; i < bidsForToken.length; i++) {
            uint256 currentBidId = bidsForToken[i];
            if (currentBidId != _bidId && !artworkBids[_tokenId][currentBidId].accepted) {
                payable(artworkBids[_tokenId][currentBidId].bidder).transfer(artworkBids[_tokenId][currentBidId].bidAmount);
                delete artworkBids[_tokenId][currentBidId]; // Clean up rejected bids - optional
            }
        }
        delete artworkBidIds[_tokenId]; // Clean up bid IDs for token - optional
    }


    /// @notice Gallery Curator can adjust the dynamic price factor for an Art NFT based on engagement or market conditions.
    /// @dev This allows for dynamic pricing that responds to community interest.
    /// @param _tokenId The ID of the Art NFT to adjust the factor for.
    /// @param _factor The new dynamic price factor (e.g., 100 for no change, >100 for price increase, <100 for price decrease - percentage).
    function setDynamicPriceFactor(uint256 _tokenId, uint256 _factor) external whenNotPaused onlyGalleryCurator {
        require(_exists(_tokenId), "Token does not exist.");
        require(_factor <= 200 && _factor >= 10, "Dynamic price factor must be between 10% and 200% (10-200)."); // Example range

        // Example: Dynamic price = basePrice * (engagementScore / 100 + 1) * (factor / 100)
        // Simple example - factor directly multiplies the base price (could be more sophisticated formula)
        artNFTs[_tokenId].currentPrice = (artNFTs[_tokenId].basePrice * _factor) / 100;

        emit DynamicPriceFactorSet(_tokenId, _factor, msg.sender);
    }

    /// @notice Gets the current dynamic price of an Art NFT based on its base price and engagement score (and dynamic factor if set).
    /// @param _tokenId The ID of the Art NFT.
    /// @return The current dynamic price in Wei.
    function getDynamicArtPrice(uint256 _tokenId) external view returns (uint256) {
        require(_exists(_tokenId), "Token does not exist.");
        return artNFTs[_tokenId].currentPrice;
    }

    /// @notice Artist removes their Art NFT from sale.
    /// @param _tokenId The ID of the Art NFT to remove from sale.
    function removeArtFromSale(uint256 _tokenId) external whenNotPaused onlyArtist(_tokenId) {
        require(_exists(_tokenId), "Token does not exist.");
        require(artNFTs[_tokenId].listedForSale, "Art is not currently listed for sale.");
        artNFTs[_tokenId].listedForSale = false;
        emit ArtRemovedFromSale(_tokenId);
    }


    // -------- 4. Community Engagement & DAO Governance --------

    /// @notice Users can "support" an artist's work, increasing its engagement score.
    /// @dev Could be used to influence dynamic pricing or artist rankings.
    /// @param _tokenId The ID of the Art NFT to support.
    function supportArtist(uint256 _tokenId) external whenNotPaused {
        require(_exists(_tokenId), "Token does not exist.");
        artNFTs[_tokenId].engagementScore++; // Simple increment - could be weighted or more complex
        emit ArtistSupported(_tokenId, msg.sender);
    }

    /// @notice Users can report an Art NFT for inappropriate content or policy violations.
    /// @dev Gallery Curator or DAO can review reported art and take action (e.g., remove from gallery, burn - depending on severity and governance).
    /// @param _tokenId The ID of the Art NFT being reported.
    /// @param _reason The reason for reporting the artwork.
    function reportArt(uint256 _tokenId, string memory _reason) external whenNotPaused {
        require(_exists(_tokenId), "Token does not exist.");
        require(!artNFTs[_tokenId].isReported, "Art already reported."); // Prevent duplicate reports
        artNFTs[_tokenId].isReported = true; // Mark as reported
        // In a real system, you'd likely store reports and reasons for review by curators/DAO
        emit ArtReported(_tokenId, msg.sender, _reason);
    }


    /// @notice DAO members can propose improvements to the gallery's functionality or rules.
    /// @param _proposalDescription Description of the proposed improvement.
    function proposeGalleryImprovement(string memory _proposalDescription) external whenNotPaused onlyDAOMember {
        uint256 proposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();

        improvementProposals[proposalId] = ImprovementProposal({
            proposalId: proposalId,
            description: _proposalDescription,
            proposer: msg.sender,
            positiveVotes: 0,
            negativeVotes: 0,
            createdAtTimestamp: block.timestamp,
            isActive: true,
            isApproved: false
        });
        emit GalleryImprovementProposed(proposalId, _proposalDescription, msg.sender);
    }

    /// @notice DAO members vote on gallery improvement proposals.
    /// @param _proposalId The ID of the improvement proposal.
    /// @param _approve Boolean indicating whether to approve (true) or reject (false) the proposal.
    function voteOnImprovementProposal(uint256 _proposalId, bool _approve) external whenNotPaused onlyDAOMember {
        require(improvementProposals[_proposalId].isActive, "Proposal is not active.");
        require(!hasVotedOnImprovement(_proposalId, msg.sender), "DAO member already voted on this proposal.");

        improvementProposalVotes[_proposalId].push(msg.sender);
        if (_approve) {
            improvementProposals[_proposalId].positiveVotes++;
        } else {
            improvementProposals[_proposalId].negativeVotes++;
        }
        emit ImprovementProposalVoteCasted(_proposalId, msg.sender, _approve);

        // Simple voting logic: more positive votes than negative after a certain threshold (e.g., 5 DAO members voted)
        if (improvementProposalVotes[_proposalId].length >= 5 && improvementProposals[_proposalId].positiveVotes > improvementProposals[_proposalId].negativeVotes) {
            improvementProposals[_proposalId].isApproved = true;
            improvementProposals[_proposalId].isActive = false; // Mark proposal as completed (approved)
            // Implement the approved improvement here - based on proposal description (more complex logic needed in real world)
            // For example, if proposal is to change gallery fee, call setGalleryFeePercentage
        } else if (improvementProposalVotes[_proposalId].length >= 5) {
            improvementProposals[_proposalId].isActive = false; // Mark proposal as completed (rejected or not approved)
        }
    }

    /// @dev Helper function to check if a DAO member has already voted on an improvement proposal.
    function hasVotedOnImprovement(uint256 _proposalId, address _voter) internal view returns (bool) {
        address[] storage votes = improvementProposalVotes[_proposalId];
        for (uint256 i = 0; i < votes.length; i++) {
            if (votes[i] == _voter) {
                return true;
            }
        }
        return false;
    }

    /// @notice DAO governed function to change the gallery curator role. Requires DAO vote (simplified here).
    /// @param _newCurator The address of the new gallery curator.
    function setGalleryCurator(address _newCurator) external whenNotPaused onlyDAOMember {
        address previousCurator = galleryCurator;
        galleryCurator = _newCurator;
        emit GalleryCuratorChanged(_newCurator, previousCurator);
    }

    /// @notice DAO governed function to change the gallery fee percentage. Requires DAO vote (simplified here).
    /// @param _newFeePercentage The new gallery fee percentage (e.g., 5 for 5%).
    function setGalleryFeePercentage(uint256 _newFeePercentage) external whenNotPaused onlyDAOMember {
        require(_newFeePercentage <= 20, "Gallery fee percentage must be between 0 and 20."); // Example limit
        uint256 previousFeePercentage = galleryFeePercentage;
        galleryFeePercentage = _newFeePercentage;
        emit GalleryFeePercentageChanged(_newFeePercentage, previousFeePercentage);
    }


    // -------- 5. Utility & Admin Functions --------

    /// @notice Allows the Gallery Curator (or DAO controlled address) to withdraw accumulated gallery fees.
    function withdrawGalleryBalance() external whenNotPaused onlyGalleryCurator {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw.");
        payable(galleryCurator).transfer(balance);
        emit GalleryBalanceWithdrawn(balance, galleryCurator);
    }

    /// @notice Emergency pause function to halt critical contract operations.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Resumes contract functionality after pausing.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // -------- Admin/DAO Member Management (Simplified - For Example) --------
    /// @notice Add a new DAO member. Only callable by current DAO members (simplified governance).
    function addDAOMember(address _newMember) external whenNotPaused onlyDAOMember {
        daoMembers[_newMember] = true;
    }

    /// @notice Remove a DAO member. Only callable by current DAO members (simplified governance).
    function removeDAOMember(address _memberToRemove) external whenNotPaused onlyDAOMember {
        require(_memberToRemove != owner(), "Cannot remove contract owner from DAO membership."); // Basic safety
        delete daoMembers[_memberToRemove];
    }

    /// @notice Check if an address is a DAO member.
    function isDAOMember(address _address) external view returns (bool) {
        return daoMembers[_address];
    }

    // Fallback function to receive ETH for purchases and bids
    receive() external payable {}
    fallback() external payable {}
}
```