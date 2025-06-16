Okay, here is a smart contract focusing on a "Dynamic NFT Marketplace" with several advanced concepts, aiming for uniqueness and demonstrating creative functionality beyond typical marketplace contracts. It incorporates dynamic NFT properties, different listing types (fixed price, auction, bundle, conditional), royalty distribution, delegated trading, and a simulated oracle interaction.

It *does not* inherit directly from standard OpenZeppelin contracts like `ERC721`, `Ownable`, `ERC2981`, etc., but interacts with them via interfaces (`IERC721`, `IERC20`) where necessary, and implements custom logic for ownership, access control, royalties, etc., to fulfill the non-duplication requirement for the *contract itself*.

---

**Outline & Function Summary**

**Contract Name:** `DynamicNFTMarketplace`

**Core Concepts:**
1.  **Dynamic NFTs:** Tracks and allows modification of NFT properties (`level`, `mood`) based on actions (manual level-up, external oracle updates, staking time). Allows claiming rewards based on state.
2.  **Advanced Marketplace:** Supports various listing types (fixed price, auction, bundle, conditional). Handles marketplace fees and creator royalties.
3.  **Delegated Trading:** Allows NFT owners to delegate listing/managing their NFTs to another address.
4.  **Simulated Oracle:** Includes a mechanism (`updateExternalFactor`) callable by a designated address to influence NFT dynamics.
5.  **Staking:** Allows users to stake NFTs within the contract, potentially influencing dynamic properties or earning rewards.

**Function Summary (Minimum 20 distinct functions):**

*   **Admin Functions:**
    *   `constructor()`: Initializes contract, sets owner and initial fee.
    *   `setFeePercentage(uint256 _feePercentage)`: Sets the marketplace fee percentage (owner only).
    *   `withdrawFees(address payable _to, uint256 _amount)`: Allows owner to withdraw accumulated marketplace fees.
    *   `setRoyaltyPercentage(uint256 _royaltyPercentage)`: Sets the global royalty percentage for sales (owner only).
    *   `setOracleAddress(address _oracle)`: Sets the address allowed to update the external factor for dynamic NFTs (owner only).
    *   `grantAdminRole(address _admin)`: Grants an additional admin role (owner only - *simplified access control for example*).
    *   `revokeAdminRole(address _admin)`: Revokes an admin role (owner only).

*   **Marketplace Listing/Buying (Fixed Price):**
    *   `listNFT(address _nftContract, uint256 _tokenId, uint256 _price)`: Lists an NFT for a fixed price.
    *   `buyNFT(uint256 _listingId)`: Buys a fixed-price listed NFT.
    *   `cancelListing(uint256 _listingId)`: Cancels a fixed-price listing.
    *   `getListingDetails(uint256 _listingId)`: Queries details of a fixed-price listing.

*   **Marketplace Listing/Buying (Auction):**
    *   `createAuction(address _nftContract, uint256 _tokenId, uint256 _minBid, uint64 _endTime)`: Creates an auction for an NFT.
    *   `placeBid(uint256 _auctionId)`: Places a bid in an ongoing auction.
    *   `settleAuction(uint256 _auctionId)`: Settles a finished auction, transferring NFT and funds.
    *   `cancelAuction(uint256 _auctionId)`: Cancels an auction if no bids have been placed.
    *   `getAuctionDetails(uint256 _auctionId)`: Queries details of an auction.

*   **Marketplace Listing/Buying (Bundle):**
    *   `listBundle(address[] memory _nftContracts, uint256[] memory _tokenIds, uint256 _totalPrice)`: Lists a bundle of NFTs for a fixed price.
    *   `buyBundle(uint256 _bundleListingId)`: Buys an NFT bundle.
    *   `cancelBundleListing(uint256 _bundleListingId)`: Cancels a bundle listing.
    *   `getBundleListingDetails(uint256 _bundleListingId)`: Queries details of a bundle listing.

*   **Marketplace Listing/Buying (Conditional):**
    *   `listConditionalSale(address _nftContract, uint256 _tokenId, uint256 _price, address _requiredToken, uint256 _requiredAmount)`: Lists an NFT that can only be bought by an address holding a minimum amount of a specific ERC20 token.
    *   `buyConditionalSale(uint256 _conditionalListingId)`: Buys a conditionally listed NFT (checks buyer's ERC20 balance).
    *   `cancelConditionalSale(uint256 _conditionalListingId)`: Cancels a conditional listing.
    *   `getConditionalListingDetails(uint256 _conditionalListingId)`: Queries details of a conditional listing.

*   **Dynamic NFT Functions:**
    *   `updateExternalFactor(int256 _factor)`: Callable by oracle address to update the external factor influencing NFT mood.
    *   `levelUpNFT(address _nftContract, uint256 _tokenId)`: Allows NFT owner to manually level up their NFT (may have cost logic, simplified here).
    *   `claimDynamicRewards(address _nftContract, uint256 _tokenId)`: Allows claiming rewards based on the NFT's current dynamic state.
    *   `getNFTDynamicState(address _nftContract, uint256 _tokenId)`: Queries the current dynamic state (`level`, `mood`, `lastUpdate`) of an NFT.
    *   `getLevelUpCost(uint256 _currentLevel)`: Calculates the cost to level up based on current level.

*   **Staking Functions:**
    *   `stakeNFT(address _nftContract, uint256 _tokenId)`: Stakes an NFT within the contract.
    *   `unstakeNFT(address _nftContract, uint256 _tokenId)`: Unstakes an NFT.
    *   `getNFTStakingDetails(address _nftContract, uint256 _tokenId)`: Queries staking details for an NFT.

*   **Delegation Functions:**
    *   `delegateTradingApproval(address _delegate)`: Grants trading approval to another address for your NFTs.
    *   `removeDelegateApproval(address _delegate)`: Revokes trading approval from an address.
    *   `isDelegate(address _owner, address _delegate)`: Checks if an address is a delegate for an owner.

*   **Royalty Functions:**
    *   `withdrawRoyalties(address payable _to)`: Allows royalty recipients to withdraw their earned royalties.
    *   `getAccumulatedRoyalties(address _royaltyRecipient)`: Queries accumulated royalties for a recipient.

*   **Query Functions:**
    *   `getUserListings(address _user)`: Gets a list of listing IDs for a user.
    *   `getUserAuctions(address _user)`: Gets a list of auction IDs for a user.
    *   `getUserBundleListings(address _user)`: Gets a list of bundle listing IDs for a user.
    *   `getUserConditionalListings(address _user)`: Gets a list of conditional listing IDs for a user.
    *   `getAccumulatedFees()`: Gets the total accumulated fees.

Total distinct functions: 39. This exceeds the minimum requirement of 20.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Note: This contract interacts with ERC721 and ERC20 contracts via interfaces
// but does not inherit core implementations like ERC721Enumerable, Ownable, etc.
// Custom logic is used for access control, listing management, and dynamic NFT state.

contract DynamicNFTMarketplace {
    using Address for address payable;

    address private owner;
    mapping(address => bool) private admins; // Simplified multi-admin role

    uint256 private feePercentage; // 0-10000 for 0-100% (e.g., 250 for 2.5%)
    uint256 private accumulatedFees;

    uint256 private royaltyPercentage; // 0-10000 for 0-100%
    mapping(address => uint256) private accumulatedRoyalties;

    address private oracleAddress; // Address allowed to call updateExternalFactor

    // --- Structs and Enums ---

    enum ListingStatus { Active, Sold, Cancelled }

    struct Listing {
        uint256 listingId;
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price; // In native currency (ETH)
        ListingStatus status;
    }

    enum AuctionStatus { Active, Ended, Settled, Cancelled }

    struct Auction {
        uint256 auctionId;
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 minBid;
        uint256 highestBid;
        address payable highestBidder;
        uint64 endTime;
        AuctionStatus status;
    }

    struct BundleListing {
        uint256 bundleListingId;
        address seller;
        address[] nftContracts;
        uint256[] tokenIds;
        uint256 totalPrice; // In native currency (ETH)
        ListingStatus status;
    }

    struct ConditionalListing {
        uint256 conditionalListingId;
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price; // In native currency (ETH)
        address requiredToken; // ERC20 token required for buyer
        uint256 requiredAmount; // Minimum balance required for buyer
        ListingStatus status;
    }

    struct DynamicNFTData {
        uint256 level;
        int256 mood; // Can be negative or positive
        uint64 lastDynamicUpdate; // Timestamp
        uint64 lastStakedAt; // Timestamp when staked, 0 if not staked
        uint256 accumulatedStakingTime; // Total time staked
    }

    // --- Mappings and Counters ---

    uint256 private nextListingId = 1;
    mapping(uint256 => Listing) public listings;
    mapping(address => uint256[]) private userFixedListings; // Seller address => array of listing IDs

    uint256 private nextAuctionId = 1;
    mapping(uint256 => Auction) public auctions;
    mapping(address => uint256[]) private userAuctions; // Seller address => array of auction IDs

    uint256 private nextBundleListingId = 1;
    mapping(uint256 => BundleListing) public bundleListings;
    mapping(address => uint256[]) private userBundleListings; // Seller address => array of bundle listing IDs

    uint256 private nextConditionalListingId = 1;
    mapping(uint256 => ConditionalListing) public conditionalListings;
    mapping(address => uint256[]) private userConditionalListings; // Seller address => array of conditional listing IDs

    mapping(address => mapping(uint256 => DynamicNFTData)) private dynamicNFTs; // nftContract => tokenId => data
    mapping(address => mapping(uint256 => address)) private stakedNFTs; // nftContract => tokenId => staker address (0x0 if not staked)

    mapping(address => mapping(address => bool)) private delegatedTradingApprovals; // owner => delegate => approved

    // --- Events ---

    event ListingCreated(uint256 indexed listingId, address indexed seller, address indexed nftContract, uint256 tokenId, uint256 price);
    event NFTBought(uint256 indexed listingId, address indexed buyer, address indexed seller, uint256 price);
    event ListingCancelled(uint256 indexed listingId);

    event AuctionCreated(uint256 indexed auctionId, address indexed seller, address indexed nftContract, uint256 tokenId, uint256 minBid, uint64 endTime);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event AuctionSettled(uint256 indexed auctionId, address indexed winner, uint256 winningBid);
    event AuctionCancelled(uint256 indexed auctionId);

    event BundleListingCreated(uint256 indexed bundleListingId, address indexed seller, address[] nftContracts, uint256[] tokenIds, uint256 totalPrice);
    event BundleBought(uint256 indexed bundleListingId, address indexed buyer, address indexed seller, uint256 totalPrice);
    event BundleListingCancelled(uint256 indexed bundleListingId);

    event ConditionalListingCreated(uint256 indexed conditionalListingId, address indexed seller, address indexed nftContract, uint256 tokenId, uint256 price, address requiredToken, uint256 requiredAmount);
    event ConditionalSaleBought(uint256 indexed conditionalListingId, address indexed buyer, address indexed seller, uint256 price);
    event ConditionalListingCancelled(uint256 indexed conditionalListingId);

    event ExternalFactorUpdated(int256 factor);
    event NFTLeveledUp(address indexed nftContract, uint256 indexed tokenId, uint256 newLevel, address indexed leveledBy);
    event DynamicRewardsClaimed(address indexed nftContract, uint256 indexed tokenId, address indexed recipient, uint256 amount);

    event NFTStaked(address indexed nftContract, uint256 indexed tokenId, address indexed staker);
    event NFTUnstaked(address indexed nftContract, uint256 indexed tokenId, address indexed staker, uint256 accumulatedStakingTime);

    event TradingApprovalDelegated(address indexed owner, address indexed delegate);
    event TradingApprovalRemoved(address indexed owner, address indexed delegate);

    event FeesWithdrawn(address indexed to, uint256 amount);
    event RoyaltiesWithdrawn(address indexed recipient, uint256 amount);
    event FeePercentageUpdated(uint256 newPercentage);
    event RoyaltyPercentageUpdated(uint256 newPercentage);
    event OracleAddressUpdated(address indexed newOracle);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner || admins[msg.sender], "Not authorized admin");
        _;
    }

     modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Not authorized oracle");
        _;
    }

    modifier onlyListingCreator(uint256 _listingId) {
        require(listings[_listingId].seller == msg.sender || delegatedTradingApprovals[listings[_listingId].seller][msg.sender], "Not listing creator or delegate");
        _;
    }

    modifier onlyAuctionCreator(uint256 _auctionId) {
        require(auctions[_auctionId].seller == msg.sender || delegatedTradingApprovals[auctions[_auctionId].seller][msg.sender], "Not auction creator or delegate");
        _;
    }

    modifier onlyBundleListingCreator(uint256 _bundleListingId) {
        require(bundleListings[_bundleListingId].seller == msg.sender || delegatedTradingApprovals[bundleListings[_bundleListingId].seller][msg.sender], "Not bundle listing creator or delegate");
        _;
    }

    modifier onlyConditionalListingCreator(uint256 _conditionalListingId) {
        require(conditionalListings[_conditionalListingId].seller == msg.sender || delegatedTradingApprovals[conditionalListings[_conditionalListingId].seller][msg.sender], "Not conditional listing creator or delegate");
        _;
    }

    // --- Constructor ---

    constructor(uint256 _initialFeePercentage, uint256 _initialRoyaltyPercentage) {
        owner = msg.sender;
        require(_initialFeePercentage <= 10000, "Fee percentage out of bounds");
        feePercentage = _initialFeePercentage;
        require(_initialRoyaltyPercentage <= 10000, "Royalty percentage out of bounds");
        royaltyPercentage = _initialRoyaltyPercentage;
        oracleAddress = msg.sender; // Owner is initial oracle
    }

    // --- Admin Functions ---

    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 10000, "Fee percentage out of bounds");
        feePercentage = _feePercentage;
        emit FeePercentageUpdated(_feePercentage);
    }

    function withdrawFees(address payable _to, uint256 _amount) external onlyOwner {
        require(_amount > 0 && _amount <= accumulatedFees, "Invalid amount to withdraw");
        accumulatedFees -= _amount;
        _to.sendValue(_amount); // Use sendValue for safety
        emit FeesWithdrawn(_to, _amount);
    }

    function setRoyaltyPercentage(uint256 _royaltyPercentage) external onlyOwner {
        require(_royaltyPercentage <= 10000, "Royalty percentage out of bounds");
        royaltyPercentage = _royaltyPercentage;
        emit RoyaltyPercentageUpdated(_royaltyPercentage);
    }

    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Oracle address cannot be zero");
        oracleAddress = _oracle;
        emit OracleAddressUpdated(_oracle);
    }

    function grantAdminRole(address _admin) external onlyOwner {
        require(_admin != address(0), "Admin address cannot be zero");
        admins[_admin] = true;
        // Event could be added here
    }

    function revokeAdminRole(address _admin) external onlyOwner {
        require(_admin != address(0), "Admin address cannot be zero");
        admins[_admin] = false;
         // Event could be added here
    }

    // --- Marketplace Functions (Fixed Price) ---

    function listNFT(address _nftContract, uint256 _tokenId, uint256 _price) external {
        require(_price > 0, "Price must be greater than zero");
        require(_nftContract != address(0), "NFT contract address cannot be zero");

        IERC721 nft = IERC721(_nftContract);
        address ownerOfNFT = nft.ownerOf(_tokenId);

        require(ownerOfNFT == msg.sender || delegatedTradingApprovals[ownerOfNFT][msg.sender], "Not owner or delegate of NFT");
        require(nft.isApprovedForAll(ownerOfNFT, address(this)) || nft.getApproved(_tokenId) == address(this), "Marketplace not approved to transfer NFT");

        uint256 currentListingId = nextListingId++;
        listings[currentListingId] = Listing(
            currentListingId,
            ownerOfNFT, // Store the actual owner, not the delegate
            _nftContract,
            _tokenId,
            _price,
            ListingStatus.Active
        );
        userFixedListings[ownerOfNFT].push(currentListingId);

        emit ListingCreated(currentListingId, ownerOfNFT, _nftContract, _tokenId, _price);
    }

    function buyNFT(uint256 _listingId) external payable {
        Listing storage listing = listings[_listingId];
        require(listing.status == ListingStatus.Active, "Listing is not active");
        require(msg.value == listing.price, "Incorrect price");

        address seller = listing.seller;
        address buyer = msg.sender;
        address nftContract = listing.nftContract;
        uint256 tokenId = listing.tokenId;
        uint256 price = listing.price;

        listing.status = ListingStatus.Sold; // Mark as sold immediately

        // Calculate fees and royalties
        uint256 marketplaceFee = (price * feePercentage) / 10000;
        uint256 royaltyAmount = (price * royaltyPercentage) / 10000;
        uint256 sellerProceeds = price - marketplaceFee - royaltyAmount;

        accumulatedFees += marketplaceFee;
        // In a real system, you'd map royalties to the original creator or previous owners
        // For simplicity here, royalties go to the *seller* of this specific sale.
        // A more advanced system would use ERC2981 or a custom royalty registry.
        accumulatedRoyalties[seller] += royaltyAmount;


        // Transfer NFT to buyer
        IERC721(nftContract).safeTransferFrom(seller, buyer, tokenId);

        // Send funds (Checks-Effects-Interactions Pattern)
        (bool successSeller, ) = payable(seller).call{value: sellerProceeds}("");
        require(successSeller, "Failed to send ETH to seller");

        // Note: Fees and royalties are accumulated in the contract and withdrawn by owner/seller respectively.
        // This avoids multiple external calls within one function which can expose to re-entrancy.

        emit NFTBought(_listingId, buyer, seller, price);
    }

    function cancelListing(uint256 _listingId) external onlyListingCreator(_listingId) {
        Listing storage listing = listings[_listingId];
        require(listing.status == ListingStatus.Active, "Listing is not active");

        listing.status = ListingStatus.Cancelled;
        // The NFT remains with the seller/owner, approval to the marketplace might need to be revoked separately by the owner.
        // However, the marketplace logic prevents transfer if not listed/approved.

        emit ListingCancelled(_listingId);
    }

    // --- Marketplace Functions (Auction) ---

    function createAuction(address _nftContract, uint256 _tokenId, uint256 _minBid, uint64 _endTime) external {
        require(_minBid > 0, "Min bid must be greater than zero");
        require(_nftContract != address(0), "NFT contract address cannot be zero");
        require(_endTime > block.timestamp, "Auction end time must be in the future");

        IERC721 nft = IERC721(_nftContract);
        address ownerOfNFT = nft.ownerOf(_tokenId);

        require(ownerOfNFT == msg.sender || delegatedTradingApprovals[ownerOfNFT][msg.sender], "Not owner or delegate of NFT");
        require(nft.isApprovedForAll(ownerOfNFT, address(this)) || nft.getApproved(_tokenId) == address(this), "Marketplace not approved to transfer NFT");

        uint256 currentAuctionId = nextAuctionId++;
        auctions[currentAuctionId] = Auction(
            currentAuctionId,
            ownerOfNFT, // Store the actual owner, not the delegate
            _nftContract,
            _tokenId,
            _minBid,
            0, // highestBid
            payable(0), // highestBidder
            _endTime,
            AuctionStatus.Active
        );
        userAuctions[ownerOfNFT].push(currentAuctionId);

        emit AuctionCreated(currentAuctionId, ownerOfNFT, _nftContract, _tokenId, _minBid, _endTime);
    }

    function placeBid(uint256 _auctionId) external payable {
        Auction storage auction = auctions[_auctionId];
        require(auction.status == AuctionStatus.Active, "Auction is not active");
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(msg.value > auction.highestBid, "Bid must be higher than current highest bid");
        require(msg.value >= auction.minBid, "Bid must meet minimum bid");
        require(msg.sender != auction.seller, "Seller cannot bid on their own auction");

        // Refund previous highest bidder if exists
        if (auction.highestBidder != payable(0)) {
             (bool successRefund, ) = auction.highestBidder.call{value: auction.highestBid}("");
             require(successRefund, "Failed to refund previous bidder"); // Consider safer handling or manual claim
        }

        auction.highestBid = msg.value;
        auction.highestBidder = payable(msg.sender);

        emit BidPlaced(_auctionId, msg.sender, msg.value);
    }

    function settleAuction(uint256 _auctionId) external {
        Auction storage auction = auctions[_auctionId];
        require(auction.status == AuctionStatus.Active, "Auction is not active");
        require(block.timestamp >= auction.endTime, "Auction has not ended");
        require(auction.highestBidder != payable(0), "No bids were placed");

        address seller = auction.seller;
        address winner = auction.highestBidder;
        address nftContract = auction.nftContract;
        uint256 tokenId = auction.tokenId;
        uint256 winningBid = auction.highestBid;

        auction.status = AuctionStatus.Settled; // Mark as settled immediately

        // Calculate fees and royalties
        uint256 marketplaceFee = (winningBid * feePercentage) / 10000;
        uint256 royaltyAmount = (winningBid * royaltyPercentage) / 10000;
        uint256 sellerProceeds = winningBid - marketplaceFee - royaltyAmount;

        accumulatedFees += marketplaceFee;
        accumulatedRoyalties[seller] += royaltyAmount;

        // Transfer NFT to winner
        IERC721(nftContract).safeTransferFrom(seller, winner, tokenId);

        // Send proceeds to seller (Checks-Effects-Interactions Pattern)
        (bool successSeller, ) = payable(seller).call{value: sellerProceeds}("");
        require(successSeller, "Failed to send ETH to seller");

        emit AuctionSettled(_auctionId, winner, winningBid);
    }

     function cancelAuction(uint256 _auctionId) external onlyAuctionCreator(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        require(auction.status == AuctionStatus.Active, "Auction is not active");
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(auction.highestBidder == payable(0), "Cannot cancel auction with bids");

        auction.status = AuctionStatus.Cancelled;
        // NFT remains with seller

        emit AuctionCancelled(_auctionId);
    }

    // --- Marketplace Functions (Bundle) ---

    function listBundle(address[] memory _nftContracts, uint256[] memory _tokenIds, uint256 _totalPrice) external {
        require(_nftContracts.length > 0, "Bundle must contain at least one NFT");
        require(_nftContracts.length == _tokenIds.length, "NFT contract and token ID arrays must match length");
        require(_totalPrice > 0, "Bundle price must be greater than zero");

        address seller = msg.sender;
        // Check ownership and approval for all NFTs in the bundle
        for (uint i = 0; i < _nftContracts.length; i++) {
            address nftContract = _nftContracts[i];
            uint256 tokenId = _tokenIds[i];

            IERC721 nft = IERC721(nftContract);
            address ownerOfNFT = nft.ownerOf(tokenId);

            require(ownerOfNFT == seller || delegatedTradingApprovals[ownerOfNFT][seller], "Not owner or delegate of all NFTs in bundle");
            require(nft.isApprovedForAll(ownerOfNFT, address(this)) || nft.getApproved(tokenId) == address(this), "Marketplace not approved for all NFTs in bundle");
             // Ensure the seller is consistent across all NFTs in the bundle if delegation is used
            if (i > 0 && ownerOfNFT != bundleListings[nextBundleListingId].seller) {
                 // If delegation allows listing NFTs from different owners, this check would need adjustment.
                 // Assuming for simplicity all listed NFTs belong to the same owner or their delegate.
                 require(ownerOfNFT == bundleListings[nextBundleListingId].seller, "All NFTs in bundle must have the same owner");
            }
             if (i == 0) {
                 seller = ownerOfNFT; // Set the actual owner from the first NFT
             }
        }

        uint256 currentBundleListingId = nextBundleListingId++;
        bundleListings[currentBundleListingId] = BundleListing(
            currentBundleListingId,
            seller, // Store the actual owner
            _nftContracts,
            _tokenIds,
            _totalPrice,
            ListingStatus.Active
        );
        userBundleListings[seller].push(currentBundleListingId);

        emit BundleListingCreated(currentBundleListingId, seller, _nftContracts, _tokenIds, _totalPrice);
    }

    function buyBundle(uint256 _bundleListingId) external payable {
        BundleListing storage bundleListing = bundleListings[_bundleListingId];
        require(bundleListing.status == ListingStatus.Active, "Bundle listing is not active");
        require(msg.value == bundleListing.totalPrice, "Incorrect price");

        address seller = bundleListing.seller;
        address buyer = msg.sender;
        uint256 totalPrice = bundleListing.totalPrice;

        bundleListing.status = ListingStatus.Sold; // Mark as sold immediately

        // Calculate fees and royalties (applied to total bundle price)
        uint256 marketplaceFee = (totalPrice * feePercentage) / 10000;
        uint256 royaltyAmount = (totalPrice * royaltyPercentage) / 10000; // Simplistic: total royalty to bundle seller
        uint256 sellerProceeds = totalPrice - marketplaceFee - royaltyAmount;

        accumulatedFees += marketplaceFee;
        accumulatedRoyalties[seller] += royaltyAmount;

        // Transfer all NFTs in the bundle
        for (uint i = 0; i < bundleListing.nftContracts.length; i++) {
            IERC721(bundleListing.nftContracts[i]).safeTransferFrom(seller, buyer, bundleListing.tokenIds[i]);
        }

        // Send funds (Checks-Effects-Interactions Pattern)
        (bool successSeller, ) = payable(seller).call{value: sellerProceeds}("");
        require(successSeller, "Failed to send ETH to seller");

        emit BundleBought(_bundleListingId, buyer, seller, totalPrice);
    }

    function cancelBundleListing(uint256 _bundleListingId) external onlyBundleListingCreator(_bundleListingId) {
        BundleListing storage bundleListing = bundleListings[_bundleListingId];
        require(bundleListing.status == ListingStatus.Active, "Bundle listing is not active");

        bundleListing.status = ListingStatus.Cancelled;

        emit BundleListingCancelled(_bundleListingId);
    }

    // --- Marketplace Functions (Conditional) ---

    function listConditionalSale(address _nftContract, uint256 _tokenId, uint256 _price, address _requiredToken, uint256 _requiredAmount) external {
        require(_price > 0, "Price must be greater than zero");
        require(_nftContract != address(0), "NFT contract address cannot be zero");
        require(_requiredToken != address(0), "Required token address cannot be zero");
        require(_requiredAmount > 0, "Required token amount must be greater than zero");

        IERC721 nft = IERC721(_nftContract);
        address ownerOfNFT = nft.ownerOf(_tokenId);

        require(ownerOfNFT == msg.sender || delegatedTradingApprovals[ownerOfNFT][msg.sender], "Not owner or delegate of NFT");
        require(nft.isApprovedForAll(ownerOfNFT, address(this)) || nft.getApproved(_tokenId) == address(this), "Marketplace not approved to transfer NFT");

        uint256 currentConditionalListingId = nextConditionalListingId++;
        conditionalListings[currentConditionalListingId] = ConditionalListing(
            currentConditionalListingId,
            ownerOfNFT, // Store the actual owner
            _nftContract,
            _tokenId,
            _price,
            _requiredToken,
            _requiredAmount,
            ListingStatus.Active
        );
        userConditionalListings[ownerOfNFT].push(currentConditionalListingId);

        emit ConditionalListingCreated(currentConditionalListingId, ownerOfNFT, _nftContract, _tokenId, _price, _requiredToken, _requiredAmount);
    }

     function buyConditionalSale(uint256 _conditionalListingId) external payable {
        ConditionalListing storage conditionalListing = conditionalListings[_conditionalListingId];
        require(conditionalListing.status == ListingStatus.Active, "Conditional listing is not active");
        require(msg.value == conditionalListing.price, "Incorrect price");

        // Check buyer's required token balance
        IERC20 requiredToken = IERC20(conditionalListing.requiredToken);
        require(requiredToken.balanceOf(msg.sender) >= conditionalListing.requiredAmount, "Buyer does not meet required token balance");

        address seller = conditionalListing.seller;
        address buyer = msg.sender;
        address nftContract = conditionalListing.nftContract;
        uint256 tokenId = conditionalListing.tokenId;
        uint256 price = conditionalListing.price;

        conditionalListing.status = ListingStatus.Sold; // Mark as sold immediately

        // Calculate fees and royalties
        uint256 marketplaceFee = (price * feePercentage) / 10000;
        uint256 royaltyAmount = (price * royaltyPercentage) / 10000;
        uint256 sellerProceeds = price - marketplaceFee - royaltyAmount;

        accumulatedFees += marketplaceFee;
        accumulatedRoyalties[seller] += royaltyAmount;

        // Transfer NFT to buyer
        IERC721(nftContract).safeTransferFrom(seller, buyer, tokenId);

        // Send funds (Checks-Effects-Interactions Pattern)
        (bool successSeller, ) = payable(seller).call{value: sellerProceeds}("");
        require(successSeller, "Failed to send ETH to seller");

        emit ConditionalSaleBought(_conditionalListingId, buyer, seller, price);
    }

    function cancelConditionalSale(uint256 _conditionalListingId) external onlyConditionalListingCreator(_conditionalListingId) {
        ConditionalListing storage conditionalListing = conditionalListings[_conditionalListingId];
        require(conditionalListing.status == ListingStatus.Active, "Conditional listing is not active");

        conditionalListing.status = ListingStatus.Cancelled;

        emit ConditionalListingCancelled(_conditionalListingId);
    }

    // --- Dynamic NFT Functions ---

    function _getDynamicNFTData(address _nftContract, uint256 _tokenId) internal view returns (DynamicNFTData storage) {
         return dynamicNFTs[_nftContract][_tokenId];
    }

    function updateExternalFactor(int256 _factor) external onlyOracle {
        // This function is designed to be called by a trusted oracle address.
        // It simulates an external force influencing all dynamic NFTs' mood.
        // In a real system, _factor could be derived from off-chain data.
        // For simplicity, this update is global. A more complex system could apply it selectively.

        // Apply factor - e.g., adjust mood based on current mood and new factor
        // This example just *sets* a global mood effect. A real system would update per-NFT mood.
        // Let's update a dummy global factor for now. Per-NFT update is complex.
        // For this example, let's just store the factor and allow level calculation to use it.
        // We need a state variable for the global factor.
        // Let's add: int256 private globalExternalFactor;
        globalExternalFactor = _factor;
        // A more advanced approach would iterate or have NFTs pull the factor and update their own state.
        // Given gas costs, per-NFT updates triggered by a global event are often avoided.
        // Let's make NFT dynamics *pull* the factor when queried or acted upon.

        emit ExternalFactorUpdated(_factor);
    }
    int256 private globalExternalFactor; // State variable for the simulated oracle factor


    function levelUpNFT(address _nftContract, uint256 _tokenId) external {
        require(IERC721(_nftContract).ownerOf(_tokenId) == msg.sender, "Not owner of NFT");

        DynamicNFTData storage nftData = _getDynamicNFTData(_nftContract, _tokenId);

        // Simple level up cost logic - requires ETH
        uint256 currentLevel = nftData.level;
        uint256 cost = getLevelUpCost(currentLevel);
        require(msg.value >= cost, "Insufficient payment for level up");

        // Handle payment - send cost to contract owner (or burn, or distribute)
        // For simplicity, send excess back to sender if any, cost stays here (like fees)
        if (msg.value > cost) {
             (bool successRefund, ) = payable(msg.sender).call{value: msg.value - cost}("");
             require(successRefund, "Failed to refund excess ETH"); // Or revert
        }
         accumulatedFees += cost; // Treat level-up cost like a fee

        nftData.level++;
        nftData.lastDynamicUpdate = uint64(block.timestamp); // Mark update time

        emit NFTLeveledUp(_nftContract, _tokenId, nftData.level, msg.sender);
    }

    function getLevelUpCost(uint256 _currentLevel) public pure returns (uint256) {
        // Example cost function: linearly increasing cost
        // Cost = (Current Level + 1) * 0.01 ETH
        return (_currentLevel + 1) * 1e16; // 1e16 = 0.01 ETH in wei
    }

    // Internal helper to update dynamic state based on time/staking
    function _updateDynamicStateBasedOnTime(DynamicNFTData storage nftData) internal {
        uint64 lastUpdate = nftData.lastStakedAt > 0 ? nftData.lastStakedAt : nftData.lastDynamicUpdate;
        if (block.timestamp > lastUpdate) {
            uint64 timePassed = uint64(block.timestamp) - lastUpdate;
            // Accumulate staking time if staked
            if (nftData.lastStakedAt > 0) {
                 nftData.accumulatedStakingTime += timePassed;
            }
             // Simple mood decay/change over time + influenced by global factor
             // Mood changes based on time passed and external factor.
             // e.g., mood = mood * decayFactor + externalFactor * timeEffect
             // This is highly simplified; actual implementation needs careful math.
             // Let's simplify: mood adjusts slightly towards zero over time, pushed by factor.
             int256 moodChange = int256(timePassed / 3600) * (globalExternalFactor > 0 ? 1 : -1); // +1 or -1 mood per hour based on global factor direction
             if (globalExternalFactor == 0) {
                 // If no factor, mood decays towards 0
                 if (nftData.mood > 0) moodChange = -int256(timePassed / 7200); // -1 mood per 2 hours
                 else if (nftData.mood < 0) moodChange = int256(timePassed / 7200); // +1 mood per 2 hours
                 else moodChange = 0;
             }
             nftData.mood += moodChange;
            // Cap mood? e.g., between -100 and 100
             if (nftData.mood > 100) nftData.mood = 100;
             if (nftData.mood < -100) nftData.mood = -100;


            nftData.lastDynamicUpdate = uint64(block.timestamp); // Update timestamp after calculation
            if (nftData.lastStakedAt > 0) {
                nftData.lastStakedAt = uint64(block.timestamp); // Also update staked timestamp
            }
        }
    }

    function claimDynamicRewards(address _nftContract, uint256 _tokenId) external {
        // Example: Rewards based on level * mood (absolute value)
        // This could be a simple token reward (ERC20) or ETH.
        // For simplicity, let's simulate awarding ETH proportional to level * abs(mood)
        // A real system needs a reward pool or minting mechanism.
        // Here, we'll just log the potential reward amount.
        require(IERC721(_nftContract).ownerOf(_tokenId) == msg.sender, "Not owner of NFT");

        DynamicNFTData storage nftData = _getDynamicNFTData(_nftContract, _tokenId);
        _updateDynamicStateBasedOnTime(nftData); // Update state before claiming

        uint256 potentialReward = uint256(nftData.level) * uint256(nftData.mood > 0 ? nftData.mood : -nftData.mood);

        // A real system would transfer tokens/ETH or update a claimable balance here.
        // Example: transfer ERC20 rewards from a pool managed by the contract.
        // require(IERC20(rewardTokenAddress).transfer(msg.sender, potentialReward), "Reward transfer failed");

        // For this example, we'll just emit an event
        emit DynamicRewardsClaimed(_nftContract, _tokenId, msg.sender, potentialReward); // potentialReward is a placeholder value

        // Reset state or introduce cooldown? E.g., reset mood to 0 after claiming.
         nftData.mood = 0; // Reset mood after claiming rewards

        // This function is simplified; a real system would need a sustainable reward model.
    }

    function getNFTDynamicState(address _nftContract, uint256 _tokenId) public view returns (uint256 level, int256 mood, uint64 lastUpdate, uint64 lastStakedAt, uint256 accumulatedStakingTime, int256 currentExternalFactor) {
         DynamicNFTData storage nftData = dynamicNFTs[_nftContract][_tokenId];
         // Note: This view function doesn't change state, so the mood displayed might be slightly outdated until
         // _updateDynamicStateBasedOnTime is called by a transaction (like claimRewards or unstake).
         // A more precise getter would calculate the time effect but that would make it non-view and potentially expensive.
         // For simplicity, this getter returns the stored values.
         // You could add a helper *view* function to *calculate* potential mood based on time passed *since* last update.
         return (nftData.level, nftData.mood, nftData.lastDynamicUpdate, nftData.lastStakedAt, nftData.accumulatedStakingTime, globalExternalFactor);
    }

    // --- Staking Functions ---

    function stakeNFT(address _nftContract, uint256 _tokenId) external {
        IERC721 nft = IERC721(_nftContract);
        require(nft.ownerOf(_tokenId) == msg.sender, "Not owner of NFT");
        require(stakedNFTs[_nftContract][_tokenId] == address(0), "NFT is already staked");
        require(nft.isApprovedForAll(msg.sender, address(this)) || nft.getApproved(_tokenId) == address(this), "Marketplace not approved to transfer NFT");

        stakedNFTs[_nftContract][_tokenId] = msg.sender;
        DynamicNFTData storage nftData = _getDynamicNFTData(_nftContract, _tokenId);
        nftData.lastStakedAt = uint64(block.timestamp); // Record staking time

        // Transfer NFT into the marketplace contract
        nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        emit NFTStaked(_nftContract, _tokenId, msg.sender);
    }

    function unstakeNFT(address _nftContract, uint256 _tokenId) external {
        require(stakedNFTs[_nftContract][_tokenId] == msg.sender, "Not the staker of this NFT");

        DynamicNFTData storage nftData = _getDynamicNFTData(_nftContract, _tokenId);
        _updateDynamicStateBasedOnTime(nftData); // Update dynamic state based on staking duration

        address staker = msg.sender;
        stakedNFTs[_nftContract][_tokenId] = address(0); // Mark as unstaked
        nftData.lastStakedAt = 0; // Reset staking time marker

        // Transfer NFT back to the staker
        IERC721(_nftContract).safeTransferFrom(address(this), staker, _tokenId);

        emit NFTUnstaked(_nftContract, _tokenId, staker, nftData.accumulatedStakingTime);
        // Reset accumulated staking time after unstake if desired, or let it accumulate across stakes.
        // nftData.accumulatedStakingTime = 0; // Optional: reset time after unstake
    }

     function getNFTStakingDetails(address _nftContract, uint256 _tokenId) public view returns (address staker, uint64 lastStakedAt, uint256 accumulatedStakingTime) {
         address currentStaker = stakedNFTs[_nftContract][_tokenId];
         if (currentStaker == address(0)) {
             return (address(0), 0, 0);
         }
         DynamicNFTData storage nftData = dynamicNFTs[_nftContract][_tokenId];
         uint64 currentStakingDuration = nftData.lastStakedAt > 0 ? uint64(block.timestamp) - nftData.lastStakedAt : 0;
         return (currentStaker, nftData.lastStakedAt, nftData.accumulatedStakingTime + currentStakingDuration);
     }


    // --- Delegation Functions ---

    function delegateTradingApproval(address _delegate) external {
        require(_delegate != address(0), "Delegate address cannot be zero");
        delegatedTradingApprovals[msg.sender][_delegate] = true;
        emit TradingApprovalDelegated(msg.sender, _delegate);
    }

    function removeDelegateApproval(address _delegate) external {
        require(_delegate != address(0), "Delegate address cannot be zero");
        delegatedTradingApprovals[msg.sender][_delegate] = false;
        emit TradingApprovalRemoved(msg.sender, _delegate);
    }

    function isDelegate(address _owner, address _delegate) external view returns (bool) {
        return delegatedTradingApprovals[_owner][_delegate];
    }

    // --- Royalty Functions ---

    function withdrawRoyalties(address payable _to) external {
        uint256 amount = accumulatedRoyalties[msg.sender];
        require(amount > 0, "No accumulated royalties to withdraw");

        accumulatedRoyalties[msg.sender] = 0;
        _to.sendValue(amount); // Use sendValue for safety
        emit RoyaltiesWithdrawn(msg.sender, amount);
    }

    function getAccumulatedRoyalties(address _royaltyRecipient) external view returns (uint256) {
        return accumulatedRoyalties[_royaltyRecipient];
    }

    // --- Query Functions ---

    function getListingDetails(uint256 _listingId) public view returns (uint256 listingId, address seller, address nftContract, uint256 tokenId, uint256 price, ListingStatus status) {
        Listing storage listing = listings[_listingId];
        return (listing.listingId, listing.seller, listing.nftContract, listing.tokenId, listing.price, listing.status);
    }

     function getAuctionDetails(uint256 _auctionId) public view returns (uint256 auctionId, address seller, address nftContract, uint256 tokenId, uint256 minBid, uint256 highestBid, address highestBidder, uint64 endTime, AuctionStatus status) {
        Auction storage auction = auctions[_auctionId];
        return (auction.auctionId, auction.seller, auction.nftContract, auction.tokenId, auction.minBid, auction.highestBid, auction.highestBidder, auction.endTime, auction.status);
    }

    function getBundleListingDetails(uint256 _bundleListingId) public view returns (uint256 bundleListingId, address seller, address[] memory nftContracts, uint256[] memory tokenIds, uint256 totalPrice, ListingStatus status) {
        BundleListing storage bundleListing = bundleListings[_bundleListingId];
        return (bundleListing.bundleListingId, bundleListing.seller, bundleListing.nftContracts, bundleListing.tokenIds, bundleListing.totalPrice, bundleListing.status);
    }

    function getConditionalListingDetails(uint256 _conditionalListingId) public view returns (uint256 conditionalListingId, address seller, address nftContract, uint256 tokenId, uint256 price, address requiredToken, uint256 requiredAmount, ListingStatus status) {
        ConditionalListing storage conditionalListing = conditionalListings[_conditionalListingId];
        return (conditionalListing.conditionalListingId, conditionalListing.seller, conditionalListing.nftContract, conditionalListing.tokenId, conditionalListing.price, conditionalListing.requiredToken, conditionalListing.requiredAmount, conditionalListing.status);
    }

    function getUserListings(address _user) external view returns (uint256[] memory) {
        return userFixedListings[_user];
    }

     function getUserAuctions(address _user) external view returns (uint256[] memory) {
        return userAuctions[_user];
    }

    function getUserBundleListings(address _user) external view returns (uint256[] memory) {
        return userBundleListings[_user];
    }

    function getUserConditionalListings(address _user) external view returns (uint256[] memory) {
        return userConditionalListings[_user];
    }

     function getAccumulatedFees() external view returns (uint256) {
        return accumulatedFees;
    }

     function getOwner() external view returns (address) {
         return owner;
     }

     function getFeePercentage() external view returns (uint256) {
         return feePercentage;
     }

      function getRoyaltyPercentage() external view returns (uint256) {
         return royaltyPercentage;
     }

     function getOracleAddress() external view returns (address) {
         return oracleAddress;
     }

     function isAdmin(address _account) external view returns (bool) {
         return _account == owner || admins[_account];
     }
}
```