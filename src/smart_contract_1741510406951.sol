```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI-Powered Curation & Personalized Experiences
 * @author Bard (Example - Replace with your name)
 * @dev A sophisticated NFT marketplace featuring dynamic NFTs, AI-driven curation, personalized recommendations,
 *      advanced bidding mechanisms, decentralized governance, and creator-centric royalty and feature controls.
 *
 * **Outline & Function Summary:**
 *
 * **Core Functionality:**
 * 1. `createDynamicNFTCollection(string memory _name, string memory _symbol, string memory _baseURI, address _royaltyRecipient, uint256 _royaltyPercentage)`: Allows the contract owner to deploy a new Dynamic NFT collection with custom settings.
 * 2. `mintDynamicNFT(address _collectionAddress, string memory _metadataURI, uint256[] memory _dynamicTraits)`: Mints a new Dynamic NFT within a specified collection.
 * 3. `updateDynamicNFTTraits(address _collectionAddress, uint256 _tokenId, uint256[] memory _newTraits)`: Allows the NFT owner or authorized updater to modify the dynamic traits of an NFT.
 * 4. `listNFTForSale(address _collectionAddress, uint256 _tokenId, uint256 _price)`: Lists an NFT for sale at a fixed price.
 * 5. `buyNFT(address _collectionAddress, uint256 _tokenId)`: Allows a buyer to purchase a listed NFT.
 * 6. `cancelNFTSale(address _collectionAddress, uint256 _tokenId)`: Cancels an NFT listing, removing it from the marketplace.
 * 7. `placeBid(address _collectionAddress, uint256 _tokenId, uint256 _bidAmount)`: Places a bid on an NFT (if bidding enabled for the collection).
 * 8. `acceptBid(address _collectionAddress, uint256 _tokenId, uint256 _bidId)`: Accepts a specific bid for an NFT, completing the sale.
 * 9. `rejectBid(address _collectionAddress, uint256 _tokenId, uint256 _bidId)`: Rejects a specific bid for an NFT, returning the bidder's funds.
 * 10. `withdrawBid(address _collectionAddress, uint256 _tokenId, uint256 _bidId)`: Allows a bidder to withdraw their bid before it's accepted or rejected.
 * 11. `setCollectionMarketplaceFee(address _collectionAddress, uint256 _feePercentage)`: Sets the marketplace fee percentage for a specific collection.
 * 12. `setMarketplaceFeeRecipient(address _recipient)`: Sets the address that receives marketplace fees.
 * 13. `setDynamicTraitUpdater(address _collectionAddress, address _updaterAddress, bool _isUpdater)`: Authorizes or revokes an address to update dynamic traits for a specific collection.
 * 14. `setUserPreferences(string memory _preferencesJson)`: Allows users to set their marketplace preferences (used for AI curation - off-chain processing).
 * 15. `reportNFT(address _collectionAddress, uint256 _tokenId, string memory _reportReason)`: Allows users to report NFTs for policy violations (triggers off-chain AI moderation).
 * 16. `pauseCollectionTrading(address _collectionAddress)`: Pauses trading for a specific NFT collection (governance or admin function).
 * 17. `unpauseCollectionTrading(address _collectionAddress)`: Resumes trading for a paused NFT collection (governance or admin function).
 * 18. `enableCollectionBidding(address _collectionAddress, bool _enableBidding)`: Enables or disables bidding functionality for a specific collection.
 * 19. `setCollectionRoyalty(address _collectionAddress, address _royaltyRecipient, uint256 _royaltyPercentage)`: Updates the royalty settings for an existing NFT collection.
 * 20. `withdrawMarketplaceFees()`: Allows the marketplace fee recipient to withdraw accumulated fees.
 * 21. `getNFTListingDetails(address _collectionAddress, uint256 _tokenId)`: Retrieves detailed listing information for a specific NFT.
 * 22. `getCollectionDetails(address _collectionAddress)`: Retrieves details about an NFT collection, including fees and settings.
 *
 * **Advanced Concepts:**
 * - Dynamic NFTs: NFTs with traits that can be updated, reflecting in-game progress, data feeds, or external events.
 * - AI-Powered Curation (Off-chain integration): User preferences and NFT reports can be processed by an off-chain AI for personalized recommendations and content moderation.
 * - Advanced Bidding: Offers bidding system with bid placement, acceptance, rejection, and withdrawal functionalities.
 * - Decentralized Governance (Potential extension): Functions like pausing/unpausing collections can be tied to a governance mechanism in a future iteration.
 * - Creator-Centric Features: Customizable royalty percentages and recipient addresses per collection.
 */

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DynamicNFTMarketplace is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- Structs and Enums ---

    struct NFTListing {
        address seller;
        uint256 price;
        bool isListed;
    }

    struct Bid {
        address bidder;
        uint256 bidAmount;
        bool isActive;
    }

    struct CollectionDetails {
        string name;
        string symbol;
        string baseURI;
        address royaltyRecipient;
        uint256 royaltyPercentage;
        uint256 marketplaceFeePercentage;
        bool isBiddingEnabled;
        bool isTradingPaused;
    }

    // --- State Variables ---

    mapping(address => CollectionDetails) public collectionDetails; // Collection address => Collection details
    mapping(address => mapping(uint256 => NFTListing)) public nftListings; // Collection address => Token ID => Listing details
    mapping(address => mapping(uint256 => mapping(uint256 => Bid))) public nftBids; // Collection address => Token ID => Bid ID => Bid details
    mapping(address => mapping(address => bool)) public collectionDynamicTraitUpdaters; // Collection address => Updater address => Is Updater
    mapping(address => bool) public isCollectionDeployed; // Track deployed collection contracts
    mapping(address => bool) public isTradingPausedForCollection; // Track paused collections

    address public marketplaceFeeRecipient;
    uint256 public defaultMarketplaceFeePercentage = 250; // 2.5% in basis points (10000 = 100%)
    uint256 public bidCounter; // Global bid counter across all collections

    // --- Events ---

    event CollectionCreated(address collectionAddress, string name, string symbol, address creator);
    event NFTMinted(address collectionAddress, uint256 tokenId, address minter);
    event DynamicTraitsUpdated(address collectionAddress, uint256 tokenId, uint256[] newTraits, address updater);
    event NFTListed(address collectionAddress, uint256 tokenId, uint256 price, address seller);
    event NFTBought(address collectionAddress, uint256 tokenId, uint256 price, address buyer, address seller);
    event NFTSaleCancelled(address collectionAddress, uint256 tokenId, address seller);
    event BidPlaced(address collectionAddress, uint256 tokenId, uint256 bidId, uint256 bidAmount, address bidder);
    event BidAccepted(address collectionAddress, uint256 tokenId, uint256 bidId, uint256 bidAmount, address buyer, address seller);
    event BidRejected(address collectionAddress, uint256 tokenId, uint256 bidId, address bidder);
    event BidWithdrawn(address collectionAddress, uint256 tokenId, uint256 bidId, address bidder);
    event MarketplaceFeeUpdated(address collectionAddress, uint256 feePercentage, address admin);
    event MarketplaceFeeRecipientUpdated(address recipient, address admin);
    event DynamicTraitUpdaterSet(address collectionAddress, address updaterAddress, bool isUpdater, address admin);
    event UserPreferencesSet(address user, string preferencesJson);
    event NFTReported(address collectionAddress, uint256 tokenId, string reportReason, address reporter);
    event CollectionTradingPaused(address collectionAddress, address admin);
    event CollectionTradingUnpaused(address collectionAddress, address admin);
    event CollectionBiddingEnabled(address collectionAddress, bool enabled, address admin);
    event CollectionRoyaltyUpdated(address collectionAddress, address royaltyRecipient, uint256 royaltyPercentage, address admin);
    event MarketplaceFeesWithdrawn(address recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyCollectionOwner(address _collectionAddress) {
        DynamicNFTCollection collection = DynamicNFTCollection(_collectionAddress);
        require(collection.owner() == _msgSender(), "Not collection owner");
        _;
    }

    modifier validCollection(address _collectionAddress) {
        require(isCollectionDeployed[_collectionAddress], "Invalid collection address");
        _;
    }

    modifier tradingActive(address _collectionAddress) {
        require(!isTradingPausedForCollection[_collectionAddress], "Trading paused for this collection");
        _;
    }

    modifier biddingEnabledForCollection(address _collectionAddress) {
        require(collectionDetails[_collectionAddress].isBiddingEnabled, "Bidding is not enabled for this collection");
        _;
    }

    modifier validNFT(address _collectionAddress, uint256 _tokenId) {
        DynamicNFTCollection collection = DynamicNFTCollection(_collectionAddress);
        require(collection.exists(_tokenId), "NFT does not exist in collection");
        _;
    }

    modifier isNFTOwner(address _collectionAddress, uint256 _tokenId) {
        DynamicNFTCollection collection = DynamicNFTCollection(_collectionAddress);
        require(collection.ownerOf(_tokenId) == _msgSender(), "Not NFT owner");
        _;
    }

    modifier isDynamicTraitUpdater(address _collectionAddress) {
        require(collectionDynamicTraitUpdaters[_collectionAddress][_msgSender()], "Not authorized dynamic trait updater");
        _;
    }

    modifier nftNotListed(address _collectionAddress, uint256 _tokenId) {
        require(!nftListings[_collectionAddress][_tokenId].isListed, "NFT already listed");
        _;
    }

    modifier nftListed(address _collectionAddress, uint256 _tokenId) {
        require(nftListings[_collectionAddress][_tokenId].isListed, "NFT not listed");
        _;
    }

    modifier sellerIsListingOwner(address _collectionAddress, uint256 _tokenId) {
        require(nftListings[_collectionAddress][_tokenId].seller == _msgSender(), "Not listing owner");
        _;
    }

    // --- Constructor ---

    constructor(address _feeRecipient) payable {
        marketplaceFeeRecipient = _feeRecipient;
    }

    // --- Collection Management Functions ---

    function createDynamicNFTCollection(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _royaltyRecipient,
        uint256 _royaltyPercentage
    ) external onlyOwner returns (address) {
        require(_royaltyPercentage <= 10000, "Royalty percentage too high (max 100%)"); // Max 100% royalty
        DynamicNFTCollection newCollection = new DynamicNFTCollection(_name, _symbol, _baseURI);
        collectionDetails[address(newCollection)] = CollectionDetails({
            name: _name,
            symbol: _symbol,
            baseURI: _baseURI,
            royaltyRecipient: _royaltyRecipient,
            royaltyPercentage: _royaltyPercentage,
            marketplaceFeePercentage: defaultMarketplaceFeePercentage,
            isBiddingEnabled: false, // Bidding disabled by default
            isTradingPaused: false // Trading active by default
        });
        isCollectionDeployed[address(newCollection)] = true;
        emit CollectionCreated(address(newCollection), _name, _symbol, _msgSender());
        return address(newCollection);
    }

    function setCollectionRoyalty(address _collectionAddress, address _royaltyRecipient, uint256 _royaltyPercentage)
        external onlyOwner validCollection(_collectionAddress)
    {
        require(_royaltyPercentage <= 10000, "Royalty percentage too high (max 100%)");
        collectionDetails[_collectionAddress].royaltyRecipient = _royaltyRecipient;
        collectionDetails[_collectionAddress].royaltyPercentage = _royaltyPercentage;
        emit CollectionRoyaltyUpdated(_collectionAddress, _royaltyRecipient, _royaltyPercentage, _msgSender());
    }


    function setCollectionMarketplaceFee(address _collectionAddress, uint256 _feePercentage)
        external onlyOwner validCollection(_collectionAddress)
    {
        require(_feePercentage <= 10000, "Marketplace fee percentage too high (max 100%)");
        collectionDetails[_collectionAddress].marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeUpdated(_collectionAddress, _feePercentage, _msgSender());
    }

    function setMarketplaceFeeRecipient(address _recipient) external onlyOwner {
        marketplaceFeeRecipient = _recipient;
        emit MarketplaceFeeRecipientUpdated(_recipient, _msgSender());
    }

    function setDynamicTraitUpdater(address _collectionAddress, address _updaterAddress, bool _isUpdater)
        external onlyCollectionOwner(_collectionAddress) validCollection(_collectionAddress)
    {
        collectionDynamicTraitUpdaters[_collectionAddress][_updaterAddress] = _isUpdater;
        emit DynamicTraitUpdaterSet(_collectionAddress, _updaterAddress, _isUpdater, _msgSender());
    }

    function pauseCollectionTrading(address _collectionAddress)
        external onlyOwner validCollection(_collectionAddress)
    {
        isTradingPausedForCollection[_collectionAddress] = true;
        emit CollectionTradingPaused(_collectionAddress, _msgSender());
    }

    function unpauseCollectionTrading(address _collectionAddress)
        external onlyOwner validCollection(_collectionAddress)
    {
        isTradingPausedForCollection[_collectionAddress] = false;
        emit CollectionTradingUnpaused(_collectionAddress, _msgSender());
    }

    function enableCollectionBidding(address _collectionAddress, bool _enableBidding)
        external onlyOwner validCollection(_collectionAddress)
    {
        collectionDetails[_collectionAddress].isBiddingEnabled = _enableBidding;
        emit CollectionBiddingEnabled(_collectionAddress, _enableBidding, _msgSender());
    }


    // --- NFT Minting and Dynamic Trait Functions ---

    function mintDynamicNFT(address _collectionAddress, string memory _metadataURI, uint256[] memory _dynamicTraits)
        external onlyCollectionOwner(_collectionAddress) validCollection(_collectionAddress)
    {
        DynamicNFTCollection collection = DynamicNFTCollection(_collectionAddress);
        uint256 tokenId = collection.nextTokenIdCounter(); // Get the next token ID before minting
        collection.mint(_msgSender(), tokenId, _metadataURI, _dynamicTraits);
        emit NFTMinted(_collectionAddress, tokenId, _msgSender());
    }

    function updateDynamicNFTTraits(address _collectionAddress, uint256 _tokenId, uint256[] memory _newTraits)
        external validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId)
        tradingActive(_collectionAddress)
    {
        DynamicNFTCollection collection = DynamicNFTCollection(_collectionAddress);
        require(collection.ownerOf(_tokenId) == _msgSender() || collectionDynamicTraitUpdaters[_collectionAddress][_msgSender()], "Not NFT owner or authorized updater");
        collection.updateDynamicTraits(_tokenId, _newTraits);
        emit DynamicTraitsUpdated(_collectionAddress, _tokenId, _newTraits, _msgSender());
    }


    // --- Marketplace Listing and Buying Functions ---

    function listNFTForSale(address _collectionAddress, uint256 _tokenId, uint256 _price)
        external validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId)
        isNFTOwner(_collectionAddress, _tokenId) tradingActive(_collectionAddress) nftNotListed(_collectionAddress, _tokenId)
    {
        nftListings[_collectionAddress][_tokenId] = NFTListing({
            seller: _msgSender(),
            price: _price,
            isListed: true
        });
        DynamicNFTCollection collection = DynamicNFTCollection(_collectionAddress);
        collection.approve(address(this), _tokenId); // Approve marketplace to handle transfer
        emit NFTListed(_collectionAddress, _tokenId, _price, _msgSender());
    }

    function buyNFT(address _collectionAddress, uint256 _tokenId)
        external payable validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId)
        tradingActive(_collectionAddress) nftListed(_collectionAddress, _tokenId) nonReentrant
    {
        NFTListing storage listing = nftListings[_collectionAddress][_tokenId];
        require(_msgSender() != listing.seller, "Seller cannot buy their own NFT");
        require(msg.value >= listing.price, "Insufficient funds sent");

        DynamicNFTCollection collection = DynamicNFTCollection(_collectionAddress);
        uint256 royaltyAmount = listing.price.mul(collectionDetails[_collectionAddress].royaltyPercentage).div(10000);
        uint256 marketplaceFee = listing.price.mul(collectionDetails[_collectionAddress].marketplaceFeePercentage).div(10000).sub(royaltyAmount); // Fee after royalty.

        // Transfer funds
        payable(listing.seller).transfer(listing.price.sub(royaltyAmount).sub(marketplaceFee)); // Seller receives price - royalty - marketplace fee.
        payable(collectionDetails[_collectionAddress].royaltyRecipient).transfer(royaltyAmount); // Royalty recipient gets royalty amount.
        // Marketplace fee is kept within the contract to be withdrawn later by the fee recipient.

        collection.safeTransferFrom(listing.seller, _msgSender(), _tokenId);

        listing.isListed = false;
        delete nftListings[_collectionAddress][_tokenId]; // Clean up listing

        emit NFTBought(_collectionAddress, _tokenId, listing.price, _msgSender(), listing.seller);

        // Keep marketplace fee in contract, ready to be withdrawn.
        payable(address(this)).transfer(marketplaceFee);
    }

    function cancelNFTSale(address _collectionAddress, uint256 _tokenId)
        external validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId)
        tradingActive(_collectionAddress) nftListed(_collectionAddress, _tokenId) sellerIsListingOwner(_collectionAddress, _tokenId)
    {
        nftListings[_collectionAddress][_tokenId].isListed = false;
        delete nftListings[_collectionAddress][_tokenId];
        emit NFTSaleCancelled(_collectionAddress, _tokenId, _msgSender());
    }


    // --- Bidding Functions ---

    function placeBid(address _collectionAddress, uint256 _tokenId, uint256 _bidAmount)
        external payable validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId)
        tradingActive(_collectionAddress) biddingEnabledForCollection(_collectionAddress)
    {
        require(msg.value >= _bidAmount, "Insufficient bid amount sent");
        require(_msgSender() != nftListings[_collectionAddress][_tokenId].seller, "Seller cannot bid on their own listed NFT"); // Prevent seller from bidding if listed.

        bidCounter++;
        nftBids[_collectionAddress][_tokenId][bidCounter] = Bid({
            bidder: _msgSender(),
            bidAmount: _bidAmount,
            isActive: true
        });

        emit BidPlaced(_collectionAddress, _tokenId, bidCounter, _bidAmount, _msgSender());
        // Refund excess ETH if bid amount is less than msg.value
        if (msg.value > _bidAmount) {
            payable(_msgSender()).transfer(msg.value - _bidAmount);
        }
    }

    function acceptBid(address _collectionAddress, uint256 _tokenId, uint256 _bidId)
        external validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId)
        tradingActive(_collectionAddress) biddingEnabledForCollection(_collectionAddress)
        isNFTOwner(_collectionAddress, _tokenId) nonReentrant
    {
        Bid storage bid = nftBids[_collectionAddress][_tokenId][_bidId];
        require(bid.bidder != address(0) && bid.isActive, "Invalid or inactive bid");

        DynamicNFTCollection collection = DynamicNFTCollection(_collectionAddress);
        uint256 royaltyAmount = bid.bidAmount.mul(collectionDetails[_collectionAddress].royaltyPercentage).div(10000);
        uint256 marketplaceFee = bid.bidAmount.mul(collectionDetails[_collectionAddress].marketplaceFeePercentage).div(10000).sub(royaltyAmount); // Fee after royalty.

        // Transfer funds
        payable(collectionDetails[_collectionAddress].royaltyRecipient).transfer(royaltyAmount); // Royalty recipient gets royalty amount.
        payable(ownerOf(_collectionAddress, _tokenId)).transfer(bid.bidAmount.sub(royaltyAmount).sub(marketplaceFee)); // Seller receives bid - royalty - marketplace fee.

        collection.safeTransferFrom(ownerOf(_collectionAddress, _tokenId), bid.bidder, _tokenId);

        bid.isActive = false; // Deactivate bid
        delete nftBids[_collectionAddress][_tokenId][_bidId]; // Clean up bid data

        // Refund other active bidders (if any - simplified for this example, more complex logic could be implemented)
        // In a real implementation, you'd likely track all active bids and refund them.

        emit BidAccepted(_collectionAddress, _tokenId, _bidId, bid.bidAmount, bid.bidder, ownerOf(_collectionAddress, _tokenId));
        // Keep marketplace fee in contract, ready to be withdrawn.
        payable(address(this)).transfer(marketplaceFee);

        // Clear any existing listing if bid is accepted.
        if (nftListings[_collectionAddress][_tokenId].isListed) {
            nftListings[_collectionAddress][_tokenId].isListed = false;
            delete nftListings[_collectionAddress][_tokenId];
        }
    }

    function rejectBid(address _collectionAddress, uint256 _tokenId, uint256 _bidId)
        external validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId)
        tradingActive(_collectionAddress) biddingEnabledForCollection(_collectionAddress)
        isNFTOwner(_collectionAddress, _tokenId)
    {
        Bid storage bid = nftBids[_collectionAddress][_tokenId][_bidId];
        require(bid.bidder != address(0) && bid.isActive, "Invalid or inactive bid");

        bid.isActive = false;
        payable(bid.bidder).transfer(bid.bidAmount); // Refund bid amount
        emit BidRejected(_collectionAddress, _tokenId, _bidId, bid.bidder);
        delete nftBids[_collectionAddress][_tokenId][_bidId]; // Clean up bid data
    }

    function withdrawBid(address _collectionAddress, uint256 _tokenId, uint256 _bidId)
        external validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId)
        tradingActive(_collectionAddress) biddingEnabledForCollection(_collectionAddress)
    {
        Bid storage bid = nftBids[_collectionAddress][_tokenId][_bidId];
        require(bid.bidder == _msgSender() && bid.isActive, "Not bidder or bid not active");

        bid.isActive = false;
        payable(bid.bidder).transfer(bid.bidAmount); // Refund bid amount
        emit BidWithdrawn(_collectionAddress, _tokenId, _bidId, _msgSender());
        delete nftBids[_collectionAddress][_tokenId][_bidId]; // Clean up bid data
    }


    // --- User Preference & Reporting Functions (Off-chain AI Integration) ---

    function setUserPreferences(string memory _preferencesJson) external {
        // In a real-world scenario, this would likely be stored off-chain, perhaps in a decentralized database or IPFS.
        // For this example, we just emit an event to signal preference update for off-chain AI processing.
        emit UserPreferencesSet(_msgSender(), _preferencesJson);
    }

    function reportNFT(address _collectionAddress, uint256 _tokenId, string memory _reportReason)
        external validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId)
    {
        // This action would trigger an off-chain AI moderation process.
        // The AI would analyze the report reason, NFT metadata, and potentially image/content.
        // Based on moderation policies, actions like NFT delisting or collection pausing could be taken (potentially through governance).
        emit NFTReported(_collectionAddress, _tokenId, _reportReason, _msgSender());
    }

    // --- Admin & Utility Functions ---

    function withdrawMarketplaceFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        payable(marketplaceFeeRecipient).transfer(balance);
        emit MarketplaceFeesWithdrawn(marketplaceFeeRecipient, balance);
    }

    function getNFTListingDetails(address _collectionAddress, uint256 _tokenId)
        external view validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId)
        returns (address seller, uint256 price, bool isListed)
    {
        NFTListing storage listing = nftListings[_collectionAddress][_tokenId];
        return (listing.seller, listing.price, listing.isListed);
    }

    function getCollectionDetails(address _collectionAddress)
        external view validCollection(_collectionAddress)
        returns (CollectionDetails memory details)
    {
        return collectionDetails[_collectionAddress];
    }

    function ownerOf(address _collectionAddress, uint256 _tokenId) public view validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId) returns(address) {
        DynamicNFTCollection collection = DynamicNFTCollection(_collectionAddress);
        return collection.ownerOf(_tokenId);
    }

    // --- Fallback Function (Optional - for receiving ETH directly) ---
    receive() external payable {}


}


// ----------------------------------------------------------------------------
//  Dynamic NFT Collection Contract (Separate Contract for Reusability)
// ----------------------------------------------------------------------------
contract DynamicNFTCollection is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    string public baseURI;
    uint256 public tokenIdCounter;

    struct NFTData {
        string metadataURI;
        uint256[] dynamicTraits;
    }

    mapping(uint256 => NFTData) public nftData;

    constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        tokenIdCounter = 1;
    }

    function mint(address _to, uint256 _tokenId, string memory _metadataURI, uint256[] memory _dynamicTraits) external onlyOwner {
        _mint(_to, _tokenId);
        nftData[_tokenId] = NFTData({
            metadataURI: _metadataURI,
            dynamicTraits: _dynamicTraits
        });
        tokenIdCounter++; // Increment token ID counter for next mint.
    }

    function updateDynamicTraits(uint256 _tokenId, uint256[] memory _newTraits) external {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == _msgSender() || msg.sender == owner(), "Not NFT owner or collection owner"); // Allow collection owner to update too.
        nftData[_tokenId].dynamicTraits = _newTraits;
        // Consider emitting an event here to signal trait update if needed.
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, nftData[_tokenId].metadataURI));
    }

    function getDynamicTraits(uint256 _tokenId) public view returns (uint256[] memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return nftData[_tokenId].dynamicTraits;
    }

    function nextTokenIdCounter() public view returns (uint256) {
        return tokenIdCounter;
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }
}
```

**Explanation of Advanced Concepts and Functions:**

1.  **Dynamic NFTs:**
    *   The `DynamicNFTCollection` contract is designed to manage NFTs with dynamic traits. Each NFT has `dynamicTraits` (an array of `uint256`) that can be updated after minting.
    *   `updateDynamicNFTTraits`: This function allows authorized addresses (NFT owner or designated trait updaters) to modify these traits. This is crucial for NFTs that evolve, change based on game events, data feeds, or user interactions.
    *   The metadata URI is still stored, but the dynamic traits provide a way to represent evolving properties of the NFT on-chain. The off-chain metadata can then be designed to interpret these traits.

2.  **AI-Powered Curation (Off-chain Integration):**
    *   `setUserPreferences(string memory _preferencesJson)`: This function allows users to submit their preferences in JSON format. This data would be captured by an off-chain service (listening to the `UserPreferencesSet` event). An AI model could then analyze these preferences to provide personalized NFT recommendations, filter content, etc.
    *   `reportNFT(address _collectionAddress, uint256 _tokenId, string memory _reportReason)`:  Users can report NFTs. This triggers the `NFTReported` event. An off-chain AI moderation system can monitor these reports and take actions based on platform policies (e.g., delisting NFTs, flagging collections).

3.  **Advanced Bidding System:**
    *   `placeBid`, `acceptBid`, `rejectBid`, `withdrawBid`: These functions implement a comprehensive bidding system.
    *   Bids are tracked per NFT with unique IDs.
    *   Sellers can accept bids, and bidders can withdraw bids before acceptance or rejection.
    *   Rejection and withdrawal refund bidders.
    *   Bid acceptance handles fund transfer and NFT ownership change.

4.  **Decentralized Governance (Potential Extension - Simple Admin Control Implemented):**
    *   While full decentralized governance is not implemented in this code for brevity, functions like `pauseCollectionTrading` and `unpauseCollectionTrading` are designed as potential governance levers. In a real-world scenario, these could be controlled by a DAO or a voting mechanism rather than just the contract owner.
    *   Setting marketplace fees, royalty percentages, and dynamic trait updaters are also admin-controlled in this version but could be governed in a more decentralized fashion.

5.  **Creator-Centric Features:**
    *   `createDynamicNFTCollection`:  Allows the contract owner to deploy new collections but with customizable royalty recipient and royalty percentage specified by the creator (through the contract owner).
    *   `setCollectionRoyalty`: Enables updating royalty settings for existing collections.
    *   The royalty mechanism ensures creators receive a percentage of secondary sales, fostering a more sustainable ecosystem.

6.  **Marketplace Fees and Recipient:**
    *   `setCollectionMarketplaceFee` and `setMarketplaceFeeRecipient`:  Control marketplace fees and where they are directed.
    *   `withdrawMarketplaceFees`:  Allows the fee recipient to withdraw accumulated fees.

7.  **Dynamic Trait Updaters:**
    *   `setDynamicTraitUpdater`:  Provides fine-grained control over who can update dynamic traits for a collection, allowing collection owners to delegate this responsibility.

8.  **Collection Management:**
    *   `pauseCollectionTrading`, `unpauseCollectionTrading`, `enableCollectionBidding`:  Functions to manage the operational state of NFT collections within the marketplace.

9.  **Information Retrieval:**
    *   `getNFTListingDetails`, `getCollectionDetails`, `ownerOf`:  View functions to easily retrieve information about listings, collections, and NFT ownership, important for UI and off-chain integrations.

**Important Considerations and Next Steps (For a Real-World Implementation):**

*   **Off-chain AI Integration:** The AI curation and moderation aspects are currently represented by events. A real implementation would require building off-chain services to:
    *   Listen for `UserPreferencesSet` and `NFTReported` events.
    *   Process user preferences and NFT reports using AI models.
    *   Potentially interact back with the smart contract (e.g., through governance proposals or admin actions) to enforce moderation decisions or update recommendations.
*   **Scalability and Gas Optimization:** For a production marketplace, gas optimization would be critical. Consider:
    *   Using more gas-efficient data structures.
    *   Batch operations where possible.
    *   Potentially using layer-2 solutions for reduced transaction costs.
*   **Security Audits:**  Smart contracts handling financial transactions (NFT sales, bids) must undergo thorough security audits by reputable firms before deployment to a live network.
*   **User Interface (UI) and UX:**  A user-friendly UI is essential for a successful marketplace. The UI would need to interact with the smart contract to list, buy, bid, and display dynamic NFT data and AI recommendations.
*   **Decentralized Storage (IPFS, Arweave):** For truly decentralized NFTs, consider storing NFT metadata (and potentially assets) on decentralized storage solutions like IPFS or Arweave, rather than centralized servers.
*   **Governance Mechanism:** To enhance decentralization, a governance mechanism (DAO, voting) could be implemented to control key marketplace parameters, collection approvals, and moderation policies.

This smart contract provides a foundation for a sophisticated and innovative NFT marketplace, incorporating many advanced and trendy concepts while aiming to be distinct from existing open-source solutions. Remember to thoroughly test, audit, and iterate upon this code before deploying it in a production environment.