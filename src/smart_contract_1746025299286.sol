Okay, let's design a smart contract that combines dynamic NFTs with a time-sensitive marketplace, staking, and basic governance. The core idea is "Temporal NFTs" (TNTs) whose utility or attributes change based on time, traded on a market with features like time-limited listings and auctions, plus staking for yield and governance over market parameters.

This contract will act as the ERC721 contract for the Temporal NFTs *and* the marketplace, staking, and governance hub. This helps meet the function count while keeping the logic interconnected and unique.

---

## Smart Contract Outline & Function Summary

**Contract Name:** `ChronosMarketWithTemporalNFTs`

**Concept:** A decentralized marketplace and management contract for "Temporal NFTs" (TNTs). TNTs are ERC721 tokens whose perceived value or utility can be influenced by time (e.g., time since mint, time since last transfer, time staked). The market supports standard listings, time-limited auctions, and offers. NFTs can be staked for a time-based yield in a governance token. Key market parameters are subject to basic on-chain governance.

**Core Features:**
1.  **Temporal NFTs (TNTs):** ERC721 tokens with time-sensitive attributes/potential.
2.  **Marketplace:** Fixed-price listings (with optional expiration), time-limited auctions, and direct offers.
3.  **Staking:** Stake TNTs to earn yield in a separate governance token.
4.  **Governance:** Simple system to propose and vote on changes to market parameters (fees, auction duration, staking rates).

**Function Summary:**

**ERC721 Standard Implementation (for Temporal NFTs managed by this contract):**
1.  `balanceOf(address owner)`: Returns the number of tokens owned by an address.
2.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific token ID.
3.  `approve(address to, uint256 tokenId)`: Approves another address to transfer a specific token.
4.  `getApproved(uint256 tokenId)`: Returns the approved address for a single token ID.
5.  `setApprovalForAll(address operator, bool approved)`: Approves or disapproves an operator for all tokens of `msg.sender`.
6.  `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for an owner.
7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of a token.
8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer with optional data.
9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer with data.
10. `supportsInterface(bytes4 interfaceId)`: Standard ERC165 support check.

**Temporal NFT Specific Functions:**
11. `mintTemporalNFT(address to, string memory uri, uint256 initialPotential)`: Mints a new TNT with initial potential and URI.
12. `getTemporalNFTDetails(uint256 tokenId)`: Returns stored details (mint time, last transfer time, potential, etc.) for a TNT.
13. `calculateCurrentUtility(uint256 tokenId)`: **View Function:** Calculates the dynamic utility/value modifier based on the NFT's time-based parameters and current time. (This is a core "dynamic" aspect).

**Marketplace Functions:**
14. `listItem(uint256 tokenId, uint256 price, uint64 expirationTimestamp)`: Lists an NFT for sale at a fixed price, with optional expiration.
15. `buyItem(uint256 tokenId)`: Buys a listed NFT.
16. `cancelListing(uint256 tokenId)`: Cancels an active listing.
17. `listAuction(uint256 tokenId, uint256 minBid, uint64 startTimestamp, uint64 endTimestamp)`: Lists an NFT for auction.
18. `placeBid(uint256 tokenId)`: Places a bid on an auction. Requires sending Ether.
19. `cancelOffer(uint256 tokenId)`: Cancels a direct offer you made.
20. `acceptOffer(uint256 tokenId, address offerer)`: Seller accepts a direct offer on their NFT.
21. `makeOffer(uint256 tokenId, uint256 offerAmount, uint64 expirationTimestamp)`: Makes a direct offer on an NFT, regardless of listing state. Requires sending Ether.
22. `closeAuction(uint256 tokenId)`: Ends an auction and transfers the NFT to the highest bidder if applicable.

**Staking Functions:**
23. `stakeNFT(uint256 tokenId)`: Stakes a TNT to earn governance tokens. Requires ownership.
24. `unstakeNFT(uint256 tokenId)`: Unstakes a TNT.
25. `claimStakingRewards(uint256[] calldata tokenIds)`: Claims accumulated governance token rewards for multiple staked NFTs.
26. `getAccumulatedRewards(uint256 tokenId)`: **View Function:** Calculates the pending staking rewards for a specific staked NFT.

**Governance Functions:**
27. `proposeParameterChange(uint256 paramIndex, uint256 newValue, string memory description)`: Proposes changing a specific market parameter.
28. `voteOnProposal(uint256 proposalId, bool support)`: Casts a vote on an active proposal.
29. `executeProposal(uint256 proposalId)`: Executes a successful proposal after the voting period ends.
30. `getProposalState(uint256 proposalId)`: **View Function:** Gets the current state of a proposal.

**Admin/Utility Functions:**
31. `setFeeReceiver(address _feeReceiver)`: Sets the address receiving market fees.
32. `withdrawMarketFees()`: Allows the fee receiver to withdraw collected fees.
33. `getMarketParams()`: **View Function:** Returns the current market parameters.
34. `getCurrentListing(uint256 tokenId)`: **View Function:** Gets details of the active listing for a token.
35. `getCurrentAuction(uint256 tokenId)`: **View Function:** Gets details of the active auction for a token.
36. `getOffer(uint256 tokenId, address offerer)`: **View Function:** Gets details of a specific offer on a token.
37. `getStakingPosition(uint256 tokenId)`: **View Function:** Gets details of the staking position for a token.

*(Note: This is 37 functions, well over the minimum 20)*

---

## Solidity Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For governance token
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Outline & Function Summary Above ---

contract ChronosMarketWithTemporalNFTs is Context, Ownable, ERC721, IERC721Receiver {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Errors ---
    error InvalidInput();
    error NotOwner();
    error NotApprovedOrOwner();
    error TokenDoesNotExist();
    error AlreadyListedOrAuctioned();
    error NotListedOrAuctioned();
    error ListingExpired();
    error PriceMismatch();
    error ERC20TransferFailed();
    error ERC721TransferFailed();
    error AuctionNotStarted();
    error AuctionEnded();
    error BidTooLow();
    error NoBidsYet();
    error AuctionStillActive();
    error CannotBidOnOwnAuction();
    error OfferExpired();
    error OfferAlreadyExists();
    error OfferDoesNotExist();
    error CannotAcceptOwnOffer();
    error NotStaked();
    error AlreadyStaked();
    error RewardsNotClaimableYet(); // If min staking duration needed
    error NoRewardsToClaim();
    error GovernanceProposalNotFound();
    error GovernanceProposalNotActive();
    error GovernanceProposalAlreadyVoted();
    error GovernanceProposalNotSucceeded();
    error GovernanceProposalExpired();
    error GovernanceProposalNotExecutableYet(); // If there's a delay after success
    error MarketFeeWithdrawFailed();
    error InvalidProposalParamIndex();
    error StakingAlreadyExists();
    error TokenNotStaked();

    // --- Events ---
    event TemporalNFTMinted(uint256 indexed tokenId, address indexed owner, string uri, uint256 initialPotential, uint64 mintTimestamp);
    event TemporalNFTTransferred(uint256 indexed tokenId, address indexed from, address indexed to, uint64 timestamp);
    event TemporalNFTBurned(uint256 indexed tokenId);

    event ItemListed(uint256 indexed tokenId, address indexed seller, uint256 price, uint64 expirationTimestamp);
    event ItemBought(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event ListingCancelled(uint256 indexed tokenId);

    event AuctionStarted(uint256 indexed tokenId, address indexed seller, uint256 minBid, uint64 startTimestamp, uint64 endTimestamp);
    event BidPlaced(uint256 indexed tokenId, address indexed bidder, uint256 amount);
    event AuctionClosed(uint256 indexed tokenId, address indexed winner, uint256 finalPrice);
    event BidWithdrawn(uint256 indexed tokenId, address indexed bidder, uint256 amount);

    event OfferMade(uint256 indexed tokenId, address indexed offerer, uint256 amount, uint64 expirationTimestamp);
    event OfferAccepted(uint256 indexed tokenId, address indexed offerer, uint256 amount);
    event OfferCancelled(uint256 indexed tokenId, address indexed offerer);

    event NFTStaked(uint256 indexed tokenId, address indexed staker, uint64 stakeTimestamp);
    event NFTUnstaked(uint256 indexed tokenId, address indexed staker, uint64 unstakeTimestamp);
    event StakingRewardsClaimed(address indexed staker, uint256[] tokenIds, uint256 amount);

    event ParameterChangeProposed(uint256 indexed proposalId, address indexed proposer, uint256 paramIndex, uint256 newValue, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, uint256 paramIndex, uint256 newValue);

    event FeeReceiverUpdated(address indexed oldReceiver, address indexed newReceiver);
    event MarketFeesWithdrawn(address indexed receiver, uint256 amount);

    // --- State Variables ---

    // Temporal NFT Data
    struct TemporalNFTData {
        uint64 mintTimestamp;
        uint64 lastTransferTimestamp; // Use 0 if never transferred after mint
        uint256 initialPotential; // Base value for utility calculation
        // Add more dynamic parameters here if needed, e.g., decayRate, growthRate
    }
    mapping(uint256 => TemporalNFTData) private _temporalNFTs;
    Counters.Counter private _tokenIdCounter;

    // Marketplace Data
    enum ListingStatus { Active, Cancelled, Sold, Expired }
    struct Listing {
        uint256 tokenId;
        address payable seller;
        uint26 price; // Use uint256, adjusted size is optimization for uint26
        uint64 listingTimestamp;
        uint64 expirationTimestamp; // 0 for no expiration
        ListingStatus status;
    }
    mapping(uint256 => Listing) private _listings; // tokenId -> Listing
    mapping(address => uint256[]) private _sellerListings; // seller -> list of tokenIds

    enum AuctionStatus { Active, Ended, Cancelled }
     struct Auction {
        uint256 tokenId;
        address payable seller;
        uint256 minBid;
        uint64 startTimestamp;
        uint64 endTimestamp;
        address highestBidder;
        uint256 highestBid;
        mapping(address => uint256) bids; // bidder -> bid amount (for managing refunds)
        AuctionStatus status;
    }
    mapping(uint256 => Auction) private _auctions; // tokenId -> Auction

    enum OfferStatus { Active, Accepted, Rejected, Cancelled, Expired }
    struct Offer {
        uint256 amount;
        address payable offerer;
        uint64 offerTimestamp;
        uint64 expirationTimestamp;
        OfferStatus status;
    }
    mapping(uint256 => mapping(address => Offer)) private _offers; // tokenId -> offerer -> Offer

    // Staking Data
    struct StakingPosition {
        uint256 tokenId;
        address staker;
        uint64 stakeTimestamp;
        uint256 accumulatedRewards; // Rewards calculated up to the last interaction (claim/unstake)
        // uint256 lastRewardCalculationTimestamp; // Needed if calculation is complex
    }
    mapping(uint256 => StakingPosition) private _stakedNFTs; // tokenId -> StakingPosition
    mapping(address => uint256[]) private _stakerStakedNFTs; // staker -> list of staked tokenIds

    IERC20 public immutable governanceToken; // The token used for rewards and governance

    // Governance Data
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Expired }
    struct GovernanceProposal {
        uint256 id;
        address proposer;
        uint64 creationTimestamp;
        uint64 votingPeriodEnd; // Duration added to creationTimestamp
        uint256 paramIndex; // Index of the parameter being changed
        uint256 newValue; // New value for the parameter
        string description;
        uint256 totalVotes;
        uint256 supportVotes;
        mapping(address => bool) hasVoted;
        ProposalState state;
    }
    mapping(uint256 => GovernanceProposal) private _proposals;
    Counters.Counter private _proposalIdCounter;

    struct MarketParams {
        uint16 marketFeeBasisPoints; // e.g., 250 for 2.5%
        uint64 minListingDuration; // in seconds
        uint64 minAuctionDuration; // in seconds
        uint64 maxAuctionDuration; // in seconds
        uint64 minOfferDuration; // in seconds
        uint64 maxOfferDuration; // in seconds
        uint64 stakingAPYBasisPoints; // e.g., 500 for 5% APY
        uint64 governanceVotingPeriod; // in seconds
        uint256 governanceQuorumBasisPoints; // e.g., 5000 for 50% of supply
    }
    MarketParams public marketParams;

    address payable public feeReceiver;
    uint26 public totalMarketFeesCollected; // Use uint256

    uint256 public constant PARAM_MARKET_FEE = 0;
    uint256 public constant PARAM_MIN_LISTING_DURATION = 1;
    uint256 public constant PARAM_MIN_AUCTION_DURATION = 2;
    uint256 public constant PARAM_MAX_AUCTION_DURATION = 3;
    uint256 public constant PARAM_MIN_OFFER_DURATION = 4;
    uint256 public constant PARAM_MAX_OFFER_DURATION = 5;
    uint256 public constant PARAM_STAKING_APY = 6;
    uint256 public constant PARAM_GOVERNANCE_VOTING_PERIOD = 7;
    uint256 public constant PARAM_GOVERNANCE_QUORUM = 8;

    // --- Constructor ---
    constructor(
        address _governanceTokenAddress,
        address payable _feeReceiver,
        uint16 _initialMarketFeeBasisPoints,
        uint64 _initialMinListingDuration,
        uint64 _initialMinAuctionDuration,
        uint64 _initialMaxAuctionDuration,
        uint64 _initialMinOfferDuration,
        uint64 _initialMaxOfferDuration,
        uint64 _initialStakingAPYBasisPoints,
        uint64 _initialGovernanceVotingPeriod,
        uint256 _initialGovernanceQuorumBasisPoints // Needs total supply context, simple basis points here.
    ) ERC721("TemporalNFT", "TNT") Ownable(_msgSender()) {
        require(_governanceTokenAddress != address(0), "Invalid governance token address");
        require(_feeReceiver != address(0), "Invalid fee receiver address");
        require(_initialMarketFeeBasisPoints <= 10000, "Fee must be <= 100%");
        require(_initialStakingAPYBasisPoints <= 100000, "APY must be reasonable"); // e.g., Max 1000%
        require(_initialGovernanceQuorumBasisPoints <= 10000, "Quorum must be <= 100%");
        require(_initialMinAuctionDuration > 0 && _initialMaxAuctionDuration >= _initialMinAuctionDuration, "Invalid auction durations");

        governanceToken = IERC20(_governanceTokenAddress);
        feeReceiver = _feeReceiver;

        marketParams = MarketParams({
            marketFeeBasisPoints: _initialMarketFeeBasisPoints,
            minListingDuration: _initialMinListingDuration,
            minAuctionDuration: _initialMinAuctionDuration,
            maxAuctionDuration: _initialMaxAuctionDuration,
            minOfferDuration: _initialMinOfferDuration,
            maxOfferDuration: _initialMaxOfferDuration,
            stakingAPYBasisPoints: _initialStakingAPYBasisPoints,
            governanceVotingPeriod: _initialGovernanceVotingPeriod,
            governanceQuorumBasisPoints: _initialGovernanceQuorumBasisPoints
        });

        totalMarketFeesCollected = 0;
    }

    // --- ERC721 Standard Implementation ---
    // Inherited from OpenZeppelin: balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom(address,address,uint256), safeTransferFrom(address,address,uint256,bytes)
    // We only need to override the transfer/safeTransferFrom methods to update our internal time tracking.
    // supportsInterface is also inherited.

    // Overriding transfers to track lastTransferTimestamp
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        // Add checks: Not listed, not in auction, not staked
        _checkTransferAllowed(tokenId);
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
         // Add checks: Not listed, not in auction, not staked
        _checkTransferAllowed(tokenId);
       _safeTransfer(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
         // Add checks: Not listed, not in auction, not staked
        _checkTransferAllowed(tokenId);
        _safeTransfer(from, to, tokenId, data);
    }

     // Internal transfer logic override to update timestamp
    function _transfer(address from, address to, uint256 tokenId) internal override {
        // Ensure the token exists and the `from` address is the owner before standard transfer
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Perform the standard ERC721 transfer
        super._transfer(from, to, tokenId);

        // Update our internal time tracking
        TemporalNFTData storage nftData = _temporalNFTs[tokenId];
        nftData.lastTransferTimestamp = uint64(block.timestamp);

        emit TemporalNFTTransferred(tokenId, from, to, uint64(block.timestamp));
    }

    // Needed for safeTransferFrom callback
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external pure override returns (bytes4) {
        // This function is called when an ERC721 is transferred *to* this contract.
        // We need this to accept NFTs, e.g., for listing or staking.
        // The logic for *what to do* with the received NFT is handled within
        // listItem, listAuction, stakeNFT functions *before* calling safeTransferFrom.
        // This callback just needs to return the selector to indicate acceptance.
        return IERC721Receiver.onERC721Received.selector;
    }


    // --- Temporal NFT Specific Functions ---

    /**
     * @notice Mints a new Temporal NFT and assigns it to an address.
     * @param to The address to receive the NFT.
     * @param uri The metadata URI for the NFT.
     * @param initialPotential A base value used for dynamic utility calculation.
     */
    function mintTemporalNFT(address to, string memory uri, uint256 initialPotential) public onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _mint(to, newTokenId);
        _setTokenURI(newTokenId, uri);

        _temporalNFTs[newTokenId] = TemporalNFTData({
            mintTimestamp: uint64(block.timestamp),
            lastTransferTimestamp: uint64(block.timestamp), // Initialize to mint time
            initialPotential: initialPotential
            // Initialize other potential dynamic params here
        });

        emit TemporalNFTMinted(newTokenId, to, uri, initialPotential, uint64(block.timestamp));
        return newTokenId;
    }

     /**
     * @notice Returns the stored temporal data for a specific NFT.
     * @param tokenId The ID of the NFT.
     * @return A struct containing the NFT's temporal data.
     */
    function getTemporalNFTDetails(uint256 tokenId) public view returns (TemporalNFTData memory) {
        require(_exists(tokenId), TokenDoesNotExist());
        return _temporalNFTs[tokenId];
    }

    /**
     * @notice Calculates the current dynamic utility or modifier for an NFT based on time.
     * @dev This is a simple example calculation. Real-world use would be more complex.
     *      Example: Utility decays over time since last transfer. Higher initial potential
     *      means higher starting utility.
     *      Formula: initialPotential * (decayFactor ^ (currentTime - lastTransferTime))
     *      decayFactor < 1. For simplicity, let's use a linear decay or a simple step function.
     *      Let's do: initialPotential * max(0, (decayDuration - elapsedTransferTime) / decayDuration)
     * @param tokenId The ID of the NFT.
     * @return The calculated current utility value.
     */
    function calculateCurrentUtility(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), TokenDoesNotExist());
        TemporalNFTData memory nftData = _temporalNFTs[tokenId];
        uint256 initialPotential = nftData.initialPotential;
        uint64 lastTransferTime = nftData.lastTransferTimestamp;
        uint66 currentTime = uint66(block.timestamp);

        // Example simple linear decay over a fixed duration (e.g., 365 days = 31536000 seconds)
        uint64 decayDuration = 31536000; // 1 year
        uint66 elapsedTransferTime = currentTime - lastTransferTime;

        if (elapsedTransferTime >= decayDuration) {
            return 0; // Full decay
        } else {
            uint256 remainingTime = decayDuration - uint256(elapsedTransferTime);
            // Avoid division by zero if decayDuration is 0 (shouldn't happen with >0 constant)
            uint256 utility = initialPotential.mul(remainingTime).div(decayDuration);
             // Adjusting for staking impact - if staked, maybe utility doesn't decay or even grows?
             // This adds complexity. Let's keep it simple for now and just base it on transfer time.
            return utility;
        }
    }

    // Internal helper to check if transfer is allowed (not listed, auctioned, staked)
    function _checkTransferAllowed(uint256 tokenId) internal view {
        require(_listings[tokenId].status == ListingStatus.Cancelled || _listings[tokenId].status == ListingStatus.Sold || _listings[tokenId].tokenId == 0, "NFT is listed");
        require(_auctions[tokenId].status == AuctionStatus.Ended || _auctions[tokenId].status == AuctionStatus.Cancelled || _auctions[tokenId].tokenId == 0, "NFT is in auction");
        require(_stakedNFTs[tokenId].tokenId == 0, "NFT is staked");
    }

    // --- Marketplace Functions ---

    /**
     * @notice Lists an NFT for sale at a fixed price.
     * @param tokenId The ID of the NFT to list.
     * @param price The fixed price in native currency (Ether/Wei).
     * @param expirationTimestamp Optional timestamp for listing expiration (0 for no expiration). Must be in the future if > 0.
     */
    function listItem(uint256 tokenId, uint256 price, uint64 expirationTimestamp) public {
        address owner = ownerOf(tokenId);
        require(owner == _msgSender(), NotOwner());
        require(price > 0, InvalidInput());
        if (expirationTimestamp > 0) {
             require(expirationTimestamp > block.timestamp + marketParams.minListingDuration, InvalidInput()); // Must be min duration in the future
        }

        // Check if token is already listed, in auction, or staked
        _checkTransferAllowed(tokenId);

        // Transfer NFT to the contract
        // Requires seller to have approved the contract
        safeTransferFrom(owner, address(this), tokenId);

        _listings[tokenId] = Listing({
            tokenId: tokenId,
            seller: payable(owner),
            price: uint26(price), // Cast should be safe up to ~67 million ETH
            listingTimestamp: uint64(block.timestamp),
            expirationTimestamp: expirationTimestamp,
            status: ListingStatus.Active
        });

        _sellerListings[owner].push(tokenId);

        emit ItemListed(tokenId, owner, price, expirationTimestamp);
    }

    /**
     * @notice Buys a listed NFT.
     * @param tokenId The ID of the NFT to buy.
     */
    function buyItem(uint256 tokenId) public payable {
        Listing storage listing = _listings[tokenId];
        require(listing.status == ListingStatus.Active, NotListedOrAuctioned());
        require(listing.tokenId == tokenId, TokenDoesNotExist()); // Double check mapping exists

        // Check expiration
        if (listing.expirationTimestamp > 0 && block.timestamp > listing.expirationTimestamp) {
            listing.status = ListingStatus.Expired;
            revert ListingExpired();
        }

        require(msg.value >= listing.price, PriceMismatch());

        uint256 marketFee = listing.price.mul(marketParams.marketFeeBasisPoints).div(10000);
        uint256 sellerPayout = listing.price.sub(marketFee);

        // Transfer funds
        (bool successFee, ) = feeReceiver.call{value: marketFee}("");
        require(successFee, MarketFeeWithdrawFailed()); // Should be payable address

        (bool successPayout, ) = listing.seller.call{value: sellerPayout}("");
        require(successPayout, "Seller payout failed");

        // Transfer NFT from contract to buyer
        // Contract is owner, no approval needed from original seller anymore
        _transfer(address(this), _msgSender(), tokenId);

        listing.status = ListingStatus.Sold;
        // Consider removing from _sellerListings array for gas optimization, but array management is complex.
        // Simpler to just rely on status check.

        // Refund excess Eth if any
        if (msg.value > listing.price) {
            (bool successRefund, ) = payable(_msgSender()).call{value: msg.value.sub(listing.price)}("");
            require(successRefund, "Refund failed"); // Should not revert buyer transaction for failed refund? Maybe log?
        }

        emit ItemBought(tokenId, _msgSender(), listing.price);
    }

    /**
     * @notice Cancels an active listing. Only the seller can cancel.
     * @param tokenId The ID of the NFT listing to cancel.
     */
    function cancelListing(uint256 tokenId) public {
        Listing storage listing = _listings[tokenId];
        require(listing.status == ListingStatus.Active, NotListedOrAuctioned());
        require(listing.tokenId == tokenId, TokenDoesNotExist());
        require(listing.seller == _msgSender(), NotOwner());

        listing.status = ListingStatus.Cancelled;

        // Transfer NFT back to seller
        _transfer(address(this), listing.seller, tokenId);

        emit ListingCancelled(tokenId);
    }

     /**
     * @notice Lists an NFT for auction.
     * @param tokenId The ID of the NFT to auction.
     * @param minBid The minimum starting bid.
     * @param startTimestamp The time the auction starts.
     * @param endTimestamp The time the auction ends.
     */
    function listAuction(uint256 tokenId, uint256 minBid, uint64 startTimestamp, uint64 endTimestamp) public {
        address owner = ownerOf(tokenId);
        require(owner == _msgSender(), NotOwner());
        require(minBid > 0, InvalidInput());
        require(startTimestamp >= block.timestamp, "Auction start must be in the future");
        require(endTimestamp > startTimestamp, "Auction end must be after start");
        require(endTimestamp >= startTimestamp + marketParams.minAuctionDuration, "Auction duration too short");
        require(endTimestamp <= startTimestamp + marketParams.maxAuctionDuration, "Auction duration too long");

        // Check if token is already listed, in auction, or staked
        _checkTransferAllowed(tokenId);

        // Transfer NFT to the contract
        safeTransferFrom(owner, address(this), tokenId);

        _auctions[tokenId] = Auction({
            tokenId: tokenId,
            seller: payable(owner),
            minBid: minBid,
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp,
            highestBidder: address(0),
            highestBid: 0,
            bids: new mapping(address => uint256), // Initialize inner mapping
            status: AuctionStatus.Active
        });

        emit AuctionStarted(tokenId, owner, minBid, startTimestamp, endTimestamp);
    }

     /**
     * @notice Places a bid on an active auction.
     * @param tokenId The ID of the NFT in auction.
     */
    function placeBid(uint256 tokenId) public payable {
        Auction storage auction = _auctions[tokenId];
        require(auction.status == AuctionStatus.Active, NotListedOrAuctioned());
        require(auction.tokenId == tokenId, TokenDoesNotExist());

        require(block.timestamp >= auction.startTimestamp, AuctionNotStarted());
        require(block.timestamp < auction.endTimestamp, AuctionEnded());

        require(_msgSender() != auction.seller, CannotBidOnOwnAuction());

        uint256 currentHighestBid = auction.highestBid;
        uint256 minimumNextBid = (currentHighestBid == 0) ? auction.minBid : currentHighestBid.add(currentHighestBid.div(100).add(1)); // Example: 1% increment + 1 Wei
        require(msg.value >= minimumNextBid, BidTooLow());

        // Refund previous highest bidder
        if (auction.highestBidder != address(0)) {
            (bool success, ) = payable(auction.highestBidder).call{value: auction.highestBid}("");
            require(success, "Previous bidder refund failed"); // Potentially problematic if refund fails
            emit BidWithdrawn(tokenId, auction.highestBidder, auction.highestBid);
        }

        auction.bids[_msgSender()] = msg.value; // Store bid amount for potential future refunds
        auction.highestBidder = _msgSender();
        auction.highestBid = msg.value;

        emit BidPlaced(tokenId, _msgSender(), msg.value);
    }

     /**
     * @notice Closes an auction after its end time. Can be called by anyone.
     * @param tokenId The ID of the NFT in auction.
     */
    function closeAuction(uint256 tokenId) public {
        Auction storage auction = _auctions[tokenId];
        require(auction.status == AuctionStatus.Active, NotListedOrAuctioned());
        require(auction.tokenId == tokenId, TokenDoesNotExist());
        require(block.timestamp >= auction.endTimestamp, AuctionStillActive());

        auction.status = AuctionStatus.Ended;

        address winner = auction.highestBidder;
        uint26 finalPrice = uint26(auction.highestBid); // Cast should be safe

        if (winner == address(0)) {
            // No bids, return NFT to seller
            _transfer(address(this), auction.seller, tokenId);
            emit AuctionClosed(tokenId, address(0), 0);
        } else {
            // Transfer NFT to winner
            _transfer(address(this), winner, tokenId);

            // Payout seller (fee deducted)
            uint256 marketFee = finalPrice.mul(marketParams.marketFeeBasisPoints).div(10000);
            uint256 sellerPayout = finalPrice.sub(marketFee);

            (bool successFee, ) = feeReceiver.call{value: marketFee}("");
            require(successFee, MarketFeeWithdrawFailed()); // Should be payable address

            (bool successPayout, ) = auction.seller.call{value: sellerPayout}("");
            require(successPayout, "Seller payout failed");

            emit AuctionClosed(tokenId, winner, finalPrice);
        }

        // Note: Unsuccessful bids were refunded immediately in placeBid.
    }

     /**
     * @notice Makes a direct offer on an NFT. Requires sending Ether.
     * @param tokenId The ID of the NFT.
     * @param offerAmount The amount of the offer in native currency (Ether/Wei).
     * @param expirationTimestamp Optional timestamp for offer expiration (0 for no expiration). Must be in the future if > 0.
     */
    function makeOffer(uint256 tokenId, uint256 offerAmount, uint64 expirationTimestamp) public payable {
        require(_exists(tokenId), TokenDoesNotExist());
        require(offerAmount > 0, InvalidInput());
        require(msg.value == offerAmount, PriceMismatch());
        if (expirationTimestamp > 0) {
            require(expirationTimestamp > block.timestamp + marketParams.minOfferDuration, InvalidInput()); // Must be min duration in the future
        }

        address currentOwner = ownerOf(tokenId);
        require(currentOwner != address(0), TokenDoesNotExist()); // Should be covered by _exists
        require(currentOwner != _msgSender(), "Cannot make offer on your own NFT");

        // Check if offer from this address already exists and is active
        Offer storage existingOffer = _offers[tokenId][_msgSender()];
        require(existingOffer.status != OfferStatus.Active && existingOffer.status != OfferStatus.Pending, OfferAlreadyExists()); // Ensure it's not active

        _offers[tokenId][_msgSender()] = Offer({
            amount: offerAmount,
            offerer: payable(_msgSender()),
            offerTimestamp: uint64(block.timestamp),
            expirationTimestamp: expirationTimestamp,
            status: OfferStatus.Active
        });

        emit OfferMade(tokenId, _msgSender(), offerAmount, expirationTimestamp);
    }

     /**
     * @notice Seller accepts a direct offer on their NFT.
     * @param tokenId The ID of the NFT.
     * @param offerer The address of the offerer.
     */
    function acceptOffer(uint256 tokenId, address offerer) public {
        require(_exists(tokenId), TokenDoesNotExist());
        require(ownerOf(tokenId) == _msgSender(), NotOwner());

        Offer storage offer = _offers[tokenId][offerer];
        require(offer.status == OfferStatus.Active, OfferDoesNotExist());
        require(offer.offerer == offerer, OfferDoesNotExist()); // Double check mapping exists

        // Check expiration
        if (offer.expirationTimestamp > 0 && block.timestamp > offer.expirationTimestamp) {
            offer.status = OfferStatus.Expired;
            revert OfferExpired();
        }

        require(offerer != _msgSender(), CannotAcceptOwnOffer());

        uint256 marketFee = offer.amount.mul(marketParams.marketFeeBasisPoints).div(10000);
        uint256 sellerPayout = offer.amount.sub(marketFee);

        // Transfer funds from contract (where they were held when offer was made)
        (bool successFee, ) = feeReceiver.call{value: marketFee}("");
        require(successFee, MarketFeeWithdrawFailed());

        (bool successPayout, ) = payable(_msgSender()).call{value: sellerPayout}(""); // Pay seller (msg.sender)
        require(successPayout, "Seller payout failed");

        // Transfer NFT from seller to buyer (offerer)
        // Requires seller to have approved the contract to move the NFT
        // Or, the seller could own the contract (in a specific architecture), but general marketplaces require approval.
        // Assuming standard ERC721 flow: Seller must have approved *this contract* via setApprovalForAll or approve.
        require(_isApprovedOrOwner(address(this), tokenId), "Marketplace not approved to transfer NFT"); // Check approval *of the market contract*

        _transfer(_msgSender(), offerer, tokenId);

        offer.status = OfferStatus.Accepted;

        emit OfferAccepted(tokenId, offerer, offer.amount);

        // Any other active offers for this NFT would implicitly become invalid as owner changed.
        // We could add a mechanism to cancel them explicitly or let them expire. Implicit expiry is gas cheaper.
    }


     /**
     * @notice Cancels a direct offer you made.
     * @param tokenId The ID of the NFT.
     */
    function cancelOffer(uint256 tokenId) public {
        Offer storage offer = _offers[tokenId][_msgSender()];
        require(offer.status == OfferStatus.Active, OfferDoesNotExist());
        require(offer.offerer == _msgSender(), OfferDoesNotExist()); // Double check mapping exists

        offer.status = OfferStatus.Cancelled;

        // Refund the offer amount held by the contract
        (bool successRefund, ) = payable(_msgSender()).call{value: offer.amount}("");
        require(successRefund, "Offer refund failed");

        emit OfferCancelled(tokenId, _msgSender());
    }


    // --- Staking Functions ---

    /**
     * @notice Stakes a Temporal NFT to earn governance tokens.
     * @param tokenId The ID of the NFT to stake.
     */
    function stakeNFT(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(owner == _msgSender(), NotOwner());

        // Check if token is already listed, in auction, or staked
        _checkTransferAllowed(tokenId);

        // Check if already staked (should be covered by _checkTransferAllowed, but safety)
        require(_stakedNFTs[tokenId].tokenId == 0, StakingAlreadyExists());


        // Transfer NFT to the contract
        safeTransferFrom(owner, address(this), tokenId);

        _stakedNFTs[tokenId] = StakingPosition({
            tokenId: tokenId,
            staker: _msgSender(),
            stakeTimestamp: uint64(block.timestamp),
            accumulatedRewards: 0
        });

        _stakerStakedNFTs[_msgSender()].push(tokenId);

        emit NFTStaked(tokenId, _msgSender(), uint64(block.timestamp));
    }

    /**
     * @notice Unstakes a Temporal NFT. Calculates and adds pending rewards to accumulated rewards.
     * @param tokenId The ID of the NFT to unstake.
     */
    function unstakeNFT(uint256 tokenId) public {
        StakingPosition storage position = _stakedNFTs[tokenId];
        require(position.tokenId == tokenId, TokenNotStaked());
        require(position.staker == _msgSender(), NotStaked());

        // Calculate pending rewards before unstaking
        uint256 pendingRewards = getAccumulatedRewards(tokenId);
        position.accumulatedRewards = position.accumulatedRewards.add(pendingRewards);
        // Reset stake timestamp as it's now unstaked
        position.stakeTimestamp = 0;

        // Transfer NFT back to staker
        _transfer(address(this), _msgSender(), tokenId);

        // Remove from staker's list (basic implementation, efficient removal is complex)
        uint256[] storage stakerNFTs = _stakerStakedNFTs[_msgSender()];
        for (uint i = 0; i < stakerNFTs.length; i++) {
            if (stakerNFTs[i] == tokenId) {
                stakerNFTs[i] = stakerNFTs[stakerNFTs.length - 1];
                stakerNFTs.pop();
                break;
            }
        }

        // Clear the staking position entry
        delete _stakedNFTs[tokenId]; // Does this work with inner structs/mappings? No, need to zero out

        // Manually zero out struct fields if deleting doesn't fully clear mappings within structs
         position.tokenId = 0;
         position.staker = address(0);
         position.accumulatedRewards = 0;


        emit NFTUnstaked(tokenId, _msgSender(), uint64(block.timestamp));

        // Rewards must be claimed separately via claimStakingRewards
    }

    /**
     * @notice Claims accumulated governance token rewards for specified staked (or previously staked) NFTs.
     * @param tokenIds An array of token IDs for which to claim rewards.
     */
    function claimStakingRewards(uint256[] calldata tokenIds) public {
        uint256 totalRewards = 0;

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            StakingPosition storage position = _stakedNFTs[tokenId];

            // Check if the caller is the staker (or original staker if position was deleted)
            // If position.tokenId is 0, it means it was unstaked, but we still need to track rewards
            // This requires a different storage approach if rewards persist *after* unstaking.
            // Let's refine: accumulatedRewards tracks rewards *while staked*. getAccumulatedRewards calculates *pending* rewards *while staked*.
            // Upon unstaking, pending are added to accumulated. Claim drains accumulated.
            // So, we need a mapping for `address => uint256 totalClaimableRewards` separate from positions.
            // Let's simplify for this example: Rewards are only claimable *while staked*.

            // Require NFT to be currently staked by the caller
             require(position.tokenId == tokenId && position.staker == _msgSender(), "Not staked by caller");

            // Calculate pending rewards since last calculation or stake time
            uint256 pending = getAccumulatedRewards(tokenId);

            totalRewards = totalRewards.add(position.accumulatedRewards).add(pending);

            // Reset accumulated rewards and update stake timestamp for next calculation cycle
            // If claiming resets accrual, uncomment: position.stakeTimestamp = uint64(block.timestamp);
            // If claiming doesn't reset accrual until unstake, remove above line. Let's not reset.
            position.accumulatedRewards = 0; // Clear accumulated rewards after calculating total

        }

         require(totalRewards > 0, NoRewardsToClaim());

        // Transfer governance tokens
        bool success = governanceToken.transfer(_msgSender(), totalRewards);
        require(success, ERC20TransferFailed());

        emit StakingRewardsClaimed(_msgSender(), tokenIds, totalRewards);
    }

     /**
     * @notice Calculates the pending staking rewards for a specific currently staked NFT.
     * @param tokenId The ID of the staked NFT.
     * @return The amount of pending governance tokens.
     */
    function getAccumulatedRewards(uint256 tokenId) public view returns (uint256) {
        StakingPosition storage position = _stakedNFTs[tokenId];
        if (position.tokenId == 0 || position.staker == address(0)) {
             // Not staked
            return 0;
        }

        uint64 stakeTimestamp = position.stakeTimestamp;
        uint66 currentTime = uint66(block.timestamp);

        // Time elapsed in seconds
        uint66 timeElapsed = currentTime - stakeTimestamp;

        // Calculate based on APY (Annual Percentage Yield)
        // APY in basis points: e.g., 500 for 5% -> 500/10000 = 0.05
        // Assuming reward accrues linearly based on time and NFT's 'potential' or a fixed rate per NFT.
        // Let's use a fixed rate per NFT based on the contract's APY setting.
        // Rewards = StakedAmount * (APY / 10000) * (TimeElapsed / SecondsPerYear)
        // StakedAmount is the value of the NFT. We don't have a simple value.
        // Let's use a fixed amount per NFT per second based on APY.
        // APY (bp) per second = (APY / 10000) / (365 * 24 * 60 * 60)
        // Seconds per year = 31536000 (approx)
        // Rewards per second per NFT = 1 token * (APY_bp / 10000) / 31536000
        // To simplify, let's say the APY applies to a base value of 1 Ether or 1 token equivalent.
        // Or, even simpler: total reward tokens minted per year per NFT = initialPotential * (APY_bp / 10000)
        // Daily rewards = initialPotential * (APY_bp / 10000) / 365
        // Seconds per day = 86400
        // Rewards per second = initialPotential * (APY_bp / 10000) / 31536000

        // Let's use the NFT's initial potential as a factor for calculating yield.
        TemporalNFTData memory nftData = _temporalNFTs[tokenId];
        uint256 initialPotential = nftData.initialPotential;

        // Handle potential = 0
        if (initialPotential == 0) {
            return position.accumulatedRewards; // Return only previously accumulated
        }

        // Calculate rewards per second for this NFT
        // Simplified: Rewards per second = initialPotential * (APY_bp / 10000) / (Seconds per Year)
        // Using 1e18 for base unit to avoid small fractions
        uint256 rewardsPerSecond = initialPotential.mul(marketParams.stakingAPYBasisPoints).div(10000).div(31536000);

        uint256 pendingRewards = rewardsPerSecond.mul(timeElapsed);

        return position.accumulatedRewards.add(pendingRewards);
    }


    // --- Governance Functions ---

    /**
     * @notice Proposes changing a specific market parameter. Requires holding Governance Tokens (optional check).
     * @dev Simple proposal system. Needs improvements for real DAO (e.g., proposal threshold, voting power based on token balance).
     * @param paramIndex The index of the parameter to change (use constants).
     * @param newValue The new value for the parameter.
     * @param description A description of the proposal.
     */
    function proposeParameterChange(uint256 paramIndex, uint256 newValue, string memory description) public {
         // require(governanceToken.balanceOf(_msgSender()) >= PROPOSAL_THRESHOLD, "Insufficient governance tokens to propose"); // Add threshold logic
        require(paramIndex <= PARAM_GOVERNANCE_QUORUM, InvalidProposalParamIndex());

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        _proposals[proposalId] = GovernanceProposal({
            id: proposalId,
            proposer: _msgSender(),
            creationTimestamp: uint64(block.timestamp),
            votingPeriodEnd: uint64(block.timestamp) + marketParams.governanceVotingPeriod,
            paramIndex: paramIndex,
            newValue: newValue,
            description: description,
            totalVotes: 0,
            supportVotes: 0,
            hasVoted: new mapping(address => bool),
            state: ProposalState.Active
        });

        emit ParameterChangeProposed(proposalId, _msgSender(), paramIndex, newValue, description);
    }

    /**
     * @notice Casts a vote on an active proposal. Requires holding Governance Tokens (optional check).
     * @dev Voting power is 1 token = 1 vote for simplicity. Snapshot voting needed for real DAO.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for yes, false for no.
     */
    function voteOnProposal(uint256 proposalId, bool support) public {
        GovernanceProposal storage proposal = _proposals[proposalId];
        require(proposal.state == ProposalState.Active, GovernanceProposalNotActive());
        require(block.timestamp <= proposal.votingPeriodEnd, GovernanceProposalExpired());
        require(!proposal.hasVoted[_msgSender()], GovernanceProposalAlreadyVoted());

        // Simple voting power: 1 person, 1 vote. For token-based, use governanceToken.balanceOf(_msgSender())
        // uint256 votingPower = governanceToken.balanceOf(_msgSender());
        // require(votingPower > 0, "No voting power"); // For token-based voting

        uint256 votingPower = 1; // Simple: 1 address, 1 vote

        proposal.hasVoted[_msgSender()] = true;
        proposal.totalVotes = proposal.totalVotes.add(votingPower);
        if (support) {
            proposal.supportVotes = proposal.supportVotes.add(votingPower);
        }

        emit Voted(proposalId, _msgSender(), support);
    }

    /**
     * @notice Executes a proposal that has succeeded after the voting period ends.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public {
        GovernanceProposal storage proposal = _proposals[proposalId];
        require(proposal.state == ProposalState.Active, GovernanceProposalNotActive());
        require(block.timestamp > proposal.votingPeriodEnd, GovernanceProposalNotExecutableYet());

        // Check if quorum is met and votes are sufficient
        uint256 totalPossibleVotes = proposal.totalVotes; // In a real DAO, this would be total supply at snapshot
        // Simplified Quorum check: requires a certain percentage of votes *cast*
        // Real Quorum: requires a certain percentage of total supply *to have voted*
        uint26 quorumThreshold = marketParams.governanceQuorumBasisPoints; // Use uint26 for storage opt? No, uint256 is safer.
        uint256 requiredVotesForQuorum = totalPossibleVotes.mul(quorumThreshold).div(10000);

        // Simple majority: > 50% of votes cast
        bool succeeded = proposal.supportVotes.mul(10000).div(totalPossibleVotes) > 5000; // Support > 50% of total votes cast

        // Combine quorum and majority
        // bool succeeded = proposal.totalVotes >= requiredVotesForQuorum && proposal.supportVotes > proposal.totalVotes.sub(proposal.supportVotes); // Example: quorum AND simple majority
        // A common DAO model: quorum AND majority of *total voting power* OR majority of *votes cast* if quorum met.
        // Let's use the simple majority of votes *cast* + a check that at least *some* votes were cast relative to a hypothetical total.
        // Simpler logic: Majority of votes cast IF total votes cast meets a threshold relative to a hypothetical total supply (e.g., of the governance token).
        // This simple contract doesn't know the total supply of the ERC20 unless it's passed in.
        // Let's assume the quorumBasisPoints applies to the *total votes cast* for simplicity in this example contract structure.
         bool quorumMet = proposal.totalVotes.mul(10000).div(totalPossibleVotes > 0 ? totalPossibleVotes : 1) >= quorumThreshold; // % of votes cast

        if (succeeded && quorumMet) {
            proposal.state = ProposalState.Succeeded;
            // Apply the parameter change
            uint256 paramIndex = proposal.paramIndex;
            uint224 newValue = uint224(proposal.newValue); // Cast to appropriate size

            if (paramIndex == PARAM_MARKET_FEE) marketParams.marketFeeBasisPoints = uint16(newValue);
            else if (paramIndex == PARAM_MIN_LISTING_DURATION) marketParams.minListingDuration = uint64(newValue);
            else if (paramIndex == PARAM_MIN_AUCTION_DURATION) marketParams.minAuctionDuration = uint64(newValue);
            else if (paramIndex == PARAM_MAX_AUCTION_DURATION) marketParams.maxAuctionDuration = uint64(newValue);
            else if (paramIndex == PARAM_MIN_OFFER_DURATION) marketParams.minOfferDuration = uint64(newValue);
            else if (paramIndex == PARAM_MAX_OFFER_DURATION) marketParams.maxOfferDuration = uint64(newValue);
            else if (paramIndex == PARAM_STAKING_APY) marketParams.stakingAPYBasisPoints = uint64(newValue);
            else if (paramIndex == PARAM_GOVERNANCE_VOTING_PERIOD) marketParams.governanceVotingPeriod = uint64(newValue);
            else if (paramIndex == PARAM_GOVERNANCE_QUORUM) marketParams.governanceQuorumBasisPoints = uint256(newValue); // Quorum is uint256

            proposal.state = ProposalState.Executed;
            emit ProposalExecuted(proposalId, paramIndex, proposal.newValue);

        } else {
            proposal.state = ProposalState.Failed;
        }
    }

    /**
     * @notice Gets the current state of a governance proposal.
     * @param proposalId The ID of the proposal.
     * @return The state of the proposal.
     */
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        require(_proposals[proposalId].id == proposalId, GovernanceProposalNotFound()); // Check existence
        return _proposals[proposalId].state;
    }


    // --- Admin/Utility Functions ---

    /**
     * @notice Sets the address that receives market fees.
     * @param _feeReceiver The new fee receiver address.
     */
    function setFeeReceiver(address payable _feeReceiver) public onlyOwner {
        require(_feeReceiver != address(0), InvalidInput());
        address oldReceiver = feeReceiver;
        feeReceiver = _feeReceiver;
        emit FeeReceiverUpdated(oldReceiver, _feeReceiver);
    }

    /**
     * @notice Allows the fee receiver to withdraw collected market fees.
     */
    function withdrawMarketFees() public {
        require(_msgSender() == feeReceiver, "Not fee receiver");
        uint256 amount = totalMarketFeesCollected;
        require(amount > 0, NoRewardsToClaim()); // Use NoRewardsToClaim error for lack of funds

        totalMarketFeesCollected = 0; // Reset balance before transfer

        (bool success, ) = feeReceiver.call{value: amount}("");
        require(success, MarketFeeWithdrawFailed()); // Revert if transfer fails

        emit MarketFeesWithdrawn(feeReceiver, amount);
    }

    /**
     * @notice Returns the current market parameters.
     */
    function getMarketParams() public view returns (MarketParams memory) {
        return marketParams;
    }

    /**
     * @notice Gets details of the active listing for a token ID.
     * @param tokenId The ID of the NFT.
     * @return Listing details struct. Returns default struct if no active listing.
     */
    function getCurrentListing(uint256 tokenId) public view returns (Listing memory) {
        Listing storage listing = _listings[tokenId];
        // Return default struct if not active or doesn't exist
        if (listing.status != ListingStatus.Active || listing.tokenId != tokenId) {
             return Listing({
                tokenId: 0, seller: payable(address(0)), price: 0,
                listingTimestamp: 0, expirationTimestamp: 0, status: ListingStatus.Cancelled
            });
        }
        return listing;
    }

    /**
     * @notice Gets details of the active auction for a token ID.
     * @param tokenId The ID of the NFT.
     * @return Auction details struct. Returns default struct if no active auction.
     */
    function getCurrentAuction(uint256 tokenId) public view returns (Auction memory) {
        Auction storage auction = _auctions[tokenId];
         // Return default struct if not active or doesn't exist
        if (auction.status != AuctionStatus.Active || auction.tokenId != tokenId) {
             return Auction({
                 tokenId: 0, seller: payable(address(0)), minBid: 0,
                 startTimestamp: 0, endTimestamp: 0, highestBidder: address(0),
                 highestBid: 0, bids: new mapping(address => uint256), // Note: Mapping will be empty
                 status: AuctionStatus.Ended
             });
        }
        return auction;
    }

    /**
     * @notice Gets details of a specific offer on a token ID.
     * @param tokenId The ID of the NFT.
     * @param offerer The address of the offerer.
     * @return Offer details struct. Returns default struct if no active offer from this offerer.
     */
    function getOffer(uint256 tokenId, address offerer) public view returns (Offer memory) {
        Offer storage offer = _offers[tokenId][offerer];
        // Return default struct if not active or doesn't exist
        if (offer.status != OfferStatus.Active || offer.offerer != offerer) {
             return Offer({
                amount: 0, offerer: payable(address(0)), offerTimestamp: 0,
                expirationTimestamp: 0, status: OfferStatus.Cancelled
            });
        }
        return offer;
    }

     /**
     * @notice Gets details of the staking position for a token ID.
     * @param tokenId The ID of the NFT.
     * @return Staking position details struct. Returns default struct if not staked.
     */
    function getStakingPosition(uint256 tokenId) public view returns (StakingPosition memory) {
         StakingPosition storage position = _stakedNFTs[tokenId];
         // Return default struct if not staked
         if (position.tokenId != tokenId || position.staker == address(0)) {
              return StakingPosition({
                 tokenId: 0, staker: address(0), stakeTimestamp: 0, accumulatedRewards: 0
             });
         }
         return position;
    }

    // Fallback function to receive Ether for bids/offers
    receive() external payable {}
    fallback() external payable {}
}
```

---

**Explanation of Advanced/Creative/Trendy Concepts Used:**

1.  **Dynamic/Temporal NFTs (TNTs):** The `TemporalNFTData` struct and the `calculateCurrentUtility` function introduce the dynamic aspect. The utility is not static metadata but a value calculated on the fly based on time elapsed since the last transfer. This could represent decaying benefits, accumulating loyalty bonuses, or other time-dependent properties not typically found in standard NFTs. (Function 11, 12, 13).
2.  **Time-Sensitive Marketplace:** Listings (`listItem`, `buyItem`, `cancelListing`) and Offers (`makeOffer`, `acceptOffer`, `cancelOffer`) can have `expirationTimestamp`. Auctions (`listAuction`, `placeBid`, `closeAuction`) are inherently time-bound. The contract enforces these time constraints (`ListingExpired`, `AuctionNotStarted`, `AuctionEnded`, `OfferExpired`). (Functions 14-22).
3.  **NFT Staking for Yield:** Users can lock their TNTs in the contract (`stakeNFT`) to earn a yield in a separate ERC20 governance token (`claimStakingRewards`). The yield calculation (`getAccumulatedRewards`) is time-based, linking the duration of staking to the rewards received. This is a popular DeFi mechanism applied to NFTs. (Functions 23-26).
4.  **Basic On-Chain Governance:** The contract parameters (`marketParams`) are not fixed by the owner after deployment (except initially). A simple governance system (`proposeParameterChange`, `voteOnProposal`, `executeProposal`, `getProposalState`) allows holders (conceptually, or simply addresses in this minimal implementation) to propose and vote on changes like market fees, auction durations, or staking APY. This moves towards a more decentralized model. (Functions 27-30).
5.  **Integrated System:** Instead of separate contracts for NFT, Marketplace, Staking, and Governance, this contract attempts to combine core logic for all related features, making interactions potentially more atomic and enforcing internal state consistency (e.g., an NFT cannot be listed *and* staked simultaneously enforced by `_checkTransferAllowed`).
6.  **Gas Efficiency Considerations (Partial):** Using `uint64` for timestamps where appropriate, and `uint26` for Ether amounts (though safer with `uint256` for larger values), and packing structs where possible are minor optimizations. Using custom errors saves gas compared to `require` with strings in newer Solidity versions.
7.  **Standard Interface Usage:** Correctly uses `IERC721Receiver` for secure NFT deposits and `IERC20` for interacting with the governance token. Inherits from OpenZeppelin's `ERC721`, `Ownable`, `Context`, `Counters`, `Strings`, `SafeMath` (though SafeMath is often not needed in 0.8+ with checked arithmetic, explicitly using it for clarity/safety in divisions/multiplications is okay).

This contract provides a rich set of interconnected functionalities centered around time-aware digital assets and their ecosystem, fulfilling the requirements for creativity, advanced concepts, and a high function count without directly copying a single existing large open-source project blueprint.

Remember that for production use, this contract would need significant auditing, more robust error handling, potential gas optimizations, and a more sophisticated governance module (e.g., handling voting power based on token balance snapshots, more complex proposal types, timelocks).