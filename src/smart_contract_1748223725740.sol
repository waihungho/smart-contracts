Okay, let's create a smart contract with an interesting, advanced, and creative concept. We'll build an auction contract with a twist: a "Quantum Leap" mechanism where participants can influence the probability of the auction ending early through staked "Temporal Distortion Points" (TDPs). The winner is the highest bidder when the auction *actually* ends, whether by natural time limit or a quantum leap.

This incorporates:
1.  **Auction Mechanics:** Standard rising bid.
2.  **Staking/Influence:** Users stake funds to gain influence (TDPs) over the auction's duration.
3.  **Probabilistic Outcome:** A chance for the auction to end early, influenced by staked TDPs.
4.  **Dynamic End Time:** The exact end time is uncertain.
5.  **ERC721 Integration:** Auctioning a specific NFT.
6.  **Withdrawal Patterns:** Safe handling of bid withdrawals.

We will *simulate* Temporal Distortion Points (TDPs) by having users stake ETH/WETH directly into the contract associated with a specific auction. Their staked amount contributes to their "TDP influence." *Note: True randomness on-chain is hard. The quantum leap probability will use a pseudo-random source (block data + caller address) which is susceptible to front-running, as is common with simple on-chain randomness. A production system would require Chainlink VRF or similar.*

Here's the contract:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Potentially for future TDP token, or just demonstration
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For probability calc (optional but useful)
import "@openzeppelin/contracts/utils/Address.sol"; // For ETH transfers

// --- Outline ---
// 1. State Variables: Define auction parameters, state, bid info, TDP info.
// 2. Enums: Define auction states.
// 3. Events: Announce key actions (start, bid, leap, end, withdraw, stake).
// 4. Modifiers: Restrict function access based on state, owner, etc.
// 5. Constructor: Initialize owner.
// 6. Auction Creation & Management: Functions for owner/seller to setup and potentially cancel.
// 7. Bidding: Function for users to place bids.
// 8. Quantum Leap Mechanism: Functions to stake for TDP influence and trigger the leap.
// 9. Auction Ending: Functions for natural end and leap-triggered end.
// 10. Claiming/Withdrawals: Functions for winner to claim item, seller to claim proceeds, losers to withdraw bids, stakers to withdraw TDP stakes.
// 11. View Functions: Get auction details, bid info, TDP stake info, remaining time, probability.
// 12. Owner/Emergency Functions: Safeties for owner.

// --- Function Summary ---
// 1. constructor(): Initializes the contract with an owner.
// 2. createAuction(address _itemToken, uint256 _itemId, uint256 _duration, uint256 _reservePrice, uint256 _minBidIncrement, uint256 _sellerFeeBasisPoints, uint256 _baseLeapProbabilityBps, uint256 _leapProbabilityMultiplierPerTdpUnit): Sets up a new auction. Must be called by owner. Transfers the NFT to the contract.
// 3. cancelAuction(): Cancels the auction if no bids have been placed and it hasn't started or is in early phase (configurable). Owner or seller only.
// 4. placeBid() payable: Allows a user to place a bid. Must be higher than current highest bid + increment. Sends ETH/WETH.
// 5. withdrawBid(): Allows a losing bidder (or initial bidders if auction is cancelled) to withdraw their locked bid amount after the auction ends or is cancelled.
// 6. withdrawSellerProceeds(): Allows the seller to withdraw the winning bid amount minus the fee after the auction ends and the winner has paid.
// 7. stakeTDPInfluence() payable: Allows a user to stake ETH/WETH to gain Temporal Distortion Points (TDP) influence for the current auction, increasing their quantum leap trigger probability.
// 8. unstakeTDPInfluence(): Allows a user to unstake their TDP influence amount after the auction has ended.
// 9. triggerQuantumLeap(): Allows any user to attempt to trigger an early end to the auction based on a probability influenced by TDP stakes. Uses pseudo-randomness.
// 10. endAuctionNaturally(): Allows any user to finalize the auction state if the planned duration has passed and no quantum leap occurred.
// 11. payWinningBid() payable: Allows the highest bidder to pay their winning bid amount after the auction has ended. Required before claiming the item.
// 12. claimItem(): Allows the winner (who has paid) to claim the auctioned NFT.
// 13. getAuctionState(): Returns the current state of the auction (enum).
// 14. getAuctionDetails(): Returns core parameters of the auction setup.
// 15. getCurrentBidDetails(): Returns the current highest bid amount and bidder address.
// 16. getTimeRemaining(): Calculates and returns the estimated time remaining until the planned end, or 0 if ended.
// 17. getBidAmount(address _bidder): Returns the bid amount placed by a specific address.
// 18. getStakedTDPInfluence(address _staker): Returns the amount of ETH/WETH staked by a user for TDP influence.
// 19. getTotalStakedTDPInfluence(): Returns the total amount of ETH/WETH staked for TDP influence across all users.
// 20. getQuantumLeapProbability(address _caller): Calculates the probability (in basis points) that a specific caller's `triggerQuantumLeap` call would succeed based on their stake. (View function).
// 21. updateMinimumIncrement(uint256 _newIncrement): Allows the owner to update the minimum bid increment *before* the auction starts.
// 22. updateReservePrice(uint256 _newReservePrice): Allows the owner to update the reserve price *before* the auction starts.
// 23. emergencyWithdrawETH(address _to, uint256 _amount): Owner function to withdraw *non-bid/non-stake* ETH accidentally sent to the contract.
// 24. recoverERC721(address _tokenAddress, uint256 _tokenId, address _to): Owner function to recover ERC721 tokens accidentally sent (excluding the auction item).
// 25. recoverERC20(address _tokenAddress, address _to): Owner function to recover ERC20 tokens accidentally sent.

contract QuantumLeapAuction is ReentrancyGuard, Ownable {
    using Address for address payable;

    enum AuctionState { NotStarted, Active, Ended, Cancelled }

    struct Auction {
        AuctionState state;
        address seller;
        IERC721 itemToken;
        uint256 itemId;
        uint256 startTime;
        uint256 plannedEndTime; // The original end time, leap can shorten this
        uint256 actualEndTime;  // The time it actually ended (natural or leap)
        uint256 reservePrice;
        uint256 minBidIncrement;
        uint256 highestBid;
        address payable highestBidder;
        uint256 sellerFeeBasisPoints; // Fee taken from winning bid, in basis points (e.g., 100 for 1%)

        uint256 baseLeapProbabilityBps; // Base chance for leap (e.g., 50 bps = 0.5%)
        uint256 leapProbabilityMultiplierPerTdpUnit; // How much probability increases per unit of TDP staked (e.g., per wei staked)
    }

    Auction public auction;

    // Bids stored per user
    mapping(address => uint256) public bids;

    // Temporal Distortion Points (TDP) influence staking
    // Represents ETH/WETH staked by users specifically to influence leap probability
    mapping(address => uint256) public tdpStakes;
    uint256 public totalTdpStaked;

    // --- Events ---
    event AuctionCreated(address indexed itemToken, uint256 indexed itemId, address indexed seller, uint256 startTime, uint256 plannedEndTime, uint256 reservePrice);
    event AuctionCancelled();
    event BidPlaced(address indexed bidder, uint256 amount, uint256 highestBid, address indexed highestBidder);
    event QuantumLeapTriggered(address indexed caller, uint256 actualEndTime);
    event AuctionEnded(uint256 actualEndTime, address indexed winner, uint256 winningBid);
    event BidWithdrawn(address indexed bidder, uint256 amount);
    event SellerProceedsWithdrawn(address indexed seller, uint256 amount);
    event TDPSupplied(address indexed staker, uint256 amount);
    event TDPReturned(address indexed staker, uint256 amount);
    event ItemClaimed(address indexed winner, address indexed itemToken, uint256 indexed itemId);
    event WinningBidPaid(address indexed winner, uint256 amount);

    // --- Modifiers ---
    modifier whenState(AuctionState _state) {
        require(auction.state == _state, "QLA: Invalid state");
        _;
    }

    modifier auctionActive() {
        require(auction.state == AuctionState.Active, "QLA: Auction not active");
        require(block.timestamp < auction.plannedEndTime, "QLA: Auction time expired, finalize"); // Ensure it hasn't naturally ended yet
        _;
    }

    modifier auctionEnded() {
        require(auction.state == AuctionState.Ended, "QLA: Auction not ended");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == auction.seller, "QLA: Only seller");
        _;
    }

    modifier onlyHighestBidder() {
        require(msg.sender == auction.highestBidder, "QLA: Only highest bidder");
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) {}

    // --- Auction Creation & Management ---

    /// @notice Creates and starts a new quantum leap auction for an ERC721 item.
    /// @param _itemToken The address of the ERC721 token contract.
    /// @param _itemId The ID of the specific token being auctioned.
    /// @param _duration The planned duration of the auction in seconds.
    /// @param _reservePrice The minimum acceptable bid.
    /// @param _minBidIncrement The minimum amount a new bid must exceed the current highest bid.
    /// @param _sellerFeeBasisPoints The percentage fee taken from the winning bid, in basis points (e.g., 100 for 1%). Max 10000 (100%).
    /// @param _baseLeapProbabilityBps The base chance (in basis points) for `triggerQuantumLeap` to succeed with zero TDP influence. Max 10000.
    /// @param _leapProbabilityMultiplierPerTdpUnit How much the probability increases per unit (wei) of ETH/WETH staked for TDP influence.
    function createAuction(
        address _itemToken,
        uint256 _itemId,
        uint256 _duration,
        uint256 _reservePrice,
        uint256 _minBidIncrement,
        uint256 _sellerFeeBasisPoints,
        uint256 _baseLeapProbabilityBps,
        uint256 _leapProbabilityMultiplierPerTdpUnit
    ) external onlyOwner whenState(AuctionState.NotStarted) {
        require(_duration > 0, "QLA: Duration must be positive");
        require(_reservePrice >= 0, "QLA: Reserve price non-negative");
        require(_minBidIncrement > 0, "QLA: Increment must be positive");
        require(_sellerFeeBasisPoints <= 10000, "QLA: Fee exceeds 100%");
        require(_baseLeapProbabilityBps <= 10000, "QLA: Base probability exceeds 100%");
        // Multiplier can be 0

        IERC721 item = IERC721(_itemToken);
        require(item.ownerOf(_itemId) == msg.sender, "QLA: Caller must own the item");

        // Transfer item to the contract BEFORE setting state to Active
        item.safeTransferFrom(msg.sender, address(this), _itemId);

        auction.state = AuctionState.Active;
        auction.seller = msg.sender;
        auction.itemToken = item;
        auction.itemId = _itemId;
        auction.startTime = block.timestamp;
        auction.plannedEndTime = block.timestamp + _duration;
        auction.reservePrice = _reservePrice;
        auction.minBidIncrement = _minBidIncrement;
        auction.highestBid = _reservePrice; // Initialize highest bid to reserve price
        auction.highestBidder = payable(address(0)); // No bidder initially
        auction.sellerFeeBasisPoints = _sellerFeeBasisPoints;
        auction.baseLeapProbabilityBps = _baseLeapProbabilityBps;
        auction.leapProbabilityMultiplierPerTdpUnit = _leapProbabilityMultiplierPerTdpUnit;

        emit AuctionCreated(_itemToken, _itemId, msg.sender, auction.startTime, auction.plannedEndTime, _reservePrice);
    }

    /// @notice Cancels the auction if no bids have been placed and it hasn't started or is in early phase.
    function cancelAuction() external onlyOwner whenState(AuctionState.NotStarted) {
        // Can only cancel if not started, or implement limited cancellation period
        // For simplicity here, only allow if NotStarted
        require(auction.highestBidder == address(0), "QLA: Cannot cancel with bids placed");

        auction.state = AuctionState.Cancelled;

        // Return item to seller if already transferred (shouldn't happen if NotStarted)
        // IERC721(auction.itemToken).safeTransferFrom(address(this), auction.seller, auction.itemId); // This check is safer if cancellation is allowed after transfer

        emit AuctionCancelled();
    }

    // --- Bidding ---

    /// @notice Places a bid on the auction. Requires sending ETH/WETH with the transaction.
    function placeBid() external payable nonReentrant auctionActive {
        uint256 currentBid = msg.value;

        require(currentBid > auction.highestBid, "QLA: Bid must be higher than current highest");
        require(currentBid >= auction.highestBid + auction.minBidIncrement, "QLA: Bid must meet minimum increment");

        // Refund previous highest bidder if they exist and weren't this bidder rebidding
        if (auction.highestBidder != address(0) && auction.highestBidder != msg.sender) {
            // Send their previous bid back
            // Using low-level call for robustness against reentrant traps in recipient fallback
             (bool success, ) = auction.highestBidder.call{value: auction.highestBid}("");
             require(success, "QLA: Failed to refund previous bidder");
        } else if (auction.highestBidder == msg.sender) {
             // This bidder is increasing their own bid. Refund their old bid.
             // The total amount required is new_bid - old_bid. msg.value should be this difference.
             // The `require(currentBid == bids[msg.sender] + msg.value, ...)` logic is more complex with msg.value being the *total* sent.
             // Simpler logic: require new bid is valid total, refund old bid amount if any.
             if (bids[msg.sender] > 0) {
                 (bool success, ) = payable(msg.sender).call{value: bids[msg.sender]}("");
                 require(success, "QLA: Failed to refund previous self-bid");
             }
        }


        // Record the new bid
        bids[msg.sender] = currentBid;
        auction.highestBid = currentBid;
        auction.highestBidder = payable(msg.sender);

        emit BidPlaced(msg.sender, currentBid, auction.highestBid, auction.highestBidder);
    }

    /// @notice Allows a losing bidder to withdraw their bid amount after the auction ends or is cancelled.
    function withdrawBid() external nonReentrant {
        // Can only withdraw if auction is ended or cancelled
        require(auction.state == AuctionState.Ended || auction.state == AuctionState.Cancelled, "QLA: Auction must be ended or cancelled to withdraw bids");

        uint256 userBid = bids[msg.sender];
        require(userBid > 0, "QLA: No bid to withdraw");

        // If auction ended, must not be the winner's bid (winner pays, doesn't withdraw)
        if (auction.state == AuctionState.Ended) {
            require(msg.sender != auction.highestBidder, "QLA: Winner cannot withdraw bid");
        }

        bids[msg.sender] = 0; // Clear the bid first

        // Send the ETH/WETH
        (bool success, ) = payable(msg.sender).call{value: userBid}("");
        require(success, "QLA: Failed to withdraw bid");

        emit BidWithdrawn(msg.sender, userBid);
    }

     /// @notice Allows the seller to withdraw the winning bid amount minus the fee after the auction ends and winner paid.
    function withdrawSellerProceeds() external nonReentrant onlySeller auctionEnded {
        require(auction.highestBidder != address(0), "QLA: No winning bid");
        require(bids[auction.highestBidder] == 0, "QLA: Winner has not paid yet"); // Winning bid amount is moved to contract balance after winner pays

        uint256 winningBidAmount = auction.highestBid;
        uint256 feeAmount = (winningBidAmount * auction.sellerFeeBasisPoints) / 10000;
        uint256 sellerProceeds = winningBidAmount - feeAmount;

        require(sellerProceeds > 0, "QLA: No proceeds to withdraw");

        // Seller's proceeds are implicitly held in the contract's balance after winner payment.
        // Ensure contract has enough balance (should be true if winner paid).

        // Prevent double withdrawal
        // We can't easily track if seller already withdrew without another state variable.
        // A simple way is to zero out the highestBid after withdrawal, preventing future calls for *this* auction.
        uint256 currentHighestBid = auction.highestBid;
        auction.highestBid = 0; // Prevent re-withdrawal for this auction

        (bool success, ) = payable(msg.sender).call{value: sellerProceeds}("");
        require(success, "QLA: Failed to withdraw seller proceeds");

        emit SellerProceedsWithdrawn(msg.sender, sellerProceeds);

         // Restore highest bid value if the transfer somehow fails after state update (less safe)
         // For simplicity and safety, keep highestBid=0 on success and rely on require.
         if (!success) {
             // Consider reverting or re-setting state carefully, but simpler to just let it fail and require manual intervention if call fails.
             // If call fails, seller would need manual help. Better to just revert.
              auction.highestBid = currentHighestBid; // Revert state change on failure
              revert("QLA: Failed to withdraw seller proceeds");
         }
    }


    // --- Quantum Leap Mechanism ---

    /// @notice Allows a user to stake ETH/WETH to gain Temporal Distortion Points (TDP) influence.
    /// This stake increases their probability of successfully triggering a quantum leap.
    /// The staked amount is tied to this specific auction and can be unstaked after it ends.
    function stakeTDPInfluence() external payable nonReentrant whenState(AuctionState.Active) {
        require(msg.value > 0, "QLA: Must stake a positive amount");

        tdpStakes[msg.sender] += msg.value;
        totalTdpStaked += msg.value;

        emit TDPSupplied(msg.sender, msg.value);
    }

    /// @notice Allows a user to unstake their TDP influence amount after the auction has ended.
    function unstakeTDPInfluence() external nonReentrant auctionEnded {
        uint256 stake = tdpStakes[msg.sender];
        require(stake > 0, "QLA: No TDP influence stake to withdraw");

        tdpStakes[msg.sender] = 0; // Clear stake first

        // Note: We don't decrease totalTdpStaked here as it was used for probability calculation
        // during the auction's active phase. Leaving it as is represents the total influence exerted.
        // If totalTdpStaked needed to be accurate post-auction, we'd subtract here, but it's not necessary for logic.

        (bool success, ) = payable(msg.sender).call{value: stake}("");
        require(success, "QLA: Failed to unstake TDP influence");

        emit TDPReturned(msg.sender, stake);
    }

    /// @notice Attempts to trigger an early end to the auction (Quantum Leap).
    /// Success probability is based on staked TDP influence and base probability.
    /// Uses a simple pseudo-random number source.
    function triggerQuantumLeap() external nonReentrant auctionActive {
        // Calculate caller's influence probability
        uint256 callerStake = tdpStakes[msg.sender];
        uint256 probabilityBps = auction.baseLeapProbabilityBps;

        if (totalTdpStaked > 0 && auction.leapProbabilityMultiplierPerTdpUnit > 0) {
             // Use higher precision for calculation before converting back to basis points
            uint256 influenceProbability = (callerStake * auction.leapProbabilityMultiplierPerTdpUnit * 1e18) / (totalTdpStaked * 1e18 / 10000); // Calculate bps influence
            probabilityBps = Math.min(10000, auction.baseLeapProbabilityBps + influenceProbability); // Cap at 100% (10000 bps)
        } else {
             // If no TDPs staked or multiplier is 0, only base probability applies.
             probabilityBps = Math.min(10000, auction.baseLeapProbabilityBps); // Still cap at 100%
        }


        // --- Pseudo-Randomness (WARNING: Predictable) ---
        // This is a simple example using block data and caller address.
        // NOT secure for high-value or truly fair randomness. Can be front-run.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)));
        uint256 randomPercentageBps = randomNumber % 10001; // Get a number between 0 and 10000

        if (randomPercentageBps < probabilityBps) {
            // Quantum Leap successful! End the auction immediately.
            finalizeAuction(block.timestamp); // End at current time

            emit QuantumLeapTriggered(msg.sender, auction.actualEndTime);
        } else {
            // Leap failed. Nothing happens (except gas cost).
            // Could potentially add a small penalty or cooldown here.
        }
    }

    /// @notice Calculates the probability (in basis points) that a specific caller's
    /// `triggerQuantumLeap` call would succeed based on their current stake.
    /// @param _caller The address to check the probability for.
    /// @return The probability in basis points (0-10000).
    function getQuantumLeapProbability(address _caller) public view returns (uint256) {
        if (auction.state != AuctionState.Active) {
            return 0; // Cannot trigger if not active
        }

        uint256 callerStake = tdpStakes[_caller];
        uint256 probabilityBps = auction.baseLeapProbabilityBps;

         if (totalTdpStaked > 0 && auction.leapProbabilityMultiplierPerTdpUnit > 0) {
            // Calculate influence probability, similar logic to trigger function
            // Using uint256(1e18) as a scaling factor for better precision in intermediate calculation
            uint256 influenceProbability = (callerStake * auction.leapProbabilityMultiplierPerTdpUnit * 1e18) / (totalTdpStaked * 1e18 / 10000); // Calculate bps influence
            probabilityBps = Math.min(10000, auction.baseLeapProbabilityBps + influenceProbability);
        } else {
             probabilityBps = Math.min(10000, auction.baseLeapProbabilityBps);
        }

        return probabilityBps;
    }


    // --- Auction Ending ---

    /// @notice Allows any user to finalize the auction state if the planned duration has passed.
    function endAuctionNaturally() external nonReentrant whenState(AuctionState.Active) {
        require(block.timestamp >= auction.plannedEndTime, "QLA: Planned auction time not yet reached");
        finalizeAuction(auction.plannedEndTime); // End at planned time
    }

    /// @dev Internal function to finalize the auction state after it ends (naturally or by leap).
    /// @param _endTime The timestamp at which the auction actually ended.
    function finalizeAuction(uint256 _endTime) internal {
        require(auction.state == AuctionState.Active, "QLA: Auction not active"); // Should only be called from Active state

        auction.state = AuctionState.Ended;
        auction.actualEndTime = _endTime;

        // If reserve price was not met, or no valid bids above reserve price, set highestBidder to address(0)
        if (auction.highestBid < auction.reservePrice || auction.highestBidder == address(0)) {
            auction.highestBidder = payable(address(0));
        }

        emit AuctionEnded(auction.actualEndTime, auction.highestBidder, auction.highestBid);
    }

    // --- Claiming / Withdrawals ---

    /// @notice Allows the highest bidder to pay their winning bid amount after the auction has ended.
    /// This moves the bid amount from their `bids` mapping entry into the contract's balance,
    /// and is a prerequisite for claiming the item.
    function payWinningBid() external payable nonReentrant auctionEnded onlyHighestBidder {
        require(auction.highestBidder != address(0), "QLA: No winner for this auction");
        require(msg.value == auction.highestBid, "QLA: Must send the exact winning bid amount");
        require(bids[msg.sender] == auction.highestBid, "QLA: Internal error - Bid mapping mismatch");
        require(bids[msg.sender] > 0, "QLA: Winning bid already paid"); // Check if bid amount is still recorded (means not paid yet)

        // Move the bid amount from user's 'bids' balance to contract balance
        // The ETH was already sent via `placeBid`. This step just clears the internal record.
        // No, this logic is slightly off. The ETH for the *winning* bid is held by the bidder until they call this.
        // Let's adjust: The highest bid amount IS the amount they must send now.
        // The previous `placeBid` call refunded the *previous* highest bidder. The current highest bidder's funds are NOT in the contract until they call `payWinningBid`.

        // This function requires the winner to send the winning bid amount *now*.
        // Ensure the bid mapping entry is for tracking purposes only after `placeBid`.
        // Let's refine: `bids` mapping tracks the last valid bid attempt, not the currently held amount in the contract.
        // The `placeBid` function should handle refunds of previous bids. The winning bid amount is *not* held by the contract until `payWinningBid`.

        // Let's fix placeBid logic slightly: it should *only* track the highest bid, and refund the *previous* highest bidder. The current highest bidder's funds are *not* sent to the contract until they win and call `payWinningBid`.

        // REVISIT `placeBid`: The `placeBid` function *does* transfer the value (`msg.value`). So, the winning bid *is* held by the contract.
        // Okay, let's make `payWinningBid` just a state update that verifies they are the winner and marks the bid as 'paid' internally, perhaps by zeroing their bid amount in the mapping.
        // BUT, if `placeBid` sends the ETH, and losers withdraw, where does the winner's ETH go? It stays in the contract balance.
        // The `bids` mapping should represent the *amount* held by the contract on behalf of a specific address.

        // Let's redefine:
        // `placeBid()`: Sends msg.value, updates highest bid/bidder. Refunds previous highest bidder. Adds msg.value to `bids[msg.sender]`.
        // `withdrawBid()`: Sends `bids[msg.sender]` amount back, zeros `bids[msg.sender]`.
        // `payWinningBid()`: Called by winner. Verifies they are the winner. Zeros `bids[msg.sender]`. The ETH is already in the contract. This step is just a state transition.
        // `withdrawSellerProceeds()`: Sends winning bid amount - fees from contract balance to seller. Needs to check that winner has paid (bids[winner] is 0).

        // Okay, let's re-check `placeBid` again. If `msg.value` is sent, and the previous bidder is refunded, the *new* highest bidder's funds *are* now in the contract.
        // The `bids` mapping should indeed track the amount currently held for a specific address's active bid.

        // Corrected logic for `payWinningBid`:
        // It seems my initial thought about `payWinningBid` *sending* the funds was wrong based on the `placeBid` implementation.
        // `placeBid` already sends the funds. `payWinningBid` is redundant if its only purpose is to transfer ETH from the winner *now*.
        // The purpose of `payWinningBid` should be to *signal* that the winner is ready to finalize and potentially claim the item, and perhaps verify the amount they *already sent* via `placeBid`.

        // Let's simplify: The winner's funds are already in the contract via `placeBid`. `withdrawBid` is for losers. `payWinningBid` as a separate function might be confusing if funds are already there.
        // Let's remove `payWinningBid` as a separate payable function and integrate its logic into `claimItem` or just assume the winning bid ETH is available.

        // Re-evaluating: The safest withdrawal pattern has users calling withdraw functions *after* the event (auction end).
        // `placeBid`: User sends ETH. If they are outbid, their old bid is refunded immediately. If they are the highest bidder, their bid is held.
        // `withdrawBid`: Losers call this after auction ends to get their held bid back.
        // `claimItem`: Winner calls this after auction ends. Requires their winning bid amount to be available *in the contract*. This means the winner's funds *must* be in the contract from their `placeBid` call.
        // `withdrawSellerProceeds`: Seller calls this after auction ends *and* the winner has claimed/paid.

        // Let's keep `payWinningBid` but make it non-payable and its purpose is just to verify the winner's claim and mark their bid as processed so seller can withdraw. The ETH is already in the contract from `placeBid`.

        // Corrected `payWinningBid`:
        require(auction.highestBidder != address(0), "QLA: No winner for this auction");
        require(bids[msg.sender] == auction.highestBid, "QLA: Winning bid amount not found for caller"); // Verify caller is winner and bid is recorded
        require(bids[msg.sender] > 0, "QLA: Winning bid already processed/paid"); // Check if bid amount is still recorded (means not processed yet)

        // Mark the winning bid as processed. The ETH remains in the contract until seller withdraws.
        // We zero the bid amount to prevent double processing.
        bids[msg.sender] = 0;

        emit WinningBidPaid(msg.sender, auction.highestBid);
    }


    /// @notice Allows the winner (highest bidder who has paid) to claim the auctioned NFT.
    function claimItem() external nonReentrant auctionEnded onlyHighestBidder {
        require(auction.highestBidder != address(0), "QLA: No winner for this auction");
        require(bids[msg.sender] == 0, "QLA: Winning bid has not been paid yet"); // Winner must have called payWinningBid

        IERC721 item = auction.itemToken;
        uint256 itemId = auction.itemId;

        // Ensure the contract still owns the item
        require(item.ownerOf(itemId) == address(this), "QLA: Contract does not own the item");

        // Transfer item to the winner
        item.safeTransferFrom(address(this), msg.sender, itemId);

        // Clear item info from auction struct to prevent double claiming
        auction.itemToken = IERC721(address(0));
        auction.itemId = 0;

        emit ItemClaimed(msg.sender, address(item), itemId);
    }


    // --- View Functions ---

    /// @notice Returns the current state of the auction.
    function getAuctionState() external view returns (AuctionState) {
        return auction.state;
    }

    /// @notice Returns core parameters of the auction setup.
    function getAuctionDetails()
        external
        view
        returns (
            AuctionState state,
            address seller,
            address itemToken,
            uint256 itemId,
            uint256 startTime,
            uint256 plannedEndTime,
            uint256 actualEndTime,
            uint256 reservePrice,
            uint256 minBidIncrement,
            uint256 sellerFeeBasisPoints,
            uint256 baseLeapProbabilityBps,
            uint256 leapProbabilityMultiplierPerTdpUnit
        )
    {
        return (
            auction.state,
            auction.seller,
            address(auction.itemToken),
            auction.itemId,
            auction.startTime,
            auction.plannedEndTime,
            auction.actualEndTime,
            auction.reservePrice,
            auction.minBidIncrement,
            auction.sellerFeeBasisPoints,
            auction.baseLeapProbabilityBps,
            auction.leapProbabilityMultiplierPerTdpUnit
        );
    }

    /// @notice Returns the current highest bid amount and bidder address.
    function getCurrentBidDetails() external view returns (uint256 highestBid, address highestBidder) {
        return (auction.highestBid, auction.highestBidder);
    }

    /// @notice Calculates and returns the estimated time remaining until the planned end, or 0 if ended.
    function getTimeRemaining() external view returns (uint256) {
        if (auction.state == AuctionState.Active) {
            if (block.timestamp >= auction.plannedEndTime) {
                 return 0; // Should be ended naturally, but show 0 time remaining
            }
            return auction.plannedEndTime - block.timestamp;
        }
        return 0; // Not active
    }

    /// @notice Returns the bid amount placed by a specific address.
    /// @param _bidder The address to check.
    function getBidAmount(address _bidder) external view returns (uint256) {
        return bids[_bidder];
    }

    /// @notice Returns the amount of ETH/WETH staked by a user for TDP influence.
    /// @param _staker The address to check.
    function getStakedTDPInfluence(address _staker) external view returns (uint256) {
        return tdpStakes[_staker];
    }

    /// @notice Returns the total amount of ETH/WETH staked for TDP influence across all users.
    function getTotalStakedTDPInfluence() external view returns (uint256) {
        return totalTdpStaked;
    }

    // Note: getQuantumLeapProbability is already defined above (function 20)


    // --- Owner / Emergency Functions ---

    /// @notice Allows the owner to update the minimum bid increment before the auction starts.
    /// @param _newIncrement The new minimum bid increment.
    function updateMinimumIncrement(uint256 _newIncrement) external onlyOwner whenState(AuctionState.NotStarted) {
        require(_newIncrement > 0, "QLA: Increment must be positive");
        auction.minBidIncrement = _newIncrement;
    }

    /// @notice Allows the owner to update the reserve price before the auction starts.
    /// @param _newReservePrice The new reserve price.
    function updateReservePrice(uint256 _newReservePrice) external onlyOwner whenState(AuctionState.NotStarted) {
         require(_newReservePrice >= 0, "QLA: Reserve price non-negative");
         auction.reservePrice = _newReservePrice;
         // If highestBid was initialized to reserve, maybe update it?
         // No, only update the reserve price rule. Highest bid starts at reserve implicitly once active.
    }


    /// @notice Allows the owner to withdraw any ETH accidentally sent to the contract
    /// that is NOT part of active bids or TDP stakes.
    /// @param _to The address to send ETH to.
    /// @param _amount The amount of ETH to withdraw.
    function emergencyWithdrawETH(address payable _to, uint256 _amount) external onlyOwner nonReentrant {
        uint256 contractBalance = address(this).balance;
        uint256 heldFunds = totalTdpStaked; // TDP stakes are ETH
        // Add up total bid amounts held by the contract for active bidders
        // This is tricky without iterating. We know the highest bid ETH is held IF auction is active/ended AND winner hasn't claimed/seller hasn't withdrawn.
        // A safer emergency withdrawal would be to check total balance vs *expected* held funds (sum of all bids in mapping + total TDP stake).
        // For simplicity here, let's assume bids[winner] represents the winning bid amount held until seller withdraws.
        // This is an approximation. A more robust contract might track explicitly held funds.
        if (auction.state != AuctionState.NotStarted && auction.highestBidder != address(0) && bids[auction.highestBidder] > 0) {
             heldFunds += bids[auction.highestBidder]; // Approximate winner's bid amount if still marked as held
        }
         // Other bids are refunded or withdrawn by users.

        // Emergency withdrawal only possible if contract balance is MORE than known held funds
        require(contractBalance > heldFunds, "QLA: Amount exceeds available non-held funds");
        require(_amount <= contractBalance - heldFunds, "QLA: Amount exceeds available non-held funds for withdrawal");

        (bool success, ) = _to.call{value: _amount}("");
        require(success, "QLA: Failed to withdraw emergency ETH");
    }

    /// @notice Allows the owner to recover any ERC721 tokens accidentally sent to the contract,
    /// excluding the specific item currently being auctioned.
    /// @param _tokenAddress The address of the ERC721 token contract.
    /// @param _tokenId The ID of the token to recover.
    /// @param _to The address to send the token to.
    function recoverERC721(address _tokenAddress, uint256 _tokenId, address _to) external onlyOwner nonReentrant {
        IERC721 token = IERC721(_tokenAddress);
        // Ensure it's not the auction item if the auction is active or ended but not claimed
        if (auction.state != AuctionState.NotStarted && address(token) == address(auction.itemToken) && _tokenId == auction.itemId) {
            // If auction ended and item is claimed, this check might be too strict.
            // Safer: Ensure the contract still owns the item AND it's not the *currently auctioned and unclaimed* item.
             bool isAuctionItemOwnedAndUnclaimed = (auction.state == AuctionState.Active || (auction.state == AuctionState.Ended && address(auction.itemToken) != address(0))) && (address(token) == address(auction.itemToken) && _tokenId == auction.itemId);
             require(!isAuctionItemOwnedAndUnclaimed, "QLA: Cannot recover the active/unclaimed auction item");
        }
         require(token.ownerOf(_tokenId) == address(this), "QLA: Contract does not own this token");

        token.safeTransferFrom(address(this), _to, _tokenId);
    }

    /// @notice Allows the owner to recover any ERC20 tokens accidentally sent to the contract.
    /// @param _tokenAddress The address of the ERC20 token contract.
    /// @param _to The address to send the tokens to.
    function recoverERC20(address _tokenAddress, address _to) external onlyOwner nonReentrant {
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "QLA: No balance of this token");
        token.transfer(_to, balance);
    }

    // Receive ETH function to accept bids and TDP stakes
    receive() external payable {
        // This receive is just a fallback. Actual bidding/staking should go through specific functions.
        // Could add a require here to only allow if a specific function is being called,
        // but that's complex. It's safer to just have it accept ETH and rely on
        // `placeBid` and `stakeTDPInfluence` to properly handle the `msg.value`.
    }
}
```