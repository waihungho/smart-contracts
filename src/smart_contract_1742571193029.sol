```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with Advanced Features
 * @author Bard (AI Assistant)
 * @dev A sophisticated NFT marketplace contract showcasing dynamic NFTs,
 *      advanced trading mechanisms, staking, renting, governance, and more.
 *      This contract is designed to be unique and explore cutting-edge concepts
 *      beyond typical marketplace functionalities.

 * **Outline:**
 * 1. **Core NFT Functionality:**
 *    - Minting Dynamic NFTs with mutable metadata.
 *    - NFT Metadata Update Mechanism based on on-chain/off-chain events.
 *    - Batch Minting and Transferring.
 * 2. **Advanced Marketplace Features:**
 *    - Order Book System: Limit orders for buying and selling NFTs.
 *    - Dutch Auction Mechanism for NFT Sales.
 *    - Escrow Service for Secure NFT Trading.
 *    - Conditional Sales: NFTs sold only if certain conditions are met (e.g., oracle data).
 *    - NFT Bundling: Selling multiple NFTs as a single bundle.
 * 3. **NFT Utility and Engagement:**
 *    - NFT Staking for Platform Tokens.
 *    - NFT Renting/Leasing Mechanism.
 *    - Dynamic Royalty System based on NFT attributes.
 *    - Community Governance: NFT Holders voting on platform features/parameters.
 * 4. **Enhanced Security and Management:**
 *    - Pause/Unpause Functionality for Emergency Control.
 *    - Fee Management and Platform Revenue Distribution.
 *    - Dispute Resolution Mechanism for Marketplace Transactions.
 *    - Whitelist/Blacklist Functionality for Users/NFTs.
 * 5. **Dynamic and Creative Elements:**
 *    - NFT Evolution: NFTs changing appearance/attributes over time or based on user interaction.
 *    - Mystery Box Sales: Selling NFTs with randomized rarity revealed after purchase.
 *    - On-chain Achievements: NFTs unlocking new abilities or features based on on-chain activities.

 * **Function Summary:**
 * 1. `mintDynamicNFT(address _to, string memory _baseURI, string memory _initialMetadata)`: Mints a new dynamic NFT with mutable metadata.
 * 2. `updateNFTMetadata(uint256 _tokenId, string memory _newMetadata)`: Updates the metadata URI of a specific NFT.
 * 3. `batchMintNFTs(address _to, string memory _baseURI, uint256 _count)`: Mints multiple NFTs in a single transaction.
 * 4. `createLimitOrder(uint256 _tokenId, uint256 _price)`: Creates a limit order to sell an NFT at a specified price.
 * 5. `cancelLimitOrder(uint256 _orderId)`: Cancels an existing limit order.
 * 6. `fillLimitOrder(uint256 _orderId)`: Fills a limit order to buy an NFT.
 * 7. `createDutchAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _decrementAmount, uint256 _decrementInterval)`: Starts a Dutch Auction for an NFT.
 * 8. `bidOnDutchAuction(uint256 _auctionId)`: Allows users to bid on a Dutch Auction.
 * 9. `endDutchAuction(uint256 _auctionId)`: Ends a Dutch Auction and transfers NFT to the highest bidder.
 * 10. `createEscrowTransaction(uint256 _tokenId, address _buyer, uint256 _price)`: Creates an escrow transaction for secure NFT trading.
 * 11. `buyerConfirmEscrow(uint256 _escrowId)`: Buyer confirms receipt of NFT in escrow.
 * 12. `sellerConfirmEscrow(uint256 _escrowId)`: Seller confirms payment received in escrow.
 * 13. `cancelEscrowTransaction(uint256 _escrowId)`: Cancels an escrow transaction.
 * 14. `createConditionalSale(uint256 _tokenId, uint256 _price, address _conditionOracle, bytes memory _conditionData)`: Creates a conditional sale where NFT is sold only if a condition is met.
 * 15. `fulfillConditionalSale(uint256 _saleId)`: Fulfills a conditional sale if the condition is met (oracle data check).
 * 16. `createNFTBundle(uint256[] memory _tokenIds, uint256 _bundlePrice)`: Creates a bundle of NFTs for sale.
 * 17. `buyNFTBundle(uint256 _bundleId)`: Buys an NFT bundle.
 * 18. `stakeNFT(uint256 _tokenId)`: Stakes an NFT to earn platform tokens.
 * 19. `unstakeNFT(uint256 _tokenId)`: Unstakes an NFT.
 * 20. `rentNFT(uint256 _tokenId, address _renter, uint256 _rentDuration)`: Allows NFT owners to rent out their NFTs.
 * 21. `endRent(uint256 _rentId)`: Ends an NFT rental agreement.
 * 22. `createGovernanceProposal(string memory _title, string memory _description, bytes memory _calldata)`: Allows NFT holders to create governance proposals.
 * 23. `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows NFT holders to vote on governance proposals.
 * 24. `executeProposal(uint256 _proposalId)`: Executes a passed governance proposal.
 * 25. `setPause(bool _paused)`: Pauses or unpauses the marketplace contract.
 * 26. `setPlatformFee(uint256 _feePercentage)`: Sets the platform fee percentage for marketplace transactions.
 * 27. `resolveDispute(uint256 _transactionId, address _winner)`: Admin function to resolve disputes in marketplace transactions.
 * 28. `addToWhitelist(address _user)`: Adds an address to the whitelist.
 * 29. `removeFromWhitelist(address _user)`: Removes an address from the whitelist.
 * 30. `addToBlacklistNFT(uint256 _tokenId)`: Blacklists a specific NFT.
 * 31. `removeFromBlacklistNFT(uint256 _tokenId)`: Removes an NFT from the blacklist.
 * 32. `evolveNFT(uint256 _tokenId)`: Triggers an evolution event for a dynamic NFT (example of dynamic feature).
 * 33. `openMysteryBox(uint256 _boxId)`: Opens a mystery box NFT to reveal the contained NFT.
 * 34. `unlockAchievement(uint256 _tokenId, string memory _achievementName)`: Unlocks an on-chain achievement for an NFT.
 */

contract DynamicNFTMarketplace {
    // --- State Variables ---
    string public name = "DynamicNFTMarketplace";
    string public symbol = "DNFTM";
    uint256 public totalSupply;
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => bool)) public getApproved;
    mapping(uint256 => address) public tokenApprovals;
    mapping(uint256 => string) public tokenMetadataURIs;
    address public platformOwner;
    uint256 public platformFeePercentage = 2; // 2% platform fee
    bool public paused = false;

    // Limit Order State
    uint256 public nextOrderId = 1;
    struct LimitOrder {
        uint256 orderId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => LimitOrder) public limitOrders;

    // Dutch Auction State
    uint256 public nextAuctionId = 1;
    struct DutchAuction {
        uint256 auctionId;
        uint256 tokenId;
        address seller;
        uint256 startingPrice;
        uint256 currentPrice;
        uint256 decrementAmount;
        uint256 decrementInterval;
        uint256 startTime;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool isActive;
    }
    mapping(uint256 => DutchAuction) public dutchAuctions;

    // Escrow State
    uint256 public nextEscrowId = 1;
    struct EscrowTransaction {
        uint256 escrowId;
        uint256 tokenId;
        address seller;
        address buyer;
        uint256 price;
        bool sellerConfirmed;
        bool buyerConfirmed;
        bool isActive;
    }
    mapping(uint256 => EscrowTransaction) public escrowTransactions;

    // Conditional Sale State (Example with Oracle - Placeholder)
    uint256 public nextSaleId = 1;
    struct ConditionalSale {
        uint256 saleId;
        uint256 tokenId;
        address seller;
        uint256 price;
        address conditionOracle; // Placeholder - In real world, interface to oracle
        bytes conditionData;     // Placeholder - Data for oracle condition
        bool conditionMet;       // Placeholder - Oracle would update this
        bool isActive;
    }
    mapping(uint256 => ConditionalSale) public conditionalSales;

    // NFT Bundle State
    uint256 public nextBundleId = 1;
    struct NFTBundle {
        uint256 bundleId;
        uint256[] tokenIds;
        uint256 bundlePrice;
        address seller;
        bool isActive;
    }
    mapping(uint256 => NFTBundle) public nftBundles;

    // Staking State (Simplified Example)
    mapping(uint256 => bool) public isNFTStaked;
    mapping(address => uint256) public stakingBalance; // Platform token balance example

    // Renting State (Simplified Example)
    uint256 public nextRentId = 1;
    struct NFTRent {
        uint256 rentId;
        uint256 tokenId;
        address owner;
        address renter;
        uint256 rentDuration; // In blocks/seconds - Placeholder
        uint256 rentStartTime;
        bool isActive;
    }
    mapping(uint256 => NFTRent) public nftRents;
    mapping(uint256 => uint256) public nftRentId; // TokenId to RentId mapping

    // Governance State (Basic Example)
    uint256 public nextProposalId = 1;
    struct GovernanceProposal {
        uint256 proposalId;
        string title;
        string description;
        bytes calldata; // Function call data for proposal execution
        uint256 yesVotes;
        uint256 noVotes;
        uint256 quorum; // Minimum votes needed
        uint256 votingEndTime;
        bool executed;
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public proposalVotingDuration = 7 days;
    uint256 public proposalQuorumPercentage = 5; // 5% of total supply quorum

    // Whitelist/Blacklist
    mapping(address => bool) public whitelist;
    mapping(uint256 => bool) public nftBlacklist;

    // --- Events ---
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event Mint(address indexed _to, uint256 indexed _tokenId);
    event MetadataUpdate(uint256 indexed _tokenId, string _newMetadata);
    event LimitOrderCreated(uint256 _orderId, uint256 indexed _tokenId, address indexed _seller, uint256 _price);
    event LimitOrderCancelled(uint256 _orderId);
    event LimitOrderFilled(uint256 _orderId, address indexed _buyer);
    event DutchAuctionCreated(uint256 _auctionId, uint256 indexed _tokenId, address indexed _seller, uint256 _startingPrice);
    event DutchAuctionBid(uint256 _auctionId, address indexed _bidder, uint256 _bidAmount);
    event DutchAuctionEnded(uint256 _auctionId, address indexed _winner, uint256 _finalPrice);
    event EscrowCreated(uint256 _escrowId, uint256 indexed _tokenId, address indexed _seller, address indexed _buyer, uint256 _price);
    event EscrowConfirmed(uint256 _escrowId, address indexed _party);
    event EscrowCancelled(uint256 _escrowId);
    event ConditionalSaleCreated(uint256 _saleId, uint256 indexed _tokenId, address indexed _seller);
    event ConditionalSaleFulfilled(uint256 _saleId, address indexed _buyer);
    event NFTBundleCreated(uint256 _bundleId, address indexed _seller, uint256 _bundlePrice);
    event NFTBundleBought(uint256 _bundleId, address indexed _buyer);
    event NFTStaked(uint256 indexed _tokenId, address indexed _user);
    event NFTUnstaked(uint256 indexed _tokenId, address indexed _user);
    event NFTRented(uint256 _rentId, uint256 indexed _tokenId, address indexed _renter, uint256 _rentDuration);
    event RentEnded(uint256 _rentId);
    event GovernanceProposalCreated(uint256 _proposalId, address indexed _proposer, string _title);
    event GovernanceVoteCast(uint256 _proposalId, address indexed _voter, bool _vote);
    event GovernanceProposalExecuted(uint256 _proposalId);
    event PlatformPaused(bool _paused);
    event PlatformFeeUpdated(uint256 _feePercentage);
    event DisputeResolved(uint256 _transactionId, address indexed _winner);
    event WhitelistedUserAdded(address indexed _user);
    event WhitelistedUserRemoved(address indexed _user);
    event BlacklistedNFTAdded(uint256 indexed _tokenId);
    event BlacklistedNFTRemoved(uint256 indexed _tokenId);
    event NFTEvolved(uint256 indexed _tokenId);
    event MysteryBoxOpened(uint256 _boxId, uint256 _revealedTokenId);
    event AchievementUnlocked(uint256 indexed _tokenId, string _achievementName);


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == platformOwner, "Only platform owner can call this function.");
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

    modifier validTokenId(uint256 _tokenId) {
        require(ownerOf[_tokenId] != address(0), "Invalid token ID.");
        _;
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(ownerOf[_tokenId] == msg.sender, "You are not the owner of this token.");
        _;
    }

    modifier onlyApprovedOrOwner(uint256 _tokenId) {
        require(ownerOf[_tokenId] == msg.sender || tokenApprovals[_tokenId] == msg.sender || getApproved[ownerOf[_tokenId]][msg.sender], "Not approved or owner.");
        _;
    }

    modifier whitelistedUser() {
        require(whitelist[msg.sender], "User is not whitelisted.");
        _;
    }

    modifier notBlacklistedNFT(uint256 _tokenId) {
        require(!nftBlacklist[_tokenId], "NFT is blacklisted.");
        _;
    }


    // --- Constructor ---
    constructor() {
        platformOwner = msg.sender;
        whitelist[platformOwner] = true; // Whitelist platform owner by default
    }

    // --- Core NFT Functionality ---

    /// @notice Mints a new dynamic NFT with mutable metadata.
    /// @param _to The address to mint the NFT to.
    /// @param _baseURI The base URI for the NFT metadata.
    /// @param _initialMetadata The initial metadata URI for the NFT.
    function mintDynamicNFT(address _to, string memory _baseURI, string memory _initialMetadata) external onlyOwner returns (uint256 tokenId) {
        require(_to != address(0), "Mint to the zero address");
        totalSupply++;
        tokenId = totalSupply;
        ownerOf[tokenId] = _to;
        balanceOf[_to]++;
        tokenMetadataURIs[tokenId] = string(abi.encodePacked(_baseURI, _initialMetadata)); // Using baseURI + metadata for dynamic URI structure
        emit Transfer(address(0), _to, tokenId);
        emit Mint(_to, tokenId);
    }

    /// @notice Updates the metadata URI of a specific NFT.
    /// @param _tokenId The ID of the NFT to update.
    /// @param _newMetadata The new metadata URI for the NFT.
    function updateNFTMetadata(uint256 _tokenId, string memory _newMetadata) external validTokenId onlyApprovedOrOwner(_tokenId) {
        tokenMetadataURIs[_tokenId] = _newMetadata;
        emit MetadataUpdate(_tokenId, _newMetadata);
    }

    /// @notice Mints multiple NFTs in a single transaction.
    /// @param _to The address to mint the NFTs to.
    /// @param _baseURI The base URI for the NFTs metadata.
    /// @param _count The number of NFTs to mint.
    function batchMintNFTs(address _to, string memory _baseURI, uint256 _count) external onlyOwner returns (uint256[] memory tokenIds) {
        require(_to != address(0), "Mint to the zero address");
        tokenIds = new uint256[](_count);
        for (uint256 i = 0; i < _count; i++) {
            totalSupply++;
            uint256 tokenId = totalSupply;
            tokenIds[i] = tokenId;
            ownerOf[tokenId] = _to;
            balanceOf[_to]++;
            tokenMetadataURIs[tokenId] = _baseURI; // Or generate unique metadata if needed
            emit Transfer(address(0), _to, tokenId);
            emit Mint(_to, tokenId);
        }
        return tokenIds;
    }

    // --- Advanced Marketplace Features ---

    /// @notice Creates a limit order to sell an NFT at a specified price.
    /// @param _tokenId The ID of the NFT to sell.
    /// @param _price The price to sell the NFT for (in Wei).
    function createLimitOrder(uint256 _tokenId, uint256 _price) external validTokenId onlyTokenOwner(_tokenId) whenNotPaused notBlacklistedNFT(_tokenId) {
        require(_price > 0, "Price must be greater than zero.");
        require(tokenApprovals[_tokenId] == address(this) || getApproved[msg.sender][address(this)], "Contract must be approved to transfer NFT.");

        uint256 orderId = nextOrderId++;
        limitOrders[orderId] = LimitOrder({
            orderId: orderId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        emit LimitOrderCreated(orderId, _tokenId, msg.sender, _price);
    }

    /// @notice Cancels an existing limit order.
    /// @param _orderId The ID of the limit order to cancel.
    function cancelLimitOrder(uint256 _orderId) external whenNotPaused {
        require(limitOrders[_orderId].isActive, "Order is not active.");
        require(limitOrders[_orderId].seller == msg.sender, "Only seller can cancel order.");
        limitOrders[_orderId].isActive = false;
        emit LimitOrderCancelled(_orderId);
    }

    /// @notice Fills a limit order to buy an NFT.
    /// @param _orderId The ID of the limit order to fill.
    function fillLimitOrder(uint256 _orderId) external payable whenNotPaused whitelistedUser {
        require(limitOrders[_orderId].isActive, "Order is not active.");
        require(msg.value >= limitOrders[_orderId].price, "Insufficient funds.");
        uint256 tokenId = limitOrders[_orderId].tokenId;
        address seller = limitOrders[_orderId].seller;
        uint256 price = limitOrders[_orderId].price;

        limitOrders[_orderId].isActive = false;
        _transfer(seller, msg.sender, tokenId);

        // Transfer funds to seller and platform owner
        uint256 platformFee = (price * platformFeePercentage) / 100;
        uint256 sellerProceeds = price - platformFee;
        payable(platformOwner).transfer(platformFee);
        payable(seller).transfer(sellerProceeds);

        emit LimitOrderFilled(_orderId, msg.sender);
    }


    /// @notice Creates a Dutch Auction for an NFT.
    /// @param _tokenId The ID of the NFT to auction.
    /// @param _startingPrice The starting price of the auction (in Wei).
    /// @param _decrementAmount The amount to decrement the price by each interval (in Wei).
    /// @param _decrementInterval The interval (in seconds) to decrement the price.
    function createDutchAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _decrementAmount, uint256 _decrementInterval) external validTokenId onlyTokenOwner(_tokenId) whenNotPaused notBlacklistedNFT(_tokenId) {
        require(_startingPrice > 0, "Starting price must be greater than zero.");
        require(_decrementAmount > 0, "Decrement amount must be greater than zero.");
        require(_decrementInterval > 0, "Decrement interval must be greater than zero.");
        require(tokenApprovals[_tokenId] == address(this) || getApproved[msg.sender][address(this)], "Contract must be approved to transfer NFT.");

        uint256 auctionId = nextAuctionId++;
        dutchAuctions[auctionId] = DutchAuction({
            auctionId: auctionId,
            tokenId: _tokenId,
            seller: msg.sender,
            startingPrice: _startingPrice,
            currentPrice: _startingPrice,
            decrementAmount: _decrementAmount,
            decrementInterval: _decrementInterval,
            startTime: block.timestamp,
            endTime: block.timestamp + (30 days), // Example: 30 days auction duration, can be adjusted
            highestBidder: address(0),
            highestBid: 0,
            isActive: true
        });
        emit DutchAuctionCreated(auctionId, _tokenId, msg.sender, _startingPrice);
    }

    /// @notice Allows users to bid on a Dutch Auction.
    /// @param _auctionId The ID of the Dutch Auction to bid on.
    function bidOnDutchAuction(uint256 _auctionId) external payable whenNotPaused whitelistedUser {
        require(dutchAuctions[_auctionId].isActive, "Auction is not active.");
        require(block.timestamp < dutchAuctions[_auctionId].endTime, "Auction has ended.");
        require(msg.value >= dutchAuctions[_auctionId].currentPrice, "Bid is too low. Current price is higher.");

        DutchAuction storage auction = dutchAuctions[_auctionId];

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid); // Refund previous highest bidder
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        auction.currentPrice = msg.value; // Set current price to the bid price (in Dutch auction, price can increase upon bid)

        emit DutchAuctionBid(_auctionId, msg.sender, msg.value);
    }

    /// @notice Ends a Dutch Auction and transfers NFT to the highest bidder.
    /// @param _auctionId The ID of the Dutch Auction to end.
    function endDutchAuction(uint256 _auctionId) external whenNotPaused {
        require(dutchAuctions[_auctionId].isActive, "Auction is not active.");
        require(block.timestamp >= dutchAuctions[_auctionId].endTime || dutchAuctions[_auctionId].highestBidder != address(0), "Auction cannot be ended yet."); // Allow end after time or if bid is placed

        DutchAuction storage auction = dutchAuctions[_auctionId];
        require(auction.seller == msg.sender || auction.highestBidder == msg.sender || msg.sender == platformOwner, "Only seller, highest bidder, or owner can end auction."); // Allow seller, bidder, or platform owner to end

        auction.isActive = false;
        uint256 tokenId = auction.tokenId;
        address seller = auction.seller;
        address winner = auction.highestBidder;
        uint256 finalPrice = auction.currentPrice;

        if (winner != address(0)) {
            _transfer(seller, winner, tokenId);

             // Transfer funds to seller and platform owner
            uint256 platformFee = (finalPrice * platformFeePercentage) / 100;
            uint256 sellerProceeds = finalPrice - platformFee;
            payable(platformOwner).transfer(platformFee);
            payable(seller).transfer(sellerProceeds);

            emit DutchAuctionEnded(_auctionId, winner, finalPrice);
        } else {
            // No bidder, return NFT to seller - optional handling
            emit DutchAuctionEnded(_auctionId, address(0), 0); // Indicate no winner
        }
    }

    /// @notice Creates an escrow transaction for secure NFT trading.
    /// @param _tokenId The ID of the NFT to trade.
    /// @param _buyer The address of the buyer.
    /// @param _price The price of the NFT (in Wei).
    function createEscrowTransaction(uint256 _tokenId, address _buyer, uint256 _price) external validTokenId onlyTokenOwner(_tokenId) whenNotPaused notBlacklistedNFT(_tokenId) {
        require(_buyer != address(0), "Buyer address cannot be zero.");
        require(_price > 0, "Price must be greater than zero.");
        require(tokenApprovals[_tokenId] == address(this) || getApproved[msg.sender][address(this)], "Contract must be approved to transfer NFT.");

        uint256 escrowId = nextEscrowId++;
        escrowTransactions[escrowId] = EscrowTransaction({
            escrowId: escrowId,
            tokenId: _tokenId,
            seller: msg.sender,
            buyer: _buyer,
            price: _price,
            sellerConfirmed: false,
            buyerConfirmed: false,
            isActive: true
        });
        emit EscrowCreated(escrowId, _tokenId, msg.sender, _buyer, _price);
    }

    /// @notice Buyer confirms receipt of NFT in escrow (after seller transfer).
    /// @param _escrowId The ID of the escrow transaction.
    function buyerConfirmEscrow(uint256 _escrowId) external payable whenNotPaused whitelistedUser {
        require(escrowTransactions[_escrowId].isActive, "Escrow is not active.");
        require(escrowTransactions[_escrowId].buyer == msg.sender, "Only buyer can confirm escrow.");
        require(msg.value >= escrowTransactions[_escrowId].price, "Insufficient funds. Send agreed price to escrow.");

        EscrowTransaction storage escrow = escrowTransactions[_escrowId];
        escrow.buyerConfirmed = true;

        if (escrow.sellerConfirmed) {
            _finalizeEscrow(_escrowId); // Finalize if both parties confirmed
        } else {
            emit EscrowConfirmed(_escrowId, msg.sender);
        }
    }

    /// @notice Seller confirms payment received in escrow (after buyer deposit).
    /// @param _escrowId The ID of the escrow transaction.
    function sellerConfirmEscrow(uint256 _escrowId) external whenNotPaused {
        require(escrowTransactions[_escrowId].isActive, "Escrow is not active.");
        require(escrowTransactions[_escrowId].seller == msg.sender, "Only seller can confirm escrow.");
        escrowTransactions[_escrowId].sellerConfirmed = true;

        if (escrowTransactions[_escrowId].buyerConfirmed) {
            _finalizeEscrow(_escrowId); // Finalize if both parties confirmed
        } else {
            emit EscrowConfirmed(_escrowId, msg.sender);
        }
    }

    /// @notice Cancels an escrow transaction.
    /// @param _escrowId The ID of the escrow transaction to cancel.
    function cancelEscrowTransaction(uint256 _escrowId) external whenNotPaused {
        require(escrowTransactions[_escrowId].isActive, "Escrow is not active.");
        require(escrowTransactions[_escrowId].seller == msg.sender || escrowTransactions[_escrowId].buyer == msg.sender || msg.sender == platformOwner, "Only seller, buyer, or owner can cancel escrow."); // Allow seller, buyer, or platform owner to cancel

        EscrowTransaction storage escrow = escrowTransactions[_escrowId];
        escrow.isActive = false;
        address seller = escrow.seller;
        address buyer = escrow.buyer;

        // Refund buyer if they deposited funds (simplified - in real escrow, funds handling would be more robust)
        if (escrow.buyerConfirmed) {
            payable(buyer).transfer(escrow.price);
        }

        emit EscrowCancelled(_escrowId);
    }

    /// @dev Internal function to finalize an escrow transaction.
    /// @param _escrowId The ID of the escrow transaction.
    function _finalizeEscrow(uint256 _escrowId) internal {
        EscrowTransaction storage escrow = escrowTransactions[_escrowId];
        require(escrow.isActive, "Escrow is not active.");
        require(escrow.sellerConfirmed && escrow.buyerConfirmed, "Both parties must confirm escrow.");

        escrow.isActive = false;
        uint256 tokenId = escrow.tokenId;
        address seller = escrow.seller;
        address buyer = escrow.buyer;
        uint256 price = escrow.price;

        _transfer(seller, buyer, tokenId);

        // Transfer funds to seller and platform owner
        uint256 platformFee = (price * platformFeePercentage) / 100;
        uint256 sellerProceeds = price - platformFee;
        payable(platformOwner).transfer(platformFee);
        payable(seller).transfer(sellerProceeds);
    }

    // --- Conditional Sales (Placeholder - Oracle Integration Needed) ---
    // In a real-world scenario, you'd integrate with an actual oracle service
    // to fetch external data and determine if a condition is met.

    /// @notice Creates a conditional sale where NFT is sold only if a condition is met.
    /// @param _tokenId The ID of the NFT to sell.
    /// @param _price The price of the NFT (in Wei).
    /// @param _conditionOracle Address of the oracle contract (placeholder).
    /// @param _conditionData Data to send to the oracle to check the condition (placeholder).
    function createConditionalSale(uint256 _tokenId, uint256 _price, address _conditionOracle, bytes memory _conditionData) external validTokenId onlyTokenOwner(_tokenId) whenNotPaused notBlacklistedNFT(_tokenId) {
        require(_price > 0, "Price must be greater than zero.");
        require(tokenApprovals[_tokenId] == address(this) || getApproved[msg.sender][address(this)], "Contract must be approved to transfer NFT.");
        require(_conditionOracle != address(0), "Oracle address cannot be zero."); // Placeholder - In real world, validate oracle contract

        uint256 saleId = nextSaleId++;
        conditionalSales[saleId] = ConditionalSale({
            saleId: saleId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            conditionOracle: _conditionOracle, // Placeholder
            conditionData: _conditionData,     // Placeholder
            conditionMet: false,              // Placeholder - Oracle would update this
            isActive: true
        });
        emit ConditionalSaleCreated(saleId, _tokenId, msg.sender);
    }

    /// @notice Fulfills a conditional sale if the condition is met (oracle data check - placeholder).
    /// @param _saleId The ID of the conditional sale to fulfill.
    function fulfillConditionalSale(uint256 _saleId) external payable whenNotPaused whitelistedUser {
        ConditionalSale storage sale = conditionalSales[_saleId];
        require(sale.isActive, "Sale is not active.");
        require(msg.value >= sale.price, "Insufficient funds.");
        // In a real implementation, you would interact with the `sale.conditionOracle`
        // contract using `sale.conditionData` to check if the condition is met.
        // For this example, we'll just assume the condition is met (placeholder).
        sale.conditionMet = true; // Placeholder - Simulate condition met

        require(sale.conditionMet, "Condition for sale is not met yet.");

        sale.isActive = false;
        uint256 tokenId = sale.tokenId;
        address seller = sale.seller;
        address buyer = msg.sender;
        uint256 price = sale.price;

        _transfer(seller, buyer, tokenId);

        // Transfer funds to seller and platform owner
        uint256 platformFee = (price * platformFeePercentage) / 100;
        uint256 sellerProceeds = price - platformFee;
        payable(platformOwner).transfer(platformFee);
        payable(seller).transfer(sellerProceeds);

        emit ConditionalSaleFulfilled(_saleId, buyer);
    }


    /// @notice Creates a bundle of NFTs for sale.
    /// @param _tokenIds An array of token IDs to include in the bundle.
    /// @param _bundlePrice The price of the NFT bundle (in Wei).
    function createNFTBundle(uint256[] memory _tokenIds, uint256 _bundlePrice) external whenNotPaused notBlacklistedNFT(_tokenIds[0]) { // Basic blacklist check against first NFT, can be extended
        require(_tokenIds.length > 0, "Bundle must contain at least one NFT.");
        require(_bundlePrice > 0, "Bundle price must be greater than zero.");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            require(validTokenId(tokenId), "Invalid token ID in bundle.");
            require(onlyTokenOwner(tokenId), "You are not the owner of token in bundle."); // Check owner for each token
            require(tokenApprovals[tokenId] == address(this) || getApproved[msg.sender][address(this)], "Contract must be approved to transfer NFTs in bundle.");
        }

        uint256 bundleId = nextBundleId++;
        nftBundles[bundleId] = NFTBundle({
            bundleId: bundleId,
            tokenIds: _tokenIds,
            bundlePrice: _bundlePrice,
            seller: msg.sender,
            isActive: true
        });
        emit NFTBundleCreated(bundleId, msg.sender, _bundlePrice);
    }

    /// @notice Buys an NFT bundle.
    /// @param _bundleId The ID of the NFT bundle to buy.
    function buyNFTBundle(uint256 _bundleId) external payable whenNotPaused whitelistedUser {
        NFTBundle storage bundle = nftBundles[_bundleId];
        require(bundle.isActive, "Bundle is not active.");
        require(msg.value >= bundle.bundlePrice, "Insufficient funds for bundle.");

        bundle.isActive = false;
        address seller = bundle.seller;
        uint256[] memory tokenIds = bundle.tokenIds;
        uint256 bundlePrice = bundle.bundlePrice;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _transfer(seller, msg.sender, tokenIds[i]); // Transfer each NFT in bundle
        }

         // Transfer funds to seller and platform owner
        uint256 platformFee = (bundlePrice * platformFeePercentage) / 100;
        uint256 sellerProceeds = bundlePrice - platformFee;
        payable(platformOwner).transfer(platformFee);
        payable(seller).transfer(sellerProceeds);

        emit NFTBundleBought(_bundleId, msg.sender);
    }


    // --- NFT Utility and Engagement ---

    /// @notice Stakes an NFT to earn platform tokens.
    /// @param _tokenId The ID of the NFT to stake.
    function stakeNFT(uint256 _tokenId) external validTokenId onlyTokenOwner(_tokenId) whenNotPaused notBlacklistedNFT(_tokenId) {
        require(!isNFTStaked[_tokenId], "NFT is already staked.");
        isNFTStaked[_tokenId] = true;
        _transfer(msg.sender, address(this), _tokenId); // Transfer NFT to contract for staking
        stakingBalance[msg.sender]++; // Example: Increase staking balance (platform tokens)
        emit NFTStaked(_tokenId, msg.sender);
    }

    /// @notice Unstakes an NFT.
    /// @param _tokenId The ID of the NFT to unstake.
    function unstakeNFT(uint256 _tokenId) external validTokenId onlyTokenOwner(_tokenId) whenNotPaused {
        require(isNFTStaked[_tokenId], "NFT is not staked.");
        isNFTStaked[_tokenId] = false;
        _transfer(address(this), msg.sender, _tokenId); // Transfer NFT back to owner
        stakingBalance[msg.sender]--; // Example: Decrease staking balance
        emit NFTUnstaked(_tokenId, msg.sender);
    }

    /// @notice Allows NFT owners to rent out their NFTs.
    /// @param _tokenId The ID of the NFT to rent out.
    /// @param _renter The address of the renter.
    /// @param _rentDuration The duration of the rent (in blocks/seconds - placeholder).
    function rentNFT(uint256 _tokenId, address _renter, uint256 _rentDuration) external validTokenId onlyTokenOwner(_tokenId) whenNotPaused notBlacklistedNFT(_tokenId) {
        require(_renter != address(0), "Renter address cannot be zero.");
        require(!isNFTStaked[_tokenId], "Cannot rent staked NFT.");
        require(nftRentId[_tokenId] == 0, "NFT is already rented."); // Only one active rent at a time (simplified)

        uint256 rentId = nextRentId++;
        nftRents[rentId] = NFTRent({
            rentId: rentId,
            tokenId: _tokenId,
            owner: msg.sender,
            renter: _renter,
            rentDuration: _rentDuration,
            rentStartTime: block.timestamp,
            isActive: true
        });
        nftRentId[_tokenId] = rentId; // Map tokenId to rentId
        _transfer(msg.sender, _renter, _tokenId); // Transfer NFT to renter (careful with ownership in real rent scenario)
        emit NFTRented(rentId, _tokenId, _renter, _rentDuration);
    }

    /// @notice Ends an NFT rental agreement.
    /// @param _rentId The ID of the rent agreement to end.
    function endRent(uint256 _rentId) external whenNotPaused {
        NFTRent storage rent = nftRents[_rentId];
        require(rent.isActive, "Rent is not active.");
        require(rent.renter == msg.sender || rent.owner == msg.sender || msg.sender == platformOwner, "Only renter, owner or owner can end rent.");

        rent.isActive = false;
        uint256 tokenId = rent.tokenId;
        address owner = rent.owner;
        address renter = rent.renter;
        nftRentId[tokenId] = 0; // Clear rent mapping

        _transfer(renter, owner, tokenId); // Transfer NFT back to owner
        emit RentEnded(_rentId);
    }


    // --- Community Governance ---

    /// @notice Allows NFT holders to create governance proposals.
    /// @param _title Title of the proposal.
    /// @param _description Description of the proposal.
    /// @param _calldata Function call data to execute if proposal passes.
    function createGovernanceProposal(string memory _title, string memory _description, bytes memory _calldata) external whenNotPaused whitelistedUser { // Whitelisted user can propose for now
        require(balanceOf[msg.sender] > 0, "Only NFT holders can create proposals."); // Basic check - any NFT holder can propose
        require(bytes(_title).length > 0 && bytes(_description).length > 0, "Title and description cannot be empty.");

        uint256 proposalId = nextProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            title: _title,
            description: _description,
            calldata: _calldata,
            yesVotes: 0,
            noVotes: 0,
            quorum: (totalSupply * proposalQuorumPercentage) / 100, // Calculate quorum based on percentage
            votingEndTime: block.timestamp + proposalVotingDuration,
            executed: false
        });
        emit GovernanceProposalCreated(proposalId, msg.sender, _title);
    }

    /// @notice Allows NFT holders to vote on governance proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote `true` for yes, `false` for no.
    function voteOnProposal(uint256 _proposalId, bool _vote) external whenNotPaused whitelistedUser { // Whitelisted user can vote for now
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(!proposal.executed, "Proposal already executed.");
        require(block.timestamp < proposal.votingEndTime, "Voting has ended.");
        require(balanceOf[msg.sender] > 0, "Only NFT holders can vote."); // Basic check - any NFT holder can vote

        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit GovernanceVoteCast(_proposalId, msg.sender, _vote);
    }

    /// @notice Executes a passed governance proposal.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyOwner whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(!proposal.executed, "Proposal already executed.");
        require(block.timestamp >= proposal.votingEndTime, "Voting is still ongoing.");
        require(proposal.yesVotes >= proposal.quorum, "Proposal does not meet quorum.");
        require(proposal.yesVotes > proposal.noVotes, "Proposal not passed - No majority.");

        proposal.executed = true;
        (bool success, ) = address(this).call(proposal.calldata); // Execute proposal's calldata
        require(success, "Proposal execution failed.");
        emit GovernanceProposalExecuted(_proposalId);
    }

    // --- Enhanced Security and Management ---

    /// @notice Pauses or unpauses the marketplace contract.
    /// @param _paused `true` to pause, `false` to unpause.
    function setPause(bool _paused) external onlyOwner {
        paused = _paused;
        emit PlatformPaused(_paused);
    }

    /// @notice Sets the platform fee percentage for marketplace transactions.
    /// @param _feePercentage The new platform fee percentage (e.g., 2 for 2%).
    function setPlatformFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeUpdated(_feePercentage);
    }

    /// @notice Admin function to resolve disputes in marketplace transactions (example).
    /// @param _transactionId  ID of the disputed transaction (e.g., escrowId).
    /// @param _winner Address of the party deemed the winner.
    function resolveDispute(uint256 _transactionId, address _winner) external onlyOwner {
        // Example: For escrow disputes - Refund buyer and return NFT to seller or vice versa based on dispute resolution
        EscrowTransaction storage escrow = escrowTransactions[_transactionId];
        require(escrow.isActive, "Escrow is not active.");
        escrow.isActive = false; // Mark escrow as resolved

        if (_winner == escrow.buyer) {
            _transfer(escrow.seller, escrow.buyer, escrow.tokenId); // Transfer NFT to buyer
            payable(escrow.buyer).transfer(escrow.price); // Refund buyer (if funds were in escrow - simplified)
        } else if (_winner == escrow.seller) {
            payable(escrow.seller).transfer(escrow.price); // Pay seller (if funds were in escrow - simplified)
            // NFT remains with seller - or handle return from buyer if already transferred in escrow
        }
        emit DisputeResolved(_transactionId, _winner);
    }

    /// @notice Adds an address to the whitelist.
    /// @param _user The address to whitelist.
    function addToWhitelist(address _user) external onlyOwner {
        whitelist[_user] = true;
        emit WhitelistedUserAdded(_user);
    }

    /// @notice Removes an address from the whitelist.
    /// @param _user The address to remove from the whitelist.
    function removeFromWhitelist(address _user) external onlyOwner {
        whitelist[_user] = false;
        emit WhitelistedUserRemoved(_user);
    }

    /// @notice Blacklists a specific NFT.
    /// @param _tokenId The ID of the NFT to blacklist.
    function addToBlacklistNFT(uint256 _tokenId) external onlyOwner {
        nftBlacklist[_tokenId] = true;
        emit BlacklistedNFTAdded(_tokenId);
    }

    /// @notice Removes an NFT from the blacklist.
    /// @param _tokenId The ID of the NFT to remove from the blacklist.
    function removeFromBlacklistNFT(uint256 _tokenId) external onlyOwner {
        nftBlacklist[_tokenId] = false;
        emit BlacklistedNFTRemoved(_tokenId);
    }


    // --- Dynamic and Creative Elements (Examples) ---

    /// @notice Triggers an evolution event for a dynamic NFT (example).
    /// @param _tokenId The ID of the NFT to evolve.
    function evolveNFT(uint256 _tokenId) external validTokenId onlyTokenOwner(_tokenId) whenNotPaused notBlacklistedNFT(_tokenId) {
        // Example logic: Update metadata to a new URI for evolved state
        string memory currentMetadata = tokenMetadataURIs[_tokenId];
        string memory evolvedMetadata = string(abi.encodePacked(currentMetadata, "_evolved")); // Simple example - append "_evolved"

        tokenMetadataURIs[_tokenId] = evolvedMetadata;
        emit MetadataUpdate(_tokenId, evolvedMetadata);
        emit NFTEvolved(_tokenId);
    }

    /// @notice Opens a mystery box NFT to reveal the contained NFT (example - simplified).
    /// @param _boxId The ID of the mystery box NFT.
    function openMysteryBox(uint256 _boxId) external validTokenId onlyTokenOwner(_boxId) whenNotPaused notBlacklistedNFT(_boxId) {
        // Example Logic: Assume mystery boxes are NFTs themselves.
        // On opening, they "reveal" a new random NFT (minted or pre-existing from a pool)
        require(symbol == "DNFTM", "Mystery boxes should be of DNFTM type for this example."); // Simplified check

        // Example: Mint a new NFT as the "reward" (replace with your actual logic)
        uint256 revealedTokenId = totalSupply + 1; // Simple next tokenId
        mintDynamicNFT(msg.sender, "ipfs://mysteryboxrewards/", string(abi.encodePacked("reward_", uint256(block.timestamp)))); // Example metadata
        _burn(_boxId); // Burn the mystery box NFT after opening

        emit MysteryBoxOpened(_boxId, revealedTokenId);
    }

    /// @notice Unlocks an on-chain achievement for an NFT (example).
    /// @param _tokenId The ID of the NFT to unlock achievement for.
    /// @param _achievementName The name of the achievement unlocked.
    function unlockAchievement(uint256 _tokenId, string memory _achievementName) external validTokenId onlyTokenOwner(_tokenId) whenNotPaused notBlacklistedNFT(_tokenId) {
        // Example logic: Update metadata to reflect the achievement
        string memory currentMetadata = tokenMetadataURIs[_tokenId];
        string memory achievementMetadata = string(abi.encodePacked(currentMetadata, "_achievement_", _achievementName)); // Simple example - append achievement to metadata

        tokenMetadataURIs[_tokenId] = achievementMetadata;
        emit MetadataUpdate(_tokenId, achievementMetadata);
        emit AchievementUnlocked(_tokenId, _achievementName);
    }


    // --- ERC721 Core Functions (Simplified - for demonstration) ---

    /// @dev Internal function to transfer tokens.
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        require(_to != address(0), "Transfer to the zero address");
        require(ownerOf[_tokenId] == _from, "Transfer from incorrect owner");

        balanceOf[_from]--;
        balanceOf[_to]++;
        ownerOf[_tokenId] = _to;
        delete tokenApprovals[_tokenId]; // Clear approvals on transfer
        emit Transfer(_from, _to, _tokenId);
    }

    /// @dev Internal function to burn tokens (example for mystery boxes).
    function _burn(uint256 _tokenId) internal validTokenId onlyTokenOwner(_tokenId) { // Example - onlyOwner can burn in this context
        address owner = ownerOf[_tokenId];

        balanceOf[owner]--;
        delete ownerOf[_tokenId];
        delete tokenMetadataURIs[_tokenId];
        delete tokenApprovals[_tokenId];
        totalSupply--;
        emit Transfer(owner, address(0), _tokenId); // Transfer to zero address indicates burn
    }


    /// @notice Approve another address to transfer the given token ID
    /// @param _approved The address to be approved for the given token ID
    /// @param _tokenId Token ID to be approved
    function approve(address _approved, uint256 _tokenId) public validTokenId onlyTokenOwner(_tokenId) whenNotPaused {
        tokenApprovals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage all of msg.sender's tokens.
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) public whenNotPaused {
        getApproved[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice Get the approved address for a single NFT ID
    /// @param _tokenId The NFT ID to find the approved address for
    /// @return Address currently approved to transfer the NFT ID
    function getApprovedAddress(uint256 _tokenId) public view validTokenId returns (address) {
        return tokenApprovals[_tokenId];
    }

    /// @notice Check if `_operator` is approved to manage all of `_owner`'s assets.
    /// @param _owner The address of the owner.
    /// @param _operator The address of the operator.
    /// @return True if the operator is approved for all, false otherwise
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return getApproved[_owner][_operator];
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @param _from The current owner address of the NFT
    /// @param _to The address to which to transfer the NFT
    /// @param _tokenId The token ID to be transferred
    function transferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused onlyApprovedOrOwner(_tokenId) notBlacklistedNFT(_tokenId) {
        _transfer(_from, _to, _tokenId);
    }

    /// @notice Safely transfers the ownership of an NFT from one address to another address
    /// @param _from The current owner address for the NFT
    /// @param _to The address to which to transfer the NFT
    /// @param _tokenId The token ID to be transferred
    /// @param _data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public whenNotPaused onlyApprovedOrOwner(_tokenId) notBlacklistedNFT(_tokenId) {
        transferFrom(_from, _to, _tokenId); // For simplicity, using regular transferFrom for now. Safe transfer implementation can be added.
        require(_checkOnERC721Received(), "ERC721: transfer to non ERC721Receiver implementer"); // Placeholder - Implement proper ERC721Receiver check if needed
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused onlyApprovedOrOwner(_tokenId) notBlacklistedNFT(_tokenId) {
        safeTransferFrom(_from, _to, _tokenId, ""); // Calls overloaded function with empty data
    }


    // --- Placeholder for ERC721Receiver check (Implement if needed for safe transfers) ---
    function _checkOnERC721Received() private pure returns (bool) {
        // In a real implementation, you would check if the recipient address is a contract
        // and if it implements ERC721Receiver interface, and call onERC721Received.
        // For this example, we are skipping this part for simplicity.
        return true; // Placeholder - Assume all transfers are safe for demonstration
    }


    // --- Fallback and Receive (Optional - for receiving ETH) ---
    receive() external payable {}
    fallback() external payable {}
}
```