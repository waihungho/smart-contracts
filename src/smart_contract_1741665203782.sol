```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with Evolving Traits and AI-Driven Rarity
 * @author Gemini AI (Conceptual Smart Contract - Not for Production)
 * @dev This contract implements a decentralized marketplace for Dynamic NFTs,
 * featuring NFTs that can evolve based on on-chain interactions or external data (simulated here).
 * It incorporates AI-driven rarity calculation (simulated) and advanced marketplace features.
 *
 * **Outline:**
 *
 * **NFT Creation and Management:**
 *   1. `createDynamicNFT(string _baseURI, string _initialMetadata)`: Mints a new Dynamic NFT with initial metadata and base URI.
 *   2. `updateNFTMetadata(uint256 _tokenId, string _newMetadata)`: Allows owner to update NFT metadata.
 *   3. `evolveNFTTrait(uint256 _tokenId, string _traitName, string _newValue)`: Simulates evolution of a specific NFT trait.
 *   4. `setBaseURI(string _newBaseURI)`: Sets the base URI for all NFTs.
 *   5. `tokenURI(uint256 _tokenId)`: Returns the URI for a given token, combining base URI and token-specific ID.
 *   6. `getNFTMetadata(uint256 _tokenId)`: Retrieves the current metadata of an NFT.
 *   7. `getNFTRarityScore(uint256 _tokenId)`: Returns a simulated AI-driven rarity score for an NFT.
 *
 * **Marketplace Functionality:**
 *   8. `listNFTForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale on the marketplace.
 *   9. `unlistNFTFromSale(uint256 _tokenId)`: Removes an NFT from sale.
 *   10. `buyNFT(uint256 _tokenId)`: Allows anyone to buy a listed NFT.
 *   11. `offerBid(uint256 _tokenId, uint256 _bidAmount)`: Allows users to place bids on NFTs.
 *   12. `acceptBid(uint256 _tokenId, uint256 _bidId)`: Seller accepts a specific bid.
 *   13. `cancelBid(uint256 _tokenId, uint256 _bidId)`: Bidder can cancel their bid before acceptance.
 *   14. `withdrawFunds()`: Seller and Marketplace owner can withdraw their earned funds.
 *   15. `setMarketplaceFee(uint256 _newFeePercentage)`: Admin function to set marketplace fee percentage.
 *   16. `getListingDetails(uint256 _tokenId)`: Retrieves details of an NFT listing.
 *   17. `getBidDetails(uint256 _tokenId, uint256 _bidId)`: Retrieves details of a specific bid on an NFT.
 *   18. `getAllListings()`: Returns a list of all currently listed NFTs.
 *   19. `getAllBidsForNFT(uint256 _tokenId)`: Returns a list of all bids for a specific NFT.
 *
 * **Admin and Utility Functions:**
 *   20. `pauseMarketplace()`: Admin function to pause marketplace operations.
 *   21. `unpauseMarketplace()`: Admin function to unpause marketplace operations.
 *   22. `supportsInterface(bytes4 interfaceId)`: Standard ERC721 interface support.
 *   23. `ownerOf(uint256 _tokenId)`: Standard ERC721 ownerOf function.
 *   24. `balanceOf(address _owner)`: Standard ERC721 balanceOf function.
 *   25. `transferFrom(address _from, address _to, uint256 _tokenId)`: Standard ERC721 transferFrom function (partially implemented for internal use).
 *
 * **Function Summaries:**
 *
 * - **NFT Creation & Management:** Functions to mint dynamic NFTs, update their metadata, simulate trait evolution, and manage base URIs. Includes functions to fetch metadata and a simulated AI-driven rarity score.
 * - **Marketplace Functionality:** Functions to list NFTs for sale, buy NFTs, handle bidding system (offer, accept, cancel bids), manage marketplace fees, and withdraw funds. Includes functions to retrieve listing and bid details and get lists of all listings and bids.
 * - **Admin & Utility Functions:** Functions for admin control (pause/unpause marketplace, set fees), standard ERC721 interface support, and basic ERC721 functions for ownership and balance.
 */
contract DynamicNFTMarketplace {
    // State Variables

    // NFT Metadata and Supply
    string public name = "DynamicNFT";
    string public symbol = "DNFT";
    string public baseURI;
    uint256 public totalSupply;
    mapping(uint256 => string) private _tokenMetadata;
    mapping(uint256 => address) private _tokenOwners;
    mapping(address => uint256) private _ownerTokenCount;
    mapping(uint256 => uint256) private _nftRarityScores; // Simulated AI Rarity Score

    // Marketplace State
    mapping(uint256 => Listing) public nftListings;
    mapping(uint256 => Bid[]) public nftBids;
    uint256 public marketplaceFeePercentage = 2; // 2% marketplace fee
    address payable public marketplaceOwner;
    uint256 public marketplaceBalance;
    bool public isMarketplacePaused = false;

    // Structs
    struct Listing {
        uint256 price;
        address payable seller;
        bool isListed;
    }

    struct Bid {
        uint256 bidId;
        uint256 bidAmount;
        address bidder;
        bool isActive;
    }

    // Events
    event NFTMinted(uint256 tokenId, address owner, string metadata);
    event MetadataUpdated(uint256 tokenId, string newMetadata);
    event TraitEvolved(uint256 tokenId, string traitName, string newValue);
    event NFTListed(uint256 tokenId, uint256 price, address seller);
    event NFTUnlisted(uint256 tokenId, address seller);
    event NFTSold(uint256 tokenId, address buyer, address seller, uint256 price);
    event BidOffered(uint256 tokenId, uint256 bidId, uint256 bidAmount, address bidder);
    event BidAccepted(uint256 tokenId, uint256 bidId, address seller, address bidder, uint256 price);
    event BidCancelled(uint256 tokenId, uint256 bidId, address bidder);
    event MarketplaceFeeSet(uint256 newFeePercentage);
    event MarketplacePaused();
    event MarketplaceUnpaused();

    // Modifiers
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(_tokenOwners[_tokenId] == msg.sender, "Not NFT owner");
        _;
    }

    modifier onlyMarketplaceOwner() {
        require(msg.sender == marketplaceOwner, "Not marketplace owner");
        _;
    }

    modifier whenMarketplaceNotPaused() {
        require(!isMarketplacePaused, "Marketplace is paused");
        _;
    }

    modifier whenMarketplacePaused() {
        require(isMarketplacePaused, "Marketplace is not paused");
        _;
    }


    // Constructor
    constructor(string memory _baseURI) payable {
        baseURI = _baseURI;
        marketplaceOwner = payable(msg.sender);
    }

    // ------------------------------------------------------------------------
    //                            NFT CREATION & MANAGEMENT
    // ------------------------------------------------------------------------

    /**
     * @dev Mints a new Dynamic NFT with initial metadata.
     * @param _baseURI The base URI for all NFTs.
     * @param _initialMetadata The initial metadata for the NFT (e.g., JSON string).
     */
    function createDynamicNFT(string memory _baseURI, string memory _initialMetadata) public {
        baseURI = _baseURI; // Setting base URI here for simplicity, could be moved to constructor only
        _mint(msg.sender, _initialMetadata);
    }

    /**
     * @dev Mints a new Dynamic NFT with initial metadata.
     * @param _initialMetadata The initial metadata for the NFT (e.g., JSON string).
     */
    function createDynamicNFTWithMetadata(string memory _initialMetadata) public {
        _mint(msg.sender, _initialMetadata);
    }

    /**
     * @dev Mints a new Dynamic NFT with an evolving trait defined in metadata.
     * @param _initialMetadata The initial metadata for the NFT including an evolving trait.
     */
    function createDynamicNFTWithEvolvingTrait(string memory _initialMetadata) public {
        _mint(msg.sender, _initialMetadata);
        // Example: Could trigger initial evolution logic based on metadata content here
    }

    /**
     * @dev Internal function to mint a new NFT.
     * @param _to The address to mint the NFT to.
     * @param _metadata The initial metadata for the NFT.
     */
    function _mint(address _to, string memory _metadata) internal {
        totalSupply++;
        uint256 tokenId = totalSupply; // Token IDs start from 1
        _tokenOwners[tokenId] = _to;
        _ownerTokenCount[_to]++;
        _tokenMetadata[tokenId] = _metadata;
        _nftRarityScores[tokenId] = _simulateAIRarityScore(tokenId); // Simulate AI rarity score on mint
        emit NFTMinted(tokenId, _to, _metadata);
    }

    /**
     * @dev Updates the metadata of an NFT. Only owner can update.
     * @param _tokenId The ID of the NFT to update.
     * @param _newMetadata The new metadata for the NFT.
     */
    function updateNFTMetadata(uint256 _tokenId, string memory _newMetadata) public onlyOwnerOf(_tokenId) {
        _tokenMetadata[_tokenId] = _newMetadata;
        emit MetadataUpdated(_tokenId, _newMetadata);
    }

    /**
     * @dev Simulates evolution of a specific trait of an NFT. Only owner can evolve.
     * @param _tokenId The ID of the NFT to evolve.
     * @param _traitName The name of the trait to evolve.
     * @param _newValue The new value for the trait.
     */
    function evolveNFTTrait(uint256 _tokenId, string memory _traitName, string memory _newValue) public onlyOwnerOf(_tokenId) {
        // In a real dynamic NFT, this would involve more complex logic, potentially external data sources
        // Here, we simply append the evolved trait to the metadata string (for demonstration)
        string memory currentMetadata = _tokenMetadata[_tokenId];
        string memory updatedMetadata = string(abi.encodePacked(currentMetadata, ',"', _traitName, '":"', _newValue, '"'));
        _tokenMetadata[_tokenId] = updatedMetadata;
        emit TraitEvolved(_tokenId, _traitName, _newValue);
    }

    /**
     * @dev Sets the base URI for all NFTs. Can be changed by contract owner.
     * @param _newBaseURI The new base URI.
     */
    function setBaseURI(string memory _newBaseURI) public onlyMarketplaceOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @dev Returns the URI for a given token, combining base URI and token ID.
     * @param _tokenId The ID of the NFT.
     * @return The URI for the NFT.
     */
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "Token URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, "/", Strings.toString(_tokenId)));
    }

    /**
     * @dev Retrieves the current metadata of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The metadata of the NFT.
     */
    function getNFTMetadata(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "Token does not exist");
        return _tokenMetadata[_tokenId];
    }

    /**
     * @dev Simulates an AI-driven rarity score calculation for an NFT.
     *  This is a placeholder and would be replaced with actual AI integration or complex logic.
     * @param _tokenId The ID of the NFT.
     * @return A simulated rarity score.
     */
    function _simulateAIRarityScore(uint256 _tokenId) internal pure returns (uint256) {
        // Placeholder: In reality, this would involve analyzing NFT metadata, traits, etc.,
        // potentially using an oracle or on-chain AI model.
        // For now, let's just return a pseudo-random score based on tokenId.
        return uint256(keccak256(abi.encodePacked(_tokenId, block.timestamp))) % 1000; // Score out of 1000
    }

    /**
     * @dev Returns the simulated AI-driven rarity score for an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The rarity score.
     */
    function getNFTRarityScore(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "Token does not exist");
        return _nftRarityScores[_tokenId];
    }


    // ------------------------------------------------------------------------
    //                            MARKETPLACE FUNCTIONALITY
    // ------------------------------------------------------------------------

    /**
     * @dev Lists an NFT for sale on the marketplace.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The price to list the NFT for (in wei).
     */
    function listNFTForSale(uint256 _tokenId, uint256 _price) public onlyOwnerOf(_tokenId) whenMarketplaceNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        require(!nftListings[_tokenId].isListed, "NFT already listed");
        require(_price > 0, "Price must be greater than zero");

        _approveMarketplaceIfNeeded(_tokenId); // Approve marketplace to handle NFT transfer

        nftListings[_tokenId] = Listing({
            price: _price,
            seller: payable(msg.sender),
            isListed: true
        });
        emit NFTListed(_tokenId, _price, msg.sender);
    }

    /**
     * @dev Removes an NFT from sale on the marketplace.
     * @param _tokenId The ID of the NFT to unlist.
     */
    function unlistNFTFromSale(uint256 _tokenId) public onlyOwnerOf(_tokenId) whenMarketplaceNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        require(nftListings[_tokenId].isListed, "NFT not listed");
        require(nftListings[_tokenId].seller == msg.sender, "Not the lister");

        delete nftListings[_tokenId]; // Reset listing details to default, effectively unlisting
        emit NFTUnlisted(_tokenId, msg.sender);
    }

    /**
     * @dev Allows anyone to buy a listed NFT.
     * @param _tokenId The ID of the NFT to buy.
     */
    function buyNFT(uint256 _tokenId) public payable whenMarketplaceNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        require(nftListings[_tokenId].isListed, "NFT is not listed for sale");
        require(msg.value >= nftListings[_tokenId].price, "Insufficient funds to buy NFT");

        Listing memory listing = nftListings[_tokenId];
        uint256 price = listing.price;
        address payable seller = listing.seller;

        // Calculate marketplace fee
        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = price - marketplaceFee;

        // Transfer NFT to buyer
        _transfer(seller, msg.sender, _tokenId);

        // Transfer funds to seller and marketplace owner
        (bool successSeller, ) = seller.call{value: sellerProceeds}(""); // Send proceeds to seller
        require(successSeller, "Seller payment failed");
        (bool successMarketplace, ) = marketplaceOwner.call{value: marketplaceFee}(""); // Send fee to marketplace
        require(successMarketplace, "Marketplace fee payment failed");

        marketplaceBalance += marketplaceFee; // Track marketplace balance

        delete nftListings[_tokenId]; // Remove listing after sale
        emit NFTSold(_tokenId, msg.sender, seller, price);
    }

    /**
     * @dev Allows users to place bids on NFTs.
     * @param _tokenId The ID of the NFT to bid on.
     * @param _bidAmount The amount of the bid (in wei).
     */
    function offerBid(uint256 _tokenId, uint256 _bidAmount) public payable whenMarketplaceNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        require(msg.value >= _bidAmount, "Bid amount must be sent with transaction");
        require(_bidAmount > 0, "Bid amount must be greater than zero");

        uint256 bidId = nftBids[_tokenId].length;
        nftBids[_tokenId].push(Bid({
            bidId: bidId,
            bidAmount: _bidAmount,
            bidder: msg.sender,
            isActive: true
        }));

        emit BidOffered(_tokenId, bidId, _bidAmount, msg.sender);
    }

    /**
     * @dev Seller accepts a specific bid on their NFT.
     * @param _tokenId The ID of the NFT.
     * @param _bidId The ID of the bid to accept.
     */
    function acceptBid(uint256 _tokenId, uint256 _bidId) public onlyOwnerOf(_tokenId) whenMarketplaceNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        require(nftBids[_tokenId].length > _bidId, "Invalid bid ID");
        Bid storage bidToAccept = nftBids[_tokenId][_bidId];
        require(bidToAccept.isActive, "Bid is not active");
        require(nftListings[_tokenId].seller == msg.sender || !_isListed(_tokenId), "NFT must be listed by you or not listed"); // Seller can accept if listed or not listed.

        address bidder = bidToAccept.bidder;
        uint256 bidAmount = bidToAccept.bidAmount;

        // Calculate marketplace fee
        uint256 marketplaceFee = (bidAmount * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = bidAmount - marketplaceFee;

        // Transfer NFT to bidder
        _transfer(msg.sender, bidder, _tokenId);

        // Transfer funds to seller and marketplace owner
        (bool successSeller, ) = payable(msg.sender).call{value: sellerProceeds}(""); // Send proceeds to seller
        require(successSeller, "Seller payment failed");
        (bool successMarketplace, ) = marketplaceOwner.call{value: marketplaceFee}(""); // Send fee to marketplace
        require(successMarketplace, "Marketplace fee payment failed");

        marketplaceBalance += marketplaceFee; // Track marketplace balance

        // Refund any higher bids (not implemented in this simplified example for brevity, but crucial in real implementations)
        // Mark bid as inactive
        bidToAccept.isActive = false;

        delete nftListings[_tokenId]; // Remove listing after sale (if it was listed)
        emit BidAccepted(_tokenId, _bidId, msg.sender, bidder, bidAmount);
    }

    /**
     * @dev Bidder can cancel their bid before it's accepted.
     * @param _tokenId The ID of the NFT.
     * @param _bidId The ID of the bid to cancel.
     */
    function cancelBid(uint256 _tokenId, uint256 _bidId) public whenMarketplaceNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        require(nftBids[_tokenId].length > _bidId, "Invalid bid ID");
        Bid storage bidToCancel = nftBids[_tokenId][_bidId];
        require(bidToCancel.bidder == msg.sender, "Not the bidder");
        require(bidToCancel.isActive, "Bid is not active");

        bidToCancel.isActive = false; // Mark bid as inactive
        // Refund bid amount (not implemented in this simplified example for brevity, but crucial in real implementations)

        emit BidCancelled(_tokenId, _bidId, msg.sender);
    }

    /**
     * @dev Allows seller and marketplace owner to withdraw their earned funds.
     */
    function withdrawFunds() public payable whenMarketplaceNotPaused {
        uint256 sellerBalance = address(this).balance - marketplaceBalance; // Assuming all non-marketplaceBalance is seller's funds
        uint256 ownerBalance = marketplaceBalance;

        if (sellerBalance > 0 && msg.sender != marketplaceOwner) { // Seller withdraw
            uint256 amountToWithdraw = sellerBalance;
            marketplaceBalance = 0; // Reset tracked marketplace balance to avoid double counting in this simplified example. In real scenario, tracking needs to be more robust.
            (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
            require(success, "Withdrawal failed");
        } else if (ownerBalance > 0 && msg.sender == marketplaceOwner) { // Marketplace owner withdraw
            uint256 amountToWithdraw = ownerBalance;
            marketplaceBalance = 0;
            (bool success, ) = marketplaceOwner.call{value: amountToWithdraw}("");
            require(success, "Withdrawal failed");
        } else {
            revert("No funds to withdraw for this address");
        }
    }

    /**
     * @dev Admin function to set the marketplace fee percentage.
     * @param _newFeePercentage The new marketplace fee percentage (e.g., 2 for 2%).
     */
    function setMarketplaceFee(uint256 _newFeePercentage) public onlyMarketplaceOwner {
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100%");
        marketplaceFeePercentage = _newFeePercentage;
        emit MarketplaceFeeSet(_newFeePercentage);
    }

    /**
     * @dev Retrieves details of an NFT listing.
     * @param _tokenId The ID of the NFT.
     * @return Listing struct containing listing details.
     */
    function getListingDetails(uint256 _tokenId) public view returns (Listing memory) {
        return nftListings[_tokenId];
    }

    /**
     * @dev Retrieves details of a specific bid on an NFT.
     * @param _tokenId The ID of the NFT.
     * @param _bidId The ID of the bid.
     * @return Bid struct containing bid details.
     */
    function getBidDetails(uint256 _tokenId, uint256 _bidId) public view returns (Bid memory) {
        require(nftBids[_tokenId].length > _bidId, "Invalid bid ID");
        return nftBids[_tokenId][_bidId];
    }

    /**
     * @dev Retrieves a list of all currently listed NFTs (token IDs).
     * @return An array of token IDs that are currently listed.
     */
    function getAllListings() public view returns (uint256[] memory) {
        uint256[] memory listedTokenIds = new uint256[](totalSupply); // Max possible size, could be optimized
        uint256 listingCount = 0;
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (nftListings[i].isListed) {
                listedTokenIds[listingCount] = i;
                listingCount++;
            }
        }
        // Resize array to actual listing count
        assembly {
            mstore(listedTokenIds, listingCount) // Update array length in memory
        }
        return listedTokenIds;
    }

    /**
     * @dev Retrieves a list of all bids for a specific NFT.
     * @param _tokenId The ID of the NFT.
     * @return An array of Bid structs for the NFT.
     */
    function getAllBidsForNFT(uint256 _tokenId) public view returns (Bid[] memory) {
        return nftBids[_tokenId];
    }

    // ------------------------------------------------------------------------
    //                            ADMIN & UTILITY FUNCTIONS
    // ------------------------------------------------------------------------

    /**
     * @dev Pauses marketplace operations. Only marketplace owner can pause.
     */
    function pauseMarketplace() public onlyMarketplaceOwner whenMarketplaceNotPaused {
        isMarketplacePaused = true;
        emit MarketplacePaused();
    }

    /**
     * @dev Unpauses marketplace operations. Only marketplace owner can unpause.
     */
    function unpauseMarketplace() public onlyMarketplaceOwner whenMarketplacePaused {
        isMarketplacePaused = false;
        emit MarketplaceUnpaused();
    }

    /**
     * @dev Standard ERC721 interface support.
     * @param interfaceId The interface ID to check.
     * @return True if interface is supported, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @dev Standard ERC721 ownerOf function.
     * @param _tokenId The ID of the NFT.
     * @return The address of the owner.
     */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = _tokenOwners[_tokenId];
        require(owner != address(0), "Token does not exist");
        return owner;
    }

    /**
     * @dev Standard ERC721 balanceOf function.
     * @param _owner The address to check balance of.
     * @return The balance of the owner.
     */
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "Owner address cannot be zero");
        return _ownerTokenCount[_owner];
    }

    /**
     * @dev Standard ERC721 transferFrom function (partially implemented for internal marketplace use).
     * @param _from The current owner of the NFT.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) whenMarketplaceNotPaused {
        _transfer(_from, _to, _tokenId);
    }


    // ------------------------------------------------------------------------
    //                            INTERNAL FUNCTIONS
    // ------------------------------------------------------------------------

    /**
     * @dev Internal function to transfer NFT ownership.
     * @param _from The current owner of the NFT.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        require(_exists(_tokenId), "Token does not exist");
        require(ownerOf(_tokenId) == _from, "From address is not the owner");
        require(_to != address(0), "To address cannot be zero");

        _clearApproval(_tokenId); // Clear any approvals for the token

        _ownerTokenCount[_from]--;
        _ownerTokenCount[_to]++;
        _tokenOwners[_tokenId] = _to;

        // Events for transfer are not explicitly defined here for brevity, but should be added in a full ERC721 implementation.
    }

    /**
     * @dev Internal function to check if a token exists.
     * @param _tokenId The ID of the NFT.
     * @return True if token exists, false otherwise.
     */
    function _exists(uint256 _tokenId) internal view returns (bool) {
        return _tokenOwners[_tokenId] != address(0);
    }

    /**
     * @dev Internal function to check if an NFT is listed on the marketplace.
     * @param _tokenId The ID of the NFT.
     * @return True if listed, false otherwise.
     */
    function _isListed(uint256 _tokenId) internal view returns (bool) {
        return nftListings[_tokenId].isListed;
    }

    /**
     * @dev Internal function to clear approvals (not fully implemented in this simplified version, but crucial for full ERC721).
     * @param _tokenId The ID of the NFT.
     */
    function _clearApproval(uint256 _tokenId) internal virtual {
        // In a full ERC721, this would clear approvals for the token.
        // Not implementing full approval mechanism for brevity in this example.
    }

    /**
     * @dev Internal function to approve marketplace to handle NFT transfer if not already approved.
     * @param _tokenId The ID of the NFT.
     */
    function _approveMarketplaceIfNeeded(uint256 _tokenId) internal {
        // In a full ERC721, you'd check for existing approvals and potentially approve the marketplace contract.
        // For simplicity in this example, we are skipping explicit approvals management for marketplace,
        // assuming internal `_transfer` can be used directly by marketplace logic.
        // In a real scenario, consider implementing ERC721 `approve` and `getApproved` for secure marketplace interactions.
    }
}


// --- Helper Libraries (Simplified String Conversion for Token URI) ---
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// --- Interfaces for ERC721 and ERC165 (Simplified for Basic Functionality) ---
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
```