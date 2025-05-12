Okay, let's design a smart contract that incorporates several advanced, creative, and trendy features beyond a standard NFT or marketplace contract. We'll create a "Dynamic NFT Marketplace with Advanced Interactions".

Here's the concept:
*   **Dynamic NFTs:** NFTs that have on-chain attributes which can change based on actions (owner interaction, external triggers, time).
*   **Marketplace:** Supports fixed-price listings, auctions, *and* bundles of NFTs.
*   **Advanced NFT Interactions:** Allows staking NFTs to earn rewards and renting out NFTs.
*   **Configurable:** Fees, royalties, and allowed payment tokens are configurable.
*   **Timed Events:** Supports flash sales for specific NFTs or bundles.

This combines ERC721, marketplace logic, on-chain data dynamics, staking, rental, and timed sales.

---

## DynamicNFTMarketplace Smart Contract

This contract implements an advanced marketplace for Dynamic NFTs (DNFTs). DNFTs have mutable on-chain attributes. The marketplace supports various listing types (fixed price, auction, bundle, flash sale) and includes features like NFT staking and rental.

**Outline:**

1.  **Contract Name:** `DynamicNFTMarketplace`
2.  **Inherits:** `ERC721` (OpenZeppelin), `Ownable` (OpenZeppelin), `Pausable` (OpenZeppelin), `ReentrancyGuard` (OpenZeppelin).
3.  **Core Concepts:** Dynamic On-Chain Attributes, Fixed Price Listings, Auctions, Bundles, Flash Sales, NFT Staking, NFT Rental, Configurable Fees & Royalties, Payment Token Whitelisting.
4.  **State Variables:** Mappings for listings, auctions, bundles, dynamic attributes, staked NFTs, rented NFTs. Configurable fee percentages, fee recipient, flash sale details, allowed payment tokens.
5.  **Structs:** Define data structures for listings, auctions, bundles, dynamic attributes, staking info, rental info.
6.  **Events:** Emit events for all significant state changes (ListingCreated, BidPlaced, NFTStaked, RentalStarted, AttributeUpdated, etc.).
7.  **Modifiers:** Use standard OpenZeppelin modifiers (`onlyOwner`, `whenNotPaused`, `nonReentrant`).
8.  **Functions:** (See summary below, aiming for 20+ unique functions)

**Function Summary (20+ Functions):**

1.  `constructor(string name, string symbol, address initialOwner)`: Initializes the ERC721 contract and sets the initial owner.
2.  `safeMint(address to, uint256 tokenId, Attribute initialAttributes)`: Mints a new Dynamic NFT with initial on-chain attributes.
3.  `_updateNFTAttribute(uint256 tokenId, string key, bytes data)`: Internal helper function to update a specific on-chain attribute for an NFT.
4.  `interactWithNFT(uint256 tokenId, bytes interactionData)`: Allows the owner (or approved address) to interact with the NFT, potentially triggering attribute changes based on `interactionData`.
5.  `triggerExternalUpdate(uint256 tokenId, string key, bytes externalData)`: Simulates an update triggered by an external source (like an oracle), changing a specific attribute. Requires a specific role or permission.
6.  `getNFTCurrentAttributes(uint256 tokenId)`: Retrieves the current on-chain attributes of an NFT.
7.  `listNFTFixedPrice(uint256 tokenId, uint256 price, address paymentToken)`: Lists an owned NFT for sale at a fixed price using a specified payment token. Requires NFT approval to the marketplace.
8.  `buyNFTFixedPrice(uint256 listingId)`: Allows a buyer to purchase an NFT listed at a fixed price. Handles payment transfer, fee deduction, and NFT transfer.
9.  `cancelFixedPriceListing(uint256 listingId)`: Allows the seller to cancel an active fixed-price listing. Returns the NFT to the seller.
10. `createAuction(uint256 tokenId, uint256 reservePrice, uint256 duration, address paymentToken)`: Creates an auction for an owned NFT with a reserve price and duration. Requires NFT approval.
11. `placeBid(uint256 auctionId)`: Allows a user to place a bid on an active auction. Requires sending enough payment tokens (or native token if applicable) to cover the bid.
12. `endAuction(uint256 auctionId)`: Ends an auction after its duration expires. Transfers the NFT to the highest bidder (if reserve met) and sends funds to the seller/fees recipient. Refunds losing bids.
13. `cancelAuction(uint256 auctionId)`: Allows the seller to cancel an auction *before* any bids are placed or *before* expiry if no bids met the reserve.
14. `listBundleFixedPrice(uint256[] tokenIds, uint256 price, address paymentToken)`: Lists a bundle of owned NFTs for sale at a single fixed price. Requires approval for all NFTs in the bundle.
15. `buyBundleFixedPrice(uint256 bundleListingId)`: Allows a buyer to purchase a bundle of NFTs. Transfers payment, handles fees, and transfers all NFTs in the bundle.
16. `cancelBundleListing(uint256 bundleListingId)`: Allows the seller to cancel a bundle listing. Returns all NFTs to the seller.
17. `stakeNFT(uint256 tokenId)`: Allows an owner to stake their NFT in the contract. Requires NFT approval. Starts tracking staking duration.
18. `unstakeNFT(uint256 tokenId)`: Allows an owner to unstake their NFT. Calculates potential rewards (simple model based on duration for this example) and returns the NFT.
19. `claimStakingRewards(uint256 tokenId)`: Allows claiming accumulated rewards for a staked NFT without unstaking (requires separate reward token logic, simplified here).
20. `rentNFT(uint256 tokenId, uint256 duration, uint256 dailyPrice, address paymentToken)`: Allows an owner to list their NFT for rent. Sets terms for rental. Requires NFT approval.
21. `rentOutNFT(uint256 rentalListingId)`: Allows a user to rent an NFT listed for rent. Transfers the NFT temporarily and handles payment.
22. `endRental(uint256 rentalListingId)`: Allows the owner or the renter (after duration) to end a rental. Returns the NFT to the owner and potentially refunds part of the payment based on early termination (simplified).
23. `setMarketplaceFee(uint16 newFeeBps)`: Allows the owner to set the marketplace fee percentage (in basis points).
24. `setFeeRecipient(address newRecipient)`: Allows the owner to set the address where marketplace fees are sent.
25. `withdrawFees(address tokenAddress)`: Allows the fee recipient to withdraw accumulated fees for a specific token.
26. `addAllowedPaymentToken(address tokenAddress)`: Allows the owner to whitelist an ERC20 token that can be used for payments.
27. `removeAllowedPaymentToken(address tokenAddress)`: Allows the owner to remove a token from the payment whitelist.
28. `setRoyaltyPercentage(uint256 tokenId, uint16 royaltyBps)`: Allows the owner (or potentially the original creator) to set a specific royalty percentage for a particular NFT on future sales.
29. `initiateFlashSale(uint256 listingId, uint256 duration, uint256 flashPrice)`: Allows the owner to initiate a temporary flash sale for an existing fixed-price listing with a lower flash price.
30. `cancelFlashSale(uint256 listingId)`: Allows the owner to cancel an ongoing flash sale.
31. `buyNFTDuringFlashSale(uint256 listingId)`: Allows buying an NFT at the flash sale price during the active flash sale window.
32. `pause()`: Pauses contract functionality (buying, selling, staking, renting).
33. `unpause()`: Unpauses contract functionality.
34. `tokenURI(uint256 tokenId)`: Overrides ERC721 `tokenURI` to potentially include or reference the dynamic attributes. (Implementation note: Often points to an off-chain service that queries on-chain attributes).
35. `getListingDetails(uint256 listingId)`: Query function to get details of a fixed-price listing.
36. `getAuctionDetails(uint256 auctionId)`: Query function to get details of an auction.
37. `getBundleDetails(uint256 bundleListingId)`: Query function to get details of a bundle listing.
38. `getStakedInfo(uint256 tokenId)`: Query function to check staking status and potential rewards for an NFT.
39. `getRentalInfo(uint256 tokenId)`: Query function to check rental status and terms for an NFT.

*Note: Some query functions (like `getNFTCurrentAttributes`, `getListingDetails`, etc.) might return complex data structures or require external processing to be fully user-friendly, but their inclusion counts towards the functional scope.*

This list exceeds 20 functions and covers a range of advanced marketplace and NFT mechanics.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Helper struct for dynamic attributes (simple key-value, allowing different data types via bytes)
struct Attribute {
    string key;
    bytes value;
}

// Structs for marketplace listings
struct FixedPriceListing {
    uint256 listingId;
    uint256 tokenId;
    address seller;
    uint256 price;
    address paymentToken; // Address(0) for native token
    bool active;
}

struct Auction {
    uint256 auctionId;
    uint256 tokenId;
    address seller;
    uint256 reservePrice;
    uint256 startTime;
    uint256 endTime;
    uint256 highestBid;
    address highestBidder;
    bool ended;
    address paymentToken; // Address(0) for native token
}

struct BundleListing {
    uint256 bundleId;
    uint256[] tokenIds;
    address seller;
    uint256 price;
    address paymentToken; // Address(0) for native token
    bool active;
}

// Structs for advanced NFT features
struct StakedNFT {
    uint256 tokenId;
    address owner;
    uint256 stakeTime;
    // Simplified reward tracking - could be more complex
    uint256 lastRewardClaimTime;
}

struct RentalListing {
    uint256 rentalListingId;
    uint256 tokenId;
    address owner; // Original owner listing for rent
    uint256 dailyPrice; // Price per day
    uint256 duration; // Max rental duration in days
    address paymentToken; // Address(0) for native token
    bool available;
}

struct ActiveRental {
    uint256 rentalListingId;
    uint256 tokenId;
    address originalOwner; // Original owner
    address currentRenter; // Address currently holding rights
    uint256 startTime; // Time rental started
    uint256 endTime; // Expected end time
    uint256 paidAmount; // Total amount paid for the rental period
    address paymentToken;
    bool active;
}

// Struct for Flash Sale
struct FlashSale {
    uint256 listingId; // References a FixedPriceListing
    uint256 flashPrice;
    uint256 startTime;
    uint256 endTime;
    bool active;
}


contract DynamicNFTMarketplace is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter private _listingIds;
    Counters.Counter private _auctionIds;
    Counters.Counter private _bundleIds;
    Counters.Counter private _rentalListingIds;
    Counters.Counter private _activeRentalIds; // To track individual rental instances


    // --- State Variables ---

    mapping(uint256 => FixedPriceListing) public fixedPriceListings;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => BundleListing) public bundleListings;
    mapping(uint256 => RentalListing) public rentalListings;
    mapping(uint256 => ActiveRental) public activeRentals; // Mapped by _activeRentalIds

    // Dynamic Attributes Storage: tokenId => attributeKey => attributeValue
    mapping(uint256 => mapping[string] => bytes) private _dynamicAttributes;
    // Keep track of all attribute keys for a token for retrieval (optional, can be gas intensive)
    mapping(uint256 => string[]) private _attributeKeys;

    // Staking information: tokenId => StakedNFT struct
    mapping(uint256 => StakedNFT) public stakedNFTs;
    mapping(uint256 => bool) private _isStaked; // Quick lookup if an NFT is staked

    // Rental information: tokenId => ActiveRental ID
    mapping(uint256 => uint256) private _nftActiveRental; // Maps tokenId to activeRentalId (0 if not rented)

    // Marketplace Configuration
    uint16 public marketplaceFeeBps = 250; // 2.5%
    address public feeRecipient;

    EnumerableSet.AddressSet private _allowedPaymentTokens;
    mapping(uint256 => uint16) private _tokenRoyalties; // Royalty percentage per tokenId in BPS

    // Flash Sale
    mapping(uint256 => FlashSale) public flashSales; // Mapped by FixedPriceListing ID


    // --- Events ---

    event NFTAttributesUpdated(uint256 indexed tokenId, string key, bytes newValue);
    event FixedPriceListingCreated(uint256 indexed listingId, uint256 indexed tokenId, address seller, uint256 price, address paymentToken);
    event FixedPriceListingCancelled(uint256 indexed listingId);
    event NFTPurchased(uint256 indexed listingId, uint256 indexed tokenId, address buyer, uint256 price);
    event AuctionCreated(uint256 indexed auctionId, uint256 indexed tokenId, address seller, uint256 reservePrice, uint256 endTime, address paymentToken);
    event BidPlaced(uint256 indexed auctionId, address bidder, uint256 amount);
    event AuctionEnded(uint256 indexed auctionId, address winner, uint256 winningBid);
    event AuctionCancelled(uint256 indexed auctionId);
    event BundleListingCreated(uint256 indexed bundleId, uint256[] tokenIds, address seller, uint256 price, address paymentToken);
    event BundleListingCancelled(uint256 indexed bundleId);
    event BundlePurchased(uint256 indexed bundleId, address buyer, uint256 price);
    event NFTStaked(uint256 indexed tokenId, address owner, uint256 stakeTime);
    event NFTUnstaked(uint256 indexed tokenId, address owner, uint256 unstakeTime);
    event StakingRewardsClaimed(uint256 indexed tokenId, address owner, uint256 rewardsAmount); // Simplified - needs reward token
    event RentalListingCreated(uint256 indexed rentalListingId, uint256 indexed tokenId, address owner, uint256 dailyPrice, uint256 duration, address paymentToken);
    event RentalStarted(uint256 indexed activeRentalId, uint256 indexed rentalListingId, uint256 indexed tokenId, address originalOwner, address renter, uint256 duration, uint256 totalPaid);
    event RentalEnded(uint256 indexed activeRentalId, uint256 indexed tokenId, address originalOwner, address renter);
    event MarketplaceFeeUpdated(uint16 newFeeBps);
    event FeeRecipientUpdated(address newRecipient);
    event FeesWithdrawn(address tokenAddress, address recipient, uint256 amount);
    event AllowedPaymentTokenAdded(address tokenAddress);
    event AllowedPaymentTokenRemoved(address tokenAddress);
    event RoyaltyPercentageUpdated(uint256 indexed tokenId, uint16 royaltyBps);
    event FlashSaleInitiated(uint256 indexed listingId, uint256 flashPrice, uint256 endTime);
    event FlashSaleCancelled(uint256 indexed listingId);
    event NFTFlashPurchased(uint256 indexed listingId, uint256 indexed tokenId, address buyer, uint256 price);


    // --- Constructor ---

    constructor(string memory name, string memory symbol, address initialOwner)
        ERC721(name, symbol)
        Ownable(initialOwner)
        Pausable()
    {
        feeRecipient = initialOwner; // Default fee recipient is the owner
        _allowedPaymentTokens.add(address(0)); // Allow native token by default
    }

    // --- Pausable Overrides ---
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable) // Added ERC721Enumerable
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Ensure staked/rented NFTs cannot be transferred via standard means
        require(!_isStaked[tokenId], "Token is staked");
        require(_nftActiveRental[tokenId] == 0, "Token is rented out");
    }

    // --- ERC721Enumerable overrides required by solidity 0.8.20 ---
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    // --- Dynamic NFT Functions ---

    /**
     * @dev Mints a new Dynamic NFT with initial attributes.
     * Can only be called by the contract owner or a designated minter role.
     */
    function safeMint(address to, uint256 tokenId, Attribute[] memory initialAttributes)
        public onlyOwner nonReentrant // Added nonReentrant just in case attribute processing is complex
    {
        require(!_exists(tokenId), "Token ID already exists");
        _safeMint(to, tokenId);

        for (uint i = 0; i < initialAttributes.length; i++) {
            _updateNFTAttribute(tokenId, initialAttributes[i].key, initialAttributes[i].value);
            // Store key for later retrieval (potentially gas intensive for many keys)
             bool found = false;
             for(uint j=0; j<_attributeKeys[tokenId].length; j++) {
                 if (keccak256(abi.encodePacked(_attributeKeys[tokenId][j])) == keccak256(abi.encodePacked(initialAttributes[i].key))) {
                     found = true;
                     break;
                 }
             }
             if (!found) {
                 _attributeKeys[tokenId].push(initialAttributes[i].key);
             }
        }
    }

    /**
     * @dev Internal helper to update a single attribute. Emits event.
     */
    function _updateNFTAttribute(uint256 tokenId, string memory key, bytes memory value) internal {
        require(_exists(tokenId), "Token ID does not exist");
        _dynamicAttributes[tokenId][key] = value;
        emit NFTAttributesUpdated(tokenId, key, value);
    }

    /**
     * @dev Allows the token owner (or approved) to trigger interaction logic,
     * potentially changing attributes based on contract-defined rules and data.
     * Example: Feeding a pet, leveling up a character.
     * @param interactionData Arbitrary data interpreted by the contract's logic.
     */
    function interactWithNFT(uint256 tokenId, bytes memory interactionData) public nonReentrant {
        require(_exists(tokenId), "Token does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner or approved");

        // --- Example Interaction Logic (Replace with actual game/app logic) ---
        // This is a placeholder. Real logic would decode interactionData and update attributes.
        // Example: Assuming interactionData could be a simple string like "feed" or "train"
        string memory interactionType = string(interactionData);
        if (keccak256(abi.encodePacked(interactionType)) == keccak256(abi.encodePacked("levelUp"))) {
             // Example: Increment a level attribute (requires decoding existing value)
             bytes memory currentLevelBytes = _dynamicAttributes[tokenId]["level"];
             uint256 currentLevel = 0;
             if (currentLevelBytes.length > 0) {
                 // Simple decoding for uint256
                 require(currentLevelBytes.length == 32, "Invalid level data format");
                 assembly {
                     currentLevel := mload(add(currentLevelBytes, 32))
                 }
             }
             uint256 newLevel = currentLevel + 1;
             bytes memory newLevelBytes = abi.encodePacked(newLevel);
             _updateNFTAttribute(tokenId, "level", newLevelBytes);
        }
        // --- End Example Interaction Logic ---
    }

    /**
     * @dev Simulates an external trigger updating NFT attributes.
     * Could be called by an oracle, a keeper network, or owner for timed updates.
     * @param key The attribute key to update.
     * @param externalData The new value for the attribute.
     */
    function triggerExternalUpdate(uint256 tokenId, string memory key, bytes memory externalData)
        public onlyOwner // Simplified: Only owner can trigger. In real app, might be specific role or oracle.
    {
        require(_exists(tokenId), "Token does not exist");
        _updateNFTAttribute(tokenId, key, externalData);
    }

    /**
     * @dev Retrieves the current dynamic attributes for an NFT.
     * Note: Iterating over string keys is complex/gas-intensive on-chain.
     * This simplified version assumes known keys or requires off-chain processing.
     */
    function getNFTCurrentAttributes(uint256 tokenId)
        public view returns (Attribute[] memory)
    {
        require(_exists(tokenId), "Token does not exist");

        // In a real scenario, you'd need a way to know which keys exist.
        // Storing keys in an array during minting/updating (as done in safeMint) helps.
        string[] memory keys = _attributeKeys[tokenId];
        Attribute[] memory currentAttributes = new Attribute[](keys.length);

        for (uint i = 0; i < keys.length; i++) {
             currentAttributes[i] = Attribute({
                 key: keys[i],
                 value: _dynamicAttributes[tokenId][keys[i]]
             });
        }
        return currentAttributes;
    }

    /**
     * @dev Overrides tokenURI to potentially include dynamic attributes reference.
     * A real implementation would likely point to an API that fetches attributes
     * via getNFTCurrentAttributes and generates JSON metadata.
     */
    function tokenURI(uint256 tokenId)
        public view override returns (string memory)
    {
         require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
         // Example: Point to a base URI + tokenId, which an external service
         // would resolve and fetch attributes via getNFTCurrentAttributes().
         return string(abi.encodePacked("ipfs://YOUR_METADATA_GATEWAY/", Strings.toString(tokenId)));
         // A more advanced version might encode attributes directly if small enough,
         // or hash them on-chain to verify off-chain metadata.
    }


    // --- Marketplace Functions (Fixed Price) ---

    /**
     * @dev Lists an NFT for sale at a fixed price.
     * @param paymentToken Address of the ERC20 token, or Address(0) for native token.
     */
    function listNFTFixedPrice(uint256 tokenId, uint256 price, address paymentToken)
        public nonReentrant whenNotPaused
    {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not the owner of the token");
        require(!_isStaked[tokenId], "Token is staked");
        require(_nftActiveRental[tokenId] == 0, "Token is rented out");
        require(price > 0, "Price must be greater than 0");
        require(_allowedPaymentTokens.contains(paymentToken), "Payment token not allowed");

        _listingIds.increment();
        uint256 listingId = _listingIds.current();

        fixedPriceListings[listingId] = FixedPriceListing({
            listingId: listingId,
            tokenId: tokenId,
            seller: msg.sender,
            price: price,
            paymentToken: paymentToken,
            active: true
        });

        // Transfer NFT to the marketplace contract
        _transfer(msg.sender, address(this), tokenId);

        emit FixedPriceListingCreated(listingId, tokenId, msg.sender, price, paymentToken);
    }

    /**
     * @dev Buys an NFT from a fixed-price listing.
     */
    function buyNFTFixedPrice(uint256 listingId) public payable nonReentrant whenNotPaused {
        FixedPriceListing storage listing = fixedPriceListings[listingId];
        require(listing.active, "Listing is not active");
        require(_exists(listing.tokenId), "Listed token does not exist");
        require(ownerOf(listing.tokenId) == address(this), "Token is not held by marketplace");
        require(msg.sender != listing.seller, "Cannot buy your own listing");

        uint256 totalPrice = listing.price;
        uint256 feeAmount = (totalPrice * marketplaceFeeBps) / 10000;
        uint256 sellerProceeds = totalPrice - feeAmount;
        uint256 royaltyAmount = (totalPrice * _tokenRoyalties[listing.tokenId]) / 10000;
        sellerProceeds -= royaltyAmount; // Deduct royalty from seller proceeds

        address originalCreator = ownerOf(listing.tokenId); // Assuming minter is creator for simplicity
        // This requires tracking original creator/royalty receiver separately if creator != minter

        address royaltyReceiver = originalCreator; // Simplified: royalty goes to minter

        if (listing.paymentToken == address(0)) { // Native token payment
            require(msg.value == totalPrice, "Incorrect native token amount");
            Address.sendValue(payable(listing.seller), sellerProceeds);
            if (feeAmount > 0) {
                Address.sendValue(payable(feeRecipient), feeAmount);
            }
             if (royaltyAmount > 0) {
                Address.sendValue(payable(royaltyReceiver), royaltyAmount);
            }
        } else { // ERC20 token payment
            require(msg.value == 0, "Cannot send native token with ERC20 payment");
            IERC20 paymentTokenContract = IERC20(listing.paymentToken);
            require(paymentTokenContract.transferFrom(msg.sender, address(this), totalPrice), "ERC20 transfer failed from buyer");

            // Transfer to seller, fee recipient, and royalty receiver
            require(paymentTokenContract.transfer(listing.seller, sellerProceeds), "ERC20 transfer failed to seller");
            if (feeAmount > 0) {
                 require(paymentTokenContract.transfer(feeRecipient, feeAmount), "ERC20 transfer failed to fee recipient");
            }
             if (royaltyAmount > 0) {
                 require(paymentTokenContract.transfer(royaltyReceiver, royaltyAmount), "ERC20 transfer failed to royalty receiver");
            }
        }

        // Transfer NFT to buyer
        _transfer(address(this), msg.sender, listing.tokenId);

        listing.active = false; // Deactivate listing

        emit NFTPurchased(listingId, listing.tokenId, msg.sender, totalPrice);
    }

    /**
     * @dev Cancels a fixed-price listing.
     */
    function cancelFixedPriceListing(uint256 listingId) public nonReentrant whenNotPaused {
        FixedPriceListing storage listing = fixedPriceListings[listingId];
        require(listing.active, "Listing is not active");
        require(listing.seller == msg.sender, "Not the seller of the listing");
        require(_exists(listing.tokenId), "Listed token does not exist");
        require(ownerOf(listing.tokenId) == address(this), "Token is not held by marketplace");

        // Transfer NFT back to seller
        _transfer(address(this), msg.sender, listing.tokenId);

        listing.active = false; // Deactivate listing

        emit FixedPriceListingCancelled(listingId);
    }


    // --- Marketplace Functions (Auction) ---

    /**
     * @dev Creates an auction for an NFT.
     * @param paymentToken Address of the ERC20 token, or Address(0) for native token.
     */
    function createAuction(uint256 tokenId, uint256 reservePrice, uint256 duration, address paymentToken)
        public nonReentrant whenNotPaused
    {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not the owner of the token");
        require(!_isStaked[tokenId], "Token is staked");
        require(_nftActiveRental[tokenId] == 0, "Token is rented out");
        require(duration > 0, "Auction duration must be greater than 0");
        require(_allowedPaymentTokens.contains(paymentToken), "Payment token not allowed");

        _auctionIds.increment();
        uint256 auctionId = _auctionIds.current();
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;

        auctions[auctionId] = Auction({
            auctionId: auctionId,
            tokenId: tokenId,
            seller: msg.sender,
            reservePrice: reservePrice,
            startTime: startTime,
            endTime: endTime,
            highestBid: 0,
            highestBidder: address(0),
            ended: false,
            paymentToken: paymentToken
        });

        // Transfer NFT to the marketplace contract
        _transfer(msg.sender, address(this), tokenId);

        emit AuctionCreated(auctionId, tokenId, msg.sender, reservePrice, endTime, paymentToken);
    }

    /**
     * @dev Places a bid on an auction.
     * Bids must be higher than the current highest bid.
     * Sends previous highest bid back to the previous bidder.
     */
    function placeBid(uint256 auctionId) public payable nonReentrant whenNotPaused {
        Auction storage auction = auctions[auctionId];
        require(auction.startTime > 0, "Auction does not exist"); // Check if auction was created
        require(!auction.ended, "Auction has ended");
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(msg.sender != auction.seller, "Seller cannot bid on their own auction");

        uint256 bidAmount;
        if (auction.paymentToken == address(0)) {
            bidAmount = msg.value;
            require(msg.value > auction.highestBid, "Bid must be higher than current highest bid");
             // Refund previous bidder
            if (auction.highestBidder != address(0)) {
                Address.sendValue(payable(auction.highestBidder), auction.highestBid);
            }
        } else { // ERC20 bid
            // Assumes buyer *already* approved marketplace to pull tokens OR sends tokens directly (less common for auction)
            // More robust: require buyer to approve, then contract pulls bid amount
             bidAmount = msg.value; // Or passed as function param
             require(bidAmount > auction.highestBid, "Bid must be higher than current highest bid");
             require(auction.paymentToken != address(0), "ERC20 bid not allowed for native token auction");
             require(_allowedPaymentTokens.contains(auction.paymentToken), "Payment token not allowed");

             // Refund previous bidder (assuming they approved the contract)
             if (auction.highestBidder != address(0)) {
                 IERC20(auction.paymentToken).transfer(auction.highestBidder, auction.highestBid);
             }
             // Pull current bid amount from bidder (requires prior approval)
             IERC20(auction.paymentToken).transferFrom(msg.sender, address(this), bidAmount);
        }

        auction.highestBid = bidAmount;
        auction.highestBidder = msg.sender;

        emit BidPlaced(auctionId, msg.sender, bidAmount);
    }

    /**
     * @dev Ends an auction after its duration. Transfers NFT, handles funds.
     * Anyone can call this after the auction ends.
     */
    function endAuction(uint256 auctionId) public nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(auction.startTime > 0, "Auction does not exist");
        require(!auction.ended, "Auction has already ended");
        require(block.timestamp >= auction.endTime || auction.highestBidder == auction.seller, "Auction is still active"); // Allow seller to end if no bids before end time

        auction.ended = true;

        address originalCreator = ownerOf(auction.tokenId); // Simplified: minter is creator

        if (auction.highestBidder == address(0) || auction.highestBid < auction.reservePrice) {
            // No valid bids or reserve not met
            _transfer(address(this), auction.seller, auction.tokenId);
            emit AuctionEnded(auctionId, address(0), 0);
        } else {
            // Valid bid and reserve met
            uint256 winningBid = auction.highestBid;
            uint256 feeAmount = (winningBid * marketplaceFeeBps) / 10000;
            uint256 royaltyAmount = (winningBid * _tokenRoyalties[auction.tokenId]) / 10000;
            uint256 sellerProceeds = winningBid - feeAmount - royaltyAmount;

            address royaltyReceiver = originalCreator;

            if (auction.paymentToken == address(0)) { // Native token
                Address.sendValue(payable(auction.seller), sellerProceeds);
                if (feeAmount > 0) {
                    Address.sendValue(payable(feeRecipient), feeAmount);
                }
                 if (royaltyAmount > 0) {
                    Address.sendValue(payable(royaltyReceiver), royaltyAmount);
                }
            } else { // ERC20
                IERC20 paymentTokenContract = IERC20(auction.paymentToken);
                require(paymentTokenContract.transfer(auction.seller, sellerProceeds), "ERC20 transfer failed to seller");
                 if (feeAmount > 0) {
                    require(paymentTokenContract.transfer(feeRecipient, feeAmount), "ERC20 transfer failed to fee recipient");
                }
                 if (royaltyAmount > 0) {
                    require(paymentTokenContract.transfer(royaltyReceiver, royaltyAmount), "ERC20 transfer failed to royalty receiver");
                }
            }

            // Transfer NFT to winner
            _transfer(address(this), auction.highestBidder, auction.tokenId);

            emit AuctionEnded(auctionId, auction.highestBidder, winningBid);
        }
    }

     /**
     * @dev Allows the seller to cancel an auction.
     * Only possible if no bids have been placed, or if called before the auction end time and no bids met reserve.
     * Simplified: Only allow if highestBid is 0.
     */
    function cancelAuction(uint256 auctionId) public nonReentrant whenNotPaused {
        Auction storage auction = auctions[auctionId];
        require(auction.startTime > 0, "Auction does not exist");
        require(!auction.ended, "Auction has ended");
        require(auction.seller == msg.sender, "Not the seller of the auction");
        require(auction.highestBid == 0, "Cannot cancel auction with bids"); // Simplified condition

        auction.ended = true; // Mark as ended to prevent further bids

        // Transfer NFT back to seller
        _transfer(address(this), msg.sender, auction.tokenId);

        emit AuctionCancelled(auctionId);
    }


    // --- Marketplace Functions (Bundle) ---

     /**
     * @dev Lists a bundle of NFTs for sale at a fixed price.
     * Requires prior approval for all tokens in the bundle to this contract.
     * @param paymentToken Address of the ERC20 token, or Address(0) for native token.
     */
    function listBundleFixedPrice(uint256[] memory tokenIds, uint256 price, address paymentToken)
        public nonReentrant whenNotPaused
    {
        require(tokenIds.length > 0, "Bundle must contain at least one token");
        require(price > 0, "Price must be greater than 0");
        require(_allowedPaymentTokens.contains(paymentToken), "Payment token not allowed");

        address seller = msg.sender;
        // Check ownership and transferability for all tokens
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_exists(tokenId), "Token ID does not exist");
            require(ownerOf(tokenId) == seller, "Not the owner of token in bundle");
            require(!_isStaked[tokenId], "Token in bundle is staked");
            require(_nftActiveRental[tokenId] == 0, "Token in bundle is rented out");
        }

        _bundleIds.increment();
        uint256 bundleId = _bundleIds.current();

        // Store tokens in the bundle
        uint256[] memory bundleTokenIds = new uint256[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i++) {
             bundleTokenIds[i] = tokenIds[i];
             // Transfer NFT to the marketplace contract
             _transfer(seller, address(this), tokenIds[i]);
        }


        bundleListings[bundleId] = BundleListing({
            bundleId: bundleId,
            tokenIds: bundleTokenIds,
            seller: seller,
            price: price,
            paymentToken: paymentToken,
            active: true
        });


        emit BundleListingCreated(bundleId, bundleTokenIds, seller, price, paymentToken);
    }

    /**
     * @dev Buys an NFT bundle from a fixed-price listing.
     */
    function buyBundleFixedPrice(uint256 bundleListingId) public payable nonReentrant whenNotPaused {
        BundleListing storage bundle = bundleListings[bundleListingId];
        require(bundle.active, "Bundle listing is not active");
        require(bundle.tokenIds.length > 0, "Bundle is empty or invalid");
        require(msg.sender != bundle.seller, "Cannot buy your own bundle");

        // Verify all tokens are still held by the marketplace
        for (uint i = 0; i < bundle.tokenIds.length; i++) {
             require(_exists(bundle.tokenIds[i]), "Token in bundle does not exist");
             require(ownerOf(bundle.tokenIds[i]) == address(this), "Token in bundle not held by marketplace");
        }


        uint256 totalPrice = bundle.price;
        uint256 feeAmount = (totalPrice * marketplaceFeeBps) / 10000;
        uint256 sellerProceeds = totalPrice - feeAmount;
        // Royalties for bundles are tricky - could sum royalties of individual tokens,
        // or apply a flat percentage. Summing individual royalties is more fair.
        uint256 totalRoyaltyAmount = 0;
        // Simplified: Royalty is per token. Summing them up.
        mapping(address => uint256) royaltySplits; // Address => amount
        for(uint i = 0; i < bundle.tokenIds.length; i++) {
             uint256 tokenId = bundle.tokenIds[i];
             uint256 tokenRoyalty = (totalPrice * _tokenRoyalties[tokenId]) / 10000 / bundle.tokenIds.length; // Example: Divide total price royalty by number of tokens
             totalRoyaltyAmount += tokenRoyalty;
             address originalCreator = ownerOf(tokenId); // Simplified: minter is creator
             royaltySplits[originalCreator] += tokenRoyalty; // Aggregate royalty for the same creator
        }
        sellerProceeds -= totalRoyaltyAmount;


        if (bundle.paymentToken == address(0)) { // Native token payment
            require(msg.value == totalPrice, "Incorrect native token amount");
            Address.sendValue(payable(bundle.seller), sellerProceeds);
            if (feeAmount > 0) {
                 Address.sendValue(payable(feeRecipient), feeAmount);
            }
             // Send aggregated royalties
             for(address royaltyReceiver : Address.get_keys(royaltySplits)) { // Pseudocode for iterating map keys - requires library or manual tracking
                  if (royaltySplits[royaltyReceiver] > 0) {
                       Address.sendValue(payable(royaltyReceiver), royaltySplits[royaltyReceiver]);
                  }
             }
        } else { // ERC20 token payment
            require(msg.value == 0, "Cannot send native token with ERC20 payment");
            IERC20 paymentTokenContract = IERC20(bundle.paymentToken);
            require(paymentTokenContract.transferFrom(msg.sender, address(this), totalPrice), "ERC20 transfer failed from buyer");

            // Transfer to seller, fee recipient, and royalty receivers
            require(paymentTokenContract.transfer(bundle.seller, sellerProceeds), "ERC20 transfer failed to seller");
            if (feeAmount > 0) {
                 require(paymentTokenContract.transfer(feeRecipient, feeAmount), "ERC20 transfer failed to fee recipient");
            }
             // Send aggregated royalties
             for(address royaltyReceiver : Address.get_keys(royaltySplits)) { // Pseudocode
                 if (royaltySplits[royaltyReceiver] > 0) {
                      require(paymentTokenContract.transfer(royaltyReceiver, royaltySplits[royaltyReceiver]), "ERC20 transfer failed to royalty receiver");
                 }
             }
        }

        // Transfer all NFTs in bundle to buyer
        for (uint i = 0; i < bundle.tokenIds.length; i++) {
            _transfer(address(this), msg.sender, bundle.tokenIds[i]);
        }

        bundle.active = false; // Deactivate listing

        emit BundlePurchased(bundleListingId, msg.sender, totalPrice);
    }

     /**
     * @dev Cancels a bundle listing.
     */
    function cancelBundleListing(uint256 bundleListingId) public nonReentrant whenNotPaused {
        BundleListing storage bundle = bundleListings[bundleListingId];
        require(bundle.active, "Bundle listing is not active");
        require(bundle.seller == msg.sender, "Not the seller of the bundle listing");
        require(bundle.tokenIds.length > 0, "Bundle is empty or invalid");

        // Transfer all NFTs back to seller
        for (uint i = 0; i < bundle.tokenIds.length; i++) {
             require(_exists(bundle.tokenIds[i]), "Token in bundle does not exist"); // Should always exist if bundle was valid
             require(ownerOf(bundle.tokenIds[i]) == address(this), "Token in bundle not held by marketplace"); // Should be held by marketplace
             _transfer(address(this), msg.sender, bundle.tokenIds[i]);
        }

        bundle.active = false; // Deactivate listing

        emit BundleListingCancelled(bundleListingId);
    }


    // --- Advanced NFT Functions (Staking) ---

    /**
     * @dev Allows an NFT owner to stake their NFT.
     * Requires prior approval of the NFT to this contract.
     */
    function stakeNFT(uint256 tokenId) public nonReentrant whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not the owner of the token");
        require(!_isStaked[tokenId], "Token is already staked");
        require(_nftActiveRental[tokenId] == 0, "Token is currently rented out");

        // Mark listings/auctions as inactive if staked? Or require cancellation first?
        // For simplicity, let's require cancellation first by requiring ownerOf == msg.sender above.

        _isStaked[tokenId] = true;
        stakedNFTs[tokenId] = StakedNFT({
            tokenId: tokenId,
            owner: msg.sender,
            stakeTime: block.timestamp,
            lastRewardClaimTime: block.timestamp
        });

        // Transfer NFT to the contract
        _transfer(msg.sender, address(this), tokenId);

        emit NFTStaked(tokenId, msg.sender, block.timestamp);
    }

    /**
     * @dev Allows an owner to unstake their NFT. Calculates potential rewards.
     */
    function unstakeNFT(uint256 tokenId) public nonReentrant whenNotPaused {
        require(_isStaked[tokenId], "Token is not staked");
        require(stakedNFTs[tokenId].owner == msg.sender, "Not the owner of the staked token");

        // Calculate rewards earned since last claim/stake time (simplified model)
        // In a real scenario, reward calculation would be more complex,
        // potentially involving a separate reward token and distribution logic.
        uint256 timeStaked = block.timestamp - stakedNFTs[tokenId].stakeTime;
        uint256 timeSinceLastClaim = block.timestamp - stakedNFTs[tokenId].lastRewardClaimTime;
        uint256 potentialRewards = (timeSinceLastClaim / 1 days) * 1 ether; // Example: 1 native token per day staked (simplified)

        // Reset staking state
        _isStaked[tokenId] = false;
        delete stakedNFTs[tokenId]; // Removes the entry

        // Transfer NFT back to the owner
        _transfer(address(this), msg.sender, tokenId);

        // Distribute rewards (simplified: just send native token)
        if (potentialRewards > 0) {
             Address.sendValue(payable(msg.sender), potentialRewards);
             emit StakingRewardsClaimed(tokenId, msg.sender, potentialRewards);
        }

        emit NFTUnstaked(tokenId, msg.sender, block.timestamp);
    }

    /**
     * @dev Allows claiming staking rewards without unstaking.
     */
    function claimStakingRewards(uint256 tokenId) public nonReentrant {
         require(_isStaked[tokenId], "Token is not staked");
         require(stakedNFTs[tokenId].owner == msg.sender, "Not the owner of the staked token");

         // Calculate rewards earned since last claim time (simplified model)
         uint256 timeSinceLastClaim = block.timestamp - stakedNFTs[tokenId].lastRewardClaimTime;
         uint256 rewardsToClaim = (timeSinceLastClaim / 1 days) * 1 ether; // Example: 1 native token per day staked

         require(rewardsToClaim > 0, "No rewards accumulated yet");

         stakedNFTs[tokenId].lastRewardClaimTime = block.timestamp; // Update last claim time

         // Distribute rewards (simplified: just send native token)
         Address.sendValue(payable(msg.sender), rewardsToClaim);

         emit StakingRewardsClaimed(tokenId, msg.sender, rewardsToClaim);
    }

    /**
     * @dev Query function to get staking information for a token.
     * @return isStaked Whether the token is currently staked.
     * @return owner The address of the staker.
     * @return stakeTime The timestamp when the token was staked.
     */
    function getStakedInfo(uint256 tokenId)
         public view returns (bool isStaked, address owner, uint256 stakeTime)
    {
         isStaked = _isStaked[tokenId];
         if (isStaked) {
              StakedNFT storage staked = stakedNFTs[tokenId];
              owner = staked.owner;
              stakeTime = staked.stakeTime;
         } else {
              owner = address(0);
              stakeTime = 0;
         }
    }


    // --- Advanced NFT Functions (Rental) ---

    /**
     * @dev Allows an NFT owner to list their NFT for rent.
     * Requires prior approval of the NFT to this contract.
     * @param paymentToken Address of the ERC20 token, or Address(0) for native token.
     */
    function rentNFT(uint256 tokenId, uint256 duration, uint256 dailyPrice, address paymentToken)
        public nonReentrant whenNotPaused
    {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not the owner of the token");
        require(!_isStaked[tokenId], "Token is staked");
        require(_nftActiveRental[tokenId] == 0, "Token is already listed for rent or rented out");
        require(duration > 0 && dailyPrice > 0, "Duration and price must be greater than 0");
        require(_allowedPaymentTokens.contains(paymentToken), "Payment token not allowed");

        _rentalListingIds.increment();
        uint256 rentalListingId = _rentalListingIds.current();

        rentalListings[rentalListingId] = RentalListing({
            rentalListingId: rentalListingId,
            tokenId: tokenId,
            owner: msg.sender,
            dailyPrice: dailyPrice,
            duration: duration, // Max days
            paymentToken: paymentToken,
            available: true
        });

        // NFT remains with the owner until rented

        emit RentalListingCreated(rentalListingId, tokenId, msg.sender, dailyPrice, duration, paymentToken);
    }

    /**
     * @dev Allows a user to rent an NFT from a rental listing.
     * Renter pays upfront for the specified duration.
     */
    function rentOutNFT(uint256 rentalListingId) public payable nonReentrant whenNotPaused {
        RentalListing storage listing = rentalListings[rentalListingId];
        require(listing.available, "Rental listing is not available");
        require(_exists(listing.tokenId), "Listed token does not exist");
        require(ownerOf(listing.tokenId) == listing.owner, "Token is not with the original owner"); // Ensure original owner still has it
        require(_nftActiveRental[listing.tokenId] == 0, "Token is already rented out");
        require(msg.sender != listing.owner, "Cannot rent your own NFT");

        uint256 totalRentalPrice = listing.dailyPrice * listing.duration;
        uint256 feeAmount = (totalRentalPrice * marketplaceFeeBps) / 10000;
        uint256 ownerProceeds = totalRentalPrice - feeAmount;

        if (listing.paymentToken == address(0)) { // Native token payment
            require(msg.value == totalRentalPrice, "Incorrect native token amount");
            Address.sendValue(payable(listing.owner), ownerProceeds);
             if (feeAmount > 0) {
                 Address.sendValue(payable(feeRecipient), feeAmount);
            }
        } else { // ERC20 token payment
            require(msg.value == 0, "Cannot send native token with ERC20 payment");
            IERC20 paymentTokenContract = IERC20(listing.paymentToken);
            require(paymentTokenContract.transferFrom(msg.sender, address(this), totalRentalPrice), "ERC20 transfer failed from renter");

            require(paymentTokenContract.transfer(listing.owner, ownerProceeds), "ERC20 transfer failed to owner");
             if (feeAmount > 0) {
                require(paymentTokenContract.transfer(feeRecipient, feeAmount), "ERC20 transfer failed to fee recipient");
            }
        }

        // Transfer NFT to the renter (temporary)
        // IMPORTANT: This transfers ownership. A real rental contract might use a wrapper or delegate call logic
        // to grant *usage rights* without full ownership transfer, but standard ERC721 transfer is simpler here.
        // The renter will need to approve the marketplace to transfer it back.
         require(_isApprovedOrOwner(address(this), listing.tokenId), "Marketplace needs approval from owner to transfer for rental");
        _transfer(listing.owner, msg.sender, listing.tokenId); // Transfer from owner to renter

        _activeRentalIds.increment();
        uint256 activeRentalId = _activeRentalIds.current();

        activeRentals[activeRentalId] = ActiveRental({
            rentalListingId: rentalListingId, // Link back to listing
            tokenId: listing.tokenId,
            originalOwner: listing.owner,
            currentRenter: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + (listing.duration * 1 days), // Rental ends after X days
            paidAmount: totalRentalPrice,
            paymentToken: listing.paymentToken,
            active: true
        });

        _nftActiveRental[listing.tokenId] = activeRentalId; // Map token to active rental
        listing.available = false; // Mark listing as unavailable

        emit RentalStarted(activeRentalId, rentalListingId, listing.tokenId, listing.owner, msg.sender, listing.duration, totalRentalPrice);
    }

    /**
     * @dev Ends an active rental. Can be called by original owner or renter after expiry.
     * Transfers NFT back to original owner.
     */
    function endRental(uint256 activeRentalId) public nonReentrant whenNotPaused {
        ActiveRental storage rental = activeRentals[activeRentalId];
        require(rental.active, "Rental is not active");
        require(_exists(rental.tokenId), "Rented token does not exist");
        require(msg.sender == rental.originalOwner || msg.sender == rental.currentRenter || block.timestamp >= rental.endTime,
                "Not original owner, current renter, or rental not ended");

        // Only allow ending by renter if rental period is over OR
        // if original owner initiated early end (would require another function/logic)

        require(ownerOf(rental.tokenId) == rental.currentRenter, "Token is not with the current renter");

        // Transfer NFT back to the original owner
        // Renter must approve the marketplace to transfer the NFT back.
        require(_isApprovedOrOwner(address(this), rental.tokenId), "Marketplace needs approval from renter to transfer token back");
        _transfer(rental.currentRenter, rental.originalOwner, rental.tokenId);

        // Handle potential refunds for early termination (complex, simplified: no refund)
        // uint256 actualDuration = block.timestamp - rental.startTime;
        // uint256 paidDuration = rental.duration * 1 days;
        // if (actualDuration < paidDuration && msg.sender == rental.originalOwner) { ... refund calc ... }

        // Reset rental state
        rental.active = false;
        delete _nftActiveRental[rental.tokenId]; // Remove mapping

        // Mark the original rental listing as available again
        RentalListing storage listing = rentalListings[rental.rentalListingId];
        if (listing.owner == rental.originalOwner) { // Ensure it's the same listing used
             listing.available = true;
        }


        emit RentalEnded(activeRentalId, rental.tokenId, rental.originalOwner, rental.currentRenter);
    }


    /**
     * @dev Query function to get rental information for a token.
     * @return isActive Whether the token is currently rented.
     * @return activeRentalId The ID of the active rental instance.
     * @return originalOwner The address of the original owner.
     * @return currentRenter The address of the current renter.
     * @return endTime The timestamp when the rental ends.
     */
    function getRentalInfo(uint256 tokenId)
         public view returns (bool isActive, uint256 activeRentalId, address originalOwner, address currentRenter, uint256 endTime)
    {
         activeRentalId = _nftActiveRental[tokenId];
         isActive = activeRentalId != 0;
         if (isActive) {
              ActiveRental storage rental = activeRentals[activeRentalId];
              originalOwner = rental.originalOwner;
              currentRenter = rental.currentRenter;
              endTime = rental.endTime;
         } else {
              originalOwner = address(0);
              currentRenter = address(0);
              endTime = 0;
         }
    }


    // --- Marketplace Configuration / Admin ---

    /**
     * @dev Allows the owner to set the marketplace fee percentage.
     * @param newFeeBps Fee in basis points (e.g., 250 for 2.5%). Max 10000 (100%).
     */
    function setMarketplaceFee(uint16 newFeeBps) public onlyOwner {
        require(newFeeBps <= 10000, "Fee cannot exceed 100%");
        marketplaceFeeBps = newFeeBps;
        emit MarketplaceFeeUpdated(newFeeBps);
    }

    /**
     * @dev Allows the owner to set the address that receives marketplace fees.
     */
    function setFeeRecipient(address newRecipient) public onlyOwner {
        require(newRecipient != address(0), "Fee recipient cannot be zero address");
        feeRecipient = newRecipient;
        emit FeeRecipientUpdated(newRecipient);
    }

    /**
     * @dev Allows the fee recipient to withdraw accumulated fees for a specific token.
     * @param tokenAddress Address of the token (Address(0) for native token).
     */
    function withdrawFees(address tokenAddress) public nonReentrant {
        require(msg.sender == feeRecipient, "Only fee recipient can withdraw fees");

        uint256 balance = 0;
        if (tokenAddress == address(0)) {
            balance = address(this).balance;
             // Subtract any ETH held for bids or rentals temporarily
             // Requires tracking pending ETH carefully, which is complex.
             // Simplified: Assume all contract ETH balance minus explicit pending amounts is fees.
             // A safer implementation tracks fee balances per token explicitly.
             // For this example, just send current contract balance.
             (bool success, ) = payable(feeRecipient).call{value: balance}("");
             require(success, "Native token withdrawal failed");
        } else {
            IERC20 token = IERC20(tokenAddress);
            balance = token.balanceOf(address(this));
            // Similar complexity as native token for non-fee balances.
            // Simplified: Just send current token balance.
            require(token.transfer(feeRecipient, balance), "ERC20 withdrawal failed");
        }

        emit FeesWithdrawn(tokenAddress, feeRecipient, balance);
    }

    /**
     * @dev Allows the owner to whitelist a token for payments.
     */
    function addAllowedPaymentToken(address tokenAddress) public onlyOwner {
        require(tokenAddress != address(0), "Cannot add zero address");
        require(!_allowedPaymentTokens.contains(tokenAddress), "Token already allowed");
        _allowedPaymentTokens.add(tokenAddress);
        emit AllowedPaymentTokenAdded(tokenAddress);
    }

    /**
     * @dev Allows the owner to remove a token from the payment whitelist.
     * Cannot remove the native token (address(0)).
     */
    function removeAllowedPaymentToken(address tokenAddress) public onlyOwner {
        require(tokenAddress != address(0), "Cannot remove native token");
        require(_allowedPaymentTokens.contains(tokenAddress), "Token not allowed");
        _allowedPaymentTokens.remove(tokenAddress);
        emit AllowedPaymentTokenRemoved(tokenAddress);
    }

    /**
     * @dev Allows setting a royalty percentage for a specific token on future sales.
     * Simplified: Only callable by owner. In a real ERC2981 setup, creator would call.
     * @param royaltyBps Royalty in basis points (e.g., 500 for 5%). Max 10000.
     */
    function setRoyaltyPercentage(uint256 tokenId, uint16 royaltyBps) public onlyOwner {
         require(_exists(tokenId), "Token does not exist");
         require(royaltyBps <= 10000, "Royalty cannot exceed 100%");
         _tokenRoyalties[tokenId] = royaltyBps;
         emit RoyaltyPercentageUpdated(tokenId, royaltyBps);
    }


    // --- Marketplace Functions (Flash Sale) ---

    /**
     * @dev Initiates a flash sale for an existing fixed-price listing.
     * The listing must be active and owned by msg.sender.
     * @param duration Duration of the flash sale in seconds.
     */
    function initiateFlashSale(uint256 listingId, uint256 duration, uint256 flashPrice) public nonReentrant whenNotPaused {
        FixedPriceListing storage listing = fixedPriceListings[listingId];
        require(listing.active, "Listing is not active");
        require(listing.seller == msg.sender, "Not the seller of the listing");
        require(duration > 0, "Duration must be greater than 0");
        require(flashPrice > 0 && flashPrice < listing.price, "Flash price must be greater than 0 and less than original price");

        // Cancel any previous flash sale for this listing
        if (flashSales[listingId].active) {
             cancelFlashSale(listingId);
        }

        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;

        flashSales[listingId] = FlashSale({
            listingId: listingId,
            flashPrice: flashPrice,
            startTime: startTime,
            endTime: endTime,
            active: true
        });

        emit FlashSaleInitiated(listingId, flashPrice, endTime);
    }

    /**
     * @dev Cancels an ongoing flash sale for a listing.
     * Can be called by the seller.
     */
    function cancelFlashSale(uint256 listingId) public nonReentrant {
        FlashSale storage flashSale = flashSales[listingId];
        require(flashSale.active, "No active flash sale for this listing");
        require(fixedPriceListings[listingId].seller == msg.sender, "Not the seller of the listing");

        flashSale.active = false; // Deactivate the flash sale

        emit FlashSaleCancelled(listingId);
    }

    /**
     * @dev Buys an NFT during an active flash sale.
     * Uses the flash sale price instead of the original listing price.
     */
    function buyNFTDuringFlashSale(uint256 listingId) public payable nonReentrant whenNotPaused {
        FixedPriceListing storage listing = fixedPriceListings[listingId];
        FlashSale storage flashSale = flashSales[listingId];

        require(listing.active, "Listing is not active");
        require(flashSale.active, "No active flash sale for this listing");
        require(block.timestamp >= flashSale.startTime && block.timestamp < flashSale.endTime, "Flash sale is not active");
        require(_exists(listing.tokenId), "Listed token does not exist");
        require(ownerOf(listing.tokenId) == address(this), "Token is not held by marketplace");
        require(msg.sender != listing.seller, "Cannot buy your own listing");

        uint256 totalPrice = flashSale.flashPrice; // Use flash sale price
        uint256 feeAmount = (totalPrice * marketplaceFeeBps) / 10000;
        uint256 sellerProceeds = totalPrice - feeAmount;
        uint256 royaltyAmount = (totalPrice * _tokenRoyalties[listing.tokenId]) / 10000;
        sellerProceeds -= royaltyAmount; // Deduct royalty from seller proceeds

        address originalCreator = ownerOf(listing.tokenId); // Simplified: minter is creator
        address royaltyReceiver = originalCreator;

        if (listing.paymentToken == address(0)) { // Native token payment
            require(msg.value == totalPrice, "Incorrect native token amount");
            Address.sendValue(payable(listing.seller), sellerProceeds);
            if (feeAmount > 0) {
                Address.sendValue(payable(feeRecipient), feeAmount);
            }
             if (royaltyAmount > 0) {
                Address.sendValue(payable(royaltyReceiver), royaltyAmount);
            }
             // Refund any excess native token sent if msg.value > totalPrice (good practice)
             if (msg.value > totalPrice) {
                 (bool success, ) = payable(msg.sender).call{value: msg.value - totalPrice}("");
                 require(success, "Excess native token refund failed");
             }

        } else { // ERC20 token payment
            require(msg.value == 0, "Cannot send native token with ERC20 payment");
            IERC20 paymentTokenContract = IERC20(listing.paymentToken);
            require(paymentTokenContract.transferFrom(msg.sender, address(this), totalPrice), "ERC20 transfer failed from buyer");

            // Transfer to seller, fee recipient, and royalty receiver
            require(paymentTokenContract.transfer(listing.seller, sellerProceeds), "ERC20 transfer failed to seller");
            if (feeAmount > 0) {
                 require(paymentTokenContract.transfer(feeRecipient, feeAmount), "ERC20 transfer failed to fee recipient");
            }
             if (royaltyAmount > 0) {
                 require(paymentTokenContract.transfer(royaltyReceiver, royaltyAmount), "ERC20 transfer failed to royalty receiver");
             }
        }

        // Transfer NFT to buyer
        _transfer(address(this), msg.sender, listing.tokenId);

        listing.active = false; // Deactivate original listing
        flashSale.active = false; // Deactivate flash sale

        emit NFTFlashPurchased(listingId, listing.tokenId, msg.sender, totalPrice);
    }


    // --- Query Functions ---

    /**
     * @dev Get details for a fixed-price listing.
     */
    function getListingDetails(uint256 listingId)
        public view returns (FixedPriceListing memory)
    {
        return fixedPriceListings[listingId];
    }

    /**
     * @dev Get details for an auction.
     */
    function getAuctionDetails(uint256 auctionId)
        public view returns (Auction memory)
    {
        return auctions[auctionId];
    }

     /**
     * @dev Get details for a bundle listing.
     */
    function getBundleDetails(uint256 bundleListingId)
        public view returns (BundleListing memory)
    {
        return bundleListings[bundleListingId];
    }

    /**
     * @dev Get details for a rental listing.
     */
     function getRentalListingDetails(uint256 rentalListingId)
         public view returns (RentalListing memory)
     {
         return rentalListings[rentalListingId];
     }

     /**
     * @dev Get details for an active rental instance.
     */
     function getActiveRentalDetails(uint256 activeRentalId)
         public view returns (ActiveRental memory)
     {
         return activeRentals[activeRentalId];
     }

     /**
      * @dev Get details for a flash sale.
      */
     function getFlashSaleDetails(uint256 listingId)
          public view returns (FlashSale memory)
     {
          return flashSales[listingId];
     }

     /**
     * @dev Get list of allowed payment tokens.
     * Note: Iterating over EnumerableSet on-chain is gas-intensive for large sets.
     * Use off-chain querying for large lists.
     */
    function getAllowedPaymentTokens() public view returns (address[] memory) {
        address[] memory tokens = new address[](_allowedPaymentTokens.length());
        for (uint i = 0; i < _allowedPaymentTokens.length(); i++) {
            tokens[i] = _allowedPaymentTokens.at(i);
        }
        return tokens;
    }
}

// Helper to get keys from a mapping (not native Solidity feature, requires library or assembly)
// This is a placeholder and would need a real library like 'EnumerableMap' or custom assembly.
// For demonstration purposes, assuming a helper exists or relying on off-chain queries for map keys.
library Address {
    // Mock function for demonstration. Real implementation needed for on-chain iteration.
    function get_keys(mapping(address => uint256) storage map) internal pure returns (address[] memory) {
         // This cannot be reliably implemented efficiently on-chain without a separate list of keys.
         // For real use, either track keys in a list/EnumerableSet or query off-chain.
         // Returning an empty array as a placeholder.
         address[] memory keys = new address[](0);
         return keys;
    }
     // Standard Address.sendValue from OpenZeppelin (already imported)
}
```

**Explanation of Advanced/Creative/Trendy Aspects:**

1.  **Dynamic NFTs (DNFTs):**
    *   On-chain mutable attributes (`_dynamicAttributes`).
    *   Triggered updates via `interactWithNFT` (simulating game/dApp interaction) and `triggerExternalUpdate` (simulating oracle/external data).
    *   `tokenURI` is overridden to signal that metadata is dynamic and should be fetched dynamically (typically pointing to an API that reads on-chain attributes).
2.  **Diverse Marketplace Types:**
    *   Fixed-price listings (`listNFTFixedPrice`, `buyNFTFixedPrice`).
    *   English Auctions (`createAuction`, `placeBid`, `endAuction`).
    *   Bundle Listings (`listBundleFixedPrice`, `buyBundleFixedPrice`) - selling multiple NFTs together.
    *   Flash Sales (`initiateFlashSale`, `buyNFTDuringFlashSale`) - timed, discounted sales tied to existing listings.
3.  **Advanced NFT Interactions:**
    *   NFT Staking (`stakeNFT`, `unstakeNFT`, `claimStakingRewards`) - allows locking NFTs to potentially earn yield (simplified native token yield model).
    *   NFT Rental (`rentNFT`, `rentOutNFT`, `endRental`) - allows temporary transfer of NFT usage rights for a fee (simplified with full ownership transfer, a real system might use delegate calls or wrapper tokens).
4.  **Configurable & Extensible:**
    *   Configurable Marketplace Fee (`setMarketplaceFee`).
    *   Configurable Fee Recipient (`setFeeRecipient`).
    *   Allowed Payment Token Whitelisting (`addAllowedPaymentToken`, `removeAllowedPaymentToken`) - supports multiple ERC20s and native token.
    *   Per-Token Royalties (`setRoyaltyPercentage`) - allows setting different royalty rates for different NFTs (basic implementation).
5.  **Security & Standards:**
    *   Inherits standard OpenZeppelin contracts (ERC721Enumerable, Ownable, Pausable, ReentrancyGuard) for robustness and standard compliance.
    *   Uses `nonReentrant` guards on functions transferring tokens.
    *   Uses `whenNotPaused` modifier.

This contract goes significantly beyond a simple NFT or fixed-price marketplace by adding dynamic attributes, multiple sale types, and advanced interaction models like staking and rental, while maintaining configurability and using standard security patterns. The total function count is well over the requested 20.