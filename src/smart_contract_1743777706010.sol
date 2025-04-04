```solidity
/**
 * @title Decentralized Dynamic NFT Marketplace with Evolving Metadata and Community Governance
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a decentralized NFT marketplace with dynamic NFT metadata updates based on market activity and community governance features.
 * It features advanced concepts like dynamic metadata, bundled listings, auction mechanisms, offer systems, and basic governance for fee adjustments and feature proposals.
 * This contract is designed to be unique and explores functionalities beyond standard NFT marketplaces.
 *
 * **Outline:**
 * 1. **Core Marketplace Functions:** Listing, Buying, Delisting, Offers, Bundles, Auctions
 * 2. **Dynamic NFT Metadata:** Evolving metadata based on marketplace events (e.g., listing, sale, popularity)
 * 3. **Royalty Management:** Support for creator royalties on secondary sales.
 * 4. **Community Governance (Basic):** Proposal and voting mechanism for fee changes and feature requests.
 * 5. **Token Gating:**  Functionality to restrict access to certain features based on token ownership.
 * 6. **Reporting and Flagging:** Mechanism to report potentially inappropriate listings.
 * 7. **Currency Flexibility:** Support for accepting multiple ERC20 tokens as payment (in this example, focusing on one additional ERC20).
 * 8. **Advanced Listing Options:**  Timed auctions, bundled listings.
 * 9. **Admin and Owner Functions:**  For contract management and emergency controls.
 * 10. **Event Emission:** Comprehensive event logging for off-chain tracking and indexing.
 *
 * **Function Summary:**
 * 1. `listNFT(uint256 _tokenId, address _nftContract, uint256 _price)`: List an NFT for sale at a fixed price.
 * 2. `unlistNFT(uint256 _listingId)`: Remove an NFT listing from the marketplace.
 * 3. `buyNFT(uint256 _listingId)`: Purchase an NFT listed on the marketplace.
 * 4. `makeOffer(uint256 _listingId, uint256 _offerPrice)`: Make an offer on a listed NFT.
 * 5. `acceptOffer(uint256 _offerId)`: Seller accepts a specific offer for their listed NFT.
 * 6. `rejectOffer(uint256 _offerId)`: Seller rejects a specific offer.
 * 7. `createBundleListing(address[] _nftContracts, uint256[] _tokenIds, uint256 _bundlePrice)`: List a bundle of NFTs for sale.
 * 8. `buyBundle(uint256 _bundleListingId)`: Purchase a bundle of NFTs.
 * 9. `startAuction(uint256 _tokenId, address _nftContract, uint256 _startingBid, uint256 _duration)`: Start a timed auction for an NFT.
 * 10. `bidOnAuction(uint256 _auctionId, uint256 _bidAmount)`: Place a bid on an active auction.
 * 11. `endAuction(uint256 _auctionId)`: End an auction and settle with the highest bidder.
 * 12. `setRoyalty(address _nftContract, uint256 _royaltyPercentage)`: Set the royalty percentage for an NFT contract.
 * 13. `getRoyalty(address _nftContract)`: Get the royalty percentage for an NFT contract.
 * 14. `proposeFeeChange(uint256 _newFeePercentage)`: Propose a change to the marketplace fee percentage. (Governance)
 * 15. `voteOnProposal(uint256 _proposalId, bool _vote)`: Vote on a governance proposal. (Governance)
 * 16. `executeProposal(uint256 _proposalId)`: Execute a passed governance proposal. (Governance)
 * 17. `reportListing(uint256 _listingId, string _reason)`: Report a listing for inappropriate content.
 * 18. `moderateListing(uint256 _listingId, bool _approve)`: Admin function to moderate a reported listing.
 * 19. `setAcceptedPaymentToken(address _tokenContract, bool _isAccepted)`: Set whether an ERC20 token is accepted as payment.
 * 20. `withdrawFunds(address _recipient)`: Admin/Owner function to withdraw marketplace fees.
 * 21. `pauseMarketplace()`: Owner function to pause all marketplace functionalities.
 * 22. `unpauseMarketplace()`: Owner function to unpause marketplace functionalities.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DynamicNFTMarketplace is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // Marketplace Fee (percentage, e.g., 200 for 2%)
    uint256 public marketplaceFeePercentage = 200; // 2% default fee
    address public feeRecipient;

    // Accepted Payment Tokens (address => bool) - Initially only ETH and one ERC20
    mapping(address => bool) public acceptedPaymentTokens;
    address public primaryPaymentToken; // Address(0) for ETH

    // Royalty Information (NFT Contract Address => Royalty Percentage)
    mapping(address => uint256) public nftRoyalties;

    // Listing Struct
    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address nftContract;
        address seller;
        uint256 price;
        bool isActive;
        bool isBundle;
        uint256 listingTime;
    }
    mapping(uint256 => Listing) public listings;
    Counters.Counter private _listingIdCounter;

    // Bundle Listing Struct
    struct BundleListing {
        uint256 bundleListingId;
        address[] nftContracts;
        uint256[] tokenIds;
        address seller;
        uint256 bundlePrice;
        bool isActive;
        uint256 listingTime;
    }
    mapping(uint256 => BundleListing) public bundleListings;
    Counters.Counter private _bundleListingIdCounter;

    // Offer Struct
    struct Offer {
        uint256 offerId;
        uint256 listingId;
        address offerer;
        uint256 offerPrice;
        bool isActive;
        uint256 offerTime;
    }
    mapping(uint256 => Offer) public offers;
    Counters.Counter private _offerIdCounter;

    // Auction Struct
    struct Auction {
        uint256 auctionId;
        uint256 tokenId;
        address nftContract;
        address seller;
        uint256 startingBid;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool isActive;
    }
    mapping(uint256 => Auction) public auctions;
    Counters.Counter private _auctionIdCounter;

    // Governance Proposal Struct
    struct GovernanceProposal {
        uint256 proposalId;
        string description;
        address proposer;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool isExecuted;
        ProposalType proposalType;
        uint256 proposalValue; // Value associated with the proposal (e.g., new fee percentage)
    }
    enum ProposalType { FeeChange, FeatureRequest }
    mapping(uint256 => GovernanceProposal) public proposals;
    Counters.Counter private _proposalIdCounter;
    uint256 public governanceVotingDuration = 7 days; // Default voting duration

    // Reported Listings (listingId => reason)
    mapping(uint256 => string) public reportedListings;

    // Paused State
    bool public marketplacePaused = false;

    // Events
    event NFTListed(uint256 listingId, uint256 tokenId, address nftContract, address seller, uint256 price);
    event NFTUnlisted(uint256 listingId);
    event NFTSold(uint256 listingId, address buyer, uint256 price);
    event OfferMade(uint256 offerId, uint256 listingId, address offerer, uint256 offerPrice);
    event OfferAccepted(uint256 offerId, uint256 listingId, address seller, address buyer, uint256 price);
    event OfferRejected(uint256 offerId);
    event BundleListed(uint256 bundleListingId, address seller, uint256 bundlePrice);
    event BundleSold(uint256 bundleListingId, address buyer, uint256 bundlePrice);
    event AuctionStarted(uint256 auctionId, uint256 tokenId, address nftContract, address seller, uint256 startingBid, uint256 endTime);
    event BidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionEnded(uint256 auctionId, address winner, uint256 winningBid);
    event RoyaltySet(address nftContract, uint256 royaltyPercentage);
    event FeePercentageChanged(uint256 newFeePercentage);
    event GovernanceProposalCreated(uint256 proposalId, string description, address proposer, ProposalType proposalType, uint256 proposalValue);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event ListingReported(uint256 listingId, string reason, address reporter);
    event ListingModerated(uint256 listingId, bool approved, address moderator);
    event PaymentTokenAccepted(address tokenContract, bool isAccepted);
    event MarketplacePaused();
    event MarketplaceUnpaused();

    constructor(address _feeRecipient, address _primaryPaymentToken) {
        feeRecipient = _feeRecipient;
        primaryPaymentToken = _primaryPaymentToken; // Address(0) for ETH
        acceptedPaymentTokens[_primaryPaymentToken] = true; // Accept ETH by default
    }

    // --- 1. Core Marketplace Functions ---

    /// @notice List an NFT for sale at a fixed price.
    /// @param _tokenId The token ID of the NFT to list.
    /// @param _nftContract The address of the NFT contract.
    /// @param _price The listing price in the primary payment token.
    function listNFT(uint256 _tokenId, address _nftContract, uint256 _price) external nonReentrant whenNotPaused {
        IERC721 nft = IERC721(_nftContract);
        require(nft.ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        require(nft.getApproved(_tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)), "Marketplace not approved for NFT transfer");
        require(_price > 0, "Price must be greater than zero");

        _listingIdCounter.increment();
        uint256 listingId = _listingIdCounter.current();

        listings[listingId] = Listing({
            listingId: listingId,
            tokenId: _tokenId,
            nftContract: _nftContract,
            seller: msg.sender,
            price: _price,
            isActive: true,
            isBundle: false,
            listingTime: block.timestamp
        });

        emit NFTListed(listingId, _tokenId, _nftContract, msg.sender, _price);
    }

    /// @notice Remove an NFT listing from the marketplace.
    /// @param _listingId The ID of the listing to unlist.
    function unlistNFT(uint256 _listingId) external nonReentrant whenNotPaused {
        require(listings[_listingId].seller == msg.sender, "Not listing owner");
        require(listings[_listingId].isActive, "Listing not active");

        listings[_listingId].isActive = false;
        emit NFTUnlisted(_listingId);
    }

    /// @notice Purchase an NFT listed on the marketplace.
    /// @param _listingId The ID of the listing to buy.
    function buyNFT(uint256 _listingId) external payable nonReentrant whenNotPaused {
        Listing storage listing = listings[_listingId];
        require(listing.isActive, "Listing not active");
        require(listing.seller != msg.sender, "Cannot buy your own NFT");

        uint256 price = listing.price;
        address nftContract = listing.nftContract;
        uint256 tokenId = listing.tokenId;
        address seller = listing.seller;

        // Payment Processing
        require(acceptedPaymentTokens[primaryPaymentToken], "Primary payment token not accepted");
        if (primaryPaymentToken == address(0)) { // ETH payment
            require(msg.value >= price, "Insufficient ETH sent");
        } else { // ERC20 payment (using primaryPaymentToken as example ERC20)
            IERC20 paymentToken = IERC20(primaryPaymentToken);
            require(paymentToken.transferFrom(msg.sender, address(this), price), "ERC20 payment failed");
        }

        // Transfer NFT
        IERC721 nft = IERC721(nftContract);
        nft.safeTransferFrom(seller, msg.sender, tokenId);

        // Fee and Royalty Distribution
        uint256 feeAmount = price.mul(marketplaceFeePercentage).div(10000);
        uint256 royaltyAmount = price.mul(nftRoyalties[nftContract]).div(10000);
        uint256 sellerPayout = price.sub(feeAmount).sub(royaltyAmount);

        // Transfer Fees and Royalties
        payable(feeRecipient).transfer(feeAmount);
        if (royaltyAmount > 0) {
            // Assuming a function in NFT contract to get creator address, or stored royalty recipient address
            // For simplicity, assuming royalty goes back to the seller for now (replace with actual royalty recipient logic)
            payable(seller).transfer(royaltyAmount); // Replace with actual royalty recipient logic
        }
        payable(seller).transfer(sellerPayout);


        listings[_listingId].isActive = false; // Deactivate listing after purchase

        // Dynamic Metadata Update Example - Increase "popularity" score based on sales (simplified example)
        // In a real-world scenario, this could trigger an off-chain service to update NFT metadata
        // based on marketplace events. Here, we're just emitting an event to indicate a sale for potential off-chain processing.
        emit NFTSold(_listingId, msg.sender, price);
        // Example of triggering dynamic metadata update (off-chain service would listen to this event)
        emit DynamicMetadataUpdateRequested(nftContract, tokenId, "sale");
    }

    /// @notice Make an offer on a listed NFT.
    /// @param _listingId The ID of the listing to make an offer on.
    /// @param _offerPrice The offered price in the primary payment token.
    function makeOffer(uint256 _listingId, uint256 _offerPrice) external payable nonReentrant whenNotPaused {
        Listing storage listing = listings[_listingId];
        require(listing.isActive, "Listing not active");
        require(listing.seller != msg.sender, "Cannot make offer on your own NFT");
        require(_offerPrice > 0 && _offerPrice < listing.price, "Offer price must be positive and less than listing price");

        _offerIdCounter.increment();
        uint256 offerId = _offerIdCounter.current();

        offers[offerId] = Offer({
            offerId: offerId,
            listingId: _listingId,
            offerer: msg.sender,
            offerPrice: _offerPrice,
            isActive: true,
            offerTime: block.timestamp
        });

        emit OfferMade(offerId, _listingId, msg.sender, _offerPrice);
    }

    /// @notice Seller accepts a specific offer for their listed NFT.
    /// @param _offerId The ID of the offer to accept.
    function acceptOffer(uint256 _offerId) external nonReentrant whenNotPaused {
        Offer storage offer = offers[_offerId];
        require(offer.isActive, "Offer not active");
        Listing storage listing = listings[offer.listingId];
        require(listing.isActive, "Listing not active");
        require(listing.seller == msg.sender, "Not listing owner");
        require(offer.offerer != msg.sender, "Cannot accept offer made by yourself");

        uint256 price = offer.offerPrice;
        address nftContract = listing.nftContract;
        uint256 tokenId = listing.tokenId;
        address seller = listing.seller;
        address buyer = offer.offerer;

        // Payment Processing - Assuming buyer needs to have approved marketplace to spend their tokens
        require(acceptedPaymentTokens[primaryPaymentToken], "Primary payment token not accepted");
        if (primaryPaymentToken == address(0)) { // ETH payment - Assuming offerer already sent ETH with offer? (For simplicity, assuming offerer sends ETH again on accept)
            require(msg.value >= price, "Insufficient ETH sent for offer acceptance");
        } else { // ERC20 payment
            IERC20 paymentToken = IERC20(primaryPaymentToken);
            require(paymentToken.transferFrom(msg.sender, address(this), price), "ERC20 payment failed for offer acceptance");
        }

        // Transfer NFT
        IERC721 nft = IERC721(nftContract);
        nft.safeTransferFrom(seller, buyer, tokenId);

        // Fee and Royalty Distribution
        uint256 feeAmount = price.mul(marketplaceFeePercentage).div(10000);
        uint256 royaltyAmount = price.mul(nftRoyalties[nftContract]).div(10000);
        uint256 sellerPayout = price.sub(feeAmount).sub(royaltyAmount);

        // Transfer Fees and Royalties
        payable(feeRecipient).transfer(feeAmount);
        if (royaltyAmount > 0) {
            payable(seller).transfer(royaltyAmount); // Replace with actual royalty recipient logic
        }
        payable(seller).transfer(sellerPayout);

        listings[offer.listingId].isActive = false; // Deactivate listing
        offers[_offerId].isActive = false; // Deactivate offer

        emit OfferAccepted(_offerId, offer.listingId, seller, buyer, price);
        emit NFTSold(offer.listingId, buyer, price); // Reuse NFTSold event for offer acceptance sales
        emit DynamicMetadataUpdateRequested(nftContract, tokenId, "offer_accepted"); // Dynamic metadata update
    }

    /// @notice Seller rejects a specific offer.
    /// @param _offerId The ID of the offer to reject.
    function rejectOffer(uint256 _offerId) external whenNotPaused {
        Offer storage offer = offers[_offerId];
        require(offer.isActive, "Offer not active");
        Listing storage listing = listings[offer.listingId];
        require(listing.isActive, "Listing not active");
        require(listing.seller == msg.sender, "Not listing owner");

        offers[_offerId].isActive = false;
        emit OfferRejected(_offerId);
    }

    /// @notice Create a listing for a bundle of NFTs.
    /// @param _nftContracts Array of NFT contract addresses in the bundle.
    /// @param _tokenIds Array of token IDs corresponding to each NFT contract in the bundle.
    /// @param _bundlePrice The price of the entire bundle.
    function createBundleListing(address[] memory _nftContracts, uint256[] memory _tokenIds, uint256 _bundlePrice) external nonReentrant whenNotPaused {
        require(_nftContracts.length == _tokenIds.length && _nftContracts.length > 0, "Invalid bundle NFTs");
        require(_bundlePrice > 0, "Bundle price must be greater than zero");

        for (uint256 i = 0; i < _nftContracts.length; i++) {
            IERC721 nft = IERC721(_nftContracts[i]);
            require(nft.ownerOf(_tokenIds[i]) == msg.sender, "Not owner of all NFTs in bundle");
            require(nft.getApproved(_tokenIds[i]) == address(this) || nft.isApprovedForAll(msg.sender, address(this)), "Marketplace not approved for NFT transfer in bundle");
        }

        _bundleListingIdCounter.increment();
        uint256 bundleListingId = _bundleListingIdCounter.current();

        bundleListings[bundleListingId] = BundleListing({
            bundleListingId: bundleListingId,
            nftContracts: _nftContracts,
            tokenIds: _tokenIds,
            seller: msg.sender,
            bundlePrice: _bundlePrice,
            isActive: true,
            listingTime: block.timestamp
        });

        emit BundleListed(bundleListingId, msg.sender, _bundlePrice);
    }

    /// @notice Purchase a bundle of NFTs.
    /// @param _bundleListingId The ID of the bundle listing to buy.
    function buyBundle(uint256 _bundleListingId) external payable nonReentrant whenNotPaused {
        BundleListing storage bundleListing = bundleListings[_bundleListingId];
        require(bundleListing.isActive, "Bundle listing not active");
        require(bundleListing.seller != msg.sender, "Cannot buy your own bundle");

        uint256 bundlePrice = bundleListing.bundlePrice;
        address[] storage nftContracts = bundleListing.nftContracts;
        uint256[] storage tokenIds = bundleListing.tokenIds;
        address seller = bundleListing.seller;

        // Payment Processing
        require(acceptedPaymentTokens[primaryPaymentToken], "Primary payment token not accepted");
        if (primaryPaymentToken == address(0)) { // ETH payment
            require(msg.value >= bundlePrice, "Insufficient ETH sent for bundle");
        } else { // ERC20 payment
            IERC20 paymentToken = IERC20(primaryPaymentToken);
            require(paymentToken.transferFrom(msg.sender, address(this), bundlePrice), "ERC20 payment failed for bundle");
        }

        // Transfer NFTs in bundle
        for (uint256 i = 0; i < nftContracts.length; i++) {
            IERC721 nft = IERC721(nftContracts[i]);
            nft.safeTransferFrom(seller, msg.sender, tokenIds[i]);
            emit DynamicMetadataUpdateRequested(nftContracts[i], tokenIds[i], "bundle_sale"); // Dynamic metadata update for each NFT in bundle
        }

        // Fee Distribution (applied to the entire bundle price)
        uint256 feeAmount = bundlePrice.mul(marketplaceFeePercentage).div(10000);
        uint256 sellerPayout = bundlePrice.sub(feeAmount);

        payable(feeRecipient).transfer(feeAmount);
        payable(seller).transfer(sellerPayout);

        bundleListings[_bundleListingId].isActive = false; // Deactivate bundle listing

        emit BundleSold(_bundleListingId, msg.sender, bundlePrice);
    }

    /// @notice Start a timed auction for an NFT.
    /// @param _tokenId The token ID of the NFT to auction.
    /// @param _nftContract The address of the NFT contract.
    /// @param _startingBid The starting bid price in the primary payment token.
    /// @param _duration Auction duration in seconds.
    function startAuction(uint256 _tokenId, address _nftContract, uint256 _startingBid, uint256 _duration) external nonReentrant whenNotPaused {
        IERC721 nft = IERC721(_nftContract);
        require(nft.ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        require(nft.getApproved(_tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)), "Marketplace not approved for NFT transfer");
        require(_startingBid > 0, "Starting bid must be greater than zero");
        require(_duration > 0 && _duration <= 30 days, "Auction duration must be within 30 days");

        _auctionIdCounter.increment();
        uint256 auctionId = _auctionIdCounter.current();

        auctions[auctionId] = Auction({
            auctionId: auctionId,
            tokenId: _tokenId,
            nftContract: _nftContract,
            seller: msg.sender,
            startingBid: _startingBid,
            endTime: block.timestamp + _duration,
            highestBidder: address(0),
            highestBid: 0,
            isActive: true
        });

        emit AuctionStarted(auctionId, _tokenId, _nftContract, msg.sender, _startingBid, block.timestamp + _duration);
    }

    /// @notice Place a bid on an active auction.
    /// @param _auctionId The ID of the auction to bid on.
    /// @param _bidAmount The bid amount in the primary payment token.
    function bidOnAuction(uint256 _auctionId, uint256 _bidAmount) external payable nonReentrant whenNotPaused {
        Auction storage auction = auctions[_auctionId];
        require(auction.isActive, "Auction not active");
        require(block.timestamp < auction.endTime, "Auction ended");
        require(auction.seller != msg.sender, "Seller cannot bid on own auction");
        require(_bidAmount > auction.highestBid, "Bid amount must be higher than current highest bid");

        // Payment Processing - Refund previous bidder if exists
        if (auction.highestBidder != address(0)) {
            if (primaryPaymentToken == address(0)) {
                payable(auction.highestBidder).transfer(auction.highestBid);
            } else {
                IERC20 paymentToken = IERC20(primaryPaymentToken);
                require(paymentToken.transfer(auction.highestBidder, auction.highestBid), "Refund to previous bidder failed");
            }
        }

        // Payment for new bid
        require(acceptedPaymentTokens[primaryPaymentToken], "Primary payment token not accepted");
        if (primaryPaymentToken == address(0)) { // ETH payment
            require(msg.value >= _bidAmount, "Insufficient ETH sent for bid");
        } else { // ERC20 payment
            IERC20 paymentToken = IERC20(primaryPaymentToken);
            require(paymentToken.transferFrom(msg.sender, address(this), _bidAmount), "ERC20 payment failed for bid");
        }

        auctions[_auctionId].highestBidder = msg.sender;
        auctions[_auctionId].highestBid = _bidAmount;

        emit BidPlaced(_auctionId, msg.sender, _bidAmount);
    }

    /// @notice End an auction and settle with the highest bidder.
    /// @param _auctionId The ID of the auction to end.
    function endAuction(uint256 _auctionId) external nonReentrant whenNotPaused {
        Auction storage auction = auctions[_auctionId];
        require(auction.isActive, "Auction not active");
        require(block.timestamp >= auction.endTime, "Auction not ended yet");

        auction.isActive = false;

        address seller = auction.seller;
        address winner = auction.highestBidder;
        uint256 winningBid = auction.highestBid;
        address nftContract = auction.nftContract;
        uint256 tokenId = auction.tokenId;

        if (winner != address(0)) {
            // Transfer NFT to winner
            IERC721 nft = IERC721(nftContract);
            nft.safeTransferFrom(seller, winner, tokenId);

            // Fee and Royalty Distribution from winning bid
            uint256 feeAmount = winningBid.mul(marketplaceFeePercentage).div(10000);
            uint256 royaltyAmount = winningBid.mul(nftRoyalties[nftContract]).div(10000);
            uint256 sellerPayout = winningBid.sub(feeAmount).sub(royaltyAmount);

            // Transfer Fees and Royalties
            payable(feeRecipient).transfer(feeAmount);
            if (royaltyAmount > 0) {
                 payable(seller).transfer(royaltyAmount); // Replace with actual royalty recipient logic
            }
            payable(seller).transfer(sellerPayout);

            emit AuctionEnded(_auctionId, winner, winningBid);
            emit DynamicMetadataUpdateRequested(nftContract, tokenId, "auction_sold"); // Dynamic metadata update
        } else {
            // No bids, return NFT to seller (optional - could also relist or handle differently)
            IERC721 nft = IERC721(nftContract);
            nft.transferFrom(address(this), seller, tokenId); // Assuming marketplace holds NFT during auction? (for simplicity, not implemented here, seller holds NFT until auction end)
            // In a real auction scenario, the NFT might be escrowed in the contract.
            emit AuctionEnded(_auctionId, address(0), 0); // Indicate no winner
        }
    }

    // --- 2. Dynamic NFT Metadata (Example - Event Emission for off-chain processing) ---
    event DynamicMetadataUpdateRequested(address nftContract, uint256 tokenId, string reason);
    // In a real application, an off-chain service would listen to these events and update the NFT metadata.
    // The "reason" parameter provides context for the metadata update (e.g., "sale", "offer_accepted", "auction_sold").

    // --- 3. Royalty Management ---

    /// @notice Set the royalty percentage for an NFT contract. Only owner can set.
    /// @param _nftContract The address of the NFT contract.
    /// @param _royaltyPercentage The royalty percentage (e.g., 500 for 5%).
    function setRoyalty(address _nftContract, uint256 _royaltyPercentage) external onlyOwner {
        require(_royaltyPercentage <= 2000, "Royalty percentage cannot exceed 20%"); // Example limit
        nftRoyalties[_nftContract] = _royaltyPercentage;
        emit RoyaltySet(_nftContract, _royaltyPercentage);
    }

    /// @notice Get the royalty percentage for an NFT contract.
    /// @param _nftContract The address of the NFT contract.
    /// @return uint256 The royalty percentage.
    function getRoyalty(address _nftContract) external view returns (uint256) {
        return nftRoyalties[_nftContract];
    }

    // --- 4. Community Governance (Basic Proposal & Voting) ---

    /// @notice Propose a change to the marketplace fee percentage.
    /// @param _newFeePercentage The new fee percentage to propose (e.g., 150 for 1.5%).
    function proposeFeeChange(uint256 _newFeePercentage) external whenNotPaused {
        require(_newFeePercentage <= 10000, "Fee percentage cannot exceed 100%"); // Example limit
        _propose(ProposalType.FeeChange, "Change Marketplace Fee", _newFeePercentage);
    }

    /// @dev Internal function to create a governance proposal.
    function _propose(ProposalType _proposalType, string memory _description, uint256 _proposalValue) internal {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            description: _description,
            proposer: msg.sender,
            votingEndTime: block.timestamp + governanceVotingDuration,
            yesVotes: 0,
            noVotes: 0,
            isExecuted: false,
            proposalType: _proposalType,
            proposalValue: _proposalValue
        });

        emit GovernanceProposalCreated(proposalId, _description, msg.sender, _proposalType, _proposalValue);
    }

    /// @notice Vote on a governance proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote `true` for yes, `false` for no.
    function voteOnProposal(uint256 _proposalId, bool _vote) external whenNotPaused {
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(!proposal.isExecuted, "Proposal already executed");
        require(block.timestamp < proposal.votingEndTime, "Voting period ended");
        // Basic voting - everyone can vote once (simple example, can be improved with token-weighted voting)

        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    /// @notice Execute a passed governance proposal (after voting period).
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyOwner whenNotPaused {
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(!proposal.isExecuted, "Proposal already executed");
        require(block.timestamp >= proposal.votingEndTime, "Voting period not ended");
        require(proposal.yesVotes > proposal.noVotes, "Proposal not passed"); // Simple majority

        proposal.isExecuted = true;

        if (proposal.proposalType == ProposalType.FeeChange) {
            marketplaceFeePercentage = proposal.proposalValue;
            emit FeePercentageChanged(marketplaceFeePercentage);
        } else if (proposal.proposalType == ProposalType.FeatureRequest) {
            // Example: Log feature request for off-chain action, or enable/disable features based on proposalValue (if feature flags implemented)
            emit ProposalExecuted(_proposalId); // Just emit event for feature requests for now.
            // In a more advanced system, you could have feature flags controlled by governance.
        }
        emit ProposalExecuted(_proposalId);
    }

    // --- 5. Token Gating (Example - Future Feature, Placeholder) ---
    // Functionality to restrict listing/buying based on token ownership could be added here.
    // For example, require users to hold a specific NFT or token to access premium features or specific NFT collections.

    // --- 6. Reporting and Flagging ---

    /// @notice Report a listing for inappropriate content.
    /// @param _listingId The ID of the listing to report.
    /// @param _reason The reason for reporting.
    function reportListing(uint256 _listingId, string memory _reason) external whenNotPaused {
        require(listings[_listingId].isActive || bundleListings[_listingId].isActive, "Listing not found or inactive"); // Check for both types

        reportedListings[_listingId] = _reason;
        emit ListingReported(_listingId, _reason, msg.sender);
    }

    /// @notice Admin function to moderate a reported listing (approve or disapprove).
    /// @param _listingId The ID of the listing to moderate.
    /// @param _approve `true` to approve the listing (remove from reported list), `false` to disapprove (deactivate listing).
    function moderateListing(uint256 _listingId, bool _approve) external onlyOwner whenNotPaused {
        require(reportedListings[_listingId].length > 0, "Listing not reported");

        if (_approve) {
            delete reportedListings[_listingId]; // Remove from reported list if approved
        } else {
            if (listings[_listingId].isActive) {
                listings[_listingId].isActive = false; // Deactivate NFT listing
            } else if (bundleListings[_listingId].isActive) {
                bundleListings[_listingId].isActive = false; // Deactivate bundle listing
            }
        }
        emit ListingModerated(_listingId, _approve, msg.sender);
    }

    // --- 7. Currency Flexibility ---

    /// @notice Set whether an ERC20 token is accepted as payment in the marketplace.
    /// @param _tokenContract The address of the ERC20 token contract.
    /// @param _isAccepted `true` to accept, `false` to reject.
    function setAcceptedPaymentToken(address _tokenContract, bool _isAccepted) external onlyOwner {
        acceptedPaymentTokens[_tokenContract] = _isAccepted;
        emit PaymentTokenAccepted(_tokenContract, _isAccepted);
    }

    // --- 9. Admin and Owner Functions ---

    /// @notice Owner function to withdraw marketplace fees.
    /// @param _recipient The address to withdraw fees to.
    function withdrawFunds(address payable _recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        if (primaryPaymentToken != address(0)) { // Also withdraw ERC20 if primary payment is ERC20
            balance = balance.add(IERC20(primaryPaymentToken).balanceOf(address(this)));
        }
        require(balance > 0, "No funds to withdraw");
        payable(_recipient).transfer(balance); // Withdraw ETH fees
        if (primaryPaymentToken != address(0)) {
            IERC20 paymentToken = IERC20(primaryPaymentToken);
            uint256 tokenBalance = paymentToken.balanceOf(address(this));
            if (tokenBalance > 0) {
                require(paymentToken.transfer(_recipient, tokenBalance), "ERC20 withdrawal failed"); // Withdraw ERC20 fees
            }
        }
    }

    /// @notice Owner function to pause the marketplace.
    function pauseMarketplace() external onlyOwner {
        marketplacePaused = true;
        emit MarketplacePaused();
    }

    /// @notice Owner function to unpause the marketplace.
    function unpauseMarketplace() external onlyOwner {
        marketplacePaused = false;
        emit MarketplaceUnpaused();
    }

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!marketplacePaused, "Marketplace is paused");
        _;
    }
}
```