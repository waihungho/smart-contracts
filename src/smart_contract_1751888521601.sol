Okay, this is an exciting challenge! Let's create a smart contract based on concepts like time-based state transitions, dynamic resource management, reputation mechanics, and on-chain "chronicles" of user progress, while avoiding standard open-source patterns.

Here's a concept: **The Quantum Flux Chronicle**. Users (`Chroniclers`) navigate through different `Eras`. Each Era has specific rules, time requirements, and impacts on a user's `Reputation` and a resource called `Chronal Energy`. Users must manage their energy and reputation to progress between Eras. The contract itself manages the definitions of Eras and the global progression.

---

## Quantum Flux Chronicle Smart Contract

**Concept Summary:**
This smart contract simulates a journey through different "Eras" for registered participants called "Chroniclers". Chroniclers possess `Reputation` and `Chronal Energy`. Each Era has unique properties affecting how actions impact reputation and energy, minimum time requirements, and energy/reputation costs to transition to the next Era. Chroniclers earn/lose reputation and energy by performing actions specific to their current Era. Successfully transitioning to a new Era requires meeting criteria and may involve spending energy or paying a fee. The contract owner defines and advances the Eras. This contract explores concepts of time-based state evolution, resource decay, reputation systems, and dynamic parameters based on contract state.

**Key Concepts Highlighted:**
1.  **Time-Based State Transition:** Chroniclers must spend a minimum time in an Era before attempting to transition.
2.  **Dynamic Resources & Decay:** `Chronal Energy` is a resource that decays over real time unless replenished or managed.
3.  **Reputation System:** `Reputation` is an internal metric influenced by actions, potentially going negative.
4.  **Era-Specific Logic:** The effects of user actions and transition requirements vary based on the Chronicler's current Era.
5.  **Tiered Progression:** Users move sequentially through predefined Eras.
6.  **Delegation:** Users can delegate the ability to attempt Era transitions on their behalf.
7.  **On-chain "History" (Implicit):** While not storing every event, the user's state (current Era, entry time, reputation evolution) forms their personal chronicle.

**Outline:**

1.  **State Variables:** Core contract data (owner, pause status, current era, global decay rate, mappings for users and eras).
2.  **Structs:** Data structures for `Era` and `Chronicler`.
3.  **Events:** Signaling key actions and state changes (registration, transitions, actions, admin changes).
4.  **Modifiers:** Access control (`onlyOwner`, `whenNotPaused`, `whenPaused`) and state checks (`isRegisteredChronicler`, `isValidEra`).
5.  **Admin & Setup:** Functions only callable by the owner (set rates, add/update eras, advance global era, withdraw funds, pause/unpause, ownership).
6.  **Chronicler Management & Core Logic:** Functions for users to register, perform actions within an era, calculate current energy, and attempt era transitions.
7.  **Delegation:** Functions for managing Era transition delegation rights.
8.  **Energy Management:** Functions related to Chronal Energy (deposit ETH for energy, delegate energy).
9.  **View Functions:** Read-only functions to query contract state and user status.
10. **Internal Helpers:** Private/internal functions for core logic (calculating decay, state updates, eligibility checks).
11. **Receive/Fallback:** Allow receiving ETH.

**Function Summary:**

1.  `constructor()`: Initializes contract with owner and initial era.
2.  `addEraDefinition()`: Owner adds a new Era definition.
3.  `updateEraDefinition()`: Owner updates an existing Era definition.
4.  `setCurrentEra()`: Owner advances the global current Era the contract is operating under.
5.  `setBaseEnergyDecayRate()`: Owner sets the base rate for Chronal Energy decay.
6.  `setEraTransitionFee()`: Owner sets an ETH fee for transitioning into a specific era.
7.  `registerChronicler()`: Allows a user to register as a Chronicler (potentially with a fee).
8.  `performActionInEra()`: A Chronicler performs an action, affecting reputation and energy based on their current Era rules.
9.  `calculateCurrentChronalEnergy()`: Calculates a Chronicler's energy considering decay since the last update.
10. `attuneToEra()`: A Chronicler performs a specific action to potentially mitigate decay or gain a small boost (calls `performActionInEra` with specific type).
11. `attemptEraTransition()`: A Chronicler attempts to move to the next Era, checking time, reputation, energy, and fee requirements.
12. `delegateEraTransition()`: A Chronicler delegates their right to call `attemptEraTransition` to another address.
13. `revokeEraTransitionDelegation()`: A Chronicler revokes an existing delegation.
14. `depositETHForEnergy()`: Allows a Chronicler to deposit ETH to gain Chronal Energy.
15. `delegateChronalEnergy()`: A Chronicler can delegate a portion of their Chronal Energy to another Chronicler.
16. `reclaimDelegatedEnergy()`: A Chronicler can reclaim energy they previously delegated.
17. `withdrawFees()`: Owner can withdraw accumulated ETH fees.
18. `pauseContract()`: Owner can pause certain contract functions.
19. `unpauseContract()`: Owner can unpause the contract.
20. `transferOwnership()`: Owner transfers contract ownership.
21. `renounceOwnership()`: Owner renounces contract ownership.
22. `getChroniclerStatus()`: View function to get a Chronicler's detailed state.
23. `getCurrentEraDetails()`: View function to get details of the global current Era.
24. `getEraDefinition()`: View function to get details of any defined Era by ID.
25. `getTimeSpentInCurrentEra()`: View function to get the time a Chronicler has been in their current Era.
26. `isRegisteredChronicler()`: View function to check if an address is registered.
27. `getAccountBalance()`: View function to get the contract's current ETH balance.
28. `getEraTransitionDelegatee()`: View function to see who a Chronicler has delegated transition rights to.
29. `getDelegatedEnergy()`: View function to see how much energy a Chronicler has delegated to another.
30. `receive()`: Allows the contract to receive ETH directly.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title QuantumFluxChronicle
/// @dev A smart contract where users (Chroniclers) progress through time-based Eras,
/// managing Reputation and Chronal Energy influenced by actions and decay.

contract QuantumFluxChronicle is Ownable, Pausable {

    // --- State Variables ---

    /// @dev Defines the properties and requirements of an Era.
    struct Era {
        uint256 id;                  // Unique identifier for the era
        uint256 minDuration;         // Minimum time (seconds) a chronicler must spend in this era
        int256 minReputation;       // Minimum reputation required to *attempt* transition to the next era
        uint256 energyCostToEnter;   // Chronal Energy cost to enter the *next* era from this one
        int256 reputationEffectPerAction; // Change in reputation for performing a standard action in this era
        int256 energyEffectPerAction;     // Change in energy for performing a standard action in this era
        uint256 chronalDecayRateOverride; // Optional decay rate specific to this era (0 means use base rate)
        uint256 entryFee;            // ETH fee required to enter the *next* era from this one
    }

    /// @dev Stores the state of a registered Chronicler.
    struct Chronicler {
        bool isRegistered;                  // Whether the address is a registered chronicler
        uint256 currentEraId;              // The ID of the era the chronicler is currently in
        uint256 eraEntryTimestamp;         // Timestamp when the chronicler entered the current era
        int256 reputation;                  // The chronicler's current reputation score
        uint256 chronalEnergy;             // The chronicler's current chronal energy resource
        address eraTransitionDelegatee;    // Address allowed to attempt era transition on behalf of this chronicler
        mapping(address => uint256) delegatedEnergy; // Energy this chronicler has delegated to others
        mapping(address => uint256) receivedDelegatedEnergy; // Energy received from others (for tracking)
        uint256 lastEnergyCalculationTimestamp; // Timestamp energy was last updated/calculated
    }

    uint256 public totalErasDefined; // Total number of era definitions created
    uint256 public currentGlobalEraId; // The ID of the currently active era for *new* registrations/global events
    uint256 public baseChronalEnergyDecayRate; // Base energy decay rate per second (e.g., 1 unit per second)
    uint256 public registrationFee; // ETH fee to become a Chronicler

    mapping(uint256 => Era) public eraDefinitions; // Stores definitions of all eras by ID
    mapping(address => Chronicler) private chroniclers; // Stores chronicler state by address

    // --- Events ---

    event ChroniclerRegistered(address indexed chronicler, uint256 eraId, uint256 registrationFeePaid);
    event EraTransitionAttempted(address indexed chronicler, uint256 fromEraId, uint256 toEraId, bool successful, string message);
    event EraTransitionSuccessful(address indexed chronicler, uint256 fromEraId, uint256 toEraId, uint256 timestamp, uint256 transitionFeePaid);
    event ActionPerformed(address indexed chronicler, uint256 eraId, int256 reputationChange, int256 energyChange);
    event EnergyDeposited(address indexed chronicler, uint256 amountETH, uint256 energyGained);
    event EnergyDelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event EnergyReclaimed(address indexed delegator, address indexed delegatee, uint256 amount);
    event EraDefinitionAdded(uint256 eraId);
    event EraDefinitionUpdated(uint256 eraId);
    event CurrentGlobalEraAdvanced(uint256 newEraId);
    event FundsWithdrawn(address indexed to, uint255 amount); // Using uint255 for safe arithmetic with balance
    event EraTransitionDelegationSet(address indexed delegator, address indexed delegatee);
    event EraTransitionDelegationRevoked(address indexed delegator);
    event RegistrationFeeUpdated(uint256 newFee);
    event BaseEnergyDecayRateUpdated(uint256 newRate);

    // --- Modifiers ---

    /// @dev Checks if the caller is a registered chronicler.
    modifier isRegisteredChronicler(address _addr) {
        require(chroniclers[_addr].isRegistered, "Not a registered chronicler");
        _;
    }

    /// @dev Checks if an era ID is valid (exists).
    modifier isValidEra(uint256 eraId) {
        require(eraId > 0 && eraId <= totalErasDefined, "Invalid era ID");
        _;
    }

    // --- Constructor ---

    constructor(uint256 _initialBaseDecayRate, uint256 _initialRegistrationFee) Ownable(msg.sender) Pausable() {
        // Era 0 is a non-existent placeholder. Era IDs start from 1.
        totalErasDefined = 0;
        currentGlobalEraId = 1; // New chroniclers start at Era 1 (assuming it's added immediately after deploy)
        baseChronalEnergyDecayRate = _initialBaseDecayRate;
        registrationFee = _initialRegistrationFee;
    }

    // --- Receive/Fallback ---

    /// @dev Allows the contract to receive ETH directly.
    /// ETH sent directly without calling a payable function is added to the contract balance.
    receive() external payable {}

    // --- Admin & Setup (onlyOwner) ---

    /// @notice Adds a new era definition. Requires era IDs to be sequential.
    /// @param _minDuration Minimum time (seconds) in era before transition eligibility.
    /// @param _minReputation Minimum reputation to attempt transition.
    /// @param _energyCostToEnter Chronal Energy cost to enter the *next* era.
    /// @param _reputationEffectPerAction Reputation change per action in this era.
    /// @param _energyEffectPerAction Energy change per action in this era.
    /// @param _chronalDecayRateOverride Optional decay override (0 means use base rate).
    /// @param _entryFee ETH fee to enter the *next* era from this one.
    /// @dev Only callable by the owner. Adds the era definition with the next available ID.
    function addEraDefinition(
        uint256 _minDuration,
        int256 _minReputation,
        uint256 _energyCostToEnter,
        int256 _reputationEffectPerAction,
        int256 _energyEffectPerAction,
        uint256 _chronalDecayRateOverride,
        uint256 _entryFee
    ) external onlyOwner {
        totalErasDefined++;
        eraDefinitions[totalErasDefined] = Era({
            id: totalErasDefined,
            minDuration: _minDuration,
            minReputation: _minReputation,
            energyCostToEnter: _energyCostToEnter,
            reputationEffectPerAction: _reputationEffectPerAction,
            energyEffectPerAction: _energyEffectPerAction,
            chronalDecayRateOverride: _chronalDecayRateOverride,
            entryFee: _entryFee
        });
        emit EraDefinitionAdded(totalErasDefined);
    }

    /// @notice Updates an existing era definition.
    /// @param _eraId The ID of the era to update.
    /// @param _minDuration New minimum duration.
    /// @param _minReputation New minimum reputation.
    /// @param _energyCostToEnter New energy cost to enter next era.
    /// @param _reputationEffectPerAction New reputation effect.
    /// @param _energyEffectPerAction New energy effect.
    /// @param _chronalDecayRateOverride New decay override.
    /// @param _entryFee New ETH entry fee for next era.
    /// @dev Only callable by the owner. Cannot update Era 0.
    function updateEraDefinition(
        uint256 _eraId,
        uint256 _minDuration,
        int256 _minReputation,
        uint256 _energyCostToEnter,
        int256 _reputationEffectPerAction,
        int256 _energyEffectPerAction,
        uint256 _chronalDecayRateOverride,
        uint256 _entryFee
    ) external onlyOwner isValidEra(_eraId) {
        Era storage era = eraDefinitions[_eraId];
        era.minDuration = _minDuration;
        era.minReputation = _minReputation;
        era.energyCostToEnter = _energyCostToEnter;
        era.reputationEffectPerAction = _reputationEffectPerAction;
        era.energyEffectPerAction = _energyEffectPerAction;
        era.chronalDecayRateOverride = _chronalDecayRateOverride;
        era.entryFee = _entryFee;
        emit EraDefinitionUpdated(_eraId);
    }

    /// @notice Advances the current global era ID. New chroniclers will register into the new era.
    /// Does not affect chroniclers already registered in previous eras.
    /// @dev Only callable by the owner. Requires the next era definition to exist.
    function setCurrentGlobalEra() external onlyOwner {
        require(currentGlobalEraId + 1 <= totalErasDefined, "Next era definition does not exist");
        currentGlobalEraId++;
        emit CurrentGlobalEraAdvanced(currentGlobalEraId);
    }

    /// @notice Sets the base chronal energy decay rate per second.
    /// @param _rate The new base decay rate.
    /// @dev Only callable by the owner. Era-specific overrides take precedence.
    function setBaseEnergyDecayRate(uint256 _rate) external onlyOwner {
        baseChronalEnergyDecayRate = _rate;
        emit BaseEnergyDecayRateUpdated(_rate);
    }

     /// @notice Sets the registration fee required for new chroniclers.
     /// @param _fee The new registration fee in wei.
     /// @dev Only callable by the owner.
    function setRegistrationFee(uint256 _fee) external onlyOwner {
        registrationFee = _fee;
        emit RegistrationFeeUpdated(_fee);
    }

    /// @notice Allows the owner to withdraw accumulated ETH fees.
    /// @param _to The address to send the ETH to.
    /// @dev Only callable by the owner. Transfers the entire contract balance.
    function withdrawFees(address payable _to) external onlyOwner {
        uint255 balance = uint255(address(this).balance); // Use uint255 for balance check
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = _to.call{value: balance}("");
        require(success, "ETH withdrawal failed");
        emit FundsWithdrawn(_to, balance);
    }

    /// @notice Pauses the contract, preventing most user interactions.
    /// @dev Inherited from OpenZeppelin Pausable. Only callable by the owner.
    function pauseContract() external onlyOwner {
        _pause();
        emit ContractPaused();
    }

    /// @notice Unpauses the contract, allowing user interactions again.
    /// @dev Inherited from OpenZeppelin Pausable. Only callable by the owner.
    function unpauseContract() external onlyOwner {
        _unpause();
        emit ContractUnpaused();
    }

    // transferOwnership and renounceOwnership are inherited from Ownable and are external

    // --- Chronicler Management & Core Logic (whenNotPaused) ---

    /// @notice Allows an address to register as a Chronicler.
    /// They are placed in the `currentGlobalEraId` and start with 0 reputation and energy.
    /// Requires paying the current `registrationFee`.
    /// @dev Only callable if not paused. An address can only register once.
    function registerChronicler() external payable whenNotPaused {
        require(!chroniclers[msg.sender].isRegistered, "Already a registered chronicler");
        require(msg.value >= registrationFee, "Insufficient registration fee");
        require(currentGlobalEraId > 0 && currentGlobalEraId <= totalErasDefined, "Global era not set up"); // Ensure Era 1 exists

        // Refund excess ETH
        if (msg.value > registrationFee) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - registrationFee}("");
            require(success, "Refund failed");
        }

        Chronicler storage chronicler = chroniclers[msg.sender];
        chronicler.isRegistered = true;
        chronicler.currentEraId = currentGlobalEraId;
        chronicler.eraEntryTimestamp = block.timestamp;
        chronicler.reputation = 0;
        chronicler.chronalEnergy = 0; // Start with no energy, must acquire it
        chronicler.lastEnergyCalculationTimestamp = block.timestamp;

        emit ChroniclerRegistered(msg.sender, currentGlobalEraId, registrationFee);
    }

    /// @notice Performs a generic action within the Chronicler's current era.
    /// Effects on reputation and energy depend on the Chronicler's current Era definition.
    /// Automatically calculates and applies energy decay before applying action effects.
    /// @dev Only callable by a registered chronicler when not paused.
    function performActionInEra() external whenNotPaused isRegisteredChronicler(msg.sender) {
        Chronicler storage chronicler = chroniclers[msg.sender];
        Era storage currentEra = eraDefinitions[chronicler.currentEraId];

        // 1. Apply energy decay first
        _applyEnergyDecay(msg.sender);

        // 2. Apply action effects
        chronicler.reputation += currentEra.reputationEffectPerAction;
        // Ensure energy doesn't go below zero
        if (currentEra.energyEffectPerAction < 0) {
             uint256 energyLoss = uint256(-currentEra.energyEffectPerAction);
             if (chronicler.chronalEnergy < energyLoss) {
                 chronicler.chronalEnergy = 0;
             } else {
                 chronicler.chronalEnergy -= energyLoss;
             }
        } else {
             chronicler.chronalEnergy += uint256(currentEra.energyEffectPerAction);
        }

        // 3. Update energy calculation timestamp
        chronicler.lastEnergyCalculationTimestamp = block.timestamp;

        emit ActionPerformed(msg.sender, chronicler.currentEraId, currentEra.reputationEffectPerAction, currentEra.energyEffectPerAction);
    }

     /// @notice A specific action type within an era, primarily for mitigating decay or gaining a small boost.
     /// @dev Calls `performActionInEra` internally, but could have specific logic if needed.
    function attuneToEra() external whenNotPaused isRegisteredChronicler(msg.sender) {
        // Currently this is just a wrapper, but could have unique parameters/effects in a more complex version.
        // For this implementation, it's treated as a standard action.
        performActionInEra();
        // Could emit a different event if needed: emit AttunementPerformed(msg.sender, chroniclers[msg.sender].currentEraId);
    }


    /// @notice Calculates a Chronicler's current energy, accounting for decay since the last update.
    /// Does *not* modify the chronicler's stored energy state. Use performActionInEra or attemptEraTransition
    /// to update the stored state after calculation.
    /// @param _addr The address of the chronicler.
    /// @return The calculated current chronal energy.
    /// @dev Internal helper, but exposed as a view function for convenience.
    function calculateCurrentChronalEnergy(address _addr) public view isRegisteredChronicler(_addr) returns (uint256) {
        Chronicler storage chronicler = chroniclers[_addr];
        uint256 eraId = chronicler.currentEraId;

        uint256 decayRate = eraDefinitions[eraId].chronalDecayRateOverride > 0
                            ? eraDefinitions[eraId].chronalDecayRateOverride
                            : baseChronalEnergyDecayRate;

        uint256 timeElapsed = block.timestamp - chronicler.lastEnergyCalculationTimestamp;
        uint256 decayAmount = timeElapsed * decayRate;

        if (decayAmount > chronicler.chronalEnergy) {
            return 0;
        } else {
            return chronicler.chronalEnergy - decayAmount;
        }
    }

    /// @notice Allows a Chronicler (or their delegatee) to attempt to transition to the next era.
    /// Checks if the current era definition allows transition and if the chronicler meets all requirements.
    /// If successful, updates the chronicler's era, timestamp, reputation, and energy.
    /// Pays the required `entryFee` to the contract.
    /// @dev Callable by the chronicler or their delegatee when not paused. Requires sufficient ETH attached if there's an entry fee.
    function attemptEraTransition() external payable whenNotPaused isRegisteredChronicler(msg.sender) {
        Chronicler storage chronicler = chroniclers[msg.sender];
        uint256 fromEraId = chronicler.currentEraId;
        uint256 toEraId = fromEraId + 1;

        // Check if caller is the chronicler or their delegatee
        require(msg.sender == address(chronicler) || msg.sender == chronicler.eraTransitionDelegatee, "Not authorized to attempt transition");

        // Calculate current energy before checking requirements
        chronicler.chronalEnergy = calculateCurrentChronalEnergy(msg.sender);
        chronicler.lastEnergyCalculationTimestamp = block.timestamp; // Update timestamp after calculation

        string memory failMessage = "";
        bool success = false;
        uint256 feePaid = 0;

        // Check if the next era exists
        if (toEraId > totalErasDefined) {
            failMessage = "Next era definition does not exist";
        } else {
            Era storage fromEra = eraDefinitions[fromEraId];
            Era storage toEra = eraDefinitions[toEraId];

            // Check transition requirements
            uint256 timeInEra = block.timestamp - chronicler.eraEntryTimestamp;
            if (timeInEra < fromEra.minDuration) {
                failMessage = "Minimum duration not met";
            } else if (chronicler.reputation < fromEra.minReputation) {
                 failMessage = "Minimum reputation not met";
            } else if (chronicler.chronalEnergy < fromEra.energyCostToEnter) {
                 failMessage = "Insufficient chronal energy";
            } else if (msg.value < fromEra.entryFee) {
                 failMessage = "Insufficient ETH for entry fee";
            } else {
                // Transition successful
                chronicler.currentEraId = toEraId;
                chronicler.eraEntryTimestamp = block.timestamp;
                chronicler.chronalEnergy -= fromEra.energyCostToEnter; // Spend energy cost

                // Refund excess ETH
                if (msg.value > fromEra.entryFee) {
                    (bool refundSuccess, ) = payable(msg.sender).call{value: msg.value - fromEra.entryFee}("");
                    require(refundSuccess, "Refund failed after successful transition"); // Must succeed or revert
                }
                feePaid = fromEra.entryFee;
                success = true;
                emit EraTransitionSuccessful(msg.sender, fromEraId, toEraId, block.timestamp, feePaid);
            }
        }

        emit EraTransitionAttempted(msg.sender, fromEraId, toEraId, success, success ? "Success" : failMessage);

        require(success, failMessage); // Revert if transition failed
    }

    // --- Delegation ---

    /// @notice Delegates the ability to attempt Era transition for the caller to another address.
    /// Only the delegatee can call `attemptEraTransition` on behalf of the delegator.
    /// Can be set to `address(0)` to clear delegation.
    /// @param _delegatee The address to delegate the transition right to.
    /// @dev Only callable by a registered chronicler when not paused. Cannot delegate to self.
    function delegateEraTransition(address _delegatee) external whenNotPaused isRegisteredChronicler(msg.sender) {
        require(msg.sender != _delegatee, "Cannot delegate to self");
        chroniclers[msg.sender].eraTransitionDelegatee = _delegatee;
        emit EraTransitionDelegationSet(msg.sender, _delegatee);
    }

    /// @notice Revokes the current Era transition delegation for the caller.
    /// @dev Only callable by a registered chronicler when not paused.
    function revokeEraTransitionDelegation() external whenNotPaused isRegisteredChronicler(msg.sender) {
        chroniclers[msg.sender].eraTransitionDelegatee = address(0);
        emit EraTransitionDelegationRevoked(msg.sender);
    }

    // --- Energy Management (whenNotPaused) ---

    /// @notice Allows a Chronicler to deposit ETH and receive Chronal Energy in exchange.
    /// The conversion rate could be fixed or dynamic (this example uses a simple fixed rate or owner-set rate).
    /// Requires ETH to be sent with the transaction.
    /// @dev Only callable by a registered chronicler when not paused.
    function depositETHForEnergy() external payable whenNotPaused isRegisteredChronicler(msg.sender) {
        require(msg.value > 0, "Must deposit ETH");

        // Simple conversion: 1 ETH = 1000 Energy (example rate, owner could set this)
        // Using a fixed rate for simplicity here. A dynamic rate would add more complexity.
        uint256 energyRatePerEth = 1000; // Owner could have a function to set this
        uint256 energyGained = (msg.value * energyRatePerEth) / 1 ether;

        Chronicler storage chronicler = chroniclers[msg.sender];
         // Apply decay before adding new energy
        chronicler.chronalEnergy = calculateCurrentChronalEnergy(msg.sender);
        chronicler.chronalEnergy += energyGained;
        chronicler.lastEnergyCalculationTimestamp = block.timestamp;

        emit EnergyDeposited(msg.sender, msg.value, energyGained);
    }

    /// @notice Allows a Chronicler to delegate a portion of their Chronal Energy to another Chronicler.
    /// The recipient cannot re-delegate this energy. The delegator can reclaim it.
    /// @param _delegatee The address to delegate energy to.
    /// @param _amount The amount of energy to delegate.
    /// @dev Only callable by a registered chronicler when not paused. Delegatee must also be registered. Cannot delegate to self.
    function delegateChronalEnergy(address _delegatee, uint256 _amount) external whenNotPaused isRegisteredChronicler(msg.sender) isRegisteredChronicler(_delegatee) {
        require(msg.sender != _delegatee, "Cannot delegate energy to self");
        require(_amount > 0, "Amount must be greater than 0");

        Chronicler storage delegator = chroniclers[msg.sender];
        Chronicler storage delegatee = chroniclers[_delegatee];

         // Apply decay before checking balance and delegating
        delegator.chronalEnergy = calculateCurrentChronalEnergy(msg.sender);
        delegator.lastEnergyCalculationTimestamp = block.timestamp;

        require(delegator.chronalEnergy >= _amount, "Insufficient chronal energy to delegate");

        delegator.chronalEnergy -= _amount;
        delegator.delegatedEnergy[_delegatee] += _amount;
        delegatee.chronalEnergy += _amount; // Delegatee immediately receives the energy
        delegatee.receivedDelegatedEnergy[msg.sender] += _amount; // Track who it came from
        delegatee.lastEnergyCalculationTimestamp = block.timestamp; // Update delegatee's timestamp as their energy changed

        emit EnergyDelegated(msg.sender, _delegatee, _amount);
    }

    /// @notice Allows a Chronicler to reclaim Chronal Energy previously delegated to another Chronicler.
    /// The reclaiming Chronicler receives the energy back from the delegatee's current balance.
    /// If the delegatee doesn't have enough balance, the reclaiming Chronicler gets what's available.
    /// @param _delegatee The address the energy was delegated to.
    /// @dev Only callable by a registered chronicler when not paused. Delegatee must be registered.
    function reclaimDelegatedEnergy(address _delegatee) external whenNotPaused isRegisteredChronicler(msg.sender) isRegisteredChronicler(_delegatee) {
        require(msg.sender != _delegatee, "Cannot reclaim energy from self");

        Chronicler storage delegator = chroniclers[msg.sender];
        Chronicler storage delegatee = chroniclers[_delegatee];

        uint256 amountToReclaim = delegator.delegatedEnergy[_delegatee];
        require(amountToReclaim > 0, "No energy delegated to this address");

         // Apply decay to both before transferring
        delegator.chronalEnergy = calculateCurrentChronalEnergy(msg.sender);
        delegator.lastEnergyCalculationTimestamp = block.timestamp;

        delegatee.chronalEnergy = calculateCurrentChronalEnergy(_delegatee);
        delegatee.lastEnergyCalculationTimestamp = block.timestamp;

        uint256 amountReclaimed = 0;
        if (delegatee.chronalEnergy >= amountToReclaim) {
            // Delegatee has enough energy to give back the full amount
            delegatee.chronalEnergy -= amountToReclaim;
            delegator.chronalEnergy += amountToReclaim;
            amountReclaimed = amountToReclaim;
        } else {
            // Delegatee doesn't have enough, reclaim what they have
            amountReclaimed = delegatee.chronalEnergy;
            delegator.chronalEnergy += amountReclaimed;
            delegatee.chronalEnergy = 0;
        }

        delegator.delegatedEnergy[_delegatee] -= amountReclaimed;
        delegatee.receivedDelegatedEnergy[msg.sender] -= amountReclaimed;

        emit EnergyReclaimed(msg.sender, _delegatee, amountReclaimed);
    }


    // --- View Functions ---

    /// @notice Gets the detailed status of a chronicler.
    /// @param _addr The address of the chronicler.
    /// @return isRegistered, currentEraId, eraEntryTimestamp, reputation, chronalEnergy (calculated), lastEnergyCalculationTimestamp, eraTransitionDelegatee.
    function getChroniclerStatus(address _addr) external view isRegisteredChronicler(_addr) returns (
        bool isRegistered,
        uint256 currentEraId,
        uint256 eraEntryTimestamp,
        int256 reputation,
        uint256 chronalEnergy, // This is the calculated current energy
        uint256 lastEnergyCalculationTimestamp,
        address eraTransitionDelegatee
    ) {
        Chronicler storage chronicler = chroniclers[_addr];
        return (
            chronicler.isRegistered,
            chronicler.currentEraId,
            chronicler.eraEntryTimestamp,
            chronicler.reputation,
            calculateCurrentChronalEnergy(_addr), // Return calculated energy
            chronicler.lastEnergyCalculationTimestamp,
            chronicler.eraTransitionDelegatee
        );
    }

    /// @notice Gets the details of the current global era.
    /// @return The Era struct for the current global era.
    function getCurrentEraDetails() external view isValidEra(currentGlobalEraId) returns (Era memory) {
        return eraDefinitions[currentGlobalEraId];
    }

    /// @notice Gets the definition details for a specific era ID.
    /// @param _eraId The ID of the era to query.
    /// @return The Era struct for the requested era.
    function getEraDefinition(uint256 _eraId) external view isValidEra(_eraId) returns (Era memory) {
        return eraDefinitions[_eraId];
    }

    /// @notice Calculates and returns the time a chronicler has spent in their current era.
    /// @param _addr The address of the chronicler.
    /// @return The duration in seconds.
    function getTimeSpentInCurrentEra(address _addr) external view isRegisteredChronicler(_addr) returns (uint256) {
        return block.timestamp - chroniclers[_addr].eraEntryTimestamp;
    }

    /// @notice Checks if an address is a registered chronicler.
    /// @param _addr The address to check.
    /// @return True if registered, false otherwise.
    function isRegisteredChronicler(address _addr) public view returns (bool) {
        return chroniclers[_addr].isRegistered;
    }

    /// @notice Gets the contract's current ETH balance.
    /// @return The balance in wei.
    function getAccountBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Gets the address currently delegated to attempt Era transition for a chronicler.
    /// @param _addr The address of the chronicler.
    /// @return The delegatee address, or address(0) if no delegatee is set.
    function getEraTransitionDelegatee(address _addr) external view isRegisteredChronicler(_addr) returns (address) {
        return chroniclers[_addr].eraTransitionDelegatee;
    }

     /// @notice Gets the amount of energy a chronicler has delegated to a specific address.
     /// @param _delegator The address of the chronicler who delegated energy.
     /// @param _delegatee The address the energy was delegated to.
     /// @return The amount of delegated energy.
    function getDelegatedEnergy(address _delegator, address _delegatee) external view isRegisteredChronicler(_delegator) returns (uint256) {
         // Does not require delegatee to be registered to check amount delegated *to* them
        return chroniclers[_delegator].delegatedEnergy[_delegatee];
    }

    // --- Internal Helpers ---

    /// @dev Calculates and applies chronal energy decay for a chronicler.
    /// Updates the chronicler's chronal energy and last energy calculation timestamp.
    /// @param _addr The address of the chronicler.
    function _applyEnergyDecay(address _addr) internal {
        Chronicler storage chronicler = chroniclers[_addr];
        Era storage currentEra = eraDefinitions[chronicler.currentEraId];

        uint256 decayRate = currentEra.chronalDecayRateOverride > 0
                            ? currentEra.chronalDecayRateOverride
                            : baseChronalEnergyDecayRate;

        uint256 timeElapsed = block.timestamp - chronicler.lastEnergyCalculationTimestamp;
        uint256 decayAmount = timeElapsed * decayRate;

        if (decayAmount >= chronicler.chronalEnergy) {
            chronicler.chronalEnergy = 0;
        } else {
            chronicler.chronalEnergy -= decayAmount;
        }

        chronicler.lastEnergyCalculationTimestamp = block.timestamp;
    }
}
```