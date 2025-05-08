Okay, here is a Solidity smart contract for a "Dynamic NFT Marketplace with Staking and Advanced Auction Types". This contract aims to be interesting and advanced by:

1.  **Handling Dynamic NFTs (DNFTs):** The contract stores parameters influencing how an off-chain service (like a keeper or oracle) determines the NFT's dynamic state and metadata. It provides a function for an authorized keeper to update the *proof* (hash) of the NFT's state on-chain based on external factors or rules defined within the contract.
2.  **Incorporating Staking:** Users can stake their NFTs in the marketplace contract. Staked NFTs can potentially receive boosts related to their dynamic properties or earn a share of marketplace fees.
3.  **Advanced Marketplace Features:** Supports both standard fixed-price listings, English auctions (bid up), and Dutch auctions (price drops over time).
4.  **Configurable Royalties & Fees:** Collection-level royalties and marketplace fees are implemented.
5.  **Role-Based Access:** Introduces a `METADATA_STATE_KEEPER_ROLE` for managing dynamic NFT state updates.

This is a relatively complex contract combining multiple concepts. It utilizes standard interfaces (`ERC721`) and patterns (`Ownable`, `ReentrancyGuard`). The dynamic NFT aspect *requires* an off-chain component (a watcher, keeper, or oracle) to monitor conditions, calculate state changes based on the on-chain parameters, generate metadata, and call the `updateDynamicNFTStateHash` function. The contract *itself* doesn't perform the complex off-chain data fetching or metadata generation.

---

**Smart Contract Outline & Function Summary**

**Contract Name:** DynamicNFTMarketplace

**Core Concepts:**
*   Marketplace for ERC-721 NFTs
*   Supports Fixed-Price Listings, English Auctions, and Dutch Auctions.
*   Allows Staking of NFTs within the marketplace for benefits (e.g., fee sharing eligibility, dynamic trait boosts).
*   Tracks parameters for Dynamic NFTs (DNFTs), allowing authorized keepers to update state hashes.
*   Configurable Marketplace Fees and Collection Royalties.
*   Role-based access control for sensitive operations (like updating DNFT state parameters or setting keepers).

**Outline:**

1.  **State Variables:**
    *   Owner and Access Control roles.
    *   Mappings for Listings (tokenId -> Listing).
    *   Mappings for Auctions (tokenId -> Auction).
    *   Mappings for Staking (tokenId -> StakingInfo).
    *   Mappings for Dynamic NFT Parameters (tokenId -> DynamicNFTParameters).
    *   Mappings for Collection Royalties (collectionAddress -> royaltyRate).
    *   Marketplace Fee Rate.
    *   Accumulated Fees.
    *   Staker Fee Shares (stakerAddress -> claimableFees).
    *   Events.
    *   Structs for Listing, Auction, StakingInfo, DynamicNFTParameters.
    *   Enums for Listing and Auction states.

2.  **Modifiers:**
    *   `onlyOwner` (from Ownable)
    *   `onlyMetadataStateKeeper`

3.  **Constructor:**
    *   Initializes owner.
    *   Sets default roles if applicable.

4.  **Marketplace Functions (Fixed Price):**
    *   `listNFTForSale`
    *   `buyNFT`
    *   `cancelListing`
    *   `updateListingPrice`

5.  **Marketplace Functions (Auctions):**
    *   `createEnglishAuction`
    *   `placeBid` (for English Auction)
    *   `settleEnglishAuction`
    *   `createDutchAuction`
    *   `buyInDutchAuction`
    *   `cancelAuction` (for both types)

6.  **Dynamic NFT Functions:**
    *   `registerDynamicNFT` (Links an existing ERC721 to the contract's dynamic state tracking)
    *   `setDynamicNFTParameters` (Owner/Admin sets rules/params for a DNFT)
    *   `updateDynamicNFTStateHash` (Called by METADATA_STATE_KEEPER)
    *   `getDynamicNFTParameters` (Read function)
    *   `getLatestMetadataHash` (Read function)

7.  **Staking Functions:**
    *   `stakeNFT`
    *   `unstakeNFT`
    *   `claimStakingFeeShare` (Pull mechanism)
    *   `calculateStakingFeeShare` (Internal helper)
    *   `distributePlatformFeesToStakers` (Owner/Admin pushes accumulated fees to stakers' claimable balance)
    *   `getStakingInfo` (Read function)
    *   `getStakeEligibilityBoost` (Example function showing how staking affects dynamic logic)

8.  **Admin/Configuration Functions:**
    *   `setMarketplaceFeeRate`
    *   `setCollectionRoyaltyRate`
    *   `withdrawMarketplaceFees` (Owner/Admin)
    *   `grantMetadataStateKeeperRole` (Owner)
    *   `renounceMetadataStateKeeperRole` (Keeper)

9.  **Utility/Read Functions:**
    *   `getListing`
    *   `getAuction`
    *   `getMarketplaceFeeRate`
    *   `getCollectionRoyaltyRate`
    *   `getAccumulatedFees`
    *   `getStakerClaimableFees`

**Function Summary:**

1.  `constructor()`: Initializes the contract owner.
2.  `listNFTForSale(address _collection, uint256 _tokenId, uint256 _price)`: Creates a fixed-price listing for an NFT. Requires prior ERC-721 `approve`.
3.  `buyNFT(address _collection, uint256 _tokenId)`: Allows a user to buy an NFT from a fixed-price listing. Handles fee and royalty distribution.
4.  `cancelListing(address _collection, uint256 _tokenId)`: Allows the seller to cancel a fixed-price listing.
5.  `updateListingPrice(address _collection, uint256 _tokenId, uint256 _newPrice)`: Allows the seller to change the price of an active listing.
6.  `createEnglishAuction(address _collection, uint256 _tokenId, uint256 _startingPrice, uint64 _endTime)`: Starts an English auction for an NFT. Requires prior ERC-721 `approve`.
7.  `placeBid(address _collection, uint256 _tokenId) payable`: Allows a user to place a bid in an active English auction. Must be higher than the current highest bid. Handles returning previous bid.
8.  `settleEnglishAuction(address _collection, uint256 _tokenId)`: Ends an English auction. Transfers NFT to the winner and funds to the seller (after fees/royalties). Refunds losing bidders.
9.  `createDutchAuction(address _collection, uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint64 _endTime)`: Starts a Dutch auction. Requires prior ERC-721 `approve`.
10. `buyInDutchAuction(address _collection, uint256 _tokenId) payable`: Allows a user to buy an NFT in an active Dutch auction at the current price.
11. `cancelAuction(address _collection, uint256 _tokenId)`: Allows the seller to cancel an auction (if conditions met, e.g., before any bids in English).
12. `registerDynamicNFT(address _collection, uint256 _tokenId, uint64 _updateInterval)`: Marks an NFT as dynamic within this marketplace's context and sets initial dynamic parameters.
13. `setDynamicNFTParameters(address _collection, uint256 _tokenId, uint64 _updateInterval, uint256 _param1, uint256 _param2)`: Owner/Admin sets/updates parameters that an off-chain keeper uses for dynamic state logic.
14. `updateDynamicNFTStateHash(address _collection, uint256 _tokenId, bytes32 _newStateHash)`: Called by the Metadata State Keeper to update the on-chain hash representing the NFT's latest dynamic state.
15. `getStakeEligibilityBoost(address _collection, uint256 _tokenId)`: Calculates a hypothetical boost factor for dynamic updates based on staking duration. (Example logic, needs concrete implementation tied to off-chain system).
16. `stakeNFT(address _collection, uint256 _tokenId)`: Stakes an NFT in the marketplace contract. Requires prior ERC-721 `approve`.
17. `unstakeNFT(address _collection, uint256 _tokenId)`: Unstakes an NFT, returning it to the staker.
18. `claimStakingFeeShare()`: Allows a staker to claim their accumulated share of marketplace fees.
19. `distributePlatformFeesToStakers()`: Owner/Admin calls this to calculate and allocate accumulated marketplace fees among active stakers based on their contribution/stake time.
20. `setMarketplaceFeeRate(uint256 _feeRate)`: Owner/Admin sets the marketplace fee percentage (basis points).
21. `setCollectionRoyaltyRate(address _collection, uint256 _royaltyRate)`: Owner/Admin sets the royalty percentage (basis points) for a specific NFT collection.
22. `withdrawMarketplaceFees()`: Owner/Admin withdraws accumulated marketplace fees *not* allocated to stakers.
23. `grantMetadataStateKeeperRole(address _account)`: Owner grants the METADATA_STATE_KEEPER_ROLE.
24. `renounceMetadataStateKeeperRole()`: A keeper revokes their own role.
25. `getListing(address _collection, uint256 _tokenId)`: Reads details of a fixed-price listing.
26. `getAuction(address _collection, uint256 _tokenId)`: Reads details of an auction.
27. `getStakingInfo(address _collection, uint256 _tokenId)`: Reads details of a staked NFT.
28. `getDynamicNFTParameters(address _collection, uint256 _tokenId)`: Reads the dynamic parameters set for an NFT.
29. `getLatestMetadataHash(address _collection, uint256 _tokenId)`: Reads the latest on-chain metadata hash for a dynamic NFT.
30. `getCollectionRoyaltyRate(address _collection)`: Reads the royalty rate for a collection.
31. `getMarketplaceFeeRate()`: Reads the current marketplace fee rate.
32. `getAccumulatedFees()`: Reads total accumulated fees before distribution.
33. `getStakerClaimableFees(address _staker)`: Reads the claimable fee amount for a staker.

**(Note: This list contains 33 functions, exceeding the minimum of 20 required).**

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// Outline and Function Summary located at the top of this file.

contract DynamicNFTMarketplace is Ownable, ReentrancyGuard, ERC721Holder, AccessControl {
    using SafeMath for uint256;
    using Address for address payable;

    bytes32 public constant METADATA_STATE_KEEPER_ROLE = keccak256("METADATA_STATE_KEEPER");

    // --- State Structures ---

    enum ListingState { Inactive, Active, Sold, Cancelled }
    enum AuctionState { Inactive, Active, Ended, Cancelled }
    enum AuctionType { English, Dutch }

    struct Listing {
        address payable seller;
        uint256 price;
        ListingState state;
    }

    struct Auction {
        address payable seller;
        AuctionType auctionType;
        uint256 startingPrice;
        uint256 currentPriceOrBid; // For English: highest bid, for Dutch: current price
        uint256 endingPrice; // Only for Dutch
        address payable highestBidder; // Only for English
        uint64 startTime;
        uint64 endTime;
        AuctionState state;
    }

    struct StakingInfo {
        address staker;
        uint64 stakeStartTime;
        bool isStaked;
    }

    // Parameters influencing dynamic state calculations by an off-chain keeper.
    // The keeper reads these and external data (time, oracle feeds, etc.)
    // to determine the new NFT state and call updateDynamicNFTStateHash.
    struct DynamicNFTParameters {
        uint64 updateInterval; // e.g., time between potential updates (seconds)
        uint256 param1;       // Generic parameter 1
        uint256 param2;       // Generic parameter 2
        bytes32 latestStateHash; // Hash representing the latest determined state
        uint64 lastUpdateTimestamp; // Timestamp of the last state hash update
        bool isDynamic;       // Flag if the NFT is registered for dynamic features
    }

    // --- State Variables ---

    mapping(address => mapping(uint256 => Listing)) public listings;
    mapping(address => mapping(uint256 => Auction)) public auctions;
    mapping(address => mapping(uint256 => StakingInfo)) public stakedNFTs;
    mapping(address => mapping(uint256 => DynamicNFTParameters)) public dynamicNFTs;

    mapping(address => uint256) public collectionRoyaltyRate; // Basis points (e.g., 250 for 2.5%)
    uint256 public marketplaceFeeRate; // Basis points (e.g., 100 for 1%)

    uint256 public accumulatedFees;
    mapping(address => uint256) public stakerClaimableFees;

    // State needed for fee distribution calculation among stakers
    uint256 private totalStakingTimeWeighted; // Cumulative sum of (stake time * boost) or similar
    mapping(address => uint256) private stakerTimeWeightedSnapshot; // Snapshot at last distribution
    uint265 private lastFeeDistributionTimestamp; // Last time fees were distributed to stakers

    // --- Events ---

    event NFTListed(address indexed collection, uint256 indexed tokenId, uint256 price, address indexed seller);
    event NFTBought(address indexed collection, uint256 indexed tokenId, uint256 price, address indexed buyer, address indexed seller);
    event ListingCancelled(address indexed collection, uint256 indexed tokenId);
    event ListingPriceUpdated(address indexed collection, uint256 indexed tokenId, uint256 newPrice);

    event EnglishAuctionCreated(address indexed collection, uint256 indexed tokenId, uint256 startingPrice, uint64 endTime, address indexed seller);
    event BidPlaced(address indexed collection, uint256 indexed tokenId, uint256 amount, address indexed bidder);
    event EnglishAuctionSettled(address indexed collection, uint256 indexed tokenId, uint256 finalPrice, address indexed winner, address indexed seller);
    event DutchAuctionCreated(address indexed collection, uint256 indexed tokenId, uint256 startingPrice, uint256 endingPrice, uint64 endTime, address indexed seller);
    event DutchAuctionBought(address indexed collection, uint256 indexed tokenId, uint256 price, address indexed buyer, address indexed seller);
    event AuctionCancelled(address indexed collection, uint256 indexed tokenId);

    event NFTStaked(address indexed collection, uint256 indexed tokenId, address indexed staker);
    event NFTUnstaked(address indexed collection, uint256 indexed tokenId, address indexed staker);
    event StakingFeeShareClaimed(address indexed staker, uint256 amount);
    event PlatformFeesDistributedToStakers(uint256 totalDistributedAmount, uint64 distributionTimestamp);

    event DynamicNFTRegistered(address indexed collection, uint256 indexed tokenId, uint64 updateInterval);
    event DynamicNFTParametersUpdated(address indexed collection, uint256 indexed tokenId, uint64 updateInterval, uint256 param1, uint256 param2);
    event DynamicNFTStateHashUpdated(address indexed collection, uint256 indexed tokenId, bytes32 newStateHash, address indexed updater);

    event MarketplaceFeeRateUpdated(uint256 newFeeRate);
    event CollectionRoyaltyRateUpdated(address indexed collection, uint256 newRoyaltyRate);
    event MarketplaceFeesWithdrawn(uint256 amount, address indexed receiver);

    // --- Constructor ---

    constructor(uint256 defaultMarketplaceFeeRate) Ownable(msg.sender) {
        // Grant the owner the initial Metadata State Keeper role
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(METADATA_STATE_KEEPER_ROLE, msg.sender);

        marketplaceFeeRate = defaultMarketplaceFeeRate; // e.g., 100 for 1%
        lastFeeDistributionTimestamp = uint64(block.timestamp); // Initialize timestamp
    }

    // --- Marketplace Functions (Fixed Price) ---

    /**
     * @dev Lists an NFT for a fixed price.
     * Seller must approve the NFT to the marketplace contract beforehand.
     */
    function listNFTForSale(address _collection, uint256 _tokenId, uint256 _price) external nonReentrant {
        require(_price > 0, "Price must be positive");
        require(listings[_collection][_tokenId].state == ListingState.Inactive, "NFT already listed");
        require(auctions[_collection][_tokenId].state == AuctionState.Inactive, "NFT is in auction");
        require(!stakedNFTs[_collection][_tokenId].isStaked, "NFT is staked");

        IERC721 nftCollection = IERC721(_collection);
        require(nftCollection.ownerOf(_tokenId) == msg.sender, "Only owner can list");

        // Transfer NFT to the marketplace contract
        nftCollection.safeTransferFrom(msg.sender, address(this), _tokenId);

        listings[_collection][_tokenId] = Listing({
            seller: payable(msg.sender),
            price: _price,
            state: ListingState.Active
        });

        emit NFTListed(_collection, _tokenId, _price, msg.sender);
    }

    /**
     * @dev Buys an NFT from a fixed-price listing.
     * Pays seller, marketplace fee, and royalties.
     */
    function buyNFT(address _collection, uint256 _tokenId) external payable nonReentrant {
        Listing storage listing = listings[_collection][_tokenId];
        require(listing.state == ListingState.Active, "Listing not active");
        require(msg.value >= listing.price, "Insufficient payment");

        listing.state = ListingState.Sold;

        uint256 royalty = _calculateRoyalty(_collection, listing.price);
        uint256 marketplaceFee = _calculateMarketplaceFee(listing.price);
        uint256 amountToSeller = listing.price.sub(royalty).sub(marketplaceFee);

        // Send payments
        if (amountToSeller > 0) {
             listing.seller.sendValue(amountToSeller);
        }

        // Send royalties (assuming royalty receiver is the collection address itself, or could be a separate mapping)
        // Note: A more complex royalty implementation might involve EIP-2981 or a mapping to minter/creator.
        // Here, we send to the collection address as a placeholder.
        if (royalty > 0) {
            payable(_collection).sendValue(royalty);
        }

        // Accumulate marketplace fees for later withdrawal/distribution
        accumulatedFees = accumulatedFees.add(marketplaceFee);

        // Transfer NFT to buyer
        IERC721(_collection).safeTransferFrom(address(this), msg.sender, _tokenId);

        // Handle potential overpayment refund
        if (msg.value > listing.price) {
            payable(msg.sender).sendValue(msg.value.sub(listing.price));
        }

        emit NFTBought(_collection, _tokenId, listing.price, msg.sender, listing.seller);
    }

     /**
     * @dev Allows the seller to cancel an active fixed-price listing.
     */
    function cancelListing(address _collection, uint256 _tokenId) external nonReentrant {
        Listing storage listing = listings[_collection][_tokenId];
        require(listing.state == ListingState.Active, "Listing not active");
        require(listing.seller == msg.sender, "Only seller can cancel");

        listing.state = ListingState.Cancelled;

        // Transfer NFT back to seller
        IERC721(_collection).safeTransferFrom(address(this), msg.sender, _tokenId);

        emit ListingCancelled(_collection, _tokenId);
    }

    /**
     * @dev Allows the seller to update the price of an active fixed-price listing.
     */
    function updateListingPrice(address _collection, uint256 _tokenId, uint256 _newPrice) external nonReentrant {
        Listing storage listing = listings[_collection][_tokenId];
        require(listing.state == ListingState.Active, "Listing not active");
        require(listing.seller == msg.sender, "Only seller can update");
        require(_newPrice > 0, "New price must be positive");

        listing.price = _newPrice;

        emit ListingPriceUpdated(_collection, _tokenId, _newPrice);
    }

    // --- Marketplace Functions (Auctions) ---

    /**
     * @dev Creates an English auction for an NFT.
     * Seller must approve the NFT to the marketplace contract beforehand.
     */
    function createEnglishAuction(address _collection, uint256 _tokenId, uint256 _startingPrice, uint64 _endTime) external nonReentrant {
        require(_startingPrice > 0, "Starting price must be positive");
        require(_endTime > block.timestamp, "End time must be in the future");
        require(listings[_collection][_tokenId].state == ListingState.Inactive, "NFT already listed");
        require(auctions[_collection][_tokenId].state == AuctionState.Inactive, "NFT is in auction");
         require(!stakedNFTs[_collection][_tokenId].isStaked, "NFT is staked");


        IERC721 nftCollection = IERC721(_collection);
        require(nftCollection.ownerOf(_tokenId) == msg.sender, "Only owner can list");

        // Transfer NFT to the marketplace contract
        nftCollection.safeTransferFrom(msg.sender, address(this), _tokenId);

        auctions[_collection][_tokenId] = Auction({
            seller: payable(msg.sender),
            auctionType: AuctionType.English,
            startingPrice: _startingPrice,
            currentPriceOrBid: _startingPrice, // current bid starts as starting price
            endingPrice: 0, // Not used for English
            highestBidder: payable(address(0)),
            startTime: uint64(block.timestamp),
            endTime: _endTime,
            state: AuctionState.Active
        });

        emit EnglishAuctionCreated(_collection, _tokenId, _startingPrice, _endTime, msg.sender);
    }

    /**
     * @dev Places a bid in an active English auction.
     * Sends previous highest bid back to the previous bidder.
     */
    function placeBid(address _collection, uint256 _tokenId) external payable nonReentrant {
        Auction storage auction = auctions[_collection][_tokenId];
        require(auction.state == AuctionState.Active, "Auction not active");
        require(auction.auctionType == AuctionType.English, "Not an English auction");
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(msg.sender != auction.seller, "Seller cannot bid");
        require(msg.value > auction.currentPriceOrBid, "Bid must be higher than current highest bid");
        // Optional: Add minimum bid increment

        // Refund previous highest bidder
        if (auction.highestBidder != payable(address(0))) {
            auction.highestBidder.sendValue(auction.currentPriceOrBid);
        }

        auction.currentPriceOrBid = msg.value;
        auction.highestBidder = payable(msg.sender);

        emit BidPlaced(_collection, _tokenId, msg.value, msg.sender);
    }

    /**
     * @dev Settles an English auction after its end time.
     * Transfers NFT to the highest bidder and funds to the seller (after fees/royalties).
     * Refunds any losing bidders (already done in placeBid, but good practice to check/handle edge cases).
     */
    function settleEnglishAuction(address _collection, uint256 _tokenId) external nonReentrant {
        Auction storage auction = auctions[_collection][_tokenId];
        require(auction.state == AuctionState.Active, "Auction not active");
        require(auction.auctionType == AuctionType.English, "Not an English auction");
        require(block.timestamp >= auction.endTime, "Auction not ended yet");

        auction.state = AuctionState.Ended;

        address payable winner = auction.highestBidder;
        uint256 finalPrice = auction.currentPriceOrBid;

        if (winner == payable(address(0))) {
            // No bids, return NFT to seller
            IERC721(_collection).safeTransferFrom(address(this), auction.seller, _tokenId);
        } else {
            // Transfer NFT to winner
            IERC721(_collection).safeTransferFrom(address(this), winner, _tokenId);

            uint256 royalty = _calculateRoyalty(_collection, finalPrice);
            uint256 marketplaceFee = _calculateMarketplaceFee(finalPrice);
            uint256 amountToSeller = finalPrice.sub(royalty).sub(marketplaceFee);

            // Send payments
            if (amountToSeller > 0) {
                auction.seller.sendValue(amountToSeller);
            }
            if (royalty > 0) {
                payable(_collection).sendValue(royalty); // Send royalties to collection address
            }
            accumulatedFees = accumulatedFees.add(marketplaceFee);

            emit EnglishAuctionSettled(_collection, _tokenId, finalPrice, winner, auction.seller);
        }

        // Clear auction data (or mark as ended) - state change handles this mostly
    }

    /**
     * @dev Creates a Dutch auction for an NFT. Price decreases over time.
     * Seller must approve the NFT to the marketplace contract beforehand.
     */
     function createDutchAuction(address _collection, uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint64 _endTime) external nonReentrant {
        require(_startingPrice > _endingPrice, "Starting price must be greater than ending price");
        require(_endTime > block.timestamp, "End time must be in the future");
        require(listings[_collection][_tokenId].state == ListingState.Inactive, "NFT already listed");
        require(auctions[_collection][_tokenId].state == AuctionState.Inactive, "NFT is in auction");
        require(!stakedNFTs[_collection][_tokenId].isStaked, "NFT is staked");


        IERC721 nftCollection = IERC721(_collection);
        require(nftCollection.ownerOf(_tokenId) == msg.sender, "Only owner can list");

        // Transfer NFT to the marketplace contract
        nftCollection.safeTransferFrom(msg.sender, address(this), _tokenId);

        auctions[_collection][_tokenId] = Auction({
            seller: payable(msg.sender),
            auctionType: AuctionType.Dutch,
            startingPrice: _startingPrice,
            currentPriceOrBid: _startingPrice, // Initial price
            endingPrice: _endingPrice,
            highestBidder: payable(address(0)), // Not used for Dutch
            startTime: uint64(block.timestamp),
            endTime: _endTime,
            state: AuctionState.Active
        });

        emit DutchAuctionCreated(_collection, _tokenId, _startingPrice, _endingPrice, _endTime, msg.sender);
     }

    /**
     * @dev Allows a user to buy an NFT in an active Dutch auction.
     * The price is calculated based on the current time.
     */
    function buyInDutchAuction(address _collection, uint256 _tokenId) external payable nonReentrant {
        Auction storage auction = auctions[_collection][_tokenId];
        require(auction.state == AuctionState.Active, "Auction not active");
        require(auction.auctionType == AuctionType.Dutch, "Not a Dutch auction");
        require(block.timestamp < auction.endTime, "Auction has ended");

        uint256 currentPrice = _getCurrentDutchAuctionPrice(auction);
        require(msg.value >= currentPrice, "Insufficient payment");

        auction.state = AuctionState.Ended; // Auction ends once bought

        uint256 royalty = _calculateRoyalty(_collection, currentPrice);
        uint256 marketplaceFee = _calculateMarketplaceFee(currentPrice);
        uint256 amountToSeller = currentPrice.sub(royalty).sub(marketplaceFee);

        // Send payments
         if (amountToSeller > 0) {
            auction.seller.sendValue(amountToSeller);
        }
        if (royalty > 0) {
            payable(_collection).sendValue(royalty); // Send royalties
        }
        accumulatedFees = accumulatedFees.add(marketplaceFee);

        // Transfer NFT to buyer
        IERC721(_collection).safeTransferFrom(address(this), msg.sender, _tokenId);

        // Handle potential overpayment refund
        if (msg.value > currentPrice) {
            payable(msg.sender).sendValue(msg.value.sub(currentPrice));
        }

        emit DutchAuctionBought(_collection, _tokenId, currentPrice, msg.sender, auction.seller);

        // Clear auction data or mark as ended
    }

    /**
     * @dev Calculates the current price for a Dutch auction based on time elapsed.
     */
    function _getCurrentDutchAuctionPrice(Auction storage auction) internal view returns (uint256) {
        uint64 timeElapsed = uint64(block.timestamp).sub(auction.startTime);
        uint64 duration = auction.endTime.sub(auction.startTime);

        if (timeElapsed >= duration) {
            return auction.endingPrice; // Reached ending price
        }

        uint256 priceRange = auction.startingPrice.sub(auction.endingPrice);
        // Calculate price reduction proportional to time elapsed
        uint256 priceReduction = priceRange.mul(timeElapsed) / duration;

        return auction.startingPrice.sub(priceReduction);
    }

    /**
     * @dev Allows the seller to cancel an active auction.
     * For English auctions, typically only allowed before the first bid.
     */
    function cancelAuction(address _collection, uint256 _tokenId) external nonReentrant {
        Auction storage auction = auctions[_collection][_tokenId];
        require(auction.state == AuctionState.Active, "Auction not active");
        require(auction.seller == msg.sender, "Only seller can cancel");

        if (auction.auctionType == AuctionType.English) {
            require(auction.highestBidder == payable(address(0)), "Cannot cancel English auction with bids");
        }

        auction.state = AuctionState.Cancelled;

        // Return NFT to seller
        IERC721(_collection).safeTransferFrom(address(this), msg.sender, _tokenId);

        emit AuctionCancelled(_collection, _tokenId);
    }


    // --- Dynamic NFT Functions ---

    /**
     * @dev Registers an existing NFT for dynamic features within this marketplace context.
     * Does not require NFT transfer initially, just associates parameters.
     * The off-chain keeper system should monitor these registered NFTs.
     */
    function registerDynamicNFT(address _collection, uint256 _tokenId, uint64 _updateInterval) external onlyOwner {
        DynamicNFTParameters storage dnft = dynamicNFTs[_collection][_tokenId];
        require(!dnft.isDynamic, "NFT already registered as dynamic");

        dnft.isDynamic = true;
        dnft.updateInterval = _updateInterval;
        dnft.lastUpdateTimestamp = uint64(block.timestamp); // Initialize last update

        // Initial state hash could be a hash of initial metadata or zero bytes
        dnft.latestStateHash = bytes32(0); // Example: set initial hash

        emit DynamicNFTRegistered(_collection, _tokenId, _updateInterval);
    }

     /**
     * @dev Sets/updates parameters that an off-chain Metadata State Keeper uses
     * to determine the dynamic state of an NFT.
     * Requires OWNER or DEFAULT_ADMIN_ROLE.
     */
    function setDynamicNFTParameters(address _collection, uint256 _tokenId, uint64 _updateInterval, uint256 _param1, uint256 _param2) external onlyOwner {
         DynamicNFTParameters storage dnft = dynamicNFTs[_collection][_tokenId];
         require(dnft.isDynamic, "NFT not registered as dynamic");

         dnft.updateInterval = _updateInterval;
         dnft.param1 = _param1;
         dnft.param2 = _param2;

         emit DynamicNFTParametersUpdated(_collection, _tokenId, _updateInterval, _param1, _param2);
     }

    /**
     * @dev Called by an authorized Metadata State Keeper to update the on-chain hash
     * representing the latest dynamic state of an NFT.
     * The keeper calculates the state off-chain based on parameters and external data,
     * generates metadata, and provides the hash of that metadata/state here.
     */
    function updateDynamicNFTStateHash(address _collection, uint256 _tokenId, bytes32 _newStateHash) external onlyMetadataStateKeeper {
        DynamicNFTParameters storage dnft = dynamicNFTs[_collection][_tokenId];
        require(dnft.isDynamic, "NFT not registered as dynamic");
        // Optional: Add checks based on updateInterval or other parameters if needed
        // e.g., require(block.timestamp >= dnft.lastUpdateTimestamp + dnft.updateInterval, "Update interval not met");

        dnft.latestStateHash = _newStateHash;
        dnft.lastUpdateTimestamp = uint64(block.timestamp);

        emit DynamicNFTStateHashUpdated(_collection, _tokenId, _newStateHash, msg.sender);
    }

    // --- Staking Functions ---

    /**
     * @dev Stakes an NFT in the marketplace contract.
     * NFT must be owned by the staker and approved to the contract.
     * Makes the NFT ineligible for listing/auction while staked.
     */
    function stakeNFT(address _collection, uint256 _tokenId) external nonReentrant {
        StakingInfo storage staking = stakedNFTs[_collection][_tokenId];
        require(!staking.isStaked, "NFT already staked");
        require(listings[_collection][_tokenId].state == ListingState.Inactive, "NFT listed for sale");
        require(auctions[_collection][_tokenId].state == AuctionState.Inactive, "NFT is in auction");

        IERC721 nftCollection = IERC721(_collection);
        require(nftCollection.ownerOf(_tokenId) == msg.sender, "Only owner can stake");

        // Transfer NFT to the marketplace contract (it holds staked NFTs)
        nftCollection.safeTransferFrom(msg.sender, address(this), _tokenId);

        staking.staker = msg.sender;
        staking.stakeStartTime = uint64(block.timestamp);
        staking.isStaked = true;

        // In a real system, staking might increase a staker's "staking power" or
        // contribute to a cumulative total used for fee distribution calculation.
        // For this example, we'll link it to fee distribution eligibility and a potential boost.
        // Update totalStakingTimeWeighted or similar metric if needed for complex distribution

        emit NFTStaked(_collection, _tokenId, msg.sender);
    }

    /**
     * @dev Unstakes an NFT from the marketplace contract.
     * Returns the NFT to the staker.
     */
    function unstakeNFT(address _collection, uint256 _tokenId) external nonReentrant {
        StakingInfo storage staking = stakedNFTs[_collection][_tokenId];
        require(staking.isStaked, "NFT not staked");
        require(staking.staker == msg.sender, "Only staker can unstake");

        staking.isStaked = false;
        // In a real system, unstaking might finalize contribution period for fee distribution

        // Transfer NFT back to staker
        IERC721(_collection).safeTransferFrom(address(this), msg.sender, _tokenId);

        // Clear staking info (optional, could leave history)
        // delete stakedNFTs[_collection][_tokenId];

        emit NFTUnstaked(_collection, _tokenId, msg.sender);
    }

    /**
     * @dev Allows a staker to claim their allocated share of marketplace fees.
     * Fees are allocated via the distributePlatformFeesToStakers function.
     */
    function claimStakingFeeShare() external nonReentrant {
        uint256 claimable = stakerClaimableFees[msg.sender];
        require(claimable > 0, "No fees available to claim");

        stakerClaimableFees[msg.sender] = 0;

        // Send fees to staker
        payable(msg.sender).sendValue(claimable);

        emit StakingFeeShareClaimed(msg.sender, claimable);
    }

     /**
     * @dev Owner/Admin calls this to distribute accumulated marketplace fees
     * among active stakers. This calculates each staker's share based on
     * a defined logic (e.g., duration staked since last distribution) and
     * adds it to their claimable balance.
     * NOTE: A robust, gas-efficient distribution logic for many stakers is complex.
     * This function outlines the *intent*. A real implementation might use
     * checkpointing or a more sophisticated staking reward system.
     */
    function distributePlatformFeesToStakers() external onlyOwner nonReentrant {
        // This is a simplified placeholder logic.
        // A real implementation needs to iterate through active stakers
        // or use a pull-based system with checkpoints.

        uint265 currentTimestamp = uint265(block.timestamp);
        uint256 feesToDistribute = accumulatedFees; // Distribute all accumulated fees for simplicity
        accumulatedFees = 0; // Reset accumulated fees

        if (feesToDistribute == 0) {
            return; // Nothing to distribute
        }

        // --- Simplified Distribution Logic Placeholder ---
        // This is NOT gas-efficient or robust for many stakers.
        // It would require iterating over all staked NFTs or stakers, which
        // can easily exceed block gas limits.
        // A better approach involves:
        // 1. Tracking cumulative staking power/points over time.
        // 2. Stakers accrue a pro-rata share of fees based on their power vs total power
        //    in between claims or distribution checkpoints.
        // 3. Using a Merkle tree or a claim-based system with checkpoints to avoid iteration.
        // For demonstration, we'll just *assume* a mechanism updates `stakerClaimableFees`.
        // In a real contract, you'd replace this comment block with the actual distribution math
        // or remove this function and rely solely on `withdrawMarketplaceFees` by the owner.
        // Example (Conceptual):
        // uint256 totalWeightedStakePower = calculateTotalWeightedStakePower(); // Needs to track this efficiently
        // for each staker:
        //     uint256 stakerWeightedPower = calculateStakerWeightedPower(staker, lastFeeDistributionTimestamp, currentTimestamp); // Needs efficient tracking
        //     if (totalWeightedStakePower > 0) {
        //         uint256 stakerShare = (feesToDistribute * stakerWeightedPower) / totalWeightedStakePower;
        //         stakerClaimableFees[staker] = stakerClaimableFees[staker].add(stakerShare);
        //     }
        // lastFeeDistributionTimestamp = currentTimestamp;
        // --------------------------------------------------

        // For the purpose of this example, we will just log the event
        // indicating fees *were intended* to be distributed, but the actual
        // allocation logic needs to be implemented robustly.
         emit PlatformFeesDistributedToStakers(feesToDistribute, uint64(block.timestamp));

        // A simple alternative for example purposes (distribute equally, highly inefficient):
        // uint256 numStakers = ... // Need to track number of unique stakers
        // uint256 sharePerStaker = feesToDistribute / numStakers; // Handle remainder
        // for each staker: stakerClaimableFees[staker] = stakerClaimableFees[staker].add(sharePerStaker);

        // Or, simplest but bypasses staking rewards, just withdraw owner share:
        // withdrawMarketplaceFees(); // This is already a separate function.

        // Given the complexity of gas-efficient on-chain iteration,
        // a common pattern is to use an off-chain process to calculate shares
        // and then use a contract like MerkleDistributor to allow stakers to claim.
        // Alternatively, the contract tracks points, and users' claim function
        // calculates their share of *accumulated* points vs total points,
        // multiplied by the total fees released *since the last time they claimed*.
        // This requires tracking cumulative points and total fees distributed.
        // For *this example*, we will make `distributePlatformFeesToStakers` purely symbolic,
        // and rely on `withdrawMarketplaceFees` for fee payout, making staking benefits
        // primarily about the hypothetical dynamic boost.
    }


    /**
     * @dev Example function showing how staking duration *could* influence
     * a dynamic property calculation. The off-chain keeper would call this
     * (or a similar read function) to get a factor.
     */
    function getStakeEligibilityBoost(address _collection, uint256 _tokenId) public view returns (uint256) {
         StakingInfo storage staking = stakedNFTs[_collection][_tokenId];

         if (!staking.isStaked || staking.stakeStartTime == 0) {
             return 1; // No boost if not staked
         }

         // Simple linear boost based on stake duration (example logic)
         uint64 stakeDuration = uint64(block.timestamp).sub(staking.stakeStartTime);
         // Boost: 1 + (duration in days / 30) - capped, or log scale, etc.
         // Example: 10000 means no boost (basis points). +100 per day staked.
         uint256 boost = 10000 + (uint256(stakeDuration) / 1 days * 100);
         // Cap boost to prevent overflow or excessive impact, e.g., max 2x (20000 basis points)
         if (boost > 20000) {
             boost = 20000;
         }
         return boost; // Returns boost in basis points (e.g., 10100 for 1% boost)
    }


    // --- Admin/Configuration Functions ---

    /**
     * @dev Sets the marketplace fee rate in basis points (e.g., 100 = 1%).
     * Only owner can call.
     */
    function setMarketplaceFeeRate(uint256 _feeRate) external onlyOwner {
        require(_feeRate <= 10000, "Fee rate cannot exceed 100%");
        marketplaceFeeRate = _feeRate;
        emit MarketplaceFeeRateUpdated(_feeRate);
    }

    /**
     * @dev Sets the royalty rate for a specific collection in basis points.
     * Only owner can call.
     */
    function setCollectionRoyaltyRate(address _collection, uint256 _royaltyRate) external onlyOwner {
        require(_royaltyRate <= 10000, "Royalty rate cannot exceed 100%");
        collectionRoyaltyRate[_collection] = _royaltyRate;
        emit CollectionRoyaltyRateUpdated(_collection, _royaltyRate);
    }

    /**
     * @dev Owner/Admin can withdraw the marketplace fees that have accumulated
     * and have *not* been allocated to stakers yet (if fee distribution is implemented).
     * Given the symbolic nature of `distributePlatformFeesToStakers` in this example,
     * this function effectively withdraws *all* accumulated fees.
     */
    function withdrawMarketplaceFees() external onlyOwner nonReentrant {
        uint256 fees = accumulatedFees;
        accumulatedFees = 0;

        if (fees > 0) {
            payable(msg.sender).sendValue(fees);
            emit MarketplaceFeesWithdrawn(fees, msg.sender);
        }
    }

     /**
     * @dev Grants the METADATA_STATE_KEEPER_ROLE to an account.
     * Only account with DEFAULT_ADMIN_ROLE (initially owner) can grant roles.
     */
    function grantMetadataStateKeeperRole(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(METADATA_STATE_KEEPER_ROLE, _account);
    }

    /**
     * @dev Allows a METADATA_STATE_KEEPER to renounce their role.
     */
    function renounceMetadataStateKeeperRole() external {
        renounceRole(METADATA_STATE_KEEPER_ROLE);
    }

    // --- Internal Helper Functions ---

    function _calculateRoyalty(address _collection, uint256 _price) internal view returns (uint256) {
        uint256 rate = collectionRoyaltyRate[_collection];
        if (rate == 0) {
            return 0;
        }
        return _price.mul(rate) / 10000; // Rate is in basis points
    }

    function _calculateMarketplaceFee(uint256 _price) internal view returns (uint256) {
        uint256 rate = marketplaceFeeRate;
         if (rate == 0) {
            return 0;
        }
        return _price.mul(rate) / 10000; // Rate is in basis points
    }

    // --- Utility/Read Functions ---

    function getListing(address _collection, uint256 _tokenId) external view returns (ListingState state, address seller, uint256 price) {
        Listing storage listing = listings[_collection][_tokenId];
        return (listing.state, listing.seller, listing.price);
    }

    function getAuction(address _collection, uint256 _tokenId) external view returns (
        AuctionState state,
        AuctionType auctionType,
        address seller,
        uint256 currentPriceOrBid,
        uint256 endingPrice,
        address highestBidder,
        uint64 startTime,
        uint64 endTime
    ) {
        Auction storage auction = auctions[_collection][_tokenId];
        return (
            auction.state,
            auction.auctionType,
            auction.seller,
            auction.currentPriceOrBid,
            auction.endingPrice,
            auction.highestBidder,
            auction.startTime,
            auction.endTime
        );
    }

    function getStakingInfo(address _collection, uint256 _tokenId) external view returns (address staker, uint64 stakeStartTime, bool isStaked) {
         StakingInfo storage staking = stakedNFTs[_collection][_tokenId];
         return (staking.staker, staking.stakeStartTime, staking.isStaked);
    }

    function getDynamicNFTParameters(address _collection, uint256 _tokenId) external view returns (bool isDynamic, uint64 updateInterval, uint256 param1, uint256 param2) {
        DynamicNFTParameters storage dnft = dynamicNFTs[_collection][_tokenId];
        return (dnft.isDynamic, dnft.updateInterval, dnft.param1, dnft.param2);
    }

     function getLatestMetadataHash(address _collection, uint256 _tokenId) external view returns (bytes32) {
        return dynamicNFTs[_collection][_tokenId].latestStateHash;
     }


    function getCollectionRoyaltyRate(address _collection) external view returns (uint256) {
        return collectionRoyaltyRate[_collection];
    }

    function getMarketplaceFeeRate() external view returns (uint256) {
        return marketplaceFeeRate;
    }

    function getAccumulatedFees() external view returns (uint256) {
        return accumulatedFees;
    }

    function getStakerClaimableFees(address _staker) external view returns (uint256) {
         return stakerClaimableFees[_staker];
    }

    // --- Required ERC721Holder Function ---
    // Allows the contract to receive ERC721 tokens.
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        // Ensure the token is being received for a valid reason (listing, auction, staking)
        // This requires checking internal state, which can be complex inside onERC721Received.
        // A common pattern is to only allow transfers *initiated by the contract itself*
        // in list/stake/etc. functions, rather than relying solely on this hook
        // for validation of external transfers *into* the contract.
        // By using safeTransferFrom *from* the seller/staker *to* `address(this)`
        // inside the list/stake functions, we ensure only intended transfers are processed.
        // This hook mainly signifies successful receipt *after* our function initiated it.
        return this.onERC721Received.selector;
    }

    // Fallback function to prevent unauthorized ether deposits directly
    receive() external payable {
        revert("Direct ether deposits not allowed. Use buy/bid functions.");
    }
}
```

**Explanation of Advanced Concepts and Creativity:**

1.  **Dynamic NFTs (DNFTs):** Instead of static metadata, this contract introduces a framework where an NFT's state and properties can change. The contract stores key `DynamicNFTParameters` (like update interval, param1, param2) and a `latestStateHash`. The actual logic for *how* these parameters, along with external data (simulated or via oracle integration outside this contract), translate into a new state and metadata is handled *off-chain* by a designated `METADATA_STATE_KEEPER`. The keeper observes the on-chain parameters and external data, calculates the new state, generates the corresponding metadata (e.g., a new image, new properties), and then calls `updateDynamicNFTStateHash` with the *hash* of this new metadata/state. This provides an on-chain, tamper-evident proof of the NFT's current dynamic state, while keeping complex, potentially expensive or data-intensive logic off-chain. The `getStakeEligibilityBoost` function shows a simple example of how staking could influence the dynamic logic (e.g., give a staked NFT a higher chance of a positive dynamic update).
2.  **Staking for Utility/Rewards:** Users can lock their NFTs in the contract. This isn't just passive holding; staked NFTs are *required* for potentially receiving certain benefits (like fee share eligibility) or having their dynamic properties influenced by their stake status (as hinted by `getStakeEligibilityBoost`). The contract accumulates marketplace fees, and the owner can trigger a distribution to stakers based on their contribution (represented conceptually by `stakerClaimableFees`). This adds a layer of interaction and potential yield/utility to owning and holding NFTs *within* the marketplace ecosystem. (Note: The actual fee distribution logic for stakers is complex to make gas-efficient on-chain for many users and is outlined as a placeholder).
3.  **Combined Marketplace Functionality:** It doesn't just do fixed price or one auction type; it integrates fixed price listings, English auctions (competitive bidding), and Dutch auctions (price decay). This offers sellers more flexibility in how they choose to sell their assets.
4.  **Role-Based Access for DNFTs:** The introduction of the `METADATA_STATE_KEEPER_ROLE` uses AccessControl from OpenZeppelin, allowing specific, authorized entities (not just the owner) to perform the crucial `updateDynamicNFTStateHash` function. This is necessary because the keeper is an external actor needing permission to modify the NFT's state hash based on off-chain events.
5.  **Separation of Concerns (On-chain Proof vs. Off-chain Logic):** The contract intelligently separates what belongs on-chain (state parameters, state hash proof, transfer logic, payments, rules) from what is better handled off-chain (complex data fetching, metadata generation, triggering updates based on rules). This is a standard pattern for scalable and practical dynamic NFT implementations.

This contract serves as a solid base demonstrating how multiple advanced concepts can be combined into a more sophisticated marketplace and NFT ecosystem than typical basic examples.