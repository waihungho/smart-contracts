```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI-Powered Personalization
 * @author Bard (Example Smart Contract - Conceptual and for illustrative purposes only)
 *
 * @dev This smart contract outlines a decentralized NFT marketplace with advanced features including:
 *      - Dynamic NFTs that can evolve based on on-chain or off-chain data (simulated AI).
 *      - Personalized user experience with curated collections and recommendations.
 *      - Advanced marketplace functionalities like auctions, bundled NFTs, and bidding systems.
 *      - Decentralized governance mechanisms for platform evolution and fee management.
 *
 * Function Summary:
 * -----------------
 * **Core NFT Management:**
 * 1. mintNFT(address _to, string memory _uri, bytes memory _initialTraits): Mints a new Dynamic NFT.
 * 2. updateNFTTraits(uint256 _tokenId, bytes memory _newTraits): Updates the dynamic traits of an NFT.
 * 3. burnNFT(uint256 _tokenId): Burns (destroys) an NFT.
 * 4. setTokenURI(uint256 _tokenId, string memory _newUri): Updates the URI of an NFT.
 * 5. getTokenTraits(uint256 _tokenId) view returns (bytes memory): Retrieves the dynamic traits of an NFT.
 *
 * **Marketplace Listing & Selling:**
 * 6. listNFTForSale(uint256 _tokenId, uint256 _price): Lists an NFT for sale at a fixed price.
 * 7. cancelNFTListing(uint256 _listingId): Cancels an existing NFT listing.
 * 8. buyNFT(uint256 _listingId): Allows a user to buy a listed NFT.
 * 9. createAuction(uint256 _tokenId, uint256 _startPrice, uint256 _startTime, uint256 _endTime): Creates a Dutch Auction for an NFT.
 * 10. bidOnAuction(uint256 _auctionId, uint256 _bidAmount): Allows users to bid on an ongoing auction.
 * 11. settleAuction(uint256 _auctionId): Settles a Dutch auction and transfers NFT to the highest bidder.
 * 12. bundleNFTs(uint256[] memory _tokenIds, string memory _bundleName): Creates a bundle of NFTs.
 * 13. listBundleForSale(uint256 _bundleId, uint256 _price): Lists an NFT bundle for sale.
 * 14. buyBundle(uint256 _bundleId): Allows a user to buy an NFT bundle.
 * 15. makeOfferForNFT(uint256 _tokenId, uint256 _offerAmount): Allows users to make offers on NFTs not listed for sale.
 * 16. acceptOffer(uint256 _offerId): Allows NFT owner to accept a pending offer.
 *
 * **Personalization & Discovery (Simulated AI):**
 * 17. setUserPreferences(bytes memory _preferencesData): Allows users to set their preferences (simulating AI input).
 * 18. getPersonalizedRecommendations(address _userAddress) view returns (uint256[] memory): Returns a list of recommended NFTs based on user preferences (simulated AI logic).
 * 19. createCuratedCollection(string memory _collectionName, uint256[] memory _tokenIds): Creates a curated NFT collection by the platform.
 * 20. getCollectionNFTs(uint256 _collectionId) view returns (uint256[] memory): Retrieves NFTs in a specific curated collection.
 *
 * **Platform Governance & Utility:**
 * 21. setPlatformFee(uint256 _newFeePercentage): Updates the platform fee percentage (governance controlled).
 * 22. withdrawPlatformFees(): Allows the platform owner to withdraw accumulated fees.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DynamicNFTMarketplace is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _listingIdCounter;
    Counters.Counter private _auctionIdCounter;
    Counters.Counter private _bundleIdCounter;
    Counters.Counter private _offerIdCounter;
    Counters.Counter private _collectionIdCounter;

    // Platform Fee (percentage - e.g., 200 for 2%)
    uint256 public platformFeePercentage = 200; // Default 2%

    // NFT Traits Storage (Dynamic part of NFTs)
    mapping(uint256 => bytes) public nftTraits;

    // Marketplace Listings
    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => Listing) public nftListings;

    // Dutch Auctions
    struct Auction {
        uint256 auctionId;
        uint256 tokenId;
        address seller;
        uint256 startPrice;
        uint256 startTime;
        uint256 endTime;
        uint256 currentPrice;
        address highestBidder;
        uint256 highestBid;
        bool isActive;
    }
    mapping(uint256 => Auction) public dutchAuctions;

    // NFT Bundles
    struct NFTBundle {
        uint256 bundleId;
        string bundleName;
        uint256[] tokenIds;
        address creator;
        uint256 price;
        bool isListed;
    }
    mapping(uint256 => NFTBundle) public nftBundles;
    mapping(uint256 => bool) public isBundleListed; // Track if a bundle is listed

    // Offers on NFTs
    struct Offer {
        uint256 offerId;
        uint256 tokenId;
        address offerer;
        uint256 offerAmount;
        bool isActive;
    }
    mapping(uint256 => Offer) public nftOffers;

    // User Preferences (Simulated AI Input - In real world, this would be more complex & off-chain)
    mapping(address => bytes) public userPreferences;

    // Curated Collections
    struct CuratedCollection {
        uint256 collectionId;
        string collectionName;
        uint256[] tokenIds;
        address curator; // Platform or designated curator
    }
    mapping(uint256 => CuratedCollection) public curatedCollections;

    // Platform Fee Balance
    uint256 public platformFeeBalance;

    event NFTMinted(uint256 tokenId, address to, string tokenURI);
    event NFTTraitsUpdated(uint256 tokenId, bytes newTraits);
    event NFTBurned(uint256 tokenId);
    event NFTListCreated(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event NFTListCancelled(uint256 listingId);
    event NFTSold(uint256 listingId, uint256 tokenId, address buyer, address seller, uint256 price);
    event AuctionCreated(uint256 auctionId, uint256 tokenId, address seller, uint256 startPrice, uint256 startTime, uint256 endTime);
    event BidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionSettled(uint256 auctionId, uint256 tokenId, address winner, uint256 finalPrice);
    event BundleCreated(uint256 bundleId, string bundleName, uint256[] tokenIds, address creator);
    event BundleListed(uint256 bundleId, uint256 price);
    event BundleSold(uint256 bundleId, address buyer, address seller, uint256 price);
    event OfferMade(uint256 offerId, uint256 tokenId, address offerer, uint256 offerAmount);
    event OfferAccepted(uint256 offerId, uint256 tokenId, address buyer, address seller, uint256 price);
    event UserPreferencesSet(address user, bytes preferencesData);
    event CollectionCreated(uint256 collectionId, string collectionName, address curator);


    constructor() ERC721("DynamicNFT", "DNFT") Ownable() {}

    // ====================== Core NFT Management ======================

    /// @notice Mints a new Dynamic NFT.
    /// @param _to Address to mint the NFT to.
    /// @param _uri Metadata URI for the NFT.
    /// @param _initialTraits Initial dynamic traits of the NFT.
    function mintNFT(address _to, string memory _uri, bytes memory _initialTraits) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _uri);
        nftTraits[tokenId] = _initialTraits;
        emit NFTMinted(tokenId, _to, _uri);
        emit NFTTraitsUpdated(tokenId, _newTraits); // Emit event even if initial traits are provided
    }

    /// @notice Updates the dynamic traits of an NFT.
    /// @param _tokenId ID of the NFT to update.
    /// @param _newTraits New dynamic traits to set for the NFT.
    function updateNFTTraits(uint256 _tokenId, bytes memory _newTraits) public {
        require(_exists(_tokenId), "NFT does not exist");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not NFT owner or approved");
        nftTraits[_tokenId] = _newTraits;
        emit NFTTraitsUpdated(_tokenId, _newTraits);
    }

    /// @notice Burns (destroys) an NFT.
    /// @param _tokenId ID of the NFT to burn.
    function burnNFT(uint256 _tokenId) public {
        require(_exists(_tokenId), "NFT does not exist");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not NFT owner or approved");
        _burn(_tokenId);
        emit NFTBurned(_tokenId);
    }

    /// @notice Updates the URI of an NFT.
    /// @param _tokenId ID of the NFT to update.
    /// @param _newUri New metadata URI for the NFT.
    function setTokenURI(uint256 _tokenId, string memory _newUri) public onlyOwner {
        require(_exists(_tokenId), "NFT does not exist");
        _setTokenURI(_tokenId, _newUri);
    }

    /// @notice Retrieves the dynamic traits of an NFT.
    /// @param _tokenId ID of the NFT.
    /// @return bytes Dynamic traits of the NFT.
    function getTokenTraits(uint256 _tokenId) public view returns (bytes memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return nftTraits[_tokenId];
    }

    // ====================== Marketplace Listing & Selling ======================

    /// @notice Lists an NFT for sale at a fixed price.
    /// @param _tokenId ID of the NFT to list.
    /// @param _price Sale price in wei.
    function listNFTForSale(uint256 _tokenId, uint256 _price) public nonReentrant {
        require(_exists(_tokenId), "NFT does not exist");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not NFT owner or approved");
        require(ownerOf(_tokenId) == msg.sender, "Not the owner of the NFT");
        require(nftListings[_tokenId].isActive == false, "NFT already listed"); // Prevent relisting without cancelling first

        _listingIdCounter.increment();
        uint256 listingId = _listingIdCounter.current();

        nftListings[listingId] = Listing({
            listingId: listingId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });

        _approve(address(this), _tokenId); // Approve marketplace to transfer NFT
        emit NFTListCreated(listingId, _tokenId, msg.sender, _price);
    }

    /// @notice Cancels an existing NFT listing.
    /// @param _listingId ID of the listing to cancel.
    function cancelNFTListing(uint256 _listingId) public nonReentrant {
        require(nftListings[_listingId].isActive, "Listing is not active");
        require(nftListings[_listingId].seller == msg.sender, "Not the seller of the NFT");

        nftListings[_listingId].isActive = false;
        emit NFTListCancelled(_listingId);
    }

    /// @notice Allows a user to buy a listed NFT.
    /// @param _listingId ID of the listing to buy.
    function buyNFT(uint256 _listingId) public payable nonReentrant {
        require(nftListings[_listingId].isActive, "Listing is not active");
        require(msg.value >= nftListings[_listingId].price, "Insufficient funds sent");

        Listing memory listing = nftListings[_listingId];
        nftListings[_listingId].isActive = false; // Deactivate listing

        uint256 platformFee = (listing.price * platformFeePercentage) / 10000; // Calculate platform fee
        uint256 sellerPayment = listing.price - platformFee;

        platformFeeBalance += platformFee;

        // Transfer funds to seller and platform
        (bool successSeller, ) = payable(listing.seller).call{value: sellerPayment}("");
        require(successSeller, "Seller payment failed");

        // Transfer NFT to buyer
        transferFrom(listing.seller, msg.sender, listing.tokenId);

        emit NFTSold(_listingId, listing.tokenId, msg.sender, listing.seller, listing.price);
    }

    /// @notice Creates a Dutch Auction for an NFT. Price decreases over time.
    /// @param _tokenId ID of the NFT for auction.
    /// @param _startPrice Starting price of the auction in wei.
    /// @param _startTime Unix timestamp for auction start time.
    /// @param _endTime Unix timestamp for auction end time.
    function createAuction(uint256 _tokenId, uint256 _startPrice, uint256 _startTime, uint256 _endTime) public nonReentrant {
        require(_exists(_tokenId), "NFT does not exist");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not NFT owner or approved");
        require(ownerOf(_tokenId) == msg.sender, "Not the owner of the NFT");
        require(_startTime >= block.timestamp && _endTime > _startTime, "Invalid auction times");

        _auctionIdCounter.increment();
        uint256 auctionId = _auctionIdCounter.current();

        dutchAuctions[auctionId] = Auction({
            auctionId: auctionId,
            tokenId: _tokenId,
            seller: msg.sender,
            startPrice: _startPrice,
            startTime: _startTime,
            endTime: _endTime,
            currentPrice: _startPrice,
            highestBidder: address(0),
            highestBid: 0,
            isActive: true
        });

        _approve(address(this), _tokenId); // Approve marketplace to transfer NFT
        emit AuctionCreated(auctionId, _tokenId, msg.sender, _startPrice, _startTime, _endTime);
    }

    /// @notice Allows users to bid on an ongoing Dutch auction.
    /// @param _auctionId ID of the auction to bid on.
    /// @param _bidAmount Bid amount in wei.
    function bidOnAuction(uint256 _auctionId, uint256 _bidAmount) public payable nonReentrant {
        require(dutchAuctions[_auctionId].isActive, "Auction is not active");
        require(block.timestamp >= dutchAuctions[_auctionId].startTime && block.timestamp <= dutchAuctions[_auctionId].endTime, "Auction not in progress");
        require(msg.value >= _bidAmount, "Insufficient funds sent");

        Auction storage auction = dutchAuctions[_auctionId];

        // Calculate current price (linear decrease for simplicity - can be more complex)
        uint256 auctionDuration = auction.endTime - auction.startTime;
        uint256 timeElapsed = block.timestamp - auction.startTime;
        uint256 priceDecrease = (auction.startPrice * timeElapsed) / auctionDuration;
        auction.currentPrice = auction.startPrice - priceDecrease;

        require(_bidAmount >= auction.currentPrice, "Bid amount too low for current price");

        // Refund previous bidder if exists
        if (auction.highestBidder != address(0)) {
            (bool refundSuccess, ) = payable(auction.highestBidder).call{value: auction.highestBid}("");
            require(refundSuccess, "Refund to previous bidder failed");
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = _bidAmount;
        emit BidPlaced(_auctionId, msg.sender, _bidAmount);
    }

    /// @notice Settles a Dutch auction and transfers NFT to the highest bidder.
    /// @param _auctionId ID of the auction to settle.
    function settleAuction(uint256 _auctionId) public nonReentrant {
        require(dutchAuctions[_auctionId].isActive, "Auction is not active");
        require(block.timestamp > dutchAuctions[_auctionId].endTime, "Auction is not finished yet");

        Auction storage auction = dutchAuctions[_auctionId];
        auction.isActive = false; // Deactivate auction

        uint256 platformFee = (auction.highestBid * platformFeePercentage) / 10000;
        uint256 sellerPayment = auction.highestBid - platformFee;
        platformFeeBalance += platformFee;

        // Transfer funds to seller and platform
        (bool successSeller, ) = payable(auction.seller).call{value: sellerPayment}("");
        require(successSeller, "Seller payment failed");

        // Transfer NFT to highest bidder
        if (auction.highestBidder != address(0)) {
            transferFrom(auction.seller, auction.highestBidder, auction.tokenId);
            emit AuctionSettled(_auctionId, auction.tokenId, auction.highestBidder, auction.highestBid);
        } else {
            // No bids, return NFT to seller (optional behavior - can also burn or relist)
            transferFrom(address(this), auction.seller, auction.tokenId); // Marketplace was approved
            // Optionally, refund auction creation fee if any was charged.
        }
    }

    /// @notice Creates a bundle of NFTs.
    /// @param _tokenIds Array of NFT token IDs to bundle.
    /// @param _bundleName Name for the NFT bundle.
    function bundleNFTs(uint256[] memory _tokenIds, string memory _bundleName) public nonReentrant {
        require(_tokenIds.length > 1, "Bundle must contain at least two NFTs");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_exists(_tokenIds[i]), "NFT in bundle does not exist");
            require(_isApprovedOrOwner(msg.sender, _tokenIds[i]), "Not owner/approved of NFT in bundle");
            require(ownerOf(_tokenIds[i]) == msg.sender, "Not the owner of NFT in bundle");
        }

        _bundleIdCounter.increment();
        uint256 bundleId = _bundleIdCounter.current();

        nftBundles[bundleId] = NFTBundle({
            bundleId: bundleId,
            bundleName: _bundleName,
            tokenIds: _tokenIds,
            creator: msg.sender,
            price: 0, // Price set when listing
            isListed: false
        });

        // Approve marketplace to transfer all NFTs in bundle
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _approve(address(this), _tokenIds[i]);
        }

        emit BundleCreated(bundleId, _bundleName, _tokenIds, msg.sender);
    }

    /// @notice Lists an NFT bundle for sale.
    /// @param _bundleId ID of the bundle to list.
    /// @param _price Sale price of the bundle in wei.
    function listBundleForSale(uint256 _bundleId, uint256 _price) public nonReentrant {
        require(nftBundles[_bundleId].creator == msg.sender, "Not bundle creator");
        require(!nftBundles[_bundleId].isListed, "Bundle already listed");

        nftBundles[_bundleId].price = _price;
        nftBundles[_bundleId].isListed = true;
        emit BundleListed(_bundleId, _price);
    }

    /// @notice Allows a user to buy an NFT bundle.
    /// @param _bundleId ID of the bundle to buy.
    function buyBundle(uint256 _bundleId) public payable nonReentrant {
        require(nftBundles[_bundleId].isListed, "Bundle is not listed");
        require(msg.value >= nftBundles[_bundleId].price, "Insufficient funds sent");

        NFTBundle storage bundle = nftBundles[_bundleId];
        bundle.isListed = false; // Mark bundle as sold

        uint256 platformFee = (bundle.price * platformFeePercentage) / 10000;
        uint256 sellerPayment = bundle.price - platformFee;
        platformFeeBalance += platformFee;

        // Transfer funds to bundle creator and platform
        (bool successSeller, ) = payable(bundle.creator).call{value: sellerPayment}("");
        require(successSeller, "Seller payment failed");

        // Transfer all NFTs in bundle to buyer
        for (uint256 i = 0; i < bundle.tokenIds.length; i++) {
            transferFrom(bundle.creator, msg.sender, bundle.tokenIds[i]);
        }

        emit BundleSold(_bundleId, msg.sender, bundle.creator, bundle.price);
    }

    /// @notice Allows users to make offers on NFTs not currently listed for sale.
    /// @param _tokenId ID of the NFT to make an offer on.
    /// @param _offerAmount Offer amount in wei.
    function makeOfferForNFT(uint256 _tokenId, uint256 _offerAmount) public nonReentrant {
        require(_exists(_tokenId), "NFT does not exist");
        require(nftListings[_tokenId].isActive == false, "NFT is already listed for sale"); // Prevent offers on listed NFTs

        _offerIdCounter.increment();
        uint256 offerId = _offerIdCounter.current();

        nftOffers[offerId] = Offer({
            offerId: offerId,
            tokenId: _tokenId,
            offerer: msg.sender,
            offerAmount: _offerAmount,
            isActive: true
        });

        emit OfferMade(offerId, _tokenId, msg.sender, _offerAmount);
    }

    /// @notice Allows NFT owner to accept a pending offer.
    /// @param _offerId ID of the offer to accept.
    function acceptOffer(uint256 _offerId) public nonReentrant {
        require(nftOffers[_offerId].isActive, "Offer is not active");
        Offer storage offer = nftOffers[_offerId];
        require(ownerOf(offer.tokenId) == msg.sender, "Not the owner of the NFT");

        nftOffers[_offerId].isActive = false; // Deactivate offer

        uint256 platformFee = (offer.offerAmount * platformFeePercentage) / 10000;
        uint256 sellerPayment = offer.offerAmount - platformFee;
        platformFeeBalance += platformFee;

        // Transfer funds to seller and platform
        (bool successSeller, ) = payable(msg.sender).call{value: sellerPayment}(""); // msg.sender is the NFT owner (seller)
        require(successSeller, "Seller payment failed");

        // Transfer NFT to offerer (buyer)
        transferFrom(msg.sender, offer.offerer, offer.tokenId);

        emit OfferAccepted(_offerId, offer.tokenId, offer.offerer, msg.sender, offer.offerAmount);
    }


    // ====================== Personalization & Discovery (Simulated AI) ======================

    /// @notice Allows users to set their preferences (simulating AI input).
    /// @param _preferencesData Data representing user preferences (e.g., bytes representing categories, artists, etc.).
    function setUserPreferences(bytes memory _preferencesData) public {
        userPreferences[msg.sender] = _preferencesData;
        emit UserPreferencesSet(msg.sender, _preferencesData);
    }

    /// @notice Returns a list of recommended NFTs based on user preferences (simulated AI logic).
    /// @param _userAddress Address of the user to get recommendations for.
    /// @return uint256[] Array of recommended NFT token IDs.
    function getPersonalizedRecommendations(address _userAddress) public view returns (uint256[] memory) {
        // **Simulated AI Logic - In a real-world scenario, this would be off-chain and more complex.**
        // This is a placeholder for demonstration purposes.
        bytes memory preferences = userPreferences[_userAddress];
        uint256[] memory recommendations;

        if (bytes(preferences).length > 0) {
            // Example: If user has preferences, recommend NFTs minted recently
            uint256 currentTokenId = _tokenIdCounter.current();
            if (currentTokenId > 0) {
                recommendations = new uint256[](1);
                recommendations[0] = currentTokenId; // Recommend the latest NFT minted.
            } else {
                recommendations = new uint256[](0); // No recommendations if no NFTs minted yet.
            }
        } else {
            // Default: Recommend NFTs with interesting traits (again, very simplistic)
            recommendations = new uint256[](0);
            for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
                if (_exists(i) && bytes(nftTraits[i]).length > 10) { // Example: Recommend if traits are "complex" (arbitrary length check)
                    uint256[] memory tempRecommendations = new uint256[](recommendations.length + 1);
                    for(uint256 j=0; j<recommendations.length; j++){
                        tempRecommendations[j] = recommendations[j];
                    }
                    tempRecommendations[recommendations.length] = i;
                    recommendations = tempRecommendations;
                }
            }
        }
        return recommendations;
    }

    /// @notice Creates a curated NFT collection by the platform.
    /// @param _collectionName Name of the curated collection.
    /// @param _tokenIds Array of NFT token IDs to include in the collection.
    function createCuratedCollection(string memory _collectionName, uint256[] memory _tokenIds) public onlyOwner {
        _collectionIdCounter.increment();
        uint256 collectionId = _collectionIdCounter.current();

        curatedCollections[collectionId] = CuratedCollection({
            collectionId: collectionId,
            collectionName: _collectionName,
            tokenIds: _tokenIds,
            curator: msg.sender // Owner of the contract (platform) is the curator
        });
        emit CollectionCreated(collectionId, _collectionName, msg.sender);
    }

    /// @notice Retrieves NFTs in a specific curated collection.
    /// @param _collectionId ID of the curated collection.
    /// @return uint256[] Array of NFT token IDs in the collection.
    function getCollectionNFTs(uint256 _collectionId) public view returns (uint256[] memory) {
        require(_collectionId > 0 && _collectionId <= _collectionIdCounter.current(), "Invalid collection ID");
        return curatedCollections[_collectionId].tokenIds;
    }


    // ====================== Platform Governance & Utility ======================

    /// @notice Updates the platform fee percentage. Only owner can call.
    /// @param _newFeePercentage New platform fee percentage (e.g., 200 for 2%).
    function setPlatformFee(uint256 _newFeePercentage) public onlyOwner {
        platformFeePercentage = _newFeePercentage;
    }

    /// @notice Allows the platform owner to withdraw accumulated fees.
    function withdrawPlatformFees() public onlyOwner {
        uint256 amountToWithdraw = platformFeeBalance;
        platformFeeBalance = 0; // Reset platform fee balance after withdrawal
        (bool success, ) = payable(owner()).call{value: amountToWithdraw}("");
        require(success, "Withdrawal failed");
    }

    // Override supportsInterface to declare support for ERC721Metadata
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
    }
}
```