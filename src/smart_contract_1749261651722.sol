Okay, here is a Solidity smart contract called `EtherealEpochs`. It implements a system based on time-locked "epochs", internal resource management ("EpochalEssence"), user interactions, and dynamic state changes.

It aims for creativity by combining:
1.  **Epoch-based System:** State and interactions change based on time-bound periods (epochs).
2.  **Internal Resource:** Users manage a non-transferable resource (`EpochalEssence`) within the contract.
3.  **Time-Locked Actions:** Users can commit to actions that only become available in future epochs.
4.  **Decentralized Epoch Advancement:** Anyone can trigger the check for epoch advancement, with potential rewards.
5.  **Dynamic Parameters:** Interaction costs and essence generation rates can change.
6.  **Epoch States:** Epochs can have different "moods" that affect available actions.

It includes over 20 functions covering management, user interaction, configuration, and state queries.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline and Function Summary ---
/*
Contract: EtherealEpochs

Concept:
A dynamic system evolving through discrete time periods called "Epochs". Users, referred to as "Keepers", manage an internal resource called "EpochalEssence" and interact with the system. Actions and resource generation are influenced by the current Epoch's state and specific time-locked mechanics. Epochs can be advanced by anyone once a time threshold is met, potentially rewarding the caller.

State Variables:
- Ownership and Admin
- Epoch tracking (current number, start time, duration)
- User Essence balances
- User Time-Locked Actions
- Epoch configuration parameters (costs, rates)
- Epoch state/mood
- Keeper registration

Enums:
- EpochState: Defines the possible "moods" or states of an epoch (e.g., Dormant, Flourishing, Turbulent).

Structs:
- LockedAction: Details of a time-locked action (target epoch, amount, type).

Modifiers:
- onlyOwner: Restricts access to the contract owner.
- onlyKeeper: Restricts access to registered Keepers.
- epochReadyToAdvance: Checks if the time threshold for advancing the epoch has passed.
- actionLocked: Checks if a user has a pending locked action.
- actionClaimable: Checks if a user's locked action is ready to be claimed.
- epochInteractionAvailable: Checks if basic epoch interaction is allowed in the current state.
- essenceGenerationAvailable: Checks if essence generation is allowed in the current state.

Events:
- EpochAdvanced: Emitted when a new epoch begins.
- EpochStateChanged: Emitted when the epoch state transitions.
- EssenceGenerated: Emitted when a user generates essence.
- EssenceConsumed: Emitted when essence is spent.
- EssenceDistributed: Emitted when essence is distributed.
- LockedActionSet: Emitted when a user sets a time-locked action.
- LockedActionClaimed: Emitted when a time-locked action is claimed.
- LockedActionCancelled: Emitted when a time-locked action is cancelled.
- KeeperRegistered: Emitted when a new address registers as a Keeper.
- InteractionPerformed: Emitted when a user performs the main epoch interaction.

Functions (> 20 total):

-   **Epoch Management:**
    1.  `constructor`: Initializes the contract with owner, initial epoch, duration, and state.
    2.  `triggerEpochTransitionCheck`: External function allowing anyone to check if the epoch can advance and trigger the internal logic. Rewards caller if successful.
    3.  `_advanceEpoch`: Internal core logic to advance the epoch, update state, and distribute reward.
    4.  `getCurrentEpoch`: Returns the current epoch number. (View)
    5.  `getEpochStartTime`: Returns the timestamp when the current epoch started. (View)
    6.  `getEpochDuration`: Returns the configured duration of each epoch. (View)
    7.  `getEpochTransitionThreshold`: Returns the timestamp when the *next* epoch transition is possible. (View)
    8.  `getCurrentEpochState`: Returns the current state/mood of the epoch. (View)
    9.  `setEpochDuration`: Allows owner to change the duration of future epochs. (Owner)
    10. `forceEpochStateTransition`: Allows owner to manually set the current epoch state. (Owner)
    11. `getEpochInteractionAvailability`: Checks if `performEpochInteraction` is currently allowed based on state. (View)
    12. `getEssenceGenerationAvailability`: Checks if `generateEssence` is currently allowed based on state. (View)
    13. `setInteractionAvailability`: Owner configures which states allow basic interaction. (Owner)
    14. `setEssenceGenerationAvailability`: Owner configures which states allow essence generation. (Owner)

-   **Essence Management:**
    15. `getUserEssence`: Returns the EpochalEssence balance for an address. (View)
    16. `generateEssence`: Allows a Keeper to generate essence based on current epoch state and rate. (Keeper)
    17. `consumeEssence`: Internal function to deduct essence.
    18. `distributeEssence`: Allows owner to distribute essence to an address. (Owner)
    19. `burnEssence`: Allows a Keeper to burn their own essence. (Keeper)
    20. `batchDistributeEssence`: Allows owner to distribute essence to multiple addresses. (Owner)
    21. `setEssenceGenerationRate`: Owner sets the base rate for essence generation. (Owner)
    22. `getEssenceGenerationRate`: Returns the current essence generation rate. (View)
    23. `queryEssenceGenerationAmount`: Pure function to calculate potential essence generation. (Pure)

-   **Keeper & Interaction:**
    24. `registerKeeper`: Allows any address to register as a Keeper.
    25. `isKeeper`: Checks if an address is a registered Keeper. (View)
    26. `getKeeperCount`: Returns the total number of registered Keepers. (View)
    27. `performEpochInteraction`: A core action a Keeper can take, costs essence, affected by epoch state. (Keeper)
    28. `getInteractionCost`: Returns the current cost of `performEpochInteraction`. (View)
    29. `setInteractionCost`: Owner sets the cost for `performEpochInteraction`. (Owner)

-   **Time-Locked Actions:**
    30. `setTimeLockedAction`: Allows a Keeper to lock essence or an action until a future epoch. (Keeper)
    31. `claimLockedAction`: Allows a Keeper to claim/execute their locked action once the target epoch is reached. (Keeper)
    32. `cancelLockedAction`: Allows a Keeper to cancel a pending locked action before the target epoch (potentially with penalty). (Keeper)
    33. `getUserLockedAction`: Returns details of a user's pending locked action. (View)

-   **Ownership & Configuration:**
    34. `transferOwnership`: Transfers contract ownership. (Owner)
    35. `renounceOwnership`: Renounces contract ownership. (Owner)
    36. `getEpochAdvancementReward`: Returns the amount of ETH rewarded for triggering epoch advancement. (View)
    37. `setEpochAdvancementReward`: Owner sets the ETH reward for triggering epoch advancement. (Owner)

*/

// --- Errors ---
error NotOwner();
error NotKeeper();
error EpochNotReadyToAdvance();
error EpochDurationTooShort();
error InvalidEpochState();
error InsufficientEssence(uint256 required, uint256 available);
error InteractionNotAvailable();
error EssenceGenerationNotAvailable();
error KeeperAlreadyRegistered();
error NoLockedActionPending();
error LockedActionNotClaimableYet(uint256 targetEpoch, uint256 currentEpoch);
error LockedActionAlreadyClaimable();
error LockedActionTypeInvalid(); // For cancellation penalty logic, etc.
error AmountMustBePositive();
error AddressCannotBeZero();
error LockedActionTargetEpochInvalid(); // Must be future epoch

// --- Events ---
event EpochAdvanced(uint256 indexed epochNumber, uint256 startTime, EpochState newState, address indexed triggeredBy, uint256 rewardPaid);
event EpochStateChanged(uint256 indexed epochNumber, EpochState indexed oldState, EpochState indexed newState);
event EssenceGenerated(address indexed keeper, uint256 indexed epoch, uint256 amount);
event EssenceConsumed(address indexed keeper, uint256 indexed epoch, uint256 amount, string action);
event EssenceDistributed(address indexed admin, address indexed recipient, uint256 amount);
event EssenceBurned(address indexed keeper, uint256 indexed epoch, uint256 amount);
event LockedActionSet(address indexed keeper, uint256 indexed currentEpoch, uint256 targetEpoch, uint256 amount, uint8 actionType);
event LockedActionClaimed(address indexed keeper, uint256 indexed claimedEpoch, uint256 amount, uint8 actionType);
event LockedActionCancelled(address indexed keeper, uint256 indexed cancelledEpoch, uint256 amount, uint8 actionType, uint256 penalty);
event KeeperRegistered(address indexed newKeeper);
event InteractionPerformed(address indexed keeper, uint256 indexed epoch, uint256 essenceSpent);
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

// --- Enums ---
enum EpochState {
    Dormant,      // Passive state, minimal interaction
    Flourishing,  // High essence generation, lower interaction cost
    Turbulent,    // Low essence generation, higher interaction cost, maybe unique actions
    Mystic        // Special state, perhaps enabling locked actions, or higher rewards
}

// --- Structs ---
struct LockedAction {
    uint256 targetEpoch; // The epoch number when the action becomes available
    uint256 amount;      // Essence amount or parameter related to the action
    uint8 actionType;    // Identifier for the type of action (e.g., 1 for essence unlock, 2 for special claim)
    bool isActive;       // True if there is a pending locked action
}

// --- Contract ---
contract EtherealEpochs {
    address private _owner;

    // Epoch State
    uint256 public currentEpoch;
    uint256 public currentEpochStartTime;
    uint256 public epochDuration; // in seconds
    EpochState public currentEpochState;

    // Essence Management (Internal Mapping)
    mapping(address => uint256) private _userEssence;

    // Keeper Registration
    mapping(address => bool) private _isKeeper;
    uint256 private _keeperCount;

    // User Locked Actions (Only one pending action per keeper for simplicity)
    mapping(address => LockedAction) private _lockedActions;

    // Configuration Parameters
    uint256 public interactionCost; // Essence cost for performEpochInteraction
    uint256 public essenceGenerationRate; // Base amount of essence generated
    uint256 public epochAdvancementReward; // ETH reward for triggering epoch advance

    // Epoch State Availability Configuration
    mapping(EpochState => bool) public epochInteractionAvailability;
    mapping(EpochState => bool) public essenceGenerationAvailability;

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert NotOwner();
        }
        _;
    }

    modifier onlyKeeper() {
        if (!_isKeeper[msg.sender]) {
            revert NotKeeper();
        }
        _;
    }

    modifier epochReadyToAdvance() {
        if (block.timestamp < currentEpochStartTime + epochDuration) {
            revert EpochNotReadyToAdvance();
        }
        _;
    }

    modifier actionLocked() {
        if (!_lockedActions[msg.sender].isActive) {
            revert NoLockedActionPending();
        }
        _;
    }

     modifier actionClaimable() {
        LockedAction memory locked = _lockedActions[msg.sender];
        if (!locked.isActive) {
             revert NoLockedActionPending();
        }
        if (currentEpoch < locked.targetEpoch) {
            revert LockedActionNotClaimableYet(locked.targetEpoch, currentEpoch);
        }
        _;
    }

    modifier epochInteractionAvailable() {
        if (!epochInteractionAvailability[currentEpochState]) {
            revert InteractionNotAvailable();
        }
        _;
    }

    modifier essenceGenerationAvailable() {
        if (!essenceGenerationAvailability[currentEpochState]) {
            revert EssenceGenerationNotAvailable();
        }
        _;
    }

    // --- Constructor ---
    constructor(uint256 _initialEpochDuration, uint256 _initialInteractionCost, uint256 _initialEssenceGenerationRate, uint256 _initialEpochAdvancementReward) {
        if (_initialEpochDuration == 0) revert EpochDurationTooShort();
        if (_initialInteractionCost == 0) revert AmountMustBePositive();
        if (_initialEssenceGenerationRate == 0) revert AmountMustBePositive();
        // _initialEpochAdvancementReward can be 0

        _owner = msg.sender;
        currentEpoch = 1;
        currentEpochStartTime = block.timestamp;
        epochDuration = _initialEpochDuration;
        currentEpochState = EpochState.Dormant; // Start in Dormant state

        interactionCost = _initialInteractionCost;
        essenceGenerationRate = _initialEssenceGenerationRate;
        epochAdvancementReward = _initialEpochAdvancementReward;

        // Default availability: allow interaction and generation in Flourishing and Mystic states
        epochInteractionAvailability[EpochState.Dormant] = false;
        epochInteractionAvailability[EpochState.Flourishing] = true;
        epochInteractionAvailability[EpochState.Turbulent] = false;
        epochInteractionAvailability[EpochState.Mystic] = true;

        essenceGenerationAvailability[EpochState.Dormant] = false;
        essenceGenerationAvailability[EpochState.Flourishing] = true;
        essenceGenerationAvailability[EpochState.Turbulent] = false;
        essenceGenerationAvailability[EpochState.Mystic] = true;
    }

    // --- Epoch Management ---

    /// @notice Allows anyone to check if the epoch time has passed and trigger advancement.
    /// @dev Sends a small ETH reward to the caller if advancement occurs.
    /// @return bool True if the epoch was advanced.
    function triggerEpochTransitionCheck() external payable epochReadyToAdvance returns (bool) {
         _advanceEpoch(msg.sender);
         return true;
    }

    /// @dev Internal function to handle the actual epoch advancement logic.
    /// @param _triggeredBy The address that triggered the advancement.
    function _advanceEpoch(address _triggeredBy) private {
        // Re-check timestamp inside internal function for safety
        require(block.timestamp >= currentEpochStartTime + epochDuration, "Epoch not yet ready for internal advance");

        uint256 oldEpoch = currentEpoch;
        EpochState oldState = currentEpochState;

        currentEpoch++;
        currentEpochStartTime = block.timestamp;

        // Simple state transition logic: cycle through states
        // Can be made more complex (e.g., based on contract activity, randomness, owner input)
        currentEpochState = EpochState((uint8(currentEpochState) + 1) % 4); // Cycles through 0, 1, 2, 3

        emit EpochAdvanced(currentEpoch, currentEpochStartTime, currentEpochState, _triggeredBy, epochAdvancementReward);
        if (oldState != currentEpochState) {
             emit EpochStateChanged(currentEpoch, oldState, currentEpochState);
        }

        // Pay reward to the triggerer
        if (epochAdvancementReward > 0 && address(this).balance >= epochAdvancementReward) {
             payable(_triggeredBy).transfer(epochAdvancementReward);
        }
    }

    /// @notice Returns the current epoch number.
    /// @return uint256 The current epoch.
    function getCurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }

    /// @notice Returns the timestamp when the current epoch began.
    /// @return uint256 The start timestamp.
    function getEpochStartTime() external view returns (uint256) {
        return currentEpochStartTime;
    }

    /// @notice Returns the configured duration of each epoch in seconds.
    /// @return uint256 The epoch duration.
    function getEpochDuration() external view returns (uint256) {
        return epochDuration;
    }

    /// @notice Calculates and returns the timestamp when the next epoch transition becomes possible.
    /// @return uint256 The timestamp threshold for the next epoch.
    function getEpochTransitionThreshold() external view returns (uint256) {
        return currentEpochStartTime + epochDuration;
    }

     /// @notice Returns the current state or mood of the epoch.
    /// @return EpochState The current state.
    function getCurrentEpochState() external view returns (EpochState) {
        return currentEpochState;
    }

    /// @notice Allows the owner to set the duration of future epochs.
    /// @param _newDuration The new epoch duration in seconds. Must be greater than 0.
    function setEpochDuration(uint256 _newDuration) external onlyOwner {
        if (_newDuration == 0) revert EpochDurationTooShort();
        epochDuration = _newDuration;
    }

     /// @notice Allows the owner to manually set the current epoch state.
     /// @dev Use with caution as this overrides the automatic cycle.
     /// @param _newState The state to transition to.
    function forceEpochStateTransition(EpochState _newState) external onlyOwner {
        EpochState oldState = currentEpochState;
        if (oldState != _newState) {
            currentEpochState = _newState;
            emit EpochStateChanged(currentEpoch, oldState, currentEpochState);
        }
    }

    /// @notice Checks if the basic epoch interaction (`performEpochInteraction`) is allowed in the current state.
    /// @return bool True if interaction is available.
    function getEpochInteractionAvailability() external view returns (bool) {
        return epochInteractionAvailability[currentEpochState];
    }

    /// @notice Checks if essence generation (`generateEssence`) is allowed in the current state.
    /// @return bool True if generation is available.
    function getEssenceGenerationAvailability() external view returns (bool) {
        return essenceGenerationAvailability[currentEpochState];
    }

    /// @notice Owner sets which states allow the basic epoch interaction.
    /// @param _state The epoch state being configured.
    /// @param _available Whether interaction is allowed in this state.
    function setInteractionAvailability(EpochState _state, bool _available) external onlyOwner {
        epochInteractionAvailability[_state] = _available;
    }

    /// @notice Owner sets which states allow essence generation.
    /// @param _state The epoch state being configured.
    /// @param _available Whether generation is allowed in this state.
    function setEssenceGenerationAvailability(EpochState _state, bool _available) external onlyOwner {
        essenceGenerationAvailability[_state] = _available;
    }


    // --- Essence Management ---

    /// @notice Returns the EpochalEssence balance for a given address.
    /// @param _address The address to query.
    /// @return uint256 The essence balance.
    function getUserEssence(address _address) external view returns (uint256) {
        return _userEssence[_address];
    }

    /// @notice Allows a registered Keeper to generate EpochalEssence.
    /// @dev Availability is controlled by the current epoch state.
    function generateEssence() external onlyKeeper essenceGenerationAvailable {
        uint256 generated = essenceGenerationRate; // Simple rate, could add complexity based on epoch, user state, etc.
        _userEssence[msg.sender] += generated;
        emit EssenceGenerated(msg.sender, currentEpoch, generated);
    }

    /// @dev Internal function to consume (deduct) essence from a user.
    /// @param _user The address of the user.
    /// @param _amount The amount of essence to consume.
    /// @param _action A string describing the action causing consumption.
    function consumeEssence(address _user, uint256 _amount, string memory _action) private {
        if (_userEssence[_user] < _amount) {
             revert InsufficientEssence(_amount, _userEssence[_user]);
        }
        _userEssence[_user] -= _amount;
        emit EssenceConsumed(_user, currentEpoch, _amount, _action);
    }

    /// @notice Allows the owner to distribute essence to an address.
    /// @param _recipient The address to receive essence.
    /// @param _amount The amount of essence to distribute.
    function distributeEssence(address _recipient, uint256 _amount) external onlyOwner {
        if (_recipient == address(0)) revert AddressCannotBeZero();
        if (_amount == 0) revert AmountMustBePositive();
        _userEssence[_recipient] += _amount;
        emit EssenceDistributed(msg.sender, _recipient, _amount);
    }

    /// @notice Allows a Keeper to burn their own essence.
    /// @param _amount The amount of essence to burn.
    function burnEssence(uint256 _amount) external onlyKeeper {
         if (_amount == 0) revert AmountMustBePositive();
         consumeEssence(msg.sender, _amount, "Burn");
         emit EssenceBurned(msg.sender, currentEpoch, _amount);
    }

    /// @notice Allows the owner to distribute essence to multiple addresses in a batch.
    /// @param _recipients Array of addresses to receive essence.
    /// @param _amounts Array of amounts corresponding to recipients. Must be same length.
    function batchDistributeEssence(address[] calldata _recipients, uint256[] calldata _amounts) external onlyOwner {
        if (_recipients.length != _amounts.length) revert("Recipient and amount arrays must match length");
        for (uint i = 0; i < _recipients.length; i++) {
            if (_recipients[i] == address(0)) revert AddressCannotBeZero();
            if (_amounts[i] == 0) revert AmountMustBePositive(); // Or allow 0 amounts? Let's require positive.
            _userEssence[_recipients[i]] += _amounts[i];
            emit EssenceDistributed(msg.sender, _recipients[i], _amounts[i]);
        }
    }

    /// @notice Owner sets the base rate for essence generation.
    /// @param _rate The new generation rate. Must be positive.
    function setEssenceGenerationRate(uint256 _rate) external onlyOwner {
        if (_rate == 0) revert AmountMustBePositive();
        essenceGenerationRate = _rate;
    }

    /// @notice Returns the current configured essence generation rate.
    /// @return uint256 The generation rate.
    function getEssenceGenerationRate() external view returns (uint256) {
        return essenceGenerationRate;
    }

    /// @notice Pure function to calculate potential essence generation based on the current rate.
    /// @dev Does not check availability or user state.
    /// @return uint256 The calculated generation amount.
    function queryEssenceGenerationAmount() external pure returns (uint256) {
        // In a real scenario, this might take parameters or interact with state.
        // Keeping it simple as pure requires no state interaction.
        // If it depended on state vars, it would be `view`.
        return 100; // Example fixed calculation for pure, replace with actual logic if state-dependent
    }

    // --- Keeper & Interaction ---

    /// @notice Allows any address to register as a Keeper.
    function registerKeeper() external {
        if (_isKeeper[msg.sender]) {
             revert KeeperAlreadyRegistered();
        }
        _isKeeper[msg.sender] = true;
        _keeperCount++;
        emit KeeperRegistered(msg.sender);
    }

    /// @notice Checks if an address is a registered Keeper.
    /// @param _address The address to check.
    /// @return bool True if the address is a Keeper.
    function isKeeper(address _address) external view returns (bool) {
        return _isKeeper[_address];
    }

    /// @notice Returns the total number of registered Keepers.
    /// @return uint256 The keeper count.
    function getKeeperCount() external view returns (uint256) {
        return _keeperCount;
    }

    /// @notice Allows a Keeper to perform the main interaction action.
    /// @dev Costs essence and is only available during certain epoch states.
    function performEpochInteraction() external onlyKeeper epochInteractionAvailable {
        consumeEssence(msg.sender, interactionCost, "Epoch Interaction");
        // Implement what the interaction *does* here
        // e.g., influences future epoch states, provides a small non-essence reward, updates user state
        emit InteractionPerformed(msg.sender, currentEpoch, interactionCost);
    }

    /// @notice Returns the current configured essence cost for `performEpochInteraction`.
    /// @return uint256 The interaction cost.
    function getInteractionCost() external view returns (uint256) {
        return interactionCost;
    }

    /// @notice Owner sets the essence cost for `performEpochInteraction`.
    /// @param _cost The new interaction cost. Must be positive.
    function setInteractionCost(uint256 _cost) external onlyOwner {
        if (_cost == 0) revert AmountMustBePositive();
        interactionCost = _cost;
    }

    // --- Time-Locked Actions ---

    /// @notice Allows a Keeper to set a time-locked action that unlocks in a future epoch.
    /// @dev A user can only have one locked action pending at a time.
    /// @param _targetEpoch The epoch number when the action will unlock. Must be greater than the current epoch.
    /// @param _amount The amount or parameter associated with the action.
    /// @param _actionType Identifier for the type of locked action.
    function setTimeLockedAction(uint256 _targetEpoch, uint256 _amount, uint8 _actionType) external onlyKeeper {
        if (_lockedActions[msg.sender].isActive) {
             revert actionLocked(); // User already has a pending action
        }
        if (_targetEpoch <= currentEpoch) {
            revert LockedActionTargetEpochInvalid();
        }
         if (_amount == 0 && _actionType == 0) revert AmountMustBePositive(); // Require some value/type for the action

        // Example: If actionType implies locking essence, consume it here
        // if (_actionType == 1 && _amount > 0) {
        //     consumeEssence(msg.sender, _amount, "Locking Essence");
        // }
        // For this example, we just record the parameters. The 'amount' and 'actionType'
        // are interpreted when claiming.

        _lockedActions[msg.sender] = LockedAction({
            targetEpoch: _targetEpoch,
            amount: _amount,
            actionType: _actionType,
            isActive: true
        });

        emit LockedActionSet(msg.sender, currentEpoch, _targetEpoch, _amount, _actionType);
    }

    /// @notice Allows a Keeper to claim their time-locked action once the target epoch is reached.
    function claimLockedAction() external onlyKeeper actionClaimable {
        LockedAction memory locked = _lockedActions[msg.sender];

        // Interpret and execute the locked action based on actionType and amount
        // Example logic:
        // if (locked.actionType == 1) {
        //    // Unlock essence (add back to user balance)
        //    _userEssence[msg.sender] += locked.amount;
        // } else if (locked.actionType == 2) {
        //    // Grant a special bonus or ability (simplified here as just an event)
        //    // based on locked.amount
        //    // emit SpecialBonusClaimed(msg.sender, locked.amount);
        // } else {
        //    revert LockedActionTypeInvalid(); // Handle unknown action types
        // }

        // For this example, we'll simply mark it claimed and emit event
        delete _lockedActions[msg.sender]; // Mark action as inactive/claimed by deleting
        emit LockedActionClaimed(msg.sender, currentEpoch, locked.amount, locked.actionType);
    }

    /// @notice Allows a Keeper to cancel a pending time-locked action before the target epoch.
    /// @dev May incur a penalty (e.g., burning a portion of the locked amount).
    function cancelLockedAction() external onlyKeeper actionLocked {
        LockedAction memory locked = _lockedActions[msg.sender];

        // Check if already claimable - cannot cancel once claimable
        if (currentEpoch >= locked.targetEpoch) {
            revert LockedActionAlreadyClaimable();
        }

        uint256 penalty = 0;
        // Example penalty logic:
        // if (locked.actionType == 1 && locked.amount > 0) {
        //    // If essence was locked, burn a percentage as penalty
        //    penalty = locked.amount / 10; // 10% penalty example
        //    if (_userEssence[msg.sender] < penalty) {
        //         // If user doesn't have enough essence for penalty, burn what they have
        //         penalty = _userEssence[msg.sender];
        //    }
        //    consumeEssence(msg.sender, penalty, "Locked Action Cancel Penalty");
        //    // Refund remaining locked amount if essence was consumed when locking
        //    // uint256 refund = locked.amount - penalty;
        //    // _userEssence[msg.sender] += refund; // This logic depends on setTimeLockedAction
        // } else {
        //     // No essence locked or action type doesn't have essence penalty
        //     penalty = 0;
        // }

        // For this example, no penalty, just cancellation. Add penalty logic if needed.
        delete _lockedActions[msg.sender]; // Mark action as inactive by deleting
        emit LockedActionCancelled(msg.sender, currentEpoch, locked.amount, locked.actionType, penalty);
    }

    /// @notice Returns the details of a user's pending time-locked action.
    /// @param _address The address to query.
    /// @return uint256 targetEpoch, uint256 amount, uint8 actionType, bool isActive
    function getUserLockedAction(address _address) external view returns (uint256 targetEpoch, uint256 amount, uint8 actionType, bool isActive) {
        LockedAction memory locked = _lockedActions[_address];
        return (locked.targetEpoch, locked.amount, locked.actionType, locked.isActive);
    }

    // --- Ownership & Configuration ---

    /// @notice Returns the address of the current owner.
    function owner() public view returns (address) {
        return _owner;
    }

    /// @notice Transfers ownership of the contract to a new account.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert AddressCannotBeZero();
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /// @notice Renounces the ownership of the contract.
    /// @dev The renounce operation will leave the contract without an owner, thereby removing any functionality that is only available to the owner.
    function renounceOwnership() external onlyOwner {
        address oldOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }

     /// @notice Returns the amount of ETH rewarded for triggering epoch advancement.
     /// @return uint256 The ETH reward amount in wei.
    function getEpochAdvancementReward() external view returns (uint256) {
        return epochAdvancementReward;
    }

    /// @notice Owner sets the amount of ETH rewarded for triggering epoch advancement.
    /// @param _reward The new reward amount in wei. Can be 0.
    function setEpochAdvancementReward(uint256 _reward) external onlyOwner {
        epochAdvancementReward = _reward;
    }

    /// @dev Receive function to allow the contract to receive ETH for the epoch advancement reward pool.
    receive() external payable {}
    /// @dev Fallback function (optional, could revert if unexpected calls happen).
    fallback() external payable {
        revert("Unexpected call or ETH deposit");
    }
}
```