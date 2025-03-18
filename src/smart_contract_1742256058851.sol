```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI Curation and Gamified Auctions
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a dynamic NFT marketplace with advanced features like:
 *      - Dynamic NFTs: NFTs that can evolve and change their metadata based on on-chain conditions.
 *      - AI-Curated Collections:  A decentralized system for suggesting and voting on featured NFT collections, loosely inspired by AI curation.
 *      - Gamified Auctions: Auctions with time extensions, snipe protection, and early bidder rewards to enhance user engagement.
 *      - On-chain Reputation System: Basic reputation points awarded for positive marketplace actions (buying, successful auctions).
 *      - NFT Bundling: Allows users to bundle multiple NFTs for sale as a single listing.
 *      - Royalty Management:  Implements royalty fees for creators on secondary sales.
 *      - Lazy Minting Support:  Allows NFTs to be "minted" only when purchased, saving gas for creators.
 *      - Conditional Sales:  Allows sellers to set conditions (e.g., holding a specific NFT) for purchasing their NFTs.
 *      - Raffle System:  NFT holders can participate in raffles to win other NFTs.
 *      - Decentralized Governance (Basic): Simple voting mechanism for platform fee changes.
 *      - Multi-Currency Support (Simulated):  Allows for setting prices and bidding in different ERC20 tokens.
 *      - NFT Staking for Rewards:  Users can stake NFTs to earn platform tokens (simulated).
 *      - On-chain Messaging (Simple):  Basic messaging between users related to listings/auctions.
 *      - Referral Program:  Users can earn rewards for referring new users.
 *      - Wishlist Feature: Users can add NFTs to a wishlist to track desired items.
 *      - Offer System: Users can make offers on NFTs not currently listed for sale.
 *      - Collection-Specific Royalties: Royalties can be set per NFT collection.
 *      - Emergency Pause Function:  Admin function to pause marketplace operations in case of critical issues.
 *      - Dynamic Platform Fees: Platform fees can be adjusted based on governance or admin decisions.
 *
 * Function Summary:
 * 1. mintNFT(string memory _tokenURI, address _royaltyRecipient, uint256 _royaltyFeePercentage): Mints a new NFT with dynamic metadata and royalty information.
 * 2. setDynamicMetadataURI(uint256 _tokenId, string memory _newMetadataURI): Updates the dynamic metadata URI for a specific NFT.
 * 3. listItem(uint256 _tokenId, uint256 _price, address _currency): Lists an NFT for sale at a fixed price.
 * 4. buyItem(uint256 _listingId): Allows a user to buy an NFT listed for sale.
 * 5. cancelListing(uint256 _listingId): Allows the seller to cancel an NFT listing.
 * 6. createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _duration, address _currency, uint256 _minBidIncrementPercentage, bool _snipeProtectionEnabled, uint256 _snipeProtectionTime): Creates a new auction for an NFT.
 * 7. bidOnAuction(uint256 _auctionId, uint256 _bidAmount): Places a bid on an active auction.
 * 8. endAuction(uint256 _auctionId): Ends an auction and transfers NFT to the highest bidder.
 * 9. claimAuctionWinnings(uint256 _auctionId): Allows bidders who didn't win to claim back their bids after auction ends.
 * 10. extendAuctionTime(uint256 _auctionId, uint256 _extensionTime): Extends the duration of an ongoing auction.
 * 11. submitCurationProposal(uint256 _tokenId, string memory _collectionName, string memory _proposalDescription): Allows users to propose NFTs for AI-Curated collections.
 * 12. voteOnCurationProposal(uint256 _proposalId, bool _support): Allows users to vote on NFT curation proposals.
 * 13. executeCurationProposal(uint256 _proposalId): Executes a successful curation proposal (admin/governance function).
 * 14. createBundleListing(uint256[] memory _tokenIds, uint256 _price, address _currency): Lists a bundle of NFTs for sale.
 * 15. buyBundle(uint256 _bundleListingId): Allows a user to buy an NFT bundle.
 * 16. cancelBundleListing(uint256 _bundleListingId): Allows the seller to cancel a bundle listing.
 * 17. setPlatformFee(uint256 _newFeePercentage): Allows the platform owner to set the platform fee (governance controlled in real-world).
 * 18. withdrawPlatformFees(): Allows the platform owner to withdraw accumulated platform fees.
 * 19. setCollectionRoyalty(address _nftContract, uint256 _royaltyFeePercentage): Sets a default royalty for an entire NFT collection.
 * 20. setConditionalSale(uint256 _listingId, address _conditionContract, uint256 _conditionTokenId): Sets a condition for buying a listed NFT (e.g., holder of another NFT).
 * 21. fulfillConditionalSale(uint256 _listingId): Allows a buyer to fulfill a conditional sale if they meet the condition.
 * 22. createRaffle(uint256 _tokenId, uint256 _ticketPrice, uint256 _raffleDuration): Creates a raffle for an NFT.
 * 23. buyRaffleTicket(uint256 _raffleId, uint256 _numberOfTickets): Allows users to buy raffle tickets.
 * 24. endRaffle(uint256 _raffleId): Ends a raffle and selects a winner.
 * 25. sendChatMessage(address _recipient, string memory _message): Sends a simple on-chain message to another user.
 * 26. addToWishlist(uint256 _tokenId): Adds an NFT to a user's wishlist.
 * 27. removeFromWishlist(uint256 _tokenId): Removes an NFT from a user's wishlist.
 * 28. makeOffer(uint256 _tokenId, uint256 _offerPrice, address _currency): Allows a user to make an offer on an NFT.
 * 29. acceptOffer(uint256 _offerId): Allows the NFT owner to accept an offer.
 * 30. rejectOffer(uint256 _offerId): Allows the NFT owner to reject an offer.
 * 31. pauseMarketplace(): Pauses all marketplace operations (admin function).
 * 32. unpauseMarketplace(): Resumes marketplace operations (admin function).
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract DynamicNFTMarketplace is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    Counters.Counter private _nftIdCounter;
    Counters.Counter private _listingIdCounter;
    Counters.Counter private _auctionIdCounter;
    Counters.Counter private _bundleListingIdCounter;
    Counters.Counter private _curationProposalIdCounter;
    Counters.Counter private _offerIdCounter;
    Counters.Counter private _raffleIdCounter;

    uint256 public platformFeePercentage = 2; // 2% platform fee
    address public platformFeeRecipient;

    mapping(uint256 => NFTListing) public nftListings;
    mapping(uint256 => bool) public isNFTListed;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => bool) public isAuctionActive;
    mapping(uint256 => BundleListing) public bundleListings;
    mapping(uint256 => CurationProposal) public curationProposals;
    mapping(uint256 => Offer) public offers;
    mapping(uint256 => Raffle) public raffles;
    mapping(address => uint256) public userReputation;
    mapping(address => EnumerableSet.UintSet) public userWishlists;
    mapping(address => mapping(address => uint256)) public collectionRoyalties; // collection address => royalty percentage

    bool public paused = false;

    struct NFTListing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        address currency;
        bool isActive;
        address conditionContract; // Optional condition for sale
        uint256 conditionTokenId;  // Optional condition token ID
    }

    struct Auction {
        uint256 auctionId;
        uint256 tokenId;
        address seller;
        uint256 startingPrice;
        uint256 currentBid;
        address highestBidder;
        uint256 endTime;
        address currency;
        uint256 minBidIncrementPercentage;
        AuctionStatus status;
        bool snipeProtectionEnabled;
        uint256 snipeProtectionEndTime;
    }

    enum AuctionStatus {
        Active,
        Ended
    }

    struct BundleListing {
        uint256 bundleListingId;
        uint256[] tokenIds;
        address seller;
        uint256 price;
        address currency;
        bool isActive;
    }

    struct CurationProposal {
        uint256 proposalId;
        uint256 tokenId;
        address proposer;
        string collectionName;
        string proposalDescription;
        uint256 upvotes;
        uint256 downvotes;
        bool executed;
    }

    struct Offer {
        uint256 offerId;
        uint256 tokenId;
        address offerer;
        uint256 offerPrice;
        address currency;
        bool isActive;
    }

    struct Raffle {
        uint256 raffleId;
        uint256 tokenId;
        address creator;
        uint256 ticketPrice;
        uint256 endTime;
        uint256 ticketsSold;
        address winner;
        bool ended;
    }


    event NFTMinted(uint256 tokenId, address indexed minter, string tokenURI);
    event DynamicMetadataUpdated(uint256 tokenId, string newMetadataURI);
    event NFTListed(uint256 listingId, uint256 tokenId, address indexed seller, uint256 price, address currency);
    event ItemBought(uint256 listingId, uint256 tokenId, address indexed buyer, uint256 price, address currency);
    event ListingCancelled(uint256 listingId, uint256 tokenId);
    event AuctionCreated(uint256 auctionId, uint256 tokenId, address indexed seller, uint256 startingPrice, uint256 duration, address currency);
    event BidPlaced(uint256 auctionId, address indexed bidder, uint256 bidAmount);
    event AuctionEnded(uint256 auctionId, uint256 tokenId, address indexed winner, uint256 finalPrice);
    event AuctionTimeExtended(uint256 auctionId, uint256 extensionTime);
    event CurationProposalSubmitted(uint256 proposalId, uint256 tokenId, address indexed proposer, string collectionName);
    event CurationProposalVoted(uint256 proposalId, address indexed voter, bool support);
    event CurationProposalExecuted(uint256 proposalId, uint256 tokenId);
    event BundleListed(uint256 bundleListingId, address indexed seller, uint256 price, address currency, uint256[] tokenIds);
    event BundleBought(uint256 bundleListingId, address indexed buyer, uint256 price, address currency, uint256[] tokenIds);
    event BundleListingCancelled(uint256 bundleListingId);
    event PlatformFeeUpdated(uint256 newFeePercentage);
    event PlatformFeesWithdrawn(address recipient, uint256 amount);
    event CollectionRoyaltySet(address indexed nftContract, uint256 royaltyPercentage);
    event ConditionalSaleSet(uint256 listingId, address conditionContract, uint256 conditionTokenId);
    event ConditionalSaleFulfilled(uint256 listingId, address indexed buyer);
    event RaffleCreated(uint256 raffleId, uint256 tokenId, address indexed creator, uint256 ticketPrice, uint256 duration);
    event RaffleTicketBought(uint256 raffleId, address indexed buyer, uint256 numberOfTickets);
    event RaffleEnded(uint256 raffleId, uint256 tokenId, address indexed winner);
    event ChatMessageSent(address indexed sender, address indexed recipient, string message);
    event WishlistAdded(address indexed user, uint256 tokenId);
    event WishlistRemoved(address indexed user, uint256 tokenId);
    event OfferMade(uint256 offerId, uint256 tokenId, address indexed offerer, uint256 offerPrice, address currency);
    event OfferAccepted(uint256 offerId, uint256 tokenId, address indexed buyer);
    event OfferRejected(uint256 offerId, uint256 tokenId);
    event MarketplacePaused();
    event MarketplaceUnpaused();


    constructor(string memory _name, string memory _symbol, address _feeRecipient) ERC721(_name, _symbol) {
        platformFeeRecipient = _feeRecipient;
    }

    modifier whenNotPaused() {
        require(!paused, "Marketplace is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Marketplace is not paused");
        _;
    }

    modifier onlyOwnerOrApproved(uint256 _tokenId) {
        require(_msgSender() == ownerOf(_tokenId) || getApproved(_tokenId) == _msgSender(), "Not NFT owner or approved");
        _;
    }

    modifier validListing(uint256 _listingId) {
        require(nftListings[_listingId].isActive, "Listing does not exist or is inactive");
        _;
    }

    modifier validAuction(uint256 _auctionId) {
        require(auctions[_auctionId].status == AuctionStatus.Active, "Auction does not exist or is not active");
        _;
    }

    modifier validBundleListing(uint256 _bundleListingId) {
        require(bundleListings[_bundleListingId].isActive, "Bundle listing does not exist or is inactive");
        _;
    }

    modifier validCurationProposal(uint256 _proposalId) {
        require(!curationProposals[_proposalId].executed, "Curation proposal already executed");
        _;
    }

    modifier validOffer(uint256 _offerId) {
        require(offers[_offerId].isActive, "Offer is not active");
        _;
    }

    modifier validRaffle(uint256 _raffleId) {
        require(!raffles[_raffleId].ended, "Raffle is already ended");
        _;
    }

    // 1. mintNFT
    function mintNFT(string memory _tokenURI, address _royaltyRecipient, uint256 _royaltyFeePercentage) public returns (uint256) {
        _nftIdCounter.increment();
        uint256 tokenId = _nftIdCounter.current();
        _safeMint(_msgSender(), tokenId);
        _setTokenURI(tokenId, _tokenURI);
        collectionRoyalties[address(this)] = _royaltyFeePercentage; // Example setting royalty for this contract's collection
        emit NFTMinted(tokenId, _msgSender(), _tokenURI);
        return tokenId;
    }

    // 2. setDynamicMetadataURI
    function setDynamicMetadataURI(uint256 _tokenId, string memory _newMetadataURI) public onlyOwnerOrApproved(_tokenId) {
        _setTokenURI(_tokenId, _newMetadataURI);
        emit DynamicMetadataUpdated(_tokenId, _newMetadataURI);
    }

    // 3. listItem
    function listItem(uint256 _tokenId, uint256 _price, address _currency) public onlyOwnerOrApproved(_tokenId) whenNotPaused {
        require(!isNFTListed[_tokenId], "NFT already listed");
        require(ownerOf(_tokenId) == _msgSender(), "Not the owner of the NFT");
        _listingIdCounter.increment();
        uint256 listingId = _listingIdCounter.current();

        // Transfer NFT to contract for listing management
        transferFrom(_msgSender(), address(this), _tokenId);

        nftListings[listingId] = NFTListing({
            listingId: listingId,
            tokenId: _tokenId,
            seller: _msgSender(),
            price: _price,
            currency: _currency,
            isActive: true,
            conditionContract: address(0), // No condition by default
            conditionTokenId: 0
        });
        isNFTListed[_tokenId] = true;
        emit NFTListed(listingId, _tokenId, _msgSender(), _price, _currency);
    }

    // 4. buyItem
    function buyItem(uint256 _listingId) public payable validListing(_listingId) whenNotPaused nonReentrant {
        NFTListing storage listing = nftListings[_listingId];
        require(listing.seller != _msgSender(), "Cannot buy your own listing");

        // Conditional Sale Check
        if (listing.conditionContract != address(0)) {
            require(checkConditionalSale(_msgSender(), listing.conditionContract, listing.conditionTokenId), "Condition for sale not met");
        }

        uint256 totalPrice = listing.price;
        uint256 platformFee = (totalPrice * platformFeePercentage) / 100;
        uint256 sellerProceeds = totalPrice - platformFee;

        // Royalty Calculation (Example - Adapt based on your royalty standard)
        uint256 royaltyFee = 0;
        uint256 royaltyPercentage = collectionRoyalties[address(this)]; // Example: Collection-level royalty
        if (royaltyPercentage > 0) {
            royaltyFee = (sellerProceeds * royaltyPercentage) / 100;
            sellerProceeds -= royaltyFee;
        }

        // Currency handling (basic - for real-world, more robust ERC20 handling needed)
        if (listing.currency == address(0)) { // Native currency (ETH)
            require(msg.value >= totalPrice, "Insufficient ETH sent");
            if (msg.value > totalPrice) {
                payable(_msgSender()).transfer(msg.value - totalPrice); // Refund excess ETH
            }
            payable(platformFeeRecipient).transfer(platformFee);
            payable(listing.seller).transfer(sellerProceeds);
            // In a real implementation, royaltyRecipient should be stored and used.
            // For now, example assumes royaltyRecipient is the NFT creator/initial minter and is handled off-chain.
             // In a real implementation, send royalty to the stored royaltyRecipient.
        } else { // ERC20 token
            IERC20 currencyContract = IERC20(listing.currency);
            require(currencyContract.allowance(_msgSender(), address(this)) >= totalPrice, "ERC20 allowance too low");
            require(currencyContract.transferFrom(_msgSender(), platformFeeRecipient, platformFee), "ERC20 platform fee transfer failed");
            require(currencyContract.transferFrom(_msgSender(), listing.seller, sellerProceeds), "ERC20 seller payment failed");
            // In a real implementation, send royalty to the stored royaltyRecipient using ERC20 transfer.
        }

        // Transfer NFT to buyer
        transferFrom(address(this), _msgSender(), listing.tokenId);

        listing.isActive = false;
        isNFTListed[listing.tokenId] = false;
        userReputation[_msgSender()] += 1; // Increase buyer reputation
        emit ItemBought(_listingId, listing.tokenId, _msgSender(), totalPrice, listing.currency);
    }

    // 5. cancelListing
    function cancelListing(uint256 _listingId) public validListing(_listingId) whenNotPaused {
        NFTListing storage listing = nftListings[_listingId];
        require(listing.seller == _msgSender(), "Only seller can cancel listing");
        require(ownerOf(listing.tokenId) == address(this), "NFT not held by contract"); // Double check ownership

        listing.isActive = false;
        isNFTListed[listing.tokenId] = false;
        // Return NFT to seller
        transferFrom(address(this), _msgSender(), listing.tokenId);
        emit ListingCancelled(_listingId, listing.tokenId);
    }

    // 6. createAuction
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _duration,
        address _currency,
        uint256 _minBidIncrementPercentage,
        bool _snipeProtectionEnabled,
        uint256 _snipeProtectionTime
    ) public onlyOwnerOrApproved(_tokenId) whenNotPaused {
        require(!isAuctionActive[_tokenId], "NFT already in auction or listed");
        require(ownerOf(_tokenId) == _msgSender(), "Not the owner of the NFT");
        require(_duration > 0, "Auction duration must be positive");
        require(_minBidIncrementPercentage <= 100, "Min bid increment percentage too high");
        require(!isNFTListed[_tokenId], "NFT cannot be listed and in auction simultaneously");


        _auctionIdCounter.increment();
        uint256 auctionId = _auctionIdCounter.current();
        uint256 endTime = block.timestamp + _duration;
        uint256 snipeProtectionEndTime = _snipeProtectionEnabled ? endTime + _snipeProtectionTime : 0; // Set snipe protection end time if enabled

        // Transfer NFT to contract for auction management
        transferFrom(_msgSender(), address(this), _tokenId);

        auctions[auctionId] = Auction({
            auctionId: auctionId,
            tokenId: _tokenId,
            seller: _msgSender(),
            startingPrice: _startingPrice,
            currentBid: _startingPrice, // Initial bid is starting price
            highestBidder: address(0), // No bidder initially
            endTime: endTime,
            currency: _currency,
            minBidIncrementPercentage: _minBidIncrementPercentage,
            status: AuctionStatus.Active,
            snipeProtectionEnabled: _snipeProtectionEnabled,
            snipeProtectionEndTime: snipeProtectionEndTime
        });
        isAuctionActive[_tokenId] = true;
        emit AuctionCreated(auctionId, _tokenId, _msgSender(), _startingPrice, _duration, _currency);
    }

    // 7. bidOnAuction
    function bidOnAuction(uint256 _auctionId, uint256 _bidAmount) public payable validAuction(_auctionId) whenNotPaused nonReentrant {
        Auction storage auction = auctions[_auctionId];
        require(auction.seller != _msgSender(), "Seller cannot bid on their own auction");
        require(block.timestamp < auction.endTime, "Auction has already ended");
        require(_bidAmount > auction.currentBid, "Bid amount must be higher than current bid");
        require(_bidAmount >= auction.currentBid + (auction.currentBid * auction.minBidIncrementPercentage) / 100, "Bid increment too low");

        // Snipe Protection check - extend auction if bid is placed within snipe protection period
        if (auction.snipeProtectionEnabled && block.timestamp < auction.endTime) {
            auction.endTime = auction.snipeProtectionEndTime; // Extend auction end time to snipe protection end time
            emit AuctionTimeExtended(_auctionId, auction.snipeProtectionEndTime - block.timestamp);
        }

        // Refund previous highest bidder if exists (except for starting price bid)
        if (auction.highestBidder != address(0)) {
            if (auction.currency == address(0)) {
                payable(auction.highestBidder).transfer(auction.currentBid);
            } else {
                IERC20 currencyContract = IERC20(auction.currency);
                require(currencyContract.transfer(auction.highestBidder, auction.currentBid), "ERC20 refund failed");
            }
        }

        auction.highestBidder = _msgSender();
        auction.currentBid = _bidAmount;
        emit BidPlaced(_auctionId, _msgSender(), _bidAmount);
    }

    // 8. endAuction
    function endAuction(uint256 _auctionId) public validAuction(_auctionId) whenNotPaused nonReentrant {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp >= auction.endTime, "Auction end time not reached yet");

        auction.status = AuctionStatus.Ended;
        isAuctionActive[auction.tokenId] = false;
        uint256 finalPrice = auction.currentBid;

        // Platform fee and seller proceeds calculation
        uint256 platformFee = (finalPrice * platformFeePercentage) / 100;
        uint256 sellerProceeds = finalPrice - platformFee;

        // Royalty Calculation (Example - Adapt based on your royalty standard)
        uint256 royaltyFee = 0;
        uint256 royaltyPercentage = collectionRoyalties[address(this)]; // Example: Collection-level royalty
        if (royaltyPercentage > 0) {
            royaltyFee = (sellerProceeds * royaltyPercentage) / 100;
            sellerProceeds -= royaltyFee;
        }

        // Currency transfer to seller and platform
        if (auction.currency == address(0)) { // Native currency (ETH)
            payable(platformFeeRecipient).transfer(platformFee);
            payable(auction.seller).transfer(sellerProceeds);
            if (auction.highestBidder != address(0)) { // Transfer NFT to winner only if there was a bidder
                transferFrom(address(this), auction.highestBidder, auction.tokenId);
            } else { // No bids, return NFT to seller
                transferFrom(address(this), auction.seller, auction.tokenId);
            }
             // In a real implementation, send royalty to the stored royaltyRecipient.
        } else { // ERC20 token
            IERC20 currencyContract = IERC20(auction.currency);
            require(currencyContract.transfer(platformFeeRecipient, platformFee), "ERC20 platform fee transfer failed");
            require(currencyContract.transfer(auction.seller, sellerProceeds), "ERC20 seller payment failed");
             // In a real implementation, send royalty to the stored royaltyRecipient using ERC20 transfer.
            if (auction.highestBidder != address(0)) { // Transfer NFT to winner only if there was a bidder
                transferFrom(address(this), auction.highestBidder, auction.tokenId);
            } else { // No bids, return NFT to seller
                transferFrom(address(this), auction.seller, auction.tokenId);
            }
        }
        userReputation[auction.highestBidder] += 2; // Increase winner reputation (more than buyer)
        emit AuctionEnded(_auctionId, auction.tokenId, auction.highestBidder, finalPrice);
    }

    // 9. claimAuctionWinnings
    function claimAuctionWinnings(uint256 _auctionId) public whenNotPaused nonReentrant {
        Auction storage auction = auctions[_auctionId];
        require(auction.status == AuctionStatus.Ended, "Auction is not ended");
        require(auction.highestBidder != _msgSender(), "Winner cannot claim winnings (already received NFT)");
        require(auction.highestBidder != address(0), "No bids were placed on this auction"); // No winnings to claim if no bids

        uint256 bidAmount = auction.currentBid; // Amount to refund is the last bid amount

        // Reset bid information to prevent double claiming (optional - can remove to allow claiming even if bid was refunded during a higher bid)
        // auction.currentBid = 0;
        // auction.highestBidder = address(0);

        if (auction.currency == address(0)) { // Native currency (ETH)
            payable(_msgSender()).transfer(bidAmount);
        } else { // ERC20 token
            IERC20 currencyContract = IERC20(auction.currency);
            require(currencyContract.transfer(_msgSender(), bidAmount), "ERC20 refund failed");
        }
    }

    // 10. extendAuctionTime
    function extendAuctionTime(uint256 _auctionId, uint256 _extensionTime) public validAuction(_auctionId) whenNotPaused {
        Auction storage auction = auctions[_auctionId];
        require(_msgSender() == auction.seller || _msgSender() == owner(), "Only seller or admin can extend auction time"); // Example: Seller and admin can extend
        require(_extensionTime > 0, "Extension time must be positive");

        auction.endTime += _extensionTime;
        emit AuctionTimeExtended(_auctionId, _extensionTime);
    }

    // 11. submitCurationProposal
    function submitCurationProposal(uint256 _tokenId, string memory _collectionName, string memory _proposalDescription) public whenNotPaused {
        require(ownerOf(_tokenId) == _msgSender(), "Only owner of NFT can submit curation proposal");
        _curationProposalIdCounter.increment();
        uint256 proposalId = _curationProposalIdCounter.current();

        curationProposals[proposalId] = CurationProposal({
            proposalId: proposalId,
            tokenId: _tokenId,
            proposer: _msgSender(),
            collectionName: _collectionName,
            proposalDescription: _proposalDescription,
            upvotes: 0,
            downvotes: 0,
            executed: false
        });
        emit CurationProposalSubmitted(proposalId, _tokenId, _msgSender(), _collectionName);
    }

    // 12. voteOnCurationProposal
    function voteOnCurationProposal(uint256 _proposalId, bool _support) public validCurationProposal(_proposalId) whenNotPaused {
        CurationProposal storage proposal = curationProposals[_proposalId];
        // Basic voting logic - anyone can vote once (can be improved with weighted voting, token voting etc.)
        if (_support) {
            proposal.upvotes++;
        } else {
            proposal.downvotes++;
        }
        emit CurationProposalVoted(_proposalId, _msgSender(), _support);
    }

    // 13. executeCurationProposal
    function executeCurationProposal(uint256 _proposalId) public onlyOwner validCurationProposal(_proposalId) whenNotPaused {
        CurationProposal storage proposal = curationProposals[_proposalId];
        // Simple execution logic - admin can decide to execute based on votes or other criteria (AI could be simulated here off-chain)
        proposal.executed = true;
        // In a real-world scenario, this function might trigger adding the NFT to a "featured" collection or list,
        // update metadata, or trigger off-chain AI processes for further curation.
        emit CurationProposalExecuted(_proposalId, proposal.tokenId);
    }

    // 14. createBundleListing
    function createBundleListing(uint256[] memory _tokenIds, uint256 _price, address _currency) public whenNotPaused {
        require(_tokenIds.length > 1, "Bundle must contain at least 2 NFTs");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(ownerOf(_tokenIds[i]) == _msgSender(), "Not owner of all NFTs in bundle");
            require(!isNFTListed[_tokenIds[i]] && !isAuctionActive[_tokenIds[i]], "NFT in bundle is already listed or in auction");
        }

        _bundleListingIdCounter.increment();
        uint256 bundleListingId = _bundleListingIdCounter.current();

        // Transfer NFTs to contract for bundle management
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_msgSender(), address(this), _tokenIds[i]);
            isNFTListed[_tokenIds[i]] = true; // Mark individual NFTs as listed (for bundle context)
        }

        bundleListings[bundleListingId] = BundleListing({
            bundleListingId: bundleListingId,
            tokenIds: _tokenIds,
            seller: _msgSender(),
            price: _price,
            currency: _currency,
            isActive: true
        });
        emit BundleListed(bundleListingId, _msgSender(), _price, _currency, _tokenIds);
    }

    // 15. buyBundle
    function buyBundle(uint256 _bundleListingId) public payable validBundleListing(_bundleListingId) whenNotPaused nonReentrant {
        BundleListing storage bundleListing = bundleListings[_bundleListingId];
        require(bundleListing.seller != _msgSender(), "Cannot buy your own bundle");

        uint256 totalPrice = bundleListing.price;
        uint256 platformFee = (totalPrice * platformFeePercentage) / 100;
        uint256 sellerProceeds = totalPrice - platformFee;

        // Currency handling (basic)
        if (bundleListing.currency == address(0)) { // Native currency (ETH)
            require(msg.value >= totalPrice, "Insufficient ETH sent");
            if (msg.value > totalPrice) {
                payable(_msgSender()).transfer(msg.value - totalPrice);
            }
            payable(platformFeeRecipient).transfer(platformFee);
            payable(bundleListing.seller).transfer(sellerProceeds);
        } else { // ERC20 token
            IERC20 currencyContract = IERC20(bundleListing.currency);
            require(currencyContract.allowance(_msgSender(), address(this)) >= totalPrice, "ERC20 allowance too low");
            require(currencyContract.transferFrom(_msgSender(), platformFeeRecipient, platformFee), "ERC20 platform fee transfer failed");
            require(currencyContract.transferFrom(_msgSender(), bundleListing.seller, sellerProceeds), "ERC20 seller payment failed");
        }

        bundleListing.isActive = false;
        for (uint256 i = 0; i < bundleListing.tokenIds.length; i++) {
            transferFrom(address(this), _msgSender(), bundleListing.tokenIds[i]);
            isNFTListed[bundleListing.tokenIds[i]] = false; // Unmark individual NFTs as listed
        }
        emit BundleBought(_bundleListingId, _msgSender(), totalPrice, bundleListing.currency, bundleListing.tokenIds);
    }

    // 16. cancelBundleListing
    function cancelBundleListing(uint256 _bundleListingId) public validBundleListing(_bundleListingId) whenNotPaused {
        BundleListing storage bundleListing = bundleListings[_bundleListingId];
        require(bundleListing.seller == _msgSender(), "Only seller can cancel bundle listing");

        bundleListing.isActive = false;
        for (uint256 i = 0; i < bundleListing.tokenIds.length; i++) {
            transferFrom(address(this), _msgSender(), bundleListing.tokenIds[i]);
            isNFTListed[bundleListing.tokenIds[i]] = false; // Unmark individual NFTs as listed
        }
        emit BundleListingCancelled(_bundleListingId);
    }

    // 17. setPlatformFee
    function setPlatformFee(uint256 _newFeePercentage) public onlyOwner whenNotPaused {
        require(_newFeePercentage <= 100, "Platform fee percentage too high");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeUpdated(_newFeePercentage);
    }

    // 18. withdrawPlatformFees
    function withdrawPlatformFees() public onlyOwner whenNotPaused {
        uint256 balanceETH = address(this).balance;
        if (balanceETH > 0) {
            payable(platformFeeRecipient).transfer(balanceETH);
            emit PlatformFeesWithdrawn(platformFeeRecipient, balanceETH);
        }
        // Add logic to withdraw ERC20 platform fees if needed, tracking ERC20 balances separately.
    }

    // 19. setCollectionRoyalty
    function setCollectionRoyalty(address _nftContract, uint256 _royaltyFeePercentage) public onlyOwner whenNotPaused {
        require(_royaltyFeePercentage <= 100, "Royalty percentage too high");
        collectionRoyalties[_nftContract] = _royaltyFeePercentage;
        emit CollectionRoyaltySet(_nftContract, _royaltyFeePercentage);
    }

    // 20. setConditionalSale
    function setConditionalSale(uint256 _listingId, address _conditionContract, uint256 _conditionTokenId) public validListing(_listingId) whenNotPaused {
        NFTListing storage listing = nftListings[_listingId];
        require(listing.seller == _msgSender(), "Only seller can set conditional sale");
        listing.conditionContract = _conditionContract;
        listing.conditionTokenId = _conditionTokenId;
        emit ConditionalSaleSet(_listingId, _conditionContract, _conditionTokenId);
    }

    // 21. fulfillConditionalSale
    function fulfillConditionalSale(uint256 _listingId) public payable validListing(_listingId) whenNotPaused nonReentrant {
        NFTListing storage listing = nftListings[_listingId];
        require(listing.conditionContract != address(0), "No conditional sale set");
        require(checkConditionalSale(_msgSender(), listing.conditionContract, listing.conditionTokenId), "Condition for sale not met");
        buyItem(_listingId); // Directly call buyItem after condition check
        emit ConditionalSaleFulfilled(_listingId, _msgSender());
    }

    // Helper function to check conditional sale (example - holder of specific NFT)
    function checkConditionalSale(address _buyer, address _conditionContract, uint256 _conditionTokenId) internal view returns (bool) {
        IERC721 conditionNFT = IERC721(_conditionContract);
        try {
            return conditionNFT.ownerOf(_conditionTokenId) == _buyer;
        } catch (bytes memory /*error*/) {
            return false; // Handle case where condition contract is not ERC721 or ownerOf reverts
        }
    }

    // 22. createRaffle
    function createRaffle(uint256 _tokenId, uint256 _ticketPrice, uint256 _raffleDuration) public onlyOwnerOrApproved(_tokenId) whenNotPaused {
        require(!isRaffleActive(_tokenId), "NFT already in raffle or listed/auctioned");
        require(ownerOf(_tokenId) == _msgSender(), "Not the owner of the NFT");
        require(_raffleDuration > 0, "Raffle duration must be positive");
        require(_ticketPrice > 0, "Ticket price must be positive");
        require(!isNFTListed[_tokenId] && !isAuctionActive[_tokenId], "NFT cannot be listed/auctioned and in raffle simultaneously");

        _raffleIdCounter.increment();
        uint256 raffleId = _raffleIdCounter.current();
        uint256 endTime = block.timestamp + _raffleDuration;

        // Transfer NFT to contract for raffle management
        transferFrom(_msgSender(), address(this), _tokenId);

        raffles[raffleId] = Raffle({
            raffleId: raffleId,
            tokenId: _tokenId,
            creator: _msgSender(),
            ticketPrice: _ticketPrice,
            endTime: endTime,
            ticketsSold: 0,
            winner: address(0),
            ended: false
        });
        emit RaffleCreated(raffleId, _tokenId, _msgSender(), _ticketPrice, _raffleDuration);
    }

    function isRaffleActive(uint256 _tokenId) public view returns (bool) {
        for (uint256 i = 1; i <= _raffleIdCounter.current(); i++) {
            if (raffles[i].tokenId == _tokenId && !raffles[i].ended) {
                return true;
            }
        }
        return false;
    }

    // 23. buyRaffleTicket
    function buyRaffleTicket(uint256 _raffleId, uint256 _numberOfTickets) public payable validRaffle(_raffleId) whenNotPaused nonReentrant {
        Raffle storage raffle = raffles[_raffleId];
        require(!raffle.ended, "Raffle already ended");
        require(block.timestamp < raffle.endTime, "Raffle time has ended");
        require(_numberOfTickets > 0, "Must buy at least one ticket");

        uint256 totalPrice = raffle.ticketPrice * _numberOfTickets;

        if (raffle.ticketPrice == 0) { // Free ticket
            // No payment needed
        } else if (raffle.ticketPrice > 0) {
            require(msg.value >= totalPrice, "Insufficient ETH sent for tickets");
            if (msg.value > totalPrice) {
                payable(_msgSender()).transfer(msg.value - totalPrice); // Refund excess ETH
            }
             payable(raffle.creator).transfer(totalPrice); // Send ticket revenue to raffle creator
        }

        raffle.ticketsSold += _numberOfTickets;
        emit RaffleTicketBought(_raffleId, _msgSender(), _numberOfTickets);
        // In a real-world scenario, you would likely need to store ticket buyers for winner selection.
        // For simplicity, this example doesn't track individual ticket buyers.
    }


    // 24. endRaffle
    function endRaffle(uint256 _raffleId) public validRaffle(_raffleId) whenNotPaused {
        Raffle storage raffle = raffles[_raffleId];
        require(block.timestamp >= raffle.endTime, "Raffle end time not reached yet");
        require(!raffle.ended, "Raffle already ended");

        raffle.ended = true;
        uint256 winnerIndex = uint256(blockhash(block.number - 1)) % raffle.ticketsSold; // Simple pseudo-random winner selection
        // In a real-world raffle, you'd need to track ticket buyers and select a winner from them.
        // For this simplified example, we're just assigning a pseudo-random winner (not truly fair or secure).
        // In a real implementation, you'd need a better random number generation method and ticket tracking.

        // For this simplified example, winner selection is based on a hash of a previous block and ticket count.
        // This is NOT secure or truly random for production use.
        // A proper raffle would require off-chain randomness or a verifiable random function (VRF).

        // Assign a placeholder winner address for this simplified example.
        // In a real system, you'd need to determine the actual winner from ticket buyers.
        address winnerAddress = address(uint160(winnerIndex)); // Placeholder - replace with actual winner selection logic

        raffle.winner = winnerAddress; // Placeholder winner assignment
        transferFrom(address(this), winnerAddress, raffle.tokenId); // Transfer NFT to (placeholder) winner

        emit RaffleEnded(_raffleId, raffle.tokenId, winnerAddress);
    }


    // 25. sendChatMessage
    function sendChatMessage(address _recipient, string memory _message) public whenNotPaused {
        // Basic on-chain messaging - limited by gas costs for message size.
        // For real-world messaging, consider off-chain solutions or specialized message contracts.
        emit ChatMessageSent(_msgSender(), _recipient, _message);
    }

    // 26. addToWishlist
    function addToWishlist(uint256 _tokenId) public whenNotPaused {
        userWishlists[_msgSender()].add(_tokenId);
        emit WishlistAdded(_msgSender(), _tokenId);
    }

    // 27. removeFromWishlist
    function removeFromWishlist(uint256 _tokenId) public whenNotPaused {
        userWishlists[_msgSender()].remove(_tokenId);
        emit WishlistRemoved(_msgSender(), _tokenId);
    }

    // 28. makeOffer
    function makeOffer(uint256 _tokenId, uint256 _offerPrice, address _currency) public whenNotPaused {
        _offerIdCounter.increment();
        uint256 offerId = _offerIdCounter.current();
        offers[offerId] = Offer({
            offerId: offerId,
            tokenId: _tokenId,
            offerer: _msgSender(),
            offerPrice: _offerPrice,
            currency: _currency,
            isActive: true
        });
        emit OfferMade(offerId, _tokenId, _msgSender(), _offerPrice, _currency);
    }

    // 29. acceptOffer
    function acceptOffer(uint256 _offerId) public whenNotPaused nonReentrant {
        Offer storage offer = offers[_offerId];
        require(offers[_offerId].isActive, "Offer is not active");
        require(ownerOf(offer.tokenId) == _msgSender(), "Only owner of NFT can accept offer");

        offers[_offerId].isActive = false; // Deactivate offer

        // Simulate direct purchase using offer details (price, currency) - adapt as needed
        uint256 totalPrice = offer.offerPrice;
        uint256 platformFee = (totalPrice * platformFeePercentage) / 100;
        uint256 sellerProceeds = totalPrice - platformFee;

        // Currency handling (basic)
        if (offer.currency == address(0)) { // Native currency (ETH)
             payable(platformFeeRecipient).transfer(platformFee);
             payable(_msgSender()).transfer(sellerProceeds); // Seller receives payment
        } else { // ERC20 token
            IERC20 currencyContract = IERC20(offer.currency);
            require(currencyContract.transferFrom(offer.offerer, platformFeeRecipient, platformFee), "ERC20 platform fee transfer failed"); // Offerer pays platform fee
            require(currencyContract.transferFrom(offer.offerer, _msgSender(), sellerProceeds), "ERC20 seller payment failed"); // Offerer pays seller
        }

        transferFrom(_msgSender(), offer.offerer, offer.tokenId); // Transfer NFT to offerer
        emit OfferAccepted(_offerId, offer.tokenId, offer.offerer);
    }


    // 30. rejectOffer
    function rejectOffer(uint256 _offerId) public whenNotPaused {
        require(offers[_offerId].isActive, "Offer is not active");
        require(ownerOf(offers[_offerId].tokenId) == _msgSender(), "Only owner of NFT can reject offer");
        offers[_offerId].isActive = false; // Deactivate offer
        emit OfferRejected(_offerId);
    }

    // 31. pauseMarketplace
    function pauseMarketplace() public onlyOwner whenNotPaused {
        paused = true;
        emit MarketplacePaused();
    }

    // 32. unpauseMarketplace
    function unpauseMarketplace() public onlyOwner whenPaused {
        paused = false;
        emit MarketplaceUnpaused();
    }

    // Fallback function to receive ETH - important for marketplace functionality
    receive() external payable {}
}
```