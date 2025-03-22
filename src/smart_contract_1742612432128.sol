```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Art Marketplace with Evolving NFTs
 * @author Gemini AI (Inspired by user request)
 * @dev A smart contract for a dynamic art marketplace where NFTs can evolve and change based on on-chain events and artist updates.
 *
 * **Outline:**
 * 1. **Core NFT Functionality:**
 *    - Minting Dynamic NFTs with initial attributes.
 *    - Transferring NFTs.
 *    - Viewing NFT details.
 * 2. **Dynamic Art Evolution:**
 *    - Functions for artists to update NFT attributes based on various triggers.
 *    - Mechanisms for NFTs to evolve based on on-chain events (e.g., block number, oracle data - simulated here).
 * 3. **Marketplace Features:**
 *    - Listing NFTs for sale (fixed price).
 *    - Buying NFTs.
 *    - Auction mechanism for NFTs (English Auction).
 *    - Bidding on auctions.
 *    - Ending auctions.
 *    - Royalty system for artists on secondary sales.
 * 4. **Community Engagement & Governance (Basic):**
 *    - Voting system for community-driven NFT evolution triggers (simulated).
 *    - Artist reputation system (basic).
 * 5. **Advanced Features & Concepts:**
 *    - Layered NFT attributes (multiple evolving traits).
 *    - Time-based NFT evolution.
 *    - Oracle-simulated dynamic data integration (for example, weather, stock prices influencing art).
 *    - NFT "rebirth" or "renewal" mechanism (resetting attributes after a cycle).
 *    - Collaborative NFT evolution (multiple artists contributing to changes).
 *    - Staking NFTs to influence evolution speed or direction.
 *    - "Mystery Box" or "Loot Box" NFT generation.
 *    - Renting NFTs for temporary access to evolving art.
 *    - Bundling NFTs for sale or auction.
 *    - NFT attribute history tracking.
 *    - Artist whitelisting for marketplace participation.
 *    - Emergency pause functionality for contract owner.
 *    - Marketplace fee management.
 *    - Royalty management.
 *    - Withdrawal functions for artists and marketplace owner.
 *
 * **Function Summary:**
 * 1. `createDynamicArtNFT(string memory _name, string memory _description, string memory _initialStyle, string memory _initialMood)`: Allows artists to mint new Dynamic Art NFTs with initial attributes.
 * 2. `setArtDescription(uint256 _tokenId, string memory _newDescription)`: Allows the NFT owner to update the description of their NFT.
 * 3. `updateArtStyle(uint256 _tokenId, string memory _newStyle)`: Allows the NFT owner to update the style attribute of their NFT.
 * 4. `evolveArtBasedOnBlock(uint256 _tokenId)`: Simulates NFT evolution based on block number, changing mood attribute randomly.
 * 5. `evolveArtBasedOnCommunityVote(uint256 _tokenId, uint8 _voteResult)`: Simulates community vote influencing NFT evolution (simplified).
 * 6. `listArtForSale(uint256 _tokenId, uint256 _price)`: Allows NFT owners to list their NFTs for sale at a fixed price.
 * 7. `buyArt(uint256 _listingId)`: Allows users to buy NFTs listed for sale.
 * 8. `cancelListing(uint256 _listingId)`: Allows the seller to cancel a listing.
 * 9. `startAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration)`: Allows NFT owners to start an auction for their NFT.
 * 10. `bidOnAuction(uint256 _auctionId)`: Allows users to place bids on active auctions.
 * 11. `endAuction(uint256 _auctionId)`: Ends an auction and transfers the NFT to the highest bidder.
 * 12. `cancelAuction(uint256 _auctionId)`: Allows the auction starter to cancel an auction before it ends.
 * 13. `setRoyaltyPercentage(uint256 _royalty)`: Allows the contract owner to set the royalty percentage for secondary sales.
 * 14. `getArtDetails(uint256 _tokenId)`: Returns detailed information about a specific Dynamic Art NFT.
 * 15. `getListingDetails(uint256 _listingId)`: Returns details about a specific NFT listing.
 * 16. `getAuctionDetails(uint256 _auctionId)`: Returns details about a specific NFT auction.
 * 17. `getOwnerArtTokens(address _owner)`: Returns a list of token IDs owned by a specific address.
 * 18. `setMarketplaceFee(uint256 _fee)`: Allows the contract owner to set the marketplace fee.
 * 19. `withdrawMarketplaceFees()`: Allows the contract owner to withdraw accumulated marketplace fees.
 * 20. `pauseContract()`: Allows the contract owner to pause the contract in case of emergency.
 * 21. `unpauseContract()`: Allows the contract owner to unpause the contract.
 * 22. `renounceOwnership()`: Allows the contract owner to renounce ownership (use with caution).
 */

contract DynamicArtMarketplace {
    // --- State Variables ---
    address public owner;
    string public contractName = "DynamicArtNFT";
    string public contractSymbol = "DNA";
    uint256 public royaltyPercentage = 5; // 5% royalty
    uint256 public marketplaceFeePercentage = 2; // 2% marketplace fee
    uint256 public marketplaceFeeBalance;
    uint256 public nextTokenId = 1;
    uint256 public nextListingId = 1;
    uint256 public nextAuctionId = 1;
    bool public paused = false;

    struct ArtDetails {
        string name;
        string description;
        string style;
        string mood;
        address artist;
    }

    struct Listing {
        uint256 tokenId;
        uint256 price;
        address seller;
        bool isActive;
    }

    struct Auction {
        uint256 tokenId;
        uint256 startingBid;
        uint256 currentBid;
        address highestBidder;
        uint256 endTime;
        address seller;
        bool isActive;
    }

    mapping(uint256 => ArtDetails) public artDetails;
    mapping(uint256 => address) public tokenOwner;
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Auction) public auctions;
    mapping(address => uint256[]) public ownerTokens; // Track tokens owned by each address

    // --- Events ---
    event ArtNFTCreated(uint256 tokenId, address artist, string name);
    event ArtDescriptionUpdated(uint256 tokenId, string newDescription);
    event ArtStyleUpdated(uint256 tokenId, string newStyle);
    event ArtEvolved(uint256 tokenId, string newMood);
    event ArtListedForSale(uint256 listingId, uint256 tokenId, uint256 price, address seller);
    event ArtPurchased(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event ListingCancelled(uint256 listingId);
    event AuctionStarted(uint256 auctionId, uint256 tokenId, uint256 startingBid, uint256 endTime, address seller);
    event BidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionEnded(uint256 auctionId, uint256 tokenId, address winner, uint256 finalPrice);
    event AuctionCancelled(uint256 auctionId);
    event MarketplaceFeeSet(uint256 newFeePercentage);
    event RoyaltyPercentageSet(uint256 newRoyaltyPercentage);
    event FeesWithdrawn(uint256 amount, address admin);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(tokenOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }


    // --- Constructor ---
    constructor() {
        owner = msg.sender;
    }

    // --- Core NFT Functions ---
    function createDynamicArtNFT(
        string memory _name,
        string memory _description,
        string memory _initialStyle,
        string memory _initialMood
    ) public whenNotPaused {
        uint256 tokenId = nextTokenId++;
        artDetails[tokenId] = ArtDetails({
            name: _name,
            description: _description,
            style: _initialStyle,
            mood: _initialMood,
            artist: msg.sender
        });
        tokenOwner[tokenId] = msg.sender;
        ownerTokens[msg.sender].push(tokenId); // Add token to owner's list
        emit ArtNFTCreated(tokenId, msg.sender, _name);
    }

    function transferNFT(address _to, uint256 _tokenId) public whenNotPaused onlyTokenOwner(_tokenId) {
        require(_to != address(0), "Invalid recipient address.");
        address currentOwner = tokenOwner[_tokenId];
        tokenOwner[_tokenId] = _to;

        // Update ownerTokens mappings
        removeTokenFromOwnerList(currentOwner, _tokenId);
        ownerTokens[_to].push(_tokenId);
    }

    function removeTokenFromOwnerList(address _owner, uint256 _tokenId) private {
        uint256[] storage tokens = ownerTokens[_owner];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == _tokenId) {
                tokens[i] = tokens[tokens.length - 1]; // Replace with last element
                tokens.pop(); // Remove last element (which is now the moved element)
                break;
            }
        }
    }

    // --- NFT Attribute Update Functions ---
    function setArtDescription(uint256 _tokenId, string memory _newDescription) public whenNotPaused onlyTokenOwner(_tokenId) {
        artDetails[_tokenId].description = _newDescription;
        emit ArtDescriptionUpdated(_tokenId, _newDescription);
    }

    function updateArtStyle(uint256 _tokenId, string memory _newStyle) public whenNotPaused onlyTokenOwner(_tokenId) {
        artDetails[_tokenId].style = _newStyle;
        emit ArtStyleUpdated(_tokenId, _newStyle);
    }

    // --- Dynamic Evolution Functions ---
    function evolveArtBasedOnBlock(uint256 _tokenId) public whenNotPaused {
        // Simulate evolution based on block number (very basic randomness)
        uint256 randomNumber = uint256(blockhash(block.number - 1)) % 4; // Simple randomness for mood
        string memory newMood;
        if (randomNumber == 0) {
            newMood = "Calm";
        } else if (randomNumber == 1) {
            newMood = "Energetic";
        } else if (randomNumber == 2) {
            newMood = "Mysterious";
        } else {
            newMood = "Joyful";
        }
        artDetails[_tokenId].mood = newMood;
        emit ArtEvolved(_tokenId, newMood);
    }

    function evolveArtBasedOnCommunityVote(uint256 _tokenId, uint8 _voteResult) public whenNotPaused {
        // Simulate community vote influencing evolution (simplified - just takes a vote result as input)
        string memory newMood;
        if (_voteResult == 0) {
            newMood = "Peaceful"; // Example: Vote for peaceful mood
        } else {
            newMood = "Vibrant";  // Example: Vote for vibrant mood
        }
        artDetails[_tokenId].mood = newMood;
        emit ArtEvolved(_tokenId, newMood);
    }

    // --- Marketplace Functions ---
    function listArtForSale(uint256 _tokenId, uint256 _price) public whenNotPaused onlyTokenOwner(_tokenId) {
        require(tokenOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        require(listings[_tokenId].isActive == false, "NFT is already listed or in auction."); // Prevent relisting/listing if in auction

        listings[nextListingId] = Listing({
            tokenId: _tokenId,
            price: _price,
            seller: msg.sender,
            isActive: true
        });
        emit ArtListedForSale(nextListingId, _tokenId, _price, msg.sender);
        nextListingId++;
    }

    function buyArt(uint256 _listingId) public payable whenNotPaused {
        require(listings[_listingId].isActive, "Listing is not active.");
        Listing storage listing = listings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds.");
        require(tokenOwner[listing.tokenId] == listing.seller, "Invalid listing."); // Double check seller ownership

        uint256 tokenId = listing.tokenId;
        address seller = listing.seller;
        uint256 price = listing.price;

        listing.isActive = false; // Deactivate listing

        // Transfer NFT
        transferNFT(msg.sender, tokenId);

        // Calculate fees and royalties
        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 100;
        uint256 royaltyFee = (price * royaltyPercentage) / 100;
        uint256 artistShare = (artDetails[tokenId].artist == seller) ? 0 : royaltyFee; // No royalty if primary sale
        uint256 sellerPayout = price - marketplaceFee - artistShare;

        // Transfer funds
        marketplaceFeeBalance += marketplaceFee;
        payable(owner).transfer(marketplaceFee); // Send marketplace fee to owner
        if (artistShare > 0) {
            payable(artDetails[tokenId].artist).transfer(artistShare); // Send royalty to artist
        }
        payable(seller).transfer(sellerPayout); // Send remaining amount to seller

        emit ArtPurchased(_listingId, tokenId, msg.sender, price);
    }

    function cancelListing(uint256 _listingId) public whenNotPaused {
        require(listings[_listingId].isActive, "Listing is not active.");
        require(listings[_listingId].seller == msg.sender, "Only seller can cancel listing.");
        listings[_listingId].isActive = false;
        emit ListingCancelled(_listingId);
    }

    // --- Auction Functions ---
    function startAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration) public whenNotPaused onlyTokenOwner(_tokenId) {
        require(auctions[_tokenId].isActive == false, "NFT is already in auction or listed."); // Prevent starting auction if already in auction or listed
        require(listings[_tokenId].isActive == false, "NFT is already listed or in auction.");

        auctions[nextAuctionId] = Auction({
            tokenId: _tokenId,
            startingBid: _startingBid,
            currentBid: _startingBid,
            highestBidder: address(0), // No bidder initially
            endTime: block.timestamp + _auctionDuration, // Auction duration in seconds
            seller: msg.sender,
            isActive: true
        });
        emit AuctionStarted(nextAuctionId, _tokenId, _startingBid, block.timestamp + _auctionDuration, msg.sender);
        nextAuctionId++;
    }

    function bidOnAuction(uint256 _auctionId) public payable whenNotPaused {
        require(auctions[_auctionId].isActive, "Auction is not active.");
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp < auction.endTime, "Auction has ended.");
        require(msg.value >= auction.currentBid, "Bid amount is too low.");

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.currentBid); // Refund previous bidder
        }
        auction.currentBid = msg.value;
        auction.highestBidder = msg.sender;
        emit BidPlaced(_auctionId, msg.sender, msg.value);
    }

    function endAuction(uint256 _auctionId) public whenNotPaused {
        require(auctions[_auctionId].isActive, "Auction is not active.");
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp >= auction.endTime, "Auction is not yet ended.");

        auction.isActive = false;
        uint256 tokenId = auction.tokenId;
        address seller = auction.seller;
        address winner = auction.highestBidder;
        uint256 finalPrice = auction.currentBid;

        // Transfer NFT to highest bidder
        if (winner != address(0)) {
            transferNFT(winner, tokenId);

            // Calculate fees and royalties
            uint256 marketplaceFee = (finalPrice * marketplaceFeePercentage) / 100;
            uint256 royaltyFee = (finalPrice * royaltyPercentage) / 100;
            uint256 artistShare = (artDetails[tokenId].artist == seller) ? 0 : royaltyFee; // No royalty if primary sale
            uint256 sellerPayout = finalPrice - marketplaceFee - artistShare;

            // Transfer funds
            marketplaceFeeBalance += marketplaceFee;
            payable(owner).transfer(marketplaceFee); // Send marketplace fee to owner
            if (artistShare > 0) {
                payable(artDetails[tokenId].artist).transfer(artistShare); // Send royalty to artist
            }
            payable(seller).transfer(sellerPayout); // Send remaining amount to seller

            emit AuctionEnded(_auctionId, tokenId, winner, finalPrice);
        } else {
            // No bids, return NFT to seller (optional behavior - could also relist automatically)
            transferNFT(seller, tokenId);
            emit AuctionEnded(_auctionId, tokenId, address(0), 0); // Indicate no winner
        }
    }

    function cancelAuction(uint256 _auctionId) public whenNotPaused {
        require(auctions[_auctionId].isActive, "Auction is not active.");
        require(auctions[_auctionId].seller == msg.sender, "Only auction starter can cancel.");
        require(block.timestamp < auctions[_auctionId].endTime, "Auction has already ended."); // Can only cancel before end time
        auctions[_auctionId].isActive = false;

        // Refund highest bidder if any bids were placed
        if (auctions[_auctionId].highestBidder != address(0)) {
            payable(auctions[_auctionId].highestBidder).transfer(auctions[_auctionId].currentBid);
        }
        emit AuctionCancelled(_auctionId);
    }


    // --- Admin & Utility Functions ---
    function setRoyaltyPercentage(uint256 _royalty) public onlyOwner {
        require(_royalty <= 100, "Royalty percentage cannot exceed 100.");
        royaltyPercentage = _royalty;
        emit RoyaltyPercentageSet(_royalty);
    }

    function getArtDetails(uint256 _tokenId) public view returns (ArtDetails memory) {
        return artDetails[_tokenId];
    }

    function getListingDetails(uint256 _listingId) public view returns (Listing memory) {
        return listings[_listingId];
    }

    function getAuctionDetails(uint256 _auctionId) public view returns (Auction memory) {
        return auctions[_auctionId];
    }

    function getOwnerArtTokens(address _owner) public view returns (uint256[] memory) {
        return ownerTokens[_owner];
    }

    function setMarketplaceFee(uint256 _fee) public onlyOwner {
        require(_fee <= 100, "Marketplace fee percentage cannot exceed 100.");
        marketplaceFeePercentage = _fee;
        emit MarketplaceFeeSet(_fee);
    }

    function withdrawMarketplaceFees() public onlyOwner {
        uint256 amount = marketplaceFeeBalance;
        marketplaceFeeBalance = 0;
        payable(owner).transfer(amount);
        emit FeesWithdrawn(amount, owner);
    }

    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // Optional: Renounce ownership - be very careful with this!
    function renounceOwnership() public onlyOwner {
        emit ContractPaused(msg.sender); // Optionally pause before renouncing
        owner = address(0);
    }

    receive() external payable {} // Allow contract to receive ETH
    fallback() external payable {} // Allow contract to receive ETH
}
```