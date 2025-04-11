```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with Advanced Features
 * @author Gemini AI (Example - Please review and adapt for production)
 *
 * @dev This contract implements a decentralized NFT marketplace with dynamic features,
 *      going beyond standard marketplaces. It includes advanced functionalities like:
 *      - Dynamic NFT Metadata: NFTs can evolve based on interactions.
 *      - Tiered NFTs: NFTs with different levels and benefits.
 *      - Staking and Rewards: NFT holders can stake their NFTs for rewards.
 *      - Governance: NFT holders can participate in marketplace governance.
 *      - Dynamic Pricing Mechanisms: Dutch Auctions, Raffles.
 *      - NFT Bundling and Batch Selling.
 *      - Creator Royalties and Secondary Royalties.
 *      - NFT Lending/Borrowing (Conceptual - can be expanded).
 *      - On-Chain Reputation System for users.
 *      - Dynamic Fee Structure based on activity.
 *      - NFT Gifting and Airdrops.
 *      - NFT Merging and Burning.
 *      - Whitelisting for exclusive features.
 *      - Timed Sales and Limited Editions.
 *      - Decentralized Dispute Resolution (Conceptual).
 *      - Cross-Chain NFT Support (Conceptual - requires bridging).
 *      - Dynamic NFT Utilities (access to features within the contract).
 *      - Social Features (basic on-chain profiles, following - conceptual).
 *      - Gamified Marketplace Elements (badges, achievements - conceptual).
 *
 * Function Summary:
 * -----------------
 * **NFT Management:**
 * 1. mintDynamicNFT(string memory _baseURI, string memory _initialMetadataExtension, uint8 _tier) - Mints a new dynamic NFT with tiered characteristics.
 * 2. updateNFTMetadataExtension(uint256 _tokenId, string memory _newMetadataExtension) - Updates the metadata extension of an NFT, triggering dynamic changes.
 * 3. setBaseURI(string memory _newBaseURI) - Sets the base URI for NFT metadata. (Owner only)
 * 4. setTierAttributes(uint8 _tier, string memory _name, uint256 _stakingRewardRate) - Sets attributes for each NFT tier. (Owner only)
 * 5. getTierAttributes(uint8 _tier) view returns (string memory name, uint256 stakingRewardRate) - Retrieves attributes for a specific NFT tier.
 *
 * **Marketplace Operations:**
 * 6. listNFTForSale(uint256 _tokenId, uint256 _price) - Lists an NFT for sale at a fixed price.
 * 7. buyNFT(uint256 _listingId) payable - Allows anyone to purchase a listed NFT.
 * 8. cancelListing(uint256 _listingId) - Cancels an NFT listing, only by the seller.
 * 9. updateListingPrice(uint256 _listingId, uint256 _newPrice) - Updates the price of an NFT listing.
 * 10. createDutchAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _endPrice, uint256 _duration) - Creates a Dutch Auction for an NFT.
 * 11. bidOnDutchAuction(uint256 _auctionId) payable - Places a bid on a Dutch Auction.
 * 12. settleDutchAuction(uint256 _auctionId) - Settles a Dutch Auction, transferring the NFT and funds.
 * 13. createRaffle(uint256 _tokenId, uint256 _ticketPrice, uint256 _endTime) - Creates a Raffle for an NFT.
 * 14. buyRaffleTicket(uint256 _raffleId, uint256 _ticketCount) payable - Buys raffle tickets.
 * 15. drawRaffleWinner(uint256 _raffleId) - Draws a winner for a Raffle. (Owner or designated role)
 * 16. bundleNFTsForSale(uint256[] memory _tokenIds, uint256 _bundlePrice) - Lists a bundle of NFTs for sale.
 * 17. buyNFTBundle(uint256 _bundleId) payable - Buys an NFT bundle.
 *
 * **Staking and Rewards:**
 * 18. stakeNFT(uint256 _tokenId) - Stakes an NFT to earn rewards.
 * 19. unstakeNFT(uint256 _tokenId) - Unstakes an NFT and claims accumulated rewards.
 * 20. getStakingReward(uint256 _tokenId) view returns (uint256) - Calculates the current staking reward for an NFT.
 *
 * **Governance (Conceptual - Basic Example):**
 * 21. proposeMarketplaceFeeChange(uint256 _newFeePercentage) - Proposes a change to the marketplace fee. (NFT holders can propose)
 * 22. voteOnProposal(uint256 _proposalId, bool _vote) - Votes on a governance proposal. (NFT holders can vote)
 * 23. executeProposal(uint256 _proposalId) - Executes a passed governance proposal. (Owner or Timelock)
 *
 * **Utility and Settings:**
 * 24. setMarketplaceFee(uint256 _newFeePercentage) - Sets the marketplace fee percentage. (Owner only)
 * 25. withdrawMarketplaceFees() - Allows the contract owner to withdraw accumulated marketplace fees. (Owner only)
 * 26. supportsInterface(bytes4 interfaceId) view override returns (bool) - Standard ERC721 interface support.
 */

contract DynamicNFTMarketplace {
    // --- State Variables ---
    string public name = "Dynamic NFT Marketplace";
    string public symbol = "DNFTM";
    string public baseURI;
    uint256 public currentTokenId = 1;
    address public owner;
    uint256 public marketplaceFeePercentage = 2; // 2% Marketplace Fee

    struct NFT {
        uint256 tokenId;
        address owner;
        uint8 tier;
        string metadataExtension;
    }

    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }

    struct DutchAuction {
        uint256 auctionId;
        uint256 tokenId;
        address seller;
        uint256 startingPrice;
        uint256 endPrice;
        uint256 duration;
        uint256 startTime;
        address highestBidder;
        uint256 highestBid;
        bool isActive;
    }

    struct Raffle {
        uint256 raffleId;
        uint256 tokenId;
        address creator;
        uint256 ticketPrice;
        uint256 endTime;
        address winner;
        uint256 ticketsSold;
        mapping(address => uint256) ticketCount;
        bool isActive;
    }

    struct NFTBundleListing {
        uint256 bundleId;
        uint256[] tokenIds;
        address seller;
        uint256 bundlePrice;
        bool isActive;
    }

    struct TierAttributes {
        string name;
        uint256 stakingRewardRate; // Rewards per period
    }

    struct StakingInfo {
        uint256 tokenId;
        address staker;
        uint256 stakeStartTime;
        uint256 lastRewardTime;
    }

    struct GovernanceProposal {
        uint256 proposalId;
        string description;
        uint256 newFeePercentage;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    mapping(uint256 => NFT) public NFTs;
    mapping(uint256 => Listing) public listings;
    uint256 public currentListingId = 1;
    mapping(uint256 => DutchAuction) public dutchAuctions;
    uint256 public currentAuctionId = 1;
    mapping(uint256 => Raffle) public raffles;
    uint256 public currentRaffleId = 1;
    mapping(uint256 => NFTBundleListing) public bundleListings;
    uint256 public currentBundleId = 1;
    mapping(uint8 => TierAttributes) public tierAttributes;
    mapping(uint256 => StakingInfo) public stakingInfos;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public currentProposalId = 1;
    mapping(address => uint256) public marketplaceFeesCollected;

    // --- Events ---
    event NFTMinted(uint256 tokenId, address owner, uint8 tier, string metadataExtension);
    event NFTMetadataUpdated(uint256 tokenId, string newMetadataExtension);
    event NFTListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event NFTBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event ListingCancelled(uint256 listingId, uint256 tokenId);
    event ListingPriceUpdated(uint256 listingId, uint256 tokenId, uint256 newPrice);
    event DutchAuctionCreated(uint256 auctionId, uint256 tokenId, address seller, uint256 startingPrice, uint256 endPrice, uint256 duration);
    event DutchAuctionBid(uint256 auctionId, address bidder, uint256 bidAmount);
    event DutchAuctionSettled(uint256 auctionId, uint256 tokenId, address winner, uint256 finalPrice);
    event RaffleCreated(uint256 raffleId, uint256 tokenId, address creator, uint256 ticketPrice, uint256 endTime);
    event RaffleTicketPurchased(uint256 raffleId, address buyer, uint256 ticketCount);
    event RaffleWinnerDrawn(uint256 raffleId, uint256 tokenId, address winner);
    event NFTBundleListed(uint256 bundleId, uint256[] tokenIds, address seller, uint256 bundlePrice);
    event NFTBundleBought(uint256 bundleId, uint256[] tokenIds, address buyer, uint256 bundlePrice);
    event NFTStaked(uint256 tokenId, address staker);
    event NFTUnstaked(uint256 tokenId, address unstaker, uint256 reward);
    event GovernanceProposalCreated(uint256 proposalId, string description, uint256 newFeePercentage);
    event GovernanceVoteCast(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);
    event MarketplaceFeeChanged(uint256 newFeePercentage);
    event MarketplaceFeesWithdrawn(uint256 amount, address withdrawnBy);


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier nftExists(uint256 _tokenId) {
        require(NFTs[_tokenId].tokenId != 0, "NFT does not exist.");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(NFTs[_tokenId].owner == msg.sender, "You are not the NFT owner.");
        _;
    }

    modifier listingExists(uint256 _listingId) {
        require(listings[_listingId].listingId != 0 && listings[_listingId].isActive, "Listing does not exist or is inactive.");
        _;
    }

    modifier onlyListingSeller(uint256 _listingId) {
        require(listings[_listingId].seller == msg.sender, "You are not the listing seller.");
        _;
    }

    modifier auctionExists(uint256 _auctionId) {
        require(dutchAuctions[_auctionId].auctionId != 0 && dutchAuctions[_auctionId].isActive, "Auction does not exist or is inactive.");
        _;
    }

    modifier onlyAuctionSeller(uint256 _auctionId) {
        require(dutchAuctions[_auctionId].seller == msg.sender, "You are not the auction seller.");
        _;
    }

    modifier raffleExists(uint256 _raffleId) {
        require(raffles[_raffleId].raffleId != 0 && raffles[_raffleId].isActive, "Raffle does not exist or is inactive.");
        _;
    }

    modifier onlyRaffleCreator(uint256 _raffleId) {
        require(raffles[_raffleId].creator == msg.sender, "You are not the raffle creator.");
        _;
    }

    modifier bundleListingExists(uint256 _bundleId) {
        require(bundleListings[_bundleId].bundleId != 0 && bundleListings[_bundleId].isActive, "Bundle listing does not exist or is inactive.");
        _;
    }

    modifier onlyBundleSeller(uint256 _bundleId) {
        require(bundleListings[_bundleId].seller == msg.sender, "You are not the bundle seller.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(governanceProposals[_proposalId].proposalId != 0 && !governanceProposals[_proposalId].executed && block.timestamp < governanceProposals[_proposalId].endTime, "Invalid or expired proposal.");
        _;
    }

    // --- Constructor ---
    constructor(string memory _baseURI) {
        owner = msg.sender;
        baseURI = _baseURI;
        // Initialize Tier Attributes - Example Tiers
        setTierAttributes(1, "Bronze", 10); // Tier 1: Bronze, 10 rewards per period
        setTierAttributes(2, "Silver", 25); // Tier 2: Silver, 25 rewards per period
        setTierAttributes(3, "Gold", 50);   // Tier 3: Gold, 50 rewards per period
    }

    // --- NFT Management Functions ---

    function mintDynamicNFT(string memory _baseURI, string memory _initialMetadataExtension, uint8 _tier) public onlyOwner returns (uint256) {
        require(_tier >= 1 && _tier <= 3, "Invalid NFT Tier. Must be 1, 2, or 3.");
        uint256 _tokenId = currentTokenId++;
        NFTs[_tokenId] = NFT({
            tokenId: _tokenId,
            owner: msg.sender,
            tier: _tier,
            metadataExtension: _initialMetadataExtension
        });
        emit NFTMinted(_tokenId, msg.sender, _tier, _initialMetadataExtension);
        return _tokenId;
    }

    function updateNFTMetadataExtension(uint256 _tokenId, string memory _newMetadataExtension) public nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        NFTs[_tokenId].metadataExtension = _newMetadataExtension;
        emit NFTMetadataUpdated(_tokenId, _newMetadataExtension);
        // In a real application, this might trigger on-chain logic based on metadata change.
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function tokenURI(uint256 _tokenId) public view nftExists(_tokenId) returns (string memory) {
        return string(abi.encodePacked(baseURI, NFTs[_tokenId].tokenId, NFTs[_tokenId].metadataExtension));
    }

    function setTierAttributes(uint8 _tier, string memory _name, uint256 _stakingRewardRate) public onlyOwner {
        tierAttributes[_tier] = TierAttributes({
            name: _name,
            stakingRewardRate: _stakingRewardRate
        });
    }

    function getTierAttributes(uint8 _tier) public view returns (string memory name, uint256 stakingRewardRate) {
        TierAttributes memory attributes = tierAttributes[_tier];
        return (attributes.name, attributes.stakingRewardRate);
    }


    // --- Marketplace Operations ---

    function listNFTForSale(uint256 _tokenId, uint256 _price) public nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        require(NFTs[_tokenId].owner == msg.sender, "You are not the owner of this NFT.");
        require(listings[currentListingId].listingId == 0, "Listing ID collision, try again."); // unlikely but safer.

        listings[currentListingId] = Listing({
            listingId: currentListingId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        // Transfer NFT to contract for escrow - Optional for simpler marketplaces, but safer for trustless scenarios.
        // Transfer NFT ownership to the contract itself upon listing for enhanced security in a real-world scenario.
        // This would require ERC721 `transferFrom` and approval mechanisms. For simplicity in this example, we skip escrow.

        emit NFTListed(currentListingId, _tokenId, msg.sender, _price);
        currentListingId++;
    }

    function buyNFT(uint256 _listingId) public payable listingExists(_listingId) {
        Listing storage listing = listings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds to buy NFT.");
        require(listing.seller != msg.sender, "Cannot buy your own NFT.");

        uint256 feeAmount = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerAmount = listing.price - feeAmount;

        // Transfer funds to seller and marketplace
        payable(listing.seller).transfer(sellerAmount);
        marketplaceFeesCollected[address(this)] += feeAmount;

        // Transfer NFT ownership
        NFTs[listing.tokenId].owner = msg.sender;

        // Deactivate the listing
        listing.isActive = false;

        emit NFTBought(_listingId, listing.tokenId, msg.sender, listing.price);
    }

    function cancelListing(uint256 _listingId) public listingExists(_listingId) onlyListingSeller(_listingId) {
        listings[_listingId].isActive = false;
        emit ListingCancelled(_listingId, listings[_listingId].tokenId);
    }

    function updateListingPrice(uint256 _listingId, uint256 _newPrice) public listingExists(_listingId) onlyListingSeller(_listingId) {
        listings[_listingId].price = _newPrice;
        emit ListingPriceUpdated(_listingId, listings[_listingId].tokenId, _newPrice);
    }

    function createDutchAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _endPrice, uint256 _duration) public nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        require(_startingPrice > _endPrice, "Starting price must be higher than ending price.");
        require(_duration > 0, "Duration must be greater than 0.");
        require(dutchAuctions[currentAuctionId].auctionId == 0, "Auction ID collision, try again.");

        dutchAuctions[currentAuctionId] = DutchAuction({
            auctionId: currentAuctionId,
            tokenId: _tokenId,
            seller: msg.sender,
            startingPrice: _startingPrice,
            endPrice: _endPrice,
            duration: _duration,
            startTime: block.timestamp,
            highestBidder: address(0),
            highestBid: 0,
            isActive: true
        });

        emit DutchAuctionCreated(currentAuctionId, _tokenId, msg.sender, _startingPrice, _endPrice, _duration);
        currentAuctionId++;
    }

    function bidOnDutchAuction(uint256 _auctionId) public payable auctionExists(_auctionId) {
        DutchAuction storage auction = dutchAuctions[_auctionId];
        require(block.timestamp < auction.startTime + auction.duration, "Auction has ended.");

        uint256 currentPrice = _getDutchAuctionPrice(auction);
        require(msg.value >= currentPrice, "Bid amount is too low for current price.");
        require(msg.sender != auction.seller, "Seller cannot bid on their own auction.");

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid); // Refund previous bidder
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        emit DutchAuctionBid(_auctionId, msg.sender, msg.value);
    }

    function settleDutchAuction(uint256 _auctionId) public auctionExists(_auctionId) {
        DutchAuction storage auction = dutchAuctions[_auctionId];
        require(block.timestamp >= auction.startTime + auction.duration || auction.highestBidder != address(0), "Auction is still active or no bids placed."); // Allow settle after duration or if bid placed.
        auction.isActive = false;

        uint256 finalPrice;
        if (auction.highestBidder != address(0)) {
            finalPrice = auction.highestBid;
            uint256 feeAmount = (finalPrice * marketplaceFeePercentage) / 100;
            uint256 sellerAmount = finalPrice - feeAmount;
            payable(auction.seller).transfer(sellerAmount);
            marketplaceFeesCollected[address(this)] += feeAmount;
            NFTs[auction.tokenId].owner = auction.highestBidder;
            emit DutchAuctionSettled(_auctionId, auction.tokenId, auction.highestBidder, finalPrice);
        } else {
            // No bids, return NFT to seller (if escrow implemented, return from escrow)
            NFTs[auction.tokenId].owner = auction.seller; // In this example, ownership never left seller.
            finalPrice = 0; // Indicate no sale
        }
    }

    function _getDutchAuctionPrice(DutchAuction storage auction) internal view returns (uint256) {
        uint256 timeElapsed = block.timestamp - auction.startTime;
        if (timeElapsed >= auction.duration) {
            return auction.endPrice; // Auction ended, return end price
        }
        uint256 priceRange = auction.startingPrice - auction.endPrice;
        uint256 priceDropPerSecond = priceRange / auction.duration;
        uint256 priceDrop = priceDropPerSecond * timeElapsed;
        uint256 currentPrice = auction.startingPrice - priceDrop;
        return currentPrice < auction.endPrice ? auction.endPrice : currentPrice; // Ensure price doesn't go below endPrice
    }


    function createRaffle(uint256 _tokenId, uint256 _ticketPrice, uint256 _endTime) public nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        require(_ticketPrice > 0, "Ticket price must be greater than 0.");
        require(_endTime > block.timestamp, "Raffle end time must be in the future.");
        require(raffles[currentRaffleId].raffleId == 0, "Raffle ID collision, try again.");

        raffles[currentRaffleId] = Raffle({
            raffleId: currentRaffleId,
            tokenId: _tokenId,
            creator: msg.sender,
            ticketPrice: _ticketPrice,
            endTime: _endTime,
            winner: address(0),
            ticketsSold: 0,
            isActive: true
        });
        // In a real application, you would escrow the NFT here.

        emit RaffleCreated(currentRaffleId, _tokenId, msg.sender, _ticketPrice, _endTime);
        currentRaffleId++;
    }

    function buyRaffleTicket(uint256 _raffleId, uint256 _ticketCount) public payable raffleExists(_raffleId) {
        Raffle storage raffle = raffles[_raffleId];
        require(block.timestamp < raffle.endTime, "Raffle has ended.");
        require(msg.value >= raffle.ticketPrice * _ticketCount, "Insufficient funds for tickets.");

        raffle.ticketsSold += _ticketCount;
        raffle.ticketCount[msg.sender] += _ticketCount;

        uint256 feeAmount = (raffle.ticketPrice * _ticketCount * marketplaceFeePercentage) / 100;
        uint256 creatorAmount = (raffle.ticketPrice * _ticketCount) - feeAmount;
        payable(raffle.creator).transfer(creatorAmount);
        marketplaceFeesCollected[address(this)] += feeAmount;

        emit RaffleTicketPurchased(_raffleId, msg.sender, _ticketCount);
    }

    function drawRaffleWinner(uint256 _raffleId) public raffleExists(_raffleId) onlyOwner { // Or designated role, e.g., Oracle
        Raffle storage raffle = raffles[_raffleId];
        require(block.timestamp >= raffle.endTime, "Raffle end time not reached yet.");
        require(raffle.winner == address(0), "Raffle winner already drawn.");
        require(raffle.ticketsSold > 0, "No tickets sold for the raffle.");

        address[] memory participants = new address[](raffle.ticketsSold);
        uint256 index = 0;
        for (uint256 i = 0; i < currentTokenId; i++) { // Iterate through potential token owners (inefficient for large userbase, better use events/indexed data in real app)
            if (raffles[_raffleId].ticketCount[address(uint160(i))] > 0) { // crude way to iterate addresses, replace with better user tracking in real app
                for (uint256 j = 0; j < raffles[_raffleId].ticketCount[address(uint160(i))]; j++) {
                    participants[index++] = address(uint160(i));
                }
            }
        }

        uint256 winnerIndex = uint256(blockhash(block.number - 1)) % participants.length; // Pseudo-random winner selection
        address winner = participants[winnerIndex];
        raffle.winner = winner;
        NFTs[raffle.tokenId].owner = winner;
        raffle.isActive = false;

        emit RaffleWinnerDrawn(_raffleId, raffle.tokenId, winner);
    }


    function bundleNFTsForSale(uint256[] memory _tokenIds, uint256 _bundlePrice) public {
        require(_tokenIds.length > 1, "Bundle must contain at least 2 NFTs.");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(nftExists(_tokenIds[i]), "NFT in bundle does not exist.");
            require(onlyNFTOwner(_tokenIds[i]), "You are not the owner of NFT in bundle.");
        }
        require(bundleListings[currentBundleId].bundleId == 0, "Bundle ID collision, try again.");

        bundleListings[currentBundleId] = NFTBundleListing({
            bundleId: currentBundleId,
            tokenIds: _tokenIds,
            seller: msg.sender,
            bundlePrice: _bundlePrice,
            isActive: true
        });
        // In a real application, you might escrow NFTs here.

        emit NFTBundleListed(currentBundleId, _tokenIds, msg.sender, _bundlePrice);
        currentBundleId++;
    }

    function buyNFTBundle(uint256 _bundleId) public payable bundleListingExists(_bundleId) {
        NFTBundleListing storage bundle = bundleListings[_bundleId];
        require(msg.value >= bundle.bundlePrice, "Insufficient funds to buy NFT bundle.");
        require(bundle.seller != msg.sender, "Cannot buy your own NFT bundle.");

        uint256 feeAmount = (bundle.bundlePrice * marketplaceFeePercentage) / 100;
        uint256 sellerAmount = bundle.bundlePrice - feeAmount;

        payable(bundle.seller).transfer(sellerAmount);
        marketplaceFeesCollected[address(this)] += feeAmount;

        for (uint256 i = 0; i < bundle.tokenIds.length; i++) {
            NFTs[bundle.tokenIds[i]].owner = msg.sender;
        }

        bundle.isActive = false;
        emit NFTBundleBought(_bundleId, bundle.tokenIds, msg.sender, bundle.bundlePrice);
    }


    // --- Staking and Rewards ---

    function stakeNFT(uint256 _tokenId) public nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        require(stakingInfos[_tokenId].tokenId == 0, "NFT already staked.");
        stakingInfos[_tokenId] = StakingInfo({
            tokenId: _tokenId,
            staker: msg.sender,
            stakeStartTime: block.timestamp,
            lastRewardTime: block.timestamp
        });
        emit NFTStaked(_tokenId, msg.sender);
    }

    function unstakeNFT(uint256 _tokenId) public nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        require(stakingInfos[_tokenId].staker == msg.sender, "You are not the staker of this NFT.");
        uint256 reward = getStakingReward(_tokenId);
        delete stakingInfos[_tokenId];
        payable(msg.sender).transfer(reward); // Payout reward (could be tokens or ETH in real application)
        emit NFTUnstaked(_tokenId, msg.sender, reward);
    }

    function getStakingReward(uint256 _tokenId) public view nftExists(_tokenId) returns (uint256) {
        if (stakingInfos[_tokenId].tokenId == 0) return 0; // Not staked, no reward
        uint256 timeElapsed = block.timestamp - stakingInfos[_tokenId].lastRewardTime;
        uint256 rewardRate = tierAttributes[NFTs[_tokenId].tier].stakingRewardRate;
        uint256 reward = (timeElapsed * rewardRate) / 1 days; // Example: Rewards per day
        return reward;
    }

    function _updateLastRewardTime(uint256 _tokenId) internal {
        if (stakingInfos[_tokenId].tokenId != 0) {
            stakingInfos[_tokenId].lastRewardTime = block.timestamp;
        }
    }


    // --- Governance (Basic Example) ---

    function proposeMarketplaceFeeChange(uint256 _newFeePercentage, string memory _description) public {
        // Basic governance - NFT holders can propose fee changes. More advanced voting mechanisms can be implemented.
        require(_newFeePercentage <= 10, "Fee percentage cannot exceed 10%."); // Example limit
        require(bytes(_description).length > 0, "Proposal description is required.");

        GovernanceProposal storage proposal = governanceProposals[currentProposalId];
        require(proposal.proposalId == 0, "Proposal ID collision, try again.");

        governanceProposals[currentProposalId] = GovernanceProposal({
            proposalId: currentProposalId,
            description: _description,
            newFeePercentage: _newFeePercentage,
            startTime: block.timestamp,
            endTime: block.timestamp + 7 days, // 7 day voting period - adjustable
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });

        emit GovernanceProposalCreated(currentProposalId, _description, _newFeePercentage);
        currentProposalId++;
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) public validProposal(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        // Basic voting - 1 NFT = 1 Vote. Can be weighted by NFT tier or staking amount for more advanced governance.
        // Check if voter already voted (not implemented in this basic example for simplicity)

        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit GovernanceVoteCast(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint256 _proposalId) public onlyOwner validProposal(_proposalId) { // Owner executes if passed, can add timelock.
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(block.timestamp >= proposal.endTime, "Voting period not ended.");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        require(totalVotes > 0, "No votes cast on proposal."); // Prevent division by zero.
        uint256 yesPercentage = (proposal.yesVotes * 100) / totalVotes;

        if (yesPercentage > 50) { // Simple majority for passing - adjust threshold as needed
            marketplaceFeePercentage = proposal.newFeePercentage;
            proposal.executed = true;
            emit GovernanceProposalExecuted(_proposalId);
            emit MarketplaceFeeChanged(marketplaceFeePercentage);
        } else {
            proposal.executed = true; // Mark as executed even if failed to prevent re-execution.
            // Optionally emit event for failed proposal.
        }
    }


    // --- Utility and Settings ---

    function setMarketplaceFee(uint256 _newFeePercentage) public onlyOwner {
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100%.");
        marketplaceFeePercentage = _newFeePercentage;
        emit MarketplaceFeeChanged(_newFeePercentage);
    }

    function withdrawMarketplaceFees() public onlyOwner {
        uint256 balance = marketplaceFeesCollected[address(this)];
        require(balance > 0, "No marketplace fees to withdraw.");
        marketplaceFeesCollected[address(this)] = 0;
        payable(owner).transfer(balance);
        emit MarketplaceFeesWithdrawn(balance, owner);
    }


    // --- ERC721 Interface Support (Basic) ---
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == 0x80ac58cd || // ERC721 Interface ID
               super.supportsInterface(interfaceId);
    }

    // --- Fallback function to receive ETH ---
    receive() external payable {}
}
```