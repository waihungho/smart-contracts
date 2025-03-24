```solidity
/**
 * @title Dynamic NFT Marketplace with Fractional Ownership and Social Features
 * @author Bard (AI Assistant)
 * @dev This smart contract implements an advanced NFT marketplace with features like dynamic NFTs,
 *      fractional ownership, social interactions, reputation system, and curated collections.
 *      It goes beyond basic marketplace functionalities and aims for a more engaging and feature-rich experience.
 *
 * **Outline:**
 * 1. **Core Marketplace Functionality:**
 *    - NFT Listing and Delisting
 *    - Buying NFTs
 *    - Bidding System
 *    - Accepting Bids
 *    - Direct Offers
 *    - Cancelling Offers
 *    - Royalties Management
 *
 * 2. **Fractional Ownership Features:**
 *    - Fractionalize NFT
 *    - Buy Fractions
 *    - Sell Fractions
 *    - Redeem NFT (when all fractions are owned by one address)
 *
 * 3. **Dynamic NFT Features:**
 *    - Set Dynamic Metadata URI Function (Admin Controlled)
 *    - Trigger Dynamic Metadata Update (Based on on-chain events)
 *    - View Current Metadata URI
 *
 * 4. **Social Features:**
 *    - User Profile Creation
 *    - Follow/Unfollow Users
 *    - Like NFT Listings
 *    - Comment on NFT Listings
 *    - Curated Collections (Users can create and manage)
 *
 * 5. **Reputation and Platform Features:**
 *    - Reputation Points System (based on platform activity)
 *    - Staking Platform Token for Enhanced Features/Benefits
 *    - Platform Fee Management (Admin Controlled)
 *    - Pause/Unpause Marketplace (Admin Controlled)
 *    - Withdraw Platform Fees (Admin Controlled)
 *
 * **Function Summary:**
 * 1. `listNFT(address _nftContract, uint256 _tokenId, uint256 _price, bool _isFractionalizable)`: Allows NFT owner to list their NFT for sale on the marketplace.
 * 2. `delistNFT(uint256 _listingId)`: Allows the listing owner to delist their NFT from the marketplace.
 * 3. `buyNFT(uint256 _listingId)`: Allows a buyer to purchase an NFT listed on the marketplace at the listed price.
 * 4. `placeBid(uint256 _listingId, uint256 _bidAmount)`: Allows users to place bids on listed NFTs.
 * 5. `acceptBid(uint256 _listingId, uint256 _bidId)`: Allows the listing owner to accept a specific bid on their NFT.
 * 6. `makeOffer(uint256 _listingId, uint256 _offerPrice)`: Allows users to make direct offers on listed NFTs at a price lower than the listing price.
 * 7. `cancelOffer(uint256 _offerId)`: Allows users to cancel their pending offers on listed NFTs.
 * 8. `acceptOffer(uint256 _offerId)`: Allows the listing owner to accept a direct offer on their NFT.
 * 9. `fractionalizeNFT(uint256 _listingId, uint256 _numberOfFractions)`: Allows the NFT owner to fractionalize their listed NFT into a specified number of fractions.
 * 10. `buyFraction(uint256 _fractionalListingId, uint256 _fractionAmount)`: Allows users to buy fractions of a fractionalized NFT.
 * 11. `sellFraction(uint256 _fractionalListingId, uint256 _fractionAmount)`: Allows fraction owners to sell their fractions of a fractionalized NFT.
 * 12. `redeemNFT(uint256 _fractionalListingId)`: Allows the owner of all fractions of an NFT to redeem the original NFT.
 * 13. `setDynamicMetadataBaseURI(string memory _baseURI)`: (Admin) Sets the base URI for dynamic NFT metadata.
 * 14. `triggerDynamicMetadataUpdate(uint256 _listingId)`: Triggers a dynamic metadata update for a specific NFT listing based on predefined logic.
 * 15. `getNFTMetadataURI(uint256 _listingId)`: Returns the current metadata URI for a given NFT listing.
 * 16. `createUserProfile(string memory _username, string memory _profileURI)`: Allows users to create their marketplace profile.
 * 17. `followUser(address _userToFollow)`: Allows users to follow other users on the marketplace.
 * 18. `unfollowUser(address _userToUnfollow)`: Allows users to unfollow other users.
 * 19. `likeListing(uint256 _listingId)`: Allows users to like NFT listings.
 * 20. `commentOnListing(uint256 _listingId, string memory _comment)`: Allows users to comment on NFT listings.
 * 21. `createCuratedCollection(string memory _collectionName, string memory _collectionDescription)`: Allows users to create curated NFT collections.
 * 22. `addNFTToCollection(uint256 _collectionId, uint256 _listingId)`: Allows users to add listed NFTs to their curated collections.
 * 23. `removeNFTFromCollection(uint256 _collectionId, uint256 _listingId)`: Allows users to remove NFTs from their curated collections.
 * 24. `stakePlatformToken(uint256 _amount)`: Allows users to stake platform tokens for enhanced features.
 * 25. `unstakePlatformToken(uint256 _amount)`: Allows users to unstake platform tokens.
 * 26. `setPlatformFee(uint256 _feePercentage)`: (Admin) Sets the platform fee percentage.
 * 27. `pauseMarketplace()`: (Admin) Pauses the marketplace, disabling core trading functions.
 * 28. `unpauseMarketplace()`: (Admin) Unpauses the marketplace, re-enabling core trading functions.
 * 29. `withdrawPlatformFees()`: (Admin) Allows the platform owner to withdraw accumulated platform fees.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DynamicNFTMarketplace is Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Platform Token (Example - Replace with your actual token)
    IERC20 public platformToken;

    // Platform Fee Percentage (e.g., 200 = 2%)
    uint256 public platformFeePercentage = 200;

    // Dynamic Metadata Base URI
    string public dynamicMetadataBaseURI;

    // Data Structures
    struct Listing {
        uint256 listingId;
        address nftContract;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isFractionalizable;
        bool isFractionalized;
        bool isActive;
    }

    struct Bid {
        uint256 bidId;
        uint256 listingId;
        address bidder;
        uint256 bidAmount;
        bool isActive;
    }

    struct Offer {
        uint256 offerId;
        uint256 listingId;
        address offerer;
        uint256 offerPrice;
        bool isActive;
    }

    struct FractionalListing {
        uint256 fractionalListingId;
        uint256 listingId; // Reference to the original listing
        uint256 totalFractions;
        uint256 fractionsSold;
        mapping(address => uint256) fractionBalances;
        bool isActive;
    }

    struct UserProfile {
        address userAddress;
        string username;
        string profileURI;
        uint256 reputationPoints;
    }

    struct CuratedCollection {
        uint256 collectionId;
        address creator;
        string collectionName;
        string collectionDescription;
        uint256[] listingIds;
    }

    // Mappings and Arrays
    mapping(uint256 => Listing) public listings;
    Counters.Counter private _listingIdCounter;

    mapping(uint256 => Bid) public bids;
    Counters.Counter private _bidIdCounter;

    mapping(uint256 => Offer) public offers;
    Counters.Counter private _offerIdCounter;

    mapping(uint256 => FractionalListing) public fractionalListings;
    Counters.Counter private _fractionalListingIdCounter;

    mapping(address => UserProfile) public userProfiles;
    mapping(address => mapping(address => bool)) public following; // follower -> followed -> isFollowing

    mapping(uint256 => uint256) public listingLikes; // listingId -> likeCount

    mapping(uint256 => string[]) public listingComments; // listingId -> array of comments

    mapping(uint256 => CuratedCollection) public curatedCollections;
    Counters.Counter private _collectionIdCounter;

    mapping(address => uint256) public stakedTokenBalances; // user -> staked amount

    uint256 public totalPlatformFeesCollected;

    // Events
    event NFTListed(uint256 listingId, address nftContract, uint256 tokenId, address seller, uint256 price);
    event NFTDelisted(uint256 listingId);
    event NFTSold(uint256 listingId, address buyer, uint256 price);
    event BidPlaced(uint256 bidId, uint256 listingId, address bidder, uint256 bidAmount);
    event BidAccepted(uint256 bidId, uint256 listingId, address winner, uint256 price);
    event OfferMade(uint256 offerId, uint256 listingId, address offerer, uint256 offerPrice);
    event OfferCancelled(uint256 offerId);
    event OfferAccepted(uint256 offerId, uint256 listingId, address buyer, uint256 price);
    event NFTFractionalized(uint256 fractionalListingId, uint256 listingId, uint256 totalFractions);
    event FractionBought(uint256 fractionalListingId, address buyer, uint256 fractionAmount);
    event FractionSold(uint256 fractionalListingId, address seller, uint256 fractionAmount);
    event NFTRedeemed(uint256 fractionalListingId, address redeemer);
    event DynamicMetadataUpdated(uint256 listingId, string metadataURI);
    event UserProfileCreated(address userAddress, string username, string profileURI);
    event UserFollowed(address follower, address followed);
    event UserUnfollowed(address follower, address unfollowed);
    event ListingLiked(uint256 listingId, address user);
    event ListingCommented(uint256 listingId, address user, string comment);
    event CollectionCreated(uint256 collectionId, address creator, string collectionName);
    event NFTAddedToCollection(uint256 collectionId, uint256 listingId);
    event NFTRemovedFromCollection(uint256 collectionId, uint256 listingId);
    event TokensStaked(address user, uint256 amount);
    event TokensUnstaked(address user, uint256 amount);
    event PlatformFeeSet(uint256 feePercentage);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event PlatformFeesWithdrawn(uint256 amount, address admin);

    // Modifiers
    modifier onlyListingOwner(uint256 _listingId) {
        require(listings[_listingId].seller == _msgSender(), "Not listing owner");
        _;
    }

    modifier onlyFractionalListingOwner(uint256 _fractionalListingId) {
        require(fractionalListings[_fractionalListingId].listingId > 0 && listings[fractionalListings[_fractionalListingId].listingId].seller == _msgSender(), "Not fractional listing owner");
        _;
    }

    modifier onlyValidListing(uint256 _listingId) {
        require(listings[_listingId].listingId > 0 && listings[_listingId].isActive, "Invalid or inactive listing");
        _;
    }

    modifier onlyValidFractionalListing(uint256 _fractionalListingId) {
        require(fractionalListings[_fractionalListingId].fractionalListingId > 0 && fractionalListings[_fractionalListingId].isActive, "Invalid or inactive fractional listing");
        _;
    }

    modifier onlyExistingUserProfile() {
        require(userProfiles[_msgSender()].userAddress != address(0), "User profile does not exist");
        _;
    }

    modifier nonExistingUserProfile() {
        require(userProfiles[_msgSender()].userAddress == address(0), "User profile already exists");
        _;
    }

    modifier validCollectionId(uint256 _collectionId) {
        require(curatedCollections[_collectionId].collectionId > 0, "Invalid collection ID");
        _;
    }

    modifier onlyCollectionCreator(uint256 _collectionId) {
        require(curatedCollections[_collectionId].creator == _msgSender(), "Not collection creator");
        _;
    }

    constructor(address _platformTokenAddress) {
        platformToken = IERC20(_platformTokenAddress);
    }

    // 1. Core Marketplace Functionality

    /// @notice Lists an NFT for sale on the marketplace.
    /// @param _nftContract Address of the NFT contract.
    /// @param _tokenId Token ID of the NFT to list.
    /// @param _price Price in platform token for the NFT.
    /// @param _isFractionalizable Whether the NFT can be fractionalized.
    function listNFT(address _nftContract, uint256 _tokenId, uint256 _price, bool _isFractionalizable) external whenNotPaused {
        require(_price > 0, "Price must be greater than 0");
        // Ensure seller is owner or approved for all
        IERC721 nft = IERC721(_nftContract);
        require(nft.ownerOf(_tokenId) == _msgSender() || nft.getApproved(_tokenId) == _msgSender() || nft.isApprovedForAll(nft.ownerOf(_tokenId), _msgSender()), "Not NFT owner or approved");
        // Transfer NFT to marketplace contract (escrow)
        nft.safeTransferFrom(_msgSender(), address(this), _tokenId);

        _listingIdCounter.increment();
        uint256 listingId = _listingIdCounter.current();

        listings[listingId] = Listing({
            listingId: listingId,
            nftContract: _nftContract,
            tokenId: _tokenId,
            seller: _msgSender(),
            price: _price,
            isFractionalizable: _isFractionalizable,
            isFractionalized: false,
            isActive: true
        });

        emit NFTListed(listingId, _nftContract, _tokenId, _msgSender(), _price);
    }

    /// @notice Delists an NFT from the marketplace.
    /// @param _listingId ID of the listing to delist.
    function delistNFT(uint256 _listingId) external onlyListingOwner(_listingId) whenNotPaused onlyValidListing(_listingId) {
        require(!listings[_listingId].isFractionalized, "Cannot delist fractionalized NFT");
        listings[_listingId].isActive = false;
        IERC721(listings[_listingId].nftContract).safeTransferFrom(address(this), listings[_listingId].seller, listings[_listingId].tokenId);
        emit NFTDelisted(_listingId);
    }

    /// @notice Buys an NFT from the marketplace.
    /// @param _listingId ID of the listing to buy.
    function buyNFT(uint256 _listingId) external payable whenNotPaused onlyValidListing(_listingId) {
        Listing storage listing = listings[_listingId];
        uint256 platformFee = (listing.price * platformFeePercentage) / 10000;
        uint256 sellerProceeds = listing.price - platformFee;

        // Transfer platform fee to platform owner and seller proceeds to seller
        require(platformToken.transferFrom(_msgSender(), owner(), platformFee), "Platform token transfer failed for platform fee");
        require(platformToken.transferFrom(_msgSender(), listing.seller, sellerProceeds), "Platform token transfer failed for seller proceeds");

        totalPlatformFeesCollected += platformFee;

        listing.isActive = false; // Mark listing as sold
        emit NFTSold(_listingId, _msgSender(), listing.price);

        // Transfer NFT to buyer
        IERC721(listing.nftContract).safeTransferFrom(address(this), _msgSender(), listing.tokenId);
    }

    /// @notice Places a bid on a listed NFT.
    /// @param _listingId ID of the listing to bid on.
    /// @param _bidAmount Amount to bid in platform tokens.
    function placeBid(uint256 _listingId, uint256 _bidAmount) external whenNotPaused onlyValidListing(_listingId) {
        require(_bidAmount > 0, "Bid amount must be greater than 0");
        require(_bidAmount > listings[_listingId].price, "Bid must be higher than listing price"); // Example: Bid must be higher than current price
        _bidIdCounter.increment();
        uint256 bidId = _bidIdCounter.current();
        bids[bidId] = Bid({
            bidId: bidId,
            listingId: _listingId,
            bidder: _msgSender(),
            bidAmount: _bidAmount,
            isActive: true
        });
        emit BidPlaced(bidId, _listingId, _msgSender(), _bidAmount);
    }

    /// @notice Accepts a bid on a listed NFT.
    /// @param _listingId ID of the listing.
    /// @param _bidId ID of the bid to accept.
    function acceptBid(uint256 _listingId, uint256 _bidId) external onlyListingOwner(_listingId) whenNotPaused onlyValidListing(_listingId) {
        require(bids[_bidId].listingId == _listingId, "Bid not for this listing");
        require(bids[_bidId].isActive, "Bid is not active");

        Listing storage listing = listings[_listingId];
        Bid storage bid = bids[_bidId];

        uint256 platformFee = (bid.bidAmount * platformFeePercentage) / 10000;
        uint256 sellerProceeds = bid.bidAmount - platformFee;

        // Transfer platform fee to platform owner and seller proceeds to seller
        require(platformToken.transferFrom(bid.bidder, owner(), platformFee), "Platform token transfer failed for platform fee");
        require(platformToken.transferFrom(bid.bidder, listing.seller, sellerProceeds), "Platform token transfer failed for seller proceeds");

        totalPlatformFeesCollected += platformFee;

        listing.isActive = false; // Mark listing as sold
        bid.isActive = false; // Mark bid as accepted
        emit BidAccepted(_bidId, _listingId, bid.bidder, bid.bidAmount);
        emit NFTSold(_listingId, bid.bidder, bid.bidAmount);

        // Transfer NFT to bidder
        IERC721(listing.nftContract).safeTransferFrom(address(this), bid.bidder, listing.tokenId);

        // Refund other bidders (Implementation could be more sophisticated in a real scenario)
        // For simplicity, we are not tracking other bids for refunding in this example.
    }

    /// @notice Makes a direct offer on a listed NFT.
    /// @param _listingId ID of the listing to make an offer on.
    /// @param _offerPrice Price offered in platform tokens.
    function makeOffer(uint256 _listingId, uint256 _offerPrice) external whenNotPaused onlyValidListing(_listingId) {
        require(_offerPrice > 0, "Offer price must be greater than 0");
        require(_offerPrice < listings[_listingId].price, "Offer must be lower than listing price"); // Example: Offer must be lower than listing price
        _offerIdCounter.increment();
        uint256 offerId = _offerIdCounter.current();
        offers[offerId] = Offer({
            offerId: offerId,
            listingId: _listingId,
            offerer: _msgSender(),
            offerPrice: _offerPrice,
            isActive: true
        });
        emit OfferMade(offerId, _listingId, _msgSender(), _offerPrice);
    }

    /// @notice Cancels a pending offer.
    /// @param _offerId ID of the offer to cancel.
    function cancelOffer(uint256 _offerId) external whenNotPaused {
        require(offers[_offerId].offerer == _msgSender(), "Not offer owner");
        require(offers[_offerId].isActive, "Offer is not active");
        offers[_offerId].isActive = false;
        emit OfferCancelled(_offerId);
    }

    /// @notice Accepts a direct offer on a listed NFT.
    /// @param _offerId ID of the offer to accept.
    function acceptOffer(uint256 _offerId) external onlyListingOwner(offers[_offerId].listingId) whenNotPaused onlyValidListing(offers[_offerId].listingId) {
        require(offers[_offerId].isActive, "Offer is not active");
        Listing storage listing = listings[offers[_offerId].listingId];
        Offer storage offer = offers[_offerId];

        uint256 platformFee = (offer.offerPrice * platformFeePercentage) / 10000;
        uint256 sellerProceeds = offer.offerPrice - platformFee;

        // Transfer platform fee to platform owner and seller proceeds to seller
        require(platformToken.transferFrom(offer.offerer, owner(), platformFee), "Platform token transfer failed for platform fee");
        require(platformToken.transferFrom(offer.offerer, listing.seller, sellerProceeds), "Platform token transfer failed for seller proceeds");

        totalPlatformFeesCollected += platformFee;

        listing.isActive = false; // Mark listing as sold
        offer.isActive = false; // Mark offer as accepted
        emit OfferAccepted(_offerId, offers[_offerId].listingId, offer.offerer, offer.offerPrice);
        emit NFTSold(offers[_offerId].listingId, offer.offerer, offer.offerPrice);

        // Transfer NFT to offerer
        IERC721(listing.nftContract).safeTransferFrom(address(this), offer.offerer, listing.tokenId);
    }


    // 2. Fractional Ownership Features

    /// @notice Fractionalizes a listed NFT.
    /// @param _listingId ID of the listing to fractionalize.
    /// @param _numberOfFractions Number of fractions to create.
    function fractionalizeNFT(uint256 _listingId, uint256 _numberOfFractions) external onlyListingOwner(_listingId) whenNotPaused onlyValidListing(_listingId) {
        require(listings[_listingId].isFractionalizable, "NFT is not fractionalizable");
        require(_numberOfFractions > 1 && _numberOfFractions <= 10000, "Number of fractions must be between 2 and 10000"); // Example limit
        require(!listings[_listingId].isFractionalized, "NFT already fractionalized");

        _fractionalListingIdCounter.increment();
        uint256 fractionalListingId = _fractionalListingIdCounter.current();

        fractionalListings[fractionalListingId] = FractionalListing({
            fractionalListingId: fractionalListingId,
            listingId: _listingId,
            totalFractions: _numberOfFractions,
            fractionsSold: 0,
            isActive: true
        });
        listings[_listingId].isFractionalized = true; // Mark original listing as fractionalized
        emit NFTFractionalized(fractionalListingId, _listingId, _numberOfFractions);
    }

    /// @notice Buys fractions of a fractionalized NFT.
    /// @param _fractionalListingId ID of the fractional listing.
    /// @param _fractionAmount Number of fractions to buy.
    function buyFraction(uint256 _fractionalListingId, uint256 _fractionAmount) external payable whenNotPaused onlyValidFractionalListing(_fractionalListingId) {
        require(_fractionAmount > 0, "Fraction amount must be greater than 0");
        FractionalListing storage fractionalListing = fractionalListings[_fractionalListingId];
        Listing storage listing = listings[fractionalListing.listingId];

        uint256 availableFractions = fractionalListing.totalFractions - fractionalListing.fractionsSold;
        require(_fractionAmount <= availableFractions, "Not enough fractions available");

        uint256 fractionPrice = listing.price / fractionalListing.totalFractions; // Simple equal fraction price
        uint256 totalPrice = fractionPrice * _fractionAmount;

        uint256 platformFee = (totalPrice * platformFeePercentage) / 10000;
        uint256 sellerProceeds = totalPrice - platformFee;

        // Transfer platform fee to platform owner and seller proceeds to seller
        require(platformToken.transferFrom(_msgSender(), owner(), platformFee), "Platform token transfer failed for platform fee");
        require(platformToken.transferFrom(_msgSender(), listing.seller, sellerProceeds), "Platform token transfer failed for seller proceeds");

        totalPlatformFeesCollected += platformFee;

        fractionalListing.fractionBalances[_msgSender()] += _fractionAmount;
        fractionalListing.fractionsSold += _fractionAmount;

        emit FractionBought(_fractionalListingId, _msgSender(), _fractionAmount);

        if (fractionalListing.fractionsSold == fractionalListing.totalFractions) {
            fractionalListing.isActive = false; // Mark fractional listing as sold out
            listings[fractionalListing.listingId].isActive = false; // Deactivate original listing too
        }
    }

    /// @notice Sells fractions of a fractionalized NFT (Peer-to-peer fraction trading - advanced).
    /// @param _fractionalListingId ID of the fractional listing.
    /// @param _fractionAmount Number of fractions to sell.
    function sellFraction(uint256 _fractionalListingId, uint256 _fractionAmount) external whenNotPaused onlyValidFractionalListing(_fractionalListingId) {
        require(_fractionAmount > 0, "Fraction amount must be greater than 0");
        FractionalListing storage fractionalListing = fractionalListings[_fractionalListingId];
        require(fractionalListing.fractionBalances[_msgSender()] >= _fractionAmount, "Not enough fractions to sell");

        // In a real scenario, you'd implement a secondary market for fractions here.
        // This is a placeholder for a more complex fraction selling mechanism.
        // For now, let's just assume it's a burn/transfer back to contract for simplicity (not ideal for trading).

        fractionalListing.fractionBalances[_msgSender()] -= _fractionAmount;
        fractionalListing.fractionsSold -= _fractionAmount; // Assuming fractions are "burnt" or returned to pool.

        emit FractionSold(_fractionalListingId, _msgSender(), _fractionAmount);
    }

    /// @notice Redeems the original NFT after owning all fractions.
    /// @param _fractionalListingId ID of the fractional listing.
    function redeemNFT(uint256 _fractionalListingId) external whenNotPaused onlyValidFractionalListing(_fractionalListingId) {
        FractionalListing storage fractionalListing = fractionalListings[_fractionalListingId];
        Listing storage listing = listings[fractionalListing.listingId];
        require(fractionalListing.fractionBalances[_msgSender()] == fractionalListing.totalFractions, "Must own all fractions to redeem");
        require(fractionalListing.fractionsSold == fractionalListing.totalFractions, "Fractions not fully sold yet (internal error)"); // Extra check

        fractionalListing.isActive = false; // Mark fractional listing as redeemed
        listings[fractionalListing.listingId].isActive = false; // Deactivate original listing

        emit NFTRedeemed(_fractionalListingId, _msgSender());
        IERC721(listing.nftContract).safeTransferFrom(address(this), _msgSender(), listing.tokenId);
    }


    // 3. Dynamic NFT Features

    /// @notice Sets the base URI for dynamic NFT metadata (Admin function).
    /// @param _baseURI The new base URI for dynamic metadata.
    function setDynamicMetadataBaseURI(string memory _baseURI) external onlyOwner {
        dynamicMetadataBaseURI = _baseURI;
    }

    /// @notice Triggers a dynamic metadata update for a specific NFT listing (Example based on listing likes).
    /// @param _listingId ID of the listing to update metadata for.
    function triggerDynamicMetadataUpdate(uint256 _listingId) external whenNotPaused onlyValidListing(_listingId) {
        // Example dynamic metadata logic: Change metadata based on number of likes
        uint256 likeCount = listingLikes[_listingId];
        string memory newMetadataURI = string(abi.encodePacked(dynamicMetadataBaseURI, "/", _listingId.toString(), "-", likeCount.toString()));

        // In a real implementation, you would likely use off-chain services (IPFS, centralized storage, etc.)
        // and generate metadata JSON based on on-chain data and logic.
        // This example just constructs a URI string.

        emit DynamicMetadataUpdated(_listingId, newMetadataURI);
        // In a real dynamic NFT implementation, you might need to update tokenURI function
        // or use a proxy contract pattern to dynamically serve metadata.
    }

    /// @notice Returns the current metadata URI for a given NFT listing.
    /// @param _listingId ID of the listing.
    /// @return The current metadata URI.
    function getNFTMetadataURI(uint256 _listingId) external view returns (string memory) {
        // In a real implementation, this would fetch dynamic metadata based on listing state.
        // For this example, we simply return a placeholder or base URI.
        return string(abi.encodePacked(dynamicMetadataBaseURI, "/", _listingId.toString()));
    }


    // 4. Social Features

    /// @notice Creates a user profile on the marketplace.
    /// @param _username Username for the profile.
    /// @param _profileURI URI pointing to the profile data (e.g., IPFS link).
    function createUserProfile(string memory _username, string memory _profileURI) external whenNotPaused nonExistingUserProfile {
        userProfiles[_msgSender()] = UserProfile({
            userAddress: _msgSender(),
            username: _username,
            profileURI: _profileURI,
            reputationPoints: 0 // Initial reputation
        });
        emit UserProfileCreated(_msgSender(), _username, _profileURI);
    }

    /// @notice Allows a user to follow another user.
    /// @param _userToFollow Address of the user to follow.
    function followUser(address _userToFollow) external whenNotPaused onlyExistingUserProfile {
        require(_userToFollow != _msgSender(), "Cannot follow yourself");
        require(userProfiles[_userToFollow].userAddress != address(0), "User to follow does not exist");
        require(!following[_msgSender()][_userToFollow], "Already following this user");
        following[_msgSender()][_userToFollow] = true;
        emit UserFollowed(_msgSender(), _userToFollow);
    }

    /// @notice Allows a user to unfollow another user.
    /// @param _userToUnfollow Address of the user to unfollow.
    function unfollowUser(address _userToUnfollow) external whenNotPaused onlyExistingUserProfile {
        require(following[_msgSender()][_userToUnfollow], "Not following this user");
        following[_msgSender()][_userToUnfollow] = false;
        emit UserUnfollowed(_msgSender(), _userToUnfollow);
    }

    /// @notice Allows a user to like an NFT listing.
    /// @param _listingId ID of the listing to like.
    function likeListing(uint256 _listingId) external whenNotPaused onlyValidListing(_listingId) onlyExistingUserProfile {
        listingLikes[_listingId]++;
        emit ListingLiked(_listingId, _msgSender());
        // Optionally increase reputation of listing owner here
        // userProfiles[listings[_listingId].seller].reputationPoints++;
    }

    /// @notice Allows a user to comment on an NFT listing.
    /// @param _listingId ID of the listing to comment on.
    /// @param _comment Comment text.
    function commentOnListing(uint256 _listingId, string memory _comment) external whenNotPaused onlyValidListing(_listingId) onlyExistingUserProfile {
        listingComments[_listingId].push(_comment);
        emit ListingCommented(_listingId, _msgSender(), _comment);
        // Optionally increase reputation of commenter and/or listing owner
        // userProfiles[_msgSender()].reputationPoints++;
        // userProfiles[listings[_listingId].seller].reputationPoints++;
    }

    /// @notice Creates a curated NFT collection.
    /// @param _collectionName Name of the collection.
    /// @param _collectionDescription Description of the collection.
    function createCuratedCollection(string memory _collectionName, string memory _collectionDescription) external whenNotPaused onlyExistingUserProfile {
        _collectionIdCounter.increment();
        uint256 collectionId = _collectionIdCounter.current();
        curatedCollections[collectionId] = CuratedCollection({
            collectionId: collectionId,
            creator: _msgSender(),
            collectionName: _collectionName,
            collectionDescription: _collectionDescription,
            listingIds: new uint256[](0) // Initialize with empty listing array
        });
        emit CollectionCreated(collectionId, _msgSender(), _collectionName);
    }

    /// @notice Adds an NFT listing to a curated collection.
    /// @param _collectionId ID of the collection to add to.
    /// @param _listingId ID of the listing to add.
    function addNFTToCollection(uint256 _collectionId, uint256 _listingId) external whenNotPaused validCollectionId(_collectionId) onlyCollectionCreator(_collectionId) onlyValidListing(_listingId) {
        bool alreadyInCollection = false;
        for (uint256 i = 0; i < curatedCollections[_collectionId].listingIds.length; i++) {
            if (curatedCollections[_collectionId].listingIds[i] == _listingId) {
                alreadyInCollection = true;
                break;
            }
        }
        require(!alreadyInCollection, "NFT already in collection");
        curatedCollections[_collectionId].listingIds.push(_listingId);
        emit NFTAddedToCollection(_collectionId, _listingId);
    }

    /// @notice Removes an NFT listing from a curated collection.
    /// @param _collectionId ID of the collection to remove from.
    /// @param _listingId ID of the listing to remove.
    function removeNFTFromCollection(uint256 _collectionId, uint256 _listingId) external whenNotPaused validCollectionId(_collectionId) onlyCollectionCreator(_collectionId) {
        uint256[] storage listingIds = curatedCollections[_collectionId].listingIds;
        bool found = false;
        uint256 indexToRemove;
        for (uint256 i = 0; i < listingIds.length; i++) {
            if (listingIds[i] == _listingId) {
                found = true;
                indexToRemove = i;
                break;
            }
        }
        require(found, "NFT not in collection");

        // Remove element by swapping with the last element and popping
        listingIds[indexToRemove] = listingIds[listingIds.length - 1];
        listingIds.pop();
        emit NFTRemovedFromCollection(_collectionId, _listingId);
    }


    // 5. Reputation and Platform Features

    /// @notice Allows users to stake platform tokens for enhanced features (Example - placeholder).
    /// @param _amount Amount of platform tokens to stake.
    function stakePlatformToken(uint256 _amount) external whenNotPaused onlyExistingUserProfile {
        require(_amount > 0, "Stake amount must be greater than 0");
        require(platformToken.transferFrom(_msgSender(), address(this), _amount), "Platform token transfer failed for staking");
        stakedTokenBalances[_msgSender()] += _amount;
        emit TokensStaked(_msgSender(), _amount);
        // In a real implementation, staking could unlock premium features, reduced fees, governance rights, etc.
    }

    /// @notice Allows users to unstake platform tokens (Example - placeholder).
    /// @param _amount Amount of platform tokens to unstake.
    function unstakePlatformToken(uint256 _amount) external whenNotPaused onlyExistingUserProfile {
        require(_amount > 0, "Unstake amount must be greater than 0");
        require(stakedTokenBalances[_msgSender()] >= _amount, "Insufficient staked balance");
        require(platformToken.transfer( _msgSender(), _amount), "Platform token transfer failed for unstaking");
        stakedTokenBalances[_msgSender()] -= _amount;
        emit TokensUnstaked(_msgSender(), _amount);
    }

    /// @notice Sets the platform fee percentage (Admin function).
    /// @param _feePercentage New platform fee percentage (e.g., 200 for 2%).
    function setPlatformFee(uint256 _feePercentage) external onlyOwner {
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    /// @notice Pauses the marketplace, preventing core trading functions (Admin function).
    function pauseMarketplace() external onlyOwner {
        _pause();
        emit MarketplacePaused();
    }

    /// @notice Unpauses the marketplace, re-enabling core trading functions (Admin function).
    function unpauseMarketplace() external onlyOwner {
        _unpause();
        emit MarketplaceUnpaused();
    }

    /// @notice Allows the platform owner to withdraw accumulated platform fees (Admin function).
    function withdrawPlatformFees() external onlyOwner {
        uint256 amountToWithdraw = totalPlatformFeesCollected;
        totalPlatformFeesCollected = 0; // Reset collected fees
        require(platformToken.transfer(owner(), amountToWithdraw), "Platform fee withdrawal failed");
        emit PlatformFeesWithdrawn(amountToWithdraw, owner());
    }

    // Fallback function to receive platform tokens directly
    receive() external payable {}
}
```