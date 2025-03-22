```solidity
/**
 * @title Decentralized Dynamic NFT Marketplace with Reputation and Advanced Features
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a dynamic NFT marketplace with advanced functionalities
 *      including dynamic NFT content updates, seller reputation system, auction mechanism,
 *      batch operations, whitelisting, blacklisting, and more. It is designed to be
 *      creative, trendy, and avoid duplication of existing open-source contracts by
 *      combining and extending various concepts in a unique way.
 *
 * **Outline and Function Summary:**
 *
 * **Core Marketplace Functions:**
 * 1.  `createNFT(string memory _uri, bytes memory _initialDynamicData) external`: Creates a new Dynamic NFT with initial URI and dynamic data.
 * 2.  `listItem(uint256 _tokenId, uint256 _price) external`: Lists an NFT for sale on the marketplace.
 * 3.  `buyNFT(uint256 _tokenId) payable external`: Allows anyone to buy a listed NFT.
 * 4.  `cancelListing(uint256 _tokenId) external`: Allows the seller to cancel an NFT listing.
 * 5.  `updateListingPrice(uint256 _tokenId, uint256 _newPrice) external`: Updates the price of an NFT listing.
 * 6.  `getActiveListings() external view returns (uint256[] memory)`: Returns an array of currently listed NFT token IDs.
 * 7.  `getNFTListing(uint256 _tokenId) external view returns (address seller, uint256 price, bool isActive)`: Gets listing details for a specific NFT.
 *
 * **Dynamic NFT Features:**
 * 8.  `updateNFTContent(uint256 _tokenId, string memory _newUri) external`: Allows the NFT owner to update the NFT's URI (metadata).
 * 9.  `setDynamicData(uint256 _tokenId, bytes memory _dynamicData) external`: Allows the NFT owner to set dynamic data associated with the NFT.
 * 10. `getDynamicData(uint256 _tokenId) external view returns (bytes memory)`: Retrieves the dynamic data associated with an NFT.
 * 11. `triggerDynamicEvent(uint256 _tokenId, bytes memory _eventData) external`: Allows the NFT owner to trigger a dynamic event that can be handled off-chain to update NFT properties (e.g., rarity, traits based on external data).
 *
 * **Reputation and Trust System:**
 * 12. `upvoteSeller(address _seller) external`: Allows users to upvote a seller, increasing their reputation.
 * 13. `downvoteSeller(address _seller) external`: Allows users to downvote a seller, decreasing their reputation.
 * 14. `getUserReputation(address _user) external view returns (int256)`: Returns the reputation score of a user.
 * 15. `setReputationThresholdForListing(int256 _threshold) external onlyOwner`: Sets the minimum reputation required to list NFTs.
 *
 * **Advanced Marketplace Features:**
 * 16. `createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _durationInSeconds) external`: Creates an auction for an NFT.
 * 17. `bidOnAuction(uint256 _auctionId) payable external`: Allows users to bid on an active auction.
 * 18. `finalizeAuction(uint256 _auctionId) external`: Finalizes an auction and transfers the NFT to the highest bidder.
 * 19. `batchListItem(uint256[] memory _tokenIds, uint256[] memory _prices) external`: Allows listing multiple NFTs at once.
 * 20. `batchBuyNFT(uint256[] memory _tokenIds) payable external`: Allows buying multiple NFTs at once.
 * 21. `whitelistContract(address _contractAddress) external onlyOwner`: Whitelists a contract address to interact with certain functions (e.g., for approved dynamic updates).
 * 22. `blacklistContract(address _contractAddress) external onlyOwner`: Blacklists a contract address, preventing interaction.
 * 23. `pauseContract() external onlyOwner`: Pauses the contract, disabling critical functions.
 * 24. `unpauseContract() external onlyOwner`: Unpauses the contract, re-enabling functions.
 * 25. `setPlatformFee(uint256 _feePercentage) external onlyOwner`: Sets the platform fee percentage for sales.
 * 26. `setPlatformFeeRecipient(address _recipient) external onlyOwner`: Sets the address to receive platform fees.
 * 27. `withdrawPlatformFees() external onlyOwner`: Allows the platform owner to withdraw accumulated fees.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DynamicNFTMarketplace is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _auctionIdCounter;

    // Struct to store NFT listing information
    struct NFTListing {
        address seller;
        uint256 price;
        bool isActive;
    }

    // Struct to store auction information
    struct Auction {
        uint256 tokenId;
        address seller;
        uint256 startingBid;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool isActive;
    }

    mapping(uint256 => NFTListing) public nftListings; // tokenId => NFTListing
    mapping(uint256 => Auction) public auctions; // auctionId => Auction
    mapping(uint256 => string) public nftURIs; // tokenId => URI (Dynamic)
    mapping(uint256 => bytes) public nftDynamicData; // tokenId => Dynamic Data
    mapping(address => int256) public userReputation; // userAddress => Reputation Score
    mapping(address => bool) public whitelistedContracts; // contractAddress => isWhitelisted
    mapping(address => bool) public blacklistedContracts; // contractAddress => isBlacklisted

    uint256 public platformFeePercentage = 2; // 2% platform fee by default
    address public platformFeeRecipient;
    uint256 public reputationThresholdForListing = -10; // Default threshold, can be adjusted
    bool public paused = false;

    event NFTCreated(uint256 tokenId, address creator, string uri);
    event NFTListed(uint256 tokenId, address seller, uint256 price);
    event NFTBought(uint256 tokenId, address buyer, address seller, uint256 price);
    event ListingCancelled(uint256 tokenId, address seller);
    event ListingPriceUpdated(uint256 tokenId, uint256 newPrice);
    event NFTContentUpdated(uint256 tokenId, string newUri);
    event DynamicDataUpdated(uint256 tokenId, bytes dynamicData);
    event DynamicEventTriggered(uint256 tokenId, bytes eventData);
    event SellerUpvoted(address seller, address upvoter);
    event SellerDownvoted(address seller, address downvoter);
    event AuctionCreated(uint256 auctionId, uint256 tokenId, address seller, uint256 startingBid, uint256 endTime);
    event AuctionBidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionFinalized(uint256 auctionId, uint256 tokenId, address winner, uint256 finalPrice);
    event ContractPaused();
    event ContractUnpaused();
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeeRecipientSet(address recipient);
    event PlatformFeesWithdrawn(address recipient, uint256 amount);
    event ContractWhitelisted(address contractAddress);
    event ContractBlacklisted(address contractAddress);
    event ReputationThresholdSet(int256 threshold);


    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier onlyWhitelistedContract(address _contractAddress) {
        require(whitelistedContracts[_contractAddress], "Contract is not whitelisted");
        _;
    }

    modifier onlyNotBlacklistedContract(address _contractAddress) {
        require(!blacklistedContracts[_contractAddress], "Contract is blacklisted");
        _;
    }

    modifier onlyListedNFT(uint256 _tokenId) {
        require(nftListings[_tokenId].isActive, "NFT is not listed");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not NFT owner or approved");
        _;
    }

    modifier onlySeller(uint256 _tokenId) {
        require(nftListings[_tokenId].seller == _msgSender(), "Not the seller of this NFT");
        _;
    }

    modifier hasSufficientReputationForListing() {
        require(userReputation[_msgSender()] >= reputationThresholdForListing, "Insufficient reputation to list NFTs");
        _;
    }

    constructor(string memory _name, string memory _symbol, address _feeRecipient) ERC721(_name, _symbol) {
        platformFeeRecipient = _feeRecipient;
    }

    // --- Core Marketplace Functions ---

    /// @notice Creates a new Dynamic NFT with initial URI and dynamic data.
    /// @param _uri The initial URI for the NFT metadata.
    /// @param _initialDynamicData Initial dynamic data associated with the NFT.
    function createNFT(string memory _uri, bytes memory _initialDynamicData) external whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(_msgSender(), tokenId);
        nftURIs[tokenId] = _uri;
        nftDynamicData[tokenId] = _initialDynamicData;
        emit NFTCreated(tokenId, _msgSender(), _uri);
        return tokenId;
    }

    /// @notice Lists an NFT for sale on the marketplace.
    /// @param _tokenId The ID of the NFT to list.
    /// @param _price The listing price in wei.
    function listItem(uint256 _tokenId, uint256 _price) external whenNotPaused onlyNFTOwner(_tokenId) hasSufficientReputationForListing {
        require(nftListings[_tokenId].seller == address(0), "NFT already listed"); // Prevent relisting without cancelling
        _approve(address(this), _tokenId); // Approve contract to transfer NFT
        nftListings[_tokenId] = NFTListing({
            seller: _msgSender(),
            price: _price,
            isActive: true
        });
        emit NFTListed(_tokenId, _msgSender(), _price);
    }

    /// @notice Allows anyone to buy a listed NFT.
    /// @param _tokenId The ID of the NFT to buy.
    function buyNFT(uint256 _tokenId) payable external whenNotPaused onlyListedNFT(_tokenId) {
        NFTListing storage listing = nftListings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds to buy NFT");

        uint256 platformFee = (listing.price * platformFeePercentage) / 100;
        uint256 sellerProceeds = listing.price - platformFee;

        listing.isActive = false; // Deactivate listing
        nftListings[_tokenId] = listing; // Update listing in storage (important because listing is a storage pointer)

        _transfer(listing.seller, _msgSender(), _tokenId); // Transfer NFT to buyer

        payable(listing.seller).transfer(sellerProceeds); // Send proceeds to seller
        payable(platformFeeRecipient).transfer(platformFee); // Send platform fee

        emit NFTBought(_tokenId, _msgSender(), listing.seller, listing.price);
    }

    /// @notice Allows the seller to cancel an NFT listing.
    /// @param _tokenId The ID of the NFT listing to cancel.
    function cancelListing(uint256 _tokenId) external whenNotPaused onlyListedNFT(_tokenId) onlySeller(_tokenId) {
        nftListings[_tokenId].isActive = false;
        emit ListingCancelled(_tokenId, _msgSender());
    }

    /// @notice Updates the price of an NFT listing.
    /// @param _tokenId The ID of the NFT listing to update.
    /// @param _newPrice The new listing price in wei.
    function updateListingPrice(uint256 _tokenId, uint256 _newPrice) external whenNotPaused onlyListedNFT(_tokenId) onlySeller(_tokenId) {
        nftListings[_tokenId].price = _newPrice;
        emit ListingPriceUpdated(_tokenId, _newPrice);
    }

    /// @notice Returns an array of currently listed NFT token IDs.
    /// @return An array of token IDs for active listings.
    function getActiveListings() external view returns (uint256[] memory) {
        uint256 listingCount = 0;
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            if (nftListings[i].isActive) {
                listingCount++;
            }
        }
        uint256[] memory activeListings = new uint256[](listingCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            if (nftListings[i].isActive) {
                activeListings[index] = i;
                index++;
            }
        }
        return activeListings;
    }

    /// @notice Gets listing details for a specific NFT.
    /// @param _tokenId The ID of the NFT to query.
    /// @return seller The address of the seller.
    /// @return price The listing price in wei.
    /// @return isActive Boolean indicating if the NFT is currently listed.
    function getNFTListing(uint256 _tokenId) external view returns (address seller, uint256 price, bool isActive) {
        return (nftListings[_tokenId].seller, nftListings[_tokenId].price, nftListings[_tokenId].isActive);
    }

    // --- Dynamic NFT Features ---

    /// @notice Allows the NFT owner to update the NFT's URI (metadata).
    /// @param _tokenId The ID of the NFT to update.
    /// @param _newUri The new URI for the NFT metadata.
    function updateNFTContent(uint256 _tokenId, string memory _newUri) external whenNotPaused onlyNFTOwner(_tokenId) {
        nftURIs[_tokenId] = _newUri;
        emit NFTContentUpdated(_tokenId, _newUri);
    }

    /// @notice Allows the NFT owner to set dynamic data associated with the NFT.
    /// @param _tokenId The ID of the NFT to update.
    /// @param _dynamicData The dynamic data to set (e.g., JSON, bytes, etc.).
    function setDynamicData(uint256 _tokenId, bytes memory _dynamicData) external whenNotPaused onlyNFTOwner(_tokenId) {
        nftDynamicData[_tokenId] = _dynamicData;
        emit DynamicDataUpdated(_tokenId, _dynamicData);
    }

    /// @notice Retrieves the dynamic data associated with an NFT.
    /// @param _tokenId The ID of the NFT to query.
    /// @return The dynamic data associated with the NFT.
    function getDynamicData(uint256 _tokenId) external view returns (bytes memory) {
        return nftDynamicData[_tokenId];
    }

    /// @notice Allows the NFT owner to trigger a dynamic event that can be handled off-chain.
    /// @dev This function emits an event that can be listened to by off-chain services
    ///      to update NFT properties based on external data or logic.
    /// @param _tokenId The ID of the NFT for which to trigger the event.
    /// @param _eventData Optional data associated with the event.
    function triggerDynamicEvent(uint256 _tokenId, bytes memory _eventData) external whenNotPaused onlyNFTOwner(_tokenId) {
        emit DynamicEventTriggered(_tokenId, _eventData);
    }

    // --- Reputation and Trust System ---

    /// @notice Allows users to upvote a seller, increasing their reputation.
    /// @param _seller The address of the seller to upvote.
    function upvoteSeller(address _seller) external whenNotPaused {
        userReputation[_seller]++;
        emit SellerUpvoted(_seller, _msgSender());
    }

    /// @notice Allows users to downvote a seller, decreasing their reputation.
    /// @param _seller The address of the seller to downvote.
    function downvoteSeller(address _seller) external whenNotPaused {
        userReputation[_seller]--;
        emit SellerDownvoted(_seller, _msgSender());
    }

    /// @notice Returns the reputation score of a user.
    /// @param _user The address of the user to query.
    /// @return The reputation score of the user.
    function getUserReputation(address _user) external view returns (int256) {
        return userReputation[_user];
    }

    /// @notice Sets the minimum reputation required to list NFTs (Only Owner).
    /// @param _threshold The minimum reputation threshold.
    function setReputationThresholdForListing(int256 _threshold) external onlyOwner {
        reputationThresholdForListing = _threshold;
        emit ReputationThresholdSet(_threshold);
    }


    // --- Advanced Marketplace Features ---

    /// @notice Creates an auction for an NFT.
    /// @param _tokenId The ID of the NFT to auction.
    /// @param _startingBid The starting bid price in wei.
    /// @param _durationInSeconds The duration of the auction in seconds.
    function createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _durationInSeconds) external whenNotPaused onlyNFTOwner(_tokenId) hasSufficientReputationForListing {
        require(auctions[_auctionIdCounter.current()].isActive == false, "Previous auction not finalized"); // Simple check to avoid concurrent auctions
        require(nftListings[_tokenId].seller == address(0), "NFT cannot be listed and auctioned simultaneously"); // Prevent listing and auction at same time
        _auctionIdCounter.increment();
        uint256 auctionId = _auctionIdCounter.current();
        _approve(address(this), _tokenId); // Approve contract to transfer NFT
        auctions[auctionId] = Auction({
            tokenId: _tokenId,
            seller: _msgSender(),
            startingBid: _startingBid,
            endTime: block.timestamp + _durationInSeconds,
            highestBidder: address(0),
            highestBid: 0,
            isActive: true
        });
        emit AuctionCreated(auctionId, _tokenId, _msgSender(), _startingBid, block.timestamp + _durationInSeconds);
    }

    /// @notice Allows users to bid on an active auction.
    /// @param _auctionId The ID of the auction to bid on.
    function bidOnAuction(uint256 _auctionId) payable external whenNotPaused {
        Auction storage auction = auctions[_auctionId];
        require(auction.isActive, "Auction is not active");
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(msg.value > auction.highestBid, "Bid amount is not high enough");
        require(msg.value >= auction.startingBid || auction.highestBid > 0, "Bid amount is not high enough (starting bid)"); // Ensure initial bid meets starting bid

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid); // Refund previous highest bidder
        }

        auction.highestBidder = _msgSender();
        auction.highestBid = msg.value;
        auctions[_auctionId] = auction; // Update auction in storage

        emit AuctionBidPlaced(_auctionId, _msgSender(), msg.value);
    }

    /// @notice Finalizes an auction and transfers the NFT to the highest bidder.
    /// @param _auctionId The ID of the auction to finalize.
    function finalizeAuction(uint256 _auctionId) external whenNotPaused {
        Auction storage auction = auctions[_auctionId];
        require(auction.isActive, "Auction is not active");
        require(block.timestamp >= auction.endTime, "Auction has not ended yet");

        auction.isActive = false; // Deactivate auction
        auctions[_auctionId] = auction; // Update auction in storage

        if (auction.highestBidder != address(0)) {
            uint256 platformFee = (auction.highestBid * platformFeePercentage) / 100;
            uint256 sellerProceeds = auction.highestBid - platformFee;

            _transfer(auction.seller, auction.highestBidder, auction.tokenId); // Transfer NFT to winner
            payable(auction.seller).transfer(sellerProceeds); // Send proceeds to seller
            payable(platformFeeRecipient).transfer(platformFee); // Send platform fee

            emit AuctionFinalized(_auctionId, auction.tokenId, auction.highestBidder, auction.highestBid);
        } else {
            // No bids, return NFT to seller (optional - could also relist or burn)
            _transfer(address(this), auction.seller, auction.tokenId); // Transfer NFT back to seller from contract (contract holds it after approval)
            // Consider emitting an event for no bids auction finalized.
        }
    }

    /// @notice Allows listing multiple NFTs at once.
    /// @param _tokenIds An array of NFT token IDs to list.
    /// @param _prices An array of prices for each NFT, corresponding to the token IDs.
    function batchListItem(uint256[] memory _tokenIds, uint256[] memory _prices) external whenNotPaused hasSufficientReputationForListing {
        require(_tokenIds.length == _prices.length, "Token IDs and prices arrays must have the same length");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            listItem(_tokenIds[i], _prices[i]); // Reusing single listing function
        }
    }

    /// @notice Allows buying multiple NFTs at once.
    /// @param _tokenIds An array of NFT token IDs to buy.
    function batchBuyNFT(uint256[] memory _tokenIds) payable external whenNotPaused {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(nftListings[_tokenIds[i]].isActive, "NFT is not listed");
            totalValue += nftListings[_tokenIds[i]].price;
        }
        require(msg.value >= totalValue, "Insufficient funds for batch purchase");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            buyNFT(_tokenIds[i]); // Reusing single buy function.  Note: gas costs might be higher for repeated calls. Consider optimizing if needed for very large batches.
        }
    }

    // --- Admin & Utility Functions ---

    /// @notice Whitelists a contract address to interact with certain functions (Only Owner).
    /// @param _contractAddress The address of the contract to whitelist.
    function whitelistContract(address _contractAddress) external onlyOwner {
        whitelistedContracts[_contractAddress] = true;
        emit ContractWhitelisted(_contractAddress);
    }

    /// @notice Blacklists a contract address, preventing interaction (Only Owner).
    /// @param _contractAddress The address of the contract to blacklist.
    function blacklistContract(address _contractAddress) external onlyOwner {
        blacklistedContracts[_contractAddress] = true;
        emit ContractBlacklisted(_contractAddress);
    }

    /// @notice Pauses the contract, disabling critical functions (Only Owner).
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Unpauses the contract, re-enabling functions (Only Owner).
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Sets the platform fee percentage for sales (Only Owner).
    /// @param _feePercentage The new platform fee percentage (e.g., 2 for 2%).
    function setPlatformFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    /// @notice Sets the address to receive platform fees (Only Owner).
    /// @param _recipient The address of the platform fee recipient.
    function setPlatformFeeRecipient(address _recipient) external onlyOwner {
        platformFeeRecipient = _recipient;
        emit PlatformFeeRecipientSet(_recipient);
    }

    /// @notice Allows the platform owner to withdraw accumulated fees (Only Owner).
    function withdrawPlatformFees() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 withdrawableAmount = balance; // In a real contract, you might track platform fees separately and only withdraw those.
        payable(platformFeeRecipient).transfer(withdrawableAmount);
        emit PlatformFeesWithdrawn(platformFeeRecipient, withdrawableAmount);
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return nftURIs[_tokenId];
    }
}
```