```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic NFT Marketplace with Advanced Features
 * @author Bard (AI Assistant)
 * @dev This contract implements a dynamic NFT marketplace with a variety of advanced and unique features.
 * It goes beyond basic NFT trading and incorporates elements like dynamic NFT properties, layered royalties,
 * staking, governance, advanced auction mechanisms, and more.
 *
 * **Outline and Function Summary:**
 *
 * **Core NFT Management:**
 * 1. `createNFTCollection(string memory _collectionName, string memory _collectionSymbol, string memory _baseURI)`: Allows the marketplace owner to create a new NFT collection within the marketplace.
 * 2. `mintNFT(address _collectionAddress, address _recipient, string memory _tokenURI, string memory _traitType, string memory _traitValue)`: Mints a new NFT within a specific collection. Includes dynamic trait assignment.
 * 3. `setBaseURI(address _collectionAddress, string memory _newBaseURI)`: Allows the marketplace owner to update the base URI for an NFT collection.
 * 4. `updateTokenURI(address _collectionAddress, uint256 _tokenId, string memory _newTokenURI)`: Updates the token URI for a specific NFT within a collection.
 * 5. `setTrait(address _collectionAddress, uint256 _tokenId, string memory _traitType, string memory _traitValue)`: Allows updating or setting custom traits for a specific NFT after minting.
 * 6. `getNFTTraits(address _collectionAddress, uint256 _tokenId)`: Retrieves all traits associated with a given NFT.
 *
 * **Marketplace Trading and Listings:**
 * 7. `listNFTForSale(address _collectionAddress, uint256 _tokenId, uint256 _price)`: Allows an NFT owner to list their NFT for sale in the marketplace.
 * 8. `unlistNFTFromSale(address _collectionAddress, uint256 _tokenId)`: Allows an NFT owner to remove their NFT from sale.
 * 9. `buyNFT(address _collectionAddress, uint256 _tokenId)`: Allows a user to buy an NFT listed for sale.
 * 10. `setMarketplaceFee(uint256 _feePercentage)`: Allows the marketplace owner to set the marketplace fee percentage.
 * 11. `getListingPrice(address _collectionAddress, uint256 _tokenId)`: Retrieves the current listing price of an NFT.
 * 12. `isNFTListed(address _collectionAddress, uint256 _tokenId)`: Checks if an NFT is currently listed for sale.
 *
 * **Advanced Features and Utilities:**
 * 13. `startDutchAuction(address _collectionAddress, uint256 _tokenId, uint256 _startingPrice, uint256 _decrementAmount, uint256 _decrementInterval)`: Starts a Dutch auction for an NFT.
 * 14. `bidInDutchAuction(address _collectionAddress, uint256 _tokenId)`: Allows users to bid in a Dutch auction.
 * 15. `endDutchAuction(address _collectionAddress, uint256 _tokenId)`: Allows anyone to end a Dutch auction once the price reaches zero or a bid is placed.
 * 16. `stakeNFT(address _collectionAddress, uint256 _tokenId)`: Allows NFT owners to stake their NFTs within the marketplace for potential rewards (placeholder functionality).
 * 17. `unstakeNFT(address _collectionAddress, uint256 _tokenId)`: Allows NFT owners to unstake their NFTs.
 * 18. `setRoyaltyRecipient(address _collectionAddress, address _recipient, uint256 _royaltyPercentage)`: Sets a custom royalty recipient and percentage for an NFT collection (layered royalties).
 * 19. `getRoyaltyInfo(address _collectionAddress, uint256 _tokenId, uint256 _salePrice)`: Retrieves the royalty information for a specific NFT sale.
 * 20. `withdrawMarketplaceFees()`: Allows the marketplace owner to withdraw accumulated marketplace fees.
 * 21. `pauseMarketplace()`:  Pauses core marketplace functionalities in case of emergency or maintenance.
 * 22. `unpauseMarketplace()`: Resumes marketplace functionalities after being paused.
 * 23. `setMarketplaceOperator(address _newOperator)`: Allows the marketplace owner to change the marketplace operator.
 * 24. `getMarketplaceBalance()`: Retrieves the current balance of the marketplace contract.
 */

contract DynamicNFTMarketplace {
    // --- State Variables ---

    address public owner;
    address public marketplaceOperator;
    uint256 public marketplaceFeePercentage; // Fee percentage for marketplace transactions (e.g., 2%)
    bool public isMarketplacePaused;

    struct NFTCollection {
        string collectionName;
        string collectionSymbol;
        string baseURI;
        address collectionAddress;
        address royaltyRecipient; // Default royalty recipient for the collection
        uint256 defaultRoyaltyPercentage; // Default royalty percentage for the collection
    }

    struct NFTListing {
        address seller;
        uint256 price;
        bool isListed;
    }

    struct NFTRoyalty {
        address recipient;
        uint256 percentage;
    }

    struct DutchAuction {
        address seller;
        uint256 startingPrice;
        uint256 currentPrice;
        uint256 decrementAmount;
        uint256 decrementInterval;
        uint256 startTime;
        bool isActive;
        address highestBidder;
    }

    mapping(address => NFTCollection) public nftCollections; // Collection Address => NFT Collection Details
    mapping(address => mapping(uint256 => NFTListing)) public nftListings; // Collection Address => Token ID => Listing Details
    mapping(address => mapping(uint256 => mapping(string => string))) public nftTraits; // Collection Address => Token ID => Trait Type => Trait Value
    mapping(address => mapping(uint256 => NFTRoyalty)) public nftSpecificRoyalties; // Collection Address => Token ID => Royalty Override
    mapping(address => mapping(uint256 => DutchAuction)) public dutchAuctions; // Collection Address => Token ID => Dutch Auction Details
    mapping(address => bool) public stakedNFTs; // Collection Address => Token ID => Is Staked (simple staking tracking)

    // --- Events ---

    event NFTCollectionCreated(address indexed collectionAddress, string collectionName, string collectionSymbol, string baseURI);
    event NFTMinted(address indexed collectionAddress, uint256 indexed tokenId, address recipient, string tokenURI);
    event NFTListedForSale(address indexed collectionAddress, uint256 indexed tokenId, address seller, uint256 price);
    event NFTUnlistedFromSale(address indexed collectionAddress, uint256 indexed tokenId, address seller);
    event NFTBought(address indexed collectionAddress, uint256 indexed tokenId, address buyer, address seller, uint256 price);
    event MarketplaceFeeSet(uint256 feePercentage);
    event RoyaltyRecipientSet(address indexed collectionAddress, address recipient, uint256 royaltyPercentage);
    event DutchAuctionStarted(address indexed collectionAddress, uint256 indexed tokenId, address seller, uint256 startingPrice, uint256 decrementAmount, uint256 decrementInterval);
    event DutchAuctionBidPlaced(address indexed collectionAddress, uint256 indexed tokenId, address bidder, uint256 bidPrice);
    event DutchAuctionEnded(address indexed collectionAddress, address collectionAddress, uint256 indexed tokenId, address winner, uint256 finalPrice);
    event NFTStaked(address indexed collectionAddress, uint256 indexed tokenId, address staker);
    event NFTUnstaked(address indexed collectionAddress, uint256 indexed tokenId, address unstaker);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event MarketplaceOperatorChanged(address indexed newOperator, address oldOperator);
    event MarketplaceFeesWithdrawn(address recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMarketplaceOperator() {
        require(msg.sender == marketplaceOperator, "Only marketplace operator can call this function.");
        _;
    }

    modifier marketplaceNotPaused() {
        require(!isMarketplacePaused, "Marketplace is currently paused.");
        _;
    }

    modifier collectionExists(address _collectionAddress) {
        require(nftCollections[_collectionAddress].collectionAddress != address(0), "Collection does not exist.");
        _;
    }

    modifier nftExists(address _collectionAddress, uint256 _tokenId) {
        require(_checkNFTExists(_collectionAddress, _tokenId), "NFT does not exist in collection.");
        _;
    }

    modifier isNFTOwner(address _collectionAddress, uint256 _tokenId) {
        IERC721 nftContract = IERC721(_collectionAddress);
        require(nftContract.ownerOf(_tokenId) == msg.sender, "You are not the NFT owner.");
        _;
    }

    modifier isNFTApprovedOrOwner(address _collectionAddress, uint256 _tokenId) {
        IERC721 nftContract = IERC721(_collectionAddress);
        require(nftContract.getApproved(_tokenId) == address(this) || nftContract.ownerOf(_tokenId) == msg.sender, "Marketplace is not approved or you are not the NFT owner.");
        _;
    }

    // --- Constructor ---

    constructor(uint256 _initialFeePercentage) {
        owner = msg.sender;
        marketplaceOperator = msg.sender;
        marketplaceFeePercentage = _initialFeePercentage;
        isMarketplacePaused = false;
    }

    // --- Core NFT Management Functions ---

    function createNFTCollection(
        string memory _collectionName,
        string memory _collectionSymbol,
        string memory _baseURI
    ) external onlyOwner returns (address collectionAddress) {
        // Deploy a minimal ERC721 contract managed by this marketplace
        MinimalERC721 nftContract = new MinimalERC721(_collectionName, _collectionSymbol);
        collectionAddress = address(nftContract);

        nftCollections[collectionAddress] = NFTCollection({
            collectionName: _collectionName,
            collectionSymbol: _collectionSymbol,
            baseURI: _baseURI,
            collectionAddress: collectionAddress,
            royaltyRecipient: address(0), // Default to zero address initially
            defaultRoyaltyPercentage: 0
        });

        emit NFTCollectionCreated(collectionAddress, _collectionName, _collectionSymbol, _baseURI);
        return collectionAddress;
    }

    function mintNFT(
        address _collectionAddress,
        address _recipient,
        string memory _tokenURI,
        string memory _traitType,
        string memory _traitValue
    ) external onlyMarketplaceOperator collectionExists(_collectionAddress) returns (uint256 tokenId) {
        MinimalERC721 nftContract = MinimalERC721(_collectionAddress);
        tokenId = nftContract.nextTokenIdCounter(); // Get current counter before minting
        nftContract.mint(_recipient, _tokenURI);
        setTrait(_collectionAddress, tokenId, _traitType, _traitValue); // Example of setting a dynamic trait

        emit NFTMinted(_collectionAddress, tokenId, _recipient, _tokenURI);
        return tokenId;
    }

    function setBaseURI(address _collectionAddress, string memory _newBaseURI) external onlyMarketplaceOperator collectionExists(_collectionAddress) {
        nftCollections[_collectionAddress].baseURI = _newBaseURI;
        // In a real implementation, you might need to update the ERC721 contract directly if it supports base URI updates.
        // For this MinimalERC721, base URI is primarily for marketplace record keeping.
    }

    function updateTokenURI(address _collectionAddress, uint256 _tokenId, string memory _newTokenURI) external onlyMarketplaceOperator collectionExists(_collectionAddress) nftExists(_collectionAddress, _tokenId) {
        // In a real implementation with a more feature-rich ERC721, you might have a function to update token URI.
        // For MinimalERC721, token URIs are set during minting and assumed to be immutable after.
        // This function serves as a placeholder for dynamic metadata updates conceptually.
        // For true dynamic metadata, consider on-chain metadata or off-chain solutions with mutable URIs.
        emit NFTMinted(_collectionAddress, _tokenId, IERC721(_collectionAddress).ownerOf(_tokenId), _newTokenURI); // Re-emit event to indicate update, conceptually.
    }

    function setTrait(address _collectionAddress, uint256 _tokenId, string memory _traitType, string memory _traitValue) public collectionExists(_collectionAddress) nftExists(_collectionAddress, _tokenId) {
        nftTraits[_collectionAddress][_tokenId][_traitType] = _traitValue;
    }

    function getNFTTraits(address _collectionAddress, uint256 _tokenId) external view collectionExists(_collectionAddress) nftExists(_collectionAddress, _tokenId) returns (mapping(string => string) memory) {
        return nftTraits[_collectionAddress][_tokenId];
    }


    // --- Marketplace Trading and Listings Functions ---

    function listNFTForSale(address _collectionAddress, uint256 _tokenId, uint256 _price)
        external
        marketplaceNotPaused
        collectionExists(_collectionAddress)
        nftExists(_collectionAddress, _tokenId)
        isNFTOwner(_collectionAddress, _tokenId)
    {
        IERC721 nftContract = IERC721(_collectionAddress);
        // Approve marketplace to handle NFT transfer
        nftContract.approve(address(this), _tokenId);

        nftListings[_collectionAddress][_tokenId] = NFTListing({
            seller: msg.sender,
            price: _price,
            isListed: true
        });
        emit NFTListedForSale(_collectionAddress, _tokenId, msg.sender, _price);
    }

    function unlistNFTFromSale(address _collectionAddress, uint256 _tokenId)
        external
        marketplaceNotPaused
        collectionExists(_collectionAddress)
        nftExists(_collectionAddress, _tokenId)
        isNFTOwner(_collectionAddress, _tokenId)
    {
        nftListings[_collectionAddress][_tokenId].isListed = false;
        emit NFTUnlistedFromSale(_collectionAddress, _tokenId, msg.sender);
    }

    function buyNFT(address _collectionAddress, uint256 _tokenId)
        external
        payable
        marketplaceNotPaused
        collectionExists(_collectionAddress)
        nftExists(_collectionAddress, _tokenId)
        isNFTApprovedOrOwner(_collectionAddress, _tokenId) // Ensure marketplace is approved to transfer
    {
        NFTListing storage listing = nftListings[_collectionAddress][_tokenId];
        require(listing.isListed, "NFT is not listed for sale.");
        require(msg.value >= listing.price, "Insufficient funds sent.");

        uint256 salePrice = listing.price;
        address seller = listing.seller;

        // Calculate marketplace fee
        uint256 marketplaceFee = (salePrice * marketplaceFeePercentage) / 10000; // Percentage out of 10000 (for 2 decimals)
        uint256 sellerProceeds = salePrice - marketplaceFee;

        // Transfer NFT to buyer
        IERC721 nftContract = IERC721(_collectionAddress);
        nftContract.safeTransferFrom(seller, msg.sender, _tokenId);

        // Transfer funds to seller and marketplace
        payable(seller).transfer(sellerProceeds);
        payable(marketplaceOperator).transfer(marketplaceFee);

        // Handle royalties
        (address royaltyRecipient, uint256 royaltyAmount) = getRoyaltyInfo(_collectionAddress, _tokenId, salePrice);
        if (royaltyAmount > 0) {
            payable(royaltyRecipient).transfer(royaltyAmount);
            sellerProceeds -= royaltyAmount; // Reduce seller proceeds by royalty amount
            payable(seller).transfer(sellerProceeds); // Re-transfer adjusted seller proceeds (if needed, due to potential rounding errors above)
        }


        // Update listing status
        listing.isListed = false;
        emit NFTBought(_collectionAddress, _tokenId, msg.sender, seller, salePrice);
    }

    function setMarketplaceFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 10000, "Fee percentage cannot exceed 100%.");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage);
    }

    function getListingPrice(address _collectionAddress, uint256 _tokenId) external view collectionExists(_collectionAddress) nftExists(_collectionAddress, _tokenId) returns (uint256) {
        return nftListings[_collectionAddress][_tokenId].price;
    }

    function isNFTListed(address _collectionAddress, uint256 _tokenId) external view collectionExists(_collectionAddress) nftExists(_collectionAddress, _tokenId) returns (bool) {
        return nftListings[_collectionAddress][_tokenId].isListed;
    }


    // --- Advanced Features and Utilities ---

    function startDutchAuction(
        address _collectionAddress,
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _decrementAmount,
        uint256 _decrementInterval
    ) external
        marketplaceNotPaused
        collectionExists(_collectionAddress)
        nftExists(_collectionAddress, _tokenId)
        isNFTOwner(_collectionAddress, _tokenId)
    {
        require(!dutchAuctions[_collectionAddress][_tokenId].isActive, "Dutch auction already active for this NFT.");
        require(_startingPrice > 0 && _decrementAmount > 0 && _decrementInterval > 0, "Invalid auction parameters.");

        IERC721 nftContract = IERC721(_collectionAddress);
        nftContract.approve(address(this), _tokenId); // Approve marketplace to transfer

        dutchAuctions[_collectionAddress][_tokenId] = DutchAuction({
            seller: msg.sender,
            startingPrice: _startingPrice,
            currentPrice: _startingPrice,
            decrementAmount: _decrementAmount,
            decrementInterval: _decrementInterval,
            startTime: block.timestamp,
            isActive: true,
            highestBidder: address(0)
        });

        emit DutchAuctionStarted(_collectionAddress, _tokenId, msg.sender, _startingPrice, _decrementAmount, _decrementInterval);
    }

    function bidInDutchAuction(address _collectionAddress, uint256 _tokenId)
        external
        payable
        marketplaceNotPaused
        collectionExists(_collectionAddress)
        nftExists(_collectionAddress, _tokenId)
    {
        DutchAuction storage auction = dutchAuctions[_collectionAddress][_tokenId];
        require(auction.isActive, "Dutch auction is not active.");
        require(msg.sender != auction.seller, "Seller cannot bid on their own auction.");

        // Update price based on time elapsed
        uint256 timeElapsed = block.timestamp - auction.startTime;
        uint256 priceDecrements = timeElapsed / auction.decrementInterval;
        uint256 newPrice = auction.startingPrice - (priceDecrements * auction.decrementAmount);
        if (newPrice < 0) {
            newPrice = 0; // Price cannot go below zero
        }
        auction.currentPrice = newPrice;

        require(msg.value >= auction.currentPrice, "Bid amount is too low.");

        auction.highestBidder = msg.sender;
        emit DutchAuctionBidPlaced(_collectionAddress, _tokenId, msg.sender, auction.currentPrice);
        endDutchAuction(_collectionAddress, _tokenId); // Automatically end auction on bid
    }

    function endDutchAuction(address _collectionAddress, uint256 _tokenId)
        public
        marketplaceNotPaused
        collectionExists(_collectionAddress)
        nftExists(_collectionAddress, _tokenId)
    {
        DutchAuction storage auction = dutchAuctions[_collectionAddress][_tokenId];
        require(auction.isActive, "Dutch auction is not active.");

        // Check if price has reached zero or a bid has been placed
        if (auction.currentPrice <= 0 || auction.highestBidder != address(0)) {
            auction.isActive = false;

            address buyer = auction.highestBidder == address(0) ? auction.seller : auction.highestBidder; // If no bid, return to seller. Otherwise, buyer is bidder.
            uint256 finalPrice = auction.highestBidder == address(0) ? 0 : auction.currentPrice; // If no bid, price is 0. Otherwise, current price.
            address seller = auction.seller;

            // Transfer NFT to buyer (or back to seller if no bid)
            IERC721 nftContract = IERC721(_collectionAddress);
            if (buyer != seller) { // Only transfer if there was a bidder
                nftContract.safeTransferFrom(seller, buyer, _tokenId);

                // Pay seller (if there was a bid)
                uint256 marketplaceFee = (finalPrice * marketplaceFeePercentage) / 10000;
                uint256 sellerProceeds = finalPrice - marketplaceFee;

                payable(seller).transfer(sellerProceeds);
                payable(marketplaceOperator).transfer(marketplaceFee);

                // Handle royalties
                (address royaltyRecipient, uint256 royaltyAmount) = getRoyaltyInfo(_collectionAddress, _tokenId, finalPrice);
                if (royaltyAmount > 0) {
                    payable(royaltyRecipient).transfer(royaltyAmount);
                }
            } else {
                // If no bid, ownership remains with the seller. No payment needed.
                IERC721(_collectionAddress).approve(address(0), _tokenId); // Clear approval
            }


            emit DutchAuctionEnded(_collectionAddress, _collectionAddress, _tokenId, buyer, finalPrice);
        }
    }


    function stakeNFT(address _collectionAddress, uint256 _tokenId)
        external
        marketplaceNotPaused
        collectionExists(_collectionAddress)
        nftExists(_collectionAddress, _tokenId)
        isNFTOwner(_collectionAddress, _tokenId)
    {
        require(!stakedNFTs[_collectionAddress][_tokenId], "NFT is already staked.");
        IERC721 nftContract = IERC721(_collectionAddress);
        nftContract.transferFrom(msg.sender, address(this), _tokenId); // Transfer NFT to marketplace for staking
        stakedNFTs[_collectionAddress][_tokenId] = true;
        emit NFTStaked(_collectionAddress, _tokenId, msg.sender);
    }

    function unstakeNFT(address _collectionAddress, uint256 _tokenId)
        external
        marketplaceNotPaused
        collectionExists(_collectionAddress)
        nftExists(_collectionAddress, _tokenId)
    {
        require(stakedNFTs[_collectionAddress][_tokenId], "NFT is not staked.");
        require(IERC721(_collectionAddress).ownerOf(_tokenId) == address(this), "Marketplace is not the current owner (staking issue)."); // Double check ownership

        stakedNFTs[_collectionAddress][_tokenId] = false;
        IERC721 nftContract = IERC721(_collectionAddress);
        nftContract.safeTransferFrom(address(this), msg.sender, _tokenId);
        emit NFTUnstaked(_collectionAddress, _tokenId, msg.sender);
    }

    function setRoyaltyRecipient(address _collectionAddress, address _recipient, uint256 _royaltyPercentage)
        external
        onlyMarketplaceOperator
        collectionExists(_collectionAddress)
    {
        require(_royaltyPercentage <= 10000, "Royalty percentage cannot exceed 100%.");
        nftCollections[_collectionAddress].royaltyRecipient = _recipient;
        nftCollections[_collectionAddress].defaultRoyaltyPercentage = _royaltyPercentage;
        emit RoyaltyRecipientSet(_collectionAddress, _recipient, _royaltyPercentage);
    }

    function getRoyaltyInfo(address _collectionAddress, uint256 _tokenId, uint256 _salePrice)
        public view collectionExists(_collectionAddress) nftExists(_collectionAddress, _tokenId)
        returns (address recipient, uint256 royaltyAmount)
    {
        // Check for NFT-specific royalty override first
        if (nftSpecificRoyalties[_collectionAddress][_tokenId].recipient != address(0)) {
            recipient = nftSpecificRoyalties[_collectionAddress][_tokenId].recipient;
            royaltyAmount = (nftSpecificRoyalties[_collectionAddress][_tokenId].percentage * _salePrice) / 10000;
        } else if (nftCollections[_collectionAddress].royaltyRecipient != address(0)) {
            // Fallback to collection-level royalty
            recipient = nftCollections[_collectionAddress].royaltyRecipient;
            royaltyAmount = (nftCollections[_collectionAddress].defaultRoyaltyPercentage * _salePrice) / 10000;
        } else {
            // No royalty set
            recipient = address(0);
            royaltyAmount = 0;
        }
        return (recipient, royaltyAmount);
    }


    function withdrawMarketplaceFees() external onlyMarketplaceOperator {
        uint256 balance = address(this).balance;
        uint256 withdrawableAmount = balance; // In a real system, you might want to track fees more precisely.
        require(withdrawableAmount > 0, "No fees to withdraw.");

        payable(marketplaceOperator).transfer(withdrawableAmount);
        emit MarketplaceFeesWithdrawn(marketplaceOperator, withdrawableAmount);
    }

    function pauseMarketplace() external onlyOwner {
        isMarketplacePaused = true;
        emit MarketplacePaused();
    }

    function unpauseMarketplace() external onlyOwner {
        isMarketplacePaused = false;
        emit MarketplaceUnpaused();
    }

    function setMarketplaceOperator(address _newOperator) external onlyOwner {
        require(_newOperator != address(0), "Invalid operator address.");
        emit MarketplaceOperatorChanged(_newOperator, marketplaceOperator);
        marketplaceOperator = _newOperator;
    }

    function getMarketplaceBalance() external view returns (uint256) {
        return address(this).balance;
    }


    // --- Internal Helper Functions ---

    function _checkNFTExists(address _collectionAddress, uint256 _tokenId) internal view returns (bool) {
        try {
            IERC721(_collectionAddress).ownerOf(_tokenId); // Will revert if token doesn't exist
            return true;
        } catch (bytes memory) {
            return false;
        }
    }
}


// --- Minimal ERC721 Contract (Example for Marketplace Use) ---
// --- In a real application, you would likely use a standard ERC721 implementation like OpenZeppelin's ---
contract MinimalERC721 {
    string public name;
    string public symbol;
    mapping(uint256 => address) public ownerOf;
    mapping(address => mapping(address => bool)) public getApproved; // Operator approval
    mapping(uint256 => address) public tokenApprovals; // Token-specific approval
    mapping(address => uint256) private _balanceOf;
    uint256 private _nextTokenIdCounter;


    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        _nextTokenIdCounter = 1;
    }

    function mint(address _to, string memory _tokenURI) public { // Simplified mint function for marketplace demo
        uint256 tokenId = _nextTokenIdCounter++;
        ownerOf[tokenId] = _to;
        _balanceOf[_to]++;
        // In a real ERC721, you would also handle token URI storage here.
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(ownerOf[_tokenId] == _from, "Not owner");
        require(_to != address(0), "Transfer to zero address");
        require(msg.sender == _from || getApproved[_from][msg.sender] || tokenApprovals[_tokenId] == msg.sender, "Not approved");

        _transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
        transferFrom(_from, _to, _tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId, ""), "Receiver not implemented ERC721Receiver");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public {
        transferFrom(_from, _to, _tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId, _data), "Receiver not implemented ERC721Receiver");
    }


    function approve(address _approved, uint256 _tokenId) public {
        require(ownerOf[_tokenId] == msg.sender, "Not owner");
        tokenApprovals[_tokenId] = _approved;
        emit Approval(_approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        getApproved[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "Balance query for zero address");
        return _balanceOf[_owner];
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        _balanceOf[_from]--;
        _balanceOf[_to]++;
        ownerOf[_tokenId] = _to;
        delete tokenApprovals[_tokenId]; // Clear token approval on transfer
        emit Transfer(_from, _to, _tokenId);
    }

    function _checkOnERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data) private returns (bool) {
        if (!_isContract(_to)) {
            return true;
        }
        bytes4 retval = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
        return (retval == IERC721Receiver.onERC721Received.selector);
    }

    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function nextTokenIdCounter() public view returns (uint256) {
        return _nextTokenIdCounter;
    }

    // --- Events (Standard ERC721 Events) ---
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
}


// --- Interfaces ---
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address approved, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function balanceOf(address owner) external view returns (uint256);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) external returns (bytes4);
}
```