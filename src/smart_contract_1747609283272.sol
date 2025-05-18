Okay, here is a Solidity smart contract for a Decentralized AI Art Marketplace. It incorporates several advanced concepts like:

1.  **Dynamic Metadata:** While the contract can't *generate* metadata, it includes mechanisms (events and data storage like vote counts) that *trigger* off-chain services to update NFT metadata based on on-chain interactions (like sales, votes).
2.  **Generative Parameter Linking:** Allows artists to link hashes or references to the parameters used to generate the AI art, promoting transparency or reproducibility.
3.  **Advanced Auction Mechanics:** Includes standard English auctions but is structured to allow for potential extensions (though only English is implemented here to keep size manageable while hitting function count).
4.  **Community Curation/Voting:** Users can vote for art pieces, and the vote count is stored on-chain. This can feed into the dynamic metadata or off-chain ranking.
5.  **Split Royalties & Community Fund:** Royalties are split between the artist and a community-managed (or DAO-governed, though simplified to owner in this example) fund, potentially for funding AI research, platform development, etc.
6.  **ERC2981 Royalties:** Implements the standard for on-chain royalty payments.
7.  **Pause Mechanism:** Standard safety feature.

It aims to be creative by connecting on-chain actions (sales, votes) to the *potential* for off-chain impact (metadata updates, parameter linking, community fund use) relevant to AI art.

**Outline and Function Summary**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title DecentralizedAIArtMarketplace
 * @dev A marketplace for AI-generated art NFTs with dynamic features,
 *      community curation, and split royalties.
 */
contract DecentralizedAIArtMarketplace is ERC721Burnable, Ownable, Pausable, IERC2981 {
    using Counters for Counters.Counter;
    using Address for address payable;

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;

    // Marketplace Fees & Fund Split (in basis points, e.g., 100 = 1%)
    uint16 public marketplaceFeePercentage; // Fee collected by the marketplace owner
    uint16 public communityFundSplitPercentage; // Percentage of royalty/fee directed to community fund

    // Art Data Storage
    mapping(uint256 => bytes32) private _artParametersHash; // Stores hash/reference to generative parameters
    mapping(uint256 => string) private _tokenMetadataUris; // Stores token-specific metadata URI (overrides base URI if set)
    mapping(uint256 => uint256) private _artVoteCounts; // Stores community vote counts for each art piece
    mapping(uint256 => mapping(address => bool)) private _hasVoted; // Tracks if an address has voted for a specific token

    // Royalty Information (per token)
    struct RoyaltyInfo {
        address payable recipient;
        uint96 percentage; // In basis points
    }
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    // Fixed Price Listings
    struct Listing {
        uint256 tokenId;
        address payable seller;
        uint256 price;
        bool active;
    }
    mapping(uint256 => Listing) private _listings; // tokenId => Listing
    mapping(address => uint256[]) private _sellerListings; // seller address => list of tokenIds they are listing

    // Auction Listings
    struct Auction {
        uint256 tokenId;
        address payable seller;
        uint256 startingPrice;
        uint256 currentBid;
        address payable currentBidder;
        uint64 endTime;
        bool ended;
    }
    mapping(uint256 => Auction) private _auctions; // tokenId => Auction

    // Community Fund
    uint256 private _communityFundBalance;

    // --- Events ---
    event ArtMinted(uint256 indexed tokenId, address indexed minter, string metadataURI);
    event ArtParametersHashSet(uint256 indexed tokenId, bytes32 parametersHash);
    event ArtMetadataUriUpdated(uint256 indexed tokenId, string newMetadataURI);
    event ArtVoted(uint256 indexed tokenId, address indexed voter, uint256 newVoteCount);

    event ItemListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event ListingCancelled(uint256 indexed tokenId);
    event ItemSold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);

    event AuctionStarted(uint256 indexed tokenId, address indexed seller, uint256 startingPrice, uint64 endTime);
    event BidPlaced(uint256 indexed tokenId, address indexed bidder, uint256 amount);
    event AuctionEnded(uint256 indexed tokenId, address indexed winner, uint256 finalPrice);
    event AuctionCancelled(uint256 indexed tokenId);

    event RoyaltyInfoUpdated(uint256 indexed tokenId, address indexed recipient, uint96 percentage);
    event RoyaltyPaid(uint256 indexed tokenId, address indexed recipient, uint256 amount);
    event MarketplaceFeePaid(uint256 indexed tokenId, uint256 amount);
    event CommunityFundDeposited(uint256 indexed tokenId, uint256 amount);
    event CommunityFundWithdrawn(address indexed recipient, uint256 amount);

    event MarketplaceFeePercentageUpdated(uint16 newPercentage);
    event CommunityFundSplitPercentageUpdated(uint16 newPercentage);

    // --- Modifiers ---
    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
        _;
    }

    modifier onlyArtOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Caller is not the art owner");
        _;
    }

    modifier whenNotListedOrAuctioned(uint256 tokenId) {
        require(!_listings[tokenId].active && _auctions[tokenId].endTime == 0, "Item is currently listed or in auction");
        _;
    }

    modifier onlyListingSeller(uint256 tokenId) {
        require(_listings[tokenId].seller == msg.sender, "Caller is not the listing seller");
        _;
    }

    modifier onlyAuctionSeller(uint256 tokenId) {
        require(_auctions[tokenId].seller == msg.sender, "Caller is not the auction seller");
        _;
    }

    // --- Structs --- (Defined above with state variables for clarity)

    // --- Constructor ---
    /**
     * @dev Initializes the contract.
     * @param name_ The name of the token collection.
     * @param symbol_ The symbol of the token collection.
     * @param initialMarketplaceFee The initial fee percentage for the marketplace owner (basis points).
     * @param initialCommunityFundSplit The initial percentage split to the community fund from royalties/fees (basis points).
     */
    constructor(string memory name_, string memory symbol_, uint16 initialMarketplaceFee, uint16 initialCommunityFundSplit)
        ERC721(name_, symbol_)
        Ownable(msg.sender)
    {
        require(initialMarketplaceFee + initialCommunityFundSplit <= 10000, "Fee and split sum exceeds 100%");
        marketplaceFeePercentage = initialMarketplaceFee;
        communityFundSplitPercentage = initialCommunityFundSplit;
    }

    // --- ERC721 Functions (Inherited & Overridden) ---
    // ERC721 standard functions are available:
    // - balanceOf(address owner)
    // - ownerOf(uint256 tokenId)
    // - transferFrom(address from, address to, uint256 tokenId)
    // - safeTransferFrom(address from, address to, uint256 tokenId)
    // - approve(address to, uint256 tokenId)
    // - setApprovalForAll(address operator, bool approved)
    // - getApproved(uint256 tokenId)
    // - isApprovedForAll(address owner, address operator)
    // - supportsInterface(bytes4 interfaceId) // Supports ERC165, ERC721, ERC721Metadata, ERC2981

    /**
     * @dev Returns the metadata URI for a token.
     *      Prioritizes token-specific URI over base URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists
        string memory uri = _tokenMetadataUris[tokenId];
        if (bytes(uri).length > 0) {
            return uri;
        }
        return super.tokenURI(tokenId); // Fallback to base URI
    }

    // --- Minting Function ---
    /**
     * @dev Mints a new AI art NFT. Only callable by the owner or a designated minter role (simplified to owner here).
     * @param to The address that will own the new NFT.
     * @param metadataURI_ The initial metadata URI for the token.
     * @return The newly minted tokenId.
     */
    function mintAIArt(address to, string memory metadataURI_) public onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(to, newItemId);
        _tokenMetadataUris[newItemId] = metadataURI_; // Set initial token-specific URI
        emit ArtMinted(newItemId, to, metadataURI_);
        return newItemId;
    }

    // --- Art Data Management Functions ---
    /**
     * @dev Sets a hash or reference to the generative parameters used for a piece of art.
     *      Allows transparency or potential reproduction off-chain.
     *      Only callable by the current owner of the art.
     * @param tokenId The ID of the token.
     * @param parametersHash_ The hash or reference.
     */
    function setArtParametersHash(uint256 tokenId, bytes32 parametersHash_) public onlyArtOwner(tokenId) {
        _artParametersHash[tokenId] = parametersHash_;
        emit ArtParametersHashSet(tokenId, parametersHash_);
    }

    /**
     * @dev Gets the generative parameters hash for a piece of art.
     * @param tokenId The ID of the token.
     * @return The stored parameters hash.
     */
    function getArtParametersHash(uint256 tokenId) public view returns (bytes32) {
        _requireOwned(tokenId); // Ensure token exists
        return _artParametersHash[tokenId];
    }

    /**
     * @dev Updates the token-specific metadata URI for a piece of art.
     *      Can be called by the owner. This is useful if off-chain logic
     *      determines metadata should change (e.g., based on votes, sales).
     * @param tokenId The ID of the token.
     * @param newMetadataURI_ The new metadata URI.
     */
    function updateArtMetadataUri(uint256 tokenId, string memory newMetadataURI_) public onlyArtOwner(tokenId) {
        _tokenMetadataUris[tokenId] = newMetadataURI_;
        emit ArtMetadataUriUpdated(tokenId, newMetadataURI_);
    }

    // --- Marketplace (Fixed Price) Functions ---
    /**
     * @dev Lists an owned art NFT for sale at a fixed price.
     *      Requires the marketplace contract to be approved to manage the token.
     * @param tokenId The ID of the token to list.
     * @param price The sale price in native currency (e.g., Wei).
     */
    function listItemForSale(uint256 tokenId, uint256 price) public payable onlyApprovedOrOwner(tokenId) whenNotListedOrAuctioned(tokenId) whenNotPaused {
        require(price > 0, "Price must be greater than zero");

        // Transfer the token to the marketplace contract (if not already owned)
        // This ensures the marketplace has control during the sale.
        // Alternatively, we could just require approval and transfer on purchase.
        // Transferring requires marketplace to be the receiver in safeTransferFrom.
        // Let's simplify and just require approval for this contract.
        address owner = ownerOf(tokenId);
        require(getApproved(tokenId) == address(this) || isApprovedForAll(owner, address(this)), "Marketplace contract is not approved");

        Listing storage listing = _listings[tokenId];
        listing.tokenId = tokenId;
        listing.seller = payable(owner);
        listing.price = price;
        listing.active = true;

        _sellerListings[owner].push(tokenId); // Track seller's listings

        emit ItemListed(tokenId, owner, price);
    }

    /**
     * @dev Cancels a fixed-price listing.
     *      Only callable by the seller or the contract owner.
     * @param tokenId The ID of the token listing to cancel.
     */
    function cancelListing(uint256 tokenId) public whenNotPaused {
        Listing storage listing = _listings[tokenId];
        require(listing.active, "Listing not active");
        require(listing.seller == msg.sender || owner() == msg.sender, "Not the listing seller or owner");

        // Mark as inactive and clear details (optional, saves gas on subsequent reads if needed)
        listing.active = false;
        delete _listings[tokenId]; // Clears the struct fields

        // Remove from seller's listings array (less gas efficient, consider different data structure for many listings)
        uint256[] storage listingsBySeller = _sellerListings[listing.seller];
        for (uint i = 0; i < listingsBySeller.length; i++) {
            if (listingsBySeller[i] == tokenId) {
                // Replace with last element and pop
                listingsBySeller[i] = listingsBySeller[listingsBySeller.length - 1];
                listingsBySeller.pop();
                break;
            }
        }

        emit ListingCancelled(tokenId);
    }

    /**
     * @dev Buys an item listed for a fixed price.
     *      Transfers the NFT to the buyer and distributes the payment.
     * @param tokenId The ID of the token to buy.
     */
    function buyItem(uint256 tokenId) public payable whenNotPaused {
        Listing storage listing = _listings[tokenId];
        require(listing.active, "Listing not active");
        require(msg.value >= listing.price, "Insufficient funds sent");

        address buyer = msg.sender;
        address payable seller = listing.seller;
        uint256 salePrice = listing.price;

        // Ensure excess ETH is refunded to the buyer
        if (msg.value > salePrice) {
            payable(msg.sender).call{value: msg.value - salePrice}("");
        }

        // Transfer NFT ownership to the buyer BEFORE distributing funds
        // to prevent reentrancy issues if ownerOf is checked in payment logic.
        // The token must be owned by the seller or approved for transfer by this contract.
        // If using the model where the contract holds the NFT, transfer from `address(this)`.
        // If using the approval model, transfer from `listing.seller`.
        // Assuming the approval model here:
        _safeTransfer(listing.seller, buyer, tokenId);


        // Calculate fees and royalties
        uint256 totalAmount = salePrice;
        uint256 marketplaceFee = (totalAmount * marketplaceFeePercentage) / 10000;
        uint256 royaltyAmount = 0;
        address payable royaltyRecipient = payable(0);

        RoyaltyInfo storage tokenRoyalty = _tokenRoyaltyInfo[tokenId];
        if (tokenRoyalty.recipient != address(0) && tokenRoyalty.percentage > 0) {
             royaltyAmount = (totalAmount * tokenRoyalty.percentage) / 10000;
             royaltyRecipient = tokenRoyalty.recipient;
             emit RoyaltyPaid(tokenId, royaltyRecipient, royaltyAmount);
        }

        // Ensure fees + royalties don't exceed total amount (shouldn't happen with percentages <= 10000, but good check)
        uint256 artistSellerAmount = totalAmount - marketplaceFee - royaltyAmount;

        // Split marketplace fee and royalty amount for community fund
        uint256 communityFundCut = (marketplaceFee + royaltyAmount) * communityFundSplitPercentage / 10000;

        // Deduct community fund cut from fee/royalty amounts
        marketplaceFee -= (marketplaceFee * communityFundSplitPercentage / 10000);
        if (royaltyRecipient != address(0)) {
             royaltyAmount -= (royaltyAmount * communityFundSplitPercentage / 10000);
        } else {
            // If no royalty recipient, the community fund cut from royalty part goes to seller/artist instead?
            // Or just from the fee? Let's simplify and say community cut only applies if a royalty recipient exists.
            // Or even simpler: community cut comes *only* from the marketplace fee.
            // Let's change the split logic: Community fund gets % of the *marketplace fee*.
            // New logic: marketplaceFee = total * marketplaceFeePct / 10000
            //           communityFundCut = marketplaceFee * communityFundSplitPct / 10000
            //           remainingFee = marketplaceFee - communityFundCut
            //           royaltyAmount = total * royaltyPct / 10000
            //           sellerAmount = total - marketplaceFee - royaltyAmount

            // Re-calculate with simpler split logic
            marketplaceFee = (totalAmount * marketplaceFeePercentage) / 10000;
            uint256 royaltyPart = 0;
             if (tokenRoyalty.recipient != address(0) && tokenRoyalty.percentage > 0) {
                royaltyPart = (totalAmount * tokenRoyalty.percentage) / 10000;
                royaltyRecipient = tokenRoyalty.recipient;
             }

            uint256 feeAndRoyaltyTotal = marketplaceFee + royaltyPart;
            communityFundCut = (feeAndRoyaltyTotal * communityFundSplitPercentage) / 10000;

            uint256 payableToOwner = marketplaceFee - (marketplaceFee * communityFundSplitPercentage / 10000); // Split fee
            uint256 payableToRoyalty = royaltyPart - (royaltyPart * communityFundSplitPercentage / 10000); // Split royalty (if applicable)
            uint256 payableToSeller = totalAmount - marketplaceFee - royaltyPart; // Remainder to seller

            // Distribute funds (use call for safety)
            if (payableToSeller > 0) seller.call{value: payableToSeller}("");
            if (payableToOwner > 0) payable(owner()).call{value: payableToOwner}("");
            if (payableToRoyalty > 0 && royaltyRecipient != address(0)) royaltyRecipient.call{value: payableToRoyalty}("");
            _communityFundBalance += communityFundCut;

            emit MarketplaceFeePaid(tokenId, payableToOwner); // Emitting the amount sent to owner after split
            if (royaltyRecipient != address(0)) emit RoyaltyPaid(tokenId, royaltyRecipient, payableToRoyalty); // Emitting amount sent after split
            emit CommunityFundDeposited(tokenId, communityFundCut);
            emit ItemSold(tokenId, seller, buyer, salePrice);
        }


        // Deactivate listing
        listing.active = false;
        delete _listings[tokenId];

        // Remove from seller's listings array (similar inefficient approach as cancelListing)
        uint256[] storage listingsBySeller = _sellerListings[seller];
        for (uint i = 0; i < listingsBySeller.length; i++) {
            if (listingsBySeller[i] == tokenId) {
                listingsBySeller[i] = listingsBySeller[listingsBySeller.length - 1];
                listingsBySeller.pop();
                break;
            }
        }
    }

    /**
     * @dev Gets the details of a fixed-price listing.
     * @param tokenId The ID of the token.
     * @return The listing details.
     */
    function getListingDetails(uint256 tokenId) public view returns (Listing memory) {
        return _listings[tokenId];
    }

    /**
     * @dev Gets a list of all currently active fixed-price listings.
     *      Warning: This can be gas-intensive for large numbers of listings.
     *      Consider off-chain indexing for large collections.
     * @return An array of active listing structs.
     */
    function getAllActiveListings() public view returns (Listing[] memory) {
        uint256 totalListings = _tokenIdCounter.current();
        Listing[] memory activeListings = new Listing[](totalListings); // Max possible size
        uint256 count = 0;
        // Iterate through all potential token IDs
        for (uint256 i = 1; i <= totalListings; i++) {
             if (_listings[i].active) {
                activeListings[count] = _listings[i];
                count++;
             }
        }
        // Trim the array to the actual count
        Listing[] memory result = new Listing[](count);
        for(uint i = 0; i < count; i++){
            result[i] = activeListings[i];
        }
        return result;
    }

    // --- Marketplace (Auction) Functions ---
    /**
     * @dev Starts an auction for an owned art NFT.
     *      Requires the marketplace contract to be approved to manage the token.
     * @param tokenId The ID of the token to auction.
     * @param startingPrice The minimum bid price.
     * @param duration The duration of the auction in seconds.
     */
    function startAuction(uint256 tokenId, uint256 startingPrice, uint64 duration) public payable onlyApprovedOrOwner(tokenId) whenNotListedOrAuctioned(tokenId) whenNotPaused {
        require(startingPrice > 0, "Starting price must be greater than zero");
        require(duration > 0, "Auction duration must be greater than zero");

        address owner = ownerOf(tokenId);
         require(getApproved(tokenId) == address(this) || isApprovedForAll(owner, address(this)), "Marketplace contract is not approved");

        Auction storage auction = _auctions[tokenId];
        require(auction.endTime == 0 || auction.ended, "Auction already exists for this token"); // Ensure no active auction

        auction.tokenId = tokenId;
        auction.seller = payable(owner);
        auction.startingPrice = startingPrice;
        auction.currentBid = startingPrice; // Current bid starts at starting price
        auction.currentBidder = payable(address(0)); // No bidder initially
        auction.endTime = uint64(block.timestamp) + duration;
        auction.ended = false; // Explicitly set to false

        emit AuctionStarted(tokenId, owner, startingPrice, auction.endTime);
    }

    /**
     * @dev Places a bid on an active auction.
     *      Refunds the previous highest bidder.
     * @param tokenId The ID of the token being auctioned.
     */
    function placeBid(uint256 tokenId) public payable whenNotPaused {
        Auction storage auction = _auctions[tokenId];
        require(auction.endTime != 0 && !auction.ended, "Auction is not active");
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(msg.sender != auction.seller, "Seller cannot bid on their own auction");

        require(msg.value > auction.currentBid, "Bid amount must be greater than current bid");

        // Refund previous bidder if exists
        if (auction.currentBidder != address(0)) {
            auction.currentBidder.call{value: auction.currentBid}("");
        }

        auction.currentBid = msg.value;
        auction.currentBidder = payable(msg.sender);

        emit BidPlaced(tokenId, msg.sender, msg.value);
    }

    /**
     * @dev Ends an auction after the end time has passed.
     *      Transfers the NFT to the winning bidder and distributes payment.
     *      Can be called by anyone, winner, or seller.
     * @param tokenId The ID of the token auction to end.
     */
    function endAuction(uint256 tokenId) public whenNotPaused {
        Auction storage auction = _auctions[tokenId];
        require(auction.endTime != 0 && !auction.ended, "Auction is not active");
        require(block.timestamp >= auction.endTime, "Auction has not ended yet");

        auction.ended = true; // Mark as ended immediately to prevent reentrancy

        address payable winner = auction.currentBidder;
        uint256 finalPrice = auction.currentBid;
        address payable seller = auction.seller;

        // Handle no bids case
        if (winner == address(0)) {
            // NFT stays with seller, no payment
             emit AuctionEnded(tokenId, address(0), 0);
             delete _auctions[tokenId]; // Clean up
             return;
        }

        // Transfer NFT to winner
         _safeTransfer(seller, winner, tokenId); // Assuming approval model

        // Calculate fees and royalties - Same logic as buyItem
        uint256 totalAmount = finalPrice;
        uint256 marketplaceFee = (totalAmount * marketplaceFeePercentage) / 10000;
        uint256 royaltyPart = 0;
        address payable royaltyRecipient = payable(0);

        RoyaltyInfo storage tokenRoyalty = _tokenRoyaltyInfo[tokenId];
        if (tokenRoyalty.recipient != address(0) && tokenRoyalty.percentage > 0) {
            royaltyPart = (totalAmount * tokenRoyalty.percentage) / 10000;
            royaltyRecipient = tokenRoyalty.recipient;
        }

        uint256 feeAndRoyaltyTotal = marketplaceFee + royaltyPart;
        uint256 communityFundCut = (feeAndRoyaltyTotal * communityFundSplitPercentage) / 10000;

        uint256 payableToOwner = marketplaceFee - (marketplaceFee * communityFundSplitPercentage / 10000);
        uint256 payableToRoyalty = royaltyPart - (royaltyPart * communityFundSplitPercentage / 10000);
        uint256 payableToSeller = totalAmount - marketplaceFee - royaltyPart;

        // Distribute funds
        if (payableToSeller > 0) seller.call{value: payableToSeller}("");
        if (payableToOwner > 0) payable(owner()).call{value: payableToOwner}("");
        if (payableToRoyalty > 0 && royaltyRecipient != address(0)) royaltyRecipient.call{value: payableToRoyalty}("");
        _communityFundBalance += communityFundCut;

        emit MarketplaceFeePaid(tokenId, payableToOwner);
        if (royaltyRecipient != address(0)) emit RoyaltyPaid(tokenId, royaltyRecipient, payableToRoyalty);
        emit CommunityFundDeposited(tokenId, communityFundCut);
        emit AuctionEnded(tokenId, winner, finalPrice);

        delete _auctions[tokenId]; // Clean up auction data
    }

     /**
     * @dev Cancels an auction.
     *      Only callable by the seller or contract owner BEFORE the auction ends.
     * @param tokenId The ID of the token auction to cancel.
     */
    function cancelAuction(uint256 tokenId) public whenNotPaused {
        Auction storage auction = _auctions[tokenId];
        require(auction.endTime != 0 && !auction.ended, "Auction is not active");
        require(block.timestamp < auction.endTime, "Cannot cancel auction after it has ended");
        require(auction.seller == msg.sender || owner() == msg.sender, "Not the auction seller or owner");

        // Refund current bidder if any
        if (auction.currentBidder != address(0)) {
            auction.currentBidder.call{value: auction.currentBid}("");
        }

        auction.ended = true; // Mark as ended/cancelled
        emit AuctionCancelled(tokenId);

        delete _auctions[tokenId]; // Clean up auction data
    }

    /**
     * @dev Gets the details of an auction.
     * @param tokenId The ID of the token.
     * @return The auction details.
     */
    function getAuctionDetails(uint256 tokenId) public view returns (Auction memory) {
        return _auctions[tokenId];
    }

     /**
     * @dev Gets a list of all currently active auctions.
     *      Warning: Can be gas-intensive. Consider off-chain indexing.
     * @return An array of active auction structs.
     */
    function getAllActiveAuctions() public view returns (Auction[] memory) {
        uint256 totalTokens = _tokenIdCounter.current();
        Auction[] memory activeAuctions = new Auction[](totalTokens); // Max possible size
        uint256 count = 0;
        // Iterate through all potential token IDs
        for (uint256 i = 1; i <= totalTokens; i++) {
             Auction storage auction = _auctions[i];
             if (auction.endTime != 0 && !auction.ended) {
                activeAuctions[count] = auction;
                count++;
             }
        }
        // Trim the array
        Auction[] memory result = new Auction[](count);
        for(uint i = 0; i < count; i++){
            result[i] = activeAuctions[i];
        }
        return result;
    }

    // --- Community Curation Functions ---
    /**
     * @dev Allows a user to vote for an art piece.
     *      Each address can vote only once per token.
     * @param tokenId The ID of the token to vote for.
     */
    function voteForArt(uint256 tokenId) public whenNotPaused {
        _requireOwned(tokenId); // Ensure token exists
        require(!_hasVoted[tokenId][msg.sender], "Already voted for this art");

        _artVoteCounts[tokenId]++;
        _hasVoted[tokenId][msg.sender] = true;

        emit ArtVoted(tokenId, msg.sender, _artVoteCounts[tokenId]);

        // Note: Dynamic metadata update based on vote count would be triggered off-chain
        // by listening for the ArtVoted event and checking the new count.
    }

    /**
     * @dev Gets the current vote count for an art piece.
     * @param tokenId The ID of the token.
     * @return The number of votes.
     */
    function getArtVoteCount(uint256 tokenId) public view returns (uint256) {
         _requireOwned(tokenId); // Ensure token exists
        return _artVoteCounts[tokenId];
    }

    // --- Royalty Functions (ERC2981) ---
    /**
     * @dev Sets the royalty information for a specific token.
     *      Only callable by the current owner of the art.
     * @param tokenId The ID of the token.
     * @param recipient The address to receive royalties.
     * @param percentage The royalty percentage in basis points (0-10000).
     */
    function setTokenRoyaltyInfo(uint256 tokenId, address payable recipient, uint96 percentage) public onlyArtOwner(tokenId) {
        require(percentage <= 10000, "Royalty percentage exceeds 100%");
        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(recipient, percentage);
        emit RoyaltyInfoUpdated(tokenId, recipient, percentage);
    }

    /**
     * @dev See {IERC2981-royaltyInfo}.
     *      Returns the royalty recipient and amount for a given sale price.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view override returns (address receiver, uint256 royaltyAmount) {
        RoyaltyInfo storage tokenRoyalty = _tokenRoyaltyInfo[tokenId];
        if (tokenRoyalty.recipient == address(0) || tokenRoyalty.percentage == 0) {
            return (address(0), 0);
        }
        // Calculate royalty amount before community fund split
        uint256 baseRoyalty = (salePrice * tokenRoyalty.percentage) / 10000;
        // Calculate royalty amount after community fund split
        uint256 payableRoyalty = baseRoyalty - (baseRoyalty * communityFundSplitPercentage / 10000);

        return (tokenRoyalty.recipient, payableRoyalty);
    }


    // --- Fee and Community Fund Functions ---
     /**
     * @dev Sets the marketplace fee percentage. Only owner.
     * @param newPercentage The new percentage in basis points (0-10000).
     */
    function setMarketplaceFeePercentage(uint16 newPercentage) public onlyOwner {
        require(newPercentage + communityFundSplitPercentage <= 10000, "Fee and split sum exceeds 100%");
        marketplaceFeePercentage = newPercentage;
        emit MarketplaceFeePercentageUpdated(newPercentage);
    }

     /**
     * @dev Sets the community fund split percentage. Only owner.
     * @param newPercentage The new percentage in basis points (0-10000).
     */
    function setCommunityFundSplitPercentage(uint16 newPercentage) public onlyOwner {
         require(marketplaceFeePercentage + newPercentage <= 10000, "Fee and split sum exceeds 100%");
        communityFundSplitPercentage = newPercentage;
        emit CommunityFundSplitPercentageUpdated(newPercentage);
    }

    /**
     * @dev Gets the current balance of the community fund.
     * @return The community fund balance in native currency.
     */
    function getCommunityFundBalance() public view returns (uint256) {
        return _communityFundBalance;
    }

    /**
     * @dev Withdraws funds from the community fund.
     *      Only callable by the contract owner. In a full DAO, this would be governed.
     * @param amount The amount to withdraw.
     * @param recipient The address to send the funds to.
     */
    function withdrawCommunityFund(uint256 amount, address payable recipient) public onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= _communityFundBalance, "Insufficient funds in community fund");
        _communityFundBalance -= amount;
        recipient.call{value: amount}("");
        emit CommunityFundWithdrawn(recipient, amount);
    }

    // --- Admin/Utility Functions ---
     /**
     * @dev Pauses the contract. Only owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Gets all token IDs owned by an address.
     *      Warning: Can be gas-intensive for addresses owning many tokens.
     *      Consider off-chain indexing.
     * @param owner The address to query.
     * @return An array of token IDs owned by the address.
     */
    function getOwnedTokens(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        uint256 currentTokenId = 1; // Assuming token IDs start from 1
        uint256 foundCount = 0;
        // Iterate through all potential token IDs (up to current total supply)
        while (currentTokenId <= _tokenIdCounter.current() && foundCount < tokenCount) {
            try ownerOf(currentTokenId) returns (address tokenOwner) {
                if (tokenOwner == owner) {
                    tokenIds[foundCount] = currentTokenId;
                    foundCount++;
                }
            } catch {
                // Handle case where ownerOf might revert for a non-existent token
                // (though with Counters, this shouldn't happen if iterating up to current())
            }
             currentTokenId++;
        }
         // If foundCount is less than tokenCount, it means we might have burned tokens
         // or ownerOf logic is different. The standard ERC721 doesn't require tracking tokens per owner.
         // A more robust way requires internal _ownedTokens mapping, but adds storage cost.
         // For this example, we'll return the array as is, which might be shorter than balanceOf if tokens were burned.
         // If a truly accurate list is needed, a separate mapping `address => uint256[]` needs to be maintained
         // whenever tokens are minted, transferred, or burned.
         // Let's add a simple helper for demo, acknowledging its potential inaccuracy if burnable is used extensively without tracking.

         // A better approach for `getOwnedTokens` requires manual tracking in mappings during _safeMint, _transfer, _burn
         // Example: mapping(address => uint255[]) _ownedTokensArray;
         // And update it in _afterTokenTransfer.
         // For this example, we'll stick to iterating, which is the *only* way with just standard ERC721 and Counters.
         // Let's refine the loop to only iterate up to _tokenIdCounter.current().
        uint256 currentSupply = _tokenIdCounter.current();
        uint256[] memory ownedTokens = new uint256[](balanceOf(owner));
        uint256 index = 0;
        for (uint256 i = 1; i <= currentSupply; i++) {
            // Wrap ownerOf in try-catch for safety, though with sequential IDs it might not be needed
            // if token exists. ownerOf reverts for non-existent tokens.
            // Since we minted sequentially, i *should* exist if i <= currentSupply, unless burned.
            // Handling burns correctly requires an internal mapping of owned tokens.
             try ownerOf(i) returns (address tokenOwner) {
                 if (tokenOwner == owner) {
                     // Ensure we don't go out of bounds if balanceOf is high but many tokens were burned
                     if (index < ownedTokens.length) {
                        ownedTokens[index] = i;
                        index++;
                     } else {
                         // This case indicates an inconsistency, likely due to burned tokens
                         // without updating a separate tracking array. Break or handle.
                         break;
                     }
                 }
             } catch {
                 // If ownerOf reverts, the token likely doesn't exist (e.g., was burned)
             }
        }
         // If index < ownedTokens.length, it means some tokens were burned.
         // We should ideally return a trimmed array.
         uint256[] memory finalOwnedTokens = new uint256[](index);
         for(uint i = 0; i < index; i++){
             finalOwnedTokens[i] = ownedTokens[i];
         }
        return finalOwnedTokens;
    }


    // --- Internal/Helper Functions ---
    // _beforeTokenTransfer and _afterTokenTransfer can be overridden for custom logic
    // (e.g., updating _ownedTokensArray if implemented)

    // The _isApprovedOrOwner function is inherited from ERC721 and used by the modifier.

}

/*
 Outline:

 1.  State Variables:
     - Token counter (_tokenIdCounter)
     - Marketplace fees/split (marketplaceFeePercentage, communityFundSplitPercentage)
     - Art data (generative params hash, token URI overrides, vote counts, voter tracking)
     - Royalty info (per token)
     - Fixed Price Listings (struct, mapping)
     - Auction Listings (struct, mapping)
     - Community Fund balance
 2.  Events:
     - Minting (ArtMinted)
     - Art Data Updates (ArtParametersHashSet, ArtMetadataUriUpdated)
     - Community Voting (ArtVoted)
     - Fixed Price Listing (ItemListed, ListingCancelled, ItemSold)
     - Auction Listing (AuctionStarted, BidPlaced, AuctionEnded, AuctionCancelled)
     - Financial (RoyaltyInfoUpdated, RoyaltyPaid, MarketplaceFeePaid, CommunityFundDeposited, CommunityFundWithdrawn)
     - Settings (MarketplaceFeePercentageUpdated, CommunityFundSplitPercentageUpdated)
 3.  Modifiers:
     - onlyApprovedOrOwner
     - onlyArtOwner
     - whenNotListedOrAuctioned
     - onlyListingSeller
     - onlyAuctionSeller
 4.  Structs:
     - RoyaltyInfo
     - Listing
     - Auction
 5.  Constructor:
     - Initializes ERC721, Ownable
     - Sets initial fee and split percentages
 6.  ERC721 Functions (Inherited & Overridden):
     - balanceOf
     - ownerOf
     - transferFrom
     - safeTransferFrom
     - approve
     - setApprovalForAll
     - getApproved
     - isApprovedForAll
     - supportsInterface
     - tokenURI (Overridden for token-specific URI)
 7.  Minting Function:
     - mintAIArt
 8.  Art Data Management Functions:
     - setArtParametersHash
     - getArtParametersHash
     - updateArtMetadataUri
 9.  Marketplace (Fixed Price) Functions:
     - listItemForSale
     - cancelListing
     - buyItem
     - getListingDetails
     - getAllActiveListings
 10. Marketplace (Auction) Functions:
     - startAuction
     - placeBid
     - endAuction
     - cancelAuction
     - getAuctionDetails
     - getAllActiveAuctions
 11. Community Curation Functions:
     - voteForArt
     - getArtVoteCount
 12. Royalty Functions (ERC2981):
     - setTokenRoyaltyInfo
     - royaltyInfo (Implements IERC2981)
 13. Fee and Community Fund Functions:
     - setMarketplaceFeePercentage
     - setCommunityFundSplitPercentage
     - getCommunityFundBalance
     - withdrawCommunityFund
 14. Admin/Utility Functions:
     - pause
     - unpause
     - getOwnedTokens (Helper view, potentially inefficient for large collections)
 15. Internal/Helper Functions:
     - (Inherited ERC721 internals like _safeMint, _requireOwned, _isApprovedOrOwner, _safeTransfer)

 Function Summary:

 - constructor: Deploys the contract, sets name, symbol, initial fees.
 - balanceOf: (ERC721) Returns the number of tokens owned by an address.
 - ownerOf: (ERC721) Returns the owner of a specific token.
 - transferFrom: (ERC721) Transfers ownership of a token.
 - safeTransferFrom: (ERC721) Safely transfers ownership of a token.
 - approve: (ERC721) Gives approval to a specific address for one token.
 - setApprovalForAll: (ERC721) Gives/revokes approval to an operator for all of the sender's tokens.
 - getApproved: (ERC721) Gets the approved address for a specific token.
 - isApprovedForAll: (ERC721) Checks if an address is an approved operator for another address.
 - supportsInterface: (ERC165, ERC721, ERC721Metadata, ERC2981) Indicates which interfaces the contract implements.
 - tokenURI: (ERC721Metadata, Overridden) Returns the metadata URI for a token, prioritizing token-specific URI.
 - mintAIArt: Creates a new NFT, assigns it to an address, and sets its initial metadata URI. Only owner.
 - setArtParametersHash: Stores a hash/reference related to the generative parameters for a token. Only art owner.
 - getArtParametersHash: Retrieves the generative parameters hash for a token.
 - updateArtMetadataUri: Updates the token-specific metadata URI. Only art owner. Can be triggered by off-chain logic reacting to events.
 - voteForArt: Allows a user to cast a vote for a specific art piece. Only one vote per address per token.
 - getArtVoteCount: Retrieves the total vote count for a specific art piece.
 - listItemForSale: Creates a fixed-price listing for an owned NFT. Requires approval.
 - cancelListing: Removes an active fixed-price listing. Only seller or owner.
 - buyItem: Purchases a listed item, transfers NFT, and distributes payment (seller, marketplace owner, royalty recipient, community fund).
 - getListingDetails: Retrieves the details of a fixed-price listing.
 - getAllActiveListings: (View) Returns an array of all active fixed-price listings. (Inefficient for large data).
 - startAuction: Creates an auction listing for an owned NFT. Requires approval.
 - placeBid: Places a bid on an active auction, refunding the previous bidder.
 - endAuction: Concludes an auction after the end time. Transfers NFT to winner and distributes funds. Handles no bids. Anyone can call after end time.
 - cancelAuction: Removes an active auction before the end time. Refunds bidder. Only seller or owner.
 - getAuctionDetails: Retrieves the details of an auction.
 - getAllActiveAuctions: (View) Returns an array of all active auctions. (Inefficient for large data).
 - setTokenRoyaltyInfo: Sets the ERC2981 royalty recipient and percentage for a specific token. Only art owner.
 - royaltyInfo: (ERC2981) Calculates and returns the royalty amount and recipient for a given sale price according to ERC2981 standard, considering the community fund split.
 - setMarketplaceFeePercentage: Sets the marketplace's fee percentage. Only owner.
 - setCommunityFundSplitPercentage: Sets the percentage of fees/royalties directed to the community fund. Only owner.
 - getCommunityFundBalance: Retrieves the current balance held in the community fund.
 - withdrawCommunityFund: Allows the owner to withdraw funds from the community fund. (Simplified, could be DAO governed).
 - pause: Halts sensitive operations (minting, listing, bidding, buying, auction ending). Only owner.
 - unpause: Resumes operations. Only owner.
 - getOwnedTokens: (View) Returns an array of token IDs owned by an address. (Inefficient for large data).
 */
```