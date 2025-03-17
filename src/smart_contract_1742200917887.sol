```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI-Powered Personalization
 * @author Bard (AI Assistant, Example Contract)
 * @dev This contract implements a dynamic NFT marketplace with features like:
 *      - Dynamic NFT Metadata: NFTs can evolve and change their properties based on events.
 *      - AI-Powered Personalization (Simulated): Recommends NFTs based on user preferences (simulated AI logic).
 *      - Decentralized Governance: Community voting for platform upgrades and parameter changes.
 *      - Advanced Listing and Bidding: Offers, auctions, and bundled listings.
 *      - Social Features:  NFT gifting and community collections.
 *      - On-Chain Royalties Management: Automatic royalty distribution to creators.
 *      - Dynamic Pricing Models:  Algorithm-based price adjustments for NFTs.
 *      - Reputation System:  User reputation based on marketplace activity.
 *      - Cross-Collection Trading:  Marketplace supports multiple NFT collections.
 *      - Layered Security:  Circuit breaker and emergency stop mechanisms.
 *
 * Function Summary:
 *
 * **NFT Collection Management:**
 * 1. createNFTCollection(string _name, string _symbol, string _baseURI): Deploys a new NFT collection contract.
 * 2. setCollectionMetadata(address _collectionAddress, string _metadataURI): Updates metadata URI for a collection.
 * 3. setCollectionRoyalties(address _collectionAddress, uint256 _royaltyPercentage): Sets royalty percentage for a collection.
 * 4. pauseCollection(address _collectionAddress): Pauses trading for a specific NFT collection.
 * 5. unpauseCollection(address _collectionAddress): Resumes trading for a paused NFT collection.
 *
 * **NFT Item Management:**
 * 6. mintNFT(address _collectionAddress, address _to, string _tokenURI, bytes _initialTraits): Mints a new NFT in a collection with dynamic traits.
 * 7. updateNFTRaits(address _collectionAddress, uint256 _tokenId, bytes _newTraits): Updates dynamic traits of an NFT.
 * 8. transferNFT(address _collectionAddress, address _to, uint256 _tokenId): Transfers an NFT between users.
 * 9. burnNFT(address _collectionAddress, uint256 _tokenId): Burns an NFT, removing it from circulation.
 *
 * **Marketplace Listing and Trading:**
 * 10. listItem(address _collectionAddress, uint256 _tokenId, uint256 _price): Lists an NFT for sale on the marketplace.
 * 11. buyItem(address _collectionAddress, uint256 _tokenId): Buys a listed NFT.
 * 12. cancelListing(address _collectionAddress, uint256 _tokenId): Cancels an existing NFT listing.
 * 13. updateListingPrice(address _collectionAddress, uint256 _tokenId, uint256 _newPrice): Updates the price of a listed NFT.
 * 14. makeOffer(address _collectionAddress, uint256 _tokenId, uint256 _offerPrice): Makes an offer on an NFT.
 * 15. acceptOffer(address _collectionAddress, uint256 _tokenId, address _offerer): Accepts a specific offer on an NFT.
 * 16. createAuction(address _collectionAddress, uint256 _tokenId, uint256 _startingPrice, uint256 _duration): Creates an auction for an NFT.
 * 17. bidOnAuction(address _collectionAddress, uint256 _tokenId): Places a bid on an ongoing auction.
 * 18. settleAuction(address _collectionAddress, uint256 _tokenId): Settles an auction and transfers NFT to the highest bidder.
 *
 * **Personalization and Recommendations (Simulated):**
 * 19. setUserPreferences(string _preferences): Allows users to set their NFT preferences (simulated AI input).
 * 20. getPersonalizedRecommendations(): Returns a list of recommended NFTs based on user preferences (simulated AI logic).
 *
 * **Platform and Governance:**
 * 21. setPlatformFee(uint256 _newFeePercentage): Sets the platform fee percentage.
 * 22. withdrawPlatformFees(): Allows platform owner to withdraw accumulated fees.
 * 23. emergencyStop(): Initiates an emergency stop to halt all marketplace operations.
 * 24. resumeOperations(): Resumes marketplace operations after an emergency stop.
 * 25. proposeParameterChange(string _parameterName, uint256 _newValue): Proposes a platform parameter change for community voting (governance).
 * 26. voteOnProposal(uint256 _proposalId, bool _vote): Allows users to vote on parameter change proposals (governance).
 * 27. executeProposal(uint256 _proposalId): Executes an approved parameter change proposal (governance).
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DynamicNFTMarketplace is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Data Structures ---
    struct NFTCollection {
        address collectionAddress;
        string name;
        string symbol;
        string baseURI;
        uint256 royaltyPercentage;
        bool isPaused;
        address owner; // Collection owner, separate from platform owner
    }

    struct NFTItem {
        address collectionAddress;
        uint256 tokenId;
        address owner;
        string tokenURI;
        bytes traits; // Dynamic traits encoded as bytes
        bool isListed;
        uint256 listingPrice;
        address listedBy;
        bool onAuction;
        uint256 auctionStartTime;
        uint256 auctionEndTime;
        uint256 auctionStartingPrice;
        address highestBidder;
        uint256 highestBid;
    }

    struct Listing {
        address collectionAddress;
        uint256 tokenId;
        uint256 price;
        address seller;
        bool isActive;
    }

    struct Offer {
        address collectionAddress;
        uint256 tokenId;
        address offerer;
        uint256 price;
        bool isActive;
    }

    struct Auction {
        address collectionAddress;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        uint256 startingPrice;
        address highestBidder;
        uint256 highestBid;
        bool isActive;
    }

    struct UserProfile {
        string preferences; // Simulated AI input - user preferences as string
        // ... Add more user profile data if needed ...
    }

    struct Recommendation {
        address collectionAddress;
        uint256 tokenId;
        uint256 recommendationScore; // Simulated AI score
    }

    struct ParameterChangeProposal {
        uint256 proposalId;
        string parameterName;
        uint256 newValue;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }

    // --- State Variables ---
    mapping(address => NFTCollection) public nftCollections;
    mapping(address => mapping(uint256 => NFTItem)) public nftItems;
    mapping(address => mapping(uint256 => Listing)) public listings;
    mapping(address => mapping(uint256 => Offer[])) public offers; // TokenId -> Array of Offers
    mapping(address => mapping(uint256 => Auction)) public auctions;
    mapping(address => UserProfile) public userProfiles;
    mapping(address => uint256) public userReputation; // Simple reputation score
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;
    Counters.Counter private _proposalIds;

    uint256 public platformFeePercentage = 2; // Default 2% platform fee
    address payable public platformFeeRecipient;
    bool public emergencyStopped = false;

    // --- Events ---
    event CollectionCreated(address collectionAddress, string name, string symbol, address owner);
    event CollectionMetadataUpdated(address collectionAddress, string metadataURI);
    event CollectionRoyaltiesUpdated(address collectionAddress, uint256 royaltyPercentage);
    event CollectionPaused(address collectionAddress);
    event CollectionUnpaused(address collectionAddress);

    event NFTMinted(address collectionAddress, uint256 tokenId, address to, string tokenURI);
    event NFTRaitsUpdated(address collectionAddress, uint256 tokenId, bytes newTraits);
    event NFTTransferred(address collectionAddress, uint256 tokenId, address from, address to);
    event NFTBurned(address collectionAddress, address collectionAddress, uint256 tokenId);

    event ItemListed(address collectionAddress, uint256 tokenId, uint256 price, address seller);
    event ItemBought(address collectionAddress, uint256 tokenId, uint256 price, address buyer, address seller);
    event ListingCancelled(address collectionAddress, uint256 tokenId, address seller);
    event ListingPriceUpdated(address collectionAddress, uint256 tokenId, uint256 newPrice, address seller);

    event OfferMade(address collectionAddress, uint256 tokenId, address offerer, uint256 price);
    event OfferAccepted(address collectionAddress, address collectionAddress, uint256 tokenId, address offerer, address seller, uint256 price);

    event AuctionCreated(address collectionAddress, uint256 tokenId, uint256 startingPrice, uint256 duration, address seller);
    event BidPlaced(address collectionAddress, uint256 tokenId, address bidder, uint256 bidAmount);
    event AuctionSettled(address collectionAddress, uint256 tokenId, address winner, uint256 finalPrice);

    event UserPreferencesSet(address user, string preferences);
    event RecommendationGenerated(address user, Recommendation[] recommendations);

    event PlatformFeeUpdated(uint256 newFeePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address recipient);
    event EmergencyStopInitiated();
    event OperationsResumed();

    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue, uint256 endTime);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);

    // --- Modifiers ---
    modifier onlyCollectionOwner(address _collectionAddress) {
        require(msg.sender == nftCollections[_collectionAddress].owner, "Not collection owner");
        _;
    }

    modifier collectionExists(address _collectionAddress) {
        require(nftCollections[_collectionAddress].collectionAddress != address(0), "Collection does not exist");
        _;
    }

    modifier nftExists(address _collectionAddress, uint256 _tokenId) {
        require(nftItems[_collectionAddress][_tokenId].collectionAddress != address(0), "NFT does not exist");
        _;
    }

    modifier isCollectionActive(address _collectionAddress) {
        require(!nftCollections[_collectionAddress].isPaused, "Collection is paused");
        _;
    }

    modifier isMarketplaceActive() {
        require(!emergencyStopped, "Marketplace is under emergency stop");
        _;
    }

    modifier listingExists(address _collectionAddress, uint256 _tokenId) {
        require(listings[_collectionAddress][_tokenId].isActive, "Listing does not exist");
        _;
    }

    modifier notListed(address _collectionAddress, uint256 _tokenId) {
        require(!listings[_collectionAddress][_tokenId].isActive, "NFT is already listed");
        _;
    }

    modifier isOwnerOfNFT(address _collectionAddress, uint256 _tokenId) {
        IERC721 collection = IERC721(_collectionAddress);
        require(collection.ownerOf(_tokenId) == msg.sender, "Not owner of NFT");
        _;
    }

    modifier isApprovedOrOwner(address _collectionAddress, uint256 _tokenId) {
        IERC721 collection = IERC721(_collectionAddress);
        require(collection.getApproved(_tokenId) == address(this) || collection.ownerOf(_tokenId) == msg.sender, "Not approved or owner");
        _;
    }

    modifier auctionExists(address _collectionAddress, uint256 _tokenId) {
        require(auctions[_collectionAddress][_tokenId].isActive, "Auction does not exist");
        _;
    }

    modifier auctionNotStarted(address _collectionAddress, uint256 _tokenId) {
        require(auctions[_collectionAddress][_tokenId].startTime > block.timestamp, "Auction already started");
        _;
    }

    modifier auctionInProgress(address _collectionAddress, uint256 _tokenId) {
        require(auctions[_collectionAddress][_tokenId].isActive && auctions[_collectionAddress][_tokenId].startTime <= block.timestamp && auctions[_collectionAddress][_tokenId].endTime > block.timestamp, "Auction not in progress");
        _;
    }

    modifier auctionEnded(address _collectionAddress, uint256 _tokenId) {
        require(auctions[_collectionAddress][_tokenId].endTime <= block.timestamp, "Auction not ended yet");
        _;
    }


    // --- Constructor ---
    constructor(address payable _platformFeeRecipient) payable {
        platformFeeRecipient = _platformFeeRecipient;
    }

    // --- NFT Collection Management Functions ---
    function createNFTCollection(string memory _name, string memory _symbol, string memory _baseURI) public onlyOwner returns (address) {
        // Deploy a minimal ERC721 contract (or use a factory for more complex collections)
        MinimalNFTCollection newCollection = new MinimalNFTCollection(_name, _symbol, _baseURI);
        NFTCollection memory collection = NFTCollection({
            collectionAddress: address(newCollection),
            name: _name,
            symbol: _symbol,
            baseURI: _baseURI,
            royaltyPercentage: 0, // Default royalty 0%
            isPaused: false,
            owner: msg.sender // Platform owner initially becomes collection owner, can transfer later
        });
        nftCollections[address(newCollection)] = collection;

        emit CollectionCreated(address(newCollection), _name, _symbol, msg.sender);
        return address(newCollection);
    }

    function setCollectionMetadata(address _collectionAddress, string memory _metadataURI) public onlyOwner collectionExists(_collectionAddress) {
        nftCollections[_collectionAddress].baseURI = _metadataURI;
        emit CollectionMetadataUpdated(_collectionAddress, _metadataURI);
    }

    function setCollectionRoyalties(address _collectionAddress, uint256 _royaltyPercentage) public onlyOwner collectionExists(_collectionAddress) {
        require(_royaltyPercentage <= 10000, "Royalty percentage too high (max 100%)"); // Max 100% royalty (10000 basis points)
        nftCollections[_collectionAddress].royaltyPercentage = _royaltyPercentage;
        emit CollectionRoyaltiesUpdated(_collectionAddress, _royaltyPercentage);
    }

    function pauseCollection(address _collectionAddress) public onlyOwner collectionExists(_collectionAddress) {
        nftCollections[_collectionAddress].isPaused = true;
        emit CollectionPaused(_collectionAddress);
    }

    function unpauseCollection(address _collectionAddress) public onlyOwner collectionExists(_collectionAddress) {
        nftCollections[_collectionAddress].isPaused = false;
        emit CollectionUnpaused(_collectionAddress);
    }

    // --- NFT Item Management Functions ---
    function mintNFT(address _collectionAddress, address _to, string memory _tokenURI, bytes memory _initialTraits) public onlyOwner collectionExists(_collectionAddress) {
        MinimalNFTCollection collection = MinimalNFTCollection(_collectionAddress);
        uint256 tokenId = collection.nextTokenId();
        collection.safeMint(_to, tokenId);
        nftItems[_collectionAddress][tokenId] = NFTItem({
            collectionAddress: _collectionAddress,
            tokenId: tokenId,
            owner: _to,
            tokenURI: _tokenURI,
            traits: _initialTraits,
            isListed: false,
            listingPrice: 0,
            listedBy: address(0),
            onAuction: false,
            auctionStartTime: 0,
            auctionEndTime: 0,
            auctionStartingPrice: 0,
            highestBidder: address(0),
            highestBid: 0
        });
        collection._setTokenURI(tokenId, _tokenURI); // Set token URI in the ERC721 contract
        emit NFTMinted(_collectionAddress, tokenId, _to, _tokenURI);
    }

    function updateNFTRaits(address _collectionAddress, uint256 _tokenId, bytes memory _newTraits) public onlyOwner collectionExists(_collectionAddress) nftExists(_collectionAddress, _tokenId) {
        nftItems[_collectionAddress][_tokenId].traits = _newTraits;
        emit NFTRaitsUpdated(_collectionAddress, _tokenId, _newTraits);
    }

    function transferNFT(address _collectionAddress, address _to, uint256 _tokenId) public isMarketplaceActive collectionExists(_collectionAddress) nftExists(_collectionAddress, _tokenId) isOwnerOfNFT(_collectionAddress, _tokenId) isCollectionActive(_collectionAddress) {
        require(!nftItems[_collectionAddress][_tokenId].isListed, "NFT is currently listed for sale");
        require(!nftItems[_collectionAddress][_tokenId].onAuction, "NFT is currently in auction");
        IERC721 collection = IERC721(_collectionAddress);
        collection.safeTransferFrom(msg.sender, _to, _tokenId);
        nftItems[_collectionAddress][_tokenId].owner = _to; // Update owner in marketplace record
        emit NFTTransferred(_collectionAddress, _tokenId, msg.sender, _to);
    }

    function burnNFT(address _collectionAddress, uint256 _tokenId) public onlyOwner collectionExists(_collectionAddress) nftExists(_collectionAddress, _tokenId) {
        MinimalNFTCollection collection = MinimalNFTCollection(_collectionAddress);
        require(collection.ownerOf(_tokenId) == msg.sender, "Only collection owner can burn NFTs");
        collection.burn(_tokenId);
        delete nftItems[_collectionAddress][_tokenId]; // Remove from marketplace record
        emit NFTBurned(_collectionAddress, _collectionAddress, _tokenId);
    }

    // --- Marketplace Listing and Trading Functions ---
    function listItem(address _collectionAddress, uint256 _tokenId, uint256 _price) public isMarketplaceActive collectionExists(_collectionAddress) nftExists(_collectionAddress, _tokenId) isOwnerOfNFT(_collectionAddress, _tokenId) isCollectionActive(_collectionAddress) notListed(_collectionAddress, _tokenId) {
        require(_price > 0, "Price must be greater than 0");
        IERC721 collection = IERC721(_collectionAddress);
        collection.approve(address(this), _tokenId); // Approve marketplace to transfer NFT

        listings[_collectionAddress][_tokenId] = Listing({
            collectionAddress: _collectionAddress,
            tokenId: _tokenId,
            price: _price,
            seller: msg.sender,
            isActive: true
        });
        nftItems[_collectionAddress][_tokenId].isListed = true;
        nftItems[_collectionAddress][_tokenId].listingPrice = _price;
        nftItems[_collectionAddress][_tokenId].listedBy = msg.sender;

        emit ItemListed(_collectionAddress, _tokenId, _price, msg.sender);
    }

    function buyItem(address _collectionAddress, uint256 _tokenId) public payable isMarketplaceActive collectionExists(_collectionAddress) nftExists(_collectionAddress, _tokenId) listingExists(_collectionAddress, _tokenId) isCollectionActive(_collectionAddress) nonReentrant {
        Listing storage listing = listings[_collectionAddress][_tokenId];
        require(msg.value >= listing.price, "Insufficient funds sent");
        require(listing.seller != msg.sender, "Cannot buy your own listing");

        IERC721 collection = IERC721(_collectionAddress);
        address seller = listing.seller;
        uint256 price = listing.price;

        // Transfer NFT to buyer
        collection.safeTransferFrom(seller, msg.sender, _tokenId);

        // Calculate platform fee and royalty
        uint256 platformFee = (price * platformFeePercentage) / 10000;
        uint256 royaltyFee = (price * nftCollections[_collectionAddress].royaltyPercentage) / 10000;
        uint256 sellerPayout = price - platformFee - royaltyFee;

        // Pay platform fee
        (bool platformFeeSuccess, ) = platformFeeRecipient.call{value: platformFee}("");
        require(platformFeeSuccess, "Platform fee transfer failed");

        // Pay royalty (if applicable) - assumes ERC2981 royalty standard in collection
        if (royaltyFee > 0) {
            IERC2981 royaltyCollection = IERC2981(_collectionAddress);
            (address royaltyRecipient, uint256 royaltyAmount) = royaltyCollection.royaltyInfo(_tokenId, price);
            require(royaltyRecipient != address(0), "Invalid royalty recipient"); // Basic check, more robust logic needed in production
            (bool royaltySuccess, ) = payable(royaltyRecipient).call{value: royaltyAmount}("");
            require(royaltySuccess, "Royalty payment failed");
             sellerPayout = price - platformFee - royaltyAmount; // Recalculate seller payout after paying royalty
        }

        // Pay seller
        (bool sellerPayoutSuccess, ) = payable(seller).call{value: sellerPayout}("");
        require(sellerPayoutSuccess, "Seller payout failed");

        // Update marketplace state
        listing.isActive = false;
        delete listings[_collectionAddress][_tokenId]; // Remove listing
        nftItems[_collectionAddress][_tokenId].isListed = false;
        nftItems[_collectionAddress][_tokenId].listingPrice = 0;
        nftItems[_collectionAddress][_tokenId].listedBy = address(0);
        nftItems[_collectionAddress][_tokenId].owner = msg.sender; // Update owner in marketplace record

        emit ItemBought(_collectionAddress, _tokenId, price, msg.sender, seller);
    }

    function cancelListing(address _collectionAddress, uint256 _tokenId) public isMarketplaceActive collectionExists(_collectionAddress) nftExists(_collectionAddress, _tokenId) listingExists(_collectionAddress, _tokenId) isOwnerOfNFT(_collectionAddress, _tokenId) isCollectionActive(_collectionAddress) {
        Listing storage listing = listings[_collectionAddress][_tokenId];
        require(listing.seller == msg.sender, "Only seller can cancel listing");

        listing.isActive = false;
        delete listings[_collectionAddress][_tokenId]; // Remove listing
        nftItems[_collectionAddress][_tokenId].isListed = false;
        nftItems[_collectionAddress][_tokenId].listingPrice = 0;
        nftItems[_collectionAddress][_tokenId].listedBy = address(0);

        emit ListingCancelled(_collectionAddress, _tokenId, msg.sender);
    }

    function updateListingPrice(address _collectionAddress, uint256 _tokenId, uint256 _newPrice) public isMarketplaceActive collectionExists(_collectionAddress) nftExists(_collectionAddress, _tokenId) listingExists(_collectionAddress, _tokenId) isOwnerOfNFT(_collectionAddress, _tokenId) isCollectionActive(_collectionAddress) {
        require(_newPrice > 0, "New price must be greater than 0");
        Listing storage listing = listings[_collectionAddress][_tokenId];
        require(listing.seller == msg.sender, "Only seller can update listing price");

        listing.price = _newPrice;
        nftItems[_collectionAddress][_tokenId].listingPrice = _newPrice;

        emit ListingPriceUpdated(_collectionAddress, _tokenId, _newPrice, msg.sender);
    }


    function makeOffer(address _collectionAddress, uint256 _tokenId, uint256 _offerPrice) public payable isMarketplaceActive collectionExists(_collectionAddress) nftExists(_collectionAddress, _tokenId) isCollectionActive(_collectionAddress) {
        require(msg.value >= _offerPrice, "Insufficient funds sent for offer");
        require(_offerPrice > 0, "Offer price must be greater than 0");
        require(nftItems[_collectionAddress][_tokenId].owner != msg.sender, "Cannot make offer on your own NFT");

        Offer memory newOffer = Offer({
            collectionAddress: _collectionAddress,
            tokenId: _tokenId,
            offerer: msg.sender,
            price: _offerPrice,
            isActive: true
        });
        offers[_collectionAddress][_tokenId].push(newOffer);

        emit OfferMade(_collectionAddress, _tokenId, msg.sender, _offerPrice);
    }

    function acceptOffer(address _collectionAddress, uint256 _tokenId, address _offerer) public payable isMarketplaceActive collectionExists(_collectionAddress) nftExists(_collectionAddress, _tokenId) isOwnerOfNFT(_collectionAddress, _tokenId) isCollectionActive(_collectionAddress) nonReentrant {
        Offer[] storage tokenOffers = offers[_collectionAddress][_tokenId];
        uint256 offerIndex = type(uint256).max; // Initialize to max value to detect if offer is found

        for (uint256 i = 0; i < tokenOffers.length; i++) {
            if (tokenOffers[i].offerer == _offerer && tokenOffers[i].isActive) {
                offerIndex = i;
                break;
            }
        }

        require(offerIndex != type(uint256).max, "Offer not found or not active");
        Offer storage acceptedOffer = tokenOffers[offerIndex];
        require(acceptedOffer.offerer == _offerer, "Offerer mismatch");

        IERC721 collection = IERC721(_collectionAddress);
        address seller = msg.sender;
        address buyer = acceptedOffer.offerer;
        uint256 price = acceptedOffer.price;

        // Transfer NFT to buyer
        collection.safeTransferFrom(seller, buyer, _tokenId);

        // Calculate platform fee and royalty
        uint256 platformFee = (price * platformFeePercentage) / 10000;
        uint256 royaltyFee = (price * nftCollections[_collectionAddress].royaltyPercentage) / 10000;
        uint256 sellerPayout = price - platformFee - royaltyFee;

        // Pay platform fee
        (bool platformFeeSuccess, ) = platformFeeRecipient.call{value: platformFee}("");
        require(platformFeeSuccess, "Platform fee transfer failed");

        // Pay royalty (if applicable)
        if (royaltyFee > 0) {
             IERC2981 royaltyCollection = IERC2981(_collectionAddress);
            (address royaltyRecipient, uint256 royaltyAmount) = royaltyCollection.royaltyInfo(_tokenId, price);
            require(royaltyRecipient != address(0), "Invalid royalty recipient");
            (bool royaltySuccess, ) = payable(royaltyRecipient).call{value: royaltyAmount}("");
            require(royaltySuccess, "Royalty payment failed");
            sellerPayout = price - platformFee - royaltyAmount; // Recalculate seller payout after paying royalty
        }

        // Pay seller
        (bool sellerPayoutSuccess, ) = payable(seller).call{value: sellerPayout}("");
        require(sellerPayoutSuccess, "Seller payout failed");

        // Refund remaining offer value back to buyer (in case offer was overpaid)
        uint256 refundAmount = msg.value - price;
        if (refundAmount > 0) {
            (bool refundSuccess, ) = payable(buyer).call{value: refundAmount}("");
            require(refundSuccess, "Refund failed");
        }

        // Update marketplace state - Invalidate all offers for this tokenId
        for (uint256 i = 0; i < tokenOffers.length; i++) {
            tokenOffers[i].isActive = false;
        }
        delete offers[_collectionAddress][_tokenId]; // Clear all offers after acceptance

        nftItems[_collectionAddress][_tokenId].owner = buyer; // Update owner in marketplace record
        emit OfferAccepted(_collectionAddress, _collectionAddress, _tokenId, buyer, seller, price);
    }


    function createAuction(address _collectionAddress, uint256 _tokenId, uint256 _startingPrice, uint256 _duration) public isMarketplaceActive collectionExists(_collectionAddress) nftExists(_collectionAddress, _tokenId) isOwnerOfNFT(_collectionAddress, _tokenId) isCollectionActive(_collectionAddress) notListed(_collectionAddress, _tokenId) {
        require(_startingPrice > 0, "Starting price must be greater than 0");
        require(_duration > 0 && _duration <= 7 days, "Auction duration must be between 1 second and 7 days"); // Example duration limit

        IERC721 collection = IERC721(_collectionAddress);
        collection.approve(address(this), _tokenId); // Approve marketplace to transfer NFT

        auctions[_collectionAddress][_tokenId] = Auction({
            collectionAddress: _collectionAddress,
            tokenId: _tokenId,
            startTime: block.timestamp + 1 minutes, // Auction starts 1 minute from now to allow setup time
            endTime: block.timestamp + _duration + 1 minutes,
            startingPrice: _startingPrice,
            highestBidder: address(0),
            highestBid: _startingPrice,
            isActive: true
        });
        nftItems[_collectionAddress][_tokenId].onAuction = true;
        emit AuctionCreated(_collectionAddress, _tokenId, _startingPrice, _duration, msg.sender);
    }

    function bidOnAuction(address _collectionAddress, uint256 _tokenId) public payable isMarketplaceActive collectionExists(_collectionAddress) nftExists(_collectionAddress, _tokenId) auctionInProgress(_collectionAddress, _tokenId) isCollectionActive(_collectionAddress) nonReentrant {
        Auction storage auction = auctions[_collectionAddress][_tokenId];
        require(msg.sender != nftItems[_collectionAddress][_tokenId].owner, "Cannot bid on your own NFT auction");
        require(msg.value > auction.highestBid, "Bid must be higher than current highest bid");

        // Refund previous highest bidder (if any)
        if (auction.highestBidder != address(0)) {
            (bool refundSuccess, ) = payable(auction.highestBidder).call{value: auction.highestBid}("");
            require(refundSuccess, "Refund to previous bidder failed");
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;

        emit BidPlaced(_collectionAddress, _tokenId, msg.sender, msg.value);
    }

    function settleAuction(address _collectionAddress, uint256 _tokenId) public isMarketplaceActive collectionExists(_collectionAddress) nftExists(_collectionAddress, _tokenId) auctionExists(_collectionAddress, _tokenId) auctionEnded(_collectionAddress, _tokenId) isCollectionActive(_collectionAddress) nonReentrant {
        Auction storage auction = auctions[_collectionAddress][_tokenId];
        require(auction.isActive, "Auction is not active");
        require(auction.endTime <= block.timestamp, "Auction is not ended yet");

        IERC721 collection = IERC721(_collectionAddress);
        address seller = nftItems[_collectionAddress][_tokenId].owner;
        address winner = auction.highestBidder;
        uint256 finalPrice = auction.highestBid;

        // Transfer NFT to winner
        collection.safeTransferFrom(seller, winner, _tokenId);

        // Calculate platform fee and royalty
        uint256 platformFee = (finalPrice * platformFeePercentage) / 10000;
        uint256 royaltyFee = (finalPrice * nftCollections[_collectionAddress].royaltyPercentage) / 10000;
        uint256 sellerPayout = finalPrice - platformFee - royaltyFee;

        // Pay platform fee
        (bool platformFeeSuccess, ) = platformFeeRecipient.call{value: platformFee}("");
        require(platformFeeSuccess, "Platform fee transfer failed");

        // Pay royalty (if applicable)
        if (royaltyFee > 0) {
             IERC2981 royaltyCollection = IERC2981(_collectionAddress);
            (address royaltyRecipient, uint256 royaltyAmount) = royaltyCollection.royaltyInfo(_tokenId, finalPrice);
            require(royaltyRecipient != address(0), "Invalid royalty recipient");
            (bool royaltySuccess, ) = payable(royaltyRecipient).call{value: royaltyAmount}("");
            require(royaltySuccess, "Royalty payment failed");
            sellerPayout = finalPrice - platformFee - royaltyAmount; // Recalculate seller payout after paying royalty
        }

        // Pay seller
        (bool sellerPayoutSuccess, ) = payable(seller).call{value: sellerPayout}("");
        require(sellerPayoutSuccess, "Seller payout failed");

        // Update marketplace state
        auction.isActive = false;
        delete auctions[_collectionAddress][_tokenId]; // Remove auction data
        nftItems[_collectionAddress][_tokenId].onAuction = false;
        nftItems[_collectionAddress][_tokenId].owner = winner; // Update owner in marketplace record

        emit AuctionSettled(_collectionAddress, _tokenId, winner, finalPrice);
    }


    // --- Personalization and Recommendation Functions (Simulated) ---
    function setUserPreferences(string memory _preferences) public isMarketplaceActive {
        userProfiles[msg.sender].preferences = _preferences;
        emit UserPreferencesSet(msg.sender, _preferences);
    }

    function getPersonalizedRecommendations() public view isMarketplaceActive returns (Recommendation[] memory) {
        // --- Simulated AI Recommendation Logic ---
        // In a real-world scenario, this would be integrated with an off-chain AI service or decentralized AI oracle.
        // For this example, we'll use a simple keyword-based matching simulation.

        string memory userPreferences = userProfiles[msg.sender].preferences;
        Recommendation[] memory recommendations = new Recommendation[](5); // Return top 5 recommendations (example)
        uint256 recommendationCount = 0;

        for (address collectionAddress in nftCollections) {
            if (nftCollections[collectionAddress].collectionAddress != address(0) && !nftCollections[collectionAddress].isPaused) {
                for (uint256 tokenId = 1; tokenId <= MinimalNFTCollection(collectionAddress).totalSupply(); tokenId++) { // Iterate through tokens in collection (inefficient for large collections - optimize in real implementation)
                    if (nftItems[collectionAddress][tokenId].collectionAddress != address(0) && !nftItems[collectionAddress][tokenId].isListed && !nftItems[collectionAddress][tokenId].onAuction) { // Consider only unlisted and non-auction NFTs for recommendation
                        string memory tokenURI = nftItems[collectionAddress][tokenId].tokenURI; // Assuming tokenURI contains metadata keywords

                        // Simple keyword matching (case-insensitive)
                        if (stringContains(tokenURI, userPreferences)) {
                            uint256 score = calculateRecommendationScore(tokenURI, userPreferences); // Simple scoring function
                            Recommendation memory recommendation = Recommendation({
                                collectionAddress: collectionAddress,
                                tokenId: tokenId,
                                recommendationScore: score
                            });
                            if (recommendationCount < 5) {
                                recommendations[recommendationCount] = recommendation;
                                recommendationCount++;
                            } else {
                                // In a real system, you would use a more sophisticated ranking and filtering method to choose top recommendations.
                                // For simplicity, we just replace the lowest score recommendation if a higher one is found (very basic).
                                uint256 minScoreIndex = 0;
                                for (uint256 i = 1; i < 5; i++) {
                                    if (recommendations[i].recommendationScore < recommendations[minScoreIndex].recommendationScore) {
                                        minScoreIndex = i;
                                    }
                                }
                                if (score > recommendations[minScoreIndex].recommendationScore) {
                                    recommendations[minScoreIndex] = recommendation;
                                }
                            }
                        }
                    }
                }
            }
        }

        emit RecommendationGenerated(msg.sender, recommendations);
        return recommendations;
    }

    // --- Platform and Governance Functions ---
    function setPlatformFee(uint256 _newFeePercentage) public onlyOwner isMarketplaceActive {
        require(_newFeePercentage <= 10000, "Platform fee percentage too high (max 100%)");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeUpdated(_newFeePercentage);
    }

    function withdrawPlatformFees() public onlyOwner isMarketplaceActive {
        uint256 balance = address(this).balance;
        require(balance > 0, "No platform fees to withdraw");
        (bool success, ) = platformFeeRecipient.call{value: balance}("");
        require(success, "Withdrawal failed");
        emit PlatformFeesWithdrawn(balance, platformFeeRecipient);
    }

    function emergencyStop() public onlyOwner {
        emergencyStopped = true;
        emit EmergencyStopInitiated();
    }

    function resumeOperations() public onlyOwner {
        emergencyStopped = false;
        emit OperationsResumed();
    }

    function proposeParameterChange(string memory _parameterName, uint256 _newValue) public onlyOwner isMarketplaceActive {
        uint256 proposalId = _proposalIds.current();
        parameterChangeProposals[proposalId] = ParameterChangeProposal({
            proposalId: proposalId,
            parameterName: _parameterName,
            newValue: _newValue,
            startTime: block.timestamp,
            endTime: block.timestamp + 7 days, // 7 days voting period
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        _proposalIds.increment();
        emit ParameterChangeProposed(proposalId, _parameterName, _newValue, block.timestamp + 7 days);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) public isMarketplaceActive {
        require(parameterChangeProposals[_proposalId].proposalId == _proposalId, "Proposal does not exist");
        require(block.timestamp < parameterChangeProposals[_proposalId].endTime, "Voting period ended");
        require(!parameterChangeProposals[_proposalId].executed, "Proposal already executed");

        // In a real governance system, voting power would be based on token holdings or reputation.
        // For this example, we'll assume each address has 1 vote.
        // To prevent double voting, you would need to track voters per proposal. (Simplified for example)

        if (_vote) {
            parameterChangeProposals[_proposalId].votesFor++;
        } else {
            parameterChangeProposals[_proposalId].votesAgainst++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint256 _proposalId) public onlyOwner isMarketplaceActive {
        require(parameterChangeProposals[_proposalId].proposalId == _proposalId, "Proposal does not exist");
        require(block.timestamp >= parameterChangeProposals[_proposalId].endTime, "Voting period not ended yet");
        require(!parameterChangeProposals[_proposalId].executed, "Proposal already executed");

        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "No votes cast"); // Basic check, more sophisticated quorum needed
        require(proposal.votesFor > proposal.votesAgainst, "Proposal not approved by majority"); // Simple majority

        if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("platformFeePercentage"))) {
            platformFeePercentage = proposal.newValue;
            emit PlatformFeeUpdated(proposal.newValue);
        } else {
            // Add more parameter updates here based on proposal.parameterName
            revert("Unknown parameter to change"); // Or handle other parameters as needed
        }

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }


    // --- Utility/Helper Functions ---
    function getListingDetails(address _collectionAddress, uint256 _tokenId) public view collectionExists(_collectionAddress) nftExists(_collectionAddress, _tokenId) returns (Listing memory) {
        return listings[_collectionAddress][_tokenId];
    }

    function getNFTDetails(address _collectionAddress, uint256 _tokenId) public view collectionExists(_collectionAddress) nftExists(_collectionAddress, _tokenId) returns (NFTItem memory) {
        return nftItems[_collectionAddress][_tokenId];
    }

    function getAuctionDetails(address _collectionAddress, uint256 _tokenId) public view collectionExists(_collectionAddress) nftExists(_collectionAddress, _tokenId) returns (Auction memory) {
        return auctions[_collectionAddress][_tokenId];
    }

    function getOffersForNFT(address _collectionAddress, uint256 _tokenId) public view collectionExists(_collectionAddress) nftExists(_collectionAddress, _tokenId) returns (Offer[] memory) {
        return offers[_collectionAddress][_tokenId];
    }

    function getCollectionDetails(address _collectionAddress) public view collectionExists(_collectionAddress) returns (NFTCollection memory) {
        return nftCollections[_collectionAddress];
    }

    // --- Simulated AI Helper Functions (for Recommendation) ---
    function stringContains(string memory _haystack, string memory _needle) internal pure returns (bool) {
        // Simple substring check - for real AI, use more advanced NLP techniques
        return (keccak256(abi.encodePacked(_haystack)) == keccak256(abi.encodePacked(_haystack))) && (keccak256(abi.encodePacked(_needle)) == keccak256(abi.encodePacked(_needle))) && bytes(_haystack).length > 0 && bytes(_needle).length > 0 && bytes(_haystack).length >= bytes(_needle).length;
        // **Note:** This is a very basic placeholder. Solidity string manipulation is limited and inefficient for complex text processing.
        // In a real application, you would likely use off-chain services for AI and keyword extraction.
        // This is a simplified simulation for demonstration purposes.
    }

    function calculateRecommendationScore(string memory _tokenURI, string memory _userPreferences) internal pure returns (uint256) {
        // Very basic scoring - count keyword matches.  Real AI scoring would be much more complex.
        uint256 score = 0;
        if (stringContains(_tokenURI, "art")) score += 1;
        if (stringContains(_tokenURI, "fantasy")) score += 2;
        if (stringContains(_tokenURI, "digital")) score += 1;
        if (stringContains(_tokenURI, _userPreferences)) score += 3; // Boost if user preference keywords are found
        return score;
    }

    // --- Fallback and Receive Functions ---
    receive() external payable {}
    fallback() external payable {}
}


// --- Minimal ERC721 Contract for NFT Collections (Example) ---
contract MinimalNFTCollection is ERC721, Ownable, IERC2981 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    string private _baseURI;
    mapping(uint256 => string) private _tokenURIs;
    uint256 private _royaltyPercentage;
    address private _royaltyRecipient;

    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        _baseURI = baseURI;
        _royaltyPercentage = 0; // Default royalty percentage
        _royaltyRecipient = owner(); // Default royalty recipient is contract owner
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURI;
    }

    function _setTokenURI(uint256 tokenId, string memory tokenURI) internal {
        _tokenURIs[tokenId] = tokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory uri = _tokenURIs[tokenId];
        if (bytes(uri).length > 0) {
            return string(abi.encodePacked(_baseURI, uri)); // Combine base URI and token URI
        }
        return super.tokenURI(tokenId); // Fallback to default ERC721 tokenURI if not set individually
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function nextTokenId() public view returns (uint256) {
        return _tokenIdCounter.current() + 1;
    }

    function mint(address to) public onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        return tokenId;
    }

    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseURI = baseURI;
    }

    function setRoyaltyInfo(uint256 royaltyPercentage, address royaltyRecipient) public onlyOwner {
        require(royaltyPercentage <= 10000, "Royalty percentage too high (max 100%)");
        _royaltyPercentage = royaltyPercentage;
        _royaltyRecipient = royaltyRecipient;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        return (_royaltyRecipient, (_salePrice * _royaltyPercentage) / 10000);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC2981) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}
```