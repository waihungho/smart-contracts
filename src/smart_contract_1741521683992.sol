```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with Advanced Features
 * @author Bard (Inspired by User Request)
 * @dev This contract implements a decentralized marketplace for Dynamic NFTs,
 *      incorporating various advanced and trendy features beyond standard marketplaces.
 *      It includes dynamic NFT metadata updates, staking, rentals, auctions (English & Dutch),
 *      bundle sales, creator royalties, and community governance aspects.
 *
 * **Outline & Function Summary:**
 *
 * **1. NFT Management:**
 *    - `createDynamicNFT(string memory _baseURI, string memory _initialMetadata)`: Creates a new Dynamic NFT with base URI and initial metadata.
 *    - `updateNFTMetadata(uint256 _tokenId, string memory _newMetadata)`: Updates the metadata of a specific NFT.
 *    - `getNFTMetadata(uint256 _tokenId)`: Retrieves the current metadata of an NFT.
 *    - `transferNFT(address _to, uint256 _tokenId)`: Transfers an NFT to another address.
 *
 * **2. Marketplace Core Functionality:**
 *    - `listItemForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale in the marketplace.
 *    - `buyNFT(uint256 _tokenId)`: Allows anyone to buy an NFT listed for sale.
 *    - `delistItem(uint256 _tokenId)`: Allows the NFT owner to delist their NFT from sale.
 *    - `getListingPrice(uint256 _tokenId)`: Retrieves the current listing price of an NFT.
 *    - `isNFTListed(uint256 _tokenId)`: Checks if an NFT is currently listed for sale.
 *
 * **3. Advanced Marketplace Features:**
 *    - `stakeNFT(uint256 _tokenId)`: Allows NFT owners to stake their NFTs to earn rewards.
 *    - `unstakeNFT(uint256 _tokenId)`: Allows NFT owners to unstake their NFTs.
 *    - `claimStakingRewards(uint256 _tokenId)`: Allows stakers to claim accumulated staking rewards.
 *    - `rentNFT(uint256 _tokenId, uint256 _rentalDuration)`: Allows NFT owners to rent out their NFTs for a specified duration.
 *    - `returnNFT(uint256 _tokenId)`: Allows renters to return rented NFTs before the rental period ends.
 *    - `extendRental(uint256 _tokenId, uint256 _extensionDuration)`: Allows renters to extend the rental period.
 *    - `createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration, AuctionType _auctionType)`: Creates an auction for an NFT (English or Dutch).
 *    - `bidOnAuction(uint256 _auctionId)`: Allows users to bid on an ongoing auction.
 *    - `finalizeAuction(uint256 _auctionId)`: Finalizes an auction, transferring NFT and funds.
 *    - `createBundleSale(uint256[] memory _tokenIds, uint256 _bundlePrice)`: Creates a bundle of NFTs for sale at a fixed price.
 *    - `buyBundle(uint256 _bundleId)`: Allows users to buy an NFT bundle.
 *
 * **4. Royalty & Platform Management:**
 *    - `setRoyaltyPercentage(uint256 _tokenId, uint256 _royaltyPercentage)`: Sets the royalty percentage for an NFT (for secondary sales).
 *    - `getRoyaltyPercentage(uint256 _tokenId)`: Retrieves the royalty percentage for an NFT.
 *    - `setPlatformFeePercentage(uint256 _feePercentage)`: Sets the platform fee percentage for all marketplace transactions.
 *    - `getPlatformFeePercentage()`: Retrieves the current platform fee percentage.
 *    - `withdrawPlatformFees()`: Allows the contract owner to withdraw accumulated platform fees.
 *    - `pauseMarketplace()`: Pauses all marketplace functionalities.
 *    - `unpauseMarketplace()`: Resumes marketplace functionalities.
 */

contract DynamicNFTMarketplace {
    // --- Data Structures ---
    struct NFT {
        address owner;
        string baseURI;
        string metadata;
        uint256 royaltyPercentage; // Royalty percentage for secondary sales
    }

    struct Listing {
        uint256 price;
        address seller;
        bool isListed;
    }

    struct StakingInfo {
        uint256 stakeStartTime;
        uint256 lastRewardClaimTime;
        bool isStaked;
    }

    struct RentalInfo {
        address renter;
        uint256 rentalEndTime;
        bool isRented;
    }

    enum AuctionType { ENGLISH, DUTCH }

    struct Auction {
        uint256 tokenId;
        AuctionType auctionType;
        uint256 startingBid;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool isActive;
    }

    struct BundleSale {
        uint256[] tokenIds;
        uint256 bundlePrice;
        address seller;
        bool isActive;
    }

    // --- State Variables ---
    NFT[] public nfts; // Array to store NFT data
    mapping(uint256 => Listing) public listings; // Mapping from tokenId to Listing details
    mapping(uint256 => StakingInfo) public stakingInfos; // Mapping from tokenId to staking information
    mapping(uint256 => RentalInfo) public rentalInfos; // Mapping from tokenId to rental information
    mapping(uint256 => Auction) public auctions; // Mapping from auctionId to Auction details
    uint256 public auctionCounter; // Counter for auction IDs
    mapping(uint256 => BundleSale) public bundleSales; // Mapping from bundleId to BundleSale details
    uint256 public bundleCounter; // Counter for bundle IDs

    uint256 public platformFeePercentage = 2; // Default platform fee percentage (2%)
    address payable public platformFeeRecipient; // Address to receive platform fees
    mapping(uint256 => uint256) public royaltyPercentages; // Mapping from tokenId to royalty percentage

    bool public marketplacePaused = false;
    address public owner;

    // --- Events ---
    event NFTCreated(uint256 tokenId, address creator, string baseURI, string initialMetadata);
    event NFTMetadataUpdated(uint256 tokenId, string newMetadata);
    event NFTListedForSale(uint256 tokenId, uint256 price, address seller);
    event NFTBought(uint256 tokenId, address buyer, uint256 price);
    event NFTDelisted(uint256 tokenId, address seller);
    event NFTStaked(uint256 tokenId, address staker);
    event NFTUnstaked(uint256 tokenId, address unstaker);
    event StakingRewardsClaimed(uint256 tokenId, address staker, uint256 rewardAmount);
    event NFTRented(uint256 tokenId, address renter, uint256 rentalEndTime);
    event NFTReturned(uint256 tokenId, address renter);
    event RentalExtended(uint256 tokenId, address renter, uint256 newRentalEndTime);
    event AuctionCreated(uint256 auctionId, uint256 tokenId, AuctionType auctionType, uint256 startingBid, uint256 endTime);
    event BidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionFinalized(uint256 auctionId, uint256 tokenId, address winner, uint256 finalPrice);
    event BundleSaleCreated(uint256 bundleId, uint256[] tokenIds, uint256 bundlePrice, address seller);
    event BundleBought(uint256 bundleId, address buyer, uint256 bundlePrice);
    event RoyaltyPercentageSet(uint256 tokenId, uint256 royaltyPercentage);
    event PlatformFeePercentageSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address recipient);
    event MarketplacePaused();
    event MarketplaceUnpaused();

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!marketplacePaused, "Marketplace is currently paused.");
        _;
    }

    modifier whenPaused() {
        require(marketplacePaused, "Marketplace is currently active.");
        _;
    }

    modifier nftExists(uint256 _tokenId) {
        require(_tokenId < nfts.length, "NFT does not exist.");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(nfts[_tokenId].owner == msg.sender, "You are not the NFT owner.");
        _;
    }

    modifier onlyListedNFTOwner(uint256 _tokenId) {
        require(listings[_tokenId].seller == msg.sender, "You are not the listing seller.");
        _;
    }

    modifier nftNotListed(uint256 _tokenId) {
        require(!listings[_tokenId].isListed, "NFT is already listed for sale.");
        _;
    }

    modifier nftListed(uint256 _tokenId) {
        require(listings[_tokenId].isListed, "NFT is not listed for sale.");
        _;
    }

    modifier nftNotStaked(uint256 _tokenId) {
        require(!stakingInfos[_tokenId].isStaked, "NFT is currently staked.");
        _;
    }

    modifier nftStaked(uint256 _tokenId) {
        require(stakingInfos[_tokenId].isStaked, "NFT is not staked.");
        _;
    }

    modifier nftNotRented(uint256 _tokenId) {
        require(!rentalInfos[_tokenId].isRented, "NFT is currently rented.");
        _;
    }

    modifier nftRented(uint256 _tokenId) {
        require(rentalInfos[_tokenId].isRented, "NFT is not rented.");
        _;
    }

    modifier validAuction(uint256 _auctionId) {
        require(_auctionId < auctionCounter, "Invalid auction ID.");
        require(auctions[_auctionId].isActive, "Auction is not active.");
        _;
    }

    modifier auctionCreator(uint256 _auctionId) {
        require(nfts[auctions[_auctionId].tokenId].owner == msg.sender, "You are not the auction creator.");
        _;
    }

    modifier bundleExists(uint256 _bundleId) {
        require(_bundleId < bundleCounter, "Bundle sale does not exist.");
        require(bundleSales[_bundleId].isActive, "Bundle sale is not active.");
        _;
    }

    modifier bundleSeller(uint256 _bundleId) {
        require(bundleSales[_bundleId].seller == msg.sender, "You are not the bundle seller.");
        _;
    }


    // --- Constructor ---
    constructor(address payable _platformFeeRecipient) {
        owner = msg.sender;
        platformFeeRecipient = _platformFeeRecipient;
        auctionCounter = 0;
        bundleCounter = 0;
    }

    // --- 1. NFT Management Functions ---

    /// @notice Creates a new Dynamic NFT.
    /// @param _baseURI Base URI for the NFT (e.g., IPFS base URI).
    /// @param _initialMetadata Initial metadata for the NFT.
    function createDynamicNFT(string memory _baseURI, string memory _initialMetadata) public whenNotPaused {
        uint256 tokenId = nfts.length;
        nfts.push(NFT({
            owner: msg.sender,
            baseURI: _baseURI,
            metadata: _initialMetadata,
            royaltyPercentage: 5 // Default royalty is 5%
        }));
        emit NFTCreated(tokenId, msg.sender, _baseURI, _initialMetadata);
    }

    /// @notice Updates the metadata of a specific NFT. Can only be called by the NFT owner.
    /// @param _tokenId ID of the NFT to update.
    /// @param _newMetadata New metadata string.
    function updateNFTMetadata(uint256 _tokenId, string memory _newMetadata) public nftExists(_tokenId) onlyNFTOwner(_tokenId) whenNotPaused {
        nfts[_tokenId].metadata = _newMetadata;
        emit NFTMetadataUpdated(_tokenId, _newMetadata);
    }

    /// @notice Retrieves the current metadata of an NFT.
    /// @param _tokenId ID of the NFT.
    /// @return The metadata string of the NFT.
    function getNFTMetadata(uint256 _tokenId) public view nftExists(_tokenId) returns (string memory) {
        return nfts[_tokenId].metadata;
    }

    /// @notice Transfers an NFT to another address. Can only be called by the NFT owner.
    /// @param _to Address to transfer the NFT to.
    /// @param _tokenId ID of the NFT to transfer.
    function transferNFT(address _to, uint256 _tokenId) public nftExists(_tokenId) onlyNFTOwner(_tokenId) whenNotPaused nftNotStaked(_tokenId) nftNotRented(_tokenId) {
        require(_to != address(0), "Invalid recipient address.");
        require(_to != address(this), "Cannot transfer to contract address.");

        nfts[_tokenId].owner = _to;
        delete listings[_tokenId]; // Delist if listed during transfer
        emit NFTBought(_tokenId, _to, listings[_tokenId].price); // Using Buy event for transfer notification. Price will be 0 in this case
    }


    // --- 2. Marketplace Core Functionality ---

    /// @notice Lists an NFT for sale on the marketplace. Can only be called by the NFT owner.
    /// @param _tokenId ID of the NFT to list.
    /// @param _price Sale price in wei.
    function listItemForSale(uint256 _tokenId, uint256 _price) public nftExists(_tokenId) onlyNFTOwner(_tokenId) nftNotListed(_tokenId) whenNotPaused nftNotStaked(_tokenId) nftNotRented(_tokenId) {
        require(_price > 0, "Price must be greater than zero.");
        listings[_tokenId] = Listing({
            price: _price,
            seller: msg.sender,
            isListed: true
        });
        emit NFTListedForSale(_tokenId, _price, msg.sender);
    }

    /// @notice Allows anyone to buy an NFT listed for sale.
    /// @param _tokenId ID of the NFT to buy.
    function buyNFT(uint256 _tokenId) public payable nftExists(_tokenId) nftListed(_tokenId) whenNotPaused {
        Listing storage listing = listings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds sent.");

        uint256 platformFee = (listing.price * platformFeePercentage) / 100;
        uint256 creatorRoyalty = (listing.price * nfts[_tokenId].royaltyPercentage) / 100;
        uint256 sellerProceeds = listing.price - platformFee - creatorRoyalty;

        // Transfer platform fee
        (bool feeSuccess, ) = platformFeeRecipient.call{value: platformFee}("");
        require(feeSuccess, "Platform fee transfer failed.");

        // Transfer royalty to creator (assuming creator is the original minter, for simplicity. Could be more complex tracking)
        address creatorAddress = nfts[_tokenId].owner; // Simplification: Using current owner as creator for royalty.
        if (creatorRoyalty > 0) {
            (bool royaltySuccess, ) = payable(creatorAddress).call{value: creatorRoyalty}("");
            require(royaltySuccess, "Royalty transfer failed.");
        }

        // Transfer proceeds to seller
        (bool sellerSuccess, ) = payable(listing.seller).call{value: sellerProceeds}("");
        require(sellerSuccess, "Seller proceeds transfer failed.");


        nfts[_tokenId].owner = msg.sender;
        delete listings[_tokenId]; // Delist after purchase
        emit NFTBought(_tokenId, msg.sender, listing.price);
    }

    /// @notice Allows the NFT owner to delist their NFT from sale.
    /// @param _tokenId ID of the NFT to delist.
    function delistItem(uint256 _tokenId) public nftExists(_tokenId) onlyListedNFTOwner(_tokenId) whenNotPaused {
        require(listings[_tokenId].isListed, "NFT is not listed for sale.");
        delete listings[_tokenId];
        emit NFTDelisted(_tokenId, msg.sender);
    }

    /// @notice Retrieves the current listing price of an NFT.
    /// @param _tokenId ID of the NFT.
    /// @return The listing price in wei.
    function getListingPrice(uint256 _tokenId) public view nftExists(_tokenId) returns (uint256) {
        return listings[_tokenId].price;
    }

    /// @notice Checks if an NFT is currently listed for sale.
    /// @param _tokenId ID of the NFT.
    /// @return True if listed, false otherwise.
    function isNFTListed(uint256 _tokenId) public view nftExists(_tokenId) returns (bool) {
        return listings[_tokenId].isListed;
    }


    // --- 3. Advanced Marketplace Features ---

    /// @notice Allows NFT owners to stake their NFTs to earn rewards (placeholder - reward mechanism needs to be implemented).
    /// @param _tokenId ID of the NFT to stake.
    function stakeNFT(uint256 _tokenId) public nftExists(_tokenId) onlyNFTOwner(_tokenId) nftNotStaked(_tokenId) nftNotListed(_tokenId) nftNotRented(_tokenId) whenNotPaused {
        stakingInfos[_tokenId] = StakingInfo({
            stakeStartTime: block.timestamp,
            lastRewardClaimTime: block.timestamp,
            isStaked: true
        });
        emit NFTStaked(_tokenId, msg.sender);
    }

    /// @notice Allows NFT owners to unstake their NFTs.
    /// @param _tokenId ID of the NFT to unstake.
    function unstakeNFT(uint256 _tokenId) public nftExists(_tokenId) onlyNFTOwner(_tokenId) nftStaked(_tokenId) whenNotPaused {
        stakingInfos[_tokenId].isStaked = false;
        emit NFTUnstaked(_tokenId, msg.sender);
    }

    /// @notice Allows stakers to claim accumulated staking rewards (placeholder - reward calculation needs to be implemented).
    /// @param _tokenId ID of the NFT for which to claim rewards.
    function claimStakingRewards(uint256 _tokenId) public nftExists(_tokenId) onlyNFTOwner(_tokenId) nftStaked(_tokenId) whenNotPaused {
        // --- Placeholder for reward calculation logic ---
        // In a real implementation, you would calculate rewards based on staking duration,
        // reward rates, and potentially other factors.
        uint256 rewardAmount = 0; // Placeholder - Replace with actual reward calculation
        stakingInfos[_tokenId].lastRewardClaimTime = block.timestamp;
        // --- End of placeholder ---

        // Transfer rewards to staker (assuming rewards are in ETH for simplicity - could be another token)
        if (rewardAmount > 0) {
            (bool rewardSuccess, ) = payable(msg.sender).call{value: rewardAmount}("");
            require(rewardSuccess, "Reward transfer failed.");
            emit StakingRewardsClaimed(_tokenId, msg.sender, rewardAmount);
        }
    }

    /// @notice Allows NFT owners to rent out their NFTs for a specified duration.
    /// @param _tokenId ID of the NFT to rent.
    /// @param _rentalDuration Rental duration in seconds.
    function rentNFT(uint256 _tokenId, uint256 _rentalDuration) public payable nftExists(_tokenId) onlyNFTOwner(_tokenId) nftNotListed(_tokenId) nftNotStaked(_tokenId) nftNotRented(_tokenId) whenNotPaused {
        require(_rentalDuration > 0, "Rental duration must be greater than zero.");
        uint256 rentalPrice = calculateRentalPrice(_tokenId, _rentalDuration); // Placeholder - Implement rental price calculation
        require(msg.value >= rentalPrice, "Insufficient funds for rental.");

        // Transfer rental fee to NFT owner (minus platform fee if applicable)
        uint256 platformRentalFee = (rentalPrice * platformFeePercentage) / 100;
        uint256 ownerRentalProceeds = rentalPrice - platformRentalFee;

        (bool feeSuccess, ) = platformFeeRecipient.call{value: platformRentalFee}("");
        require(feeSuccess, "Platform rental fee transfer failed.");

        (bool rentalSuccess, ) = payable(msg.sender).call{value: ownerRentalProceeds}(""); // Rent is paid to renter in this example (typo, should be owner receiving rent)
        require(rentalSuccess, "Rental fee transfer to owner failed.");


        rentalInfos[_tokenId] = RentalInfo({
            renter: msg.sender,
            rentalEndTime: block.timestamp + _rentalDuration,
            isRented: true
        });
        emit NFTRented(_tokenId, msg.sender, rentalInfos[_tokenId].rentalEndTime);

        nfts[_tokenId].owner = msg.sender; // Owner remains the same, renter gets rental rights, this line should be removed or corrected if rental ownership is intended
    }

    /// @notice Allows renters to return rented NFTs before the rental period ends.
    /// @param _tokenId ID of the NFT to return.
    function returnNFT(uint256 _tokenId) public nftExists(_tokenId) nftRented(_tokenId) whenNotPaused {
        require(rentalInfos[_tokenId].renter == msg.sender, "Only the renter can return the NFT.");
        rentalInfos[_tokenId].isRented = false;
        emit NFTReturned(_tokenId, msg.sender);
    }

    /// @notice Allows renters to extend the rental period.
    /// @param _tokenId ID of the NFT to extend rental for.
    /// @param _extensionDuration Duration to extend the rental by in seconds.
    function extendRental(uint256 _tokenId, uint256 _extensionDuration) public payable nftExists(_tokenId) nftRented(_tokenId) whenNotPaused {
        require(rentalInfos[_tokenId].renter == msg.sender, "Only the renter can extend the rental.");
        require(_extensionDuration > 0, "Extension duration must be greater than zero.");
        uint256 extensionPrice = calculateRentalPrice(_tokenId, _extensionDuration); // Placeholder - Implement extension price calculation
        require(msg.value >= extensionPrice, "Insufficient funds for rental extension.");

        // Transfer extension fee (similar to rentNFT, handle platform fee etc.)
        uint256 platformExtensionFee = (extensionPrice * platformFeePercentage) / 100;
        uint256 ownerExtensionProceeds = extensionPrice - platformExtensionFee;

        (bool feeSuccess, ) = platformFeeRecipient.call{value: platformExtensionFee}("");
        require(feeSuccess, "Platform extension fee transfer failed.");

        (bool extensionSuccess, ) = payable(msg.sender).call{value: ownerExtensionProceeds}(""); // Extension fee to owner
        require(extensionSuccess, "Extension fee transfer to owner failed.");


        rentalInfos[_tokenId].rentalEndTime += _extensionDuration;
        emit RentalExtended(_tokenId, msg.sender, rentalInfos[_tokenId].rentalEndTime);
    }

    /// @notice Creates an auction for an NFT.
    /// @param _tokenId ID of the NFT to auction.
    /// @param _startingBid Starting bid price in wei.
    /// @param _auctionDuration Auction duration in seconds.
    /// @param _auctionType Type of auction (ENGLISH or DUTCH).
    function createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration, AuctionType _auctionType) public nftExists(_tokenId) onlyNFTOwner(_tokenId) nftNotListed(_tokenId) nftNotStaked(_tokenId) nftNotRented(_tokenId) whenNotPaused {
        require(_startingBid > 0, "Starting bid must be greater than zero.");
        require(_auctionDuration > 0, "Auction duration must be greater than zero.");

        auctions[auctionCounter] = Auction({
            tokenId: _tokenId,
            auctionType: _auctionType,
            startingBid: _startingBid,
            endTime: block.timestamp + _auctionDuration,
            highestBidder: address(0),
            highestBid: 0,
            isActive: true
        });
        emit AuctionCreated(auctionCounter, _tokenId, _auctionType, _startingBid, auctions[auctionCounter].endTime);
        auctionCounter++;
    }

    /// @notice Allows users to bid on an ongoing auction.
    /// @param _auctionId ID of the auction to bid on.
    function bidOnAuction(uint256 _auctionId) public payable validAuction(_auctionId) whenNotPaused {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp < auction.endTime, "Auction has ended.");
        require(msg.value > auction.highestBid, "Bid amount must be higher than the current highest bid.");

        if (auction.highestBidder != address(0)) {
            // Refund previous highest bidder
            (bool refundSuccess, ) = payable(auction.highestBidder).call{value: auction.highestBid}("");
            require(refundSuccess, "Refund to previous bidder failed.");
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        emit BidPlaced(_auctionId, msg.sender, msg.value);
    }

    /// @notice Finalizes an auction, transferring NFT and funds to the winner and seller.
    /// @param _auctionId ID of the auction to finalize.
    function finalizeAuction(uint256 _auctionId) public validAuction(_auctionId) auctionCreator(_auctionId) whenNotPaused {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp >= auction.endTime, "Auction is not yet ended.");
        auction.isActive = false;

        uint256 platformAuctionFee = (auction.highestBid * platformFeePercentage) / 100;
        uint256 sellerAuctionProceeds = auction.highestBid - platformAuctionFee;

        // Transfer platform fee
        (bool feeSuccess, ) = platformFeeRecipient.call{value: platformAuctionFee}("");
        require(feeSuccess, "Platform auction fee transfer failed.");

        // Transfer proceeds to seller
        (bool sellerSuccess, ) = payable(nfts[auction.tokenId].owner).call{value: sellerAuctionProceeds}("");
        require(sellerSuccess, "Seller auction proceeds transfer failed.");


        if (auction.highestBidder != address(0)) {
            nfts[auction.tokenId].owner = auction.highestBidder;
            emit AuctionFinalized(_auctionId, auction.tokenId, auction.highestBidder, auction.highestBid);
        } else {
            // No bids, NFT remains with owner
            emit AuctionFinalized(_auctionId, auction.tokenId, address(0), 0);
        }
    }

    /// @notice Creates a bundle of NFTs for sale at a fixed price.
    /// @param _tokenIds Array of NFT token IDs to include in the bundle.
    /// @param _bundlePrice Price of the entire bundle.
    function createBundleSale(uint256[] memory _tokenIds, uint256 _bundlePrice) public whenNotPaused {
        require(_tokenIds.length > 0, "Bundle must contain at least one NFT.");
        require(_bundlePrice > 0, "Bundle price must be greater than zero.");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            require(nftExists(tokenId), "NFT in bundle does not exist.");
            require(onlyNFTOwner(tokenId), "You are not the owner of all NFTs in the bundle."); // Simplified: All NFTs must belong to the caller
            require(nftNotListed(tokenId), "One of the NFTs in the bundle is already listed.");
            require(nftNotStaked(tokenId), "One of the NFTs in the bundle is staked.");
            require(nftNotRented(tokenId), "One of the NFTs in the bundle is rented.");
        }

        bundleSales[bundleCounter] = BundleSale({
            tokenIds: _tokenIds,
            bundlePrice: _bundlePrice,
            seller: msg.sender,
            isActive: true
        });
        emit BundleSaleCreated(bundleCounter, _tokenIds, _bundlePrice, msg.sender);
        bundleCounter++;
    }

    /// @notice Allows users to buy an NFT bundle.
    /// @param _bundleId ID of the bundle to buy.
    function buyBundle(uint256 _bundleId) public payable bundleExists(_bundleId) whenNotPaused {
        BundleSale storage bundle = bundleSales[_bundleId];
        require(msg.value >= bundle.bundlePrice, "Insufficient funds for bundle purchase.");

        uint256 platformBundleFee = (bundle.bundlePrice * platformFeePercentage) / 100;
        uint256 sellerBundleProceeds = bundle.bundlePrice - platformBundleFee;

        // Transfer platform fee
        (bool feeSuccess, ) = platformFeeRecipient.call{value: platformBundleFee}("");
        require(feeSuccess, "Platform bundle fee transfer failed.");

        // Transfer proceeds to seller
        (bool sellerSuccess, ) = payable(bundle.seller).call{value: sellerBundleProceeds}("");
        require(sellerSuccess, "Seller bundle proceeds transfer failed.");


        for (uint256 i = 0; i < bundle.tokenIds.length; i++) {
            nfts[bundle.tokenIds[i]].owner = msg.sender;
            delete listings[bundle.tokenIds[i]]; // Delist any listed items in bundle
        }
        bundle.isActive = false;
        emit BundleBought(_bundleId, msg.sender, bundle.bundlePrice);
    }


    // --- 4. Royalty & Platform Management Functions ---

    /// @notice Sets the royalty percentage for an NFT. Can only be called by the NFT owner.
    /// @param _tokenId ID of the NFT to set royalty for.
    /// @param _royaltyPercentage Royalty percentage (e.g., 5 for 5%).
    function setRoyaltyPercentage(uint256 _tokenId, uint256 _royaltyPercentage) public nftExists(_tokenId) onlyOwner { // For simplicity, only owner can set royalty, can be changed to creator if tracked.
        require(_royaltyPercentage <= 100, "Royalty percentage cannot exceed 100%.");
        nfts[_tokenId].royaltyPercentage = _royaltyPercentage;
        emit RoyaltyPercentageSet(_tokenId, _royaltyPercentage);
    }

    /// @notice Retrieves the royalty percentage for an NFT.
    /// @param _tokenId ID of the NFT.
    /// @return The royalty percentage.
    function getRoyaltyPercentage(uint256 _tokenId) public view nftExists(_tokenId) returns (uint256) {
        return nfts[_tokenId].royaltyPercentage;
    }

    /// @notice Sets the platform fee percentage for all marketplace transactions. Can only be called by the contract owner.
    /// @param _feePercentage Platform fee percentage (e.g., 2 for 2%).
    function setPlatformFeePercentage(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 100, "Platform fee percentage cannot exceed 100%.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeePercentageSet(_feePercentage);
    }

    /// @notice Retrieves the current platform fee percentage.
    /// @return The platform fee percentage.
    function getPlatformFeePercentage() public view returns (uint256) {
        return platformFeePercentage;
    }

    /// @notice Allows the contract owner to withdraw accumulated platform fees.
    function withdrawPlatformFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No platform fees to withdraw.");
        (bool success, ) = platformFeeRecipient.call{value: balance}("");
        require(success, "Platform fee withdrawal failed.");
        emit PlatformFeesWithdrawn(balance, platformFeeRecipient);
    }

    /// @notice Pauses all marketplace functionalities. Can only be called by the contract owner.
    function pauseMarketplace() public onlyOwner whenNotPaused {
        marketplacePaused = true;
        emit MarketplacePaused();
    }

    /// @notice Resumes marketplace functionalities. Can only be called by the contract owner.
    function unpauseMarketplace() public onlyOwner whenPaused {
        marketplacePaused = false;
        emit MarketplaceUnpaused();
    }


    // --- Utility/Helper Functions (Internal/Private) ---

    /// @dev Placeholder function to calculate rental price based on NFT and duration.
    /// @param _tokenId ID of the NFT.
    /// @param _duration Rental duration in seconds.
    /// @return Calculated rental price (placeholder - needs implementation).
    function calculateRentalPrice(uint256 _tokenId, uint256 _duration) internal view returns (uint256) {
        // --- Placeholder for rental price calculation logic ---
        // This could be based on NFT rarity, market value, rental duration, etc.
        // For now, a simple placeholder:
        return _duration * 1 wei; // Example: 1 wei per second
        // --- End of placeholder ---
    }

    /// @dev Placeholder function to calculate staking rewards (needs implementation).
    /// @param _tokenId ID of the NFT.
    /// @return Calculated staking reward amount (placeholder - needs implementation).
    function calculateStakingRewards(uint256 _tokenId) internal view returns (uint256) {
        // --- Placeholder for staking reward calculation logic ---
        // This could be based on staking duration, reward rates, NFT rarity, etc.
        // For now, a simple placeholder (no rewards):
        return 0;
        // --- End of placeholder ---
    }

    // --- Fallback and Receive functions for receiving ETH ---
    receive() external payable {}
    fallback() external payable {}
}
```