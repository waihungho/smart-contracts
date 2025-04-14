```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Art Marketplace - "ArtVerse"
 * @author Bard (AI Assistant)
 * @dev A smart contract for a dynamic art marketplace where NFTs can evolve, interact, and have layered functionalities.
 *
 * Outline and Function Summary:
 *
 * 1.  **Art NFT Creation & Management:**
 *     - `mintArtNFT(string memory _metadataURI, string memory _initialData)`: Mints a new Dynamic Art NFT.
 *     - `updateArtData(uint256 _tokenId, string memory _newData)`: Updates the dynamic data associated with an Art NFT (artist only).
 *     - `setArtEvolvable(uint256 _tokenId, bool _isEvolvable)`: Sets whether an NFT is evolvable (artist/admin).
 *     - `evolveArtNFT(uint256 _tokenId, string memory _evolutionData)`:  Allows NFT to evolve based on specific criteria (if evolvable).
 *     - `burnArtNFT(uint256 _tokenId)`: Burns an Art NFT (artist/admin).
 *     - `transferArtNFT(address _to, uint256 _tokenId)`: Safe transfer function with ownership checks.
 *
 * 2.  **Marketplace Listing & Trading:**
 *     - `listItemForSale(uint256 _tokenId, uint256 _price)`: Lists an Art NFT for sale on the marketplace.
 *     - `buyArtNFT(uint256 _tokenId)`: Allows anyone to buy a listed Art NFT.
 *     - `delistItem(uint256 _tokenId)`: Delists an Art NFT from the marketplace (seller only).
 *     - `updateListingPrice(uint256 _tokenId, uint256 _newPrice)`: Updates the price of a listed Art NFT (seller only).
 *     - `createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _duration)`: Creates an auction for an Art NFT.
 *     - `bidOnAuction(uint256 _auctionId)`: Allows users to bid on an active auction.
 *     - `settleAuction(uint256 _auctionId)`: Settles an auction and transfers the NFT to the highest bidder.
 *     - `cancelAuction(uint256 _auctionId)`: Cancels an auction (seller only, before any bids).
 *
 * 3.  **Dynamic Layers & Interaction:**
 *     - `addArtLayer(uint256 _tokenId, string memory _layerName, string memory _layerData)`: Adds a dynamic layer to an Art NFT (artist/admin).
 *     - `updateArtLayerData(uint256 _tokenId, string memory _layerName, string memory _newLayerData)`: Updates data for a specific layer (artist/admin).
 *     - `removeArtLayer(uint256 _tokenId, string memory _layerName)`: Removes a layer from an Art NFT (artist/admin).
 *     - `interactWithArt(uint256 _tokenId, string memory _interactionType, string memory _interactionData)`: Allows users to interact with Art NFTs (e.g., likes, comments, votes - customizable interaction types).
 *
 * 4.  **Community & Governance (Basic):**
 *     - `setMarketplaceFee(uint256 _feePercentage)`: Sets the marketplace fee percentage (admin only).
 *     - `withdrawMarketplaceFees()`: Allows the contract owner to withdraw accumulated marketplace fees (admin only).
 *     - `pauseMarketplace()`: Pauses all marketplace trading functions (admin only).
 *     - `unpauseMarketplace()`: Resumes marketplace trading functions (admin only).
 *
 * 5. **Utility & View Functions:**
 *     - `getArtDetails(uint256 _tokenId)`: Returns detailed information about an Art NFT.
 *     - `getListingDetails(uint256 _tokenId)`: Returns listing details for a listed NFT.
 *     - `getAuctionDetails(uint256 _auctionId)`: Returns details of an auction.
 *     - `isArtNFTListed(uint256 _tokenId)`: Checks if an Art NFT is currently listed for sale.
 *     - `isArtNFTOnAuction(uint256 _tokenId)`: Checks if an Art NFT is currently on auction.
 */

contract ArtVerseMarketplace {
    // --- State Variables ---

    string public name = "ArtVerse";
    string public symbol = "AVRT";
    address public admin;
    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    bool public marketplacePaused = false;

    uint256 public nextTokenId = 1;
    uint256 public nextAuctionId = 1;

    mapping(uint256 => address) public artTokenOwner;
    mapping(uint256 => string) public artMetadataURIs;
    mapping(uint256 => string) public artDynamicData;
    mapping(uint256 => bool) public isArtEvolvable;

    struct ArtLayer {
        string layerName;
        string layerData;
    }
    mapping(uint256 => mapping(string => ArtLayer)) public artLayers; // tokenId => layerName => ArtLayer

    struct Listing {
        uint256 tokenId;
        uint256 price;
        address seller;
        bool isActive;
    }
    mapping(uint256 => Listing) public listings; // tokenId => Listing

    struct Auction {
        uint256 auctionId;
        uint256 tokenId;
        uint256 startingPrice;
        uint256 endTime;
        address seller;
        address highestBidder;
        uint256 highestBid;
        bool isActive;
    }
    mapping(uint256 => Auction) public auctions; // auctionId => Auction

    mapping(uint256 => mapping(address => uint256)) public tokenBalances; // tokenId => owner => balance (ERC1155 style, but for unique NFTs)

    // --- Events ---
    event ArtNFTMinted(uint256 tokenId, address artist, string metadataURI);
    event ArtDataUpdated(uint256 tokenId, string newData);
    event ArtEvolvableSet(uint256 tokenId, bool isEvolvable);
    event ArtEvolved(uint256 tokenId, string evolutionData);
    event ArtNFTBurned(uint256 tokenId);
    event ArtNFTTransferred(uint256 tokenId, address from, address to);

    event ItemListed(uint256 tokenId, uint256 price, address seller);
    event ItemBought(uint256 tokenId, uint256 price, address buyer, address seller);
    event ItemDelisted(uint256 tokenId, address seller);
    event ListingPriceUpdated(uint256 tokenId, uint256 newPrice, address seller);

    event AuctionCreated(uint256 auctionId, uint256 tokenId, uint256 startingPrice, uint256 endTime, address seller);
    event BidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionSettled(uint256 auctionId, uint256 tokenId, address winner, uint256 finalPrice);
    event AuctionCancelled(uint256 auctionId, address seller);

    event ArtLayerAdded(uint256 tokenId, string layerName, string layerData);
    event ArtLayerUpdated(uint256 tokenId, string layerName, string newLayerData);
    event ArtLayerRemoved(uint256 tokenId, string layerName);
    event ArtInteraction(uint256 tokenId, address user, string interactionType, string interactionData);

    event MarketplaceFeeSet(uint256 feePercentage, address admin);
    event MarketplaceFeesWithdrawn(uint256 amount, address admin);
    event MarketplacePaused(address admin);
    event MarketplaceUnpaused(address admin);


    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier onlyArtOwner(uint256 _tokenId) {
        require(artTokenOwner[_tokenId] == msg.sender, "You are not the owner of this Art NFT.");
        _;
    }

    modifier marketplaceActive() {
        require(!marketplacePaused, "Marketplace is currently paused.");
        _;
    }

    modifier validTokenId(uint256 _tokenId) {
        require(artTokenOwner[_tokenId] != address(0), "Invalid Token ID.");
        _;
    }

    modifier listingExists(uint256 _tokenId) {
        require(listings[_tokenId].isActive, "Art NFT is not listed for sale.");
        _;
    }

    modifier auctionExists(uint256 _auctionId) {
        require(auctions[_auctionId].isActive, "Auction does not exist or is not active.");
        _;
    }

    modifier auctionNotStarted(uint256 _auctionId) {
        require(auctions[_auctionId].highestBid == 0, "Auction has bids already, cannot cancel now.");
        _;
    }

    // --- Constructor ---
    constructor() {
        admin = msg.sender;
    }

    // --- 1. Art NFT Creation & Management ---

    /// @notice Mints a new Dynamic Art NFT.
    /// @param _metadataURI URI pointing to the art's metadata (off-chain).
    /// @param _initialData Initial dynamic data associated with the Art NFT.
    function mintArtNFT(string memory _metadataURI, string memory _initialData) public {
        uint256 tokenId = nextTokenId++;
        artTokenOwner[tokenId] = msg.sender;
        artMetadataURIs[tokenId] = _metadataURI;
        artDynamicData[tokenId] = _initialData;
        isArtEvolvable[tokenId] = false; // Default not evolvable
        tokenBalances[tokenId][msg.sender] = 1; // ERC1155 style balance tracking for unique NFTs

        emit ArtNFTMinted(tokenId, msg.sender, _metadataURI);
    }

    /// @notice Updates the dynamic data associated with an Art NFT. Only the artist (owner) can call this.
    /// @param _tokenId ID of the Art NFT to update.
    /// @param _newData New dynamic data for the Art NFT.
    function updateArtData(uint256 _tokenId, string memory _newData) public validTokenId(_tokenId) onlyArtOwner(_tokenId) {
        artDynamicData[_tokenId] = _newData;
        emit ArtDataUpdated(_tokenId, _newData);
    }

    /// @notice Sets whether an Art NFT is evolvable. Can be set by artist or admin.
    /// @param _tokenId ID of the Art NFT.
    /// @param _isEvolvable Boolean value to set evolvability (true or false).
    function setArtEvolvable(uint256 _tokenId, bool _isEvolvable) public validTokenId(_tokenId) {
        require(msg.sender == admin || msg.sender == artTokenOwner[_tokenId], "Only admin or art owner can set evolvability.");
        isArtEvolvable[_tokenId] = _isEvolvable;
        emit ArtEvolvableSet(_tokenId, _isEvolvable);
    }

    /// @notice Allows an Art NFT to evolve, changing its dynamic data if it's marked as evolvable.
    /// @param _tokenId ID of the Art NFT to evolve.
    /// @param _evolutionData Data describing the evolution.
    function evolveArtNFT(uint256 _tokenId, string memory _evolutionData) public validTokenId(_tokenId) {
        require(isArtEvolvable[_tokenId], "Art NFT is not set as evolvable.");
        // In a real-world scenario, evolution logic could be more complex, potentially using oracles or on-chain randomness.
        // For this example, we simply append the evolution data to the existing dynamic data.
        artDynamicData[_tokenId] = string(abi.encodePacked(artDynamicData[_tokenId], " | Evolved: ", _evolutionData));
        emit ArtEvolved(_tokenId, _evolutionData);
    }

    /// @notice Burns an Art NFT, effectively destroying it. Can be called by the artist or admin.
    /// @param _tokenId ID of the Art NFT to burn.
    function burnArtNFT(uint256 _tokenId) public validTokenId(_tokenId) {
        require(msg.sender == admin || msg.sender == artTokenOwner[_tokenId], "Only admin or art owner can burn NFT.");

        address owner = artTokenOwner[_tokenId];
        delete artTokenOwner[_tokenId];
        delete artMetadataURIs[_tokenId];
        delete artDynamicData[_tokenId];
        delete isArtEvolvable[_tokenId];
        delete artLayers[_tokenId];
        delete listings[_tokenId]; // Delist if listed
        delete auctions[_tokenId]; // Cancel if on auction
        delete tokenBalances[_tokenId];

        emit ArtNFTBurned(_tokenId);
        emit ArtNFTTransferred(_tokenId, owner, address(0)); // Emitting a transfer event to address(0) for burn.
    }


    /// @notice Safe transfer function for Art NFTs.
    /// @param _to Address to transfer the NFT to.
    /// @param _tokenId ID of the Art NFT to transfer.
    function transferArtNFT(address _to, uint256 _tokenId) public validTokenId(_tokenId) onlyArtOwner(_tokenId) {
        require(_to != address(0), "Transfer to the zero address is not allowed.");
        require(_to != address(this), "Transfer to the contract address is not allowed.");
        require(!isArtNFTListed(_tokenId) && !isArtNFTOnAuction(_tokenId), "Cannot transfer NFT that is listed or on auction. Delist/Cancel first.");

        address from = msg.sender;
        artTokenOwner[_tokenId] = _to;
        tokenBalances[_tokenId][from] = 0;
        tokenBalances[_tokenId][_to] = 1;

        emit ArtNFTTransferred(_tokenId, from, _to);
    }


    // --- 2. Marketplace Listing & Trading ---

    /// @notice Lists an Art NFT for sale on the marketplace.
    /// @param _tokenId ID of the Art NFT to list.
    /// @param _price Price in wei for which the NFT is listed.
    function listItemForSale(uint256 _tokenId, uint256 _price) public marketplaceActive validTokenId(_tokenId) onlyArtOwner(_tokenId) {
        require(_price > 0, "Price must be greater than zero.");
        require(!isArtNFTListed(_tokenId) && !isArtNFTOnAuction(_tokenId), "Art NFT is already listed or on auction.");

        listings[_tokenId] = Listing({
            tokenId: _tokenId,
            price: _price,
            seller: msg.sender,
            isActive: true
        });
        emit ItemListed(_tokenId, _price, msg.sender);
    }

    /// @notice Allows anyone to buy a listed Art NFT.
    /// @param _tokenId ID of the Art NFT to buy.
    function buyArtNFT(uint256 _tokenId) public payable marketplaceActive validTokenId(_tokenId) listingExists(_tokenId) {
        Listing storage listing = listings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds sent.");

        uint256 marketplaceFee = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = listing.price - marketplaceFee;

        // Transfer NFT to buyer
        address seller = listing.seller;
        artTokenOwner[_tokenId] = msg.sender;
        tokenBalances[_tokenId][seller] = 0;
        tokenBalances[_tokenId][msg.sender] = 1;


        // Pay seller and marketplace fee
        payable(seller).transfer(sellerProceeds);
        payable(admin).transfer(marketplaceFee);

        // Delist the item
        listing.isActive = false;

        emit ItemBought(_tokenId, listing.price, msg.sender, seller);
        emit ItemDelisted(_tokenId, seller); // Optional, but good to emit a delisting event as well.
    }

    /// @notice Delists an Art NFT from the marketplace. Only the seller can call this.
    /// @param _tokenId ID of the Art NFT to delist.
    function delistItem(uint256 _tokenId) public marketplaceActive validTokenId(_tokenId) listingExists(_tokenId) onlyArtOwner(_tokenId) {
        require(listings[_tokenId].seller == msg.sender, "Only the seller can delist this item.");
        listings[_tokenId].isActive = false;
        emit ItemDelisted(_tokenId, msg.sender);
    }

    /// @notice Updates the price of a listed Art NFT. Only the seller can call this.
    /// @param _tokenId ID of the Art NFT to update the price for.
    /// @param _newPrice New price in wei.
    function updateListingPrice(uint256 _tokenId, uint256 _newPrice) public marketplaceActive validTokenId(_tokenId) listingExists(_tokenId) onlyArtOwner(_tokenId) {
        require(listings[_tokenId].seller == msg.sender, "Only the seller can update the price.");
        require(_newPrice > 0, "Price must be greater than zero.");
        listings[_tokenId].price = _newPrice;
        emit ListingPriceUpdated(_tokenId, _newPrice, msg.sender);
    }

    /// @notice Creates an auction for an Art NFT.
    /// @param _tokenId ID of the Art NFT to auction.
    /// @param _startingPrice Starting bid price in wei.
    /// @param _duration Auction duration in seconds.
    function createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _duration) public marketplaceActive validTokenId(_tokenId) onlyArtOwner(_tokenId) {
        require(_startingPrice > 0, "Starting price must be greater than zero.");
        require(_duration > 0, "Auction duration must be greater than zero.");
        require(!isArtNFTListed(_tokenId) && !isArtNFTOnAuction(_tokenId), "Art NFT is already listed or on auction.");

        auctions[nextAuctionId] = Auction({
            auctionId: nextAuctionId,
            tokenId: _tokenId,
            startingPrice: _startingPrice,
            endTime: block.timestamp + _duration,
            seller: msg.sender,
            highestBidder: address(0),
            highestBid: 0,
            isActive: true
        });

        emit AuctionCreated(nextAuctionId, _tokenId, _startingPrice, block.timestamp + _duration, msg.sender);
        nextAuctionId++;
    }

    /// @notice Allows users to bid on an active auction.
    /// @param _auctionId ID of the auction to bid on.
    function bidOnAuction(uint256 _auctionId) public payable marketplaceActive auctionExists(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp < auction.endTime, "Auction has already ended.");
        require(msg.value > auction.highestBid, "Bid amount must be higher than the current highest bid.");

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid); // Refund previous bidder
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        emit BidPlaced(_auctionId, msg.sender, msg.value);
    }

    /// @notice Settles an auction and transfers the NFT to the highest bidder.
    /// @param _auctionId ID of the auction to settle.
    function settleAuction(uint256 _auctionId) public marketplaceActive auctionExists(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp >= auction.endTime, "Auction is not yet ended.");
        require(auction.isActive, "Auction is not active.");

        auction.isActive = false; // Mark auction as inactive immediately to prevent re-entrancy issues if any.

        if (auction.highestBidder != address(0)) {
            uint256 marketplaceFee = (auction.highestBid * marketplaceFeePercentage) / 100;
            uint256 sellerProceeds = auction.highestBid - marketplaceFee;

            // Transfer NFT to highest bidder
            address seller = auction.seller;
            artTokenOwner[auction.tokenId] = auction.highestBidder;
            tokenBalances[auction.tokenId][seller] = 0;
            tokenBalances[auction.tokenId][auction.highestBidder] = 1;


            // Pay seller and marketplace fee
            payable(seller).transfer(sellerProceeds);
            payable(admin).transfer(marketplaceFee);

            emit AuctionSettled(_auctionId, auction.tokenId, auction.highestBidder, auction.highestBid);
            emit ArtNFTTransferred(auction.tokenId, seller, auction.highestBidder); // Emit transfer event
        } else {
            // No bids, return NFT to seller (or keep it with seller, depending on logic). In this case, we keep it with the seller.
            emit AuctionSettled(_auctionId, auction.tokenId, address(0), 0); // Settle event with no winner.
        }
    }

    /// @notice Cancels an auction. Only the seller can call this before any bids are placed.
    /// @param _auctionId ID of the auction to cancel.
    function cancelAuction(uint256 _auctionId) public marketplaceActive auctionExists(_auctionId) auctionNotStarted(_auctionId) onlyArtOwner(auctions[_auctionId].tokenId) {
        require(auctions[_auctionId].seller == msg.sender, "Only the seller can cancel the auction.");
        auctions[_auctionId].isActive = false;
        emit AuctionCancelled(_auctionId, msg.sender);
    }

    // --- 3. Dynamic Layers & Interaction ---

    /// @notice Adds a dynamic layer to an Art NFT. Can be used for visual layers, metadata layers, etc.
    /// @param _tokenId ID of the Art NFT to add a layer to.
    /// @param _layerName Unique name for the layer.
    /// @param _layerData Initial data for the layer.
    function addArtLayer(uint256 _tokenId, string memory _layerName, string memory _layerData) public validTokenId(_tokenId) {
        require(msg.sender == admin || msg.sender == artTokenOwner[_tokenId], "Only admin or art owner can add layers.");
        require(bytes(artLayers[_tokenId][_layerName].layerName).length == 0, "Layer name already exists. Use updateArtLayerData to modify.");

        artLayers[_tokenId][_layerName] = ArtLayer({
            layerName: _layerName,
            layerData: _layerData
        });
        emit ArtLayerAdded(_tokenId, _layerName, _layerData);
    }

    /// @notice Updates the data for a specific layer of an Art NFT.
    /// @param _tokenId ID of the Art NFT.
    /// @param _layerName Name of the layer to update.
    /// @param _newLayerData New data for the layer.
    function updateArtLayerData(uint256 _tokenId, string memory _layerName, string memory _newLayerData) public validTokenId(_tokenId) {
        require(msg.sender == admin || msg.sender == artTokenOwner[_tokenId], "Only admin or art owner can update layers.");
        require(bytes(artLayers[_tokenId][_layerName].layerName).length > 0, "Layer name does not exist. Use addArtLayer to create.");

        artLayers[_tokenId][_layerName].layerData = _newLayerData;
        emit ArtLayerUpdated(_tokenId, _layerName, _newLayerData);
    }

    /// @notice Removes a layer from an Art NFT.
    /// @param _tokenId ID of the Art NFT.
    /// @param _layerName Name of the layer to remove.
    function removeArtLayer(uint256 _tokenId, string memory _layerName) public validTokenId(_tokenId) {
        require(msg.sender == admin || msg.sender == artTokenOwner[_tokenId], "Only admin or art owner can remove layers.");
        require(bytes(artLayers[_tokenId][_layerName].layerName).length > 0, "Layer name does not exist.");

        delete artLayers[_tokenId][_layerName];
        emit ArtLayerRemoved(_tokenId, _layerName);
    }

    /// @notice Allows users to interact with Art NFTs. Interaction types can be likes, comments, votes, etc.
    /// @param _tokenId ID of the Art NFT to interact with.
    /// @param _interactionType Type of interaction (e.g., "like", "comment", "vote").
    /// @param _interactionData Data associated with the interaction (e.g., comment text).
    function interactWithArt(uint256 _tokenId, string memory _interactionType, string memory _interactionData) public validTokenId(_tokenId) {
        // In a real-world scenario, you might want to store interactions in a more structured way, possibly off-chain or using events for indexing.
        // For this example, we simply emit an event.
        emit ArtInteraction(_tokenId, msg.sender, _interactionType, _interactionData);
    }

    // --- 4. Community & Governance (Basic) ---

    /// @notice Sets the marketplace fee percentage. Only admin can call this.
    /// @param _feePercentage New marketplace fee percentage (e.g., 2 for 2%).
    function setMarketplaceFee(uint256 _feePercentage) public onlyAdmin {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage, msg.sender);
    }

    /// @notice Allows the contract owner (admin) to withdraw accumulated marketplace fees.
    function withdrawMarketplaceFees() public onlyAdmin {
        uint256 balance = address(this).balance;
        uint256 adminBalance = balance; // All contract balance is considered marketplace fees in this simple example.

        payable(admin).transfer(adminBalance);
        emit MarketplaceFeesWithdrawn(adminBalance, msg.sender);
    }

    /// @notice Pauses all marketplace trading functions (listing, buying, auctioning). Only admin can call this.
    function pauseMarketplace() public onlyAdmin {
        marketplacePaused = true;
        emit MarketplacePaused(msg.sender);
    }

    /// @notice Resumes marketplace trading functions. Only admin can call this.
    function unpauseMarketplace() public onlyAdmin {
        marketplacePaused = false;
        emit MarketplaceUnpaused(msg.sender);
    }

    // --- 5. Utility & View Functions ---

    /// @notice Returns detailed information about an Art NFT.
    /// @param _tokenId ID of the Art NFT.
    /// @return metadataURI The metadata URI of the NFT.
    /// @return dynamicData The dynamic data associated with the NFT.
    /// @return evolvable Whether the NFT is evolvable.
    /// @return owner The owner address of the NFT.
    function getArtDetails(uint256 _tokenId) public view validTokenId(_tokenId) returns (string memory metadataURI, string memory dynamicData, bool evolvable, address owner) {
        return (artMetadataURIs[_tokenId], artDynamicData[_tokenId], isArtEvolvable[_tokenId], artTokenOwner[_tokenId]);
    }

    /// @notice Returns listing details for a listed NFT.
    /// @param _tokenId ID of the Art NFT.
    /// @return price The listing price.
    /// @return seller The seller address.
    /// @return isActive Whether the listing is active.
    function getListingDetails(uint256 _tokenId) public view validTokenId(_tokenId) returns (uint256 price, address seller, bool isActive) {
        return (listings[_tokenId].price, listings[_tokenId].seller, listings[_tokenId].isActive);
    }

    /// @notice Returns details of an auction.
    /// @param _auctionId ID of the auction.
    /// @return tokenId The token ID being auctioned.
    /// @return startingPrice The starting price of the auction.
    /// @return endTime The auction end timestamp.
    /// @return seller The seller address.
    /// @return highestBidder The address of the highest bidder.
    /// @return highestBid The current highest bid amount.
    /// @return isActive Whether the auction is active.
    function getAuctionDetails(uint256 _auctionId) public view auctionExists(_auctionId) returns (uint256 tokenId, uint256 startingPrice, uint256 endTime, address seller, address highestBidder, uint256 highestBid, bool isActive) {
        Auction storage auction = auctions[_auctionId];
        return (auction.tokenId, auction.startingPrice, auction.endTime, auction.seller, auction.highestBidder, auction.highestBid, auction.isActive);
    }

    /// @notice Checks if an Art NFT is currently listed for sale.
    /// @param _tokenId ID of the Art NFT.
    /// @return True if listed, false otherwise.
    function isArtNFTListed(uint256 _tokenId) public view validTokenId(_tokenId) returns (bool) {
        return listings[_tokenId].isActive;
    }

    /// @notice Checks if an Art NFT is currently on auction.
    /// @param _tokenId ID of the Art NFT.
    /// @return True if on auction, false otherwise.
    function isArtNFTOnAuction(uint256 _tokenId) public view validTokenId(_tokenId) returns (bool) {
        for (uint256 i = 1; i < nextAuctionId; i++) {
            if (auctions[i].tokenId == _tokenId && auctions[i].isActive) {
                return true;
            }
        }
        return false;
    }

    /// @notice Fallback function to receive Ether.
    receive() external payable {}
}
```