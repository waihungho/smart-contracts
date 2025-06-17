Okay, let's design a smart contract that manages unique digital assets with dynamic attributes (like 'Potential' and 'Alignment') that change over time and based on interaction, incorporating features like conditional triggers, scheduled actions, and delegation.

This contract, let's call it `QuantumFlow`, will manage `QuantumUnit` tokens. These units are non-fungible, but unlike standard NFTs, their intrinsic value or utility ('Potential') accrues over time or under certain conditions, and they can enter different states ('Alignment') which affect their behavior.

**Core Concept:** Users own QuantumUnits. Each unit passively gains 'Potential' over time. Units can be 'Aligned' which might change the potential accrual rate or unlock specific actions. Potential can be 'Discharged' to trigger conditional 'QuantumEvents', or scheduled for future discharge. Owners can delegate discharge rights for their units.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumFlow
 * @dev A smart contract managing dynamic, stateful Non-Fungible Tokens (QuantumUnits)
 *      with features like time-based potential accrual, alignment states,
 *      conditional event triggers, scheduled actions, and delegation.
 *
 * Core Concept:
 * QuantumUnits are unique tokens (similar to NFTs) that possess 'Potential'.
 * Potential accrues passively over time for each unit.
 * Units can be in an 'Aligned' or 'Unaigned' state, affecting potential accrual and available actions.
 * Potential can be 'Discharged' to trigger 'QuantumEvents', subject to conditions (e.g., min potential, alignment state).
 * Future potential discharge can be scheduled.
 * Owners can delegate the right to discharge potential for their units.
 */

// --- OUTLINE ---
// 1. Ownership & Control (Manual Ownable & Pausable implementation)
// 2. Configuration Parameters (Potential rates, Alignment costs/requirements, Event conditions, Cooldowns)
// 3. Data Structures (QuantumUnitState, ScheduledDischarge, Parameters)
// 4. State Variables (Mappings for ownership, state, schedules, delegations, parameters)
// 5. Events (Signaling key state changes and actions)
// 6. Modifiers (Access control, state checks)
// 7. Internal Helpers (Potential calculation, state updates, ownership basics)
// 8. Core Token Management (Minting, Transferring, Burning - basic ERC721-like ownership)
// 9. Potential Mechanics (Calculating, Getting, Setting parameters)
// 10. Alignment Mechanics (Aligning, De-aligning, Setting parameters)
// 11. Discharge Mechanics (Discharging, Setting parameters)
// 12. Conditional Event Triggers (Triggering events based on state/potential)
// 13. Timed & Scheduled Actions (Scheduling, Cancelling, Executing future discharges)
// 14. Delegation (Delegating/Revoking discharge rights)
// 15. Utility & Query Functions (Getters for state, schedules, parameters, delegation)
// 16. Emergency Functions (Withdrawals)

// --- FUNCTION SUMMARY ---
// 1.  constructor() - Initializes the contract owner and default parameters.
// 2.  owner() view - Returns the current owner.
// 3.  transferOwnership(address newOwner) - Transfers ownership.
// 4.  pause() onlyOwner - Pauses the contract.
// 5.  unpause() onlyOwner - Unpauses the contract.
// 6.  paused() view - Returns the paused state.
// 7.  setPotentialParameters(uint256 baseAccrualRate, uint256 alignedBonusRate, uint256 dischargeRateMultiplier) onlyOwner - Sets potential calculation parameters.
// 8.  getPotentialParameters() view - Gets current potential parameters.
// 9.  setAlignmentParameters(uint256 cost, uint256 potentialRequirement) onlyOwner - Sets alignment cost and potential requirements.
// 10. getAlignmentParameters() view - Gets current alignment parameters.
// 11. setDealignmentCooldown(uint64 cooldownDuration) onlyOwner - Sets the cooldown duration after de-aligning.
// 12. getDealignmentCooldown() view - Gets the current de-alignment cooldown.
// 13. setEventTriggerConditions(uint256 minPotential, bool requiresAlignment) onlyOwner - Sets conditions for triggering a QuantumEvent.
// 14. getEventTriggerConditions() view - Gets current QuantumEvent trigger conditions.
// 15. withdrawEther(address payable to, uint256 amount) onlyOwner whenPaused - Allows owner to withdraw Ether, restricted when paused for safety.
// 16. mintUnit(address to) - Mints a new QuantumUnit token to an address.
// 17. transferUnit(address from, address to, uint256 unitId) - Transfers a QuantumUnit token.
// 18. burnUnit(uint256 unitId) - Burns a QuantumUnit token.
// 19. ownerOf(uint256 unitId) view - Returns the owner of a QuantumUnit token. (Basic ERC721-like)
// 20. getOwnedUnits(address account) view - Returns an array of unit IDs owned by an account.
// 21. calculateCurrentPotential(uint256 unitId) view - Calculates the theoretical potential of a unit *at this moment* without updating state.
// 22. getUnitPotential(uint256 unitId) - Gets the current potential of a unit, updating its state.
// 23. isUnitAligned(uint256 unitId) view - Checks if a unit is currently Aligned.
// 24. alignUnit(uint256 unitId) payable whenNotPaused - Aligns a unit, potentially costing Ether and requiring potential.
// 25. dealignUnit(uint256 unitId) whenNotPaused - De-aligns a unit, subject to a cooldown.
// 26. dischargePotential(uint256 unitId, uint256 amount) whenNotPaused - Discharges a specific amount of potential from a unit.
// 27. triggerQuantumEvent(uint256 unitId) whenNotPaused - Attempts to trigger a QuantumEvent using a unit's potential, subject to predefined conditions.
// 28. scheduleFutureDischarge(uint256 unitId, uint256 amount, uint64 executionTimestamp) whenNotPaused - Schedules a potential discharge for a future time.
// 29. cancelFutureDischarge(uint256 unitId) whenNotPaused - Cancels a pending scheduled discharge.
// 30. executeScheduledDischarge(uint256 unitId) whenNotPaused - Executes a scheduled discharge if the time has arrived.
// 31. getScheduledDischarge(uint256 unitId) view - Gets details of a unit's pending scheduled discharge.
// 32. delegateDischarge(uint256 unitId, address delegate) whenNotPaused - Delegates potential discharge rights for a unit.
// 33. revokeDischargeDelegation(uint256 unitId) whenNotPaused - Revokes potential discharge delegation for a unit.
// 34. getDischargeDelegate(uint256 unitId) view - Gets the current discharge delegate for a unit.
// 35. isDelegatedForDischarge(uint256 unitId, address account) view - Checks if an account is the delegate for a unit.

contract QuantumFlow {
    // --- State Variables ---

    address private _owner;
    bool private _paused;

    // ERC721-like minimal ownership tracking
    mapping(uint256 => address) private _owners;
    mapping(address => uint256[]) private _ownedUnits; // Store unit IDs owned by an address
    uint256 private _tokenCounter; // Simple counter for unique token IDs

    // Quantum Unit State
    struct QuantumUnitState {
        uint64 lastPotentialUpdateTime;
        uint256 potential; // Stored potential (integer, use scaling if needed for fractional)
        bool isAligned;
        uint64 alignmentTime; // Timestamp when alignment state last changed
        uint64 dealignmentCooldownEnd; // Timestamp when dealignment cooldown ends
    }
    mapping(uint256 => QuantumUnitState) private _unitStates;

    // Scheduled Discharges
    struct ScheduledDischarge {
        uint256 amount;
        uint64 executionTimestamp;
        address requester; // Address that scheduled it
        bool exists; // To check if a schedule exists for a unit
    }
    mapping(uint256 => ScheduledDischarge) private _scheduledDischarges;

    // Delegation Mapping: unitId -> delegate address
    mapping(uint256 => address) private _dischargeDelegates;

    // Parameters
    struct PotentialParameters {
        uint256 baseAccrualRate; // Potential units per second for unaligned
        uint256 alignedBonusRate; // Additional potential units per second for aligned
        uint256 dischargeRateMultiplier; // Multiplier when calculating potential cost (e.g., 1000 for 100% cost)
    }
    PotentialParameters public potentialParams;

    struct AlignmentParameters {
        uint256 cost; // Cost in wei to align a unit
        uint256 potentialRequirement; // Minimum potential required to align
    }
    AlignmentParameters public alignmentParams;

    uint64 public dealignmentCooldownDuration; // Duration in seconds

    struct EventTriggerConditions {
        uint256 minPotential;
        bool requiresAlignment;
    }
    EventTriggerConditions public eventTriggerConditions;

    // --- Events ---

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);

    event UnitMinted(address indexed to, uint256 indexed unitId);
    event UnitTransferred(address indexed from, address indexed to, uint256 indexed unitId);
    event UnitBurned(uint256 indexed unitId);

    event PotentialParametersUpdated(uint256 baseRate, uint256 alignedBonus, uint256 dischargeMultiplier);
    event AlignmentParametersUpdated(uint256 cost, uint256 potentialReq);
    event DealignmentCooldownUpdated(uint64 duration);
    event EventTriggerConditionsUpdated(uint256 minPotential, bool requiresAlignment);

    event UnitPotentialUpdated(uint256 indexed unitId, uint256 newPotential, uint64 updateTime);
    event PotentialDischarged(uint256 indexed unitId, address indexed discharger, uint256 amount);

    event UnitAligned(uint256 indexed unitId, address indexed account, uint64 alignmentTime);
    event UnitDealigend(uint256 indexed unitId, address indexed account, uint64 dealignmentTime);

    event QuantumEventTriggered(uint256 indexed unitId, address indexed triggerer, uint256 potentialUsed);

    event FutureDischargeScheduled(uint256 indexed unitId, address indexed requester, uint256 amount, uint64 executionTimestamp);
    event FutureDischargeCancelled(uint256 indexed unitId, address indexed canceller);
    event FutureDischargeExecuted(uint256 indexed unitId, address indexed executor, uint256 amount);

    event DischargeDelegated(uint256 indexed unitId, address indexed delegator, address indexed delegate);
    event DischargeDelegationRevoked(uint256 indexed unitId, address indexed delegator, address indexed revokedDelegate);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this");
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

    modifier unitExists(uint256 unitId) {
        require(_exists(unitId), "Unit does not exist");
        _;
    }

    // --- Constructor ---

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);

        // Set initial default parameters (can be updated by owner)
        potentialParams = PotentialParameters({
            baseAccrualRate: 1 ether / 1 days, // 1 Ether worth of potential per day (example scaling)
            alignedBonusRate: 0.5 ether / 1 days, // 0.5 Ether bonus per day when aligned
            dischargeRateMultiplier: 1 // 100% cost multiplier by default
        });
        alignmentParams = AlignmentParameters({
            cost: 0.01 ether, // 0.01 Ether to align
            potentialRequirement: 0 // No potential needed initially
        });
        dealignmentCooldownDuration = 7 days; // 7 days cooldown
        eventTriggerConditions = EventTriggerConditions({
            minPotential: 1 ether, // Need 1 Ether worth of potential to trigger
            requiresAlignment: true // Must be aligned to trigger
        });
    }

    // --- Internal Helpers ---

    function _exists(uint256 unitId) internal view returns (bool) {
        return _owners[unitId] != address(0);
    }

    // Helper to add unitId to ownedUnits array
    function _addUnitToOwnerList(address to, uint256 unitId) internal {
        _ownedUnits[to].push(unitId);
    }

     // Helper to remove unitId from ownedUnits array (simple linear scan - inefficient for many units per owner)
    function _removeUnitFromOwnerList(address from, uint256 unitId) internal {
        uint256 len = _ownedUnits[from].length;
        for (uint i = 0; i < len; i++) {
            if (_ownedUnits[from][i] == unitId) {
                // Replace with last element and pop
                _ownedUnits[from][i] = _ownedUnits[from][len - 1];
                _ownedUnits[from].pop();
                break;
            }
        }
    }

    // Calculates how much potential has accrued since the last update
    function _calculatePotentialAccrued(uint256 unitId) internal view returns (uint256) {
        QuantumUnitState storage unit = _unitStates[unitId];
        uint64 timeElapsed = uint64(block.timestamp) - unit.lastPotentialUpdateTime;

        uint256 accrualRate = potentialParams.baseAccrualRate;
        if (unit.isAligned) {
            accrualRate += potentialParams.alignedBonusRate;
        }

        return accrualRate * timeElapsed;
    }

    // Updates the potential and last update time for a unit
    function _updateUnitPotentialState(uint256 unitId) internal {
        QuantumUnitState storage unit = _unitStates[unitId];
        uint256 accrued = _calculatePotentialAccrued(unitId);
        unit.potential += accrued;
        unit.lastPotentialUpdateTime = uint64(block.timestamp);
        emit UnitPotentialUpdated(unitId, unit.potential, unit.lastPotentialUpdateTime);
    }

    // --- Ownership & Control Functions ---

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function pause() public onlyOwner {
        require(!_paused, "Already paused");
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner {
        require(_paused, "Not paused");
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    // --- Configuration Functions ---

    function setPotentialParameters(uint256 baseAccrualRate, uint256 alignedBonusRate, uint256 dischargeRateMultiplier) public onlyOwner {
        potentialParams = PotentialParameters({
            baseAccrualRate: baseAccrualRate,
            alignedBonusRate: alignedBonusRate,
            dischargeRateMultiplier: dischargeRateMultiplier
        });
        emit PotentialParametersUpdated(baseAccrualRate, alignedBonusRate, dischargeRateMultiplier);
    }

    function getPotentialParameters() public view returns (uint256, uint256, uint256) {
        return (potentialParams.baseAccrualRate, potentialParams.alignedBonusRate, potentialParams.dischargeRateMultiplier);
    }

    function setAlignmentParameters(uint256 cost, uint256 potentialRequirement) public onlyOwner {
        alignmentParams = AlignmentParameters({
            cost: cost,
            potentialRequirement: potentialRequirement
        });
        emit AlignmentParametersUpdated(cost, potentialRequirement);
    }

    function getAlignmentParameters() public view returns (uint256, uint256) {
        return (alignmentParams.cost, alignmentParams.potentialRequirement);
    }

    function setDealignmentCooldown(uint64 cooldownDuration) public onlyOwner {
        dealignmentCooldownDuration = cooldownDuration;
        emit DealignmentCooldownUpdated(cooldownDuration);
    }

    function getDealignmentCooldown() public view returns (uint64) {
        return dealignmentCooldownDuration;
    }

    function setEventTriggerConditions(uint256 minPotential, bool requiresAlignment) public onlyOwner {
        eventTriggerConditions = EventTriggerConditions({
            minPotential: minPotential,
            requiresAlignment: requiresAlignment
        });
        emit EventTriggerConditionsUpdated(minPotential, requiresAlignment);
    }

    function getEventTriggerConditions() public view returns (uint256, bool) {
        return (eventTriggerConditions.minPotential, eventTriggerConditions.requiresAlignment);
    }

    function withdrawEther(address payable to, uint256 amount) public onlyOwner whenPaused {
         require(amount <= address(this).balance, "Insufficient contract balance");
         (bool success, ) = to.call{value: amount}("");
         require(success, "Ether withdrawal failed");
    }

    // --- Core Token Management (Basic) ---

    function mintUnit(address to) public onlyOwner returns (uint256) {
        uint256 newTokenId = _tokenCounter;
        _tokenCounter++;

        _owners[newTokenId] = to;
        _addUnitToOwnerList(to, newTokenId);

        _unitStates[newTokenId] = QuantumUnitState({
            lastPotentialUpdateTime: uint64(block.timestamp),
            potential: 0,
            isAligned: false,
            alignmentTime: uint64(block.timestamp), // Initialize alignment time
            dealignmentCooldownEnd: 0 // No cooldown initially
        });

        emit UnitMinted(to, newTokenId);
        return newTokenId;
    }

    // Note: This is a simplified transfer, without ERC721 approve/transferFrom logic
    function transferUnit(address from, address to, uint256 unitId) public whenNotPaused unitExists(unitId) {
        require(_owners[unitId] == from, "Caller is not owner or From is incorrect");
        require(msg.sender == from || msg.sender == _owner, "Not authorized to transfer");
        require(to != address(0), "Transfer to zero address");

        // Update potential before transfer
        _updateUnitPotentialState(unitId);

        _removeUnitFromOwnerList(from, unitId);
        _owners[unitId] = to;
        _addUnitToOwnerList(to, unitId);

        // Clear delegation on transfer
        delete _dischargeDelegates[unitId];

        emit UnitTransferred(from, to, unitId);
    }

    function burnUnit(uint256 unitId) public whenNotPaused unitExists(unitId) {
        address owner = _owners[unitId];
        require(msg.sender == owner || msg.sender == _owner, "Not authorized to burn");

        // Update potential one last time? Or discard? Let's discard.
        // _updateUnitPotentialState(unitId); // Optional: finalize potential

        _removeUnitFromOwnerList(owner, unitId);
        delete _owners[unitId];
        delete _unitStates[unitId];
        delete _scheduledDischarges[unitId]; // Remove any pending schedules
        delete _dischargeDelegates[unitId]; // Remove any delegation

        emit UnitBurned(unitId);
    }

    function ownerOf(uint256 unitId) public view unitExists(unitId) returns (address) {
        return _owners[unitId];
    }

    function getOwnedUnits(address account) public view returns (uint256[] memory) {
         return _ownedUnits[account];
    }

    // --- Potential Mechanics ---

     // View function to see potential *right now* without state change
    function calculateCurrentPotential(uint256 unitId) public view unitExists(unitId) returns (uint256) {
        QuantumUnitState storage unit = _unitStates[unitId];
        uint256 accrued = _calculatePotentialAccrued(unitId);
        return unit.potential + accrued;
    }

    // Public function to get potential, updates state
    function getUnitPotential(uint256 unitId) public unitExists(unitId) returns (uint256) {
        _updateUnitPotentialState(unitId);
        return _unitStates[unitId].potential;
    }

    // Internal function to handle potential discharge after state update
    function _dischargePotential(uint256 unitId, uint256 amount, address discharger) internal {
        require(amount > 0, "Discharge amount must be positive");
        QuantumUnitState storage unit = _unitStates[unitId];

        // Ensure state is updated before discharging
        _updateUnitPotentialState(unitId);

        uint256 actualCost = (amount * potentialParams.dischargeRateMultiplier) / 1; // Assuming multiplier is scaled, e.g., 1 is 100%
        // If multiplier is like 1000 for 100%, need different math: amount * multiplier / 1000; Let's assume 1 = 100%.

        require(unit.potential >= actualCost, "Insufficient potential");

        unit.potential -= actualCost;
        emit PotentialDischarged(unitId, discharger, actualCost);
    }

    // --- Alignment Mechanics ---

    function isUnitAligned(uint256 unitId) public view unitExists(unitId) returns (bool) {
        return _unitStates[unitId].isAligned;
    }

    function alignUnit(uint256 unitId) public payable whenNotPaused unitExists(unitId) {
        address owner = _owners[unitId];
        require(msg.sender == owner, "Only owner can align");
        require(!_unitStates[unitId].isAligned, "Unit is already aligned");

        // Update potential before checking requirement
        _updateUnitPotentialState(unitId);

        require(msg.value >= alignmentParams.cost, "Insufficient Ether for alignment cost");
        require(_unitStates[unitId].potential >= alignmentParams.potentialRequirement, "Insufficient potential for alignment");

        // Transfer cost to contract (handled by payable)

        QuantumUnitState storage unit = _unitStates[unitId];
        unit.isAligned = true;
        unit.alignmentTime = uint64(block.timestamp);

        emit UnitAligned(unitId, msg.sender, unit.alignmentTime);
    }

    function dealignUnit(uint256 unitId) public whenNotPaused unitExists(unitId) {
        address owner = _owners[unitId];
        require(msg.sender == owner, "Only owner can dealign");
        require(_unitStates[unitId].isAligned, "Unit is already unaligned");
        require(uint64(block.timestamp) >= _unitStates[unitId].dealignmentCooldownEnd, "Unit is in dealignment cooldown");

        QuantumUnitState storage unit = _unitStates[unitId];
        unit.isAligned = false;
        unit.alignmentTime = uint66(block.timestamp); // Update state change time
        unit.dealignmentCooldownEnd = uint64(block.timestamp) + dealignmentCooldownDuration;

        emit UnitDealigend(unitId, msg.sender, unit.alignmentTime);
    }

    // --- Discharge & Event Mechanics ---

     // Directly discharge potential without triggering an event
    function dischargePotential(uint256 unitId, uint256 amount) public whenNotPaused unitExists(unitId) {
        address owner = _owners[unitId];
        address delegate = _dischargeDelegates[unitId];
        require(msg.sender == owner || msg.sender == delegate, "Not authorized to discharge potential");

        _dischargePotential(unitId, amount, msg.sender);
         // Note: This function emits PotentialDischarged. QuantumEventTriggered is separate.
    }


    function triggerQuantumEvent(uint256 unitId) public whenNotPaused unitExists(unitId) {
        address owner = _owners[unitId];
        address delegate = _dischargeDelegates[unitId];
        require(msg.sender == owner || msg.sender == delegate, "Not authorized to trigger event");

        // Update potential state first
        _updateUnitPotentialState(unitId);
        QuantumUnitState storage unit = _unitStates[unitId];

        // Check event trigger conditions
        require(unit.potential >= eventTriggerConditions.minPotential, "Insufficient potential to trigger event");
        if (eventTriggerConditions.requiresAlignment) {
            require(unit.isAligned, "Unit must be aligned to trigger event");
        }

        // Discharge the required potential
        uint256 potentialUsed = eventTriggerConditions.minPotential; // Or could discharge more, or a variable amount
        _dischargePotential(unitId, potentialUsed, msg.sender);

        // Trigger the event
        emit QuantumEventTriggered(unitId, msg.sender, potentialUsed);

        // Note: The "event" here is just an emitted log. In a real system, this might call another contract,
        // grant a temporary buff, unlock a feature, etc., based on the potential cost.
    }

    // --- Timed & Scheduled Actions ---

    function scheduleFutureDischarge(uint256 unitId, uint256 amount, uint64 executionTimestamp) public whenNotPaused unitExists(unitId) {
        address owner = _owners[unitId];
        require(msg.sender == owner, "Only owner can schedule discharge");
        require(amount > 0, "Discharge amount must be positive");
        require(executionTimestamp > block.timestamp, "Execution time must be in the future");
        require(!_scheduledDischarges[unitId].exists, "A future discharge is already scheduled for this unit");

        // Update potential before scheduling to check if enough *will* be available?
        // Or just check *now*? Let's require enough potential *now* to reserve it.
        _updateUnitPotentialState(unitId);
        uint256 actualCost = (amount * potentialParams.dischargeRateMultiplier) / 1;
        require(_unitStates[unitId].potential >= actualCost, "Insufficient potential to schedule");

        // Reserve potential by discharging it immediately but marking for future execution
        _unitStates[unitId].potential -= actualCost; // Potential is removed now
        emit PotentialDischarged(unitId, msg.sender, actualCost); // Event emitted now for accounting

        _scheduledDischarges[unitId] = ScheduledDischarge({
            amount: amount, // Store original requested amount
            executionTimestamp: executionTimestamp,
            requester: msg.sender,
            exists: true
        });

        emit FutureDischargeScheduled(unitId, msg.sender, amount, executionTimestamp);
    }

    function cancelFutureDischarge(uint256 unitId) public whenNotPaused unitExists(unitId) {
        address owner = _owners[unitId];
        require(msg.sender == owner || msg.sender == _scheduledDischarges[unitId].requester, "Not authorized to cancel schedule");
        require(_scheduledDischarges[unitId].exists, "No future discharge scheduled for this unit");
        require(uint64(block.timestamp) < _scheduledDischarges[unitId].executionTimestamp, "Schedule execution time has already passed");

        // Return the reserved potential (adjusted by multiplier)
        uint256 refundedPotential = (_scheduledDischarges[unitId].amount * potentialParams.dischargeRateMultiplier) / 1;
        _unitStates[unitId].potential += refundedPotential;
        emit PotentialDischarged(unitId, msg.sender, refundedPotential); // Emit as a negative discharge / refund

        delete _scheduledDischarges[unitId];
        emit FutureDischargeCancelled(unitId, msg.sender);
    }

    function executeScheduledDischarge(uint256 unitId) public whenNotPaused unitExists(unitId) {
        require(_scheduledDischarges[unitId].exists, "No future discharge scheduled for this unit");
        require(uint64(block.timestamp) >= _scheduledDischarges[unitId].executionTimestamp, "Execution time has not yet arrived");

        ScheduledDischarge memory scheduled = _scheduledDischarges[unitId];

        // Potential was already discharged when scheduled, so this is just the execution trigger
        // Could add logic here if execution itself has effects separate from potential discharge.
        // For this example, the event is the primary effect.

        delete _scheduledDischarges[unitId]; // Remove the schedule

        emit FutureDischargeExecuted(unitId, msg.sender, scheduled.amount);

        // Optional: Trigger a specific event or effect tied to execution rather than discharge
        // e.g., emit ScheduledEventTriggered(unitId, msg.sender, scheduled.amount);
    }

    function getScheduledDischarge(uint256 unitId) public view unitExists(unitId) returns (uint256 amount, uint64 executionTimestamp, address requester, bool exists) {
        ScheduledDischarge memory scheduled = _scheduledDischarges[unitId];
        return (scheduled.amount, scheduled.executionTimestamp, scheduled.requester, scheduled.exists);
    }

    // --- Delegation ---

    function delegateDischarge(uint256 unitId, address delegate) public whenNotPaused unitExists(unitId) {
        address owner = _owners[unitId];
        require(msg.sender == owner, "Only owner can delegate discharge");
        require(delegate != address(0), "Delegate cannot be the zero address");
        require(delegate != owner, "Cannot delegate to self");

        _dischargeDelegates[unitId] = delegate;
        emit DischargeDelegated(unitId, owner, delegate);
    }

    function revokeDischargeDelegation(uint256 unitId) public whenNotPaused unitExists(unitId) {
        address owner = _owners[unitId];
        require(msg.sender == owner, "Only owner can revoke delegation");
        require(_dischargeDelegates[unitId] != address(0), "No delegation exists for this unit");

        address revokedDelegate = _dischargeDelegates[unitId];
        delete _dischargeDelegates[unitId];
        emit DischargeDelegationRevoked(unitId, owner, revokedDelegate);
    }

    function getDischargeDelegate(uint256 unitId) public view unitExists(unitId) returns (address) {
        return _dischargeDelegates[unitId];
    }

     function isDelegatedForDischarge(uint256 unitId, address account) public view unitExists(unitId) returns (bool) {
        return _dischargeDelegates[unitId] == account;
    }
}
```