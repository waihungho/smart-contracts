Okay, let's design a smart contract that manages a dynamic "Kinetic Potential" resource within a network of participants. This potential decays over time but can be regenerated through actions or passive processes, and can be used to perform high-impact operations. It includes delegation features and dynamic parameters.

This contract is designed to be a core component for systems involving resource management, gamification, influence mechanics, or time-locked actions. It avoids standard ERC token patterns directly, focusing purely on the resource state and its dynamics.

---

## Smart Contract: KineticPotentialManager

**Concept:**
This contract manages a unique, time-sensitive resource called "Kinetic Potential" for registered participants. Potential decays gradually over time if unused but can be increased through specific on-chain actions. Participants can use potential to perform various impact levels of actions. A delegation mechanism allows participants to empower others, potentially influencing resource flow or action effectiveness.

**Key Features:**
*   **Dynamic Potential:** Potential values for each participant change over time based on defined decay and generation rates.
*   **Time-Based Mechanics:** Potential updates are calculated based on elapsed time since the last interaction, using `block.timestamp`.
*   **Action Costs & Rewards:** Different actions consume varying amounts of potential, while specific efforts can generate potential.
*   **Delegation:** Participants can delegate their "potential influence" to another address, impacting potential generation mechanics for both parties.
*   **Configurable Parameters:** Admin can adjust decay rates, generation rates, action costs, and rewards.
*   **Access Control:** Basic ownership and pausing mechanisms.

---

## Outline and Function Summary:

1.  **State Variables:** Stores global parameters, participant data, owner, and pause status.
2.  **Events:** Notifies external listeners of significant actions (potential changes, registration, delegation, parameter updates, etc.).
3.  **Errors:** Custom errors for specific failure conditions.
4.  **Modifiers:** Reusable checks for access control, contract state, participant status, and potential balance.
5.  **Structs:** (Not strictly needed for this simple participant state, using mappings instead for efficiency).
6.  **Internal Helper Functions:** Core logic for calculating and updating participant potential based on time.
7.  **Constructor:** Initializes the contract with an owner and initial parameters.
8.  **Participant Management Functions:** Registering, checking status, deactivating.
9.  **Potential Management Functions (Internal/View):** Calculating current potential, updating state.
10. **Action Functions:** Functions participants call that consume or generate potential.
11. **Delegation Functions:** Managing delegation relationships.
12. **Parameter Management Functions (Admin):** Modifying contract parameters.
13. **Contract State Management Functions (Admin/View):** Pausing, checking state, withdrawing funds.
14. **View Functions:** Reading contract state and participant data.

---

## Function Summary:

*   `constructor(uint256 initialDecayRate, uint256 initialGenerationRate, uint256 initialPotentialInterval, uint256 initialMinorCost, uint256 initialMediumCost, uint256 initialMajorCost, uint256 initialEffortReward)`: Deploys the contract, sets owner and initial parameters.
*   `registerParticipant()`: Allows any address to register as a participant.
*   `isActiveParticipant(address participant)`: Checks if an address is a registered participant.
*   `_calculateCurrentPotential(address participant)`: *Internal* helper to calculate the participant's potential considering decay/generation since last update. Returns the calculated potential and the new last update time.
*   `_updatePotential(address participant, uint256 newPotential, uint256 newLastUpdateTime)`: *Internal* helper to update a participant's potential state variables.
*   `_spendPotential(address participant, uint256 amount)`: *Internal* helper to calculate current potential, check balance, and reduce potential after an action.
*   `_addPotential(address participant, uint256 amount)`: *Internal* helper to calculate current potential and add potential (used by generation actions or admin).
*   `getParticipantPotential(address participant)`: *View* function to get the *current* calculated potential of a participant.
*   `getParticipantLastUpdateTime(address participant)`: *View* function to get the timestamp of the participant's last potential update.
*   `performMinorAction()`: Participant action consuming minor potential.
*   `performMediumAction()`: Participant action consuming medium potential.
*   `performMajorAction()`: Participant action consuming major potential.
*   `contributeEffort()`: Participant action generating potential (with delegation bonus).
*   `boostInfluence(uint256 baseCost)`: Participant action consuming a variable base amount of potential, potentially with external effects (not implemented here, but structure provided).
*   `delegatePotential(address delegatee)`: Allows a participant to delegate their "influence" to another participant.
*   `undelegatePotential()`: Allows a participant to remove their delegation.
*   `getDelegatee(address delegator)`: *View* function to see who a participant has delegated to.
*   `getDelegator(address delegatee)`: *View* function to see who has delegated to this participant (returns the *last* delegator if multiple, simplified).
*   `setDecayRate(uint256 rate)`: Admin sets the rate at which potential decays per interval.
*   `setGenerationRate(uint256 rate)`: Admin sets the rate at which potential generates per interval (passive).
*   `setPotentialInterval(uint256 interval)`: Admin sets the time interval for decay/generation calculation.
*   `setActionCosts(uint256 minorCost, uint256 mediumCost, uint256 majorCost)`: Admin sets potential costs for actions.
*   `setEffortReward(uint256 reward)`: Admin sets potential reward for contributing effort.
*   `setDelegationBonusRate(uint256 bonusRate)`: Admin sets the percentage bonus potential the delegatee receives when delegator contributes effort.
*   `deactivateParticipant(address participant)`: Admin can deactivate a participant (e.g., faster decay).
*   `activateParticipant(address participant)`: Admin can reactivate a participant.
*   `pauseContract()`: Owner pauses core actions.
*   `unpauseContract()`: Owner unpauses core actions.
*   `isPaused()`: *View* checks if contract is paused.
*   `withdrawEther(uint256 amount)`: Owner withdraws Ether from the contract (if any accrues, e.g., from fees - not implemented here, but good utility).
*   `getContractParameters()`: *View* returns all major contract parameters.
*   `getParticipantState(address participant)`: *View* returns multiple state variables for a participant.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title KineticPotentialManager
 * @notice Manages a dynamic 'Kinetic Potential' resource for participants,
 * where potential decays over time but can be generated or spent on actions.
 * Includes delegation and configurable parameters.
 */
contract KineticPotentialManager {

    // --- State Variables ---

    address public owner;

    // Mapping: participant address => is registered and active
    mapping(address => bool) public participants;
    // Mapping: participant address => current raw potential value
    mapping(address => uint256) private _potential;
    // Mapping: participant address => timestamp of the last potential state update
    mapping(address => uint256) private _lastPotentialUpdateTime;

    // Mapping: delegator address => delegatee address
    mapping(address => address) public delegatee;
    // Mapping: delegatee address => delegator address (simplified: stores the last delegator)
    mapping(address => address) public delegator;

    // Parameters controlling potential dynamics
    uint256 public decayRatePerInterval; // Amount of potential decayed per interval (scaled)
    uint256 public generationRatePerInterval; // Amount of potential generated per interval (scaled)
    uint256 public potentialInterval; // Time in seconds for one potential calculation interval
    uint256 public delegationBonusRate; // Percentage of effort reward delegatee gets (e.g., 10 for 10%)

    // Parameters controlling action costs and rewards
    uint256 public minorActionCost;
    uint256 public mediumActionCost;
    uint256 public majorActionCost;
    uint256 public effortReward;

    // Contract state
    bool public paused;

    // --- Events ---

    event ParticipantRegistered(address indexed participant);
    event ParticipantDeactivated(address indexed participant);
    event ParticipantActivated(address indexed participant);
    event PotentialUpdated(address indexed participant, uint256 oldPotential, uint256 newPotential, uint256 timestamp);
    event PotentialSpent(address indexed participant, uint256 amount, string action);
    event PotentialGenerated(address indexed participant, uint256 amount, string action);
    event DelegationUpdated(address indexed delegator, address indexed oldDelegatee, address indexed newDelegatee);
    event ParametersUpdated(string paramName, uint256 oldValue, uint256 newValue);
    event ActionPerformed(address indexed participant, string actionType, uint256 potentialCost, uint256 potentialGenerated);
    event ContractPaused(address indexed account);
    event ContractUnpaused(address indexed account);
    event EtherWithdrawn(address indexed to, uint256 amount);

    // --- Errors ---

    error NotOwner();
    error WhenPaused();
    error WhenNotPaused();
    error AlreadyRegistered();
    error NotRegistered();
    error InsufficientPotential(uint256 required, uint256 available);
    error SelfDelegationNotAllowed();
    error AlreadyDelegatingTo(address delegatee);
    error NotDelegating();
    error InvalidAmount();
    error ParticipantNotActive();

    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert WhenPaused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert WhenNotPaused();
        _;
    }

    modifier isActiveParticipantModifier(address participant) {
        if (!participants[participant]) revert NotRegistered();
        // Add check for active status if needed, but `participants` mapping already serves this
        _;
    }

    modifier hasEnoughPotential(address participant, uint256 requiredAmount) {
        uint256 currentPotential = getParticipantPotential(participant); // Get up-to-date potential
        if (currentPotential < requiredAmount) revert InsufficientPotential(requiredAmount, currentPotential);
        _;
    }

    // --- Constructor ---

    constructor(
        uint256 initialDecayRate,
        uint256 initialGenerationRate,
        uint256 initialPotentialInterval,
        uint256 initialMinorCost,
        uint256 initialMediumCost,
        uint256 initialMajorCost,
        uint256 initialEffortReward,
        uint256 initialDelegationBonusRate // Added bonus rate param
    ) {
        owner = msg.sender;
        decayRatePerInterval = initialDecayRate;
        generationRatePerInterval = initialGenerationRate;
        potentialInterval = initialPotentialInterval;
        minorActionCost = initialMinorCost;
        mediumActionCost = initialMediumCost;
        majorActionCost = initialMajorCost;
        effortReward = initialEffortReward;
        delegationBonusRate = initialDelegationBonusRate;
        paused = false;
    }

    // --- Internal Helper Functions ---

    /**
     * @notice Calculates the participant's current potential based on time elapsed
     * since the last update and current rates. Applies decay/generation.
     * IMPORTANT: This function ONLY calculates the theoretical potential.
     * State update (`_updatePotential`) must be called separately if state needs to change.
     * It also updates the state variables *during* calculation to avoid needing `_updatePotential` call immediately after,
     * making it atomic for reads and priming for writes.
     * @param participant The address of the participant.
     * @return currentCalculatedPotential The potential value after applying time-based changes.
     */
    function _calculateAndApplyPotentialChange(address participant) internal returns (uint256 currentCalculatedPotential) {
        uint256 currentRawPotential = _potential[participant];
        uint256 lastUpdate = _lastPotentialUpdateTime[participant];
        uint256 currentTime = block.timestamp;

        // If never updated or no time passed, return current raw potential
        if (lastUpdate == 0 || currentTime <= lastUpdate) {
             // Initialize if first time calculation
            if (lastUpdate == 0) {
                 _lastPotentialUpdateTime[participant] = currentTime;
            }
            return currentRawPotential;
        }

        uint256 timeElapsed = currentTime - lastUpdate;
        uint256 numIntervals = timeElapsed / potentialInterval;

        if (numIntervals > 0) {
            uint256 totalDecay = numIntervals * decayRatePerInterval;
            uint256 totalGeneration = numIntervals * generationRatePerInterval;

            // Apply decay, ensure potential doesn't go below 0
            if (currentRawPotential >= totalDecay) {
                currentCalculatedPotential = currentRawPotential - totalDecay;
            } else {
                currentCalculatedPotential = 0;
            }

            // Apply generation
            currentCalculatedPotential += totalGeneration; // Handle potential overflow if needed, though unlikely with uint256

            // Update state only if changes were applied
             emit PotentialUpdated(participant, currentRawPotential, currentCalculatedPotential, currentTime);
            _potential[participant] = currentCalculatedPotential;
            _lastPotentialUpdateTime[participant] = currentTime;

        } else {
             // No full interval passed, potential remains the same for now, update timestamp
             _lastPotentialUpdateTime[participant] = currentTime;
             currentCalculatedPotential = currentRawPotential;
        }
    }


    /**
     * @notice Spends a calculated amount of potential for a participant.
     * Assumes _calculateAndApplyPotentialChange has been called recently or will be called.
     * Does NOT check balance here; balance check should happen *before* calling this, typically
     * by getting the value from `_calculateAndApplyPotentialChange` or using the `hasEnoughPotential` modifier.
     * @param participant The address of the participant.
     * @param amount The amount of potential to spend.
     */
    function _spendPotential(address participant, uint256 amount) internal {
         // Calculate potential decay/generation first
        uint256 currentCalculatedPotential = _calculateAndApplyPotentialChange(participant);

        // Now, spend from the current calculated potential
        if (currentCalculatedPotential < amount) {
             // This should ideally not happen if hasEnoughPotential modifier is used,
             // but included as a safeguard.
             revert InsufficientPotential(amount, currentCalculatedPotential);
        }

        uint256 newPotential = currentCalculatedPotential - amount;
        _potential[participant] = newPotential; // State update was already done in _calculateAndApplyPotentialChange
                                                // The update here is just setting the final value after spend.
        emit PotentialSpent(participant, amount, "Internal Spend");
    }

     /**
     * @notice Adds a calculated amount of potential for a participant.
     * Assumes _calculateAndApplyPotentialChange has been called recently or will be called.
     * @param participant The address of the participant.
     * @param amount The amount of potential to add.
     */
    function _addPotential(address participant, uint256 amount) internal {
        // Calculate potential decay/generation first
        uint256 currentCalculatedPotential = _calculateAndApplyPotentialChange(participant);

        // Now, add to the current calculated potential
        uint256 newPotential = currentCalculatedPotential + amount; // Handles overflow implicitly by wrapping around uint256 max
        _potential[participant] = newPotential; // State update was already done in _calculateAndApplyPotentialChange
                                                // The update here is just setting the final value after add.
        emit PotentialGenerated(participant, amount, "Internal Add");
    }


    // --- Participant Management Functions ---

    /**
     * @notice Registers the caller as a participant.
     */
    function registerParticipant() external whenNotPaused {
        if (participants[msg.sender]) revert AlreadyRegistered();
        participants[msg.sender] = true;
        _lastPotentialUpdateTime[msg.sender] = block.timestamp; // Initialize timestamp
        // Initial potential is 0 unless set otherwise by admin/constructor
        emit ParticipantRegistered(msg.sender);
    }

    /**
     * @notice Deactivates a participant. Admin only.
     * @param participant The address to deactivate.
     */
    function deactivateParticipant(address participant) external onlyOwner isActiveParticipantModifier(participant) {
        // Note: This doesn't remove participant data, just marks them inactive.
        // The potential dynamics might need to be adjusted here if deactivated state
        // means different decay/generation. For now, just a status flag.
        participants[participant] = false;
        emit ParticipantDeactivated(participant);
    }

    /**
     * @notice Activates a participant. Admin only.
     * @param participant The address to activate.
     */
    function activateParticipant(address participant) external onlyOwner {
        if (participants[participant]) revert AlreadyRegistered(); // Or maybe add a state flag?
        participants[participant] = true;
         // Ensure timestamp is set if reactivating a non-registered address (edge case)
        if (_lastPotentialUpdateTime[participant] == 0) {
            _lastPotentialUpdateTime[participant] = block.timestamp;
        }
        emit ParticipantActivated(participant);
    }


    // --- Potential Management Functions (View) ---

     /**
     * @notice Gets the current, calculated potential of a participant.
     * This function triggers the time-based potential update implicitly.
     * @param participant The address of the participant.
     * @return The participant's current potential.
     */
    function getParticipantPotential(address participant) public view isActiveParticipantModifier(participant) returns (uint256) {
        // This view function *should* ideally calculate the potential based on time without
        // changing state. However, Solidity view functions cannot change state.
        // The common pattern is to expose the raw state (`_potential`) and let off-chain
        // or other contracts handle the calculation, OR to make functions that *modify*
        // state calculate it first.
        // Let's stick to the common pattern: _calculateAndApplyPotentialChange is INTERNAL
        // and called by modifying functions. This VIEW function returns the *last saved*
        // potential. Users/other contracts should call a modifying function (even a simple
        // "ping" function) to update the state before reading if high accuracy is needed,
        // or perform the calculation off-chain using the view data.
        // To make it "seem" dynamic for the view, we can return the result of the calculation
        // *without* writing to state. This means duplicating calculation logic or careful structure.
        // Option 1 (Simpler but less dynamic view): Return _potential[participant]
        // Option 2 (More Dynamic View): Re-implement calculation logic without state write
        // Let's go with Option 2 for a more "dynamic" feel in the view function,
        // but emphasize that on-chain state updates happen via modifying functions.

        uint256 currentRawPotential = _potential[participant];
        uint256 lastUpdate = _lastPotentialUpdateTime[participant];
        uint256 currentTime = block.timestamp;

        if (lastUpdate == 0 || currentTime <= lastUpdate) {
            return currentRawPotential;
        }

        uint256 timeElapsed = currentTime - lastUpdate;
        uint256 numIntervals = timeElapsed / potentialInterval;

        if (numIntervals > 0) {
            uint256 totalDecay = numIntervals * decayRatePerInterval;
            uint256 totalGeneration = numIntervals * generationRatePerInterval;

            uint256 calculatedPotential;
             if (currentRawPotential >= totalDecay) {
                calculatedPotential = currentRawPotential - totalDecay;
            } else {
                calculatedPotential = 0;
            }
            calculatedPotential += totalGeneration;
            return calculatedPotential;

        } else {
            return currentRawPotential;
        }
    }

    /**
     * @notice Gets the timestamp of the last potential state update for a participant.
     * @param participant The address of the participant.
     * @return The timestamp.
     */
    function getParticipantLastUpdateTime(address participant) public view isActiveParticipantModifier(participant) returns (uint256) {
        return _lastPotentialUpdateTime[participant];
    }

    // --- Action Functions ---

    /**
     * @notice Participant performs an action that costs minor potential.
     */
    function performMinorAction() external whenNotPaused isActiveParticipantModifier(msg.sender) hasEnoughPotential(msg.sender, minorActionCost) {
        // _spendPotential calls _calculateAndApplyPotentialChange internally first
        _spendPotential(msg.sender, minorActionCost);
        emit ActionPerformed(msg.sender, "Minor", minorActionCost, 0);
    }

    /**
     * @notice Participant performs an action that costs medium potential.
     */
    function performMediumAction() external whenNotPaused isActiveParticipantModifier(msg.sender) hasEnoughPotential(msg.sender, mediumActionCost) {
        _spendPotential(msg.sender, mediumActionCost);
        emit ActionPerformed(msg.sender, "Medium", mediumActionCost, 0);
    }

    /**
     * @notice Participant performs an action that costs major potential.
     */
    function performMajorAction() external whenNotPaused isActiveParticipantModifier(msg.sender) hasEnoughPotential(msg.sender, majorActionCost) {
        _spendPotential(msg.sender, majorActionCost);
        emit ActionPerformed(msg.sender, "Major", majorActionCost, 0);
    }

    /**
     * @notice Participant performs an action that generates potential.
     * Includes a bonus for their delegatee, if any.
     */
    function contributeEffort() external whenNotPaused isActiveParticipantModifier(msg.sender) {
         // _addPotential calls _calculateAndApplyPotentialChange internally first
        _addPotential(msg.sender, effortReward);
        emit ActionPerformed(msg.sender, "Effort", 0, effortReward);

        // Apply delegation bonus if applicable
        address currentDelegatee = delegatee[msg.sender];
        if (currentDelegatee != address(0) && participants[currentDelegatee]) {
            uint256 bonusAmount = (effortReward * delegationBonusRate) / 100;
            if (bonusAmount > 0) {
                 // _addPotential for delegatee also calls _calculateAndApplyPotentialChange internally
                _addPotential(currentDelegatee, bonusAmount);
                emit PotentialGenerated(currentDelegatee, bonusAmount, "Delegation Bonus");
            }
        }
    }

    /**
     * @notice Participant performs a more dynamic action with a variable potential cost.
     * Placeholder for actions with more complex effects.
     * @param baseCost The base potential cost for this specific action instance.
     */
    function boostInfluence(uint256 baseCost) external whenNotPaused isActiveParticipantModifier(msg.sender) hasEnoughPotential(msg.sender, baseCost) {
         _spendPotential(msg.sender, baseCost);
         emit ActionPerformed(msg.sender, "BoostInfluence", baseCost, 0);
         // Add logic here for what "boosting influence" actually does
         // (e.g., affects a separate ranking system, unlocks features, etc.)
    }


    // --- Delegation Functions ---

    /**
     * @notice Delegates the caller's potential influence to another participant.
     * @param delegateeAddress The address of the participant to delegate to.
     */
    function delegatePotential(address delegateeAddress) external whenNotPaused isActiveParticipantModifier(msg.sender) {
        if (msg.sender == delegateeAddress) revert SelfDelegationNotAllowed();
        if (!participants[delegateeAddress]) revert NotRegistered(); // Delegatee must be registered

        address currentDelegatee = delegatee[msg.sender];
        if (currentDelegatee == delegateeAddress) revert AlreadyDelegatingTo(delegateeAddress);

        // Remove old delegation reference from the old delegatee
        if (currentDelegatee != address(0)) {
             // Note: This only stores the LAST delegator.
             // For tracking all delegators, a mapping(address => address[]) or similar is needed,
             // which adds complexity (adding/removing from arrays).
             // Keeping it simple with last delegator for this example.
             if (delegator[currentDelegatee] == msg.sender) {
                 delegator[currentDelegatee] = address(0); // Clear if this was the only/last delegator
             }
        }

        // Set new delegation
        delegatee[msg.sender] = delegateeAddress;
        delegator[delegateeAddress] = msg.sender; // Store this delegator for the delegatee

        emit DelegationUpdated(msg.sender, currentDelegatee, delegateeAddress);
    }

    /**
     * @notice Removes the caller's potential delegation.
     */
    function undelegatePotential() external whenNotPaused isActiveParticipantModifier(msg.sender) {
        address currentDelegatee = delegatee[msg.sender];
        if (currentDelegatee == address(0)) revert NotDelegating();

        // Clear delegation
        delegatee[msg.sender] = address(0);

        // Clear delegator reference on the delegatee side (if this was the last delegator)
        if (delegator[currentDelegatee] == msg.sender) {
             delegator[currentDelegatee] = address(0);
        }

        emit DelegationUpdated(msg.sender, currentDelegatee, address(0));
    }

     /**
     * @notice Gets the address a participant has delegated their influence to.
     * @param delegatorAddress The address of the delegator.
     * @return The address of the delegatee, or address(0) if none.
     */
    function getDelegatee(address delegatorAddress) external view returns (address) {
        return delegatee[delegatorAddress];
    }

    /**
     * @notice Gets the address of the LAST participant who delegated to this address.
     * Simplified for example purposes. Tracking all delegators would require a different data structure.
     * @param delegateeAddress The address to check for incoming delegations.
     * @return The address of the last delegator, or address(0) if none recorded this way.
     */
     function getDelegator(address delegateeAddress) external view returns (address) {
         return delegator[delegateeAddress];
     }

    // --- Parameter Management Functions (Admin) ---

    /**
     * @notice Admin sets the potential decay rate per interval.
     * @param rate The new decay rate.
     */
    function setDecayRate(uint256 rate) external onlyOwner {
        uint256 oldRate = decayRatePerInterval;
        decayRatePerInterval = rate;
        emit ParametersUpdated("decayRatePerInterval", oldRate, rate);
    }

     /**
     * @notice Admin sets the potential generation rate per interval.
     * @param rate The new generation rate.
     */
    function setGenerationRate(uint256 rate) external onlyOwner {
        uint256 oldRate = generationRatePerInterval;
        generationRatePerInterval = rate;
        emit ParametersUpdated("generationRatePerInterval", oldRate, rate);
    }

    /**
     * @notice Admin sets the time interval for potential calculation.
     * @param interval The new interval in seconds.
     */
    function setPotentialInterval(uint256 interval) external onlyOwner {
        if (interval == 0) revert InvalidAmount();
        uint256 oldInterval = potentialInterval;
        potentialInterval = interval;
        emit ParametersUpdated("potentialInterval", oldInterval, interval);
    }

    /**
     * @notice Admin sets the potential costs for minor, medium, and major actions.
     * @param minorCost_ The new minor action cost.
     * @param mediumCost_ The new medium action cost.
     * @param majorCost_ The new major action cost.
     */
    function setActionCosts(uint256 minorCost_, uint256 mediumCost_, uint256 majorCost_) external onlyOwner {
        minorActionCost = minorCost_;
        mediumActionCost = mediumCost_;
        majorActionCost = majorCost_;
        // Emit separate events or a single structured event
        emit ParametersUpdated("minorActionCost", minorActionCost, minorCost_); // Emitting current before update, then new
        emit ParametersUpdated("mediumActionCost", mediumActionCost, mediumCost_);
        emit ParametersUpdated("majorActionCost", majorActionCost, majorCost_);
    }

    /**
     * @notice Admin sets the potential reward for the effort action.
     * @param reward The new effort reward.
     */
    function setEffortReward(uint256 reward) external onlyOwner {
        uint256 oldReward = effortReward;
        effortReward = reward;
        emit ParametersUpdated("effortReward", oldReward, reward);
    }

     /**
     * @notice Admin sets the percentage bonus potential the delegatee receives on effort action.
     * @param bonusRate The new bonus rate (e.g., 10 for 10%).
     */
    function setDelegationBonusRate(uint256 bonusRate) external onlyOwner {
         if (bonusRate > 100) revert InvalidAmount(); // Bonus cannot be > 100% of reward
        uint256 oldRate = delegationBonusRate;
        delegationBonusRate = bonusRate;
        emit ParametersUpdated("delegationBonusRate", oldRate, bonusRate);
     }

    // --- Contract State Management Functions (Admin/View) ---

    /**
     * @notice Pauses the contract, preventing most actions. Owner only.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Unpauses the contract, allowing actions again. Owner only.
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @notice Checks if the contract is currently paused.
     */
    function isPaused() external view returns (bool) {
        return paused;
    }

    /**
     * @notice Allows the owner to withdraw any Ether sent to the contract.
     * Useful if the contract were to collect fees or receive funds accidentally.
     * @param amount The amount of Ether to withdraw.
     */
    function withdrawEther(uint256 amount) external onlyOwner {
        if (amount == 0) revert InvalidAmount();
        if (address(this).balance < amount) revert InsufficientPotential(amount, address(this).balance); // Reusing error type for simplicity

        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Ether withdrawal failed"); // Use require for low-level call
        emit EtherWithdrawn(owner, amount);
    }


    // --- View Functions ---

    /**
     * @notice Returns all major contract parameters in a single view call.
     * @return params Tuple containing all parameters.
     */
    function getContractParameters()
        external
        view
        returns (
            uint256 decayRate,
            uint256 generationRate,
            uint256 potentialIntervalSeconds,
            uint256 minorCost,
            uint256 mediumCost,
            uint256 majorCost,
            uint256 effortRewardAmount,
            uint256 delegationBonusRatePercent,
            address contractOwner,
            bool isContractPaused
        )
    {
        return (
            decayRatePerInterval,
            generationRatePerInterval,
            potentialInterval,
            minorActionCost,
            mediumActionCost,
            majorActionCost,
            effortReward,
            delegationBonusRate,
            owner,
            paused
        );
    }

    /**
     * @notice Returns multiple state variables for a given participant.
     * Includes their current potential (dynamically calculated in view), last update time,
     * and delegation info.
     * @param participant The address of the participant.
     * @return state Tuple containing participant's potential, last update, delegatee, and delegator.
     */
     function getParticipantState(address participant)
        external
        view
        isActiveParticipantModifier(participant)
        returns (
            uint256 currentPotential,
            uint256 lastUpdateTime,
            address delegatedTo,
            address delegatedFromLast
        )
    {
         // Call the view function that calculates dynamic potential
         currentPotential = getParticipantPotential(participant);
         lastUpdateTime = _lastPotentialUpdateTime[participant];
         delegatedTo = delegatee[participant];
         delegatedFromLast = delegator[participant]; // Note: Simplified, last delegator only

         return (
             currentPotential,
             lastUpdateTime,
             delegatedTo,
             delegatedFromLast
         );
    }

    // Fallback function to receive Ether
    receive() external payable {}
    fallback() external payable {}
}
```