```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI-Powered Recommendations and Gamified Interactions
 * @author Bard (Google AI)
 * @dev This smart contract implements a decentralized NFT marketplace with dynamic NFTs,
 * AI-powered recommendation simulation, gamified user interactions, and advanced features.
 *
 * **Outline and Function Summary:**
 *
 * **1. NFT Management:**
 *    - `mintDynamicNFT(string memory _baseURI, string memory _initialMetadata)`: Mints a new Dynamic NFT.
 *    - `updateNFTMetadata(uint256 _tokenId, string memory _newMetadata)`: Updates the metadata of a Dynamic NFT (dynamic aspect).
 *    - `transferNFT(address _to, uint256 _tokenId)`: Transfers ownership of an NFT.
 *    - `burnNFT(uint256 _tokenId)`: Burns an NFT, permanently removing it.
 *    - `exists(uint256 _tokenId)`: Checks if an NFT with a given ID exists.
 *    - `ownerOf(uint256 _tokenId)`: Returns the owner of a given NFT.
 *    - `tokenURI(uint256 _tokenId)`: Returns the URI for the metadata of a given NFT.
 *
 * **2. Marketplace Operations:**
 *    - `listItem(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale on the marketplace.
 *    - `delistItem(uint256 _tokenId)`: Removes an NFT listing from the marketplace.
 *    - `buyNFT(uint256 _tokenId)`: Allows anyone to buy a listed NFT.
 *    - `offerBid(uint256 _tokenId, uint256 _bidPrice)`: Allows users to place bids on NFTs.
 *    - `acceptBid(uint256 _tokenId, uint256 _bidId)`: Seller accepts a specific bid for their NFT.
 *    - `cancelBid(uint256 _tokenId, uint256 _bidId)`: Bidder can cancel their bid before it's accepted.
 *    - `getListingPrice(uint256 _tokenId)`: Retrieves the listing price of an NFT (if listed).
 *    - `isListed(uint256 _tokenId)`: Checks if an NFT is currently listed for sale.
 *
 * **3. User Profile and Reputation:**
 *    - `createUserProfile(string memory _username)`: Creates a user profile with a username.
 *    - `updateUserProfile(string memory _newUsername)`: Updates the username of the user profile.
 *    - `rateSeller(address _seller, uint8 _rating)`: Allows buyers to rate sellers after a purchase.
 *    - `getSellerRating(address _seller)`: Retrieves the average rating of a seller.
 *
 * **4. AI Recommendation Simulation (Simplified):**
 *    - `requestNFTRecommendations(address _userAddress)`: Simulates a request for NFT recommendations based on user address (in a real system, this would trigger an off-chain AI service).
 *    - `applyRecommendationBoost(uint256 _tokenId, uint256 _boostPercentage)`:  Simulates applying a recommendation boost to an NFT (e.g., increases visibility, temporary price adjustment - for demonstration).
 *
 * **5. Gamified Interactions and Rewards:**
 *    - `earnPointsForListing(uint256 _tokenId)`: Awards points to users for listing NFTs.
 *    - `earnPointsForBuying(uint256 _tokenId)`: Awards points to users for buying NFTs.
 *    - `redeemPointsForDiscount(uint256 _pointsToRedeem)`: Allows users to redeem points for marketplace discounts.
 *    - `checkUserPoints(address _userAddress)`:  Allows users to check their accumulated points.
 *
 * **6. Utility and Admin Functions:**
 *    - `setMarketplaceFee(uint256 _newFeePercentage)`: Admin function to set the marketplace fee percentage.
 *    - `withdrawMarketplaceFees()`: Admin function to withdraw accumulated marketplace fees.
 *    - `pauseContract()`: Admin function to pause the contract for maintenance.
 *    - `unpauseContract()`: Admin function to unpause the contract.
 */

contract DynamicNFTMarketplace {
    // --- Data Structures ---

    struct NFT {
        uint256 tokenId;
        address owner;
        string baseURI;
        string metadata;
    }

    struct Listing {
        uint256 tokenId;
        uint256 price;
        address seller;
        bool isActive;
    }

    struct Bid {
        uint256 bidId;
        uint256 tokenId;
        address bidder;
        uint256 bidPrice;
        bool isActive;
    }

    struct UserProfile {
        string username;
        uint256 points;
        uint256 ratingCount;
        uint256 totalRating;
    }

    // --- State Variables ---

    mapping(uint256 => NFT) public NFTs; // tokenId => NFT details
    mapping(uint256 => Listing) public listings; // tokenId => Listing details
    mapping(uint256 => mapping(uint256 => Bid)) public bids; // tokenId => (bidId => Bid details)
    mapping(address => UserProfile) public userProfiles; // userAddress => UserProfile details
    mapping(uint256 => address) public nftOwner; // tokenId => owner address
    mapping(address => uint256[]) public tokensOfOwner; // owner address => array of tokenIds
    mapping(uint256 => bool) public nftExists; // tokenId => exists or not

    uint256 public nextNFTId = 1;
    uint256 public nextBidId = 1;
    uint256 public marketplaceFeePercentage = 2; // 2% marketplace fee
    address public admin;
    bool public paused = false;

    // --- Events ---

    event NFTMinted(uint256 tokenId, address owner);
    event NFTMetadataUpdated(uint256 tokenId, string newMetadata);
    event NFTListed(uint256 tokenId, uint256 price, address seller);
    event NFTDelisted(uint256 tokenId, address seller);
    event NFTSold(uint256 tokenId, address buyer, address seller, uint256 price);
    event BidPlaced(uint256 tokenId, uint256 bidId, address bidder, uint256 bidPrice);
    event BidAccepted(uint256 tokenId, uint256 bidId, address seller, address bidder, uint256 price);
    event BidCancelled(uint256 tokenId, uint256 bidId, address bidder);
    event UserProfileCreated(address userAddress, string username);
    event UserProfileUpdated(address userAddress, string newUsername);
    event SellerRated(address seller, address rater, uint8 rating);
    event PointsEarned(address userAddress, string reason, uint256 points);
    event PointsRedeemed(address userAddress, uint256 pointsRedeemed, uint256 discountApplied);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event MarketplaceFeeSet(uint256 newFeePercentage, address admin);
    event FeesWithdrawn(address admin, uint256 amount);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
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

    modifier nftExistsCheck(uint256 _tokenId) {
        require(nftExists[_tokenId], "NFT does not exist.");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(nftOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        _;
    }

    modifier listingExists(uint256 _tokenId) {
        require(listings[_tokenId].isActive, "NFT is not listed for sale.");
        _;
    }

    modifier listingNotExists(uint256 _tokenId) {
        require(!listings[_tokenId].isActive, "NFT is already listed for sale.");
        _;
    }

    modifier bidExists(uint256 _tokenId, uint256 _bidId) {
        require(bids[_tokenId][_bidId].isActive, "Bid does not exist or is inactive.");
        _;
    }

    modifier bidNotExists(uint256 _tokenId, uint256 _bidId) {
        require(!bids[_tokenId][_bidId].isActive, "Bid already exists or is active."); // Potentially redundant, but clarifies intent
        _;
    }


    // --- Constructor ---

    constructor() {
        admin = msg.sender;
    }

    // --- 1. NFT Management Functions ---

    /// @notice Mints a new Dynamic NFT.
    /// @param _baseURI The base URI for the NFT metadata.
    /// @param _initialMetadata Initial metadata string for the NFT.
    function mintDynamicNFT(string memory _baseURI, string memory _initialMetadata) public whenNotPaused returns (uint256) {
        uint256 tokenId = nextNFTId++;
        NFTs[tokenId] = NFT(tokenId, msg.sender, _baseURI, _initialMetadata);
        nftOwner[tokenId] = msg.sender;
        tokensOfOwner[msg.sender].push(tokenId);
        nftExists[tokenId] = true;
        emit NFTMinted(tokenId, msg.sender);
        return tokenId;
    }

    /// @notice Updates the metadata of a Dynamic NFT. Only owner can update.
    /// @param _tokenId The ID of the NFT to update.
    /// @param _newMetadata The new metadata string.
    function updateNFTMetadata(uint256 _tokenId, string memory _newMetadata) public whenNotPaused nftExistsCheck(_tokenId) onlyNFTOwner(_tokenId) {
        NFTs[_tokenId].metadata = _newMetadata;
        emit NFTMetadataUpdated(_tokenId, _newMetadata);
    }

    /// @notice Transfers ownership of an NFT.
    /// @param _to The address to transfer the NFT to.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferNFT(address _to, uint256 _tokenId) public whenNotPaused nftExistsCheck(_tokenId) onlyNFTOwner(_tokenId) {
        require(_to != address(0), "Invalid recipient address.");
        address currentOwner = nftOwner[_tokenId];

        // Remove tokenId from sender's token list
        uint256[] storage senderTokens = tokensOfOwner[currentOwner];
        for (uint256 i = 0; i < senderTokens.length; i++) {
            if (senderTokens[i] == _tokenId) {
                senderTokens[i] = senderTokens[senderTokens.length - 1];
                senderTokens.pop();
                break;
            }
        }

        // Add tokenId to receiver's token list
        tokensOfOwner[_to].push(_tokenId);
        nftOwner[_tokenId] = _to;
        NFTs[_tokenId].owner = _to;

        // Deactivate listing if it exists
        if (listings[_tokenId].isActive) {
            listings[_tokenId].isActive = false;
        }

        // Deactivate all bids for this NFT
        for (uint256 i = 1; i < nextBidId; i++) { // Iterate through potential bidIds (simplified for example, could be optimized)
            if (bids[_tokenId][i].isActive) {
                bids[_tokenId][i].isActive = false;
            }
        }

        // Consider emitting a generic Transfer event if needed for compatibility with standards.
        // For this example, we are focusing on marketplace specific events.
    }

    /// @notice Burns an NFT, permanently removing it. Only owner can burn.
    /// @param _tokenId The ID of the NFT to burn.
    function burnNFT(uint256 _tokenId) public whenNotPaused nftExistsCheck(_tokenId) onlyNFTOwner(_tokenId) {
        address currentOwner = nftOwner[_tokenId];

        // Remove tokenId from sender's token list
        uint256[] storage senderTokens = tokensOfOwner[currentOwner];
        for (uint256 i = 0; i < senderTokens.length; i++) {
            if (senderTokens[i] == _tokenId) {
                senderTokens[i] = senderTokens[senderTokens.length - 1];
                senderTokens.pop();
                break;
            }
        }

        delete NFTs[_tokenId];
        delete nftOwner[_tokenId];
        delete nftExists[_tokenId];

        // Deactivate listing if it exists
        if (listings[_tokenId].isActive) {
            listings[_tokenId].isActive = false;
        }
        // Deactivate all bids for this NFT
        for (uint256 i = 1; i < nextBidId; i++) { // Iterate through potential bidIds (simplified for example, could be optimized)
            if (bids[_tokenId][i].isActive) {
                bids[_tokenId][i].isActive = false;
            }
        }

        // Consider emitting a generic Burn event if needed for compatibility with standards.
        // For this example, we are focusing on marketplace specific events.
    }

    /// @notice Checks if an NFT with a given ID exists.
    /// @param _tokenId The ID of the NFT to check.
    /// @return True if the NFT exists, false otherwise.
    function exists(uint256 _tokenId) public view returns (bool) {
        return nftExists[_tokenId];
    }

    /// @notice Returns the owner of a given NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The address of the NFT owner.
    function ownerOf(uint256 _tokenId) public view nftExistsCheck(_tokenId) returns (address) {
        return nftOwner[_tokenId];
    }

    /// @notice Returns the URI for the metadata of a given NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The metadata URI string.
    function tokenURI(uint256 _tokenId) public view nftExistsCheck(_tokenId) returns (string memory) {
        return string(abi.encodePacked(NFTs[_tokenId].baseURI, NFTs[_tokenId].metadata)); // Simple concatenation, adjust as needed for URI structure
    }


    // --- 2. Marketplace Operations Functions ---

    /// @notice Lists an NFT for sale on the marketplace. Only NFT owner can list.
    /// @param _tokenId The ID of the NFT to list.
    /// @param _price The listing price in wei.
    function listItem(uint256 _tokenId, uint256 _price) public whenNotPaused nftExistsCheck(_tokenId) onlyNFTOwner(_tokenId) listingNotExists(_tokenId) {
        require(_price > 0, "Price must be greater than zero.");
        require(nftOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");

        listings[_tokenId] = Listing(_tokenId, _price, msg.sender, true);
        emit NFTListed(_tokenId, _price, msg.sender);
        earnPointsForListing(_tokenId); // Gamification: Earn points for listing
    }

    /// @notice Removes an NFT listing from the marketplace. Only seller can delist.
    /// @param _tokenId The ID of the NFT to delist.
    function delistItem(uint256 _tokenId) public whenNotPaused nftExistsCheck(_tokenId) onlyNFTOwner(_tokenId) listingExists(_tokenId) {
        require(listings[_tokenId].seller == msg.sender, "You are not the seller of this NFT.");
        listings[_tokenId].isActive = false;
        emit NFTDelisted(_tokenId, msg.sender);
    }

    /// @notice Allows anyone to buy a listed NFT.
    /// @param _tokenId The ID of the NFT to buy.
    function buyNFT(uint256 _tokenId) public payable whenNotPaused nftExistsCheck(_tokenId) listingExists(_tokenId) {
        Listing storage currentListing = listings[_tokenId];
        require(msg.value >= currentListing.price, "Insufficient funds to buy NFT.");
        require(currentListing.seller != msg.sender, "Seller cannot buy their own NFT.");

        uint256 sellerProceeds = (currentListing.price * (100 - marketplaceFeePercentage)) / 100;
        uint256 marketplaceFees = currentListing.price - sellerProceeds;

        // Transfer funds to seller
        (bool successSeller, ) = payable(currentListing.seller).call{value: sellerProceeds}("");
        require(successSeller, "Seller payment failed.");

        // Transfer marketplace fees to admin (contract balance) - can be withdrawn later
        (bool successMarketplace, ) = payable(address(this)).call{value: marketplaceFees}(""); // Send to contract address for fee collection
        require(successMarketplace, "Marketplace fee transfer failed.");


        // Transfer NFT ownership
        transferNFT(msg.sender, _tokenId);

        // Deactivate listing
        currentListing.isActive = false;
        emit NFTSold(_tokenId, msg.sender, currentListing.seller, currentListing.price);
        earnPointsForBuying(_tokenId); // Gamification: Earn points for buying
        rateSeller(currentListing.seller, 0); // Initialize rating - buyer can rate later
    }

    /// @notice Allows users to place bids on NFTs.
    /// @param _tokenId The ID of the NFT to bid on.
    /// @param _bidPrice The bid price in wei.
    function offerBid(uint256 _tokenId, uint256 _bidPrice) public payable whenNotPaused nftExistsCheck(_tokenId) {
        require(_bidPrice > 0, "Bid price must be greater than zero.");
        require(msg.value >= _bidPrice, "Insufficient funds for bid.");
        require(nftOwner[_tokenId] != msg.sender, "Cannot bid on your own NFT.");

        uint256 bidId = nextBidId++;
        bids[_tokenId][bidId] = Bid(bidId, _tokenId, msg.sender, _bidPrice, true);
        emit BidPlaced(_tokenId, bidId, msg.sender, _bidPrice);

        // Hold the bid funds in the contract (simple approach, could be more sophisticated)
        (bool successHold, ) = payable(address(this)).call{value: msg.value}(""); // Hold funds in contract
        require(successHold, "Bid fund holding failed.");
    }

    /// @notice Seller accepts a specific bid for their NFT.
    /// @param _tokenId The ID of the NFT to accept bid for.
    /// @param _bidId The ID of the bid to accept.
    function acceptBid(uint256 _tokenId, uint256 _bidId) public whenNotPaused nftExistsCheck(_tokenId) onlyNFTOwner(_tokenId) bidExists(_tokenId, _bidId) {
        Bid storage currentBid = bids[_tokenId][_bidId];
        require(currentBid.bidder != address(0), "Invalid bidder address.");
        require(currentBid.isActive, "Bid is not active.");

        uint256 sellerProceeds = (currentBid.bidPrice * (100 - marketplaceFeePercentage)) / 100;
        uint256 marketplaceFees = currentBid.bidPrice - sellerProceeds;

        // Transfer funds to seller (from contract balance - bid funds held)
        (bool successSeller, ) = payable(msg.sender).call{value: sellerProceeds}(""); // Seller is accepting, so msg.sender is the seller
        require(successSeller, "Seller payment failed.");

        // Transfer marketplace fees to admin (contract balance)
        (bool successMarketplace, ) = payable(address(this)).call{value: marketplaceFees}("");
        require(successMarketplace, "Marketplace fee transfer failed.");


        // Transfer NFT ownership to bidder
        transferNFT(currentBid.bidder, _tokenId);

        // Deactivate bid and all other bids for this NFT
        currentBid.isActive = false;
        for (uint256 i = 1; i < nextBidId; i++) { // Inefficient iteration - optimize if needed for production
            if (bids[_tokenId][i].isActive && i != _bidId) {
                bids[_tokenId][i].isActive = false;
                // Refund rejected bids (implementation needed - not done in this basic example for simplicity)
                // In a real system, you would need to track bid deposits and refund them.
            }
        }

        // Deactivate listing if it exists
        if (listings[_tokenId].isActive) {
            listings[_tokenId].isActive = false;
        }

        emit BidAccepted(_tokenId, _bidId, msg.sender, currentBid.bidder, currentBid.bidPrice);
        earnPointsForBuying(_tokenId); // Gamification: Bidder earns points for successful bid
        rateSeller(msg.sender, 0); // Initialize rating - buyer (bidder) can rate later
    }

    /// @notice Bidder can cancel their bid before it's accepted.
    /// @param _tokenId The ID of the NFT for which the bid was placed.
    /// @param _bidId The ID of the bid to cancel.
    function cancelBid(uint256 _tokenId, uint256 _bidId) public whenNotPaused nftExistsCheck(_tokenId) bidExists(_tokenId, _bidId) {
        require(bids[_tokenId][_bidId].bidder == msg.sender, "Only bidder can cancel their bid.");
        require(bids[_tokenId][_bidId].isActive, "Bid is not active.");

        bids[_tokenId][_bidId].isActive = false;
        emit BidCancelled(_tokenId, _bidId, msg.sender);

        // Refund bid amount to bidder (implementation needed - not done in this basic example for simplicity)
        // In a real system, you would need to track bid deposits and refund them.
    }

    /// @notice Retrieves the listing price of an NFT (if listed).
    /// @param _tokenId The ID of the NFT.
    /// @return The listing price in wei, or 0 if not listed.
    function getListingPrice(uint256 _tokenId) public view nftExistsCheck(_tokenId) returns (uint256) {
        if (listings[_tokenId].isActive) {
            return listings[_tokenId].price;
        } else {
            return 0;
        }
    }

    /// @notice Checks if an NFT is currently listed for sale.
    /// @param _tokenId The ID of the NFT.
    /// @return True if the NFT is listed, false otherwise.
    function isListed(uint256 _tokenId) public view nftExistsCheck(_tokenId) returns (bool) {
        return listings[_tokenId].isActive;
    }


    // --- 3. User Profile and Reputation Functions ---

    /// @notice Creates a user profile with a username.
    /// @param _username The username for the user profile.
    function createUserProfile(string memory _username) public whenNotPaused {
        require(bytes(userProfiles[msg.sender].username).length == 0, "Profile already exists for this address.");
        require(bytes(_username).length > 0, "Username cannot be empty.");
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            points: 0,
            ratingCount: 0,
            totalRating: 0
        });
        emit UserProfileCreated(msg.sender, _username);
    }

    /// @notice Updates the username of the user profile.
    /// @param _newUsername The new username.
    function updateUserProfile(string memory _newUsername) public whenNotPaused {
        require(bytes(userProfiles[msg.sender].username).length > 0, "No profile exists to update.");
        require(bytes(_newUsername).length > 0, "Username cannot be empty.");
        userProfiles[msg.sender].username = _newUsername;
        emit UserProfileUpdated(msg.sender, _newUsername);
    }

    /// @notice Allows buyers to rate sellers after a purchase.
    /// @param _seller The address of the seller to rate.
    /// @param _rating The rating given (e.g., 1 to 5).
    function rateSeller(address _seller, uint8 _rating) public whenNotPaused {
        require(_seller != msg.sender, "Cannot rate yourself.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        require(bytes(userProfiles[_seller].username).length > 0, "Seller profile does not exist.");

        UserProfile storage sellerProfile = userProfiles[_seller];
        sellerProfile.totalRating += _rating;
        sellerProfile.ratingCount++;
        emit SellerRated(_seller, msg.sender, _rating);
    }

    /// @notice Retrieves the average rating of a seller.
    /// @param _seller The address of the seller.
    /// @return The average seller rating (0 if no ratings yet).
    function getSellerRating(address _seller) public view returns (uint256) {
        if (userProfiles[_seller].ratingCount == 0) {
            return 0;
        }
        return userProfiles[_seller].totalRating / userProfiles[_seller].ratingCount;
    }


    // --- 4. AI Recommendation Simulation Functions ---

    /// @notice Simulates a request for NFT recommendations based on user address.
    ///         In a real system, this would trigger an off-chain AI service.
    /// @param _userAddress The address of the user requesting recommendations.
    function requestNFTRecommendations(address _userAddress) public whenNotPaused {
        // In a real application:
        // 1. This function would trigger an event that is listened to by an off-chain service (AI model).
        // 2. The off-chain service would use user data (e.g., transaction history, profile, interests - if tracked)
        //    to generate NFT recommendations.
        // 3. The off-chain service would then call back to the smart contract (potentially through another function)
        //    to apply recommendations or store recommendation data.

        // For this simplified example, we just emit an event indicating a request was made.
        // In a real system, you would likely pass more data in the event for the AI service.
        // For example: emit RecommendationRequested(_userAddress, block.timestamp, ... );

        // For demonstration purposes, let's just simulate a recommendation boost for a random NFT for this user.
        // This is highly simplified and not a real AI recommendation, but illustrates the concept.
        if (tokensOfOwner[_userAddress].length > 0) {
            uint256 randomTokenIndex = block.timestamp % tokensOfOwner[_userAddress].length; // Very basic "random" selection
            uint256 recommendedTokenId = tokensOfOwner[_userAddress][randomTokenIndex];
            applyRecommendationBoost(recommendedTokenId, 10); // Example: 10% boost (meaning can be defined)
        }

        // In a real system, you'd likely have a different mechanism to handle the AI response
        // and apply recommendations based on *actual* AI output.
        // This is just a placeholder to show the *idea* of requesting recommendations.
    }

    /// @notice Simulates applying a recommendation boost to an NFT (e.g., increases visibility, temporary price adjustment - for demonstration).
    ///         This is a simplified example and the "boost" effect is not fully defined in this contract.
    /// @param _tokenId The ID of the NFT to boost.
    /// @param _boostPercentage The percentage boost to apply (meaning depends on implementation).
    function applyRecommendationBoost(uint256 _tokenId, uint256 _boostPercentage) public whenNotPaused nftExistsCheck(_tokenId) {
        // Example of "boost" effect - for demonstration only.
        // In a real system, the "boost" might involve:
        // - Increasing visibility in the marketplace UI.
        // - Temporarily adjusting the listed price (if dynamic pricing is implemented).
        // - Highlighting the NFT in recommendation sections.
        // - ... etc.

        // For this basic example, we just emit an event to indicate a boost was applied.
        // The actual "boost" effect needs to be implemented in the frontend or off-chain services
        // that consume this contract's events.

        // For demonstration, let's just temporarily lower the price if it's listed.
        if (listings[_tokenId].isActive) {
            uint256 originalPrice = listings[_tokenId].price;
            uint256 discountedPrice = (originalPrice * (100 - _boostPercentage)) / 100;
            listings[_tokenId].price = discountedPrice;
            // In a real system, you would likely have a mechanism to revert this boost after a certain time
            // or based on other criteria.
            emit NFTListed(_tokenId, discountedPrice, listings[_tokenId].seller); // Re-emit listed event to reflect price change.
        }
        // In a more advanced system, you could store boost data, track boost duration, etc.
        // This is a very basic simulation to illustrate the concept.
    }


    // --- 5. Gamified Interactions and Rewards Functions ---

    /// @notice Awards points to users for listing NFTs.
    /// @param _tokenId The ID of the listed NFT (for context, not directly used for points calculation here).
    function earnPointsForListing(uint256 _tokenId) internal {
        uint256 points = 10; // Example points for listing
        userProfiles[msg.sender].points += points;
        emit PointsEarned(msg.sender, "Listing NFT", points);
    }

    /// @notice Awards points to users for buying NFTs.
    /// @param _tokenId The ID of the bought NFT (for context).
    function earnPointsForBuying(uint256 _tokenId) internal {
        uint256 points = 20; // Example points for buying
        userProfiles[msg.sender].points += points;
        emit PointsEarned(msg.sender, "Buying NFT", points);
    }

    /// @notice Allows users to redeem points for marketplace discounts.
    /// @param _pointsToRedeem The number of points to redeem.
    function redeemPointsForDiscount(uint256 _pointsToRedeem) public whenNotPaused {
        require(userProfiles[msg.sender].points >= _pointsToRedeem, "Insufficient points.");
        require(_pointsToRedeem > 0, "Points to redeem must be greater than zero.");

        uint256 discountPercentage = _pointsToRedeem / 10; // Example: 10 points = 1% discount
        require(discountPercentage <= 50, "Discount percentage cannot exceed 50%."); // Example limit

        userProfiles[msg.sender].points -= _pointsToRedeem;
        emit PointsRedeemed(msg.sender, _pointsToRedeem, discountPercentage);

        // In a real marketplace, you would apply this discount during the purchase process.
        // This example just records the redemption and emits an event.
        // The frontend or off-chain system would need to handle applying the discount at checkout.
    }

    /// @notice Allows users to check their accumulated points.
    /// @param _userAddress The address of the user to check points for.
    /// @return The number of points the user has.
    function checkUserPoints(address _userAddress) public view returns (uint256) {
        return userProfiles[_userAddress].points;
    }


    // --- 6. Utility and Admin Functions ---

    /// @notice Admin function to set the marketplace fee percentage.
    /// @param _newFeePercentage The new marketplace fee percentage (e.g., 2 for 2%).
    function setMarketplaceFee(uint256 _newFeePercentage) public onlyAdmin whenNotPaused {
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100%.");
        marketplaceFeePercentage = _newFeePercentage;
        emit MarketplaceFeeSet(_newFeePercentage, msg.sender);
    }

    /// @notice Admin function to withdraw accumulated marketplace fees.
    function withdrawMarketplaceFees() public onlyAdmin whenNotPaused {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No fees to withdraw.");

        (bool success, ) = payable(admin).call{value: contractBalance}("");
        require(success, "Fee withdrawal failed.");
        emit FeesWithdrawn(msg.sender, contractBalance);
    }

    /// @notice Admin function to pause the contract for maintenance.
    function pauseContract() public onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Admin function to unpause the contract.
    function unpauseContract() public onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }
}
```

**Explanation of Advanced Concepts and Creative Functions:**

1.  **Dynamic NFTs (`mintDynamicNFT`, `updateNFTMetadata`):**  The NFTs are not static. Their metadata can be updated after minting by the owner. This allows for NFTs that evolve, change based on external events, user actions, or even AI-driven updates (though the AI part is simulated here).

2.  **AI Recommendation Simulation (`requestNFTRecommendations`, `applyRecommendationBoost`):**
    *   **`requestNFTRecommendations`**:  This function *simulates* triggering an AI recommendation engine. In a real-world scenario, this would emit an event that an off-chain AI service listens to. The AI service would then analyze user data (which would need to be collected and managed off-chain) and generate NFT recommendations.
    *   **`applyRecommendationBoost`**:  Again, a simulation. This function demonstrates how recommendations *could* be applied within the smart contract. In this basic example, it temporarily lowers the price of a recommended NFT (if listed).  In a real system, "boost" could mean increased visibility, special UI placement, etc., managed by the frontend or off-chain services.

3.  **Gamified Interactions (`earnPointsForListing`, `earnPointsForBuying`, `redeemPointsForDiscount`, `checkUserPoints`):**
    *   **Points System**:  Users earn points for actions like listing and buying NFTs.
    *   **Redeemable Discounts**: Points can be redeemed for discounts in the marketplace, incentivizing participation and engagement.

4.  **User Profile and Reputation (`createUserProfile`, `updateUserProfile`, `rateSeller`, `getSellerRating`):**
    *   **Usernames**: Basic user profiles with usernames for identity within the marketplace.
    *   **Seller Ratings**: Buyers can rate sellers after transactions, building a reputation system to enhance trust and quality within the marketplace.

5.  **Bidding System (`offerBid`, `acceptBid`, `cancelBid`):**  Beyond simple fixed-price listings, the marketplace includes a bidding system for more dynamic pricing and auction-like functionality.

6.  **Marketplace Fees and Admin Control (`setMarketplaceFee`, `withdrawMarketplaceFees`, `pauseContract`, `unpauseContract`):**  Standard marketplace features for revenue generation and administrative control.

7.  **Event Emission**:  The contract emits events for all significant actions (minting, listing, buying, bidding, rating, points, admin actions). These events are crucial for off-chain monitoring, indexing, and building a user interface that reflects the state of the smart contract.

**Important Considerations and Simplifications in this Example:**

*   **AI Recommendation is Simulated**: The AI recommendation part is highly simplified.  Real AI integration would require complex off-chain infrastructure and data management. This example just shows the *concept* of how a smart contract could interact with an AI system.
*   **Bid Fund Management is Basic**: The bid fund holding and refunding mechanism is very basic and needs significant improvement for a production system. In reality, you'd need to carefully manage funds and potentially use more sophisticated escrow or payment channel patterns.
*   **Security**: This is a conceptual example.  A production-ready smart contract would require rigorous security audits to prevent vulnerabilities.
*   **Gas Optimization**:  The code is written for clarity and feature demonstration, not necessarily for gas optimization. Production contracts would need to be optimized to reduce gas costs.
*   **Error Handling and Edge Cases**:  While some `require` statements are included, a production contract would need more comprehensive error handling and consideration of edge cases.
*   **Scalability**:  Smart contracts have inherent scalability limitations. For a high-volume marketplace, Layer-2 solutions or other scaling techniques might be necessary.
*   **Dynamic NFT Metadata Storage**: The `metadata` is stored as a string directly on-chain. For complex metadata, it's more common to store a URI pointing to off-chain storage (like IPFS) to save gas.

This example provides a foundation and demonstrates several advanced and trendy concepts within a single smart contract.  Building a real-world marketplace with these features would require significantly more development, testing, and integration with off-chain services.