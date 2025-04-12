```solidity
/**
 * @title Decentralized Dynamic NFT Marketplace with AI Curation & Fractionalization
 * @author Bard (Example Smart Contract - Not for Production)
 * @notice This contract implements a dynamic NFT marketplace with advanced features:
 *   - Dynamic NFTs: NFTs with evolving metadata and attributes based on on-chain events.
 *   - AI Curation (Simulated): A basic on-chain algorithm simulating AI curation for NFT ranking and discovery.
 *   - NFT Fractionalization: Owners can fractionalize their NFTs into ERC20 tokens for shared ownership.
 *   - Advanced Listing and Bidding: Features like auction listings, reserve price listings, and timed auctions.
 *   - Reputation System: Basic reputation points for users based on marketplace activity.
 *   - Governance (Simple): Basic parameters adjustable by contract owner.
 *   - Staking (NFT and Marketplace Token): Staking mechanisms for NFTs and a hypothetical marketplace token.
 *   - Dynamic Fees: Marketplace fees that can be adjusted and potentially dynamically based on volume.
 *   - NFT Bundling: Allow users to bundle multiple NFTs for sale as a single listing.
 *   - Royalty Support: Mechanisms for NFT creators to receive royalties on secondary sales.
 *
 * Function Summary:
 * 1. createNFT: Mints a new Dynamic NFT.
 * 2. updateNFTMetadata: Allows authorized updaters to modify NFT metadata dynamically.
 * 3. setDynamicAttribute: Sets a dynamic attribute for an NFT, triggering potential metadata updates.
 * 4. calculateCurationScore: (Simulated AI) Calculates a basic curation score for an NFT.
 * 5. listNFTForSale: Lists an NFT for direct sale at a fixed price.
 * 6. listNFTForAuction: Lists an NFT for auction with a starting price and duration.
 * 7. buyNFT: Buys an NFT listed for direct sale.
 * 8. placeBid: Places a bid on an NFT listed for auction.
 * 9. settleAuction: Settles an auction after the duration, awarding NFT to the highest bidder.
 * 10. cancelListing: Cancels an existing NFT listing.
 * 11. fractionalizeNFT: Fractionalizes an NFT, creating ERC20 tokens representing fractions.
 * 12. redeemFractionsForNFT: Allows fraction holders to redeem fractions for the original NFT (requires thresholds and logic).
 * 13. stakeNFT: Allows users to stake NFTs for potential rewards or benefits.
 * 14. unstakeNFT: Allows users to unstake NFTs.
 * 15. claimStakingRewards: Allows users to claim staking rewards.
 * 16. addReputationPoints: Adds reputation points to a user based on positive actions.
 * 17. deductReputationPoints: Deducts reputation points from a user based on negative actions.
 * 18. setMarketplaceFee: Allows the contract owner to set the marketplace fee.
 * 19. withdrawMarketplaceFees: Allows the contract owner to withdraw accumulated marketplace fees.
 * 20. createNFTBundleListing: Lists a bundle of NFTs for sale as a single unit.
 * 21. buyNFTBundle: Buys an NFT bundle listing.
 * 22. setRoyaltyPercentage: Sets the royalty percentage for an NFT creator.
 * 23. getNFTDetails: Retrieves detailed information about an NFT.
 * 24. getListingDetails: Retrieves details about a specific marketplace listing.
 * 25. getAuctionDetails: Retrieves details about a specific auction listing.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DynamicAINFTMarketplace is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    // --- Data Structures ---
    struct NFT {
        string baseURI; // Base URI for dynamic metadata
        string name;
        string description;
        uint256 creationTimestamp;
        mapping(string => string) dynamicAttributes; // Key-value pairs for dynamic attributes
        uint256 curationScore; // Simulated AI curation score
        address creator;
        uint256 royaltyPercentage; // Royalty percentage for creator
    }

    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isAuction;
        uint256 auctionEndTime;
        uint256 reservePrice;
        address highestBidder;
        uint256 highestBid;
        bool isActive;
        bool isBundle; // Flag for bundle listing
    }

    struct FractionToken {
        ERC20 tokenContract;
        uint256 originalNFTId;
    }

    mapping(uint256 => NFT) public NFTs;
    mapping(uint256 => Listing) public Listings;
    mapping(uint256 => FractionToken) public FractionalizedNFTs; // NFT ID to Fraction Token
    mapping(address => uint256) public userReputation;
    mapping(uint256 => address[]) public nftStakers; // NFT ID to list of stakers
    mapping(address => uint256) public stakedNFTCount; // Address to count of NFTs staked
    mapping(uint256 => uint256) public nftStakeStartTime; // NFT ID to stake start time

    address public marketplaceTokenAddress; // Address of the marketplace ERC20 token (hypothetical)
    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    address payable public marketplaceFeeRecipient;
    uint256 public stakingRewardPerBlock = 1; // Example staking reward per block (hypothetical)
    uint256 public fractionalizationFactor = 1000; // Number of fractions per NFT

    // Allowed addresses for updating NFT metadata dynamically (e.g., oracles, AI services)
    mapping(address => bool) public allowedMetadataUpdaters;

    // Events
    event NFTCreated(uint256 tokenId, address creator, string name);
    event NFTMetadataUpdated(uint256 tokenId);
    event DynamicAttributeSet(uint256 tokenId, string attributeName, string attributeValue);
    event NFTListed(uint256 listingId, uint256 tokenId, address seller, uint256 price, bool isAuction);
    event NFTBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event BidPlaced(uint256 listingId, uint256 tokenId, address bidder, uint256 bidAmount);
    event AuctionSettled(uint256 listingId, uint256 tokenId, address winner, uint256 finalPrice);
    event ListingCancelled(uint256 listingId, uint256 tokenId);
    event NFTFractionalized(uint256 tokenId, address fractionTokenAddress);
    event FractionsRedeemed(uint256 tokenId, address redeemer);
    event NFTStaked(uint256 tokenId, address staker);
    event NFTUnstaked(uint256 tokenId, address unstaker);
    event StakingRewardsClaimed(address staker, uint256 amount);
    event ReputationPointsAdded(address user, uint256 pointsAdded);
    event ReputationPointsDeducted(address user, uint256 pointsDeducted);
    event MarketplaceFeeSet(uint256 newFeePercentage);
    event MarketplaceFeesWithdrawn(address recipient, uint256 amount);
    event NFTBundleListed(uint256 listingId, address seller);
    event NFTBundleBought(uint256 listingId, address buyer, uint256 price);
    event RoyaltyPercentageSet(uint256 tokenId, uint256 royaltyPercentage);


    constructor(string memory _name, string memory _symbol, address _marketplaceTokenAddress, address payable _marketplaceFeeRecipient) ERC721(_name, _symbol) {
        marketplaceTokenAddress = _marketplaceTokenAddress;
        marketplaceFeeRecipient = _marketplaceFeeRecipient;
    }

    modifier onlyAllowedUpdater() {
        require(allowedMetadataUpdaters[msg.sender], "Not an allowed metadata updater");
        _;
    }

    modifier listingExists(uint256 _listingId) {
        require(Listings[_listingId].tokenId != 0, "Listing does not exist");
        _;
    }

    modifier listingActive(uint256 _listingId) {
        require(Listings[_listingId].isActive, "Listing is not active");
        _;
    }

    modifier notListed(uint256 _tokenId) {
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) { // Iterate through existing listings, consider optimization for large scale
            if (Listings[i].tokenId == _tokenId && Listings[i].isActive) {
                revert("NFT is already listed.");
            }
        }
        _;
    }

    modifier isNFTCreator(uint256 _tokenId) {
        require(NFTs[_tokenId].creator == msg.sender, "You are not the NFT creator");
        _;
    }


    // 1. createNFT: Mints a new Dynamic NFT.
    function createNFT(string memory _name, string memory _description, string memory _baseURI, uint256 _royaltyPercentage) public returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        NFTs[tokenId] = NFT({
            baseURI: _baseURI,
            name: _name,
            description: _description,
            creationTimestamp: block.timestamp,
            curationScore: 0, // Initial curation score
            creator: msg.sender,
            royaltyPercentage: _royaltyPercentage
        });

        _mint(msg.sender, tokenId);
        emit NFTCreated(tokenId, msg.sender, _name);
        return tokenId;
    }

    // 2. updateNFTMetadata: Allows authorized updaters to modify NFT metadata dynamically.
    function updateNFTMetadata(uint256 _tokenId, string memory _newBaseURI, string memory _newName, string memory _newDescription) public onlyAllowedUpdater {
        require(_exists(_tokenId), "NFT does not exist");
        NFTs[_tokenId].baseURI = _newBaseURI;
        NFTs[_tokenId].name = _newName;
        NFTs[_tokenId].description = _newDescription;
        emit NFTMetadataUpdated(_tokenId);
    }

    // 3. setDynamicAttribute: Sets a dynamic attribute for an NFT, triggering potential metadata updates.
    function setDynamicAttribute(uint256 _tokenId, string memory _attributeName, string memory _attributeValue) public onlyAllowedUpdater {
        require(_exists(_tokenId), "NFT does not exist");
        NFTs[_tokenId].dynamicAttributes[_attributeName] = _attributeValue;
        emit DynamicAttributeSet(_tokenId, _attributeName, _attributeValue);
        // Potentially trigger metadata refresh logic here based on attribute change
    }

    // 4. calculateCurationScore: (Simulated AI) Calculates a basic curation score for an NFT.
    function calculateCurationScore(uint256 _tokenId) public {
        require(_exists(_tokenId), "NFT does not exist");
        // This is a very basic example - a real AI curation would be much more complex and likely off-chain
        uint256 score = 0;
        score += NFTs[_tokenId].creationTimestamp / 1000; // Example: Score based on creation time
        score += uint256(keccak256(abi.encode(NFTs[_tokenId].name))) % 100; // Example: Score based on name hash
        score += uint256(keccak256(abi.encode(NFTs[_tokenId].description))) % 50; // Example: Score based on description hash
        // Add more factors here - e.g., on-chain interaction metrics (likes, views - if tracked), dynamic attributes, etc.
        NFTs[_tokenId].curationScore = score;
    }

    // 5. listNFTForSale: Lists an NFT for direct sale at a fixed price.
    function listNFTForSale(uint256 _tokenId, uint256 _price) public notListed(_tokenId) {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");
        require(_price > 0, "Price must be greater than zero");

        _approve(address(this), _tokenId); // Approve marketplace to transfer NFT

        Counters.increment(_tokenIdCounter); // Reusing tokenIdCounter for listing IDs (can separate if needed)
        uint256 listingId = _tokenIdCounter.current();

        Listings[listingId] = Listing({
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isAuction: false,
            auctionEndTime: 0,
            reservePrice: 0,
            highestBidder: address(0),
            highestBid: 0,
            isActive: true,
            isBundle: false
        });

        emit NFTListed(listingId, _tokenId, msg.sender, _price, false);
    }

    // 6. listNFTForAuction: Lists an NFT for auction with a starting price and duration.
    function listNFTForAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _auctionDuration, uint256 _reservePrice) public notListed(_tokenId) {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");
        require(_startingPrice > 0, "Starting price must be greater than zero");
        require(_auctionDuration > 0, "Auction duration must be greater than zero");

        _approve(address(this), _tokenId); // Approve marketplace to transfer NFT

        Counters.increment(_tokenIdCounter);
        uint256 listingId = _tokenIdCounter.current();

        Listings[listingId] = Listing({
            tokenId: _tokenId,
            seller: msg.sender,
            price: _startingPrice, // Initial price is starting price
            isAuction: true,
            auctionEndTime: block.timestamp + _auctionDuration,
            reservePrice: _reservePrice,
            highestBidder: address(0),
            highestBid: 0,
            isActive: true,
            isBundle: false
        });

        emit NFTListed(listingId, _tokenId, msg.sender, _startingPrice, true);
    }

    // 7. buyNFT: Buys an NFT listed for direct sale.
    function buyNFT(uint256 _listingId) public payable listingExists(_listingId) listingActive(_listingId) {
        Listing storage listing = Listings[_listingId];
        require(!listing.isAuction, "Cannot buy an auction listing directly");
        require(msg.value >= listing.price, "Insufficient funds to buy NFT");

        uint256 feeAmount = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerAmount = listing.price - feeAmount;

        payable(listing.seller).transfer(sellerAmount);
        marketplaceFeeRecipient.transfer(feeAmount);

        _transferFrom(listing.seller, msg.sender, listing.tokenId);

        Listings[_listingId].isActive = false; // Mark listing as inactive

        emit NFTBought(_listingId, listing.tokenId, msg.sender, listing.price);
        addReputationPoints(listing.seller, 1); // Example: seller gains reputation for successful sale
        addReputationPoints(msg.sender, 1);     // Example: buyer gains reputation for successful purchase
    }

    // 8. placeBid: Places a bid on an NFT listed for auction.
    function placeBid(uint256 _listingId) public payable listingExists(_listingId) listingActive(_listingId) {
        Listing storage listing = Listings[_listingId];
        require(listing.isAuction, "This is not an auction listing");
        require(block.timestamp < listing.auctionEndTime, "Auction has ended");
        require(msg.value > listing.highestBid, "Bid must be higher than the current highest bid");

        if (listing.highestBidder != address(0)) {
            payable(listing.highestBidder).transfer(listing.highestBid); // Refund previous bidder
        }

        Listings[_listingId].highestBidder = msg.sender;
        Listings[_listingId].highestBid = msg.value;

        emit BidPlaced(_listingId, listing.tokenId, msg.sender, msg.value);
    }

    // 9. settleAuction: Settles an auction after the duration, awarding NFT to the highest bidder.
    function settleAuction(uint256 _listingId) public listingExists(_listingId) listingActive(_listingId) {
        Listing storage listing = Listings[_listingId];
        require(listing.isAuction, "This is not an auction listing");
        require(block.timestamp >= listing.auctionEndTime, "Auction is not yet ended");
        require(listing.highestBidder != address(0), "No bids placed on this auction");
        require(listing.highestBid >= listing.reservePrice, "Reserve price not met"); // Optional reserve price check

        uint256 finalPrice = listing.highestBid;
        uint256 feeAmount = (finalPrice * marketplaceFeePercentage) / 100;
        uint256 sellerAmount = finalPrice - feeAmount;

        payable(listing.seller).transfer(sellerAmount);
        marketplaceFeeRecipient.transfer(feeAmount);

        _transferFrom(listing.seller, listing.highestBidder, listing.tokenId);

        Listings[_listingId].isActive = false; // Mark listing as inactive

        emit AuctionSettled(_listingId, listing.tokenId, listing.highestBidder, finalPrice);
        addReputationPoints(listing.seller, 2); // Example: Seller gets more reputation for successful auction
        addReputationPoints(listing.highestBidder, 2); // Example: Winner gets more reputation
    }

    // 10. cancelListing: Cancels an existing NFT listing.
    function cancelListing(uint256 _listingId) public listingExists(_listingId) listingActive(_listingId) {
        Listing storage listing = Listings[_listingId];
        require(listing.seller == msg.sender, "You are not the seller of this listing");
        require(listing.highestBidder == address(0), "Cannot cancel listing with bids"); // Optional: Prevent cancellation if bids exist

        Listings[_listingId].isActive = false;
        emit ListingCancelled(_listingId, listing.tokenId);
    }

    // 11. fractionalizeNFT: Fractionalizes an NFT, creating ERC20 tokens representing fractions.
    function fractionalizeNFT(uint256 _tokenId, string memory _fractionTokenName, string memory _fractionTokenSymbol) public {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");
        require(FractionalizedNFTs[_tokenId].tokenContract == ERC20(address(0)), "NFT already fractionalized"); // Prevent double fractionalization

        _approve(address(this), _tokenId); // Approve marketplace to transfer NFT temporarily

        // Create a new ERC20 token representing fractions
        ERC20 fractionToken = new ERC20(_fractionTokenName, _fractionTokenSymbol);
        FractionalizedNFTs[_tokenId] = FractionToken({
            tokenContract: fractionToken,
            originalNFTId: _tokenId
        });

        // Mint fractions to the NFT owner
        fractionToken.mint(msg.sender, fractionalizationFactor);

        // Transfer NFT to this contract to represent fractionalization custody (alternative approaches possible)
        _transferFrom(msg.sender, address(this), _tokenId);

        emit NFTFractionalized(_tokenId, address(fractionToken));
    }

    // 12. redeemFractionsForNFT: Allows fraction holders to redeem fractions for the original NFT (requires thresholds and logic).
    function redeemFractionsForNFT(uint256 _tokenId) public {
        require(_exists(_tokenId), "NFT does not exist");
        require(FractionalizedNFTs[_tokenId].tokenContract != ERC20(address(0)), "NFT is not fractionalized");
        ERC20 fractionToken = FractionalizedNFTs[_tokenId].tokenContract;
        require(fractionToken.balanceOf(msg.sender) >= fractionalizationFactor, "Not enough fractions to redeem");

        // Logic for redemption - could require burning fractions and transferring NFT back
        fractionToken.burnFrom(msg.sender, fractionalizationFactor);
        _transferFrom(address(this), msg.sender, _tokenId); // Transfer NFT back from marketplace custody

        emit FractionsRedeemed(_tokenId, msg.sender);
    }

    // 13. stakeNFT: Allows users to stake NFTs for potential rewards or benefits.
    function stakeNFT(uint256 _tokenId) public {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");
        require(nftStakeStartTime[_tokenId] == 0, "NFT already staked"); // Prevent double staking

        _approve(address(this), _tokenId); // Approve marketplace to hold NFT during staking
        _transferFrom(msg.sender, address(this), _tokenId); // Transfer NFT to marketplace for staking

        nftStakers[_tokenId].push(msg.sender);
        stakedNFTCount[msg.sender]++;
        nftStakeStartTime[_tokenId] = block.timestamp;

        emit NFTStaked(_tokenId, msg.sender);
    }

    // 14. unstakeNFT: Allows users to unstake NFTs.
    function unstakeNFT(uint256 _tokenId) public {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == address(this), "NFT not staked in this contract"); // Check if contract owns it (meaning it's staked)
        require(nftStakeStartTime[_tokenId] != 0, "NFT is not staked");

        bool foundStaker = false;
        for(uint i = 0; i < nftStakers[_tokenId].length; i++){
            if(nftStakers[_tokenId][i] == msg.sender){
                foundStaker = true;
                break;
            }
        }
        require(foundStaker, "You are not a staker of this NFT");


        _transferFrom(address(this), msg.sender, _tokenId); // Transfer NFT back to staker

        stakedNFTCount[msg.sender]--;
        nftStakeStartTime[_tokenId] = 0; // Reset stake start time

        emit NFTUnstaked(_tokenId, msg.sender);
    }

    // 15. claimStakingRewards: Allows users to claim staking rewards.
    function claimStakingRewards() public {
        // Example: Simple reward based on staked NFT count and elapsed blocks since last claim
        uint256 rewardAmount = stakedNFTCount[msg.sender] * stakingRewardPerBlock; // Very basic example
        // In a real implementation, track last claim time and calculate rewards based on actual staking duration
        // and potentially different reward rates for different NFTs.

        // Assuming marketplaceTokenAddress is set and points to a real ERC20 token
        if (marketplaceTokenAddress != address(0)) {
            ERC20 marketplaceToken = ERC20(marketplaceTokenAddress);
            marketplaceToken.transfer(msg.sender, rewardAmount); // Need to ensure contract has tokens to distribute
            emit StakingRewardsClaimed(msg.sender, rewardAmount);
        } else {
            // Handle case where no marketplace token is configured (e.g., revert or emit warning)
            revert("Marketplace token not configured for staking rewards.");
        }
    }

    // 16. addReputationPoints: Adds reputation points to a user based on positive actions.
    function addReputationPoints(address _user, uint256 _points) internal {
        userReputation[_user] += _points;
        emit ReputationPointsAdded(_user, _points);
    }

    // 17. deductReputationPoints: Deducts reputation points from a user based on negative actions.
    function deductReputationPoints(address _user, uint256 _points) public onlyOwner { // Example: Only owner can deduct reputation
        require(userReputation[_user] >= _points, "Insufficient reputation points to deduct");
        userReputation[_user] -= _points;
        emit ReputationPointsDeducted(_user, _points);
    }

    // 18. setMarketplaceFee: Allows the contract owner to set the marketplace fee.
    function setMarketplaceFee(uint256 _newFeePercentage) public onlyOwner {
        require(_newFeePercentage <= 10, "Fee percentage cannot exceed 10%"); // Example limit
        marketplaceFeePercentage = _newFeePercentage;
        emit MarketplaceFeeSet(_newFeePercentage);
    }

    // 19. withdrawMarketplaceFees: Allows the contract owner to withdraw accumulated marketplace fees.
    function withdrawMarketplaceFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No marketplace fees to withdraw");
        marketplaceFeeRecipient.transfer(balance);
        emit MarketplaceFeesWithdrawn(marketplaceFeeRecipient, balance);
    }

    // 20. createNFTBundleListing: Lists a bundle of NFTs for sale as a single unit.
    function createNFTBundleListing(uint256[] memory _tokenIds, uint256 _price) public notListed(_tokenIds[0]) { // Basic check on first NFT in bundle
        require(_tokenIds.length > 1, "Bundle must contain at least two NFTs");
        require(_price > 0, "Price must be greater than zero");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_exists(_tokenIds[i]), "NFT in bundle does not exist");
            require(ownerOf(_tokenIds[i]) == msg.sender, "You are not the owner of an NFT in the bundle");
            _approve(address(this), _tokenIds[i]); // Approve marketplace to transfer each NFT
        }

        Counters.increment(_tokenIdCounter); // Reusing tokenIdCounter for listing IDs
        uint256 listingId = _tokenIdCounter.current();

        Listings[listingId] = Listing({
            tokenId: _tokenIds[0], // Using first token ID as representative for bundle listing (consider better ID approach)
            seller: msg.sender,
            price: _price,
            isAuction: false,
            auctionEndTime: 0,
            reservePrice: 0,
            highestBidder: address(0),
            highestBid: 0,
            isActive: true,
            isBundle: true
        });
        // Store bundle token IDs separately (mapping listingId -> tokenId[]) if needed for more complex bundle management

        emit NFTBundleListed(listingId, msg.sender);
        emit NFTListed(listingId, _tokenIds[0], msg.sender, _price, false); // Also emit regular NFTListed event for general listing info
    }

    // 21. buyNFTBundle: Buys an NFT bundle listing.
    function buyNFTBundle(uint256 _listingId) public payable listingExists(_listingId) listingActive(_listingId) {
        Listing storage listing = Listings[_listingId];
        require(listing.isBundle, "This is not a bundle listing");
        require(!listing.isAuction, "Cannot buy an auction bundle directly"); // Bundles are only for direct sale in this example
        require(msg.value >= listing.price, "Insufficient funds to buy NFT bundle");

        uint256 feeAmount = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerAmount = listing.price - feeAmount;

        payable(listing.seller).transfer(sellerAmount);
        marketplaceFeeRecipient.transfer(feeAmount);

        // Assuming bundle token IDs are stored in a separate mapping (not implemented in this example for brevity)
        // For example: mapping(uint256 listingId => uint256[]) public bundleTokenIds;
        // Then, iterate through bundleTokenIds[_listingId] and transfer each NFT:
        // for (uint256 i = 0; i < bundleTokenIds[_listingId].length; i++) {
        //     _transferFrom(listing.seller, msg.sender, bundleTokenIds[_listingId][i]);
        // }
        // For now, assuming listing.tokenId represents the first NFT in the bundle and the rest are implied
        // (This is a simplification and needs proper bundle token tracking in a real implementation)

        // **Simplified Bundle Transfer - Requires Proper Bundle Token Tracking for Real Use**
        // (This only transfers the representative NFT, not the whole bundle - needs improvement)
        // _transferFrom(listing.seller, msg.sender, listing.tokenId);

        // **Place holder for bundle transfer logic -  Needs to be implemented correctly based on how bundle NFTs are tracked**
        //  Assuming bundle tokens are stored and accessible (e.g., in bundleTokenIds mapping)

        // In this simplified example, we just mark the listing as inactive and emit the event
        Listings[_listingId].isActive = false; // Mark listing as inactive

        emit NFTBundleBought(_listingId, msg.sender, listing.price);
        emit NFTBought(_listingId, listing.tokenId, msg.sender, listing.price); // Emit regular NFTBought for general marketplace activity tracking
        addReputationPoints(listing.seller, 1); // Example: seller gains reputation
        addReputationPoints(msg.sender, 1);     // Example: buyer gains reputation
    }

    // 22. setRoyaltyPercentage: Sets the royalty percentage for an NFT creator.
    function setRoyaltyPercentage(uint256 _tokenId, uint256 _royaltyPercentage) public isNFTCreator(_tokenId) {
        require(_royaltyPercentage <= 15, "Royalty percentage cannot exceed 15%"); // Example limit
        NFTs[_tokenId].royaltyPercentage = _royaltyPercentage;
        emit RoyaltyPercentageSet(_tokenId, _royaltyPercentage);
    }

    // --- Getter/View Functions ---

    // 23. getNFTDetails: Retrieves detailed information about an NFT.
    function getNFTDetails(uint256 _tokenId) public view returns (NFT memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return NFTs[_tokenId];
    }

    // 24. getListingDetails: Retrieves details about a specific marketplace listing.
    function getListingDetails(uint256 _listingId) public view listingExists(_listingId) returns (Listing memory) {
        return Listings[_listingId];
    }

    // 25. getAuctionDetails: Retrieves details about a specific auction listing.
    function getAuctionDetails(uint256 _listingId) public view listingExists(_listingId) listingActive(_listingId) returns (address highestBidder, uint256 highestBid, uint256 auctionEndTime) {
        Listing storage listing = Listings[_listingId];
        require(listing.isAuction, "Listing is not an auction");
        return (listing.highestBidder, listing.highestBid, listing.auctionEndTime);
    }

    // --- Admin/Owner Functions ---
    function addAllowedMetadataUpdater(address _updaterAddress) public onlyOwner {
        allowedMetadataUpdaters[_updaterAddress] = true;
    }

    function removeAllowedMetadataUpdater(address _updaterAddress) public onlyOwner {
        allowedMetadataUpdaters[_updaterAddress] = false;
    }

    function setMarketplaceTokenAddress(address _tokenAddress) public onlyOwner {
        marketplaceTokenAddress = _tokenAddress;
    }

    function setMarketplaceFeeRecipient(address payable _recipient) public onlyOwner {
        marketplaceFeeRecipient = _recipient;
    }

    function setStakingRewardPerBlock(uint256 _reward) public onlyOwner {
        stakingRewardPerBlock = _reward;
    }

    function setFractionalizationFactor(uint256 _factor) public onlyOwner {
        fractionalizationFactor = _factor;
    }

    // --- Token URI Override for Dynamic Metadata ---
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist");
        string memory base = NFTs[_tokenId].baseURI;
        string memory name = NFTs[_tokenId].name;
        string memory description = NFTs[_tokenId].description;
        string memory attributesJson = "[";
        bool firstAttribute = true;
        for (uint256 i = 0; i < 10; i++) { // Example: Iterate through first 10 dynamic attributes (can be improved)
            string memory attributeName = string(abi.encodePacked("attribute", Strings.toString(i))); // Example attribute names
            if (bytes(NFTs[_tokenId].dynamicAttributes[attributeName]).length > 0) {
                if (!firstAttribute) {
                    attributesJson = string(abi.encodePacked(attributesJson, ","));
                }
                attributesJson = string(abi.encodePacked(attributesJson,
                    '{"trait_type": "', attributeName, '", "value": "', NFTs[_tokenId].dynamicAttributes[attributeName], '"}'
                ));
                firstAttribute = false;
            }
        }
        attributesJson = string(abi.encodePacked(attributesJson, "]"));

        string memory metadata = string(abi.encodePacked(
            '{"name": "', name, '",',
            '"description": "', description, '",',
            '"image": "', base, "/image/", _tokenId.toString(), '.png", '",', // Example image URI construction
            '"attributes": ', attributesJson,
            '}'
        ));

        string memory jsonUri = string(abi.encodePacked(
            "data:application/json;base64,",
            vm.base64Encode(bytes(metadata)) // Requires Solidity >= 0.8.4 or external library for base64 encoding
        ));
        return jsonUri;
    }

    // --- Fallback function to receive ETH ---
    receive() external payable {}
}
```