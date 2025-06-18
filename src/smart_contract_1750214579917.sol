```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumFlux
 * @author Your Name (Conceptual Design)
 * @notice A highly experimental and conceptual smart contract exploring advanced mechanics.
 * This contract manages "Flux Cycles" where users contribute value (ETH in this case)
 * to influence the 'probability' of different 'Flux States' occurring during a 'Collapse' event.
 * After collapse, rewards are distributed based on contributions to the winning state.
 * It incorporates ideas of dynamic state, probabilistic outcomes influenced by stake,
 * cycle management, and conceptual 'influence' tracking (though simplified here).
 *
 * DISCLAIMER: This is a complex, experimental design for demonstration purposes.
 * It contains advanced concepts and simplified security assumptions (like random selection).
 * DO NOT use in production without rigorous audits and improvements, especially regarding RNG.
 */

/*
 * Outline:
 * 1. State Variables and Data Structures:
 *    - Define structs for Flux States, Flux Cycles, Contributions, User Profiles.
 *    - Mappings and arrays to store active data.
 *    - Global state variables (cycle counter, pause state, owner).
 *    - Configuration variables (cycle duration, collapse trigger type).
 * 2. Events:
 *    - Log key actions like state addition, cycle start/end, contributions, collapses, rewards.
 * 3. Modifiers:
 *    - onlyOwner, whenNotPaused, whenPaused, onlyCycleActive, onlyCycleCollapsed.
 * 4. Constructor:
 *    - Initialize owner and basic state.
 * 5. State Definition Functions:
 *    - addFluxStateDefinition, updateFluxStateDefinition, removeFluxStateDefinition. (Manage blueprint states)
 * 6. Cycle Management Functions:
 *    - startNewFluxCycle, triggerCollapse (core probabilistic logic), endCurrentCycle (cleanup).
 * 7. User Interaction Functions:
 *    - contributeToFluxState, withdrawContribution (before collapse), claimRewards (after collapse).
 * 8. Query Functions:
 *    - getCurrentCycleId, getCycleDetails, getContributionDetails, getWinningState, getFluxStateDefinition, getUserInfluence, getTotalStakedInCycle, getContractBalance.
 * 9. Admin/Configuration Functions:
 *    - setCollapseTriggerType, setCycleDuration, pauseContract, unpauseContract, emergencyWithdrawEth (for owner).
 * 10. Internal Helper Functions:
 *     - _calculateProbabilities, _selectWinningState (probabilistic logic), _distributeRewards, _updateInfluence (conceptual), _requireCycleActive, _requireCycleCollapsed.
 *
 * Function Summary (>= 20 functions):
 * 1.  constructor(): Initializes contract owner.
 * 2.  addFluxStateDefinition(string memory name, string memory description, uint256 rewardBasisPoints): Owner adds a blueprint for a potential state in cycles.
 * 3.  updateFluxStateDefinition(uint256 stateId, string memory name, string memory description, uint256 rewardBasisPoints): Owner updates an existing state blueprint.
 * 4.  removeFluxStateDefinition(uint256 stateId): Owner removes a state blueprint (fails if active in a cycle).
 * 5.  startNewFluxCycle(uint256[] memory stateDefinitionIds, uint256 durationInSeconds): Owner starts a new cycle with specified state definitions and duration.
 * 6.  contributeToFluxState(uint256 cycleId, uint256 stateId) payable: Users stake ETH into a specific state within an active cycle.
 * 7.  withdrawContribution(uint256 cycleId, uint256 stateId, uint256 amount): Users withdraw stake before the cycle collapses.
 * 8.  triggerCollapse(): Initiates the collapse sequence for the current cycle if conditions met. Determines the winning state probabilistically.
 * 9.  claimRewards(uint256 cycleId): Users claim rewards from a collapsed cycle if they contributed to the winning state.
 * 10. getCurrentCycleId(): Returns the ID of the current or last active cycle.
 * 11. getCycleDetails(uint256 cycleId): Returns details of a specific cycle.
 * 12. getContributionDetails(uint256 cycleId, address user): Returns user's total contribution mapping for a cycle.
 * 13. getWinningState(uint256 cycleId): Returns the ID of the winning state for a collapsed cycle.
 * 14. getFluxStateDefinition(uint256 stateId): Returns details of a specific state blueprint.
 * 15. getAllFluxStateDefinitions(): Returns IDs of all state blueprints.
 * 16. getUserInfluence(address user): Returns the conceptual influence score of a user.
 * 17. getTotalStakedInCycle(uint256 cycleId): Returns the total ETH staked in a specific cycle.
 * 18. getContractBalance(): Returns the current ETH balance of the contract.
 * 19. setCollapseTriggerType(uint8 triggerType): Owner sets the mechanism for cycle collapse (e.g., TIME, MANUAL_OWNER).
 * 20. setCycleDuration(uint256 duration): Owner sets the default duration for cycles (if time-based trigger).
 * 21. pauseContract(): Owner pauses the contract, preventing state changes.
 * 22. unpauseContract(): Owner unpauses the contract.
 * 23. emergencyWithdrawEth(uint256 amount): Owner can withdraw ETH in extreme emergencies (should be minimal or removed in prod).
 * 24. endCurrentCycleInternal(): Internal helper to clean up and potentially start a new cycle automatically. (Can be merged or kept separate depending on flow). Let's keep it internal.
 * 25. getActiveStateIdsInCycle(uint256 cycleId): Returns the list of state IDs active in a specific cycle.
 * 26. getCycleContributionByState(uint256 cycleId, uint256 stateId): Returns total staked amount for a specific state in a specific cycle.
 */

contract QuantumFlux {
    address private _owner;
    bool private _paused;

    uint256 private _nextStateId = 1;
    uint256 private _nextCycleId = 1;

    // --- Config ---
    enum CollapseTriggerType { NONE, TIME, MANUAL_OWNER, MANUAL_MIN_STAKE }
    CollapseTriggerType public collapseTriggerType = CollapseTriggerType.TIME;
    uint256 public defaultCycleDuration = 7 days; // Default duration if TIME trigger

    // --- Data Structures ---

    struct FluxStateDefinition {
        uint256 id;
        string name;
        string description;
        uint256 rewardBasisPoints; // Percentage of pool awarded (e.g., 10000 for 100%)
        bool isActive; // Can this definition be used in new cycles?
    }

    struct FluxCycle {
        uint256 id;
        uint256 startTime;
        uint256 endTime; // Relevant for TIME trigger
        uint256 totalPool; // Total ETH staked in this cycle
        uint256 winningStateId; // 0 if not collapsed yet
        bool isCollapsed;
        mapping(uint256 => uint256) stateTotalStakes; // Total stake for each state ID within THIS cycle
        mapping(address => mapping(uint256 => uint256)) userStateContributions; // User's stake per state ID in THIS cycle
        uint256[] activeStateIds; // IDs of states included in this cycle
    }

    // --- State Variables ---

    mapping(uint256 => FluxStateDefinition) public fluxStateDefinitions;
    uint256[] public allFluxStateDefinitionIds; // To iterate over definitions

    mapping(uint256 => FluxCycle) public fluxCycles;
    uint256 public currentCycleId; // Points to the currently active cycle, 0 if none

    mapping(address => uint256) public userInfluence; // Conceptual influence score

    // --- Events ---

    event StateDefinitionAdded(uint256 indexed stateId, string name);
    event StateDefinitionUpdated(uint256 indexed stateId, string name);
    event StateDefinitionRemoved(uint256 indexed stateId);
    event CycleStarted(uint256 indexed cycleId, uint256 startTime, uint256 endTime);
    event ContributionMade(uint256 indexed cycleId, address indexed user, uint256 indexed stateId, uint256 amount, uint256 newTotalForState);
    event ContributionWithdrawn(uint256 indexed cycleId, address indexed user, uint256 indexed stateId, uint256 amount, uint256 newTotalForState);
    event CycleCollapsed(uint256 indexed cycleId, uint256 indexed winningStateId, uint256 collapseTime);
    event RewardsClaimed(uint256 indexed cycleId, address indexed user, uint256 amount);
    event InfluenceUpdated(address indexed user, uint256 newInfluence);
    event Paused(address account);
    event Unpaused(address account);
    event CollapseTriggerTypeUpdated(uint8 indexed newType);
    event CycleDurationUpdated(uint256 newDuration);
    event EmergencyWithdrawal(address indexed recipient, uint256 amount);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Contract is not paused");
        _;
    }

    modifier onlyCycleActive(uint256 _cycleId) {
        require(_cycleId > 0 && _cycleId == currentCycleId && !fluxCycles[_cycleId].isCollapsed, "Cycle not active");
        _;
    }

     modifier onlyCycleCollapsed(uint256 _cycleId) {
        require(_cycleId > 0 && fluxCycles[_cycleId].isCollapsed, "Cycle not collapsed");
        _;
    }

    // --- Constructor ---

    constructor() {
        _owner = msg.sender;
        emit Paused(msg.sender); // Start paused by default
    }

    // --- Admin Functions ---

    /**
     * @notice Allows the owner to pause the contract.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Allows the owner to unpause the contract.
     */
    function unpauseContract() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @notice Allows the owner to add a new potential state definition.
     * @param name The name of the flux state.
     * @param description A description of the state.
     * @param rewardBasisPoints The basis points for calculating rewards if this state wins (e.g., 10000 = 100%).
     */
    function addFluxStateDefinition(string memory name, string memory description, uint256 rewardBasisPoints) external onlyOwner whenNotPaused {
        uint256 stateId = _nextStateId++;
        fluxStateDefinitions[stateId] = FluxStateDefinition(stateId, name, description, rewardBasisPoints, true);
        allFluxStateDefinitionIds.push(stateId);
        emit StateDefinitionAdded(stateId, name);
    }

    /**
     * @notice Allows the owner to update an existing state definition.
     * @param stateId The ID of the state definition to update.
     * @param name The new name.
     * @param description The new description.
     * @param rewardBasisPoints The new reward basis points.
     */
    function updateFluxStateDefinition(uint256 stateId, string memory name, string memory description, uint256 rewardBasisPoints) external onlyOwner whenNotPaused {
        require(fluxStateDefinitions[stateId].id != 0, "State definition not found");
        // Optional: Prevent update if definition is currently active in the *current* cycle
        // (Would require iterating through currentCycle.activeStateIds, skipping for simplicity here)
        fluxStateDefinitions[stateId].name = name;
        fluxStateDefinitions[stateId].description = description;
        fluxStateDefinitions[stateId].rewardBasisPoints = rewardBasisPoints;
        emit StateDefinitionUpdated(stateId, name);
    }

    /**
     * @notice Allows the owner to remove a state definition.
     * @param stateId The ID of the state definition to remove.
     * @dev Does not remove from `allFluxStateDefinitionIds` array for gas efficiency; iteration must check `isActive`.
     */
    function removeFluxStateDefinition(uint256 stateId) external onlyOwner whenNotPaused {
        require(fluxStateDefinitions[stateId].id != 0, "State definition not found");
        // Prevent removal if it's active in the current cycle
        if (currentCycleId != 0 && !fluxCycles[currentCycleId].isCollapsed) {
             for(uint256 i = 0; i < fluxCycles[currentCycleId].activeStateIds.length; i++) {
                 if (fluxCycles[currentCycleId].activeStateIds[i] == stateId) {
                     revert("Cannot remove active state definition");
                 }
             }
        }
        fluxStateDefinitions[stateId].isActive = false; // Mark as inactive instead of deleting
        // delete fluxStateDefinitions[stateId]; // Safer to just mark inactive
        emit StateDefinitionRemoved(stateId);
    }

     /**
     * @notice Allows the owner to set the mechanism for cycle collapse.
     * @param triggerType The type of trigger (0=NONE, 1=TIME, 2=MANUAL_OWNER, 3=MANUAL_MIN_STAKE).
     */
    function setCollapseTriggerType(uint8 triggerType) external onlyOwner whenNotPaused {
        require(triggerType <= uint8(CollapseTriggerType.MANUAL_MIN_STAKE), "Invalid trigger type");
        collapseTriggerType = CollapseTriggerType(triggerType);
        emit CollapseTriggerTypeUpdated(triggerType);
    }

    /**
     * @notice Allows the owner to set the default duration for time-triggered cycles.
     * @param duration Duration in seconds.
     */
    function setCycleDuration(uint256 duration) external onlyOwner whenNotPaused {
        require(duration > 0, "Duration must be greater than 0");
        defaultCycleDuration = duration;
        emit CycleDurationUpdated(duration);
    }

     /**
      * @notice Allows the owner to withdraw ETH from the contract in emergency.
      * @dev Use with extreme caution. Should have strong governance or be removed in production.
      * @param amount The amount of ETH to withdraw.
      */
     function emergencyWithdrawEth(uint256 amount) external onlyOwner {
         require(amount > 0, "Amount must be > 0");
         require(amount <= address(this).balance, "Insufficient contract balance");
         payable(msg.sender).transfer(amount);
         emit EmergencyWithdrawal(msg.sender, amount);
     }


    // --- Cycle Management ---

    /**
     * @notice Starts a new flux cycle with specified state definitions.
     * Can only be called if no cycle is currently active and not collapsed.
     * @param stateDefinitionIds The IDs of the state definitions to include in this cycle.
     * @param durationInSeconds Optional duration override for this specific cycle (if time-triggered).
     */
    function startNewFluxCycle(uint256[] memory stateDefinitionIds, uint256 durationInSeconds) external onlyOwner whenNotPaused {
        require(currentCycleId == 0 || fluxCycles[currentCycleId].isCollapsed, "Previous cycle is still active");
        require(stateDefinitionIds.length > 0, "Must include at least one state definition");

        uint256 cycleId = _nextCycleId++;
        uint256 startTime = block.timestamp;
        uint256 endTime = (collapseTriggerType == CollapseTriggerType.TIME) ? startTime + (durationInSeconds > 0 ? durationInSeconds : defaultCycleDuration) : 0;

        FluxCycle storage newCycle = fluxCycles[cycleId];
        newCycle.id = cycleId;
        newCycle.startTime = startTime;
        newCycle.endTime = endTime;
        newCycle.isCollapsed = false;
        newCycle.totalPool = 0;
        newCycle.winningStateId = 0; // Not set yet

        // Add active states for this cycle
        newCycle.activeStateIds = new uint256[](stateDefinitionIds.length);
        for (uint256 i = 0; i < stateDefinitionIds.length; i++) {
            uint256 stateDefId = stateDefinitionIds[i];
            require(fluxStateDefinitions[stateDefId].isActive, "State definition is not active");
            newCycle.activeStateIds[i] = stateDefId;
            // Initialize stateTotalStakes entry
            newCycle.stateTotalStakes[stateDefId] = 0;
        }

        currentCycleId = cycleId;

        emit CycleStarted(cycleId, startTime, endTime);
    }

    /**
     * @notice Triggers the collapse of the current cycle if conditions are met.
     * This function is responsible for selecting the winning state and marking the cycle as collapsed.
     * The randomness/probabilistic outcome is simulated based on weighted contributions.
     * NOTE: On-chain randomness is challenging and this implementation uses a simplified,
     * potentially manipulable method based on block hash. NOT SUITABLE FOR PRODUCTION.
     */
    function triggerCollapse() external whenNotPaused {
        uint256 cycleId = currentCycleId;
        FluxCycle storage cycle = fluxCycles[cycleId];
        _requireCycleActive(cycleId);

        bool canCollapse = false;
        if (collapseTriggerType == CollapseTriggerType.TIME) {
            canCollapse = block.timestamp >= cycle.endTime;
        } else if (collapseTriggerType == CollapseTriggerType.MANUAL_OWNER) {
            canCollapse = msg.sender == _owner;
        } else if (collapseTriggerType == CollapseTriggerType.MANUAL_MIN_STAKE) {
             // Example: Check if total stake exceeds a threshold (threshold not implemented for simplicity)
             // canCollapse = cycle.totalPool >= minimumCollapseStake;
             revert("Manual_Min_Stake trigger type not fully implemented"); // Placeholder
        } else if (collapseTriggerType == CollapseTriggerType.NONE) {
             // Can only be triggered manually by owner? Or maybe no collapse?
             // Let's assume MANUAL_OWNER behavior if NONE.
             canCollapse = msg.sender == _owner;
        }


        require(canCollapse, "Collapse conditions not met");
        require(cycle.totalPool > 0, "Cannot collapse cycle with no contributions");

        // --- Probabilistic Selection Logic (Conceptual & Simplified!) ---
        // This part is highly experimental and NOT secure for production.
        // It's meant to demonstrate the idea of stake influencing outcome probability.

        uint256 totalWeight = 0;
        uint256[] memory stateIds = cycle.activeStateIds;
        uint256[] memory weights = new uint256[](stateIds.length);

        for (uint256 i = 0; i < stateIds.length; i++) {
            uint256 stateId = stateIds[i];
            uint256 stateStake = cycle.stateTotalStakes[stateId];
            // Weight = Stake (simple weighting)
            weights[i] = stateStake;
            totalWeight += stateStake;
        }

        require(totalWeight > 0, "Total weight must be greater than 0"); // Should be covered by totalPool > 0

        // Pseudo-random number generation using block data (PREDICTABLE! NOT SECURE!)
        // A real implementation would use Chainlink VRF or similar.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, totalWeight)));
        uint256 randomValue = randomNumber % totalWeight;

        uint256 winningStateId = 0;
        uint256 cumulativeWeight = 0;

        for (uint256 i = 0; i < stateIds.length; i++) {
            cumulativeWeight += weights[i];
            if (randomValue < cumulativeWeight) {
                winningStateId = stateIds[i];
                break;
            }
        }

        // Fallback in case loop doesn't select (shouldn't happen with totalWeight > 0)
        if (winningStateId == 0) {
             // This indicates an error in the selection logic or totalWeight calculation
             // As a fallback, pick the state with highest stake or first state
             uint256 maxStake = 0;
             for (uint256 i = 0; i < stateIds.length; i++) {
                 if (cycle.stateTotalStakes[stateIds[i]] > maxStake) {
                     maxStake = cycle.stateTotalStakes[stateIds[i]];
                     winningStateId = stateIds[i];
                 }
             }
             if (winningStateId == 0 && stateIds.length > 0) winningStateId = stateIds[0]; // Final fallback
             require(winningStateId != 0, "Failed to select winning state"); // Should not happen if totalPool > 0
        }


        // --- End Probabilistic Selection ---

        cycle.isCollapsed = true;
        cycle.winningStateId = winningStateId;

        emit CycleCollapsed(cycleId, winningStateId, block.timestamp);

        // Optionally, immediately start a new cycle or require owner action
        // For this example, we leave it collapsed until owner starts a new one.
        // To automate, could call _startNewCycleInternal(next states) here.
    }

    // --- User Interaction ---

    /**
     * @notice Allows a user to contribute ETH to a specific state within the current active cycle.
     * Their contribution influences the probability of that state winning.
     * @param cycleId The ID of the cycle to contribute to. Must be the current active cycle.
     * @param stateId The ID of the state within the cycle to contribute to.
     */
    function contributeToFluxState(uint256 cycleId, uint256 stateId) external payable whenNotPaused onlyCycleActive(cycleId) {
        require(msg.value > 0, "Contribution must be > 0 ETH");

        FluxCycle storage cycle = fluxCycles[cycleId];

        // Check if the stateId is active in this cycle
        bool stateActiveInCycle = false;
        for(uint256 i = 0; i < cycle.activeStateIds.length; i++) {
            if (cycle.activeStateIds[i] == stateId) {
                stateActiveInCycle = true;
                break;
            }
        }
        require(stateActiveInCycle, "State ID is not active in this cycle");

        cycle.userStateContributions[msg.sender][stateId] += msg.value;
        cycle.stateTotalStakes[stateId] += msg.value;
        cycle.totalPool += msg.value;

        // Update user influence (simplified: more contribution -> more potential influence)
        _updateInfluence(msg.sender, msg.value); // Example: Influence = total ETH ever contributed

        emit ContributionMade(cycleId, msg.sender, stateId, msg.value, cycle.stateTotalStakes[stateId]);
    }

    /**
     * @notice Allows a user to withdraw their contribution before the cycle collapses.
     * Partial withdrawals are allowed.
     * @param cycleId The ID of the cycle. Must be the current active cycle.
     * @param stateId The ID of the state the contribution was made to.
     * @param amount The amount to withdraw.
     */
    function withdrawContribution(uint256 cycleId, uint256 stateId, uint256 amount) external whenNotPaused onlyCycleActive(cycleId) {
         FluxCycle storage cycle = fluxCycles[cycleId];

         require(amount > 0, "Amount must be > 0");
         require(cycle.userStateContributions[msg.sender][stateId] >= amount, "Insufficient contribution amount");

         cycle.userStateContributions[msg.sender][stateId] -= amount;
         cycle.stateTotalStakes[stateId] -= amount;
         cycle.totalPool -= amount;

         // Note: Influence is not reduced on withdrawal in this simple model.
         // A more complex model might adjust influence.

         payable(msg.sender).transfer(amount);

         emit ContributionWithdrawn(cycleId, msg.sender, stateId, amount, cycle.stateTotalStakes[stateId]);
    }

    /**
     * @notice Allows a user to claim rewards from a collapsed cycle if they contributed
     * to the winning state. Can only be called once per user per cycle.
     * Rewards are calculated based on the user's contribution percentage to the winning state's pool
     * and the winning state's defined reward basis points from the *total* cycle pool.
     * @param cycleId The ID of the collapsed cycle.
     */
    function claimRewards(uint256 cycleId) external whenNotPaused onlyCycleCollapsed(cycleId) {
        FluxCycle storage cycle = fluxCycles[cycleId];
        require(cycle.winningStateId != 0, "Winning state not determined for this cycle");
        require(cycle.userStateContributions[msg.sender][cycle.winningStateId] > 0, "User did not contribute to the winning state");

        // Prevent claiming twice for the same cycle/user
        // A simple way is to zero out their contribution after claiming
        uint256 userWinningContribution = cycle.userStateContributions[msg.sender][cycle.winningStateId];
        require(userWinningContribution > 0, "Rewards already claimed or no contribution");

        uint256 winningStateId = cycle.winningStateId;
        uint256 totalWinningStateStake = cycle.stateTotalStakes[winningStateId]; // Total stake in winning state
        uint256 totalCyclePool = cycle.totalPool; // Total stake in the entire cycle

        // Calculate the user's share of the winning state's pool
        // User share % = userWinningContribution / totalWinningStateStake
        uint256 userShareBps = (userWinningContribution * 10000) / totalWinningStateStake;

        // Get the reward basis points for the winning state definition
        uint256 winningStateRewardBps = fluxStateDefinitions[winningStateId].rewardBasisPoints;

        // Calculate total rewards allocated to the winning state
        // Total winning state reward = totalCyclePool * (winningStateRewardBps / 10000)
        // Use multiplication before division to maintain precision
        uint256 totalWinningStateReward = (totalCyclePool * winningStateRewardBps) / 10000;

        // Calculate the user's final reward amount
        // User Reward = totalWinningStateReward * (userShareBps / 10000)
        uint256 userRewardAmount = (totalWinningStateReward * userShareBps) / 10000;

        // Mark contribution as claimed by zeroing it out
        cycle.userStateContributions[msg.sender][winningStateId] = 0;

        // Update user influence (simplified: winning rewards increases influence)
        _updateInfluence(msg.sender, userRewardAmount); // Example: Influence += rewards claimed

        payable(msg.sender).transfer(userRewardAmount);

        emit RewardsClaimed(cycleId, msg.sender, userRewardAmount);
    }


    // --- Query Functions ---

    /**
     * @notice Returns the ID of the current or last active cycle.
     */
    function getCurrentCycleId() external view returns (uint256) {
        return currentCycleId;
    }

    /**
     * @notice Returns details about a specific flux cycle.
     * @param cycleId The ID of the cycle.
     */
    function getCycleDetails(uint256 cycleId) external view returns (
        uint256 id,
        uint256 startTime,
        uint256 endTime,
        uint256 totalPool,
        uint256 winningStateId,
        bool isCollapsed,
        uint256[] memory activeStateIds
    ) {
        require(fluxCycles[cycleId].id != 0, "Cycle not found");
        FluxCycle storage cycle = fluxCycles[cycleId];
        return (
            cycle.id,
            cycle.startTime,
            cycle.endTime,
            cycle.totalPool,
            cycle.winningStateId,
            cycle.isCollapsed,
            cycle.activeStateIds
        );
    }

    /**
     * @notice Returns a user's total contributions to each state within a specific cycle.
     * @param cycleId The ID of the cycle.
     * @param user The address of the user.
     * @return A mapping from state ID to the user's contributed amount for that state in the given cycle.
     * @dev Note: Solidity cannot return a `mapping` directly. This function would typically
     * be replaced in a frontend/backend with individual queries like `getUserContributionByState(cycleId, user, stateId)`
     * or requires returning state IDs the user contributed to and querying each.
     * For conceptual completeness, we show the structure but note the limitation.
     * A practical implementation would likely return `uint256[] memory stateIds, uint256[] memory amounts`.
     * Let's implement a helper for individual state query.
     */
    // function getContributionDetails(uint256 cycleId, address user) external view returns (mapping(uint256 => uint256)) {
    //     // Return mapping not supported
    //     return fluxCycles[cycleId].userStateContributions[user];
    // }
     /**
     * @notice Returns a user's contribution to a specific state within a specific cycle.
     * @param cycleId The ID of the cycle.
     * @param user The address of the user.
     * @param stateId The ID of the state.
     */
    function getUserContributionByState(uint255 cycleId, address user, uint256 stateId) external view returns (uint256) {
         require(fluxCycles[cycleId].id != 0, "Cycle not found");
         // No need to check if state is active in cycle here, just return the value
         return fluxCycles[cycleId].userStateContributions[user][stateId];
    }


    /**
     * @notice Returns the ID of the winning state for a collapsed cycle.
     * Returns 0 if the cycle is not yet collapsed or no winning state was determined.
     * @param cycleId The ID of the cycle.
     */
    function getWinningState(uint256 cycleId) external view returns (uint256) {
        require(fluxCycles[cycleId].id != 0, "Cycle not found");
        return fluxCycles[cycleId].winningStateId;
    }

    /**
     * @notice Returns details about a specific flux state definition blueprint.
     * @param stateId The ID of the state definition.
     */
    function getFluxStateDefinition(uint256 stateId) external view returns (
        uint256 id,
        string memory name,
        string memory description,
        uint256 rewardBasisPoints,
        bool isActive
    ) {
        require(fluxStateDefinitions[stateId].id != 0, "State definition not found");
        FluxStateDefinition storage definition = fluxStateDefinitions[stateId];
        return (
            definition.id,
            definition.name,
            definition.description,
            definition.rewardBasisPoints,
            definition.isActive
        );
    }

    /**
     * @notice Returns the IDs of all registered flux state definition blueprints.
     * Iteration over these IDs is required to get full details or filter by `isActive`.
     */
    function getAllFluxStateDefinitionIds() external view returns (uint256[] memory) {
        return allFluxStateDefinitionIds;
    }

    /**
     * @notice Returns the conceptual influence score of a user.
     * @param user The address of the user.
     */
    function getUserInfluence(address user) external view returns (uint256) {
        return userInfluence[user];
    }

     /**
      * @notice Returns the total ETH staked in a specific cycle.
      * @param cycleId The ID of the cycle.
      */
    function getTotalStakedInCycle(uint256 cycleId) external view returns (uint256) {
         require(fluxCycles[cycleId].id != 0, "Cycle not found");
         return fluxCycles[cycleId].totalPool;
    }

    /**
     * @notice Returns the current ETH balance of the contract.
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

     /**
     * @notice Returns the IDs of states active in a specific cycle.
     * @param cycleId The ID of the cycle.
     */
     function getActiveStateIdsInCycle(uint256 cycleId) external view returns (uint256[] memory) {
         require(fluxCycles[cycleId].id != 0, "Cycle not found");
         return fluxCycles[cycleId].activeStateIds;
     }

     /**
      * @notice Returns the total staked amount for a specific state within a specific cycle.
      * @param cycleId The ID of the cycle.
      * @param stateId The ID of the state.
      */
     function getCycleContributionByState(uint256 cycleId, uint256 stateId) external view returns (uint256) {
          require(fluxCycles[cycleId].id != 0, "Cycle not found");
          // No need to check if state is active in cycle here, just return the value
          return fluxCycles[cycleId].stateTotalStakes[stateId];
     }


    // --- Internal Helpers ---

    /**
     * @dev Internal function to update user influence. Simplified implementation.
     * @param user The address of the user.
     * @param amount The amount impacting influence (e.g., contribution amount, reward amount).
     */
    function _updateInfluence(address user, uint256 amount) internal {
        // Simple addition as an example. Could be more complex (logarithmic, decay, etc.)
        userInfluence[user] += amount;
        emit InfluenceUpdated(user, userInfluence[user]);
    }

     /**
     * @dev Internal helper to check if a cycle is currently active and not collapsed.
     * @param cycleId The ID of the cycle.
     */
    function _requireCycleActive(uint256 cycleId) internal view {
        require(cycleId > 0 && cycleId == currentCycleId && !fluxCycles[cycleId].isCollapsed, "Cycle not active");
    }

    /**
     * @dev Internal helper to check if a cycle is collapsed.
     * @param cycleId The ID of the cycle.
     */
    function _requireCycleCollapsed(uint256 cycleId) internal view {
        require(cycleId > 0 && fluxCycles[cycleId].isCollapsed, "Cycle not collapsed");
    }


    // --- Receive/Fallback ---
    receive() external payable {
        // Optionally handle direct ETH transfers, e.g., add to current cycle pool or reject.
        // For this example, we'll just let it increase the contract balance.
        // In a real dapp, direct sends might be disallowed or have a specific purpose.
    }

    fallback() external payable {
        // Handle calls to non-existent functions
        revert("Invalid function call");
    }
}
```