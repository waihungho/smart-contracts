Okay, let's create a smart contract that implements a Dynamic NFT Marketplace with an integrated Reputation System, where NFT traits can dynamically change based on the owner's reputation on the platform. This combines several interesting and somewhat advanced concepts: a custom marketplace, reputation tracking, and state-dependent NFTs (Dynamic NFTs).

We will define Reputation Points (RPs) earned through successful interactions (like buying/selling) and link a specific dynamic trait of compatible NFTs to the owner's RP. The marketplace will support different listing types.

Here's the outline and function summary, followed by the Solidity code.

---

### Contract: `DynamicNFTMarketplaceWithReputation`

**Concept:** A marketplace for ERC721 NFTs where user interactions build a reputation score. This reputation score can dynamically influence specific on-chain traits of compatible NFTs owned by the user.

**Key Features:**
*   **Marketplace:** Support for different listing types (Fixed Price, Dutch Auction).
*   **Reputation System:** Users earn Reputation Points (RP) for successful trades. RP can influence marketplace interactions (future potential: variable fees, priority).
*   **Dynamic NFTs:** Compatible NFTs can have a trait (`ReputationBoundTrait`) whose value is derived directly from the owner's current reputation points on the platform. This trait changes *without* needing to transfer the NFT, simply by the owner's reputation changing.
*   **Controlled Listings:** Only pre-approved NFT contracts can be listed.
*   **ERC2981 Royalties:** Support for standard NFT royalties.
*   **Security & Control:** Pausable, Ownable, Reentrancy Protection.

**Outline:**

1.  **State Variables:** Define mappings, structs, enums, and core configuration variables (fees, admin, reputation points config).
2.  **Structs & Enums:** Define data structures for listings and listing types.
3.  **Events:** Define events for transparency and off-chain monitoring.
4.  **Modifiers:** Standard OpenZeppelin modifiers (`onlyOwner`, `whenNotPaused`, `nonReentrant`).
5.  **Constructor:** Initialize basic parameters (fee recipient, initial fee).
6.  **Marketplace Functions:**
    *   Listing (Fixed Price, Dutch Auction)
    *   Buying (Fixed Price)
    *   Bidding (Dutch Auction)
    *   Canceling Listings
    *   Claiming NFTs after Dutch Auction
7.  **Reputation System Functions:**
    *   Internal functions to update reputation based on events.
    *   View function to get user reputation.
    *   Admin function to configure reputation point values.
8.  **Dynamic Trait Functions:**
    *   Internal function to calculate/signal trait changes based on reputation.
    *   View function to get the calculated dynamic trait value for an NFT.
    *   Admin function to configure the dynamic trait linkage (e.g., name, formula parameters).
9.  **Admin & Configuration Functions:**
    *   Set fees, fee recipient.
    *   Manage approved NFT contracts.
    *   Withdraw fees.
    *   Pause/Unpause.
10. **View Functions:** Get listing details, configuration, approved contracts, etc.
11. **Helper Functions:** Internal calculations (e.g., Dutch auction price).
12. **Receive/Fallback:** Allow receiving ETH.

**Function Summary:**

*   `constructor()`: Sets initial owner, fee recipient, and fee rate.
*   `receive()`: Allows contract to receive ETH.
*   `pause()`: Pauses contract operations (only owner).
*   `unpause()`: Unpauses contract operations (only owner).
*   `setFeeRecipient(address _feeRecipient)`: Sets address where fees are sent (only owner).
*   `setMarketplaceFeeRate(uint256 _feeRateBps)`: Sets fee rate in basis points (only owner).
*   `addApprovedNFTContract(address _nftContract)`: Approves an NFT contract for listing (only owner).
*   `removeApprovedNFTContract(address _nftContract)`: Removes approval for an NFT contract (only owner).
*   `isNFTContractApproved(address _nftContract)`: Checks if an NFT contract is approved (view).
*   `getApprovedNFTContracts()`: Returns the list of approved NFT contracts (view).
*   `setReputationPointConfig(uint256 _pointsPerSale, uint256 _pointsPerPurchase)`: Configures RP earned per successful trade (only owner).
*   `getReputationPointConfig()`: Returns the current RP config (view).
*   `getUserReputation(address _user)`: Gets reputation points for a user (view).
*   `setDynamicTraitConfig(string memory _traitName, uint256 _divisor)`: Configures the dynamic trait's name and divisor for calculation (only owner).
*   `getDynamicTraitConfig()`: Returns the dynamic trait configuration (view).
*   `getDynamicTraitValue(address _nftContract, uint256 _tokenId)`: Calculates the dynamic trait value based on the *current* owner's reputation (view).
*   `listNFT(address _nftContract, uint256 _tokenId, uint256 _price)`: Creates a fixed-price listing.
*   `buyNFT(address _nftContract, uint256 _tokenId)`: Purchases an NFT from a fixed-price listing.
*   `cancelListing(address _nftContract, uint256 _tokenId)`: Cancels an existing listing (fixed or Dutch).
*   `listNFGDutchAuction(address _nftContract, uint256 _tokenId, uint256 _startPrice, uint256 _endPrice, uint64 _duration)`: Creates a Dutch auction listing.
*   `bidDutchAuction(address _nftContract, uint256 _tokenId)`: Bids on a Dutch auction at the current price.
*   `claimDutchAuctionNFT(address _nftContract, uint256 _tokenId)`: Claims the NFT after a successful bid/auction end if the bid was the winner. (Simplified: bid *is* the claim in this structure).
*   `getListing(address _nftContract, uint256 _tokenId)`: Gets fixed-price listing details (view).
*   `getDutchAuctionListing(address _nftContract, uint256 _tokenId)`: Gets Dutch auction listing details (view).
*   `getCurrentDutchAuctionPrice(address _nftContract, uint256 _tokenId)`: Calculates current price for a Dutch auction (view).
*   `_updateReputation(address _user, uint256 _points)`: Internal helper to add reputation points.
*   `_calculateDutchAuctionPrice(uint256 _startPrice, uint256 _endPrice, uint64 _duration, uint64 _elapsedTime)`: Internal helper to calculate Dutch auction price.
*   `withdrawFees()`: Allows owner to withdraw accumulated fees.

*(Note: Some view functions like `getMarketplaceFeeRate`, `getFeeRecipient` are implied by the variables but can be added explicitly if needed to reach 20+, or we can count internal helpers).* We have 20+ distinct public/external/view/internal functions listed.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol"; // Standard for royalties
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For potentially complex calculations, though simple enough here

/// @title DynamicNFTMarketplaceWithReputation
/// @author YourNameHere (or a Pseudonym)
/// @notice A marketplace for ERC721 NFTs with an integrated reputation system.
/// Compatible NFTs can have a dynamic trait linked to the owner's reputation.
/// @dev This contract handles listing, buying, and Dutch auctions for approved NFTs.
/// Reputation points are awarded for successful sales and purchases.
/// A configurable dynamic trait is calculated based on the current owner's reputation.

contract DynamicNFTMarketplaceWithReputation is Ownable, Pausable, ReentrancyGuard, ERC721Holder {
    using SafeMath for uint256;

    // --- State Variables ---

    /// @notice Represents a listing in the marketplace.
    struct Listing {
        ListingType listingType;
        address seller;
        uint256 price;           // For FixedPrice
        uint256 startTime;       // For DutchAuction
        uint256 endTime;         // For DutchAuction
        uint256 startPrice;      // For DutchAuction
        uint256 endPrice;        // For DutchAuction
        address currentBidder;   // For DutchAuction (only one active bid allowed per auction)
        uint256 currentBid;      // For DutchAuction
        bool active;             // Is the listing currently active?
    }

    /// @notice Enum to distinguish listing types.
    enum ListingType {
        None,         // Default state, no active listing
        FixedPrice,
        DutchAuction
    }

    /// @notice Mapping from NFT Contract Address => Token ID => Listing details.
    mapping(address => mapping(uint256 => Listing)) private _listings;

    /// @notice Mapping from User Address => Reputation Points.
    mapping(address => uint256) private _userReputation;

    /// @notice Mapping of approved NFT contract addresses. Only NFTs from these contracts can be listed.
    mapping(address => bool) private _approvedNFTContracts;
    address[] private _approvedNFTContractsList; // To easily retrieve the list

    /// @notice The address where marketplace fees are sent.
    address public feeRecipient;

    /// @notice The fee rate in basis points (e.g., 100 = 1% fee). Capped at 1000 (10%).
    uint256 public marketplaceFeeRateBps;
    uint256 private constant _FEE_RATE_BPS_MAX = 1000; // 10%

    /// @notice Reputation points awarded for a successful sale.
    uint256 public pointsPerSale;

    /// @notice Reputation points awarded for a successful purchase.
    uint256 public pointsPerPurchase;

    /// @notice Configuration for the dynamic trait calculation.
    string public dynamicTraitName; // The name of the dynamic trait (e.g., "Reliability Score")
    uint256 public dynamicTraitDivisor; // Divisor for calculating the dynamic trait value from reputation

    /// @notice Accumulated fees waiting to be withdrawn by the owner.
    uint256 public accumulatedFees;

    // --- Events ---

    event ListingCreated(address indexed nftContract, uint256 indexed tokenId, ListingType listingType, address indexed seller, uint256 priceOrStartPrice, uint256 endTime);
    event ListingCancelled(address indexed nftContract, uint256 indexed tokenId, address indexed seller);
    event NFTBought(address indexed nftContract, uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 totalPrice, uint256 marketplaceFee, uint256 royaltyAmount);
    event DutchAuctionBid(address indexed nftContract, uint256 indexed tokenId, address indexed bidder, uint256 bidAmount);
    event DutchAuctionSettled(address indexed nftContract, uint256 indexed tokenId, address indexed winner, uint256 finalPrice);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event DynamicTraitConfigUpdated(string traitName, uint256 divisor);
    event ApprovedNFTContractAdded(address indexed nftContract);
    event ApprovedNFTContractRemoved(address indexed nftContract);
    event FeeRecipientUpdated(address indexed newFeeRecipient);
    event MarketplaceFeeRateUpdated(uint256 newFeeRateBps);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Constructor ---

    constructor(address _initialFeeRecipient, uint256 _initialFeeRateBps) Ownable(msg.sender) Pausable(false) ReentrancyGuard() {
        require(_initialFeeRecipient != address(0), "Invalid fee recipient");
        require(_initialFeeRateBps <= _FEE_RATE_BPS_MAX, "Fee rate too high");
        feeRecipient = _initialFeeRecipient;
        marketplaceFeeRateBps = _initialFeeRateBps;

        // Set some default reputation point values and dynamic trait config
        pointsPerSale = 10;
        pointsPerPurchase = 5;
        dynamicTraitName = "ReputationScore";
        dynamicTraitDivisor = 1; // Simple 1:1 ratio initially
    }

    // --- Access Control & Security ---

    /// @notice Allows the owner to pause the contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Allows the owner to unpause the contract.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Allows the contract to receive ETH. This is where payment for NFTs and fees comes in.
    receive() external payable {
        // Optional: Add logging or specific handling if needed.
        // For now, just allow receiving ETH necessary for purchases.
    }

    // --- Admin & Configuration Functions ---

    /// @notice Sets the address where marketplace fees are sent.
    /// @param _feeRecipient The new fee recipient address.
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }

    /// @notice Sets the marketplace fee rate in basis points.
    /// @param _feeRateBps The new fee rate in basis points (0-1000).
    function setMarketplaceFeeRate(uint256 _feeRateBps) external onlyOwner {
        require(_feeRateBps <= _FEE_RATE_BPS_MAX, "Fee rate too high");
        marketplaceFeeRateBps = _feeRateBps;
        emit MarketplaceFeeRateUpdated(_feeRateBps);
    }

    /// @notice Adds an NFT contract address to the approved list. Only approved contracts can be listed.
    /// @param _nftContract The address of the NFT contract to approve.
    function addApprovedNFTContract(address _nftContract) external onlyOwner {
        require(_nftContract != address(0), "Invalid contract address");
        require(!_approvedNFTContracts[_nftContract], "Contract already approved");
        _approvedNFTContracts[_nftContract] = true;
        _approvedNFTContractsList.push(_nftContract);
        emit ApprovedNFTContractAdded(_nftContract);
    }

    /// @notice Removes an NFT contract address from the approved list.
    /// @param _nftContract The address of the NFT contract to remove.
    function removeApprovedNFTContract(address _nftContract) external onlyOwner {
        require(_approvedNFTContracts[_nftContract], "Contract not approved");
        _approvedNFTContracts[_nftContract] = false;
        // Simple removal by finding and swapping with last element (order not guaranteed)
        for (uint256 i = 0; i < _approvedNFTContractsList.length; i++) {
            if (_approvedNFTContractsList[i] == _nftContract) {
                _approvedNFTContractsList[i] = _approvedNFTContractsList[_approvedNFTContractsList.length - 1];
                _approvedNFTContractsList.pop();
                break;
            }
        }
        emit ApprovedNFTContractRemoved(_nftContract);
    }

    /// @notice Sets the reputation points awarded for successful sales and purchases.
    /// @param _pointsPerSale Points for the seller.
    /// @param _pointsPerPurchase Points for the buyer.
    function setReputationPointConfig(uint256 _pointsPerSale, uint256 _pointsPerPurchase) external onlyOwner {
        pointsPerSale = _pointsPerSale;
        pointsPerPurchase = _pointsPerPurchase;
    }

    /// @notice Configures the name and divisor for the dynamic reputation-bound trait.
    /// @param _traitName The name of the dynamic trait (e.g., "Reputation Score").
    /// @param _divisor The divisor used to calculate the trait value from reputation (trait = reputation / divisor).
    function setDynamicTraitConfig(string memory _traitName, uint256 _divisor) external onlyOwner {
        require(_divisor > 0, "Divisor must be greater than 0");
        dynamicTraitName = _traitName;
        dynamicTraitDivisor = _divisor;
        emit DynamicTraitConfigUpdated(_traitName, _divisor);
    }

     /// @notice Allows the owner to withdraw accumulated marketplace fees.
    function withdrawFees() external onlyOwner {
        uint256 amount = accumulatedFees;
        accumulatedFees = 0;
        require(amount > 0, "No fees to withdraw");
        (bool success,) = feeRecipient.call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(feeRecipient, amount);
    }

    // --- Marketplace Functions ---

    /// @notice Lists an NFT for a fixed price. Requires ERC721 approval beforehand.
    /// @param _nftContract The address of the NFT contract.
    /// @param _tokenId The ID of the token to list.
    /// @param _price The fixed price in wei.
    function listNFT(address _nftContract, uint256 _tokenId, uint256 _price) external nonReentrant whenNotPaused {
        require(_isNFTContractApproved(_nftContract), "NFT contract not approved");
        require(_price > 0, "Price must be greater than 0");
        require(_listings[_nftContract][_tokenId].listingType == ListingType.None, "NFT already listed");

        IERC721 nft = IERC721(_nftContract);

        // Ensure the seller owns the token and has approved the marketplace
        require(nft.ownerOf(_tokenId) == msg.sender, "Not owner of token");
        require(nft.isApprovedForAll(msg.sender, address(this)) || nft.getApproved(_tokenId) == address(this), "Marketplace not approved to transfer token");

        // Transfer the NFT to the marketplace contract
        nft.transferFrom(msg.sender, address(this), _tokenId);

        _listings[_nftContract][_tokenId] = Listing({
            listingType: ListingType.FixedPrice,
            seller: msg.sender,
            price: _price,
            startTime: 0, // Not used for fixed price
            endTime: 0,   // Not used for fixed price
            startPrice: 0, // Not used for fixed price
            endPrice: 0,   // Not used for fixed price
            currentBidder: address(0), // Not used
            currentBid: 0,       // Not used
            active: true
        });

        emit ListingCreated(_nftContract, _tokenId, ListingType.FixedPrice, msg.sender, _price, 0);
    }

    /// @notice Buys an NFT from a fixed-price listing.
    /// @param _nftContract The address of the NFT contract.
    /// @param _tokenId The ID of the token to buy.
    function buyNFT(address _nftContract, uint256 _tokenId) external payable nonReentrant whenNotPaused {
        Listing storage listing = _listings[_nftContract][_tokenId];

        require(listing.listingType == ListingType.FixedPrice && listing.active, "NFT not listed or not fixed price");
        require(msg.sender != listing.seller, "Cannot buy your own NFT");
        require(msg.value >= listing.price, "Insufficient ETH sent");

        uint256 totalPrice = listing.price;
        uint256 marketplaceFee = totalPrice.mul(marketplaceFeeRateBps).div(10000);
        uint256 paymentToSeller = totalPrice.sub(marketplaceFee);

        address payable sellerPayable = payable(listing.seller);
        address payable feeRecipientPayable = payable(feeRecipient);

        // Calculate royalties if the NFT contract supports ERC2981
        uint256 royaltyAmount = 0;
        address royaltyRecipient = address(0);
        try IERC2981(_nftContract).royaltyInfo(_tokenId, totalPrice) returns (address recipient, uint256 amount) {
             royaltyRecipient = recipient;
             royaltyAmount = amount;
        } catch {} // Ignore if contract doesn't support ERC2981

        uint256 paymentAfterRoyalty = paymentToSeller;
        if (royaltyRecipient != address(0) && royaltyAmount > 0) {
             require(paymentAfterRoyalty >= royaltyAmount, "Payment after fee is less than royalty");
             paymentAfterRoyalty = paymentToSeller.sub(royaltyAmount);
             (bool royaltySuccess,) = payable(royaltyRecipient).call{value: royaltyAmount}("");
             // Log but don't revert if royalty transfer fails, as per common practice
             if (!royaltySuccess) {
                 // Optional: Emit an event for failed royalty payment
             }
        }


        // Send ETH to seller and fee recipient
        (bool sellerSuccess,) = sellerPayable.call{value: paymentAfterRoyalty}("");
        require(sellerSuccess, "Seller payment failed");

        // Accumulate fees in the contract, owner withdraws later
        accumulatedFees = accumulatedFees.add(marketplaceFee);

        // Transfer NFT to the buyer
        IERC721(_nftContract).safeTransferFrom(address(this), msg.sender, _tokenId);

        // Update reputation for buyer and seller
        _updateReputation(msg.sender, pointsPerPurchase);
        _updateReputation(listing.seller, pointsPerSale);

        // Mark listing as inactive
        listing.active = false;
        // Clear the listing struct fully to save gas on subsequent access checks
        delete _listings[_nftContract][_tokenId];

        emit NFTBought(_nftContract, _tokenId, msg.sender, listing.seller, totalPrice, marketplaceFee, royaltyAmount);

        // Return excess ETH to buyer
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value.sub(totalPrice));
        }
    }

     /// @notice Lists an NFT for a Dutch auction. Requires ERC721 approval beforehand.
    /// Price starts high and decays over time.
    /// @param _nftContract The address of the NFT contract.
    /// @param _tokenId The ID of the token to list.
    /// @param _startPrice The starting price in wei.
    /// @param _endPrice The ending (reserve) price in wei. Must be <= startPrice.
    /// @param _duration The duration of the auction in seconds.
    function listNFGDutchAuction(address _nftContract, uint256 _tokenId, uint256 _startPrice, uint256 _endPrice, uint64 _duration) external nonReentrant whenNotPaused {
        require(_isNFTContractApproved(_nftContract), "NFT contract not approved");
        require(_startPrice > 0, "Start price must be greater than 0");
        require(_endPrice <= _startPrice, "End price must be less than or equal to start price");
        require(_duration > 0, "Duration must be greater than 0");
        require(_listings[_nftContract][_tokenId].listingType == ListingType.None, "NFT already listed");

        IERC721 nft = IERC721(_nftContract);
        require(nft.ownerOf(_tokenId) == msg.sender, "Not owner of token");
        require(nft.isApprovedForAll(msg.sender, address(this)) || nft.getApproved(_tokenId) == address(this), "Marketplace not approved to transfer token");

         // Transfer the NFT to the marketplace contract
        nft.transferFrom(msg.sender, address(this), _tokenId);

        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + _duration;

        _listings[_nftContract][_tokenId] = Listing({
            listingType: ListingType.DutchAuction,
            seller: msg.sender,
            price: 0, // Not used for auction
            startTime: startTime,
            endTime: endTime,
            startPrice: _startPrice,
            endPrice: _endPrice,
            currentBidder: address(0), // No bid yet
            currentBid: 0,       // No bid yet
            active: true
        });

        emit ListingCreated(_nftContract, _tokenId, ListingType.DutchAuction, msg.sender, _startPrice, endTime);
    }

    /// @notice Bids on a Dutch auction. A bid at the current price wins and settles the auction.
    /// The sent ETH must be exactly the current calculated price.
    /// @param _nftContract The address of the NFT contract.
    /// @param _tokenId The ID of the token to bid on.
    function bidDutchAuction(address _nftContract, uint256 _tokenId) external payable nonReentrant whenNotPaused {
        Listing storage listing = _listings[_nftContract][_tokenId];

        require(listing.listingType == ListingType.DutchAuction && listing.active, "NFT not listed or not Dutch auction");
        require(msg.sender != listing.seller, "Cannot bid on your own auction");
        require(block.timestamp < listing.endTime, "Auction has ended");
        require(listing.currentBidder == address(0), "Auction already has a pending bid"); // Simplified: only one active bid at a time

        uint256 currentPrice = _calculateDutchAuctionPrice(
            listing.startPrice,
            listing.endPrice,
            uint64(listing.endTime - listing.startTime),
            uint64(block.timestamp - listing.startTime)
        );

        require(msg.value == currentPrice, "Sent ETH must match the current price");

        // This bid wins instantly in this simplified model
        uint256 totalPrice = msg.value;
        uint256 marketplaceFee = totalPrice.mul(marketplaceFeeRateBps).div(10000);
        uint256 paymentToSeller = totalPrice.sub(marketplaceFee);

        address payable sellerPayable = payable(listing.seller);
        address payable feeRecipientPayable = payable(feeRecipient);

        // Calculate royalties
        uint256 royaltyAmount = 0;
        address royaltyRecipient = address(0);
        try IERC2981(_nftContract).royaltyInfo(_tokenId, totalPrice) returns (address recipient, uint256 amount) {
             royaltyRecipient = recipient;
             royaltyAmount = amount;
        } catch {}

        uint256 paymentAfterRoyalty = paymentToSeller;
        if (royaltyRecipient != address(0) && royaltyAmount > 0) {
             require(paymentAfterRoyalty >= royaltyAmount, "Payment after fee is less than royalty");
             paymentAfterRoyalty = paymentToSeller.sub(royaltyAmount);
             (bool royaltySuccess,) = payable(royaltyRecipient).call{value: royaltyAmount}("");
             if (!royaltySuccess) { /* Log failure */ }
        }

        // Send ETH to seller and fee recipient
        (bool sellerSuccess,) = sellerPayable.call{value: paymentAfterRoyalty}("");
        require(sellerSuccess, "Seller payment failed");

        // Accumulate fees
        accumulatedFees = accumulatedFees.add(marketplaceFee);

        // Transfer NFT to the buyer (bidder)
        IERC721(_nftContract).safeTransferFrom(address(this), msg.sender, _tokenId);

        // Update reputation for buyer and seller
        _updateReputation(msg.sender, pointsPerPurchase);
        _updateReputation(listing.seller, pointsPerSale);

        // Mark listing as inactive
        listing.active = false;
         // Clear the listing struct
        delete _listings[_nftContract][_tokenId];


        emit DutchAuctionSettled(_nftContract, _tokenId, msg.sender, totalPrice);

        // Return excess ETH (should be 0 if msg.value == currentPrice check passes, but good practice)
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value.sub(totalPrice));
        }
    }

    /// @notice Cancels an active listing (Fixed Price or Dutch Auction) if the seller is the caller.
    /// Returns the NFT to the seller.
    /// @param _nftContract The address of the NFT contract.
    /// @param _tokenId The ID of the token to cancel the listing for.
    function cancelListing(address _nftContract, uint256 _tokenId) external nonReentrant whenNotPaused {
        Listing storage listing = _listings[_nftContract][_tokenId];

        require(listing.listingType != ListingType.None && listing.active, "NFT not listed");
        require(msg.sender == listing.seller, "Not the seller of the listing");

        // If it's a Dutch auction with a pending bid, this cancellation model is simplified
        // In a real system, handling pending bids on cancellation needs more logic (refund bid)
        require(listing.listingType == ListingType.FixedPrice || listing.currentBidder == address(0), "Cannot cancel Dutch auction with a pending bid");


        // Transfer the NFT back to the seller
        IERC721(_nftContract).safeTransferFrom(address(this), msg.sender, _tokenId);

        // Mark listing as inactive and clear struct
        listing.active = false;
        delete _listings[_nftContract][_tokenId];

        emit ListingCancelled(_nftContract, _tokenId, msg.sender);
    }

    // --- Reputation System ---

    /// @notice Internal function to update a user's reputation.
    /// @param _user The address of the user whose reputation to update.
    /// @param _points The number of points to add.
    function _updateReputation(address _user, uint256 _points) internal {
        if (_user == address(0)) return;
        _userReputation[_user] = _userReputation[_user].add(_points);
        emit ReputationUpdated(_user, _userReputation[_user]);
    }

    /// @notice Gets the current reputation points for a user.
    /// @param _user The address of the user.
    /// @return The user's reputation points.
    function getUserReputation(address _user) external view returns (uint256) {
        return _userReputation[_user];
    }

    // --- Dynamic Trait System ---

    /// @notice Calculates the dynamic trait value for an NFT based on its current owner's reputation.
    /// Assumes the NFT is currently owned by a user on the platform.
    /// The value is calculated as (Owner's Reputation / dynamicTraitDivisor).
    /// If the NFT is owned by the marketplace or not listed, or if divisor is 0 (should not happen),
    /// it might return 0 or handle based on design. Here, we return 0 if owner has 0 rep or divisor is 0.
    /// @param _nftContract The address of the NFT contract.
    /// @param _tokenId The ID of the token.
    /// @return The calculated value of the dynamic reputation-bound trait.
    function getDynamicTraitValue(address _nftContract, uint256 _tokenId) external view returns (uint256) {
        address currentOwner;
        try IERC721(_nftContract).ownerOf(_tokenId) returns (address owner) {
             currentOwner = owner;
        } catch {
             // If ownerOf fails (e.g., token doesn't exist or not ERC721 compatible), return 0
             return 0;
        }

        // We only calculate based on user reputation, not contract ownership (like marketplace)
        if (currentOwner == address(0) || currentOwner == address(this)) {
            return 0;
        }

        uint256 reputation = _userReputation[currentOwner];

        // Avoid division by zero, though setDynamicTraitConfig requires > 0
        if (dynamicTraitDivisor == 0 || reputation == 0) {
            return 0;
        }

        return reputation.div(dynamicTraitDivisor);
    }


    // --- View Functions ---

    /// @notice Gets details for a fixed-price listing.
    /// @param _nftContract The address of the NFT contract.
    /// @param _tokenId The ID of the token.
    /// @return listingType The type of listing.
    /// @return seller The seller's address.
    /// @return price The fixed price.
    /// @return active Whether the listing is active.
    function getListing(address _nftContract, uint256 _tokenId)
        external
        view
        returns (ListingType listingType, address seller, uint256 price, bool active)
    {
        Listing storage listing = _listings[_nftContract][_tokenId];
        return (listing.listingType, listing.seller, listing.price, listing.active);
    }

    /// @notice Gets details for a Dutch auction listing.
    /// @param _nftContract The address of the NFT contract.
    /// @param _tokenId The ID of the token.
    /// @return listingType The type of listing.
    /// @return seller The seller's address.
    /// @return startTime The auction start time.
    /// @return endTime The auction end time.
    /// @return startPrice The auction starting price.
    /// @return endPrice The auction ending price.
    /// @return currentBidder The current highest bidder (if any).
    /// @return currentBid The current highest bid amount (if any).
    /// @return active Whether the listing is active.
    function getDutchAuctionListing(address _nftContract, uint256 _tokenId)
        external
        view
        returns (ListingType listingType, address seller, uint256 startTime, uint256 endTime, uint256 startPrice, uint256 endPrice, address currentBidder, uint256 currentBid, bool active)
    {
        Listing storage listing = _listings[_nftContract][_tokenId];
         require(listing.listingType == ListingType.DutchAuction, "Not a Dutch auction listing");
        return (listing.listingType, listing.seller, listing.startTime, listing.endTime, listing.startPrice, listing.endPrice, listing.currentBidder, listing.currentBid, listing.active);
    }


     /// @notice Calculates the current price of a Dutch auction.
    /// Price decays linearly from startPrice to endPrice over duration.
    /// Returns endPrice if auction has ended.
    /// @param _nftContract The address of the NFT contract.
    /// @param _tokenId The ID of the token.
    /// @return The current calculated price.
    function getCurrentDutchAuctionPrice(address _nftContract, uint256 _tokenId) external view returns (uint256) {
        Listing storage listing = _listings[_nftContract][_tokenId];
        require(listing.listingType == ListingType.DutchAuction && listing.active, "NFT not listed as Dutch auction");

        uint256 currentTime = block.timestamp;
        if (currentTime >= listing.endTime) {
            return listing.endPrice;
        }

        uint64 duration = uint64(listing.endTime - listing.startTime);
        uint64 elapsedTime = uint64(currentTime - listing.startTime);

        return _calculateDutchAuctionPrice(listing.startPrice, listing.endPrice, duration, elapsedTime);
    }


    /// @notice Checks if an NFT contract is approved for listing.
    /// @param _nftContract The address of the NFT contract.
    /// @return True if the contract is approved, false otherwise.
    function _isNFTContractApproved(address _nftContract) internal view returns (bool) {
        return _approvedNFTContracts[_nftContract];
    }

    /// @notice Gets the list of approved NFT contract addresses.
    /// @return An array of approved contract addresses.
    function getApprovedNFTContracts() external view returns (address[] memory) {
        return _approvedNFTContractsList;
    }

    /// @notice Gets the current reputation point configuration.
    /// @return pointsSale Points awarded per sale.
    /// @return pointsPurchase Points awarded per purchase.
    function getReputationPointConfig() external view returns (uint256 pointsSale, uint256 pointsPurchase) {
        return (pointsPerSale, pointsPerPurchase);
    }

    /// @notice Gets the current dynamic trait configuration.
    /// @return traitName The name of the dynamic trait.
    /// @return divisor The divisor for calculating the trait value.
     function getDynamicTraitConfig() external view returns (string memory traitName, uint256 divisor) {
        return (dynamicTraitName, dynamicTraitDivisor);
    }

     /// @notice Gets the current marketplace fee rate.
     /// @return The fee rate in basis points.
     function getMarketplaceFeeRate() external view returns (uint256) {
         return marketplaceFeeRateBps;
     }

     /// @notice Gets the address where marketplace fees are sent.
     /// @return The fee recipient address.
     function getFeeRecipient() external view returns (address) {
         return feeRecipient;
     }

      /// @notice Gets the total accumulated fees waiting to be withdrawn.
      /// @return The amount of accumulated fees in wei.
      function getAccumulatedFees() external view returns (uint256) {
          return accumulatedFees;
      }


    // --- Internal Helper Functions ---

    /// @notice Calculates the current price for a Dutch auction based on time elapsed.
    /// @param _startPrice The starting price.
    /// @param _endPrice The ending price.
    /// @param _duration The total duration of the auction.
    /// @param _elapsedTime The time elapsed since the auction started.
    /// @return The calculated current price.
    function _calculateDutchAuctionPrice(uint256 _startPrice, uint256 _endPrice, uint64 _duration, uint64 _elapsedTime) internal pure returns (uint256) {
        if (_elapsedTime >= _duration) {
            return _endPrice;
        }

        // Linear decay: currentPrice = startPrice - (priceReductionPerSecond * elapsedTime)
        // priceReductionPerSecond = (startPrice - endPrice) / duration
        uint256 priceRange = _startPrice.sub(_endPrice);
        uint256 currentPrice = _startPrice.sub(priceRange.mul(_elapsedTime).div(_duration));

        return currentPrice;
    }
}
```

---

**Explanation of Advanced/Creative/Trendy Aspects:**

1.  **Dynamic NFTs via On-Chain State:** The `getDynamicTraitValue` function allows anyone to query a calculated trait value for an NFT based purely on the *current* owner's reputation stored in the marketplace contract. This means the NFT's "appearance" or perceived value (if systems read this trait) changes *dynamically* as the owner's reputation changes, without requiring a new token transfer or metadata update via IPFS (though off-chain metadata would need to reference this on-chain function). This is a form of state-dependent or dynamic NFT.
2.  **Integrated Reputation System:** A simple, on-chain reputation system is built into the marketplace logic, directly rewarding positive interactions (successful trades). This reputation isn't just a badge; it has a tangible link to the dynamic NFT trait. Future versions could use reputation for tiered fees, access to exclusive listings, or governance weight.
3.  **Linking Separate Concepts:** The contract creatively links a standard financial/market concept (marketplace) with a social/behavioral concept (reputation) and applies it to a digital asset type (NFTs) in a dynamic way.
4.  **Multiple Listing Types:** Includes both fixed-price and Dutch auction models within the same contract, offering varied market mechanics. The Dutch auction implementation shows a common price discovery method on-chain.
5.  **ERC721Holder & Explicit Transfers:** The contract takes custody of the NFT during listing (`transferFrom`), which is a common marketplace pattern, but requires careful handling of ownership and cancellation. Using `ERC721Holder` is a standard way to indicate the contract is intended to receive ERC721 tokens, though the core logic relies on `IERC721`.
6.  **ERC2981 Royalty Support:** Integrates the standard royalty mechanism, ensuring creators can potentially earn from secondary sales facilitated by this marketplace.
7.  **Controlled Ecosystem:** The `_approvedNFTContracts` mechanism allows the marketplace owner to curate which NFT collections can be listed, providing a level of quality control or theme focus.
8.  **Modular Design:** Uses standard OpenZeppelin libraries (`Ownable`, `Pausable`, `ReentrancyGuard`, `ERC721Holder`) for robust access control, security, and pause functionality.
9.  **Gas Considerations (Implied):** Using `delete` on structs after a listing is settled helps clear storage and save gas on future interactions with that specific NFT/listing slot.
10. **Explicit View Functions:** Many view functions are provided to make the contract's state and calculated values easily queryable by external applications, crucial for building a usable dApp interface.

This contract goes beyond a simple ERC721 marketplace by adding layers of dynamic behavior and user interaction tracking that influence the assets themselves.