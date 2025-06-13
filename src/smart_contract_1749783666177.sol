Okay, let's design an advanced smart contract concept. How about a "Quantum Auction House"? This isn't about actual quantum physics, but uses "Quantum" as a metaphor for unpredictable elements, multiple potential states/outcomes, and rules that change based on time or external factors.

Here's a concept: An auction where the rules (like minimum bid increment) can change during different time phases, a probabilistic bonus might be awarded based on factors determined *at* the moment of finalization, and a portion of fees might be conditionally redirected.

---

**Quantum Auction House Smart Contract Outline**

1.  **License and Pragma**
2.  **Imports:** ERC721 interface, possibly SafeMath (though modern Solidity handles overflow).
3.  **Enums:** Define auction states (Created, Active, Paused, Ended, Finalized, Cancelled) and phases (Initial, SuddenDeath, FinalizationPeriod).
4.  **Structs:** Define `Auction` struct to hold all details for a specific auction.
5.  **State Variables:**
    *   Owner address.
    *   Fee percentage, conditional payout address, conditional threshold.
    *   Mapping for auction data (by ID).
    *   Mapping for tracking user bids (amount, auction ID).
    *   Mapping for tracking payable refunds (auction ID, bidder address).
    *   Counter for auction IDs.
    *   Pausable state.
6.  **Events:** To signal key actions (Creation, Start, Bid, Phase Change, End, Finalize, Claim, Refund, Bonus, Fee Withdrawal, Pause/Unpause, Cancel).
7.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `whenPaused`.
8.  **Core Logic Functions (by category):**
    *   **Admin/Owner:**
        *   Set global parameters (fees, conditional payout).
        *   Withdraw collected fees.
        *   Pause/Unpause the contract.
    *   **Auction Management:**
        *   Create a new auction (define item, duration, reserve, etc.).
        *   Start a created auction.
        *   Cancel an auction (under conditions).
        *   Trigger phase changes based on time/state.
        *   End the bidding period.
        *   Finalize the auction (determine winner, distribute funds/item, calculate bonuses/conditionals).
    *   **Bidding:**
        *   Place a bid (handle minimums, refunds).
    *   **Claiming:**
        *   Claim won item.
        *   Claim bid refund.
        *   Claim potential bonus.
    *   **Query Functions (View/Pure):**
        *   Get details of an auction.
        *   Get current highest bid/bidder.
        *   Get auction state and phase.
        *   Check refund amount for a user.
        *   Check bonus eligibility/status.
        *   Check conditional payout status.

---

**Function Summary**

This contract manages multiple ERC721 auctions with advanced features:

1.  `constructor()`: Initializes the contract owner and sets initial parameters.
2.  `setFeePercentage(uint256 _feePercentage)`: Owner sets the percentage fee taken from the final sale price (e.g., 100 = 1%). Capped at 10000 (100%).
3.  `setConditionalPayoutAddress(address _conditionalPayoutAddress)`: Owner sets an address to receive a conditional portion of fees.
4.  `setConditionalPayoutThreshold(uint256 _threshold)`: Owner sets the minimum winning bid required to trigger the conditional fee payout.
5.  `withdrawFees(address payable _to)`: Owner withdraws collected standard auction fees to a specified address.
6.  `withdrawConditionalPayout(address payable _to)`: Owner withdraws the conditional fee amount (if threshold met) to a specified address.
7.  `pause()`: Owner can pause core functionality (bidding, claiming, finalization) in case of emergency.
8.  `unpause()`: Owner unpauses the contract.
9.  `createAuction(address _nftContract, uint256 _nftTokenId, uint256 _duration, uint256 _reservePrice, uint256 _minimumIncrement)`: Seller or owner creates a new auction for a specific NFT, defining duration, reserve price, and minimum bid increment. Requires NFT approval.
10. `startAuction(uint256 _auctionId)`: Seller or owner starts a created auction, making it active for bidding.
11. `cancelAuction(uint256 _auctionId)`: Seller or owner cancels an auction if it hasn't started or no valid bids have been placed. Transfers NFT back.
12. `placeBid(uint256 _auctionId) payable`: Users place bids. Requires sending ETH >= minimum bid and >= current highest bid + minimum increment. Refunds previous highest bidder.
13. `triggerPhaseChange(uint256 _auctionId)`: Can be called by anyone once time conditions are met to move the auction through predefined phases (e.g., Initial -> Sudden Death -> Finalization). Rules might change per phase.
14. `endAuctionPeriod(uint256 _auctionId)`: Callable after the main auction duration ends. Transitions the auction to the finalization period.
15. `finalizeAuction(uint256 _auctionId)`: Callable after the finalization period. Determines the winner (if reserve met), calculates fees, triggers potential bonus calculation based on block entropy, transfers ETH and NFT, updates state.
16. `claimItem(uint256 _auctionId)`: Winner claims the auctioned NFT after finalization.
17. `claimRefund(uint256 _auctionId)`: Bidders who did not win can claim their submitted ETH back after finalization.
18. `claimBonus(uint256 _auctionId)`: If a bonus was calculated and allocated during finalization for this bidder, they can claim it.
19. `getAuctionDetails(uint256 _auctionId) view`: Returns key parameters of a specific auction (NFT, seller, duration, prices, state).
20. `getCurrentBid(uint256 _auctionId) view`: Returns the current highest bid amount and the address of the highest bidder.
21. `getAuctionState(uint256 _auctionId) view`: Returns the current state (enum) and phase (enum) of the auction.
22. `getRefundAmount(uint256 _auctionId, address _bidder) view`: Checks how much ETH is available for a specific bidder to refund for an auction.
23. `getBonusStatus(uint256 _auctionId, address _bidder) view`: Checks if a specific bidder is eligible for a bonus and the amount.
24. `getConditionalPayoutStatus(uint256 _auctionId) view`: Checks if the conditional payout threshold was met and the amount allocated.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Outline:
// 1. License and Pragma
// 2. Imports (ERC721, Pausable, Ownable, Address utility for transfers)
// 3. Enums for Auction States and Phases
// 4. Struct for Auction data
// 5. State Variables (Owner, Fees, Conditionals, Auction Data, Counters, Pausable)
// 6. Events
// 7. Modifiers (Implicit via Pausable and Ownable)
// 8. Core Logic Functions:
//    - Admin (set fees, withdraw fees, pause/unpause)
//    - Auction Management (create, start, cancel, trigger phase, end period, finalize)
//    - Bidding (place bid)
//    - Claiming (claim item, claim refund, claim bonus)
//    - Query (get details, bid, state, refunds, bonus, conditionals)

// Function Summary:
// 1. constructor(): Initializes owner, sets initial parameters.
// 2. setFeePercentage(uint256 _feePercentage): Owner sets auction fee rate (basis points).
// 3. setConditionalPayoutAddress(address _conditionalPayoutAddress): Owner sets address for conditional fees.
// 4. setConditionalPayoutThreshold(uint256 _threshold): Owner sets bid threshold for conditional fees.
// 5. withdrawFees(address payable _to): Owner withdraws standard collected fees.
// 6. withdrawConditionalPayout(address payable _to): Owner withdraws conditional fees.
// 7. pause(): Owner pauses core actions.
// 8. unpause(): Owner unpauses core actions.
// 9. createAuction(address _nftContract, uint256 _nftTokenId, uint256 _duration, uint256 _reservePrice, uint256 _minimumIncrement): Creates a new auction.
// 10. startAuction(uint256 _auctionId): Starts a created auction.
// 11. cancelAuction(uint256 _auctionId): Cancels an auction before valid bids.
// 12. placeBid(uint256 _auctionId) payable: Places a bid on an active auction.
// 13. triggerPhaseChange(uint256 _auctionId): Advances auction phase based on time/rules.
// 14. endAuctionPeriod(uint256 _auctionId): Transitions auction to finalization period.
// 15. finalizeAuction(uint256 _auctionId): Determines outcome, transfers assets, calculates bonuses/conditionals.
// 16. claimItem(uint256 _auctionId): Winner claims the NFT.
// 17. claimRefund(uint256 _auctionId): Non-winners claim their bids back.
// 18. claimBonus(uint256 _auctionId): Eligible bidders claim probabilistic bonus.
// 19. getAuctionDetails(uint256 _auctionId) view: Get main auction parameters.
// 20. getCurrentBid(uint256 _auctionId) view: Get current highest bid and bidder.
// 21. getAuctionState(uint256 _auctionId) view: Get current state and phase.
// 22. getRefundAmount(uint256 _auctionId, address _bidder) view: Check available refund for a bidder.
// 23. getBonusStatus(uint256 _auctionId, address _bidder) view: Check bonus eligibility/amount for a bidder.
// 24. getConditionalPayoutStatus(uint256 _auctionId) view: Check if conditional payout is active and amount.

contract QuantumAuctionHouse is Ownable, Pausable {
    using Address for address payable;

    enum AuctionState {
        Created,
        Active,
        Paused,
        Ended,
        Finalized,
        Cancelled
    }

    // Phases represent different bidding rule sets or states within the Active period
    enum AuctionPhase {
        Initial, // Standard bidding
        SuddenDeath, // e.g., Smaller minimum increment, rapid end
        FinalizationPeriod // Bidding is over, waiting for finalization call
    }

    struct Auction {
        uint256 id;
        address payable seller; // Address to send net proceeds
        address nftContract;
        uint256 nftTokenId;
        uint256 duration; // Total active bidding duration in seconds

        uint256 startTime; // Timestamp when Active state begins
        uint256 endTime; // Timestamp when Active state ends (startTime + duration)

        uint256 reservePrice;
        uint256 minimumIncrement; // Minimum increase over current highest bid

        uint256 currentHighestBid;
        address payable currentHighestBidder;

        AuctionState state;
        AuctionPhase phase;

        bool reserveMet; // True if final highest bid >= reservePrice
        bool finalized;

        // State for refunds - tracking ETH sent by each bidder
        mapping(address => uint256) bids;
        uint256 totalBidsReceived; // Sum of all bids ever placed (useful for tracking ETH in contract)

        // State for bonus - determined during finalization
        mapping(address => uint256) bonusAmount; // Amount of bonus ETH owed to a bidder
        bool bonusCalculated; // Flag to ensure bonus calculation only happens once

        // State for conditional payout
        bool conditionalPayoutTriggered; // True if winning bid >= threshold
        uint256 conditionalPayoutAmount; // Amount allocated to conditional address
    }

    uint256 private _auctionCounter;
    mapping(uint256 => Auction) public auctions;

    // Global settings
    uint256 public feePercentageBasisPoints; // Fee in basis points (e.g., 100 = 1%)
    address public conditionalPayoutAddress;
    uint256 public conditionalPayoutThreshold;

    // Contract balance tracking (optional but good practice)
    uint256 public totalStandardFeesCollected;
    uint256 public totalConditionalFeesCollected;

    // Events
    event AuctionCreated(uint256 indexed auctionId, address indexed seller, address indexed nftContract, uint256 nftTokenId, uint256 startTime, uint256 endTime);
    event AuctionStarted(uint256 indexed auctionId, uint256 startTime);
    event AuctionCancelled(uint256 indexed auctionId);
    event NewBid(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 currentHighestBid);
    event BidRefunded(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event AuctionPhaseChanged(uint256 indexed auctionId, AuctionPhase newPhase);
    event AuctionEnded(uint256 indexed auctionId); // Bidding period ended
    event AuctionFinalized(uint256 indexed auctionId, address indexed winner, uint256 winningBid, bool reserveMet, uint256 feesPaid);
    event ItemClaimed(uint256 indexed auctionId, address indexed winner, uint256 nftTokenId);
    event RefundClaimed(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event BonusClaimed(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event FeesWithdrawn(address indexed to, uint256 amount);
    event ConditionalPayoutWithdrawn(address indexed to, uint256 amount);
    event Paused(address account);
    event Unpaused(address account);

    constructor() Ownable(msg.sender) Pausable() {
        _auctionCounter = 0;
        feePercentageBasisPoints = 500; // Default 5% fee
        conditionalPayoutAddress = address(0);
        conditionalPayoutThreshold = 0;
    }

    // --- Admin Functions ---

    /// @notice Sets the fee percentage for auctions. Charged from the winning bid.
    /// @param _feePercentage The fee percentage in basis points (e.g., 100 = 1%). Max 10000 (100%).
    function setFeePercentage(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 10000, "Fee percentage cannot exceed 100%");
        feePercentageBasisPoints = _feePercentage;
    }

    /// @notice Sets the address that receives a conditional portion of fees.
    /// @param _conditionalPayoutAddress The address to send conditional fees to.
    function setConditionalPayoutAddress(address _conditionalPayoutAddress) public onlyOwner {
        conditionalPayoutAddress = _conditionalPayoutAddress;
    }

    /// @notice Sets the minimum winning bid amount required to trigger the conditional payout to the conditional address.
    /// @param _threshold The bid threshold (in ETH) to trigger the conditional payout.
    function setConditionalPayoutThreshold(uint256 _threshold) public onlyOwner {
        conditionalPayoutThreshold = _threshold;
    }

    /// @notice Owner can withdraw accumulated standard auction fees.
    /// @param _to The address to send the fees to.
    function withdrawFees(address payable _to) public onlyOwner {
        uint256 amount = totalStandardFeesCollected;
        totalStandardFeesCollected = 0;
        if (amount > 0) {
             _to.sendValue(amount);
             emit FeesWithdrawn(_to, amount);
        }
    }

    /// @notice Owner can withdraw accumulated conditional fees.
    /// @param _to The address to send the conditional fees to.
    function withdrawConditionalPayout(address payable _to) public onlyOwner {
        require(conditionalPayoutAddress != address(0), "Conditional address not set");
        uint256 amount = totalConditionalFeesCollected;
        totalConditionalFeesCollected = 0;
         if (amount > 0) {
            _to.sendValue(amount);
            emit ConditionalPayoutWithdrawn(_to, amount);
        }
    }

    /// @notice Pauses the contract, preventing core interactions like bidding, claiming, and finalization.
    function pause() public onlyOwner whenNotPaused {
        _pause();
        emit Paused(msg.sender);
    }

    /// @notice Unpauses the contract, allowing core interactions again.
    function unpause() public onlyOwner whenPaused {
        _unpause();
        emit Unpaused(msg.sender);
    }

    // --- Auction Management ---

    /// @notice Creates a new auction for an ERC721 token.
    /// @param _nftContract Address of the ERC721 contract.
    /// @param _nftTokenId The token ID of the NFT being auctioned.
    /// @param _duration The total duration of the active bidding period in seconds.
    /// @param _reservePrice The minimum price the seller is willing to sell for.
    /// @param _minimumIncrement The minimum amount a new bid must exceed the current highest bid by.
    /// @return The ID of the newly created auction.
    function createAuction(
        address _nftContract,
        uint256 _nftTokenId,
        uint256 _duration,
        uint256 _reservePrice,
        uint256 _minimumIncrement
    ) public payable returns (uint256) {
        require(_duration > 0, "Auction duration must be positive");
        require(_minimumIncrement > 0, "Minimum increment must be positive");
        require(_nftContract != address(0), "NFT contract address cannot be zero");
        // Check if contract is approved to transfer the NFT
        // This requires the seller to approve this contract BEFORE calling createAuction
        require(IERC721(_nftContract).isApprovedForAll(msg.sender, address(this)) || IERC721(_nftContract).getApproved(_nftTokenId) == address(this),
            "Contract must be approved to transfer the NFT");
        require(IERC721(_nftContract).ownerOf(_nftTokenId) == msg.sender, "Only NFT owner can create auction");

        _auctionCounter++;
        uint256 auctionId = _auctionCounter;

        auctions[auctionId] = Auction({
            id: auctionId,
            seller: payable(msg.sender),
            nftContract: _nftContract,
            nftTokenId: _nftTokenId,
            duration: _duration,
            startTime: 0, // Set on startAuction
            endTime: 0, // Set on startAuction
            reservePrice: _reservePrice,
            minimumIncrement: _minimumIncrement,
            currentHighestBid: 0,
            currentHighestBidder: payable(address(0)),
            state: AuctionState.Created,
            phase: AuctionPhase.Initial,
            reserveMet: false,
            finalized: false,
            bids: new mapping(address => uint256)(), // Initialize mapping
            totalBidsReceived: 0,
            bonusAmount: new mapping(address => uint256)(), // Initialize mapping
            bonusCalculated: false,
            conditionalPayoutTriggered: false,
            conditionalPayoutAmount: 0
        });

        emit AuctionCreated(auctionId, msg.sender, _nftContract, _nftTokenId, 0, 0);

        return auctionId;
    }

    /// @notice Starts a created auction, making it active for bidding.
    /// @param _auctionId The ID of the auction to start.
    function startAuction(uint256 _auctionId) public onlyOwner whenNotPaused {
        Auction storage auction = auctions[_auctionId];
        require(auction.state == AuctionState.Created, "Auction must be in Created state");

        auction.state = AuctionState.Active;
        auction.startTime = block.timestamp;
        auction.endTime = block.timestamp + auction.duration;
        // No transfer of NFT here, it stays in seller's wallet until finalize

        emit AuctionStarted(_auctionId, auction.startTime);
    }

    /// @notice Cancels an auction if it hasn't started or has no valid bids.
    /// @param _auctionId The ID of the auction to cancel.
    function cancelAuction(uint256 _auctionId) public whenNotPaused {
        Auction storage auction = auctions[_auctionId];
        require(msg.sender == auction.seller || msg.sender == owner(), "Only seller or owner can cancel");
        require(auction.state == AuctionState.Created || (auction.state == AuctionState.Active && auction.currentHighestBid == 0),
                "Auction cannot be cancelled after bids are placed or if already finalized/cancelled");

        auction.state = AuctionState.Cancelled;
        // If NFT was transferred to contract on creation (not in this design, but common), transfer back here.
        // In this design, NFT stays with seller until finalize, so no transfer needed on cancel.

        // Refund any bids that might have somehow been placed with 0 currentHighestBid (shouldn't happen with logic)
        // or if cancelling from Created state with misplaced ETH (unlikely).
        // For simplicity in this model, cancellation before bids means no refunds needed.

        emit AuctionCancelled(_auctionId);
    }

    /// @notice Places a bid on an active auction.
    /// @param _auctionId The ID of the auction to bid on.
    function placeBid(uint256 _auctionId) public payable whenNotPaused {
        Auction storage auction = auctions[_auctionId];
        require(auction.state == AuctionState.Active, "Auction must be Active");
        require(block.timestamp < auction.endTime, "Bidding period has ended");
        require(msg.value > 0, "Bid amount must be greater than zero");

        uint256 minBid = auction.currentHighestBid > 0 ? auction.currentHighestBid + auction.minimumIncrement : auction.reservePrice;
        require(msg.value >= minBid, "Bid is too low");

        // Refund previous highest bidder
        if (auction.currentHighestBidder != address(0)) {
            // Store the amount to be refunded. The user claims it later.
            // This prevents reentrancy issues by not sending ETH directly here.
            // We use a separate refund amount tracking, potentially per auction ID
            // Mapping is already used for `bids`, let's repurpose/clarify.
            // `auction.bids[bidder]` will store the *latest* valid bid from that bidder.
            // We need a separate mechanism for *amounts available for withdrawal*.
            // Let's add a global mapping for this: `mapping(address => uint256) public refundableETH;`
            // Alternative: `mapping(uint256 => mapping(address => uint256)) public auctionRefundableETH;`
            // Let's use the second, more specific one. Need to add this mapping to state.

            // Okay, let's use the auctionRefundableETH mapping
            // The previous bidder's *latest* bid amount is now refundable
            auctions[_auctionId].bids[auction.currentHighestBidder] = auction.currentHighestBid; // Store for refund claim

             emit BidRefunded(_auctionId, auction.currentHighestBidder, auction.currentHighestBid);
        }

        // Set new highest bid
        auction.currentHighestBidder = payable(msg.sender);
        auction.currentHighestBid = msg.value;
        // Note: We don't store msg.value in auction.bids[msg.sender] yet.
        // The actual bid amount is just the currentHighestBid.
        // The ETH sent by the bidder is held by the contract implicitly via msg.value.
        // Only the *losing* bids need explicit tracking for refunds.
        // The winning bid ETH is kept by the contract until finalize.
        // So, the `bids` mapping *inside* the Auction struct will store amounts *available for refund*.

        // The ETH for the *current* highest bid stays in the contract implicitly.
        // Only when a *new* higher bid comes, the *previous* highest bidder's ETH needs tracking for refund.
        // This means we update the mapping `auction.bids[previousHighestBidder] = previousHighestBidAmount;`

        emit NewBid(_auctionId, msg.sender, msg.value, auction.currentHighestBid);
    }

    /// @notice Allows the auction to move to the next phase based on time elapsed.
    /// @dev This function makes phases opt-in triggers, rather than automatic.
    /// @param _auctionId The ID of the auction.
    function triggerPhaseChange(uint256 _auctionId) public whenNotPaused {
        Auction storage auction = auctions[_auctionId];
        require(auction.state == AuctionState.Active, "Auction must be Active");
        require(block.timestamp < auction.endTime, "Bidding period has ended");

        // Example Phase Logic:
        // Phase 0 (Initial): 0% to 80% of duration
        // Phase 1 (SuddenDeath): 80% to 100% of duration
        // Phase 2 (FinalizationPeriod): After endTime

        uint256 elapsed = block.timestamp - auction.startTime;
        uint256 totalDuration = auction.duration;
        uint256 elapsedPercentage = (elapsed * 10000) / totalDuration; // in basis points

        if (auction.phase == AuctionPhase.Initial && elapsedPercentage >= 8000) { // 80% elapsed
            auction.phase = AuctionPhase.SuddenDeath;
            // Optionally, update minimumIncrement here
            // auction.minimumIncrement = auction.minimumIncrement / 2; // Example rule change

            emit AuctionPhaseChanged(_auctionId, AuctionPhase.SuddenDeath);

        } else if (block.timestamp >= auction.endTime && auction.phase < AuctionPhase.FinalizationPeriod) {
             auction.phase = AuctionPhase.FinalizationPeriod;
             // Also transition state
             auction.state = AuctionState.Ended;
             emit AuctionPhaseChanged(_auctionId, AuctionPhase.FinalizationPeriod);
             emit AuctionEnded(_auctionId);
        }
        // Add more complex phase logic here if needed
    }

    /// @notice Explicitly transitions auction to the finalization period state after bidding time is up.
    /// @dev Can be called by anyone after `endTime`.
    /// @param _auctionId The ID of the auction.
     function endAuctionPeriod(uint256 _auctionId) public whenNotPaused {
        Auction storage auction = auctions[_auctionId];
        require(auction.state == AuctionState.Active, "Auction must be Active");
        require(block.timestamp >= auction.endTime, "Bidding period is not over yet");
        require(auction.phase < AuctionPhase.FinalizationPeriod, "Auction is already in finalization period");

        auction.state = AuctionState.Ended; // Bidding is officially over
        auction.phase = AuctionPhase.FinalizationPeriod; // Phase reflects state
        emit AuctionEnded(_auctionId);
         emit AuctionPhaseChanged(_auctionId, AuctionPhase.FinalizationPeriod);
     }


    /// @notice Finalizes the auction outcome, transfers assets, and calculates distributions.
    /// @dev Can be called by anyone after the finalization period starts (`state == Ended`).
    /// @param _auctionId The ID of the auction to finalize.
    function finalizeAuction(uint256 _auctionId) public whenNotPaused {
        Auction storage auction = auctions[_auctionId];
        require(auction.state == AuctionState.Ended, "Auction must be in Ended state");
        require(!auction.finalized, "Auction is already finalized");

        auction.finalized = true;

        uint256 winningBidAmount = auction.currentHighestBid;
        address payable winner = auction.currentHighestBidder;

        // 1. Determine Reserve Met
        if (winningBidAmount >= auction.reservePrice) {
            auction.reserveMet = true;

            // 2. Calculate Fees
            uint256 feeAmount = (winningBidAmount * feePercentageBasisPoints) / 10000;
            uint256 netProceeds = winningBidAmount - feeAmount;

            // Calculate conditional fee portion
            uint256 standardFeePortion = feeAmount;
            if (conditionalPayoutAddress != address(0) && winningBidAmount >= conditionalPayoutThreshold) {
                 // Example: 20% of the fee goes to the conditional address
                 uint256 conditionalFee = (feeAmount * 2000) / 10000; // 20%
                 auction.conditionalPayoutAmount = conditionalFee;
                 standardFeePortion = feeAmount - conditionalFee; // Remaining fee goes to owner
                 auction.conditionalPayoutTriggered = true;
            }
             totalStandardFeesCollected += standardFeePortion;

            // 3. Transfer ETH (Net proceeds to seller, fees stay in contract for owner/conditional withdrawal)
             auction.seller.sendValue(netProceeds); // Send net proceeds to seller

            // 4. Transfer NFT to Winner
            IERC721(auction.nftContract).transferFrom(auction.seller, winner, auction.nftTokenId); // Seller must have approved this contract

            // 5. Calculate Potential Bonus (Probabilistic Element)
            // Example: Use block hash entropy near the end of the auction
            // Note: blockhash is only available for the last 256 blocks.
            // A more robust solution might use Chainlink VRF or similar oracle.
            // For this example, we'll use a simple deterministic check based on timestamp.
            // Get a value influenced by recent time/block properties
            uint256 entropy = uint256(blockhash(block.number - 1) % 100); // Entropy from last blockhash, range 0-99
            if (entropy < 10) { // 10% chance of a bonus calculation being triggered
                 // Example Bonus Logic: Give a small bonus back to *some* bidders
                 // e.g., 1% of their losing bid amount to a few random losers
                 // Or, give a fixed small amount to the winner as a 'lucky' bonus
                 uint256 bonusForWinner = (winningBidAmount * 100) / 10000; // 1% bonus for winner
                 auction.bonusAmount[winner] = bonusForWinner;
            }
             auction.bonusCalculated = true;


            emit AuctionFinalized(_auctionId, winner, winningBidAmount, auction.reserveMet, feeAmount);

        } else {
            // Reserve not met - no winner, no fees, NFT stays with seller
            emit AuctionFinalized(_auctionId, address(0), winningBidAmount, auction.reserveMet, 0);
        }

        // Regardless of reserve met, state is Finalized
        auction.state = AuctionState.Finalized;

        // Now, all other bidders (who aren't the winner if reserveMet) can claim refunds
        // The `bids` mapping for this auction now definitively holds amounts owed to losing bidders.
    }


    // --- Claiming Functions ---

    /// @notice Allows the winner of a finalized auction to claim their NFT.
    /// @param _auctionId The ID of the auction.
    function claimItem(uint256 _auctionId) public whenNotPaused {
        Auction storage auction = auctions[_auctionId];
        require(auction.state == AuctionState.Finalized, "Auction must be Finalized");
        require(auction.reserveMet, "Reserve price was not met");
        require(msg.sender == auction.currentHighestBidder, "Only the winner can claim the item");

        // The NFT was already transferred in finalizeAuction.
        // This function primarily serves as a signal/receipt for the winner.
        // Add a flag to prevent double claims if needed, but NFT transfer handles uniqueness.
        // We could add a `itemClaimed` flag to the Auction struct.
        // For simplicity, let's assume the NFT transfer itself is the single action.

        emit ItemClaimed(_auctionId, msg.sender, auction.nftTokenId);
    }

    /// @notice Allows a bidder to claim their ETH refund for losing bids in a finalized auction.
    /// @param _auctionId The ID of the auction.
    function claimRefund(uint256 _auctionId) public whenNotPaused {
        Auction storage auction = auctions[_auctionId];
        require(auction.state == AuctionState.Finalized || auction.state == AuctionState.Cancelled, "Auction must be Finalized or Cancelled");
        require(msg.sender != auction.currentHighestBidder || !auction.reserveMet, "Winner with reserve met does not get a refund"); // Winner gets item, not refund (unless reserve not met)

        uint256 refundAmount = auction.bids[msg.sender];
        require(refundAmount > 0, "No refund amount available for this bidder in this auction");

        // Reset the refund amount before sending to prevent reentrancy
        auction.bids[msg.sender] = 0;

        // Send ETH
        payable(msg.sender).sendValue(refundAmount);

        emit RefundClaimed(_auctionId, msg.sender, refundAmount);
    }

    /// @notice Allows a bidder potentially awarded a bonus to claim it.
    /// @param _auctionId The ID of the auction.
    function claimBonus(uint256 _auctionId) public whenNotPaused {
         Auction storage auction = auctions[_auctionId];
         require(auction.state == AuctionState.Finalized, "Auction must be Finalized to claim bonus");
         require(auction.bonusCalculated, "Bonus calculation not completed for this auction");

         uint256 bonusAmt = auction.bonusAmount[msg.sender];
         require(bonusAmt > 0, "No bonus amount available for this bidder");

         // Reset bonus amount before sending
         auction.bonusAmount[msg.sender] = 0;

         // Send ETH
         payable(msg.sender).sendValue(bonusAmt);

         emit BonusClaimed(_auctionId, msg.sender, bonusAmt);
    }


    // --- Query Functions (View) ---

    /// @notice Gets the detailed information for a specific auction.
    /// @param _auctionId The ID of the auction.
    /// @return A tuple containing auction details.
    function getAuctionDetails(uint256 _auctionId)
        public view
        returns (
            uint256 id,
            address seller,
            address nftContract,
            uint256 nftTokenId,
            uint256 duration,
            uint256 startTime,
            uint256 endTime,
            uint256 reservePrice,
            uint256 minimumIncrement,
            AuctionState state,
            AuctionPhase phase,
            bool reserveMet,
            bool finalized
        )
    {
        Auction storage auction = auctions[_auctionId];
        return (
            auction.id,
            auction.seller,
            auction.nftContract,
            auction.nftTokenId,
            auction.duration,
            auction.startTime,
            auction.endTime,
            auction.reservePrice,
            auction.minimumIncrement,
            auction.state,
            auction.phase,
            auction.reserveMet,
            auction.finalized
        );
    }

    /// @notice Gets the current highest bid and bidder for an auction.
    /// @param _auctionId The ID of the auction.
    /// @return currentHighestBid The amount of the current highest bid.
    /// @return currentHighestBidder The address of the current highest bidder.
    function getCurrentBid(uint256 _auctionId)
        public view
        returns (uint256 currentHighestBid, address currentHighestBidder)
    {
        Auction storage auction = auctions[_auctionId];
        return (auction.currentHighestBid, auction.currentHighestBidder);
    }

    /// @notice Gets the current state and phase of an auction.
    /// @param _auctionId The ID of the auction.
    /// @return state The current AuctionState enum.
    /// @return phase The current AuctionPhase enum.
    function getAuctionState(uint256 _auctionId)
        public view
        returns (AuctionState state, AuctionPhase phase)
    {
        Auction storage auction = auctions[_auctionId];
        return (auction.state, auction.phase);
    }

    /// @notice Checks the amount of ETH available for refund for a specific bidder in an auction.
    /// @param _auctionId The ID of the auction.
    /// @param _bidder The address of the bidder to check.
    /// @return The amount of ETH the bidder can claim as a refund.
    function getRefundAmount(uint256 _auctionId, address _bidder) public view returns (uint256) {
        Auction storage auction = auctions[_auctionId];
        // Refunds are only available once finalized or cancelled
        if (auction.state != AuctionState.Finalized && auction.state != AuctionState.Cancelled) {
             return 0;
        }
         // Winner (if reserve met) does not have a refund amount here
        if (auction.state == AuctionState.Finalized && auction.reserveMet && _bidder == auction.currentHighestBidder) {
            return 0;
        }
        return auction.bids[_bidder]; // `bids` mapping stores refundable amounts after finalization/cancellation
    }

     /// @notice Checks the bonus eligibility and amount for a specific bidder in an auction.
     /// @param _auctionId The ID of the auction.
     /// @param _bidder The address of the bidder to check.
     /// @return isCalculated True if bonus calculation has run.
     /// @return bonusAmt The amount of bonus ETH the bidder is eligible to claim.
     function getBonusStatus(uint256 _auctionId, address _bidder) public view returns (bool isCalculated, uint256 bonusAmt) {
         Auction storage auction = auctions[_auctionId];
         return (auction.bonusCalculated, auction.bonusAmount[_bidder]);
     }

    /// @notice Checks if the conditional payout was triggered for an auction and the amount.
    /// @param _auctionId The ID of the auction.
    /// @return isTriggered True if the conditional payout threshold was met.
    /// @return payoutAmount The amount allocated to the conditional payout address.
    function getConditionalPayoutStatus(uint256 _auctionId) public view returns (bool isTriggered, uint256 payoutAmount) {
        Auction storage auction = auctions[_auctionId];
        return (auction.conditionalPayoutTriggered, auction.conditionalPayoutAmount);
    }

    // --- Internal/Helper Functions (if needed, e.g., for complex calculations) ---
    // No complex ones needed for this basic structure, logic is inline.

    // Fallback function to prevent random ETH sends without calling placeBid
    receive() external payable {
        revert("ETH only accepted via placeBid function");
    }

     fallback() external payable {
        revert("Function does not exist or ETH sent incorrectly");
    }
}
```