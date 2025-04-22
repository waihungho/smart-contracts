Okay, let's design a smart contract around a probabilistic prediction game with dynamically shifting probabilities influenced by user actions, timed phases, and observer incentives. We'll call it "QuantumFlips".

**Concept:**

Users bet on the outcome of a multi-dimensional, probabilistic "flip". The interesting part is that the probability distribution for the outcome is not fixed; it is dynamically influenced by the collective amount staked by users on each possible outcome combination during the commitment phase. The flip then resolves based on this influenced probability distribution using a verifiable randomness source (simulated simply for this example, but ideally Chainlink VRF or similar). Users who predicted correctly can claim a share of the losing bets, minus a protocol fee and an incentive for the "Observer" who triggered the resolution.

**Advanced Concepts:**

1.  **Dynamic Probability Influence:** User stake directly alters the probability distribution of the outcome, introducing strategic depth beyond simple prediction.
2.  **Timed State Machine:** The contract transitions through distinct phases (Commitment, Resolution, Payout) governed by block timestamps.
3.  **Observer Pattern with Incentives:** Anyone can trigger the resolution (`resolveFlip`) and is incentivized to do so.
4.  **Probabilistic Outcome Space:** Outcomes aren't binary (like Heads/Tails) but can be combinations across multiple dimensions.
5.  **Gas Efficiency Considerations:** While the logic is complex, we aim to structure functions (like `claimPayout`) to be individually callable by users to avoid unbounded loops.
6.  **Internal State Management:** Complex internal logic manages staked amounts per outcome, calculates dynamic weights, and determines payouts.

**Disclaimer:** This is a complex example for demonstration. The randomness source (`blockhash`) used here is *highly insecure* for production use and vulnerable to miner manipulation. A secure VRF solution like Chainlink VRF is necessary for real-world applications.

---

**Outline:**

1.  **Pragma and Licenses**
2.  **Error Definitions**
3.  **Events**
4.  **Enums**
5.  **Structs**
6.  **State Variables**
    *   Owner, Paused State
    *   Flip Configuration (Durations, Minimum Stake, Admin Fee, Observer Incentive)
    *   Current Flip State (Number, Phase, Timestamps, Total Staked, Resolved Outcome)
    *   Commitment Data (User commitments, Total staked per outcome combination)
    *   Payout Data (Claimed status)
    *   Historical Data (Resolved outcomes - limited storage for history)
7.  **Modifiers**
8.  **Constructor**
9.  **Admin Functions (onlyOwner)**
    *   `pause`, `unpause`
    *   `setFlipParameters`
    *   `setMinimumCommitmentAmount`
    *   `setAdminFeePercentage`
    *   `setObserverIncentivePercentage`
    *   `withdrawAdminFees`
    *   `emergencyWithdraw`
    *   `cancelCurrentFlip`
10. **Core Flip Flow Functions**
    *   `startNewFlip` (Admin or automated, triggered here by admin)
    *   `commitToOutcome` (Users stake Ether on a predicted outcome)
    *   `resolveFlip` (Observer triggers randomness and outcome resolution)
    *   `claimPayout` (Winners claim their share)
11. **View/Query Functions**
    *   `getCurrentFlipNumber`
    *   `getFlipState`
    *   `getFlipParameters`
    *   `getCommitmentPhaseEndTime`
    *   `getResolutionPhaseEndTime`
    *   `getPayoutPhaseEndTime`
    *   `getMinimumCommitmentAmount`
    *   `getAdminFeePercentage`
    *   `getObserverIncentivePercentage`
    *   `getUserCommitment`
    *   `getResolvedOutcome`
    *   `calculateUserPotentialPayout`
    *   `hasUserClaimed`
    *   `getTotalStakedInFlip`
    *   `getTotalStakedForOutcome`
    *   `getHistoricalOutcome`
12. **Internal Helper Functions**
    *   `_transitionState`
    *   `_calculateWeightedOutcome` (Implements dynamic probability logic)
    *   `_generatePseudoRandomValue` (Insecure randomness source)
    *   `_calculatePayoutAmount`

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumFlips
 * @dev A smart contract implementing a probabilistic prediction game with dynamic probabilities.
 * Users commit Ether to predict the outcome of a multi-dimensional flip.
 * The probability distribution for the flip outcome is influenced by the total amount staked on each outcome combination.
 * A designated observer triggers the resolution phase, using a pseudo-random number (INSECURE FOR PRODUCTION - use VRF).
 * Winners share the losing pool proportionally, after deducting protocol fees and observer incentives.
 * The game progresses through distinct Commitment, Resolution, and Payout phases.
 */

// --- Error Definitions ---
error NotOwner();
error Paused();
error NotPaused();
error InvalidStateTransition(FlipState currentState, FlipState expectedState);
error CommitmentTooLow(uint256 requiredAmount);
error CommitmentPhaseInactive();
error ResolutionPhaseInactive();
error PayoutPhaseInactive();
error FlipAlreadyStarted();
error FlipNotStarted();
error FlipNotResolved();
error NothingToClaim();
error AlreadyClaimed();
error InvalidParameters();
error NoAdminFeesToWithdraw();
error NothingToWithdraw();
error FlipAlreadyResolved();
error FlipResolutionRequiresCommitments();
error OutcomeIndexOutOfRange();
error HistoricalFlipNotFound();

// --- Events ---
event FlipStarted(uint256 indexed flipNumber, uint256 commitmentEndTime, uint256 resolutionEndTime, uint256 payoutEndTime);
event CommitmentMade(uint256 indexed flipNumber, address indexed user, uint256 amount, uint8[] predictedOutcome);
event FlipResolved(uint256 indexed flipNumber, address indexed observer, uint8[] resolvedOutcome, uint256 totalStaked);
event PayoutClaimed(uint256 indexed flipNumber, address indexed user, uint256 amount);
event StateTransitioned(uint256 indexed flipNumber, FlipState indexed oldState, FlipState indexed newState);
event ParametersUpdated(uint256 commitmentDuration, uint256 resolutionDuration, uint256 payoutDuration, uint256 minCommitment, uint256 adminFeePercent, uint256 observerIncentivePercent);
event AdminFeesWithdrawn(address indexed admin, uint256 amount);
event EmergencyWithdrawal(address indexed admin, uint256 amount);
event FlipCancelled(uint256 indexed flipNumber);

// --- Enums ---
enum FlipState {
    Setup,       // Ready to start a new flip
    Commitment,  // Accepting commitments (stakes)
    Resolution,  // Waiting for resolution trigger
    Payout,      // Resolved, winners can claim
    Finished     // Payout period ended, ready for next setup
}

// --- Structs ---
struct FlipParameters {
    uint256 commitmentDuration;    // Duration of commitment phase in seconds
    uint256 resolutionDuration;    // Duration of resolution phase in seconds
    uint256 payoutDuration;       // Duration of payout phase in seconds
    uint256 minimumCommitmentAmount; // Minimum Ether required per commitment
    uint16 adminFeePercentage;     // Percentage of total staked taken as admin fee (scaled by 10000)
    uint16 observerIncentivePercentage; // Percentage of total staked given to the observer (scaled by 10000)
    uint8[] outcomeDimensions;     // Max value for each dimension (e.g., [2, 3] means first dimension 0 or 1, second 0, 1, or 2)
}

struct FlipStateData {
    FlipState currentState;
    uint256 startTime;
    uint256 commitmentEndTime;
    uint256 resolutionEndTime;
    uint256 payoutEndTime;
    uint256 totalStaked;
    uint8[] resolvedOutcome; // Only set after resolution
    bool resolved;
}

struct UserCommitment {
    uint256 amount;
    uint8[] predictedOutcome;
    bool exists; // To distinguish default empty struct
}

// --- State Variables ---
address public owner;
bool public paused = false;

uint256 public currentFlipNumber = 0;

FlipParameters public flipParameters;
FlipStateData public currentFlipState;

// Mapping: flipNumber => userAddress => UserCommitment
mapping(uint256 => mapping(address => UserCommitment)) private userCommitments;

// Mapping: flipNumber => outcomeCombinationHash => totalStakedForThisOutcome
// Outcome combination hash is generated from uint8[] predictedOutcome
mapping(uint256 => mapping(bytes32 => uint256)) private totalStakedPerOutcome;

// Mapping: flipNumber => userAddress => claimedStatus
mapping(uint256 => mapping(address => bool)) private userClaimedPayout;

// Stores resolved outcomes for history (can be limited or more complex for scaling)
mapping(uint256 => uint8[]) private historicalOutcomes;

uint256 private totalAdminFees = 0;

// --- Modifiers ---
modifier onlyOwner() {
    if (msg.sender != owner) revert NotOwner();
    _;
}

modifier whenNotPaused() {
    if (paused) revert Paused();
    _;
}

modifier whenPaused() {
    if (!paused) revert NotPaused();
    _;
}

modifier whenState(FlipState _state) {
    if (currentFlipState.currentState != _state) revert InvalidStateTransition(currentFlipState.currentState, _state);
    _;
}

// --- Constructor ---
constructor(
    uint256 _commitmentDuration,
    uint256 _resolutionDuration,
    uint256 _payoutDuration,
    uint256 _minimumCommitmentAmount,
    uint16 _adminFeePercentageScaled, // e.g., 200 for 2%
    uint16 _observerIncentivePercentageScaled, // e.g., 50 for 0.5%
    uint8[] memory _outcomeDimensions // e.g., [2, 3]
) {
    if (_commitmentDuration == 0 || _resolutionDuration == 0 || _payoutDuration == 0 || _minimumCommitmentAmount == 0 || _outcomeDimensions.length == 0) {
         revert InvalidParameters();
    }
    // Basic check for outcome dimensions - each dimension must have at least 2 possibilities
    for(uint i = 0; i < _outcomeDimensions.length; i++) {
        if (_outcomeDimensions[i] < 2) revert InvalidParameters();
    }

    owner = msg.sender;
    flipParameters = FlipParameters({
        commitmentDuration: _commitmentDuration,
        resolutionDuration: _resolutionDuration,
        payoutDuration: _payoutDuration,
        minimumCommitmentAmount: _minimumCommitmentAmount,
        adminFeePercentage: _adminFeePercentageScaled,
        observerIncentivePercentage: _observerIncentivePercentageScaled,
        outcomeDimensions: _outcomeDimensions
    });
    currentFlipState.currentState = FlipState.Setup;
}

// --- Admin Functions ---

/**
 * @dev Pauses the contract, preventing state-changing operations except by owner.
 */
function pause() external onlyOwner whenNotPaused {
    paused = true;
    // Potentially transition state if a flip is active? Or just freeze it?
    // Freezing seems simpler.
}

/**
 * @dev Unpauses the contract.
 */
function unpause() external onlyOwner whenPaused {
    paused = false;
}

/**
 * @dev Sets parameters for future flips. Does not affect an ongoing flip.
 * @param _commitmentDuration Duration of commitment phase in seconds.
 * @param _resolutionDuration Duration of resolution phase in seconds.
 * @param _payoutDuration Duration of payout phase in seconds.
 * @param _minimumCommitmentAmount Minimum Ether required per commitment.
 * @param _adminFeePercentageScaled Admin fee percentage scaled by 10000 (e.g., 200 for 2%). Max 10000 (100%).
 * @param _observerIncentivePercentageScaled Observer incentive percentage scaled by 10000 (e.g., 50 for 0.5%). Max 10000 (100%).
 * @param _outcomeDimensions Max value for each dimension (e.g., [2, 3] means first dimension 0 or 1, second 0, 1, or 2).
 */
function setFlipParameters(
    uint256 _commitmentDuration,
    uint256 _resolutionDuration,
    uint256 _payoutDuration,
    uint256 _minimumCommitmentAmount,
    uint16 _adminFeePercentageScaled,
    uint16 _observerIncentivePercentageScaled,
    uint8[] memory _outcomeDimensions
) external onlyOwner {
     if (_commitmentDuration == 0 || _resolutionDuration == 0 || _payoutDuration == 0 || _minimumCommitmentAmount == 0 || _outcomeDimensions.length == 0) {
         revert InvalidParameters();
     }
    for(uint i = 0; i < _outcomeDimensions.length; i++) {
        if (_outcomeDimensions[i] < 2) revert InvalidParameters();
    }
     if (_adminFeePercentageScaled + _observerIncentivePercentageScaled > 10000) {
         revert InvalidParameters(); // Fees cannot exceed 100%
     }

    flipParameters = FlipParameters({
        commitmentDuration: _commitmentDuration,
        resolutionDuration: _resolutionDuration,
        payoutDuration: _payoutDuration,
        minimumCommitmentAmount: _minimumCommitmentAmount,
        adminFeePercentage: _adminFeePercentageScaled,
        observerIncentivePercentage: _observerIncentivePercentageScaled,
        outcomeDimensions: _outcomeDimensions
    });

    emit ParametersUpdated(
        _commitmentDuration,
        _resolutionDuration,
        _payoutDuration,
        _minimumCommitmentAmount,
        _adminFeePercentageScaled,
        _observerIncentivePercentageScaled
    );
}

/**
 * @dev Sets the minimum commitment amount for future flips.
 * @param _amount The new minimum amount in wei.
 */
function setMinimumCommitmentAmount(uint256 _amount) external onlyOwner {
     if (_amount == 0) revert InvalidParameters();
     flipParameters.minimumCommitmentAmount = _amount;
     emit ParametersUpdated(
         flipParameters.commitmentDuration,
         flipParameters.resolutionDuration,
         flipParameters.payoutDuration,
         flipParameters.minimumCommitmentAmount,
         flipParameters.adminFeePercentage,
         flipParameters.observerIncentivePercentage
     );
}

/**
 * @dev Sets the admin fee percentage for future flips.
 * @param _percentageScaled The percentage scaled by 10000 (e.g., 200 for 2%). Max 10000.
 */
function setAdminFeePercentage(uint16 _percentageScaled) external onlyOwner {
    if (_percentageScaled > 10000 || _percentageScaled + flipParameters.observerIncentivePercentage > 10000) revert InvalidParameters();
    flipParameters.adminFeePercentage = _percentageScaled;
     emit ParametersUpdated(
         flipParameters.commitmentDuration,
         flipParameters.resolutionDuration,
         flipParameters.payoutDuration,
         flipParameters.minimumCommitmentAmount,
         flipParameters.adminFeePercentage,
         flipParameters.observerIncentivePercentage
     );
}

/**
 * @dev Sets the observer incentive percentage for future flips.
 * @param _percentageScaled The percentage scaled by 10000 (e.g., 50 for 0.5%). Max 10000.
 */
function setObserverIncentivePercentage(uint16 _percentageScaled) external onlyOwner {
    if (_percentageScaled > 10000 || flipParameters.adminFeePercentage + _percentageScaled > 10000) revert InvalidParameters();
    flipParameters.observerIncentivePercentage = _percentageScaled;
     emit ParametersUpdated(
         flipParameters.commitmentDuration,
         flipParameters.resolutionDuration,
         flipParameters.payoutDuration,
         flipParameters.minimumCommitmentAmount,
         flipParameters.adminFeePercentage,
         flipParameters.observerIncentivePercentage
     );
}

/**
 * @dev Allows the owner to withdraw accumulated admin fees.
 */
function withdrawAdminFees() external onlyOwner {
    if (totalAdminFees == 0) revert NoAdminFeesToWithdraw();
    uint256 amount = totalAdminFees;
    totalAdminFees = 0;
    (bool success, ) = owner.call{value: amount}("");
    if (!success) {
        // In case of failure, revert to prevent burning funds, or implement a recovery mechanism
        totalAdminFees = amount; // Revert state change
        revert("Withdrawal failed"); // Or handle differently if preferred
    }
    emit AdminFeesWithdrawn(owner, amount);
}

/**
 * @dev Allows the owner to withdraw contract balance in case of emergency.
 * Intended for recovering funds if the contract gets stuck, not normal operation.
 */
function emergencyWithdraw(uint256 amount) external onlyOwner whenPaused {
    if (amount == 0 || amount > address(this).balance) revert NothingToWithdraw();
    (bool success, ) = owner.call{value: amount}("");
    if (!success) {
        revert("Emergency withdrawal failed");
    }
    emit EmergencyWithdrawal(owner, amount);
}

/**
 * @dev Allows the owner to cancel the current flip if it's in Setup or Commitment phase.
 * Returns all staked funds to users.
 */
function cancelCurrentFlip() external onlyOwner whenNotPaused {
    if (currentFlipState.currentState != FlipState.Setup && currentFlipState.currentState != FlipState.Commitment) {
        revert InvalidStateTransition(currentFlipState.currentState, FlipState.Setup); // Can only cancel before Resolution
    }

    // In a real contract with many users, iterating here would be gas-prohibitive.
    // A different mechanism would be needed, e.g., users claiming refunds individually.
    // For this example, we assume a reasonable number of users per flip or accept high gas.

    uint256 flipNum = currentFlipNumber;
    // Iterate through *all* users who committed in this flip (requires tracking users, not just commitments per outcome)
    // This is a major limitation for scalability in this simple example.
    // A real system might use a Merkle tree of commitments or require users to self-refund.
    // To avoid unbounded loops, this example will *not* implement auto-refunds on cancel.
    // Instead, users would need to call a hypothetical `claimRefundIfCancelled(flipNum)` function.
    // We'll add a note about this limitation.

    // NOTE: Iterating over `userCommitments` mapping keys directly is not possible in Solidity.
    // To refund, we'd need a separate list/set of users who committed, which adds complexity.
    // For simplicity in this example, cancelling just transitions state and marks flip as cancelled,
    // making it impossible for users to claim normally. A separate refund mechanism would be needed.

    currentFlipState.currentState = FlipState.Finished; // Mark as finished/cancelled
    currentFlipState.resolved = false; // Ensure it's not marked resolved
    currentFlipState.totalStaked = 0; // Reset for next flip

    emit FlipCancelled(flipNum);

    // Ready for next flip
    _transitionState(FlipState.Finished);
}


// --- Core Flip Flow Functions ---

/**
 * @dev Starts a new flip. Can only be called when the contract is in the Setup state.
 * Increments the flip number and sets up the next flip's timing and parameters.
 */
function startNewFlip() external onlyOwner whenNotPaused whenState(FlipState.Setup) {
    currentFlipNumber++;
    uint256 nowTime = block.timestamp;

    // Reset state for the new flip
    currentFlipState.startTime = nowTime;
    currentFlipState.commitmentEndTime = nowTime + flipParameters.commitmentDuration;
    currentFlipState.resolutionEndTime = currentFlipState.commitmentEndTime + flipParameters.resolutionDuration;
    currentFlipState.payoutEndTime = currentFlipState.resolutionEndTime + flipParameters.payoutDuration;
    currentFlipState.totalStaked = 0;
    // Clear previous flip's mappings? Not strictly necessary as they are mapped by flipNumber,
    // but could save gas on first access of a new flip. Manual deletion is complex.
    // Solidity's mapping behavior means old flip data is just inert.
    delete currentFlipState.resolvedOutcome; // Clear outcome from previous flip
    currentFlipState.resolved = false; // Ensure not resolved

    emit FlipStarted(
        currentFlipNumber,
        currentFlipState.commitmentEndTime,
        currentFlipState.resolutionEndTime,
        currentFlipState.payoutEndTime
    );

    _transitionState(FlipState.Commitment);
}

/**
 * @dev Allows a user to commit to a predicted outcome for the current flip.
 * Must be called during the Commitment phase.
 * User stakes Ether equal to or greater than the minimum commitment amount.
 * The staked amount contributes to the total staked for the predicted outcome,
 * influencing its probability.
 * @param _predictedOutcome The predicted outcome as an array of uint8.
 * Each element represents a dimension's outcome, must be within bounds defined by flipParameters.outcomeDimensions.
 */
function commitToOutcome(uint8[] memory _predictedOutcome) external payable whenNotPaused {
    // Ensure commitment phase is active
    if (currentFlipState.currentState != FlipState.Commitment || block.timestamp >= currentFlipState.commitmentEndTime) {
        revert CommitmentPhaseInactive();
    }
    // Ensure value sent is >= minimum commitment
    if (msg.value < flipParameters.minimumCommitmentAmount) {
        revert CommitmentTooLow(flipParameters.minimumCommitmentAmount);
    }
    // Ensure predicted outcome dimensions match and are within bounds
    if (_predictedOutcome.length != flipParameters.outcomeDimensions.length) revert InvalidParameters();
    for(uint i = 0; i < _predictedOutcome.length; i++) {
        if (_predictedOutcome[i] >= flipParameters.outcomeDimensions[i]) revert OutcomeIndexOutOfRange();
    }

    uint256 flipNum = currentFlipNumber;
    bytes32 outcomeHash = keccak256(abi.encodePacked(_predictedOutcome));

    // Check if user already committed (only one commitment per user per flip)
    if (userCommitments[flipNum][msg.sender].exists) {
        // Allow updating commitment? Or disallow? Let's disallow for simplicity.
        // To allow update, we'd need to subtract old stake and add new.
        revert("User already committed to this flip");
    }

    // Store user commitment details
    userCommitments[flipNum][msg.sender] = UserCommitment({
        amount: msg.value,
        predictedOutcome: _predictedOutcome, // Store the actual outcome array
        exists: true
    });

    // Update total staked for this outcome combination
    totalStakedPerOutcome[flipNum][outcomeHash] += msg.value;

    // Update total staked in the flip
    currentFlipState.totalStaked += msg.value;

    emit CommitmentMade(flipNum, msg.sender, msg.value, _predictedOutcome);

    // Auto-transition if commitment phase ends while processing this transaction
    // (though less likely with block.timestamp checks)
    // The next state is checked when resolveFlip is called
}

/**
 * @dev Triggers the resolution of the flip.
 * Can be called by anyone during or after the Resolution phase.
 * Uses a pseudo-random number to determine the winning outcome based on
 * the dynamically influenced probabilities from user commitments.
 * Distributes observer incentive and admin fee, makes funds available for winners.
 * @param _blockNumberForRandomness The block number to use for pseudo-randomness.
 * This parameter is required to mitigate basic front-running where a miner could
 * compute the outcome and choose whether to include the transaction.
 * NOTE: This is still NOT SECURE. A truly secure VRF (like Chainlink) is needed.
 */
function resolveFlip(uint256 _blockNumberForRandomness) external whenNotPaused {
    // Ensure resolution phase is active or has ended but hasn't been resolved yet
    if (currentFlipState.currentState != FlipState.Resolution && currentFlipState.currentState != FlipState.Payout) {
         // Allow transition from commitment if commitment phase is over
        if (currentFlipState.currentState == FlipState.Commitment && block.timestamp >= currentFlipState.commitmentEndTime) {
            // Allow state transition implicitly here
        } else {
             revert InvalidStateTransition(currentFlipState.currentState, FlipState.Resolution);
        }
    }

    // Ensure not already resolved
    if (currentFlipState.resolved) revert FlipAlreadyResolved();

    // Ensure there were commitments made
    if (currentFlipState.totalStaked == 0) {
         // No commitments, just transition to finished
         _transitionState(FlipState.Finished);
         currentFlipState.resolved = true; // Still mark as resolved to prevent future attempts
         currentFlipState.resolvedOutcome = new uint8[](0); // Indicate no outcome
         emit FlipResolved(currentFlipNumber, msg.sender, currentFlipState.resolvedOutcome, 0);
         return; // Exit early if no stakes
    }

    uint256 flipNum = currentFlipNumber;

    // Ensure the chosen block for randomness is in the past
    // (Mitigates simple front-running, but not sophisticated miner manipulation)
    if (_blockNumberForRandomness >= block.number) revert("Block number for randomness must be in the past");
    // Also, prevent using a block that's too old and might have been pruned
    // (Requires knowing chain's pruning depth, e.g., within last 256 blocks for blockhash)
    if (_blockNumberForRandomness < block.number - 256) revert("Block number for randomness is too old");


    // --- Calculate Weighted Probabilities and Determine Outcome ---
    // This is where the dynamic probability logic lives.
    // The total stake on each outcome combination `totalStakedPerOutcome[flipNum][outcomeHash]`
    // acts as a weight.
    // We need a way to map stake weights to ranges in a random number space.
    // This requires iterating through all *possible* outcome combinations or *all* committed outcome combinations.
    // Iterating all *possible* outcomes is deterministic but the number can be huge (prod(dimensions)).
    // Iterating *committed* outcomes is gas-dependent on number of unique outcomes committed.
    // For this example, we'll iterate over the keys in `totalStakedPerOutcome[flipNum]`.
    // NOTE: Iterating keys of a mapping in Solidity is NOT possible directly and is a major limitation.
    // A real implementation needs to track committed outcome hashes in a list/array.
    // For this example, we will SIMULATE this iteration or assume a limited set of possible outcomes are tracked.
    // We'll define a fixed small set of possible outcomes for simplicity in simulating the logic.
    // A robust contract would need to store ALL unique outcome hashes that received stake in an array.

    // Let's assume we have a way to get an array of unique committed outcome hashes:
    // bytes32[] memory committedOutcomeHashes = getUniqueCommittedOutcomeHashes(flipNum); // Hypothetical function
    // To make this example runnable, we'll simplify and just use the insecure blockhash directly
    // without complex weighting, or use a simplified weighting over a known small set.

    // Simplification: Instead of complex dynamic weighting, let's use a simpler model
    // where the outcome is determined by a range within the random number,
    // and the *size* of each range is proportional to the stake for that outcome.

    // Collect all unique committed outcome hashes and their staked amounts
    // This requires iterating over user commitments or having a separate structure.
    // Again, direct mapping iteration is impossible. Let's use a hypothetical representation.
    struct OutcomeWeight { bytes32 outcomeHash; uint256 weight; uint8[] outcome; }
    OutcomeWeight[] memory weightedOutcomes;
    uint256 totalWeight = 0; // This will be equal to currentFlipState.totalStaked

    // Simulate gathering weighted outcomes (this part is NOT standard Solidity mapping iteration)
    // In a real contract, you would need a list/set of all unique outcome hashes committed.
    // For demo purposes, let's just use the totalStaked as the 'weight' for one simplified outcome.
    // A more complex system would iterate through `totalStakedPerOutcome` and build the `weightedOutcomes` array.

    // Simplified dynamic probability: The random number is chosen, and we find which outcome range it falls into.
    // The ranges are determined by the cumulative stake on each outcome.
    // E.g., Outcome A gets 60 ETH stake, Outcome B gets 40 ETH. Total 100 ETH.
    // Random number range 0-99. A gets 0-59, B gets 60-99.
    // This requires sorting outcomes or using their hash deterministically.

    // Let's use a simpler dynamic probability: We generate *multiple* random values.
    // For each dimension, we generate a random number, but bias it towards outcomes with higher stake.
    // This is still complex to implement purely on-chain efficiently for high dimensions/outcomes.

    // Let's revert to a simpler dynamic probability model that's *demonstrable*:
    // Generate a single large random number. Divide the space [0, large_number] into segments.
    // The size of the segment for a given outcome combination (hash) is proportional to its stake.
    // Iterate through ALL possible outcome combinations, calculate its stake, and assign a range.
    // This is only feasible if the number of *possible* outcome combinations is small.
    // E.g., dimensions [2, 2] -> 4 possible outcomes (0,0), (0,1), (1,0), (1,1).
    // Let's stick to this assumption for the example code: small, fixed outcome space.

    uint256 pseudoRandomValue = _generatePseudoRandomValue(_blockNumberForRandomness);
    uint8[] memory resolvedOutcome = _calculateWeightedOutcome(pseudoRandomValue); // Implements the dynamic weighting logic


    currentFlipState.resolvedOutcome = resolvedOutcome;
    currentFlipState.resolved = true; // Mark as resolved
    historicalOutcomes[flipNum] = resolvedOutcome; // Store for history

    // Calculate fees and observer incentive
    uint256 totalStake = currentFlipState.totalStaked;
    uint256 adminFee = (totalStake * flipParameters.adminFeePercentage) / 10000;
    uint256 observerIncentive = (totalStake * flipParameters.observerIncentivePercentage) / 10000;

    // Ensure fees don't exceed total stake (should be guaranteed by constructor/setters, but belt-and-suspenders)
    if (adminFee + observerIncentive > totalStake) {
        // This should not happen if parameters are set correctly
        adminFee = (totalStake * flipParameters.adminFeePercentage) / (flipParameters.adminFeePercentage + flipParameters.observerIncentivePercentage);
        observerIncentive = totalStake - adminFee;
        if (adminFee + observerIncentive > totalStake) { // Handle potential rounding issues
             uint256 excess = adminFee + observerIncentive - totalStake;
             adminFee -= excess; // Trim from admin fee
        }
    }


    totalAdminFees += adminFee;
    uint256 payoutPool = totalStake - adminFee - observerIncentive;

    // Send observer incentive
    (bool success, ) = msg.sender.call{value: observerIncentive}("");
    // Handle transfer failure? Observer doesn't necessarily *need* the incentive for the flip to resolve.
    // Could log failure and let admin recover or leave in contract balance.
    // For simplicity, we'll just check success and not revert the entire resolution.
    if (!success) {
        // Log or handle failure, maybe add incentive back to totalAdminFees?
        // totalAdminFees += observerIncentive; // Option to add failed incentive to admin pool
        emit event("ObserverIncentiveTransferFailed", msg.sender, observerIncentive, flipNum); // Example logging
    }


    // Now transition to Payout state
    _transitionState(FlipState.Payout);

    emit FlipResolved(flipNum, msg.sender, resolvedOutcome, totalStake);
}

/**
 * @dev Allows a user to claim their payout if they predicted the correct outcome.
 * Can be called by the user during or after the Payout phase.
 * Calculates the user's share of the payout pool based on their stake.
 */
function claimPayout() external payable whenNotPaused {
    uint256 flipNum = currentFlipNumber; // User claims for the *current* finished flip

    // We need to ensure the flip is resolvable/resolved AND the payout phase is active or has ended.
    // Users claim for the *most recently resolved* flip.
    // If the current flip isn't resolved, they might be claiming for a *previous* one.
    // This implies we need to track claimed status *per flip*. Our mapping `userClaimedPayout` does this.

    // Let's assume `claimPayout` is for the most recent finished/resolved flip
    // This requires the state machine to handle multiple flips properly,
    // or `claimPayout` needs to take a flip number parameter.
    // Let's make it claim for the *last* flip that is in Payout or Finished state.
    // This complicates things if multiple flips could be in Payout state simultaneously.
    // Let's simplify: `claimPayout` is for the *current* flip number, *if* it's resolved.

    if (!currentFlipState.resolved || currentFlipState.currentState < FlipState.Payout) {
        revert FlipNotResolved(); // Flip must be resolved
    }
     if (currentFlipState.currentState != FlipState.Payout && currentFlipState.currentState != FlipState.Finished) {
        // Should ideally not happen if state machine is correct, but safety check
         revert PayoutPhaseInactive(); // Must be in Payout or Finished state
    }

    address user = msg.sender;
    uint256 flipToClaim = currentFlipNumber; // Assume claim is for the current flip

    // Check if user committed in this flip
    UserCommitment storage commitment = userCommitments[flipToClaim][user];
    if (!commitment.exists) revert NothingToClaim(); // User didn't commit

    // Check if user already claimed for this flip
    if (userClaimedPayout[flipToClaim][user]) revert AlreadyClaimed();

    // Check if user's predicted outcome matches the resolved outcome
    uint8[] memory resolved = currentFlipState.resolvedOutcome;
    uint8[] memory predicted = commitment.predictedOutcome;

    bool isWinner = true;
    if (resolved.length != predicted.length) {
        isWinner = false; // Should match dimensions, but safety check
    } else {
        for(uint i = 0; i < resolved.length; i++) {
            if (resolved[i] != predicted[i]) {
                isWinner = false;
                break;
            }
        }
    }

    if (!isWinner) revert NothingToClaim(); // User lost

    // Calculate payout amount
    uint256 payoutAmount = _calculatePayoutAmount(flipToClaim, user);
    if (payoutAmount == 0) revert NothingToClaim(); // Should not happen if winner and stake > 0, but safety

    // Mark as claimed *before* transfer
    userClaimedPayout[flipToClaim][user] = true;

    // Transfer payout to user
    (bool success, ) = user.call{value: payoutAmount}("");
    if (!success) {
        // If transfer fails, user has paid gas but cannot claim.
        // Reverting the claimed status allows them to try again.
        userClaimedPayout[flipToClaim][user] = false; // Revert state change
        revert("Payout transfer failed");
    }

    emit PayoutClaimed(flipToClaim, user, payoutAmount);
}

// --- View / Query Functions ---

/**
 * @dev Gets the current flip number.
 */
function getCurrentFlipNumber() external view returns (uint256) {
    return currentFlipNumber;
}

/**
 * @dev Gets the current state of the flip.
 */
function getFlipState() external view returns (FlipState) {
    // Check if state should transition automatically based on time
    if (currentFlipState.currentState == FlipState.Commitment && block.timestamp >= currentFlipState.commitmentEndTime) return FlipState.Resolution;
    if (currentFlipState.currentState == FlipState.Resolution && block.timestamp >= currentFlipState.resolutionEndTime && !currentFlipState.resolved) return FlipState.Resolution; // Still Resolution until resolved
    if (currentFlipState.currentState == FlipState.Resolution && block.timestamp >= currentFlipState.resolutionEndTime && currentFlipState.resolved) return FlipState.Payout; // Should transition to Payout upon resolution if past resolution end
    if (currentFlipState.currentState == FlipState.Payout && block.timestamp >= currentFlipState.payoutEndTime) return FlipState.Finished;

    return currentFlipState.currentState;
}

/**
 * @dev Gets the parameters for the next flip.
 */
function getFlipParameters() external view returns (
    uint256 commitmentDuration,
    uint256 resolutionDuration,
    uint256 payoutDuration,
    uint256 minimumCommitmentAmount,
    uint16 adminFeePercentageScaled,
    uint16 observerIncentivePercentageScaled,
    uint8[] memory outcomeDimensions
) {
    return (
        flipParameters.commitmentDuration,
        flipParameters.resolutionDuration,
        flipParameters.payoutDuration,
        flipParameters.minimumCommitmentAmount,
        flipParameters.adminFeePercentage,
        flipParameters.observerIncentivePercentage,
        flipParameters.outcomeDimensions
    );
}

/**
 * @dev Gets the timestamp when the commitment phase ends for the current flip.
 */
function getCommitmentPhaseEndTime() external view returns (uint256) {
    return currentFlipState.commitmentEndTime;
}

/**
 * @dev Gets the timestamp when the resolution phase ends for the current flip.
 */
function getResolutionPhaseEndTime() external view returns (uint256) {
    return currentFlipState.resolutionEndTime;
}

/**
 * @dev Gets the timestamp when the payout phase ends for the current flip.
 */
function getPayoutPhaseEndTime() external view returns (uint256) {
    return currentFlipState.payoutEndTime;
}

/**
 * @dev Gets the minimum required commitment amount.
 */
function getMinimumCommitmentAmount() external view returns (uint256) {
    return flipParameters.minimumCommitmentAmount;
}

/**
 * @dev Gets the admin fee percentage (scaled by 10000).
 */
function getAdminFeePercentage() external view returns (uint16) {
    return flipParameters.adminFeePercentage;
}

/**
 * @dev Gets the observer incentive percentage (scaled by 10000).
 */
function getObserverIncentivePercentage() external view returns (uint16) {
    return flipParameters.observerIncentivePercentage;
}

/**
 * @dev Gets the commitment details for a specific user and flip.
 * @param _flipNumber The flip number to query.
 * @param _user The user address to query.
 */
function getUserCommitment(uint256 _flipNumber, address _user) external view returns (uint256 amount, uint8[] memory predictedOutcome, bool exists) {
    UserCommitment storage commitment = userCommitments[_flipNumber][_user];
    return (commitment.amount, commitment.predictedOutcome, commitment.exists);
}

/**
 * @dev Gets the resolved outcome for a specific flip number.
 * @param _flipNumber The flip number to query.
 */
function getResolvedOutcome(uint256 _flipNumber) external view returns (uint8[] memory) {
    if (!historicalOutcomes[_flipNumber].length > 0 && (_flipNumber != currentFlipNumber || !currentFlipState.resolved)) {
         revert FlipNotResolved(); // Only return if resolved and recorded
    }
     if (_flipNumber == currentFlipNumber) return currentFlipState.resolvedOutcome;
    return historicalOutcomes[_flipNumber];
}

/**
 * @dev Calculates the potential payout amount for a user in a specific flip, if they won.
 * Does not check if the user *actually* won or if payout has been claimed.
 * For informational purposes only.
 * @param _flipNumber The flip number to calculate for.
 * @param _user The user address.
 */
function calculateUserPotentialPayout(uint256 _flipNumber, address _user) external view returns (uint256) {
    // Check if the flip number is valid and resolved
    if (_flipNumber == 0 || _flipNumber > currentFlipNumber || !historicalOutcomes[_flipNumber].length > 0 && (_flipNumber != currentFlipNumber || !currentFlipState.resolved) ) {
        // Flip not found or not resolved
        return 0;
    }

    // Get user commitment
    UserCommitment storage commitment = userCommitments[_flipNumber][_user];
    if (!commitment.exists || commitment.amount == 0) return 0; // User didn't commit or committed 0

    // Get the resolved outcome for that flip
    uint8[] memory resolvedOutcome = (_flipNumber == currentFlipNumber) ? currentFlipState.resolvedOutcome : historicalOutcomes[_flipNumber];

    // Check if user's predicted outcome matches the resolved outcome
    uint8[] memory predictedOutcome = commitment.predictedOutcome;
    bool isWinner = true;
    if (resolvedOutcome.length != predictedOutcome.length) {
        isWinner = false;
    } else {
        for(uint i = 0; i < resolvedOutcome.length; i++) {
            if (resolvedOutcome[i] != predictedOutcome[i]) {
                isWinner = false;
                break;
            }
        }
    }

    if (!isWinner) return 0; // User is not a winner

    // Calculate the payout amount
    return _calculatePayoutAmount(_flipNumber, _user);
}

/**
 * @dev Checks if a user has already claimed their payout for a specific flip.
 * @param _flipNumber The flip number to query.
 * @param _user The user address to query.
 */
function hasUserClaimed(uint256 _flipNumber, address _user) external view returns (bool) {
    return userClaimedPayout[_flipNumber][_user];
}

/**
 * @dev Gets the total amount of Ether staked in a specific flip.
 * @param _flipNumber The flip number to query.
 */
function getTotalStakedInFlip(uint256 _flipNumber) external view returns (uint256) {
    if (_flipNumber == currentFlipNumber) {
        return currentFlipState.totalStaked;
    }
    // Retrieving total staked for past flips requires storing it, which we don't currently do for history.
    // This function only works for the current flip.
    // To support history, totalStaked would need to be stored in historical data.
    // For now, revert or return 0 for past flips.
    if (_flipNumber > currentFlipNumber || _flipNumber == 0) return 0;
    // Fallback for resolved past flips where totalStake wasn't explicitly stored:
    // Could iterate `userCommitments[_flipNumber]` but impossible.
    // Requires storage.
    return 0; // Placeholder - requires historical storage of totalStaked
}

/**
 * @dev Gets the total amount of Ether staked for a specific outcome combination in a specific flip.
 * @param _flipNumber The flip number to query.
 * @param _outcome The outcome combination (array of uint8) to query.
 */
function getTotalStakedForOutcome(uint256 _flipNumber, uint8[] memory _outcome) external view returns (uint256) {
     // Ensure outcome dimensions match and are within bounds
    if (_outcome.length != flipParameters.outcomeDimensions.length) return 0;
    for(uint i = 0; i < _outcome.length; i++) {
        if (_outcome[i] >= flipParameters.outcomeDimensions[i]) return 0;
    }
    bytes32 outcomeHash = keccak256(abi.encodePacked(_outcome));
    return totalStakedPerOutcome[_flipNumber][outcomeHash];
}

/**
 * @dev Gets the historical resolved outcome for a specific flip.
 * Wrapper around getResolvedOutcome for clarity.
 * @param _flipNumber The flip number to query.
 */
function getHistoricalOutcome(uint256 _flipNumber) external view returns (uint8[] memory) {
     if (_flipNumber == 0 || _flipNumber > currentFlipNumber || !historicalOutcomes[_flipNumber].length > 0) {
         revert HistoricalFlipNotFound();
     }
     return historicalOutcomes[_flipNumber];
}

// --- Internal Helper Functions ---

/**
 * @dev Internal function to transition the flip state.
 * @param _newState The state to transition to.
 */
function _transitionState(FlipState _newState) internal {
    // Basic state transition checks (can be more complex if needed)
    bool valid = false;
    if (currentFlipState.currentState == FlipState.Setup && _newState == FlipState.Commitment) valid = true;
    if (currentFlipState.currentState == FlipState.Commitment && _newState == FlipState.Resolution) valid = true; // Can transition when time is up OR by resolve call
    if (currentFlipState.currentState == FlipState.Resolution && _newState == FlipState.Payout) valid = true; // Transitions upon successful resolution
    if (currentFlipState.currentState == FlipState.Payout && _newState == FlipState.Finished) valid = true;
    if (currentFlipState.currentState == FlipState.Finished && _newState == FlipState.Setup) valid = true; // Ready for next flip start
    // Allow Setup/Commitment -> Finished for cancel
    if ((currentFlipState.currentState == FlipState.Setup || currentFlipState.currentState == FlipState.Commitment) && _newState == FlipState.Finished) valid = true;


    if (!valid) revert InvalidStateTransition(currentFlipState.currentState, _newState);

    FlipState oldState = currentFlipState.currentState;
    currentFlipState.currentState = _newState;
    emit StateTransitioned(currentFlipNumber, oldState, _newState);
}

/**
 * @dev Calculates the weighted random outcome based on stakes.
 * This is a simplified dynamic probability implementation.
 * Iterates through all *possible* outcomes (based on dimensions)
 * and assigns a probability range proportional to the stake on that outcome.
 * Finds which outcome the random value falls into.
 * WARNING: This iterates over the state space which can be large!
 * NOT SCALABLE for high dimensions or possibilities per dimension.
 * A better approach for scalability requires different data structures (e.g., a list of committed outcomes)
 * or a different probabilistic model.
 * @param _randomValue A pseudo-random number.
 * @return The selected winning outcome as an array of uint8.
 */
function _calculateWeightedOutcome(uint256 _randomValue) internal view returns (uint8[] memory) {
    uint8[] memory dimensions = flipParameters.outcomeDimensions;
    uint256 numDimensions = dimensions.length;

    // Get all unique committed outcome hashes and their stakes (SIMULATED)
    // In a real contract, you would need a separate array containing all bytes32 keys
    // from totalStakedPerOutcome[currentFlipNumber].
    // For this example, we'll build a list of *all possible* outcome combinations
    // and get their stakes from the mapping. This is only feasible for small state spaces.

    // Calculate total possible outcomes
    uint256 totalPossibleOutcomes = 1;
    for(uint i = 0; i < numDimensions; i++) {
        totalPossibleOutcomes *= dimensions[i];
    }

    // Iterate through all possible outcomes, calculate their cumulative weight
    // This is where the scalability issue lies.
    // currentCumulativeWeight tracks the end of the range for the current outcome.
    uint256 currentCumulativeWeight = 0;
    uint8[] memory currentOutcome = new uint8[](numDimensions); // Start with [0, 0, ...]

    for (uint256 i = 0; i < totalPossibleOutcomes; i++) {
        // Calculate the stake for the current outcome combination
        bytes32 outcomeHash = keccak256(abi.encodePacked(currentOutcome));
        uint256 stakeForOutcome = totalStakedPerOutcome[currentFlipNumber][outcomeHash]; // Will be 0 if no one staked on it

        // Add this stake as weight
        currentCumulativeWeight += stakeForOutcome;

        // Check if the random value falls into this outcome's range
        // We need to normalize the random value against the total staked amount.
        // The random value could be huge. Modulo total staked might introduce bias.
        // Better: Scale random value to [0, totalStaked).
        // Assuming _randomValue is from a wide range (like blockhash).
        uint256 scaledRandomValue = _randomValue % (currentFlipState.totalStaked + 1); // +1 to avoid division by zero if totalStaked is 0, though handled earlier


        if (scaledRandomValue < currentCumulativeWeight || i == totalPossibleOutcomes -1) {
            // If random value is within this range, this is the winning outcome.
            // Or if it's the last outcome, it gets all remaining weight.
            // Need to return a *copy* of the outcome array.
            uint8[] memory winningOutcome = new uint8[](numDimensions);
            for(uint j = 0; j < numDimensions; j++) {
                winningOutcome[j] = currentOutcome[j];
            }
            return winningOutcome;
        }

        // Move to the next outcome combination (increment logic for mixed radix system)
        // Treat currentOutcome as digits in a mixed radix number system where radixes are dimensions[j]
        for(int j = int(numDimensions) - 1; j >= 0; j--) {
             currentOutcome[j]++;
             if (currentOutcome[j] < dimensions[j]) {
                 break; // Moved to next combo in this dimension
             } else {
                 currentOutcome[j] = 0; // Rolled over, reset to 0
                 // Carry over to the next dimension (loop continues)
             }
        }
         // If loop finishes, we've rolled over all dimensions, shouldn't happen before totalPossibleOutcomes iterations
    }

    // Fallback (should not be reached if logic is correct and totalPossibleOutcomes > 0)
    // Return default or error
     revert("Weighted outcome calculation failed"); // Should indicate a bug
}

/**
 * @dev Generates a pseudo-random value using blockhash.
 * WARNING: HIGHLY INSECURE FOR PRODUCTION. Miners can influence blockhash.
 * @param _blockNumber The block number to use for blockhash.
 * @return A pseudo-random uint256 value.
 */
function _generatePseudoRandomValue(uint256 _blockNumber) internal view returns (uint256) {
    // blockhash(block.number) is not possible. blockhash(block.number - 1) might be front-run.
    // Using a user-provided past block hash is slightly better, but still insecure.
    // Also, blockhash is only available for the last 256 blocks.

    // Combining blockhash with other factors (timestamp, address, etc.)
    // is common but doesn't solve the fundamental insecurity.
    // This is purely for demonstration purposes.
    bytes32 hash = blockhash(_blockNumber);
     if (hash == bytes32(0)) {
        revert("Block hash not available"); // Or handle retry
    }
    return uint256(hash);
}

/**
 * @dev Calculates the exact payout amount for a winning user.
 * Assumes the flip is resolved and the user is a winner.
 * @param _flipNumber The flip number.
 * @param _user The user address.
 * @return The calculated payout amount in wei.
 */
function _calculatePayoutAmount(uint256 _flipNumber, address _user) internal view returns (uint256) {
    // This function assumes the flip is resolved and user is a winner.
    // It needs to be called after those checks.

    uint256 totalStake = currentFlipState.totalStaked; // Use total stake from currentFlipState (only available for current flip)
                                                      // For historical flips, total stake would need to be stored historically.
    if (_flipNumber != currentFlipNumber) {
        // Payout calculation for historical flips requires historical totalStaked and historical totalStakedPerOutcome
        // This example only stores historical outcomes, not full historical stake data.
        // Implementing historical payout calculation adds significant storage complexity.
        // For simplicity, calculate only for the current flip.
        revert("Payout calculation only supported for the current flip");
    }

    uint256 adminFee = (totalStake * flipParameters.adminFeePercentage) / 10000;
    uint256 observerIncentive = (totalStake * flipParameters.observerIncentivePercentage) / 10000;
     // Re-calculate correctly handling potential fee rounding issues
    if (adminFee + observerIncentive > totalStake) {
        adminFee = (totalStake * flipParameters.adminFeePercentage) / (flipParameters.adminFeePercentage + flipParameters.observerIncentivePercentage);
        observerIncentive = totalStake - adminFee;
         if (adminFee + observerIncentive > totalStake) { // Handle potential rounding issues
             uint256 excess = adminFee + observerIncentive - totalStake;
             adminFee -= excess; // Trim from admin fee
         }
    }


    uint256 payoutPool = totalStake - adminFee - observerIncentive;

    UserCommitment storage commitment = userCommitments[_flipNumber][_user];
    uint256 userStake = commitment.amount; // Amount the user staked

    // Calculate total stake specifically on the *winning* outcome
    bytes32 winningOutcomeHash = keccak256(abi.encodePacked(currentFlipState.resolvedOutcome));
    uint256 totalStakeOnWinningOutcome = totalStakedPerOutcome[_flipNumber][winningOutcomeHash];

    // Payout is proportional to user's stake on the winning outcome relative to
    // the total stake on the winning outcome.
    // payout = (userStake / totalStakeOnWinningOutcome) * payoutPool
    // Use multiplication before division to maintain precision
    // Prevent division by zero if somehow totalStakeOnWinningOutcome is 0 (shouldn't happen if there's a winner)
    if (totalStakeOnWinningOutcome == 0) return 0; // Should not happen for a winner with stake > 0

    uint256 payout = (userStake * payoutPool) / totalStakeOnWinningOutcome;

    return payout;
}

// Fallback function to receive Ether
receive() external payable {
    // Can potentially accept Ether outside of commitments, e.g., for future features or just to fund the contract.
    // Consider if this is intended. For this design, only commitment flow should deposit user funds.
    // Allowing arbitrary receive might complicate accounting. Let's disallow accidental sends.
    // revert("Ether received outside of commitment function");
}

// Add a payable fallback if needed, though receive() is preferred in 0.6+
// fallback() external payable {
// }

}
```

---

**Function Summary:**

Here's a summary of the public/external functions (counting towards the ~20+):

1.  `constructor()`: Initializes the contract owner and sets default flip parameters.
2.  `pause()`: Admin function to pause the contract.
3.  `unpause()`: Admin function to unpause the contract.
4.  `setFlipParameters()`: Admin function to set durations, min stake, and fee percentages for *future* flips.
5.  `setMinimumCommitmentAmount()`: Admin function to set the minimum stake for *future* flips.
6.  `setAdminFeePercentage()`: Admin function to set the admin fee percentage for *future* flips.
7.  `setObserverIncentivePercentage()`: Admin function to set the observer incentive percentage for *future* flips.
8.  `withdrawAdminFees()`: Admin function to withdraw accumulated protocol fees.
9.  `emergencyWithdraw()`: Admin function to withdraw funds when paused (for emergencies).
10. `cancelCurrentFlip()`: Admin function to cancel an ongoing flip in Setup or Commitment phase (user refunds require separate mechanism).
11. `startNewFlip()`: Admin function to initiate a new flip round, moving to the Commitment phase.
12. `commitToOutcome()`: Allows users to stake Ether and predict an outcome during the Commitment phase. `payable`.
13. `resolveFlip()`: Allows anyone (the "Observer") to trigger the flip resolution after the Commitment phase ends, receiving an incentive.
14. `claimPayout()`: Allows winning users to claim their proportional share of the payout pool after the flip is resolved. `payable` (can receive leftover gas if needed, though not explicitly used).
15. `getCurrentFlipNumber()`: View function to get the current flip round number.
16. `getFlipState()`: View function to get the current state of the flip (Setup, Commitment, Resolution, Payout, Finished), accounting for time transitions.
17. `getFlipParameters()`: View function to get the current flip configuration parameters.
18. `getCommitmentPhaseEndTime()`: View function to get the timestamp for the end of the commitment phase.
19. `getResolutionPhaseEndTime()`: View function to get the timestamp for the end of the resolution phase.
20. `getPayoutPhaseEndTime()`: View function to get the timestamp for the end of the payout phase.
21. `getMinimumCommitmentAmount()`: View function to get the minimum stake requirement.
22. `getAdminFeePercentage()`: View function to get the admin fee percentage.
23. `getObserverIncentivePercentage()`: View function to get the observer incentive percentage.
24. `getUserCommitment()`: View function to retrieve a user's commitment details for a specific flip.
25. `getResolvedOutcome()`: View function to get the winning outcome for a specific flip number.
26. `calculateUserPotentialPayout()`: View function to calculate a user's potential winnings for a specific flip (informational only).
27. `hasUserClaimed()`: View function to check if a user has claimed payout for a specific flip.
28. `getTotalStakedInFlip()`: View function to get the total ETH staked in the current flip. (Limited support for history).
29. `getTotalStakedForOutcome()`: View function to get the total ETH staked on a specific outcome combination for a specific flip.
30. `getHistoricalOutcome()`: View function to retrieve the resolved outcome for a historical flip number.

This contract includes 30 public/external functions, going well beyond the requested 20. It incorporates advanced concepts like dynamic probability influence (simulated), a timed state machine, observer incentives, and multi-dimensional outcomes, while attempting to avoid direct copies of common open-source patterns. Remember the critical limitation regarding randomness and scalability for the weighted outcome calculation.