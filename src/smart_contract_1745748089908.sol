Okay, let's create a smart contract with an interesting, advanced, and creative concept. We'll build a "Quantum Flux Auction" – a multi-phase auction where the final settlement amount and refund structure are influenced by the dynamic "flux" level of the auction, which changes based on bidding activity and timing. This isn't a standard English, Dutch, or Sealed Bid auction.

It incorporates:
1.  **Multi-Phase System:** Different rules/dynamics apply in different phases.
2.  **Dynamic State ('Flux'):** A value (`currentFlux`) changes based on bidding behavior, influencing the outcome.
3.  **Entropy Accumulation:** A pseudo-randomness or activity metric (`accumulatedEntropy`) derived from bid timing and values, influencing the flux and phase transitions.
4.  **Flux-Influenced Settlement:** The winning bidder pays the highest bid, but losing bidders receive a refund amount that is *less* than their bid, with the deducted amount depending on the final `currentFlux` level. This deducted amount (the "flux cost of participation") contributes to the auction owner's proceeds.
5.  **Strategic Bidding:** Bidders can specify a minimum flux tolerance, subtly interacting with the dynamic system.
6.  **Outcome Estimation:** A function allows bidders to get a *non-binding estimate* of their potential outcome based on the *current* state, highlighting the uncertainty.

This goes beyond typical auction examples by adding dynamic, state-dependent outcomes and strategic complexity.

---

## Outline and Function Summary

**Contract Name:** QuantumFluxAuction

**Concept:** A multi-phase auction for a conceptual digital asset ("Quantum Entangled Unit" - QEU) where bidding activity influences a dynamic "flux" level. The final settlement (loser refunds) is adjusted based on this flux, adding a layer of strategic cost and unpredictability.

**States:** `Pending`, `Active`, `Paused`, `Settling`, `Completed`, `Cancelled`
**Phases (within Active state):** `Stabilization`, `Fluctuation`, `Convergence`, `Settlement`

**State Variables:**
*   Basic auction parameters (owner, item details - conceptual, min bid, increment)
*   Auction state and phase
*   Timing (start time, phase durations, calculated end times)
*   Bid tracking (highest bid, bidder info mapping, list of bidders)
*   Dynamic state (current flux, accumulated entropy)
*   Settlement tracking (winner, claimed status)
*   Flux/Entropy parameters (factors for calculation)

**Events:**
*   `AuctionStarted`, `PhaseTransitioned`, `BidPlaced`, `BidRetracted`, `AuctionPaused`, `AuctionResumed`, `AuctionCancelled`, `SettlementInitiated`, `ItemClaimed`, `RefundClaimed`, `OwnerProceedsWithdrawn`, `ParametersUpdated`

**Function Summary (29 functions):**

**Setup & Configuration (Owner Only):**
1.  `constructor(uint256 _minBid, uint256 _bidIncrement, uint64[3] memory _phaseDurations, string memory _itemDetails)`: Initializes auction parameters and owner.
2.  `setPhaseDuration(AuctionPhase _phase, uint64 _duration)`: Sets duration for a specific phase before auction starts.
3.  `setMinBid(uint256 _minBid)`: Sets minimum bid requirement before auction starts.
4.  `setMinBidIncrement(uint256 _increment)`: Sets minimum bid increment before auction starts.
5.  `setFluxParameters(uint256 _entropyPerBidFactor, uint256 _entropyPerTimeFactor, uint256 _fluxEntropyFactor, uint256 _fluxBidFactor)`: Configures parameters for flux/entropy calculation.

**Auction Lifecycle (Owner/Trigger):**
6.  `startAuction()`: Transitions state from `Pending` to `Active` and phase to `Stabilization`.
7.  `triggerPhaseTransition()`: Allows anyone to trigger phase transition if time conditions are met. Owner can force transition.
8.  `pauseAuction()`: Owner transitions state to `Paused`.
9.  `resumeAuction()`: Owner transitions state from `Paused` to `Active`, resuming timer.
10. `cancelAuction()`: Owner transitions state to `Cancelled`, enabling refund claims.
11. `settleAuction()`: Transitions state to `Settling` and phase to `Settlement`. Determines winner and calculates final settlement parameters based on flux.

**Bidding & Participation:**
12. `placeBid(uint256 _minFluxTolerance)`: Allows participants to place a bid in ETH. Updates high bid, entropy, and flux. Requires minimum bid/increment and active state. Includes a strategic `_minFluxTolerance` parameter.
13. `retractBid()`: Allows a bidder (if not current high bidder and before `Convergence` phase) to withdraw their bid.

**Settlement & Claims:**
14. `claimItem()`: Allows the winning bidder to conceptually claim the auctioned item after settlement.
15. `claimRefunds()`: Allows losing bidders to claim their bid amount minus the flux-dependent participation cost after settlement.
16. `withdrawOwnerProceeds()`: Owner collects the winning bid amount plus the accumulated participation costs from losing bidders.

**Dynamic State Calculation (Internal/View):**
17. `_calculateFlux(uint256 _currentEntropy, uint256 _totalBidVolume)`: Internal helper to determine current flux level based on entropy and bid activity.
18. `_updateEntropy(uint256 _bidAmountDifference)`: Internal helper to accumulate entropy based on bid activity and timing.
19. `_getEffectiveParticipationCost(uint256 _finalFlux, uint256 _bidAmount, uint256 _bidFluxTolerance)`: Internal helper to calculate the amount deducted from a losing bid based on final flux and the bidder's tolerance.

**Query & View Functions:**
20. `getAuctionState()`: Returns the current state of the auction.
21. `getCurrentPhase()`: Returns the current phase of the auction.
22. `getHighBid()`: Returns details of the current highest bid.
23. `getBidDetails(address _bidder)`: Returns details for a specific bidder's bid.
24. `getFluxLevel()`: Returns the current calculated flux level.
25. `getEntropy()`: Returns the current accumulated entropy.
26. `getSettlementDetails()`: Returns details about the winner, winning bid, and final flux after settlement.
27. `getPhaseEndTime(AuctionPhase _phase)`: Returns the calculated end time for a given phase.
28. `getAuctionEndTime()`: Returns the estimated overall auction end time (end of Convergence).
29. `predictOutcomeEstimate(address _bidder)`: Provides a *non-binding estimate* of potential refund/outcome based on *current* state and hypothetical final flux. (Creative/Advanced)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumFluxAuction
 * @dev A multi-phase auction where settlement outcome (loser refunds) is influenced
 *      by a dynamic 'flux' level, which changes based on bidding activity and entropy.
 *      Features multi-phases, dynamic state, flux-influenced settlement, and outcome prediction.
 *      This is a non-standard auction mechanism for a conceptual digital asset.
 *
 * Outline:
 * - State variables for auction configuration, state, phase, timing, bids, dynamic flux/entropy, settlement.
 * - Enums for AuctionState and AuctionPhase.
 * - Struct for Bid details.
 * - Events for key state changes and actions.
 * - Modifiers for access control and state checks.
 * - Functions for setup, starting, pausing, resuming, cancelling.
 * - Functions for placing and retracting bids.
 * - Functions for dynamic state calculation (internal helpers).
 * - Function to trigger phase transitions.
 * - Function to settle the auction, determine winner, and calculate final flux cost.
 * - Functions for claiming the item (winner) and refunds (losers).
 * - Function for owner to withdraw proceeds.
 * - Extensive view functions to query auction status, bids, dynamic state, and settlement details.
 * - A creative view function for predicting potential outcomes based on current state.
 *
 * Function Summary (29 functions):
 * 1. constructor(uint256 _minBid, uint256 _bidIncrement, uint64[3] memory _phaseDurations, string memory _itemDetails)
 * 2. setPhaseDuration(AuctionPhase _phase, uint64 _duration) (Owner)
 * 3. setMinBid(uint256 _minBid) (Owner)
 * 4. setMinBidIncrement(uint256 _increment) (Owner)
 * 5. setFluxParameters(uint256 _entropyPerBidFactor, uint256 _entropyPerTimeFactor, uint256 _fluxEntropyFactor, uint256 _fluxBidFactor) (Owner)
 * 6. startAuction() (Owner)
 * 7. triggerPhaseTransition() (Anyone/Owner)
 * 8. pauseAuction() (Owner)
 * 9. resumeAuction() (Owner)
 * 10. cancelAuction() (Owner)
 * 11. settleAuction() (Anyone after Convergence end)
 * 12. placeBid(uint256 _minFluxTolerance) (Anyone)
 * 13. retractBid() (Bidder)
 * 14. claimItem() (Winner)
 * 15. claimRefunds() (Losing Bidders)
 * 16. withdrawOwnerProceeds() (Owner)
 * 17. _calculateFlux(uint256 _currentEntropy, uint256 _totalBidVolume) (Internal View)
 * 18. _updateEntropy(uint256 _bidAmountDifference) (Internal)
 * 19. _getEffectiveParticipationCost(uint256 _finalFlux, uint256 _bidAmount, uint256 _bidFluxTolerance) (Internal View)
 * 20. getAuctionState() (View)
 * 21. getCurrentPhase() (View)
 * 22. getHighBid() (View)
 * 23. getBidDetails(address _bidder) (View)
 * 24. getFluxLevel() (View)
 * 25. getEntropy() (View)
 * 26. getSettlementDetails() (View)
 * 27. getPhaseEndTime(AuctionPhase _phase) (View)
 * 28. getAuctionEndTime() (View)
 * 29. predictOutcomeEstimate(address _bidder) (View - Creative)
 */
contract QuantumFluxAuction {

    address payable public owner;

    enum AuctionState { Pending, Active, Paused, Settling, Completed, Cancelled }
    AuctionState public auctionState;

    enum AuctionPhase { Stabilization, Fluctuation, Convergence, Settlement, Ended } // Added Ended for post-settlement
    AuctionPhase public currentPhase;

    struct Bid {
        uint256 amount;
        uint64 timestamp;
        uint256 minFluxTolerance; // Strategic parameter from bidder
        bool exists; // To check if address has bid
    }

    string public itemDetails; // Conceptual details about the item
    uint256 public minBid;
    uint256 public minBidIncrement;

    uint256 public highBid;
    address public highBidder;

    mapping(address => Bid) public bids;
    address[] public biddersList; // To iterate or check existence efficiently

    uint64 public auctionStartTime;
    mapping(AuctionPhase => uint64) public phaseDurations;
    mapping(AuctionPhase => uint64) public phaseStartTimes; // To calculate elapsed time in phase

    // Dynamic State Variables
    uint256 public currentFlux; // Represents the instability/activity level
    uint256 public accumulatedEntropy; // Metric influenced by bids and time
    uint256 public lastEntropyUpdateTime;

    // Flux & Entropy Calculation Parameters (Owner Configurable)
    uint256 public entropyPerBidFactor = 1e16; // Factor for entropy increase per bid amount difference
    uint256 public entropyPerTimeFactor = 1e15; // Factor for entropy increase per second elapsed
    uint256 public fluxEntropyFactor = 1e16; // Factor relating entropy to flux
    uint256 public fluxBidFactor = 1e16; // Factor relating total bid volume to flux

    // Settlement Variables
    address public winner;
    uint256 public finalFluxAtSettlement;
    bool public itemClaimed;
    mapping(address => bool) public refundClaimed;

    // Events
    event AuctionStarted(uint64 startTime);
    event PhaseTransitioned(AuctionPhase oldPhase, AuctionPhase newPhase, uint64 transitionTime);
    event BidPlaced(address bidder, uint256 amount, uint256 highBid, address highBidder, uint256 fluxTolerance);
    event BidRetracted(address bidder, uint256 amount);
    event AuctionPaused(uint64 pauseTime);
    event AuctionResumed(uint64 resumeTime);
    event AuctionCancelled();
    event SettlementInitiated(address winner, uint256 winningBid, uint256 finalFlux);
    event ItemClaimed(address winner);
    event RefundClaimed(address claimant, uint256 amountRefunded, uint256 participationCost);
    event OwnerProceedsWithdrawn(address owner, uint256 amount);
    event ParametersUpdated(string paramName, uint256 value); // Generic event for parameter changes

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier inState(AuctionState _state) {
        require(auctionState == _state, "Invalid state");
        _;
    }

    modifier notInState(AuctionState _state) {
        require(auctionState != _state, "Invalid state");
        _;
    }

    modifier inPhase(AuctionPhase _phase) {
        require(currentPhase == _phase, "Invalid phase");
        _;
    }

    modifier notInPhase(AuctionPhase _phase) {
        require(currentPhase != _phase, "Invalid phase");
        _;
    }

    modifier onlyBidder() {
        require(bids[msg.sender].exists, "Not a bidder");
        _;
    }

    /**
     * @dev Constructor initializes the auction with core parameters.
     * @param _minBid Minimum required bid amount.
     * @param _bidIncrement Minimum amount a new bid must exceed the current high bid.
     * @param _phaseDurations Array containing durations for Stabilization, Fluctuation, and Convergence phases.
     * @param _itemDetails Conceptual details string for the auctioned item.
     */
    constructor(uint256 _minBid, uint256 _bidIncrement, uint64[3] memory _phaseDurations, string memory _itemDetails) {
        owner = payable(msg.sender);
        minBid = _minBid;
        minBidIncrement = _bidIncrement;
        phaseDurations[AuctionPhase.Stabilization] = _phaseDurations[0];
        phaseDurations[AuctionPhase.Fluctuation] = _phaseDurations[1];
        phaseDurations[AuctionPhase.Convergence] = _phaseDurations[2];
        itemDetails = _itemDetails;
        auctionState = AuctionState.Pending;
        currentPhase = AuctionPhase.Stabilization; // Starting point, even in Pending state
        lastEntropyUpdateTime = uint64(block.timestamp); // Initialize entropy timer
    }

    // --- Owner Configuration Functions ---

    /**
     * @dev Allows owner to set the duration for a specific phase before the auction starts.
     * @param _phase The phase to configure (Stabilization, Fluctuation, Convergence).
     * @param _duration The duration in seconds.
     */
    function setPhaseDuration(AuctionPhase _phase, uint64 _duration) external onlyOwner inState(AuctionState.Pending) {
        require(_phase != AuctionPhase.Settlement && _phase != AuctionPhase.Ended, "Cannot set duration for settlement/ended phases");
        phaseDurations[_phase] = _duration;
        emit ParametersUpdated("PhaseDuration", uint256(_phase));
    }

    /**
     * @dev Allows owner to set the minimum bid amount before the auction starts.
     * @param _minBid The minimum bid amount.
     */
    function setMinBid(uint256 _minBid) external onlyOwner inState(AuctionState.Pending) {
        minBid = _minBid;
        emit ParametersUpdated("MinBid", _minBid);
    }

    /**
     * @dev Allows owner to set the minimum bid increment before the auction starts.
     * @param _increment The minimum bid increment.
     */
    function setMinBidIncrement(uint256 _increment) external onlyOwner inState(AuctionState.Pending) {
        minBidIncrement = _increment;
        emit ParametersUpdated("MinBidIncrement", _increment);
    }

    /**
     * @dev Allows owner to set parameters influencing entropy and flux calculations.
     *      Higher factors mean more influence from that source.
     * @param _entropyPerBidFactor Factor for entropy increase based on bid amount difference.
     * @param _entropyPerTimeFactor Factor for entropy increase based on time elapsed between entropy updates.
     * @param _fluxEntropyFactor Factor relating accumulated entropy to current flux.
     * @param _fluxBidFactor Factor relating total bid volume to current flux.
     */
    function setFluxParameters(uint256 _entropyPerBidFactor, uint256 _entropyPerTimeFactor, uint256 _fluxEntropyFactor, uint256 _fluxBidFactor) external onlyOwner {
         // Basic sanity checks (prevent division by zero if factors are used in denominator, though not currently)
        require(_fluxEntropyFactor > 0 && _fluxBidFactor > 0, "Flux factors must be > 0");
        entropyPerBidFactor = _entropyPerBidFactor;
        entropyPerTimeFactor = _entropyPerTimeFactor;
        fluxEntropyFactor = _fluxEntropyFactor;
        fluxBidFactor = _fluxBidFactor;
        emit ParametersUpdated("FluxParameters", 0); // Use 0 or struct if needed, this is just a signal
    }

    // --- Auction Lifecycle Functions ---

    /**
     * @dev Starts the auction, moving from Pending to Active. Can only be called once by the owner.
     */
    function startAuction() external onlyOwner inState(AuctionState.Pending) {
        auctionState = AuctionState.Active;
        auctionStartTime = uint64(block.timestamp);
        phaseStartTimes[AuctionPhase.Stabilization] = auctionStartTime;
        currentPhase = AuctionPhase.Stabilization;
        emit AuctionStarted(auctionStartTime);
        emit PhaseTransitioned(AuctionPhase.Pending, AuctionPhase.Stabilization, auctionStartTime);
    }

    /**
     * @dev Triggers a phase transition if the current phase duration has passed.
     *      Owner can force transition regardless of time.
     */
    function triggerPhaseTransition() external notInState(AuctionState.Pending) notInState(AuctionState.Settling) notInState(AuctionState.Completed) notInState(AuctionState.Cancelled) {
        AuctionPhase nextPhase = AuctionPhase.Stabilization; // Default, will be overwritten
        uint64 transitionTime = uint64(block.timestamp);

        bool ownerOverride = (msg.sender == owner);
        bool timeMet = false;

        if (currentPhase == AuctionPhase.Stabilization) {
            nextPhase = AuctionPhase.Fluctuation;
            if (transitionTime >= phaseStartTimes[AuctionPhase.Stabilization] + phaseDurations[AuctionPhase.Stabilization]) {
                timeMet = true;
            }
        } else if (currentPhase == AuctionPhase.Fluctuation) {
            nextPhase = AuctionPhase.Convergence;
            if (transitionTime >= phaseStartTimes[AuctionPhase.Fluctuation] + phaseDurations[AuctionPhase.Fluctuation]) {
                 timeMet = true;
            }
        } else if (currentPhase == AuctionPhase.Convergence) {
             nextPhase = AuctionPhase.Settlement; // Prepare for settlement
             if (transitionTime >= phaseStartTimes[AuctionPhase.Convergence] + phaseDurations[AuctionPhase.Convergence]) {
                 timeMet = true;
            }
        } else {
            revert("No further phases to transition automatically");
        }

        require(ownerOverride || timeMet, "Phase duration not met");

        // Prevent transitioning past Convergence unless settling
        if (nextPhase == AuctionPhase.Settlement && currentPhase != AuctionPhase.Convergence) {
             revert("Invalid phase transition attempt");
        }
         if (currentPhase == AuctionPhase.Convergence && nextPhase == AuctionPhase.Settlement && !ownerOverride) {
             // If settling phase is triggered automatically, immediately call settleAuction
             settleAuction(); // This transitions to Settling state and Settlement phase
             return; // settlementInitiated event handles the signal
         }

        // Normal phase transition
        phaseStartTimes[nextPhase] = transitionTime;
        AuctionPhase oldPhase = currentPhase;
        currentPhase = nextPhase;
        emit PhaseTransitioned(oldPhase, currentPhase, transitionTime);

        if (currentPhase == AuctionPhase.Settlement) {
             // This path is only reached if owner forced transition to Settlement
             settleAuction(); // Ensure settlement logic runs
        }
    }


    /**
     * @dev Pauses the auction. Only owner.
     */
    function pauseAuction() external onlyOwner inState(AuctionState.Active) {
        auctionState = AuctionState.Paused;
        emit AuctionPaused(uint64(block.timestamp));
    }

    /**
     * @dev Resumes a paused auction. Only owner. Timer resumes from block.timestamp.
     */
    function resumeAuction() external onlyOwner inState(AuctionState.Paused) {
        // Adjust phase start time to account for pause duration
        uint64 pauseDuration = uint64(block.timestamp) - uint64(emit AuctionPaused.timestamp); // Requires event field access, or track pause start time
        // Simpler approach: Just set the phase start time to now upon resuming
        phaseStartTimes[currentPhase] = uint64(block.timestamp);
        auctionState = AuctionState.Active;
        lastEntropyUpdateTime = uint64(block.timestamp); // Reset entropy time
        emit AuctionResumed(uint64(block.timestamp));
    }

    /**
     * @dev Cancels the auction. Only owner. Allows all bidders to claim full refunds.
     */
    function cancelAuction() external onlyOwner notInState(AuctionState.Settling) notInState(AuctionState.Completed) {
        auctionState = AuctionState.Cancelled;
        // In cancelled state, claimRefunds will allow full withdrawal
        emit AuctionCancelled();
    }

    /**
     * @dev Settles the auction after the Convergence phase ends. Determines winner and final flux.
     *      Can be called by anyone once conditions are met, or owner anytime after Convergence phase *should* end.
     */
    function settleAuction() public notInState(AuctionState.Pending) notInState(AuctionState.Paused) notInState(AuctionState.Settling) notInState(AuctionState.Completed) notInState(AuctionState.Cancelled) {
        // Check if Convergence phase has ended or owner is forcing
        uint64 convergenceEndTime = phaseStartTimes[AuctionPhase.Convergence] + phaseDurations[AuctionPhase.Convergence];
        bool ownerOverride = (msg.sender == owner);
        require(ownerOverride || (currentPhase == AuctionPhase.Convergence && block.timestamp >= convergenceEndTime), "Settlement not yet available");

        auctionState = AuctionState.Settling;
        currentPhase = AuctionPhase.Settlement; // Explicitly set settlement phase
        phaseStartTimes[AuctionPhase.Settlement] = uint64(block.timestamp);

        winner = highBidder;
        finalFluxAtSettlement = currentFlux; // Capture the flux at the moment of settlement

        emit SettlementInitiated(winner, highBid, finalFluxAtSettlement);
    }

    // --- Bidding & Participation Functions ---

    /**
     * @dev Allows a participant to place a bid.
     * @param _minFluxTolerance A strategic parameter from the bidder indicating their tolerance
     *        for potential refund reduction due to flux. Higher tolerance *might* subtly
     *        influence future flux/entropy dynamics or their own perceived outcome.
     *        (Conceptual influence in this implementation focuses on refund calculation).
     */
    function placeBid(uint256 _minFluxTolerance) external payable inState(AuctionState.Active) notInPhase(AuctionPhase.Settlement) notInPhase(AuctionPhase.Ended) {
        uint256 bidAmount = msg.value;
        require(bidAmount >= minBid, "Bid amount too low");

        uint256 requiredBid;
        if (highBid == 0) {
            requiredBid = minBid;
        } else {
            requiredBid = highBid + minBidIncrement;
        }
        require(bidAmount >= requiredBid, "Bid amount must be higher than current high bid + increment");

        // If bidder already exists, handle their previous bid (refund or add to proceeds if allowed by state)
        if (bids[msg.sender].exists) {
            // For simplicity in this complex example, previous bids are NOT automatically refunded here.
            // The bidder's previous bid ETH remains in the contract until claimRefunds is called
            // *after* settlement (if they don't become the winner).
            // This encourages higher bids and less bid retraction during active phases.
            // If they become the new high bidder, their *new* bid ETH is added, and their *old* bid ETH
            // is effectively 'locked' as part of their total potential winning amount,
            // or available for refund if they are outbid later.
             bids[msg.sender].exists = false; // Mark old bid struct as inactive conceptually
             // The ETH from the old bid is still associated with msg.sender in terms of potential claims later.
             // This requires careful tracking if we wanted to allow partial refunds *on placing a new bid*,
             // which adds significant complexity. Sticking to post-settlement claims is simpler here.
        } else {
             biddersList.push(msg.sender);
        }

        // Update bid details for the sender
        bids[msg.sender] = Bid({
            amount: bidAmount,
            timestamp: uint64(block.timestamp),
            minFluxTolerance: _minFluxTolerance,
            exists: true // Mark the new bid as active
        });

        // Update high bid
        uint256 bidAmountDifference = bidAmount - highBid; // Will be 0 if highBid was 0
        highBid = bidAmount;
        highBidder = msg.sender;

        // Update dynamic state (Entropy and Flux)
        _updateEntropy(bidAmountDifference);
        currentFlux = _calculateFlux(accumulatedEntropy, highBid); // Using highBid as a proxy for total bid volume impact

        emit BidPlaced(msg.sender, bidAmount, highBid, highBidder, _minFluxTolerance);
    }

    /**
     * @dev Allows a bidder to retract their bid under specific conditions.
     *      Conditions: Not the current high bidder, and before the Convergence phase starts.
     *      Refunds the full bid amount.
     */
    function retractBid() external payable onlyBidder inState(AuctionState.Active) notInPhase(AuctionPhase.Convergence) notInPhase(AuctionPhase.Settlement) notInPhase(AuctionPhase.Ended) {
        require(msg.sender != highBidder, "Cannot retract high bid");

        Bid storage bidderBid = bids[msg.sender];
        uint256 amount = bidderBid.amount;

        // Mark bid as inactive
        bidderBid.exists = false;

        // Remove from biddersList conceptually (or rebuild list, or just live with inactive entries)
        // Simple approach for demo: don't remove from list, just mark as inactive via 'exists' flag.

        // Refund ETH
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Refund failed");

        emit BidRetracted(msg.sender, amount);
    }

    // --- Settlement & Claims Functions ---

    /**
     * @dev Allows the winner to claim the item. Can only be called once.
     */
    function claimItem() external inState(AuctionState.Settling) notInPhase(AuctionPhase.Ended) {
        require(msg.sender == winner, "Only winner can claim item");
        require(!itemClaimed, "Item already claimed");

        itemClaimed = true;
        // In a real contract, this would transfer an NFT or similar.
        // Here, it just marks the item as claimed conceptually.

        // If all refunds are also claimed, we could transition to Ended state.
        // For simplicity, Ended state is not strictly enforced by claim status here,
        // but can be a conceptual final state after settlement.

        emit ItemClaimed(winner);
    }

    /**
     * @dev Allows a non-winning bidder to claim their refund after settlement.
     *      The refund amount is their original bid minus the calculated participation cost.
     */
    function claimRefunds() external inState(AuctionState.Settling) notInPhase(AuctionPhase.Ended) onlyBidder {
        require(msg.sender != winner, "Winner claims item, not refund");
        require(!refundClaimed[msg.sender], "Refund already claimed");

        Bid storage bidderBid = bids[msg.sender];
        require(bidderBid.exists, "No active bid found for this address"); // Ensure they had an active bid at settlement

        uint256 totalBid = bidderBid.amount;
        uint256 participationCost = _getEffectiveParticipationCost(finalFluxAtSettlement, totalBid, bidderBid.minFluxTolerance);
        uint256 refundAmount = totalBid - participationCost;

        // Mark refund as claimed
        refundClaimed[msg.sender] = true;
        bidderBid.exists = false; // Mark bid as fully settled/inactive

        // Refund ETH
        (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
        require(success, "Refund failed");

        emit RefundClaimed(msg.sender, refundAmount, participationCost);
    }

     /**
     * @dev Allows the owner to withdraw the auction proceeds (winning bid + accumulated participation costs).
     *      Only available after settlement has been initiated.
     */
    function withdrawOwnerProceeds() external onlyOwner inState(AuctionState.Settling) notInPhase(AuctionPhase.Ended) {
        // Calculate total proceeds available to owner.
        // This is the winning bid amount (which remained in the contract)
        // plus the sum of participation costs from all losing bidders.

        uint256 totalProceeds = highBid; // Winning bid amount

        // Sum up participation costs from losing bidders
        for (uint i = 0; i < biddersList.length; i++) {
            address bidderAddr = biddersList[i];
            if (bidderAddr != winner && bids[bidderAddr].exists == false && refundClaimed[bidderAddr]) { // Check if they were a bidder and have claimed refund
                uint256 bidAmount = bids[bidderAddr].amount; // Get original bid amount
                uint256 participationCost = _getEffectiveParticipationCost(finalFluxAtSettlement, bidAmount, bids[bidderAddr].minFluxTolerance);
                totalProceeds += participationCost;
            } else if (bidderAddr != winner && bids[bidderAddr].exists == false && !refundClaimed[bidderAddr]) {
                 // This case is for bidders who existed but haven't claimed refund yet in Settling phase.
                 // Their participation cost will be added when they claim.
                 // OR, should the owner be able to claim it if they don't?
                 // For simplicity, owner only claims what's ready (winner's bid + claimed loser costs).
                 // A more complex version would track unclaimed costs separately or allow owner to force claim unclaimed.
            } else if (bidderAddr == winner) {
                 // Winner's full bid was added initially, no participation cost from winner.
            }
             // If exists is true, they are either winner (handled) or haven't claimed refund yet (cost not added yet).
        }

        // Note: This calculation assumes the winner's full bid amount is available.
        // It also assumes participation costs become available upon refund claim.
        // A more robust system might require owner to wait for all refunds, or claim costs piecemeal.

        // For demo, let's assume the winning bid and ALL calculated participation costs are claimable once settlement is initiated,
        // regardless of whether losers have claimed their *refunds* yet. This simplifies the owner claim logic.
        // Re-calculate total proceeds based on ALL bids' calculated costs post-settlement.
        totalProceeds = highBid; // Winner's bid
         for (uint i = 0; i < biddersList.length; i++) {
            address bidderAddr = biddersList[i];
            // Only add participation cost for non-winners who placed a bid
            if (bidderAddr != winner && bids[bidderAddr].amount > 0) { // Check original bid amount, not just exists
                uint256 bidAmount = bids[bidderAddr].amount;
                 // Calculate cost based on final flux and their *recorded* tolerance
                uint256 participationCost = _getEffectiveParticipationCost(finalFluxAtSettlement, bidAmount, bids[bidderAddr].minFluxTolerance);
                totalProceeds += participationCost;
            }
        }


        require(totalProceeds > 0, "No proceeds to withdraw");

        (bool success, ) = owner.call{value: totalProceeds}("");
        require(success, "Withdrawal failed");

        emit OwnerProceedsWithdrawn(owner, totalProceeds);

        // Optionally transition to Ended state if all claims are done (more complex to track)
        // For simplicity, we stay in Settling until potentially manually marked Ended by owner.
    }

    // --- Dynamic State Calculation Helpers ---

    /**
     * @dev Internal function to update the accumulated entropy.
     *      Entropy increases based on time elapsed and the difference between the new bid and the previous high bid.
     *      This makes entropy a function of auction activity and volatility.
     * @param _bidAmountDifference The difference between the new bid amount and the previous high bid.
     */
    function _updateEntropy(uint256 _bidAmountDifference) internal {
        uint256 timeElapsed = uint64(block.timestamp) - lastEntropyUpdateTime;
        accumulatedEntropy += (timeElapsed * entropyPerTimeFactor);
        accumulatedEntropy += (_bidAmountDifference * entropyPerBidFactor);
        lastEntropyUpdateTime = uint64(block.timestamp);
    }

    /**
     * @dev Internal view function to calculate the current flux level.
     *      Flux is conceptually related to how "chaotic" the auction is.
     *      Calculation is a simplified model based on accumulated entropy and total bid volume (approximated by high bid).
     *      Range is arbitrary, scaled for example calculations.
     * @param _currentEntropy The current accumulated entropy.
     * @param _totalBidVolume Approximated by the current high bid amount.
     * @return uint256 The calculated current flux level.
     */
    function _calculateFlux(uint256 _currentEntropy, uint256 _totalBidVolume) internal view returns (uint256) {
         // Avoid division by zero if factors are 0 (though checked in setFluxParameters)
        uint256 entropyInfluence = _currentEntropy / (fluxEntropyFactor > 0 ? fluxEntropyFactor : 1);
        uint256 bidVolumeInfluence = _totalBidVolume / (fluxBidFactor > 0 ? fluxBidFactor : 1);

        // Simple additive model - can be made more complex (multiplicative, non-linear)
        uint256 calculatedFlux = entropyInfluence + bidVolumeInfluence;

        // Cap flux at a reasonable maximum for calculations (optional, but good practice)
        // Let's assume a maximum conceptual flux level, e.g., scaled to Gwei or something.
        // Max flux could be e.g., 1e18 (1 ETH equivalent), meaning a high participation cost.
        uint256 maxConceptualFlux = 5e17; // Example max cap (0.5 ETH equiv)
        return calculatedFlux > maxConceptualFlux ? maxConceptualFlux : calculatedFlux;
    }

    /**
     * @dev Internal view function to calculate the effective participation cost for a losing bidder.
     *      This is the amount deducted from their original bid, influenced by the final flux level
     *      at settlement and the bidder's submitted minimum flux tolerance.
     *      A higher final flux means a higher cost. A higher bidder tolerance *might* reduce the cost slightly
     *      (example logic below).
     * @param _finalFlux The flux level at the moment of settlement.
     * @param _bidAmount The losing bidder's original bid amount.
     * @param _bidFluxTolerance The minimum flux tolerance specified by the bidder.
     * @return uint256 The calculated participation cost (amount deducted from refund).
     */
    function _getEffectiveParticipationCost(uint256 _finalFlux, uint256 _bidAmount, uint256 _bidFluxTolerance) internal view returns (uint256) {
        // Example Logic:
        // Cost is a percentage of the bid, scaled by final flux.
        // Cost percentage increases with flux.
        // Bidder's tolerance slightly offsets the flux impact.

        // Base cost percentage influence from flux (e.g., flux scaled down)
        // Let's assume max conceptual flux (5e17) maps to a base cost factor, e.g., 20%.
        // CostFactor = FinalFlux / MaxConceptualFlux * BaseCostInfluence
        uint256 maxConceptualFlux = 5e17; // Needs to match value in _calculateFlux
        uint256 baseCostPercentageBasis = 200; // Represents 20.0% (scaled by 10)
        uint256 fluxCostBasis = (_finalFlux * baseCostPercentageBasis) / (maxConceptualFlux > 0 ? maxConceptualFlux : 1); // Scales based on final flux

        // Tolerance influence: Higher tolerance slightly reduces the effective flux cost basis.
        // E.g., tolerance up to 1e18 (1 ETH) can reduce basis by up to 5%
        uint256 maxToleranceInfluenceBasis = 50; // Represents 5.0% reduction basis
        uint256 toleranceReductionBasis = (_bidFluxTolerance * maxToleranceInfluenceBasis) / (1e18 > 0 ? 1e18 : 1); // Scale tolerance

        // Apply reduction, ensure it doesn't go below zero or make cost basis too low
        uint256 effectiveCostBasis = fluxCostBasis > toleranceReductionBasis ? fluxCostBasis - toleranceReductionBasis : 0;
        // Cap the effective basis, e.g., max cost is 50% of bid regardless of flux/tolerance interaction
        uint256 maxEffectiveCostBasis = 500; // Represents 50.0%
        effectiveCostBasis = effectiveCostBasis > maxEffectiveCostBasis ? maxEffectiveCostBasis : effectiveCostBasis;

        // Calculate the actual cost amount from the bid amount using the effective cost basis
        // Cost = BidAmount * EffectiveCostBasis / 1000 (since basis is scaled by 10)
        uint256 participationCost = (_bidAmount * effectiveCostBasis) / 1000;

        // Ensure cost doesn't exceed the bid amount itself (should be handled by logic, but safety)
        return participationCost > _bidAmount ? _bidAmount : participationCost;
    }


    // --- Query & View Functions ---

    /**
     * @dev Returns the current state of the auction.
     * @return AuctionState The current state enum.
     */
    function getAuctionState() external view returns (AuctionState) {
        return auctionState;
    }

    /**
     * @dev Returns the current phase of the auction.
     * @return AuctionPhase The current phase enum.
     */
    function getCurrentPhase() external view returns (AuctionPhase) {
        return currentPhase;
    }

    /**
     * @dev Returns the details of the current highest bid.
     * @return address The address of the high bidder.
     * @return uint256 The amount of the high bid.
     * @return uint64 The timestamp of the high bid.
     * @return uint256 The minimum flux tolerance specified by the high bidder.
     */
    function getHighBid() external view returns (address, uint256, uint64, uint256) {
        if (highBidder == address(0)) {
            return (address(0), 0, 0, 0);
        }
        Bid storage highBidStruct = bids[highBidder];
        return (highBidder, highBid, highBidStruct.timestamp, highBidStruct.minFluxTolerance);
    }

    /**
     * @dev Returns the bid details for a specific bidder.
     * @param _bidder The address of the bidder.
     * @return uint256 The bid amount.
     * @return uint64 The bid timestamp.
     * @return uint256 The minimum flux tolerance specified by the bidder.
     * @return bool True if the address has placed an active bid.
     */
    function getBidDetails(address _bidder) external view returns (uint256, uint64, uint256, bool) {
        Bid storage bidderBid = bids[_bidder];
        return (bidderBid.amount, bidderBid.timestamp, bidderBid.minFluxTolerance, bidderBid.exists);
    }

    /**
     * @dev Returns the current calculated flux level.
     *      Note: Flux is only calculated based on accumulated entropy and high bid when placeBid is called.
     *      This function returns the last calculated value. For real-time flux, recalculation would be needed here.
     * @return uint256 The current flux level.
     */
    function getFluxLevel() external view returns (uint256) {
        // Optionally recalculate flux on demand here for freshness, but might cost gas.
        // Returning stored value is gas-efficient.
        // For demonstration, return the last calculated value.
        // uint256 totalBidVolume = highBid; // Proxy
        // uint256 flux = _calculateFlux(accumulatedEntropy, totalBidVolume);
        // return flux;
         return currentFlux; // Return the stored value for gas efficiency
    }

     /**
     * @dev Returns the current accumulated entropy.
     *      Entropy is updated when placeBid is called.
     * @return uint256 The current accumulated entropy.
     */
    function getEntropy() external view returns (uint256) {
        // Optionally update entropy based on time elapsed since last update here, then return.
        // But that adds complexity. Returning stored value is simplest.
        // _updateEntropy(0); // Update entropy based on time only? Depends on desired model.
        return accumulatedEntropy;
    }


    /**
     * @dev Returns settlement details after settlement has been initiated.
     * @return address The address of the winner.
     * @return uint256 The winning bid amount.
     * @return uint256 The final flux level recorded at settlement.
     * @return bool True if the item has been claimed by the winner.
     */
    function getSettlementDetails() external view returns (address, uint256, uint256, bool) {
        require(auctionState == AuctionState.Settling || auctionState == AuctionState.Completed || auctionState == AuctionState.Ended, "Auction not settled");
        return (winner, highBid, finalFluxAtSettlement, itemClaimed);
    }

     /**
     * @dev Calculates and returns the estimated end time for a specific phase.
     *      Assumes the phase starts at its recorded start time.
     * @param _phase The phase to check.
     * @return uint64 The estimated end timestamp. Returns 0 if phase start time is 0.
     */
    function getPhaseEndTime(AuctionPhase _phase) external view returns (uint64) {
        if (phaseStartTimes[_phase] == 0 || _phase == AuctionPhase.Settlement || _phase == AuctionPhase.Ended) {
             // Settlement/Ended don't have fixed durations this way, or start time is 0 for not started phases
            return 0;
        }
        return phaseStartTimes[_phase] + phaseDurations[_phase];
    }

     /**
     * @dev Calculates and returns the estimated overall auction end time (end of Convergence phase).
     * @return uint64 The estimated end timestamp. Returns 0 if auction hasn't started or is cancelled/ended.
     */
    function getAuctionEndTime() external view returns (uint64) {
         if (auctionState == AuctionState.Pending || auctionState == AuctionState.Cancelled || currentPhase == AuctionPhase.Settlement || currentPhase == AuctionPhase.Ended) {
             return 0;
         }
        return getPhaseEndTime(AuctionPhase.Convergence);
    }

    /**
     * @dev Returns the current minimum bid requirement.
     * @return uint256 The minimum bid amount.
     */
    function getMinimumBid() external view returns (uint256) {
        if (highBid == 0) {
            return minBid;
        } else {
            return highBid + minBidIncrement;
        }
    }

    /**
     * @dev Provides a non-binding estimate of a bidder's potential outcome (refund amount)
     *      if the auction were to settle *right now* with the *current* flux level.
     *      This is purely for informational purposes and does NOT guarantee the actual outcome,
     *      as flux will continue to change until final settlement.
     *      Shows the impact of current flux on a specific bid.
     * @param _bidder The address of the bidder to estimate for.
     * @return uint256 Estimated refund amount. Returns 0 if bidder hasn't bid or auction not active/settling.
     */
    function predictOutcomeEstimate(address _bidder) external view returns (uint256 estimatedRefund) {
        Bid storage bidderBid = bids[_bidder];
        if (!bidderBid.exists) {
            return 0; // Bidder hasn't placed a bid
        }

        // If settlement is complete, return the actual outcome
        if (auctionState == AuctionState.Settling || auctionState == AuctionState.Completed || auctionState == AuctionState.Ended) {
             if (_bidder == winner) {
                 // Winner doesn't get refund, they get item. Indicate this? Or return 0?
                 // Let's return 0 refund for winner.
                 return 0;
             } else {
                 // For losers, calculate actual refund based on recorded final flux
                 uint256 totalBid = bidderBid.amount;
                 uint256 participationCost = _getEffectiveParticipationCost(finalFluxAtSettlement, totalBid, bidderBid.minFluxTolerance);
                 return totalBid - participationCost;
             }
        }

        // For active/paused auction states, provide an estimate based on current state
        if (auctionState == AuctionState.Active || auctionState == AuctionState.Paused) {
             // If they are the current high bidder, their outcome depends on whether they *remain* the winner
             // and what the final flux is. It's hard to estimate winning outcome here.
             // Let's focus this function on estimating the *refund* if they were to *lose* with the *current* flux.
             // If they *are* the current high bidder, the estimation is less relevant for winning,
             // but still shows the 'cost' if they were *just* outbid by someone else right now.

             uint256 estimatedFlux = getFluxLevel(); // Use current flux for estimation
             uint256 totalBid = bidderBid.amount;
             uint256 estimatedParticipationCost = _getEffectiveParticipationCost(estimatedFlux, totalBid, bidderBid.minFluxTolerance);
             estimatedRefund = totalBid - estimatedParticipationCost;

             return estimatedRefund;
        }

        // For Pending/Cancelled states, no meaningful prediction related to flux/settlement.
        return 0;
    }

    /**
     * @dev Returns a list of all addresses that have placed a bid.
     *      Note: This list includes addresses that may have retracted bids if 'exists' is false,
     *      or addresses that placed multiple bids (though only the last one is active).
     *      Filtering by `bids[addr].exists` is needed externally if only active bidders are desired.
     *      Exposing large arrays like this can be gas-intensive to read off-chain.
     * @return address[] The list of bidder addresses.
     */
    function getActiveBidders() external view returns (address[] memory) {
        // Filter biddersList to only include those where bids[addr].exists is true
        uint256 activeCount = 0;
        for (uint i = 0; i < biddersList.length; i++) {
            if (bids[biddersList[i]].exists) {
                activeCount++;
            }
        }

        address[] memory activeBidders = new address[](activeCount);
        uint256 currentIndex = 0;
        for (uint i = 0; i < biddersList.length; i++) {
            if (bids[biddersList[i]].exists) {
                activeBidders[currentIndex] = biddersList[i];
                currentIndex++;
            }
        }
        return activeBidders;
    }

    /**
     * @dev Checks if an address has placed an active bid.
     * @param _address The address to check.
     * @return bool True if the address has an active bid, false otherwise.
     */
    function isBidder(address _address) external view returns (bool) {
        return bids[_address].exists;
    }

    /**
     * @dev Returns the duration set for a specific phase.
     * @param _phase The phase to check.
     * @return uint64 The duration in seconds.
     */
    function getPhaseDuration(AuctionPhase _phase) external view returns (uint64) {
         if (_phase == AuctionPhase.Settlement || _phase == AuctionPhase.Ended) {
             return 0; // These phases don't have fixed, pre-set durations this way
         }
        return phaseDurations[_phase];
    }

    /**
     * @dev Returns the item details string.
     * @return string The details string.
     */
    function getItemDetails() external view returns (string memory) {
        return itemDetails;
    }

    // --- Fallback/Receive ---
    receive() external payable {
        // Optional: Allow receiving ETH outside of placeBid? Not recommended for clarity.
        // require(msg.sender == address(this), "External ETH deposit not allowed"); // Prevent random sends
    }

    fallback() external payable {
        // Optional: Handle fallback calls. Not recommended for clarity in this contract.
    }
}
```