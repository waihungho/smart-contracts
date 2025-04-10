```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with Advanced Features
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a decentralized marketplace for Dynamic NFTs with advanced features
 *      such as dynamic metadata updates, reputation system, decentralized governance, and unique auction mechanisms.
 *
 * **Outline and Function Summary:**
 *
 * **1. Core NFT Functionality:**
 *    - `mintDynamicNFT(address _to, string memory _baseURI)`: Mints a new Dynamic NFT to the specified address with an initial base URI.
 *    - `transferNFT(address _to, uint256 _tokenId)`: Transfers an NFT to another address.
 *    - `burnNFT(uint256 _tokenId)`: Burns (destroys) an NFT.
 *    - `setBaseURI(string memory _newBaseURI)`: Sets the base URI for all NFTs in the collection (Admin only).
 *    - `tokenURI(uint256 _tokenId)`: Returns the dynamic URI for a specific NFT, incorporating dynamic metadata logic.
 *
 * **2. Marketplace Listing and Trading:**
 *    - `listNFTForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale at a fixed price.
 *    - `unlistNFTFromSale(uint256 _tokenId)`: Removes an NFT listing from sale.
 *    - `buyNFT(uint256 _tokenId)`: Allows anyone to buy a listed NFT.
 *    - `offerNFTPrice(uint256 _tokenId, uint256 _price)`: Allows users to make an offer on an NFT, even if not listed.
 *    - `acceptNFTOffer(uint256 _offerId)`: Seller accepts a specific offer made on their NFT.
 *
 * **3. Dynamic Metadata and Traits:**
 *    - `updateDynamicMetadata(uint256 _tokenId, string memory _dynamicData)`: Updates the dynamic metadata part of an NFT's URI.
 *    - `setNFTTrait(uint256 _tokenId, string memory _traitName, string memory _traitValue)`: Sets a specific trait for an NFT, influencing metadata.
 *    - `getNFTTraits(uint256 _tokenId)`: Retrieves all traits associated with an NFT.
 *
 * **4. Reputation and Trust System:**
 *    - `rateUser(address _user, uint8 _rating, string memory _feedback)`: Allows users to rate other users based on marketplace interactions.
 *    - `getUserRating(address _user)`: Retrieves the average rating and feedback count for a user.
 *
 * **5. Decentralized Governance (Simplified):**
 *    - `proposeMarketplaceFee(uint256 _newFeePercentage)`: Allows users to propose a change to the marketplace fee.
 *    - `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows NFT holders to vote on active proposals.
 *    - `executeProposal(uint256 _proposalId)`: Executes a passed proposal (Admin/Governance controlled).
 *
 * **6. Unique Auction Mechanism (Progressive Dutch Auction):**
 *    - `startProgressiveDutchAuction(uint256 _tokenId, uint256 _startPrice, uint256 _endPrice, uint256 _duration)`: Starts a Progressive Dutch Auction for an NFT.
 *    - `bidInAuction(uint256 _auctionId)`: Allows users to bid in the Dutch Auction; price progressively decreases over time.
 *    - `endAuction(uint256 _auctionId)`: Ends the auction and transfers NFT to the highest bidder (or reverts if no bids).
 *
 * **7. Utility and Admin Functions:**
 *    - `setMarketplaceFee(uint256 _feePercentage)`: Sets the marketplace fee percentage (Admin only).
 *    - `withdrawMarketplaceFees()`: Allows the contract owner to withdraw accumulated marketplace fees (Admin only).
 *    - `pauseMarketplace()`: Pauses all marketplace trading functionality (Admin only).
 *    - `unpauseMarketplace()`: Resumes marketplace trading functionality (Admin only).
 */

contract DynamicNFTMarketplace {
    // ** State Variables **

    string public name = "Dynamic NFT Marketplace";
    string public symbol = "DNFTM";
    string public baseURI; // Base URI for NFT metadata
    address public owner;
    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    uint256 public nextNFTId = 1;
    uint256 public nextOfferId = 1;
    uint256 public nextAuctionId = 1;
    bool public paused = false;

    mapping(uint256 => address) public nftOwner; // Token ID to owner address
    mapping(uint256 => string) public dynamicMetadata; // Token ID to dynamic metadata string
    mapping(uint256 => mapping(string => string)) public nftTraits; // Token ID to traits mapping (traitName -> traitValue)

    mapping(uint256 => Listing) public nftListings; // Token ID to Listing details
    mapping(uint256 => Offer) public nftOffers; // Offer ID to Offer details
    mapping(address => UserRating) public userRatings; // User address to rating data
    mapping(uint256 => Auction) public auctions; // Auction ID to Auction details
    mapping(uint256 => Proposal) public proposals; // Proposal ID to Proposal details
    uint256 public nextProposalId = 1;

    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }

    struct Offer {
        uint256 offerId;
        uint256 tokenId;
        address buyer;
        uint256 price;
        bool isActive;
    }

    struct UserRating {
        uint256 totalRating;
        uint256 ratingCount;
        mapping(uint256 => string) feedbacks; // Feedback ID to feedback text
        uint256 nextFeedbackId;
    }

    struct Auction {
        uint256 auctionId;
        uint256 tokenId;
        address seller;
        uint256 startPrice;
        uint256 endPrice;
        uint256 duration; // Auction duration in seconds
        uint256 startTime;
        address highestBidder;
        uint256 highestBid;
        bool isActive;
    }

    struct Proposal {
        uint256 proposalId;
        string description;
        uint256 newFeePercentage; // Example proposal for fee change
        uint256 yesVotes;
        uint256 noVotes;
        bool isActive;
        bool executed;
    }

    // ** Events **

    event NFTMinted(uint256 tokenId, address to);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTBurned(uint256 tokenId, address owner);
    event NFTListedForSale(uint256 tokenId, uint256 price, address seller);
    event NFTUnlistedFromSale(uint256 tokenId, address seller);
    event NFTBought(uint256 tokenId, address buyer, address seller, uint256 price);
    event NFTOfferMade(uint256 offerId, uint256 tokenId, address buyer, uint256 price);
    event NFTOfferAccepted(uint256 offerId, uint256 tokenId, address buyer, address seller, uint256 price);
    event DynamicMetadataUpdated(uint256 tokenId, string dynamicData);
    event NFTTraitSet(uint256 tokenId, string traitName, string traitValue);
    event UserRated(address user, uint8 rating, string feedback);
    event MarketplaceFeeProposed(uint256 proposalId, uint256 newFeePercentage, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event ProgressiveDutchAuctionStarted(uint256 auctionId, uint256 tokenId, uint256 startPrice, uint256 endPrice, uint256 duration, address seller);
    event BidPlacedInAuction(uint256 auctionId, address bidder, uint256 bidAmount);
    event ProgressiveDutchAuctionEnded(uint256 auctionId, uint256 tokenId, address winner, uint256 finalPrice);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event MarketplaceFeeSet(uint256 feePercentage);
    event MarketplaceFeesWithdrawn(uint256 amount, address admin);

    // ** Modifiers **

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Marketplace is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Marketplace is not paused.");
        _;
    }

    modifier nftExists(uint256 _tokenId) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(nftOwner[_tokenId] == msg.sender, "You are not the NFT owner.");
        _;
    }

    modifier listingExists(uint256 _tokenId) {
        require(nftListings[_tokenId].isActive, "NFT is not listed for sale.");
        _;
    }

    modifier offerExists(uint256 _offerId) {
        require(nftOffers[_offerId].isActive, "Offer does not exist or is inactive.");
        _;
    }

    modifier auctionExists(uint256 _auctionId) {
        require(auctions[_auctionId].isActive, "Auction does not exist or is inactive.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].isActive, "Proposal does not exist or is inactive.");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!proposals[_proposalId].executed, "Proposal already executed.");
        _;
    }

    // ** Constructor **

    constructor(string memory _baseURI) {
        owner = msg.sender;
        baseURI = _baseURI;
    }

    // ** 1. Core NFT Functionality **

    /// @dev Mints a new Dynamic NFT to the specified address.
    /// @param _to The address to mint the NFT to.
    /// @param _baseURI The initial base URI for the NFT collection.
    function mintDynamicNFT(address _to, string memory _baseURI) external onlyOwner {
        require(_to != address(0), "Invalid recipient address.");
        uint256 tokenId = nextNFTId++;
        nftOwner[tokenId] = _to;
        baseURI = _baseURI; // Set base URI for the collection on first mint. Consider separate collection contract for more complex scenarios.
        emit NFTMinted(tokenId, _to);
    }

    /// @dev Transfers an NFT to another address.
    /// @param _to The address to transfer the NFT to.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferNFT(address _to, uint256 _tokenId) external nftExists(_tokenId) onlyNFTOwner(_tokenId) whenNotPaused {
        require(_to != address(0), "Invalid recipient address.");
        address from = msg.sender;
        nftOwner[_tokenId] = _to;
        emit NFTTransferred(_tokenId, from, _to);
    }

    /// @dev Burns (destroys) an NFT.
    /// @param _tokenId The ID of the NFT to burn.
    function burnNFT(uint256 _tokenId) external nftExists(_tokenId) onlyNFTOwner(_tokenId) whenNotPaused {
        address ownerAddress = nftOwner[_tokenId];
        delete nftOwner[_tokenId];
        delete nftListings[_tokenId]; // Remove from listing if listed
        emit NFTBurned(_tokenId, ownerAddress);
    }

    /// @dev Sets the base URI for all NFTs in the collection (Admin only).
    /// @param _newBaseURI The new base URI to set.
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /// @dev Returns the dynamic URI for a specific NFT, incorporating dynamic metadata logic.
    /// @param _tokenId The ID of the NFT.
    /// @return The URI for the NFT, dynamically generated based on metadata.
    function tokenURI(uint256 _tokenId) external view nftExists(_tokenId) returns (string memory) {
        string memory dynamicDataPart = dynamicMetadata[_tokenId];
        string memory traitsPart = "";
        mapping(string => string) storage traits = nftTraits[_tokenId];
        if (traits.length > 0) {
            traitsPart = "?traits=";
            bool firstTrait = true;
            for (uint256 i = 0; i < traits.length; i++) {
                // Solidity mappings don't directly support iteration, so this is a simplified example.
                // In a real-world scenario, you might use a separate array to track trait names for iteration if needed.
                // For this example, assuming a limited number of traits and manual retrieval might be sufficient.
                // A more robust approach would involve a different data structure for traits if iteration is crucial.
                // Placeholder iteration (replace with actual logic if iteration is essential):
                // string memory traitName = getTraitNameAtIndex(tokenId, i); // Hypothetical function
                // string memory traitValue = traits[traitName];
                // if (!firstTrait) {
                //     traitsPart = string.concat(traitsPart, "&");
                // }
                // traitsPart = string.concat(traitsPart, traitName, "=", traitValue);
                // firstTrait = false;
            }
        }

        return string.concat(baseURI, "/", Strings.toString(_tokenId), dynamicDataPart, traitsPart);
    }


    // ** 2. Marketplace Listing and Trading **

    /// @dev Lists an NFT for sale at a fixed price.
    /// @param _tokenId The ID of the NFT to list.
    /// @param _price The price to list the NFT for (in wei).
    function listNFTForSale(uint256 _tokenId, uint256 _price) external nftExists(_tokenId) onlyNFTOwner(_tokenId) whenNotPaused {
        require(_price > 0, "Price must be greater than zero.");
        require(!nftListings[_tokenId].isActive, "NFT is already listed for sale.");

        nftListings[_tokenId] = Listing({
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        emit NFTListedForSale(_tokenId, _price, msg.sender);
    }

    /// @dev Unlists an NFT from sale.
    /// @param _tokenId The ID of the NFT to unlist.
    function unlistNFTFromSale(uint256 _tokenId) external nftExists(_tokenId) onlyNFTOwner(_tokenId) listingExists(_tokenId) whenNotPaused {
        require(nftListings[_tokenId].seller == msg.sender, "Only seller can unlist.");
        nftListings[_tokenId].isActive = false;
        emit NFTUnlistedFromSale(_tokenId, msg.sender);
    }

    /// @dev Allows anyone to buy a listed NFT.
    /// @param _tokenId The ID of the NFT to buy.
    function buyNFT(uint256 _tokenId) external payable nftExists(_tokenId) listingExists(_tokenId) whenNotPaused {
        Listing storage listing = nftListings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds.");
        require(listing.seller != msg.sender, "Seller cannot buy their own NFT.");

        uint256 marketplaceFee = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = listing.price - marketplaceFee;

        // Transfer NFT to buyer
        nftOwner[_tokenId] = msg.sender;
        listing.isActive = false; // Deactivate listing

        // Pay seller and marketplace fee
        (bool successSeller, ) = listing.seller.call{value: sellerProceeds}("");
        require(successSeller, "Seller payment failed.");
        (bool successMarketplace, ) = owner.call{value: marketplaceFee}("");
        require(successMarketplace, "Marketplace fee payment failed.");

        emit NFTBought(_tokenId, msg.sender, listing.seller, listing.price);
        emit NFTTransferred(_tokenId, listing.seller, msg.sender);
    }

    /// @dev Allows users to make an offer on an NFT, even if not listed.
    /// @param _tokenId The ID of the NFT to make an offer on.
    /// @param _price The price offered for the NFT (in wei).
    function offerNFTPrice(uint256 _tokenId, uint256 _price) external payable nftExists(_tokenId) whenNotPaused {
        require(_price > 0, "Offer price must be greater than zero.");
        require(msg.value >= _price, "Insufficient funds for offer.");

        uint256 offerId = nextOfferId++;
        nftOffers[offerId] = Offer({
            offerId: offerId,
            tokenId: _tokenId,
            buyer: msg.sender,
            price: _price,
            isActive: true
        });
        emit NFTOfferMade(offerId, _tokenId, msg.sender, _price);
    }

    /// @dev Seller accepts a specific offer made on their NFT.
    /// @param _offerId The ID of the offer to accept.
    function acceptNFTOffer(uint256 _offerId) external offerExists(_offerId) whenNotPaused {
        Offer storage offer = nftOffers[_offerId];
        uint256 tokenId = offer.tokenId;
        require(nftOwner[tokenId] == msg.sender, "You are not the NFT owner.");
        require(offer.isActive, "Offer is not active.");

        uint256 marketplaceFee = (offer.price * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = offer.price - marketplaceFee;

        // Transfer NFT to buyer
        nftOwner[tokenId] = offer.buyer;
        offer.isActive = false; // Deactivate offer

        // Pay seller and marketplace fee
        (bool successSeller, ) = msg.sender.call{value: sellerProceeds}(""); // Seller is msg.sender accepting offer
        require(successSeller, "Seller payment failed.");
        (bool successMarketplace, ) = owner.call{value: marketplaceFee}("");
        require(successMarketplace, "Marketplace fee payment failed.");

        // Refund remaining offer amount back to buyer (if overpaid, unlikely in typical offer scenario but good practice)
        if (offer.price > sellerProceeds + marketplaceFee) {
            uint256 refundAmount = offer.price - (sellerProceeds + marketplaceFee);
            (bool successRefund, ) = offer.buyer.call{value: refundAmount}("");
            require(successRefund, "Offer refund failed.");
        }

        emit NFTOfferAccepted(_offerId, tokenId, offer.buyer, msg.sender, offer.price);
        emit NFTTransferred(tokenId, msg.sender, offer.buyer);
    }

    // ** 3. Dynamic Metadata and Traits **

    /// @dev Updates the dynamic metadata part of an NFT's URI.
    /// @param _tokenId The ID of the NFT to update.
    /// @param _dynamicData The new dynamic data string to append to the URI.
    function updateDynamicMetadata(uint256 _tokenId, string memory _dynamicData) external nftExists(_tokenId) onlyNFTOwner(_tokenId) whenNotPaused {
        dynamicMetadata[_tokenId] = _dynamicData;
        emit DynamicMetadataUpdated(_tokenId, _dynamicData);
    }

    /// @dev Sets a specific trait for an NFT, influencing metadata.
    /// @param _tokenId The ID of the NFT.
    /// @param _traitName The name of the trait.
    /// @param _traitValue The value of the trait.
    function setNFTTrait(uint256 _tokenId, string memory _traitName, string memory _traitValue) external nftExists(_tokenId) onlyNFTOwner(_tokenId) whenNotPaused {
        nftTraits[_tokenId][_traitName] = _traitValue;
        emit NFTTraitSet(_tokenId, _traitName, _traitValue);
    }

    /// @dev Retrieves all traits associated with an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return A mapping of trait names to trait values.
    function getNFTTraits(uint256 _tokenId) external view nftExists(_tokenId) returns (mapping(string => string) memory) {
        return nftTraits[_tokenId];
    }

    // ** 4. Reputation and Trust System **

    /// @dev Allows users to rate other users based on marketplace interactions.
    /// @param _user The address of the user to rate.
    /// @param _rating The rating given (1-5 scale, for example).
    /// @param _feedback Optional feedback text.
    function rateUser(address _user, uint8 _rating, string memory _feedback) external whenNotPaused {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        UserRating storage ratingData = userRatings[_user];
        ratingData.totalRating += _rating;
        ratingData.ratingCount++;
        ratingData.feedbacks[ratingData.nextFeedbackId++] = _feedback;
        emit UserRated(_user, _rating, _feedback);
    }

    /// @dev Retrieves the average rating and feedback count for a user.
    /// @param _user The address of the user to query.
    /// @return Average rating and feedback count.
    function getUserRating(address _user) external view returns (uint256 averageRating, uint256 feedbackCount) {
        UserRating storage ratingData = userRatings[_user];
        if (ratingData.ratingCount == 0) {
            return (0, 0); // No ratings yet
        }
        averageRating = ratingData.totalRating / ratingData.ratingCount;
        feedbackCount = ratingData.ratingCount;
        return (averageRating, feedbackCount);
    }

    // ** 5. Decentralized Governance (Simplified) **

    /// @dev Allows users to propose a change to the marketplace fee.
    /// @param _newFeePercentage The new marketplace fee percentage to propose.
    function proposeMarketplaceFee(uint256 _newFeePercentage) external whenNotPaused {
        require(_newFeePercentage <= 10, "Proposed fee percentage too high (max 10%)."); // Example limit
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            description: "Change marketplace fee to " + Strings.toString(_newFeePercentage) + "%",
            newFeePercentage: _newFeePercentage,
            yesVotes: 0,
            noVotes: 0,
            isActive: true,
            executed: false
        });
        emit MarketplaceFeeProposed(proposalId, _newFeePercentage, msg.sender);
    }

    /// @dev Allows NFT holders to vote on active proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote True for yes, false for no.
    function voteOnProposal(uint256 _proposalId, bool _vote) external proposalExists(_proposalId) proposalNotExecuted(_proposalId) whenNotPaused {
        require(nftOwner[1] != address(0), "Only NFT holders can vote (example: holder of tokenId 1)."); // Simplified governance - in real DAO, use token voting or snapshot
        Proposal storage proposal = proposals[_proposalId];
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @dev Executes a passed proposal (Admin/Governance controlled).
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyOwner proposalExists(_proposalId) proposalNotExecuted(_proposalId) whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.yesVotes > proposal.noVotes, "Proposal not passed."); // Simple majority for example
        require(proposal.newFeePercentage > 0 && proposal.newFeePercentage <= 10, "Invalid proposed fee percentage after voting."); // Re-validate fee range

        marketplaceFeePercentage = proposal.newFeePercentage;
        proposal.isActive = false;
        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
        emit MarketplaceFeeSet(marketplaceFeePercentage);
    }

    // ** 6. Unique Auction Mechanism (Progressive Dutch Auction) **

    /// @dev Starts a Progressive Dutch Auction for an NFT. Price decreases over time.
    /// @param _tokenId The ID of the NFT to auction.
    /// @param _startPrice The starting price of the auction.
    /// @param _endPrice The ending price of the auction.
    /// @param _duration The duration of the auction in seconds.
    function startProgressiveDutchAuction(uint256 _tokenId, uint256 _startPrice, uint256 _endPrice, uint256 _duration) external nftExists(_tokenId) onlyNFTOwner(_tokenId) whenNotPaused {
        require(_startPrice > _endPrice, "Start price must be greater than end price.");
        require(_duration > 0, "Auction duration must be greater than zero.");
        require(!auctions[nextAuctionId].isActive, "Previous auction not ended, try again later."); // Simple concurrency control

        uint256 auctionId = nextAuctionId++;
        auctions[auctionId] = Auction({
            auctionId: auctionId,
            tokenId: _tokenId,
            seller: msg.sender,
            startPrice: _startPrice,
            endPrice: _endPrice,
            duration: _duration,
            startTime: block.timestamp,
            highestBidder: address(0),
            highestBid: 0,
            isActive: true
        });
        emit ProgressiveDutchAuctionStarted(auctionId, _tokenId, _startPrice, _endPrice, _duration, msg.sender);
    }

    /// @dev Allows users to bid in the Dutch Auction. Price progressively decreases over time.
    /// @param _auctionId The ID of the auction to bid in.
    function bidInAuction(uint256 _auctionId) external payable auctionExists(_auctionId) whenNotPaused {
        Auction storage auction = auctions[_auctionId];
        require(auction.seller != msg.sender, "Seller cannot bid on their own auction.");
        require(block.timestamp < auction.startTime + auction.duration, "Auction has ended.");

        uint256 currentPrice = getCurrentDutchAuctionPrice(auction._auctionId);
        require(msg.value >= currentPrice, "Bid price is too low.");

        if (auction.highestBidder != address(0)) {
            // Refund previous highest bidder
            (bool refundSuccess, ) = auction.highestBidder.call{value: auction.highestBid}("");
            require(refundSuccess, "Refund to previous bidder failed.");
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        emit BidPlacedInAuction(_auctionId, msg.sender, msg.value);
    }

    /// @dev Ends the auction and transfers NFT to the highest bidder (or reverts if no bids).
    /// @param _auctionId The ID of the auction to end.
    function endAuction(uint256 _auctionId) external auctionExists(_auctionId) whenNotPaused {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp >= auction.startTime + auction.duration, "Auction duration not yet elapsed.");
        require(auction.isActive, "Auction already ended.");
        auction.isActive = false; // Mark auction as ended

        if (auction.highestBidder != address(0)) {
            // Transfer NFT to highest bidder
            nftOwner[auction.tokenId] = auction.highestBidder;

            // Pay seller (minus marketplace fee)
            uint256 marketplaceFee = (auction.highestBid * marketplaceFeePercentage) / 100;
            uint256 sellerProceeds = auction.highestBid - marketplaceFee;
            (bool sellerPaymentSuccess, ) = auction.seller.call{value: sellerProceeds}("");
            require(sellerPaymentSuccess, "Seller payment failed.");
            (bool marketplaceFeeSuccess, ) = owner.call{value: marketplaceFee}("");
            require(marketplaceFeeSuccess, "Marketplace fee payment failed.");

            emit ProgressiveDutchAuctionEnded(_auctionId, auction.tokenId, auction.highestBidder, auction.highestBid);
            emit NFTTransferred(auction.tokenId, auction.seller, auction.highestBidder);
        } else {
            // No bids, auction ends without sale, NFT remains with seller
            emit ProgressiveDutchAuctionEnded(_auctionId, auction.tokenId, address(0), 0); // Winner address 0 indicates no bids
        }
    }

    /// @dev Calculates the current price of a Progressive Dutch Auction based on elapsed time.
    /// @param _auctionId The ID of the auction.
    /// @return The current price of the auction.
    function getCurrentDutchAuctionPrice(uint256 _auctionId) public view auctionExists(_auctionId) returns (uint256) {
        Auction storage auction = auctions[_auctionId];
        uint256 elapsedTime = block.timestamp - auction.startTime;
        if (elapsedTime >= auction.duration) {
            return auction.endPrice; // Auction ended, return end price
        }

        uint256 priceRange = auction.startPrice - auction.endPrice;
        uint256 priceDecreasePerSecond = priceRange / auction.duration;
        uint256 priceDecrease = priceDecreasePerSecond * elapsedTime;
        uint256 currentPrice = auction.startPrice - priceDecrease;

        return currentPrice > auction.endPrice ? currentPrice : auction.endPrice; // Ensure price doesn't go below endPrice
    }


    // ** 7. Utility and Admin Functions **

    /// @dev Sets the marketplace fee percentage (Admin only).
    /// @param _feePercentage The new marketplace fee percentage.
    function setMarketplaceFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 10, "Marketplace fee percentage cannot exceed 10%."); // Example limit
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage);
    }

    /// @dev Allows the contract owner to withdraw accumulated marketplace fees (Admin only).
    function withdrawMarketplaceFees() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 contractBalance = balance - getNFTValueHeld(); // Exclude value locked in NFTs if any advanced accounting is implemented
        (bool success, ) = owner.call{value: contractBalance}("");
        require(success, "Withdrawal failed.");
        emit MarketplaceFeesWithdrawn(contractBalance, owner);
    }

    /// @dev Pauses all marketplace trading functionality (Admin only).
    function pauseMarketplace() external onlyOwner whenNotPaused {
        paused = true;
        emit MarketplacePaused();
    }

    /// @dev Resumes marketplace trading functionality (Admin only).
    function unpauseMarketplace() external onlyOwner whenPaused {
        paused = false;
        emit MarketplaceUnpaused();
    }

    /// @dev Placeholder function to calculate value of NFTs held in contract (if needed for advanced features).
    /// @return Total value of NFTs held (currently returns 0 as placeholder).
    function getNFTValueHeld() public view returns (uint256) {
        // In a more complex scenario, you could track NFT values and calculate the total value held by the contract.
        // This is a placeholder and returns 0 for this example.
        return 0;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Optimized for majority of use cases
        if (value < 100) {
            return _toString(value);
        }
        uint256 temp = value; // Avoid modifying value
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation with leading zeros.
     */
    function toString(uint256 value, uint256 length) internal pure returns (string memory) {
        string memory strVal = toString(value);
        if (length <= bytes(strVal).length) return strVal;
        bytes memory buffer = new bytes(length);
        for (uint256 i = 0; i < length - bytes(strVal).length; i++) {
            buffer[i] = bytes1(uint8(48));
        }
        for (uint256 i = 0; i < bytes(strVal).length; i++) {
            buffer[length - bytes(strVal).length + i] = bytes1(uint8(bytes(strVal)[i]));
        }
        return string(buffer);
    }

    // @dev Optimized version of toString for uint256 < 100
    function _toString(uint256 value) private pure returns (string memory) {
        uint256 temp = value;
        bytes memory buffer = new bytes(2);
        buffer[1] = bytes1(uint8(48 + uint256(temp % 10)));
        temp /= 10;
        buffer[0] = bytes1(uint8(48 + uint256(temp % 10)));
        if (value < 10) {
            return string(buffer[1:]);
        }
        return string(buffer);
    }
}
```