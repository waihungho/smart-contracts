```solidity
/**
 * @title Decentralized Dynamic NFT Marketplace with AI Art Generation
 * @author Gemini AI
 * @dev A smart contract implementing a dynamic NFT marketplace with integrated AI art generation capabilities.
 *      This contract allows users to mint unique AI-generated NFTs based on prompts, list them for sale,
 *      participate in auctions, and dynamically update NFT metadata based on on-chain or off-chain events.
 *      It incorporates advanced concepts like dynamic NFTs, AI interaction (simulated here), and a comprehensive marketplace.
 *
 * Function Summary:
 * -----------------
 * **NFT Minting & Management:**
 * 1. `mintAIArtNFT(string memory _prompt, string memory _style)`: Mints a new AI-generated NFT based on a user prompt and style.
 * 2. `setBaseURI(string memory _baseURI)`: Sets the base URI for NFT metadata (Owner only).
 * 3. `tokenURI(uint256 _tokenId)`: Returns the URI for the metadata of a specific NFT.
 * 4. `updateNFTMetadata(uint256 _tokenId, string memory _newMetadataURI)`: Updates the metadata URI of an NFT (Owner or approved operator).
 * 5. `transferNFT(address _to, uint256 _tokenId)`: Transfers NFT ownership to another address.
 * 6. `approveNFT(address _approved, uint256 _tokenId)`: Approves an address to operate on a specific NFT.
 * 7. `getApprovedNFT(uint256 _tokenId)`: Retrieves the approved address for a specific NFT.
 * 8. `setApprovalForAllNFT(address _operator, bool _approved)`: Enables or disables approval for all NFTs for an operator.
 * 9. `isApprovedForAllNFT(address _owner, address _operator)`: Checks if an operator is approved for all NFTs of an owner.
 * 10. `burnNFT(uint256 _tokenId)`: Burns (destroys) a specific NFT (Owner only).
 *
 * **Marketplace Functions:**
 * 11. `listNFTForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale in the marketplace.
 * 12. `buyNFT(uint256 _listingId)`: Allows anyone to buy an NFT listed for sale.
 * 13. `cancelNFTListing(uint256 _listingId)`: Cancels an NFT listing (Seller only).
 * 14. `createAuction(uint256 _tokenId, uint256 _startPrice, uint256 _duration)`: Creates an auction for an NFT.
 * 15. `bidOnAuction(uint256 _auctionId)`: Allows users to bid on an active auction.
 * 16. `endAuction(uint256 _auctionId)`: Ends an auction and transfers NFT to the highest bidder.
 * 17. `getListingDetails(uint256 _listingId)`: Retrieves details of a specific NFT listing.
 * 18. `getAuctionDetails(uint256 _auctionId)`: Retrieves details of a specific NFT auction.
 * 19. `setPlatformFee(uint256 _feePercentage)`: Sets the platform fee percentage for marketplace transactions (Owner only).
 * 20. `withdrawPlatformFees()`: Allows the contract owner to withdraw accumulated platform fees.
 *
 * **Utility & Admin Functions:**
 * 21. `pauseContract()`: Pauses the contract, disabling critical functions (Owner only).
 * 22. `unpauseContract()`: Resumes the contract after pausing (Owner only).
 * 23. `supportsInterface(bytes4 interfaceId)`: Standard ERC721 interface support check.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

contract DecentralizedAIDynamicNFTMarketplace is ERC721, Ownable, Pausable, IERC721Receiver, IERC721Metadata, IERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _listingIdCounter;
    Counters.Counter private _auctionIdCounter;

    string private _baseURI;
    uint256 public platformFeePercentage = 2; // Default 2% platform fee
    address payable public platformFeeRecipient;

    // Mapping from token ID to metadata URI (dynamic metadata concept)
    mapping(uint256 => string) private _tokenMetadataURIs;

    // Marketplace Listings
    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => uint256) public tokenIdToListingId; // Token ID to listing ID for quick lookup

    // Auctions
    struct Auction {
        uint256 auctionId;
        uint256 tokenId;
        address seller;
        uint256 startPrice;
        uint256 currentBid;
        address highestBidder;
        uint256 endTime;
        bool isActive;
    }
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => uint256) public tokenIdToAuctionId; // Token ID to auction ID for quick lookup

    event NFTMinted(uint256 tokenId, address minter, string prompt, string style);
    event NFTListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event NFTBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event NFTListingCancelled(uint256 listingId, uint256 tokenId, address seller);
    event AuctionCreated(uint256 auctionId, uint256 tokenId, address seller, uint256 startPrice, uint256 duration);
    event BidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionEnded(uint256 auctionId, uint256 tokenId, address winner, uint256 finalPrice);
    event MetadataUpdated(uint256 tokenId, string newMetadataURI);

    constructor(string memory _name, string memory _symbol, string memory _uri) ERC721(_name, _symbol) {
        _baseURI = _uri;
        platformFeeRecipient = payable(msg.sender); // Owner is default recipient
    }

    /**
     * @dev Sets the base URI for all token metadata. Only callable by the contract owner.
     * @param _baseURI The new base URI.
     */
    function setBaseURI(string memory _baseURI) public onlyOwner {
        _baseURI = _baseURI;
    }

    /**
     * @dev Returns the base URI for token metadata.
     * @return string The base URI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev Mints a new AI-generated NFT.
     * @param _prompt The prompt used to generate the AI art.
     * @param _style The style of AI art to generate.
     * @return uint256 The ID of the newly minted NFT.
     *
     * @notice In a real-world scenario, AI generation would likely happen off-chain.
     *         This function simulates the process and assigns a metadata URI based on prompt/style.
     */
    function mintAIArtNFT(string memory _prompt, string memory _style) public whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);

        // Simulate AI art generation and metadata URI creation
        string memory metadataURI = string(abi.encodePacked(_baseURI, "/", Strings.toString(tokenId), ".json?prompt=", _prompt, "&style=", _style));
        _tokenMetadataURIs[tokenId] = metadataURI;

        emit NFTMinted(tokenId, msg.sender, _prompt, _style);
        return tokenId;
    }

    /**
     * @dev Returns the URI for the metadata of a specific NFT.
     * @param _tokenId The ID of the NFT.
     * @return string The metadata URI.
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenMetadataURIs[_tokenId];
    }

    /**
     * @dev Updates the metadata URI of an NFT. Can be called by the owner or approved operator.
     * @param _tokenId The ID of the NFT to update.
     * @param _newMetadataURI The new metadata URI.
     */
    function updateNFTMetadata(uint256 _tokenId, string memory _newMetadataURI) public whenNotPaused {
        require(_exists(_tokenId), "NFTMarketplace: Token does not exist");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "NFTMarketplace: Not owner or approved");
        _tokenMetadataURIs[_tokenId] = _newMetadataURI;
        emit MetadataUpdated(_tokenId, _newMetadataURI);
    }

    /**
     * @dev Lists an NFT for sale in the marketplace.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The sale price in wei.
     */
    function listNFTForSale(uint256 _tokenId, uint256 _price) public whenNotPaused {
        require(_exists(_tokenId), "NFTMarketplace: Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "NFTMarketplace: Not token owner");
        require(getApproved(_tokenId) == address(0), "NFTMarketplace: Token is approved for another operator, please revoke approval first");
        require(tokenIdToListingId[_tokenId] == 0, "NFTMarketplace: Token already listed");
        require(tokenIdToAuctionId[_tokenId] == 0, "NFTMarketplace: Token is in auction, cannot list");

        _listingIdCounter.increment();
        uint256 listingId = _listingIdCounter.current();

        _approve(address(this), _tokenId); // Approve contract to transfer NFT on sale

        listings[listingId] = Listing({
            listingId: listingId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        tokenIdToListingId[_tokenId] = listingId;

        emit NFTListed(listingId, _tokenId, msg.sender, _price);
    }

    /**
     * @dev Allows anyone to buy an NFT listed for sale.
     * @param _listingId The ID of the listing.
     */
    function buyNFT(uint256 _listingId) public payable whenNotPaused {
        require(listings[_listingId].isActive, "NFTMarketplace: Listing is not active");
        require(listings[_listingId].price == msg.value, "NFTMarketplace: Incorrect purchase price");

        Listing storage listing = listings[_listingId];
        uint256 tokenId = listing.tokenId;
        address seller = listing.seller;
        uint256 price = listing.price;

        listing.isActive = false;
        tokenIdToListingId[tokenId] = 0;

        // Transfer NFT
        _transfer(seller, msg.sender, tokenId);

        // Calculate platform fee and transfer funds
        uint256 platformFee = (price * platformFeePercentage) / 100;
        uint256 sellerProceeds = price - platformFee;

        (bool successSeller, ) = payable(seller).call{value: sellerProceeds}("");
        require(successSeller, "NFTMarketplace: Seller payment failed");
        (bool successPlatform, ) = platformFeeRecipient.call{value: platformFee}("");
        require(successPlatform, "NFTMarketplace: Platform fee payment failed");

        emit NFTBought(_listingId, tokenId, msg.sender, price);
    }

    /**
     * @dev Cancels an NFT listing. Only the seller can cancel.
     * @param _listingId The ID of the listing to cancel.
     */
    function cancelNFTListing(uint256 _listingId) public whenNotPaused {
        require(listings[_listingId].isActive, "NFTMarketplace: Listing is not active");
        require(listings[_listingId].seller == msg.sender, "NFTMarketplace: Not listing seller");

        Listing storage listing = listings[_listingId];
        uint256 tokenId = listing.tokenId;

        listing.isActive = false;
        tokenIdToListingId[tokenId] = 0;
        _approve(address(0), tokenId); // Revoke contract approval

        emit NFTListingCancelled(_listingId, tokenId, msg.sender);
    }

    /**
     * @dev Creates an auction for an NFT.
     * @param _tokenId The ID of the NFT to auction.
     * @param _startPrice The starting bid price in wei.
     * @param _duration Auction duration in seconds.
     */
    function createAuction(uint256 _tokenId, uint256 _startPrice, uint256 _duration) public whenNotPaused {
        require(_exists(_tokenId), "NFTMarketplace: Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "NFTMarketplace: Not token owner");
        require(getApproved(_tokenId) == address(0), "NFTMarketplace: Token is approved for another operator, please revoke approval first");
        require(tokenIdToAuctionId[_tokenId] == 0, "NFTMarketplace: Token already in auction or listed");
        require(tokenIdToListingId[_tokenId] == 0, "NFTMarketplace: Token is listed for sale, cannot auction");
        require(_duration > 0, "NFTMarketplace: Auction duration must be positive");

        _auctionIdCounter.increment();
        uint256 auctionId = _auctionIdCounter.current();
        uint256 endTime = block.timestamp + _duration;

        _approve(address(this), _tokenId); // Approve contract to transfer NFT on auction

        auctions[auctionId] = Auction({
            auctionId: auctionId,
            tokenId: _tokenId,
            seller: msg.sender,
            startPrice: _startPrice,
            currentBid: 0,
            highestBidder: address(0),
            endTime: endTime,
            isActive: true
        });
        tokenIdToAuctionId[_tokenId] = auctionId;

        emit AuctionCreated(auctionId, _tokenId, msg.sender, _startPrice, _duration);
    }

    /**
     * @dev Allows users to bid on an active auction.
     * @param _auctionId The ID of the auction.
     */
    function bidOnAuction(uint256 _auctionId) public payable whenNotPaused {
        require(auctions[_auctionId].isActive, "NFTMarketplace: Auction is not active");
        require(block.timestamp < auctions[_auctionId].endTime, "NFTMarketplace: Auction has ended");
        require(msg.value > auctions[_auctionId].currentBid, "NFTMarketplace: Bid amount is too low");

        Auction storage auction = auctions[_auctionId];

        if (auction.currentBid > 0) {
            // Refund previous highest bidder
            (bool refundSuccess, ) = auction.highestBidder.call{value: auction.currentBid}("");
            require(refundSuccess, "NFTMarketplace: Refund to previous bidder failed");
        }

        auction.currentBid = msg.value;
        auction.highestBidder = msg.sender;

        emit BidPlaced(_auctionId, msg.sender, msg.value);
    }

    /**
     * @dev Ends an auction and transfers NFT to the highest bidder.
     * @param _auctionId The ID of the auction to end.
     */
    function endAuction(uint256 _auctionId) public whenNotPaused {
        require(auctions[_auctionId].isActive, "NFTMarketplace: Auction is not active");
        require(block.timestamp >= auctions[_auctionId].endTime, "NFTMarketplace: Auction is not yet ended");

        Auction storage auction = auctions[_auctionId];
        require(auction.seller == msg.sender || auction.highestBidder == msg.sender || owner() == msg.sender, "NFTMarketplace: Only seller, highest bidder or owner can end auction");

        auction.isActive = false;
        tokenIdToAuctionId[auction.tokenId] = 0;

        uint256 tokenId = auction.tokenId;
        address seller = auction.seller;
        address winner = auction.highestBidder;
        uint256 finalPrice = auction.currentBid;

        if (winner != address(0)) {
            // Transfer NFT to winner
            _transfer(seller, winner, tokenId);

            // Calculate platform fee and transfer funds to seller
            uint256 platformFee = (finalPrice * platformFeePercentage) / 100;
            uint256 sellerProceeds = finalPrice - platformFee;

            (bool successSeller, ) = payable(seller).call{value: sellerProceeds}("");
            require(successSeller, "NFTMarketplace: Seller payment failed");
            (bool successPlatform, ) = platformFeeRecipient.call{value: platformFee}("");
            require(successPlatform, "NFTMarketplace: Platform fee payment failed");

            emit AuctionEnded(_auctionId, tokenId, winner, finalPrice);
        } else {
            // No bids, return NFT to seller, revoke approval
            _approve(address(0), tokenId);
            emit AuctionEnded(_auctionId, tokenId, address(0), 0); // Indicate no winner
        }
    }

    /**
     * @dev Retrieves details of a specific NFT listing.
     * @param _listingId The ID of the listing.
     * @return Listing struct containing listing details.
     */
    function getListingDetails(uint256 _listingId) public view returns (Listing memory) {
        return listings[_listingId];
    }

    /**
     * @dev Retrieves details of a specific NFT auction.
     * @param _auctionId The ID of the auction.
     * @return Auction struct containing auction details.
     */
    function getAuctionDetails(uint256 _auctionId) public view returns (Auction memory) {
        return auctions[_auctionId];
    }

    /**
     * @dev Sets the platform fee percentage for marketplace transactions. Only callable by the contract owner.
     * @param _feePercentage The new platform fee percentage (e.g., 2 for 2%).
     */
    function setPlatformFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 100, "NFTMarketplace: Fee percentage cannot exceed 100");
        platformFeePercentage = _feePercentage;
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 contractBalance = balance - msg.value; // Exclude current tx value
        (bool success, ) = platformFeeRecipient.call{value: contractBalance}("");
        require(success, "NFTMarketplace: Withdrawal failed");
    }

    /**
     * @dev Pauses the contract, preventing critical functions from being executed. Only callable by the contract owner.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing functions to be executed again. Only callable by the contract owner.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     * @dev Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev Override supportsInterface to implement ERC721 and ERC721Metadata interfaces.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return interfaceId == type(IERC721Metadata).interfaceId
            || interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    // --- ERC721 Overrides for Enumerable ---
    function tokenByIndex(uint256 index) public view virtual override(ERC721Enumerable) returns (uint256) {
        return super.tokenByIndex(index);
    }

    function totalSupply() public view virtual override(ERC721Enumerable) returns (uint256) {
        return super.totalSupply();
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override(ERC721Enumerable) returns (uint256) {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    // --- ERC721 Overrides for Approvals and Transfers ---
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override whenNotPaused {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override whenNotPaused {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override whenNotPaused {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function approve(address approved, uint256 tokenId) public virtual override whenNotPaused {
        super.approve(approved, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override whenNotPaused {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev Internal function to check if an address is the owner or approved for a token.
     * @param _account The address to check.
     * @param _tokenId The ID of the token.
     * @return bool True if the address is the owner or approved, false otherwise.
     */
    function _isApprovedOrOwner(address _account, uint256 _tokenId) internal view virtual returns (bool) {
        return (ownerOf(_tokenId) == _account || getApproved(_tokenId) == _account || isApprovedForAll(ownerOf(_tokenId), _account));
    }

    /**
     * @dev Allows the owner to burn (destroy) a specific NFT.
     * @param _tokenId The ID of the NFT to burn.
     */
    function burnNFT(uint256 _tokenId) public onlyOwner whenNotPaused {
        require(_exists(_tokenId), "NFTMarketplace: Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "NFTMarketplace: Not token owner");

        // Clean up marketplace and auction mappings if necessary (optional depending on desired behavior)
        if (tokenIdToListingId[_tokenId] != 0) {
            listings[tokenIdToListingId[_tokenId]].isActive = false;
            tokenIdToListingId[_tokenId] = 0;
        }
        if (tokenIdToAuctionId[_tokenId] != 0) {
            auctions[tokenIdToAuctionId[_tokenId]].isActive = false;
            tokenIdToAuctionId[_tokenId] = 0;
        }

        _burn(_tokenId);
    }

    // --- ERC721 Standard Functions (Re-exposed for clarity and potential overrides if needed) ---
    function transferNFT(address _to, uint256 _tokenId) public whenNotPaused {
        safeTransferFrom(msg.sender, _to, _tokenId);
    }

    function approveNFT(address _approved, uint256 _tokenId) public whenNotPaused {
        approve(_approved, _tokenId);
    }

    function getApprovedNFT(uint256 _tokenId) public view returns (address) {
        return getApproved(_tokenId);
    }

    function setApprovalForAllNFT(address _operator, bool _approved) public whenNotPaused {
        setApprovalForAll(_operator, _approved);
    }

    function isApprovedForAllNFT(address _owner, address _operator) public view returns (bool) {
        return isApprovedForAll(_owner, _operator);
    }
}

// --- Helper Library for String Conversions (from OpenZeppelin Contracts - removed from newer versions, so included here) ---
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.5.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```