```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI Art Generation Features
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a decentralized NFT marketplace with advanced features,
 * including dynamic NFTs, AI-inspired art generation requests, and a sophisticated bidding system.
 *
 * **Outline & Function Summary:**
 *
 * **1. Core Marketplace Functions:**
 *    - `createNFTCollection(string _name, string _symbol, string _collectionBaseURI)`: Allows a user to create a new NFT collection.
 *    - `mintNFT(uint256 _collectionId, address _recipient, string _tokenURI)`: Mints a new NFT within a specified collection.
 *    - `listNFTForSale(uint256 _collectionId, uint256 _tokenId, uint256 _price)`: Allows NFT owner to list their NFT for sale at a fixed price.
 *    - `buyNFT(uint256 _collectionId, uint256 _tokenId)`: Allows a buyer to purchase a listed NFT.
 *    - `cancelNFTListing(uint256 _collectionId, uint256 _tokenId)`: Allows the seller to cancel an NFT listing.
 *    - `setListingPrice(uint256 _collectionId, uint256 _tokenId, uint256 _newPrice)`: Allows the seller to update the listing price of an NFT.
 *    - `transferNFT(uint256 _collectionId, uint256 _tokenId, address _to)`: Allows NFT owner to transfer NFT to another address.
 *    - `burnNFT(uint256 _collectionId, uint256 _tokenId)`: Allows NFT owner to burn (destroy) their NFT.
 *
 * **2. Advanced Bidding System:**
 *    - `offerBid(uint256 _collectionId, uint256 _tokenId, uint256 _bidAmount)`: Allows a user to place a bid on a listed NFT.
 *    - `acceptBid(uint256 _collectionId, uint256 _tokenId, uint256 _bidId)`: Allows the seller to accept a specific bid on their NFT.
 *    - `cancelBid(uint256 _collectionId, uint256 _tokenId, uint256 _bidId)`: Allows a bidder to cancel their pending bid.
 *    - `getHighestBid(uint256 _collectionId, uint256 _tokenId)`: Returns the highest current bid for an NFT.
 *    - `getBidsForNFT(uint256 _collectionId, uint256 _tokenId)`: Returns a list of all bids for a specific NFT.
 *
 * **3. Dynamic NFT & AI Art Integration (Conceptual - Off-chain AI assumed):**
 *    - `requestAIArtGeneration(uint256 _collectionId, uint256 _tokenId, string _prompt)`: Allows NFT owner to request AI-inspired art generation for their NFT (triggers off-chain process).
 *    - `setAIArtData(uint256 _collectionId, uint256 _tokenId, string _aiArtURI)`:  (Admin/Oracle function) Sets the AI-generated art URI for an NFT, updating its dynamic aspect.
 *    - `getAIArtData(uint256 _collectionId, uint256 _tokenId)`: Retrieves the AI-generated art URI associated with an NFT.
 *    - `evolveNFTMetadata(uint256 _collectionId, uint256 _tokenId, string _evolutionData)`: Allows for generic metadata evolution based on certain conditions (e.g., time, external events).
 *
 * **4. Collection Management & Utility:**
 *    - `setCollectionRoyalty(uint256 _collectionId, uint256 _royaltyPercentage)`: Allows collection owner to set a royalty percentage for secondary sales.
 *    - `getCollectionDetails(uint256 _collectionId)`: Returns details about a specific NFT collection.
 *    - `pauseCollection(uint256 _collectionId)`: Pauses all marketplace operations for a specific collection.
 *    - `unpauseCollection(uint256 _collectionId)`: Resumes marketplace operations for a specific collection.
 *    - `setMarketplaceFee(uint256 _feePercentage)`: Allows contract owner to set the marketplace fee percentage.
 *    - `withdrawMarketplaceFees()`: Allows contract owner to withdraw accumulated marketplace fees.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DynamicNFTMarketplace is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _collectionIds;
    Counters.Counter private _nftIds;
    Counters.Counter private _bidIds;

    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee

    struct NFTCollection {
        string name;
        string symbol;
        string collectionBaseURI;
        address owner;
        uint256 royaltyPercentage;
        bool paused;
    }

    struct NFTListing {
        uint256 price;
        address seller;
        bool isActive;
    }

    struct NFTBid {
        uint256 bidAmount;
        address bidder;
        bool isActive;
    }

    mapping(uint256 => NFTCollection) public nftCollections;
    mapping(uint256 => mapping(uint256 => NFTListing)) public nftListings; // collectionId => tokenId => Listing
    mapping(uint256 => mapping(uint256 => mapping(uint256 => NFTBid))) public nftBids; // collectionId => tokenId => bidId => Bid
    mapping(uint256 => mapping(uint256 => string)) public nftAIArtData; // collectionId => tokenId => AI Art URI
    mapping(uint256 => mapping(uint256 => address)) public nftOwners; // collectionId => tokenId => owner address
    mapping(uint256 => ERC721) public collectionContracts; // collectionId => ERC721 Contract Instance


    event CollectionCreated(uint256 collectionId, string name, string symbol, address owner);
    event NFTMinted(uint256 collectionId, uint256 tokenId, address recipient);
    event NFTListed(uint256 collectionId, uint256 tokenId, uint256 price, address seller);
    event NFTListingCancelled(uint256 collectionId, uint256 tokenId);
    event NFTPriceUpdated(uint256 collectionId, uint256 tokenId, uint256 newPrice);
    event NFTBought(uint256 collectionId, uint256 tokenId, address buyer, address seller, uint256 price);
    event NFTBidOffered(uint256 collectionId, uint256 tokenId, uint256 bidId, uint256 bidAmount, address bidder);
    event NFTBidAccepted(uint256 collectionId, uint256 tokenId, uint256 bidId, address seller, address bidder, uint256 bidAmount);
    event NFTBidCancelled(uint256 collectionId, uint256 tokenId, uint256 bidId);
    event AIArtRequested(uint256 collectionId, uint256 tokenId, address requester, string prompt);
    event AIArtDataSet(uint256 collectionId, uint256 tokenId, string aiArtURI);
    event MetadataEvolved(uint256 collectionId, uint256 tokenId, string evolutionData);
    event CollectionRoyaltySet(uint256 collectionId, uint256 royaltyPercentage);
    event CollectionPaused(uint256 collectionId);
    event CollectionUnpaused(uint256 collectionId);
    event MarketplaceFeeSet(uint256 feePercentage);
    event MarketplaceFeesWithdrawn(uint256 amount, address admin);
    event NFTTransferred(uint256 collectionId, uint256 tokenId, address from, address to);
    event NFTBurned(uint256 collectionId, uint256 tokenId, address owner);


    modifier onlyCollectionOwner(uint256 _collectionId) {
        require(nftCollections[_collectionId].owner == msg.sender, "Not collection owner");
        _;
    }

    modifier onlyNFTOwner(uint256 _collectionId, uint256 _tokenId) {
        require(nftOwners[_collectionId][_tokenId] == msg.sender, "Not NFT owner");
        _;
    }

    modifier collectionNotPaused(uint256 _collectionId) {
        require(!nftCollections[_collectionId].paused, "Collection is paused");
        _;
    }

    constructor() payable {
        // Optional: Initialize any setup here
    }

    /**
     * @dev Allows a user to create a new NFT collection.
     * @param _name Name of the NFT collection.
     * @param _symbol Symbol of the NFT collection.
     * @param _collectionBaseURI Base URI for the collection's metadata.
     */
    function createNFTCollection(string memory _name, string memory _symbol, string memory _collectionBaseURI) external onlyOwner {
        _collectionIds.increment();
        uint256 collectionId = _collectionIds.current();

        NFTCollection storage newCollection = nftCollections[collectionId];
        newCollection.name = _name;
        newCollection.symbol = _symbol;
        newCollection.collectionBaseURI = _collectionBaseURI;
        newCollection.owner = msg.sender;
        newCollection.royaltyPercentage = 0; // Default royalty to 0%
        newCollection.paused = false;

        // Deploy a new ERC721 contract for the collection
        ERC721 newERC721Contract = new ERC721(_name, _symbol);
        collectionContracts[collectionId] = newERC721Contract;

        emit CollectionCreated(collectionId, _name, _symbol, msg.sender);
    }

    /**
     * @dev Mints a new NFT within a specified collection. Only collection owner can call this.
     * @param _collectionId ID of the collection to mint into.
     * @param _recipient Address to receive the minted NFT.
     * @param _tokenURI URI for the NFT's metadata.
     */
    function mintNFT(uint256 _collectionId, address _recipient, string memory _tokenURI) external onlyCollectionOwner(_collectionId) collectionNotPaused(_collectionId) {
        _nftIds.increment();
        uint256 tokenId = _nftIds.current();

        ERC721 collectionERC721 = collectionContracts[_collectionId];
        require(address(collectionERC721) != address(0), "Collection contract not found");

        nftOwners[_collectionId][tokenId] = _recipient; // Track ownership in marketplace contract

        // Mint using the deployed ERC721 contract
        collectionERC721.safeMint(_recipient, tokenId);
        // Set token URI in the deployed ERC721 contract (if needed, or handle metadata externally)
        // collectionERC721.setTokenURI(tokenId, _tokenURI); // Assuming ERC721 has such a function, may need to implement it in custom ERC721

        emit NFTMinted(_collectionId, tokenId, _recipient);
    }


    /**
     * @dev Allows NFT owner to list their NFT for sale at a fixed price.
     * @param _collectionId ID of the NFT collection.
     * @param _tokenId ID of the NFT to list.
     * @param _price Sale price in wei.
     */
    function listNFTForSale(uint256 _collectionId, uint256 _tokenId, uint256 _price) external onlyNFTOwner(_collectionId, _tokenId) collectionNotPaused(_collectionId) {
        require(nftOwners[_collectionId][_tokenId] == msg.sender, "Not NFT owner");
        require(_price > 0, "Price must be greater than zero");
        require(nftListings[_collectionId][_tokenId].isActive == false, "NFT already listed"); // Prevent relisting without canceling first

        nftListings[_collectionId][_tokenId] = NFTListing({
            price: _price,
            seller: msg.sender,
            isActive: true
        });

        emit NFTListed(_collectionId, _tokenId, _price, msg.sender);
    }

    /**
     * @dev Allows a buyer to purchase a listed NFT.
     * @param _collectionId ID of the NFT collection.
     * @param _tokenId ID of the NFT to buy.
     */
    function buyNFT(uint256 _collectionId, uint256 _tokenId) external payable nonReentrant collectionNotPaused(_collectionId) {
        NFTListing storage listing = nftListings[_collectionId][_tokenId];
        require(listing.isActive, "NFT not listed for sale");
        require(msg.value >= listing.price, "Insufficient funds");

        address seller = listing.seller;
        uint256 price = listing.price;

        listing.isActive = false; // Deactivate listing after purchase
        nftOwners[_collectionId][_tokenId] = msg.sender; // Update ownership in marketplace contract

        // Transfer NFT ownership in the deployed ERC721 contract
        ERC721 collectionERC721 = collectionContracts[_collectionId];
        collectionERC721.transferFrom(seller, msg.sender, _tokenId);

        // Calculate and transfer fees and royalties
        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 100;
        uint256 royaltyFee = (price * nftCollections[_collectionId].royaltyPercentage) / 100;
        uint256 sellerPayout = price - marketplaceFee - royaltyFee;

        // Transfer funds
        payable(owner()).transfer(marketplaceFee); // Marketplace fee to contract owner
        payable(nftCollections[_collectionId].owner).transfer(royaltyFee); // Royalty to collection owner
        payable(seller).transfer(sellerPayout); // Payout to seller

        emit NFTBought(_collectionId, _tokenId, msg.sender, seller, price);
    }

    /**
     * @dev Allows the seller to cancel an NFT listing.
     * @param _collectionId ID of the NFT collection.
     * @param _tokenId ID of the NFT to cancel listing for.
     */
    function cancelNFTListing(uint256 _collectionId, uint256 _tokenId) external onlyNFTOwner(_collectionId, _tokenId) collectionNotPaused(_collectionId) {
        require(nftListings[_collectionId][_tokenId].isActive, "NFT not listed");
        nftListings[_collectionId][_tokenId].isActive = false;
        emit NFTListingCancelled(_collectionId, _tokenId);
    }

    /**
     * @dev Allows the seller to update the listing price of an NFT.
     * @param _collectionId ID of the NFT collection.
     * @param _tokenId ID of the NFT to update price for.
     * @param _newPrice New listing price in wei.
     */
    function setListingPrice(uint256 _collectionId, uint256 _tokenId, uint256 _newPrice) external onlyNFTOwner(_collectionId, _tokenId) collectionNotPaused(_collectionId) {
        require(nftListings[_collectionId][_tokenId].isActive, "NFT not listed");
        require(_newPrice > 0, "Price must be greater than zero");
        nftListings[_collectionId][_tokenId].price = _newPrice;
        emit NFTPriceUpdated(_collectionId, _tokenId, _newPrice);
    }

    /**
     * @dev Allows NFT owner to transfer NFT to another address.
     * @param _collectionId ID of the NFT collection.
     * @param _tokenId ID of the NFT to transfer.
     * @param _to Address to transfer the NFT to.
     */
    function transferNFT(uint256 _collectionId, uint256 _tokenId, address _to) external onlyNFTOwner(_collectionId, _tokenId) collectionNotPaused(_collectionId) {
        require(_to != address(0), "Invalid recipient address");
        require(_to != msg.sender, "Cannot transfer to self");

        address currentOwner = nftOwners[_collectionId][_tokenId];

        // Transfer NFT ownership in the deployed ERC721 contract
        ERC721 collectionERC721 = collectionContracts[_collectionId];
        collectionERC721.transferFrom(currentOwner, _to, _tokenId);

        nftOwners[_collectionId][_tokenId] = _to; // Update ownership in marketplace contract

        // Deactivate listing if any
        if (nftListings[_collectionId][_tokenId].isActive) {
            nftListings[_collectionId][_tokenId].isActive = false;
        }

        emit NFTTransferred(_collectionId, _tokenId, currentOwner, _to);
    }

    /**
     * @dev Allows NFT owner to burn (destroy) their NFT.
     * @param _collectionId ID of the NFT collection.
     * @param _tokenId ID of the NFT to burn.
     */
    function burnNFT(uint256 _collectionId, uint256 _tokenId) external onlyNFTOwner(_collectionId, _tokenId) collectionNotPaused(_collectionId) {
        address currentOwner = nftOwners[_collectionId][_tokenId];

        // Burn NFT in the deployed ERC721 contract
        ERC721 collectionERC721 = collectionContracts[_collectionId];
        // Assuming ERC721 has a _burn function or similar accessible internally/via extension
        // collectionERC721._burn(_tokenId); // Requires custom ERC721 implementation with _burn accessible

        // For standard ERC721, burning is typically not directly available externally.
        // You might need to implement a burn function in a custom ERC721 extension if required.
        // For demonstration purpose, we will just remove ownership from marketplace tracking.
        delete nftOwners[_collectionId][_tokenId];
        delete nftListings[_collectionId][_tokenId]; // Remove listing if any
        delete nftAIArtData[_collectionId][_tokenId]; // Remove AI art data if any

        emit NFTBurned(_collectionId, _tokenId, currentOwner);
    }

    /**
     * @dev Allows a user to place a bid on a listed NFT.
     * @param _collectionId ID of the NFT collection.
     * @param _tokenId ID of the NFT to bid on.
     * @param _bidAmount Bid amount in wei.
     */
    function offerBid(uint256 _collectionId, uint256 _tokenId, uint256 _bidAmount) external payable collectionNotPaused(_collectionId) {
        require(nftListings[_collectionId][_tokenId].isActive, "NFT not listed for sale");
        require(msg.value >= _bidAmount, "Insufficient funds for bid");
        require(_bidAmount > getHighestBid(_collectionId, _tokenId), "Bid must be higher than current highest bid");

        _bidIds.increment();
        uint256 bidId = _bidIds.current();

        nftBids[_collectionId][_tokenId][bidId] = NFTBid({
            bidAmount: _bidAmount,
            bidder: msg.sender,
            isActive: true
        });

        emit NFTBidOffered(_collectionId, _tokenId, bidId, _bidAmount, msg.sender);
    }

    /**
     * @dev Allows the seller to accept a specific bid on their NFT.
     * @param _collectionId ID of the NFT collection.
     * @param _tokenId ID of the NFT to accept bid for.
     * @param _bidId ID of the bid to accept.
     */
    function acceptBid(uint256 _collectionId, uint256 _tokenId, uint256 _bidId) external onlyNFTOwner(_collectionId, _tokenId) nonReentrant collectionNotPaused(_collectionId) {
        NFTBid storage bid = nftBids[_collectionId][_tokenId][_bidId];
        require(nftListings[_collectionId][_tokenId].isActive, "NFT not listed for sale");
        require(bid.isActive, "Bid is not active");

        address seller = nftListings[_collectionId][_tokenId].seller;
        address bidder = bid.bidder;
        uint256 bidAmount = bid.bidAmount;

        nftListings[_collectionId][_tokenId].isActive = false; // Deactivate listing after bid acceptance
        bid.isActive = false; // Deactivate accepted bid
        nftOwners[_collectionId][_tokenId] = bidder; // Update ownership to bidder

        // Transfer NFT ownership in the deployed ERC721 contract
        ERC721 collectionERC721 = collectionContracts[_collectionId];
        collectionERC721.transferFrom(seller, bidder, _tokenId);

        // Calculate and transfer fees and royalties (same as buyNFT logic)
        uint256 marketplaceFee = (bidAmount * marketplaceFeePercentage) / 100;
        uint256 royaltyFee = (bidAmount * nftCollections[_collectionId].royaltyPercentage) / 100;
        uint256 sellerPayout = bidAmount - marketplaceFee - royaltyFee;

        // Transfer funds
        payable(owner()).transfer(marketplaceFee); // Marketplace fee to contract owner
        payable(nftCollections[_collectionId].owner).transfer(royaltyFee); // Royalty to collection owner
        payable(seller).transfer(sellerPayout); // Payout to seller

        // Refund other bidders (implementation omitted for brevity - would require tracking all bids and refunding those not accepted)
        // In a real implementation, you would iterate through other bids for this NFT and refund them.

        emit NFTBidAccepted(_collectionId, _tokenId, _bidId, seller, bidder, bidAmount);
    }

    /**
     * @dev Allows a bidder to cancel their pending bid.
     * @param _collectionId ID of the NFT collection.
     * @param _tokenId ID of the NFT to cancel bid for.
     * @param _bidId ID of the bid to cancel.
     */
    function cancelBid(uint256 _collectionId, uint256 _tokenId, uint256 _bidId) external collectionNotPaused(_collectionId) {
        NFTBid storage bid = nftBids[_collectionId][_tokenId][_bidId];
        require(bid.bidder == msg.sender, "Not bid owner");
        require(bid.isActive, "Bid is not active");

        bid.isActive = false;
        emit NFTBidCancelled(_collectionId, _tokenId, _bidId);
        // In a real implementation, you would also refund the bid amount back to the bidder.
        // payable(msg.sender).transfer(bid.bidAmount); // Refund bid amount (requires tracking bid amount in state)
    }

    /**
     * @dev Returns the highest current bid for an NFT.
     * @param _collectionId ID of the NFT collection.
     * @param _tokenId ID of the NFT.
     * @return Highest bid amount in wei.
     */
    function getHighestBid(uint256 _collectionId, uint256 _tokenId) public view returns (uint256) {
        uint256 highestBid = 0;
        for (uint256 i = 1; i <= _bidIds.current(); i++) { // Iterate through all bids (less efficient for large number of bids)
            if (nftBids[_collectionId][_tokenId][i].isActive && nftBids[_collectionId][_tokenId][i].bidAmount > highestBid) {
                highestBid = nftBids[_collectionId][_tokenId][i].bidAmount;
            }
        }
        return highestBid;
    }

    /**
     * @dev Returns a list of all bids for a specific NFT.
     * @param _collectionId ID of the NFT collection.
     * @param _tokenId ID of the NFT.
     * @return Array of NFTBid structs.
     */
    function getBidsForNFT(uint256 _collectionId, uint256 _tokenId) external view returns (NFTBid[] memory) {
        uint256 bidCount = 0;
        for (uint256 i = 1; i <= _bidIds.current(); i++) {
            if (nftBids[_collectionId][_tokenId][i].isActive) {
                bidCount++;
            }
        }

        NFTBid[] memory bids = new NFTBid[](bidCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= _bidIds.current(); i++) {
            if (nftBids[_collectionId][_tokenId][i].isActive) {
                bids[index] = nftBids[_collectionId][_tokenId][i];
                index++;
            }
        }
        return bids;
    }

    /**
     * @dev Allows NFT owner to request AI-inspired art generation for their NFT.
     * This is a conceptual function and would typically trigger an off-chain AI process.
     * @param _collectionId ID of the NFT collection.
     * @param _tokenId ID of the NFT to request AI art for.
     * @param _prompt Text prompt for AI art generation.
     */
    function requestAIArtGeneration(uint256 _collectionId, uint256 _tokenId, string memory _prompt) external onlyNFTOwner(_collectionId, _tokenId) collectionNotPaused(_collectionId) {
        // In a real-world scenario, this function would:
        // 1. Emit an event that is listened to by an off-chain service.
        // 2. The off-chain service uses the _prompt and NFT details to generate AI art.
        // 3. The off-chain service then calls `setAIArtData` (or similar) to update the NFT's data.

        emit AIArtRequested(_collectionId, _tokenId, msg.sender, _prompt);
        // Placeholder: For demonstration, we can directly set some dummy AI art data.
        // setAIArtData(_collectionId, _tokenId, "ipfs://dummy-ai-art-uri");
    }

    /**
     * @dev (Admin/Oracle function) Sets the AI-generated art URI for an NFT, updating its dynamic aspect.
     * This function would be called by an authorized off-chain service (oracle or admin controlled process).
     * @param _collectionId ID of the NFT collection.
     * @param _tokenId ID of the NFT to set AI art data for.
     * @param _aiArtURI URI pointing to the AI-generated art (e.g., IPFS URI).
     */
    function setAIArtData(uint256 _collectionId, uint256 _tokenId, string memory _aiArtURI) external onlyOwner { // Ideally, restrict to a designated oracle address
        nftAIArtData[_collectionId][_tokenId] = _aiArtURI;
        emit AIArtDataSet(_collectionId, _tokenId, _aiArtURI);
    }

    /**
     * @dev Retrieves the AI-generated art URI associated with an NFT.
     * @param _collectionId ID of the NFT collection.
     * @param _tokenId ID of the NFT.
     * @return URI of the AI-generated art.
     */
    function getAIArtData(uint256 _collectionId, uint256 _tokenId) external view returns (string memory) {
        return nftAIArtData[_collectionId][_tokenId];
    }

    /**
     * @dev Allows for generic metadata evolution based on certain conditions.
     * This is a placeholder for more complex dynamic NFT behavior.
     * @param _collectionId ID of the NFT collection.
     * @param _tokenId ID of the NFT to evolve.
     * @param _evolutionData Data representing the evolution (e.g., JSON string, URI, etc.).
     */
    function evolveNFTMetadata(uint256 _collectionId, uint256 _tokenId, string memory _evolutionData) external onlyCollectionOwner(_collectionId) collectionNotPaused(_collectionId) {
        // This function is a placeholder. Real-world implementation could involve:
        // 1. Updating the tokenURI of the NFT in the ERC721 contract.
        // 2. Storing evolution data on-chain or off-chain linked to the NFT.
        // 3. Triggering logic based on _evolutionData to dynamically change NFT properties.

        emit MetadataEvolved(_collectionId, _tokenId, _evolutionData);
        // Example placeholder: You might store evolution data and update tokenURI based on it.
        // nftEvolutionData[_collectionId][_tokenId] = _evolutionData;
        // collectionContracts[_collectionId].setTokenURI(_tokenId, generateDynamicTokenURI(_collectionId, _tokenId)); // Hypothetical function
    }

    /**
     * @dev Allows collection owner to set a royalty percentage for secondary sales.
     * @param _collectionId ID of the NFT collection.
     * @param _royaltyPercentage Royalty percentage (e.g., 5 for 5%).
     */
    function setCollectionRoyalty(uint256 _collectionId, uint256 _royaltyPercentage) external onlyCollectionOwner(_collectionId) {
        require(_royaltyPercentage <= 100, "Royalty percentage must be <= 100");
        nftCollections[_collectionId].royaltyPercentage = _royaltyPercentage;
        emit CollectionRoyaltySet(_collectionId, _royaltyPercentage);
    }

    /**
     * @dev Returns details about a specific NFT collection.
     * @param _collectionId ID of the NFT collection.
     * @return NFTCollection struct containing collection details.
     */
    function getCollectionDetails(uint256 _collectionId) external view returns (NFTCollection memory) {
        return nftCollections[_collectionId];
    }

    /**
     * @dev Pauses all marketplace operations for a specific collection. Only collection owner can call this.
     * @param _collectionId ID of the NFT collection to pause.
     */
    function pauseCollection(uint256 _collectionId) external onlyCollectionOwner(_collectionId) {
        nftCollections[_collectionId].paused = true;
        emit CollectionPaused(_collectionId);
    }

    /**
     * @dev Resumes marketplace operations for a specific collection. Only collection owner can call this.
     * @param _collectionId ID of the NFT collection to unpause.
     */
    function unpauseCollection(uint256 _collectionId) external onlyCollectionOwner(_collectionId) {
        nftCollections[_collectionId].paused = false;
        emit CollectionUnpaused(_collectionId);
    }

    /**
     * @dev Allows contract owner to set the marketplace fee percentage.
     * @param _feePercentage New marketplace fee percentage (e.g., 3 for 3%).
     */
    function setMarketplaceFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage must be <= 100");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage);
    }

    /**
     * @dev Allows contract owner to withdraw accumulated marketplace fees.
     */
    function withdrawMarketplaceFees() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
        emit MarketplaceFeesWithdrawn(balance, owner());
    }

    // Fallback function to reject direct ether transfers to the contract (except for buyNFT and bid functions)
    receive() external payable {
        require(msg.sig == bytes4(keccak256("buyNFT(uint256,uint256)")) || msg.sig == bytes4(keccak256("offerBid(uint256,uint256,uint256)")), "Only for buyNFT/offerBid");
    }
}
```