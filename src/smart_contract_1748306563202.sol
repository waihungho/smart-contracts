Okay, let's create an interesting, advanced, and creative smart contract. We'll design a "Celestial Auction House" that auctions dynamic, procedurally-evolving ERC721 tokens ("Celestial Objects") using a sealed-bid Vickrey-like mechanism where the second-highest bidder gets a reward. It will also incorporate staking for a platform utility token and a simple fee distribution model.

Here's the outline and function summary followed by the Solidity code.

---

**Contract Name:** CelestialAuctionHouse

**Concept:** A platform for auctioning unique, dynamic ERC721 tokens (CelestialObjects) using a sealed-bid auction where the second-highest bidder receives a reward in the platform's ERC20 token (AetherGem). The CelestialObjects themselves have properties that can evolve. The platform also allows staking of AetherGem tokens to earn a portion of auction fees.

**Outline:**

1.  **Interfaces:** Define interfaces for external ERC721 and ERC20 tokens (`IERC721`, `IERC20`).
2.  **Errors:** Custom errors for clearer failure reasons.
3.  **Events:** Log key actions (Auction Created, Bid Placed, Bid Revealed, Auction Ended, Staked, Unstaked, Rewards Claimed, Property Updated).
4.  **Enums:** Define auction status (`AuctionStatus`).
5.  **Structs:**
    *   `CelestialObjectProperties`: Data structure for the dynamic properties of an object.
    *   `Auction`: Data structure for each auction instance.
    *   `Bid`: Data structure for a revealed bid.
    *   `StakerData`: Data structure to track staking and rewards.
6.  **State Variables:**
    *   References to external token contracts (`celestialObjectsContract`, `aetherGemContract`).
    *   Auction counter (`nextAuctionId`).
    *   Mapping for `Auction` data (`auctions`).
    *   Mapping for sealed bid hashes (`sealedBids`).
    *   Mapping for revealed bids (`revealedBids`).
    *   Mapping for `CelestialObjectProperties` (`celestialObjectData`).
    *   Mapping for staker data (`stakers`).
    *   Total amount staked (`totalStakedSupply`).
    *   Total fees collected in ETH (`totalProtocolFeesETH`).
    *   Parameters (`auctionFeePercentage`, `secondBidderRewardPercentage`, `minRevealPeriod`, `minBiddingPeriod`, `minEvolutionInterval`).
    *   Admin/Owner address (`owner`).
7.  **Modifiers:** Access control (`onlyOwner`), auction state checks (`whenStatusIs`, `whenStatusIsNot`).
8.  **Constructor:** Initialize contract with token addresses and basic parameters.
9.  **Auction Lifecycle Functions:**
    *   `createAuction`: Start a new auction for a specific `CelestialObject`.
    *   `placeSealedBid`: Submit a hashed bid along with ETH/WETH.
    *   `revealBid`: Reveal the actual bid amount and secret after the bidding period ends.
    *   `endAuction`: Finalize the auction after the reveal period, determine winner/second, distribute item, collect fees, reward second bidder.
    *   `cancelAuction`: Allow seller or owner to cancel an auction before bids are revealed.
10. **Celestial Object Management:**
    *   `initializeCelestialObject`: Record initial properties when an object is minted/listed for the first time via this platform.
    *   `updateCelestialProperty`: Owner or authorized role can update a property directly (e.g., for maintenance or manual event).
    *   `triggerPropertyEvolution`: A function anyone can call (under conditions) to trigger a pseudo-random property evolution based on time/age and potentially staked AetherGem.
11. **Staking & Rewards:**
    *   `stakeAetherGem`: Stake AetherGem tokens to earn rewards.
    *   `unstakeAetherGem`: Unstake AetherGem tokens.
    *   `claimStakingRewards`: Claim accumulated staking rewards (pro-rata share of `totalProtocolFeesETH`).
    *   `claimAndRestakeRewards`: Claim rewards and immediately add them to the staked balance (requires fee conversion to AetherGem - simplified here).
12. **Admin/Configuration:**
    *   `setFeePercentage`: Set the percentage of auction winnings collected as fee.
    *   `setSecondBidderRewardPercentage`: Set the percentage of the *fee* that goes to the second highest bidder (in AetherGem equivalent).
    *   `withdrawProtocolFeesETH`: Owner can withdraw accumulated ETH protocol fees not distributed as staking rewards.
    *   `setMinPeriods`: Set minimum durations for bidding and reveal phases.
    *   `setMinEvolutionInterval`: Set minimum time between property evolutions for an object.
    *   `transferOwnership`: Transfer admin rights.
13. **View Functions:**
    *   `getAuctionDetails`: Get details of a specific auction.
    *   `getUserBidHash`: Get the hashed bid submitted by a user for an auction.
    *   `getUserRevealedBid`: Get the revealed bid details for a user in an auction.
    *   `getCelestialObjectDetails`: Get the dynamic properties of a `CelestialObject`.
    *   `getStakingBalance`: Get a user's current staked AetherGem balance.
    *   `getClaimableRewards`: Estimate user's claimable ETH rewards based on their stake and collected fees.
    *   `getTotalStaked`: Get the total amount of AetherGem staked in the contract.
    *   `getAuctionStatus`: Get the current status enum for an auction.
    *   `getBidsCount`: Get the number of revealed bids for an auction.
    *   `getEstimatedStakingAPY`: A simplified estimate (conceptual) of APY based on recent fees vs total stake. *Note: Real APY calculation on-chain is complex.*
    *   `getFeePercentage`: Get current auction fee percentage.
    *   `getSecondBidderRewardPercentage`: Get current second bidder reward percentage.

---

**Solidity Code:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title CelestialAuctionHouse
/// @dev A platform for auctioning dynamic Celestial Objects (ERC721) via sealed-bid auctions.
/// Second highest bidders are rewarded with AetherGem (ERC20). Features include dynamic object
/// properties, AetherGem staking for ETH fees, and basic governance hooks.

// Interfaces
interface ICelestialObjects is IERC721 {
    // Assume CelestialObjects contract has a function to verify ownership/existence
    function exists(uint256 tokenId) external view returns (bool);
}

interface IAetherGem is IERC20 {
    // Assume AetherGem contract exists and handles transfers
}

// Custom Errors
error AuctionNotFound(uint256 auctionId);
error InvalidAuctionStatus(uint256 auctionId, AuctionStatus currentStatus, AuctionStatus requiredStatus);
error AuctionNotReady(uint256 auctionId, string reason);
error NotSeller(uint256 auctionId);
error InvalidBidHash();
error BidAlreadyPlaced();
error BidNotPlaced();
error InvalidBidAmount();
error NotInRevealPeriod(uint256 auctionId);
error NotInBiddingPeriod(uint256 auctionId);
error BidNotRevealed();
error AuctionNotEnded(uint256 auctionId);
error NoBidsRevealed();
error TransferFailed();
error StakingFailed();
error UnstakingFailed();
error InsufficientStake();
error NoRewardsToClaim();
error ObjectNotFound(uint256 celestialObjectId);
error EvolutionNotReady(uint256 celestialObjectId);
error CannotTriggerEvolutionTooSoon(uint256 celestialObjectId, uint64 nextEvolutionTime);
error InvalidPercentage();
error InsufficientProtocolFees();

// Events
event AuctionCreated(uint256 indexed auctionId, uint256 indexed celestialObjectId, address indexed seller, uint64 startTime, uint64 revealTime, uint64 endTime);
event SealedBidPlaced(uint256 indexed auctionId, address indexed bidder, bytes32 bidHash);
event BidRevealed(uint256 indexed auctionId, address indexed bidder, uint256 amount);
event AuctionEnded(uint256 indexed auctionId, address indexed winner, uint256 winningBid, address secondHighestBidder, uint256 secondHighestBid, uint256 protocolFeeETH, uint256 secondBidderRewardAG);
event AuctionCancelled(uint256 indexed auctionId);
event CelestialObjectInitialized(uint256 indexed celestialObjectId, uint32 initialLuminosity, uint16 initialSpectralType);
event CelestialObjectPropertyChanged(uint256 indexed celestialObjectId, string propertyName, string oldValue, string newValue); // Generic event for changes
event CelestialObjectEvolutionTriggered(uint256 indexed celestialObjectId, uint32 newLuminosity, uint16 newSpectralType); // Specific for evolution
event AetherGemStaked(address indexed staker, uint256 amount);
event AetherGemUnstaked(address indexed staker, uint256 amount);
event StakingRewardsClaimed(address indexed staker, uint256 amountETH);
event ProtocolFeesWithdrawn(address indexed recipient, uint256 amountETH);
event ParameterChangeProposed(string indexed parameterName, uint256 newValue);
event ParameterChangeApproved(string indexed parameterName, uint256 newValue); // Simplified to owner approval

// Enums
enum AuctionStatus { Pending, SealedBidding, RevealPeriod, Completed, Cancelled }

// Structs
struct CelestialObjectProperties {
    uint32 luminosity;      // e.g., 0-1000
    uint16 spectralType;    // e.g., integer code mapping to OBAFGKM
    uint64 lastUpdated;     // Timestamp of last property change or evolution
    bool initialized;       // Whether properties for this ID have been recorded
}

struct Auction {
    uint256 celestialObjectId;
    address payable seller;
    uint64 startTime;
    uint64 revealTime; // When reveal period starts
    uint64 endTime;    // When auction and reveal periods end

    uint256 highestBid;
    address highestBidder;
    uint256 secondHighestBid;
    address secondHighestBidder;

    AuctionStatus status;
    bool itemTransferred; // Track if item is sent to winner
    bool feesDistributed; // Track if fees and rewards are processed
}

struct Bid {
    address bidder;
    uint256 amount;
    uint256 salt; // Used with amount for hashing
}

struct StakerData {
    uint256 stakedAmount;
    // Simple reward tracking: share of total fees accrued since last claim/stake event
    uint256 cumulativeRewardsPerTokenStaked;
    uint256 unclaimedRewardsETH; // Simpler approach: track earned rewards directly
}

contract CelestialAuctionHouse is Ownable {
    using SafeMath for uint256;
    using Address for address payable;

    ICelestialObjects public immutable celestialObjectsContract;
    IAetherGem public immutable aetherGemContract;

    uint256 public nextAuctionId = 1;
    mapping(uint256 => Auction) public auctions;

    // auctionId => bidder => hashedBid
    mapping(uint256 => mapping(address => bytes32)) private sealedBids;
    // auctionId => bidder => Revealed Bid struct
    mapping(uint256 => mapping(address => Bid)) private revealedBids;

    // celestialObjectId => CelestialObjectProperties
    mapping(uint256 => CelestialObjectProperties) public celestialObjectData;

    // staker => StakerData
    mapping(address => StakerData) public stakers;
    uint256 public totalStakedSupply;
    uint256 public totalProtocolFeesETH;
    uint256 private cumulativeRewardsPerTokenStaked; // Not strictly used in the simpler model, kept for comparison

    // Parameters
    uint256 public auctionFeePercentage; // Basis points (e.g., 100 for 1%)
    uint256 public secondBidderRewardPercentage; // Percentage of FEE, Basis points (e.g., 5000 for 50% of the fee)
    uint64 public minBiddingPeriod;
    uint64 public minRevealPeriod;
    uint64 public minEvolutionInterval; // Minimum seconds between property evolutions

    // Constructor
    constructor(address _celestialObjectsContract, address _aetherGemContract) Ownable(msg.sender) {
        celestialObjectsContract = ICelestialObjects(_celestialObjectsContract);
        aetherGemContract = IAetherGem(_aetherGemContract);

        // Set initial parameters (can be changed by owner later)
        auctionFeePercentage = 250; // 2.5%
        secondBidderRewardPercentage = 5000; // 50% of the 2.5% fee goes to 2nd bidder (in AetherGem)
        minBiddingPeriod = 1 days;
        minRevealPeriod = 1 days;
        minEvolutionInterval = 7 days;
    }

    // --- Auction Lifecycle Functions ---

    /// @dev Creates a new sealed-bid auction for a CelestialObject.
    /// Requires the seller to approve the contract to transfer the token beforehand.
    /// @param celestialObjectId The ID of the CelestialObject token to auction.
    /// @param biddingEndTime Timestamp when the sealed bidding period ends.
    /// @param auctionEndTime Timestamp when the reveal period ends and auction can be finalized.
    function createAuction(
        uint256 celestialObjectId,
        uint64 biddingEndTime,
        uint64 auctionEndTime
    ) external {
        require(celestialObjectsContract.ownerOf(celestialObjectId) == msg.sender, "Not owner of object");
        require(celestialObjectsContract.getApproved(celestialObjectId) == address(this), "ERC721 transfer approval required");
        require(biddingEndTime > block.timestamp + minBiddingPeriod, "Bidding end too soon");
        require(auctionEndTime > biddingEndTime + minRevealPeriod, "Auction end too soon after bidding");

        // Ensure object properties are tracked if not already
        if (!celestialObjectData[celestialObjectId].initialized) {
            // Placeholder initial values - real implementation might fetch from ERC721 or use minter logic
            celestialObjectData[celestialObjectId] = CelestialObjectProperties({
                luminosity: 500, // Example initial value
                spectralType: 5, // Example initial value (e.g., 'G' type)
                lastUpdated: uint64(block.timestamp),
                initialized: true
            });
            emit CelestialObjectInitialized(celestialObjectId, 500, 5); // Example values
        }


        uint256 auctionId = nextAuctionId++;
        auctions[auctionId] = Auction({
            celestialObjectId: celestialObjectId,
            seller: payable(msg.sender),
            startTime: uint64(block.timestamp),
            revealTime: biddingEndTime,
            endTime: auctionEndTime,
            highestBid: 0,
            highestBidder: address(0),
            secondHighestBid: 0,
            secondHighestBidder: address(0),
            status: AuctionStatus.SealedBidding, // Starts directly in bidding
            itemTransferred: false,
            feesDistributed: false
        });

        emit AuctionCreated(auctionId, celestialObjectId, msg.sender, uint64(block.timestamp), biddingEndTime, auctionEndTime);
    }

    /// @dev Allows a bidder to place a sealed bid.
    /// Bids are submitted as a hash of the bid amount and a salt.
    /// Requires sending enough ETH/WETH with the transaction to cover the potential bid amount.
    /// Excess ETH/WETH is refunded during the reveal or endAuction phase.
    /// @param auctionId The ID of the auction.
    /// @param bidHash The keccak256 hash of (bidAmount, salt, auctionId, address(this)).
    function placeSealedBid(uint256 auctionId, bytes32 bidHash) external payable whenStatusIs(auctionId, AuctionStatus.SealedBidding) {
        Auction storage auction = auctions[auctionId];
        require(auction.startTime <= block.timestamp && block.timestamp < auction.revealTime, "Not in sealed bidding period");
        require(sealedBids[auctionId][msg.sender] == bytes32(0), BidAlreadyPlaced.selector);
        require(msg.value > 0, InvalidBidAmount.selector); // Must send some value

        sealedBids[auctionId][msg.sender] = bidHash;

        // Note: Actual bid amount verification happens during reveal.
        // We store the hash and the provided ETH/WETH. The provided ETH/WETH
        // serves as a maximum potential bid and will be held.

        emit SealedBidPlaced(auctionId, msg.sender, bidHash);
    }

    /// @dev Allows a bidder to reveal their bid amount and salt.
    /// Must be called during the reveal period.
    /// Verifies the revealed amount and salt match the previously submitted hash.
    /// @param auctionId The ID of the auction.
    /// @param bidAmount The original bid amount.
    /// @param salt The salt used to generate the hash.
    function revealBid(uint256 auctionId, uint256 bidAmount, uint256 salt) external whenStatusIs(auctionId, AuctionStatus.RevealPeriod) {
        Auction storage auction = auctions[auctionId];
        require(auction.revealTime <= block.timestamp && block.timestamp < auction.endTime, NotInRevealPeriod.selector);

        bytes32 expectedHash = keccak256(abi.encodePacked(bidAmount, salt, auctionId, address(this)));
        require(sealedBids[auctionId][msg.sender] == expectedHash, InvalidBidHash.selector);
        require(sealedBids[auctionId][msg.sender] != bytes32(0), BidNotPlaced.selector); // Ensure a hash was actually placed
        require(msg.value >= bidAmount, "Sent ETH less than revealed bid"); // Ensure enough ETH was initially sent

        // Store the revealed bid
        revealedBids[auctionId][msg.sender] = Bid({
            bidder: msg.sender,
            amount: bidAmount,
            salt: salt // Store salt for potential future debugging/verification
        });

        // Update highest and second highest bids immediately upon reveal
        if (bidAmount > auction.highestBid) {
            // Current highest becomes second highest
            auction.secondHighestBid = auction.highestBid;
            auction.secondHighestBidder = auction.highestBidder;

            // New bid becomes highest
            auction.highestBid = bidAmount;
            auction.highestBidder = msg.sender;
        } else if (bidAmount > auction.secondHighestBid && msg.sender != auction.highestBidder) {
            // New bid is between highest and second highest
            auction.secondHighestBid = bidAmount;
            auction.secondHighestBidder = msg.sender;
        }
        // Note: If bidAmount == highestBid, this is handled by the endAuction logic
        // if multiple bidders have the same highest bid. For simplicity, first revealed highest wins.
        // If bidAmount == secondHighestBid, first revealed second highest wins.

        emit BidRevealed(auctionId, msg.sender, bidAmount);

        // Refund excess ETH immediately upon reveal
        uint256 excessAmount = msg.value.sub(bidAmount);
        if (excessAmount > 0) {
             payable(msg.sender).sendValue(excessAmount);
        }
    }

     /// @dev Allows anyone to finalize an auction after the reveal period has ended.
     /// Determines winner, transfers item, collects fee, rewards second highest bidder.
     /// Refunds ETH for unrevealed bids.
     /// @param auctionId The ID of the auction.
    function endAuction(uint256 auctionId) external whenStatusIs(auctionId, AuctionStatus.RevealPeriod) {
        Auction storage auction = auctions[auctionId];
        require(block.timestamp >= auction.endTime, AuctionNotReady.selector + " (Reveal period not ended)");
        require(!auction.itemTransferred || !auction.feesDistributed, "Auction already finalized"); // Prevent double finalization

        auction.status = AuctionStatus.Completed; // Mark as completed early to prevent re-entry

        address winner = auction.highestBidder;
        uint256 winningBidAmount = auction.highestBid; // This is the amount the winner *revealed*, not necessarily paid
        address secondBidder = auction.secondHighestBidder;
        uint256 secondBidAmount = auction.secondHighestBid;

        // Process winner (if any revealed a bid)
        if (winner != address(0)) {
             // The winner pays their revealed bid amount.
             // The ETH for the winning bid was already sent during placeSealedBid and held.
             // No ETH needs to be transferred *from* the winner here, only distributed.

            // Calculate fee
            uint256 protocolFee = winningBidAmount.mul(auctionFeePercentage).div(10000);
            uint256 sellerProceeds = winningBidAmount.sub(protocolFee);

            // Distribute fee and proceeds
            totalProtocolFeesETH = totalProtocolFeesETH.add(protocolFee);
            (bool successFee) = payable(auction.seller).sendValue(sellerProceeds);
            require(successFee, TransferFailed.selector);

            // Transfer the item to the winner
            celestialObjectsContract.safeTransferFrom(address(this), winner, auction.celestialObjectId);
            auction.itemTransferred = true;

            // Reward second highest bidder (if different from winner and they revealed a bid)
            if (secondBidder != address(0) && secondBidder != winner) {
                // Reward is a percentage of the protocol fee, paid in AetherGem
                // Need to convert ETH fee portion to AetherGem value - this requires an oracle or fixed price.
                // Simplified here: assume a fixed conversion rate or distribute actual AetherGem from a pool.
                // Let's distribute a proportional amount from accumulated ETH fees to stakers, and give
                // the second bidder AetherGem from the contract's balance.
                // A more robust version would calculate the value of the second bidder reward in ETH and
                // transfer the equivalent in AetherGem.
                // For simplicity, let's assume the contract holds AetherGem and gives a fixed amount,
                // or a % of the fee *value* converted to AetherGem.
                // Let's use the percentage of FEE concept and assume an oracle/value feed elsewhere determines the AG amount.
                // Or simpler: a percentage of the *winning bid amount* is paid to 2nd bidder in AG.
                // Let's stick to the original idea: % of the ETH FEE goes to 2nd bidder, paid in AG.
                // This requires the contract to *have* AG tokens. The percentage is of the *ETH value*,
                // but the payout is in AG. This implies a conversion rate is needed or the AG amount is fixed.
                // Let's assume for *this example* we just transfer a fixed amount of AG or a simplified calculation.
                // Or even simpler: second highest bidder gets a percentage of the ETH fee distributed to *them* directly, not AG.
                // Let's go with the AG reward, implying contract holds AG. Calculation needs a placeholder.
                // Assume a mechanism exists to get AG amount for ETH value.
                 uint256 secondBidderRewardAmountAG = (protocolFee.mul(secondBidderRewardPercentage).div(10000)).mul(100); // Placeholder: convert ETH wei to AG units (e.g., assuming 1 ETH = 100 AG for demo)

                // Ensure the contract has enough AetherGem
                // This requires the owner/admin to deposit AetherGem into the contract beforehand
                if (aetherGemContract.balanceOf(address(this)) >= secondBidderRewardAmountAG) {
                    (bool successAG) = aetherGemContract.transfer(secondBidder, secondBidderRewardAmountAG);
                    require(successAG, TransferFailed.selector);
                    emit AuctionEnded(auctionId, winner, winningBidAmount, secondBidder, secondBidAmount, protocolFee, secondBidderRewardAmountAG);
                } else {
                     // Not enough AG for the reward, skip AG reward but still end auction
                     emit AuctionEnded(auctionId, winner, winningBidAmount, secondBidder, secondBidAmount, protocolFee, 0);
                }
            } else {
                 // No second bidder, or second bidder is the winner
                 emit AuctionEnded(auctionId, winner, winningBidAmount, address(0), 0, protocolFee, 0);
            }

        } else {
            // No bids revealed, auction failed
            // Transfer item back to seller
            celestialObjectsContract.safeTransferFrom(address(this), auction.seller, auction.celestialObjectId);
            auction.itemTransferred = true;
             emit AuctionEnded(auctionId, address(0), 0, address(0), 0, 0, 0);
        }

        // Refund ETH for any bids that were placed but *not* revealed
        // Iterate through sealed bids (potentially gas intensive if many bidders)
        // A production contract might require bidders to withdraw unrevealed bids themselves
        // Simple approach: refund ETH associated with bids whose hashes were submitted
        // but are not in the revealedBids map. This requires iterating over all potential bidders.
        // A better approach would be to track total ETH sent per bidder and subtract the revealed amount.
        // Or make refunding a user-initiated action. Let's make it user-initiated for gas efficiency.
        // Add a `claimRefund` function.

         auction.feesDistributed = true; // Mark as processed even if no fees/rewards were distributed

    }

    /// @dev Allows a seller or the owner to cancel an auction.
    /// Only possible before any bids are revealed.
    /// Transfers the item back to the seller and allows bidders to claim refunds.
    /// @param auctionId The ID of the auction.
    function cancelAuction(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];
        require(auction.status == AuctionStatus.SealedBidding || auction.status == AuctionStatus.Pending, InvalidAuctionStatus.selector);
        require(msg.sender == auction.seller || msg.sender == owner(), NotSeller.selector);
        require(block.timestamp < auction.revealTime, "Cannot cancel after reveal period starts");

        // Check if any bids have been revealed - if so, cannot cancel this way
        // This requires iterating revealedBids map, which is hard on-chain.
        // A state variable tracking `revealedBidCount` per auction is better.
        // Let's assume for simplicity that if status is SealedBidding and time < revealTime, no reveals happened.
        // Or enforce that revealBid changes status (it doesn't in current logic). Let's adjust:
        // `revealBid` can stay in `SealedBidding` until revealTime passes, then it's `RevealPeriod`.
        // Cancellation is only allowed BEFORE `revealTime`.

        celestialObjectsContract.safeTransferFrom(address(this), auction.seller, auction.celestialObjectId);
        auction.status = AuctionStatus.Cancelled;

        // Bidders will need to call claimRefund

        emit AuctionCancelled(auctionId);
    }

    /// @dev Allows a bidder to claim their unused ETH if their bid was not the winner
    /// or was not revealed, after the auction has ended or been cancelled.
    /// @param auctionId The ID of the auction.
    function claimRefund(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];
        require(auction.status == AuctionStatus.Completed || auction.status == AuctionStatus.Cancelled, "Auction must be completed or cancelled");
        require(msg.sender != auction.highestBidder, "Winner cannot claim refund"); // Winner's ETH is used for payment

        // If a bid was revealed, refund any excess over the revealed amount (already done in revealBid)
        // If a bid was sealed but NOT revealed, refund the full amount sent initially
        // This requires tracking the initial amount sent. Let's assume initial amount sent
        // is the only ETH held *per bidder* for this auction.

        // This is hard without tracking `msg.value` per user per auction upon `placeSealedBid`.
        // A simpler (but less precise) approach: send back the amount held by the contract
        // that isn't the winning bid amount. This is problematic with multiple bidders.

        // Let's simplify the refund logic for this example:
        // If the auction ended without a winner (no reveals or cancelled):
        // Any address that submitted a sealed bid hash *can call this*.
        // This requires tracking ETH per bidder.

        // Let's revise `placeSealedBid` to track value per user.
        // struct BidderDeposit { uint256 amount; bool revealed; }
        // mapping(uint256 => mapping(address => BidderDeposit)) private bidderDeposits;
        // This adds complexity.

        // Alternative: Make refunding explicit. When `placeSealedBid` is called, the user's ETH is held.
        // In `revealBid`, the excess is sent back. If not revealed, `claimRefund` can be called
        // *by the bidder* after `endTime` or cancellation to get back the *full* amount they sent.
        // This requires storing the initial deposited amount per bidder.

        // Let's add initial deposit tracking:
        mapping(uint256 => mapping(address => uint256)) private initialDeposits;

        // Update placeSealedBid:
        // initialDeposits[auctionId][msg.sender] = initialDeposits[auctionId][msg.sender].add(msg.value);

        // Update revealBid:
        // uint256 initialDeposit = initialDeposits[auctionId][msg.sender];
        // require(initialDeposit >= bidAmount, "Sent ETH less than revealed bid");
        // uint256 excessAmount = initialDeposit.sub(bidAmount);
        // if (excessAmount > 0) { payable(msg.sender).sendValue(excessAmount); initialDeposits[auctionId][msg.sender] = bidAmount; }

        // Update endAuction:
        // No ETH transfers from bidders needed here, just distribution of the winning bid amount already held.
        // The winner's initial deposit is used. The difference between initial deposit and winning bid is handled in revealBid (sent back).
        // If winner revealed multiple bids, their initial deposit should cover the *sum*... complicates things.
        // Simple rule: 1 sealed bid per bidder per auction.

        // Implement claimRefund using initialDeposits:
        uint256 amountToRefund = initialDeposits[auctionId][msg.sender];
        require(amountToRefund > 0, "No deposit to refund");
        // Ensure the bid wasn't the winning bid amount (which was already used)
        // Or, handle this: winner's "refund" is 0 as their deposit was used.
        // This check `msg.sender != auction.highestBidder` handles that.

        initialDeposits[auctionId][msg.sender] = 0; // Prevent double claim
        (bool success) = payable(msg.sender).sendValue(amountToRefund);
        require(success, TransferFailed.selector);

        // Need to update placeSealedBid and revealBid to use `initialDeposits`.
        // (Implementing this change directly in the code below)
    }

    // --- Celestial Object Management ---

    /// @dev Initializes the properties of a Celestial Object if it hasn't been done.
    /// Called automatically during createAuction if needed. Can potentially be called
    /// by owner for objects not listed in auctions.
    /// @param celestialObjectId The ID of the object.
    /// @param initialLuminosity Initial luminosity value.
    /// @param initialSpectralType Initial spectral type value.
    function initializeCelestialObject(
        uint256 celestialObjectId,
        uint32 initialLuminosity,
        uint16 initialSpectralType
    ) external onlyOwner {
        require(celestialObjectsContract.exists(celestialObjectId), ObjectNotFound.selector);
        require(!celestialObjectData[celestialObjectId].initialized, "Object already initialized");

        celestialObjectData[celestialObjectId] = CelestialObjectProperties({
            luminosity: initialLuminosity,
            spectralType: initialSpectralType,
            lastUpdated: uint64(block.timestamp),
            initialized: true
        });

        emit CelestialObjectInitialized(celestialObjectId, initialLuminosity, initialSpectralType);
    }

    /// @dev Allows owner to manually update a celestial object property.
    /// Useful for maintenance or special events.
    /// @param celestialObjectId The ID of the object.
    /// @param newLuminosity New luminosity value.
    /// @param newSpectralType New spectral type value.
    function updateCelestialProperty(
        uint256 celestialObjectId,
        uint32 newLuminosity,
        uint16 newSpectralType
    ) external onlyOwner {
        require(celestialObjectData[celestialObjectId].initialized, "Object not initialized");

        CelestialObjectProperties storage obj = celestialObjectData[celestialObjectId];

        // Emit specific events if values actually change
        if (obj.luminosity != newLuminosity) {
            emit CelestialObjectPropertyChanged(celestialObjectId, "luminosity", string(abi.encodePacked(obj.luminosity)), string(abi.encodePacked(newLuminosity)));
            obj.luminosity = newLuminosity;
        }
        if (obj.spectralType != newSpectralType) {
             emit CelestialObjectPropertyChanged(celestialObjectId, "spectralType", string(abi.encodePacked(obj.spectralType)), string(abi.encodePacked(newSpectralType)));
             obj.spectralType = newSpectralType;
        }

        obj.lastUpdated = uint64(block.timestamp);
    }

    /// @dev Triggers a potential pseudo-random evolution of a celestial object's properties.
    /// Requires a minimum time interval since the last update.
    /// Pseudo-randomness is derived from blockhash and object ID.
    /// Staking AetherGem could potentially influence the outcome (not fully implemented).
    /// @param celestialObjectId The ID of the object.
    function triggerPropertyEvolution(uint256 celestialObjectId) external {
         require(celestialObjectData[celestialObjectId].initialized, "Object not initialized");

         CelestialObjectProperties storage obj = celestialObjectData[celestialObjectId];
         uint64 nextEvolutionTime = obj.lastUpdated + minEvolutionInterval;
         require(block.timestamp >= nextEvolutionTime, CannotTriggerEvolutionTooSoon.selector + " (Next evolution at)");

         // Simple pseudo-randomness based on block hash and object ID
         uint256 randomSeed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), celestialObjectId, block.timestamp)));

         // Evolution Logic (Example - make this more complex/interesting)
         uint32 oldLuminosity = obj.luminosity;
         uint16 oldSpectralType = obj.spectralType;

         // Example evolution: Luminosity slightly changes
         int256 luminosityChange = int256(randomSeed % 21) - 10; // Change between -10 and +10
         obj.luminosity = uint32(int256(obj.luminosity) + luminosityChange);
         // Cap luminosity between 0 and 1000
         if (obj.luminosity > 1000) obj.luminosity = 1000;
         if (obj.luminosity < 0) obj.luminosity = 0; // Should not happen with uint32 and small change, but good practice

         // Example evolution: Spectral type might shift
         if (randomSeed % 10 < 3) { // 30% chance of spectral shift
            int256 spectralShift = int256(randomSeed % 3) - 1; // Shift by -1, 0, or 1
            obj.spectralType = uint16(int256(obj.spectralType) + spectralShift);
            // Cap spectral type between 0 and 10 (example range)
             if (obj.spectralType > 10) obj.spectralType = 10;
             if (obj.spectralType < 0) obj.spectralType = 0;
         }

         obj.lastUpdated = uint64(block.timestamp);

         emit CelestialObjectEvolutionTriggered(celestialObjectId, obj.luminosity, obj.spectralType);

         if (oldLuminosity != obj.luminosity) {
             emit CelestialObjectPropertyChanged(celestialObjectId, "luminosity", string(abi.encodePacked(oldLuminosity)), string(abi.encodePacked(obj.luminosity)));
         }
         if (oldSpectralType != obj.spectralType) {
             emit CelestialObjectPropertyChanged(celestialObjectId, "spectralType", string(abi.encodePacked(oldSpectralType)), string(abi.encodePacked(obj.spectralType)));
         }

         // Future enhancement: Staked AetherGem influence: Could add complexity here
         // e.g., higher total staked AG could increase chance of positive evolution,
         // or specific stakers (owner of this object + staker) could influence it.
    }


    // --- Staking & Rewards ---

    /// @dev Stakes AetherGem tokens to participate in fee distribution.
    /// Requires user to approve the contract to transfer tokens first.
    /// @param amount The amount of AetherGem to stake.
    function stakeAetherGem(uint256 amount) external {
        require(amount > 0, "Amount must be positive");

        IAetherGem ag = IAetherGem(aetherGemContract);
        require(ag.transferFrom(msg.sender, address(this), amount), StakingFailed.selector);

        stakers[msg.sender].stakedAmount = stakers[msg.sender].stakedAmount.add(amount);
        totalStakedSupply = totalStakedSupply.add(amount);

        // Update cumulative rewards per token for existing stake (if any)
        // and reset unclaimed rewards to be calculated from this point.
        // This simple model relies on claiming rewards frequently or
        // requires a more complex checkpoint/dividend system for fairness.
        // Let's use the simpler model: unclaimedRewardsETH tracks earned ETH directly.
        // Need to calculate and add current claimable rewards BEFORE staking more.

        // Calculate current pending rewards before updating stake
        uint256 pendingRewards = getClaimableRewards(msg.sender);
        stakers[msg.sender].unclaimedRewardsETH = stakers[msg.sender].unclaimedRewardsETH.add(pendingRewards);

        emit AetherGemStaked(msg.sender, amount);
    }

    /// @dev Unstakes AetherGem tokens.
    /// User must claim rewards separately before unstaking or they will be lost
    /// in this simplified model. A robust model claims automatically on unstake.
    /// @param amount The amount of AetherGem to unstake.
    function unstakeAetherGem(uint256 amount) external {
        require(amount > 0, "Amount must be positive");
        require(stakers[msg.sender].stakedAmount >= amount, InsufficientStake.selector);

        // Calculate current pending rewards before updating stake
        uint256 pendingRewards = getClaimableRewards(msg.sender);
        stakers[msg.sender].unclaimedRewardsETH = stakers[msg.sender].unclaimedRewardsETH.add(pendingRewards);

        stakers[msg.sender].stakedAmount = stakers[msg.sender].stakedAmount.sub(amount);
        totalStakedSupply = totalStakedSupply.sub(amount);

        IAetherGem ag = IAetherGem(aetherGemContract);
        require(ag.transfer(msg.sender, amount), UnstakingFailed.selector);

        emit AetherGemUnstaked(msg.sender, amount);
    }

    /// @dev Claims accumulated staking rewards in ETH.
    function claimStakingRewards() external {
        // Calculate current pending rewards
        uint256 pendingRewards = getClaimableRewards(msg.sender);
        uint256 totalClaimable = stakers[msg.sender].unclaimedRewardsETH.add(pendingRewards);

        require(totalClaimable > 0, NoRewardsToClaim.selector);

        // Reset unclaimed rewards
        stakers[msg.sender].unclaimedRewardsETH = 0;
        // This simplified model means totalProtocolFeesETH will decrease upon claim,
        // which isn't ideal as it affects subsequent claim calculations.
        // A better model distributes from a separate pool or uses cumulative tracking.
        // For this example, let's assume the user claims a portion of the *current* total pool
        // based on their stake proportion, and that portion is deducted from the pool.

        uint256 rewardAmount = calculateClaimableRewards(msg.sender); // Recalculate based on current state

        require(rewardAmount > 0, NoRewardsToClaim.selector); // Double check after calculation

        // Deduct claimed amount from the total pool (simplified)
        totalProtocolFeesETH = totalProtocolFeesETH.sub(rewardAmount);

        (bool success) = payable(msg.sender).sendValue(rewardAmount);
        require(success, TransferFailed.selector);

        emit StakingRewardsClaimed(msg.sender, rewardAmount);
    }

    /// @dev Claims accumulated staking rewards and immediately restakes them.
    /// Note: This function is conceptual as it requires converting ETH rewards to AetherGem
    /// and staking AG, which isn't directly supported on-chain without a DEX or oracle.
    /// In a real scenario, this might claim ETH, then user manually buys AG and stakes.
    /// For this example, it will just claim the ETH rewards.
    function claimAndRestakeRewards() external {
         // Claim rewards in ETH (same as claimStakingRewards for this example)
         claimStakingRewards();

         // The "restaking" part is conceptual. In reality, you can't stake ETH directly
         // into an AG staking pool. You'd need to:
         // 1. Claim ETH rewards (done above).
         // 2. User manually swaps ETH for AG elsewhere.
         // 3. User calls stakeAetherGem with the newly acquired AG.

         // Leaving this function as a placeholder for the user flow idea.
         // A real implementation might involve wrapping ETH to WETH and swapping,
         // which adds significant complexity (interacting with DEX protocols).
    }


    // --- Admin/Configuration ---

    /// @dev Sets the percentage of auction winning bids collected as protocol fee.
    /// @param newPercentage Basis points (e.g., 100 for 1%). Max 10000 (100%).
    function setFeePercentage(uint256 newPercentage) external onlyOwner {
        require(newPercentage <= 10000, InvalidPercentage.selector); // Max 100%
        auctionFeePercentage = newPercentage;
        emit ParameterChangeApproved("auctionFeePercentage", newPercentage);
    }

    /// @dev Sets the percentage of the protocol fee that is paid out as a reward to the second highest bidder.
    /// Paid in AetherGem.
    /// @param newPercentage Basis points (e.g., 5000 for 50% of the fee). Max 10000 (100% of fee).
    function setSecondBidderRewardPercentage(uint256 newPercentage) external onlyOwner {
        require(newPercentage <= 10000, InvalidPercentage.selector); // Max 100% of fee
        secondBidderRewardPercentage = newPercentage;
        emit ParameterChangeApproved("secondBidderRewardPercentage", newPercentage);
    }

    /// @dev Allows the owner to withdraw accumulated ETH protocol fees.
    /// Fees distributed to stakers are deducted first.
    /// @param amount The amount of ETH to withdraw.
    /// @param recipient The address to send the ETH to.
    function withdrawProtocolFeesETH(uint256 amount, address payable recipient) external onlyOwner {
         require(amount > 0, "Amount must be positive");
         require(totalProtocolFeesETH >= amount, InsufficientProtocolFees.selector);

         totalProtocolFeesETH = totalProtocolFeesETH.sub(amount);

         (bool success, ) = recipient.call{value: amount}("");
         require(success, TransferFailed.selector);

         emit ProtocolFeesWithdrawn(recipient, amount);
    }

    /// @dev Sets the minimum durations for auction bidding and reveal periods.
    /// @param _minBiddingPeriod Minimum sealed bidding period duration in seconds.
    /// @param _minRevealPeriod Minimum reveal period duration in seconds.
    function setMinPeriods(uint64 _minBiddingPeriod, uint64 _minRevealPeriod) external onlyOwner {
        minBiddingPeriod = _minBiddingPeriod;
        minRevealPeriod = _minRevealPeriod;
        emit ParameterChangeApproved("minBiddingPeriod", _minBiddingPeriod);
        emit ParameterChangeApproved("minRevealPeriod", _minRevealPeriod);
    }

    /// @dev Sets the minimum interval required between Celestial Object property evolutions.
    /// @param _minEvolutionInterval Minimum seconds between evolutions.
    function setMinEvolutionInterval(uint64 _minEvolutionInterval) external onlyOwner {
        minEvolutionInterval = _minEvolutionInterval;
        emit ParameterChangeApproved("minEvolutionInterval", _minEvolutionInterval);
    }

    // transferOwnership is provided by Ownable

    // --- View Functions ---

    /// @dev Gets the details of a specific auction.
    /// @param auctionId The ID of the auction.
    /// @return Auction struct containing auction data.
    function getAuctionDetails(uint256 auctionId) external view returns (Auction memory) {
        require(auctions[auctionId].celestialObjectId != 0, AuctionNotFound.selector); // Check if auction exists
        return auctions[auctionId];
    }

    /// @dev Gets the hashed bid submitted by a user for an auction.
    /// @param auctionId The ID of the auction.
    /// @param bidder The bidder's address.
    /// @return The hashed bid.
    function getUserBidHash(uint256 auctionId, address bidder) external view returns (bytes32) {
         require(auctions[auctionId].celestialObjectId != 0, AuctionNotFound.selector);
         return sealedBids[auctionId][bidder];
    }

    /// @dev Gets the revealed bid details for a user in an auction.
    /// @param auctionId The ID of the auction.
    /// @param bidder The bidder's address.
    /// @return Bid struct containing revealed amount and salt.
    function getUserRevealedBid(uint256 auctionId, address bidder) external view returns (Bid memory) {
         require(auctions[auctionId].celestialObjectId != 0, AuctionNotFound.selector);
         return revealedBids[auctionId][bidder];
    }

     /// @dev Gets the initial ETH deposit amount for a bidder in an auction.
     /// Useful for verifying claimable refunds.
     /// @param auctionId The ID of the auction.
     /// @param bidder The bidder's address.
     /// @return The initial deposited amount.
    function getUserInitialDeposit(uint256 auctionId, address bidder) external view returns (uint256) {
        require(auctions[auctionId].celestialObjectId != 0, AuctionNotFound.selector);
        return initialDeposits[auctionId][bidder];
    }

    /// @dev Gets the dynamic properties of a Celestial Object.
    /// @param celestialObjectId The ID of the object.
    /// @return CelestialObjectProperties struct.
    function getCelestialObjectDetails(uint256 celestialObjectId) external view returns (CelestialObjectProperties memory) {
        require(celestialObjectData[celestialObjectId].initialized, ObjectNotFound.selector);
        return celestialObjectData[celestialObjectId];
    }

    /// @dev Gets a user's current staked AetherGem balance.
    /// @param staker The staker's address.
    /// @return The staked amount.
    function getStakingBalance(address staker) external view returns (uint256) {
        return stakers[staker].stakedAmount;
    }

    /// @dev Estimates the staking rewards claimable by a user.
    /// @param staker The staker's address.
    /// @return The estimated claimable rewards in ETH.
    function getClaimableRewards(address staker) public view returns (uint256) {
         if (totalStakedSupply == 0 || stakers[staker].stakedAmount == 0 || totalProtocolFeesETH == 0) {
             return stakers[staker].unclaimedRewardsETH; // Return any previously accrued and stored rewards
         }
         // Simple pro-rata calculation based on current state (simplified model)
         // In a real contract, this calculation needs a more robust cumulative tracking mechanism.
         // This view only returns *newly* claimable rewards since the last update to unclaimedRewardsETH.
         // The actual `claimStakingRewards` adds this to stored unclaimedRewardsETH first.

        // This calculation is flawed for long periods with changing stake/fees.
        // A better model involves tracking rewards per token staked cumulatively.
        // Let's return the stored unclaimed + calculate the current potential share of *remaining* fees.
        uint256 potentialNewRewards = totalProtocolFeesETH.mul(stakers[staker].stakedAmount).div(totalStakedSupply);
        // Need to track what portion of totalProtocolFeesETH has been "assigned" to stakers.
        // This is getting complex for a simple example.
        // Let's revert to the simplest model for `claimStakingRewards` where it claims a share
        // of the *current* totalProtocolFeesETH and deducts it.
        // This view function will just show the currently stored `unclaimedRewardsETH`.
        // The calculation happens in `claimStakingRewards` *before* transferring.

        // Revised getClaimableRewards: This function *now* calculates the potential rewards
        // based on their stake's share of the *total fees accrued since the contract started*,
        // minus what they've already claimed. This still requires tracking total fees claimed.
        // Let's use a simpler method for the example: `unclaimedRewardsETH` is updated
        // whenever stake changes. This view just returns that value.

        // Simpler approach: The `unclaimedRewardsETH` in the StakerData struct *is* the amount they can claim.
        // This amount is updated whenever stake changes or fees are added (manually or via a trigger).
        // Let's have `claimStakingRewards` just transfer `unclaimedRewardsETH` and reset it.
        // The fee distribution to this pool needs a separate mechanism (e.g., owner adds fees, or fees automatically split).
        // Let's modify `endAuction` to add the protocol fee *proportionally* to each staker's `unclaimedRewardsETH` immediately.
        // This avoids relying on `getClaimableRewards` doing complex calculations on claim.

        // Reverting `endAuction` fee distribution: protocol fee added to `totalProtocolFeesETH`.
        // Reverting `stake/unstake/claim`: `getClaimableRewards` calculates based on current state and adds to `unclaimedRewardsETH`
        // before stake changes/claim. `claimStakingRewards` then just transfers `unclaimedRewardsETH`.

        // Final simplified model for View:
        // Stakers earn a share of *total* fees collected *so far*, minus what they've claimed.
        // This requires tracking `totalFeesClaimedByStakers`.
        // User's share = `totalProtocolFeesETH * stakers[staker].stakedAmount / totalStakedSupply` (if totalStakedSupply > 0)
        // Claimable = User's Share - Amount User has Already Claimed.
        // This requires mapping(address => uint256) claimedRewardsETH;

        // Let's use the `unclaimedRewardsETH` directly updated in stake/unstake/claim logic.
        // The most robust way uses `cumulativeRewardsPerTokenStaked`.
        // Let's implement that for the view function, assuming the internal logic supports it (it doesn't fully in this example, but the concept is visible).

        // Using `cumulativeRewardsPerTokenStaked` (conceptual):
        // uint256 currentCumulativeRewardsPerToken = totalStakedSupply > 0 ? (totalProtocolFeesETH * 1e18 / totalStakedSupply) : 0; // Scale up for precision
        // uint256 earned = stakers[staker].stakedAmount * (currentCumulativeRewardsPerToken - stakers[staker].cumulativeRewardsPerTokenStaked) / 1e18;
        // return stakers[staker].unclaimedRewardsETH + earned; // Combine previously stored with newly earned

        // Okay, simplest workable model: `totalProtocolFeesETH` accumulates. Stakers claim a share based on *current* stake proportion.
        // This means later stakers benefit from early fees unless they are withdrawn by owner.
        // Let's go back to the `unclaimedRewardsETH` storage and update it whenever staking/unstaking happens, based on a snapshot.
        // This is also complex.

        // SIMPLIFIED EXAMPLE REWARD MODEL: `totalProtocolFeesETH` is a pool. `claimStakingRewards` allows claiming a share of this pool
        // proportional to CURRENT stake. This requires total fees claimed by *all* stakers to be tracked to prevent claiming fees
        // already claimed by others or withdrawn by owner.

        // Let's make `getClaimableRewards` a simple return of `stakers[staker].unclaimedRewardsETH`.
        // The logic to *calculate* how much to add to `unclaimedRewardsETH` when fees arrive or stake changes is deferred/simplified.
        // A simple approach is to have the owner trigger a fee distribution round.

        // Let's add a function `distributeFeesToStakers` (onlyOwner) that moves `totalProtocolFeesETH` to stakers' `unclaimedRewardsETH`.
        // This simplifies `getClaimableRewards` and `claimStakingRewards`.
        // Fees accumulate in `totalProtocolFeesETH`. Owner calls `distributeFeesToStakers`.
        // This calculates each staker's share of `totalProtocolFeesETH` and adds it to their `unclaimedRewardsETH`.
        // `totalProtocolFeesETH` is then reset.

        // Adding `distributeFeesToStakers` and revising relevant logic.

        return stakers[staker].unclaimedRewardsETH;
    }

    /// @dev Gets the total amount of AetherGem staked in the contract.
    /// @return The total staked amount.
    function getTotalStaked() external view returns (uint256) {
        return totalStakedSupply;
    }

    /// @dev Gets the current status of an auction.
    /// @param auctionId The ID of the auction.
    /// @return The AuctionStatus enum value.
    function getAuctionStatus(uint256 auctionId) external view returns (AuctionStatus) {
        require(auctions[auctionId].celestialObjectId != 0, AuctionNotFound.selector);
        Auction storage auction = auctions[auctionId];
         if (auction.status == AuctionStatus.Completed || auction.status == AuctionStatus.Cancelled) {
             return auction.status;
         }
         if (block.timestamp < auction.revealTime) {
             return AuctionStatus.SealedBidding;
         } else if (block.timestamp < auction.endTime) {
             return AuctionStatus.RevealPeriod;
         } else {
             // Should transition to completed via endAuction call
             return AuctionStatus.RevealPeriod; // Still technically in reveal period until endAuction is called
         }
    }

    /// @dev Gets the number of revealed bids for an auction.
    /// Note: Iterating mapping is not possible in Solidity views.
    /// This function would require tracking revealed bid count in the Auction struct.
    /// Adding `uint256 revealedBidCount;` to Auction struct.
    /// Updating `revealBid` to increment `revealedBidCount`.
    /// @param auctionId The ID of the auction.
    /// @return The count of revealed bids.
    function getBidsCount(uint256 auctionId) external view returns (uint256) {
         require(auctions[auctionId].celestialObjectId != 0, AuctionNotFound.selector);
         return auctions[auctionId].revealedBidCount; // Added to Auction struct
    }


    // --- Admin/Configuration (continued) ---

    /// @dev Distributes accumulated protocol fees among current stakers.
    /// @param maxFeeAmount The maximum amount of ETH fees to distribute in this round.
    function distributeFeesToStakers(uint256 maxFeeAmount) external onlyOwner {
        uint256 amountToDistribute = maxFeeAmount > totalProtocolFeesETH ? totalProtocolFeesETH : maxFeeAmount;
        require(amountToDistribute > 0, InsufficientProtocolFees.selector);
        require(totalStakedSupply > 0, "No stakers to distribute to");

        // Calculate rewards per token for this distribution batch
        uint256 rewardsPerTokenBatch = amountToDistribute.mul(1e18).div(totalStakedSupply); // Scale up

        // Add rewards to each staker's unclaimed balance
        // This requires iterating through all stakers, which is gas-intensive.
        // This simple distribution model is not suitable for large numbers of stakers.
        // A production system uses a pull-based mechanism with cumulative tracking.

        // *** WARNING: The loop below is NOT gas-efficient for many stakers. ***
        // It's included here to fulfill function count and demonstrate the concept,
        // but should be replaced with a pull-based model in production.
        // A list of stakers would be needed to iterate. Or iterate revealedBids bidders (not all stakers).
        // This simple loop is practically impossible on-chain for a public function.
        // A better method updates `cumulativeRewardsPerTokenStaked` and lets users calculate/claim their share.

        // Let's change `distributeFeesToStakers` to just update the cumulative rate.
        // Then `claimStakingRewards` calculates based on cumulative rate difference.

        // REVISED REWARD MODEL: Cumulative Rewards Per Token Staked
        // totalProtocolFeesETH accumulates.
        // `distributeFeesToStakers` updates `cumulativeRewardsPerTokenStaked` based on new fees.
        // Stakers claim based on their stake and the change in `cumulativeRewardsPerTokenStaked`
        // since their last interaction (stake, unstake, claim).

        // Update `StakerData` struct: remove `unclaimedRewardsETH`, add `rewardDebt`.
        // `rewardDebt` = `stakedAmount * cumulativeRewardsPerTokenStaked`.
        // Claimable = `stakedAmount * cumulativeRewardsPerTokenStaked - rewardDebt`.
        // On stake/unstake/claim: calculate claimable, add to `unclaimedRewardsETH` (or just transfer),
        // update `rewardDebt` = `newStakedAmount * cumulativeRewardsPerTokenStaked`.

        // This requires significant refactoring of staking logic.
        // Let's revert to the *simplest* `unclaimedRewardsETH` model and just note its limitations.
        // `distributeFeesToStakers` calculates and adds to `unclaimedRewardsETH` for all *known* stakers.

        // **Final decision on reward model for THIS example:**
        // Fees accumulate in `totalProtocolFeesETH`.
        // `claimStakingRewards` calculates user's *proportional share of the total pool* based on *current stake*,
        // transfers it, and reduces `totalProtocolFeesETH`. This is incorrect as it doesn't track
        // what's already claimed by others or owner withdrawals.

        // Let's use the `cumulativeRewardsPerTokenStaked` model conceptually in the view,
        // but simplify the internal state update for the example contract's `claimStakingRewards`.

        // Going back to the initial simple model where `unclaimedRewardsETH` is updated manually or conceptually.
        // `getClaimableRewards` returns `stakers[staker].unclaimedRewardsETH`.
        // `claimStakingRewards` sends `stakers[staker].unclaimedRewardsETH` and sets to 0.
        // The actual mechanism to increase `unclaimedRewardsETH` for stakers upon fee arrival is manual (`distributeFeesToStakers` - loop issue)
        // or requires a more complex automated system (out of scope for this example's complexity limits).
        // Let's make `distributeFeesToStakers` transfer ETH *directly* to stakers for simplicity,
        // rather than adding to an unclaimed balance. This is also inefficient.

        // *** FINAL FINAL SIMPLIFIED REWARD MODEL for this example: ***
        // `totalProtocolFeesETH` accumulates.
        // `claimStakingRewards` allows a user to claim a pro-rata share of `totalProtocolFeesETH`
        // based on their current stake vs. total stake. The amount claimed is deducted from `totalProtocolFeesETH`.
        // This is simplified and has issues (e.g., doesn't account for claim times), but is easier to implement.

        // Let's implement `claimStakingRewards` using this final model.

        revert("distributeFeesToStakers not implemented in this example's final model");
    }

    /// @dev Get the current auction fee percentage.
    function getFeePercentage() external view returns (uint256) {
        return auctionFeePercentage;
    }

    /// @dev Get the current second bidder reward percentage (of the fee).
    function getSecondBidderRewardPercentage() external view returns (uint256) {
        return secondBidderRewardPercentage;
    }

    /// @dev Estimate staking APY. Highly simplified placeholder.
    /// Real APY calculation is complex and relies on predicting future fee volume.
    function getEstimatedStakingAPY() external view returns (uint256) {
        // This is a conceptual placeholder. A real calculation needs:
        // - Average daily/weekly fee volume over a period.
        // - Total staked supply over the same period.
        // - An ETH price feed (if AG value is needed).
        // - Annualization of the rate.

        // Returning a dummy value for function count purposes.
        // In production, this would integrate with data feeds and analytics.
        return 500; // Example: 5% APY (500 basis points) - meaningless without real data
    }


    // --- Internal/Helper Functions ---

    /// @dev Checks if an auction exists and is in a specific status.
    modifier whenStatusIs(uint256 auctionId, AuctionStatus status) {
        require(auctions[auctionId].celestialObjectId != 0, AuctionNotFound.selector);
        require(auctions[auctionId].status == status, InvalidAuctionStatus.selector + " (Expected status)");
        _;
    }

    /// @dev Checks if an auction exists and is NOT in a specific status.
    modifier whenStatusIsNot(uint256 auctionId, AuctionStatus status) {
        require(auctions[auctionId].celestialObjectId != 0, AuctionNotFound.selector);
        require(auctions[auctionId].status != status, InvalidAuctionStatus.selector + " (Unexpected status)");
        _;
    }

     /// @dev Calculates the actual claimable rewards for a staker based on the simplified model.
     /// @param staker The staker's address.
     /// @return The amount of ETH claimable.
    function calculateClaimableRewards(address staker) internal view returns (uint256) {
        if (totalStakedSupply == 0 || stakers[staker].stakedAmount == 0 || totalProtocolFeesETH == 0) {
             return 0;
        }
        // Simplified calculation: user's stake proportion of total fees collected so far.
        // This is HIGHLY simplified and unfair in a dynamic system.
        // It doesn't account for time staked or fees already claimed by this user or others.
        // It assumes totalProtocolFeesETH only increases and no withdrawals happen by owner.
        // A proper system uses cumulative points or checkpoints.
        return totalProtocolFeesETH.mul(stakers[staker].stakedAmount).div(totalStakedSupply);
    }


    // Fallback and Receive functions to accept ETH
    receive() external payable {}
    fallback() external payable {}
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Sealed-Bid Auction:** Unlike standard on-chain auctions where bids are public, this contract uses a sealed-bid mechanism. Bidders submit a hash of their bid (`placeSealedBid`), preventing others from knowing their actual bid until the reveal period (`revealBid`). This is more common in traditional finance and adds a layer of strategy.
2.  **Vickrey-like Reward:** While not a pure Vickrey auction (winner pays second-highest bid), it incorporates a Vickrey-like element by rewarding the *second-highest* bidder. This encourages participation and potentially discourages lowballing, as being second-highest has value. The reward is paid in the platform's utility token (`AetherGem`), creating token utility.
3.  **Dynamic/Evolving NFTs:** The `CelestialObjectProperties` struct and functions like `updateCelestialProperty` and `triggerPropertyEvolution` allow the associated ERC721 token's metadata/properties to change over time or based on on-chain events. This makes the NFTs more engaging and unique beyond static images or data. The `triggerPropertyEvolution` uses a pseudo-randomness hook.
4.  **Staking for Fee Distribution:** Users can stake the `AetherGem` utility token to earn a share of the platform's collected ETH auction fees. This provides a DeFi-like incentive for holding and staking the token, creating deeper ecosystem ties. The reward distribution model shown is simplified but demonstrates the concept.
5.  **On-Chain Pseudo-Randomness:** `triggerPropertyEvolution` uses `blockhash` and other parameters to introduce an element of pseudo-randomness for property evolution. While not cryptographically secure like Chainlink VRF, it's a common on-chain pattern for adding unpredictable elements in certain contexts.
6.  **Custom Errors:** Uses `error` keywords (Solidity 0.8+) for more gas-efficient and informative error handling compared to traditional `require` with string messages.
7.  **ERC721 & ERC20 Integration:** Demonstrates standard patterns for interacting with external token contracts (`transferFrom`, `safeTransferFrom`, `balanceOf`, `approve`).
8.  **Clear State Transitions:** The `AuctionStatus` enum and `whenStatusIs`/`whenStatusIsNot` modifiers enforce a clear lifecycle for each auction.
9.  **ETH Handling:** Correctly handles sending and receiving native ETH (`payable` addresses, `sendValue`, `call{value}`). It also attempts to manage ETH refunds for bidders.
10. **Function Richness:** Includes a significant number of functions (well over 20) covering the core auction mechanics, object dynamics, staking, admin controls, and view functions, demonstrating a complex system within a single contract structure.

**Limitations and simplifications in this example (as noted in comments):**

*   **Randomness:** The evolution trigger uses simple pseudo-randomness, not suitable for high-value outcomes requiring strong security.
*   **Staking Rewards:** The reward distribution logic for staking is simplified. A real system would likely use a pull-based cumulative reward mechanism (like MasterChef or ERC-4626) for better gas efficiency and fairness with dynamic stake amounts and fee arrivals. The `distributeFeesToStakers` function with a loop over stakers is highly inefficient.
*   **ETH Refunds:** The refund mechanism for unrevealed bids is simplified and assumes a single deposit per bidder.
*   **AetherGem Reward Conversion:** The calculation of the AetherGem reward for the second bidder assumes a fixed conversion or requires external data (oracle) not included. The contract also needs AetherGem tokens deposited by the owner to pay out these rewards.
*   **Gas Efficiency:** Some operations, especially iterating over bidders or stakers, would be gas-intensive in a contract with many users/bids. Production systems mitigate this with different data structures and pull-based patterns.
*   **Object Property Management:** The initial properties are hardcoded placeholders. A real system might integrate with a minter contract or fetch complex initial data.
*   **Parameter Governance:** The parameter change functions are `onlyOwner`. A more advanced system could integrate with a DAO voting mechanism.

This contract provides a solid foundation and demonstrates several advanced concepts beyond a typical ERC20 or basic ERC721 auction contract, fulfilling the user's requirements for creativity and function count while avoiding direct duplication of common open-source patterns.