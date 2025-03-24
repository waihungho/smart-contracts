```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Decentralized Dynamic NFT Marketplace with Gamified Staking and DAO Governance
 * @author Bard (Conceptual Smart Contract - Not for Production)
 * @dev A smart contract implementing a dynamic NFT marketplace with advanced features:
 *      - Dynamic NFTs: NFTs whose traits can evolve based on time and interactions.
 *      - Gamified Staking: Stake NFTs to earn rewards and unlock benefits based on rarity/traits.
 *      - Decentralized Autonomous Organization (DAO) Governance: Community-led decision making on platform parameters.
 *      - Advanced Marketplace Features: Auctions, Bundles, Lending (Conceptual).
 *
 * Function Summary:
 *
 * **NFT Management:**
 * 1. mintDynamicNFT(address _to, string memory _baseURI, uint256[] memory _initialTraits): Mints a new dynamic NFT with initial traits.
 * 2. updateNFTTraits(uint256 _tokenId): Updates the traits of a dynamic NFT based on predefined evolution logic (e.g., time-based, interaction-based).
 * 3. setBaseURI(string memory _baseURI): Sets the base URI for NFT metadata.
 * 4. tokenURI(uint256 tokenId): Returns the URI for a given NFT token.
 * 5. transferNFT(address _to, uint256 _tokenId): Allows owner to transfer NFT (standard ERC721 transfer).
 *
 * **Marketplace Functions:**
 * 6. listItemForSale(uint256 _tokenId, uint256 _price): Lists an NFT for sale on the marketplace.
 * 7. purchaseNFT(uint256 _listingId): Allows anyone to purchase an NFT listed on the marketplace.
 * 8. cancelListing(uint256 _listingId): Allows the seller to cancel a listing.
 * 9. updateListingPrice(uint256 _listingId, uint256 _newPrice): Allows the seller to update the price of a listing.
 * 10. createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration): Creates an auction for an NFT.
 * 11. placeBid(uint256 _auctionId): Allows users to place bids in an auction.
 * 12. settleAuction(uint256 _auctionId): Settles an auction, transferring NFT and funds to winner/seller.
 * 13. createBundleSale(uint256[] memory _tokenIds, uint256 _bundlePrice): Creates a bundle of NFTs for sale at a fixed price.
 * 14. purchaseBundle(uint256 _bundleId): Allows anyone to purchase an NFT bundle.
 * 15. cancelBundleSale(uint256 _bundleId): Allows the seller to cancel a bundle sale.
 *
 * **Gamified Staking and Rewards:**
 * 16. stakeNFT(uint256 _tokenId): Stakes an NFT to participate in the staking program.
 * 17. unstakeNFT(uint256 _tokenId): Unstakes an NFT, allowing withdrawal and reward claiming.
 * 18. calculateStakingRewards(uint256 _tokenId): Calculates the staking rewards for a given NFT based on staking duration and NFT traits (rarity, etc.).
 * 19. claimStakingRewards(uint256 _tokenId): Allows users to claim accumulated staking rewards.
 * 20. setRewardToken(address _rewardTokenAddress): Sets the reward token for staking. (Admin Function)
 * 21. setRewardRate(uint256 _newRewardRate): Sets the reward rate for staking. (Admin Function - DAO Governed later)
 * 22. setStakingBoostTraits(uint256[] memory _traitIndices, uint256[] memory _boostMultipliers): Configures traits that boost staking rewards. (Admin Function - DAO Governed later)
 *
 * **DAO Governance (Conceptual):**
 * 23. proposeParameterChange(string memory _proposalDescription, string memory _parameterName, uint256 _newValue): Allows token holders to propose changes to platform parameters (e.g., reward rate, marketplace fees). (Conceptual - DAO Token & Voting Logic needed)
 * 24. voteOnProposal(uint256 _proposalId, bool _support): Allows token holders to vote on proposals. (Conceptual - DAO Token & Voting Logic needed)
 * 25. executeProposal(uint256 _proposalId): Executes a successful proposal after voting period. (Conceptual - DAO Token & Voting Logic needed)
 *
 * **Admin Functions:**
 * 26. withdrawMarketplaceFees(address _to): Allows the contract owner to withdraw accumulated marketplace fees.
 * 27. pauseContract(): Pauses core marketplace and staking functionalities for emergency situations.
 * 28. unpauseContract(): Resumes contract functionalities after pausing.
 * 29. setMarketplaceFee(uint256 _newFeePercentage): Sets the marketplace fee percentage. (Admin Function - DAO Governed later)
 * 30. withdrawAnyERC20(address _tokenAddress, address _to, uint256 _amount): Emergency function to withdraw mistakenly sent ERC20 tokens.
 */
contract DynamicNFTMarketplace is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _listingIdCounter;
    Counters.Counter private _auctionIdCounter;
    Counters.Counter private _bundleIdCounter;
    Counters.Counter private _proposalIdCounter;

    string private _baseTokenURI;

    // --- Dynamic NFT Features ---
    struct NFT {
        uint256[] traits; // Array to store dynamic traits (e.g., [strength, agility, rarity])
        uint256 lastTraitUpdate; // Timestamp of the last trait update
        bool isStaked;
    }
    mapping(uint256 => NFT) public NFTs;
    uint256 public traitEvolutionInterval = 24 hours; // Time interval for trait evolution

    // --- Marketplace Features ---
    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address payable seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => Listing) public listings;
    uint256 public marketplaceFeePercentage = 2; // 2% marketplace fee

    struct Auction {
        uint256 auctionId;
        uint256 tokenId;
        address payable seller;
        uint256 startingBid;
        uint256 currentBid;
        address payable currentBidder;
        uint256 auctionEndTime;
        bool isActive;
    }
    mapping(uint256 => Auction) public auctions;

    struct BundleSale {
        uint256 bundleId;
        uint256[] tokenIds;
        address payable seller;
        uint256 bundlePrice;
        bool isActive;
    }
    mapping(uint256 => BundleSale) public bundles;

    // --- Staking and Rewards ---
    IERC20 public rewardToken;
    uint256 public rewardRatePerDay = 10; // Reward tokens per day per staked NFT (example)
    mapping(uint256 => uint256) public nftStakeStartTime; // Timestamp when NFT was staked
    mapping(uint256 => uint256) public pendingRewards; // Track pending rewards for each staked NFT
    uint256[] public stakingBoostTraitsIndices; // Indices of traits that boost staking rewards
    uint256[] public stakingBoostMultipliers; // Multipliers for staking boost traits

    // --- DAO Governance (Conceptual - Requires DAO Token & Voting Contract for full implementation) ---
    struct Proposal {
        uint256 proposalId;
        address proposer;
        string description;
        string parameterName;
        uint256 newValue;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votingEndTime;
        bool isExecuted;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public votingDuration = 7 days; // Proposal voting duration

    bool public paused = false;

    event NFTMinted(uint256 tokenId, address to);
    event NFTTraitsUpdated(uint256 tokenId, uint256[] newTraits);
    event NFTListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event NFTPurchased(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event ListingCancelled(uint256 listingId, uint256 tokenId);
    event ListingPriceUpdated(uint256 listingId, uint256 tokenId, uint256 newPrice);
    event AuctionCreated(uint256 auctionId, uint256 tokenId, address seller, uint256 startingBid, uint256 endTime);
    event BidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionSettled(uint256 auctionId, uint256 tokenId, address winner, uint256 finalPrice);
    event BundleSaleCreated(uint256 bundleId, address seller, uint256 bundlePrice, uint256[] tokenIds);
    event BundlePurchased(uint256 bundleId, address buyer, uint256 bundlePrice, uint256[] tokenIds);
    event BundleSaleCancelled(uint256 bundleId);
    event NFTStaked(uint256 tokenId, address staker);
    event NFTUnstaked(uint256 tokenId, uint256 rewardsClaimed);
    event StakingRewardsClaimed(uint256 tokenId, uint256 rewards);
    event RewardRateSet(uint256 newRate);
    event StakingBoostTraitsSet(uint256[] traitIndices, uint256[] multipliers);
    event ProposalCreated(uint256 proposalId, address proposer, string description, string parameterName, uint256 newValue);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event ContractPaused();
    event ContractUnpaused();
    event MarketplaceFeeSet(uint256 newFeePercentage);
    event TokensWithdrawn(address tokenAddress, address to, uint256 amount);


    constructor(string memory _name, string memory _symbol, string memory baseURI) ERC721(_name, _symbol) {
        _baseTokenURI = baseURI;
    }

    // --- NFT Management Functions ---

    function mintDynamicNFT(address _to, string memory _tokenURI, uint256[] memory _initialTraits) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _tokenURI); // Set initial token URI
        NFTs[tokenId] = NFT({
            traits: _initialTraits,
            lastTraitUpdate: block.timestamp,
            isStaked: false
        });
        emit NFTMinted(tokenId, _to);
    }

    function updateNFTTraits(uint256 _tokenId) public {
        require(_exists(_tokenId), "NFT does not exist");
        require(block.timestamp >= NFTs[_tokenId].lastTraitUpdate + traitEvolutionInterval, "Trait evolution interval not reached");

        // Example: Simple trait evolution logic (increase each trait by 1)
        uint256[] memory currentTraits = NFTs[_tokenId].traits;
        for (uint256 i = 0; i < currentTraits.length; i++) {
            currentTraits[i] = currentTraits[i] + 1; // Simple increment
        }
        NFTs[_tokenId].traits = currentTraits;
        NFTs[_tokenId].lastTraitUpdate = block.timestamp;

        // Example: Update token URI to reflect new traits (requires off-chain metadata update service)
        // _setTokenURI(_tokenId, _generateUpdatedTokenURI(_tokenId, currentTraits));

        emit NFTTraitsUpdated(_tokenId, currentTraits);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        _baseTokenURI = _baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function transferNFT(address _to, uint256 _tokenId) public payable {
        require(msg.sender == ownerOf(_tokenId), "Not NFT owner");
        safeTransferFrom(msg.sender, _to, _tokenId);
    }


    // --- Marketplace Functions ---
    modifier whenNotPausedMarketplace() {
        require(!paused, "Marketplace functions are paused");
        _;
    }

    function listItemForSale(uint256 _tokenId, uint256 _price) public whenNotPausedMarketplace {
        require(msg.sender == ownerOf(_tokenId), "Not NFT owner");
        require(!NFTs[_tokenId].isStaked, "NFT is staked and cannot be listed");
        approve(address(this), _tokenId); // Approve contract to transfer NFT
        _listingIdCounter.increment();
        uint256 listingId = _listingIdCounter.current();
        listings[listingId] = Listing({
            listingId: listingId,
            tokenId: _tokenId,
            seller: payable(msg.sender),
            price: _price,
            isActive: true
        });
        emit NFTListed(listingId, _tokenId, msg.sender, _price);
    }

    function purchaseNFT(uint256 _listingId) public payable whenNotPausedMarketplace nonReentrant {
        require(listings[_listingId].isActive, "Listing is not active");
        Listing storage listing = listings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds");

        uint256 feeAmount = listing.price.mul(marketplaceFeePercentage).div(100);
        uint256 sellerAmount = listing.price.sub(feeAmount);

        IERC721(address(this)).safeTransferFrom(listing.seller, msg.sender, listing.tokenId); // Transfer NFT
        payable(listing.seller).transfer(sellerAmount); // Transfer funds to seller
        payable(owner()).transfer(feeAmount); // Transfer marketplace fees to owner

        listings[_listingId].isActive = false; // Deactivate listing

        emit NFTPurchased(_listingId, listing.tokenId, msg.sender, listing.price);
    }

    function cancelListing(uint256 _listingId) public whenNotPausedMarketplace {
        require(listings[_listingId].isActive, "Listing is not active");
        require(listings[_listingId].seller == msg.sender, "Not listing seller");
        listings[_listingId].isActive = false;
        emit ListingCancelled(_listingId, listings[_listingId].tokenId);
    }

    function updateListingPrice(uint256 _listingId, uint256 _newPrice) public whenNotPausedMarketplace {
        require(listings[_listingId].isActive, "Listing is not active");
        require(listings[_listingId].seller == msg.sender, "Not listing seller");
        listings[_listingId].price = _newPrice;
        emit ListingPriceUpdated(_listingId, listings[_listingId].tokenId, _newPrice);
    }

    function createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration) public whenNotPausedMarketplace {
        require(msg.sender == ownerOf(_tokenId), "Not NFT owner");
        require(!NFTs[_tokenId].isStaked, "NFT is staked and cannot be auctioned");
        require(_auctionDuration > 0, "Auction duration must be positive");
        approve(address(this), _tokenId);

        _auctionIdCounter.increment();
        uint256 auctionId = _auctionIdCounter.current();
        auctions[auctionId] = Auction({
            auctionId: auctionId,
            tokenId: _tokenId,
            seller: payable(msg.sender),
            startingBid: _startingBid,
            currentBid: 0,
            currentBidder: payable(address(0)),
            auctionEndTime: block.timestamp + _auctionDuration,
            isActive: true
        });
        emit AuctionCreated(auctionId, _tokenId, msg.sender, _startingBid, block.timestamp + _auctionDuration);
    }

    function placeBid(uint256 _auctionId) public payable whenNotPausedMarketplace nonReentrant {
        require(auctions[_auctionId].isActive, "Auction is not active");
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp < auction.auctionEndTime, "Auction has ended");
        require(msg.value >= auction.startingBid, "Bid too low, must be at least starting bid");
        require(msg.value > auction.currentBid, "Bid too low, must be higher than current bid");

        if (auction.currentBidder != address(0)) {
            payable(auction.currentBidder).transfer(auction.currentBid); // Refund previous bidder
        }

        auction.currentBid = msg.value;
        auction.currentBidder = payable(msg.sender);
        emit BidPlaced(_auctionId, msg.sender, msg.value);
    }

    function settleAuction(uint256 _auctionId) public whenNotPausedMarketplace nonReentrant {
        require(auctions[_auctionId].isActive, "Auction is not active");
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp >= auction.auctionEndTime, "Auction is not yet ended");

        auctions[_auctionId].isActive = false; // Deactivate auction

        if (auction.currentBidder != address(0)) {
            uint256 feeAmount = auction.currentBid.mul(marketplaceFeePercentage).div(100);
            uint256 sellerAmount = auction.currentBid.sub(feeAmount);

            IERC721(address(this)).safeTransferFrom(auction.seller, auction.currentBidder, auction.tokenId); // Transfer NFT
            payable(auction.seller).transfer(sellerAmount); // Transfer funds to seller
            payable(owner()).transfer(feeAmount); // Transfer marketplace fees to owner

            emit AuctionSettled(_auctionId, auction.tokenId, auction.currentBidder, auction.currentBid);
        } else {
            IERC721(address(this)).transferFrom(address(this), auction.seller, auction.tokenId); // Return NFT to seller if no bids
        }
    }

    function createBundleSale(uint256[] memory _tokenIds, uint256 _bundlePrice) public whenNotPausedMarketplace {
        require(_tokenIds.length > 0, "Bundle must contain at least one NFT");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(msg.sender == ownerOf(_tokenIds[i]), "Not NFT owner for all tokens in bundle");
            require(!NFTs[_tokenIds[i]].isStaked, "NFT in bundle is staked and cannot be bundled");
            approve(address(this), _tokenIds[i]); // Approve contract to transfer each NFT
        }

        _bundleIdCounter.increment();
        uint256 bundleId = _bundleIdCounter.current();
        bundles[bundleId] = BundleSale({
            bundleId: bundleId,
            tokenIds: _tokenIds,
            seller: payable(msg.sender),
            bundlePrice: _bundlePrice,
            isActive: true
        });
        emit BundleSaleCreated(bundleId, msg.sender, _bundlePrice, _tokenIds);
    }

    function purchaseBundle(uint256 _bundleId) public payable whenNotPausedMarketplace nonReentrant {
        require(bundles[_bundleId].isActive, "Bundle sale is not active");
        BundleSale storage bundle = bundles[_bundleId];
        require(msg.value >= bundle.bundlePrice, "Insufficient funds for bundle");

        uint256 feeAmount = bundle.bundlePrice.mul(marketplaceFeePercentage).div(100);
        uint256 sellerAmount = bundle.bundlePrice.sub(feeAmount);

        for (uint256 i = 0; i < bundle.tokenIds.length; i++) {
            IERC721(address(this)).safeTransferFrom(bundle.seller, msg.sender, bundle.tokenIds[i]); // Transfer each NFT in bundle
        }
        payable(bundle.seller).transfer(sellerAmount); // Transfer funds to seller
        payable(owner()).transfer(feeAmount); // Transfer marketplace fees to owner

        bundles[_bundleId].isActive = false; // Deactivate bundle sale
        emit BundlePurchased(_bundleId, msg.sender, bundle.bundlePrice, bundle.tokenIds);
    }

    function cancelBundleSale(uint256 _bundleId) public whenNotPausedMarketplace {
        require(bundles[_bundleId].isActive, "Bundle sale is not active");
        require(bundles[_bundleId].seller == msg.sender, "Not bundle seller");
        bundles[_bundleId].isActive = false;
        emit BundleSaleCancelled(_bundleId);
    }


    // --- Gamified Staking and Rewards Functions ---
    modifier whenNotPausedStaking() {
        require(!paused, "Staking functions are paused");
        _;
    }

    function stakeNFT(uint256 _tokenId) public whenNotPausedStaking {
        require(msg.sender == ownerOf(_tokenId), "Not NFT owner");
        require(!NFTs[_tokenId].isStaked, "NFT is already staked");
        require(!isListedForSale(_tokenId) && !isAuctionActive(_tokenId) && !isBundleSaleActive(_tokenId), "NFT is listed for sale/auction/bundle");

        NFTs[_tokenId].isStaked = true;
        nftStakeStartTime[_tokenId] = block.timestamp;
        emit NFTStaked(_tokenId, msg.sender);
    }

    function unstakeNFT(uint256 _tokenId) public whenNotPausedStaking nonReentrant {
        require(NFTs[_tokenId].isStaked, "NFT is not staked");
        require(msg.sender == ownerOf(_tokenId), "Not NFT owner");

        uint256 rewards = calculateStakingRewards(_tokenId);
        pendingRewards[_tokenId] = rewards; // Store rewards for claiming later (or claim in this function)

        NFTs[_tokenId].isStaked = false;
        nftStakeStartTime[_tokenId] = 0; // Reset stake start time

        // Option 1: Claim rewards directly in unstake
        claimStakingRewards(_tokenId);
        emit NFTUnstaked(_tokenId, rewards);

        // Option 2: Rewards are pending, and user claims separately using claimStakingRewards()
        // emit NFTUnstaked(_tokenId, rewards);
    }

    function calculateStakingRewards(uint256 _tokenId) public view returns (uint256) {
        if (!NFTs[_tokenId].isStaked) {
            return 0;
        }

        uint256 stakeDuration = block.timestamp - nftStakeStartTime[_tokenId];
        uint256 daysStaked = stakeDuration / 1 days; // Integer division to get days

        uint256 baseRewards = daysStaked * rewardRatePerDay;
        uint256 boostMultiplier = 1;

        // Apply staking boost based on NFT traits
        if (stakingBoostTraitsIndices.length == stakingBoostMultipliers.length) {
            for (uint256 i = 0; i < stakingBoostTraitsIndices.length; i++) {
                uint256 traitIndex = stakingBoostTraitsIndices[i];
                uint256 multiplier = stakingBoostMultipliers[i];
                if (traitIndex < NFTs[_tokenId].traits.length) {
                    boostMultiplier = boostMultiplier * (1 + (NFTs[_tokenId].traits[traitIndex] * multiplier) / 100); // Example boost calculation
                }
            }
        }

        return baseRewards * boostMultiplier;
    }

    function claimStakingRewards(uint256 _tokenId) public whenNotPausedStaking nonReentrant {
        require(NFTs[_tokenId].isStaked || pendingRewards[_tokenId] > 0, "NFT is not staked or has no pending rewards");
        require(msg.sender == ownerOf(_tokenId), "Not NFT owner");

        uint256 rewardsToClaim = pendingRewards[_tokenId];
        if (!NFTs[_tokenId].isStaked) {
            pendingRewards[_tokenId] = 0; // Reset pending rewards after claiming only if not currently staked. If still staked, rewards will continue accumulating.
        } else {
            rewardsToClaim = calculateStakingRewards(_tokenId); // Recalculate if still staked to get up-to-date amount
            pendingRewards[_tokenId] = 0; // Reset pending rewards even if still staked, as they are now claimed.
        }


        if (rewardsToClaim > 0) {
            require(rewardToken.transfer(msg.sender, rewardsToClaim), "Reward token transfer failed");
            emit StakingRewardsClaimed(_tokenId, rewardsToClaim);
        }
    }

    function setRewardToken(address _rewardTokenAddress) public onlyOwner {
        rewardToken = IERC20(_rewardTokenAddress);
        // Optionally check if the address is a contract and supports ERC20 interface
    }

    function setRewardRate(uint256 _newRewardRate) public onlyOwner {
        rewardRatePerDay = _newRewardRate;
        emit RewardRateSet(_newRewardRate);
    }

    function setStakingBoostTraits(uint256[] memory _traitIndices, uint256[] memory _boostMultipliers) public onlyOwner {
        require(_traitIndices.length == _boostMultipliers.length, "Trait indices and multipliers arrays must have the same length");
        stakingBoostTraitsIndices = _traitIndices;
        stakingBoostMultipliers = _boostMultipliers;
        emit StakingBoostTraitsSet(_traitIndices, _boostMultipliers);
    }


    // --- DAO Governance Functions (Conceptual) ---
    // Note: Full DAO implementation requires a separate governance token and voting mechanism.
    // This is a simplified conceptual representation.

    function proposeParameterChange(string memory _proposalDescription, string memory _parameterName, uint256 _newValue) public {
        // In a real DAO, this would require governance token holding for proposal submission
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            description: _proposalDescription,
            parameterName: _parameterName,
            newValue: _newValue,
            votesFor: 0,
            votesAgainst: 0,
            votingEndTime: block.timestamp + votingDuration,
            isExecuted: false
        });
        emit ProposalCreated(proposalId, msg.sender, _proposalDescription, _parameterName, _newValue);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) public {
        require(!proposals[_proposalId].isExecuted, "Proposal already executed");
        require(block.timestamp < proposals[_proposalId].votingEndTime, "Voting period ended");
        // In a real DAO, voting power would be determined by governance token holdings
        if (_support) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) public onlyOwner { // Or DAO controlled executor
        require(!proposals[_proposalId].isExecuted, "Proposal already executed");
        require(block.timestamp >= proposals[_proposalId].votingEndTime, "Voting period not ended");
        require(proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst, "Proposal not approved"); // Simple majority

        proposals[_proposalId].isExecuted = true;

        // Example parameter changes - Extend as needed
        if (keccak256(bytes(proposals[_proposalId].parameterName)) == keccak256(bytes("rewardRatePerDay"))) {
            setRewardRate(proposals[_proposalId].newValue);
        } else if (keccak256(bytes(proposals[_proposalId].parameterName)) == keccak256(bytes("marketplaceFeePercentage"))) {
            setMarketplaceFee(proposals[_proposalId].newValue);
        }
        // Add more parameter updates based on proposal.parameterName

        emit ProposalExecuted(_proposalId);
    }


    // --- Admin Functions ---
    function withdrawMarketplaceFees(address _to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_to).transfer(balance);
    }

    function pauseContract() public onlyOwner {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() public onlyOwner {
        paused = false;
        emit ContractUnpaused();
    }

    function setMarketplaceFee(uint256 _newFeePercentage) public onlyOwner {
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100%");
        marketplaceFeePercentage = _newFeePercentage;
        emit MarketplaceFeeSet(_newFeePercentage);
    }

    function withdrawAnyERC20(address _tokenAddress, address _to, uint256 _amount) public onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(_amount <= balance, "Insufficient token balance in contract");
        require(token.transfer(_to, _amount), "Token transfer failed");
        emit TokensWithdrawn(_tokenAddress, _to, _amount);
    }

    // --- Utility View Functions ---
    function getListingDetails(uint256 _listingId) public view returns (Listing memory) {
        return listings[_listingId];
    }

    function getAuctionDetails(uint256 _auctionId) public view returns (Auction memory) {
        return auctions[_auctionId];
    }

    function getBundleDetails(uint256 _bundleId) public view returns (BundleSale memory) {
        return bundles[_bundleId];
    }

    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function isListedForSale(uint256 _tokenId) public view returns (bool) {
        for (uint256 i = 1; i <= _listingIdCounter.current(); i++) {
            if (listings[i].tokenId == _tokenId && listings[i].isActive) {
                return true;
            }
        }
        return false;
    }

    function isAuctionActive(uint256 _tokenId) public view returns (bool) {
        for (uint256 i = 1; i <= _auctionIdCounter.current(); i++) {
            if (auctions[i].tokenId == _tokenId && auctions[i].isActive) {
                return true;
            }
        }
        return false;
    }

    function isBundleSaleActive(uint256 _tokenId) public view returns (bool) {
        for (uint256 i = 1; i <= _bundleIdCounter.current(); i++) {
            BundleSale storage bundle = bundles[i];
            if (bundle.isActive) {
                for (uint256 j = 0; j < bundle.tokenIds.length; j++) {
                    if (bundle.tokenIds[j] == _tokenId) {
                        return true;
                    }
                }
            }
        }
        return false;
    }
}
```