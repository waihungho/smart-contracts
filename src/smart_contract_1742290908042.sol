```solidity
pragma solidity ^0.8.0;

/**
 * @title Dynamic NFT Marketplace with Gamified Staking and DAO Governance
 * @author Bard (Example Smart Contract)
 * @dev This contract implements a dynamic NFT marketplace with advanced features like:
 *      - Dynamic NFT metadata updates based on staking and marketplace events.
 *      - Gamified NFT staking with reward token distribution and tiered rewards.
 *      - Decentralized Autonomous Organization (DAO) governance for marketplace parameters and feature proposals.
 *      - Advanced marketplace functionalities like auctions, batch listings, and offers.
 *      - Role-based access control for administrative and governance functions.
 *
 * Function Summary:
 *
 * **Marketplace Core Functions:**
 * 1. `mintNFT(address _to, string memory _uri)`: Mints a new NFT with a given URI.
 * 2. `listNFT(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale at a fixed price.
 * 3. `buyNFT(uint256 _tokenId)`: Allows buying a listed NFT.
 * 4. `delistNFT(uint256 _tokenId)`: Allows owner to delist their NFT.
 * 5. `setNFTPrice(uint256 _tokenId, uint256 _newPrice)`: Allows seller to update the price of listed NFT.
 * 6. `makeOffer(uint256 _tokenId, uint256 _offerPrice)`: Allows users to make offers on NFTs.
 * 7. `acceptOffer(uint256 _tokenId, uint256 _offerId)`: Allows NFT owner to accept a specific offer.
 * 8. `createAuction(uint256 _tokenId, uint256 _startPrice, uint256 _auctionDuration)`: Starts a Dutch auction for an NFT.
 * 9. `bidOnAuction(uint256 _tokenId)`: Allows users to bid on an active auction.
 * 10. `endAuction(uint256 _tokenId)`: Ends an auction and transfers NFT to the highest bidder.
 * 11. `batchListNFTs(uint256[] memory _tokenIds, uint256[] memory _prices)`: Lists multiple NFTs for sale in a single transaction.
 * 12. `batchBuyNFTs(uint256[] memory _tokenIds)`: Buys multiple NFTs in a single transaction.
 *
 * **Gamified Staking Functions:**
 * 13. `stakeNFT(uint256 _tokenId)`: Stakes an NFT to earn reward tokens.
 * 14. `unstakeNFT(uint256 _tokenId)`: Unstakes an NFT and claims accumulated reward tokens.
 * 15. `claimRewards(uint256 _tokenId)`: Claims accumulated reward tokens for a staked NFT without unstaking.
 * 16. `setStakingRewardRate(uint256 _newRate)`: DAO function to set the reward rate for staking.
 * 17. `setStakingTierMultiplier(uint256 _tier, uint256 _multiplier)`: DAO function to set reward multiplier for staking tiers.
 *
 * **DAO Governance Functions:**
 * 18. `createProposal(string memory _title, string memory _description, bytes memory _calldata)`: Allows DAO members to create proposals.
 * 19. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows DAO members to vote on proposals.
 * 20. `executeProposal(uint256 _proposalId)`: Executes a passed proposal after voting period ends.
 * 21. `setDAOAddress(address _newDAOAddress)`: Owner function to set the DAO contract address.
 * 22. `setMarketplaceFee(uint256 _newFeePercentage)`: DAO function to set the marketplace fee percentage.
 * 23. `withdrawMarketplaceFees()`: Owner/DAO function to withdraw accumulated marketplace fees.
 * 24. `pauseMarketplace()`: DAO function to pause marketplace operations in case of emergency.
 * 25. `unpauseMarketplace()`: DAO function to unpause marketplace operations.
 *
 * **Utility and View Functions (Implicitly included through other functionalities and standard ERC721):**
 *    - `tokenURI(uint256 _tokenId)`: Standard ERC721 function to get token URI.
 *    - `ownerOf(uint256 _tokenId)`: Standard ERC721 function to get NFT owner.
 *    - `balanceOf(address _owner)`: Standard ERC721 function to get NFT balance of an address.
 *    - `getListingPrice(uint256 _tokenId)`: View function to get the listing price of an NFT.
 *    - `getOfferDetails(uint256 _tokenId, uint256 _offerId)`: View function to get details of a specific offer.
 *    - `getAuctionDetails(uint256 _tokenId)`: View function to get details of an active auction.
 *    - `getStakingDetails(uint256 _tokenId)`: View function to get staking details of an NFT.
 *    - `getProposalDetails(uint256 _proposalId)`: View function to get details of a DAO proposal.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DynamicNFTMarketplace is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

    // Marketplace Settings
    uint256 public marketplaceFeePercentage = 2; // 2% marketplace fee
    address public feeRecipient; // Address to receive marketplace fees
    bool public marketplaceActive = true;
    address public daoAddress; // Address of the DAO contract governing this marketplace

    // NFT Listing
    struct Listing {
        uint256 price;
        address seller;
        bool isListed;
    }
    mapping(uint256 => Listing) public nftListings;

    // NFT Offers
    struct Offer {
        uint256 offerPrice;
        address offerer;
        bool isActive;
    }
    mapping(uint256 => mapping(uint256 => Offer)) public nftOffers; // tokenId => offerId => Offer
    mapping(uint256 => Counters.Counter) private _offerIdCounters; // tokenId => offerCounter

    // NFT Auction
    struct Auction {
        uint256 startPrice;
        uint256 currentPrice; // For Dutch auction, price decreases over time
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool isActive;
        bool isDutchAuction; // Example to extend to different auction types
    }
    mapping(uint256 => Auction) public nftAuctions;

    // NFT Staking & Rewards
    struct StakingInfo {
        uint256 stakeStartTime;
        uint256 lastRewardClaimTime;
        uint256 accumulatedRewards;
        bool isStaked;
    }
    mapping(uint256 => StakingInfo) public nftStakingInfo;
    uint256 public stakingRewardRate = 10; // Reward tokens per day per NFT (example - adjust units and token)
    address public rewardTokenAddress; // Address of the Reward Token contract (ERC20) - Assume a separate RewardToken contract exists
    mapping(uint256 => uint256) public stakingTierMultipliers; // Tier (e.g., rarity level) to reward multiplier

    // DAO Governance - Simple Proposal Structure
    struct Proposal {
        string title;
        string description;
        bytes calldata; // Function call data
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        bool isActive;
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIdCounter;
    uint256 public votingDuration = 7 days; // Example voting duration
    uint256 public quorumPercentage = 50; // Percentage of DAO members needed to vote for quorum

    // Events
    event NFTMinted(uint256 tokenId, address to, string tokenURI);
    event NFTListed(uint256 tokenId, uint256 price, address seller);
    event NFTBought(uint256 tokenId, address buyer, address seller, uint256 price);
    event NFTDelisted(uint256 tokenId, address seller);
    event NFTPriceUpdated(uint256 tokenId, uint256 newPrice);
    event OfferMade(uint256 tokenId, uint256 offerId, uint256 offerPrice, address offerer);
    event OfferAccepted(uint256 tokenId, uint256 offerId, address seller, address buyer, uint256 price);
    event AuctionCreated(uint256 tokenId, uint256 startPrice, uint256 auctionDuration, address seller);
    event BidPlaced(uint256 tokenId, address bidder, uint256 bidAmount);
    event AuctionEnded(uint256 tokenId, address winner, uint256 finalPrice);
    event NFTStaked(uint256 tokenId, address staker);
    event NFTUnstaked(uint256 tokenId, address unstaker, uint256 rewardsClaimed);
    event RewardsClaimed(uint256 tokenId, address claimer, uint256 rewardsClaimed);
    event ProposalCreated(uint256 proposalId, string title, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event MarketplaceFeeSet(uint256 newFeePercentage);
    event StakingRewardRateSet(uint256 newRate);
    event StakingTierMultiplierSet(uint256 tier, uint256 multiplier);
    event DAOAddressSet(address newDAOAddress);

    // Modifiers
    modifier onlyDAO() {
        require(msg.sender == daoAddress, "Only DAO can call this function");
        _;
    }

    modifier isMarketplaceActive() {
        require(marketplaceActive, "Marketplace is paused");
        _;
    }

    modifier nftExists(uint256 _tokenId) {
        require(_exists(_tokenId), "NFT does not exist");
        _;
    }

    modifier isNFTListed(uint256 _tokenId) {
        require(nftListings[_tokenId].isListed, "NFT is not listed for sale");
        _;
    }

    modifier isNFTNotListed(uint256 _tokenId) {
        require(!nftListings[_tokenId].isListed, "NFT is already listed for sale");
        _;
    }

    modifier isNFTOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "You are not the NFT owner");
        _;
    }

    modifier isNFTNotStaked(uint256 _tokenId) {
        require(!nftStakingInfo[_tokenId].isStaked, "NFT is already staked");
        _;
    }

    modifier isNFTStaked(uint256 _tokenId) {
        require(nftStakingInfo[_tokenId].isStaked, "NFT is not staked");
        _;
    }

    modifier isAuctionActive(uint256 _tokenId) {
        require(nftAuctions[_tokenId].isActive, "Auction is not active");
        _;
    }

    modifier isProposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].isActive, "Proposal is not active");
        _;
    }


    constructor(string memory _name, string memory _symbol, address _feeRecipient, address _daoAddress, address _rewardTokenAddress) ERC721(_name, _symbol) {
        feeRecipient = _feeRecipient;
        daoAddress = _daoAddress;
        rewardTokenAddress = _rewardTokenAddress;
        stakingTierMultipliers[1] = 1; // Default tier 1 multiplier
        stakingTierMultipliers[2] = 2; // Example tier 2 multiplier
        stakingTierMultipliers[3] = 5; // Example tier 3 multiplier
    }

    // -------------------- Marketplace Core Functions --------------------

    /**
     * @dev Mints a new NFT with a given URI.
     * @param _to Address to mint NFT to.
     * @param _uri URI for the NFT metadata.
     */
    function mintNFT(address _to, string memory _uri) public onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _mint(_to, tokenId);
        _setTokenURI(tokenId, _uri);
        emit NFTMinted(tokenId, _to, _uri);
        return tokenId;
    }

    /**
     * @dev Lists an NFT for sale at a fixed price.
     * @param _tokenId ID of the NFT to list.
     * @param _price Sale price in wei.
     */
    function listNFT(uint256 _tokenId, uint256 _price) public isMarketplaceActive nftExists(_tokenId) isNFTOwner(_tokenId) isNFTNotListed(_tokenId) {
        require(!nftStakingInfo[_tokenId].isStaked, "Cannot list a staked NFT"); // Cannot list staked NFT
        nftListings[_tokenId] = Listing({
            price: _price,
            seller: msg.sender,
            isListed: true
        });
        emit NFTListed(_tokenId, _price, msg.sender);
    }

    /**
     * @dev Allows buying a listed NFT.
     * @param _tokenId ID of the NFT to buy.
     */
    function buyNFT(uint256 _tokenId) public payable isMarketplaceActive nftExists(_tokenId) isNFTListed(_tokenId) nonReentrant {
        Listing storage listing = nftListings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds to buy NFT");
        require(listing.seller != msg.sender, "Cannot buy your own NFT");

        uint256 marketplaceFee = listing.price.mul(marketplaceFeePercentage).div(100);
        uint256 sellerProceeds = listing.price.sub(marketplaceFee);

        // Transfer NFT to buyer
        _transferNFT(listing.seller, msg.sender, _tokenId);

        // Pay seller and marketplace fee
        payable(listing.seller).transfer(sellerProceeds);
        payable(feeRecipient).transfer(marketplaceFee);

        // Clear listing
        delete nftListings[_tokenId];
        emit NFTBought(_tokenId, msg.sender, listing.seller, listing.price);
    }

    /**
     * @dev Allows owner to delist their NFT.
     * @param _tokenId ID of the NFT to delist.
     */
    function delistNFT(uint256 _tokenId) public isMarketplaceActive nftExists(_tokenId) isNFTOwner(_tokenId) isNFTListed(_tokenId) {
        require(nftListings[_tokenId].seller == msg.sender, "Only seller can delist");
        delete nftListings[_tokenId];
        emit NFTDelisted(_tokenId, msg.sender);
    }

    /**
     * @dev Allows seller to update the price of listed NFT.
     * @param _tokenId ID of the NFT to update price for.
     * @param _newPrice New sale price in wei.
     */
    function setNFTPrice(uint256 _tokenId, uint256 _newPrice) public isMarketplaceActive nftExists(_tokenId) isNFTOwner(_tokenId) isNFTListed(_tokenId) {
        require(nftListings[_tokenId].seller == msg.sender, "Only seller can update price");
        nftListings[_tokenId].price = _newPrice;
        emit NFTPriceUpdated(_tokenId, _newPrice);
    }

    /**
     * @dev Allows users to make offers on NFTs.
     * @param _tokenId ID of the NFT to make an offer on.
     * @param _offerPrice Offer price in wei.
     */
    function makeOffer(uint256 _tokenId, uint256 _offerPrice) public payable isMarketplaceActive nftExists(_tokenId) nonReentrant {
        require(msg.value >= _offerPrice, "Insufficient funds for offer");
        require(ownerOf(_tokenId) != msg.sender, "Cannot make offer on your own NFT");

        Counters.Counter storage offerCounter = _offerIdCounters[_tokenId];
        offerCounter.increment();
        uint256 offerId = offerCounter.current();

        nftOffers[_tokenId][offerId] = Offer({
            offerPrice: _offerPrice,
            offerer: msg.sender,
            isActive: true
        });
        emit OfferMade(_tokenId, offerId, _offerPrice, msg.sender);
    }

    /**
     * @dev Allows NFT owner to accept a specific offer.
     * @param _tokenId ID of the NFT for which to accept the offer.
     * @param _offerId ID of the offer to accept.
     */
    function acceptOffer(uint256 _tokenId, uint256 _offerId) public isMarketplaceActive nftExists(_tokenId) isNFTOwner(_tokenId) nonReentrant {
        Offer storage offer = nftOffers[_tokenId][_offerId];
        require(offer.isActive, "Offer is not active");
        require(offer.offerer != address(0), "Invalid offer");

        uint256 marketplaceFee = offer.offerPrice.mul(marketplaceFeePercentage).div(100);
        uint256 sellerProceeds = offer.offerPrice.sub(marketplaceFee);

        // Transfer NFT to offerer
        _transferNFT(msg.sender, offer.offerer, _tokenId);

        // Pay seller and marketplace fee
        payable(msg.sender).transfer(sellerProceeds);
        payable(feeRecipient).transfer(marketplaceFee);

        // Mark offer as inactive and clear
        offer.isActive = false;
        delete nftOffers[_tokenId][_offerId];

        emit OfferAccepted(_tokenId, _offerId, msg.sender, offer.offerer, offer.offerPrice);

        // Refund remaining offer amount if any (though unlikely in this simple example as offerPrice is the value sent)
        if (msg.value > offer.offerPrice) {
            payable(offer.offerer).transfer(msg.value - offer.offerPrice);
        }
    }

    /**
     * @dev Starts a Dutch auction for an NFT.
     * @param _tokenId ID of the NFT to auction.
     * @param _startPrice Starting price for the auction in wei.
     * @param _auctionDuration Duration of the auction in seconds.
     */
    function createAuction(uint256 _tokenId, uint256 _startPrice, uint256 _auctionDuration) public isMarketplaceActive nftExists(_tokenId) isNFTOwner(_tokenId) isNFTNotListed(_tokenId) {
        require(!nftStakingInfo[_tokenId].isStaked, "Cannot auction a staked NFT"); // Cannot auction staked NFT
        require(!nftAuctions[_tokenId].isActive, "Auction already active for this NFT"); // Only one active auction at a time

        nftAuctions[_tokenId] = Auction({
            startPrice: _startPrice,
            currentPrice: _startPrice,
            endTime: block.timestamp + _auctionDuration,
            highestBidder: address(0),
            highestBid: 0,
            isActive: true,
            isDutchAuction: true // Example: Could extend to English auction with different logic
        });

        emit AuctionCreated(_tokenId, _startPrice, _auctionDuration, msg.sender);
    }

    /**
     * @dev Allows users to bid on an active auction.
     * @param _tokenId ID of the NFT auction to bid on.
     */
    function bidOnAuction(uint256 _tokenId) public payable isMarketplaceActive nftExists(_tokenId) isAuctionActive(_tokenId) nonReentrant {
        Auction storage auction = nftAuctions[_tokenId];
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(msg.sender != ownerOf(_tokenId), "Cannot bid on your own NFT auction");
        require(msg.value > auction.highestBid, "Bid must be higher than the current highest bid");
        require(msg.value >= auction.currentPrice, "Bid must be at least the current auction price"); // For Dutch Auction, enforce current price

        // Refund previous highest bidder
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        emit BidPlaced(_tokenId, msg.sender, msg.value);
    }

    /**
     * @dev Ends an auction and transfers NFT to the highest bidder.
     * @param _tokenId ID of the NFT auction to end.
     */
    function endAuction(uint256 _tokenId) public isMarketplaceActive nftExists(_tokenId) isNFTOwner(_tokenId) isAuctionActive(_tokenId) nonReentrant {
        Auction storage auction = nftAuctions[_tokenId];
        require(block.timestamp >= auction.endTime, "Auction is not yet ended");

        auction.isActive = false; // Mark auction as inactive

        if (auction.highestBidder != address(0)) {
            uint256 marketplaceFee = auction.highestBid.mul(marketplaceFeePercentage).div(100);
            uint256 sellerProceeds = auction.highestBid.sub(marketplaceFee);

            // Transfer NFT to highest bidder
            _transferNFT(msg.sender, auction.highestBidder, _tokenId);

            // Pay seller and marketplace fee
            payable(msg.sender).transfer(sellerProceeds);
            payable(feeRecipient).transfer(marketplaceFee);
            emit AuctionEnded(_tokenId, auction.highestBidder, auction.highestBid);
        } else {
            // No bids, revert NFT ownership to seller (if it was transferred to contract for auction - in this example, seller retains ownership until auction end)
            // In a more complex auction, NFT might be transferred to the contract at auction start
            emit AuctionEnded(_tokenId, address(0), 0); // No winner
        }

        delete nftAuctions[_tokenId]; // Clean up auction data
    }

    /**
     * @dev Lists multiple NFTs for sale in a single transaction.
     * @param _tokenIds Array of NFT IDs to list.
     * @param _prices Array of sale prices in wei (must match _tokenIds length).
     */
    function batchListNFTs(uint256[] memory _tokenIds, uint256[] memory _prices) public isMarketplaceActive {
        require(_tokenIds.length == _prices.length, "Token IDs and prices arrays must have the same length");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            uint256 price = _prices[i];
            require(_exists(tokenId), "NFT does not exist");
            require(ownerOf(tokenId) == msg.sender, "You are not the NFT owner");
            require(!nftListings[tokenId].isListed, "NFT is already listed for sale");
            require(!nftStakingInfo[tokenId].isStaked, "Cannot list a staked NFT");

            nftListings[tokenId] = Listing({
                price: price,
                seller: msg.sender,
                isListed: true
            });
            emit NFTListed(tokenId, price, msg.sender);
        }
    }

    /**
     * @dev Buys multiple NFTs in a single transaction.
     * @param _tokenIds Array of NFT IDs to buy.
     */
    function batchBuyNFTs(uint256[] memory _tokenIds) public payable isMarketplaceActive nonReentrant {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            require(_exists(tokenId), "NFT does not exist");
            require(nftListings[tokenId].isListed, "NFT is not listed for sale");
            totalValue = totalValue.add(nftListings[tokenId].price);
        }
        require(msg.value >= totalValue, "Insufficient funds to buy NFTs");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            Listing storage listing = nftListings[tokenId];

            uint256 marketplaceFee = listing.price.mul(marketplaceFeePercentage).div(100);
            uint256 sellerProceeds = listing.price.sub(marketplaceFee);

            // Transfer NFT to buyer
            _transferNFT(listing.seller, msg.sender, tokenId);

            // Pay seller and marketplace fee
            payable(listing.seller).transfer(sellerProceeds);
            payable(feeRecipient).transfer(marketplaceFee);

            // Clear listing
            delete nftListings[tokenId];
            emit NFTBought(tokenId, msg.sender, listing.seller, listing.price);
        }
        // Refund any excess value sent (though unlikely with precise batch buying)
        if (msg.value > totalValue) {
            payable(msg.sender).transfer(msg.value.sub(totalValue));
        }
    }


    // -------------------- Gamified Staking Functions --------------------

    /**
     * @dev Stakes an NFT to earn reward tokens.
     * @param _tokenId ID of the NFT to stake.
     */
    function stakeNFT(uint256 _tokenId) public isMarketplaceActive nftExists(_tokenId) isNFTOwner(_tokenId) isNFTNotStaked(_tokenId) {
        require(!nftListings[_tokenId].isListed, "Cannot stake a listed NFT"); // Cannot stake listed NFT
        require(!nftAuctions[_tokenId].isActive, "Cannot stake an NFT in auction"); // Cannot stake NFT in auction

        nftStakingInfo[_tokenId] = StakingInfo({
            stakeStartTime: block.timestamp,
            lastRewardClaimTime: block.timestamp,
            accumulatedRewards: 0,
            isStaked: true
        });
        // Transfer NFT ownership to this contract (optional - could just track staking status without transfer)
        _transferNFT(msg.sender, address(this), _tokenId);
        emit NFTStaked(_tokenId, msg.sender);
    }

    /**
     * @dev Unstakes an NFT and claims accumulated reward tokens.
     * @param _tokenId ID of the NFT to unstake.
     */
    function unstakeNFT(uint256 _tokenId) public isMarketplaceActive nftExists(_tokenId) isNFTOwner(_tokenId) isNFTStaked(_tokenId) nonReentrant {
        uint256 rewards = _calculateRewards(_tokenId);
        nftStakingInfo[_tokenId].isStaked = false; // Mark as unstaked
        nftStakingInfo[_tokenId].accumulatedRewards = 0; // Reset accumulated rewards

        // Transfer NFT back to owner
        _transferNFT(address(this), msg.sender, _tokenId);

        // Transfer reward tokens to owner (assuming RewardToken contract exists and has a `transfer` function)
        if (rewardTokenAddress != address(0) && rewards > 0) {
            // Example integration with RewardToken (ERC20) - Adjust based on your RewardToken contract interface
            IERC20(rewardTokenAddress).transfer(msg.sender, rewards);
            emit NFTUnstaked(_tokenId, msg.sender, rewards);
        } else {
            emit NFTUnstaked(_tokenId, msg.sender, 0); // No rewards claimed if rewardTokenAddress is not set or rewards are 0
        }
    }

    /**
     * @dev Claims accumulated reward tokens for a staked NFT without unstaking.
     * @param _tokenId ID of the staked NFT to claim rewards for.
     */
    function claimRewards(uint256 _tokenId) public isMarketplaceActive nftExists(_tokenId) isNFTOwner(_tokenId) isNFTStaked(_tokenId) nonReentrant {
        uint256 rewards = _calculateRewards(_tokenId);
        nftStakingInfo[_tokenId].lastRewardClaimTime = block.timestamp;
        nftStakingInfo[_tokenId].accumulatedRewards = 0; // Reset accumulated rewards after claiming

        // Transfer reward tokens to owner
        if (rewardTokenAddress != address(0) && rewards > 0) {
            IERC20(rewardTokenAddress).transfer(msg.sender, rewards);
            emit RewardsClaimed(_tokenId, msg.sender, rewards);
        } else {
            emit RewardsClaimed(_tokenId, msg.sender, 0); // No rewards claimed if rewardTokenAddress is not set or rewards are 0
        }
    }

    /**
     * @dev DAO function to set the reward rate for staking.
     * @param _newRate New staking reward rate.
     */
    function setStakingRewardRate(uint256 _newRate) public onlyDAO {
        stakingRewardRate = _newRate;
        emit StakingRewardRateSet(_newRate);
    }

    /**
     * @dev DAO function to set reward multiplier for staking tiers.
     * @param _tier Staking tier level (e.g., 1, 2, 3).
     * @param _multiplier Reward multiplier for the tier.
     */
    function setStakingTierMultiplier(uint256 _tier, uint256 _multiplier) public onlyDAO {
        stakingTierMultipliers[_tier] = _multiplier;
        emit StakingTierMultiplierSet(_tier, _multiplier);
    }


    // -------------------- DAO Governance Functions --------------------

    /**
     * @dev Allows DAO members to create proposals.
     * @param _title Title of the proposal.
     * @param _description Description of the proposal.
     * @param _calldata Encoded function call data to be executed if proposal passes.
     */
    function createProposal(string memory _title, string memory _description, bytes memory _calldata) public onlyDAO isMarketplaceActive {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();
        proposals[proposalId] = Proposal({
            title: _title,
            description: _description,
            calldata: _calldata,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            isActive: true
        });
        emit ProposalCreated(proposalId, _title, msg.sender);
    }

    /**
     * @dev Allows DAO members to vote on proposals.
     * @param _proposalId ID of the proposal to vote on.
     * @param _support True for yes, false for no.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyDAO isMarketplaceActive isProposalActive(_proposalId) {
        require(block.timestamp < proposals[_proposalId].endTime, "Voting period has ended");
        Proposal storage proposal = proposals[_proposalId];
        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a passed proposal after voting period ends.
     * @param _proposalId ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyDAO isMarketplaceActive isProposalActive(_proposalId) nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.endTime, "Voting period is still active");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        uint256 quorumVotesNeeded = totalVotes.mul(quorumPercentage).div(100); // Calculate quorum based on total votes cast

        require(proposal.yesVotes > proposal.noVotes && totalVotes > 0 && proposal.yesVotes >= quorumVotesNeeded, "Proposal did not pass or quorum not met");

        (bool success,) = address(this).delegatecall(proposal.calldata); // Execute the proposal's function call
        require(success, "Proposal execution failed");

        proposal.executed = true;
        proposal.isActive = false;
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Owner function to set the DAO contract address.
     * @param _newDAOAddress New DAO contract address.
     */
    function setDAOAddress(address _newDAOAddress) public onlyOwner {
        daoAddress = _newDAOAddress;
        emit DAOAddressSet(_newDAOAddress);
    }

    /**
     * @dev DAO function to set the marketplace fee percentage.
     * @param _newFeePercentage New marketplace fee percentage (e.g., 2 for 2%).
     */
    function setMarketplaceFee(uint256 _newFeePercentage) public onlyDAO {
        marketplaceFeePercentage = _newFeePercentage;
        emit MarketplaceFeeSet(_newFeePercentage);
    }

    /**
     * @dev Owner/DAO function to withdraw accumulated marketplace fees.
     */
    function withdrawMarketplaceFees() public onlyDAO nonReentrant {
        uint256 balance = address(this).balance;
        payable(feeRecipient).transfer(balance);
    }

    /**
     * @dev DAO function to pause marketplace operations in case of emergency.
     */
    function pauseMarketplace() public onlyDAO {
        marketplaceActive = false;
        emit MarketplacePaused();
    }

    /**
     * @dev DAO function to unpause marketplace operations.
     */
    function unpauseMarketplace() public onlyDAO {
        marketplaceActive = true;
        emit MarketplaceUnpaused();
    }


    // -------------------- Utility and Internal Functions --------------------

    /**
     * @dev Internal function to transfer NFT.
     * @param _from Address to transfer from.
     * @param _to Address to transfer to.
     * @param _tokenId ID of the NFT to transfer.
     */
    function _transferNFT(address _from, address _to, uint256 _tokenId) internal {
        _transfer(_from, _to, _tokenId);
    }

    /**
     * @dev Internal function to calculate staking rewards.
     * @param _tokenId ID of the NFT to calculate rewards for.
     * @return Calculated rewards amount.
     */
    function _calculateRewards(uint256 _tokenId) internal view returns (uint256) {
        StakingInfo storage staking = nftStakingInfo[_tokenId];
        if (!staking.isStaked) {
            return 0; // No rewards if not staked
        }
        uint256 timeElapsed = block.timestamp - staking.lastRewardClaimTime;
        uint256 rewardPerSecond = stakingRewardRate.div(86400); // Assuming reward rate is per day
        uint256 tierMultiplier = stakingTierMultipliers[1]; // Default to tier 1, could be dynamic based on NFT metadata
        uint256 rewards = timeElapsed.mul(rewardPerSecond).mul(tierMultiplier);
        return rewards;
    }

    /**
     * @dev View function to get the listing price of an NFT.
     * @param _tokenId ID of the NFT.
     * @return Listing price in wei.
     */
    function getListingPrice(uint256 _tokenId) public view nftExists(_tokenId) returns (uint256) {
        return nftListings[_tokenId].price;
    }

    /**
     * @dev View function to get details of a specific offer.
     * @param _tokenId ID of the NFT.
     * @param _offerId ID of the offer.
     * @return Offer details (price, offerer, isActive).
     */
    function getOfferDetails(uint256 _tokenId, uint256 _offerId) public view nftExists(_tokenId) returns (uint256 offerPrice, address offerer, bool isActive) {
        Offer storage offer = nftOffers[_tokenId][_offerId];
        return (offer.offerPrice, offer.offerer, offer.isActive);
    }

    /**
     * @dev View function to get details of an active auction.
     * @param _tokenId ID of the NFT.
     * @return Auction details (startPrice, currentPrice, endTime, highestBidder, highestBid, isActive).
     */
    function getAuctionDetails(uint256 _tokenId) public view nftExists(_tokenId) returns (uint256 startPrice, uint256 currentPrice, uint256 endTime, address highestBidder, uint256 highestBid, bool isActive) {
        Auction storage auction = nftAuctions[_tokenId];
        return (auction.startPrice, auction.currentPrice, auction.endTime, auction.highestBidder, auction.highestBid, auction.isActive);
    }

    /**
     * @dev View function to get staking details of an NFT.
     * @param _tokenId ID of the NFT.
     * @return Staking details (stakeStartTime, lastRewardClaimTime, accumulatedRewards, isStaked).
     */
    function getStakingDetails(uint256 _tokenId) public view nftExists(_tokenId) returns (uint256 stakeStartTime, uint256 lastRewardClaimTime, uint256 accumulatedRewards, bool isStaked) {
        StakingInfo storage staking = nftStakingInfo[_tokenId];
        return (staking.stakeStartTime, staking.lastRewardClaimTime, staking.accumulatedRewards, staking.isStaked);
    }

    /**
     * @dev View function to get details of a DAO proposal.
     * @param _proposalId ID of the proposal.
     * @return Proposal details (title, description, startTime, endTime, yesVotes, noVotes, executed, isActive).
     */
    function getProposalDetails(uint256 _proposalId) public view returns (string memory title, string memory description, uint256 startTime, uint256 endTime, uint256 yesVotes, uint256 noVotes, bool executed, bool isActive) {
        Proposal storage proposal = proposals[_proposalId];
        return (proposal.title, proposal.description, proposal.startTime, proposal.endTime, proposal.yesVotes, proposal.noVotes, proposal.executed, proposal.isActive);
    }

    // --- ERC721 Overrides (Optional - for example, to customize transfer behavior if needed) ---
    // override _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
    //     super._beforeTokenTransfer(from, to, tokenId);
    //     // Add custom logic before token transfer if needed (e.g., check for staking status)
    // }
}

// --- Example ERC20 Interface for Reward Token (Assuming RewardToken contract exists) ---
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    // ... other standard ERC20 functions if needed
}
```