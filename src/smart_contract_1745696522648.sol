Okay, here is a smart contract concept called `QuantumFluctuator`. It's designed around the idea of an on-chain system whose internal "state" fluctuates over time and based on external input (token "energy"), influencing probabilistic outcomes for users who interact with it. It incorporates concepts of state dynamics, entropy accumulation, phase shifts, and observer patterns, aiming to be distinct from common open-source examples.

It requires an ERC-20 token as "energy".

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Outline and Function Summary ---
/*
Contract Name: QuantumFluctuator

Purpose:
A contract that simulates a dynamic, fluctuating system on-chain.
Users inject ERC-20 energy tokens to interact. The contract's internal
"state vector" changes over time based on block data and accumulated
entropy. Interacting (sampling a fluctuation) costs energy and yields
a variable amount of energy back, determined by the current state.
The system can undergo "phase shifts" when entropy is high, causing
a significant state change. Users can "sync" to the current state
for potential bonuses or become "observers" to track state changes.

State Variables:
- energyToken: Address of the ERC-20 token used as energy.
- energyPool: Current balance of energy tokens held by the contract.
- stateVector: An array representing the core fluctuating state dimensions.
- stateEntropy: Accumulates randomness/disorder over time.
- phaseShiftThreshold: Entropy level triggering a phase shift.
- lastFluctuationBlock: Block number when the state last significantly fluctuated.
- fluctuationParams: Parameters influencing state fluctuation calculations.
- sampleCost: Energy required to sample a fluctuation.
- baseSampleReward: Base energy reward for sampling before state multiplier.
- userSyncBlocks: Mapping tracking until which block a user is synced.
- syncDurationBlocks: Number of blocks user sync lasts.
- syncCost: Energy cost to synchronize.
- quantumObservers: Mapping tracking addresses registered as observers.

Events:
- EnergyInjected(address indexed user, uint256 amount): When energy is deposited.
- FluctuationSampled(address indexed user, uint256 cost, uint256 reward, uint256[] currentState): When a user samples, showing cost, reward, and state snapshot.
- StateFluctuated(uint256[] oldState, uint256[] newState, uint256 newEntropy, uint256 blockNumber): When the internal state updates.
- PhaseShiftOccurred(uint256[] oldState, uint256[] newState, uint256 blockNumber): When a major phase shift happens.
- SyncStateActivated(address indexed user, uint256 activatedUntilBlock): When a user syncs.
- QuantumObserverRegistered(address indexed user): When an address registers as an observer.
- QuantumObserverUnregistered(address indexed user): When an address unregisters as an observer.
- ParameterUpdated(string indexed paramName, uint256 value): Generic event for single-value parameter updates.
- ParametersUpdated(string indexed paramName, uint256[] values): Generic event for array parameter updates.
- EnergyWithdrawn(address indexed owner, uint256 amount): When owner withdraws energy.

Functions:
(Total > 20 callable/view functions)

Public/External/View Functions:

1.  constructor(address initialEnergyToken, uint256 _phaseShiftThreshold, uint256[] memory initialFluctuationParams, uint256 _sampleCost, uint256 _baseSampleReward, uint256 _syncDurationBlocks, uint256 _syncCost): Initializes the contract with parameters and the energy token.
2.  injectEnergy(uint256 amount): Allows users to deposit energy tokens into the contract.
3.  sampleFluctuation(): Allows a user to pay energy to sample the current state, triggering state fluctuation and receiving a variable energy reward based on the state.
4.  syncState(): Allows a user to pay a sync cost to gain a temporary "synced" status.
5.  registerQuantumObserver(): Allows an address to register to receive state change events without interacting financially.
6.  unregisterQuantumObserver(): Allows a registered address to stop receiving observer events.
7.  queryStateVector() view: Returns the current values of the internal state vector.
8.  queryStateEntropy() view: Returns the current accumulated state entropy.
9.  queryPhaseShiftThreshold() view: Returns the current entropy threshold for phase shifts.
10. queryLastFluctuationBlock() view: Returns the block number of the last state fluctuation.
11. queryFluctuationParams() view: Returns the current parameters used in state fluctuation calculations.
12. querySampleCost() view: Returns the current energy cost to sample a fluctuation.
13. queryBaseSampleReward() view: Returns the current base energy reward for sampling.
14. queryEnergyPool() view: Returns the contract's current balance of the energy token.
15. queryUserSyncStatus(address user) view: Returns the block number until which a user is synced.
16. querySyncDurationBlocks() view: Returns the duration of the sync state in blocks.
17. querySyncCost() view: Returns the energy cost to sync.
18. queryIsQuantumObserver(address user) view: Returns true if the user is a registered observer.
19. predictNextFluctuationBounds() view: Provides an illustrative projection of the possible range for the next state values based on current parameters (simplified for example).
20. queryTimeSinceLastFluctuation() view: Returns the number of blocks elapsed since the last state fluctuation.
21. queryPredictedPhaseShiftBlock() view: Provides an illustrative estimate of the block number when the next phase shift might occur based on current entropy accumulation (simplified).
22. setStateFluctuationParams(uint256[] memory params) onlyOwner: Sets the parameters for state fluctuation calculations.
23. setPhaseShiftThreshold(uint256 threshold) onlyOwner: Sets the entropy threshold for phase shifts.
24. setSampleCost(uint256 cost) onlyOwner: Sets the energy cost for sampling.
25. setBaseSampleReward(uint256 reward) onlyOwner: Sets the base energy reward for sampling.
26. setSyncDurationBlocks(uint256 duration) onlyOwner: Sets the duration of the user sync state.
27. setSyncCost(uint256 cost) onlyOwner: Sets the energy cost to sync.
28. withdrawEnergy(uint256 amount) onlyOwner: Allows the owner to withdraw energy tokens from the contract.
29. setEnergyToken(address tokenAddress) onlyOwner: Sets the energy token address (dangerous, handle with care).

Internal Functions:

- _fluctuateState(): Internal function to update the state vector based on block data and entropy.
- _accumulateEntropy(): Internal function to increase state entropy over time.
- _checkAndApplyPhaseShift(): Internal function to check if a phase shift is needed and apply it.
- _applyPhaseShift(): Internal function to dramatically change the state vector and reset entropy.
- _calculateFluctuationEffect(): Internal function to determine the reward multiplier based on the current state.
- _getRandomness(uint256 seed) pure: Internal helper for deriving pseudo-randomness from block data and a seed.
- _decayUserSync(): Internal function to decrement sync duration (checked implicitly by block number).

*/

contract QuantumFluctuator is Ownable, ReentrancyGuard {

    IERC20 public energyToken;
    uint256 public energyPool;

    // State variables simulating quantum state
    uint256[4] public stateVector; // Example: 4 dimensions
    uint256 public stateEntropy;
    uint256 public phaseShiftThreshold;
    uint256 public lastFluctuationBlock;
    uint256[] public fluctuationParams; // Parameters for state calculations

    // Interaction parameters
    uint256 public sampleCost;
    uint256 public baseSampleReward;

    // User sync feature
    mapping(address => uint256) public userSyncBlocks; // Block number until synced
    uint256 public syncDurationBlocks;
    uint256 public syncCost;
    uint256 private constant SYNC_BONUS_MULTIPLIER = 120; // 120/100 = 20% bonus

    // Quantum Observers
    mapping(address => bool) public quantumObservers;

    // Events
    event EnergyInjected(address indexed user, uint256 amount);
    event FluctuationSampled(address indexed user, uint256 cost, uint256 reward, uint256[] currentState);
    event StateFluctuated(uint256[] oldState, uint256[] newState, uint256 newEntropy, uint256 blockNumber);
    event PhaseShiftOccurred(uint256[] oldState, uint256[] newState, uint256 blockNumber);
    event SyncStateActivated(address indexed user, uint256 activatedUntilBlock);
    event QuantumObserverRegistered(address indexed user);
    event QuantumObserverUnregistered(address indexed user);
    event ParameterUpdated(string indexed paramName, uint256 value);
    event ParametersUpdated(string indexed paramName, uint256[] values);
    event EnergyWithdrawn(address indexed owner, uint256 amount);


    /// @notice Initializes the QuantumFluctuator contract.
    /// @param initialEnergyToken Address of the ERC-20 token used for energy.
    /// @param _phaseShiftThreshold The entropy level to trigger a phase shift.
    /// @param initialFluctuationParams Parameters influencing state dynamics (length must match stateVector dimensions).
    /// @param _sampleCost Energy required for a single fluctuation sample.
    /// @param _baseSampleReward Base reward before state-based multiplier.
    /// @param _syncDurationBlocks Duration of user sync status in blocks.
    /// @param _syncCost Energy cost to activate sync status.
    constructor(
        address initialEnergyToken,
        uint256 _phaseShiftThreshold,
        uint256[] memory initialFluctuationParams,
        uint256 _sampleCost,
        uint256 _baseSampleReward,
        uint256 _syncDurationBlocks,
        uint256 _syncCost
    ) Ownable(msg.sender) {
        require(initialFluctuationParams.length == stateVector.length, "Initial params length mismatch");
        energyToken = IERC20(initialEnergyToken);
        phaseShiftThreshold = _phaseShiftThreshold;
        fluctuationParams = initialFluctuationParams;
        sampleCost = _sampleCost;
        baseSampleReward = _baseSampleReward;
        syncDurationBlocks = _syncDurationBlocks;
        syncCost = _syncCost;

        // Initialize state based on constructor params and block data
        lastFluctuationBlock = block.number;
        uint256 initialSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender)));
        for (uint i = 0; i < stateVector.length; i++) {
            stateVector[i] = (_getRandomness(initialSeed + i) % 1000) + 1; // State values between 1 and 1000 initially
        }
        stateEntropy = 0; // Start with low entropy
    }

    /// @notice Allows users to inject energy tokens into the contract.
    /// @param amount The amount of energy tokens to inject.
    function injectEnergy(uint256 amount) external nonReentrant {
        require(amount > 0, "Must inject positive amount");
        // Transfer tokens from the user to the contract
        require(energyToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        energyPool += amount; // Update internal pool tracker
        emit EnergyInjected(msg.sender, amount);
    }

    /// @notice Allows a user to sample the current state fluctuations. Costs energy and yields a variable reward.
    /// @dev Triggers state fluctuation logic and potential phase shifts.
    function sampleFluctuation() external nonReentrant {
        require(energyPool >= sampleCost, "Insufficient energy in pool");
        // User pays the sample cost
        require(energyToken.transferFrom(msg.sender, address(this), sampleCost), "Payment transfer failed");
        energyPool += sampleCost; // Energy pool increases by cost paid

        // --- Internal State Logic ---
        // 1. Accumulate entropy based on time since last fluctuation
        _accumulateEntropy();
        // 2. Fluctuate the state based on entropy and params
        _fluctuateState();
        // 3. Check for and apply phase shift if entropy is high
        _checkAndApplyPhaseShift();
        // --- End Internal State Logic ---

        // 4. Calculate reward based on current state and sync status
        uint256 reward = _calculateFluctuationEffect();

        // Apply sync bonus if active
        if (userSyncBlocks[msg.sender] > block.number) {
            reward = (reward * SYNC_BONUS_MULTIPLIER) / 100;
            // Sync status automatically decays as block.number increases past userSyncBlocks
        }

        require(energyPool >= reward, "Insufficient energy in pool for reward");
        // Transfer reward to the user
        require(energyToken.transfer(msg.sender, reward), "Reward transfer failed");
        energyPool -= reward; // Energy pool decreases by reward

        // Convert stateVector to dynamic array for event
        uint256[] memory currentStateSnapshot = new uint256[](stateVector.length);
        for(uint i = 0; i < stateVector.length; i++){
            currentStateSnapshot[i] = stateVector[i];
        }

        emit FluctuationSampled(msg.sender, sampleCost, reward, currentStateSnapshot);
    }

    /// @notice Allows a user to pay a cost to activate a temporary "synced" status.
    /// @dev Synced status might grant bonuses on fluctuations.
    function syncState() external nonReentrant {
        require(syncDurationBlocks > 0, "Sync feature not enabled");
        require(energyPool >= syncCost, "Insufficient energy in pool for sync cost");

        // User pays the sync cost
        require(energyToken.transferFrom(msg.sender, address(this), syncCost), "Sync payment transfer failed");
        energyPool += syncCost; // Energy pool increases by cost paid

        userSyncBlocks[msg.sender] = block.number + syncDurationBlocks;

        emit SyncStateActivated(msg.sender, userSyncBlocks[msg.sender]);
    }

    /// @notice Registers the sender as a quantum observer to receive state change events.
    /// @dev Observers do not interact financially but are notified of StateFluctuated and PhaseShiftOccurred events.
    function registerQuantumObserver() external {
        require(!quantumObservers[msg.sender], "Already registered observer");
        quantumObservers[msg.sender] = true;
        emit QuantumObserverRegistered(msg.sender);
    }

    /// @notice Unregisters the sender as a quantum observer.
    function unregisterQuantumObserver() external {
        require(quantumObservers[msg.sender], "Not a registered observer");
        quantumObservers[msg.sender] = false;
        emit QuantumObserverUnregistered(msg.sender);
    }

    /// @notice Returns the current values of the internal state vector.
    /// @return uint256[] An array representing the current state dimensions.
    function queryStateVector() external view returns (uint256[] memory) {
        uint256[] memory currentState = new uint256[](stateVector.length);
        for(uint i = 0; i < stateVector.length; i++){
            currentState[i] = stateVector[i];
        }
        return currentState;
    }

    /// @notice Returns the current accumulated state entropy.
    /// @return uint256 The current entropy value.
    function queryStateEntropy() external view returns (uint256) {
        return stateEntropy;
    }

    /// @notice Returns the current entropy threshold for phase shifts.
    /// @return uint256 The phase shift threshold value.
    function queryPhaseShiftThreshold() external view returns (uint256) {
        return phaseShiftThreshold;
    }

    /// @notice Returns the block number when the state last significantly fluctuated.
    /// @return uint256 The block number of the last fluctuation.
    function queryLastFluctuationBlock() external view returns (uint256) {
        return lastFluctuationBlock;
    }

    /// @notice Returns the current parameters used in state fluctuation calculations.
    /// @return uint256[] An array of fluctuation parameters.
    function queryFluctuationParams() external view returns (uint256[] memory) {
        return fluctuationParams;
    }

    /// @notice Returns the current energy cost to sample a fluctuation.
    /// @return uint256 The sample cost.
    function querySampleCost() external view returns (uint256) {
        return sampleCost;
    }

    /// @notice Returns the current base energy reward for sampling.
    /// @return uint256 The base sample reward.
    function queryBaseSampleReward() external view returns (uint256) {
        return baseSampleReward;
    }

    /// @notice Returns the contract's current balance of the energy token.
    /// @return uint256 The energy pool balance.
    function queryEnergyPool() external view returns (uint256) {
        return energyToken.balanceOf(address(this));
        // Note: energyPool state variable is tracked internally but balance might differ slightly if tokens are sent directly
        // using energyToken.balanceOf() is the canonical source of truth for actual balance
    }

    /// @notice Returns the block number until which a user is synced.
    /// @param user The address to check.
    /// @return uint256 The block number until synced, or 0 if not synced.
    function queryUserSyncStatus(address user) external view returns (uint256) {
        return userSyncBlocks[user];
    }

    /// @notice Returns the duration of the sync state in blocks.
    /// @return uint256 The sync duration in blocks.
    function querySyncDurationBlocks() external view returns (uint256) {
        return syncDurationBlocks;
    }

    /// @notice Returns the energy cost to activate sync status.
    /// @return uint256 The sync cost.
    function querySyncCost() external view returns (uint256) {
        return syncCost;
    }

    /// @notice Returns true if the user is a registered quantum observer.
    /// @param user The address to check.
    /// @return bool True if registered, false otherwise.
    function queryIsQuantumObserver(address user) external view returns (bool) {
        return quantumObservers[user];
    }

    /// @notice Provides an illustrative projection of the possible range for the next state values.
    /// @dev This is a simplified view based on current state and parameters, not a true prediction.
    /// @return uint256[] An array representing estimated min/max ranges for each state dimension [min1, max1, min2, max2, ...].
    function predictNextFluctuationBounds() external view returns (uint256[] memory) {
         uint256[] memory bounds = new uint256[](stateVector.length * 2);
         // This is highly simplified for the example. A real prediction would be complex.
         // We'll just show a range based on fluctuation params and current state.
         for (uint i = 0; i < stateVector.length; i++) {
             uint256 currentStateVal = stateVector[i];
             uint256 param = fluctuationParams[i % fluctuationParams.length];
             // Simple estimation: next value is likely within +/- param/10 of current value
             // with a lower bound of 1.
             uint256 minBound = currentStateVal > param / 10 ? currentStateVal - param / 10 : 1;
             uint256 maxBound = currentStateVal + param / 10; // Simplified max

             bounds[i * 2] = minBound;
             bounds[i * 2 + 1] = maxBound;
         }
         return bounds;
    }

    /// @notice Returns the number of blocks elapsed since the state last significantly fluctuated.
    /// @return uint256 The number of blocks.
    function queryTimeSinceLastFluctuation() external view returns (uint256) {
        return block.number - lastFluctuationBlock;
    }

    /// @notice Provides an illustrative estimate of the block number for the next phase shift.
    /// @dev This is a simplified view based on current entropy and accumulation rate.
    /// @return uint256 The estimated block number, or a very high number if threshold is 0 or unachievable soon.
    function queryPredictedPhaseShiftBlock() external view returns (uint256) {
         if (phaseShiftThreshold == 0) return type(uint256).max; // Phase shifts disabled
         if (stateEntropy >= phaseShiftThreshold) return block.number; // Shift is imminent or overdue

         // Estimate blocks needed: (threshold - current entropy) / blocks_per_entropy_unit
         // Let's assume entropy accumulates by 1 per block for simplicity in this view function
         uint256 entropyNeeded = phaseShiftThreshold - stateEntropy;
         return block.number + entropyNeeded; // Simplified: assumes constant rate
    }


    // --- Owner-only configuration functions ---

    /// @notice Sets the parameters for state fluctuation calculations.
    /// @param params The new array of fluctuation parameters. Length must match stateVector dimensions.
    function setStateFluctuationParams(uint256[] memory params) external onlyOwner {
        require(params.length == stateVector.length, "Params length mismatch");
        fluctuationParams = params;
        emit ParametersUpdated("fluctuationParams", fluctuationParams);
    }

    /// @notice Sets the entropy threshold for phase shifts.
    /// @param threshold The new phase shift threshold value.
    function setPhaseShiftThreshold(uint256 threshold) external onlyOwner {
        phaseShiftThreshold = threshold;
        emit ParameterUpdated("phaseShiftThreshold", threshold);
    }

    /// @notice Sets the energy cost for sampling a fluctuation.
    /// @param cost The new sample cost.
    function setSampleCost(uint256 cost) external onlyOwner {
        sampleCost = cost;
        emit ParameterUpdated("sampleCost", cost);
    }

    /// @notice Sets the base energy reward for sampling.
    /// @param reward The new base sample reward.
    function setBaseSampleReward(uint256 reward) external onlyOwner {
        baseSampleReward = reward;
        emit ParameterUpdated("baseSampleReward", reward);
    }

    /// @notice Sets the duration of the user sync state in blocks.
    /// @param duration The new sync duration in blocks.
    function setSyncDurationBlocks(uint256 duration) external onlyOwner {
        syncDurationBlocks = duration;
         emit ParameterUpdated("syncDurationBlocks", duration);
    }

    /// @notice Sets the energy cost to activate sync status.
    /// @param cost The new sync cost.
    function setSyncCost(uint256 cost) external onlyOwner {
        syncCost = cost;
        emit ParameterUpdated("syncCost", cost);
    }

     /// @notice Allows the owner to withdraw energy tokens from the contract.
     /// @dev Use cautiously. Should not drain funds needed for rewards.
     /// @param amount The amount of energy tokens to withdraw.
     function withdrawEnergy(uint256 amount) external onlyOwner nonReentrant {
         // Prevent withdrawing funds needed for immediate samples or syncs
         require(energyPool >= amount + sampleCost + syncCost, "Insufficient withdrawable energy"); // Simple safety check
         energyPool -= amount; // Decrease internal tracker first

         require(energyToken.transfer(owner(), amount), "Withdrawal transfer failed");
         emit EnergyWithdrawn(owner(), amount);
     }

    /// @notice Sets the address of the energy token. Use with extreme caution.
    /// @param tokenAddress The address of the new energy token contract.
    function setEnergyToken(address tokenAddress) external onlyOwner {
        require(address(energyToken) != tokenAddress, "New token address is the same");
        energyToken = IERC20(tokenAddress);
         // Note: energyPool state variable will be incorrect after this change.
         // owner would need to manually update it after verifying balances, or this function removed/modified.
         // Keeping it simple for this example. In a real contract, this is highly dangerous.
         emit ParameterUpdated("energyToken", uint256(uint160(tokenAddress))); // Casting address to uint256 for event
    }


    // --- Internal Logic Functions ---

    /// @dev Updates the state vector based on time elapsed, current entropy, and fluctuation parameters.
    /// @dev Uses block.timestamp and block.number for pseudo-randomness influence.
    function _fluctuateState() internal {
        uint256 blocksElapsed = block.number - lastFluctuationBlock;
        if (blocksElapsed == 0) {
            // State only fluctuates at least one block after the last fluctuation.
            // This prevents rapid fluctuation within the same block.
            return;
        }

        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, stateEntropy, lastFluctuationBlock)));

        uint256[] memory oldStateSnapshot = new uint256[](stateVector.length);
        for(uint i = 0; i < stateVector.length; i++){
            oldStateSnapshot[i] = stateVector[i];
        }

        for (uint i = 0; i < stateVector.length; i++) {
            uint256 param = fluctuationParams[i % fluctuationParams.length];
            uint256 currentVal = stateVector[i];

            // Fluctuation logic: influenced by seed, param, blocks elapsed, and entropy
            // Add some pseudo-randomness based on block data
            uint256 delta = (_getRandomness(seed + i) % param) + 1; // Delta between 1 and param

            // Direction: Based on another random factor
            if (_getRandomness(seed + i + 1000) % 2 == 0) {
                // Increase state value, capping at a high arbitrary limit (e.g., 10000)
                stateVector[i] = currentVal + delta;
                if (stateVector[i] > 10000) stateVector[i] = 10000;
            } else {
                // Decrease state value, ensuring minimum is 1
                stateVector[i] = currentVal > delta ? currentVal - delta : 1;
            }

            // Further influence by entropy and blocks elapsed
            // Higher entropy means more volatile changes
            uint256 entropyInfluence = stateEntropy > 0 ? (_getRandomness(seed + i + 2000) % stateEntropy) : 0;
            uint256 blockInfluence = blocksElapsed > 0 ? (_getRandomness(seed + i + 3000) % blocksElapsed) : 0;

            stateVector[i] += entropyInfluence / 10 + blockInfluence / 20; // Add some positive drift based on entropy/blocks
             if (stateVector[i] > 10000) stateVector[i] = 10000; // Re-cap

             // Add some negative drift (decay)
             uint256 decay = (_getRandomness(seed + i + 4000) % (stateVector[i] / 5)) + 1; // Decay proportional to value
             stateVector[i] = stateVector[i] > decay ? stateVector[i] - decay : 1;
        }

        lastFluctuationBlock = block.number;

        // Convert stateVector to dynamic array for event
        uint256[] memory newStateSnapshot = new uint256[](stateVector.length);
        for(uint i = 0; i < stateVector.length; i++){
            newStateSnapshot[i] = stateVector[i];
        }

        emit StateFluctuated(oldStateSnapshot, newStateSnapshot, stateEntropy, block.number);
    }

    /// @dev Increases state entropy based on blocks elapsed since last fluctuation.
    /// @dev Entropy accumulates faster if fluctuationParams are volatile (conceptually).
    function _accumulateEntropy() internal {
        uint256 blocksElapsed = block.number - lastFluctuationBlock;
        if (blocksElapsed > 0) {
            // Entropy increases by blocks elapsed, possibly modified by params or other factors
            uint256 entropyIncrease = blocksElapsed; // Simple accumulation
            // Add some variation based on current state magnitude or volatility
            for(uint i=0; i<stateVector.length; i++){
                 entropyIncrease += stateVector[i] / 100; // Example: larger state values add more entropy
            }
            stateEntropy += entropyIncrease;
        }
    }

    /// @dev Checks if the phase shift threshold is met and applies a phase shift if necessary.
    function _checkAndApplyPhaseShift() internal {
        if (stateEntropy >= phaseShiftThreshold && phaseShiftThreshold > 0) {
            _applyPhaseShift();
        }
    }

    /// @dev Applies a dramatic change to the state vector and resets entropy.
    /// @dev Simulates a major system event or transition.
    function _applyPhaseShift() internal {
        uint256[] memory oldStateSnapshot = new uint256[](stateVector.length);
        for(uint i = 0; i < stateVector.length; i++){
            oldStateSnapshot[i] = stateVector[i];
        }

        uint256 shiftSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, stateEntropy, fluctuationParams)));

        // Apply a significant transformation
        for (uint i = 0; i < stateVector.length; i++) {
            uint256 shiftFactor = (_getRandomness(shiftSeed + i) % 500) + 1; // Factor between 1 and 500
             // Combine existing state, shift factor, and params in a new way
            stateVector[i] = (stateVector[i] * shiftFactor + fluctuationParams[i % fluctuationParams.length]) % 5000 + 1; // New value between 1 and 5000
        }

        stateEntropy = stateEntropy / 2; // Entropy is partially reset but not to zero

        // Convert stateVector to dynamic array for event
        uint256[] memory newStateSnapshot = new uint256[](stateVector.length);
        for(uint i = 0; i < stateVector.length; i++){
            newStateSnapshot[i] = stateVector[i];
        }

        emit PhaseShiftOccurred(oldStateSnapshot, newStateSnapshot, block.number);
         // Also emit general state fluctuation event after the shift
        emit StateFluctuated(oldStateSnapshot, newStateSnapshot, stateEntropy, block.number);

        lastFluctuationBlock = block.number; // Reset fluctuation block after phase shift
    }


    /// @dev Calculates the energy reward multiplier based on the current state vector and entropy.
    /// @dev This is where the state directly influences the outcome.
    /// @return uint256 The calculated reward amount (baseReward * multiplier / 100).
    function _calculateFluctuationEffect() internal view returns (uint256) {
        uint256 stateInfluence = 0;
        // Example logic: Sum of state vector values influences reward
        for (uint i = 0; i < stateVector.length; i++) {
            stateInfluence += stateVector[i];
        }

        // Reward multiplier is based on state influence, potentially modified by entropy
        // High state values could mean high rewards. High entropy could add variance.
        uint256 multiplier = stateInfluence / stateVector.length; // Average state value as base multiplier
        uint256 entropyVariance = stateEntropy > 0 ? (_getRandomness(uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender)))) % stateEntropy) : 0;

        // Apply variance - could be positive or negative (within limits)
        if (_getRandomness(uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender, "variance")))) % 2 == 0) {
             multiplier += entropyVariance / 50; // Positive variance
        } else {
             multiplier = multiplier > entropyVariance / 50 ? multiplier - entropyVariance / 50 : 0; // Negative variance, min 0
        }

        // Ensure multiplier is within a reasonable range (e.g., 50% to 500% of base)
        if (multiplier < 50) multiplier = 50;
        if (multiplier > 500) multiplier = 500;

        // Calculate final reward (baseReward * multiplier / 100)
        return (baseSampleReward * multiplier) / 100;
    }

    /// @dev Helper function to derive a pseudo-random number from block data and a seed.
    /// @dev Note: block.blockhash is deprecated and unreliable past 256 blocks. block.timestamp/number are predictable.
    /// @dev This is for illustrative purposes only and NOT suitable for high-stakes randomness.
    /// @param seed An additional seed value for uniqueness.
    /// @return uint256 A pseudo-random number.
    function _getRandomness(uint256 seed) internal pure returns (uint256) {
        // Using a combination of block data and a seed. Highly deterministic on-chain.
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.number, block.difficulty, msg.sender, seed)));
    }

    // No explicit _decayUserSync needed, as queryUserSyncStatus and check in sampleFluctuation
    // implicitly compare userSyncBlocks[user] against the current block.number.
}
```