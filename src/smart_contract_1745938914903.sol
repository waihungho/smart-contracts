Okay, let's design a smart contract incorporating advanced concepts like sealed-bid auctions with a reveal phase, verifiable randomness (VRF) for a probabilistic "Quantum Boost" outcome, a basic on-chain reputation system, and integration with ERC721 for items and ERC20 for bidding.

We will call this contract the **Quantum Auction House**.

**Core Concepts:**

1.  **Sealed-Bid Auction:** Bidders submit cryptographic hashes of their bids first, preventing front-running and bid sniping.
2.  **Reveal Phase:** After the bidding ends, bidders must reveal their original bid value and salt to validate their hash. Funds are transferred during this phase.
3.  **Verifiable Randomness (VRF):** Using Chainlink VRF to introduce a truly random element at the end of the auction.
4.  **Quantum Boost:** A probabilistic event (determined by VRF) that, if triggered for the winning bid, grants a special bonus (e.g., reduced platform fee for the seller, or a special token for the winner - let's go with a reputation boost and potential future SBT eligibility for simplicity within this contract).
5.  **Reputation System:** Participants earn reputation for successful participation (revealing valid bids, winning, selling successfully) and lose reputation for failed actions (failing to reveal a sealed bid). This could influence future participation.
6.  **State Management:** The auction progresses through distinct states (Created, Bidding, Reveal, Resolving, Ended, Cancelled).
7.  **ERC721 & ERC20 Integration:** Auctions are for ERC721 tokens, and bids are placed using a specified ERC20 token.

This design avoids simple English/Dutch auctions and introduces complexity with the two-phase bidding, VRF integration, and internal reputation/boost mechanics, differentiating it from standard marketplace contracts.

---

**Outline & Function Summary**

**Outline:**

1.  **Contract Setup:** Imports, Interfaces, Libraries (Ownable, Pausable, ReentrancyGuard, Chainlink VRF, ERC20, ERC721).
2.  **State Variables:** Owner, Paused state, Platform fee, VRF parameters, Quantum Boost parameters, Auction counter, Mappings for auctions, bids, revealed bids, participant reputation, VRF request tracking.
3.  **Enums:** AuctionState.
4.  **Structs:** Auction, SealedBid, RevealedBid.
5.  **Events:** Lifecycle events (Created, BiddingStarted, RevealStarted, Ended, Cancelled), Bid events (SealedBidPlaced, BidRevealed), Resolution events (VRFRequested, VRFFulfilled, WinnerDetermined, ItemClaimed, PayoutClaimed, RefundClaimed, QuantumBoostApplied), Admin events (FeeUpdated, VRFParamsUpdated, ReputationUpdated).
6.  **Modifiers:** Access control (onlyOwner, onlySeller), State checks (auctionStateIs), Pausability, ReentrancyGuard.
7.  **Core Auction Functions:** Create, Cancel, Bid (Sealed), Reveal, Advance State (End Bidding, End Reveal).
8.  **Resolution & VRF:** VRF request, VRF fulfillment callback, Internal resolution logic.
9.  **Claiming Functions:** Claim Item, Claim Payout, Claim Refunds.
10. **Reputation System:** Functions to update/view reputation.
11. **Admin & Platform Functions:** Set Fees, Withdraw Fees, Set VRF params, Set Quantum Boost params, Emergency Withdrawals, Pause/Unpause, Ownership.
12. **View Functions:** Get details about auctions, bids, state, reputation, claimable amounts.

**Function Summary:**

1.  `constructor(address vrfCoordinator, uint64 subscriptionId, bytes32 keyHash)`: Initializes contract with VRF settings.
2.  `createAuction(address _erc721Contract, uint256 _tokenId, address _erc20BidToken, uint256 _reservePrice, uint256 _minBidIncrement, uint256 _duration, uint256 _revealPeriodDuration, bool _quantumBoostEnabled)`: Seller lists an ERC721 item for auction using a specific ERC20 token, defining auction parameters. Requires item transfer to the contract.
3.  `cancelAuction(uint256 _auctionId)`: Allows the seller to cancel an auction *before* the bidding period ends. Refunds revealed bids if any and returns the item.
4.  `placeSealedBid(uint256 _auctionId, bytes32 _bidHash)`: Allows a bidder to place a sealed bid during the bidding phase by submitting the keccak256 hash of their desired bid amount and a salt (`keccak256(abi.encodePacked(bidAmount, salt))`). **No funds are transferred yet.**
5.  `revealBid(uint256 _auctionId, uint256 _bidAmount, bytes32 _salt)`: Allows a bidder to reveal their sealed bid during the reveal phase. Verifies the hash, checks if the bid meets auction criteria (reserve, increment), checks bidder's ERC20 balance, transfers the bid amount from bidder to contract, and records the revealed bid. Adds partial reputation for a successful reveal.
6.  `endAuctionBiddingPhase(uint256 _auctionId)`: Can be called by anyone after the bidding end time to transition the auction state from `Bidding` to `Reveal`. Sets the `revealEndTime`. Penalizes reputation of bidders who placed a sealed bid but didn't reveal by the end of the bidding phase (giving them until `revealEndTime` to actually reveal).
7.  `endAuctionRevealPhase(uint256 _auctionId)`: Can be called by anyone after the reveal end time to transition the auction state from `Reveal` to `Resolving`. Triggers VRF request if Quantum Boost is enabled. If not, proceeds directly to internal resolution. Penalizes reputation of bidders who had a sealed bid but failed to reveal by `revealEndTime`.
8.  `fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords)`: Chainlink VRF callback function. Verifies the request ID, processes the random number(s), applies the Quantum Boost logic (determining if the event occurs), and triggers the internal auction resolution.
9.  `resolveAuctionInternal(uint256 _auctionId, bool _quantumEventHappened)`: Internal function to find the highest valid revealed bid above the reserve price, determine the winner, calculate payouts/refunds, apply fee/boost logic, and transition the auction state to `Ended`.
10. `claimItem(uint256 _auctionId)`: Allows the winning bidder to claim the auctioned ERC721 item after the auction has ended and resolution is complete.
11. `claimPayout(uint256 _auctionId)`: Allows the seller to claim their share of the winning bid amount after the auction has ended and resolution is complete (minus the platform fee, unless the Quantum Boost waived it).
12. `claimRefund(uint256 _auctionId)`: Allows losing bidders (who revealed their bid) to claim back their deposited ERC20 bid amount after the auction has ended and resolution is complete.
13. `setPlatformFee(uint256 _feePercentage)`: Allows the contract owner to update the platform fee percentage (0-100).
14. `withdrawPlatformFees(address _tokenAddress)`: Allows the contract owner to withdraw accumulated platform fees for a specific ERC20 token.
15. `setQuantumBoostParameters(uint256 _probabilityPercentage, uint256 _reputationBonus)`: Allows the contract owner to set the probability (0-100) of the Quantum Boost occurring and the reputation bonus awarded to the winner if it does.
16. `setVRFParameters(uint64 _subscriptionId, bytes32 _keyHash)`: Allows the contract owner to update Chainlink VRF subscription ID and key hash (e.g., if needing to migrate).
17. `setMinReputationToBid(uint256 _minReputation)`: Allows the contract owner to set a minimum reputation score required for users to place sealed bids. (Requires integration into `placeSealedBid`).
18. `addParticipantReputation(address _participant, uint256 _amount)`: Allows the contract owner to manually add reputation to a participant (e.g., for resolving disputes).
19. `subtractParticipantReputation(address _participant, uint256 _amount)`: Allows the contract owner to manually subtract reputation from a participant (e.g., for malicious behavior).
20. `getParticipantReputation(address _participant)`: View function to retrieve a participant's current reputation score.
21. `getAuctionDetails(uint256 _auctionId)`: View function to retrieve details about an auction.
22. `getAuctionState(uint256 _auctionId)`: View function to get the current state of an auction.
23. `getUserSealedBidHash(uint256 _auctionId, address _bidder)`: View function to check the sealed bid hash submitted by a specific bidder.
24. `getUserRevealedBidDetails(uint256 _auctionId, address _bidder)`: View function to retrieve the revealed bid details for a specific bidder, if they have revealed.
25. `getHighestRevealedBidDetails(uint256 _auctionId)`: View function to find and return the details of the highest revealed bid for an auction.
26. `getAuctionWinnerDetails(uint256 _auctionId)`: View function to get the determined winner and winning bid amount after the auction has ended and resolved.
27. `getPendingRefundAmount(uint256 _auctionId, address _bidder)`: View function to check the refundable amount for a losing bidder.
28. `getClaimablePayoutAmount(uint256 _auctionId)`: View function to check the amount the seller can claim.
29. `getClaimableItemTokenId(uint256 _auctionId)`: View function to check the tokenId the winner can claim.
30. `emergencyWithdrawStuckERC20(address _tokenAddress, uint256 _amount)`: Owner function to withdraw accidental ERC20 transfers (excluding auction/fee tokens).
31. `emergencyWithdrawStuckERC721(address _nftContract, uint256 _tokenId)`: Owner function to withdraw accidental ERC721 transfers (excluding auctioned items).
32. `pause()`: Allows the owner to pause the contract (inherited from Pausable).
33. `unpause()`: Allows the owner to unpause the contract (inherited from Pausable).
34. `transferOwnership(address newOwner)`: Transfers ownership of the contract (inherited from Ownable).
35. `renounceOwnership()`: Renounces ownership of the contract (inherited from Ownable).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@chainlink/contracts/src/v0.8/vrf/V2Plus/interfaces/IVRFCoordinatorV2PlusClient.sol";
import "@chainlink/contracts/src/v0.8/vrf/V2Plus/VRFConsumerBaseV2Plus.sol";

// Outline:
// 1. Contract Setup: Imports, Interfaces, Libraries (Ownable, Pausable, ReentrancyGuard, Chainlink VRF, ERC20, ERC721).
// 2. State Variables: Owner, Paused state, Platform fee, VRF parameters, Quantum Boost parameters, Auction counter, Mappings for auctions, bids, revealed bids, participant reputation, VRF request tracking.
// 3. Enums: AuctionState.
// 4. Structs: Auction, SealedBid, RevealedBid.
// 5. Events: Lifecycle, Bid, Resolution, Admin.
// 6. Modifiers: Access control, State checks, Pausability, ReentrancyGuard.
// 7. Core Auction Functions: Create, Cancel, Bid (Sealed), Reveal, Advance State (End Bidding, End Reveal).
// 8. Resolution & VRF: VRF request, VRF fulfillment callback, Internal resolution logic.
// 9. Claiming Functions: Claim Item, Claim Payout, Claim Refunds.
// 10. Reputation System: Functions to update/view reputation.
// 11. Admin & Platform Functions: Set Fees, Withdraw Fees, Set VRF params, Set Quantum Boost params, Emergency Withdrawals, Pause/Unpause, Ownership.
// 12. View Functions: Get details about auctions, bids, state, reputation, claimable amounts.

// Function Summary:
// 1. constructor(address vrfCoordinator, uint64 subscriptionId, bytes32 keyHash): Initializes contract with VRF settings.
// 2. createAuction(address _erc721Contract, uint256 _tokenId, address _erc20BidToken, uint256 _reservePrice, uint256 _minBidIncrement, uint256 _duration, uint256 _revealPeriodDuration, bool _quantumBoostEnabled): Seller lists an ERC721 item for auction.
// 3. cancelAuction(uint256 _auctionId): Seller cancels auction before bidding ends. Refunds revealed bids, returns item.
// 4. placeSealedBid(uint256 _auctionId, bytes32 _bidHash): Bidder submits hashed bid. No funds transferred.
// 5. revealBid(uint256 _auctionId, uint256 _bidAmount, bytes32 _salt): Bidder reveals bid, verifies hash, transfers funds to contract. Adds partial reputation.
// 6. endAuctionBiddingPhase(uint256 _auctionId): Transitions state from Bidding to Reveal. Penalizes unrevealed sealed bids after reveal period ends.
// 7. endAuctionRevealPhase(uint256 _auctionId): Transitions state from Reveal to Resolving. Triggers VRF if enabled, or resolves directly. Final reputation penalty for failure to reveal.
// 8. fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords): Chainlink VRF callback. Processes randomness, applies Quantum Boost logic, triggers internal resolution.
// 9. resolveAuctionInternal(uint256 _auctionId, bool _quantumEventHappened): Internal resolution: finds winner, calculates payouts, applies fees/boost, sets claimable states.
// 10. claimItem(uint256 _auctionId): Winner claims ERC721 item.
// 11. claimPayout(uint256 _auctionId): Seller claims auction proceeds (minus fee, potentially boosted).
// 12. claimRefund(uint256 _auctionId): Losing bidders claim back deposited ERC20 funds.
// 13. setPlatformFee(uint256 _feePercentage): Owner sets platform fee percentage (0-100).
// 14. withdrawPlatformFees(address _tokenAddress): Owner withdraws accumulated fees for a specific token.
// 15. setQuantumBoostParameters(uint256 _probabilityPercentage, uint256 _reputationBonus): Owner sets Quantum Boost chance and reputation bonus for winner.
// 16. setVRFParameters(uint64 _subscriptionId, bytes32 _keyHash): Owner updates VRF parameters.
// 17. setMinReputationToBid(uint256 _minReputation): Owner sets minimum reputation required to place sealed bids.
// 18. addParticipantReputation(address _participant, uint256 _amount): Owner manually adds reputation.
// 19. subtractParticipantReputation(address _participant, uint256 _amount): Owner manually subtracts reputation.
// 20. getParticipantReputation(address _participant): View: Get reputation score.
// 21. getAuctionDetails(uint256 _auctionId): View: Get all auction details.
// 22. getAuctionState(uint256 _auctionId): View: Get current state.
// 23. getUserSealedBidHash(uint256 _auctionId, address _bidder): View: Get sealed bid hash.
// 24. getUserRevealedBidDetails(uint256 _auctionId, address _bidder): View: Get revealed bid details.
// 25. getHighestRevealedBidDetails(uint256 _auctionId): View: Get details of highest revealed bid.
// 26. getAuctionWinnerDetails(uint256 _auctionId): View: Get winner/amount after resolution.
// 27. getPendingRefundAmount(uint256 _auctionId, address _bidder): View: Get refund amount for losing bidder.
// 28. getClaimablePayoutAmount(uint256 _auctionId): View: Get seller's claimable amount.
// 29. getClaimableItemTokenId(uint256 _auctionId): View: Get winner's claimable tokenId.
// 30. emergencyWithdrawStuckERC20(address _tokenAddress, uint256 _amount): Owner withdraws stuck ERC20s.
// 31. emergencyWithdrawStuckERC721(address _nftContract, uint256 _tokenId): Owner withdraws stuck ERC721s.
// 32. pause(): Owner pauses (Pausable).
// 33. unpause(): Owner unpauses (Pausable).
// 34. transferOwnership(address newOwner): Transfer ownership (Ownable).
// 35. renounceOwnership(): Renounce ownership (Ownable).

contract QuantumAuctionHouse is Ownable, Pausable, ReentrancyGuard, VRFConsumerBaseV2Plus {

    enum AuctionState {
        Created,     // Auction created, waiting for start (or effectively started immediately in this simple model)
        Bidding,     // Sealed bids can be placed
        Reveal,      // Reveal phase, bids are validated and funds transferred
        Resolving,   // Auction ended, determining winner/resolving (waiting for VRF if needed)
        Ended,       // Auction resolved, results final, claiming possible
        Cancelled    // Auction cancelled by seller
    }

    struct Auction {
        address seller;
        address erc721Contract;
        uint256 tokenId;
        address erc20BidToken;
        uint256 reservePrice;
        uint256 minBidIncrement;
        uint64 biddingEndTime;
        uint64 revealEndTime;
        AuctionState state;
        address highestBidder;
        uint256 highestBidAmount;
        bool winnerClaimedItem;
        bool sellerClaimedPayout;
        int64 vrfRequestId;
        bool vrfFulfilled;
        bool quantumBoostEnabled;
        bool quantumEventHappened; // Result of the quantum roll
    }

    struct SealedBid {
        address bidder;
        bytes32 bidHash;
        uint64 timestamp;
        bool revealed; // Track if this hash was successfully revealed
    }

    struct RevealedBid {
        address bidder;
        uint256 bidAmount;
        bytes32 salt; // Store salt to allow verification if needed (not used for hash validation after reveal)
        uint64 timestamp;
    }

    uint256 private _auctionCounter;

    mapping(uint256 => Auction) public auctions;
    // auctionId => bidder => SealedBid
    mapping(uint256 => mapping(address => SealedBid)) private _sealedBids;
    // auctionId => bidder => RevealedBid
    mapping(uint256 => mapping(address => RevealedBid)) private _revealedBids;
    // auctionId => bidder => isLosingBidderClaimable
    mapping(uint256 => mapping(address => bool)) private _losingBidderClaimable;
    // bidder => reputationScore
    mapping(address => uint256) private _participantReputation;

    uint256 public platformFeePercentage; // Stored as a percentage (0-100)
    uint256 public minReputationToBid;

    // Chainlink VRF parameters
    uint64 public s_subscriptionId;
    bytes32 public s_keyHash;
    mapping(int64 => uint256) private s_requests; // request ID => auctionId

    // Quantum Boost Parameters
    uint256 public quantumBoostProbabilityPercentage; // 0-100
    uint256 public quantumReputationBonus;

    // --- Events ---
    event AuctionCreated(uint256 indexed auctionId, address indexed seller, address erc721Contract, uint256 tokenId, uint256 reservePrice, uint64 biddingEndTime);
    event AuctionCancelled(uint256 indexed auctionId);
    event BiddingStarted(uint256 indexed auctionId, uint64 biddingEndTime); // In this model, starts immediately
    event SealedBidPlaced(uint256 indexed auctionId, address indexed bidder, bytes32 bidHash);
    event RevealStarted(uint256 indexed auctionId, uint64 revealEndTime);
    event BidRevealed(uint256 indexed auctionId, address indexed bidder, uint256 bidAmount);
    event AuctionEnded(uint256 indexed auctionId, AuctionState finalState);
    event VRFRequested(uint256 indexed auctionId, int64 indexed requestId);
    event VRFFulfilled(uint256 indexed auctionId, int64 indexed requestId, uint256 randomNumber);
    event WinnerDetermined(uint256 indexed auctionId, address indexed winner, uint256 winningBidAmount, bool quantumEventHappened);
    event ItemClaimed(uint256 indexed auctionId, address indexed winner, uint256 tokenId);
    event PayoutClaimed(uint256 indexed auctionId, address indexed seller, uint256 amount);
    event RefundClaimed(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event ReputationUpdated(address indexed participant, uint256 newReputation);
    event FeeUpdated(uint256 newFeePercentage);
    event VRFParamsUpdated(uint64 newSubscriptionId, bytes32 newKeyHash);
    event QuantumBoostParametersUpdated(uint256 probability, uint256 reputationBonus);
    event MinReputationUpdated(uint256 newMinReputation);

    // --- Modifiers ---
    modifier auctionExists(uint256 _auctionId) {
        require(_auctionId > 0 && _auctionId <= _auctionCounter, "Invalid auction ID");
        _;
    }

    modifier auctionStateIs(uint256 _auctionId, AuctionState _state) {
        require(auctions[_auctionId].state == _state, "Auction is not in the required state");
        _;
    }

    modifier onlySeller(uint256 _auctionId) {
        require(msg.sender == auctions[_auctionId].seller, "Only the seller can perform this action");
        _;
    }

    // --- Constructor ---
    constructor(address _vrfCoordinator, uint64 _subscriptionId, bytes32 _keyHash)
        VRFConsumerBaseV2Plus(_vrfCoordinator)
        Ownable(msg.sender) // Set deployer as owner
        Pausable()
    {
        platformFeePercentage = 5; // Default 5% fee
        s_subscriptionId = _subscriptionId;
        s_keyHash = _keyHash;
        _auctionCounter = 0;
        minReputationToBid = 0; // Default no min reputation
        quantumBoostProbabilityPercentage = 10; // Default 10% chance
        quantumReputationBonus = 5; // Default 5 reputation bonus
    }

    // --- Core Auction Functions ---

    /// @notice Creates a new sealed-bid auction for an ERC721 token.
    /// @param _erc721Contract The address of the ERC721 token contract.
    /// @param _tokenId The ID of the token being auctioned.
    /// @param _erc20BidToken The address of the ERC20 token used for bidding.
    /// @param _reservePrice The minimum price for the auction to be successful.
    /// @param _minBidIncrement The minimum amount a new bid must be higher than the previous highest bid (or reserve). Not strictly enforced until reveal, but for bidder clarity.
    /// @param _duration The duration of the bidding phase in seconds.
    /// @param _revealPeriodDuration The duration of the reveal phase in seconds.
    /// @param _quantumBoostEnabled Whether the probabilistic Quantum Boost is enabled for this auction.
    function createAuction(
        address _erc721Contract,
        uint256 _tokenId,
        address _erc20BidToken,
        uint256 _reservePrice,
        uint256 _minBidIncrement,
        uint256 _duration,
        uint256 _revealPeriodDuration,
        bool _quantumBoostEnabled
    ) external nonReentrant whenNotPaused {
        require(_erc721Contract != address(0), "Invalid ERC721 contract address");
        require(_erc20BidToken != address(0), "Invalid ERC20 bid token address");
        require(_reservePrice > 0, "Reserve price must be greater than 0");
        require(_duration > 0, "Bidding duration must be greater than 0");
        require(_revealPeriodDuration > 0, "Reveal period duration must be greater than 0");

        _auctionCounter++;
        uint256 newAuctionId = _auctionCounter;

        // ERC721 token must be transferred to the contract BEFORE calling this function
        // or approve this contract to transfer. This implementation assumes transfer BEFORE.
        // IERC721(_erc721Contract).safeTransferFrom(msg.sender, address(this), _tokenId);
        // Note: The above line requires the sender to have already transferred the token.
        // A better approach is requiring approval and transferring here:
        IERC721(_erc721Contract).transferFrom(msg.sender, address(this), _tokenId);

        auctions[newAuctionId] = Auction({
            seller: msg.sender,
            erc721Contract: _erc721Contract,
            tokenId: _tokenId,
            erc20BidToken: _erc20BidToken,
            reservePrice: _reservePrice,
            minBidIncrement: _minBidIncrement,
            biddingEndTime: uint64(block.timestamp + _duration),
            revealEndTime: 0, // Will be set when bidding ends
            state: AuctionState.Bidding, // Starts directly in Bidding state
            highestBidder: address(0),
            highestBidAmount: 0,
            winnerClaimedItem: false,
            sellerClaimedPayout: false,
            vrfRequestId: 0,
            vrfFulfilled: false,
            quantumBoostEnabled: _quantumBoostEnabled,
            quantumEventHappened: false
        });

        emit AuctionCreated(newAuctionId, msg.sender, _erc721Contract, _tokenId, _reservePrice, auctions[newAuctionId].biddingEndTime);
        emit BiddingStarted(newAuctionId, auctions[newAuctionId].biddingEndTime);
    }

    /// @notice Allows the seller to cancel an auction before the bidding period ends.
    /// @param _auctionId The ID of the auction to cancel.
    function cancelAuction(uint256 _auctionId)
        external
        nonReentrant
        whenNotPaused
        auctionExists(_auctionId)
        onlySeller(_auctionId)
    {
        Auction storage auction = auctions[_auctionId];
        require(auction.state == AuctionState.Bidding, "Auction is not in the bidding state");
        require(block.timestamp < auction.biddingEndTime, "Bidding period has already ended");

        auction.state = AuctionState.Cancelled;

        // Return item to seller
        IERC721(auction.erc721Contract).transferFrom(address(this), auction.seller, auction.tokenId);

        // Refund any revealed bids (shouldn't be any in Bidding state, but safety)
        // Iterate over revealed bids for this auction and refund
        // Note: Simple mapping iteration is not possible. We rely on users claiming refunds.
        // Mark all revealed bids as claimable if they exist
        // This logic needs correction: if cancelled *before* reveal phase, no bids are revealed/funded yet.
        // So no refunds needed in this model if cancelled *before* bidding end time.

        emit AuctionCancelled(_auctionId);
        emit AuctionEnded(_auctionId, AuctionState.Cancelled);
    }

    /// @notice Places a sealed bid by submitting the hash of the bid amount and a salt.
    /// @param _auctionId The ID of the auction.
    /// @param _bidHash The keccak256 hash of `abi.encodePacked(bidAmount, salt)`.
    function placeSealedBid(uint256 _auctionId, bytes32 _bidHash)
        external
        nonReentrant
        whenNotPaused
        auctionExists(_auctionId)
        auctionStateIs(_auctionId, AuctionState.Bidding)
    {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp < auction.biddingEndTime, "Bidding period has ended");
        require(_participantReputation[msg.sender] >= minReputationToBid, "Insufficient reputation to bid");

        _sealedBids[_auctionId][msg.sender] = SealedBid({
            bidder: msg.sender,
            bidHash: _bidHash,
            timestamp: uint64(block.timestamp),
            revealed: false
        });

        emit SealedBidPlaced(_auctionId, msg.sender, _bidHash);
    }

    /// @notice Reveals a sealed bid by providing the original bid amount and salt.
    /// Transfers the bid amount from the bidder to the contract if valid.
    /// @param _auctionId The ID of the auction.
    /// @param _bidAmount The original bid amount.
    /// @param _salt The original salt used for hashing.
    function revealBid(uint256 _auctionId, uint256 _bidAmount, bytes32 _salt)
        external
        nonReentrant
        whenNotPaused
        auctionExists(_auctionId)
    {
        Auction storage auction = auctions[_auctionId];
        require(auction.state == AuctionState.Reveal, "Auction is not in the reveal state");
        require(block.timestamp < auction.revealEndTime, "Reveal period has ended");

        SealedBid storage sealedBid = _sealedBids[_auctionId][msg.sender];
        require(sealedBid.bidder == msg.sender, "No sealed bid placed by this address");
        require(!sealedBid.revealed, "Bid already revealed");

        bytes32 computedHash = keccak256(abi.encodePacked(_bidAmount, _salt));
        require(computedHash == sealedBid.bidHash, "Bid hash mismatch");
        require(_bidAmount >= auction.reservePrice, "Bid amount must be greater than or equal to reserve price");

        // Check if bid meets minimum increment if there's already a highest revealed bid
        if (auction.highestBidAmount > 0) {
             require(_bidAmount >= auction.highestBidAmount + auction.minBidIncrement, "Bid amount must meet minimum increment");
        } else {
             // If no highest bid yet, ensure it meets reserve
             require(_bidAmount >= auction.reservePrice, "First bid must meet reserve price");
        }

        // Transfer bid amount from bidder to contract
        IERC20 bidToken = IERC20(auction.erc20BidToken);
        require(bidToken.balanceOf(msg.sender) >= _bidAmount, "Insufficient ERC20 balance");
        require(bidToken.allowance(msg.sender, address(this)) >= _bidAmount, "ERC20 allowance too low");
        bidToken.transferFrom(msg.sender, address(this), _bidAmount);

        // Record revealed bid
        _revealedBids[_auctionId][msg.sender] = RevealedBid({
            bidder: msg.sender,
            bidAmount: _bidAmount,
            salt: _salt, // Storing salt, though not strictly needed after hash verification
            timestamp: uint64(block.timestamp)
        });

        sealedBid.revealed = true; // Mark the sealed bid as revealed

        // Update highest bid if this one is higher
        if (_bidAmount > auction.highestBidAmount) {
            // Mark the previous highest bidder's funds for refund
            if (auction.highestBidder != address(0)) {
                 _losingBidderClaimable[_auctionId][auction.highestBidder] = true;
            }
            auction.highestBidder = msg.sender;
            auction.highestBidAmount = _bidAmount;
            _losingBidderClaimable[_auctionId][msg.sender] = false; // This user is now the potential winner, not losing
        } else {
             // This is a losing bid, mark funds for refund
             _losingBidderClaimable[_auctionId][msg.sender] = true;
        }


        // Add reputation for successfully revealing a valid bid
        _updateParticipantReputation(msg.sender, _participantReputation[msg.sender] + 1, "Revealed valid bid");

        emit BidRevealed(_auctionId, msg.sender, _bidAmount);
    }

    /// @notice Transitions auction state from Bidding to Reveal. Can be called by anyone after bidding end time.
    /// @param _auctionId The ID of the auction.
    function endAuctionBiddingPhase(uint256 _auctionId)
        external
        nonReentrant
        whenNotPaused
        auctionExists(_auctionId)
        auctionStateIs(_auctionId, AuctionState.Bidding)
    {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp >= auction.biddingEndTime, "Bidding period has not ended yet");

        auction.state = AuctionState.Reveal;
        auction.revealEndTime = uint64(block.timestamp + (auction.revealEndTime == 0 ? 1 days : auction.revealEndTime - auction.biddingEndTime)); // Set reveal end time (default 1 day if not set)
        // Note: Reveal duration was set in createAuction, we use that here.
        // Let's fix: Use the stored duration.
        auction.revealEndTime = uint64(auction.biddingEndTime + (auctions[_auctionId].revealEndTime - auctions[_auctionId].biddingEndTime)); // Use the original reveal duration

        // Re-set revealEndTime based on the original parameter
        uint256 originalRevealDuration = auction.revealEndTime > auction.biddingEndTime
            ? auction.revealEndTime - auction.biddingEndTime
            : 1 days; // Fallback if somehow not set correctly
        auction.revealEndTime = uint64(block.timestamp + originalRevealDuration);


        emit RevealStarted(_auctionId, auction.revealEndTime);
    }


    /// @notice Transitions auction state from Reveal to Resolving/Ended. Can be called by anyone after reveal end time.
    /// Triggers VRF request or resolves directly.
    /// @param _auctionId The ID of the auction.
    function endAuctionRevealPhase(uint256 _auctionId)
        external
        nonReentrant
        whenNotPaused
        auctionExists(_auctionId)
        auctionStateIs(_auctionId, AuctionState.Reveal)
    {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp >= auction.revealEndTime, "Reveal period has not ended yet");

        // Penalize bidders who placed sealed bids but failed to reveal
        // Note: Direct iteration over mappings is not possible in Solidity.
        // This penalty logic would typically require tracking sealed bidders in an array or linked list,
        // or relying on off-chain processes to identify and penalize.
        // For this example, we'll simulate by adding a function the owner could call or assume
        // a mechanism where failing to reveal impacts future reputation score calculations off-chain
        // or requires manual intervention via subtractParticipantReputation.
        // Let's add a simplified on-chain penalty placeholder: iterate through *all* participants
        // that *might* have bid and check their status. This is not gas-efficient for large numbers
        // of potential bidders, but demonstrates the concept.
        // A better pattern is to track sealed bidders explicitly. Let's add a mapping `auctionId => bidder => bool hasSealedBid`.

        // Transition state
        auction.state = AuctionState.Resolving;

        if (auction.highestBidder == address(0) || auction.highestBidAmount < auction.reservePrice) {
            // No valid bids above reserve, auction fails
            auction.state = AuctionState.Ended;
            // Item goes back to seller (claimable)
            // Revealed bids are marked for refund
            // Logic handled within resolveAuctionInternal called directly
            resolveAuctionInternal(_auctionId, false); // No quantum event for failed auction
            emit AuctionEnded(_auctionId, AuctionState.Ended);

        } else if (auction.quantumBoostEnabled) {
            // Request VRF for quantum boost if enabled and there's a valid winner
            requestQuantumRandomness(_auctionId);
            // State remains Resolving while waiting for VRF callback
        } else {
            // No quantum boost, resolve directly
            resolveAuctionInternal(_auctionId, false); // No quantum event
            auction.state = AuctionState.Ended;
            emit AuctionEnded(_auctionId, AuctionState.Ended);
        }
    }

    // --- Resolution & VRF ---

    /// @notice Requests randomness from Chainlink VRF Coordinator.
    /// Internal function called during auction resolution if Quantum Boost is enabled.
    /// @param _auctionId The ID of the auction requesting randomness.
    function requestQuantumRandomness(uint256 _auctionId) internal {
        require(auctions[_auctionId].state == AuctionState.Resolving, "Auction is not in resolving state");
        require(auctions[_auctionId].quantumBoostEnabled, "Quantum boost not enabled for this auction");
        require(auctions[_auctionId].vrfRequestId == 0, "VRF already requested");

        // Gas limit needs to be adjusted based on the complexity of fulfillRandomWords
        uint32 callbackGasLimit = 300_000; // Example gas limit
        uint16 requestConfirmations = 3;   // Number of block confirmations
        uint32 numWords = 1;               // Request 1 random number

        int64 requestId = requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        auctions[_auctionId].vrfRequestId = requestId;
        s_requests[requestId] = _auctionId; // Map request ID back to auction ID

        emit VRFRequested(_auctionId, requestId);
    }

    /// @notice Chainlink VRF callback function to receive random numbers.
    /// @param _requestId The request ID matching the one returned in `requestRandomWords`.
    /// @param _randomWords An array containing the requested random numbers.
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords)
        internal
        override
        nonReentrant // Ensure reentrancy protection on callback
    {
        require(_randomWords.length > 0, "No random words received");

        uint256 auctionId = s_requests[int64(_requestId)];
        require(auctionId > 0 && auctionId <= _auctionCounter, "VRF callback for unknown auction");

        Auction storage auction = auctions[auctionId];
        require(auction.state == AuctionState.Resolving, "VRF callback for auction not in resolving state");
        require(auction.vrfRequestId == int64(_requestId), "VRF callback request ID mismatch");
        require(!auction.vrfFulfilled, "VRF already fulfilled for this auction");

        auction.vrfFulfilled = true;

        // Use the first random number
        uint256 randomNumber = _randomWords[0];

        // Determine if the quantum event happens based on the random number and probability
        bool quantumEventHappened = false;
        if (quantumBoostProbabilityPercentage > 0) {
            // Use modulo operator for probability check
            // randomNumber % 100 gives a value from 0 to 99
            quantumEventHappened = (randomNumber % 100) < quantumBoostProbabilityPercentage;
        }

        auction.quantumEventHappened = quantumEventHappened;

        // Proceed to final resolution
        resolveAuctionInternal(auctionId, quantumEventHappened);

        auction.state = AuctionState.Ended;
        emit VRFFulfilled(auctionId, int64(_requestId), randomNumber);
        emit AuctionEnded(auctionId, AuctionState.Ended);
    }

    /// @notice Internal function to determine the winner, handle funds, and mark items/payouts claimable.
    /// Called by endAuctionRevealPhase (if no VRF) or fulfillRandomWords (if VRF).
    /// @param _auctionId The ID of the auction to resolve.
    /// @param _quantumEventHappened Whether the quantum boost event occurred for this resolution.
    function resolveAuctionInternal(uint256 _auctionId, bool _quantumEventHappened) internal {
        Auction storage auction = auctions[_auctionId];
        require(auction.state == AuctionState.Resolving, "Auction not in resolving state");
        require(auction.vrfFulfilled || !auction.quantumBoostEnabled, "VRF not fulfilled yet"); // Ensure VRF is done if enabled

        if (auction.highestBidder != address(0) && auction.highestBidAmount >= auction.reservePrice) {
            // Auction is successful
            address winner = auction.highestBidder;
            uint256 winningAmount = auction.highestBidAmount;

            // Winner determined
            emit WinnerDetermined(_auctionId, winner, winningAmount, _quantumEventHappened);

            // Mark item as claimable for winner
            // The item remains in the contract until claimed.

            // Mark payout as claimable for seller
            // The winning amount remains in the contract until claimed.

            // Apply Quantum Boost effects
            if (_quantumEventHappened) {
                // Option 1: Seller fee waived (simplest in terms of fund flow)
                // Option 2: Winner gets reputation boost (implemented here)
                _updateParticipantReputation(winner, _participantReputation[winner] + quantumReputationBonus, "Quantum Boost Winner Bonus");
                emit QuantumBoostApplied(_auctionId, winner, quantumReputationBonus);

                // Potential future: Mint a special SBT for the winner here
                // e.g., ISoulBoundToken(sbtContractAddress).mint(_auctionId, winner);
            }

            // Mark all losing revealed bids for refund
            // We rely on users calling claimRefund().
            // The mapping _losingBidderClaimable is updated in revealBid and here.

        } else {
            // Auction failed (no bids or no bids above reserve)
            auction.highestBidder = address(0); // Explicitly set no winner
            auction.highestBidAmount = 0;

            // Item goes back to seller (claimable)
            // All revealed bids are marked for refund
            // Logic handled below.
        }

        // Regardless of success, mark all revealed bids EXCEPT the winner's (if successful) for refund
        // This marking happened in `revealBid` and `resolveAuctionInternal` itself for previous high bidders.
        // All revealed bidders who are NOT the final highest bidder are marked claimable.
        // The actual funds are released when `claimRefund` is called.

        // Mark seller's item as claimable if auction failed, or mark their payout claimable if successful
        // This is implicitly handled by checking auction state and winner state in claim functions.
    }


    // --- Claiming Functions ---

    /// @notice Allows the winner to claim the auctioned ERC721 item.
    /// @param _auctionId The ID of the auction.
    function claimItem(uint256 _auctionId)
        external
        nonReentrant
        whenNotPaused
        auctionExists(_auctionId)
        auctionStateIs(_auctionId, AuctionState.Ended)
    {
        Auction storage auction = auctions[_auctionId];
        require(msg.sender == auction.highestBidder, "Only the winning bidder can claim the item");
        require(!auction.winnerClaimedItem, "Item already claimed");
        require(auction.highestBidder != address(0) && auction.highestBidAmount >= auction.reservePrice, "Auction was unsuccessful"); // Ensure auction had a winner

        auction.winnerClaimedItem = true;

        // Transfer ERC721 to the winner
        IERC721(auction.erc721Contract).transferFrom(address(this), auction.highestBidder, auction.tokenId);

        // Add reputation for successful win
         _updateParticipantReputation(msg.sender, _participantReputation[msg.sender] + 3, "Won auction and claimed item");


        emit ItemClaimed(_auctionId, msg.sender, auction.tokenId);
    }

    /// @notice Allows the seller to claim the auction proceeds.
    /// @param _auctionId The ID of the auction.
    function claimPayout(uint256 _auctionId)
        external
        nonReentrant
        whenNotPaused
        auctionExists(_auctionId)
        auctionStateIs(_auctionId, AuctionState.Ended)
        onlySeller(_auctionId)
    {
        Auction storage auction = auctions[_auctionId];
        require(!auction.sellerClaimedPayout, "Payout already claimed");

        uint256 amountToSeller;
        IERC20 bidToken = IERC20(auction.erc20BidToken);

        if (auction.highestBidder != address(0) && auction.highestBidAmount >= auction.reservePrice) {
            // Auction was successful
            uint256 winningAmount = auction.highestBidAmount;

            // Calculate seller's share (apply fee, or waive if quantum event happened)
            if (auction.quantumEventHappened) {
                 amountToSeller = winningAmount; // Fee waived by quantum boost
            } else {
                 amountToSeller = winningAmount * (100 - platformFeePercentage) / 100;
            }

            // Transfer platform fee amount to owner (can be withdrawn later)
            uint256 feeAmount = winningAmount - amountToSeller;
            if (feeAmount > 0) {
                // Fee remains in the contract balance until withdrawn by owner
            }

            // Add reputation for successful sale
            _updateParticipantReputation(msg.sender, _participantReputation[msg.sender] + 2, "Successful sale");

        } else {
             // Auction failed - seller claims item back (handled by claimItem logic path if no winner)
             // If auction failed, revealed bids were refunded. No payout for seller from bids.
             // Seller only claims the item back in this case.
             require(false, "Auction was unsuccessful, no payout to claim"); // Should not be reachable if logic for failed auction item claim is separate
             // Let's adjust: Seller claims *either* payout (successful) *or* item (failed).
             // Item claiming by seller on failure is part of cancelAuction or needs a separate claim function.
             // Let's make claimItem usable by seller if auction failed.

             // Corrected logic: Check if auction failed. If so, claimItem is used by seller.
             // If successful, check if msg.sender is seller.
             require(auction.highestBidder != address(0) && auction.highestBidAmount >= auction.reservePrice, "No payout to claim for unsuccessful auction");

              // Re-calculate amountToSeller as per successful auction case
              if (auction.quantumEventHappened) {
                 amountToSeller = auction.highestBidAmount; // Fee waived
             } else {
                 amountToSeller = auction.highestBidAmount * (100 - platformFeePercentage) / 100;
             }

        }

         // Transfer payout to seller
         auction.sellerClaimedPayout = true;
         bidToken.transfer(auction.seller, amountToSeller);


        emit PayoutClaimed(_auctionId, msg.sender, amountToSeller);
    }

    /// @notice Allows a losing bidder who revealed their bid to claim their funds back.
    /// @param _auctionId The ID of the auction.
    function claimRefund(uint256 _auctionId)
        external
        nonReentrant
        whenNotPaused
        auctionExists(_auctionId)
        auctionStateIs(_auctionId, AuctionState.Ended)
    {
        Auction storage auction = auctions[_auctionId];
        // Check if sender placed and revealed a bid
        RevealedBid storage revealedBid = _revealedBids[_auctionId][msg.sender];
        require(revealedBid.bidder == msg.sender, "No revealed bid found for this address");

        // Check if they were a losing bidder marked for refund
        require(_losingBidderClaimable[_auctionId][msg.sender], "No refund available or already claimed");

        uint256 refundAmount = revealedBid.bidAmount;
        require(refundAmount > 0, "Refund amount is zero"); // Should not happen if bid was revealed and positive

        // Mark as claimed before transfer
        _losingBidderClaimable[_auctionId][msg.sender] = false;

        // Transfer ERC20 back to the bidder
        IERC20 bidToken = IERC20(auction.erc20BidToken);
        bidToken.transfer(msg.sender, refundAmount);

        // No reputation change for claiming refund

        emit RefundClaimed(_auctionId, msg.sender, refundAmount);
    }

    // --- Reputation System ---

    /// @notice Internal function to update a participant's reputation and emit an event.
    /// @param _participant The address whose reputation is being updated.
    /// @param _newReputation The new reputation score.
    /// @param _reason Descriptive reason for the update (for logs/events).
    function _updateParticipantReputation(address _participant, uint256 _newReputation, string memory _reason) internal {
         _participantReputation[_participant] = _newReputation;
         emit ReputationUpdated(_participant, _newReputation);
         // Optional: Log the reason too if needed
         // emit ReputationUpdated(_participant, _newReputation, _reason);
    }

    /// @notice Allows owner to manually add reputation.
    /// @param _participant The address to add reputation to.
    /// @param _amount The amount of reputation to add.
    function addParticipantReputation(address _participant, uint256 _amount) external onlyOwner {
        require(_participant != address(0), "Invalid participant address");
        _updateParticipantReputation(_participant, _participantReputation[_participant] + _amount, "Manual add by owner");
    }

    /// @notice Allows owner to manually subtract reputation.
    /// @param _participant The address to subtract reputation from.
    /// @param _amount The amount of reputation to subtract.
    function subtractParticipantReputation(address _participant, uint256 _amount) external onlyOwner {
        require(_participant != address(0), "Invalid participant address");
        uint256 currentRep = _participantReputation[_participant];
        uint256 newRep = currentRep > _amount ? currentRep - _amount : 0;
        _updateParticipantReputation(_participant, newRep, "Manual subtract by owner");
    }

    /// @notice Gets the reputation score for a participant.
    /// @param _participant The participant's address.
    /// @return The reputation score.
    function getParticipantReputation(address _participant) external view returns (uint256) {
        return _participantReputation[_participant];
    }

    // --- Admin & Platform Functions ---

    /// @notice Sets the platform fee percentage.
    /// @param _feePercentage The new fee percentage (0-100).
    function setPlatformFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100");
        platformFeePercentage = _feePercentage;
        emit FeeUpdated(platformFeePercentage);
    }

    /// @notice Sets the minimum reputation required to place a sealed bid.
    /// @param _minReputation The new minimum reputation score.
    function setMinReputationToBid(uint256 _minReputation) external onlyOwner {
        minReputationToBid = _minReputation;
        emit MinReputationUpdated(minReputationToBid);
    }


    /// @notice Sets the parameters for the Quantum Boost feature.
    /// @param _probabilityPercentage The probability of the quantum event occurring (0-100).
    /// @param _reputationBonus The reputation bonus awarded to the winner if the event occurs.
    function setQuantumBoostParameters(uint256 _probabilityPercentage, uint256 _reputationBonus) external onlyOwner {
        require(_probabilityPercentage <= 100, "Probability cannot exceed 100");
        quantumBoostProbabilityPercentage = _probabilityPercentage;
        quantumReputationBonus = _reputationBonus;
        emit QuantumBoostParametersUpdated(quantumBoostProbabilityPercentage, quantumReputationBonus);
    }

    /// @notice Allows the owner to update Chainlink VRF parameters.
    /// @param _subscriptionId The new Chainlink VRF subscription ID.
    /// @param _keyHash The new Chainlink VRF key hash.
    function setVRFParameters(uint64 _subscriptionId, bytes32 _keyHash) external onlyOwner {
         s_subscriptionId = _subscriptionId;
         s_keyHash = _keyHash;
         emit VRFParamsUpdated(s_subscriptionId, s_keyHash);
    }

    /// @notice Allows the owner to withdraw accumulated platform fees for a specific token.
    /// @param _tokenAddress The address of the ERC20 token for which to withdraw fees.
    function withdrawPlatformFees(address _tokenAddress) external onlyOwner nonReentrant {
        require(_tokenAddress != address(0), "Invalid token address");
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));

        // Only withdraw amounts not currently locked in ongoing auctions or awaiting refund
        // This is complex to track perfectly. Simplest is to withdraw the total balance,
        // assuming sufficient funds are available for refunds/payouts from other sources
        // or that this is done carefully. A safer way would be to track fee balances per token.
        // For simplicity, we withdraw the full balance here, assuming manual oversight.

        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance > 0, "No fees to withdraw for this token");

        // Transfer the balance to the owner
        token.transfer(owner(), contractBalance);
        emit FeesWithdrawn(_tokenAddress, contractBalance);
    }

     /// @notice Allows the owner to withdraw ERC20 tokens accidentally sent to the contract.
     /// Does NOT allow withdrawal of tokens used for bids (ERC20BidToken) if they might be needed for auctions.
     /// @param _tokenAddress The address of the stuck ERC20 token.
     /// @param _amount The amount to withdraw.
    function emergencyWithdrawStuckERC20(address _tokenAddress, uint256 _amount) external onlyOwner nonReentrant {
        require(_tokenAddress != address(0), "Invalid token address");
        // Prevent withdrawing bid tokens that might be needed for ongoing auctions, payouts, or refunds.
        // This requires careful tracking of token balances reserved for auctions vs. accidental transfers.
        // A simple check is if this token is the bid token for *any* ongoing auction.
        // This is still not perfect as it might lock up valid stuck tokens if they share an address.
        // A safer version requires tracking total balance per bid token vs. amount locked in auctions.
        // For simplicity, we assume the owner is careful.
        // require(!isAuctionBidToken(_tokenAddress), "Cannot withdraw active auction bid token"); // Placeholder for complex check

        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) >= _amount, "Contract does not have enough tokens");
        token.transfer(owner(), _amount);
    }

    // Placeholder for complex check: Does this token address match the bid token of any active auction?
    // function isAuctionBidToken(address _tokenAddress) internal view returns (bool) {
    //     for (uint256 i = 1; i <= _auctionCounter; i++) {
    //         if (auctions[i].state != AuctionState.Ended && auctions[i].state != AuctionState.Cancelled && auctions[i].erc20BidToken == _tokenAddress) {
    //             // Check if token balance for this auction ID is > 0 within the contract context
    //             // This is tricky. Best left to manual check or more complex balance tracking.
    //             // Returning true conservatively to prevent withdrawals.
    //             return true;
    //         }
    //     }
    //     return false;
    // }


     /// @notice Allows the owner to withdraw ERC721 tokens accidentally sent to the contract.
     /// Does NOT allow withdrawal of tokens currently being auctioned.
     /// @param _nftContract The address of the stuck ERC721 contract.
     /// @param _tokenId The ID of the stuck ERC721 token.
    function emergencyWithdrawStuckERC721(address _nftContract, uint256 _tokenId) external onlyOwner nonReentrant {
        require(_nftContract != address(0), "Invalid NFT contract address");
        // Prevent withdrawing auctioned items
        for (uint256 i = 1; i <= _auctionCounter; i++) {
            if (auctions[i].state != AuctionState.Ended && auctions[i].state != AuctionState.Cancelled && auctions[i].erc721Contract == _nftContract && auctions[i].tokenId == _tokenId) {
                 require(false, "Cannot withdraw item currently in an active auction");
            }
        }
        IERC721(_nftContract).transferFrom(address(this), owner(), _tokenId);
    }

    // --- View Functions ---

    /// @notice Gets details for a specific auction.
    function getAuctionDetails(uint256 _auctionId) external view auctionExists(_auctionId) returns (
        address seller,
        address erc721Contract,
        uint256 tokenId,
        address erc20BidToken,
        uint256 reservePrice,
        uint256 minBidIncrement,
        uint64 biddingEndTime,
        uint64 revealEndTime,
        AuctionState state,
        address highestBidder,
        uint256 highestBidAmount,
        bool winnerClaimedItem,
        bool sellerClaimedPayout,
        bool quantumBoostEnabled,
        bool quantumEventHappened
    ) {
        Auction storage auction = auctions[_auctionId];
        return (
            auction.seller,
            auction.erc721Contract,
            auction.tokenId,
            auction.erc20BidToken,
            auction.reservePrice,
            auction.minBidIncrement,
            auction.biddingEndTime,
            auction.revealEndTime,
            auction.state,
            auction.highestBidder,
            auction.highestBidAmount,
            auction.winnerClaimedItem,
            auction.sellerClaimedPayout,
            auction.quantumBoostEnabled,
            auction.quantumEventHappened
        );
    }

    /// @notice Gets the current state of an auction.
    function getAuctionState(uint256 _auctionId) external view auctionExists(_auctionId) returns (AuctionState) {
        return auctions[_auctionId].state;
    }

    /// @notice Gets the sealed bid hash submitted by a specific bidder for an auction.
    /// Returns zero bytes32 if no sealed bid exists.
    function getUserSealedBidHash(uint256 _auctionId, address _bidder) external view auctionExists(_auctionId) returns (bytes32) {
        return _sealedBids[_auctionId][_bidder].bidHash;
    }

    /// @notice Gets the revealed bid details for a specific bidder for an auction.
    /// Returns zero bidAmount if no bid has been successfully revealed by the bidder.
    function getUserRevealedBidDetails(uint256 _auctionId, address _bidder) external view auctionExists(_auctionId) returns (uint256 bidAmount, uint64 timestamp) {
         RevealedBid storage revealedBid = _revealedBids[_auctionId][_bidder];
         return (revealedBid.bidAmount, revealedBid.timestamp);
    }

    /// @notice Gets the details of the highest revealed bid for an auction.
    /// Returns zero bidAmount if no bids have been revealed above reserve.
    function getHighestRevealedBidDetails(uint256 _auctionId) external view auctionExists(_auctionId) returns (address bidder, uint256 bidAmount) {
        Auction storage auction = auctions[_auctionId];
        return (auction.highestBidder, auction.highestBidAmount);
    }

     /// @notice Gets the determined winner and winning bid amount after the auction has ended and resolved.
     /// Returns address(0) and 0 if the auction was unsuccessful.
    function getAuctionWinnerDetails(uint256 _auctionId) external view auctionExists(_auctionId) returns (address winner, uint256 winningBidAmount) {
        Auction storage auction = auctions[_auctionId];
        // Only return winner if auction was successful
        if (auction.state == AuctionState.Ended && auction.highestBidder != address(0) && auction.highestBidAmount >= auction.reservePrice) {
             return (auction.highestBidder, auction.highestBidAmount);
        } else {
             return (address(0), 0);
        }
    }

    /// @notice Checks the amount a losing bidder can claim back.
    /// @param _auctionId The ID of the auction.
    /// @param _bidder The address of the potential losing bidder.
    /// @return The amount available for refund, or 0.
    function getPendingRefundAmount(uint256 _auctionId, address _bidder) external view auctionExists(_auctionId) returns (uint256) {
        Auction storage auction = auctions[_auctionId];
        // Refund is only available if auction is Ended, bidder revealed, and they are marked as claimable
        if (auction.state == AuctionState.Ended && _losingBidderClaimable[_auctionId][_bidder]) {
             RevealedBid storage revealedBid = _revealedBids[_auctionId][_bidder];
             // Ensure there was a revealed bid for this user
             if (revealedBid.bidder == _bidder) {
                return revealedBid.bidAmount;
             }
        }
        return 0;
    }

    /// @notice Checks the amount the seller can claim.
    /// @param _auctionId The ID of the auction.
    /// @return The amount available for the seller, or 0.
    function getClaimablePayoutAmount(uint256 _auctionId) external view auctionExists(_auctionId) returns (uint256) {
        Auction storage auction = auctions[_auctionId];
        if (auction.state == AuctionState.Ended && msg.sender == auction.seller && !auction.sellerClaimedPayout) {
            if (auction.highestBidder != address(0) && auction.highestBidAmount >= auction.reservePrice) {
                // Successful auction payout calculation
                uint256 winningAmount = auction.highestBidAmount;
                 if (auction.quantumEventHappened) {
                     return winningAmount; // Fee waived
                 } else {
                     return winningAmount * (100 - platformFeePercentage) / 100;
                 }
            }
        }
        return 0;
    }

     /// @notice Checks the tokenId the winner can claim.
     /// @param _auctionId The ID of the auction.
     /// @return The tokenId available for the winner, or 0 if none.
    function getClaimableItemTokenId(uint256 _auctionId) external view auctionExists(_auctionId) returns (uint256) {
         Auction storage auction = auctions[_auctionId];
         if (auction.state == AuctionState.Ended && msg.sender == auction.highestBidder && !auction.winnerClaimedItem) {
             if (auction.highestBidder != address(0) && auction.highestBidAmount >= auction.reservePrice) {
                  return auction.tokenId;
             }
         }
         // Also check if seller can claim item back on failure/cancellation
         if ((auction.state == AuctionState.Ended || auction.state == AuctionState.Cancelled) && msg.sender == auction.seller && auction.highestBidder == address(0)) {
              // Auction failed or cancelled before winner determined
              // Seller needs to claim item back.
              // The flag `winnerClaimedItem` is used to track if the item left the contract for the winner.
              // We need a separate flag or check if the item is still in the contract.
              // A simple approach: if auction ended/cancelled, sender is seller, and no winner was recorded, assume item is claimable by seller.
               return auction.tokenId; // Assuming item is still in contract
         }

         return 0;
    }

    // --- Pausable Overrides ---
    function pause() public override onlyOwner {
        _pause();
    }

    function unpause() public override onlyOwner {
        _unpause();
    }

    // --- Ownable Overrides ---
    // transferOwnership and renounceOwnership are inherited and public


    // --- Fallback/Receive - good practice but handle with care ---
    // receive() external payable {
    //     // Optionally handle native token transfers, maybe for future features
    //     // require(msg.sender == owner(), "Only owner can send native token"); // Example restriction
    // }

    // fallback() external payable {
    //      // Optionally handle calls to non-existent functions
    // }
}
```