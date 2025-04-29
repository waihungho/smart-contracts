Okay, here is a Solidity smart contract for a complex "Crypto Art Gallery" that combines several advanced concepts like community curation, multiple listing types (fixed price, auction), internal fractionalization management, and social interaction features, while avoiding direct copies of standard ERC patterns (though it *interacts* with ERC721).

This contract is designed to be interesting, advanced, and creative, focusing on gallery-specific logic rather than just being another NFT minting contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title CryptoArtGallery
/// @dev A complex smart contract for a curated digital art gallery featuring various sale mechanics,
/// fractional ownership management, community curation, and social interactions.
contract CryptoArtGallery is ReentrancyGuard {
    using Address for address payable;

    // --- Outline ---
    // 1. State Variables & Events
    // 2. Roles & Access Control (Owner, Artist, Curator)
    // 3. User/Role Management
    // 4. Art Submission & Curation
    // 5. Art Listings (Fixed Price & Auction)
    // 6. Sales & Auction Mechanics
    // 7. Fractional Ownership Management
    // 8. Social & Interaction Features
    // 9. Withdrawals & Fees
    // 10. Pause Functionality
    // 11. View Functions

    // --- Function Summary ---
    // --- Admin & Core Settings ---
    // 1. setGalleryFee(uint256 _feePercentage): Set the gallery commission fee.
    // 2. addCurator(address _curator): Add an address to the curator role (Owner only).
    // 3. removeCurator(address _curator): Remove an address from the curator role (Owner only).
    // 4. withdrawGalleryFees(): Withdraw accumulated gallery fees (Owner only).
    // 5. pause(): Pause core contract functions (Owner only).
    // 6. unpause(): Unpause the contract (Owner only).

    // --- User & Role Management ---
    // 7. registerArtist(string memory _name, string memory _bio): Register as an artist.
    // 8. applyAsCurator(string memory _applicationText): Submit an application to be a curator. (Owner reviews off-chain/via events)
    // 9. updateArtistProfile(string memory _name, string memory _bio): Update artist profile info.

    // --- Art Submission & Curation ---
    // 10. submitArtForCuration(address _nftContract, uint256 _tokenId): Artist submits an NFT for gallery approval.
    // 11. curatorApproveArt(uint256 _artId): Curator approves a submitted art piece.
    // 12. curatorRejectArt(uint256 _artId, string memory _reason): Curator rejects a submitted art piece.

    // --- Art Listings & Sales ---
    // 13. listArtForFixedPrice(uint256 _artId, uint256 _price, uint256 _duration): List approved art for sale at a fixed price.
    // 14. listArtForAuction(uint256 _artId, uint256 _minBid, uint256 _duration): List approved art for auction (English auction).
    // 15. cancelListing(uint256 _listingId): Cancel an active listing/auction (Seller only).
    // 16. buyArtFixedPrice(uint256 _listingId): Purchase art listed at a fixed price.
    // 17. placeAuctionBid(uint256 _listingId): Place a bid on an art auction.
    // 18. endAuction(uint256 _listingId): End an auction and finalize the sale/refund bids.

    // --- Fractional Ownership ---
    // 19. proposeFractionalization(uint256 _artId, uint256 _totalShares, uint256 _pricePerShare): Propose fractionalizing an approved art piece held by the gallery.
    // 20. buyArtFraction(uint256 _artId, uint256 _shares): Buy shares of a fractionalized art piece.
    // 21. redeemArtFraction(uint256 _artId): Redeem the original NFT by owning and burning all shares.

    // --- Social & Interactions ---
    // 22. likeArt(uint256 _artId): Like a specific art piece.
    // 23. tipArtist(address payable _artist, uint256 _artId): Tip an artist directly.

    // --- Withdrawals ---
    // 24. withdrawArtistProceeds(): Artist withdraws accumulated sales proceeds.
    // 25. withdrawBidRefund(uint256 _listingId): Bidder withdraws their refund after being outbid or auction cancellation.

    // --- View Functions ---
    // 26. getArtDetails(uint256 _artId): Get details of a specific art piece.
    // 27. getArtListingDetails(uint256 _listingId): Get details of a specific listing/auction.
    // 28. getArtFractionDetails(uint256 _artId): Get fractionalization details for an art piece.
    // 29. getArtistProfile(address _artist): Get artist profile details.
    // 30. isCurator(address _user): Check if an address is a curator.
    // 31. getGalleryFeePercentage(): Get the current gallery fee percentage.
    // 32. getUserLikedArt(address _user): Get the list of art IDs a user has liked.


    // --- State Variables ---

    address private immutable i_owner;
    uint256 public galleryFeePercentage; // e.g., 500 for 5% (stored as basis points)
    uint256 private constant FEE_DENOMINATOR = 10000; // Basis points

    uint256 public approvalsNeededForCuration = 3; // Number of curators required to approve art

    uint256 public nextArtId = 1;
    uint256 public nextListingId = 1;

    struct ArtItem {
        address nftContract;
        uint256 tokenId;
        address artist;
        uint256 submittedTimestamp;
        bool isApproved; // Approved by curators
        bool isListed; // Currently listed for sale/auction
        bool isFractionalized; // Held by gallery and fractionalized
        uint256 approvalCount; // Current number of curator approvals
        mapping(address => bool) curatorApproved; // Track which curators approved
        string rejectionReason; // Reason if rejected
    }

    struct ArtListing {
        uint256 artId;
        address payable seller; // Artist or current owner listing
        uint256 price; // Used for fixed price or min bid for auction
        uint256 startTime;
        uint256 endTime;
        bool isAuction;
        bool active; // Whether the listing is currently active

        // Auction specific
        address payable highestBidder;
        uint256 highestBid;
        mapping(address => uint256) bids; // Track bids for refunds
    }

    struct ArtistProfile {
        string name;
        string bio;
        bool isRegistered;
    }

    // For Fractionalization: Internal management of shares
    struct FractionalArtInfo {
        uint256 totalShares; // Total shares minted
        uint256 pricePerShare; // Price to buy a share
        address currentHolder; // Address holding the original NFT (should be this contract if fractionalized)
    }

    mapping(uint256 => ArtItem) public artItems;
    mapping(uint256 => ArtListing) public artListings;
    mapping(address => ArtistProfile) public artistProfiles;
    mapping(address => bool) public curators;
    mapping(address => uint256) public artistProceeds; // Funds owed to artists
    mapping(address => uint256) public galleryFunds; // Funds owed to the gallery

    // Social features
    mapping(address => mapping(uint256 => bool)) public userLikesArt;
    mapping(uint256 => uint256) public artLikeCount;

    // Fractionalization state
    mapping(uint256 => FractionalArtInfo) public fractionalArtInfo;
    mapping(uint256 => mapping(address => uint256)) public artFractions; // artId => user => shares

    // List of liked art per user (to implement getUserLikedArt view)
    mapping(address => uint256[]) private userLikedArtIds;


    // --- Events ---

    event GalleryFeeSet(uint256 indexed newFeePercentage);
    event CuratorAdded(address indexed curator);
    event CuratorRemoved(address indexed curator);
    event ArtistRegistered(address indexed artist);
    event CuratorApplicationSubmitted(address indexed applicant, string applicationText);
    event ArtSubmitted(uint256 indexed artId, address indexed artist, address nftContract, uint256 tokenId);
    event ArtApproved(uint256 indexed artId, address indexed curator);
    event ArtRejected(uint256 indexed artId, address indexed curator, string reason);
    event ArtListedFixedPrice(uint256 indexed listingId, uint256 indexed artId, uint256 price, uint256 endTime);
    event ArtListedAuction(uint256 indexed listingId, uint256 indexed artId, uint256 minBid, uint256 endTime);
    event ListingCancelled(uint256 indexed listingId, uint256 indexed artId);
    event ArtBought(uint256 indexed listingId, uint256 indexed artId, address indexed buyer, uint256 price);
    event AuctionBidPlaced(uint256 indexed listingId, address indexed bidder, uint256 amount, uint256 highestBid);
    event AuctionEnded(uint256 indexed listingId, uint256 indexed artId, address indexed winner, uint256 winningBid);
    event BidRefunded(uint256 indexed listingId, address indexed bidder, uint256 amount);
    event FractionalizationProposed(uint256 indexed artId, uint256 totalShares, uint256 pricePerShare);
    event ArtFractionBought(uint256 indexed artId, address indexed buyer, uint256 sharesBought, uint256 cost);
    event ArtFractionRedeemed(uint256 indexed artId, address indexed redeemer, uint256 totalSharesBurned);
    event ArtLiked(uint256 indexed artId, address indexed user, uint256 newLikeCount);
    event ArtistTipped(address indexed artist, uint256 indexed artId, address indexed tipper, uint256 amount);
    event ArtistProceedsWithdrawn(address indexed artist, uint256 amount);
    event GalleryFeesWithdrawn(uint256 amount);
    event ContractPaused(address account);
    event ContractUnpaused(address account);


    // --- Modifiers ---

    modifier onlyGalleryOwner() {
        require(msg.sender == i_owner, "Only gallery owner can call");
        _;
    }

    modifier onlyArtist(address _artist) {
        require(artistProfiles[_artist].isRegistered, "Only registered artists can call");
        _;
    }

    modifier onlyCurator() {
        require(curators[msg.sender], "Only curators can call");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    // Pausability state
    bool public paused = false;


    // --- Constructor ---

    constructor(uint256 _initialFeePercentage, uint256 _approvalsNeeded) {
        i_owner = msg.sender;
        galleryFeePercentage = _initialFeePercentage;
        approvalsNeededForCuration = _approvalsNeeded;
    }


    // --- Admin & Core Settings (1-6) ---

    /// @notice Sets the percentage of sale price taken as gallery commission.
    /// @param _feePercentage The fee percentage in basis points (e.g., 500 for 5%).
    function setGalleryFee(uint256 _feePercentage) public onlyGalleryOwner {
        require(_feePercentage <= FEE_DENOMINATOR, "Fee percentage cannot exceed 100%");
        galleryFeePercentage = _feePercentage;
        emit GalleryFeeSet(_feePercentage);
    }

    /// @notice Adds an address to the curator role.
    /// @param _curator The address to make a curator.
    function addCurator(address _curator) public onlyGalleryOwner {
        require(!curators[_curator], "Address is already a curator");
        curators[_curator] = true;
        emit CuratorAdded(_curator);
    }

    /// @notice Removes an address from the curator role.
    /// @param _curator The address to remove from the curator role.
    function removeCurator(address _curator) public onlyGalleryOwner {
        require(curators[_curator], "Address is not a curator");
        curators[_curator] = false;
        // Note: Removing a curator does not affect existing approval counts
        emit CuratorRemoved(_curator);
    }

    /// @notice Allows the owner to withdraw accumulated gallery fees.
    function withdrawGalleryFees() public onlyGalleryOwner nonReentrant {
        uint256 amount = galleryFunds[msg.sender];
        require(amount > 0, "No gallery fees to withdraw");
        galleryFunds[msg.sender] = 0;
        payable(msg.sender).sendValue(amount);
        emit GalleryFeesWithdrawn(amount);
    }

    /// @notice Pauses core contract functions (listing, buying, bidding).
    function pause() public onlyGalleryOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses the contract.
    function unpause() public onlyGalleryOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }


    // --- User & Role Management (7-9) ---

    /// @notice Registers the caller as an artist.
    /// @param _name The artist's name.
    /// @param _bio The artist's bio.
    function registerArtist(string memory _name, string memory _bio) public {
        require(!artistProfiles[msg.sender].isRegistered, "Address is already registered as artist");
        artistProfiles[msg.sender] = ArtistProfile(_name, _bio, true);
        emit ArtistRegistered(msg.sender);
    }

    /// @notice Submits an application to become a curator.
    /// @dev Owner must review applications off-chain. This function simply logs the intent.
    /// @param _applicationText A brief text explaining why they should be a curator.
    function applyAsCurator(string memory _applicationText) public {
        require(!curators[msg.sender], "Address is already a curator");
        // Owner reviews applications and calls addCurator manually
        emit CuratorApplicationSubmitted(msg.sender, _applicationText);
    }

    /// @notice Allows a registered artist to update their profile information.
    /// @param _name The new artist name.
    /// @param _bio The new artist bio.
    function updateArtistProfile(string memory _name, string memory _bio) public onlyArtist(msg.sender) {
         artistProfiles[msg.sender].name = _name;
         artistProfiles[msg.sender].bio = _bio;
         // No explicit event for update, rely on profile view
    }


    // --- Art Submission & Curation (10-12) ---

    /// @notice Submits an NFT art piece for curation and potential listing in the gallery.
    /// @dev Requires the NFT to be approved to the gallery contract *before* submission if the artist plans to list it later.
    /// @param _nftContract The address of the ERC721 contract.
    /// @param _tokenId The token ID of the NFT.
    function submitArtForCuration(address _nftContract, uint256 _tokenId) public onlyArtist(msg.sender) whenNotPaused {
        require(_nftContract != address(0), "Invalid NFT contract address");
        // Check if NFT exists and is owned by the artist (optional but good practice)
        require(IERC721(_nftContract).ownerOf(_tokenId) == msg.sender, "Only owner of NFT can submit");

        uint256 artId = nextArtId++;
        artItems[artId] = ArtItem({
            nftContract: _nftContract,
            tokenId: _tokenId,
            artist: msg.sender,
            submittedTimestamp: block.timestamp,
            isApproved: false,
            isListed: false,
            isFractionalized: false,
            approvalCount: 0,
            curatorApproved: new mapping(address => bool),
            rejectionReason: ""
        });

        emit ArtSubmitted(artId, msg.sender, _nftContract, _tokenId);
    }

    /// @notice Allows a curator to approve a submitted art piece.
    /// @param _artId The ID of the art item to approve.
    function curatorApproveArt(uint256 _artId) public onlyCurator whenNotPaused {
        ArtItem storage art = artItems[_artId];
        require(art.nftContract != address(0), "Art item does not exist");
        require(!art.isApproved, "Art is already fully approved");
        require(!art.curatorApproved[msg.sender], "Curator already approved this art");
        require(art.approvalCount < approvalsNeededForCuration, "Art already has enough approvals");

        art.curatorApproved[msg.sender] = true;
        art.approvalCount++;
        art.rejectionReason = ""; // Clear rejection reason on approval attempt

        if (art.approvalCount >= approvalsNeededForCuration) {
            art.isApproved = true;
        }

        emit ArtApproved(_artId, msg.sender);
    }

    /// @notice Allows a curator to reject a submitted art piece.
    /// @param _artId The ID of the art item to reject.
    /// @param _reason The reason for rejection.
    function curatorRejectArt(uint256 _artId, string memory _reason) public onlyCurator whenNotPaused {
        ArtItem storage art = artItems[_artId];
        require(art.nftContract != address(0), "Art item does not exist");
        require(!art.isApproved, "Art is already fully approved");

        // A rejection by one curator marks it as rejected (simpler logic)
        // For more complex logic, could require N rejections.
        art.isApproved = false; // Ensure it's marked not approved
        art.rejectionReason = _reason; // Overwrite any previous reason

        emit ArtRejected(_artId, msg.sender, _reason);
    }


    // --- Art Listings & Sales (13-18) ---

    /// @notice Lists an approved art piece for sale at a fixed price.
    /// @dev Requires the NFT to be approved to the gallery contract *before* listing.
    /// @param _artId The ID of the approved art item.
    /// @param _price The fixed price in wei.
    /// @param _duration The duration of the listing in seconds.
    /// @return listingId The ID of the created listing.
    function listArtForFixedPrice(uint256 _artId, uint256 _price, uint256 _duration) public payable onlyArtist(msg.sender) whenNotPaused returns (uint256 listingId) {
        ArtItem storage art = artItems[_artId];
        require(art.nftContract != address(0), "Art item does not exist");
        require(art.isApproved, "Art is not approved for listing");
        require(!art.isListed, "Art is already listed");
        require(!art.isFractionalized, "Fractionalized art cannot be listed normally");
        require(_price > 0, "Price must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");
        require(IERC721(art.nftContract).ownerOf(art.tokenId) == msg.sender, "Only the NFT owner can list");

        // The lister must have approved the NFT transfer to this contract
        address approvedAddress = IERC721(art.nftContract).getApproved(art.tokenId);
        require(approvedAddress == address(this) || IERC721(art.nftContract).isApprovedForAll(msg.sender, address(this)), "NFT not approved for transfer to gallery");

        listingId = nextListingId++;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + _duration;

        artListings[listingId] = ArtListing({
            artId: _artId,
            seller: payable(msg.sender),
            price: _price,
            startTime: startTime,
            endTime: endTime,
            isAuction: false,
            active: true,
            highestBidder: payable(address(0)), // Not used for fixed price
            highestBid: 0,                     // Not used for fixed price
            bids: new mapping(address => uint256) // Not used for fixed price
        });

        art.isListed = true;

        emit ArtListedFixedPrice(listingId, _artId, _price, endTime);
        return listingId;
    }

    /// @notice Lists an approved art piece for auction (English auction).
    /// @dev Requires the NFT to be approved to the gallery contract *before* listing.
    /// @param _artId The ID of the approved art item.
    /// @param _minBid The minimum starting bid in wei.
    /// @param _duration The duration of the auction in seconds.
    /// @return listingId The ID of the created listing.
    function listArtForAuction(uint256 _artId, uint256 _minBid, uint256 _duration) public payable onlyArtist(msg.sender) whenNotPaused returns (uint256 listingId) {
        ArtItem storage art = artItems[_artId];
        require(art.nftContract != address(0), "Art item does not exist");
        require(art.isApproved, "Art is not approved for listing");
        require(!art.isListed, "Art is already listed");
        require(!art.isFractionalized, "Fractionalized art cannot be listed normally");
        require(_minBid >= 0, "Minimum bid cannot be negative"); // 0 is valid for starting bid
        require(_duration > 0, "Duration must be greater than 0");
        require(IERC721(art.nftContract).ownerOf(art.tokenId) == msg.sender, "Only the NFT owner can list");

        // The lister must have approved the NFT transfer to this contract
        address approvedAddress = IERC721(art.nftContract).getApproved(art.tokenId);
        require(approvedAddress == address(this) || IERC721(art.nftContract).isApprovedForAll(msg.sender, address(this)), "NFT not approved for transfer to gallery");

        listingId = nextListingId++;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + _duration;

        artListings[listingId] = ArtListing({
            artId: _artId,
            seller: payable(msg.sender),
            price: _minBid, // Min bid
            startTime: startTime,
            endTime: endTime,
            isAuction: true,
            active: true,
            highestBidder: payable(address(0)),
            highestBid: 0, // Starts at 0, first bid must be >= minBid
            bids: new mapping(address => uint256)
        });

        art.isListed = true;

        emit ArtListedAuction(listingId, _artId, _minBid, endTime);
        return listingId;
    }

    /// @notice Allows the seller of an art piece or the gallery owner to cancel an active listing/auction.
    /// @dev Cannot cancel if an auction already has bids.
    /// @param _listingId The ID of the listing to cancel.
    function cancelListing(uint256 _listingId) public whenNotPaused {
        ArtListing storage listing = artListings[_listingId];
        require(listing.active, "Listing is not active");
        require(msg.sender == listing.seller || msg.sender == i_owner, "Only seller or owner can cancel");
        require(listing.highestBid == 0, "Cannot cancel auction with bids");
        require(block.timestamp < listing.endTime, "Cannot cancel after listing/auction ended");

        listing.active = false;
        artItems[listing.artId].isListed = false;

        // NFT remains with the seller, no transfer needed here.
        // Approval to this contract might still be active.

        emit ListingCancelled(_listingId, listing.artId);
    }

    /// @notice Purchases an art piece listed at a fixed price.
    /// @param _listingId The ID of the fixed-price listing.
    function buyArtFixedPrice(uint256 _listingId) public payable nonReentrant whenNotPaused {
        ArtListing storage listing = artListings[_listingId];
        require(listing.active && !listing.isAuction, "Listing is not an active fixed price sale");
        require(block.timestamp < listing.endTime, "Listing has expired");
        require(msg.value >= listing.price, "Insufficient funds");

        ArtItem storage art = artItems[listing.artId];
        require(art.nftContract != address(0), "Art item linked to listing does not exist");
        require(!art.isFractionalized, "Fractionalized art cannot be bought this way");

        uint256 amountToSeller = listing.price;
        uint256 fee = (amountToSeller * galleryFeePercentage) / FEE_DENOMINATOR;
        amountToSeller = amountToSeller - fee;

        listing.active = false; // Mark as sold
        art.isListed = false;

        // Transfer NFT from seller to buyer
        IERC721(art.nftContract).safeTransferFrom(listing.seller, msg.sender, art.tokenId);

        // Distribute funds
        artistProceeds[listing.seller] += amountToSeller;
        galleryFunds[i_owner] += fee; // Gallery fees go to owner's withdrawable balance

        // Refund any excess ETH sent
        if (msg.value > listing.price) {
            payable(msg.sender).sendValue(msg.value - listing.price);
        }

        emit ArtBought(_listingId, listing.artId, msg.sender, listing.price);
    }

    /// @notice Places a bid on an art auction.
    /// @param _listingId The ID of the auction listing.
    function placeAuctionBid(uint256 _listingId) public payable nonReentrant whenNotPaused {
        ArtListing storage listing = artListings[_listingId];
        require(listing.active && listing.isAuction, "Listing is not an active auction");
        require(block.timestamp >= listing.startTime && block.timestamp < listing.endTime, "Auction is not active");
        require(msg.value > listing.highestBid, "Bid must be higher than current highest bid");
        require(msg.value >= listing.price, "Bid must be at least the minimum bid"); // price stores minBid for auction
        require(msg.sender != listing.seller, "Seller cannot bid on their own auction");

        // Refund previous highest bidder
        if (listing.highestBidder != payable(address(0))) {
            uint256 refundAmount = listing.highestBid;
            require(listing.bids[listing.highestBidder] >= refundAmount, "Internal error: Bidder balance mismatch"); // Sanity check
            listing.bids[listing.highestBidder] -= refundAmount;
            // Instead of direct transfer, add to a withdrawable balance
            artistProceeds[listing.highestBidder] += refundAmount; // Re-using artistProceeds map for simplicity, could use a dedicated bidRefunds map
            emit BidRefunded(_listingId, listing.highestBidder, refundAmount);
        }

        // Update highest bid
        listing.highestBidder = payable(msg.sender);
        listing.highestBid = msg.value;
        listing.bids[msg.sender] += msg.value; // Add full bid amount to bidder's balance tracking

        emit AuctionBidPlaced(_listingId, msg.sender, msg.value, listing.highestBid);
    }

    /// @notice Ends an art auction. Can be called by anyone after the end time.
    /// @param _listingId The ID of the auction listing.
    function endAuction(uint256 _listingId) public nonReentrant {
        ArtListing storage listing = artListings[_listingId];
        require(listing.active && listing.isAuction, "Listing is not an active auction");
        require(block.timestamp >= listing.endTime, "Auction has not ended yet");

        listing.active = false; // Mark auction as ended

        ArtItem storage art = artItems[listing.artId];
        art.isListed = false; // Mark art as not listed

        if (listing.highestBidder == payable(address(0)) || listing.highestBid < listing.price) {
            // No bids or highest bid below min bid - auction failed
            // NFT remains with seller.
            emit AuctionEnded(_listingId, listing.artId, address(0), 0);
        } else {
            // Auction successful
            address payable winner = listing.highestBidder;
            uint256 winningBid = listing.highestBid;
            address payable seller = listing.seller;

            // Transfer NFT from seller to winner
            // Requires seller to have approved the gallery contract to transfer the NFT initially
            IERC721(art.nftContract).safeTransferFrom(seller, winner, art.tokenId);

            // Calculate fees and distribute funds
            uint256 fee = (winningBid * galleryFeePercentage) / FEE_DENOMINATOR;
            uint256 amountToSeller = winningBid - fee;

            artistProceeds[seller] += amountToSeller; // Pay seller (likely the artist)
            galleryFunds[i_owner] += fee;             // Gallery fees

            // The winner's bid amount is already held in listing.bids[winner].
            // The amount equal to winningBid is transferred to seller/gallery.
            // Any amount bid *above* the winning bid by the winner needs to be refunded.
            // In a standard English auction, the winning bid is the highest bid.
            // The full amount sent by the winner is listing.bids[winner].
            // The winning price is listing.highestBid.
            // Refund = listing.bids[winner] - listing.highestBid
            uint256 refundToWinner = listing.bids[winner] - listing.highestBid;
            if (refundToWinner > 0) {
                 artistProceeds[winner] += refundToWinner; // Re-using map for winner's refund
                 emit BidRefunded(_listingId, winner, refundToWinner);
            }
             listing.bids[winner] = 0; // Clear the winner's bid balance after processing

            emit AuctionEnded(_listingId, listing.artId, winner, winningBid);
        }
    }


    // --- Fractional Ownership Management (19-21) ---
    // Note: This is an internal fractionalization model. The original NFT is held by the gallery contract.
    // Users buy/sell 'shares' tracked internally by this contract.
    // Redemption is only possible by the address that holds 100% of the shares.

    /// @notice Proposes an approved art piece for fractionalization.
    /// @dev Requires the NFT to be transferred to the gallery contract before proposing.
    /// Once fractionalized, the NFT is held by the gallery and standard listings are disabled.
    /// @param _artId The ID of the approved art item.
    /// @param _totalShares The total number of shares to divide the art into.
    /// @param _pricePerShare The price in wei for each share.
    function proposeFractionalization(uint256 _artId, uint256 _totalShares, uint256 _pricePerShare) public payable onlyArtist(msg.sender) whenNotPaused {
        ArtItem storage art = artItems[_artId];
        require(art.nftContract != address(0), "Art item does not exist");
        require(art.isApproved, "Art is not approved for fractionalization");
        require(!art.isListed, "Art is currently listed");
        require(!art.isFractionalized, "Art is already fractionalized");
        require(_totalShares > 0, "Total shares must be greater than 0");
        require(_pricePerShare > 0, "Price per share must be greater than 0");
        require(IERC721(art.nftContract).ownerOf(art.tokenId) == msg.sender, "Only the NFT owner can propose fractionalization");

        // NFT must be transferred to this contract before finalizing fractionalization
        // Artist must call safeTransferFrom(msg.sender, address(this), art.tokenId) on the NFT contract first.
        require(IERC721(art.nftContract).ownerOf(art.tokenId) == address(this), "NFT must be transferred to gallery contract first");

        art.isFractionalized = true;
        fractionalArtInfo[_artId] = FractionalArtInfo({
            totalShares: _totalShares,
            pricePerShare: _pricePerShare,
            currentHolder: address(this)
        });

        // Artist (proposer) initially owns all shares
        artFractions[_artId][msg.sender] = _totalShares;

        emit FractionalizationProposed(_artId, _totalShares, _pricePerShare);
    }

    /// @notice Allows a user to buy shares of a fractionalized art piece.
    /// @param _artId The ID of the fractionalized art item.
    /// @param _shares The number of shares to buy.
    function buyArtFraction(uint256 _artId, uint256 _shares) public payable nonReentrant whenNotPaused {
        ArtItem storage art = artItems[_artId];
        require(art.isFractionalized, "Art is not fractionalized");
        FractionalArtInfo storage fractionInfo = fractionalArtInfo[_artId];
        require(_shares > 0, "Must buy at least 1 share");

        uint256 cost = _shares * fractionInfo.pricePerShare;
        require(msg.value >= cost, "Insufficient ETH sent");

        // Transfer ETH to the fractional art's current holder (initially the artist)
        // In this simple model, the ETH for shares goes to the artist who fractionalized it.
        // More complex models could distribute pro-rata to existing share holders.
        // For now, funds go to the original owner who proposed fractionalization.
        // Need to track original owner or send to artistProceeds directly. Let's send to artistProceeds.
        // Assumes the artist who proposed is the one whose proceeds should receive funds.
        address originalArtist = art.artist; // Funds go to the artist who submitted the art
        artistProceeds[originalArtist] += cost;

        // Assign shares to the buyer
        artFractions[_artId][msg.sender] += _shares;

        // Refund excess ETH
        if (msg.value > cost) {
             payable(msg.sender).sendValue(msg.value - cost);
        }

        emit ArtFractionBought(_artId, msg.sender, _shares, cost);
    }

     /// @notice Allows the holder of 100% of the shares to redeem the original NFT.
     /// @param _artId The ID of the fractionalized art item.
     function redeemArtFraction(uint256 _artId) public nonReentrant whenNotPaused {
        ArtItem storage art = artItems[_artId];
        require(art.isFractionalized, "Art is not fractionalized");
        FractionalArtInfo storage fractionInfo = fractionalArtInfo[_artId];

        // Check if caller owns all shares
        require(artFractions[_artId][msg.sender] == fractionInfo.totalShares, "Caller does not own all shares");

        // Transfer NFT from gallery contract back to the redeemer
        IERC721(art.nftContract).safeTransferFrom(address(this), msg.sender, art.tokenId);

        // Burn the shares held by the redeemer
        artFractions[_artId][msg.sender] = 0;

        // Mark art as not fractionalized and update info
        art.isFractionalized = false;
        // Clear fractional info? Or keep it for history? Let's clear relevant parts.
        fractionInfo.currentHolder = address(0); // No longer held by gallery

        emit ArtFractionRedeemed(_artId, msg.sender, fractionInfo.totalShares);
    }


    // --- Social & Interaction Features (22-23) ---

    /// @notice Allows a user to like a specific art piece.
    /// @param _artId The ID of the art item to like.
    function likeArt(uint256 _artId) public whenNotPaused {
        ArtItem storage art = artItems[_artId];
        require(art.nftContract != address(0), "Art item does not exist");

        if (!userLikesArt[msg.sender][_artId]) {
            userLikesArt[msg.sender][_artId] = true;
            artLikeCount[_artId]++;

            // Add to user's liked list if not already there
            // (Simple append, could add checks for duplicates if needed, but mapping prevents double likes)
            userLikedArtIds[msg.sender].push(_artId);

            emit ArtLiked(_artId, msg.sender, artLikeCount[_artId]);
        }
        // If already liked, do nothing.
    }

    /// @notice Allows a user to tip an artist.
    /// @param _artist The address of the artist to tip.
    /// @param _artId The ID of a specific art piece by this artist (optional context).
    function tipArtist(address payable _artist, uint256 _artId) public payable whenNotPaused {
        require(artistProfiles[_artist].isRegistered, "Recipient is not a registered artist");
        require(msg.value > 0, "Tip amount must be greater than 0");

        // Optionally validate _artId belongs to _artist if needed for stricter context
        // require(artItems[_artId].artist == _artist, "Art ID does not belong to this artist");

        // Send tip amount directly to artist's withdrawable balance
        artistProceeds[_artist] += msg.value;

        emit ArtistTipped(_artist, _artId, msg.sender, msg.value);
    }


    // --- Withdrawals (24-25) ---

    /// @notice Allows a registered artist to withdraw their accumulated proceeds from sales and tips.
    function withdrawArtistProceeds() public onlyArtist(msg.sender) nonReentrant {
        uint256 amount = artistProceeds[msg.sender];
        require(amount > 0, "No proceeds to withdraw");
        artistProceeds[msg.sender] = 0;
        payable(msg.sender).sendValue(amount);
        emit ArtistProceedsWithdrawn(msg.sender, amount);
    }

     /// @notice Allows a bidder to withdraw their refundable amount from an auction (outbid or cancelled).
     /// @dev This re-uses the artistProceeds mapping for simplicity.
     /// @param _listingId The ID of the auction the bid was placed on.
     function withdrawBidRefund(uint256 _listingId) public nonReentrant {
        ArtListing storage listing = artListings[_listingId];
        // Check if the listing exists and the caller had a bid recorded
        require(listing.artId != 0, "Listing does not exist");
        uint256 amount = listing.bids[msg.sender]; // Check mapping associated with the listing
        require(amount > 0, "No refundable bid amount for this listing");
        require(listing.highestBidder != msg.sender, "Cannot withdraw full bid while you are the highest bidder"); // Prevent winner withdrawing before endAuction

        listing.bids[msg.sender] = 0; // Clear the amount for this listing
        // Add to the general artistProceeds map for withdrawal.
        // This conflates bid refunds with artist proceeds, but simplifies state.
        // A dedicated mapping `bidRefunds[user][listingId]` and `withdrawBidRefunds()` function would be more precise.
        // Let's stick to re-using artistProceeds for brevity, as the artist is the most likely bidder who needs refund.
        // A user who is not an artist *can* still get funds into artistProceeds this way.
        artistProceeds[msg.sender] += amount;

        // Alternative: Direct send here. Using artistProceeds map is safer with nonReentrant.
        // payable(msg.sender).sendValue(amount);
        // emit BidRefunded(_listingId, msg.sender, amount); // Can emit here or in placeAuctionBid/endAuction
        // For consistency, let's only emit in placeAuctionBid/endAuction when refund is scheduled.
     }


    // --- View Functions (26-32) ---

    /// @notice Gets details about a specific art item.
    /// @param _artId The ID of the art item.
    /// @return artItem Returns the ArtItem struct.
    function getArtDetails(uint256 _artId) public view returns (ArtItem memory) {
        require(artItems[_artId].nftContract != address(0), "Art item does not exist");
        return artItems[_artId];
    }

    /// @notice Gets details about a specific art listing (fixed price or auction).
    /// @param _listingId The ID of the listing.
    /// @return listing Returns the ArtListing struct.
    function getArtListingDetails(uint256 _listingId) public view returns (ArtListing memory) {
        require(artListings[_listingId].artId != 0, "Listing does not exist");
        return artListings[_listingId];
    }

    /// @notice Gets fractionalization details for an art piece.
    /// @param _artId The ID of the art item.
    /// @return info Returns the FractionalArtInfo struct and user's shares.
    /// @return userShares Returns the number of shares the caller owns.
    function getArtFractionDetails(uint256 _artId) public view returns (FractionalArtInfo memory info, uint256 userShares) {
        require(artItems[_artId].isFractionalized, "Art is not fractionalized");
        info = fractionalArtInfo[_artId];
        userShares = artFractions[_artId][msg.sender];
        return (info, userShares);
    }

    /// @notice Gets the profile details for a registered artist.
    /// @param _artist The address of the artist.
    /// @return profile Returns the ArtistProfile struct.
    function getArtistProfile(address _artist) public view returns (ArtistProfile memory) {
        require(artistProfiles[_artist].isRegistered, "Address is not a registered artist");
        return artistProfiles[_artist];
    }

    /// @notice Checks if an address is a curator.
    /// @param _user The address to check.
    /// @return isCuratorStatus True if the address is a curator, false otherwise.
    function isCurator(address _user) public view returns (bool isCuratorStatus) {
        return curators[_user];
    }

     /// @notice Gets the current gallery fee percentage.
     /// @return feePercentage Returns the fee percentage in basis points.
     function getGalleryFeePercentage() public view returns (uint256 feePercentage) {
         return galleryFeePercentage;
     }

     /// @notice Gets the list of art IDs liked by a specific user.
     /// @param _user The address of the user.
     /// @return likedArtIds Returns an array of art IDs liked by the user.
     function getUserLikedArt(address _user) public view returns (uint256[] memory) {
         return userLikedArtIds[_user];
     }

    // Fallback and Receive functions to accept ETH
    receive() external payable {
        // ETH sent directly to the contract could be considered a general tip or handled
        // based on contract state (e.g., during a specific event).
        // For this contract, direct ETH might be unexpected unless part of a specific flow.
        // Let's allow it but not assign it automatically, it will be held in contract balance.
        // Could add a mechanism for owner to withdraw or redistribute unassigned ETH.
        // For simplicity, we'll leave it accessible only via the owner's withdrawGalleryFees
        // if we conceptually tie unassigned ETH to gallery funds.
    }

    fallback() external payable {
        // Same logic as receive
    }
}
```

---

**Explanation of Concepts & Features:**

1.  **Custom Roles (`onlyGalleryOwner`, `onlyArtist`, `onlyCurator`):** Instead of standard libraries like OpenZeppelin's AccessControl, custom mappings (`curators`, `artistProfiles`) and modifiers are used for granular control based on gallery-specific roles.
2.  **Community Curation:** Artists `submitArtForCuration`. Curators (appointed by the owner) review and `curatorApproveArt`. Art requires a threshold (`approvalsNeededForCuration`) of curator approvals before it can be listed. Curators can also `curatorRejectArt`.
3.  **Multiple Listing Types:** Supports both `listArtForFixedPrice` and `listArtForAuction` (English auction). Each listing has a duration and is tied to an approved `ArtItem`.
4.  **Auction Mechanics:** Includes `placeAuctionBid`, `endAuction`, and handling of bid refunds for outbid users (`withdrawBidRefund`). Bids are tracked internally per listing.
5.  **Internal Fractionalization:** A more advanced concept where the original NFT is transferred to and held by the gallery contract (`proposeFractionalization`). Users buy "shares" tracked *within* the gallery contract (`buyArtFraction`). The original NFT can only be `redeemArtFraction` by an address holding 100% of the internal shares. This avoids relying on external ERC20 or ERC1155 contracts *for the shares themselves* within this example (though in a real system, issuing ERC20s is more standard for tradability). The NFT must be sent to the gallery *before* proposing fractionalization.
6.  **Social Features:** Users can `likeArt`, with the counts tracked (`artLikeCount`). They can also `tipArtist` directly in ETH, with tips added to the artist's withdrawable balance. A view function `getUserLikedArt` shows a user's liked items.
7.  **Withdrawal System:** Sales proceeds and tips for artists are accumulated in `artistProceeds` mapping, requiring artists to call `withdrawArtistProceeds`. Bid refunds are also tracked (re-using `artistProceeds` mapping for simplicity) and withdrawn via `withdrawBidRefund`. Gallery fees are accumulated and withdrawn by the owner via `withdrawGalleryFees`. This uses the pull pattern (`nonReentrant`) for safety.
8.  **Pausability:** Standard owner-controlled pausing mechanism to halt sensitive operations (`pause`, `unpause`, `whenNotPaused`, `whenPaused`).
9.  **Interaction with ERC721:** The contract does *not* mint NFTs. It interacts with *external* ERC721 contracts. Artists must own the NFT and approve the gallery contract (`setApprovalForAll` or `approve`) before submitting/listing, allowing the gallery to transfer the NFT upon sale or redemption.
10. **Gas Considerations:** While having many functions, the state structure is somewhat optimized by using mappings directly keyed by IDs. However, storing string profiles, mapping within structs (`curatorApproved`), and arrays (`userLikedArtIds`) adds complexity and gas cost, especially for writing operations and some view functions (arrays). The fractionalization model storing shares internally is less gas-heavy than external ERC20 transfers *within* the gallery functions, but the redemption might be gas intensive depending on share holder count (though redeemed by single holder).
11. **Error Handling & Events:** Includes custom `require` messages and comprehensive events for transparency and off-chain monitoring.

This contract demonstrates a blend of ownership, marketplace, social, and financial concepts built around a core curation process for NFTs. It goes beyond a simple marketplace by adding layers of interaction and custom mechanics.