```solidity
/**
 * @title Decentralized Dynamic NFT Marketplace with AI Art Generation & Fractional Ownership
 * @author Bard (AI Assistant)
 * @dev A sophisticated smart contract encompassing dynamic NFTs, AI-inspired art generation (simulated),
 *      fractional ownership, a robust marketplace with auctions and offers, and a reputation system.
 *
 * **Outline:**
 * 1. **DynamicNFT Contract:** Manages dynamic NFTs with evolving metadata, influenced by simulated AI art styles.
 * 2. **AIArtGenerator Contract:** Simulates AI art style generation (randomly for demonstration). In a real-world scenario, this would be an off-chain AI service.
 * 3. **Marketplace Contract:** Handles NFT listings, sales, auctions, offers, and platform fees.
 * 4. **FractionalOwnership Contract:** Enables fractionalization of NFTs and trading of fractional shares.
 * 5. **Reputation Contract:** Tracks user reputation based on marketplace interactions.
 * 6. **Governance Contract (Simplified):**  Allows for basic platform parameter adjustments through voting (e.g., platform fees).
 *
 * **Function Summary (20+ Functions):**
 *
 * **DynamicNFT Contract:**
 *   1. `createDynamicNFT(string initialName, string initialDescription)`: Mints a new dynamic NFT with initial metadata.
 *   2. `updateNFTMetadata(uint256 tokenId, string newName, string newDescription)`: Updates the metadata of an NFT.
 *   3. `evolveNFTArtStyle(uint256 tokenId)`: Triggers simulated AI art style evolution for an NFT.
 *   4. `getNFTMetadata(uint256 tokenId)`: Retrieves the current metadata of an NFT.
 *   5. `tokenURI(uint256 tokenId)`: Returns the dynamic token URI based on current metadata and art style.
 *   6. `transferNFT(address to, uint256 tokenId)`: Transfers ownership of an NFT.
 *   7. `approveNFT(address approved, uint256 tokenId)`: Approves an address to operate on a single NFT.
 *   8. `getApprovedNFT(uint256 tokenId)`: Gets the approved address for an NFT.
 *   9. `setApprovalForAllNFT(address operator, bool approved)`: Enables/disables approval for all NFTs for an operator.
 *   10. `isApprovedForAllNFT(address owner, address operator)`: Checks if an operator is approved for all NFTs of an owner.
 *   11. `ownerOfNFT(uint256 tokenId)`: Returns the owner of an NFT.
 *
 * **AIArtGenerator Contract:**
 *   12. `generateArtStyle(uint256 tokenId)`: Simulates AI art style generation and returns a style ID (randomly chosen for demo).
 *   13. `getArtStyleName(uint256 styleId)`: Returns the name of an art style based on its ID.
 *
 * **Marketplace Contract:**
 *   14. `listItem(uint256 tokenId, uint256 price)`: Lists an NFT for sale on the marketplace.
 *   15. `buyItem(uint256 itemId)`: Purchases an NFT listed on the marketplace.
 *   16. `unlistItem(uint256 itemId)`: Removes an NFT listing from the marketplace.
 *   17. `createAuction(uint256 tokenId, uint256 startingBid, uint256 auctionDuration)`: Creates an auction for an NFT.
 *   18. `bidOnAuction(uint256 auctionId)`: Places a bid on an active auction.
 *   19. `finalizeAuction(uint256 auctionId)`: Ends an auction and transfers NFT to the highest bidder.
 *   20. `makeOffer(uint256 tokenId, uint256 offerPrice)`: Makes an offer on an NFT not currently listed.
 *   21. `acceptOffer(uint256 offerId)`: Accepts a specific offer on an NFT.
 *   22. `cancelOffer(uint256 offerId)`: Cancels an offer that was made.
 *   23. `setPlatformFee(uint256 feePercentage)`: (Governance controlled) Sets the platform fee percentage.
 *   24. `withdrawPlatformFees()`: (Admin function) Withdraws accumulated platform fees.
 *
 * **FractionalOwnership Contract:**
 *   25. `fractionalizeNFT(uint256 tokenId, uint256 numberOfFractions)`: Fractionalizes an NFT into a specified number of fractional tokens.
 *   26. `buyFractionalToken(uint256 fractionId, uint256 amount)`: Buys fractional tokens.
 *   27. `sellFractionalToken(uint256 fractionId, uint256 amount)`: Sells fractional tokens.
 *   28. `redeemNFT(uint256 fractionId)`: Allows holders of all fractional tokens to redeem the original NFT (complex governance/voting could be added).
 *
 * **Reputation Contract:**
 *   29. `reportUser(address userToReport, string reason)`: Allows users to report other users for misconduct.
 *   30. `getReputationScore(address user)`: Returns the reputation score of a user (simplified - can be enhanced with more sophisticated logic).
 *
 * **Governance Contract (Simplified):**
 *   31. `proposePlatformFeeChange(uint256 newFeePercentage)`: Allows governance to propose a change to the platform fee.
 *   32. `voteOnProposal(uint256 proposalId, bool support)`: Allows token holders to vote on a governance proposal.
 *   33. `executeProposal(uint256 proposalId)`: Executes a successful governance proposal.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// ----------------------------------------------------------------------------
// DynamicNFT Contract
// ----------------------------------------------------------------------------
contract DynamicNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct NFTMetadata {
        string name;
        string description;
        uint256 artStyleId; // Reference to AIArtGenerator style
        uint256 lastEvolvedTimestamp;
    }

    mapping(uint256 => NFTMetadata) public nftMetadata;
    AIArtGenerator public aiArtGenerator;

    event NFTCreated(uint256 tokenId, address creator, string initialName);
    event NFTMetadataUpdated(uint256 tokenId, string newName, string newDescription);
    event NFTArtStyleEvolved(uint256 tokenId, uint256 newArtStyleId);

    constructor(string memory _name, string memory _symbol, address _aiArtGeneratorAddress) ERC721(_name, _symbol) {
        aiArtGenerator = AIArtGenerator(_aiArtGeneratorAddress);
    }

    function createDynamicNFT(string memory initialName, string memory initialDescription) public returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);

        nftMetadata[newItemId] = NFTMetadata({
            name: initialName,
            description: initialDescription,
            artStyleId: 0, // Default style or could be randomly assigned initially
            lastEvolvedTimestamp: block.timestamp
        });

        emit NFTCreated(newItemId, msg.sender, initialName);
        return newItemId;
    }

    function updateNFTMetadata(uint256 tokenId, string memory newName, string memory newDescription) public onlyOwnerOf(tokenId) {
        nftMetadata[tokenId].name = newName;
        nftMetadata[tokenId].description = newDescription;
        emit NFTMetadataUpdated(tokenId, newName, newDescription);
    }

    function evolveNFTArtStyle(uint256 tokenId) public onlyOwnerOf(tokenId) {
        require(block.timestamp >= nftMetadata[tokenId].lastEvolvedTimestamp + 1 days, "Evolve cooldown not reached yet"); // Evolve cooldown

        uint256 newArtStyleId = aiArtGenerator.generateArtStyle(tokenId);
        nftMetadata[tokenId].artStyleId = newArtStyleId;
        nftMetadata[tokenId].lastEvolvedTimestamp = block.timestamp;
        emit NFTArtStyleEvolved(tokenId, newArtStyleId);
    }

    function getNFTMetadata(uint256 tokenId) public view returns (NFTMetadata memory) {
        return nftMetadata[tokenId];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "NFT does not exist");
        NFTMetadata memory metadata = nftMetadata[tokenId];
        string memory styleName = aiArtGenerator.getArtStyleName(metadata.artStyleId);

        // Construct a dynamic JSON metadata string (example - in real use IPFS for metadata storage)
        string memory jsonMetadata = string(abi.encodePacked(
            '{"name": "', metadata.name, '", ',
            '"description": "', metadata.description, '", ',
            '"image": "ipfs://your-ipfs-hash-for-style-', styleName, '-token-', Strings.toString(tokenId), '.png", ', // Example IPFS link
            '"attributes": [',
                '{"trait_type": "Art Style", "value": "', styleName, '"},',
                '{"trait_type": "Evolved At", "value": "', Strings.toString(metadata.lastEvolvedTimestamp), '"}',
            ']}'
        ));

        string memory base64Json = Base64.encode(bytes(jsonMetadata));
        return string(abi.encodePacked("data:application/json;base64,", base64Json));
    }

    modifier onlyOwnerOf(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
        _;
    }

    // Override _beforeTokenTransfer to potentially add logic before transfers if needed
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
        // Add any custom logic before transfer here if needed (e.g., trigger events)
    }

    // Standard ERC721 functions are inherited and available:
    // - transferNFT (using safeTransferFrom and transferFrom)
    // - approveNFT (approve)
    // - getApprovedNFT (getApproved)
    // - setApprovalForAllNFT (setApprovalForAll)
    // - isApprovedForAllNFT (isApprovedForAll)
    // - ownerOfNFT (ownerOf)
}

// ----------------------------------------------------------------------------
// AIArtGenerator Contract (Simulated)
// ----------------------------------------------------------------------------
contract AIArtGenerator {
    string[] public artStyleNames = ["Abstract", "Impressionist", "Cyberpunk", "Surrealist", "Minimalist"];

    function generateArtStyle(uint256 tokenId) public returns (uint256) {
        // In a real application, this would interact with an off-chain AI art generation service.
        // For this example, we simulate by randomly choosing a style.
        uint256 styleIndex = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId))) % artStyleNames.length;
        return styleIndex;
    }

    function getArtStyleName(uint256 styleId) public view returns (string memory) {
        require(styleId < artStyleNames.length, "Invalid art style ID");
        return artStyleNames[styleId];
    }
}

// ----------------------------------------------------------------------------
// Marketplace Contract
// ----------------------------------------------------------------------------
contract Marketplace is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _auctionIds;
    Counters.Counter private _offerIds;

    struct MarketItem {
        uint256 itemId;
        uint256 tokenId;
        address nftContract;
        address seller;
        uint256 price;
        bool sold;
    }

    struct Auction {
        uint256 auctionId;
        uint256 itemId; // MarketItem ID of the auctioned NFT
        uint256 tokenId;
        address nftContract;
        address seller;
        uint256 startingBid;
        uint256 highestBid;
        address highestBidder;
        uint256 auctionEndTime;
        bool finalized;
    }

    struct Offer {
        uint256 offerId;
        uint256 tokenId;
        address nftContract;
        address offerer;
        uint256 offerPrice;
        bool accepted;
        bool cancelled;
    }

    mapping(uint256 => MarketItem) public marketItems;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => Offer) public offers;
    mapping(uint256 => uint256) public itemToAuctionId; // Map MarketItem to Auction ID if auctioned

    uint256 public platformFeePercentage = 2; // 2% platform fee
    address payable public platformFeeRecipient;

    event ItemListed(uint256 itemId, uint256 tokenId, address nftContract, address seller, uint256 price);
    event ItemSold(uint256 itemId, uint256 tokenId, address nftContract, address buyer, uint256 price);
    event ItemUnlisted(uint256 itemId);
    event AuctionCreated(uint256 auctionId, uint256 itemId, uint256 tokenId, address nftContract, address seller, uint256 startingBid, uint256 auctionEndTime);
    event BidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionFinalized(uint256 auctionId, address winner, uint256 finalPrice);
    event OfferMade(uint256 offerId, uint256 tokenId, address nftContract, address offerer, uint256 offerPrice);
    event OfferAccepted(uint256 offerId, uint256 itemId, address buyer, address seller, uint256 price);
    event OfferCancelled(uint256 offerId);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address recipient);


    constructor(address payable _platformFeeRecipient) Ownable() {
        platformFeeRecipient = _platformFeeRecipient;
    }

    modifier itemExists(uint256 itemId) {
        require(marketItems[itemId].itemId != 0, "Market item does not exist");
        _;
    }

    modifier auctionExists(uint256 auctionId) {
        require(auctions[auctionId].auctionId != 0, "Auction does not exist");
        _;
    }

    modifier offerExists(uint256 offerId) {
        require(offers[offerId].offerId != 0, "Offer does not exist");
        _;
    }

    modifier notSold(uint256 itemId) {
        require(!marketItems[itemId].sold, "Item already sold");
        _;
    }

    modifier notFinalized(uint256 auctionId) {
        require(!auctions[auctionId].finalized, "Auction already finalized");
        _;
    }

    function listItem(uint256 tokenId, uint256 price, address nftContractAddress) public nonReentrant {
        require(price > 0, "Price must be greater than zero");

        IERC721 nftContract = IERC721(nftContractAddress);
        require(nftContract.ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
        nftContract.approve(address(this), tokenId); // Approve marketplace to transfer NFT

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        marketItems[itemId] = MarketItem({
            itemId: itemId,
            tokenId: tokenId,
            nftContract: nftContractAddress,
            seller: msg.sender,
            price: price,
            sold: false
        });

        emit ItemListed(itemId, tokenId, nftContractAddress, msg.sender, price);
    }

    function buyItem(uint256 itemId) public payable nonReentrant itemExists(notSold(itemId)) {
        MarketItem storage item = marketItems[itemId];
        require(msg.value >= item.price, "Insufficient funds to buy item");

        uint256 platformFee = (item.price * platformFeePercentage) / 100;
        uint256 sellerPayout = item.price - platformFee;

        item.sold = true;
        IERC721(item.nftContract).safeTransferFrom(item.seller, msg.sender, item.tokenId);

        payable(item.seller).transfer(sellerPayout);
        platformFeeRecipient.transfer(platformFee);

        emit ItemSold(itemId, item.tokenId, item.nftContract, msg.sender, item.price);
    }

    function unlistItem(uint256 itemId) public itemExists(notSold(itemId)) {
        MarketItem storage item = marketItems[itemId];
        require(item.seller == msg.sender, "You are not the seller of this item");

        delete marketItems[itemId]; // Remove from marketplace listing
        emit ItemUnlisted(itemId);
    }

    function createAuction(uint256 tokenId, uint256 startingBid, uint256 auctionDuration, address nftContractAddress) public nonReentrant {
        require(startingBid > 0, "Starting bid must be greater than zero");
        require(auctionDuration > 0 && auctionDuration <= 7 days, "Auction duration must be between 1 second and 7 days"); // Limit auction duration

        IERC721 nftContract = IERC721(nftContractAddress);
        require(nftContract.ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
        nftContract.approve(address(this), tokenId); // Approve marketplace to transfer NFT

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        _auctionIds.increment();
        uint256 auctionId = _auctionIds.current();

        marketItems[itemId] = MarketItem({ // Create a market item for auction tracking
            itemId: itemId,
            tokenId: tokenId,
            nftContract: nftContractAddress,
            seller: msg.sender,
            price: 0, // Price not relevant for auction
            sold: false
        });
        itemToAuctionId[itemId] = auctionId; // Link item to auction

        auctions[auctionId] = Auction({
            auctionId: auctionId,
            itemId: itemId,
            tokenId: tokenId,
            nftContract: nftContractAddress,
            seller: msg.sender,
            startingBid: startingBid,
            highestBid: startingBid,
            highestBidder: address(0), // No bidder initially
            auctionEndTime: block.timestamp + auctionDuration,
            finalized: false
        });

        emit AuctionCreated(auctionId, itemId, tokenId, nftContractAddress, msg.sender, startingBid, block.timestamp + auctionDuration);
    }

    function bidOnAuction(uint256 auctionId) public payable nonReentrant auctionExists(notFinalized(auctionId)) {
        Auction storage auction = auctions[auctionId];
        require(block.timestamp < auction.auctionEndTime, "Auction has ended");
        require(msg.value >= auction.highestBid, "Bid amount is not high enough");

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid); // Refund previous highest bidder
        }

        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;

        emit BidPlaced(auctionId, msg.sender, msg.value);
    }

    function finalizeAuction(uint256 auctionId) public nonReentrant auctionExists(notFinalized(auctionId)) {
        Auction storage auction = auctions[auctionId];
        require(block.timestamp >= auction.auctionEndTime, "Auction is not yet ended");

        auction.finalized = true;
        MarketItem storage item = marketItems[auction.itemId];
        item.sold = true; // Mark item as sold through auction

        if (auction.highestBidder != address(0)) {
            uint256 platformFee = (auction.highestBid * platformFeePercentage) / 100;
            uint256 sellerPayout = auction.highestBid - platformFee;

            IERC721(auction.nftContract).safeTransferFrom(auction.seller, auction.highestBidder, auction.tokenId);
            payable(auction.seller).transfer(sellerPayout);
            platformFeeRecipient.transfer(platformFee);

            emit AuctionFinalized(auctionId, auction.highestBidder, auction.highestBid);
            emit ItemSold(item.itemId, item.tokenId, item.nftContract, auction.highestBidder, auction.highestBid); // Emit ItemSold for auction completion
        } else {
            // No bids, return NFT to seller (optional behavior - could also keep it in marketplace)
            IERC721(auction.nftContract).transferFrom(address(this), auction.seller, auction.tokenId);
             emit AuctionFinalized(auctionId, address(0), 0); // No winner
        }
    }

    function makeOffer(uint256 tokenId, uint256 offerPrice, address nftContractAddress) public nonReentrant {
        require(offerPrice > 0, "Offer price must be greater than zero");

        IERC721 nftContract = IERC721(nftContractAddress);
        address owner = nftContract.ownerOf(tokenId);
        require(owner != address(0), "NFT does not exist");
        require(owner != msg.sender, "Cannot make offer on your own NFT");

        _offerIds.increment();
        uint256 offerId = _offerIds.current();

        offers[offerId] = Offer({
            offerId: offerId,
            tokenId: tokenId,
            nftContract: nftContractAddress,
            offerer: msg.sender,
            offerPrice: offerPrice,
            accepted: false,
            cancelled: false
        });

        emit OfferMade(offerId, tokenId, nftContractAddress, msg.sender, offerPrice);
    }

    function acceptOffer(uint256 offerId) public payable nonReentrant offerExists(offerId) {
        Offer storage offer = offers[offerId];
        require(!offer.accepted && !offer.cancelled, "Offer is not active");

        IERC721 nftContract = IERC721(offer.nftContract);
        require(nftContract.ownerOf(offer.tokenId) == msg.sender, "You are not the owner of this NFT");
        require(msg.value >= offer.offerPrice, "Insufficient funds to accept offer");

        uint256 platformFee = (offer.offerPrice * platformFeePercentage) / 100;
        uint256 sellerPayout = offer.offerPrice - platformFee;

        offer.accepted = true;
        IERC721(offer.nftContract).safeTransferFrom(msg.sender, offer.offerer, offer.tokenId);

        payable(msg.sender).transfer(sellerPayout);
        platformFeeRecipient.transfer(platformFee);

        // Create a MarketItem record to track offer acceptance (optional, for marketplace history)
        _itemIds.increment();
        uint256 itemId = _itemIds.current();
        marketItems[itemId] = MarketItem({
            itemId: itemId,
            tokenId: offer.tokenId,
            nftContract: offer.nftContract,
            seller: msg.sender,
            price: offer.offerPrice,
            sold: true
        });

        emit OfferAccepted(offerId, itemId, offer.offerer, msg.sender, offer.offerPrice);
        emit ItemSold(itemId, offer.tokenId, offer.nftContract, offer.offerer, offer.offerPrice); // Emit ItemSold for offer acceptance
    }

    function cancelOffer(uint256 offerId) public offerExists(offerId) {
        Offer storage offer = offers[offerId];
        require(offer.offerer == msg.sender, "Only offerer can cancel offer");
        require(!offer.accepted && !offer.cancelled, "Offer is not active");

        offer.cancelled = true;
        emit OfferCancelled(offerId);
    }

    // Governance/Admin Functions

    function setPlatformFee(uint256 feePercentage) public onlyOwner {
        require(feePercentage <= 10, "Platform fee percentage too high (max 10%)"); // Example limit
        platformFeePercentage = feePercentage;
        emit PlatformFeeSet(feePercentage);
    }

    function withdrawPlatformFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No platform fees to withdraw");
        platformFeeRecipient.transfer(balance);
        emit PlatformFeesWithdrawn(balance, platformFeeRecipient);
    }
}


// ----------------------------------------------------------------------------
// FractionalOwnership Contract
// ----------------------------------------------------------------------------
contract FractionalOwnership is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _fractionIds;

    struct FractionalNFT {
        uint256 fractionId;
        uint256 tokenId;
        address nftContract;
        uint256 totalSupply; // Total supply of fractional tokens
        mapping(address => uint256) balances; // Balances of fractional tokens
        address originalNFTContract; // Address of the original DynamicNFT or ERC721 contract
    }

    mapping(uint256 => FractionalNFT) public fractionalNFTs;
    mapping(uint256 => bool) public isFractionalized; // Track if an NFT is fractionalized

    event NFTFractionalized(uint256 fractionId, uint256 tokenId, address nftContract, uint256 numberOfFractions);
    event FractionalTokenBought(uint256 fractionId, address buyer, uint256 amount);
    event FractionalTokenSold(uint256 fractionId, address seller, uint256 amount);
    event NFTRedeemed(uint256 fractionId, address redeemer, uint256 tokenId, address nftContract);


    function fractionalizeNFT(uint256 tokenId, uint256 numberOfFractions, address nftContractAddress) public nonReentrant {
        require(numberOfFractions > 1 && numberOfFractions <= 10000, "Number of fractions must be between 2 and 10000"); // Example fraction limit

        IERC721 nftContract = IERC721(nftContractAddress);
        require(nftContract.ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
        require(!isFractionalized[tokenId], "NFT is already fractionalized");

        nftContract.approve(address(this), tokenId); // Approve FractionalOwnership contract to handle NFT

        _fractionIds.increment();
        uint256 fractionId = _fractionIds.current();

        fractionalNFTs[fractionId] = FractionalNFT({
            fractionId: fractionId,
            tokenId: tokenId,
            nftContract: nftContractAddress,
            totalSupply: numberOfFractions,
            originalNFTContract: nftContractAddress // Storing original NFT contract address
        });
        isFractionalized[tokenId] = true;

        fractionalNFTs[fractionId].balances[msg.sender] = numberOfFractions; // Give all fractions to fractionalizer initially

        emit NFTFractionalized(fractionId, tokenId, nftContractAddress, numberOfFractions);
    }

    function buyFractionalToken(uint256 fractionId, uint256 amount) public payable nonReentrant {
        FractionalNFT storage fraction = fractionalNFTs[fractionId];
        require(fraction.fractionId != 0, "Fractional NFT does not exist");
        require(amount > 0, "Amount must be greater than zero");

        // Example: Simple pricing - fixed price per fractional token (can be more dynamic)
        uint256 pricePerToken = 0.001 ether; // Example price, adjust as needed
        uint256 totalPrice = amount * pricePerToken;
        require(msg.value >= totalPrice, "Insufficient funds to buy fractional tokens");

        fraction.balances[msg.sender] += amount;
        fraction.balances[tx.origin] -= amount; // Assuming tokens are sold by the contract itself (can be modified for P2P selling)

        payable(owner()).transfer(totalPrice); // Send funds to contract owner for simplicity (adjust as needed for sellers in P2P model)

        emit FractionalTokenBought(fractionId, msg.sender, amount);
    }


    function sellFractionalToken(uint256 fractionId, uint256 amount) public nonReentrant {
        FractionalNFT storage fraction = fractionalNFTs[fractionId];
        require(fraction.fractionId != 0, "Fractional NFT does not exist");
        require(amount > 0, "Amount must be greater than zero");
        require(fraction.balances[msg.sender] >= amount, "Insufficient fractional tokens to sell");

         // Example: Simple pricing - fixed price per fractional token (can be more dynamic)
        uint256 pricePerToken = 0.0009 ether; // Slightly lower price for selling back
        uint256 totalPrice = amount * pricePerToken;

        fraction.balances[msg.sender] -= amount;
        fraction.balances[address(this)] += amount; // Contract holds tokens it buys back

        payable(msg.sender).transfer(totalPrice);

        emit FractionalTokenSold(fractionId, msg.sender, amount);
    }


    function redeemNFT(uint256 fractionId) public nonReentrant {
        FractionalNFT storage fraction = fractionalNFTs[fractionId];
        require(fraction.fractionId != 0, "Fractional NFT does not exist");

        uint256 holderBalance = fraction.balances[msg.sender];
        require(holderBalance == fraction.totalSupply, "You do not hold all fractional tokens to redeem");

        // Transfer the original NFT back to the redeemer
        IERC721(fraction.originalNFTContract).safeTransferFrom(address(this), msg.sender, fraction.tokenId); // Contract should hold the original NFT after fractionalization (implementation detail to add)

        // Burn/invalidate fractional tokens (or manage supply in a way that makes them unusable)
        fraction.balances[msg.sender] = 0; // Zero out balance
        isFractionalized[fraction.tokenId] = false; // Mark as no longer fractionalized (optional - can keep fractionalization record)

        emit NFTRedeemed(fractionId, msg.sender, fraction.tokenId, fraction.originalNFTContract);
    }

    function getFractionalTokenBalance(uint256 fractionId, address account) public view returns (uint256) {
        return fractionalNFTs[fractionId].balances[account];
    }
}


// ----------------------------------------------------------------------------
// Reputation Contract (Simplified)
// ----------------------------------------------------------------------------
contract Reputation is Ownable {
    mapping(address => uint256) public reputationScores;
    mapping(address => uint256) public reportCounts; // Track reports against users

    event UserReported(address reporter, address reportedUser, string reason);
    event ReputationScoreUpdated(address user, uint256 newScore);

    constructor() Ownable() {}

    function reportUser(address userToReport, string memory reason) public {
        require(userToReport != msg.sender, "Cannot report yourself");
        require(reportCounts[userToReport] < 100, "User already heavily reported"); // Example report limit

        reportCounts[userToReport]++;
        reputationScores[userToReport] = reputationScores[userToReport] > 0 ? reputationScores[userToReport] - 1 : 0; // Decrease score, but not below 0

        emit UserReported(msg.sender, userToReport, reason);
        emit ReputationScoreUpdated(userToReport, reputationScores[userToReport]);
    }

    function getReputationScore(address user) public view returns (uint256) {
        return reputationScores[user];
    }

    // Admin function to manually adjust reputation (for dispute resolution, etc.)
    function adjustReputationScore(address user, int256 scoreChange) public onlyOwner {
        if (scoreChange > 0) {
            reputationScores[user] += uint256(scoreChange);
        } else if (scoreChange < 0) {
            int256 currentScore = int256(reputationScores[user]);
            int256 newScore = currentScore + scoreChange; // scoreChange is negative
            reputationScores[user] = uint256(max(0, newScore)); // Ensure score doesn't go below 0
        }
        emit ReputationScoreUpdated(user, reputationScores[user]);
    }

    function max(uint256 a, int256 b) private pure returns (uint256) {
        return a > uint256(b) ? a : uint256(max(0,b));
    }
     function max(int256 a, int256 b) private pure returns (int256) {
        return a > b ? a : b;
    }
}


// ----------------------------------------------------------------------------
// Governance Contract (Simplified - Token Voting Example)
// ----------------------------------------------------------------------------
contract Governance is Ownable {
    struct Proposal {
        uint256 proposalId;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 platformFeeToSet; // Example parameter to govern
    }

    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIds;

    event ProposalCreated(uint256 proposalId, string description);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);

    Marketplace public marketplace; // Governance controls Marketplace parameters

    constructor(address _marketplaceAddress) Ownable() {
        marketplace = Marketplace(_marketplaceAddress);
    }

    modifier proposalExists(uint256 proposalId) {
        require(proposals[proposalId].proposalId != 0, "Proposal does not exist");
        _;
    }

    modifier notExecuted(uint256 proposalId) {
        require(!proposals[proposalId].executed, "Proposal already executed");
        _;
    }


    function proposePlatformFeeChange(string memory description, uint256 newFeePercentage) public onlyOwner {
        require(newFeePercentage <= 10, "Proposed platform fee percentage too high (max 10%)"); // Example limit

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            description: description,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            platformFeeToSet: newFeePercentage
        });

        emit ProposalCreated(proposalId, description);
    }

    function voteOnProposal(uint256 proposalId, bool support) public proposalExists(notExecuted(proposalId)) {
        Proposal storage proposal = proposals[proposalId];

        // In a real governance system, voting power would be based on token holdings (ERC20/721 tokens)
        // For simplicity, in this example, every address has equal voting power.

        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit VoteCast(proposalId, msg.sender, support);
    }

    function executeProposal(uint256 proposalId) public onlyOwner proposalExists(notExecuted(proposalId)) {
        Proposal storage proposal = proposals[proposalId];

        // Example: Simple majority vote - can be adjusted based on governance rules
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "No votes cast on proposal");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass"); // Simple majority

        marketplace.setPlatformFee(proposal.platformFeeToSet); // Execute the platform fee change
        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }

    function getProposalDetails(uint256 proposalId) public view proposalExists(proposalId) returns (Proposal memory) {
        return proposals[proposalId];
    }
}


// --- Utility Library for Base64 Encoding ---
library Base64 {
    string internal constant ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory alphabet = ALPHABET;

        uint256 encodedLen = 4 * ((data.length + 2) / 3); // Equivalent to ceil(length / 3) * 4
        string memory result = new string(encodedLen);

        assembly {
            let dataPtr := add(data, 32) // Skip data length prefix
            let endPtr := add(dataPtr, mload(data))

            let resultPtr := add(result, 32) // Skip string length prefix

            // The main loop processes 3 input bytes at a time
            loop:
                jumpi(done, iszero(lt(dataPtr, endPtr)))

                // Read 3 bytes from data
                let b1 := mload(dataPtr)
                dataPtr := add(dataPtr, 1)
                let b2 := mload(dataPtr)
                dataPtr := add(dataPtr, 1)
                let b3 := mload(dataPtr)
                dataPtr := add(dataPtr, 1)

                // Encode 3 bytes into 4 characters
                mstore8(resultPtr, mload(add(alphabet, mul(shr(18, b1), 1))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(alphabet, mul(and(shr(12, b1), 0x3F), 1))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(alphabet, mul(and(shr(6, b2), 0x3F), 1))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(alphabet, mul(and(b3, 0x3F), 1))))
                resultPtr := add(resultPtr, 1)

                jump(loop)

            done:
                // Padding if the input length is not a multiple of 3
                switch mod(mload(data), 3)
                case 1 {
                    mstore(sub(resultPtr, 2), shl(16, 0x3d3d)) // '==' padding
                }
                case 2 {
                    mstore(sub(resultPtr, 1), shl(8, 0x3d)) // '=' padding
                }
        }

        return result;
    }
}

library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.5.sol

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

// --- Interfaces ---
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address approved, uint256 tokenId) external;
}
```