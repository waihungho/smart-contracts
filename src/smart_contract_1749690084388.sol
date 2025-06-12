Okay, let's design a smart contract with a creative and advanced concept. We'll build a "Quantum State Foundry," a contract that manages unique digital assets (NFTs) whose properties and behavior change dynamically based on time, interaction, and simulated quantum states, powered by an internal resource economy.

This is not a simple ERC721 or ERC20 derivative. It defines a unique lifecycle and interaction model for its assets.

---

**Smart Contract: Quantum State Foundry**

This contract manages a collection of unique digital assets called "Quantum Cores". These Cores have dynamic properties that change over time and through specific interactions, influenced by a simulated "Quantum Resonance" and consuming an internal resource called "Aether". The contract includes mechanisms for forging Cores, harvesting Resonance into a fungible "Chronon" token, fusing Cores, stabilizing their state, and more.

**Outline:**

1.  **Contract Definition:** Basic structure, ownership.
2.  **Error Definitions:** Custom errors for clarity.
3.  **Events:** Signal key actions (Forge, Harvest, Fuse, Transfer, StateChange, etc.).
4.  **Enums:** Define possible states for Quantum Cores.
5.  **Structs:** Define the structure of a Quantum Core, including dynamic properties.
6.  **State Variables:**
    *   Ownership.
    *   Counters for Cores and Chronons.
    *   Mappings for Core data, ownership, approvals (ERC721-like internal).
    *   Mappings for Chronon and Aether balances (internal token logic).
    *   Global Aether pool balance.
    *   Contract parameters (decay rates, costs, conversion rates).
7.  **Internal Helpers:**
    *   `_updateCoreStateDynamics`: Calculates and updates core properties and state based on elapsed time and interactions.
    *   `_calculateCurrentResonanceYield`: Determines how much Chronon can be harvested.
    *   `_exists`: Checks if a Core ID is valid.
    *   `_isApprovedOrOwner`: Checks if an address is authorized for a Core.
    *   `_transferCore`: Internal logic for changing Core ownership.
    *   `_mintCore`: Internal logic for creating a new Core.
    *   `_burnCore`: Internal logic for destroying a Core.
    *   `_mintChronons`: Internal Chronon minting.
    *   `_burnChronons`: Internal Chronon burning.
    *   `_mintAether`: Internal Aether minting.
    *   `_burnAether`: Internal Aether burning.
    *   `_transferAether`: Internal Aether transfer.
8.  **Functions (Public/External):**
    *   Core Management & Interaction (10+ functions):
        *   `forgeQuantumCore`: Mint a new Core.
        *   `harvestResonance`: Convert Core's resonance accumulation into Chronons.
        *   `fuseQuantumCores`: Combine two Cores into a potentially more powerful one.
        *   `stabilizeCoreState`: Temporarily halt or slow down state change/decay.
        *   `catalyzeResonance`: Temporarily boost resonance accumulation rate.
        *   `transferCore`: Transfer Core ownership (ERC721-like).
        *   `approveCore`: ERC721-like approval.
        *   `setApprovalForAllCores`: ERC721-like operator approval.
        *   `shatterCore`: Destroy a Core for minimal return.
        *   `syncCoreState`: Force an immediate state recalculation (useful for reading current dynamic properties).
        *   `sleepCore`: Put core into a dormant state, pausing dynamics.
        *   `awakenCore`: Resume dynamics from a dormant state.
    *   Internal Economy (Chronon/Aether) (5+ functions):
        *   `crystallizeChrononsToAether`: Convert earned Chronons into usable Aether resource.
        *   `transferChronons`: Transfer Chronons between users.
        *   `transferAether`: Transfer Aether between users.
        *   `withdrawAetherFromPool`: Draw Aether from a global pool (if pool is separate from user balances). *Refined:* Aether is user-balanced; Crystallizing Chronons *mints* Aether for the user.
        *   `depositAetherToPool`: (Less likely in this model, maybe for admin/fees?) *Refined:* Not needed for this model.
    *   Query Functions (5+ functions):
        *   `getCoreDetails`: Retrieve all data for a specific Core.
        *   `getCoreState`: Get the current state enum of a Core.
        *   `getCoreProperties`: Get dynamic properties (Purity, Resonance, Charge) of a Core.
        *   `calculateProjectedResonanceYield`: Simulate yield without modifying state.
        *   `balanceOfCores`: Get number of Cores owned by an address (ERC721-like).
        *   `ownerOfCore`: Get owner of a Core (ERC721-like).
        *   `getApprovedCore`: Get approved address for a Core (ERC721-like).
        *   `isApprovedForAllCores`: Check operator approval (ERC721-like).
        *   `balanceOfChronons`: Get Chronon balance for an address.
        *   `balanceOfAether`: Get Aether balance for an address.
        *   `getTotalCores`: Get total number of Cores minted.
        *   `getTotalChrononSupply`: Get total Chronons minted.
        *   `getGlobalAetherSupply`: Get total Aether minted/in circulation.
    *   Admin/Parameter Functions (2+ functions):
        *   `setParameters`: Update contract parameters (decay rates, costs, etc.).
        *   `withdrawEthFees`: (If contract collected fees in ETH - not in this model, Chronon/Aether internal) *Refined:* Not needed.
        *   `transferOwnership`: Change contract owner.
        *   `renounceOwnership`: Renounce contract ownership.

This structure provides >20 functions, focusing on the dynamic asset state, internal resource management, and novel interactions beyond typical token standards.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Quantum State Foundry
/// @dev Manages dynamic Quantum Cores (NFTs) with properties that change based on time and interactions,
/// powered by an internal Chronon/Aether resource economy.

// Custom Errors
error QuantumStateFoundry__NotCoreOwner();
error QuantumStateFoundry__NotApprovedOrOwner();
error QuantumStateFoundry__CoreDoesNotExist();
error QuantumStateFoundry__InvalidAmount();
error QuantumStateFoundry__InsufficientFunds(uint256 required, uint256 available);
error QuantumStateFoundry__CoreNotInValidState();
error QuantumStateFoundry__FusionNotEligible();
error QuantumStateFoundry__CoreAlreadySleeping();
error QuantumStateFoundry__CoreNotSleeping();
error QuantumStateFoundry__InvalidParameterValue();
error QuantumStateFoundry__NotContractOwner();
error QuantumStateFoundry__CannotSelfApprove();


// Events
event CoreForged(uint256 indexed coreId, address indexed owner, uint256 initialPurity, uint256 initialResonance);
event ResonanceHarvested(uint256 indexed coreId, address indexed owner, uint256 chrononsMinted, uint256 remainingCharge);
event CoresFused(uint256 indexed coreId1, uint256 indexed coreId2, uint256 indexed newCoreId, address owner);
event CoreStateChanged(uint256 indexed coreId, CoreState newState, CoreState oldState);
event CoreTransfer(address indexed from, address indexed to, uint256 indexed coreId);
event Approval(address indexed owner, address indexed approved, uint256 indexed coreId);
event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
event CoreShattered(uint256 indexed coreId, address indexed owner, uint256 chrononsReturned);
event CoreStabilized(uint256 indexed coreId, uint256 duration);
event ResonanceCatalyzed(uint256 indexed coreId, uint256 duration);
event CoreSlept(uint256 indexed coreId);
event CoreAwakened(uint256 indexed coreId);
event ChrononsCrystallizedIntoAether(address indexed owner, uint256 chrononsBurned, uint256 aetherMinted);
event ChrononTransfer(address indexed from, address indexed to, uint256 amount);
event AetherTransfer(address indexed from, address indexed to, uint256 amount);
event ParametersUpdated(address indexed owner);


// Enums
enum CoreState {
    Nascent,    // Newly forged, rapid growth potential
    Harmonizing,// Maturing state, optimal resonance growth
    Stable,     // Peak state, slow decay, consistent charge
    Decaying,   // Resonance and purity decline
    Dormant     // Sleeping state, dynamics paused
}

// Structs
struct QuantumCore {
    uint256 id;
    CoreState state;
    uint256 purity;         // Affects decay resistance and max potential (0-10000)
    uint256 resonance;      // Affects charge accumulation rate (0-10000)
    uint256 temporalCharge; // Accumulates over time, harvestable into Chronons
    uint40 bornTimestamp;
    uint40 lastUpdatedTimestamp;
    uint40 timeFreezeUntil; // Dynamics paused until this timestamp
    uint40 resonanceBoostUntil; // Resonance calculation gets a boost until this timestamp
    // State for Dormant cores to resume dynamics accurately
    uint40 sleepTimestamp;
    uint256 purityAtSleep;
    uint256 resonanceAtSleep;
    uint256 temporalChargeAtSleep;
}

contract QuantumStateFoundry {

    // --- Ownership ---
    address private _owner;

    // --- Counters ---
    uint256 private _coreIds; // Starts at 1 for first core
    uint256 private _totalChrononsMinted;
    uint256 private _totalAetherMinted; // Total Aether in circulation


    // --- Mappings (Core Management - ERC721-like Internal) ---
    mapping(uint256 => QuantumCore) private _idToCore;
    mapping(uint256 => address) private _idToOwner;
    mapping(address => uint256) private _ownerCoreCount;
    mapping(uint256 => address) private _coreApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // --- Mappings (Internal Economy - Chronon/Aether) ---
    mapping(address => uint256) private _chrononBalances;
    mapping(address => uint256) private _aetherBalances;

    // --- Contract Parameters (Adjustable by Owner/Governance) ---
    uint256 public forgeAetherCostBase = 100 * 1e18; // Base Aether cost to forge (scaled)
    uint256 public forgePurityCostFactor = 100 * 1e18; // Additional Aether cost per point of desired purity
    uint256 public forgeResonanceCostFactor = 100 * 1e18; // Additional Aether cost per point of desired resonance

    uint256 public harvestChargeRateBase = 1; // Base charge per second
    uint256 public harvestChargeRatePerResonance = 1e14; // Charge per second per point of Resonance (scaled)

    uint256 public stateDurationNascent = 1 days;
    uint256 public stateDurationHarmonizing = 7 days;
    uint256 public stateDurationStable = 30 days;
    // Decaying state duration is potentially infinite until shattered

    uint256 public purityDecayRateStable = 1; // Purity decay per day in Stable state
    uint256 public purityDecayRateDecaying = 10; // Purity decay per day in Decaying state
    uint256 public resonanceDecayRateStable = 0; // Resonance decay per day in Stable state
    uint256 public resonanceDecayRateDecaying = 5; // Resonance decay per day in Decaying state

    uint256 public fuseAetherCost = 500 * 1e18; // Aether cost to fuse
    uint256 public shatterChrononReturnRate = 5 * 1e18; // Chronons returned per point of final Purity/Resonance (average)

    uint256 public stabilizeAetherCostPerDay = 50 * 1e18;
    uint256 public catalyzeAetherCostPerDay = 75 * 1e18;
    uint256 public sleepAetherCost = 10 * 1e18;
    uint256 public awakenAetherCost = 20 * 1e18;

    uint256 public chrononToAetherRate = 1e18; // 1 Chronon crystallizes into 1 Aether (scaled)

    uint256 private constant PURITY_MAX = 10000;
    uint256 private constant RESONANCE_MAX = 10000;
    uint256 private constant SCALING_FACTOR = 1e18; // For fixed-point arithmetic if needed later, useful placeholder


    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
    }

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) revert QuantumStateFoundry__NotContractOwner();
        _;
    }

    // --- Internal Helper Functions ---

    /// @dev Calculates and updates the state and properties of a Quantum Core based on time and active effects.
    /// This is a crucial function called before any action that depends on or changes core state.
    /// @param coreId The ID of the core to update.
    function _updateCoreStateDynamics(uint256 coreId) internal {
        QuantumCore storage core = _idToCore[coreId];
        if (core.id == 0 || core.state == CoreState.Dormant) return; // Core doesn't exist or is sleeping, no dynamics update needed

        uint256 currentTime = block.timestamp;
        uint256 timePassed = currentTime - core.lastUpdatedTimestamp;

        // Apply time freeze effect
        uint256 effectiveTimePassed = timePassed;
        if (currentTime < core.timeFreezeUntil) {
             // If currently frozen, effective time passed is 0
             effectiveTimePassed = 0;
        } else if (core.lastUpdatedTimestamp < core.timeFreezeUntil) {
            // If freeze ended during this time slice, only count time since freeze ended
            effectiveTimePassed = currentTime - core.timeFreezeUntil;
        }
        // Note: If freeze *starts* in the future, effectiveTimePassed is still `timePassed`.
        // This logic assumes timeFreezeUntil is in the future *when set*, and we handle the period *since* last update.

        // Apply resonance boost effect (doesn't affect state transition, only resonance growth/decay calculation)
        uint256 resonanceBoostDuration = 0;
        if (currentTime > core.resonanceBoostUntil && core.lastUpdatedTimestamp < core.resonanceBoostUntil) {
             // Boost ended during this time slice, calculate duration boost was active
             resonanceBoostDuration = core.resonanceBoostUntil - core.lastUpdatedTimestamp;
        } else if (currentTime <= core.resonanceBoostUntil) {
             // Boost active for the entire time slice
             resonanceBoostDuration = timePassed;
        }
        // Note: If boost *starts* in the future, it won't affect this time slice.


        uint256 age = currentTime - core.bornTimestamp;

        // --- State Transition ---
        CoreState oldState = core.state;
        if (core.state == CoreState.Nascent && age >= stateDurationNascent) {
            core.state = CoreState.Harmonizing;
        }
        if (core.state == CoreState.Harmonizing && age >= stateDurationNascent + stateDurationHarmonizing) {
             core.state = CoreState.Stable;
        }
        if (core.state == CoreState.Stable && age >= stateDurationNascent + stateDurationHarmonizing + stateDurationStable) {
             core.state = CoreState.Decaying;
        }
        // Decaying state is terminal unless fused/shattered

        if (core.state != oldState) {
            emit CoreStateChanged(coreId, core.state, oldState);
        }

        // --- Property Dynamics (Purity, Resonance, Temporal Charge) ---
        if (effectiveTimePassed > 0) {
            uint256 effectiveDaysPassed = effectiveTimePassed / 1 days; // Integer days passed

            // Purity Decay
            uint256 purityDecayPerDay = 0;
            if (core.state == CoreState.Stable) purityDecayPerDay = purityDecayRateStable;
            if (core.state == CoreState.Decaying) purityDecayPerDay = purityDecayRateDecaying;

            if (purityDecayPerDay > 0 && core.purity > 0) {
                 uint256 decayAmount = purityDecayPerDay * effectiveDaysPassed;
                 if (decayAmount > core.purity) core.purity = 0;
                 else core.purity -= decayAmount;
            }

            // Resonance Change (Simplified: decays in later states)
            uint256 resonanceDecayPerDay = 0;
             if (core.state == CoreState.Stable) resonanceDecayPerDay = resonanceDecayRateStable;
             if (core.state == CoreState.Decaying) resonanceDecayPerDay = resonanceDecayRateDecaying;

             if (resonanceDecayPerDay > 0 && core.resonance > 0) {
                 uint256 decayAmount = resonanceDecayPerDay * effectiveDaysPassed;
                 if (decayAmount > core.resonance) core.resonance = 0;
                 else core.resonance -= decayAmount;
            }


            // Temporal Charge Accumulation
            // Base accumulation + accumulation based on Resonance
            // Boosted rate applies during resonanceBoostUntil period
            uint256 totalChargeAdded = 0;

            if (effectiveTimePassed > resonanceBoostDuration) {
                 // Time passed OUTSIDE boost period
                 totalChargeAdded += (effectiveTimePassed - resonanceBoostDuration) * (harvestChargeRateBase + (core.resonance * harvestChargeRatePerResonance / SCALING_FACTOR));
            }
             if (resonanceBoostDuration > 0) {
                 // Time passed INSIDE boost period (e.g., 2x rate)
                 // Example: Resonance is 1000. Rate is Base + 1000 * RatePerResonance.
                 // Boosted rate could be (Base + 1000 * RatePerResonance) * BOOST_FACTOR
                 uint256 boostedRate = harvestChargeRateBase + (core.resonance * harvestChargeRatePerResonance * 2 / SCALING_FACTOR); // Example: 2x boost factor
                 totalChargeAdded += resonanceBoostDuration * boostedRate;
             }

            core.temporalCharge += totalChargeAdded;
        }

        core.lastUpdatedTimestamp = uint40(currentTime);
    }

    /// @dev Calculates the amount of Chronons that would be yielded from a Core's current temporal charge.
    /// Does NOT modify the core's state or charge.
    /// @param coreId The ID of the core.
    /// @return The amount of Chronons the current charge represents.
    function _calculateCurrentResonanceYield(uint256 coreId) internal view returns (uint256) {
        QuantumCore storage core = _idToCore[coreId];
        if (core.id == 0) return 0; // Core does not exist

        // Simulate update to get potential current charge
        uint256 currentTime = block.timestamp;
        uint256 timePassed = currentTime - core.lastUpdatedTimestamp;

        uint256 effectiveTimePassed = timePassed;
        if (currentTime < core.timeFreezeUntil) effectiveTimePassed = 0; // If frozen now, no charge accumulates *in this period*

        uint256 resonanceBoostDuration = 0;
        if (currentTime > core.resonanceBoostUntil && core.lastUpdatedTimestamp < core.resonanceBoostUntil) {
             resonanceBoostDuration = core.resonanceBoostUntil - core.lastUpdatedTimestamp;
        } else if (currentTime <= core.resonanceBoostUntil) {
             resonanceBoostDuration = timePassed;
        }

        uint256 simulatedChargeAdded = 0;
         if (effectiveTimePassed > resonanceBoostDuration) {
             simulatedChargeAdded += (effectiveTimePassed - resonanceBoostDuration) * (harvestChargeRateBase + (core.resonance * harvestChargeRatePerResonance / SCALING_FACTOR));
         }
         if (resonanceBoostDuration > 0) {
             uint256 boostedRate = harvestChargeRateBase + (core.resonance * harvestChargeRatePerResonance * 2 / SCALING_FACTOR); // Example: 2x boost factor
             simulatedChargeAdded += resonanceBoostDuration * boostedRate;
         }


        uint256 currentSimulatedCharge = core.temporalCharge + simulatedChargeAdded;

        // Simple yield calculation: 1 Temporal Charge unit = 1 Chronon unit
        return currentSimulatedCharge; // Assuming 1:1 for simplicity, or add a conversion rate if needed
    }

    /// @dev Checks if a core exists.
    /// @param coreId The ID of the core.
    /// @return True if the core exists, false otherwise.
    function _exists(uint256 coreId) internal view returns (bool) {
        return _idToOwner[coreId] != address(0);
    }

    /// @dev Checks if an address is the owner of a core or is approved for it.
    /// @param approvedOrOwner The address to check.
    /// @param coreId The ID of the core.
    /// @return True if the address is authorized, false otherwise.
    function _isApprovedOrOwner(address approvedOrOwner, uint256 coreId) internal view returns (bool) {
        address owner = _idToOwner[coreId];
        return (approvedOrOwner == owner ||
                approvedOrOwner == _coreApprovals[coreId] ||
                _operatorApprovals[owner][approvedOrOwner]);
    }

    /// @dev Internal core transfer logic. Assumes authorization checks are done externally.
    /// @param from The current owner.
    /// @param to The new owner.
    /// @param coreId The ID of the core to transfer.
    function _transferCore(address from, address to, uint256 coreId) internal {
        // Clear approvals for the transferred core
        delete _coreApprovals[coreId];

        _ownerCoreCount[from]--;
        _ownerCoreCount[to]++;
        _idToOwner[coreId] = to;

        emit CoreTransfer(from, to, coreId);
    }

    /// @dev Internal core minting logic. Assumes payment/cost checks are done externally.
    /// @param owner The recipient of the new core.
    /// @param initialPurity The initial purity value.
    /// @param initialResonance The initial resonance value.
    /// @return The ID of the newly minted core.
    function _mintCore(address owner, uint256 initialPurity, uint256 initialResonance) internal returns (uint256) {
        _coreIds++;
        uint256 newCoreId = _coreIds;
        uint40 currentTime = uint40(block.timestamp);

        _idToCore[newCoreId] = QuantumCore({
            id: newCoreId,
            state: CoreState.Nascent,
            purity: initialPurity,
            resonance: initialResonance,
            temporalCharge: 0,
            bornTimestamp: currentTime,
            lastUpdatedTimestamp: currentTime,
            timeFreezeUntil: 0,
            resonanceBoostUntil: 0,
            sleepTimestamp: 0, // Not sleeping initially
            purityAtSleep: 0,
            resonanceAtSleep: 0,
            temporalChargeAtSleep: 0
        });

        _idToOwner[newCoreId] = owner;
        _ownerCoreCount[owner]++;

        emit CoreForged(newCoreId, owner, initialPurity, initialResonance);

        return newCoreId;
    }

    /// @dev Internal core burning logic. Assumes authorization checks are done externally.
    /// @param coreId The ID of the core to burn.
    /// @param owner The owner of the core.
    function _burnCore(uint256 coreId, address owner) internal {
        // Clear approvals
        delete _coreApprovals[coreId];
        delete _operatorApprovals[owner][msg.sender]; // Clear operator approvals by this sender for this owner? No, that's not how it works. Operator approval is for the owner's *all* tokens.

        _ownerCoreCount[owner]--;
        delete _idToOwner[coreId];
        delete _idToCore[coreId]; // Remove core data
        // Note: coreId will never be reused in _idToCore mapping logic due to counter increment, but explicitly deleting mapping entry is cleaner.
        // The _coreIds counter keeps incrementing, ensuring unique future IDs.
    }

    /// @dev Internal Chronon minting logic.
    /// @param account The recipient of Chronons.
    /// @param amount The amount to mint.
    function _mintChronons(address account, uint256 amount) internal {
        _chrononBalances[account] += amount;
        _totalChrononsMinted += amount; // Track total supply
        // No event for internal minting, only when earned via harvest
    }

    /// @dev Internal Chronon burning logic.
    /// @param account The account burning Chronons.
    /// @param amount The amount to burn.
    function _burnChronons(address account, uint256 amount) internal {
        uint256 balance = _chrononBalances[account];
        if (balance < amount) revert QuantumStateFoundry__InsufficientFunds(amount, balance);
        _chrononBalances[account] -= amount;
        _totalChrononsMinted -= amount; // Decrement total supply
    }

     /// @dev Internal Aether minting logic.
    /// @param account The recipient of Aether.
    /// @param amount The amount to mint.
    function _mintAether(address account, uint256 amount) internal {
        _aetherBalances[account] += amount;
        _totalAetherMinted += amount; // Track total supply
        // No event for internal minting, only when earned via crystallization
    }

    /// @dev Internal Aether burning logic.
    /// @param account The account burning Aether.
    /// @param amount The amount to burn.
    function _burnAether(address account, uint256 amount) internal {
        uint256 balance = _aetherBalances[account];
        if (balance < amount) revert QuantumStateFoundry__InsufficientFunds(amount, balance);
        _aetherBalances[account] -= amount;
        _totalAetherMinted -= amount; // Decrement total supply
    }

    /// @dev Internal Aether transfer logic. Assumes authorization checks are done externally.
    /// @param from The sender.
    /// @param to The recipient.
    /// @param amount The amount to transfer.
    function _transferAether(address from, address to, uint256 amount) internal {
        _burnAether(from, amount);
        _mintAether(to, amount);
        emit AetherTransfer(from, to, amount);
    }


    // --- Public & External Functions ---

    // --- Core Management & Interaction ---

    /// @summary Forges a new Quantum Core.
    /// @dev Requires spending Aether. Initial properties are influenced by desired inputs within contract limits.
    /// @param desiredPurity Desired initial Purity (0-10000).
    /// @param desiredResonance Desired initial Resonance (0-10000).
    function forgeQuantumCore(uint256 desiredPurity, uint256 desiredResonance) external {
        if (desiredPurity > PURITY_MAX || desiredResonance > RESONANCE_MAX) {
            revert QuantumStateFoundry__InvalidParameterValue();
        }

        // Calculate Aether cost based on desired properties
        uint256 requiredAether = forgeAetherCostBase +
                                   (desiredPurity * forgePurityCostFactor / PURITY_MAX) +
                                   (desiredResonance * forgeResonanceCostFactor / RESONANCE_MAX);

        if (_aetherBalances[msg.sender] < requiredAether) {
             revert QuantumStateFoundry__InsufficientFunds(requiredAether, _aetherBalances[msg.sender]);
        }

        _burnAether(msg.sender, requiredAether);

        // Actual initial properties might be slightly different or capped based on parameters
        uint256 initialPurity = desiredPurity; // Simplified: use desired directly for now
        uint256 initialResonance = desiredResonance; // Simplified: use desired directly for now

        _mintCore(msg.sender, initialPurity, initialResonance);
    }

    /// @summary Harvests accumulated Temporal Charge from a Core into Chronon tokens.
    /// @dev Updates Core state, calculates and mints Chronons, resets Core's temporal charge.
    /// @param coreId The ID of the Core to harvest from.
    function harvestResonance(uint256 coreId) external {
        if (!_exists(coreId)) revert QuantumStateFoundry__CoreDoesNotExist();
        if (_idToOwner[coreId] != msg.sender) revert QuantumStateFoundry__NotCoreOwner();
        if (_idToCore[coreId].state == CoreState.Dormant) revert QuantumStateFoundry__CoreAlreadySleeping();


        _updateCoreStateDynamics(coreId); // Ensure state is current before harvesting

        QuantumCore storage core = _idToCore[coreId];

        uint256 yieldAmount = core.temporalCharge; // 1:1 conversion Temporal Charge to Chronons

        if (yieldAmount == 0) return; // Nothing to harvest

        _mintChronons(msg.sender, yieldAmount);

        uint256 remainingCharge = core.temporalCharge;
        core.temporalCharge = 0; // Reset temporal charge after harvest

        emit ResonanceHarvested(coreId, msg.sender, yieldAmount, remainingCharge);
    }

    /// @summary Fuses two Quantum Cores into a new, single Core.
    /// @dev Burns the two source Cores, calculates properties for a new Core based on the inputs, and mints the new Core. Requires Aether cost.
    /// @param coreId1 The ID of the first Core.
    /// @param coreId2 The ID of the second Core.
    function fuseQuantumCores(uint256 coreId1, uint256 coreId2) external {
        if (!_exists(coreId1)) revert QuantumStateFoundry__CoreDoesNotExist();
        if (!_exists(coreId2)) revert QuantumStateFoundry__CoreDoesNotExist();
        if (coreId1 == coreId2) revert QuantumStateFoundry__FusionNotEligible(); // Cannot fuse a core with itself
        if (_idToOwner[coreId1] != msg.sender || _idToOwner[coreId2] != msg.sender) revert QuantumStateFoundry__NotCoreOwner(); // Must own both cores

        if (_aetherBalances[msg.sender] < fuseAetherCost) {
             revert QuantumStateFoundry__InsufficientFunds(fuseAetherCost, _aetherBalances[msg.sender]);
        }

        _updateCoreStateDynamics(coreId1); // Ensure states are current
        _updateCoreStateDynamics(coreId2);

        QuantumCore storage core1 = _idToCore[coreId1];
        QuantumCore storage core2 = _idToCore[coreId2];

        // Fusion Logic (Example: weighted average of properties, minimum of current states)
        uint256 newPurity = (core1.purity + core2.purity) / 2;
        uint256 newResonance = (core1.resonance + core2.resonance) / 2;
        // State logic could be: if either is decaying, new one starts decaying. If both stable, new one starts stable etc.
        // Simplistic state logic: new core starts in Harmonizing unless inputs are Decaying.
        CoreState newInitialState = CoreState.Harmonizing;
        if (core1.state == CoreState.Decaying || core2.state == CoreState.Decaying) {
             newInitialState = CoreState.Decaying; // Fusion can't save a decaying fate fully
        } else if (core1.state == CoreState.Stable && core2.state == CoreState.Stable) {
             newInitialState = CoreState.Stable; // High quality inputs start higher
        }


        _burnAether(msg.sender, fuseAetherCost);
        _burnCore(coreId1, msg.sender);
        _burnCore(coreId2, msg.sender);

        uint256 newCoreId = _mintCore(msg.sender, newPurity, newResonance);
        _idToCore[newCoreId].state = newInitialState; // Set determined initial state
        _idToCore[newCoreId].bornTimestamp = uint40(block.timestamp); // Reset age for new core dynamics

        emit CoresFused(coreId1, coreId2, newCoreId, msg.sender);
    }

    /// @summary Stabilizes a Core's state, temporarily halting or slowing down decay/state transitions.
    /// @dev Requires Aether cost based on duration. Sets `timeFreezeUntil`.
    /// @param coreId The ID of the Core to stabilize.
    /// @param durationDays The duration in days to stabilize the core.
    function stabilizeCoreState(uint256 coreId, uint256 durationDays) external {
        if (!_exists(coreId)) revert QuantumStateFoundry__CoreDoesNotExist();
        if (_idToOwner[coreId] != msg.sender) revert QuantumStateFoundry__NotCoreOwner();
        if (durationDays == 0) revert QuantumStateFoundry__InvalidParameterValue();
         if (_idToCore[coreId].state == CoreState.Dormant) revert QuantumStateFoundry__CoreAlreadySleeping();


        uint256 requiredAether = durationDays * stabilizeAetherCostPerDay;
         if (_aetherBalances[msg.sender] < requiredAether) {
             revert QuantumStateFoundry__InsufficientFunds(requiredAether, _aetherBalances[msg.sender]);
        }

        _updateCoreStateDynamics(coreId); // Ensure state is current before applying effect

        QuantumCore storage core = _idToCore[coreId];
        // Extend time freeze from current time or existing freeze end
        uint256 freezeUntil = block.timestamp;
        if (core.timeFreezeUntil > freezeUntil) {
            freezeUntil = core.timeFreezeUntil;
        }
        core.timeFreezeUntil = uint40(freezeUntil + durationDays * 1 days);

        _burnAether(msg.sender, requiredAether);

        emit CoreStabilized(coreId, durationDays);
    }

     /// @summary Temporarily boosts a Core's resonance accumulation rate.
    /// @dev Requires Aether cost based on duration. Sets `resonanceBoostUntil`.
    /// @param coreId The ID of the Core to catalyze.
    /// @param durationDays The duration in days for the boost.
    function catalyzeResonance(uint256 coreId, uint256 durationDays) external {
        if (!_exists(coreId)) revert QuantumStateFoundry__CoreDoesNotExist();
        if (_idToOwner[coreId] != msg.sender) revert QuantumStateFoundry__NotCoreOwner();
        if (durationDays == 0) revert QuantumStateFoundry__InvalidParameterValue();
        if (_idToCore[coreId].state == CoreState.Dormant) revert QuantumStateFoundry__CoreAlreadySleeping();


        uint256 requiredAether = durationDays * catalyzeAetherCostPerDay;
         if (_aetherBalances[msg.sender] < requiredAether) {
             revert QuantumStateFoundry__InsufficientFunds(requiredAether, _aetherBalances[msg.sender]);
        }

         _updateCoreStateDynamics(coreId); // Ensure state is current before applying effect

        QuantumCore storage core = _idToCore[coreId];
        // Extend boost from current time or existing boost end
        uint256 boostUntil = block.timestamp;
        if (core.resonanceBoostUntil > boostUntil) {
            boostUntil = core.resonanceBoostUntil;
        }
        core.resonanceBoostUntil = uint40(boostUntil + durationDays * 1 days);

        _burnAether(msg.sender, requiredAether);

        emit ResonanceCatalyzed(coreId, durationDays);
    }


    /// @summary Transfers ownership of a Core.
    /// @dev ERC721-like transfer. Requires approval or ownership. Does not include ERC721 `safeTransferFrom`.
    /// @param from The current owner.
    /// @param to The recipient.
    /// @param coreId The ID of the Core.
    function transferCore(address from, address to, uint256 coreId) external {
        if (!_exists(coreId)) revert QuantumStateFoundry__CoreDoesNotExist();
        if (_idToOwner[coreId] != from) revert QuantumStateFoundry__NotCoreOwner(); // 'from' must be the actual owner
        if (to == address(0)) revert QuantumStateFoundry__InvalidParameterValue(); // Cannot transfer to zero address

        // Check authorization: sender must be owner OR approved OR an approved operator
        if (!_isApprovedOrOwner(msg.sender, coreId)) {
             revert QuantumStateFoundry__NotApprovedOrOwner();
        }

        // It's good practice to update dynamics before transfer, though not strictly necessary for *transfer* logic itself,
        // it ensures the receiver gets a core with properties reflecting time passed up to the transfer point.
        _updateCoreStateDynamics(coreId);

        _transferCore(from, to, coreId);
    }

     /// @summary Approves an address to manage a specific Core.
    /// @dev ERC721-like approval.
    /// @param approved The address to approve.
    /// @param coreId The ID of the Core.
    function approveCore(address approved, uint256 coreId) external {
         if (!_exists(coreId)) revert QuantumStateFoundry__CoreDoesNotExist();
         address owner = _idToOwner[coreId];
         if (msg.sender != owner && !_operatorApprovals[owner][msg.sender]) {
             revert QuantumStateFoundry__NotApprovedOrOwner(); // Only owner or approved operator can approve
         }
         if (approved == owner) revert QuantumStateFoundry__CannotSelfApprove(); // Cannot approve owner

         _coreApprovals[coreId] = approved;
         emit Approval(owner, approved, coreId);
    }

    /// @summary Sets or unsets approval for an operator to manage all of the sender's Cores.
    /// @dev ERC721-like approval for all.
    /// @param operator The address to set as operator.
    /// @param approved True to approve, false to unapprove.
    function setApprovalForAllCores(address operator, bool approved) external {
        if (operator == msg.sender) revert QuantumStateFoundry__CannotSelfApprove(); // Cannot set self as operator

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }


    /// @summary Destroys a Quantum Core for a small return in Chronons.
    /// @dev Burns the Core and mints Chronons based on its final state/properties. Requires ownership.
    /// @param coreId The ID of the Core to shatter.
    function shatterCore(uint256 coreId) external {
        if (!_exists(coreId)) revert QuantumStateFoundry__CoreDoesNotExist();
        if (_idToOwner[coreId] != msg.sender) revert QuantumStateFoundry__NotCoreOwner();

        _updateCoreStateDynamics(coreId); // Final update before shattering

        QuantumCore storage core = _idToCore[coreId];

        // Calculate return based on final purity and resonance
        uint256 returnChronons = (core.purity + core.resonance) / 2 * shatterChrononReturnRate / 10000; // Average Purity/Resonance out of 10000

        _mintChronons(msg.sender, returnChronons);

        _burnCore(coreId, msg.sender);

        emit CoreShattered(coreId, msg.sender, returnChronons);
    }

    /// @summary Forces an immediate update of a Core's state and properties.
    /// @dev Useful for clients to see the current dynamic state without performing an action.
    /// @param coreId The ID of the Core to sync.
    function syncCoreState(uint256 coreId) external {
        if (!_exists(coreId)) revert QuantumStateFoundry__CoreDoesNotExist();
        // Anyone can sync a core's state to see its public dynamic properties
        _updateCoreStateDynamics(coreId);
    }

    /// @summary Puts a Core into a dormant state, pausing its dynamics.
    /// @dev Saves current dynamic state values to resume accurately later. Requires Aether cost.
    /// @param coreId The ID of the Core to sleep.
    function sleepCore(uint256 coreId) external {
        if (!_exists(coreId)) revert QuantumStateFoundry__CoreDoesNotExist();
        if (_idToOwner[coreId] != msg.sender) revert QuantumStateFoundry__NotCoreOwner();
        if (_idToCore[coreId].state == CoreState.Dormant) revert QuantumStateFoundry__CoreAlreadySleeping();

        if (_aetherBalances[msg.sender] < sleepAetherCost) {
             revert QuantumStateFoundry__InsufficientFunds(sleepAetherCost, _aetherBalances[msg.sender]);
        }

        _updateCoreStateDynamics(coreId); // Capture current state before sleeping

        QuantumCore storage core = _idToCore[coreId];
        core.sleepTimestamp = uint40(block.timestamp);
        core.purityAtSleep = core.purity;
        core.resonanceAtSleep = core.resonance;
        core.temporalChargeAtSleep = core.temporalCharge;

        CoreState oldState = core.state;
        core.state = CoreState.Dormant;

        _burnAether(msg.sender, sleepAetherCost);

        emit CoreSlept(coreId);
        emit CoreStateChanged(coreId, CoreState.Dormant, oldState);
    }

     /// @summary Awakens a Core from a dormant state, resuming its dynamics.
    /// @dev Requires Aether cost. Recalculates properties based on saved sleep state and total age.
    /// @param coreId The ID of the Core to awaken.
    function awakenCore(uint256 coreId) external {
        if (!_exists(coreId)) revert QuantumStateFoundry__CoreDoesNotExist();
        if (_idToOwner[coreId] != msg.sender) revert QuantumStateFoundry__NotCoreOwner();
        if (_idToCore[coreId].state != CoreState.Dormant) revert QuantumStateFoundry__CoreNotSleeping();

        if (_aetherBalances[msg.sender] < awakenAetherCost) {
             revert QuantumStateFoundry__InsufficientFunds(awakenAetherCost, _aetherBalances[msg.sender]);
        }

        QuantumCore storage core = _idToCore[coreId];
        uint40 currentTime = uint40(block.timestamp);

        // Restore properties from sleep state (these are the values time dynamics paused on)
        core.purity = core.purityAtSleep;
        core.resonance = core.resonanceAtSleep;
        core.temporalCharge = core.temporalChargeAtSleep;

        // Recalculate age-based state and dynamics as if time was *not* paused
        // Total age = (Sleep Timestamp - Born Timestamp) + (Current Timestamp - Sleep Timestamp)
        // Simplified: The time spent sleeping is *not* added to the core's active age.
        // Dynamics resume *from* the point they stopped, based on time passed *since* awakening.
        // The 'bornTimestamp' remains the true birth time. `lastUpdatedTimestamp` is key here.
        core.lastUpdatedTimestamp = currentTime; // Dynamics resume from now

        // Determine new state based on total age excluding sleep time?
        // OR, resume based on state at sleep + dynamics since awakening?
        // Let's keep it simple: Resume dynamics from the time it wakes up, based on its state *when it went to sleep*,
        // and its *actual* born timestamp for state transitions that depend on total age.
        // The `_updateCoreStateDynamics` handles age correctly.

        CoreState oldState = core.state;
        // Reset sleep state variables
        core.sleepTimestamp = 0;
        core.purityAtSleep = 0;
        core.resonanceAtSleep = 0;
        core.temporalChargeAtSleep = 0;

        // Immediately update state dynamics to transition out of dormant if needed based on age
        _updateCoreStateDynamics(coreId);

        _burnAether(msg.sender, awakenAetherCost);

        emit CoreAwakened(coreId);
        // StateChange event is emitted by _updateCoreStateDynamics if state changes
    }


    // --- Internal Economy (Chronon/Aether) ---

    /// @summary Converts Chronon tokens held by the sender into Aether tokens.
    /// @dev Burns Chronons and mints Aether at a fixed rate.
    /// @param chrononsToBurn The amount of Chronons to burn.
    function crystallizeChrononsToAether(uint256 chrononsToBurn) external {
        if (chrononsToBurn == 0) revert QuantumStateFoundry__InvalidAmount();
        if (_chrononBalances[msg.sender] < chrononsToBurn) {
            revert QuantumStateFoundry__InsufficientFunds(chrononsToBurn, _chrononBalances[msg.sender]);
        }

        uint256 aetherToMint = chrononsToBurn * chrononToAetherRate / SCALING_FACTOR; // Use SCALING_FACTOR for rate

        _burnChronons(msg.sender, chrononsToBurn);
        _mintAether(msg.sender, aetherToMint);

        emit ChrononsCrystallizedIntoAether(msg.sender, chrononsToBurn, aetherToMint);
    }

    /// @summary Transfers Chronon tokens from the sender to another address.
    /// @param to The recipient address.
    /// @param amount The amount of Chronons to transfer.
    function transferChronons(address to, uint256 amount) external {
         if (to == address(0)) revert QuantumStateFoundry__InvalidParameterValue();
         if (amount == 0) revert QuantumStateFoundry__InvalidAmount();
         if (_chrononBalances[msg.sender] < amount) {
             revert QuantumStateFoundry__InsufficientFunds(amount, _chrononBalances[msg.sender]);
         }

        _burnChronons(msg.sender, amount); // Burning from sender
        _mintChronons(to, amount); // Minting to recipient

        emit ChrononTransfer(msg.sender, to, amount);
    }

    /// @summary Transfers Aether tokens from the sender to another address.
    /// @param to The recipient address.
    /// @param amount The amount of Aether to transfer.
    function transferAether(address to, uint256 amount) external {
        if (to == address(0)) revert QuantumStateFoundry__InvalidParameterValue();
        if (amount == 0) revert QuantumStateFoundry__InvalidAmount();
        if (_aetherBalances[msg.sender] < amount) {
             revert QuantumStateFoundry__InsufficientFunds(amount, _aetherBalances[msg.sender]);
        }

        _transferAether(msg.sender, to, amount); // Uses internal helper
    }


    // --- Query Functions ---

    /// @summary Gets all details for a specific Quantum Core.
    /// @dev Includes state, properties, timestamps, and active effects.
    /// @param coreId The ID of the Core.
    /// @return The QuantumCore struct data.
    function getCoreDetails(uint256 coreId) external view returns (QuantumCore memory) {
        if (!_exists(coreId)) revert QuantumStateFoundry__CoreDoesNotExist();
        // Call internal helper to get the struct copy (view function cannot modify storage)
        // Note: State returned reflects last update, not real-time unless syncCoreState was just called.
        // For real-time dynamic properties, use getCoreProperties or calculateProjected...
        return _idToCore[coreId];
    }

     /// @summary Gets the current state of a Quantum Core.
    /// @param coreId The ID of the Core.
    /// @return The CoreState enum value.
    function getCoreState(uint256 coreId) external view returns (CoreState) {
        if (!_exists(coreId)) revert QuantumStateFoundry__CoreDoesNotExist();
        // Note: This returns the state at the last update. Use syncCoreState first for real-time.
        return _idToCore[coreId].state;
    }

    /// @summary Gets the current dynamic properties of a Quantum Core (Purity, Resonance, Temporal Charge).
    /// @param coreId The ID of the Core.
    /// @return purity, resonance, temporalCharge values.
    function getCoreProperties(uint256 coreId) external view returns (uint256 purity, uint256 resonance, uint256 temporalCharge) {
        if (!_exists(coreId)) revert QuantumStateFoundry__CoreDoesNotExist();
        // Note: These reflect properties at the last update. Use syncCoreState first for real-time.
        QuantumCore storage core = _idToCore[coreId];
        return (core.purity, core.resonance, core.temporalCharge);
    }


    /// @summary Calculates the *projected* Temporal Charge yield after a given number of seconds.
    /// @dev This is a simulation and does not modify the Core's state. Accounts for active effects (freeze/boost) within the projection window.
    /// @param coreId The ID of the Core.
    /// @param secondsInFuture The number of seconds to project forward.
    /// @return The simulated Temporal Charge amount after the projection.
    function calculateProjectedTemporalCharge(uint256 coreId, uint256 secondsInFuture) external view returns (uint256) {
        if (!_exists(coreId)) revert QuantumStateFoundry__CoreDoesNotExist();
        QuantumCore storage core = _idToCore[coreId];

        // This calculation needs to replicate the charge logic in _updateCoreStateDynamics
        // but applied to a hypothetical future time.

        uint256 lastUpdated = core.lastUpdatedTimestamp;
        uint256 simulationEndTime = block.timestamp + secondsInFuture;

        uint256 effectiveTimePassedForSim = simulationEndTime - lastUpdated;

        // Account for time freeze during the simulation period
        uint256 freezeUntil = core.timeFreezeUntil;
        if (lastUpdated < freezeUntil && simulationEndTime > freezeUntil) {
            // Freeze ends during the simulation period
            effectiveTimePassedForSim = (freezeUntil - lastUpdated) * 0 + (simulationEndTime - freezeUntil); // Time spent frozen is 0 effective time
        } else if (simulationEndTime <= freezeUntil) {
            // Simulation entirely within freeze period
            effectiveTimePassedForSim = 0;
        }
        // If lastUpdated >= freezeUntil, freeze already ended, effectiveTimePassedForSim is just simulationEndTime - lastUpdated


        // Account for resonance boost during the simulation period
        uint256 resonanceBoostUntil = core.resonanceBoostUntil;
        uint256 boostedDurationInSim = 0;

        if (lastUpdated < resonanceBoostUntil && simulationEndTime > resonanceBoostUntil) {
            // Boost ends during simulation
            boostedDurationInSim = resonanceBoostUntil - lastUpdated;
        } else if (simulationEndTime <= resonanceBoostUntil && lastUpdated < simulationEndTime) {
            // Simulation entirely within boost period (that started before or at lastUpdated)
            boostedDurationInSim = simulationEndTime - lastUpdated;
        } else if (lastUpdated < resonanceBoostUntil && simulationEndTime <= resonanceBoostUntil) {
             // Simulation starts before boost ends and ends within boost period
             boostedDurationInSim = simulationEndTime - lastUpdated;
        }


        uint256 simulatedChargeAdded = 0;

         if (effectiveTimePassedForSim > boostedDurationInSim) {
             // Time passed OUTSIDE boost period during simulation
             simulatedChargeAdded += (effectiveTimePassedForSim - boostedDurationInSim) * (harvestChargeRateBase + (core.resonance * harvestChargeRatePerResonance / SCALING_FACTOR));
         }
         if (boostedDurationInSim > 0) {
             // Time passed INSIDE boost period during simulation
             uint256 boostedRate = harvestChargeRateBase + (core.resonance * harvestChargeRatePerResonance * 2 / SCALING_FACTOR); // Example: 2x boost factor
             simulatedChargeAdded += boostedDurationInSim * boostedRate;
         }

        // Total charge is current charge + simulated added charge
        return core.temporalCharge + simulatedChargeAdded;
    }


    /// @summary Gets the number of Cores owned by an address.
    /// @dev ERC721-like balance query.
    /// @param owner The address to query.
    /// @return The number of Cores owned.
    function balanceOfCores(address owner) external view returns (uint256) {
        return _ownerCoreCount[owner];
    }

    /// @summary Gets the owner of a specific Core.
    /// @dev ERC721-like owner query.
    /// @param coreId The ID of the Core.
    /// @return The owner's address.
    function ownerOfCore(uint256 coreId) external view returns (address) {
         if (!_exists(coreId)) revert QuantumStateFoundry__CoreDoesNotExist(); // Standard ERC721 returns address(0), but let's revert for clarity
        return _idToOwner[coreId];
    }

     /// @summary Gets the approved address for a specific Core.
    /// @dev ERC721-like approval query.
    /// @param coreId The ID of the Core.
    /// @return The approved address.
    function getApprovedCore(uint256 coreId) external view returns (address) {
         if (!_exists(coreId)) revert QuantumStateFoundry__CoreDoesNotExist();
        return _coreApprovals[coreId];
    }

    /// @summary Checks if an operator is approved for all of an owner's Cores.
    /// @dev ERC721-like operator approval query.
    /// @param owner The owner's address.
    /// @param operator The operator's address.
    /// @return True if approved, false otherwise.
    function isApprovedForAllCores(address owner, address operator) external view returns (bool) {
        return _operatorApprovals[owner][operator];
    }


    /// @summary Gets the Chronon balance for an address.
    /// @param owner The address to query.
    /// @return The Chronon balance.
    function balanceOfChronons(address owner) external view returns (uint256) {
        return _chrononBalances[owner];
    }

    /// @summary Gets the Aether balance for an address.
    /// @param owner The address to query.
    /// @return The Aether balance.
    function balanceOfAether(address owner) external view returns (uint256) {
        return _aetherBalances[owner];
    }

    /// @summary Gets the total number of Quantum Cores minted.
    /// @return The total supply of Cores.
    function getTotalCores() external view returns (uint256) {
        return _coreIds; // Counter goes up, even if some are burned. Could track actively circulating if needed.
    }

    /// @summary Gets the total supply of Chronon tokens.
    /// @return The total supply of Chronons.
    function getTotalChrononSupply() external view returns (uint256) {
        return _totalChrononsMinted; // Tracks minted - burned
    }

     /// @summary Gets the total supply of Aether tokens.
    /// @return The total supply of Aether.
    function getTotalAetherSupply() external view returns (uint256) {
        return _totalAetherMinted; // Tracks minted - burned
    }


    // --- Admin/Parameter Functions ---

    /// @summary Allows the contract owner to update core parameters.
    /// @dev Sensitive function, control access carefully.
    /// @param _forgeAetherCostBase Base Aether cost to forge.
    /// @param _forgePurityCostFactor Additional Aether cost per point of purity.
    /// @param _forgeResonanceCostFactor Additional Aether cost per point of resonance.
    /// @param _harvestChargeRateBase Base charge per second.
    /// @param _harvestChargeRatePerResonance Charge per second per resonance point.
    /// @param _stateDurationNascent Nascent state duration in seconds.
    /// @param _stateDurationHarmonizing Harmonizing state duration in seconds.
    /// @param _stateDurationStable Stable state duration in seconds.
    /// @param _purityDecayRateStable Purity decay per day in Stable state.
    /// @param _purityDecayRateDecaying Purity decay per day in Decaying state.
    /// @param _resonanceDecayRateStable Resonance decay per day in Stable state.
    /// @param _resonanceDecayRateDecaying Resonance decay per day in Decaying state.
    /// @param _fuseAetherCost Aether cost to fuse.
    /// @param _shatterChrononReturnRate Chronons returned per point of purity/resonance on shatter.
    /// @param _stabilizeAetherCostPerDay Aether cost per day to stabilize.
    /// @param _catalyzeAetherCostPerDay Aether cost per day to catalyze.
    /// @param _sleepAetherCost Aether cost to sleep a core.
    /// @param _awakenAetherCost Aether cost to awaken a core.
    /// @param _chrononToAetherRate Chronon to Aether conversion rate.
    function setParameters(
        uint256 _forgeAetherCostBase,
        uint256 _forgePurityCostFactor,
        uint256 _forgeResonanceCostFactor,
        uint256 _harvestChargeRateBase,
        uint256 _harvestChargeRatePerResonance,
        uint256 _stateDurationNascent,
        uint256 _stateDurationHarmonizing,
        uint256 _stateDurationStable,
        uint256 _purityDecayRateStable,
        uint256 _purityDecayRateDecaying,
        uint256 _resonanceDecayRateStable,
        uint256 _resonanceDecayRateDecaying,
        uint256 _fuseAetherCost,
        uint256 _shatterChrononReturnRate,
        uint256 _stabilizeAetherCostPerDay,
        uint256 _catalyzeAetherCostPerDay,
        uint256 _sleepAetherCost,
        uint256 _awakenAetherCost,
        uint256 _chrononToAetherRate
    ) external onlyOwner {
        // Add validation for parameters if necessary (e.g., rates > 0, durations > 0 for non-terminal states)

        forgeAetherCostBase = _forgeAetherCostBase;
        forgePurityCostFactor = _forgePurityCostFactor;
        forgeResonanceCostFactor = _forgeResonanceCostFactor;

        harvestChargeRateBase = _harvestChargeRateBase;
        harvestChargeRatePerResonance = _harvestChargeRatePerResonance;

        stateDurationNascent = _stateDurationNascent;
        stateDurationHarmonizing = _stateDurationHarmonizing;
        stateDurationStable = _stateDurationStable;

        purityDecayRateStable = _purityDecayRateStable;
        purityDecayRateDecaying = _purityDecayRateDecaying;
        resonanceDecayRateStable = _resonanceDecayRateStable;
        resonanceDecayRateDecaying = _resonanceDecayRateDecaying;

        fuseAetherCost = _fuseAetherCost;
        shatterChrononReturnRate = _shatterChrononReturnRate;

        stabilizeAetherCostPerDay = _stabilizeAetherCostPerDay;
        catalyzeAetherCostPerDay = _catalyzeAetherCostPerDay;
        sleepAetherCost = _sleepAetherCost;
        awakenAetherCost = _awakenAetherCost;

        chrononToAetherRate = _chrononToAetherRate;

        emit ParametersUpdated(msg.sender);
    }

    /// @summary Transfers ownership of the contract.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert QuantumStateFoundry__InvalidParameterValue();
        _owner = newOwner;
        // Standard Ownable would emit OwnershipTransferred event.
    }

    /// @summary Renounces contract ownership.
    /// @dev The contract will have no owner after this.
    function renounceOwnership() external onlyOwner {
        _owner = address(0);
        // Standard Ownable would emit OwnershipTransferred event.
    }

    /// @summary Gets the current owner of the contract.
    function getOwner() external view returns (address) {
        return _owner;
    }
}
```