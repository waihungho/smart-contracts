Okay, let's design a smart contract that implements a unique auction mechanism inspired by quantum entanglement – not actual quantum physics (which isn't possible on EVM), but the *concept* of linked states where measuring one affects the other, and a paired state requires overcoming combined thresholds.

We'll call it `QuantumEntanglementAuction`. It auctions two related items (e.g., NFTs) simultaneously. Bidders can bid on item A, item B, or the entangled pair (A+B). The twist is that a paired bid's validity and final outcome are linked to the highest individual bids placed, and this linkage strength can "decay" over time, making paired bids potentially easier towards the end.

---

**QuantumEntanglementAuction Smart Contract**

**Outline:**

1.  **Contract Definition & Imports:** Standard setup, includes interfaces for ERC721/ERC1155 and ReentrancyGuard.
2.  **Error Handling:** Custom errors for clarity.
3.  **Enums:** Auction state (`Created`, `Active`, `Ended`, `Finalized`).
4.  **Structs:**
    *   `Bid`: Represents a bid (amount, bidder).
    *   `PairBid`: Represents a paired bid (amount, bidder, split A %, split B %).
    *   `AssetInfo`: Stores details of the auctioned asset (contract address, token ID, type - ERC721/ERC1155).
5.  **State Variables:**
    *   Owner address.
    *   Assets being auctioned (`AssetInfo` for A and B).
    *   Auction times (start, end).
    *   Current auction state.
    *   Highest bids (`Bid` for A, `Bid` for B, `PairBid` for pair).
    *   Mapping for pending refunds (`address => uint256`).
    *   Winner addresses and winning amounts after finalization.
    *   Claimed status for assets.
    *   Entanglement decay rate and base (controls how the paired bid threshold decreases).
    *   Fee percentage and recipient.
6.  **Events:** Signalling key actions (creation, start, bids, finalization, claims, refunds).
7.  **Modifiers:** State checks.
8.  **Constructor:** Sets initial owner, fee configuration, decay parameters.
9.  **Owner Functions:**
    *   `createAuction`: Sets up the auction with assets and duration. Requires assets to be transferred *before* or approved *to* the contract.
    *   `startAuction`: Begins the bidding period.
    *   `cancelAuction`: Stops auction, refunds assets/bids.
    *   `updateAuctionEndTime`: Extends the auction end time (with restrictions).
    *   `withdrawFees`: Owner collects accumulated fees.
    *   `setFeeRecipient`: Change fee recipient.
    *   `setEntanglementDecayRate`: Adjust the decay rate parameter.
10. **Bidding Functions:**
    *   `placeBidIndividualA`: Bid on Asset A only.
    *   `placeBidIndividualB`: Bid on Asset B only.
    *   `placeBidPair`: Bid on the Entangled Pair (A+B) with a specified value split. Includes the entanglement validation logic with decay.
11. **Refund Function:**
    *   `withdrawRefund`: Allows users to withdraw their losing bid amounts.
12. **Finalization Function:**
    *   `finalizeAuction`: Called after auction ends to determine winner(s) based on the entanglement logic, transfer funds, and prepare for asset claims.
13. **Claiming Functions:**
    *   `claimAssetA`: Allows the winner of Asset A to claim the NFT/Token.
    *   `claimAssetB`: Allows the winner of Asset B to claim the NFT/Token.
14. **View Functions:**
    *   `getAuctionState`: Returns current state.
    *   `getAuctionDetails`: Returns setup parameters (assets, times, decay).
    *   `getCurrentBids`: Returns current highest bids.
    *   `getPendingRefund`: Returns a user's available refund amount.
    *   `getWinnerA`, `getWinnerB`, `getWinningAmountA`, `getWinningAmountB`: Returns final auction results after finalization.
    *   `isAssetAClaimed`, `isAssetBClaimed`: Returns if assets have been claimed.
    *   `calculatePairBidValues`: Helper view to see how a pair bid amount splits.
    *   `getEntanglementDecayRate`: Get the configured decay rate.
    *   `calculateCurrentDecay`: Calculates the decay percentage based on current time.

**Function Summary (Total: 26 functions/views):**

*   `constructor()`
*   `createAuction(address _assetAContract, uint256 _assetATokenId, uint8 _assetAType, address _assetBContract, uint256 _assetBTokenId, uint8 _assetBType, uint48 _duration, uint16 _feePercentage, uint16 _entanglementDecayRatePercentPerDuration)` - **Owner** - Setup auction details.
*   `startAuction()` - **Owner** - Start the bidding phase.
*   `cancelAuction()` - **Owner** - Cancel auction, refund assets/bids.
*   `updateAuctionEndTime(uint48 _newEndTime)` - **Owner** - Extend auction (with limits).
*   `withdrawFees()` - **Owner** - Collect fees.
*   `setFeeRecipient(address _feeRecipient)` - **Owner** - Set fee recipient.
*   `setEntanglementDecayRate(uint16 _entanglementDecayRatePercentPerDuration)` - **Owner** - Adjust decay rate parameter.
*   `placeBidIndividualA()` - **User** - Bid on Asset A.
*   `placeBidIndividualB()` - **User** - Bid on Asset B.
*   `placeBidPair(uint16 _splitAPercent)` - **User** - Bid on the Pair with A/B split.
*   `withdrawRefund()` - **User** - Claim losing bid amounts.
*   `finalizeAuction()` - **Anyone** - End auction, determine winners, distribute funds.
*   `claimAssetA()` - **Winner** - Claim Asset A.
*   `claimAssetB()` - **Winner** - Claim Asset B.
*   `getAuctionState()` - **View** - Current state.
*   `getAuctionDetails()` - **View** - Auction setup info.
*   `getCurrentBids()` - **View** - Highest bids.
*   `getPendingRefund(address _bidder)` - **View** - User's refund amount.
*   `getWinnerA()` - **View** - Winner of A.
*   `getWinnerB()` - **View** - Winner of B.
*   `getWinningAmountA()` - **View** - Winning amount for A.
*   `getWinningAmountB()` - **View** - Winning amount for B.
*   `isAssetAClaimed()` - **View** - Has A been claimed?
*   `isAssetBClaimed()` - **View** - Has B been claimed?
*   `calculatePairBidValues(uint256 _amount, uint16 _splitAPercent)` - **Pure** - Calculate A/B values for a pair bid.
*   `getEntanglementDecayRate()` - **View** - Get configured decay rate.
*   `calculateCurrentDecay()` - **View** - Calculate current decay percentage.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Custom Errors for clarity and gas efficiency
error AuctionNotCreated();
error AuctionAlreadyStarted();
error AuctionNotActive();
error AuctionAlreadyEnded();
error AuctionNotEnded();
error AuctionNotFinalized();
error InvalidAmount();
error BidTooLow();
error InvalidSplit();
error NotHighestBidder();
error NoRefundAvailable();
error AssetAlreadyClaimed();
error OnlyOwner();
error OnlyWinner();
error TransferFailed();
error InvalidAuctionState();
error CannotUpdateEndedAuction();
error InvalidDecayRate();
error InvalidFeeRecipient();
error InvalidFeePercentage();
error AuctionDurationTooShort(); // Added check
error AuctionEndTimeTooEarly(); // Added check for update

/**
 * @title QuantumEntanglementAuction
 * @dev A novel auction mechanism for two assets (ERC721/ERC1155) inspired by quantum entanglement.
 * Bidders can bid on individual assets or an "entangled" pair.
 * A paired bid's validity and winning condition are linked to the highest individual bids,
 * with an 'entanglement decay' making paired bids potentially easier relative to individual bids over time.
 * Requires assets to be transferred to the contract address or approved before calling createAuction.
 */
contract QuantumEntanglementAuction is Ownable, ReentrancyGuard {
    using Address for address;

    // --- Enums ---

    enum AuctionState {
        Created,    // Auction parameters set, assets received, not started
        Active,     // Bidding is open
        Ended,      // Bidding is closed, but not finalized
        Finalized   // Winner(s) determined, funds distributed, ready for claims
    }

    // --- Structs ---

    struct Bid {
        uint256 amount;
        address bidder;
    }

    struct PairBid {
        uint256 amount;
        address bidder;
        uint16 splitAPercent; // Percentage points for Asset A (0-10000)
    }

    enum AssetType {
        ERC721,
        ERC1155
    }

    struct AssetInfo {
        address contractAddress;
        uint256 tokenId;
        AssetType assetType;
        uint256 amount; // Only relevant for ERC1155
    }

    // --- State Variables ---

    AssetInfo public assetA;
    AssetInfo public assetB;

    uint48 public startTime;
    uint48 public endTime;
    AuctionState public currentState;

    Bid public highestIndividualABid;
    Bid public highestIndividualBBid;
    PairBid public highestPairBid;

    // Mapping to track amounts available for refund to users whose bids were surpassed or lost
    mapping(address => uint256) public pendingRefunds;

    address public winnerA;
    address public winnerB;
    uint256 public winningAmountA;
    uint256 public winningAmountB;

    bool public assetAClaimed;
    bool public assetBClaimed;

    // Fee configuration
    uint16 public feePercentage; // Percentage points (0-10000)
    address payable public feeRecipient;
    uint256 private totalFeesCollected;

    // Entanglement configuration
    // How much the required individual bid threshold decays for paired bids over the auction duration
    // Percentage points (0-10000) over the *entire* duration
    uint16 public entanglementDecayRatePercentPerDuration;

    // Constants
    uint16 private constant PERCENTAGE_BASE = 10000; // Represents 100%

    // --- Events ---

    event AuctionCreated(address indexed assetAContract, uint256 assetATokenId, AssetType assetAType, uint256 assetAAmount,
                          address indexed assetBContract, uint256 assetBTokenId, AssetType assetBType, uint256 assetBAmount,
                          uint48 duration, uint16 feePercentage, uint16 entanglementDecayRate);
    event AuctionStarted(uint48 startTime, uint48 endTime);
    event AuctionCancelled();
    event AuctionEndTimeUpdated(uint48 newEndTime);

    event BidPlaced(address indexed bidder, uint256 amount, string bidType); // bidType: "IndividualA", "IndividualB", "Pair"
    event IndividualABidPlaced(address indexed bidder, uint256 amount);
    event IndividualBBidPlaced(address indexed bidder, uint256 amount);
    event PairBidPlaced(address indexed bidder, uint256 amount, uint16 splitAPercent, uint16 splitBPercent);

    event RefundWithdrawn(address indexed recipient, uint256 amount);

    event AuctionFinalized(address indexed winnerA, uint256 winningAmountA, address indexed winnerB, uint256 winningAmountB, bool pairBidWon);

    event AssetClaimed(address indexed winner, address indexed assetContract, uint256 tokenId, AssetType assetType, uint256 amount);

    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event FeeRecipientUpdated(address indexed newRecipient);
    event EntanglementDecayRateUpdated(uint16 newRate);


    // --- Modifiers ---

    modifier whenState(AuctionState _expectedState) {
        if (currentState != _expectedState) revert InvalidAuctionState();
        _;
    }

    modifier notState(AuctionState _forbiddenState) {
        if (currentState == _forbiddenState) revert InvalidAuctionState();
        _;
    }

    // --- Constructor ---

    constructor(address payable _feeRecipient) Ownable(msg.sender) {
        if (_feeRecipient == address(0)) revert InvalidFeeRecipient();
        feeRecipient = _feeRecipient;
        currentState = AuctionState.Created; // Explicitly start in Created state
    }

    // --- Owner Functions ---

    /**
     * @dev Sets up the auction parameters. Must be in Created state.
     * Requires assets to be transferred to this contract or approved beforehand.
     * @param _assetAContract Address of Asset A contract (ERC721 or ERC1155).
     * @param _assetATokenId Token ID of Asset A.
     * @param _assetAType Type of Asset A (0 for ERC721, 1 for ERC1155).
     * @param _assetAAmount Amount of Asset A (only for ERC1155).
     * @param _assetBContract Address of Asset B contract (ERC721 or ERC1155).
     * @param _assetBTokenId Token ID of Asset B.
     * @param _assetBType Type of Asset B (0 for ERC721, 1 for ERC1155).
     * @param _assetBAmount Amount of Asset B (only for ERC1155).
     * @param _duration Duration of the auction in seconds (minimum 1 minute).
     * @param _feePercentage Percentage of winning bids sent to feeRecipient (0-10000).
     * @param _entanglementDecayRatePercentPerDuration Rate at which entanglement 'decays' (0-10000).
     */
    function createAuction(
        address _assetAContract, uint256 _assetATokenId, uint8 _assetAType, uint256 _assetAAmount,
        address _assetBContract, uint256 _assetBTokenId, uint8 _assetBType, uint256 _assetBAmount,
        uint48 _duration, uint16 _feePercentage, uint16 _entanglementDecayRatePercentPerDuration
    ) external onlyOwner whenState(AuctionState.Created) {
        if (_assetAContract == address(0) || _assetBContract == address(0)) revert InvalidAmount(); // Using InvalidAmount as a generic zero address error
        if (_duration < 60) revert AuctionDurationTooShort(); // Minimum duration
        if (_feePercentage > PERCENTAGE_BASE) revert InvalidFeePercentage();
        if (_entanglementDecayRatePercentPerDuration > PERCENTAGE_BASE) revert InvalidDecayRate();
        if (_assetAType > uint8(AssetType.ERC1155) || _assetBType > uint8(AssetType.ERC1155)) revert InvalidAmount(); // Basic type check
        if (_assetAType == uint8(AssetType.ERC1155) && _assetAAmount == 0) revert InvalidAmount();
        if (_assetBType == uint8(AssetType.ERC1155) && _assetBAmount == 0) revert InvalidAmount();

        assetA = AssetInfo({
            contractAddress: _assetAContract,
            tokenId: _assetATokenId,
            assetType: AssetType(_assetAType),
            amount: _assetAAmount
        });
        assetB = AssetInfo({
            contractAddress: _assetBContract,
            tokenId: _assetBTokenId,
            assetType: AssetType(_assetBType),
            amount: _assetBAmount
        });
        // startTime and endTime set in startAuction
        feePercentage = _feePercentage;
        entanglementDecayRatePercentPerDuration = _entanglementDecayRatePercentPerDuration;

        // Note: Assets must be transferred or approved to this contract BEFORE calling startAuction
        // The create function only sets parameters, not asset custody directly within this call.

        emit AuctionCreated(
            assetA.contractAddress, assetA.tokenId, assetA.assetType, assetA.amount,
            assetB.contractAddress, assetB.tokenId, assetB.assetType, assetB.amount,
            _duration, feePercentage, entanglementDecanglementDecayRatePercentPerDuration
        );
    }

    /**
     * @dev Starts the auction. Can only be called once in Created state.
     */
    function startAuction() external onlyOwner whenState(AuctionState.Created) {
        // Basic validation that assets are likely here (doesn't guarantee)
        // A more robust contract might check balances/approvals here,
        // but that adds complexity for this example.
        if (assetA.contractAddress == address(0) || assetB.contractAddress == address(0)) revert AuctionNotCreated();

        startTime = uint48(block.timestamp);
        endTime = startTime + uint48(getAuctionDuration());
        currentState = AuctionState.Active;

        emit AuctionStarted(startTime, endTime);
    }

    /**
     * @dev Cancels the auction before it ends. Refunds assets to owner and bids to bidders.
     */
    function cancelAuction() external onlyOwner notState(AuctionState.Ended) notState(AuctionState.Finalized) nonReentrant {
        // Transfer assets back to owner
        _transferAsset(assetA, owner(), false); // false = not to winner
        _transferAsset(assetB, owner(), false); // false = not to winner

        // Refund current highest bids
        if (highestIndividualABid.bidder != address(0)) {
            pendingRefunds[highestIndividualABid.bidder] += highestIndividualABid.amount;
        }
        if (highestIndividualBBid.bidder != address(0)) {
            pendingRefunds[highestIndividualBBid.bidder] += highestIndividualBBid.amount;
        }
        if (highestPairBid.bidder != address(0)) {
            pendingRefunds[highestPairBid.bidder] += highestPairBid.amount;
        }

        // Note: This cancellation only refunds the *current highest* bids.
        // For a production contract, you'd need to track all bids for full refunds.
        // This example simplifies by only tracking highest bids and allowing users
        // to withdraw previous bids when they are outbid.

        currentState = AuctionState.Ended; // Set to ended, implies cancelled state
        emit AuctionCancelled();
    }

    /**
     * @dev Extends the auction end time. Can only be called when Active.
     * @param _newEndTime The new desired end time (must be in the future and after current end time).
     */
    function updateAuctionEndTime(uint48 _newEndTime) external onlyOwner whenState(AuctionState.Active) {
        if (_newEndTime <= endTime) revert AuctionEndTimeTooEarly();
        if (_newEndTime <= block.timestamp) revert AuctionEndTimeTooEarly(); // Must be in the future

        endTime = _newEndTime;
        emit AuctionEndTimeUpdated(endTime);
    }

    /**
     * @dev Allows the fee recipient to withdraw accumulated fees.
     */
    function withdrawFees() external nonReentrant {
        if (msg.sender != feeRecipient) revert OnlyOwner(); // Or create a specific error

        uint256 amount = totalFeesCollected;
        totalFeesCollected = 0;

        if (amount == 0) return;

        (bool success, ) = feeRecipient.call{value: amount}("");
        if (!success) {
            // If transfer fails, return funds to the fee recipient's pending balance
            totalFeesCollected += amount;
            revert TransferFailed();
        }
        emit FeesWithdrawn(feeRecipient, amount);
    }

    /**
     * @dev Sets a new address for fee collection.
     * @param _feeRecipient The new address.
     */
    function setFeeRecipient(address payable _feeRecipient) external onlyOwner {
        if (_feeRecipient == address(0)) revert InvalidFeeRecipient();
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }

    /**
     * @dev Sets a new entanglement decay rate.
     * @param _entanglementDecayRatePercentPerDuration New rate (0-10000).
     */
    function setEntanglementDecayRate(uint16 _entanglementDecayRatePercentPerDuration) external onlyOwner {
         if (_entanglementDecayRatePercentPerDuration > PERCENTAGE_BASE) revert InvalidDecayRate();
         entanglementDecayRatePercentPerDuration = _entanglementDecayRatePercentPerDuration;
         emit EntanglementDecayRateUpdated(_entanglementDecayRatePercentPerDuration);
    }

    // --- Bidding Functions ---

    /**
     * @dev Places a bid solely on Asset A. Requires paying at least the current highest individual A bid + 1 wei.
     */
    function placeBidIndividualA() external payable nonReentrant whenState(AuctionState.Active) {
        if (msg.value <= highestIndividualABid.amount) revert BidTooLow();

        // Refund previous highest bidder for A
        if (highestIndividualABid.bidder != address(0)) {
            pendingRefunds[highestIndividualABid.bidder] += highestIndividualABid.amount;
        }

        highestIndividualABid = Bid({
            amount: msg.value,
            bidder: msg.sender
        });

        emit BidPlaced(msg.sender, msg.value, "IndividualA");
        emit IndividualABidPlaced(msg.sender, msg.value);
    }

    /**
     * @dev Places a bid solely on Asset B. Requires paying at least the current highest individual B bid + 1 wei.
     */
    function placeBidIndividualB() external payable nonReentrant whenState(AuctionState.Active) {
        if (msg.value <= highestIndividualBBid.amount) revert BidTooLow();

        // Refund previous highest bidder for B
        if (highestIndividualBBid.bidder != address(0)) {
            pendingRefunds[highestIndividualBBid.bidder] += highestIndividualBBid.amount;
        }

        highestIndividualBBid = Bid({
            amount: msg.value,
            bidder: msg.sender
        });

        emit BidPlaced(msg.sender, msg.value, "IndividualB");
        emit IndividualBBidPlaced(msg.sender, msg.value);
    }

    /**
     * @dev Places a bid on the Entangled Pair (Asset A + Asset B).
     * Requires paying at least the current highest paired bid + 1 wei.
     * The bid amount is split between A and B based on _splitAPercent.
     * **Entanglement Rule:** The calculated value for Asset A must be strictly greater than the highest individual A bid (adjusted by decay),
     * AND the calculated value for Asset B must be strictly greater than the highest individual B bid (adjusted by decay).
     * @param _splitAPercent Percentage points for Asset A (0-10000). Asset B gets the rest.
     */
    function placeBidPair(uint16 _splitAPercent) external payable nonReentrant whenState(AuctionState.Active) {
        if (msg.value <= highestPairBid.amount) revert BidTooLow();
        if (_splitAPercent == 0 || _splitAPercent == PERCENTAGE_BASE) revert InvalidSplit(); // Must split between both

        uint256 currentDecay = calculateCurrentDecay(); // Decay % points (0-10000)

        // Calculate the effective individual bid thresholds after decay
        uint256 thresholdA = (highestIndividualABid.amount * (PERCENTAGE_BASE - currentDecay)) / PERCENTAGE_BASE;
        uint256 thresholdB = (highestIndividualBBid.amount * (PERCENTAGE_BASE - currentDecay)) / PERCENTAGE_BASE;

        // Calculate proposed values for A and B from the new pair bid
        (uint256 proposedValueA, uint256 proposedValueB) = calculatePairBidValues(msg.value, _splitAPercent);

        // Entanglement Validation: Proposed values must beat current (decayed) individual highs
        // AND the new pair bid must be strictly greater than the previous highest pair bid.
        if (proposedValueA <= thresholdA || proposedValueB <= thresholdB) {
             revert BidTooLow(); // Re-using error, could be custom like InvalidPairedBidSplit
        }

        // Refund previous highest paired bidder
        if (highestPairBid.bidder != address(0)) {
            pendingRefunds[highestPairBid.bidder] += highestPairBid.amount;
        }
        // Note: This does *not* refund the previous highest individual A or B bidders
        // if this new pair bid surpasses them. Their funds remain held until finalizeAuction
        // or until they are outbid by a new *individual* bid.

        highestPairBid = PairBid({
            amount: msg.value,
            bidder: msg.sender,
            splitAPercent: _splitAPercent
        });

        emit BidPlaced(msg.sender, msg.value, "Pair");
        emit PairBidPlaced(msg.sender, msg.value, _splitAPercent, PERCENTAGE_BASE - _splitAPercent);
    }

    /**
     * @dev Allows a bidder to withdraw funds that were locked by their bid but have since been surpassed or refunded.
     */
    function withdrawRefund() external nonReentrant {
        uint256 amount = pendingRefunds[msg.sender];
        if (amount == 0) revert NoRefundAvailable();

        pendingRefunds[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) {
            // If transfer fails, return funds to the pending balance
            pendingRefunds[msg.sender] += amount;
            revert TransferFailed();
        }
        emit RefundWithdrawn(msg.sender, amount);
    }

    // --- Finalization Function ---

    /**
     * @dev Finalizes the auction after the end time. Determines winner(s) and distributes funds.
     * Can be called by anyone once the auction has ended.
     */
    function finalizeAuction() external nonReentrant {
        if (currentState != AuctionState.Active || block.timestamp < endTime) revert AuctionNotEnded();
        if (currentState == AuctionState.Finalized) revert AuctionAlreadyEnded(); // Prevent double finalization

        currentState = AuctionState.Finalized;

        uint256 currentDecay = calculateCurrentDecay(); // Decay is fixed at finalization time
        uint256 thresholdA = (highestIndividualABid.amount * (PERCENTAGE_BASE - currentDecay)) / PERCENTAGE_BASE;
        uint256 thresholdB = (highestIndividualBBid.amount * (PERCENTAGE_BASE - currentDecay)) / PERCENTAGE_BASE;

        bool pairBidWins = false;

        // Check if the highest pair bid wins based on the final individual bids and decay
        if (highestPairBid.bidder != address(0)) {
             (uint256 pairValueA, uint256 pairValueB) = calculatePairBidValues(highestPairBid.amount, highestPairBid.splitAPercent);

             // Paired bid wins if its derived values are *strictly* greater than the
             // final individual bids (adjusted by decay).
             // Note: This rule means if individual bids match the threshold exactly, the pair bid *doesn't* win.
             if (pairValueA > thresholdA && pairValueB > thresholdB) {
                 pairBidWins = true;
                 winnerA = highestPairBid.bidder;
                 winnerB = highestPairBid.bidder;
                 winningAmountA = (highestPairBid.amount * highestPairBid.splitAPercent) / PERCENTAGE_BASE;
                 winningAmountB = highestPairBid.amount - winningAmountA; // Use remaining amount to avoid potential rounding issues on B
                 // The total amount paid is highestPairBid.amount
             }
        }

        uint256 ownerProceeds = 0;

        if (pairBidWins) {
            // Paired bidder wins both assets.
            // Refund individual bidders
            if (highestIndividualABid.bidder != address(0)) {
                pendingRefunds[highestIndividualABid.bidder] += highestIndividualABid.amount;
            }
            if (highestIndividualBBid.bidder != address(0)) {
                pendingRefunds[highestIndividualBBid.bidder] += highestIndividualBBid.amount;
            }
            // The winning pair bid amount stays in the contract (it was msg.value)
            ownerProceeds = highestPairBid.amount;

        } else {
            // Individual bidders win their respective assets (if they exist)
            winnerA = highestIndividualABid.bidder;
            winningAmountA = highestIndividualABid.amount;
            if (winnerA != address(0)) ownerProceeds += winningAmountA;
            else _transferAsset(assetA, owner(), false); // No bid on A, return A to owner

            winnerB = highestIndividualBBid.bidder;
            winningAmountB = highestIndividualBBid.amount;
            if (winnerB != address(0)) ownerProceeds += winningAmountB;
            else _transferAsset(assetB, owner(), false); // No bid on B, return B to owner

            // Refund the highest paired bidder
            if (highestPairBid.bidder != address(0)) {
                 pendingRefunds[highestPairBid.bidder] += highestPairBid.amount;
            }
            // Any other bids (if full bid history was tracked) would also be refunded here.
        }

        // Distribute fees to feeRecipient
        if (ownerProceeds > 0 && feePercentage > 0) {
             uint256 fees = (ownerProceeds * feePercentage) / PERCENTAGE_BASE;
             totalFeesCollected += fees;
             // ownerProceeds -= fees; // This reduction isn't needed, the fee is taken from total balance
        }

        // The remaining balance in the contract is distributed to the owner (or stays if owner is feeRecipient)
        // For simplicity, the owner's proceeds includes the amount designated for fees.
        // The fees are withdrawn separately by the feeRecipient.
        // Funds for refunds remain in the contract until withdrawn by users.

        emit AuctionFinalized(winnerA, winningAmountA, winnerB, winningAmountB, pairBidWins);
    }

    // --- Claiming Functions ---

    /**
     * @dev Allows the winner of Asset A to claim it after finalization.
     */
    function claimAssetA() external nonReentrant whenState(AuctionState.Finalized) {
        if (msg.sender == address(0) || msg.sender != winnerA) revert OnlyWinner();
        if (assetAClaimed) revert AssetAlreadyClaimed();
        if (assetA.contractAddress == address(0)) revert InvalidAmount(); // Asset wasn't set

        assetAClaimed = true;
        _transferAsset(assetA, winnerA, true); // true = to winner

        emit AssetClaimed(winnerA, assetA.contractAddress, assetA.tokenId, assetA.assetType, assetA.amount);
    }

    /**
     * @dev Allows the winner of Asset B to claim it after finalization.
     */
    function claimAssetB() external nonReentrant whenState(AuctionState.Finalized) {
        if (msg.sender == address(0) || msg.sender != winnerB) revert OnlyWinner();
        if (assetBClaimed) revert AssetAlreadyClaimed();
        if (assetB.contractAddress == address(0)) revert InvalidAmount(); // Asset wasn't set

        assetBClaimed = true;
        _transferAsset(assetB, winnerB, true); // true = to winner

        emit AssetClaimed(winnerB, assetB.contractAddress, assetB.tokenId, assetB.assetType, assetB.amount);
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Calculates the current entanglement decay percentage (0-10000).
     * Decay is linear based on time elapsed relative to total auction duration.
     */
    function calculateCurrentDecay() internal view returns (uint256) {
        if (currentState != AuctionState.Active && currentState != AuctionState.Finalized) return 0;
        if (entanglementDecayRatePercentPerDuration == 0) return 0;

        uint256 duration = getAuctionDuration();
        if (duration == 0) return 0; // Avoid division by zero

        uint256 elapsed = block.timestamp - startTime;
        if (elapsed >= duration) return entanglementDecayRatePercentPerDuration; // Full decay if time's up

        // Linear decay: (elapsed / duration) * decayRate
        // Use 20000 as base for intermediate multiplication to maintain precision
        return (elapsed * entanglementDecayRatePercentPerDuration * PERCENTAGE_BASE) / (duration * PERCENTAGE_BASE);
    }

    /**
     * @dev Transfers an asset (ERC721 or ERC1155).
     * @param asset The asset info.
     * @param recipient The address to transfer to.
     * @param isWinnerTransfer True if transferring to the winner, false if back to owner (e.g., cancellation or no bid).
     */
    function _transferAsset(AssetInfo memory asset, address recipient, bool isWinnerTransfer) internal {
        if (asset.contractAddress == address(0) || recipient == address(0)) return; // Cannot transfer if asset or recipient is zero address

        if (asset.assetType == AssetType.ERC721) {
            IERC721(asset.contractAddress).transferFrom(address(this), recipient, asset.tokenId);
        } else if (asset.assetType == AssetType.ERC1155) {
             // For ERC1155, requires operator approval or isWinnerTransfer to be true
             // If cancelling or no bid (isWinnerTransfer=false), contract should have operator status from owner.
             // If transferring to winner (isWinnerTransfer=true), contract is implicitly allowed to send from itself.
             IERC1155(asset.contractAddress).safeTransferFrom(address(this), recipient, asset.tokenId, asset.amount, "");
        } else {
            revert TransferFailed(); // Should not happen with checks
        }
    }

    /**
     * @dev Returns the total duration of the auction.
     */
    function getAuctionDuration() internal view returns (uint256) {
        if (startTime == 0 || endTime == 0 || endTime <= startTime) return 0;
        return endTime - startTime;
    }


    // --- View Functions ---

    /**
     * @dev Returns the current state of the auction.
     */
    function getAuctionState() external view returns (AuctionState) {
        return currentState;
    }

    /**
     * @dev Returns details about the auction setup.
     */
    function getAuctionDetails() external view returns (
        AssetInfo memory _assetA, AssetInfo memory _assetB,
        uint48 _startTime, uint48 _endTime, uint16 _feePercentage, uint16 _entanglementDecayRatePercentPerDuration
    ) {
        return (
            assetA, assetB,
            startTime, endTime, feePercentage, entanglementDecayRatePercentPerDuration
        );
    }

    /**
     * @dev Returns the current highest bids for individual A, individual B, and the paired bid.
     */
    function getCurrentBids() external view returns (Bid memory individualA, Bid memory individualB, PairBid memory pair) {
        return (highestIndividualABid, highestIndividualBBid, highestPairBid);
    }

    /**
     * @dev Returns the amount a specific bidder can withdraw as refund.
     * @param _bidder The address of the bidder.
     */
    function getPendingRefund(address _bidder) external view returns (uint256) {
        return pendingRefunds[_bidder];
    }

    /**
     * @dev Returns the winner of Asset A after finalization.
     */
    function getWinnerA() external view returns (address) {
        return winnerA;
    }

     /**
     * @dev Returns the winner of Asset B after finalization.
     */
    function getWinnerB() external view returns (address) {
        return winnerB;
    }

    /**
     * @dev Returns the winning amount for Asset A after finalization.
     */
    function getWinningAmountA() external view returns (uint256) {
        return winningAmountA;
    }

    /**
     * @dev Returns the winning amount for Asset B after finalization.
     */
    function getWinningAmountB() external view returns (uint256) {
        return winningAmountB;
    }

    /**
     * @dev Returns true if Asset A has been claimed by the winner.
     */
    function isAssetAClaimed() external view returns (bool) {
        return assetAClaimed;
    }

    /**
     * @dev Returns true if Asset B has been claimed by the winner.
     */
    function isAssetBClaimed() external view returns (bool) {
        return assetBClaimed;
    }

    /**
     * @dev Calculates the theoretical values for Asset A and B based on a paired bid amount and split.
     * Useful for users to see how their paired bid is interpreted.
     * @param _amount The total paired bid amount.
     * @param _splitAPercent Percentage points for Asset A (0-10000).
     * @return valueA Calculated value for Asset A.
     * @return valueB Calculated value for Asset B.
     */
    function calculatePairBidValues(uint256 _amount, uint16 _splitAPercent) public pure returns (uint256 valueA, uint256 valueB) {
        if (_splitAPercent == 0 || _splitAPercent > PERCENTAGE_BASE) {
            return (0, 0); // Invalid split
        }
        valueA = (_amount * _splitAPercent) / PERCENTAGE_BASE;
        valueB = _amount - valueA; // Calculate B value from remainder
        return (valueA, valueB);
    }

    /**
     * @dev Returns the configured entanglement decay rate.
     */
    function getEntanglementDecayRate() external view returns (uint16) {
        return entanglementDecayRatePercentPerDuration;
    }

    /**
     * @dev Calculates and returns the current entanglement decay percentage (0-10000).
     */
     function calculateCurrentDecay() public view returns (uint256) {
        if (currentState != AuctionState.Active && currentState != AuctionState.Finalized) return 0;
        if (entanglementDecayRatePercentPerDuration == 0) return 0;

        uint256 duration = getAuctionDuration();
        if (duration == 0) return 0; // Should not happen if auction started correctly

        uint256 elapsed = block.timestamp - startTime;
        if (elapsed >= duration) return entanglementDecayRatePercentPerDuration; // Full decay

        // Linear decay: (elapsed / duration) * decayRate
        // Multiply by PERCENTAGE_BASE twice for precision before dividing once
        return (elapsed * entanglementDecayRatePercentPerDuration * PERCENTAGE_BASE) / (duration);
     }

    // --- Receive/Fallback ---

    // Required to receive ETH bids
    receive() external payable {}
    fallback() external payable {}

    // --- ERC721/ERC1155 Receiver Hooks (Optional but good practice if contract *receives* assets directly) ---
    // For this example, we assume assets are transferred *before* createAuction or approved.
    // If assets were transferred *during* createAuction, you'd need these hooks.
    // Example:
    /*
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        // Check if from is owner, operator is approved, and tokenId matches assetA/assetB etc.
        // Return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns (bytes4) {
        // Check if from is owner, operator is approved, id matches assetA/assetB etc.
        // Return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external returns (bytes4) {
         // Return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
         return this.onERC1155BatchReceived.selector;
    }
    */
}
```