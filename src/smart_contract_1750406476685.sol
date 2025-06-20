Okay, let's design a smart contract concept around a dynamic, interconnected system, leveraging state changes, resource management, and calculated scores. We'll call it `QuantumEntanglementLink` as a metaphor for complex, linked states.

The core idea is to manage unique "Link Units". These units can be "entangled" with each other, sharing a state influenced by their individual properties (like energy) and the link type. Entanglement requires maintenance (energy), decays over time, and contributes to a unit's "Resonance Score".

This is *not* a standard token contract (like ERC20, ERC721, ERC1155), although units have owners. It's focused on the interaction and state of the units themselves.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntanglementLink
 * @dev A smart contract managing unique 'Link Units' that can be 'entangled' with each other.
 * Entanglement requires energy, decays over time, and influences unit states and a calculated Resonance Score.
 * This contract explores complex state management, timed effects, and dynamic interaction patterns beyond standard token mechanics.
 */

/*
Outline and Function Summary:

I. Contract Administration (Owned by Deployer)
   - setLinkCost(linkType, cost): Set energy cost for a specific link type.
   - setDecayRate(rate): Set the base decay rate for entangled energy.
   - withdrawBalance(): Withdraw any native token sent to the contract (e.g., for failed transactions or future mechanics).

II. Link Unit Management (Ownership-based)
   - mintUnit(): Create a new Link Unit.
   - transferUnitOwnership(unitId, newOwner): Transfer ownership of a unit.
   - burnUnit(unitId): Destroy a Link Unit.
   - injectEnergy(unitId, amount): Add energy to a unit.
   - transferEnergyBetweenLinkedUnits(fromUnitId, toUnitId, amount): Transfer energy between two units IF they are entangled.
   - quarantineUnit(unitId): Temporarily disable a unit from linking/transferring.
   - releaseUnit(unitId): Remove quarantine from a unit.

III. Entanglement Mechanics
   - proposeLink(fromUnitId, toUnitId, linkType): Initiate a link proposal from one unit to another. Requires recipient acceptance.
   - acceptLinkProposal(toUnitId, fromUnitId): Accept a pending link proposal, creating the entanglement. Consumes energy.
   - breakLink(unitId): Break an existing entanglement from the perspective of the calling unit's owner. Consumes energy penalty.
   - mutateLinkType(unitId, newLinkType): Change the type of an existing link. Consumes energy.
   - autoReinforceLink(unitId): Automatically consume energy from the unit to counteract decay for a period.

IV. State Updates and Maintenance (Permissionless, potentially incentivizable externally)
   - decayEntanglement(): Processes energy decay for all currently entangled units based on time elapsed. Anyone can call this. (Note: Could be gas-intensive with many units; a batching mechanism would be needed in production).

V. Information & Query (View Functions)
   - getUnitDetails(unitId): Get all details of a specific unit.
   - getTotalUnits(): Get the total number of units minted.
   - checkEntanglementStatus(unitId): Check if a unit is currently entangled.
   - getLinkedUnit(unitId): Get the ID of the unit it's linked to, if any.
   - calculateResonance(unitId): Calculate the dynamic Resonance Score for a unit based on its state.
   - getLinkCost(linkType): Get the current energy cost for a specific link type.
   - getDecayRate(): Get the current base decay rate.
   - getLastDecayTimestamp(): Get the timestamp of the last decay calculation.
   - getLinkProposal(fromUnitId, toUnitId): Check details of a pending link proposal.
   - findHighestResonancePair(): Finds an unlinked pair of units with the highest combined *potential* resonance (based on individual scores). Note: Simple heuristic, potentially gas-heavy.

VI. Internal Helpers (Private/Internal Functions and Modifiers)
   - _updateUnitState: Internal logic for changing unit state.
   - _applyDecay: Internal logic for calculating and applying energy decay to a unit.
   - onlyUnitOwner: Modifier to restrict functions to the unit's owner.
   - unitExists: Modifier to check if a unit ID is valid.
   - unitIsNotQuarantined: Modifier to check if a unit is not quarantined.
   - unitIsntLinked: Modifier to check if a unit is not currently entangled.
   - unitIsLinked: Modifier to check if a unit IS currently entangled.
   - unitsAreLinked: Modifier to check if two *specific* units are linked to each other.
*/

// Enums for better state management
enum UnitState {
    Idle,          // Not entangled
    ProposingLink, // Has proposed a link to another unit
    ReceivingLink, // Has received a link proposal from another unit
    Entangled,     // Actively linked to another unit
    Decaying,      // Entangled, but energy is critically low/decaying faster
    Quarantined    // Temporarily disabled
}

enum LinkType {
    Basic,         // Standard link
    Synergetic,    // Provides a small energy bonus
    Resonant,      // Amplifies resonance score
    Volatile       // Higher decay rate, potentially higher reward/penalty on break (conceptually)
}

struct LinkUnit {
    uint256 id;
    address owner;
    uint64 creationTime; // Timestamp of creation
    uint128 energyLevel; // Current energy stored in the unit
    UnitState state;
    uint256 linkedUnitId; // ID of the unit it's linked to (0 if not linked)
    LinkType linkType;    // Type of the current link (if state is Entangled)
    uint64 lastStateChangeTime; // Timestamp of the last state change (useful for decay calculation)
    bool isQuarantined;
}

struct LinkProposal {
    uint256 fromUnitId;
    uint256 toUnitId;
    LinkType linkType;
    uint64 proposalTime;
    bool exists; // To check if a proposal exists in the mapping
}

// Error messages
error UnitNotFound(uint256 unitId);
error NotUnitOwner(uint256 unitId, address caller);
error InvalidUnitState(uint256 unitId, UnitState currentState, string expectedCondition);
error UnitAlreadyLinked(uint256 unitId);
error UnitNotLinked(uint256 unitId);
error UnitsNotLinkedToEachOther(uint256 unitIdA, uint256 unitIdB);
error InsufficientEnergy(uint256 unitId, uint128 currentEnergy, uint128 requiredEnergy);
error LinkProposalNotFound(uint256 fromUnitId, uint256 toUnitId);
error ProposalTargetMismatch(uint256 expectedTargetId, uint256 actualTargetId);
error UnitIsQuarantined(uint256 unitId);
error InvalidLinkType(uint8 linkType);
error InvalidTransferAmount();
error NoUnitsExist();
error NothingToWithdraw();


contract QuantumEntanglementLink {
    address public owner; // Contract deployer

    uint256 private _unitCounter; // Counter for unique unit IDs
    mapping(uint256 => LinkUnit) public units; // Store unit data by ID
    mapping(address => uint256[]) public ownerUnits; // Store unit IDs owned by an address (simplified list, not exhaustive for performance with many units)

    // Pending link proposals: mapping from proposer unit ID => target unit ID => proposal details
    mapping(uint256 => mapping(uint256 => LinkProposal)) private _pendingLinkProposals;

    // Configuration parameters
    mapping(uint8 => uint256) public linkCosts; // Energy cost to establish a link (indexed by LinkType enum value)
    uint256 public entanglementDecayRate = 1; // Base energy decay rate per second for entangled units
    uint256 public constant BREAK_LINK_ENERGY_PENALTY_PERCENT = 10; // % energy lost on break
    uint256 public constant BASE_RESONANCE_SCORE = 100; // Base score for any unit
    uint128 public constant MAX_ENERGY = type(uint128).max; // Maximum energy a unit can hold

    uint64 public lastDecayRunTimestamp; // Timestamp when decayEntanglement was last executed

    event UnitMinted(uint256 indexed unitId, address indexed owner, uint64 creationTime);
    event UnitBurned(uint255 indexed unitId, address indexed owner);
    event UnitTransferred(uint256 indexed unitId, address indexed from, address indexed to);
    event EnergyInjected(uint256 indexed unitId, uint128 amount, uint128 newEnergy);
    event EnergyTransferred(uint256 indexed fromUnitId, uint256 indexed toUnitId, uint128 amount);
    event LinkProposalCreated(uint256 indexed fromUnitId, uint256 indexed toUnitId, LinkType linkType);
    event LinkProposalCancelled(uint256 indexed fromUnitId, uint256 indexed toUnitId);
    event LinkAccepted(uint256 indexed unitIdA, uint256 indexed unitIdB, LinkType linkType);
    event LinkBroken(uint256 indexed unitIdA, uint256 indexed unitIdB); // Emitted from the perspective of the unit triggering the break
    event EntanglementDecayed(uint256 indexed unitId, uint128 energyLost, uint128 newEnergy);
    event LinkTypeMutated(uint256 indexed unitId, LinkType oldType, LinkType newType);
    event UnitQuarantined(uint256 indexed unitId);
    event UnitReleased(uint256 indexed unitId);
    event LinkCostUpdated(LinkType indexed linkType, uint256 newCost);
    event DecayRateUpdated(uint256 newRate);
    event ContractBalanceWithdrawn(address indexed to, uint256 amount);

    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotUnitOwner(0, msg.sender); // Using 0 as unitId placeholder for contract owner
        _;
    }

    modifier unitExists(uint256 unitId) {
        if (units[unitId].id == 0 && _unitCounter < unitId) revert UnitNotFound(unitId); // Check if ID exists and is <= counter
        _;
    }

    modifier onlyUnitOwner(uint256 unitId) {
        if (units[unitId].owner != msg.sender) revert NotUnitOwner(unitId, msg.sender);
        _;
    }

    modifier unitIsNotQuarantined(uint256 unitId) {
        if (units[unitId].isQuarantined) revert UnitIsQuarantined(unitId);
        _;
    }

    modifier unitIsntLinked(uint256 unitId) {
        if (units[unitId].state == UnitState.Entangled || units[unitId].state == UnitState.ProposingLink || units[unitId].state == UnitState.ReceivingLink) revert UnitAlreadyLinked(unitId);
        _;
    }

    modifier unitIsLinked(uint256 unitId) {
        if (units[unitId].state != UnitState.Entangled) revert UnitNotLinked(unitId);
        _;
    }

    modifier unitsAreLinked(uint256 unitIdA, uint256 unitIdB) {
        if (units[unitIdA].state != UnitState.Entangled || units[unitIdB].state != UnitState.Entangled || units[unitIdA].linkedUnitId != unitIdB || units[unitIdB].linkedUnitId != unitIdA) {
             revert UnitsNotLinkedToEachOther(unitIdA, unitIdB);
        }
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        _unitCounter = 0;
        lastDecayRunTimestamp = uint64(block.timestamp);

        // Set default link costs
        linkCosts[uint8(LinkType.Basic)] = 100;
        linkCosts[uint8(LinkType.Synergetic)] = 150;
        linkCosts[uint8(LinkType.Resonant)] = 200;
        linkCosts[uint8(LinkType.Volatile)] = 300;
    }

    // --- Admin Functions ---

    /**
     * @notice Sets the energy cost required to establish a specific type of link.
     * @param linkType The type of link (as uint8 enum value).
     * @param cost The energy cost.
     */
    function setLinkCost(uint8 linkType, uint256 cost) external onlyOwner {
        if (linkType >= uint8(LinkType.Volatile) + 1) revert InvalidLinkType(linkType); // Basic range check
        linkCosts[linkType] = cost;
        emit LinkCostUpdated(LinkType(linkType), cost);
    }

    /**
     * @notice Sets the base rate at which energy decays for entangled units per second.
     * @param rate The new decay rate.
     */
    function setDecayRate(uint256 rate) external onlyOwner {
        entanglementDecayRate = rate;
        emit DecayRateUpdated(rate);
    }

    /**
     * @notice Allows the contract owner to withdraw any native token sent to the contract.
     */
    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NothingToWithdraw();
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Withdrawal failed");
        emit ContractBalanceWithdrawn(owner, balance);
    }

    // --- Link Unit Management ---

    /**
     * @notice Mints a new Link Unit and assigns ownership to the caller.
     * @return The ID of the newly minted unit.
     */
    function mintUnit() external returns (uint256) {
        _unitCounter++;
        uint255 newUnitId = uint255(_unitCounter); // Use uint255 for safety against potential overflow related to type(uint256).max, although unlikely with simple counter

        units[newUnitId] = LinkUnit({
            id: newUnitId,
            owner: msg.sender,
            creationTime: uint64(block.timestamp),
            energyLevel: 0, // Starts with zero energy
            state: UnitState.Idle,
            linkedUnitId: 0,
            linkType: LinkType.Basic, // Default type
            lastStateChangeTime: uint64(block.timestamp),
            isQuarantined: false
        });

        // Simplified ownerUnits update (might not be exhaustive, requires off-chain tracking for scalability)
        ownerUnits[msg.sender].push(newUnitId);

        emit UnitMinted(newUnitId, msg.sender, uint64(block.timestamp));
        return newUnitId;
    }

    /**
     * @notice Transfers ownership of a Link Unit.
     * @param unitId The ID of the unit to transfer.
     * @param newOwner The address of the new owner.
     */
    function transferUnitOwnership(uint256 unitId, address newOwner)
        external
        unitExists(unitId)
        onlyUnitOwner(unitId)
    {
        address oldOwner = units[unitId].owner;
        units[unitId].owner = newOwner;

        // Simplified ownerUnits update (requires off-chain tracking for full list)
        // In a real ERC721, you'd manage arrays/mappings more carefully.
        // We won't remove from old owner's array here for simplicity, highlighting limitation.
        ownerUnits[newOwner].push(unitId);

        emit UnitTransferred(unitId, oldOwner, newOwner);
    }


    /**
     * @notice Burns (destroys) a Link Unit. Requires the unit to be idle (not linked or proposing).
     * @param unitId The ID of the unit to burn.
     */
    function burnUnit(uint256 unitId)
        external
        unitExists(unitId)
        onlyUnitOwner(unitId)
        unitIsntLinked(unitId)
        unitIsNotQuarantined(unitId)
    {
        address unitOwner = units[unitId].owner;
        delete units[unitId]; // Remove unit data

        // Simplified ownerUnits update (requires off-chain tracking for full list)
        // Removing from array is gas intensive, skipping for this example.

        emit UnitBurned(unitId, unitOwner);
    }

    /**
     * @notice Injects energy into a specific Link Unit.
     * @param unitId The ID of the unit.
     * @param amount The amount of energy to inject.
     */
    function injectEnergy(uint256 unitId, uint128 amount)
        external
        unitExists(unitId)
        onlyUnitOwner(unitId)
        unitIsNotQuarantined(unitId)
    {
        // Prevent overflow by checking if current energy plus amount exceeds MAX_ENERGY
        uint128 newEnergy = units[unitId].energyLevel;
        if (newEnergy > MAX_ENERGY - amount) {
             newEnergy = MAX_ENERGY; // Cap at max
        } else {
            newEnergy += amount;
        }

        // Apply decay *before* injecting if entangled and hasn't decayed recently
        if (units[unitId].state == UnitState.Entangled) {
             _applyDecay(unitId); // Apply decay up to current time
        }

        units[unitId].energyLevel = newEnergy;
        emit EnergyInjected(unitId, amount, units[unitId].energyLevel);
    }

     /**
     * @notice Transfers energy from one unit to another, but ONLY if they are actively entangled.
     * @param fromUnitId The ID of the unit sending energy.
     * @param toUnitId The ID of the unit receiving energy.
     * @param amount The amount of energy to transfer.
     */
    function transferEnergyBetweenLinkedUnits(uint256 fromUnitId, uint256 toUnitId, uint128 amount)
        external
        unitExists(fromUnitId)
        unitExists(toUnitId)
        onlyUnitOwner(fromUnitId) // Caller must own the sending unit
        unitIsNotQuarantined(fromUnitId)
        unitIsNotQuarantined(toUnitId)
        unitsAreLinked(fromUnitId, toUnitId) // Ensure they are entangled with each other
    {
        if (amount == 0) revert InvalidTransferAmount();
        if (units[fromUnitId].energyLevel < amount) revert InsufficientEnergy(fromUnitId, units[fromUnitId].energyLevel, amount);

        // Apply decay before transfer
        _applyDecay(fromUnitId);
        _applyDecay(toUnitId);

        units[fromUnitId].energyLevel -= amount;
        // Prevent overflow on receiver
        uint128 receiverEnergy = units[toUnitId].energyLevel;
         if (receiverEnergy > MAX_ENERGY - amount) {
             receiverEnergy = MAX_ENERGY;
         } else {
             receiverEnergy += amount;
         }
        units[toUnitId].energyLevel = receiverEnergy;

        emit EnergyTransferred(fromUnitId, toUnitId, amount);
        // Could potentially trigger state changes if sender energy drops too low
        _updateUnitState(fromUnitId);
        _updateUnitState(toUnitId);
    }

    /**
     * @notice Temporarily quarantines a unit, preventing linking actions and transfers.
     * @param unitId The ID of the unit to quarantine.
     */
    function quarantineUnit(uint256 unitId)
        external
        unitExists(unitId)
        onlyUnitOwner(unitId)
    {
        if (units[unitId].isQuarantined) return; // Already quarantined
        if (units[unitId].state == UnitState.Entangled) {
             // Breaking the link upon quarantine is a design choice.
             // Here, let's allow quarantine *only* if idle.
             revert InvalidUnitState(unitId, units[unitId].state, "must be Idle to quarantine");
        }

        _updateUnitState(unitId, UnitState.Quarantined);
        units[unitId].isQuarantined = true;
        emit UnitQuarantined(unitId);
    }

    /**
     * @notice Releases a quarantined unit, returning it to Idle state.
     * @param unitId The ID of the unit to release.
     */
    function releaseUnit(uint256 unitId)
        external
        unitExists(unitId)
        onlyUnitOwner(unitId)
    {
        if (!units[unitId].isQuarantined) return; // Not quarantined

        units[unitId].isQuarantined = false;
        _updateUnitState(unitId, UnitState.Idle); // Return to Idle state
        emit UnitReleased(unitId);
    }


    // --- Entanglement Mechanics ---

    /**
     * @notice Proposes a link from the calling unit to another unit. Requires the target unit's owner to accept.
     * @param fromUnitId The ID of the unit proposing the link.
     * @param toUnitId The ID of the unit receiving the proposal.
     * @param linkType The desired type of the link.
     */
    function proposeLink(uint256 fromUnitId, uint256 toUnitId, LinkType linkType)
        external
        unitExists(fromUnitId)
        unitExists(toUnitId)
        onlyUnitOwner(fromUnitId)
        unitIsNotQuarantined(fromUnitId)
        unitIsNotQuarantined(toUnitId)
        unitIsntLinked(fromUnitId) // Proposer must be idle
        unitIsntLinked(toUnitId) // Target must be idle
    {
        if (fromUnitId == toUnitId) revert InvalidUnitState(fromUnitId, units[fromUnitId].state, "cannot link to self");

        // Check if a proposal already exists between these two (in either direction)
        if (_pendingLinkProposals[fromUnitId][toUnitId].exists || _pendingLinkProposals[toUnitId][fromUnitId].exists) {
            revert InvalidUnitState(fromUnitId, units[fromUnitId].state, "existing proposal pending");
        }

        _pendingLinkProposals[fromUnitId][toUnitId] = LinkProposal({
            fromUnitId: fromUnitId,
            toUnitId: toUnitId,
            linkType: linkType,
            proposalTime: uint64(block.timestamp),
            exists: true
        });

        _updateUnitState(fromUnitId, UnitState.ProposingLink);
        _updateUnitState(toUnitId, UnitState.ReceivingLink);

        emit LinkProposalCreated(fromUnitId, toUnitId, linkType);
    }

    /**
     * @notice Cancels a pending link proposal initiated by the caller's unit.
     * @param fromUnitId The ID of the unit that made the proposal.
     * @param toUnitId The ID of the unit that received the proposal.
     */
    function cancelLinkProposal(uint256 fromUnitId, uint256 toUnitId)
        external
        unitExists(fromUnitId)
        unitExists(toUnitId)
        onlyUnitOwner(fromUnitId) // Only the proposer can cancel
        unitIsNotQuarantined(fromUnitId)
    {
        LinkProposal storage proposal = _pendingLinkProposals[fromUnitId][toUnitId];
        if (!proposal.exists) revert LinkProposalNotFound(fromUnitId, toUnitId);
        if (proposal.fromUnitId != fromUnitId || proposal.toUnitId != toUnitId) revert ProposalTargetMismatch(toUnitId, proposal.toUnitId); // Should match map keys

        // Restore states if they were changed to Proposing/Receiving
        if (units[fromUnitId].state == UnitState.ProposingLink && units[fromUnitId].linkedUnitId == toUnitId) { // Check linkedUnitId temporarily stores target during proposal
             _updateUnitState(fromUnitId, UnitState.Idle);
        }
         if (units[toUnitId].state == UnitState.ReceivingLink && units[toUnitId].linkedUnitId == fromUnitId) { // Check linkedUnitId temporarily stores proposer during proposal
             _updateUnitState(toUnitId, UnitState.Idle);
         }


        delete _pendingLinkProposals[fromUnitId][toUnitId];

        emit LinkProposalCancelled(fromUnitId, toUnitId);
    }


    /**
     * @notice Accepts a pending link proposal, creating an entanglement between two units.
     * Requires the owner of the target unit to call this. Consumes energy from BOTH units.
     * @param toUnitId The ID of the unit accepting the proposal (owned by caller).
     * @param fromUnitId The ID of the unit that made the proposal.
     */
    function acceptLinkProposal(uint256 toUnitId, uint256 fromUnitId)
        external
        unitExists(toUnitId)
        unitExists(fromUnitId)
        onlyUnitOwner(toUnitId) // Caller must own the unit accepting
        unitIsNotQuarantined(toUnitId)
        unitIsNotQuarantined(fromUnitId)
        unitIsntLinked(toUnitId) // Acceptor must be idle/receiving
        unitIsntLinked(fromUnitId) // Proposer must be idle/proposing
    {
        LinkProposal storage proposal = _pendingLinkProposals[fromUnitId][toUnitId];
        if (!proposal.exists) revert LinkProposalNotFound(fromUnitId, toUnitId);

        uint256 requiredEnergy = linkCosts[uint8(proposal.linkType)];
        if (units[fromUnitId].energyLevel < requiredEnergy) revert InsufficientEnergy(fromUnitId, units[fromUnitId].energyLevel, uint128(requiredEnergy));
        if (units[toUnitId].energyLevel < requiredEnergy) revert InsufficientEnergy(toUnitId, units[toUnitId].energyLevel, uint128(requiredEnergy));

        // Consume energy
        units[fromUnitId].energyLevel -= uint128(requiredEnergy);
        units[toUnitId].energyLevel -= uint128(requiredEnergy);

        // Establish the link
        units[fromUnitId].linkedUnitId = toUnitId;
        units[toUnitId].linkedUnitId = fromUnitId;
        units[fromUnitId].linkType = proposal.linkType; // Set link type on both ends
        units[toUnitId].linkType = proposal.linkType;

        // Update states
        _updateUnitState(fromUnitId, UnitState.Entangled);
        _updateUnitState(toUnitId, UnitState.Entangled);

        // Clean up proposal
        delete _pendingLinkProposals[fromUnitId][toUnitId];

        emit LinkAccepted(fromUnitId, toUnitId, proposal.linkType);
    }

    /**
     * @notice Breaks an existing entanglement for a unit. Consumes energy penalty.
     * @param unitId The ID of the unit breaking the link.
     */
    function breakLink(uint256 unitId)
        external
        unitExists(unitId)
        onlyUnitOwner(unitId)
        unitIsNotQuarantined(unitId)
        unitIsLinked(unitId) // Must be entangled
    {
        uint256 linkedId = units[unitId].linkedUnitId;
        if (linkedId == 0 || units[linkedId].linkedUnitId != unitId) {
             // Should be caught by unitIsLinked, but double check consistency
             revert UnitNotLinked(unitId);
        }

        // Apply decay before calculating penalty
        _applyDecay(unitId);
        _applyDecay(linkedId);

        // Apply energy penalty
        uint128 penaltyAmount = units[unitId].energyLevel * uint128(BREAK_LINK_ENERGY_PENALTY_PERCENT) / 100;
        units[unitId].energyLevel = units[unitId].energyLevel >= penaltyAmount ? units[unitId].energyLevel - penaltyAmount : 0;

        // Break the link on both sides
        units[unitId].linkedUnitId = 0;
        units[linkedId].linkedUnitId = 0;

        // Reset states
        _updateUnitState(unitId, UnitState.Idle);
        _updateUnitState(linkedId, UnitState.Idle); // The other unit becomes Idle too

        emit LinkBroken(unitId, linkedId);
    }

    /**
     * @notice Mutates the type of an existing link. Consumes energy based on the new type cost difference.
     * @param unitId The ID of one of the entangled units.
     * @param newLinkType The desired new type for the link.
     */
    function mutateLinkType(uint256 unitId, LinkType newLinkType)
        external
        unitExists(unitId)
        onlyUnitOwner(unitId) // Only one owner needs to initiate mutation
        unitIsNotQuarantined(unitId)
        unitIsLinked(unitId) // Must be entangled
    {
        uint256 linkedId = units[unitId].linkedUnitId;
        LinkType oldLinkType = units[unitId].linkType;

        if (oldLinkType == newLinkType) return; // No change needed

        uint256 oldCost = linkCosts[uint8(oldLinkType)];
        uint256 newCost = linkCosts[uint8(newLinkType)];

        // Calculate energy cost/gain
        // If new type is more expensive, cost is difference. If less, might get some energy back (or just no cost)
        uint256 costDifference = 0;
        if (newCost > oldCost) {
            costDifference = newCost - oldCost;
        } else {
            // Mutating to a less expensive link type is free (or could potentially grant energy,
            // but let's keep it simple and just make it free).
        }

        // Apply decay before calculating costs
        _applyDecay(unitId);
        _applyDecay(linkedId);

        // Check energy for cost difference (apply to both units?) Let's apply to initiator only for simplicity.
        if (units[unitId].energyLevel < costDifference) revert InsufficientEnergy(unitId, units[unitId].energyLevel, uint128(costDifference));
        units[unitId].energyLevel -= uint128(costDifference);


        // Update link type on both sides
        units[unitId].linkType = newLinkType;
        units[linkedId].linkType = newLinkType;

        // Update state if needed (e.g., if energy drops below threshold)
        _updateUnitState(unitId);
        _updateUnitState(linkedId);

        emit LinkTypeMutated(unitId, oldLinkType, newLinkType);
    }

    /**
     * @notice Allows a unit's owner to spend energy from the unit to automatically counteract decay
     * for a specific duration or energy amount (let's use a simple energy amount here).
     * Consumes energy immediately.
     * @param unitId The ID of the unit to reinforce.
     * @param energyToSpend The amount of energy to spend on reinforcement.
     */
    function autoReinforceLink(uint256 unitId, uint128 energyToSpend)
        external
        unitExists(unitId)
        onlyUnitOwner(unitId)
        unitIsNotQuarantined(unitId)
        unitIsLinked(unitId) // Must be entangled to reinforce the link
    {
         if (energyToSpend == 0) revert InvalidTransferAmount(); // Reusing error for zero check
         if (units[unitId].energyLevel < energyToSpend) revert InsufficientEnergy(unitId, units[unitId].energyLevel, energyToSpend);

         // Apply decay before reinforcing
         _applyDecay(unitId);
         _applyDecay(units[unitId].linkedUnitId);

         units[unitId].energyLevel -= energyToSpend;

         // Conceptually, this energy reinforces the link.
         // It could add to the linked unit's energy, or a pool, or just vanish.
         // Let's have it add to the linked unit's energy (capped).
         uint256 linkedId = units[unitId].linkedUnitId;
         uint128 reinforcedEnergy = units[linkedId].energyLevel;
          if (reinforcedEnergy > MAX_ENERGY - energyToSpend) {
             reinforcedEnergy = MAX_ENERGY;
         } else {
             reinforcedEnergy += energyToSpend;
         }
         units[linkedId].energyLevel = reinforcedEnergy;


         // Update states if energy levels changed significantly
         _updateUnitState(unitId);
         _updateUnitState(linkedId);

         // No specific event for auto-reinforce, EnergyTransferred could be used, or a new event.
         // Let's use EnergyTransferred conceptually here, from unitId to linkedId.
         emit EnergyTransferred(unitId, linkedId, energyToSpend);
    }


    // --- State Updates and Maintenance ---

    /**
     * @notice Processes energy decay for all currently entangled units.
     * Can be called by anyone to help maintain the system.
     * (Note: Iterating over all units can be gas-intensive. A production system might use iteration keys,
     * a limited batch size, or external keepers.) This simple implementation iterates through the units map.
     * It updates the last decay run timestamp upon successful execution.
     */
    function decayEntanglement() external {
        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsed = currentTime - lastDecayRunTimestamp;

        // If negligible time passed, or no decay rate, do nothing.
        if (timeElapsed == 0 || entanglementDecayRate == 0) {
             lastDecayRunTimestamp = currentTime; // Still update timestamp to avoid large jump later
             return;
        }

        // Iterate through potentially existing unit IDs up to the counter.
        // This loop can be a major gas sink for many units.
        for (uint256 i = 1; i <= _unitCounter; i++) {
            // Check if unit exists and is entangled or decaying
            if (units[i].id != 0 && (units[i].state == UnitState.Entangled || units[i].state == UnitState.Decaying)) {
                // Only apply decay if its last state change was before the *last* decay run timestamp
                // This ensures we don't over-decay units that changed state recently AFTER the last global decay run
                // and before the *current* run.
                // Or, simply calculate decay since unit's lastStateChangeTime, capped by timeElapsed.
                // Let's use the latter for more granular decay per unit.
                 _applyDecay(i);
            }
        }

        lastDecayRunTimestamp = currentTime; // Record when this run finished
    }

    /**
     * @dev Internal function to apply energy decay to a single unit based on time elapsed since its last state change.
     * Updates unit's energy and state.
     * @param unitId The ID of the unit to decay.
     */
    function _applyDecay(uint256 unitId) internal {
        // Ensure the unit is in a state where decay applies
        if (units[unitId].state != UnitState.Entangled && units[unitId].state != UnitState.Decaying) {
            // Should not happen if called correctly, but good defensive check
            return;
        }

        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsedSinceLastUpdate = currentTime - units[unitId].lastStateChangeTime;

        // Calculate decay amount
        // Decay is per second, affected by link type (e.g., Volatile has higher rate)
        uint256 effectiveDecayRate = entanglementDecayRate;
        if (units[unitId].linkType == LinkType.Volatile) {
            effectiveDecayRate = effectiveDecayRate * 2; // Example: Volatile decays twice as fast
        }
        // Could add multipliers for other link types or unit properties

        uint128 energyLoss = uint128(timeElapsedSinceLastUpdate * effectiveDecayRate);

        uint128 oldEnergy = units[unitId].energyLevel;
        uint128 newEnergy;

        if (oldEnergy <= energyLoss) {
            newEnergy = 0;
            // If energy drops to 0, break the link automatically
            uint256 linkedId = units[unitId].linkedUnitId;
            if (linkedId != 0) {
                units[unitId].linkedUnitId = 0;
                units[linkedId].linkedUnitId = 0;
                 _updateUnitState(unitId, UnitState.Idle);
                _updateUnitState(linkedId, UnitState.Idle);
                 // No penalty on auto-break from decay
                 emit LinkBroken(unitId, linkedId); // Still emit event
            } else {
                // Should already be Idle if not linked, but set to Idle if somehow decaying but not linked
                 _updateUnitState(unitId, UnitState.Idle);
            }
        } else {
            newEnergy = oldEnergy - energyLoss;
             _updateUnitState(unitId); // Update state based on new energy level (e.g., to Decaying)
        }

        units[unitId].energyLevel = newEnergy;
        units[unitId].lastStateChangeTime = currentTime; // Update timestamp for this unit

        if (energyLoss > 0) {
            emit EntanglementDecayed(unitId, energyLoss, newEnergy);
        }
    }

    /**
     * @dev Internal function to update a unit's state based on its energy level and current links.
     * Called after actions that change energy or link status.
     * @param unitId The ID of the unit to update.
     */
    function _updateUnitState(uint256 unitId) internal {
         // Apply decay first to get current energy level based on time
         if (units[unitId].state == UnitState.Entangled || units[unitId].state == UnitState.Decaying) {
             _applyDecay(unitId); // Ensure energy is up-to-date
         }

         UnitState currentState = units[unitId].state;
         UnitState newState = currentState;

         if (units[unitId].isQuarantined) {
             newState = UnitState.Quarantined;
         } else if (units[unitId].linkedUnitId != 0) {
              // Linked units
             if (units[unitId].energyLevel == 0) {
                 // Should have been handled by _applyDecay setting to Idle, but double check
                 newState = UnitState.Idle;
             } else if (units[unitId].energyLevel < 50) { // Example threshold for Decaying state
                 newState = UnitState.Decaying;
             } else {
                 newState = UnitState.Entangled;
             }
         } else {
             // Not linked, check proposal status
             bool isProposing = _pendingLinkProposals[unitId][units[unitId].linkedUnitId].exists; // linkedUnitId is 0 if idle
             bool isReceiving = false;
             // Checking all incoming proposals is inefficient. A separate mapping for incoming proposals is better.
             // For this example, we rely on the linkedUnitId being temporarily set during proposal state.
             // This is a simplification/potential bug source; a proper proposal mapping would be better.
             // Let's stick to the simplified model where linkedUnitId is used temporarily.
             // When Proposing/Receiving, linkedUnitId points to the target/proposer.

             if (currentState == UnitState.ProposingLink) {
                 // Check if the proposal still exists in the mapping
                 if (_pendingLinkProposals[unitId][units[unitId].linkedUnitId].exists) {
                     newState = UnitState.ProposingLink;
                 } else {
                     // Proposal cancelled externally or accepted
                     newState = UnitState.Idle; // Revert to idle if proposal is gone
                 }
             } else if (currentState == UnitState.ReceivingLink) {
                  // Need to find the proposer's ID. This requires iterating or a reverse map.
                  // For now, assume the linkedUnitId temp storage works and check if proposal exists.
                  // This is a weak point in the simplified state model. Let's refine the proposal struct.
                  // Proposal struct now has from/to. Let's iterate through *potential* proposers to this unit.
                  // This is also inefficient. A better approach for state update would be:
                  // 1. Actions (propose, accept, break) set the state directly.
                  // 2. Decay handler sets to Idle if energy drops to 0.
                  // 3. Keep this function simple, maybe just for Decaying threshold.

                  // Let's revise: UnitState enum reflects the *primary* status.
                  // Proposing/Receiving is handled by the `_pendingLinkProposals` mapping, not the main state.
                  // The main state is Idle, Entangled, Decaying, Quarantined.
                  // We only transition to Decaying based on energy while Entangled.
                  // BreakLink/AcceptLink/Burn/Quarantine/Release handle Idle/Entangled/Quarantined.

                  // Revised State Update Logic:
                 if (units[unitId].linkedUnitId != 0) { // Is Entangled
                     if (units[unitId].energyLevel < 50 && units[unitId].energyLevel > 0) { // Example threshold
                         newState = UnitState.Decaying;
                     } else if (units[unitId].energyLevel == 0) {
                          newState = UnitState.Idle; // Link broken by decay
                     }
                     // Stays Entangled otherwise
                 } else { // Is Idle (not linked)
                      // Check if currently in a proposal state that should be cleared
                     if (currentState == UnitState.ProposingLink || currentState == UnitState.ReceivingLink) {
                         // This indicates a proposal state wasn't fully cleaned up.
                         // This state transition logic is complex with the current structure.
                         // Let's simplify: Proposing/Receiving states *are* part of the enum,
                         // and unit.linkedUnitId *does* store the temporary partner ID during proposal.
                         // We check the *mapping* for the proposal's existence.
                         bool proposalExists = _pendingLinkProposals[units[unitId].id][units[unitId].linkedUnitId].exists;
                         if (currentState == UnitState.ProposingLink && !proposalExists) newState = UnitState.Idle;
                         // Checking for incoming proposals efficiently is hard without reverse mapping.
                         // Let's skip automatically reverting Receiving state to Idle here. It relies on cancel/accept.
                         // Or, on any state update, clear pending proposals involving this unit if its state isn't Proposing/Receiving.
                         // This is getting complex. Let's keep the original simplified state enum but acknowledge the complexity of managing proposal states cleanly.
                         // The _pendingLinkProposals mapping is the source of truth for proposals. Unit state is secondary indicator.
                     }
                     // If not linked and not in a pending proposal state, stays Idle.
                     // Quarantined overrides everything else.
                     if (units[unitId].isQuarantined) newState = UnitState.Quarantined;
                 }

                 // Final State Determination based on Link/Quarantine status + Energy if linked
                 if (units[unitId].isQuarantined) {
                     newState = UnitState.Quarantined;
                 } else if (units[unitId].linkedUnitId != 0) { // Linked
                     if (units[unitId].energyLevel == 0) newState = UnitState.Idle; // Should be broken by decay
                     else if (units[unitId].energyLevel < 50) newState = UnitState.Decaying;
                     else newState = UnitState.Entangled;
                 } else { // Not Linked
                      // Check for proposals - relies on linkedUnitId temp storage during proposal
                      if (currentState == UnitState.ProposingLink && _pendingLinkProposals[units[unitId].id][units[unitId].linkedUnitId].exists) {
                          newState = UnitState.ProposingLink;
                      } else if (currentState == UnitState.ReceivingLink) {
                           // Need to check if any proposal is pointing *to* this unit. Inefficient without reverse map.
                           // Let's rely on accept/cancel to clear the proposal state. If they don't happen, unit stays in RecevingLink state indefinitely.
                           // This is a known simplification for this example contract.
                           newState = UnitState.ReceivingLink; // Stays Receiving unless accepted/cancelled
                      } else {
                          newState = UnitState.Idle;
                      }
                 }
         }


        if (newState != currentState) {
            units[unitId].state = newState;
            units[unitId].lastStateChangeTime = uint64(block.timestamp); // Update timestamp on *any* state change
        }
    }


    /**
     * @dev Internal function to set a unit's state explicitly and update timestamp.
     * Use this for state transitions initiated by functions (mint, break, accept, quarantine, release).
     * @param unitId The ID of the unit.
     * @param newState The state to set.
     */
    function _updateUnitState(uint256 unitId, UnitState newState) internal {
         // Apply decay *before* state change if relevant
        if ((units[unitId].state == UnitState.Entangled || units[unitId].state == UnitState.Decaying) && (newState != UnitState.Entangled && newState != UnitState.Decaying)) {
             _applyDecay(unitId); // Apply final decay upon leaving entangled/decaying state
         }

        // Handle specific transitions clearing state
        if (newState == UnitState.Idle || newState == UnitState.Quarantined) {
            units[unitId].linkedUnitId = 0; // Ensure linkedId is 0 if becoming Idle/Quarantined
            units[unitId].linkType = LinkType.Basic; // Reset link type
        } else if (newState == UnitState.ProposingLink) {
             // linkedUnitId must be set to the target unit ID by the calling function (proposeLink)
        } else if (newState == UnitState.ReceivingLink) {
             // linkedUnitId must be set to the proposer unit ID by the calling function (proposeLink target)
        } else if (newState == UnitState.Entangled) {
             // linkedUnitId and linkType must be set by the calling function (acceptLinkProposal, mutateLinkType)
        }


        units[unitId].state = newState;
        units[unitId].lastStateChangeTime = uint64(block.timestamp);
    }


    // --- Information & Query Functions ---

    /**
     * @notice Gets the full details of a Link Unit.
     * @param unitId The ID of the unit.
     * @return A tuple containing all unit properties.
     */
    function getUnitDetails(uint256 unitId)
        external
        view
        unitExists(unitId)
        returns (uint256 id, address owner, uint64 creationTime, uint128 energyLevel, UnitState state, uint256 linkedUnitId, LinkType linkType, uint64 lastStateChangeTime, bool isQuarantined)
    {
        LinkUnit storage unit = units[unitId];
        return (
            unit.id,
            unit.owner,
            unit.creationTime,
            unit.energyLevel,
            unit.state,
            unit.linkedUnitId,
            unit.linkType,
            unit.lastStateChangeTime,
            unit.isQuarantined
        );
    }

     /**
     * @notice Gets the total number of units that have been minted.
     * @return The total unit count.
     */
    function getTotalUnits() external view returns (uint256) {
        return _unitCounter;
    }

    /**
     * @notice Checks if a unit is currently entangled (in Entangled or Decaying state).
     * @param unitId The ID of the unit.
     * @return True if entangled or decaying, false otherwise.
     */
    function checkEntanglementStatus(uint256 unitId) external view unitExists(unitId) returns (bool) {
        return units[unitId].state == UnitState.Entangled || units[unitId].state == UnitState.Decaying;
    }

    /**
     * @notice Gets the ID of the unit currently linked to this unit, if any.
     * @param unitId The ID of the unit.
     * @return The linked unit ID, or 0 if not linked.
     */
    function getLinkedUnit(uint256 unitId) external view unitExists(unitId) returns (uint256) {
        return units[unitId].linkedUnitId;
    }

    /**
     * @notice Calculates a dynamic Resonance Score for a unit based on its current state.
     * This is a conceptual score based on energy, state, and link type.
     * Score increases with energy, is highest when Entangled, modified by LinkType.
     * @param unitId The ID of the unit.
     * @return The calculated Resonance Score.
     */
    function calculateResonance(uint256 unitId) external view unitExists(unitId) returns (uint256) {
        LinkUnit storage unit = units[unitId];
        uint256 score = BASE_RESONANCE_SCORE; // Base score

        // Add score based on energy level (simple linear mapping for example)
        // Max energy gives MAX_ENERGY contribution to score
        score += unit.energyLevel; // Assuming energyLevel won't exceed uint256 here, or handle potential overflow

        // Adjust score based on state
        if (unit.state == UnitState.Entangled) {
            score += 200; // Bonus for being actively entangled
        } else if (unit.state == UnitState.Decaying) {
            score += 50; // Small bonus even when decaying, represents potential
        } else if (unit.state == UnitState.ProposingLink || unit.state == UnitState.ReceivingLink) {
             score += 20; // Small bonus for being active in the linking process
        }

        // Adjust score based on link type (if entangled)
        if (unit.state == UnitState.Entangled || unit.state == UnitState.Decaying) {
            if (unit.linkType == LinkType.Synergetic) score += 50;
            else if (unit.linkType == LinkType.Resonant) score += 100; // Highest bonus for Resonant links
            else if (unit.linkType == LinkType.Volatile) score -= 30; // Penalty for Volatile links (more effort)
        }

        // Quarantined or Idle state doesn't add state/link type bonuses

        return score;
    }

    /**
     * @notice Gets the current energy cost to establish a specific type of link.
     * @param linkType The type of link (as uint8 enum value).
     * @return The energy cost.
     */
    function getLinkCost(uint8 linkType) external view returns (uint256) {
         if (linkType >= uint8(LinkType.Volatile) + 1) revert InvalidLinkType(linkType);
         return linkCosts[linkType];
    }

    /**
     * @notice Gets the current base energy decay rate per second for entangled units.
     * @return The decay rate.
     */
    function getDecayRate() external view returns (uint256) {
        return entanglementDecayRate;
    }

     /**
     * @notice Gets the timestamp when the decayEntanglement function was last successfully executed.
     * @return The timestamp.
     */
    function getLastDecayTimestamp() external view returns (uint64) {
        return lastDecayRunTimestamp;
    }

     /**
     * @notice Gets the details of a pending link proposal between two units.
     * @param fromUnitId The ID of the unit that proposed.
     * @param toUnitId The ID of the unit that received the proposal.
     * @return A tuple containing proposal details.
     */
    function getLinkProposal(uint256 fromUnitId, uint256 toUnitId)
        external
        view
        returns (uint256 from, uint256 to, LinkType linkType, uint64 proposalTime, bool exists)
    {
         LinkProposal storage proposal = _pendingLinkProposals[fromUnitId][toUnitId];
         return (proposal.fromUnitId, proposal.toUnitId, proposal.linkType, proposal.proposalTime, proposal.exists);
    }

    /**
     * @notice Finds an unlinked pair of units that would have the highest combined Resonance Score if linked.
     * Note: This function is potentially gas-intensive as it iterates through all units.
     * Not suitable for contracts with a very large number of units in a single call.
     * @return A tuple containing the IDs of the two units with the highest combined potential resonance score.
     */
    function findHighestResonancePair() external view returns (uint256 unitIdA, uint256 unitIdB) {
        uint256 highestScore = 0;
        uint256 bestUnitA = 0;
        uint256 bestUnitB = 0;

        if (_unitCounter < 2) revert NoUnitsExist(); // Need at least two units

        // Collect IDs of all unlinked units
        uint256[] memory unlinkedUnitIds = new uint256[](_unitCounter); // Max possible size
        uint256 unlinkedCount = 0;
         for (uint256 i = 1; i <= _unitCounter; i++) {
             if (units[i].id != 0 && units[i].state == UnitState.Idle && !units[i].isQuarantined) {
                 unlinkedUnitIds[unlinkedCount] = i;
                 unlinkedCount++;
             }
         }

        if (unlinkedCount < 2) revert NoUnitsExist(); // Need at least two *unlinked* units

        // Resize the array to actual count
        uint256[] memory activeUnlinkedUnits = new uint256[](unlinkedCount);
        for(uint i = 0; i < unlinkedCount; i++) {
            activeUnlinkedUnits[i] = unlinkedUnitIds[i];
        }

        // Iterate through all unique pairs of unlinked units
        for (uint i = 0; i < unlinkedCount; i++) {
            for (uint j = i + 1; j < unlinkedCount; j++) {
                uint256 currentUnitAId = activeUnlinkedUnits[i];
                uint256 currentUnitBId = activeUnlinkedUnits[j];

                // Calculate combined individual resonance scores (as a heuristic for potential linked score)
                // A more advanced version might simulate the linked state and calculate the resonance.
                uint256 scoreA = calculateResonance(currentUnitAId);
                uint256 scoreB = calculateResonance(currentUnitBId);
                uint256 combinedScore = scoreA + scoreB; // Simple sum as heuristic

                if (combinedScore > highestScore) {
                    highestScore = combinedScore;
                    bestUnitA = currentUnitAId;
                    bestUnitB = currentUnitBId;
                }
            }
        }

        return (bestUnitA, bestUnitB);
    }
}
```