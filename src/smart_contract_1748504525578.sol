Okay, let's design an advanced smart contract for a **Decentralized Generative Art Marketplace with On-Chain Parameters and Curator Governance**.

This contract goes beyond simple NFT minting/trading by:
1.  Storing *generation parameters* on-chain, not just a token URI pointing to an external image.
2.  Allowing artists to register *generator* contracts (or logic references) through a curator system.
3.  Implementing both Direct Sale and Auction marketplace mechanisms within the same contract.
4.  Handling ERC2981 royalties *and* platform fees.
5.  Incorporating a Curator role for decentralized (or semi-decentralized) control over adding generators and pausing the marketplace.
6.  Potentially enabling dynamic metadata via the `tokenURI` based on on-chain parameters.

---

**Outline & Function Summary**

**Contract Name:** `GenerativeArtMarketplace`

**Concept:** A marketplace for unique generative art NFTs where the art's parameters are stored on-chain. Features artist-registered generators (approved by a curator), direct sales, auctions, ERC2981 royalties, platform fees, and administrative controls.

**Key Components:**
*   **Generators:** Registered templates/logic for generating art, managed by artists and approved by curators.
*   **Art (Tokens):** ERC721 NFTs, each linked to a specific generator, containing unique on-chain parameters (seed, custom inputs).
*   **Marketplace:** Supports direct 'Buy Now' listings and English Auctions.
*   **Royalties & Fees:** ERC2981 standard royalties for artists + a platform fee.
*   **Governance:** Owner and Curator roles for system management.

**Function Summary (Alphabetical Order):**

1.  `addGenerator(string name, address artist, bytes generationParams)`: Registers a new generative art template/logic identifier. Requires curator/owner approval.
2.  `approve(address to, uint256 tokenId)`: Grants approval for a single token transfer (ERC721 standard).
3.  `balanceOf(address owner)`: Returns the number of tokens owned by an address (ERC721 standard).
4.  `buyArt(uint256 tokenId)`: Allows a user to purchase a listed token at its direct sale price. Handles transfer, royalties, and fees.
5.  `cancelAuction(uint256 tokenId)`: Cancels an ongoing auction if no valid bids have been placed.
6.  `cancelListing(uint256 tokenId)`: Removes a token from the direct sale marketplace.
7.  `endAuction(uint256 tokenId)`: Finalizes an auction after its duration ends. Transfers token to the highest bidder, distributes funds (seller, artist royalty, platform fee), and returns funds to losing bidders.
8.  `getArtDetails(uint256 tokenId)`: Retrieves the generator ID, seed, and parameters for a specific artwork token.
9.  `getArtParameters(uint256 tokenId)`: Returns only the custom generation parameters for a token.
10. `getArtSeed(uint256 tokenId)`: Returns only the seed used for a token's generation.
11. `getAuction(uint256 tokenId)`: Retrieves details of an ongoing or past auction for a token.
12. `getGeneratorDetails(uint256 generatorId)`: Retrieves details about a registered generator (name, artist, parameters).
13. `getGeneratorParameters(uint256 generatorId)`: Returns the base parameters associated with a generator.
14. `getListing(uint256 tokenId)`: Retrieves details of a direct sale listing for a token.
15. `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all of an owner's tokens (ERC721 standard).
16. `listForSale(uint256 tokenId, uint256 price)`: Lists an owned token on the direct sale marketplace at a fixed price.
17. `mintArt(uint256 generatorId, bytes customParams)`: Mints a new unique artwork token using the specified generator and custom parameters. A unique seed is incorporated.
18. `ownerOf(uint256 tokenId)`: Returns the owner of a specific token (ERC721 standard).
19. `pause()`: Pauses all marketplace and minting activities. Requires owner/curator.
20. `placeBid(uint256 tokenId)`: Places a bid on an ongoing auction. Requires sending ether value.
21. `removeGenerator(uint256 generatorId)`: Deactivates or removes a generator (requires owner/curator).
22. `royaltyInfo(uint256 tokenId, uint256 salePrice)`: Returns royalty recipient and amount based on ERC2981 standard (calculates artist royalty + platform fee).
23. `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfers token, checking recipient's ERC721 support (ERC721 standard).
24. `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safely transfers token with data (ERC721 standard).
25. `setApprovalForAll(address operator, bool approved)`: Sets approval for an operator to manage all of the owner's tokens (ERC721 standard).
26. `setArtistRoyaltyPercentage(uint256 generatorId, uint96 percentage)`: Allows a generator's artist to set their royalty percentage (up to a cap).
27. `setCurator(address newCurator)`: Sets the address of the marketplace curator. Requires owner.
28. `setMinimumBidIncrement(uint256 increment)`: Sets the minimum required increase for new bids in auctions. Requires owner.
29. `setPlatformFeePercentage(uint96 percentage)`: Sets the percentage of sales retained by the platform. Requires owner.
30. `startAuction(uint256 tokenId, uint256 minBid, uint64 duration)`: Starts an English auction for an owned token.
31. `supportsInterface(bytes4 interfaceId)`: ERC165 standard, indicates supported interfaces (ERC721, ERC2981).
32. `tokenURI(uint256 tokenId)`: Returns a URI for the token metadata. Includes parameters needed for off-chain rendering service.
33. `transferFrom(address from, address to, uint256 tokenId)`: Transfers token without checking recipient support (ERC721 standard).
34. `transferOwnership(address newOwner)`: Transfers contract ownership.
35. `unpause()`: Unpauses marketplace and minting activities. Requires owner/curator.
36. `withdrawArtistEarnings()`: Allows an artist to withdraw their accumulated royalty and sale earnings.
37. `withdrawBid(uint256 tokenId)`: Allows a bidder to withdraw their previous bid if they were outbid or the auction failed/cancelled.
38. `withdrawPlatformFees()`: Allows the owner to withdraw accumulated platform fees.

*(Note: Some standard ERC721 getters like `getApproved` are not explicitly listed here for brevity in the summary but are included in the contract).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Generative Art Marketplace with On-Chain Parameters and Curator Governance
/// @author Your Name/Alias (or contract purpose)
/// @notice This contract implements a decentralized marketplace for generative art NFTs.
/// Art parameters are stored on-chain. Artists register generators via curators.
/// Supports direct sales, auctions, ERC2981 royalties, and platform fees.
/// @dev Integrates ERC721, ERC2981, Ownable, Pausable standards.
/// Requires an off-chain service to render art based on on-chain parameters provided via tokenURI.

contract GenerativeArtMarketplace is ERC721, ERC721Enumerable, IERC2981, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _tokenIds;
    Counters.Counter private _generatorIds;

    struct Generator {
        string name;
        address artist;
        bytes baseGenerationParams; // Default parameters for this generator type
        bool active; // Can new art be minted from this generator?
        uint96 artistRoyaltyPercentage; // Percentage artist gets on sales
    }

    struct ArtDetails {
        uint256 generatorId;
        uint256 seed; // Unique seed for this specific piece
        bytes customParams; // Custom parameters used during minting (override/add to base)
    }

    struct Listing {
        uint256 price; // Price in native token (e.g., ETH)
        address seller;
    }

    struct Auction {
        uint256 tokenId;
        uint256 minBid; // Minimum starting bid
        uint256 highestBid;
        address highestBidder;
        uint64 endTime;
        bool ended;
    }

    mapping(uint256 => Generator) private _generators;
    mapping(uint256 => ArtDetails) private _artDetails;
    mapping(uint256 => Listing) private _listings; // tokenId -> Listing
    mapping(uint256 => Auction) private _auctions; // tokenId -> Auction
    mapping(address => uint256) private _artistEarnings; // Artist address -> accumulated earnings
    uint256 private _platformEarnings; // Accumulated platform fees
    mapping(uint256 => uint256) private _pendingReturns; // Auction withdrawals: bidder -> amount

    address private _curator;
    uint96 private _platformFeePercentage; // Percentage platform gets on sales
    uint265 private _minimumBidIncrement; // Minimum increase for new bids

    uint96 private constant MAX_PERCENTAGE = 10000; // Representing 100% (e.g., 100 = 1%)
    uint96 private constant MAX_ROYALTY_PERCENTAGE = 5000; // Max 50% for artist royalty

    // Base URI for metadata, pointing to an off-chain rendering service
    string private _baseTokenURI;

    // --- Events ---

    event GeneratorAdded(uint256 indexed generatorId, string name, address indexed artist);
    event GeneratorRemoved(uint256 indexed generatorId);
    event ArtMinted(uint256 indexed tokenId, uint256 indexed generatorId, address indexed minter, uint256 seed);
    event ArtParametersUpdated(uint256 indexed tokenId, bytes newParams);
    event ListedForSale(uint256 indexed tokenId, address indexed seller, uint256 price);
    event SaleCancelled(uint256 indexed tokenId);
    event ArtSold(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event AuctionStarted(uint256 indexed tokenId, address indexed seller, uint256 minBid, uint64 endTime);
    event BidPlaced(uint256 indexed tokenId, address indexed bidder, uint256 amount);
    event AuctionEnded(uint256 indexed tokenId, address indexed winner, uint256 amount);
    event BidWithdrawal(address indexed bidder, uint256 amount);
    event ArtistRoyaltySet(uint256 indexed generatorId, uint96 percentage);
    event PlatformFeeSet(uint96 percentage);
    event CuratorSet(address indexed oldCurator, address indexed newCurator);
    event MinimumBidIncrementSet(uint256 increment);

    // --- Modifiers ---

    modifier onlyCurator() {
        require(msg.sender == _curator, "Only curator");
        _;
    }

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, string memory baseTokenURI_, address initialCurator, uint96 initialPlatformFeePercentage, uint256 initialMinBidIncrement)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _baseTokenURI = baseTokenURI_;
        _curator = initialCurator;
        require(initialPlatformFeePercentage <= MAX_PERCENTAGE, "Platform fee exceeds 100%");
        _platformFeePercentage = initialPlatformFeePercentage;
        _minimumBidIncrement = initialMinBidIncrement;

        emit CuratorSet(address(0), initialCurator);
        emit PlatformFeeSet(initialPlatformFeePercentage);
        emit MinimumBidIncrementSet(initialMinBidIncrement);
    }

    // --- Pausable Overrides ---

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);

        // Ensure token is not actively listed or in auction when transferring via ERC721 methods
        require(_listings[tokenId].seller == address(0), "Token listed for sale");
        require(_auctions[tokenId].seller == address(0), "Token in auction"); // Assuming seller is set during auction start
    }

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
         return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint256 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }


    // --- ERC721 & ERC165 Standard Functions ---

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        ArtDetails storage art = _artDetails[tokenId];
        Generator storage generator = _generators[art.generatorId];

        // Construct a URI that includes parameters needed for the off-chain renderer
        // Example format: baseURI/tokenId?generatorId=X&seed=Y&params=Z
        // The off-chain service reads these query params to render the art and serve metadata.
        // Encoding bytes to string might require a library or specific handling off-chain.
        // This is a simplified representation.

        string memory uri = string(abi.encodePacked(
            _baseTokenURI,
            tokenId.toString(),
            "?generatorId=", art.generatorId.toString(),
            "&seed=", art.seed.toString()
            // Encoding art.customParams and generator.baseGenerationParams requires careful handling (e.g., hex encoding)
            // For simplicity, we omit params here but a real implementation would include them.
        ));

        return uri;
    }

    // --- ERC2981 Royalty Function ---

    /// @dev Calculates royalty amount based on artist's set percentage and platform fee.
    /// Royalty is paid to the artist's address associated with the generator.
    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "Invalid token ID");

        ArtDetails storage art = _artDetails[tokenId];
        Generator storage generator = _generators[art.generatorId];

        // Total fee is artist royalty + platform fee
        uint256 totalPercentage = generator.artistRoyaltyPercentage + _platformFeePercentage;
        require(totalPercentage <= MAX_PERCENTAGE, "Total fees exceed 100%"); // Should be enforced during setting

        // Calculate total royalty amount
        uint256 totalRoyalty = (salePrice * totalPercentage) / MAX_PERCENTAGE;

        // Royalties combined and paid to the artist's associated address.
        // The split between artist and platform happens internally upon withdrawal.
        // ERC2981 spec assumes a single receiver, so we direct it to the artist's withdrawal address.
        // The contract tracks the internal split.
        return (generator.artist, totalRoyalty);
    }

    // --- Generator Management ---

    /// @notice Allows a curator or owner to register a new art generator.
    /// @param name The name of the generator (e.g., "Perlin Noise Landscapes").
    /// @param artist The address of the artist who owns/manages this generator.
    /// @param generationParams Default parameters for this generator type.
    function addGenerator(string memory name, address artist, bytes memory generationParams) external onlyCurator {
        _generatorIds.increment();
        uint256 generatorId = _generatorIds.current();
        _generators[generatorId] = Generator({
            name: name,
            artist: artist,
            baseGenerationParams: generationParams,
            active: true,
            artistRoyaltyPercentage: 0 // Default to 0, artist sets later
        });
        emit GeneratorAdded(generatorId, name, artist);
    }

    /// @notice Allows a curator or owner to deactivate a generator, preventing new mints.
    /// @param generatorId The ID of the generator to remove.
    function removeGenerator(uint256 generatorId) external onlyCurator {
        require(_generators[generatorId].artist != address(0), "Generator does not exist");
        _generators[generatorId].active = false; // Just deactivate, keep data for existing tokens
        emit GeneratorRemoved(generatorId);
    }

    /// @notice Gets details for a specific generator.
    /// @param generatorId The ID of the generator.
    /// @return name, artist, baseGenerationParams, active, artistRoyaltyPercentage
    function getGeneratorDetails(uint256 generatorId) external view returns (string memory name, address artist, bytes memory baseGenerationParams, bool active, uint96 artistRoyaltyPercentage) {
        Generator storage g = _generators[generatorId];
        require(g.artist != address(0), "Generator does not exist");
        return (g.name, g.artist, g.baseGenerationParams, g.active, g.artistRoyaltyPercentage);
    }

    /// @notice Gets the base generation parameters for a generator.
    /// @param generatorId The ID of the generator.
    /// @return baseGenerationParams
    function getGeneratorParameters(uint256 generatorId) external view returns (bytes memory) {
         Generator storage g = _generators[generatorId];
        require(g.artist != address(0), "Generator does not exist");
        return g.baseGenerationParams;
    }

     /// @notice Allows the artist of a generator to set their royalty percentage.
    /// @param generatorId The ID of the generator.
    /// @param percentage The royalty percentage (0-10000, where 10000 is 100%).
    function setArtistRoyaltyPercentage(uint256 generatorId, uint96 percentage) external whenNotPaused {
        Generator storage generator = _generators[generatorId];
        require(generator.artist != address(0), "Generator does not exist");
        require(msg.sender == generator.artist, "Only generator artist can set royalty");
        require(percentage <= MAX_ROYALTY_PERCENTAGE, "Artist royalty exceeds cap");

        generator.artistRoyaltyPercentage = percentage;
        emit ArtistRoyaltySet(generatorId, percentage);
    }

     /// @notice Gets the artist royalty percentage for a generator.
    /// @param generatorId The ID of the generator.
    /// @return percentage
    function getArtistRoyaltyPercentage(uint256 generatorId) external view returns (uint96) {
         Generator storage generator = _generators[generatorId];
        require(generator.artist != address(0), "Generator does not exist");
        return generator.artistRoyaltyPercentage;
    }


    // --- Minting ---

    /// @notice Mints a new generative art token.
    /// @param generatorId The ID of the generator to use.
    /// @param customParams Custom parameters specific to this mint, which combine with base generator params.
    /// @return The ID of the newly minted token.
    function mintArt(uint256 generatorId, bytes memory customParams) external whenNotPaused returns (uint256) {
        Generator storage generator = _generators[generatorId];
        require(generator.artist != address(0), "Generator does not exist");
        require(generator.active, "Generator is not active");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        // Use a combination of block data and caller for a semi-unique seed
        // Note: block.timestamp and block.difficulty/prevrandao are susceptible to miner manipulation
        // For true randomness, use Chainlink VRF or similar. This is simpler for demonstration.
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            msg.sender,
            newTokenId
        )));

        _artDetails[newTokenId] = ArtDetails({
            generatorId: generatorId,
            seed: seed,
            customParams: customParams
        });

        _safeMint(msg.sender, newTokenId);

        emit ArtMinted(newTokenId, generatorId, msg.sender, seed);
        return newTokenId;
    }

    /// @notice Gets the full art details (generator ID, seed, params) for a token.
    /// @param tokenId The ID of the token.
    /// @return generatorId, seed, customParams
    function getArtDetails(uint256 tokenId) external view returns (uint256 generatorId, uint256 seed, bytes memory customParams) {
        require(_exists(tokenId), "Token does not exist");
        ArtDetails storage art = _artDetails[tokenId];
        return (art.generatorId, art.seed, art.customParams);
    }

     /// @notice Gets the seed used for a token's generation.
    /// @param tokenId The ID of the token.
    /// @return seed
    function getArtSeed(uint256 tokenId) external view returns (uint256) {
         require(_exists(tokenId), "Token does not exist");
        return _artDetails[tokenId].seed;
    }

     /// @notice Gets the custom generation parameters used for a token.
    /// @param tokenId The ID of the token.
    /// @return customParams
    function getArtParameters(uint256 tokenId) external view returns (bytes memory) {
         require(_exists(tokenId), "Token does not exist");
        return _artDetails[tokenId].customParams;
    }


    // --- Direct Sale Marketplace ---

    /// @notice Lists a token for direct sale.
    /// @param tokenId The ID of the token to list.
    /// @param price The price in native tokens (e.g., wei).
    function listForSale(uint256 tokenId, uint256 price) external whenNotPaused onlyApprovedOrOwner(tokenId) {
        require(_listings[tokenId].seller == address(0), "Token already listed");
        require(_auctions[tokenId].seller == address(0), "Token in auction"); // Assuming seller check implies active auction

        _listings[tokenId] = Listing({
            price: price,
            seller: msg.sender
        });

        // Approve the contract to hold/transfer the token when listed
        // If the contract is already approved for all, this is redundant but harmless.
        // If only the individual token is approved, this ensures the contract can take it.
        // However, a simpler approach is to *require* the owner approves the marketplace *before* listing.
        // Let's stick to requiring `onlyApprovedOrOwner` which means the user has already approved the contract.
        // We don't transfer ownership here, just list it for sale.

        emit ListedForSale(tokenId, msg.sender, price);
    }

    /// @notice Cancels a direct sale listing.
    /// @param tokenId The ID of the token listing to cancel.
    function cancelListing(uint256 tokenId) external whenNotPaused {
        require(_listings[tokenId].seller == msg.sender, "Not the seller or token not listed");

        delete _listings[tokenId];

        emit SaleCancelled(tokenId);
    }

    /// @notice Buys a token listed for direct sale.
    /// @param tokenId The ID of the token to buy.
    function buyArt(uint256 tokenId) external payable whenNotPaused {
        Listing storage listing = _listings[tokenId];
        require(listing.seller != address(0), "Token not listed for sale");
        require(msg.sender != listing.seller, "Cannot buy your own token");
        require(msg.value >= listing.price, "Insufficient funds");

        uint256 totalPrice = listing.price;
        address seller = listing.seller;
        address buyer = msg.sender;

        // Calculate royalties and platform fee
        (address royaltyReceiver, uint256 totalRoyalty) = royaltyInfo(tokenId, totalPrice);

        uint256 platformFee = (totalPrice * _platformFeePercentage) / MAX_PERCENTAGE;
        uint256 artistRoyalty = totalRoyalty - platformFee; // artistRoyaltyPercentage + platformFeePercentage = totalPercentage

        uint256 sellerPayout = totalPrice - totalRoyalty;

        // Clear the listing BEFORE transfers (checks-effects-interactions)
        delete _listings[tokenId];

        // Effects: Record earnings
        _artistEarnings[royaltyReceiver] += artistRoyalty;
        _platformEarnings += platformFee;

        // Effects: Transfer token
        _transfer(seller, buyer, tokenId);

        // Interactions: Send seller payout
        (bool success, ) = payable(seller).call{value: sellerPayout}("");
        require(success, "Seller payout failed");

        // Refund excess Ether if any
        if (msg.value > totalPrice) {
             (success, ) = payable(msg.sender).call{value: msg.value - totalPrice}("");
             require(success, "Refund failed");
        }

        emit ArtSold(tokenId, buyer, totalPrice);
    }

    /// @notice Gets the details of a direct sale listing.
    /// @param tokenId The ID of the token.
    /// @return price, seller (seller is address(0) if not listed)
    function getListing(uint256 tokenId) external view returns (uint256 price, address seller) {
        Listing storage listing = _listings[tokenId];
        return (listing.price, listing.seller);
    }


    // --- Auction Marketplace (English Auction) ---

    /// @notice Starts an English auction for a token.
    /// @param tokenId The ID of the token to auction.
    /// @param minBid The minimum starting bid amount.
    /// @param duration The duration of the auction in seconds.
    function startAuction(uint256 tokenId, uint256 minBid, uint64 duration) external whenNotPaused onlyApprovedOrOwner(tokenId) {
        require(_listings[tokenId].seller == address(0), "Token listed for sale");
        require(_auctions[tokenId].seller == address(0), "Token already in auction");
        require(minBid > 0, "Minimum bid must be greater than 0");
        require(duration > 0, "Auction duration must be greater than 0");
        require(block.timestamp + duration > block.timestamp, "Duration overflow"); // Prevent time wrap around

        _auctions[tokenId] = Auction({
            tokenId: tokenId,
            minBid: minBid,
            highestBid: minBid, // Set initial highest bid to minBid
            highestBidder: address(0), // No bidder yet
            endTime: uint64(block.timestamp + duration),
            ended: false
        });

        // Approve the contract to manage the token during the auction
        // Similar to listing, require owner approves the contract before calling startAuction.
        // onlyApprovedOrOwner modifier handles this.

        emit AuctionStarted(tokenId, msg.sender, minBid, uint64(block.timestamp + duration));
    }

     /// @notice Allows a user to place a bid on an ongoing auction.
    /// @param tokenId The ID of the token in auction.
    function placeBid(uint256 tokenId) external payable whenNotPaused {
        Auction storage auction = _auctions[tokenId];
        require(auction.seller != address(0), "Token not in auction"); // Check if auction exists
        require(!auction.ended, "Auction has ended");
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(msg.sender != ownerOf(tokenId), "Seller cannot bid"); // Seller cannot bid on their own auction
        require(msg.value >= auction.highestBid + _minimumBidIncrement, "Bid too low");

        // If there is a current highest bidder, refund their previous bid
        if (auction.highestBidder != address(0)) {
            _pendingReturns[auction.highestBidder] += auction.highestBid;
            emit BidWithdrawal(auction.highestBidder, auction.highestBid);
        }

        // Update highest bid and bidder (effects)
        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;

        emit BidPlaced(tokenId, msg.sender, msg.value);
    }

     /// @notice Allows the seller to cancel an auction if no bids have been placed yet.
    /// @param tokenId The ID of the token in auction.
    function cancelAuction(uint256 tokenId) external whenNotPaused {
        Auction storage auction = _auctions[tokenId];
        require(ownerOf(tokenId) == msg.sender, "Only seller can cancel auction"); // Assuming seller is current owner
        require(auction.seller != address(0), "Token not in auction");
        require(!auction.ended, "Auction has ended");
        require(auction.highestBidder == address(0), "Cannot cancel after a bid is placed");

        // Clear the auction details (effects)
        delete _auctions[tokenId];

        emit AuctionEnded(tokenId, address(0), 0); // Indicate cancellation
    }

    /// @notice Ends an auction after its duration has passed. Can be called by anyone.
    /// @param tokenId The ID of the token in auction.
    function endAuction(uint256 tokenId) external whenNotPaused {
        Auction storage auction = _auctions[tokenId];
        require(auction.seller != address(0), "Token not in auction");
        require(!auction.ended, "Auction has ended");
        require(block.timestamp >= auction.endTime, "Auction has not ended yet");

        auction.ended = true; // Mark as ended immediately (effects)

        address seller = ownerOf(tokenId); // Seller is the current owner
        address winner = auction.highestBidder;
        uint256 winningBid = auction.highestBid;

        if (winner == address(0)) {
            // No bids were placed
            emit AuctionEnded(tokenId, address(0), 0);
            // No transfer or payment needed
        } else {
            // Calculate royalties and platform fee
            (address royaltyReceiver, uint256 totalRoyalty) = royaltyInfo(tokenId, winningBid);
            uint256 platformFee = (winningBid * _platformFeePercentage) / MAX_PERCENTAGE;
            uint256 artistRoyalty = totalRoyalty - platformFee;

            uint256 sellerPayout = winningBid - totalRoyalty;

            // Effects: Record earnings
            _artistEarnings[royaltyReceiver] += artistRoyalty;
            _platformEarnings += platformFee;

            // Effects: Transfer token to winner
            _transfer(seller, winner, tokenId);

            // Interactions: Send seller payout
            // Use low-level call for flexibility and to prevent reentrancy with check-effects-interactions
            (bool success, ) = payable(seller).call{value: sellerPayout}("");
            require(success, "Seller payout failed");

            emit AuctionEnded(tokenId, winner, winningBid);
        }
         // Clean up auction data after handling
        delete _auctions[tokenId];
    }

     /// @notice Allows a bidder to withdraw their previous bid if they were outbid or auction ended without them winning.
    /// @param tokenId The ID of the token in auction. (Used to identify the auction, not the token being withdrawn)
    function withdrawBid(uint256 tokenId) external {
        uint256 amount = _pendingReturns[msg.sender];
        require(amount > 0, "No pending returns for this address");

        _pendingReturns[msg.sender] = 0; // Clear balance *before* sending (effects)

        // Interaction: Send the amount
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");

        emit BidWithdrawal(msg.sender, amount);
    }

    /// @notice Gets the details of an auction.
    /// @param tokenId The ID of the token.
    /// @return tokenId, minBid, highestBid, highestBidder, endTime, ended
    function getAuction(uint256 tokenId) external view returns (uint256 tId, uint256 minBid, uint256 highestBid, address highestBidder, uint64 endTime, bool ended) {
        Auction storage auction = _auctions[tokenId];
         require(auction.seller != address(0) || auction.ended, "Token not in active or ended auction"); // Allow viewing ended auctions briefly
        return (auction.tokenId, auction.minBid, auction.highestBid, auction.highestBidder, auction.endTime, auction.ended);
    }

     /// @notice Sets the minimum bid increment for auctions.
    /// @param increment The new minimum increment amount.
    function setMinimumBidIncrement(uint256 increment) external onlyOwner {
        _minimumBidIncrement = increment;
        emit MinimumBidIncrementSet(increment);
    }


    // --- Fee Management ---

    /// @notice Allows the owner to set the platform fee percentage.
    /// @param percentage The platform fee percentage (0-10000, where 10000 is 100%).
    function setPlatformFeePercentage(uint96 percentage) external onlyOwner {
        require(percentage <= MAX_PERCENTAGE, "Percentage exceeds 100%");
        _platformFeePercentage = percentage;
        emit PlatformFeeSet(percentage);
    }

    /// @notice Allows the platform owner to withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyOwner {
        uint256 amount = _platformEarnings;
        require(amount > 0, "No platform earnings to withdraw");

        _platformEarnings = 0; // Clear balance *before* sending (effects)

        // Interaction: Send the amount
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Platform fee withdrawal failed");
    }

     /// @notice Allows an artist to withdraw their accumulated earnings (royalties + sale proceeds).
    function withdrawArtistEarnings() external whenNotPaused {
        uint256 amount = _artistEarnings[msg.sender];
        require(amount > 0, "No artist earnings to withdraw");

        _artistEarnings[msg.sender] = 0; // Clear balance *before* sending (effects)

        // Interaction: Send the amount
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Artist earnings withdrawal failed");
    }


    // --- Admin & Curator Functions ---

    /// @notice Sets the address of the curator role.
    /// @param newCurator The address to set as curator.
    function setCurator(address newCurator) external onlyOwner {
        address oldCurator = _curator;
        _curator = newCurator;
        emit CuratorSet(oldCurator, newCurator);
    }

    /// @notice Removes the curator role.
    function removeCurator() external onlyOwner {
        address oldCurator = _curator;
        _curator = address(0);
        emit CuratorSet(oldCurator, address(0));
    }

    /// @notice Pauses the contract (minting, listing, bidding, buying, withdrawing earnings).
    function pause() external onlyOwnerOrCurator {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpause() external onlyOwnerOrCurator {
        _unpause();
    }

    // --- Internal Helpers ---

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

     function onlyOwnerOrCurator() internal view returns (bool) {
        return msg.sender == owner() || msg.sender == _curator;
    }

    // Override isApprovedForAll to allow marketplace listings/auctions even if not explicitly approved.
    // The _beforeTokenTransfer checks handle the state (listed/auctioned).
    // This override might be too permissive depending on exact security model.
    // A safer approach is to require explicit approval *before* listing/auctioning.
    // Sticking with requiring onlyApprovedOrOwner before list/startAuction makes this override unnecessary.
    // Let's remove this potential override and rely on user calling approve/setApprovalForAll.


    // The following functions are overrides required by Solidity.
    // They ensure the ERC721Enumerable functions work correctly alongside Pausable.
    function _update(address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId);
    }
}
```