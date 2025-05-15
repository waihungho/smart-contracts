Okay, here is a Solidity smart contract incorporating several advanced, creative, and trendy concepts like dynamic NFTs, gamified user/NFT progression, staking-based features, and basic on-chain proposals. The core idea is a marketplace where user activity and NFT ownership/holding influence their attributes and grant benefits.

This contract combines:
1.  **Dynamic NFTs:** Attributes of NFTs change based on actions within the marketplace.
2.  **Gamification:** Users and NFTs earn "Activity Points" (AP) leading to levels and unlocks.
3.  **Staking:** Users can stake a platform token for boosts and voting power.
4.  **Marketplace:** Listing, buying, and auctioning NFTs.
5.  **On-chain Proposals:** Stakers/high-level users can create and vote on proposals affecting contract parameters.

**Disclaimer:** This is a complex example for educational purposes. A production-ready contract would require significant security audits, gas optimizations, and potentially breaking down logic into separate contracts (e.g., Marketplace, Gamification, Staking, Governance) for better modularity and security. This combines them into one file to meet the "20+ functions in *a* smart contract" request.

---

### Contract Outline & Function Summary

**Contract Name:** `DynamicNFTMarketplaceWithGamification`

**Core Concepts:**
*   Dynamic NFT attribute updates triggered by marketplace/staking events.
*   User & NFT leveling based on earned Activity Points (AP).
*   Marketplace for fixed-price and auction listings.
*   Staking of an external ERC20 token for boosts and voting power.
*   On-chain proposal system for community input on contract parameters.

**Structs:**
*   `Listing`: Represents an NFT listing (fixed price or auction).
*   `Proposal`: Represents an on-chain proposal for configuration changes.

**State Variables:**
*   Addresses for owner, fee recipient, NFT contract, staking token contract.
*   Marketplace parameters (fees, min price).
*   Listing data and counter.
*   User and NFT activity points, levels, level thresholds.
*   Staking data (user stakes, total staked, reward rate/boost factor).
*   Proposal data and counter.

**Events:**
*   Standard marketplace events (`NFTListed`, `NFTBought`, `NewBid`, `AuctionEnded`, `ListingCancelled`).
*   Gamification events (`ActivityPointsEarned`, `LeveledUp`, `NFTPointsEarned`, `NFTAttributesUpdated`).
*   Staking events (`Staked`, `Unstaked`, `RewardsClaimed`).
*   Proposal events (`ProposalCreated`, `Voted`, `ProposalExecuted`).

**Functions Summary (>= 20):**

1.  `constructor`: Initializes the contract with necessary addresses and parameters.
2.  `listNFT`: Creates a fixed-price or auction listing for an NFT. (User action)
3.  `buyNFT`: Buys a fixed-price listed NFT. (User action)
4.  `bidNFT`: Places a bid on an auction listing. (User action)
5.  `endAuction`: Ends an auction listing and distributes assets if successful. (User/Anyone action)
6.  `cancelListing`: Cancels an active listing (owner/seller only). (User action)
7.  `stake`: Stakes platform tokens to earn AP boosts and voting power. (User action)
8.  `unstake`: Unstakes platform tokens. (User action)
9.  `createProposal`: Creates a new on-chain proposal (requires minimum stake or level). (User action)
10. `voteOnProposal`: Casts a vote on an open proposal. (User action, voting power based on stake/level)
11. `executeProposal`: Executes a proposal if it has passed and is within the execution window. (Anyone action)
12. `_addActivityPoints`: Internal function to add points to a user and trigger level checks. (Internal trigger)
13. `_addNFTActivityPoints`: Internal function to add points/XP to an NFT and trigger attribute updates. (Internal trigger)
14. `updateNFTAttributes`: Internal function (or external restricted) that calls the NFT contract to change attributes based on its XP/level. (Internal trigger)
15. `_checkAndLevelUp`: Internal function to check if a user has earned enough points to level up. (Internal trigger)
16. `_applyProposalEffect`: Internal function to apply the outcome of a successful proposal (e.g., change fees). (Internal trigger from `executeProposal`)
17. `getUserActivityPoints`: View function to get a user's current AP. (View)
18. `getUserLevel`: View function to get a user's current level. (View)
19. `getNFTActivityPoints`: View function to get an NFT's current AP/XP. (View)
20. `getUserStake`: View function to get a user's current staked amount. (View)
21. `getListing`: View function to retrieve details of a specific listing. (View)
22. `getProposal`: View function to retrieve details of a specific proposal. (View)
23. `getUserVote`: View function to check if a user has voted on a specific proposal. (View)
24. `getFeeRecipient`: View function for fee recipient. (View)
25. `getListingFeeBps`: View function for listing fee. (View)
26. `getSalesFeeBps`: View function for sales fee. (View)
27. `getMinListingPrice`: View function for min listing price. (View)
28. `getTotalStaked`: View function for total staked tokens. (View)
29. `getLevelThresholds`: View function for level requirements. (View)
30. `setFeeRecipient`: Owner-only function to set the fee recipient (potentially via proposal execution). (Admin/Internal action)
31. `setFeeBps`: Owner-only function to set marketplace fees (potentially via proposal execution). (Admin/Internal action)
32. `setLevelThresholds`: Owner-only function to set level point requirements (potentially via proposal execution). (Admin/Internal action)
33. `setStakingBoostFactor`: Owner-only function to set the staking AP boost (potentially via proposal execution). (Admin/Internal action)
34. `setNFTContract`: Owner-only function to set the Dynamic NFT contract address. (Admin action)
35. `setStakingToken`: Owner-only function to set the Staking Token contract address. (Admin action)
36. `withdrawETH`: Owner-only function to withdraw accumulated ETH fees. (Admin action)
37. `withdrawTokens`: Owner-only function to withdraw accumulated ERC20 tokens (excluding staked). (Admin action)

**(Note: Function count exceeds 20, ensuring the requirement is met with several core and administrative/view functions.)**

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Define an interface for the dynamic NFT contract
// We assume the NFT contract has functions to get and update its dynamic attributes
interface IDynamicNFT is IERC721 {
    // Example struct for dynamic attributes - actual structure depends on the NFT contract
    struct DynamicAttributes {
        uint256 level;
        uint256 xp;
        uint256 rarityScore; // Example attribute
        // Add other dynamic attributes here
    }

    function getDynamicAttributes(uint256 tokenId) external view returns (DynamicAttributes memory);
    // This function is called by the marketplace to trigger attribute changes
    function updateAttributes(uint256 tokenId, uint256 newXP, uint256 newRarityScore) external; // Example update function
    // Add other update functions based on your NFT contract's needs
}


contract DynamicNFTMarketplaceWithGamification is Ownable {
    using Address for address payable;

    // --- State Variables ---

    address payable public feeRecipient;
    IDynamicNFT public nftContract;
    IERC20 public stakingToken;

    // Marketplace configuration
    uint256 public listingFeeBps; // Basis points (e.g., 100 = 1%) for listing fee
    uint256 public salesFeeBps;   // Basis points for sales fee
    uint256 public minListingPrice; // Minimum price for fixed-price listings

    // Listing data
    struct Listing {
        uint256 listingId;
        address payable seller;
        uint256 tokenId;
        uint256 price; // For fixed price
        bool isAuction;
        uint256 endTime; // For auction
        address highestBidder; // For auction
        uint256 highestBid;   // For auction
        bool active;
    }
    mapping(uint256 => Listing) public listings;
    uint256 private _listingIdCounter;

    // Gamification data
    mapping(address => uint256) public userActivityPoints;
    mapping(address => uint256) public userLevel;
    uint256[] public levelThresholds; // Points required for each level (level 0 is base)
    mapping(uint256 => uint256) public nftActivityPoints; // XP/Points for individual NFTs

    // Staking data
    mapping(address => uint256) public userStakes;
    uint256 public totalStaked;
    uint256 public stakingBoostFactor = 100; // Percentage boost to AP earned (e.g., 100 = 1x, 150 = 1.5x)

    // Proposal data
    struct Proposal {
        uint256 proposalId;
        address proposer;
        string description; // e.g., "Change sales fee to 200 bps"
        uint256 creationTime;
        uint256 expirationTime;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVotingPower; // Sum of voting power from participants
        bool executed;
        bool isOpen;
        bytes data; // Data payload for execution (e.g., function signature + params)
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 private _proposalIdCounter;
    mapping(address => mapping(uint256 => bool)) public userVoted; // user => proposalId => voted?

    // --- Events ---

    event NFTListed(uint256 indexed listingId, address indexed seller, uint256 indexed tokenId, uint256 price, bool isAuction, uint256 endTime);
    event NFTBought(uint256 indexed listingId, address indexed buyer, uint256 indexed seller, uint256 indexed tokenId, uint256 price);
    event NewBid(uint256 indexed listingId, address indexed bidder, uint256 amount);
    event AuctionEnded(uint256 indexed listingId, address indexed winner, uint256 amount, uint256 indexed tokenId);
    event ListingCancelled(uint256 indexed listingId, address indexed seller, uint256 indexed tokenId);

    event ActivityPointsEarned(address indexed user, uint256 points);
    event LeveledUp(address indexed user, uint256 newLevel);
    event NFTPointsEarned(uint256 indexed tokenId, uint256 points);
    event NFTAttributesUpdated(uint256 indexed tokenId);

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 expirationTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor);
    event ProposalVoteFailed(uint256 indexed proposalId);

    // --- Errors ---

    error ListingNotFound(uint256 listingId);
    error NotListingOwner(uint256 listingId, address caller);
    error ListingNotActive(uint256 listingId);
    error InvalidAmount(uint256 amount);
    error PriceTooLow(uint256 price, uint256 minPrice);
    error NFTNotApprovedOrOwned(uint256 tokenId);
    error NotEnoughETH(uint255 required, uint256 sent);
    error ListingIsNotAuction(uint256 listingId);
    error ListingIsAuction(uint256 listingId);
    error AuctionEnded(uint256 listingId);
    error AuctionNotEnded(uint256 listingId);
    error BidTooLow(uint256 listingId, uint256 currentHighestBid, uint256 newBid);
    error CannotBidOnOwnListing();
    error NoBidsYet(uint256 listingId);
    error TokenTransferFailed();
    error NFTTransferFailed();
    error ETHTransferFailed();
    error StakingTokenNotSet();
    error NFTContractNotSet();
    error NotEnoughStaked(uint256 required, uint256 staked);
    error ProposalNotFound(uint256 proposalId);
    error ProposalNotOpen(uint256 proposalId);
    error ProposalExpired(uint256 proposalId);
    error ProposalAlreadyVoted(uint256 proposalId, address voter);
    error ProposalAlreadyExecuted(uint256 proposalId);
    error ProposalNotApproved(uint256 proposalId); // Votes didn't pass threshold
    error OnlyCallableByProposal(uint256 proposalId); // Function only callable by a proposal execution
    error InvalidLevelThresholds();
    error MinimumStakeOrLevelRequired(uint256 minStake, uint256 minLevel); // For creating proposals

    // --- Modifiers ---

    // Re-check this - this logic might be better inside functions
    modifier onlyCallableByProposalExecution(uint256 proposalId) {
        // This check is tricky without delegatecall or a more complex execution pattern.
        // For simplicity in this example, we'll assume only executeProposal calls functions
        // that check against a *currently processing* proposalId.
        // A safer implementation might involve hashing the proposal data and requiring it.
        // This is a simplified example and NOT production safe for arbitrary calls.
        _; // Placeholder - actual implementation needs careful design
    }

    // --- Constructor ---

    constructor(
        address payable _feeRecipient,
        address _nftContract,
        address _stakingToken,
        uint256 _listingFeeBps,
        uint256 _salesFeeBps,
        uint256 _minListingPrice,
        uint256[] memory _levelThresholds
    ) Ownable(msg.sender) {
        require(_feeRecipient != address(0), "Invalid fee recipient address");
        require(_nftContract != address(0), "Invalid NFT contract address");
        require(_stakingToken != address(0), "Invalid staking token address");
        require(_salesFeeBps <= 10000, "Sales fee cannot exceed 100%");
        require(_listingFeeBps <= 10000, "Listing fee cannot exceed 100%");
        require(_levelThresholds.length > 0, "Level thresholds must be provided");

        feeRecipient = _feeRecipient;
        nftContract = IDynamicNFT(_nftContract);
        stakingToken = IERC20(_stakingToken);
        listingFeeBps = _listingFeeBps;
        salesFeeBps = _salesFeeBps;
        minListingPrice = _minListingPrice;
        levelThresholds = _levelThresholds; // levelThresholds[0] is points for level 1, [1] for level 2, etc.
    }

    // --- Marketplace Functions ---

    /**
     * @notice Creates a new listing for an NFT. Can be fixed-price or auction.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The price for fixed-price, or starting bid for auction.
     * @param _isAuction True if this is an auction listing.
     * @param _duration The duration in seconds for an auction (0 for fixed price).
     */
    function listNFT(uint256 _tokenId, uint256 _price, bool _isAuction, uint256 _duration) external {
        require(_price >= minListingPrice, PriceTooLow(_price, minListingPrice));
        require(nftContract.ownerOf(_tokenId) == msg.sender, NFTNotApprovedOrOwned(_tokenId));
        // Requires prior approval: `nftContract.approve(address(this), _tokenId)` or `setApprovalForAll`

        // Transfer NFT to the marketplace contract
        nftContract.transferFrom(msg.sender, address(this), _tokenId);

        _listingIdCounter++;
        uint256 currentListingId = _listingIdCounter;

        listings[currentListingId] = Listing({
            listingId: currentListingId,
            seller: payable(msg.sender),
            tokenId: _tokenId,
            price: _price,
            isAuction: _isAuction,
            endTime: _isAuction ? block.timestamp + _duration : 0,
            highestBidder: address(0),
            highestBid: _isAuction ? 0 : _price, // Highest bid starts at 0 for auction
            active: true
        });

        // Apply listing fee if > 0
        uint256 feeAmount = (_price * listingFeeBps) / 10000;
        if (feeAmount > 0) {
             // For listing fee, can require ERC20 payment or deduct from sale
             // Let's assume ETH payment for simplicity in this example
             // A real contract might require `stakingToken.transferFrom` here
             // require(msg.value >= feeAmount, NotEnoughETH(feeAmount, msg.value));
             // (Skip collecting listing fee in ETH for simplicity of buy function logic)
             // Or deduct from final sale price. For this example, let's make listing free initially.
        }


        // Add activity points for listing
        _addActivityPoints(msg.sender, 5); // Example points

        emit NFTListed(currentListingId, msg.sender, _tokenId, _price, _isAuction, listings[currentListingId].endTime);
    }

    /**
     * @notice Buys a fixed-price listed NFT.
     * @param _listingId The ID of the listing to buy.
     */
    function buyNFT(uint256 _listingId) external payable {
        Listing storage listing = listings[_listingId];
        if (!listing.active) revert ListingNotFound(_listingId);
        if (listing.isAuction) revert ListingIsAuction(_listingId);
        if (msg.value < listing.price) revert NotEnoughETH(listing.price, msg.value);

        address payable seller = listing.seller;
        uint256 price = listing.price;
        uint256 tokenId = listing.tokenId;

        // Calculate fees
        uint256 salesFee = (price * salesFeeBps) / 10000;
        uint256 amountToSeller = price - salesFee;

        // Deactivate listing first (effects-interactions-checks)
        listing.active = false;

        // Transfer ETH
        feeRecipient.sendValue(salesFee);
        seller.sendValue(amountToSeller);
        if (msg.value > price) {
            // Refund excess ETH
            payable(msg.sender).sendValue(msg.value - price);
        }

        // Transfer NFT
        nftContract.transferFrom(address(this), msg.sender, tokenId);

        // Add activity points
        _addActivityPoints(msg.sender, 10); // Buyer points
        _addActivityPoints(seller, 10); // Seller points (for successful sale)
        _addNFTActivityPoints(tokenId, 20); // NFT gains points from sale

        emit NFTBought(_listingId, msg.sender, seller, tokenId, price);
    }

    /**
     * @notice Places a bid on an auction listing.
     * @param _listingId The ID of the auction listing.
     */
    function bidNFT(uint256 _listingId) external payable {
        Listing storage listing = listings[_listingId];
        if (!listing.active) revert ListingNotFound(_listingId);
        if (!listing.isAuction) revert ListingIsNotAuction(_listingId);
        if (block.timestamp >= listing.endTime) revert AuctionEnded(_listingId);
        if (msg.sender == listing.seller) revert CannotBidOnOwnListing();

        uint256 currentHighestBid = listing.highestBid;
        if (msg.value <= currentHighestBid) revert BidTooLow(_listingId, currentHighestBid, msg.value);

        // Refund previous highest bidder
        if (listing.highestBidder != address(0)) {
            payable(listing.highestBidder).sendValue(currentHighestBid);
        }

        // Set new highest bid and bidder
        listing.highestBid = msg.value;
        listing.highestBidder = msg.sender;

        // Add activity points
        _addActivityPoints(msg.sender, 3); // Bidder points
        _addNFTActivityPoints(listing.tokenId, 5); // NFT gains points from bid

        emit NewBid(_listingId, msg.sender, msg.value);
    }

    /**
     * @notice Ends an auction and distributes assets. Can be called by anyone after end time.
     * @param _listingId The ID of the auction listing.
     */
    function endAuction(uint256 _listingId) external {
        Listing storage listing = listings[_listingId];
        if (!listing.active) revert ListingNotFound(_listingId);
        if (!listing.isAuction) revert ListingIsNotAuction(_listingId);
        if (block.timestamp < listing.endTime) revert AuctionNotEnded(_listingId);

        address payable seller = listing.seller;
        uint256 tokenId = listing.tokenId;
        address winner = listing.highestBidder;
        uint256 winningBid = listing.highestBid;

        // Deactivate listing
        listing.active = false;

        if (winner == address(0)) {
            // No bids, return NFT to seller
            nftContract.transferFrom(address(this), seller, tokenId);
            emit AuctionEnded(_listingId, address(0), 0, tokenId);
        } else {
            // Calculate fees
            uint256 salesFee = (winningBid * salesFeeBps) / 10000;
            uint256 amountToSeller = winningBid - salesFee;

            // Transfer ETH
            feeRecipient.sendValue(salesFee);
            seller.sendValue(amountToSeller);

            // Transfer NFT to winner
            nftContract.transferFrom(address(this), winner, tokenId);

            // Add activity points
            _addActivityPoints(winner, 15); // Winner points
            _addActivityPoints(seller, 15); // Seller points (for successful auction)
            _addNFTActivityPoints(tokenId, 30); // NFT gains points from auction win

            emit AuctionEnded(_listingId, winner, winningBid, tokenId);
        }
    }

    /**
     * @notice Cancels a listing. Only callable by the seller or contract owner.
     * @param _listingId The ID of the listing to cancel.
     */
    function cancelListing(uint256 _listingId) external {
        Listing storage listing = listings[_listingId];
        if (!listing.active) revert ListingNotFound(_listingId);
        if (msg.sender != listing.seller && msg.sender != owner()) revert NotListingOwner(_listingId, msg.sender);
        // For auctions with bids, cancellation might need specific logic (e.g., allow only before first bid)
        if (listing.isAuction && listing.highestBidder != address(0)) {
            // Decide policy: require owner cancel, or disallow cancel after bids?
            // For this example, disallow seller cancel after bids. Owner can always cancel.
             if (msg.sender == listing.seller) {
                 revert InvalidAmount(0); // Reusing error for "cannot cancel auction with bids"
             }
        }


        // Deactivate listing
        listing.active = false;

        // Return NFT to seller
        nftContract.transferFrom(address(this), listing.seller, listing.tokenId);

        // Add activity points (maybe deduct for cancelled listing?)
        _addActivityPoints(msg.sender, 1); // Small points for attempt? Or -5 points? Let's add 1 for simplicity.

        emit ListingCancelled(_listingId, listing.seller, listing.tokenId);
    }

    // --- Gamification Functions (Internal & View) ---

    /**
     * @notice Internal function to add activity points to a user and check for level ups.
     * @param _user The address of the user.
     * @param _points The amount of points to add.
     */
    function _addActivityPoints(address _user, uint256 _points) internal {
        uint256 pointsToAdd = _points;
        // Apply staking boost
        if (userStakes[_user] > 0) {
            pointsToAdd = (pointsToAdd * (100 + stakingBoostFactor)) / 100;
        }

        userActivityPoints[_user] += pointsToAdd;
        emit ActivityPointsEarned(_user, pointsToAdd);

        _checkAndLevelUp(_user);
    }

    /**
     * @notice Internal function to check if a user can level up based on their AP.
     * @param _user The address of the user.
     */
    function _checkAndLevelUp(address _user) internal {
        uint256 currentLevel = userLevel[_user];
        uint256 currentPoints = userActivityPoints[_user];

        while (currentLevel < levelThresholds.length && currentPoints >= levelThresholds[currentLevel]) {
            currentLevel++;
            userLevel[_user] = currentLevel;
            emit LeveledUp(_user, currentLevel);
        }
    }

    /**
     * @notice Internal function to add activity points/XP to an NFT and trigger attribute updates.
     * @param _tokenId The ID of the NFT.
     * @param _points The amount of points/XP to add.
     */
    function _addNFTActivityPoints(uint256 _tokenId, uint256 _points) internal {
        nftActivityPoints[_tokenId] += _points;
        emit NFTPointsEarned(_tokenId, _points);

        // Trigger dynamic attribute update on the NFT contract
        // This assumes the NFT contract's update logic is based on total XP
        IDynamicNFT.DynamicAttributes memory currentAttrs = nftContract.getDynamicAttributes(_tokenId);
        // Example: Update based on cumulative XP and maybe a calculated rarity factor
        uint256 newXP = nftActivityPoints[_tokenId];
        uint256 newRarityScore = currentAttrs.rarityScore; // Keep or recalculate based on XP/level

        // A more complex logic might derive level/rarity solely from XP
        // For this simple example, let's just pass XP through and a placeholder rarity
        nftContract.updateAttributes(_tokenId, newXP, newRarityScore);

        emit NFTAttributesUpdated(_tokenId);
    }

    /**
     * @notice View function to get a user's current activity points.
     * @param _user The address of the user.
     * @return The user's activity points.
     */
    function getUserActivityPoints(address _user) external view returns (uint256) {
        return userActivityPoints[_user];
    }

    /**
     * @notice View function to get a user's current level.
     * @param _user The address of the user.
     * @return The user's level.
     */
    function getUserLevel(address _user) external view returns (uint256) {
        return userLevel[_user];
    }

    /**
     * @notice View function to get an NFT's current activity points (XP).
     * @param _tokenId The ID of the NFT.
     * @return The NFT's activity points (XP).
     */
    function getNFTActivityPoints(uint256 _tokenId) external view returns (uint256) {
        return nftActivityPoints[_tokenId];
    }

    /**
     * @notice View function to get the points required for each level.
     * @return An array of level thresholds.
     */
    function getLevelThresholds() external view returns (uint256[] memory) {
        return levelThresholds;
    }

    // --- Staking Functions ---

    /**
     * @notice Stakes platform tokens in the contract. Requires prior approval.
     * @param _amount The amount of tokens to stake.
     */
    function stake(uint256 _amount) external {
        if (_amount == 0) revert InvalidAmount(_amount);
        if (address(stakingToken) == address(0)) revert StakingTokenNotSet();

        // Transfer tokens from user to this contract
        bool success = stakingToken.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert TokenTransferFailed();

        userStakes[msg.sender] += _amount;
        totalStaked += _amount;

        // Add activity points for staking (e.g., small amount per stake, or based on amount)
        _addActivityPoints(msg.sender, 2); // Example points

        emit Staked(msg.sender, _amount);
    }

    /**
     * @notice Unstakes platform tokens from the contract.
     * @param _amount The amount of tokens to unstake.
     */
    function unstake(uint256 _amount) external {
        if (_amount == 0) revert InvalidAmount(_amount);
        if (address(stakingToken) == address(0)) revert StakingTokenNotSet();
        if (userStakes[msg.sender] < _amount) revert NotEnoughStaked(_amount, userStakes[msg.sender]);

        userStakes[msg.sender] -= _amount;
        totalStaked -= _amount;

        // Transfer tokens from this contract back to user
        bool success = stakingToken.transfer(msg.sender, _amount);
        if (!success) revert TokenTransferFailed();

        // Maybe deduct points or reduce level effects slightly for unstaking?
        // For simplicity, just unstake.

        emit Unstaked(msg.sender, _amount);
    }

     /**
     * @notice View function to get a user's current staked amount.
     * @param _user The address of the user.
     * @return The user's staked tokens.
     */
    function getUserStake(address _user) external view returns (uint256) {
        return userStakes[_user];
    }

     /**
     * @notice View function to get the total amount of tokens staked in the contract.
     * @return Total staked tokens.
     */
    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }


    // --- Proposal Functions ---

    /**
     * @notice Creates a new on-chain proposal.
     * @param _description A description of the proposal.
     * @param _duration The duration in seconds for voting.
     * @param _data Optional data payload for execution if the proposal passes.
     *             (e.g., ABI encoded function call for a specific allowed admin function)
     */
    function createProposal(string calldata _description, uint256 _duration, bytes calldata _data) external {
        // Require minimum stake or level to prevent spam
        uint256 minStakeForProposal = 100 * (10**stakingToken.decimals()); // Example: 100 tokens
        uint256 minLevelForProposal = 5; // Example: Level 5

        if (userStakes[msg.sender] < minStakeForProposal && userLevel[msg.sender] < minLevelForProposal) {
            revert MinimumStakeOrLevelRequired(minStakeForProposal, minLevelForProposal);
        }

        _proposalIdCounter++;
        uint256 currentProposalId = _proposalIdCounter;
        uint256 expiration = block.timestamp + _duration;

        proposals[currentProposalId] = Proposal({
            proposalId: currentProposalId,
            proposer: msg.sender,
            description: _description,
            creationTime: block.timestamp,
            expirationTime: expiration,
            votesFor: 0,
            votesAgainst: 0,
            totalVotingPower: 0,
            executed: false,
            isOpen: true,
            data: _data
        });

        emit ProposalCreated(currentProposalId, msg.sender, _description, expiration);
    }

    /**
     * @notice Casts a vote on an open proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' (yes), False for 'against' (no).
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        if (!proposal.isOpen) revert ProposalNotFound(_proposalId); // Using notFound error for not open/exists
        if (block.timestamp >= proposal.expirationTime) revert ProposalExpired(_proposalId);
        if (userVoted[msg.sender][_proposalId]) revert ProposalAlreadyVoted(_proposalId, msg.sender);

        // Calculate voting power: e.g., 1 power per staked token + bonus per level
        uint256 votingPower = userStakes[msg.sender] + (userLevel[msg.sender] * 10); // Example calculation

        require(votingPower > 0, InsufficientStakeOrLevel()); // Need stake or level to vote

        userVoted[msg.sender][_proposalId] = true;
        proposal.totalVotingPower += votingPower;

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        // Add activity points for voting
        _addActivityPoints(msg.sender, 1); // Small points for engagement

        emit Voted(_proposalId, msg.sender, _support, votingPower);
    }

    /**
     * @notice Executes a proposal if it has ended and passed the voting threshold.
     *         Can be called by anyone after the voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        if (!proposal.isOpen) revert ProposalNotFound(_proposalId); // Using notFound error for not open/exists
        if (block.timestamp < proposal.expirationTime) revert AuctionNotEnded(_proposalId); // Reusing error for "not ended"
        if (proposal.executed) revert ProposalAlreadyExecuted(_proposalId);

        // Define voting threshold: e.g., > 50% of participating voting power
        // Or require minimum total participation
        bool passed = proposal.votesFor > proposal.votesAgainst &&
                      proposal.votesFor + proposal.votesAgainst > 0; // Ensure at least one vote

        proposal.isOpen = false; // Close voting

        if (passed) {
            proposal.executed = true;
            // Attempt to apply the proposal effect using the data payload
            // **SECURITY NOTE:** Direct `call` with arbitrary user-provided data is extremely dangerous.
            // A production system would have a strict allowlist of function signatures/parameters
            // that proposals can trigger, or a more robust governance module.
            // For this example, we'll call an internal helper that *might* interpret the data,
            // but the helper itself would need strict checks. Let's just emit event for demo.

             // _applyProposalEffect(_proposalId, proposal.data); // Example call (dangerous pattern)

            emit ProposalExecuted(_proposalId, msg.sender);

        } else {
             emit ProposalVoteFailed(_proposalId);
        }

         // Add activity points for participating/attempting execution
         _addActivityPoints(msg.sender, 2); // Example points
    }

    // Internal helper to apply effects - Placeholder for actual logic (see security note above)
    // This function is NOT secure for arbitrary data/calls.
    function _applyProposalEffect(uint256 _proposalId, bytes memory _data) internal {
        // Example: Interpret data to call admin functions like setFeeBps
        // This requires careful encoding/decoding and validation.
        // For this example, we'll just acknowledge it was called.
        require(proposals[_proposalId].executed, "Proposal must be executed");
        // if (_data.length > 0) {
        //     (bool success, bytes memory result) = address(this).call(_data);
        //     require(success, "Proposal execution call failed");
        // }
         // No actual execution logic here for safety in demo.
    }


    /**
     * @notice View function to get the details of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return The proposal struct.
     */
    function getProposal(uint256 _proposalId) external view returns (Proposal memory) {
        if (_proposalId == 0 || _proposalId > _proposalIdCounter) revert ProposalNotFound(_proposalId);
        return proposals[_proposalId];
    }

    /**
     * @notice View function to check if a user has voted on a specific proposal.
     * @param _user The address of the user.
     * @param _proposalId The ID of the proposal.
     * @return True if the user has voted, false otherwise.
     */
    function getUserVote(address _user, uint256 _proposalId) external view returns (bool) {
        return userVoted[_user][_proposalId];
    }


    // --- View Functions (Marketplace Config) ---

    function getFeeRecipient() external view returns (address payable) {
        return feeRecipient;
    }

    function getListingFeeBps() external view returns (uint256) {
        return listingFeeBps;
    }

    function getSalesFeeBps() external view returns (uint256) {
        return salesFeeBps;
    }

    function getMinListingPrice() external view returns (uint256) {
        return minListingPrice;
    }

    /**
     * @notice View function to get details of a specific listing.
     * @param _listingId The ID of the listing.
     * @return The Listing struct.
     */
    function getListing(uint256 _listingId) external view returns (Listing memory) {
        if (_listingId == 0 || _listingId > _listingIdCounter || !listings[_listingId].active) {
             revert ListingNotFound(_listingId);
        }
        return listings[_listingId];
    }


    // --- Admin Functions (Potentially callable via successful proposals) ---

    /**
     * @notice Sets the address that receives marketplace fees. Owner-only.
     *         In a governance system, this would likely be triggered by a successful proposal.
     * @param _feeRecipient The new fee recipient address.
     */
    function setFeeRecipient(address payable _feeRecipient) external onlyOwner {
         require(_feeRecipient != address(0), "Invalid address");
         feeRecipient = _feeRecipient;
    }

    /**
     * @notice Sets the listing and sales fee percentages in basis points. Owner-only.
     *         In a governance system, this would likely be triggered by a successful proposal.
     * @param _listingBps New listing fee in basis points.
     * @param _salesBps New sales fee in basis points.
     */
    function setFeeBps(uint256 _listingBps, uint256 _salesBps) external onlyOwner {
        require(_listingBps <= 10000, "Listing fee exceeds 100%");
        require(_salesBps <= 10000, "Sales fee exceeds 100%");
        listingFeeBps = _listingBps;
        salesFeeBps = _salesBps;
    }

     /**
     * @notice Sets the points required for each level. Owner-only.
     *         In a governance system, this would likely be triggered by a successful proposal.
     * @param _levelThresholds Array of points for each level (index 0 = level 1, etc.).
     */
    function setLevelThresholds(uint256[] memory _levelThresholds) external onlyOwner {
        require(_levelThresholds.length > 0, InvalidLevelThresholds());
        levelThresholds = _levelThresholds;
    }

     /**
     * @notice Sets the percentage boost applied to AP earned by stakers. Owner-only.
     *         In a governance system, this would likely be triggered by a successful proposal.
     * @param _boostFactor The new boost factor percentage (e.g., 150 for 1.5x).
     */
    function setStakingBoostFactor(uint256 _boostFactor) external onlyOwner {
        stakingBoostFactor = _boostFactor;
    }

    /**
     * @notice Sets the address of the Dynamic NFT contract. Owner-only.
     * @param _nftContract The address of the IDynamicNFT contract.
     */
    function setNFTContract(address _nftContract) external onlyOwner {
        require(_nftContract != address(0), "Invalid address");
        nftContract = IDynamicNFT(_nftContract);
    }

    /**
     * @notice Sets the address of the Staking Token contract. Owner-only.
     * @param _stakingToken The address of the IERC20 staking token.
     */
    function setStakingToken(address _stakingToken) external onlyOwner {
        require(_stakingToken != address(0), "Invalid address");
        stakingToken = IERC20(_stakingToken);
    }

    /**
     * @notice Withdraws accumulated ETH fees to the fee recipient. Owner-only.
     */
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = feeRecipient.call{value: balance}("");
            require(success, ETHTransferFailed());
        }
    }

    /**
     * @notice Withdraws accumulated ERC20 tokens (excluding staked) to the owner. Owner-only.
     * @param _tokenAddress The address of the ERC20 token to withdraw.
     */
    function withdrawTokens(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == address(stakingToken)) {
             // Don't withdraw staked tokens this way
             uint256 nonStakedBalance = stakingToken.balanceOf(address(this)) - totalStaked;
             if (nonStakedBalance > 0) {
                 bool success = stakingToken.transfer(owner(), nonStakedBalance);
                 require(success, TokenTransferFailed());
             }
        } else {
            // Withdraw other ERC20 tokens the contract might hold accidentally
            IERC20 tokenToWithdraw = IERC20(_tokenAddress);
            uint256 balance = tokenToWithdraw.balanceOf(address(this));
            if (balance > 0) {
                 bool success = tokenToWithdraw.transfer(owner(), balance);
                 require(success, TokenTransferFailed());
            }
        }
    }

    // Receive function to allow receiving ETH
    receive() external payable {}
    fallback() external payable {} // Allow receiving ETH via fallback as well

}
```