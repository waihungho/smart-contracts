Okay, here is a smart contract concept for a "Generative Art Marketplace with Dynamic Traits and Licensing". This combines several concepts:
1.  **Generative Art:** Tokens represent art pieces created based on initial parameters.
2.  **Dynamic Traits:** A portion of the art's traits can change over time or based on external factors (simulated here using blockchain data like block number).
3.  **Marketplace:** Users can list, buy, and bid on these unique art NFTs.
4.  **Advanced Royalties:** Custom royalty percentages and recipients per token.
5.  **Licensing:** Owners can grant non-transferable licenses for specific uses of their art.
6.  **Approved Minters:** Control over who can create new art pieces.

This is more complex than a basic ERC721 and incorporates multiple sub-protocols and custom logic.

**Outline and Function Summary**

```
Contract Name: GenerativeArtMarketplace

Concept:
An NFT marketplace focused on generative art pieces where the art's traits can be dynamic based on blockchain state. It includes features for custom royalties, licensing, and controlled minting.

Key Features:
- ERC721 compliant NFT ownership.
- Storage of initial "Generative Parameters" used for art creation.
- "Dynamic Traits" that can be updated based on block data (simulated external influence).
- A marketplace for fixed-price listings and auctions (bids).
- Per-token custom royalty settings (implements ERC2981).
- Non-transferable licensing of specific art pieces.
- Approved minter list to control new art creation.
- Admin functions for fees, pausing, and minter management.

Outline:
1.  State Variables, Structs, Events, Error Definitions
2.  Modifiers
3.  Constructor & Initial Setup
4.  Admin/Ownership Functions
5.  Approved Minter Management
6.  NFT (ERC721) Core Functions
7.  Generative Parameters & Dynamic Traits
8.  Minting (Creating New Art)
9.  Marketplace Functions (Listing, Buying, Bidding)
10. Royalty Functions (ERC2981 Implementation & Custom Settings)
11. Licensing Functions
12. Utility/View Functions

Function Summary:

Admin/Ownership:
- `setFeeRecipient(address _feeRecipient)`: Sets the address to receive marketplace fees.
- `setMarketplaceFee(uint96 _marketplaceFeeBps)`: Sets the marketplace fee percentage (in basis points).
- `withdrawFees()`: Allows the fee recipient to withdraw accumulated fees.
- `pause()`: Pauses core contract functions (marketplace, minting).
- `unpause()`: Unpauses the contract.

Approved Minter Management:
- `setApprovedMinters(address[] calldata _minters)`: Adds addresses to the approved minter list.
- `removeApprovedMinters(address[] calldata _minters)`: Removes addresses from the approved minter list.
- `isApprovedMinter(address _addr)`: Checks if an address is an approved minter.
- `getApprovedMinters()`: Returns the list of approved minters.

NFT (ERC721) Core:
- `balanceOf(address owner)`: Returns the number of tokens owned by an address.
- `ownerOf(uint256 tokenId)`: Returns the owner of a specific token.
- `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers token ownership safely.
- `safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)`: Transfers token ownership safely with data.
- `approve(address to, uint256 tokenId)`: Approves an address to spend a token.
- `getApproved(uint256 tokenId)`: Returns the approved address for a token.
- `setApprovalForAll(address operator, bool approved)`: Approves/disapproves an operator for all tokens.
- `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all tokens.
- `tokenURI(uint256 tokenId)`: Returns the metadata URI for a token.

Generative Parameters & Dynamic Traits:
- `getGenerativeParameters(uint256 tokenId)`: Returns the original generative parameters for a token.
- `syncDynamicTraits(uint256 tokenId)`: Updates the dynamic traits for a token based on current blockchain data (callable by anyone after cooldown).
- `getDynamicTrait(uint256 tokenId)`: Returns the current dynamic trait value for a token.

Minting:
- `mintArtPiece(address to, string calldata _metadataURI, GenerativeParameters calldata _params)`: Creates a new generative art NFT.

Marketplace:
- `listItemForSale(uint256 tokenId, uint256 price)`: Lists an owned token for sale at a fixed price.
- `cancelListing(uint256 tokenId)`: Cancels an active listing.
- `buyItem(uint256 tokenId)`: Buys a listed token.
- `placeBid(uint256 tokenId)`: Places a bid on a token that is *not* currently listed for fixed price.
- `acceptBid(uint256 tokenId, address bidder)`: Accepts a specific bid for a token.
- `cancelBid(uint256 tokenId)`: Cancels the user's own bid on a token.
- `getListing(uint256 tokenId)`: Returns information about a token's listing.
- `getBid(uint256 tokenId, address bidder)`: Returns information about a specific bid on a token.

Royalty (ERC2981 & Custom):
- `setDefaultRoyalty(uint96 _royaltyBasisPoints)`: Sets the default royalty for future tokens (Admin only).
- `setTokenRoyaltyRecipient(uint256 tokenId, address _recipient)`: Sets a custom royalty recipient for a token (Owner only).
- `setTokenRoyaltyPercentage(uint256 tokenId, uint96 _percentageBasisPoints)`: Sets a custom royalty percentage for a token (Owner only).
- `royaltyInfo(uint256 tokenId, uint256 salePrice)`: Returns royalty payment information for a sale (ERC2981 standard).

Licensing:
- `grantLicense(uint256 tokenId, address licensee, uint256 duration, string calldata purpose)`: Grants a non-transferable license for a token to an address (Owner only).
- `revokeLicense(uint256 tokenId, address licensee)`: Revokes an active license (Owner only).
- `getLicenseInfo(uint256 tokenId, address licensee)`: Returns information about a specific license.

Utility/View:
- `supportsInterface(bytes4 interfaceId)`: Checks if the contract supports a given interface (ERC165).
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Useful for getApprovedMinters (or implement manually)
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Using OpenZeppelin for battle-tested components like ERC721, Ownable, Pausable, ReentrancyGuard, ERC2981, EnumerableSet.
// The custom logic for generative params, dynamic traits, marketplace, and licensing is unique.

contract GenerativeArtMarketplace is ERC721, ERC721Enumerable, Ownable, Pausable, ReentrancyGuard, ERC2981 {
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- State Variables ---
    uint256 private _nextTokenId;
    uint96 public marketplaceFeeBasisPoints; // Fee for marketplace sales, in basis points (e.g., 250 = 2.5%)
    address public feeRecipient;
    uint256 public constant DYNAMIC_TRAIT_SYNC_COOLDOWN = 1 days; // Cooldown period for dynamic trait sync

    // --- Structs ---

    // Represents the initial parameters used for generative art creation
    struct GenerativeParameters {
        uint256 creationSeed; // A base seed
        uint8 colorPaletteId; // Index of a predefined color palette
        uint8 shapePatternId; // Index of a predefined shape pattern
        // Add more parameters relevant to the generative algorithm off-chain
        string extraParams; // Placeholder for complex JSON/string parameters
    }

    // Represents dynamic traits that can change
    struct DynamicTraits {
        uint256 syncTimestamp; // Last time traits were synced
        uint256 dynamicSeed;   // Seed influenced by blockchain data
        uint8 moodFactor;      // A trait derived from dynamicSeed (e.g., 0-255)
        // Add more dynamic traits
    }

    // Represents a fixed-price listing on the marketplace
    struct Listing {
        address seller;
        uint256 price;
        bool isActive;
    }

    // Represents a bid in an auction-like system (can exist even without a formal "auction state")
    struct Bid {
        address bidder;
        uint256 amount;
        uint256 timestamp;
    }

    // Represents a non-transferable license for a token
    struct License {
        address licensee;
        uint256 expirationTimestamp;
        string purpose; // e.g., "Commercial Use", "Print", "Digital Display"
        bool isActive;
    }

    // --- Mappings ---
    mapping(uint256 => GenerativeParameters) private _generativeParameters;
    mapping(uint256 => DynamicTraits) private _dynamicTraits;
    mapping(uint256 => Listing) private _listings;
    mapping(uint256 => mapping(address => Bid)) private _bids; // tokenId => bidder => bid
    mapping(uint256 => mapping(address => License)) private _licenses; // tokenId => licensee => license

    // Approved minters
    EnumerableSet.AddressSet private _approvedMinters;

    // Custom per-token royalties (overrides default)
    mapping(uint256 => address) private _tokenRoyaltyRecipient;
    mapping(uint256 => uint96) private _tokenRoyaltyPercentageBasisPoints;

    // accumulated fees waiting to be withdrawn
    uint256 private _accruedFees;

    // --- Events ---
    event ArtPieceMinted(uint256 indexed tokenId, address indexed owner, string metadataURI, GenerativeParameters params);
    event DynamicTraitsSynced(uint256 indexed tokenId, DynamicTraits traits);
    event ItemListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event ListingCancelled(uint256 indexed tokenId, address indexed seller);
    event ItemSold(uint256 indexed tokenId, address indexed buyer, uint256 indexed seller, uint256 price);
    event BidPlaced(uint256 indexed tokenId, address indexed bidder, uint256 amount);
    event BidAccepted(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 amount);
    event BidCancelled(uint256 indexed tokenId, address indexed bidder);
    event LicenseGranted(uint256 indexed tokenId, address indexed licensee, uint256 expirationTimestamp, string purpose);
    event LicenseRevoked(uint256 indexed tokenId, address indexed licensee);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event ApprovedMinterAdded(address indexed minter);
    event ApprovedMinterRemoved(address indexed minter);
    event RoyaltyRecipientSet(uint256 indexed tokenId, address recipient);
    event RoyaltyPercentageSet(uint256 indexed tokenId, uint96 percentageBasisPoints);
    event DefaultRoyaltySet(uint96 percentageBasisPoints);
    event MetadataURISet(uint256 indexed tokenId, string metadataURI);

    // --- Errors ---
    error OnlyApprovedMinter();
    error ListingNotFound();
    error NotListingSeller();
    error ListingStillActive();
    error NotListingPrice();
    error AlreadyListed();
    error BidNotFound();
    error NotBidder();
    error BidTooLow();
    error BidOnListedItem();
    error InvalidBidAmount();
    error LicenseNotFound();
    error NotLicenseOwner();
    error LicenseStillActive();
    error TraitSyncCooldownActive();
    error NoFeesAccrued();
    error CannotTransferSelf();


    // --- Modifiers ---
    modifier onlyApprovedMinter() {
        if (!_approvedMinters.contains(_msgSender())) revert OnlyApprovedMinter();
        _;
    }

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        address tokenOwner = ownerOf(tokenId);
        if (_msgSender() != tokenOwner && !_approvedMinters.contains(_msgSender())) {
            revert("Caller is not owner or approved minter");
        }
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, address initialFeeRecipient, uint96 initialMarketplaceFeeBps)
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable()
        ERC2981()
    {
        feeRecipient = initialFeeRecipient;
        marketplaceFeeBasisPoints = initialMarketplaceFeeBps;
        _setDefaultRoyalty(initialMarketplaceFeeBps); // Also set a contract-wide default for ERC2981
    }

    // --- Admin/Ownership Functions ---

    /// @notice Sets the address that receives marketplace fees.
    /// @param _feeRecipient The new fee recipient address.
    function setFeeRecipient(address _feeRecipient) public onlyOwner {
        feeRecipient = _feeRecipient;
    }

    /// @notice Sets the percentage fee for marketplace sales.
    /// @param _marketplaceFeeBps The new fee percentage in basis points (0-10000).
    function setMarketplaceFee(uint96 _marketplaceFeeBps) public onlyOwner {
        require(_marketplaceFeeBps <= 10000, "Fee cannot exceed 100%");
        marketplaceFeeBasisPoints = _marketplaceFeeBps;
    }

    /// @notice Allows the fee recipient to withdraw accumulated fees.
    function withdrawFees() public nonReentrant {
        if (_msgSender() != feeRecipient) revert OwnableUnauthorizedAccount(feeRecipient);
        if (_accruedFees == 0) revert NoFeesAccrued();

        uint256 amount = _accruedFees;
        _accruedFees = 0;

        // Use low-level call for safety against re-entrancy (pattern)
        (bool success, ) = payable(feeRecipient).call{value: amount}("");
        require(success, "Fee withdrawal failed");

        emit FeesWithdrawn(feeRecipient, amount);
    }

    /// @notice Pauses core contract functionality (minting, marketplace interactions).
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses core contract functionality.
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    // --- Approved Minter Management ---

    /// @notice Adds addresses to the list of approved minters.
    /// @param _minters Array of addresses to add.
    function setApprovedMinters(address[] calldata _minters) public onlyOwner {
        for (uint i = 0; i < _minters.length; i++) {
            if (_approvedMinters.add(_minters[i])) {
                emit ApprovedMinterAdded(_minters[i]);
            }
        }
    }

    /// @notice Removes addresses from the list of approved minters.
    /// @param _minters Array of addresses to remove.
    function removeApprovedMinters(address[] calldata _minters) public onlyOwner {
        for (uint i = 0; i < _minters.length; i++) {
            if (_approvedMinters.remove(_minters[i])) {
                emit ApprovedMinterRemoved(_minters[i]);
            }
        }
    }

    /// @notice Checks if an address is currently an approved minter.
    /// @param _addr The address to check.
    /// @return True if the address is an approved minter, false otherwise.
    function isApprovedMinter(address _addr) public view returns (bool) {
        return _approvedMinters.contains(_addr);
    }

    /// @notice Gets the list of all approved minters.
    /// @dev This could be gas intensive for a large number of minters. Consider pagination off-chain.
    /// @return An array of approved minter addresses.
    function getApprovedMinters() public view returns (address[] memory) {
        return _approvedMinters.values();
    }

    // --- NFT (ERC721) Core Functions ---

    // Using OpenZeppelin's implementations. Overridden for Pausable checks.
    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) nonReentrant whenNotPaused {
        if (_listings[tokenId].isActive && _listings[tokenId].seller == from) {
             // Automatically cancel listing on transfer by seller
            _cancelListingInternal(tokenId);
        }
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721, IERC721) nonReentrant whenNotPaused {
         if (_listings[tokenId].isActive && _listings[tokenId].seller == from) {
             // Automatically cancel listing on transfer by seller
            _cancelListingInternal(tokenId);
        }
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function approve(address to, uint256 tokenId) public override(ERC721, IERC721) whenNotPaused {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) whenNotPaused {
        super.setApprovalForAll(operator, approved);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, IERC721Metadata) returns (string memory) {
        // This is a standard ERC721 function.
        // In a real Dapp, the off-chain service serving this URI would need
        // to fetch _generativeParameters and _dynamicTraits from the chain
        // to dynamically generate the metadata JSON reflecting the current state.
        return super.tokenURI(tokenId);
    }

    // --- Generative Parameters & Dynamic Traits ---

    /// @notice Gets the original generative parameters for a token.
    /// @param tokenId The ID of the token.
    /// @return The GenerativeParameters struct.
    function getGenerativeParameters(uint256 tokenId) public view returns (GenerativeParameters memory) {
        _requireOwnedOrApproved(ownerOf(tokenId), tokenId); // Only owner or approved can see params? Or public? Let's make it public.
        return _generativeParameters[tokenId];
    }

    /// @notice Updates the dynamic traits for a token based on current blockchain data.
    /// @dev Simulates external influence using block number and timestamp. Can only be called after a cooldown.
    /// @param tokenId The ID of the token.
    function syncDynamicTraits(uint256 tokenId) public nonReentrant whenNotPaused {
        _requireMinted(tokenId);
        DynamicTraits storage currentTraits = _dynamicTraits[tokenId];

        // Enforce cooldown
        if (block.timestamp < currentTraits.syncTimestamp + DYNAMIC_TRAIT_SYNC_COOLDOWN) {
            revert TraitSyncCooldownActive();
        }

        // Simulate dynamic trait update using blockchain data
        // WARNING: block.timestamp and blockhash can be manipulated by miners to a degree.
        // For truly random or external data dependent traits, use Chainlink VRF or oracles.
        uint256 dynamicSeed = uint256(keccak256(abi.encodePacked(
            _generativeParameters[tokenId].creationSeed, // Combine with original seed
            block.number,
            block.timestamp,
            tx.origin // Add tx origin for variability (caution: may have centralization implications)
        )));

        // Derive a simple trait from the dynamic seed
        uint8 moodFactor = uint8(dynamicSeed % 256); // Example derivation

        currentTraits.syncTimestamp = block.timestamp;
        currentTraits.dynamicSeed = dynamicSeed;
        currentTraits.moodFactor = moodFactor;
        // Update other dynamic traits here

        emit DynamicTraitsSynced(tokenId, currentTraits);

        // Optional: Trigger metadata update notification if the URI serving allows dynamic content based on chain state
        // event MetadataUpdate(uint256 _tokenId); // If using ERC4906
    }

    /// @notice Gets the current dynamic trait value for a token.
    /// @param tokenId The ID of the token.
    /// @return The DynamicTraits struct.
    function getDynamicTrait(uint256 tokenId) public view returns (DynamicTraits memory) {
        _requireMinted(tokenId);
        return _dynamicTraits[tokenId];
    }

    // --- Minting (Creating New Art) ---

    /// @notice Creates a new generative art NFT.
    /// @param to The recipient of the new token.
    /// @param _metadataURI The metadata URI for the token.
    /// @param _params The initial generative parameters for the art piece.
    function mintArtPiece(address to, string calldata _metadataURI, GenerativeParameters calldata _params)
        public
        onlyApprovedMinter
        whenNotPaused
        nonReentrant
    {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _metadataURI);

        // Store generative parameters
        _generativeParameters[tokenId] = _params;

        // Initialize dynamic traits (optional, could be lazy initialized on first sync)
        _dynamicTraits[tokenId] = DynamicTraits({
            syncTimestamp: block.timestamp, // Initialize sync time
            dynamicSeed: uint256(0),        // Zero or derived from initial seed
            moodFactor: uint8(0)            // Zero or derived from initial seed
        });

        // Set default royalty for this token based on contract default
        _setTokenRoyaltyRecipient(tokenId, owner()); // Set default recipient as contract owner initially
        _setTokenRoyaltyPercentageBasisPoints[tokenId] = defaultRoyaltyBasisPoints;


        emit ArtPieceMinted(tokenId, to, _metadataURI, _params);
    }

    // Internal function to check if a token exists
    function _requireMinted(uint256 tokenId) internal view {
        require(_exists(tokenId), "Token does not exist");
    }

    // --- Marketplace Functions ---

    /// @notice Lists an owned token for sale at a fixed price.
    /// @param tokenId The ID of the token to list.
    /// @param price The price in Ether. Must be greater than 0.
    function listItemForSale(uint256 tokenId, uint256 price) public nonReentrant whenNotPaused {
        address tokenOwner = ownerOf(tokenId); // Automatically checks if token exists
        require(tokenOwner == _msgSender(), "Caller is not token owner");
        if (_listings[tokenId].isActive) revert AlreadyListed();
        require(price > 0, "Price must be greater than 0");

        _listings[tokenId] = Listing({
            seller: tokenOwner,
            price: price,
            isActive: true
        });

        // Cancel any active bids when listing
        // Note: This simplifies bid management; a more complex system might handle bids differently.
        // We just clear existing bids when a fixed-price listing is made.
        // A full auction system would require more complex state management.
        // This implementation supports fixed price OR bids (one at a time per token).
        // _clearBids(tokenId); // Need to iterate and clear bids, skipped for simplicity but noted.

        emit ItemListed(tokenId, tokenOwner, price);
    }

    /// @notice Cancels an active listing for an owned token.
    /// @param tokenId The ID of the token.
    function cancelListing(uint256 tokenId) public nonReentrant whenNotPaused {
        Listing storage listing = _listings[tokenId];
        if (!listing.isActive) revert ListingNotFound();
        if (listing.seller != _msgSender()) revert NotListingSeller();

        _cancelListingInternal(tokenId);
    }

     function _cancelListingInternal(uint256 tokenId) internal {
        Listing storage listing = _listings[tokenId];
        listing.isActive = false; // Deactivate
        // No need to zero out other fields unless gas optimization is critical,
        // but deactivating is sufficient to prevent buying.

        emit ListingCancelled(tokenId, listing.seller);
    }


    /// @notice Buys a listed token at the fixed price.
    /// @param tokenId The ID of the token to buy.
    function buyItem(uint256 tokenId) public payable nonReentrant whenNotPaused {
        Listing storage listing = _listings[tokenId];
        if (!listing.isActive) revert ListingNotFound();
        if (msg.value < listing.price) revert NotListingPrice();
        if (_msgSender() == listing.seller) revert CannotTransferSelf();

        address seller = listing.seller;
        uint256 price = listing.price;
        uint256 feeAmount = (price * marketplaceFeeBasisPoints) / 10000;
        uint256 sellerProceeds = price - feeAmount;

        // Cancel listing before state changes and transfers
        _cancelListingInternal(tokenId);

        // Transfer ownership of the NFT
        _transfer(seller, _msgSender(), tokenId);

        // Accrue fees
        _accruedFees += feeAmount;

        // Pay seller
        (bool success, ) = payable(seller).call{value: sellerProceeds}("");
        require(success, "Payment to seller failed"); // Consider more robust handling on failure

        // Refund excess Ether if any
        if (msg.value > price) {
            (success, ) = payable(_msgSender()).call{value: msg.value - price}("");
            require(success, "Refund failed"); // Consider more robust handling on failure
        }

        emit ItemSold(tokenId, _msgSender(), seller, price);

        // Pay royalties (ERC2981) - This function is called *after* the sale
        // off-chain indexers/clients would see the ItemSold event and call royaltyInfo
        // to determine royalties. Direct on-chain royalty payment adds complexity (need
        // to split payment again, ensure recipient is payable).
        // For simplicity and gas efficiency, ERC2981 is typically calculated and
        // paid off-chain by the marketplace frontend upon seeing the sale event.
        // If *on-chain* royalty distribution is required, modify the payment logic.
        // For THIS example, we stick to ERC2981 which is an *information* standard.
    }

    /// @notice Places or updates a bid on a token. Only allowed if the token is NOT listed for fixed price.
    /// @param tokenId The ID of the token.
    function placeBid(uint256 tokenId) public payable nonReentrant whenNotPaused {
        _requireMinted(tokenId);
        if (_listings[tokenId].isActive) revert BidOnListedItem();
        address tokenOwner = ownerOf(tokenId);
        if (_msgSender() == tokenOwner) revert("Owner cannot bid on their own token");
        if (msg.value == 0) revert InvalidBidAmount();

        Bid storage existingBid = _bids[tokenId][_msgSender()];

        // Refund previous bid if exists
        if (existingBid.amount > 0) {
            (bool success, ) = payable(_msgSender()).call{value: existingBid.amount}("");
            require(success, "Previous bid refund failed"); // Crucial safety check
        }

        // Update bid
        existingBid.bidder = _msgSender();
        existingBid.amount = msg.value;
        existingBid.timestamp = block.timestamp;

        emit BidPlaced(tokenId, _msgSender(), msg.value);
    }

    /// @notice Accepts a specific bid for an owned token.
    /// @param tokenId The ID of the token.
    /// @param bidder The address of the bidder whose bid is being accepted.
    function acceptBid(uint256 tokenId, address bidder) public nonReentrant whenNotPaused {
        address tokenOwner = ownerOf(tokenId); // Automatically checks if token exists
        require(tokenOwner == _msgSender(), "Caller is not token owner");
         if (_listings[tokenId].isActive) revert AlreadyListed(); // Cannot accept bid if listed for fixed price

        Bid storage bid = _bids[tokenId][bidder];
        if (bid.amount == 0) revert BidNotFound();
        if (bidder == tokenOwner) revert("Cannot accept bid from self"); // Should be caught by placeBid, but double check

        uint256 acceptedPrice = bid.amount;
        uint256 feeAmount = (acceptedPrice * marketplaceFeeBasisPoints) / 10000;
        uint256 sellerProceeds = acceptedPrice - feeAmount;

        // Clear the accepted bid immediately
        delete _bids[tokenId][bidder];

        // Transfer ownership of the NFT
        _transfer(tokenOwner, bidder, tokenId);

        // Accrue fees
        _accruedFees += feeAmount;

        // Pay seller
        (bool success, ) = payable(tokenOwner).call{value: sellerProceeds}("");
        require(success, "Payment to seller failed"); // Consider more robust handling on failure

        // In a more complex system, you might need to manage other active bids (e.g., refund).
        // Here, we just delete the accepted one. Other bids remain until cancelled or a new bid is placed.

        emit BidAccepted(tokenId, tokenOwner, bidder, acceptedPrice);

         // Pay royalties (ERC2981) - See comments in buyItem
    }

    /// @notice Cancels a user's own bid on a token.
    /// @param tokenId The ID of the token.
    function cancelBid(uint256 tokenId) public nonReentrant whenNotPaused {
        Bid storage bid = _bids[tokenId][_msgSender()];
        if (bid.amount == 0) revert BidNotFound();
        if (bid.bidder != _msgSender()) revert NotBidder(); // Redundant check as key is msg.sender, but good practice

        uint256 refundAmount = bid.amount;
        delete _bids[tokenId][_msgSender()];

        (bool success, ) = payable(_msgSender()).call{value: refundAmount}("");
        require(success, "Bid refund failed");

        emit BidCancelled(tokenId, _msgSender());
    }

    /// @notice Gets information about a token's fixed-price listing.
    /// @param tokenId The ID of the token.
    /// @return The Listing struct.
    function getListing(uint256 tokenId) public view returns (Listing memory) {
        _requireMinted(tokenId); // Ensure token exists before returning potentially empty struct
        return _listings[tokenId];
    }

    /// @notice Gets information about a specific bid on a token.
    /// @param tokenId The ID of the token.
    /// @param bidder The address of the bidder.
    /// @return The Bid struct.
    function getBid(uint256 tokenId, address bidder) public view returns (Bid memory) {
         _requireMinted(tokenId); // Ensure token exists
        return _bids[tokenId][bidder];
    }

    // --- Royalty Functions (ERC2981 Implementation & Custom Settings) ---

    // ERC2981 standard function
    /// @notice Returns royalty payment information for a sale according to ERC2981.
    /// @param tokenId The ID of the token sold.
    /// @param salePrice The price the token was sold for.
    /// @return receiver The address to pay royalties to.
    /// @return royaltyAmount The amount of royalty to pay.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        override(ERC2981, IERC2981)
        returns (address receiver, uint256 royaltyAmount)
    {
        _requireMinted(tokenId); // Ensure token exists
        address tokenOwner = ownerOf(tokenId); // Get current owner for potential recipient fallback

        address recipient = _tokenRoyaltyRecipient[tokenId] == address(0) ? tokenOwner : _tokenRoyaltyRecipient[tokenId];
        uint96 percentage = _tokenRoyaltyPercentageBasisPoints[tokenId] == 0 ? defaultRoyaltyBasisPoints : _tokenRoyaltyPercentageBasisPoints[tokenId];

        uint256 amount = (salePrice * percentage) / 10000;

        return (recipient, amount);
    }

    // Custom functions to set token-specific royalties

    /// @notice Sets the default royalty recipient for a specific token. Only callable by the token owner.
    /// @param tokenId The ID of the token.
    /// @param _recipient The address to receive royalties for this token. Address(0) means current owner.
    function setTokenRoyaltyRecipient(uint256 tokenId, address _recipient) public nonReentrant whenNotPaused {
        require(ownerOf(tokenId) == _msgSender(), "Caller is not token owner"); // Checks token existence
        _tokenRoyaltyRecipient[tokenId] = _recipient;
        emit RoyaltyRecipientSet(tokenId, _recipient);
    }

    /// @notice Sets the custom royalty percentage for a specific token. Only callable by the token owner.
    /// @param tokenId The ID of the token.
    /// @param _percentageBasisPoints The royalty percentage in basis points (0-10000).
    function setTokenRoyaltyPercentage(uint256 tokenId, uint96 _percentageBasisPoints) public nonReentrant whenNotPaused {
        require(ownerOf(tokenId) == _msgSender(), "Caller is not token owner"); // Checks token existence
        require(_percentageBasisPoints <= 10000, "Royalty percentage cannot exceed 100%");
        _tokenRoyaltyPercentageBasisPoints[tokenId] = _percentageBasisPoints;
        emit RoyaltyPercentageSet(tokenId, _percentageBasisPoints);
    }

    /// @notice Sets the contract-wide default royalty percentage for future tokens. Only callable by owner.
    /// @param _royaltyBasisPoints The default royalty percentage in basis points (0-10000).
    function setDefaultRoyalty(uint96 _royaltyBasisPoints) public onlyOwner {
        require(_royaltyBasisPoints <= 10000, "Default royalty percentage cannot exceed 100%");
         _setDefaultRoyalty(owner(), _royaltyBasisPoints); // Use ERC2981 internal function
        emit DefaultRoyaltySet(_royaltyBasisPoints);
    }


    // --- Licensing Functions ---

    /// @notice Grants a non-transferable license for a token to an address. Only callable by the token owner.
    /// @dev Licenses are stored per tokenId and licensee. Granting a new license to the same licensee overwrites the old one.
    /// @param tokenId The ID of the token.
    /// @param licensee The address receiving the license.
    /// @param duration The duration of the license in seconds (0 for indefinite).
    /// @param purpose The specific purpose of the license (e.g., "Commercial Print", "Website Display").
    function grantLicense(uint256 tokenId, address licensee, uint256 duration, string calldata purpose) public nonReentrant whenNotPaused {
        require(ownerOf(tokenId) == _msgSender(), "Caller is not token owner"); // Checks token existence
        require(licensee != address(0), "Licensee cannot be zero address");

        uint256 expirationTimestamp = (duration == 0) ? type(uint256).max : block.timestamp + duration;

        _licenses[tokenId][licensee] = License({
            licensee: licensee,
            expirationTimestamp: expirationTimestamp,
            purpose: purpose,
            isActive: true
        });

        emit LicenseGranted(tokenId, licensee, expirationTimestamp, purpose);
    }

    /// @notice Revokes an active license for a token granted to a specific address. Only callable by the token owner.
    /// @param tokenId The ID of the token.
    /// @param licensee The address whose license is being revoked.
    function revokeLicense(uint256 tokenId, address licensee) public nonReentrant whenNotPaused {
        require(ownerOf(tokenId) == _msgSender(), "Caller is not token owner"); // Checks token existence
        License storage license = _licenses[tokenId][licensee];

        if (!license.isActive) revert LicenseNotFound();
        // No need to check licensee != address(0) because isActive implies existence

        license.isActive = false; // Deactivate

        emit LicenseRevoked(tokenId, licensee);
    }

    /// @notice Gets information about a specific license for a token.
    /// @param tokenId The ID of the token.
    /// @param licensee The address of the potential licensee.
    /// @return The License struct. Note: will return default struct if no active license exists.
    function getLicenseInfo(uint256 tokenId, address licensee) public view returns (License memory) {
        _requireMinted(tokenId); // Ensure token exists
        License storage license = _licenses[tokenId][licensee];

        // Return active license or default if not active/found or expired
        if (!license.isActive || (license.expirationTimestamp != type(uint256).max && block.timestamp > license.expirationTimestamp)) {
            return License(address(0), 0, "", false);
        }

        return license;
    }

    // --- Utility/View Functions ---

    /// @notice Returns the total supply of tokens.
    function totalSupply() public view override(ERC721, ERC721Enumerable) returns (uint256) {
        return super.totalSupply();
    }

    /// @notice Returns the token ID at a specific index.
    function tokenByIndex(uint256 index) public view override(ERC721Enumerable) returns (uint256) {
        return super.tokenByIndex(index);
    }

    /// @notice Returns the token ID at a specific index for an owner.
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override(ERC721Enumerable) returns (uint256) {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    /// @notice See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        // Supports ERC721, ERC165, ERC721Enumerable, ERC2981
        return super.supportsInterface(interfaceId);
    }

    // --- Internal Overrides ---

    // Required ERC721Enumerable overrides
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
         // Additional checks before transfer if needed, e.g., disallow transfer if licensed?
         // This would require iterating through licenses, potentially gas intensive.
         // Current design allows transfer, meaning license is tied to licensee, not owner.
         // A license granted by the previous owner *might* still be valid depending on the Dapp's interpretation.
         // For this contract, licenses are explicitly tied to the *token ID* and *licensee address*,
         // and are granted/revoked by the *current owner*. Transfer doesn't automatically invalidate existing licenses.
         // The `getLicenseInfo` function includes an `isActive` check managed by `revokeLicense`.

        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

     function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Enumerable) {
        // Clear listings and potentially bids after transfer
        // This is already handled in safeTransferFrom for the seller transferring.
        // If transfer happens by other means (e.g., internal _transfer from owner),
        // the listing would still need to be cancelled. We handle this in buyItem and acceptBid.
        // If owner calls _transfer directly without using market function, the listing remains until manually cancelled or next market interaction.
        // It's safer to ensure cancellation happens *before* the transfer in all relevant paths or add a hook here.
        // Adding check here for completeness, although buy/accept already do it.
        if (_listings[tokenId].isActive && _listings[tokenId].seller == from) {
             _cancelListingInternal(tokenId);
        }
         // Also clear any active bids on the token by anyone when ownership changes
         // (As previous owner is no longer the one who can accept bids)
         // This requires iterating bids or tracking bidders, adding complexity.
         // For simplicity, bids placed on a token by the *buyer* in `placeBid` are cleared
         // upon acceptance/purchase. Other bids remain but cannot be accepted by the new owner.
         // A cleaner approach might clear *all* bids on transfer. Skipping for this example.

        super._afterTokenTransfer(from, to, tokenId, batchSize);
     }

    // Required ERC721 overrides
     function _increaseBalance(address account, uint256 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
     }

    // Required ERC721 overrides
    function _decreaseBalance(address account, uint256 value) internal override(ERC721, ERC721Enumerable) {
         super._decreaseBalance(account, value);
    }
}
```