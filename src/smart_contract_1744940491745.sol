```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI Art Generation & Gamified Auctions
 * @author Bard (AI Assistant)
 * @dev A smart contract for a dynamic NFT marketplace that incorporates AI-assisted art generation
 *      and gamified auction mechanics. This contract features dynamic NFTs that can evolve based
 *      on marketplace activity and external factors, offering a unique and engaging experience.
 *
 * Function Outline:
 *
 * ### NFT Management Functions:
 * 1. `createDynamicNFT(string memory _initialPrompt, string memory _initialMetadataURI)`: Allows authorized minters to create a new Dynamic NFT with an AI prompt and metadata URI.
 * 2. `updateNFTMetadata(uint256 _tokenId, string memory _newMetadataURI)`: Allows the NFT owner to update the metadata URI of their NFT.
 * 3. `burnNFT(uint256 _tokenId)`: Allows the NFT owner to burn their NFT, removing it from circulation.
 * 4. `setAllowedMinter(address _minter, bool _isAllowed)`: Allows the contract owner to manage authorized NFT minters.
 * 5. `isAllowedMinter(address _minter) view returns (bool)`: Checks if an address is an authorized NFT minter.
 * 6. `getNFTOwner(uint256 _tokenId) view returns (address)`: Returns the owner of a specific NFT.
 * 7. `getNFTMetadataURI(uint256 _tokenId) view returns (string memory)`: Returns the metadata URI of a specific NFT.
 * 8. `getTotalNFTSupply() view returns (uint256)`: Returns the total number of NFTs minted.
 *
 * ### Marketplace Functions:
 * 9. `listItemForSale(uint256 _tokenId, uint256 _price)`: Allows NFT owner to list their NFT for sale at a fixed price.
 * 10. `delistItemFromSale(uint256 _tokenId)`: Allows NFT owner to delist their NFT from sale.
 * 11. `purchaseItem(uint256 _tokenId)`: Allows anyone to purchase a listed NFT at its fixed price.
 * 12. `startAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration)`: Allows NFT owner to start a timed auction for their NFT.
 * 13. `bidOnAuction(uint256 _auctionId)`: Allows anyone to place a bid on an active auction.
 * 14. `endAuction(uint256 _auctionId)`: Ends an auction and transfers the NFT to the highest bidder.
 * 15. `cancelAuction(uint256 _auctionId)`: Allows the NFT owner to cancel an auction before it ends (with potential penalty).
 * 16. `getListingPrice(uint256 _tokenId) view returns (uint256)`: Returns the listing price of an NFT if it's listed for sale.
 * 17. `getAuctionDetails(uint256 _auctionId) view returns (Auction memory)`: Returns details of a specific auction.
 * 18. `isNFTListed(uint256 _tokenId) view returns (bool)`: Checks if an NFT is currently listed for sale.
 * 19. `isNFTOnAuction(uint256 _tokenId) view returns (bool)`: Checks if an NFT is currently on auction.
 *
 * ### Dynamic & Gamification Functions:
 * 20. `triggerNFTDynamicEvolution(uint256 _tokenId, string memory _evolutionData)`: Allows an authorized "Evolution Oracle" to trigger a dynamic evolution of an NFT based on external data.
 * 21. `setEvolutionOracle(address _oracle, bool _isOracle)`: Allows the contract owner to manage authorized Evolution Oracles.
 * 22. `isEvolutionOracle(address _oracle) view returns (bool)`: Checks if an address is an authorized Evolution Oracle.
 * 23. `setPlatformFee(uint256 _feePercentage)`: Allows the contract owner to set the platform fee percentage for sales and auctions.
 * 24. `withdrawPlatformFees()`: Allows the contract owner to withdraw accumulated platform fees.
 * 25. `pauseContract()`: Allows the contract owner to pause the contract for maintenance or emergency.
 * 26. `unpauseContract()`: Allows the contract owner to unpause the contract.
 * 27. `isContractPaused() view returns (bool)`: Checks if the contract is currently paused.
 */
contract DynamicNFTMarketplace {
    // --- Structs ---
    struct NFT {
        string initialPrompt;
        string metadataURI;
    }

    struct Listing {
        uint256 price;
        address seller;
        bool isListed;
    }

    struct Auction {
        uint256 tokenId;
        uint256 startingBid;
        uint256 bidIncrement; // Optional: For advanced auction types
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        address seller;
        bool isActive;
    }

    // --- State Variables ---
    mapping(uint256 => NFT) public NFTs; // tokenId => NFT data
    mapping(uint256 => address) public nftOwner; // tokenId => owner address
    mapping(uint256 => Listing) public listings; // tokenId => Listing details
    mapping(uint256 => Auction) public auctions; // auctionId => Auction details
    uint256 public nextAuctionId = 1;
    uint256 public platformFeePercentage = 2; // Default 2% platform fee
    address public contractOwner;
    mapping(address => bool) public allowedMinters;
    mapping(address => bool) public evolutionOracles;
    uint256 public nftSupply = 0;
    bool public paused = false;
    uint256 public platformFeesCollected;

    // --- Events ---
    event NFTCreated(uint256 tokenId, address owner, string initialPrompt, string metadataURI);
    event NFTMetadataUpdated(uint256 tokenId, string newMetadataURI);
    event NFTBurned(uint256 tokenId, address owner);
    event NFTListedForSale(uint256 tokenId, uint256 price, address seller);
    event NFTDelistedFromSale(uint256 tokenId, address seller);
    event ItemPurchased(uint256 tokenId, address buyer, uint256 price, address seller);
    event AuctionStarted(uint256 auctionId, uint256 tokenId, uint256 startingBid, uint256 endTime, address seller);
    event BidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionEnded(uint256 auctionId, uint256 tokenId, address winner, uint256 winningBid);
    event AuctionCancelled(uint256 auctionId, uint256 tokenId, address seller);
    event DynamicNFTEvolutionTriggered(uint256 tokenId, string evolutionData);
    event PlatformFeeUpdated(uint256 newFeePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address admin);
    event ContractPaused();
    event ContractUnpaused();

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function.");
        _;
    }

    modifier onlyAllowedMinter() {
        require(allowedMinters[msg.sender], "Not an allowed minter.");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(nftOwner[_tokenId] == msg.sender, "You are not the NFT owner.");
        _;
    }

    modifier onlyEvolutionOracle() {
        require(evolutionOracles[msg.sender], "Not an authorized evolution oracle.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    // --- Constructor ---
    constructor() {
        contractOwner = msg.sender;
    }

    // --- NFT Management Functions ---
    function createDynamicNFT(string memory _initialPrompt, string memory _initialMetadataURI)
        public
        onlyAllowedMinter
        whenNotPaused
        returns (uint256 tokenId)
    {
        nftSupply++;
        tokenId = nftSupply;
        NFTs[tokenId] = NFT({
            initialPrompt: _initialPrompt,
            metadataURI: _initialMetadataURI
        });
        nftOwner[tokenId] = msg.sender; // Minter becomes the initial owner
        emit NFTCreated(tokenId, msg.sender, _initialPrompt, _initialMetadataURI);
    }

    function updateNFTMetadata(uint256 _tokenId, string memory _newMetadataURI)
        public
        onlyNFTOwner(_tokenId)
        whenNotPaused
    {
        NFTs[_tokenId].metadataURI = _newMetadataURI;
        emit NFTMetadataUpdated(_tokenId, _newMetadataURI);
    }

    function burnNFT(uint256 _tokenId) public onlyNFTOwner(_tokenId) whenNotPaused {
        delete NFTs[_tokenId];
        delete nftOwner[_tokenId];
        delete listings[_tokenId];
        delete auctions[_tokenId]; // If on auction, remove it
        emit NFTBurned(_tokenId, msg.sender);
    }

    function setAllowedMinter(address _minter, bool _isAllowed) public onlyOwner whenNotPaused {
        allowedMinters[_minter] = _isAllowed;
    }

    function isAllowedMinter(address _minter) public view returns (bool) {
        return allowedMinters[_minter];
    }

    function getNFTOwner(uint256 _tokenId) public view returns (address) {
        return nftOwner[_tokenId];
    }

    function getNFTMetadataURI(uint256 _tokenId) public view returns (string memory) {
        return NFTs[_tokenId].metadataURI;
    }

    function getTotalNFTSupply() public view returns (uint256) {
        return nftSupply;
    }


    // --- Marketplace Functions ---
    function listItemForSale(uint256 _tokenId, uint256 _price) public onlyNFTOwner(_tokenId) whenNotPaused {
        require(nftOwner[_tokenId] == msg.sender, "You are not the NFT owner.");
        require(!listings[_tokenId].isListed, "NFT is already listed for sale.");
        require(!auctions[_tokenId].isActive, "NFT is currently on auction.");

        listings[_tokenId] = Listing({
            price: _price,
            seller: msg.sender,
            isListed: true
        });
        emit NFTListedForSale(_tokenId, _price, msg.sender);
    }

    function delistItemFromSale(uint256 _tokenId) public onlyNFTOwner(_tokenId) whenNotPaused {
        require(listings[_tokenId].isListed, "NFT is not listed for sale.");
        delete listings[_tokenId]; // Reset to default struct values (isListed becomes false)
        emit NFTDelistedFromSale(_tokenId, msg.sender);
    }

    function purchaseItem(uint256 _tokenId) public payable whenNotPaused {
        require(listings[_tokenId].isListed, "NFT is not listed for sale.");
        Listing storage listing = listings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds to purchase NFT.");

        uint256 platformFee = (listing.price * platformFeePercentage) / 100;
        uint256 sellerPayout = listing.price - platformFee;

        platformFeesCollected += platformFee;
        nftOwner[_tokenId] = msg.sender; // Transfer ownership
        delete listings[_tokenId]; // Delist after purchase

        (bool successSeller, ) = listing.seller.call{value: sellerPayout}(""); // Send payout to seller
        require(successSeller, "Seller payout failed.");
        (bool successPlatform, ) = contractOwner.call{value: platformFee}(""); // Send fee to platform
        require(successPlatform, "Platform fee transfer failed.");

        emit ItemPurchased(_tokenId, msg.sender, listing.price, listing.seller);
    }

    function startAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration)
        public
        onlyNFTOwner(_tokenId)
        whenNotPaused
    {
        require(!listings[_tokenId].isListed, "NFT is currently listed for sale. Delist it first.");
        require(!auctions[_tokenId].isActive, "NFT is already on auction.");
        require(_auctionDuration > 0, "Auction duration must be greater than 0.");

        auctions[nextAuctionId] = Auction({
            tokenId: _tokenId,
            startingBid: _startingBid,
            bidIncrement: 0, // Optional: Can be added for more complex auctions
            endTime: block.timestamp + _auctionDuration,
            highestBidder: address(0),
            highestBid: 0,
            seller: msg.sender,
            isActive: true
        });

        emit AuctionStarted(nextAuctionId, _tokenId, _startingBid, block.timestamp + _auctionDuration, msg.sender);
        nextAuctionId++;
    }

    function bidOnAuction(uint256 _auctionId) public payable whenNotPaused {
        require(auctions[_auctionId].isActive, "Auction is not active.");
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp < auction.endTime, "Auction has ended.");
        require(msg.sender != auction.seller, "Seller cannot bid on their own auction.");

        require(msg.value > auction.highestBid, "Bid amount is too low.");
        require(msg.value >= (auction.highestBid == 0 ? auction.startingBid : auction.highestBid), "Bid must be at least the current highest bid."); // Simplified bid logic

        if (auction.highestBidder != address(0)) {
            (bool refundSuccess, ) = auction.highestBidder.call{value: auction.highestBid}(""); // Refund previous highest bidder
            require(refundSuccess, "Refund to previous bidder failed.");
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        emit BidPlaced(_auctionId, msg.sender, msg.value);
    }

    function endAuction(uint256 _auctionId) public whenNotPaused {
        require(auctions[_auctionId].isActive, "Auction is not active.");
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp >= auction.endTime, "Auction is not yet ended.");

        auction.isActive = false;

        if (auction.highestBidder != address(0)) {
            uint256 platformFee = (auction.highestBid * platformFeePercentage) / 100;
            uint256 sellerPayout = auction.highestBid - platformFee;

            platformFeesCollected += platformFee;
            nftOwner[auction.tokenId] = auction.highestBidder; // Transfer ownership to highest bidder

            (bool successSeller, ) = auction.seller.call{value: sellerPayout}("");
            require(successSeller, "Seller payout failed.");
            (bool successPlatform, ) = contractOwner.call{value: platformFee}("");
            require(successPlatform, "Platform fee transfer failed.");


            emit AuctionEnded(_auctionId, auction.tokenId, auction.highestBidder, auction.highestBid);
        } else {
            // No bids placed, return NFT to seller
            nftOwner[auction.tokenId] = auction.seller;
            emit AuctionEnded(_auctionId, auction.tokenId, address(0), 0); // Winner is address(0) when no bids
        }
    }

    function cancelAuction(uint256 _auctionId) public onlyNFTOwner(auctions[_auctionId].tokenId) whenNotPaused {
        require(auctions[_auctionId].isActive, "Auction is not active.");
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp < auction.endTime, "Auction cannot be cancelled after it ends.");

        auction.isActive = false;
        nftOwner[auction.tokenId] = auction.seller; // Return NFT to seller
        if (auction.highestBidder != address(0)) {
            (bool refundSuccess, ) = auction.highestBidder.call{value: auction.highestBid}(""); // Refund highest bidder if any
            require(refundSuccess, "Refund to highest bidder failed.");
        }

        emit AuctionCancelled(_auctionId, auction.tokenId, msg.sender);
    }

    function getListingPrice(uint256 _tokenId) public view returns (uint256) {
        if (listings[_tokenId].isListed) {
            return listings[_tokenId].price;
        } else {
            return 0; // Not listed
        }
    }

    function getAuctionDetails(uint256 _auctionId) public view returns (Auction memory) {
        return auctions[_auctionId];
    }

    function isNFTListed(uint256 _tokenId) public view returns (bool) {
        return listings[_tokenId].isListed;
    }

    function isNFTOnAuction(uint256 _tokenId) public view returns (bool) {
        return auctions[_tokenId].isActive && auctions[_tokenId].tokenId == _tokenId; // Check if active and for the right token
    }


    // --- Dynamic & Gamification Functions ---
    function triggerNFTDynamicEvolution(uint256 _tokenId, string memory _evolutionData)
        public
        onlyEvolutionOracle
        whenNotPaused
    {
        // In a real-world scenario, this function would interact with an external oracle or AI service.
        // For this example, we'll simply update the metadata URI based on _evolutionData.
        string memory newMetadataURI = string(abi.encodePacked(NFTs[_tokenId].metadataURI, "?evolved=", _evolutionData)); // Example: Append evolution data to URI
        NFTs[_tokenId].metadataURI = newMetadataURI;
        emit DynamicNFTEvolutionTriggered(_tokenId, _evolutionData);
        emit NFTMetadataUpdated(_tokenId, newMetadataURI); // Also emit metadata update event
    }

    function setEvolutionOracle(address _oracle, bool _isOracle) public onlyOwner whenNotPaused {
        evolutionOracles[_oracle] = _isOracle;
    }

    function isEvolutionOracle(address _oracle) public view returns (bool) {
        return evolutionOracles[_oracle];
    }

    function setPlatformFee(uint256 _feePercentage) public onlyOwner whenNotPaused {
        require(_feePercentage <= 100, "Platform fee percentage cannot exceed 100%.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeUpdated(_feePercentage);
    }

    function withdrawPlatformFees() public onlyOwner whenNotPaused {
        uint256 amountToWithdraw = platformFeesCollected;
        platformFeesCollected = 0; // Reset collected fees after withdrawal
        (bool success, ) = contractOwner.call{value: amountToWithdraw}("");
        require(success, "Platform fee withdrawal failed.");
        emit PlatformFeesWithdrawn(amountToWithdraw, contractOwner);
    }

    // --- Pause/Unpause Functions ---
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    function isContractPaused() public view returns (bool) {
        return paused;
    }

    // --- Fallback function to receive ETH ---
    receive() external payable {}
}
```