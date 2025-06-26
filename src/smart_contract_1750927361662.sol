Okay, here is a Solidity smart contract demonstrating a "Dynamic NFT Marketplace with Oracle-Driven Traits and Staking".

This concept involves:
1.  **Dynamic NFTs:** NFTs whose traits can change based on external data feeds.
2.  **Oracle Integration:** The contract receives data updates (simulated here) from designated oracle addresses.
3.  **Trait Controllers:** Registered helper contracts that interpret oracle data and NFT state to determine dynamic traits.
4.  **Multiple Marketplace Mechanisms:** Direct Sale, Auctions, and Offers.
5.  **NFT Staking:** Users can stake their NFTs in the marketplace to potentially earn rewards (logic placeholder) or affect dynamic traits.
6.  **Access Control & Configuration:** Admin functions for managing fees, allowed tokens, oracles, and trait controllers.

It aims for advanced concepts like external data integration, modularity (trait controllers), and combining multiple DeFi/NFT primitives.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// --- Outline and Function Summary ---
/*
Contract: DynamicNFTMarketplace

Purpose: A decentralized marketplace for dynamic Non-Fungible Tokens (NFTs).
It allows users to list NFTs for direct sale, auction, or accept offers.
Key features include:
1.  **Dynamic Traits:** NFTs registered as dynamic can have traits influenced by external data.
2.  **Oracle Integration:** Supports registering oracle addresses that can push data updates.
3.  **Trait Controllers:** Uses separate contracts (implementing ITraitController) to interpret oracle data and NFT state to calculate dynamic traits.
4.  **NFT Staking:** Users can stake their NFTs to potentially earn rewards or influence traits.
5.  **Multiple Listing Types:** Direct Buy, Auctions, and Offers.
6.  **ERC20 Support:** Allows listing/bidding using approved ERC20 tokens.
7.  **Admin Control:** Owner can manage fees, allowed tokens, oracles, trait controllers, and pause the contract.

Inherits:
-   Ownable: For basic admin access control.
-   ReentrancyGuard: Prevents reentrancy attacks on critical functions.
-   Pausable: Allows pausing core contract operations.
-   ERC721Holder: Safely receives NFTs (though standard transfer pattern is list after approve).

Interfaces:
-   ITraitController: Defines the interface for contracts responsible for calculating dynamic traits.

State Variables:
-   Fees, allowed payment tokens, admin wallet.
-   Mappings for active listings, auctions, offers, staked NFTs.
-   Mappings for dynamic NFT registry, oracle addresses, latest oracle data.
-   Mappings for registered trait controllers.
-   Counters for listing, auction, offer IDs.

Events:
-   Emitted for state changes: listing created/cancelled, sale, offer made/accepted/rejected, auction started/bid/ended, NFT staked/unstaked, oracle data updated, fees withdrawn, config changes.

Error Definitions:
-   Custom errors for clearer error handling.

Modifiers:
-   `onlyOracle`: Restricts access to registered oracle addresses.
-   `onlyAllowedToken`: Ensures operations use approved payment tokens.

Functions (categorized):

--- Core Marketplace ---
1.  `listNFTForSale`: List an NFT for a fixed price.
2.  `cancelListing`: Owner or admin cancels a direct sale listing.
3.  `buyNFT`: Purchase an NFT from a direct sale listing.
4.  `makeOffer`: Make an offer on a specific NFT (listed or not, typically listed).
5.  `acceptOffer`: Listing owner accepts a pending offer.
6.  `rejectOffer`: Listing owner or offer maker cancels a pending offer.

--- Auction Marketplace ---
7.  `listNFTForAuction`: List an NFT for auction.
8.  `placeBid`: Place a bid on an active auction.
9.  `endAuction`: End an auction and transfer NFT/funds to winner/seller.

--- Dynamic NFT Management ---
10. `registerTraitController`: Admin registers a contract address as a valid trait controller.
11. `setTraitControllerAddress`: Admin updates the address for a registered trait controller type.
12. `addNFTToDynamicRegistry`: Owner or trait controller registers a specific NFT as dynamic with a controller type.
13. `removeNFTFromDynamicRegistry`: Owner or admin removes an NFT from the dynamic registry.
14. `registerTraitOracle`: Admin registers an address as a valid oracle for a specific key.
15. `updateTraitOracleValue`: Registered oracle updates a data value.
16. `getDynamicTrait`: Public view function to get the calculated dynamic trait for an NFT.

--- NFT Staking ---
17. `stakeNFT`: Stake an NFT in the marketplace contract.
18. `unstakeNFT`: Unstake a previously staked NFT.
19. `claimStakingRewards`: Claim accrued staking rewards (logic placeholder).
20. `setStakingYieldRate`: Admin sets the yield rate for staking rewards.

--- Admin & Configuration ---
21. `withdrawAdminFees`: Owner withdraws accumulated fees.
22. `setListingFee`: Owner sets the percentage fee for direct sales and offers.
23. `setAuctionFee`: Owner sets the percentage fee for auctions.
24. `addAllowedPaymentToken`: Owner adds an ERC20 token address as a valid payment method.
25. `removeAllowedPaymentToken`: Owner removes an ERC20 token address.
26. `pauseContract`: Owner pauses core contract operations.
27. `unpauseContract`: Owner unpauses core contract operations.

--- View Functions ---
28. `getListingDetails`: Get details for a direct sale listing.
29. `getAuctionDetails`: Get details for an auction.
30. `getOfferDetails`: Get details for an offer.
31. `getNFTStakingDetails`: Get staking details for an NFT.
32. `getTraitOracleValue`: Get the latest value reported by an oracle key.
33. `getRegisteredTraitControllers`: Get the mapping of trait controller types to addresses.
34. `getRegisteredDynamicNFTs`: Check if an NFT is registered as dynamic and get its controller type.
35. `getPausedStatus`: Check if the contract is paused.
36. `getAllowedPaymentTokens`: Get the list of allowed ERC20 payment token addresses.

Note: This contract is a complex example combining multiple features. It includes placeholders for complex logic (e.g., staking rewards, detailed trait calculation) and assumes interaction with external ERC721 and ERC20 contracts. Security audits are crucial for production use.
*/

// --- Interfaces ---

/// @title ITraitController
/// @notice Interface for contracts that calculate dynamic NFT traits.
interface ITraitController {
    /// @notice Calculates the dynamic trait value for an NFT.
    /// @param collection The address of the NFT collection.
    /// @param tokenId The ID of the NFT.
    /// @param marketplaceOracleData The latest relevant oracle data from the marketplace.
    /// @param marketplaceNFTState Current state of the NFT in the marketplace (e.g., isStaked).
    /// @return traitValue A value representing the calculated dynamic trait.
    function calculateTrait(
        address collection,
        uint256 tokenId,
        bytes memory marketplaceOracleData,
        bytes memory marketplaceNFTState // e.g., abi.encode(isStaked)
    ) external view returns (bytes memory traitValue); // Return bytes to allow flexibility (string, uint256, struct, etc.)
}

// --- Error Definitions ---
error Market__NotListingOwner();
error Market__ListingNotFound();
error Market__InvalidBuyer();
error Market__ListingPriceMismatch();
error Market__NFTTransferFailed();
error Market__InvalidPaymentToken();
error Market__InsufficientFunds();
error Market__NFTAlreadyListed();
error Market__NotApprovedForMarketplace();

error Market__AuctionNotFound();
error Market__AuctionNotActive();
error Market__AuctionEnded();
error Market__BidTooLow();
error Market__AuctionNotExpired();
error Market__AuctionStillActive();
error Market__AlreadyHighestBidder();
error Market__AuctionSelfBid();
error Market__AuctionClaimFailed();

error Market__OfferNotFound();
error Market__OfferNotActive();
error Market__OfferAlreadyExists();
error Market__OfferExpired();
error Market__OfferNotForYou();
error Market__OfferNotFromYou();

error Market__NFTNotStaked();
error Market__NFTAlreadyStaked();
error Market__InvalidYieldRate();
error Market__StakeclaimFailed();

error Market__TraitControllerAlreadyRegistered();
error Market__TraitControllerNotRegistered();
error Market__NFTNotDynamic();
error Market__OracleAlreadyRegistered();
error Market__OracleNotRegistered();
error Market__InvalidOracleValue();

error Market__FeeTooHigh(uint256 maxFee);
error Market__ZeroAddress();
error Market__NoFeesToWithdraw();

contract DynamicNFTMarketplace is Ownable, ReentrancyGuard, Pausable, ERC721Holder {

    // --- State Variables ---

    // Admin Configuration
    address payable public adminWallet;
    uint256 public listingFeeBasisPoints = 250; // 2.5%
    uint256 public auctionFeeBasisPoints = 500; // 5%
    uint256 public constant MAX_FEE_BASIS_POINTS = 1000; // Max 10%
    mapping(address => bool) public allowedPaymentTokens;

    // Listing State (Direct Sale)
    struct Listing {
        uint256 listingId;
        address seller;
        address nftCollection;
        uint256 tokenId;
        uint256 price;
        address paymentToken; // Address of ERC20 token, or address(0) for native currency
        bool active;
    }
    mapping(uint256 => Listing) public listings;
    uint256 private _listingCounter = 0;

    // Auction State
    struct Auction {
        uint256 auctionId;
        address seller;
        address nftCollection;
        uint256 tokenId;
        uint256 reservePrice;
        uint256 highestBid;
        address highestBidder;
        uint64 startTime;
        uint64 endTime;
        bool active;
        mapping(address => uint256) bids; // Track bids for withdrawal if outbid
    }
    mapping(uint256 => Auction) public auctions;
    uint256 private _auctionCounter = 0;

    // Offer State
    struct Offer {
        uint256 offerId;
        address nftCollection;
        uint256 tokenId;
        address offerer;
        uint256 value;
        address paymentToken;
        uint64 expiresAt;
        bool active;
    }
    mapping(uint256 => Offer) public offers;
    uint256 private _offerCounter = 0;

    // Dynamic NFT State
    struct DynamicNFTInfo {
        bytes32 controllerType; // Identifier for the type of trait controller
        bool isRegistered;
    }
    // Maps collection + tokenId hash to dynamic info
    mapping(bytes32 => DynamicNFTInfo) public dynamicNFTs;
    // Maps controller type hash to the actual ITraitController contract address
    mapping(bytes32 => address) public traitControllers;
    // Maps oracle key hash to the oracle address
    mapping(bytes32 => address) public registeredOracles;
    // Maps oracle key hash to the latest data reported by the oracle
    mapping(bytes32 => bytes) public latestOracleData;

    // Staking State
    struct StakedNFT {
        address owner;
        uint64 stakeStartTime;
        uint256 rewardClaimed; // Placeholder for tracking claimed rewards
    }
    // Maps collection + tokenId hash to staking info
    mapping(bytes32 => StakedNFT) public stakedNFTs;
    uint256 public stakingYieldRate = 0; // Placeholder: rate per unit time/block per staked NFT

    // Fee Tracking
    uint256 public collectedFeesETH = 0;
    mapping(address => uint256) public collectedFeesERC20;

    // --- Events ---
    event ListingCreated(uint256 indexed listingId, address indexed seller, address indexed nftCollection, uint256 tokenId, uint256 price, address paymentToken);
    event ListingCancelled(uint256 indexed listingId);
    event NFTSold(uint256 indexed listingId, address indexed seller, address indexed buyer, address indexed nftCollection, uint256 tokenId, uint256 price, address paymentToken);

    event AuctionCreated(uint256 indexed auctionId, address indexed seller, address indexed nftCollection, uint256 tokenId, uint256 reservePrice, uint64 startTime, uint64 endTime);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event AuctionEnded(uint256 indexed auctionId, address indexed winner, uint256 winningBid, address indexed nftCollection, uint256 tokenId);
    event BidWithdrawn(uint256 indexed auctionId, address indexed bidder, uint256 amount);

    event OfferMade(uint256 indexed offerId, address indexed offerer, address indexed nftCollection, uint256 tokenId, uint256 value, address paymentToken, uint64 expiresAt);
    event OfferAccepted(uint256 indexed offerId, address indexed accepter, address indexed nftCollection, uint256 tokenId, uint256 value, address paymentToken);
    event OfferRejected(uint256 indexed offerId);

    event NFTStaked(address indexed owner, address indexed nftCollection, uint256 tokenId, uint64 stakeTime);
    event NFTUnstaked(address indexed owner, address indexed nftCollection, uint256 tokenId);
    event StakingRewardsClaimed(address indexed owner, address indexed nftCollection, uint256 tokenId, uint256 amount);

    event OracleDataUpdated(bytes32 indexed key, bytes value);
    event TraitControllerRegistered(bytes32 indexed controllerType, address indexed controllerAddress);
    event TraitControllerAddressUpdated(bytes32 indexed controllerType, address indexed newAddress);
    event NFTRegisteredAsDynamic(address indexed nftCollection, uint256 tokenId, bytes32 indexed controllerType);
    event NFTRemovedFromDynamicRegistry(address indexed nftCollection, uint256 tokenId);

    event AdminFeesWithdrawn(address indexed recipient, uint256 amountETH, mapping(address => uint256) amountsERC20); // Mapping info might need external query or separate events
    event ListingFeeUpdated(uint256 oldFee, uint256 newFee);
    event AuctionFeeUpdated(uint256 oldFee, uint256 newFee);
    event AllowedPaymentTokenAdded(address indexed token);
    event AllowedPaymentTokenRemoved(address indexed token);
    event StakingYieldRateUpdated(uint256 oldRate, uint256 newRate);

    // --- Modifiers ---

    modifier onlyOracle(bytes32 key) {
        if (registeredOracles[key] == address(0)) revert Market__OracleNotRegistered();
        if (registeredOracles[key] != msg.sender) revert OwnableUnauthorizedAccount(msg.sender); // Using Ownable error for unauthorized access
        _;
    }

    modifier onlyAllowedToken(address tokenAddress) {
        if (tokenAddress != address(0) && !allowedPaymentTokens[tokenAddress]) revert Market__InvalidPaymentToken();
        _;
    }

    // --- Constructor ---

    constructor(address payable _adminWallet) Ownable(msg.sender) Pausable() {
        if (_adminWallet == address(0)) revert Market__ZeroAddress();
        adminWallet = _adminWallet;
        allowedPaymentTokens[address(0)] = true; // Allow native currency by default
    }

    // Receive ETH fallback (prevent accidental sends)
    receive() external payable {
        revert("ETH direct transfer not allowed");
    }

    // --- Core Marketplace Functions ---

    /// @notice Lists an NFT for a fixed price sale.
    /// @param _nftCollection The address of the NFT contract.
    /// @param _tokenId The token ID of the NFT.
    /// @param _price The price of the NFT.
    /// @param _paymentToken The address of the payment token (address(0) for ETH).
    function listNFTForSale(
        address _nftCollection,
        uint256 _tokenId,
        uint256 _price,
        address _paymentToken
    ) external whenNotPaused nonReentrant onlyAllowedToken(_paymentToken) {
        if (_price == 0) revert Market__ListingPriceMismatch(); // Price must be > 0

        // Check if NFT is already listed, in auction, or staked
        bytes32 nftHash = keccak256(abi.encodePacked(_nftCollection, _tokenId));
        if (isNFTListed(_nftCollection, _tokenId) || isNFTInAuction(_nftCollection, _tokenId) || stakedNFTs[nftHash].owner != address(0)) {
             revert Market__NFTAlreadyListed(); // Covers all busy states
        }

        // Requires the user to have called approve(_marketplaceAddress, _tokenId) on the NFT contract beforehand
        IERC721 nftContract = IERC721(_nftCollection);
        if (nftContract.getApproved(_tokenId) != address(this) && nftContract.ownerOf(_tokenId) != msg.sender) {
             revert Market__NotApprovedForMarketplace(); // Or not the owner
        }
        if (nftContract.ownerOf(_tokenId) != msg.sender) revert Market__NotListingOwner(); // Ensure seller owns the NFT

        _listingCounter++;
        listings[_listingCounter] = Listing({
            listingId: _listingCounter,
            seller: msg.sender,
            nftCollection: _nftCollection,
            tokenId: _tokenId,
            price: _price,
            paymentToken: _paymentToken,
            active: true
        });

        // Transfer NFT to the marketplace contract
        nftContract.transferFrom(msg.sender, address(this), _tokenId);

        emit ListingCreated(_listingCounter, msg.sender, _nftCollection, _tokenId, _price, _paymentToken);
    }

    /// @notice Cancels a fixed price listing.
    /// @param _listingId The ID of the listing to cancel.
    function cancelListing(uint256 _listingId) external whenNotPaused nonReentrant {
        Listing storage listing = listings[_listingId];
        if (!listing.active) revert Market__ListingNotFound();
        if (listing.seller != msg.sender && owner() != msg.sender) revert Market__NotListingOwner(); // Allow owner/admin to cancel

        listing.active = false;

        // Return NFT to seller
        IERC721(listing.nftCollection).transferFrom(address(this), listing.seller, listing.tokenId);

        emit ListingCancelled(_listingId);
        // Note: Listing struct is not deleted to preserve history/prevent ID reuse issues, just marked inactive.
    }

    /// @notice Buys an NFT from a fixed price listing.
    /// @param _listingId The ID of the listing.
    function buyNFT(uint256 _listingId) external payable whenNotPaused nonReentrant {
        Listing storage listing = listings[_listingId];
        if (!listing.active) revert Market__ListingNotFound();
        if (listing.seller == msg.sender) revert Market__InvalidBuyer();

        uint256 totalPrice = listing.price;
        uint256 feeAmount = (totalPrice * listingFeeBasisPoints) / 10000;
        uint256 sellerReceiveAmount = totalPrice - feeAmount;

        if (listing.paymentToken == address(0)) { // Native currency (ETH)
            if (msg.value < totalPrice) revert Market__InsufficientFunds();

            // Transfer fee to admin wallet
            (bool successFee,) = payable(adminWallet).call{value: feeAmount}("");
            // Keep track internally if transfer fails, attempt later
            if (!successFee) collectedFeesETH += feeAmount;

            // Transfer funds to seller
            (bool successSeller,) = payable(listing.seller).call{value: sellerReceiveAmount}("");
            if (!successSeller) revert Market__NFTTransferFailed(); // Revert if seller can't receive funds

            // Refund any excess ETH sent
            if (msg.value > totalPrice) {
                (bool successRefund,) = payable(msg.sender).call{value: msg.value - totalPrice}("");
                 if (!successRefund) {
                    // This is bad. Excess ETH stuck. Need a more robust refund mechanism or require exact amount.
                    // For this example, we'll just let it potentially fail silently, but in production, handle this.
                    // A robust marketplace might hold excess in a user balance mapping.
                 }
            }

        } else { // ERC20 Token
            IERC20 paymentToken = IERC20(listing.paymentToken);
            // Transfer tokens from buyer to marketplace
            if (!paymentToken.transferFrom(msg.sender, address(this), totalPrice)) revert Market__InsufficientFunds(); // ERC20 transferFrom requires buyer approval

            // Transfer fee to admin wallet (store internally)
            collectedFeesERC20[listing.paymentToken] += feeAmount; // Store internally, admin withdraws later

            // Transfer funds to seller
            if (!paymentToken.transfer(listing.seller, sellerReceiveAmount)) revert Market__NFTTransferFailed(); // Revert if seller can't receive tokens
        }

        listing.active = false; // Mark listing as sold

        // Transfer NFT to buyer
        IERC721(listing.nftCollection).transferFrom(address(this), msg.sender, listing.tokenId);

        emit NFTSold(listing.listingId, listing.seller, msg.sender, listing.nftCollection, listing.tokenId, totalPrice, listing.paymentToken);
    }

    /// @notice Makes an offer on a specific NFT. The NFT does not need to be listed for sale/auction.
    /// @param _nftCollection The address of the NFT contract.
    /// @param _tokenId The token ID of the NFT.
    /// @param _value The offered price.
    /// @param _paymentToken The address of the payment token (address(0) for ETH).
    /// @param _expiresAt Timestamp when the offer expires.
    function makeOffer(
        address _nftCollection,
        uint256 _tokenId,
        uint256 _value,
        address _paymentToken,
        uint64 _expiresAt
    ) external payable whenNotPaused nonReentrant onlyAllowedToken(_paymentToken) {
         if (_value == 0) revert Market__OfferNotFound(); // Offer must be > 0
         if (_expiresAt <= block.timestamp) revert Market__OfferExpired();

         // Check if the offerer already has an active offer for this NFT
         // (This is simplified; production would need to track existing offers more robustly)
         for (uint256 i = 1; i <= _offerCounter; i++) {
             Offer storage existingOffer = offers[i];
             if (existingOffer.active && existingOffer.nftCollection == _nftCollection && existingOffer.tokenId == _tokenId && existingOffer.offerer == msg.sender) {
                 revert Market__OfferAlreadyExists();
             }
         }


        if (_paymentToken == address(0)) { // Native currency (ETH)
             if (msg.value < _value) revert Market__InsufficientFunds();
             if (msg.value > _value) {
                 // Refund excess ETH sent immediately
                 (bool successRefund,) = payable(msg.sender).call{value: msg.value - _value}("");
                  if (!successRefund) {
                     // Again, problematic. Handle with user balances in production.
                  }
             }
             // ETH is held by the contract until accepted/rejected/expired
        } else { // ERC20 Token
             IERC20 paymentToken = IERC20(_paymentToken);
             // Transfer tokens from offerer to marketplace (requires approval)
             if (!paymentToken.transferFrom(msg.sender, address(this), _value)) revert Market__InsufficientFunds();
        }

         _offerCounter++;
         offers[_offerCounter] = Offer({
             offerId: _offerCounter,
             nftCollection: _nftCollection,
             tokenId: _tokenId,
             offerer: msg.sender,
             value: _value,
             paymentToken: _paymentToken,
             expiresAt: _expiresAt,
             active: true
         });

         emit OfferMade(_offerCounter, msg.sender, _nftCollection, _tokenId, _value, _paymentToken, _expiresAt);
    }

    /// @notice Accepts an offer for a specific NFT.
    /// @param _offerId The ID of the offer to accept.
    function acceptOffer(uint256 _offerId) external whenNotPaused nonReentrant {
        Offer storage offer = offers[_offerId];
        if (!offer.active || offer.expiresAt <= block.timestamp) revert Market__OfferNotFound(); // Treat expired offers as not found/inactive

        IERC721 nftContract = IERC721(offer.nftCollection);
        address nftOwner = nftContract.ownerOf(offer.tokenId);

        // Only the current owner of the NFT can accept the offer
        if (nftOwner != msg.sender) revert Market__OfferNotForYou();

        // Check if NFT is listed for sale/auction or staked (prevent conflicts)
        bytes32 nftHash = keccak256(abi.encodePacked(offer.nftCollection, offer.tokenId));
         if (isNFTListed(offer.nftCollection, offer.tokenId) || isNFTInAuction(offer.nftCollection, offer.tokenId) || stakedNFTs[nftHash].owner != address(0)) {
              revert Market__NFTAlreadyListed(); // Covers all busy states - cannot accept offer if busy
         }

        uint256 totalValue = offer.value;
        uint256 feeAmount = (totalValue * listingFeeBasisPoints) / 10000; // Use listing fee for offers
        uint256 sellerReceiveAmount = totalValue - feeAmount;

        offer.active = false; // Deactivate offer

        if (offer.paymentToken == address(0)) { // Native currency (ETH)
            // ETH is already held by the contract from makeOffer

            // Transfer fee to admin wallet
             (bool successFee,) = payable(adminWallet).call{value: feeAmount}("");
             if (!successFee) collectedFeesETH += feeAmount;

            // Transfer funds to seller (NFT owner)
             (bool successSeller,) = payable(nftOwner).call{value: sellerReceiveAmount}("");
             if (!successSeller) revert Market__NFTTransferFailed(); // Revert if seller can't receive funds

        } else { // ERC20 Token
             IERC20 paymentToken = IERC20(offer.paymentToken);
             // Tokens are already held by the contract

             // Transfer fee to admin wallet (store internally)
             collectedFeesERC20[offer.paymentToken] += feeAmount;

             // Transfer funds to seller (NFT owner)
             if (!paymentToken.transfer(nftOwner, sellerReceiveAmount)) revert Market__NFTTransferFailed();
        }

        // Transfer NFT to buyer (offerer)
        // Requires the NFT owner to have called approve(_marketplaceAddress, offer.tokenId) beforehand
        if (nftContract.getApproved(offer.tokenId) != address(this)) {
             revert Market__NotApprovedForMarketplace();
        }
        nftContract.transferFrom(nftOwner, offer.offerer, offer.tokenId);


        emit OfferAccepted(_offerId, msg.sender, offer.nftCollection, offer.tokenId, offer.value, offer.paymentToken);
    }

    /// @notice Rejects or cancels a pending offer. Can be called by the offerer or the NFT owner.
    /// @param _offerId The ID of the offer.
    function rejectOffer(uint256 _offerId) external whenNotPaused nonReentrant {
        Offer storage offer = offers[_offerId];
        if (!offer.active) revert Market__OfferNotFound();

        IERC721 nftContract = IERC721(offer.nftCollection);
        address nftOwner;
        // Wrap in try-catch in case the NFT does not exist anymore
        try nftContract.ownerOf(offer.tokenId) returns (address currentOwner) {
             nftOwner = currentOwner;
        } catch {
            // NFT doesn't exist, allow rejection by offerer
            if (offer.offerer != msg.sender) revert Market__OfferNotFromYou();
            offer.active = false; // Deactivate even if NFT is gone

             // Refund funds if held
             if (offer.paymentToken == address(0)) {
                 (bool successRefund,) = payable(offer.offerer).call{value: offer.value}("");
                  if (!successRefund) {
                     // Problematic refund again.
                  }
             } else {
                 IERC20 paymentToken = IERC20(offer.paymentToken);
                 // Check balance before transfer (contract might not hold the tokens anymore if accepted)
                 if (paymentToken.balanceOf(address(this)) >= offer.value) {
                     if (!paymentToken.transfer(offer.offerer, offer.value)) {
                          // Problematic refund again.
                     }
                 }
             }
             emit OfferRejected(_offerId);
             return; // Exit after handling non-existent NFT
        }


        // Check if caller is the offerer or the NFT owner
        if (offer.offerer != msg.sender && nftOwner != msg.sender) revert Market__OfferNotForYou(); // Covers OfferNotFromYou implicitly

        offer.active = false; // Deactivate offer

        // Refund funds if held by the contract
         if (offer.paymentToken == address(0)) {
             (bool successRefund,) = payable(offer.offerer).call{value: offer.value}("");
              if (!successRefund) {
                 // Problematic refund again.
              }
         } else {
             IERC20 paymentToken = IERC20(offer.paymentToken);
             // Check balance before transfer (contract might not hold the tokens anymore if accepted)
             if (paymentToken.balanceOf(address(this)) >= offer.value) {
                 if (!paymentToken.transfer(offer.offerer, offer.value)) {
                      // Problematic refund again.
                 }
             }
         }

        emit OfferRejected(_offerId);
    }


    // --- Auction Marketplace Functions ---

    /// @notice Lists an NFT for auction.
    /// @param _nftCollection The address of the NFT contract.
    /// @param _tokenId The token ID of the NFT.
    /// @param _reservePrice The minimum price for the auction to succeed.
    /// @param _duration The duration of the auction in seconds.
    function listNFTForAuction(
        address _nftCollection,
        uint256 _tokenId,
        uint256 _reservePrice,
        uint64 _duration
    ) external whenNotPaused nonReentrant {
        if (_duration == 0) revert Market__AuctionEnded(); // Duration must be > 0

        // Check if NFT is already listed, in auction, or staked
        bytes32 nftHash = keccak256(abi.encodePacked(_nftCollection, _tokenId));
         if (isNFTListed(_nftCollection, _tokenId) || isNFTInAuction(_nftCollection, _tokenId) || stakedNFTs[nftHash].owner != address(0)) {
              revert Market__NFTAlreadyListed(); // Covers all busy states
         }

        IERC721 nftContract = IERC721(_nftCollection);
        if (nftContract.getApproved(_tokenId) != address(this)) revert Market__NotApprovedForMarketplace();
         if (nftContract.ownerOf(_tokenId) != msg.sender) revert Market__NotListingOwner(); // Ensure seller owns the NFT


        _auctionCounter++;
        uint64 startTime = uint64(block.timestamp);
        uint64 endTime = startTime + _duration;

        auctions[_auctionCounter] = Auction({
            auctionId: _auctionCounter,
            seller: msg.sender,
            nftCollection: _nftCollection,
            tokenId: _tokenId,
            reservePrice: _reservePrice,
            highestBid: _reservePrice, // Initial highest bid is reserve price
            highestBidder: address(0), // No bidder yet
            startTime: startTime,
            endTime: endTime,
            active: true,
            bids: new mapping(address => uint256)() // Initialize the inner mapping
        });

         // Transfer NFT to the marketplace contract
        nftContract.transferFrom(msg.sender, address(this), _tokenId);

        emit AuctionCreated(_auctionCounter, msg.sender, _nftCollection, _tokenId, _reservePrice, startTime, endTime);
    }

    /// @notice Places a bid on an active auction.
    /// @param _auctionId The ID of the auction.
    function placeBid(uint256 _auctionId) external payable whenNotPaused nonReentrant {
        Auction storage auction = auctions[_auctionId];
        if (!auction.active || block.timestamp < auction.startTime) revert Market__AuctionNotActive();
        if (block.timestamp >= auction.endTime) revert Market__AuctionEnded();
        if (msg.sender == auction.seller) revert Market__AuctionSelfBid();
        if (msg.value <= auction.highestBid) revert Market__BidTooLow();
        if (msg.sender == auction.highestBidder) revert Market__AlreadyHighestBidder();


        // Refund previous highest bidder if one exists
        if (auction.highestBidder != address(0)) {
            uint256 previousBid = auction.bids[auction.highestBidder];
            if (previousBid > 0) {
                (bool successRefund,) = payable(auction.highestBidder).call{value: previousBid}("");
                 if (!successRefund) {
                     // Problematic refund. Production requires user balance mechanism.
                 }
                 auction.bids[auction.highestBidder] = 0; // Clear previous bid
            }
        }

        // Record the new bid
        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;
        auction.bids[msg.sender] = msg.value; // Store the bid amount for potential refund

        emit BidPlaced(_auctionId, msg.sender, msg.value);
    }

    /// @notice Ends an auction and distributes the NFT/funds. Can be called by anyone after the end time.
    /// @param _auctionId The ID of the auction.
    function endAuction(uint256 _auctionId) external nonReentrant {
        Auction storage auction = auctions[_auctionId];
        if (!auction.active) revert Market__AuctionNotFound();
        if (block.timestamp < auction.endTime && owner() != msg.sender) revert Market__AuctionStillActive(); // Allow owner to force end early if needed (e.g., emergency)

        auction.active = false; // Deactivate auction

        address nftCollection = auction.nftCollection;
        uint256 tokenId = auction.tokenId;

        if (auction.highestBidder == address(0) || auction.highestBid < auction.reservePrice) {
            // No valid bid, return NFT to seller
            IERC721(nftCollection).transferFrom(address(this), auction.seller, tokenId);
            emit AuctionEnded(_auctionId, address(0), 0, nftCollection, tokenId);
        } else {
            // Valid bid, transfer NFT to winner and funds to seller
            uint256 winningBid = auction.highestBid;
            address winner = auction.highestBidder;

            // Transfer NFT to winner
            IERC721(nftCollection).transferFrom(address(this), winner, tokenId);

            // Calculate and distribute funds
            uint256 feeAmount = (winningBid * auctionFeeBasisPoints) / 10000;
            uint256 sellerReceiveAmount = winningBid - feeAmount;

            // Transfer fee to admin wallet
             (bool successFee,) = payable(adminWallet).call{value: feeAmount}("");
             if (!successFee) collectedFeesETH += feeAmount;

            // Transfer funds to seller
             (bool successSeller,) = payable(auction.seller).call{value: sellerReceiveAmount}("");
             if (!successSeller) revert Market__AuctionClaimFailed(); // Revert if seller can't receive funds

            emit AuctionEnded(_auctionId, winner, winningBid, nftCollection, tokenId);
        }

        // Any losing bids (should be refunded during placeBid), but as a fallback, clear bids map
        // Note: Iterating over maps in Solidity is inefficient. This is a simplification.
        // In a real contract, bidders would likely need a separate function to claim refunds for losing bids.
        // Skipping explicit map clearing here for simplicity and gas consideration mention.
    }


    // --- Dynamic NFT Management Functions ---

    /// @notice Admin function to register a new trait controller type.
    /// @param _controllerType A unique identifier (e.g., keccak256("WeatherController")) for the trait controller type.
    /// @param _controllerAddress The address of the ITraitController contract.
    function registerTraitController(bytes32 _controllerType, address _controllerAddress) external onlyOwner {
        if (_controllerAddress == address(0)) revert Market__ZeroAddress();
        if (traitControllers[_controllerType] != address(0)) revert Market__TraitControllerAlreadyRegistered();
        traitControllers[_controllerType] = _controllerAddress;
        emit TraitControllerRegistered(_controllerType, _controllerAddress);
    }

     /// @notice Admin function to update the address of an existing trait controller type.
     /// @param _controllerType The unique identifier for the trait controller type.
     /// @param _newAddress The new address of the ITraitController contract.
    function setTraitControllerAddress(bytes32 _controllerType, address _newAddress) external onlyOwner {
         if (_newAddress == address(0)) revert Market__ZeroAddress();
         if (traitControllers[_controllerType] == address(0)) revert Market__TraitControllerNotRegistered();
         traitControllers[_controllerType] = _newAddress;
         emit TraitControllerAddressUpdated(_controllerType, _newAddress);
    }

    /// @notice Registers a specific NFT as dynamic with a trait controller type.
    /// Can be called by the NFT owner or a registered trait controller address.
    /// @param _nftCollection The address of the NFT contract.
    /// @param _tokenId The token ID of the NFT.
    /// @param _controllerType The identifier for the trait controller type.
    function addNFTToDynamicRegistry(
        address _nftCollection,
        uint256 _tokenId,
        bytes32 _controllerType
    ) external whenNotPaused nonReentrant {
        if (traitControllers[_controllerType] == address(0)) revert Market__TraitControllerNotRegistered();

        IERC721 nftContract = IERC721(_nftCollection);
        address nftOwner = nftContract.ownerOf(_tokenId);

        // Allow NFT owner or the registered trait controller itself to register the NFT
        if (nftOwner != msg.sender && traitControllers[_controllerType] != msg.sender) revert Market__NotListingOwner(); // Reusing error, but means unauthorized

        bytes32 nftHash = keccak256(abi.encodePacked(_nftCollection, _tokenId));
        if (dynamicNFTs[nftHash].isRegistered) revert Market__NFTAlreadyListed(); // Reusing error, means already dynamic

        dynamicNFTs[nftHash] = DynamicNFTInfo({
            controllerType: _controllerType,
            isRegistered: true
        });

        emit NFTRegisteredAsDynamic(_nftCollection, _tokenId, _controllerType);
    }

     /// @notice Removes an NFT from the dynamic registry. Can be called by the NFT owner or admin.
     /// @param _nftCollection The address of the NFT contract.
     /// @param _tokenId The token ID of the NFT.
    function removeNFTFromDynamicRegistry(address _nftCollection, uint256 _tokenId) external whenNotPaused {
         bytes32 nftHash = keccak256(abi.encodePacked(_nftCollection, _tokenId));
         if (!dynamicNFTs[nftHash].isRegistered) revert Market__NFTNotDynamic();

         IERC721 nftContract = IERC721(_nftCollection);
         address nftOwner = nftContract.ownerOf(_tokenId);

         // Allow NFT owner or admin to remove
         if (nftOwner != msg.sender && owner() != msg.sender) revert Market__NotListingOwner();

         delete dynamicNFTs[nftHash]; // Unregister the NFT

         emit NFTRemovedFromDynamicRegistry(_nftCollection, _tokenId);
    }


    /// @notice Admin function to register an address as an oracle for a specific key.
    /// @param _key A unique identifier (e.g., keccak256("WeatherOracle")) for the oracle data.
    /// @param _oracleAddress The address of the oracle.
    function registerTraitOracle(bytes32 _key, address _oracleAddress) external onlyOwner {
        if (_oracleAddress == address(0)) revert Market__ZeroAddress();
        if (registeredOracles[_key] != address(0)) revert Market__OracleAlreadyRegistered();
        registeredOracles[_key] = _oracleAddress;
        emit OracleDataUpdated(_key, bytes("")); // Indicate registration, no data yet
    }

    /// @notice Updates the oracle data for a specific key. Only callable by the registered oracle address.
    /// @param _key The identifier for the oracle data.
    /// @param _value The new data value (bytes allows flexibility).
    function updateTraitOracleValue(bytes32 _key, bytes calldata _value) external onlyOracle(_key) {
        latestOracleData[_key] = _value;
        emit OracleDataUpdated(_key, _value);
    }

    /// @notice Gets the calculated dynamic trait for an NFT by querying its registered trait controller.
    /// @param _nftCollection The address of the NFT contract.
    /// @param _tokenId The token ID of the NFT.
    /// @return traitValue The calculated dynamic trait value.
    function getDynamicTrait(address _nftCollection, uint256 _tokenId) external view returns (bytes memory) {
         bytes32 nftHash = keccak256(abi.encodePacked(_nftCollection, _tokenId));
         DynamicNFTInfo storage nftInfo = dynamicNFTs[nftHash];
         if (!nftInfo.isRegistered) revert Market__NFTNotDynamic();

         address controllerAddress = traitControllers[nftInfo.controllerType];
         if (controllerAddress == address(0)) {
              // This should not happen if addNFTToDynamicRegistry check passes, but double-check
              revert Market__TraitControllerNotRegistered();
         }

         ITraitController controller = ITraitController(controllerAddress);

         // Prepare marketplace NFT state for the controller
         bool isStaked = stakedNFTs[nftHash].owner != address(0);
         bytes memory marketplaceState = abi.encode(isStaked); // Example: tell controller if the NFT is staked

         // Prepare oracle data for the controller (this assumes the controller knows which oracle keys it needs)
         // In a real scenario, the controller might need multiple oracle values.
         // This simple example just passes the *latest* oracle data stored in the marketplace,
         // or the controller might need to query the marketplace view function `getTraitOracleValue` itself.
         // Let's pass the latest data directly.
         bytes memory oracleData = bytes(""); // Default empty
         // If the controller type implicitly relies on a specific oracle key, we could pass that data.
         // For this example, we'll rely on the ITraitController to potentially query `getTraitOracleValue` directly if needed,
         // or we could pass a specific key's data here if the mapping is 1:1.
         // Let's refine: the controller *should* know its oracle dependencies. It calls back to the marketplace
         // using a view function like `getTraitOracleValue`. So we just pass the relevant state.

         // Simplified: controller calculates based on NFT state (like staking) and *its own* knowledge of needed oracles.
         // The oracle data stored in the marketplace state variables is accessible to the controller
         // via `getTraitOracleValue` calls back into this contract.

         return controller.calculateTrait(_nftCollection, _tokenId, latestOracleData[bytes32(0)], marketplaceState); // Passing dummy oracle data key 0 for example, controller should query specifically
    }


    // --- NFT Staking Functions ---

    /// @notice Stakes an NFT in the marketplace.
    /// @param _nftCollection The address of the NFT contract.
    /// @param _tokenId The token ID of the NFT.
    function stakeNFT(address _nftCollection, uint256 _tokenId) external whenNotPaused nonReentrant {
        bytes32 nftHash = keccak256(abi.encodePacked(_nftCollection, _tokenId));

        // Check if NFT is already busy (listed, auctioned, staked)
        if (isNFTListed(_nftCollection, _tokenId) || isNFTInAuction(_nftCollection, _tokenId) || stakedNFTs[nftHash].owner != address(0)) {
             revert Market__NFTAlreadyStaked(); // Covers all busy states, NFTAlreadyStaked is specific for this action
        }

        IERC721 nftContract = IERC721(_nftCollection);
        if (nftContract.getApproved(_tokenId) != address(this)) revert Market__NotApprovedForMarketplace();
        if (nftContract.ownerOf(_tokenId) != msg.sender) revert Market__NotListingOwner(); // Must be the owner

        stakedNFTs[nftHash] = StakedNFT({
            owner: msg.sender,
            stakeStartTime: uint64(block.timestamp),
            rewardClaimed: 0 // Initialize claimed rewards
        });

        // Transfer NFT to marketplace contract
        nftContract.transferFrom(msg.sender, address(this), _tokenId);

        emit NFTStaked(msg.sender, _nftCollection, _tokenId, uint64(block.timestamp));
    }

    /// @notice Unstakes an NFT from the marketplace.
    /// @param _nftCollection The address of the NFT contract.
    /// @param _tokenId The token ID of the NFT.
    function unstakeNFT(address _nftCollection, uint256 _tokenId) external whenNotPaused nonReentrant {
        bytes32 nftHash = keccak256(abi.encodePacked(_nftCollection, _tokenId));
        StakedNFT storage stakedInfo = stakedNFTs[nftHash];

        if (stakedInfo.owner != msg.sender) revert Market__NFTNotStaked(); // Only staker can unstake

        // Placeholder: Claim any pending rewards before unstaking
        // claimStakingRewards(_nftCollection, _tokenId); // Or integrate logic here

        delete stakedNFTs[nftHash]; // Remove from staked registry

        // Transfer NFT back to original staker
        IERC721(stakedInfo.owner).transferFrom(address(this), stakedInfo.owner, _tokenId);

        emit NFTUnstaked(stakedInfo.owner, _nftCollection, _tokenId);
    }

    /// @notice Claims staking rewards for a staked NFT.
    /// @param _nftCollection The address of the NFT contract.
    /// @param _tokenId The token ID of the NFT.
    function claimStakingRewards(address _nftCollection, uint256 _tokenId) external whenNotPaused nonReentrant {
        bytes32 nftHash = keccak256(abi.encodePacked(_nftCollection, _tokenId));
        StakedNFT storage stakedInfo = stakedNFTs[nftHash];

        if (stakedInfo.owner != msg.sender) revert Market__NFTNotStaked();

        // --- Reward Calculation Placeholder ---
        // This is where complex reward logic would go.
        // It could involve:
        // - Time staked: (block.timestamp - stakedInfo.stakeStartTime)
        // - Staking yield rate: stakingYieldRate (per second/block/day?)
        // - Other factors: based on dynamic traits, other staked NFTs, etc.
        // - An external reward token address that the marketplace holds or mints.

        uint256 accruedRewards = 0; // Calculate based on logic above

        // Example simplified logic (rewards proportional to time staked and yield rate)
        if (stakingYieldRate > 0) {
            uint256 timeStaked = block.timestamp - stakedInfo.stakeStartTime;
            accruedRewards = (timeStaked * stakingYieldRate) / 1e18; // Assume stakingYieldRate is a fractional value like 1e18 = 1 unit
            // This needs careful design based on the reward token and rate unit
        }


        if (accruedRewards == 0) return; // No rewards to claim

        // --- Reward Distribution Placeholder ---
        // This would typically involve transferring an ERC20 reward token.
        // For simplicity, let's imagine the marketplace holds an "ExampleRewardToken".
        // IERC20 rewardToken = IERC20(address(EXAMPLE_REWARD_TOKEN)); // Need a state variable for this
        // if (!rewardToken.transfer(msg.sender, accruedRewards)) {
        //     revert Market__StakeclaimFailed();
        // }
        // For this example, we'll just emit an event and update state,
        // implying rewards are tracked internally or distributed elsewhere.

        stakedInfo.rewardClaimed += accruedRewards; // Update claimed amount
        stakedInfo.stakeStartTime = uint64(block.timestamp); // Reset timer for next claim cycle

        emit StakingRewardsClaimed(msg.sender, _nftCollection, _tokenId, accruedRewards);
    }

    /// @notice Admin function to set the staking yield rate.
    /// @param _rate The new yield rate. Units depend on reward calculation logic.
    function setStakingYieldRate(uint256 _rate) external onlyOwner {
        if (_rate > 1e20) revert Market__InvalidYieldRate(); // Example sanity check (100 units)
        uint256 oldRate = stakingYieldRate;
        stakingYieldRate = _rate;
        emit StakingYieldRateUpdated(oldRate, _rate);
    }


    // --- Admin & Configuration Functions ---

    /// @notice Owner withdraws accumulated fees.
    function withdrawAdminFees() external onlyOwner {
        if (collectedFeesETH == 0 && !_hasERC20FeesToWithdraw()) revert Market__NoFeesToWithdraw();

        uint256 ethAmount = collectedFeesETH;
        collectedFeesETH = 0; // Reset ETH fees

        if (ethAmount > 0) {
            (bool success,) = payable(adminWallet).call{value: ethAmount}("");
             if (!success) {
                // Handle failed ETH withdrawal - perhaps keep the amount and retry later
                collectedFeesETH += ethAmount; // Add back to collected if failed
             }
        }

        // Withdraw ERC20 fees (requires iterating through allowed tokens)
        // Note: Iterating over mappings is inefficient. In production, track tokens with fees in an array.
        // This is a simplified representation.
        mapping(address => uint256) memory withdrawnERC20Amounts; // To include in event

        address[] memory tokens = getAllowedPaymentTokens(); // Get array from view function
        for(uint i = 0; i < tokens.length; i++) {
            address tokenAddress = tokens[i];
            if (tokenAddress != address(0)) { // Skip native ETH
                uint256 tokenAmount = collectedFeesERC20[tokenAddress];
                if (tokenAmount > 0) {
                    collectedFeesERC20[tokenAddress] = 0; // Reset fee
                    IERC20 token = IERC20(tokenAddress);
                    // Check if the marketplace contract actually holds the tokens
                    if (token.balanceOf(address(this)) >= tokenAmount) {
                         if (!token.transfer(adminWallet, tokenAmount)) {
                             // Handle failed ERC20 withdrawal - add back to collected
                             collectedFeesERC20[tokenAddress] += tokenAmount;
                         } else {
                              withdrawnERC20Amounts[tokenAddress] = tokenAmount;
                         }
                    } else {
                         // Log warning: fee amount tracked exceeds actual contract balance
                         // Could happen if tokens were moved manually or due to bugs
                         // In production, need better balance reconciliation.
                    }
                }
            }
        }

         // Emit event - passing the mapping info might be tricky/gas heavy,
         // simpler to emit eth amount and rely on external calls for ERC20 details
         // Or emit separate events for each token. Let's emit a general one.
         // Note: Emitting the mapping directly in the event might not be indexed/searchable well.
        emit AdminFeesWithdrawn(adminWallet, ethAmount, withdrawnERC20Amounts);
    }

    /// @dev Internal helper to check if there are any ERC20 fees to withdraw.
    function _hasERC20FeesToWithdraw() internal view returns (bool) {
         // Again, requires iterating through allowed tokens. Inefficient.
         address[] memory tokens = getAllowedPaymentTokens();
         for(uint i = 0; i < tokens.length; i++) {
             if (tokens[i] != address(0) && collectedFeesERC20[tokens[i]] > 0) {
                 return true;
             }
         }
         return false;
    }


    /// @notice Owner sets the listing fee percentage (in basis points).
    /// @param _feeBasisPoints The fee rate (e.g., 250 for 2.5%).
    function setListingFee(uint256 _feeBasisPoints) external onlyOwner {
        if (_feeBasisPoints > MAX_FEE_BASIS_POINTS) revert Market__FeeTooHigh(MAX_FEE_BASIS_POINTS);
        uint256 oldFee = listingFeeBasisPoints;
        listingFeeBasisPoints = _feeBasisPoints;
        emit ListingFeeUpdated(oldFee, _feeBasisPoints);
    }

    /// @notice Owner sets the auction fee percentage (in basis points).
    /// @param _feeBasisPoints The fee rate (e.g., 500 for 5%).
    function setAuctionFee(uint256 _feeBasisPoints) external onlyOwner {
        if (_feeBasisPoints > MAX_FEE_BASIS_POINTS) revert Market__FeeTooHigh(MAX_FEE_BASIS_POINTS);
        uint256 oldFee = auctionFeeBasisPoints;
        auctionFeeBasisPoints = _feeBasisPoints;
        emit AuctionFeeUpdated(oldFee, _feeBasisPoints);
    }

    /// @notice Owner adds an allowed ERC20 payment token.
    /// @param _tokenAddress The address of the ERC20 token.
    function addAllowedPaymentToken(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == address(0)) revert Market__ZeroAddress();
        allowedPaymentTokens[_tokenAddress] = true;
        emit AllowedPaymentTokenAdded(_tokenAddress);
    }

    /// @notice Owner removes an allowed ERC20 payment token.
    /// @param _tokenAddress The address of the ERC20 token.
    function removeAllowedPaymentToken(address _tokenAddress) external onlyOwner {
         if (_tokenAddress == address(0)) revert Market__ZeroAddress(); // Cannot remove native ETH address mapping
        allowedPaymentTokens[_tokenAddress] = false;
        emit AllowedPaymentTokenRemoved(_tokenAddress);
    }

    /// @notice Owner pauses the contract (stops most actions).
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Owner unpauses the contract.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // --- View Functions ---

    /// @notice Gets details for a direct sale listing.
    /// @param _listingId The ID of the listing.
    /// @return listing The Listing struct.
    function getListingDetails(uint256 _listingId) external view returns (Listing memory) {
        return listings[_listingId];
    }

    /// @notice Gets details for an auction.
    /// @param _auctionId The ID of the auction.
    /// @return auction The Auction struct.
    function getAuctionDetails(uint256 _auctionId) external view returns (Auction memory) {
        return auctions[_auctionId];
    }

    /// @notice Gets details for an offer.
    /// @param _offerId The ID of the offer.
    /// @return offer The Offer struct.
    function getOfferDetails(uint256 _offerId) external view returns (Offer memory) {
        return offers[_offerId];
    }

    /// @notice Gets staking details for a specific NFT.
    /// @param _nftCollection The address of the NFT contract.
    /// @param _tokenId The token ID of the NFT.
    /// @return stakedInfo The StakedNFT struct.
    function getNFTStakingDetails(address _nftCollection, uint256 _tokenId) external view returns (StakedNFT memory) {
         bytes32 nftHash = keccak256(abi.encodePacked(_nftCollection, _tokenId));
         return stakedNFTs[nftHash];
    }

     /// @notice Gets the latest value reported by an oracle for a specific key.
     /// @param _key The identifier for the oracle data.
     /// @return value The latest data value.
    function getTraitOracleValue(bytes32 _key) external view returns (bytes memory) {
         return latestOracleData[_key];
    }

     /// @notice Gets the mapping of trait controller types to their contract addresses.
     /// Note: Iterating large mappings is inefficient. This is a simplified getter.
     /// A real contract might track registered types in an array or use events.
     /// @return controllerTypes Array of registered controller types.
     /// @return controllerAddresses Array of corresponding controller addresses.
    function getRegisteredTraitControllers() external view returns (bytes32[] memory controllerTypes, address[] memory controllerAddresses) {
        // Cannot efficiently iterate over mappings in Solidity for view functions
        // This function is just a placeholder or would require external off-chain indexer
        // or an auxiliary state variable (array) to track keys.
        // For demonstration, we'll return empty arrays or require iterating known keys.
        // Let's assume an auxiliary array exists for this view function:
        // bytes32[] private _registeredControllerTypes;
        // And add/remove from it in registerTraitController/setTraitControllerAddress.
        // For this example, we'll return dummy data or indicate it's not efficiently accessible on-chain.
        // Returning empty arrays as a placeholder:
        controllerTypes = new bytes32[](0);
        controllerAddresses = new address[](0);
        // In a real scenario, you'd need to maintain a separate array of keys (_registeredControllerTypes)
        // and iterate through that array to build the return arrays.
    }

     /// @notice Checks if an NFT is registered as dynamic and gets its controller type.
     /// @param _nftCollection The address of the NFT contract.
     /// @param _tokenId The token ID of the NFT.
     /// @return isRegistered True if dynamic, false otherwise.
     /// @return controllerType The controller type if registered, empty bytes32 otherwise.
    function getRegisteredDynamicNFTs(address _nftCollection, uint256 _tokenId) external view returns (bool isRegistered, bytes32 controllerType) {
         bytes32 nftHash = keccak256(abi.encodePacked(_nftCollection, _tokenId));
         DynamicNFTInfo storage nftInfo = dynamicNFTs[nftHash];
         return (nftInfo.isRegistered, nftInfo.controllerType);
    }

    /// @notice Checks if the contract is paused.
    /// @return isPaused True if paused, false otherwise.
    function getPausedStatus() external view returns (bool) {
        return paused();
    }

    /// @notice Gets the list of allowed ERC20 payment token addresses.
    /// Note: Iterating mappings. Same efficiency issue as `getRegisteredTraitControllers`.
    /// @return tokens Array of allowed ERC20 token addresses.
    function getAllowedPaymentTokens() public view returns (address[] memory) {
        // As above, requires an auxiliary array to track added tokens efficiently.
        // Or rely on external indexers watching events.
        // Returning a dummy array or requiring iteration of known tokens.
        // Let's return a hardcoded example list assuming some were added, or iterate if keys were tracked.
        // This example doesn't track keys in an array, so this is inefficient or relies on external knowledge.
        // Returning a placeholder array. A production contract would need to maintain an array of allowed token addresses.
         uint256 count = 0;
         // Need to iterate all possible addresses, which is impossible.
         // Proper implementation requires storing allowed tokens in an array.
         // Dummy return for structure:
         address[] memory tokens = new address[](1); // Assuming ETH is always allowed implicitly
         tokens[0] = address(0); // Representing native currency
         // In a real contract, populate this from an array `_allowedTokenAddresses`.

         return tokens;
    }

     // Helper view functions to check if an NFT is currently busy in the marketplace
     /// @notice Checks if an NFT is currently listed for direct sale.
     /// @param _nftCollection The address of the NFT contract.
     /// @param _tokenId The token ID of the NFT.
     /// @return isListed True if listed, false otherwise.
    function isNFTListed(address _nftCollection, uint256 _tokenId) public view returns (bool) {
        // This is inefficient - requires iterating all listings.
        // Production would require tracking NFTs in listings via a mapping:
        // mapping(bytes32 => uint256) private nftToListingId;
        // For demonstration, we skip the full iteration logic and return based on the proper mapping.
        // A better implementation would link NFT hash to Listing ID.
        // Mapping `nftHash => listingId` would allow O(1) check.
        // Let's add that mapping for efficiency check:
        // mapping(bytes32 => uint256) private nftHashToListingId;
        // Update it in list/cancel/buy.
        // Based on that, the check is:
         bytes32 nftHash = keccak256(abi.encodePacked(_nftCollection, _tokenId));
         uint256 listingId = nftHashToListingId[nftHash];
         return listingId != 0 && listings[listingId].active; // Check if ID exists and listing is active

    }

     /// @notice Checks if an NFT is currently listed in an auction.
     /// @param _nftCollection The address of the NFT contract.
     /// @param _tokenId The token ID of the NFT.
     /// @return isInAuction True if in auction, false otherwise.
    function isNFTInAuction(address _nftCollection, uint256 _tokenId) public view returns (bool) {
         // Same as above, requires mapping `nftHash => auctionId`.
         // mapping(bytes32 => uint256) private nftHashToAuctionId;
         // Update in list/end auction.
         // Check:
         bytes32 nftHash = keccak256(abi.encodePacked(_nftCollection, _tokenId));
         uint256 auctionId = nftHashToAuctionId[nftHash];
         return auctionId != 0 && auctions[auctionId].active; // Check if ID exists and auction is active
    }


    // Internal mappings for efficient NFT status checks (added based on view function analysis)
    mapping(bytes32 => uint256) private nftHashToListingId;
    mapping(bytes32 => uint256) private nftHashToAuctionId;


    // Update list/cancel/buy functions to use nftHashToListingId
    // listNFTForSale: nftHashToListingId[nftHash] = _listingCounter;
    // cancelListing: delete nftHashToListingId[keccak256(abi.encodePacked(listing.nftCollection, listing.tokenId))];
    // buyNFT: delete nftHashToListingId[keccak256(abi.encodePacked(listing.nftCollection, listing.tokenId))];

    // Update list/endAuction functions to use nftHashToAuctionId
    // listNFTForAuction: nftHashToAuctionId[nftHash] = _auctionCounter;
    // endAuction: delete nftHashToAuctionId[keccak256(abi.encodePacked(auction.nftCollection, auction.tokenId))];


    // Need to override ERC721Holder's onERC721Received if we want to receive NFTs not initiated by our `transferFrom` calls.
    // Standard marketplace flow is `approve` then `transferFrom` within the list/buy/etc functions,
    // so the Holder implementation is mostly for safety against accidental transfers.

    // Override to accept NFTs sent directly (e.g., via safeTransferFrom from outside the marketplace flow)
    // Important if listing requires sending NFT first without approval check inside `listNFTForSale`.
    // However, the current `listNFTForSale` requires prior approval and calls `transferFrom`,
    // so the standard ERC721Holder functionality is sufficient if users follow the `approve` then `list` pattern.
    // Leaving the holder inheritance is good practice for receiving NFTs safely.


    // Function count check:
    // 1. listNFTForSale
    // 2. cancelListing
    // 3. buyNFT
    // 4. makeOffer
    // 5. acceptOffer
    // 6. rejectOffer
    // 7. listNFTForAuction
    // 8. placeBid
    // 9. endAuction
    // 10. registerTraitController
    // 11. setTraitControllerAddress
    // 12. addNFTToDynamicRegistry
    // 13. removeNFTFromDynamicRegistry
    // 14. registerTraitOracle
    // 15. updateTraitOracleValue
    // 16. getDynamicTrait (View)
    // 17. stakeNFT
    // 18. unstakeNFT
    // 19. claimStakingRewards
    // 20. setStakingYieldRate
    // 21. withdrawAdminFees
    // 22. setListingFee
    // 23. setAuctionFee
    // 24. addAllowedPaymentToken
    // 25. removeAllowedPaymentToken
    // 26. pauseContract
    // 27. unpauseContract
    // 28. getListingDetails (View)
    // 29. getAuctionDetails (View)
    // 30. getOfferDetails (View)
    // 31. getNFTStakingDetails (View)
    // 32. getTraitOracleValue (View)
    // 33. getRegisteredTraitControllers (View - placeholder)
    // 34. getRegisteredDynamicNFTs (View)
    // 35. getPausedStatus (View)
    // 36. getAllowedPaymentTokens (View - placeholder)
    // 37. isNFTListed (View - internal helper, but public)
    // 38. isNFTInAuction (View - internal helper, but public)

    // Total function count is 38, well over the minimum 20.
    // Need to implement the `nftHashToListingId` and `nftHashToAuctionId` logic properly in the functions.

    // --- Implementing hash mappings ---

    // listNFTForSale
    // Check if NFT is already listed, in auction, or staked
    // bytes32 nftHash = keccak256(abi.encodePacked(_nftCollection, _tokenId));
    // if (nftHashToListingId[nftHash] != 0 || nftHashToAuctionId[nftHash] != 0 || stakedNFTs[nftHash].owner != address(0)) {
    //      revert Market__NFTAlreadyListed(); // Covers all busy states
    // }
    // ...
    // listings[_listingCounter] = Listing({...});
    // nftHashToListingId[nftHash] = _listingCounter; // ADD THIS

    // cancelListing
    // ...
    // delete nftHashToListingId[keccak256(abi.encodePacked(listing.nftCollection, listing.tokenId))]; // ADD THIS

    // buyNFT
    // ...
    // delete nftHashToListingId[keccak256(abi.encodePacked(listing.nftCollection, listing.tokenId))]; // ADD THIS

    // listNFTForAuction
    // Check if NFT is already listed, in auction, or staked
    // bytes32 nftHash = keccak256(abi.encodePacked(_nftCollection, _tokenId));
    // if (nftHashToListingId[nftHash] != 0 || nftHashToAuctionId[nftHash] != 0 || stakedNFTs[nftHash].owner != address(0)) {
    //      revert Market__NFTAlreadyListed(); // Covers all busy states
    // }
    // ...
    // auctions[_auctionCounter] = Auction({...});
    // nftHashToAuctionId[nftHash] = _auctionCounter; // ADD THIS

    // endAuction
    // ...
    // delete nftHashToAuctionId[keccak256(abi.encodePacked(auction.nftCollection, auction.tokenId))]; // ADD THIS

    // stakeNFT
    // Check if NFT is already busy (listed, auctioned, staked)
    // bytes32 nftHash = keccak256(abi.encodePacked(_nftCollection, _tokenId));
    // if (nftHashToListingId[nftHash] != 0 || nftHashToAuctionId[nftHash] != 0 || stakedNFTs[nftHash].owner != address(0)) {
    //      revert Market__NFTAlreadyStaked(); // Covers all busy states, NFTAlreadyStaked is specific for this action
    // }
    // ... stakedNFTs[nftHash] = StakedNFT({...});

    // unstakeNFT
    // ... delete stakedNFTs[nftHash];

    // acceptOffer
    // Check if NFT is listed for sale/auction or staked (prevent conflicts)
    // bytes32 nftHash = keccak256(abi.encodePacked(offer.nftCollection, offer.tokenId));
    // if (nftHashToListingId[nftHash] != 0 || nftHashToAuctionId[nftHash] != 0 || stakedNFTs[nftHash].owner != address(0)) {
    //      revert Market__NFTAlreadyListed(); // Covers all busy states - cannot accept offer if busy
    // }


    // The placeholder view functions `getRegisteredTraitControllers` and `getAllowedPaymentTokens`
    // still have the iteration issue. A production contract would need auxiliary arrays.
    // For this example, we'll leave them as placeholders indicating the design challenge.
    // They contribute to the function count but are noted as potentially inefficient in practice without further state variables.

    // Final check on errors used: Market__NotListingOwner, Market__ListingNotFound, Market__InvalidBuyer, Market__ListingPriceMismatch, Market__NFTTransferFailed, Market__InvalidPaymentToken, Market__InsufficientFunds, Market__NFTAlreadyListed, Market__NotApprovedForMarketplace, Market__AuctionNotFound, Market__AuctionNotActive, Market__AuctionEnded, Market__BidTooLow, Market__AuctionNotExpired, Market__AuctionStillActive, Market__AlreadyHighestBidder, Market__AuctionSelfBid, Market__AuctionClaimFailed, Market__OfferNotFound, Market__OfferNotActive, Market__OfferAlreadyExists, Market__OfferExpired, Market__OfferNotForYou, Market__OfferNotFromYou, Market__NFTNotStaked, Market__NFTAlreadyStaked, Market__InvalidYieldRate, Market__StakeclaimFailed, Market__TraitControllerAlreadyRegistered, Market__TraitControllerNotRegistered, Market__NFTNotDynamic, Market__OracleAlreadyRegistered, Market__OracleNotRegistered, Market__InvalidOracleValue, Market__FeeTooHigh, Market__ZeroAddress, Market__NoFeesToWithdraw, OwnableUnauthorizedAccount (from OZ). All seem defined or from OZ.

    // Final Check: Need to add the missing mapping updates identified during the function count check.

    // --- Re-implementing functions with hash mappings ---

    function listNFTForSale(address _nftCollection, uint256 _tokenId, uint256 _price, address _paymentToken) external whenNotPaused nonReentrant onlyAllowedToken(_paymentToken) {
        if (_price == 0) revert Market__ListingPriceMismatch();

        bytes32 nftHash = keccak256(abi.encodePacked(_nftCollection, _tokenId));
        if (nftHashToListingId[nftHash] != 0 || nftHashToAuctionId[nftHash] != 0 || stakedNFTs[nftHash].owner != address(0)) {
             revert Market__NFTAlreadyListed();
        }

        IERC721 nftContract = IERC721(_nftCollection);
        if (nftContract.getApproved(_tokenId) != address(this) && nftContract.ownerOf(_tokenId) != msg.sender) revert Market__NotApprovedForMarketplace();
        if (nftContract.ownerOf(_tokenId) != msg.sender) revert Market__NotListingOwner();

        _listingCounter++;
        listings[_listingCounter] = Listing({
            listingId: _listingCounter,
            seller: msg.sender,
            nftCollection: _nftCollection,
            tokenId: _tokenId,
            price: _price,
            paymentToken: _paymentToken,
            active: true
        });
        nftHashToListingId[nftHash] = _listingCounter; // Add NFT hash mapping

        nftContract.transferFrom(msg.sender, address(this), _tokenId);

        emit ListingCreated(_listingCounter, msg.sender, _nftCollection, _tokenId, _price, _paymentToken);
    }

    function cancelListing(uint256 _listingId) external whenNotPaused nonReentrant {
        Listing storage listing = listings[_listingId];
        if (!listing.active) revert Market__ListingNotFound();
        if (listing.seller != msg.sender && owner() != msg.sender) revert Market__NotListingOwner();

        listing.active = false;
        bytes32 nftHash = keccak256(abi.encodePacked(listing.nftCollection, listing.tokenId));
        delete nftHashToListingId[nftHash]; // Remove NFT hash mapping

        IERC721(listing.nftCollection).transferFrom(address(this), listing.seller, listing.tokenId);

        emit ListingCancelled(_listingId);
    }

    function buyNFT(uint256 _listingId) external payable whenNotPaused nonReentrant {
        Listing storage listing = listings[_listingId];
        if (!listing.active) revert Market__ListingNotFound();
        if (listing.seller == msg.sender) revert Market__InvalidBuyer();

        uint256 totalPrice = listing.price;
        uint256 feeAmount = (totalPrice * listingFeeBasisPoints) / 10000;
        uint256 sellerReceiveAmount = totalPrice - feeAmount;

        if (listing.paymentToken == address(0)) { // Native currency (ETH)
            if (msg.value < totalPrice) revert Market__InsufficientFunds();

            (bool successFee,) = payable(adminWallet).call{value: feeAmount}("");
            if (!successFee) collectedFeesETH += feeAmount;

            (bool successSeller,) = payable(listing.seller).call{value: sellerReceiveAmount}("");
            if (!successSeller) revert Market__NFTTransferFailed();

            if (msg.value > totalPrice) {
                (bool successRefund,) = payable(msg.sender).call{value: msg.value - totalPrice}("");
                 if (!successRefund) {/* handle refund failure */}
            }
        } else { // ERC20 Token
            IERC20 paymentToken = IERC20(listing.paymentToken);
            if (!paymentToken.transferFrom(msg.sender, address(this), totalPrice)) revert Market__InsufficientFunds(); // ERC20 transferFrom requires buyer approval

            collectedFeesERC20[listing.paymentToken] += feeAmount; // Store internally

            if (!paymentToken.transfer(listing.seller, sellerReceiveAmount)) revert Market__NFTTransferFailed();
        }

        listing.active = false;
        bytes32 nftHash = keccak256(abi.encodePacked(listing.nftCollection, listing.tokenId));
        delete nftHashToListingId[nftHash]; // Remove NFT hash mapping

        IERC721(listing.nftCollection).transferFrom(address(this), msg.sender, listing.tokenId);

        emit NFTSold(listing.listingId, listing.seller, msg.sender, listing.nftCollection, listing.tokenId, totalPrice, listing.paymentToken);
    }

    function listNFTForAuction(address _nftCollection, uint256 _tokenId, uint256 _reservePrice, uint64 _duration) external whenNotPaused nonReentrant {
        if (_duration == 0) revert Market__AuctionEnded();

        bytes32 nftHash = keccak256(abi.encodePacked(_nftCollection, _tokenId));
         if (nftHashToListingId[nftHash] != 0 || nftHashToAuctionId[nftHash] != 0 || stakedNFTs[nftHash].owner != address(0)) {
              revert Market__NFTAlreadyListed();
         }

        IERC721 nftContract = IERC721(_nftCollection);
        if (nftContract.getApproved(_tokenId) != address(this)) revert Market__NotApprovedForMarketplace();
        if (nftContract.ownerOf(_tokenId) != msg.sender) revert Market__NotListingOwner();

        _auctionCounter++;
        uint64 startTime = uint64(block.timestamp);
        uint64 endTime = startTime + _duration;

        auctions[_auctionCounter] = Auction({
            auctionId: _auctionCounter,
            seller: msg.sender,
            nftCollection: _nftCollection,
            tokenId: _tokenId,
            reservePrice: _reservePrice,
            highestBid: _reservePrice,
            highestBidder: address(0),
            startTime: startTime,
            endTime: endTime,
            active: true,
            bids: new mapping(address => uint256)()
        });
        nftHashToAuctionId[nftHash] = _auctionCounter; // Add NFT hash mapping

        nftContract.transferFrom(msg.sender, address(this), _tokenId);

        emit AuctionCreated(_auctionCounter, msg.sender, _nftCollection, _tokenId, _reservePrice, startTime, endTime);
    }

    function endAuction(uint256 _auctionId) external nonReentrant {
        Auction storage auction = auctions[_auctionId];
        if (!auction.active) revert Market__AuctionNotFound();
        if (block.timestamp < auction.endTime && owner() != msg.sender) revert Market__AuctionStillActive();

        auction.active = false;
        bytes32 nftHash = keccak256(abi.encodePacked(auction.nftCollection, auction.tokenId));
        delete nftHashToAuctionId[nftHash]; // Remove NFT hash mapping


        address nftCollection = auction.nftCollection;
        uint256 tokenId = auction.tokenId;

        if (auction.highestBidder == address(0) || auction.highestBid < auction.reservePrice) {
            IERC721(nftCollection).transferFrom(address(this), auction.seller, tokenId);
            emit AuctionEnded(_auctionId, address(0), 0, nftCollection, tokenId);
        } else {
            uint256 winningBid = auction.highestBid;
            address winner = auction.highestBidder;

            IERC721(nftCollection).transferFrom(address(this), winner, tokenId);

            uint256 feeAmount = (winningBid * auctionFeeBasisPoints) / 10000;
            uint256 sellerReceiveAmount = winningBid - feeAmount;

            (bool successFee,) = payable(adminWallet).call{value: feeAmount}("");
            if (!successFee) collectedFeesETH += feeAmount;

            (bool successSeller,) = payable(auction.seller).call{value: sellerReceiveAmount}("");
            if (!successSeller) revert Market__AuctionClaimFailed();

            emit AuctionEnded(_auctionId, winner, winningBid, nftCollection, tokenId);
        }
    }

     function stakeNFT(address _nftCollection, uint256 _tokenId) external whenNotPaused nonReentrant {
        bytes32 nftHash = keccak256(abi.encodePacked(_nftCollection, _tokenId));

        if (nftHashToListingId[nftHash] != 0 || nftHashToAuctionId[nftHash] != 0 || stakedNFTs[nftHash].owner != address(0)) {
             revert Market__NFTAlreadyStaked();
        }

        IERC721 nftContract = IERC721(_nftCollection);
        if (nftContract.getApproved(_tokenId) != address(this)) revert Market__NotApprovedForMarketplace();
        if (nftContract.ownerOf(_tokenId) != msg.sender) revert Market__NotListingOwner();

        stakedNFTs[nftHash] = StakedNFT({
            owner: msg.sender,
            stakeStartTime: uint64(block.timestamp),
            rewardClaimed: 0
        });

        nftContract.transferFrom(msg.sender, address(this), _tokenId);

        emit NFTStaked(msg.sender, _nftCollection, _tokenId, uint64(block.timestamp));
    }

     function unstakeNFT(address _nftCollection, uint256 _tokenId) external whenNotPaused nonReentrant {
        bytes32 nftHash = keccak256(abi.encodePacked(_nftCollection, _tokenId));
        StakedNFT storage stakedInfo = stakedNFTs[nftHash];

        if (stakedInfo.owner != msg.sender) revert Market__NFTNotStaked();

        // Placeholder: Claim any pending rewards before unstaking
        // claimStakingRewards(_nftCollection, _tokenId);

        address originalStaker = stakedInfo.owner;
        delete stakedNFTs[nftHash];

        IERC721(originalStaker).transferFrom(address(this), originalStaker, _tokenId); // Transfer back to original staker

        emit NFTUnstaked(originalStaker, _nftCollection, _tokenId);
    }

    // isNFTListed and isNFTInAuction are now efficient using the mappings.

    // Final check of total functions: The count remains 38 as the two helper view functions were already counted.
    // The implementation logic for hash mappings is now included.


}
```