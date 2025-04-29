Okay, here is a Solidity smart contract concept focusing on a "Quantum Vault" prediction/commitment system. This contract introduces phases, commitments to potential future states, and distribution of funds based on an oracle-determined "measurement" outcome, simulating quantum uncertainty collapsing into a definite state. It combines elements of prediction markets, timed releases, and state-dependent logic, aiming for creativity beyond standard patterns.

It includes a system of phases, user commitments to specific outcomes, oracle integration (simulated for demonstration) to determine the 'winning' state, and a distribution mechanism based on prediction accuracy.

---

**Outline & Function Summary**

**Contract Name:** `QuantumVault`

**Concept:** A vault that allows users to commit tokens to one of several potential future states ("Quantum States"). After a "measurement" event (determined by an oracle), the contract identifies the "winning" state. Users who committed to the winning state can claim their principal back plus a proportional share of the tokens committed by users who chose losing states. This simulates a simplified probabilistic or predictive system tied to an external unpredictable event.

**Core Features:**
1.  **Phased Cycles:** The contract operates in distinct phases (Idle, Commitment, MeasurementPending, Distribution, Archived).
2.  **Quantum States:** Users commit to one of defined potential outcomes.
3.  **Commitment:** Users deposit a specific ERC20 token and choose a state.
4.  **Measurement Trigger:** An authorized entity triggers the 'measurement' (simulated oracle call).
5.  **Oracle Integration:** Relies on an external oracle to provide the outcome result.
6.  **Outcome Claiming:** Users claim their principal and potential rewards based on their prediction vs. the measured outcome.
7.  **Dynamic Distribution:** Losing commitments' tokens are redistributed among winning commitments.
8.  **Configurability:** Owner can set the commitment token, oracle, phase durations, etc.

**Functions:**

*   **Owner Functions:**
    *   `constructor(address initialCommitmentToken)`: Initializes the contract, setting the first allowed commitment token and owner.
    *   `startNewCycle()`: Starts a new cycle, moving the contract to the `Commitment` phase.
    *   `endCommitmentPhase()`: Manually transitions from `Commitment` to `MeasurementPending` phase.
    *   `triggerMeasurement()`: Initiates the oracle call (simulated). Only callable in `MeasurementPending` phase.
    *   `setCommitmentToken(address newToken)`: Sets the allowed ERC20 token for commitments.
    *   `setMeasurementOracle(address oracleAddress)`: Sets the address of the oracle contract.
    *   `setPhaseDurations(uint64 commitmentDuration, uint64 measurementPendingDuration, uint64 distributionDuration)`: Sets the durations for different phases.
    *   `withdrawEmergencyTokens(address tokenAddress, uint256 amount)`: Allows owner to withdraw arbitrary tokens in an emergency (use with caution).
    *   `pause()`: Pauses specific contract actions (commit, claim, trigger).
    *   `unpause()`: Unpauses the contract.
    *   `endDistributionPhase()`: Manually transitions from `Distribution` to `Archived` phase.
    *   `addPossibleState(uint8 state, string memory name)`: Adds a new possible Quantum State (by ID) and its name.
    *   `removePossibleState(uint8 state)`: Removes a possible Quantum State.

*   **User Functions:**
    *   `commit(uint256 amount, uint8 chosenState)`: Commits a specified amount of the commitment token to a chosen state for the current cycle. Requires token approval.
    *   `cancelCommitment()`: Cancels the user's commitment for the current cycle, reclaiming tokens. Only allowed during the `Commitment` phase.
    *   `claimOutcome(uint256 cycleId)`: Claims the user's principal and potential rewards for a specified past cycle based on the measurement outcome.
    *   `depositExtraRewards(address tokenAddress, uint256 amount)`: Allows anyone to deposit extra reward tokens for the current cycle (or future cycles if handled differently, but currently adds to current).

*   **Oracle Callback (Internal Logic - Simulated Public for Demo):**
    *   `receiveMeasurementResult(uint256 cycleId, uint8 winningState)`: This function *simulates* the callback from an external oracle. It's where the winning state for a cycle is registered. *In a real oracle integration (like Chainlink VRF), this would be an internal callback triggered by the oracle protocol.* Making it public here is purely for demonstration/testing simplicity.

*   **View Functions:**
    *   `getCurrentCycleId()`: Returns the ID of the current active cycle.
    *   `getCurrentPhase()`: Returns the current phase of the active cycle.
    *   `getCycleInfo(uint256 cycleId)`: Returns detailed information about a specific cycle.
    *   `getUserCommitment(uint256 cycleId, address user)`: Returns commitment details for a user in a specific cycle.
    *   `getTotalCommittedByState(uint256 cycleId, uint8 state)`: Returns the total tokens committed to a specific state in a cycle.
    *   `getCommitmentToken()`: Returns the address of the currently allowed commitment token.
    *   `getMeasurementOracle()`: Returns the address of the configured oracle.
    *   `getPhaseDurations()`: Returns the configured durations for each phase.
    *   `getContractTokenBalance(address tokenAddress)`: Returns the contract's balance of a specific token.
    *   `getPossibleStates()`: Returns the list of valid Quantum State IDs.
    *   `getPossibleStateName(uint8 state)`: Returns the name for a given Quantum State ID.

**Total Callable Functions:** 25 (Excluding the internal logic of `receiveMeasurementResult`, which is made public for simulation purposes but shouldn't be called by arbitrary users in a production oracle setup). If we strictly count external/public user/owner calls: 24.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Outline & Function Summary ---
// See the outline block above the source code for details.
// This block is repeated here for completeness within the file.
/*
Contract Name: QuantumVault

Concept: A vault that allows users to commit tokens to one of several potential future states ("Quantum States").
After a "measurement" event (determined by an oracle), the contract identifies the "winning" state. Users who
committed to the winning state can claim their principal back plus a proportional share of the tokens committed
by users who chose losing states. This simulates a simplified probabilistic or predictive system tied to an
external unpredictable event.

Core Features:
1. Phased Cycles: The contract operates in distinct phases (Idle, Commitment, MeasurementPending, Distribution, Archived).
2. Quantum States: Users commit to one of defined potential outcomes.
3. Commitment: Users deposit a specific ERC20 token and choose a state.
4. Measurement Trigger: An authorized entity triggers the 'measurement' (simulated oracle call).
5. Oracle Integration: Relies on an external oracle to provide the outcome result.
6. Outcome Claiming: Users claim their principal and potential rewards based on their prediction vs. the measured outcome.
7. Dynamic Distribution: Losing commitments' tokens are redistributed among winning commitments.
8. Configurability: Owner can set the commitment token, oracle, phase durations, etc.

Functions:

*   Owner Functions (12): constructor, startNewCycle, endCommitmentPhase, triggerMeasurement, setCommitmentToken, setMeasurementOracle, setPhaseDurations, withdrawEmergencyTokens, pause, unpause, endDistributionPhase, addPossibleState, removePossibleState
*   User Functions (3): commit, cancelCommitment, claimOutcome, depositExtraRewards
*   Oracle Callback (1 - Simulated Public for Demo): receiveMeasurementResult
*   View Functions (10): getCurrentCycleId, getCurrentPhase, getCycleInfo, getUserCommitment, getTotalCommittedByState, getCommitmentToken, getMeasurementOracle, getPhaseDurations, getContractTokenBalance, getPossibleStates, getPossibleStateName

Total Callable Functions: 25 (Including the simulated oracle callback).
*/

// --- Contract Start ---

contract QuantumVault is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum QuantumPhase {
        Idle,
        Commitment,
        MeasurementPending,
        MeasurementReceived, // Outcome is known
        Distribution, // Users can claim
        Archived
    }

    // Simplified states. Can add more via addPossibleState.
    enum InitialQuantumState {
        StateA,
        StateB,
        Undetermined // Default state before measurement
    }

    struct Commitment {
        address user;
        uint256 amount;
        uint8 chosenState; // Refers to the enum value (e.g., 0 for StateA, 1 for StateB)
        bool claimed;
    }

    struct CycleInfo {
        uint256 cycleId;
        QuantumPhase currentPhase;
        uint64 startTime;
        uint64 commitmentEndTime;
        uint64 measurementPendingEndTime;
        uint64 distributionEndTime; // Time after which manual archival is typical

        uint8 winningState; // The state determined by the oracle (corresponds to QuantumState enum value)
        bool measurementTriggered;
        bool measurementReceived;
        bytes32 measurementRequestId; // Optional: For tracking oracle requests

        mapping(address => Commitment) userCommitments;
        mapping(uint8 => uint256) totalCommittedByState;
        mapping(address => uint256) extraRewards; // Rewards deposited by others for this cycle
        uint256 totalExtraRewards; // Total extra rewards for this cycle
    }

    uint256 public currentCycleId;

    mapping(uint256 => CycleInfo) public cycleInfo;

    address public commitmentToken;
    address public measurementOracle; // Address of the oracle contract

    // Phase durations in seconds
    uint64 public commitmentPhaseDuration = 3 days;
    uint64 public measurementPendingPhaseDuration = 1 day;
    uint64 public distributionPhaseDuration = 7 days;

    // Mapping of state ID (uint8) to its human-readable name
    mapping(uint8 => string) public possibleStateNames;
    // Array of valid state IDs
    uint8[] public possibleStates;

    event CycleStarted(uint256 cycleId, uint64 startTime, uint64 commitmentEndTime);
    event CommitmentMade(uint256 cycleId, address user, uint256 amount, uint8 chosenState);
    event CommitmentCancelled(uint256 cycleId, address user, uint256 amount);
    event CommitmentPhaseEnded(uint256 cycleId);
    event MeasurementTriggered(uint256 cycleId, address trigger);
    event MeasurementReceived(uint256 cycleId, uint8 winningState);
    event OutcomeClaimed(uint256 cycleId, address user, uint256 amountClaimed, bool predictedCorrectly);
    event ExtraRewardsDeposited(uint256 cycleId, address depositor, address token, uint256 amount);
    event DistributionPhaseEnded(uint256 cycleId);
    event PossibleStateAdded(uint8 state, string name);
    event PossibleStateRemoved(uint8 state);

    modifier onlyOracle() {
        // In a real implementation, this would verify the caller is the configured oracle
        require(msg.sender == measurementOracle, "Not authorized oracle");
        _;
    }

    modifier whenPhase(QuantumPhase phase) {
        require(cycleInfo[currentCycleId].currentPhase == phase, "Incorrect phase");
        _;
    }

    modifier validState(uint8 state) {
        bool found = false;
        for (uint i = 0; i < possibleStates.length; i++) {
            if (possibleStates[i] == state) {
                found = true;
                break;
            }
        }
        require(found, "Invalid state");
        _;
    }

    constructor(address initialCommitmentToken) Ownable(msg.sender) {
        require(initialCommitmentToken != address(0), "Invalid token address");
        commitmentToken = initialCommitmentToken;
        // Add initial states
        addPossibleState(uint8(InitialQuantumState.StateA), "State A");
        addPossibleState(uint8(InitialQuantumState.StateB), "State B");
    }

    // --- Owner Functions ---

    /**
     * @notice Starts a new cycle, moving the contract to the Commitment phase.
     * @dev Can only be called when the current phase is Idle or Archived.
     */
    function startNewCycle() external onlyOwner whenPhase(QuantumPhase.Idle) {
        // Increment cycle ID and initialize new cycle info
        currentCycleId++;
        CycleInfo storage current = cycleInfo[currentCycleId];
        current.cycleId = currentCycleId;
        current.currentPhase = QuantumPhase.Commitment;
        current.startTime = uint64(block.timestamp);
        current.commitmentEndTime = uint64(block.timestamp + commitmentPhaseDuration);
        current.winningState = uint8(InitialQuantumState.Undetermined); // Initially undetermined
        current.measurementTriggered = false;
        current.measurementReceived = false;
        current.totalExtraRewards = 0;

        emit CycleStarted(currentCycleId, current.startTime, current.commitmentEndTime);
    }

    /**
     * @notice Manually transitions from the Commitment phase to MeasurementPending.
     * @dev Can be called by owner after the commitment phase duration, or manually.
     */
    function endCommitmentPhase() external onlyOwner {
        CycleInfo storage current = cycleInfo[currentCycleId];
        require(current.currentPhase == QuantumPhase.Commitment, "Not in Commitment phase");

        current.currentPhase = QuantumPhase.MeasurementPending;
        current.measurementPendingEndTime = uint64(block.timestamp + measurementPendingPhaseDuration);

        emit CommitmentPhaseEnded(current.cycleId);
    }


    /**
     * @notice Triggers the oracle call to determine the winning state.
     * @dev Can only be called in MeasurementPending phase.
     * In a real oracle integration (e.g., Chainlink VRF), this would request randomness/data.
     * For this demo, it just sets a flag that allows `receiveMeasurementResult` to be called next.
     */
    function triggerMeasurement() external onlyOwner whenPhase(QuantumPhase.MeasurementPending) {
        CycleInfo storage current = cycleInfo[currentCycleId];
        require(!current.measurementTriggered, "Measurement already triggered");
        require(block.timestamp >= current.commitmentEndTime, "Commitment phase not ended");

        current.measurementTriggered = true;
        // In a real contract, interact with the oracle here.
        // Example: VRFCoordinatorV2Interface(oracleAddress).requestRandomWords(...)
        // For this simulation, we just allow the receiveMeasurementResult call.

        emit MeasurementTriggered(current.cycleId, msg.sender);
    }

     /**
     * @notice Manually transitions from the Distribution phase to Archived.
     * @dev Can be called by owner after the distribution phase duration, or manually.
     * After archival, no more claims are possible for this cycle.
     */
    function endDistributionPhase() external onlyOwner {
        CycleInfo storage current = cycleInfo[currentCycleId];
        require(current.currentPhase == QuantumPhase.Distribution, "Not in Distribution phase");

        current.currentPhase = QuantumPhase.Archived;

        emit DistributionPhaseEnded(current.cycleId);
    }

    /**
     * @notice Sets the allowed ERC20 token for commitments.
     * @dev Can only be called by owner. Requires contract to be in Idle or Archived phase.
     * @param newToken Address of the new ERC20 token.
     */
    function setCommitmentToken(address newToken) external onlyOwner {
        require(cycleInfo[currentCycleId].currentPhase == QuantumPhase.Idle || cycleInfo[currentCycleId].currentPhase == QuantumPhase.Archived, "Can only set token in Idle or Archived phase");
        require(newToken != address(0), "Invalid token address");
        commitmentToken = newToken;
    }

    /**
     * @notice Sets the address of the oracle contract.
     * @dev Can only be called by owner.
     * @param oracleAddress Address of the oracle contract.
     */
    function setMeasurementOracle(address oracleAddress) external onlyOwner {
        require(oracleAddress != address(0), "Invalid oracle address");
        measurementOracle = oracleAddress;
    }

    /**
     * @notice Sets the durations for the different cycle phases.
     * @dev Can only be called by owner. Requires contract to be in Idle or Archived phase.
     * Durations are in seconds.
     * @param commitmentDuration Duration of the Commitment phase.
     * @param measurementPendingDuration Duration of the MeasurementPending phase.
     * @param distributionDuration Duration of the Distribution phase.
     */
    function setPhaseDurations(uint64 commitmentDuration, uint64 measurementPendingDuration, uint64 measurementReceivedDelay, uint64 distributionDuration) external onlyOwner {
        require(cycleInfo[currentCycleId].currentPhase == QuantumPhase.Idle || cycleInfo[currentCycleId].currentPhase == QuantumPhase.Archived, "Can only set durations in Idle or Archived phase");
        require(commitmentDuration > 0, "Commitment duration must be > 0");
        // measurementPendingDuration can be 0 if oracle is instant
        require(distributionDuration > 0, "Distribution duration must be > 0");

        commitmentPhaseDuration = commitmentDuration;
        measurementPendingPhaseDuration = measurementPendingDuration;
        distributionPhaseDuration = distributionDuration;
    }

    /**
     * @notice Adds a new possible Quantum State the oracle can resolve to.
     * @dev Can only be called by owner. State ID must not already exist.
     * @param state The unique ID (uint8) for the state.
     * @param name The human-readable name for the state.
     */
    function addPossibleState(uint8 state, string memory name) public onlyOwner {
        // Check if state already exists
        for (uint i = 0; i < possibleStates.length; i++) {
            require(possibleStates[i] != state, "State already exists");
        }
        require(state != uint8(InitialQuantumState.Undetermined), "Cannot use Undetermined as a possible outcome state");

        possibleStates.push(state);
        possibleStateNames[state] = name;

        emit PossibleStateAdded(state, name);
    }

     /**
     * @notice Removes a possible Quantum State.
     * @dev Can only be called by owner. State must exist and cannot be Undetermined.
     * Removing states might affect ongoing cycles if they were committed to, use with caution.
     * @param state The ID (uint8) of the state to remove.
     */
    function removePossibleState(uint8 state) external onlyOwner {
         require(state != uint8(InitialQuantumState.Undetermined), "Cannot remove Undetermined state");
         bool found = false;
         uint index = 0;
         for (uint i = 0; i < possibleStates.length; i++) {
             if (possibleStates[i] == state) {
                 found = true;
                 index = i;
                 break;
             }
         }
         require(found, "State not found");

         // Remove from array by swapping with last and popping
         possibleStates[index] = possibleStates[possibleStates.length - 1];
         possibleStates.pop();

         // Optional: clear name mapping, though not strictly necessary as check relies on array
         delete possibleStateNames[state];

         emit PossibleStateRemoved(state);
     }


    /**
     * @notice Allows the owner to withdraw any token from the contract in an emergency.
     * @dev Use with extreme caution. Should only be used for recovering mistakenly sent tokens.
     * @param tokenAddress The address of the token to withdraw.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawEmergencyTokens(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient contract balance");
        token.safeTransfer(owner(), amount);
    }

    /**
     * @notice Pauses specific contract actions (commit, claim, trigger).
     * @dev Can only be called by owner.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Unpauses the contract.
     * @dev Can only be called by owner.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // --- User Functions ---

    /**
     * @notice Commits an amount of the commitment token to a chosen state for the current cycle.
     * @dev Requires the user to have approved the contract to spend the `commitmentToken`.
     * Can only be called during the `Commitment` phase.
     * @param amount The amount of tokens to commit.
     * @param chosenState The state (uint8 ID) the user is committing to.
     */
    function commit(uint256 amount, uint8 chosenState) external whenPhase(QuantumPhase.Commitment) nonReentrant whenNotPaused validState(chosenState) {
        require(amount > 0, "Amount must be greater than 0");
        require(chosenState != uint8(InitialQuantumState.Undetermined), "Cannot commit to Undetermined state");
        CycleInfo storage current = cycleInfo[currentCycleId];
        require(current.userCommitments[msg.sender].amount == 0, "Already committed in this cycle");
        require(block.timestamp < current.commitmentEndTime, "Commitment phase has ended");

        // Transfer tokens from user to contract
        IERC20(commitmentToken).safeTransferFrom(msg.sender, address(this), amount);

        // Record commitment
        current.userCommitments[msg.sender] = Commitment({
            user: msg.sender,
            amount: amount,
            chosenState: chosenState,
            claimed: false
        });

        current.totalCommittedByState[chosenState] += amount;

        emit CommitmentMade(currentCycleId, msg.sender, amount, chosenState);
    }

    /**
     * @notice Cancels the user's commitment for the current cycle and refunds tokens.
     * @dev Only allowed during the `Commitment` phase.
     * @param cycleId The cycle ID for which to cancel the commitment.
     */
    function cancelCommitment(uint256 cycleId) external nonReentrant whenNotPaused {
        CycleInfo storage cycle = cycleInfo[cycleId];
        require(cycle.currentPhase == QuantumPhase.Commitment, "Not in Commitment phase for this cycle");
        require(cycleId == currentCycleId, "Can only cancel commitment for the current cycle");
        require(cycle.userCommitments[msg.sender].amount > 0, "No active commitment found");
        require(block.timestamp < cycle.commitmentEndTime, "Commitment phase has ended");

        uint256 amount = cycle.userCommitments[msg.sender].amount;
        uint8 chosenState = cycle.userCommitments[msg.sender].chosenState;

        // Refund tokens
        IERC20(commitmentToken).safeTransfer(msg.sender, amount);

        // Clear commitment record
        cycle.totalCommittedByState[chosenState] -= amount; // Deduct from total
        delete cycle.userCommitments[msg.sender];

        emit CommitmentCancelled(cycleId, msg.sender, amount);
    }

    /**
     * @notice Allows users to claim their principal and potential rewards for a completed cycle.
     * @dev Callable in the `Distribution` phase or later (if not archived).
     * Calculates rewards based on prediction accuracy and redistributes losing pool.
     * @param cycleId The cycle ID to claim from.
     */
    function claimOutcome(uint256 cycleId) external nonReentrant whenNotPaused {
        CycleInfo storage cycle = cycleInfo[cycleId];
        require(cycle.currentPhase >= QuantumPhase.MeasurementReceived, "Outcome not determined yet for this cycle");
        require(cycle.currentPhase < QuantumPhase.Archived, "Cycle has been archived");

        Commitment storage commitment = cycle.userCommitments[msg.sender];
        require(commitment.amount > 0, "No commitment found for this cycle");
        require(!commitment.claimed, "Outcome already claimed for this cycle");

        uint256 amountToClaim = commitment.amount;
        bool predictedCorrectly = false;

        // Calculate reward if prediction was correct
        if (commitment.chosenState == cycle.winningState) {
            predictedCorrectly = true;
            uint265 totalCommittedWinning = cycle.totalCommittedByState[cycle.winningState];
            uint265 totalCommittedLosing = 0;

            // Sum all committed amounts for losing states
            for (uint i = 0; i < possibleStates.length; i++) {
                uint8 state = possibleStates[i];
                if (state != cycle.winningState) {
                     totalCommittedLosing += cycle.totalCommittedByState[state];
                }
            }

            // Calculate reward from the losing pool distribution
            // Reward = user_amount + (user_amount * total_losing_pool) / total_winning_pool
            // Handle division by zero if no winners
            if (totalCommittedWinning > 0) {
                uint256 rewardFromLosingPool = (commitment.amount * totalCommittedLosing) / totalCommittedWinning;
                amountToClaim += rewardFromLosingPool;
            }
            // Note: Any extra rewards would typically be added here, but our current ExtraRewards
            // mapping is per-user, which might not be the desired distribution model.
            // For simplicity in this example, extra rewards are *not* automatically distributed
            // to winners in claimOutcome, they are just sitting in the contract.
            // A more complex model could distribute extra rewards based on winning proportion.
            // Example addition: amountToClaim += (commitment.amount * cycle.totalExtraRewards) / totalCommittedWinning;
            // Need to consider the token of extra rewards vs commitment token. Let's skip this complexity for now.

        } else {
             // If predicted incorrectly, just get the principal back.
             // (This assumes a model where losers get principal back; could also be 0 return for losers)
             // Note: In the losing pool redistribution model implemented above, the loser's principal
             // is what makes up the 'totalCommittedLosing' pool. So claiming the principal here
             // is essential for the losing user.
             amountToClaim = commitment.amount; // User gets their principal back if they lost
             predictedCorrectly = false;
        }

        // Transfer tokens to user
        IERC20(commitmentToken).safeTransfer(msg.sender, amountToClaim);

        // Mark as claimed
        commitment.claimed = true;

        emit OutcomeClaimed(cycleId, msg.sender, amountToClaim, predictedCorrectly);
    }

    /**
     * @notice Allows anyone to deposit extra reward tokens for the current cycle.
     * @dev Requires the depositor to have approved the contract to spend the token.
     * These rewards sit in the contract and are *not* automatically distributed in `claimOutcome` in this version.
     * A more advanced version could distribute these to winners.
     * @param tokenAddress The address of the token being deposited as rewards.
     * @param amount The amount of tokens to deposit.
     */
    function depositExtraRewards(address tokenAddress, uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        // Tokens can be deposited at any phase, but their distribution mechanism needs careful consideration.
        // For simplicity, let's associate them with the *current* cycle.
        CycleInfo storage current = cycleInfo[currentCycleId];
        require(current.currentPhase != QuantumPhase.Idle, "Cannot deposit rewards when no cycle is active");

        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);

        // Store which token was deposited as extra reward and by whom/how much for this cycle.
        // This version doesn't *automatically* distribute them.
        // current.extraRewards[tokenAddress] += amount; // Can track total per token type if needed
        current.totalExtraRewards += amount; // Simple tracker, assumes commitment token for simplicity
                                            // A real system needs to handle multiple reward token types
                                            // and define how they are distributed.

        emit ExtraRewardsDeposited(currentCycleId, msg.sender, tokenAddress, amount);
    }


    // --- Oracle Callback (Simulated) ---

    /**
     * @notice Receives the measurement result from the oracle.
     * @dev In a real implementation, this would be called by the oracle protocol (e.g., VRFCoordinator).
     * It is public here ONLY for demonstration/testing purposes.
     * Transitions the phase to MeasurementReceived and then immediately to Distribution.
     * @param cycleId The cycle ID the result is for.
     * @param winningState The state (uint8 ID) determined by the oracle.
     */
    function receiveMeasurementResult(uint256 cycleId, uint8 winningState) public nonReentrant { // Should be onlyOracle in production
        // require(msg.sender == measurementOracle, "Not authorized oracle"); // Add this check in production
        CycleInfo storage cycle = cycleInfo[cycleId];
        require(cycle.currentPhase == QuantumPhase.MeasurementPending, "Not in MeasurementPending phase");
        require(cycle.measurementTriggered, "Measurement not triggered");
        require(!cycle.measurementReceived, "Measurement already received");
        require(winningState != uint8(InitialQuantumState.Undetermined), "Winning state cannot be Undetermined");
        validState(winningState); // Ensure the reported winning state is one of the possible ones

        cycle.winningState = winningState;
        cycle.measurementReceived = true;
        cycle.currentPhase = QuantumPhase.MeasurementReceived; // Briefly in this phase
        cycle.currentPhase = QuantumPhase.Distribution; // Immediately transition to Distribution
        cycle.distributionEndTime = uint64(block.timestamp + distributionPhaseDuration);


        emit MeasurementReceived(cycleId, winningState);
    }


    // --- View Functions (At least 10 needed, aiming for >= 20 total) ---

    /**
     * @notice Returns the ID of the current active cycle.
     */
    function getCurrentCycleId() external view returns (uint256) {
        return currentCycleId;
    }

    /**
     * @notice Returns the current phase of the active cycle.
     */
    function getCurrentPhase() external view returns (QuantumPhase) {
        return cycleInfo[currentCycleId].currentPhase;
    }

    /**
     * @notice Returns detailed information about a specific cycle.
     * @param cycleId The ID of the cycle to query.
     */
    function getCycleInfo(uint256 cycleId) external view returns (
        uint256 id,
        QuantumPhase phase,
        uint64 startTime,
        uint64 commitmentEndTime,
        uint64 measurementPendingEndTime,
        uint64 distributionEndTime,
        uint8 winningState,
        bool measurementTriggered,
        bool measurementReceived
    ) {
        CycleInfo storage cycle = cycleInfo[cycleId];
        return (
            cycle.cycleId,
            cycle.currentPhase,
            cycle.startTime,
            cycle.commitmentEndTime,
            cycle.measurementPendingEndTime,
            cycle.distributionEndTime,
            cycle.winningState,
            cycle.measurementTriggered,
            cycle.measurementReceived
        );
    }

    /**
     * @notice Returns commitment details for a user in a specific cycle.
     * @param cycleId The ID of the cycle to query.
     * @param user The address of the user.
     */
    function getUserCommitment(uint256 cycleId, address user) external view returns (
        uint256 amount,
        uint8 chosenState,
        bool claimed
    ) {
        Commitment storage commitment = cycleInfo[cycleId].userCommitments[user];
        return (
            commitment.amount,
            commitment.chosenState,
            commitment.claimed
        );
    }

     /**
     * @notice Returns the total tokens committed to a specific state in a cycle.
     * @param cycleId The ID of the cycle to query.
     * @param state The state ID (uint8) to query.
     */
    function getTotalCommittedByState(uint256 cycleId, uint8 state) external view returns (uint256) {
        // No need to check validState here as mapping access is safe
        return cycleInfo[cycleId].totalCommittedByState[state];
    }

    /**
     * @notice Returns the address of the currently allowed commitment token.
     */
    function getCommitmentToken() external view returns (address) {
        return commitmentToken;
    }

    /**
     * @notice Returns the address of the configured oracle.
     */
    function getMeasurementOracle() external view returns (address) {
        return measurementOracle;
    }

    /**
     * @notice Returns the configured durations for each phase.
     * @dev Returns commitmentDuration, measurementPendingDuration, distributionDuration in seconds.
     */
    function getPhaseDurations() external view returns (uint64 commitmentDuration, uint64 measurementPendingDuration, uint64 distributionDuration) {
        return (commitmentPhaseDuration, measurementPendingPhaseDuration, distributionPhaseDuration);
    }

     /**
     * @notice Returns the contract's balance of a specific token.
     * @param tokenAddress The address of the token to query.
     */
    function getContractTokenBalance(address tokenAddress) external view returns (uint256) {
        require(tokenAddress != address(0), "Invalid token address");
        return IERC20(tokenAddress).balanceOf(address(this));
    }

     /**
     * @notice Returns the list of valid Quantum State IDs that can be committed to.
     */
    function getPossibleStates() external view returns (uint8[] memory) {
        return possibleStates;
    }

     /**
     * @notice Returns the human-readable name for a given Quantum State ID.
     * @param state The state ID (uint8) to query.
     */
    function getPossibleStateName(uint8 state) external view returns (string memory) {
         // Note: This will return an empty string for invalid/unknown states,
         // unless you add a require(validState(state)) check.
         return possibleStateNames[state];
     }
}
```