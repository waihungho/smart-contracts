```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with Advanced Features
 * @author Bard (Example Implementation)
 * @dev This contract implements a decentralized marketplace for Dynamic NFTs with various advanced and creative features.
 *
 * Function Summary:
 *
 * **NFT Management (Dynamic & Core)**
 * 1. `createDynamicNFT(string memory _baseURI, string memory _initialMetadata)`: Mints a new Dynamic NFT with customizable base URI and initial metadata.
 * 2. `updateNFTMetadata(uint256 _tokenId, string memory _newMetadata)`: Allows the NFT owner to update the metadata of their NFT, triggering dynamic changes.
 * 3. `getNFTMetadata(uint256 _tokenId)`: Retrieves the current metadata URI for a given NFT ID.
 * 4. `setNFTDynamicTrait(uint256 _tokenId, string memory _traitName, string memory _traitValue)`:  Demonstrates a dynamic trait update function. (More complex logic can be added).
 * 5. `burnNFT(uint256 _tokenId)`: Allows the NFT owner to burn/destroy their NFT.
 *
 * **Marketplace Core Functions**
 * 6. `listItem(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale on the marketplace.
 * 7. `buyItem(uint256 _itemId)`: Allows anyone to purchase a listed NFT.
 * 8. `delistItem(uint256 _itemId)`: Allows the seller to remove their NFT from the marketplace.
 * 9. `getItemDetails(uint256 _itemId)`: Retrieves detailed information about a listed item.
 * 10. `getAllListedItems()`: Returns a list of all currently listed items on the marketplace.
 *
 * **Advanced Marketplace Features**
 * 11. `createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration)`: Starts a time-based English auction for an NFT.
 * 12. `bidOnAuction(uint256 _auctionId)`: Allows users to bid on an active auction.
 * 13. `endAuction(uint256 _auctionId)`: Ends an auction and transfers the NFT to the highest bidder.
 * 14. `makeOffer(uint256 _tokenId, uint256 _offerPrice)`: Allows users to make an offer on an NFT that is not currently listed.
 * 15. `acceptOffer(uint256 _offerId)`: Allows the NFT owner to accept a specific offer.
 * 16. `cancelOffer(uint256 _offerId)`: Allows the offer maker to cancel their pending offer.
 * 17. `createBundleSale(uint256[] memory _tokenIds, uint256 _bundlePrice)`: Allows users to create a bundle of multiple NFTs for sale at a fixed price.
 * 18. `buyBundle(uint256 _bundleId)`: Allows users to purchase a bundle of NFTs.
 * 19. `setMarketplaceFee(uint256 _feePercentage)`: Allows the contract owner to set a marketplace fee percentage.
 * 20. `withdrawMarketplaceFees()`: Allows the contract owner to withdraw accumulated marketplace fees.
 * 21. `pauseMarketplace()`: Allows the contract owner to pause all marketplace functionalities for emergency or maintenance.
 * 22. `unpauseMarketplace()`: Allows the contract owner to resume marketplace functionalities.
 * 23. `supportsInterface(bytes4 interfaceId)`:  Standard ERC721 interface support.
 */
contract DynamicNFTMarketplace {
    // --- State Variables ---

    string public name = "DynamicNFTMarketplace";
    string public symbol = "DNFTM";
    uint256 public currentItemId = 0;
    uint256 public currentAuctionId = 0;
    uint256 public currentOfferId = 0;
    uint256 public currentBundleId = 0;
    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    address payable public marketplaceFeeRecipient;
    bool public paused = false;

    mapping(uint256 => address) public nftOwner;
    mapping(uint256 => string) public nftMetadataURIs;
    mapping(uint256 => string) public nftBaseURIs;
    mapping(uint256 => bool) public nftExists;
    mapping(uint256 => Item) public items;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => Offer) public offers;
    mapping(uint256 => Bundle) public bundles;
    mapping(address => uint256) public marketplaceFeeBalances; // Track fees owed to marketplace

    address public contractOwner;

    struct Item {
        uint256 itemId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isSold;
        bool isListed;
    }

    struct Auction {
        uint256 auctionId;
        uint256 tokenId;
        address seller;
        uint256 startingBid;
        uint256 highestBid;
        address highestBidder;
        uint256 auctionEndTime;
        bool isActive;
    }

    struct Offer {
        uint256 offerId;
        uint256 tokenId;
        address offerer;
        uint256 offerPrice;
        bool isActive;
    }

    struct Bundle {
        uint256 bundleId;
        uint256[] tokenIds;
        address seller;
        uint256 bundlePrice;
        bool isSold;
    }

    // --- Events ---
    event NFTCreated(uint256 tokenId, address owner, string baseURI, string metadataURI);
    event NFTMetadataUpdated(uint256 tokenId, string newMetadataURI);
    event NFTBurned(uint256 tokenId, address owner);
    event ItemListed(uint256 itemId, uint256 tokenId, address seller, uint256 price);
    event ItemSold(uint256 itemId, uint256 tokenId, address seller, address buyer, uint256 price);
    event ItemDelisted(uint256 itemId, uint256 tokenId, address seller);
    event AuctionCreated(uint256 auctionId, uint256 tokenId, address seller, uint256 startingBid, uint256 endTime);
    event BidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionEnded(uint256 auctionId, uint256 tokenId, address seller, address winner, uint256 finalPrice);
    event OfferMade(uint256 offerId, uint256 tokenId, address offerer, uint256 offerPrice);
    event OfferAccepted(uint256 offerId, uint256 tokenId, address seller, address buyer, uint256 price);
    event OfferCancelled(uint256 offerId, address offerer);
    event BundleCreated(uint256 bundleId, uint256[] tokenIds, address seller, uint256 bundlePrice);
    event BundleSold(uint256 bundleId, uint256[] tokenIds, address seller, address buyer, uint256 bundlePrice);
    event MarketplaceFeeUpdated(uint256 newFeePercentage);
    event MarketplaceFeesWithdrawn(uint256 amount, address recipient);
    event MarketplacePaused();
    event MarketplaceUnpaused();

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function.");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(nftOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        _;
    }

    modifier onlyMarketplaceActive() {
        require(!paused, "Marketplace is currently paused.");
        _;
    }

    // --- Constructor ---
    constructor(address payable _feeRecipient) {
        contractOwner = msg.sender;
        marketplaceFeeRecipient = _feeRecipient;
    }

    // --- NFT Management Functions ---

    /**
     * @dev Creates a new Dynamic NFT.
     * @param _baseURI The base URI for the NFT's metadata.
     * @param _initialMetadata The initial metadata URI for the NFT.
     */
    function createDynamicNFT(string memory _baseURI, string memory _initialMetadata) public onlyMarketplaceActive returns (uint256) {
        currentItemId++; // Reuse itemId as tokenId for simplicity in this example
        uint256 tokenId = currentItemId;
        nftOwner[tokenId] = msg.sender;
        nftMetadataURIs[tokenId] = _initialMetadata;
        nftBaseURIs[tokenId] = _baseURI;
        nftExists[tokenId] = true; // Track if NFT exists (for burn functionality)

        emit NFTCreated(tokenId, msg.sender, _baseURI, _initialMetadata);
        return tokenId;
    }

    /**
     * @dev Updates the metadata URI of an existing NFT.
     * @param _tokenId The ID of the NFT to update.
     * @param _newMetadata The new metadata URI.
     */
    function updateNFTMetadata(uint256 _tokenId, string memory _newMetadata) public onlyNFTOwner(_tokenId) onlyMarketplaceActive {
        require(nftExists[_tokenId], "NFT does not exist.");
        nftMetadataURIs[_tokenId] = _newMetadata;
        emit NFTMetadataUpdated(_tokenId, _newMetadata);
    }

    /**
     * @dev Retrieves the current metadata URI for a given NFT ID.
     * @param _tokenId The ID of the NFT.
     * @return The metadata URI string.
     */
    function getNFTMetadata(uint256 _tokenId) public view returns (string memory) {
        require(nftExists[_tokenId], "NFT does not exist.");
        return nftMetadataURIs[_tokenId];
    }

    /**
     * @dev Example of setting a dynamic trait of an NFT. Can be extended for more complex dynamic behaviors.
     * @param _tokenId The ID of the NFT.
     * @param _traitName The name of the trait to update.
     * @param _traitValue The new value of the trait.
     * @dev Note: This is a placeholder. Dynamic traits are typically reflected in the metadata URI and require off-chain services for rendering and updates.
     */
    function setNFTDynamicTrait(uint256 _tokenId, string memory _traitName, string memory _traitValue) public onlyNFTOwner(_tokenId) onlyMarketplaceActive {
        require(nftExists[_tokenId], "NFT does not exist.");
        // In a real dynamic NFT, you would likely update the metadata URI here to reflect the trait change.
        // This might involve constructing a new metadata URI based on the base URI and updated traits,
        // potentially using off-chain services to generate and host the updated metadata.
        // For this example, we'll just emit an event to demonstrate the concept.
        emit NFTMetadataUpdated(_tokenId, string(abi.encodePacked(nftBaseURIs[_tokenId], "?trait=", _traitName, "=", _traitValue))); // Simple example, needs robust metadata update mechanism
    }

    /**
     * @dev Burns (destroys) an NFT.
     * @param _tokenId The ID of the NFT to burn.
     */
    function burnNFT(uint256 _tokenId) public onlyNFTOwner(_tokenId) onlyMarketplaceActive {
        require(nftExists[_tokenId], "NFT does not exist.");
        delete nftOwner[_tokenId];
        delete nftMetadataURIs[_tokenId];
        delete nftBaseURIs[_tokenId];
        nftExists[_tokenId] = false; // Mark as not existing
        emit NFTBurned(_tokenId, msg.sender);
    }


    // --- Marketplace Core Functions ---

    /**
     * @dev Lists an NFT for sale on the marketplace.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The listing price in wei.
     */
    function listItem(uint256 _tokenId, uint256 _price) public onlyNFTOwner(_tokenId) onlyMarketplaceActive {
        require(nftExists[_tokenId], "NFT does not exist.");
        require(items[_tokenId].itemId == 0 || !items[_tokenId].isListed, "NFT is already listed or an item ID conflict exists."); // Ensure not already listed or item ID conflict
        require(_price > 0, "Price must be greater than zero.");

        currentItemId++;
        Item storage item = items[currentItemId];
        item.itemId = currentItemId;
        item.tokenId = _tokenId;
        item.seller = msg.sender;
        item.price = _price;
        item.isSold = false;
        item.isListed = true;

        emit ItemListed(currentItemId, _tokenId, msg.sender, _price);
    }

    /**
     * @dev Allows anyone to purchase a listed NFT.
     * @param _itemId The ID of the listed item.
     */
    function buyItem(uint256 _itemId) public payable onlyMarketplaceActive {
        Item storage item = items[_itemId];
        require(item.isListed, "Item is not listed for sale.");
        require(!item.isSold, "Item is already sold.");
        require(msg.value >= item.price, "Insufficient funds to purchase item.");

        uint256 marketplaceFee = (item.price * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = item.price - marketplaceFee;

        // Transfer funds to seller and marketplace fee recipient
        payable(item.seller).transfer(sellerProceeds);
        marketplaceFeeBalances[marketplaceFeeRecipient] += marketplaceFee;

        // Update NFT ownership and item status
        nftOwner[item.tokenId] = msg.sender;
        item.isSold = true;
        item.isListed = false;

        emit ItemSold(_itemId, item.tokenId, item.seller, msg.sender, item.price);

        // Refund any excess payment
        if (msg.value > item.price) {
            payable(msg.sender).transfer(msg.value - item.price);
        }
    }

    /**
     * @dev Allows the seller to remove their NFT from the marketplace.
     * @param _itemId The ID of the listed item.
     */
    function delistItem(uint256 _itemId) public onlyMarketplaceActive {
        Item storage item = items[_itemId];
        require(item.seller == msg.sender, "Only the seller can delist this item.");
        require(item.isListed, "Item is not currently listed.");
        require(!item.isSold, "Item is already sold and cannot be delisted.");

        item.isListed = false;
        emit ItemDelisted(_itemId, item.tokenId, msg.sender);
    }

    /**
     * @dev Retrieves detailed information about a listed item.
     * @param _itemId The ID of the listed item.
     * @return Item struct containing item details.
     */
    function getItemDetails(uint256 _itemId) public view returns (Item memory) {
        require(items[_itemId].itemId != 0, "Item does not exist."); // Ensure item ID is valid
        return items[_itemId];
    }

    /**
     * @dev Returns a list of all currently listed items on the marketplace.
     * @return An array of Item structs representing listed items.
     */
    function getAllListedItems() public view returns (Item[] memory) {
        uint256 listedItemCount = 0;
        for (uint256 i = 1; i <= currentItemId; i++) { // Iterate through possible item IDs (from 1 to currentItemId)
            if (items[i].isListed && !items[i].isSold) {
                listedItemCount++;
            }
        }

        Item[] memory listedItems = new Item[](listedItemCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= currentItemId; i++) {
            if (items[i].isListed && !items[i].isSold) {
                listedItems[index] = items[i];
                index++;
            }
        }
        return listedItems;
    }


    // --- Advanced Marketplace Features ---

    /**
     * @dev Creates a new English auction for an NFT.
     * @param _tokenId The ID of the NFT to auction.
     * @param _startingBid The starting bid price in wei.
     * @param _auctionDuration The duration of the auction in seconds.
     */
    function createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration) public onlyNFTOwner(_tokenId) onlyMarketplaceActive {
        require(nftExists[_tokenId], "NFT does not exist.");
        require(_startingBid > 0, "Starting bid must be greater than zero.");
        require(_auctionDuration > 0, "Auction duration must be greater than zero.");

        currentAuctionId++;
        Auction storage auction = auctions[currentAuctionId];
        auction.auctionId = currentAuctionId;
        auction.tokenId = _tokenId;
        auction.seller = msg.sender;
        auction.startingBid = _startingBid;
        auction.highestBid = _startingBid; // Initial highest bid is the starting bid
        auction.highestBidder = address(0); // No bidder initially
        auction.auctionEndTime = block.timestamp + _auctionDuration;
        auction.isActive = true;

        emit AuctionCreated(currentAuctionId, _tokenId, msg.sender, _startingBid, auction.auctionEndTime);
    }

    /**
     * @dev Allows users to place a bid on an active auction.
     * @param _auctionId The ID of the auction to bid on.
     */
    function bidOnAuction(uint256 _auctionId) public payable onlyMarketplaceActive {
        Auction storage auction = auctions[_auctionId];
        require(auction.isActive, "Auction is not active.");
        require(block.timestamp < auction.auctionEndTime, "Auction has ended.");
        require(msg.value > auction.highestBid, "Bid must be higher than the current highest bid.");

        if (auction.highestBidder != address(0)) {
            // Refund previous highest bidder (if any, except for the very first bid which starts with startingBid)
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;
        emit BidPlaced(_auctionId, msg.sender, msg.value);
    }

    /**
     * @dev Ends an auction and transfers the NFT to the highest bidder.
     * @param _auctionId The ID of the auction to end.
     */
    function endAuction(uint256 _auctionId) public onlyMarketplaceActive {
        Auction storage auction = auctions[_auctionId];
        require(auction.isActive, "Auction is not active.");
        require(block.timestamp >= auction.auctionEndTime, "Auction time has not yet elapsed.");

        auction.isActive = false;
        uint256 finalPrice = auction.highestBid;
        address winner = auction.highestBidder;

        if (winner != address(0)) {
            uint256 marketplaceFee = (finalPrice * marketplaceFeePercentage) / 100;
            uint256 sellerProceeds = finalPrice - marketplaceFee;

            // Transfer funds to seller and marketplace fee recipient
            payable(auction.seller).transfer(sellerProceeds);
            marketplaceFeeBalances[marketplaceFeeRecipient] += marketplaceFee;

            // Transfer NFT to the winner
            nftOwner[auction.tokenId] = winner;

            emit AuctionEnded(_auctionId, auction.tokenId, auction.seller, winner, finalPrice);
        } else {
            // No bids placed, auction ends without a winner. NFT stays with the seller.
            emit AuctionEnded(_auctionId, auction.tokenId, auction.seller, address(0), 0);
        }
    }

    /**
     * @dev Allows users to make an offer on an NFT that is not currently listed.
     * @param _tokenId The ID of the NFT to make an offer on.
     * @param _offerPrice The offer price in wei.
     */
    function makeOffer(uint256 _tokenId, uint256 _offerPrice) public payable onlyMarketplaceActive {
        require(nftExists[_tokenId], "NFT does not exist.");
        require(_offerPrice > 0, "Offer price must be greater than zero.");

        currentOfferId++;
        Offer storage offer = offers[currentOfferId];
        offer.offerId = currentOfferId;
        offer.tokenId = _tokenId;
        offer.offerer = msg.sender;
        offer.offerPrice = _offerPrice;
        offer.isActive = true;

        emit OfferMade(currentOfferId, _tokenId, msg.sender, _offerPrice);
    }

    /**
     * @dev Allows the NFT owner to accept a specific offer.
     * @param _offerId The ID of the offer to accept.
     */
    function acceptOffer(uint256 _offerId) public onlyNFTOwner(offers[_offerId].tokenId) onlyMarketplaceActive {
        Offer storage offer = offers[_offerId];
        require(offer.isActive, "Offer is not active.");
        require(offer.offerPrice > 0, "Invalid offer price."); // Sanity check

        uint256 price = offer.offerPrice;
        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = price - marketplaceFee;

        // Transfer funds to seller and marketplace fee recipient (offer price was already sent when making offer - assuming in a real implementation, not just payable here for simplicity)
        payable(offer.offerer).transfer(price); //  For simplicity in this example, assuming offerer initially sent funds. In real implementation, escrow/hold funds might be needed.
        payable(nftOwner[offer.tokenId]).transfer(sellerProceeds); // Seller receives proceeds
        marketplaceFeeBalances[marketplaceFeeRecipient] += marketplaceFee;

        // Update NFT ownership and offer status
        nftOwner[offer.tokenId] = offer.offerer;
        offer.isActive = false; // Mark offer as inactive

        emit OfferAccepted(_offerId, offer.tokenId, msg.sender, offer.offerer, price);
    }

    /**
     * @dev Allows the offer maker to cancel their pending offer.
     * @param _offerId The ID of the offer to cancel.
     */
    function cancelOffer(uint256 _offerId) public onlyMarketplaceActive {
        Offer storage offer = offers[_offerId];
        require(offer.offerer == msg.sender, "Only the offerer can cancel this offer.");
        require(offer.isActive, "Offer is not active.");

        offer.isActive = false;
        emit OfferCancelled(_offerId, msg.sender);

        // In a real implementation, you would need to refund any funds held in escrow for the offer.
        // For this simplified example, we are assuming funds are not held in escrow during offer making.
    }

    /**
     * @dev Creates a bundle of multiple NFTs for sale at a fixed price.
     * @param _tokenIds An array of NFT token IDs to include in the bundle.
     * @param _bundlePrice The total price of the bundle in wei.
     */
    function createBundleSale(uint256[] memory _tokenIds, uint256 _bundlePrice) public onlyMarketplaceActive {
        require(_tokenIds.length > 1, "Bundle must contain at least two NFTs.");
        require(_bundlePrice > 0, "Bundle price must be greater than zero.");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(nftOwner[_tokenIds[i]] == msg.sender, "You are not the owner of all NFTs in the bundle.");
            require(nftExists[_tokenIds[i]], "One or more NFTs in the bundle do not exist.");
        }

        currentBundleId++;
        Bundle storage bundle = bundles[currentBundleId];
        bundle.bundleId = currentBundleId;
        bundle.tokenIds = _tokenIds;
        bundle.seller = msg.sender;
        bundle.bundlePrice = _bundlePrice;
        bundle.isSold = false;

        emit BundleCreated(currentBundleId, _tokenIds, msg.sender, _bundlePrice);
    }

    /**
     * @dev Allows users to purchase a bundle of NFTs.
     * @param _bundleId The ID of the bundle to purchase.
     */
    function buyBundle(uint256 _bundleId) public payable onlyMarketplaceActive {
        Bundle storage bundle = bundles[_bundleId];
        require(!bundle.isSold, "Bundle is already sold.");
        require(msg.value >= bundle.bundlePrice, "Insufficient funds to purchase bundle.");

        uint256 marketplaceFee = (bundle.bundlePrice * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = bundle.bundlePrice - marketplaceFee;

        // Transfer funds to seller and marketplace fee recipient
        payable(bundle.seller).transfer(sellerProceeds);
        marketplaceFeeBalances[marketplaceFeeRecipient] += marketplaceFee;

        // Transfer NFTs in the bundle to the buyer
        for (uint256 i = 0; i < bundle.tokenIds.length; i++) {
            nftOwner[bundle.tokenIds[i]] = msg.sender;
        }

        bundle.isSold = true;
        emit BundleSold(_bundleId, bundle.tokenIds, bundle.seller, msg.sender, bundle.bundlePrice);

        // Refund any excess payment
        if (msg.value > bundle.bundlePrice) {
            payable(msg.sender).transfer(msg.value - bundle.bundlePrice);
        }
    }


    // --- Marketplace Administration Functions ---

    /**
     * @dev Sets the marketplace fee percentage. Only callable by the contract owner.
     * @param _feePercentage The new marketplace fee percentage (e.g., 2 for 2%).
     */
    function setMarketplaceFee(uint256 _feePercentage) public onlyOwner onlyMarketplaceActive {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%.");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeUpdated(_feePercentage);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated marketplace fees.
     */
    function withdrawMarketplaceFees() public onlyOwner onlyMarketplaceActive {
        uint256 balance = marketplaceFeeBalances[marketplaceFeeRecipient];
        require(balance > 0, "No marketplace fees to withdraw.");

        marketplaceFeeBalances[marketplaceFeeRecipient] = 0; // Reset balance before transfer to prevent re-entrancy issues if possible
        payable(marketplaceFeeRecipient).transfer(balance);
        emit MarketplaceFeesWithdrawn(balance, marketplaceFeeRecipient);
    }

    /**
     * @dev Pauses all marketplace functionalities. Only callable by the contract owner.
     */
    function pauseMarketplace() public onlyOwner {
        paused = true;
        emit MarketplacePaused();
    }

    /**
     * @dev Resumes marketplace functionalities after being paused. Only callable by the contract owner.
     */
    function unpauseMarketplace() public onlyOwner {
        paused = false;
        emit MarketplaceUnpaused();
    }

    // --- ERC721 Interface Support (Partial - for basic compatibility) ---
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == 0x80ac58cd || // ERC721 Interface ID
               interfaceId == 0x5b5e139f;   // ERC721Metadata Interface ID (optional for now)
    }
}
```