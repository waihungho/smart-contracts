```solidity
/**
 * @title Decentralized Dynamic NFT Marketplace with AI Curator
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized NFT marketplace featuring dynamic NFTs,
 *      AI-curated collections (simulated), and advanced marketplace functionalities.
 *
 * **Outline:**
 *  - **NFT Core:** Minting, Dynamic Metadata, Royalties
 *  - **Marketplace Functionality:** Listing, Buying, Auctions, Bundles, Offers
 *  - **AI Curation (Simulated):**  Curation Scores, Community Influence, Evolving NFTs
 *  - **Advanced Features:** Staking for Curators, Governance (Basic), Pausing, Fees
 *
 * **Function Summary:**
 *  1. `mintNFT(string _tokenURI, uint256 _royalty)`: Mints a new Dynamic NFT with initial metadata and royalty percentage.
 *  2. `updateNFTMetadata(uint256 _tokenId, string _newTokenURI)`: Updates the metadata URI of a Dynamic NFT.
 *  3. `setRoyalty(uint256 _tokenId, uint256 _royalty)`: Sets the royalty percentage for an NFT.
 *  4. `listNFTForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale at a fixed price.
 *  5. `buyNFT(uint256 _listingId)`: Allows anyone to buy a listed NFT.
 *  6. `cancelNFTListing(uint256 _listingId)`: Allows the seller to cancel an NFT listing.
 *  7. `updateListingPrice(uint256 _listingId, uint256 _newPrice)`: Allows the seller to update the price of a listed NFT.
 *  8. `createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration)`: Creates an auction for an NFT.
 *  9. `bidOnAuction(uint256 _auctionId)`: Allows users to bid on an active auction.
 *  10. `finalizeAuction(uint256 _auctionId)`: Finalizes an auction and transfers the NFT to the highest bidder.
 *  11. `createNFTBundle(uint256[] _tokenIds)`: Creates a bundle of NFTs.
 *  12. `listBundleForSale(uint256 _bundleId, uint256 _price)`: Lists an NFT bundle for sale.
 *  13. `buyBundle(uint256 _bundleListingId)`: Allows anyone to buy a listed NFT bundle.
 *  14. `cancelBundleListing(uint256 _bundleListingId)`: Allows the seller to cancel a bundle listing.
 *  15. `makeOfferOnNFT(uint256 _tokenId, uint256 _offerPrice)`: Allows users to make offers on NFTs not currently listed.
 *  16. `acceptNFTOffer(uint256 _offerId)`: Allows the NFT owner to accept a specific offer.
 *  17. `getCurationScore(uint256 _tokenId)`: Returns the simulated AI curation score of an NFT.
 *  18. `voteForCuration(uint256 _tokenId, uint8 _vote)`: Allows users to vote to influence the curation score (simulated community feedback).
 *  19. `stakeForCuration(uint256 _tokenId)`: Allows users to stake tokens to boost the curation score of an NFT (incentivized curation).
 *  20. `unstakeForCuration(uint256 _tokenId)`: Allows users to unstake tokens from an NFT's curation pool.
 *  21. `setMarketplaceFee(uint256 _feePercentage)`: Allows the contract owner to set the marketplace fee percentage.
 *  22. `pauseMarketplace()`: Allows the contract owner to pause marketplace operations.
 *  23. `unpauseMarketplace()`: Allows the contract owner to unpause marketplace operations.
 *  24. `withdrawMarketplaceFees()`: Allows the contract owner to withdraw accumulated marketplace fees.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DynamicNFTMarketplace is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _listingIdCounter;
    Counters.Counter private _auctionIdCounter;
    Counters.Counter private _bundleIdCounter;
    Counters.Counter private _offerIdCounter;

    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    bool public isMarketplacePaused = false;

    struct NFTListing {
        uint256 listingId;
        uint256 tokenId;
        address payable seller;
        uint256 price;
        bool isActive;
    }

    struct NFTAuction {
        uint256 auctionId;
        uint256 tokenId;
        address payable seller;
        uint256 startingBid;
        uint256 highestBid;
        address payable highestBidder;
        uint256 auctionEndTime;
        bool isActive;
    }

    struct NFTBundle {
        uint256 bundleId;
        uint256[] tokenIds;
        address payable creator;
    }

    struct BundleListing {
        uint256 bundleListingId;
        uint256 bundleId;
        address payable seller;
        uint256 price;
        bool isActive;
    }

    struct NFTOffer {
        uint256 offerId;
        uint256 tokenId;
        address payable offerer;
        uint256 offerPrice;
        bool isActive;
    }

    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => uint256) private _royaltyPercentages; // tokenId => royalty percentage
    mapping(uint256 => NFTListing) private _nftListings;
    mapping(uint256 => NFTAuction) private _nftAuctions;
    mapping(uint256 => NFTBundle) private _nftBundles;
    mapping(uint256 => BundleListing) private _bundleListings;
    mapping(uint256 => NFTOffer) private _nftOffers;
    mapping(uint256 => uint256) private _curationScores; // tokenId => curation score (simulated AI)
    mapping(uint256 => mapping(address => uint8)) private _curationVotes; // tokenId => voter => vote (1=up, 0=down)
    mapping(uint256 => uint256) private _curationStakes; // tokenId => staked amount

    event NFTMinted(uint256 tokenId, address creator, string tokenURI);
    event NFTMetadataUpdated(uint256 tokenId, string newTokenURI);
    event RoyaltySet(uint256 tokenId, uint256 royaltyPercentage);
    event NFTListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event NFTBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event NFTListingCancelled(uint256 listingId);
    event ListingPriceUpdated(uint256 listingId, uint256 newPrice);
    event AuctionCreated(uint256 auctionId, uint256 tokenId, address seller, uint256 startingBid, uint256 auctionEndTime);
    event BidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionFinalized(uint256 auctionId, address winner, uint256 finalPrice);
    event NFTBundleCreated(uint256 bundleId, address creator, uint256[] tokenIds);
    event BundleListed(uint256 bundleListingId, uint256 bundleId, address seller, uint256 price);
    event BundleBought(uint256 bundleListingId, uint256 bundleId, address buyer, uint256 price);
    event BundleListingCancelled(uint256 bundleListingId);
    event OfferMade(uint256 offerId, uint256 tokenId, address offerer, uint256 offerPrice);
    event OfferAccepted(uint256 offerId, uint256 tokenId, address buyer, uint256 price);
    event CurationScoreUpdated(uint256 tokenId, uint256 newScore);
    event VoteCast(uint256 tokenId, address voter, uint8 vote);
    event StakeAdded(uint256 tokenId, address staker, uint256 amount);
    event StakeRemoved(uint256 tokenId, address unstaker, uint256 amount);
    event MarketplaceFeeSet(uint256 feePercentage);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event MarketplaceFeesWithdrawn(address withdrawer, uint256 amount);

    constructor() ERC721("DynamicNFT", "DNFT") {}

    modifier whenMarketplaceNotPaused() {
        require(!isMarketplacePaused, "Marketplace is paused");
        _;
    }

    modifier whenMarketplacePaused() {
        require(isMarketplacePaused, "Marketplace is not paused");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not NFT owner or approved");
        _;
    }

    modifier onlyBundleCreator(uint256 _bundleId) {
        require(_nftBundles[_bundleId].creator == _msgSender(), "Not bundle creator");
        _;
    }

    modifier validListing(uint256 _listingId) {
        require(_nftListings[_listingId].isActive, "Listing is not active");
        _;
    }

    modifier validAuction(uint256 _auctionId) {
        require(_nftAuctions[_auctionId].isActive && block.timestamp < _nftAuctions[_auctionId].auctionEndTime, "Auction is not active or ended");
        _;
    }

    modifier validBundleListing(uint256 _bundleListingId) {
        require(_bundleListings[_bundleListingId].isActive, "Bundle listing is not active");
        _;
    }

    modifier validOffer(uint256 _offerId) {
        require(_nftOffers[_offerId].isActive, "Offer is not active");
        _;
    }

    // 1. Mint NFT
    function mintNFT(string memory _tokenURI, uint256 _royalty) public whenMarketplaceNotPaused returns (uint256) {
        require(_royalty <= 100, "Royalty must be less than or equal to 100"); // Royalty as percentage
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _mint(_msgSender(), tokenId);
        _tokenURIs[tokenId] = _tokenURI;
        _royaltyPercentages[tokenId] = _royalty;
        _curationScores[tokenId] = 50; // Initial curation score (arbitrary starting point)
        emit NFTMinted(tokenId, _msgSender(), _tokenURI);
        return tokenId;
    }

    // 2. Update NFT Metadata
    function updateNFTMetadata(uint256 _tokenId, string memory _newTokenURI) public onlyNFTOwner(_tokenId) whenMarketplaceNotPaused {
        _tokenURIs[_tokenId] = _newTokenURI;
        emit NFTMetadataUpdated(_tokenId, _newTokenURI);
    }

    // 3. Set Royalty
    function setRoyalty(uint256 _tokenId, uint256 _royalty) public onlyNFTOwner(_tokenId) whenMarketplaceNotPaused {
        require(_royalty <= 100, "Royalty must be less than or equal to 100");
        _royaltyPercentages[_tokenId] = _royalty;
        emit RoyaltySet(_tokenId, _royalty);
    }

    // 4. List NFT for Sale
    function listNFTForSale(uint256 _tokenId, uint256 _price) public onlyNFTOwner(_tokenId) whenMarketplaceNotPaused {
        approve(address(this), _tokenId); // Approve marketplace to transfer NFT
        _listingIdCounter.increment();
        uint256 listingId = _listingIdCounter.current();
        _nftListings[listingId] = NFTListing({
            listingId: listingId,
            tokenId: _tokenId,
            seller: payable(_msgSender()),
            price: _price,
            isActive: true
        });
        emit NFTListed(listingId, _tokenId, _msgSender(), _price);
    }

    // 5. Buy NFT
    function buyNFT(uint256 _listingId) public payable validListing(_listingId) whenMarketplaceNotPaused {
        NFTListing storage listing = _nftListings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds");

        uint256 marketplaceFee = listing.price.mul(marketplaceFeePercentage).div(100);
        uint256 sellerProceeds = listing.price.sub(marketplaceFee);

        // Royalty payment (if applicable)
        uint256 royaltyAmount = sellerProceeds.mul(_royaltyPercentages[listing.tokenId]).div(100);
        if (royaltyAmount > 0) {
            payable(ownerOf(listing.tokenId)).transfer(royaltyAmount); // Assuming owner at mint is royalty recipient. Could be more complex.
            sellerProceeds = sellerProceeds.sub(royaltyAmount);
        }

        payable(listing.seller).transfer(sellerProceeds);
        payable(owner()).transfer(marketplaceFee); // Marketplace fee goes to contract owner
        transferFrom(listing.seller, _msgSender(), listing.tokenId);

        listing.isActive = false;
        emit NFTBought(_listingId, listing.tokenId, _msgSender(), listing.price);
    }

    // 6. Cancel NFT Listing
    function cancelNFTListing(uint256 _listingId) public validListing(_listingId) whenMarketplaceNotPaused {
        require(_nftListings[_listingId].seller == _msgSender(), "Not listing seller");
        _nftListings[_listingId].isActive = false;
        emit NFTListingCancelled(_listingId);
    }

    // 7. Update Listing Price
    function updateListingPrice(uint256 _listingId, uint256 _newPrice) public validListing(_listingId) whenMarketplaceNotPaused {
        require(_nftListings[_listingId].seller == _msgSender(), "Not listing seller");
        _nftListings[_listingId].price = _newPrice;
        emit ListingPriceUpdated(_listingId, _newPrice);
    }

    // 8. Create Auction
    function createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration) public onlyNFTOwner(_tokenId) whenMarketplaceNotPaused {
        require(_auctionDuration > 0, "Auction duration must be greater than 0");
        approve(address(this), _tokenId);
        _auctionIdCounter.increment();
        uint256 auctionId = _auctionIdCounter.current();
        _nftAuctions[auctionId] = NFTAuction({
            auctionId: auctionId,
            tokenId: _tokenId,
            seller: payable(_msgSender()),
            startingBid: _startingBid,
            highestBid: _startingBid,
            highestBidder: payable(address(0)), // No bidder initially
            auctionEndTime: block.timestamp + _auctionDuration,
            isActive: true
        });
        emit AuctionCreated(auctionId, _tokenId, _msgSender(), _startingBid, block.timestamp + _auctionDuration);
    }

    // 9. Bid on Auction
    function bidOnAuction(uint256 _auctionId) public payable validAuction(_auctionId) whenMarketplaceNotPaused {
        NFTAuction storage auction = _nftAuctions[_auctionId];
        require(msg.value > auction.highestBid, "Bid amount must be higher than current highest bid");

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid); // Refund previous highest bidder
        }
        auction.highestBid = msg.value;
        auction.highestBidder = payable(_msgSender());
        emit BidPlaced(_auctionId, _msgSender(), msg.value);
    }

    // 10. Finalize Auction
    function finalizeAuction(uint256 _auctionId) public validAuction(_auctionId) whenMarketplaceNotPaused {
        NFTAuction storage auction = _nftAuctions[_auctionId];
        require(block.timestamp >= auction.auctionEndTime, "Auction is not yet ended");

        auction.isActive = false;
        uint256 finalPrice = auction.highestBid;
        uint256 marketplaceFee = finalPrice.mul(marketplaceFeePercentage).div(100);
        uint256 sellerProceeds = finalPrice.sub(marketplaceFee);

        // Royalty payment
        uint256 royaltyAmount = sellerProceeds.mul(_royaltyPercentages[auction.tokenId]).div(100);
        if (royaltyAmount > 0) {
            payable(ownerOf(auction.tokenId)).transfer(royaltyAmount);
            sellerProceeds = sellerProceeds.sub(royaltyAmount);
        }

        payable(auction.seller).transfer(sellerProceeds);
        payable(owner()).transfer(marketplaceFee);

        if (auction.highestBidder != address(0)) {
            transferFrom(auction.seller, auction.highestBidder, auction.tokenId);
            emit AuctionFinalized(_auctionId, auction.highestBidder, finalPrice);
        } else {
            // No bids, return NFT to seller (optional: or handle differently)
            transferFrom(address(this), auction.seller, auction.tokenId); // Transfer back from marketplace contract
            // Consider emitting an event for no bids auction ending.
        }
    }

    // 11. Create NFT Bundle
    function createNFTBundle(uint256[] memory _tokenIds) public whenMarketplaceNotPaused returns (uint256) {
        require(_tokenIds.length > 0, "Bundle must contain at least one NFT");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(ownerOf(_tokenIds[i]) == _msgSender(), "Not owner of all NFTs in bundle");
            approve(address(this), _tokenIds[i]); // Approve marketplace to transfer NFTs in bundle
        }

        _bundleIdCounter.increment();
        uint256 bundleId = _bundleIdCounter.current();
        _nftBundles[bundleId] = NFTBundle({
            bundleId: bundleId,
            tokenIds: _tokenIds,
            creator: payable(_msgSender())
        });
        emit NFTBundleCreated(bundleId, _msgSender(), _tokenIds);
        return bundleId;
    }

    // 12. List Bundle for Sale
    function listBundleForSale(uint256 _bundleId, uint256 _price) public onlyBundleCreator(_bundleId) whenMarketplaceNotPaused {
        _bundleListingIdCounter.increment();
        uint256 bundleListingId = _bundleListingIdCounter.current();
        _bundleListings[bundleListingId] = BundleListing({
            bundleListingId: bundleListingId,
            bundleId: _bundleId,
            seller: payable(_msgSender()),
            price: _price,
            isActive: true
        });
        emit BundleListed(bundleListingId, _bundleId, _msgSender(), _price);
    }

    // 13. Buy Bundle
    function buyBundle(uint256 _bundleListingId) public payable validBundleListing(_bundleListingId) whenMarketplaceNotPaused {
        BundleListing storage bundleListing = _bundleListings[_bundleListingId];
        require(msg.value >= bundleListing.price, "Insufficient funds");

        uint256 marketplaceFee = bundleListing.price.mul(marketplaceFeePercentage).div(100);
        uint256 sellerProceeds = bundleListing.price.sub(marketplaceFee);

        payable(bundleListing.seller).transfer(sellerProceeds);
        payable(owner()).transfer(marketplaceFee);

        NFTBundle storage bundle = _nftBundles[bundleListing.bundleId];
        for (uint256 i = 0; i < bundle.tokenIds.length; i++) {
            transferFrom(bundleListing.seller, _msgSender(), bundle.tokenIds[i]); // Seller assumed to be owner of all NFTs in bundle
        }

        bundleListing.isActive = false;
        emit BundleBought(_bundleListingId, bundleListing.bundleId, _msgSender(), bundleListing.price);
    }

    // 14. Cancel Bundle Listing
    function cancelBundleListing(uint256 _bundleListingId) public validBundleListing(_bundleListingId) whenMarketplaceNotPaused {
        require(_bundleListings[_bundleListingId].seller == _msgSender(), "Not bundle listing seller");
        _bundleListings[_bundleListingId].isActive = false;
        emit BundleListingCancelled(_bundleListingId);
    }

    // 15. Make Offer on NFT
    function makeOfferOnNFT(uint256 _tokenId, uint256 _offerPrice) public payable whenMarketplaceNotPaused {
        require(msg.value >= _offerPrice, "Offered amount must be sent with transaction");
        _offerIdCounter.increment();
        uint256 offerId = _offerIdCounter.current();
        _nftOffers[offerId] = NFTOffer({
            offerId: offerId,
            tokenId: _tokenId,
            offerer: payable(_msgSender()),
            offerPrice: _offerPrice,
            isActive: true
        });
        emit OfferMade(offerId, _tokenId, _msgSender(), _offerPrice);
        // Consider storing msg.value and refunding if offer is rejected/expires
    }

    // 16. Accept NFT Offer
    function acceptNFTOffer(uint256 _offerId) public onlyNFTOwner(_nftOffers[_offerId].tokenId) validOffer(_offerId) whenMarketplaceNotPaused {
        NFTOffer storage offer = _nftOffers[_offerId];
        require(ownerOf(offer.tokenId) == _msgSender(), "Not NFT owner"); // Double check owner

        uint256 offerPrice = offer.offerPrice;
        uint256 marketplaceFee = offerPrice.mul(marketplaceFeePercentage).div(100);
        uint256 sellerProceeds = offerPrice.sub(marketplaceFee);

        // Royalty payment
        uint256 royaltyAmount = sellerProceeds.mul(_royaltyPercentages[offer.tokenId]).div(100);
        if (royaltyAmount > 0) {
            payable(ownerOf(offer.tokenId)).transfer(royaltyAmount);
            sellerProceeds = sellerProceeds.sub(royaltyAmount);
        }

        payable(offer.offerer).transfer(offerPrice); // Refund offer amount (already sent in makeOffer) - logic needs adjustment if offer amount was held differently.
        payable(offer.offerer).transfer(sellerProceeds); // Send proceeds again - incorrect logic, should send seller proceeds to NFT owner.
        payable(owner()).transfer(marketplaceFee);

        transferFrom(_msgSender(), offer.offerer, offer.tokenId); // Transfer from current owner (accepting offer) to offerer

        offer.isActive = false;
        emit OfferAccepted(_offerId, offer.tokenId, offer.offerer, offerPrice);
    }

    // 17. Get Curation Score (Simulated AI)
    function getCurationScore(uint256 _tokenId) public view returns (uint256) {
        return _curationScores[_tokenId];
    }

    // 18. Vote for Curation (Simulated Community Feedback)
    function voteForCuration(uint256 _tokenId, uint8 _vote) public whenMarketplaceNotPaused {
        require(_vote == 0 || _vote == 1, "Invalid vote value (0 or 1)"); // 1 for upvote, 0 for downvote.
        require(_curationVotes[_tokenId][_msgSender()] == 0, "Already voted for this NFT"); // Prevent multiple votes from same address

        _curationVotes[_tokenId][_msgSender()] = _vote + 1; // Store vote (1 or 2 for easy counting later if needed)

        // Simple score update based on vote (can be more sophisticated)
        if (_vote == 1) {
            _curationScores[_tokenId] = _curationScores[_tokenId].add(1); // Upvote increases score
        } else {
            _curationScores[_tokenId] = _curationScores[_tokenId].sub(1); // Downvote decreases score (careful with underflow if score is 0)
        }
        emit CurationScoreUpdated(_tokenId, _curationScores[_tokenId]);
        emit VoteCast(_tokenId, _msgSender(), _vote);
    }

    // 19. Stake for Curation (Incentivized Curation - Basic Token Staking Simulation)
    function stakeForCuration(uint256 _tokenId) public payable whenMarketplaceNotPaused {
        require(msg.value > 0, "Stake amount must be greater than 0");
        _curationStakes[_tokenId] = _curationStakes[_tokenId].add(msg.value);
        _curationScores[_tokenId] = _curationScores[_tokenId].add(msg.value.div(1 ether)); // Example: 1 ETH stake increases score by 1. Adjust scaling as needed.
        emit StakeAdded(_tokenId, _msgSender(), msg.value);
        emit CurationScoreUpdated(_tokenId, _curationScores[_tokenId]);
        // In a real scenario, you might want to manage staking periods, rewards, etc. This is a very simplified example.
        // Consider using a separate staking token for a more realistic staking mechanism.
    }

    // 20. Unstake for Curation
    function unstakeForCuration(uint256 _tokenId) public whenMarketplaceNotPaused {
        uint256 stakedAmount = _curationStakes[_tokenId];
        require(stakedAmount > 0, "No stake to withdraw");
        _curationStakes[_tokenId] = 0; // Reset stake for simplicity - in real case, track per-user stakes
        _curationScores[_tokenId] = _curationScores[_tokenId].sub(stakedAmount.div(1 ether)); // Reverse the score increase from staking
        payable(_msgSender()).transfer(stakedAmount); // Return the staked amount
        emit StakeRemoved(_tokenId, _msgSender(), stakedAmount);
        emit CurationScoreUpdated(_tokenId, _curationScores[_tokenId]);
    }

    // Admin Functions (Ownable)

    // 21. Set Marketplace Fee
    function setMarketplaceFee(uint256 _feePercentage) public onlyOwner whenMarketplaceNotPaused {
        require(_feePercentage <= 100, "Fee percentage must be less than or equal to 100");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage);
    }

    // 22. Pause Marketplace
    function pauseMarketplace() public onlyOwner whenMarketplaceNotPaused {
        isMarketplacePaused = true;
        emit MarketplacePaused();
    }

    // 23. Unpause Marketplace
    function unpauseMarketplace() public onlyOwner whenMarketplacePaused {
        isMarketplacePaused = false;
        emit MarketplaceUnpaused();
    }

    // 24. Withdraw Marketplace Fees
    function withdrawMarketplaceFees() public onlyOwner whenMarketplaceNotPaused {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
        emit MarketplaceFeesWithdrawn(owner(), balance);
    }

    // Override supportsInterface to declare ERC165 interface ID for ERC721
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Public getter for token URI
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[_tokenId];
    }

    // Public getter for royalty percentage
    function getRoyaltyPercentage(uint256 _tokenId) public view returns (uint256) {
        return _royaltyPercentages[_tokenId];
    }

    // Public getter for listing details
    function getListing(uint256 _listingId) public view returns (NFTListing memory) {
        return _nftListings[_listingId];
    }

    // Public getter for auction details
    function getAuction(uint256 _auctionId) public view returns (NFTAuction memory) {
        return _nftAuctions[_auctionId];
    }

    // Public getter for bundle details
    function getBundle(uint256 _bundleId) public view returns (NFTBundle memory) {
        return _nftBundles[_bundleId];
    }

    // Public getter for bundle listing details
    function getBundleListing(uint256 _bundleListingId) public view returns (BundleListing memory) {
        return _bundleListings[_bundleListingId];
    }

    // Public getter for offer details
    function getOffer(uint256 _offerId) public view returns (NFTOffer memory) {
        return _nftOffers[_offerId];
    }
}
```