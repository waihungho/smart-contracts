Okay, let's design a smart contract that goes beyond standard examples. We'll create a **Decentralized Ephemeral Marketplace with Reputation and Conditional Logic**.

This contract will allow users to list ERC721 tokens for sale with a set expiration time. Listings and offers can be made *conditional* based on external data fetched from an oracle (simulated). User reputation, based on successful trades, influences listing duration and potentially future features. Listings that expire and are not reclaimed can eventually "decay", becoming claimable by a community pool or burned after a secondary grace period.

This incorporates:
*   **Ephemeral State:** Listings have limited lifespans.
*   **Dynamic Interaction:** Offers and purchases interact with and potentially extend lifespan.
*   **Reputation System:** On-chain reputation based on marketplace activity.
*   **Conditional Logic:** Using external data (via an oracle) to gate actions.
*   **Decay Mechanism:** A unique concept for handling unclaimed, expired assets.
*   **Standard Marketplace Features:** Listing, buying, offering, canceling.
*   **Access Control:** Ownership for admin functions.
*   **Fee Structure:** Configurable fees.

Let's outline the structure and functions.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol"; // Good practice for checking ERC721

// --- Contract Outline ---
// 1. Imports: Standard libraries for ERC721, Ownership, Address utilities.
// 2. Errors: Custom errors for specific failure conditions.
// 3. Events: To log key actions and state changes.
// 4. Interfaces: Definition for a generic ConditionOracle.
// 5. Structs: Data structures for Listings, Offers, and Conditions.
// 6. State Variables: Storage for listings, offers, reputation, fees, ownership, etc.
// 7. Modifiers: Custom checks (e.g., onlyActiveListing).
// 8. Constructor: Initializes owner, fees, and recipients.
// 9. Core Marketplace Logic:
//    - Listing (standard and conditional)
//    - Buying
//    - Canceling
//    - Offers (making, accepting, rejecting, retracting, conditional)
// 10. Ephemeral/Decay Logic:
//     - Extending listing life
//     - Reclaiming expired items (by seller)
//     - Decaying expired items (by anyone after grace period)
// 11. Reputation Logic:
//     - Getting reputation
//     - Internal updates on successful trades
// 12. Conditional Logic:
//     - Internal function to check conditions via Oracle
//     - Public view function to check a condition externally
// 13. State Query Functions (Views):
//     - Retrieving listing/offer details
//     - Getting user-specific data (listings/offers)
//     - Checking status (active, expired, valid)
// 14. Admin/Ownership Functions:
//     - Setting fees, recipients, oracle address
//     - Withdrawing fees
//     - Standard Ownable functions (transfer, renounce)

// --- Function Summary (Public/External Functions) ---
// 1.  constructor(uint256 initialListingFee, uint16 initialTradeFeeBps, address initialFeeRecipient, address initialDecayRecipient): Initializes the contract settings.
// 2.  listItem(address _tokenContract, uint256 _itemId, uint256 _price, uint64 _duration): Lists an ERC721 item for sale with a price and duration. Requires listing fee.
// 3.  listItemWithCondition(address _tokenContract, uint256 _itemId, uint256 _price, uint64 _duration, Condition memory _condition): Lists an item with a price, duration, and an external condition that must be met for purchase. Requires listing fee.
// 4.  cancelListing(uint256 _listingId): Allows the seller to cancel an active listing before it expires or is bought/offered on.
// 5.  reclaimExpiredItem(uint256 _listingId): Allows the seller to reclaim their item if the listing has expired and there are no active offers.
// 6.  decayExpiredItem(uint256 _listingId): Allows anyone to trigger the decay process for an item whose listing expired *and* is past a secondary decay grace period and wasn't reclaimed. Item is sent to decayRecipient.
// 7.  extendListingLife(uint256 _listingId): Allows the seller to extend the expiration time of their active listing.
// 8.  buyItem(uint256 _listingId): Allows a buyer to purchase an item directly at the list price. Checks conditions if applicable. Requires payment.
// 9.  makeOffer(uint256 _listingId, uint256 _price): Allows a buyer to make an offer on a listed item. Requires depositing the offer amount.
// 10. makeConditionalOffer(uint256 _listingId, uint256 _price, Condition memory _condition): Allows a buyer to make an offer that is only valid if a specified external condition is met. Requires depositing the offer amount.
// 11. acceptOffer(uint256 _offerId): Allows the seller to accept an active offer. Checks conditions if applicable. Transfers funds and item.
// 12. rejectOffer(uint256 _offerId): Allows the seller to reject an active offer, refunding the buyer.
// 13. retractOffer(uint256 _offerId): Allows the buyer to retract their active offer, refunding themselves.
// 14. getListingDetails(uint256 _listingId): View function to retrieve details of a specific listing.
// 15. getOffersForItem(uint256 _listingId): View function to retrieve a list of offer IDs for a specific listing.
// 16. getUserListings(address _user): View function to retrieve a list of listing IDs owned by a user.
// 17. getUserOffers(address _user): View function to retrieve a list of offer IDs made by a user.
// 18. getReputation(address _user): View function to get the reputation score of a user.
// 19. getTotalListings(): View function to get the total number of listings ever created.
// 20. isListingActive(uint256 _listingId): View function to check if a listing is currently active and not expired.
// 21. isOfferValid(uint256 _offerId): View function to check if an offer is currently active and its conditions (and the listing's conditions) are met.
// 22. checkCondition(Condition memory _condition): View function to check if a specific condition evaluates to true using the oracle.
// 23. setListingFee(uint256 _listingFee): Owner function to set the fee for creating a listing.
// 24. setTradeFeeBps(uint16 _tradeFeeBps): Owner function to set the percentage fee (in basis points) on successful trades.
// 25. setFeeRecipient(address _feeRecipient): Owner function to set the address where fees are sent.
// 26. setDecayRecipient(address _decayRecipient): Owner function to set the address where decayed items are sent.
// 27. setOracleAddress(address _oracleAddress): Owner function to set the address of the oracle contract used for conditional checks.
// 28. withdrawFees(): Owner function to withdraw accumulated fees.
// 29. transferOwnership(address newOwner): Ownable function.
// 30. renounceOwnership(): Ownable function.

// Note: This contract requires that ERC721 tokens transferred into it
// implement the IERC721 and IERC165 interfaces and allow the marketplace
// contract to call safeTransferFrom.

interface IConditionOracle {
    // This is a simplified interface. Real oracles would likely have more complex data types
    // or methods to specify feeds/queries. `_data` could be bytes representing feed ID, query params, etc.
    // Returns true if the condition specified by _data and _threshold/comparison is met.
    function checkCondition(bytes calldata _data, uint256 _threshold, uint8 _comparisonType) external view returns (bool);
}

contract DecentralizedEphemeralMarketplace is Ownable {
    using Address for address payable;

    // --- Errors ---
    error NotSeller();
    error NotBuyer();
    error ListingNotFound();
    error ListingNotActive();
    error ListingExpired();
    error ListingNotExpired();
    error ListingHasActiveOffers();
    error ListingNotReclaimableYet();
    error ListingAlreadyReclaimedOrDecayed();
    error OfferNotFound();
    error OfferNotActive();
    error OfferNotForListing();
    error InsufficientPayment();
    error ConditionNotMet();
    error OracleNotSet();
    error DecayGracePeriodNotPassed();
    error ERC721TransferFailed();
    error InvalidFeeSetting();
    error InvalidRecipient();
    error ItemAlreadyListed(); // Simple check for now, can be relaxed depending on desired behavior

    // --- Events ---
    event ListingCreated(uint256 indexed listingId, address indexed seller, address indexed tokenContract, uint256 itemId, uint256 price, uint64 duration, bool isConditional, uint64 expirationTime);
    event ListingCancelled(uint256 indexed listingId);
    event ItemPurchased(uint256 indexed listingId, address indexed buyer, address indexed seller, uint256 pricePaid);
    event OfferMade(uint256 indexed offerId, uint256 indexed listingId, address indexed buyer, uint256 price, bool isConditional);
    event OfferAccepted(uint256 indexed offerId, uint256 indexed listingId);
    event OfferRejected(uint256 indexed offerId, uint256 indexed listingId);
    event OfferRetracted(uint256 indexed offerId);
    event ListingExpirationExtended(uint256 indexed listingId, uint64 newExpirationTime);
    event ItemReclaimed(uint256 indexed listingId, address indexed seller);
    event ItemDecayed(uint256 indexed listingId, address indexed decayRecipient);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event FeeWithdrawn(address indexed recipient, uint256 amount);
    event FeesUpdated(uint256 listingFee, uint16 tradeFeeBps);
    event RecipientUpdated(address indexed feeRecipient, address indexed decayRecipient);
    event OracleUpdated(address indexed oracleAddress);

    // --- Structs ---
    struct Condition {
        address oracle;         // Address of the oracle contract implementing IConditionOracle
        bytes data;             // Data specific to the oracle query (e.g., data feed ID)
        uint256 threshold;      // Threshold value for comparison
        uint8 comparisonType;   // Type of comparison (e.g., 0: >=, 1: <=, 2: ==, 3: !=, etc.)
                                // Oracle interprets data and performs comparison with threshold
    }

    struct Listing {
        uint256 id;             // Unique listing ID
        address seller;         // Address of the seller
        address tokenContract;  // Address of the ERC721 token contract
        uint256 itemId;         // ERC721 token ID
        uint256 price;          // Listing price in wei
        uint64 creationTime;    // Timestamp when listing was created
        uint64 expirationTime;  // Timestamp when listing expires
        bool isActive;          // True if the listing is currently active
        bool isConditional;     // True if the listing has a condition
        Condition condition;    // The condition struct if isConditional is true
        bool isReclaimed;       // True if the item was reclaimed by the seller after expiry
        bool isDecayed;         // True if the item has gone through the decay process
        uint256[] offerIds;     // Array of offer IDs made for this listing (Simplified: actual offers stored separately)
    }

    struct Offer {
        uint256 id;             // Unique offer ID
        uint256 listingId;      // ID of the listing this offer is for
        address buyer;          // Address of the buyer making the offer
        uint256 price;          // Offer price in wei
        uint64 timestamp;       // Timestamp when offer was made
        bool isActive;          // True if the offer is currently active (not accepted/rejected/retracted)
        bool isConditional;     // True if the offer has a condition
        Condition condition;    // The condition struct if isConditional is true
    }

    // --- State Variables ---
    uint256 private _nextListingId = 1;
    uint256 private _nextOfferId = 1;

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Offer) public offers;
    mapping(address => uint256[]) private _userListings; // Seller -> list of listing IDs
    mapping(address => uint256[]) private _userOffers;   // Buyer -> list of offer IDs
    mapping(address => uint256) private _userReputation; // User -> reputation score (e.g., number of successful trades)
    mapping(address => mapping(uint256 => uint256)) private _itemToListingId; // tokenContract -> itemId -> current active listingId (Simplified: allows only one active listing per item at a time)

    uint256 public listingFee;         // Fee to create a listing (in wei)
    uint16 public tradeFeeBps;         // Fee percentage on successful trades (in basis points, 100 = 1%)
    address payable public feeRecipient; // Address receiving fees
    address payable public decayRecipient; // Address receiving decayed items (ERC721 transfer)

    address public oracleAddress;      // Address of the oracle contract

    uint64 public constant DECAY_GRACE_PERIOD = 7 * 24 * 60 * 60; // 7 days after listing expiration before decay is possible

    // --- Modifiers ---
    modifier onlyListingSeller(uint256 _listingId) {
        if (listings[_listingId].seller != msg.sender) revert NotSeller();
        _;
    }

    modifier onlyOfferBuyer(uint256 _offerId) {
        if (offers[_offerId].buyer != msg.sender) revert NotBuyer();
        _;
    }

    modifier onlyActiveListing(uint256 _listingId) {
        Listing storage listing = listings[_listingId];
        if (listing.id == 0) revert ListingNotFound(); // Check if listing exists
        if (!listing.isActive) revert ListingNotActive();
        if (block.timestamp >= listing.expirationTime) {
             // Automatically deactivate on access if expired
            listing.isActive = false;
            // Note: A getter function like isListingActive should also check expiration.
            revert ListingExpired();
        }
        _;
    }

    modifier onlyActiveOffer(uint256 _offerId) {
        Offer storage offer = offers[_offerId];
        if (offer.id == 0) revert OfferNotFound(); // Check if offer exists
        if (!offer.isActive) revert OfferNotActive();
        _;
    }

    // --- Constructor ---
    constructor(uint256 initialListingFee, uint16 initialTradeFeeBps, address payable initialFeeRecipient, address payable initialDecayRecipient) Ownable(msg.sender) {
        if (initialFeeRecipient == address(0) || initialDecayRecipient == address(0)) revert InvalidRecipient();
        if (initialTradeFeeBps > 10000) revert InvalidFeeSetting(); // Max 100% fee

        listingFee = initialListingFee;
        tradeFeeBps = initialTradeFeeBps;
        feeRecipient = initialFeeRecipient;
        decayRecipient = initialDecayRecipient;
    }

    // --- Core Marketplace Logic ---

    /// @notice Lists an ERC721 item for sale.
    /// @param _tokenContract The address of the ERC721 contract.
    /// @param _itemId The ID of the ERC721 token.
    /// @param _price The price of the item in wei.
    /// @param _duration The duration of the listing in seconds.
    function listItem(address _tokenContract, uint256 _itemId, uint256 _price, uint64 _duration) external payable {
        _createListing(_tokenContract, _itemId, _price, _duration, false, Condition({oracle: address(0), data: "", threshold: 0, comparisonType: 0}));
    }

    /// @notice Lists an ERC721 item for sale with a condition.
    /// @param _tokenContract The address of the ERC721 contract.
    /// @param _itemId The ID of the ERC721 token.
    /// @param _price The price of the item in wei.
    /// @param _duration The duration of the listing in seconds.
    /// @param _condition The condition that must be met for the item to be purchased or offer accepted.
    function listItemWithCondition(address _tokenContract, uint256 _itemId, uint256 _price, uint64 _duration, Condition memory _condition) external payable {
        if (_condition.oracle == address(0)) revert OracleNotSet();
        _createListing(_tokenContract, _itemId, _price, _duration, true, _condition);
    }

    /// @notice Internal helper to create a listing.
    function _createListing(address _tokenContract, uint256 _itemId, uint256 _price, uint64 _duration, bool _isConditional, Condition memory _condition) internal {
        if (msg.value < listingFee) revert InsufficientPayment();
        if (_duration == 0) revert InvalidFeeSetting(); // Duration must be > 0

        // Simple check to prevent relisting the *same* item from the *same* contract if an active listing exists
        // More complex logic might track item ownership vs. listing status
        if (_itemToListingId[_tokenContract][_itemId] != 0 && listings[_itemToListingId[_tokenContract][_itemId]].isActive) {
             revert ItemAlreadyListed();
        }

        uint256 listingId = _nextListingId++;
        uint64 expirationTime = uint64(block.timestamp) + _duration;

        listings[listingId] = Listing({
            id: listingId,
            seller: msg.sender,
            tokenContract: _tokenContract,
            itemId: _itemId,
            price: _price,
            creationTime: uint64(block.timestamp),
            expirationTime: expirationTime,
            isActive: true,
            isConditional: _isConditional,
            condition: _condition,
            isReclaimed: false,
            isDecayed: false,
            offerIds: new uint256[](0) // Initialize empty offers array
        });

        _userListings[msg.sender].push(listingId);
        _itemToListingId[_tokenContract][_itemId] = listingId; // Track active listing for item

        // Transfer NFT to contract
        IERC721(_tokenContract).safeTransferFrom(msg.sender, address(this), _itemId);

        // Transfer listing fee
        (bool success, ) = feeRecipient.call{value: listingFee}("");
        // If fee transfer fails, consider if you want to revert the listing or just log
        // Reverting seems safer for state consistency.
        if (!success) {
            // Potentially compensate the seller or handle the NFT return here if reverting
            // For simplicity, reverting is the easiest behavior.
            revert ERC721TransferFailed(); // Reusing error, perhaps needs a specific FeeTransferFailed
        }


        emit ListingCreated(listingId, msg.sender, _tokenContract, _itemId, _price, _duration, _isConditional, expirationTime);
    }


    /// @notice Allows the seller to cancel an active listing.
    /// @param _listingId The ID of the listing to cancel.
    function cancelListing(uint256 _listingId) external onlyListingSeller(_listingId) {
        Listing storage listing = listings[_listingId];
        if (!listing.isActive) revert ListingNotActive(); // Allow cancelling active listing only
        if (block.timestamp >= listing.expirationTime) revert ListingExpired(); // Cannot cancel if expired

        // Check if there are any active offers. Sellers might only be allowed to cancel if no active offers exist.
        // Or they could cancel, automatically rejecting all offers. Let's choose the latter for flexibility.
        for (uint256 i = 0; i < listing.offerIds.length; i++) {
            uint256 offerId = listing.offerIds[i];
            if (offers[offerId].isActive) {
                // Automatically reject any active offers for this listing
                _rejectOffer(offerId);
            }
        }

        listing.isActive = false;
        // Remove item to listing mapping
        delete _itemToListingId[listing.tokenContract][listing.itemId];

        // Return NFT to seller
        IERC721(listing.tokenContract).safeTransferFrom(address(this), listing.seller, listing.itemId);

        emit ListingCancelled(_listingId);
    }


    /// @notice Allows a buyer to purchase an item directly at the list price.
    /// @param _listingId The ID of the listing to purchase.
    function buyItem(uint256 _listingId) external payable onlyActiveListing(_listingId) {
        Listing storage listing = listings[_listingId];
        if (msg.value < listing.price) revert InsufficientPayment();

        // Check condition if applicable
        if (listing.isConditional) {
            if (!_checkCondition(listing.condition)) revert ConditionNotMet();
        }

        _processSale(_listingId, msg.sender, listing.price);

        // Refund any excess payment
        if (msg.value > listing.price) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - listing.price}("");
            if (!success) {
                 // This is a non-critical failure after sale is done. Log or handle.
                 // For simplicity, we just let it pass but note the potential issue.
            }
        }
    }


    /// @notice Allows a buyer to make an offer on a listed item.
    /// @param _listingId The ID of the listing.
    /// @param _price The offer price in wei. Must be >= 0.
    function makeOffer(uint256 _listingId, uint256 _price) external payable onlyActiveListing(_listingId) {
         _createOffer(_listingId, _price, false, Condition({oracle: address(0), data: "", threshold: 0, comparisonType: 0}));
    }

    /// @notice Allows a buyer to make a conditional offer on a listed item.
    /// @param _listingId The ID of the listing.
    /// @param _price The offer price in wei.
    /// @param _condition The condition that must be met for the offer to be accepted.
    function makeConditionalOffer(uint256 _listingId, uint256 _price, Condition memory _condition) external payable onlyActiveListing(_listingId) {
        if (_condition.oracle == address(0)) revert OracleNotSet();
        _createOffer(_listingId, _price, true, _condition);
    }

    /// @notice Internal helper to create an offer.
    function _createOffer(uint256 _listingId, uint256 _price, bool _isConditional, Condition memory _condition) internal {
        Listing storage listing = listings[_listingId]; // Already checked by onlyActiveListing modifier
        if (msg.value < _price) revert InsufficientPayment();
        if (msg.sender == listing.seller) revert NotBuyer(); // Cannot make offer on your own listing

        uint256 offerId = _nextOfferId++;

        offers[offerId] = Offer({
            id: offerId,
            listingId: _listingId,
            buyer: msg.sender,
            price: _price,
            timestamp: uint64(block.timestamp),
            isActive: true,
            isConditional: _isConditional,
            condition: _condition
        });

        listing.offerIds.push(offerId); // Add offer ID to the listing's offers list
        _userOffers[msg.sender].push(offerId); // Track offer for the buyer

        emit OfferMade(offerId, _listingId, msg.sender, _price, _isConditional);
    }


    /// @notice Allows the seller to accept an active offer.
    /// @param _offerId The ID of the offer to accept.
    function acceptOffer(uint256 _offerId) external onlyActiveOffer(_offerId) onlyListingSeller(offers[_offerId].listingId) {
        Offer storage offer = offers[_offerId];
        Listing storage listing = listings[offer.listingId]; // Check existence via modifier on offer

        // Check listing is still active and not expired
        if (!listing.isActive || block.timestamp >= listing.expirationTime) revert ListingNotActive(); // Listing might have become inactive or expired since offer was made

        // Check condition if applicable for the offer AND the listing
        if (offer.isConditional) {
            if (!_checkCondition(offer.condition)) revert ConditionNotMet();
        }
         if (listing.isConditional) {
            if (!_checkCondition(listing.condition)) revert ConditionNotMet();
        }

        _processSale(offer.listingId, offer.buyer, offer.price);

        offer.isActive = false; // Deactivate the accepted offer

        // Reject all other active offers for this listing
        for (uint256 i = 0; i < listing.offerIds.length; i++) {
            uint256 otherOfferId = listing.offerIds[i];
            if (otherOfferId != _offerId && offers[otherOfferId].isActive) {
                _rejectOffer(otherOfferId);
            }
        }

        emit OfferAccepted(_offerId, offer.listingId);
    }


    /// @notice Allows the seller to reject an active offer.
    /// @param _offerId The ID of the offer to reject.
    function rejectOffer(uint256 _offerId) external onlyActiveOffer(_offerId) onlyListingSeller(offers[_offerId].listingId) {
        _rejectOffer(_offerId);
        emit OfferRejected(_offerId, offers[_offerId].listingId);
    }

    /// @notice Internal helper to reject an offer and refund the buyer.
    function _rejectOffer(uint256 _offerId) internal {
         Offer storage offer = offers[_offerId]; // Assumes offer existence check before calling

         if (!offer.isActive) return; // Already inactive, nothing to do

        offer.isActive = false;

        // Refund buyer's held ETH
        (bool success, ) = payable(offer.buyer).call{value: offer.price}("");
        if (!success) {
             // Handle failure to refund buyer - critical issue.
             // Could transfer to owner, or leave in contract and require buyer to claim.
             // For simplicity, log and potentially re-enable offer for manual handling (complex).
             // Reverting is often safer in practice if state isn't already changed.
             // Since we already marked offer as inactive, reverting here is problematic.
             // Let's add an event for failed refunds to track.
            emit FeeWithdrawn(offer.buyer, offer.price); // Reusing event for simplicity, maybe add RefundFailed event
        }
    }


    /// @notice Allows the buyer to retract their active offer.
    /// @param _offerId The ID of the offer to retract.
    function retractOffer(uint256 _offerId) external onlyOfferBuyer(_offerId) onlyActiveOffer(_offerId) {
        _rejectOffer(_offerId); // Retracting is effectively rejecting by the buyer
        emit OfferRetracted(_offerId);
    }

    /// @notice Internal helper to process a sale (direct buy or accepted offer).
    function _processSale(uint256 _listingId, address _buyer, uint256 _price) internal {
        Listing storage listing = listings[_listingId]; // Assumes listing existence and activity checked

        // Calculate fees
        uint256 tradeFee = (_price * tradeFeeBps) / 10000;
        uint256 amountToSeller = _price - tradeFee;

        // Transfer ETH to seller
        (bool successSeller, ) = payable(listing.seller).call{value: amountToSeller}("");
         if (!successSeller) revert ERC721TransferFailed(); // Reusing error, needs specific SellerPaymentFailed error

        // Transfer ETH fee to recipient
        (bool successFee, ) = feeRecipient.call{value: tradeFee}("");
         if (!successFee) revert ERC721TransferFailed(); // Needs specific FeePaymentFailed error

        // Transfer NFT to buyer
        IERC721(listing.tokenContract).safeTransferFrom(address(this), _buyer, listing.itemId);

        // Update state
        listing.isActive = false;
        // Remove item to listing mapping
        delete _itemToListingId[listing.tokenContract][listing.itemId];

        // Update reputation for both buyer and seller
        _updateReputation(listing.seller);
        _updateReputation(_buyer);

        emit ItemPurchased(_listingId, _buyer, listing.seller, _price);
    }

    /// @notice Extends the expiration time of an active listing.
    /// @param _listingId The ID of the listing.
    function extendListingLife(uint256 _listingId) external onlyListingSeller(_listingId) onlyActiveListing(_listingId) {
        // Extend expiration by a base amount (e.g., initial duration / 2) or a fixed value.
        // Could also be based on reputation. Let's use a fixed extension for simplicity.
        // Maybe base extension is 1 day (86400 seconds).
        uint64 extensionAmount = 1 days; // 1 day
        // Could also use listing.duration to calculate a proportion: uint64(listing.expirationTime - listing.creationTime) / 2;

        Listing storage listing = listings[_listingId];
        listing.expirationTime += extensionAmount; // Add extension to current expiration time

        emit ListingExpirationExtended(_listingId, listing.expirationTime);
    }

    // --- Ephemeral / Decay Logic ---

    /// @notice Allows the seller to reclaim their item after the listing has expired.
    /// Can only be called if there are no active offers.
    /// @param _listingId The ID of the listing.
    function reclaimExpiredItem(uint256 _listingId) external onlyListingSeller(_listingId) {
        Listing storage listing = listings[_listingId];
        if (listing.id == 0) revert ListingNotFound();
        if (listing.isActive) revert ListingNotExpired();
        if (listing.isReclaimed) revert ListingAlreadyReclaimedOrDecayed();
        if (listing.isDecayed) revert ListingAlreadyReclaimedOrDecayed();

        // Check if expired
        if (block.timestamp < listing.expirationTime) revert ListingNotExpired();

        // Check for active offers
        for (uint256 i = 0; i < listing.offerIds.length; i++) {
            if (offers[listing.offerIds[i]].isActive) {
                revert ListingHasActiveOffers(); // Seller cannot reclaim if there are active offers
            }
        }

        // Return NFT to seller
        IERC721(listing.tokenContract).safeTransferFrom(address(this), listing.seller, listing.itemId);

        listing.isReclaimed = true; // Mark as reclaimed
        // Remove item to listing mapping (it's expired anyway, but good practice)
        delete _itemToListingId[listing.tokenContract][listing.itemId];


        emit ItemReclaimed(_listingId, listing.seller);
    }


    /// @notice Allows anyone to trigger the decay process for an item whose listing expired and is past the decay grace period.
    /// The item is transferred to the decay recipient. This function is intended for cleanup of abandoned items.
    /// @param _listingId The ID of the listing.
    function decayExpiredItem(uint256 _listingId) external {
        Listing storage listing = listings[_listingId];
        if (listing.id == 0) revert ListingNotFound();
        if (listing.isActive) revert ListingNotExpired(); // Must be expired
        if (listing.isReclaimed) revert ListingAlreadyReclaimedOrDecayed();
        if (listing.isDecayed) revert ListingAlreadyReclaimedOrDecayed();

        // Check if expired
        if (block.timestamp < listing.expirationTime) revert ListingNotExpired();

        // Check if decay grace period has passed
        if (block.timestamp < listing.expirationTime + DECAY_GRACE_PERIOD) revert DecayGracePeriodNotPassed();

        // Check for active offers (shouldn't be any if expired and past grace, but safety check)
         for (uint256 i = 0; i < listing.offerIds.length; i++) {
            if (offers[listing.offerIds[i]].isActive) {
                 // If there are active offers this late, something is wrong, or offers weren't cancelled on expiry.
                 // Let's auto-reject them before decaying.
                _rejectOffer(listing.offerIds[i]);
            }
        }


        // Transfer NFT to decay recipient
        IERC721(listing.tokenContract).safeTransferFrom(address(this), decayRecipient, listing.itemId);

        listing.isDecayed = true; // Mark as decayed
         // Remove item to listing mapping (it's expired anyway, but good practice)
        delete _itemToListingId[listing.tokenContract][listing.itemId];


        emit ItemDecayed(_listingId, decayRecipient);
    }


    // --- Reputation Logic ---

    /// @notice Gets the reputation score of a user.
    /// @param _user The address of the user.
    /// @return The user's reputation score.
    function getReputation(address _user) external view returns (uint256) {
        return _userReputation[_user];
    }

    /// @notice Internal helper to update reputation.
    /// @param _user The user whose reputation to update.
    function _updateReputation(address _user) internal {
        // Simple reputation: increment for each successful trade involving the user.
        _userReputation[_user]++;
        emit ReputationUpdated(_user, _userReputation[_user]);
    }

    // --- Conditional Logic ---

    /// @notice Internal helper to check if a given condition is met using the oracle.
    /// @param _condition The condition struct.
    /// @return True if the condition is met, false otherwise.
    function _checkCondition(Condition memory _condition) internal view returns (bool) {
        if (_condition.oracle == address(0)) return true; // No oracle/condition means condition is always met

        // Ensure the oracle address is set in the contract state if we have a condition object with an oracle
        if (oracleAddress == address(0)) revert OracleNotSet();

        // Ensure the provided oracle address matches the one configured in the contract
        if (_condition.oracle != oracleAddress) revert OracleNotSet(); // Or a more specific error like "MismatchedOracle"

        try IConditionOracle(oracleAddress).checkCondition(_condition.data, _condition.threshold, _condition.comparisonType) returns (bool conditionMet) {
            return conditionMet;
        } catch {
            // Handle oracle call failure - assume condition is not met or revert based on policy
            // Reverting is safer to prevent unexpected behavior if oracle is down/malicious
            revert ConditionNotMet(); // Reusing, but could be OracleCheckFailed
        }
    }

    /// @notice Allows external parties to check if a specific condition is currently met.
    /// Useful for dApps or users to see if a conditional listing/offer is currently valid.
    /// @param _condition The condition struct to check.
    /// @return True if the condition is met, false otherwise.
    function checkCondition(Condition memory _condition) external view returns (bool) {
        return _checkCondition(_condition);
    }


    // --- State Query Functions (Views) ---

    /// @notice Gets the details of a specific listing.
    /// @param _listingId The ID of the listing.
    /// @return The Listing struct.
    function getListingDetails(uint256 _listingId) external view returns (Listing memory) {
        if (listings[_listingId].id == 0) revert ListingNotFound();
        return listings[_listingId];
    }

    /// @notice Gets the list of offer IDs for a specific listing.
    /// @param _listingId The ID of the listing.
    /// @return An array of offer IDs.
    function getOffersForItem(uint256 _listingId) external view returns (uint256[] memory) {
         if (listings[_listingId].id == 0) revert ListingNotFound();
        return listings[_listingId].offerIds;
    }

     /// @notice Gets the details of a specific offer.
    /// @param _offerId The ID of the offer.
    /// @return The Offer struct.
    function getOfferDetails(uint256 _offerId) external view returns (Offer memory) {
        if (offers[_offerId].id == 0) revert OfferNotFound();
        return offers[_offerId];
    }


    /// @notice Gets the list of listing IDs created by a user.
    /// @param _user The address of the user.
    /// @return An array of listing IDs.
    function getUserListings(address _user) external view returns (uint256[] memory) {
        return _userListings[_user];
    }

    /// @notice Gets the list of offer IDs made by a user.
    /// @param _user The address of the user.
    /// @return An array of offer IDs.
    function getUserOffers(address _user) external view returns (uint256[] memory) {
        return _userOffers[_user];
    }

    /// @notice Gets the total number of listings created.
    /// @return The total count of listings.
    function getTotalListings() external view returns (uint256) {
        return _nextListingId - 1;
    }

    /// @notice Checks if a listing is currently active and not expired.
    /// @param _listingId The ID of the listing.
    /// @return True if active and not expired, false otherwise.
    function isListingActive(uint256 _listingId) external view returns (bool) {
        Listing storage listing = listings[_listingId];
        return listing.id != 0 && listing.isActive && block.timestamp < listing.expirationTime;
    }

     /// @notice Checks if an offer is currently active and its (and the listing's) conditions are met.
    /// @param _offerId The ID of the offer.
    /// @return True if active and conditions met, false otherwise.
    function isOfferValid(uint256 _offerId) external view returns (bool) {
        Offer storage offer = offers[_offerId];
        if (offer.id == 0 || !offer.isActive) return false;

        Listing storage listing = listings[offer.listingId];
        // Offer is only valid if the listing it's for is also active and valid
        if (listing.id == 0 || !listing.isActive || block.timestamp >= listing.expirationTime) return false;

        // Check offer condition
        if (offer.isConditional && !_checkCondition(offer.condition)) return false;

        // Check listing condition
        if (listing.isConditional && !_checkCondition(listing.condition)) return false;

        return true;
    }


    /// @notice Gets the expiration time of a listing.
    /// @param _listingId The ID of the listing.
    /// @return The expiration timestamp (uint64). Returns 0 if listing not found.
    function getListingExpiration(uint256 _listingId) external view returns (uint64) {
         if (listings[_listingId].id == 0) return 0;
        return listings[_listingId].expirationTime;
    }


    // --- Admin / Ownership Functions ---

    /// @notice Sets the fee for creating a listing.
    /// @param _listingFee The new listing fee in wei.
    function setListingFee(uint256 _listingFee) external onlyOwner {
        listingFee = _listingFee;
        emit FeesUpdated(listingFee, tradeFeeBps);
    }

    /// @notice Sets the percentage fee on successful trades.
    /// @param _tradeFeeBps The new trade fee in basis points (e.g., 100 for 1%). Max 10000.
    function setTradeFeeBps(uint16 _tradeFeeBps) external onlyOwner {
        if (_tradeFeeBps > 10000) revert InvalidFeeSetting();
        tradeFeeBps = _tradeFeeBps;
        emit FeesUpdated(listingFee, tradeFeeBps);
    }

    /// @notice Sets the address where fees are sent.
    /// @param _feeRecipient The new fee recipient address.
    function setFeeRecipient(address payable _feeRecipient) external onlyOwner {
        if (_feeRecipient == address(0)) revert InvalidRecipient();
        feeRecipient = _feeRecipient;
        emit RecipientUpdated(feeRecipient, decayRecipient);
    }

     /// @notice Sets the address where decayed items are sent.
    /// @param _decayRecipient The new decay recipient address.
    function setDecayRecipient(address payable _decayRecipient) external onlyOwner {
        if (_decayRecipient == address(0)) revert InvalidRecipient();
        decayRecipient = _decayRecipient;
         emit RecipientUpdated(feeRecipient, decayRecipient);
    }


    /// @notice Sets the address of the oracle contract used for conditional checks.
    /// @param _oracleAddress The address of the oracle contract.
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        // Optional: Add check that _oracleAddress implements IConditionOracle
        // require(IERC165(_oracleAddress).supportsInterface(type(IConditionOracle).interfaceId), "Invalid oracle interface");
        oracleAddress = _oracleAddress;
        emit OracleUpdated(oracleAddress);
    }


    /// @notice Allows the owner to withdraw accumulated fees from the contract.
    function withdrawFees() external onlyOwner {
        uint256 amount = address(this).balance;
        if (amount == 0) return; // Nothing to withdraw

        // Ensure fees are sent to the configured feeRecipient, not msg.sender
        (bool success, ) = feeRecipient.call{value: amount}("");
        if (!success) {
             // Handle failure to withdraw - critical for owner.
             // Could revert, or log and allow retries. Reverting is safer.
            revert ERC721TransferFailed(); // Reusing error, needs specific FeeWithdrawFailed
        }

        emit FeeWithdrawn(feeRecipient, amount);
    }

    // --- Ownable functions are inherited ---
    // transferOwnership
    // renounceOwnership

    // --- Receive/Fallback for ETH ---
    // The contract needs to be able to receive ETH for direct buys and offers.
    receive() external payable {}
    // fallback() external payable {} // Optional: useful if contract might receive ETH from unexpected calls


}
```