Okay, let's design a sophisticated smart contract. We'll create a "Dynamic NFT Marketplace" where NFTs can change their state and appearance based on on-chain actions (like staking time or being used in a 'quest' initiated via the contract) or external triggers (via authorized oracles/updaters). This combines NFTs, marketplaces, and on-chain state changes.

It will include features like:
1.  **Standard NFT (ERC721):** Minting, transferring, burning.
2.  **Dynamic Metadata:** The `tokenURI` will reflect an internal state stored on-chain.
3.  **State Evolution:** Functions to change the NFT's internal state, potentially triggered by different roles or conditions.
4.  **Marketplace:** Fixed-price listings and English auctions.
5.  **Staking:** Users can stake their NFTs within the contract to earn time-based benefits or trigger state changes.
6.  **Access Control:** Owner, authorized state updaters, etc.
7.  **Fees:** Marketplace fees on sales.

Here's the outline and function summary, followed by the Solidity code.

---

**Smart Contract Outline: DynamicNFTMarketplace**

1.  **Contract Details:**
    *   SPDX License Identifier
    *   Pragma version
    *   Imports (OpenZeppelin ERC721, Ownable, ReentrancyGuard)

2.  **State Variables:**
    *   NFT Data (`struct NFTState`)
    *   Mappings for NFT State (`_nftStates`)
    *   Base Token URI (`_baseTokenURI`)
    *   Token Counter (`_tokenIdCounter`)
    *   Marketplace Listings (`struct Listing`)
    *   Mapping for Listings (`_listings`)
    *   Listing Counter (`_listingIdCounter`)
    *   Auction Details (`struct Auction`)
    *   Mapping for Auctions (`_auctions`)
    *   Auction Counter (`_auctionIdCounter`)
    *   Auction Bids (`struct Bid`)
    *   Mapping for Bids (`_bids`)
    *   Mapping to track highest bids for auctions (`_highestBids`)
    *   Staking Data (`struct Stake`)
    *   Mapping for Staked NFTs (`_stakedNFTs`)
    *   Marketplace Fees (`_marketplaceFeePercent`, `_feeRecipient`, `_protocolFees`)
    *   Authorized State Updaters (`_authorizedStateUpdaters`)
    *   Paused state (`_paused`)

3.  **Events:**
    *   `NFTMinted`
    *   `NFTStateChanged`
    *   `NFTStaked`
    *   `NFTUnstaked`
    *   `ListingCreated`
    *   `ListingCancelled`
    *   `ItemSold`
    *   `AuctionCreated`
    *   `BidPlaced`
    *   `AuctionEnded`
    *   `MarketplaceFeeUpdated`
    *   `FeeRecipientUpdated`
    *   `FeesWithdrawn`
    *   `AuthorizedStateUpdaterAdded`
    *   `AuthorizedStateUpdaterRemoved`
    *   `Paused`
    *   `Unpaused`

4.  **Modifiers:**
    *   `whenNotPaused`
    *   `whenPaused`
    *   `onlyOwnerOrApproved`
    *   `onlyAuthorizedUpdater`

5.  **Structs:**
    *   `NFTState`: Example structure for dynamic traits (e.g., level, XP, status)
    *   `Listing`: Details for fixed-price listings
    *   `Auction`: Details for auction listings
    *   `Bid`: Details for a bid on an auction
    *   `Stake`: Details for staked NFTs

6.  **Functions (Total: 30+ functions planned):**

    *   **NFT Management (ERC721 + Dynamic):**
        *   `constructor`: Initialize contract, set base URI.
        *   `mint`: Create a new NFT with initial state (Admin/Minter role).
        *   `burn`: Destroy an NFT (Owner role, with checks).
        *   `tokenURI`: Get the dynamic metadata URI based on base URI and on-chain state.
        *   `setBaseURI`: Set the base part of the token URI (Owner only).
        *   `getNFTState`: View the current on-chain state of an NFT.
        *   `_updateNFTState`: Internal helper to change state and emit event.

    *   **Dynamic State Evolution:**
        *   `evolveNFTState`: Trigger state change for an NFT by an authorized updater (e.g., game logic, oracle).
        *   `ownerTriggerNFTStateEvolution`: Allow NFT owner to trigger state change (maybe costs ETH or requires condition).
        *   `addAuthorizedStateUpdater`: Grant permission to an address to call `evolveNFTState` (Owner only).
        *   `removeAuthorizedStateUpdater`: Revoke permission (Owner only).
        *   `grantNFTStateUpdatePermission`: Allow a specific address to call `evolveNFTState` for a *single, specific* token (NFT Owner only).
        *   `revokeNFTStateUpdatePermission`: Revoke permission for a specific address on a specific token (NFT Owner only).

    *   **Marketplace (Fixed Price):**
        *   `listNFTFixedPrice`: List an NFT for sale at a fixed price. Requires NFT approval.
        *   `cancelListing`: Cancel an active fixed-price listing (Seller only).
        *   `buyNFTFixedPrice`: Purchase an NFT from a fixed-price listing. Handles fee distribution.
        *   `getListingDetails`: View details of a specific listing.

    *   **Marketplace (Auction):**
        *   `listNFTAuction`: List an NFT for sale via auction. Requires NFT approval. Defines start/end times and min bid.
        *   `cancelAuction`: Cancel an auction before it starts or has valid bids (Seller only).
        *   `placeBid`: Place a bid on an active auction. Handles bid refunds for previous highest bidder.
        *   `endAuction`: Conclude an auction after its end time. Transfers token to highest bidder, distributes funds. Can be called by anyone.
        *   `getAuctionDetails`: View details of a specific auction.
        *   `getHighestBid`: View the current highest bid for an auction.

    *   **NFT Staking:**
        *   `stakeNFT`: Lock an NFT in the contract for staking. Requires NFT approval.
        *   `unstakeNFT`: Retrieve a staked NFT. Can potentially trigger state changes based on stake duration.
        *   `getNFTStakeTime`: View how long an NFT has been staked.
        *   `isNFTStaked`: Check if an NFT is currently staked.

    *   **Admin & Fees:**
        *   `setMarketplaceFeePercent`: Set the marketplace fee percentage (Owner only).
        *   `setFeeRecipient`: Set the address receiving marketplace fees (Owner only).
        *   `withdrawMarketplaceFees`: Withdraw accumulated protocol fees (Fee Recipient only).
        *   `pause`: Pause core contract functionality (listing, buying, bidding, staking, unstaking - Owner only).
        *   `unpause`: Unpause the contract (Owner only).

    *   **Inherited/Standard ERC721 Functions (already counted implicitly but good to list):**
        *   `transferFrom`
        *   `safeTransferFrom`
        *   `approve`
        *   `setApprovalForAll`
        *   `getApproved`
        *   `isApprovedForAll`
        *   `balanceOf`
        *   `ownerOf`
        *   `supportsInterface`

*(Note: While many standard ERC721 functions are included via inheritance, the custom dynamic state, marketplace, staking, and state evolution functions provide the core innovation and easily exceed the 20-function requirement with distinct logic.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/// @title DynamicNFTMarketplace
/// @dev A marketplace for ERC721 NFTs that can have their state dynamically updated
///      based on on-chain actions (like staking) or external triggers (via authorized updaters).
///      Supports fixed-price listings, English auctions, and NFT staking.

contract DynamicNFTMarketplace is ERC721, Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;
    using Address for address payable;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _listingIdCounter;
    Counters.Counter private _auctionIdCounter;

    string private _baseTokenURI;

    // Represents the dynamic state/traits of an NFT
    struct NFTState {
        uint256 level;
        uint256 experiencePoints;
        bytes32 status; // e.g., 'Idle', 'Staked', 'Questing'
        // Add more dynamic attributes as needed
    }
    mapping(uint256 => NFTState) private _nftStates;

    // Represents a fixed-price listing
    struct Listing {
        uint256 tokenId;
        address payable seller;
        uint256 price;
        bool active;
    }
    mapping(uint256 => Listing) private _listings;

    // Represents an auction listing
    struct Auction {
        uint256 tokenId;
        address payable seller;
        uint256 minBid;
        uint256 startTime;
        uint256 endTime;
        bool ended;
    }
    mapping(uint256 => Auction) private _auctions;

    // Represents a bid on an auction
    struct Bid {
        uint256 auctionId;
        address payable bidder;
        uint256 amount;
    }
    mapping(uint256 => Bid) private _bids; // mapping from bid ID to bid details
    mapping(uint256 => uint256) private _highestBids; // mapping from auction ID to highest bid ID

    // Represents staking data for an NFT
    struct Stake {
        uint256 tokenId;
        address owner; // Who staked it
        uint48 stakeStartTime; // Use uint48 for time (seconds)
        bool isStaked;
    }
    mapping(uint256 => Stake) private _stakedNFTs; // Mapping from token ID to staking details

    // Marketplace Fee Configuration
    uint256 public marketplaceFeePercent; // Basis points (e.g., 100 = 1%)
    address payable public feeRecipient;
    uint256 public protocolFees; // Accumulated fees ready for withdrawal

    // Role-based access for triggering state changes
    mapping(address => bool) private _authorizedStateUpdaters;
    // Permission for specific addresses to update state of specific tokens
    mapping(uint256 => mapping(address => bool)) private _specificTokenStateUpdatePermissions;


    // --- Events ---

    event NFTMinted(uint256 indexed tokenId, address indexed owner, NFTState initialState);
    event NFTStateChanged(uint256 indexed tokenId, NFTState newState, address indexed triggeredBy);
    event NFTStaked(uint256 indexed tokenId, address indexed owner, uint48 stakeStartTime);
    event NFTUnstaked(uint256 indexed tokenId, address indexed owner, uint48 stakeDuration);
    event ListingCreated(uint256 indexed listingId, uint256 indexed tokenId, uint256 price);
    event ListingCancelled(uint256 indexed listingId);
    event ItemSold(uint256 indexed listingId, uint256 indexed tokenId, address indexed buyer, uint256 price);
    event AuctionCreated(uint256 indexed auctionId, uint256 indexed tokenId, uint256 minBid, uint256 startTime, uint256 endTime);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event AuctionEnded(uint256 indexed auctionId, uint256 indexed tokenId, address indexed winner, uint256 winningBid);
    event MarketplaceFeeUpdated(uint256 newFeePercent);
    event FeeRecipientUpdated(address indexed newRecipient);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event AuthorizedStateUpdaterAdded(address indexed updater);
    event AuthorizedStateUpdaterRemoved(address indexed updater);
    event Paused(address account);
    event Unpaused(address account);


    // --- Modifiers ---

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    modifier onlyOwnerOrApproved(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner nor approved");
        _;
    }

    modifier onlyAuthorizedUpdater() {
        require(_authorizedStateUpdaters[msg.sender], "Not an authorized updater");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, string memory baseURI)
        ERC721(name, symbol)
        Ownable(msg.sender)
        ReentrancyGuard() // Added ReentrancyGuard
    {
        _baseTokenURI = baseURI;
        marketplaceFeePercent = 200; // 2% default fee
        feeRecipient = payable(msg.sender);
        _paused = false; // Start unpaused
    }

    // --- NFT Management (ERC721 + Dynamic) ---

    /// @dev Mints a new NFT with initial state. Callable only by the contract owner.
    /// @param recipient The address to mint the token to.
    /// @param initialState The initial dynamic state for the new NFT.
    function mint(address recipient, NFTState memory initialState) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(recipient, newTokenId);
        _nftStates[newTokenId] = initialState;
        emit NFTMinted(newTokenId, recipient, initialState);
    }

    /// @dev Burns an NFT, removing it from existence and deleting its state.
    /// @param tokenId The ID of the token to burn.
    function burn(uint256 tokenId) public onlyOwnerOrApproved(tokenId) {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        // Ensure the token is not currently staked or listed/in auction
        require(!_stakedNFTs[tokenId].isStaked, "NFT is staked");
        require(!_isNFTListed(tokenId), "NFT is listed");
        require(!_isNFTInAuction(tokenId), "NFT is in auction");

        // Before burning, clean up associated data if any (though market/stake requires not being active)
        delete _nftStates[tokenId];
        _burn(tokenId);
        // Token counter is not decremented as it's only for minting new IDs
    }

    /// @dev Returns the Base URI for the NFT metadata. Combined with state data off-chain to form full URI.
    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    /// @dev See {IERC721Metadata-tokenURI}. This marketplace assumes an off-chain service
    ///      will read the on-chain state (`getNFTState`) and combine it with the `baseTokenURI`
    ///      to return the full, dynamic metadata URI. This function provides the base URI
    ///      and the token ID, leaving the state part for the off-chain service.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Note: The actual dynamic part based on _nftStates[tokenId] is expected to be handled
        // by the metadata server that serves this URI. The contract only stores the state.
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
    }

    /// @dev Allows the contract owner to update the base URI for the token metadata.
    /// @param newBaseURI The new base URI.
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    /// @dev Gets the current dynamic state of an NFT.
    /// @param tokenId The ID of the token.
    /// @return The NFTState struct.
    function getNFTState(uint256 tokenId) public view returns (NFTState memory) {
        require(_exists(tokenId), "NFT does not exist");
        return _nftStates[tokenId];
    }

    /// @dev Internal helper function to update the state of an NFT and emit an event.
    /// @param tokenId The ID of the token.
    /// @param newState The new state for the token.
    /// @param triggeredBy The address that triggered the state change.
    function _updateNFTState(uint256 tokenId, NFTState memory newState, address triggeredBy) internal {
        _nftStates[tokenId] = newState;
        emit NFTStateChanged(tokenId, newState, triggeredBy);
    }


    // --- Dynamic State Evolution ---

    /// @dev Allows an authorized state updater to evolve the state of an NFT.
    ///      This is intended for use by game logic, oracles, or other trusted systems.
    /// @param tokenId The ID of the token to evolve.
    /// @param newState The new state for the token.
    function evolveNFTState(uint256 tokenId, NFTState memory newState) public onlyAuthorizedUpdater {
        require(_exists(tokenId), "NFT does not exist");
        _updateNFTState(tokenId, newState, msg.sender);
    }

    /// @dev Allows the owner of an NFT (or an address with specific permission) to trigger
    ///      a state evolution for their token. Could potentially require payment or check conditions.
    /// @param tokenId The ID of the token.
    /// @param newState The new state for the token.
    function ownerTriggerNFTStateEvolution(uint256 tokenId, NFTState memory newState) public {
        require(_exists(tokenId), "NFT does not exist");
        require(ownerOf(tokenId) == msg.sender || _specificTokenStateUpdatePermissions[tokenId][msg.sender],
                "Not authorized to update this token's state");

        // Optional: Add require statements here for cost (e.g., require(msg.value >= evolutionCost))
        // Optional: Add require statements here for conditions (e.g., require(_nftStates[tokenId].level > 5))

        // Refund excess ETH if applicable
        // if (msg.value > evolutionCost) payable(msg.sender).transfer(msg.value - evolutionCost);

        _updateNFTState(tokenId, newState, msg.sender);
    }

    /// @dev Grants permission to an address to call `evolveNFTState`. Callable only by the contract owner.
    /// @param updater The address to authorize.
    function addAuthorizedStateUpdater(address updater) public onlyOwner {
        require(updater != address(0), "Invalid address");
        require(!_authorizedStateUpdaters[updater], "Updater already authorized");
        _authorizedStateUpdaters[updater] = true;
        emit AuthorizedStateUpdaterAdded(updater);
    }

    /// @dev Removes permission from an address to call `evolveNFTState`. Callable only by the contract owner.
    /// @param updater The address to deauthorize.
    function removeAuthorizedStateUpdater(address updater) public onlyOwner {
        require(updater != address(0), "Invalid address");
        require(_authorizedStateUpdaters[updater], "Updater not authorized");
        _authorizedStateUpdaters[updater] = false;
        emit AuthorizedStateUpdaterRemoved(updater);
    }

     /// @dev Allows the NFT owner to grant a specific address permission to trigger state updates
     ///      for this *specific* token using `ownerTriggerNFTStateEvolution`.
     /// @param tokenId The ID of the token.
     /// @param authorizedAddress The address to grant permission to.
     function grantNFTStateUpdatePermission(uint256 tokenId, address authorizedAddress) public {
         require(_exists(tokenId), "NFT does not exist");
         require(ownerOf(tokenId) == msg.sender, "Not the owner of the token");
         require(authorizedAddress != address(0), "Invalid address");
         _specificTokenStateUpdatePermissions[tokenId][authorizedAddress] = true;
     }

     /// @dev Allows the NFT owner to revoke a specific address's permission to trigger state updates
     ///      for this *specific* token.
     /// @param tokenId The ID of the token.
     /// @param authorizedAddress The address to revoke permission from.
     function revokeNFTStateUpdatePermission(uint256 tokenId, address authorizedAddress) public {
         require(_exists(tokenId), "NFT does not exist");
         require(ownerOf(tokenId) == msg.sender, "Not the owner of the token");
         require(authorizedAddress != address(0), "Invalid address");
         _specificTokenStateUpdatePermissions[tokenId][authorizedAddress] = false;
     }


    // --- Marketplace (Fixed Price) ---

    /// @dev Creates a fixed-price listing for an NFT. Requires the NFT to be approved
    ///      to the marketplace contract or transferred to the contract first (approval pattern used here).
    /// @param tokenId The ID of the token to list.
    /// @param price The fixed price in wei.
    /// @return The ID of the created listing.
    function listNFTFixedPrice(uint256 tokenId, uint256 price) public nonReentrant whenNotPaused {
        require(_exists(tokenId), "NFT does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not the owner of the token");
        require(price > 0, "Price must be greater than zero");
        require(getApproved(tokenId) == address(this) || isApprovedForAll(msg.sender, address(this)),
                "NFT must be approved to marketplace");

        // Ensure token isn't already listed or in auction
        require(!_isNFTListed(tokenId), "NFT already listed");
        require(!_isNFTInAuction(tokenId), "NFT already in auction");
        require(!_stakedNFTs[tokenId].isStaked, "NFT is staked"); // Cannot list staked NFT

        _listingIdCounter.increment();
        uint256 newListingId = _listingIdCounter.current();

        _listings[newListingId] = Listing(
            tokenId,
            payable(msg.sender),
            price,
            true
        );

        emit ListingCreated(newListingId, tokenId, price);
        // Token remains with the owner; contract is approved to transfer on sale.
        return newListingId;
    }

    /// @dev Cancels an active fixed-price listing. Callable only by the seller.
    /// @param listingId The ID of the listing to cancel.
    function cancelListing(uint256 listingId) public nonReentrant whenNotPaused {
        Listing storage listing = _listings[listingId];
        require(listing.active, "Listing not active");
        require(listing.seller == msg.sender, "Not the seller");

        listing.active = false; // Deactivate the listing
        emit ListingCancelled(listingId);
        // Token remains with owner, no transfer needed.
    }

    /// @dev Purchases an NFT from a fixed-price listing.
    /// @param listingId The ID of the listing to purchase from.
    function buyNFTFixedPrice(uint256 listingId) public payable nonReentrant whenNotPaused {
        Listing storage listing = _listings[listingId];
        require(listing.active, "Listing not active");
        require(msg.value >= listing.price, "Insufficient funds");

        uint256 tokenId = listing.tokenId;
        address payable seller = listing.seller;
        uint256 price = listing.price;

        // Ensure the listing is still valid (NFT owner hasn't transferred it away)
        require(ownerOf(tokenId) == seller, "NFT owner changed");

        listing.active = false; // Deactivate listing

        // Calculate and distribute fees
        uint256 feeAmount = (price * marketplaceFeePercent) / 10000;
        uint256 sellerProceeds = price - feeAmount;

        protocolFees += feeAmount; // Accumulate protocol fees
        seller.transfer(sellerProceeds); // Transfer proceeds to seller

        // Transfer the NFT to the buyer
        _safeTransferFrom(seller, msg.sender, tokenId);

        // Refund excess payment if any
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }

        emit ItemSold(listingId, tokenId, msg.sender, price);
    }

    /// @dev Gets the details of a fixed-price listing.
    /// @param listingId The ID of the listing.
    /// @return The Listing struct.
    function getListingDetails(uint256 listingId) public view returns (Listing memory) {
        return _listings[listingId];
    }

     /// @dev Helper function to check if an NFT is currently listed via fixed price.
     function _isNFTListed(uint256 tokenId) internal view returns (bool) {
         uint256 currentListingId = _listingIdCounter.current();
         for(uint256 i = 1; i <= currentListingId; i++) {
             Listing storage listing = _listings[i];
             if(listing.active && listing.tokenId == tokenId) {
                 return true;
             }
         }
         return false;
     }


    // --- Marketplace (Auction) ---

    /// @dev Creates an English auction listing for an NFT. Requires NFT approval.
    /// @param tokenId The ID of the token to auction.
    /// @param minBid The minimum starting bid.
    /// @param duration The duration of the auction in seconds (minimum 1 minute).
    /// @return The ID of the created auction.
    function listNFTAuction(uint256 tokenId, uint256 minBid, uint256 duration) public nonReentrant whenNotPaused {
        require(_exists(tokenId), "NFT does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not the owner of the token");
        require(minBid >= 0, "Min bid cannot be negative"); // Allow 0 for free auctions? Or enforce > 0
        require(duration >= 60, "Auction duration must be at least 1 minute"); // Minimum duration
        require(getApproved(tokenId) == address(this) || isApprovedForAll(msg.sender, address(this)),
                "NFT must be approved to marketplace");

        // Ensure token isn't already listed or in auction
        require(!_isNFTListed(tokenId), "NFT already listed");
        require(!_isNFTInAuction(tokenId), "NFT already in auction");
        require(!_stakedNFTs[tokenId].isStaked, "NFT is staked"); // Cannot list staked NFT

        _auctionIdCounter.increment();
        uint256 newAuctionId = _auctionIdCounter.current();
        uint256 currentTime = block.timestamp;

        _auctions[newAuctionId] = Auction(
            tokenId,
            payable(msg.sender),
            minBid,
            currentTime,
            currentTime + duration,
            false
        );

        emit AuctionCreated(newAuctionId, tokenId, minBid, currentTime, currentTime + duration);
         // Token remains with the owner; contract is approved to transfer on sale.
        return newAuctionId;
    }

    /// @dev Cancels an auction. Only callable by the seller, and only if no bids have been placed yet.
    /// @param auctionId The ID of the auction to cancel.
    function cancelAuction(uint256 auctionId) public nonReentrant whenNotPaused {
        Auction storage auction = _auctions[auctionId];
        require(!auction.ended, "Auction already ended");
        require(auction.seller == msg.sender, "Not the seller");
        require(_highestBids[auctionId] == 0, "Cannot cancel auction with bids"); // Require no bids

        auction.ended = true; // Mark as ended
        emit AuctionEnded(auctionId, auction.tokenId, address(0), 0); // Indicate cancellation
        // Token remains with owner.
    }


    /// @dev Places a bid on an active auction. Requires sending ETH equal to the bid amount.
    ///      Refunds previous highest bidder.
    /// @param auctionId The ID of the auction to bid on.
    function placeBid(uint256 auctionId) public payable nonReentrant whenNotPaused {
        Auction storage auction = _auctions[auctionId];
        require(!auction.ended, "Auction already ended");
        require(block.timestamp >= auction.startTime, "Auction has not started");
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(msg.sender != auction.seller, "Seller cannot bid on their own auction");

        uint256 currentHighestBidId = _highestBids[auctionId];
        uint256 currentHighestAmount = (currentHighestBidId == 0) ? auction.minBid : _bids[currentHighestBidId].amount;

        require(msg.value > currentHighestAmount, "Bid must be higher than current highest bid");

        // Refund previous highest bidder if exists
        if (currentHighestBidId != 0) {
            address payable previousBidder = _bids[currentHighestBidId].bidder;
            uint256 previousBidAmount = _bids[currentHighestBidId].amount;
            // It's safer to transfer here than accumulate internal balances, but requires reentrancy guard
            previousBidder.transfer(previousBidAmount);
        }

        // Record the new highest bid
        uint256 newBidId = uint256(_bids.length) + 1; // Simple unique ID logic, might need improvement for production
        _bids[newBidId] = Bid(auctionId, payable(msg.sender), msg.value);
        _highestBids[auctionId] = newBidId;

        emit BidPlaced(auctionId, msg.sender, msg.value);
    }

    /// @dev Ends an auction after its end time has passed. Transfers the NFT to the winner
    ///      and sends the winning bid amount to the seller (minus fees). Can be called by anyone.
    /// @param auctionId The ID of the auction to end.
    function endAuction(uint256 auctionId) public nonReentrant whenNotPaused {
        Auction storage auction = _auctions[auctionId];
        require(!auction.ended, "Auction already ended");
        require(block.timestamp >= auction.endTime, "Auction has not ended yet");

        auction.ended = true; // Mark auction as ended

        uint256 highestBidId = _highestBids[auctionId];

        if (highestBidId == 0) {
            // No bids or highest bid is initial min bid (if minBid was > 0) - return NFT to seller
             require(ownerOf(auction.tokenId) == auction.seller, "NFT owner changed unexpectedly before auction end");
            emit AuctionEnded(auctionId, auction.tokenId, address(0), 0); // Indicate no winner
        } else {
            Bid storage winningBid = _bids[highestBidId];
            uint256 winningAmount = winningBid.amount;
            address payable winner = winningBid.bidder;
            address payable seller = auction.seller;
            uint256 tokenId = auction.tokenId;

            // Ensure the NFT is still owned by the seller
             require(ownerOf(tokenId) == seller, "NFT owner changed unexpectedly before auction end");

            // Calculate and distribute fees
            uint256 feeAmount = (winningAmount * marketplaceFeePercent) / 10000;
            uint256 sellerProceeds = winningAmount - feeAmount;

            protocolFees += feeAmount; // Accumulate protocol fees

            // Transfer the NFT to the winner
            _safeTransferFrom(seller, winner, tokenId);

            // Send proceeds to the seller
            seller.transfer(sellerProceeds);

            emit AuctionEnded(auctionId, tokenId, winner, winningAmount);
        }
    }

    /// @dev Gets the details of an auction.
    /// @param auctionId The ID of the auction.
    /// @return The Auction struct.
    function getAuctionDetails(uint256 auctionId) public view returns (Auction memory) {
        return _auctions[auctionId];
    }

    /// @dev Gets the details of the current highest bid for an auction.
    /// @param auctionId The ID of the auction.
    /// @return The Bid struct (bidder, amount, auctionId). Returns zero values if no bids.
    function getHighestBid(uint256 auctionId) public view returns (Bid memory) {
        uint256 highestBidId = _highestBids[auctionId];
        if (highestBidId == 0) {
            // Return an empty bid struct if no bids placed
            return Bid(0, payable(address(0)), 0);
        }
        return _bids[highestBidId];
    }

    /// @dev Helper function to check if an NFT is currently in an auction.
    function _isNFTInAuction(uint256 tokenId) internal view returns (bool) {
        uint256 currentAuctionId = _auctionIdCounter.current();
        for(uint256 i = 1; i <= currentAuctionId; i++) {
            Auction storage auction = _auctions[i];
            if(!auction.ended && auction.tokenId == tokenId) {
                return true;
            }
        }
        return false;
    }


    // --- NFT Staking ---

    /// @dev Stakes an NFT by transferring it to the contract.
    ///      NFT state can potentially change based on staking duration.
    /// @param tokenId The ID of the token to stake.
    function stakeNFT(uint256 tokenId) public nonReentrant whenNotPaused {
        require(_exists(tokenId), "NFT does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not the owner of the token");
        require(!_stakedNFTs[tokenId].isStaked, "NFT already staked");

        // Ensure token isn't listed or in auction
        require(!_isNFTListed(tokenId), "NFT is listed");
        require(!_isNFTInAuction(tokenId), "NFT is in auction");

        // Transfer the NFT to the contract
        safeTransferFrom(msg.sender, address(this), tokenId);

        _stakedNFTs[tokenId] = Stake(
            tokenId,
            msg.sender,
            uint48(block.timestamp),
            true
        );

        // Example state change on staking: Set status to 'Staked'
        NFTState storage currentState = _nftStates[tokenId];
        currentState.status = "Staked";
        _updateNFTState(tokenId, currentState, address(this)); // Triggered by contract itself

        emit NFTStaked(tokenId, msg.sender, _stakedNFTs[tokenId].stakeStartTime);
    }

    /// @dev Unstakes an NFT, transferring it back to the original staker.
    ///      Can trigger state changes based on stake duration.
    /// @param tokenId The ID of the token to unstake.
    function unstakeNFT(uint256 tokenId) public nonReentrant whenNotPaused {
        require(_exists(tokenId), "NFT does not exist");
        require(_stakedNFTs[tokenId].isStaked, "NFT is not staked");
        require(_stakedNFTs[tokenId].owner == msg.sender, "Not the staker of this NFT");
        require(ownerOf(tokenId) == address(this), "NFT not owned by marketplace"); // Sanity check

        Stake storage stake = _stakedNFTs[tokenId];
        uint48 stakeDuration = uint48(block.timestamp) - stake.stakeStartTime;

        // Transfer the NFT back to the original staker
        _safeTransferFrom(address(this), msg.sender, tokenId);

        // Clear staking data
        stake.isStaked = false;
        stake.stakeStartTime = 0; // Reset time
        // delete _stakedNFTs[tokenId]; // Or simply mark as not staked

        // Example state change on unstaking: Calculate XP or change status based on duration
        NFTState storage currentState = _nftStates[tokenId];
        currentState.status = "Idle"; // Example: Reset status
        // Example: Add XP based on duration (1 XP per 100 seconds staked)
        // currentState.experiencePoints += stakeDuration / 100; // Requires careful casting/scaling
        _updateNFTState(tokenId, currentState, address(this)); // Triggered by contract

        emit NFTUnstaked(tokenId, msg.sender, stakeDuration);
    }

    /// @dev Checks if an NFT is currently staked in the contract.
    /// @param tokenId The ID of the token.
    /// @return True if staked, false otherwise.
    function isNFTStaked(uint256 tokenId) public view returns (bool) {
        return _stakedNFTs[tokenId].isStaked;
    }

    /// @dev Gets the time duration (in seconds) an NFT has been staked so far.
    ///      Returns 0 if not staked.
    /// @param tokenId The ID of the token.
    /// @return The duration staked in seconds (or 0 if not staked).
    function getNFTStakeTime(uint256 tokenId) public view returns (uint256) {
        if (_stakedNFTs[tokenId].isStaked) {
            return block.timestamp - _stakedNFTs[tokenId].stakeStartTime;
        }
        return 0;
    }

    /// @dev Gets the start time of the stake for an NFT.
    ///      Returns 0 if not staked.
    /// @param tokenId The ID of the token.
    /// @return The stake start timestamp (or 0 if not staked).
     function getNFTStakeStartTime(uint256 tokenId) public view returns (uint48) {
         return _stakedNFTs[tokenId].stakeStartTime;
     }


    // --- Admin & Fees ---

    /// @dev Sets the marketplace fee percentage. Callable only by the contract owner.
    /// @param newFeePercent The new fee percentage in basis points (e.g., 100 = 1%). Max 10000 (100%).
    function setMarketplaceFeePercent(uint256 newFeePercent) public onlyOwner {
        require(newFeePercent <= 10000, "Fee percent cannot exceed 100%");
        marketplaceFeePercent = newFeePercent;
        emit MarketplaceFeeUpdated(newFeePercent);
    }

    /// @dev Sets the address that receives accumulated marketplace fees. Callable only by the contract owner.
    /// @param newRecipient The new fee recipient address.
    function setFeeRecipient(address payable newRecipient) public onlyOwner {
        require(newRecipient != address(0), "Invalid address");
        feeRecipient = newRecipient;
        emit FeeRecipientUpdated(newRecipient);
    }

    /// @dev Allows the fee recipient to withdraw accumulated protocol fees.
    function withdrawMarketplaceFees() public nonReentrant {
        require(msg.sender == feeRecipient, "Not the fee recipient");
        uint256 amount = protocolFees;
        require(amount > 0, "No fees to withdraw");

        protocolFees = 0; // Reset fees BEFORE transfer
        feeRecipient.transfer(amount); // Transfer fees

        emit FeesWithdrawn(feeRecipient, amount);
    }

    /// @dev Pauses the contract, disabling core marketplace and staking actions.
    /// @inheritdoc Pausable
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /// @dev Unpauses the contract, enabling core marketplace and staking actions.
    /// @inheritdoc Pausable
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /// @dev See {Pausable-_beforeTokenTransfer}. Ensures transfers are not paused.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Additional check: Prevent transferring out if listed/in auction
         if (from != address(0) && from != address(this) && to != address(0) && to != address(this)) {
            require(!_isNFTListed(tokenId), "Cannot transfer listed NFT");
            require(!_isNFTInAuction(tokenId), "Cannot transfer NFT in auction");
            require(!_stakedNFTs[tokenId].isStaked, "Cannot transfer staked NFT manually");
         }
    }

    // --- Standard ERC721 Overrides ---

    // These functions are inherited and work out of the box with our _safeMint and _burn overrides:
    // transferFrom, safeTransferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll, balanceOf, ownerOf, supportsInterface

    // Override _update to potentially handle pre/post transfer logic related to state
    // For now, _beforeTokenTransfer is sufficient.

    // Override _safeMint
    function _safeMint(address to, uint256 tokenId) internal override {
        super._safeMint(to, tokenId);
    }

    // Override _burn
    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);
    }

     // Override supportsInterface to include ERC2981 Royalty Standard if needed (not implemented here)
     // function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC165) returns (bool) {
     //     return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
     // }
}
```

---

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic NFT State (`NFTState`, `_nftStates`, `tokenURI`, `evolveNFTState`, `ownerTriggerNFTStateEvolution`):** This is the core creative concept. The NFT's characteristics (`level`, `experiencePoints`, `status`) are stored *on-chain*. The `tokenURI` function is overridden to point to a base URI, *implying* that an off-chain metadata server will read this on-chain state via `getNFTState` and generate the appropriate JSON metadata and image URL dynamically. This allows the NFT's appearance and traits to evolve without creating new token IDs.
2.  **Role-Based State Evolution (`onlyAuthorizedUpdater`, `addAuthorizedStateUpdater`, `removeAuthorizedStateUpdater`):** Introduces a permissioned system where specific addresses (like game contracts, oracles, or administrators) can be authorized to trigger state changes for *any* NFT. This is crucial for integrating with external logic.
3.  **NFT Owner-Controlled State Evolution (`ownerTriggerNFTStateEvolution`, `grantNFTStateUpdatePermission`, `revokeNFTStateUpdatePermission`):** Allows the NFT holder to initiate state changes, potentially consuming resources (ETH, other tokens - though not fully implemented in the example, the structure is there) or meeting specific conditions. The ability to grant/revoke permission for others on a per-token basis adds granularity.
4.  **Integrated Staking (`stakeNFT`, `unstakeNFT`, `_stakedNFTs`, `getNFTStakeTime`):** Users can lock their NFTs in the contract. This isn't just passive locking; the `unstakeNFT` function includes logic hooks (`// Example state change on unstaking`) where you can implement mechanics that change the NFT's state based on how long it was staked. The dynamic state enables visible effects of staking.
5.  **Multiple Marketplace Mechanisms (Fixed Price & Auction):** Combining distinct marketplace models within a single contract adds complexity and utility compared to a simple "buy now" contract.
6.  **Reentrancy Protection (`ReentrancyGuard`, `nonReentrant`):** Essential security pattern, especially when handling external transfers like auction bid refunds or fee distribution.
7.  **Pausable Functionality (`Pausable`, `pause`, `unpause`, `whenNotPaused`, `whenPaused`):** Standard but crucial for being able to halt sensitive operations in case of bugs or upgrades (though upgrades require proxy patterns not included here).
8.  **Fee Distribution:** Implementing a protocol fee with a configurable percentage and recipient.
9.  **Internal State Checks (`_isNFTListed`, `_isNFTInAuction`, `isNFTStaked`):** Helper functions to prevent conflicting actions (e.g., cannot list a staked NFT, cannot transfer a listed NFT manually).
10. **Gas Optimization Considerations (Implicit):** Using `uint48` for timestamps and thinking about loop bounds (`_isNFTListed`, `_isNFTInAuction`) are small touches towards optimization, although the loops could become expensive with many listings/auctions. Production systems might use more advanced indexing.

This contract goes beyond basic NFT creation or a simple fixed-price shop by introducing state evolution, external triggers, owner-controlled changes, and an integrated staking mechanism alongside multiple marketplace types. The requirement for an off-chain service to serve the dynamic metadata based on the on-chain state is a common and practical pattern for dynamic NFTs.