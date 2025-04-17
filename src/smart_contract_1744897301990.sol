```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAAG) Smart Contract
 * @author Bard (AI Assistant)

 * @dev This smart contract implements a Decentralized Autonomous Art Gallery (DAAG)
 * with advanced features for artists, collectors, curators, and community engagement.
 * It incorporates concepts like NFTs, curated collections, dynamic pricing, decentralized governance,
 * and community-driven features to create a novel art ecosystem on the blockchain.

 * **Contract Outline:**

 * **1. Core NFT Functionality:**
 *    - mintArtNFT: Allows artists to mint unique Art NFTs.
 *    - transferArtNFT: Standard NFT transfer function.
 *    - getArtNFTOwner: Retrieve the owner of an Art NFT.
 *    - getArtNFTMetadataURI: Get the metadata URI for an Art NFT.

 * **2. Artist Management:**
 *    - registerArtist: Allows artists to register with the gallery.
 *    - setArtistProfile: Artists can set their profile information (e.g., bio, website).
 *    - getArtistProfile: Retrieve an artist's profile.
 *    - setRoyaltyPercentage: Artists can set their royalty percentage on secondary sales.

 * **3. Gallery Curation & Collections:**
 *    - applyToBeCurator: Users can apply to become a curator.
 *    - approveCurator: Admin function to approve curator applications.
 *    - rejectCurator: Admin function to reject curator applications.
 *    - createCuratedCollection: Curators can create curated art collections.
 *    - addToCuratedCollection: Curators can add Art NFTs to curated collections.
 *    - removeFromCuratedCollection: Curators can remove Art NFTs from collections.
 *    - getCuratedCollectionDetails: Retrieve details of a curated collection.
 *    - isNFTInCollection: Check if an NFT belongs to a specific collection.

 * **4. Dynamic Pricing & Auctions:**
 *    - listArtNFTForSale: Artists can list their NFTs for sale at a fixed price.
 *    - buyArtNFT: Collectors can buy NFTs listed for sale.
 *    - createDutchAuction: Artists can create a Dutch auction for their NFTs.
 *    - bidOnDutchAuction: Collectors can bid on Dutch auctions.
 *    - endDutchAuction: Function to end a Dutch auction (can be called by anyone after time limit).

 * **5. Community & Engagement Features:**
 *    - likeArtNFT: Registered users can 'like' Art NFTs.
 *    - getArtNFTLikes: Get the number of likes for an Art NFT.
 *    - setPlatformFee: Admin function to set the platform fee percentage.
 *    - withdrawPlatformFees: Admin function to withdraw accumulated platform fees.
 *    - pauseContract: Admin function to pause contract functionalities in emergencies.
 *    - unpauseContract: Admin function to unpause contract functionalities.

 * **Function Summary:**

 * - `mintArtNFT`: Allows registered artists to mint unique NFTs representing their artwork.
 * - `transferArtNFT`: Enables standard NFT transfers between owners.
 * - `getArtNFTOwner`: Returns the current owner of a given Art NFT.
 * - `getArtNFTMetadataURI`: Retrieves the URI pointing to the metadata of an Art NFT.
 * - `registerArtist`: Allows users to register as artists on the platform.
 * - `setArtistProfile`: Artists can update their profile information (bio, website, etc.).
 * - `getArtistProfile`: Fetches an artist's profile details.
 * - `setRoyaltyPercentage`: Artists can define the royalty percentage they receive on secondary sales.
 * - `applyToBeCurator`: Users can submit applications to become curators.
 * - `approveCurator`: Admin function to approve curator applications.
 * - `rejectCurator`: Admin function to reject curator applications.
 * - `createCuratedCollection`: Curators can create thematic collections of Art NFTs.
 * - `addToCuratedCollection`: Curators can add NFTs to their curated collections.
 * - `removeFromCuratedCollection`: Curators can remove NFTs from collections.
 * - `getCuratedCollectionDetails`: Retrieves information about a specific curated collection.
 * - `isNFTInCollection`: Checks if a given NFT is part of a specific curated collection.
 * - `listArtNFTForSale`: Artists can list their NFTs for sale at a fixed price.
 * - `buyArtNFT`: Collectors can purchase NFTs listed for sale.
 * - `createDutchAuction`: Artists can initiate a Dutch auction for their NFTs with a starting price and decrement rate.
 * - `bidOnDutchAuction`: Collectors can place bids on Dutch auction NFTs.
 * - `endDutchAuction`: Ends a Dutch auction, allowing the highest bidder to claim the NFT (or reverts if no bids).
 * - `likeArtNFT`: Registered users can express appreciation for Art NFTs by 'liking' them.
 * - `getArtNFTLikes`: Returns the number of likes an Art NFT has received.
 * - `setPlatformFee`: Admin function to set the platform's fee percentage on sales.
 * - `withdrawPlatformFees`: Admin function to withdraw accumulated platform fees.
 * - `pauseContract`: Admin function to temporarily halt most contract functionalities.
 * - `unpauseContract`: Admin function to resume normal contract functionalities.

 */
contract DecentralizedAutonomousArtGallery {
    // ** State Variables **

    // NFT Details
    string public name = "Decentralized Autonomous Art Gallery NFT";
    string public symbol = "DAAGNFT";
    uint256 public nextNFTId = 1;
    mapping(uint256 => address) public nftOwner;
    mapping(uint256 => string) public nftMetadataURI;
    mapping(uint256 => bool) public existsNFT;

    // Artist Management
    mapping(address => bool) public isRegisteredArtist;
    mapping(address => ArtistProfile) public artistProfiles;
    mapping(uint256 => uint256) public royaltyPercentage; // NFT ID => Royalty Percentage

    struct ArtistProfile {
        string bio;
        string website;
    }

    // Curator Management
    mapping(address => bool) public isCurator;
    mapping(address => bool) public pendingCuratorApplication;
    address[] public pendingCuratorApplicants;

    // Curated Collections
    uint256 public nextCollectionId = 1;
    mapping(uint256 => Collection) public collections;
    mapping(uint256 => mapping(uint256 => bool)) public collectionNFTs; // Collection ID => NFT ID => Exists

    struct Collection {
        string name;
        string description;
        address curator;
        uint256 creationTimestamp;
    }

    // Marketplace & Pricing
    mapping(uint256 => Listing) public nftListings; // NFT ID => Listing Details
    struct Listing {
        bool isListed;
        uint256 price;
        address seller;
    }

    mapping(uint256 => DutchAuction) public dutchAuctions; // NFT ID => Auction Details
    struct DutchAuction {
        bool isActive;
        uint256 startTime;
        uint256 endTime;
        uint256 startPrice;
        uint256 decrementPerBlock;
        address seller;
        address highestBidder;
        uint256 highestBid;
    }

    // Community Features
    mapping(uint256 => uint256) public nftLikes; // NFT ID => Like Count
    mapping(uint256 => mapping(address => bool)) public userLikedNFT; // NFT ID => User Address => Liked?

    // Platform Fees
    uint256 public platformFeePercentage = 2; // Default 2% platform fee
    uint256 public accumulatedPlatformFees;
    address public owner;
    bool public paused = false;

    // ** Events **
    event ArtNFTMinted(uint256 nftId, address artist, string metadataURI);
    event ArtistRegistered(address artistAddress, string artistName);
    event ArtistProfileUpdated(address artistAddress);
    event RoyaltyPercentageSet(uint256 nftId, uint256 percentage);
    event CuratorApplicationSubmitted(address applicant);
    event CuratorApproved(address curatorAddress);
    event CuratorRejected(address curatorAddress);
    event CuratedCollectionCreated(uint256 collectionId, string collectionName, address curator);
    event NFTAddedToCollection(uint256 collectionId, uint256 nftId);
    event NFTRemovedFromCollection(uint256 collectionId, uint256 nftId);
    event ArtNFTListedForSale(uint256 nftId, uint256 price, address seller);
    event ArtNFTBought(uint256 nftId, address buyer, uint256 price);
    event DutchAuctionCreated(uint256 nftId, uint256 startTime, uint256 endTime, uint256 startPrice, uint256 decrementPerBlock, address seller);
    event DutchAuctionBidPlaced(uint256 nftId, address bidder, uint256 bidAmount);
    event DutchAuctionEnded(uint256 nftId, address winner, uint256 finalPrice);
    event ArtNFTLiked(uint256 nftId, address user);
    event PlatformFeePercentageSet(uint256 percentage);
    event PlatformFeesWithdrawn(uint256 amount, address admin);
    event ContractPaused();
    event ContractUnpaused();


    // ** Modifiers **

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action.");
        _;
    }

    modifier onlyArtist() {
        require(isRegisteredArtist[msg.sender], "Only registered artists can perform this action.");
        _;
    }

    modifier onlyCurator() {
        require(isCurator[msg.sender], "Only curators can perform this action.");
        _;
    }

    modifier onlyExistingNFT(uint256 _nftId) {
        require(existsNFT[_nftId], "NFT does not exist.");
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


    // ** Constructor **
    constructor() {
        owner = msg.sender;
    }

    // ** 1. Core NFT Functionality **

    /// @dev Mints a new Art NFT for a registered artist.
    /// @param _metadataURI URI pointing to the NFT metadata (e.g., IPFS link).
    function mintArtNFT(string memory _metadataURI) external onlyArtist whenNotPaused {
        uint256 currentNFTId = nextNFTId;
        nftOwner[currentNFTId] = msg.sender;
        nftMetadataURI[currentNFTId] = _metadataURI;
        existsNFT[currentNFTId] = true;
        nextNFTId++;

        emit ArtNFTMinted(currentNFTId, msg.sender, _metadataURI);
    }

    /// @dev Transfers an Art NFT to a new owner.
    /// @param _to Address of the recipient.
    /// @param _nftId ID of the NFT to transfer.
    function transferArtNFT(address _to, uint256 _nftId) external whenNotPaused onlyExistingNFT(_nftId) {
        require(nftOwner[_nftId] == msg.sender, "You are not the owner of this NFT.");
        nftOwner[_nftId] = _to;
        // Consider adding safeTransferFrom pattern for enhanced security in production.
    }

    /// @dev Retrieves the owner of a specific Art NFT.
    /// @param _nftId ID of the NFT.
    /// @return The address of the NFT owner.
    function getArtNFTOwner(uint256 _nftId) external view onlyExistingNFT(_nftId) returns (address) {
        return nftOwner[_nftId];
    }

    /// @dev Retrieves the metadata URI for a specific Art NFT.
    /// @param _nftId ID of the NFT.
    /// @return The metadata URI string.
    function getArtNFTMetadataURI(uint256 _nftId) external view onlyExistingNFT(_nftId) returns (string memory) {
        return nftMetadataURI[_nftId];
    }


    // ** 2. Artist Management **

    /// @dev Registers a user as an artist.
    /// @param _artistName Name of the artist (can be used for display).
    function registerArtist(string memory _artistName) external whenNotPaused {
        require(!isRegisteredArtist[msg.sender], "You are already a registered artist.");
        isRegisteredArtist[msg.sender] = true;
        emit ArtistRegistered(msg.sender, _artistName);
    }

    /// @dev Allows artists to set or update their profile information.
    /// @param _bio Artist's biography.
    /// @param _website Artist's website URL.
    function setArtistProfile(string memory _bio, string memory _website) external onlyArtist whenNotPaused {
        artistProfiles[msg.sender] = ArtistProfile({bio: _bio, website: _website});
        emit ArtistProfileUpdated(msg.sender);
    }

    /// @dev Retrieves the profile information of an artist.
    /// @param _artistAddress Address of the artist.
    /// @return ArtistProfile struct containing bio and website.
    function getArtistProfile(address _artistAddress) external view returns (ArtistProfile memory) {
        return artistProfiles[_artistAddress];
    }

    /// @dev Allows artists to set their royalty percentage for secondary sales of their NFTs.
    /// @param _nftId ID of the NFT.
    /// @param _percentage Royalty percentage (e.g., 5 for 5%).
    function setRoyaltyPercentage(uint256 _nftId, uint256 _percentage) external onlyArtist whenNotPaused onlyExistingNFT(_nftId) {
        require(nftOwner[_nftId] == msg.sender, "You are not the owner of this NFT.");
        require(_percentage <= 20, "Royalty percentage cannot exceed 20%."); // Example limit
        royaltyPercentage[_nftId] = _percentage;
        emit RoyaltyPercentageSet(_nftId, _percentage);
    }


    // ** 3. Gallery Curation & Collections **

    /// @dev Allows users to apply to become a curator.
    function applyToBeCurator() external whenNotPaused {
        require(!isCurator[msg.sender], "You are already a curator.");
        require(!pendingCuratorApplication[msg.sender], "You have already applied to be a curator.");
        pendingCuratorApplication[msg.sender] = true;
        pendingCuratorApplicants.push(msg.sender);
        emit CuratorApplicationSubmitted(msg.sender);
    }

    /// @dev Admin function to approve a curator application.
    /// @param _applicant Address of the curator applicant.
    function approveCurator(address _applicant) external onlyOwner whenNotPaused {
        require(pendingCuratorApplication[_applicant], "Applicant has not applied to be a curator.");
        isCurator[_applicant] = true;
        pendingCuratorApplication[_applicant] = false;
        // Remove from pending list (optional, but good for cleanup)
        for (uint256 i = 0; i < pendingCuratorApplicants.length; i++) {
            if (pendingCuratorApplicants[i] == _applicant) {
                pendingCuratorApplicants[i] = pendingCuratorApplicants[pendingCuratorApplicants.length - 1];
                pendingCuratorApplicants.pop();
                break;
            }
        }
        emit CuratorApproved(_applicant);
    }

    /// @dev Admin function to reject a curator application.
    /// @param _applicant Address of the curator applicant.
    function rejectCurator(address _applicant) external onlyOwner whenNotPaused {
        require(pendingCuratorApplication[_applicant], "Applicant has not applied to be a curator.");
        pendingCuratorApplication[_applicant] = false;
         // Remove from pending list
        for (uint256 i = 0; i < pendingCuratorApplicants.length; i++) {
            if (pendingCuratorApplicants[i] == _applicant) {
                pendingCuratorApplicants[i] = pendingCuratorApplicants[pendingCuratorApplicants.length - 1];
                pendingCuratorApplicants.pop();
                break;
            }
        }
        emit CuratorRejected(_applicant);
    }

    /// @dev Allows curators to create a new curated collection.
    /// @param _name Name of the collection.
    /// @param _description Description of the collection.
    function createCuratedCollection(string memory _name, string memory _description) external onlyCurator whenNotPaused {
        uint256 currentCollectionId = nextCollectionId;
        collections[currentCollectionId] = Collection({
            name: _name,
            description: _description,
            curator: msg.sender,
            creationTimestamp: block.timestamp
        });
        nextCollectionId++;
        emit CuratedCollectionCreated(currentCollectionId, _name, msg.sender);
    }

    /// @dev Allows curators to add an Art NFT to a curated collection.
    /// @param _collectionId ID of the collection.
    /// @param _nftId ID of the NFT to add.
    function addToCuratedCollection(uint256 _collectionId, uint256 _nftId) external onlyCurator whenNotPaused onlyExistingNFT(_nftId) {
        require(collections[_collectionId].curator == msg.sender, "You are not the curator of this collection.");
        require(!collectionNFTs[_collectionId][_nftId], "NFT is already in this collection.");
        collectionNFTs[_collectionId][_nftId] = true;
        emit NFTAddedToCollection(_collectionId, _nftId);
    }

    /// @dev Allows curators to remove an Art NFT from a curated collection.
    /// @param _collectionId ID of the collection.
    /// @param _nftId ID of the NFT to remove.
    function removeFromCuratedCollection(uint256 _collectionId, uint256 _nftId) external onlyCurator whenNotPaused onlyExistingNFT(_nftId) {
        require(collections[_collectionId].curator == msg.sender, "You are not the curator of this collection.");
        require(collectionNFTs[_collectionId][_nftId], "NFT is not in this collection.");
        delete collectionNFTs[_collectionId][_nftId];
        emit NFTRemovedFromCollection(_collectionId, _nftId);
    }

    /// @dev Retrieves details of a curated collection.
    /// @param _collectionId ID of the collection.
    /// @return Collection struct containing collection details.
    function getCuratedCollectionDetails(uint256 _collectionId) external view returns (Collection memory) {
        return collections[_collectionId];
    }

    /// @dev Checks if an NFT is part of a specific curated collection.
    /// @param _collectionId ID of the collection.
    /// @param _nftId ID of the NFT.
    /// @return True if the NFT is in the collection, false otherwise.
    function isNFTInCollection(uint256 _collectionId, uint256 _nftId) external view onlyExistingNFT(_nftId) returns (bool) {
        return collectionNFTs[_collectionId][_nftId];
    }


    // ** 4. Dynamic Pricing & Auctions **

    /// @dev Allows artists to list their Art NFT for sale at a fixed price.
    /// @param _nftId ID of the NFT to list.
    /// @param _price Sale price in wei.
    function listArtNFTForSale(uint256 _nftId, uint256 _price) external onlyArtist whenNotPaused onlyExistingNFT(_nftId) {
        require(nftOwner[_nftId] == msg.sender, "You are not the owner of this NFT.");
        nftListings[_nftId] = Listing({isListed: true, price: _price, seller: msg.sender});
        emit ArtNFTListedForSale(_nftId, _price, msg.sender);
    }

    /// @dev Allows collectors to buy an Art NFT listed for sale.
    /// @param _nftId ID of the NFT to buy.
    function buyArtNFT(uint256 _nftId) external payable whenNotPaused onlyExistingNFT(_nftId) {
        require(nftListings[_nftId].isListed, "NFT is not listed for sale.");
        require(msg.value >= nftListings[_nftId].price, "Insufficient funds sent.");

        Listing memory listing = nftListings[_nftId];
        address seller = listing.seller;
        uint256 price = listing.price;

        // Platform Fee Calculation
        uint256 platformFee = (price * platformFeePercentage) / 100;
        uint256 artistPayout = price - platformFee;

        // Transfer NFT
        nftOwner[_nftId] = msg.sender;
        delete nftListings[_nftId]; // Remove listing after purchase

        // Pay Artist and Platform
        payable(seller).transfer(artistPayout);
        accumulatedPlatformFees += platformFee;

        // Royalty Payment (If applicable)
        if (royaltyPercentage[_nftId] > 0) {
            uint256 royaltyAmount = (price * royaltyPercentage[_nftId]) / 100;
            uint256 royaltyRecipientPayout = (royaltyAmount * (100 - platformFeePercentage)) / 100; // Apply platform fee to royalty as well (optional, can be adjusted)
            uint256 royaltyPlatformFee = royaltyAmount - royaltyRecipientPayout;
            accumulatedPlatformFees += royaltyPlatformFee;
            payable(nftOwner[_nftId]).transfer(royaltyRecipientPayout); // Pay current owner as royalty recipient (adjust logic if needed based on royalty rules)
            artistPayout -= royaltyAmount; // Reduce artist payout by royalty amount
        }

        emit ArtNFTBought(_nftId, msg.sender, price);
    }


    /// @dev Creates a Dutch auction for an Art NFT.
    /// @param _nftId ID of the NFT to auction.
    /// @param _startPrice Starting price of the auction in wei.
    /// @param _decrementPerBlock Price decrement per block in wei.
    /// @param _durationInBlocks Auction duration in blocks.
    function createDutchAuction(uint256 _nftId, uint256 _startPrice, uint256 _decrementPerBlock, uint256 _durationInBlocks) external onlyArtist whenNotPaused onlyExistingNFT(_nftId) {
        require(nftOwner[_nftId] == msg.sender, "You are not the owner of this NFT.");
        require(!dutchAuctions[_nftId].isActive, "Auction already active for this NFT.");

        dutchAuctions[_nftId] = DutchAuction({
            isActive: true,
            startTime: block.number,
            endTime: block.number + _durationInBlocks,
            startPrice: _startPrice,
            decrementPerBlock: _decrementPerBlock,
            seller: msg.sender,
            highestBidder: address(0),
            highestBid: 0
        });
        emit DutchAuctionCreated(_nftId, block.number, block.number + _durationInBlocks, _startPrice, _decrementPerBlock, msg.sender);
    }

    /// @dev Allows collectors to bid on a Dutch auction.
    /// @param _nftId ID of the NFT in auction.
    function bidOnDutchAuction(uint256 _nftId) external payable whenNotPaused onlyExistingNFT(_nftId) {
        require(dutchAuctions[_nftId].isActive, "Auction is not active.");
        require(block.number <= dutchAuctions[_nftId].endTime, "Auction has ended.");
        uint256 currentPrice = getCurrentDutchAuctionPrice(_nftId);
        require(msg.value >= currentPrice, "Bid amount is less than the current price.");

        DutchAuction storage auction = dutchAuctions[_nftId];

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid); // Refund previous bidder
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;

        emit DutchAuctionBidPlaced(_nftId, msg.sender, msg.value);
    }

    /// @dev Ends a Dutch auction. Can be called by anyone after the auction end time.
    /// @param _nftId ID of the NFT in auction.
    function endDutchAuction(uint256 _nftId) external whenNotPaused onlyExistingNFT(_nftId) {
        require(dutchAuctions[_nftId].isActive, "Auction is not active.");
        require(block.number > dutchAuctions[_nftId].endTime, "Auction has not ended yet.");

        DutchAuction storage auction = dutchAuctions[_nftId];
        require(auction.highestBidder != address(0), "No bids were placed on this auction."); // Or handle no bid scenario differently

        auction.isActive = false;
        address seller = auction.seller;
        uint256 finalPrice = auction.highestBid;

         // Platform Fee Calculation
        uint256 platformFee = (finalPrice * platformFeePercentage) / 100;
        uint256 artistPayout = finalPrice - platformFee;

        // Transfer NFT
        nftOwner[_nftId] = auction.highestBidder;

        // Pay Artist and Platform
        payable(seller).transfer(artistPayout);
        accumulatedPlatformFees += platformFee;

        // Royalty Payment (If applicable)
        if (royaltyPercentage[_nftId] > 0) {
            uint256 royaltyAmount = (finalPrice * royaltyPercentage[_nftId]) / 100;
            uint256 royaltyRecipientPayout = (royaltyAmount * (100 - platformFeePercentage)) / 100; // Apply platform fee to royalty as well (optional, can be adjusted)
            uint256 royaltyPlatformFee = royaltyAmount - royaltyRecipientPayout;
            accumulatedPlatformFees += royaltyPlatformFee;
            payable(nftOwner[_nftId]).transfer(royaltyRecipientPayout); // Pay current owner as royalty recipient (adjust logic if needed based on royalty rules)
            artistPayout -= royaltyAmount; // Reduce artist payout by royalty amount
        }

        emit DutchAuctionEnded(_nftId, auction.highestBidder, finalPrice);

    }

    /// @dev Internal function to calculate the current price of a Dutch auction.
    /// @param _nftId ID of the NFT in auction.
    /// @return Current auction price in wei.
    function getCurrentDutchAuctionPrice(uint256 _nftId) internal view returns (uint256) {
        DutchAuction memory auction = dutchAuctions[_nftId];
        if (!auction.isActive || block.number > auction.endTime) {
            return 0; // Auction not active or ended, price is 0
        }
        uint256 blocksPassed = block.number - auction.startTime;
        uint256 priceDecrement = blocksPassed * auction.decrementPerBlock;
        uint256 currentPrice = auction.startPrice > priceDecrement ? auction.startPrice - priceDecrement : 0; // Price cannot be negative
        return currentPrice;
    }

    /// @dev Public function to get the current price of a Dutch auction.
    /// @param _nftId ID of the NFT in auction.
    /// @return Current auction price in wei.
    function getDutchAuctionCurrentPrice(uint256 _nftId) external view returns (uint256) {
        return getCurrentDutchAuctionPrice(_nftId);
    }


    // ** 5. Community & Engagement Features **

    /// @dev Allows registered users to 'like' an Art NFT.
    /// @param _nftId ID of the NFT to like.
    function likeArtNFT(uint256 _nftId) external whenNotPaused onlyExistingNFT(_nftId) {
        require(isRegisteredArtist[msg.sender] || nftOwner[_nftId] == msg.sender || isCurator[msg.sender] , "Only registered users (artists, owners, curators) can like NFTs."); // Example: Restrict likes to registered users
        require(!userLikedNFT[_nftId][msg.sender], "You have already liked this NFT.");
        nftLikes[_nftId]++;
        userLikedNFT[_nftId][msg.sender] = true;
        emit ArtNFTLiked(_nftId, msg.sender);
    }

    /// @dev Retrieves the number of likes for an Art NFT.
    /// @param _nftId ID of the NFT.
    /// @return The number of likes.
    function getArtNFTLikes(uint256 _nftId) external view onlyExistingNFT(_nftId) returns (uint256) {
        return nftLikes[_nftId];
    }


    // ** 6. Platform & Admin Functions **

    /// @dev Admin function to set the platform fee percentage.
    /// @param _percentage New platform fee percentage.
    function setPlatformFee(uint256 _percentage) external onlyOwner whenNotPaused {
        require(_percentage <= 10, "Platform fee percentage cannot exceed 10%."); // Example limit
        platformFeePercentage = _percentage;
        emit PlatformFeePercentageSet(_percentage);
    }

    /// @dev Admin function to withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyOwner whenNotPaused {
        uint256 amountToWithdraw = accumulatedPlatformFees;
        accumulatedPlatformFees = 0;
        payable(owner).transfer(amountToWithdraw);
        emit PlatformFeesWithdrawn(amountToWithdraw, owner);
    }

    /// @dev Admin function to pause the contract, halting critical functionalities.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @dev Admin function to unpause the contract, resuming functionalities.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /// @dev Fallback function to receive Ether.
    receive() external payable {}
}
```