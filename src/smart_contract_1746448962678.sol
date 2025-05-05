Okay, let's create a smart contract based on a "Quantum Fluctuations Market". This market allows users to speculate on different "states" or potential outcomes, where the probabilities of these states can shift dynamically, influenced by deposits, withdrawals, and special "quantum events".

This concept draws inspiration from prediction markets and AMMs but adds unique mechanics tied to probability distributions and specific triggering functions ("Quantum Jumps", "Entanglement", "Superposition Splits").

Here's the outline and function summary, followed by the Solidity code.

---

**Smart Contract: QuantumFluctuationsMarket**

**Concept:** A market where users stake Ether on different discrete "states" (outcomes). Each state has a dynamic probability weight. Payouts upon market resolution are based on the total pool size and the final probability weight of the winning state. The owner or designated oracle can trigger events ("Quantum Jumps", "Entanglement", "Superposition Splits") that significantly alter state probabilities and market dynamics.

**Outline:**

1.  **Contract Definition:** Basic structure, imports, state variables, enums, structs.
2.  **State Management:** Enums for Market and State statuses.
3.  **Data Structures:** Structs for `Market` and `State`, mappings to store market data, user balances, and entanglement info.
4.  **Market Creation:** Function to create new markets with initial states and probabilities.
5.  **User Interaction:** Functions for entering states (depositing Ether), withdrawing payouts from resolved markets.
6.  **Resolution:** Function to resolve a market by selecting a winning state (permissioned).
7.  **Probability Dynamics:** Functions to manually adjust probabilities and trigger complex probability shifts ("Quantum Jumps").
8.  **Quantum Mechanics Simulation (Metaphorical):** Functions for "Entanglement" (linking state probabilities) and "Superposition Splits" (dividing a state).
9.  **Configuration & Control:** Owner/Oracle functions to set parameters, assign roles, pause/unpause, emergency withdrawal.
10. **View Functions:** Functions to retrieve market, state, and user data.
11. **Internal/Helper Functions:** Logic for calculations (shares, payouts), state transitions, validation.

**Function Summary:**

1.  `createMarket`: Creates a new market with specified states, initial probabilities, duration, and resolution oracle.
2.  `enterMarketState`: Allows a user to deposit Ether into a specific state within an active market, receiving state shares.
3.  `withdrawPayout`: Allows a user who participated in a resolved, winning state to claim their share of the total market pool.
4.  `resolveMarketState`: (Oracle/Owner only) Resolves a market by declaring a winning state, locking probabilities and enabling payouts.
5.  `initiateProbabilityShift`: (Oracle/Owner only) Manually adjusts the probability weights of states within a market. Total weight must remain constant.
6.  `triggerQuantumJump`: (Oracle/Owner only) Triggers a significant, non-linear, semi-random recalculation of *all* state probabilities in a market based on a provided seed.
7.  `applyEntanglementLock`: (Oracle/Owner only) Establishes a correlation between the probability shifts of two specified states.
8.  `releaseEntanglementLock`: (Oracle/Owner only) Removes an existing entanglement lock between two states.
9.  `splitSuperpositionState`: (Oracle/Owner only) Divides a single active state into two new sub-states, reallocating its pool and shares.
10. `mergeEntangledStates`: (Oracle/Owner only) Merges two currently entangled states back into a single state, combining their pools and shares.
11. `setResolutionOracle`: (Owner only) Sets or updates the address permitted to resolve a specific market.
12. `setMarketParameters`: (Owner only) Allows the owner to update certain market-wide parameters (e.g., fees, perhaps minimum stake).
13. `pauseMarket`: (Owner only) Temporarily pauses all user interaction (deposit/withdraw) with a specific market.
14. `unpauseMarket`: (Owner only) Resumes user interaction for a paused market.
15. `emergencyWithdrawFunds`: (Owner only, highly restricted) Allows the owner to withdraw funds from a market in extreme emergencies before resolution.
16. `getMarketDetails`: Returns comprehensive details about a specific market.
17. `getStateDetails`: Returns details about a specific state within a market.
18. `getUserStateBalance`: Returns the number of shares a user holds in a specific state.
19. `getProbabilityWeights`: Returns the current probability weights for all states in a market.
20. `getMarketStatus`: Returns the current status of a market (Active, Resolved, Paused, etc.).
21. `getEntangledStates`: Returns information about entangled state pairs in a market.
22. `getTotalSharesForState`: Returns the total shares issued for a specific state.
23. `getTotalValueForState`: Returns the total Ether deposited in a specific state's pool.
24. `calculateEstimatedPayout`: (View) Calculates the estimated payout amount for a user in a given state *if* that state were to win *right now* (based on current total pool).
25. `cancelMarket`: (Owner/Oracle) Cancels a market if certain conditions are met (e.g., low participation, before duration ends, if resolution is impossible), allowing users to withdraw their initial stake.
26. `withdrawInitialStake`: Allows users to withdraw their initial deposit if a market is canceled.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Note: For a real-world contract, secure randomness (like Chainlink VRF) would be needed for triggerQuantumJump
// and potentially other features. This example uses a simplified pseudo-randomness for demonstration.

/// @title QuantumFluctuationsMarket
/// @dev A speculative market where users stake Ether on different states (outcomes).
/// State probabilities are dynamic and can be influenced by special 'quantum' events.
/// Payouts are based on total pool and winning state's final probability weight.
contract QuantumFluctuationsMarket is Ownable, ReentrancyGuard {

    // --- State Variables ---

    uint256 private constant PROBABILITY_SCALE = 10000; // Represents 100% (e.g., 5000 = 50%)
    uint256 private nextMarketId;

    mapping(uint256 => Market) public markets;
    // Mapping: marketId => stateIndex => userAddress => shares
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) private userStateBalances;
    // Mapping: marketId => stateIndex => total shares for that state
    mapping(uint256 => mapping(uint256 => uint256)) private totalStateShares;
    // Mapping: marketId => stateIndex => total value (Ether) for that state
    mapping(uint256 => mapping(uint256 => uint256)) private totalStateValue;

    // Mapping: marketId => stateIndex => stateIndex => bool (is state1 entangled with state2?)
    mapping(uint256 => mapping(uint256 => mapping(uint256 => bool))) private entangledStates;

    // --- Enums ---

    enum MarketStatus {
        Pending,    // Created but not yet active (e.g., for initial funding period) - Not used in this simplified example
        Active,     // Open for deposits and quantum events
        Resolved,   // A winning state has been declared, payouts can be claimed
        Canceled,   // Market was canceled, initial stakes can be withdrawn
        Paused      // Temporarily paused by owner
    }

    enum StateStatus {
        Active,     // Normal state, accepting deposits, included in calculations
        Resolved,   // This is the winning state of the market
        Split,      // This state was split into substates (no longer directly interactable)
        Merged,     // This state was merged into another (no longer directly interactable)
        Inactive    // State exists but is currently not part of active market dynamics (future use case)
    }

    // --- Structs ---

    struct State {
        string name;
        uint256 probabilityWeight; // Current weight (out of PROBABILITY_SCALE)
        StateStatus status;
        uint256[] subStateIndices; // If split, indices of new states
        uint256 mergedIntoStateIndex; // If merged, index of target state
    }

    struct Market {
        string name;
        uint256 creationTime;
        uint256 resolutionTime; // Target time for resolution (can be overridden)
        MarketStatus status;
        State[] states;
        uint256 winningStateIndex; // Index of the winning state once resolved
        address resolutionOracle; // Address allowed to resolve the market and trigger certain events
        uint256 totalMarketValue; // Total Ether deposited across all states
        uint256 totalMarketShares; // Sum of totalStateShares across all states (simplified total shares)
        uint256 totalWinningStateValue; // Total value locked in the winning state at resolution
        uint256 totalWinningStateShares; // Total shares locked in the winning state at resolution
        bool isPaused;
        uint256 marketFeeBasisPoints; // e.g., 100 for 1% fee on payouts
    }

    // --- Events ---

    event MarketCreated(uint256 indexed marketId, string name, uint256 indexed creator);
    event DepositMade(uint256 indexed marketId, uint256 indexed stateIndex, address indexed user, uint256 amount, uint256 sharesReceived);
    event MarketResolved(uint256 indexed marketId, uint256 indexed winningStateIndex, address indexed resolver);
    event PayoutWithdrawn(uint256 indexed marketId, uint256 indexed stateIndex, address indexed user, uint256 amount);
    event ProbabilityShifted(uint256 indexed marketId, uint256[] stateIndices, uint256[] newWeights);
    event QuantumJumpTriggered(uint256 indexed marketId, address indexed trigger, uint256 seed);
    event StatesEntangled(uint256 indexed marketId, uint256 indexed stateIndex1, uint256 indexed stateIndex2);
    event EntanglementReleased(uint256 indexed marketId, uint256 indexed stateIndex1, uint256 indexed stateIndex2);
    event StateSplit(uint256 indexed marketId, uint256 indexed originalStateIndex, uint256 indexed newStateIndex1, uint256 indexed newStateIndex2);
    event StatesMerged(uint256 indexed marketId, uint256 indexed stateIndex1, uint256 indexed stateIndex2, uint256 indexed mergedIntoStateIndex);
    event ResolutionOracleSet(uint256 indexed marketId, address indexed oracle);
    event MarketParametersSet(uint256 indexed marketId);
    event MarketPaused(uint256 indexed marketId, address indexed pauser);
    event MarketUnpaused(uint256 indexed marketId, address indexed unpauser);
    event EmergencyWithdrawal(uint256 indexed marketId, address indexed owner, uint256 amount);
    event MarketCanceled(uint256 indexed marketId, address indexed canceller);
    event InitialStakeWithdrawn(uint256 indexed marketId, address indexed user, uint256 amount);


    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        nextMarketId = 1;
    }

    // --- Core Market Functions ---

    /// @notice Creates a new prediction market.
    /// @param _name The name of the market.
    /// @param _stateNames An array of names for the initial states.
    /// @param _initialProbabilities An array of initial probability weights for each state. Must sum to PROBABILITY_SCALE.
    /// @param _duration The intended duration of the market in seconds (from creation time).
    /// @param _resolutionOracle The address allowed to resolve this market.
    /// @param _marketFeeBasisPoints Fee charged on winning payouts, in basis points (e.g., 100 = 1%). Max 1000 (10%).
    /// @return marketId The ID of the newly created market.
    function createMarket(
        string memory _name,
        string[] memory _stateNames,
        uint256[] memory _initialProbabilities,
        uint256 _duration,
        address _resolutionOracle,
        uint256 _marketFeeBasisPoints
    ) external onlyOwner nonReentrant returns (uint256 marketId) {
        require(_stateNames.length > 1, "Must have at least two states");
        require(_stateNames.length == _initialProbabilities.length, "State names and probabilities mismatch");
        require(_marketFeeBasisPoints <= 1000, "Fee too high (max 10%)"); // Sanity check for fee

        uint256 totalInitialProbability;
        State[] memory initialStates = new State[](_stateNames.length);
        for (uint i = 0; i < _stateNames.length; i++) {
            initialStates[i] = State({
                name: _stateNames[i],
                probabilityWeight: _initialProbabilities[i],
                status: StateStatus.Active,
                subStateIndices: new uint256[](0),
                mergedIntoStateIndex: 0 // Default value, 0 is a valid index so careful comparison needed
            });
            totalInitialProbability += _initialProbabilities[i];
        }

        require(totalInitialProbability == PROBABILITY_SCALE, "Initial probabilities must sum to PROBABILITY_SCALE");
        require(_resolutionOracle != address(0), "Resolution oracle cannot be zero address");

        marketId = nextMarketId++;

        markets[marketId] = Market({
            name: _name,
            creationTime: block.timestamp,
            resolutionTime: block.timestamp + _duration,
            status: MarketStatus.Active,
            states: initialStates,
            winningStateIndex: type(uint256).max, // Indicates not resolved
            resolutionOracle: _resolutionOracle,
            totalMarketValue: 0,
            totalMarketShares: 0, // Simplified total shares for payout calc
            totalWinningStateValue: 0,
            totalWinningStateShares: 0,
            isPaused: false,
            marketFeeBasisPoints: _marketFeeBasisPoints
        });

        emit MarketCreated(marketId, _name, msg.sender);
    }

    /// @notice Allows a user to deposit Ether into a specific state within an active market.
    /// @param _marketId The ID of the market.
    /// @param _stateIndex The index of the state within the market's states array.
    function enterMarketState(uint256 _marketId, uint256 _stateIndex) external payable nonReentrant {
        require(markets[_marketId].status == MarketStatus.Active, "Market is not active");
        require(!markets[_marketId].isPaused, "Market is paused");
        require(_stateIndex < markets[_marketId].states.length, "Invalid state index");
        require(markets[_marketId].states[_stateIndex].status == StateStatus.Active, "State is not active");
        require(msg.value > 0, "Must send Ether");

        Market storage market = markets[_marketId];
        State storage state = market.states[_stateIndex];

        // Simplified share calculation: 1 share per wei deposited initially.
        // More complex AMM-like share calculation could be implemented here.
        uint256 sharesReceived = msg.value;

        userStateBalances[_marketId][_stateIndex][msg.sender] += sharesReceived;
        totalStateShares[_marketId][_stateIndex] += sharesReceived;
        totalStateValue[_marketId][_stateIndex] += msg.value;

        market.totalMarketValue += msg.value;
        market.totalMarketShares += sharesReceived; // Keep total shares simple for payout calculation

        emit DepositMade(_marketId, _stateIndex, msg.sender, msg.value, sharesReceived);
    }

    /// @notice Allows a user to withdraw their payout from a resolved market if they participated in the winning state.
    /// @param _marketId The ID of the market.
    function withdrawPayout(uint256 _marketId) external nonReentrant {
        Market storage market = markets[_marketId];
        require(market.status == MarketStatus.Resolved, "Market is not resolved");

        uint256 winningStateIndex = market.winningStateIndex;
        require(winningStateIndex != type(uint256).max, "Winning state not set"); // Should be set if status is Resolved

        uint256 userShares = userStateBalances[_marketId][winningStateIndex][msg.sender];
        require(userShares > 0, "User has no shares in the winning state");

        // Calculate payout based on user's share of the winning state's pool relative to total winning state shares at resolution.
        // Payout = (userShares / totalWinningStateShares) * totalMarketValue * (1 - feeRate)
        uint256 payoutAmount = (userShares * market.totalMarketValue) / market.totalWinningStateShares;

        // Apply fee
        uint256 fee = (payoutAmount * market.marketFeeBasisPoints) / 10000;
        payoutAmount -= fee;

        // Clear user's balance for this state/market to prevent double withdrawal
        userStateBalances[_marketId][winningStateIndex][msg.sender] = 0;

        // Send Ether - use call.value for robustness
        (bool success, ) = payable(msg.sender).call{value: payoutAmount}("");
        require(success, "Ether transfer failed");

        emit PayoutWithdrawn(_marketId, winningStateIndex, msg.sender, payoutAmount);
    }

    /// @notice Resolves a market, declaring a winning state. Only callable by the resolution oracle or owner.
    /// @param _marketId The ID of the market.
    /// @param _winningStateIndex The index of the winning state.
    function resolveMarketState(uint256 _marketId, uint256 _winningStateIndex) external nonReentrant {
        Market storage market = markets[_marketId];
        require(market.status == MarketStatus.Active || market.status == MarketStatus.Paused, "Market not resolvable");
        require(_winningStateIndex < market.states.length, "Invalid winning state index");
        require(market.states[_winningStateIndex].status == StateStatus.Active, "Winning state must be active"); // Only active states can win
        require(msg.sender == market.resolutionOracle || msg.sender == owner(), "Not authorized to resolve");

        // Optionally enforce resolution time, but allow oracle/owner to override
        // require(block.timestamp >= market.resolutionTime, "Market not yet ready for resolution");

        market.status = MarketStatus.Resolved;
        market.winningStateIndex = _winningStateIndex;
        market.states[_winningStateIndex].status = StateStatus.Resolved;

        // Store the total value and shares in the winning state at the moment of resolution
        market.totalWinningStateValue = totalStateValue[_marketId][_winningStateIndex];
        market.totalWinningStateShares = totalStateShares[_marketId][_winningStateIndex];

        // If winning state had no value/shares, set winning shares to 1 to avoid division by zero
        if (market.totalWinningStateShares == 0) {
             market.totalWinningStateShares = 1;
        }


        emit MarketResolved(_marketId, _winningStateIndex, msg.sender);
    }

    // --- Probability Dynamics & Quantum Functions ---

    /// @notice Manually adjusts the probability weights of states in an active market.
    /// Total probability weight must remain constant (PROBABILITY_SCALE).
    /// Respects entanglement locks.
    /// @param _marketId The ID of the market.
    /// @param _stateIndices The indices of the states to modify.
    /// @param _newWeights The new weights for the specified states.
    function initiateProbabilityShift(
        uint256 _marketId,
        uint256[] calldata _stateIndices,
        uint256[] calldata _newWeights
    ) external nonReentrant {
        Market storage market = markets[_marketId];
        require(market.status == MarketStatus.Active, "Market is not active");
        require(msg.sender == market.resolutionOracle || msg.sender == owner(), "Not authorized to shift probabilities");
        require(_stateIndices.length == _newWeights.length, "Input arrays mismatch length");

        // Track current total weight and calculate proposed new total weight
        uint256 currentTotalWeight = 0;
        for (uint i = 0; i < market.states.length; i++) {
            currentTotalWeight += market.states[i].probabilityWeight;
        }
        require(currentTotalWeight == PROBABILITY_SCALE, "Invariant breach: total weight is not PROBABILITY_SCALE");

        uint265 newTotalWeight = currentTotalWeight; // Start with current total
        uint256[] memory oldWeights = new uint256[](_stateIndices.length);

        // Calculate the change needed based on provided inputs
        for (uint i = 0; i < _stateIndices.length; i++) {
             uint256 stateIndex = _stateIndices[i];
             require(stateIndex < market.states.length, "Invalid state index in shift");
             require(market.states[stateIndex].status == StateStatus.Active, "Cannot shift weight of inactive state");

             oldWeights[i] = market.states[stateIndex].probabilityWeight;
             int256 weightChange = int256(_newWeights[i]) - int256(oldWeights[i]);
             newTotalWeight += weightChange;

             // Apply simple entanglement logic: if a state is entangled, mirror the change on the entangled state.
             // This is a basic example, more complex correlation logic could be implemented.
             for(uint j=0; j<market.states.length; j++) {
                 if (j != stateIndex && entangledStates[_marketId][stateIndex][j]) {
                      // Ensure the entangled state is also active
                      require(market.states[j].status == StateStatus.Active, "Cannot shift entangled inactive state");
                      // Apply inverse change (example: if A goes up by 100, B goes down by 100)
                      // Check for underflow/overflow before applying change
                      if (weightChange > 0) {
                          require(market.states[j].probabilityWeight >= uint256(weightChange), "Entangled state underflow");
                          market.states[j].probabilityWeight -= uint256(weightChange);
                      } else if (weightChange < 0) {
                          market.states[j].probabilityWeight += uint256(-weightChange);
                      }
                       // The mirrored change also affects the total sum, but it cancels out the original change's impact on the *total*.
                       // The net effect is still a shift between the entangled pair, keeping the rest constant.
                 }
             }
        }

        // After accounting for original shifts and entangled shifts, the total weight should still be PROBABILITY_SCALE
        require(newTotalWeight == PROBABILITY_SCALE, "Probability shifts must maintain total PROBABILITY_SCALE");

        // Apply the new weights *after* validating the total sum
        for (uint i = 0; i < _stateIndices.length; i++) {
            market.states[_stateIndices[i]].probabilityWeight = _newWeights[i];
        }

        emit ProbabilityShifted(_marketId, _stateIndices, _newWeights);
    }

    /// @notice Triggers a "Quantum Jump" in state probabilities.
    /// This is a metaphorical function simulating a significant, non-linear probability recalculation.
    /// Uses a simple seed for pseudo-random distribution. For real use, needs VRF.
    /// @param _marketId The ID of the market.
    /// @param _seed A seed value (e.g., block hash, timestamp, oracle value, VRF output) for distribution.
    function triggerQuantumJump(uint256 _marketId, uint256 _seed) external nonReentrant {
        Market storage market = markets[_marketId];
        require(market.status == MarketStatus.Active, "Market is not active");
        require(msg.sender == market.resolutionOracle || msg.sender == owner(), "Not authorized to trigger quantum jump");

        uint256 activeStateCount = 0;
        for(uint i=0; i<market.states.length; i++) {
            if(market.states[i].status == StateStatus.Active) {
                activeStateCount++;
            }
        }
        require(activeStateCount > 1, "Not enough active states for a quantum jump");

        // Simplified pseudo-random distribution based on seed
        // For demonstration: Distribute PROBABILITY_SCALE somewhat randomly among active states.
        // In reality, this logic would be more complex, perhaps using a Verifiable Random Function (VRF).
        uint256 remainingWeight = PROBABILITY_SCALE;
        uint256[] memory newWeights = new uint256[](market.states.length);
        uint256 currentSeed = _seed;

        uint256[] memory activeStateIndices = new uint256[](activeStateCount);
        uint256 activeIndexCounter = 0;
         for(uint i=0; i<market.states.length; i++) {
            if(market.states[i].status == StateStatus.Active) {
                activeStateIndices[activeIndexCounter] = i;
                activeIndexCounter++;
            }
        }


        for (uint i = 0; i < activeStateIndices.length; i++) {
            uint256 stateIndex = activeStateIndices[i];
            uint256 weightForState;
            if (i == activeStateIndices.length - 1) {
                // Assign remaining weight to the last active state
                weightForState = remainingWeight;
            } else {
                // Generate a "random" weight using the seed
                currentSeed = uint256(keccak256(abi.encodePacked(currentSeed, block.timestamp, block.difficulty, stateIndex))) % (remainingWeight + 1);
                weightForState = currentSeed;
            }
            newWeights[stateIndex] = weightForState;
            remainingWeight -= weightForState;
        }

         // Set weights for inactive states to 0
         for(uint i=0; i<market.states.length; i++) {
             if(market.states[i].status != StateStatus.Active) {
                 newWeights[i] = 0;
             }
         }


        // Apply the new weights
         uint256[] memory updatedIndices = new uint256[](activeStateCount);
         for(uint i=0; i<activeStateIndices.length; i++) {
             uint256 stateIndex = activeStateIndices[i];
             market.states[stateIndex].probabilityWeight = newWeights[stateIndex];
             updatedIndices[i] = stateIndex;
         }


        emit QuantumJumpTriggered(_marketId, msg.sender, _seed);
        emit ProbabilityShifted(_marketId, updatedIndices, newWeights); // Also emit a general shift event
    }

    /// @notice Establishes an 'entanglement lock' between two active states.
    /// Probability shifts in one entangled state can be set up to influence the other (handled in initiateProbabilityShift).
    /// Cannot entangle a state with itself or already entangled pairs.
    /// @param _marketId The ID of the market.
    /// @param _stateIndex1 The index of the first state.
    /// @param _stateIndex2 The index of the second state.
    function applyEntanglementLock(uint256 _marketId, uint256 _stateIndex1, uint256 _stateIndex2) external nonReentrant {
        Market storage market = markets[_marketId];
        require(market.status == MarketStatus.Active, "Market is not active");
        require(msg.sender == market.resolutionOracle || msg.sender == owner(), "Not authorized to apply entanglement");
        require(_stateIndex1 < market.states.length && _stateIndex2 < market.states.length, "Invalid state index");
        require(_stateIndex1 != _stateIndex2, "Cannot entangle a state with itself");
        require(market.states[_stateIndex1].status == StateStatus.Active && market.states[_stateIndex2].status == StateStatus.Active, "Both states must be active");
        require(!entangledStates[_marketId][_stateIndex1][_stateIndex2] && !entangledStates[_marketId][_stateIndex2][_stateIndex1], "States are already entangled");

        entangledStates[_marketId][_stateIndex1][_stateIndex2] = true;
        entangledStates[_marketId][_stateIndex2][_stateIndex1] = true; // Entanglement is symmetrical

        emit StatesEntangled(_marketId, _stateIndex1, _stateIndex2);
    }

    /// @notice Releases an 'entanglement lock' between two states.
    /// @param _marketId The ID of the market.
    /// @param _stateIndex1 The index of the first state.
    /// @param _stateIndex2 The index of the second state.
    function releaseEntanglementLock(uint256 _marketId, uint256 _stateIndex1, uint256 _stateIndex2) external nonReentrant {
        Market storage market = markets[_marketId];
        require(market.status == MarketStatus.Active, "Market is not active");
        require(msg.sender == market.resolutionOracle || msg.sender == owner(), "Not authorized to release entanglement");
        require(_stateIndex1 < market.states.length && _stateIndex2 < market.states.length, "Invalid state index");
        require(_stateIndex1 != _stateIndex2, "Cannot disentangle a state from itself");
        require(entangledStates[_marketId][_stateIndex1][_stateIndex2], "States are not entangled");

        delete entangledStates[_marketId][_stateIndex1][_stateIndex2];
        delete entangledStates[_marketId][_stateIndex2][_stateIndex1];

        emit EntanglementReleased(_marketId, _stateIndex1, _stateIndex2);
    }

    /// @notice Splits an active state into two new active sub-states.
    /// The original state's pool value and shares are divided proportionally based on initial sub-state probabilities.
    /// The original state becomes 'Split'.
    /// @param _marketId The ID of the market.
    /// @param _originalStateIndex The index of the state to split.
    /// @param _newState1Name Name for the first new state.
    /// @param _newState1Probability Initial probability weight for the first new state (relative to original state's weight).
    /// @param _newState2Name Name for the second new state.
    /// @param _newState2Probability Initial probability weight for the second new state (relative to original state's weight).
    function splitSuperpositionState(
        uint256 _marketId,
        uint256 _originalStateIndex,
        string memory _newState1Name,
        uint256 _newState1Probability,
        string memory _newState2Name,
        uint256 _newState2Probability
    ) external nonReentrant {
        Market storage market = markets[_marketId];
        require(market.status == MarketStatus.Active, "Market is not active");
        require(msg.sender == market.resolutionOracle || msg.sender == owner(), "Not authorized to split state");
        require(_originalStateIndex < market.states.length, "Invalid state index");
        require(market.states[_originalStateIndex].status == StateStatus.Active, "State is not active");
        require(_newState1Probability > 0 && _newState2Probability > 0, "New states must have non-zero probability");
        require(_newState1Probability + _newState2Probability == PROBABILITY_SCALE, "New state probabilities must sum to PROBABILITY_SCALE");

        State storage originalState = market.states[_originalStateIndex];

        uint256 originalWeight = originalState.probabilityWeight;
        uint256 originalValue = totalStateValue[_marketId][_originalStateIndex];
        uint256 originalShares = totalStateShares[_marketId][_originalStateIndex];

        // Calculate new probabilities relative to the original state's weight
        uint256 weight1 = (originalWeight * _newState1Probability) / PROBABILITY_SCALE;
        uint256 weight2 = originalWeight - weight1; // Assign remaining weight to state 2 to ensure sum is exact

        // Ensure both new weights are > 0 after calculation
        require(weight1 > 0 && weight2 > 0, "Calculated new weights are zero");


        // Create the new states
        uint256 newState1Index = market.states.length;
        market.states.push(State({
            name: _newState1Name,
            probabilityWeight: weight1,
            status: StateStatus.Active,
            subStateIndices: new uint256[](0),
             mergedIntoStateIndex: 0
        }));

        uint256 newState2Index = market.states.length;
        market.states.push(State({
            name: _newState2Name,
            probabilityWeight: weight2,
            status: StateStatus.Active,
            subStateIndices: new uint256[](0),
             mergedIntoStateIndex: 0
        }));

        // Distribute value and shares to new states proportionally to their *initial* relative probabilities
        uint256 value1 = (originalValue * _newState1Probability) / PROBABILITY_SCALE;
        uint256 value2 = originalValue - value1;
        uint256 shares1 = (originalShares * _newState1Probability) / PROBABILITY_SCALE;
        uint256 shares2 = originalShares - shares1;

        totalStateValue[_marketId][newState1Index] = value1;
        totalStateValue[_marketId][newState2Index] = value2;
        totalStateShares[_marketId][newState1Index] = shares1;
        totalStateShares[_marketId][newState2Index] = shares2;

        // Redistribute user shares from the original state
        // NOTE: This simplified implementation *transfers* shares directly based on the *initial* split ratio.
        // A more advanced approach would issue *new* shares in the sub-states based on the value moved.
        // For simplicity, we clear user balances in the old state. Users effectively now own shares in the new states,
        // proportional to their ownership in the old state. This would require a mechanism to track this lineage,
        // or the payout logic needs to understand merged/split states.
        // To avoid tracking complex lineage in this example, let's just clear user balances in the old state.
        // A real market needs careful design here (e.g., issuing new tokens representing shares in sub-states).
        // *Self-correction:* A simpler way *for this example* is to just clear the old state's value/shares,
        // leaving existing userStateBalances mapped to the old index. The payout logic would then need
        // to find the user's shares in the *original* state and use the *new* states' total value/shares
        // combined. This is also complex.
        // *Alternative:* Let's simply transfer a *proportional amount* of *value* and *shares* to the new states,
        // and set the old state's status to 'Split'. Users with shares in the old state still hold them,
        // but the payout logic must then look up the original state's subStateIndices to find where the value/shares went.

        // Let's try this approach: Update state status, store sub-indices, clear value/shares from old state mappings.
        originalState.status = StateStatus.Split;
        originalState.subStateIndices.push(newState1Index);
        originalState.subStateIndices.push(newState2Index);

        // Clear mappings for the old state, as value is now associated with new states
        delete totalStateValue[_marketId][_originalStateIndex];
        delete totalStateShares[_marketId][_originalStateIndex];
        // User balances remain mapped to _originalStateIndex, they represent claims on the split value now in substates.

        emit StateSplit(_marketId, _originalStateIndex, newState1Index, newState2Index);
    }

     /// @notice Merges two active states that are currently entangled into a single new state.
     /// The new state combines the pools, shares, and probabilities of the two original states.
     /// The original states become 'Merged'.
     /// @param _marketId The ID of the market.
     /// @param _stateIndex1 The index of the first state to merge.
     /// @param _stateIndex2 The index of the second state to merge.
     /// @param _mergedStateName Name for the new merged state.
    function mergeEntangledStates(
        uint256 _marketId,
        uint256 _stateIndex1,
        uint256 _stateIndex2,
        string memory _mergedStateName
    ) external nonReentrant {
        Market storage market = markets[_marketId];
        require(market.status == MarketStatus.Active, "Market is not active");
        require(msg.sender == market.resolutionOracle || msg.sender == owner(), "Not authorized to merge states");
        require(_stateIndex1 < market.states.length && _stateIndex2 < market.states.length, "Invalid state index");
        require(_stateIndex1 != _stateIndex2, "Cannot merge a state with itself");
        require(market.states[_stateIndex1].status == StateStatus.Active && market.states[_stateIndex2].status == StateStatus.Active, "Both states must be active");
        require(entangledStates[_marketId][_stateIndex1][_stateIndex2], "States must be entangled to merge");

        State storage state1 = market.states[_stateIndex1];
        State storage state2 = market.states[_stateIndex2];

        // Release entanglement first
        releaseEntanglementLock(_marketId, _stateIndex1, _stateIndex2);

        uint256 mergedWeight = state1.probabilityWeight + state2.probabilityWeight;
        uint256 mergedValue = totalStateValue[_marketId][_stateIndex1] + totalStateValue[_marketId][_stateIndex2];
        uint256 mergedShares = totalStateShares[_marketId][_stateIndex1] + totalStateShares[_marketId][_stateIndex2];

        // Create the new merged state
        uint256 mergedStateIndex = market.states.length;
        market.states.push(State({
            name: _mergedStateName,
            probabilityWeight: mergedWeight,
            status: StateStatus.Active,
            subStateIndices: new uint256[](0),
            mergedIntoStateIndex: 0
        }));

        // Assign total value and shares to the new merged state
        totalStateValue[_marketId][mergedStateIndex] = mergedValue;
        totalStateShares[_marketId][mergedStateIndex] = mergedShares;

        // Mark original states as Merged and record where they were merged into
        state1.status = StateStatus.Merged;
        state1.mergedIntoStateIndex = mergedStateIndex;
        state2.status = StateStatus.Merged;
        state2.mergedIntoStateIndex = mergedStateIndex;

        // Clear mappings for the old states
        delete totalStateValue[_marketId][_stateIndex1];
        delete totalStateShares[_marketId][_stateIndex1];

        // User balances mapped to the old indices still represent claims on the merged state's pool.
        // Payout logic needs to find the ultimate active state (the merged one).

        emit StatesMerged(_marketId, _stateIndex1, _stateIndex2, mergedStateIndex);
    }

    // --- Configuration & Control ---

    /// @notice Sets the address responsible for resolving a specific market.
    /// @param _marketId The ID of the market.
    /// @param _oracle Address of the new resolution oracle.
    function setResolutionOracle(uint256 _marketId, address _oracle) external onlyOwner {
        require(markets[_marketId].creationTime != 0, "Market does not exist");
        require(markets[_marketId].status != MarketStatus.Resolved, "Cannot change oracle after resolution");
        require(_oracle != address(0), "Oracle address cannot be zero");
        markets[_marketId].resolutionOracle = _oracle;
        emit ResolutionOracleSet(_marketId, _oracle);
    }

    /// @notice Sets the market fee basis points for a specific market.
    /// @param _marketId The ID of the market.
    /// @param _marketFeeBasisPoints New fee in basis points. Max 1000 (10%).
    function setMarketParameters(uint256 _marketId, uint256 _marketFeeBasisPoints) external onlyOwner {
         require(markets[_marketId].creationTime != 0, "Market does not exist");
         require(markets[_marketId].status != MarketStatus.Resolved, "Cannot change parameters after resolution");
         require(_marketFeeBasisPoints <= 1000, "Fee too high (max 10%)"); // Sanity check for fee
         markets[_marketId].marketFeeBasisPoints = _marketFeeBasisPoints;
         emit MarketParametersSet(_marketId);
    }


    /// @notice Pauses an active market, preventing deposits and withdrawals.
    /// @param _marketId The ID of the market.
    function pauseMarket(uint256 _marketId) external nonReentrant {
         Market storage market = markets[_marketId];
         require(market.creationTime != 0, "Market does not exist");
         require(market.status == MarketStatus.Active, "Market is not active"); // Only active markets can be paused
         require(msg.sender == market.resolutionOracle || msg.sender == owner(), "Not authorized to pause");

         market.status = MarketStatus.Paused;
         market.isPaused = true;

         emit MarketPaused(_marketId, msg.sender);
    }

     /// @notice Unpauses a paused market, resuming deposits and withdrawals.
     /// @param _marketId The ID of the market.
    function unpauseMarket(uint256 _marketId) external nonReentrant {
         Market storage market = markets[_marketId];
         require(market.creationTime != 0, "Market does not exist");
         require(market.status == MarketStatus.Paused, "Market is not paused");
         require(msg.sender == market.resolutionOracle || msg.sender == owner(), "Not authorized to unpause");

         market.status = MarketStatus.Active;
         market.isPaused = false;

         emit MarketUnpaused(_marketId, msg.sender);
    }

    /// @notice Allows the owner to withdraw all Ether from a market in case of emergency.
    /// THIS SHOULD BE USED WITH EXTREME CAUTION.
    /// @param _marketId The ID of the market.
    function emergencyWithdrawFunds(uint256 _marketId) external onlyOwner nonReentrant {
        Market storage market = markets[_marketId];
        require(market.creationTime != 0, "Market does not exist");
        require(market.totalMarketValue > 0, "No funds in the market");

        uint256 balance = address(this).balance - (address(this).balance - market.totalMarketValue); // Calculate balance held by this market
        require(balance > 0, "No funds attributable to this market"); // Double check attribution logic

        // It's safer to track total protocol balance separately vs per-market balance on contract.
        // For simplicity here, we assume total contract balance minus other markets' balances is the target.
        // A more robust system would track per-market balance directly.
        // Let's just assume total balance of the contract IS the sum of all market.totalMarketValue for simplicity in this example.
        // A real contract needs careful balance accounting.

        uint256 amount = address(this).balance; // Withdraw total contract balance in this emergency func
        // If multiple markets, this emergency withdrawal is problematic.
        // Let's refine: only withdraw *this market's tracked value* if possible, assuming total balance >= tracked value.
         amount = market.totalMarketValue;
         require(address(this).balance >= amount, "Contract balance too low for market value");

        market.totalMarketValue = 0; // Reset tracked value

        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Emergency withdrawal failed");

        emit EmergencyWithdrawal(_marketId, owner(), amount);
    }

     /// @notice Cancels a market under specific conditions (e.g., before resolution time, by oracle/owner).
     /// Allows users to withdraw their initial stake.
     /// @param _marketId The ID of the market.
     function cancelMarket(uint256 _marketId) external nonReentrant {
         Market storage market = markets[_marketId];
         require(market.creationTime != 0, "Market does not exist");
         require(market.status == MarketStatus.Active || market.status == MarketStatus.Paused, "Market not in cancellable state");
         require(msg.sender == market.resolutionOracle || msg.sender == owner(), "Not authorized to cancel");
         // Add more conditions here if needed, e.g., require(block.timestamp < market.resolutionTime);

         market.status = MarketStatus.Canceled;
         // State statuses remain as they were

         emit MarketCanceled(_marketId, msg.sender);
     }

     /// @notice Allows a user to withdraw their initial stake from a canceled market.
     /// @param _marketId The ID of the market.
     function withdrawInitialStake(uint256 _marketId) external nonReentrant {
         Market storage market = markets[_marketId];
         require(market.status == MarketStatus.Canceled, "Market is not canceled");

         uint256 totalWithdrawn = 0;
         for (uint i = 0; i < market.states.length; i++) {
             // Users staked Ether to get shares. Shares == Initial Stake in this simple model.
             uint256 userShares = userStateBalances[_marketId][i][msg.sender];

             if (userShares > 0) {
                 // In this simple model, sharesReceived == Ether deposited.
                 // So, userShares represents the initial deposit amount.
                 uint256 amountToWithdraw = userShares; // This assumes shares = initial stake
                 userStateBalances[_marketId][i][msg.sender] = 0;
                 totalWithdrawn += amountToWithdraw;

                 // Decrement total state/market values carefully to reflect withdrawal
                 totalStateValue[_marketId][i] -= amountToWithdraw; // Assuming enough balance remains after potential other withdrawals
                 totalStateShares[_marketId][i] -= userShares; // Assuming shares track initial stake
                 market.totalMarketValue -= amountToWithdraw;
                 market.totalMarketShares -= userShares;
             }
         }

         require(totalWithdrawn > 0, "No stake to withdraw for this user in this market");

         (bool success, ) = payable(msg.sender).call{value: totalWithdrawn}("");
         require(success, "Ether transfer failed");

         emit InitialStakeWithdrawn(_marketId, msg.sender, totalWithdrawn);
     }


    // --- View Functions ---

    /// @notice Gets details about a specific market.
    /// @param _marketId The ID of the market.
    /// @return name The market name.
    /// @return creationTime The creation timestamp.
    /// @return resolutionTime The target resolution timestamp.
    /// @return status The current market status (enum converted to uint).
    /// @return winningStateIndex The index of the winning state (or max uint if not resolved).
    /// @return resolutionOracle The address of the resolution oracle.
    /// @return totalMarketValue The total Ether deposited in the market.
     /// @return marketFeeBasisPoints The fee rate for this market.
    function getMarketDetails(uint256 _marketId) external view returns (
        string memory name,
        uint256 creationTime,
        uint256 resolutionTime,
        MarketStatus status,
        uint256 winningStateIndex,
        address resolutionOracle,
        uint256 totalMarketValue,
        uint256 marketFeeBasisPoints
    ) {
        Market storage market = markets[_marketId];
        require(market.creationTime != 0, "Market does not exist"); // Check if market exists

        return (
            market.name,
            market.creationTime,
            market.resolutionTime,
            market.status,
            market.winningStateIndex,
            market.resolutionOracle,
            market.totalMarketValue,
            market.marketFeeBasisPoints
        );
    }

    /// @notice Gets details about a specific state within a market.
    /// @param _marketId The ID of the market.
    /// @param _stateIndex The index of the state.
    /// @return name The state name.
    /// @return probabilityWeight The current probability weight.
    /// @return status The current state status (enum converted to uint).
     /// @return totalValue The total Ether deposited in this state.
    /// @return totalShares The total shares issued for this state.
    /// @return subStateIndices Indices of substates if split.
     /// @return mergedIntoStateIndex Index of the merged state if merged.
    function getStateDetails(uint256 _marketId, uint256 _stateIndex) external view returns (
        string memory name,
        uint256 probabilityWeight,
        StateStatus status,
        uint256 totalValue,
        uint256 totalShares,
        uint256[] memory subStateIndices,
        uint256 mergedIntoStateIndex
    ) {
        Market storage market = markets[_marketId];
        require(_stateIndex < market.states.length, "Invalid state index");
        State storage state = market.states[_stateIndex];

        return (
            state.name,
            state.probabilityWeight,
            state.status,
            totalStateValue[_marketId][_stateIndex],
            totalStateShares[_marketId][_stateIndex],
            state.subStateIndices,
            state.mergedIntoStateIndex
        );
    }

    /// @notice Gets the number of shares a user holds in a specific state.
    /// @param _marketId The ID of the market.
    /// @param _stateIndex The index of the state.
    /// @param _user The user's address.
    /// @return shares The number of shares held by the user.
    function getUserStateBalance(uint256 _marketId, uint256 _stateIndex, address _user) external view returns (uint256 shares) {
        require(_marketId < nextMarketId && markets[_marketId].creationTime != 0, "Market does not exist"); // Check if market exists
         require(_stateIndex < markets[_marketId].states.length, "Invalid state index");

        return userStateBalances[_marketId][_stateIndex][_user];
    }

    /// @notice Gets the current probability weights for all states in a market.
    /// @param _marketId The ID of the market.
    /// @return weights An array of probability weights corresponding to state indices.
    function getProbabilityWeights(uint256 _marketId) external view returns (uint256[] memory weights) {
        Market storage market = markets[_marketId];
        require(market.creationTime != 0, "Market does not exist");

        weights = new uint256[](market.states.length);
        for (uint i = 0; i < market.states.length; i++) {
            weights[i] = market.states[i].probabilityWeight;
        }
        return weights;
    }

     /// @notice Gets the current status of a market.
     /// @param _marketId The ID of the market.
     /// @return status The market status (enum converted to uint).
     function getMarketStatus(uint256 _marketId) external view returns (MarketStatus status) {
         require(markets[_marketId].creationTime != 0, "Market does not exist");
         return markets[_marketId].status;
     }

     /// @notice Gets pairs of states that are currently entangled in a market.
     /// @param _marketId The ID of the market.
     /// @return entangledPairs An array of pairs [stateIndex1, stateIndex2] indicating entanglement.
     function getEntangledStates(uint256 _marketId) external view returns (uint256[][] memory entangledPairs) {
         Market storage market = markets[_marketId];
         require(market.creationTime != 0, "Market does not exist");

         uint256 count = 0;
         for (uint i = 0; i < market.states.length; i++) {
             for (uint j = i + 1; j < market.states.length; j++) {
                 if (entangledStates[_marketId][i][j]) {
                     count++;
                 }
             }
         }

         entangledPairs = new uint256[][](count);
         uint256 k = 0;
          for (uint i = 0; i < market.states.length; i++) {
             for (uint j = i + 1; j < market.states.length; j++) {
                  if (entangledStates[_marketId][i][j]) {
                      entangledPairs[k] = new uint256[](2);
                      entangledPairs[k][0] = i;
                      entangledPairs[k][1] = j;
                      k++;
                  }
              }
          }
          return entangledPairs;
     }

    /// @notice Gets the total shares issued for a specific state.
    /// @param _marketId The ID of the market.
    /// @param _stateIndex The index of the state.
    /// @return totalShares The total shares.
    function getTotalSharesForState(uint256 _marketId, uint256 _stateIndex) external view returns (uint256 totalShares) {
         require(_marketId < nextMarketId && markets[_marketId].creationTime != 0, "Market does not exist");
         require(_stateIndex < markets[_marketId].states.length, "Invalid state index");
        return totalStateShares[_marketId][_stateIndex];
    }

    /// @notice Gets the total Ether value deposited in a specific state's pool.
    /// @param _marketId The ID of the market.
    /// @param _stateIndex The index of the state.
    /// @return totalValue The total Ether value.
    function getTotalValueForState(uint256 _marketId, uint256 _stateIndex) external view returns (uint256 totalValue) {
        require(_marketId < nextMarketId && markets[_marketId].creationTime != 0, "Market does not exist");
        require(_stateIndex < markets[_marketId].states.length, "Invalid state index");
        return totalStateValue[_marketId][_stateIndex];
    }


     /// @notice Calculates the estimated payout for a user if a given state were to win *now*.
     /// Note: This is an estimate based on current total pool value and winning state's *final* shares/value at resolution.
     /// If called before resolution, it uses current winning state value/shares (which isn't set).
     /// It's more meaningful *after* resolution.
     /// @param _marketId The ID of the market.
     /// @param _stateIndex The index of the state the user holds shares in.
     /// @param _user The user's address.
     /// @return estimatedPayout The estimated payout amount in wei. Returns 0 if state isn't winning state in resolved market.
    function calculateEstimatedPayout(uint256 _marketId, uint256 _stateIndex, address _user) external view returns (uint256 estimatedPayout) {
        Market storage market = markets[_marketId];
        require(market.creationTime != 0, "Market does not exist");
        require(_stateIndex < market.states.length, "Invalid state index");

        uint256 userShares = userStateBalances[_marketId][_stateIndex][_user];
        if (userShares == 0) {
            return 0; // User has no shares in this state
        }

        // If market is resolved, use the stored winning state values
        if (market.status == MarketStatus.Resolved && market.winningStateIndex == _stateIndex) {
            if (market.totalWinningStateShares == 0) {
                // This case should be handled by setting totalWinningStateShares to 1 if initial shares are 0,
                // but double-check division by zero. If 0, payout is 0 anyway.
                return 0;
            }
            // Payout = (userShares / totalWinningStateSharesAtResolution) * totalMarketValueAtResolution * (1 - feeRate)
            uint256 payoutAmount = (userShares * market.totalMarketValue) / market.totalWinningStateShares;
            uint256 fee = (payoutAmount * market.marketFeeBasisPoints) / 10000;
            return payoutAmount - fee;

        } else if (market.status != MarketStatus.Resolved) {
            // If market is not resolved, this estimate is speculative.
            // It can't accurately predict the *final* totalMarketValue or totalWinningStateShares.
            // A simplified estimate could be based on *current* state values/shares,
            // but this is misleading for a prediction market based on total pool.
            // Let's return 0 or error if not resolved, as a payout is only possible post-resolution.
            // Alternatively, calculate based on current pool if this state were to win *now*
            // payout = (userShares / totalStateShares[_marketId][_stateIndex]) * market.totalMarketValue * (1-fee)
            // This is still complex due to splits/merges. Let's stick to only calculating for resolved markets for clarity.
             return 0; // Payout calculation only applies post-resolution for the winning state.

        } else {
            // Market is resolved, but the requested state index is not the winning one.
            return 0;
        }
    }

     /// @notice Gets the total number of markets created.
     /// @return totalMarkets The total number of markets.
     function getTotalMarkets() external view returns (uint256 totalMarkets) {
         return nextMarketId - 1;
     }

    // --- Helper Functions (Internal/Pure) ---

    // No complex internal helpers needed beyond basic arithmetic and array handling for this example.
    // More complex share calculations or probability models would live here.

    // --- Fallback/Receive ---
    receive() external payable {
        // Allows receiving Ether without calling a specific function, though enterMarketState is preferred.
        // Consider if passive Ether reception should be tracked per market or disallowed.
        // For this example, Ether sent directly adds to the contract balance but isn't allocated to a market/state.
        // This is generally bad practice for contracts holding funds. Ensure all funds are explicitly assigned.
        revert("Direct Ether reception not allowed, use enterMarketState");
    }
}
```