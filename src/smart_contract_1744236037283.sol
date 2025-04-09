```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI-Powered Recommendations
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized NFT marketplace with advanced features,
 * including dynamic NFTs, AI-powered recommendations (conceptually integrated),
 * reputation system, and various marketplace functionalities.
 *
 * Function Summary:
 *
 * --- NFT Management ---
 * 1. mintDynamicNFT: Mints a new dynamic NFT with initial metadata and dynamic data.
 * 2. updateDynamicNFTData: Updates the dynamic data of an existing NFT (can be triggered by oracle/AI).
 * 3. getNFTMetadata: Retrieves the static metadata URI of an NFT.
 * 4. getDynamicNFTData: Retrieves the dynamic data of an NFT.
 * 5. transferNFT: Transfers ownership of an NFT.
 * 6. burnNFT: Burns (destroys) an NFT.
 * 7. isDynamicNFT: Checks if an NFT is a dynamic NFT.
 *
 * --- Marketplace Functionality ---
 * 8. listItemForSale: Lists an NFT for sale at a fixed price.
 * 9. buyNFT: Allows a user to purchase an NFT listed for sale.
 * 10. cancelListing: Cancels an NFT listing, removing it from sale.
 * 11. createAuction: Creates an auction for an NFT with a starting price and duration.
 * 12. bidOnAuction: Allows users to bid on an active auction.
 * 13. endAuction: Ends an auction and transfers the NFT to the highest bidder.
 * 14. makeOffer: Allows a user to make a direct offer on an NFT (even if not listed).
 * 15. acceptOffer: Allows the NFT owner to accept a direct offer.
 * 16. withdrawFunds: Allows sellers to withdraw their earnings from sales and auctions.
 * 17. getListingDetails: Retrieves details of an NFT listing.
 * 18. getAuctionDetails: Retrieves details of an NFT auction.
 * 19. getUserOffers: Retrieves offers made by a specific user.
 *
 * --- AI Recommendation Integration (Conceptual) ---
 * 20. requestNFTRecommendation: Allows a user to request NFT recommendations (triggers off-chain AI process via event).
 * 21. storeNFTRecommendationResult: Allows the platform admin (or trusted oracle) to store AI recommendation results on-chain.
 *
 * --- Reputation System (Basic) ---
 * 22. addReputation: Allows admin to add reputation points to a user (e.g., for positive marketplace interactions).
 * 23. getReputation: Retrieves the reputation score of a user.
 *
 * --- Utility & Admin ---
 * 24. setPlatformFee: Sets the platform fee percentage for sales.
 * 25. getPlatformFee: Retrieves the current platform fee percentage.
 * 26. pauseContract: Pauses the contract, disabling critical functions (admin only).
 * 27. unpauseContract: Unpauses the contract, re-enabling functions (admin only).
 * 28. withdrawPlatformFees: Allows the platform owner to withdraw accumulated platform fees.
 */
contract DynamicNFTMarketplaceAI {
    // --- State Variables ---
    address public owner;
    uint256 public platformFeePercentage = 2; // 2% platform fee by default
    bool public paused = false;

    uint256 public nextNFTId = 1;
    mapping(uint256 => address) public nftOwner;
    mapping(uint256 => string) public nftMetadataURI; // Static metadata
    mapping(uint256 => string) public dynamicNFTData; // Dynamic data (can be updated)
    mapping(uint256 => bool) public isNFTDynamicToken;

    struct NFTListing {
        uint256 tokenId;
        uint256 price;
        address seller;
        bool isActive;
    }
    mapping(uint256 => NFTListing) public nftListings;

    struct Auction {
        uint256 tokenId;
        uint256 startingPrice;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        address seller;
        bool isActive;
    }
    mapping(uint256 => Auction) public nftAuctions;
    uint256 public nextAuctionId = 1;

    struct Offer {
        uint256 offerId;
        uint256 tokenId;
        uint256 amount;
        address buyer;
        bool isActive;
    }
    mapping(uint256 => Offer) public nftOffers;
    uint256 public nextOfferId = 1;

    mapping(address => uint256) public userReputation;
    mapping(address => uint256[]) public userRecommendations; // Stores recommended NFT tokenIds per user

    // --- Events ---
    event NFTMinted(uint256 tokenId, address owner, string metadataURI, string dynamicData, bool isDynamic);
    event DynamicNFTDataUpdated(uint256 tokenId, string newDynamicData);
    event NFTListed(uint256 listingId, uint256 tokenId, uint256 price, address seller);
    event NFTBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event ListingCancelled(uint256 listingId, uint256 tokenId);
    event AuctionCreated(uint256 auctionId, uint256 tokenId, uint256 startingPrice, uint256 endTime, address seller);
    event BidPlaced(uint256 auctionId, uint256 tokenId, address bidder, uint256 amount);
    event AuctionEnded(uint256 auctionId, uint256 tokenId, address winner, uint256 finalPrice);
    event OfferMade(uint256 offerId, uint256 tokenId, uint256 amount, address buyer);
    event OfferAccepted(uint256 offerId, uint256 tokenId, address seller, address buyer, uint256 price);
    event FundsWithdrawn(address seller, uint256 amount);
    event RecommendationRequested(address user, string userPreferences);
    event RecommendationStored(address user, uint256[] recommendedTokenIds);
    event ReputationAdded(address user, uint256 points);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event PlatformFeeUpdated(uint256 newFeePercentage);
    event PlatformFeesWithdrawn(address admin, uint256 amount);


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
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

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(nftOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
    }

    // --- NFT Management Functions ---

    /// @notice Mints a new dynamic NFT.
    /// @param _metadataURI URI for static NFT metadata.
    /// @param _initialDynamicData Initial dynamic data string for the NFT.
    function mintDynamicNFT(string memory _metadataURI, string memory _initialDynamicData) external whenNotPaused {
        uint256 tokenId = nextNFTId++;
        nftOwner[tokenId] = msg.sender;
        nftMetadataURI[tokenId] = _metadataURI;
        dynamicNFTData[tokenId] = _initialDynamicData;
        isNFTDynamicToken[tokenId] = true;
        emit NFTMinted(tokenId, msg.sender, _metadataURI, _initialDynamicData, true);
    }

    /// @notice Mints a standard NFT (non-dynamic).
    /// @param _metadataURI URI for static NFT metadata.
    function mintNFT(string memory _metadataURI) external whenNotPaused {
        uint256 tokenId = nextNFTId++;
        nftOwner[tokenId] = msg.sender;
        nftMetadataURI[tokenId] = _metadataURI;
        isNFTDynamicToken[tokenId] = false;
        emit NFTMinted(tokenId, msg.sender, _metadataURI, "", false);
    }


    /// @notice Updates the dynamic data of an existing dynamic NFT.
    /// @dev Can be triggered by an oracle or AI service (off-chain logic).
    /// @param _tokenId ID of the NFT to update.
    /// @param _newDynamicData New dynamic data string.
    function updateDynamicNFTData(uint256 _tokenId, string memory _newDynamicData) external whenNotPaused {
        require(isNFTDynamicToken[_tokenId], "NFT is not dynamic.");
        require(msg.sender == owner || msg.sender == nftOwner[_tokenId], "Only owner or NFT owner can update dynamic data (or trusted oracle)."); // Example: Owner can act as oracle for simplicity
        dynamicNFTData[_tokenId] = _newDynamicData;
        emit DynamicNFTDataUpdated(_tokenId, _newDynamicData);
    }

    /// @notice Retrieves the static metadata URI of an NFT.
    /// @param _tokenId ID of the NFT.
    /// @return The metadata URI string.
    function getNFTMetadata(uint256 _tokenId) external view returns (string memory) {
        return nftMetadataURI[_tokenId];
    }

    /// @notice Retrieves the dynamic data of an NFT.
    /// @param _tokenId ID of the NFT.
    /// @return The dynamic data string.
    function getDynamicNFTData(uint256 _tokenId) external view returns (string memory) {
        return dynamicNFTData[_tokenId];
    }

    /// @notice Transfers ownership of an NFT.
    /// @param _to Address of the recipient.
    /// @param _tokenId ID of the NFT to transfer.
    function transferNFT(address _to, uint256 _tokenId) external whenNotPaused onlyNFTOwner(_tokenId) {
        require(_to != address(0), "Invalid recipient address.");
        nftOwner[_tokenId] = _to;
        // Consider adding event for NFT transfer if needed for more detailed tracking.
    }

    /// @notice Burns (destroys) an NFT.
    /// @param _tokenId ID of the NFT to burn.
    function burnNFT(uint256 _tokenId) external whenNotPaused onlyNFTOwner(_tokenId) {
        delete nftOwner[_tokenId];
        delete nftMetadataURI[_tokenId];
        delete dynamicNFTData[_tokenId];
        delete isNFTDynamicToken[_tokenId];
        delete nftListings[_tokenId]; // Remove from listing if listed
        delete nftAuctions[_tokenId];  // Remove from auction if in auction
        // Consider emitting event for NFT burn.
    }

    /// @notice Checks if an NFT is a dynamic NFT.
    /// @param _tokenId ID of the NFT.
    /// @return True if dynamic, false otherwise.
    function isDynamicNFT(uint256 _tokenId) external view returns (bool) {
        return isNFTDynamicToken[_tokenId];
    }


    // --- Marketplace Functionality ---

    /// @notice Lists an NFT for sale at a fixed price.
    /// @param _tokenId ID of the NFT to list.
    /// @param _price Sale price in wei.
    function listItemForSale(uint256 _tokenId, uint256 _price) external whenNotPaused onlyNFTOwner(_tokenId) {
        require(nftListings[_tokenId].tokenId == 0 || !nftListings[_tokenId].isActive, "NFT is already listed or in auction."); // Prevent relisting if already active
        require(nftAuctions[_tokenId].tokenId == 0 || !nftAuctions[_tokenId].isActive, "NFT is already in auction or listed.");
        nftListings[_tokenId] = NFTListing({
            tokenId: _tokenId,
            price: _price,
            seller: msg.sender,
            isActive: true
        });
        emit NFTListed(nftListings[_tokenId].tokenId, _tokenId, _price, msg.sender);
    }

    /// @notice Allows a user to purchase an NFT listed for sale.
    /// @param _tokenId ID of the NFT to buy.
    function buyNFT(uint256 _tokenId) external payable whenNotPaused {
        require(nftListings[_tokenId].isActive, "NFT is not listed for sale.");
        require(msg.value >= nftListings[_tokenId].price, "Insufficient funds sent.");

        uint256 platformFee = (nftListings[_tokenId].price * platformFeePercentage) / 100;
        uint256 sellerAmount = nftListings[_tokenId].price - platformFee;

        nftListings[_tokenId].isActive = false; // Deactivate listing
        address seller = nftListings[_tokenId].seller;
        nftOwner[_tokenId] = msg.sender; // Transfer ownership

        payable(seller).transfer(sellerAmount);
        payable(owner).transfer(platformFee); // Platform fee goes to owner

        emit NFTBought(nftListings[_tokenId].tokenId, _tokenId, msg.sender, nftListings[_tokenId].price);
    }

    /// @notice Cancels an NFT listing, removing it from sale.
    /// @param _tokenId ID of the NFT listing to cancel.
    function cancelListing(uint256 _tokenId) external whenNotPaused onlyNFTOwner(_tokenId) {
        require(nftListings[_tokenId].isActive, "NFT is not currently listed.");
        nftListings[_tokenId].isActive = false;
        emit ListingCancelled(nftListings[_tokenId].tokenId, _tokenId);
    }

    /// @notice Creates an auction for an NFT.
    /// @param _tokenId ID of the NFT to auction.
    /// @param _startingPrice Starting bid price in wei.
    /// @param _duration Auction duration in seconds.
    function createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _duration) external whenNotPaused onlyNFTOwner(_tokenId) {
        require(nftListings[_tokenId].tokenId == 0 || !nftListings[_tokenId].isActive, "NFT is already listed or in auction."); // Prevent auction if already listed/auctioned
        require(nftAuctions[_tokenId].tokenId == 0 || !nftAuctions[_tokenId].isActive, "NFT is already in auction or listed.");
        require(_duration > 0, "Auction duration must be greater than 0.");

        nftAuctions[nextAuctionId] = Auction({
            auctionId: nextAuctionId,
            tokenId: _tokenId,
            startingPrice: _startingPrice,
            endTime: block.timestamp + _duration,
            highestBidder: address(0),
            highestBid: 0,
            seller: msg.sender,
            isActive: true
        });
        emit AuctionCreated(nextAuctionId, _tokenId, _startingPrice, block.timestamp + _duration, msg.sender);
        nextAuctionId++;
    }

    /// @notice Allows users to bid on an active auction.
    /// @param _auctionId ID of the auction to bid on.
    function bidOnAuction(uint256 _auctionId) external payable whenNotPaused {
        require(nftAuctions[_auctionId].isActive, "Auction is not active.");
        require(block.timestamp < nftAuctions[_auctionId].endTime, "Auction has ended.");
        require(msg.value > nftAuctions[_auctionId].highestBid, "Bid amount is too low.");

        if (nftAuctions[_auctionId].highestBidder != address(0)) {
            payable(nftAuctions[_auctionId].highestBidder).transfer(nftAuctions[_auctionId].highestBid); // Refund previous bidder
        }

        nftAuctions[_auctionId].highestBidder = msg.sender;
        nftAuctions[_auctionId].highestBid = msg.value;
        emit BidPlaced(_auctionId, nftAuctions[_auctionId].tokenId, msg.sender, msg.value);
    }

    /// @notice Ends an auction and transfers the NFT to the highest bidder.
    /// @param _auctionId ID of the auction to end.
    function endAuction(uint256 _auctionId) external whenNotPaused {
        require(nftAuctions[_auctionId].isActive, "Auction is not active.");
        require(block.timestamp >= nftAuctions[_auctionId].endTime, "Auction is not yet ended.");
        nftAuctions[_auctionId].isActive = false;

        address winner = nftAuctions[_auctionId].highestBidder;
        uint256 finalPrice = nftAuctions[_auctionId].highestBid;
        address seller = nftAuctions[_auctionId].seller;
        uint256 tokenId = nftAuctions[_auctionId].tokenId;

        if (winner != address(0)) {
            uint256 platformFee = (finalPrice * platformFeePercentage) / 100;
            uint256 sellerAmount = finalPrice - platformFee;

            nftOwner[tokenId] = winner; // Transfer ownership
            payable(seller).transfer(sellerAmount);
            payable(owner).transfer(platformFee);
            emit AuctionEnded(_auctionId, tokenId, winner, finalPrice);
        } else {
            // No bids, return NFT to seller (or handle as needed - e.g., relist, destroy)
            nftOwner[tokenId] = seller; // Return to seller if no bids
            // Consider emitting event for auction ended with no bids.
        }
    }

    /// @notice Allows a user to make a direct offer on an NFT (even if not listed).
    /// @param _tokenId ID of the NFT to make an offer on.
    /// @param _amount Offer amount in wei.
    function makeOffer(uint256 _tokenId, uint256 _amount) external payable whenNotPaused {
        require(msg.value >= _amount, "Insufficient funds sent for offer.");
        nftOffers[nextOfferId] = Offer({
            offerId: nextOfferId,
            tokenId: _tokenId,
            amount: _amount,
            buyer: msg.sender,
            isActive: true
        });
        emit OfferMade(nextOfferId, _tokenId, _amount, msg.sender);
        nextOfferId++;
    }

    /// @notice Allows the NFT owner to accept a direct offer.
    /// @param _offerId ID of the offer to accept.
    function acceptOffer(uint256 _offerId) external payable whenNotPaused {
        Offer storage offer = nftOffers[_offerId];
        require(offer.isActive, "Offer is not active or does not exist.");
        require(nftOwner[offer.tokenId] == msg.sender, "You are not the owner of this NFT.");

        uint256 platformFee = (offer.amount * platformFeePercentage) / 100;
        uint256 sellerAmount = offer.amount - platformFee;

        offer.isActive = false; // Deactivate offer
        address buyer = offer.buyer;
        uint256 tokenId = offer.tokenId;

        nftOwner[tokenId] = buyer; // Transfer ownership
        payable(msg.sender).transfer(sellerAmount); // Seller receives funds
        payable(owner).transfer(platformFee); // Platform fee to owner

        emit OfferAccepted(_offerId, tokenId, msg.sender, buyer, offer.amount);
    }

    /// @notice Allows sellers to withdraw their earnings from sales and auctions.
    function withdrawFunds() external payable whenNotPaused {
        // In a real marketplace, you'd track individual user balances.
        // For simplicity in this example, assume funds are directly transferred on sale/auction end.
        // This function might be for withdrawing platform fees by the owner, or more complex scenarios.
        // In a real application, consider tracking balances and withdrawal requests.
        // This function is a placeholder for more advanced withdrawal logic if needed.
        // For this example, we will just allow owner to withdraw platform fees via withdrawPlatformFees.
        revert("Withdrawal logic for individual sellers not implemented in this example. Funds are directly transferred on sale/auction end.");
    }

    /// @notice Retrieves details of an NFT listing.
    /// @param _tokenId ID of the NFT.
    /// @return Listing details (price, seller, isActive).
    function getListingDetails(uint256 _tokenId) external view returns (uint256 price, address seller, bool isActive) {
        NFTListing storage listing = nftListings[_tokenId];
        return (listing.price, listing.seller, listing.isActive);
    }

    /// @notice Retrieves details of an NFT auction.
    /// @param _auctionId ID of the auction.
    /// @return Auction details (starting price, end time, highest bidder, highest bid, seller, isActive).
    function getAuctionDetails(uint256 _auctionId) external view returns (uint256 startingPrice, uint256 endTime, address highestBidder, uint256 highestBid, address seller, bool isActive) {
        Auction storage auction = nftAuctions[_auctionId];
        return (auction.startingPrice, auction.endTime, auction.highestBidder, auction.highestBid, auction.seller, auction.isActive);
    }

    /// @notice Retrieves offers made by a specific user.
    /// @param _userAddress Address of the user.
    /// @return Array of offer IDs made by the user.
    function getUserOffers(address _userAddress) external view returns (uint256[] memory) {
        uint256[] memory offerIds = new uint256[](nextOfferId); // Overestimate size, will filter later
        uint256 count = 0;
        for (uint256 i = 1; i < nextOfferId; i++) {
            if (nftOffers[i].buyer == _userAddress && nftOffers[i].isActive) {
                offerIds[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of offers
        uint256[] memory resultOfferIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resultOfferIds[i] = offerIds[i];
        }
        return resultOfferIds;
    }


    // --- AI Recommendation Integration (Conceptual) ---

    /// @notice Allows a user to request NFT recommendations based on preferences.
    /// @dev This function emits an event that can be listened to by an off-chain AI service.
    ///      The AI service would process the request and then call storeNFTRecommendationResult.
    /// @param _userPreferences String describing user preferences (e.g., "abstract art", "sci-fi games").
    function requestNFTRecommendation(string memory _userPreferences) external whenNotPaused {
        emit RecommendationRequested(msg.sender, _userPreferences);
    }

    /// @notice Allows the platform admin (or trusted oracle) to store AI recommendation results on-chain.
    /// @dev This function is called by an authorized entity after processing the recommendation request off-chain.
    /// @param _user Address of the user who requested recommendations.
    /// @param _recommendedTokenIds Array of NFT token IDs recommended by the AI.
    function storeNFTRecommendationResult(address _user, uint256[] memory _recommendedTokenIds) external onlyOwner whenNotPaused { // Owner acts as trusted entity for demo
        userRecommendations[_user] = _recommendedTokenIds;
        emit RecommendationStored(_user, _recommendedTokenIds);
    }

    /// @notice Retrieves the AI recommendations for a user (if any have been stored).
    /// @param _user Address of the user.
    /// @return Array of recommended NFT token IDs.
    function getUserRecommendations(address _user) external view returns (uint256[] memory) {
        return userRecommendations[_user];
    }


    // --- Reputation System (Basic) ---

    /// @notice Adds reputation points to a user. (Admin function)
    /// @param _user Address of the user to add reputation to.
    /// @param _points Number of reputation points to add.
    function addReputation(address _user, uint256 _points) external onlyOwner whenNotPaused {
        userReputation[_user] += _points;
        emit ReputationAdded(_user, _points);
    }

    /// @notice Retrieves the reputation score of a user.
    /// @param _user Address of the user.
    /// @return Reputation score.
    function getReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }


    // --- Utility & Admin Functions ---

    /// @notice Sets the platform fee percentage for marketplace sales. (Admin function)
    /// @param _newFeePercentage New platform fee percentage (e.g., 2 for 2%).
    function setPlatformFee(uint256 _newFeePercentage) external onlyOwner whenNotPaused {
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100%.");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeUpdated(_newFeePercentage);
    }

    /// @notice Retrieves the current platform fee percentage.
    /// @return The current platform fee percentage.
    function getPlatformFee() external view returns (uint256) {
        return platformFeePercentage;
    }

    /// @notice Pauses the contract, disabling critical functions. (Admin function)
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses the contract, re-enabling functions. (Admin function)
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Allows the platform owner to withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyOwner whenNotPaused {
        uint256 balance = address(this).balance;
        uint256 contractBalanceWithoutFees = 0; // In a real app, track funds separately if needed.
        uint256 withdrawableFees = balance - contractBalanceWithoutFees; // Simple calculation, adjust if needed.

        payable(owner).transfer(withdrawableFees);
        emit PlatformFeesWithdrawn(msg.sender, withdrawableFees);
    }

    // Fallback function to receive Ether (for buyNFT, bidOnAuction, makeOffer)
    receive() external payable {}
}
```