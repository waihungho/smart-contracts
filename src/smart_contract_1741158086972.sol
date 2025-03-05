```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI-Powered Curation & Advanced Features
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a decentralized NFT marketplace with dynamic NFT capabilities,
 * AI-powered curation integration (off-chain oracle based), advanced listing options, staking,
 * governance, and more. It goes beyond typical marketplace functionalities to offer a richer
 * and more engaging NFT trading experience.
 *
 * **Outline and Function Summary:**
 *
 * **Core Marketplace Functions:**
 * 1. `listItem(address _nftContract, uint256 _tokenId, uint256 _price, ListingType _listingType, uint256 _duration)`:  Allows users to list their NFTs for sale or auction. Supports fixed price and timed auctions.
 * 2. `buyItem(uint256 _listingId)`:  Allows buyers to purchase NFTs listed at a fixed price.
 * 3. `cancelListing(uint256 _listingId)`: Allows sellers to cancel their NFT listings before they are sold or auction ends.
 * 4. `bidOnItem(uint256 _listingId)`: Allows users to place bids on NFTs listed in auctions.
 * 5. `acceptBid(uint256 _listingId, uint256 _bidId)`: Allows sellers to accept a bid and finalize the auction sale.
 * 6. `settleAuction(uint256 _listingId)`:  Automatically settles an auction if the seller hasn't accepted a bid after the auction duration. Selects the highest bidder.
 * 7. `getListingDetails(uint256 _listingId)`: Retrieves detailed information about a specific NFT listing.
 * 8. `getAllListings()`: Returns a list of all active NFT listings in the marketplace.
 * 9. `getListingsBySeller(address _seller)`: Returns a list of listings created by a specific seller.
 * 10. `getListingsByNFTContract(address _nftContract)`: Returns a list of listings for a specific NFT contract.
 *
 * **Dynamic NFT & Curation Features:**
 * 11. `reportNFT(uint256 _listingId, ReportReason _reason)`: Allows users to report listings for policy violations. Reports can be used for off-chain AI curation and moderation.
 * 12. `setAICurationScore(uint256 _listingId, uint256 _score)`: (Oracle function) Allows a designated oracle to update the AI curation score of a listing.
 * 13. `getAICurationScore(uint256 _listingId)`: Retrieves the AI curation score of a listing.
 * 14. `setDynamicMetadataURI(uint256 _listingId, string memory _metadataURI)`: Allows authorized entities (e.g., NFT creator, curation DAO) to update the dynamic metadata URI of a listed NFT.
 * 15. `getDynamicMetadataURI(uint256 _listingId)`: Retrieves the dynamic metadata URI for a listing.
 *
 * **Staking & Reward Features:**
 * 16. `stakeNFTForCuration(uint256 _listingId)`: Allows users to stake platform tokens to support and curate a specific NFT listing.
 * 17. `unstakeNFTForCuration(uint256 _listingId)`: Allows users to unstake their platform tokens from a listing.
 * 18. `claimCurationRewards(uint256 _listingId)`: Allows stakers to claim rewards based on the performance/popularity of the curated listing.
 * 19. `getTotalStakedForListing(uint256 _listingId)`: Returns the total amount of platform tokens staked for a specific listing.
 *
 * **Platform Management & Utility Functions:**
 * 20. `setPlatformFee(uint256 _feePercentage)`: Allows the platform owner to set the marketplace platform fee.
 * 21. `withdrawPlatformFees()`: Allows the platform owner to withdraw accumulated platform fees.
 * 22. `pauseMarketplace()`: Allows the platform owner to pause all marketplace functionalities.
 * 23. `unpauseMarketplace()`: Allows the platform owner to unpause the marketplace.
 * 24. `setOracleAddress(address _oracleAddress)`:  Allows the platform owner to set the address of the trusted AI curation oracle.
 * 25. `setPlatformTokenAddress(address _platformTokenAddress)`: Allows the platform owner to set the address of the platform's utility token.
 */

contract DynamicNFTMarketplace {

    // Enums
    enum ListingType { FIXED_PRICE, AUCTION }
    enum ListingStatus { ACTIVE, SOLD, CANCELLED, AUCTION_ENDED }
    enum ReportReason { INAPPROPRIATE_CONTENT, FAKE_NFT, POLICY_VIOLATION, OTHER }

    // Structs
    struct Listing {
        uint256 listingId;
        address nftContract;
        uint256 tokenId;
        address seller;
        uint256 price; // Fixed price or starting bid
        ListingType listingType;
        ListingStatus status;
        uint256 startTime;
        uint256 duration; // Auction duration in seconds
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        string dynamicMetadataURI; // URI for dynamic metadata updates
        uint256 aiCurationScore; // Score provided by AI oracle (off-chain)
    }

    struct Bid {
        uint256 bidId;
        uint256 listingId;
        address bidder;
        uint256 bidAmount;
        uint256 timestamp;
    }

    struct Stake {
        uint256 listingId;
        address staker;
        uint256 amount;
    }

    // State variables
    Listing[] public listings;
    Bid[] public bids;
    Stake[] public stakes;
    uint256 public nextListingId = 1;
    uint256 public nextBidId = 1;
    uint256 public platformFeePercentage = 2; // Default 2% platform fee
    address public platformOwner;
    bool public paused = false;
    address public oracleAddress;
    address public platformTokenAddress; // Address of the platform's utility token

    // Mappings
    mapping(uint256 => Listing) public listingDetails;
    mapping(uint256 => Bid[]) public listingBids;
    mapping(uint256 => Stake[]) public listingStakes;
    mapping(uint256 => uint256) public totalStakedPerListing; // Listing ID => Total staked amount

    // Events
    event ListingCreated(uint256 listingId, address nftContract, uint256 tokenId, address seller, uint256 price, ListingType listingType);
    event ItemBought(uint256 listingId, address buyer, uint256 price);
    event ListingCancelled(uint256 listingId, address seller);
    event BidPlaced(uint256 bidId, uint256 listingId, address bidder, uint256 bidAmount);
    event BidAccepted(uint256 listingId, uint256 bidId, address buyer, uint256 price);
    event AuctionSettled(uint256 listingId, address buyer, uint256 price);
    event NFTReported(uint256 listingId, address reporter, ReportReason reason);
    event AICurationScoreUpdated(uint256 listingId, uint256 score, address oracle);
    event DynamicMetadataURISet(uint256 listingId, string metadataURI, address setter);
    event NFTStakedForCuration(uint256 listingId, address staker, uint256 amount);
    event NFTUnstakedForCuration(uint256 listingId, address staker, uint256 amount);
    event CurationRewardsClaimed(uint256 listingId, address staker, uint256 rewardAmount);
    event PlatformFeeUpdated(uint256 newFeePercentage, address owner);
    event PlatformFeesWithdrawn(uint256 amount, address owner);
    event MarketplacePaused(address owner);
    event MarketplaceUnpaused(address owner);
    event OracleAddressUpdated(address newOracleAddress, address owner);
    event PlatformTokenAddressUpdated(address newPlatformTokenAddress, address owner);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == platformOwner, "Only platform owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Marketplace is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Marketplace is not paused.");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Only the designated oracle can call this function.");
        _;
    }

    modifier validListing(uint256 _listingId) {
        require(_listingId > 0 && _listingId <= listings.length, "Invalid listing ID.");
        require(listingDetails[_listingId].status == ListingStatus.ACTIVE, "Listing is not active.");
        _;
    }

    modifier validAuctionListing(uint256 _listingId) {
        require(listingDetails[_listingId].listingType == ListingType.AUCTION, "Listing is not an auction.");
        _;
    }

    modifier validFixedPriceListing(uint256 _listingId) {
        require(listingDetails[_listingId].listingType == ListingType.FIXED_PRICE, "Listing is not a fixed price listing.");
        _;
    }


    constructor() {
        platformOwner = msg.sender;
    }

    /**
     * @dev Lists an NFT for sale or auction on the marketplace.
     * @param _nftContract Address of the NFT contract.
     * @param _tokenId Token ID of the NFT.
     * @param _price Fixed price for fixed price listings, starting bid for auctions.
     * @param _listingType Type of listing (FIXED_PRICE or AUCTION).
     * @param _duration Auction duration in seconds (only applicable for auctions).
     */
    function listItem(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price,
        ListingType _listingType,
        uint256 _duration
    ) external whenNotPaused {
        require(_price > 0, "Price must be greater than zero.");
        require(_duration >= 0, "Duration must be non-negative."); // Duration 0 is allowed for fixed price
        if (_listingType == ListingType.AUCTION) {
            require(_duration > 0, "Auction duration must be greater than zero.");
        }

        // Transfer NFT ownership to this contract for escrow during listing
        // Assuming _nftContract is an ERC721 or ERC1155 compliant contract with `transferFrom` or `safeTransferFrom`
        IERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenId);

        Listing memory newListing = Listing({
            listingId: nextListingId,
            nftContract: _nftContract,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            listingType: _listingType,
            status: ListingStatus.ACTIVE,
            startTime: block.timestamp,
            duration: _listingType == ListingType.AUCTION ? _duration : 0,
            endTime: _listingType == ListingType.AUCTION ? block.timestamp + _duration : 0,
            highestBidder: address(0),
            highestBid: 0,
            dynamicMetadataURI: "", // Initially empty, can be set later
            aiCurationScore: 0 // Initially 0
        });

        listings.push(newListing);
        listingDetails[nextListingId] = newListing;

        emit ListingCreated(nextListingId, _nftContract, _tokenId, msg.sender, _price, _listingType);
        nextListingId++;
    }

    /**
     * @dev Allows a buyer to purchase an NFT listed at a fixed price.
     * @param _listingId ID of the listing to buy.
     */
    function buyItem(uint256 _listingId) external payable whenNotPaused validListing(_listingId) validFixedPriceListing(_listingId) {
        Listing storage currentListing = listingDetails[_listingId];
        require(msg.value >= currentListing.price, "Insufficient funds.");

        uint256 platformFee = (currentListing.price * platformFeePercentage) / 100;
        uint256 sellerProceeds = currentListing.price - platformFee;

        // Transfer platform fee to platform owner
        payable(platformOwner).transfer(platformFee);
        // Transfer proceeds to seller
        payable(currentListing.seller).transfer(sellerProceeds);
        // Transfer NFT to buyer
        IERC721(currentListing.nftContract).safeTransferFrom(address(this), msg.sender, currentListing.tokenId);

        currentListing.status = ListingStatus.SOLD;
        emit ItemBought(_listingId, msg.sender, currentListing.price);
    }

    /**
     * @dev Cancels an NFT listing before it is sold or auction ends.
     * @param _listingId ID of the listing to cancel.
     */
    function cancelListing(uint256 _listingId) external whenNotPaused validListing(_listingId) {
        Listing storage currentListing = listingDetails[_listingId];
        require(currentListing.seller == msg.sender, "Only seller can cancel listing.");
        require(currentListing.status == ListingStatus.ACTIVE, "Listing is not active.");

        currentListing.status = ListingStatus.CANCELLED;
        // Return NFT to seller
        IERC721(currentListing.nftContract).safeTransferFrom(address(this), msg.sender, currentListing.tokenId);

        emit ListingCancelled(_listingId, msg.sender);
    }

    /**
     * @dev Allows users to place bids on NFTs listed in auctions.
     * @param _listingId ID of the auction listing.
     */
    function bidOnItem(uint256 _listingId) external payable whenNotPaused validListing(_listingId) validAuctionListing(_listingId) {
        Listing storage currentListing = listingDetails[_listingId];
        require(block.timestamp < currentListing.endTime, "Auction has ended.");
        require(msg.value >= currentListing.price, "Bid must be at least the starting bid.");
        require(msg.value > currentListing.highestBid, "Bid must be higher than the current highest bid.");

        // Refund previous highest bidder (if any)
        if (currentListing.highestBidder != address(0)) {
            payable(currentListing.highestBidder).transfer(currentListing.highestBid);
        }

        currentListing.highestBidder = msg.sender;
        currentListing.highestBid = msg.value;

        Bid memory newBid = Bid({
            bidId: nextBidId,
            listingId: _listingId,
            bidder: msg.sender,
            bidAmount: msg.value,
            timestamp: block.timestamp
        });
        bids.push(newBid);
        listingBids[_listingId].push(newBid);

        emit BidPlaced(nextBidId, _listingId, msg.sender, msg.value);
        nextBidId++;
    }

    /**
     * @dev Allows the seller to accept a specific bid and finalize the auction sale.
     * @param _listingId ID of the auction listing.
     * @param _bidId ID of the bid to accept.
     */
    function acceptBid(uint256 _listingId, uint256 _bidId) external whenNotPaused validListing(_listingId) validAuctionListing(_listingId) {
        Listing storage currentListing = listingDetails[_listingId];
        require(currentListing.seller == msg.sender, "Only seller can accept bid.");
        require(currentListing.status == ListingStatus.ACTIVE, "Listing is not active.");
        require(block.timestamp < currentListing.endTime, "Auction has ended. Settle auction instead.");

        Bid memory acceptedBid;
        bool bidFound = false;
        for (uint i = 0; i < listingBids[_listingId].length; i++) {
            if (listingBids[_listingId][i].bidId == _bidId) {
                acceptedBid = listingBids[_listingId][i];
                bidFound = true;
                break;
            }
        }
        require(bidFound, "Bid not found for this listing.");
        require(acceptedBid.bidder == currentListing.highestBidder, "Accepted bid is not the highest bid.");

        uint256 platformFee = (acceptedBid.bidAmount * platformFeePercentage) / 100;
        uint256 sellerProceeds = acceptedBid.bidAmount - platformFee;

        // Transfer platform fee to platform owner
        payable(platformOwner).transfer(platformFee);
        // Transfer proceeds to seller
        payable(currentListing.seller).transfer(sellerProceeds);
        // Transfer NFT to buyer (bidder)
        IERC721(currentListing.nftContract).safeTransferFrom(address(this), acceptedBid.bidder, currentListing.tokenId);

        currentListing.status = ListingStatus.SOLD;
        emit BidAccepted(_listingId, _bidId, acceptedBid.bidder, acceptedBid.bidAmount);

        // Refund other bidders
        for (uint i = 0; i < listingBids[_listingId].length; i++) {
            Bid memory bid = listingBids[_listingId][i];
            if (bid.bidder != acceptedBid.bidder) {
                payable(bid.bidder).transfer(bid.bidAmount);
            }
        }
    }

    /**
     * @dev Automatically settles an auction after the duration ends if the seller hasn't accepted a bid.
     * Selects the highest bidder as the winner.
     * @param _listingId ID of the auction listing.
     */
    function settleAuction(uint256 _listingId) external whenNotPaused validListing(_listingId) validAuctionListing(_listingId) {
        Listing storage currentListing = listingDetails[_listingId];
        require(currentListing.status == ListingStatus.ACTIVE, "Auction is not active.");
        require(block.timestamp >= currentListing.endTime, "Auction has not ended yet.");

        if (currentListing.highestBidder != address(0)) {
            uint256 platformFee = (currentListing.highestBid * platformFeePercentage) / 100;
            uint256 sellerProceeds = currentListing.highestBid - platformFee;

            // Transfer platform fee to platform owner
            payable(platformOwner).transfer(platformFee);
            // Transfer proceeds to seller
            payable(currentListing.seller).transfer(sellerProceeds);
            // Transfer NFT to highest bidder
            IERC721(currentListing.nftContract).safeTransferFrom(address(this), currentListing.highestBidder, currentListing.tokenId);

            currentListing.status = ListingStatus.AUCTION_ENDED;
            emit AuctionSettled(_listingId, currentListing.highestBidder, currentListing.highestBid);

            // Refund other bidders
            for (uint i = 0; i < listingBids[_listingId].length; i++) {
                Bid memory bid = listingBids[_listingId][i];
                if (bid.bidder != currentListing.highestBidder) {
                    payable(bid.bidder).transfer(bid.bidAmount);
                }
            }
        } else {
            // No bids placed, return NFT to seller
            currentListing.status = ListingStatus.CANCELLED;
            IERC721(currentListing.nftContract).safeTransferFrom(address(this), currentListing.seller, currentListing.tokenId);
            emit ListingCancelled(_listingId, currentListing.seller);
        }
    }

    /**
     * @dev Retrieves detailed information about a specific NFT listing.
     * @param _listingId ID of the listing.
     * @return Listing struct containing listing details.
     */
    function getListingDetails(uint256 _listingId) external view returns (Listing memory) {
        require(_listingId > 0 && _listingId <= listings.length, "Invalid listing ID.");
        return listingDetails[_listingId];
    }

    /**
     * @dev Returns a list of all active NFT listings in the marketplace.
     * @return Array of listing IDs.
     */
    function getAllListings() external view returns (uint256[] memory) {
        uint256[] memory activeListingIds = new uint256[](listings.length);
        uint256 count = 0;
        for (uint i = 0; i < listings.length; i++) {
            if (listings[i].status == ListingStatus.ACTIVE) {
                activeListingIds[count] = listings[i].listingId;
                count++;
            }
        }
        // Resize array to actual count
        assembly {
            mstore(activeListingIds, count)
        }
        return activeListingIds;
    }

    /**
     * @dev Returns a list of listings created by a specific seller.
     * @param _seller Address of the seller.
     * @return Array of listing IDs.
     */
    function getListingsBySeller(address _seller) external view returns (uint256[] memory) {
        uint256[] memory sellerListingIds = new uint256[](listings.length);
        uint256 count = 0;
        for (uint i = 0; i < listings.length; i++) {
            if (listings[i].seller == _seller) {
                sellerListingIds[count] = listings[i].listingId;
                count++;
            }
        }
        // Resize array to actual count
        assembly {
            mstore(sellerListingIds, count)
        }
        return sellerListingIds;
    }

    /**
     * @dev Returns a list of listings for a specific NFT contract.
     * @param _nftContract Address of the NFT contract.
     * @return Array of listing IDs.
     */
    function getListingsByNFTContract(address _nftContract) external view returns (uint256[] memory) {
        uint256[] memory contractListingIds = new uint256[](listings.length);
        uint256 count = 0;
        for (uint i = 0; i < listings.length; i++) {
            if (listings[i].nftContract == _nftContract) {
                contractListingIds[count] = listings[i].listingId;
                count++;
            }
        }
        // Resize array to actual count
        assembly {
            mstore(contractListingIds, count)
        }
        return contractListingIds;
    }

    /**
     * @dev Allows users to report a listing for policy violations.
     * This can be used for off-chain AI curation and moderation.
     * @param _listingId ID of the listing to report.
     * @param _reason Reason for reporting.
     */
    function reportNFT(uint256 _listingId, ReportReason _reason) external whenNotPaused validListing(_listingId) {
        emit NFTReported(_listingId, msg.sender, _reason);
        // In a real application, this event would trigger an off-chain process
        // that involves AI curation and potential moderation actions.
    }

    /**
     * @dev (Oracle function) Allows a designated oracle to update the AI curation score of a listing.
     * @param _listingId ID of the listing to update.
     * @param _score AI curation score (e.g., 0-100).
     */
    function setAICurationScore(uint256 _listingId, uint256 _score) external onlyOracle whenNotPaused validListing(_listingId) {
        listingDetails[_listingId].aiCurationScore = _score;
        emit AICurationScoreUpdated(_listingId, _score, msg.sender);
    }

    /**
     * @dev Retrieves the AI curation score of a listing.
     * @param _listingId ID of the listing.
     * @return AI curation score.
     */
    function getAICurationScore(uint256 _listingId) external view returns (uint256) {
        require(_listingId > 0 && _listingId <= listings.length, "Invalid listing ID.");
        return listingDetails[_listingId].aiCurationScore;
    }

    /**
     * @dev Allows authorized entities (e.g., NFT creator, curation DAO) to update the dynamic metadata URI of a listed NFT.
     * @param _listingId ID of the listing.
     * @param _metadataURI New dynamic metadata URI.
     */
    function setDynamicMetadataURI(uint256 _listingId, string memory _metadataURI) external whenNotPaused validListing(_listingId) {
        // In a real-world scenario, access control here could be more sophisticated,
        // e.g., checking if msg.sender is the NFT creator or part of a curation DAO.
        // For simplicity, we'll just allow platform owner for now.
        require(msg.sender == platformOwner, "Only authorized entity can set dynamic metadata URI.");

        listingDetails[_listingId].dynamicMetadataURI = _metadataURI;
        emit DynamicMetadataURISet(_listingId, _metadataURI, msg.sender);
    }

    /**
     * @dev Retrieves the dynamic metadata URI for a listing.
     * @param _listingId ID of the listing.
     * @return Dynamic metadata URI string.
     */
    function getDynamicMetadataURI(uint256 _listingId) external view returns (string memory) {
        require(_listingId > 0 && _listingId <= listings.length, "Invalid listing ID.");
        return listingDetails[_listingId].dynamicMetadataURI;
    }

    /**
     * @dev Allows users to stake platform tokens to support and curate a specific NFT listing.
     * @param _listingId ID of the listing to stake for.
     */
    function stakeNFTForCuration(uint256 _listingId) external whenNotPaused validListing(_listingId) {
        require(platformTokenAddress != address(0), "Platform token address not set.");
        // Assume platform token is ERC20 compatible
        IERC20 platformToken = IERC20(platformTokenAddress);
        uint256 stakeAmount = 100 * 10**18; // Example: Stake 100 platform tokens (adjust based on token decimals)

        require(platformToken.allowance(msg.sender, address(this)) >= stakeAmount, "Insufficient platform token allowance.");
        require(platformToken.balanceOf(msg.sender) >= stakeAmount, "Insufficient platform token balance.");

        // Transfer tokens from staker to this contract (for staking)
        platformToken.transferFrom(msg.sender, address(this), stakeAmount);

        Stake memory newStake = Stake({
            listingId: _listingId,
            staker: msg.sender,
            amount: stakeAmount
        });
        stakes.push(newStake);
        listingStakes[_listingId].push(newStake);
        totalStakedPerListing[_listingId] += stakeAmount;

        emit NFTStakedForCuration(_listingId, msg.sender, stakeAmount);
    }

    /**
     * @dev Allows users to unstake their platform tokens from a listing.
     * @param _listingId ID of the listing to unstake from.
     */
    function unstakeNFTForCuration(uint256 _listingId) external whenNotPaused validListing(_listingId) {
        uint256 unstakeAmount = 0;
        uint256 stakeIndexToRemove = type(uint256).max;

        for (uint i = 0; i < listingStakes[_listingId].length; i++) {
            if (listingStakes[_listingId][i].staker == msg.sender) {
                unstakeAmount = listingStakes[_listingId][i].amount;
                stakeIndexToRemove = i;
                break; // Assuming only one stake per user per listing for simplicity
            }
        }
        require(stakeIndexToRemove != type(uint256).max, "No stake found for this user on this listing.");

        // Return staked tokens to user
        IERC20(platformTokenAddress).transfer(msg.sender, unstakeAmount);

        // Remove stake from mapping and array (shifting elements in array for simplicity - consider more efficient data structures for large scale)
        delete listingStakes[_listingId][stakeIndexToRemove];
        if (stakeIndexToRemove < listingStakes[_listingId].length - 1) {
            for (uint j = stakeIndexToRemove; j < listingStakes[_listingId].length - 1; j++) {
                listingStakes[_listingId][j] = listingStakes[_listingId][j + 1];
            }
        }
        listingStakes[_listingId].pop();
        totalStakedPerListing[_listingId] -= unstakeAmount;


        emit NFTUnstakedForCuration(_listingId, msg.sender, unstakeAmount);
    }

    /**
     * @dev Allows stakers to claim rewards based on the performance/popularity of the curated listing.
     * Reward mechanism logic (how rewards are calculated and distributed) would need to be implemented.
     * This is a placeholder function.
     * @param _listingId ID of the curated listing.
     */
    function claimCurationRewards(uint256 _listingId) external whenNotPaused validListing(_listingId) {
        // *** Placeholder for reward calculation and distribution logic ***
        // Example: Reward based on AI curation score, sales volume, or time staked.
        uint256 rewardAmount = 10 * 10**18; // Example reward: 10 platform tokens (adjust based on tokenomics)

        // Transfer reward tokens to staker
        IERC20(platformTokenAddress).transfer(msg.sender, rewardAmount);

        emit CurationRewardsClaimed(_listingId, msg.sender, rewardAmount);
    }

    /**
     * @dev Returns the total amount of platform tokens staked for a specific listing.
     * @param _listingId ID of the listing.
     * @return Total staked amount.
     */
    function getTotalStakedForListing(uint256 _listingId) external view returns (uint256) {
        require(_listingId > 0 && _listingId <= listings.length, "Invalid listing ID.");
        return totalStakedPerListing[_listingId];
    }

    /**
     * @dev Allows the platform owner to set the marketplace platform fee percentage.
     * @param _feePercentage New platform fee percentage (e.g., 2 for 2%).
     */
    function setPlatformFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeUpdated(_feePercentage, msg.sender);
    }

    /**
     * @dev Allows the platform owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(platformOwner).transfer(balance);
        emit PlatformFeesWithdrawn(balance, msg.sender);
    }

    /**
     * @dev Allows the platform owner to pause all marketplace functionalities.
     */
    function pauseMarketplace() external onlyOwner whenNotPaused {
        paused = true;
        emit MarketplacePaused(msg.sender);
    }

    /**
     * @dev Allows the platform owner to unpause the marketplace.
     */
    function unpauseMarketplace() external onlyOwner whenPaused {
        paused = false;
        emit MarketplaceUnpaused(msg.sender);
    }

    /**
     * @dev Allows the platform owner to set the address of the trusted AI curation oracle.
     * @param _oracleAddress Address of the oracle contract or EOA.
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        oracleAddress = _oracleAddress;
        emit OracleAddressUpdated(_oracleAddress, msg.sender);
    }

    /**
     * @dev Allows the platform owner to set the address of the platform's utility token.
     * @param _platformTokenAddress Address of the platform token contract (ERC20).
     */
    function setPlatformTokenAddress(address _platformTokenAddress) external onlyOwner {
        platformTokenAddress = _platformTokenAddress;
        emit PlatformTokenAddressUpdated(_platformTokenAddress, msg.sender);
    }

    // ** Interface for ERC721 (Minimalistic - for demonstration purposes)**
    interface IERC721 {
        function safeTransferFrom(address from, address to, uint256 tokenId) external;
        function transferFrom(address from, address to, uint256 tokenId) external;
    }

    // ** Interface for ERC20 (Minimalistic - for demonstration purposes)**
    interface IERC20 {
        function transfer(address to, uint256 amount) external returns (bool);
        function transferFrom(address from, address to, uint256 amount) external returns (bool);
        function balanceOf(address account) external view returns (uint256);
        function allowance(address owner, address spender) external view returns (uint256);
    }
}
```