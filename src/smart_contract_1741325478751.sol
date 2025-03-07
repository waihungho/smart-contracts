```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI-Driven Personalization
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a dynamic NFT marketplace with advanced features such as:
 *      - Dynamic NFT metadata updates based on external oracles (simulated AI here)
 *      - Personalized NFT recommendations based on user profiles and AI logic (simulated)
 *      - Advanced marketplace functionalities like auctions, bonding curves, and fractionalization
 *      - On-chain governance for marketplace parameters (simulated simple governance)
 *      - Social features like NFT gifting and community curation (simulated).
 *
 * **Outline:**
 * 1.  **NFT Core Functionality:** Minting, Transfer, Metadata Management (Dynamic).
 * 2.  **Marketplace Core Functionality:** Listing, Buying, Selling, Auctions, Bonding Curves.
 * 3.  **Dynamic NFT Logic:** Simulation of external data influence on NFT metadata.
 * 4.  **Personalization & Recommendations:** User Profiles, Preference Setting, AI Recommendation Simulation.
 * 5.  **Advanced Marketplace Features:** Fractionalization, Gifting.
 * 6.  **Governance (Simplified):** Marketplace Fee Setting.
 * 7.  **Utility Functions:** Metadata retrieval, User Profile management.
 *
 * **Function Summary:**
 * 1.  `mintNFT(address _to, string memory _initialMetadata)`: Mints a new Dynamic NFT to the specified address with initial metadata.
 * 2.  `transferNFT(address _from, address _to, uint256 _tokenId)`: Transfers an NFT from one address to another (standard ERC721).
 * 3.  `getNFTMetadata(uint256 _tokenId)`: Retrieves the current metadata URI for a given NFT.
 * 4.  `updateNFTMetadata(uint256 _tokenId)`: Simulates an external trigger to update the metadata of an NFT dynamically.
 * 5.  `listNFTForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale in the marketplace at a fixed price.
 * 6.  `buyNFT(uint256 _listingId)`: Allows a user to buy an NFT listed for sale.
 * 7.  `cancelNFTListing(uint256 _listingId)`: Allows the seller to cancel an NFT listing.
 * 8.  `createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration)`: Creates a new auction for an NFT.
 * 9.  `bidOnAuction(uint256 _auctionId)`: Allows users to bid on an active auction.
 * 10. `finalizeAuction(uint256 _auctionId)`: Finalizes an auction and transfers the NFT to the highest bidder.
 * 11. `createBondingCurve(uint256 _tokenId, uint256 _initialPrice)`: Creates a bonding curve for an NFT, allowing users to buy/sell tokens based on supply.
 * 12. `buyFromBondingCurve(uint256 _bondingCurveId, uint256 _amount)`: Buys tokens from a bonding curve, increasing the price.
 * 13. `sellToBondingCurve(uint256 _bondingCurveId, uint256 _amount)`: Sells tokens to a bonding curve, decreasing the price.
 * 14. `fractionalizeNFT(uint256 _tokenId, uint256 _fractionCount)`: Fractionalizes an NFT, creating fungible tokens representing ownership.
 * 15. `redeemNFTFraction(uint256 _fractionalNFTId, uint256 _fractionAmount)`: Allows fraction holders to redeem a portion of the original NFT (complex logic, simplified here).
 * 16. `giftNFT(uint256 _tokenId, address _recipient, string memory _message)`: Allows a user to gift an NFT with an optional message.
 * 17. `createUserProfile(string memory _username, string memory _preferences)`: Allows a user to create a profile with preferences for NFT recommendations.
 * 18. `getUserProfile(address _userAddress)`: Retrieves a user's profile information.
 * 19. `requestNFTRecommendations()`: Simulates requesting NFT recommendations based on the user's profile and AI logic (simplified).
 * 20. `setMarketplaceFee(uint256 _newFeePercentage)`: Allows the contract owner to set the marketplace fee percentage.
 * 21. `withdrawMarketplaceFees()`: Allows the contract owner to withdraw accumulated marketplace fees.
 * 22. `pauseMarketplace()`: Allows the contract owner to pause marketplace functionalities.
 * 23. `unpauseMarketplace()`: Allows the contract owner to unpause marketplace functionalities.
 */
contract DynamicNFTMarketplace {
    // --- State Variables ---
    string public name = "Dynamic NFT Marketplace";
    string public symbol = "DNFTM";
    address public owner;
    uint256 public marketplaceFeePercentage = 2; // 2% fee
    uint256 public marketplaceFeesCollected = 0;
    bool public paused = false;

    uint256 public nextNFTId = 1;
    mapping(uint256 => address) public nftOwner;
    mapping(uint256 => string) public nftMetadata; // Dynamic metadata URI
    mapping(uint256 => bool) public nftExists;
    mapping(address => uint256) public balance;

    struct NFTListing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }
    uint256 public nextListingId = 1;
    mapping(uint256 => NFTListing) public nftListings;

    struct NFTAuction {
        uint256 auctionId;
        uint256 tokenId;
        address seller;
        uint256 startingBid;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool isActive;
    }
    uint256 public nextAuctionId = 1;
    mapping(uint256 => NFTAuction) public nftAuctions;

    struct BondingCurve {
        uint256 curveId;
        uint256 tokenId;
        uint256 currentPrice;
        uint256 supply;
    }
    uint256 public nextBondingCurveId = 1;
    mapping(uint256 => BondingCurve) public nftBondingCurves;

    struct FractionalNFT {
        uint256 fractionalNFTId;
        uint256 originalNFTId;
        uint256 fractionCount;
        mapping(address => uint256) fractionBalances;
    }
    uint256 public nextFractionalNFTId = 1;
    mapping(uint256 => FractionalNFT) public fractionalNFTs;

    struct UserProfile {
        string username;
        string preferences; // e.g., JSON string of interests
    }
    mapping(address => UserProfile) public userProfiles;

    // --- Events ---
    event NFTMinted(uint256 tokenId, address to, string metadataURI);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTMetadataUpdated(uint256 tokenId, string newMetadataURI);
    event NFTListedForSale(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event NFTBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event NFTListingCancelled(uint256 listingId);
    event AuctionCreated(uint256 auctionId, uint256 tokenId, address seller, uint256 startingBid, uint256 endTime);
    event AuctionBidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionFinalized(uint256 auctionId, uint256 tokenId, address winner, uint256 finalPrice);
    event BondingCurveCreated(uint256 curveId, uint256 tokenId, uint256 initialPrice);
    event BoughtFromBondingCurve(uint256 curveId, address buyer, uint256 amount, uint256 totalPrice);
    event SoldToBondingCurve(uint256 curveId, address seller, uint256 amount, uint256 receivedAmount);
    event NFTFractionalized(uint256 fractionalNFTId, uint256 originalNFTId, uint256 fractionCount);
    event NFTGifted(uint256 tokenId, address from, address to, string message);
    event UserProfileCreated(address userAddress, string username);
    event MarketplaceFeeSet(uint256 newFeePercentage);
    event MarketplaceFeesWithdrawn(uint256 amount);
    event MarketplacePaused();
    event MarketplaceUnpaused();

    // --- Modifiers ---
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

    modifier nftExistsCheck(uint256 _tokenId) {
        require(nftExists[_tokenId], "NFT does not exist.");
        _;
    }

    modifier isNFTOwner(uint256 _tokenId) {
        require(nftOwner[_tokenId] == msg.sender, "You are not the NFT owner.");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
    }

    // --- NFT Core Functions ---
    function mintNFT(address _to, string memory _initialMetadata) public whenNotPaused returns (uint256) {
        uint256 tokenId = nextNFTId++;
        nftOwner[tokenId] = _to;
        nftMetadata[tokenId] = _initialMetadata;
        nftExists[tokenId] = true;
        balance[_to]++;
        emit NFTMinted(tokenId, _to, _initialMetadata);
        return tokenId;
    }

    function transferNFT(address _to, uint256 _tokenId) public whenNotPaused nftExistsCheck(_tokenId) isNFTOwner(_tokenId) {
        address from = msg.sender;
        nftOwner[_tokenId] = _to;
        balance[from]--;
        balance[_to]++;
        emit NFTTransferred(_tokenId, from, _to);
    }

    function getNFTMetadata(uint256 _tokenId) public view nftExistsCheck(_tokenId) returns (string memory) {
        return nftMetadata[_tokenId];
    }

    function updateNFTMetadata(uint256 _tokenId) public whenNotPaused nftExistsCheck(_tokenId) onlyOwner {
        // Simulate external update (e.g., AI or Oracle data influence)
        // In a real-world scenario, this might be triggered by an oracle or off-chain process.
        // For demonstration, we'll just append a timestamp to the metadata.
        string memory currentMetadata = nftMetadata[_tokenId];
        string memory newMetadata = string(abi.encodePacked(currentMetadata, " - Updated at ", block.timestamp));
        nftMetadata[_tokenId] = newMetadata;
        emit NFTMetadataUpdated(_tokenId, newMetadata);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balance[_owner];
    }

    function ownerOf(uint256 _tokenId) public view nftExistsCheck(_tokenId) returns (address) {
        return nftOwner[_tokenId];
    }

    // --- Marketplace Core Functions ---
    function listNFTForSale(uint256 _tokenId, uint256 _price) public whenNotPaused nftExistsCheck(_tokenId) isNFTOwner(_tokenId) {
        require(_price > 0, "Price must be greater than zero.");
        require(nftListings[nextListingId].isActive == false, "Listing ID collision, try again."); // Simple collision check

        nftListings[nextListingId] = NFTListing({
            listingId: nextListingId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        emit NFTListedForSale(nextListingId, _tokenId, msg.sender, _price);
        nextListingId++;
    }

    function buyNFT(uint256 _listingId) public payable whenNotPaused {
        require(nftListings[_listingId].isActive, "Listing is not active or does not exist.");
        NFTListing storage listing = nftListings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds.");
        require(listing.seller != msg.sender, "Cannot buy your own NFT.");

        uint256 fee = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerPayment = listing.price - fee;

        marketplaceFeesCollected += fee;
        payable(owner).transfer(fee); // Transfer fee to owner
        payable(listing.seller).transfer(sellerPayment); // Transfer payment to seller
        transferNFT(msg.sender, listing.tokenId); // Transfer NFT to buyer

        listing.isActive = false; // Mark listing as inactive
        emit NFTBought(_listingId, listing.tokenId, msg.sender, listing.price);
    }

    function cancelNFTListing(uint256 _listingId) public whenNotPaused {
        require(nftListings[_listingId].isActive, "Listing is not active or does not exist.");
        require(nftListings[_listingId].seller == msg.sender, "Only seller can cancel listing.");

        nftListings[_listingId].isActive = false;
        emit NFTListingCancelled(_listingId);
    }

    // --- Auction Functions ---
    function createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration) public whenNotPaused nftExistsCheck(_tokenId) isNFTOwner(_tokenId) {
        require(_startingBid > 0, "Starting bid must be greater than zero.");
        require(_auctionDuration > 0 && _auctionDuration <= 7 days, "Auction duration must be between 1 second and 7 days.");
        require(nftAuctions[nextAuctionId].isActive == false, "Auction ID collision, try again."); // Simple collision check

        nftAuctions[nextAuctionId] = NFTAuction({
            auctionId: nextAuctionId,
            tokenId: _tokenId,
            seller: msg.sender,
            startingBid: _startingBid,
            endTime: block.timestamp + _auctionDuration,
            highestBidder: address(0),
            highestBid: 0,
            isActive: true
        });
        emit AuctionCreated(nextAuctionId, _tokenId, msg.sender, _startingBid, block.timestamp + _auctionDuration);
        nextAuctionId++;
    }

    function bidOnAuction(uint256 _auctionId) public payable whenNotPaused {
        require(nftAuctions[_auctionId].isActive, "Auction is not active or does not exist.");
        NFTAuction storage auction = nftAuctions[_auctionId];
        require(block.timestamp < auction.endTime, "Auction has ended.");
        require(msg.value > auction.highestBid, "Bid must be higher than the current highest bid.");
        require(auction.seller != msg.sender, "Seller cannot bid on their own auction.");

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid); // Refund previous bidder
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        emit AuctionBidPlaced(_auctionId, msg.sender, msg.value);
    }

    function finalizeAuction(uint256 _auctionId) public whenNotPaused {
        require(nftAuctions[_auctionId].isActive, "Auction is not active or does not exist.");
        NFTAuction storage auction = nftAuctions[_auctionId];
        require(block.timestamp >= auction.endTime, "Auction is not yet ended.");

        auction.isActive = false; // Mark auction as inactive

        if (auction.highestBidder != address(0)) {
            uint256 fee = (auction.highestBid * marketplaceFeePercentage) / 100;
            uint256 sellerPayment = auction.highestBid - fee;

            marketplaceFeesCollected += fee;
            payable(owner).transfer(fee); // Transfer fee to owner
            payable(auction.seller).transfer(sellerPayment); // Transfer payment to seller
            transferNFT(auction.highestBidder, auction.tokenId); // Transfer NFT to highest bidder
            emit AuctionFinalized(_auctionId, auction.tokenId, auction.highestBidder, auction.highestBid);
        } else {
            // No bids, return NFT to seller (optional, could also set a reserve price in a real system)
            emit AuctionFinalized(_auctionId, auction.tokenId, address(0), 0); // Indicate no winner
        }
    }

    // --- Bonding Curve Functions (Simplified - Linear Curve) ---
    function createBondingCurve(uint256 _tokenId, uint256 _initialPrice) public whenNotPaused nftExistsCheck(_tokenId) isNFTOwner(_tokenId) {
        require(_initialPrice > 0, "Initial price must be greater than zero.");
        require(nftBondingCurves[nextBondingCurveId].curveId == 0, "Bonding Curve ID collision, try again."); // Simple collision check

        nftBondingCurves[nextBondingCurveId] = BondingCurve({
            curveId: nextBondingCurveId,
            tokenId: _tokenId,
            currentPrice: _initialPrice,
            supply: 0 // Initial supply is zero, increases with buys
        });
        emit BondingCurveCreated(nextBondingCurveId, _tokenId, _initialPrice);
        nextBondingCurveId++;
    }

    function buyFromBondingCurve(uint256 _bondingCurveId, uint256 _amount) public payable whenNotPaused {
        require(nftBondingCurves[_bondingCurveId].curveId != 0, "Bonding curve does not exist.");
        BondingCurve storage curve = nftBondingCurves[_bondingCurveId];
        require(_amount > 0, "Amount must be greater than zero.");

        uint256 totalPrice = curve.currentPrice * _amount; // Simplified linear curve
        require(msg.value >= totalPrice, "Insufficient funds for bonding curve purchase.");

        curve.supply += _amount;
        curve.currentPrice += _amount; // Simple linear price increase
        balance[msg.sender] += _amount; // Assume fungible tokens are issued for bonding curve NFTs (simplification)

        emit BoughtFromBondingCurve(_bondingCurveId, msg.sender, _amount, totalPrice);
    }

    function sellToBondingCurve(uint256 _bondingCurveId, uint256 _amount) public whenNotPaused {
        require(nftBondingCurves[_bondingCurveId].curveId != 0, "Bonding curve does not exist.");
        BondingCurve storage curve = nftBondingCurves[_bondingCurveId];
        require(_amount > 0, "Amount must be greater than zero.");
        require(balance[msg.sender] >= _amount, "Insufficient tokens to sell.");

        uint256 receivedAmount = curve.currentPrice * _amount; // Simplified linear curve
        require(address(this).balance >= receivedAmount, "Contract has insufficient funds to buy back."); // Simple check for contract balance

        curve.supply -= _amount;
        curve.currentPrice -= _amount; // Simple linear price decrease
        balance[msg.sender] -= _amount;

        payable(msg.sender).transfer(receivedAmount);
        emit SoldToBondingCurve(_bondingCurveId, msg.sender, _amount, receivedAmount);
    }

    // --- Fractionalization (Simplified) ---
    function fractionalizeNFT(uint256 _tokenId, uint256 _fractionCount) public whenNotPaused nftExistsCheck(_tokenId) isNFTOwner(_tokenId) {
        require(_fractionCount > 0 && _fractionCount <= 10000, "Fraction count must be between 1 and 10000.");
        require(fractionalNFTs[nextFractionalNFTId].fractionalNFTId == 0, "Fractional NFT ID collision, try again."); // Simple collision check

        fractionalNFTs[nextFractionalNFTId] = FractionalNFT({
            fractionalNFTId: nextFractionalNFTId,
            originalNFTId: _tokenId,
            fractionCount: _fractionCount
        });

        fractionalNFTs[nextFractionalNFTId].fractionBalances[msg.sender] = _fractionCount;
        balance[msg.sender] += _fractionCount; // Assign fractions to the NFT owner
        // In a real system, you might burn/lock the original NFT here.

        emit NFTFractionalized(nextFractionalNFTId, _tokenId, _fractionCount);
        nextFractionalNFTId++;
    }

    function redeemNFTFraction(uint256 _fractionalNFTId, uint256 _fractionAmount) public whenNotPaused {
        // Simplified redemption - in a real system, this is complex and requires governance/voting etc.
        // For simplicity, we just reduce fraction balance.
        require(fractionalNFTs[_fractionalNFTId].fractionalNFTId != 0, "Fractional NFT does not exist.");
        FractionalNFT storage fractionalNFT = fractionalNFTs[_fractionalNFTId];
        require(fractionalNFT.fractionBalances[msg.sender] >= _fractionAmount, "Insufficient fractional tokens to redeem.");
        require(_fractionAmount > 0, "Redemption amount must be greater than zero.");

        fractionalNFT.fractionBalances[msg.sender] -= _fractionAmount;
        balance[msg.sender] -= _fractionAmount;

        // In a real system, redemption would involve a mechanism to return a portion of the original NFT
        // or some other benefit to fraction holders. This is highly simplified for demonstration.
        // Consider governance, voting, or dynamic NFT metadata update based on collective ownership in a real implementation.
    }

    // --- Social Features ---
    function giftNFT(uint256 _tokenId, address _recipient, string memory _message) public whenNotPaused nftExistsCheck(_tokenId) isNFTOwner(_tokenId) {
        require(_recipient != address(0), "Recipient address cannot be zero.");
        transferNFT(_recipient, _tokenId);
        emit NFTGifted(_tokenId, msg.sender, _recipient, _message);
    }

    // --- Personalization & Recommendations (Simplified AI Simulation) ---
    function createUserProfile(string memory _username, string memory _preferences) public whenNotPaused {
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            preferences: _preferences // Store user preferences (e.g., JSON string)
        });
        emit UserProfileCreated(msg.sender, _username);
    }

    function getUserProfile(address _userAddress) public view returns (UserProfile memory) {
        return userProfiles[_userAddress];
    }

    function requestNFTRecommendations() public view whenNotPaused returns (uint256[] memory) {
        // --- Simplified AI Recommendation Logic ---
        // In a real application, this would interface with an off-chain AI service.
        // Here, we simulate a very basic recommendation based on user preferences (if set).

        UserProfile memory profile = userProfiles[msg.sender];
        uint256[] memory recommendations;

        if (bytes(profile.preferences).length > 0) {
            // Simulate preference matching - very basic keyword check
            string memory userPreferences = profile.preferences;
            uint256 recommendationCount = 0;
            uint256[] memory tempRecommendations = new uint256[](nextNFTId - 1); // Max possible recommendations

            for (uint256 i = 1; i < nextNFTId; i++) {
                if (nftExists[i]) {
                    string memory metadata = nftMetadata[i];
                    if (stringContains(metadata, userPreferences)) { // Basic string search
                        tempRecommendations[recommendationCount++] = i;
                    }
                }
            }

            recommendations = new uint256[](recommendationCount);
            for (uint256 i = 0; i < recommendationCount; i++) {
                recommendations[i] = tempRecommendations[i];
            }
        } else {
            // If no preferences, recommend recently minted NFTs (simplistic fallback)
            uint256 recommendationCount = 0;
            uint256[] memory tempRecommendations = new uint256[](nextNFTId - 1);
             for (uint256 i = nextNFTId - 1; i >= 1 && recommendationCount < 5; i--) { // Recommend up to 5 recent NFTs
                if (nftExists[i]) {
                    tempRecommendations[recommendationCount++] = i;
                }
                if (i == 1 ) break; // prevent underflow
            }
            recommendations = new uint256[](recommendationCount);
            for (uint256 i = 0; i < recommendationCount; i++) {
                recommendations[i] = tempRecommendations[i];
            }
        }

        return recommendations;
    }

    // --- Governance (Simplified - Owner Controlled) ---
    function setMarketplaceFee(uint256 _newFeePercentage) public onlyOwner {
        require(_newFeePercentage <= 10, "Fee percentage cannot exceed 10%.");
        marketplaceFeePercentage = _newFeePercentage;
        emit MarketplaceFeeSet(_newFeePercentage);
    }

    function withdrawMarketplaceFees() public onlyOwner {
        uint256 amount = marketplaceFeesCollected;
        marketplaceFeesCollected = 0;
        payable(owner).transfer(amount);
        emit MarketplaceFeesWithdrawn(amount);
    }

    function pauseMarketplace() public onlyOwner whenNotPaused {
        paused = true;
        emit MarketplacePaused();
    }

    function unpauseMarketplace() public onlyOwner whenPaused {
        paused = false;
        emit MarketplaceUnpaused();
    }


    // --- Utility Functions ---
    function stringContains(string memory _str, string memory _substring) internal pure returns (bool) {
        return stringToBytes(keccak256(abi.encodePacked(_str))) == stringToBytes(keccak256(abi.encodePacked(_substring))); // Very basic and inefficient string check - for demo purposes only!
        // For robust string operations, consider off-chain processing or more advanced libraries (not ideal on-chain for gas).
    }

    function stringToBytes(bytes32 _string) internal pure returns (bytes32) {
        return _string; // Simplistic conversion for demo string comparison
    }
}
```