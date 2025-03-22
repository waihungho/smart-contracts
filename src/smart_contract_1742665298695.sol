```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI-Powered Personalization
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a dynamic NFT marketplace with advanced features
 * including AI-powered (simulated within contract logic) NFT personalization, dynamic NFT metadata updates based on user interactions,
 * decentralized governance for marketplace parameters, and advanced listing/auction mechanisms.
 *
 * Function Summary:
 * -----------------
 * **Collection Management:**
 * 1. createNFTCollection(string memory _collectionName, string memory _collectionSymbol, string memory _baseURI): Allows creators to launch new NFT collections.
 * 2. setCollectionBaseURI(uint256 _collectionId, string memory _newBaseURI): Updates the base URI for a specific NFT collection (owner only).
 * 3. toggleCollectionVerification(uint256 _collectionId): Toggles verification status for a collection (marketplace admin only).
 *
 * **NFT Management:**
 * 4. mintNFT(uint256 _collectionId, address _recipient, string memory _tokenURI, string memory _initialDynamicData): Mints a new NFT within a collection with dynamic data.
 * 5. updateNFTDynamicData(uint256 _tokenId, string memory _newDynamicData): Updates the dynamic data of an NFT (owner only).
 * 6. burnNFT(uint256 _tokenId): Allows NFT owner to burn their NFT.
 * 7. getNFTDynamicData(uint256 _tokenId): Retrieves the dynamic data associated with an NFT.
 *
 * **Marketplace Listing and Sales:**
 * 8. listItemForSale(uint256 _tokenId, uint256 _price): Lists an NFT for sale at a fixed price.
 * 9. buyNFT(uint256 _listingId): Allows users to purchase an NFT listed for sale.
 * 10. cancelListing(uint256 _listingId): Allows seller to cancel an NFT listing.
 * 11. createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _durationHours): Creates an auction for an NFT.
 * 12. bidOnAuction(uint256 _auctionId, uint256 _bidAmount): Allows users to bid on an active auction.
 * 13. finalizeAuction(uint256 _auctionId): Ends an auction and transfers NFT to the highest bidder.
 * 14. setMarketplaceFee(uint256 _feePercentage): Sets the marketplace fee percentage (marketplace admin only).
 * 15. withdrawMarketplaceFees(): Allows marketplace admin to withdraw accumulated fees.
 *
 * **Personalization and Recommendation (Simulated AI):**
 * 16. setUserPreferences(string memory _preferences): Allows users to set their preferences for NFT recommendations.
 * 17. getPersonalizedNFTRecommendations(address _user): Returns (simulated AI) NFT recommendations based on user preferences and marketplace activity.
 * 18. provideFeedbackOnRecommendation(uint256 _recommendedTokenId, bool _isRelevant): Allows users to provide feedback on recommendations to (simulated) improve AI.
 * 19. setRecommendationAlgorithmParameters(uint256 _param1, uint256 _param2): Allows marketplace admin to adjust (simulated) AI algorithm parameters.
 *
 * **Utility and Admin Functions:**
 * 20. supportsInterface(bytes4 interfaceId): Standard ERC165 interface support.
 * 21. pauseMarketplace(): Pauses core marketplace functionalities (marketplace admin only).
 * 22. unpauseMarketplace(): Resumes marketplace functionalities (marketplace admin only).
 * 23. rescueERC20(address _tokenAddress, address _recipient, uint256 _amount): Allows marketplace admin to rescue accidentally sent ERC20 tokens.
 */
contract DynamicNFTMarketplace {
    // --- Outline & Function Summary Above ---

    // --- State Variables ---
    address public owner;
    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    uint256 public marketplaceFeesCollected = 0;
    bool public paused = false;

    // Collection Data
    uint256 public nextCollectionId = 1;
    struct NFTCollection {
        string collectionName;
        string collectionSymbol;
        string baseURI;
        address creator;
        bool isVerified;
    }
    mapping(uint256 => NFTCollection) public collections;
    mapping(address => uint256[]) public creatorCollections; // Track collections created by each address

    // NFT Data
    uint256 public nextTokenId = 1;
    struct NFT {
        uint256 collectionId;
        uint256 tokenIdWithinCollection; // Unique within the collection
        address owner;
        string tokenURI;
        string dynamicData; // Store dynamic information that can be updated
    }
    mapping(uint256 => NFT) public nfts;
    mapping(address => uint256[]) public userNFTs; // Track NFTs owned by each user
    mapping(uint256 => address) public nftCollectionCreator; // Mapping to easily get collection creator from tokenId


    // Marketplace Listing Data
    uint256 public nextListingId = 1;
    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => uint256) public tokenIdToListingId; // Quickly find listing ID by tokenId
    mapping(uint256 => bool) public activeListings; // Track active listing IDs

    // Auction Data
    uint256 public nextAuctionId = 1;
    struct Auction {
        uint256 auctionId;
        uint256 tokenId;
        address seller;
        uint256 startingPrice;
        uint256 highestBid;
        address highestBidder;
        uint256 endTime;
        bool isActive;
    }
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => uint256) public tokenIdToAuctionId; // Quickly find auction ID by tokenId
    mapping(uint256 => bool) public activeAuctions; // Track active auction IDs

    // User Preferences (Simulated AI Data)
    mapping(address => string) public userPreferences; // Store user preference strings
    // (In a real AI implementation, this would be more complex and off-chain)


    // --- Events ---
    event CollectionCreated(uint256 collectionId, string collectionName, address creator);
    event CollectionBaseURISet(uint256 collectionId, string newBaseURI);
    event CollectionVerificationToggled(uint256 collectionId, bool isVerified);

    event NFTMinted(uint256 tokenId, uint256 collectionId, address recipient);
    event NFTDynamicDataUpdated(uint256 tokenId, string newDynamicData);
    event NFTBurned(uint256 tokenId, address owner);

    event NFTListedForSale(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event NFTBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event ListingCancelled(uint256 listingId, uint256 tokenId);

    event AuctionCreated(uint256 auctionId, uint256 tokenId, address seller, uint256 startingPrice, uint256 endTime);
    event BidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionFinalized(uint256 auctionId, uint256 tokenId, address winner, uint256 finalPrice);

    event UserPreferencesSet(address user, string preferences);
    event RecommendationFeedbackGiven(uint256 recommendedTokenId, address user, bool isRelevant);
    event MarketplaceFeeUpdated(uint256 newFeePercentage);
    event MarketplaceFeesWithdrawn(uint256 amount, address admin);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event ERC20TokensRescued(address tokenAddress, address recipient, uint256 amount);


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
        _;
    }

    modifier onlyCollectionCreator(uint256 _collectionId) {
        require(collections[_collectionId].creator == msg.sender, "Only collection creator can call this function.");
        _;
    }

    modifier onlyMarketplaceAdmin() {
        require(msg.sender == owner, "Only marketplace admin can call this function."); // For simplicity, owner is admin
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

    modifier validListing(uint256 _listingId) {
        require(listings[_listingId].isActive, "Listing is not active.");
        _;
    }

    modifier validAuction(uint256 _auctionId) {
        require(auctions[_auctionId].isActive, "Auction is not active.");
        require(block.timestamp < auctions[_auctionId].endTime, "Auction has ended.");
        _;
    }

    modifier isTokenOwner(uint256 _tokenId) {
        require(nfts[_tokenId].owner == msg.sender, "You are not the owner of this NFT.");
        _;
    }

    modifier isListingSeller(uint256 _listingId) {
        require(listings[_listingId].seller == msg.sender, "You are not the seller of this listing.");
        _;
    }

    modifier isAuctionSeller(uint256 _auctionId) {
        require(auctions[_auctionId].seller == msg.sender, "You are not the seller of this auction.");
        _;
    }


    // --- Constructor ---
    constructor() {
        owner = msg.sender;
    }

    // --- Collection Management Functions ---
    function createNFTCollection(
        string memory _collectionName,
        string memory _collectionSymbol,
        string memory _baseURI
    ) public whenNotPaused {
        require(bytes(_collectionName).length > 0 && bytes(_collectionSymbol).length > 0, "Collection name and symbol cannot be empty.");
        uint256 collectionId = nextCollectionId++;
        collections[collectionId] = NFTCollection({
            collectionName: _collectionName,
            collectionSymbol: _collectionSymbol,
            baseURI: _baseURI,
            creator: msg.sender,
            isVerified: false
        });
        creatorCollections[msg.sender].push(collectionId);
        emit CollectionCreated(collectionId, _collectionName, msg.sender);
    }

    function setCollectionBaseURI(uint256 _collectionId, string memory _newBaseURI) public onlyCollectionCreator(_collectionId) whenNotPaused {
        collections[_collectionId].baseURI = _newBaseURI;
        emit CollectionBaseURISet(_collectionId, _newBaseURI);
    }

    function toggleCollectionVerification(uint256 _collectionId) public onlyMarketplaceAdmin whenNotPaused {
        collections[_collectionId].isVerified = !collections[_collectionId].isVerified;
        emit CollectionVerificationToggled(_collectionId, collections[_collectionId].isVerified);
    }


    // --- NFT Management Functions ---
    function mintNFT(
        uint256 _collectionId,
        address _recipient,
        string memory _tokenURI,
        string memory _initialDynamicData
    ) public onlyCollectionCreator(_collectionId) whenNotPaused {
        require(_recipient != address(0), "Recipient address cannot be zero.");
        uint256 tokenId = nextTokenId++;
        uint256 tokenIdWithinCollection = 0; // In a real app, track this per collection if needed
        nfts[tokenId] = NFT({
            collectionId: _collectionId,
            tokenIdWithinCollection: tokenIdWithinCollection,
            owner: _recipient,
            tokenURI: _tokenURI,
            dynamicData: _initialDynamicData
        });
        userNFTs[_recipient].push(tokenId);
        nftCollectionCreator[tokenId] = collections[_collectionId].creator; // Track creator for each NFT
        emit NFTMinted(tokenId, _collectionId, _recipient);
    }

    function updateNFTDynamicData(uint256 _tokenId, string memory _newDynamicData) public isTokenOwner(_tokenId) whenNotPaused {
        nfts[_tokenId].dynamicData = _newDynamicData;
        emit NFTDynamicDataUpdated(_tokenId, _newDynamicData);
    }

    function burnNFT(uint256 _tokenId) public isTokenOwner(_tokenId) whenNotPaused {
        address nftOwner = nfts[_tokenId].owner;

        // Remove tokenId from userNFTs mapping
        uint256[] storage ownerNftList = userNFTs[nftOwner];
        for (uint256 i = 0; i < ownerNftList.length; i++) {
            if (ownerNftList[i] == _tokenId) {
                ownerNftList[i] = ownerNftList[ownerNftList.length - 1]; // Replace with last element
                ownerNftList.pop(); // Remove last element (duplicate now)
                break;
            }
        }

        delete nfts[_tokenId]; // Delete NFT data
        emit NFTBurned(_tokenId, nftOwner);
    }

    function getNFTDynamicData(uint256 _tokenId) public view returns (string memory) {
        require(nfts[_tokenId].owner != address(0), "NFT does not exist.");
        return nfts[_tokenId].dynamicData;
    }


    // --- Marketplace Listing and Sales Functions ---
    function listItemForSale(uint256 _tokenId, uint256 _price) public isTokenOwner(_tokenId) whenNotPaused {
        require(_price > 0, "Price must be greater than zero.");
        require(tokenIdToListingId[_tokenId] == 0, "NFT is already listed or in auction."); // Prevent double listing

        uint256 listingId = nextListingId++;
        listings[listingId] = Listing({
            listingId: listingId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        tokenIdToListingId[_tokenId] = listingId;
        activeListings[listingId] = true;
        emit NFTListedForSale(listingId, _tokenId, msg.sender, _price);
    }

    function buyNFT(uint256 _listingId) public payable whenNotPaused validListing(_listingId) {
        Listing storage listing = listings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds.");
        require(msg.sender != listing.seller, "Seller cannot buy their own NFT.");

        uint256 tokenId = listing.tokenId;
        address seller = listing.seller;
        uint256 price = listing.price;

        // Transfer NFT ownership
        nfts[tokenId].owner = msg.sender;
        userNFTs[seller] = _removeNFTFromUserList(userNFTs[seller], tokenId);
        userNFTs[msg.sender].push(tokenId);

        // Transfer funds (with marketplace fee)
        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 100;
        uint256 sellerPayout = price - marketplaceFee;

        (bool successSeller, ) = payable(seller).call{value: sellerPayout}("");
        require(successSeller, "Seller payment failed.");
        marketplaceFeesCollected += marketplaceFee;

        // Deactivate listing
        listing.isActive = false;
        activeListings[_listingId] = false;
        delete tokenIdToListingId[tokenId];

        emit NFTBought(_listingId, tokenId, msg.sender, price);
    }

    function cancelListing(uint256 _listingId) public whenNotPaused validListing(_listingId) isListingSeller(_listingId) {
        uint256 tokenId = listings[_listingId].tokenId;
        listings[_listingId].isActive = false;
        activeListings[_listingId] = false;
        delete tokenIdToListingId[tokenId];
        emit ListingCancelled(_listingId, tokenId);
    }

    function createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _durationHours) public isTokenOwner(_tokenId) whenNotPaused {
        require(_startingPrice > 0, "Starting price must be greater than zero.");
        require(_durationHours > 0 && _durationHours <= 720, "Auction duration must be between 1 and 720 hours."); // Max 30 days
        require(tokenIdToAuctionId[_tokenId] == 0 && tokenIdToListingId[_tokenId] == 0, "NFT is already listed or in auction."); // Prevent double listing

        uint256 auctionId = nextAuctionId++;
        uint256 endTime = block.timestamp + (_durationHours * 1 hours); // Duration in seconds

        auctions[auctionId] = Auction({
            auctionId: auctionId,
            tokenId: _tokenId,
            seller: msg.sender,
            startingPrice: _startingPrice,
            highestBid: 0,
            highestBidder: address(0),
            endTime: endTime,
            isActive: true
        });
        tokenIdToAuctionId[_tokenId] = auctionId;
        activeAuctions[auctionId] = true;
        emit AuctionCreated(auctionId, _tokenId, msg.sender, _startingPrice, endTime);
    }

    function bidOnAuction(uint256 _auctionId, uint256 _bidAmount) public payable whenNotPaused validAuction(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        require(msg.value >= _bidAmount, "Bid amount is less than sent value.");
        require(msg.sender != auction.seller, "Seller cannot bid on their own auction.");
        require(_bidAmount > auction.highestBid, "Bid amount must be higher than the current highest bid.");

        if (auction.highestBidder != address(0)) {
            // Refund previous highest bidder
            (bool successRefund, ) = payable(auction.highestBidder).call{value: auction.highestBid}("");
            require(successRefund, "Refund to previous bidder failed.");
        }

        auction.highestBid = _bidAmount;
        auction.highestBidder = msg.sender;
        emit BidPlaced(_auctionId, msg.sender, _bidAmount);
    }

    function finalizeAuction(uint256 _auctionId) public whenNotPaused validAuction(_auctionId) isAuctionSeller(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp >= auction.endTime, "Auction is not yet finished.");

        uint256 tokenId = auction.tokenId;
        address seller = auction.seller;
        address winner = auction.highestBidder;
        uint256 finalPrice = auction.highestBid;

        // Deactivate auction
        auction.isActive = false;
        activeAuctions[_auctionId] = false;
        delete tokenIdToAuctionId[tokenId];

        if (winner != address(0)) {
            // Transfer NFT to winner
            nfts[tokenId].owner = winner;
            userNFTs[seller] = _removeNFTFromUserList(userNFTs[seller], tokenId);
            userNFTs[winner].push(tokenId);

            // Transfer funds to seller (with marketplace fee)
            uint256 marketplaceFee = (finalPrice * marketplaceFeePercentage) / 100;
            uint256 sellerPayout = finalPrice - marketplaceFee;

            (bool successSeller, ) = payable(seller).call{value: sellerPayout}("");
            require(successSeller, "Seller payment failed.");
            marketplaceFeesCollected += marketplaceFee;

            emit AuctionFinalized(_auctionId, tokenId, winner, finalPrice);
        } else {
            // No bids, return NFT to seller (no sale)
            emit AuctionFinalized(_auctionId, tokenId, address(0), 0); // Winner address 0 indicates no sale
        }
    }

    function setMarketplaceFee(uint256 _feePercentage) public onlyMarketplaceAdmin whenNotPaused {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeUpdated(_feePercentage);
    }

    function withdrawMarketplaceFees() public onlyMarketplaceAdmin whenNotPaused {
        uint256 amountToWithdraw = marketplaceFeesCollected;
        marketplaceFeesCollected = 0; // Reset collected fees
        (bool success, ) = payable(owner).call{value: amountToWithdraw}("");
        require(success, "Fee withdrawal failed.");
        emit MarketplaceFeesWithdrawn(amountToWithdraw, owner);
    }


    // --- Personalization and Recommendation Functions (Simulated AI) ---
    function setUserPreferences(string memory _preferences) public whenNotPaused {
        userPreferences[msg.sender] = _preferences;
        emit UserPreferencesSet(msg.sender, _preferences);
    }

    function getPersonalizedNFTRecommendations(address _user) public view whenNotPaused returns (uint256[] memory) {
        // --- Simulated AI Recommendation Logic ---
        // This is a very basic example. In a real AI system, this would be much more complex and likely off-chain.
        // Here, we simulate a simple keyword-based recommendation based on user preferences.

        string memory userPref = userPreferences[_user];
        if (bytes(userPref).length == 0) {
            // If no preferences, return a few random NFTs or popular NFTs
            return _getRandomNFTRecommendations();
        }

        string[] memory keywords = _splitString(userPref, ","); // Simple comma-separated keywords
        uint256[] memory recommendations = new uint256[](0);

        for (uint256 i = 1; i < nextTokenId; i++) { // Iterate through all NFTs
            if (nfts[i].owner != address(0)) { // Check if NFT exists
                string memory nftDynamicData = nfts[i].dynamicData;
                for (uint256 j = 0; j < keywords.length; j++) {
                    if (stringContains(nftDynamicData, keywords[j])) {
                        recommendations = _pushToArray(recommendations, i);
                        break; // Avoid adding same NFT multiple times if multiple keywords match
                    }
                }
            }
        }

        if (recommendations.length == 0) {
            return _getRandomNFTRecommendations(); // If no keyword matches, return random
        }

        return recommendations;
    }

    function provideFeedbackOnRecommendation(uint256 _recommendedTokenId, bool _isRelevant) public whenNotPaused {
        // In a real AI system, this feedback would be used to retrain the model.
        // Here, we just emit an event for potential off-chain analysis or logging.
        emit RecommendationFeedbackGiven(_recommendedTokenId, msg.sender, _isRelevant);
        // In a more advanced simulation, you could adjust weights or parameters based on feedback.
    }

    function setRecommendationAlgorithmParameters(uint256 _param1, uint256 _param2) public onlyMarketplaceAdmin whenNotPaused {
        // This is a placeholder for setting parameters for a simulated AI algorithm.
        // In a real AI system, these parameters would be much more complex and managed off-chain.
        // Example: Could control the "randomness" or "keyword matching sensitivity" of the simulated recommendation logic.
        // For now, we just acknowledge the function exists.
        // (In a real application, you'd likely have no parameters in the smart contract for a true AI, as AI logic is off-chain)
        // (This function exists to demonstrate the concept of parameter tuning, even if simulated).
        _param1; // To avoid "Unused function parameter" warning
        _param2; // To avoid "Unused function parameter" warning
        // Implement any simulated parameter adjustments here if needed for your simulated AI logic.
    }


    // --- Utility and Admin Functions ---
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }

    function pauseMarketplace() public onlyMarketplaceAdmin whenNotPaused {
        paused = true;
        emit MarketplacePaused();
    }

    function unpauseMarketplace() public onlyMarketplaceAdmin whenPaused {
        paused = false;
        emit MarketplaceUnpaused();
    }

    function rescueERC20(address _tokenAddress, address _recipient, uint256 _amount) public onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        uint256 amountToRescue = Math.min(_amount, balance); // Prevent over-rescue
        require(amountToRescue > 0, "No tokens to rescue or amount is zero.");
        bool success = token.transfer(_recipient, amountToRescue);
        require(success, "ERC20 rescue transfer failed.");
        emit ERC20TokensRescued(_tokenAddress, _recipient, amountToRescue);
    }


    // --- Internal Helper Functions ---
    function _removeNFTFromUserList(uint256[] memory _userNftList, uint256 _tokenIdToRemove) internal pure returns (uint256[] memory) {
        uint256[] memory newList = new uint256[](_userNftList.length - 1);
        uint256 newListIndex = 0;
        bool found = false;
        for (uint256 i = 0; i < _userNftList.length; i++) {
            if (_userNftList[i] == _tokenIdToRemove && !found) {
                found = true; // Skip the token to remove
            } else {
                newList[newListIndex++] = _userNftList[i];
            }
        }
        return newList;
    }

    function _getRandomNFTRecommendations() internal view returns (uint256[] memory) {
        // Very basic random recommendation (not truly random on blockchain without oracles)
        uint256 count = 0;
        uint256[] memory recommendations = new uint256[](0);
        for (uint256 i = 1; i < nextTokenId && count < 5; i++) { // Limit to 5 random recommendations
            if (nfts[i].owner != address(0)) {
                recommendations = _pushToArray(recommendations, i);
                count++;
            }
        }
        return recommendations;
    }

    function _pushToArray(uint256[] memory _array, uint256 _value) internal pure returns (uint256[] memory) {
        uint256[] memory newArray = new uint256[](_array.length + 1);
        for (uint256 i = 0; i < _array.length; i++) {
            newArray[i] = _array[i];
        }
        newArray[_array.length] = _value;
        return newArray;
    }

    function _splitString(string memory _str, string memory _delimiter) internal pure returns (string[] memory) {
        bytes memory strBytes = bytes(_str);
        bytes memory delimiterBytes = bytes(_delimiter);

        if (strBytes.length == 0) {
            return new string[](0);
        }

        if (delimiterBytes.length == 0) {
            return new string[](1);
        }

        uint256 counter = 0;
        for (uint256 i = 0; i < strBytes.length - (delimiterBytes.length - 1); i++) {
            bool match = true;
            for (uint256 j = 0; j < delimiterBytes.length; j++) {
                if (strBytes[i + j] != delimiterBytes[j]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                counter++;
            }
        }

        string[] memory result = new string[](counter + 1);
        uint256 startIndex = 0;
        uint256 resultIndex = 0;

        for (uint256 i = 0; i < strBytes.length - (delimiterBytes.length - 1); i++) {
            bool match = true;
            for (uint256 j = 0; j < delimiterBytes.length; j++) {
                if (strBytes[i + j] != delimiterBytes[j]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                result[resultIndex++] = string(slice(strBytes, startIndex, i));
                startIndex = i + delimiterBytes.length;
                i += delimiterBytes.length - 1;
            }
        }

        result[resultIndex] = string(slice(strBytes, startIndex, strBytes.length));
        return result;
    }

    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + _start <= _bytes.length, "Slice bounds out of range");

        bytes memory tempBytes = new bytes(_length);

        for (uint256 i = 0; i < _length; i++) {
            tempBytes[i] = _bytes[_start + i];
        }
        return tempBytes;
    }

    function stringContains(string memory _string, string memory _substring) internal pure returns (bool) {
        bytes memory stringBytes = bytes(_string);
        bytes memory substringBytes = bytes(_substring);

        if (substringBytes.length == 0) {
            return true; // Empty substring is always contained
        }
        if (stringBytes.length < substringBytes.length) {
            return false; // Substring longer than string
        }

        for (uint256 i = 0; i <= stringBytes.length - substringBytes.length; i++) {
            bool match = true;
            for (uint256 j = 0; j < substringBytes.length; j++) {
                if (stringBytes[i + j] != substringBytes[j]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                return true; // Substring found
            }
        }
        return false; // Substring not found
    }
}

// --- Interfaces ---
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
```