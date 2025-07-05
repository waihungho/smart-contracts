Okay, here is a smart contract concept for a "Decentralized Dynamic Art Gallery" featuring a multi-stage curation process, different sale mechanisms, user interaction features (liking), and a basic commission/payout system. It builds upon standard interfaces (ERC721) but adds novel logic for the gallery operations, aiming for creativity and advanced concepts beyond a simple minting contract or marketplace.

It will implement at least 20 custom functions related to the gallery's specific logic.

---

**Smart Contract: DecentralizedDynamicArtGallery**

**Concept:**

This contract represents a decentralized art gallery where artists can submit digital artworks (as NFTs), the community and appointed curators collaboratively curate submissions, and approved artworks can be listed for direct sale or auction. The contract incorporates features for user interaction (liking artworks) and manages the distribution of sale proceeds, including a gallery commission. The "Dynamic" aspect refers to the potential for artwork metadata (handled off-chain or via related contracts not detailed here) to potentially react to on-chain events tracked by the gallery, though the contract primarily focuses on the gallery *management* logic.

**Advanced/Creative Concepts:**

1.  **Multi-Stage Decentralized Curation:** Combines community voting with a final curator approval step.
2.  **Integrated Sales Mechanisms:** Supports both direct sales and timed auctions within the same contract.
3.  **Social/Interaction Layer:** Tracks "likes" on artworks, a simple but unique feature for an art NFT contract itself.
4.  **Automated Commission & Payouts:** Manages splitting funds between artists and the gallery upon sale.
5.  **Role-Based Access Control:** Uses `Ownable` for administration and a custom `Curator` role for curation.

**Outline:**

1.  **State Variables:**
    *   Basic ERC721 properties (name, symbol, token counter, owner mappings - inherited/managed).
    *   Gallery configuration (commission rate, vote thresholds).
    *   Artwork data (metadata URI, artist, status, votes, likes).
    *   Curation data (curator addresses).
    *   Marketplace data (direct sale prices, auction details).
    *   Financial data (balances for artists and gallery).
    *   Mapping to track user votes and likes per artwork.
    *   Mapping to track artworks per artist.

2.  **Enums:** Artwork status (PendingSubmission, PendingCommunityVote, PendingCuratorApproval, Approved, Rejected, ListedForSale, ListedForAuction, Sold).

3.  **Structs:**
    *   `Artwork`: Stores main artwork details.
    *   `Auction`: Stores details for an active auction.

4.  **Events:**
    *   Lifecycle: `ArtworkSubmitted`, `ArtworkApproved`, `ArtworkRejected`.
    *   Curation: `VoteCast`, `CuratorAdded`, `CuratorRemoved`.
    *   Marketplace: `ArtworkListedForSale`, `ArtworkSalePriceUpdated`, `ArtworkSaleCancelled`, `ArtworkPurchased`, `ArtworkListedForAuction`, `NewBid`, `AuctionSettled`, `AuctionCancelled`.
    *   Interaction: `ArtworkLiked`, `ArtworkUnliked`.
    *   Financial: `ArtistProceedsWithdrawn`, `GalleryCommissionWithdrawn`.
    *   Configuration: `CommissionRateUpdated`, `VoteThresholdsUpdated`.

5.  **Modifiers:** `onlyCurator`, `onlyArtistOf`, `onlyApprovedOrOwnerOf`.

6.  **Functions:** (Detailed summary below - aiming for 20+ custom logic functions)

**Function Summary (Custom Logic Functions):**

*(Inherited ERC721 standard functions like `transferFrom`, `ownerOf`, `balanceOf`, etc., are not listed here as they are standard and not part of the contract's novel gallery logic, though they are necessary for NFT functionality).*

1.  `submitArtwork(string memory tokenURI)`: Allows an artist to submit a new artwork NFT for consideration. Mints the token and sets status to `PendingCommunityVote`.
2.  `voteForArtwork(uint256 artworkId)`: Allows any user to cast a vote for a submitted artwork. Increments vote count. If threshold met, updates status to `PendingCuratorApproval`.
3.  `getArtworkVotes(uint256 artworkId)`: View function to get current community vote count for an artwork.
4.  `approveArtwork(uint256 artworkId)`: Allows a curator to approve an artwork if it's in `PendingCuratorApproval` state. Sets status to `Approved`.
5.  `rejectArtwork(uint256 artworkId, string memory reason)`: Allows a curator to reject an artwork in `PendingCuratorApproval` state. Sets status to `Rejected`. Artist can withdraw.
6.  `withdrawRejectedArtwork(uint256 artworkId)`: Allows the original artist to burn or retrieve a rejected artwork NFT. (Let's allow burning to keep the gallery clean).
7.  `listArtworkForDirectSale(uint256 artworkId, uint256 price)`: Allows the artwork owner (artist initially) to list an approved artwork for direct purchase. Sets status to `ListedForSale`.
8.  `updateDirectSalePrice(uint256 artworkId, uint256 newPrice)`: Allows the owner to change the price of an artwork listed for direct sale.
9.  `cancelDirectSale(uint256 artworkId)`: Allows the owner to remove an artwork from direct sale listing. Sets status back to `Approved`.
10. `purchaseArtwork(uint256 artworkId)`: Allows a buyer to purchase an artwork listed for direct sale by sending the exact ETH price. Handles ownership transfer, commission calculation, and payout balance updates.
11. `listArtworkForAuction(uint256 artworkId, uint256 reservePrice, uint256 duration)`: Allows the owner to list an approved artwork for auction. Sets status to `ListedForAuction`.
12. `placeBid(uint256 artworkId)`: Allows a user to place a bid on an artwork auction. Must be higher than the current highest bid and reserve price (initially). Handles returning previous bid ETH.
13. `settleAuction(uint256 artworkId)`: Allows anyone to settle an auction after the duration ends. If successful bid exists, transfers ownership, calculates commission, and updates payout balances. If no bids, cancels listing.
14. `cancelAuctionListing(uint256 artworkId)`: Allows the owner to cancel an auction before the first bid is placed. Sets status back to `Approved`.
15. `likeArtwork(uint256 artworkId)`: Allows a user to "like" an artwork. Tracks per user to prevent duplicate likes.
16. `unlikeArtwork(uint256 artworkId)`: Allows a user to remove their "like" from an artwork.
17. `getArtworkLikes(uint256 artworkId)`: View function to get the total number of likes for an artwork.
18. `withdrawArtistProceeds()`: Allows an artist to withdraw their accumulated ETH balance from artwork sales, minus commission.
19. `withdrawGalleryCommission()`: Allows the contract owner (gallery admin) to withdraw the accumulated gallery commission ETH.
20. `addCurator(address curatorAddress)`: Allows the contract owner to add an address to the list of approved curators.
21. `removeCurator(address curatorAddress)`: Allows the contract owner to remove an address from the curator list.
22. `isCurator(address account)`: View function to check if an address is a curator.
23. `setCommissionRate(uint256 rate)`: Allows the owner to set the gallery commission rate (in basis points, e.g., 500 for 5%).
24. `setMinVoteThresholds(uint256 submissionThreshold, uint256 curatorApprovalThreshold)`: Allows the owner to set the minimum community votes needed to move artwork from PendingCommunityVote to PendingCuratorApproval state.
25. `getArtworkDetails(uint256 artworkId)`: View function to retrieve detailed information about an artwork.
26. `getArtistArtworks(address artist)`: View function to list all artwork IDs associated with a specific artist.
27. `getAuctionDetails(uint256 artworkId)`: View function to retrieve current details for an active auction.
28. `getDirectSalePrice(uint256 artworkId)`: View function to get the direct sale price if listed.
29. `getGalleryBalance()`: View function to see the ETH balance held by the gallery for commissions/payouts.
30. `getArtworkStatus(uint256 artworkId)`: View function to get the current status of an artwork.

*(This list already has 30 custom functions, fulfilling the requirement of at least 20)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Smart Contract: DecentralizedDynamicArtGallery
// Concept: A decentralized platform for artists to submit, curate (via community vote & curators),
// display, and sell digital artworks as NFTs through direct sales and auctions.
// Includes features for user interaction (liking) and automated commission/payouts.
// Advanced Concepts: Multi-stage decentralized curation, integrated marketplace types, social interaction layer.
// Novelty: Combines community voting, curator approval, direct sale, auction, and liking mechanisms
// within a single NFT gallery contract, with custom payout logic.

// Outline:
// - State Variables (Gallery config, Artwork data, Curation, Marketplace, Financial)
// - Enums (Artwork status)
// - Structs (Artwork, Auction)
// - Events (Lifecycle, Curation, Marketplace, Interaction, Financial, Configuration)
// - Modifiers (onlyCurator, onlyArtistOf, etc.)
// - Functions (30+ custom logic functions listed in summary above)

// Function Summary (Custom Logic - Not standard ERC721):
// 1. submitArtwork(string memory tokenURI)
// 2. voteForArtwork(uint256 artworkId)
// 3. getArtworkVotes(uint256 artworkId)
// 4. approveArtwork(uint256 artworkId)
// 5. rejectArtwork(uint256 artworkId, string memory reason)
// 6. withdrawRejectedArtwork(uint256 artworkId)
// 7. listArtworkForDirectSale(uint256 artworkId, uint256 price)
// 8. updateDirectSalePrice(uint256 artworkId, uint256 newPrice)
// 9. cancelDirectSale(uint256 artworkId)
// 10. purchaseArtwork(uint256 artworkId)
// 11. listArtworkForAuction(uint256 artworkId, uint256 reservePrice, uint256 duration)
// 12. placeBid(uint256 artworkId)
// 13. settleAuction(uint256 artworkId)
// 14. cancelAuctionListing(uint256 artworkId)
// 15. likeArtwork(uint256 artworkId)
// 16. unlikeArtwork(uint256 artworkId)
// 17. getArtworkLikes(uint256 artworkId)
// 18. withdrawArtistProceeds()
// 19. withdrawGalleryCommission()
// 20. addCurator(address curatorAddress)
// 21. removeCurator(address curatorAddress)
// 22. isCurator(address account)
// 23. setCommissionRate(uint256 rate)
// 24. setMinVoteThresholds(uint256 submissionThreshold, uint256 curatorApprovalThreshold)
// 25. getArtworkDetails(uint256 artworkId)
// 26. getArtworkVotes(uint256 artworkId) // Duplicate from 3, kept for clarity in list.
// 27. getArtworkLikes(uint256 artworkId) // Duplicate from 17, kept for clarity in list.
// 28. getArtistArtworks(address artist)
// 29. getAuctionDetails(uint256 artworkId)
// 30. getDirectSalePrice(uint256 artworkId)
// 31. getGalleryBalance()
// 32. getArtworkStatus(uint256 artworkId)

contract DecentralizedDynamicArtGallery is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _artworkIds;

    enum ArtworkStatus {
        PendingSubmission, // Initial state (though not used as it immediately moves to PendingCommunityVote)
        PendingCommunityVote, // Awaiting community votes for threshold
        PendingCuratorApproval, // Passed community threshold, awaiting curator review
        Approved, // Approved by curator, eligible for listing
        Rejected, // Rejected by curator, artist can withdraw/burn
        ListedForSale, // Listed for direct purchase
        ListedForAuction, // Listed for auction
        Sold // Sold (NFT ownership transferred, funds pending withdrawal)
    }

    struct Artwork {
        address artist;
        string tokenURI;
        ArtworkStatus status;
        uint256 creationTimestamp;
    }

    struct Auction {
        uint256 artworkId;
        uint256 reservePrice;
        uint256 startTime;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool ended;
        address payable seller; // Owner at time of listing
    }

    // --- State Variables ---
    mapping(uint256 => Artwork) private _artworks;
    mapping(address => uint256[]) private _artistArtworks; // Track artworks per artist
    mapping(address => bool) private _curators; // Set of approved curators

    // Curation State
    mapping(uint256 => mapping(address => bool)) private _artworkVotes; // ArtworkId => Voter => Voted
    mapping(uint256 => uint256) private _artworkVoteCounts; // ArtworkId => Total Votes
    uint256 public minCommunityVotesForCuratorReview; // Threshold for community voting

    // Interaction State
    mapping(uint256 => mapping(address => bool)) private _artworkLikes; // ArtworkId => Liker => Liked
    mapping(uint256 => uint256) private _artworkLikeCounts; // ArtworkId => Total Likes

    // Marketplace State
    mapping(uint256 => uint256) private _directSalePrices; // ArtworkId => Price
    mapping(uint256 => Auction) private _artworkAuctions; // ArtworkId => Auction details
    mapping(address => uint256) private _pendingReturns; // Address => ETH balance waiting to be returned (e.g., failed bids)

    // Financial State
    uint256 public galleryCommissionRateBasisPoints; // e.g., 500 for 5%
    mapping(address => uint256) private _artistBalances; // Artist Address => ETH balance pending withdrawal
    uint256 private _galleryBalance; // Accumulated gallery commission

    // --- Events ---
    event ArtworkSubmitted(uint256 indexed artworkId, address indexed artist, string tokenURI);
    event ArtworkStatusUpdated(uint256 indexed artworkId, ArtworkStatus oldStatus, ArtworkStatus newStatus);
    event ArtworkApproved(uint256 indexed artworkId, address indexed curator);
    event ArtworkRejected(uint256 indexed artworkId, address indexed curator, string reason);

    event VoteCast(uint256 indexed artworkId, address indexed voter);
    event CuratorAdded(address indexed curator);
    event CuratorRemoved(address indexed curator);

    event ArtworkLiked(uint256 indexed artworkId, address indexed liker);
    event ArtworkUnliked(uint256 indexed artworkId, address indexed unliker);

    event ArtworkListedForSale(uint256 indexed artworkId, uint256 price);
    event ArtworkSalePriceUpdated(uint256 indexed artworkId, uint256 newPrice);
    event ArtworkSaleCancelled(uint256 indexed artworkId);
    event ArtworkPurchased(uint256 indexed artworkId, address indexed buyer, uint256 price);

    event ArtworkListedForAuction(uint256 indexed artworkId, uint256 reservePrice, uint256 duration);
    event NewBid(uint256 indexed artworkId, address indexed bidder, uint256 amount);
    event AuctionSettled(uint256 indexed artworkId, address indexed winner, uint256 finalPrice);
    event AuctionCancelled(uint256 indexed artworkId, string reason);

    event ArtistProceedsWithdrawn(address indexed artist, uint256 amount);
    event GalleryCommissionWithdrawn(uint256 amount);

    event CommissionRateUpdated(uint256 newRate);
    event VoteThresholdsUpdated(uint256 newSubmissionThreshold, uint256 newCuratorApprovalThreshold);

    // --- Modifiers ---
    modifier onlyCurator() {
        require(_curators[msg.sender], "Only curators can perform this action");
        _;
    }

    modifier onlyArtworkOwner(uint256 artworkId) {
        require(ownerOf(artworkId) == msg.sender, "Only artwork owner can perform this action");
        _;
    }

    modifier whenArtworkInStatus(uint256 artworkId, ArtworkStatus expectedStatus) {
        require(_artworks[artworkId].status == expectedStatus, "Artwork is not in the expected status");
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        galleryCommissionRateBasisPoints = 500; // Default 5%
        minCommunityVotesForCuratorReview = 10; // Default 10 votes
    }

    // --- Custom Gallery Logic Functions ---

    /**
     * @dev Allows an artist to submit a new artwork for curation.
     * Mints a new NFT and sets its status to PendingCommunityVote.
     * @param tokenURI The metadata URI for the artwork.
     */
    function submitArtwork(string memory tokenURI) public {
        _artworkIds.increment();
        uint256 newArtworkId = _artworkIds.current();
        address artist = msg.sender;

        _mint(artist, newArtworkId);
        _artworks[newArtworkId] = Artwork({
            artist: artist,
            tokenURI: tokenURI,
            status: ArtworkStatus.PendingCommunityVote,
            creationTimestamp: block.timestamp
        });
        _artistArtworks[artist].push(newArtworkId);

        emit ArtworkSubmitted(newArtworkId, artist, tokenURI);
        emit ArtworkStatusUpdated(newArtworkId, ArtworkStatus.PendingSubmission, ArtworkStatus.PendingCommunityVote);
    }

    /**
     * @dev Allows any user to cast a vote for an artwork in the PendingCommunityVote state.
     * An address can only vote once per artwork.
     * If vote threshold is reached, status transitions to PendingCuratorApproval.
     * @param artworkId The ID of the artwork to vote for.
     */
    function voteForArtwork(uint256 artworkId) public {
        Artwork storage artwork = _artworks[artworkId];
        require(artwork.artist != address(0), "Artwork does not exist");
        require(artwork.status == ArtworkStatus.PendingCommunityVote, "Artwork is not awaiting community votes");
        require(!_artworkVotes[artworkId][msg.sender], "Already voted for this artwork");

        _artworkVotes[artworkId][msg.sender] = true;
        _artworkVoteCounts[artworkId]++;

        emit VoteCast(artworkId, msg.sender);

        if (_artworkVoteCounts[artworkId] >= minCommunityVotesForCuratorReview) {
            artwork.status = ArtworkStatus.PendingCuratorApproval;
            emit ArtworkStatusUpdated(artworkId, ArtworkStatus.PendingCommunityVote, ArtworkStatus.PendingCuratorApproval);
        }
    }

    /**
     * @dev Allows a curator to approve an artwork in the PendingCuratorApproval state.
     * Sets status to Approved.
     * @param artworkId The ID of the artwork to approve.
     */
    function approveArtwork(uint256 artworkId) public onlyCurator {
        Artwork storage artwork = _artworks[artworkId];
        require(artwork.artist != address(0), "Artwork does not exist");
        require(artwork.status == ArtworkStatus.PendingCuratorApproval, "Artwork is not awaiting curator approval");

        artwork.status = ArtworkStatus.Approved;

        emit ArtworkApproved(artworkId, msg.sender);
        emit ArtworkStatusUpdated(artworkId, ArtworkStatus.PendingCuratorApproval, ArtworkStatus.Approved);
    }

    /**
     * @dev Allows a curator to reject an artwork in the PendingCuratorApproval state.
     * Sets status to Rejected.
     * @param artworkId The ID of the artwork to reject.
     * @param reason The reason for rejection.
     */
    function rejectArtwork(uint256 artworkId, string memory reason) public onlyCurator {
        Artwork storage artwork = _artworks[artworkId];
        require(artwork.artist != address(0), "Artwork does not exist");
        require(artwork.status == ArtworkStatus.PendingCuratorApproval, "Artwork is not awaiting curator approval");

        artwork.status = ArtworkStatus.Rejected;

        emit ArtworkRejected(artworkId, msg.sender, reason);
        emit ArtworkStatusUpdated(artworkId, ArtworkStatus.PendingCuratorApproval, ArtworkStatus.Rejected);
    }

    /**
     * @dev Allows the original artist of a rejected artwork to burn it.
     * @param artworkId The ID of the rejected artwork.
     */
    function withdrawRejectedArtwork(uint256 artworkId) public {
        Artwork storage artwork = _artworks[artworkId];
        require(artwork.artist != address(0), "Artwork does not exist");
        require(artwork.status == ArtworkStatus.Rejected, "Artwork is not in Rejected status");
        require(artwork.artist == msg.sender, "Only the original artist can withdraw rejected artwork");
        require(ownerOf(artworkId) == msg.sender, "Artist must still own the artwork"); // Should be true if rejected

        _burn(artworkId);
        // Optionally clear artwork data or mark as burned
        // For simplicity, we leave the struct data but artwork no longer exists as token
    }

    /**
     * @dev Allows the artwork owner to list an approved artwork for direct sale.
     * @param artworkId The ID of the artwork to list.
     * @param price The price in Wei.
     */
    function listArtworkForDirectSale(uint256 artworkId, uint256 price) public onlyArtworkOwner(artworkId) whenArtworkInStatus(artworkId, ArtworkStatus.Approved) {
        require(price > 0, "Price must be positive");
        _directSalePrices[artworkId] = price;
        _artworks[artworkId].status = ArtworkStatus.ListedForSale;

        emit ArtworkListedForSale(artworkId, price);
        emit ArtworkStatusUpdated(artworkId, ArtworkStatus.Approved, ArtworkStatus.ListedForSale);
    }

    /**
     * @dev Allows the artwork owner to update the price of an artwork listed for direct sale.
     * @param artworkId The ID of the artwork.
     * @param newPrice The new price in Wei.
     */
    function updateDirectSalePrice(uint256 artworkId, uint256 newPrice) public onlyArtworkOwner(artworkId) whenArtworkInStatus(artworkId, ArtworkStatus.ListedForSale) {
        require(newPrice > 0, "Price must be positive");
        _directSalePrices[artworkId] = newPrice;

        emit ArtworkSalePriceUpdated(artworkId, newPrice);
    }

    /**
     * @dev Allows the artwork owner to cancel a direct sale listing.
     * @param artworkId The ID of the artwork.
     */
    function cancelDirectSale(uint256 artworkId) public onlyArtworkOwner(artworkId) whenArtworkInStatus(artworkId, ArtworkStatus.ListedForSale) {
        delete _directSalePrices[artworkId];
        _artworks[artworkId].status = ArtworkStatus.Approved;

        emit ArtworkSaleCancelled(artworkId);
        emit ArtworkStatusUpdated(artworkId, ArtworkStatus.ListedForSale, ArtworkStatus.Approved);
    }

    /**
     * @dev Allows a buyer to purchase an artwork listed for direct sale.
     * Requires sending the exact ETH price. Handles transfer, commission, and payouts.
     * @param artworkId The ID of the artwork to purchase.
     */
    function purchaseArtwork(uint256 artworkId) public payable nonReentrant {
        Artwork storage artwork = _artworks[artworkId];
        require(artwork.artist != address(0), "Artwork does not exist"); // Ensure artwork exists
        require(artwork.status == ArtworkStatus.ListedForSale, "Artwork is not listed for sale");

        uint256 price = _directSalePrices[artworkId];
        require(msg.value == price, "Incorrect ETH amount sent");

        address seller = ownerOf(artworkId);
        require(seller != address(0), "Artwork has no owner");

        // Calculate commission and payout
        uint256 commissionAmount = price.mul(galleryCommissionRateBasisPoints).div(10000);
        uint256 artistPayout = price.sub(commissionAmount);

        // Transfer ownership first
        _safeTransfer(seller, msg.sender, artworkId);

        // Update balances
        _artistBalances[seller] = _artistBalances[seller].add(artistPayout);
        _galleryBalance = _galleryBalance.add(commissionAmount);

        // Clean up listing data
        delete _directSalePrices[artworkId];
        artwork.status = ArtworkStatus.Sold; // Mark as sold

        emit ArtworkPurchased(artworkId, msg.sender, price);
        emit ArtworkStatusUpdated(artworkId, ArtworkStatus.ListedForSale, ArtworkStatus.Sold);
    }

    /**
     * @dev Allows the artwork owner to list an approved artwork for auction.
     * @param artworkId The ID of the artwork.
     * @param reservePrice The minimum price for the auction to be successful.
     * @param duration The duration of the auction in seconds.
     */
    function listArtworkForAuction(uint256 artworkId, uint256 reservePrice, uint256 duration) public onlyArtworkOwner(artworkId) whenArtworkInStatus(artworkId, ArtworkStatus.Approved) {
        require(reservePrice > 0, "Reserve price must be positive");
        require(duration > 0, "Duration must be positive");
        require(duration <= 30 days, "Auction duration too long"); // Example limit

        _artworkAuctions[artworkId] = Auction({
            artworkId: artworkId,
            reservePrice: reservePrice,
            startTime: block.timestamp,
            endTime: block.timestamp + duration,
            highestBidder: address(0),
            highestBid: 0,
            ended: false,
            seller: payable(msg.sender)
        });

        _artworks[artworkId].status = ArtworkStatus.ListedForAuction;

        emit ArtworkListedForAuction(artworkId, reservePrice, duration);
        emit ArtworkStatusUpdated(artworkId, ArtworkStatus.Approved, ArtworkStatus.ListedForAuction);
    }

    /**
     * @dev Allows a user to place a bid on an active auction.
     * @param artworkId The ID of the artwork auction.
     */
    function placeBid(uint256 artworkId) public payable nonReentrant {
        Auction storage auction = _artworkAuctions[artworkId];
        require(_artworks[artworkId].status == ArtworkStatus.ListedForAuction, "Artwork is not listed for auction");
        require(auction.artworkId == artworkId, "Auction does not exist for this artwork"); // Ensure auction struct exists
        require(block.timestamp < auction.endTime, "Auction has already ended");
        require(msg.sender != auction.seller, "Seller cannot bid on their own auction");

        // Return previous highest bid if it exists
        if (auction.highestBidder != address(0)) {
            _pendingReturns[auction.highestBidder] = _pendingReturns[auction.highestBidder].add(auction.highestBid);
        }

        // Check new bid amount
        uint256 currentMinBid = (auction.highestBid == 0) ? auction.reservePrice : auction.highestBid.add(1); // Minimum bid increment of 1 Wei
        require(msg.value >= currentMinBid, "Bid must be higher than current highest bid or reserve price");

        // Update auction state
        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;

        emit NewBid(artworkId, msg.sender, msg.value);
    }

    /**
     * @dev Allows anyone to settle an auction after it has ended.
     * Transfers ownership, calculates commission, and updates payout balances if there was a successful bid.
     * @param artworkId The ID of the artwork auction to settle.
     */
    function settleAuction(uint256 artworkId) public nonReentrant {
        Auction storage auction = _artworkAuctions[artworkId];
        require(_artworks[artworkId].status == ArtworkStatus.ListedForAuction, "Artwork is not listed for auction");
        require(auction.artworkId == artworkId, "Auction does not exist for this artwork");
        require(block.timestamp >= auction.endTime, "Auction has not yet ended");
        require(!auction.ended, "Auction already settled");

        auction.ended = true; // Prevent double settlement

        emit AuctionStatusUpdated(artworkId, AuctionStatus.ListedForAuction, ArtworkStatus.Sold); // Assume sold if settled

        if (auction.highestBidder == address(0) || auction.highestBid < auction.reservePrice) {
            // No successful bid or reserve not met
            _artworks[artworkId].status = ArtworkStatus.Approved; // Return to approved state
            emit AuctionCancelled(artworkId, "No successful bid or reserve not met");
             emit ArtworkStatusUpdated(artworkId, ArtworkStatus.ListedForAuction, ArtworkStatus.Approved);
        } else {
            // Successful bid
            address seller = auction.seller;
            address winner = auction.highestBidder;
            uint256 finalPrice = auction.highestBid;

            // Transfer ownership
            _safeTransfer(seller, winner, artworkId);

            // Calculate commission and payout
            uint256 commissionAmount = finalPrice.mul(galleryCommissionRateBasisPoints).div(10000);
            uint256 artistPayout = finalPrice.sub(commissionAmount);

            // Update balances
            _artistBalances[seller] = _artistBalances[seller].add(artistPayout);
            _galleryBalance = _galleryBalance.add(commissionAmount);

            emit AuctionSettled(artworkId, winner, finalPrice);
        }

        // Clean up auction data (optional: might keep for history)
        // delete _artworkAuctions[artworkId]; // Decide if history is needed on-chain
    }

     /**
     * @dev Allows the owner to cancel an auction *before* the first bid is placed.
     * @param artworkId The ID of the artwork auction.
     */
    function cancelAuctionListing(uint256 artworkId) public onlyArtworkOwner(artworkId) whenArtworkInStatus(artworkId, ArtworkStatus.ListedForAuction) {
        Auction storage auction = _artworkAuctions[artworkId];
        require(auction.artworkId == artworkId, "Auction does not exist for this artwork");
        require(auction.highestBidder == address(0), "Cannot cancel auction after a bid is placed");
        require(!auction.ended, "Auction has already ended");

        _artworks[artworkId].status = ArtworkStatus.Approved; // Return to approved state

        // Clean up auction data
        delete _artworkAuctions[artworkId];

        emit AuctionCancelled(artworkId, "Cancelled by owner before bid");
        emit ArtworkStatusUpdated(artworkId, ArtworkStatus.ListedForAuction, ArtworkStatus.Approved);
    }


    /**
     * @dev Allows a user to like an artwork. Tracks unique likes per user.
     * @param artworkId The ID of the artwork to like.
     */
    function likeArtwork(uint256 artworkId) public {
        Artwork storage artwork = _artworks[artworkId];
        require(artwork.artist != address(0), "Artwork does not exist"); // Ensure artwork exists
        require(!_artworkLikes[artworkId][msg.sender], "Already liked this artwork");

        _artworkLikes[artworkId][msg.sender] = true;
        _artworkLikeCounts[artworkId]++;

        emit ArtworkLiked(artworkId, msg.sender);
    }

    /**
     * @dev Allows a user to remove their like from an artwork.
     * @param artworkId The ID of the artwork to unlike.
     */
    function unlikeArtwork(uint256 artworkId) public {
        Artwork storage artwork = _artworks[artworkId];
        require(artwork.artist != address(0), "Artwork does not exist"); // Ensure artwork exists
        require(_artworkLikes[artworkId][msg.sender], "Have not liked this artwork");

        _artworkLikes[artworkId][msg.sender] = false; // Mark as false
        _artworkLikeCounts[artworkId] = _artworkLikeCounts[artworkId].sub(1); // Decrement safely

        emit ArtworkUnliked(artworkId, msg.sender);
    }

    /**
     * @dev Allows a user (artist) to withdraw their accumulated balance from sales.
     */
    function withdrawArtistProceeds() public nonReentrant {
        uint256 amount = _artistBalances[msg.sender];
        require(amount > 0, "No balance to withdraw");

        _artistBalances[msg.sender] = 0; // Reset balance before sending

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit ArtistProceedsWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Allows the contract owner to withdraw the accumulated gallery commission.
     */
    function withdrawGalleryCommission() public onlyOwner nonReentrant {
        uint256 amount = _galleryBalance;
        require(amount > 0, "No gallery commission to withdraw");

        _galleryBalance = 0; // Reset balance before sending

        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit GalleryCommissionWithdrawn(amount);
    }

    /**
     * @dev Allows a bidder to withdraw ETH from failed bids or bids on settled auctions where they weren't the winner.
     */
     function withdrawPendingReturns() public nonReentrant {
        uint256 amount = _pendingReturns[msg.sender];
        require(amount > 0, "No pending returns to withdraw");

        _pendingReturns[msg.sender] = 0; // Reset balance

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");
    }

    /**
     * @dev Allows the owner to add a new curator.
     * @param curatorAddress The address to add as a curator.
     */
    function addCurator(address curatorAddress) public onlyOwner {
        require(curatorAddress != address(0), "Invalid address");
        require(!_curators[curatorAddress], "Address is already a curator");
        _curators[curatorAddress] = true;
        emit CuratorAdded(curatorAddress);
    }

    /**
     * @dev Allows the owner to remove a curator.
     * @param curatorAddress The address to remove as a curator.
     */
    function removeCurator(address curatorAddress) public onlyOwner {
        require(curatorAddress != address(0), "Invalid address");
        require(_curators[curatorAddress], "Address is not a curator");
        _curators[curatorAddress] = false;
        emit CuratorRemoved(curatorAddress);
    }

    /**
     * @dev Allows the owner to set the gallery commission rate.
     * @param rate The new rate in basis points (e.g., 500 for 5%). Max 10000 (100%).
     */
    function setCommissionRate(uint256 rate) public onlyOwner {
        require(rate <= 10000, "Rate cannot exceed 10000 basis points (100%)");
        galleryCommissionRateBasisPoints = rate;
        emit CommissionRateUpdated(rate);
    }

    /**
     * @dev Allows the owner to set the minimum vote thresholds for curation.
     * @param submissionThreshold The minimum community votes required to move from PendingCommunityVote to PendingCuratorApproval.
     * @param curatorApprovalThreshold Not used in current logic, but reserved for future multi-threshold models.
     */
    function setMinVoteThresholds(uint256 submissionThreshold, uint256 curatorApprovalThreshold) public onlyOwner {
        // curatorApprovalThreshold param is currently unused in the logic but kept for interface consistency
        minCommunityVotesForCuratorReview = submissionThreshold;
        emit VoteThresholdsUpdated(submissionThreshold, curatorApprovalThreshold);
    }

    // --- View Functions (Custom) ---

    /**
     * @dev Gets detailed information about an artwork.
     * @param artworkId The ID of the artwork.
     * @return artwork data struct.
     */
    function getArtworkDetails(uint256 artworkId) public view returns (Artwork memory) {
         require(_artworks[artworkId].artist != address(0), "Artwork does not exist");
        return _artworks[artworkId];
    }

    /**
     * @dev Gets the current community vote count for an artwork.
     * @param artworkId The ID of the artwork.
     * @return The vote count.
     */
    function getArtworkVotes(uint256 artworkId) public view returns (uint256) {
         require(_artworks[artworkId].artist != address(0), "Artwork does not exist");
        return _artworkVoteCounts[artworkId];
    }

    /**
     * @dev Gets the current like count for an artwork.
     * @param artworkId The ID of the artwork.
     * @return The like count.
     */
    function getArtworkLikes(uint256 artworkId) public view returns (uint256) {
         require(_artworks[artworkId].artist != address(0), "Artwork does not exist");
        return _artworkLikeCounts[artworkId];
    }

    /**
     * @dev Gets a list of artwork IDs associated with a specific artist.
     * @param artist The address of the artist.
     * @return An array of artwork IDs.
     */
    function getArtistArtworks(address artist) public view returns (uint256[] memory) {
        return _artistArtworks[artist];
    }

    /**
     * @dev Checks if an address is currently an approved curator.
     * @param account The address to check.
     * @return True if the address is a curator, false otherwise.
     */
    function isCurator(address account) public view returns (bool) {
        return _curators[account];
    }

    /**
     * @dev Gets the current details for an active auction.
     * Returns zero values if no active auction exists for the ID.
     * @param artworkId The ID of the artwork.
     * @return Auction struct details.
     */
    function getAuctionDetails(uint256 artworkId) public view returns (Auction memory) {
         require(_artworks[artworkId].artist != address(0), "Artwork does not exist");
         require(_artworks[artworkId].status == ArtworkStatus.ListedForAuction || _artworks[artworkId].status == ArtworkStatus.Sold, "Artwork is not in an auction state"); // Can view after settled
        return _artworkAuctions[artworkId];
    }

    /**
     * @dev Gets the direct sale price for an artwork if listed.
     * Returns 0 if not listed for direct sale.
     * @param artworkId The ID of the artwork.
     * @return The price in Wei.
     */
    function getDirectSalePrice(uint256 artworkId) public view returns (uint256) {
         require(_artworks[artworkId].artist != address(0), "Artwork does not exist");
         require(_artworks[artworkId].status == ArtworkStatus.ListedForSale, "Artwork is not listed for direct sale");
        return _directSalePrices[artworkId];
    }

     /**
     * @dev Gets the current status of an artwork.
     * @param artworkId The ID of the artwork.
     * @return The ArtworkStatus enum value.
     */
    function getArtworkStatus(uint256 artworkId) public view returns (ArtworkStatus) {
        require(_artworks[artworkId].artist != address(0), "Artwork does not exist");
        return _artworks[artworkId].status;
    }


    /**
     * @dev Gets the total accumulated gallery commission balance.
     * @return The balance in Wei.
     */
    function getGalleryBalance() public view returns (uint256) {
        return _galleryBalance;
    }

    /**
     * @dev Gets the current pending ETH balance for an artist from sales proceeds.
     * @param artist The address of the artist.
     * @return The balance in Wei.
     */
     function getArtistBalance(address artist) public view returns (uint256) {
         return _artistBalances[artist];
     }

    /**
     * @dev Gets the total number of artworks minted in the gallery.
     * @return The total count.
     */
    function getTotalArtworks() public view returns (uint256) {
        return _artworkIds.current();
    }


    // --- Override ERC721Enumerable internal functions ---

    // The following are overrides of internal functions from ERC721Enumerable
    // and ERC721 for proper state management within this contract's logic.
    // They are necessary for the Enumerable extension and standard operations
    // to interact correctly with our custom status tracking.

    function _update(address to, uint256 tokenId, address auth) internal virtual override(ERC721, ERC721Enumerable) returns (address) {
        // Add custom logic if needed around transfers affecting gallery state
        // For now, just call parent method
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal virtual override(ERC721, ERC721Enumerable) {
        // Add custom logic if needed around balance changes
        // For now, just call parent method
        super._increaseBalance(account, value);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        // Custom logic is handled in submitArtwork before calling _mint
        super._safeMint(to, tokenId);
    }

    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual override(ERC721, ERC721Enumerable) {
         // Custom logic is handled in submitArtwork before calling _mint
        super._safeMint(to, tokenId, data);
    }

    function _mint(address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
         // Custom logic is handled in submitArtwork before calling _mint
        super._mint(to, tokenId);
    }


    // The following functions are standard ERC721/Enumerable views,
    // implemented by inheritance but listed here for completeness of available interaction.
    // These are NOT counted in the 20+ *custom logic* functions requested.

    // function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool)
    // function tokenOfOwnerByIndex(address owner, uint256 index) public view override(ERC721Enumerable) returns (uint256)
    // function tokenByIndex(uint256 index) public view override(ERC721Enumerable) returns (uint256)
    // function totalSupply() public view override(ERC721Enumerable) returns (uint256)
    // function ownerOf(uint256 tokenId) public view override(ERC721) returns (address owner)
    // function balanceOf(address owner) public view override(ERC721) returns (uint256 balance)
    // function approve(address to, uint256 tokenId) public override(ERC721)
    // function getApproved(uint256 tokenId) public view override(ERC721) returns (address operator)
    // function setApprovalForAll(address operator, bool approved) public override(ERC721)
    // function isApprovedForAll(address owner, address operator) public view override(ERC721) returns (bool)
    // function transferFrom(address from, address to, uint256 tokenId) public override(ERC721)
    // function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721)
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721)

}
```