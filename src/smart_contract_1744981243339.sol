```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with Advanced Features
 * @author Bard (AI Assistant)
 * @notice This contract implements a decentralized marketplace for Dynamic NFTs, offering advanced features like dynamic metadata updates,
 *         tiered royalty system, NFT renting, governance through voting, and a unique reputation system based on marketplace activity.
 *
 * **Outline:**
 *
 * **1. NFT Management & Dynamic Metadata:**
 *    - `createDynamicNFT(string initialMetadata)`: Mints a new Dynamic NFT with initial metadata.
 *    - `setDynamicState(uint256 tokenId, bytes stateData)`: Sets dynamic state data for an NFT, triggering metadata update (internal).
 *    - `getNFTMetadata(uint256 tokenId)`: Retrieves the current metadata URI for an NFT, dynamically generated.
 *    - `getNFTState(uint256 tokenId)`: Retrieves the dynamic state data of an NFT.
 *    - `updateBaseMetadataURI(string newBaseURI)`: Admin function to update the base URI for metadata generation.
 *
 * **2. Marketplace Core Functions:**
 *    - `listItemForSale(uint256 tokenId, uint256 price)`: Lists an NFT for sale in the marketplace.
 *    - `unlistItemForSale(uint256 tokenId)`: Removes an NFT listing from the marketplace.
 *    - `buyNFT(uint256 tokenId)`: Allows anyone to purchase a listed NFT.
 *    - `offerBid(uint256 tokenId, uint256 bidPrice)`: Allows users to place bids on NFTs.
 *    - `acceptBid(uint256 tokenId, uint256 bidId)`: Seller accepts a specific bid for their NFT.
 *    - `cancelBid(uint256 tokenId, uint256 bidId)`: Bidder can cancel their bid before acceptance.
 *    - `getListingDetails(uint256 tokenId)`: Retrieves details of an NFT listing (price, seller).
 *    - `getBidDetails(uint256 tokenId, uint256 bidId)`: Retrieves details of a specific bid.
 *
 * **3. Advanced Marketplace Features:**
 *    - `rentNFT(uint256 tokenId, uint256 rentalPrice, uint256 rentalDuration)`: Allows NFT owners to rent out their NFTs for a specified duration.
 *    - `endRental(uint256 tokenId)`: Allows the renter or owner to end the rental period and return the NFT.
 *    - `setRoyaltyTier(uint256 tokenId, uint8 tier)`: Sets a royalty tier for an NFT, impacting future sales commissions.
 *    - `getRoyaltyInfo(uint256 tokenId)`: Returns the royalty information for an NFT (tier and percentage).
 *    - `withdrawMarketplaceFees()`: Admin function to withdraw accumulated marketplace fees.
 *
 * **4. Reputation & Governance Features:**
 *    - `reportUser(address user, string reason)`: Allows users to report other users for marketplace violations (reputation system).
 *    - `voteToSuspendUser(address user)`: Governance function for token holders to vote on suspending a user based on reports.
 *    - `getUserReputation(address user)`: Returns the reputation score of a user (initially based on activity, influenced by reports/votes).
 *    - `setMarketplaceFee(uint256 newFee)`: Admin function to change the marketplace fee percentage.
 *    - `pauseMarketplace()`: Admin function to temporarily pause all marketplace transactions.
 *    - `unpauseMarketplace()`: Admin function to resume marketplace transactions.
 *
 * **Function Summary:**
 *
 * - `createDynamicNFT`: Mints a new Dynamic NFT.
 * - `setDynamicState`: Updates the dynamic state of an NFT, triggering metadata update.
 * - `getNFTMetadata`: Retrieves the dynamic metadata URI of an NFT.
 * - `getNFTState`: Retrieves the dynamic state data of an NFT.
 * - `updateBaseMetadataURI`: Updates the base URI for metadata generation (admin).
 * - `listItemForSale`: Lists an NFT for sale.
 * - `unlistItemForSale`: Removes an NFT from sale listing.
 * - `buyNFT`: Purchases a listed NFT.
 * - `offerBid`: Places a bid on an NFT.
 * - `acceptBid`: Accepts a specific bid for an NFT.
 * - `cancelBid`: Cancels a placed bid.
 * - `getListingDetails`: Gets details of an NFT listing.
 * - `getBidDetails`: Gets details of a specific bid.
 * - `rentNFT`: Rents out an NFT for a duration.
 * - `endRental`: Ends an NFT rental period.
 * - `setRoyaltyTier`: Sets a royalty tier for an NFT.
 * - `getRoyaltyInfo`: Gets royalty information for an NFT.
 * - `withdrawMarketplaceFees`: Withdraws marketplace fees (admin).
 * - `reportUser`: Reports a user for marketplace violations.
 * - `voteToSuspendUser`: Votes to suspend a user (governance).
 * - `getUserReputation`: Gets the reputation score of a user.
 * - `setMarketplaceFee`: Sets the marketplace fee percentage (admin).
 * - `pauseMarketplace`: Pauses marketplace transactions (admin).
 * - `unpauseMarketplace`: Unpauses marketplace transactions (admin).
 */
contract DynamicNFTMarketplace {
    // --- State Variables ---

    string public name = "Dynamic NFT Marketplace";
    string public symbol = "DNFTM";
    string public baseMetadataURI; // Base URI for dynamic metadata
    address public admin;
    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    bool public paused = false;

    uint256 public nextTokenId = 1;
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => string) private _nftMetadata; // Store initial metadata, dynamic part is generated
    mapping(uint256 => bytes) private _nftStateData; // Store dynamic state data
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Bid[]) public bids;
    uint256 public nextBidId = 1;
    mapping(uint256 => Rental) public rentals;
    mapping(uint256 => uint8) public royaltyTiers; // NFT ID to Royalty Tier
    mapping(address => uint256) public userReputation; // User address to reputation score
    mapping(address => Report[]) public userReports;
    mapping(address => bool) public suspendedUsers;

    // --- Structs ---

    struct Listing {
        uint256 price;
        address seller;
        bool isListed;
    }

    struct Bid {
        uint256 bidId;
        uint256 bidPrice;
        address bidder;
        bool isActive;
    }

    struct Rental {
        uint256 rentalPrice;
        address renter;
        uint256 rentalEndTime;
        bool isActive;
    }

    struct Report {
        address reporter;
        string reason;
        uint256 timestamp;
    }

    // --- Events ---

    event NFTCreated(uint256 tokenId, address creator, string initialMetadata);
    event NFTMetadataUpdated(uint256 tokenId, string metadataURI);
    event NFTListed(uint256 tokenId, uint256 price, address seller);
    event NFTUnlisted(uint256 tokenId, uint256 price, address seller);
    event NFTSold(uint256 tokenId, address buyer, address seller, uint256 price);
    event BidPlaced(uint256 tokenId, uint256 bidId, uint256 bidPrice, address bidder);
    event BidAccepted(uint256 tokenId, uint256 bidId, address seller, address bidder, uint256 price);
    event BidCancelled(uint256 tokenId, uint256 bidId, address bidder);
    event NFTRented(uint256 tokenId, address renter, uint256 rentalPrice, uint256 rentalEndTime);
    event RentalEnded(uint256 tokenId, address renter);
    event RoyaltyTierSet(uint256 tokenId, uint8 tier);
    event UserReported(address reportedUser, address reporter, string reason);
    event UserSuspensionVoteStarted(address user);
    event UserSuspended(address user);
    event MarketplaceFeeUpdated(uint256 newFeePercentage);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event AdminUpdatedBaseMetadataURI(string newBaseURI);

    // --- Modifiers ---

    modifier onlyOwnerOf(uint256 tokenId) {
        require(ownerOf[tokenId] == msg.sender, "Not NFT owner");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Marketplace is paused");
        _;
    }

    // --- Constructor ---

    constructor(string memory _baseMetadataURI) {
        admin = msg.sender;
        baseMetadataURI = _baseMetadataURI;
    }

    // --- 1. NFT Management & Dynamic Metadata ---

    function createDynamicNFT(string memory initialMetadata) public returns (uint256 tokenId) {
        tokenId = nextTokenId++;
        ownerOf[tokenId] = msg.sender;
        balanceOf[msg.sender]++;
        _nftMetadata[tokenId] = initialMetadata; // Store initial metadata
        _nftStateData[tokenId] = bytes(""); // Initial state is empty
        emit NFTCreated(tokenId, msg.sender, initialMetadata);
        _updateNFTMetadataURI(tokenId); // Generate initial metadata URI
    }

    function setDynamicState(uint256 tokenId, bytes memory stateData) public onlyOwnerOf(tokenId) whenNotPaused {
        _nftStateData[tokenId] = stateData;
        _updateNFTMetadataURI(tokenId); // Dynamically update metadata URI upon state change
    }

    function getNFTMetadata(uint256 tokenId) public view returns (string memory) {
        require(ownerOf[tokenId] != address(0), "Token does not exist");
        return _generateMetadataURI(tokenId);
    }

    function getNFTState(uint256 tokenId) public view returns (bytes memory) {
        require(ownerOf[tokenId] != address(0), "Token does not exist");
        return _nftStateData[tokenId];
    }

    function updateBaseMetadataURI(string memory newBaseURI) public onlyAdmin {
        baseMetadataURI = newBaseURI;
        emit AdminUpdatedBaseMetadataURI(newBaseURI);
    }

    // Internal function to generate dynamic metadata URI
    function _generateMetadataURI(uint256 tokenId) internal view returns (string memory) {
        // This is a placeholder. In a real application, you'd have a more sophisticated
        // mechanism to generate dynamic metadata based on baseMetadataURI, tokenId, and _nftStateData[tokenId].
        // You might use IPFS, a centralized server, or an on-chain data service to construct the URI.
        // For simplicity, we just append the tokenId to the base URI.
        return string(abi.encodePacked(baseMetadataURI, "/", Strings.toString(tokenId)));
    }

    // Internal function to update and emit NFT metadata URI change
    function _updateNFTMetadataURI(uint256 tokenId) internal {
        string memory metadataURI = _generateMetadataURI(tokenId);
        emit NFTMetadataUpdated(tokenId, metadataURI);
    }


    // --- 2. Marketplace Core Functions ---

    function listItemForSale(uint256 tokenId, uint256 price) public onlyOwnerOf(tokenId) whenNotPaused {
        require(price > 0, "Price must be greater than zero");
        require(!listings[tokenId].isListed, "NFT already listed");
        require(!rentals[tokenId].isActive, "NFT is currently rented and cannot be listed");

        listings[tokenId] = Listing({
            price: price,
            seller: msg.sender,
            isListed: true
        });
        emit NFTListed(tokenId, price, msg.sender);
    }

    function unlistItemForSale(uint256 tokenId) public onlyOwnerOf(tokenId) whenNotPaused {
        require(listings[tokenId].isListed, "NFT not listed");
        delete listings[tokenId]; // Reset listing to default struct values
        emit NFTUnlisted(tokenId, listings[tokenId].price, msg.sender); // Emit with old price for record
    }

    function buyNFT(uint256 tokenId) public payable whenNotPaused {
        require(listings[tokenId].isListed, "NFT not listed for sale");
        Listing memory listing = listings[tokenId];
        require(msg.value >= listing.price, "Insufficient funds");

        // Calculate marketplace fee and royalty
        uint256 marketplaceFee = (listing.price * marketplaceFeePercentage) / 100;
        uint256 royaltyFee = _calculateRoyalty(tokenId, listing.price - marketplaceFee);
        uint256 sellerProceeds = listing.price - marketplaceFee - royaltyFee;

        // Transfer funds
        payable(listing.seller).transfer(sellerProceeds);
        payable(admin).transfer(marketplaceFee);
        _payRoyalty(tokenId, royaltyFee); // Pay royalty if applicable

        // Transfer NFT ownership
        _transferNFT(tokenId, msg.sender, listing.seller);

        // Update listing status and emit event
        delete listings[tokenId];
        emit NFTSold(tokenId, msg.sender, listing.seller, listing.price);
    }

    function offerBid(uint256 tokenId, uint256 bidPrice) public payable whenNotPaused {
        require(ownerOf[tokenId] != address(0), "Token does not exist");
        require(msg.value >= bidPrice, "Insufficient bid amount");
        require(!listings[tokenId].isListed, "Cannot bid on listed NFTs, use buyNFT");
        require(!rentals[tokenId].isActive, "Cannot bid on rented NFTs");

        bids[tokenId].push(Bid({
            bidId: nextBidId++,
            bidPrice: bidPrice,
            bidder: msg.sender,
            isActive: true
        }));
        emit BidPlaced(tokenId, nextBidId - 1, bidPrice, msg.sender);
    }

    function acceptBid(uint256 tokenId, uint256 bidId) public onlyOwnerOf(tokenId) whenNotPaused {
        require(ownerOf[tokenId] == msg.sender, "Only owner can accept bids");
        Bid storage bidToAccept;
        bool foundBid = false;
        for (uint256 i = 0; i < bids[tokenId].length; i++) {
            if (bids[tokenId][i].bidId == bidId && bids[tokenId][i].isActive) {
                bidToAccept = bids[tokenId][i];
                foundBid = true;
                break;
            }
        }
        require(foundBid, "Bid not found or inactive");

        // Calculate marketplace fee and royalty
        uint256 marketplaceFee = (bidToAccept.bidPrice * marketplaceFeePercentage) / 100;
        uint256 royaltyFee = _calculateRoyalty(tokenId, bidToAccept.bidPrice - marketplaceFee);
        uint256 sellerProceeds = bidToAccept.bidPrice - marketplaceFee - royaltyFee;

        // Transfer funds
        payable(msg.sender).transfer(sellerProceeds); // Seller receives bid amount
        payable(admin).transfer(marketplaceFee); // Marketplace fee
        _payRoyalty(tokenId, royaltyFee); // Royalty payment

        // Transfer NFT ownership
        _transferNFT(tokenId, bidToAccept.bidder, msg.sender);

        // Deactivate all bids for this tokenId
        for (uint256 i = 0; i < bids[tokenId].length; i++) {
            bids[tokenId][i].isActive = false;
        }

        emit BidAccepted(tokenId, bidId, msg.sender, bidToAccept.bidder, bidToAccept.bidPrice);
    }

    function cancelBid(uint256 tokenId, uint256 bidId) public whenNotPaused {
        Bid storage bidToCancel;
        bool foundBid = false;
        for (uint256 i = 0; i < bids[tokenId].length; i++) {
            if (bids[tokenId][i].bidId == bidId && bids[tokenId][i].bidder == msg.sender && bids[tokenId][i].isActive) {
                bidToCancel = bids[tokenId][i];
                foundBid = true;
                break;
            }
        }
        require(foundBid, "Bid not found, not yours, or already inactive");

        bidToCancel.isActive = false; // Mark bid as inactive
        emit BidCancelled(tokenId, bidId, msg.sender);
    }

    function getListingDetails(uint256 tokenId) public view returns (uint256 price, address seller, bool isListed) {
        Listing memory listing = listings[tokenId];
        return (listing.price, listing.seller, listing.isListed);
    }

    function getBidDetails(uint256 tokenId, uint256 bidId) public view returns (uint256 bidPrice, address bidder, bool isActive) {
        for (uint256 i = 0; i < bids[tokenId].length; i++) {
            if (bids[tokenId][i].bidId == bidId) {
                return (bids[tokenId][i].bidPrice, bids[tokenId][i].bidder, bids[tokenId][i].isActive);
            }
        }
        revert("Bid not found");
    }


    // --- 3. Advanced Marketplace Features ---

    function rentNFT(uint256 tokenId, uint256 rentalPrice, uint256 rentalDuration) public onlyOwnerOf(tokenId) whenNotPaused {
        require(rentalPrice > 0, "Rental price must be greater than zero");
        require(rentalDuration > 0, "Rental duration must be greater than zero");
        require(!listings[tokenId].isListed, "NFT is listed for sale, cannot be rented");
        require(!rentals[tokenId].isActive, "NFT is already being rented");

        rentals[tokenId] = Rental({
            rentalPrice: rentalPrice,
            renter: msg.sender, // Owner is renting to themselves initially, actual renter will pay
            rentalEndTime: block.timestamp + rentalDuration,
            isActive: true
        });
    }

    function endRental(uint256 tokenId) public whenNotPaused {
        require(rentals[tokenId].isActive, "NFT is not being rented");
        require(msg.sender == rentals[tokenId].renter || msg.sender == ownerOf[tokenId] || block.timestamp >= rentals[tokenId].rentalEndTime, "Only renter, owner or after rental end can end rental");

        delete rentals[tokenId]; // Reset rental to default struct values
        emit RentalEnded(tokenId, rentals[tokenId].renter); // Emit event with old renter for record
    }

    function setRoyaltyTier(uint256 tokenId, uint8 tier) public onlyAdmin {
        require(tier <= 3, "Invalid royalty tier, max tier is 3"); // Example: 3 tiers
        royaltyTiers[tokenId] = tier;
        emit RoyaltyTierSet(tokenId, tier);
    }

    function getRoyaltyInfo(uint256 tokenId) public view returns (uint8 tier, uint256 percentage) {
        tier = royaltyTiers[tokenId];
        percentage = _getRoyaltyPercentage(tier);
    }

    function withdrawMarketplaceFees() public onlyAdmin {
        uint256 balance = address(this).balance;
        payable(admin).transfer(balance);
    }


    // --- 4. Reputation & Governance Features ---

    function reportUser(address user, string memory reason) public whenNotPaused {
        require(user != msg.sender, "Cannot report yourself");
        userReports[user].push(Report({
            reporter: msg.sender,
            reason: reason,
            timestamp: block.timestamp
        }));
        // Basic reputation update upon reporting - could be more sophisticated
        userReputation[user]--; // Decrease reputation upon being reported
        userReputation[msg.sender]++; // Increase reporter's reputation (to encourage reporting, but needs balancing)
        emit UserReported(user, msg.sender, reason);
    }

    function voteToSuspendUser(address user) public whenNotPaused {
        // Basic governance - anyone can "vote", in a real system, voting power would be based on token holdings
        // For simplicity, first 10 votes suspend user. Could be more complex voting logic.
        // In production, implement proper governance with token voting.
        uint256 suspensionVotes = 0;
        for (uint256 i = 0; i < userReports[user].length; i++) {
            // Simple vote: consider each report as a vote to suspend (could be weighted votes)
            suspensionVotes++;
        }

        if (suspensionVotes >= 10 && !suspendedUsers[user]) { // Example: 10 reports needed for suspension
            suspendedUsers[user] = true;
            emit UserSuspended(user);
        } else {
            emit UserSuspensionVoteStarted(user); // Event even if suspension not yet reached
        }
    }

    function getUserReputation(address user) public view returns (uint256) {
        return userReputation[user];
    }

    function setMarketplaceFee(uint256 newFee) public onlyAdmin {
        require(newFee <= 100, "Fee percentage cannot exceed 100%");
        marketplaceFeePercentage = newFee;
        emit MarketplaceFeeUpdated(newFee);
    }

    function pauseMarketplace() public onlyAdmin {
        paused = true;
        emit MarketplacePaused();
    }

    function unpauseMarketplace() public onlyAdmin {
        paused = false;
        emit MarketplaceUnpaused();
    }


    // --- Internal Helper Functions ---

    function _transferNFT(uint256 tokenId, address to, address from) internal {
        ownerOf[tokenId] = to;
        balanceOf[from]--;
        balanceOf[to]++;
        // No transfer event emitted here, as it's part of buy/acceptBid - events are emitted in those functions.
    }

    function _calculateRoyalty(uint256 tokenId, uint256 salePrice) internal view returns (uint256) {
        uint8 tier = royaltyTiers[tokenId];
        uint256 royaltyPercentage = _getRoyaltyPercentage(tier);
        return (salePrice * royaltyPercentage) / 100;
    }

    function _getRoyaltyPercentage(uint8 tier) internal pure returns (uint256) {
        if (tier == 1) {
            return 2; // 2% royalty for Tier 1
        } else if (tier == 2) {
            return 5; // 5% royalty for Tier 2
        } else if (tier == 3) {
            return 10; // 10% royalty for Tier 3
        } else {
            return 0; // No royalty for Tier 0 or invalid tier
        }
    }

    function _payRoyalty(uint256 tokenId, uint256 royaltyAmount) internal {
        // In a real application, you would have logic to determine who the royalty recipient is
        // (e.g., original creator, previous owner, etc.) and send the royalty payment to them.
        // For simplicity, this example just sends the royalty to the admin address.
        if (royaltyAmount > 0) {
            payable(admin).transfer(royaltyAmount); // Placeholder - send royalty to admin for now
        }
    }
}

// --- Helper library for string conversion ---
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```