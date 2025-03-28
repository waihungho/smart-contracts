```solidity
/**
 * @title Decentralized Dynamic NFT Marketplace with AI Integration
 * @author Gemini AI (Conceptual Smart Contract - Not for Production)
 * @dev This smart contract implements a dynamic NFT marketplace with advanced features,
 * including AI-driven NFT property updates, decentralized governance, advanced bidding
 * mechanisms, and unique utility functions. It aims to be creative and trendy, avoiding
 * direct duplication of existing open-source marketplaces while incorporating modern concepts.
 *
 * **Outline:**
 *
 * **1. NFT Management & Creation:**
 *    - `createDynamicNFT(string memory _name, string memory _symbol, string memory _baseURI)`: Creates a new collection of dynamic NFTs.
 *    - `mintDynamicNFT(uint256 _collectionId, address _to, string memory _tokenURI, bytes memory _initialDynamicData)`: Mints a new dynamic NFT within a collection.
 *    - `updateNFTMetadata(uint256 _collectionId, uint256 _tokenId, string memory _newTokenURI)`: Updates the metadata URI of an NFT.
 *    - `transferNFT(uint256 _collectionId, address _from, address _to, uint256 _tokenId)`: Transfers an NFT between addresses.
 *    - `burnNFT(uint256 _collectionId, uint256 _tokenId)`: Burns (destroys) an NFT.
 *    - `setCollectionBaseURI(uint256 _collectionId, string memory _newBaseURI)`: Sets the base URI for a collection.
 *
 * **2. Marketplace Core Functions:**
 *    - `listItem(uint256 _collectionId, uint256 _tokenId, uint256 _price)`: Lists an NFT for sale on the marketplace.
 *    - `unlistItem(uint256 _collectionId, uint256 _tokenId)`: Removes an NFT listing from the marketplace.
 *    - `buyItem(uint256 _collectionId, uint256 _tokenId)`: Allows buying a listed NFT at the listed price.
 *    - `offerBid(uint256 _collectionId, uint256 _tokenId)`: Allows users to place bids on NFTs.
 *    - `acceptBid(uint256 _collectionId, uint256 _tokenId, uint256 _bidId)`: Seller accepts a specific bid for an NFT.
 *    - `cancelBid(uint256 _collectionId, uint256 _tokenId, uint256 _bidId)`: Bidder cancels their bid.
 *    - `updateListingPrice(uint256 _collectionId, uint256 _tokenId, uint256 _newPrice)`: Updates the listing price of an NFT.
 *
 * **3. Dynamic NFT & AI Integration:**
 *    - `requestAIDynamicUpdate(uint256 _collectionId, uint256 _tokenId)`: Triggers a request to an external AI service to suggest dynamic property updates for an NFT.
 *    - `reportAIDynamicUpdate(uint256 _collectionId, uint256 _tokenId, bytes memory _dynamicData)`:  (Called by authorized AI Oracle) Reports back dynamic property updates for an NFT based on AI analysis.
 *    - `getDynamicNFTData(uint256 _collectionId, uint256 _tokenId)`: Retrieves the current dynamic data associated with an NFT.
 *
 * **4. Governance & Platform Features:**
 *    - `setPlatformFee(uint256 _newFeePercentage)`: Sets the platform fee percentage for marketplace transactions.
 *    - `withdrawPlatformFees()`: Allows the platform owner to withdraw accumulated platform fees.
 *    - `pauseMarketplace()`: Pauses all marketplace trading activity.
 *    - `unpauseMarketplace()`: Resumes marketplace trading activity.
 *    - `setAIOracleAddress(address _newOracleAddress)`: Sets the address of the authorized AI Oracle.
 *    - `getVersion()`: Returns the contract version.
 *
 * **Function Summary:**
 *
 * **NFT Management:**
 *   - `createDynamicNFT`: Deploy a new NFT collection with dynamic capabilities.
 *   - `mintDynamicNFT`: Issue a new dynamic NFT to a specific user within a collection.
 *   - `updateNFTMetadata`: Modify the metadata URI of an existing NFT.
 *   - `transferNFT`: Send an NFT to another user.
 *   - `burnNFT`: Destroy an NFT permanently.
 *   - `setCollectionBaseURI`: Change the base URI for a collection's metadata.
 *
 * **Marketplace Operations:**
 *   - `listItem`: Put an NFT up for sale in the marketplace.
 *   - `unlistItem`: Remove an NFT from sale.
 *   - `buyItem`: Purchase an NFT listed for sale at the set price.
 *   - `offerBid`: Place a bid on an NFT.
 *   - `acceptBid`: Seller agrees to a specific bid, completing the sale.
 *   - `cancelBid`: Bidder retracts their bid.
 *   - `updateListingPrice`: Change the listed price of an NFT.
 *
 * **Dynamic NFT & AI:**
 *   - `requestAIDynamicUpdate`: Initiate a request for AI analysis to update NFT properties.
 *   - `reportAIDynamicUpdate`: AI Oracle reports back updated dynamic NFT properties.
 *   - `getDynamicNFTData`: Fetch the current dynamic data associated with an NFT.
 *
 * **Governance & Platform:**
 *   - `setPlatformFee`: Adjust the marketplace platform fee.
 *   - `withdrawPlatformFees`: Owner can withdraw collected platform fees.
 *   - `pauseMarketplace`: Temporarily halt marketplace trading.
 *   - `unpauseMarketplace`: Reactivate marketplace trading.
 *   - `setAIOracleAddress`: Define the authorized AI Oracle contract address.
 *   - `getVersion`: Retrieve the contract's version identifier.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract DynamicAINFTMarketplace is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    // --- State Variables ---
    Counters.Counter private _collectionIdCounter;
    mapping(uint256 => Collection) public collections; // Collection ID => Collection Data
    mapping(uint256 => mapping(uint256 => Listing)) public listings; // collectionId => tokenId => Listing
    mapping(uint256 => mapping(uint256 => mapping(uint256 => Bid))) public bids; // collectionId => tokenId => bidId => Bid
    mapping(uint256 => mapping(uint256 => bytes)) public dynamicNFTData; // collectionId => tokenId => dynamic data
    mapping(uint256 => EnumerableSet.UintSet) public collectionTokenIds; // Collection ID => Set of token IDs in the collection

    uint256 public platformFeePercentage = 2; // Default platform fee (2%)
    address public platformFeeRecipient; // Address to receive platform fees
    address public aiOracleAddress; // Address of the authorized AI Oracle contract
    bool public isMarketplacePaused = false;
    string public constant VERSION = "1.0.0";

    // --- Structs ---
    struct Collection {
        string name;
        string symbol;
        string baseURI;
        address creator;
    }

    struct Listing {
        uint256 price;
        address seller;
        bool isActive;
    }

    struct Bid {
        uint256 bidPrice;
        address bidder;
        bool isActive;
    }

    // --- Events ---
    event CollectionCreated(uint256 collectionId, string name, string symbol, address creator);
    event DynamicNFTMinted(uint256 collectionId, uint256 tokenId, address to, string tokenURI);
    event NFTMetadataUpdated(uint256 collectionId, uint256 tokenId, string newTokenURI);
    event NFTListed(uint256 collectionId, uint256 tokenId, uint256 price, address seller);
    event NFTUnlisted(uint256 collectionId, uint256 tokenId);
    event ItemBought(uint256 collectionId, uint256 tokenId, address buyer, uint256 price);
    event BidOffered(uint256 collectionId, uint256 tokenId, uint256 bidId, uint256 bidPrice, address bidder);
    event BidAccepted(uint256 collectionId, uint256 tokenId, uint256 bidId, address seller, address bidder, uint256 price);
    event BidCancelled(uint256 collectionId, uint256 tokenId, uint256 bidId, address bidder);
    event ListingPriceUpdated(uint256 collectionId, uint256 tokenId, uint256 newPrice);
    event AIDynamicUpdateRequest(uint256 collectionId, uint256 tokenId);
    event AIDynamicUpdateReported(uint256 collectionId, uint256 tokenId, bytes dynamicData);
    event PlatformFeeSet(uint256 newFeePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address recipient);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event AIOracleAddressSet(address newOracleAddress);

    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "Only AI Oracle can call this function");
        _;
    }

    modifier marketplaceActive() {
        require(!isMarketplacePaused, "Marketplace is currently paused");
        _;
    }

    modifier validCollection(uint256 _collectionId) {
        require(collections[_collectionId].creator != address(0), "Invalid collection ID");
        _;
    }

    modifier validToken(uint256 _collectionId, uint256 _tokenId) {
        require(_exists(collections[_collectionId].symbol, _tokenId), "Invalid token ID or collection");
        _;
    }

    modifier isTokenOwner(uint256 _collectionId, uint256 _tokenId) {
        require(_ownerOf(collections[_collectionId].symbol, _tokenId) == msg.sender, "You are not the token owner");
        _;
    }

    modifier isListed(uint256 _collectionId, uint256 _tokenId) {
        require(listings[_collectionId][_tokenId].isActive, "NFT is not listed for sale");
        _;
    }

    modifier notListed(uint256 _collectionId, uint256 _tokenId) {
        require(!listings[_collectionId][_tokenId].isActive, "NFT is already listed for sale");
        _;
    }

    modifier validBid(uint256 _collectionId, uint256 _tokenId, uint256 _bidId) {
        require(bids[_collectionId][_tokenId][_bidId].bidder != address(0) && bids[_collectionId][_tokenId][_bidId].isActive, "Invalid or inactive bid ID");
        _;
    }


    // --- Constructor ---
    constructor(address _platformFeeRecipient, address _initialAIOracleAddress) ERC721("", "") { // Name and symbol are set per collection
        platformFeeRecipient = _platformFeeRecipient;
        aiOracleAddress = _initialAIOracleAddress;
    }

    // --- 1. NFT Management & Creation Functions ---

    function createDynamicNFT(string memory _name, string memory _symbol, string memory _baseURI) public onlyOwner returns (uint256 collectionId) {
        _collectionIdCounter.increment();
        collectionId = _collectionIdCounter.current();
        collections[collectionId] = Collection({
            name: _name,
            symbol: _symbol,
            baseURI: _baseURI,
            creator: msg.sender
        });
        emit CollectionCreated(collectionId, _name, _symbol, msg.sender);
    }

    function mintDynamicNFT(uint256 _collectionId, address _to, string memory _tokenURI, bytes memory _initialDynamicData) public validCollection(_collectionId) returns (uint256 tokenId) {
        Counters.Counter storage tokenCounter = _tokenIds(collections[_collectionId].symbol);
        tokenCounter.increment();
        tokenId = tokenCounter.current();
        _mint(collections[_collectionId].symbol, _to, tokenId);
        _setTokenURI(collections[_collectionId].symbol, tokenId, _tokenURI);
        dynamicNFTData[_collectionId][tokenId] = _initialDynamicData;
        collectionTokenIds[_collectionId].add(tokenId);
        emit DynamicNFTMinted(_collectionId, tokenId, _to, _tokenURI);
    }

    function updateNFTMetadata(uint256 _collectionId, uint256 _tokenId, string memory _newTokenURI) public validCollection(_collectionId) validToken(_collectionId, _tokenId) isTokenOwner(_collectionId, _tokenId) {
        _setTokenURI(collections[_collectionId].symbol, _tokenId, _newTokenURI);
        emit NFTMetadataUpdated(_collectionId, _tokenId, _newTokenURI);
    }

    function transferNFT(uint256 _collectionId, address _from, address _to, uint256 _tokenId) public validCollection(_collectionId) validToken(_collectionId, _tokenId) isTokenOwner(_collectionId, _tokenId) {
        safeTransferFrom(collections[_collectionId].symbol, _from, _to, _tokenId);
        // ERC721's safeTransferFrom already handles ownership checks, but we keep `isTokenOwner` for clarity in function purpose.
    }

    function burnNFT(uint256 _collectionId, uint256 _tokenId) public validCollection(_collectionId) validToken(_collectionId, _tokenId) isTokenOwner(_collectionId, _tokenId) {
        _burn(collections[_collectionId].symbol, _tokenId);
        collectionTokenIds[_collectionId].remove(_tokenId);
    }

    function setCollectionBaseURI(uint256 _collectionId, string memory _newBaseURI) public validCollection(_collectionId) onlyOwner {
        collections[_collectionId].baseURI = _newBaseURI;
    }


    // --- 2. Marketplace Core Functions ---

    function listItem(uint256 _collectionId, uint256 _tokenId, uint256 _price) public marketplaceActive validCollection(_collectionId) validToken(_collectionId, _tokenId) isTokenOwner(_collectionId, _tokenId) notListed(_collectionId, _tokenId) {
        require(_price > 0, "Price must be greater than zero");
        listings[_collectionId][_tokenId] = Listing({
            price: _price,
            seller: msg.sender,
            isActive: true
        });
        _approve(collections[_collectionId].symbol, address(this), _tokenId); // Approve marketplace to transfer NFT
        emit NFTListed(_collectionId, _tokenId, _price, msg.sender);
    }

    function unlistItem(uint256 _collectionId, uint256 _tokenId) public marketplaceActive validCollection(_collectionId) validToken(_collectionId, _tokenId) isTokenOwner(_collectionId, _tokenId) isListed(_collectionId, _tokenId) {
        listings[_collectionId][_tokenId].isActive = false;
        emit NFTUnlisted(_collectionId, _tokenId);
    }

    function buyItem(uint256 _collectionId, uint256 _tokenId) public payable marketplaceActive validCollection(_collectionId) validToken(_collectionId, _tokenId) isListed(_collectionId, _tokenId) {
        Listing storage itemListing = listings[_collectionId][_tokenId];
        require(msg.value >= itemListing.price, "Insufficient funds to buy item");
        uint256 platformFee = (itemListing.price * platformFeePercentage) / 100;
        uint256 sellerPayout = itemListing.price - platformFee;

        // Transfer NFT
        safeTransferFrom(collections[_collectionId].symbol, itemListing.seller, msg.sender, _tokenId);

        // Payment distribution
        payable(itemListing.seller).transfer(sellerPayout);
        payable(platformFeeRecipient).transfer(platformFee);

        itemListing.isActive = false; // Deactivate listing

        emit ItemBought(_collectionId, _tokenId, msg.sender, itemListing.price);
    }


    function offerBid(uint256 _collectionId, uint256 _tokenId) public payable marketplaceActive validCollection(_collectionId) validToken(_collectionId, _tokenId) notListed(_collectionId, _tokenId) {
        require(msg.value > 0, "Bid price must be greater than zero");

        Counters.Counter storage bidCounter = _bidCounters(_collectionId, _tokenId);
        bidCounter.increment();
        uint256 bidId = bidCounter.current();

        bids[_collectionId][_tokenId][bidId] = Bid({
            bidPrice: msg.value,
            bidder: msg.sender,
            isActive: true
        });

        emit BidOffered(_collectionId, _tokenId, bidId, msg.value, msg.sender);
    }

    function acceptBid(uint256 _collectionId, uint256 _tokenId, uint256 _bidId) public marketplaceActive validCollection(_collectionId) validToken(_collectionId, _tokenId) isTokenOwner(_collectionId, _tokenId) validBid(_collectionId, _tokenId, _bidId) {
        Bid storage currentBid = bids[_collectionId][_tokenId][_bidId];
        require(_ownerOf(collections[_collectionId].symbol, _tokenId) == msg.sender, "You are not the owner of the NFT"); // Re-check owner for security
        require(currentBid.isActive, "Bid is not active");

        uint256 platformFee = (currentBid.bidPrice * platformFeePercentage) / 100;
        uint256 sellerPayout = currentBid.bidPrice - platformFee;

        // Transfer NFT
        safeTransferFrom(collections[_collectionId].symbol, msg.sender, currentBid.bidder, _tokenId);

        // Payment distribution
        payable(msg.sender).transfer(sellerPayout);
        payable(platformFeeRecipient).transfer(platformFee);

        currentBid.isActive = false; // Deactivate accepted bid

        // Cancel other active bids for this token (optional - for exclusivity)
        for (uint256 i = 1; i <= _bidCounters(_collectionId, _tokenId).current(); i++) {
            if (bids[_collectionId][_tokenId][i].isActive && i != _bidId) {
                cancelBid(_collectionId, _tokenId, i); // Automatically refund other bidders.
            }
        }

        emit BidAccepted(_collectionId, _tokenId, _bidId, msg.sender, currentBid.bidder, currentBid.bidPrice);
    }

    function cancelBid(uint256 _collectionId, uint256 _tokenId, uint256 _bidId) public marketplaceActive validCollection(_collectionId) validToken(_collectionId, _tokenId) validBid(_collectionId, _tokenId, _bidId) {
        Bid storage currentBid = bids[_collectionId][_tokenId][_bidId];
        require(currentBid.bidder == msg.sender, "Only bidder can cancel their bid");

        payable(msg.sender).transfer(currentBid.bidPrice); // Refund bidder
        currentBid.isActive = false; // Deactivate bid

        emit BidCancelled(_collectionId, _tokenId, _bidId, msg.sender);
    }

    function updateListingPrice(uint256 _collectionId, uint256 _tokenId, uint256 _newPrice) public marketplaceActive validCollection(_collectionId) validToken(_collectionId, _tokenId) isTokenOwner(_collectionId, _tokenId) isListed(_collectionId, _tokenId) {
        require(_newPrice > 0, "New price must be greater than zero");
        listings[_collectionId][_tokenId].price = _newPrice;
        emit ListingPriceUpdated(_collectionId, _tokenId, _newPrice);
    }


    // --- 3. Dynamic NFT & AI Integration Functions ---

    function requestAIDynamicUpdate(uint256 _collectionId, uint256 _tokenId) public marketplaceActive validCollection(_collectionId) validToken(_collectionId, _tokenId) {
        require(aiOracleAddress != address(0), "AI Oracle address not set");
        // In a real scenario, you would likely emit an event that an off-chain AI Oracle service listens to.
        // The event would contain collectionId, tokenId, and potentially other context data.
        emit AIDynamicUpdateRequest(_collectionId, _tokenId);
    }

    function reportAIDynamicUpdate(uint256 _collectionId, uint256 _tokenId, bytes memory _dynamicData) public onlyAIOracle validCollection(_collectionId) validToken(_collectionId, _tokenId) {
        dynamicNFTData[_collectionId][_tokenId] = _dynamicData;
        emit AIDynamicUpdateReported(_collectionId, _tokenId, _dynamicData);
    }

    function getDynamicNFTData(uint256 _collectionId, uint256 _tokenId) public view validCollection(_collectionId) validToken(_collectionId, _tokenId) returns (bytes memory) {
        return dynamicNFTData[_collectionId][_tokenId];
    }


    // --- 4. Governance & Platform Features ---

    function setPlatformFee(uint256 _newFeePercentage) public onlyOwner {
        require(_newFeePercentage <= 100, "Platform fee percentage cannot exceed 100%");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeSet(_newFeePercentage);
    }

    function withdrawPlatformFees() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(platformFeeRecipient).transfer(balance);
        emit PlatformFeesWithdrawn(balance, platformFeeRecipient);
    }

    function pauseMarketplace() public onlyOwner {
        isMarketplacePaused = true;
        emit MarketplacePaused();
    }

    function unpauseMarketplace() public onlyOwner {
        isMarketplacePaused = false;
        emit MarketplaceUnpaused();
    }

    function setAIOracleAddress(address _newOracleAddress) public onlyOwner {
        aiOracleAddress = _newOracleAddress;
        emit AIOracleAddressSet(_newOracleAddress);
    }

    function getVersion() public pure returns (string memory) {
        return VERSION;
    }


    // --- Internal Helper Counters ---
    function _bidCounters(uint256 _collectionId, uint256 _tokenId) internal pure returns (Counters.Counter storage counter) {
        string memory key = string(abi.encodePacked("bidCounter", Strings.toString(_collectionId), Strings.toString(_tokenId)));
        bytes32 slot = keccak256(abi.encodePacked(key, "_bidCounters_slot")); // Unique storage slot to avoid collisions.
        assembly {
            counter.slot := slot
        }
    }

    function _tokenIds(string memory _collectionSymbol) internal pure returns (Counters.Counter storage counter) {
        string memory key = string(abi.encodePacked("tokenIdCounter", _collectionSymbol));
        bytes32 slot = keccak256(abi.encodePacked(key, "_tokenIds_slot")); // Unique storage slot to avoid collisions.
        assembly {
            counter.slot := slot
        }
    }

    // --- Override ERC721 functions to use dynamic collection symbol ---
    function _exists(string memory _collectionSymbol, uint256 tokenId) internal view override returns (bool) {
        return _ownerOf(_collectionSymbol, tokenId) != address(0);
    }

    function _ownerOf(string memory _collectionSymbol, uint256 tokenId) internal view override returns (address) {
        return ERC721Enumerable.ownerOf(keccak256(abi.encodePacked(_collectionSymbol)), tokenId); // Using hash of symbol as collection ID for ERC721 internal tracking (not ideal in real-world complex scenarios, but simplified here)
    }

    function _tokenURI(string memory _collectionSymbol, uint256 tokenId) internal view override returns (string memory) {
        return ERC721Enumerable.tokenURI(keccak256(abi.encodePacked(_collectionSymbol)), tokenId); // Using hash of symbol as collection ID for ERC721 internal tracking
    }

    function _mint(string memory _collectionSymbol, address to, uint256 tokenId) internal override {
        ERC721Enumerable._mint(keccak256(abi.encodePacked(_collectionSymbol)), to, tokenId); // Using hash of symbol as collection ID for ERC721 internal tracking
    }

    function _burn(string memory _collectionSymbol, uint256 tokenId) internal override {
        ERC721Enumerable._burn(keccak256(abi.encodePacked(_collectionSymbol)), tokenId); // Using hash of symbol as collection ID for ERC721 internal tracking
    }

    function _setTokenURI(string memory _collectionSymbol, uint256 tokenId, string memory uri) internal override {
        ERC721Enumerable._setTokenURI(keccak256(abi.encodePacked(_collectionSymbol)), tokenId, uri); // Using hash of symbol as collection ID for ERC721 internal tracking
    }

    function safeTransferFrom(string memory _collectionSymbol, address from, address to, uint256 tokenId) public override {
        ERC721Enumerable.safeTransferFrom(keccak256(abi.encodePacked(_collectionSymbol)), from, to, tokenId); // Using hash of symbol as collection ID
    }

    function transferFrom(string memory _collectionSymbol, address from, address to, uint256 tokenId) public override {
        ERC721Enumerable.transferFrom(keccak256(abi.encodePacked(_collectionSymbol)), from, to, tokenId); // Using hash of symbol as collection ID
    }

    function approve(string memory _collectionSymbol, address approved, uint256 tokenId) public override {
        ERC721Enumerable.approve(keccak256(abi.encodePacked(_collectionSymbol)), approved, tokenId); // Using hash of symbol as collection ID
    }

    function getApproved(string memory _collectionSymbol, uint256 tokenId) public view override returns (address) {
        return ERC721Enumerable.getApproved(keccak256(abi.encodePacked(_collectionSymbol)), tokenId); // Using hash of symbol as collection ID
    }

    function setApprovalForAll(string memory _collectionSymbol, address operator, bool approved) public override {
        ERC721Enumerable.setApprovalForAll(keccak256(abi.encodePacked(_collectionSymbol)), operator, approved); // Using hash of symbol as collection ID
    }

    function isApprovedForAll(string memory _collectionSymbol, address owner, address operator) public view override returns (bool) {
        return ERC721Enumerable.isApprovedForAll(keccak256(abi.encodePacked(_collectionSymbol)), owner, operator); // Using hash of symbol as collection ID
    }

    function _approve(string memory _collectionSymbol, address to, uint256 tokenId) internal override {
        ERC721Enumerable._approve(keccak256(abi.encodePacked(_collectionSymbol)), to, tokenId); // Using hash of symbol as collection ID
    }

    function ownerOf(uint256 _collectionId, uint256 _tokenId) public view validCollection(_collectionId) validToken(_collectionId, _tokenId) returns (address) {
        return _ownerOf(collections[_collectionId].symbol, _tokenId);
    }

    function tokenURI(uint256 _collectionId, uint256 _tokenId) public view validCollection(_collectionId) validToken(_collectionId, _tokenId) returns (string memory) {
        return _tokenURI(collections[_collectionId].symbol, _tokenId);
    }
}
```